/*
$Id$
Copyright 1995, 2003-2008 Eric Smith <eric@brouhaha.com>

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
#define EXPSIZE 3  // two exponent and one exponent sign digit

typedef digit_t reg_t [WSIZE];


#define SSIZE 14


#define EXT_FLAG_SIZE 14

#define EF_PRINTER_BUSY     0  // 82143A printer
#define EF_CARD_READER      1  // 82104A card reader
#define EF_WAND_DATA_AVAIL  2  // 82153A bar code wand
#define EF_BLINKY_EDAV      5  // 88242A IR printer module
#define EF_HPIL_IFCR        6  // 82160A HP-IL module
#define EF_HPIL_SRQR        7
#define EF_HPIL_FRAV        8
#define EF_HPIL_FRNS        9
#define EF_HPIL_ORAV       10
#define EF_TIMER           12  // 82182A Time Module (built into 41CX)
#define EF_SERVICE_REQUEST 13  // shared general service request
// Flags 3, 4, and 11 are apparently not used by any standard peripherals


#define STACK_DEPTH 4

#define PAGE_SIZE 4096
#define MAX_PAGE 16
#define MAX_BANK 4


typedef enum
{
  KB_IDLE,
  KB_PRESSED,
  KB_RELEASED,
  KB_WAIT_CHK,
  KB_WAIT_CYC,
  KB_STATE_MAX  // must be last
} keyboard_state_t;


enum
{
  event_periph_select = first_arch_event,
  event_ram_select,
  event_display_state_change
};


typedef uint16_t rom_addr_t;


struct nut_reg_t;

typedef void ram_access_fn_t (struct nut_reg_t *nut_reg, int addr, reg_t *reg);

typedef struct nut_reg_t
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

#ifdef NUT_BUGS
  int prev_tef_last;  // last digit of field of previous arith. instruction
                      // used to simulate bug in logical or and and
#endif // NUT_BUGS

  bool s [SSIZE];

  rom_addr_t pc;
  rom_addr_t prev_pc;

  rom_addr_t stack [STACK_DEPTH];

  rom_addr_t cxisa_addr;

  inst_state_t inst_state;

  rom_word_t first_word;   /* long branch: remember first word */

  bool key_down;      /* true while a key is down */
  keyboard_state_t kb_state;
  int kb_debounce_cycle_counter;
  int key_buf;        /* most recently pressed key */

  bool awake;

  void (* op_fcn [1024])(struct sim_t *sim, int opcode);

  // ROM:
  int bank_group [MAX_PAGE];  // defines which pages bank switch together
  uint8_t active_bank [MAX_PAGE];  // bank number from 0..MAX_BANK-1
  bool rom_writeable [MAX_PAGE][MAX_BANK];
  rom_word_t *rom [MAX_PAGE][MAX_BANK];
  bool *rom_breakpoint [MAX_PAGE][MAX_BANK];
  // source_code_line_info_t *source_code_line_info [MAX_PAGE][MAX_BANK];

  // RAM:
  addr_t ram_addr;  // selected RAM address
  bool *ram_exists;
  reg_t *ram;
  ram_access_fn_t **ram_read_fn;
  ram_access_fn_t **ram_write_fn;

  // Peripherals:
  uint16_t max_pf;
  uint8_t pf_addr;  // selected peripheral address
  bool *pf_exists;

  bool ext_flag [EXT_FLAG_SIZE];

  // Peripheral I/O functions return true if the peripheral responded.
  bool (* rd_n_fcn [256])(struct sim_t *sim, int n);
  bool (* wr_n_fcn [256])(struct sim_t *sim, int n);
  bool (* wr_fcn   [256])(struct sim_t *sim);

  uint8_t selprf;  // selected "smart peripheral" number

  // Function to call for "smart peripheral" to handle opcodes after
  // a selprf instruction:
  bool (* selprf_fcn [16])(struct sim_t *sim, rom_word_t opcode);

  // Bender:
  uint64_t bender_last_transition_cycle;  // or 0 if a long time ago
  uint64_t bender_last_pulse_width;       // to detect frequency changes
  int bender_sound_ref;

  // Other chips:

  chip_t *display_chip;   // opaque
  bool   display_enable;  // slaved from display using an event

  chip_t *phineas_chip;   // opaque

  chip_t *helios_chip;    // opaque
} nut_reg_t;


// defined in dis_nut.c:
bool nut_disassemble (sim_t        *sim,
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
