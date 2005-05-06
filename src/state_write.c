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

#include <libxml/xmlwriter.h>

#include "util.h"
#include "display.h"
#include "proc.h"
#include "arch.h"
#include "platform.h"
#include "model.h"
#include "state_io.h"


static void xml_start_element (xmlTextWriterPtr writer, char *element_name)
{
  if (xmlTextWriterStartElement (writer, BAD_CAST element_name) < 0)
    fatal (2, "can't start element\n");
}


static void xml_end_element (xmlTextWriterPtr writer)
{
  if (xmlTextWriterEndElement (writer) < 0)
    fatal (2, "can't end element\n");
}


#if 0
static void xml_write_element_string (xmlTextWriterPtr writer,
				      char *element_name,
				      char *value)
{
  if (xmlTextWriterWriteElement (writer,
				 BAD_CAST element_name, 
				 BAD_CAST value) < 0)
    fatal (2, "can't write element\n");
}


static void xml_write_string_vformat (xmlTextWriterPtr writer,
				      char *format,
				      va_list ap)
{
  if (xmlTextWriterWriteVFormatString (writer, format, ap) < 0)
    fatal (2, "can't write string\n");
}


static void xml_write_string_format (xmlTextWriterPtr writer,
				     char *format,
				     ...)
{
  va_list ap;
  va_start (ap, format);
  xml_write_string_vformat (writer, format, ap);
  va_end (ap);
}
#endif


static void xml_write_attribute_vformat (xmlTextWriterPtr writer,
					 char *attribute_name,
					 char *format,
					 va_list ap)
{
  if (xmlTextWriterWriteVFormatAttribute (writer,
					  BAD_CAST attribute_name,
					  format,
					  ap) < 0)
    fatal (2, "can't write string\n");
}


static void xml_write_attribute_format (xmlTextWriterPtr writer,
					char *attribute_name,
					char *format,
					...)
{
  va_list ap;
  va_start (ap, format);
  xml_write_attribute_vformat (writer, attribute_name, format, ap);
  va_end (ap);
}


static void xml_write_attribute_string (xmlTextWriterPtr writer,
					char *attribute_name,
					char *value)
{
  if (xmlTextWriterWriteAttribute (writer, 
				   BAD_CAST attribute_name, 
				   BAD_CAST value) < 0)
    fatal (2, "can't write element\n");
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
    xml_write_attribute_format (writer, "index", "%d", index);
  va_start (ap, format);
  xml_write_attribute_vformat (writer, "data", format, ap);
  va_end (ap);
  xml_end_element (writer);  // reg
}


static void write_registers (sim_t *sim, int chip, xmlTextWriterPtr writer)
{
  int reg_count;
  int reg_num;
  int index;
  reg_info_t *reg_info;
  uint64_t val;
  int digits;

  reg_count = sim_get_reg_count (sim, chip);
  if (! reg_count)
    return;

  xml_start_element (writer, "registers");

  for (reg_num = 0; reg_num < reg_count; reg_num++)
    {
      reg_info = sim_get_register_info (sim, chip, reg_num);
      for (index = 0; index < reg_info->array_element_count; index++)
	{
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


static void write_chips (sim_t *sim, xmlTextWriterPtr writer)
{
  int chip_count;
  int register_count;
  int chip_num;

  chip_count = sim_get_max_chip_count (sim);

  for (chip_num = 0; chip_num < chip_count; chip_num++)
    {
      chip_info_t *chip_info;
      chip_info = sim_get_chip_info (sim, chip_num);
      register_count = sim_get_reg_count (sim, chip_num);
      if (chip_info && register_count)
	{
	  xml_start_element (writer, "chip");
	  xml_write_attribute_string (writer, "name", chip_info->name);
	  xml_write_attribute_format (writer, "addr", "%02x", chip_num);
	  write_registers (sim, chip_num, writer);
	  xml_end_element (writer);  // chip
	}
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
  uint64_t data;
  xml_start_element (writer, "memory");

  xml_write_attribute_string (writer, "as", "ram");

  for (addr = 0; addr < MAX_RAM; addr++)
    {
      if (sim_read_ram (sim, addr, & data))
	write_mem_loc (writer, addr, "%014" PRIx64, data);
    }

  xml_end_element (writer);  // memory
}


void state_write_xml (sim_t *sim, char *fn)
{
  xmlOutputBufferPtr out;
  xmlTextWriterPtr writer;

  model_info_t *model_info;
  arch_info_t *arch_info;

  // LIBXML_TEST_VERSION

#if 1
  out = xmlOutputBufferCreateFilename (fn, NULL, true);

  writer = xmlNewTextWriter (out);
  if (! writer)
    fatal (2, "can't open output file\n");
#else
  writer = xmlNewTextWriterFilename ("foo.xml", 0);
  if (! writer)
    fatal (2, "can't open output file\n");
#endif

  if (xmlTextWriterStartDocument (writer, NULL, "ISO-8859-1", NULL) < 0)
    fatal (2, "can't start document\n");

  model_info = get_model_info (sim_get_model (sim));

  if (xmlTextWriterWriteDTD (writer,
                             BAD_CAST "state",           // name
			     NULL,                       // pubid
			     BAD_CAST "nonpareil.dtd",   // sysid
                             NULL) < 0)                  // subset
    fatal (2, "can't write DTD\n");

  xml_start_element (writer, "state");
  xml_write_attribute_string (writer, "version", "1.00");

  arch_info = get_arch_info (model_info->cpu_arch);

  xml_write_attribute_string (writer, "model", model_info->name);
  xml_write_attribute_string (writer, "platform", platform_name [model_info->platform]);
  xml_write_attribute_string (writer, "arch", arch_info->name);

  write_chips (sim, writer);
  write_memory (sim, writer);

  xml_end_element (writer);  // state

  if (xmlTextWriterEndDocument (writer) < 0)
    fatal (2, "can't end document\n");

  xmlFreeTextWriter (writer);
}


