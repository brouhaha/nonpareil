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
#include <string.h>

#include <glib.h>

#include "proc.h"
#include "util.h"


sim_state_t sim_state = SIM_IDLE;


sim_env_t sim_env;


void (*display_update)(char *buf);


uint64_t cycle_count;


#define MAX_GROUP 2
#define MAX_ROM 8
#define ROM_SIZE 256


romword ucode [MAX_GROUP] [MAX_ROM] [ROM_SIZE];
uint8_t bpt     [MAX_GROUP] [MAX_ROM] [ROM_SIZE];
char *source  [MAX_GROUP] [MAX_ROM] [ROM_SIZE];


static void bad_op (int opcode)
{
  printf ("illegal opcode %02x at %05o\n", opcode, sim_env.prev_pc);
}


static digit_t do_add (digit_t x, digit_t y)
{
  int res;

  res = x + y + sim_env.carry;
  if (res > 9)
    {
      res -= 10;
      sim_env.carry = 1;
    }
  else
    sim_env.carry = 0;
  return (res);
}


static digit_t do_sub (digit_t x, digit_t y)
{
  int res;

  res = (x - y) - sim_env.carry;
  if (res < 0)
    {
      res += 10;
      sim_env.carry = 1;
    }
  else
    sim_env.carry = 0;
  return (res);
}


static void op_arith (int opcode)
{
  uint8_t op, field;
  int first, last;
  int temp;
  int i;
  reg_t t;

  op = opcode >> 5;
  field = (opcode >> 2) & 7;

  switch (field)
    {
    case 0:  /* p  */
      first =  sim_env.p; last =  sim_env.p;
      if (sim_env.p >= WSIZE)
	{
	  printf ("Warning! p > WSIZE at %05o\n", sim_env.prev_pc);
	  last = 0;  /* don't do anything */
	}
      break;
    case 1:  /* m  */  first =  3; last = 12; break;
    case 2:  /* x  */  first =  0; last =  2; break;
    case 3:  /* w  */  first =  0; last = 13; break;
    case 4:  /* wp */
      first =  0; last =  sim_env.p; break;
      if (sim_env.p > 13)
	{
	  printf ("Warning! p >= WSIZE at %05o\n", sim_env.prev_pc);
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
	sim_env.carry |= (sim_env.b [i] != 0);
      break;
    case 0x01:  /* 0 -> b[f] */
      for (i = first; i <= last; i++)
	sim_env.b [i] = 0;
      sim_env.carry = 0;
      break;
    case 0x02:  /* if a >= c[f] */
      sim_env.carry = 0;
      for (i = first; i <= last; i++)
	t [i] = do_sub (sim_env.a [i], sim_env.c [i]);
      break;
    case 0x03:  /* if c[f] >= 1 */
      sim_env.carry = 1;
      for (i = first; i <= last; i++)
	sim_env.carry &= (sim_env.c [i] == 0);
      break;
    case 0x04:  /* b -> c[f] */
      for (i = first; i <= last; i++)
	sim_env.c [i] = sim_env.b [i];
      sim_env.carry = 0;
      break;
    case 0x05:  /* 0 - c -> c[f] */
      sim_env.carry = 0;
      for (i = first; i <= last; i++)
	sim_env.c [i] = do_sub (0, sim_env.c [i]);
      break;
    case 0x06:  /* 0 -> c[f] */
      for (i = first; i <= last; i++)
	sim_env.c [i] = 0;
      sim_env.carry = 0;
      break;
    case 0x07:  /* 0 - c - 1 -> c[f] */
      sim_env.carry = 1;
      for (i = first; i <= last; i++)
	sim_env.c [i] = do_sub (0, sim_env.c [i]);
      break;
    case 0x08:  /* shift left a[f] */
      for (i = last; i >= first; i--)
	sim_env.a [i] = (i == first) ? 0 : sim_env.a [i-1];
      sim_env.carry = 0;
      break;
    case 0x09:  /* a -> b[f] */
      for (i = first; i <= last; i++)
	sim_env.b [i] = sim_env.a [i];
      sim_env.carry = 0;
      break;
    case 0x0a:  /* a - c -> c[f] */
      sim_env.carry = 0;
      for (i = first; i <= last; i++)
	sim_env.c [i] = do_sub (sim_env.a [i], sim_env.c [i]);
      break;
    case 0x0b:  /* c - 1 -> c[f] */
      sim_env.carry = 1;
      for (i = first; i <= last; i++)
	sim_env.c [i] = do_sub (sim_env.c [i], 0);
      break;
    case 0x0c:  /* c -> a[f] */
      for (i = first; i <= last; i++)
	sim_env.a [i] = sim_env.c [i];
      sim_env.carry = 0;
      break;
    case 0x0d:  /* if c[f] = 0 */
      for (i = first; i <= last; i++)
	sim_env.carry |= (sim_env.c [i] != 0);
      break;
    case 0x0e:  /* a + c -> c[f] */
      sim_env.carry = 0;
      for (i = first; i <= last; i++)
	sim_env.c [i] = do_add (sim_env.a [i], sim_env.c [i]);
      break;
    case 0x0f:  /* c + 1 -> c[f] */
      sim_env.carry = 1;
      for (i = first; i <= last; i++)
	sim_env.c [i] = do_add (sim_env.c [i], 0);
      break;
    case 0x10:  /* if a >= b[f] */
      sim_env.carry = 0;
      for (i = first; i <= last; i++)
	t [i] = do_sub (sim_env.a [i], sim_env.b [i]);
      break;
    case 0x11:  /* b exchange c[f] */
      for (i = first; i <= last; i++)
	{
	  temp = sim_env.b[i];
	  sim_env.b [i] = sim_env.c [i];
	  sim_env.c [i] = temp;
	}
      sim_env.carry = 0;
      break;
    case 0x12:  /* shift right c[f] */
      for (i = first; i <= last; i++)
	sim_env.c [i] = (i == last) ? 0 : sim_env.c [i+1];
      sim_env.carry = 0;
      break;
    case 0x13:  /* if a[f] >= 1 */
      sim_env.carry = 1;
      for (i = first; i <= last; i++)
	sim_env.carry &= (sim_env.a [i] == 0);
      break;
    case 0x14:  /* shift right b[f] */
      for (i = first; i <= last; i++)
	sim_env.b [i] = (i == last) ? 0 : sim_env.b [i+1];
      sim_env.carry = 0;
      break;
    case 0x15:  /* c + c -> c[f] */
      sim_env.carry = 0;
      for (i = first; i <= last; i++)
	sim_env.c [i] = do_add (sim_env.c [i], sim_env.c [i]);
      break;
    case 0x16:  /* shift right a[f] */
      for (i = first; i <= last; i++)
	sim_env.a [i] = (i == last) ? 0 : sim_env.a [i+1];
      sim_env.carry = 0;
      break;
    case 0x17:  /* 0 -> a[f] */
      for (i = first; i <= last; i++)
	sim_env.a [i] = 0;
      sim_env.carry = 0;
      break;
    case 0x18:  /* a - b -> a[f] */
      sim_env.carry = 0;
      for (i = first; i <= last; i++)
	sim_env.a [i] = do_sub (sim_env.a [i], sim_env.b [i]);
      break;
    case 0x19:  /* a exchange b[f] */
      for (i = first; i <= last; i++)
	{
	  temp = sim_env.a[i];
	  sim_env.a [i] = sim_env.b [i];
	  sim_env.b [i] = temp; 
	}
      sim_env.carry = 0;
      break;
    case 0x1a:  /* a - c -> a[f] */
      sim_env.carry = 0;
      for (i = first; i <= last; i++)
        sim_env.a [i] = do_sub (sim_env.a [i], sim_env.c [i]);
      break;
    case 0x1b:  /* a - 1 -> a[f] */
      sim_env.carry = 1;
      for (i = first; i <= last; i++)
	sim_env.a [i] = do_sub (sim_env.a [i], 0);
      break;
    case 0x1c:  /* a + b -> a[f] */
      sim_env.carry = 0;
      for (i = first; i <= last; i++)
	sim_env.a [i] = do_add (sim_env.a [i], sim_env.b [i]);
      break;
    case 0x1d:  /* a exchange c[f] */
      for (i = first; i <= last; i++)
	{
	  temp = sim_env.a [i];
	  sim_env.a [i] = sim_env.c [i];
	  sim_env.c [i] = temp;
	}
      sim_env.carry = 0;
      break;
    case 0x1e:  /* a + c -> a[f] */
      sim_env.carry = 0;
      for (i = first; i <= last; i++)
	sim_env.a [i] = do_add (sim_env.a [i], sim_env.c [i]);
      break;
    case 0x1f:  /* a + 1 -> a[f] */
      sim_env.carry = 1;
      for (i = first; i <= last; i++)
	sim_env.a [i] = do_add (sim_env.a [i], 0);
      break;
    }
}


static void op_goto (int opcode)
{
  if (! sim_env.prev_carry)
    {
      sim_env.pc = opcode >> 2;
      sim_env.rom = sim_env.del_rom;
      sim_env.group = sim_env.del_grp;
    }
}


static void op_jsb (int opcode)
{
  sim_env.ret_pc = sim_env.pc;
  sim_env.pc = opcode >> 2;
  sim_env.rom = sim_env.del_rom;
  sim_env.group = sim_env.del_grp;
}


static void op_return (int opcode)
{
  sim_env.pc = sim_env.ret_pc;
}


static void op_nop (int opcode)
{
}


static void op_dec_p (int opcode)
{
  sim_env.p = (sim_env.p - 1) & 0xf;
}


static void op_inc_p (int opcode)
{
  sim_env.p = (sim_env.p + 1) & 0xf;
}


static void op_clear_s (int opcode)
{
  int i;
  for (i = 0; i < SSIZE; i++)
    sim_env.s [i] = 0;
}


static void op_c_exch_m (int opcode)
{
  int i, t;
  for (i = 0; i < WSIZE; i++)
    {
      t = sim_env.c [i];
      sim_env.c [i] = sim_env.m[i];
      sim_env.m [i] = t;
    }
}


static void op_m_to_c (int opcode)
{
  int i;
  for (i = 0; i < WSIZE; i++)
    sim_env.c [i] = sim_env.m [i];
}


static void op_c_to_addr (int opcode)
{
  if (sim_env.max_ram > 10)
    sim_env.ram_addr = sim_env.c [12] * 10 + sim_env.c [11];
  else
    sim_env.ram_addr = sim_env.c [12];
  if (sim_env.ram_addr >= sim_env.max_ram)
    printf ("c -> ram addr: address %d out of range\n", sim_env.ram_addr);
}


static void op_c_to_data (int opcode)
{
  int i;
  if (sim_env.ram_addr >= sim_env.max_ram)
    {
      printf ("c -> data: address %d out of range\n", sim_env.ram_addr);
      return;
    }
  for (i = 0; i < WSIZE; i++)
    sim_env.ram [sim_env.ram_addr] [i] = sim_env.c [i];
}


static void op_data_to_c (int opcode)
{
  int i;
  if (sim_env.ram_addr >= sim_env.max_ram)
    {
      printf ("data -> c: address %d out of range, loading 0\n", sim_env.ram_addr);
      for (i = 0; i < WSIZE; i++)
	sim_env.c [i] = 0;
      return;
    }
  for (i = 0; i < WSIZE; i++)
    sim_env.c [i] = sim_env.ram [sim_env.ram_addr] [i];
}


static void op_c_to_stack (int opcode)
{
  int i;
  for (i = 0; i < WSIZE; i++)
    {
      sim_env.f [i] = sim_env.e [i];
      sim_env.e [i] = sim_env.d [i];
      sim_env.d [i] = sim_env.c [i];
    }
}


static void op_stack_to_a (int opcode)
{
  int i;
  for (i = 0; i < WSIZE; i++)
    {
      sim_env.a [i] = sim_env.d [i];
      sim_env.d [i] = sim_env.e [i];
      sim_env.e [i] = sim_env.f [i];
    }
}


static void op_down_rotate (int opcode)
{
  int i, t;
  for (i = 0; i < WSIZE; i++)
    {
      t = sim_env.c [i];
      sim_env.c [i] = sim_env.d [i];
      sim_env.d [i] = sim_env.e [i];
      sim_env.e [i] = sim_env.f [i];
      sim_env.f [i] = t;
    }
}


static void op_clear_reg (int opcode)
{
  int i;
  for (i = 0; i < WSIZE; i++)
    sim_env.a [i] = sim_env.b [i] = sim_env.c [i] = sim_env.d [i] =
      sim_env.e [i] = sim_env.f [i] = sim_env.m [i] = 0;
}


static void op_load_constant (int opcode)
{
  if (sim_env.p >= WSIZE)
    {
#if 0 /* HP-45 depends on load constant with p > 13 not affecting C */
      printf ("load constant w/ p >= WSIZE at %05o\n", sim_env.prev_pc)
      ;
#endif
    }
  else if ((opcode >> 6) > 9)
    printf ("load constant > 9\n");
  else
    sim_env.c [sim_env.p] = opcode >> 6;
  sim_env.p = (sim_env.p - 1) & 0xf;
}


static void op_set_s (int opcode)
{
  if ((opcode >> 6) >= SSIZE)
    printf ("stat >= SSIZE at %05o\n", sim_env.prev_pc);
  else
    sim_env.s [opcode >> 6] = 1;
}


static void op_clr_s (int opcode)
{
  if ((opcode >> 6) >= SSIZE)
    printf ("stat >= SSIZE at %05o\n", sim_env.prev_pc);
  else
    sim_env.s [opcode >> 6] = 0;
}


static void op_test_s (int opcode)
{
  if ((opcode >> 6) >= SSIZE)
    printf ("stat >= SSIZE at %05o\n", sim_env.prev_pc);
  else
    sim_env.carry = sim_env.s [opcode >> 6];
}


static void op_set_p (int opcode)
{
  sim_env.p = opcode >> 6;
}


static void op_test_p (int opcode)
{
  sim_env.carry = (sim_env.p == (opcode >> 6));
}


static void op_sel_rom (int opcode)
{
  sim_env.rom = opcode >> 7;
  sim_env.group = sim_env.del_grp;

  sim_env.del_rom = sim_env.rom;
}


static void op_del_sel_rom (int opcode)
{
  sim_env.del_rom = opcode >> 7;
}


static void op_del_sel_grp (int opcode)
{
  sim_env.del_grp = (opcode >> 7) & 1;
}


static void op_keys_to_rom_addr (int opcode)
{
  if (sim_env.key_buf < 0)
    {
      printf ("keys->rom address with no key pressed\n");
      sim_env.pc = 0;
      return;
    }
  sim_env.pc = sim_env.key_buf;
}


static void op_rom_addr_to_buf (int opcode)
{
  /* I don't know what this instruction is supposed to do! */
#if 0
  fprintf (stderr, "rom addr to buf!!!!!!!!!!!!\n");
#endif
}


static void op_display_off (int opcode)
{
  sim_env.display_enable = 0;
  sim_env.io_count = 2;
  /*
   * Don't immediately turn off display because the very next instruction
   * might be a display_toggle to turn it on.  This happens in the HP-45
   * stopwatch.
   */
}


static void op_display_toggle (int opcode)
{
  sim_env.display_enable = ! sim_env.display_enable;
  sim_env.io_count = 0;  /* force immediate display update */
}


static void (* op_fcn [1024])(int);


static void init_ops (void)
{
  int i, j;

  for (i = 0; i < 1024; i += 4)
    {
      op_fcn [i + 0] = bad_op;
      op_fcn [i + 1] = op_jsb;    /* type 1: aaaaaaaa01 */
      op_fcn [i + 2] = op_arith;  /* type 2: ooooowww10 */
      op_fcn [i + 3] = op_goto;   /* type 1: aaaaaaaa11 */
    }

  /* type 3 instructions: nnnnff0100*/
  for (i = 0; i <= 15; i ++)
    {
      op_fcn [0x004 + (i << 6)] = op_set_s;
      op_fcn [0x014 + (i << 6)] = op_test_s;
      op_fcn [0x024 + (i << 6)] = op_clr_s;
      op_fcn [0x034 /* + (i << 6) */ ] = op_clear_s;
    }

  /* New instructions in HP-55 and maybe HP-65, wedged into the unused
     port of the type 3 instruction space.  On the HP-35 and HP-80 these
     probably cleared all status like 0x034. */
  for (i = 0; i <= 7; i ++)
    {
      op_fcn [0x074 + (i << 7)] = op_del_sel_rom;
    }
  op_fcn [0x234] = op_del_sel_grp;
  op_fcn [0x2b4] = op_del_sel_grp;

  /* type 4 instructions: ppppff1100 */
  for (i = 0; i <= 15; i ++)
    {
      op_fcn [0x00c + (i << 6)] = op_set_p;
      op_fcn [0x02c + (i << 6)] = op_test_p;
      op_fcn [0x01c /* + (i << 6) */ ] = op_dec_p;
      op_fcn [0x03c /* + (i << 6) */ ] = op_inc_p;
    }

  /* type 5 instructions: nnnnff1000 */
  for (i = 0; i <= 9; i++)
      op_fcn [0x018 + (i << 6)] = op_load_constant;
  for (i = 0; i <= 1; i++)
    {
      op_fcn [0x028 /* + (i << 4) */ ] = op_display_toggle;
      op_fcn [0x0a8 /* + (i << 4) */ ] = op_c_exch_m;
      op_fcn [0x128 /* + (i << 4) */ ] = op_c_to_stack;
      op_fcn [0x1a8 /* + (i << 4) */ ] = op_stack_to_a;
      op_fcn [0x228 /* + (i << 4) */ ] = op_display_off;
      op_fcn [0x2a8 /* + (i << 4) */ ] = op_m_to_c;
      op_fcn [0x328 /* + (i << 4) */ ] = op_down_rotate;
      op_fcn [0x3a8 /* + (i << 4) */ ] = op_clear_reg;
      for (j = 0; j <= 3; j++)
	{
#if 0
	  op_fcn [0x068 + (j << 8) + (i << 4)] = op_is_to_a;
#endif
	  op_fcn [0x0e8 + (j << 8) + (i << 4)] = op_data_to_c;
	  /* BCD->C is nominally 0x2f8 */
	}
    }

  /* type 6 instructions: nnnff10000 */
  for (i = 0; i <= 7; i++)
    {
      op_fcn [0x010 + (i << 7)] = op_sel_rom;
      op_fcn [0x030 /* + (i << 7) */ ] = op_return;
      if (i & 1)
	op_fcn [0x050 + 0x080 /* + (i << 7) */ ] = op_keys_to_rom_addr;
#if 0
      else
	op_fcn [0x050 /* + (i << 7) */ ] = op_external_entry;
#endif
    }
  op_fcn [0x270] = op_c_to_addr;  /* also 0x370 */
  op_fcn [0x2f0] = op_c_to_data;

  /* no type 7 or type 8 instructions: xxxx100000, xxx1000000 */

  /* type 9 and 10 instructions: xxx0000000 */
  op_fcn [0x200] = op_rom_addr_to_buf;
  op_fcn [0x000] = op_nop;
}


void disassemble_instruction (int g, int r, int p, int opcode)
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
void init_breakpoints (void)
{
  int g, r, p;

  for (g = 0; g < MAX_GROUP; g++)
    for (r = 0; r < MAX_ROM; r++)
      for (p = 0; p < ROM_SIZE; p++)
	bpt [g] [r] [p] = 1;
}


void init_source (void)
{
  int g, r, p;

  for (g = 0; g < MAX_GROUP; g++)
    for (r = 0; r < MAX_ROM; r++)
      for (p = 0; p < ROM_SIZE; p++)
	source [g] [r] [p] = NULL;
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


gboolean sim_read_object_file (char *fn)
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
	  ucode [g][r][p] = opcode;
	  bpt   [g][r][p] = 0;
	  count ++;
	}
    }
  fprintf (stderr, "read %d words from '%s'\n", count, fn);
  return (TRUE);
}


gboolean sim_read_listing_file (char *fn, int keep_src)
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
	  else if (! bpt [g][r][p])
	    {
	      fprintf (stderr, "duplicate listing line for address %1o%1o%03o\n",
		       g, r, p);
	      fprintf (stderr, "orig: %s\n", source [g][r][p]);
	      fprintf (stderr, "dup:  %s\n", buf);
	    }
	  else
	    {
	      ucode  [g][r][p] = opcode;
	      bpt    [g][r][p] = 0;
	      if (keep_src)
		source [g][r][p] = newstr (& buf [0]);
	      count ++;
	    }
	}
    }
#if 0
  fprintf (stderr, "read %d words from '%s'\n", count, fn);
#endif
  return (TRUE);
}


char prev_buf [WSIZE + 2];

static void handle_io (void)
{
  char buf [WSIZE + 2];
  char *bp;
  int i;

  bp = & buf [0];
  if (sim_env.display_enable)
    {
      for (i = WSIZE - 1; i >= 0; i--)
	{
	  if (sim_env.b [i] >= 8)
	    *bp++ = ' ';
	  else if ((i == 2) || (i == 13))
	    {
	      if (sim_env.a [i] >= 8)
		*bp++ = '-';
	      else
		*bp++ = ' ';
	    }
	  else
	    *bp++ = '0' + sim_env.a [i];
	  if (sim_env.b [i] == 2)
	    *bp++ = '.';
	}
    }
  *bp = '\0';
  if (strcmp (buf, prev_buf) != 0)
    {
      display_update (buf);
      strncpy (prev_buf, buf, sizeof (buf));
    }
}


void execute_instruction (void)
{
  int i;
  int opcode;

  sim_env.prev_pc = (sim_env.group << 12) | (sim_env.rom << 9) | sim_env.pc;
  opcode = ucode [sim_env.group] [sim_env.rom] [sim_env.pc];

#if 0
  printf ("%s\n", source [sim_env.group] [sim_env.rom] [sim_env.pc]);
#endif

  sim_env.prev_carry = sim_env.carry;
  sim_env.carry = 0;

  if (sim_env.key_flag)
    sim_env.s [0] = 1;
  for (i = 0; i < SSIZE; i++)
    if (sim_env.ext_flag [i])
      sim_env.s [i] = 1;

  sim_env.pc++;
  (* op_fcn [opcode]) (opcode);
  cycle_count++;
}


void reset_processor (void)
{
  cycle_count = 0;

  sim_env.pc = 0;
  sim_env.rom = 0;
  sim_env.group = 0;
  sim_env.del_rom = 0;
  sim_env.del_grp = 0;

  op_clear_reg (0);
  op_clear_s (0);
  sim_env.p = 0;

  sim_env.display_enable = 0;
  sim_env.key_flag = 0;
}


GCond *sim_cond;
GCond *ui_cond;
GMutex *sim_mutex;


#define UINST_PER_SEC 3500

#define UINST_PER_JIFFY 35

#define JIFFY_PER_SEC (UINST_PER_SEC/UINST_PER_JIFFY)
#define JIFFY_USEC ((G_USEC_PER_SEC)/JIFFY_PER_SEC)


gpointer sim_thread_func (gpointer data)
{
  GTimeVal tv;
  int i;

  for (;;)
    {
      g_mutex_lock (sim_mutex);
      switch (sim_state)
	{
	case SIM_QUIT:
	  g_mutex_unlock (sim_mutex);
	  g_thread_exit (0);
	case SIM_RESET:
	  reset_processor ();
	  sim_state = SIM_IDLE;
	  g_cond_signal (ui_cond);
	  g_cond_wait (sim_cond, sim_mutex);
	  break;
	case SIM_IDLE:
	  g_cond_wait (sim_cond, sim_mutex);
	  break;
	case SIM_STEP:
	  execute_instruction ();
	  handle_io ();
	  sim_state = SIM_IDLE;
	  g_cond_signal (ui_cond);
	  g_cond_wait (sim_cond, sim_mutex);
	  break;
	case SIM_RUN:
	  g_get_current_time (& tv);
	  for (i = 0; i < UINST_PER_JIFFY; i++)
	    {
	      execute_instruction ();
	      handle_io ();
	    }
	  g_time_val_add (& tv, JIFFY_USEC);
	  g_cond_timed_wait (sim_cond, sim_mutex, & tv);
	  break;
	}
      g_mutex_unlock (sim_mutex);
    }
}




GThread *sim_thread;


/* The following functions can be called from the main thread: */

void sim_init (int ram_size,
	       void (*display_update_fn)(char *buf))
{
  g_thread_init (NULL);  /* $$$ has Gtk already done this? */

  sim_cond = g_cond_new ();
  ui_cond = g_cond_new ();
  sim_mutex = g_mutex_new ();

  g_mutex_lock (sim_mutex);

  init_ops ();
  init_breakpoints ();
  init_source ();

  memset ((char *) & sim_env, 0, sizeof (sim_env_t));

  sim_env.max_ram = ram_size;
  sim_env.ram = alloc (ram_size * sizeof (reg_t));

  display_update = display_update_fn;

  sim_state = SIM_IDLE;

  sim_env.key_buf = -1;  /* no key has been pressed */

  cycle_count = 0;

  sim_thread = g_thread_create (sim_thread_func, NULL, TRUE, NULL);

  g_mutex_unlock (sim_mutex);
}


void sim_quit (void)
{
  g_mutex_lock (sim_mutex);
  sim_state = SIM_QUIT;

  g_thread_join (sim_thread);
}


void sim_reset (void)
{
  g_mutex_lock (sim_mutex);
  if (sim_state != SIM_IDLE)
    fatal (2, "can't reset when not idle\n");
  sim_state = SIM_STEP;
  g_cond_signal (sim_cond);
  while (sim_state != SIM_IDLE)
    g_cond_wait (ui_cond, sim_mutex);
  g_mutex_unlock (sim_mutex);
}


void sim_step (void)
{
  g_mutex_lock (sim_mutex);
  if (sim_state != SIM_IDLE)
    fatal (2, "can't step when not idle\n");
  sim_state = SIM_STEP;
  g_cond_signal (sim_cond);
  while (sim_state != SIM_IDLE)
    g_cond_wait (ui_cond, sim_mutex);
  g_mutex_unlock (sim_mutex);
}


void sim_start (void)
{
  g_mutex_lock (sim_mutex);
  if (sim_state != SIM_IDLE)
    fatal (2, "can't start when not idle\n");
  sim_state = SIM_RUN;
  g_cond_signal (sim_cond);
  g_mutex_unlock (sim_mutex);
}


void sim_stop (void)
{
  g_mutex_lock (sim_mutex);
  if (sim_state == SIM_IDLE)
    goto done;
  if (sim_state != SIM_RUN)
    fatal (2, "can't start when not idle\n");
  sim_state = SIM_RUN;
  g_cond_signal (sim_cond);
done:
  g_mutex_unlock (sim_mutex);
}


uint64_t sim_get_cycle_count (void)
{
  uint64_t count;
  g_mutex_lock (sim_mutex);
  count = cycle_count;
  g_mutex_unlock (sim_mutex);
  return (count);
}


void sim_set_cycle_count (uint64_t count)
{
  g_mutex_lock (sim_mutex);
  cycle_count = count;
  g_mutex_unlock (sim_mutex);
}


void sim_set_breakpoint (int address)
{
  /* $$$ not yet implemented */
}


void sim_clear_breakpoint (int address)
{
  /* $$$ not yet implemented */
}


gboolean sim_running (void)
{
  gboolean result;
  g_mutex_lock (sim_mutex);
  result = (sim_state == SIM_RUN);
  g_mutex_unlock (sim_mutex);
  return (result);
}


void sim_get_env (sim_env_t *env)
{
  g_mutex_lock (sim_mutex);
  memcpy (env, & sim_env, sizeof (sim_env_t));
  g_mutex_unlock (sim_mutex);
}


void sim_set_env (sim_env_t *env)
{
  g_mutex_lock (sim_mutex);
  memcpy (& sim_env, env, sizeof (sim_env_t));
  g_mutex_unlock (sim_mutex);
}


romword sim_read_rom (int addr)
{
  /* The ROM is read-only, so we don't have to grab the mutex. */
  /* $$$ not yet implemented */
  return (0);
}


void sim_read_ram (int addr, reg_t *val)
{
  if (addr > sim_env.max_ram)
    fatal (2, "sim_read_ram: address %d out of range\n", addr);
  g_mutex_lock (sim_mutex);
  memcpy (val, & sim_env.ram [addr], sizeof (reg_t));
  g_mutex_unlock (sim_mutex);
}


void sim_write_ram (int addr, reg_t *val)
{
  if (addr > sim_env.max_ram)
    fatal (2, "sim_write_ram: address %d out of range\n", addr);
  g_mutex_lock (sim_mutex);
  memcpy (& sim_env.ram [addr], val, sizeof (reg_t));
  g_mutex_unlock (sim_mutex);
}


void sim_press_key (int keycode)
{
  g_mutex_lock (sim_mutex);
  sim_env.key_buf = keycode;
  sim_env.key_flag = TRUE;
  g_mutex_unlock (sim_mutex);
}


void sim_release_key (void)
{
  g_mutex_lock (sim_mutex);
  sim_env.key_flag = FALSE;
  g_mutex_unlock (sim_mutex);
}


void sim_set_ext_flag (int flag, gboolean state)
{
  g_mutex_lock (sim_mutex);
  sim_env.ext_flag [flag] = state;
  g_mutex_unlock (sim_mutex);
}
