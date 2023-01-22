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

/*
 * NOTE:
 * Labels are allowed to contain colons but not to end with a colon.  The HP
 * assembler allows a label, colon, and mnemonic with no intervening white spaces.
 * Due to the greedy nature of token matching, nasm does not permit this; a label
 * and colon must be followed by whitespace.
 */

%option prefix="nasm_"
%option noyywrap

%{
#include <stdbool.h>
#include <stdint.h>
#include <string.h>

#include "nasm_y.h"
#include "util.h"
#include "symtab.h"
#include "arch.h"
#include "asm.h"

static keyword_t nasm_keywords [] =
{
  { "a",         A },
  { "b",         B },
  { "c",         C },
  { "f",         F },
  { "G",         G },
  { "m",         M },
  { "n",         N },
  { "p",         P },
  { "q",         Q },
  { "s",         S },
  { "w",         W },
  { "x",         X },

  { "ab",        AB },
  { "abc",       ABC },
  { "ac",        AC },
  { "bc",        BC },
  { "blink",     BLINK },
  { "clr",       CLR },
  { "cxisa",     CXISA },
  { "data",      DATA },
  { "dec",       DEC },
  { "disp",      DISP },
  { "dw",        DW },
  { "equ",       EQU },
  { "ex",        EX },
  { "ext",       EXT },
  { "golong",    GOLONG },
  { "goto",      GOTO },
  { "gosub",     GOSUB },
  { "hex",       HEX },
  { "inc",       INC },
  { "kb",        KB },
  { "keys",      KEYS },
  { "legal",     LEGAL },
  { "lc",        LC },
  { "ldi",       LDI },
  { "lld",       LLD },
  { "nc",        NC },
  { "nop",       NOP },
  { "off",       OFF },
  { "org",       ORG },
  { "pfad",      PFAD },
  { "pop",       POP },
  { "powoff",    POWOFF },
  { "pq",        PQ },
  { "pt",        PT },
  { "ram",       RAM },
  { "rcr",       RCR },
  { "reg",       REG },
  { "regs",      REGS },
  { "rtn",       RTN },
  { "sb",        SB },
  { "sel",       SEL },
  { "set",       SET },
  { "sl",        SL },
  { "sr",        SR },
  { "st",        ST },
  { "stk",       STK },
  { "symtab",    SYMTAB },
  { "toggle",    TOGGLE },
  { "wp",        WP },
  { "xs",        XS },
  { NULL,        0 }
};

#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
  { \
    int r = strlen (lineptr); \
    if (r > max_size) \
      r = max_size; \
    memcpy (buf, lineptr, r); \
    lineptr += r; \
    result = r; \
  }

%}

octaldig	[0-7]
digit		[0-9]
hexdig          [0-9a-fA-F]

lglobal		[$]
lfirst		[a-zA-Z0-9]
lmiddle		[a-zA-Z0-9_]
lend		[a-zA-Z0-9_]

lb		\[
rb		\]

%%

{digit}+	{ nasm_lval.integer = atoi (yytext); return INTEGER; }

@{octaldig}+	{ sscanf (yytext+1, "%o", &nasm_lval.integer); return INTEGER; }

0x{hexdig}+	{ sscanf (yytext+2, "%x", &nasm_lval.integer); return INTEGER; }


{lglobal}*{lfirst}({lmiddle}*{lend})?	{
                          if ((nasm_lval.integer = keyword (yytext, nasm_keywords)))
                            return nasm_lval.integer;
                          nasm_lval.string = newstr (yytext);
                          return IDENT;
			}

\<\>            { return EX; }

\<\<            { return LSH_OP; }
\>\>            { return RSH_OP; }
\<\=            { return LE_OP; }
\>\=            { return GE_OP; }
\=\=            { return EQ_OP; }
\!\=            { return NE_OP; }


\;.*		;
[ \t]+		;
\n		;

.		{ return yytext [0]; }

%%
