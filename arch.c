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


#include <stdbool.h>
#include <string.h>
#include <strings.h>


#include "arch.h"


char *arch_name [ARCH_MAX] =
  {
    "unknown",
    "classic",
    "woodstock",
    "cricket",
    "nut",
    "capricorn",
    "saturn"
  };

int arch = ARCH_UNKNOWN;

bool select_arch (char *s)
{
  int i;
  for (i = 1; i < ARCH_MAX; i++)
    {
      if (strcasecmp (s, arch_name [i]) == 0)
	{
	  arch = i;
	  return (true);
	}
    }
  return (false);
}

char *platform_name [PLATFORM_MAX] =
  {
    "unknown",
    "classic",
    "woodstock",
    "topcat",
    "hawkeye",
    "sting",
    "spice",
    "coconut",
    "voyager",
    "capricorn",
    "gemini",
    "kangaroo",
    "titan"
  };


model_info_t model_info [] =
  {
    { "10",   PLATFORM_STING,     ARCH_WOODSTOCK,   0 },
    { "10C",  PLATFORM_VOYAGER,   ARCH_NUT,        43 },
    { "11C",  PLATFORM_VOYAGER,   ARCH_NUT,        43 },
    { "12C",  PLATFORM_VOYAGER,   ARCH_NUT,        43 },
    { "15C",  PLATFORM_VOYAGER,   ARCH_NUT,        86 },
    { "16C",  PLATFORM_VOYAGER,   ARCH_NUT,        43 },
    { "19C",  PLATFORM_STING,     ARCH_WOODSTOCK,  48 },
    { "21",   PLATFORM_WOODSTOCK, ARCH_WOODSTOCK,   0 },
    { "22",   PLATFORM_WOODSTOCK, ARCH_WOODSTOCK,  16 },
    { "25",   PLATFORM_WOODSTOCK, ARCH_WOODSTOCK,  16 },
    { "25C",  PLATFORM_WOODSTOCK, ARCH_WOODSTOCK,  16 },
    { "27",   PLATFORM_WOODSTOCK, ARCH_WOODSTOCK,  16 },
    { "29C",  PLATFORM_WOODSTOCK, ARCH_WOODSTOCK,  48 },
    { "31E",  PLATFORM_SPICE,     ARCH_WOODSTOCK,   0 },
    { "32E",  PLATFORM_SPICE,     ARCH_WOODSTOCK,   0 },
    { "33C",  PLATFORM_SPICE,     ARCH_WOODSTOCK,   0 },
    { "33E",  PLATFORM_SPICE,     ARCH_WOODSTOCK,   0 },
    { "34C",  PLATFORM_SPICE,     ARCH_WOODSTOCK,   0 },
    { "35",   PLATFORM_CLASSIC,   ARCH_CLASSIC,     0 },
    { "37E",  PLATFORM_SPICE,     ARCH_WOODSTOCK,   0 },
    { "38E",  PLATFORM_SPICE,     ARCH_WOODSTOCK,   0 },
    { "38C",  PLATFORM_SPICE,     ARCH_WOODSTOCK,   0 },
    { "41C",  PLATFORM_COCONUT,   ARCH_NUT,        80 },
    { "41CV", PLATFORM_COCONUT,   ARCH_NUT,       336 },
    { "41CX", PLATFORM_COCONUT,   ARCH_NUT,       464 },
    { "45",   PLATFORM_CLASSIC,   ARCH_CLASSIC,    10 },
    { "55",   PLATFORM_CLASSIC,   ARCH_CLASSIC,    30 },
    { "65",   PLATFORM_CLASSIC,   ARCH_CLASSIC,    10 },
    { "67",   PLATFORM_HAWKEYE,   ARCH_WOODSTOCK,  64 },
    { "70",   PLATFORM_CLASSIC,   ARCH_CLASSIC,    10 },
    { "80",   PLATFORM_CLASSIC,   ARCH_CLASSIC,     0 },
    { "91",   PLATFORM_TOPCAT,    ARCH_WOODSTOCK,  16 },
    { "92",   PLATFORM_TOPCAT,    ARCH_WOODSTOCK,  48 },
    { "95C",  PLATFORM_TOPCAT,    ARCH_WOODSTOCK,  48 },
    { "97",   PLATFORM_TOPCAT,    ARCH_WOODSTOCK,  64 },
  };


model_info_t *get_model_info (char *model)
{
  int i;

  for (i = 0; i < (sizeof (model_info) / sizeof (model_info_t)); i++)
    {
      if (strcasecmp (model, model_info [i].name) == 0)
	return (& model_info [i]);
    }
  return (NULL);
}
