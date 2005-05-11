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


// We try to schedule execution in "jiffies".
#define JIFFY_PER_SEC 30

#define JIFFY_USEC (1.0e6 / JIFFY_PER_SEC)


// Don't try to execute more than MAX_INST_BURST instructions per
// jiffy.  If we can't, we'll just fall behind.
#define MAX_INST_BURST 5000


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
  int           arg1;   // keycode, flag number, chip_num, etc.
  int           arg2;   // reg_num
  int           arg3;   // index (in read/write register)
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


// Storage size in bytes for register values of a particular
// number of bits
// Each entry is (log2(n) + 1) / 8
static int storage_size [65] =
{
  0, 1, 1, 1, 1, 1, 1, 1,
  1, 2, 2, 2, 2, 2, 2, 2,
  2, 4, 4, 4, 4, 4, 4, 4,
  4, 4, 4, 4, 4, 4, 4, 4,
  4, 8, 8, 8, 8, 8, 8, 8,
  8, 8, 8, 8, 8, 8, 8, 8,
  8, 8, 8, 8, 8, 8, 8, 8,
  8, 8, 8, 8, 8, 8, 8, 8,
  8
};


/*
 * allocate space for microcode ROM, as well as source code and breakpoints.
 * Set breakpoints at every location so we know if we hit uninitialized ROM.
 */
static void allocate_ucode (sim_t *sim)
{
  int size, i;

  size = sim->proc->max_bank * sim->proc->max_rom;

  sim->ucode      = alloc (size * sizeof (rom_word_t));
  sim->source     = alloc (size * sizeof (char *));
  sim->breakpoint = alloc (size * sizeof (bool));

  for (i = 0; i < size; i++)
    sim->breakpoint [i] = true;
}


bool sim_read_object_file (sim_t *sim, char *fn)
{
  FILE *f;
  int bank, i;
  int addr;  // should change to addr_t, but will have to change
             // the parse function profiles to match.
  rom_word_t opcode;
  int count = 0;
  char buf [80];

  f = fopen (fn, "r");
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
	  i = bank * sim->proc->max_rom + addr;
	  if (! sim->breakpoint [i])
	    {
	      fprintf (stderr, "duplicate object code for bank %d address %o\n",
		       bank, addr);
	      // fprintf (stderr, "orig: %s\n", sim->source [i]);
	      fprintf (stderr, "dup:  %s\n", buf);
	    }
	  sim->ucode      [i] = opcode;
	  sim->breakpoint [i] = 0;
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
	  if (sim->breakpoint [i])
	    {
	      fprintf (stderr, "listing line for which there was no code in object file, bank %d address %o\n",
		       bank, addr);
	      fprintf (stderr, "src: %s\n", sim->source [i]);
	    }
	  if (sim->ucode [i] != opcode)
	    {
	      fprintf (stderr, "listing line for which object code does not match object file, bank %d address %o\n",
		       bank, addr);
	      fprintf (stderr, "src: %s\n", sim->source [i]);
	      fprintf (stderr, "object file: %04o\n", sim->ucode [i]);
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
  chip_detail_t *chip_detail;
  reg_detail_t *reg_detail;
  size_t size;
  uint8_t *addr;
  uint64_t *result_val;

  msg->reply = ARG_RANGE_ERROR;

  if (msg->arg1 >= sim->proc->max_chip_count)
    return;
  chip_detail = sim->chip_detail [msg->arg1];
  if (! chip_detail)
    return;
  if (msg->arg2 >= chip_detail->reg_count)
    return;
  reg_detail = & chip_detail->reg_detail [msg->arg2];
  if (msg->arg3 >= reg_detail->info.array_element_count)
    return;

  size = storage_size [reg_detail->info.element_bits];
  addr = ((uint8_t *) sim->chip_data [msg->arg1]) + reg_detail->offset + msg->arg3 * size;
  result_val = msg->data;

  if (reg_detail->get)
    {
      if (reg_detail->get (addr,
			   reg_detail->offset,
			   result_val))
	msg->reply = OK;
    }
  else
    {
      switch (size)
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
  chip_detail_t *chip_detail;
  reg_detail_t *reg_detail;
  size_t size;
  uint8_t *addr;
  uint64_t *source_val;

  msg->reply = ARG_RANGE_ERROR;

  if (msg->arg1 >= sim->proc->max_chip_count)
    return;
  chip_detail = sim->chip_detail [msg->arg1];
  if (! chip_detail)
    return;
  if (msg->arg2 >= chip_detail->reg_count)
    return;
  reg_detail = & chip_detail->reg_detail [msg->arg2];
  if (msg->arg3 >= reg_detail->info.array_element_count)
    return;

  size = storage_size [reg_detail->info.element_bits];
  addr = ((uint8_t *) sim->chip_data [msg->arg1]) + reg_detail->offset + msg->arg3 * size;
  source_val = msg->data;

  if (reg_detail->set)
    {
      if (reg_detail->set (addr,
			   reg_detail->offset,
			   source_val))
	msg->reply = OK;
    }
  else
    {
      switch (size)
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
    case CMD_READ_ROM:
      break;
    case CMD_WRITE_ROM:
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
      gui_display_update (sim);
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

  switch (msg->cmd)
    {
    case CMD_DISPLAY_UPDATE:
      display_update (msg->display_digits, msg->display_segments);
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
		  segment_bitmap_t *char_gen)
{
  sim_t *sim;
  model_info_t *model_info = get_model_info (model);
  arch_info_t *arch_info;

  sim = alloc (sizeof (sim_t));
  sim->thread_vars = alloc (sizeof (sim_thread_vars_t));

  sim->model = model;

  sim->platform = model_info->platform;

  arch_info = get_arch_info (model_info->cpu_arch);
  sim->arch = model_info->cpu_arch;
  sim->proc = processor_dispatch [model_info->cpu_arch];

  sim->words_per_usec = clock_frequency / (1.0e6 * arch_info->word_length);

  g_thread_init (NULL);  /* $$$ has Gtk already done this? */

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

  sim->chip_detail = alloc (sim->proc->max_chip_count * sizeof (chip_detail_t *));
  sim->chip_data = alloc (sim->proc->max_chip_count * sizeof (void *));

  sim->proc->new_processor (sim, ram_size);

  allocate_ucode (sim);

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

  // $$$ should wait for thread exit here

  sim->proc->free_processor (sim);

  free (sim->chip_detail);
  free (sim->chip_data);
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


int sim_get_max_chip_count (sim_t *sim)
{
  return sim->proc->max_chip_count;
}


chip_info_t *sim_get_chip_info (sim_t *sim,
				int   chip_num)
{
  chip_detail_t *chip_detail;

  if (chip_num >= sim->proc->max_chip_count)
    return NULL;
  chip_detail = sim->chip_detail [chip_num];
  if (! chip_detail)
    return NULL;
  return & chip_detail->info;
}


int sim_get_reg_count (sim_t *sim, int chip_num)
{
  chip_detail_t *chip_detail;

  if (chip_num >= sim->proc->max_chip_count)
    return 0;

  chip_detail = sim->chip_detail [chip_num];
  if (! chip_detail)
    return 0;

  return chip_detail->reg_count;
}


int sim_find_register (sim_t *sim,
		       int   chip_num,
		       char  *name)
{
  int reg_num;
  chip_detail_t *chip_detail;

  if (chip_num >= sim->proc->max_chip_count)
    return -1;

  chip_detail = sim->chip_detail [chip_num];
  if (! chip_detail)
    return -1;

  for (reg_num = 0; reg_num < chip_detail->reg_count; reg_num++)
    {
      if (strcmp (name, chip_detail->reg_detail [reg_num].info.name) == 0)
	return reg_num;
    }

  return -1;
}


reg_info_t *sim_get_register_info (sim_t *sim,
				   int   chip_num,
				   int   reg_num)
{
  chip_detail_t *chip_detail;

  if (chip_num >= sim->proc->max_chip_count)
    return 0;

  chip_detail = sim->chip_detail [chip_num];
  if (! chip_detail)
    return 0;

  if (reg_num >= chip_detail->reg_count)
    return NULL;

  return & chip_detail->reg_detail [reg_num].info;
}


bool sim_read_register (sim_t   *sim,
			int     chip_num,
			int     reg_num,
			int     index,
			uint64_t *val)
{
  sim_msg_t msg;
  chip_detail_t *chip_detail;

  if (chip_num >= sim->proc->max_chip_count)
    return false;

  chip_detail = sim->chip_detail [chip_num];
  if (! chip_detail)
    return false;

  if (reg_num >= chip_detail->reg_count)
    return false;

  memset (& msg, 0, sizeof (sim_msg_t));
  msg.arg1 = chip_num;
  msg.arg2 = reg_num;
  msg.arg3 = index;
  msg.data = val;
  msg.cmd = CMD_READ_REGISTER;
  send_cmd_to_sim_thread (sim, (gpointer) & msg);
  return (msg.reply == OK);
}


bool sim_write_register (sim_t   *sim,
			 int     chip_num,
			 int     reg_num,
			 int     index,
			 uint64_t *val)
{
  sim_msg_t msg;
  chip_detail_t *chip_detail;

  if (chip_num >= sim->proc->max_chip_count)
    return false;

  chip_detail = sim->chip_detail [chip_num];
  if (! chip_detail)
    return false;

  if (reg_num >= chip_detail->reg_count)
    return false;

  memset (& msg, 0, sizeof (sim_msg_t));
  msg.arg1 = chip_num;
  msg.arg2 = reg_num;
  msg.arg3 = index;
  msg.data = val;
  msg.cmd = CMD_WRITE_REGISTER;
  send_cmd_to_sim_thread (sim, (gpointer) & msg);
  return (msg.reply == OK);
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


void gui_display_update (sim_t *sim)
{
  gui_msg_t *msg;

  msg = g_async_queue_try_pop (sim->thread_vars->gui_cmd_free_q);
  if (! msg)
    msg = alloc (sizeof (gui_msg_t));

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
bool get_14_dig (void *data, size_t offset, uint64_t *p)
{
  uint64_t val = 0;
  uint8_t *d;
  int i;

  d = ((uint8_t *) data) + offset + 14;
  for (i = 0; i < 14; i++)
    val = (val << 4) + *(--d);

  *p = val;

  return true;
}


bool set_14_dig (void *data, size_t offset, uint64_t *p)
{
  uint64_t val = *p;
  uint8_t *d;
  int i;

  d = ((uint8_t *) data) + offset;
  for (i = 0; i < 14; i++)
    {
      *(d++) = val & 0x0f;
      val >>= 4;
    }

  return true;
}


bool get_2_dig (void *data, size_t offset, uint64_t *p)
{
  uint8_t val = 0;
  uint8_t *d;
  int i;

  d = ((uint8_t *) data) + offset + 2;
  for (i = 0; i < 2; i++)
    val = (val << 4) + *(--d);

  *p = val;

  return true;
}


bool set_2_dig (void *data, size_t offset, uint64_t *p)
{
  uint8_t val = *p;
  uint8_t *d;
  int i;

  d = ((uint8_t *) data) + offset;
  for (i = 0; i < 2; i++)
    {
      *(d++) = val & 0x0f;
      val >>= 4;
    }

  return true;
}


int install_chip (sim_t *sim,
		  int chip_num,
		  chip_detail_t *chip_detail,
		  void *chip_data)
{
  if (chip_num < 0)
    {
      for (chip_num = 0; chip_num < sim->proc->max_chip_count; chip_num++)
	if (! sim->chip_detail [chip_num])
	  break;
    }

  if ((chip_num >= sim->proc->max_chip_count) || sim->chip_detail [chip_num])
    return -1;

  sim->chip_detail [chip_num] = chip_detail;
  sim->chip_data   [chip_num] = chip_data;

  return chip_num;
}


bool remove_chip (sim_t *sim,
		  int chip_num)
{
  if (! sim->chip_detail [chip_num])
    return false;

  free (sim->chip_detail [chip_num]);
  sim->chip_detail [chip_num] = NULL;

  free (sim->chip_data [chip_num]);
  sim->chip_data [chip_num] = NULL;

  return true;
}


void chip_event (sim_t *sim, int event)
{
  int chip_num;

  for (chip_num = 0; chip_num < sim->proc->max_chip_count; chip_num++)
    if (sim->chip_detail [chip_num] && sim->chip_detail [chip_num]->chip_event_fn)
      sim->chip_detail [chip_num]->chip_event_fn (sim, chip_num, event);
}
