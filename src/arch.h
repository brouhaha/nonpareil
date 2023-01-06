/*
Copyright 2004, 2005, 2006, 2010, 2022 Eric Smith <eric@spacewar@gmail.com>

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

#ifndef ARCH_H
#define ARCH_H

/* CPU architectures: */

typedef enum
{
  ARCH_UNKNOWN,

  ARCH_CLASSIC,
  ARCH_WOODSTOCK,
  ARCH_CRICKET,
  ARCH_NUT,
  ARCH_CAPRICORN,
  ARCH_SATURN,

  ARCH_MAX  // not an architecture - must be last
} arch_t;


typedef struct
{
  char *name;
  int word_length;
} arch_info_t;


int find_arch_by_name (char *s);

arch_info_t *get_arch_info (arch_t arch);


#define ARCH_CLASSIC_ROM_SIZE_WORDS   256
#define ARCH_CLASSIC_MAX_ROM            8
#define ARCH_CLASSIC_MAX_GROUP          2

#endif // ARCH_H
