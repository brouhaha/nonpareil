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


/* hardware platforms */

typedef enum
{
  PLATFORM_UNKNOWN,
  PLATFORM_CLASSIC,        // 35 45 55 65 70 80
  PLATFORM_CLASSIC_PR,     // 46 81 9805
  PLATFORM_WOODSTOCK,      // 21 22 25 25C 27 29C
  PLATFORM_HAWKEYE,        // 67
  PLATFORM_TOPCAT,         // 91 92 95C 97 97S
  PLATFORM_CLYDE,          // 19C
  PLATFORM_KISS,           // 10
  PLATFORM_CRICKET,        // 01
  PLATFORM_SPICE,          // 31E 32E 33C 33E 34C 37E 38C 38E
  PLATFORM_COCONUT,        // 41C 41CV 41CX
  PLATFORM_VOYAGER,        // 10C 11C 12C 15C 16C
//PLATFORM_CAPRICORN,      // 83 85 86 87 9915
//PLATFORM_KANGAROO,       // 75C, 75D
//PLATFORM_TITAN,          // 71B
//PLATFORM_INTEGRAL,       // 9807
//PLATFORM_CLAMSHELL,      // 18C 28C
//PLATFORM_CLAMSHELL2,     // 19B 19BII 28S (uses Lewis)
//PLATFORM_LEWIS,          // Pioneer graphic 17B 17BII 27S 42S
//PLATFORM_SACAJAWEA,      // Pioneer character 14B 22S 32S 32SII
//PLATFORM_BERT,           // Pioneer 7-segment, 10B 20S 21S
//PLATFORM_CLARKE,         // 38G 39G 40G 48S 48SX 48G 48GX 49G
//PLATFORM_APPLE,          // 39G+ 48GII 49G+

  PLATFORM_MAX
} platform_t;

extern char *platform_name [PLATFORM_MAX];

int find_platform_by_name (char *s);
