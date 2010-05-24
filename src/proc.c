/*
$Id$
Copyright 1995, 2004-2008, 2010 Eric Smith <eric@brouhaha.com>

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

#include <inttypes.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <glib.h>

#include <libxml/SAX.h>

#include "util.h"
#include "display.h"
#include "keyboard.h"
#include "chip.h"
#include "calcdef.h"
#include "proc.h"
#include "arch.h"
#include "platform.h"
#include "mod1_file.h"
#include "proc_int.h"
#include "glib_async_queue_source.h"
#include "helios.h"
#include "phineas.h"
#include "printer.h"


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

  plugin_module_t *module;

  const chip_detail_t *chip_detail;
  void *chip_data;

  chip_callback_fn_t *callback_fn;
  void               *callback_ref;
};


// Messages sent from GUI thread to simulator thread, and
// sent back as replies.

typedef enum
{
  CMD_NONE,
  CMD_ADD_CHIP,
  CMD_REMOVE_CHIP,
  CMD_EVENT,
  CMD_QUIT,
  CMD_GET_IO_PAUSE_FLAG,
  CMD_SET_IO_PAUSE_FLAG,
  CMD_WRITE_REGISTER,
  CMD_READ_REGISTER,
  CMD_SET_BANK_GROUP,
  CMD_WRITE_ROM,
  CMD_READ_ROM,
  CMD_SET_ROM_WRITE_ENABLE,
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
  sim_cmd_t       cmd;
  sim_reply_t     reply;
  bool            b;
  uint64_t        cycle_count;
  addr_t          addr;
  plugin_module_t *module;
  chip_type_t     chip_type;
  chip_t          *chip;
  event_id_t      event;
  int32_t         arg1;   // reg_num, keycode, flag number, bank, bank group, etc.
  int32_t         arg2;   // index (in read/write register)
  void            *data;  // register value, memory value, etc.
} sim_msg_t;


// Messages sent from simulator thread to GUI thread, for display
// updates, breakpoint notification, and the like.  There are no replies,
// though the messages get recycled through a free queue.

typedef enum
{
  CMD_DISPLAY_UPDATE,
  CMD_CHIP_ASYNC_MSG,
  CMD_DEBUG_TRACE_MSG,
  CMD_BREAKPOINT_HIT
} gui_cmd_t;

typedef struct
{
  sim_t            *sim;
  gui_cmd_t        cmd;
  chip_t           *chip;
  void             *data;
  union
  {
    struct
    {
      int              display_digits;
      segment_bitmap_t display_segments [MAX_DIGIT_POSITION];
    };
  };
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
				    bank_t bank,
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


static bool sim_read_mod1_page (sim_t           *sim,
				plugin_module_t *module,
				FILE            *f,
				int port)  // 1 to 4, -1 for not port-based
{
  mod1_file_page_t mod1_page;
  uint8_t page;
  bank_t bank;
  addr_t addr;
  int i;

  if (! mod1_read_page (f, & mod1_page))
    {
      fprintf (stderr, "Can't read MOD1 page\n");
      return false;
    }

  if (! mod1_validate_page (& mod1_page))
    {
      fprintf (stderr, "Unrecognized or inconsistent values in MOD1 page\n");
      return false;
    }

  bank = mod1_page.Bank - 1;

  if (mod1_page.Page <= 0x07)
    page = mod1_page.Page;
  else if (mod1_page.Page <= 0x0f)
    {
      if ((port != -1) && (((mod1_page.Page - 8) / 2) != (port - 1)))
	{
	  fprintf (stderr, "Module not compatible with specified port\n");
	  return false;
	}
      page = mod1_page.Page;
    }
  else if (mod1_page.Page == POSITION_ANY)
    {
      if (port == -1)
	page = 8;
      else
	page = 8 + 2 * (port - 1);
      if (sim_get_page_info (sim, mod1_page.Bank - 1, page, NULL, NULL, NULL))
	page++;
    }
  else if ((mod1_page.Page == POSITION_EVEN) ||
	   (mod1_page.Page == POSITION_LOWER))
    {
      if (port == -1)
	page = 8;
      else
	page = 8 + 2 * (port - 1);
    }
  else if ((mod1_page.Page == POSITION_ODD) ||
	   (mod1_page.Page == POSITION_UPPER))
    {
      if (port == -1)
	page = 9;
      else
	page = 9 + 2 * (port - 1);
    }
  else
    {
      fprintf (stderr, "Unsupported ROM page location in MOD1 file\n");
      return false;
    }

  if ((bank == 0) &&
      mod1_page.RAM && 
      sim_get_page_info (sim, bank, page, NULL, NULL, NULL))
    {
      // HEPAX RAM overlaid by ROM
      bank = 4;  // HIDDEN_BANK, which isn't visible here, alas
    }

  if (! sim_create_page (sim, bank, page, mod1_page.RAM, module))
    {
      fprintf (stderr, "Can't load ROM page as bank %d page %x, address space occupied\n", bank + 1, page);
      return false;
    }

  addr = page << 12;

  if (mod1_page.BankGroup)
    {
      if (! bank_group [mod1_page.BankGroup])
	bank_group [mod1_page.BankGroup] = sim_create_bank_group (sim);
      sim_set_bank_group (sim, bank_group [mod1_page.BankGroup], addr);
    }

  for (i = 0; i < 5120; i += 5)
    {
      rom_word_t data;

      data = (((mod1_page.Image [i + 1] & 0x03) << 8) |
	      (mod1_page.Image [i]));
      if (! sim_load_mod1_rom_word (sim, bank, addr++, data))
				    
        return false;

      data = (((mod1_page.Image [i + 2] & 0x0f) << 6) |
	      ((mod1_page.Image [i + 1] & 0xfc) >> 2));
      if (! sim_load_mod1_rom_word (sim, bank, addr++, data))
				    
        return false;

      data = (((mod1_page.Image [i + 3] & 0x3f) << 4) |
	      ((mod1_page.Image [i + 2] & 0xf0) >> 4));
      if (! sim_load_mod1_rom_word (sim, bank, addr++, data))
				    
        return false;

      data = ((mod1_page.Image [i + 4] << 2) |
	      ((mod1_page.Image [i + 3] & 0xc0) >> 6));
      if (! sim_load_mod1_rom_word (sim, bank, addr++, data))
				    
        return false;
    }

  addr = page << 12;

  // write-enable the page only if page in mod1 file is marked as both RAM
  // and not write protected
  sim_set_rom_write_enable (sim,
			    bank,
			    addr,
			    mod1_page.RAM && ! mod1_page.WriteProtect);

  return true;
}


static bool sim_read_mod1_file (sim_t              *sim,
				plugin_module_t    *module,
				FILE               *f,
				int port,   // 1..4, -1 for not port-based
				bool               mem_only,
				mod1_file_header_t *header)
{
  size_t file_size;
  int i;

  for (i = 1; i <= MAX_BANK_GROUP; i++)
    bank_group [i] = 0;

  fseek (f, 0, SEEK_END);
  file_size = ftell (f);
  fseek (f, 0, SEEK_SET);

  if (! mod1_read_file_header (f, header))
    {
      fprintf (stderr, "Can't read MOD1 file header\n");
      return false;
    }

  if (! mod1_validate_file_header (header, file_size))
    {
      fprintf (stderr, "Unrecognized or inconsistent values in MOD1 file header\n");
      return false;
    }

  for (i = 0; i < header->NumPages; i++)
    if (! sim_read_mod1_page (sim, module, f, port))
      return false;

  if (mem_only)
    return true;

  switch (header->Hardware)
    {
    case HARDWARE_NONE:
      break;

    case HARDWARE_TIMER:
      (void) sim_add_chip (sim,
			   module,
			   CHIP_PHINEAS,
			   0,  // index
			   0,  // flags
			   NULL,
			   NULL);
      break;

    case HARDWARE_PRINTER:
      (void) gui_printer_install (sim,
				  module,
				  CHIP_HELIOS,
				  0,   // index
				  (HAS_PAPER_ADVANCE_BUTTON +
				   HAS_PRINT_BUTTON +
				   HAS_MODE_SWITCH));
      break;

    case HARDWARE_HEPAX:
      (void) sim_add_chip (sim,
			   module,
			   CHIP_HEPAX,
			   port,  // index - use for HEPAX port #
			   0,  // flags
			   NULL,
			   NULL);
      break;

    default:
      if ((header->Hardware <= HARDWARE_MAX) &&
	  mod1_hardware_name [header->Hardware])
	fprintf (stderr, "Unsupported hardware: %s\n",
		 mod1_hardware_name [header->Hardware]);
      else
	fprintf (stderr, "Unsupported hardware type %d\n",
		 header->Hardware);
#if 1
      break;  // for debugging, allow unsupported hardware
#else
      return false;
#endif
    }

  return true;
}


#if 0
bool sim_read_object_file (sim_t *sim, char *fn)
{
  FILE *f;
  bank_t bank;
  bank_mask_t bank_mask;
  addr_t addr;
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

  if (fread_bytes (f, magic, sizeof (magic), & eof, & error) != sizeof (magic))
    {
      fprintf (stderr, "error reading object file\n");
      return (false);
    }

  if (strncmp (magic, "MOD1", sizeof (magic)) == 0)
    return sim_read_mod1_file (sim, f, -1, false);

  // switch from binary to text mode, and rewind

#if 0
  f = freopen (NULL, "r", f);
#else
  // Apparently many C libraries, including those from FreeBSD and Microsoft
  // have freopen() implementations that are non-compliant with the
  // C standard, which allows NULL for the filename if you're reopening an
  // existing file handle.
  f = freopen (fn, "r", f);
#endif
  if (! f)
    {
      fprintf (stderr, "error reopening object file\n");
      return (false);
    }

  while (fgets (buf, sizeof (buf), f))
    {
      trim_trailing_whitespace (buf);
      if (! buf [0])
	continue;
      if (sim->proc->parse_object_line (buf, & bank_mask, & addr, & opcode))
	{
	  for (bank = 0; bank < sim->proc->get_max_rom_bank (sim); bank++)
	    if (bank_mask & (1 << bank))
	      {
		if (! sim_write_rom (sim, bank, addr, & opcode))
		  fatal (3, "can't load ROM word at bank %d address %o\n", bank, addr);
	      }
	  count++;
	}
    }

#if 1
  fprintf (stderr, "read %d words from '%s'\n", count, fn);
#endif
  return (true);
}
#endif


bool sim_read_listing_file (sim_t *sim, char *fn)
{
  FILE *f;
  bank_t bank;
  bank_mask_t bank_mask;
  addr_t addr;
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
      if (sim->proc->parse_listing_line (buf, & bank_mask, & addr, & opcode))
	{
	  for (bank = 0; bank < sim->proc->get_max_rom_bank (sim); bank++)
	    if (bank_mask & (1 << bank))
	      {
		int i = bank * sim->proc->get_rom_page_size (sim) + addr;
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
	      }
	  count++;
	}
    }

#if 0
  fprintf (stderr, "read %d words from '%s'\n", count, fn);
#endif
  return (true);
}


struct plugin_module_t
{
  struct plugin_module_t *next;
  struct plugin_module_t *prev;
  char *path;
  char *name;
  int port;
  chip_t *chip;
  mod1_file_header_t header;
};

plugin_module_t *plugin_module_get_by_port (sim_t *sim,
					    int port)
{
  plugin_module_t *module;

  for (module = sim->first_module; module; module = module->next)
    {
      if (module->port == port)
	return module;
    }
  return NULL;
}

int plugin_module_get_port (plugin_module_t *module)
{
  return module->port;
}

char *plugin_module_get_path (plugin_module_t *module)
{
  return module->path;
}

char *plugin_module_get_name (plugin_module_t *module)
{
  return module->name;
}


plugin_module_t *sim_install_module (sim_t *sim,
				     char *fn,
				     int port,
				     bool mem_only)
{
  FILE *f;
  plugin_module_t *module;

  f = fopen (fn, "rb");
  if (! f)
    return false;

  module = alloc (sizeof (plugin_module_t));

  if (! sim_read_mod1_file (sim, module, f, port, mem_only, & module->header))
    {
      free (module);
      fclose (f);
      return NULL;
    }

  fclose (f);

  module->path = newstr (fn);

  module->name = newstrn (module->header.Title,
			  sizeof (module->header.Title));

  module->port = port;

  // add module at tail of list
  if (sim->last_module)
    {
      module->prev = sim->last_module;
      sim->last_module->next = module;
    }
  else
    sim->first_module = module;

  sim->last_module = module;

  return module;
}


bool sim_remove_module (sim_t *sim,
			plugin_module_t *module)
{
  chip_t * chip;
  plugin_module_t *m2;
  int page, max_page;
  int page_size;
  int bank, max_bank;

  max_bank = sim_get_max_rom_bank (sim);
  page_size = sim_get_rom_page_size (sim);
  max_page = sim_get_max_rom_addr (sim) / page_size;

  for (chip = sim->first_chip; chip; chip = chip->next)
    {
      chip_t *next_chip = chip->next;
      if (chip->module != module)
	continue;
      sim_remove_chip (sim, chip);
      chip = next_chip;
    }

  // $$$ remove RAM

  // remove ROM
  for (page = 0; page < max_page; page++)
    for (bank = 0; bank < max_bank; bank++)
      if (sim_get_page_info (sim, bank, page, & m2, NULL, NULL) &&
	  (m2 == module))
	sim_destroy_page (sim, bank, page);

  if (module->name)
    free (module->name);
  free (module);

  return false;  // $$$ not yet implemented
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


static void cmd_read_register (sim_t     *sim,
			       sim_msg_t *msg)
{
  const chip_detail_t *chip_detail;
  const reg_detail_t *reg_detail;
  uint8_t *addr;
  uint64_t *result_val;
  reg_accessor_t *get_fn;

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
    get_fn = reg_detail->get;
  else
    get_fn = & get_reg;

  if (get_fn (sim,
	      msg->chip,
	      addr,
	      reg_detail->size,
	      result_val,
	      reg_detail->accessor_arg))
    msg->reply = OK;
}


static void cmd_write_register (sim_t     *sim,
				sim_msg_t *msg)
{
  const chip_detail_t *chip_detail;
  const reg_detail_t *reg_detail;
  uint8_t *addr;
  uint64_t *source_val;
  reg_accessor_t *set_fn;

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
    set_fn = reg_detail->set;
  else
    set_fn = & set_reg;

  if (set_fn (sim,
	      msg->chip,
	      addr,
	      reg_detail->size,
	      source_val,
	      reg_detail->accessor_arg))
    msg->reply = OK;
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


static void cmd_set_rom_write_enable (sim_t *sim, sim_msg_t *msg)
{
  if (! sim->proc->set_rom_write_enable)
    msg->reply = UNIMPLEMENTED;
  else if (sim->proc->set_rom_write_enable (sim, 
					    msg->arg1,   // bank
					    msg->addr,   // addr
					    msg->b))     // write_enable
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


static void cmd_event (sim_t *sim, sim_msg_t *msg)
{
  chip_event (sim,
	      msg->chip,
	      msg->event,
	      msg->arg1,
	      msg->arg2,
	      msg->data);
}


plugin_module_t *chip_get_module (chip_t *chip)
{
  return chip->module;
}


static void cmd_add_chip (sim_t *sim, sim_msg_t *msg)
{
  chip_type_info_t *chip_type_info;

  msg->reply = ARG_RANGE_ERROR;
  msg->chip = NULL;

  chip_type_info = get_chip_type_info (msg->chip_type);

  if (chip_type_info->chip_install_fn)
    {
      msg->chip = chip_type_info->chip_install_fn (sim,
						   msg->module,
						   msg->chip_type,
						   msg->arg1,  // index
						   msg->arg2); // flags
    }
  else
    fatal (3, "don't know how to add chip of type %d\n", msg->chip_type);

  if (msg->chip)
    msg->reply = OK;
}


static void cmd_remove_chip (sim_t *sim,
			     sim_msg_t *msg)
{
  // send chip event
  chip_event (sim, msg->chip, event_remove_chip, 0, 0, NULL);

  // free chip structure
  remove_chip (msg->chip);

  msg->reply = OK;
}


sim_cmd_t current_sim_cmd;  // debug


static void handle_sim_cmd (sim_t *sim, sim_msg_t *msg)
{
  current_sim_cmd = msg->cmd;
  msg->reply = UNIMPLEMENTED;
  switch (msg->cmd)
    {
    case CMD_ADD_CHIP:
      cmd_add_chip (sim, msg);
      break;
    case CMD_REMOVE_CHIP:
      cmd_remove_chip (sim, msg);
      break;
    case CMD_EVENT:
      cmd_event (sim, msg);
      msg->reply = OK;
      break;
    case CMD_QUIT:
      sim->quit_flag = true;
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
    case CMD_SET_ROM_WRITE_ENABLE:
      cmd_set_rom_write_enable (sim, msg);
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
#if 1 || defined(HAS_DEBUGGER)
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
    case CMD_GET_DISPLAY_UPDATE:
      sim_send_display_update_to_gui (sim);
      msg->reply = OK;
      break;
    default:
      msg->reply = BAD_CMD;
    }
  g_async_queue_push (sim->thread_vars->reply_q, msg);
  current_sim_cmd = CMD_NONE;
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
    case CMD_CHIP_ASYNC_MSG:
      if (msg->chip->callback_fn)
	msg->chip->callback_fn (sim,
				msg->chip,
				msg->chip->callback_ref,
				msg->data);
      break;
    case CMD_DEBUG_TRACE_MSG:
      if (sim->debug_trace_callback)
	sim->debug_trace_callback (sim->debug_trace_callback_ref,
				   msg->data);
      break;
    case CMD_BREAKPOINT_HIT:
      break;
    }
  return (true);
}


// Called by GUI thread to create a simulator thread
// $$$ Some of the initialization here should be moved into
// the thread function.

sim_t *sim_init  (char *ncd_fn,
		  display_update_callback_fn_t *display_update_callback,
		  void *display_update_callback_ref)
{
  sim_t *sim;
  arch_info_t *arch_info;

  sim = alloc (sizeof (sim_t));
  sim->thread_vars = alloc (sizeof (sim_thread_vars_t));

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

  // save display callback info
  sim->display_update_callback = display_update_callback;
  sim->display_update_callback_ref = display_update_callback_ref;

  sim->ncd_fn = ncd_fn;

  sim->calcdef = calcdef_load (sim, sim->ncd_fn);

  sim->platform = calcdef_get_platform (sim->calcdef);
  sim->arch = calcdef_get_arch (sim->calcdef);
  sim->arch_flags = calcdef_get_arch_variant (sim->calcdef);

  sim->proc = processor_dispatch [sim->arch];

  arch_info = get_arch_info (sim->arch);
  sim->words_per_usec = calcdef_get_clock_frequency (sim->calcdef) / (1.0e6 * arch_info->word_length);

  sim->proc->new_processor (sim);

  sim->cycle_count = 0;  // $$$ necessary?

  // $$$ sim->source = alloc (sim->proc->max_bank * sim->proc->max_rom * sizeof (char *));

  sim->thread_vars->gthread = g_thread_create (sim_thread_func, sim, TRUE, NULL);

  calcdef_init_chips (sim->calcdef);

  return (sim);
}


void sim_init_debug_trace_callback (sim_t *sim,
				    debug_trace_callback_fn_t *debug_trace_callback,
				    void *debug_trace_callback_ref)
{
  sim->debug_trace_callback_ref = debug_trace_callback_ref;
  sim->debug_trace_callback = debug_trace_callback;
}


calcdef_t *sim_get_calcdef (sim_t *sim)
{
  return sim->calcdef;
}

int sim_get_arch (sim_t *sim)
{
  return sim->arch;
}

const char *sim_get_model_name (sim_t *sim)
{
  return calcdef_get_model_name (sim->calcdef);
}

const char *sim_get_ncd_fn (sim_t *sim)
{
  return sim->ncd_fn;
}


void sim_event (sim_t      *sim,
		chip_t     *chip,
		event_id_t event,
		int        arg1,
		int        arg2,
		void       *data)
{
  sim_msg_t msg;

  memset (& msg, 0, sizeof (sim_msg_t));
  msg.cmd = CMD_EVENT;
  msg.chip = chip;
  msg.event = event;
  msg.arg1 = arg1;
  msg.arg2 = arg2;
  msg.data = data;
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
  sim_event (sim, NULL, event_reset, 0, 0, NULL);
}


void sim_clear_memory (sim_t *sim)
{
  sim_event (sim, NULL, event_clear_memory, 0, 0, NULL);
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


// Pass in NULL for module to get first module.
// Returns NULL if there are no more modules.
plugin_module_t *sim_get_next_module (sim_t *sim, plugin_module_t *module)
{
  if (module)
    return module->next;
  else
    return sim->first_module;
}


chip_t *sim_add_chip (sim_t              *sim,
		      plugin_module_t    *module,
		      chip_type_t        type,
		      int                index,
		      int                flags,
		      chip_callback_fn_t *callback_fn,
		      void               *callback_ref)
{
  sim_msg_t msg;

  memset (& msg, 0, sizeof (sim_msg_t));
  msg.cmd = CMD_ADD_CHIP;
  msg.module = module;
  msg.chip_type = type;
  msg.arg1 = index;
  msg.arg2 = flags;
  send_cmd_to_sim_thread (sim, (gpointer) & msg);
  if ((msg.reply == OK) && msg.chip)
    {
      msg.chip->callback_fn  = callback_fn;
      msg.chip->callback_ref = callback_ref;
      return (msg.chip);
    }
  return NULL;
}


bool sim_remove_chip (sim_t  *sim,
		      chip_t *chip)
{
  sim_msg_t msg;

  memset (& msg, 0, sizeof (sim_msg_t));
  msg.cmd = CMD_REMOVE_CHIP;
  msg.chip = chip;
  send_cmd_to_sim_thread (sim, (gpointer) & msg);
  return (msg.reply  == OK);
}


// Pass in NULL for chip to get first chip.
// Returns NULL if there are no more chips.
chip_t *sim_get_next_chip (sim_t *sim, chip_t *chip)
{
  if (chip)
    return chip->next;
  else
    return sim->first_chip;
}


// Returns NULL if it can't find a chip with the specified name
// (and address for chips that support multiple instances).
chip_t *sim_find_chip (sim_t *sim,
		       const char *name,
		       uint64_t addr UNUSED)
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


const chip_info_t *sim_get_chip_info (sim_t *sim UNUSED,
				      chip_t *chip)
{
  return & chip->chip_detail->info;
}


int sim_get_reg_count (sim_t *sim UNUSED,
		       chip_t *chip)
{
  return chip->chip_detail->reg_count;
}


int sim_find_register (sim_t *sim UNUSED,
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


const reg_info_t *sim_get_register_info (sim_t *sim UNUSED,
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
int sim_create_bank_group (sim_t *sim UNUSED)
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
int sim_get_max_rom_bank  (sim_t *sim)
{
  return sim->proc->get_max_rom_bank (sim);
}

int sim_get_rom_page_size (sim_t *sim)
{
  return sim->proc->get_rom_page_size (sim);
}

int sim_get_max_rom_addr  (sim_t *sim)
{
  return sim->proc->get_max_rom_addr (sim);
}

bool sim_create_page      (sim_t           *sim,
			   uint8_t         bank,
			   uint8_t         page,
			   bool            ram,
			   plugin_module_t *module)
{
  return sim->proc->create_page (sim, bank, page, ram, module);
}

bool sim_destroy_page      (sim_t           *sim,
			    uint8_t         bank,
			    uint8_t         page)
{
  return sim->proc->destroy_page (sim, bank, page);
}

bool sim_get_page_info    (sim_t           *sim,
			   uint8_t         bank,
			   uint8_t         page,
			   plugin_module_t **module,
			   bool            *ram,
			   bool            *write_enable)
{
  return sim->proc->get_page_info (sim, bank, page, module, ram, write_enable);
}

bool sim_read_rom  (sim_t      *sim,
		    uint8_t    bank,
		    addr_t     addr,
		    rom_word_t *val)
{
#if 1
  // Disgusting hack to avoid deadlock when simulation thread is tracing
  // and calls disassembler, which calls sim_read_rom().  Can't send
  // message to sim thread since we're it.  But by doing this, we've
  // potentially lost atomicity.
  return sim->proc->read_rom (sim, bank, addr, val);
#else
  sim_msg_t msg;
  memset (& msg, 0, sizeof (sim_msg_t));
  msg.arg1 = bank;
  msg.addr = addr;
  msg.data = val;
  msg.cmd = CMD_READ_ROM;
  send_cmd_to_sim_thread (sim, (gpointer) & msg);
  return (msg.reply == OK);
#endif
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

bool sim_set_rom_write_enable (sim_t   *sim,
			       bank_t  bank,
			       addr_t  addr,
			       bool    write_enable)
{
  sim_msg_t msg;
  memset (& msg, 0, sizeof (sim_msg_t));
  msg.arg1 = bank;
  msg.addr = addr;
  msg.b = write_enable;
  msg.cmd = CMD_SET_ROM_WRITE_ENABLE;
  send_cmd_to_sim_thread (sim, (gpointer) & msg);
  return (msg.reply == OK);
}


addr_t sim_get_max_ram_addr (sim_t *sim)
{
  return sim->proc->get_max_ram_addr (sim);
}


bool sim_create_ram (sim_t *sim,
		     addr_t addr,
		     addr_t size)
{
  return sim->proc->create_ram (sim, addr, size);
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


void sim_key (sim_t *sim, int keycode, bool state)
{
  hw_keycode_t hw_keycode;
  chip_t *chip;

  calcdef_get_key (sim->calcdef,
		   keycode,
		   & chip,
		   & hw_keycode);

  sim_event (sim,
	     chip ? chip : sim->first_chip,  // if NULL, first chip only
	     event_key,
	     hw_keycode,
	     state,
	     NULL);
}


bool sim_set_switch (sim_t *sim,
		     uint8_t sw,
		     uint8_t position)
{
  int i;
  chip_t *chip;
  int flag;
  int value;

  if ((sw >= MAX_SWITCH) ||
      (position >= MAX_SWITCH_POSITION))
    return false;

  sim->switch_position [sw] = position;
  i = 0;
  while (calcdef_get_switch_position_flag (sim->calcdef,
					   sw,
					   position,
					   i++,
					   & chip,
					   & flag,
					   & value))
    {
      sim_event (sim,
		 chip ? chip : sim->first_chip,  // if NULL, first chip only
		 event_set_flag,
		 flag,
		 value,
		 NULL);
    }

  return true;
}


bool sim_get_switch (sim_t *sim,
		     uint8_t sw,
		     uint8_t *position)
{
  if (sw >= MAX_SWITCH)
    return false;

  *position = sim->switch_position [sw];
  return true;
}


void sim_get_display_update (sim_t *sim)
{
  sim_msg_t msg;
  memset (& msg, 0, sizeof (sim_msg_t));
  msg.cmd = CMD_GET_DISPLAY_UPDATE;
  send_cmd_to_sim_thread (sim, (gpointer) & msg);
}


#if 1 || defined(HAS_DEBUGGER)
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


void sim_send_chip_msg_to_gui (sim_t  *sim,
			       chip_t *chip,
			       void   *data)
{
  gui_msg_t *msg;

  msg = g_async_queue_try_pop (sim->thread_vars->gui_cmd_free_q);
  if (! msg)
    msg = alloc (sizeof (gui_msg_t));

  msg->sim = sim;
  msg->cmd = CMD_CHIP_ASYNC_MSG;
  msg->chip = chip;
  msg->data = data;

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
    [ARCH_SATURN]    = NULL,
  };


// Standard accessor functions
bool get_reg (sim_t    *sim UNUSED,
	      chip_t   *chip UNUSED,
	      void     *data,
	      size_t   size,
	      uint64_t *p,
	      int      arg UNUSED)
{
  switch (size)
    {
    case 1: *p = *((uint8_t  *) data); break;
    case 2: *p = *((uint16_t *) data); break;
    case 4: *p = *((uint32_t *) data); break;
    case 8: *p = *((uint64_t *) data); break;
    default:
      fatal (3, "bad storage size %d\n", size);
    }
  return true;
}

bool set_reg (sim_t    *sim UNUSED,
	      chip_t   *chip UNUSED,
	      void     *data,
	      size_t   size,
	      uint64_t *p,
	      int      arg UNUSED)
{
  switch (size)
    {
    case 1: *((uint8_t  *) data) = *p; break;
    case 2: *((uint16_t *) data) = *p; break;
    case 4: *((uint32_t *) data) = *p; break;
    case 8: *((uint64_t *) data) = *p; break;
    default:
      fatal (3, "bad storage size %d\n", size);
    }
  return true;
}


// Common non-standard acccessor functions used for fields that
// are internally stored as an array of digits, one digit per byte.
// The external representation is packed into a single uint of an
// appropriate size.
bool get_digits (sim_t    *sim UNUSED,
		 chip_t   *chip UNUSED,
		 void     *data,
		 size_t   size UNUSED,
		 uint64_t *p,
		 int      arg)
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


bool set_digits (sim_t    *sim UNUSED,
		 chip_t   *chip UNUSED,
		 void     *data,
		 size_t   size UNUSED,
		 uint64_t *p,
		 int      arg)
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


bool get_bit_digits (sim_t    *sim UNUSED,
		     chip_t   *chip UNUSED,
		     void     *data,
		     size_t   size UNUSED,
		     uint64_t *p,
		     int      arg)
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


bool set_bit_digits (sim_t    *sim UNUSED,
		     chip_t   *chip UNUSED,
		     void     *data,
		     size_t   size UNUSED,
		     uint64_t *p,
		     int      arg)
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


bool get_bools (sim_t    *sim UNUSED,
		chip_t   *chip UNUSED,
		void     *data,
		size_t   size UNUSED,
		uint64_t *p,
		int      arg)
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

bool set_bools (sim_t    *sim UNUSED,
		chip_t   *chip UNUSED,
		void     *data,
		size_t   size UNUSED,
		uint64_t *p,
		int      arg)
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
		      plugin_module_t *module,
		      const chip_detail_t *chip_detail,
		      void *chip_data)
{
  chip_t *chip;

  chip = alloc (sizeof (chip_t));

  chip->sim = sim;
  chip->module = module;

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


// Only call this after the chip has been sent a remove event.  The chip
// should already have freed its private data.
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

  free (chip);
}


void chip_event (sim_t      *sim,
		 chip_t     *chip,
		 event_id_t event,
		 int        arg1,
		 int        arg2,
		 void       *data)
{
  if (chip)
    {
      if (chip->chip_detail->chip_event_fn)
	chip->chip_detail->chip_event_fn (sim, chip, event, arg1, arg2, data);
    }
  else
    {
      for (chip = sim->first_chip; chip; chip = chip->next)
	if (chip->chip_detail->chip_event_fn)
	  chip->chip_detail->chip_event_fn (sim, chip, event, arg1, arg2, data);
    }
}


const chip_detail_t *get_chip_detail (chip_t *chip)
{
  return chip->chip_detail;
}


void *get_chip_data (chip_t *chip)
{
  return chip->chip_data;
}


bool sim_disassemble (sim_t        *sim,
		      uint32_t     flags,
		      // input and output:
		      bank_t       *bank,
		      addr_t       *addr,
		      inst_state_t *inst_state,
		      bool         *carry_known_clear,
		      addr_t       *delayed_select_mask,
		      addr_t       *delayed_select_addr,
		      // output:
		      flow_type_t  *flow_type,
		      bank_t       *target_bank,
		      addr_t       *target_addr,
		      char         *buf,
		      int          len)
{
  return sim->proc->disassemble (sim,
				 flags,
				 bank,
				 addr,
				 inst_state,
				 carry_known_clear,
				 delayed_select_mask,
				 delayed_select_addr,
				 flow_type,
				 target_bank,
				 target_addr,
				 buf,
				 len);
}

flow_type_info_t flow_type_info [MAX_FLOW_TYPE] =
{
  [flow_no_branch]              = { false, false },
  [flow_cond_branch]            = { true,  false },
  [flow_uncond_branch]          = { true,  true },
  [flow_uncond_branch_keycode]  = { false, true },
  [flow_uncond_branch_computed] = { false, true },
  [flow_subroutine_call]        = { true,  false },
  [flow_cond_subroutine_return] = { false, false },
  [flow_subroutine_return]      = { false, true },
  [flow_bank_switch]            = { true,  true }
};

bool sim_disassemble_runtime (sim_t        *sim,
			      uint32_t     flags,
			      bank_t       bank,
			      addr_t       addr,
			      inst_state_t inst_state,
			      bool         carry,
			      bool         del_rom_flag,
			      uint8_t      del_rom,
			      char         *buf,
			      int          len)
{
  bool stat;
  bool carry_known_clear = ! carry;
  addr_t delayed_select_mask = del_rom_flag ? 07400 : 00000;
  addr_t delayed_select_addr = del_rom << 8;
  bank_t target_bank;
  addr_t target_addr;
  flow_type_t flow_type;

  char target_str [10];
  char buf1 [80];

  stat = sim_disassemble (sim,
			  flags,
			  & bank,
			  & addr,
			  & inst_state,
			  & carry_known_clear,
			  & delayed_select_mask,
			  & delayed_select_addr,
			  & flow_type,
			  & target_bank,
			  & target_addr,
			  buf1,
			  sizeof (buf1));

  if (! stat)
    return false;

  if (flow_type_info [flow_type].has_target)
    {
      snprintf (target_str, sizeof (target_str), "%o-%04o", target_bank, target_addr);
      snprintf (buf, len, buf1, target_str);
    }
  else
    snprintf (buf, len, buf1);

  return true;
}


void log_printf (sim_t *sim, char *fmt, ...)
{
  int i;
  va_list ap;

  if (! sim->log_msg)
    {
      sim->log_msg_index = 0;
      sim->log_msg_space = 81;
      sim->log_msg = alloc (sim->log_msg_space);
    }

  va_start (ap, fmt);

  if (sim->log_msg_space)
    {
      i = vsnprintf (& sim->log_msg [sim->log_msg_index],
		     sim->log_msg_space,
		     fmt,
		     ap);

      sim->log_msg_index += i;
      sim->log_msg_space -= i;
    }

  va_end (ap);
}

void log_send (sim_t *sim)
{
  gui_msg_t *msg;

  if (! sim->log_msg)
    return;

  msg = g_async_queue_try_pop (sim->thread_vars->gui_cmd_free_q);
  if (! msg)
    msg = alloc (sizeof (gui_msg_t));

  msg->sim = sim;
  msg->cmd = CMD_DEBUG_TRACE_MSG;
  msg->data = sim->log_msg;

  g_async_queue_source_push (sim->thread_vars->gui_cmd_q_source, msg);

  sim->log_msg = NULL;
}
