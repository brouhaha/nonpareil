/*
$Id$
Copyright 1995, 2003, 2004, 2008 Eric L. Smith <eric@brouhaha.com>

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

%option prefix="asm_"
%option noyywrap

%{
#include <stdbool.h>
#include <stdint.h>
#include <string.h>

#include "asmy.h"
#include "util.h"
#include "symtab.h"
#include "arch.h"
#include "asm.h"

static keyword_t asm_keywords [] =
{
  { "arch",      ARCH },
  { "include",   INCLUDE },
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

alpha		[a-zA-Z]
alphanum	[a-zA-Z0-9_]

%%

{alpha}{alphanum}*	{
                          if ((asm_lval.integer = keyword (yytext, asm_keywords)))
                            return asm_lval.integer;
                          asm_lval.string = newstr (yytext);
                          return IDENT;
                        }

\"[^\"\n]\"		{
			  asm_lval.string = newstrn (yytext + 1, strlen (yytext) - 1);
			  return STRING;
			}

\;.*		;
[ \t]+		;
\n		;
.		{ return yytext [0]; }

%%
