/*
$Id$
Copyright 2004, 2005 Eric L. Smith <eric@brouhaha.com>

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

#include <inttypes.h>
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
#include "digit_ops.h"
#include "proc_woodstock.h"
#include "dis_woodstock.h"


#define HAS_DEBUGGER


/* If defined, print warnings about stack overflow or underflow. */
#undef STACK_WARNING


#define WR(name, field, bits, radix, get, set, arg) \
    {{ name, bits, 1, radix },                      \
     OFFSET_OF (act_reg_t, field),                  \
     SIZE_OF (act_reg_t, field),                    \
     get, set, arg } 


#define WRA(name, field, bits, radix, get, set, arg, array) \
    {{ name, bits, array, radix },                          \
     OFFSET_OF (act_reg_t, field[0]),                       \
     SIZE_OF (act_reg_t, field[0]),                         \
     get, set, arg } 


#define WRD(name, field, digits)      \
    {{ name, digits * 4, 1, 16 },     \
     OFFSET_OF (act_reg_t, field),    \
     SIZE_OF (act_reg_t, field),      \
     get_digits, set_digits, digits } 


static reg_detail_t woodstock_cpu_reg_detail [] =
{
  //   name     field  digits
  WRD ("a",     a,     WSIZE),
  WRD ("b",     b,     WSIZE),
  WRD ("c",     c,     WSIZE),
  WRD ("y",     y,     WSIZE),
  WRD ("z",     z,     WSIZE),
  WRD ("t",     t,     WSIZE),
  WRD ("m1",    m1,    WSIZE),
  WRD ("m2",    m2,    WSIZE),

  //   name       field    bits   radix get        set        arg
  WR  ("p",       p,       4,     16,   NULL,      NULL,      0),
  WR  ("f",       f,       4,     16,   NULL,      NULL,      0),
  WR  ("decimal", decimal, 1,      2,   NULL,      NULL,      0),
  WR  ("carry",   carry,   1,      2,   NULL,      NULL,      0),
  // prev_carry

  WR  ("s",        s,        SSIZE,         2, get_bools, set_bools, SSIZE),
  WR  ("ext_flag", ext_flag, EXT_FLAG_SIZE, 2, get_bools, set_bools, EXT_FLAG_SIZE),

  WR  ("bank",    bank,    1,     2,   NULL,      NULL,      0),
  WR  ("pc",      pc,      12,    8,   NULL,      NULL,      0),
  // prev_pc
  WRA ("stack",   stack,   12,    8, NULL,      NULL,        0, STACK_SIZE),
  WR  ("del_rom_flag", del_rom_flag,   1,     2,   NULL,      NULL,      0),
  WR  ("del_rom", del_rom, 4,     8,   NULL,      NULL,      0),

  WR  ("display_enable", display_enable,   1,     2,   NULL,      NULL,      0),
  WR  ("display_14_digit", display_14_digit,   1,     2,   NULL,      NULL,      0),
  // key_flag
  // key_buf
  WR  ("ram_addr", ram_addr, 8, 16, NULL, NULL, 0)
};


static chip_event_fn_t woodstock_event_fn;


static chip_detail_t woodstock_cpu_chip_detail =
{
  {
    "ACT",
    CHIP_CPU,
    false  // There can only be one ACT in the calculator.
  },
  sizeof (woodstock_cpu_reg_detail) / sizeof (reg_detail_t),
  woodstock_cpu_reg_detail,
  woodstock_event_fn,
};


static inline uint8_t get_effective_bank (act_reg_t *act_reg, rom_addr_t addr)
{
  uint8_t page = addr / PAGE_SIZE;
  uint8_t bank;

  bank = act_reg->bank;
  if (! (act_reg->bank_exists [page] & (1 << bank)))
    bank = 0;

  return bank;
}


static rom_word_t woodstock_get_ucode (act_reg_t *act_reg, rom_addr_t addr)
{
  uint8_t bank;

  bank = get_effective_bank (act_reg, addr);

  // $$$ check for non-existent memory?

  return act_reg->rom [bank * (MAX_PAGE * PAGE_SIZE) + addr];
}


int woodstock_get_max_rom_bank (sim_t *sim)
{
  return MAX_BANK;
}

int woodstock_get_rom_page_size (sim_t *sim)
{
  return PAGE_SIZE;
}

int woodstock_get_max_rom_addr (sim_t *sim)
{
  return MAX_PAGE * PAGE_SIZE;
}

bool woodstock_page_exists (sim_t   *sim,
			    uint8_t bank,
			    uint8_t page)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  return (act_reg->bank_exists [page] & (1 << bank)) != 0;
}


static bool woodstock_read_rom (sim_t      *sim,
				uint8_t    bank,
				addr_t     addr,
				rom_word_t *val)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  uint8_t page;
  uint16_t rom_index;

  if (addr >= (MAX_PAGE * PAGE_SIZE))
    return false;

  page = addr / PAGE_SIZE;

  if (! (act_reg->bank_exists [page] & (1 << bank)))
    return false;

  rom_index = bank * (MAX_PAGE * PAGE_SIZE) + addr;

  if (! act_reg->rom_exists [rom_index])
    return false;

  *val = act_reg->rom [rom_index];
  return true;
}


static bool woodstock_write_rom (sim_t      *sim,
				 uint8_t    bank,
				 addr_t     addr,
				 rom_word_t *val)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  uint8_t page;
  uint16_t rom_index;

  if (addr >= (MAX_PAGE * PAGE_SIZE))
    return false;

  page = addr / PAGE_SIZE;

  act_reg->bank_exists [page] |= (1 << bank);

  rom_index = bank * (MAX_PAGE * PAGE_SIZE) + addr;

  act_reg->rom_exists [rom_index] = true;
  act_reg->rom [rom_index] = *val;

  return true;
}


static inline uint8_t arithmetic_base (act_reg_t *act_reg)
{
  return act_reg->decimal ? 10 : 16;
}


static void woodstock_print_state (sim_t *sim);


static void bad_op (sim_t *sim, int opcode)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  printf ("illegal opcode %04o at %05o\n", opcode, act_reg->prev_pc);
}


static void op_arith (sim_t *sim, int opcode)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  uint8_t op, field;
  int first = 0;
  int last = 0;

  op = opcode >> 5;
  field = (opcode >> 2) & 7;

  switch (field)
    {
    case 0:  /* p  */
      first = act_reg->p; last = act_reg->p;
      if (act_reg->p >= WSIZE)
	{
	  printf ("Warning! p >= WSIZE at %05o\n", act_reg->prev_pc);
	  woodstock_print_state (sim);
	  last = 0;  /* don't do anything */
	}
      break;
    case 1:  /* wp */
      first = 0; last = act_reg->p;
      if (act_reg->p >= WSIZE)
	{
	  printf ("Warning! p >= WSIZE at %05o\n", act_reg->prev_pc);
	  woodstock_print_state (sim);
	  last = WSIZE - 1;
	}
      break;
    case 2:  /* xs */  first = EXPSIZE - 1; last = EXPSIZE - 1; break;
    case 3:  /* x  */  first = 0;           last = EXPSIZE - 1; break;
    case 4:  /* s  */  first = WSIZE - 1;   last = WSIZE - 1;   break;
    case 5:  /* m  */  first = EXPSIZE;     last = WSIZE - 2;   break;
    case 6:  /* w  */  first = 0;           last = WSIZE - 1;   break;
    case 7:  /* ms */  first = EXPSIZE;     last = WSIZE - 1;   break;
    }

  act_reg->carry = 0;

  switch (op)
    {
    case 0x00:  /* 0 -> a[f] */
      reg_zero (act_reg->a, first, last);
      break;
    case 0x01:  /* 0 -> b[f] */
      reg_zero (act_reg->b, first, last);
      break;
    case 0x02:  /* a exchange b[f] */
      reg_exch (act_reg->a, act_reg->b, first, last);
      break;
    case 0x03:  /* a -> b[f] */
      reg_copy (act_reg->b, act_reg->a, first, last);
      break;
    case 0x04:  /* a exchange c[f] */
      reg_exch (act_reg->a, act_reg->c, first, last);
      break;
    case 0x05:  /* c -> a[f] */
      reg_copy (act_reg->a, act_reg->c, first, last);
      break;
    case 0x06:  /* b -> c[f] */
      reg_copy (act_reg->c, act_reg->b, first, last);
      break;
    case 0x07:  /* b exchange c[f] */
      reg_exch (act_reg->b, act_reg->c, first, last);
      break;
    case 0x08:  /* 0 -> c[f] */
      reg_zero (act_reg->c, first, last);
      break;
    case 0x09:  /* a + b -> a[f] */
      reg_add (act_reg->a, act_reg->a, act_reg->b,
	       first, last,
	       & act_reg->carry, arithmetic_base (act_reg));
      break;
    case 0x0a:  /* a + c -> a[f] */
      reg_add (act_reg->a, act_reg->a, act_reg->c,
	       first, last,
	       & act_reg->carry, arithmetic_base (act_reg));
      break;
    case 0x0b:  /* c + c -> c[f] */
      reg_add (act_reg->c, act_reg->c, act_reg->c,
	       first, last,
	       & act_reg->carry, arithmetic_base (act_reg));
      break;
    case 0x0c:  /* a + c -> c[f] */
      reg_add (act_reg->c, act_reg->a, act_reg->c,
	       first, last,
	       & act_reg->carry, arithmetic_base (act_reg));
      break;
    case 0x0d:  /* a + 1 -> a[f] */
      act_reg->carry = 1;
      reg_add (act_reg->a, act_reg->a, NULL,
	       first, last,
	       & act_reg->carry, arithmetic_base (act_reg));
      break;
    case 0x0e:  /* shift left a[f] */
      reg_shift_left (act_reg->a, first, last);
      break;
    case 0x0f:  /* c + 1 -> c[f] */
      act_reg->carry = 1;
      reg_add (act_reg->c, act_reg->c, NULL,
	       first, last,
	       & act_reg->carry, arithmetic_base (act_reg));
      break;
    case 0x10:  /* a - b -> a[f] */
      reg_sub (act_reg->a, act_reg->a, act_reg->b,
	       first, last,
	       & act_reg->carry, arithmetic_base (act_reg));
      break;
    case 0x11:  /* a - c -> c[f] */
      reg_sub (act_reg->c, act_reg->a, act_reg->c,
	       first, last,
	       & act_reg->carry, arithmetic_base (act_reg));
      break;
    case 0x12:  /* a - 1 -> a[f] */
      act_reg->carry = 1;
      reg_sub (act_reg->a, act_reg->a, NULL,
	       first, last,
	       & act_reg->carry, arithmetic_base (act_reg));
      break;
    case 0x13:  /* c - 1 -> c[f] */
      act_reg->carry = 1;
      reg_sub (act_reg->c, act_reg->c, NULL,
	       first, last,
	       & act_reg->carry, arithmetic_base (act_reg));
      break;
    case 0x14:  /* 0 - c -> c[f] */
      reg_sub (act_reg->c, NULL, act_reg->c,
	       first, last,
	       & act_reg->carry, arithmetic_base (act_reg));
      break;
    case 0x15:  /* 0 - c - 1 -> c[f] */
      act_reg->carry = 1;
      reg_sub (act_reg->c, NULL, act_reg->c,
	       first, last,
	       & act_reg->carry, arithmetic_base (act_reg));
      break;
    case 0x16:  /* if b[f] = 0 */
      act_reg->inst_state = branch;
      reg_test_nonequal (act_reg->b, NULL, first, last, & act_reg->carry);
      break;
    case 0x17:  /* if c[f] = 0 */
      act_reg->inst_state = branch;
      reg_test_nonequal (act_reg->c, NULL, first, last, & act_reg->carry);
      break;
    case 0x18:  /* if a >= c[f] */
      act_reg->inst_state = branch;
      reg_sub (NULL, act_reg->a, act_reg->c,
	       first, last,
	       & act_reg->carry, arithmetic_base (act_reg));
      break;
    case 0x19:  /* if a >= b[f] */
      act_reg->inst_state = branch;
      reg_sub (NULL, act_reg->a, act_reg->b,
	       first, last,
	       & act_reg->carry, arithmetic_base (act_reg));
      break;
    case 0x1a:  /* if a[f] # 0 */
      act_reg->inst_state = branch;
      reg_test_equal (act_reg->a, NULL, first, last, & act_reg->carry);
      break;
    case 0x1b:  /* if c[f] # 0 */
      act_reg->inst_state = branch;
      reg_test_equal (act_reg->c, NULL, first, last, & act_reg->carry);
      break;
    case 0x1c:  /* a - c -> a[f] */
      reg_sub (act_reg->a, act_reg->a, act_reg->c,
	       first, last,
	       & act_reg->carry, arithmetic_base (act_reg));
      break;
    case 0x1d:  /* shift right a[f] */
      reg_shift_right (act_reg->a, first, last);
      break;
    case 0x1e:  /* shift right b[f] */
      reg_shift_right (act_reg->b, first, last);
      break;
    case 0x1f:  /* shift right c[f] */
      reg_shift_right (act_reg->c, first, last);
      break;
    }
}


static void handle_del_rom (act_reg_t *act_reg)
{
  if (act_reg->del_rom_flag)
    {
      act_reg->pc = (act_reg->del_rom << 8) + (act_reg->pc & 0377);
      act_reg->del_rom_flag = 0;
    }
}


static void op_goto (sim_t *sim, int opcode)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  if (! act_reg->prev_carry)
    {
      act_reg->pc = (act_reg->pc & ~0377) | (opcode >> 2);
      handle_del_rom (act_reg);
    }
}


static void op_jsb (sim_t *sim, int opcode)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  act_reg->stack [act_reg->sp] = act_reg->pc;
  act_reg->sp++;
  if (act_reg->sp >= STACK_SIZE)
    {
#ifdef STACK_WARNING
      printf ("stack overflow\n");
#endif
      act_reg->sp = 0;
    }
  act_reg->pc = (act_reg->pc & ~0377) | (opcode >> 2);
  handle_del_rom (act_reg);
}


static void op_return (sim_t *sim,
		       int opcode UNUSED)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  act_reg->sp--;
  if (act_reg->sp < 0)
    {
#ifdef STACK_WARNING
      printf ("stack underflow\n");
#endif
      act_reg->sp = STACK_SIZE - 1;
    }
  act_reg->pc = act_reg->stack [act_reg->sp];
}


static void op_nop (sim_t *sim UNUSED,
		    int opcode UNUSED)
{
}


static void op_binary (sim_t *sim,
		       int opcode UNUSED)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  act_reg->decimal = false;
}


static void op_decimal (sim_t *sim,
			int opcode UNUSED)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  act_reg->decimal = true;
}


/* $$$ woodstock doc says when increment or decrement P wraps,
 * P "disappears for one word time". */

static void op_dec_p (sim_t *sim,
		      int opcode UNUSED)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  if (act_reg->p)
    act_reg->p--;
  else
    act_reg->p = WSIZE - 1;
}


static void op_inc_p (sim_t *sim,
		      int opcode UNUSED)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  act_reg->p++;
  if (act_reg->p >= WSIZE)
    act_reg->p = 0;
}


static void op_clear_s (sim_t *sim,
			int opcode UNUSED)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  int i;

  for (i = 0; i < SSIZE; i++)
    if ((i != 1) && (i != 2) && (i != 5) && (i != 15))
      act_reg->s [i] = 0;
}


static void op_m1_exch_c (sim_t *sim,
			  int opcode UNUSED)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  reg_exch (act_reg->c, act_reg->m1, 0, WSIZE - 1);
}


static void op_m1_to_c (sim_t *sim,
			int opcode UNUSED)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  reg_copy (act_reg->c, act_reg->m1, 0, WSIZE - 1);
}


static void op_m2_exch_c (sim_t *sim,
			  int opcode UNUSED)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  reg_exch (act_reg->c, act_reg->m2, 0, WSIZE - 1);
}


static void op_m2_to_c (sim_t *sim,
			int opcode UNUSED)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  reg_copy (act_reg->c, act_reg->m2, 0, WSIZE - 1);
}


static void op_f_to_a (sim_t *sim,
		       int opcode UNUSED)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  act_reg->a [0] = act_reg->f;
}


static void op_f_exch_a (sim_t *sim,
			 int opcode UNUSED)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  int t;

  t = act_reg->a [0];
  act_reg->a [0] = act_reg->f;
  act_reg->f = t;
}


static void op_circulate_a_left (sim_t *sim,
				 int opcode UNUSED)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  int i, t;

  t = act_reg->a [WSIZE - 1];
  for (i = WSIZE - 1; i >= 1; i--)
    act_reg->a [i] = act_reg->a [i - 1];
  act_reg->a [0] = t;
}


static void op_bank_switch (sim_t *sim,
			    int opcode UNUSED)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  act_reg->bank ^= 1;
#ifdef DEBUG_BANK_SWITCH
  printf ("bank switch at %04o, will select bank %o\n",
	  act_reg->prev_pc, act_reg->bank);
#endif
}


static void op_rom_selftest (sim_t *sim,
			     int opcode UNUSED)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  act_reg->crc = 01777;
  act_reg->inst_state = selftest;
  act_reg->pc &= ~ 01777;  // start from beginning of current 1K ROM bank
  printf ("starting ROM CRC of bank %d addr %04o\n", act_reg->bank, act_reg->pc);
}


static void rom_selftest_done (sim_t *sim)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  // ROM self-test completed, return and set S5 if error
  printf ("ROM CRC done, crc = %03x: %s\n", act_reg->crc,
	  act_reg->crc == 0x078 ? "good" : "bad");
  if (act_reg->crc != 0x078)
    act_reg->s [5] = 1;  // indicate error
  act_reg->inst_state = norm;
  op_return (sim, 0);
}


static void crc_update (sim_t *sim, int word)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  int i;
  int b;

  for (i = 0; i < 10; i++)
    {
      b = act_reg->crc & 1;
      act_reg->crc >>= 1;
      if (b ^ (word & 1))
	act_reg->crc ^= 0x331;
      word >>= 1;
    }
}


static void op_c_to_addr (sim_t *sim,
			  int opcode UNUSED)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  act_reg->ram_addr = (act_reg->c [1] << 4) + act_reg->c [0];
#ifdef HAS_DEBUGGER
  if (sim->debug_flags & (1 << SIM_DEBUG_RAM_TRACE))
    printf ("RAM select %02x\n", act_reg->ram_addr);
#endif
  if (act_reg->ram_addr >= sim->max_ram)
    printf ("c -> ram addr: address %d out of range\n", act_reg->ram_addr);
}


static void op_c_to_data (sim_t *sim,
			  int opcode UNUSED)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  int i;

  if (act_reg->ram_addr >= sim->max_ram)
    {
      printf ("c -> data: address %02x out of range\n", act_reg->ram_addr);
      return;
    }
#ifdef HAS_DEBUGGER
  if (sim->debug_flags & (1 << SIM_DEBUG_RAM_TRACE))
    {
      printf ("C -> DATA, addr %02x  data ", act_reg->ram_addr);
      for (i = 0; i < WSIZE; i++)
	printf ("%x", act_reg->c [i]);
      printf ("\n");
    }
#endif
  for (i = 0; i < WSIZE; i++)
    act_reg->ram [act_reg->ram_addr] [i] = act_reg->c [i];
}


static void op_data_to_c (sim_t *sim,
			  int opcode UNUSED)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  int i;

  if (act_reg->ram_addr >= sim->max_ram)
    {
      printf ("data -> c: address %d out of range, loading 0\n", act_reg->ram_addr);
      for (i = 0; i < WSIZE; i++)
	act_reg->c [i] = 0;
      return;
    }
#ifdef HAS_DEBUGGER
  if (sim->debug_flags & (1 << SIM_DEBUG_RAM_TRACE))
    {
      printf ("DATA -> C, addr %02x  data ", act_reg->ram_addr);
      for (i = 0; i < WSIZE; i++)
	printf ("%x", act_reg->ram [act_reg->ram_addr] [i]);
      printf ("\n");
    }
#endif /* HAS_DEBUGGER */
  for (i = 0; i < WSIZE; i++)
    act_reg->c [i] = act_reg->ram [act_reg->ram_addr] [i];
}


static void op_c_to_register (sim_t *sim, int opcode)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  int i;

  act_reg->ram_addr &= ~017;
  act_reg->ram_addr += (opcode >> 6);

  if (act_reg->ram_addr >= sim->max_ram)
    {
      printf ("c -> register: address %d out of range\n", act_reg->ram_addr);
      return;
    }
#ifdef HAS_DEBUGGER
  if (sim->debug_flags & (1 << SIM_DEBUG_RAM_TRACE))
    {
      printf ("C -> REGISTER %d, addr %02x  data ", opcode >> 6, act_reg->ram_addr);
      for (i = 0; i < WSIZE; i++)
	printf ("%x", act_reg->c [i]);
      printf ("\n");
    }
#endif /* HAS_DEBUGGER */
  for (i = 0; i < WSIZE; i++)
    act_reg->ram [act_reg->ram_addr] [i] = act_reg->c [i];
}


static void op_register_to_c (sim_t *sim, int opcode)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  int i;

  act_reg->ram_addr &= ~017;
  act_reg->ram_addr += (opcode >> 6);

  if (act_reg->ram_addr >= sim->max_ram)
    {
      printf ("register -> c: address %d out of range, loading 0\n", act_reg->ram_addr);
      for (i = 0; i < WSIZE; i++)
	act_reg->c [i] = 0;
      return;
    }
#ifdef HAS_DEBUGGER
  if (sim->debug_flags & (1 << SIM_DEBUG_RAM_TRACE))
    {
      printf ("REGISTER -> C %d, addr %02x  data ", opcode >> 6, act_reg->ram_addr);
      for (i = 0; i < WSIZE; i++)
	printf ("%x", act_reg->ram [act_reg->ram_addr] [i]);
      printf ("\n");
    }
#endif /* HAS_DEBUGGER */
  for (i = 0; i < WSIZE; i++)
    act_reg->c [i] = act_reg->ram [act_reg->ram_addr] [i];
}


static void op_clear_data_regs (sim_t *sim,
				int opcode UNUSED)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  int base;
  int i, j;

#ifdef HAS_DEBUGGER
  if (sim->debug_flags & (1 << SIM_DEBUG_RAM_TRACE))
    printf ("clear data regs, addr %02x\n", act_reg->ram_addr);
#endif /* HAS_DEBUGGER */
  base = act_reg->ram_addr & ~ 017;
  for (i = base; i <= base + 15; i++)
    for (j = 0; j < WSIZE; j++)
      act_reg->ram [i] [j] = 0;
}


static void op_c_to_stack (sim_t *sim,
			   int opcode UNUSED)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  int i;

  for (i = 0; i < WSIZE; i++)
    {
      act_reg->t [i] = act_reg->z [i];
      act_reg->z [i] = act_reg->y [i];
      act_reg->y [i] = act_reg->c [i];
    }
}


static void op_stack_to_a (sim_t *sim,
			   int opcode UNUSED)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  int i;

  for (i = 0; i < WSIZE; i++)
    {
      act_reg->a [i] = act_reg->y [i];
      act_reg->y [i] = act_reg->z [i];
      act_reg->z [i] = act_reg->t [i];
    }
}


static void op_y_to_a (sim_t *sim,
		       int opcode UNUSED)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  int i;

  for (i = 0; i < WSIZE; i++)
    {
      act_reg->a [i] = act_reg->y [i];
    }
}


static void op_down_rotate (sim_t *sim,
			    int opcode UNUSED)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  int i, t;

  for (i = 0; i < WSIZE; i++)
    {
      t = act_reg->c [i];
      act_reg->c [i] = act_reg->y [i];
      act_reg->y [i] = act_reg->z [i];
      act_reg->z [i] = act_reg->t [i];
      act_reg->t [i] = t;
    }
}


static void op_clear_reg (sim_t *sim,
			  int opcode UNUSED)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  int i;

  for (i = 0; i < WSIZE; i++)
    act_reg->a [i] = act_reg->b [i] = act_reg->c [i] = act_reg->y [i] =
      act_reg->z [i] = act_reg->t [i] = 0;
  // Apparently we're not supposed to clear F, or the HP-21 CLR function
  // resets the display format.
  // Should this clear P?  Probably not.
}


static void op_load_constant (sim_t *sim, int opcode)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  if (act_reg->p >= WSIZE)
    {
      printf ("load constant w/ p >= WSIZE at %05o\n", act_reg->prev_pc);
      woodstock_print_state (sim);
    }
  else
    act_reg->c [act_reg->p] = opcode >> 6;
  if (act_reg->p)
    act_reg->p--;
  else
    act_reg->p = WSIZE - 1;
}


static void op_set_s (sim_t *sim, int opcode)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  if ((opcode >> 6) >= SSIZE)
    printf ("stat >= SSIZE at %05o\n", act_reg->prev_pc);
  else
    act_reg->s [opcode >> 6] = 1;
}


static void op_clr_s (sim_t *sim, int opcode)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  if ((opcode >> 6) >= SSIZE)
    printf ("stat >= SSIZE at %05o\n", act_reg->prev_pc);
  else
    act_reg->s [opcode >> 6] = 0;
}


static void op_test_s_eq_0 (sim_t *sim, int opcode)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  act_reg->inst_state = branch;
  act_reg->carry = act_reg->s [opcode >> 6];
}


static void op_test_s_eq_1 (sim_t *sim, int opcode)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  act_reg->inst_state = branch;
  act_reg->carry = ! act_reg->s [opcode >> 6];
}


static uint8_t p_set_map [16] =
  { 14,  4,  7,  8, 11,  2, 10, 12,  1,  3, 13,  6,  0,  9,  5, 14 };

static uint8_t p_test_map [16] =
  {  4,  8, 12,  2,  9,  1,  6,  3,  1, 13,  5,  0, 11, 10,  7,  4 };


static void op_set_p (sim_t *sim, int opcode)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  act_reg->p = p_set_map [opcode >> 6];
  if (act_reg->p >= WSIZE)
    printf ("invalid set p, operand encoding is %02o\n", opcode > 6);
}


static void op_test_p_eq (sim_t *sim, int opcode)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  act_reg->inst_state = branch;
  act_reg->carry = ! (act_reg->p == p_test_map [opcode >> 6]);
}


static void op_test_p_ne (sim_t *sim, int opcode)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  act_reg->inst_state = branch;
  act_reg->carry = ! (act_reg->p != p_test_map [opcode >> 6]);
}


static void op_sel_rom (sim_t *sim, int opcode)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  act_reg->pc = ((opcode & 01700) << 2) + (act_reg->pc & 0377);
}


static void op_del_sel_rom (sim_t *sim, int opcode)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  act_reg->del_rom = opcode >> 6;
  act_reg->del_rom_flag = 1;
}


static void op_keys_to_rom_addr (sim_t *sim,
				 int opcode UNUSED)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  act_reg->pc = act_reg->pc & ~0377;
  handle_del_rom (act_reg);
  if (act_reg->key_buf < 0)
    {
      printf ("keys->rom address with no key pressed\n");
      return;
    }
  act_reg->pc += act_reg->key_buf;
}


static void op_keys_to_a (sim_t *sim,
			  int opcode UNUSED)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  if (act_reg->key_buf < 0)
    {
      printf ("keys->a with no key pressed\n");
      act_reg->a [2] = 0;
      act_reg->a [1] = 0;
      return;
    }
  act_reg->a [2] = act_reg->key_buf >> 4;
  act_reg->a [1] = act_reg->key_buf & 0x0f;
}


static void op_a_to_rom_addr (sim_t *sim,
			      int opcode UNUSED)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  act_reg->pc = act_reg->pc & ~0377;
  handle_del_rom (act_reg);
  act_reg->pc += ((act_reg->a [2] << 4) + act_reg->a [1]);
}


static void op_display_off (sim_t *sim,
			    int opcode UNUSED)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  act_reg->display_enable = 0;
}


static void op_display_toggle (sim_t *sim,
			       int opcode UNUSED)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  act_reg->display_enable = ! act_reg->display_enable;
}


static void op_display_reset_twf (sim_t *sim,
				  int opcode UNUSED)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  act_reg->display_14_digit = true;
  act_reg->right_scan = 0;
}


static void op_crc_clear_f1 (sim_t *sim UNUSED,
			     int opcode UNUSED)
{
  // don't do anything, as CRC F1 is controlled by hardware
  // (in our case, ext_flag [1])
  ;  
}


static void op_crc_test_f1 (sim_t *sim,
			    int opcode UNUSED)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  if (act_reg->ext_flag [1])
    act_reg->s [3] = 1;
}


static void init_ops (act_reg_t *act_reg)
{
  int i;

  for (i = 0; i < 1024; i += 4)
    {
      act_reg->op_fcn [i + 0] = bad_op;
      act_reg->op_fcn [i + 1] = op_jsb;    /* type 1: aaaaaaaa01 */
      act_reg->op_fcn [i + 2] = op_arith;  /* type 2: ooooowww10 */
      act_reg->op_fcn [i + 3] = op_goto;   /* type 1: aaaaaaaa11 */
    }

  for (i = 0; i <= 15; i ++)
    {
      /* xx00 uassigned */
      act_reg->op_fcn [00004 + (i << 6)] = op_set_s;
      /* xx10 misc */
      act_reg->op_fcn [00014 + (i << 6)] = op_clr_s;
      /* xx20 misc */
      act_reg->op_fcn [00024 + (i << 6)] = op_test_s_eq_1;
      act_reg->op_fcn [00030 + (i << 6)] = op_load_constant;
      act_reg->op_fcn [00034 + (i << 6)] = op_test_s_eq_0;
      act_reg->op_fcn [00040 + (i << 6)] = op_sel_rom;
      act_reg->op_fcn [00044 + (i << 6)] = op_test_p_eq;
      act_reg->op_fcn [00050 + (i << 6)] = op_c_to_register;
      act_reg->op_fcn [00054 + (i << 6)] = op_test_p_ne;
      /* xx60 misc */
      act_reg->op_fcn [00064 + (i << 6)] = op_del_sel_rom;
      act_reg->op_fcn [00070 + (i << 6)] = op_register_to_c;
      act_reg->op_fcn [00074 + (i << 6)] = op_set_p;
    }

  act_reg->op_fcn [00000] = op_nop;
  act_reg->op_fcn [00070] = op_data_to_c;

  act_reg->op_fcn [00010] = op_clear_reg;
  act_reg->op_fcn [00110] = op_clear_s;
  act_reg->op_fcn [00210] = op_display_toggle;
  act_reg->op_fcn [00310] = op_display_off;
  act_reg->op_fcn [00410] = op_m1_exch_c;
  act_reg->op_fcn [00510] = op_m1_to_c;
  act_reg->op_fcn [00610] = op_m2_exch_c;
  act_reg->op_fcn [00710] = op_m2_to_c;
  act_reg->op_fcn [01010] = op_stack_to_a;
  act_reg->op_fcn [01110] = op_down_rotate;
  act_reg->op_fcn [01210] = op_y_to_a;
  act_reg->op_fcn [01310] = op_c_to_stack;
  act_reg->op_fcn [01410] = op_decimal;
  /* 1510 unassigned */
  act_reg->op_fcn [01610] = op_f_to_a;
  act_reg->op_fcn [01710] = op_f_exch_a;

  act_reg->op_fcn [00020] = op_keys_to_rom_addr;
  act_reg->op_fcn [00120] = op_keys_to_a;
  act_reg->op_fcn [00220] = op_a_to_rom_addr;
  act_reg->op_fcn [00320] = op_display_reset_twf;
  act_reg->op_fcn [00420] = op_binary;
  act_reg->op_fcn [00520] = op_circulate_a_left;
  act_reg->op_fcn [00620] = op_dec_p;
  act_reg->op_fcn [00720] = op_inc_p;
  act_reg->op_fcn [01020] = op_return;
  /* 1120..1720 unknown, probably printer */

  /* 0060 unknown */
  /* 0160..0760 unassigned/unknown */
  act_reg->op_fcn [01060] = op_bank_switch;
  act_reg->op_fcn [01160] = op_c_to_addr;
  act_reg->op_fcn [01260] = op_clear_data_regs;
  act_reg->op_fcn [01360] = op_c_to_data;
  act_reg->op_fcn [01460] = op_rom_selftest;  /* Only on Spice series */
  /* 1560..1660 unassigned/unknown */
  act_reg->op_fcn [01760] = op_nop;  /* "HI I'M WOODSTOCK" */

  /* CRC chip in 67/97 */
  act_reg->op_fcn [00300] = op_crc_test_f1;
  act_reg->op_fcn [01500] = op_crc_clear_f1;

  act_reg->op_fcn [00560] = op_nop;

  act_reg->op_fcn [00400] = op_nop;
  act_reg->op_fcn [01000] = op_nop;
  act_reg->op_fcn [01300] = op_nop;

  /*
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
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  rom_word_t op1, op2;

  if (act_reg->inst_state == branch)  /* second word of conditional branch */
    {
      snprintf (buf, len, "...");
      return;
    }

  op1 = woodstock_get_ucode (act_reg, addr);
  op2 = woodstock_get_ucode (act_reg, addr + 1);

  woodstock_disassemble_inst (addr, op1, op2, buf, len);
}


static void display_scan_advance (sim_t *sim)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  if ((--act_reg->display_scan_position) < act_reg->right_scan)
    {
      while (act_reg->display_digit_position < MAX_DIGIT_POSITION)
	sim->display_segments [act_reg->display_digit_position++] = 0;

      sim_send_display_update_to_gui (sim);

      act_reg->display_digit_position = 0;
      act_reg->display_scan_position = act_reg->left_scan;
    }
}


static void woodstock_display_scan (sim_t *sim)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  int a = act_reg->a [act_reg->display_scan_position];
  int b = act_reg->b [act_reg->display_scan_position];
  segment_bitmap_t segs = 0;

  if (act_reg->display_14_digit && (act_reg->display_digit_position == 0))
    {
      // save room for mantissa sign
      sim->display_segments [act_reg->display_digit_position++] = 0;
    }

  if (act_reg->display_enable)
    {
      if (b & 2)
	{
	  if ((a >= 2) && ((a & 7) != 7))
	    segs = sim->char_gen ['-'];
	}
      else
	segs = sim->char_gen [a];
      if (act_reg->display_14_digit && (act_reg->display_digit_position == 12))
	{
	  // mantissa sign comes from E segment of exponent sign digit
	  if (segs & (1 << 4))
	    sim->display_segments [0] = sim->char_gen ['-'];  
          // exponent sign digit only has G segment
	  segs &= sim->char_gen ['-'];
	}
      if (b & 1)
	segs |= sim->char_gen ['.'];
    }

  sim->display_segments [act_reg->display_digit_position++] = segs;

  display_scan_advance (sim);
}


static void spice_display_scan (sim_t *sim)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  int a = act_reg->a [act_reg->display_scan_position];
  int b = act_reg->b [act_reg->display_scan_position];
  segment_bitmap_t segs = 0;

  if (! act_reg->display_digit_position)
    sim->display_segments [act_reg->display_digit_position++] = 0;  /* make room for sign */

  if (act_reg->display_enable)
    {
      if ((act_reg->display_scan_position == act_reg->left_scan) && (b & 4))
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

  sim->display_segments [act_reg->display_digit_position++] = segs;

  display_scan_advance (sim);
}


static void print_reg (char *label, reg_t reg)
{
  int i;
  printf ("%s", label);
  for (i = WSIZE - 1; i >= 0; i--)
    printf ("%x", reg [i]);
  printf ("\n");
}

static void woodstock_print_state (sim_t *sim)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  int i;
  uint8_t bank;
  int mapped_addr;

  bank = get_effective_bank (act_reg, act_reg->prev_pc);
  mapped_addr = bank * (MAX_PAGE * PAGE_SIZE) + act_reg->prev_pc;

  printf ("pc=%05o  radix=%d  p=%d  f=%x  stat:",
	  mapped_addr, arithmetic_base (act_reg), act_reg->p, act_reg->f);
  for (i = 0; i < 16; i++)
    if (act_reg->s [i])
      printf (" %d", i);
  printf ("\n");
  print_reg ("a:  ", act_reg->a);
  print_reg ("b:  ", act_reg->b);
  print_reg ("c:  ", act_reg->c);
  print_reg ("m1: ", act_reg->m1);
  print_reg ("m2: ", act_reg->m2);

  if (sim->source [mapped_addr])
    printf ("%s\n", sim->source [mapped_addr]);
  else
    {
      char buf [80];
      printf ("%" PRId64 ": ", sim->cycle_count);
      woodstock_disassemble (sim, act_reg->prev_pc, buf, sizeof (buf));
      printf ("%s\n", buf);
    }
}


static bool woodstock_execute_cycle (sim_t *sim)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  rom_word_t opcode;
  inst_state_t prev_inst_state;

  act_reg->prev_pc = act_reg->pc;
  opcode = woodstock_get_ucode (act_reg, act_reg->pc);

  if ((sim->platform != PLATFORM_SPICE) &&
      (act_reg->pc < 02000) &&
      (act_reg->bank == 1))
     {
#ifdef DEBUG_BANK_SWITCH
	printf ("implicit bank switch at %04o, will select bank 0\n",
		act_reg->pc);
#endif
	act_reg->bank = 0;
     }

#ifdef HAS_DEBUGGER
  if ((sim->debug_flags & (1 << SIM_DEBUG_KEY_TRACE)) &&
      (act_reg->inst_state == norm))
    {
      if (opcode == 00020)
	sim->debug_flags |= (1 << SIM_DEBUG_TRACE);
      else if (opcode == 01724)
	sim->debug_flags &= ~ (1 << SIM_DEBUG_TRACE);
    }

  if ((sim->debug_flags & (1 << SIM_DEBUG_TRACE)) &&
      (act_reg->inst_state != selftest))
    {
      woodstock_print_state (sim);
    }
#endif /* HAS_DEBUGGER */

  prev_inst_state = act_reg->inst_state;
  if (act_reg->inst_state == branch)
    act_reg->inst_state = norm;

  act_reg->prev_carry = act_reg->carry;
  act_reg->carry = 0;

  if (act_reg->key_flag)
    act_reg->s [15] = 1;

  if (act_reg->ext_flag [3])
    act_reg->s [3] = 1;
  if (act_reg->ext_flag [5])
    act_reg->s [5] = 1;

  act_reg->pc = (act_reg->pc + 1) & 07777;

  switch (prev_inst_state)
    {
    case norm:
      (* act_reg->op_fcn [opcode]) (sim, opcode);
      break;
    case branch:
      if (! act_reg->prev_carry)
	act_reg->pc = (act_reg->pc & ~01777) | opcode;
      break;
    case selftest:
      crc_update (sim, opcode);
      if (opcode == 01060)
	op_bank_switch (sim, opcode);  // bank switch even in self-test
      if (! (act_reg->pc & 01777))    // end of 1K ROM bank?
	rom_selftest_done (sim);
      break;
    }

  sim->cycle_count++;

  act_reg->display_scan_fn (sim);

  return (true);  /* never sleeps */
}


static bool woodstock_execute_instruction (sim_t *sim)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  do
    {
      if (! woodstock_execute_cycle (sim))
	return false;
    }
  while (act_reg->inst_state != norm);
  return true;
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
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  act_reg->key_buf = keycode;
  act_reg->key_flag = true;
}

static void woodstock_release_key (sim_t *sim)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  act_reg->key_flag = false;
}

static void woodstock_set_ext_flag (sim_t *sim, int flag, bool state)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  act_reg->ext_flag [flag] = state;
}



static bool woodstock_read_ram (sim_t *sim, int addr, uint64_t *val)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  uint64_t data = 0;
  int i;
  bool status;

  if (addr >= sim->max_ram)
    {
      status = false;
      // warning ("woodstock_read_ram: address %d out of range\n", addr);
    }
  else
    {
      // pack act_reg->ram [addr] into data
      for (i = WSIZE - 1; i >= 0; i--)
	{
	  data <<= 4;
	  data += act_reg->ram [addr] [i];
	}
      status = true;
    }

  *val = data;

  return status;
}


static bool woodstock_write_ram (sim_t *sim, int addr, uint64_t *val)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  uint64_t data;
  int i;

  if (addr >= sim->max_ram)
    {
      warning ("woodstock_write_ram: address %d out of range\n", addr);
      return false;
    }

  data = *val;

  // now unpack data into act_reg->ram [addr]
  for (i = 0; i <= WSIZE; i++)
    {
      act_reg->ram [addr] [i] = data & 0x0f;
      data >>= 4;
    }

  return true;
}


static void woodstock_reset (sim_t *sim)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  sim->cycle_count = 0;

  act_reg->decimal = true;

  act_reg->pc = 0;
  act_reg->del_rom_flag = 0;

  act_reg->inst_state = norm;

  act_reg->sp = 0;

  op_clear_reg (sim, 0);
  op_clear_s (sim, 0);
  act_reg->p = 0;

  act_reg->display_enable = 0;
  act_reg->display_digit_position = 0;
  act_reg->display_scan_position = WSIZE - 1;

  act_reg->key_buf = -1;  // no key has been pressed
  act_reg->key_flag = 0;

  if (sim->platform == PLATFORM_WOODSTOCK)  // but not PLATFORM_TOPCAT
    act_reg->ext_flag [5] = 1;  // force battery ok
}


static void woodstock_clear_memory (sim_t *sim)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  int addr;

  for (addr = 0; addr < sim->max_ram; addr++)
    reg_zero (act_reg->ram [addr], 0, WSIZE - 1);
}


static void woodstock_new_rom_addr_space (sim_t *sim,
					  int max_bank,
					  int max_page,
					  int page_size)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  size_t max_words;

  max_words = max_bank * max_page * page_size;

  act_reg->rom = alloc (max_words * sizeof (rom_word_t));
  act_reg->rom_exists = alloc (max_words * sizeof (bool));
  act_reg->rom_breakpoint = alloc (max_words * sizeof (bool));
}


static void woodstock_new_ram_addr_space (sim_t *sim, int max_ram)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  sim->max_ram = max_ram;
  act_reg->ram = alloc (max_ram * sizeof (reg_t));
}


static void woodstock_new_processor (sim_t *sim, int ram_size)
{
  act_reg_t *act_reg;

  act_reg = alloc (sizeof (act_reg_t));

  install_chip (sim, & woodstock_cpu_chip_detail, act_reg);

  woodstock_new_rom_addr_space (sim, MAX_BANK, MAX_PAGE, PAGE_SIZE);
  woodstock_new_ram_addr_space (sim, ram_size);

  switch (sim->platform)
    {
    case PLATFORM_WOODSTOCK:
    case PLATFORM_TOPCAT:
      // default to twelve digits, but RESET TWF instruction switches to
      // fourteen digits plus special case for sign
      sim->display_digits = MAX_DIGIT_POSITION;
      act_reg->display_scan_fn = woodstock_display_scan;
      act_reg->left_scan = WSIZE - 1;
      act_reg->right_scan = 2;
      break;
    case PLATFORM_SPICE:
      // ten digits plus special-case for sign
      sim->display_digits = MAX_DIGIT_POSITION;
      act_reg->display_scan_fn = spice_display_scan;
      act_reg->left_scan = WSIZE - 2;
      act_reg->right_scan = 3;
      break;
    default:
      fatal (2, "Woodstock arch doesn't know how to handle display for platform %s\n", platform_name [sim->platform]);
    }

  act_reg->display_scan_position = act_reg->left_scan;
  act_reg->display_digit_position = 0;

  init_ops (act_reg);

  chip_event (sim, event_reset, NULL, 0, NULL);
}


static void woodstock_free_processor (sim_t *sim)
{
  remove_chip (sim->first_chip);
}


static void woodstock_event_fn (sim_t  *sim,
				chip_t *chip UNUSED,
				int    event,
				int    arg   UNUSED,
				void   *data UNUSED)
{
  // act_reg_t *act_reg = get_chip_data (sim->first_chip);

  switch (event)
    {
    case event_reset:
       woodstock_reset (sim);
       break;
    case event_clear_memory:
       woodstock_clear_memory (sim);
       break;
    case event_restore_completed:
      // force display update
      break;
    default:
      // warning ("proc_woodstock: unknown event %d\n", event);
      break;
    }
}


processor_dispatch_t woodstock_processor =
  {
    .max_rom             = 4096,
    .max_bank            = 2, 

    .new_processor       = woodstock_new_processor,
    .free_processor      = woodstock_free_processor,

    .parse_object_line   = woodstock_parse_object_line,
    .parse_listing_line  = woodstock_parse_listing_line,

    .execute_cycle       = woodstock_execute_cycle,
    .execute_instruction = woodstock_execute_instruction,

    .press_key           = woodstock_press_key,
    .release_key         = woodstock_release_key,
    .set_ext_flag        = woodstock_set_ext_flag,

    .set_bank_group      = NULL,
    .get_max_rom_bank    = woodstock_get_max_rom_bank,
    .get_rom_page_size   = woodstock_get_rom_page_size,
    .get_max_rom_addr    = woodstock_get_max_rom_addr,
    .page_exists         = woodstock_page_exists,
    .read_rom            = woodstock_read_rom,
    .write_rom           = woodstock_write_rom,

    .read_ram            = woodstock_read_ram,
    .write_ram           = woodstock_write_ram,

    .disassemble         = woodstock_disassemble,
    .print_state         = woodstock_print_state
  };
