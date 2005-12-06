/*
$Id$
Copyright 1995, 2003, 2004, 2005 Eric L. Smith <eric@brouhaha.com>

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


#define WSIZE 16
#define EXPSIZE 3  // two exponent and one exponent sign digit

typedef digit_t reg_t [WSIZE];


#define SSIZE 16


#define STACK_DEPTH 8


#define MAX_OPCODE_DIGITS 21


typedef uint32_t rom_addr_t;  // 20 bits


typedef enum
  {
    sleep;
    inst_fetch_0;
    inst_fetch;
  } inst_state_t;


struct saturn_reg_t;

typedef void ram_access_fn_t (struct nut_reg_t *nut_reg, uint32_t addr, reg_t *reg);


#define REG_A 0
#define REG_B 1
#define REG_C 2
#define REG_D 3
#define REG_R(x) (4+x)

#define MAX_REG_R 5  // only R0 to R4 implemented

#define MAX_REG REG_R(MAX_REG_R)

#define MAX_REG_D 2


typedef struct saturn_reg_t
{
  addr_t d [MAX_REG_D];  // D0 and D1 pointer registers (20 bits each)

  reg_t reg [MAX_REG];   // arithmetic registers (64 bits each)

  digit_t p;             // pointer register, 4 bits

  bool decimal;  // true for arithmetic radix 10, false for 16

  bool carry;       // carry being generated in current instruction
  bool prev_carry;  // carry that resulted from previous instruction

  bool s [SSIZE];

  rom_addr_t pc;
  rom_addr_t prev_pc;

  int stack_ptr;
  rom_addr_t stack [STACK_DEPTH];

  inst_state_t inst_state;

  digit_t inst [MAX_OPCODE_DIGITS];
  int inst_digits;      // total length of instruction, or 0 if unknown
  int inst_cur_digits;  // how many digits of opcode are currently valid

} nut_reg_t;
