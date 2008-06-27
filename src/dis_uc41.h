/*
$Id$
Copyright 2008 Eric Smith <eric@brouhaha.com>

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

bool uc41_disassemble (sim_t        *sim,
		       uint32_t     flags UNUSED,
		       // input and output:
		       bank_t       *bank,
		       addr_t       *addr,
		       inst_state_t *inst_state,
		       bool         *carry_known_clear,
		       addr_t       *delayed_select_mask UNUSED,
		       addr_t       *delayed_select_addr UNUSED,
		       // output:
		       flow_type_t  *flow_type,
		       bank_t       *target_bank,
		       addr_t       *target_addr,
		       char         *buf,
		       int          len);
