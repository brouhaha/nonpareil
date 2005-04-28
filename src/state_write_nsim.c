/*
$Id$
Copyright 1995, 2003, 2005 Eric L. Smith <eric@brouhaha.com>

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


#include <inttypes.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

#include "util.h"
#include "nsim_conv.h"


static void write_reg (FILE *f, uint64_t v, int d)
{
  fprintf (f, "%0*" PRIx64 "\n" , d, v);
}

static void write_flags (FILE *f)
{
  if (regs.awake)
    fprintf (f, "a");
  if (regs.carry)
    fprintf (f, "c");
  if (regs.decimal)
    fprintf (f, "d");
  if (regs.q_selected)
    fprintf (f, "q");
  fprintf (f, "\n");
}

static void write_stack (FILE *f)
{
  int i;

  for (i = 0; i < MAX_STACK; i++)
    fprintf (f, " %04" PRIx64, regs.stack [i]);
  fprintf (f, "\n");
}

static void write_status (FILE *f)
{
  int i;

  fprintf (f, "s: ");
  for (i = SSIZE - 1; i >= 0; i--)
    fprintf (f, (regs.status & (1 << i)) ? "*" : ".");
  fprintf (f, "\n");
}


void state_write_nsim (char *fn)
{
  FILE *f;
  uint16_t addr;

  f = fopen (fn, "w");
  if (! f)
    fatal (2, "Error opening nsim state file for writing\n");

  fprintf (f, "f: "); write_flags (f);
  fprintf (f, "a: "); write_reg (f, regs.a, WSIZE);
  fprintf (f, "b: "); write_reg (f, regs.b, WSIZE);
  fprintf (f, "c: "); write_reg (f, regs.c, WSIZE);
  fprintf (f, "m: "); write_reg (f, regs.m, WSIZE);
  fprintf (f, "n: "); write_reg (f, regs.n, WSIZE);
  fprintf (f, "g: "); write_reg (f, regs.g, 2);
  fprintf (f, "p: "); write_reg (f, regs.p, 1);
  fprintf (f, "q: "); write_reg (f, regs.q, 1);
  write_status (f);
  fprintf (f, "P: %04" PRIx64 "\n", regs.pc);
  fprintf (f, "S:");  write_stack (f);
  fprintf (f, "xfd-e: %c\n", regs.lcd.enable ? 'e' : 'd');
  fprintf (f, "xfd-a: "); write_reg (f, regs.lcd.a, 12);
  fprintf (f, "xfd-b: "); write_reg (f, regs.lcd.b, 12);
  fprintf (f, "xfd-c: "); write_reg (f, regs.lcd.c, 12);
  fprintf (f, "xfd-f: "); write_reg (f, regs.lcd.ann, 3);
#if 0
  for (addr = 0; addr < MAX_PFAD; addr++)
    if (pf_exists [addr] && save_fcn [addr])
      {
	sprintf (buf, "x%02x-", addr);
	save_fcn [addr] (f, buf);
      }
#endif
  for (addr = 0; addr < MAX_RAM; addr++)
    if (ram_used [addr])
      {
	fprintf (f, "%03x: ", addr);
	write_reg (f, ram [addr], WSIZE);
      }

  fclose (f);
}


