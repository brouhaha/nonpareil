/*
proc_woodstock.c
$Id$
Copyright 2004 Eric L. Smith

Nonpareil is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License version 2 as
published by the Free Software Foundation.  Note that I am not
granting permission to redistribute or modify CASM under the terms of
any later version of the General Public License.

This program is distributed in the hope that it will be useful (or at least
amusing), but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with
this program (in the file "COPYING"); if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
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


#define SSIZE 12

#define MAX_GROUP 2
#define MAX_ROM 8
#define ROM_SIZE 256


struct sim_env_t
{
  reg_t a;
  reg_t b;
  reg_t c;
  reg_t d;
  reg_t e;
  reg_t f;
  reg_t m;

  digit_t p;

  uint8_t carry, prev_carry;

  uint8_t s [SSIZE];

  int ram_addr;  /* selected RAM address */

  uint8_t pc;
  uint8_t rom;
  uint8_t group;

  uint8_t del_rom;
  uint8_t del_grp;

  uint8_t ret_pc;

  int prev_pc;  /* used to store complete five-digit octal address of instruction */

  int display_enable;
  int io_count;

  bool key_flag;      /* true if a key is down */
  int key_buf;        /* most recently pressed key */

  uint8_t ext_flag [SSIZE];  /* external flags, e.g., slide switches,
				magnetic card inserted */

  int max_ram;
  reg_t ram [];
};


static void bad_op (sim_t *sim, int opcode)
{
  printf ("illegal opcode %02x at %02o%03o\n", opcode,
	  sim->env->prev_pc >> 8, sim->env->prev_pc & 0377);
}


static digit_t do_add (sim_t *sim, digit_t x, digit_t y)
{
  int res;

  res = x + y + sim->env->carry;
  if (res > 9)
    {
      res -= 10;
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
      res += 10;
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
	  printf ("Warning! p > WSIZE at %02o%03o\n",
		  sim->env->prev_pc >> 8, sim->env->prev_pc & 0377);
	  last = 0;  /* don't do anything */
	}
      break;
    case 1:  /* m  */  first =  3; last = 12; break;
    case 2:  /* x  */  first =  0; last =  2; break;
    case 3:  /* w  */  first =  0; last = 13; break;
    case 4:  /* wp */
      first =  0; last =  sim->env->p;
      if (sim->env->p > 13)
	{
	  printf ("Warning! p >= WSIZE at %02o%03o\n",
		  sim->env->prev_pc >> 8, sim->env->prev_pc & 0377);
	  last = 13;
	}
      break;
    case 5:  /* ms */  first =   3; last = 13; break;
    case 6:  /* xs */  first =   2; last =  2; break;
    case 7:  /* s  */  first =  13; last = 13; break;
    }

  switch (op)
    {
    case 0x00:  /* if b[f] = 0 */
      for (i = first; i <= last; i++)
	sim->env->carry |= (sim->env->b [i] != 0);
      break;
    case 0x01:  /* 0 -> b[f] */
      for (i = first; i <= last; i++)
	sim->env->b [i] = 0;
      sim->env->carry = 0;
      break;
    case 0x02:  /* if a >= c[f] */
      sim->env->carry = 0;
      for (i = first; i <= last; i++)
	t [i] = do_sub (sim, sim->env->a [i], sim->env->c [i]);
      break;
    case 0x03:  /* if c[f] >= 1 */
      sim->env->carry = 1;
      for (i = first; i <= last; i++)
	sim->env->carry &= (sim->env->c [i] == 0);
      break;
    case 0x04:  /* b -> c[f] */
      for (i = first; i <= last; i++)
	sim->env->c [i] = sim->env->b [i];
      sim->env->carry = 0;
      break;
    case 0x05:  /* 0 - c -> c[f] */
      sim->env->carry = 0;
      for (i = first; i <= last; i++)
	sim->env->c [i] = do_sub (sim, 0, sim->env->c [i]);
      break;
    case 0x06:  /* 0 -> c[f] */
      for (i = first; i <= last; i++)
	sim->env->c [i] = 0;
      sim->env->carry = 0;
      break;
    case 0x07:  /* 0 - c - 1 -> c[f] */
      sim->env->carry = 1;
      for (i = first; i <= last; i++)
	sim->env->c [i] = do_sub (sim, 0, sim->env->c [i]);
      break;
    case 0x08:  /* shift left a[f] */
      for (i = last; i >= first; i--)
	sim->env->a [i] = (i == first) ? 0 : sim->env->a [i-1];
      sim->env->carry = 0;
      break;
    case 0x09:  /* a -> b[f] */
      for (i = first; i <= last; i++)
	sim->env->b [i] = sim->env->a [i];
      sim->env->carry = 0;
      break;
    case 0x0a:  /* a - c -> c[f] */
      sim->env->carry = 0;
      for (i = first; i <= last; i++)
	sim->env->c [i] = do_sub (sim, sim->env->a [i], sim->env->c [i]);
      break;
    case 0x0b:  /* c - 1 -> c[f] */
      sim->env->carry = 1;
      for (i = first; i <= last; i++)
	sim->env->c [i] = do_sub (sim, sim->env->c [i], 0);
      break;
    case 0x0c:  /* c -> a[f] */
      for (i = first; i <= last; i++)
	sim->env->a [i] = sim->env->c [i];
      sim->env->carry = 0;
      break;
    case 0x0d:  /* if c[f] = 0 */
      for (i = first; i <= last; i++)
	sim->env->carry |= (sim->env->c [i] != 0);
      break;
    case 0x0e:  /* a + c -> c[f] */
      sim->env->carry = 0;
      for (i = first; i <= last; i++)
	sim->env->c [i] = do_add (sim, sim->env->a [i], sim->env->c [i]);
      break;
    case 0x0f:  /* c + 1 -> c[f] */
      sim->env->carry = 1;
      for (i = first; i <= last; i++)
	sim->env->c [i] = do_add (sim, sim->env->c [i], 0);
      break;
    case 0x10:  /* if a >= b[f] */
      sim->env->carry = 0;
      for (i = first; i <= last; i++)
	t [i] = do_sub (sim, sim->env->a [i], sim->env->b [i]);
      break;
    case 0x11:  /* b exchange c[f] */
      for (i = first; i <= last; i++)
	{
	  temp = sim->env->b[i];
	  sim->env->b [i] = sim->env->c [i];
	  sim->env->c [i] = temp;
	}
      sim->env->carry = 0;
      break;
    case 0x12:  /* shift right c[f] */
      for (i = first; i <= last; i++)
	sim->env->c [i] = (i == last) ? 0 : sim->env->c [i+1];
      sim->env->carry = 0;
      break;
    case 0x13:  /* if a[f] >= 1 */
      sim->env->carry = 1;
      for (i = first; i <= last; i++)
	sim->env->carry &= (sim->env->a [i] == 0);
      break;
    case 0x14:  /* shift right b[f] */
      for (i = first; i <= last; i++)
	sim->env->b [i] = (i == last) ? 0 : sim->env->b [i+1];
      sim->env->carry = 0;
      break;
    case 0x15:  /* c + c -> c[f] */
      sim->env->carry = 0;
      for (i = first; i <= last; i++)
	sim->env->c [i] = do_add (sim, sim->env->c [i], sim->env->c [i]);
      break;
    case 0x16:  /* shift right a[f] */
      for (i = first; i <= last; i++)
	sim->env->a [i] = (i == last) ? 0 : sim->env->a [i+1];
      sim->env->carry = 0;
      break;
    case 0x17:  /* 0 -> a[f] */
      for (i = first; i <= last; i++)
	sim->env->a [i] = 0;
      sim->env->carry = 0;
      break;
    case 0x18:  /* a - b -> a[f] */
      sim->env->carry = 0;
      for (i = first; i <= last; i++)
	sim->env->a [i] = do_sub (sim, sim->env->a [i], sim->env->b [i]);
      break;
    case 0x19:  /* a exchange b[f] */
      for (i = first; i <= last; i++)
	{
	  temp = sim->env->a[i];
	  sim->env->a [i] = sim->env->b [i];
	  sim->env->b [i] = temp; 
	}
      sim->env->carry = 0;
      break;
    case 0x1a:  /* a - c -> a[f] */
      sim->env->carry = 0;
      for (i = first; i <= last; i++)
        sim->env->a [i] = do_sub (sim, sim->env->a [i], sim->env->c [i]);
      break;
    case 0x1b:  /* a - 1 -> a[f] */
      sim->env->carry = 1;
      for (i = first; i <= last; i++)
	sim->env->a [i] = do_sub (sim, sim->env->a [i], 0);
      break;
    case 0x1c:  /* a + b -> a[f] */
      sim->env->carry = 0;
      for (i = first; i <= last; i++)
	sim->env->a [i] = do_add (sim, sim->env->a [i], sim->env->b [i]);
      break;
    case 0x1d:  /* a exchange c[f] */
      for (i = first; i <= last; i++)
	{
	  temp = sim->env->a [i];
	  sim->env->a [i] = sim->env->c [i];
	  sim->env->c [i] = temp;
	}
      sim->env->carry = 0;
      break;
    case 0x1e:  /* a + c -> a[f] */
      sim->env->carry = 0;
      for (i = first; i <= last; i++)
	sim->env->a [i] = do_add (sim, sim->env->a [i], sim->env->c [i]);
      break;
    case 0x1f:  /* a + 1 -> a[f] */
      sim->env->carry = 1;
      for (i = first; i <= last; i++)
	sim->env->a [i] = do_add (sim, sim->env->a [i], 0);
      break;
    }
}


static void op_goto (sim_t *sim, int opcode)
{
  if (! sim->env->prev_carry)
    {
      sim->env->pc = opcode >> 2;
      sim->env->rom = sim->env->del_rom;
      sim->env->group = sim->env->del_grp;
    }
}


static void op_jsb (sim_t *sim, int opcode)
{
  sim->env->ret_pc = sim->env->pc;
  sim->env->pc = opcode >> 2;
  sim->env->rom = sim->env->del_rom;
  sim->env->group = sim->env->del_grp;
}


static void op_return (sim_t *sim, int opcode)
{
  sim->env->pc = sim->env->ret_pc;
}


static void op_nop (sim_t *sim, int opcode)
{
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
    sim->env->s [i] = 0;
}


static void op_c_exch_m (sim_t *sim, int opcode)
{
  int i, t;
  for (i = 0; i < WSIZE; i++)
    {
      t = sim->env->c [i];
      sim->env->c [i] = sim->env->m[i];
      sim->env->m [i] = t;
    }
}


static void op_m_to_c (sim_t *sim, int opcode)
{
  int i;
  for (i = 0; i < WSIZE; i++)
    sim->env->c [i] = sim->env->m [i];
}


static void op_c_to_addr (sim_t *sim, int opcode)
{
  if (sim->env->max_ram > 10)
    sim->env->ram_addr = sim->env->c [12] * 10 + sim->env->c [11];
  else
    sim->env->ram_addr = sim->env->c [12];
  if (sim->env->ram_addr >= sim->env->max_ram)
    printf ("c -> ram addr: address %d out of range\n", sim->env->ram_addr);
}


static void op_c_to_data (sim_t *sim, int opcode)
{
  int i;
  if (sim->env->ram_addr >= sim->env->max_ram)
    {
      printf ("c -> data: address %d out of range\n", sim->env->ram_addr);
      return;
    }
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
  for (i = 0; i < WSIZE; i++)
    sim->env->c [i] = sim->env->ram [sim->env->ram_addr] [i];
}


static void op_c_to_stack (sim_t *sim, int opcode)
{
  int i;
  for (i = 0; i < WSIZE; i++)
    {
      sim->env->f [i] = sim->env->e [i];
      sim->env->e [i] = sim->env->d [i];
      sim->env->d [i] = sim->env->c [i];
    }
}


static void op_stack_to_a (sim_t *sim, int opcode)
{
  int i;
  for (i = 0; i < WSIZE; i++)
    {
      sim->env->a [i] = sim->env->d [i];
      sim->env->d [i] = sim->env->e [i];
      sim->env->e [i] = sim->env->f [i];
    }
}


static void op_down_rotate (sim_t *sim, int opcode)
{
  int i, t;
  for (i = 0; i < WSIZE; i++)
    {
      t = sim->env->c [i];
      sim->env->c [i] = sim->env->d [i];
      sim->env->d [i] = sim->env->e [i];
      sim->env->e [i] = sim->env->f [i];
      sim->env->f [i] = t;
    }
}


static void op_clear_reg (sim_t *sim, int opcode)
{
  int i;
  for (i = 0; i < WSIZE; i++)
    sim->env->a [i] = sim->env->b [i] = sim->env->c [i] = sim->env->d [i] =
      sim->env->e [i] = sim->env->f [i] = sim->env->m [i] = 0;
}


static void op_load_constant (sim_t *sim, int opcode)
{
  if (sim->env->p >= WSIZE)
    {
#if 0 /* HP-45 depends on load constant with p > 13 not affecting C */
      printf ("load constant w/ p >= WSIZE at %02o%03o\n",
	      sim->env->prev_pc >> 8, sim->env->prev_pc & 0377)
      ;
#endif
    }
  else if ((opcode >> 6) > 9)
    printf ("load constant > 9\n");
  else
    sim->env->c [sim->env->p] = opcode >> 6;
  sim->env->p = (sim->env->p - 1) & 0xf;
}


static void op_set_s (sim_t *sim, int opcode)
{
  if ((opcode >> 6) >= SSIZE)
    printf ("stat >= SSIZE at %02o%03o\n",
	    sim->env->prev_pc >> 8, sim->env->prev_pc & 0377);
  else
    sim->env->s [opcode >> 6] = 1;
}


static void op_clr_s (sim_t *sim, int opcode)
{
  if ((opcode >> 6) >= SSIZE)
    printf ("stat >= SSIZE at %02o%03o\n",
	    sim->env->prev_pc >> 8, sim->env->prev_pc & 0377);
  else
    sim->env->s [opcode >> 6] = 0;
}


static void op_test_s (sim_t *sim, int opcode)
{
  if ((opcode >> 6) >= SSIZE)
    printf ("stat >= SSIZE at %02o%03o\n",
	    sim->env->prev_pc >> 8, sim->env->prev_pc & 0377);
  else
    sim->env->carry = sim->env->s [opcode >> 6];
}


static void op_set_p (sim_t *sim, int opcode)
{
  sim->env->p = opcode >> 6;
}


static void op_test_p (sim_t *sim, int opcode)
{
  sim->env->carry = (sim->env->p == (opcode >> 6));
}


static void op_sel_rom (sim_t *sim, int opcode)
{
  sim->env->rom = opcode >> 7;
  sim->env->group = sim->env->del_grp;

  sim->env->del_rom = sim->env->rom;
}


static void op_del_sel_rom (sim_t *sim, int opcode)
{
  sim->env->del_rom = opcode >> 7;
}


static void op_del_sel_grp (sim_t *sim, int opcode)
{
  sim->env->del_grp = (opcode >> 7) & 1;
}


static void op_keys_to_rom_addr (sim_t *sim, int opcode)
{
  if (sim->env->key_buf < 0)
    {
      printf ("keys->rom address with no key pressed\n");
      sim->env->pc = 0;
      return;
    }
  sim->env->pc = sim->env->key_buf;
}


static void op_rom_addr_to_buf (sim_t *sim, int opcode)
{
  /* I don't know what this instruction is supposed to do! */
#if 0
  fprintf (stderr, "rom addr to buf!!!!!!!!!!!!\n");
#endif
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
  int i, j;

  for (i = 0; i < 1024; i += 4)
    {
      sim->op_fcn [i + 0] = bad_op;
      sim->op_fcn [i + 1] = op_jsb;    /* type 1: aaaaaaaa01 */
      sim->op_fcn [i + 2] = op_arith;  /* type 2: ooooowww10 */
      sim->op_fcn [i + 3] = op_goto;   /* type 1: aaaaaaaa11 */
    }

  /* type 3 instructions: nnnnff0100*/
  for (i = 0; i <= 15; i ++)
    {
      sim->op_fcn [0x004 + (i << 6)] = op_set_s;
      sim->op_fcn [0x014 + (i << 6)] = op_test_s;
      sim->op_fcn [0x024 + (i << 6)] = op_clr_s;
      sim->op_fcn [0x034 /* + (i << 6) */ ] = op_clear_s;
    }

  /* New instructions in HP-55 and maybe HP-65, wedged into the unused
     port of the type 3 instruction space.  On the HP-35 and HP-80 these
     probably cleared all status like 0x034. */
  for (i = 0; i <= 7; i ++)
    {
      sim->op_fcn [0x074 + (i << 7)] = op_del_sel_rom;
    }
  sim->op_fcn [0x234] = op_del_sel_grp;
  sim->op_fcn [0x2b4] = op_del_sel_grp;

  /* type 4 instructions: ppppff1100 */
  for (i = 0; i <= 15; i ++)
    {
      sim->op_fcn [0x00c + (i << 6)] = op_set_p;
      sim->op_fcn [0x02c + (i << 6)] = op_test_p;
      sim->op_fcn [0x01c /* + (i << 6) */ ] = op_dec_p;
      sim->op_fcn [0x03c /* + (i << 6) */ ] = op_inc_p;
    }

  /* type 5 instructions: nnnnff1000 */
  for (i = 0; i <= 9; i++)
      sim->op_fcn [0x018 + (i << 6)] = op_load_constant;
  for (i = 0; i <= 1; i++)
    {
      sim->op_fcn [0x028 /* + (i << 4) */ ] = op_display_toggle;
      sim->op_fcn [0x0a8 /* + (i << 4) */ ] = op_c_exch_m;
      sim->op_fcn [0x128 /* + (i << 4) */ ] = op_c_to_stack;
      sim->op_fcn [0x1a8 /* + (i << 4) */ ] = op_stack_to_a;
      sim->op_fcn [0x228 /* + (i << 4) */ ] = op_display_off;
      sim->op_fcn [0x2a8 /* + (i << 4) */ ] = op_m_to_c;
      sim->op_fcn [0x328 /* + (i << 4) */ ] = op_down_rotate;
      sim->op_fcn [0x3a8 /* + (i << 4) */ ] = op_clear_reg;
      for (j = 0; j <= 3; j++)
	{
#if 0
	  sim->op_fcn [0x068 + (j << 8) + (i << 4)] = op_is_to_a;
#endif
	  sim->op_fcn [0x0e8 + (j << 8) + (i << 4)] = op_data_to_c;
	  /* BCD->C is nominally 0x2f8 */
	}
    }

  /* type 6 instructions: nnnff10000 */
  for (i = 0; i <= 7; i++)
    {
      sim->op_fcn [0x010 + (i << 7)] = op_sel_rom;
      sim->op_fcn [0x030 /* + (i << 7) */ ] = op_return;
      if (i & 1)
	sim->op_fcn [0x050 + 0x080 /* + (i << 7) */ ] = op_keys_to_rom_addr;
#if 0
      else
	sim->op_fcn [0x050 /* + (i << 7) */ ] = op_external_entry;
#endif
    }
  sim->op_fcn [0x270] = op_c_to_addr;  /* also 0x370 */
  sim->op_fcn [0x2f0] = op_c_to_data;

  /* no type 7 or type 8 instructions: xxxx100000, xxx1000000 */

  /* type 9 and 10 instructions: xxx0000000 */
  sim->op_fcn [0x200] = op_rom_addr_to_buf;
  sim->op_fcn [0x000] = op_nop;
}


static void classic_disassemble (sim_t *sim, int addr, char *buf, int len)
{
  int l;

  l = snprintf (buf, len, "%02o%03o: ", addr >> 8, addr & 0377);
  buf += l;
  len -= l;
  if (len <= 0)
    return;

  l = snprintf (buf, len, "%04o", sim->ucode [addr]);
  buf += l;
  len -= l;
  if (len <= 0)
    return;

  return;
}


static void classic_handle_io (sim_t *sim)
{
  char buf [(WSIZE + 1) * 2 + 1];
  char *bp;
  int i;

  bp = & buf [0];
  if (sim->env->display_enable)
    {
      for (i = WSIZE - 1; i >= 0; i--)
	{
	  if (sim->env->b [i] >= 8)
	    *bp++ = ' ';
	  else if ((i == 2) || (i == 13))
	    {
	      if (sim->env->a [i] >= 8)
		*bp++ = '-';
	      else
		*bp++ = ' ';
	    }
	  else
	    *bp++ = '0' + sim->env->a [i];
	  *bp++ = ' ';  /* no decimal in same digit */

	  if (sim->env->b [i] == 2)
	    {
	      *bp++ = '.';  /* decimal gets its own digit position */
	      *bp++ = ' ';
	    }
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

static void classic_print_state (sim_t *sim, sim_env_t *env)
{
  int i;
  printf ("pc=%05o  p=%d  stat:",
	  (env->group << 11) + (env->rom << 8) + (env->pc),
	  env->p);
  for (i = 0; i < 14; i++)
    if (env->s [i])
      printf (" %d", i);
  printf ("\n");
  print_reg ("a: ", env->a);
  print_reg ("b: ", env->b);
  print_reg ("c: ", env->c);
  print_reg ("m: ", env->m);
}

void classic_execute_instruction (sim_t *sim)
{
  int addr;
  int i;
  int opcode;

  addr = (sim->env->group << 11) | (sim->env->rom << 8) | sim->env->pc;
  sim->env->prev_pc = addr;
  opcode = sim->ucode [addr];

#if 0
  printf ("%s\n", sim->source [addr]);
#endif

  sim->env->prev_carry = sim->env->carry;
  sim->env->carry = 0;

  if (sim->env->key_flag)
    sim->env->s [0] = 1;
  for (i = 0; i < SSIZE; i++)
    if (sim->env->ext_flag [i])
      sim->env->s [i] = 1;

  sim->env->pc++;
  (* sim->op_fcn [opcode]) (sim, opcode);
  sim->cycle_count++;

  classic_handle_io (sim);
}


static int parse_address (char *oct, int *g, int *r, int *p)
{
  return (sscanf (oct, "%1o%1o%3o", g, r, p) == 3);
}


static int parse_opcode (char *bin, int *opcode)
{
  int i;

  *opcode = 0;
  for (i = 0; i < 10; i++)
    {
      (*opcode) <<= 1;
      if (*bin == '1')
	(*opcode) += 1;
      else if (*bin == '.')
	(*opcode) += 0;
      else
	return (0);
      *bin++;
    }
  return (1);
}


static bool classic_parse_listing_line (char *buf, int *bank, int *addr,
					rom_word_t *opcode)
{
  int g, r, p, o;

  if ((strlen (buf) < 25) || (buf [7] != 'L') || (buf [13] != ':'))
    return (false);

  if (! parse_address (& buf [8], &g, &r, &p))
    {
      fprintf (stderr, "bad address\n");
      return (false);
    }

  if ((g >= MAX_GROUP) || (r >= MAX_ROM) || (p >= ROM_SIZE))
    {
      fprintf (stderr, "bad address\n");
      return (false);
    }

  if (! parse_opcode (& buf [16], & o))
    {
      fprintf (stderr, "bad opcode\n");
      return (false);
    }

  *bank = 0;
  *addr = (g << 11) + (r << 8) + p;
  *opcode = o;
  return (true);
}


static void classic_press_key (sim_t *sim, int keycode)
{
  sim->env->key_buf = keycode;
  sim->env->key_flag = true;
}

static void classic_release_key (sim_t *sim)
{
  sim->env->key_flag = false;
}

static void classic_set_ext_flag (sim_t *sim, int flag, bool state)
{
  sim->env->ext_flag [flag] = state;
}


void classic_reset_processor (sim_t *sim)
{
  sim->cycle_count = 0;

  sim->env->pc = 0;
  sim->env->rom = 0;
  sim->env->group = 0;
  sim->env->del_rom = 0;
  sim->env->del_grp = 0;

  op_clear_reg (sim, 0);
  op_clear_s (sim, 0);
  sim->env->p = 0;

  sim->env->display_enable = 0;
  sim->env->key_flag = 0;
}


static void classic_read_ram (sim_t *sim, int addr, reg_t *val)
{
  if (addr > sim->env->max_ram)
    fatal (2, "classic_read_ram: address %d out of range\n", addr);
  memcpy (val, & sim->env->ram [addr], sizeof (reg_t));
}


static void classic_write_ram (sim_t *sim, int addr, reg_t *val)
{
  if (addr > sim->env->max_ram)
    fatal (2, "sim_write_ram: address %d out of range\n", addr);
  memcpy (& sim->env->ram [addr], val, sizeof (reg_t));
}


static sim_env_t *classic_get_env (sim_t *sim)
{
  sim_env_t *env;
  size_t size;

  size = sizeof (sim_env_t) + sim->env->max_ram * sizeof (reg_t);
  env = alloc (size);
  memcpy (env, sim->env, size);
  return (env);
}

static void classic_set_env (sim_t *sim, sim_env_t *env)
{
  size_t size;

  size = sizeof (sim_env_t) + sim->env->max_ram * sizeof (reg_t);
  memcpy (sim->env, env, size);
}

static void classic_free_env (sim_t *sim, sim_env_t *env)
{
  free (env);
}


static void classic_new_processor (sim_t *sim, int ram_size)
{
  sim->env = alloc (sizeof (sim_env_t) + ram_size * sizeof (reg_t));
  sim->env->max_ram = ram_size;

  init_ops (sim);
}


static void classic_free_processor (sim_t *sim)
{
  free (sim->env->ram);
  free (sim->env);
  sim->env = NULL;
}


processor_dispatch_t classic_processor =
  {
    4096,
    1,

    classic_new_processor,
    classic_free_processor,

    classic_parse_listing_line,

    classic_reset_processor,
    classic_execute_instruction,

    classic_press_key,
    classic_release_key,
    classic_set_ext_flag,

    classic_read_ram,
    classic_write_ram,
    classic_disassemble,

    classic_get_env,
    classic_set_env,
    classic_free_env,
    classic_print_state
  };
