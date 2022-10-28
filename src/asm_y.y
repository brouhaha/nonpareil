/*
Copyright 1995, 2006, 2008, 2022 Eric Smith <spacewar@gmail.com>

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

%define api.prefix {asm_}

%{
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

#include "symtab.h"
#include "arch.h"
#include "util.h"
#include "asm.h"

void asm_error (char *s);
%}

%union {
    int integer;
    char *string;
  }

%token ARCH
%token COPYRIGHT
%token INCLUDE
%token LICENSE

%token <string> IDENT
%token <string> STRING

%%

line		: '.' pseudo_op
		|	
		| error
		;

pseudo_op	: ps_arch
		| ps_include
                | ps_copyright
                | ps_license
		;

ps_arch		: ARCH IDENT
		  {
		    int a = find_arch_by_name ($2);
		    if (a == ARCH_UNKNOWN)
		      error ("unrecognized architecture '%s'\n", $2);
		    else
		      arch = a;
		  }
		;

ps_include	: INCLUDE STRING {
                                   if (get_cond_state ())
                                     pseudo_include ($2);
                                 };

ps_copyright    : COPYRIGHT STRING { copyright_string = newstr($2); };

ps_license      : LICENSE STRING { license_string = newstr($2); };

%%

void asm_error (char *s)
{
  parse_error = true;
}
