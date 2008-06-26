/*
$Id$
Copyright 2005, 2006, 2007, 2008 Eric Smith <eric@brouhaha.com>

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

#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <glib.h>

#include "util.h"
#include "platform.h"
#include "arch.h"
#include "model.h"
#include "display.h"  // proc.h needs segment_bitmap_t
#include "keyboard.h"
#include "chip.h"
#include "proc.h"
#include "calcdef.h"
#include "mod1_file.h"

#include "sound.h"  // ugh! needed for stub sound functions


#ifdef DEFAULT_PATH
char *default_path = MAKESTR(DEFAULT_PATH);
#else
char *default_path = NULL;
#endif


void usage (FILE *f)
{
  fprintf (f, "udis - %s\n", nonpareil_release);
  fprintf (f, "Copyright 2005, 2006, 2007, 2008 Eric Smith <eric@brouhaha.com>\n");
  fprintf (f, "http://nonpareil.brouhaha.com/\n");
  fprintf (f, "\n");
  fprintf (f, "usage: %s [options] model\n", progname);
  fprintf (f, "options:\n");
  fprintf (f, "   -a  assembly source mode\n");
  fprintf (f, "   -l  listing mode (default)\n");
  fprintf (f, "   --bank <bank>   bank\n");
  fprintf (f, "   --start <addr>  start address\n");
  fprintf (f, "   --end <addr>    end address\n");
}


bool listing_mode = true;
bool pass_two;

bool hex_addr_mode;


bank_t max_bank;
int page_size;
uint8_t max_page;
addr_t max_addr;

#define SYM_CALL 0x01
#define SYM_JUMP 0x02
#define SYM_KEY  0x04
uint8_t *symtab;


void set_symbol (bank_t bank, addr_t addr, uint8_t type)
{
  uint8_t *sym = & symtab [bank * max_addr + addr];
  (*sym) |= type;
}


void get_symbol (bank_t bank, addr_t addr, char *buf, int len)
{
  uint8_t *sym = & symtab [bank * max_addr + addr];
  if (*sym & SYM_CALL)
    snprintf (buf, len, hex_addr_mode ? "S%04x" : "S%05o", bank * max_addr + addr);
  else if (*sym & SYM_JUMP)
    snprintf (buf, len, hex_addr_mode ? "L%04x" : "L%05o", bank * max_addr + addr);
  else
    buf [0] = '\0';
}


void postprocess (bank_t       *bank,
		  addr_t       *addr,
		  flow_type_t  flow_type,
		  bank_t       target_bank,
		  addr_t       target_addr,
		  char         *buf,
		  int          len UNUSED)
{
  if (! pass_two)
    {
      if (flow_type_info [flow_type].has_target)
	{
	  if (flow_type == flow_subroutine_call)
	    set_symbol (target_bank, target_addr, SYM_CALL);
	  else
	    set_symbol (target_bank, target_addr, SYM_JUMP);
	}
    }
  else
    {
      char *p;
      char label [8];

      get_symbol (bank, addr, label, sizeof (label));
      // find label insertion point
      p = strstr (buf, "<label>");
      if (! p)
	fatal (2, "missing label insertion marker\n");
      memset (p, ' ', 7);
      if (label [0] && (label [0] != ' '))
	{
	  memcpy (p, label, strlen (label));
	  p [strlen (label)] = ':';
	}
      if (flow_type_info [flow_type].has_target)
	{
	  get_symbol (target_bank, target_addr, label, sizeof (label));
	  printf (buf, label);
	}
      else
	printf (buf);
      printf ("\n");
      if (flow_type_info [flow_type].ends_flow)
	printf ("\n");
    }
}


static void disassemble_all (sim_t *sim, uint32_t flags)
{
  uint8_t page;
  bank_t bank, target_bank;
  addr_t addr, target_addr, base_addr;
  inst_state_t inst_state = inst_normal;
  bool carry_known_clear;
  addr_t delayed_select_mask = 0, delayed_select_addr = 0;
  flow_type_t flow_type;
  char buf [100];

  for (bank = 0; bank < max_bank; bank++)
    for (page = 0; page < max_page; page++)
      if (sim_page_exists (sim, bank, page))
	{
	  fprintf (stderr, "disassembling bank %d page %d\n", bank, page);
	  addr = page * page_size;
	  while ((addr >= page * page_size) &&
		 (addr < ((page + 1) * page_size)))
	    {
	      base_addr = addr;
	      if (! sim_disassemble (sim,
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
				     buf,
				     sizeof (buf)))
		{
		  warning ("disassembler error at bank %d addr %05o\n", bank, (addr + 1) % max_addr);
		  break;
		}
	      postprocess (bank,
			   base_addr,
			   flow_type,
			   target_bank,
			   target_addr,
			   buf,
			   sizeof (buf));
	    }
	}
}


static void disassemble_range (sim_t    *sim,
			       uint32_t flags,
			       bank_t   bank,
			       addr_t   start_addr,
			       addr_t   end_addr)
{
  bank_t target_bank;
  addr_t addr, target_addr, base_addr;
  inst_state_t inst_state = inst_normal;
  bool carry_known_clear;
  addr_t delayed_select_mask = 0, delayed_select_addr = 0;
  flow_type_t flow_type;
  char buf [100];

  addr = start_addr;
  while (addr <= end_addr)
    {
      base_addr = addr;
      if (! sim_disassemble (sim,
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
			     buf,
			     sizeof (buf)))
	{
	  warning ("disassembler error at bank %d addr %05o\n", bank, (addr + 1) % max_addr);
	  break;
	}
      postprocess (bank,
		   base_addr,
		   flow_type,
		   target_bank,
		   target_addr,
		   buf,
		   sizeof (buf));
    }
}


int main (int argc, char *argv[])
{
  char *model_str = NULL;
  char *ncd_fn;
  char *module_str = NULL;
  char *mod1_fn;
  sim_t *sim;
  int arch;
  arch_info_t *arch_info;
  bool got_bank = false;
  bool got_start_addr = false;
  bool got_end_addr = false;
  uint32_t bank = 0;
  uint32_t start_addr;
  uint32_t end_addr;
  uint32_t flags;

  progname = argv [0];

  g_thread_init (NULL);

  while (--argc)
    {
      argv++;
      if (*argv [0] == '-')
	{
	  if (strcmp (argv [0], "-a") == 0)
	    listing_mode = false;
	  else if (strcmp (argv [0], "-l") == 0)
	    listing_mode = true;
	  else if (strcmp (argv [0], "--start") == 0)
	    {
	      got_start_addr = true;
	      start_addr = str_to_uint32 (argv [1], NULL, 0);
	      argc--;
	      argv++;
	    }
	  else if (strcmp (argv [0], "--end") == 0)
	    {
	      got_end_addr = true;
	      end_addr = str_to_uint32 (argv [1], NULL, 0);
	      argc--;
	      argv++;
	    }
	  else if (strcmp (argv [0], "--bank") == 0)
	    {
	      got_bank = true;
	      bank = str_to_uint32 (argv [1], NULL, 0);
	      argc--;
	      argv++;
	    }
	  else
	    fatal (1, "unrecognized option '%s'\n", argv [0]);
	}
      else if (! model_str)
	model_str = argv [0];
      else if (! module_str)
	module_str = argv [0];
      else
	{
	  fatal (1, "only one model and one module may be specified\n");
	}
    }

  if (got_start_addr ^ got_end_addr)
    fatal (1, "start and end address must both be present\n");

  if (got_bank && ! got_start_addr)
    fatal (1, "bank requires start and end address\n");

  ncd_fn = find_file_with_suffix (model_str, ".ncd", default_path);
  if (! ncd_fn)
    fatal (2, "can't find .ncd file\n");

  sim = sim_init (ncd_fn,
		  NULL,  // install_hardware_callback
		  NULL,  // install_hardware_callback_ref
		  NULL,  // display_update_callback
		  NULL); // display_udpate_callback_ref 

  max_bank = sim_get_max_rom_bank (sim);
  page_size = sim_get_rom_page_size (sim);
  max_addr = sim_get_max_rom_addr (sim);
  max_page = max_addr / page_size;

  symtab = alloc (max_bank * max_addr * sizeof (uint8_t));

  arch = sim_get_arch (sim);
  arch_info = get_arch_info (arch);
  hex_addr_mode = (arch == ARCH_NUT);

  if (module_str)
    {
      if (arch != ARCH_NUT)
	fatal (1, "module files can only be used with Nut processor\n");

      mod1_fn = find_file_with_suffix (module_str, ".mod", default_path);
      if (! mod1_fn)
	fatal (2, "can't find .mod file\n");

      if (! sim_install_module (sim, mod1_fn, -1, true))
	fatal (2, "can't load .mod file\n");
    }

  flags = DIS_FLAG_LABEL;
  if (listing_mode)
    flags |= DIS_FLAG_LISTING;

  pass_two = false;
  if (got_start_addr)
    disassemble_range (sim, flags,bank, start_addr, end_addr);
  else
    disassemble_all (sim, flags);

  pass_two = true;
  printf ("\t.arch %s\n\n", arch_info->name);
  if (got_start_addr)
    disassemble_range (sim, flags, bank, start_addr, end_addr);
  else
    disassemble_all (sim, flags);

  exit (0);
}


// sound function stubs
bool stop_sound (int id UNUSED)
{
  return true;
}

int synth_sound (float    frequency UNUSED,
		 float    amplitude UNUSED,
		 float    duration UNUSED,
		 sample_t *waveform_table UNUSED,
		 uint32_t waveform_table_length UNUSED)
{
  return 0;
}

sample_t squarewave_waveform_table [1] = { 0 };
uint32_t squarewave_waveform_table_length = 1;
