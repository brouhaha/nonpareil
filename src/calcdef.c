/*
$Id$
Copyright 2006, 2008, 2010 Eric Smith <eric@brouhaha.com>

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

#include <ctype.h>
#include <inttypes.h>
#include <stdbool.h>
#include <stdint.h>
#include <string.h>

#include <libxml/SAX.h>
#include <libxml/xmlwriter.h>

#include "util.h"
#include "xmlutil.h"
#include "display.h"
#include "keyboard.h"
#include "chip.h"
#include "calcdef.h"
#include "proc.h"
#include "arch.h"
#include "platform.h"
#include "proc_int.h"


static xmlSAXHandler sax_handler;


typedef struct calcdef_mem_t
{
  struct calcdef_mem_t *next;
  char *addr_space;
  addr_t base_addr;
  addr_t size;
  bank_mask_t bank_mask;
  rom_word_t *data;
} calcdef_mem_t;


typedef struct
{
  bool bitmap;  // false for segments, true for bitmap
  int count;    // count of segments
  int id;       // temp during parsing
  segment_bitmap_t *char_gen;
} calcdef_char_gen_t;


typedef struct calcdef_chip_t
{
  struct calcdef_chip_t *next;
  chip_type_t type;
  char *id;
  int32_t index;
  int32_t flags;
  calcdef_mem_t *mem;
  struct chip_t *chip;
  calcdef_char_gen_t *char_gen;
} calcdef_chip_t;


typedef struct calcdef_flag_t
{
  struct calcdef_flag_t *next;
  char *chip_id;
  int number;
  int value;
} calcdef_flag_t;


typedef struct calcdef_switch_position_t
{
  struct calcdef_switch_position_t *next;
  int position;
  calcdef_flag_t *flag;
} calcdef_switch_position_t;


typedef struct calcdef_switch_t
{
  struct calcdef_switch_t *next;
  int number;
  calcdef_switch_position_t *position;
} calcdef_switch_t;


typedef struct calcdef_key_t
{
  char *chip_id;
  struct chip_t *chip;
  hw_keycode_t hw_keycode;
} calcdef_key_t;


struct calcdef_t
{
  sim_t *sim;
  char *ncd_copyright;
  char *ncd_license;
  char *model_name;
  int platform;
  int arch;
  int arch_variant;
  int ram_size;
  double clock_frequency;  // in Hz
  calcdef_chip_t *chip;
  calcdef_key_t **keyboard_map;
  calcdef_switch_t *sw;
};


static bank_mask_t parse_bank_mask (const char *s)
{
  bank_mask_t bank_mask = 0;
  while (*s)
    {
      int bank;
      char c = *(s++);
      if ((c >= '0') && (c <= '9'))
	bank = c - '0';
      else if ((c >= 'a') & (c <= 'f'))
	bank = 10 + c - 'a';
      else if ((c >= 'A') & (c <= 'F'))
	bank = 10 + c - 'A';
      else
	fatal (3, "invalid bank\n");
      bank_mask |= (1 << bank);
    }
  if (! bank_mask)
    fatal (3, "memory must be in at least one bank\n");
  return bank_mask;
}


static uint8_t parse_id (const char *s)
{
  unsigned long id;
  char *endptr = NULL;

  if (s [0] == '\'')
    {
      if ((s [1] != '\0') && (s [2] == '\'') && (s [3] == '\0'))
	id = s [1];
      else
	fatal (3, "invalid character literal '%s' in id\n", s);
    }
  else
    {
      id = strtoul (s, & endptr, 0);
      if (endptr && (*endptr != '\0'))
	fatal (3, "invalid character '%c' in id\n", *endptr);
    }

  return (uint8_t) id;
}

static void parse_segments (void *ref,
			    const xmlChar *ch,
			    int len)
{
  calcdef_t *calcdef = ref;
  uint32_t segment_bitmap = 0;
  int count = 0;

  while (len--)
    {
      char c = (char) *(ch++);
      if (isspace (c))
	continue;
      if ((c >= 'a') && (c <= 'z'))
	{
	  segment_bitmap |= (1 << (c - 'a'));
	  count++;
	}
      else if (c == '.')
	{
	  count++;
	}
      else
	fatal (3, "invalid character '%c' in segments\n", c);
    }
  if (count != calcdef->chip->char_gen->count)
    fatal (3, "char %02x incorrect segment count %d, should be %d\n", calcdef->chip->char_gen->id, count, calcdef->chip->char_gen->count);
  calcdef->chip->char_gen->char_gen [calcdef->chip->char_gen->id] = segment_bitmap;
}


static void parse_bitmap (void *ref,
			  const xmlChar *ch,
			  int len)
{
  calcdef_t *calcdef = ref;
  uint64_t bitmap = 0;
  int count = 0;

  while (len--)
    {
      char c = (char) *(ch++);
      if (isspace (c))
	continue;
      if (c == '.')
	{
	  bitmap <<= 1;
	  count++;
	}
      else if (c == '*')
	{
	  bitmap = (bitmap << 1) | 1;
	  count++;
	}
      else
	fatal (3, "invalid character '%c' in bitmap\n", c);
    }
  if (count != calcdef->chip->char_gen->count)
    fatal (3, "char %02x incorrect bitmap pixel count %d, should be %d\n", calcdef->chip->char_gen->id, count, calcdef->chip->char_gen->count);
  calcdef->chip->char_gen->char_gen [calcdef->chip->char_gen->id] = bitmap;
}


static void parse_calcdef (calcdef_t *calcdef,
			   const xmlChar **attrs)
{
  int i;
  bool got_version = false;
  bool got_arch = false;
  bool got_platform = false;
  bool got_model = false;

  for (i = 0; attrs && attrs [i]; i += 2)
    {
      if (strcmp ((char *) attrs [i], "version") == 0)
	{
	  if (strcmp ((char *) attrs [i + 1], "1.0") != 0)
	    warning ("Unrecognized version '%s' of NCD format\n",
		     attrs [i + 1]);
	  got_version = true;
	}
      else if (strcmp ((char *) attrs [i], "arch") == 0)
	{
	  calcdef->arch = find_arch_by_name ((char *) attrs [i + 1]);
	  if (calcdef->arch == ARCH_UNKNOWN)
	    fatal (3, "Unknown architecture %s\n", attrs [i + 1]);
	  got_arch = true;
	}
      else if (strcmp ((char *) attrs [i], "arch_variant") == 0)
	{
	  calcdef->arch_variant = atoi ((char *) attrs [i + 1]);
	}
      else if (strcmp ((char *) attrs [i], "platform") == 0)
	{
	  calcdef->platform = find_platform_by_name ((char *) attrs [i + 1]);
	  if (calcdef->platform == PLATFORM_UNKNOWN)
	    fatal (3, "Unknown platform %s\n", attrs [i + 1]);
	  got_platform = true;
	}
      else if (strcmp ((char *) attrs [i], "model") == 0)
	{
	  calcdef->model_name = newstr ((char *) attrs [i + 1]);
	  got_model = true;
	}
      else if (strcmp ((char *) attrs [i], "copyright") == 0)
	{
	  calcdef->ncd_copyright = newstr ((char *) attrs [i + 1]);
	}
      else if (strcmp ((char *) attrs [i], "license") == 0)
	{
	  calcdef->ncd_license = newstr ((char *) attrs [i + 1]);
	}
      else
	warning ("unknown attribute '%s' in 'loc' element\n", attrs [i]);
    }
  if (! got_version)
    warning ("calcdef element doesn't have version attribute\n");
  if (! got_arch)
    warning ("calcdef element doesn't have arch attribute\n");
  if (! got_platform)
    warning ("calcdef element doesn't have platform attribute\n");
  if (! got_model)
    warning ("calcdef element doesn't have model attribute\n");
}


static void parse_inst_clock (calcdef_t *calcdef,
			      const xmlChar **attrs)
{
  int i;
  bool got_freq = false;
  char *endptr = NULL;

  for (i = 0; attrs && attrs [i]; i += 2)
    {
      if (strcmp ((char *) attrs [i], "freq") == 0)
	{
	  calcdef->clock_frequency = strtod ((char *) attrs [i + 1], & endptr);
	  if (endptr && (*endptr != '\0'))
	    fatal (3, "invalid character '%c' in freq\n", *endptr);
	  got_freq = true;
	}
      else if (strcmp ((char *) attrs [i], "osc_type") == 0)
	{
	  ;  // we don't really care
	}
      else
	warning ("unknown attribute '%s' in 'loc' element\n", attrs [i]);
    }
  if (! got_freq)
    warning ("inst_clock element doesn't have freq attribute\n");
}


static void parse_keyboard (calcdef_t *calcdef UNUSED,
			    const xmlChar **attrs UNUSED)
{
  if (calcdef->keyboard_map)
    fatal (3, "only one keyboard element allowed per nui file\n");

  calcdef->keyboard_map = alloc (sizeof (calcdef_key_t *) *
				 (2 * MAX_KEYCODE + 1));

  // Note that because user keycodes can be negative, we offset
  // the base of the keyboard map.
  calcdef->keyboard_map += MAX_KEYCODE;
}


static void parse_key (calcdef_t *calcdef UNUSED,
		       const xmlChar **attrs UNUSED)
{
  int i;
  long user_keycode;
  unsigned long hw_keycode;
  bool got_user_keycode = false;
  bool got_hw_keycode = false;
  char *chip_id = NULL;
  char *endptr = NULL;
  calcdef_key_t *key;

  for (i = 0; attrs && attrs [i]; i += 2)
    {
      if (strcmp ((char *) attrs [i], "user_keycode") == 0)
	{
	  user_keycode = strtol ((char *) attrs [i + 1], & endptr, 0);
	  if ((user_keycode < -MAX_KEYCODE) || (user_keycode > MAX_KEYCODE))
	    fatal (3, "user keycode %d out of range\n");
	  if (endptr && (*endptr != '\0'))
	    fatal (3, "invalid character '%c' in user_keycode\n", *endptr);
	  got_user_keycode = true;
	}
      else if (strcmp ((char *) attrs [i], "chip_id") == 0)
	{
	  chip_id = newstr ((char *) attrs [i + 1]);
	}
      else if (strcmp ((char *) attrs [i], "hw_keycode") == 0)
	{
	  hw_keycode = strtoul ((char *) attrs [i + 1], & endptr, 0);
	  if (endptr && (*endptr != '\0'))
	    fatal (3, "invalid character '%c' in hw_keycode\n", *endptr);
	  got_hw_keycode = true;
	}
      else
	warning ("unknown attribute '%s' in 'loc' element\n", attrs [i]);
    }

  if (! got_user_keycode)
    warning ("key element doesn't have user_keycode attribute\n");
  if (! got_hw_keycode)
    warning ("key element doesn't have hw_keycode attribute\n");

  if (calcdef->keyboard_map [user_keycode])
    warning ("duplicate key element\n");

  key = alloc (sizeof (calcdef_key_t));

  key->hw_keycode = (hw_keycode_t) hw_keycode;
  key->chip_id = chip_id;

  calcdef->keyboard_map [user_keycode] = key;
}


static void parse_flag (calcdef_t *calcdef UNUSED,
			const xmlChar **attrs UNUSED)
{
  int i;
  calcdef_flag_t *flag;
  bool got_number = false;
  bool got_value = false;

  flag = alloc (sizeof (calcdef_flag_t));
  flag->next = calcdef->sw->position->flag;

  for (i = 0; attrs && attrs [i]; i += 2)
    {
      if (strcmp ((char *) attrs [i], "chip_id") == 0)
	{
	  flag->chip_id = newstr ((char *) attrs [i + 1]);
	}
      else if (strcmp ((char *) attrs [i], "number") == 0)
	{
	  flag->number = atoi ((char *) attrs [i + 1]);
	  got_number = true;
	}
      else if (strcmp ((char *) attrs [i], "value") == 0)
	{
	  flag->value = atoi ((char *) attrs [i + 1]);
	  got_value = true;
	}
      else
	warning ("unknown attribute '%s' in 'flag' element\n", attrs [i]);
    }
  if (! got_number)
    {
      warning ("flag element doesn't have number attribute\n");
      return;
    }
  if (! got_value)
    {
      warning ("flag element doesn't have number attribute\n");
      return;
    }

  calcdef->sw->position->flag = flag;
}


static void parse_switch_pos (calcdef_t *calcdef UNUSED,
			      const xmlChar **attrs UNUSED)
{
  int i;
  calcdef_switch_position_t *pos;
  bool got_position = false;

  pos = alloc (sizeof (calcdef_switch_position_t));
  pos->next = calcdef->sw->position;

  for (i = 0; attrs && attrs [i]; i += 2)
    {
      if (strcmp ((char *) attrs [i], "position") == 0)
	{
	  pos->position = atoi ((char *) attrs [i + 1]);
	  got_position = true;
	}
      else
	warning ("unknown attribute '%s' in 'switch_pos' element\n", attrs [i]);
    }
  if (! got_position)
    {
      warning ("switch_pos element doesn't have position attribute\n");
      return;
    }

  calcdef->sw->position = pos;
}


static void parse_switch (calcdef_t *calcdef UNUSED,
			  const xmlChar **attrs UNUSED)
{
  int i;
  calcdef_switch_t *sw;
  bool got_number = false;

  sw = alloc (sizeof (calcdef_switch_t));
  sw->next = calcdef->sw;

  for (i = 0; attrs && attrs [i]; i += 2)
    {
      if (strcmp ((char *) attrs [i], "number") == 0)
	{
	  sw->number = atoi ((char *) attrs [i + 1]);
	  got_number = true;
	}
      else
	warning ("unknown attribute '%s' in 'switch' element\n", attrs [i]);
    }
  if (! got_number)
    {
      warning ("switch element doesn't have number attribute\n");
      return;
    }

  calcdef->sw = sw;
}


static void parse_hybrid (calcdef_t *calcdef UNUSED,
			  const xmlChar **attrs UNUSED)
{
}


static void parse_chip (calcdef_t *calcdef,
			const xmlChar **attrs UNUSED)
{
  calcdef_chip_t *chip;
  int i;

  chip = alloc (sizeof (calcdef_chip_t));
  chip->next = calcdef->chip;

  for (i = 0; attrs && attrs [i]; i += 2)
    {
      if (strcmp ((char *) attrs [i], "id") == 0)
	{
	  chip->id = newstr ((char *) attrs [i + 1]);
	}
      else if (strcmp ((char *) attrs [i], "type") == 0)
	{
	  chip->type = find_chip_type_by_name ((char *) attrs [i + 1]);
	}
      else if (strcmp ((char *) attrs [i], "index") == 0)
	{
	  chip->index = str_to_int32 ((char *) attrs [i + 1], NULL, 0);
	}
      else if (strcmp ((char *) attrs [i], "flags") == 0)
	{
	  chip->flags = str_to_int32 ((char *) attrs [i + 1], NULL, 0);
	}
      else
	warning ("unknown attribute '%s' in 'chip' element\n", attrs [i]);
    }

  calcdef->chip = chip;
}


static void parse_part_info (calcdef_t *calcdef UNUSED,
			     const xmlChar **attrs UNUSED)
{
}


static void parse_vendor_name (calcdef_t *calcdef UNUSED,
			       const xmlChar **attrs UNUSED)
{
}


static void parse_part_number (calcdef_t *calcdef UNUSED,
			       const xmlChar **attrs UNUSED)
{
}


static void parse_date_code (calcdef_t *calcdef UNUSED,
			     const xmlChar **attrs UNUSED)
{
}

static void parse_memory (calcdef_t *calcdef,
			  const xmlChar **attrs)
{
  calcdef_mem_t *mem;
  int i;
  bool got_addr_space = false;
  bool got_base_addr = false;
  bool got_size = false;

  mem = alloc (sizeof (calcdef_mem_t));
  mem->next = calcdef->chip->mem;
  calcdef->chip->mem = mem;

  mem->bank_mask = (1 << 0);   // default bank 0 only

  for (i = 0; attrs && attrs [i]; i += 2)
    {
      if (strcmp ((char *) attrs [i], "addr_space") == 0)
	{
	  mem->addr_space = newstr ((char *) attrs [i + 1]);
	  got_addr_space = true;
	}
      else if (strcmp ((char *) attrs [i], "banks") == 0)
	mem->bank_mask = parse_bank_mask ((char *) attrs [i + 1]);
      else if (strcmp ((char *) attrs [i], "base_addr") == 0)
	{
	  mem->base_addr = str_to_uint32 ((char *) attrs [i + 1], NULL, 0);
	  got_base_addr = true;
	}
      else if (strcmp ((char *) attrs [i], "size") == 0)
	{
	  mem->size = str_to_uint32 ((char *) attrs [i + 1], NULL, 0);
	  got_size = true;
	}
      else
	warning ("unknown attribute '%s' in 'memory' element\n", attrs [i]);
    }
  if (! got_addr_space)
    warning ("memory element doesn't have version attribute\n");
  if (! got_base_addr)
    warning ("memory element doesn't have base_addr attribute\n");
  if (! got_size)
    warning ("memory element doesn't have size attribute\n");
}


static void parse_loc (calcdef_t *calcdef,
		       const xmlChar **attrs)
{
  bool got_addr = false;
  bool got_data = false;
  addr_t addr;
  addr_t offset;
  rom_word_t data;
  int i;
    
  for (i = 0; attrs && attrs [i]; i += 2)
    {
      if (strcmp ((char *) attrs [i], "addr") == 0)
	{
	  addr = str_to_uint32 ((char *) attrs [i + 1], NULL, 0);
	  got_addr = true;
	}
      else if (strcmp ((char *) attrs [i], "data") == 0)
	{
	  data = str_to_uint32 ((char *) attrs [i + 1], NULL, 0);
	  got_data = true;
	}
      else
	warning ("unknown attribute '%s' in 'loc' element\n", attrs [i]);
    }
  if (! got_addr)
    fatal (3, "missing 'addr' attribute in 'loc' element\n");
  if (! got_data)
    fatal (3, "missing 'data' attribute in 'loc' element\n");

  // range check addr
  if ((addr < calcdef->chip->mem->base_addr) ||
      (addr >= (calcdef->chip->mem->base_addr + calcdef->chip->mem->size)))
    fatal (3, "address %03x out of range\n", addr);

  offset = addr - calcdef->chip->mem->base_addr;

  if (! calcdef->chip->mem->data)
    calcdef->chip->mem->data = alloc (calcdef->chip->mem->size * sizeof (rom_word_t));

  calcdef->chip->mem->data [offset] = data;
}


static void parse_chargen (calcdef_t *calcdef,
			   const xmlChar **attrs)
{
  int i;
  bool got_type = false;
  bool got_count = false;

  if (! calcdef->chip)
    fatal (3, "chargen element must be nested in chip element\n");
  if (calcdef->chip->char_gen)
    fatal (3, "only one chargen element allowed per chip\n");

  calcdef->chip->char_gen = alloc (sizeof (calcdef_char_gen_t));
  calcdef->chip->char_gen->char_gen = alloc (sizeof (segment_bitmap_t) * 256);

  for (i = 0; attrs && attrs [i]; i += 2)
    {
      if (strcmp ((char *) attrs [i], "type") == 0)
	{
	  if (strcmp ((char *) attrs [i + 1], "segment") == 0)
	    {
	      got_type = true;
	      calcdef->chip->char_gen->bitmap = false;
	    }
	  else if (strcmp ((char *) attrs [i + 1], "bitmap") == 0)
	    {
	      got_type = true;
	      calcdef->chip->char_gen->bitmap = true;
	    }
	  else
	    fatal (3, "unrecognized chargen type\n");
	}
      else if (strcmp ((char *) attrs [i], "count") == 0)
	{
	  got_count = true;
	  calcdef->chip->char_gen->count = atoi ((char *) attrs [i + 1]);
	}
      else
	warning ("unknown attribute '%s' in 'chargen' element\n", attrs [i]);
    }
  if (! got_type)
    fatal (3, "chargen element doesn't have type attribute\n");
}


static void parse_char (calcdef_t *calcdef,
			const xmlChar **attrs)
{
  int i;
  uint8_t id;
  bool got_id = false;

  if ((! calcdef->chip) || (! calcdef->chip->char_gen))
    fatal (3, "char element must be nested in chargen element\n");

  for (i = 0; attrs && attrs [i]; i += 2)
    {
      if (strcmp ((char *) attrs [i], "id") == 0)
	{
	  id = parse_id ((char *) attrs [i + 1]);
	  got_id = true;
	}
      else if (strcmp ((char *) attrs [i], "print") == 0)
	{
	  // ignored for now
	}
      else
	warning ("unknown attribute '%s' in 'char' element\n", attrs [i]);
    }
  if (! got_id)
    fatal (3, "char element doesn't have id attribute\n");
  calcdef->chip->char_gen->id = id;
  if (calcdef->chip->char_gen->bitmap)
    sax_handler.characters = parse_bitmap;
  else
    sax_handler.characters = parse_segments;
}


typedef void element_handler_t (calcdef_t *calcdef,
				const xmlChar **attrs);


typedef struct
{
  char *name;
  element_handler_t *handler;
} element_handler_info_t;


static element_handler_info_t element_handlers [] =
{
  { "calcdef",     parse_calcdef },
  { "inst_clock",  parse_inst_clock },
  { "keyboard",    parse_keyboard },
  { "key",         parse_key },
  { "switch",      parse_switch },
  { "switch_pos",  parse_switch_pos },
  { "flag",        parse_flag },
  { "hybrid",      parse_hybrid },
  { "chip",        parse_chip },
  { "part_info",   parse_part_info },
  { "vendor_name", parse_vendor_name },
  { "part_number", parse_part_number },
  { "date_code",   parse_date_code },
  { "memory",      parse_memory },
  { "loc",         parse_loc },
  { "chargen",     parse_chargen },
  { "char",        parse_char },
};


static const int element_handler_count = (sizeof (element_handlers) / sizeof (element_handler_info_t));


static void sax_start_element (void *ref,
			       const xmlChar *name,
			       const xmlChar **attrs)
{
  calcdef_t *calcdef = ref;
  int i;

  for (i = 0; i < element_handler_count; i++)
    if (xml_strcmp (name, element_handlers [i].name) == 0)
      {
	element_handlers [i].handler (calcdef, attrs);
	return;
      }

  warning ("unknown element '%s'\n", name);
}


static void sax_end_element (void *ref UNUSED,
			     const xmlChar *name UNUSED)
{
  sax_handler.characters = NULL;
}


static xmlSAXHandler sax_handler =
{
  .getEntity     = sax_get_entity,
  .startElement  = sax_start_element,
  .characters    = NULL,               // will change dynamically
  .endElement    = sax_end_element,
  .warning       = sax_warning,
  .error         = sax_error,
  .fatalError    = sax_fatal_error,
};


calcdef_t *calcdef_load (sim_t *sim, char *ncd_fn)
{
  calcdef_t *calcdef;

  calcdef = alloc (sizeof (calcdef_t));

  calcdef->sim = sim;

  xmlSAXUserParseFile (& sax_handler,
		       calcdef,
		       ncd_fn);

  return calcdef;
}


const char *calcdef_get_ncd_copyright (calcdef_t *calcdef)
{
  return calcdef->ncd_copyright;
}

const char *calcdef_get_ncd_license (calcdef_t *calcdef)
{
  return calcdef->ncd_license;
}

const char *calcdef_get_model_name (calcdef_t *calcdef)
{
  return calcdef->model_name;
}

int calcdef_get_platform (calcdef_t *calcdef)
{
  return calcdef->platform;
}

int calcdef_get_arch (calcdef_t *calcdef)
{
  return calcdef->arch;
}

int calcdef_get_arch_variant (calcdef_t *calcdef)
{
  return calcdef->arch_variant;
}

int calcdef_get_ram_size (calcdef_t *calcdef)
{
  return calcdef->ram_size;
}

double calcdef_get_clock_frequency (calcdef_t *calcdef)  // in Hz
{
  return calcdef->clock_frequency;
}


static struct calcdef_chip_t *find_chip_by_id (calcdef_t *calcdef,
					       char *chip_id)
{
  calcdef_chip_t *chip;

  for (chip = calcdef->chip; chip; chip = chip->next)
    {
      if (chip->id && strcmp (chip->id, chip_id) == 0)
	return chip;
    }
  return NULL;
}


const segment_bitmap_t *calcdef_get_char_gen (calcdef_t *calcdef,
					      char *chip_id)
{
  calcdef_chip_t *chip;

  chip = find_chip_by_id (calcdef, chip_id);
  if ((! chip) || (! chip->char_gen))
    return NULL;
  return chip->char_gen->char_gen;
}

static void calcdef_init_rom (calcdef_t *calcdef,
			      calcdef_mem_t *mem,
			      int bank_group)
{
  bank_t bank;
  addr_t offset;

  for (bank = 0; bank < MAX_MAX_BANK; bank++)
    {
      if (! ((1 << bank) & mem->bank_mask))
	continue;
      for (offset = 0; offset < mem->size; offset++)
	{
	  addr_t addr = mem->base_addr + offset;
	  if (! sim_write_rom (calcdef->sim,
			       bank,
			       addr,
			       & mem->data [offset]))
	    {
	      fatal (4, "can't init ROM bank %d addr %05o\n", bank, addr);
	    }
	  if (bank_group && (addr & 0xfff) == 0)  // $$$ ugly, should get page size form proc
	    {
	      if (! sim_set_bank_group (calcdef->sim,
					bank_group,
					addr))
		{
		  fatal (4, "can't set bank group at addr 0x%04x\n", addr);
		}
	    }
	}
    }
}

static void calcdef_init_ram (calcdef_t *calcdef, calcdef_mem_t *mem)
{
  if (! sim_create_ram (calcdef->sim, mem->base_addr, mem->size))
    fatal (4, "can't create RAM at addr %05o\n", mem->base_addr);
}


static bool is_banked_rom_chip (calcdef_chip_t *chip)
{
  calcdef_mem_t *mem;
  bank_mask_t bank_mask = 0;

  for (mem = chip->mem; mem; mem = mem->next)
    {
      if (strcmp (mem->addr_space, "inst") != 0)
	continue;  // not ROM
      if (! bank_mask)
	bank_mask = mem->bank_mask;  // first ROM we've seen
      else if (bank_mask != mem->bank_mask)
	return true;  // ROM memory regions in the same ROM have different
                      // bank masks
    }
  return false;
}


void calcdef_init_chips (calcdef_t *calcdef)
{
  calcdef_chip_t *chip;
  calcdef_mem_t *mem;
  chip_type_info_t *chip_type_info;

  for (chip = calcdef->chip; chip; chip = chip->next)
    {
      int bank_group = 0;
      if (is_banked_rom_chip (chip))
	{
	  bank_group = sim_create_bank_group (calcdef->sim);
#ifdef BANK_GROUP_DEBUG
	  printf ("created bank group %d\n", bank_group);
#endif
	}
      for (mem = chip->mem; mem; mem = mem->next)
	{
	  if (strcmp (mem->addr_space, "inst") == 0)
	    calcdef_init_rom (calcdef, mem, bank_group);
	  else if (strcmp (mem->addr_space, "data") == 0)
	    calcdef_init_ram (calcdef, mem);
	  else
	    warning ("unknown address space '%s'\n", mem->addr_space);
	}
      chip_type_info = get_chip_type_info (chip->type);
      if (chip_type_info->chip_gui_install_fn)
	chip->chip = chip_type_info->chip_gui_install_fn (calcdef->sim,
							  NULL,  // module
							  chip->type,
							  chip->index,
							  chip->flags);
      else if (chip_type_info->chip_install_fn)
	chip->chip = sim_add_chip (calcdef->sim,
				   NULL,  // module
				   chip->type,
				   chip->index,
				   chip->flags,
				   NULL, // callback_fn
				   NULL); // ref
    }
}


static calcdef_switch_t *calcdef_get_switch (calcdef_t *calcdef,
					     int sw)
{
  calcdef_switch_t *sw_p;
  for (sw_p = calcdef->sw; sw_p; sw_p = sw_p->next)
    if (sw_p->number == sw)
      return sw_p;
  return NULL;
}

static calcdef_switch_position_t *calcdef_get_switch_position (calcdef_t *calcdef,
							       int sw,
							       int pos)
{
  calcdef_switch_t *sw_p;
  calcdef_switch_position_t *pos_p;

  sw_p = calcdef_get_switch (calcdef, sw);
  if (! sw_p)
    return NULL;
  for (pos_p = sw_p->position; pos_p; pos_p = pos_p->next)
    if (pos_p->position == pos)
      return pos_p;
  return NULL;
}


bool calcdef_get_key (calcdef_t *calcdef,
		      int user_keycode,
		      struct chip_t **chip,
		      hw_keycode_t *hw_keycode)
{
  calcdef_key_t *key;
  calcdef_chip_t *calcdef_chip;

  if ((user_keycode < -MAX_KEYCODE) || (user_keycode > MAX_KEYCODE))
    return false;

  key = calcdef->keyboard_map [user_keycode];
  if (! key)
    return false;

  if ((key->chip_id) && (! key->chip))
    {
      calcdef_chip = find_chip_by_id (calcdef, key->chip_id);
      if (calcdef_chip)
	key->chip = calcdef_chip->chip;
    }

  *chip = key->chip;
  *hw_keycode = key->hw_keycode;
  return true;
}


bool calcdef_get_switch_position_flag  (calcdef_t *calcdef,
					int sw,
					int pos,
					int index,
					struct chip_t **chip,
					int *flag,
					int *value)
{
  calcdef_switch_position_t *pos_p;
  calcdef_flag_t *flag_p;

  pos_p = calcdef_get_switch_position (calcdef, sw, pos);
  if (! pos_p)
    return false;
  for (flag_p = pos_p->flag; flag_p; flag_p = flag_p->next)
    {
      if (index-- == 0)
	{
	  if (flag_p->chip_id)
	    {
	      calcdef_chip_t *calcdef_chip;
	      calcdef_chip = find_chip_by_id (calcdef, flag_p->chip_id);
	      if (calcdef_chip)
		*chip = calcdef_chip->chip;
	      else
		*chip = NULL;
	    }
	  else
	    *chip = NULL;
	  *flag = flag_p->number;
	  *value = flag_p->value;
	  return true;
	}
    }
  return false;
}
