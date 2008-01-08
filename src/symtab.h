/*
$Id$
Copyright 1995, 2004, 2008 Eric L. Smith <eric@brouhaha.com>

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

typedef struct symtab_t symtab_t;

/* create a symbol table, returns handle to be passed in to all other calls */
symtab_t *alloc_symbol_table (void);

/* free a symbol table */
void free_symbol_table (symtab_t *table);

/* returns true for success, false if duplicate name */
bool create_symbol (symtab_t *table, char *name, int value, int lineno);

/* returns true for success, false if not found */
bool lookup_symbol (symtab_t *table, char *name, int *value);

typedef void value_fmt_fn_t (int value, char *buf, int buf_len);

void print_symbol_table (symtab_t *table, FILE *f, value_fmt_fn_t *value_fmt_fn);
