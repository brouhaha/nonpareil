/*
casm.l: lexical analyzer specification

CASM is an assembler for the processor used in the HP "Classic" series
of calculators, which includes the HP-35, HP-45, HP-55, HP-65, HP-70,
and HP-80.

Copyright 1995, 2003 Eric L. Smith

CASM is free software; you can redistribute it and/or modify it under the
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

$Header: /home/svn/casmsim/casml.l,v 1.12 2003/05/30 02:04:05 eric Exp $
*/

%{
#include "casmy.tab.h"
#include "symtab.h"
#include "casm.h"

#ifdef OLD_FLEX
#undef yywrap
/* Only needed for versions of flex prior to 2.4.1. */
int yywrap (void);
#endif /* OLD_FLEX */

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
alpha		[a-zA-Z]
alphanum	[a-zA-Z0-9_]
lb		\[
rb		\]
%%
{digit}+	{ yylval.integer = atoi (yytext); return INTEGER; }

@{octaldig}+	{ sscanf (yytext+1, "%o", &yylval.integer); return INTEGER; }

[sS][0-9]		{ yylval.integer = atoi (yytext+1); return STATBIT; }
[sS]1[0-1]		{ yylval.integer = atoi (yytext+1); return STATBIT; }

{alpha}{alphanum}*	{
                          if (yylval.integer = keyword (yytext))
                            return yylval.integer;
                          yylval.string = newstr (yytext);
                          return IDENT;
                        }

{lb}[pP]{rb}		{ yylval.integer = 0; return FIELDSPEC; }
{lb}[mM]{rb}		{ yylval.integer = 1; return FIELDSPEC; }
{lb}[xX]{rb}		{ yylval.integer = 2; return FIELDSPEC; }
{lb}[wW]{rb}		{ yylval.integer = 3; return FIELDSPEC; }
{lb}[wW][pP]{rb}	{ yylval.integer = 4; return FIELDSPEC; }
{lb}[mM][sS]{rb}	{ yylval.integer = 5; return FIELDSPEC; }
{lb}[xX][sS]{rb}	{ yylval.integer = 6; return FIELDSPEC; }
{lb}[sS]{rb}		{ yylval.integer = 7; return FIELDSPEC; }

\>=		{ return GE; }
-\>		{ return ARROW; }

\;.*		;
[ \t]+		;
\n		;
.		{ return yytext [0]; }

%%

struct keyword
{
  char *name;
  int value;
}
keywords [] =
{
  "a",         A,
  "b",         B,
  "c",         C,
  "m",         M,
  "p",         P,

  "address",   ADDRESS,
  "advance",   ADVANCE,
  "and",       AND,
  "buffer",    BUFFER,
  "carry",     CARRY,
  "clear",     CLEAR,
  "constant",  CONSTANT,
  "data",      DATA,
  "delayed",   DELAYED,
  "delete",    DELETE,
  "display",   DISPLAY,
  "down",      DOWN,
  "exchange",  EXCHANGE,
  "for",       FOR,
  "go",        GO,
  "group",     GROUP,
  "if",        IF,
  "insert",    INSERT,
  "jsb",       JSB,
  "keys",      KEYS,
  "label",     LABEL,
  "left",      LEFT,
  "load",      LOAD,
  "mark",      MARK,
  "memory",    MEMORY,
  "no",        NO,
  "off",       OFF,
  "operation", OPERATION,
  "pointer",   POINTER,
  "registers", REGISTERS,
  "return",    RETURN,
  "right",     RIGHT,
  "rom",       ROM,
  "rotate",    ROTATE,
  "search",    SEARCH,
  "select",    SELECT,
  "shift",     SHIFT,
  "stack",     STACK,
  "status",    STATUS,
  "symtab",    SYMTAB,
  "then",      THEN,
  "to",        TO,
  "toggle",    TOGGLE,
  NULL,        0,
};

int keyword (char *string)
{
  struct keyword *ptr;

  for (ptr = keywords; ptr->name; ptr++)
    if (stricmp (string, ptr->name) == 0)
      return ptr->value;
  return 0;
}

int yywrap (void)
{
#ifdef OLD_FLEX
/* Only needed for versions of flex prior to 2.4.1. */
  yyrestart (yyin);
#endif /* OLD_FLEX */
  return (1);
}
