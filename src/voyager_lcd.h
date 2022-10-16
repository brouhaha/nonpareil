/*
Copyright 1995, 2004, 2005, 2008, 2022 Eric Smith <spacewar@gmail.com>

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


// The Voyager display doesn't have a peripheral address like the
// Coconut display, but we have to pick a chip number somehow, so we'll
// use the same one.
#define PFADDR_LCD_DISPLAY 0xfd


chip_t *voyager_r2d2_install (sim_t           *sim,
			      plugin_module_t *module,
			      chip_type_t     chip_type,
			      int32_t         index,
			      int32_t         flags);
