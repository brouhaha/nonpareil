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


typedef bool reg_accessor_t (sim_env_t *env,
			     size_t offset,
			     uint64_t *p);


typedef struct
{
  reg_info_t info;     // publicly visible info: name, bit count, etc.
  size_t     offset;   // offset into sim_env_t
  // accessor functions - if NULL, use default
  reg_accessor_t *get;
  reg_accessor_t *set;
} reg_detail_t;

reg_accessor_t get_14_dig, set_14_dig;
reg_accessor_t get_2_dig, set_2_dig;


/* dispatch table for processor-specific functions: */

typedef struct
{
  int max_rom;
  int max_bank;

  int reg_count;
  reg_detail_t *reg_detail;

  void (* new_processor)       (sim_t *sim, int ram_size);
  void (* free_processor)      (sim_t *sim);

  bool (* parse_object_line)   (char *buf, int *bank, int *addr,
				rom_word_t *opcode);
  bool (* parse_listing_line)  (char *buf, int *bank, int *addr,
				rom_word_t *opcode);

  void (* reset_processor)     (sim_t *sim);

  /* returns false if asleep (can't execute cycles) */
  bool (* execute_cycle)       (sim_t *sim);

  /* returns false if asleep (can't execute instructions) */
  bool (* execute_instruction) (sim_t *sim);

  /* I/O */
  void (* press_key)           (sim_t *sim, int keycode);
  void (* release_key)         (sim_t *sim);
  void (* set_ext_flag)        (sim_t *sim, int flag, bool state);

  /* for debugger: */
  bool (* read_ram)            (sim_t *sim, int addr, uint8_t *val);
  bool (* write_ram)           (sim_t *sim, int addr, uint8_t *val);

  void (* disassemble)         (sim_t *sim, int addr, char *buf, int len);

  void (* print_state)         (sim_t *sim, sim_env_t *env);
} processor_dispatch_t;


extern processor_dispatch_t *processor_dispatch [ARCH_MAX];


/* common to all architectures: */

typedef struct sim_thread_vars_t sim_thread_vars_t;


struct sim_t
{
  bool quit_flag;

  bool run_flag;
  bool single_cycle_flag;
  bool single_inst_flag;

  sim_thread_vars_t *thread_vars;

  int arch;
  processor_dispatch_t *proc;

  int platform;

  double words_per_usec;  /* Processor word times per microsecond, typically
			     much less than 1.  For instance, 3.5e-3 for
			     HP-55. */

  sim_env_t *env;		/* architecture-unique */
  uint64_t cycle_count;

  segment_bitmap_t *char_gen;

  int left_scan;
  int right_scan;
  int display_scan_position;   /* word index, left_scan down to right_scan */
  int display_digit_position;  /* character index, 0 to MAX_DIGIT_POSITION-1 */

  int display_digits;
  segment_bitmap_t display_segments [MAX_DIGIT_POSITION];

  void (* display_scan_fn) (sim_t *sim);

  rom_word_t *ucode;
  bool       *breakpoint;
  char       **source;

#ifdef HAS_DEBUGGER
  int debug_flags;  /* SIM_DEBUG_TRACE etc. */
#endif

  void (* op_fcn [1024])(struct sim_t *sim, int opcode);

  void (* rd_n_fcn [256])(struct sim_t *sim, int n);
  void (* wr_n_fcn [256])(struct sim_t *sim, int n);
  void (* wr_fcn   [256])(struct sim_t *sim);
};


