/*
$Id$
Copyright 2004, 2005, 2006, 2008 Eric Smith <eric@brouhaha.com>

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

#include <gsf/gsf-infile.h>
#include <gsf/gsf-input.h>

#include "util.h"
#include "display.h"
#include "kml.h"


GsfInfile *kml_gsfinfile;
GsfInput *kml_gsfinput;

int kml_lineno;
int kml_tokenpos;
int kml_errors;

char kml_linebuf [KML_LINEBUF_SIZE];


void yyerror (char *fmt, ...)
{
  va_list ap;

  fprintf (stderr, "%d: ", kml_lineno);

  va_start (ap, fmt);
  vfprintf (stderr, fmt, ap);
  va_end (ap);

  fprintf (stderr, "\n");

  trim_trailing_whitespace (kml_linebuf);
  fprintf (stderr, "%s\n", kml_linebuf);
  fprintf (stderr, "%*s\n", 1 + kml_tokenpos, "^");
}


void range_check (int val, int min, int max)
{
  if ((val < min) || (val > max))
    yyerror ("value %d out of range [%d, %d]", val, min, max);
}


void range_check_char (int val, int min, int max)
{
  if ((val < min) || (val > max))
    yyerror ("value '%c' out of range ['%c', '%c']", val, min, max);
}


int kml_yyinput (unsigned char *buf, size_t max_size)
{
  size_t size;
  unsigned char const * rp;
  size_t r;

  if (kml_gsfinput)
    {
      size = gsf_input_remaining (kml_gsfinput);
      if (! size)
	return 0;

      if (size > max_size)
	size = max_size;
      rp = gsf_input_read (kml_gsfinput, size, buf);
      if (rp)
	return size;
      else
	return 0;
    }
  else
    {
      // not very efficient
      r = fread (buf, 1, max_size, yyin);
      return r;
    }
}


kml_t *read_kml_file (char *fn)
{
  kml_t *kml;
  extern kml_t *yy_kml;

  kml_gsfinfile = NULL;

  yyin = fopen (fn, "r");
  if (! yyin)
    return (NULL);
 
  kml = alloc (sizeof (kml_t));

  yy_kml = kml;

  kml_lineno = 1;

  yyparse ();
  
  fclose (yyin);
  yyin = NULL;

  return (kml);
}


kml_t *read_kml_file_from_gsfinfile (GsfInfile *nui, char *fn)
{
  kml_t *kml;
  extern kml_t *yy_kml;

  kml_gsfinput = gsf_infile_child_by_name (nui, fn);
  if (! kml_gsfinput)
    return NULL;

  kml_gsfinfile = nui;
  g_object_ref (G_OBJECT (kml_gsfinfile));

  kml = alloc (sizeof (kml_t));

  yy_kml = kml;

  kml_lineno = 1;

  yyparse ();

  g_object_unref (G_OBJECT (kml_gsfinput));
  kml_gsfinput = NULL;
  g_object_unref (G_OBJECT (kml_gsfinfile));
  kml_gsfinfile = NULL;

  return (kml);
}

void kml_include (char *fn UNUSED)
{
  fatal (2, "KML include not currently supported.");
}


static void free_kml_command_list (kml_command_list_t *list)
{
  while (list)
    {
      kml_command_list_t *next = list->next;
      if (list->then_part)
	free_kml_command_list (list->then_part);
      if (list->else_part)
	free_kml_command_list (list->then_part);
      free (list);
      list = next;
    }
}

void free_kml (kml_t *kml)
{
  int i;
  kml_scancode_t *scancode, *next_scancode;

  /* ISO/IEC 9899 paragraph 7.20.3.2 says free(NULL) has no effect. */
  free (kml->title);
  free (kml->author);
  free (kml->model);
  free (kml->image_fn);

  for (i = 0; i < KML_MAX_GLOBAL_COLOR; i++)
    free (kml->global_color [i]);

  for (i = 0; i < KML_MAX_DISPLAY_COLOR; i++)
    free (kml->display_color [i]);

  for (i = 0; i < KML_MAX_SEGMENT; i++)
    free (kml->segment [KML_MAX_SEGMENT]);

  for (i = 0; i < KML_MAX_ANNUNCIATOR; i++)
    free (kml->annunciator [i]);

  for (i = 0; i < KML_MAX_BUTTON; i++)
    if (kml->button [i])
      {
	free_kml_command_list (kml->button [i]->onup);
	free_kml_command_list (kml->button [i]->ondown);
	free (kml->button [i]);
      }

  for (scancode = kml->first_scancode; scancode; scancode = next_scancode)
    {
      next_scancode = scancode->next;
      free_kml_command_list (scancode->commands);
      free (scancode);
    }
}


static void print_kml_string (FILE *f, char *name, char *val)
{
  if (name)
    fprintf (f, "\t%s \"%s\"\n", name, val);
}


static void print_kml_size (FILE *f, kml_size_t *size)
{
  fprintf (f, "size %d %d ", size->width, size->height);
}


static void print_kml_offset (FILE *f, kml_offset_t *offset)
{
  fprintf (f, "offset %d %d ", offset->x, offset->y);
}


static void print_kml_global (FILE *f, kml_t *kml)
{
  fprintf (f, "global\n");
  print_kml_string (f, "title",        kml->title);
  print_kml_string (f, "author",       kml->author);
  print_kml_string (f, "model",        kml->model);
  print_kml_string (f, "image",        kml->image_fn);
  if (kml->has_transparency)
    fprintf (f, "\ttransparency %d\n", kml->transparency_threshold);
  fprintf (f, "end\n\n");
}

static void print_kml_switch (FILE *f, kml_t *kml, int s)
{
  int p;
  fprintf (f, "switch %d\n", s);
  fprintf (f, "\tsize %d %d\n",
	   kml->kswitch [s]->size.width,
	   kml->kswitch [s]->size.height);
  fprintf (f, "\toffset %d %d\n",
	   kml->kswitch [s]->offset.x,
	   kml->kswitch [s]->offset.y);
  fprintf (f, "\tdefault %d\n", kml->kswitch [s]->default_position);
  for (p = 0; p < KML_MAX_SWITCH_POSITION; p++)
    if (kml->kswitch [s]->position [p])
      {
	fprintf (f, "\tposition %d", p);
	fprintf (f, "  end\n");
      }
  fprintf (f, "end\n\n");
}

void print_kml_command_list (FILE *f, kml_command_list_t *commands)
{
  while (commands)
    {
      switch (commands->cmd)
	{
	case KML_CMD_MAP:
	  fprintf (f, "map %d %d", commands->arg1, commands->arg2);
	  break;
	case KML_CMD_PRESS:
	  fprintf (f, "press %d ", commands->arg1);
	  break;
	case KML_CMD_RELEASE:
	  fprintf (f, "release %d ", commands->arg1);
	  break;
	case KML_CMD_SETFLAG:
	  fprintf (f, "setflag %d ", commands->arg1);
	  break;
	case KML_CMD_RESETFLAG:
	  fprintf (f, "resetflag %d ", commands->arg1);
	  break;
	case KML_CMD_MENUITEM:
	  fprintf (f, "menuitem %d ", commands->arg1);
	  break;
	case KML_CMD_IFFLAG:
	  fprintf (f, "ifflag %d ", commands->arg1);
	  print_kml_command_list (f, commands->then_part);
	  if (commands->else_part)
	    {
	      fprintf (f, "else ");
	      print_kml_command_list (f, commands->else_part);
	    }
	  fprintf (f, " end");
	  break;
	case KML_CMD_IFPRESSED:
	  fprintf (f, "ifpressed %d ", commands->arg1);
	  print_kml_command_list (f, commands->then_part);
	  if (commands->else_part)
	    {
	      fprintf (f, "else ");
	      print_kml_command_list (f, commands->else_part);
	    }
	  fprintf (f, " end");
	  break;
	}
      commands = commands->next;
    }
}

void print_kml_scancode (FILE *f, kml_scancode_t *scancode)
{
  fprintf (f, "scancode %d ", scancode->scancode);
  print_kml_command_list (f, scancode->commands);
  fprintf (f, " end\n");
}

void print_kml_annunciator (FILE *f, kml_t *kml, int i)
{
  fprintf (f, "annunciator %d  ", i);
  print_kml_size (f, & kml->annunciator [i]->size);
  print_kml_offset (f, & kml->annunciator [i]->offset);
  fprintf (f, "end\n");
}

void print_kml (FILE *f, kml_t *kml)
{
  int i;
  kml_scancode_t *scancode;

  print_kml_global (f, kml);
  for (i = 0; i < KML_MAX_ANNUNCIATOR; i++)
    if (kml->annunciator [i])
      print_kml_annunciator (f, kml, i);
  for (i = 0; i < KML_MAX_SWITCH; i++)
    if (kml->kswitch [i])
      print_kml_switch (f, kml, i);
  for (scancode = kml->first_scancode; scancode; scancode = scancode->next)
    print_kml_scancode (f, scancode);
}


