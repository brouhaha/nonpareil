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

#include <assert.h>
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

static uint16_t pc_mask [ARCH_MAX] =
  {
    [ARCH_UNKNOWN]   = 0,
    [ARCH_CLASSIC]   = (ARCH_CLASSIC_ROM_SIZE_WORDS * ARCH_CLASSIC_MAX_ROM * ARCH_CLASSIC_MAX_GROUP) - 1,
    [ARCH_WOODSTOCK] = 07777,
    [ARCH_NUT]       = 0xffff
  };


void usage (FILE *f)
{
  fprintf (f, "uasm microassembler - %s\n", nonpareil_release);
  fprintf (f, "Copyright 1995-2022 Eric Smith <spacewar@gmail.com>\n");
  fprintf (f, "http://nonpareil.brouhaha.com/\n");
  fprintf (f, "\n");
  fprintf (f, "usage: %s [options...] sourcefile\n", progname);
  fprintf (f, "options:\n");
  fprintf (f, "   -o objfile\n");
  fprintf (f, "   -l listfile\n");
}


parser_t *parser [ARCH_MAX] =
  {
    [ARCH_UNKNOWN]   = NULL,
    [ARCH_CLASSIC]   = casm_parse,
    [ARCH_WOODSTOCK] = wasm_parse,
    [ARCH_NUT]       = nasm_parse
  };


typedef void (write_obj_t)(FILE *f, int opcode);

static write_obj_t *write_obj [ARCH_MAX];

int pass;
int errors;
int warnings;

bool parse_error;


addr_t pc;		/* current pc */
uint32_t bank_mask;

// for "delayed select rom" and "delayed select group":
addr_t delayed_pc_mask [2];
addr_t delayed_pc_bits [2];

char flag_char;

#define MAX_OBJ_PER_SOURCE_LINE 256
static int obj_word_count;  // number of words emitted by source line
static int obj_words[MAX_OBJ_PER_SOURCE_LINE];

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


#define MAX_INCLUDE_NEST 128

static int include_nest;

static char *src_fn   [MAX_INCLUDE_NEST];
static int lineno     [MAX_INCLUDE_NEST];
static FILE *src_file [MAX_INCLUDE_NEST];
static FILE *obj_file  = NULL;
static FILE *list_file = NULL;


symtab_t *global_symtab;
symtab_t *symtab [MAXROM];  /* separate symbol tables for each '.rom' directive */


const char *copyright_string = NULL;
const char *license_string = NULL;


static void open_source (char *fn)
{
  if (++include_nest == MAX_INCLUDE_NEST)
    fatal (2, "include files nested too deep\n");
  src_fn [include_nest] = strdup (fn);
  lineno [include_nest] = 0;
  src_file [include_nest] = fopen (fn, "r");
  if (! src_file [include_nest])
    fatal (2, "can't open input file '%s'\n", fn);
}

static bool close_source (void)
{
  if (include_nest < 0)
    fatal (2, "mismatched source file close\n");
  fclose (src_file [include_nest]);
  free (src_fn [include_nest]);
  include_nest--;
  return include_nest >= 0;
}

void pseudo_include (char *s)
{
  char *p;
  char *s2;

  // prepend path prefix of current file
  p = path_prefix (src_fn [include_nest]);
  s2 = path_cat_n (2, p, s);
  open_source (s2);

  free (p);
  free (s);
}


#define MAX_COND_NEST_LEVEL 63
static int cond_nest_level;
static uint64_t cond_state;
static uint64_t cond_else;

static void cond_init (void)
{
  cond_nest_level = 0;
  cond_state = 1;
  cond_else = 0;
}

bool get_cond_state (void)
{
  return cond_state & 1;
}

int  get_lineno (void)
{
  return lineno [include_nest];
}

void pseudo_if (int val)
{
  if (cond_nest_level >= MAX_COND_NEST_LEVEL)
    {
      error ("conditionals nested too deep");
      return;
    }
  cond_nest_level++;
  cond_state <<= 1;
  cond_else <<= 1;
  cond_state |= (val != 0);
}

void pseudo_ifdef (char *s)
{
  symtab_t *table;
  int val;

  if (cond_nest_level >= MAX_COND_NEST_LEVEL)
    {
      error ("conditionals nested too deep");
      return;
    }
  if (local_label_flag && (*s != '$'))
    table = symtab [local_label_current_rom];
  else
    table = global_symtab;
  cond_nest_level++;
  cond_state <<= 1;
  cond_else <<= 1;

  bool cond_val = lookup_symbol (table, s, & val, lineno [include_nest]);
  cond_state |= cond_val;
}

void pseudo_ifndef (char *s)
{
  symtab_t *table;
  int val;

  if (cond_nest_level >= MAX_COND_NEST_LEVEL)
    {
      error ("conditionals nested too deep");
      return;
    }
  if (local_label_flag && (*s != '$'))
    table = symtab [local_label_current_rom];
  else
    table = global_symtab;
  cond_nest_level++;
  cond_state <<= 1;
  cond_else <<= 1;

  bool cond_val = ! lookup_symbol (table, s, & val, lineno [include_nest]);
  cond_state |= cond_val;
}

void pseudo_else (void)
{
  if (! cond_nest_level)
    {
      error ("else without conditional");
      return;
    }
  if (cond_else & 1)
    {
      error ("second else for same conditional");
      return;
    }
  cond_else |= 1;
  cond_state ^= 1;
}

void pseudo_endif (void)
{
  if (! cond_nest_level)
    {
      error ("endif without conditional");
      return;
    }
  cond_nest_level--;
  cond_state >>= 1;
  cond_else >>= 1;
}


void value_fmt_fn_classic (int value, char *buf, int buf_len)
{
  snprintf (buf, buf_len, "%01o%01o%03o", (value >> 11) & 01,
	                                  (value >> 8) & 07,
	                                  value & 0377);
}

void value_fmt_fn_nut(int value, char *buf, int buf_len)
{
  snprintf (buf, buf_len, "%04x", value);
}


static value_fmt_fn_t *value_fmt_fn [ARCH_MAX] =
{
  [ARCH_UNKNOWN]   = NULL,
  [ARCH_CLASSIC]   = value_fmt_fn_classic,
  [ARCH_WOODSTOCK] = NULL, // default OK
  [ARCH_NUT]       = value_fmt_fn_nut
};


void format_listing_unknown (void)
{
  listptr += sprintf (listptr, "%4d   ", lineno [include_nest]);
  listptr += sprintf (listptr, "             ");
  strcat (listptr, linebuf);
  listptr += strlen (listptr);
}

void format_listing_classic (void)
{
  int i;

  listptr += sprintf (listptr, "%4d   ", lineno [include_nest]);

  if (obj_word_count)
    {
      assert(obj_word_count == 1);
      listptr += sprintf (listptr, "L%1o%1o%03o:  ",
			  pc >> 11,
			  (pc >> 8) & 7,
			  pc & 0377);
      for (i = 0x200; i; i >>= 1)
	*listptr++ = (obj_words[0] & i) ? '1' : '.';
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
  listptr += sprintf (listptr, "%4d   ", lineno [include_nest]);

  if (obj_word_count)
    {
      assert(obj_word_count == 1);
      listptr += sprintf (listptr, "%04o:  %06o  ", pc, obj_words[0]);
    }
  else
    listptr += sprintf (listptr, "              ");
  
  strcat (listptr, linebuf);
  listptr += strlen (listptr);
}

void format_listing_nut(void)
{
  listptr += sprintf (listptr, "%4d   ", lineno [include_nest]);

  assert(obj_word_count <= 2);
  switch (obj_word_count)
    {
    case 0:
      listptr += sprintf (listptr, "               ");
      break;
    case 1:
      listptr += sprintf (listptr, "%04x: %03x      ", pc, obj_words[0]);
      break;
    case 2:
      listptr += sprintf (listptr, "%04x: %03x %03x  ", pc, obj_words[0], obj_words[1]);
      break;
    }
  
  strcat (listptr, linebuf);
  listptr += strlen (listptr);
}

typedef void (format_listing_t) (void);

static format_listing_t *format_listing [ARCH_MAX] =
{
  [ARCH_UNKNOWN]   = format_listing_unknown,
  [ARCH_CLASSIC]   = format_listing_classic,
  [ARCH_WOODSTOCK] = format_listing_woodstock,
  [ARCH_NUT]       = format_listing_nut
};


static void parse_source_line (void)
{
  lineptr = & linebuf [0];
  parse_error = false;
  asm_cond_parse ();
  if (! parse_error)
    return;  // successfully parsed a conditional assembly directive

  if (! (cond_state & 1))
    return;  // conditional false, don't try to parse

  lineptr = & linebuf [0];
  parse_error = false;
  asm_parse ();
  if (! parse_error)
    return;  // successfully parsed a directive

  if (! parser [arch])
    {
      error ("architecture not defined");
      return;
    }

  lineptr = & linebuf [0];
  parse_error = false;
  parser [arch] ();
}


static void process_line (char *inbuf)
{
  // remove trailing whitespace including newline if present
  trim_trailing_whitespace (inbuf);

  expand_tabs (linebuf,
	       sizeof (linebuf),
	       inbuf,
	       8);

  lineno [include_nest]++;

  listptr = & listbuf [0];
  listbuf [0] = '\0';

  errptr = & errbuf [0];
  errbuf [0] = '\0';

  obj_word_count = 0;
  target_flag = false;
  flag_char = ' ';

  symtab_pseudoop_flag = false;

  delayed_pc_mask [1] = delayed_pc_mask [0];
  delayed_pc_bits [1] = delayed_pc_bits [0];
  delayed_pc_mask [0] = 0;

  parse_source_line ();

  if (pass == 2)
    {
      if (symtab_pseudoop_flag)
	{
	  if (list_file && local_label_flag)
	    print_symbol_table (symtab [local_label_current_rom],
				list_file,
				value_fmt_fn [arch]);
	}
      else
	{
	  format_listing [arch] ();
	  if (list_file)
	    fprintf (list_file, "%s\n", listbuf);
	  if (errptr != & errbuf [0])
	    {
	      fprintf (stderr, "%s\n", listbuf);
	      if (list_file)
		fprintf (list_file, "%s", errbuf);
	      fprintf (stderr, "%s",   errbuf);
	    }
	}
    }

  pc = (pc + obj_word_count) & pc_mask[arch];
}


static void do_pass (int p)
{
  char inbuf [MAX_LINE];

  arch = ARCH_UNKNOWN;
  
  pass = p;
  errors = 0;
  warnings = 0;

  cond_init ();
  pc = 0;
  bank_mask = 0;
  delayed_pc_mask [0] = 0;

  last_instruction_type = OTHER_INST;
  legal_flag = false;
  local_label_flag = false;

  printf ("Pass %d rom", pass);

  while (1)
    {
      if (! fgets (inbuf, MAX_LINE, src_file [include_nest]))
	{
	  if (ferror (src_file [include_nest]))
	    fatal (2, "error reading source file\n");
	  if (close_source ())
	    continue;
	  else
	    break;
	}

      process_line (inbuf);
    }

  if (cond_nest_level != 0)
    error ("unterminated conditional(s)");

  if ((pass == 2) && list_file)
    {
      fprintf (list_file, "\nGlobal symbols:\n\n");
      print_symbol_table (global_symtab,
			  list_file,
			  value_fmt_fn [arch]);
      fprintf (list_file, "\n");
    }

  printf ("\n");
}


static void parse_define_option (char *opt)
{
  char *name;
  long value;

  name = opt + 2;  // skip the "-D"
  if (! *name)
    goto syntax_err;  // must be a name

  char *equals = strchr (name, '=');
  if (equals)
    {
      char *val_end_ptr;
      *equals = '\0';
      if (! * (equals + 1))  // must be a value after the equals
	goto syntax_err;
      value = strtol (equals + 1, & val_end_ptr, 0);
      if (* val_end_ptr)
	goto syntax_err;  // extra characters that can't be parsed as a value
    }
  else
    value = 1;

  fprintf (stderr, "defining '%s' to have value %ld\n", name, value);

  if (! create_symbol (global_symtab, name, value, 0))
    fatal (1, "duplicate symbol in '-D' option: '%s'\n", name);

  return;

 syntax_err:
  fatal (1, "malformed '-D' option\n");
  return;
}


static void write_object_file_metadata(void)
{
  if (! obj_file)
    return;

  if (copyright_string)
    fprintf(obj_file, "# COPYRIGHT: %s\n", copyright_string);
  if (license_string)
    fprintf(obj_file, "# SPDX-License-Identifier: %s\n", license_string);
}


int main (int argc, char *argv[])
{
  char *src_fn = NULL;
  char *obj_fn = NULL;
  char *list_fn = NULL;
  int rom;

  progname = argv [0];

  global_symtab = alloc_symbol_table ();
  if (! global_symtab)
    fatal (2, "symbol table allocation failed\n");

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
	  else if (strncmp (argv [0], "-D", 2) == 0)
	    {
	      parse_define_option (argv [0]);
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

  for (rom = 0; rom < MAXROM; rom++)
    {
      symtab [rom] = alloc_symbol_table ();
      if (! symtab [rom])
	fatal (2, "symbol table allocation failed\n");
    }

  if (obj_fn)
    {
      obj_file = fopen (obj_fn, "w");
      if (! obj_file)
	fatal (2, "can't open input file '%s'\n", obj_fn);
    }

  if (list_fn)
    {
      list_file = fopen (list_fn, "w");
      if (! list_file)
	fatal (2, "can't open listing file '%s'\n", list_fn);
    }

  include_nest = -1;
  open_source (src_fn);
  do_pass (1);

  open_source (src_fn);
  write_object_file_metadata();
  do_pass (2);

  err_printf ("%d errors detected, %d warnings\n", errors, warnings);

  if (obj_file)
    fclose (obj_file);
  if (list_file)
    fclose (list_file);
  exit (0);
}


void define_symbol (char *s, int value)
{
  int prev_val;
  symtab_t *table;

  if (local_label_flag && (*s != '$'))
    table = symtab [local_label_current_rom];
  else
    table = global_symtab;

  if (pass == 1)
    {
      if (! create_symbol (table, s, value, lineno [include_nest]))
	error ("multiply defined symbol '%s'\n", s);
    }
  else if (! lookup_symbol (table, s, & prev_val, lineno [include_nest]))
    error ("undefined symbol '%s'\n", s);
  else if (prev_val != value)
    error ("phase error for symbol '%s'\n", s);
}


void do_label (char *s)
{
  define_symbol (s, pc);
}


static void write_obj_classic (FILE *f, int opcode)
{
  if (f)
    fprintf (f, "%04o:%04o\n", pc + (obj_word_count - 1), opcode &01777);
}


static void write_obj_woodstock (FILE *f, int opcode)
{
  if (f)
    {
      if (bank_mask)
	{
	  unsigned int i;
	  fprintf (f, "[");
	  for (i = 0; i < (8 * sizeof (bank_mask)); i++)
	    if (bank_mask & (1 << i))
	      fprintf (f, "%d", i);
	  fprintf (f, "]");
	}
      fprintf (f, "%04o:%04o\n", pc + (obj_word_count - 1), opcode &01777);
    }
}

static void write_obj_nut (FILE *f, int opcode)
{
  if (f)
    fprintf (f, "%04x:%03x\n", pc + (obj_word_count - 1), opcode);
}


static write_obj_t *write_obj [ARCH_MAX] =
  {
    [ARCH_CLASSIC]   = write_obj_classic,
    [ARCH_WOODSTOCK] = write_obj_woodstock,
    [ARCH_NUT]       = write_obj_nut
  };


static void emit_core (int op, int inst_type)
{
  obj_words[obj_word_count++] = op;
  last_instruction_type = inst_type;

  if (pass == 2)
    write_obj [arch] (obj_file, op);
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

  next_pc = (pc + 1) & pc_mask[arch];
  next_pc &= ~ delayed_pc_mask [1];
  next_pc |= (delayed_pc_mask [1] & delayed_pc_bits [1]);

  return next_pc;
}

int range (int val, int min, int max)
{
  if ((val < min) || (val > max))
    {
      error ("value %d out of range [%d to %d], using %d\n", val, min, max, min);
      return min;
    }
  return val;
}

int range_pass2 (int val, int min, int max)
{
  if ((val < min) || (val > max))
    {
      if (pass == 2)
	error ("value %d out of range [%d to %d], using %d\n", val, min, max, min);
      return min;
    }
  return val;
}


// returns 0 if no bits are set
static int rightmost_one (uint64_t v)
{
  int b = 0;
  if (! v)
    return 0;
  while (! (v & 1))
    {
      v >>= 1;
      b++;
    }
  return b;
}


int range_mask (int val, uint64_t mask)
{
  if ((val < 0) || (val > 63) || ! (mask & (1 << val)))
    {
      val = rightmost_one (val);
      error ("value out of range, using %d", val);
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

  if (list_file && (pass == 2))
    {
      va_list ap_copy;

      va_copy (ap_copy, ap);
      vfprintf (list_file, format, ap_copy);
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

  err_printf ("error in file %s line %d: ", src_fn [include_nest], lineno [include_nest]);
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

  err_printf ("warning in file %s line %d: ", src_fn [include_nest], lineno [include_nest]);
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
