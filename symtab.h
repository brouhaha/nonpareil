/*
symtab.h: a simple binary tree symbol table

CASM is an assembler for the processor used in the HP "Classic" series
of calculators, which includes the HP-35, HP-45, HP-55, HP-65, HP-70,
and HP-80.

Copyright 1995 Eric L. Smith

CASM is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License version 2 as published by the Free
Software Foundation.  Note that I am not granting permission to redistribute
or modify CASM under the terms of any later version of the General Public
License.
*/

void init_symbol_table (void);

/* returns 1 for success, 0 if duplicate name */
int create_symbol (char *name, int value, int lineno);

/* returns 1 for success, 0 if not found */
int lookup_symbol (char *name, int *value);

void print_symbol_table (FILE *f);
