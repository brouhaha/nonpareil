/*
Copyright 1995-2023 Eric Smith <spacewar@gmail.com>
SPDX-License-Identifier: GPL-3.0-only

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License version 3 as
published by the Free Software Foundation.

Note that permission is NOT granted to redistribute and/or modify
this porogram under the terms of any other version, earlier or
later, of the GNU General Public License.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License version 3 for more details.

You should have received a copy of the GNU General Public License
version 3 along with this program (in the file "gpl-3.0.txt"); if not,
see <https://www.gnu.org/licenses/>.
*/

#include <inttypes.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "arch.h"
#include "platform.h"
#include "util.h"
#include "display.h"
#include "keyboard.h"
#include "chip.h"
#include "calcdef.h"
#include "proc.h"
#include "proc_int.h"
#include "digit_ops.h"
#include "proc_nut.h"
#include "sound.h"


#undef WARNING_G

#define MAX_RAM 1024  // possibly only 256 for Voyagers?


#define KBD_RELEASE_DEBOUNCE_CYCLES 32

#undef KEYBOARD_DEBUG

#ifdef KEYBOARD_DEBUG
static char *kbd_state_name [KB_STATE_MAX] =
  {
    [KB_IDLE]     = "idle",
    [KB_PRESSED]  = "pressed",
    [KB_RELEASED] = "released",
    [KB_WAIT_CHK] = "wait_chk",
    [KB_WAIT_CYC] = "wait_cyc"
  };
#endif


#undef WARN_STRAY_WRITE


static void print_reg (reg_t reg);


#define NR(name, field, bits, radix, get, set, arg) \
    {{ name, bits, 1, radix },                      \
     offsetof (nut_reg_t, field),                   \
     FIELD_SIZE_OF (nut_reg_t, field),              \
     get, set, arg } 


#define NRA(name, field, bits, radix, get, set, arg, array) \
    {{ name, bits, array, radix },                          \
     offsetof (nut_reg_t, field[0]),                        \
     FIELD_SIZE_OF (nut_reg_t, field[0]),                   \
     get, set, arg } 


#define NRD(name, field, digits)       \
    {{ name, digits * 4, 1, 16 },      \
     offsetof (nut_reg_t, field),      \
     FIELD_SIZE_OF (nut_reg_t, field), \
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
  NRA ("stack",   stack,   16,    16,   NULL,      NULL,      0, STACK_DEPTH ),
  NR  ("decimal", decimal, 1,      2,   NULL,      NULL,      0),
  NR  ("carry",   carry,   1,      2,   NULL,      NULL,      0),
  NR  ("awake",   awake,   1,      2,   NULL,      NULL,      0),
  // key_down
  // kb_state
  // key_buf
  NR  ("pf_addr", pf_addr, 8,     16,   NULL,      NULL,      0),
  NR  ("ram_addr", ram_addr, 10,  16,   NULL,      NULL,      0),
  NRA ("active_bank", active_bank, 2, 16, NULL, NULL, 0, MAX_PAGE),

  // inst_state

  // following are only applicable if inst_state != norm:
  // first_word
  // cxisa_addr
#ifdef NUT_BUGS
  // prev_tef_last
#endif // NUT_BUGS

  // NR  ("selpf",   selpf,   4,     16,   NULL,      NULL,      0),

  // display_enable
};


static chip_event_fn_t nut_event_fn;


static chip_detail_t nut_cpu_chip_detail =
{
  {
    "Nut",
    CHIP_NUT_CPU,
    false  // There can only be one Nut processor in the calculator.
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
  bank_t bank = nut_reg->active_bank [page];
  uint16_t offset = addr & (PAGE_SIZE - 1);
  prog_mem_page_t *prog_mem_page = nut_reg->prog_mem_page [bank][page];

  if (prog_mem_page)
    return prog_mem_page->data [offset];
  else
     return 0;  // non-existent memory
}


static void nut_set_ucode (nut_reg_t *nut_reg,
			   rom_addr_t addr,
			   rom_word_t data)
{
  uint8_t page = addr / PAGE_SIZE;
  bank_t bank = nut_reg->active_bank [page];
  uint16_t offset = addr & (PAGE_SIZE - 1);
  prog_mem_page_t *prog_mem_page = nut_reg->prog_mem_page [bank][page];

  if (! prog_mem_page)
    {
#if 0
      fprintf (stderr, "write to nonexistent ROM location %04x (bank %d)\n", addr, bank);
#endif
      return;
    }
  if ((! prog_mem_page->ram) || (! prog_mem_page->write_enable))
    {
#if 0
      fprintf (stderr, "write to non-writeable ROM location %04x (bank %d)\n", addr, bank);
#endif
      return;
    }
  prog_mem_page->data [offset] = data;
}


static bool nut_set_bank_group (sim_t    *sim,
				int      bank_group,
				addr_t   addr)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  uint8_t page;
  uint16_t offset;
  
  if (addr >= (MAX_PAGE * PAGE_SIZE))
    return false;

  page = addr / PAGE_SIZE;
  offset = addr & (PAGE_SIZE - 1);

  if (offset != 0)
    return false;

  nut_reg->bank_group [page] = bank_group;

  return true;
}

bank_t nut_get_max_rom_bank (sim_t *sim UNUSED)
{
  return MAX_BANK;
}

int nut_get_rom_page_size (sim_t *sim UNUSED)
{
  return PAGE_SIZE;
}

int nut_get_max_rom_addr (sim_t *sim UNUSED)
{
  return MAX_PAGE * PAGE_SIZE;
}


void debug_nut_show_pages (sim_t *sim)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  uint8_t page;
  bank_t bank;
  for (page = 0; page < 16; page++)
    for (bank = 0; bank < 5; bank++)
      {
	prog_mem_page_t *prog_mem_page = nut_reg->prog_mem_page [bank][page];
	if (prog_mem_page)
	  {
	    printf ("page %x bank %d:", page, bank);
	    if (prog_mem_page->ram)
	      printf ("  ram");
	    if (prog_mem_page->write_enable)
	      printf ("  write enable");
	    if (prog_mem_page->module)
	      printf ("  module %s", plugin_module_get_name (prog_mem_page->module));
	    printf ("\n");
	  }
      }
}


bool nut_create_page (sim_t           *sim,
		      bank_t          bank,
		      uint8_t         page,
		      bool            ram,
		      plugin_module_t *module)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  prog_mem_page_t *prog_mem_page;

  if (nut_reg->prog_mem_page [bank][page])
    {
      fprintf (stderr, "create bank %d page %x failed\n", bank, page);
      return false;
    }

  prog_mem_page = alloc (sizeof (prog_mem_page_t));
  prog_mem_page->ram = ram;
  prog_mem_page->module = module;
  nut_reg->prog_mem_page [bank][page] = prog_mem_page;
  return true;
}

bool nut_destroy_page (sim_t           *sim,
		       bank_t          bank,
		       uint8_t         page)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  if (! nut_reg->prog_mem_page [bank][page])
    return false;  // doesn't exist!

  free (nut_reg->prog_mem_page [bank][page]);
  nut_reg->prog_mem_page [bank][page] = NULL;
  return true;
}

bool nut_get_page_info (sim_t           *sim,
			bank_t          bank,
			uint8_t         page,
			plugin_module_t **module,
			bool            *ram,
			bool            *write_enable)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  prog_mem_page_t *prog_mem_page = nut_reg->prog_mem_page [bank][page];
  if (! prog_mem_page)
    return false;

  if (module)
    *module = prog_mem_page->module;
  if (ram)
    *ram = prog_mem_page->ram;
  if (write_enable)
    *write_enable = prog_mem_page->write_enable;
  return true;
}


static bool nut_read_rom (sim_t      *sim,
			  bank_t     bank,
			  addr_t     addr,
			  rom_word_t *val)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  uint8_t page = addr / PAGE_SIZE;
  uint16_t offset = addr & (PAGE_SIZE - 1);
  prog_mem_page_t *prog_mem_page = nut_reg->prog_mem_page [bank][page];

  if ((addr >= (MAX_PAGE * PAGE_SIZE)) || (bank > MAX_BANK))
    return false;

  if (! prog_mem_page)
    return false;

  *val = prog_mem_page->data [offset];
  return true;
}


static bool nut_write_rom (sim_t      *sim,
			   bank_t     bank,
			   addr_t     addr,
			   rom_word_t *val)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  uint8_t page = addr / PAGE_SIZE;
  uint16_t offset = addr & (PAGE_SIZE - 1);
  prog_mem_page_t *prog_mem_page = nut_reg->prog_mem_page [bank][page];

  if ((addr >= (MAX_PAGE * PAGE_SIZE)) || (bank > MAX_BANK))
    return false;

  if (! prog_mem_page)  // does the page/bank exist?
    {
      // no, allocate a new page
      prog_mem_page = alloc (sizeof (prog_mem_page_t));
      nut_reg->prog_mem_page [bank][page] = prog_mem_page;
    }

  prog_mem_page->data [offset] = *val;
  return true;
}


static bool nut_set_rom_write_enable (sim_t      *sim,
				      bank_t     bank,
				      addr_t     addr,
				      bool       write_enable)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  uint8_t page = addr / PAGE_SIZE;
  prog_mem_page_t *prog_mem_page = nut_reg->prog_mem_page [bank][page];

  if ((addr >= (MAX_PAGE * PAGE_SIZE)) || (bank > MAX_BANK))
    return false;

  if (! prog_mem_page)  // does the page/bank exist?
    return false;

  if (! prog_mem_page->ram && write_enable)
    {
      fprintf (stderr, "attempting to write enable ROM in page %x bank %d", page, bank);
      return false;
    }
  
  prog_mem_page->write_enable = write_enable;
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
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  printf ("illegal opcode %03x at %04x\n", opcode, nut_reg->prev_pc);
}


static void op_arith (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
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

#ifdef NUT_BUGS
  nut_reg->prev_tef_last = last;
#endif // NUT_BUGS

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
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
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
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  int i;

  for (i = STACK_DEPTH - 1; i > 0; i--)
    nut_reg->stack [i] = nut_reg->stack [i - 1];
  nut_reg->stack [0] = a;
}

static void op_return (sim_t *sim,
		       int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  nut_reg->pc = pop (sim);
}

static void op_return_if_carry (sim_t *sim,
				int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  if (nut_reg->prev_carry)
    nut_reg->pc = pop (sim);
}

static void op_return_if_no_carry (sim_t *sim,
				   int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  if (! nut_reg->prev_carry)
    nut_reg->pc = pop (sim);
}

static void op_pop (sim_t *sim,
		    int opcode UNUSED)
{
  (void) pop (sim);
}

static void op_pop_c (sim_t *sim,
		      int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  rom_addr_t a;

  a = pop (sim);
  nut_reg->c [6] = a >> 12;
  nut_reg->c [5] = (a >> 8) & 0x0f;
  nut_reg->c [4] = (a >> 4) & 0x0f;
  nut_reg->c [3] = a & 0x0f;
}


static void op_push_c (sim_t *sim,
		       int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

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
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  int offset;

  offset = (opcode >> 3) & 0x3f;
  if (opcode & 0x200)
    offset -= 64;

  if (((opcode >> 2) & 1) == nut_reg->prev_carry)
    nut_reg->pc = nut_reg->pc + offset - 1;
}


static void op_long_branch (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  nut_reg->inst_state = inst_nut_long_branch;
  nut_reg->first_word = opcode;
  nut_reg->carry = nut_reg->prev_carry;  // remember carry for second word
}


static void op_long_branch_word_2 (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  rom_addr_t target;

  nut_reg->inst_state = inst_normal;
  target = (nut_reg->first_word >> 2) | ((opcode & 0x3fc) << 6);

  if ((opcode & 0x001) == nut_reg->prev_carry)
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


static void op_goto_c (sim_t *sim,
		       int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  nut_reg->pc = ((nut_reg->c [6] << 12) |
		  (nut_reg->c [5] << 8) |
		  (nut_reg->c [4] << 4) | 
		  (nut_reg->c [3]));
}


// Bank selection used in 41CX, Advantage ROM, and perhaps others

static void select_bank_page (sim_t *sim, uint8_t page, bank_t new_bank)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  prog_mem_page_t *prog_mem_page = nut_reg->prog_mem_page [new_bank][page];

  if (prog_mem_page)
    nut_reg->active_bank [page] = new_bank;
  else
    fprintf (stderr, "bank %d select for page %x: nonexistent!\n", new_bank, page);
}

static void select_bank (sim_t *sim, rom_addr_t addr, bank_t new_bank)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  uint8_t page;
  int bank_group;
  prog_mem_page_t *prog_mem_page;

  page = addr / PAGE_SIZE;
  bank_group = nut_reg->bank_group [page];
  if (bank_group)
    {
      for (page = 0; page < MAX_PAGE; page++)
	{
	  prog_mem_page = nut_reg->prog_mem_page [new_bank][page];
	  if ((nut_reg->bank_group [page] == bank_group) && prog_mem_page)
	    select_bank_page (sim, page, new_bank);
	}
    }
  else
    select_bank_page (sim, page, new_bank);
}


// note that banks 3 and 4 are only supported by third-party devices
// such as the HEPAX
static void op_enbank (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  bank_t bank = ((opcode >> 5) & 2) + ((opcode >> 7) & 1);

#undef NUT_BANK_SWITCH_DEBUG
#ifdef NUT_BANK_SWITCH_DEBUG
  fprintf (stderr, "enbank %d (%03x) at %04x\n", bank + 1, opcode, nut_reg->prev_pc);
#endif
  select_bank (sim, nut_reg->prev_pc, bank);
}


/*
 * m operations
 */

static void op_c_to_m (sim_t *sim,
		       int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  reg_copy (nut_reg->m, nut_reg->c, 0, WSIZE - 1);
}

static void op_m_to_c (sim_t *sim,
		       int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  reg_copy (nut_reg->c, nut_reg->m, 0, WSIZE - 1);
}

static void op_c_exch_m (sim_t *sim,
			 int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  reg_exch (nut_reg->c, nut_reg->m, 0, WSIZE - 1);
}


/*
 * n operations
 */

static void op_c_to_n (sim_t *sim,
		       int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  reg_copy (nut_reg->n, nut_reg->c, 0, WSIZE - 1);
}

static void op_n_to_c (sim_t *sim,
		       int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  reg_copy (nut_reg->c, nut_reg->n, 0, WSIZE - 1);
}

static void op_c_exch_n (sim_t *sim,
			 int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  reg_exch (nut_reg->c, nut_reg->n, 0, WSIZE - 1);
}


/*
 * RAM and peripheral operations
 */

void nut_ram_read_zero (nut_reg_t *nut_reg UNUSED,
			int addr           UNUSED,
			reg_t *reg)
{
  int i;
  for (i = 0; i < WSIZE; i++)
    (*reg) [i] = 0;
}


void nut_ram_write_ignore (nut_reg_t *nut_reg UNUSED,
			   int addr           UNUSED,
			   reg_t *reg         UNUSED)
{
  ;
}


static void op_c_to_dadd (sim_t *sim,
			  int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  nut_reg->ram_addr = ((nut_reg->c [2] << 8) | 
			(nut_reg->c [1] << 4) |
			(nut_reg->c [0])) & 0x3ff;

  chip_event (sim,
	      NULL,
	      event_ram_select,
	      0,
	      0,
	      NULL);
}

static void op_c_to_pfad (sim_t *sim,
			  int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  nut_reg->pf_addr = ((nut_reg->c [1] << 4) |
		       (nut_reg->c [0]));

  chip_event (sim,
	      NULL,
	      event_periph_select,
	      0,
	      0,
	      NULL);
}

static void op_read_reg_n (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
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

  is_pf  = (nut_reg->pf_exists  [pf_addr] &&
	    nut_reg->rd_n_fcn   [pf_addr] &&
	    (*nut_reg->rd_n_fcn [pf_addr]) (sim, opcode >> 6));

  if (is_ram)
    {
      if (is_pf)
	printf ("warning: conflicting read RAM %03x PF %02x reg %01x\n",
		ram_addr, pf_addr, opcode >> 6);
      if (nut_reg->ram_read_fn [ram_addr])
        nut_reg->ram_read_fn [ram_addr] (nut_reg, ram_addr, & nut_reg->c);
      else
        for (i = 0; i < WSIZE; i++)
	  nut_reg->c [i] = nut_reg->ram [ram_addr][i];
    }
  else if (! is_pf)
    {
      printf ("warning: stray read RAM %03x PF %02x reg %01x\n",
	      ram_addr, pf_addr, opcode >> 6);
    }
}


static void op_write_reg_n (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  uint16_t ram_addr;
  uint8_t pf_addr;
  int i;
  int is_ram, is_pf;

  nut_reg->ram_addr = (nut_reg->ram_addr & ~0x0f) | (opcode >> 6);

  ram_addr = nut_reg->ram_addr;
  pf_addr = nut_reg->pf_addr;

  is_ram = nut_reg->ram_exists [ram_addr];

  is_pf  = (nut_reg->pf_exists  [pf_addr] &&
	    nut_reg->wr_n_fcn [pf_addr] &&
	    (*nut_reg->wr_n_fcn [pf_addr]) (sim, opcode >> 6));

  if (is_ram)
    {
      if (is_pf)
	printf ("warning: conflicting write RAM %03x PF %02x reg %01x\n",
		ram_addr, pf_addr, opcode >> 6);
      if (nut_reg->ram_write_fn [ram_addr])
        nut_reg->ram_write_fn [ram_addr] (nut_reg, ram_addr, & nut_reg->c);
      else
	for (i = 0; i < WSIZE; i++)
	  nut_reg->ram [ram_addr][i] = nut_reg->c [i];
    }
  else if (! is_pf)
    {
#ifdef WARN_STRAY_WRITE
      printf ("warning: stray write RAM %03x PF %02x reg %01x data ",
	      ram_addr, pf_addr, opcode >> 6);
      print_reg (nut_reg->c);
      printf ("\n");
#endif
    }
}


static void op_c_to_data (sim_t *sim,
			  int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  uint16_t ram_addr;
  uint8_t pf_addr;
  int i;
  int is_ram, is_pf;

  ram_addr = nut_reg->ram_addr;
  pf_addr = nut_reg->pf_addr;

  is_ram = nut_reg->ram_exists [ram_addr];

  is_pf  = (nut_reg->pf_exists  [pf_addr] &&
	    nut_reg->wr_fcn [pf_addr] &&
	    (*nut_reg->wr_fcn [pf_addr]) (sim));

  if (is_ram)
    {
      if (is_pf)
	printf ("warning: conflicting write RAM %03x PF %02x\n",
		ram_addr, pf_addr);
      if (nut_reg->ram_write_fn [ram_addr])
        nut_reg->ram_write_fn [ram_addr] (nut_reg, ram_addr, & nut_reg->c);
      else
	for (i = 0; i < WSIZE; i++)
	  nut_reg->ram [ram_addr][i] = nut_reg->c [i];
    }
  else if (! is_pf)
    {
#ifdef WARN_STRAY_WRITE
      printf ("warning: stray write RAM %03x PF %02x data ",
	      ram_addr, pf_addr);
      print_reg (nut_reg->c);
      printf ("\n");
#endif
    }
}


static void op_test_ext_flag (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  nut_reg->carry = nut_reg->ext_flag [tmap [opcode >> 6]];
}


static void op_selpf (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  nut_reg->selpf = opcode >> 6;
  nut_reg->inst_state = inst_nut_selpf;
}


// This "opcode" handles all instructions following a selpf (AKA
// PERTCT, SELP, or SELPRF) instruction until a return of control.
static void op_smart_periph (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  bool flag = false;

  if (nut_reg->selpf_fcn [nut_reg->selpf])
    flag = nut_reg->selpf_fcn [nut_reg->selpf] (sim, opcode);
  if ((opcode & 0x03f) == 0x003)
    nut_reg->carry = flag;
  if (opcode & 1)
    nut_reg->inst_state = inst_normal;
}


/*
 * s operations
 */

static void op_set_s (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  nut_reg->s [tmap [opcode >> 6]] = 1;
}

static void op_clr_s (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  nut_reg->s [tmap [opcode >> 6]] = 0;
}

static void op_test_s (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  nut_reg->carry = nut_reg->s [tmap [opcode >> 6]];
}

static int get_s_bits (sim_t *sim, int first, int count)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
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
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  int i;
  int mask = 1;

  for (i = first; i < first + count; i++)
    {
      nut_reg->s [i] = (a & mask) != 0;
      mask <<= 1;
    }
}

static void op_clear_all_s (sim_t *sim,
			    int opcode UNUSED)
{
  set_s_bits (sim, 0, 8, 0);
}

static void op_c_to_s (sim_t *sim,
		       int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  set_s_bits (sim, 0, 4, nut_reg->c [0]);
  set_s_bits (sim, 4, 4, nut_reg->c [1]);
}

static void op_s_to_c (sim_t *sim,
		       int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  nut_reg->c [0] = get_s_bits (sim, 0, 4);
  nut_reg->c [1] = get_s_bits (sim, 4, 4);
}

static void op_c_exch_s (sim_t *sim,
			 int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  int t;

  t = get_s_bits (sim, 0, 4);
  set_s_bits (sim, 0, 4, nut_reg->c [0]);
  nut_reg->c [0] = t;
  t = get_s_bits (sim, 4, 4);
  set_s_bits (sim, 4, 4, nut_reg->c [1]);
  nut_reg->c [1] = t;
}


// Standard 41C tones have pulse widths of 3 to 18 word times, and are
// symmetric for a total cycle time of 6 to 36 word times.  Allow for
// tones of slightly lower frequency.
#define BENDER_MAX_PULSE_WIDTH 20


static void bender_off (sim_t *sim)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  // $$$ stop sound if playing
  if (nut_reg->bender_sound_ref >= 0)
    stop_sound (nut_reg->bender_sound_ref);
  nut_reg->bender_sound_ref = -1;

  nut_reg->bender_last_transition_cycle = 0;  // a long time ago
  nut_reg->bender_last_pulse_width = 0;       // will never match

#ifdef SOUND_DEBUG
  printf ("bender off\n");
#endif
}


static void bender_pulse (sim_t *sim, uint64_t pulse_width)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  float frequency;

  if (pulse_width == nut_reg->bender_last_pulse_width)
    return;

  nut_reg->bender_last_pulse_width = pulse_width;

  if (nut_reg->bender_sound_ref >= 0)
    stop_sound (nut_reg->bender_sound_ref);
  nut_reg->bender_sound_ref = -1;

#ifdef SOUND_DEBUG
  if (pulse_width <= BENDER_MAX_PULSE_WIDTH)
    printf ("bender pulse width %" PRId64 " cycles\n", pulse_width);
#endif

  frequency = calcdef_get_clock_frequency (sim->calcdef) / (112.0 * pulse_width);

#ifdef SOUND_DEBUG
  printf ("frequency: %f\n", frequency);
#endif

  nut_reg->bender_sound_ref = synth_sound (frequency,
					   0.1,  // amplitude
					   0.0,  // duration - indefinite
					   squarewave_waveform_table,
					   squarewave_waveform_table_length);
}


static void set_fo (sim_t *sim, uint8_t val)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  if (nut_reg->fo == val)
    return;  // no change

  if (nut_reg->bender_last_transition_cycle)
    bender_pulse (sim,
		  sim->cycle_count - nut_reg->bender_last_transition_cycle);

  nut_reg->bender_last_transition_cycle = sim->cycle_count;
  nut_reg->fo = val;
}


static void op_sb_to_f (sim_t *sim,
			int opcode UNUSED)
{
  set_fo (sim, get_s_bits (sim, 0, 8));
}

static void op_f_to_sb (sim_t *sim,
			int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  set_s_bits (sim, 0, 8, nut_reg->fo);
}

static void op_f_exch_sb (sim_t *sim,
			  int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  int t;

  t = get_s_bits (sim, 0, 8);
  set_s_bits (sim, 0, 8, nut_reg->fo);
  set_fo (sim, t);
}

/*
 * pointer operations
 */

static void op_dec_pt (sim_t *sim,
		       int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  (*pt (nut_reg))--;
  if ((*pt (nut_reg)) >= WSIZE)  // can't be negative because it is unsigned
    (*pt (nut_reg)) = WSIZE - 1;
}

static void op_inc_pt (sim_t *sim,
		       int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  (*pt (nut_reg))++;
  if ((*pt (nut_reg)) >= WSIZE)
    (*pt (nut_reg)) = 0;
}

static void op_set_pt (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  (*pt (nut_reg)) = tmap [opcode >> 6];
}

static void op_test_pt (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  nut_reg->carry = ((*pt (nut_reg)) == tmap [opcode >> 6]);
}

static void op_sel_p (sim_t *sim,
		      int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  nut_reg->q_sel = false;
}

static void op_sel_q (sim_t *sim,
		      int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  nut_reg->q_sel = true;
}

static void op_test_pq (sim_t *sim,
			int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  if (nut_reg->p == nut_reg->q)
    nut_reg->carry = 1;
}

static void op_lc (sim_t *sim,
		   int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  nut_reg->c [(*pt (nut_reg))--] = opcode >> 6;
  if ((*pt (nut_reg)) >= WSIZE)  /* unsigned, can't be negative */
    *pt (nut_reg) = WSIZE - 1;
}

static void op_c_to_g (sim_t *sim,
		       int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  int low_digit_index = *pt (nut_reg);

  if (low_digit_index < (WSIZE - 1))
  {
    nut_reg->g [0] = nut_reg->c [low_digit_index];
    nut_reg->g [1] = nut_reg->c [low_digit_index + 1];
  }
  else
  {
#ifdef WARNING_G
    fprintf (stderr, "warning: c to g transfer with pt=13, pc=%04x\n", nut_reg->prev_pc);
#endif
    // If the pointer register only just changed to WSIZE - 1 by the
    // previous instruction, the following is not correct.
    // See the David Assembler Manual, Appendix F for details.
    nut_reg->g [0] = nut_reg->c [0];
    nut_reg->g [1] = nut_reg->c [WSIZE - 1];
  }
}

static void op_g_to_c (sim_t *sim,
		       int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  int low_digit_index = *pt (nut_reg);

  if (low_digit_index < (WSIZE - 1))
  {
    nut_reg->c [low_digit_index] = nut_reg->g [0];
    nut_reg->c [low_digit_index + 1] = nut_reg->g [1];
  }
  else
  {
#ifdef WARNING_G
    fprintf (stderr, "warning: g to c transfer with pt=13, pc=%04x\n", nut_reg->prev_pc);
#endif
    // If the pointer register only just changed to WSIZE - 1 by the
    // previous instruction, the following is not correct.
    // See the David Assembler Manual, Appendix F for details.
    nut_reg->c [0] = nut_reg->g [0];
    nut_reg->c [WSIZE - 1] = nut_reg->g [1];
  }
    
}


static void swap_digit(digit_t *a, digit_t *b)
{
  digit_t t;

  t = *a;
  *a = *b;
  *b = t;
}

static void op_c_exch_g (sim_t *sim,
			 int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  int low_digit_index = *pt (nut_reg);

  if (low_digit_index < (WSIZE - 1))
  {
    swap_digit(& nut_reg->g[0], & nut_reg->c[low_digit_index]);
    swap_digit(& nut_reg->g[1], & nut_reg->c[low_digit_index + 1]);
  }
  else
  {
#ifdef WARNING_G
    fprintf (stderr, "warning: c exchange g with pt=13\n, pc=%04x\n", nut_reg->prev_pc);
#endif
    // If the pointer register only just changed to WSIZE - 1 by the
    // previous instruction, the following is not correct.
    // See the David Assembler Manual, Appendix F for details.
    swap_digit(& nut_reg->g[0], & nut_reg->c[0]);
    swap_digit(& nut_reg->g[1], & nut_reg->c[WSIZE - 1]);
  }
}


/*
 * keyboard operations
 */

static void op_keys_to_rom_addr (sim_t *sim,
				 int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  nut_reg->pc = (nut_reg->pc & 0xff00) | nut_reg->key_buf;
}


static void op_keys_to_c (sim_t *sim,
			  int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  nut_reg->c [4] = nut_reg->key_buf >> 4;
  nut_reg->c [3] = nut_reg->key_buf & 0x0f;
}


static void op_test_kb (sim_t *sim,
			int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

#ifdef KEYBOARD_DEBUG
  printf ("kb test, addr %04x, state %s\n", nut_reg->prev_pc, kbd_state_name [nut_reg->kb_state]);
#endif

  nut_reg->carry = ((nut_reg->kb_state == KB_PRESSED) ||
		    (nut_reg->kb_state == KB_RELEASED));
  if (nut_reg->kb_state == KB_WAIT_CHK)
    {
      nut_reg->kb_state = KB_WAIT_CYC;
      nut_reg->kb_debounce_cycle_counter = KBD_RELEASE_DEBOUNCE_CYCLES;
    }
}


static void op_reset_kb (sim_t *sim,
			 int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

#ifdef KEYBOARD_DEBUG
  printf ("kb reset, addr %04x, state %s\n", nut_reg->prev_pc, kbd_state_name [nut_reg->kb_state]);
#endif

  if (nut_reg->kb_state == KB_RELEASED)
    nut_reg->kb_state = KB_WAIT_CHK;
}


static void nut_kbd_scanner_cycle (nut_reg_t *nut_reg)
{
  if ((nut_reg->kb_state == KB_WAIT_CYC) &&
      (--nut_reg->kb_debounce_cycle_counter == 0))
    {
      if (nut_reg->key_down)
	{
	  nut_reg->kb_state = KB_PRESSED;
#ifdef SLEEP_DEBUG
	  if (! nut_reg->awake)
	    printf ("waking up!\n");
#endif
	  nut_reg->awake = true;
	}
      else
	nut_reg->kb_state = KB_IDLE;
    }
}


static void nut_kbd_scanner_sleep (nut_reg_t *nut_reg)
{
#ifdef KEYBOARD_DEBUG
  printf ("nut_kbd_scanner_sleep, state=%s\n", kbd_state_name [nut_reg->kb_state]);
#endif

  if (nut_reg->kb_state == KB_PRESSED)
    {
      // $$$ This shouldn't happen, should it?
#if defined(KEYBOARD_DEBUG) || defined(SLEEP_DEBUG)
      if (! nut_reg->awake)
	printf ("waking up!\n");
#endif
      nut_reg->awake = true;
    }
  if (nut_reg->kb_state == KB_WAIT_CYC)
    {
      if (nut_reg->key_down)
	{
	  nut_reg->kb_state = KB_PRESSED;
#if defined(KEYBOARD_DEBUG) || defined(SLEEP_DEBUG)
	  if (! nut_reg->awake)
	    printf ("waking up!\n");
#endif
	  nut_reg->awake = true;
	}
      else
	nut_reg->kb_state = KB_IDLE;
    }
}


/*
 * misc. operations
 */

static void op_nop (sim_t *sim UNUSED,
		    int opcode UNUSED)
{
}

static void op_set_hex (sim_t *sim,
			int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  nut_reg->decimal = false;
}

static void op_set_dec (sim_t *sim,
			int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  nut_reg->decimal = true;
}

static void op_rom_to_c (sim_t *sim,
			 int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  nut_reg->cxisa_addr = ((nut_reg->c [6] << 12) |
			  (nut_reg->c [5] << 8) |
			  (nut_reg->c [4] << 4) |
			  (nut_reg->c [3]));
  nut_reg->inst_state = inst_nut_cxisa;
}

static void op_rom_to_c_cycle_2 (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  nut_reg->c [2] = opcode >> 8;
  nut_reg->c [1] = (opcode >> 4) & 0x0f;
  nut_reg->c [0] = opcode & 0x0f;

  nut_reg->inst_state = inst_normal;
}

// only supported by third-party writeable program memory devices
static void op_write_mldl (sim_t *sim,
			   int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  uint16_t addr = ((nut_reg->c [6] << 12) |
		   (nut_reg->c [5] << 8) |
		   (nut_reg->c [4] << 4) |
		   (nut_reg->c [3]));
  uint16_t data = ((nut_reg->c [2] << 8) |
		   (nut_reg->c [1] << 4) |
		   (nut_reg->c [0])) & 0x3ff;
  nut_set_ucode (nut_reg, addr, data);
}

static void op_clear_abc (sim_t *sim,
			  int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  reg_zero (nut_reg->a, 0, WSIZE - 1);
  reg_zero (nut_reg->b, 0, WSIZE - 1);
  reg_zero (nut_reg->c, 0, WSIZE - 1);
}

static void op_ldi (sim_t *sim,
		    int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  nut_reg->inst_state = inst_nut_ldi;
}

static void op_ldi_cycle_2 (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  nut_reg->c [2] = opcode >> 8;
  nut_reg->c [1] = (opcode >> 4) & 0x0f;
  nut_reg->c [0] = opcode & 0x00f;

  nut_reg->inst_state = inst_normal;
}

static void op_or (sim_t *sim,
		   int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  int i;

  for (i = 0; i < WSIZE; i++)
    nut_reg->c [i] |= nut_reg->a [i];
#ifdef NUT_BUGS
  if (nut_reg->prev_carry && (nut_reg->prev_tef_last == (WSIZE - 1)))
    {
      nut_reg->c [WSIZE - 1] = nut_reg->c [0];
      nut_reg->a [WSIZE - 1] = nut_reg->c [0];
    }
#endif // NUT_BUGS
}

static void op_and (sim_t *sim,
		    int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  int i;

  for (i = 0; i < WSIZE; i++)
    nut_reg->c [i] &= nut_reg->a [i];
#ifdef NUT_BUGS
  if (nut_reg->prev_carry && (nut_reg->prev_tef_last == (WSIZE - 1)))
    {
      nut_reg->c [WSIZE - 1] = nut_reg->c [0];
      nut_reg->a [WSIZE - 1] = nut_reg->c [0];
    }
#endif // NUT_BUGS
}

static void op_rcr (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
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

static void op_lld (sim_t *sim,
		    int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  nut_reg->carry = 0;  /* "batteries" are fine */
}

static void op_powoff (sim_t *sim,
		       int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  int i;

  for (i = 0; i < MAX_PAGE; i++)
    nut_reg->active_bank [i] = 0;

#ifdef SLEEP_DEBUG
  printf ("going to sleep!\n");
#endif

  nut_reg->awake = false;
  nut_reg->pc = 0;
  chip_event (sim,
	      NULL,
	      event_sleep,
	      0,
	      0,
	      NULL);
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

  nut_reg->op_fcn [0x040] = op_write_mldl;
  // only supported by third-party writeable program memory devices

  for (i = 0; i < 4; i++)
     nut_reg->op_fcn [0x100 + i * 0x040] = op_enbank;
     // note that banks 3 and 4 are only supported by third-party devices
     // such as the HEPAX

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
      nut_reg->op_fcn [0x024 + (i << 6)] = op_selpf;
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


static void print_reg (reg_t reg)
{
  int i;
  for (i = WSIZE - 1; i >= 0; i--)
    printf ("%x", reg [i]);
}


static void log_print_reg (sim_t *sim, char *label, reg_t reg)
{
  int i;
  log_printf (sim, "%s", label);
  for (i = WSIZE - 1; i >= 0; i--)
    log_printf (sim, "%x", reg [i]);
  log_printf (sim, "\n");
  log_send (sim);
}


static void log_print_stat (sim_t *sim)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  int i;
  for (i = 0; i < SSIZE; i++)
    log_printf (sim, nut_reg->s [i] ? "%x" : ".", i);
}


static void nut_print_state (sim_t *sim)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  uint8_t page = nut_reg->prev_pc / PAGE_SIZE;
  bank_t bank = nut_reg->active_bank [page];

  log_printf (sim, "cycle %5" PRId64 "  ", sim->cycle_count);
  log_printf (sim, "%c=%x ", (nut_reg->q_sel) ? 'p' : 'P', nut_reg->p);
  log_printf (sim, "%c=%x ", (nut_reg->q_sel) ? 'Q' : 'q', nut_reg->q);
  log_printf (sim, "g=%x%x ", (nut_reg->g[1], nut_reg->g[0]));
  log_printf (sim, "carry=%d ", nut_reg->carry);
  log_printf (sim, " stat=");
  log_print_stat (sim);
  log_printf (sim, "\n");
  log_send (sim);

  log_print_reg (sim, "a=", nut_reg->a);
  log_print_reg (sim, "b=", nut_reg->b);
  log_print_reg (sim, "c=", nut_reg->c);
  log_print_reg (sim, "m=", nut_reg->m);
  log_print_reg (sim, "n=", nut_reg->n);

  log_printf(sim, "stack:");
  for (int i = 0; i < STACK_DEPTH; i++)
    log_printf(sim, " %04x", nut_reg->stack[i]);
  log_printf(sim, "\n");

  if (sim->source && sim->source [nut_reg->prev_pc])
    log_printf (sim, "%s", sim->source [nut_reg->prev_pc]);
  else
    {
      char buf [80];
      if (sim_disassemble_runtime (sim,
				   DIS_FLAG_LISTING,  // flags
				   bank,              // bank
				   nut_reg->prev_pc,  // addr
				   nut_reg->inst_state,
				   nut_reg->carry,
				   0,                 // delayed_select_mask
				   0,                 // delayed_select_addr
				   buf,
				   sizeof (buf)))
	log_printf (sim, "pc=%04x: %s", nut_reg->prev_pc, buf);
    }
  log_printf (sim, "\n");
  log_send (sim);
}

static bool nut_execute_cycle (sim_t *sim)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  int opcode;

  chip_event (sim,
	      NULL,
	      event_cycle,
	      0,
	      0,
	      NULL);

  if (! nut_reg->awake)
    return (false);

  // bender
  if (nut_reg->bender_last_transition_cycle &&
      ((sim->cycle_count - nut_reg->bender_last_transition_cycle) > BENDER_MAX_PULSE_WIDTH))
    bender_off (sim);

  if (nut_reg->inst_state == inst_nut_cxisa)
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
    case inst_normal:
      nut_reg->pc++;
      (* nut_reg->op_fcn [opcode]) (sim, opcode);
      break;
    case inst_nut_long_branch:
      nut_reg->pc++;
      op_long_branch_word_2 (sim, opcode);
      break;
    case inst_nut_cxisa:
      op_rom_to_c_cycle_2 (sim, opcode);
      break;
    case inst_nut_ldi:
      nut_reg->pc++;
      op_ldi_cycle_2 (sim, opcode);
      break;
    case inst_nut_selpf:
      nut_reg->pc++;
      op_smart_periph (sim, opcode);
      break;
    default:
      printf ("nut: bad inst_state %d!\n", nut_reg->inst_state);
      nut_reg->inst_state = inst_normal;
      break;
    }
  sim->cycle_count++;

  return (true);
}


static bool nut_execute_instruction (sim_t *sim)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  do
    {
#if 1
      (void) nut_execute_cycle (sim);
#else
      if (! nut_execute_cycle (sim))
	return false;
#endif
    }
  while (nut_reg->inst_state != inst_normal);
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


static bool nut_parse_object_line (char        *buf,
				   bank_mask_t *bank_mask,
				   addr_t      *addr,
				   rom_word_t  *opcode)
{
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

  *bank_mask = 1;
  *addr = a;
  *opcode = o;
  return (true);
}


static bool nut_parse_listing_line (char        *buf    UNUSED,
				    bank_mask_t *bank   UNUSED,
				    addr_t      *addr   UNUSED,
				    rom_word_t  *opcode UNUSED)
{
  return (false);
}


static void nut_press_key (sim_t *sim, int keycode)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

#ifdef KEYBOARD_DEBUG
  printf ("key %o press, addr %04x, state %s\n", keycode, nut_reg->prev_pc, kbd_state_name [nut_reg->kb_state]);
#endif


  // In deep sleep (display off), only the ON key can wake us.
  if ((! nut_reg->awake) && (! nut_reg->display_enable) && (keycode != 0x18))
    return;

  nut_reg->key_buf = keycode;
  nut_reg->key_down = true;
  if (nut_reg->kb_state == KB_IDLE)
    nut_reg->kb_state = KB_PRESSED;
#ifdef SLEEP_DEBUG
  if (! nut_reg->awake)
    printf ("waking up!\n");
#endif
  nut_reg->awake = true;
  chip_event (sim,
	      NULL,
	      event_wake,
	      0,
	      0,
	      NULL);
}

static void nut_release_key (sim_t *sim, int keycode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

#ifdef KEYBOARD_DEBUG
  printf ("key release, addr %04x, state %s\n", nut_reg->prev_pc, kbd_state_name [nut_reg->kb_state]);
#endif

  nut_reg->key_down = false;
  if (nut_reg->kb_state == KB_PRESSED)
    nut_reg->kb_state = KB_RELEASED;
}


static void nut_reset (sim_t *sim)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
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
  nut_reg->inst_state = inst_normal;
  nut_reg->carry = 1;

  nut_reg->kb_state = KB_IDLE;

  nut_reg->bender_last_transition_cycle = 0;
  nut_reg->bender_sound_ref = -1;  // no sound playing
}


static void nut_clear_memory (sim_t *sim)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  int addr;

  for (addr = 0; addr < MAX_RAM; addr++)
    if (nut_reg->ram_exists [addr])
      reg_zero (nut_reg->ram [addr], 0, WSIZE - 1);
}


static int nut_get_max_ram_addr (sim_t *sim UNUSED)
{
  return MAX_RAM;
}


static bool nut_read_ram (sim_t *sim, addr_t addr, uint64_t *val)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  uint64_t data = 0;
  int i;

  if (addr > MAX_RAM)
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


static bool nut_write_ram (sim_t *sim, addr_t addr, uint64_t *val)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  uint64_t data;
  int i;

  if (addr > MAX_RAM)
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


static void nut_new_rom_addr_space (sim_t *sim    UNUSED,
				    int max_bank  UNUSED,
				    int max_page  UNUSED,
				    int page_size UNUSED)
{
  ;
}



static void nut_new_pf_addr_space (sim_t *sim, int max_pf)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  nut_reg->max_pf = max_pf;
  nut_reg->pf_exists = alloc (max_pf * sizeof (bool));
}


static void nut_new_ram_addr_space (sim_t *sim, int max_ram)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  nut_reg->ram_exists   = alloc (max_ram * sizeof (bool));
  nut_reg->ram          = alloc (max_ram * sizeof (reg_t));
  nut_reg->ram_read_fn  = alloc (max_ram * sizeof (ram_access_fn_t *));
  nut_reg->ram_write_fn = alloc (max_ram * sizeof (ram_access_fn_t *));
}


static bool nut_create_ram (sim_t *sim, addr_t addr, addr_t size)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  while (size--)
    nut_reg->ram_exists [addr++] = true;

  return true;
}


static void nut_new_processor (sim_t *sim)
{
  nut_reg_t *nut_reg;

  nut_reg = alloc (sizeof (nut_reg_t));

  install_chip (sim,
		NULL,  // module
		& nut_cpu_chip_detail,
		nut_reg);

  nut_init_ops (nut_reg);

  nut_new_rom_addr_space (sim, MAX_BANK, MAX_PAGE, PAGE_SIZE);

  nut_new_ram_addr_space (sim, 1024);

  nut_new_pf_addr_space (sim, 256);

  chip_event (sim,
	      NULL,
	      event_reset,
	      0,
	      0,
	      NULL);
}


static void nut_free_processor (sim_t *sim)
{
  remove_chip (sim->first_chip);
}


static void nut_event_fn (sim_t      *sim,
			  chip_t     *chip UNUSED,
			  event_id_t event,
			  int        arg1,
			  int        arg2,
			  void       *data UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  switch (event)
    {
    case event_cycle:
      nut_kbd_scanner_cycle (nut_reg);
      break;
    case event_sleep:
      nut_kbd_scanner_sleep (nut_reg);
      break;
    case event_reset:
      nut_reset (sim);
      break;
    case event_clear_memory:
      nut_clear_memory (sim);
      break;
    case event_display_state_change:
      nut_reg->display_enable = arg1;
      break;
    case event_key:
      if (arg2)
	nut_press_key (sim, arg1);
      else
	nut_release_key (sim, arg1);
      break;
    case event_set_flag:
      nut_reg->ext_flag [arg1] = arg2;
      break;
    default:
      // warning ("proc_nut: unknown event %d\n", event);
      break;
    }
}


processor_dispatch_t nut_processor =
  {
    .new_processor       = nut_new_processor,
    .free_processor      = nut_free_processor,

    .parse_object_line   = nut_parse_object_line,
    .parse_listing_line  = nut_parse_listing_line,

    .execute_cycle       = nut_execute_cycle,
    .execute_instruction = nut_execute_instruction,

    .set_bank_group      = nut_set_bank_group,
    .get_max_rom_bank    = nut_get_max_rom_bank,
    .get_rom_page_size   = nut_get_rom_page_size,
    .get_max_rom_addr    = nut_get_max_rom_addr,
    .create_page         = nut_create_page,
    .destroy_page        = nut_destroy_page,
    .get_page_info       = nut_get_page_info,

    .read_rom            = nut_read_rom,
    .write_rom           = nut_write_rom,
    .set_rom_write_enable = nut_set_rom_write_enable,

    .get_max_ram_addr    = nut_get_max_ram_addr,
    .create_ram          = nut_create_ram,
    .read_ram            = nut_read_ram,
    .write_ram           = nut_write_ram,

    .disassemble         = nut_disassemble,
    .print_state         = nut_print_state
  };
