/*
$Id$
Copyright 2004 Eric L. Smith <eric@brouhaha.com>

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


#include "platform.h"


char *platform_name [PLATFORM_MAX] =
  {
    [PLATFORM_UNKNOWN] = "unknown",
    [PLATFORM_CLASSIC]   = "classic",
    [PLATFORM_WOODSTOCK] = "woodstock",
    [PLATFORM_TOPCAT]    = "topcat",
    [PLATFORM_HAWKEYE]   = "hawkeye",
    [PLATFORM_STING]     = "sting",
    [PLATFORM_CRICKET]   = "cricket",
    [PLATFORM_SPICE]     = "spice",
    [PLATFORM_COCONUT]   = "coconut",
    [PLATFORM_VOYAGER]   = "voyager",
    [PLATFORM_CAPRICORN] = "capricorn",
    [PLATFORM_GEMINI]    = "gemini",
    [PLATFORM_KANGAROO]  = "kangaroo",
    [PLATFORM_TITAN]     = "titan"
  };
