/*
$Id$
Copyright 2004, 2005, 2006, 2008 Eric Smith <eric@brouhaha.com>

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


struct chip_t;
struct sim_t;


typedef enum
{
  CHIP_UNKNOWN,

  // classic
  CHIP_CLASSIC_CTC,
  CHIP_CLASSIC_ARC,
  CHIP_CLASSIC_CLOCK_DRIVER,
  CHIP_CLASSIC_CATHODE_DRIVER,
  CHIP_CLASSIC_ANODE_DRIVER,
  CHIP_CLASSIC_ROM,
  CHIP_CLASSIC_RAM,
  CHIP_CLASSIC_PROGRAM_MEMORY,

  // woodstock (and topcat, sting)
  CHIP_WOODSTOCK_ACT,
  CHIP_WOODSTOCK_CATHODE_DRIVER_12,  // Woodstock
  CHIP_WOODSTOCK_CATHODE_DRIVER_14,  // 67, 19C, Topcat
  CHIP_WOODSTOCK_ROM_ANODE_DRIVER,
  CHIP_WOODSTOCK_RAM,
  CHIP_WOODSTOCK_ROM_RAM,
  CHIP_WOODSTOCK_PICK,  // Printer Interface Control and Keyboard in Topcat
  CHIP_WOODSTOCK_CRC,   // Card Reader Controller in 67/97

  // spice
  CHIP_SPICE_ACT,

  // coconut & peripherals
  CHIP_NUT_CPU,
  CHIP_NUT_ROM,
  CHIP_NUT_RAM,
  CHIP_COCONUT_LCD,     // two chips, but we'll treat them as one
  CHIP_PHINEAS,		// timer chip in 82184A Time Module, 41CX
  CHIP_HELIOS,		// NPIC chip in 82143A Printer
  CHIP_HYSTER,          // 82104A card reader
  CHIP_CHESHIRE,        // 82153A bar code wand
  CHIP_GRAPENUTS,       // 82160A HP-IL interface
  CHIP_BLINKY,          // 82442A infrared printer interface (for 82440A/B)

  CHIP_HEPAX,           // HEPAX module (third-party)

  // voyager (uses Nut CPU)
  CHIP_VOYAGER_R2D2,    // RAM/ROM/Display Driver

  MAX_CHIP_TYPE 	// must be last
} chip_type_t;


struct plugin_module_t;

typedef struct chip_t *chip_install_fn_t (struct sim_t           *sim,
					  struct plugin_module_t *module,
					  chip_type_t            type,
					  int32_t                index,
					  int32_t                flags);


typedef struct
{
  char *name;
  chip_install_fn_t *chip_gui_install_fn;
  chip_install_fn_t *chip_install_fn;
} chip_type_info_t;


// opaque type representing a chip (or more generally, a hardware device)
typedef struct chip_t chip_t;


chip_type_t find_chip_type_by_name (char *s);

chip_type_info_t *get_chip_type_info (chip_type_t type);

struct plugin_module_t *chip_get_module (chip_t *chip);
