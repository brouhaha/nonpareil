/*
symtab.c: a simple binary tree symbol table
$Id$
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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "symtab.h"
#include "util.h"


typedef struct sym
{
  char *name;
  int value;
  int lineno;
  struct sym *left;
  struct sym *right;
} sym;


t_symtab alloc_symbol_table (void)
{
  sym **table;
  table = (sym **) calloc (1, sizeof (sym *));
  return (table);
}

static void free_entry (sym *p)
{
  if (p->left)
    free_entry (p->left);
  if (p->right)
    free_entry (p->right);
  free (p);
}

void free_symbol_table (t_symtab t)
{
  sym **table = t;
  free_entry (*table);
  free (table);
}

static int insert_symbol (sym **p, sym *newsym)
{
  int i;

  if (! *p)
    {
      (*p) = newsym;
      return (1);
    }

  i = strcasecmp (newsym->name, (*p)->name);

  if (i == 0)
    return (0);
  else if (i < 0)
    return (insert_symbol (& ((*p)->left), newsym));
  else
    return (insert_symbol (& ((*p)->right), newsym));
}


/* returns 1 for success, 0 if duplicate name */
int create_symbol (t_symtab t, char *name, int value, int lineno)
{
  sym **table = t;
  sym *newsym;

  newsym = (sym *) calloc (1, sizeof (sym));
  if (! newsym)
    {
      fprintf (stderr, "memory allocation failure\n");
      exit (2);
    }

  newsym->name = newstr (name);
  newsym->value = value;
  newsym->lineno = lineno;

  return (insert_symbol (table, newsym));
}

/* returns 1 for success, 0 if not found */
int lookup_symbol (t_symtab t, char *name, int *value)
{
  sym **table = t;
  sym *p = *table;
  int i;

  while (p)
    {
      i = strcasecmp (name, p->name);
      if (i == 0)
	{
	  *value = p->value;
	  return (1);
	}
      if (i < 0)
	p = p->left;
      else
	p = p->right;
    }
  return (0);
}

static void print_symbols (FILE *f, sym *p)
{
  if (! p)
    return;
  print_symbols (f, p->left);
  fprintf (f, "%05o %s %d\n", p->value, p->name, p->lineno);
  print_symbols (f, p->right);
}

void print_symbol_table (t_symtab t, FILE *f)
{
  sym **table = t;
  print_symbols (f, *table);
}
