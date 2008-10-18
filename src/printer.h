/*
$Id$
Copyright 2005, 2008 Eric Smith <eric@brouhaha.com>

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


#define PRINTER_MODE_MAN 0
#define PRINTER_MODE_TRACE 1
#define PRINTER_MODE_NORM 2


enum
{
  event_printer_set_mode = first_printer_event,
  event_printer_print_button,
  event_printer_paper_advance_button
};


typedef struct
{
  bool tear;
  int col_count;
  uint8_t columns [0];
} printer_line_data_t;


// config flags:
#define HAS_PAPER_ADVANCE_BUTTON 0x01
#define HAS_PRINT_BUTTON         0x02
#define HAS_MODE_SWITCH          0x04


chip_t *gui_printer_install (sim_t           *sim,
			     plugin_module_t *module,
			     chip_type_t     type,
			     int32_t         index,
			     int32_t         flags);


#define MAX_CHARACTER_WIDTH_PIXELS 7
#define MAX_PRINTER_WIDTH_CHARS 24
#define MAX_PRINTER_WIDTH_PIXELS (MAX_PRINTER_WIDTH_CHARS * MAX_CHARACTER_WIDTH_PIXELS)
