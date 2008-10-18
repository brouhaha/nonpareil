/*
$Id$
Copyright 2005, 2006, 2008 Eric Smith <eric@brouhaha.com>

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

#include <gsf/gsf-infile.h>

#include <libxml/xmlwriter.h>
#include <libxml/SAX.h>

#include "util.h"
#include "xmlutil.h"
#include "display.h"
#include "kml.h"
#include "chip.h"
#include "proc.h"
#include "state_io.h"


typedef struct
{
  sim_t *sim;
  chip_t *chip;
  plugin_module_t *module;
  bool skip_module;
} sax_data_t;


static void parse_state (sax_data_t *sdata, char **attrs)
{
  int i;
  bool got_version = false;
  bool got_ncd = false;

  for (i = 0; attrs && attrs [i]; i += 2)
    {
      if (strcmp (attrs [i], "version") == 0)
	{
	  if (strcmp (attrs [i + 1], "1.0") != 0)
	    warning ("Unrecognized version '%s' of Nonpareil state format\n",
		     attrs [i + 1]);
	  got_version = true;
	}
      else if (strcmp (attrs [i], "ncd") == 0)
	{
	  if (strcmp (attrs [i + 1], sim_get_ncd_fn (sdata->sim)) != 0)
	    fatal (3, "NCD '%s' doesn't match simulator NCD '%s'\n",
		   attrs [i + 1], sim_get_ncd_fn (sdata->sim));
	  got_ncd = true;
	}
      else
	warning ("unknown attribute '%s' in 'loc' element\n", attrs [i]);
    }
  if (! got_version)
    warning ("state file doesn't have version\n");
  if (! got_ncd)
    warning ("state file doesn't have NCD\n");
}


static void parse_ui (sax_data_t *sdata UNUSED,
		      char **attrs UNUSED)
{
  ; // don't need to do anything
}


static void parse_switch (sax_data_t *sdata,
			  char **attrs)
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
  if (! sim_set_switch (sdata->sim, number, position))
    fatal (3, "can't set switch %d to position %d\n", number, position);
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
    {
      warning ("can't find chip '%s' addr %" PRIx64 ", skipping\n", name, addr);
      return;
    }
  chip_info = sim_get_chip_info (sdata->sim, sdata->chip);
  if (! chip_info)
    fatal (3, "can't get info on chip '%s' addr %" PRIx64 "\n,", name, addr);
  if (got_addr && ! chip_info->multiple)
    warning ("address specified unnecessarily for chip '%s'\n", name);
}


static void parse_registers (sax_data_t *sdata UNUSED,
			     char **attrs UNUSED)
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

  if(! sdata->chip)  // if the register belongs to a chip not present, skip it
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


static void parse_memory (sax_data_t *sdata UNUSED,
			  char **attrs UNUSED)
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

  for (i = 0; attrs && attrs [i]; i += 2)
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


static void parse_module (sax_data_t *sdata, char **attrs)
{
  int i;
  bool got_port = false;
  int32_t port;
  char *name = NULL;
  char *path = NULL;

  for (i = 0; attrs && attrs [i]; i += 2)
    {
      if (strcmp (attrs [i], "name") == 0)
	{
	  name = attrs [i + 1];
	}
      else if (strcmp (attrs [i], "path") == 0)
	{
	  path = attrs [i + 1];
	}
      else if (strcmp (attrs [i], "port") == 0)
	{
	  port = str_to_int32 (attrs [i + 1], NULL, 10);
	  got_port = true;
	}
      else
	warning ("unknown attribute '%s' in 'module' element\n", attrs [i]);
    }
  if (! port)
    fatal (3, "missing 'port' attribute in 'module' element\n");
  if (! path)
    fatal (3, "missing 'path' attribute in 'module' element\n");

  sdata->module = sim_install_module (sdata->sim,
				      path,
				      port,
				      false); // mem_only

  sdata->skip_module = ! sdata->module;
}


static void sax_start_element (void *ref,
			       const xmlChar *name,
			       const xmlChar **attrs)
{
  sax_data_t *sdata = ref;

  if (xml_strcmp (name, "state") == 0)
    parse_state (sdata, (char **) attrs);
  else if (xml_strcmp (name, "ui") == 0)
    parse_ui (sdata, (char **) attrs);
  else if (xml_strcmp (name, "switch") == 0)
    parse_switch (sdata, (char **) attrs);
  else if (xml_strcmp (name, "chip") == 0)
    parse_chip (sdata, (char **) attrs);
  else if (xml_strcmp (name, "registers") == 0)
    parse_registers (sdata, (char **) attrs);
  else if (xml_strcmp (name, "reg") == 0)
    parse_reg (sdata, (char **) attrs);
  else if (xml_strcmp (name, "memory") == 0)
    parse_memory (sdata, (char **) attrs);
  else if (xml_strcmp (name, "loc") == 0)
    parse_loc (sdata, (char **) attrs);
  else if (xml_strcmp (name, "module") == 0)
    parse_module (sdata, (char **) attrs);
  else
    warning ("unknown element '%s'\n", name);
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
  sim_event (sim,
	     NULL,
	     event_restore_starting,
	     0,
	     0,
	     NULL);

  memset (& sdata, 0, sizeof (sdata));

  sdata.sim = sim;

  xmlSAXUserParseFile (& sax_handler,
		       & sdata,
		       fn);

  sim_event (sim,
	     NULL,
	     event_restore_completed,
	     0,
	     0,
	     NULL);
  sim_set_io_pause_flag (sim, false);
}
