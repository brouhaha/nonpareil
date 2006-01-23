/*
$Id$
Copyright 2005, 2006 Eric L. Smith <eric@brouhaha.com>
Based on TI57E Pascal code by HrastProgrammer, used by permission.

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

typedef digit_t reg_t [WSIZE];


#define MAX_BANK 1
#define MAX_PAGE 1
#define PAGE_SIZE 2048

typedef uint16_t rom_addr_t;

#define STACK_DEPTH 3


typedef enum
{
  REG_A,
  REG_B,
  REG_C,
  REG_D
} gen_reg_t;


typedef struct
{
  reg_t reg [4];  // A, B, C, D

  reg_t x [8];
  reg_t y [8];

  bool decimal;

  rom_addr_t prev_pc;
  rom_addr_t pc;
  rom_addr_t stack [STACK_DEPTH];

  bool cond;

  // are these really the appropriate types?
  // uint8_t mf;  $$  replace mf with (op >> 8)
  uint8_t r5;
  uint8_t rab;  // Register Address Buffer, used to index x and y registers

  uint8_t key_buf;
  bool key_flag;

  bool ti57_hack;  // Enable HrastProgrammer's workarounds for bugs in
                   // code listings in TI-57 patents (probably fixed in
                   // production TI-57 code.
  bool ti57_hack_sigma;  // TI-57 stat bug workaround by HrastProgrammer 

  rom_word_t *rom;
  bool *rom_exists;
  bool *rom_breakpoint;

  void (* op_fcn [1024])(struct sim_t *sim, int opcode);
} tmc_reg_t;
