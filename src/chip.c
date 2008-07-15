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

#include <stdint.h>
#include <string.h>

#include "chip.h"

// chip GUI install functions:
chip_install_fn_t gui_printer_install;

// chip install functions:
chip_install_fn_t crc_install;
chip_install_fn_t pick_install;

chip_install_fn_t coconut_lcd_install;
chip_install_fn_t helios_install;
chip_install_fn_t phineas_install;

chip_install_fn_t voyager_r2d2_install;

static chip_type_info_t chip_type_info [] =
{
  [CHIP_UNKNOWN]                     = { "unknown", NULL, NULL },

  // classic
  [CHIP_CLASSIC_CTC]                 = { "classic_ctc", NULL, NULL },
  [CHIP_CLASSIC_ARC]                 = { "classic_arc", NULL, NULL },
  [CHIP_CLASSIC_CLOCK_DRIVER]        = { "classic_clock_driver", NULL, NULL },
  [CHIP_CLASSIC_CATHODE_DRIVER]      = { "classic_cathode_driver", NULL, NULL },
  [CHIP_CLASSIC_ANODE_DRIVER]        = { "classic_anode_driver", NULL, NULL },
  [CHIP_CLASSIC_ROM]                 = { "classic_rom", NULL, NULL },
  [CHIP_CLASSIC_RAM]                 = { "classic_ram", NULL, NULL },
  [CHIP_CLASSIC_PROGRAM_MEMORY]      = { "classic_program_memory", NULL, NULL },

  // woodstock (and topcat, sting)
  [CHIP_WOODSTOCK_ACT]               = { "woodstock_act", NULL, NULL },
  [CHIP_WOODSTOCK_CATHODE_DRIVER_12] = { "woodstock_cathode_driver_12", NULL, NULL },
  [CHIP_WOODSTOCK_CATHODE_DRIVER_14] = { "woodstock_cathode_driver_14", NULL, NULL },
  [CHIP_WOODSTOCK_ROM_ANODE_DRIVER]  = { "woodstock_anode_driver", NULL, NULL },
  [CHIP_WOODSTOCK_RAM]               = { "woodstock_ram", NULL, NULL },
  [CHIP_WOODSTOCK_ROM_RAM]           = { "woodstock_rom_ram", NULL, NULL },
  [CHIP_WOODSTOCK_PICK]              = { "woodstock_pick", gui_printer_install, pick_install },
  [CHIP_WOODSTOCK_CRC]               = { "woodstock_crc", NULL, crc_install },

  // spice
  [CHIP_SPICE_ACT]                   = { "spice_act", NULL, NULL },

  // coconut & peripherals
  [CHIP_NUT_CPU]                     = { "nut_cpu", NULL, NULL },
  [CHIP_NUT_ROM]                     = { "nut_rom", NULL, NULL },
  [CHIP_NUT_RAM]                     = { "nut_ram", NULL, NULL },
  [CHIP_COCONUT_LCD]                 = { "coconut_lcd", NULL, coconut_lcd_install },
  [CHIP_PHINEAS]                     = { "nut_phineas", NULL, phineas_install },
  [CHIP_HELIOS]                      = { "nut_helios", NULL, helios_install },
  [CHIP_HYSTER]                      = { "nut_hyster", NULL, NULL },
  [CHIP_CHESHIRE]                    = { "nut_cheshire", NULL, NULL },
  [CHIP_GRAPENUTS]                   = { "nut_grapenuts", NULL, NULL },
  [CHIP_BLINKY]                      = { "nut_blinky", NULL, NULL },

  // voyager (uses NUT CPU)
  [CHIP_VOYAGER_R2D2]                = { "voyager_r2d2", NULL, voyager_r2d2_install },
};


chip_type_t find_chip_type_by_name (char *s)
{
  unsigned int i;

  for (i = 0; i < (sizeof (chip_type_info) / sizeof (chip_type_info_t)); i++)
    {
      if (strcasecmp (s, chip_type_info [i].name) == 0)
	return (chip_type_t) i;
    }
  return CHIP_UNKNOWN;
}


chip_type_info_t *get_chip_type_info (chip_type_t type)
{
  return (& chip_type_info [type]);
}
