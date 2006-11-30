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

#include <stdint.h>
#include <stdio.h>


static uint8_t p_set_map [16] =
  { 14,  4,  7,  8, 11,  2, 10, 12,  1,  3, 13,  6,  0,  9,  5, 14 };

static uint8_t p_test_map [16] =
  {  4,  8, 12,  2,  9,  1,  6,  3,  1, 13,  5,  0, 11, 10,  7,  4 };


static int woodstock_disassemble_branch (char *mnem, int addr, int op1,
					 char *buf, int len)
{
  int l;
  int target;

  target = (addr & 07400) + (op1 >> 2);

  l = snprintf (buf, len, "%s %04o", mnem, target);
  buf += l;
  len -= l;

  return (1);
}


static char *woodstock_misc_00_mnem [16] =
  {
    "???",
    "???",
    "???",
    "crc f1?",
    "???",
    "???",
    "???",
    "???",
    "???",
    "???",
    "???",
    "???",
    "???",
    "???",
    "???",
    "???"
  };


static char *woodstock_misc_10_mnem [16] =
  {
    "clear regs",
    "clear status",
    "display toggle",
    "display off",
    "m1 exchange c",
    "m1 -> c",
    "m2 exchange c",
    "m2 -> c",
    "stack -> a",
    "down rotate",
    "y -> a",
    "c -> stack",
    "decimal",
    "???",
    "f -> a[x]",
    "f exchange a[x]"
  };


static char *woodstock_misc_20_mnem [16] =
  {
    "keys -> rom address",
    "keys -> a",
    "a -> rom address",
    "reset twf",
    "binary",
    "rotate a left",
    "p - 1 -> p",
    "p + 1 -> p",
    "return",
    "???",
    "???",
    "???",
    "???",
    "???",
    "???",
    "???"
  };


static char *woodstock_misc_60_mnem [16] =
  {
    "???",
    "???",
    "???",
    "???",
    "???",
    "???",
    "???",
    "???",
    "bank switch",
    "c -> data address",
    "clear data registers",
    "c -> data",
    "rom checksum",
    "???",
    "???",
    "hi i'm woodstock"   // "hi i'm woodstock" in HP-25 source code.
    			 // Apparently a NOP to ACT, but may be used by CRC
			 // or PIK.
  };


static void woodstock_disassemble_then (int addr, int op2, char *buf, int len)
{
  snprintf (buf, len, " then go to %04o", (addr & 006000) + op2);
}


static int woodstock_disassemble_00 (int addr, int op1, int op2,
				     char *buf, int len)
{
  int arg = op1 >> 6;
  int l;
  int inst_len = 1;

  switch (op1 & 074)
    {
    case 000:
      snprintf (buf, len, "%s", woodstock_misc_00_mnem [arg]);
      break;
    case 004:
      snprintf (buf, len, "1 -> s %d", arg);
      break;
    case 010:
      snprintf (buf, len, "%s", woodstock_misc_10_mnem [arg]);
      break;
    case 014:
      snprintf (buf, len, "0 -> s %d", arg);
      break;
    case 020:
      snprintf (buf, len, "%s", woodstock_misc_20_mnem [arg]);
      break;
    case 024:
      l = snprintf (buf, len, "if 1 = s %d", arg);
      buf += l;
      len -= l;
      if (len > 0)
	woodstock_disassemble_then (addr + 1, op2, buf, len);
      inst_len = 2;
      break;
    case 030:
      snprintf (buf, len, "load constant %d", arg);
      break;
    case 034:
      l = snprintf (buf, len, "if 0 = s %d", arg);
      buf += l;
      len -= l;
      if (len > 0)
	woodstock_disassemble_then (addr + 1, op2, buf, len);
      inst_len = 2;
      break;
    case 040:
      snprintf (buf, len, "select rom %02o", arg);
      break;
    case 044:
      l = snprintf (buf, len, "if p = %d", p_test_map [arg]);
      buf += l;
      len -= l;
      if (len > 0)
	woodstock_disassemble_then (addr + 1, op2, buf, len);
      inst_len = 2;
      break;
    case 050:
      snprintf (buf, len, "c -> register %d", arg);
      break;
    case 054:
      l = snprintf (buf, len, "if p # %d", p_test_map [arg]);
      buf += l;
      len -= l;
      if (len > 0)
	woodstock_disassemble_then (addr + 1, op2, buf, len);
      inst_len = 2;
      break;
    case 060:
      snprintf (buf, len, "%s", woodstock_misc_60_mnem [op1 >> 6]);
      break;
    case 064:
      snprintf (buf, len, "delayed rom %02o", arg);
      break;
    case 070:
      if (arg == 0)
	snprintf (buf, len, "data -> c");
      else
	snprintf (buf, len, "register -> c %d", arg);
      break;
    case 074:
      snprintf (buf, len, "p <- %d", p_set_map [arg]);
      break;
    }

  return (inst_len);
}
 

static char *woodstock_arith_mnem [32] [2] =
  {
    { "0 -> a", NULL },
    { "0 -> b", NULL },
    { "a exchange b", NULL },
    { "a -> b", NULL },
    { "a exchange c", NULL },
    { "c -> a", NULL },
    { "b -> c", NULL },
    { "b exchange c", NULL },
    { "0 -> c", NULL },
    { "a + b -> a", NULL },
    { "a + c -> a", NULL },
    { "c + c -> c", NULL },
    { "a + c -> c", NULL },
    { "a + 1 -> a", NULL },
    { "shift left a", NULL },
    { "c + 1 -> c", NULL },
    { "a - b -> a", NULL },
    { "a - c -> c", NULL },
    { "a - 1 -> a", NULL },
    { "c - 1 -> c", NULL },
    { "0 - c -> c", NULL },
    { "0 - c - 1 -> c", NULL },
    { "if b", " = 0" },
    { "if c", " = 0" },
    { "if a >= c", NULL },
    { "if a >= b", NULL },
    { "if a", " # 0" },
    { "if c", " # 0" },
    { "a - c -> a", NULL },
    { "shift right a", NULL },
    { "shift right b", NULL },
    { "shift right c", NULL }
  };

static char *woodstock_field_mnem [8] =
  { "p", "wp", "xs", "x", "s", "m", "w", "ms" };


static int woodstock_disassemble_arith (int addr, int op1, int op2,
					char *buf, int len)
{
  int l;
  int op = op1 >> 5;
  int field = (op1 >> 2) & 7;

  l = snprintf (buf, len, "%s[%s]",
		woodstock_arith_mnem [op] [0],
		woodstock_field_mnem [field]);
  buf += l;
  len -= l;
  if (len <= 0)
    return (0);
  if (woodstock_arith_mnem [op] [1])
    {
      l = snprintf (buf, len, "%s", woodstock_arith_mnem [op] [1]);
      buf += l;
      len -= l;
    }
  if (len <= 0)
    return (0);
  if ((op < 0x16) || (op > 0x1b))
    return (1);
  woodstock_disassemble_then (addr + 1, op2, buf, len);
  return (2);
}


int woodstock_disassemble_inst (int addr, int op1, int op2,
				char *buf, int len)
{
  int l;

  l = snprintf (buf, len, "%o-%04o: %04o ",
		addr >> 12, addr & 07777, op1);
  buf += l;
  len -= l;
  if (len <= 0)
    return (0);

  switch (op1 & 3)
    {
    case 0:
      return (woodstock_disassemble_00 (addr, op1, op2, buf, len));
    case 1:
      return (woodstock_disassemble_branch ("jsb ", addr, op1, buf, len));
    case 2:
      return (woodstock_disassemble_arith (addr, op1, op2, buf, len));
    case 3:
      return (woodstock_disassemble_branch ("if n/c go to ", addr, op1, buf, len));
    }

  return (0);  // can't happen, but avoid compiler warning
}
