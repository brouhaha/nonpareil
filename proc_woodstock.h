/*
proc_woodstock.h
$Id$
Copyright 2004 Eric L. Smith

Nonpareil is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License version 2 as
published by the Free Software Foundation.  Note that I am not
granting permission to redistribute or modify CASM under the terms of
any later version of the General Public License.

This program is distributed in the hope that it will be useful (or at least
amusing), but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with
this program (in the file "COPYING"); if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/


struct sim_env_t
{
  reg_t a;
  reg_t b;
  reg_t c;
  reg_t y;
  reg_t z;
  reg_t t;
  reg_t m1;
  reg_t m2;

  digit_t f;

  digit_t p;

  uint8_t arithmetic_base;  /* 10 or 16 */

  uint8_t carry, prev_carry;

  uint8_t s [SSIZE];  /* status bits */
  uint8_t ext_flag [SSIZE];  /* external flags, cause status bits to get set */

  int ram_addr;  /* selected RAM address */

  int max_ram;
  reg_t *ram;

  uint16_t pc;

  uint8_t del_rom_flag;
  uint8_t del_rom;

  uint8_t if_flag;  /* True if "IF" instruction was executed, in which
		       case the next instruction word fetched is a 10-bit
		       branch address. */

  int sp;  /* stack pointer */
  uint16_t return_stack [STACK_SIZE];

  int prev_pc;  /* used to store complete five-digit octal address of instruction */

  int display_enable;
  int io_count;

  gboolean key_flag;  /* true if a key is down */
  int key_buf;        /* most recently pressed key */
};
