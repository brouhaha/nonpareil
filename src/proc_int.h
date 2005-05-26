/*
$Id$
Copyright 1995, 2004, 2005 Eric L. Smith <eric@brouhaha.com>

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


/*
 * The following structures form the interface between proc.c and the actual
 * processor models (e.g., proc_woodstock):
 */

typedef bool reg_accessor_t (void *data,
			     uint64_t *p,
			     int arg);

// get/set one four-bit digit per uint8
reg_accessor_t get_digits, set_digits;

// get/set one bit per uint8
reg_accessor_t get_bit_digits, set_bit_digits;

// get/set array of bools
reg_accessor_t get_bools, set_bools;


typedef struct
{
  reg_info_t info;     // publicly visible info: name, bit count, etc.
  size_t     offset;   // offset into register data structure
  // accessor functions - if NULL, use default
  reg_accessor_t *get;
  reg_accessor_t *set;
  int accessor_arg;
} reg_detail_t;



typedef void chip_event_fn_t (sim_t *sim, int chip_num, int event);


typedef struct chip_detail_t
{
  chip_info_t          info;
  int                  reg_count;
  const reg_detail_t   *reg_detail;
  chip_event_fn_t      *chip_event_fn;
} chip_detail_t;


/* dispatch table for processor-specific functions: */

typedef struct
{
  int max_rom;
  int max_bank;

  int max_chip_count;

  void (* new_processor)       (sim_t *sim, int ram_size);
  void (* free_processor)      (sim_t *sim);

  bool (* parse_object_line)   (char *buf, int *bank, int *addr,
				rom_word_t *opcode);
  bool (* parse_listing_line)  (char *buf, int *bank, int *addr,
				rom_word_t *opcode);

  /* returns false if asleep (can't execute cycles) */
  bool (* execute_cycle)       (sim_t *sim);

  /* returns false if asleep (can't execute instructions) */
  bool (* execute_instruction) (sim_t *sim);

  /* I/O */
  void (* press_key)           (sim_t *sim, int keycode);
  void (* release_key)         (sim_t *sim);
  void (* set_ext_flag)        (sim_t *sim, int flag, bool state);

  /* memory access: */
  bool (* read_rom)            (sim_t      *sim,
				uint8_t    bank,
				addr_t     addr,
				rom_word_t *val);
  bool (* write_rom)           (sim_t      *sim,
				uint8_t    bank,
				addr_t     addr,
				rom_word_t *val);

  bool (* read_ram)            (sim_t *sim, int addr, uint64_t *val);
  bool (* write_ram)           (sim_t *sim, int addr, uint64_t *val);

  /* for debugger: */
  void (* disassemble)         (sim_t *sim, int addr, char *buf, int len);

  void (* print_state)         (sim_t *sim);
} processor_dispatch_t;


extern processor_dispatch_t *processor_dispatch [ARCH_MAX];


/* common to all architectures: */

typedef struct sim_thread_vars_t sim_thread_vars_t;


struct sim_t
{
  const chip_detail_t **chip_detail;   // array [max_chip_count]
  void **chip_data;         // array [max_chip_count]

  bool quit_flag;

  bool io_pause_flag;    // If true, don't execute anything, state IO is pending
                         // Overrides run_flag, single_cycle_flag, single_inst_flag.

  bool run_flag;
  bool single_cycle_flag;
  bool single_inst_flag;

  sim_thread_vars_t *thread_vars;

  int model;
  int platform;

  int arch;
  processor_dispatch_t *proc;

  double words_per_usec;  /* Processor word times per microsecond, typically
			     much less than 1.  For instance, 3.5e-3 for
			     HP-55. */

  uint64_t cycle_count;

  segment_bitmap_t *char_gen;

  int display_digits;
  segment_bitmap_t display_segments [MAX_DIGIT_POSITION];

#ifdef HAS_DEBUGGER
  int debug_flags;  /* SIM_DEBUG_TRACE etc. */
#endif

  // RAM:
  uint16_t   max_ram;

  // ROM:
  bool       *breakpoint;
  char       **source;
};


// Use -1 for chip_num for don't care.
// Return value is actual chip_num, or negative if error.
int install_chip (sim_t *sim,
		  int chip_num,
		  const chip_detail_t *chip_detail,
		  void *chip_data);

bool remove_chip (sim_t *sim,
		  int chip_num);

// Notify all chips of an event.
void chip_event (sim_t *sim, int event);
