/*
$Id$
Copyright 2005-2008, 2010 Eric Smith <eric@brouhaha.com>

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
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <glib.h>

#include "util.h"
#include "platform.h"
#include "arch.h"
#include "display.h"  // proc.h needs segment_bitmap_t
#include "keyboard.h"
#include "chip.h"
#include "calcdef.h"
#include "proc.h"
#include "mod1_file.h"
#include "dis_uc41.h"

#include "sound.h"  // ugh! needed for stub sound functions


#ifdef DEFAULT_PATH
char *default_path = MAKESTR(DEFAULT_PATH);
#else
char *default_path = NULL;
#endif


void usage (FILE *f)
{
  fprintf (f, "udis - %s\n", nonpareil_release);
  fprintf (f, "Copyright 2005, 2006, 2007, 2008 Eric Smith <eric@brouhaha.com>\n");
  fprintf (f, "http://nonpareil.brouhaha.com/\n");
  fprintf (f, "\n");
  fprintf (f, "usage: %s [options] model\n", progname);
  fprintf (f, "options:\n");
  fprintf (f, "   -a  assembly source mode\n");
  fprintf (f, "   -l  listing mode (default)\n");
  fprintf (f, "   --bank <bank>   bank\n");
  fprintf (f, "   --page <page>   page (41C)\n");
  fprintf (f, "   --start <addr>  start address\n");
  fprintf (f, "   --end <addr>    end address\n");
  fprintf (f, "   --fat           decode FAT and user code (41C)\n");
}


bool listing_mode = true;
bool decode_fat = false;

bool pass_two;

bool hex_addr_mode;


bank_t max_bank;
int page_size;
uint8_t max_page;
addr_t max_addr;

#define SYM_CALL 0x01
#define SYM_JUMP 0x02
#define SYM_KEY  0x04
uint8_t *symtab;


void set_symbol (bank_t bank, addr_t addr, uint8_t type)
{
  uint8_t *sym = & symtab [bank * max_addr + addr];
  (*sym) |= type;
}


void get_symbol (bank_t bank, addr_t addr, char *buf, int len)
{
  uint8_t *sym = & symtab [bank * max_addr + addr];
  if (*sym & SYM_CALL)
    snprintf (buf, len, hex_addr_mode ? "S%04x" : "S%05o", bank * max_addr + addr);
  else if (*sym & SYM_JUMP)
    snprintf (buf, len, hex_addr_mode ? "L%04x" : "L%05o", bank * max_addr + addr);
  else
    buf [0] = '\0';
}


void postprocess (bank_t       bank,
		  addr_t       addr,
		  flow_type_t  flow_type,
		  bank_t       target_bank,
		  addr_t       target_addr,
		  char         *buf,
		  int          len UNUSED)
{
  if (! pass_two)
    {
      if (flow_type_info [flow_type].has_target)
	{
	  if (flow_type == flow_subroutine_call)
	    set_symbol (target_bank, target_addr, SYM_CALL);
	  else
	    set_symbol (target_bank, target_addr, SYM_JUMP);
	}
    }
  else
    {
      char *p;
      char label [8];

      get_symbol (bank, addr, label, sizeof (label));
      // find label insertion point
      p = strstr (buf, "<label>");
      if (p)
	{
	  memset (p, ' ', 7);
	  if (label [0] && (label [0] != ' '))
	    {
	      memcpy (p, label, strlen (label));
	      p [strlen (label)] = ':';
	    }
	}
      else
	{
	  // fatal (2, "missing label insertion marker\n");
	}
      if (flow_type_info [flow_type].has_target)
	{
	  get_symbol (target_bank, target_addr, label, sizeof (label));
	  printf (buf, label);
	}
      else
	printf (buf);
      printf ("\n");
      if (flow_type_info [flow_type].ends_flow)
	printf ("\n");
    }
}


static void disassemble_all (sim_t *sim, uint32_t flags)
{
  uint8_t page;
  bank_t bank, target_bank;
  addr_t addr, target_addr, base_addr;
  inst_state_t inst_state = inst_normal;
  bool carry_known_clear;
  addr_t delayed_select_mask = 0, delayed_select_addr = 0;
  flow_type_t flow_type;
  char buf [100];

  for (bank = 0; bank < max_bank; bank++)
    for (page = 0; page < max_page; page++)
      if (sim_get_page_info (sim, bank, page, NULL, NULL, NULL))
	{
	  fprintf (stderr, "disassembling bank %d page %d\n", bank, page);
	  addr = page * page_size;
	  while ((addr >= (addr_t) (page * page_size)) &&
		 (addr < (addr_t) ((page + 1) * page_size)))
	    {
	      base_addr = addr;
	      if (! sim_disassemble (sim,
				     flags,
				     & bank,
				     & addr,
				     & inst_state,
				     & carry_known_clear,
				     & delayed_select_mask,
				     & delayed_select_addr,
				     & flow_type,
				     & target_bank,
				     & target_addr,
				     buf,
				     sizeof (buf)))
		{
		  warning ("disassembler error at bank %d addr %05o\n", bank, (addr + 1) % max_addr);
		  break;
		}
	      postprocess (bank,
			   base_addr,
			   flow_type,
			   target_bank,
			   target_addr,
			   buf,
			   sizeof (buf));
	    }
	}
}


static void disassemble_range (sim_t    *sim,
			       uint32_t flags,
			       bank_t   bank,
			       addr_t   start_addr,
			       addr_t   end_addr)
{
  bank_t target_bank;
  addr_t addr, target_addr, base_addr;
  inst_state_t inst_state = inst_normal;
  bool carry_known_clear;
  addr_t delayed_select_mask = 0, delayed_select_addr = 0;
  flow_type_t flow_type;
  char buf [100];

  addr = start_addr;
  while (addr <= end_addr)
    {
      base_addr = addr;
      if (! sim_disassemble (sim,
			     flags,
			     & bank,
			     & addr,
			     & inst_state,
			     & carry_known_clear,
			     & delayed_select_mask,
			     & delayed_select_addr,
			     & flow_type,
			     & target_bank,
			     & target_addr,
			     buf,
			     sizeof (buf)))
	{
	  warning ("disassembler error at bank %d addr %05o\n", bank, (addr + 1) % max_addr);
	  break;
	}
      postprocess (bank,
		   base_addr,
		   flow_type,
		   target_bank,
		   target_addr,
		   buf,
		   sizeof (buf));
    }
}


typedef enum
{
  ucode = 0,
  poll_entry,
  raw,          // used for two-word UC header, FAT trailer
  fat_header,
  ucode_name,
  ucode_name_first_char,
  uc
} rom_word_usage_t;

#ifdef DEBUG_PARSE_FAT
char rom_usage_char [6] =
{
  [ucode]                 = 'u',
  [poll_entry]            = 'p',
  [raw]                   = 'r',
  [fat_header]            = 'f',
  [ucode_name]            = 'n',
  [ucode_name_first_char] = 'n',
  [uc]                    = 'U'
};
#endif // DEBUG_PARSE_FAT

static rom_word_usage_t rom_word_usage [0x1000];


static bool disassemble_raw (sim_t    *sim UNUSED,
			     uint32_t flags UNUSED,
			     bank_t   *bank UNUSED,
			     addr_t   *addr UNUSED,
			     char     *buf UNUSED,
			     int      len UNUSED)
{
  rom_word_t w1;

  if (! sim_read_rom (sim, *bank, *addr, & w1))
    return false;
  (*addr) = ((*addr) + 1) & 0xffff;

  buf_printf (& buf, & len, "        .word 0x%02x", w1);
  return true;
}


static bool disassemble_fat_header (sim_t    *sim UNUSED,
				    uint32_t flags UNUSED,
				    bank_t   *bank UNUSED,
				    addr_t   *addr UNUSED,
				    char     *buf UNUSED,
				    int      len UNUSED)
{
  rom_word_t w1, w2;
  addr_t offset;

  if (! sim_read_rom (sim, *bank, *addr, & w1))
    return false;

  if (((*addr) & 0x0fff) == 0)
    {
      (*addr) = ((*addr) + 1) & 0xffff;
      buf_printf (& buf, & len, "        .word %d     ; XROM number", w1);
      return true;
    }

  if (((*addr) & 0x0fff) == 1)
    {
      (*addr) = ((*addr) + 1) & 0xffff;
      buf_printf (& buf, & len, "        .word %d     ; function count", w1);
      return true;
    }

  (*addr) = ((*addr) + 1) & 0xffff;
  if (! sim_read_rom (sim, *bank, *addr, & w2))
    return false;
  (*addr) = ((*addr) + 1) & 0xffff;

  offset = ((w1 & 0xff) << 8) + (w2 & 0xff);
  buf_printf (& buf, & len, "        %s %04x", (w1 & 0x200) ? ".uc_ent" : ".ucode_ent", offset);

  return true;
}


static const char LCDtoASCII []=
{
  '@', 'A', 'B', 'C', 'D', 'E', 'F', 'G',
  'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O',
  'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W',
  'X', 'Y', 'Z', '[', '\\',']', '^', '_',
  ' ', '!', '\"','#', '$', '%', '&', '\'',
  '(', ')', '*', '+', '{', '-', '}', '/',
  '0', '1', '2', '3', '4', '5', '6', '7',
  '8', '9', '~', ';', '<', '=', '>', '?',
  '~', 'a', 'b', 'c', 'd', 'e', '~', '~',
  '~', '~', '~', '~', '~', '~', '~', '~',
  '~', '~', '~', '~', '~', '~', '~', '~',
  '~', '~', '~', '~', '~', '~', '~', '~',
  '~', 'a', 'b', 'c', 'd', 'e', 'f', 'g',
  'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o',
  'p', 'q', 'r', 's', 't', 'u', 'v', 'w',
  'x', 'y', 'z', '~', '~', '~', '~', '~'
};


static bool disassemble_ucode_name (sim_t    *sim UNUSED,
			    uint32_t flags UNUSED,
			    bank_t   *bank UNUSED,
			    addr_t   *addr UNUSED,
			    char     *buf UNUSED,
			    int      len UNUSED)
{
  addr_t p = *addr;
  int name_len = 0;
  rom_word_t char_byte;

  while (rom_word_usage [p & 0xfff] == ucode_name)
    {
      p++;
      name_len++;
    }

  // now we should be at a ucode_name_first_char
  p++;
  name_len++;

  (*addr) += name_len;

  buf_printf (& buf, & len, "        .rstring \"");
  while (name_len--)
    {
      if (! sim_read_rom (sim, *bank, --p, & char_byte))
	return false;
      buf_printf (& buf, & len, "%c", LCDtoASCII [char_byte & 0x7f]);
    }
  buf_printf (& buf, & len, "\"");
  return true;
}

static bool parse_fat_uc (sim_t *sim,
			  bank_t bank,
			  addr_t start_addr,
			  addr_t entry_offset)
{
  addr_t offset;
  rom_word_t word;

  if (rom_word_usage [entry_offset] == uc)
    return true;

  // find lower bound
  offset = entry_offset;
  for (;;)
    {
      offset--;
      if (! sim_read_rom (sim, bank, start_addr + offset, & word))
	return false;
      if (word & 0x200)
	break;
      rom_word_usage [offset] = uc;
    }
  rom_word_usage [offset - 1] = raw;  // uc header
  rom_word_usage [offset]     = raw;  // uc header
  
  // find upper bound
  offset = entry_offset;
  for (;;)
    {
      if (! sim_read_rom (sim, bank, start_addr + offset, & word))
	return false;
      rom_word_usage [offset++] = uc;
      if (word & 0x200)
	break;
    }

  return true;
}


static bool parse_fat_ucode (sim_t *sim,
			     bank_t bank,
			     addr_t start_addr,
			     addr_t entry_offset)
{
  addr_t offset = entry_offset;
  rom_word_t word;
  bool first = true;

  // name is in LCD character set, in reverse order preceding
  // the ucode function
  for (;;)
    {
      offset--;
      if (! sim_read_rom (sim, bank, start_addr + offset, & word))
	return false;
      if (word & 0x300)  // MSBs shouldn't be set
	break;
      rom_word_usage [offset] = first ? ucode_name_first_char : ucode_name;
      first = false;
      if (word & 0x080)
	break;
    }
  return true;
}


static bool parse_fat (sim_t *sim,
		       bank_t bank,
		       addr_t start_addr)
{
  rom_word_t fn_count;
  rom_word_t w1, w2;
  addr_t entry_offset;
  int i;

  memset (rom_word_usage, 0, sizeof (rom_word_usage));

  rom_word_usage [0] = fat_header;
  rom_word_usage [1] = fat_header;

  if (! sim_read_rom (sim, bank, start_addr + 1, & fn_count))
    return false;

  for (i = 0; i < fn_count; i++)
    {
      if (! sim_read_rom (sim, bank, start_addr + 2 + 2 * i, & w1))
	return false;
      if (! sim_read_rom (sim, bank, start_addr + 2 + 2 * i + 1, & w2))
	return false;
      rom_word_usage [2 + 2 * i]     = fat_header;
      rom_word_usage [2 + 2 * i + 1] = fat_header;
      entry_offset = ((w1 & 0xff) << 8) | (w2 & 0xff);
      if (entry_offset > 0xfff)
	continue;
      if (w1 & 0x200)
	{
	  if (! parse_fat_uc (sim, bank, start_addr, entry_offset))
	    return false;
	}
      else
	{
	  if (! parse_fat_ucode (sim, bank, start_addr, entry_offset))
	    return false;
	}
    }

  if (! sim_read_rom (sim, bank, start_addr + 2 + 2 * i, & w1))
    return false;
  if (! sim_read_rom (sim, bank, start_addr + 2 + 2 * i + 1, & w2))
    return false;

  if ((w1 == 0) && (w2 == 0))
    {
      rom_word_usage [2 + 2 * i]     = raw;
      rom_word_usage [2 + 2 * i + 1] = raw;
    }

  // there should be two zero words after the end of the FAT
  // (not sure about the case of a 64-function FAT)

  // poll table
  for (i = 0xff4; i <= 0xffa; i++)
    rom_word_usage [i] = poll_entry;

  // ROM ID
  for (i = 0xffb; i <= 0xffd; i++)
    rom_word_usage [i] = ucode_name;
  rom_word_usage [0xfff] = ucode_name_first_char;

  // ROM checksum
  rom_word_usage [0xfff] = raw;

#ifdef DEBUG_PARSE_FAT
  for (i = 0; i < 0x1000; i+= 64)
    {
      int j;
      printf ("%04x: ", start_addr + i);
      for (j = i; j < (i + 64); j++)
	{
	  printf ("%c", rom_usage_char [rom_word_usage [j]]);
	}
      printf ("\n");
    }
  fflush (stdout);
#endif // DEBUG_PARSE_FAT

  return true;
}


static void disassemble_fat (sim_t    *sim,
			     uint32_t flags,
			     bank_t   bank,
			     addr_t   start_addr)
{
  bank_t target_bank;
  addr_t addr, target_addr, base_addr;
  inst_state_t inst_state = inst_normal;
  bool carry_known_clear;
  addr_t delayed_select_mask = 0, delayed_select_addr = 0;
  flow_type_t flow_type;
  bool status;
  char buf [100];

  if (! pass_two)
    {
      if (! parse_fat (sim, bank, start_addr))
	fatal (2, "error parsing FAT\n");
    }

  addr = start_addr;
  while (addr < (start_addr + 0x1000))
    {
      base_addr = addr;
      switch (rom_word_usage [addr - start_addr])
	{
	case ucode:
	case poll_entry:
	  status = sim_disassemble (sim,
				    flags,
				    & bank,
				    & addr,
				    & inst_state,
				    & carry_known_clear,
				    & delayed_select_mask,
				    & delayed_select_addr,
				    & flow_type,
				    & target_bank,
				    & target_addr,
				    buf,
				    sizeof (buf));
	  break;
	case raw:
	  status = disassemble_raw (sim, flags, & bank, & addr, buf, sizeof (buf));
	  flow_type = flow_no_branch;
	  break;
	case fat_header:
	  status = disassemble_fat_header (sim, flags, & bank, & addr, buf, sizeof (buf));
	  flow_type = flow_no_branch;
	  break;
	case ucode_name:
	  status = disassemble_ucode_name (sim, flags, & bank, & addr, buf, sizeof (buf));
	  flow_type = flow_no_branch;
	  break;
	case uc:
	  status = uc41_disassemble (sim,
				     flags,
				     & bank,
				     & addr,
				     & inst_state,
				     & carry_known_clear,
				     & delayed_select_mask,
				     & delayed_select_addr,
				     & flow_type,
				     & target_bank,
				     & target_addr,
				     buf,
				     sizeof (buf));
	  break;
	default:
	  fatal (2, "unknown rom word usage\n");
	  if (! status)
	    {
	      warning ("disassembler error at bank %d addr %05o\n", bank, (addr + 1) % max_addr);
	      break;
	    }
	}
      postprocess (bank,
		   base_addr,
		   flow_type,
		   target_bank,
		   target_addr,
		   buf,
		   sizeof (buf));
    }
}


void setup_path (void)
{
  char *p = getenv ("NONPAREIL_PATH");
  if (p)
    default_path = p;
}


int main (int argc, char *argv[])
{
  char *model_str = NULL;
  char *ncd_fn;
  char *module_str = NULL;
  char *mod1_fn;
  sim_t *sim;
  calcdef_t *calcdef;
  int arch;
  arch_info_t *arch_info;
  bool got_bank = false;
  bool got_page = false;
  bool got_start_addr = false;
  bool got_end_addr = false;
  uint32_t bank = 0;
  uint32_t page;
  uint32_t start_addr;
  uint32_t end_addr;
  uint32_t flags;

  progname = argv [0];

  setup_path ();

  g_thread_init (NULL);

  while (--argc)
    {
      argv++;
      if (*argv [0] == '-')
	{
	  if (strcmp (argv [0], "-a") == 0)
	    listing_mode = false;
	  else if (strcmp (argv [0], "-l") == 0)
	    listing_mode = true;
	  else if (strcmp (argv [0], "--fat") == 0)
	    decode_fat = true;
	  else if (strcmp (argv [0], "--bank") == 0)
	    {
	      got_bank = true;
	      bank = str_to_uint32 (argv [1], NULL, 0);
	      argc--;
	      argv++;
	    }
	  else if (strcmp (argv [0], "--page") == 0)
	    {
	      got_page = true;
	      page = str_to_uint32 (argv [1], NULL, 0);
	      if ((page < 0x3) || (page > 0xf))
		fatal (1, "page range is 0x3 to 0xf\n");
	      argc--;
	      argv++;
	    }
	  else if (strcmp (argv [0], "--start") == 0)
	    {
	      got_start_addr = true;
	      start_addr = str_to_uint32 (argv [1], NULL, 0);
	      argc--;
	      argv++;
	    }
	  else if (strcmp (argv [0], "--end") == 0)
	    {
	      got_end_addr = true;
	      end_addr = str_to_uint32 (argv [1], NULL, 0);
	      argc--;
	      argv++;
	    }
	  else
	    fatal (1, "unrecognized option '%s'\n", argv [0]);
	}
      else if (! model_str)
	model_str = argv [0];
      else if (! module_str)
	module_str = argv [0];
      else
	{
	  fatal (1, "only one model and one module may be specified\n");
	}
    }

  if (got_page)
    {
      if (got_start_addr || got_end_addr)
	fatal (1, "page and start/end options are mutually exclusive\n");
      start_addr = page << 12;
      end_addr = start_addr + 0xfff;
      got_start_addr = true;
      got_end_addr = true;
    }

  if (got_start_addr ^ got_end_addr)
    fatal (1, "start and end address must both be present\n");

  if (got_bank && ! (got_page || got_start_addr))
    fatal (1, "bank requires page or start and end address\n");

  ncd_fn = find_file_with_suffix (model_str, ".ncd", default_path);
  if (! ncd_fn)
    fatal (2, "can't find .ncd file\n");

  sim = sim_init (ncd_fn,
		  NULL,  // display_update_callback
		  NULL); // display_udpate_callback_ref 

  max_bank = sim_get_max_rom_bank (sim);
  page_size = sim_get_rom_page_size (sim);
  max_addr = sim_get_max_rom_addr (sim);
  max_page = max_addr / page_size;

  symtab = alloc (max_bank * max_addr * sizeof (uint8_t));

  calcdef = sim_get_calcdef (sim);
  arch = calcdef_get_arch (calcdef);
  arch_info = get_arch_info (arch);
  hex_addr_mode = (arch == ARCH_NUT);

  if (decode_fat)
    {
      if (arch != ARCH_NUT)
	fatal (1, "--fat only works on the Nut architecture\n");
      if (! got_start_addr)
	fatal (1, "--fat requires --page (or --start and --end)\n");
      if ((start_addr & 0x0fff) ||
	  ((end_addr & 0x0fff) != 0x0fff) ||
	  ((start_addr ^ end_addr) & 0xf000))
	fatal (1, "--fat requires address range to be a single aligned page\n");
    }

  if (module_str)
    {
      if (arch != ARCH_NUT)
	fatal (1, "module files can only be used with Nut processor\n");

      mod1_fn = find_file_with_suffix (module_str, ".mod", default_path);
      if (! mod1_fn)
	fatal (2, "can't find .mod file\n");

      if (! sim_install_module (sim, mod1_fn, -1, true))
	fatal (2, "can't load .mod file\n");
    }

  flags = DIS_FLAG_LABEL;
  if (listing_mode)
    flags |= DIS_FLAG_LISTING;

  pass_two = false;
  if (decode_fat)
    disassemble_fat (sim, flags, bank, start_addr);
  else if (got_start_addr)
    disassemble_range (sim, flags, bank, start_addr, end_addr);
  else
    disassemble_all (sim, flags);

  pass_two = true;
  printf ("\t.arch %s\n\n", arch_info->name);
  if (decode_fat)
    disassemble_fat (sim, flags, bank, start_addr);
  else if (got_start_addr)
    disassemble_range (sim, flags, bank, start_addr, end_addr);
  else
    disassemble_all (sim, flags);

  exit (0);
}


// GUI stubs
chip_t *gui_printer_install (sim_t *sim,
			     chip_type_t type,
			     int32_t index,
			     int32_t flags)
{
}

chip_t *gui_card_reader_install (sim_t *sim,
				 chip_type_t type,
				 int32_t index,
				 int32_t flags)
{
}


// sound function stubs
bool stop_sound (int id UNUSED)
{
  return true;
}

int synth_sound (float    frequency UNUSED,
		 float    amplitude UNUSED,
		 float    duration UNUSED,
		 sample_t *waveform_table UNUSED,
		 uint32_t waveform_table_length UNUSED)
{
  return 0;
}

sample_t squarewave_waveform_table [1] = { 0 };
uint32_t squarewave_waveform_table_length = 1;
