/*
CSIM is a simulator for the processor used in the HP "Classic" series
of calculators, which includes the HP-35, HP-45, HP-55, HP-65, HP-70,
and HP-80.

$Id$
Copyright 1995, 2004 Eric L. Smith

CSIM is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License version 2 as published by the Free
Software Foundation.  Note that I am not granting permission to redistribute
or modify CSIM under the terms of any later version of the General Public
License.

This program is distributed in the hope that it will be useful (or at least
amusing), but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with
this program (in the file "COPYING"); if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <glib.h>

#include "proc.h"
#include "util.h"


#define MAX_GROUP 2
#define MAX_ROM 8
#define ROM_SIZE 256


typedef enum
  {
    SIM_UNKNOWN,
    SIM_IDLE,
    SIM_RESET,
    SIM_STEP,
    SIM_RUN,
    SIM_QUIT
  } sim_state_t;


struct sim_t
{
  GThread *thread;
  GCond *sim_cond;
  GCond *ui_cond;
  GMutex *sim_mutex;

  GTimeVal tv;
  GTimeVal prev_tv;

  sim_state_t state;
  sim_state_t prev_state;

  sim_env_t env;
  uint64_t cycle_count;

  void (*display_update)(char *buf);

  romword ucode [MAX_GROUP] [MAX_ROM] [ROM_SIZE];
  uint8_t bpt     [MAX_GROUP] [MAX_ROM] [ROM_SIZE];
  char *source  [MAX_GROUP] [MAX_ROM] [ROM_SIZE];

  void (* op_fcn [1024])(struct sim_t *sim, int opcode);

  char prev_display [WSIZE + 2];
};


static void bad_op (sim_t *sim, int opcode)
{
  printf ("illegal opcode %02x at %05o\n", opcode, sim->env.prev_pc);
}


static digit_t do_add (sim_t *sim, digit_t x, digit_t y)
{
  int res;

  res = x + y + sim->env.carry;
  if (res > 9)
    {
      res -= 10;
      sim->env.carry = 1;
    }
  else
    sim->env.carry = 0;
  return (res);
}


static digit_t do_sub (sim_t *sim, digit_t x, digit_t y)
{
  int res;

  res = (x - y) - sim->env.carry;
  if (res < 0)
    {
      res += 10;
      sim->env.carry = 1;
    }
  else
    sim->env.carry = 0;
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
      first =  sim->env.p; last =  sim->env.p;
      if (sim->env.p >= WSIZE)
	{
	  printf ("Warning! p > WSIZE at %05o\n", sim->env.prev_pc);
	  last = 0;  /* don't do anything */
	}
      break;
    case 1:  /* m  */  first =  3; last = 12; break;
    case 2:  /* x  */  first =  0; last =  2; break;
    case 3:  /* w  */  first =  0; last = 13; break;
    case 4:  /* wp */
      first =  0; last =  sim->env.p;
      if (sim->env.p > 13)
	{
	  printf ("Warning! p >= WSIZE at %05o\n", sim->env.prev_pc);
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
	sim->env.carry |= (sim->env.b [i] != 0);
      break;
    case 0x01:  /* 0 -> b[f] */
      for (i = first; i <= last; i++)
	sim->env.b [i] = 0;
      sim->env.carry = 0;
      break;
    case 0x02:  /* if a >= c[f] */
      sim->env.carry = 0;
      for (i = first; i <= last; i++)
	t [i] = do_sub (sim, sim->env.a [i], sim->env.c [i]);
      break;
    case 0x03:  /* if c[f] >= 1 */
      sim->env.carry = 1;
      for (i = first; i <= last; i++)
	sim->env.carry &= (sim->env.c [i] == 0);
      break;
    case 0x04:  /* b -> c[f] */
      for (i = first; i <= last; i++)
	sim->env.c [i] = sim->env.b [i];
      sim->env.carry = 0;
      break;
    case 0x05:  /* 0 - c -> c[f] */
      sim->env.carry = 0;
      for (i = first; i <= last; i++)
	sim->env.c [i] = do_sub (sim, 0, sim->env.c [i]);
      break;
    case 0x06:  /* 0 -> c[f] */
      for (i = first; i <= last; i++)
	sim->env.c [i] = 0;
      sim->env.carry = 0;
      break;
    case 0x07:  /* 0 - c - 1 -> c[f] */
      sim->env.carry = 1;
      for (i = first; i <= last; i++)
	sim->env.c [i] = do_sub (sim, 0, sim->env.c [i]);
      break;
    case 0x08:  /* shift left a[f] */
      for (i = last; i >= first; i--)
	sim->env.a [i] = (i == first) ? 0 : sim->env.a [i-1];
      sim->env.carry = 0;
      break;
    case 0x09:  /* a -> b[f] */
      for (i = first; i <= last; i++)
	sim->env.b [i] = sim->env.a [i];
      sim->env.carry = 0;
      break;
    case 0x0a:  /* a - c -> c[f] */
      sim->env.carry = 0;
      for (i = first; i <= last; i++)
	sim->env.c [i] = do_sub (sim, sim->env.a [i], sim->env.c [i]);
      break;
    case 0x0b:  /* c - 1 -> c[f] */
      sim->env.carry = 1;
      for (i = first; i <= last; i++)
	sim->env.c [i] = do_sub (sim, sim->env.c [i], 0);
      break;
    case 0x0c:  /* c -> a[f] */
      for (i = first; i <= last; i++)
	sim->env.a [i] = sim->env.c [i];
      sim->env.carry = 0;
      break;
    case 0x0d:  /* if c[f] = 0 */
      for (i = first; i <= last; i++)
	sim->env.carry |= (sim->env.c [i] != 0);
      break;
    case 0x0e:  /* a + c -> c[f] */
      sim->env.carry = 0;
      for (i = first; i <= last; i++)
	sim->env.c [i] = do_add (sim, sim->env.a [i], sim->env.c [i]);
      break;
    case 0x0f:  /* c + 1 -> c[f] */
      sim->env.carry = 1;
      for (i = first; i <= last; i++)
	sim->env.c [i] = do_add (sim, sim->env.c [i], 0);
      break;
    case 0x10:  /* if a >= b[f] */
      sim->env.carry = 0;
      for (i = first; i <= last; i++)
	t [i] = do_sub (sim, sim->env.a [i], sim->env.b [i]);
      break;
    case 0x11:  /* b exchange c[f] */
      for (i = first; i <= last; i++)
	{
	  temp = sim->env.b[i];
	  sim->env.b [i] = sim->env.c [i];
	  sim->env.c [i] = temp;
	}
      sim->env.carry = 0;
      break;
    case 0x12:  /* shift right c[f] */
      for (i = first; i <= last; i++)
	sim->env.c [i] = (i == last) ? 0 : sim->env.c [i+1];
      sim->env.carry = 0;
      break;
    case 0x13:  /* if a[f] >= 1 */
      sim->env.carry = 1;
      for (i = first; i <= last; i++)
	sim->env.carry &= (sim->env.a [i] == 0);
      break;
    case 0x14:  /* shift right b[f] */
      for (i = first; i <= last; i++)
	sim->env.b [i] = (i == last) ? 0 : sim->env.b [i+1];
      sim->env.carry = 0;
      break;
    case 0x15:  /* c + c -> c[f] */
      sim->env.carry = 0;
      for (i = first; i <= last; i++)
	sim->env.c [i] = do_add (sim, sim->env.c [i], sim->env.c [i]);
      break;
    case 0x16:  /* shift right a[f] */
      for (i = first; i <= last; i++)
	sim->env.a [i] = (i == last) ? 0 : sim->env.a [i+1];
      sim->env.carry = 0;
      break;
    case 0x17:  /* 0 -> a[f] */
      for (i = first; i <= last; i++)
	sim->env.a [i] = 0;
      sim->env.carry = 0;
      break;
    case 0x18:  /* a - b -> a[f] */
      sim->env.carry = 0;
      for (i = first; i <= last; i++)
	sim->env.a [i] = do_sub (sim, sim->env.a [i], sim->env.b [i]);
      break;
    case 0x19:  /* a exchange b[f] */
      for (i = first; i <= last; i++)
	{
	  temp = sim->env.a[i];
	  sim->env.a [i] = sim->env.b [i];
	  sim->env.b [i] = temp; 
	}
      sim->env.carry = 0;
      break;
    case 0x1a:  /* a - c -> a[f] */
      sim->env.carry = 0;
      for (i = first; i <= last; i++)
        sim->env.a [i] = do_sub (sim, sim->env.a [i], sim->env.c [i]);
      break;
    case 0x1b:  /* a - 1 -> a[f] */
      sim->env.carry = 1;
      for (i = first; i <= last; i++)
	sim->env.a [i] = do_sub (sim, sim->env.a [i], 0);
      break;
    case 0x1c:  /* a + b -> a[f] */
      sim->env.carry = 0;
      for (i = first; i <= last; i++)
	sim->env.a [i] = do_add (sim, sim->env.a [i], sim->env.b [i]);
      break;
    case 0x1d:  /* a exchange c[f] */
      for (i = first; i <= last; i++)
	{
	  temp = sim->env.a [i];
	  sim->env.a [i] = sim->env.c [i];
	  sim->env.c [i] = temp;
	}
      sim->env.carry = 0;
      break;
    case 0x1e:  /* a + c -> a[f] */
      sim->env.carry = 0;
      for (i = first; i <= last; i++)
	sim->env.a [i] = do_add (sim, sim->env.a [i], sim->env.c [i]);
      break;
    case 0x1f:  /* a + 1 -> a[f] */
      sim->env.carry = 1;
      for (i = first; i <= last; i++)
	sim->env.a [i] = do_add (sim, sim->env.a [i], 0);
      break;
    }
}


static void op_goto (sim_t *sim, int opcode)
{
  if (! sim->env.prev_carry)
    {
      sim->env.pc = opcode >> 2;
      sim->env.rom = sim->env.del_rom;
      sim->env.group = sim->env.del_grp;
    }
}


static void op_jsb (sim_t *sim, int opcode)
{
  sim->env.ret_pc = sim->env.pc;
  sim->env.pc = opcode >> 2;
  sim->env.rom = sim->env.del_rom;
  sim->env.group = sim->env.del_grp;
}


static void op_return (sim_t *sim, int opcode)
{
  sim->env.pc = sim->env.ret_pc;
}


static void op_nop (sim_t *sim, int opcode)
{
}


static void op_dec_p (sim_t *sim, int opcode)
{
  sim->env.p = (sim->env.p - 1) & 0xf;
}


static void op_inc_p (sim_t *sim, int opcode)
{
  sim->env.p = (sim->env.p + 1) & 0xf;
}


static void op_clear_s (sim_t *sim, int opcode)
{
  int i;
  for (i = 0; i < SSIZE; i++)
    sim->env.s [i] = 0;
}


static void op_c_exch_m (sim_t *sim, int opcode)
{
  int i, t;
  for (i = 0; i < WSIZE; i++)
    {
      t = sim->env.c [i];
      sim->env.c [i] = sim->env.m[i];
      sim->env.m [i] = t;
    }
}


static void op_m_to_c (sim_t *sim, int opcode)
{
  int i;
  for (i = 0; i < WSIZE; i++)
    sim->env.c [i] = sim->env.m [i];
}


static void op_c_to_addr (sim_t *sim, int opcode)
{
  if (sim->env.max_ram > 10)
    sim->env.ram_addr = sim->env.c [12] * 10 + sim->env.c [11];
  else
    sim->env.ram_addr = sim->env.c [12];
  if (sim->env.ram_addr >= sim->env.max_ram)
    printf ("c -> ram addr: address %d out of range\n", sim->env.ram_addr);
}


static void op_c_to_data (sim_t *sim, int opcode)
{
  int i;
  if (sim->env.ram_addr >= sim->env.max_ram)
    {
      printf ("c -> data: address %d out of range\n", sim->env.ram_addr);
      return;
    }
  for (i = 0; i < WSIZE; i++)
    sim->env.ram [sim->env.ram_addr] [i] = sim->env.c [i];
}


static void op_data_to_c (sim_t *sim, int opcode)
{
  int i;
  if (sim->env.ram_addr >= sim->env.max_ram)
    {
      printf ("data -> c: address %d out of range, loading 0\n", sim->env.ram_addr);
      for (i = 0; i < WSIZE; i++)
	sim->env.c [i] = 0;
      return;
    }
  for (i = 0; i < WSIZE; i++)
    sim->env.c [i] = sim->env.ram [sim->env.ram_addr] [i];
}


static void op_c_to_stack (sim_t *sim, int opcode)
{
  int i;
  for (i = 0; i < WSIZE; i++)
    {
      sim->env.f [i] = sim->env.e [i];
      sim->env.e [i] = sim->env.d [i];
      sim->env.d [i] = sim->env.c [i];
    }
}


static void op_stack_to_a (sim_t *sim, int opcode)
{
  int i;
  for (i = 0; i < WSIZE; i++)
    {
      sim->env.a [i] = sim->env.d [i];
      sim->env.d [i] = sim->env.e [i];
      sim->env.e [i] = sim->env.f [i];
    }
}


static void op_down_rotate (sim_t *sim, int opcode)
{
  int i, t;
  for (i = 0; i < WSIZE; i++)
    {
      t = sim->env.c [i];
      sim->env.c [i] = sim->env.d [i];
      sim->env.d [i] = sim->env.e [i];
      sim->env.e [i] = sim->env.f [i];
      sim->env.f [i] = t;
    }
}


static void op_clear_reg (sim_t *sim, int opcode)
{
  int i;
  for (i = 0; i < WSIZE; i++)
    sim->env.a [i] = sim->env.b [i] = sim->env.c [i] = sim->env.d [i] =
      sim->env.e [i] = sim->env.f [i] = sim->env.m [i] = 0;
}


static void op_load_constant (sim_t *sim, int opcode)
{
  if (sim->env.p >= WSIZE)
    {
#if 0 /* HP-45 depends on load constant with p > 13 not affecting C */
      printf ("load constant w/ p >= WSIZE at %05o\n", sim->env.prev_pc)
      ;
#endif
    }
  else if ((opcode >> 6) > 9)
    printf ("load constant > 9\n");
  else
    sim->env.c [sim->env.p] = opcode >> 6;
  sim->env.p = (sim->env.p - 1) & 0xf;
}


static void op_set_s (sim_t *sim, int opcode)
{
  if ((opcode >> 6) >= SSIZE)
    printf ("stat >= SSIZE at %05o\n", sim->env.prev_pc);
  else
    sim->env.s [opcode >> 6] = 1;
}


static void op_clr_s (sim_t *sim, int opcode)
{
  if ((opcode >> 6) >= SSIZE)
    printf ("stat >= SSIZE at %05o\n", sim->env.prev_pc);
  else
    sim->env.s [opcode >> 6] = 0;
}


static void op_test_s (sim_t *sim, int opcode)
{
  if ((opcode >> 6) >= SSIZE)
    printf ("stat >= SSIZE at %05o\n", sim->env.prev_pc);
  else
    sim->env.carry = sim->env.s [opcode >> 6];
}


static void op_set_p (sim_t *sim, int opcode)
{
  sim->env.p = opcode >> 6;
}


static void op_test_p (sim_t *sim, int opcode)
{
  sim->env.carry = (sim->env.p == (opcode >> 6));
}


static void op_sel_rom (sim_t *sim, int opcode)
{
  sim->env.rom = opcode >> 7;
  sim->env.group = sim->env.del_grp;

  sim->env.del_rom = sim->env.rom;
}


static void op_del_sel_rom (sim_t *sim, int opcode)
{
  sim->env.del_rom = opcode >> 7;
}


static void op_del_sel_grp (sim_t *sim, int opcode)
{
  sim->env.del_grp = (opcode >> 7) & 1;
}


static void op_keys_to_rom_addr (sim_t *sim, int opcode)
{
  if (sim->env.key_buf < 0)
    {
      printf ("keys->rom address with no key pressed\n");
      sim->env.pc = 0;
      return;
    }
  sim->env.pc = sim->env.key_buf;
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
  sim->env.display_enable = 0;
  sim->env.io_count = 2;
  /*
   * Don't immediately turn off display because the very next instruction
   * might be a display_toggle to turn it on.  This happens in the HP-45
   * stopwatch.
   */
}


static void op_display_toggle (sim_t *sim, int opcode)
{
  sim->env.display_enable = ! sim->env.display_enable;
  sim->env.io_count = 0;  /* force immediate display update */
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


void disassemble_instruction (sim_t *sim, int g, int r, int p, int opcode)
{
  int i;
  printf ("L%1o%1o%3o:  ", g, r, p);
  for (i = 0x200; i; i >>= 1)
    printf ((opcode & i) ? "1" : ".");
}


/*
 * set breakpoints at every location so we know if we hit
 * uninitialized ROM
 */
void init_breakpoints (sim_t *sim)
{
  int g, r, p;

  for (g = 0; g < MAX_GROUP; g++)
    for (r = 0; r < MAX_ROM; r++)
      for (p = 0; p < ROM_SIZE; p++)
	sim->bpt [g] [r] [p] = 1;
}


void init_source (sim_t *sim)
{
  int g, r, p;

  for (g = 0; g < MAX_GROUP; g++)
    for (r = 0; r < MAX_ROM; r++)
      for (p = 0; p < ROM_SIZE; p++)
	sim->source [g] [r] [p] = NULL;
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


gboolean sim_read_object_file (sim_t *sim, char *fn)
{
  int i;
  FILE *f;
  int g, r, p, opcode;
  int count = 0;
  char buf [80];

  f = fopen (fn, "r");
  if (! f)
    {
      fprintf (stderr, "error opening listing file\n");
      return (FALSE);
    }

  while (fgets (buf, sizeof (buf), f))
    {
      i = sscanf (buf, "%1o%1o%3o:%3x", & g, & r, & p, & opcode);
      if (i != 4)
	fprintf (stderr, "only converted %d items\n", i);
      else if ((g >= MAX_GROUP) || (r >= MAX_ROM) || (p >= ROM_SIZE))
	fprintf (stderr, "bad address\n");
      else
	{
	  sim->ucode [g][r][p] = opcode;
	  sim->bpt   [g][r][p] = 0;
	  count ++;
	}
    }
  fprintf (stderr, "read %d words from '%s'\n", count, fn);
  return (TRUE);
}


gboolean sim_read_listing_file (sim_t *sim, char *fn, int keep_src)
{
  FILE *f;
  int g, r, p, opcode;
  int count = 0;
  char buf [80];

  f = fopen (fn, "r");
  if (! f)
    {
      fprintf (stderr, "error opening listing file\n");
      return (FALSE);
    }

  while (fgets (buf, sizeof (buf), f))
    {
      trim_trailing_whitespace (buf);
      if ((strlen (buf) >= 25) && (buf [7] == 'L') && (buf [13] == ':') &&
	  parse_address (& buf [8], & g, &r, &p) &&
	  parse_opcode (& buf [16], & opcode))
	{
	  if ((g >= MAX_GROUP) || (r >= MAX_ROM) || (p >= ROM_SIZE))
	    fprintf (stderr, "bad address\n");
	  else if (! sim->bpt [g][r][p])
	    {
	      fprintf (stderr, "duplicate listing line for address %1o%1o%03o\n",
		       g, r, p);
	      fprintf (stderr, "orig: %s\n", sim->source [g][r][p]);
	      fprintf (stderr, "dup:  %s\n", buf);
	    }
	  else
	    {
	      sim->ucode  [g][r][p] = opcode;
	      sim->bpt    [g][r][p] = 0;
	      if (keep_src)
		sim->source [g][r][p] = newstr (& buf [0]);
	      count ++;
	    }
	}
    }
#if 0
  fprintf (stderr, "read %d words from '%s'\n", count, fn);
#endif
  return (TRUE);
}


static void handle_io (sim_t *sim)
{
  char buf [WSIZE + 2];
  char *bp;
  int i;

  bp = & buf [0];
  if (sim->env.display_enable)
    {
      for (i = WSIZE - 1; i >= 0; i--)
	{
	  if (sim->env.b [i] >= 8)
	    *bp++ = ' ';
	  else if ((i == 2) || (i == 13))
	    {
	      if (sim->env.a [i] >= 8)
		*bp++ = '-';
	      else
		*bp++ = ' ';
	    }
	  else
	    *bp++ = '0' + sim->env.a [i];
	  if (sim->env.b [i] == 2)
	    *bp++ = '.';
	}
    }
  *bp = '\0';
  if (strcmp (buf, sim->prev_display) != 0)
    {
      sim->display_update (buf);
      strncpy (sim->prev_display, buf, sizeof (buf));
    }
}


void execute_instruction (sim_t *sim)
{
  int i;
  int opcode;

  sim->env.prev_pc = (sim->env.group << 12) | (sim->env.rom << 9) | sim->env.pc;
  opcode = sim->ucode [sim->env.group] [sim->env.rom] [sim->env.pc];

#if 0
  printf ("%s\n", sim->source [sim->env.group] [sim->env.rom] [sim->env.pc]);
#endif

  sim->env.prev_carry = sim->env.carry;
  sim->env.carry = 0;

  if (sim->env.key_flag)
    sim->env.s [0] = 1;
  for (i = 0; i < SSIZE; i++)
    if (sim->env.ext_flag [i])
      sim->env.s [i] = 1;

  sim->env.pc++;
  (* sim->op_fcn [opcode]) (sim, opcode);
  sim->cycle_count++;
}


void reset_processor (sim_t *sim)
{
  sim->cycle_count = 0;

  sim->env.pc = 0;
  sim->env.rom = 0;
  sim->env.group = 0;
  sim->env.del_rom = 0;
  sim->env.del_grp = 0;

  op_clear_reg (sim, 0);
  op_clear_s (sim, 0);
  sim->env.p = 0;

  sim->env.display_enable = 0;
  sim->env.key_flag = 0;
}


/* The real hardware executes a fixed number of microinstructions per
   second.  The HP-55 uses a crystal, but the other models use an LC
   oscillator that is not adjusted.  We try to run at nominally the
   same rate. */
#define UINST_PER_SEC 3500

/* we try to schedule execution in "jiffies": */
#define JIFFY_PER_SEC 30

#define UINST_USEC (1.0e6 / UINST_PER_SEC)
#define JIFFY_USEC (1.0e6 / JIFFY_PER_SEC)


gpointer sim_thread_func (gpointer data)
{
  int i;
  long usec;

  sim_t *sim = (sim_t *) data;

  for (;;)
    {
      g_mutex_lock (sim->sim_mutex);
      if (sim->state != sim->prev_state)
	{
	  if (sim->state == SIM_RUN)
	    g_get_current_time (& sim->prev_tv);
	}
      sim->prev_state = sim->state;
      switch (sim->state)
	{
	case SIM_QUIT:
	  g_mutex_unlock (sim->sim_mutex);
	  g_thread_exit (0);

	case SIM_RESET:
	  reset_processor (sim);
	  sim->state = SIM_IDLE;
	  g_cond_signal (sim->ui_cond);
	  g_cond_wait (sim->sim_cond, sim->sim_mutex);
	  break;

	case SIM_IDLE:
	  g_cond_wait (sim->sim_cond, sim->sim_mutex);
	  break;

	case SIM_STEP:
	  execute_instruction (sim);
	  handle_io (sim);
	  sim->state = SIM_IDLE;
	  g_cond_signal (sim->ui_cond);
	  g_cond_wait (sim->sim_cond, sim->sim_mutex);
	  break;

	case SIM_RUN:
	  /* find out how much time has elapsed, saturated at one second */
	  g_get_current_time (& sim->tv);

	  /* compute how many microinstructions we want to execute */
	  usec = sim->tv.tv_usec - sim->prev_tv.tv_usec;
	  switch (sim->tv.tv_sec - sim->prev_tv.tv_sec)
	    {
	    case 0: break;
	    case 1: usec += 1000000; break;
	    default: usec = 1000000;
	    }
	  i = usec / UINST_USEC;
#if 0
	  printf ("tv %d.%06d, usec %d, i %d\n", sim->tv.tv_sec, sim->tv.tv_usec, usec, i);
#endif

	  /* execute the microinstructions */
	  while (i--)
	    {
	      execute_instruction (sim);
	    }

	  /* update the display */
	  handle_io (sim);

	  /* remember when we ran */
	  memcpy (& sim->prev_tv, & sim->tv, sizeof (GTimeVal));

	  /* sleep a while */
	  g_time_val_add (& sim->tv, JIFFY_USEC);
	  g_cond_timed_wait (sim->sim_cond, sim->sim_mutex, & sim->tv);
	  break;

	default:
	  fatal (2, "bad simulator state\n");
	}
      g_mutex_unlock (sim->sim_mutex);
    }

  return (NULL);  /* $$$ Hmmm... what are we supposed to return? */
}


/* The following functions can be called from the main thread: */

sim_t *sim_init (int ram_size,
		 void (*display_update_fn)(char *buf))
{
  sim_t *sim;

  sim = alloc (sizeof (sim_t));
  sim->prev_state = SIM_UNKNOWN;
  sim->state = SIM_IDLE;

  g_thread_init (NULL);  /* $$$ has Gtk already done this? */

  sim->sim_cond = g_cond_new ();
  sim->ui_cond = g_cond_new ();
  sim->sim_mutex = g_mutex_new ();

  g_mutex_lock (sim->sim_mutex);

  init_ops (sim);
  init_breakpoints (sim);
  init_source (sim);

  sim->env.max_ram = ram_size;
  sim->env.ram = alloc (ram_size * sizeof (reg_t));

  sim->display_update = display_update_fn;

  sim->state = SIM_IDLE;

  sim->env.key_buf = -1;  /* no key has been pressed */

  sim->cycle_count = 0;

  sim->thread = g_thread_create (sim_thread_func, sim, TRUE, NULL);

  g_mutex_unlock (sim->sim_mutex);

  return (sim);
}


void sim_quit (sim_t *sim)
{
  g_mutex_lock (sim->sim_mutex);
  sim->state = SIM_QUIT;

  g_thread_join (sim->thread);

  free (sim);
}


void sim_reset (sim_t *sim)
{
  g_mutex_lock (sim->sim_mutex);
  if (sim->state != SIM_IDLE)
    fatal (2, "can't reset when not idle\n");
  sim->state = SIM_RESET;
  g_cond_signal (sim->sim_cond);
  while (sim->state != SIM_IDLE)
    g_cond_wait (sim->ui_cond, sim->sim_mutex);
  g_mutex_unlock (sim->sim_mutex);
}


void sim_step (sim_t *sim)
{
  g_mutex_lock (sim->sim_mutex);
  if (sim->state != SIM_IDLE)
    fatal (2, "can't step when not idle\n");
  sim->state = SIM_STEP;
  g_cond_signal (sim->sim_cond);
  while (sim->state != SIM_IDLE)
    g_cond_wait (sim->ui_cond, sim->sim_mutex);
  g_mutex_unlock (sim->sim_mutex);
}


void sim_start (sim_t *sim)
{
  g_mutex_lock (sim->sim_mutex);
  if (sim->state != SIM_IDLE)
    fatal (2, "can't start when not idle\n");
  sim->state = SIM_RUN;
  g_cond_signal (sim->sim_cond);
  g_mutex_unlock (sim->sim_mutex);
}


void sim_stop (sim_t *sim)
{
  g_mutex_lock (sim->sim_mutex);
  if (sim->state == SIM_IDLE)
    goto done;
  if (sim->state != SIM_RUN)
    fatal (2, "can't stop when not running\n");
  sim->state = SIM_IDLE;
  g_cond_signal (sim->sim_cond);
done:
  g_mutex_unlock (sim->sim_mutex);
}


uint64_t sim_get_cycle_count (sim_t *sim)
{
  uint64_t count;
  g_mutex_lock (sim->sim_mutex);
  count = sim->cycle_count;
  g_mutex_unlock (sim->sim_mutex);
  return (count);
}


void sim_set_cycle_count (sim_t *sim, uint64_t count)
{
  g_mutex_lock (sim->sim_mutex);
  sim->cycle_count = count;
  g_mutex_unlock (sim->sim_mutex);
}


void sim_set_breakpoint (sim_t *sim, int address)
{
  /* $$$ not yet implemented */
}


void sim_clear_breakpoint (sim_t *sim, int address)
{
  /* $$$ not yet implemented */
}


gboolean sim_running (sim_t *sim)
{
  gboolean result;
  g_mutex_lock (sim->sim_mutex);
  result = (sim->state == SIM_RUN);
  g_mutex_unlock (sim->sim_mutex);
  return (result);
}


void sim_get_env (sim_t *sim, sim_env_t *env)
{
  size_t ram_bytes;
  reg_t *ram;

  g_mutex_lock (sim->sim_mutex);

  /* Copy everything but the RAM pointer, we have to copy the RAM
     separately. */
  ram = env->ram;
  memcpy (env, & sim->env, sizeof (sim_env_t));
  env->ram = ram;

  /* now copy the RAM */
  ram_bytes = sim->env.max_ram * sizeof (reg_t);

  env->ram = realloc (env->ram, ram_bytes);
  if (! env->ram)
    fatal (2, "can't realloc ram\n");

  memcpy (env->ram, sim->env.ram, ram_bytes);

  g_mutex_unlock (sim->sim_mutex);
}


void sim_set_env (sim_t *sim, sim_env_t *env)
{
  reg_t *sim_ram;

  g_mutex_lock (sim->sim_mutex);

  /* Copy everything but the RAM pointer, we have to copy the RAM
     separately. */
  sim_ram = sim->env.ram;
  memcpy (& sim->env, env, sizeof (sim_env_t));
  sim->env.ram = sim_ram;

  /* now copy the RAM */
  memcpy (sim->env.ram, env->ram, sim->env.max_ram * sizeof (reg_t));

  g_mutex_unlock (sim->sim_mutex);
}


romword sim_read_rom (sim_t *sim, int addr)
{
  /* The ROM is read-only, so we don't have to grab the mutex. */
  /* $$$ not yet implemented */
  return (0);
}


void sim_read_ram (sim_t *sim, int addr, reg_t *val)
{
  if (addr > sim->env.max_ram)
    fatal (2, "sim_read_ram: address %d out of range\n", addr);
  g_mutex_lock (sim->sim_mutex);
  memcpy (val, & sim->env.ram [addr], sizeof (reg_t));
  g_mutex_unlock (sim->sim_mutex);
}


void sim_write_ram (sim_t *sim, int addr, reg_t *val)
{
  if (addr > sim->env.max_ram)
    fatal (2, "sim_write_ram: address %d out of range\n", addr);
  g_mutex_lock (sim->sim_mutex);
  memcpy (& sim->env.ram [addr], val, sizeof (reg_t));
  g_mutex_unlock (sim->sim_mutex);
}


void sim_press_key (sim_t *sim, int keycode)
{
  g_mutex_lock (sim->sim_mutex);
  sim->env.key_buf = keycode;
  sim->env.key_flag = TRUE;
  g_mutex_unlock (sim->sim_mutex);
}


void sim_release_key (sim_t *sim)
{
  g_mutex_lock (sim->sim_mutex);
  sim->env.key_flag = FALSE;
  g_mutex_unlock (sim->sim_mutex);
}


void sim_set_ext_flag (sim_t *sim, int flag, gboolean state)
{
  g_mutex_lock (sim->sim_mutex);
  sim->env.ext_flag [flag] = state;
  g_mutex_unlock (sim->sim_mutex);
}
