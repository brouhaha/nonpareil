/*
$Id$
Copyright 1995, 2003, 2004 Eric L. Smith <eric@brouhaha.com>

Nonpareil is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License version 2 as
published by the Free Software Foundation.  Note that I am not
granting permission to redistribute or modify Nonpareil under the
terms of any later version of the General Public License.

Nonpareil is distributed in the hope that it will be useful (or at
least amusing), but WITHOUT ANY WARRANTY; without even the implied
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See
the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program (in the file "COPYING"); if not, write to the
Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
MA 02111, USA.
*/


#define SSIZE 14
#define STACK_DEPTH 4

#define MAX_BANK 4
#define MAX_ROM 16
#define ROM_SIZE 4096


typedef uint16_t rom_addr_t;


typedef enum
  {
    norm,
    long_branch,
    cxisa,
    ldi
  } inst_state_t;


struct sim_env_t
{
  reg_t a;
  reg_t b;
  reg_t c;
  reg_t m;
  reg_t n;
  digit_t g [2];

  digit_t p;
  digit_t q;
  digit_t *pt;

  uint8_t fo;  /* flag output regiters, 8 bits, used to drive bender */

  uint8_t arithmetic_base;  /* 10 or 16 */

  bool carry, prev_carry;

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
  bool display_enable;

  int display_count;

  /* Coconut diplay: */
  digit_t lcd_a [DISPLAY_DIGITS];
  digit_t lcd_b [DISPLAY_DIGITS];
  digit_t lcd_c [DISPLAY_DIGITS];
  uint16_t lcd_ann;

  int pf_addr;  /* selected peripheral address */

  /* RAM */
  int max_ram;

  int ram_addr;  /* selected RAM address */

  reg_t ram [];
};


