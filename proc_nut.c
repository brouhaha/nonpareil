/*
$Id$
Copyright 1995, 2003, 2004 Eric L. Smith <eric@brouhaha.com>

Nonpareil is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License version 2 as
published by the Free Software Foundation.  Note that I am not
granting permission to redistribute or modify Nonpareil under the
terms of any later version of the General Public License.

Nonpareil is distributed in the hope that it will be useful (or at
least amusing), but WITHOUT ANY WARRANTY; without even the implied
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See
the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program (in the file "COPYING"); if not, write to the
Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
MA 02111, USA.
*/

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "arch.h"
#include "util.h"
#include "display.h"
#include "proc.h"
#include "proc_int.h"
#include "coconut_lcd.h"
#include "proc_nut.h"


/* map from high opcode bits to register index */
static int tmap [16] =
{ 3, 4, 5, 10, 8, 6, 11, -1, 2, 9, 7, 13, 1, 12, 0, -1 };

/* map from register index to high opcode bits */
static int itmap [WSIZE] =
{ 0xe, 0xc, 0x8, 0x0, 0x1, 0x2, 0x5, 0xa, 0x4, 0x9, 0x3, 0x6, 0xd, 0xb };


static void nut_print_state (sim_t *sim, sim_env_t *env);


static void bad_op (sim_t *sim, int opcode)
{
  printf ("illegal opcode %03x at %04x\n", opcode, sim->env->prev_pc);
}


static void reg_zero (digit_t *dest, int first, int last)
{
  int i;
  for (i = first; i <= last; i++)
    dest [i] = 0;
}


static void reg_copy (digit_t *dest, digit_t *src, int first, int last)
{
  int i;
  for (i = first; i <= last; i++)
    dest [i] = src [i];
}


static void reg_exch (digit_t *dest, digit_t *src, int first, int last)
{
  int i, t;
  for (i = first; i <= last; i++)
    {
      t = dest [i];
      dest [i] = src [i];
      src [i] = t;
    }
}


static digit_t do_add (sim_t *sim, digit_t x, digit_t y)
{
  int res;

  res = x + y + sim->env->carry;
  if (res >= sim->env->arithmetic_base)
    {
      res -= sim->env->arithmetic_base;
      sim->env->carry = 1;
    }
  else
    sim->env->carry = 0;
  return (res);
}


static digit_t do_sub (sim_t *sim, digit_t x, digit_t y)
{
  int res;

  res = (x - y) - sim->env->carry;
  if (res < 0)
    {
      res += sim->env->arithmetic_base;
      sim->env->carry = 1;
    }
  else
    sim->env->carry = 0;
  return (res);
}


static void reg_add (sim_t *sim, digit_t *dest, digit_t *src1, digit_t *src2,
		     int first, int last)
{
  int i;

  for (i = first; i <= last; i++)
    {
      int s2 = src2 ? src2 [i] : 0;
      dest [i] = do_add (sim, src1 [i], s2);
    }
}


static void reg_sub (sim_t *sim, digit_t *dest, digit_t *src1, digit_t *src2,
		     int first, int last)
{
  int i;

  for (i = first; i <= last; i++)
    {
      int s1 = src1 ? src1 [i] : 0;
      int s2 = src2 ? src2 [i] : 0;
      int d = do_sub (sim, s1, s2);
      if (dest)
	dest [i] = d;
    }
}


static void reg_test_nonequal (sim_t *sim, digit_t *src1, digit_t *src2,
			       int first, int last)
{
  int i;

  for (i = first; i <= last; i++)
    {
      int s2 = src2 ? src2 [i] : 0;
      sim->env->carry |= (src1 [i] != s2);
    }
}


static void reg_shift_right (digit_t *reg, int first, int last)
{
  int i;

  for (i = first; i <= last; i++)
    reg [i] = (i == last) ? 0 : reg [i+1];
}


static void reg_shift_left (digit_t *reg, int first, int last)
{
  int i;

  for (i = last; i >= first; i--)
    reg [i] = (i == first) ? 0 : reg [i-1];
}

static void op_arith (sim_t *sim, int opcode)
{
  int op, field;
  int first, last;

  op = opcode >> 5;
  field = (opcode >> 2) & 7;

  switch (field)
    {
    case 0:  /* p  */  first = *(sim->env->pt); last = *(sim->env->pt);  break;
    case 1:  /* x  */  first = 0;               last = 2;                break;
    case 2:  /* wp */  first = 0;               last = *(sim->env->pt);  break;
    case 3:  /* w  */  first = 0;               last = WSIZE - 1;        break;
    case 4:  /* pq */  first = sim->env->p;     last = sim->env->q;
      if (first > last)
	last = WSIZE - 1;
      break;
    case 5:  /* xs */  first = 2;               last =  2;              break;
    case 6:  /* m  */  first = 3;               last = WSIZE - 2;       break;
    case 7:  /* s  */  first = WSIZE - 1;       last = WSIZE - 1;       break;
    }

  switch (op)
    {
    case 0x00:  /* a=0 */
      reg_zero (sim->env->a, first, last);
      break;

    case 0x01:  /* b=0 */
      reg_zero (sim->env->b, first, last);
      break;

    case 0x02:  /* c=0 */
      reg_zero (sim->env->c, first, last);
      break;

    case 0x03:  /* ab ex */
      reg_exch (sim->env->a, sim->env->b, first, last);
      break;

    case 0x04:  /* b=a */
      reg_copy (sim->env->b, sim->env->a, first, last);
      break;

    case 0x05:  /* ac ex */
      reg_exch (sim->env->a, sim->env->c, first, last);
      break;

    case 0x06:  /* c=b */
      reg_copy (sim->env->c, sim->env->b, first, last);
      break;

    case 0x07:  /* bc ex */
      reg_exch (sim->env->b, sim->env->c, first, last);
      break;

    case 0x08:  /* a=c */
      reg_copy (sim->env->a, sim->env->c, first, last);
      break;

    case 0x09:  /* a=a+b */
      reg_add (sim, sim->env->a, sim->env->a, sim->env->b, first, last);
      break;

    case 0x0a:  /* a=a+c */
      reg_add (sim, sim->env->a, sim->env->a, sim->env->c, first, last);
      break;

    case 0x0b:    /* a=a+1 */
      sim->env->carry = 1;
      reg_add (sim, sim->env->a, sim->env->a, NULL, first, last);
      break;

    case 0x0c:  /* a=a-b */
      reg_sub (sim, sim->env->a, sim->env->a, sim->env->b, first, last);
      break;

    case 0x0d:  /* a=a-1 */
      sim->env->carry = 1;
      reg_sub (sim, sim->env->a, sim->env->a, NULL, first, last);
      break;

    case 0x0e:  /* a=a-c */
      reg_sub (sim, sim->env->a, sim->env->a, sim->env->c, first, last);
      break;

    case 0x0f:  /* c=c+c */
      reg_add (sim, sim->env->c, sim->env->c, sim->env->c, first, last);
      break;

    case 0x10:  /* c=a+c */
      reg_add (sim, sim->env->c, sim->env->a, sim->env->c, first, last);
      break;

    case 0x11:  /* c=c+1 */
      sim->env->carry = 1;
      reg_add (sim, sim->env->c, sim->env->c, NULL, first, last);
      break;

    case 0x12:  /* c=a-c */
      reg_sub (sim, sim->env->c, sim->env->a, sim->env->c, first, last);
      break;

    case 0x13:  /* c=c-1 */
      sim->env->carry = 1;
      reg_sub (sim, sim->env->c, sim->env->c, NULL, first, last);
      break;

    case 0x14:  /* c=-c */
      reg_sub (sim, sim->env->c, NULL, sim->env->c, first, last);
      break;

    case 0x15:  /* c=-c-1 */
      sim->env->carry = 1;
      reg_sub (sim, sim->env->c, NULL, sim->env->c, first, last);
      break;

    case 0x16:  /* ? b<>0 */
      reg_test_nonequal (sim, sim->env->b, NULL, first, last);
      break;

    case 0x17:  /* ? c<>0 */
      reg_test_nonequal (sim, sim->env->c, NULL, first, last);
      break;

    case 0x18:  /* ? a<c */
      reg_sub (sim, NULL, sim->env->a, sim->env->c, first, last);
      break;

    case 0x19:  /* ? a<b */
      reg_sub (sim, NULL, sim->env->a, sim->env->b, first, last);
      break;

    case 0x1a:  /* ? a<>0 */
      reg_test_nonequal (sim, sim->env->a, NULL, first, last);
      break;

    case 0x1b:  /* ? a<>c */
      reg_test_nonequal (sim, sim->env->a, sim->env->c, first, last);
      break;

    case 0x1c:  /* a sr */
      reg_shift_right (sim->env->a, first, last);
      break;

    case 0x1d:  /* b sr */
      reg_shift_right (sim->env->b, first, last);
      break;

    case 0x1e:  /* c sr */
      reg_shift_right (sim->env->c, first, last);
      break;

    case 0x1f:  /* a sl */
      reg_shift_left (sim->env->a, first, last);
      break;
    }
}


/*
 * stack operations
 */

static rom_addr_t pop (sim_t *sim)
{
  int i;
  rom_addr_t ret;

  ret = sim->env->stack [0];
  for (i = 0; i < STACK_DEPTH - 1; i++)
    sim->env->stack [i] = sim->env->stack [i + 1];
  sim->env->stack [STACK_DEPTH - 1] = 0;
  return (ret);
}

static void push (sim_t *sim, rom_addr_t a)
{
  int i;
  for (i = STACK_DEPTH - 1; i > 0; i--)
    sim->env->stack [i] = sim->env->stack [i - 1];
  sim->env->stack [0] = a;
}

static void op_return (sim_t *sim, int opcode)
{
  sim->env->pc = pop (sim);
}

static void op_return_if_carry (sim_t *sim, int opcode)
{
  if (sim->env->prev_carry)
    sim->env->pc = pop (sim);
}

static void op_return_if_no_carry (sim_t *sim, int opcode)
{
  if (! sim->env->prev_carry)
    sim->env->pc = pop (sim);
}

static void op_pop (sim_t *sim, int opcode)
{
  (void) pop (sim);
}

static void op_pop_c (sim_t *sim, int opcode)
{
  rom_addr_t a;

  a = pop (sim);
  sim->env->c [6] = a >> 12;
  sim->env->c [5] = (a >> 8) & 0x0f;
  sim->env->c [4] = (a >> 4) & 0x0f;
  sim->env->c [3] = a & 0x0f;
}


static void op_push_c (sim_t *sim, int opcode)
{
  push (sim, ((sim->env->c [6] << 12) |
	      (sim->env->c [5] << 8) |
	      (sim->env->c [4] << 4) |
	      (sim->env->c [3])));
}


//
// branch operations
//

static void op_short_branch (sim_t *sim, int opcode)
{
  int offset;

  offset = (opcode >> 3) & 0x3f;
  if (opcode & 0x200)
    offset = offset - 64;

  if (((opcode >> 2) & 1) == sim->env->prev_carry)
    sim->env->pc = sim->env->pc + offset - 1;
}


static void op_long_branch (sim_t *sim, int opcode)
{
  sim->env->inst_state = long_branch;
  sim->env->first_word = opcode;
  sim->env->long_branch_carry = sim->env->prev_carry;
}


static void op_long_branch_word_2 (sim_t *sim, int opcode)
{
  rom_addr_t target;

  sim->env->inst_state = norm;
  target = (sim->env->first_word >> 2) | ((opcode & 0x3fc) << 6);

  if ((opcode & 0x001) == sim->env->long_branch_carry)
    {
      if (opcode & 0x002)
	sim->env->pc = target;
      else
	{
	  push (sim, sim->env->pc);
	  sim->env->pc = target;
	  if (sim->ucode [sim->env->pc] == 0)
	    sim->env->pc = pop (sim);
	}
    }
}


static void op_goto_c (sim_t *sim, int opcode)
{
  sim->env->pc = ((sim->env->c [6] << 12) |
		  (sim->env->c [5] << 8) |
		  (sim->env->c [4] << 4) | 
		  (sim->env->c [3]));
}


// Bank selection used in 41CX, Advantage ROM, and perhaps others

// static void op_enbank (sim_t *sim, int opcode)
// {
//   select_bank (prev_pc, opcode & ? >> ?);
// }


/*
 * m operations
 */

static void op_c_to_m (sim_t *sim, int opcode)
{
  reg_copy (sim->env->m, sim->env->c, 0, WSIZE - 1);
}

static void op_m_to_c (sim_t *sim, int opcode)
{
  reg_copy (sim->env->c, sim->env->m, 0, WSIZE - 1);
}

static void op_c_exch_m (sim_t *sim, int opcode)
{
  reg_exch (sim->env->c, sim->env->m, 0, WSIZE - 1);
}


/*
 * n operations
 */

static void op_c_to_n (sim_t *sim, int opcode)
{
  reg_copy (sim->env->n, sim->env->c, 0, WSIZE - 1);
}

static void op_n_to_c (sim_t *sim, int opcode)
{
  reg_copy (sim->env->c, sim->env->n, 0, WSIZE - 1);
}

static void op_c_exch_n (sim_t *sim, int opcode)
{
  reg_exch (sim->env->c, sim->env->n, 0, WSIZE - 1);
}


/*
 * RAM and peripheral operations
 */

static void op_c_to_dadd (sim_t *sim, int opcode)
{
  sim->env->ram_addr = ((sim->env->c [2] << 8) | 
			(sim->env->c [1] << 4) |
			(sim->env->c [0])) & 0x3ff;
}

static void op_c_to_pfad (sim_t *sim, int opcode)
{
  sim->env->pf_addr = ((sim->env->c [1] << 4) |
		       (sim->env->c [0]));
}

static void op_read_reg_n (sim_t *sim, int opcode)
{
  int i;
  int is_ram, is_pf;

  if ((opcode >> 6) != 0)
    sim->env->ram_addr = (sim->env->ram_addr & ~0x0f) | (opcode >> 6);
  is_ram = sim->ram_exists [sim->env->ram_addr];
  is_pf  = sim->pf_exists  [sim->env->pf_addr];

  if (is_ram && is_pf)
    {
      printf ("warning: conflicting read RAM %03x PF %02x reg %01x\n",
	      sim->env->ram_addr, sim->env->pf_addr, opcode >> 6);
    }
  if (is_ram)
    {
      for (i = 0; i < WSIZE; i++)
	sim->env->c [i] = sim->env->ram [sim->env->ram_addr][i];
    }
  else if (is_pf)
    {
      if (sim->rd_n_fcn [sim->env->pf_addr])
	(*sim->rd_n_fcn [sim->env->pf_addr]) (sim, opcode >> 6);
    }
  else
    {
      printf ("warning: stray read RAM %03x PF %02x reg %01x\n",
	      sim->env->ram_addr, sim->env->pf_addr, opcode >> 6);
      for (i = 0; i < WSIZE; i++)
	sim->env->c [i] = 0;
    }
}

static void op_write_reg_n (sim_t *sim, int opcode)
{
  int i;
  int is_ram, is_pf;

  sim->env->ram_addr = (sim->env->ram_addr & ~0x0f) | (opcode >> 6);
  is_ram = sim->ram_exists [sim->env->ram_addr];
  is_pf  = sim->pf_exists  [sim->env->pf_addr];

  if (is_ram && is_pf)
    {
      printf ("warning: conflicting write RAM %03x PF %02x reg %01x\n",
	      sim->env->ram_addr, sim->env->pf_addr, opcode >> 6);
    }
  else if ((! is_ram) && (! is_pf))
    {
#ifdef WARN_STRAY_WRITE
      printf ("warning: stray write RAM %03x PF %02x reg %01x\n",
	      sim->env->ram_addr, sim->env->pf_addr, opcode >> 6);
#endif
    }
  if (is_ram)
    {
      for (i = 0; i < WSIZE; i++)
	sim->env->ram [sim->env->ram_addr][i] = sim->env->c [i];
    }
  if (is_pf)
    {
      if (sim->wr_n_fcn [sim->env->pf_addr])
	(*sim->wr_n_fcn [sim->env->pf_addr]) (sim, opcode >> 6);
    }
}

static void op_c_to_data (sim_t *sim, int opcode)
{
  int i;
  int is_ram, is_pf;

  is_ram = sim->ram_exists [sim->env->ram_addr];
  is_pf  = sim->pf_exists  [sim->env->pf_addr];

  if (is_ram && is_pf)
    {
      printf ("warning: conflicting write RAM %03x PF %02x\n",
	      sim->env->ram_addr, sim->env->pf_addr);
    }
  else if ((! is_ram) && (! is_pf))
    {
#ifdef WARN_STRAY_WRITE
      printf ("warning: stray write RAM %03x PF %02x\n",
	      sim->env->ram_addr, sim->env->pf_addr);
#endif
    }
  if (is_ram)
    {
      for (i = 0; i < WSIZE; i++)
	sim->env->ram [sim->env->ram_addr][i] = sim->env->c [i];
    }
  if (is_pf)
    {
      if (sim->wr_fcn [sim->env->pf_addr])
	(*sim->wr_fcn [sim->env->pf_addr]) (sim);
    }
}

static void op_test_ext_flag (sim_t *sim, int opcode)
{
  sim->env->carry = 0;  /* no periphs yet */
}

/*
 * s operations
 */

static void op_set_s (sim_t *sim, int opcode)
{
  sim->env->s [tmap [opcode >> 6]] = 1;
}

static void op_clr_s (sim_t *sim, int opcode)
{
  sim->env->s [tmap [opcode >> 6]] = 0;
}

static void op_test_s (sim_t *sim, int opcode)
{
  sim->env->carry = sim->env->s [tmap [opcode >> 6]];
}

static int get_s_bits (sim_t *sim, int first, int count)
{
  int i;
  int mask = 1;
  int r = 0;
  for (i = first; i < first + count; i++)
    {
      if (sim->env->s [i])
	r = r + mask;
      mask <<= 1;
    }
  return (r);
}

static void set_s_bits (sim_t *sim, int first, int count, int a)
{
  int i;
  int mask = 1;
  for (i = first; i < first + count; i++)
    {
      sim->env->s [i] = (a & mask) != 0;
      mask <<= 1;
    }
}

static void op_clear_all_s (sim_t *sim, int opcode)
{
  set_s_bits (sim, 0, 8, 0);
}

static void op_c_to_s (sim_t *sim, int opcode)
{
  set_s_bits (sim, 0, 4, sim->env->c [0]);
  set_s_bits (sim, 4, 4, sim->env->c [1]);
}

static void op_s_to_c (sim_t *sim, int opcode)
{
  sim->env->c [0] = get_s_bits (sim, 0, 4);
  sim->env->c [1] = get_s_bits (sim, 4, 4);
}

static void op_c_exch_s (sim_t *sim, int opcode)
{
  int t;
  t = get_s_bits (sim, 0, 4);
  set_s_bits (sim, 0, 4, sim->env->c [0]);
  sim->env->c [0] = t;
  t = get_s_bits (sim, 4, 4);
  set_s_bits (sim, 4, 4, sim->env->c [1]);
  sim->env->c [1] = t;
}

static void op_sb_to_f (sim_t *sim, int opcode)
{
  sim->env->fo = get_s_bits (sim, 0, 8);
}

static void op_f_to_sb (sim_t *sim, int opcode)
{
  set_s_bits (sim, 0, 8, sim->env->fo);
}

static void op_f_exch_sb (sim_t *sim, int opcode)
{
  int t;
  t = get_s_bits (sim, 0, 8);
  set_s_bits (sim, 0, 8, sim->env->fo);
  sim->env->fo = t;
}

/*
 * pointer operations
 */

static void op_dec_pt (sim_t *sim, int opcode)
{
  (*sim->env->pt)--;
  if ((*sim->env->pt) >= WSIZE)  /* can't be negative because it is unsigned */
    (*sim->env->pt) = WSIZE - 1;
}

static void op_inc_pt (sim_t *sim, int opcode)
{
  (*sim->env->pt)++;
  if ((*sim->env->pt) >= WSIZE)
    (*sim->env->pt) = 0;
}

static void op_set_pt (sim_t *sim, int opcode)
{
  (*sim->env->pt) = tmap [opcode >> 6];
}

static void op_test_pt (sim_t *sim, int opcode)
{
  sim->env->carry = ((*sim->env->pt) == tmap [opcode >> 6]);
}

static void op_sel_p (sim_t *sim, int opcode)
{
  sim->env->pt = & sim->env->p;
}

static void op_sel_q (sim_t *sim, int opcode)
{
  sim->env->pt = & sim->env->q;
}

static void op_test_pq (sim_t *sim, int opcode)
{
  if (sim->env->p == sim->env->q)
    sim->env->carry = 1;
}

static void op_lc (sim_t *sim, int opcode)
{
  sim->env->c [(*sim->env->pt)--] = opcode >> 6;
  if ((*sim->env->pt) >= WSIZE)  /* unsigned, can't be negative */
    (*sim->env->pt) = WSIZE - 1;
}

static void op_c_to_g (sim_t *sim, int opcode)
{
  sim->env->g [0] = sim->env->c [*sim->env->pt];
  if ((*sim->env->pt) == (WSIZE - 1))
    {
      sim->env->g [1] = 0;
#ifdef WARNING_G
      fprintf (stderr, "warning: c to g transfer with pt=13\n");
#endif
    }
  else
    sim->env->g [1] = sim->env->c [(*sim->env->pt) + 1];
}

static void op_g_to_c (sim_t *sim, int opcode)
{
  sim->env->c [*sim->env->pt] = sim->env->g [0];
  if ((*sim->env->pt) == (WSIZE - 1))
    {
      ;
#ifdef WARNING_G
      fprintf (stderr, "warning: g to c transfer with pt=13\n");
#endif
    }
  else
    {
      sim->env->c [(*sim->env->pt) + 1] = sim->env->g [1];
    }
    
}

static void op_c_exch_g (sim_t *sim, int opcode)
{
  int t;
  t = sim->env->g [0];
  sim->env->g [0] = sim->env->c [*sim->env->pt];
  sim->env->c [*sim->env->pt] = t;
  if ((*sim->env->pt) == (WSIZE - 1))
    {
      sim->env->g [1] = 0;
#ifdef WARNING_G
      fprintf (stderr, "warning: c exchange g with pt=13\n");
#endif
    }
  else
    {
      t = sim->env->g [1];
      sim->env->g [1] = sim->env->c [(*sim->env->pt) + 1];
      sim->env->c [(*sim->env->pt) + 1] = t;
    }
}


/*
 * keyboard operations
 */

static void op_keys_to_rom_addr (sim_t *sim, int opcode)
{
  sim->env->pc = (sim->env->pc & 0xff00) | sim->env->key_buf;
}

static void op_keys_to_c (sim_t *sim, int opcode)
{
  sim->env->c [4] = sim->env->key_buf >> 4;
  sim->env->c [3] = sim->env->key_buf & 0x0f;
}

static void op_test_kb (sim_t *sim, int opcode)
{
  sim->env->carry = sim->env->key_flag;
}

static void op_reset_kb (sim_t *sim, int opcode)
{
  sim->env->key_flag = sim->env->key_down;
}


/*
 * misc. operations
 */

static void op_nop (sim_t *sim, int opcode)
{
}

static void op_set_hex (sim_t *sim, int opcode)
{
  sim->env->arithmetic_base = 16;
}

static void op_set_dec (sim_t *sim, int opcode)
{
  sim->env->arithmetic_base = 10;
}

static void op_rom_to_c (sim_t *sim, int opcode)
{
  sim->env->cxisa_addr = ((sim->env->c [6] << 12) |
			  (sim->env->c [5] << 8) |
			  (sim->env->c [4] << 4) |
			  (sim->env->c [3]));
  sim->env->inst_state = cxisa;
}

static void op_rom_to_c_cycle_2 (sim_t *sim, int opcode)
{
  sim->env->c [2] = opcode >> 8;
  sim->env->c [1] = (opcode >> 4) & 0x0f;
  sim->env->c [0] = opcode & 0x0f;

  sim->env->inst_state = norm;
}

static void op_clear_abc (sim_t *sim, int opcode)
{
  reg_zero (sim->env->a, 0, WSIZE - 1);
  reg_zero (sim->env->b, 0, WSIZE - 1);
  reg_zero (sim->env->c, 0, WSIZE - 1);
}

static void op_ldi (sim_t *sim, int opcode)
{
  sim->env->inst_state = ldi;
}

static void op_ldi_cycle_2 (sim_t *sim, int opcode)
{
  sim->env->c [2] = opcode >> 8;
  sim->env->c [1] = (opcode >> 4) & 0x0f;
  sim->env->c [0] = opcode & 0x00f;

  sim->env->inst_state = norm;
}

static void op_or (sim_t *sim, int opcode)
{
  int i;
  for (i = 0; i < WSIZE; i++)
    sim->env->c [i] |= sim->env->a [i];
}

static void op_and (sim_t *sim, int opcode)
{
  int i;
  for (i = 0; i < WSIZE; i++)
    sim->env->c [i] &= sim->env->a [i];
}

static void op_rcr (sim_t *sim, int opcode)
{
  int count, i, j;
  reg_t t;
  count = tmap [opcode >> 6];
  for (i = 0; i < WSIZE; i++)
    {
      j = (i + count) % WSIZE;
      t [i] = sim->env->c [j];
    }
  for (i = 0; i < WSIZE; i++)
    sim->env->c [i] = t [i];
}

static void op_lld (sim_t *sim, int opcode)
{
  sim->env->carry = 0;  /* "batteries" are fine */
}

static void op_powoff (sim_t *sim, int opcode)
{
#if 0
  printf ("going to sleep!\n");
#endif
  sim->env->awake = false;
  sim->env->pc = 0;
  if (sim->env->display_enable)
    {
      /* going to light sleep */
#ifdef AUTO_POWER_OFF
      /* start display timer if LCD chip is selected */
      if (sim->env->pf_addr == LCD_DISPLAY)
	display_timer = DISPLAY_TIMEOUT;
#endif /* AUTO_POWER_OFF */
    }
  else
    /* going to deep sleep */
    sim->env->carry = 1;
}


static void nut_init_ops (sim_t *sim)
{
  int i;

  for (i = 0; i < 1024; i += 4)
    {
      sim->op_fcn [i + 0] = bad_op;
      sim->op_fcn [i + 1] = op_long_branch;
      sim->op_fcn [i + 2] = op_arith;  /* type 2: ooooowww10 */
      sim->op_fcn [i + 3] = op_short_branch;
    }

  sim->op_fcn [0x000] = op_nop;

  // sim->op_fcn [0x040] = op_write_mldl;

  // sim->op_fcn [0x100] = op_enbank1;
  // sim->op_fcn [0x180] = op_enbank2;

  // for (i = 0; i < 8; i++)
  //   op_fcn [0x200 + (i << 6)] = op_write_pil;

  for (i = 0; i < WSIZE; i ++)
    {
      sim->op_fcn [0x004 + (itmap [i] << 6)] = op_clr_s;
      sim->op_fcn [0x008 + (itmap [i] << 6)] = op_set_s;
      sim->op_fcn [0x00c + (itmap [i] << 6)] = op_test_s;
      sim->op_fcn [0x014 + (itmap [i] << 6)] = op_test_pt;
      sim->op_fcn [0x01c + (itmap [i] << 6)] = op_set_pt;
      sim->op_fcn [0x02c + (itmap [i] << 6)] = op_test_ext_flag;
      sim->op_fcn [0x03c + (itmap [i] << 6)] = op_rcr;
    }
  sim->op_fcn [0x3c4] = op_clear_all_s;
  sim->op_fcn [0x3c8] = op_reset_kb;
  sim->op_fcn [0x3cc] = op_test_kb;
  sim->op_fcn [0x3d4] = op_dec_pt;
  sim->op_fcn [0x3dc] = op_inc_pt;

  for (i = 0; i < 16; i++)
    {
      sim->op_fcn [0x010 + (i << 6)] = op_lc;
      // sim->op_fcn [0x024 + (i << 6)] = op_selprf;
      sim->op_fcn [0x028 + (i << 6)] = op_write_reg_n;
      sim->op_fcn [0x038 + (i << 6)] = op_read_reg_n;
    }

  sim->op_fcn [0x058] = op_c_to_g;
  sim->op_fcn [0x098] = op_g_to_c;
  sim->op_fcn [0x0d8] = op_c_exch_g;

  sim->op_fcn [0x158] = op_c_to_m;
  sim->op_fcn [0x198] = op_m_to_c;
  sim->op_fcn [0x1d8] = op_c_exch_m;

  sim->op_fcn [0x258] = op_sb_to_f;
  sim->op_fcn [0x298] = op_f_to_sb;
  sim->op_fcn [0x2d8] = op_f_exch_sb;

  sim->op_fcn [0x358] = op_c_to_s;
  sim->op_fcn [0x398] = op_s_to_c;
  sim->op_fcn [0x3d8] = op_c_exch_s;

  sim->op_fcn [0x020] = op_pop;
  sim->op_fcn [0x060] = op_powoff;
  sim->op_fcn [0x0a0] = op_sel_p;
  sim->op_fcn [0x0e0] = op_sel_q;
  sim->op_fcn [0x120] = op_test_pq;
  sim->op_fcn [0x160] = op_lld;
  sim->op_fcn [0x1a0] = op_clear_abc;
  sim->op_fcn [0x1e0] = op_goto_c;
  sim->op_fcn [0x220] = op_keys_to_c;
  sim->op_fcn [0x260] = op_set_hex;
  sim->op_fcn [0x2a0] = op_set_dec;
  sim->op_fcn [0x360] = op_return_if_carry;
  sim->op_fcn [0x3a0] = op_return_if_no_carry;
  sim->op_fcn [0x3e0] = op_return;

  sim->op_fcn [0x070] = op_c_to_n;
  sim->op_fcn [0x0b0] = op_n_to_c;
  sim->op_fcn [0x0f0] = op_c_exch_n;
  sim->op_fcn [0x130] = op_ldi;
  sim->op_fcn [0x170] = op_push_c;
  sim->op_fcn [0x1b0] = op_pop_c;
  sim->op_fcn [0x230] = op_keys_to_rom_addr;
  sim->op_fcn [0x270] = op_c_to_dadd;
  // sim->op_fcn [0x2b0] = op_clear_regs;
  sim->op_fcn [0x2f0] = op_c_to_data;
  sim->op_fcn [0x330] = op_rom_to_c;
  sim->op_fcn [0x370] = op_or;
  sim->op_fcn [0x3b0] = op_and;
  sim->op_fcn [0x3f0] = op_c_to_pfad;

}


static void nut_disassemble (sim_t *sim, int addr, char *buf, int len)
{
  int l;

  l = snprintf (buf, len, "%04x: ", addr);
  buf += l;
  len -= l;
  if (len <= 0)
    return;

  l = snprintf (buf, len, "%03x  ", sim->ucode [addr]);
  buf += l;
  len -= l;
  if (len <= 0)
    return;

  switch (sim->env->inst_state)
    {
    case long_branch:   snprintf (buf, len, "(long branch)"); return;
    case cxisa:         snprintf (buf, len, "(cxisa)");       return;
    case ldi:           snprintf (buf, len, "(immediate)");   return;
    case norm:          break;
    }

  return;
}


static void print_reg (reg_t reg)
{
  int i;
  for (i = WSIZE - 1; i >= 0; i--)
    printf ("%x", reg [i]);
}


static void print_stat (sim_t *sim)
{
  int i;
  for (i = 0; i < SSIZE; i++)
    printf (sim->env->s [i] ? "%x" : ".", i);
}


static void nut_print_state (sim_t *sim, sim_env_t *env)
{
  printf ("cycle %5lld  ", sim->cycle_count);
  printf ("%c=%x ", (sim->env->pt == & sim->env->p) ? 'P' : 'p', sim->env->p);
  printf ("%c=%x ", (sim->env->pt == & sim->env->q) ? 'Q' : 'q', sim->env->q);
  printf ("carry=%d ", sim->env->carry);
  printf (" stat=");
  print_stat (sim);
  printf ("\n");
  printf (" a=");
  print_reg (sim->env->a);
  printf (" b=");
  print_reg (sim->env->b);
  printf (" c=");
  print_reg (sim->env->c);
  printf ("\n");

  if (sim->source [sim->env->prev_pc])
    printf ("%s\n", sim->source [sim->env->prev_pc]);
  else
    {
      char buf [80];
      nut_disassemble (sim, sim->env->prev_pc, buf, sizeof (buf));
      printf (" %s\n", buf);
    }
}

bool nut_execute_instruction (sim_t *sim)
{
  int opcode;

  if (! sim->env->awake)
    return (false);

  if (sim->env->inst_state == cxisa)
    sim->env->prev_pc = sim->env->cxisa_addr;
  else
    sim->env->prev_pc = sim->env->pc;

  opcode = sim->ucode [sim->env->prev_pc];

#ifdef HAS_DEBUGGER
  if (sim->debug_flags & (1 << SIM_DEBUG_TRACE))
    nut_print_state (sim, sim->env);
#endif /* HAS_DEBUGGER */

  sim->env->prev_carry = sim->env->carry;
  sim->env->carry = 0;

  if (sim->env->key_flag)
    sim->env->s [0] = 1;

  switch (sim->env->inst_state)
    {
    case norm:
      sim->env->pc++;
      (* sim->op_fcn [opcode]) (sim, opcode);
      break;
    case long_branch:
      sim->env->pc++;
      op_long_branch_word_2 (sim, opcode);
      break;
    case cxisa:
      op_rom_to_c_cycle_2 (sim, opcode);
      break;
    case ldi:
      sim->env->pc++;
      op_ldi_cycle_2 (sim, opcode);
      break;
    }
  sim->cycle_count++;

  if (sim->env->display_count == 0)
    {
      coconut_display_update (sim);
      sim->env->display_count = 15;
    }
  else
    sim->env->display_count --;

  return (true);
}


static bool parse_hex (char *hex, int digits, int *val)
{
  *val = 0;

  while (digits--)
    {
      char c = *(hex++);
      (*val) <<= 4;
      if ((c >= '0') && (c <= '9'))
	(*val) += (c - '0');
      else if ((c >= 'A') && (c <= 'F'))
	(*val) += (10 + (c - 'A'));
      else if ((c >= 'a') && (c <= 'f'))
	(*val) += (10 + (c - 'a'));
      else
	return (false);
    }
  return (true);
}


static bool nut_parse_object_line (char *buf, int *bank, int *addr,
				   rom_word_t *opcode)
{
  int a, o;

  if (buf [0] == '#')  /* comment? */
    return (false);

  if (strlen (buf) != 8)
    return (false);

  if (buf [4] != ':')
    {
      fprintf (stderr, "invalid object file format\n");
      return (false);
    }

  if (! parse_hex (& buf [0], 4, & a))
    {
      fprintf (stderr, "invalid address %o\n", a);
      return (false);
    }

  if (! parse_hex (& buf [5], 3, & o))
    {
      fprintf (stderr, "invalid opcode %o\n", o);
      return (false);
    }

  *bank = 0;
  *addr = a;
  *opcode = o;
  return (true);
}


static bool nut_parse_listing_line (char *buf, int *bank, int *addr,
				    rom_word_t *opcode)
{
  return (false);
}


static void nut_press_key (sim_t *sim, int keycode)
{
  if ((! sim->env->awake) && (! sim->env->display_enable) && (keycode != 0x18))
    return;
  sim->env->key_buf = keycode;
  sim->env->key_down = true;
  sim->env->key_flag = true;
#if 0
  if (! sim->env->awake)
    printf ("waking up!\n");
#endif
  sim->env->awake = true;
}

static void nut_release_key (sim_t *sim)
{
  sim->env->key_down = false;
}

static void nut_set_ext_flag (sim_t *sim, int flag, bool state)
{
  ;  // not yet implemented
}


void nut_reset_processor (sim_t *sim)
{
  int i;

  sim->cycle_count = 0;

  for (i = 0; i < WSIZE; i++)
    {
      sim->env->a [i] = 0;
      sim->env->b [i] = 0;
      sim->env->c [i] = 0;
      sim->env->m [i] = 0;
      sim->env->n [i] = 0;
    }

  for (i = 0; i < SSIZE; i++)
    sim->env->s [i] =0;

  sim->env->p = 0;
  sim->env->q = 0;
  sim->env->pt = & sim->env->p;

  /* wake from deep sleep */
  sim->env->awake = true;
  sim->env->pc = 0;
  sim->env->inst_state = norm;
  sim->env->carry = 1;
  sim->env->display_enable = 0;
  sim->env->display_count = 0;

  sim->env->key_flag = 0;

  coconut_display_reset (sim);
}


static void nut_read_ram (sim_t *sim, int addr, reg_t *val)
{
  if (addr > sim->env->max_ram)
    fatal (2, "classic_read_ram: address %d out of range\n", addr);
  memcpy (val, & sim->env->ram [addr], sizeof (reg_t));
}


static void nut_write_ram (sim_t *sim, int addr, reg_t *val)
{
  if (addr > sim->env->max_ram)
    fatal (2, "sim_write_ram: address %d out of range\n", addr);
  memcpy (& sim->env->ram [addr], val, sizeof (reg_t));
}


static sim_env_t *nut_get_env (sim_t *sim)
{
  sim_env_t *env;
  size_t size;

  size = sizeof (sim_env_t) + sim->env->max_ram * sizeof (reg_t);
  env = alloc (size);
  memcpy (env, sim->env, size);
  return (env);
}

static void nut_set_env (sim_t *sim, sim_env_t *env)
{
  size_t size;

  size = sizeof (sim_env_t) + sim->env->max_ram * sizeof (reg_t);
  memcpy (sim->env, env, size);
}

static void nut_free_env (sim_t *sim, sim_env_t *env)
{
  free (env);
}


static void nut_new_processor (sim_t *sim, int ram_size)
{
  int i;

  sim->env = alloc (sizeof (sim_env_t) + 1024 * sizeof (reg_t));
  sim->env->max_ram = 1024;

  for (i = 0x000; i <= 0x00f; i++)
    sim->ram_exists [i] = true;

  for (i = 0x0c0; i <= 0x1ff; i++)
    sim->ram_exists [i] = true;

  nut_init_ops (sim);
  coconut_display_init_ops (sim);
}


static void nut_free_processor (sim_t *sim)
{
  free (sim->env->ram);
  free (sim->env);
  sim->env = NULL;
}


processor_dispatch_t nut_processor =
  {
    65536,
    1,

    nut_new_processor,
    nut_free_processor,

    nut_parse_object_line,
    nut_parse_listing_line,

    nut_reset_processor,
    nut_execute_instruction,

    nut_press_key,
    nut_release_key,
    nut_set_ext_flag,

    nut_read_ram,
    nut_write_ram,
    nut_disassemble,

    nut_get_env,
    nut_set_env,
    nut_free_env,
    nut_print_state
  };
