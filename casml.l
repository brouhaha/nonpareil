/*
 * casm.l: lexical analyzer specification
 *
 * CASM is an assembler for the processor used in the HP "Classic" series
 * of calculators, which includes the HP-35, HP-45, HP-55, HP-65, HP-70,
 * and HP-80.
 *
 * Copyright 1995 Eric Smith
 */

%{
#include "y.tab.h"
#include "casm.h"

#define ALLOC(x,s,t) do { x = (t) malloc (s); \
                          if (! x) { fprintf (stderr, "memory allocation failed\n");\
                                     exit (2); }} while (0)
#define BCOPY(from,to,size) memcpy(to,from,size)
#define NEWSTR(from,to) do { int len = strlen (from);\
                             ALLOC(to, len+1, char *);\
                             BCOPY(from, to, len+1);\
                           } while (0)
%}

octaldig	[0-7]
digit		[0-9]
alpha		[a-zA-Z]
alphanum	[a-zA-Z0-9]
comment		\;.*$
lb		\[
rb		\]
%%
{digit}+	{ yylval.integer = atoi (yytext); return INTEGER; }

@{octaldig}+	{ scanf (yytext+1, "%o", &yylval.integer); return INTEGER; }

[sS][1-9]		{ yylval.integer = atoi (yytext+1); return STATBIT; }
[sS]1[0-2]		{ yylval.integer = atoi (yytext+1); return STATBIT; }

{alpha}{alphanum}*	{
                          if (yylval.integer = keyword (yytext))
                            return yylval.integer;
/*
                          if ((yytext [0] == 's') || (yytext [0] == 'S'))
                            {
                              if (
                            }
*/
                          NEWSTR(yytext, yylval.string);
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

\;.*$		;
[ \t]+		;
\n		{ return '\n'; }
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
  "carry",     CARRY,
  "clear",     CLEAR,
  "constant",  CONSTANT,
  "data",      DATA,
  "delayed",   DELAYED,
  "display",   DISPLAY,
  "down",      DOWN,
  "exchange",  EXCHANGE,
  "go",        GO,
  "group",     GROUP,
  "if",        IF,
  "jsb",       JSB,
  "keys",      KEYS,
  "left",      LEFT,
  "load",      LOAD,
  "no",        NO,
  "off",       OFF,
  "operation", OPERATION,
  "registers", REGISTERS,
  "return",    RETURN,
  "right",     RIGHT,
  "rom",       ROM,
  "rotate",    ROTATE,
  "select",    SELECT,
  "shift",     SHIFT,
  "stack",     STACK,
  "status",    STATUS,
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
