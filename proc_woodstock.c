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

#include <glib.h>  /* It would be really nice to get rid of this.  See
		      the note at the top of the declaration of
		      struct sim_t in proc_int.h. */

#include "arch.h"
#include "util.h"
#include "proc.h"
#include "proc_int.h"


#define SSIZE 16
#define STACK_SIZE 2


struct sim_env_t
{
  reg_t a;
  reg_t b;
  reg_t c;
  reg_t y;
  reg_t z;
  reg_t t;
  reg_t m1;
  reg_t m2;

  digit_t f;

  digit_t p;

  uint8_t arithmetic_base;  /* 10 or 16 */

  uint8_t carry, prev_carry;

  uint8_t s [SSIZE];  /* status bits */
  uint8_t ext_flag [SSIZE];  /* external flags, cause status bits to get set */

  int ram_addr;  /* selected RAM address */

  uint16_t pc;

  uint8_t del_rom_flag;
  uint8_t del_rom;

  uint8_t if_flag;  /* True if "IF" instruction was executed, in which
		       case the next instruction word fetched is a 10-bit
		       branch address. */

  int sp;  /* stack pointer */
  uint16_t return_stack [STACK_SIZE];

  int prev_pc;  /* used to store complete five-digit octal address of instruction */

  int display_enable;
  int io_count;

  bool key_flag;      /* true if a key is down */
  int key_buf;        /* most recently pressed key */

  int max_ram;
  reg_t ram [];	      /* dynamically sized */
};


/* If defined, print debug messages for all RAM accesses. */
#undef RAM_DEBUG


/* If defined, print warnings about stack overflow or underflow. */
#undef STACK_WARNING


/* KEYTRACE is defined, trace from ROM -> KEYS through next key status
   test */
#undef KEYTRACE



static int trace = 0;


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
	  printf ("Warning! p > WSIZE at %05o\n", sim->env->prev_pc);
	  last = 0;  /* don't do anything */
	}
      break;
    case 1:  /* wp */
      first =  0; last =  sim->env->p;
      if (sim->env->p > 13)
	{
	  printf ("Warning! p >= WSIZE at %05o\n", sim->env->prev_pc);
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
      sim->env->if_flag = 1;
      for (i = first; i <= last; i++)
	sim->env->carry |= (sim->env->b [i] != 0);
      break;
    case 0x17:  /* if c[f] = 0 */
      sim->env->if_flag = 1;
      for (i = first; i <= last; i++)
	sim->env->carry |= (sim->env->c [i] != 0);
      break;
    case 0x18:  /* if a >= c[f] */
      sim->env->if_flag = 1;
      sim->env->carry = 0;
      for (i = first; i <= last; i++)
	t [i] = do_sub (sim, sim->env->a [i], sim->env->c [i]);
      break;
    case 0x19:  /* if a >= b[f] */
      sim->env->if_flag = 1;
      sim->env->carry = 0;
      for (i = first; i <= last; i++)
	t [i] = do_sub (sim, sim->env->a [i], sim->env->b [i]);
      break;
    case 0x1a:  /* if a[f] # 0 */
      sim->env->if_flag = 1;
      sim->env->carry = 1;
      for (i = first; i <= last; i++)
	sim->env->carry &= (sim->env->a [i] == 0);
      break;
    case 0x1b:  /* if c[f] # 0 */
      sim->env->if_flag = 1;
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


static void op_dec_p (sim_t *sim, int opcode)
{
  sim->env->p = (sim->env->p - 1) & 0xf;
}


static void op_inc_p (sim_t *sim, int opcode)
{
  sim->env->p = (sim->env->p + 1) & 0xf;
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


static void op_c_to_addr (sim_t *sim, int opcode)
{
  sim->env->ram_addr = (sim->env->c [1] << 4) + sim->env->c [0];
#ifdef RAM_DEBUG
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
#ifdef RAM_DEBUG
  printf ("C -> DATA, addr %02x\n", sim->env->ram_addr);
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
#ifdef RAM_DEBUG
  printf ("DATA -> C, addr %02x\n", sim->env->ram_addr);
#endif
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
#ifdef RAM_DEBUG
  printf ("C -> REGISTER %d, addr %02x\n", opcode >> 6, sim->env->ram_addr);
#endif
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
#ifdef RAM_DEBUG
  printf ("REGISTER -> C %d, addr %02x\n", opcode >> 6, sim->env->ram_addr);
#endif
  for (i = 0; i < WSIZE; i++)
    sim->env->c [i] = sim->env->ram [sim->env->ram_addr] [i];
}


static void op_clear_data_regs (sim_t *sim, int opcode)
{
  int i, j;
  for (i = 0; i < sim->env->max_ram; i++)
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
#if 0 /* HP-45 depends on load constant with p > 13 not affecting C */
      printf ("load constant w/ p >= WSIZE at %05o\n", sim->env->prev_pc)
      ;
#endif
    }
  else
    sim->env->c [sim->env->p] = opcode >> 6;
  sim->env->p = (sim->env->p - 1) & 0xf;
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
  sim->env->if_flag = 1;
  sim->env->carry = sim->env->s [opcode >> 6];
}


static void op_test_s_eq_1 (sim_t *sim, int opcode)
{
  sim->env->if_flag = 1;
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
  sim->env->if_flag = 1;
  sim->env->carry = ! (sim->env->p == p_test_map [opcode >> 6]);
}


static void op_test_p_ne (sim_t *sim, int opcode)
{
  sim->env->if_flag = 1;
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
  sim->env->io_count = 2;
  /*
   * Don't immediately turn off display because the very next instruction
   * might be a display_toggle to turn it on.  This happens in the HP-45
   * stopwatch.
   */
}


static void op_display_toggle (sim_t *sim, int opcode)
{
  sim->env->display_enable = ! sim->env->display_enable;
  sim->env->io_count = 0;  /* force immediate display update */
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
  /* 0520 unknown */
  sim->op_fcn [00620] = op_dec_p;
  sim->op_fcn [00720] = op_inc_p;
  sim->op_fcn [01020] = op_return;
  /* 1120..1720 unknown, probably printer */

  /* 0060 unknown */
  /* 0160..0760 unassigned/unknown */
  /* sim->op_fcn [01060] = op_bank_switch; */
  sim->op_fcn [01160] = op_c_to_addr;
  sim->op_fcn [01260] = op_clear_data_regs;
  sim->op_fcn [01360] = op_c_to_data;
  /* sim->op_fcn [01460] = op_rom_checksum; */
  /* 1560..1660 unassigned/unknown */
  sim->op_fcn [01760] = op_nop;  /* "HI I'M WOODSTOCK" */

  /*
   * Instruction codings unknown (probably 0120, 0320, and 0520):
   *    SHIFT_LEFT_CIRCULAR A
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
  int l;

  l = snprintf (buf, len, "%04o: ", addr);
  buf += l;
  len -= l;
  if (len <= 0)
    return;

  /* $$$ should use current bank rather than always bank 0 */
  l = snprintf (buf, len, "%04d", sim->ucode [addr]);
  buf += l;
  len -= l;
  if (len <= 0)
    return;

  return;
}


static char display_char [16] = "0123456789rHoPE ";
  

static void woodstock_handle_io (sim_t *sim)
{
  char buf [(WSIZE + 1) * 2 + 1];
  char *bp;
  int i;

  bp = & buf [0];
  if (sim->env->display_enable)
    {
      for (i = WSIZE - 1; i >= 2; i--)  /* 12 digits rather than 14 */
	{
	  if (sim->env->b [i] & 2)
	    {
	      if ((sim->env->a [i] <= 1) || ((sim->env->a [i] & 7) == 7))
		*bp++ = ' ';
	      else
		*bp++ = '-';
	    }
	  else
	    {
	      *bp++ = display_char [sim->env->a [i]];
	    }
	  if (sim->env->b [i] & 1)
	    *bp++ = '.';
	  else
	    *bp++ = ' ';
	}
    }
  *bp = '\0';
  if (strcmp (buf, sim->prev_display) != 0)
    {
      sim->display_update (buf);
      strncpy (sim->prev_display, buf, sizeof (buf));
    }
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
  printf ("pc=%04o  radix=%d  p=%d  f=%x  stat:",
	  env->pc, env->arithmetic_base, env->p, env->f);
  for (i = 0; i < 16; i++)
    if (env->s [i])
      printf (" %d", i);
  printf ("\n");
  print_reg ("a:  ", env->a);
  print_reg ("b:  ", env->b);
  print_reg ("c:  ", env->c);
  print_reg ("m1: ", env->m1);
  print_reg ("m2: ", env->m2);
}


void woodstock_execute_instruction (sim_t *sim)
{
  int i;
  int opcode;
  int prev_if_flag;

  sim->env->prev_pc = sim->env->pc;
  prev_if_flag = sim->env->if_flag;
  sim->env->if_flag = 0;

  /* $$$ need to handle bank switching */
  opcode = sim->ucode [sim->env->pc];

#ifdef KEYTRACE
  if (opcode == 00020)
    trace = 1;
  else if (opcode == 01724)
    trace = 0;
#endif

  if (trace)
    {
      woodstock_print_state (sim, sim->env);
      /* $$$ need to handle bank switching */
      printf ("%s\n", sim->source [sim->env->pc]);
    }

  sim->env->prev_carry = sim->env->carry;
  sim->env->carry = 0;

  if (sim->env->key_flag)
    sim->env->s [15] = 1;
  for (i = 0; i < SSIZE; i++)
    if (sim->env->ext_flag [i])
      sim->env->s [i] = 1;

  sim->env->pc++;

  if (prev_if_flag)
    {
      if (! sim->env->prev_carry)
	sim->env->pc = (sim->env->pc & ~01777) | opcode;
    }
  else
    (* sim->op_fcn [opcode]) (sim, opcode);

  sim->cycle_count++;

  woodstock_handle_io (sim);
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
  int a, o;

  if (buf [0] == '#')  /* comment? */
    return (false);

  if (strlen (buf) != 9)
    return (false);

  if (buf [4] != ':')
    {
      fprintf (stderr, "invalid object file format\n");
      return (false);
    }

  if (! parse_octal (& buf [0], 4, & a))
    {
      fprintf (stderr, "invalid address %o\n", a);
      return (false);
    }

  if (! parse_octal (& buf [5], 4, & o))
    {
      fprintf (stderr, "invalid opcode %o\n", o);
      return (false);
    }

  *bank = 0;
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
  sim->env->arithmetic_base = 10;

  sim->env->pc = 0;
  sim->env->del_rom_flag = 0;

  sim->env->if_flag = 0;

  sim->env->sp = 0;

  op_clear_reg (sim, 0);
  op_clear_s (sim, 0);
  sim->env->p = 0;

  sim->env->display_enable = 0;

  sim->env->key_buf = -1;  /* no key has been pressed */
  sim->env->key_flag = 0;

  sim->env->ext_flag [5] = 1;  /* force battery ok */
}


static void woodstock_new_processor (sim_t *sim, int ram_size)
{
  sim->env = alloc (sizeof (sim_env_t) + ram_size * sizeof (reg_t));
  sim->env->max_ram = ram_size;

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
