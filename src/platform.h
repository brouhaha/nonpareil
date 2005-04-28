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

#define PLATFORM_UNKNOWN     0
#define PLATFORM_CLASSIC     1  // 35 45 55 65 70 80
#define PLATFORM_CLASSIC_PR  2  // 46 81 9805
#define PLATFORM_WOODSTOCK   3  // 21 22 25 25C 27 29C 67
#define PLATFORM_TOPCAT      4  // 91 92 95C 97 97S 19C
#define PLATFORM_KISS        5  // 10
#define PLATFORM_CRICKET     6  // 01
#define PLATFORM_SPICE       7  // 31E 32E 33C 33E 34C 37E 38C 38E
#define PLATFORM_COCONUT     8  // 41C 41CV 41CX
#define PLATFORM_VOYAGER     9  // 10C 11C 12C 15C 16C
#define PLATFORM_CAPRICORN  10  // 83 85 86 87 9915
#define PLATFORM_KANGAROO   11  // 75C, 75D
#define PLATFORM_TITAN      12  // 71B
#define PLATFORM_INTEGRAL   13  // 9807
#define PLATFORM_CLAMSHELL  14  // 18C 28C
#define PLATFORM_CLAMSHELL2 15  // 19B 19BII 28S (uses Lewis)
#define PLATFORM_LEWIS      16  // Pioneer graphic 17B 17BII 27S 42S
#define PLATFORM_SACAJAWEA  17  // Pioneer character 14B 22S 32S 32SII
#define PLATFORM_BERT       18  // Pioneer 7-segment, 10B 20S 21S
#define PLATFORM_CLARKE     19  // 38G 39G 40G 48S 48SX 48G 48GX 49G
#define PLATFORM_APPLE      20  // 39G+ 48GII 49G+

#define PLATFORM_MAX        21

extern char *platform_name [PLATFORM_MAX];

int find_platform_by_name (char *s);
