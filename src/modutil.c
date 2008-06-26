/*
$Id$
Copyright 2005, 2008 Eric Smith <eric@brouhaha.com>

MOD File utility main program for Linux/Posix systems.
Reads and checks a MOD file, then outputs its contents and info.
based on code originally written by Warren Furlow <warren@furlow.org>.

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
Background:

Each HP-41 ROM page is 4096 words in size and each word is 10 bits.  There are
16 pages in the address space, but pages can be bank switched by up to 4 banks.
The pages 0-7 are for system use and pages that go there are hard coded to that
location.  Pages 8-F are for plug-in module usage through the four physical
ports.  Each port takes up two pages (Page8=Port1 Lower,Page9=Port1 Upper,
etc.).

Note that some plug-in modules and peripherals are hard coded to map into
certain system pages.

The MOD File format is an advanced multi-page format for containing an
entire module or all operating system pages.  See MODFile.h  This format is
used by V41 Release 8.
*/


#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "util.h"

#include "mod1_file.h"


static char *category_name [CATEGORY_MAX + 1] =
{
  [CATEGORY_UNDEF]        = "not categorized",
  [CATEGORY_OS]           = "base operating system",
  [CATEGORY_APP_PAC]      = "HP Application PAC",
  [CATEGORY_HPIL_PERPH]   = "HP-IL related modules and devices",
  [CATEGORY_STD_PERPH]    = "standard peripherals",
  [CATEGORY_CUSTOM_PERPH] = "custom peripherals",
  [CATEGORY_BETA]         = "BETA releases not fully debugged and finished",
  [CATEGORY_EXPERIMENTAL] = "test programs not meant for normal usage"
};


static char *hardware_name [HARDWARE_MAX + 1] =
{
  [HARDWARE_NONE]       = "none",
  [HARDWARE_PRINTER]    = "82143A printer",
  [HARDWARE_CARDREADER] = "82104A card reader",
  [HARDWARE_TIMER]      = "82182A Time Module or HP-41CX built in timer",
  [HARDWARE_WAND]       = "82153A Barcode Wand",
  [HARDWARE_HPIL]       = "82160A HP-IL Module",
  [HARDWARE_INFRARED]   = "82242A Infrared Printer Module",
  [HARDWARE_HEPAX]      = "HEPAX Module",
  [HARDWARE_WWRAMBOX]   = "W&W RAMBOX Device",
  [HARDWARE_MLDL2000]   = "MLDL2000 Device",
  [HARDWARE_CLONIX]     = "CLONIX-41 Module"
};


static char *prompt_name [16] =
{
  [0x0] = NULL,
  [0x1] = "Alpha (null input valid)",
  [0x2] = "2 Digits, ST, INF, IND ST, +, -, * or /",
  [0x3] = "2 Digits or non-null Alpha",
  [0x4] = NULL,
  [0x5] = "3 Digits",
  [0x6] = "2 Digits, ST, IND or IND ST",
  [0x7] = "2 Digits, IND, IND ST or non-null Alpha",
  [0x8] = NULL,
  [0x9] = "non-null Alpha",
  [0xa] = "2 Digits, IND or IND ST",
  [0xb] = "2 digits or non-null Alpha",
  [0xc] = NULL,
  [0xd] = "1 Digit, IND or IND ST",
  [0xe] = "2 Digits, IND or IND ST",
  [0xf] = "2 Digits, IND, IND ST, non-null Alpha . or .."
};


void usage (FILE *f)
{
  fprintf (f, "%s:  Module File Utiltiy\n",
	   nonpareil_release);
  fprintf (f, "Copyright 2005 Eric L. Smith\n");
  fprintf (f, "Based on code originally written by Warren Furlow\n");
  fprintf (f, "http://nonpareil.brouhaha.com/\n");
  fprintf (f, "\n");
  fprintf (f, "usage: %s [options...] mod_file...\n", progname);
  fprintf (f, "options:\n");
  fprintf (f, "   -v  verbose\n");
  fprintf (f, "   -e  extract ROM images, if any\n");
  fprintf (f, "   -f  decode FAT, if any\n");
  fprintf (f, "   -h  hex/text dump of pages\n");
  fprintf (f, "\n");
}


bool write_rom_file (char *fn, uint16_t *ROM)
{
  bool result = false;
  FILE *f = NULL;
  uint16_t *ROM2 = NULL;
  long size_written;
  int i;

  f = fopen (fn, "wb");
  if (! f)
    {
      fprintf (stderr, "ERROR: File Open Failed: %s\n", fn);
      goto done;
    }
  ROM2 = alloc (sizeof (uint16_t) * 0x1000);
  for (i=0; i < 0x1000; i++)
    ROM2 [i] = (ROM [i] << 8) | (ROM [i] >> 8);
  size_written = fwrite (ROM2, 1, 8192, f);
  if (size_written != 8192)
    {
      fprintf(stderr, "ERROR: File Write Failed: %s\n", fn);
      goto done;
    }

  result = true;

 done:
  if (f)
    fclose (f);
  if (ROM2)
    free (ROM2);
  return result;
}


const char LCDtoASCII []=
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


// Decodes a 9 bit LCD char into ASCII values where possible
// LCD char table: Mcode for Beginners, Emery, pg. 108

void decode_lcdchar (uint16_t lcdchar,  // LCD char in (bits 8-0)
		     char *ch,          // ASCII char out
		     char *punct)       // punctuation char out if any or == 0
{
  unsigned char val = lcdchar & 0x3f;  // take off bits 6-8

  if (lcdchar & 0x0100)
    *ch = LCDtoASCII [val + 0x040];     // bit 8 set - second 4 rows
  else
    *ch=LCDtoASCII[val];                // first 4 rows

  switch (lcdchar & 0x00c0)             // punct bits 6,7
    {
    case 0:
      *punct = 0;
      break;
    case 0x0040:
      *punct = '.';
      break;
    case 0x0080:
      *punct = ':';
      break;
    case 0x00c0:
      *punct = ',';
      break;
    }
}  


// Decodes a 10 bit FAT char into ASCII values where possible

void decode_fatchar (uint16_t word,  // word in
		     char *ch,       // PC char out
		     char *punct,    // punctuation char out if any or == 0
		     bool *end)      // end of name flag
{
  uint16_t lcdchar = word & 0x003f;  // ignore two high bits - used for
                                     // prompting - Zenrom pg 100.

  if (word & 0x40)                   // bit 6 is special chars (bit 8 in the
                                     // LCD table)
    lcdchar |= 0x0100;
  decode_lcdchar (lcdchar, ch, punct);
  *end = (word & 0x0080) != 0;       // bit 7 indicates end of name
  }


// Sum all values and when bit sum overflows into 11th bit add 1.
// Then take 2's complement.  Source: Zenrom pg. 101

uint16_t compute_checksum (uint16_t *ROM)
{
  uint16_t checksum = 0;
  int i;

  for (i=0; i < 0xfff; i++)
    {
      checksum += ROM [i];
    if (checksum > 0x3ff)
      checksum = (checksum & 0x03ff) + 1;
    }
  return ((~ checksum) + 1) & 0x3ff;
}


// gets the ROM ID at the end of the ROM.  This is valid for most ROMs
// except O/S which seems to only use 0x0ffe
// ROM ID is lcd coded and may have punct bits set but only uses chars 0-3f
// (no halfnut)
// the high two bits are apparently meaningless although some ROMs have them
// set

void get_rom_id (uint16_t *ROM,
		 char *ID)           // output: provide char[9]
{
  char *ptr = ID;
  char punct;
  int i;

  for (i = 0x0ffe; i >= 0x0ffb; i--)
    {
      decode_lcdchar (ROM [i] & 0x00ff, ptr++, & punct);
      if (punct)
	*(ptr++) = punct;
    }
  *ptr = '\0';
}


void unpack_image (uint16_t *ROM,
		   uint8_t  *BIN)
{
  int i;
  uint16_t *ptr = ROM;

  for (i = 0; i < 5120; i += 5)
    {
      *ptr++ = ((BIN [i + 1] & 0x03) << 8) | BIN [i];
      *ptr++ = ((BIN [i + 2] & 0x0F) << 6) | ((BIN [i + 1] & 0xFC) >> 2);
      *ptr++ = ((BIN [i + 3] & 0x3F) << 4) | ((BIN [i + 2] & 0xF0) >> 4);
      *ptr++ = (BIN [i + 4] << 2) | ((BIN [i + 3] & 0xC0) >> 6);
    }
}



void output_hex_dump (FILE *outfile,
		      uint16_t *ROM)
{
  int i, j;

  for (i = 0; i < 0x1000; i += 8)
    {
      fprintf (outfile, "%03x: ", i);
      for (j = i; j < (i + 8); j++)
	fprintf (outfile, "%03x ", ROM [j]);
      fprintf (outfile, "'");
      for (j = i; j < (i + 8); j++)
	{
	  char ch, punct;

	  decode_lcdchar (ROM [j] & 0x1ff, & ch, & punct);
	  fprintf (outfile, "%c", ch);
	}
      fprintf (outfile, "' '");
      for (j = i; j < (i + 8); j++)
	{
	  char ch;

	  ch = ROM [j] & 0x7f;
	  if ((ch >= ' ') && (ch <= '~'))
	    fprintf (outfile, "%c", ch);
	  else
	    fprintf (outfile, ".");
	}
      fprintf (outfile, "'\n");
    }
}


void output_fat (FILE *outfile,
		 mod1_file_page_t *page,
		 uint16_t page_addr,
		 uint16_t *ROM)
{
  uint16_t entry_num = 0;
  uint16_t page_start, addr, jmp_addr;

  if (page->Page <= 0xf)
    page_start = page->Page * 0x1000;
  else
    page_start = 0x8000;

  fprintf (outfile, "XROM  Addr Function    Type\n");
  addr = 2;

  // while entry number is less then number of entries and fat terminator
  // not found
  while ((entry_num <= ROM [1]) &&
	 ! ((ROM [addr] == 0) && (ROM [addr + 1] == 0)))
    {
      jmp_addr = ((ROM [addr] & 0x0ff) << 8) | (ROM [addr + 1] & 0x0ff);
      fprintf (outfile, "%02d,%02d %04X ", ROM [0], entry_num,
	       jmp_addr + page_addr);
      if (ROM [addr] & 0x200)
	{
          int addr2 = jmp_addr + 4;
	  int len = ROM [jmp_addr + 2] & 0x0f;

	  fprintf (outfile, "\"");
	  while (--len)
	    {
	      int ch = ROM [addr2++] & 0x7f;
	      fprintf (outfile, "%c", ch);
	    }
	  fprintf (outfile, "\"");
	  len = ROM [jmp_addr + 2] & 0x0f;
          while (len < 10)  // pad it out
            {
	      fprintf (outfile, " ");
	      len++;
            }
          fprintf (outfile, " 4K user code");
	}
      else if (jmp_addr < 0x1000)  // 4K MCODE def
	{
          int addr2 = jmp_addr;
          char ch, punct;
          int prompt;
	  bool end;

          do
            {
	      addr2--;
	      decode_fatchar (ROM [addr2], & ch, & punct, & end);
	      fprintf (outfile, "%c", ch);
            }
          while ((! end) && (addr2 > (jmp_addr - 11)));

          while (addr2 > jmp_addr - 11)  // pad it out
            {
	      fprintf (outfile, " ");
	      addr2--;
            }
          fprintf (outfile, " 4K MCODE");
          // function type
          if (ROM [jmp_addr] == 0)
            {
	      fprintf (outfile, " Nonprogrammable");
	      if (ROM [jmp_addr + 1] == 0)
		fprintf (outfile, " Immediate");
	      else
		fprintf (outfile, " NULLable");
            }
          else
            fprintf (outfile, " Programmable");
          // prompt type -high two bits of first two chars
          prompt = (ROM [jmp_addr - 1] & 0x300) >> 8;
          if (prompt && ! (ROM [jmp_addr - 2] & 0x0080))
            prompt |= (ROM [jmp_addr - 2] & 0x300) >> 6;
	  if (prompt)
	    fprintf (outfile, " Prompt; %s", prompt_name [prompt]);
	}
      else
	fprintf (outfile, "            8K MCODE (Not decoded)");
      fprintf (outfile, "\n");
      entry_num++;
      addr += 2;
    }
  // interrupt vectors
  // $$$ add printer vectors here, if it's a printer ROM
  fprintf (outfile, "INTERRUPT VECTORS:\n");
  fprintf (outfile, "Pause loop:                      %03X\n", ROM [0x0ff4]);
  fprintf (outfile, "Main running loop:               %03X\n", ROM [0x0ff5]);
  fprintf (outfile, "Deep sleep wake up, no key down: %03X\n", ROM [0x0ff6]);
  fprintf (outfile, "Off:                             %03X\n", ROM [0x0ff7]);
  fprintf (outfile, "I/O service:                     %03X\n", ROM [0x0ff8]);
  fprintf (outfile, "Deep sleep wake up:              %03X\n", ROM [0x0ff9]);
  fprintf (outfile, "Cold start:                      %03X\n", ROM [0x0ffa]);
}


void output_page_info (FILE *outfile,
		       mod1_file_page_t *page,
		       uint16_t *ROM)
{
  char ID [10];

  fprintf (outfile, "ROM NAME: %s\n", page->Name);
  get_rom_id (ROM, ID);
  if (strcmp (page->ID, ID) == 0)
    fprintf (outfile, "ROM ID: %s\n", page->ID);
  else
    fprintf (outfile, "ROM ID: \"%s\" (ACTUAL ID: \"%s\")\n", page->ID, ID);
  if (((page->Page > 0x0f) &&
       (page->Page < POSITION_MIN)) ||
      (page->Page > POSITION_MAX) ||
      (page->PageGroup > 8) ||
      (page->Bank == 0) ||
      (page->Bank > 4) ||
      (page->BankGroup > 8) || 
      (page->RAM > 1) ||
      (page->WriteProtect > 1) ||
      (page->FAT > 1) ||  // out of range values
      (page->PageGroup && (page->Page <= POSITION_ANY)) ||  // group pages cannot use non-grouped position codes
      ((! page->PageGroup) && (page->Page >POSITION_ANY)))  // non-grouped pages cannot use grouped position codes
    fprintf (outfile, "WARNING: Page info invalid\n");
  if (page->Page <= 0x0f)
    fprintf (outfile, "PAGE: %X - must be in this location\n", page->Page);
  else
    {
      fprintf (outfile, "PAGE: May be in more than one location\n");
      switch (page->Page)
        {
        case POSITION_ANY:
          fprintf (outfile,"POSITION: Any page 8-F\n");
          break;
        case POSITION_LOWER:
          fprintf (outfile,"POSITION: In lower relative to upper page\n");
          break;
        case POSITION_UPPER:
          fprintf (outfile,"POSITION: In upper page relative to lower page\n");
          break;
        case POSITION_ODD:
          fprintf (outfile,"POSITION: Any odd page (9,B,D,F)\n");
          break;
        case POSITION_EVEN:
          fprintf (outfile,"POSITION: Any even page (8,A,C,E)\n");
          break;
        case POSITION_ORDERED:
          fprintf (outfile,"POSITION: Sequentially in MOD file order\n");
          break;
        }
    }
  if (page->PageGroup == 0)
    fprintf (outfile, "PAGE GROUP: 0 - not grouped\n");
  else
    fprintf (outfile,"PAGE GROUP: %d\n", page->PageGroup);
  fprintf (outfile,"BANK: %d\n", page->Bank);
  if (page->BankGroup==0)
    fprintf (outfile, "BANK GROUP: 0 - not grouped\n");
  else
    fprintf (outfile, "BANK GROUP: %d\n", page->BankGroup);
  fprintf (outfile, "RAM: %s\n", page->RAM ? "Yes" : "No");
  fprintf (outfile, "Write Protected: %s\n",
	   page->WriteProtect ? "Yes" : "No or Not Applicable");
  if ((! page->RAM) && page->WriteProtect)
    fprintf (outfile, "WARNING: ROM pages should not have WriteProtect set\n");
  fprintf (outfile, "FAT: %s\n", page->FAT ? "Yes" : "No");

  if (page->FAT)
    {
      fprintf (outfile, "XROM: %d\n", ROM [0]);
      fprintf (outfile, "FCNS: %d\n", ROM [1]);
    }

  fprintf (outfile, "CHECKSUM: %03X", ROM[0x0fff]);
  if (compute_checksum (ROM) == ROM [0x0fff])
    fprintf (outfile," (CORRECT)\n");
  else
    fprintf (outfile," (INCORRECT - COMPUTED CHECKSUM: %03X)\n", compute_checksum (ROM));
  
  fprintf (outfile,"\n");
}


void verbose_header_output (FILE *outfile,
			    char *fn,
			    mod1_file_header_t *header)
{
  // output header info
  fprintf (outfile, "FILE NAME: %s\n", fn);
  fprintf (outfile, "FILE FORMAT: %s\n", header->FileFormat);
  fprintf (outfile, "TITLE: %s\n", header->Title);
  fprintf (outfile, "VERSION: %s\n", header->Version);
  fprintf (outfile, "PART NUMBER: %s\n", header->PartNumber);
  fprintf (outfile, "AUTHOR: %s\n", header->Author);
  fprintf (outfile, "COPYRIGHT: %s\n", header->Copyright);
  fprintf (outfile, "LICENSE: %s\n", header->License);
  fprintf (outfile, "COMMENTS: %s\n", header->Comments);
  fprintf (outfile, "CATEGORY: %s\n", category_name [header->Category]);
  fprintf (outfile, "HARDWARE: %s\n", hardware_name [header->Hardware]);
  fprintf (outfile, "MEMORY MODULES: %d\n", header->MemModules);
  fprintf (outfile, "EXENDED MEMORY MODULES: %d\n", header->XMemModules);
  fprintf (outfile, "ORIGINAL: %s\n",
	   header->Original ?
	   "Yes - unaltered" :
	   "No - this file has been updated by a user application");
  fprintf (outfile, "APPLICATION AUTO UPDATE: %s\n",
	   header->AppAutoUpdate ?
	   "Yes - update this file when saving other data (for MLDL/RAM)" :
	   "No - do not update this file");
  fprintf (outfile, "NUMBER OF PAGES: %d\n", header->NumPages);
}


// Returns true for success, false for any failure

bool output_mod_info (FILE *outfile,    // output file or set to stdout
		      char *fn,
		      bool verbose,     // decode header, page info
		      bool decode_fat,  // decode fat if it exists
		      bool hex_dump)
{
  bool result = false;
  FILE *mod_file = NULL;
  uint8_t *buffer = NULL;
  size_t file_size,size_read;
  mod1_file_header_t *header;
  int i;

  // open and read MOD file into a buffer
  mod_file = fopen (fn, "rb");
  if (! mod_file)
    {
      fprintf (stderr, "ERROR: File open failed: %s\n", fn);
      if (verbose)
	fprintf (outfile, "ERROR: File open failed: %s\n", fn);
      goto done;
    }
  fseek (mod_file, 0, SEEK_END);
  file_size = ftell (mod_file);
  fseek (mod_file, 0, SEEK_SET);
  if ((file_size - sizeof (mod1_file_header_t)) % sizeof (mod1_file_page_t))
    {
      fprintf (stderr, "ERROR: File size invalid: %s\n", fn);
      if (verbose)
	fprintf (outfile, "ERROR: File size invalid: %s\n", fn);
      goto done;
    }
  buffer = alloc (file_size);

  size_read = fread (buffer, 1, file_size, mod_file);
  fclose(mod_file);
  mod_file = NULL;
  if (size_read != file_size)
    {
      fprintf (stderr, "ERROR: File read failed: %s\n", fn);
      if (verbose)
	fprintf (outfile, "ERROR: File read failed: %s\n", fn);
      goto done;
    }

  // check header
  header = (mod1_file_header_t *) buffer;
  if (file_size != (sizeof (mod1_file_header_t) +
		    (header->NumPages * sizeof(mod1_file_page_t))))
    {
      fprintf (stderr, "ERROR: File size invalid: %s\n", fn);
      if (verbose)
	fprintf (outfile, "ERROR: File size invalid: %s\n", fn);
      goto done;
    }
  if (strcmp (header->FileFormat, MOD_FORMAT) != 0)
    {
      fprintf (stderr, "ERROR: File type unknown: %s\n", fn);
      if (verbose)
	fprintf (outfile, "ERROR: File type unknown: %s\n", fn);
      goto done;
    }
  if ((header->MemModules > 4) ||
      (header->XMemModules > 3) ||
      (header->Original > 1) ||
      (header->AppAutoUpdate > 1) ||
      (header->Category > CATEGORY_MAX) ||
      (header->Hardware > HARDWARE_MAX))
    {
      fprintf (stderr, "ERROR: llegal value(s) in header: %s\n", fn);
      if (verbose)
	fprintf (outfile, "ERROR: llegal value(s) in header: %s\n", fn);
      goto done;
    }

  if (verbose)
    verbose_header_output (outfile, fn, header);
  else
    fprintf (outfile, "%-20s %-30s %-20s\n", fn,
	     header->Title, header->Author);

  // go through each page
  for (i = 0; i < header->NumPages; i++)
    {
      uint16_t page_addr;
      mod1_file_page_t *page;
      uint16_t ROM [0x1000];

      page = (mod1_file_page_t *) (buffer +
				  sizeof (mod1_file_header_t) +
				  i * sizeof (mod1_file_page_t));

      unpack_image (ROM, page->Image);

      if (page->Page <= 0x0f)
	page_addr = page->Page * 0x1000;
      page_addr = 0x8000;  // wild-ass guess

      fprintf (outfile, "\n");
      if (verbose)
	output_page_info (outfile, page, ROM);
      if (decode_fat && page->FAT)
	output_fat (outfile, page, page_addr, ROM);
      if (hex_dump)
	output_hex_dump (outfile, ROM);
    }

  result = true;  // everything OK
      
 done:
  if (buffer)
    free (buffer);

  if (mod_file)
    fclose (mod_file);

  return result;
}


// Returns true for success, false for any failure

bool extract_roms (char *fn)
{
  bool result = false;
  FILE *mod_file = NULL;
  uint8_t *buffer = NULL;
  size_t file_size,size_read;
  mod1_file_header_t *header;
  int i;

  // open and read MOD file into a buffer
  mod_file = fopen (fn, "rb");
  if (! mod_file)
    goto done;
  fseek (mod_file, 0, SEEK_END);
  file_size = ftell (mod_file);
  fseek (mod_file, 0, SEEK_SET);
  if ((file_size - sizeof (mod1_file_header_t)) % sizeof (mod1_file_page_t))
    goto done;
  buffer = alloc (file_size);
  size_read = fread (buffer, 1, file_size, mod_file);
  fclose(mod_file);
  mod_file = NULL;
  if (size_read != file_size)
    goto done;

  // check header
  header = (mod1_file_header_t *) buffer;
  if (file_size != (sizeof (mod1_file_header_t) +
		    (header->NumPages * sizeof(mod1_file_page_t))))
    goto done;
  if (strcmp (header->FileFormat, MOD_FORMAT) != 0)
    goto done;

  if ((header->MemModules > 4) || 
      (header->XMemModules > 3) ||
      (header->Original > 1) ||
      (header->AppAutoUpdate > 1) ||
      (header->Category > CATEGORY_MAX) ||
      (header->Hardware > HARDWARE_MAX))    // out of range
    goto done;

  /* go through each page */
  for (i = 0; i < header->NumPages; i++)
    {
      char rom_fn [255];
      mod1_file_page_t *page;
      uint16_t ROM [0x1000];

      page = (mod1_file_page_t *) (buffer +
				  sizeof (mod1_file_header_t) +
				  i * sizeof (mod1_file_page_t));

      // write the ROM file
      unpack_image (ROM, page->Image);
      sprintf (rom_fn, "%s.%s", page->Name, ".rom");
      write_rom_file (rom_fn, ROM);
    }

  result = true;  // everything OK
      
 done:
  if (buffer)
    free (buffer);

  if (mod_file)
    fclose (mod_file);

  return result;
}


int main (int argc, char *argv [])
{
  int errors = 0;
  bool verbose = false;
  bool extract = false;
  bool decode_fat = false;
  bool hex_dump = false;

  progname = newstr (argv [0]);

  if (argc <= 1)
    fatal (1, NULL);  // print usage message only

  while (--argc)
    {
      argv++;
      if (*argv [0] == '-')
	{
	  if (strcmp (argv [0], "-v") == 0)
	    verbose = true;
	  else if (strcmp (argv [0], "-e") == 0)
	    extract = true;
	  else if (strcmp (argv [0], "-f") == 0)
	    decode_fat = true;
	  else if (strcmp (argv [0], "-h") == 0)
	    hex_dump = true;
	  else
	    fatal (1, "unrecognized option '%s'\n", argv [0]);
	}
      else
	{
	  if (! output_mod_info (stdout, argv [0], verbose, decode_fat, hex_dump))
	    errors++;
	  if (extract && ! extract_roms (argv [0]))
	    errors++;
	}
    }

  if (errors)
    fprintf (stderr,"*** %d ERROR(S)\n", errors);

  exit (errors != 0);
}
