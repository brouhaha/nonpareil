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

void do_pass (int p, FILE *srcf, FILE *listf)
{
  pass = p;
  lineno = 0;
  errors = 0;
  pc = 0;
  dsr = rom;
  dsg = group;

  fprintf (stderr, "Starting pass %d\n", pass);

  while (fgets (linebuf, MAX_LINE, srcf))
    {
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
	  sprintf (listptr, "%3d   ", lineno);
	  listptr += strlen (listptr);

	  if (objflag)
	    {
	      int i;
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
	  /* listptr += strlen (listpr); */
	  fprintf (listf, "%s", listbuf);
	}

      if (objflag)
	pc = (pc + 1) & 0xff;
    }
}

int main (int argc, char *argv[])
{
  char *infile;
  FILE *in;

  progname = argv [0];

  if (argc != 2)
    {
      fprintf (stderr, "Usage: %s sourcefile\n", progname);
      exit (1);
    }

  infile = argv [1];

  in = fopen (infile, "r");

  if (! in)
    {
      fprintf (stderr, "can't open input file '%s'\n", infile);
      exit (2);
    }

  rom = 0;
  group = 0;

  do_pass (1, in, stdout);

  rewind (in);

  do_pass (2, in, stdout);

  print_symbol_table (stdout);

  fprintf (stderr, "%d errors\n", errors);
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

