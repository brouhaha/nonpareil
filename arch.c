/*
arch.c
$Id$
Copyright 2004 Eric L. Smith

Nonpareil is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License version 2 as
published by the Free Software Foundation.  Note that I am not
granting permission to redistribute or modify CASM under the terms of
any later version of the General Public License.

This program is distributed in the hope that it will be useful (or at least
amusing), but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with
this program (in the file "COPYING"); if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/


#include <string.h>
#include <strings.h>


#include "arch.h"


char *arch_name [ARCH_MAX] =
  {
    [ARCH_UNKNOWN]   = "unknown",
    [ARCH_CLASSIC]   = "classic",
    [ARCH_WOODSTOCK] = "woodstock",
    [ARCH_CRICKET]   = "cricket",
    [ARCH_NUT]       = "nut",
    [ARCH_CAPRICORN] = "capricorn",
    [ARCH_SATURN]    = "saturn"
  };

int arch = ARCH_UNKNOWN;


int find_arch_by_name (char *s)
{
  int i;
  for (i = 1; i < ARCH_MAX; i++)
    if (strcasecmp (s, arch_name [i]) == 0)
      return (i);
  return (ARCH_UNKNOWN);
}
