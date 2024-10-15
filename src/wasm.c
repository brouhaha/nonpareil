/*
Copyright 2023 Eric Smith <spacewar@gmail.com>
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

#include <stdbool.h>
#include <stdint.h>

#include "symtab.h"
#include "util.h"
#include "asm.h"
#include "wasm.h"


void pseudo_check(addr_t addr)
{
  if (pass != PASS_FINAL)
  {
    emit(0);  // placeholder
    return;
  }

  // compute CRC of one quad
  // final CRC including this word should be 0x078
  // XXX this code is currently incorrect unless CRC is the
  // last word of the quad
  uint16_t crc = 0x3ff;
  addr_t base = addr & ~0x3ff;
  for (addr_t a = base; a < base + 0x400; a++)
  {
    uint16_t data = asm_memory[a];
    if ((data == 0xffff) && (a != addr))
    {
      fatal(2, "can't compute CRC because data at @%05o is undefined (@%06o)\n", a, data);
    }
    data &= 0x03ff;
    for (int i = 0; i < 10; i++)
    {
      int b = crc & 1;
      crc >>= 1;
      if (b ^ (data & 1))
	crc ^= 0x331;
      data >>= 1;
    }
  }

  emit(crc);
}
