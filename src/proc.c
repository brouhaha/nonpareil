/*
$Id$
Copyright 1995, 2004, 2005 Eric L. Smith <eric@brouhaha.com>

Nonpareil is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License version 2 as
published by the Free Software Foundation.  Note that I am not
granting permission to redistribute or modify Nonpareil under the
terms of any later version of the General Public License.

Nonpareil is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program (in the file "COPYING"); if not, write to the
Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
MA 02111, USA.
*/

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <glib.h>

#include "util.h"
#include "display.h"
#include "proc.h"
#include "arch.h"
#include "platform.h"
#include "model.h"
#include "proc_int.h"
#include "glib_async_queue_source.h"
#include "mod1_file.h"


// We try to schedule execution in "jiffies".
#define JIFFY_PER_SEC 30

#define JIFFY_USEC (1.0e6 / JIFFY_PER_SEC)


// Don't try to execute more than MAX_INST_BURST instructions per
// jiffy.  If we can't, we'll just fall behind.
#define MAX_INST_BURST 5000


struct chip_t
{
  chip_t *next;
  chip_t *prev;

  sim_t *sim;

  const chip_detail_t *chip_detail;
  void *chip_data;
};


// Messages sent from GUI thread to simulator thread, and
// sent back as replies.

typedef enum
{
  CMD_EVENT,
  CMD_QUIT,
  CMD_RESET,
  CMD_GET_IO_PAUSE_FLAG,
  CMD_SET_IO_PAUSE_FLAG,
  CMD_WRITE_REGISTER,
  CMD_READ_REGISTER,
  CMD_SET_BANK_GROUP,
  CMD_WRITE_ROM,
  CMD_READ_ROM,
  CMD_WRITE_RAM,
  CMD_READ_RAM,
  CMD_GET_CYCLE_COUNT,
  CMD_SET_CYCLE_COUNT,
  CMD_SET_RUN_FLAG,
  CMD_GET_RUN_FLAG,
  CMD_SET_DEBUG_FLAG,
  CMD_GET_DEBUG_FLAG,
  CMD_SINGLE_CYCLE,
  CMD_SINGLE_INST,
  CMD_SET_BREAKPOINT,
  CMD_PRESS_KEY,
  CMD_RELEASE_KEY,
  CMD_SET_EXT_FLAG,
  CMD_GET_DISPLAY_UPDATE
} sim_cmd_t;

typedef enum
{
  OK,
  UNIMPLEMENTED,
  BAD_CMD,
  ARG_RANGE_ERROR
} sim_reply_t;


typedef struct
{
  sim_cmd_t     cmd;
  sim_reply_t   reply;
  bool          b;
  uint64_t      cycle_count;
  addr_t        addr;
  chip_t        *chip;
  int           arg1;   // reg_num, keycode, flag number, bank, bank group, etc.
  int           arg2;   // index (in read/write register)
  void          *data;  // register value, memory value, etc.
} sim_msg_t;


// Messages sent from simulator thread to GUI thread, for display
// updates, breakpoint notification, and the like.  There are no replies,
// though the messages get recycled through a free queue.

typedef enum
{
  CMD_DISPLAY_UPDATE,
  CMD_BREAKPOINT_HIT
} gui_cmd_t;

typedef struct
{
  sim_t            *sim;
  gui_cmd_t        cmd;
  int              display_digits;
  segment_bitmap_t display_segments [MAX_DIGIT_POSITION];
} gui_msg_t;



struct sim_thread_vars_t
{
  GThread  *gthread;

  // The cmd_q and reply_q are simulator thread specific.
  GAsyncQueue *cmd_q;          // commands from GUI to sim
  GAsyncQueue *reply_q;        // replies from sim to GUI

  // The gui_cmd_q and qui_cmd_free_q could be shared between multiple
  // simulator threads, but currently are not.
  GAsyncQueue *gui_cmd_q;      // output from sim to GUI
  GAsyncQueue *gui_cmd_free_q; // free messsage blocks for use on gui_cmd_q

  GAsyncQueueSource *gui_cmd_q_source;

  GTimeVal last_run_time;
  GTimeVal next_run_time;

  GTimeVal tv;
  GTimeVal prev_tv;
};


static bool sim_load_mod1_rom_word (sim_t *sim,
				    uint8_t bank,
				    addr_t addr,
				    rom_word_t data)
{
  if (! sim_write_rom (sim, bank, addr, & data))
    {
      fprintf (stderr, "Can't load ROM word at bank %d address %o\n", bank, addr);
      return false;
    }
  return true;
}


static int bank_group [MAX_BANK_GROUP + 1];  // index from 1 .. MAX_BANK_GROUP,
                                             // entry 0 not used


static bool sim_read_mod1_page (sim_t *sim, FILE *f)
{
  mod1_file_page_t page;
  addr_t addr;
  int i;

  if (! mod1_read_page (f, & page))
    {
      fprintf (stderr, "Can't read MOD1 page\n");
      return false;
    }

  if (! mod1_validate_page (& page))
    {
      fprintf (stderr, "Unrecognized or inconsistent values in MOD1 page\n");
      return false;
    }

  if (page.Page > 0x0f)
    {
      fprintf (stderr, "Currently only MOD1 pages at fixed page numbers are supported\n");
      return false;
    }

  addr = page.Page << 12;

  if (page.BankGroup)
    {
      if (! bank_group [page.BankGroup])
	bank_group [page.BankGroup] = sim_create_bank_group (sim);
      sim_set_bank_group (sim, bank_group [page.BankGroup], addr);
    }

  for (i = 0; i < 5120; i += 5)
    {
      rom_word_t data;

      data = (((page.Image [i + 1] & 0x03) << 8) |
	      (page.Image [i]));
      if (! sim_load_mod1_rom_word (sim, page.Bank - 1, addr++, data))
				    
        return false;

      data = (((page.Image [i + 2] & 0x0f) << 6) |
	      ((page.Image [i + 1] & 0xfc) >> 2));
      if (! sim_load_mod1_rom_word (sim, page.Bank - 1, addr++, data))
				    
        return false;

      data = (((page.Image [i + 3] & 0x3f) << 4) |
	      ((page.Image [i + 2] & 0xf0) >> 4));
      if (! sim_load_mod1_rom_word (sim, page.Bank - 1, addr++, data))
				    
        return false;

      data = ((page.Image [i + 4] << 2) |
	      ((page.Image [i + 3] & 0xc0) >> 6));
      if (! sim_load_mod1_rom_word (sim, page.Bank - 1, addr++, data))
				    
        return false;
    }

  return true;
}


static bool sim_read_mod1_file (sim_t *sim, FILE *f)
{
  mod1_file_header_t header;
  size_t file_size;
  int i;

  for (i = 1; i <= MAX_BANK_GROUP; i++)
    bank_group [i] = 0;

  fseek (f, 0, SEEK_END);
  file_size = ftell (f);
  fseek (f, 0, SEEK_SET);

  if (! mod1_read_file_header (f, & header))
    {
      fprintf (stderr, "Can't read MOD1 file header\n");
      return false;
    }

  if (! mod1_validate_file_header (& header, file_size))
    {
      fprintf (stderr, "Unrecognized or inconsistent values in MOD1 file header\n");
      return false;
    }

  for (i = 0; i < header.NumPages; i++)
    if (! sim_read_mod1_page (sim, f))
      return false;

  return true;
}


bool sim_read_object_file (sim_t *sim, char *fn)
{
  FILE *f;
  int bank;
  int addr;  // should change to addr_t, but will have to change
             // the parse function profiles to match.
  rom_word_t opcode;
  int count = 0;
  char buf [80];
  char magic [4];
  bool eof, error;

  f = fopen (fn, "rb");
  if (! f)
    {
      fprintf (stderr, "error opening object file\n");
      return (false);
    }

  if (fread_bytes (f, magic, 4, & eof, & error) != 4)
    {
      fprintf (stderr, "error reading object file\n");
      return (false);
    }

  if (strcmp (magic, "MOD1") == 0)
    return sim_read_mod1_file (sim, f);

  f = freopen (NULL, "r", f);  // switch from binary to text mode, and rewind
  if (! f)
    {
      fprintf (stderr, "error opening object file\n");
      return (false);
    }

  while (fgets (buf, sizeof (buf), f))
    {
      trim_trailing_whitespace (buf);
      if (! buf [0])
	continue;
      if (sim->proc->parse_object_line (buf, & bank, & addr, & opcode))
	{
	  if (! sim_write_rom (sim, bank, addr, & opcode))
	    fatal (3, "can't load ROM word at bank %d address %o\n", bank, addr);
	  count++;
	}
    }

#if 0
  fprintf (stderr, "read %d words from '%s'\n", count, fn);
#endif
  return (true);
}


bool sim_read_listing_file (sim_t *sim, char *fn)
{
  FILE *f;
  int bank, i;
  int addr;  // should change to addr_t, but will have to change
             // the parse function profiles to match.
  rom_word_t opcode;
  rom_word_t obj_opcode;
  int count = 0;
  char buf [80];

  f = fopen (fn, "r");
  if (! f)
    {
      fprintf (stderr, "error opening listing file\n");
      return (false);
    }

  while (fgets (buf, sizeof (buf), f))
    {
      trim_trailing_whitespace (buf);
      if (sim->proc->parse_listing_line (buf, & bank, & addr, & opcode))
	{
	  i = bank * sim->proc->max_rom + addr;
	  if (sim_read_rom (sim, bank, addr, & obj_opcode))
	    {
	      fprintf (stderr, "listing line for which there was no code in object file, bank %d address %o\n",
		       bank, addr);
	      fprintf (stderr, "src: %s\n", sim->source [i]);
	    }
	  if (obj_opcode != opcode)
	    {
	      fprintf (stderr, "listing line for which object code does not match object file, bank %d address %o\n",
		       bank, addr);
	      fprintf (stderr, "src: %s\n", sim->source [i]);
	      fprintf (stderr, "object file: %04o\n", obj_opcode);
	    }
	  sim->source   [i] = newstr (& buf [0]);
	  count++;
	}
    }

#if 0
  fprintf (stderr, "read %d words from '%s'\n", count, fn);
#endif
  return (true);
}


// Sends a command from the GUI thread to the sim thread, and waits
// for a reply.
static void send_cmd_to_sim_thread (sim_t *sim, gpointer msg)
{
  gpointer msg2;
  g_async_queue_push (sim->thread_vars->cmd_q, msg);
  msg2 = g_async_queue_pop (sim->thread_vars->reply_q);
  if (msg2 != msg)
    fatal (2, "async reply != msg\n");
}


static void cmd_read_register (sim_t *sim, sim_msg_t *msg)
{
  const chip_detail_t *chip_detail;
  const reg_detail_t *reg_detail;
  uint8_t *addr;
  uint64_t *result_val;

  msg->reply = ARG_RANGE_ERROR;

  chip_detail = msg->chip->chip_detail;

  if (msg->arg1 >= chip_detail->reg_count)
    return;
  reg_detail = & chip_detail->reg_detail [msg->arg1];
  if (msg->arg2 >= reg_detail->info.array_element_count)
    return;

  addr = (((uint8_t *) msg->chip->chip_data) +
	  reg_detail->offset + msg->arg2 * reg_detail->size);
  result_val = msg->data;

  if (reg_detail->get)
    {
      if (reg_detail->get (addr, result_val, reg_detail->accessor_arg))
	msg->reply = OK;
    }
  else
    {
      switch (reg_detail->size)
	{
	case 1: *result_val = *((uint8_t  *) addr); break;
	case 2: *result_val = *((uint16_t *) addr); break;
	case 4: *result_val = *((uint32_t *) addr); break;
	case 8: *result_val = *((uint64_t *) addr); break;
	default:
	  fatal (3, "bad storage size\n");
	}
      msg->reply = OK;
    }
}


static void cmd_write_register (sim_t *sim, sim_msg_t *msg)
{
  const chip_detail_t *chip_detail;
  const reg_detail_t *reg_detail;
  uint8_t *addr;
  uint64_t *source_val;

  msg->reply = ARG_RANGE_ERROR;

  chip_detail = msg->chip->chip_detail;

  if (msg->arg1 >= chip_detail->reg_count)
    return;
  reg_detail = & chip_detail->reg_detail [msg->arg1];
  if (msg->arg2 >= reg_detail->info.array_element_count)
    return;

  addr = (((uint8_t *) msg->chip->chip_data) +
	  reg_detail->offset + msg->arg2 * reg_detail->size);
  source_val = msg->data;

  if (reg_detail->set)
    {
      if (reg_detail->set (addr, source_val, reg_detail->accessor_arg))
	msg->reply = OK;
    }
  else
    {
      switch (reg_detail->size)
	{
	case 1: *((uint8_t  *) addr) = *source_val; break;
	case 2: *((uint16_t *) addr) = *source_val; break;
	case 4: *((uint32_t *) addr) = *source_val; break;
	case 8: *((uint64_t *) addr) = *source_val; break;
	default:
	  fatal (3, "bad storage size\n");
	}
      msg->reply = OK;
    }
}


static void cmd_set_bank_group (sim_t *sim, sim_msg_t *msg)
{
  if (! sim->proc->set_bank_group)
    msg->reply = UNIMPLEMENTED;
  else if (sim->proc->set_bank_group (sim, msg->arg1, msg->addr))
    msg->reply = OK;
  else
    msg->reply = ARG_RANGE_ERROR;
}

static void cmd_read_rom (sim_t *sim, sim_msg_t *msg)
{
  if (sim->proc->read_rom (sim, msg->arg1, msg->addr, msg->data))
    msg->reply = OK;
  else
    msg->reply = ARG_RANGE_ERROR;
}


static void cmd_write_rom (sim_t *sim, sim_msg_t *msg)
{
  if (sim->proc->write_rom (sim, msg->arg1, msg->addr, msg->data))
    msg->reply = OK;
  else
    msg->reply = ARG_RANGE_ERROR;
}


static void cmd_read_ram (sim_t *sim, sim_msg_t *msg)
{
  if (sim->proc->read_ram (sim, msg->addr, msg->data))
    msg->reply = OK;
  else
    msg->reply = ARG_RANGE_ERROR;
}


static void cmd_write_ram (sim_t *sim, sim_msg_t *msg)
{
  if (sim->proc->write_ram (sim, msg->addr, msg->data))
    msg->reply = OK;
  else
    msg->reply = ARG_RANGE_ERROR;
}


static void handle_sim_cmd (sim_t *sim, sim_msg_t *msg)
{
  msg->reply = UNIMPLEMENTED;
  switch (msg->cmd)
    {
    case CMD_EVENT:
      chip_event (sim, msg->arg1);
      msg->reply = OK;
      break;
    case CMD_QUIT:
      sim->quit_flag = true;
      msg->reply = OK;
      break;
    case CMD_RESET:
      // $$$ what to do
      // $$$ Allow reset while runflag is true?
      msg->reply = OK;
      break;
    case CMD_SET_IO_PAUSE_FLAG:
      sim->io_pause_flag = msg->b;
      g_get_current_time (& sim->thread_vars->last_run_time);
      g_get_current_time (& sim->thread_vars->next_run_time);
      msg->reply = OK;
      break;
    case CMD_GET_IO_PAUSE_FLAG:
      msg->b = sim->io_pause_flag;
      msg->reply = OK;
      break;
    case CMD_READ_REGISTER:
      cmd_read_register (sim, msg);
      break;
    case CMD_WRITE_REGISTER:
      cmd_write_register (sim, msg);
      break;
    case CMD_SET_BANK_GROUP:
      cmd_set_bank_group (sim, msg);
      break;
    case CMD_READ_ROM:
      cmd_read_rom (sim, msg);
      break;
    case CMD_WRITE_ROM:
      cmd_write_rom (sim, msg);
      break;
    case CMD_READ_RAM:
      cmd_read_ram (sim, msg);
      break;
    case CMD_WRITE_RAM:
      cmd_write_ram (sim, msg);
      break;
    case CMD_GET_CYCLE_COUNT:
      msg->cycle_count = sim->cycle_count;
      msg->reply = OK;
      break;
    case CMD_SET_CYCLE_COUNT:
      sim->cycle_count = msg->cycle_count;
      msg->reply = OK;
      break;
    case CMD_SET_RUN_FLAG:
      sim->run_flag = msg->b;
      g_get_current_time (& sim->thread_vars->last_run_time);
      g_get_current_time (& sim->thread_vars->next_run_time);
      msg->reply = OK;
      break;
    case CMD_GET_RUN_FLAG:
      msg->b = sim->run_flag;
      msg->reply = OK;
      break;
#ifdef HAS_DEBUGGER
    case CMD_SET_DEBUG_FLAG:
      if (msg->b)
	sim->debug_flags |= (1 << msg->arg1);
      else
	sim->debug_flags &= ~ (1 << msg->arg1);
      msg->reply = OK;
      break;
    case CMD_GET_DEBUG_FLAG:
      msg->b = ((sim->debug_flags & (1 << msg->arg1)) != 0);
      msg->reply = OK;
      break;
#endif // HAS_DEBUGGER
    case CMD_SINGLE_CYCLE:
      // $$$ Allow step while runflag is true?
      sim->single_cycle_flag = true;
      msg->reply = OK;
      break;
    case CMD_SINGLE_INST:
      // $$$ Allow step while runflag is true?
      sim->single_inst_flag = true;
      msg->reply = OK;
      break;
    case CMD_SET_BREAKPOINT:
      break;
    case CMD_PRESS_KEY:
      sim->proc->press_key (sim, msg->arg1);
      msg->reply = OK;
      break;
    case CMD_RELEASE_KEY:
      // $$$ might be nice to allow releasing a specific key!
      sim->proc->release_key (sim);
      msg->reply = OK;
      break;
    case CMD_SET_EXT_FLAG:
      sim->proc->set_ext_flag (sim, msg->arg1, msg->b);
      msg->reply = OK;
      break;
    case CMD_GET_DISPLAY_UPDATE:
      sim_send_display_update_to_gui (sim);
      msg->reply = OK;
      break;
    default:
      msg->reply = BAD_CMD;
    }
  g_async_queue_push (sim->thread_vars->reply_q, msg);
}


void sim_run (sim_t *sim)
{
  GTimeVal now;
  int inst_count;
  long usec;

  g_get_current_time (& now);

  /* compute how many microinstructions we want to execute */
  usec = now.tv_usec - sim->thread_vars->last_run_time.tv_usec;
  switch (now.tv_sec - sim->thread_vars->last_run_time.tv_sec)
    {
    case 0: break;
    case 1: usec += 1000000; break;
    default: usec = 1000000;
    }
  inst_count = usec * sim->words_per_usec;
  if (inst_count > MAX_INST_BURST)
    inst_count = MAX_INST_BURST;
#if 0
  printf ("tv %d.%06d, usec %d, inst_count %d\n",
	  sim->thread_vars->tv.tv_sec,
	  sim->thread_vars->tv.tv_usec,
	  usec,
	  inst_count);
#endif

  /* execute the microinstructions */
  while (inst_count--)
    {
      if (! sim->proc->execute_instruction (sim))
	break;
    }

  // Remember when we ran, and figure out when to run next.
  memcpy (& sim->thread_vars->last_run_time, & now, sizeof (GTimeVal));

  memcpy (& sim->thread_vars->next_run_time, & now, sizeof (GTimeVal));
  g_time_val_add (& sim->thread_vars->next_run_time, JIFFY_USEC);
}


gpointer sim_thread_func (gpointer data)
{
  sim_t *sim = (sim_t *) data;
  sim_msg_t *msg;

  while (! sim->quit_flag)
    {
      if ((! sim->io_pause_flag) && sim->run_flag)
	msg = g_async_queue_timed_pop (sim->thread_vars->cmd_q,
				       & sim->thread_vars->next_run_time);
      else
	msg = g_async_queue_pop (sim->thread_vars->cmd_q);

      if (msg)
	{
	  handle_sim_cmd (sim, msg);
	  continue;
	}

      if (sim->io_pause_flag)
	continue;

      if (sim->single_cycle_flag)
	{
	  sim->proc->execute_cycle (sim);
	  sim->single_cycle_flag = false;
	}
      else if (sim->single_inst_flag)
	{
	  sim->proc->execute_instruction (sim);
	  sim->single_inst_flag = false;
	}
      else if (sim->run_flag)
	sim_run (sim);

      // handle_io (sim);
    }

  return (NULL);  // Exit thread
}


static void prefill_gui_cmd_q (GAsyncQueue *q, int count)
{
  while (count--)
    {
      gui_msg_t *msg = alloc (sizeof (gui_msg_t));
      g_async_queue_push (q, msg);
    }
}


static gboolean gui_cmd_callback (gpointer data)
{
  gui_msg_t *msg = (gui_msg_t *) data;
  sim_t *sim = msg->sim;

  switch (msg->cmd)
    {
    case CMD_DISPLAY_UPDATE:
      sim->display_update_callback (sim->display_update_callback_ref,
				    msg->display_digits,
				    msg->display_segments);
      break;
    case CMD_BREAKPOINT_HIT:
      break;
    }
  return (true);
}


// Called by GUI thread to create a simulator thread
// $$$ Some of the initialization here should be moved into
// the thread function.

sim_t *sim_init  (int model,
		  int clock_frequency,  /* Hz */
		  int ram_size,
		  segment_bitmap_t *char_gen,
		  display_update_callback_fn_t *display_update_callback,
		  void *display_update_callback_ref)
{
  sim_t *sim;
  model_info_t *model_info = get_model_info (model);
  arch_info_t *arch_info;

  sim = alloc (sizeof (sim_t));
  sim->thread_vars = alloc (sizeof (sim_thread_vars_t));

  // save display callback info
  sim->display_update_callback = display_update_callback;
  sim->display_update_callback_ref = display_update_callback_ref;

  sim->model = model;

  sim->platform = model_info->platform;

  arch_info = get_arch_info (model_info->cpu_arch);
  sim->arch = model_info->cpu_arch;
  sim->proc = processor_dispatch [model_info->cpu_arch];

  sim->words_per_usec = clock_frequency / (1.0e6 * arch_info->word_length);

  sim->thread_vars->cmd_q = g_async_queue_new ();
  sim->thread_vars->reply_q = g_async_queue_new ();
  sim->thread_vars->gui_cmd_q = g_async_queue_new ();
  sim->thread_vars->gui_cmd_free_q = g_async_queue_new ();

  prefill_gui_cmd_q (sim->thread_vars->gui_cmd_free_q, 10);

  // add gui_cmd_q as a "source" for GUI thread.
  sim->thread_vars->gui_cmd_q_source = g_async_queue_source_add (sim->thread_vars->gui_cmd_q,
								 sim->thread_vars->gui_cmd_free_q,
								 NULL,  // use main context
								 gui_cmd_callback);

  sim->source = alloc (sim->proc->max_bank * sim->proc->max_rom * sizeof (char *));

  sim->proc->new_processor (sim, ram_size);

  sim->char_gen = char_gen;

  sim->cycle_count = 0;

  sim->thread_vars->gthread = g_thread_create (sim_thread_func, sim, TRUE, NULL);

  return (sim);
}


int sim_get_model (sim_t *sim)
{
  return sim->model;
}


void sim_event (sim_t *sim, int event)
{
  sim_msg_t msg;

  memset (& msg, 0, sizeof (sim_msg_t));
  msg.cmd = CMD_EVENT;
  msg.arg1 = event;
  send_cmd_to_sim_thread (sim, (gpointer) & msg);
}


void sim_quit (sim_t *sim)
{
  sim_msg_t msg;

  memset (& msg, 0, sizeof (sim_msg_t));
  msg.cmd = CMD_QUIT;
  send_cmd_to_sim_thread (sim, (gpointer) & msg);

  // $$$ should remove all chips

  // $$$ should wait for thread exit here

  sim->proc->free_processor (sim);

  free (sim);
}


void sim_reset (sim_t *sim)
{
  sim_msg_t msg;
  memset (& msg, 0, sizeof (sim_msg_t));
  msg.cmd = CMD_RESET;
  send_cmd_to_sim_thread (sim, (gpointer) & msg);
}


void sim_single_cycle (sim_t *sim)
{
  sim_msg_t msg;
  memset (& msg, 0, sizeof (sim_msg_t));
  msg.cmd = CMD_SINGLE_CYCLE;
  send_cmd_to_sim_thread (sim, (gpointer) & msg);
}


void sim_single_inst (sim_t *sim)
{
  sim_msg_t msg;
  memset (& msg, 0, sizeof (sim_msg_t));
  msg.cmd = CMD_SINGLE_INST;
  send_cmd_to_sim_thread (sim, (gpointer) & msg);
}


void sim_start (sim_t *sim)
{
  sim_msg_t msg;
  memset (& msg, 0, sizeof (sim_msg_t));
  msg.cmd = CMD_SET_RUN_FLAG;
  msg.b = true;
  send_cmd_to_sim_thread (sim, (gpointer) & msg);
}


void sim_stop (sim_t *sim)
{
  sim_msg_t msg;
  memset (& msg, 0, sizeof (sim_msg_t));
  msg.cmd = CMD_SET_RUN_FLAG;
  msg.b = false;
  send_cmd_to_sim_thread (sim, (gpointer) & msg);
}


bool sim_running (sim_t *sim)
{
  sim_msg_t msg;
  memset (& msg, 0, sizeof (sim_msg_t));
  msg.cmd = CMD_GET_RUN_FLAG;
  send_cmd_to_sim_thread (sim, (gpointer) & msg);
  return msg.b;
}


void sim_set_io_pause_flag (sim_t *sim, bool io_pause_flag)
{
  sim_msg_t msg;
  memset (& msg, 0, sizeof (sim_msg_t));
  msg.cmd = CMD_SET_IO_PAUSE_FLAG;
  msg.b = io_pause_flag;
  send_cmd_to_sim_thread (sim, (gpointer) & msg);
}


bool sim_get_io_pause_flag (sim_t *sim)
{
  sim_msg_t msg;
  memset (& msg, 0, sizeof (sim_msg_t));
  msg.cmd = CMD_GET_IO_PAUSE_FLAG;
  send_cmd_to_sim_thread (sim, (gpointer) & msg);
  return msg.b;
}


// Returns NULL if there are no chips (should never happen).
chip_t *sim_get_first_chip (sim_t *sim)
{
  return sim->first_chip;
}


// Returns NULL if there are no more chips.
chip_t *sim_get_next_chip (sim_t *sim, chip_t *chip)
{
  return chip->next;
}


// Returns NULL if it can't find a chip with the specified name
// (and address for chips that support multiple instances).
chip_t *sim_find_chip (sim_t *sim,
		       const char *name,
		       uint64_t addr)
{
  chip_t *chip;

  for (chip = sim->first_chip; chip; chip = chip->next)
    if (strcmp (name, chip->chip_detail->info.name) == 0)
      {
        if (chip->chip_detail->info.multiple)
	  {
	    ; // $$$ need to check address here
	  }
	return chip;
      }

  return NULL;
}


const chip_info_t *sim_get_chip_info (sim_t *sim,
				      chip_t *chip)
{
  return & chip->chip_detail->info;
}


int sim_get_reg_count (sim_t *sim, chip_t *chip)
{
  return chip->chip_detail->reg_count;
}


int sim_find_register (sim_t *sim,
		       chip_t *chip,
		       char  *name)
{
  int reg_num;
  const chip_detail_t *chip_detail;

  chip_detail = chip->chip_detail;

  for (reg_num = 0; reg_num < chip_detail->reg_count; reg_num++)
    {
      if (strcmp (name, chip_detail->reg_detail [reg_num].info.name) == 0)
	return reg_num;
    }

  return -1;
}


const reg_info_t *sim_get_register_info (sim_t *sim,
					 chip_t *chip,
					 int   reg_num)
{
  const chip_detail_t *chip_detail;

  chip_detail = chip->chip_detail;

  chip_detail = chip->chip_detail;

  if (reg_num >= chip_detail->reg_count)
    return NULL;

  return & chip_detail->reg_detail [reg_num].info;
}


bool sim_read_register (sim_t   *sim,
			chip_t  *chip,
			int     reg_num,
			int     index,
			uint64_t *val)
{
  sim_msg_t msg;
  const chip_detail_t *chip_detail;

  chip_detail = chip->chip_detail;

  if (reg_num >= chip_detail->reg_count)
    return false;

  *val = 0;

  memset (& msg, 0, sizeof (sim_msg_t));
  msg.chip = chip;
  msg.arg1 = reg_num;
  msg.arg2 = index;
  msg.data = val;
  msg.cmd = CMD_READ_REGISTER;
  send_cmd_to_sim_thread (sim, (gpointer) & msg);
  return (msg.reply == OK);
}


bool sim_write_register (sim_t   *sim,
			 chip_t  *chip,
			 int     reg_num,
			 int     index,
			 uint64_t *val)
{
  sim_msg_t msg;
  const chip_detail_t *chip_detail;

  chip_detail = chip->chip_detail;

  if (reg_num >= chip_detail->reg_count)
    return false;

  memset (& msg, 0, sizeof (sim_msg_t));
  msg.chip = chip;
  msg.arg1 = reg_num;
  msg.arg2 = index;
  msg.data = val;
  msg.cmd = CMD_WRITE_REGISTER;
  send_cmd_to_sim_thread (sim, (gpointer) & msg);
  return (msg.reply == OK);
}


// Bank switching routines
int sim_create_bank_group (sim_t *sim)
{
  static int bank_group = 0;

  return ++bank_group;
}

bool sim_set_bank_group (sim_t  *sim,
			 int    bank_group,
			 addr_t addr)
{
  sim_msg_t msg;
  memset (& msg, 0, sizeof (sim_msg_t));
  msg.arg1 = bank_group;
  msg.addr = addr;
  msg.cmd = CMD_SET_BANK_GROUP;
  send_cmd_to_sim_thread (sim, (gpointer) & msg);
  return (msg.reply == OK);
}


// ROM access routines
bool sim_read_rom  (sim_t      *sim,
		    uint8_t    bank,
		    addr_t     addr,
		    rom_word_t *val)
{
  sim_msg_t msg;
  memset (& msg, 0, sizeof (sim_msg_t));
  msg.arg1 = bank;
  msg.addr = addr;
  msg.data = val;
  msg.cmd = CMD_READ_ROM;
  send_cmd_to_sim_thread (sim, (gpointer) & msg);
  return (msg.reply == OK);
}


bool sim_write_rom (sim_t      *sim,
		    uint8_t    bank,
		    addr_t     addr,
		    rom_word_t *val)
{
  sim_msg_t msg;
  memset (& msg, 0, sizeof (sim_msg_t));
  msg.arg1 = bank;
  msg.addr = addr;
  msg.data = val;
  msg.cmd = CMD_WRITE_ROM;
  send_cmd_to_sim_thread (sim, (gpointer) & msg);
  return (msg.reply == OK);
}


addr_t sim_get_max_ram (sim_t *sim)
{
  return sim->max_ram;
}


bool sim_read_ram (sim_t   *sim,
		   addr_t  addr,
		   uint64_t *val)
{
  sim_msg_t msg;
  memset (& msg, 0, sizeof (sim_msg_t));
  msg.addr = addr;
  msg.data = val;
  msg.cmd = CMD_READ_RAM;
  send_cmd_to_sim_thread (sim, (gpointer) & msg);
  return (msg.reply == OK);
}


bool sim_write_ram (sim_t   *sim,
		    addr_t  addr,
		    uint64_t *val)
{
  sim_msg_t msg;
  memset (& msg, 0, sizeof (sim_msg_t));
  msg.addr = addr;
  msg.data = val;
  msg.cmd = CMD_WRITE_RAM;
  send_cmd_to_sim_thread (sim, (gpointer) & msg);
  return (msg.reply == OK);
}


void sim_press_key (sim_t *sim, int keycode)
{
  sim_msg_t msg;
  memset (& msg, 0, sizeof (sim_msg_t));
  msg.cmd = CMD_PRESS_KEY;
  msg.arg1 = keycode;
  send_cmd_to_sim_thread (sim, (gpointer) & msg);
}


void sim_release_key (sim_t *sim)
{
  sim_msg_t msg;
  memset (& msg, 0, sizeof (sim_msg_t));
  msg.cmd = CMD_RELEASE_KEY;
  send_cmd_to_sim_thread (sim, (gpointer) & msg);
}


void sim_set_ext_flag (sim_t *sim, int flag, bool state)
{
  sim_msg_t msg;
  memset (& msg, 0, sizeof (sim_msg_t));
  msg.cmd = CMD_SET_EXT_FLAG;
  msg.arg1 = flag;
  msg.b = state;
  send_cmd_to_sim_thread (sim, (gpointer) & msg);
}


void sim_get_display_update (sim_t *sim)
{
  sim_msg_t msg;
  memset (& msg, 0, sizeof (sim_msg_t));
  msg.cmd = CMD_GET_DISPLAY_UPDATE;
  send_cmd_to_sim_thread (sim, (gpointer) & msg);
}


#ifdef HAS_DEBUGGER
void sim_set_debug_flag (sim_t *sim, int debug_flag, bool state)
{
  sim_msg_t msg;
  memset (& msg, 0, sizeof (sim_msg_t));
  msg.cmd = CMD_SET_DEBUG_FLAG;
  msg.arg1 = debug_flag;
  msg.b = state;
  send_cmd_to_sim_thread (sim, (gpointer) & msg);
}

bool sim_get_debug_flag (sim_t *sim, int debug_flag)
{
  sim_msg_t msg;
  memset (& msg, 0, sizeof (sim_msg_t));
  msg.cmd = CMD_GET_DEBUG_FLAG;
  msg.arg1 = debug_flag;
  send_cmd_to_sim_thread (sim, (gpointer) & msg);
  return (msg.b);
}
#endif // HAS_DEBUGGER


void sim_send_display_update_to_gui (sim_t *sim)
{
  gui_msg_t *msg;

  msg = g_async_queue_try_pop (sim->thread_vars->gui_cmd_free_q);
  if (! msg)
    msg = alloc (sizeof (gui_msg_t));

  msg->sim = sim;
  msg->cmd = CMD_DISPLAY_UPDATE;
  msg->display_digits = sim->display_digits;
  memcpy (msg->display_segments, sim->display_segments, sizeof (sim->display_segments));

  g_async_queue_source_push (sim->thread_vars->gui_cmd_q_source, msg);
}


extern processor_dispatch_t classic_processor;
extern processor_dispatch_t woodstock_processor;
extern processor_dispatch_t nut_processor;

processor_dispatch_t *processor_dispatch [ARCH_MAX] =
  {
    [ARCH_UNKNOWN]   = NULL,
    [ARCH_CLASSIC]   = & classic_processor,
    [ARCH_WOODSTOCK] = & woodstock_processor,
    [ARCH_CRICKET]   = NULL,
    [ARCH_NUT]       = & nut_processor,
    [ARCH_CAPRICORN] = NULL,
    [ARCH_SATURN]    = NULL
  };


// Common non-standard acccessor functions used for fields that
// are internally stored as an array of digits, one digit per byte.
// The external representation is packed into a single uint of an
// appropriate size.
bool get_digits (void *data, uint64_t *p, int arg)
{
  uint64_t val = 0;
  uint8_t *d;
  int i;

  d = ((uint8_t *) data) + arg;
  for (i = 0; i < arg; i++)
    val = (val << 4) + *(--d);

  *p = val;

  return true;
}


bool set_digits (void *data, uint64_t *p, int arg)
{
  uint64_t val = *p;
  uint8_t *d;
  int i;

  d = (uint8_t *) data;
  for (i = 0; i < arg; i++)
    {
      *(d++) = val & 0x0f;
      val >>= 4;
    }

  return true;
}


bool get_bit_digits (void *data, uint64_t *p, int arg)
{
  uint64_t val = 0;
  uint8_t *d;
  int i;

  d = ((uint8_t *) data) + arg;
  for (i = 0; i < arg; i++)
    val = (val << 1) + *(--d);

  *p = val;

  return true;
}


bool set_bit_digits (void *data, uint64_t *p, int arg)
{
  uint64_t val = *p;
  uint8_t *d;
  int i;

  d = (uint8_t *) data;
  for (i = 0; i < arg; i++)
    {
      *(d++) = val & 0x0f;
      val >>= 1;
    }

  return true;
}


bool get_bools (void *data, uint64_t *p, int arg)
{
  uint16_t val;
  bool *d;
  int i;

  d = ((bool *) data) + arg;
  val = 0;
  for (i = 0; i < arg; i++)
    val = (val << 1) + *(--d);

  *p = val;

  return true;
}

bool set_bools (void *data, uint64_t *p, int arg)
{
  uint16_t val;
  bool *d;
  int i;

  val = *p;
  d = (bool *) data;
  for (i = 0; i < arg; i++)
    {
      *(d++) = val & 0x01;
      val >>= 1;
    }

  return true;
}


chip_t *install_chip (sim_t *sim,
		      const chip_detail_t *chip_detail,
		      void *chip_data)
{
  chip_t *chip;

  chip = alloc (sizeof (chip_t));

  chip->sim = sim;

  chip->chip_detail   = chip_detail;
  chip->chip_data     = chip_data;

  // add chip at tail of list
  if (sim->last_chip)
    {
      chip->prev = sim->last_chip;
      sim->last_chip->next = chip;
    }
  else
    sim->first_chip = chip;

  sim->last_chip = chip;

  return chip;
}


void remove_chip (chip_t *chip)
{
  if (chip->prev)
    chip->prev->next = chip->next;
  else
    chip->sim->first_chip = chip->next;

  if (chip->next)
    chip->next->prev = chip->prev;
  else
    chip->sim->last_chip = chip->prev;

  // $$$ maybe should call a function via the chip_detail to do this?
  free (chip->chip_data);

  free (chip);
}


void chip_event (sim_t *sim, int event)
{
  chip_t *chip;

  for (chip = sim->first_chip; chip; chip = chip->next)
    if (chip->chip_detail->chip_event_fn)
      chip->chip_detail->chip_event_fn (sim, chip, event);
}


const chip_detail_t *get_chip_detail (chip_t *chip)
{
  return chip->chip_detail;
}


void *get_chip_data (chip_t *chip)
{
  return chip->chip_data;
}
