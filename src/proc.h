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


#define MAX_RAM 1024  // $$$ ugly hack, needs to go!
#define MAX_PF   256  // $$$ ugly hack, needs to go!


// common events:
enum
{
  event_reset,
  event_power_down,
  event_power_up,
  event_sleep,
  event_wake,
  event_cycle,       // occurs during every simulation cycle
  event_save_starting,
  event_save_completed,
  event_restore_starting,
  event_restore_completed,

  first_arch_event = 0x100
};


typedef uint32_t addr_t;

typedef uint16_t rom_word_t;


/* simulator state, common to all architectures (opaque): */
typedef struct sim_t sim_t;


// chip_info_t is used to get information on chips
typedef struct
{
  char *name;
  addr_t addr;
} chip_info_t;


// ref_info_t is used to get information on the available architecturally
// visible state of a simulated chip.
typedef struct
{
  char *name;
  int  element_bits;
  int  array_element_count;
  int  display_radix;
} reg_info_t;


/*
 * Create the sim thread, initially in idle state
 *
 * ram_size is the count of RAM registers external to the ARC chip,
 * 10 for HP-45, 30 for HP-55.
 */
sim_t *sim_init  (int model,
		  int clock_frequency,  /* Hz */
		  int ram_size,
		  segment_bitmap_t *char_gen);

int sim_get_model (sim_t *sim);


bool sim_read_object_file (sim_t *sim,
			   char *fn);

bool sim_read_listing_file (struct sim_t *sim,
			    char *fn);

/*
 * The following functions all send messages from the GUI thread to
 * the simulator thread, and wait for a reply.
 */

void sim_event        (sim_t *sim, int event);

void sim_quit         (sim_t *sim);  // kill the sim thread

void sim_reset        (sim_t *sim);  // resets simulated processor
void sim_single_cycle (sim_t *sim);  // executes one "cycle"
void sim_single_inst  (sim_t *sim);  // executes one instruction
void sim_start        (sim_t *sim);  // starts executing instructions (set run flag)
void sim_stop         (sim_t *sim);  // stops executing instructions (clear run flag)

bool sim_running      (sim_t *sim);  // is the simulation running? (get run flag)


// The simulation pause flag is used to stop the simulator for state I/O.  It
// overrides (but does not alter) the run flag.
void sim_set_io_pause_flag (sim_t *sim, bool pause_flag);
bool sim_get_io_pause_flag (sim_t *sim);


uint64_t sim_get_cycle_count (sim_t *siim);

void sim_set_cycle_count (sim_t *sim,
			  uint64_t count);

bool sim_read_rom  (sim_t      *sim,
		    uint8_t    bank,
		    addr_t     addr,
		    rom_word_t *val);

bool sim_write_rom (sim_t      *sim,
		    uint8_t    bank,
		    addr_t     addr,
		    rom_word_t *val);

addr_t sim_get_max_ram (sim_t *sim);

bool sim_read_ram (sim_t *sim,
		   addr_t addr,
		   uint64_t *val);

bool sim_write_ram (sim_t *sim,
		    addr_t addr,
		    uint64_t *val);


// Returns n where valid chip numbers may be in the range 0 .. n-1.
// Note that not all chips in the range will necessarily exist, and
// that chips don't necessarily have consecutive numbers.
int sim_get_max_chip_count (sim_t *sim);


// Returns NULL if specified chip_num doesn't exist.
const chip_info_t *sim_get_chip_info (sim_t *sim,
				      int   chip_num);



// Returns n where valid register numbers are in the range 0 .. n-1.
int sim_get_reg_count (sim_t *sim, int chip_num);


// Returns register number, or -1 if not found.
int sim_find_register (sim_t *sim,
		       int   chip_num,
		       char  *name);


// returns NULL if reg_num out of range
const reg_info_t *sim_get_register_info (sim_t *sim,
					 int   chip_num,
					 int   reg_num);  // 0 and up

// returns false if reg_num or index out of range
bool sim_read_register (sim_t   *sim,
			int     chip_num,
			int     reg_num,
			int     index,
			uint64_t *val);

// returns false if reg_num or index out of range
bool sim_write_register (sim_t   *sim,
			 int     chip_num,
			 int     reg_num,
			 int     index,
			 uint64_t *val);

void sim_press_key (sim_t *sim,
		    int keycode);

void sim_release_key (sim_t *sim);

void sim_set_ext_flag (sim_t *sim,
		       int flag,
		       bool state);

void sim_get_display_update (sim_t *sim);

#ifdef HAS_DEBUGGER

#define SIM_DEBUG_TRACE     0
#define SIM_DEBUG_RAM_TRACE 1
#define SIM_DEBUG_KEY_TRACE 2

void sim_set_debug_flag (sim_t *sim, int debug_flag, bool val);

bool sim_get_debug_flag (sim_t *sim, int debug_flag);

void sim_set_breakpoint (sim_t  *sim,
			 addr_t address);

void sim_clear_breakpoint (sim_t  *sim,
			   addr_t address);

#endif // HAS_DEBUGGER


/*
 * The following functions all send messages from the simulator thread to the
 * GUI thread, but do not wait for a reply..
 */

void gui_display_update (sim_t *sim);
