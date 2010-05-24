/*
$Id$
Copyright 2005, 2006, 2008, 2010 Eric Smith <eric@brouhaha.com>

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
#include "keyboard.h"
#include "kml.h"
#include "chip.h"
#include "calcdef.h"
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


static void write_chips (sim_t *sim,
			 plugin_module_t *module,
			 xmlTextWriterPtr writer)
{
  chip_t *chip = NULL;

  while ((chip = sim_get_next_chip (sim, chip)))
    {
      int first_reg = 0;
      int register_count;
      const chip_info_t *chip_info;

      if (chip_get_module (chip) != module)
	continue;

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
			   bool has_bank,
			   bank_t bank,
			   int addr,
			   char *format,
			   ...)
{
  va_list ap;
  xml_start_element (writer, "loc");
  if (has_bank)
    xml_write_attribute_format (writer, "bank", "%d", bank);
  xml_write_attribute_format (writer, "addr", "%03x", addr);
  va_start (ap, format);
  xml_write_attribute_vformat (writer, "data", format, ap);
  va_end (ap);
  xml_end_element (writer);  // loc
}


static void write_ram (sim_t *sim,
		       plugin_module_t *module,
		       xmlTextWriterPtr writer)
{
  addr_t addr;
  addr_t max_ram;
  uint64_t data;

  // $$$ need to add support for module RAM
  if (module)
    return;

  max_ram = sim_get_max_ram_addr (sim);

  xml_start_element (writer, "memory");

  xml_write_attribute_string (writer, "as", "ram");

  for (addr = 0; addr < max_ram; addr++)
    {
      if (sim_read_ram (sim, addr, & data))
	write_mem_loc (writer, false, 0, addr, "%014" PRIx64, data);
    }

  xml_end_element (writer);  // memory
}


static void write_rom (sim_t *sim,
		       plugin_module_t *module,
		       xmlTextWriterPtr writer)
{
  int page, max_page;
  int page_size;
  int bank, max_bank;
  addr_t addr;
  rom_word_t data;
  plugin_module_t *m2;
  bool ram;
  bool write_enable;

  // don't write mainframe ROM to state file
  if (! module)
    return;

  max_bank = sim_get_max_rom_bank (sim);
  page_size = sim_get_rom_page_size (sim);
  max_page = sim_get_max_rom_addr (sim) / page_size;

  for (page = 0; page < max_page; page++)
    for (bank = 0; bank < max_bank; bank++)
      if (sim_get_page_info (sim, bank, page, & m2, & ram, & write_enable) &&
	  (m2 == module) &&
	  ram)
	{
	  xml_start_element (writer, "memory");
	  xml_write_attribute_string (writer, "as", "rom");
	  xml_write_attribute_format (writer, "write_enable", "%d", write_enable);
	  xml_write_attribute_format (writer, "bank", "%d", bank);
	  xml_write_attribute_format (writer, "addr", "%04x", page * page_size);
	  for (addr = page * page_size; addr < ((page + 1) * page_size); addr++)
	    {
	      if (sim_read_rom (sim, bank, addr, & data))
		write_mem_loc (writer, true, bank, addr, "%03x", data);
	    }
	  xml_end_element (writer);  // memory
	}
}


static void write_memory (sim_t *sim,
			  plugin_module_t *module,
			  xmlTextWriterPtr writer)
{
  write_ram (sim, module, writer);
  write_rom (sim, module, writer);
}


static void write_modules (sim_t *sim, xmlTextWriterPtr writer)
{
  plugin_module_t *module = NULL;

  while ((module = sim_get_next_module (sim, module)))
    {
      xml_start_element (writer, "module");
      xml_write_attribute_format (writer,
				  "port",
				  "%d", 
				  plugin_module_get_port (module));
      xml_write_attribute_string (writer,
				  "name",
				  plugin_module_get_name (module));
      xml_write_attribute_string (writer,
				  "path",
				  plugin_module_get_path (module));
      write_chips (sim, module, writer);
      write_memory (sim, module, writer);
      xml_end_element (writer);  // module
    }
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
  write_chips (sim, NULL, writer);
  write_memory (sim, NULL, writer);
  write_modules (sim, writer);

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


