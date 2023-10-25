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


#define MAX_RAM 1024  // $$$ ugly hack, needs to go!
#define MAX_PF   256  // $$$ ugly hack, needs to go!


#define MAX_SWITCH 4           // maximum number of slide switches
#define MAX_SWITCH_POSITION 3  // max number of positions per switch

// common events:
typedef enum
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
  event_remove_chip,

  event_key,        // arg1 is keycode (user), arg2 is new value (bool)
  event_set_flag,   // arg1 selects flag, arg2 is new value (bool)
  event_pulse_flag, // arg1 selects flag

  first_arch_event = 0x100,   // CPU architecture specific events

  first_chip_event = 0x200,   // chip specific events

  // Printer events are applicable to several chips, so we'll define
  // a base for them.
  first_printer_event = 0x0300
} event_id_t;


typedef uint8_t bank_t;         // bank number
typedef uint32_t bank_mask_t;   // bank bitmask

// sim->proc->max_bank can't be more than this:
#define MAX_MAX_BANK (sizeof (bank_mask_t) * 8)


typedef uint32_t addr_t;

typedef uint16_t rom_word_t;


/* simulator state, common to all architectures (opaque): */
typedef struct sim_t sim_t;


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


typedef void debug_trace_callback_fn_t (void *ref,
					char *msg);


/*
 * Create the sim thread, initially in idle state
 */
sim_t *sim_init  (char *ncd_fn,
		  display_update_callback_fn_t *display_update_callback,
		  void *display_update_callback_ref);

void sim_init_debug_trace_callback (sim_t *sim,
				    debug_trace_callback_fn_t *debug_trace_callback,
				    void *debug_trace_callback_ref);


calcdef_t *sim_get_calcdef (sim_t *sim);

const char *sim_get_ncd_fn (sim_t *sim);


//bool sim_read_object_file (sim_t *sim,
//			   char *fn);

bool sim_read_listing_file (struct sim_t *sim,
			    char *fn);


// Plugin modules:

typedef struct plugin_module_t plugin_module_t;

plugin_module_t *plugin_module_get_by_port (sim_t *sim,
					    int port);

int plugin_module_get_port (plugin_module_t *module);

char *plugin_module_get_path (plugin_module_t *module);

char *plugin_module_get_name (plugin_module_t *module);

plugin_module_t *sim_install_module (sim_t *sim,
				     char *fn,
				     int port,
				     bool mem_only);

bool sim_remove_module (sim_t *sim,
			plugin_module_t *module);


/*
 * The following functions all send messages from the GUI thread to
 * the simulator thread, and wait for a reply.
 */

// If data is passed, chip becomes responsible for freeing it, or returning
// it to the GUI via an asynchronous notification.
void sim_event        (sim_t      *sim,
		       chip_t     *chip,  // NULL for all chips
		       event_id_t event,
		       int        arg1,
		       int        arg2,
		       void       *data);

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
bool sim_create_page      (sim_t           *sim,
			   bank_t          bank,
			   uint8_t         page,
			   bool            ram,
			   plugin_module_t *module);
bool sim_destroy_page     (sim_t           *sim,
			   bank_t          bank,
			   uint8_t         page);
bool sim_get_page_info    (sim_t           *sim,
			   bank_t          bank,
			   uint8_t         page,
			   plugin_module_t **module,
			   bool            *ram,
			   bool            *write_enable);

bool sim_read_rom  (sim_t      *sim,
		    bank_t     bank,
		    addr_t     addr,
		    rom_word_t *val);

bool sim_write_rom (sim_t      *sim,
		    bank_t     bank,
		    addr_t     addr,
		    rom_word_t *val);

bool sim_set_rom_write_enable (sim_t   *sim,
			       bank_t  bank,
			       addr_t  addr,
			       bool    write_enable);
				

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


// Pass in NULL for module to get first module.
// Returns NULL if there are no more modules.
plugin_module_t *sim_get_next_module (sim_t *sim, plugin_module_t *module);


// Chip access routines

// Callback function used when chip sends asynchronous commands and/or data
// to GUI.  If data != NULL, callback should free it.
typedef void chip_callback_fn_t (sim_t  *sim,
				 chip_t *chip,
				 void   *ref,
				 void   *data);


chip_t *sim_add_chip (sim_t              *sim,
		      plugin_module_t    *module,
		      chip_type_t        type,
		      int32_t            index,
		      int32_t            flags,
		      chip_callback_fn_t *callback_fn,
		      void               *callback_ref);

bool sim_remove_chip (sim_t  *sim,
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

// press/release key, state=true for press
void sim_key (sim_t *sim,
	      int keycode,
	      bool state);

bool sim_set_switch (sim_t *sim,
		     uint8_t sw,
		     uint8_t position);

bool sim_get_switch (sim_t *sim,
		     uint8_t sw,
		     uint8_t *position);

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

void sim_set_debug_trace_msg_to_gui (sim_t *sim,
				     char *msg);


// instruction flow type returned by disassembler:

typedef enum
{
  flow_no_branch,
  flow_cond_branch,
  flow_uncond_branch,
  flow_uncond_branch_keycode,
  flow_uncond_branch_computed,
  flow_subroutine_call,  // conditional or unconditional
  flow_cond_subroutine_return,
  flow_subroutine_return,
  flow_bank_switch,
  flow_select_rom,  // used internally to disassembler
  flow_delayed_rom,  // used internally to disassembler
  MAX_FLOW_TYPE
} flow_type_t;

typedef struct
{
  bool has_target;
  bool ends_flow;
} flow_type_info_t;

extern flow_type_info_t flow_type_info [MAX_FLOW_TYPE];

typedef enum
{
  inst_normal,
  inst_woodstock_then_goto,
  inst_woodstock_selftest,
  inst_nut_long_branch,
  inst_nut_cxisa,
  inst_nut_ldi,
  inst_nut_selpf         // "smart" peripheral selected (NPIC, PIL)
} inst_state_t;


#define DIS_FLAG_LISTING (1 << 0)
#define DIS_FLAG_LABEL   (1 << 1)

bool sim_disassemble (sim_t        *sim,
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

bool sim_disassemble_runtime (sim_t        *sim,
			      uint32_t     flags,
			      bank_t       bank,
			      addr_t       addr,
			      inst_state_t inst_state,
			      bool         carry,
			      addr_t       delayed_select_mask,
			      addr_t       delayed_select_addr,
			      char         *buf,
			      int          len);
