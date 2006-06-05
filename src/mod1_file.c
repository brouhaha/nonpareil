/*
$Id$
Copyright 2005, 2006 Eric L. Smith <eric@brouhaha.com>

MOD File utility functions.
Based on code originally written by Warren Furlow <warren@furlow.org>.

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


#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "util.h"
#include "mod1_file.h"


/*
.MOD File Structure:
These structures define the .MOD file format which replaces the older ROM
image dump formats (ROM, BIN).  MOD format allows the definition of entire
plug-in modules which may be composed of ROM images, RAM, special hardware
etc.  The HP-41C, -CV and -CX base operating system is defined in one MOD
file (ie The CX base includes 4 memory modules, the timer hardware, and
XFuns/XMem registers as well as 6 ROM images).  Additionally, Single Memory,
Quad Memory, XFuns/XMem, XMem, Timer modules can be defined each in their own
MOD file.  Obviously certain configurations do not make sense any more than
with the real hardware and may return an error (ie an HP-41CV AND a Quad
Memory Module).  It is also possible to define MLDL RAM using a blank page.

Strings are null terminated and all unused bytes are set to zero.  Fields are
strictly limited to valid values defined below.  Some combinations of values
would make no sense and not represent any actual hardware.  
File size=sizeof(ModuleFileHeader)+NumPages*sizeof(ModuleFilePage)
*/


#define MOD_FORMAT "MOD1"


#define MOD1_HEADER_SIZE   729
#define MOD1_PAGE_SIZE    5188


char *mod1_hardware_name [HARDWARE_MAX + 1] =
  {
    [HARDWARE_NONE]       = "none",
    [HARDWARE_PRINTER]    = "82143A Printer",
    [HARDWARE_CARDREADER] = "82104A Card Reader",
    [HARDWARE_TIMER]      = "82182A Time Module",
    [HARDWARE_WAND]       = "82153A Barcode Wand",
    [HARDWARE_HPIL]       = "82160A HP-IL Module",
    [HARDWARE_INFRARED]   = "82242A Infrared Printer Module",
    [HARDWARE_HEPAX]      = "HEPAX Module",
    [HARDWARE_WWRAMBOX]   = "W&W RAMBOX",
    [HARDWARE_MLDL2000]   = "MLDL2000",
    [HARDWARE_CLONIX]     = "CLONIX-41 Module",
  };


// A mod1 file consists of a module header followed by zero to 255 pages,
// As defined below.  Thus for a valid module file,
//    ((file_length - MOD1_HEADER_SIZE) % MOD1_PAGE_SIZE) == 0


// Module header

// Unfortunately this structure can't be used directly for I/O due to
// structure field alignment considerations on some systems.

typedef struct
{
  char FileFormat [5];       // constant value defines file format and revision
  char Title [50];           // the full module name (the short name is the
                             // name of the file itself)
  char Version [10];         // module version, if any 
  char PartNumber [20];      // module part number
  char Author [50];          // author, if any
  char Copyright [100];      // copyright notice, if any
  char License [200];        // license terms, if any
  char Comments [255];       // free form comments, if any
  uint8_t Category;          // module category, see codes below
  uint8_t Hardware;          // defines special hardware that module contains
  uint8_t MemModules;        // defines number of main memory modules (0-4)
  uint8_t XMemModules;       // defines number of extended memory modules
                             // (0=none, 1=Xfuns/XMem, 2,3=one or two
                             // additional XMem modules)
  uint8_t Original;          // allows validation of original contents:
                             // 1 = images and data are original,
                             // 0 = this file has been updated by a user
                             //     application (data in RAM written back to
                             //     MOD file, etc)
  uint8_t AppAutoUpdate;     // tells any application to:
                             // 1 = overwrite this file automatically when
                             //     saving other data,
                             // 0 = do not update
  uint8_t NumPages;          // the number of pages in this file (0-255, but
                             // normally between 1-6)
  uint8_t HeaderCustom[32];  // for special hardware attributes
} mod1_file_header_t;


// Module page

// Unfortunately this structure can't be used directly for I/O due to
// structure field alignment considerations on some systems.


typedef struct
{
  char Name [20];           // normally the name of the original .ROM file,
                            // if any
  char ID [9];              // ROM ID code, normally two letters and a number
                            // are ID and last letter is revision
  uint8_t Page;             // the page that this image must be in (0-F,
                            // although 8-F is not normally used)
                            // or defines each page's position relative to
                            // other images in a page group, see codes below
  uint8_t PageGroup;        // 0=not grouped, otherwise images with matching
                            // PageGroup values (1..8) are grouped according
                            // to POSITION code
  uint8_t Bank;             // the bank that this image must be in (1-4)
  uint8_t BankGroup;        // 0=not grouped, otherwise images with matching
                            // BankGroup values (1..8) are bankswitched with
                            // each other
  uint8_t RAM;              // 0=ROM, 1=RAM - normally RAM pages are all blank
                            // if Original=1
  uint8_t WriteProtect;     // 0=No or N/A, 1=protected - for HEPAX RAM and
                            // others that might support it
  uint8_t FAT;              // 0=no FAT, 1=has FAT
  uint8_t Image [5120];     // the image in packed format (.BIN file format)
  uint8_t PageCustom [32];  // for special hardware attributes
} mod1_file_page_t;


#define MOD_DEBUG


#ifdef MOD_DEBUG
static bool bad_header_value (char *field_name, uint8_t value)
{
  fprintf (stderr, "Bad mod header field %s value %d (0x%02x)\n",
	   field_name, value, value);
  return false;
}

static bool bad_page_value (char *field_name, uint8_t value)
{
  fprintf (stderr, "Bad mod page field %s value %d (0x%02x)\n",
	   field_name, value, value);
  return false;
}
#else
static inline bool bad_header_value (char *field_name, uint8_t value)
{
  return false;
}

static inline bool bad_page_value (char *field_name, uint8_t value)
{
  return false;
}
#endif



#define READ_FIELD(f,field) \
  do                        \
    if (fread_bytes (f, & field, sizeof (field), & eof, & error) !=    \
        sizeof (field))     \
      return false;         \
  while (0)                 \
      

bool mod1_read_file_header (FILE *f, mod1_file_header_t *header)
{
  bool eof, error;

  READ_FIELD (f, header->FileFormat);
  READ_FIELD (f, header->Title);
  READ_FIELD (f, header->Version);
  READ_FIELD (f, header->PartNumber);
  READ_FIELD (f, header->Author);
  READ_FIELD (f, header->Copyright);
  READ_FIELD (f, header->License);
  READ_FIELD (f, header->Comments);
  READ_FIELD (f, header->Category);
  READ_FIELD (f, header->Hardware);
  READ_FIELD (f, header->MemModules);
  READ_FIELD (f, header->XMemModules);
  READ_FIELD (f, header->Original);
  READ_FIELD (f, header->AppAutoUpdate);
  READ_FIELD (f, header->NumPages);
  READ_FIELD (f, header->HeaderCustom);
  return true;
}


bool mod1_validate_file_header (mod1_file_header_t *header, size_t file_size)
{
  bool status = true;

  if (file_size &&
      (file_size != (sizeof (mod1_file_header_t) +
		     (header->NumPages * sizeof (mod1_file_page_t)))))
    return false;  // file size invalid
  if (strcmp (header->FileFormat, MOD_FORMAT) != 0)
    return false;  // bad magic number
  if (header->MemModules > 4)
    status = bad_header_value ("MemModules", header->MemModules);
  if (header->XMemModules > 3)
    status = bad_header_value ("XMemModules", header->XMemModules);
  if (header->Original > 1)
    status = bad_header_value ("Original", header->Original);
  if (header->AppAutoUpdate > 1)
    status = bad_header_value ("AppAutoUpdate", header->AppAutoUpdate);
  if (header->Category > CATEGORY_MAX)
    status = bad_header_value ("Category", header->Category);
  if (header->Hardware > HARDWARE_MAX)
    status = bad_header_value ("Hardware\n", header->Hardware);

  return status;
}


bool mod1_read_page (FILE *f, mod1_file_page_t *page)
{
  bool eof, error;

  READ_FIELD (f, page->Name);
  READ_FIELD (f, page->ID);
  READ_FIELD (f, page->Page);
  READ_FIELD (f, page->PageGroup);
  READ_FIELD (f, page->Bank);
  READ_FIELD (f, page->BankGroup);
  READ_FIELD (f, page->RAM);
  READ_FIELD (f, page->WriteProtect);
  READ_FIELD (f, page->FAT);
  READ_FIELD (f, page->Image);
  READ_FIELD (f, page->PageCustom);
  return true;
}


bool mod1_validate_page (mod1_file_page_t *page)
{
  bool status = true;

  if (page->Page > 0x0f)
    {
      if (((page->Page & 0x0f) != 0x0f) ||
	  (page->Page < POSITION_MIN) || (page->Page > POSITION_MAX))
	status = bad_page_value ("Page", page->Page);
    }
  if ((page->Bank == 0) || (page->Bank > 4))
    status = bad_page_value ("Bank", page->Bank);
  if (page->BankGroup > 8)
    status = bad_page_value ("BankGroup", page->BankGroup);
  if (page->RAM > 1)
    status = bad_page_value ("RAM", page->RAM);
  if (page->WriteProtect > 1)
    status = bad_page_value ("WriteProtect", page->WriteProtect);
  if (page->FAT > 1)
    status = bad_page_value ("FAT", page->FAT);
  if ((page->PageGroup && (page->Page <= POSITION_ANY)) ||
      ((! page->PageGroup) && (page->Page >POSITION_ANY)))
    {
      // group pages cannot use non-grouped position codes
      // non-grouped pages cannot use grouped position codes
      status = bad_page_value ("PageGroup", page->PageGroup);
      status = bad_page_value ("Page", page->Page);
    }

  // $$$ should validate checksum here
  return status;
}


static bool sim_read_mod1_page (sim_t *sim,
				FILE *f,
				uint16_t *occupied_pages,
				uint16_t *this_mod_pages,
				uint16_t *)
{
  int p;
  mod1_file_page_t page;
  addr_t addr;
  int i;

  if (! mod1_read_page (f, & page))
    {
      fprintf (stderr, "Can't read MOD1 page\n");
      return false;
    }

  if (! mod1_validate_page (& page))
    {
      fprintf (stderr, "Unrecognized or inconsistent values in MOD1 page\n");
      return false;
    }

  if (page.Page < 0x010)
    {
      p = page.Page & 0x0f;
      if (! ((*allowed_pages) & (1 << p)))
	{
	  fprintf (stderr, "Unrecognized or inconsistent values in MOD1 page\n");
	  return false;
	}
    }
  else
    switch (page.Page)
      {
      case MOD1_POSITION_ANY:
	p = ???;
      case MOD1_POSITION_LOWER:
      case MOD1_POSITION_UPPER:
      case MOD1_POSITION_EVEN:
      case MOD1_POSITION_ODD:
      case MOD1_POSITION_ORDERED:
	fprintf (stderr, "Currently only MOD1 pages at fixed page numbers are supported\n");
	return false;
      default:
	fprintf (stderr, "invalid page value\n");
	return false;
      }

      addr = p << 12;

  for (i = 0; i < 5120; i += 5)
    {
      rom_word_t data;

      data = (((page.Image [i + 1] & 0x03) << 8) |
	      (page.Image [i]));
      if (! sim_load_mod1_rom_word (sim, page.Bank - 1, addr++, data))
				    
        return false;

      data = (((page.Image [i + 2] & 0x0f) << 6) |
	      ((page.Image [i + 1] & 0xfc) >> 2));
      if (! sim_load_mod1_rom_word (sim, page.Bank - 1, addr++, data))
				    
        return false;

      data = (((page.Image [i + 3] & 0x3f) << 4) |
	      ((page.Image [i + 2] & 0xf0) >> 4));
      if (! sim_load_mod1_rom_word (sim, page.Bank - 1, addr++, data))
				    
        return false;

      data = ((page.Image [i + 4] << 2) |
	      ((page.Image [i + 3] & 0xc0) >> 6));
      if (! sim_load_mod1_rom_word (sim, page.Bank - 1, addr++, data))
				    
        return false;
    }

  return true;
}


static bool sim_read_mod1_file (sim_t *sim,
				FILE *f,
				int port UNUSED)   // -1 for not port-based
{
  mod1_file_header_t header;
  size_t file_size;
  int i;
  uint16_t allowed_pages;

  switch (port)
    {
    case 0:
    case 1:
      allowed_pages = 0x03ff;
      break;
    case 2:
      allowed_pages = (occupied_apges
      break;
    case 3:
      allowed_pages = (1 << 0xc) | (1 << 0xd);
      break;
    case 4:
      allowed_pages = (1 << 0xe) | (1 << 0xf);
      break;
    }

  for (i = 1; i <= MOD1_MAX_BANK_GROUP; i++)
    bank_group [i] = 0;

  fseek (f, 0, SEEK_END);
  file_size = ftell (f);
  fseek (f, 0, SEEK_SET);

  if (! mod1_read_file_header (f, & header))
    {
      fprintf (stderr, "Can't read MOD1 file header\n");
      return false;
    }

  if (! mod1_validate_file_header (& header, file_size))
    {
      fprintf (stderr, "Unrecognized or inconsistent values in MOD1 file header\n");
      return false;
    }

  switch (header.Hardware)
    {

  for (i = 0; i < header.NumPages; i++)
    if (! sim_read_mod1_page (sim, f, & allowed_pages))
      return false;

  return true;
}


struct mod1_t
{
  mod1_module_info_t module_info;
  mod1_page_info_t *page_info;  // array of page info
  uint8_t **page_data;        // array of pointers, each to 5120 bytes of packed ROM data
  bool free_page_data_on_close;
  bool writeable;
  bool dirty;
}


mod1_status_t mod1_open_from_file (char *fn, mod1_t **mf)
{
  mod1_status_t status = MOD1_STATUS_ERROR;
  mod1_t *m1 = NULL;
  FILE *f = NULL;

  m1 = alloc (sizeof (mod1_t));
  if (! m1)
    {
      status = MOD1_STATUS_NO_MEM;
      goto error;
    }

  m1->writeable = false;
  m1->dirty = false;
  m1->free_page_data_on_close = true;

  f = fopen (fn, "rb");

  // $$$ more code needed here

  *mf = m1;
  status = MOD1_STATUS_OK;

 error:
  if (f)
    fclose (f);
  if (m1)
    free (m1);
  return status;
}


mod1_status_t mod1_open_from_mem (void *p, size_t len, mod1_t **mf)
{
  mod1_status_t status = MOD1_STATUS_ERROR;
  mod1_t *m1 = NULL;

  m1 = alloc (sizeof (mod1_t));
  if (! m1)
    {
      status = MOD1_STATUS_NO_MEM;
      goto error;
    }

  m1->writeable = false;
  m1->dirty = false;
  m1->free_page_data_on_close = false;

  // $$$ more code needed here

  *mf = m1;
  status = MOD1_STATUS_OK;

 error:
  return status;
}


static void free_page_info (mod1_t *mf, int page)
{
  if (mf->page_info [page]->name)
    free (mf->page_info [page]->name);
  if (mf->page_info [page]->id)
    free (mf->page_info [page]->id);
  free (mf->page_info [page]);
}


mod1_status_t mod1_close (mod1_t *mf)
{
  int i;

  for (i = 0; i < mf->mi->num_pages; i++)
    {
      free_page_info (mf, i);
      if (mf->free_page_data_on_close)
	free (mf->page_data [i]);
    }
  if (mf->module_info.name)
    free (mf->module_info.name)
  if (mf->module_info.version)
    free (mf->module_info.version)
  if (mf->module_info.part_number)
    free (mf->module_info.part_number)
  if (mf->module_info.author)
    free (mf->module_info.author)
  if (mf->module_info.copyright)
    free (mf->module_info.copyright)
  if (mf->module_info.license)
    free (mf->module_info.license)
  if (mf->module_info.comments)
    free (mf->module_info.comments)
  free (mf);

  return MOD1_STATUS_OK;
}


mod1_status_t mod1_get_module_info (mod1_t *mf,
				    mod1_module_info_t **mi)
{
  *mi = & mf->module_info;
  return MOD1_STATUS_OK;
}


mod1_status_t mod1_get_page_info (mod1_t *mf,
				  int page,
				  mod1_page_info_t **pi)
{
  if ((page < 0) || (page >= mf->module_info.num_pages))
    return MOD1_STATUS_PAGE_NUMBER_OUT_OF_RANGE;

  *pi = mf->page_info [page];
  return MOD1_STATUS_OK;
}


mod1_status_t mod1_get_rom_word (mod1_t *mf,
				 int page,
				 uint16_t offset,
				 uint16_t *data)
{
  uint8_t *raw_data;
  uint64_t four_words;

  if ((page < 0) || (page >= mf->module_info.num_pages))
    return MOD1_STATUS_PAGE_NUMBER_OUT_OF_RANGE;
  if (offset > 0xfff)
    return MOD1_STATUS_PAGE_OFFSET_OUT_OF_RANGE;

  raw_data = & mf->page_data [page] [(offset >> 2) * 5];

  four_words = ((raw_data [4] << 32) |
		(raw_data [3] << 24) |
		(raw_data [2] << 16) |
		(raw_data [1] << 8) |
		raw_data [0]);

  *data = (four_words >> (10 * (offset & 0x03))) & 0x3ff;

  return MOD1_STATUS_OK;
}


mod1_status_t mod1_put_rom_word (mod1_t *mf,
				 int page,
				 uint16_t offset,
				 uint16_t data)
{
  uint8_t *raw_data;
  uint64_t four_words;

  if (! mf->writeable)
    return MOD1_STATUS_MODULE_NOT_WRITEABLE;
  if ((page < 0) || (page >= mf->module_info.num_pages))
    return MOD1_STATUS_PAGE_NUMBER_OUT_OF_RANGE;
  if (offset > 0xfff)
    return MOD1_STATUS_PAGE_OFFSET_OUT_OF_RANGE;
  if (! mf->mod_info [page]->ram)
    return MOD1_STATUS_NOT_RAM;
  if (mf->mod_info [page]->write_protect)
    return MOD1_STATUS_WRITE_PROTECTED;

  raw_data = & mf->page_data [page] [(offset >> 2) * 5];

  four_words = ((raw_data [4] << 32) |
		(raw_data [3] << 24) |
		(raw_data [2] << 16) |
		(raw_data [1] << 8) |
		raw_data [0]);

  new_four_words &= (0x3ff << (10 * (offset & 0x03)));
  new_four_words |= ((data & 0x3ff) << (10 * (offset & 0x03)));

  if (new_four_words != four_words)
    {
      mf->dirty = true;
      raw_data [0] = four_words & 0xff;
      raw_data [1] = (four_words >> 8) & 0xff;
      raw_data [2] = (four_words >> 16) & 0xff;
      raw_data [3] = (four_words >> 24) & 0xff;
      raw_data [4] = (four_words >> 32) & 0xff;
    }

  return MOD1_STATUS_OK;
}


