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

%define api.prefix {asm_cond_}

%{
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

#include "symtab.h"
#include "arch.h"
#include "asm.h"
#include "asm_cond.h"

void asm_cond_error (char *s);
%}

%union {
    int integer;
    char *string;
  }

%token <integer> INTEGER
%token <string> IDENT

%token LSH_OP RSH_OP
%token LE_OP GE_OP EQ_OP NE_OP

%token ELSE
%token ELSEIF
%token ENDIF
%token IF
%token IFDEF
%token IFNDEF

%type <integer> factor
%type <integer> mult_expr
%type <integer> add_expr
%type <integer> shift_expr
%type <integer> relational_expr
%type <integer> equality_expr
%type <integer> and_expr
%type <integer> excl_or_expr
%type <integer> incl_or_expr
%type <integer> expr

%%

line		: '.' cond_pseudo_op
		|	
		| error
		;

cond_pseudo_op	: ps_if
		| ps_endif
		| ps_ifdef
		| ps_ifndef
		| ps_else
		| ps_elseif
		;

ps_if		: IF expr { pseudo_if ($2); };

ps_ifdef	: IFDEF IDENT { pseudo_ifdef ($2); };

ps_ifndef	: IFNDEF IDENT { pseudo_ifndef ($2); };

ps_else		: ELSE { pseudo_else (); };

ps_elseif       : ELSEIF expr { pseudo_elseif ($2); };

ps_endif	: ENDIF { pseudo_endif (); };

factor		: '(' expr ')'  { $$ = $2; }
		| INTEGER { $$ = $1; }
		| IDENT { symtab_t *table;
			  if (local_label_flag && ($1 [0] != '$'))
			    table = symtab [local_label_current_rom];
			  else
			    table = global_symtab;
			  int value;
			  if (lookup_symbol (table, $1, &value, get_lineno ()))
			    {
			      $$ = value;
			    }
			  else
			    {
			      if (pass != PASS_INITIAL)
				error ("undefined symbol '%s'\n", $1);
			      $$ = 0;
			    }
			}
		;

mult_expr       : factor               { $$ = $1; }
                | mult_expr '*' factor { $$ = $1 * $3; }
                | mult_expr '/' factor { $$ = $1 / $3; }
                | mult_expr '%' factor { $$ = $1 % $3; }
                ;

add_expr        : mult_expr              { $$ = $1; }
                | add_expr '+' mult_expr { $$ = $1 + $3; }
                | add_expr '-' mult_expr { $$ = $1 - $3; }
                ;

shift_expr      : add_expr                   { $$ = $1; }
                | shift_expr LSH_OP add_expr { $$ = $1 << $3; }
                | shift_expr RSH_OP add_expr { $$ = $1 >> $3; }
                ;

relational_expr : shift_expr                       { $$ = $1; }
                | relational_expr '<' shift_expr   { $$ = $1 < $3; }
                | relational_expr '>' shift_expr   { $$ = $1 > $3; }
                | relational_expr LE_OP shift_expr { $$ = $1 <= $3; }
                | relational_expr GE_OP shift_expr { $$ = $1 >= $3; }
                ;


equality_expr   : relational_expr                     { $$ = $1; }
                | equality_expr EQ_OP relational_expr { $$ = $1 == $3; }
                | equality_expr NE_OP relational_expr { $$ = $1 != $3; }
                ;

and_expr        : equality_expr              { $$ = $1; }
                | and_expr '&' equality_expr { $$ = $1 & $3; }

excl_or_expr    : and_expr                  { $$ = $1; }
                | excl_or_expr '^' and_expr { $$ = $1 ^ $3; }
                ;

incl_or_expr    : excl_or_expr                  { $$ = $1; }
                | incl_or_expr '|' excl_or_expr { $$ = $1 | $3; }
                ;

expr            : incl_or_expr          { $$ = $1; }
                ;

%%

void asm_cond_error (char *s)
{
  parse_error = true;
}
