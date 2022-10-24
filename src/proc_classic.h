/*
Copyright 1995, 2003, 2004, 2005, 2008, 2022 Eric Smith <spacewar@gmail.com>

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

#ifndef PROC_CLASSIC_H
#define PROC_CLASSIC_H

#include "proc_classic_ext_flags.h"

#define WSIZE 14
#define EXPSIZE 3  // two exponent and one exponent sign digit

typedef digit_t reg_t [WSIZE];


#define SSIZE 12


#define EXT_FLAG_SIZE 2


#define MAX_GROUP 2
#define MAX_ROM 8
#define ROM_SIZE 256

#if 1
  // This was the easiest way to use the existing code:
  #define MAX_BANK 1
  #define MAX_PAGE 1
  #define PAGE_SIZE (MAX_GROUP * MAX_ROM * ROM_SIZE)
#else
  // This would somewhat more accurately represent the hardware
  // behavior, but the current code won't deal with it correctly:
  #define MAX_BANK (MAX_GROUP * MAX_ROM)
  #define MAX_PAGE 1
  #define PAGE_SIZE (ROM_SIZE)
#endif


typedef struct
{
  reg_t a;
  reg_t b;
  reg_t c;
  reg_t d;
  reg_t e;
  reg_t f;
  reg_t m;

  digit_t p;

  bool carry, prev_carry;

  bool s [SSIZE];

  uint8_t pc;
  uint8_t rom;
  uint8_t group;

  bool del_rom_flag;
  uint8_t del_rom;

  bool del_group_flag;
  uint8_t del_group;

  uint8_t ret_pc;

  int prev_pc;  /* used to store complete five-digit octal address of instruction */

  bool ext_flag [EXT_FLAG_SIZE];  /* external flags, e.g., slide switches,
				     magnetic card inserted */

  // keyboard
  bool key_flag;      /* true if a key is down */
  int key_buf;        /* most recently pressed key */

  // display
  bool display_enable;

  int left_scan;
  int right_scan;
  int display_scan_position;   /* word index, left_scan down to right_scan */
  int display_digit_position;  /* character index, 0 to MAX_DIGIT_POSITION-1 */

  void (* display_scan_fn) (sim_t *sim);

  void (* op_fcn [1024])(struct sim_t *sim, int opcode);

  // ROM:
  rom_word_t *ucode;  // name "rom" was already taken
  bool *rom_exists;
  bool *rom_breakpoint;

  // RAM
  addr_t arch_max_ram;
  addr_t max_ram;
  addr_t ram_addr;  /* selected RAM address */
  bool *ram_exists;
  reg_t *ram;
} classic_cpu_reg_t;


#define FAKE_CLASSIC_DISASSEMBLER
#ifndef FAKE_CLASSIC_DISASSEMBLER
// defined in dis_classic.c:
bool classic_disassemble (sim_t        *sim,
			  uint32_t     flags,
			  // input and output:
			  bank_t       *bank,
			  addr_t       *addr,
			  inst_state_t *inst_state,
			  bool         *carry_known_clear,
			  addr_t       *delayed_select_mask,
			  addr_t       *delayed_select_addr,
			  // output:
			  flow_type_t  *flow_type,
			  bank_t       *target_bank,
			  addr_t       *target_addr,
			  char         *buf,
			  int          len);
#endif

#endif // PROC_CLASSIC_H
