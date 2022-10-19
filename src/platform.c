/*
Copyright 2004, 2005, 2006, 2022 Eric Smith <spacewar@gmail.com>

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

#include "platform.h"


char *platform_name [PLATFORM_MAX] =
{
  [PLATFORM_UNKNOWN]    = "unknown",
  [PLATFORM_CLASSIC]    = "classic",
  [PLATFORM_CLASSIC_PR] = "classic_pr",
  [PLATFORM_WOODSTOCK]  = "woodstock",
  [PLATFORM_HAWKEYE]    = "hawkeye",
  [PLATFORM_TOPCAT]     = "topcat",
  [PLATFORM_CLYDE]      = "clyde",
  [PLATFORM_KISS]       = "kiss",
  [PLATFORM_CRICKET]    = "cricket",
  [PLATFORM_SPICE]      = "spice",
  [PLATFORM_COCONUT]    = "coconut",
  [PLATFORM_VOYAGER]    = "voyager",
};

int find_platform_by_name (char *s)
{
  int i;
  for (i = 1; i < PLATFORM_MAX; i++)
    if (strcasecmp (s, platform_name [i]) == 0)
      return (i);
  return (PLATFORM_UNKNOWN);
}
