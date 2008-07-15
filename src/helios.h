/*
$Id$
Copyright 1995, 2005, 2008 Eric Smith <eric@brouhaha.com>

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

// Helios printer (82143A) using NPIC interface chip

// Public definitions, for both sim and GUI threads:

#define PRINTER_MODE_MAN 0
#define PRINTER_MODE_TRACE 1
#define PRINTER_MODE_NORM 2


#define PRINTER_CHARACTER_WIDTH_PIXELS 7
#define PRINTER_WIDTH_CHARS 24
#define PRINTER_WIDTH (PRINTER_WIDTH_CHARS * PRINTER_CHARACTER_WIDTH_PIXELS)

#define PRINTER_CHARACTER_HEIGHT_PIXELS 7


enum
{
  event_printer_set_mode = first_chip_event,
  event_printer_print_button,
  event_printer_paper_advance_button
};


// Private definitions for sim thread only:

#define HELIOS_NPIC_PERTCT_ADDR 9

extern uint8_t helios_chargen [128][5];

chip_t *helios_install (sim_t *sim,
			int32_t index,
			int32_t flags);
