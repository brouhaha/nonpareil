/*
CSIM is a simulator for the processor used in the HP "Classic" series
of calculators, which includes the HP-35, HP-45, HP-55, HP-65, HP-70,
and HP-80.

$Id$
Copyright 1995, 2004 Eric L. Smith

CSIM is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License version 2 as published by the Free
Software Foundation.  Note that I am not granting permission to redistribute
or modify CSIM under the terms of any later version of the General Public
License.

This program is distributed in the hope that it will be useful (or at least
amusing), but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with
this program (in the file "COPYING"); if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/


#define WSIZE 14

typedef uint8_t digit_t;
typedef digit_t reg_t [WSIZE];

#define SSIZE 12


typedef uint16_t romword;


typedef struct
{
  reg_t a;
  reg_t b;
  reg_t c;
  reg_t d;
  reg_t e;
  reg_t f;
  reg_t m;

  digit_t p;

  uint8_t carry, prev_carry;

  uint8_t s [SSIZE];

  int ram_addr;  /* selected RAM address */

  int max_ram;
  reg_t *ram;

  uint8_t pc;
  uint8_t rom;
  uint8_t group;

  uint8_t del_rom;
  uint8_t del_grp;

  uint8_t ret_pc;

  int prev_pc;  /* used to store complete five-digit octal address of instruction */

  int display_enable;
  int io_count;

  gboolean key_flag;  /* true if a key is down */
  int key_buf;        /* most recently pressed key */

  uint8_t ext_flag [SSIZE];  /* external flags, e.g., slide switches,
				magnetic card inserted */
} sim_env_t;


/*
 * Create the sim thread, initially in idle state
 *
 * ram_size is the count of RAM registers external to the ARC chip,
 * 10 for HP-45, 30 for HP-55.
 *
 * display_update_fn() is a callback invoked whenever the display
 * contents change.  Note that it is called in the simulator thread
 * context, so it will probably have to deal with mutexes.
 */
struct sim_handle_t *sim_init  (int ram_size,
				void (*display_update_fn)(char *buf));

/* kill the sim thread */
void sim_quit  (struct sim_handle_t *sim);

gboolean sim_read_object_file (struct sim_handle_t *sim,
			       char *fn);

gboolean sim_read_listing_file (struct sim_handle_t *sim,
				char *fn,
				int keep_src);

void sim_reset (struct sim_handle_t *sim);  /* resets simulated processor */
void sim_step  (struct sim_handle_t *sim);  /* executes one instruction */
void sim_start (struct sim_handle_t *sim);  /* starts simulation */
void sim_stop  (struct sim_handle_t *sim);  /* stops simulation */

gboolean sim_running (struct sim_handle_t *sim);  /* is the simulation running? */


uint64_t sim_get_cycle_count (struct sim_handle_t *siim);

void sim_set_cycle_count (struct sim_handle_t *sim,
			  uint64_t count);

void sim_set_breakpoint (struct sim_handle_t *sim,
			 int address);

void sim_clear_breakpoint (struct sim_handle_t *sim,
			   int address);


/* copy the simulator state into the sim_env_t supplied by the caller */
void sim_get_env (struct sim_handle_t *sim,
		  sim_env_t *env);

/* copy a sim_env_t into the simulator state */
void sim_set_env (struct sim_handle_t *sim,
		  sim_env_t *env);


romword sim_read_rom (struct sim_handle_t *sim,
		      int addr);

uint32_t sim_get_rom_accessed_count (struct sim_handle_t *sim);


void sim_read_ram (struct sim_handle_t *sim,
		   int addr,
		   reg_t *val);

void sim_write_ram (struct sim_handle_t *sim,
		    int addr,
		    reg_t *val);


void sim_press_key (struct sim_handle_t *sim,
		    int keycode);

void sim_release_key (struct sim_handle_t *sim);

void sim_set_ext_flag (struct sim_handle_t *sim,
		       int flag,
		       gboolean state);
