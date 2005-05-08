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


#define WSIZE 14

typedef uint8_t digit_t;
typedef digit_t reg_t [WSIZE];


#define SSIZE 14
#define STACK_DEPTH 4

#define MAX_BANK 4
#define MAX_ROM 16
#define ROM_SIZE 4096

#define MAX_CHIP_COUNT 256


typedef uint16_t rom_addr_t;


typedef enum
  {
    norm,
    long_branch,
    cxisa,
    ldi
  } inst_state_t;


typedef struct
{
  reg_t a;
  reg_t b;
  reg_t c;
  reg_t m;
  reg_t n;
  digit_t g [2];

  digit_t p;
  digit_t q;
  bool q_sel;  // true if q is the selected pointer, false for p

  uint8_t fo;  /* flag output regiters, 8 bits, used to drive bender */

  bool decimal;  // true for arithmetic radix 10, false for 16

  bool carry;       // carry being generated in current instruction
  bool prev_carry;  // carry that resulted from previous instruction

  int prev_tef_last;  // last digit of field of previous arith. instruction
                      // used to simulate bug in logical or and and

  bool s [SSIZE];

  rom_addr_t pc;
  rom_addr_t prev_pc;

  rom_addr_t stack [STACK_DEPTH];

  rom_addr_t cxisa_addr;

  inst_state_t inst_state;

  rom_word_t first_word;   /* long branch: remember first word */
  bool long_branch_carry;  /* and carry */

  bool key_down;      /* true if a key is down */
  bool key_flag;
  int key_buf;        /* most recently pressed key */

  bool awake;

  // RAM:
  uint16_t max_ram;
  uint16_t ram_addr;  // selected RAM address
  bool *ram_exists;
  reg_t *ram;

  // Peripherals:
  uint16_t max_pf;
  uint8_t pf_addr;  // selected peripheral address
  bool *pf_exists;
} nut_reg_t;
