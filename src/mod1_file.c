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

#include "mod1_file.h"


bool mod1_validate_file_header (mod1_file_header_t *header, size_t file_size)
{
  if (file_size &&
      (file_size != (sizeof (mod1_file_header_t) +
		     (header->NumPages * sizeof (mod1_file_page_t)))))
    return false;  // file size invalid
  if (strcmp (header->FileFormat, MOD_FORMAT) != 0)
    return false;  // bad magic number
  if ((header->MemModules > 4) ||
      (header->XMemModules > 3) ||
      (header->Original > 1) ||
      (header->AppAutoUpdate > 1) ||
      (header->Category > CATEGORY_MAX) ||
      (header->Hardware > HARDWARE_MAX))
    return false;  // illegal values in header fields

  return true;
}


bool mod1_validate_page (mod1_file_page_t *page)
{
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
    return false;

  // $$$ should validate checksum here
  return true;
}

