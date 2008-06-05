/*
$Id$
Copyright 2004, 2005, 2007, 2008 Eric Smith <eric@brouhaha.com>

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
#include <stdint.h>
#include <stdio.h>

#include "arch.h"
#include "platform.h"
#include "util.h"
#include "display.h"
#include "keyboard.h"
#include "chip.h"
#include "proc.h"
#include "calcdef.h"
#include "digit_ops.h"
#include "proc_nut.h"


static int nut_disassemble_short_branch (rom_word_t op1,
					 bank_t *bank,
					 addr_t *addr, 
					 bool *carry_known_clear,
					 flow_type_t *flow_type,
					 bank_t *target_bank,
					 addr_t *target_addr,
					 char *buf,
					 int len)
{
  int offset;
  bool cond_c, uncond;

  offset = (op1 >> 3) & 0x3f;
  if (op1 & 0x200)
    offset -= 64;
  *target_addr = ((*addr) + offset - 1) & 0xffff;
  *target_bank = *bank;

  cond_c = (op1 >> 2) & 1;

  if ((! cond_c) && * carry_known_clear)
    uncond = true;

  *flow_type = uncond ? flow_uncond_branch : flow_cond_branch;

  if (! uncond)
    buf_printf (& buf, & len, "?%s ", cond_c ? "c " : "nc");
  buf_printf (& buf, & len, "goto %%s");

  return true;
}


static bool nut_disassemble_long_branch (rom_word_t op1,
					 rom_word_t op2,
					 bank_t *bank,
					 bool *carry_known_clear,
					 flow_type_t *flow_type,
					 bank_t *target_bank,
					 addr_t *target_addr,
					 char *buf,
					 int len)
{
  bool cond_c, type, uncond;

  *target_addr = (op1 >> 2) | ((op2 & 0x3fc) << 6);
  *target_bank = *bank;

  cond_c = op2 & 0x001;
  type = op2 & 0x002;

  if ((! cond_c) && * carry_known_clear)
    uncond = true;

  if (type)
    *flow_type = uncond ? flow_uncond_branch : flow_cond_branch;
  else
    *flow_type = flow_subroutine_call;

  if (! uncond)
    buf_printf (& buf, & len, "?%s ", cond_c ? "c " : "nc");
  buf_printf (& buf, & len, "%s %%s", type ? "goto" : "call");

  return true;
}


typedef struct
{
  char *mnem;
  bool can_set_carry;
  flow_type_t flow_type;
} inst_info_t;


static char *nut_op00 [16] =
  { 
    /* 0x000 */ "nop",
    /* 0x040 */ "wrrom", 
    /* 0x080 */ "???",
    /* 0x0c0 */ "???",
    /* 0x100 */ "enbank 1",
    /* 0x140 */ "???",
    /* 0x180 */ "enbank 2",
    /* 0x1c0 */ "???",
    /* 0x200 */ "wr pil0",
    /* 0x240 */ "wr pil1",
    /* 0x280 */ "wr pil2",
    /* 0x2c0 */ "wr pil3",
    /* 0x300 */ "wr pil4",
    /* 0x340 */ "wr pil5",
    /* 0x380 */ "wr pil6",
    /* 0x3c0 */ "wr pil7",
  };


static char *nut_op18 [16] =
  { 
    /* 0x018 */ "???",
    /* 0x058 */ "g=c",
    /* 0x098 */ "c=g", 
    /* 0x0d8 */ "c<>g",
    /* 0x118 */ "???",
    /* 0x158 */ "m=c",
    /* 0x198 */ "c=m",
    /* 0x1d8 */ "c<>m",
    /* 0x218 */ "???",
    /* 0x258 */ "f=sb",
    /* 0x298 */ "sb=f",
    /* 0x2d8 */ "f<>sb",
    /* 0x318 */ "???",
    /* 0x358 */ "s=c",
    /* 0x398 */ "c=s",
    /* 0x3d8 */ "c<>s"
  };


static inst_info_t nut_op20 [16] =
  { 
    { /* 0x020 */ "pop",         false, flow_no_branch },
    { /* 0x060 */ "powoff",      false, flow_no_branch },
    { /* 0x0a0 */ "sel p",       false, flow_no_branch },
    { /* 0x0e0 */ "sel q",       false, flow_no_branch },
    { /* 0x120 */ "? p=q",       true,  flow_no_branch  },
    { /* 0x160 */ "lld",         true,  flow_no_branch  },
    { /* 0x1a0 */ "clear abc",   false, flow_no_branch },
    { /* 0x1e0 */ "goto c",      false, flow_no_branch },
    { /* 0x220 */ "c=keys",      false, flow_no_branch },
    { /* 0x260 */ "set hex",     false, flow_no_branch },
    { /* 0x2a0 */ "set dec",     false, flow_no_branch },
    { /* 0x2e0 */ "disp off",    false, flow_no_branch },
    { /* 0x320 */ "disp toggle", false, flow_no_branch },
    { /* 0x360 */ "?c rtn",      false, flow_cond_subroutine_return },
    { /* 0x3a0 */ "?nc rtn",     false, flow_cond_subroutine_return },
    { /* 0x3e0 */ "rtn",         false, flow_subroutine_return }
  };


static char *nut_op30 [16] =
  { 
    /* 0x030 */ "disp blink",  /* voyager only */
    /* 0x070 */ "n=c",
    /* 0x0b0 */ "c=n", 
    /* 0x0f0 */ "c<>n",
    /* 0x130 */ "ldi",  /* handled elsewhere */
    /* 0x170 */ "push c",
    /* 0x1b0 */ "pop c",
    /* 0x1f0 */ "???",
    /* 0x230 */ "goto keys",
    /* 0x270 */ "sel ram",
    /* 0x2b0 */ "clear regs",
    /* 0x2f0 */ "data=c",
    /* 0x330 */ "cxisa",
    /* 0x370 */ "c=c|a",
    /* 0x3b0 */ "c=c&a",
    /* 0x3f0 */ "sel pfad"
  };


/* map from high opcode bits to register index */
static int tmap [16] =
{ 3, 4, 5, 10, 8, 6, 11, -1, 2, 9, 7, 13, 1, 12, 0, -1 };


static int nut_disassemble_misc (int op1,
				 int op2,
				 bool *new_carry_known_clear,
				 flow_type_t *flow_type,
				 char *buf,
				 int len)
{
  int arg = op1 >> 6;

  switch (op1 & 0x03c)
    {
    case 0x000:
      buf_printf (& buf, & len, "%s", nut_op00 [op1 >> 6]);
      break;
    case 0x004:
      if (op1 == 0x3c4)
	buf_printf (& buf, & len, "clr s");
      else
	buf_printf (& buf, & len, "s=0 %d", tmap [arg]);
      break;
    case 0x008:
      if (op1 == 0x3c8)
	buf_printf (& buf, & len, "clr kb");
      else
	buf_printf (& buf, & len, "s=1 %d", tmap [arg]);
      break;
    case 0x00c:
      if (op1 == 0x3cc)
	buf_printf (& buf, & len, "? kb");
      else
	buf_printf (& buf, & len, "? s=0 %d", tmap [arg]);
      *new_carry_known_clear = false;
      break;
    case 0x010:
      buf_printf (& buf, & len, "lc %d", arg);
      break;
    case 0x014:
      if (op1 == 0x3d4)
	buf_printf (& buf, & len, "dec pt");
      else
	{
	  buf_printf (& buf, & len, "? pt= %d", tmap [arg]);
	  *new_carry_known_clear = false;
	}
      break;
    case 0x018:
      buf_printf (& buf, & len, "%s", nut_op18 [op1 >> 6]);
      break;
    case 0x01c:
      if (op1 == 0x3dc)
	buf_printf (& buf, & len, "inc pt");
      else
	{
	  buf_printf (& buf, & len, "pt= %d", tmap [arg]);
	  *new_carry_known_clear = false;
	}
      break;
    case 0x020:
      buf_printf (& buf, & len, "%s", nut_op20 [op1 >> 6].mnem);
      if (nut_op20 [op1 >> 6].can_set_carry)
	*new_carry_known_clear = false;
      *flow_type = nut_op20 [op1 >> 6].flow_type;
      break;
    case 0x024:
      buf_printf (& buf, & len, "selprf %d", arg);
      break;
    case 0x028:
      buf_printf (& buf, & len, "wrreg %d", arg);
      break;
    case 0x02c:
      buf_printf (& buf, & len, "? ext %d", tmap [arg]);
      *new_carry_known_clear = false;
      break;
    case 0x030:
      if (op1 == 0x130)
	buf_printf (& buf, & len, "ldi %04o", op2);
      else
	buf_printf (& buf, & len, "%s", nut_op30 [op1 >> 6]);
      break;
    case 0x034:
      buf_printf (& buf, & len, "??? %d", arg);
      break;
    case 0x038:
      buf_printf (& buf, & len, "rdreg %d", arg);
      break;
    case 0x03c:
      if (op1 == 0x3fc)
	buf_printf (& buf, & len, "disp compensation");
      else
	buf_printf (& buf, & len, "rcr %d", tmap [arg]);
      break;
    }

  return true;
}
 

static inst_info_t nut_arith_info [32] =
  {
    { "a=0",     false, flow_no_branch },
    { "b=0",     false, flow_no_branch },
    { "c=0",     false, flow_no_branch },
    { "ab ex",   false, flow_no_branch },
    { "b=a",     false, flow_no_branch },
    { "ac ex",   false, flow_no_branch },
    { "c=b",     false, flow_no_branch },
    { "bc ex",   false, flow_no_branch },
    { "a=c",     false, flow_no_branch },
    { "a=a+b",   true,  flow_no_branch },
    { "a=a+c",   true,  flow_no_branch },
    { "a=a+1",   true,  flow_no_branch },
    { "a=a-b",   true,  flow_no_branch },
    { "a=a-1",   true,  flow_no_branch },
    { "a=a-c",   true,  flow_no_branch },
    { "c=c+c",   true,  flow_no_branch },
    { "c=a+c",   true,  flow_no_branch },
    { "c=c+1",   true,  flow_no_branch },
    { "c=a-c",   true,  flow_no_branch },
    { "c=c-1",   true,  flow_no_branch },
    { "c=-c",    true,  flow_no_branch },
    { "c=-c-1",  true,  flow_no_branch },
    { "? b<>0",  true,  flow_no_branch },
    { "? c<>0",  true,  flow_no_branch },
    { "? a<c",   true,  flow_no_branch },
    { "? a<b",   true,  flow_no_branch },
    { "? a<>0",  true,  flow_no_branch },
    { "? a<>c",  true,  flow_no_branch },
    { "a sr",    false, flow_no_branch },
    { "b sr",    false, flow_no_branch },
    { "c sr",    false, flow_no_branch },
    { "a sl",    false, flow_no_branch }
  };

static char *nut_field_mnem [8] =
  { "p", "x", "wp", "w", "pq", "xs", "m", "s" };


static int nut_disassemble_arith (int op1,
				  bool *new_carry_known_clear,
				  char *buf,
				  int len)
{
  int op = op1 >> 5;
  int field = (op1 >> 2) & 7;

  buf_printf (& buf, & len, "%-8s%s",
	     nut_arith_info [op].mnem,
	     nut_field_mnem [field]);
  if (nut_arith_info [op].can_set_carry)
    *new_carry_known_clear = false;
  return true;
}


static bool nut_two_word_instruction (rom_word_t op1)
{
  bool two_word = false;

  switch (op1 & 3)
    {
    case 0:  // misc
      two_word = ((op1 & 0x3c) == 0x30);  // ldi
      break;
    case 1:  two_word = true; break;   // long branch
    case 2:  two_word = false; break;  // arith
    case 3:  two_word = false; break;  // short branch
    }

  return two_word;
}


bool nut_disassemble (sim_t        *sim,
		      // input and output:
		      bank_t       *bank,
		      addr_t       *addr,
		      inst_state_t *inst_state,
		      bool         *carry_known_clear,
		      addr_t       *delayed_select_mask UNUSED,
		      addr_t       *delayed_select_addr UNUSED,
		      // output:
		      flow_type_t  *flow_type,
		      bank_t       *target_bank,
		      addr_t       *target_addr,
		      char         *buf,
		      int          len)
{
  bool new_carry_known_clear = true;
  bool status;
  bool two_word;
  rom_word_t op1;
  rom_word_t op2 = 0;

  if ((*inst_state) != inst_normal)
    return false;

  *flow_type = flow_no_branch;

  if (! sim_read_rom (sim, *bank, *addr, & op1))
    return false;
  (*addr) = ((*addr) + 1) & 0xffff;

  two_word = nut_two_word_instruction (op1);
  if (two_word)
    {
      if (! sim_read_rom (sim, *bank, *addr, & op2))
	return false;
      (*addr) = ((*addr) + 1) & 0xffff;
    }

  switch (op1 & 3)
    {
    case 0:
      status = nut_disassemble_misc (op1,
				     op2,
				     & new_carry_known_clear,
				     flow_type,
				     buf,
				     len);
      break;
    case 1:
      status = nut_disassemble_long_branch (op1,
					    op2,
					    bank,
					    carry_known_clear,
					    flow_type,
					    target_bank,
					    target_addr,
					    buf,
					    len);
      break;
    case 2:
      status = nut_disassemble_arith (op1,
				      & new_carry_known_clear,
				      buf,
				      len);
      break;
    case 3:
      status = nut_disassemble_short_branch (op1,
					     bank,
					     addr,
					     carry_known_clear,
					     flow_type,
					     target_bank,
					     target_addr,
					     buf,
					     len);
      break;
    }

  *carry_known_clear = new_carry_known_clear;

  return status;
}
