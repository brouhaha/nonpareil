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

#include <stdio.h>


static int nut_disassemble_short_branch (int addr, int op1,
					 char *buf, int len)
{
  int offset, cond, target;

  offset = (op1 >> 3) & 0x3f;
  if (op1 & 0x200)
    offset -= 64;
  target = addr + offset;

  cond = (op1 >> 2) & 1;

  snprintf (buf, len, "?%s goto %05o", cond ? "c " : "nc", target);

  return (1);
}


static int nut_disassemble_long_branch (int op1, int op2,
					char *buf, int len)
{
  int cond, type, target;

  target = (op1 >> 2) | ((op2 & 0x3fc) << 6);

  cond = op2 & 0x001;

  type = op2 & 0x002;

  snprintf (buf, len, "?%s %s %05o", cond ? "c " : "nc",
	    type ? "goto" : "call", target);

  return (2);
}


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


static char *nut_op20 [16] =
  { 
    /* 0x020 */ "pop",
    /* 0x060 */ "powoff",
    /* 0x0a0 */ "sel p", 
    /* 0x0e0 */ "sel q",
    /* 0x120 */ "? p=q",
    /* 0x160 */ "lld",
    /* 0x1a0 */ "clear abc",
    /* 0x130 */ "goto c",
    /* 0x220 */ "c=keys",
    /* 0x260 */ "set hex",
    /* 0x2a0 */ "set dec",
    /* 0x2e0 */ "disp off",
    /* 0x320 */ "disp toggle",
    /* 0x360 */ "?c rtn",
    /* 0x3a0 */ "?nc rtn",
    /* 0x3e0 */ "rtn"
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


static int nut_disassemble_00 (int op1, int op2, char *buf, int len)
{
  int arg = op1 >> 6;
  int inst_len = 1;

  switch (op1 & 0x03c)
    {
    case 0x000:
      snprintf (buf, len, "%s", nut_op00 [op1 >> 6]);
      break;
    case 0x004:
      if (op1 == 0x3c4)
	snprintf (buf, len, "clr s");
      else
	snprintf (buf, len, "s=0 %d", tmap [arg]);
      break;
    case 0x008:
      if (op1 == 0x3c8)
	snprintf (buf, len, "clr kb");
      else
	snprintf (buf, len, "s=1 %d", tmap [arg]);
      break;
    case 0x00c:
      if (op1 == 0x3cc)
	snprintf (buf, len, "? kb");
      else
	snprintf (buf, len, "? s=0 %d", tmap [arg]);
      break;
    case 0x010:
      snprintf (buf, len, "lc %d", arg);
      break;
    case 0x014:
      if (op1 == 0x3d4)
	snprintf (buf, len, "dec pt");
      else
	snprintf (buf, len, "? pt= %d", tmap [arg]);
      break;
    case 0x018:
      snprintf (buf, len, "%s", nut_op18 [op1 >> 6]);
      break;
    case 0x01c:
      if (op1 == 0x3dc)
	snprintf (buf, len, "inc pt");
      else
	snprintf (buf, len, "pt= %d", tmap [arg]);
      break;
    case 0x020:
      snprintf (buf, len, "%s", nut_op20 [op1 >> 6]);
      inst_len = 2;
      break;
    case 0x024:
      snprintf (buf, len, "selprf %d", arg);
      break;
    case 0x028:
      snprintf (buf, len, "wrreg %d", arg);
      break;
    case 0x02c:
      snprintf (buf, len, "? ext %d", tmap [arg]);
      break;
    case 0x030:
      if (op1 == 0x130)
	 {
	    snprintf (buf, len, "ldi %04o", op2);
	    inst_len = 2;
	 }
      else
	snprintf (buf, len, "%s", nut_op30 [op1 >> 6]);
      break;
    case 0x034:
      snprintf (buf, len, "??? %d", arg);
      break;
    case 0x038:
      snprintf (buf, len, "rdreg %d", arg);
      break;
    case 0x03c:
      if (op1 == 0x3fc)
	snprintf (buf, len, "disp compensation");
      else
	snprintf (buf, len, "? rcr %d", tmap [arg]);
      break;
    }

  return (inst_len);
}
 

static char *nut_arith_mnem [32] =
  {
    "a=0",    "b=0",    "c=0",    "ab ex",
    "b=a",    "ac ex",  "c=b",    "bc ex",
    "a=c",    "a=a+b",  "a=a+c",  "a=a+1",
    "a=a-b",  "a=a-1",  "a=a-c",  "c=c+c",
    "c=a+c",  "c=c+1",  "c=a-c",  "c=c-1",
    "c=-c",   "c=-c-1", "? b<>0", "? c<>0",
    "? a<c",  "? a<b",  "? a<>0", "? a<>c",
    "a sr",   "b sr",   "c sr",   "a sl"
  };

static char *nut_field_mnem [8] =
  { "p", "x", "wp", "w", "pq", "xs", "m", "s" };


static int nut_disassemble_arith (int op1, char *buf, int len)
{
  int l;
  int op = op1 >> 5;
  int field = (op1 >> 2) & 7;

  l = snprintf (buf, len, "%-8s%s",
		nut_arith_mnem [op],
		nut_field_mnem [field]);
  return (1);
}


int nut_disassemble_inst (int addr, int op1, int op2,
			  char *buf, int len)
{
  int l;

  l = snprintf (buf, len, "%05o: %04o ", addr, op1);
  buf += l;
  len -= l;
  if (len <= 0)
    return (0);

  switch (op1 & 3)
    {
    case 0:
      return (nut_disassemble_00 (op1, op2, buf, len));
    case 1:
      return (nut_disassemble_long_branch (op1, op2, buf, len));
    case 2:
      return (nut_disassemble_arith (op1, buf, len));
    case 3:
      return (nut_disassemble_short_branch (addr, op1, buf, len));
    }
  return (0);  // can't happen, but avoid compiler warning
}
