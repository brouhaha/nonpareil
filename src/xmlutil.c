/*
$Id$
Copyright 2008 Eric Smith <eric@brouhaha.com>

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

#include <libxml/xmlwriter.h>

#include "util.h"
#include "xmlutil.h"

void xml_start_element (xmlTextWriterPtr writer, char *element_name)
{
  if (xmlTextWriterStartElement (writer, BAD_CAST element_name) < 0)
    fatal (2, "can't start element\n");
}


void xml_end_element (xmlTextWriterPtr writer)
{
  if (xmlTextWriterEndElement (writer) < 0)
    fatal (2, "can't end element\n");
}


void xml_write_element_string (xmlTextWriterPtr writer,
			       char *element_name,
			       char *value)
{
  if (xmlTextWriterWriteElement (writer,
				 BAD_CAST element_name, 
				 BAD_CAST value) < 0)
    fatal (2, "can't write element\n");
}


void xml_write_string_vformat (xmlTextWriterPtr writer,
			       char *format,
			       va_list ap)
{
  if (xmlTextWriterWriteVFormatString (writer, format, ap) < 0)
    fatal (2, "can't write string\n");
}


void xml_write_string_format (xmlTextWriterPtr writer,
			      char *format,
			      ...)
{
  va_list ap;
  va_start (ap, format);
  xml_write_string_vformat (writer, format, ap);
  va_end (ap);
}


void xml_write_attribute_vformat (xmlTextWriterPtr writer,
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


void xml_write_attribute_format (xmlTextWriterPtr writer,
				 char *attribute_name,
				 char *format,
				 ...)
{
  va_list ap;
  va_start (ap, format);
  xml_write_attribute_vformat (writer, attribute_name, format, ap);
  va_end (ap);
}


void xml_write_attribute_string (xmlTextWriterPtr writer,
				 char *attribute_name,
				 char *value)
{
  if (xmlTextWriterWriteAttribute (writer, 
				   BAD_CAST attribute_name, 
				   BAD_CAST value) < 0)
    fatal (2, "can't write element\n");
}


xmlTextWriterPtr xml_write_document (char *fn,
				     char *name,
				     char *dtd_url,
				     int compression)
{
  xmlOutputBufferPtr out;
  xmlTextWriterPtr writer;

  out = xmlOutputBufferCreateFilename (fn,
				       NULL,
				       compression);
  if (! out)
    fatal (2, "can't open output file\n");

  writer = xmlNewTextWriter (out);
  if (! writer)
    fatal (2, "can't open output file\n");

  if (xmlTextWriterStartDocument (writer,
				  NULL,       // XML version (default 1.0)
				  "UTF-8",    // encoding (default UTF-8)
				  "no") < 0)  // standalone
    fatal (2, "can't start document\n");

  if (xmlTextWriterWriteDTD (writer,
			     BAD_CAST name,     // name
			     NULL,              // putid
			     BAD_CAST dtd_url,  // sysid
			     NULL) < 0)
    fatal (2, "can't write DTD\n"); 

  return writer;
}


int xml_strcmp (const xmlChar *s1, const char *s2)
{
  const char *s1c = (const char *) s1;
  return strcmp (s1c, s2);
}


xmlEntityPtr sax_get_entity (void *ref UNUSED,
			     const xmlChar *name)
{
  return xmlGetPredefinedEntity (name);
}


void sax_warning (void *ref UNUSED,
		  const char *msg,
		  ...)
{
  va_list ap;

  va_start (ap, msg);
  fprintf (stderr, "XML warning: ");
  vfprintf (stderr, msg, ap);
  va_end (ap);
}


void sax_error (void *ref UNUSED,
		const char *msg,
		...)
{
  va_list ap;

  va_start (ap, msg);
  fprintf (stderr, "XML error: ");
  vfprintf (stderr, msg, ap);
  va_end (ap);
}


void sax_fatal_error (void *ref UNUSED,
		      const char *msg,
		      ...)
{
  va_list ap;

  va_start (ap, msg);
  fprintf (stderr, "XML fatal error: ");
  vfprintf (stderr, msg, ap);
  va_end (ap);
}
