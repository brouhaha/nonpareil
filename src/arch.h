/*
Copyright 2004, 2005, 2006, 2010, 2022 Eric Smith <eric@spacewar@gmail.com>
SPDX-License-Identifier: GPL-3.0-only

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License version 3 as
published by the Free Software Foundation.

Note that permission is NOT granted to redistribute and/or modify
this porogram under the terms of any other version, earlier or
later, of the GNU General Public License.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License version 3 for more details.

You should have received a copy of the GNU General Public License
version 3 along with this program (in the file "gpl-3.0.txt"); if not,
see <https://www.gnu.org/licenses/>.
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
