/*
wasm.l: lexical analyzer specification
$Id$
Copyright 1995, 2003, 2004 Eric L. Smith <eric@brouhaha.com>

wasm is an assembler for the HP "Woodstock" processor architecture as
used in the second and third generation HP calculators:
  Woodstock:  HP-21, HP-22, HP-25, HP-25C, HP-27, HP-29C
  Topcat: HP-91, HP-92, HP-95C (unreleased), HP-97, HP-97S
  Hawkeye:  HP-67
  Sting:  HP-10, HP-19C
  Spice:  HP-31E, HP-32E, HP-33E, HP-37E, HP-38E, HP-33C, HP-34C, HP-38C

wasm is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License version 2 as published by the Free
Software Foundation.  Note that I am not granting permission to redistribute
or modify CASM under the terms of any later version of the General Public
License.

This program is distributed in the hope that it will be useful (or at least
amusing), but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with
this program (in the file "COPYING"); if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

/*
 * NOTE:
 * Labels are allowed to contain colons but not to end with a colon.  The HP
 * assembler allows a label, colon, and mnemonic with no intervening white spaces.
 * Due to the greedy nature of token matching, wasm does not permit this; a label
 * and colon must be followed by whitespace.
 */


%{
#include <string.h>
#include "wasmy.tab.h"
#include "util.h"
#include "symtab.h"
#include "asm.h"


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
#if 0
    fprintf (stderr, "yy_input: '%s', %d\n", lineptr, r); \

#endif
%}

octaldig	[0-7]
digit		[0-9]

lglobal		[$]
lfirst		[a-zA-Z0-9]
lmiddle		[a-zA-Z0-9+\-*/.:?=<>']
lend		[a-zA-Z0-9+\-*/.?=<>]

lb		\[
rb		\]
%%
{digit}+	{ yylval.integer = atoi (yytext); return INTEGER; }

@{octaldig}+	{ sscanf (yytext+1, "%o", &yylval.integer); return INTEGER; }


{lglobal}?{lfirst}({lmiddle}*{lend})?	{
                          if ((yylval.integer = keyword (yytext)))
                            return yylval.integer;
                          yylval.string = newstr (yytext);
                          return IDENT;
			}

{lb}[pP][ ]?{rb}	{ yylval.integer = 0; return FIELDSPEC; }
{lb}[wW][pP]{rb}	{ yylval.integer = 1; return FIELDSPEC; }
{lb}[xX][sS]{rb}	{ yylval.integer = 2; return FIELDSPEC; }
{lb}[xX][ ]?{rb}	{ yylval.integer = 3; return FIELDSPEC; }
{lb}[sS][ ]?{rb}	{ yylval.integer = 4; return FIELDSPEC; }
{lb}[mM][ ]?{rb}	{ yylval.integer = 5; return FIELDSPEC; }
{lb}[wW][ ]?{rb}	{ yylval.integer = 6; return FIELDSPEC; }
{lb}[mM][sS]{rb}	{ yylval.integer = 7; return FIELDSPEC; }

\>=		{ return GE; }
-\>		{ return ARROW; }

\;.*		;
[ \t]+		;
\n		;
.		{ return yytext [0]; }

%%

keyword_t keywords [] =
{
  { "a",         A },
  { "b",         B },
  { "c",         C },
  { "f",         F },
  { "m1",        M1 },
  { "m2",        M2 },
  { "p",         P },
  { "y",         Y },

  { "address",   ADDRESS },
  { "binary",    BINARY },
  { "clear",     CLEAR },
  { "constant",  CONSTANT },
  { "data",      DATA },
  { "decimal",   DECIMAL },
  { "delayed",   DELAYED },
  { "display",   DISPLAY },
  { "down",      DOWN },
  { "exchange",  EXCHANGE },
  { "go",        GO },
  { "hi",        HI },
  { "i'm",       IAM },
  { "if",        IF },
  { "jsb",       JSB },
  { "keys",      KEYS },
  { "left",      LEFT },
  { "load",      LOAD },
  { "n/c",       NC },
  { "nop",       NOP },
  { "off",       OFF },
  { "register",  REGISTER },
  { "regs",      REGISTERS },
  { "reset",     RESET },
  { "return",    RETURN },
  { "right",     RIGHT },
  { "rom",       ROM },
  { "rotate",    ROTATE },
  { "select",    SELECT },
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
