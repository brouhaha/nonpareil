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
#include "model.h"
#include "util.h"
#include "display.h"
#include "proc.h"
#include "proc_int.h"
#include "digit_ops.h"
#include "coconut_lcd.h"
#include "voyager_lcd.h"
#include "proc_nut.h"
#include "dis_nut.h"
#include "sound.h"


// instruction flags
#define L1 (1<<1)  // Level 1 instructions - 1LK7 and later
#define L2 (1<<2)  // Level 2 instructions - 1LR2 and later
#define L3 (1<<3)  // Level 3 instructions - unknown
#define L4 (1<<4)  // Apple (Saturn emulated on ARM)

typedef void inst_fn_t (struct sim_t *sim);

typedef struct inst_info_t
{
  uint32_t flags;
  int inst_digits;
  int opcode_digits;
  struct inst_info_t *table,
  inst_fn_t *inst_fn;
} inst_info_t;


#define WARN_STRAY_WRITE


static void print_reg (reg_t reg);


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
  // long_branch_carry
  // prev_carry
  // NR  ("selprf",  selprf,  4,     16,   NULL,      NULL,      0),

  // display_enable
};


static chip_event_fn_t nut_event_fn;


static chip_detail_t nut_cpu_chip_detail =
{
  {
    "Nut",
    CHIP_CPU,
    false  // There can only be one Nut processor in the calculator.
  },
  sizeof (nut_cpu_reg_detail) / sizeof (reg_detail_t),
  nut_cpu_reg_detail,
  nut_event_fn
};


static inline uint8_t arithmetic_base (saturn_reg_t *nut_reg)
{
  return saturn_reg->decimal ? 10 : 16;
}


static void bad_op (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  printf ("illegal opcode %03x at %04x\n", opcode, nut_reg->prev_pc);
}


static void op_load_p (sim_t *sim)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);

  saturn_reg->p = saturn_reg->operand [0];
}


static void op_load_c (sim_t *sim)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);

  if (saturn_reg->operand_digits)
    {
      reg_copy (saturn_reg->c,                     // dest
		saturn_reg->operand,               // src
		0,                                 // first
		saturn_reg->operand_digits - 1);   // last
    }
  else
    {
      saturn_reg->operand_digits = ???;
      // $$$ more code needed here
    }
}


static void op_goc (sim_t *sim)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);

  // $$$ more code needed here
}


static void op_gonc (sim_t *sim)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);

  // $$$ more code needed here
}


static void op_goto (sim_t *sim)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);

  // $$$ more code needed here
}


static void op_gosub (sim_t *sim)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);

  // $$$ more code needed here
}


static void op_compare_a (sim_t *sim)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);

  // $$$ more code needed here
}


static void op_compare_fs (sim_t *sim)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);

  // $$$ more code needed here
}


static void r_eq_r_plus_s (sim_t *sim,
			   int op,
			   int r_reg,
			   int s_reg,
			   int first_digit,
			   int last_digit)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);

  switch (op)
    {
    case 0x0:  // r = r + s
      reg_add (r_reg, r_reg, s_reg,
	       first, last,
	       & saturn_reg->carry,
	       arithmetic_base (saturn_reg));
      break;

    case 0x1:  // r = r + r
      reg_add (r_reg, r_reg, r_reg,
	       first, last,
	       & saturn_reg->carry,
	       arithmetic_base (saturn_reg));
      break;

    case 0x2:  // s = r + s
      reg_add (s_reg, r_reg, r_reg,
	       first, last,
	       & saturn_reg->carry,
	       arithmetic_base (saturn_reg));
      break;

    case 0x3:  // r = r - 1
      saturn_reg->carry = 1;
      reg_sub (r_reg, r_reg, NULL,
	       first, last,
	       & saturn_reg->carry,
	       arithmetic_base (saturn_reg));
      break;

    case 0x4:  // r = 0
      reg_zero (r_reg, first, last);
      break;

    case 0x5:  // r = s
      reg_copy (r_reg, s_reg, first, last);
      break;

    case 0x6:  // s = r
      reg_copy (s_reg, r_reg, first, last);
      break;

    case 0x7:  // r exch s
      reg_exch (r_reg, s_reg, first, last);
      break;

    case 0x8:  // r = r - s
      reg_sub (r_reg, r_reg, s_reg,
	       first, last,
	       & saturn_reg->carry,
	       arithmetic_base (saturn_reg));
      break;

    case 0x9:  // r = r + 1
      nut_reg->carry = 1;
      reg_add (r_reg, r_reg, NULL,
	       first, last,
	       & saturn_reg->carry,
	       arithmetic_base (saturn_reg));
      break;

    case 0xa:  // s = s - r
      reg_sub (s_reg, s_reg, r_reg,
	       first, last,
	       & saturn_reg->carry,
	       arithmetic_base (saturn_reg));
      break;

    case 0xb:  // r = s - r
      reg_sub (r_reg, s_reg, r_reg,
	       first, last,
	       & saturn_reg->carry,
	       arithmetic_base (saturn_reg));
      break;

    case 0xc:  // r shift left
      reg_shift_right (r_reg, first, last);
      break;

    case 0xd:  // r shift right
      reg_shift_right (r_reg, first, last);
      break;

    case 0xe:  // r = -r
      reg_sub (r_reg, NULL, r_reg,
	       first, last,
	       & saturn_reg->carry,
	       arithmetic_base (saturn_reg));
      break;

    case 0xf:  // r = -r-1
      saturn_reg->carry = 1;
      reg_sub (r_reg, NULL, r_reg,
	       first, last,
	       & saturn_reg->carry,
	       arithmetic_base (saturn_reg));
      break;
    }
}


int dest_reg [4] = { REG_A, REG_B, REG_C, REG_D };
int src_reg  [4] = { REG_B, REG_C, REG_A, REG_C };
int first_digit [8] = { };
int last_digit [8] = { };

static void op_arith_fs (sim_t *sim)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);

  int rr, op, field;

  rr = saturn_reg->inst [2] & 0x03;
  op = (((saturn_reg->inst [0] & 0x01) << 3) +
	((saturn_reg->inst [1] & 0x08) >> 1) +
	((saturn_reg->inst [2] & 0xc0) >> 2));
  op_arith (sim,
	    op,
	    r_reg [rr],
	    s_reg [rr],
	    first_digit [field],
	    last_digit [field]);
}


static void op_arith_a (sim_t *sim)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);

  int rr, op;

  rr = saturn_reg->inst [1] & 0x03;
  op = (((saturn_reg->inst [0] & 0x03) << 2) +
	((saturn_reg->inst [1] & 0x0c) >> 2));
  op_arith (sim,
	    op,
	    r_reg [rr],
	    s_reg [rr],
	    0,
	    4);
}


static void op_arith_rtnsxm (sim_t *sim)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);

  // $$$ more code needed here
}


static void op_arith_rtn (sim_t *sim)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);

  // $$$ more code needed here
}


static void op_arith_rtnsc (sim_t *sim)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);

  // $$$ more code needed here
}


static void op_arith_rtncc (sim_t *sim)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);

  // $$$ more code needed here
}


static void op_arith_sethex (sim_t *sim)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);

  saturn_reg->decimal = false;
}


static void op_arith_setdec (sim_t *sim)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);

  saturn_reg->decimal = true;
}


static void op_arith_rstk_from_c (sim_t *sim)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);

  // $$$ more code needed here
}


static void op_arith_c_from_rstk (sim_t *sim)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);

  // $$$ more code needed here
}


static void op_clrst (sim_t *sim)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);

  // $$$ more code needed here
}


static void op_arith_c_from_st (sim_t *sim)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);

  // $$$ more code needed here
}


static void op_arith_st_from_c (sim_t *sim)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);

  // $$$ more code needed here
}


static void op_arith_cstex (sim_t *sim)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);

  // $$$ more code needed here
}


static void op_p_inc (sim_t *sim)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);

  // $$$ more code needed here
}


static void op_p_dec (sim_t *sim)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);

  // $$$ more code needed here
}


static void op_rti (sim_t *sim)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);

  // $$$ more code needed here
}


static void op_rn_from_a (sim_t *sim)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);

  // $$$ more code needed here
}


static void op_a_from_rn (sim_t *sim)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);

  // $$$ more code needed here
}


static void op_c_exch_rn (sim_t *sim)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);

  // $$$ more code needed here
}


static void op_13x (sim_t *sim)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);

  // $$$ more code needed here
}


static void op_14x (sim_t *sim)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);

  // $$$ more code needed here
}


static void op_15x (sim_t *sim)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);

  // $$$ more code needed here
}


static void op_d_add (sim_t *sim)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);

  // $$$ more code needed here
}


static void op_d_sub (sim_t *sim)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);

  // $$$ more code needed here
}


static void op_d_load (sim_t *sim)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);

  // $$$ more code needed here
}


static inst_info_t inst_info_808x [16] =
{
  /* 8080 */ { 0,  4, 0, NULL,              op_intoff },
  /* 8081 */ { L2, 5, 0, NULL,              op_rsi },
  /* 8082 */ { L2, 4, 0, NULL,              bad_op }, // LA(n)
  /* 8083 */ { L2, 4, 0, NULL,              bad_op }, // BUSCB
  /* 8084 */ { L2, 5, 0, NULL,              bad_op }, // ABIT=0 d
  /* 8085 */ { L2, 5, 0, NULL,              bad_op }, // ABIT=1 d
  /* 8086 */ { L2, 5, 2, NULL,              bad_op }, // ?ABIT=0 d
  /* 8087 */ { L2, 5, 2, NULL,              bad_op }, // ?ABIT=1 d
  /* 8088 */ { L2, 5, 0, NULL,              bad_op }, // CBIT=0 d
  /* 8089 */ { L2, 5, 0, NULL,              bad_op }, // CBIT=1 d
  /* 808a */ { L2, 5, 2, NULL,              op_test_c_bit_zero },  // ?CBIT=0 d
  /* 808b */ { L2, 5, 2, NULL,              op_test_c_bit_nonzero },  // ?CBIT=1 d
  /* 808c */ { L1, 4, 0, NULL,              op_pc_from_ind_a },  // PC=(A)
  /* 808d */ { L2, 4, 0, NULL,              bad_op },  // BUSCD
  /* 808e */ { L2, 4, 0, NULL,              bad_op }, // PC=(C)
  /* 808f */ { L2, 4, 0, NULL,              op_inton }, 
}


static inst_info_t inst_info_80x [16] =
{
  /* 800 */ { 0,  3, 0, NULL,              op_out_cs },
  /* 801 */ { 0,  3, 0, NULL,              op_out_c },
  /* 802 */ { 0,  3, 0, NULL,              bad_op },
  /* 803 */ { 0,  3, 0, NULL,              bad_op },
  /* 804 */ { 0,  3, 0, NULL,              op_unconfig },
  /* 805 */ { 0,  3, 0, NULL,              op_config },
  /* 806 */ { 0,  3, 0, NULL,              bad_op },
  /* 807 */ { 0,  3, 0, NULL,              op_shutdown },
  /* 808 */ { 0,  0, 0, & inst_info_808x,  NULL ],
  /* 809 */ { 0,  3, 0, NULL,              bad_op },
  /* 80a */ { 0,  3, 0, NULL,              bad_op },
  /* 80b */ { 0,  3, 0, NULL,              bad_op },
  /* 80c */ { 0,  3, 0, NULL,              bad_op },
  /* 80d */ { 0,  4, 0, NULL,              op_p_from_c_n },
  /* 80e */ { 0,  3, 0, NULL,              op_test_sreq },
  /* 80f */ { 0,  3, 0, NULL,              op_c_p_exch_n },
}


static inst_info_t inst_info_81bx [16] =
{
  /* 81b0 */ { 0,  4, 0, NULL,              bad_op },
  /* 81b1 */ { 0,  4, 0, NULL,              bad_op },
  /* 81b2 */ { L2, 4, 0, NULL,              bad_op },  // PC=A
  /* 81b3 */ { L2, 4, 0, NULL,              bad_op },  // PC=C
  /* 81b4 */ { 0,  4, 0, NULL,              bad_op },  // A=PC
  /* 81b5 */ { 0,  4, 0, NULL,              bad_op },  // C=PC
  /* 81b6 */ { L2, 4, 0, NULL,              bad_op },  // APCEX
  /* 81b7 */ { L2, 4, 0, NULL,              bad_op },  // CPCEX
  /* 81b8 */ { 0,  4, 0, NULL,              bad_op },
  /* 81b9 */ { 0,  4, 0, NULL,              bad_op },
  /* 81ba */ { 0,  4, 0, NULL,              bad_op },
  /* 81bb */ { 0,  4, 0, NULL,              bad_op },
  /* 81bc */ { 0,  4, 0, NULL,              bad_op },
  /* 81bd */ { 0,  4, 0, NULL,              bad_op },
  /* 81be */ { 0,  4, 0, NULL,              bad_op },
  /* 81bf */ { 0,  4, 0, NULL,              bad_op }
}


static inst_info_t inst_info_81x [16] =
{
  /* 810 */ { 0,  3, 0, NULL,              bad_op },  // ASLC
  /* 811 */ { 0   3, 0, NULL,              bad_op },  // BSLC
  /* 812 */ { 0,  3, 0, NULL,              bad_op },  // CSLC
  /* 813 */ { 0,  3, 0, NULL,              bad_op },  // DSLC
  /* 814 */ { 0,  3, 0, NULL,              bad_op },  // ASRC
  /* 815 */ { 0,  3, 0, NULL,              bad_op },  // BSRC
  /* 816 */ { 0,  3, 0, NULL,              bad_op },  // CSRC
  /* 817 */ { 0,  3, 0, NULL,              bad_op },  // DSRC
  /* 818 */ { L2, 6, 0, NULL,              bad_op ],  // r=r+con, r=r-con
  /* 819 */ { L2, 4, 0, NULL,              op_shift_fs },
  /* 81a */ { L2, 6, 0, NULL,              op_r_fs },
  /* 81b */ { L2, 0, 0, & inst_info_81x,   NULL },
  /* 81c */ { 0,  3, 0, NULL,              bad_op },  // ASRB
  /* 81d */ { 0,  3, 0, NULL,              bad_op },  // BSRB
  /* 81e */ { 0,  3, 0, NULL,              bad_op },  // CSRB
  /* 81f */ { 0,  3, 0, NULL,              bad_op },  // DSRB
}


static inst_info_t inst_info_8x [16] =
{
  /* 80 */ { 0,  0, 0, & inst_info_80x,   NULL },
  /* 81 */ { 0,  3, 0, & inst_info_81x,   NULL },
  /* 82 */ { 0,  3, 0, NULL,              op_clr_hst },
  /* 83 */ { 0,  3, 2, NULL,              op_test_hst },
  /* 84 */ { 0,  3, 0, NULL,              op_clr_st },
  /* 85 */ { 0,  3, 0, NULL,              op_set_st },
  /* 86 */ { 0,  3, 2, NULL,              op_test_st_zero },
  /* 87 */ { 0,  3, 2, NULL,              op_test_st_nonzero },
  /* 88 */ { 0,  3, 2, NULL,              op_test_p_ne },
  /* 89 */ { 0,  3, 2, NULL,              op_test_p_eq },
  /* 8a */ { 0,  3, 2, NULL,              op_compare_a },
  /* 8b */ { 0,  3, 2, NULL,              op_compare_a },
  /* 8c */ { 0,  2, 4, NULL,              op_goto },
  /* 8d */ { 0,  2, 5, NULL,              op_goto_abs },
  /* 8e */ { 0,  2, 4, NULL,              op_gosub },
  /* 8f */ { 0,  2, 5, NULL,              op_gosub_abs }
}


static inst_info_t inst_info_1x [16] =
{
  /* 10 */ { 0,  3, 0, NULL,              op_rn_from_a },
  /* 11 */ { 0,  3, 0, NULL,              op_a_from_rn },
  /* 12 */ { 0,  3, 0, NULL,              op_c_exch_rn },
  /* 13 */ { 0,  3, 0, NULL,              op_13x },  // AD0EX etc.
  /* 14 */ { 0,  3, 0, NULL,              op_14x },  // load/store
  /* 15 */ { 0,  3, 0, NULL,              op_15x },  // load/store
  /* 16 */ { 0,  2, 1, NULL,              op_d_add },
  /* 17 */ { 0,  2, 1, NULL,              op_d_add },
  /* 18 */ { 0,  2, 1, NULL,              op_d_sub },
  /* 19 */ { 0,  2, 2, NULL,              op_d_load },
  /* 1a */ { 0,  2, 4, NULL,              op_d_load },
  /* 1b */ { 0,  2, 5, NULL,              op_d_load },
  /* 1c */ { 0,  2, 1, NULL,              op_d_sub },
  /* 1d */ { 0,  2, 2, NULL,              op_d_load },
  /* 1e */ { 0,  2, 4, NULL,              op_d_load },
  /* 1f */ { 0,  2, 5, NULL,              op_d_load },
  /* 20 */ { 0,  ?, 5, NULL,              op_d_load }

};


static inst_info_t inst_info_0x [16] =
{
  /* 00 */ { 0,  2, 0, NULL,              op_rtnsxm },
  /* 01 */ { 0,  2, 0, NULL,              op_rtn },
  /* 02 */ { 0,  2, 0, NULL,              op_rtnsc },
  /* 03 */ { 0,  2, 0, NULL,              op_rtncc },
  /* 04 */ { 0,  2, 0, NULL,              op_sethex },
  /* 05 */ { 0,  2, 0, NULL,              op_setdec },
  /* 06 */ { 0,  2, 0, NULL,              op_rstk_from_c },
  /* 07 */ { 0,  2, 0, NULL,              op_c_from_rstk },
  /* 08 */ { 0,  2, 0, NULL,              op_clrst },
  /* 09 */ { 0,  2, 0, NULL,              op_c_from_st },
  /* 0a */ { 0,  2, 0, NULL,              op_st_from_c },
  /* 0b */ { 0,  2, 0, NULL,              op_cstex },
  /* 0c */ { 0,  2, 0, NULL,              op_p_inc },
  /* 0d */ { 0,  2, 0, NULL,              op_p_dec },
  /* 0e */ { 0,  4, 0, NULL,              op_0exx },  // logical inst
  /* 0f */ { 0,  2, 0, NULL,              op_rti }
};


static inst_info_t inst_info_x [16] =
{
  /* 0 */ { 0,  0, 0, & inst_info_0x,    NULL      },
  /* 1 */ { 0,  0, 0, & inst_info_1x,    NULL      },
  /* 2 */ { 0,  1, 1, NULL,              op_load_p },
  /* 3 */ { 0,  2, 0, NULL,              op_load_c },  // $$$ need to get count
  /* 4 */ { 0,  1, 2, NULL,              op_goc    },
  /* 5 */ { 0,  1, 2, NULL,              op_gonc   },
  /* 6 */ { 0,  1, 3, NULL,              op_goto   },
  /* 7 */ { 0,  1, 3, NULL,              op_gosub  },
  /* 8 */ { 0,  0, 0, & inst_info_8x,    NULL      },
  /* 9 */ { 0,  3, 2, NULL,              op_compare_fs },
  /* a */ { 0,  3, 0, NULL,              op_arith_fs },
  /* b */ { 0,  3, 0, NULL,              op_arith_fs },
  /* c */ { 0,  2, 0, NULL,              op_arith_a },
  /* d */ { 0,  2, 0, NULL,              op_arith_a },
  /* e */ { 0,  2, 0, NULL,              op_arith_a },
  /* f */ { 0,  2, 0, NULL,              op_arith_a }
};


static rom_word_t nut_get_ucode (nut_reg_t *nut_reg, rom_addr_t addr)
{
  uint8_t page = addr / PAGE_SIZE;
  bank_t bank = nut_reg->active_bank [page];
  uint16_t offset = addr & (PAGE_SIZE - 1);

  if (nut_reg->rom [page][bank])
    return nut_reg->rom [page][bank][offset];
  else
     return 0;  // non-existent memory
}


static void nut_set_ucode (nut_reg_t *nut_reg,
			   rom_addr_t addr,
			   rom_word_t data) UNUSED;


static void nut_set_ucode (nut_reg_t *nut_reg,
			   rom_addr_t addr,
			   rom_word_t data)
{
  uint8_t page = addr / PAGE_SIZE;
  bank_t bank = nut_reg->active_bank [page];
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


static bool nut_read_rom (sim_t      *sim,
			  bank_t     bank,
			  addr_t     addr,
			  rom_word_t *val)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
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
			   bank_t     bank,
			   addr_t     addr,
			   rom_word_t *val)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
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


static void nut_print_state (sim_t *sim);


static void print_reg (reg_t reg)
{
  int i;
  for (i = WSIZE - 1; i >= 0; i--)
    printf ("%x", reg [i]);
}


static void print_stat (sim_t *sim)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  int i;
  for (i = 0; i < SSIZE; i++)
    printf (nut_reg->s [i] ? "%x" : ".", i);
}


static void saturn_print_state (sim_t *sim)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);

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

static bool saturn_execute_cycle (sim_t *sim)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);

  chip_event (sim, event_cycle, NULL, 0, NULL);

  switch (saturn_reg->inst_state)
    {
    case sleep:
      return false;

    case inst_fetch_0:
      // fetch first digit of an instruction
      saturn_reg->prev_pc = saturn_reg->pc;
      saturn_reg->prev_carry = saturn_reg->carry;
      saturn_reg->carry = 0;

      saturn_reg->inst_digits = 0;
      saturn_reg->inst_cur_digits = 0;

      saturn_reg->operand_digits = 0;
      saturn_reg->operand_cur_digits = 0;

      saturn_reg->inst [inst_cur_digits++] = saturn_get_mem (saturn_reg,
							     saturn_reg->pc++);

      switch (saturn_reg->inst [0])
	{
	case 3:
	  saturn_reg->inst_digits = 2;
	  saturn_reg->inst_state = inst_fetch;
	  break;
	case 4:
	case 5:
	  saturn_reg->inst_digits = 1;
	  saturn_reg->operand_digits = 2;
	  saturn_reg->inst_state = operand_fetch;
	  break;
	case 6:
	case 7:
	  saturn_reg->inst_digits = 1;

	  saturn_reg->operand_digits = 3;
	  saturn_reg->inst_state = operand_fetch;
	  break;
	default:
	  saturn_reg->inst_state = inst_fetch;
	}

      break;

    case inst_fetch:
      // fetch subsequent digits of instruction
      saturn_reg->inst [inst_cur_digits++] = saturn_get_mem (saturn_reg,
							     saturn_reg->pc++);

      if (! saturn_reg->inst_digits)
	{
	  // try to determine the instruction length
	}

      if (saturn_reg->inst_cur_digits == saturn_reg->inst_digits)
	{
	  // got entire instruction, now start operand fetch or execution
	  if (saturn_reg->operand_digits)
	    saturn_reg->inst_state = operand_fetch;
	  else
	    saturn_reg->inst_state = execute;
	}
      break;

    case operand_fetch:
      saturn_reg->operand [operand_cur_digits++] = saturn_get_mem (saturn_reg,
								   saturn_reg->pc++);
      if (saturn_reg->operand_cur_digits == saturn_reg->operand_digits)
	{
	  saturn_reg->inst_state = execute;
	}
      break;

    case execute:
      // $$$ more code needed here
      break;

    }

  sim->cycle_count++;

  return (true);
}


static bool saturn_execute_instruction (sim_t *sim)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);

  do
    {
#if 1
      (void) saturn_execute_cycle (sim);
#else
      if (! saturn_execute_cycle (sim))
	return false;
#endif
    }
  while ((staturn_reg->inst_state != sleep) &&
	 (saturn_reg->inst_state != inst_fetch_0));
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


static void saturn_press_key (sim_t *sim, int keycode)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);

#ifdef KEYBOARD_DEBUG
  printf ("key %o press, addr %04x, state %s\n", keycode, nut_reg->prev_pc, kbd_state_name [nut_reg->kb_state]);
#endif
}

static void saturn_release_key (sim_t *sim)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);

#ifdef KEYBOARD_DEBUG
  printf ("key release, addr %04x, state %s\n", nut_reg->prev_pc, kbd_state_name [nut_reg->kb_state]);
#endif
}

static void saturn_reset (sim_t *sim)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);
  int i;

  sim->cycle_count = 0;

  for (i = 0; i < WSIZE; i++)
    {
      saturn_reg->a [i] = 0;
      saturn_reg->b [i] = 0;
      saturn_reg->c [i] = 0;
      saturn_reg->d [i] = 0;
      for (j = 0; j < MAX_R_REG; j++)
	saturn_reg->r [j][i] = 0;
    }

  for (i = 0; i < SSIZE; i++)
    nut_reg->s [i] =0;

  nut_reg->p = 0;
  nut_reg->q = 0;
  nut_reg->q_sel = false;

  nut_reg->pc = 0x00000;

  nut_reg->inst_state = inst_fetch_0;
  nut_reg->carry = 1;  // $$$ appropriate for Saturn?
}


static void saturn_clear_memory (sim_t *sim)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);
  int addr;
}


static void saturn_new_addr_space (sim_t *sim    UNUSED,
				   int max_bank  UNUSED,
				   int max_page  UNUSED,
				   int page_size UNUSED)
{
  ;
}



static void saturn_new_processor (sim_t *sim, int ram_size)
{
  saturn_reg_t *saturn_reg;

  saturn_reg = alloc (sizeof (saturn_reg_t));

  install_chip (sim, & saturn_cpu_chip_detail, saturn_reg);

  saturn_new_addr_space (sim, MAX_BANK, MAX_PAGE, PAGE_SIZE);

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
	}

      nut_new_ram (sim, 0x0c0, ram_size);

      coconut_display_init (sim);

      break;
    }

  chip_event (sim, event_reset, NULL, 0, NULL);
}


static void saturn_free_processor (sim_t *sim)
{
  remove_chip (sim->first_chip);
}


static void saturn_event_fn (sim_t  *sim,
			     chip_t *chip UNUSED,
			     int    event,
			     int    arg,
			     void   *data UNUSED)
{
  saturn_reg_t *saturn_reg = get_chip_data (sim->first_chip);

  switch (event)
    {
    case event_cycle:
      break;
    case event_sleep:
      break;
    case event_reset:
      saturn_reset (sim);
      break;
    case event_clear_memory:
      saturn_clear_memory (sim);
      break;
    case event_display_state_change:
      saturn_reg->display_enable = arg;
      break;
    default:
      // warning ("proc_saturn: unknown event %d\n", event);
      break;
    }
}


processor_dispatch_t saturn_processor =
  {
    .max_rom             = MAX_PAGE * PAGE_SIZE,
    .max_bank            = MAX_BANK,

    .new_processor       = saturn_new_processor,
    .free_processor      = saturn_free_processor,

    .parse_object_line   = saturn_parse_object_line,
    .parse_listing_line  = saturn_parse_listing_line,

    .execute_cycle       = saturn_execute_cycle,
    .execute_instruction = saturn_execute_instruction,

    .press_key           = saturn_press_key,
    .release_key         = saturn_release_key,
    .set_ext_flag        = saturn_set_ext_flag,

    .set_bank_group      = saturn_set_bank_group,
    .read_rom            = saturn_read_rom,
    .write_rom           = saturn_write_rom,

    .read_ram            = saturn_read_ram,
    .write_ram           = saturn_write_ram,

    .disassemble         = saturn_disassemble,
    .print_state         = saturn_print_state
  };
