/*
Copyright 2007-2009, 2022 Eric Smith <spacewar@gmail.com>

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


#define PICK_KEY_BUFFER_SIZE 7

// The PICK keyboard buffer is read as RAM at address 0xff
#define RAMADDR_PICK 0xff


#define PICK_PRINTER_CHARACTER_WIDTH_PIXELS 7
#define PICK_PRINTER_WIDTH_CHARS 20
#define PICK_PRINTER_WIDTH_PIXELS (PICK_PRINTER_WIDTH_CHARS * PICK_PRINTER_CHARACTER_WIDTH_PIXELS)

#define PICK_PRINTER_CHARACTER_HEIGHT_PIXELS 7
#define PICK_PRINTER_LINE_HEIGHT_PIXELS 12


typedef enum
{
  PICK_KEY_RET_LINE_KA = 4,
  PICK_KEY_RET_LINE_KC = 1,
  PICK_KEY_RET_LINE_KD = 8,
  PICK_KEY_RET_LINE_KE = 0,
} pick_key_ret_line_t;


chip_t *pick_install (sim_t           *sim,
		      plugin_module_t *module,
		      chip_type_t     type,
		      int32_t         index,
		      int32_t         flags);

// for key trace support
bool pick_key_buffer_empty (sim_t *sim);
