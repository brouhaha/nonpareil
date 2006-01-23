/*
$Id$
Copyright 2004, 2005, 2006 Eric L. Smith <eric@brouhaha.com>

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

#include <stdint.h>
#include <string.h>

#include "arch.h"
#include "platform.h"
#include "model.h"


model_info_t model_info [] =
  {
    { "unknown", PLATFORM_UNKNOWN, ARCH_UNKNOWN,  0,   0,      0 },
    { "01",   PLATFORM_CRICKET,   ARCH_CRICKET,   0,   0,  38400 }, /* osc > bit time? */
    { "10",   PLATFORM_KISS,      ARCH_WOODSTOCK, 0,   0, 185000 },
    { "10C",  PLATFORM_VOYAGER,   ARCH_NUT,       0,  40, 215000 },
    { "11C",  PLATFORM_VOYAGER,   ARCH_NUT,       0,  40, 215000 },
    { "12C",  PLATFORM_VOYAGER,   ARCH_NUT,       0,  40, 215000 },
    { "15C",  PLATFORM_VOYAGER,   ARCH_NUT,       0,  80, 215000 },
    { "16C",  PLATFORM_VOYAGER,   ARCH_NUT,       0,  40, 215000 },
    { "19C",  PLATFORM_TOPCAT,    ARCH_WOODSTOCK, 1,  48, 185000 },
    { "21",   PLATFORM_WOODSTOCK, ARCH_WOODSTOCK, 0,   0, 185000 },
    { "22",   PLATFORM_WOODSTOCK, ARCH_WOODSTOCK, 0,  16, 185000 },
    { "25",   PLATFORM_WOODSTOCK, ARCH_WOODSTOCK, 0,  16, 185000 },
    { "25C",  PLATFORM_WOODSTOCK, ARCH_WOODSTOCK, 0,  16, 185000 },
    { "27",   PLATFORM_WOODSTOCK, ARCH_WOODSTOCK, 0,  16, 185000 },
    { "29C",  PLATFORM_WOODSTOCK, ARCH_WOODSTOCK, 1,  48, 185000 },
    { "31E",  PLATFORM_SPICE,     ARCH_WOODSTOCK, 0,   0, 140000 },
    { "32E",  PLATFORM_SPICE,     ARCH_WOODSTOCK, 0,  32, 140000 }, /* measured */
    { "33C",  PLATFORM_SPICE,     ARCH_WOODSTOCK, 0,  32, 140000 },
    { "33E",  PLATFORM_SPICE,     ARCH_WOODSTOCK, 0,  32, 140000 },
    { "34C",  PLATFORM_SPICE,     ARCH_WOODSTOCK, 0,  64, 140000 },
    { "35",   PLATFORM_CLASSIC,   ARCH_CLASSIC,   0,   0, 196000 },
    { "37E",  PLATFORM_SPICE,     ARCH_WOODSTOCK, 0,  48, 140000 },
    { "38E",  PLATFORM_SPICE,     ARCH_WOODSTOCK, 0,  48, 140000 },
    { "38C",  PLATFORM_SPICE,     ARCH_WOODSTOCK, 0,  48, 140000 },
    { "41C",  PLATFORM_COCONUT,   ARCH_NUT,       0,  80, 375200 }, // 6700 uinst
    { "41CV", PLATFORM_COCONUT,   ARCH_NUT,       0, 336, 375200 }, //   per
    { "41CX", PLATFORM_COCONUT,   ARCH_NUT,       0, 464, 375200 }, //   second
    { "45",   PLATFORM_CLASSIC,   ARCH_CLASSIC,   0,  10, 196000 },
    { "55",   PLATFORM_CLASSIC,   ARCH_CLASSIC,   0,  30, 196000 },
    { "65",   PLATFORM_CLASSIC,   ARCH_CLASSIC,   0,  10, 196000 },
    { "67",   PLATFORM_WOODSTOCK, ARCH_WOODSTOCK, 1,  64, 185000 },
    { "70",   PLATFORM_CLASSIC,   ARCH_CLASSIC,   0,  10, 196000 },
    { "80",   PLATFORM_CLASSIC,   ARCH_CLASSIC,   0,   0, 196000 },
    { "91",   PLATFORM_TOPCAT,    ARCH_WOODSTOCK, 1,  16, 185000 },
    { "92",   PLATFORM_TOPCAT,    ARCH_WOODSTOCK, 1,  48, 185000 },
    { "95C",  PLATFORM_TOPCAT,    ARCH_WOODSTOCK, 1,  48, 185000 },
    { "97",   PLATFORM_TOPCAT,    ARCH_WOODSTOCK, 1,  64, 185000 },

    { "SR22",       PLATFORM_T_2C12D,        ARCH_TMS0200, 0,  0, 100000 },  // freq. unknown
    { "T30",        PLATFORM_T_MAJESTIC,     ARCH_TMC0980, 0,  0, 100000 },  // freq. unknown
    { "SR50",       PLATFORM_T_CLASSIC,      ARCH_TMC0501, 0,  0, 100000 },  // freq. unknown
    { "SR51",       PLATFORM_T_CLASSIC,      ARCH_TMC0501, 0,  0, 100000 },  // freq. unknown
    { "SR52",       PLATFORM_T_CARDREADER,   ARCH_TMC0501, 0,  0, 100000 },  // freq. unknown
    { "T55",        PLATFORM_T_MAJESTIC_2,   ARCH_TMC1500, 0,  0, 400000 },
    { "SR56",       PLATFORM_T_CLASSIC,      ARCH_TMC0501, 0,  0, 100000 },  // freq. unknown
    { "T57",        PLATFORM_T_MAJESTIC_2,   ARCH_TMC1500, 0,  0, 400000 },
    { "T58",        PLATFORM_T_CARDREADER_2, ARCH_TMC0501, 1,  0, 400000 },
    { "T59",        PLATFORM_T_CARDREADER_2, ARCH_TMC0501, 1,  0, 400000 },
    { "SR60",       PLATFORM_T_BIGDESK,      ARCH_TMC0501, 0,  0, 100000 },  // freq. unknown
    { "BA",         PLATFORM_T_MAJESTIC,     ARCH_TMC0980, 0,  0, 100000 },  // freq. unknown
    { "MBA",        PLATFORM_T_MAJESTIC_2,   ARCH_TMC1500, 0,  0, 400000 },
    { "PROGRAMMER", PLATFORM_T_MAJESTIC,     ARCH_TMC0980, 0,  0, 100000 }   // freq. unknown
  };


int find_model_by_name (char *s)
{
  unsigned int i;

  for (i = 0; i < (sizeof (model_info) / sizeof (model_info_t)); i++)
    {
      if (strcasecmp (s, model_info [i].name) == 0)
	return (i);
    }
  return (MODEL_UNKNOWN);
}


model_info_t *get_model_info (int model)
{
  return (& model_info [model]);
}
