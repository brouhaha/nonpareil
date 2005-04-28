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


#include <ctype.h>
#include <inttypes.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "util.h"
#include "nsim_conv.h"


static void parse_reg (char **buf, uint64_t *reg)
{
  char *s;
  int count;

  s = strchr (*buf, ':');
  if (s)
    *buf = s + 1;

  while (**buf == ' ')
    (*buf)++;

  if (sscanf (*buf, "%" SCNx64 "%n", reg, & count) < 1)
    fatal (3, "bad word value '%s'\n", *buf);
  (*buf) += count;
}


static void parse_ram (char *buf)
{
  int addr;

  if (sscanf (buf, "%3x: ", & addr) != 1)
    fatal (3, "badly formatted line '%s'\n", buf);
  if ((addr < 0) || (addr >= MAX_RAM))
    fatal (3, "IllegalRAM address %03x\n", addr);
  parse_reg (& buf, & ram [addr]);
  ram_used [addr] = true;
}


static void parse_flags (char *buf)
{
  char *s;

  s = strchr (buf, ':');
  if (s)
    buf = s + 1;

  while (*buf)
    {
      switch (*buf)
	{
	case ' ': break;
	case '\n': return;
	case 'a': regs.awake      = true; break;
	case 'c': regs.carry      = true; break;
	case 'd': regs.decimal    = true; break;
	case 'q': regs.q_selected = true; break;
	default:
	  fatal (2, "unknown flag '%c'\n", *buf);
	}
      buf++;
    }
}


static void parse_stack (char *buf)
{
  int i;

  for (i = 0; i < MAX_STACK; i++)
    parse_reg (& buf, & regs.stack [i]);
}


static void parse_status (char *buf)
{
  char *b;
  char *p;
  int i;

  b = buf;
  p = strchr (buf, ':');
  if (p)
    b = p + 1;

  while (*b == ' ')
    b++;

  for (i = SSIZE - 1; i >= 0; i--)
    {
      switch (*(b++))
	{
	case '*':
	  regs.status += (1 << i);
	  break;
	case '.':
	  break;
	default:
	  fatal (2, "bad status string '%s'\n", buf);
	}
    }
}


static void parse_periph (char **buf)
{
  char *p;

  p = strchr (*buf, ':');
  if (! p)
    goto error;
  else
    p++;

  while (isspace (*p))
    p++;

  if (strncmp (*buf, "xfd-a:", 6) == 0)
    parse_reg (buf, & regs.lcd.a);
  else if (strncmp (*buf, "xfd-b:", 6) == 0)
    parse_reg (buf, & regs.lcd.b);
  else if (strncmp (*buf, "xfd-c:", 6) == 0)
    parse_reg (buf, & regs.lcd.c);
  else if (strncmp (*buf, "xfd-f:", 6) == 0)
    parse_reg (buf, & regs.lcd.ann);
  else if (strncmp (*buf, "xfd-e:", 6) == 0)
    {
      switch (*p)
	{
	case 'e': regs.lcd.enable = true; break;
	case 'd': regs.lcd.enable = false; break;
	default: goto error;
	}
    }
  else
    error: fatal (2, "bad peripheral string '%s'\n", *buf);
}


void state_read_nsim (char *fn)
{
  FILE *f;
  char buffer [81];
  char *buf;
  int len;

  f = fopen (fn, "r");
  if (! f)
    fatal (2, "Error opening nsim state file for reading\n");

  while (fgets (buffer, sizeof (buffer), f))
    {
      len = strlen (buffer);
      while (isspace (buffer [--len]))
	buffer [len] = '\0';
      buf = & buffer [0];
      switch (buffer [0])
	{
	case '0': case '1': case '2': case '3': parse_ram (buf); break;
	case 'f': parse_flags (buf);          break;
	case 'g': parse_reg (& buf, & regs.g);  break;
	case 'p': parse_reg (& buf, & regs.p);  break;
	case 'q': parse_reg (& buf, & regs.q);  break;
	case 's': parse_status (buf);         break;
	case 'P': parse_reg (& buf, & regs.pc); break;
	case 'S': parse_stack (buf);          break;
	case 'a': parse_reg (& buf, & regs.a);  break;
	case 'b': parse_reg (& buf, & regs.b);  break;
	case 'c': parse_reg (& buf, & regs.c);  break;
	case 'm': parse_reg (& buf, & regs.m);  break;
	case 'n': parse_reg (& buf, & regs.n);  break;
	case 'x': parse_periph (& buf);         break;
	default:
	  fatal (2, "unrecognized field '%s'\n", buf);
	}
    }
  fclose (f);
}


