/*
$Id$
Copyright 1995, 2004 Eric L. Smith <eric@brouhaha.com>

Nonpareil is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License version 2 as
published by the Free Software Foundation.  Note that I am not
granting permission to redistribute or modify CASM under the terms of
any later version of the General Public License.

Nonpareil is distributed in the hope that it will be useful (or at
least amusing), but WITHOUT ANY WARRANTY; without even the implied
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See
the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program (in the file "COPYING"); if not, write to the
Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
MA 02111, USA.
*/


/*
 * The following structures form the interface between proc.c and the actual
 * processor models (e.g., proc_woodstock):
 */


/* dispatch table for processor-specific functions: */

typedef struct
{
  int max_rom;
  int max_bank;

  void (* new_processor)       (sim_t *sim, int ram_size);
  void (* free_processor)      (sim_t *sim);

  bool (* parse_listing_line)  (char *buf, int *bank, int *addr,
				rom_word_t *opcode);

  void (* reset_processor)     (sim_t *sim);
  void (* execute_instruction) (sim_t *sim);

  /* I/O */
  void (* press_key)           (sim_t *sim, int keycode);
  void (* release_key)         (sim_t *sim);
  void (* set_ext_flag)        (sim_t *sim, int flag, bool state);

  /* for debugger: */
  void (* read_ram)            (sim_t *sim, int addr, reg_t *val);
  void (* write_ram)           (sim_t *sim, int addr, reg_t *val);
  void (* disassemble)         (sim_t *sim, int addr, char *buf, int len);

  sim_env_t * (* get_env)      (sim_t *sim); 
  void (* set_env)             (sim_t *sim, sim_env_t *env); 
  void (* free_env)            (sim_t *sim, sim_env_t *env);
  void (* print_state)         (sim_t *sim, sim_env_t *env);
} processor_dispatch_t;


extern processor_dispatch_t *processor_dispatch [ARCH_MAX];


/* common to all architectures: */

typedef enum
  {
    SIM_UNKNOWN,
    SIM_IDLE,
    SIM_RESET,
    SIM_STEP,
    SIM_RUN,
    SIM_QUIT
  } sim_state_t;

struct sim_t
{
  /* These glib items should be moved into an outer structure so that
     the architecture-specific processor code doesn't have to know
     about them. */
  GThread *thread;
  GCond *sim_cond;
  GCond *ui_cond;
  GMutex *sim_mutex;

  GTimeVal tv;
  GTimeVal prev_tv;

  sim_state_t state;
  sim_state_t prev_state;

  int arch;
  processor_dispatch_t *proc;

  sim_env_t *env;		/* architecture-unique */
  uint64_t cycle_count;

  void (*display_update)(char *buf);

  rom_word_t *ucode;
  char       **source;
  bool       *breakpoint;

  void (* op_fcn [1024])(struct sim_t *sim, int opcode);

  char prev_display [(WSIZE + 1) * 2 + 1];
};


