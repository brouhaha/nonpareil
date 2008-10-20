/*
$Id$
Copyright 1995, 2004, 2005, 2006, 2008 Eric Smith <eric@brouhaha.com>

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

typedef bool reg_accessor_t (sim_t    *sim,
			     chip_t   *chip,
			     void     *data,
			     size_t   size,
			     uint64_t *p,
			     int      arg);

// default get/set functions
reg_accessor_t get_reg, set_reg;

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
  size_t     size;     // sizeof(field) in bytes (for one element)
  // accessor functions - if NULL, use default
  reg_accessor_t *get;
  reg_accessor_t *set;
  int accessor_arg;
} reg_detail_t;



typedef void chip_event_fn_t (sim_t      *sim,
			      chip_t     *chip,
			      event_id_t event,
			      int        arg1,
			      int        arg2,
			      void       *data);


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
  void (* new_processor)       (sim_t *sim);
  void (* free_processor)      (sim_t *sim);

  bool (* parse_object_line)   (char        *buf,
				bank_mask_t *bank_mask,
				addr_t      *addr,
				rom_word_t  *opcode);

  bool (* parse_listing_line)  (char        *buf,
				bank_mask_t *bank_mask,
				addr_t      *addr,
				rom_word_t  *opcode);

  /* returns false if asleep (can't execute cycles) */
  bool (* execute_cycle)       (sim_t *sim);

  /* returns false if asleep (can't execute instructions) */
  bool (* execute_instruction) (sim_t *sim);

  /* memory access: */
  bool (* set_bank_group)      (sim_t      *sim,
				int        bank_group,
				addr_t     addr);

  bank_t (* get_max_rom_bank)  (sim_t      *sim);

  int (* get_rom_page_size)    (sim_t      *sim);

  int (* get_max_rom_addr)     (sim_t      *sim);

  bool (* create_page)         (sim_t           *sim,
				bank_t          bank,
				uint8_t         page,
				bool            ram,
				plugin_module_t *module);

  bool (* destroy_page)        (sim_t           *sim,
				bank_t          bank,
				uint8_t         page);

  bool (* get_page_info)       (sim_t           *sim,
				bank_t          bank,
				uint8_t         page,
				plugin_module_t **module,
				bool            *ram,
				bool            *write_enable);

  bool (* read_rom)            (sim_t      *sim,
				bank_t     bank,
				addr_t     addr,
				rom_word_t *val);

  bool (* write_rom)           (sim_t      *sim,
				bank_t     bank,
				addr_t     addr,
				rom_word_t *val);

  bool (* set_rom_write_enable) (sim_t      *sim,
				 bank_t     bank,
				 addr_t     addr,
				 bool       write_enable);

  // RAM:
  int (* get_max_ram_addr)     (sim_t      *sim);
  bool (* create_ram)          (sim_t *sim, addr_t addr, addr_t size);
  bool (* read_ram)            (sim_t *sim, addr_t addr, uint64_t *val);
  bool (* write_ram)           (sim_t *sim, addr_t addr, uint64_t *val);

  // for debugger:
  bool (* disassemble)         (sim_t        *sim,
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

  void (* print_state)         (sim_t *sim);
} processor_dispatch_t;


extern processor_dispatch_t *processor_dispatch [ARCH_MAX];


/* common to all architectures: */

typedef struct sim_thread_vars_t sim_thread_vars_t;


struct sim_t
{
  chip_t *first_chip;  // opaque, but always the CPU
  chip_t *last_chip;   // opaque

  plugin_module_t *first_module;
  plugin_module_t *last_module;

  bool quit_flag;

  bool io_pause_flag;    // If true, don't execute anything, state IO is pending
                         // Overrides run_flag, single_cycle_flag, single_inst_flag.

  bool run_flag;
  bool single_cycle_flag;
  bool single_inst_flag;

  sim_thread_vars_t *thread_vars;

  char *ncd_fn;
  calcdef_t *calcdef;

  int arch;
  uint32_t arch_flags;
  int platform;
  const char *model_name;

  processor_dispatch_t *proc;

  double words_per_usec;  /* Processor word times per microsecond, typically
			     much less than 1.  For instance, 3.5e-3 for
			     HP-55. */

  uint64_t cycle_count;

  const segment_bitmap_t *display_char_gen;

  int display_digits;
  bool display_changed;
  segment_bitmap_t display_segments [MAX_DIGIT_POSITION];

#if 1 || defined(HAS_DEBUGGER)
  int debug_flags;  /* SIM_DEBUG_TRACE etc. */
#endif

  // slide switches
  uint8_t    switch_position [MAX_SWITCH];

  // ROM:
  bool       *breakpoint;
  char       **source;

  // callbacks into GUI
  display_update_callback_fn_t *display_update_callback;
  void *display_update_callback_ref;

  // debug log
  debug_trace_callback_fn_t *debug_trace_callback;
  void *debug_trace_callback_ref;

  char *log_msg;
  int log_msg_index;
  int log_msg_space;
};


// Returns NULL if error.
chip_t *install_chip (sim_t               *sim,
		      plugin_module_t     *module,
		      const chip_detail_t *chip_detail,
		      void                *chip_data);

void remove_chip (chip_t *chip);

// Notify one or all chips of an event.
void chip_event (sim_t      *sim,
		 chip_t     *chip,
		 event_id_t event,
		 int        arg1,
		 int        arg2,
		 void       *data);

const chip_detail_t *get_chip_detail (chip_t *chip);

void *get_chip_data (chip_t *chip);


// plugin modules:

// debug logging
void log_printf (sim_t *sim, char *fmt, ...);
void log_send (sim_t *sim);
