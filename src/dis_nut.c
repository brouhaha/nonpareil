/*
Copyright 2004-2023 Eric Smith <spacewar@gmail.com>
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

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

#include "arch.h"
#include "platform.h"
#include "util.h"
#include "display.h"
#include "keyboard.h"
#include "chip.h"
#include "calcdef.h"
#include "proc.h"
#include "digit_ops.h"
#include "proc_nut.h"


static int nut_disassemble_selpf (int op1,
				  inst_state_t *inst_state,
				  bool *new_carry_known_clear,
				  char *buf,
				  int len)
{
  if (op1 & 0x001)
  {
    *inst_state = inst_normal;
  }

  if ((op1 & 0x003) == 0x000)
    buf_printf(&buf, &len, "pfchnr 0x%02x", op1 >> 2);
  else if ((op1 & 0x003) == 0x001)
    buf_printf(&buf, &len, "pfchr  0x%02x", op1 >> 2);
  else if ((op1 & 0x03f) == 0x03a)
    buf_printf(&buf, &len, "c=pfnr %d", op1 >> 6);
  else if ((op1 & 0x03f) == 0x03b)
    buf_printf(&buf, &len, "c=pfr  %d", op1 >> 6);
  else if ((op1 & 0x03f) == 0x003)
    buf_printf(&buf, &len, "?pfsft %d", op1 >> 6);
  else
    buf_printf(&buf, &len, "??? 0x03x%", op1);

  return true;
}


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


static bool nut_disassemble_long_branch (uint32_t flags,
					 rom_word_t op1,
					 rom_word_t op2,
					 rom_word_t op3,
					 addr_t *addr, 
					 bank_t *bank,
					 bool *carry_known_clear,
					 flow_type_t *flow_type,
					 bank_t *target_bank,
					 addr_t *target_addr,
					 char *buf,
					 int len)
{
  bool cond_c, call, uncond;
  bool special_41 = false;
  bool set_hex = false;
  int special_page = -1;

  *target_addr = (op1 >> 2) | ((op2 & 0x3fc) << 6);
  *target_bank = *bank;

  cond_c = op2 & 0x001;
  call = ! (op2 & 0x002);

  uncond = (! cond_c) && (* carry_known_clear);

  if (call && (flags & DIS_FLAG_NUT_41_JUMPS))
    {
      special_41 = true;
      switch (*target_addr)
	{
	case 0x0fd9:
	  set_hex = true;
	  [[fallthrough]];
	case 0x0fda:
	  *target_addr = (*addr & 0xfc00) + op3;
	  call = false;
	  break;
	case 0x0fdd:
	  set_hex = true;
	  [[fallthrough]];
	case 0x0fde:
	  *target_addr = (*addr & 0xfc00) + op3;
	  call = true;
	  break;
	case 0x23d0:
	  *target_addr = (*addr & 0xf000) + 0x0000 + op3;
	  special_page = 0;
	  call = false;
	  break;
	case 0x23d2:
	  *target_addr = (*addr & 0xf000) + 0x0000 + op3;
	  special_page = 0;
	  call = true;
	  break;
	case 0x23d9:
	  *target_addr = (*addr & 0xf000) + 0x0400 + op3;
	  special_page = 1;
	  call = false;
	  break;
	case 0x23db:
	  *target_addr = (*addr & 0xf000) + 0x0400 + op3;
	  special_page = 1;
	  call = true;
	  break;
	case 0x23e2:
	  *target_addr = (*addr & 0xf000) + 0x0800 + op3;
	  special_page = 2;
	  call = false;
	  break;
	case 0x23e4:
	  *target_addr = (*addr & 0xf000) + 0x0800 + op3;
	  special_page = 2;
	  call = true;
	  break;
	case 0x23eb:
	  *target_addr = (*addr & 0xf000) + 0x0c00 + op3;
	  special_page = 3;
	  call = false;
	  break;
	case 0x23ed:
	  *target_addr = (*addr & 0xf000) + 0x0c00 + op3;
	  special_page = 3;
	  call = true;
	  break;
	default:
	  special_41 = false;
	}
    }

  if (call)
    *flow_type = flow_subroutine_call;
  else
    *flow_type = uncond ? flow_uncond_branch : flow_cond_branch;

  if (special_41)
    {
      if (special_page >= 0)
	buf_printf (& buf, & len, "x%s%d %%s", call ? "gosub" : "golong", special_page);
      else if (set_hex)
        buf_printf (& buf, & len, "x%s %%s", call ? "gosubh" : "golongh");
      else
        buf_printf (& buf, & len, "x%s %%s", call ? "gosub" : "golong");
    }
  else
    {
      if (! uncond)
	buf_printf (& buf, & len, "?%s ", cond_c ? "c " : "nc");
      buf_printf (& buf, & len, "%s %%s", call ? "gosub" : "golong");
    }

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
    /* 0x080 */ NULL,
    /* 0x0c0 */ NULL,
    /* 0x100 */ "enbank 1",
    /* 0x140 */ "enbank 3",
    /* 0x180 */ "enbank 2",
    /* 0x1c0 */ "enbank 4",
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
    /* 0x018 */ NULL,
    /* 0x058 */ "g=c",
    /* 0x098 */ "c=g", 
    /* 0x0d8 */ "c<>g",
    /* 0x118 */ NULL,
    /* 0x158 */ "m=c",
    /* 0x198 */ "c=m",
    /* 0x1d8 */ "c<>m",
    /* 0x218 */ NULL,
    /* 0x258 */ "f=sb",
    /* 0x298 */ "sb=f",
    /* 0x2d8 */ "f<>sb",
    /* 0x318 */ NULL,
    /* 0x358 */ "st=c",
    /* 0x398 */ "c=st",
    /* 0x3d8 */ "c<>st"
  };


static inst_info_t nut_op20 [16] =
  { 
    { /* 0x020 */ "pop stk",     false, flow_no_branch },
    { /* 0x060 */ "powoff",      false, flow_no_branch },
    { /* 0x0a0 */ "sel p",       false, flow_no_branch },
    { /* 0x0e0 */ "sel q",       false, flow_no_branch },
    { /* 0x120 */ "? p=q",       true,  flow_no_branch  },
    { /* 0x160 */ "lld",         true,  flow_no_branch  },
    { /* 0x1a0 */ "clr abc",     false, flow_no_branch },
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
    /* 0x030 */ "disp blink",  // voyager only, HEPAX uses it to relocate ROM
    /* 0x070 */ "n=c",
    /* 0x0b0 */ "c=n", 
    /* 0x0f0 */ "c<>n",
    /* 0x130 */ "ldi",  /* handled elsewhere */
    /* 0x170 */ "stk=c",
    /* 0x1b0 */ "c=stk",
    /* 0x1f0 */ "wptog",  // HEPAX write protect toggle
    /* 0x230 */ "goto keys",
    /* 0x270 */ "sel ram",
    /* 0x2b0 */ "clr regs",
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
				 inst_state_t *inst_state,
				 bool *new_carry_known_clear,
				 flow_type_t *flow_type,
				 char *buf,
				 int len)
{
  int arg = op1 >> 6;

  switch (op1 & 0x03c)
    {
    case 0x000:
      if (nut_op00 [op1 >> 6])
	buf_printf (& buf, & len, "%s", nut_op00 [op1 >> 6]);
      else
	buf_printf (& buf, & len, "con $%03x", op1);
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
	buf_printf (& buf, & len, "? s=1 %d", tmap [arg]);
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
      if (nut_op18 [op1 >> 6])
	buf_printf (& buf, & len, "%s", nut_op18 [op1 >> 6]);
      else
	buf_printf (& buf, & len, "con $%03x", op1);
      break;
    case 0x01c:
      if (op1 == 0x3dc)
	buf_printf (& buf, & len, "inc pt");
      else
	{
	  buf_printf (& buf, & len, "pt= %d", tmap [arg]);
	  *new_carry_known_clear = true;
	}
      break;
    case 0x020:
      buf_printf (& buf, & len, "%s", nut_op20 [op1 >> 6].mnem);
      if (nut_op20 [op1 >> 6].can_set_carry)
	*new_carry_known_clear = false;
      *flow_type = nut_op20 [op1 >> 6].flow_type;
      break;
    case 0x024:
      buf_printf (& buf, & len, "selpf %d", arg);
      *inst_state = inst_nut_selpf;
      break;
    case 0x028:
      buf_printf (& buf, & len, "reg=c %d", arg);
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
      buf_printf (& buf, & len, "con $%03x", op1);
      break;
    case 0x038:
      if (arg == 0)
        buf_printf (& buf, & len, "c=data", arg);
      else
        buf_printf (& buf, & len, "c=reg %d", arg);
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
    { "? c#0",   true,  flow_no_branch },
    { "? a<c",   true,  flow_no_branch },
    { "? a<b",   true,  flow_no_branch },
    { "? a#0",   true,  flow_no_branch },
    { "? a#c",   true,  flow_no_branch },
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
      two_word = (op1 == 0x130);       // ldi
      break;
    case 1:  two_word = true; break;   // long branch
    case 2:  two_word = false; break;  // arith
    case 3:  two_word = false; break;  // short branch
    }

  return two_word;
}


static bool nut_three_word_instruction (rom_word_t op1, rom_word_t op2)
{
  addr_t target;

  if ((op1 & 3) != 1)
    return false;
  if ((op2 & 2) != 0)
    return false;
  target = (op1 >> 2) | ((op2 & 0x3fc) << 6);
  switch (target)
    {
    case 0x0fd9:
    case 0x0fda:
    case 0x0fdd:
    case 0x0fde:
    case 0x23d0:
    case 0x23d2:
    case 0x23d9:
    case 0x23db:
    case 0x23e2:
    case 0x23e4:
    case 0x23eb:
    case 0x23ed:
      return true;
    }
  return false;
}


bool nut_disassemble (sim_t        *sim,
		      uint32_t     flags,
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
  bool two_word = false;
  bool three_word = false;
  rom_word_t op1;
  rom_word_t op2 = 0;
  rom_word_t op3 = 0;
  addr_t base_addr = *addr;

  if (((*inst_state) != inst_normal) &&
      ((*inst_state) != inst_nut_selpf))
    return false;

  *flow_type = flow_no_branch;

  if (! sim_read_rom (sim, *bank, *addr, & op1))
    return false;
  (*addr) = ((*addr) + 1) & 0xffff;

  if (*inst_state == inst_normal)
  {
    two_word = nut_two_word_instruction (op1);
    if (two_word)
    {
      if (! sim_read_rom (sim, *bank, *addr, & op2))
	return false;
      (*addr) = ((*addr) + 1) & 0xffff;
    }

    three_word = (two_word && (flags & DIS_FLAG_NUT_41_JUMPS) && nut_three_word_instruction (op1, op2));
    if (three_word)
    {
      if (! sim_read_rom (sim, *bank, *addr, & op3))
	return false;
      (*addr) = ((*addr) + 1) & 0xffff;
    }
  }

  if (flags & DIS_FLAG_LISTING)
    {
      buf_printf (& buf, & len, "%04x: ", base_addr);
      if (three_word)
	buf_printf (& buf, & len, "%03x %03x %03x  ", op1, op2, op3);
      else if (two_word)
	buf_printf (& buf, & len, "%03x %03x      ", op1, op2);
      else
	buf_printf (& buf, & len, "%03x          ", op1);
    }

  if (flags & DIS_FLAG_LABEL)
    {
      buf_printf (& buf, & len, "<label>  ");
    }

  if (*inst_state == inst_nut_selpf)
  {
    status = nut_disassemble_selpf(op1,
				   inst_state,
				   & new_carry_known_clear,
				   buf,
				   len);
  }
  else
  {
    switch (op1 & 3)
    {
    case 0:
      status = nut_disassemble_misc (op1,
				     op2,
				     inst_state,
				     & new_carry_known_clear,
				     flow_type,
				     buf,
				     len);
      break;
    case 1:
      status = nut_disassemble_long_branch (flags,
					    op1,
					    op2,
					    op3,
					    addr,
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
  }

  *carry_known_clear = new_carry_known_clear;

  return status;
}
