/*
$Id$
Copyright 2005 Eric L. Smith <eric@brouhaha.com>

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

#include <libxml/SAX.h>

#include "util.h"
#include "nsim_conv.h"


typedef enum { cpu, periph } reg_mode_t;

typedef struct
{
  reg_mode_t reg_mode;
  uint8_t periph_addr;
} sax_data_t;


static void parse_state (char **attrs)
{
  int i;
  bool got_version = false;
  bool got_arch = false;
  bool got_platform = false;
  bool got_model = false;

  for (i = 0; attrs && attrs [i]; i+= 2)
    {
      if (strcmp (attrs [i], "version") == 0)
	{
	  if (strcmp (attrs [i + 1], "1.00") != 0)
	    warning ("Unrecognized version '%s' of Nonpareil state format\n",
		     attrs [i + 1]);
	  got_version = true;
	}
      else if (strcmp (attrs [i], "arch") == 0)
	{
	  if (strcmp (attrs [i + 1], "nut") != 0)
	    fatal (3, "Can't convert from arch '%s'\n", attrs [i + 1]);
	  got_arch = true;
	}
      else if (strcmp (attrs [i], "platform") == 0)
	{
	  if (strcmp (attrs [i + 1], "coconut") != 0)
	    fatal (3, "Can't convert from platform '%s'\n", attrs [i + 1]);
	  got_platform = true;
	}
      else if (strcmp (attrs [i], "model") == 0)
	{
	  if (strncmp (attrs [i + 1], "41", 2) != 0)
	    fatal (3, "Can't convert from model '%s'\n", attrs [i + 1]);
	  got_model = true;
	}
      else
	warning ("unknown attribute '%s' in 'loc' element\n", attrs [i]);
    }
  if (! got_version)
    warning ("state file doesn't have version\n");
  if (! got_arch)
    warning ("state file doesn't have arch\n");
  if (! got_platform)
    warning ("state file doesn't have platform\n");
  if (! got_model)
    warning ("state file doesn't have model\n");
}

static void parse_cpu_reg (char **attrs)
{
  int i;
  char *name = NULL;
  bool got_index = false;
  bool got_data = false;
  uint64_t index;
  uint64_t data;
  
  for (i = 0; attrs && attrs [i]; i+= 2)
    {
      if (strcmp (attrs [i], "name") == 0)
	name = attrs [i + 1];
      else if (strcmp (attrs [i], "index") == 0)
	{
	  index = strtoull (attrs [i + 1], NULL, 16);
	  got_index = true;
	}
      else if (strcmp (attrs [i], "data") == 0)
	{
	  data = strtoull (attrs [i + 1], NULL, 16);
	  got_data = true;
	}
      else
	warning ("unknown attribute '%s' in 'reg' element\n", attrs [i]);
    }

  if (! name)
    fatal (3, "missing 'name' attribute in 'reg' element\n");
  if (! got_data)
    fatal (3, "missing 'data' attribute in 'reg' element\n");
  if ((strcmp (name, "stack") == 0) && ! got_index)
    fatal (3, "stack register must have 'index' attribute\n");
  if ((strcmp (name, "stack") != 0) && got_index)
    fatal (3, "only stack register may have 'index' attribute\n");
  if (got_index && (index >= MAX_STACK))
    fatal (3, "index attribute out of range\n");

  if (strcmp (name, "a") == 0)
    regs.a = data;
  else if (strcmp (name, "b") == 0)
    regs.b = data;
  else if (strcmp (name, "c") == 0)
    regs.c = data;
  else if (strcmp (name, "m") == 0)
    regs.m = data;
  else if (strcmp (name, "n") == 0)
    regs.n = data;
  else if (strcmp (name, "g") == 0)
    regs.g = data;
  else if (strcmp (name, "p") == 0)
    regs.p = data;
  else if (strcmp (name, "q") == 0)
    regs.q = data;
  else if (strcmp (name, "status") == 0)
    regs.status = data;
  else if (strcmp (name, "pc") == 0)
    regs.pc = data;
  else if (strcmp (name, "stack") == 0)
    regs.stack [index] = data;
  else if (strcmp (name, "awake") == 0)
    regs.awake = data;
  else if (strcmp (name, "carry") == 0)
    regs.carry = data;
  else if (strcmp (name, "decimal") == 0)
    regs.decimal = data;
  else if (strcmp (name, "q_selected") == 0)
    regs.q_selected = data;
  else
    warning ("unknown CPU register '%s'\n", name);
}


static void parse_lcd_reg (char **attrs)
{
  int i;
  char *name = NULL;
  bool got_data = false;
  uint64_t data;
  
  for (i = 0; attrs && attrs [i]; i+= 2)
    {
      if (strcmp (attrs [i], "name") == 0)
	name = attrs [i + 1];
      else if (strcmp (attrs [i], "data") == 0)
	{
	  data = strtoull (attrs [i + 1], NULL, 16);
	  got_data = true;
	}
      else
	warning ("unknown attribute '%s' in 'reg' element\n", attrs [i]);
    }

  if (! name)
    fatal (3, "missing 'name' attribute in 'reg' element\n");
  if (! got_data)
    fatal (3, "missing 'data' attribute in 'reg' element\n");

  if (strcmp (name, "enable") == 0)
    regs.lcd.enable = data;
  else if (strcmp (name, "a") == 0)
    regs.lcd.a = data;
  else if (strcmp (name, "b") == 0)
    regs.lcd.b = data;
  else if (strcmp (name, "c") == 0)
    regs.lcd.c = data;
  else if (strcmp (name, "ann") == 0)
    regs.lcd.ann = data;
  else
    warning ("unknown LCD register '%s'\n", name);
}


static void parse_reg (sax_data_t *data, char **attrs)
{
  if (data->reg_mode == cpu)
    parse_cpu_reg (attrs);
  else
    switch (data->periph_addr)
      {
      case LCD_PERIPH_ADDR:
	parse_lcd_reg (attrs);
	break;
      default:
	warning ("unknown peripheral address %02x\n", data->periph_addr);
      }
}


static void parse_ram (char **attrs)
{
  int i;
  bool got_addr = false;
  bool got_data = false;
  uint64_t addr;
  uint64_t data;

  for (i = 0; attrs && attrs [i]; i+= 2)
    {
      if (strcmp (attrs [i], "addr") == 0)
	{
	  addr = strtoull (attrs [i + 1], NULL, 16);
	  got_addr = true;
	}
      else if (strcmp (attrs [i], "data") == 0)
	{
	  data = strtoull (attrs [i + 1], NULL, 16);
	  got_data = true;
	}
      else
	warning ("unknown attribute '%s' in 'loc' element\n", attrs [i]);
    }
  if (! got_addr)
    fatal (3, "missing 'addr' attribute in 'loc' element\n");
  if (! got_data)
    fatal (3, "missing 'data' attribute in 'loc' element\n");
  if (addr >= MAX_RAM)
    fatal (3, "RAM address out of range\n");
  ram [addr] = data;
  ram_used [addr] = true;
}


static void parse_periph (sax_data_t *data, char **attrs)
{
  int i;
  bool got_addr = false;
  uint64_t addr;

  data->reg_mode = periph;
  
  for (i = 0; attrs && attrs [i]; i+= 2)
    {
      if (strcmp (attrs [i], "addr") == 0)
	{
	  addr = strtoull (attrs [i + 1], NULL, 16);
	  got_addr = true;
	}
      else
	warning ("unknown attribute '%s' in 'periph' element\n", attrs [i]);
    }
  if (! got_addr)
    fatal (3, "missing 'addr' attribute in 'loc' element\n");
  if (addr != LCD_PERIPH_ADDR)
    fatal (3, "peripheral address out of range\n");

  data->periph_addr = addr;
}

static void sax_start_element (void *ref,
			       const xmlChar *name,
			       const xmlChar **attrs)
{
  sax_data_t *data = ref;

  if (strcmp (name, "state") == 0)
    parse_state ((char **) attrs);
  else if (strcmp (name, "registers") == 0)
    { data->reg_mode = cpu; }
  else if (strcmp (name, "reg") == 0)
    parse_reg (data, (char **) attrs);
  else if (strcmp (name, "memory") == 0)
    { ; }
  else if (strcmp (name, "loc") == 0)
    parse_ram ((char **) attrs);
  else if (strcmp (name, "periph") == 0)
    parse_periph (data, (char **) attrs);
  else
    warning ("unknown element '%s'\n", name);
}

static xmlEntityPtr sax_get_entity (void *ref,
				    const xmlChar *name)
{
  sax_data_t *data unused = ref;
  return xmlGetPredefinedEntity (name);
}


static void sax_warning (void *ref,
			 const char *msg,
			 ...)
{
  sax_data_t *data unused = ref;
  va_list ap;

  va_start (ap, msg);
  fprintf (stderr, "XML warning: ");
  vfprintf (stderr, msg, ap);
  va_end (ap);
}


static void sax_error (void *ref,
		       const char *msg,
		       ...)
{
  sax_data_t *data unused = ref;
  va_list ap;

  va_start (ap, msg);
  fprintf (stderr, "XML warning: ");
  vfprintf (stderr, msg, ap);
  va_end (ap);
}


static void sax_fatal_error (void *ref,
			     const char *msg,
			     ...)
{
  sax_data_t *data unused = ref;
  va_list ap;

  va_start (ap, msg);
  fprintf (stderr, "XML warning: ");
  vfprintf (stderr, msg, ap);
  va_end (ap);
}


xmlSAXHandler sax_handler =
{
  .getEntity     = sax_get_entity,
  .startElement  = sax_start_element,
  .warning       = sax_warning,
  .error         = sax_error,
  .fatalError    = sax_fatal_error,
};


void state_read_xml (char *fn)
{
  sax_data_t sax_data;

  memset (& sax_data, 0, sizeof (sax_data));

  xmlSAXUserParseFile (& sax_handler,
		       & sax_data,
		       fn);
}
