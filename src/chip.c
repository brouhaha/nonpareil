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


static char *chip_name [] =
{
  // classic
  [CHIP_CLASSIC_CTC_ARC]             = "classic_ctc_arc",
  [CHIP_CLASSIC_CATHODE_DRIVER]      = "classic_cathode_driver",
  [CHIP_CLASSIC_ANODE_DRIVER]        = "classic_anode_driver",
  [CHIP_CLASSIC_ROM]                 = "classic_rom",
  [CHIP_CLASSIC_RAM]                 = "classic_ram",
  [CHIP_CLASSIC_PROGRAM_MEMORY]      = "classic_program_memory",

  // woodstock (and topcat, spice)
  [CHIP_WOODSTOCK_ACT]               = "woodstock_act",
  [CHIP_WOODSTOCK_CATHODE_DRIVER_12] = "woodstock_cathode_driver_12",
  [CHIP_WOODSTOCK_CATHODE_DRIVER_14] = "woodstock_cathode_driver_14",
  [CHIP_WOODSTOCK_ROM_ANODE_DRIVER]  = "woodstock_anode_driver",
  [CHIP_WOODSTOCK_RAM]               = "woodstock_ram",
  [CHIP_WOODSTOCK_ROM_RAM]           = "woodstock_rom_ram",
  [CHIP_WOODSTOCK_PICK]              = "woodstock_pick",
  [CHIP_WOODSTOCK_CRC]               = "woodstock_crc",

  // coconut & peripherals
  [CHIP_NUT_CPU]                     = "nut_cpu",
  [CHIP_NUT_ROM]                     = "nut_rom",
  [CHIP_NUT_RAM]                     = "nut_ram",
  [CHIP_NUT_LCD]                     = "nut_lcd",
  [CHIP_PHINEAS]                     = "nut_phineas",
  [CHIP_HELIOS]                      = "nut_helios",
  [CHIP_HYSTER]                      = "nut_hyster",
  [CHIP_CHESHIRE]                    = "nut_cheshire",
  [CHIP_GRAPENUTS]                   = "nut_grapenuts",
  [CHIP_BLINKY]                      = "nut_blinky",

  // voyager (uses NUT CPU)
  [CHIP_VOYAGER_R2D2]                = "voyager_r2d2"
} chip_type_t;
