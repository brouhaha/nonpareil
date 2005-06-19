/*
$Id$
Copyright 2005 Eric L. Smith <eric@brouhaha.com>

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

  if ((page->Page > 0x0f) &&
      ((page->Page < POSITION_MIN) || (page->Page > POSITION_MAX)))
    status = bad_page_value ("Page", page->Page);
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
