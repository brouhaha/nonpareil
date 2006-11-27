/*
$Id$
Copyright 2005 Eric L. Smith <eric@brouhaha.com>

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
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include <glib.h>

#include "util.h"
#include "platform.h"
#include "arch.h"
#include "model.h"
#include "display.h"  // proc.h needs segment_bitmap_t
#include "keyboard.h"
#include "proc.h"
#include "calcdef.h"
#include "proc_int.h"
#include "dis_woodstock.h"
#include "dis_nut.h"

#include "sound.h"  // ugh! needed for stub sound functions


#ifdef DEFAULT_PATH
char *default_path = MAKESTR(DEFAULT_PATH);
#else
char *default_path = NULL;
#endif


void usage (FILE *f)
{
  fprintf (f, "udis - %s\n", nonpareil_release);
  fprintf (f, "Copyright 2004, 2005 Eric L. Smith\n");
  fprintf (f, "http://nonpareil.brouhaha.com/\n");
  fprintf (f, "\n");
  fprintf (f, "usage: %s rom\n", progname);
}


int main (int argc, char *argv[])
{
  char *ncd_fn;
  sim_t *sim;
  unsigned int bank, page;
  unsigned int max_bank, max_page, page_size, max_addr;
  addr_t addr;
  int inst_len;
  char buf [100];

  progname = argv [0];

  g_thread_init (NULL);

  if (argc != 2)
    fatal (1, NULL);

  ncd_fn = find_file_with_suffix (argv [1], ".ncd", default_path);
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

  for (bank = 0; bank < max_bank; bank++)
    for (page = 0; page < max_page; page++)
      if (sim_page_exists (sim, bank, page))
	for (addr = page * page_size;
	     addr < ((page + 1) * page_size);
	     addr += inst_len)
	  {
	    rom_word_t op1, op2;

	    if (! sim_read_rom (sim, bank, addr, & op1))
	      fatal (2, "can't read ROM bank %d addr %05o\n", bank, addr);

	    if (! sim_read_rom (sim, bank, (addr + 1) % max_addr, & op2))
	      {
		warning ("can't read ROM bank %d addr %05o\n", bank, (addr + 1) % max_addr);
		op2 = 0;
	      }

	    switch (sim->arch)
	      {
	      case ARCH_WOODSTOCK:
		inst_len = woodstock_disassemble_inst (bank * max_addr + addr,
						       op1,
						       op2,
						       buf,
						       sizeof (buf));
		break;
	      case ARCH_NUT:
		inst_len = nut_disassemble_inst (bank * max_addr + addr,
						 op1,
						 op2,
						 buf,
						 sizeof (buf));
		break;
	      }
	    printf ("%s\n", buf);
	  }
  
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
