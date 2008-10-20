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

void xml_start_element (xmlTextWriterPtr writer,
			const char *element_name);

void xml_end_element (xmlTextWriterPtr writer);

void xml_write_element_string (xmlTextWriterPtr writer,
			       const char *element_name,
			       const char *value);

void xml_write_string_vformat (xmlTextWriterPtr writer,
			       const char *format,
			       va_list ap);

void xml_write_string_format (xmlTextWriterPtr writer,
			      const char *format,
			      ...);

void xml_write_attribute_vformat (xmlTextWriterPtr writer,
				  const char *attribute_name,
				  const char *format,
				  va_list ap);

void xml_write_attribute_format (xmlTextWriterPtr writer,
				 const char *attribute_name,
				 const char *format,
				 ...);

void xml_write_attribute_string (xmlTextWriterPtr writer,
				 const char *attribute_name,
				 const char *value);

xmlTextWriterPtr xml_write_document (const char *fn,
				     const char *name,
				     const char *dtd_url,
				     const int compression);  // 0-9, 0 = none


int xml_strcmp (const xmlChar *s1, const char *s2);

xmlEntityPtr sax_get_entity (void *ref UNUSED,
			     const xmlChar *name);

void sax_warning (void *ref,
		  const char *msg,
		  ...);

void sax_error (void *ref,
		const char *msg,
		...);

void sax_fatal_error (void *ref,
		      const char *msg,
		      ...);
