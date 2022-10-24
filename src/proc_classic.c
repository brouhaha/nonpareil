/*
Copyright 2004-2006, 2008, 2010, 2022 Eric Smith <spacewar@gmail.com>

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
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "arch.h"
#include "util.h"
#include "display.h"
#include "keyboard.h"
#include "chip.h"
#include "calcdef.h"
#include "proc.h"
#include "proc_int.h"
#include "digit_ops.h"
#include "proc_classic.h"


#define CR(name, field, bits, radix, get, set, arg) \
    {{ name, bits, 1, radix },                      \
     offsetof (classic_cpu_reg_t, field),           \
     FIELD_SIZE_OF (classic_cpu_reg_t, field),      \
     get, set, arg } 


#define CRD(name, field, digits)              \
    {{ name, digits * 4, 1, 16 }    ,         \
     offsetof (classic_cpu_reg_t, field),     \
     FIELD_SIZE_OF (classic_cpu_reg_t, field),\
     get_digits, set_digits, digits } 


static reg_detail_t classic_cpu_reg_detail [] =
{
  //   name     field  digits
  CRD ("a",     a,     WSIZE),
  CRD ("b",     b,     WSIZE),
  CRD ("c",     c,     WSIZE),
  CRD ("d",     d,     WSIZE),
  CRD ("e",     e,     WSIZE),
  CRD ("f",     f,     WSIZE),
  CRD ("m",     m,     WSIZE),

  //   name              field           bits           radix get        set        arg
  CR  ("p",              p,              4,             16,   NULL,      NULL,      0),
  CR  ("carry",          carry,          1,             2,    NULL,      NULL,      0),
  //    prev_carry
  CR  ("s",              s,              SSIZE,         2,    get_bools, set_bools, SSIZE),
  CR  ("ext_flag",       ext_flag,       EXT_FLAG_SIZE, 2,    get_bools, set_bools, EXT_FLAG_SIZE),

  CR  ("group",          group,          1,             2,    NULL,      NULL,      0),
  CR  ("rom",            rom,            3,             8,    NULL,      NULL,      0),
  CR  ("pc",             pc,             8,             8,    NULL,      NULL,      0),
  CR  ("ret_pc",         ret_pc,         8,             8,    NULL,      NULL,      0),
  //    prev_pc

  CR  ("del_group_flag", del_group_flag, 1,             2,    NULL,      NULL,      0),
  CR  ("del_group",      del_group,      1,             2,    NULL,      NULL,      0),
  CR  ("del_rom_flag",   del_rom_flag,   1,             2,    NULL,      NULL,      0),
  CR  ("del_rom",        del_rom,        3,             8,    NULL,      NULL,      0),

  CR  ("display_enable", display_enable, 1,             2,    NULL,      NULL,      0),
  // key_flag
  // key_buf
};


static chip_event_fn_t classic_event_fn;


static chip_detail_t classic_cpu_chip_detail =
{
  {
    "CTC/ARC",
    CHIP_CLASSIC_CTC,  // Actually two chips, but we have to choose one
    false  // There can only be one processor in the calculator.
  },
  sizeof (classic_cpu_reg_detail) / sizeof (reg_detail_t),
  classic_cpu_reg_detail,
  classic_event_fn
};


bank_t classic_get_max_rom_bank (sim_t *sim UNUSED)
{
  return MAX_BANK;
}

int classic_get_rom_page_size (sim_t *sim UNUSED)
{
  return PAGE_SIZE;
}

int classic_get_max_rom_addr (sim_t *sim UNUSED)
{
  return MAX_PAGE * PAGE_SIZE;
}

bool classic_get_page_info (sim_t           *sim UNUSED,
			    bank_t          bank,
			    uint8_t         page,
			    plugin_module_t **module,
			    bool            *ram,
			    bool            *write_enable)
{
  if ((bank > MAX_BANK) || (page > MAX_PAGE))
    return false;
  if (module)
    *module = NULL;
  if (ram)
    *ram = false;
  if (write_enable)
    *write_enable = false;
  return true;
}


static bool classic_read_rom (sim_t      *sim,
			      bank_t     bank,
			      addr_t     addr,
			      rom_word_t *val)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);

  if ((bank >= MAX_BANK) || (addr >= (MAX_PAGE * PAGE_SIZE)))
    return false;

  if (! cpu_reg->rom_exists [addr])
    return false;

  *val = cpu_reg->ucode [addr];
  return true;
}


static bool classic_write_rom (sim_t      *sim,
			       bank_t     bank,
			       addr_t     addr,
			       rom_word_t *val)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);

  if ((bank >= MAX_BANK) || (addr > (MAX_PAGE * PAGE_SIZE)))
    return false;

  cpu_reg->rom_exists [addr] = true;
  cpu_reg->ucode [addr] = *val;

  return true;
}


static inline uint8_t arithmetic_base (classic_cpu_reg_t *cpu_reg UNUSED)
{
  return 10;  // no binary (hex) mode on Classic
}


static void bad_op (sim_t *sim, int opcode)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);

  printf ("illegal opcode %04o at %02o%03o\n", opcode,
	  cpu_reg->prev_pc >> 8, cpu_reg->prev_pc & 0377);
}


static void op_arith (sim_t *sim, int opcode)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);
  uint8_t op, field;
  int first = 0;
  int last = 0;

  op = opcode >> 5;
  field = (opcode >> 2) & 7;

  switch (field)
    {
    case 0:  /* p  */
      first =  cpu_reg->p; last =  cpu_reg->p;
      if (cpu_reg->p >= WSIZE)
	{
	  printf ("Warning! p >= WSIZE at %02o%03o\n",
		  cpu_reg->prev_pc >> 8, cpu_reg->prev_pc & 0377);
	  last = 0;  /* don't do anything */
	}
      break;
    case 1:  /* m  */  first = EXPSIZE;      last = WSIZE - 2;   break;
    case 2:  /* x  */  first = 0;            last = EXPSIZE - 1; break;
    case 3:  /* w  */  first = 0;            last = WSIZE - 1;   break;
    case 4:  /* wp */
      first =  0; last =  cpu_reg->p;
      if (cpu_reg->p >= WSIZE)
	{
	  printf ("Warning! p >= WSIZE at %02o%03o\n",
		  cpu_reg->prev_pc >> 8, cpu_reg->prev_pc & 0377);
	  last = WSIZE - 1;
	}
      break;
    case 5:  /* ms */  first =  EXPSIZE;     last = WSIZE - 1;   break;
    case 6:  /* xs */  first =  EXPSIZE - 1; last = EXPSIZE - 1; break;
    case 7:  /* s  */  first =  WSIZE - 1;   last = WSIZE - 1;   break;
    }

  // Note: carry was set to 0 by classic_execute_instruction before
  // we're called.
  switch (op)
    {
    case 0x00:  /* if b[f] = 0 */
      reg_test_nonequal (cpu_reg->b, NULL, first, last, & cpu_reg->carry);
      break;
    case 0x01:  /* 0 -> b[f] */
      reg_zero (cpu_reg->b, first, last);
      break;
    case 0x02:  /* if a >= c[f] */
      reg_sub (NULL, cpu_reg->a, cpu_reg->c,
	       first, last,
	       & cpu_reg->carry, arithmetic_base (cpu_reg));
      break;
    case 0x03:  /* if c[f] >= 1 */
      reg_test_equal (cpu_reg->c, NULL, first, last, & cpu_reg->carry);
      break;
    case 0x04:  /* b -> c[f] */
      reg_copy (cpu_reg->c, cpu_reg->b, first, last);
      break;
    case 0x05:  /* 0 - c -> c[f] */
      reg_sub (cpu_reg->c, NULL, cpu_reg->c,
	       first, last,
	       & cpu_reg->carry, arithmetic_base (cpu_reg));
      break;
    case 0x06:  /* 0 -> c[f] */
      reg_zero (cpu_reg->c, first, last);
      break;
    case 0x07:  /* 0 - c - 1 -> c[f] */
      cpu_reg->carry = 1;
      reg_sub (cpu_reg->c, NULL, cpu_reg->c,
	       first, last,
	       & cpu_reg->carry, arithmetic_base (cpu_reg));
      break;
    case 0x08:  /* shift left a[f] */
      reg_shift_left (cpu_reg->a, first, last);
      break;
    case 0x09:  /* a -> b[f] */
      reg_copy (cpu_reg->b, cpu_reg->a, first, last);
      break;
    case 0x0a:  /* a - c -> c[f] */
      reg_sub (cpu_reg->c, cpu_reg->a, cpu_reg->c,
	       first, last,
	       & cpu_reg->carry, arithmetic_base (cpu_reg));
      break;
    case 0x0b:  /* c - 1 -> c[f] */
      cpu_reg->carry = 1;
      reg_sub (cpu_reg->c, cpu_reg->c, NULL,
	       first, last,
	       & cpu_reg->carry, arithmetic_base (cpu_reg));
      break;
    case 0x0c:  /* c -> a[f] */
      reg_copy (cpu_reg->a, cpu_reg->c, first, last);
      break;
    case 0x0d:  /* if c[f] = 0 */
      reg_test_nonequal (cpu_reg->c, NULL, first, last, & cpu_reg->carry);
      break;
    case 0x0e:  /* a + c -> c[f] */
      reg_add (cpu_reg->c, cpu_reg->a, cpu_reg->c,
	       first, last,
	       & cpu_reg->carry, arithmetic_base (cpu_reg));
      break;
    case 0x0f:  /* c + 1 -> c[f] */
      cpu_reg->carry = 1;
      reg_add (cpu_reg->c, cpu_reg->c, NULL,
	       first, last,
	       & cpu_reg->carry, arithmetic_base (cpu_reg));
      break;
    case 0x10:  /* if a >= b[f] */
      reg_sub (NULL, cpu_reg->a, cpu_reg->b,
	       first, last,
	       & cpu_reg->carry, arithmetic_base (cpu_reg));
      break;
    case 0x11:  /* b exchange c[f] */
      reg_exch (cpu_reg->b, cpu_reg->c, first, last);
      break;
    case 0x12:  /* shift right c[f] */
      reg_shift_right (cpu_reg->c, first, last);
      break;
    case 0x13:  /* if a[f] >= 1 */
      reg_test_equal (cpu_reg->a, NULL, first, last, & cpu_reg->carry);
      break;
    case 0x14:  /* shift right b[f] */
      reg_shift_right (cpu_reg->b, first, last);
      break;
    case 0x15:  /* c + c -> c[f] */
      reg_add (cpu_reg->c, cpu_reg->c, cpu_reg->c,
	       first, last,
	       & cpu_reg->carry, arithmetic_base (cpu_reg));
      break;
    case 0x16:  /* shift right a[f] */
      reg_shift_right (cpu_reg->a, first, last);
      break;
    case 0x17:  /* 0 -> a[f] */
      reg_zero (cpu_reg->a, first, last);
      break;
    case 0x18:  /* a - b -> a[f] */
      reg_sub (cpu_reg->a, cpu_reg->a, cpu_reg->b,
	       first, last,
	       & cpu_reg->carry, arithmetic_base (cpu_reg));
      break;
    case 0x19:  /* a exchange b[f] */
      reg_exch (cpu_reg->a, cpu_reg->b, first, last);
      break;
    case 0x1a:  /* a - c -> a[f] */
      reg_sub (cpu_reg->a, cpu_reg->a, cpu_reg->c,
	       first, last,
	       & cpu_reg->carry, arithmetic_base (cpu_reg));
      break;
    case 0x1b:  /* a - 1 -> a[f] */
      cpu_reg->carry = 1;
      reg_sub (cpu_reg->a, cpu_reg->a, NULL,
	       first, last,
	       & cpu_reg->carry, arithmetic_base (cpu_reg));
      break;
    case 0x1c:  /* a + b -> a[f] */
      reg_add (cpu_reg->a, cpu_reg->a, cpu_reg->b,
	       first, last,
	       & cpu_reg->carry, arithmetic_base (cpu_reg));
      break;
    case 0x1d:  /* a exchange c[f] */
      reg_exch (cpu_reg->a, cpu_reg->c, first, last);
      break;
    case 0x1e:  /* a + c -> a[f] */
      reg_add (cpu_reg->a, cpu_reg->a, cpu_reg->c,
	       first, last,
	       & cpu_reg->carry, arithmetic_base (cpu_reg));
      break;
    case 0x1f:  /* a + 1 -> a[f] */
      cpu_reg->carry = 1;
      reg_add (cpu_reg->a, cpu_reg->a, NULL,
	       first, last,
	       & cpu_reg->carry, arithmetic_base (cpu_reg));
      break;
    }
}


static void op_goto (sim_t *sim, int opcode)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);

  if (! cpu_reg->prev_carry)
    {
      cpu_reg->pc = opcode >> 2;
    }
}


static void op_jsb (sim_t *sim, int opcode)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);

  cpu_reg->ret_pc = cpu_reg->pc;
  cpu_reg->pc = opcode >> 2;
}


static void op_return (sim_t *sim,
		       int opcode UNUSED)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);

  cpu_reg->pc = cpu_reg->ret_pc;
}


static void op_nop (sim_t *sim UNUSED,
		    int opcode UNUSED)
{
}


static void op_dec_p (sim_t *sim,
		      int opcode UNUSED)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);

  cpu_reg->p = (cpu_reg->p - 1) & 0xf;
  /* On the ACT (Woodstock) if P=0 before a decrement, it will be
     13 after.  Apparently the CTC (Classic) does not do this. */
}


static void op_inc_p (sim_t *sim,
		      int opcode UNUSED)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);

  cpu_reg->p = (cpu_reg->p + 1) & 0xf;
  /* On the ACT (Woodstock) if P=13 before an increment, it will be
     0 after.  Apparently the CTC (Classic) does not do this. */
}


static void op_clear_s (sim_t *sim,
			int opcode UNUSED)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);
  int i;

  for (i = 0; i < SSIZE; i++)
    cpu_reg->s [i] = 0;
}


static void op_c_exch_m (sim_t *sim,
			 int opcode UNUSED)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);
  int i, t;

  for (i = 0; i < WSIZE; i++)
    {
      t = cpu_reg->c [i];
      cpu_reg->c [i] = cpu_reg->m[i];
      cpu_reg->m [i] = t;
    }
}


static void op_m_to_c (sim_t *sim,
		       int opcode UNUSED)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);
  int i;

  for (i = 0; i < WSIZE; i++)
    cpu_reg->c [i] = cpu_reg->m [i];
}


static void op_c_to_addr (sim_t *sim,
			  int opcode UNUSED)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);

  if (sim->arch_flags & 1)
    cpu_reg->ram_addr = cpu_reg->c [12] * 10 + cpu_reg->c [11];
  else
    cpu_reg->ram_addr = cpu_reg->c [12];
  if (cpu_reg->ram_addr >= cpu_reg->max_ram)
    printf ("c -> ram addr: address %d out of range\n", cpu_reg->ram_addr);
}


static void op_c_to_data (sim_t *sim,
			  int opcode UNUSED)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);
  int i;

  if (cpu_reg->ram_addr >= cpu_reg->max_ram)
    {
      printf ("c -> data: address %d out of range\n", cpu_reg->ram_addr);
      return;
    }
  for (i = 0; i < WSIZE; i++)
    cpu_reg->ram [cpu_reg->ram_addr] [i] = cpu_reg->c [i];
}


static void op_data_to_c (sim_t *sim,
			  int opcode UNUSED)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);
  int i;

  if (cpu_reg->ram_addr >= cpu_reg->max_ram)
    {
      printf ("data -> c: address %d out of range, loading 0\n", cpu_reg->ram_addr);
      for (i = 0; i < WSIZE; i++)
	cpu_reg->c [i] = 0;
      return;
    }
  for (i = 0; i < WSIZE; i++)
    cpu_reg->c [i] = cpu_reg->ram [cpu_reg->ram_addr] [i];
}


static void op_c_to_stack (sim_t *sim,
			   int opcode UNUSED)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);
  int i;

  for (i = 0; i < WSIZE; i++)
    {
      cpu_reg->f [i] = cpu_reg->e [i];
      cpu_reg->e [i] = cpu_reg->d [i];
      cpu_reg->d [i] = cpu_reg->c [i];
    }
}


static void op_stack_to_a (sim_t *sim,
			   int opcode UNUSED)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);
  int i;

  for (i = 0; i < WSIZE; i++)
    {
      cpu_reg->a [i] = cpu_reg->d [i];
      cpu_reg->d [i] = cpu_reg->e [i];
      cpu_reg->e [i] = cpu_reg->f [i];
    }
}


static void op_down_rotate (sim_t *sim,
			    int opcode UNUSED)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);
  int i, t;

  for (i = 0; i < WSIZE; i++)
    {
      t = cpu_reg->c [i];
      cpu_reg->c [i] = cpu_reg->d [i];
      cpu_reg->d [i] = cpu_reg->e [i];
      cpu_reg->e [i] = cpu_reg->f [i];
      cpu_reg->f [i] = t;
    }
}


static void op_clear_reg (sim_t *sim,
			  int opcode UNUSED)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);
  int i;

  for (i = 0; i < WSIZE; i++)
    cpu_reg->a [i] = cpu_reg->b [i] = cpu_reg->c [i] = cpu_reg->d [i] =
      cpu_reg->e [i] = cpu_reg->f [i] = cpu_reg->m [i] = 0;
}


static void op_load_constant (sim_t *sim, int opcode)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);

  if (cpu_reg->p >= WSIZE)
    {
#if 0 /* HP-45 depends on load constant with p > 13 not affecting C */
      printf ("load constant w/ p >= WSIZE at %02o%03o\n",
	      cpu_reg->prev_pc >> 8, cpu_reg->prev_pc & 0377)
      ;
#endif
    }
  else if ((opcode >> 6) > 9)
    printf ("load constant > 9\n");
  else
    cpu_reg->c [cpu_reg->p] = opcode >> 6;

  cpu_reg->p = (cpu_reg->p - 1) & 0xf;
  /* On the ACT (Woodstock) if P=0 before a load constant, it will be
     13 after.  Apparently the CTC (Classic) does not do this. */
}


static void op_set_s (sim_t *sim, int opcode)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);

  if ((opcode >> 6) >= SSIZE)
    printf ("stat >= SSIZE at %02o%03o\n",
	    cpu_reg->prev_pc >> 8, cpu_reg->prev_pc & 0377);
  else
    cpu_reg->s [opcode >> 6] = 1;
}


static void op_clr_s (sim_t *sim, int opcode)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);

  if ((opcode >> 6) >= SSIZE)
    printf ("stat >= SSIZE at %02o%03o\n",
	    cpu_reg->prev_pc >> 8, cpu_reg->prev_pc & 0377);
  else
    cpu_reg->s [opcode >> 6] = 0;
}


static void op_test_s (sim_t *sim, int opcode)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);

  if ((opcode >> 6) >= SSIZE)
    printf ("stat >= SSIZE at %02o%03o\n",
	    cpu_reg->prev_pc >> 8, cpu_reg->prev_pc & 0377);
  else
    cpu_reg->carry = cpu_reg->s [opcode >> 6];
}


static void op_set_p (sim_t *sim, int opcode)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);

  cpu_reg->p = opcode >> 6;
}


static void op_test_p (sim_t *sim, int opcode)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);

  cpu_reg->carry = (cpu_reg->p == (opcode >> 6));
}


static void op_sel_rom (sim_t *sim, int opcode)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);

  cpu_reg->rom = opcode >> 7;
}


static void op_del_sel_rom (sim_t *sim, int opcode)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);

  cpu_reg->del_rom = opcode >> 7;
  cpu_reg->del_rom_flag = true;
}


static void op_del_sel_grp (sim_t *sim, int opcode)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);

  cpu_reg->del_group = (opcode >> 7) & 1;
  cpu_reg->del_group_flag = true;
}


static void op_keys_to_rom_addr (sim_t *sim,
				 int opcode UNUSED)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);

  if (cpu_reg->key_buf < 0)
    {
      printf ("keys->rom address with no key pressed\n");
      cpu_reg->pc = 0;
      return;
    }
  cpu_reg->pc = cpu_reg->key_buf;
}


static void op_rom_addr_to_buf (sim_t *sim UNUSED,
				int opcode UNUSED)
{
#if 0
  // I don't know what this instruction is supposed to do, but the
  // 55 uses it quite frequently!
  fprintf (stderr, "rom addr to buf!!!!!!!!!!!!\n");
#endif
}


static void op_display_off (sim_t *sim,
			    int opcode UNUSED)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);

  cpu_reg->display_enable = 0;
}


static void op_display_toggle (sim_t *sim,
			       int opcode UNUSED)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);

  cpu_reg->display_enable = ! cpu_reg->display_enable;
}


static void init_ops (classic_cpu_reg_t *cpu_reg)
{
  int i, j;

  for (i = 0; i < 1024; i += 4)
    {
      cpu_reg->op_fcn [i + 0] = bad_op;
      cpu_reg->op_fcn [i + 1] = op_jsb;    /* type 1: aaaaaaaa01 */
      cpu_reg->op_fcn [i + 2] = op_arith;  /* type 2: ooooowww10 */
      cpu_reg->op_fcn [i + 3] = op_goto;   /* type 1: aaaaaaaa11 */
    }

  /* type 3 instructions: nnnnff0100*/
  for (i = 0; i <= 15; i ++)
    {
      cpu_reg->op_fcn [0x004 + (i << 6)] = op_set_s;
      cpu_reg->op_fcn [0x014 + (i << 6)] = op_test_s;
      cpu_reg->op_fcn [0x024 + (i << 6)] = op_clr_s;
      cpu_reg->op_fcn [0x034 /* + (i << 6) */ ] = op_clear_s;
    }

  /* New instructions in HP-55 and maybe HP-65, wedged into the unused
     port of the type 3 instruction space.  On the HP-35 and HP-80 these
     probably cleared all status like 0x034. */
  for (i = 0; i <= 7; i ++)
    {
      cpu_reg->op_fcn [0x074 + (i << 7)] = op_del_sel_rom;
    }
  cpu_reg->op_fcn [0x234] = op_del_sel_grp;
  cpu_reg->op_fcn [0x2b4] = op_del_sel_grp;

  /* type 4 instructions: ppppff1100 */
  for (i = 0; i <= 15; i ++)
    {
      cpu_reg->op_fcn [0x00c + (i << 6)] = op_set_p;
      cpu_reg->op_fcn [0x02c + (i << 6)] = op_test_p;
      cpu_reg->op_fcn [0x01c /* + (i << 6) */ ] = op_dec_p;
      cpu_reg->op_fcn [0x03c /* + (i << 6) */ ] = op_inc_p;
    }

  /* type 5 instructions: nnnnff1000 */
  for (i = 0; i <= 9; i++)
      cpu_reg->op_fcn [0x018 + (i << 6)] = op_load_constant;
  for (i = 0; i <= 1; i++)
    {
      cpu_reg->op_fcn [0x028 /* + (i << 4) */ ] = op_display_toggle;
      cpu_reg->op_fcn [0x0a8 /* + (i << 4) */ ] = op_c_exch_m;
      cpu_reg->op_fcn [0x128 /* + (i << 4) */ ] = op_c_to_stack;
      cpu_reg->op_fcn [0x1a8 /* + (i << 4) */ ] = op_stack_to_a;
      cpu_reg->op_fcn [0x228 /* + (i << 4) */ ] = op_display_off;
      cpu_reg->op_fcn [0x2a8 /* + (i << 4) */ ] = op_m_to_c;
      cpu_reg->op_fcn [0x328 /* + (i << 4) */ ] = op_down_rotate;
      cpu_reg->op_fcn [0x3a8 /* + (i << 4) */ ] = op_clear_reg;
      for (j = 0; j <= 3; j++)
	{
#if 0
	  cpu_reg->op_fcn [0x068 + (j << 8) + (i << 4)] = op_is_to_a;
#endif
	  cpu_reg->op_fcn [0x0e8 + (j << 8) + (i << 4)] = op_data_to_c;
	  /* BCD->C is nominally 0x2f8 */
	}
    }

  /* type 6 instructions: nnnff10000 */
  for (i = 0; i <= 7; i++)
    {
      cpu_reg->op_fcn [0x010 + (i << 7)] = op_sel_rom;
      cpu_reg->op_fcn [0x030 /* + (i << 7) */ ] = op_return;
      if (i & 1)
	cpu_reg->op_fcn [0x050 + 0x080 /* + (i << 7) */ ] = op_keys_to_rom_addr;
#if 0
      else
	cpu_reg->op_fcn [0x050 /* + (i << 7) */ ] = op_external_entry;
#endif
    }
  cpu_reg->op_fcn [0x270] = op_c_to_addr;  /* also 0x370 */
  cpu_reg->op_fcn [0x2f0] = op_c_to_data;

  /* no type 7 or type 8 instructions: xxxx100000, xxx1000000 */

  /* type 9 and 10 instructions: xxx0000000 */
  cpu_reg->op_fcn [0x200] = op_rom_addr_to_buf;
  cpu_reg->op_fcn [0x000] = op_nop;
}


#define FAKE_CLASSIC_DISASSEMBLER
#ifdef FAKE_CLASSIC_DISASSEMBLER
static void classic_disassemble (sim_t *sim, int addr, char *buf, int len)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);
  int l;

  l = snprintf (buf, len, "%02o%03o: ", addr >> 8, addr & 0377);
  buf += l;
  len -= l;
  if (len <= 0)
    return;

  l = snprintf (buf, len, "%04o", cpu_reg->ucode [addr]);
  buf += l;
  len -= l;
  if (len <= 0)
    return;

  return;
}
#endif // FAKE_CLASSIC_DISASSEMBLER


static void classic_display_scan (sim_t *sim)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);
  int a = cpu_reg->a [cpu_reg->display_scan_position];
  int b = cpu_reg->b [cpu_reg->display_scan_position];

  if (cpu_reg->display_digit_position < MAX_DIGIT_POSITION)
    {
      sim->display_segments [cpu_reg->display_digit_position] = 0;  /* blank */

      if (cpu_reg->display_enable && (b <= 7))
	{
	  if ((cpu_reg->display_scan_position == 2) ||
	      (cpu_reg->display_scan_position == 13))
	    {
	      if (a >= 8)
		sim->display_segments [cpu_reg->display_digit_position] = sim->display_char_gen ['-'];
	    }
	  else
	    sim->display_segments [cpu_reg->display_digit_position] = sim->display_char_gen ['0' + a];
      
	  if (b == 2)
	    {
	      if ((++cpu_reg->display_digit_position) < MAX_DIGIT_POSITION)
		sim->display_segments [cpu_reg->display_digit_position] = sim->display_char_gen ['.'];
	    }
	}
    }

  cpu_reg->display_digit_position++;

  if ((--cpu_reg->display_scan_position) < cpu_reg->right_scan)
    {
      while (cpu_reg->display_digit_position < MAX_DIGIT_POSITION)
	sim->display_segments [cpu_reg->display_digit_position++] = 0;

      sim_send_display_update_to_gui (sim);

      cpu_reg->display_digit_position = 0;
      cpu_reg->display_scan_position = cpu_reg->left_scan;
    }
}


static void log_print_reg (sim_t *sim, char *label, reg_t reg)
{
  int i;
  printf ("%s", label);
  for (i = WSIZE - 1; i >= 0; i--)
    log_printf (sim, "%x", reg [i]);
  log_printf (sim, "\n");
  log_send (sim);
}

static void classic_print_state (sim_t *sim)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);

  int i;
  log_printf (sim, "pc=%05o  p=%d  stat:",
	      (cpu_reg->group << 12) + (cpu_reg->rom << 9) + (cpu_reg->pc),
	      cpu_reg->p);
  for (i = 0; i < SSIZE; i++)
    if (cpu_reg->s [i])
      log_printf (sim, " %d", i);
  log_printf (sim, "\n");
  log_send (sim);

  log_print_reg (sim, "a: ", cpu_reg->a);
  log_print_reg (sim, "b: ", cpu_reg->b);
  log_print_reg (sim, "c: ", cpu_reg->c);
  log_print_reg (sim, "m: ", cpu_reg->m);

  if (sim->source && sim->source [cpu_reg->prev_pc])
    log_printf (sim, "%s", sim->source [cpu_reg->prev_pc]);
  else
    {
      char buf [80];

#ifdef FAKE_CLASSIC_DISASSEMBLER
      classic_disassemble (sim, cpu_reg->prev_pc, buf, sizeof (buf));
#else
      addr_t delayed_select_mask = 0;
      addr_t delayed_select_addr = 0;
      if (cpu_reg->del_rom_flag)
      {
	delayed_select_mask |= 03400;
	delayed_select_addr |= cpu_reg->del_rom << 8;
      }

      if (cpu_reg->del_group_flag)
      {
	delayed_select_mask |= 04000;
	delayed_select_addr |= cpu_reg->del_group << 11;
      }

      sim_disassemble_runtime(sim,
			      0,                  // flags
			      0,                  // bank
			      cpu_reg->prev_pc,   // addr
			      inst_normal,        // inst_state
			      cpu_reg->carry,
			      delayed_select_mask,
			      delayed_select_addr,
			      buf,
			      sizeof (buf));
#endif // FAKE_CLASSIC_DISASSEMBLER
      log_printf (sim, "%s\n", buf);
    }
  log_printf (sim, "\n");
  log_send (sim);
}


bool classic_execute_instruction (sim_t *sim)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);
  int addr;
  int opcode;

  addr = (cpu_reg->group << 11) | (cpu_reg->rom << 8) | cpu_reg->pc;
  cpu_reg->prev_pc = addr;
  opcode = cpu_reg->ucode [addr];

#ifdef HAS_DEBUGGER
  if (sim->debug_flags & (1 << SIM_DEBUG_KEY_TRACE))
    {
      if (opcode == 00320)  // keys to rom addr
	sim->debug_flags |= (1 << SIM_DEBUG_TRACE);
      else if (opcode == 00024) // if s0 # 1
	sim->debug_flags &= ~ (1 << SIM_DEBUG_TRACE);
    }

  if (sim->debug_flags & (1 << SIM_DEBUG_TRACE))
    classic_print_state (sim);
#endif /* HAS_DEBUGGER */

  cpu_reg->prev_carry = cpu_reg->carry;
  cpu_reg->carry = 0;

  bool prev_del_group_flag = cpu_reg->del_group_flag;
  uint8_t prev_del_group = cpu_reg->del_group;
  cpu_reg->del_group_flag = false;

  bool prev_del_rom_flag = cpu_reg->del_rom_flag;
  uint8_t prev_del_rom = cpu_reg->del_rom;
  cpu_reg->del_rom_flag = false;

  if (cpu_reg->key_flag)
    cpu_reg->s [0] = 1;
  if (cpu_reg->ext_flag [EXT_FLAG_CTC_F1])
    cpu_reg->s [3] = 1;
  if (cpu_reg->ext_flag [EXT_FLAG_CTC_F2])
    cpu_reg->s [11] = 1;

  cpu_reg->pc++;
  (* cpu_reg->op_fcn [opcode]) (sim, opcode);
  sim->cycle_count++;

  if (prev_del_group_flag)
  {
    cpu_reg->group = prev_del_group;
  }

  if (prev_del_rom_flag)
  {
    cpu_reg->rom = prev_del_rom;
  }

  cpu_reg->display_scan_fn (sim);

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


static bool classic_parse_object_line (char        *buf,
				       bank_mask_t *bank_mask,
				       addr_t      *addr,
				       rom_word_t  *opcode)
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

  *bank_mask = 1;
  *addr = a;
  *opcode = o;
  return (true);
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
      bin++;
    }
  return (1);
}


static bool classic_parse_listing_line (char        *buf,
					bank_mask_t *bank_mask,
					addr_t      *addr,
					rom_word_t  *opcode)
{
  int g, r, p, o;

  if ((strlen (buf) < 25) || (buf [7] != 'L') || (buf [13] != ':'))
    return (false);

  if (! parse_address (& buf [8], &g, &r, &p))
    {
      fprintf (stderr, "bad address format\n");
      return (false);
    }

  if ((g >= MAX_GROUP) || (r >= MAX_ROM) || (p >= ROM_SIZE))
    {
      fprintf (stderr, "bad address: group %o rom %o addr %03o\n", g, r, p);
      return (false);
    }

  if (! parse_opcode (& buf [16], & o))
    {
      fprintf (stderr, "bad opcode\n");
      return (false);
    }

  *bank_mask = 1;
  *addr = (g << 11) + (r << 8) + p;
  *opcode = o;
  return (true);
}


static void display_setup (sim_t *sim)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);

  sim->display_char_gen = calcdef_get_char_gen (sim->calcdef,
						"anode_driver");

  sim->display_digits = MAX_DIGIT_POSITION;
  cpu_reg->display_scan_fn = classic_display_scan;
  cpu_reg->left_scan = WSIZE - 1;
  cpu_reg->right_scan = 0;
}


static void classic_reset (sim_t *sim)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);

  sim->cycle_count = 0;

  cpu_reg->pc = 0;
  cpu_reg->rom = 0;
  cpu_reg->group = 0;
  cpu_reg->del_rom_flag = 0;
  cpu_reg->del_rom = 0;
  cpu_reg->del_group_flag = 0;
  cpu_reg->del_group = 0;

  op_clear_reg (sim, 0);
  op_clear_s (sim, 0);
  cpu_reg->p = 0;

  cpu_reg->display_enable = 0;
  cpu_reg->display_digit_position = 0;
  cpu_reg->display_scan_position = cpu_reg->left_scan;

  cpu_reg->key_flag = 0;
}


static void classic_clear_memory (sim_t *sim)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);
  addr_t addr;

  for (addr = 0; addr < cpu_reg->max_ram; addr++)
    reg_zero (cpu_reg->ram [addr], 0, WSIZE - 1);
}


static int classic_get_max_ram_addr (sim_t *sim)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);

  return cpu_reg->max_ram;
}


static bool classic_create_ram (sim_t *sim, addr_t addr, addr_t size)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);

  if ((addr + size) > cpu_reg->arch_max_ram)
    fatal (4, "ram addresses out of range\n");

  if ((addr + size) > cpu_reg->max_ram)
    cpu_reg->max_ram = addr + size;

  while (size--)
    {
      cpu_reg->ram_exists [addr] = true;
      addr++;
    }

  return true;
}


static bool classic_read_ram (sim_t *sim, addr_t addr, uint64_t *val)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);
  uint64_t data = 0;
  int i;
  bool status;

  if (addr >= cpu_reg->max_ram)
    {
      status = false;
      warning ("classic_read_ram: address %d out of range\n", addr);
    }
  else
    {
      // pack cpu_reg->ram [addr] into data
      for (i = WSIZE - 1; i >= 0; i--)
	{
	  data <<= 4;
	  data += cpu_reg->ram [addr] [i];
	}
      status = true;
    }

  *val = data;

  return status;
}


static bool classic_write_ram (sim_t *sim, addr_t addr, uint64_t *val)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);
  uint64_t data;
  int i;

  if (addr >= cpu_reg->max_ram)
    {
      warning ("classic_write_ram: address %d out of range\n", addr);
      return false;
    }

  data = *val;

  // now unpack data into cpu_reg->ram [addr]
  for (i = 0; i <= WSIZE; i++)
    {
      cpu_reg->ram [addr] [i] = data & 0x0f;
      data >>= 4;
    }

  return true;
}


static void classic_new_rom_addr_space (sim_t *sim,
					int max_bank,
					int max_page,
					int page_size)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);
  size_t max_words;

  max_words = max_bank * max_page * page_size;

  cpu_reg->ucode = alloc (max_words * sizeof (rom_word_t));
  cpu_reg->rom_exists = alloc (max_words * sizeof (bool));
  cpu_reg->rom_breakpoint = alloc (max_words * sizeof (bool));
}


static void classic_new_ram_addr_space (sim_t *sim, int max_ram)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);

  cpu_reg->ram_exists = alloc (max_ram * sizeof (bool));
  cpu_reg->ram = alloc (max_ram * sizeof (reg_t));
}


static void classic_new_processor (sim_t *sim)
{
  classic_cpu_reg_t *cpu_reg;

  cpu_reg = alloc (sizeof (classic_cpu_reg_t));

  install_chip (sim,
		NULL,  // module
		& classic_cpu_chip_detail,
		cpu_reg);

  classic_new_rom_addr_space (sim, MAX_BANK, MAX_PAGE, PAGE_SIZE);

  if (sim->arch_flags & 1)
    cpu_reg->arch_max_ram = 100;
  else
    cpu_reg->arch_max_ram = 10;

  classic_new_ram_addr_space (sim, cpu_reg->arch_max_ram);
  cpu_reg->max_ram = 0;

  cpu_reg->max_ram = cpu_reg->arch_max_ram; // $$$ wrong

  // RAM is contiguous starting from address 0.
  cpu_reg->ram = alloc (cpu_reg->max_ram * sizeof (reg_t));

  display_setup (sim);

  init_ops (cpu_reg);

  chip_event (sim,
	      NULL,
	      event_reset,
	      0,
	      0,
	      NULL);
}


static void classic_free_processor (sim_t *sim)
{
  remove_chip (sim->first_chip);
}


static void classic_event_fn (sim_t      *sim,
			      chip_t     *chip UNUSED,
			      event_id_t event,
			      int        arg1,
			      int        arg2,
			      void       *data UNUSED)
{
  classic_cpu_reg_t *cpu_reg = get_chip_data (sim->first_chip);

  switch (event)
    {
    case event_reset:
       classic_reset (sim);
       break;
    case event_clear_memory:
       classic_clear_memory (sim);
       break;
    case event_key:
      if (arg2)
	{
	  cpu_reg->key_buf = arg1;
	  cpu_reg->key_flag = true;
	}
      else
	cpu_reg->key_flag = false;
      break;
    case event_set_flag:
      cpu_reg->ext_flag [arg1] = arg2;
      break;
    default:
      // warning ("proc_classic: unknown event %d\n", event);
      break;
    }
}


processor_dispatch_t classic_processor =
  {
    .new_processor       = classic_new_processor,
    .free_processor      = classic_free_processor,

    .parse_object_line   = classic_parse_object_line,
    .parse_listing_line  = classic_parse_listing_line,

    // cycle is same as instruction
    .execute_cycle       = classic_execute_instruction,
    .execute_instruction = classic_execute_instruction,

    .set_bank_group      = NULL,
    .get_max_rom_bank    = classic_get_max_rom_bank,
    .get_rom_page_size   = classic_get_rom_page_size,
    .get_max_rom_addr    = classic_get_max_rom_addr,
    .get_page_info       = classic_get_page_info,

    .read_rom            = classic_read_rom,
    .write_rom           = classic_write_rom,

    .get_max_ram_addr    = classic_get_max_ram_addr,
    .create_ram          = classic_create_ram,
    .read_ram            = classic_read_ram,
    .write_ram           = classic_write_ram,

#ifdef FAKE_CLASSIC_DISASSEMBLER
    .disassemble         = NULL,
#else
    .disassemble         = classic_disassemble,
#endif // FAKE_CLASSIC_DISASSEMBLER
    .print_state         = classic_print_state
  };
