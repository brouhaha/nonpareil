/*
$Id$
Copyright 1995, 2003, 2004, 2005 Eric L. Smith <eric@brouhaha.com>

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


void reg_copy (digit_t *dest, digit_t *src, int first, int last)
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


static digit_t do_add (digit_t x, digit_t y, bool *carry, uint8_t base)
{
  int res;

  res = x + y + *carry;
  if (res >= base)
    {
      res -= base;
      *carry = 1;
    }
  else
    *carry = 0;
  return (res);
}


static digit_t do_sub (digit_t x, digit_t y, bool *carry, uint8_t base)
{
  int res;

  res = (x - y) - *carry;
  if (res < 0)
    {
      res += base;
      *carry = 1;
    }
  else
    *carry = 0;
  return (res);
}


void reg_add (digit_t *dest, digit_t *src1, digit_t *src2,
	      int first, int last,
	      bool *carry, uint8_t base)
{
  int i;

  for (i = first; i <= last; i++)
    {
      int s2 = src2 ? src2 [i] : 0;
      dest [i] = do_add (src1 [i], s2, carry, base);
    }
}


void reg_sub (digit_t *dest, digit_t *src1, digit_t *src2,
	      int first, int last,
	      bool *carry, uint8_t base)
{
  int i;

  for (i = first; i <= last; i++)
    {
      int s1 = src1 ? src1 [i] : 0;
      int s2 = src2 ? src2 [i] : 0;
      int d = do_sub (s1, s2, carry, base);
      if (dest)
	dest [i] = d;
    }
}


// $$$ if in decimal mode, do illegal digits get normalized?
void reg_test_nonequal (digit_t *src1, digit_t *src2,
			int first, int last,
			bool *carry)
{
  int i;

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
