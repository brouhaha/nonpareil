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


/* hardware platforms */

#define PLATFORM_UNKNOWN   0
#define PLATFORM_CLASSIC   1
#define PLATFORM_WOODSTOCK 2
#define PLATFORM_TOPCAT    3
#define PLATFORM_HAWKEYE   4
#define PLATFORM_STING     5
#define PLATFORM_CRICKET   6
#define PLATFORM_SPICE     7
#define PLATFORM_COCONUT   8
#define PLATFORM_VOYAGER   9
#define PLATFORM_CAPRICORN 10
#define PLATFORM_GEMINI    11
#define PLATFORM_KANGAROO  12
#define PLATFORM_TITAN     13

#define PLATFORM_MAX       14

extern char *platform_name [PLATFORM_MAX];
