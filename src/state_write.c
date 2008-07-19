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

#include <gdk/gdk.h>
#include <gtk/gtk.h>

#include <gsf/gsf-infile.h>

#include <libxml/xmlwriter.h>

#include "util.h"
#include "xmlutil.h"
#include "display.h"
#include "kml.h"
#include "chip.h"
#include "proc.h"
#include "state_io.h"


static void write_slide_switches (sim_t *sim,
				  xmlTextWriterPtr writer)
{
  int switch_number;
  uint8_t switch_position;

  for (switch_number = 0; switch_number < KML_MAX_SWITCH; switch_number++)
    if (sim_get_switch (sim, switch_number, & switch_position))
      {
	xml_start_element (writer, "switch");
	xml_write_attribute_format (writer, "number", "%x", switch_number);
	xml_write_attribute_format (writer, "position", "%x", switch_position);
	xml_end_element (writer);  // switch
      }
}


static void write_ui (sim_t *sim, xmlTextWriterPtr writer)
{
  xml_start_element (writer, "ui");
  write_slide_switches (sim, writer);
  xml_end_element (writer);  // ui
}


static void write_reg (xmlTextWriterPtr writer,
		       char *name,
		       int index,
		       char *format,
		       ...)
{
  va_list ap;
  xml_start_element (writer, "reg");
  xml_write_attribute_string (writer, "name", name);
  if (index >= 0)
    xml_write_attribute_format (writer, "index", "%x", index);
  va_start (ap, format);
  xml_write_attribute_vformat (writer, "data", format, ap);
  va_end (ap);
  xml_end_element (writer);  // reg
}


static void write_registers (sim_t *sim,
			     chip_t *chip,
			     int first_reg,
			     int last_reg,
			     xmlTextWriterPtr writer)
{
  int reg_num;

  xml_start_element (writer, "registers");

  for (reg_num = first_reg; reg_num <= last_reg; reg_num++)
    {
      int index;
      const reg_info_t *reg_info = sim_get_register_info (sim, chip, reg_num);

      for (index = 0; index < reg_info->array_element_count; index++)
	{
	  uint64_t val;
	  int digits;

	  if (! sim_read_register (sim, chip, reg_num, index, & val))
	    fatal (3, "error reading register from sim\n");
	  digits = (reg_info->element_bits + 3) / 4;
	  write_reg (writer,
		     reg_info->name,
		     reg_info->array_element_count > 1 ? index : -1,
		     "%0*" PRIx64,
		     digits,
		     val);
	}
    }
  
  xml_end_element (writer);  // registers
}


static void write_chip_address (sim_t *sim,
				chip_t *chip,
				xmlTextWriterPtr writer)
{
  const reg_info_t *reg_info;
  uint64_t val;
  int digits;

  reg_info = sim_get_register_info (sim, chip, 0);
  if (! reg_info)
    fatal (3, "error getting chip address from sim\n");

  if (! sim_read_register (sim, chip, 0, 0, & val))
    fatal (3, "error getting chip address from sim\n");

  digits = (reg_info->element_bits + 3) / 4;

  xml_write_attribute_format (writer, "addr", "%0*" PRIx64, digits, val);
}


static void write_chips (sim_t *sim, xmlTextWriterPtr writer)
{
  chip_t *chip = NULL;

  while ((chip = sim_get_next_chip (sim, chip)))
    {
      int first_reg = 0;
      int register_count;
      const chip_info_t *chip_info;

      chip_info = sim_get_chip_info (sim, chip);
      if (! chip_info)
	break;
      xml_start_element (writer, "chip");
      xml_write_attribute_string (writer, "name", chip_info->name);

      if (chip_info->multiple)
	{
	  write_chip_address (sim, chip, writer);
	  first_reg = 1;
	}

      register_count = sim_get_reg_count (sim, chip);
      if (register_count)
	write_registers (sim,
			 chip,
			 first_reg,
			 register_count - 1,  // last_reg
			 writer);
      xml_end_element (writer);  // chip
    }
}


static void write_mem_loc (xmlTextWriterPtr writer,
			   int addr,
			   char *format,
			   ...)
{
  va_list ap;
  xml_start_element (writer, "loc");
  xml_write_attribute_format (writer, "addr", "%03x", addr);
#ifdef WRITE_RANDOM_MEM
  xml_write_attribute_format (writer, "data", "%014" PRIx64, get_random_data());
#else
  va_start (ap, format);
  xml_write_attribute_vformat (writer, "data", format, ap);
  va_end (ap);
#endif
  xml_end_element (writer);  // loc
}


static void write_memory (sim_t *sim, xmlTextWriterPtr writer)
{
  addr_t addr;
  addr_t max_ram;
  uint64_t data;

  max_ram = sim_get_max_ram_addr (sim);

  xml_start_element (writer, "memory");

  xml_write_attribute_string (writer, "as", "ram");

  for (addr = 0; addr < max_ram; addr++)
    {
      if (sim_read_ram (sim, addr, & data))
	write_mem_loc (writer, addr, "%014" PRIx64, data);
    }

  xml_end_element (writer);  // memory
}


void state_write_xml (sim_t *sim, char *fn)
{
  xmlTextWriterPtr writer;

  // LIBXML_TEST_VERSION

  sim_set_io_pause_flag (sim, true);
  sim_event (sim,
	     NULL,
	     event_save_starting,
	     0,
	     0,
	     NULL);

  writer = xml_write_document (fn,
			       "state",
			       "http://nonpareil.brouhaha.com/dtd/state-1.0.dtd",
			       9);  // max compression

  xml_start_element (writer, "state");
  xml_write_attribute_string (writer, "version", "1.0");

  xml_write_attribute_string (writer, "ncd", sim_get_ncd_fn (sim));

  write_ui (sim, writer);
  write_chips (sim, writer);
  write_memory (sim, writer);

  xml_end_element (writer);  // state

  if (xmlTextWriterEndDocument (writer) < 0)
    fatal (2, "can't end document\n");

  xmlFreeTextWriter (writer);

  sim_event (sim,
	     NULL,
	     event_save_completed,
	     0,
	     0,
	     NULL);
  sim_set_io_pause_flag (sim, false);
}


