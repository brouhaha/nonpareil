/*
symtab.h: a simple binary tree symbol table
$Id: symtab.h,v 1.7 2003/05/30 23:38:12 eric Exp $
Copyright 1995 Eric L. Smith

CASM is an assembler for the processor used in the HP "Classic" series
of calculators, which includes the HP-35, HP-45, HP-55, HP-65, HP-70,
and HP-80.

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
*/

typedef void * t_symtab;

/* create a symbol table, returns handle to be passed in to all other calls */
t_symtab alloc_symbol_table (void);

/* free a symbol table */
void free_symbol_table (t_symtab t);

/* returns 1 for success, 0 if duplicate name */
int create_symbol (t_symtab t, char *name, int value, int lineno);

/* returns 1 for success, 0 if not found */
int lookup_symbol (t_symtab t, char *name, int *value);

void print_symbol_table (t_symtab t, FILE *f);
