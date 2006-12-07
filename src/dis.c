/*
$Id$
Copyright 2005, 2006 Eric L. Smith <eric@brouhaha.com>

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
#include "proc.h"
#include "calcdef.h"
//#include "proc_int.h"

#include "sound.h"  // ugh! needed for stub sound functions


#ifdef DEFAULT_PATH
char *default_path = MAKESTR(DEFAULT_PATH);
#else
char *default_path = NULL;
#endif


void usage (FILE *f)
{
  fprintf (f, "udis - %s\n", nonpareil_release);
  fprintf (f, "Copyright 2004, 2005, 2006 Eric L. Smith\n");
  fprintf (f, "http://nonpareil.brouhaha.com/\n");
  fprintf (f, "\n");
  fprintf (f, "usage: %s [options] model\n", progname);
  fprintf (f, "options:\n");
  fprintf (f, "   -a  assembly source mode\n");
  fprintf (f, "   -l  listing mode (default)\n");
}


bool asm_mode;
bool pass_two;


typedef struct
{
  bool has_target;
  bool ends_flow;
} flow_type_info_t;

static flow_type_info_t flow_type_info [MAX_FLOW_TYPE] =
{
  [flow_no_branch]              = { false, false},
  [flow_cond_branch]            = { true,  false},
  [flow_uncond_branch]          = { true,  true},
  [flow_uncond_branch_keycode]  = { false, true},
  [flow_uncond_branch_computed] = { false, true},
  [flow_subroutine_call]        = { true,  false},
  [flow_subroutine_return]      = { false, true},
  [flow_bank_switch]            = { true,  true}
};


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
    snprintf (buf, len, "S%04o", addr);
  else if (*sym & SYM_JUMP)
    snprintf (buf, len, "L%04o", addr);
  else
    buf [0] = '\0';
}


static void disassemble (sim_t *sim)
{
  uint8_t page;
  bank_t bank, target_bank;
  addr_t addr, target_addr, base_addr;
  int state = STATE_INITIAL;
  bool carry_known_clear;
  addr_t delayed_select_mask = 0, delayed_select_addr = 0;
  flow_type_t flow_type;
  char buf [100];

  for (bank = 0; bank < max_bank; bank++)
    for (page = 0; page < max_page; page++)
      if (sim_page_exists (sim, bank, page))
	{
	  addr = page * page_size;
	  while ((addr >= page * page_size) &&
		 (addr < ((page + 1) * page_size)))
	    {
	      base_addr = addr;
	      if (! sim_disassemble (sim,
				     & bank,
				     & addr,
				     & state,
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
		  char label [8];
		  get_symbol (bank, base_addr, label, sizeof (label));
		  if (label [0])
		    printf ("%s:  ", label);
		  else
		    printf ("        ");
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
	}
}


int main (int argc, char *argv[])
{
  char *model_str = NULL;
  char *ncd_fn;
  sim_t *sim;

  progname = argv [0];

  g_thread_init (NULL);

  while (--argc)
    {
      argv++;
      if (*argv [0] == '-')
	{
	  if (strcmp (argv [0], "-a") == 0)
	    asm_mode = true;
	  else if (strcmp (argv [0], "-l") == 0)
	    asm_mode = false;
	  else
	    fatal (1, "unrecognized option '%s'\n", argv [0]);
	}
      else if (model_str)
	{
	  fatal (1, "only one model may be specified\n");
	}
      else
	model_str = argv [0];
    }

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

  asm_mode = false;
  pass_two = false;
  disassemble (sim);

  pass_two = true;
  printf ("\t.arch woodstock\n\n");
  disassemble (sim);

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
