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

#define PLATFORM_UNKNOWN    0
#define PLATFORM_CLASSIC    1  // 35 45 55 65 70 80
#define PLATFORM_CLASSIC_PR 2  // 46 81 9805
#define PLATFORM_WOODSTOCK  3  // 21 22 25 25C 27 29C
#define PLATFORM_TOPCAT     4  // 91 92 95C 97 97S
#define PLATFORM_HAWKEYE    5  // 67
#define PLATFORM_STING      6  // 10 19C
#define PLATFORM_CRICKET    7  // 01
#define PLATFORM_SPICE      8  // 31E 32E 33C 33E 34C 37E 38C 38E
#define PLATFORM_COCONUT    9  // 41C 41CV 41CX
#define PLATFORM_VOYAGER   10  // 10C 11C 12C 15C 16C
#define PLATFORM_CAPRICORN 11  // 83 85 86 87 9915
#define PLATFORM_KANGAROO  12  // 75C, 75D
#define PLATFORM_TITAN     13  // 71B
#define PLATFORM_CLAMSHELL 14  // 18C 19B 19BII 28C 28S (but 19B 19BII 28S use Lewis chip)
#define PLATFORM_LEWIS     15  // Pioneer graphic 17B 17BII 27S 42S
#define PLATFORM_SACAJAWEA 16  // Pioneer character 14B 22S 32S 32SII
#define PLATFORM_BERT      17  // Pioneer 7-segment, 10B 20S 21S
#define PLATFORM_CLARKE    18  // 38G 39G 40G 48S 48SX 48G 48GX 49G
#define PLATFORM_APPLE     19  // 39G+ 48GII 49G+

#define PLATFORM_MAX       20

extern char *platform_name [PLATFORM_MAX];

int find_platform_by_name (char *s);
