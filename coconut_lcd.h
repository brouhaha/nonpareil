/*
NSIM is a simulator for the processor used in the HP-41 (Nut) and in the HP
Series 10 (Voyager) calculators.

$Id$
Copyright 1995, 2003 Eric Smith <eric@brouhaha.com>

NSIM is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License version 2 as published by the Free
Software Foundation.  Note that I am not granting permission to redistribute
or modify NSIM under the terms of any later version of the General Public
License.

This program is distributed in the hope that it will be useful (or at least
amusing), but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with
this program (in the file "COPYING"); if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/


#define DISPLAY_DIGITS 12


// I/O addresses:

#define LCD_DISPLAY 0xfd
#define HALFNUT     0x10


void coconut_display_init_ops (sim_t *sim);

void coconut_display_reset (sim_t *sim);

void coconut_display_update (sim_t *sim);
