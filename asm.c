/*
casm.c
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

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "symtab.h"
#include "util.h"
#include "asm.h"


int pass;
int lineno;
int errors;
int warnings;

int group;	/* current rom group */
int rom;	/* current rom */
int pc;		/* current pc */

int dsr;	/* delayed select rom */
int dsg;	/* delayed select group */

char flag_char;

int objflag;	/* used to remember args to emit() */
int objcode;

int symtab_flag;

int last_instruction_type;


int targflag;	/* used to remember args to target() */
int targgroup;
int targrom;
int targpc;

char linebuf [MAX_LINE];
char *lineptr;

#define MAX_ERRBUF 2048
char errbuf [MAX_ERRBUF];
char *errptr;

#define SRC_TAB 32
char listbuf [MAX_LINE];
char *listptr;

#ifndef PATH_MAX
#define PATH_MAX 256
#endif

char srcfn  [PATH_MAX];
char objfn  [PATH_MAX];
char listfn [PATH_MAX];

FILE *srcfile  = NULL;
FILE *objfile  = NULL;
FILE *listfile = NULL;

t_symtab symtab [MAXGROUP] [MAXROM];  /* separate symbol tables for each ROM */


void usage (FILE *f)
{
  fprintf (f, "usage: %s objectfile\n", progname);
}


void format_listing (void)
{
  int i;
	
  sprintf (listptr, "%4d   ", lineno);
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
	  
  sprintf (listptr, "  %c%c%c%c%c    ", flag_char, flag_char, flag_char,
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
  warnings = 0;
  pc = 0;
  dsr = rom;
  dsg = group;
  last_instruction_type = OTHER_INST;

  printf ("Pass %d rom", pass);

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

      errptr = & errbuf [0];
      errbuf [0] = '\0';

      objflag = 0;
      targflag = 0;
      flag_char = ' ';
      symtab_flag = 0;

      yyparse ();

      if (pass == 2)
	{
	  if (symtab_flag)
	    print_symbol_table (symtab [group] [rom], listfile);
	  else
	    {
	      format_listing ();
	      fprintf (listfile, "%s\n", listbuf);
	      if (errptr != & errbuf [0])
		{
		  fprintf (stderr, "%s\n", listbuf);
		  fprintf (listfile, "%s", errbuf);
		  fprintf (stderr, "%s",   errbuf);
		}
	    }
	}

      if (objflag)
	pc = (pc + 1) & 0xff;
    }

  printf ("\n");
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
  progname = argv [0];

  if (argc != 2)
    {
      fprintf (stderr, "Usage: %s sourcefile\n", progname);
      exit (1);
    }

  for (group = 0; group < MAXGROUP; group++)
    for (rom = 0; rom < MAXROM; rom++)
      {
	symtab [group] [rom] = alloc_symbol_table ();
	if (! symtab [group] [rom])
	  fatal (2, "symbol table allocation failed\n");
      }

  strcpy (srcfn, argv [1]);

  srcfile = fopen (srcfn, "r");

  if (! srcfile)
    fatal (2, "can't open input file '%s'\n", srcfn);

  munge_filename (objfn, srcfn, ".obj");
  munge_filename (listfn, srcfn, ".lst");

  objfile = fopen (objfn, "w");

  if (! objfile)
    fatal (2, "can't open input file '%s'\n", objfn);

  listfile = fopen (listfn, "w");

  if (! listfile)
    fatal (2, "can't open listing file '%s'\n", listfn);

  rom = 0;
  group = 0;

  do_pass (1);

  rewind (srcfile);

  do_pass (2);

  err_printf ("%d errors, %d warnings\n", errors, warnings);

  fclose (srcfile);
  fclose (objfile);
  fclose (listfile);
  exit (0);
}

void yyerror (char *s)
{
  error ("%s\n", s);
}

void do_label (char *s)
{
  int prev_val;

  if (pass == 1)
    {
      if (! create_symbol (symtab [group] [rom], s, pc, lineno))
	error ("multiply defined symbol '%s'\n", s);
    }
  else if (! lookup_symbol (symtab [group] [rom], s, & prev_val))
    error ("undefined symbol '%s'\n", s);
  else if (prev_val != pc)
    error ("phase error for symbol '%s'\n", s);
}

static void emit_core (int op, int inst_type)
{
  objcode = op;
  objflag = 1;
  last_instruction_type = inst_type;

  if ((pass == 2) && objfile)
    fprintf (objfile, "%1o%1o%03o:%03x\n", group, rom, pc, op);
}

void emit (int op)
{
  emit_core (op, OTHER_INST);
}

void emit_arith (int op)
{
  emit_core (op, ARITH_INST);
}

void emit_test (int op)
{
  emit_core (op, TEST_INST);
}

void target (int g, int r, int p)
{
  targflag = 1;
  targgroup = g;
  targrom = r;
  targpc = p;
}

int range (int val, int min, int max)
{
  if ((val < min) || (val > max))
    {
      error ("value out of range [%d to %d], using %d", min, max, min);
      return min;
    }
  return val;
}


/*
 * print to both listing error buffer and standard error
 *
 * Use this for general messages.  Don't use this for warnings or errors
 * generated by a particular line of the source file.  Use error() or
 * warning() for that.
 */
int err_vprintf (char *format, va_list ap)
{
  int res;

  if (listfile)
    vfprintf (listfile, format, ap);
  res = vfprintf (stderr, format, ap);
  return (res);
}

int err_printf (char *format, ...)
{
  int res;
  va_list ap;

  va_start (ap, format);
  res = err_vprintf (format, ap);
  va_end (ap);
  return (res);
}


/* generate error or warning messages and increment appropriate counter */
/* actually just puts the message into the error buffer */
int error   (char *format, ...)
{
  int res;
  va_list ap;

  err_printf ("error in file %s line %d: ", srcfn, lineno);
  va_start (ap, format);
  res = err_vprintf (format, ap);
  va_end (ap);
  errptr += res;
  errors ++;
  return (res);
}

int warning (char *format, ...)
{
  int res;
  va_list ap;

  err_printf ("warning in file %s line %d: ", srcfn, lineno);
  va_start (ap, format);
  res = err_vprintf (format, ap);
  va_end (ap);
  errptr += res;
  warnings ++;
  return (res);
}


int keyword (char *string)
{
  struct keyword *ptr;

  for (ptr = keywords; ptr->name; ptr++)
    if (strcasecmp (string, ptr->name) == 0)
      return ptr->value;
  return 0;
}


int yywrap (void)
{
  return (1);
}
