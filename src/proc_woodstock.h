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


#define SSIZE 16
#define STACK_SIZE 2

#define EXT_FLAG_SIZE 16

#define MAX_CHIP_COUNT 3  // ACT CPU
                          // PIK (HP-91, HP-92, HP-95C, HP-97, HP-19C only)
                          // CRC (HP-67, HP-97 only)


typedef enum
  {
    norm,
    branch,
    selftest
  } inst_state_t;


typedef struct
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

  bool decimal;

  bool carry, prev_carry;

  bool s [SSIZE];                 // ACT flags (status bits)
  bool ext_flag [EXT_FLAG_SIZE];  // external flags, cause status or CRC
                                     // bits to get set

  bool bank;

  uint16_t pc;

  bool del_rom_flag;
  uint8_t del_rom;

  inst_state_t inst_state;

  int sp;  /* stack pointer */
  uint16_t return_stack [STACK_SIZE];

  int prev_pc;  /* used to store complete five-digit octal address of instruction */

  int crc;

  // keyboard

  bool key_flag;      /* true if a key is down */
  int key_buf;        /* most recently pressed key */

  // display

  bool display_enable;
  bool display_14_digit;  // true after RESET TWF instruction

  int left_scan;
  int right_scan;
  int display_scan_position;   /* word index, left_scan down to right_scan */
  int display_digit_position;  /* character index, 0 to MAX_DIGIT_POSITION-1 */

  void (* display_scan_fn) (sim_t *sim);

  // RAM
  int ram_addr;  /* selected RAM address */

  int max_ram;
  reg_t *ram;
} act_reg_t;
