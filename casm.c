/*
 * casm.c
 *
 * CASM is an assembler for the processor used in the HP "Classic" series
 * of calculators, which includes the HP-35, HP-45, HP-55, HP-65, HP-70,
 * and HP-80.
 *
 * Copyright 1995 Eric Smith
 */

#include <stdio.h>

char *progname;
int pass;
int lineno;
int errors;
int pc;

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

  in = freopen (infile, "r", stdin);
  if (! in)
    {
      fprintf (stderr, "can't open input file '%s'\n", infile);
      exit (2);
    }

  fprintf (stderr, "Starting pass 1\n");
  pass = 1;
  errors = 0;
  lineno = 1;
  pc = 0;
  yyparse ();

  if (! errors)
    {
      rewind (stdin);

      fprintf (stderr, "Starting pass 2\n");
      pass = 2;
      lineno = 1;
      pc = 0;
      yyrestart (stdin);
      yyparse ();
    }

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
  int i;

  if (pass == 2)
    {
      printf ("L%05o: ", pc);
      for (i = 0x200; i; i >>= 1)
	printf ((op & i) ? "1" : ".");
      printf ("\n");
    }
  pc ++;
}

void endline (void)
{
  lineno ++;
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

