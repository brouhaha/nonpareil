/*
$Id$
Copyright 2004 Eric L. Smith <eric@brouhaha.com>

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
#include "platform.h"
#include "util.h"
#include "display.h"
#include "proc.h"
#include "proc_int.h"
#include "proc_woodstock.h"
#include "dis_woodstock.h"



/* If defined, print warnings about stack overflow or underflow. */
#undef STACK_WARNING


static void woodstock_print_state (sim_t *sim, sim_env_t *env);


static inline int woodstock_map_rom_address (sim_t *sim, int addr)
{
  return ((sim->env->bank << 12) + addr);
}


static void bad_op (sim_t *sim, int opcode)
{
  printf ("illegal opcode %04o at %05o\n", opcode, sim->env->prev_pc);
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


static void op_arith (sim_t *sim, int opcode)
{
  uint8_t op, field;
  int first = 0;
  int last = 0;
  int temp;
  int i;
  reg_t t;

  op = opcode >> 5;
  field = (opcode >> 2) & 7;

  switch (field)
    {
    case 0:  /* p  */
      first =  sim->env->p; last =  sim->env->p;
      if (sim->env->p >= WSIZE)
	{
	  printf ("Warning! p >= WSIZE at %05o\n", sim->env->prev_pc);
	  woodstock_print_state (sim, sim->env);
	  last = 0;  /* don't do anything */
	}
      break;
    case 1:  /* wp */
      first =  0; last =  sim->env->p;
      if (sim->env->p > 13)
	{
	  printf ("Warning! p >= WSIZE at %05o\n", sim->env->prev_pc);
	  woodstock_print_state (sim, sim->env);
	  last = 13;
	}
      break;
    case 2:  /* xs */  first =  2; last =  2; break;
    case 3:  /* x  */  first =  0; last =  2; break;
    case 4:  /* s  */  first = 13; last = 13; break;
    case 5:  /* m  */  first =  3; last = 12; break;
    case 6:  /* w  */  first =  0; last = 13; break;
    case 7:  /* ms */  first =  3; last = 13; break;
    }

  switch (op)
    {
    case 0x00:  /* 0 -> a[f] */
      for (i = first; i <= last; i++)
	sim->env->a [i] = 0;
      sim->env->carry = 0;
      break;
    case 0x01:  /* 0 -> b[f] */
      for (i = first; i <= last; i++)
	sim->env->b [i] = 0;
      sim->env->carry = 0;
      break;
    case 0x02:  /* a exchange b[f] */
      for (i = first; i <= last; i++)
	{
	  temp = sim->env->a[i];
	  sim->env->a [i] = sim->env->b [i];
	  sim->env->b [i] = temp; 
	}
      sim->env->carry = 0;
      break;
    case 0x03:  /* a -> b[f] */
      for (i = first; i <= last; i++)
	sim->env->b [i] = sim->env->a [i];
      sim->env->carry = 0;
      break;
    case 0x04:  /* a exchange c[f] */
      for (i = first; i <= last; i++)
	{
	  temp = sim->env->a [i];
	  sim->env->a [i] = sim->env->c [i];
	  sim->env->c [i] = temp;
	}
      sim->env->carry = 0;
      break;
    case 0x05:  /* c -> a[f] */
      for (i = first; i <= last; i++)
	sim->env->a [i] = sim->env->c [i];
      sim->env->carry = 0;
      break;
    case 0x06:  /* b -> c[f] */
      for (i = first; i <= last; i++)
	sim->env->c [i] = sim->env->b [i];
      sim->env->carry = 0;
      break;
    case 0x07:  /* b exchange c[f] */
      for (i = first; i <= last; i++)
	{
	  temp = sim->env->b[i];
	  sim->env->b [i] = sim->env->c [i];
	  sim->env->c [i] = temp;
	}
      sim->env->carry = 0;
      break;
    case 0x08:  /* 0 -> c[f] */
      for (i = first; i <= last; i++)
	sim->env->c [i] = 0;
      sim->env->carry = 0;
      break;
    case 0x09:  /* a + b -> a[f] */
      sim->env->carry = 0;
      for (i = first; i <= last; i++)
	sim->env->a [i] = do_add (sim, sim->env->a [i], sim->env->b [i]);
      break;
    case 0x0a:  /* a + c -> a[f] */
      sim->env->carry = 0;
      for (i = first; i <= last; i++)
	sim->env->a [i] = do_add (sim, sim->env->a [i], sim->env->c [i]);
      break;
    case 0x0b:  /* c + c -> c[f] */
      sim->env->carry = 0;
      for (i = first; i <= last; i++)
	sim->env->c [i] = do_add (sim, sim->env->c [i], sim->env->c [i]);
      break;
    case 0x0c:  /* a + c -> c[f] */
      sim->env->carry = 0;
      for (i = first; i <= last; i++)
	sim->env->c [i] = do_add (sim, sim->env->a [i], sim->env->c [i]);
      break;
    case 0x0d:  /* a + 1 -> a[f] */
      sim->env->carry = 1;
      for (i = first; i <= last; i++)
	sim->env->a [i] = do_add (sim, sim->env->a [i], 0);
      break;
    case 0x0e:  /* shift left a[f] */
      for (i = last; i >= first; i--)
	sim->env->a [i] = (i == first) ? 0 : sim->env->a [i-1];
      sim->env->carry = 0;
      break;
    case 0x0f:  /* c + 1 -> c[f] */
      sim->env->carry = 1;
      for (i = first; i <= last; i++)
	sim->env->c [i] = do_add (sim, sim->env->c [i], 0);
      break;
    case 0x10:  /* a - b -> a[f] */
      sim->env->carry = 0;
      for (i = first; i <= last; i++)
	sim->env->a [i] = do_sub (sim, sim->env->a [i], sim->env->b [i]);
      break;
    case 0x11:  /* a - c -> c[f] */
      sim->env->carry = 0;
      for (i = first; i <= last; i++)
	sim->env->c [i] = do_sub (sim, sim->env->a [i], sim->env->c [i]);
      break;
    case 0x12:  /* a - 1 -> a[f] */
      sim->env->carry = 1;
      for (i = first; i <= last; i++)
	sim->env->a [i] = do_sub (sim, sim->env->a [i], 0);
      break;
    case 0x13:  /* c - 1 -> c[f] */
      sim->env->carry = 1;
      for (i = first; i <= last; i++)
	sim->env->c [i] = do_sub (sim, sim->env->c [i], 0);
      break;
    case 0x14:  /* 0 - c -> c[f] */
      sim->env->carry = 0;
      for (i = first; i <= last; i++)
	sim->env->c [i] = do_sub (sim, 0, sim->env->c [i]);
      break;
    case 0x15:  /* 0 - c - 1 -> c[f] */
      sim->env->carry = 1;
      for (i = first; i <= last; i++)
	sim->env->c [i] = do_sub (sim, 0, sim->env->c [i]);
      break;
    case 0x16:  /* if b[f] = 0 */
      sim->env->inst_state = branch;
      for (i = first; i <= last; i++)
	sim->env->carry |= (sim->env->b [i] != 0);
      break;
    case 0x17:  /* if c[f] = 0 */
      sim->env->inst_state = branch;
      for (i = first; i <= last; i++)
	sim->env->carry |= (sim->env->c [i] != 0);
      break;
    case 0x18:  /* if a >= c[f] */
      sim->env->inst_state = branch;
      sim->env->carry = 0;
      for (i = first; i <= last; i++)
	t [i] = do_sub (sim, sim->env->a [i], sim->env->c [i]);
      break;
    case 0x19:  /* if a >= b[f] */
      sim->env->inst_state = branch;
      sim->env->carry = 0;
      for (i = first; i <= last; i++)
	t [i] = do_sub (sim, sim->env->a [i], sim->env->b [i]);
      break;
    case 0x1a:  /* if a[f] # 0 */
      sim->env->inst_state = branch;
      sim->env->carry = 1;
      for (i = first; i <= last; i++)
	sim->env->carry &= (sim->env->a [i] == 0);
      break;
    case 0x1b:  /* if c[f] # 0 */
      sim->env->inst_state = branch;
      sim->env->carry = 1;
      for (i = first; i <= last; i++)
	sim->env->carry &= (sim->env->c [i] == 0);
      break;
    case 0x1c:  /* a - c -> a[f] */
      sim->env->carry = 0;
      for (i = first; i <= last; i++)
        sim->env->a [i] = do_sub (sim, sim->env->a [i], sim->env->c [i]);
      break;
    case 0x1d:  /* shift right a[f] */
      for (i = first; i <= last; i++)
	sim->env->a [i] = (i == last) ? 0 : sim->env->a [i+1];
      sim->env->carry = 0;
      break;
    case 0x1e:  /* shift right b[f] */
      for (i = first; i <= last; i++)
	sim->env->b [i] = (i == last) ? 0 : sim->env->b [i+1];
      sim->env->carry = 0;
      break;
    case 0x1f:  /* shift right c[f] */
      for (i = first; i <= last; i++)
	sim->env->c [i] = (i == last) ? 0 : sim->env->c [i+1];
      sim->env->carry = 0;
      break;
    }
}


static void op_goto (sim_t *sim, int opcode)
{
  if (! sim->env->prev_carry)
    {
      sim->env->pc = (sim->env->pc & ~0377) | (opcode >> 2);
      if (sim->env->del_rom_flag)
	{
	  sim->env->pc = (sim->env->del_rom << 8) + (sim->env->pc & 0377);
	  sim->env->del_rom_flag = 0;
	}
    }
}


static void op_jsb (sim_t *sim, int opcode)
{
  sim->env->return_stack [sim->env->sp] = sim->env->pc;
  sim->env->sp++;
  if (sim->env->sp >= STACK_SIZE)
    {
#ifdef STACK_WARNING
      printf ("stack overflow\n");
#endif
      sim->env->sp = 0;
    }
  sim->env->pc = (sim->env->pc & ~0377) | (opcode >> 2);
  if (sim->env->del_rom_flag)
    {
      sim->env->pc = (sim->env->del_rom << 8) + (sim->env->pc & 0377);
      sim->env->del_rom_flag = 0;
    }
}


static void op_return (sim_t *sim, int opcode)
{
  sim->env->sp--;
  if (sim->env->sp < 0)
    {
#ifdef STACK_WARNING
      printf ("stack underflow\n");
#endif
      sim->env->sp = STACK_SIZE - 1;
    }
  sim->env->pc = sim->env->return_stack [sim->env->sp];
}


static void op_nop (sim_t *sim, int opcode)
{
}


static void op_binary (sim_t *sim, int opcode)
{
  sim->env->arithmetic_base = 16;
}


static void op_decimal (sim_t *sim, int opcode)
{
  sim->env->arithmetic_base = 10;
}


/* $$$ woodstock doc says when increment or decrement P wraps,
 * P "disappears for one word time". */

static void op_dec_p (sim_t *sim, int opcode)
{
  if (sim->env->p)
    sim->env->p--;
  else
    sim->env->p = WSIZE - 1;
}


static void op_inc_p (sim_t *sim, int opcode)
{
  sim->env->p++;
  if (sim->env->p >= WSIZE)
    sim->env->p = 0;
}


static void op_clear_s (sim_t *sim, int opcode)
{
  int i;
  for (i = 0; i < SSIZE; i++)
    if ((i != 1) && (i != 2) && (i != 5) && (i != 15))
      sim->env->s [i] = 0;
}


static void op_m1_exch_c (sim_t *sim, int opcode)
{
  int i, t;
  for (i = 0; i < WSIZE; i++)
    {
      t = sim->env->c [i];
      sim->env->c [i] = sim->env->m1 [i];
      sim->env->m1 [i] = t;
    }
}


static void op_m1_to_c (sim_t *sim, int opcode)
{
  int i;
  for (i = 0; i < WSIZE; i++)
    sim->env->c [i] = sim->env->m1 [i];
}


static void op_m2_exch_c (sim_t *sim, int opcode)
{
  int i, t;
  for (i = 0; i < WSIZE; i++)
    {
      t = sim->env->c [i];
      sim->env->c [i] = sim->env->m2 [i];
      sim->env->m2 [i] = t;
    }
}


static void op_m2_to_c (sim_t *sim, int opcode)
{
  int i;
  for (i = 0; i < WSIZE; i++)
    sim->env->c [i] = sim->env->m2 [i];
}


static void op_f_to_a (sim_t *sim, int opcode)
{
  sim->env->a [0] = sim->env->f;
}


static void op_f_exch_a (sim_t *sim, int opcode)
{
  int t;

  t = sim->env->a [0];
  sim->env->a [0] = sim->env->f;
  sim->env->f = t;
}


static void op_circulate_a_left (sim_t *sim, int opcode)
{
  int i, t;
  t = sim->env->a [WSIZE - 1];
  for (i = WSIZE - 1; i >= 1; i--)
    sim->env->a [i] = sim->env->a [i - 1];
  sim->env->a [0] = t;
}


static void op_bank_switch (sim_t *sim, int opcode)
{
  sim->env->bank ^= 1;
  printf ("bank switch at %04o, will select bank %o\n",
	  sim->env->prev_pc, sim->env->bank);
}


static void op_rom_selftest (sim_t *sim, int opcode)
{
  sim->env->crc = 01777;
  sim->env->inst_state = selftest;
  sim->env->pc &= ~ 01777;  // start from beginning of current 1K ROM bank
  printf ("starting CRC of bank %d addr %04o\n", sim->env->bank, sim->env->pc);
}


static void crc_update (sim_t *sim, int word)
{
  int i;
  int b;

  for (i = 0; i < 10; i++)
    {
      b = sim->env->crc & 1;
      sim->env->crc >>= 1;
      if (b ^ (word & 1))
	sim->env->crc ^= 0x331;
      word >>= 1;
    }
}


static void op_c_to_addr (sim_t *sim, int opcode)
{
  sim->env->ram_addr = (sim->env->c [1] << 4) + sim->env->c [0];
#ifdef HAS_DEBUGGER
  if (sim->debug_flags & (1 << SIM_DEBUG_RAM_TRACE))
    printf ("RAM select %02x\n", sim->env->ram_addr);
#endif
  if (sim->env->ram_addr >= sim->env->max_ram)
    printf ("c -> ram addr: address %d out of range\n", sim->env->ram_addr);
}


static void op_c_to_data (sim_t *sim, int opcode)
{
  int i;
  if (sim->env->ram_addr >= sim->env->max_ram)
    {
      printf ("c -> data: address %02x out of range\n", sim->env->ram_addr);
      return;
    }
#ifdef HAS_DEBUGGER
  if (sim->debug_flags & (1 << SIM_DEBUG_RAM_TRACE))
    {
      printf ("C -> DATA, addr %02x  data ", sim->env->ram_addr);
      for (i = 0; i < WSIZE; i++)
	printf ("%x", sim->env->c [i]);
      printf ("\n");
    }
#endif
  for (i = 0; i < WSIZE; i++)
    sim->env->ram [sim->env->ram_addr] [i] = sim->env->c [i];
}


static void op_data_to_c (sim_t *sim, int opcode)
{
  int i;
  if (sim->env->ram_addr >= sim->env->max_ram)
    {
      printf ("data -> c: address %d out of range, loading 0\n", sim->env->ram_addr);
      for (i = 0; i < WSIZE; i++)
	sim->env->c [i] = 0;
      return;
    }
#ifdef HAS_DEBUGGER
  if (sim->debug_flags & (1 << SIM_DEBUG_RAM_TRACE))
    {
      printf ("DATA -> C, addr %02x  data ", sim->env->ram_addr);
      for (i = 0; i < WSIZE; i++)
	printf ("%x", sim->env->ram [sim->env->ram_addr] [i]);
      printf ("\n");
    }
#endif /* HAS_DEBUGGER */
  for (i = 0; i < WSIZE; i++)
    sim->env->c [i] = sim->env->ram [sim->env->ram_addr] [i];
}


static void op_c_to_register (sim_t *sim, int opcode)
{
  int i;

  sim->env->ram_addr &= ~017;
  sim->env->ram_addr += (opcode >> 6);

  if (sim->env->ram_addr >= sim->env->max_ram)
    {
      printf ("c -> register: address %d out of range\n", sim->env->ram_addr);
      return;
    }
#ifdef HAS_DEBUGGER
  if (sim->debug_flags & (1 << SIM_DEBUG_RAM_TRACE))
    {
      printf ("C -> REGISTER %d, addr %02x  data ", opcode >> 6, sim->env->ram_addr);
      for (i = 0; i < WSIZE; i++)
	printf ("%x", sim->env->c [i]);
      printf ("\n");
    }
#endif /* HAS_DEBUGGER */
  for (i = 0; i < WSIZE; i++)
    sim->env->ram [sim->env->ram_addr] [i] = sim->env->c [i];
}


static void op_register_to_c (sim_t *sim, int opcode)
{
  int i;

  sim->env->ram_addr &= ~017;
  sim->env->ram_addr += (opcode >> 6);

  if (sim->env->ram_addr >= sim->env->max_ram)
    {
      printf ("register -> c: address %d out of range, loading 0\n", sim->env->ram_addr);
      for (i = 0; i < WSIZE; i++)
	sim->env->c [i] = 0;
      return;
    }
#ifdef HAS_DEBUGGER
  if (sim->debug_flags & (1 << SIM_DEBUG_RAM_TRACE))
    {
      printf ("REGISTER -> C %d, addr %02x  data ", opcode >> 6, sim->env->ram_addr);
      for (i = 0; i < WSIZE; i++)
	printf ("%x", sim->env->ram [sim->env->ram_addr] [i]);
      printf ("\n");
    }
#endif /* HAS_DEBUGGER */
  for (i = 0; i < WSIZE; i++)
    sim->env->c [i] = sim->env->ram [sim->env->ram_addr] [i];
}


static void op_clear_data_regs (sim_t *sim, int opcode)
{
  int base;
  int i, j;
#ifdef HAS_DEBUGGER
  if (sim->debug_flags & (1 << SIM_DEBUG_RAM_TRACE))
    printf ("clear data regs, addr %02x\n", sim->env->ram_addr);
#endif /* HAS_DEBUGGER */
  base = sim->env->ram_addr & ~ 017;
  for (i = base; i <= base + 15; i++)
    for (j = 0; j < WSIZE; j++)
      sim->env->ram [i] [j] = 0;
}


static void op_c_to_stack (sim_t *sim, int opcode)
{
  int i;
  for (i = 0; i < WSIZE; i++)
    {
      sim->env->t [i] = sim->env->z [i];
      sim->env->z [i] = sim->env->y [i];
      sim->env->y [i] = sim->env->c [i];
    }
}


static void op_stack_to_a (sim_t *sim, int opcode)
{
  int i;
  for (i = 0; i < WSIZE; i++)
    {
      sim->env->a [i] = sim->env->y [i];
      sim->env->y [i] = sim->env->z [i];
      sim->env->z [i] = sim->env->t [i];
    }
}


static void op_y_to_a (sim_t *sim, int opcode)
{
  int i;
  for (i = 0; i < WSIZE; i++)
    {
      sim->env->a [i] = sim->env->y [i];
    }
}


static void op_down_rotate (sim_t *sim, int opcode)
{
  int i, t;
  for (i = 0; i < WSIZE; i++)
    {
      t = sim->env->c [i];
      sim->env->c [i] = sim->env->y [i];
      sim->env->y [i] = sim->env->z [i];
      sim->env->z [i] = sim->env->t [i];
      sim->env->t [i] = t;
    }
}


static void op_clear_reg (sim_t *sim, int opcode)
{
  int i;
  for (i = 0; i < WSIZE; i++)
    sim->env->a [i] = sim->env->b [i] = sim->env->c [i] = sim->env->y [i] =
      sim->env->z [i] = sim->env->t [i];
  sim->env->f = 0;
  /* should this clear p? */
}


static void op_load_constant (sim_t *sim, int opcode)
{
  if (sim->env->p >= WSIZE)
    {
      printf ("load constant w/ p >= WSIZE at %05o\n", sim->env->prev_pc);
      woodstock_print_state (sim, sim->env);
    }
  else
    sim->env->c [sim->env->p] = opcode >> 6;
  if (sim->env->p)
    sim->env->p--;
  else
    sim->env->p = WSIZE - 1;
}


static void op_set_s (sim_t *sim, int opcode)
{
  if ((opcode >> 6) >= SSIZE)
    printf ("stat >= SSIZE at %05o\n", sim->env->prev_pc);
  else
    sim->env->s [opcode >> 6] = 1;
}


static void op_clr_s (sim_t *sim, int opcode)
{
  if ((opcode >> 6) >= SSIZE)
    printf ("stat >= SSIZE at %05o\n", sim->env->prev_pc);
  else
    sim->env->s [opcode >> 6] = 0;
}


static void op_test_s_eq_0 (sim_t *sim, int opcode)
{
  sim->env->inst_state = branch;
  sim->env->carry = sim->env->s [opcode >> 6];
}


static void op_test_s_eq_1 (sim_t *sim, int opcode)
{
  sim->env->inst_state = branch;
  sim->env->carry = ! sim->env->s [opcode >> 6];
}


static uint8_t p_set_map [16] =
  { 14,  4,  7,  8, 11,  2, 10, 12,  1,  3, 13,  6,  0,  9,  5, 14 };

static uint8_t p_test_map [16] =
  {  4,  8, 12,  2,  9,  1,  6,  3,  1, 13,  5,  0, 11, 10,  7,  4 };


static void op_set_p (sim_t *sim, int opcode)
{
  sim->env->p = p_set_map [opcode >> 6];
  if (sim->env->p >= 14)
    printf ("invalid set p, operand encoding is %02o\n", opcode > 6);
}


static void op_test_p_eq (sim_t *sim, int opcode)
{
  sim->env->inst_state = branch;
  sim->env->carry = ! (sim->env->p == p_test_map [opcode >> 6]);
}


static void op_test_p_ne (sim_t *sim, int opcode)
{
  sim->env->inst_state = branch;
  sim->env->carry = ! (sim->env->p != p_test_map [opcode >> 6]);
}


static void op_sel_rom (sim_t *sim, int opcode)
{
  sim->env->pc = ((opcode & 01700) << 2) + (sim->env->pc & 0377);
}


static void op_del_sel_rom (sim_t *sim, int opcode)
{
  sim->env->del_rom = opcode >> 6;
  sim->env->del_rom_flag = 1;
}


static void op_keys_to_rom_addr (sim_t *sim, int opcode)
{
  sim->env->pc = sim->env->pc & ~0377;
  if (sim->env->key_buf < 0)
    {
      printf ("keys->rom address with no key pressed\n");
      return;
    }
  sim->env->pc += sim->env->key_buf;
}


static void op_a_to_rom_addr (sim_t *sim, int opcode)
{
  sim->env->pc = sim->env->pc & ~0377;
  sim->env->pc += ((sim->env->a [2] << 4) + sim->env->a [1]);
}


static void op_display_off (sim_t *sim, int opcode)
{
  sim->env->display_enable = 0;
}


static void op_display_toggle (sim_t *sim, int opcode)
{
  sim->env->display_enable = ! sim->env->display_enable;
}


static void init_ops (sim_t *sim)
{
  int i;

  for (i = 0; i < 1024; i += 4)
    {
      sim->op_fcn [i + 0] = bad_op;
      sim->op_fcn [i + 1] = op_jsb;    /* type 1: aaaaaaaa01 */
      sim->op_fcn [i + 2] = op_arith;  /* type 2: ooooowww10 */
      sim->op_fcn [i + 3] = op_goto;   /* type 1: aaaaaaaa11 */
    }

  for (i = 0; i <= 15; i ++)
    {
      /* xx00 uassigned */
      sim->op_fcn [00004 + (i << 6)] = op_set_s;
      /* xx10 misc */
      sim->op_fcn [00014 + (i << 6)] = op_clr_s;
      /* xx20 misc */
      sim->op_fcn [00024 + (i << 6)] = op_test_s_eq_1;
      sim->op_fcn [00030 + (i << 6)] = op_load_constant;
      sim->op_fcn [00034 + (i << 6)] = op_test_s_eq_0;
      sim->op_fcn [00040 + (i << 6)] = op_sel_rom;
      sim->op_fcn [00044 + (i << 6)] = op_test_p_eq;
      sim->op_fcn [00050 + (i << 6)] = op_c_to_register;
      sim->op_fcn [00054 + (i << 6)] = op_test_p_ne;
      /* xx60 misc */
      sim->op_fcn [00064 + (i << 6)] = op_del_sel_rom;
      sim->op_fcn [00070 + (i << 6)] = op_register_to_c;
      sim->op_fcn [00074 + (i << 6)] = op_set_p;
    }

  sim->op_fcn [00000] = op_nop;
  sim->op_fcn [00070] = op_data_to_c;

  sim->op_fcn [00010] = op_clear_reg;
  sim->op_fcn [00110] = op_clear_s;
  sim->op_fcn [00210] = op_display_toggle;
  sim->op_fcn [00310] = op_display_off;
  sim->op_fcn [00410] = op_m1_exch_c;
  sim->op_fcn [00510] = op_m1_to_c;
  sim->op_fcn [00610] = op_m2_exch_c;
  sim->op_fcn [00710] = op_m2_to_c;
  sim->op_fcn [01010] = op_stack_to_a;
  sim->op_fcn [01110] = op_down_rotate;
  sim->op_fcn [01210] = op_y_to_a;
  sim->op_fcn [01310] = op_c_to_stack;
  sim->op_fcn [01410] = op_decimal;
  /* 1510 unassigned */
  sim->op_fcn [01610] = op_f_to_a;
  sim->op_fcn [01710] = op_f_exch_a;

  sim->op_fcn [00020] = op_keys_to_rom_addr;
  /* 0010 unknown */
  sim->op_fcn [00220] = op_a_to_rom_addr;
  /* 0320 unknown */
  sim->op_fcn [00420] = op_binary;
  sim->op_fcn [00520] = op_circulate_a_left;
  sim->op_fcn [00620] = op_dec_p;
  sim->op_fcn [00720] = op_inc_p;
  sim->op_fcn [01020] = op_return;
  /* 1120..1720 unknown, probably printer */

  /* 0060 unknown */
  /* 0160..0760 unassigned/unknown */
  sim->op_fcn [01060] = op_bank_switch;
  sim->op_fcn [01160] = op_c_to_addr;
  sim->op_fcn [01260] = op_clear_data_regs;
  sim->op_fcn [01360] = op_c_to_data;
  sim->op_fcn [01460] = op_rom_selftest;  /* Only on Spice series */
  /* 1560..1660 unassigned/unknown */
  sim->op_fcn [01760] = op_nop;  /* "HI I'M WOODSTOCK" */

  /*
   * Instruction codings unknown (probably 0120 and 0320):
   *    KEYS -> A
   *    RESET TWF
   *
   * Instruction codings unknown (probably 1160..1760):
   *    PRINT 0
   *    PRINT 1
   *    PRINT 2
   *    PRINT 3
   *    PRINT 6
   *    HOME?
   *    CR?
   */
}


static void woodstock_disassemble (sim_t *sim, int addr, char *buf, int len)
{
  int ma1, ma2;
  int op1, op2;

  if (sim->env->inst_state == branch)  /* second word of conditional branch */
    {
      snprintf (buf, len, "...");
      return;
    }

  ma1 = woodstock_map_rom_address (sim, addr);
  op1 = sim->ucode [ma1];

  ma2 = woodstock_map_rom_address (sim, addr + 1);
  op2 = sim->ucode [ma2];

  woodstock_disassemble_inst (ma1, op1, op2, buf, len);
}


static void display_scan_advance (sim_t *sim)
{
  if ((--sim->display_scan_position) < sim->right_scan)
    {
      while (sim->display_digit_position < MAX_DIGIT_POSITION)
	sim->display_segments [sim->display_digit_position++] = 0;

      sim->display_update_fn (sim->display_handle, MAX_DIGIT_POSITION,
			      sim->display_segments);

      sim->display_digit_position = 0;
      sim->display_scan_position = sim->left_scan;
    }
}


static void woodstock_display_scan (sim_t *sim)
{
  int a = sim->env->a [sim->display_scan_position];
  int b = sim->env->b [sim->display_scan_position];
  segment_bitmap_t segs = 0;

  if (sim->env->display_enable)
    {
      if (b & 2)
	{
	  if ((a >= 2) && ((a & 7) != 7))
	    segs = sim->char_gen ['-'];
	}
      else
	segs = sim->char_gen [a];
      if (b & 1)
	segs |= sim->char_gen ['.'];
    }

  sim->display_segments [sim->display_digit_position++] = segs;

  display_scan_advance (sim);
}


static void spice_display_scan (sim_t *sim)
{
  int a = sim->env->a [sim->display_scan_position];
  int b = sim->env->b [sim->display_scan_position];
  segment_bitmap_t segs = 0;

  if (! sim->display_digit_position)
    sim->display_segments [sim->display_digit_position++] = 0;  /* make room for sign */

  if (sim->env->display_enable)
    {
      if ((sim->display_scan_position == sim->left_scan) && (b & 4))
	sim->display_segments [0] = sim->char_gen ['-'];
      if (b == 6)
	{
	  if (a == 9)
	    segs = sim->char_gen ['-'];
	}
      else
	segs = sim->char_gen [a];
      if (b & 1)
	segs |= sim->char_gen [(b & 2) ? ',' : '.'];
    }

  sim->display_segments [sim->display_digit_position++] = segs;

  display_scan_advance (sim);
}


static void print_reg (char *label, reg_t reg)
{
  int i;
  printf ("%s", label);
  for (i = 13; i >= 0; i--)
    printf ("%x", reg [i]);
  printf ("\n");
}

static void woodstock_print_state (sim_t *sim, sim_env_t *env)
{
  int i;
  int mapped_addr;

  printf ("pc=%04o  radix=%d  p=%d  f=%x  stat:",
	  env->prev_pc, env->arithmetic_base, env->p, env->f);
  for (i = 0; i < 16; i++)
    if (env->s [i])
      printf (" %d", i);
  printf ("\n");
  print_reg ("a:  ", env->a);
  print_reg ("b:  ", env->b);
  print_reg ("c:  ", env->c);
  print_reg ("m1: ", env->m1);
  print_reg ("m2: ", env->m2);

  mapped_addr = woodstock_map_rom_address (sim, env->prev_pc);
  if (sim->source [mapped_addr])
    printf ("%s\n", sim->source [mapped_addr]);
  else
    {
      char buf [80];
      printf ("%lld: ", sim->cycle_count);
      woodstock_disassemble (sim, env->prev_pc, buf, sizeof (buf));
      printf ("%s\n", buf);
    }
}


bool woodstock_execute_instruction (sim_t *sim)
{
  int i;
  int opcode;
  inst_state_t prev_inst_state;

  sim->env->prev_pc = sim->env->pc;
  opcode = sim->ucode [woodstock_map_rom_address (sim, sim->env->pc)];

#ifdef HAS_DEBUGGER
  if (sim->debug_flags & (1 << SIM_DEBUG_KEY_TRACE))
    {
      if (opcode == 00020)
	sim->debug_flags |= (1 << SIM_DEBUG_TRACE);
      else if (opcode == 01724)
	sim->debug_flags &= ~ (1 << SIM_DEBUG_TRACE);
    }

  if (sim->debug_flags & (1 << SIM_DEBUG_TRACE))
    {
      woodstock_print_state (sim, sim->env);
    }
#endif /* HAS_DEBUGGER */

  prev_inst_state = sim->env->inst_state;
  if (sim->env->inst_state == branch)
    sim->env->inst_state = norm;

  sim->env->prev_carry = sim->env->carry;
  sim->env->carry = 0;

  if (sim->env->key_flag)
    sim->env->s [15] = 1;
  for (i = 0; i < SSIZE; i++)
    if (sim->env->ext_flag [i])
      sim->env->s [i] = 1;

  sim->env->pc++;

  switch (prev_inst_state)
    {
    case norm:
      (* sim->op_fcn [opcode]) (sim, opcode);
      break;
    case branch:
      if (! sim->env->prev_carry)
	sim->env->pc = (sim->env->pc & ~01777) | opcode;
      break;
    case selftest:
      if (opcode == 01060)
	op_bank_switch (sim, opcode);  // bank switch even in self-test
      crc_update (sim, opcode);
      if (! (sim->env->pc & 01777))    // end of 1K ROM bank?
	{
	  // yes, return
	  // $$$ I'm not sure what to do if CRC is bad, as I've never
	  //     had a real calculator fail the test.
	  printf ("done, crc = %03x: %s\n", sim->env->crc,
		  sim->env->crc == 0x078 ? "good" : "bad");
	  sim->env->inst_state = norm;
	  op_return (sim, 0);
	}
      break;
    }

  sim->cycle_count++;

  sim->display_scan_fn (sim);

  return (true);  /* never sleeps */
}


static bool parse_octal (char *oct, int digits, int *val)
{
  *val = 0;

  while (digits--)
    {
      if (((*oct) < '0') || ((*oct) > '7'))
	return (false);
      (*val) = ((*val) << 3) + ((*(oct++)) - '0');
    }
  return (true);
}


static bool woodstock_parse_object_line (char *buf, int *bank, int *addr,
					 rom_word_t *opcode)
{
  bool has_bank;
  int b = 0;
  int a, o;

  if (buf [0] == '#')  /* comment? */
    return (false);

  if ((strlen (buf) < 9) || (strlen (buf) > 10))
    return (false);

  if (buf [4] == ':')
    has_bank = false;
  else if (buf [5] == ':')
    has_bank = true;
  else
    {
      fprintf (stderr, "invalid object file format\n");
      return (false);
    }

  if (has_bank && ! parse_octal (& buf [0], 1, & b))
    {
      fprintf (stderr, "invalid bank in object line '%s'\n", buf);
      return (false);
    }

  if (! parse_octal (& buf [has_bank ? 1 : 0], 4, & a))
    {
      fprintf (stderr, "invalid address in object line '%s'\n", buf);
      return (false);
    }

  if (! parse_octal (& buf [has_bank ? 6 : 5], 4, & o))
    {
      fprintf (stderr, "invalid opcode in object line '%s'\n", buf);
      return (false);
    }

  *bank = b;
  *addr = a;
  *opcode = o;
  return (true);
}


static bool woodstock_parse_listing_line (char *buf, int *bank, int *addr,
					  rom_word_t *opcode)
{
  int a, o;

  if (strlen (buf) < 18)
    return (false);

  if (! parse_octal (& buf [15], 4, & a))
    {
      fprintf (stderr, "invalid address %o\n", a);
      return (false);
    }

  if (! parse_octal (& buf [ 9], 4, & o))
    {
      fprintf (stderr, "invalid opcode %o\n", o);
      return (false);
    }

  *bank = 0;
  *addr = a;
  *opcode = o;
  return (true);
}


static void woodstock_press_key (sim_t *sim, int keycode)
{
  sim->env->key_buf = keycode;
  sim->env->key_flag = true;
}

static void woodstock_release_key (sim_t *sim)
{
  sim->env->key_flag = false;
}

static void woodstock_set_ext_flag (sim_t *sim, int flag, bool state)
{
  sim->env->ext_flag [flag] = state;
}



static void woodstock_read_ram (sim_t *sim, int addr, reg_t *val)
{
  if (addr > sim->env->max_ram)
    fatal (2, "woodstock_read_ram: address %d out of range\n", addr);
  memcpy (val, sim->env->ram [addr], sizeof (reg_t));
}


static void woodstock_write_ram (sim_t *sim, int addr, reg_t *val)
{
  if (addr > sim->env->max_ram)
    fatal (2, "sim_write_ram: address %d out of range\n", addr);
  memcpy (sim->env->ram [addr], val, sizeof (reg_t));
}


static sim_env_t *woodstock_get_env (sim_t *sim)
{
  sim_env_t *env;
  size_t size;

  size = sizeof (sim_env_t) + sim->env->max_ram * sizeof (reg_t);
  env = alloc (size);
  memcpy (env, sim->env, size);
  return (env);
}

static void woodstock_set_env (sim_t *sim, sim_env_t *env)
{
  size_t size;

  size = sizeof (sim_env_t) + sim->env->max_ram * sizeof (reg_t);
  memcpy (sim->env, env, size);
}

static void woodstock_free_env (sim_t *sim, sim_env_t *env)
{
  free (env);
}


static void woodstock_reset_processor (sim_t *sim)
{
  sim->cycle_count = 0;

  sim->env->arithmetic_base = 10;

  sim->env->pc = 0;
  sim->env->del_rom_flag = 0;

  sim->env->inst_state = norm;

  sim->env->sp = 0;

  op_clear_reg (sim, 0);
  op_clear_s (sim, 0);
  sim->env->p = 0;

  sim->env->display_enable = 0;
  sim->display_digit_position = 0;
  sim->display_scan_position = WSIZE - 1;

  sim->env->key_buf = -1;  /* no key has been pressed */
  sim->env->key_flag = 0;

  if (sim->platform == PLATFORM_WOODSTOCK)
    sim->env->ext_flag [5] = 1;  /* force battery ok */
}


static void woodstock_new_processor (sim_t *sim, int ram_size)
{
  sim->env = alloc (sizeof (sim_env_t) + ram_size * sizeof (reg_t));
  sim->env->max_ram = ram_size;

  switch (sim->platform)
    {
    case PLATFORM_WOODSTOCK:
      sim->display_scan_fn = woodstock_display_scan;
      sim->left_scan = WSIZE - 1;
      sim->right_scan = 2;
      break;
    case PLATFORM_SPICE:
      sim->display_scan_fn = spice_display_scan;
      sim->left_scan = WSIZE - 2;
      sim->right_scan = 3;
      break;
    default:
      fatal (2, "Woodstock arch doesn't know how to handle display for platform %s\n", platform_name [sim->platform]);
    }

  sim->display_scan_position = sim->left_scan;
  sim->display_digit_position = 0;

  init_ops (sim);
}


static void woodstock_free_processor (sim_t *sim)
{
  free (sim->env->ram);
  free (sim->env);
  sim->env = NULL;
}


processor_dispatch_t woodstock_processor =
  {
    4096,
    2, 

    woodstock_new_processor,
    woodstock_free_processor,

    woodstock_parse_object_line,
    woodstock_parse_listing_line,

    woodstock_reset_processor,
    woodstock_execute_instruction,

    woodstock_press_key,
    woodstock_release_key,
    woodstock_set_ext_flag,

    woodstock_read_ram,
    woodstock_write_ram,
    woodstock_disassemble,

    woodstock_get_env,
    woodstock_set_env,
    woodstock_free_env,
    woodstock_print_state
  };
