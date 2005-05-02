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
#include "nsim_conv.h"


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


#undef WRITE_RANDOM_MEM
#ifdef WRITE_RANDOM_MEM
static uint64_t get_random_data ()
{
  static uint64_t val = 0xfeeddeadbeefedull;
  int a;

  a = (((val & 0x80000000000000ull) != 0) ^
       ((val & 0x00000000000001ull) != 0));
  val = ((val << 1) | a) & 0xffffffffffffffull;

  return val;
}
#endif

static void write_mem (xmlTextWriterPtr writer,
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


void state_write_xml (char *fn)
{
  int i;
  xmlOutputBufferPtr out;
  xmlTextWriterPtr writer;

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

  if (xmlTextWriterWriteDTD (writer,
                             BAD_CAST "state",           // name
			     NULL,                       // pubid
			     BAD_CAST "nonpareil.dtd",   // sysid
                             NULL) < 0)                  // subset
    fatal (2, "can't write DTD\n");

  xml_start_element (writer, "state");
  xml_write_attribute_string (writer, "version", "1.00");

  xml_write_attribute_string (writer, "arch", "nut");
  xml_write_attribute_string (writer, "platform", "coconut");
  xml_write_attribute_string (writer, "model", "41cv");

  xml_start_element (writer, "registers");

  write_reg (writer, "a",          -1, "%014" PRIx64, regs.a);
  write_reg (writer, "b",          -1, "%014" PRIx64, regs.b);
  write_reg (writer, "c",          -1, "%014" PRIx64, regs.c);
  write_reg (writer, "m",          -1, "%014" PRIx64, regs.m);
  write_reg (writer, "n",          -1, "%014" PRIx64, regs.n);
  write_reg (writer, "g",          -1, "%02"  PRIx64, regs.g);
  write_reg (writer, "p",          -1, "%01"  PRIx64, regs.p);
  write_reg (writer, "q",          -1, "%01"  PRIx64, regs.q);
  write_reg (writer, "q_selected", -1, "%d",  regs.q_selected);
  write_reg (writer, "status",     -1, "%04"  PRIx64, regs.status);
  write_reg (writer, "pc",         -1, "%01"  PRIx64, regs.pc);

  for (i = 0; i < 4; i++)
    write_reg (writer, "stack", i, "%04x", regs.stack [i]);

  write_reg (writer, "awake",   -1, "%d", regs.awake);
  write_reg (writer, "carry",   -1, "%d", regs.carry);
  write_reg (writer, "decimal", -1, "%d", regs.decimal);

  xml_end_element (writer);  // registers

  xml_start_element (writer, "memory");
  xml_write_attribute_string (writer, "as", "ram");

  for (i = 0; i < MAX_RAM; i++)
    {
      if (ram_used [i])
	write_mem (writer, i, "%014" PRIx64, ram [i]);
    }

  xml_end_element (writer);  // memory

  xml_start_element (writer, "periph");
  xml_write_attribute_format (writer, "addr", "%02x", LCD_PERIPH_ADDR);

  write_reg (writer, "enable", -1, "%d",          regs.lcd.enable);
  write_reg (writer, "a",      -1, "%012" PRIx64, regs.lcd.a);
  write_reg (writer, "b",      -1, "%012" PRIx64, regs.lcd.b);
  write_reg (writer, "c",      -1, "%012" PRIx64, regs.lcd.c);
  write_reg (writer, "ann",    -1, "%03"  PRIx64, regs.lcd.ann);

  xml_end_element (writer);  // periph

  xml_end_element (writer);  // state

  if (xmlTextWriterEndDocument (writer) < 0)
    fatal (2, "can't end document\n");

  xmlFreeTextWriter (writer);
}


