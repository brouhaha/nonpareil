/*
 * symtab.h
 *
 * CASM is an assembler for the processor used in the HP "Classic" series
 * of calculators, which includes the HP-35, HP-45, HP-55, HP-65, HP-70,
 * and HP-80.
 *
 * Copyright 1995 Eric Smith
 */

#include <stdio.h>
#include "symtab.h"

typedef struct sym
{
  char *name;
  int value;
  int lineno;
  struct sym *left;
  struct sym *right;
} sym;

sym *table = NULL;

void init_symbol_table (void)
{
}

int insert_symbol (sym **p, sym *newsym)
{
  int i;

  printf ("insert %s=%d\n", newsym->name, newsym->value);
  if (! *p)
    {
      (*p) = newsym;
      return (1);
    }

  printf ("comparing %s %s\n", (*p)->name, newsym->name);
  i = stricmp ((*p)->name, newsym->name);

  if (i == 0)
    return (0);
  else if (i < 0)
    return (insert_symbol (& ((*p)->left), newsym));
  else
    return (insert_symbol (& ((*p)->right), newsym));
}


/* returns 1 for success, 0 if duplicate name */
int create_symbol (char *name, int value, int lineno)
{
  sym *p = table;
  sym *newsym;

  newsym = (sym *) calloc (1, sizeof (sym));
  if (! newsym)
    {
      fprintf (stderr, "memory allocation failure\n");
      exit (2);
    }

  newsym->name = (char *) malloc (strlen (name));
  if (! newsym->name)
    {
      fprintf (stderr, "memory allocation failure\n");
      exit (2);
    }
  strcpy (newsym->name, name);
  newsym->value = value;
  newsym->lineno = lineno;

  return (insert_symbol (& table, newsym));
}

/* returns 1 for success, 0 if not found */
int lookup_symbol (char *name, int *value)
{
  *value = 0;
  return 0;
}

void print_symbols (FILE *f, sym *p)
{
  if (! p)
    return;
  print_symbols (f, p->left);
  fprintf (f, "%05o %s %d\n", p->value, p->name, p->lineno);
  print_symbols (f, p->right);
}

void print_symbol_table (FILE *f)
{
  print_symbols (f, table);
}
