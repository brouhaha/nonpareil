/*
$Id$
Copyright 2005 Eric L. Smith <eric@brouhaha.com>

Nonpareil is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License version 2 as
published by the Free Software Foundation.  Note that I am not
granting permission to redistribute or modify Nonpareil under the
terms of any later version of the General Public License.

Nonpareil is distributed in the hope that it will be useful (or at
least amusing), but WITHOUT ANY WARRANTY; without even the implied
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See
the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program (in the file "COPYING"); if not, write to the
Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
MA 02111, USA.
*/

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include "util.h"
#include "platform.h"
#include "arch.h"
#include "display.h"  // proc.h needs segment_bitmap_t
#include "proc.h"
#include "proc_int.h"
#include "dis_woodstock.h"
#include "dis_nut.h"


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
  int platform = PLATFORM_UNKNOWN;
  int arch = ARCH_WOODSTOCK;
  sim_t *sim;
  addr_t addr;
  addr_t last;
  int inst_len;
  char buf [100];

  progname = argv [0];

  sim = sim_init (platform, arch, 1, 1, NULL);

  if (! sim_read_object_file (sim, argv [1]))
    fatal (2, "can't read ROM file\n");

  for (addr = 0; addr < last; addr += inst_len)
    {
      switch (arch)
	{
	case ARCH_WOODSTOCK:
	  inst_len = woodstock_disassemble_inst (addr,
						 sim->ucode [addr],
						 sim->ucode [addr + 1],
						 buf,
						 sizeof (buf));
	  break;
	case ARCH_NUT:
	  inst_len = nut_disassemble_inst (addr,
					   sim->ucode [addr],
					   sim->ucode [addr + 1],
					   buf,
					   sizeof (buf));
	  break;
	}
      printf ("%s\n", buf);
    }

  exit (0);
}
