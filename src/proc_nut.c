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
#include "coconut_lcd.h"
#include "voyager_lcd.h"
#include "proc_nut.h"
#include "dis_nut.h"


static void print_reg (reg_t reg);


#undef WARN_STRAY_WRITE


#define NR(name, field, bits, radix, get, set, arg) \
    {{ name, bits, 1, radix },                      \
     OFFSET_OF (nut_reg_t, field),                  \
     SIZE_OF (nut_reg_t, field),                    \
     get, set, arg } 


#define NRA(name, field, bits, radix, get, set, arg, array) \
    {{ name, bits, array, radix },                          \
     OFFSET_OF (nut_reg_t, field[0]),                       \
     SIZE_OF (nut_reg_t, field[0]),                         \
     get, set, arg } 


#define NRD(name, field, digits)      \
    {{ name, digits * 4, 1, 16 },     \
     OFFSET_OF (nut_reg_t, field),    \
     SIZE_OF (nut_reg_t, field),      \
     get_digits, set_digits, digits } 


static reg_detail_t nut_cpu_reg_detail [] =
{
  //   name     field  digits
  NRD ("a",     a,     WSIZE),
  NRD ("b",     b,     WSIZE),
  NRD ("c",     c,     WSIZE),
  NRD ("m",     m,     WSIZE),
  NRD ("n",     n,     WSIZE),

  NRD ("g",     g,     2),

  //   name       field    bits   radix get        set        arg
  NR  ("p",       p,       4,     16,   NULL,      NULL,      0),
  NR  ("q",       q,       4,     16,   NULL,      NULL,      0),
  NR  ("q_sel",   q_sel,   1,      2,   NULL,      NULL,      0),
  NR  ("fo",      fo,      8,     16,   NULL,      NULL,      0),
  NR  ("s",       s,       SSIZE,  2,   get_bools, set_bools, SSIZE),
  NR  ("pc",      pc,      16,    16,   NULL,      NULL,      0),
  // prev_pc
  NRA ("stack",   stack,   16,    16,   NULL,      NULL,      0, STACK_DEPTH ),
  NR  ("decimal", decimal, 1,      2,   NULL,      NULL,      0),
  NR  ("carry",   carry,   1,      2,   NULL,      NULL,      0),
  NR  ("awake",   awake,   1,      2,   NULL,      NULL,      0),
  // inst_state
  // first_word
  // cxisa_addr
  // long_branch_carry
  // prev_carry
  // key_down
  // key_flag
  // key_buf
  NR  ("pf_addr", pf_addr, 8,     16,   NULL,      NULL,      0),
  NR  ("ram_addr", ram_addr, 10,  16,   NULL,      NULL,      0),
  NRA ("active_bank", active_bank, 2, 16, NULL, NULL, 0, MAX_PAGE)
};


static chip_event_fn_t nut_event_fn;


static chip_detail_t nut_cpu_chip_detail =
{
  {
    "Nut",
    0
  },
  sizeof (nut_cpu_reg_detail) / sizeof (reg_detail_t),
  nut_cpu_reg_detail,
  nut_event_fn
};


/* map from high opcode bits to register index */
static int tmap [16] =
{ 3, 4, 5, 10, 8, 6, 11, -1, 2, 9, 7, 13, 1, 12, 0, -1 };

/* map from register index to high opcode bits */
static int itmap [WSIZE] =
{ 0xe, 0xc, 0x8, 0x0, 0x1, 0x2, 0x5, 0xa, 0x4, 0x9, 0x3, 0x6, 0xd, 0xb };


static rom_word_t nut_get_ucode (nut_reg_t *nut_reg, rom_addr_t addr)
{
  uint8_t page = addr / PAGE_SIZE;
  uint8_t bank = nut_reg->active_bank [page];
  uint16_t offset = addr & (PAGE_SIZE - 1);

  if (nut_reg->rom [page][bank])
    return nut_reg->rom [page][bank][offset];
  else
     return 0;  // non-existent memory
}


static void nut_set_ucode (nut_reg_t *nut_reg,
			   rom_addr_t addr,
			   rom_word_t data)
{
  uint8_t page = addr / PAGE_SIZE;
  uint8_t bank = nut_reg->active_bank [page];
  uint16_t offset = addr & (PAGE_SIZE - 1);

  if (! nut_reg->rom [page][bank])
    {
      fprintf (stderr, "write to nonexistent ROM location %04x (bank %d)\n", addr, bank);
      return;
    }
  if (! nut_reg->rom_writeable [page][bank])
    {
      fprintf (stderr, "write to non-writeable ROM location %04x (bank %d)\n", addr, bank);
      return;
    }
  nut_reg->rom [page][bank][offset] = data;
}


static bool nut_read_rom (sim_t      *sim,
			  uint8_t    bank,
			  addr_t     addr,
			  rom_word_t *val)
{
  nut_reg_t *nut_reg = sim->chip_data [0];
  uint8_t page;
  uint16_t offset;

  if ((addr >= (MAX_PAGE * PAGE_SIZE)) || (bank > MAX_BANK))
    return false;

  page = addr / PAGE_SIZE;
  offset = addr & (PAGE_SIZE - 1);

  if (! nut_reg->rom [page][bank])
    return false;

  *val = nut_reg->rom [page][bank][offset];
  return true;
}


static bool nut_write_rom (sim_t      *sim,
			   uint8_t    bank,
			   addr_t     addr,
			   rom_word_t *val)
{
  nut_reg_t *nut_reg = sim->chip_data [0];
  uint8_t page;
  uint16_t offset;

  if ((addr >= (MAX_PAGE * PAGE_SIZE)) || (bank > MAX_BANK))
    return false;

  page = addr / PAGE_SIZE;
  offset = addr & (PAGE_SIZE - 1);

  if (! nut_reg->rom [page][bank])  // does the page/bank exist?
    {
      // no, allocate a new page
      nut_reg->rom [page][bank] = alloc (PAGE_SIZE * sizeof (rom_word_t));
      nut_reg->rom_breakpoint [page][bank] = alloc (PAGE_SIZE * sizeof (bool));
    }

  nut_reg->rom [page][bank][offset] = *val;
  return true;
}


static inline uint8_t arithmetic_base (nut_reg_t *nut_reg)
{
  return nut_reg->decimal ? 10 : 16;
}


static inline uint8_t *pt (nut_reg_t *nut_reg)
{
  return nut_reg->q_sel ? & nut_reg->q : & nut_reg->p;
}


static void nut_print_state (sim_t *sim);


static void bad_op (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  printf ("illegal opcode %03x at %04x\n", opcode, nut_reg->prev_pc);
}


static void op_arith (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];
  int op, field;
  int first, last;

  op = opcode >> 5;
  field = (opcode >> 2) & 7;

  switch (field)
    {
    case 0:  /* p  */  first = *pt (nut_reg);  last = *pt (nut_reg);  break;
    case 1:  /* x  */  first = 0;              last = EXPSIZE - 1;    break;
    case 2:  /* wp */  first = 0;              last = *pt (nut_reg);  break;
    case 3:  /* w  */  first = 0;              last = WSIZE - 1;      break;
    case 4:  /* pq */  first = nut_reg->p;     last = nut_reg->q;
      if (first > last)
	last = WSIZE - 1;
      break;
    case 5:  /* xs */  first = EXPSIZE - 1;    last = EXPSIZE - 1;    break;
    case 6:  /* m  */  first = EXPSIZE;        last = WSIZE - 2;      break;
    case 7:  /* s  */  first = WSIZE - 1;      last = WSIZE - 1;      break;
    }

  nut_reg->prev_tef_last = last;

  switch (op)
    {
    case 0x00:  /* a=0 */
      reg_zero (nut_reg->a, first, last);
      break;

    case 0x01:  /* b=0 */
      reg_zero (nut_reg->b, first, last);
      break;

    case 0x02:  /* c=0 */
      reg_zero (nut_reg->c, first, last);
      break;

    case 0x03:  /* ab ex */
      reg_exch (nut_reg->a, nut_reg->b, first, last);
      break;

    case 0x04:  /* b=a */
      reg_copy (nut_reg->b, nut_reg->a, first, last);
      break;

    case 0x05:  /* ac ex */
      reg_exch (nut_reg->a, nut_reg->c, first, last);
      break;

    case 0x06:  /* c=b */
      reg_copy (nut_reg->c, nut_reg->b, first, last);
      break;

    case 0x07:  /* bc ex */
      reg_exch (nut_reg->b, nut_reg->c, first, last);
      break;

    case 0x08:  /* a=c */
      reg_copy (nut_reg->a, nut_reg->c, first, last);
      break;

    case 0x09:  /* a=a+b */
      reg_add (nut_reg->a, nut_reg->a, nut_reg->b,
	       first, last,
	       & nut_reg->carry, arithmetic_base (nut_reg));
      break;

    case 0x0a:  /* a=a+c */
      reg_add (nut_reg->a, nut_reg->a, nut_reg->c,
	       first, last,
	       & nut_reg->carry, arithmetic_base (nut_reg));
      break;

    case 0x0b:    /* a=a+1 */
      nut_reg->carry = 1;
      reg_add (nut_reg->a, nut_reg->a, NULL,
	       first, last,
	       & nut_reg->carry, arithmetic_base (nut_reg));
      break;

    case 0x0c:  /* a=a-b */
      reg_sub (nut_reg->a, nut_reg->a, nut_reg->b,
	       first, last,
	       & nut_reg->carry, arithmetic_base (nut_reg));
      break;

    case 0x0d:  /* a=a-1 */
      nut_reg->carry = 1;
      reg_sub (nut_reg->a, nut_reg->a, NULL,
	       first, last,
	       & nut_reg->carry, arithmetic_base (nut_reg));
      break;

    case 0x0e:  /* a=a-c */
      reg_sub (nut_reg->a, nut_reg->a, nut_reg->c,
	       first, last,
	       & nut_reg->carry, arithmetic_base (nut_reg));
      break;

    case 0x0f:  /* c=c+c */
      reg_add (nut_reg->c, nut_reg->c, nut_reg->c,
	       first, last,
	       & nut_reg->carry, arithmetic_base (nut_reg));
      break;

    case 0x10:  /* c=a+c */
      reg_add (nut_reg->c, nut_reg->a, nut_reg->c,
	       first, last,
	       & nut_reg->carry, arithmetic_base (nut_reg));
      break;

    case 0x11:  /* c=c+1 */
      nut_reg->carry = 1;
      reg_add (nut_reg->c, nut_reg->c, NULL,
	       first, last,
	       & nut_reg->carry, arithmetic_base (nut_reg));
      break;

    case 0x12:  /* c=a-c */
      reg_sub (nut_reg->c, nut_reg->a, nut_reg->c,
	       first, last,
	       & nut_reg->carry, arithmetic_base (nut_reg));
      break;

    case 0x13:  /* c=c-1 */
      nut_reg->carry = 1;
      reg_sub (nut_reg->c, nut_reg->c, NULL,
	       first, last,
	       & nut_reg->carry, arithmetic_base (nut_reg));
      break;

    case 0x14:  /* c=-c */
      reg_sub (nut_reg->c, NULL, nut_reg->c,
	       first, last,
	       & nut_reg->carry, arithmetic_base (nut_reg));
      break;

    case 0x15:  /* c=-c-1 */
      nut_reg->carry = 1;
      reg_sub (nut_reg->c, NULL, nut_reg->c,
	       first, last,
	       & nut_reg->carry, arithmetic_base (nut_reg));
      break;

    case 0x16:  /* ? b<>0 */
      reg_test_nonequal (nut_reg->b, NULL,
			 first, last,
			 & nut_reg->carry);
      break;

    case 0x17:  /* ? c<>0 */
      reg_test_nonequal (nut_reg->c, NULL,
			 first, last,
			 & nut_reg->carry);
      break;

    case 0x18:  /* ? a<c */
      reg_sub (NULL, nut_reg->a, nut_reg->c,
	       first, last,
	       & nut_reg->carry, arithmetic_base (nut_reg));
      break;

    case 0x19:  /* ? a<b */
      reg_sub (NULL, nut_reg->a, nut_reg->b,
	       first, last,
	       & nut_reg->carry, arithmetic_base (nut_reg));
      break;

    case 0x1a:  /* ? a<>0 */
      reg_test_nonequal (nut_reg->a, NULL,
			 first, last,
			 & nut_reg->carry);
      break;

    case 0x1b:  /* ? a<>c */
      reg_test_nonequal (nut_reg->a, nut_reg->c,
			 first, last,
			 & nut_reg->carry);
      break;

    case 0x1c:  /* a sr */
      reg_shift_right (nut_reg->a, first, last);
      break;

    case 0x1d:  /* b sr */
      reg_shift_right (nut_reg->b, first, last);
      break;

    case 0x1e:  /* c sr */
      reg_shift_right (nut_reg->c, first, last);
      break;

    case 0x1f:  /* a sl */
      reg_shift_left (nut_reg->a, first, last);
      break;
    }
}


/*
 * stack operations
 */

static rom_addr_t pop (sim_t *sim)
{
  nut_reg_t *nut_reg = sim->chip_data [0];
  int i;
  rom_addr_t ret;

  ret = nut_reg->stack [0];
  for (i = 0; i < STACK_DEPTH - 1; i++)
    nut_reg->stack [i] = nut_reg->stack [i + 1];
  nut_reg->stack [STACK_DEPTH - 1] = 0;
  return (ret);
}

static void push (sim_t *sim, rom_addr_t a)
{
  nut_reg_t *nut_reg = sim->chip_data [0];
  int i;

  for (i = STACK_DEPTH - 1; i > 0; i--)
    nut_reg->stack [i] = nut_reg->stack [i - 1];
  nut_reg->stack [0] = a;
}

static void op_return (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  nut_reg->pc = pop (sim);
}

static void op_return_if_carry (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  if (nut_reg->prev_carry)
    nut_reg->pc = pop (sim);
}

static void op_return_if_no_carry (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  if (! nut_reg->prev_carry)
    nut_reg->pc = pop (sim);
}

static void op_pop (sim_t *sim, int opcode)
{
  (void) pop (sim);
}

static void op_pop_c (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];
  rom_addr_t a;

  a = pop (sim);
  nut_reg->c [6] = a >> 12;
  nut_reg->c [5] = (a >> 8) & 0x0f;
  nut_reg->c [4] = (a >> 4) & 0x0f;
  nut_reg->c [3] = a & 0x0f;
}


static void op_push_c (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  push (sim, ((nut_reg->c [6] << 12) |
	      (nut_reg->c [5] << 8) |
	      (nut_reg->c [4] << 4) |
	      (nut_reg->c [3])));
}


//
// branch operations
//

static void op_short_branch (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];
  int offset;

  offset = (opcode >> 3) & 0x3f;
  if (opcode & 0x200)
    offset -= 64;

  if (((opcode >> 2) & 1) == nut_reg->prev_carry)
    nut_reg->pc = nut_reg->pc + offset - 1;
}


static void op_long_branch (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  nut_reg->inst_state = long_branch;
  nut_reg->first_word = opcode;
  nut_reg->long_branch_carry = nut_reg->prev_carry;
}


static void op_long_branch_word_2 (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];
  rom_addr_t target;

  nut_reg->inst_state = norm;
  target = (nut_reg->first_word >> 2) | ((opcode & 0x3fc) << 6);

  if ((opcode & 0x001) == nut_reg->long_branch_carry)
    {
      if (opcode & 0x002)
	nut_reg->pc = target;
      else
	{
	  push (sim, nut_reg->pc);
	  nut_reg->pc = target;
	  if (nut_get_ucode (nut_reg, nut_reg->pc) == 0)
	    nut_reg->pc = pop (sim);
	}
    }
}


static void op_goto_c (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  nut_reg->pc = ((nut_reg->c [6] << 12) |
		  (nut_reg->c [5] << 8) |
		  (nut_reg->c [4] << 4) | 
		  (nut_reg->c [3]));
}


// Bank selection used in 41CX, Advantage ROM, and perhaps others

static void select_bank (sim_t *sim, rom_addr_t addr, uint8_t bank)
{
  nut_reg_t *nut_reg = sim->chip_data [0];
  uint8_t page = addr / PAGE_SIZE;

  if (nut_reg->rom [page][bank])
    nut_reg->active_bank [page] = bank;
}


static void op_enbank (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  select_bank (sim, nut_reg->prev_pc, ((opcode >> 6) & 2) + ((opcode >> 7) & 1));
}


/*
 * m operations
 */

static void op_c_to_m (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  reg_copy (nut_reg->m, nut_reg->c, 0, WSIZE - 1);
}

static void op_m_to_c (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  reg_copy (nut_reg->c, nut_reg->m, 0, WSIZE - 1);
}

static void op_c_exch_m (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  reg_exch (nut_reg->c, nut_reg->m, 0, WSIZE - 1);
}


/*
 * n operations
 */

static void op_c_to_n (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  reg_copy (nut_reg->n, nut_reg->c, 0, WSIZE - 1);
}

static void op_n_to_c (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  reg_copy (nut_reg->c, nut_reg->n, 0, WSIZE - 1);
}

static void op_c_exch_n (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  reg_exch (nut_reg->c, nut_reg->n, 0, WSIZE - 1);
}


/*
 * RAM and peripheral operations
 */

static void nut_ram_read_zero (nut_reg_t *nut_reg, int addr, reg_t *reg)
{
  int i;
  for (i = 0; i < WSIZE; i++)
    (*reg) [i] = 0;
}


static void nut_ram_write_ignore (nut_reg_t *nut_reg, int addr, reg_t *reg)
{
  ;
}

static void op_c_to_dadd (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  nut_reg->ram_addr = ((nut_reg->c [2] << 8) | 
			(nut_reg->c [1] << 4) |
			(nut_reg->c [0])) & 0x3ff;
}

static void op_c_to_pfad (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  nut_reg->pf_addr = ((nut_reg->c [1] << 4) |
		       (nut_reg->c [0]));
}

static void op_read_reg_n (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];
  uint16_t ram_addr;
  uint8_t pf_addr;
  int i;
  int is_ram, is_pf;

  for (i = 0; i < WSIZE; i++)
    nut_reg->c [i] = 0;

  if ((opcode >> 6) != 0)
    nut_reg->ram_addr = (nut_reg->ram_addr & ~0x0f) | (opcode >> 6);

  ram_addr = nut_reg->ram_addr;
  pf_addr = nut_reg->pf_addr;

  is_ram = nut_reg->ram_exists [ram_addr];
  is_pf  = nut_reg->pf_exists  [pf_addr];

  if (is_ram && is_pf)
    {
      printf ("warning: conflicting read RAM %03x PF %02x reg %01x\n",
	      ram_addr, pf_addr, opcode >> 6);
    }
  if (is_ram)
    {
      if (nut_reg->ram_read_fn [ram_addr])
        nut_reg->ram_read_fn [ram_addr] (nut_reg, ram_addr, & nut_reg->c);
      else
        for (i = 0; i < WSIZE; i++)
	  nut_reg->c [i] = nut_reg->ram [ram_addr][i];
    }
  else if (is_pf)
    {
      if (nut_reg->rd_n_fcn [pf_addr])
	(*nut_reg->rd_n_fcn [pf_addr]) (sim, opcode >> 6);
    }
  else
    {
      printf ("warning: stray read RAM %03x PF %02x reg %01x\n",
	      ram_addr, pf_addr, opcode >> 6);
    }
}


static void op_write_reg_n (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];
  uint16_t ram_addr;
  uint8_t pf_addr;
  int i;
  int is_ram, is_pf;

  nut_reg->ram_addr = (nut_reg->ram_addr & ~0x0f) | (opcode >> 6);

  ram_addr = nut_reg->ram_addr;
  pf_addr = nut_reg->pf_addr;

  is_ram = nut_reg->ram_exists [ram_addr];
  is_pf  = nut_reg->pf_exists  [pf_addr];

  if (is_ram && is_pf)
    {
      printf ("warning: conflicting write RAM %03x PF %02x reg %01x\n",
	      ram_addr, pf_addr, opcode >> 6);
    }
  else if ((! is_ram) && (! is_pf))
    {
#ifdef WARN_STRAY_WRITE
      printf ("warning: stray write RAM %03x PF %02x reg %01x data ",
	      ram_addr, pf_addr, opcode >> 6);
      print_reg (nut_reg->c);
      printf ("\n");
#endif
    }
  if (is_ram)
    {
      if (nut_reg->ram_write_fn [ram_addr])
        nut_reg->ram_write_fn [ram_addr] (nut_reg, ram_addr, & nut_reg->c);
      else
	for (i = 0; i < WSIZE; i++)
	  nut_reg->ram [ram_addr][i] = nut_reg->c [i];
    }
  if (is_pf)
    {
      if (nut_reg->wr_n_fcn [pf_addr])
	(*nut_reg->wr_n_fcn [pf_addr]) (sim, opcode >> 6);
    }
}

static void op_c_to_data (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];
  uint16_t ram_addr;
  uint8_t pf_addr;
  int i;
  int is_ram, is_pf;

  ram_addr = nut_reg->ram_addr;
  pf_addr = nut_reg->pf_addr;

  is_ram = nut_reg->ram_exists [ram_addr];
  is_pf  = nut_reg->pf_exists  [pf_addr];

  if (is_ram && is_pf)
    {
      printf ("warning: conflicting write RAM %03x PF %02x\n",
	      ram_addr, pf_addr);
    }
  else if ((! is_ram) && (! is_pf))
    {
#ifdef WARN_STRAY_WRITE
      printf ("warning: stray write RAM %03x PF %02x data ",
	      ram_addr, pf_addr);
      print_reg (nut_reg->c);
      printf ("\n");
#endif
    }
  if (is_ram)
    {
      if (nut_reg->ram_write_fn [ram_addr])
        nut_reg->ram_write_fn [ram_addr] (nut_reg, ram_addr, & nut_reg->c);
      else
        for (i = 0; i < WSIZE; i++)
          nut_reg->ram [ram_addr][i] = nut_reg->c [i];
    }
  if (is_pf)
    {
      if (nut_reg->wr_fcn [pf_addr])
	(*nut_reg->wr_fcn [pf_addr]) (sim);
    }
}

static void op_test_ext_flag (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  nut_reg->carry = 0;  /* no periphs yet */
}

/*
 * s operations
 */

static void op_set_s (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  nut_reg->s [tmap [opcode >> 6]] = 1;
}

static void op_clr_s (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  nut_reg->s [tmap [opcode >> 6]] = 0;
}

static void op_test_s (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  nut_reg->carry = nut_reg->s [tmap [opcode >> 6]];
}

static int get_s_bits (sim_t *sim, int first, int count)
{
  nut_reg_t *nut_reg = sim->chip_data [0];
  int i;
  int mask = 1;
  int r = 0;
  for (i = first; i < first + count; i++)
    {
      if (nut_reg->s [i])
	r = r + mask;
      mask <<= 1;
    }
  return (r);
}

static void set_s_bits (sim_t *sim, int first, int count, int a)
{
  nut_reg_t *nut_reg = sim->chip_data [0];
  int i;
  int mask = 1;

  for (i = first; i < first + count; i++)
    {
      nut_reg->s [i] = (a & mask) != 0;
      mask <<= 1;
    }
}

static void op_clear_all_s (sim_t *sim, int opcode)
{
  set_s_bits (sim, 0, 8, 0);
}

static void op_c_to_s (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  set_s_bits (sim, 0, 4, nut_reg->c [0]);
  set_s_bits (sim, 4, 4, nut_reg->c [1]);
}

static void op_s_to_c (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  nut_reg->c [0] = get_s_bits (sim, 0, 4);
  nut_reg->c [1] = get_s_bits (sim, 4, 4);
}

static void op_c_exch_s (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];
  int t;

  t = get_s_bits (sim, 0, 4);
  set_s_bits (sim, 0, 4, nut_reg->c [0]);
  nut_reg->c [0] = t;
  t = get_s_bits (sim, 4, 4);
  set_s_bits (sim, 4, 4, nut_reg->c [1]);
  nut_reg->c [1] = t;
}

static void op_sb_to_f (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  nut_reg->fo = get_s_bits (sim, 0, 8);
}

static void op_f_to_sb (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  set_s_bits (sim, 0, 8, nut_reg->fo);
}

static void op_f_exch_sb (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];
  int t;

  t = get_s_bits (sim, 0, 8);
  set_s_bits (sim, 0, 8, nut_reg->fo);
  nut_reg->fo = t;
}

/*
 * pointer operations
 */

static void op_dec_pt (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  (*pt (nut_reg))--;
  if ((*pt (nut_reg)) >= WSIZE)  // can't be negative because it is unsigned
    (*pt (nut_reg)) = WSIZE - 1;
}

static void op_inc_pt (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  (*pt (nut_reg))++;
  if ((*pt (nut_reg)) >= WSIZE)
    (*pt (nut_reg)) = 0;
}

static void op_set_pt (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  (*pt (nut_reg)) = tmap [opcode >> 6];
}

static void op_test_pt (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  nut_reg->carry = ((*pt (nut_reg)) == tmap [opcode >> 6]);
}

static void op_sel_p (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  nut_reg->q_sel = false;
}

static void op_sel_q (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  nut_reg->q_sel = true;
}

static void op_test_pq (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  if (nut_reg->p == nut_reg->q)
    nut_reg->carry = 1;
}

static void op_lc (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  nut_reg->c [(*pt (nut_reg))--] = opcode >> 6;
  if ((*pt (nut_reg)) >= WSIZE)  /* unsigned, can't be negative */
    *pt (nut_reg) = WSIZE - 1;
}

static void op_c_to_g (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  nut_reg->g [0] = nut_reg->c [*pt (nut_reg)];
  if ((*pt (nut_reg)) == (WSIZE - 1))
    {
      nut_reg->g [1] = 0;
#ifdef WARNING_G
      fprintf (stderr, "warning: c to g transfer with pt=13\n");
#endif
    }
  else
    nut_reg->g [1] = nut_reg->c [(*pt (nut_reg)) + 1];
}

static void op_g_to_c (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  nut_reg->c [(*pt (nut_reg))] = nut_reg->g [0];
  if ((*pt (nut_reg)) == (WSIZE - 1))
    {
      ;
#ifdef WARNING_G
      fprintf (stderr, "warning: g to c transfer with pt=13\n");
#endif
    }
  else
    {
      nut_reg->c [(*pt (nut_reg)) + 1] = nut_reg->g [1];
    }
    
}

static void op_c_exch_g (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];
  int t;

  t = nut_reg->g [0];
  nut_reg->g [0] = nut_reg->c [*pt (nut_reg)];
  nut_reg->c [*pt (nut_reg)] = t;
  if ((*pt (nut_reg)) == (WSIZE - 1))
    {
      nut_reg->g [1] = 0;
#ifdef WARNING_G
      fprintf (stderr, "warning: c exchange g with pt=13\n");
#endif
    }
  else
    {
      t = nut_reg->g [1];
      nut_reg->g [1] = nut_reg->c [(*pt (nut_reg)) + 1];
      nut_reg->c [(*pt (nut_reg)) + 1] = t;
    }
}


/*
 * keyboard operations
 */

static void op_keys_to_rom_addr (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  nut_reg->pc = (nut_reg->pc & 0xff00) | nut_reg->key_buf;
}


#ifdef VOYAGER_SELF_TEST_KEY_HACK
static int kp = 0;
static uint8_t keys [] = { 0x18, 0x17 };
#endif


static void op_keys_to_c (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

#ifdef VOYAGER_SELF_TEST_KEY_HACK
  nut_reg->c [4] = keys [kp] >> 4; /* nut_reg->key_buf >> 4; */
  nut_reg->c [3] = keys [kp] & 0xf; /* nut_reg->key_buf & 0x0f; */
  kp++;
  if (kp == sizeof (keys))
    kp = 0;
#else
  nut_reg->c [4] = nut_reg->key_buf >> 4;
  nut_reg->c [3] = nut_reg->key_buf & 0x0f;
#endif
}

static void op_test_kb (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  nut_reg->carry = nut_reg->key_flag;
}

static void op_reset_kb (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  nut_reg->key_flag = nut_reg->key_down;
}


/*
 * misc. operations
 */

static void op_nop (sim_t *sim, int opcode)
{
}

static void op_set_hex (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  nut_reg->decimal = false;
}

static void op_set_dec (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  nut_reg->decimal = true;
}

static void op_rom_to_c (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  nut_reg->cxisa_addr = ((nut_reg->c [6] << 12) |
			  (nut_reg->c [5] << 8) |
			  (nut_reg->c [4] << 4) |
			  (nut_reg->c [3]));
  nut_reg->inst_state = cxisa;
}

static void op_rom_to_c_cycle_2 (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  nut_reg->c [2] = opcode >> 8;
  nut_reg->c [1] = (opcode >> 4) & 0x0f;
  nut_reg->c [0] = opcode & 0x0f;

  nut_reg->inst_state = norm;
}

static void op_clear_abc (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  reg_zero (nut_reg->a, 0, WSIZE - 1);
  reg_zero (nut_reg->b, 0, WSIZE - 1);
  reg_zero (nut_reg->c, 0, WSIZE - 1);
}

static void op_ldi (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  nut_reg->inst_state = ldi;
}

static void op_ldi_cycle_2 (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  nut_reg->c [2] = opcode >> 8;
  nut_reg->c [1] = (opcode >> 4) & 0x0f;
  nut_reg->c [0] = opcode & 0x00f;

  nut_reg->inst_state = norm;
}

static void op_or (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];
  int i;

  for (i = 0; i < WSIZE; i++)
    nut_reg->c [i] |= nut_reg->a [i];
  if (nut_reg->prev_carry && (nut_reg->prev_tef_last == (WSIZE - 1)))
    {
      nut_reg->c [WSIZE - 1] = nut_reg->c [0];
      nut_reg->a [WSIZE - 1] = nut_reg->c [0];
    }
}

static void op_and (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];
  int i;

  for (i = 0; i < WSIZE; i++)
    nut_reg->c [i] &= nut_reg->a [i];
  if (nut_reg->prev_carry && (nut_reg->prev_tef_last == (WSIZE - 1)))
    {
      nut_reg->c [WSIZE - 1] = nut_reg->c [0];
      nut_reg->a [WSIZE - 1] = nut_reg->c [0];
    }
}

static void op_rcr (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];
  int i, j;
  reg_t t;

  j = tmap [opcode >> 6];
  for (i = 0; i < WSIZE; i++)
    {
      t [i] = nut_reg->c [j++];
      if (j >= WSIZE)
	j = 0;
    }
  for (i = 0; i < WSIZE; i++)
    nut_reg->c [i] = t [i];
}

static void op_lld (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  nut_reg->carry = 0;  /* "batteries" are fine */
}

static void op_powoff (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

#ifdef SLEEP_DEBUG
  printf ("going to sleep!\n");
#endif
  nut_reg->awake = false;
  nut_reg->pc = 0;
  chip_event (sim, event_sleep);
}


static void nut_init_ops (nut_reg_t *nut_reg)
{
  int i;

  for (i = 0; i < 1024; i += 4)
    {
      nut_reg->op_fcn [i + 0] = bad_op;
      nut_reg->op_fcn [i + 1] = op_long_branch;
      nut_reg->op_fcn [i + 2] = op_arith;  /* type 2: ooooowww10 */
      nut_reg->op_fcn [i + 3] = op_short_branch;
    }

  nut_reg->op_fcn [0x000] = op_nop;

  // nut_reg->op_fcn [0x040] = op_write_mldl;

  for (i = 0; i < 4; i++)
     nut_reg->op_fcn [0x100 + i * 0x040] = op_enbank;

  // for (i = 0; i < 8; i++)
  //   op_fcn [0x200 + (i << 6)] = op_write_pil;

  for (i = 0; i < WSIZE; i ++)
    {
      nut_reg->op_fcn [0x004 + (itmap [i] << 6)] = op_clr_s;
      nut_reg->op_fcn [0x008 + (itmap [i] << 6)] = op_set_s;
      nut_reg->op_fcn [0x00c + (itmap [i] << 6)] = op_test_s;
      nut_reg->op_fcn [0x014 + (itmap [i] << 6)] = op_test_pt;
      nut_reg->op_fcn [0x01c + (itmap [i] << 6)] = op_set_pt;
      nut_reg->op_fcn [0x02c + (itmap [i] << 6)] = op_test_ext_flag;
      nut_reg->op_fcn [0x03c + (itmap [i] << 6)] = op_rcr;
    }
  nut_reg->op_fcn [0x3c4] = op_clear_all_s;
  nut_reg->op_fcn [0x3c8] = op_reset_kb;
  nut_reg->op_fcn [0x3cc] = op_test_kb;
  nut_reg->op_fcn [0x3d4] = op_dec_pt;
  nut_reg->op_fcn [0x3dc] = op_inc_pt;
  // 0x3fc = LCD compensation

  for (i = 0; i < 16; i++)
    {
      nut_reg->op_fcn [0x010 + (i << 6)] = op_lc;
      // nut_reg->op_fcn [0x024 + (i << 6)] = op_selprf;
      nut_reg->op_fcn [0x028 + (i << 6)] = op_write_reg_n;
      nut_reg->op_fcn [0x038 + (i << 6)] = op_read_reg_n;
    }

  nut_reg->op_fcn [0x058] = op_c_to_g;
  nut_reg->op_fcn [0x098] = op_g_to_c;
  nut_reg->op_fcn [0x0d8] = op_c_exch_g;

  nut_reg->op_fcn [0x158] = op_c_to_m;
  nut_reg->op_fcn [0x198] = op_m_to_c;
  nut_reg->op_fcn [0x1d8] = op_c_exch_m;

  nut_reg->op_fcn [0x258] = op_sb_to_f;
  nut_reg->op_fcn [0x298] = op_f_to_sb;
  nut_reg->op_fcn [0x2d8] = op_f_exch_sb;

  nut_reg->op_fcn [0x358] = op_c_to_s;
  nut_reg->op_fcn [0x398] = op_s_to_c;
  nut_reg->op_fcn [0x3d8] = op_c_exch_s;

  nut_reg->op_fcn [0x020] = op_pop;
  nut_reg->op_fcn [0x060] = op_powoff;
  nut_reg->op_fcn [0x0a0] = op_sel_p;
  nut_reg->op_fcn [0x0e0] = op_sel_q;
  nut_reg->op_fcn [0x120] = op_test_pq;
  nut_reg->op_fcn [0x160] = op_lld;
  nut_reg->op_fcn [0x1a0] = op_clear_abc;
  nut_reg->op_fcn [0x1e0] = op_goto_c;
  nut_reg->op_fcn [0x220] = op_keys_to_c;
  nut_reg->op_fcn [0x260] = op_set_hex;
  nut_reg->op_fcn [0x2a0] = op_set_dec;
  // 0x2e0 = display off (Nut, Voyager)
  // 0x320 = display toggle (Nut, Voyager)
  nut_reg->op_fcn [0x360] = op_return_if_carry;
  nut_reg->op_fcn [0x3a0] = op_return_if_no_carry;
  nut_reg->op_fcn [0x3e0] = op_return;

  // 0x030 = display blink (Voyager)
  // 0x030 = ROMBLK (Hepax)
  nut_reg->op_fcn [0x070] = op_c_to_n;
  nut_reg->op_fcn [0x0b0] = op_n_to_c;
  nut_reg->op_fcn [0x0f0] = op_c_exch_n;
  nut_reg->op_fcn [0x130] = op_ldi;
  nut_reg->op_fcn [0x170] = op_push_c;
  nut_reg->op_fcn [0x1b0] = op_pop_c;
  // 0x1f0 = WPTOG (Hepax)
  nut_reg->op_fcn [0x230] = op_keys_to_rom_addr;
  nut_reg->op_fcn [0x270] = op_c_to_dadd;
  // nut_reg->op_fcn [0x2b0] = op_clear_regs;
  nut_reg->op_fcn [0x2f0] = op_c_to_data;
  nut_reg->op_fcn [0x330] = op_rom_to_c;
  nut_reg->op_fcn [0x370] = op_or;
  nut_reg->op_fcn [0x3b0] = op_and;
  nut_reg->op_fcn [0x3f0] = op_c_to_pfad;

}


static void nut_disassemble (sim_t *sim, int addr, char *buf, int len)
{
  nut_reg_t *nut_reg = sim->chip_data [0];
  int op1, op2;

  switch (nut_reg->inst_state)
    {
    case long_branch:   snprintf (buf, len, "(long branch)"); return;
    case cxisa:         snprintf (buf, len, "(cxisa)");       return;
    case ldi:           snprintf (buf, len, "(immediate)");   return;
    case norm:          break;
    }

  op1 = nut_get_ucode (nut_reg, addr);
  op2 = nut_get_ucode (nut_reg, addr + 1);

  nut_disassemble_inst (addr, op1, op2, buf, len);
}


static void print_reg (reg_t reg)
{
  int i;
  for (i = WSIZE - 1; i >= 0; i--)
    printf ("%x", reg [i]);
}


static void print_stat (sim_t *sim)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  int i;
  for (i = 0; i < SSIZE; i++)
    printf (nut_reg->s [i] ? "%x" : ".", i);
}


static void nut_print_state (sim_t *sim)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  printf ("cycle %5" PRId64 "  ", sim->cycle_count);
  printf ("%c=%x ", (nut_reg->q_sel) ? 'p' : 'P', nut_reg->p);
  printf ("%c=%x ", (nut_reg->q_sel) ? 'Q' : 'q', nut_reg->q);
  printf ("carry=%d ", nut_reg->carry);
  printf (" stat=");
  print_stat (sim);
  printf ("\n");
  printf (" a=");
  print_reg (nut_reg->a);
  printf (" b=");
  print_reg (nut_reg->b);
  printf (" c=");
  print_reg (nut_reg->c);
  printf ("\n");

  if (sim->source [nut_reg->prev_pc])
    printf ("%s\n", sim->source [nut_reg->prev_pc]);
  else
    {
      char buf [80];
      nut_disassemble (sim, nut_reg->prev_pc, buf, sizeof (buf));
      printf (" %s\n", buf);
    }
}

static bool nut_execute_cycle (sim_t *sim)
{
  nut_reg_t *nut_reg = sim->chip_data [0];
  int opcode;

  if (! nut_reg->awake)
    return (false);

  if (nut_reg->inst_state == cxisa)
    nut_reg->prev_pc = nut_reg->cxisa_addr;
  else
    nut_reg->prev_pc = nut_reg->pc;

  opcode = nut_get_ucode (nut_reg, nut_reg->prev_pc);

#ifdef HAS_DEBUGGER
  if (sim->debug_flags & (1 << SIM_DEBUG_TRACE))
    nut_print_state (sim);
#endif /* HAS_DEBUGGER */

  nut_reg->prev_carry = nut_reg->carry;
  nut_reg->carry = 0;

  switch (nut_reg->inst_state)
    {
    case norm:
      nut_reg->pc++;
      (* nut_reg->op_fcn [opcode]) (sim, opcode);
      break;
    case long_branch:
      nut_reg->pc++;
      op_long_branch_word_2 (sim, opcode);
      break;
    case cxisa:
      op_rom_to_c_cycle_2 (sim, opcode);
      break;
    case ldi:
      nut_reg->pc++;
      op_ldi_cycle_2 (sim, opcode);
      break;
    default:
      printf ("nut: bad inst_state %d!\n", nut_reg->inst_state);
      nut_reg->inst_state = norm;
      break;
    }
  sim->cycle_count++;

  chip_event (sim, event_cycle);

  return (true);
}


static bool nut_execute_instruction (sim_t *sim)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  do
    {
      if (! nut_execute_cycle (sim))
	return false;
    }
  while (nut_reg->inst_state != norm);
  return true;
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
  int b = 0;
  int a;
  int o;

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

  *bank = b;
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
  nut_reg_t *nut_reg = sim->chip_data [0];

#if 0
  if ((! nut_reg->awake) && (! nut_reg->display_enable) && (keycode != 0x18))
    return;
#endif
  nut_reg->key_buf = keycode;
  nut_reg->key_down = true;
  nut_reg->key_flag = true;
#ifdef SLEEP_DEBUG
  if (! nut_reg->awake)
    printf ("waking up!\n");
#endif
  nut_reg->awake = true;
  chip_event (sim, event_wake);
}

static void nut_release_key (sim_t *sim)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  nut_reg->key_down = false;
}

static void nut_set_ext_flag (sim_t *sim, int flag, bool state)
{
  ;  // not yet implemented
}


static void nut_reset (sim_t *sim)
{
  nut_reg_t *nut_reg = sim->chip_data [0];
  int i;

  sim->cycle_count = 0;

  for (i = 0; i < WSIZE; i++)
    {
      nut_reg->a [i] = 0;
      nut_reg->b [i] = 0;
      nut_reg->c [i] = 0;
      nut_reg->m [i] = 0;
      nut_reg->n [i] = 0;
    }

  for (i = 0; i < SSIZE; i++)
    nut_reg->s [i] =0;

  nut_reg->p = 0;
  nut_reg->q = 0;
  nut_reg->q_sel = false;

  for (i = 0; i < MAX_PAGE; i++)
    nut_reg->active_bank [i] = 0;

  /* wake from deep sleep */
  nut_reg->awake = true;
  nut_reg->pc = 0;
  nut_reg->inst_state = norm;
  nut_reg->carry = 1;

  nut_reg->key_flag = 0;
}


static bool nut_read_ram (sim_t *sim, int addr, uint64_t *val)
{
  nut_reg_t *nut_reg = sim->chip_data [0];
  uint64_t data = 0;
  int i;

  if (addr > sim->max_ram)
    fatal (2, "classic_read_ram: address %d out of range\n", addr);
  if (! nut_reg->ram_exists [addr])
    return false;

  // pack nut_reg->ram [addr] into data
  for (i = WSIZE - 1; i >= 0; i--)
    {
      data <<= 4;
      data += nut_reg->ram [addr] [i];
    }

  *val = data;

  return true;
}


static bool nut_write_ram (sim_t *sim, int addr, uint64_t *val)
{
  nut_reg_t *nut_reg = sim->chip_data [0];
  uint64_t data;
  int i;

  if (addr > sim->max_ram)
    fatal (2, "sim_write_ram: address %d out of range\n", addr);
  if (! nut_reg->ram_exists [addr])
    return false;

  data = *val;

  // now unpack data into nut_reg->ram [addr]
  for (i = 0; i <= WSIZE; i++)
    {
      nut_reg->ram [addr] [i] = data & 0x0f;
      data >>= 4;
    }

  return true;
}


static void nut_new_rom_addr_space (sim_t *sim,
				    int max_bank,
				    int max_page,
				    int page_size)
{
  ;
}



static void nut_new_pf_addr_space (sim_t *sim, int max_pf)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  nut_reg->max_pf = max_pf;
  nut_reg->pf_exists = alloc (max_pf * sizeof (bool));
}


static void nut_new_ram_addr_space (sim_t *sim, int max_ram)
{
  nut_reg_t *nut_reg = sim->chip_data [0];

  sim->max_ram = max_ram;
  nut_reg->ram_exists   = alloc (max_ram * sizeof (bool));
  nut_reg->ram          = alloc (max_ram * sizeof (reg_t));
  nut_reg->ram_read_fn  = alloc (max_ram * sizeof (ram_access_fn_t *));
  nut_reg->ram_write_fn = alloc (max_ram * sizeof (ram_access_fn_t *));
}


static void nut_new_ram (sim_t *sim, int base_addr, int count)
{
  nut_reg_t *nut_reg = sim->chip_data [0];
  int i;

  for (i = base_addr; i < (base_addr + count); i++)
    nut_reg->ram_exists [i] = true;
}


static void nut_new_processor (sim_t *sim, int ram_size)
{
  nut_reg_t *nut_reg;

  nut_reg = alloc (sizeof (nut_reg_t));

  install_chip (sim, 0, & nut_cpu_chip_detail, nut_reg);

  nut_init_ops (nut_reg);

  nut_new_rom_addr_space (sim, MAX_BANK, MAX_PAGE, PAGE_SIZE);
  nut_new_ram_addr_space (sim, 1024);
  nut_new_pf_addr_space (sim, 256);

  switch (sim->platform)
    {
    case PLATFORM_COCONUT:
      nut_new_ram (sim, 0x000, 0x010);
      ram_size -= 16;

      if (ram_size > 320)
	{
	  // Base extended memory of 41CX
	  nut_new_ram (sim, 0x40, 128);
	  ram_size = 320;
	  phineas_init (sim);
	}

      nut_new_ram (sim, 0x0c0, ram_size);

      coconut_display_init (sim);
      break;

    case PLATFORM_VOYAGER:
      nut_new_ram (sim, 0x000, 8);
      ram_size -= 8;

      nut_new_ram (sim, 0x008, 3);  // I/O registers
      nut_reg->ram_read_fn  [0x08] = nut_ram_read_zero;
      nut_reg->ram_write_fn [0x08] = nut_ram_write_ignore;

      if (ram_size > 40)
	{
	  nut_new_ram (sim, 0x010, 8);
	  ram_size -= 8;

	  nut_new_ram (sim, 0x018, 3);  // I/O registers
	  nut_reg->ram_read_fn  [0x18] = nut_ram_read_zero;
	  nut_reg->ram_write_fn [0x18] = nut_ram_write_ignore;
	}

      nut_new_ram (sim, 0x100 - ram_size, ram_size);

      voyager_display_init (sim);
      break;
    }

  chip_event (sim, event_reset);
}


static void nut_free_processor (sim_t *sim)
{
  remove_chip (sim, 0);
}


static void nut_event_fn (sim_t *sim, int chip_num, int event)
{
  // nut_reg_t *nut_reg = sim->chip_data [0];

  switch (event)
    {
    case event_reset:
       nut_reset (sim);
       break;
    default:
      // warning ("proc_nut: unknown event %d\n", event);
      break;
    }
}


processor_dispatch_t nut_processor =
  {
    .max_rom             = MAX_PAGE * PAGE_SIZE,
    .max_bank            = MAX_BANK,

    .max_chip_count      = MAX_CHIP_COUNT,

    .new_processor       = nut_new_processor,
    .free_processor      = nut_free_processor,

    .parse_object_line   = nut_parse_object_line,
    .parse_listing_line  = nut_parse_listing_line,

    .execute_cycle       = nut_execute_cycle,
    .execute_instruction = nut_execute_instruction,

    .press_key           = nut_press_key,
    .release_key         = nut_release_key,
    .set_ext_flag        = nut_set_ext_flag,

    .read_rom            = nut_read_rom,
    .write_rom           = nut_write_rom,

    .read_ram            = nut_read_ram,
    .write_ram           = nut_write_ram,

    .disassemble         = nut_disassemble,
    .print_state         = nut_print_state
  };
