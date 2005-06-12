/*
$Id$
Copyright 2005 Eric L. Smith <eric@brouhaha.com>

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


#define PRINTER_CHARACTER_WIDTH_PIXELS 7
#define PRINTER_WIDTH_CHARS 24
#define PRINTER_WIDTH (PRINTER_WIDTH_CHARS * PRINTER_CHARACTER_WIDTH_PIXELS)

#define PRINTER_CHARACTER_HEIGHT_PIXELS 7
#define PRINTER_LINE_HEIGHT_PIXELS 12

#define PRINTER_WINDOW_INITIAL_HEIGHT (10 * PRINTER_LINE_HEIGHT_PIXELS)

#define PRINTER_MAX_BUFFER_LINES (80 * 12 * 6)  // 80 ft of 6 lines per inch


enum
{
  event_printer_set_mode = first_chip_event,
  event_printer_print_button,
  event_printer_paper_advance_button
};


typedef struct
{
  bool tear;
  uint8_t columns [PRINTER_WIDTH];
} printer_line_data_t;



void gui_printer_init (sim_t *sim);
