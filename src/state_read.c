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

#include <inttypes.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <gdk/gdk.h>
#include <gtk/gtk.h>

#include <libxml/SAX.h>

#include "util.h"
#include "display.h"
#include "kml.h"
#include "proc.h"
#include "arch.h"
#include "platform.h"
#include "model.h"
#include "csim.h"  // $$$ for slide switches - really should get from sim instead
#include "state_io.h"


#define unused __attribute__((unused))


typedef struct
{
  sim_t *sim;
  chip_t *chip;
} sax_data_t;


static void parse_state (sax_data_t *sdata, char **attrs)
{
  int i;
  bool got_version = false;
  bool got_arch = false;
  bool got_platform = false;
  bool got_model = false;

  model_info_t *model_info;
  arch_info_t *arch_info;

  model_info = get_model_info (sim_get_model (sdata->sim));
  arch_info = get_arch_info (model_info->cpu_arch);

  for (i = 0; attrs && attrs [i]; i+= 2)
    {
      if (strcmp (attrs [i], "version") == 0)
	{
	  if (strcmp (attrs [i + 1], "1.00") != 0)
	    warning ("Unrecognized version '%s' of Nonpareil state format\n",
		     attrs [i + 1]);
	  got_version = true;
	}
      else if (strcmp (attrs [i], "model") == 0)
	{
	  if (strcmp (attrs [i + 1], model_info->name) != 0)
	    fatal (3, "model '%s' doesn't match simulator model '%s'\n",
		   attrs [i + 1], model_info->name);
	  got_model = true;
	}
      else if (strcmp (attrs [i], "platform") == 0)
	{
	  if (strcmp (attrs [i + 1], platform_name [model_info->platform]) != 0)
	    fatal (3, "platform '%s' doesn't match simulator platform '%s'\n",
		   attrs [i + 1], platform_name [model_info->platform]);
	  got_platform = true;
	}
      else if (strcmp (attrs [i], "arch") == 0)
	{
	  if (strcmp (attrs [i + 1], arch_info->name) != 0)
	    fatal (3, "arch '%s' doesn't match simulator arch '%s'\n",
		   attrs [i + 1], platform_name [model_info->platform]);
	  got_arch = true;
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


static void parse_ui (sax_data_t *sdata, char **attrs)
{
  ; // don't need to do anything
}


static void parse_switch (sax_data_t *sdata, char **attrs)
{
  int i;
  uint32_t number;
  uint32_t position;
  bool got_number = false;
  bool got_position = false;

  for (i = 0; attrs && attrs [i]; i += 2)
    {
      if (strcmp (attrs [i], "number") == 0)
	{
	  number = str_to_uint32 (attrs [i + 1], NULL, 16);
	  got_number = true;
	}
      else if (strcmp (attrs [i], "position") == 0)
	{
	  position = str_to_uint32 (attrs [i + 1], NULL, 16);
	  got_position = true;
	}
      else
	warning ("unknown attribute '%s' in 'switch' element\n", attrs [i]);
    }
  if (! got_number)
    fatal (3, "switch element with no number\n");
  if (! got_position)
    fatal (3, "switch element with no position\n");
  set_slide_switch_position (number, position);
}


static void parse_chip (sax_data_t *sdata, char **attrs)
{
  int i;
  uint64_t addr = 0;
  char *name;
  bool got_addr = false;
  bool got_name = false;
  const chip_info_t *chip_info;

  for (i = 0; attrs && attrs [i]; i += 2)
    {
      if (strcmp (attrs [i], "addr") == 0)
	{
	  addr = str_to_uint64 (attrs [i + 1], NULL, 16);
	  got_addr = true;
	}
      else if (strcmp (attrs [i], "name") == 0)
	{
	  name = attrs [i + 1];
	  got_name = true;
	}
      else
	warning ("unknown attribute '%s' in 'chip' element\n", attrs [i]);
    }
  if (! got_name)
    fatal (3, "chip element with no name\n");
  sdata->chip = sim_find_chip (sdata->sim, name, addr);
  if (! sdata->chip)
    fatal (3, "can't find chip '%s' addr %" PRIx64, name, addr);
  chip_info = sim_get_chip_info (sdata->sim, sdata->chip);
  if (! chip_info)
    fatal (3, "can't get info on chip '%s' addr %" PRIx64 "\n,", name, addr);
  if (got_addr && ! chip_info->multiple)
    warning ("address specified unnecessarily for chip '%s'\n", name);
}


static void parse_registers (sax_data_t *sdata, char **attrs)
{
  ; // don't need to do anything
}


static void parse_reg (sax_data_t *sdata, char **attrs)
{
  int i;
  bool got_name = false;
  bool got_index = false;
  bool got_data = false;
  char *name;
  uint64_t index = 0;
  uint64_t data;
  int reg_num;

  for (i = 0; attrs && attrs [i]; i += 2)
    {
      if (strcmp (attrs [i], "name") == 0)
	{
	  name = attrs [i + 1];
	  got_name = true;
	}
      else if (strcmp (attrs [i], "index") == 0)
	{
	  index = str_to_uint64 (attrs [i + 1], NULL, 16);
	  got_index = true;
	}
      else if (strcmp (attrs [i], "data") == 0)
	{
	  data = str_to_uint64 (attrs [i + 1], NULL, 16);
	  got_data = true;
	}
      else
	warning ("unknown attribute '%s' in 'reg' element\n", attrs [i]);
    }
  if (! got_name)
    warning ("register with no name\n");
  if (! got_data)
    warning ("register with no data\n");
  if (! (got_name && got_data))
    return;

  // find register
  reg_num = sim_find_register (sdata->sim, sdata->chip, name);
  if (reg_num < 0)
    {
      warning ("unknown register '%s'\n", name);
      return;
    }

  // write register
  if (! sim_write_register (sdata->sim, sdata->chip, reg_num, index, & data))
    fatal (3, "error writing '%014" PRIx64 "' to register '%s' (num %d) index %d\n", data, name, reg_num, index);
}


static void parse_memory (sax_data_t *sdata, char **attrs)
{
  ; // don't need to do anything
  // someday we'll want to check the "as" attribute (address space)
}


static void parse_loc (sax_data_t *sdata, char **attrs)
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
	  addr = str_to_uint64 (attrs [i + 1], NULL, 16);
	  got_addr = true;
	}
      else if (strcmp (attrs [i], "data") == 0)
	{
	  data = str_to_uint64 (attrs [i + 1], NULL, 16);
	  got_data = true;
	}
      else
	warning ("unknown attribute '%s' in 'loc' element\n", attrs [i]);
    }
  if (! got_addr)
    fatal (3, "missing 'addr' attribute in 'loc' element\n");
  if (! got_data)
    fatal (3, "missing 'data' attribute in 'loc' element\n");

  // write RAM
  if (! sim_write_ram (sdata->sim, addr, & data))
    fatal (3, "error writing '%014" PRIx64 "' to RAM addr %03x\n", data, addr);
}


static void sax_start_element (void *ref,
			       const xmlChar *name,
			       const xmlChar **attrs)
{
  sax_data_t *sdata = ref;

  if (strcmp (name, "state") == 0)
    parse_state (sdata, (char **) attrs);
  else if (strcmp (name, "ui") == 0)
    parse_ui (sdata, (char **) attrs);
  else if (strcmp (name, "switch") == 0)
    parse_switch (sdata, (char **) attrs);
  else if (strcmp (name, "chip") == 0)
    parse_chip (sdata, (char **) attrs);
  else if (strcmp (name, "registers") == 0)
    parse_registers (sdata, (char **) attrs);
  else if (strcmp (name, "reg") == 0)
    parse_reg (sdata, (char **) attrs);
  else if (strcmp (name, "memory") == 0)
    parse_memory (sdata, (char **) attrs);
  else if (strcmp (name, "loc") == 0)
    parse_loc (sdata, (char **) attrs);
  else
    warning ("unknown element '%s'\n", name);
}

static xmlEntityPtr sax_get_entity (void *ref,
				    const xmlChar *name)
{
  sax_data_t *sdata unused = ref;
  return xmlGetPredefinedEntity (name);
}


static void sax_warning (void *ref,
			 const char *msg,
			 ...)
{
  sax_data_t *sdata unused = ref;
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
  sax_data_t *sdata unused = ref;
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
  sax_data_t *sdata unused = ref;
  va_list ap;

  va_start (ap, msg);
  fprintf (stderr, "XML warning: ");
  vfprintf (stderr, msg, ap);
  va_end (ap);
}


static xmlSAXHandler sax_handler =
{
  .getEntity     = sax_get_entity,
  .startElement  = sax_start_element,
  .warning       = sax_warning,
  .error         = sax_error,
  .fatalError    = sax_fatal_error,
};


void state_read_xml (sim_t *sim, char *fn)
{
  sax_data_t sdata;

  sim_set_io_pause_flag (sim, true);
  sim_event (sim, event_restore_starting, NULL, 0, NULL);

  memset (& sdata, 0, sizeof (sdata));

  sdata.sim = sim;

  xmlSAXUserParseFile (& sax_handler,
		       & sdata,
		       fn);

  sim_event (sim, event_restore_completed, NULL, 0, NULL);
  sim_set_io_pause_flag (sim, false);
}
