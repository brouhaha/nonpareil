/*
$Id$
Copyright 1995, 2003, 2004, 2006, 2007, 2008 Eric L. Smith <eric@brouhaha.com>

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

/*
 * NOTE:
 * Labels are allowed to contain colons but not to end with a colon.  The HP
 * assembler allows a label, colon, and mnemonic with no intervening white spaces.
 * Due to the greedy nature of token matching, wasm does not permit this; a label
 * and colon must be followed by whitespace.
 */

%option prefix="wasm_"
%option noyywrap

%{
#include <stdbool.h>
#include <stdint.h>
#include <string.h>

#include "wasm_y.h"
#include "util.h"
#include "symtab.h"
#include "arch.h"
#include "asm.h"

static keyword_t wasm_keywords [] =
{
  { "a",         A },
  { "b",         B },
  { "c",         C },
  { "f",         F },
  { "m1",        M1 },
  { "m2",        M2 },
  { "p",         P },
  { "s",         S },
  { "y",         Y },

  { "address",   ADDRESS },
  { "bank",       BANK },
  { "binary",    BINARY },
  { "checksum",  CHECKSUM },
  { "clear",     CLEAR },
  { "constant",  CONSTANT },
  { "cr",        CR },
  { "crc",       CRC },
  { "data",      DATA },
  { "decimal",   DECIMAL },
  { "delayed",   DELAYED },
  { "display",   DISPLAY },
  { "down",      DOWN },
  { "dw",        DW },
  { "equ",       EQU },
  { "exchange",  EXCHANGE },
  { "fs?c",      FSC },
  { "go",        GO },
  { "hi",        HI },
  { "home",      HOME },
  { "i'm",       IAM },
  { "if",        IF },
  { "jsb",       JSB },
  { "key",       KEY },
  { "keys",      KEYS },
  { "left",      LEFT },
  { "legal",     LEGAL },
  { "load",      LOAD },
  { "n/c",       NC },
  { "nop",       NOP },
  { "off",       OFF },
  { "org",       ORG },
  { "pick",      PICK },
  { "print",     PRINT },
  { "register",  REGISTER },
  { "registers", REGISTERS },
  { "regs",      REGISTERS },
  { "reset",     RESET },
  { "return",    RETURN },
  { "right",     RIGHT },
  { "rom",       ROM },
  { "rotate",    ROTATE },
  { "select",    SELECT },
  { "sf",        SF },
  { "shift",     SHIFT },
  { "stack",     STACK },
  { "status",    STATUS },
  { "symtab",    SYMTAB },
  { "then",      THEN },
  { "to",        TO },
  { "toggle",    TOGGLE },
  { "twf",       TWF },
  { "woodstock", WOODSTOCK },
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

lglobal		[$]
lfirst		[a-zA-Z0-9]
lmiddle		[a-zA-Z0-9+\-*/.:?=<>'_]
lend		[a-zA-Z0-9+\-*/.=<>_]

lb		\[
rb		\]

%%

{digit}+	{ wasm_lval.integer = atoi (yytext); return INTEGER; }

@{octaldig}+	{ sscanf (yytext+1, "%o", &wasm_lval.integer); return INTEGER; }


{lglobal}*{lfirst}({lmiddle}*{lend})?	{
                          if ((wasm_lval.integer = keyword (yytext, wasm_keywords)))
                            return wasm_lval.integer;
                          wasm_lval.string = newstr (yytext);
                          return IDENT;
			}

{lb}[pP][ ]?{rb}	{ wasm_lval.integer = 0; return FIELDSPEC; }
{lb}[wW][pP]{rb}	{ wasm_lval.integer = 1; return FIELDSPEC; }
{lb}[xX][sS]{rb}	{ wasm_lval.integer = 2; return FIELDSPEC; }
{lb}[xX][ ]?{rb}	{ wasm_lval.integer = 3; return FIELDSPEC; }
{lb}[sS][ ]?{rb}	{ wasm_lval.integer = 4; return FIELDSPEC; }
{lb}[mM][ ]?{rb}	{ wasm_lval.integer = 5; return FIELDSPEC; }
{lb}[wW][ ]?{rb}	{ wasm_lval.integer = 6; return FIELDSPEC; }
{lb}[mM][sS]{rb}	{ wasm_lval.integer = 7; return FIELDSPEC; }

\>=		{ return GE; }
-\>		{ return ARROW; }
\<-		{ return LARROW; }

\;.*		;
[ \t]+		;
\n		;

.		{ return yytext [0]; }

%%
