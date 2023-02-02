/*
Copyright 1995-2023 Eric Smith <spacewar@gmail.com>
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

#ifndef SYMTAB_H
#define SYMTAB_H

#include <stdio.h>

typedef struct symtab_t symtab_t;

/* create a symbol table, returns handle to be passed in to all other calls */
symtab_t *alloc_symbol_table (void);

/* free a symbol table */
void free_symbol_table (symtab_t *table);

/* returns true for success, false if duplicate name */
bool create_symbol (symtab_t *table, char *name, int value, int lineno);

/* returns true for success, false if not found */
bool lookup_symbol (symtab_t *table, char *name, int *value, int lineno);

typedef void value_fmt_fn_t (int value, char *buf, int buf_len);

void print_symbol_table (symtab_t *table, FILE *f, value_fmt_fn_t *value_fmt_fn);

#endif // SYMTAB_H
