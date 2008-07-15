/*
$Id$
Copyright 1995, 2003, 2004, 2005, 2008 Eric Smith <eric@brouhaha.com>

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


typedef uint8_t digit_t;


digit_t digit_add (digit_t x, digit_t y, bool *carry, uint8_t base);

digit_t digit_sub (digit_t x, digit_t y, bool *carry, uint8_t base);

digit_t digit_add_sub (bool sub, digit_t x, digit_t y, bool *carry, uint8_t base);


void reg_zero (digit_t *dest, int first, int last);

void reg_copy (digit_t *dest, const digit_t *src, int first, int last);

void reg_exch (digit_t *dest, digit_t *src, int first, int last);

void reg_add (digit_t *dest, const digit_t *src1, const digit_t *src2,
	      int first, int last,
	      bool *carry, uint8_t base);

void reg_sub (digit_t *dest, const digit_t *src1, const digit_t *src2,
	      int first, int last,
	      bool *carry, uint8_t base);

// sets carry if equal
void reg_test_equal    (const digit_t *src1, const digit_t *src2,
			int first, int last,
			bool *carry);

// sets carry if nonequal
void reg_test_nonequal (const digit_t *src1, const digit_t *src2,
			int first, int last,
			bool *carry);

void reg_shift_right (digit_t *reg, int first, int last);

void reg_shift_left (digit_t *reg, int first, int last);


// reg to native host binary and vice versa
uint64_t reg_to_binary (digit_t *reg, int digits);

void binary_to_reg (uint64_t val, digit_t *reg, int digits);


// BCD to native host binary and vice versa
uint64_t bcd_reg_to_binary (digit_t *reg, int digits);

void binary_to_bcd_reg (uint64_t val, digit_t *reg, int digits);
