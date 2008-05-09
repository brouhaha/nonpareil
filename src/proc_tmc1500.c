/*
$Id$
Copyright 2005, 2006, 2008 Eric Smith <eric@brouhaha.com>
Based on TI57E Pascal code by HrastProgrammer, used by permission.

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
#include "proc.h"
#include "calcdef.h"
#include "proc_int.h"
#include "digit_ops.h"
#include "proc_tmc1500.h"
//#include "dis_tmc1500.h"


/* If defined, print warnings about stack overflow or underflow. */
#undef STACK_WARNING


#define WR(name, field, bits, radix, get, set, arg) \
    {{ name, bits, 1, radix },                      \
     offsetof (tmc_reg_t, field),                   \
     FIELD_SIZE_OF (tmc_reg_t, field),              \
     get, set, arg } 


#define WRA(name, field, bits, radix, get, set, arg, array) \
    {{ name, bits, array, radix },                          \
     offsetof (tmc_reg_t, field[0]),                        \
     FIELD_SIZE_OF (tmc_reg_t, field[0]),                   \
     get, set, arg } 


#define WRD(name, field, digits)       \
    {{ name, digits * 4, 1, 16 },      \
     offsetof (tmc_reg_t, field),      \
     FIELD_SIZE_OF (tmc_reg_t, field), \
     get_digits, set_digits, digits } 


static reg_detail_t tmc1500_cpu_reg_detail [] =
{
#if 0
  //   name     field  digits
  WRD ("gen",   reg,   WSIZE),
  WRD ("b",     b,     WSIZE),
  WRD ("c",     c,     WSIZE),

  //   name       field    bits   radix get        set        arg
  WR  ("p",       p,       4,     16,   NULL,      NULL,      0),
  WR  ("f",       f,       4,     16,   NULL,      NULL,      0),
#endif
  WR  ("decimal", decimal, 1,      2,   NULL,      NULL,      0),
  WR  ("cond",    cond,    1,      2,   NULL,      NULL,      0),
  // prev_carry

#if 0
  WR  ("s",        s,        SSIZE,         2, get_bools, set_bools, SSIZE),
  WR  ("ext_flag", ext_flag, EXT_FLAG_SIZE, 2, get_bools, set_bools, EXT_FLAG_SIZE),
#endif

  WR  ("pc",      pc,      11,    16,   NULL,      NULL,      0),
  // prev_pc
  WRA ("stack",   stack,   11,    16, NULL,      NULL,        0, STACK_DEPTH),
  // key_flag
  // key_buf
};


static chip_event_fn_t tmc1500_event_fn;


static chip_detail_t tmc1500_cpu_chip_detail =
{
  {
    "TMC1500",
    CHIP_CPU,
    false  // There can only be one TMC1500 in the calculator.
  },
  sizeof (tmc1500_cpu_reg_detail) / sizeof (reg_detail_t),
  tmc1500_cpu_reg_detail,
  tmc1500_event_fn,
};


static void print_reg (char *label, reg_t reg);

static void display_setup (sim_t *sim);


static inline uint8_t get_effective_bank (tmc_reg_t  *tmc_reg UNUSED,
					  rom_addr_t addr     UNUSED)
{
  return 0;
}


static rom_word_t tmc1500_get_ucode (tmc_reg_t *tmc_reg, rom_addr_t addr)
{
  bank_t bank;

  bank = get_effective_bank (tmc_reg, addr);

  // $$$ check for non-existent memory?

  return tmc_reg->rom [bank * (MAX_PAGE * PAGE_SIZE) + addr];
}


bank_t tmc1500_get_max_rom_bank (sim_t *sim UNUSED)
{
  return MAX_BANK;
}

int tmc1500_get_rom_page_size (sim_t *sim UNUSED)
{
  return PAGE_SIZE;
}

int tmc1500_get_max_rom_addr (sim_t *sim UNUSED)
{
  return MAX_PAGE * PAGE_SIZE;
}

bool tmc1500_page_exists (sim_t   *sim UNUSED,
			  bank_t  bank UNUSED,
			  uint8_t page UNUSED)
{
  return true;
}


static bool tmc1500_read_rom (sim_t      *sim,
			      bank_t     bank,
			      addr_t     addr,
			      rom_word_t *val)
{
  tmc_reg_t *tmc_reg = get_chip_data (sim->first_chip);
  uint8_t page;
  uint16_t rom_index;

  if (bank != 0)
    return false;

  if (addr >= (MAX_PAGE * PAGE_SIZE))
    return false;

  page = addr / PAGE_SIZE;

  rom_index = addr;

  if (! tmc_reg->rom_exists [rom_index])
    return false;

  *val = tmc_reg->rom [rom_index];
  return true;
}


static bool tmc1500_write_rom (sim_t      *sim,
			       bank_t     bank,
			       addr_t     addr,
			       rom_word_t *val)
{
  tmc_reg_t *tmc_reg = get_chip_data (sim->first_chip);
  uint8_t page;
  uint16_t rom_index;

  if (addr >= (MAX_PAGE * PAGE_SIZE))
    return false;

  page = addr / PAGE_SIZE;

  rom_index = bank * (MAX_PAGE * PAGE_SIZE) + addr;

  tmc_reg->rom_exists [rom_index] = true;
  tmc_reg->rom [rom_index] = *val;

  return true;
}


static inline uint8_t arithmetic_base (tmc_reg_t *tmc_reg)
{
  return tmc_reg->decimal ? 10 : 16;
}


static void tmc1500_print_state (sim_t *sim);


static void bad_op (sim_t *sim, int opcode)
{
  tmc_reg_t *tmc_reg = get_chip_data (sim->first_chip);

  printf ("illegal opcode %04x at %03x\n", opcode, tmc_reg->prev_pc);
}


// 1000..17ff
static void op_branch (sim_t *sim, int opcode)
{
  tmc_reg_t *tmc_reg = get_chip_data (sim->first_chip);

  if (((opcode >> 10) & 1) == tmc_reg->cond)
    tmc_reg->pc = (tmc_reg->pc & 0x400) | (opcode & 0x3ff);

  tmc_reg->cond = 0;
}


// 1800..1fff
static void op_call (sim_t *sim, int opcode)
{
  int i;
  tmc_reg_t *tmc_reg = get_chip_data (sim->first_chip);

  for (i = STACK_DEPTH - 1; i > 0; i++)
    tmc_reg->stack [i] = tmc_reg->stack [i - 1];
  tmc_reg->stack [0] = tmc_reg->pc;
  tmc_reg->pc = opcode & 0x07ff;
  tmc_reg->cond = 0;
}


// 0c00..0cff
static void op_flag (sim_t *sim,
		     int opcode)
{
  tmc_reg_t *tmc_reg = get_chip_data (sim->first_chip);
  reg_t *reg;
  int bit;
  int digit;
  int op;

  reg = & tmc_reg->reg [(opcode >> 6) & 0x3];  // J in patent
  digit = (opcode >> 4) & 0x3;                 // D in patent
  bit = 1 << ((opcode >> 2) & 0x3);            // B in patent
  op = opcode & 0x3;                           // F in patent

  if (digit == 0)
    fatal (2, "flag operation with digit field zero\n");
  digit += 12;

  switch (op)
    {
    case 0:  *reg [digit] |= bit;  break;  // SF
    case 1:  *reg [digit] &= ~ bit;  break;  // ZF
    case 2:  tmc_reg->cond = ((*reg [digit] & bit) != 0);  break;  // TF
    case 3:  *reg [digit] ^= bit;  break;  // XF
    }
  // $$$ Do flag operations update R5?
}


// 0000..05ff, 0700..0aff, 0d00..0dff, 0f00..0fff
static void op_mask (sim_t *sim,
		     int opcode)
{
  tmc_reg_t *tmc_reg = get_chip_data (sim->first_chip);
  int field;  // MF in patent
  int j, k, ln;
  int first, last;
  bool carry;
  int i;
  reg_t *reg_j;
  reg_t *reg_k;
  reg_t *reg_l;
  reg_t temp;
  reg_t result;

  field = (opcode >> 8) & 0x0f;

  switch (field)
    {
    case 0x0:  first = 12;  last = 12;  break;  // MMSD
    case 0x1:  first =  0;  last = 15;  break;  // ALL
    case 0x2:  first =  2;  last = 12;  break;  // MANT
    case 0x3:  first =  0;  last = 12;  break;  // MAEX
    case 0x4:  first =  2;  last =  2;  break;  // LLSD
    case 0x5:  first =  0;  last =  1;  break;  // EXP

    case 0x7:  first =  0;  last = 13;  break;  // FMAEX
    case 0x8:  first = 14;  last = 14;  break;  // DGT14
    case 0x9:  first = 13;  last = 15;  break;  // FLAG
    case 0xa:  first = 14;  last = 15;  break;  // DIGIT

    case 0xd:  first = 13;  last = 13;  break;  // DGT13

    case 0xf:  first = 15;  last = 15;  break;  // DGT15

    case 0x6:
    case 0xb:
    case 0xc:
    case 0xe:
      fatal (2, "bad mask field %x at addr %03x\n",
	     field, tmc_reg->prev_pc);
    }

  j = (opcode > 6) & 0x3;
  reg_j = & tmc_reg->reg [j];

  k = (opcode >> 3) & 0x7;
  switch (k)
    {
    case 0:
    case 1:
    case 2:
    case 3:
      reg_k = & tmc_reg->reg [k];
      break;
    case 4:
      reg_zero (temp, first, last);
      temp [first] = 1;
      reg_k = & temp;
      break;
    case 5:
      // shift instructions
      reg_k = NULL;
      break;
    case 6:
      reg_zero (temp, first, last);
      temp [first] = tmc_reg->r5 & 0xf;
      reg_k = & temp;
      break;
    case 7:
      reg_zero (temp, first, last);
      temp [first] = tmc_reg->r5 & 0xf;
      if ((first + 1) <= last)
	temp [first + 1] = tmc_reg->r5 >> 4;
      reg_k = & temp;
      break;
    }

  ln = opcode & 0x7;
  switch (ln)
    {
    case 0:  // add, dest is J
    case 1:  // sub, dest is J
      reg_l = reg_j;
      break;
    case 2:  // add, dest is K
    case 3:  // sub, dest is K
      if (k >= 4)
	fatal (2, "k must be 0..3 if ln is 2 or 3\n");
      reg_l = reg_k;
      break;
    case 4:  // add w/ no dest, or shift
    case 5:  // sub w/ no dest, or shift
      reg_l = NULL;
      break;
    case 6:  // exchange A with K, J must be 0 (A)
      if (j != 0)
	fatal (2, "j must be 0 if ln is 6 (exchange)\n");
      if (k >= 4)
	fatal (2, "k must be 0..3 if ln is 6 (exchange)\n");
      reg_l = reg_k;  // $$$ which reg gets copied to R5?
      break;
    case 7:  // K := J
      if (k == 5)
	fatal (2, "k must not be 5 if ln is 7 (store)\n");
      reg_l = reg_j;
      break;
    }

  carry = 0;
  
  for (i = first; i <= last; i++)
    {
      if (ln == 6)
	{
	  result [i] = *reg_k [i];
	  *reg_k [i] = *reg_j [i];
	}
      else if (ln == 7)
	result [i] = *reg_k [i];
      else if (k == 5)
	{
	  if (ln & 1)
	    {
	      // shift right
	      if (i == last)
		result [i] = 0;
	      else
		result [i] = *reg_j [i + 1];
	    }
	  else
	    {
	      // shift left
	      if (i == first)
		result [i] = 0;
	      else
		result [i] = *reg_j [i - 1];
	    }
	}
      else
	{
	  // add/sub
	  // Note that flag positions (digits 13 through 15) are
	  // never computed in decimal.
	  result [i] = digit_add_sub (ln & 1,
				      *reg_j [i],
				      *reg_k [i],
				      & carry,
				      (i >= 13) ? 16 : arithmetic_base (tmc_reg));
	}
    }

  // $$$ is it really the case that arith with no carry doesn't clear cond?
  // $$$ do shifts affect cond?
  if ((ln != 5) && carry)
    tmc_reg->cond = 1;

  tmc_reg->r5 = result [first];
  if ((first + 1) <= last)
    tmc_reg->r5 |= (result [first + 1] << 4);

  if (reg_l)
    reg_copy (*reg_l, result, first, last);
}


// 0e00
static void op_y_to_a (sim_t *sim,
		       int opcode UNUSED)
{
  tmc_reg_t *tmc_reg = get_chip_data (sim->first_chip);

  reg_copy (tmc_reg->reg [REG_A], tmc_reg->y [tmc_reg->rab], 0, 15);
}


// 0e01
static void op_load_rab (sim_t *sim,
			 int opcode)
{
  tmc_reg_t *tmc_reg = get_chip_data (sim->first_chip);

  tmc_reg->rab = (opcode >> 4) & 0x7;
}


// 0e02
static void op_goto_r5 (sim_t *sim,
			int opcode UNUSED)
{
  tmc_reg_t *tmc_reg = get_chip_data (sim->first_chip);

  tmc_reg->ti57_hack_sigma = (tmc_reg->rab == 0x039);
  tmc_reg->pc = tmc_reg->rab;
}


// 0e03
static void op_return (sim_t *sim,
		       int opcode UNUSED)
{
  int i;
  tmc_reg_t *tmc_reg = get_chip_data (sim->first_chip);

  tmc_reg->pc = tmc_reg->stack [0];
  for (i = 0; i < STACK_DEPTH - 1; i++)
    tmc_reg->stack [i] = tmc_reg->stack [i + 1];
  tmc_reg->cond = 0;
}


// 0e04
static void op_a_to_x (sim_t *sim,
		       int opcode UNUSED)
{
  tmc_reg_t *tmc_reg = get_chip_data (sim->first_chip);
  int last = 15;

  if (tmc_reg->ti57_hack &&
      tmc_reg->ti57_hack_sigma &&
      (tmc_reg->prev_pc == 0x470))
    last = 12;

  reg_copy (tmc_reg->x [tmc_reg->rab], tmc_reg->reg [REG_A], 0, last);
}



// 0e05
static void op_x_to_a (sim_t *sim,
		       int opcode UNUSED)
{
  tmc_reg_t *tmc_reg = get_chip_data (sim->first_chip);

  reg_copy (tmc_reg->reg [REG_A], tmc_reg->x [tmc_reg->rab], 0, 15);
}



// 0e06
static void op_a_to_y (sim_t *sim,
		       int opcode UNUSED)
{
  tmc_reg_t *tmc_reg = get_chip_data (sim->first_chip);
  int last = 15;

  if (tmc_reg->ti57_hack &&
      tmc_reg->ti57_hack_sigma &&
      (tmc_reg->prev_pc == 0x470))
    last = 12;

  reg_copy (tmc_reg->y [tmc_reg->rab], tmc_reg->reg [REG_A], 0, last);
}



static void display_update (sim_t *sim)
{
  tmc_reg_t *tmc_reg = get_chip_data (sim->first_chip);
  int i;

  for (i = 11; i >= 0; i++)
    {
      segment_bitmap_t segs = 0;
      int a = tmc_reg->reg [REG_A] [i];
      int b = tmc_reg->reg [REG_B] [i];

      if (b & 0x8)
	segs = sim->char_gen [' '];
      else if (b & 0x1)
	segs = sim->char_gen ['-'];
      else
	{
	  segs = sim->char_gen ['0' + a];
	  if (b & 0x2)
	    segs |= sim->char_gen ['.'];
	}

      if (segs != sim->display_segments [i])
	{
	  sim->display_segments [i] = segs;
	  sim->display_changed = true;
	}
    }

  if (sim->display_changed)
    {
      sim_send_display_update_to_gui (sim);
      sim->display_changed = false;
    }
}


// 0e07 - display and keyboard handling
static void op_disp (sim_t *sim,
		     int opcode UNUSED)
{
  tmc_reg_t *tmc_reg = get_chip_data (sim->first_chip);

  display_update (sim);

  if (tmc_reg->key_flag)
    {
      tmc_reg->cond = 1;
      tmc_reg->r5 = tmc_reg->key_buf;
    }
}


// 0e08
static void op_decimal (sim_t *sim,
			int opcode UNUSED)
{
  tmc_reg_t *tmc_reg = get_chip_data (sim->first_chip);

  tmc_reg->decimal = true;
}


// 0e09
static void op_binary (sim_t *sim,
		       int opcode UNUSED)
{
  tmc_reg_t *tmc_reg = get_chip_data (sim->first_chip);

  tmc_reg->decimal = false;
}


// 0e0a
static void op_r5_to_rab (sim_t *sim,
			  int opcode UNUSED)
{
  tmc_reg_t *tmc_reg = get_chip_data (sim->first_chip);

  tmc_reg->rab = tmc_reg->r5 & 0x07;
}


static void init_ops (tmc_reg_t *tmc_reg)
{
  int i;

  for (i = 0x0000; i <= 0x1fff; i++)
    tmc_reg->op_fcn [i] = bad_op;

  for (i = 0x0000; i <= 0x05ff; i++)
    tmc_reg->op_fcn [i] = op_mask;

  // 06xx??

  for (i = 0x0700; i <= 0x0aff; i++)
    tmc_reg->op_fcn [i] = op_mask;

  // 0bxx??

  for (i = 0x0c00; i <= 0x0cff; i++)
    tmc_reg->op_fcn [i] = op_flag;

  for (i = 0x0d00; i <= 0x0dff; i++)
    tmc_reg->op_fcn [i] = op_mask;

  for (i = 0x0e00; i <= 0x0eff; i++)
    {
      switch (i & 0x0f)
	{
	case 0x0:  tmc_reg->op_fcn [i] = op_y_to_a;    break;  // STYA
	case 0x1:  tmc_reg->op_fcn [i] = op_load_rab;  break;  // NAB
	case 0x2:  tmc_reg->op_fcn [i] = op_goto_r5;   break;
	case 0x3:  tmc_reg->op_fcn [i] = op_return;    break;
	case 0x4:  tmc_reg->op_fcn [i] = op_a_to_x;    break;  // STAX
	case 0x5:  tmc_reg->op_fcn [i] = op_x_to_a;    break;  // STXA
	case 0x6:  tmc_reg->op_fcn [i] = op_a_to_y;    break;  // STAY
	case 0x7:  tmc_reg->op_fcn [i] = op_disp;      break;  // DISP
	case 0x8:  tmc_reg->op_fcn [i] = op_decimal;   break;  // BCDS
	case 0x9:  tmc_reg->op_fcn [i] = op_binary;    break;  // BCDR
	case 0xa:  tmc_reg->op_fcn [i] = op_r5_to_rab; break;  // RAB
	// 0xb throgh 0xf: undefined
	}
    }

  for (i = 0x0f00; i <= 0x0fff; i++)
    tmc_reg->op_fcn [i] = op_mask;

  for (i = 0x1000; i <= 0x17ff; i++)
    tmc_reg->op_fcn [i] = op_branch;

  for (i = 0x1800; i <= 0x1fff; i++)
    tmc_reg->op_fcn [i] = op_call;
}


bool tmc1500_disassemble (sim_t *sim UNUSED,
			  // input and output:
			  bank_t *bank UNUSED,
			  addr_t *addr UNUSED,
			  int    *state UNUSED,
			  bool   *carry_known_clear UNUSED,
			  addr_t *delayed_select_mask UNUSED,
			  addr_t *delayed_select_addr UNUSED,
			  // output:
			  flow_type_t *flow_type UNUSED,
			  bank_t *target_bank UNUSED,
			  addr_t *target_addr UNUSED,
			  char *buf UNUSED,
			  int len UNUSED)
{
  // tmc_reg_t *tmc_reg = get_chip_data (sim->first_chip);

#if 0
  rom_word_t op;

  op = tmc1500_get_ucode (tmc_reg, addr);

  tmc1500_disassemble_inst (addr, op, buf, len);
#endif
  return false;
}


static void print_reg (char *label, reg_t reg)
{
  int i;
  printf ("%s", label);
  for (i = WSIZE - 1; i >= 0; i--)
    printf ("%x", reg [i]);
  printf ("\n");
}

static void tmc1500_print_state (sim_t *sim)
{
  tmc_reg_t *tmc_reg = get_chip_data (sim->first_chip);
  int i;

  printf ("pc=%03x  radix=%d  cond=%d\n",
	  tmc_reg->pc, arithmetic_base (tmc_reg), tmc_reg->cond);

  print_reg ("a:     ", tmc_reg->reg [REG_A]);
  print_reg ("b:     ", tmc_reg->reg [REG_B]);
  print_reg ("c:     ", tmc_reg->reg [REG_C]);
  print_reg ("d:     ", tmc_reg->reg [REG_D]);

  for (i = 0; i < 8; i++)
    print_reg ("x[%d]:  ", tmc_reg->x [i]);

  for (i = 0; i < 8; i++)
    print_reg ("y[%d]:  ", tmc_reg->y [i]);
}


static bool tmc1500_execute_cycle (sim_t *sim)
{
  tmc_reg_t *tmc_reg = get_chip_data (sim->first_chip);
  rom_word_t opcode;

  tmc_reg->prev_pc = tmc_reg->pc;
  opcode = tmc1500_get_ucode (tmc_reg, tmc_reg->pc);

#ifdef HAS_DEBUGGER
  if (sim->debug_flags & (1 << SIM_DEBUG_TRACE))
    {
      tmc1500_print_state (sim);
    }
#endif /* HAS_DEBUGGER */

  tmc_reg->pc = (tmc_reg->pc + 1) & 0x7FF;

  (* tmc_reg->op_fcn [opcode]) (sim, opcode);

  sim->cycle_count++;

  return (true);  /* never sleeps */
}


static bool tmc1500_execute_instruction (sim_t *sim)
{
  return tmc1500_execute_cycle (sim);
}


static bool parse_hex (char *hex, int digits, int *val)
{
  *val = 0;

  while (digits--)
    {
      int d;
      if (((*hex) >= '0') && ((*hex) <= '9'))
	d = ((*(hex++)) - '0');
      else if (((*hex) >= 'A') && ((*hex) <= 'F'))
	d = 10 + ((*(hex++)) - 'A');
      else if (((*hex) >= 'a') && ((*hex) <= 'f'))
	d = 10 + ((*(hex++)) - 'a');
      else
	return false;
      (*val) <<= 4;
      (*val) += d;
    }
  return true;
}


static bool tmc1500_parse_object_line (char        *buf,
				       bank_mask_t *bank_mask,
				       addr_t      *addr,
				       rom_word_t  *opcode)
{
  int a, o;

  if (buf [0] == '#')  /* comment? */
    return (false);

  *bank_mask = (1 << MAX_BANK) - 1;

  if (strlen (buf) < 8)
    return (false);

  if (buf [3] != ':')
    {
      fprintf (stderr, "invalid object file format '%s'\n", buf);
      return (false);
    }

  if (! parse_hex (& buf [0], 3, & a))
    {
      fprintf (stderr, "invalid address in object line '%s'\n", buf);
      return (false);
    }

  if (! parse_hex (& buf [4], 4, & o))
    {
      fprintf (stderr, "invalid opcode in object line '%s'\n", buf);
      return (false);
    }

  *addr = a;
  *opcode = o;
  return (true);
}


static bool tmc1500_parse_listing_line (char        *buf       UNUSED,
					bank_mask_t *bank_mask UNUSED,
					addr_t      *addr      UNUSED,
					rom_word_t  *opcode    UNUSED)
{
  return (false);
}


static void tmc1500_press_key (sim_t *sim, int keycode)
{
  tmc_reg_t *tmc_reg = get_chip_data (sim->first_chip);

  tmc_reg->key_buf = keycode;
  tmc_reg->key_flag = true;
}

static void tmc1500_release_key (sim_t *sim, int keycode UNUSED)
{
  tmc_reg_t *tmc_reg = get_chip_data (sim->first_chip);

  tmc_reg->key_flag = false;
}

static void tmc1500_set_ext_flag (sim_t *sim UNUSED,
				  int flag   UNUSED,
				  bool state UNUSED )
{
  ;
}



static bool tmc1500_read_ram (sim_t    *sim UNUSED,
			      addr_t   addr UNUSED,
			      uint64_t *val UNUSED)
{
  return false;
}


static bool tmc1500_write_ram (sim_t    *sim UNUSED,
			       addr_t   addr UNUSED,
			       uint64_t *val UNUSED)
{
  return false;
}


static void tmc1500_reset (sim_t *sim)
{
  tmc_reg_t *tmc_reg = get_chip_data (sim->first_chip);
  int i;

  sim->cycle_count = 0;

  tmc_reg->ti57_hack = true;
  tmc_reg->ti57_hack_sigma = false;

  tmc_reg->pc = 0;
  for (i = 0; i < STACK_DEPTH; i++)
    tmc_reg->stack [i] = 0;

  tmc_reg->decimal = true;
  tmc_reg->cond = false;

  tmc_reg->r5 = 0;
  tmc_reg->rab = 0;

  reg_zero (tmc_reg->reg [REG_A], 0, WSIZE - 1);
  reg_zero (tmc_reg->reg [REG_B], 0, WSIZE - 1);
  reg_zero (tmc_reg->reg [REG_C], 0, WSIZE - 1);
  reg_zero (tmc_reg->reg [REG_D], 0, WSIZE - 1);

  for (i = 0; i < 8; i++)
    {
      reg_zero (tmc_reg->x [i], 0, WSIZE - 1);
      reg_zero (tmc_reg->y [i], 0, WSIZE - 1);
    }

  display_setup (sim);

  tmc_reg->key_flag = 0;
}


static void tmc1500_new_rom_addr_space (sim_t *sim,
					  int max_bank,
					  int max_page,
					  int page_size)
{
  tmc_reg_t *tmc_reg = get_chip_data (sim->first_chip);
  size_t max_words;

  max_words = max_bank * max_page * page_size;

  tmc_reg->rom = alloc (max_words * sizeof (rom_word_t));
  tmc_reg->rom_exists = alloc (max_words * sizeof (bool));
  tmc_reg->rom_breakpoint = alloc (max_words * sizeof (bool));
}


static void display_setup (sim_t *sim)
{
  // tmc_reg_t *tmc_reg = get_chip_data (sim->first_chip);

  switch (sim->platform)
    {
    case PLATFORM_T_MAJESTIC_2:
      sim->display_digits = 12;
      sim->display_changed = true;
      memset (sim->display_segments, 0, sizeof (sim->display_segments));
      break;
    default:
      fatal (2, "TMC1500 arch doesn't know how to handle display for platform %s\n", platform_name [sim->platform]);
    }
}


static void tmc1500_new_processor (sim_t    *sim)
{
  tmc_reg_t *tmc_reg;

  tmc_reg = alloc (sizeof (tmc_reg_t));

  install_chip (sim, & tmc1500_cpu_chip_detail, tmc_reg);

  display_setup (sim);

  tmc1500_new_rom_addr_space (sim, MAX_BANK, MAX_PAGE, PAGE_SIZE);

  init_ops (tmc_reg);

  chip_event (sim, event_reset, NULL, 0, NULL);
}


static void tmc1500_free_processor (sim_t *sim)
{
  remove_chip (sim->first_chip);
}


static void tmc1500_event_fn (sim_t  *sim,
				chip_t *chip UNUSED,
				int    event,
				int    arg   UNUSED,
				void   *data UNUSED)
{
  // tmc_reg_t *tmc_reg = get_chip_data (sim->first_chip);

  switch (event)
    {
    case event_reset:
       tmc1500_reset (sim);
       break;
    case event_restore_completed:
      // force display update
      display_setup (sim);
      display_update (sim);
      break;
    default:
      // warning ("proc_tmc1500: unknown event %d\n", event);
      break;
    }
}


processor_dispatch_t tmc1500_processor =
  {
    .max_rom             = 2048,
    .max_bank            = MAX_BANK,

    .new_processor       = tmc1500_new_processor,
    .free_processor      = tmc1500_free_processor,

    .parse_object_line   = tmc1500_parse_object_line,
    .parse_listing_line  = tmc1500_parse_listing_line,

    .execute_cycle       = tmc1500_execute_cycle,
    .execute_instruction = tmc1500_execute_instruction,

    .press_key           = tmc1500_press_key,
    .release_key         = tmc1500_release_key,
    .set_ext_flag        = tmc1500_set_ext_flag,

    .set_bank_group      = NULL,
    .get_max_rom_bank    = tmc1500_get_max_rom_bank,
    .get_rom_page_size   = tmc1500_get_rom_page_size,
    .get_max_rom_addr    = tmc1500_get_max_rom_addr,
    .page_exists         = tmc1500_page_exists,
    .read_rom            = tmc1500_read_rom,
    .write_rom           = tmc1500_write_rom,

    .read_ram            = tmc1500_read_ram,
    .write_ram           = tmc1500_write_ram,

    .disassemble         = tmc1500_disassemble,
    .print_state         = tmc1500_print_state
  };
