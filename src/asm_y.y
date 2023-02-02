/*
Copyright 1995, 2006, 2008, 2022 Eric Smith <spacewar@gmail.com>
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

%define api.prefix {asm_}

%{
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

#include "symtab.h"
#include "arch.h"
#include "util.h"
#include "asm.h"
#include "asm_cond.h"

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
