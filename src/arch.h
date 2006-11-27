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


/* CPU architectures: */

#define ARCH_UNKNOWN   0

// Open architectures:
#define ARCH_M68K      1
#define ARCH_H8        2
#define ARCH_SUNPLUS   3
#define ARCH_ARM       4

// HP proprietary architectures:
#define ARCH_CLASSIC   5
#define ARCH_WOODSTOCK 6
#define ARCH_CRICKET   7
#define ARCH_NUT       8
#define ARCH_CAPRICORN 9
#define ARCH_SATURN    10

// TI proprietary architectures:
#define ARCH_TMS1802   11
#define ARCH_TMS0200   12
#define ARCH_TMC0501   13  // variant 0 = TMC0501, variant 1 = TMC0501E
#define ARCH_TMC0980   14
#define ARCH_TMC1500   15

#define ARCH_MAX       16


typedef struct
{
  char *name;
  int word_length;
} arch_info_t;


int find_arch_by_name (char *s);

arch_info_t *get_arch_info (int arch);
