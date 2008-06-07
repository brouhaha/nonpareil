/*
$Id$
Copyright 2006, 2007, 2008 Eric Smith <eric@brouhaha.com>

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

/*
 * This program uses libxml2, but does not attempt to free allocated
 * memory.  Since this program exits after processing one XML template,
 * we don't need to worry about it.
 */


#include <ctype.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <libxml/parser.h>
#include <libxml/tree.h>

#include "arch.h"
#include "util.h"


int arch;

char *obj_path = NULL;

#define MAX_BANK 2
#define MAX_ADDR 16384

typedef uint8_t bank_t;
typedef uint32_t bank_mask_t;
typedef uint16_t addr_t;
typedef uint16_t rom_word_t;

rom_word_t rom [MAX_BANK] [MAX_ADDR];


struct element_info
{
  struct element_info *next;
  xmlNode *element;
};

static struct element_info *deferred_unlink_list = NULL;


static void defer_unlink_element (xmlNode *element)
{
  struct element_info *ei;

  ei = alloc (sizeof (struct element_info));
  ei->next = deferred_unlink_list;
  ei->element = element;
  deferred_unlink_list = ei;
}


static void handle_deferred_unlink_elements (void)
{
  struct element_info *p;

  for (p = deferred_unlink_list; p; p = p -> next)
    xmlUnlinkNode (p->element);
}


void usage (FILE *f)
{
  fprintf (f, "%s:  Microcode-level calculator simulator\n",
	   nonpareil_release);
  fprintf (f, "Copyright 2006 Eric L. Smith\n");
  fprintf (f, "http://nonpareil.brouhaha.com/\n");
  fprintf (f, "\n");
  fprintf (f, "usage: %s xml-template [options]\n", progname);
  fprintf (f, "\n");
  fprintf (f, "Options:\n");
  fprintf (f, "  --obj <object-file>\n");
  fprintf (f, "  -o <output-file>\n");
}


xmlChar *get_attr_str (xmlNode *element, char *attr)
{
  xmlChar *attr_val;

  attr_val = xmlGetProp (element, (xmlChar *) attr);
  if (! attr_val)
    fatal (2, "'%s' element has no '%s' attribute\n", element->name, attr);
  return attr_val;
}


long get_attr_num (xmlNode *element, char *attr, int default_base)
{
  xmlChar *attr_val;
  char *endptr;
  long val;

  attr_val = get_attr_str (element, attr);
  val = strtol ((char *) attr_val, & endptr, default_base);

  return val;
}


void init_rom (void)
{
  int bank;
  int addr;

  for (bank = 0; bank < MAX_BANK; bank++)
    for (addr = 0; addr < MAX_ADDR; addr++)
      rom [bank] [addr] = 0xffff;  // mark as unknown
}


static bool parse_octal (char *oct, int digits, int *val)
{
  *val = 0;

  while (digits--)
    {
      if (((*oct) < '0') || ((*oct) > '7'))
	return (false);
      (*val) = ((*val) << 3) + ((*(oct++)) - '0');
    }
  return (true);
}


static bool parse_hex (char *hex, int digits, int *val)
{
  *val = 0;
  int d;

  while (digits--)
    {
      if (! isxdigit (*hex))
	return (false);
      if ((*hex) <= '9')
	d = *hex - '0';
      else if ((*hex) >= 'a')
	d = 10 + *hex - 'a';
      else
	d = 10 + *hex - 'A';
      (*val) = ((*val) << 4) + d;
      hex++;
    }
  return (true);
}


static bool classic_parse_object_line (char        *buf,
				       bank_mask_t *bank_mask,
				       addr_t      *addr,
				       rom_word_t  *opcode)
{
  int a, o;

  if (buf [0] == '#')  /* comment? */
    return (false);

  if (strlen (buf) != 9)
    return (false);

  if (buf [4] != ':')
    {
      fprintf (stderr, "invalid object file format\n");
      return (false);
    }

  if (! parse_octal (& buf [0], 4, & a))
    {
      fprintf (stderr, "invalid address %o\n", a);
      return (false);
    }

  if (! parse_octal (& buf [5], 4, & o))
    {
      fprintf (stderr, "invalid opcode %o\n", o);
      return (false);
    }

  *bank_mask = 1;
  *addr = a;
  *opcode = o;
  return (true);
}


static bool woodstock_parse_object_line (char        *buf,
					 bank_mask_t *bank_mask,
					 addr_t      *addr,
					 rom_word_t  *opcode)
{
  int a, b, o;

  if (buf [0] == '#')  /* comment? */
    return (false);

  if (buf [0] == '[')  // banks?
    {
      *bank_mask = 0;
      buf++;
      while ((*buf) != ']')
	{
	  if (! parse_octal (buf, 1, & b))
	    {
	      fprintf (stderr, "invalid bank in object line '%s'\n", buf);
	      return false;
	    }
	  buf++;
	  *bank_mask |= (1 << b);
	}
      buf++;
    }
  else
    *bank_mask = (1 << MAX_BANK) - 1;

  if ((strlen (buf) < 9) || (strlen (buf) > 10))
    return (false);

  if (buf [4] != ':')
    {
      fprintf (stderr, "invalid object file format '%s'\n", buf);
      return (false);
    }

  if (! parse_octal (& buf [0], 4, & a))
    {
      fprintf (stderr, "invalid address in object line '%s'\n", buf);
      return (false);
    }

  if (! parse_octal (& buf [5], 4, & o))
    {
      fprintf (stderr, "invalid opcode in object line '%s'\n", buf);
      return (false);
    }

  *addr = a;
  *opcode = o;
  return (true);
}


static bool nut_parse_object_line (char        *buf,
				   bank_mask_t *bank_mask,
				   addr_t      *addr,
				   rom_word_t  *opcode)
{
  int a, b, o;

  if (buf [0] == '#')  /* comment? */
    return (false);

  if (buf [0] == '[')  // banks?
    {
      *bank_mask = 0;
      buf++;
      while ((*buf) != ']')
	{
	  if (! parse_octal (buf, 1, & b))
	    {
	      fprintf (stderr, "invalid bank in object line '%s'\n", buf);
	      return false;
	    }
	  buf++;
	  *bank_mask |= (1 << b);
	}
      buf++;
    }
  else
    *bank_mask = (1 << MAX_BANK) - 1;

  if (strlen (buf) != 8)
    return (false);

  if (buf [4] != ':')
    {
      fprintf (stderr, "invalid object file format '%s'\n", buf);
      return (false);
    }

  if (! parse_hex (& buf [0], 4, & a))
    {
      fprintf (stderr, "invalid address in object line '%s'\n", buf);
      return (false);
    }

  if (! parse_hex (& buf [5], 3, & o))
    {
      fprintf (stderr, "invalid opcode in object line '%s'\n", buf);
      return (false);
    }

  *addr = a;
  *opcode = o;
  return (true);
}


void read_object_file (char *fn)
{
  char *fn2;
  FILE *f;
  bank_mask_t bank_mask;
  bank_t bank;
  addr_t addr;
  rom_word_t opcode;
  bool ok;
  char buf [80];

  fn2 = find_file_in_path_list (fn, NULL, obj_path);
  if (! fn2)
    fatal (2, "can't open object file '%s'\n", fn);

  f = fopen (fn2, "r");
  if (! f)
    fatal (2, "can't open object file '%s'\n", fn);

  while (fgets (buf, sizeof (buf), f))
    {
      trim_trailing_whitespace (buf);
      if (! buf [0])
	continue;
      switch (arch)
	{
	case ARCH_CLASSIC:
	  ok = classic_parse_object_line (buf, & bank_mask, & addr, & opcode);
	  break;
	case ARCH_WOODSTOCK:
	  ok = woodstock_parse_object_line (buf, & bank_mask, & addr, & opcode);
	  break;
	case ARCH_NUT:
	  ok = nut_parse_object_line (buf, & bank_mask, & addr, & opcode);
	  break;
	default:
	  fatal (3, "unrecognized or unsupported architecture %d\n", arch);
	}
      if (ok)
	{
	  for (bank = 0; bank < MAX_BANK; bank++)
	    if (bank_mask & (1 << bank))
	      rom [bank] [addr] = opcode;
	}
    }

  fclose (f);
}


typedef void node_iter_fn_t (xmlNode *element);

void iterate_named_elements (xmlNode *parent_element,
			     char *element_name,
			     node_iter_fn_t *fn)
{
  xmlNode *cur_node;

  for (cur_node = parent_element->children; cur_node; cur_node = cur_node->next)
    if ((cur_node->type == XML_ELEMENT_NODE) &&
	(strcmp ((char *) cur_node->name, element_name) == 0))
      fn (cur_node);
}


void handle_obj_file_element (xmlNode *element)
{
  xmlChar *addr_space_str;
  xmlChar *obj_fn;

  addr_space_str = get_attr_str (element, "addr_space");
  obj_fn = xmlNodeGetContent (element);
  if (! obj_fn)
    fatal (2, "no content\n");
  //printf ("obj_file '%s', addr_space '%s'\n", obj_fn, addr_space_str);

  strip_whitespace (obj_fn);

  // $$$ check that the address space exists!
  if (strcmp ((char *) addr_space_str, "inst") != 0)
    fatal (2, "only 'inst' address space is supported\n");

  read_object_file ((char *) obj_fn);

  defer_unlink_element (element);
}

void handle_memory_element (xmlNode *element)
{
  xmlChar *addr_space_str;
  xmlChar *banks_str;
  long base_addr;
  long size;
  addr_t addr;
  //bank_mask_t *bank_mask;
  bank_t bank;

  addr_space_str = get_attr_str (element, "addr_space");

  // Don't care about data memory, only instructions
  if (strcmp (addr_space_str, "inst") != 0)
    return;

  banks_str = get_attr_str (element, "banks");
  base_addr = get_attr_num (element, "base_addr", 0);
  size = get_attr_num (element, "size", 0);

  //printf ("memory: addr space '%s', banks '%s', base_addr %ld, size %ld\n",
  //	  addr_space_str, banks_str, base_addr, size);

  bank = banks_str [0] - '0';  // $$$ ugly hack

  for (addr = base_addr; addr < base_addr + size; addr++)
    {
      xmlNode *loc_node;
      xmlAttr *addr_attr;
      xmlAttr *data_attr;
      char addr_str [6];
      char data_str [6];

      if (rom [bank] [addr] == 0xffff)
	fatal (4, "uninitialized ROM at bank %d addr %04o\n", bank, addr);

      // $$$ check that values for all banks we care about match

      sprintf (addr_str, "0%04o", addr);
      sprintf (data_str, "0%04o", rom [bank] [addr]);
      
      loc_node = xmlNewChild (element, NULL, (xmlChar *) "loc", NULL);
      addr_attr = xmlNewProp (loc_node, (xmlChar *) "addr", (xmlChar *) addr_str);
      data_attr = xmlNewProp (loc_node, (xmlChar *) "data", (xmlChar *) data_str);
    }
}


void handle_chip_element (xmlNode *element)
{
  iterate_named_elements (element,
			  "memory",
			  & handle_memory_element);
}


int main (int argc, char *argv[])
{
  char *tmpl_fn = NULL;
  char *dest_fn = NULL;
  xmlDoc *doc = NULL;
  xmlNode *root_element = NULL;
  xmlChar *arch_str;

  progname = newstr (argv [0]);

  while (--argc)
    {
      argv++;
      if (*argv [0] == '-')
	{
	  if (strcasecmp (argv [0], "--obj-path") == 0)
	    {
	      if (argc < 1)
		fatal (1, "--obj option requires argument\n");
	      obj_path = *++argv;
	      --argc;
	    }
	  else if (strcasecmp (argv [0], "-o") == 0)
	    {
	      if (argc < 1)
		fatal (1, "-o option requires argument\n");
	      dest_fn = *++argv;
	      --argc;
	    }
	  else
	    fatal (1, "unrecognized option '%s'\n", argv [0]);
	}
      else if (! tmpl_fn)
	tmpl_fn = argv [0];
      else
	fatal (1, "Only one XML template may be provided\n");
    }

  if (! tmpl_fn)
    fatal (1, "XML template must be provided\n");
  if (! dest_fn)
    fatal (1, "destination filename must be provided\n");

  //printf ("arguments OK!\n");
  //printf ("tmpl_fn = '%s'\n", tmpl_fn);
  //printf ("dest_fn = '%s'\n", dest_fn);
  //if (obj_path)
  //  printf ("obj_path = '%s'\n", obj_path);

  init_rom ();

  doc = xmlReadFile (tmpl_fn, NULL, 0);
  if (! doc)
    fatal (2, "xmlReadFile failed\n");

  root_element = xmlDocGetRootElement (doc);

  arch_str = xmlGetProp (root_element, (xmlChar *) "arch");
  if (! arch_str)
    fatal (2, "no arch attribute\n");

  arch = find_arch_by_name ((char *) arch_str);
  switch (arch)
    {
    case ARCH_CLASSIC:
    case ARCH_WOODSTOCK:
    case ARCH_NUT:
      break;
    default:
      fatal (3, "unrecognized or unsupported architecture '%s'\n", arch_str);
    }

  //printf ("arch '%s' = %d\n", arch_str, arch);
  
  iterate_named_elements (root_element,
			  "obj_file",
			  & handle_obj_file_element);

  iterate_named_elements (root_element,
			  "chip",
			  & handle_chip_element);

  handle_deferred_unlink_elements ();

  xmlSetDocCompressMode (doc, 9);
  xmlSaveFormatFileEnc (dest_fn, doc, "UTF-8", 1);

  xmlFreeDoc (doc);
  xmlCleanupParser ();

  exit (0);
}
