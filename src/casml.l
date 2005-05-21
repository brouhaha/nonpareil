/*
$Id$
Copyright 1995, 2003, 2004 Eric L. Smith <eric@brouhaha.com>

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

%option prefix="casm_"
%option noyywrap

%{
#include <stdbool.h>
#include <stdint.h>
#include <string.h>

#include "casmy.h"
#include "util.h"
#include "symtab.h"
#include "arch.h"
#include "asm.h"

static keyword_t casm_keywords [] =
{
  { "a",         A },
  { "b",         B },
  { "c",         C },
  { "m",         M },
  { "p",         P },

  { "address",   ADDRESS },
  { "advance",   ADVANCE },
  { "and",       AND },
  { "buffer",    BUFFER },
  { "carry",     CARRY },
  { "clear",     CLEAR },
  { "constant",  CONSTANT },
  { "data",      DATA },
  { "delayed",   DELAYED },
  { "delete",    DELETE },
  { "display",   DISPLAY },
  { "down",      DOWN },
  { "exchange",  EXCHANGE },
  { "for",       FOR },
  { "go",        GO },
  { "group",     GROUP },
  { "if",        IF },
  { "insert",    INSERT },
  { "jsb",       JSB },
  { "keys",      KEYS },
  { "label",     LABEL },
  { "left",      LEFT },
  { "load",      LOAD },
  { "mark",      MARK },
  { "memory",    MEMORY },
  { "no",        NO },
  { "off",       OFF },
  { "operation", OPERATION },
  { "pointer",   POINTER },
  { "registers", REGISTERS },
  { "return",    RETURN },
  { "right",     RIGHT },
  { "rom",       ROM },
  { "rotate",    ROTATE },
  { "search",    SEARCH },
  { "select",    SELECT },
  { "shift",     SHIFT },
  { "stack",     STACK },
  { "status",    STATUS },
  { "symtab",    SYMTAB },
  { "then",      THEN },
  { "to",        TO },
  { "toggle",    TOGGLE },
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
alpha		[a-zA-Z]
alphanum	[a-zA-Z0-9_]
lb		\[
rb		\]
%%
{digit}+	{ casm_lval.integer = atoi (yytext); return INTEGER; }

@{octaldig}+	{ sscanf (yytext+1, "%o", &casm_lval.integer); return INTEGER; }

[sS][0-9]		{ casm_lval.integer = atoi (yytext+1); return STATBIT; }
[sS]1[0-1]		{ casm_lval.integer = atoi (yytext+1); return STATBIT; }

[fF][0-7]		{ casm_lval.integer = atoi (yytext+1); return FLAGBIT; }

{alpha}{alphanum}*	{
                          if ((casm_lval.integer = keyword (yytext, casm_keywords)))
                            return casm_lval.integer;
                          casm_lval.string = newstr (yytext);
                          return IDENT;
                        }

{lb}[pP]{rb}		{ casm_lval.integer = 0; return FIELDSPEC; }
{lb}[mM]{rb}		{ casm_lval.integer = 1; return FIELDSPEC; }
{lb}[xX]{rb}		{ casm_lval.integer = 2; return FIELDSPEC; }
{lb}[wW]{rb}		{ casm_lval.integer = 3; return FIELDSPEC; }
{lb}[wW][pP]{rb}	{ casm_lval.integer = 4; return FIELDSPEC; }
{lb}[mM][sS]{rb}	{ casm_lval.integer = 5; return FIELDSPEC; }
{lb}[xX][sS]{rb}	{ casm_lval.integer = 6; return FIELDSPEC; }
{lb}[sS]{rb}		{ casm_lval.integer = 7; return FIELDSPEC; }

\>=		{ return GE; }
-\>		{ return ARROW; }

\;.*		;
[ \t]+		;
\n		;
.		{ return yytext [0]; }

%%
