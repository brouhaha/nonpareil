/*
$Id$
Copyright 2008, 2010 Eric Smith <eric@brouhaha.com>

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
#include "calcdef.h"
#include "proc.h"
#include "digit_ops.h"
//#include "proc_nut.h"
#include "dis_uc41.h"


static const char *uc_mnem [0x100] =
{
  [0x00] = "NULL",
  [0x01] = "LBL 00",
  [0x02] = "LBL 01",
  [0x03] = "LBL 02",
  [0x04] = "LBL 03",
  [0x05] = "LBL 04",
  [0x06] = "LBL 05",
  [0x07] = "LBL 06",
  [0x08] = "LBL 07",
  [0x09] = "LBL 08",
  [0x0a] = "LBL 09",
  [0x0b] = "LBL 10",
  [0x0c] = "LBL 11",
  [0x0d] = "LBL 12",
  [0x0e] = "LBL 13",
  [0x0f] = "LBL 14",
  [0x10] = "0",
  [0x11] = "1",
  [0x12] = "2",
  [0x13] = "3",
  [0x14] = "4",
  [0x15] = "5",
  [0x16] = "6",
  [0x17] = "7",
  [0x18] = "8",
  [0x19] = "9",
  [0x1a] = ".",
  [0x1b] = " E",
  [0x1c] = "-",
  [0x1d] = "GTO",
  [0x1e] = "XEQ",
  [0x1f] = "0x1f",
  [0x20] = "RCL 00",
  [0x21] = "RCL 01",
  [0x22] = "RCL 02",
  [0x23] = "RCL 03",
  [0x24] = "RCL 04",
  [0x25] = "RCL 05",
  [0x26] = "RCL 06",
  [0x27] = "RCL 07",
  [0x28] = "RCL 08",
  [0x29] = "RCL 09",
  [0x2a] = "RCL 10",
  [0x2b] = "RCL 11",
  [0x2c] = "RCL 12",
  [0x2d] = "RCL 13",
  [0x2e] = "RCL 14",
  [0x2f] = "RCL 15",
  [0x30] = "STO 00",
  [0x31] = "STO 01",
  [0x32] = "STO 02",
  [0x33] = "STO 03",
  [0x34] = "STO 04",
  [0x35] = "STO 05",
  [0x36] = "STO 06",
  [0x37] = "STO 07",
  [0x38] = "STO 08",
  [0x39] = "STO 09",
  [0x3a] = "STO 10",
  [0x3b] = "STO 11",
  [0x3c] = "STO 12",
  [0x3d] = "STO 13",
  [0x3e] = "STO 14",
  [0x3f] = "STO 15",
  [0x40] = "+",
  [0x41] = "-",
  [0x42] = "*",
  [0x43] = "/",
  [0x44] = "X<Y?",
  [0x45] = "X>Y?",
  [0x46] = "X<=Y?",
  [0x47] = "Sigma+",
  [0x48] = "Sigma-",
  [0x49] = "HMS+",
  [0x4a] = "HMS-",
  [0x4b] = "MOD",
  [0x4c] = "%",
  [0x4d] = "%CH",
  [0x4e] = "P->R",
  [0x4f] = "R->P",
  [0x50] = "LN",
  [0x51] = "X^2",
  [0x52] = "SQRT",
  [0x53] = "Y^X",
  [0x54] = "CHS",
  [0x55] = "E^X",
  [0x56] = "LOG",
  [0x57] = "10^X",
  [0x58] = "E^X-1",
  [0x59] = "SIN",
  [0x5a] = "COS",
  [0x5b] = "TAN",
  [0x5c] = "ASIN",
  [0x5d] = "ACOS",
  [0x5e] = "ATAN",
  [0x5f] = "->DEC",
  [0x60] = "1/X",
  [0x61] = "ABS",
  [0x62] = "FACT",
  [0x63] = "X!=0?",
  [0x64] = "X>0?",
  [0x65] = "LN1+X",
  [0x66] = "X<0?",
  [0x67] = "X=0?",
  [0x68] = "INT",
  [0x69] = "FRC",
  [0x6a] = "D->R",
  [0x6b] = "R->D",
  [0x6c] = "->HMS",
  [0x6d] = "->HR",
  [0x6e] = "RND",
  [0x6f] = "OCT",
  [0x70] = "CLSigma",
  [0x71] = "X<>Y",
  [0x72] = "PI",
  [0x73] = "CLST",
  [0x74] = "R^",
  [0x75] = "RDN",
  [0x76] = "LASTX",
  [0x77] = "CLX",
  [0x78] = "X=Y?",
  [0x79] = "X!=Y?",
  [0x7a] = "SIGN",
  [0x7b] = "X<=0?",
  [0x7c] = "MEAN",
  [0x7d] = "SDEV",
  [0x7e] = "AVIEW",
  [0x7f] = "CLD",
  [0x80] = "DEG",
  [0x81] = "RAD",
  [0x82] = "GRAD",
  [0x83] = "ENTER^",
  [0x84] = "STOP",
  [0x85] = "RTN",
  [0x86] = "BEEP",
  [0x87] = "CLA",
  [0x88] = "ASHF",
  [0x89] = "PSE",
  [0x8a] = "CLRG",
  [0x8b] = "AOFF",
  [0x8c] = "AON",
  [0x8d] = "OFF",
  [0x8e] = "PROMPT",
  [0x8f] = "ADV",
  [0x90] = "RCL",
  [0x91] = "STO",
  [0x92] = "ST+",
  [0x93] = "ST-",
  [0x94] = "ST*",
  [0x95] = "ST/",
  [0x96] = "ISG",
  [0x97] = "DSE",
  [0x98] = "VIEW",
  [0x99] = "SigmaREG",
  [0x9a] = "ASTO",
  [0x9b] = "ARCL",
  [0x9c] = "FIX",
  [0x9d] = "SCI",
  [0x9e] = "ENG",
  [0x9f] = "TONE",
  [0xa0] = "XROM",
  [0xa1] = "XROM",
  [0xa2] = "XROM",
  [0xa3] = "XROM",
  [0xa4] = "XROM",
  [0xa5] = "XROM",
  [0xa6] = "XROM",
  [0xa7] = "XROM",
  [0xa8] = "SF",
  [0xa9] = "CF",
  [0xaa] = "FS?C",
  [0xab] = "FC?C",
  [0xac] = "FS?",
  [0xad] = "FC?",
  [0xae] = "GTO/XEQ IND",
  [0xaf] = "0xaf",
  [0xb0] = "0xb0",
  [0xb1] = "GTO 01",
  [0xb2] = "GTO 02",
  [0xb3] = "GTO 03",
  [0xb4] = "GTO 04",
  [0xb5] = "GTO 05",
  [0xb6] = "GTO 06",
  [0xb7] = "GTO 07",
  [0xb8] = "GTO 08",
  [0xb9] = "GTO 09",
  [0xba] = "GTO 10",
  [0xbb] = "GTO 11",
  [0xbc] = "GTO 12",
  [0xbd] = "GTO 13",
  [0xbe] = "GTO 14",
  [0xbf] = "GTO 15",
  [0xc0] = "global",
  [0xc1] = "global",
  [0xc2] = "global",
  [0xc3] = "global",
  [0xc4] = "global",
  [0xc5] = "global",
  [0xc6] = "global",
  [0xc7] = "global",
  [0xc8] = "global",
  [0xc9] = "global",
  [0xca] = "global",
  [0xcb] = "global",
  [0xcc] = "global",
  [0xcd] = "global",
  [0xce] = "X<>",
  [0xcf] = "LBL",
  [0xd0] = "GTO",
  [0xd1] = "GTO",
  [0xd2] = "GTO",
  [0xd3] = "GTO",
  [0xd4] = "GTO",
  [0xd5] = "GTO",
  [0xd6] = "GTO",
  [0xd7] = "GTO",
  [0xd8] = "GTO",
  [0xd9] = "GTO",
  [0xda] = "GTO",
  [0xdb] = "GTO",
  [0xdc] = "GTO",
  [0xdd] = "GTO",
  [0xde] = "GTO",
  [0xdf] = "GTO",
  [0xe0] = "XEQ",
  [0xe1] = "XEQ",
  [0xe2] = "XEQ",
  [0xe3] = "XEQ",
  [0xe4] = "XEQ",
  [0xe5] = "XEQ",
  [0xe6] = "XEQ",
  [0xe7] = "XEQ",
  [0xe8] = "XEQ",
  [0xe9] = "XEQ",
  [0xea] = "XEQ",
  [0xeb] = "XEQ",
  [0xec] = "XEQ",
  [0xed] = "XEQ",
  [0xee] = "XEQ",
  [0xef] = "XEQ",
  [0xf0] = "text",
  [0xf1] = "text",
  [0xf2] = "text",
  [0xf3] = "text",
  [0xf4] = "text",
  [0xf5] = "text",
  [0xf6] = "text",
  [0xf7] = "text",
  [0xf8] = "text",
  [0xf9] = "text",
  [0xfa] = "text",
  [0xfb] = "text",
  [0xfc] = "text",
  [0xfd] = "text",
  [0xfe] = "text",
  [0xff] = "text"
};

static const char *uc_high_postfix [28] =
{
  /* 0x64..0x65 */ "100", "101",
  /* 0x66..0x6f */ "A", "B", "C", "D", "E", "F", "G", "H", "I", "J",
  /* 0x70..0x74 */ "T", "Z", "Y", "X", "L",
  /* 0x75..0x7a */ "M", "N", "O", "P", "Q", "&",
  /* 0x7b..0x7f */ "a", "b", "c", "d", "e"
};

static bool disassemble_digit_entry (sim_t  *sim,
				     bank_t *bank,
				     addr_t *addr,
				     char   *buf,
				     int    len)
{
  rom_word_t op1;
  int op1_2msb;

  for (;;)
    {
      if (! sim_read_rom (sim, *bank, *addr, & op1))
	return false;
      op1_2msb = op1 >> 8;
      op1 &= 0xff;
      if ((op1 < 0x10) || (op1 > 0x1c))
	break;
      buf_printf (& buf, & len, "%s", uc_mnem [op1]);
      (*addr) = ((*addr) + 1) & 0xffff;
    }
  return true;
}


static bool disassemble_standard_postfix (sim_t      *sim,
					  rom_word_t op1,
					  bank_t     *bank,
					  addr_t     *addr,
					  char       *buf,
					  int        len)
{
  rom_word_t op2;

  if (! sim_read_rom (sim, *bank, *addr, & op2))
    return false;
  op2 &= 0xff;
  (*addr) = ((*addr) + 1) & 0xffff;
  buf_printf (& buf, & len, uc_mnem [op1]);
  if (op2 & 0x80)
    buf_printf (& buf, & len, " IND");
  if ((op2 & 0x7f) <= 99)
    buf_printf (& buf, & len, " %02d", op2 & 0x7f);
  else
    buf_printf (& buf, & len, " %s", uc_high_postfix [(op2 & 0x7f) - 100]);
  return true;
}


static bool disassemble_string (sim_t      *sim,
				bank_t     *bank,
				addr_t     *addr,
				char       *buf,
				int        len,
				bool       skip_first_char)
{
  rom_word_t len_byte, char_byte;

  if (! sim_read_rom (sim, *bank, *addr, & len_byte))
    return false;
  (*addr) = ((*addr) + 1) & 0xffff;

  len_byte &= 0xf;

  if (skip_first_char && len_byte)
    {
      (*addr) = ((*addr) + 1) & 0xffff;
      len_byte--;
    }

  buf_printf (& buf, & len, "\"");
  while (len_byte--)
    {
      if (! sim_read_rom (sim, *bank, *addr, & char_byte))
	return false;
      char_byte &= 0xff;
      (*addr) = ((*addr) + 1) & 0xffff;
      if ((char_byte >= 0x20) && (char_byte <= 0x7e))
	buf_printf (& buf, & len, "%c", char_byte);
      else
	buf_printf (& buf, & len, "\\%03o", char_byte);
    }
  buf_printf (& buf, & len, "\"");

  return true;
}


static bool disassemble_gto_xeq_ind (sim_t      *sim,
				     bank_t     *bank,
				     addr_t     *addr,
				     char       *buf,
				     int        len)
{
  rom_word_t op2;

  if (! sim_read_rom (sim, *bank, *addr, & op2))
    return false;
  op2 &= 0xff;
  (*addr) = ((*addr) + 1) & 0xffff;

  buf_printf (& buf, & len, "%s IND ", (op2 & 0x80) ? "XEQ" : "GTO");
  if ((op2 & 0x7f) <= 99)
    buf_printf (& buf, & len, " %02d", op2 & 0x7f);
  else
    buf_printf (& buf, & len, " %s", uc_high_postfix [(op2 & 0x7f) - 100]);
  return true;
}


static bool disassemble_gto_short (sim_t      *sim,
				   rom_word_t op1,
				   bank_t     *bank,
				   addr_t     *addr,
				   char       *buf,
				   int        len)
{
  rom_word_t op2;

  if (! sim_read_rom (sim, *bank, *addr, & op2))
    return false;
  op2 &= 0xff;
  (*addr) = ((*addr) + 1) & 0xffff;

  buf_printf (& buf, & len, "GTO %02d", op1 - 0xb1);
  return true;
}


static bool disassemble_gto_xeq_long (sim_t       *sim,
				      rom_word_t  op1,
				      bank_t      *bank,
				      addr_t      *addr,
				      flow_type_t *flow_type,
				      char        *buf,
				      int         len)
{
  rom_word_t op3;

  (*addr) = ((*addr) + 1) & 0xffff;  // skip second byte

  if (! sim_read_rom (sim, *bank, *addr, & op3))
    return false;
  op3 &= 0xff;
  (*addr) = ((*addr) + 1) & 0xffff;

  buf_printf (& buf, & len, "GTO %02d", op1 - 0xb1);

  if (op3 & 0x200)
    *flow_type = flow_subroutine_return;
  return true;
}


static bool disassemble_gto_xeq_alpha (sim_t      *sim,
				       rom_word_t op1,
				       bank_t     *bank,
				       addr_t     *addr,
				       char       *buf,
				       int        len)
{
  buf_printf (& buf, & len, "%s ", uc_mnem [op1]);
  disassemble_string (sim, bank, addr, buf, len, false);
  return true;
}


static bool disassemble_global (sim_t      *sim,
				rom_word_t op1 UNUSED,
				bank_t     *bank,
				addr_t     *addr,
				char       *buf,
				int        len)
{
  rom_word_t op3;

  (*addr) = ((*addr) + 1) & 0xffff;  // skip second byte

  if (! sim_read_rom (sim, *bank, *addr, & op3))
    return false;
  op3 &= 0xff;

  if ((op3 & 0xf0) == 0xf0)
    {
      buf_printf (& buf, & len, "LBL ");
      return disassemble_string (sim, bank, addr, buf, len, true);
    }

  (*addr) = ((*addr) + 1) & 0xffff;
  buf_printf (& buf, & len, "END");
  return true;
}


static bool disassemble_xrom (sim_t      *sim,
			      rom_word_t op1,
			      bank_t     *bank,
			      addr_t     *addr,
			      char       *buf,
			      int        len)
{
  rom_word_t op2;

  if (! sim_read_rom (sim, *bank, *addr, & op2))
    return false;
  op2 &= 0xff;
  (*addr) = ((*addr) + 1) & 0xffff;

  buf_printf (& buf, & len, "XROM %02d,%02d",
	      ((op1 & 0x07) << 2) + (op2 >> 6),
	      (op2 & 0x3f));
  return true;
}


bool uc41_disassemble (sim_t        *sim,
		       uint32_t     flags UNUSED,
		       // input and output:
		       bank_t       *bank,
		       addr_t       *addr,
		       inst_state_t *inst_state UNUSED,
		       bool         *carry_known_clear,
		       addr_t       *delayed_select_mask UNUSED,
		       addr_t       *delayed_select_addr UNUSED,
		       // output:
		       flow_type_t  *flow_type,
		       bank_t       *target_bank UNUSED,
		       addr_t       *target_addr UNUSED,
		       char         *buf,
		       int          len)
{
  rom_word_t op1;
  int op1_2msb;

  *flow_type = flow_no_branch;
  *carry_known_clear = true;

  if (! sim_read_rom (sim, *bank, *addr, & op1))
    return false;
  op1_2msb = op1 >> 8;
  op1 &= 0xff;

  if ((op1 >= 0x10) && (op1 <= 0x1c))
    return disassemble_digit_entry (sim, bank, addr, buf, len);

  if (op1 >= 0xf0)
    return disassemble_string (sim, bank, addr, buf, len, false);

  (*addr) = ((*addr) + 1) & 0xffff;

  if ((op1 >= 0x1d) && (op1 <= 0x1e))
    return disassemble_gto_xeq_alpha (sim, op1, bank, addr, buf, len);

  if (((op1 >= 0x90) && (op1 <= 0x9f)) ||
      ((op1 >= 0xa8) && (op1 <= 0xad)) ||
      ((op1 >= 0xce) && (op1 <= 0xcf)))
    return disassemble_standard_postfix (sim, op1, bank, addr, buf, len);

  if ((op1 >= 0xa0) && (op1 <= 0xa7))
    return disassemble_xrom (sim, op1, bank, addr, buf, len);

  if (op1 == 0xae)
    return disassemble_gto_xeq_ind (sim, bank, addr, buf, len);

  if ((op1 >= 0xb1) && (op1 <= 0xbf))
    return disassemble_gto_short (sim, op1, bank, addr, buf, len);

  if ((op1 >= 0xc0) && (op1 <= 0xcd))
    return disassemble_global (sim, op1, bank, addr, buf, len);

  if ((op1 >= 0xd0) && (op1 <= 0xef))
    return disassemble_gto_xeq_long (sim, op1, bank, addr, flow_type, buf, len);
  
  // normal one-byte instruction
  buf_printf (& buf, & len, "%s ", uc_mnem [op1]);

  return true;
}


