/*
asm.y: grammar
$Id$
Copyright 1995 Eric L. Smith

Nonpareil is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License version 2 as
published by the Free Software Foundation.  Note that I am not
granting permission to redistribute or modify CASM under the terms of
any later version of the General Public License.

This program is distributed in the hope that it will be useful (or at least
amusing), but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with
this program (in the file "COPYING"); if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

%name-prefix="asm_"

%{
#include <stdio.h>

#include "symtab.h"
#include "arch.h"
#include "asm.h"

void asm_error (char *s);
%}

%union {
    int integer;
    char *string;
  }

%token <string> IDENT

%token ARCH

%%

line		: pseudo_op
		|	
		| error
		;

pseudo_op	: ps_arch
		;

ps_arch		: '.' ARCH IDENT
		  {
		    int a = find_arch_by_name ($3);
		    if (a == ARCH_UNKNOWN)
		      error ("unrecognized architecture '%s'\n", $3);
		    else
		      arch = a;
		  }
		;

%%

void asm_error (char *s)
{
  error ("%s\n", s);
}
