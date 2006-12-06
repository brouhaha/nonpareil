/*
$Id$
Copyright 2005 Eric L. Smith <eric@brouhaha.com>

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
#include <string.h>

#include "arch.h"
#include "platform.h"
#include "util.h"
#include "display.h"
#include "keyboard.h"
#include "proc.h"
#include "calcdef.h"


static uint8_t p_set_map [16] =
  { 14,  4,  7,  8, 11,  2, 10, 12,  1,  3, 13,  6,  0,  9,  5, 14 };

static uint8_t p_test_map [16] =
  {  4,  8, 12,  2,  9,  1,  6,  3,  1, 13,  5,  0, 11, 10,  7,  4 };


typedef struct misc_inst_info_t
{
  struct misc_inst_info_t *subtable;
  char *mnem;
  char *arg_0_mnem;
  uint8_t *map;
  flow_type_t flow;
} misc_inst_info_t;

static misc_inst_info_t misc_00_info [16] =
{
  [00000 >> 6] = { NULL, "nop",             NULL, NULL, flow_no_branch },
  [00100 >> 6] = { NULL, NULL,              NULL, NULL, flow_no_branch },
  [00200 >> 6] = { NULL, NULL,              NULL, NULL, flow_no_branch },
  [00300 >> 6] = { NULL, "crc f1?",         NULL, NULL, flow_no_branch },
  [00400 >> 6] = { NULL, NULL,              NULL, NULL, flow_no_branch },
  [00500 >> 6] = { NULL, NULL,              NULL, NULL, flow_no_branch },
  [00600 >> 6] = { NULL, NULL,              NULL, NULL, flow_no_branch },
  [00700 >> 6] = { NULL, NULL,              NULL, NULL, flow_no_branch },
  [01000 >> 6] = { NULL, NULL,              NULL, NULL, flow_no_branch },
  [01100 >> 6] = { NULL, NULL,              NULL, NULL, flow_no_branch },
  [01200 >> 6] = { NULL, NULL,              NULL, NULL, flow_no_branch },
  [01300 >> 6] = { NULL, NULL,              NULL, NULL, flow_no_branch },
  [01400 >> 6] = { NULL, NULL,              NULL, NULL, flow_no_branch },
  [01500 >> 6] = { NULL, NULL,              NULL, NULL, flow_no_branch },
  [01600 >> 6] = { NULL, NULL,              NULL, NULL, flow_no_branch },
  [01700 >> 6] = { NULL, NULL,              NULL, NULL, flow_no_branch },
};

static misc_inst_info_t misc_10_info [16] =
{
  [00010 >> 6] = { NULL, "clear regs",           NULL, NULL, flow_no_branch },
  [00110 >> 6] = { NULL, "clear status",         NULL, NULL, flow_no_branch },
  [00210 >> 6] = { NULL, "display toggle",       NULL, NULL, flow_no_branch },
  [00310 >> 6] = { NULL, "display off",          NULL, NULL, flow_no_branch },
  [00410 >> 6] = { NULL, "m1 exchange c",        NULL, NULL, flow_no_branch },
  [00510 >> 6] = { NULL, "m1 -> c",              NULL, NULL, flow_no_branch },
  [00610 >> 6] = { NULL, "m2 exchange c",        NULL, NULL, flow_no_branch },
  [00710 >> 6] = { NULL, "m2 -> c",              NULL, NULL, flow_no_branch },
  [01010 >> 6] = { NULL, "stack -> a",           NULL, NULL, flow_no_branch },
  [01110 >> 6] = { NULL, "down rotate",          NULL, NULL, flow_no_branch },
  [01210 >> 6] = { NULL, "y -> a",               NULL, NULL, flow_no_branch },
  [01310 >> 6] = { NULL, "c -> stack",           NULL, NULL, flow_no_branch },
  [01410 >> 6] = { NULL, "decimal",              NULL, NULL, flow_no_branch },
  [01510 >> 6] = { NULL, NULL,                   NULL, NULL, flow_no_branch },
  [01610 >> 6] = { NULL, "f -> a[x]",            NULL, NULL, flow_no_branch },
  [01710 >> 6] = { NULL, "f exchange a[x]",      NULL, NULL, flow_no_branch },
};

static misc_inst_info_t misc_20_info [16] =
{
  [00020 >> 6] = { NULL, "keys -> rom address",  NULL, NULL, flow_uncond_branch_keycode },
  [00120 >> 6] = { NULL, "keys -> a",            NULL, NULL, flow_no_branch },
  [00220 >> 6] = { NULL, "a -> rom address",     NULL, NULL, flow_uncond_branch_computed },
  [00320 >> 6] = { NULL, "reset twf",            NULL, NULL, flow_no_branch },
  [00420 >> 6] = { NULL, "binary",               NULL, NULL, flow_no_branch },
  [00520 >> 6] = { NULL, "rotate left a",        NULL, NULL, flow_no_branch },
  [00620 >> 6] = { NULL, "p - 1 -> p",           NULL, NULL, flow_no_branch },
  [00720 >> 6] = { NULL, "p + 1 -> p",           NULL, NULL, flow_no_branch },
  [01020 >> 6] = { NULL, "return",               NULL, NULL, flow_subroutine_return },
  [01120 >> 6] = { NULL, NULL,                   NULL, NULL, flow_no_branch },
  [01220 >> 6] = { NULL, NULL,                   NULL, NULL, flow_no_branch },
  [01320 >> 6] = { NULL, NULL,                   NULL, NULL, flow_no_branch },
  [01420 >> 6] = { NULL, NULL,                   NULL, NULL, flow_no_branch },
  [01520 >> 6] = { NULL, NULL,                   NULL, NULL, flow_no_branch },
  [01620 >> 6] = { NULL, NULL,                   NULL, NULL, flow_no_branch },
  [01720 >> 6] = { NULL, NULL,                   NULL, NULL, flow_no_branch },
};

static misc_inst_info_t misc_60_info [16] =
{
  [00060 >> 6] = { NULL, NULL,                   NULL, NULL, flow_no_branch },
  [00160 >> 6] = { NULL, NULL,                   NULL, NULL, flow_no_branch },
  [00260 >> 6] = { NULL, NULL,                   NULL, NULL, flow_no_branch },
  [00360 >> 6] = { NULL, NULL,                   NULL, NULL, flow_no_branch },
  [00460 >> 6] = { NULL, NULL,                   NULL, NULL, flow_no_branch },
  [00560 >> 6] = { NULL, NULL,                   NULL, NULL, flow_no_branch },
  [00660 >> 6] = { NULL, NULL,                   NULL, NULL, flow_no_branch },
  [00760 >> 6] = { NULL, NULL,                   NULL, NULL, flow_no_branch },
  [01060 >> 6] = { NULL, "bank_switch",          NULL, NULL, flow_bank_switch },
  [01160 >> 6] = { NULL, "c -> data address",    NULL, NULL, flow_no_branch },
  [01260 >> 6] = { NULL, "clear data registers", NULL, NULL, flow_no_branch },
  [01360 >> 6] = { NULL, "c -> data",            NULL, NULL, flow_no_branch },
  [01460 >> 6] = { NULL, "rom checksum",         NULL, NULL, flow_subroutine_return },
  [01560 >> 6] = { NULL, NULL,                   NULL, NULL, flow_no_branch },
  [01660 >> 6] = { NULL, NULL,                   NULL, NULL, flow_no_branch },
  [01760 >> 6] = { NULL, "hi i'm woodstock",     NULL, NULL, flow_no_branch },
};

static misc_inst_info_t misc_info [16] =
{
  { misc_00_info, NULL,                     NULL,         NULL,       flow_no_branch },
  { NULL,         "1 -> s %d",              NULL,         NULL,       flow_no_branch },
  { misc_10_info, NULL,                     NULL,         NULL,       flow_no_branch },
  { NULL,         "0 -> s %d",              NULL,         NULL,       flow_no_branch },
  { misc_20_info, NULL,                     NULL,         NULL,       flow_no_branch },
  { NULL,         "if 1 = s %d",            NULL,         NULL,       flow_cond_branch },
  { NULL,         "load constant %d",       NULL,         NULL,       flow_no_branch },
  { NULL,         "if 0 = s %d",            NULL,         NULL,       flow_cond_branch },
  { NULL,         "select rom @%02o (%%s)", NULL,         NULL,       flow_select_rom },
  { NULL,         "if p = %d",              NULL,         p_test_map, flow_cond_branch },
  { NULL,         "c -> register %d",       NULL,         NULL,       flow_no_branch },
  { NULL,         "if p # %d",              NULL,         p_test_map, flow_cond_branch },
  { misc_60_info, NULL,                     NULL,         NULL,       flow_no_branch },
  { NULL,         "delayed rom @%02o",      NULL,         NULL,       flow_delayed_rom },
  { NULL,         "register -> c %d",       "data -> c",  NULL,       flow_no_branch },
  { NULL,         "p <- %d",                NULL,         p_set_map,  flow_no_branch },
};


typedef struct
{
  char *mnem;
  bool can_set_carry;
  bool cond_branch;
} arith_inst_info_t;

static arith_inst_info_t arith_info [32] =
  {
    { "0 -> a[%s]",         false, false },
    { "0 -> b[%s]",         false, false },
    { "a exchange b[%s]",   false, false },
    { "a -> b[%s]",         false, false },
    { "a exchange c[%s]",   false, false },
    { "c -> a[%s]",         false, false },
    { "b -> c[%s]",         false, false },
    { "b exchange c[%s]",   false, false },
    { "0 -> c[%s]",         false, false },
    { "a + b -> a[%s]",     true,  false },
    { "a + c -> a[%s]",     true,  false },
    { "c + c -> c[%s]",     true,  false },
    { "a + c -> c[%s]",     true,  false },
    { "a + 1 -> a[%s]",     true,  false },
    { "shift left a[%s]",   false, false },
    { "c + 1 -> c[%s]",     true,  false },
    { "a - b -> a[%s]",     true,  false },
    { "a - c -> c[%s]",     true,  false },
    { "a - 1 -> a[%s]",     true,  false },
    { "c - 1 -> c[%s]",     true,  false },
    { "0 - c -> c[%s]",     true,  false },
    { "0 - c - 1 -> c[%s]", true,  false },
    { "if b[%s] = 0",       false, true },
    { "if c[%s] = 0",       false, true },
    { "if a >= c[%s]",      false, true },
    { "if a >= b[%s]",      false, true },
    { "if a[%s] # 0",       false, true },
    { "if c[%s] # 0",       false, true },
    { "a - c -> a[%s]",     true,  false },
    { "shift right a[%s]",  false, false },
    { "shift right b[%s]",  false, false },
    { "shift right c[%s]",  false, false }
  };

static char *field_mnem [8] =
  { "p", "wp", "xs", "x", "s", "m", "w", "ms" };


static bool two_word_inst (rom_word_t op1)
{
  if (op1 & 01)  // "jsb" and "if n/c goto" instructions are single word
    return false;
  
  if (op1 & 02)  // arithmetic comparisons are two word
    return arith_info [op1 >> 5].cond_branch;

  uint16_t misc_op = op1 & 074;
  return (misc_op & 04) && (misc_op >= 024) && (misc_op <= 054);
}


bool woodstock_disassemble (sim_t  *sim,
			    // input and output:
			    bank_t *bank,
			    addr_t *addr,
			    bool   *carry_known_clear,
			    addr_t *delayed_select_mask,
			    addr_t *delayed_select_addr,
			    // output:
			    flow_type_t *flow_type,
			    bank_t *target_bank,
			    addr_t *target_addr,
			    char *buf,
			    int len)
{
  bool two_word;
  bool new_carry_known_clear = true;
  addr_t new_delayed_select_mask = 0;
  addr_t new_delayed_select_addr = 0;

  rom_word_t op1;

  if (! sim_read_rom (sim, *bank, *addr, & op1))
    return false;
  (*addr) = ((*addr) + 1) & 07777;

  *flow_type = flow_no_branch;

  switch (op1 & 3)
    {
    case 0:
      // misc
      {
	int inst = (op1 >> 2) & 017;
	int arg = op1 >> 6;
	if (misc_info [inst].map)
	  arg = misc_info [inst].map [arg];
	if (misc_info [inst].subtable)
	  {
	    if (misc_info [inst].subtable [arg].mnem)
	      buf_printf (& buf, & len, "%s", misc_info [inst].subtable [arg].mnem);
	    else
	      buf_printf (& buf, & len, "op @%04o", op1);
	    *flow_type = misc_info [inst].subtable [arg].flow;
	  }
	else
	  {
	    if ((arg == 0) && misc_info [inst].arg_0_mnem)
	      buf_printf (& buf, & len, misc_info [inst].arg_0_mnem);
	    else
	      buf_printf (& buf, & len, misc_info [inst].mnem, arg);
	    *flow_type = misc_info [inst].flow;
	  }
	if ((*flow_type) == flow_select_rom)
	  {
	    *flow_type = flow_uncond_branch;
	    *target_bank = *bank;
	    *target_addr = (arg << 8) + ((*addr) & 0377);
	  }
	else if ((*flow_type) == flow_delayed_rom)
	  {
	    *flow_type = flow_no_branch;
	    new_delayed_select_mask = 017 << 8;
	    new_delayed_select_addr = arg << 8;
	  }
      }
      break;
    case 1:
      // jsb
      buf_printf (& buf, & len, "jsb %%s");
      *target_bank = *bank;
      *target_addr = ((*addr) & 07400) + (op1 >> 2);
      // $$$ need to handle delayed selects
      *flow_type = flow_subroutine_call;
      break;
    case 2:
      // arith
      {
	int op = op1 >> 5;
	int field = (op1 >> 2) & 7;
	buf_printf (& buf, & len, arith_info [op].mnem, field_mnem [field]);
	if (arith_info [op].can_set_carry)
	  new_carry_known_clear = false;
      }
      break;
    case 3:
      // if n/c go to
      if (* carry_known_clear)
	{
	  *flow_type = flow_uncond_branch;
	  buf_printf (& buf, & len, "go to %%s");
	}
      else
	{
	  *flow_type = flow_cond_branch;
	  buf_printf (& buf, & len, "if n/c go to %%s");
	}
      *target_bank = *bank;
      *target_addr = ((*addr) & 07400) + (op1 >> 2);
      // $$$ need to handle delayed selects
      break;
    }

  two_word = two_word_inst (op1);
  if (two_word)
    {
      rom_word_t op2;

      if (*delayed_select_mask)
	warning ("delayed select precedes two-word instruction!\n");
      if (! sim_read_rom (sim, *bank, *addr, & op2))
	return false;
      (*addr) = ((*addr) + 1) & 07777;
      buf_printf (& buf, & len, " then go to %%s");
      *flow_type = flow_cond_branch;
      *target_bank = *bank;
      *target_addr = ((*addr) & 06000) + op2;
    }

  if (*delayed_select_mask)
    {
      if (*flow_type == flow_no_branch)
	{
	  warning ("delayed select precedes non-branch instruction!\n");
	  *flow_type = flow_uncond_branch;
	}
      *target_addr = (*target_addr & ~ *delayed_select_mask) | 
		     (*delayed_select_mask & *delayed_select_addr);
    }

  *carry_known_clear = new_carry_known_clear;
  *delayed_select_mask = new_delayed_select_mask;
  *delayed_select_addr = new_delayed_select_addr;

  return true;
}
