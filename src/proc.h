/*
$Id$
Copyright 1995, 2004, 2005, 2006 Eric L. Smith <eric@brouhaha.com>

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


#define MAX_SWITCH 4           // maximum number of slide switches
#define MAX_SWITCH_POSITION 3  // max number of positions per switch

// common events:
enum
{
  event_reset,
  event_clear_memory,
  event_power_down,
  event_power_up,
  event_sleep,
  event_wake,
  event_cycle,       // occurs during every simulation cycle
  event_save_starting,
  event_save_completed,
  event_restore_starting,
  event_restore_completed,

  first_arch_event = 0x100,  // CPU architecture specific events

  first_chip_event = 0x200   // chip specific events
};


typedef uint8_t bank_t;         // bank number
typedef uint32_t bank_mask_t;   // bank bitmask

// sim->proc->max_bank can't be more than this:
#define MAX_MAX_BANK (sizeof (bank_mask_t) * 8)


typedef uint32_t addr_t;

typedef uint16_t rom_word_t;


/* simulator state, common to all architectures (opaque): */
typedef struct sim_t sim_t;


// opaque type representing a chip (or more generally, a hardware device)
typedef struct chip_t chip_t;


typedef enum
{
  // generic
  CHIP_CPU,
  CHIP_DISPLAY,

  // coconut & peripherals
  CHIP_PHINEAS,
  CHIP_HELIOS,

  MAX_CHIP_TYPE  // must be last
} chip_type_t;


// chip_info_t is used to get information on chips
typedef struct
{
  char        *name;
  chip_type_t type;
  bool        multiple;  // True if there might be more than one chip of this
                         // kind, in which case register #0 should contain the
                         // necessary distinguishing information (e.g.,
                         // address)
} chip_info_t;


// reg_info_t is used to get information on the available architecturally
// visible state of a simulated chip.
typedef struct
{
  char *name;
  int  element_bits;
  int  array_element_count;
  int  display_radix;
} reg_info_t;


typedef bool install_hardware_callback_fn_t (void *ref,
					     chip_type_t chip_type);
					     


// callback function that will be used for display updates
typedef void display_update_callback_fn_t (void *ref,
					   int digit_count,
					   segment_bitmap_t *segments);


/*
 * Create the sim thread, initially in idle state
 */
sim_t *sim_init  (char *ncd_fn,
		  install_hardware_callback_fn_t *install_hardware_callback,
		  void *install_hardware_callback_ref,
		  display_update_callback_fn_t *display_update_callback,
		  void *display_update_callback_ref);


const char *sim_get_model_name (sim_t *sim);

const char *sim_get_ncd_fn (sim_t *sim);


bool sim_read_object_file (sim_t *sim,
			   char *fn);

bool sim_read_listing_file (struct sim_t *sim,
			    char *fn);


// Plugin modules:

typedef struct plugin_module_t plugin_module_t;

plugin_module_t *sim_install_module (sim_t *sim, char *fn, int port);

bool sim_remove_module (plugin_module_t *module);


/*
 * The following functions all send messages from the GUI thread to
 * the simulator thread, and wait for a reply.
 */

// If data is passed, chip becomes responsible for freeing it.
void sim_event        (sim_t  *sim,
		       int    event,
		       chip_t *chip,  // NULL for all chips
		       int    arg,
		       void   *data);

void sim_quit         (sim_t *sim);  // kill the sim thread

void sim_reset        (sim_t *sim);  // resets simulated processor
void sim_clear_memory (sim_t *sim);  // clears all writeable memory
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

// Bank switching routines
// $$$ should be replaced by new memory API
int sim_create_bank_group (sim_t *sim);

bool sim_set_bank_group (sim_t   *sim,
			 int     bank_group,
			 addr_t  addr);

// ROM access routines
// $$$ should be replaced by new memory API
int sim_get_max_rom_bank  (sim_t *sim);
int sim_get_rom_page_size (sim_t *sim);
int sim_get_max_rom_addr  (sim_t *sim);
bool sim_page_exists      (sim_t *sim, bank_t bank, uint8_t page);

bool sim_read_rom  (sim_t      *sim,
		    bank_t     bank,
		    addr_t     addr,
		    rom_word_t *val);

bool sim_write_rom (sim_t      *sim,
		    bank_t     bank,
		    addr_t     addr,
		    rom_word_t *val);

// RAM access routines
// $$$ should be replaced by new memory API
addr_t sim_get_max_ram_addr (sim_t *sim);

bool sim_create_ram (sim_t *sim,
		     addr_t addr,
		     addr_t size);

bool sim_read_ram (sim_t *sim,
		   addr_t addr,
		   uint64_t *val);

bool sim_write_ram (sim_t *sim,
		    addr_t addr,
		    uint64_t *val);


// Chip access routines

// Callback function used when chip sends asynchronous commands and/or data
// to GUI.  If data != NULL, callback should free it.
typedef void chip_callback_fn_t (sim_t  *sim,
				 chip_t *chip,
				 void   *ref,
				 void   *data);


chip_t *sim_add_chip (sim_t              *sim,
		      chip_type_t        type,
		      chip_callback_fn_t *callback_fn,
		      void               *callback_ref);

void sim_remove_chip (sim_t  *sim,
		      chip_t *chip);


// Pass in NULL for chip to get first chip.
// Returns NULL if there are no more chips.
chip_t *sim_get_next_chip (sim_t *sim, chip_t *chip);


// Returns NULL if it can't find a chip with the specified name
// (and address for chips that support multiple instances).
chip_t *sim_find_chip (sim_t *sim,
		       const char *name,
		       uint64_t addr);


// Returns NULL if specified chip_num doesn't exist.
const chip_info_t *sim_get_chip_info (sim_t *sim,
				      chip_t *chip);



// Returns n where valid register numbers are in the range 0 .. n-1.
int sim_get_reg_count (sim_t *sim, chip_t *chip);


// Returns register number, or -1 if not found.
int sim_find_register (sim_t *sim,
		       chip_t *chip,
		       char  *name);


// returns NULL if reg_num out of range
const reg_info_t *sim_get_register_info (sim_t *sim,
					 chip_t *chip,
					 int   reg_num);  // 0 and up

// returns false if reg_num or index out of range
bool sim_read_register (sim_t   *sim,
			chip_t  *chip,
			int     reg_num,
			int     index,
			uint64_t *val);

// returns false if reg_num or index out of range
bool sim_write_register (sim_t   *sim,
			 chip_t  *chip,
			 int     reg_num,
			 int     index,
			 uint64_t *val);

void sim_press_key (sim_t *sim,
		    int keycode);

void sim_release_key (sim_t *sim);

// sets up an association between a switch position and an ext flag
void sim_set_switch_flag (sim_t *sim,
			  uint8_t sw,
			  uint8_t position,
			  int flag);

bool sim_set_switch (sim_t *sim,
		     uint8_t sw,
		     uint8_t position);

bool sim_get_switch (sim_t *sim,
		     uint8_t sw,
		     uint8_t *position);

void sim_set_ext_flag (sim_t *sim,
		       int flag,
		       bool state);

void sim_get_display_update (sim_t *sim);

#if 1 || defined(HAS_DEBUGGER)

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

void sim_send_display_update_to_gui (sim_t *sim);

void sim_send_chip_msg_to_gui (sim_t  *sim,
			       chip_t *chip,
			       void   *data);


// instruction flow type returned by disassembler:

typedef enum
{
  flow_no_branch,
  flow_cond_branch,
  flow_uncond_branch,
  flow_uncond_branch_keycode,
  flow_uncond_branch_computed,
  flow_subroutine_call,
  flow_subroutine_return,
  flow_bank_switch,
  MAX_FLOW_TYPE
} flow_type_t;

bool sim_disassemble (sim_t  *sim,
		      // input and output:
		      bank_t *bank,
		      addr_t *addr,
		      bool   *carry_known_clear,
		      addr_t *delayed_select_mask,
		      addr_t *delayed_select_addr,
		      // output:
		      flow_type_t *flow_type,
		      bank_t *target_bank,
		      addr_t *target_addr,
		      char *buf,
		      int len);

