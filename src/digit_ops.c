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


#include <stdbool.h>
#include <stdint.h>

#include "digit_ops.h"


void reg_zero (digit_t *dest, int first, int last)
{
  int i;
  for (i = first; i <= last; i++)
    dest [i] = 0;
}


void reg_copy (digit_t *dest, const digit_t *src, int first, int last)
{
  int i;
  for (i = first; i <= last; i++)
    dest [i] = src [i];
}


void reg_exch (digit_t *dest, digit_t *src, int first, int last)
{
  int i, t;
  for (i = first; i <= last; i++)
    {
      t = dest [i];
      dest [i] = src [i];
      src [i] = t;
    }
}


digit_t digit_add_sub (bool sub, digit_t x, digit_t y, bool *carry, uint8_t base)
{
  digit_t s;

  *carry ^= sub;  // for subtract, treat carry flag as borrow;
  if (sub)
    y ^= 0xf;
  s = x + y + *carry;
  *carry = s > 0xf;
  if (base == 10)
    {
      if (sub)
	{
	  if (! *carry)
	    s += 10;
	}
      else
	{
	  *carry |= (s > 9);
	  if (*carry)
	    s += 6;
	}
    }
  *carry ^= sub;  // for subtract, treat carry flag as borrow;
  return s & 0xf;
}


void reg_add (digit_t *dest, const digit_t *src1, const digit_t *src2,
	      int first, int last,
	      bool *carry, uint8_t base)
{
  int i;

  for (i = first; i <= last; i++)
    {
      int s2 = src2 ? src2 [i] : 0;
      dest [i] = digit_add_sub (false, src1 [i], s2, carry, base);
    }
}


void reg_sub (digit_t *dest, const digit_t *src1, const digit_t *src2,
	      int first, int last,
	      bool *carry, uint8_t base)
{
  int i;

  for (i = first; i <= last; i++)
    {
      int s1 = src1 ? src1 [i] : 0;
      int s2 = src2 ? src2 [i] : 0;
      int d = digit_add_sub (true, s1, s2, carry, base);
      if (dest)
	dest [i] = d;
    }
}


// $$$ if in decimal mode, do illegal digits get normalized?
void reg_test_equal    (const digit_t *src1, const digit_t *src2,
			int first, int last,
			bool *carry)
{
  int i;

  *carry = true;
  for (i = first; i <= last; i++)
    {
      int s2 = src2 ? src2 [i] : 0;
      (*carry) &= (src1 [i] == s2);
    }
}


// $$$ if in decimal mode, do illegal digits get normalized?
void reg_test_nonequal (const digit_t *src1, const digit_t *src2,
			int first, int last,
			bool *carry)
{
  int i;

  *carry = false;
  for (i = first; i <= last; i++)
    {
      int s2 = src2 ? src2 [i] : 0;
      (*carry) |= (src1 [i] != s2);
    }
}


void reg_shift_right (digit_t *reg, int first, int last)
{
  int i;

  for (i = first; i <= last; i++)
    reg [i] = (i == last) ? 0 : reg [i+1];
}


void reg_shift_left (digit_t *reg, int first, int last)
{
  int i;

  for (i = last; i >= first; i--)
    reg [i] = (i == first) ? 0 : reg [i-1];
}


// reg to native host binary and vice versa
uint64_t reg_to_binary (digit_t *reg, int digits)
{
  uint64_t val = 0;

  reg += digits;
  while (digits--)
    {
      val <<= 4;
      val += *(--reg);
    }

  return val;
}

void binary_to_reg (uint64_t val, digit_t *reg, int digits)
{
  while (digits--)
    {
      *(reg++) = val & 0xf;
      val >>= 4;
    }
}


// BCD to native host binary and vice versa
uint64_t bcd_reg_to_binary (digit_t *reg, int digits)
{
  uint64_t val = 0;

  reg += digits;
  while (digits--)
    {
      val *= 10;
      val += *(--reg);
    }

  return val;
}

void binary_to_bcd_reg (uint64_t val, digit_t *reg, int digits)
{
  while (digits--)
    {
      *(reg++) = val % 10;
      val /= 10;
    }
}
