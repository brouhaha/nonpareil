/*
$Id$
Copyright 2004, 2005, 2006, 2010 Eric Smith <eric@brouhaha.com>

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

#include <string.h>

#include "arch.h"


static arch_info_t arch_info [ARCH_MAX] =
  {
    [ARCH_UNKNOWN]     = { "unknown",    0 },

    [ARCH_M68K]        = { "m68k",       8 },  // 32-bit longword
    [ARCH_H8]          = { "h8",         8 },
    [ARCH_6502]        = { "6502",       8 },
    [ARCH_ARM]         = { "arm",        8 },  // 32-bit word

    [ARCH_CLASSIC]     = { "classic",   56 },
    [ARCH_WOODSTOCK]   = { "woodstock", 56 },
    [ARCH_CRICKET]     = { "cricket",   48 },
    [ARCH_NUT]         = { "nut",       56 },
    [ARCH_CAPRICORN]   = { "capricorn",  8 },
    [ARCH_SATURN]      = { "saturn",     4 },  // 64-bit word

    [ARCH_TMS1802]     = { "tms1802",   64 },
    [ARCH_TMS0200]     = { "tms0200",   64 },
    [ARCH_TMC0501]     = { "tmc0501",   64 },
    [ARCH_TMC0980]     = { "tmc0501",   64 },
    [ARCH_TMC1500]     = { "tmc0501",   64 }
  };


int find_arch_by_name (char *s)
{
  int i;
  for (i = 1; i < ARCH_MAX; i++)
    if (strcasecmp (s, arch_info [i].name) == 0)
      return (i);
  return (ARCH_UNKNOWN);
}


arch_info_t *get_arch_info (int arch)
{
  return (& arch_info [arch]);
}
