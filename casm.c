/*
casm.c

CASM is an assembler for the processor used in the HP "Classic" series
of calculators, which includes the HP-35, HP-45, HP-55, HP-65, HP-70,
and HP-80.

Copyright 1995 Eric L. Smith

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
#include "casm.h"

char *progname;
int pass;
int lineno;
int errors;

int group;	/* current rom group */
int rom;	/* current rom */
int pc;		/* current pc */

int dsr;	/* delayed select rom */
int dsg;	/* delayed select group */

char flag_char;

int objflag;	/* used to remember args to emit() */
int objcode;

int targflag;	/* used to remember args to target() */
int targgroup;
int targrom;
int targpc;

char linebuf [MAX_LINE];
char *lineptr;

#define SRC_TAB 32
char listbuf [MAX_LINE];
char *listptr;

FILE *srcfile;
FILE *objfile;
FILE *listfile;

void format_listing (void)
{
  int i;
	
  sprintf (listptr, "%3d   ", lineno);
  listptr += strlen (listptr);

  if (objflag)
    {
      sprintf (listptr, "L%1o%1o%03o:  ", group, rom, pc);
      listptr += strlen (listptr);
      for (i = 0x200; i; i >>= 1)
	*listptr++ = (objcode & i) ? '1' : '.';
      *listptr = '\0';
    }
  else
    {
      strcat (listptr, "                   ");
      listptr += strlen (listptr);
    }

  if (targflag)
    {
      sprintf (listptr, "  -> L%1o%1o%03o", targgroup, targrom, targpc);
      listptr += strlen (listptr);
    }
  else
    {
      strcat (listptr, "           ");
      listptr += strlen (listptr);
    }
	  
  sprintf (listptr, "  %c%c%c%c%c     ", flag_char, flag_char, flag_char,
	   flag_char, flag_char);
  listptr += strlen (listptr);
  
  strcat (listptr, linebuf);
  listptr += strlen (listptr);
}

void do_pass (int p)
{
  int i;

  pass = p;
  lineno = 0;
  errors = 0;
  pc = 0;
  dsr = rom;
  dsg = group;

  fprintf (stderr, "Starting pass %d\n", pass);

  while (fgets (linebuf, MAX_LINE, srcfile))
    {
      /* remove newline */
      i = strlen (linebuf);
      if (linebuf [i - 1] == '\n')
	linebuf [i - 1] = '\0';

      lineno++;
      lineptr = & linebuf [0];

      listptr = & listbuf [0];
      listbuf [0] = '\0';

      objflag = 0;
      targflag = 0;
      flag_char = ' ';

      yyparse ();

      if (pass == 2)
	{
	  format_listing ();
	  fprintf (listfile, "%s\n", listbuf);
	}

      if (objflag)
	pc = (pc + 1) & 0xff;
    }
}

void munge_filename (char *dst, char *src, char *ext)
{
  int i;
  int lastdot = 0;
  for (i = 0; src [i]; i++)
    {
      if (src [i] == '.')
	lastdot = i;
    }
  if (lastdot == 0)
    lastdot = strlen (src);
  memcpy (dst, src, lastdot);
  dst [lastdot] = '\0';
  strcat (dst, ext);
}

int main (int argc, char *argv[])
{
  char *srcfn;
  char objfn [300];
  char listfn [300];

  progname = argv [0];

  if (argc != 2)
    {
      fprintf (stderr, "Usage: %s sourcefile\n", progname);
      exit (1);
    }

  srcfn = argv [1];

  srcfile = fopen (srcfn, "r");

  if (! srcfile)
    {
      fprintf (stderr, "can't open input file '%s'\n", srcfn);
      exit (2);
    }

  munge_filename (objfn, srcfn, ".obj");
  munge_filename (listfn, srcfn, ".lst");

  objfile = fopen (objfn, "w");

  if (! objfile)
    {
      fprintf (stderr, "can't open input file '%s'\n", objfn);
      exit (2);
    }

  listfile = fopen (listfn, "w");

  if (! listfile)
    {
      fprintf (stderr, "can't open listing file '%s'\n", listfn);
      exit (2);
    }

  rom = 0;
  group = 0;

  do_pass (1);

  rewind (srcfile);

  do_pass (2);

  print_symbol_table (listfile);

  fprintf (stderr, "%d errors\n", errors);

  fclose (srcfile);
  fclose (objfile);
  fclose (listfile);
}

void yyerror (char *s)
{
  fprintf (stderr, "%s: %s", progname, s);
  fprintf (stderr, " line %d\n", lineno);
  errors++;
}

int yywrap (void)
{
  return 1;
}

void do_label (char *s)
{
  int prev_val;

  if (pass == 1)
    {
      if (! create_symbol (s, pc, lineno))
	{
	  fprintf (stdout, "multiply defined symbol '%s' on line %d\n", s, lineno);
	  errors++;
	}
    }
  else if (! lookup_symbol (s, & prev_val))
    {
      fprintf (stdout, "undefined symbol '%s' on line %d\n", s, lineno);
      errors++;
    }
  else if (prev_val != pc)
    {
      fprintf (stdout, "phase error for symbol '%s' on line %d\n", s, lineno);
      errors++;
    }
}

void emit (int op)
{
  objcode = op;
  objflag = 1;

  if ((pass == 2) && objfile)
    fprintf (objfile, "%1o%1o%03o:%03x\n", group, rom, pc, op);
}

void target (int g, int r, int p)
{
  targflag = 1;
  targgroup = g;
  targrom = r;
  targpc = p;
}

void range (int val, int min, int max)
{
  if ((val < min) || (val > max))
    {
      fprintf (stderr, "range error on line %d\n", lineno);
      errors++;
    }
}

char *newstr (char *orig)
{
  int len;
  char *r;

  len = strlen (orig);
  r = (char *) malloc (len + 10);
  
  if (! r)
    {
      fprintf (stderr, "memory allocation failed\n");
      exit (2);
    }

  memcpy (r, orig, len + 1);
  return (r);
}

