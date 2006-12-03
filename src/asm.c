/*
$Id$
Copyright 1995, 2004, 2005, 2006 Eric L. Smith <eric@brouhaha.com>

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

#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "symtab.h"
#include "util.h"
#include "arch.h"
#include "asm.h"


int arch;


void usage (FILE *f)
{
  fprintf (f, "uasm microassembler - %s\n", nonpareil_release);
  fprintf (f, "Copyright 1995, 2003, 2004 Eric L. Smith\n");
  fprintf (f, "http://nonpareil.brouhaha.com/\n");
  fprintf (f, "\n");
  fprintf (f, "usage: %s [options...] sourcefile\n", progname);
  fprintf (f, "options:\n");
  fprintf (f, "   -o objfile\n");
  fprintf (f, "   -l listfile\n");
}


parser_t *parser [ARCH_MAX] =
  {
    [ARCH_UNKNOWN]   = asm_parse,
    [ARCH_CLASSIC]   = casm_parse,
    [ARCH_WOODSTOCK] = wasm_parse
  };


typedef void (write_obj_t)(FILE *f, int opcode);

static write_obj_t *write_obj [ARCH_MAX];


int pass;
int lineno;
int errors;
int warnings;

addr_t pc;		/* current pc */

// for "delayed select rom" and "delayed select group":
addr_t delayed_pc_mask [2];
addr_t delayed_pc_bits [2];

char flag_char;

bool obj_flag;	/* used to remember args to emit() */
int objcode;

bool symtab_pseudoop_flag;  // set by parser for .symtab directive

bool legal_flag;	// used to suppress warnings for unconditional
			// branches after arithmetic instructions

bool local_label_flag;  // true if ROM-local labels are in use
int local_label_current_rom;

int last_instruction_type;


bool target_flag;	/* used to remember args to target() */
addr_t target_addr;

char linebuf [MAX_LINE];
char *lineptr;

#define MAX_ERRBUF 2048
char errbuf [MAX_ERRBUF];
char *errptr;

#define SRC_TAB 32
char listbuf [MAX_LINE];
char *listptr;


char *src_fn = NULL;

FILE *srcfile  = NULL;
FILE *objfile  = NULL;
FILE *listfile = NULL;


symtab_t *global_symtab;
symtab_t *symtab [MAXROM];  /* separate symbol tables for each '.rom' directive */


void increment_pc (void)
{
  pc = (pc + 1) & 07777;
}


void value_fmt_fn_classic (int value, char *buf, int buf_len)
{
  snprintf (buf, buf_len, "%01o%01o%03o", (value >> 11) & 01,
	                                  (value >> 8) & 07,
	                                  value & 0377);
}


static value_fmt_fn_t *value_fmt_fn [ARCH_MAX] =
{
  [ARCH_UNKNOWN]   = NULL,
  [ARCH_CLASSIC]   = value_fmt_fn_classic,
  [ARCH_WOODSTOCK] = NULL  // default OK
};


void format_listing_unknown (void)
{
  listptr += sprintf (listptr, "%4d   ", lineno);
  listptr += sprintf (listptr, "             ");
  strcat (listptr, linebuf);
  listptr += strlen (listptr);
}

void format_listing_classic (void)
{
  int i;

  listptr += sprintf (listptr, "%4d   ", lineno);

  if (obj_flag)
    {
      listptr += sprintf (listptr, "L%1o%1o%03o:  ",
			  pc >> 11,
			  (pc >> 8) & 7,
			  pc & 0377);
      for (i = 0x200; i; i >>= 1)
	*listptr++ = (objcode & i) ? '1' : '.';
      *listptr = '\0';
    }
  else
    listptr += sprintf (listptr, "                   ");

  if (target_flag)
    listptr += sprintf (listptr, "  -> L%1o%1o%03o",
			(target_addr >> 11),
			(target_addr >> 8) & 3,
			target_addr & 0377);
  else
    listptr += sprintf (listptr, "           ");
  
  listptr += sprintf (listptr, "  %c%c%c%c%c    ", flag_char, flag_char,
		      flag_char, flag_char, flag_char);
  
  strcat (listptr, linebuf);
  listptr += strlen (listptr);
}

void format_listing_woodstock (void)
{
  listptr += sprintf (listptr, "%4d   ", lineno);

  if (obj_flag)
    listptr += sprintf (listptr, "%06o  %04o ", objcode, pc);
  else
    listptr += sprintf (listptr, "             ");
  
  strcat (listptr, linebuf);
  listptr += strlen (listptr);
}

typedef void (format_listing_t) (void);

static format_listing_t *format_listing [ARCH_MAX] =
{
  [ARCH_UNKNOWN]   = format_listing_unknown,
  [ARCH_CLASSIC]   = format_listing_classic,
  [ARCH_WOODSTOCK] = format_listing_woodstock
};

void do_pass (int p)
{
  int i;

  arch = ARCH_UNKNOWN;
  
  pass = p;
  lineno = 0;
  errors = 0;
  warnings = 0;
  pc = 0;
  delayed_pc_mask [0] = 0;

  last_instruction_type = OTHER_INST;
  legal_flag = false;
  local_label_flag = false;

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

      obj_flag = false;
      target_flag = false;
      flag_char = ' ';

      symtab_pseudoop_flag = false;

      delayed_pc_mask [1] = delayed_pc_mask [0];
      delayed_pc_bits [1] = delayed_pc_bits [0];
      delayed_pc_mask [0] = 0;

      parser [arch] ();

      if (pass == 2)
	{
	  if (symtab_pseudoop_flag)
	    {
	      if (listfile && local_label_flag)
		print_symbol_table (symtab [local_label_current_rom],
				    listfile,
				    value_fmt_fn [arch]);
	    }
	  else
	    {
	      format_listing [arch] ();
	      if (listfile)
		fprintf (listfile, "%s\n", listbuf);
	      if (errptr != & errbuf [0])
		{
		  fprintf (stderr, "%s\n", listbuf);
		  if (listfile)
		    fprintf (listfile, "%s", errbuf);
		  fprintf (stderr, "%s",   errbuf);
		}
	    }
	}

      if (obj_flag)
	increment_pc ();
    }

  if ((pass == 2) && listfile)
    {
      fprintf (listfile, "\nGlobal symbols:\n\n");
      print_symbol_table (global_symtab,
			  listfile,
			  value_fmt_fn [arch]);
      fprintf (listfile, "\n");
    }

  printf ("\n");
}


int main (int argc, char *argv[])
{
  char *obj_fn = NULL;
  char *list_fn = NULL;
  int rom;

  progname = argv [0];

  while (--argc)
    {
      argv++;
      if (*argv [0] == '-')
	{
	  if (strcmp (argv [0], "-o") == 0)
	    {
	      if (argc < 2)
		fatal (1, "'-o' must be followed by object filename\n");
	      obj_fn = argv [1];
	      argc--;
	      argv++;
	    }
	  else if (strcmp (argv [0], "-l") == 0)
	    {
	      if (argc < 2)
		fatal (1, "'-l' must be followed by listing filename\n");
	      list_fn = argv [1];
	      argc--;
	      argv++;
	    }
	  else
	    fatal (1, "unrecognized option '%s'\n", argv [0]);
	}
      else if (src_fn)
	fatal (1, "only one source file may be specified\n");
      else
	src_fn = argv [0];
    }

  if (! src_fn)
    fatal (1, "source file must be specified\n");

  global_symtab = alloc_symbol_table ();
  if (! global_symtab)
    fatal (2, "symbol table allocation failed\n");

  for (rom = 0; rom < MAXROM; rom++)
    {
      symtab [rom] = alloc_symbol_table ();
      if (! symtab [rom])
	fatal (2, "symbol table allocation failed\n");
    }

  srcfile = fopen (src_fn, "r");

  if (! srcfile)
    fatal (2, "can't open input file '%s'\n", src_fn);

  if (obj_fn)
    {
      objfile = fopen (obj_fn, "w");
      if (! objfile)
	fatal (2, "can't open input file '%s'\n", obj_fn);
    }

  if (list_fn)
    {
      listfile = fopen (list_fn, "w");
      if (! listfile)
	fatal (2, "can't open listing file '%s'\n", list_fn);
    }

  do_pass (1);

  rewind (srcfile);

  do_pass (2);

  err_printf ("%d errors, %d warnings\n", errors, warnings);

  fclose (srcfile);
  if (objfile)
    fclose (objfile);
  if (listfile)
    fclose (listfile);
  exit (0);
}


void do_label (char *s)
{
  int prev_val;
  symtab_t *table;

  if (local_label_flag && (*s != '$'))
    table = symtab [local_label_current_rom];
  else
    table = global_symtab;

  if (pass == 1)
    {
      if (! create_symbol (table, s, pc, lineno))
	error ("multiply defined symbol '%s'\n", s);
    }
  else if (! lookup_symbol (table, s, & prev_val))
    error ("undefined symbol '%s'\n", s);
  else if (prev_val != pc)
    error ("phase error for symbol '%s'\n", s);
}


static void write_obj_classic (FILE *f, int opcode)
{
  fprintf (f, "%04o:%04o\n", pc, opcode &01777);
}


static void write_obj_woodstock (FILE *f, int opcode)
{
  fprintf (f, "%04o:%04o\n", pc, opcode &01777);
}


static write_obj_t *write_obj [ARCH_MAX] =
  {
    [ARCH_CLASSIC]   = write_obj_classic,
    [ARCH_WOODSTOCK] = write_obj_woodstock
  };


static void emit_core (int op, int inst_type)
{
  objcode = op;
  obj_flag = true;
  last_instruction_type = inst_type;

  if ((pass == 2) && objfile)
    write_obj [arch] (objfile, op);
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

void target (addr_t addr)
{
  target_flag = true;
  target_addr = addr;
}

void delayed_select (addr_t mask, addr_t bits)
{
  delayed_pc_mask [0] = mask;
  delayed_pc_bits [0] = bits;
}

addr_t get_next_pc (void)
{
  addr_t next_pc;

  next_pc = pc + 1;
  next_pc &= ~ delayed_pc_mask [1];
  next_pc |= (delayed_pc_mask [1] & delayed_pc_bits [1]);

  return next_pc;
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
 * print to both listing file and standard error
 *
 * Use this for general messages.  Don't use this for warnings or errors
 * generated by a particular line of the source file.  Use error() or
 * warning() for that.
 */
int err_vprintf (char *format, va_list ap)
{
  int res;

  if (listfile && (pass == 2))
    {
      va_list ap_copy;

      va_copy (ap_copy, ap);
      vfprintf (listfile, format, ap_copy);
      va_end (ap_copy);
    }
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
int error   (char *format, ...)
{
  int res;
  va_list ap;

  err_printf ("error in file %s line %d: ", src_fn, lineno);
  va_start (ap, format);
  res = err_vprintf (format, ap);
  va_end (ap);
  errptr += res;
  errors ++;
  return (res);
}

int asm_warning (char *format, ...)
{
  int res;
  va_list ap;

  err_printf ("warning in file %s line %d: ", src_fn, lineno);
  va_start (ap, format);
  res = err_vprintf (format, ap);
  va_end (ap);
  errptr += res;
  warnings ++;
  return (res);
}


int keyword (char *string, keyword_t *table)
{
  while (table->name)
    {
      if (strcasecmp (string, table->name) == 0)
	return table->value;
      table++;
    }
  return 0;
}


