/*
$Id$
Copyright 2006, 2008 Eric Smith <eric@brouhaha.com>

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
#include <stdbool.h>
#include <stdint.h>
#include <string.h>

#include <libxml/SAX.h>

#include "util.h"
#include "display.h"
#include "keyboard.h"
#include "chip.h"
#include "proc.h"
#include "arch.h"
#include "platform.h"
#include "calcdef.h"
#include "proc_int.h"


typedef struct calcdef_mem_t
{
  struct calcdef_mem_t *next;
  char *addr_space;
  addr_t base_addr;
  addr_t size;
  bank_mask_t bank_mask;
  rom_word_t *data;
} calcdef_mem_t;


typedef struct calcdef_chip_t
{
  struct calcdef_chip_t *next;
  chip_type_t type;
  char *id;
  char *name;
  int32_t index;
  int32_t flags;
  calcdef_mem_t *mem;
} calcdef_chip_t;


typedef struct calcdef_flag_t
{
  struct calcdef_flag_t *next;
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
  segment_bitmap_t *char_gen;
  hw_keycode_t *keycode_map;
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

static uint32_t parse_segments (const char *s)
{
  uint32_t segments = 0;
  while (*s)
    {
      char c = *(s++);
      if ((c >= 'a') && (c <= 'z'))
	segments |= (1 << (c - 'a'));
      else if (c != ' ')
	fatal (3, "invalid character '%c' in segments\n", c);
    }
  return segments;
}


static int xml_strcmp (const xmlChar *s1, const char *s2)
{
  const char *s1c = (const char *) s1;
  return strcmp (s1c, s2);
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
  if (calcdef->keycode_map)
    {
      fatal (3, "only one chargen element allowed per nui file\n");
    }
  else
    calcdef->keycode_map = alloc (sizeof (hw_keycode_t) * 2 * MAX_KEYCODE);
}


static void parse_key (calcdef_t *calcdef UNUSED,
		       const xmlChar **attrs UNUSED)
{
  int i;
  long user_keycode;
  unsigned long hw_keycode;
  bool got_user_keycode = false;
  bool got_hw_keycode = false;
  char *endptr = NULL;

  for (i = 0; attrs && attrs [i]; i += 2)
    {
      if (strcmp ((char *) attrs [i], "user_keycode") == 0)
	{
	  user_keycode = strtol ((char *) attrs [i + 1], & endptr, 0);
	  if (endptr && (*endptr != '\0'))
	    fatal (3, "invalid character '%c' in user_keycode\n", *endptr);
	  got_user_keycode = true;
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

  if ((user_keycode < -MAX_KEYCODE) || (user_keycode >= MAX_KEYCODE))
    fatal (3, "user keycode %d out of range\n");
  calcdef->keycode_map [user_keycode + MAX_KEYCODE] = (hw_keycode_t) hw_keycode;
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
      if (strcmp ((char *) attrs [i], "number") == 0)
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


static void parse_chip (calcdef_t *calcdef UNUSED,
			const xmlChar **attrs UNUSED)
{
  calcdef_chip_t *chip;
  int i;

  chip = alloc (sizeof (calcdef_chip_t));
  chip->next = calcdef->chip;

  for (i = 0; attrs && attrs [i]; i += 2)
    {
      if (strcmp ((char *) attrs [i], "type") == 0)
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

  mem->bank_mask = (1 << 0);

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


static void parse_chargen (calcdef_t *calcdef UNUSED,
			   const xmlChar **attrs UNUSED)
{
  if (calcdef->char_gen)
    {
      fatal (3, "only one chargen element allowed per nui file\n");
    }
  else
    calcdef->char_gen = alloc (sizeof (segment_bitmap_t) * 256);
}


static void parse_char (calcdef_t *calcdef UNUSED,
			const xmlChar **attrs UNUSED)
{
  int i;
  uint8_t id;
  segment_bitmap_t segment_bitmap;
  bool got_id = false;
  bool got_segments = false;

  for (i = 0; attrs && attrs [i]; i += 2)
    {
      if (strcmp ((char *) attrs [i], "id") == 0)
	{
	  id = parse_id ((char *) attrs [i + 1]);
	  got_id = true;
	}
      else if (strcmp ((char *) attrs [i], "segments") == 0)
	{
	  segment_bitmap = parse_segments ((char *) attrs [i + 1]);
	  got_segments = true;
	}
      else if (strcmp ((char *) attrs [i], "print") == 0)
	{
	  // ignored for now
	}
      else
	warning ("unknown attribute '%s' in 'char' element\n", attrs [i]);
    }
  if (! got_id)
    warning ("char element doesn't have id attribute\n");
  if (! got_segments)
    warning ("char element doesn't have segments attribute\n");
  calcdef->char_gen [id] = segment_bitmap;
}


static xmlEntityPtr sax_get_entity (void *ref,
				    const xmlChar *name)
{
  calcdef_t *calcdef UNUSED = ref;
  return xmlGetPredefinedEntity (name);
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


static void sax_warning (void *ref,
			 const char *msg,
			 ...)
{
  calcdef_t *calcdef UNUSED = ref;
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
  calcdef_t *calcdef UNUSED = ref;
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
  calcdef_t *calcdef UNUSED = ref;
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

const segment_bitmap_t *calcdef_get_char_gen (calcdef_t *calcdef)
{
  return calcdef->char_gen;
}

// keycodes may be negative, so map is indexed by [keycode + MAX_KEYCODE]
const hw_keycode_t *calcdef_get_keycode_map (calcdef_t *calcdef)
{
  return calcdef->keycode_map;
}


static void calcdef_init_rom (calcdef_t *calcdef, calcdef_mem_t *mem)
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
	}
    }
}

static void calcdef_init_ram (calcdef_t *calcdef, calcdef_mem_t *mem)
{
  if (! sim_create_ram (calcdef->sim, mem->base_addr, mem->size))
    fatal (4, "can't create RAM at addr %05o\n", mem->base_addr);
}


void calcdef_init_chips (calcdef_t *calcdef)
{
  calcdef_chip_t *chip;
  calcdef_mem_t *mem;
  chip_type_info_t *chip_type_info;

  for (chip = calcdef->chip; chip; chip = chip->next)
    {
      for (mem = chip->mem; mem; mem = mem->next)
	{
	  if (strcmp (mem->addr_space, "inst") == 0)
	    calcdef_init_rom (calcdef, mem);
	  else if (strcmp (mem->addr_space, "data") == 0)
	    calcdef_init_ram (calcdef, mem);
	  else
	    warning ("unknown address space '%s'\n", mem->addr_space);
	}
      chip_type_info = get_chip_type_info (chip->type);
      if (chip_type_info->chip_install_fn)
	{
	  chip_type_info->chip_install_fn (calcdef->sim,
					   chip->index,
					   chip->flags);
	}
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


bool calcdef_get_switch_position_flag  (calcdef_t *calcdef,
					int sw,
					int pos,
					int index,
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
	  *flag = flag_p->number;
	  *value = flag_p->value;
	  return true;
	}
    }
  return false;
}
