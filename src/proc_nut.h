/*
Copyright 1995-2023 Eric Smith <spacewar@gmail.com>
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

#define MAX_BANK 5  // HP uses a maximum of two banks
                    // Hepax uses a maximum of four banks, but the ROM banks
                    // may "hide" a RAM bank.  In that case, we temporarily
                    // set up the RAM bank as a hidden bank until the ROM
                    // banks are moved away.
#define HIDDEN_BANK (MAX_BANK - 1)


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


typedef struct
{
  plugin_module_t *module;  // owning module, or NULL for mainframe
  bool ram;
  bool write_enable;
  rom_word_t data [PAGE_SIZE];
  bool breakpoint [PAGE_SIZE];
  // source_code_line_info_t *source_code_line_info;
} prog_mem_page_t;


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

  prog_mem_page_t *prog_mem_page [MAX_BANK][MAX_PAGE];

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

  uint8_t selpf;  // selected "smart peripheral" number

  // Function to call for "smart peripheral" to handle opcodes after
  // a selpf instruction:
  bool (* selpf_fcn [16])(struct sim_t *sim, rom_word_t opcode);

  // Bender:
  uint64_t bender_last_transition_cycle;  // or 0 if a long time ago
  uint64_t bender_last_pulse_width;       // to detect frequency changes
  int bender_sound_ref;

  // Other chips:

  chip_t *display_chip;   // opaque
  bool   display_enable;  // slaved from display using an event

  chip_t *phineas_chip;   // opaque

  chip_t *helios_chip;    // opaque

  chip_t *hepax_chip;     // opaque
} nut_reg_t;


// defined in dis_nut.c:
bool nut_disassemble (sim_t        *sim,
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


ram_access_fn_t nut_ram_read_zero;
ram_access_fn_t nut_ram_write_ignore;


bool nut_get_page_info (sim_t           *sim,
			bank_t          bank,
			uint8_t         page,
			plugin_module_t **module,
			bool            *ram,
			bool            *write_enable);

void debug_nut_show_pages (sim_t *sim);

#define DIS_FLAG_NUT_41_JUMPS (1 << 16)
