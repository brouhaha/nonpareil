/*
$Id$
Copyright 1995, 2008 Eric L. Smith <eric@brouhaha.com>

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

%name-prefix="asm_cond_"

%{
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

#include "symtab.h"
#include "arch.h"
#include "asm.h"

void asm_cond_error (char *s);
%}

%union {
    int integer;
    char *string;
  }

%token ELSE
%token ENDIF
%token IF
%token IFDEF

%token <integer> INTEGER
%token <string> IDENT

%type <integer> expr

%%

line		: '.' cond_pseudo_op
		|	
		| error
		;

cond_pseudo_op	: ps_if
		| ps_endif
		| ps_ifdef
		| ps_else
		;

ps_if		: IF expr { pseudo_if ($2); };

ps_ifdef	: IFDEF IDENT { pseudo_ifdef ($2); };

ps_else		: ELSE { pseudo_else (); };

ps_endif	: ENDIF { pseudo_endif (); };

expr		: INTEGER { $$ = $1; }
		| IDENT {
		          // Note: symbols used in conditionals must be
                          // defined before reference, so that they will
                          // be valid during phase 1.
		          if (! lookup_symbol (global_symtab, $1, &$$, lineno))
		            {
			      error ("undefined symbol '%s'\n", $1);
			      $$ = 0;
			    }
			}
		;

%%

void asm_cond_error (char *s)
{
  parse_error = true;
}
