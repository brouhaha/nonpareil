/*
$Id$
Copyright 2005, 2006 Eric L. Smith <eric@brouhaha.com>

Based on code by Warren Furlow (email: warren@furlow.org).

Description:  Describes the structure of the MODULE file for HP-41 ROM images

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


// Error codes returned by mod1 functions
typedef enum
{
  MOD1_STATUS_OK,
  MOD1_STATUS_NO_MEM,
  MOD1_STATUS_BAD_MAGIC,
  MOD1_STATUS_FILE_TRUNCATED,
  MOD1_STATUS_BAD_FIELD_VALUE,
  MOD1_STATUS_PAGE_NUMBER_OUT_OF_RANGE,
  MOD1_STATUS_PAGE_OFFSET_OUT_OF_RANGE,
  MOD1_STATUS_MODULE_NOT_WRITEABLE,
  MOD1_STATUS_NOT_RAM,
  MOD1_STATUS_NOT_WRITE_PROTECTED,
  MOD1_STATUS_ERROR
} mod1_status_t;


// Module type codes
#define MOD1_CATEGORY_UNDEF          0  // not categorized
#define MOD1_CATEGORY_OS             1  // base Operating System for C,CV,CX
#define MOD1_CATEGORY_APP_PAC        2  // HP Application PACs
#define MOD1_CATEGORY_HPIL_PERPH     3  // any HP-IL related modules and devices
#define MOD1_CATEGORY_STD_PERPH      4  // standard peripherals from HP
#define MOD1_CATEGORY_CUSTOM_PERPH   5  // third-party peripherals
#define MOD1_CATEGORY_BETA           6  // BETA releases not fully debugged
#define MOD1_CATEGORY_EXPERIMENTAL   7  // test programs not meant for normal usage
#define MOD1_CATEGORY_MAX            7  // maximum CATEGORY_ define value


// Hardware codes
#define MOD1_HARDWARE_NONE        0  // no additional hardware specified
#define MOD1_HARDWARE_PRINTER     1  // 82143A Printer
#define MOD1_HARDWARE_CARDREADER  2  // 82104A Card Reader
#define MOD1_HARDWARE_TIMER       3  // 82182A Time Module or HP-41CX built in timer
#define MOD1_HARDWARE_WAND        4  // 82153A Barcode Wand
#define MOD1_HARDWARE_HPIL        5  // 82160A HP-IL Module
#define MOD1_HARDWARE_INFRARED    6  // 82242A Infrared Printer Module
#define MOD1_HARDWARE_HEPAX       7  // HEPAX Module - has special hardware features
                                     // (write protect, relocation)
#define MOD1_HARDWARE_WWRAMBOX    8  // W&W RAMBOX - has special hardware features
                                     // (RAM block swap instructions)
#define MOD1_HARDWARE_MLDL2000    9  // MLDL2000
#define MOD1_HARDWARE_CLONIX     10  // CLONIX-41 Module
#define MOD1_HARDWARE_MAX        10  // maximum MOD1_HARDWARE_ define value


// relative position codes- do not mix these in a group except ODD/EVEN and
// UPPER/LOWER
// ODD/EVEN, UPPER/LOWER can only place ROMS in 16K blocks
#define MOD1_POSITION_MIN      0x1f  // minimum MOD1_POSITION_ define value
#define MOD1_POSITION_ANY      0x1f  // position in any port page (8-F)
#define MOD1_POSITION_LOWER    0x2f  // position in lower port page relative to any
                                     // upper image(s) (8-F)
#define MOD1_POSITION_UPPER    0x3f  // position in upper port page
#define MOD1_POSITION_EVEN     0x4f  // position in any even port page (8,A,C,E)
#define MOD1_POSITION_ODD      0x5f  // position in any odd port page (9,B,D,F)
#define MOD1_POSITION_ORDERED  0x6f  // position sequentially in MOD file order, one
                                     // image per page regardless of bank
#define MOD1_POSITION_MAX      0x6f  // maximum MOD1_POSITION_ define value


#define MOD1_MAX_PAGE_GROUP 8
#define MOD1_MAX_BANK_GROUP 8


// Opaque type for an open mod1
typedef struct mod1_t mod1_t;


typedef struct
{
  char *name;
  char *version;
  char *part_number;
  char *author;
  char *copyright;
  char *license;
  char *comments;
  uint8_t category;      // MOD1_CATEGORY_xxx
  uint8_t hardware;      // MOD1_HARDWARE_xxx
  uint8_t num_pages;     // number of 4K ROM pages
  uint8_t mem_modules;   // number of 64-register memory modules (0-4)
  uint8_t xmem_modules;  // number of extended memory modules (0-3)
  bool unmodified;
  bool auto_update;
} mod1_module_info_t;


typedef struct
{
  char *name;
  char *id;
  uint8_t page;        // 0x0..0xf for hard-addressed, or MOD1_POSITION_xxx
  uint8_t page_group;  // 0 = not grouped
  uint8_t bank;
  uint8_t bank_group;
  bool ram;
  bool write_protect;
  bool has_fat;
} mod1_page_info_t;


// Open a mod1 module from a file.  Doesn't affect simulator memory or state.
mod1_status_t mod1_open_from_file (char *fn,
				   mod1_t **mf);

// Open a mod1 module that is already memory-resident.  Doesn't affect
// simulator memory or state.
mod1_status_t mod1_open_from_mem (void *p,
				  size_t len,
				  mod1_t **mf);

// Close a mod1 module.  Doesn't affect simulator memory or state.
mod1_status_t mod1_close (mod1_t *mf);

// Get module info.  Note that the pointer returned belongs to the mod1
// library, and will not be valid after mod1_close() is called.
mod1_status_t mod1_get_module_info (mod1_t *mf
				    mod1_module_info_t **mi);

// Get module page info.  Note that the pointer returned belongs to
// the mod1 library, and will not be valid after mod1_close() is
// called.
mod1_status_t mod1_get_page_info (mod1_t *mf,
				  int page,  // 0 .. num_pages - 1
				  mod1_page_info_t **pi);

// Read a single ROM word from a module page
mod1_status_t mod1_get_rom_word (mod1_t *mf,
				 int page,          // 0 .. num_pages - 1
				 uint16_t offset,   // 0 .. 4095
				 uint16_t *data);

// Write a single ROM word to a module page
mod1_status_t mod1_put_rom_word (mod1_t *mf,
				 int page,
				 uint16_t offset,
				 uint16_t data);
