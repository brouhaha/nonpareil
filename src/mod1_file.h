/*
$Id$
Copyright 2005 Eric L. Smith <eric@brouhaha.com>

Author: Warren Furlow (email: warren@furlow.org)

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


// Module type codes
#define CATEGORY_UNDEF          0  // not categorized
#define CATEGORY_OS             1  // base Operating System for C,CV,CX
#define CATEGORY_APP_PAC        2  // HP Application PACs
#define CATEGORY_HPIL_PERPH     3  // any HP-IL related modules and devices
#define CATEGORY_STD_PERPH      4  // standard Peripherals: Wand, Printer,
                                   // Card Reader, XFuns/Mem, Service, Time,
                                   // IR Printer
#define CATEGORY_CUSTOM_PERPH   5  // custom Peripherals: AECROM, CCD, HEPAX,
                                   // PPC, ZENROM, etc
#define CATEGORY_BETA           6  // BETA releases not fully debugged and
                                   // finished
#define CATEGORY_EXPERIMENTAL   7  // test programs not meant for normal usage
#define CATEGORY_MAX            7  // maximum CATEGORY_ define value


// Hardware codes
#define HARDWARE_NONE        0  // no additional hardware specified
#define HARDWARE_PRINTER     1  // 82143A Printer
#define HARDWARE_CARDREADER  2  // 82104A Card Reader
#define HARDWARE_TIMER       3  // 82182A Time Module or HP-41CX built in timer
#define HARDWARE_WAND        4  // 82153A Barcode Wand
#define HARDWARE_HPIL        5  // 82160A HP-IL Module
#define HARDWARE_INFRARED    6  // 82242A Infrared Printer Module
#define HARDWARE_HEPAX       7  // HEPAX Module - has special hardware features
                                // (write protect, relocation)
#define HARDWARE_WWRAMBOX    8  // W&W RAMBOX - has special hardware features
                                // (RAM block swap instructions)
#define HARDWARE_MLDL2000    9  // MLDL2000
#define HARDWARE_CLONIX     10  // CLONIX-41 Module
#define HARDWARE_MAX        10  // maximum HARDWARE_ define value


// relative position codes- do not mix these in a group except ODD/EVEN and
// UPPER/LOWER
// ODD/EVEN, UPPER/LOWER can only place ROMS in 16K blocks
#define POSITION_MIN      0x1f  // minimum POSITION_ define value
#define POSITION_ANY      0x1f  // position in any port page (8-F)
#define POSITION_LOWER    0x2f  // position in lower port page relative to any
                                // upper image(s) (8-F)
#define POSITION_UPPER    0x3f  // position in upper port page
#define POSITION_EVEN     0x4f  // position in any even port page (8,A,C,E)
#define POSITION_ODD      0x5f  // position in any odd port page (9,B,D,F)
#define POSITION_ORDERED  0x6f  // position sequentially in MOD file order, one
                                // image per page regardless of bank
#define POSITION_MAX      0x6f  // maximum POSITION_ define value


#define MOD1_HEADER_SIZE   729
#define MOD1_PAGE_SIZE    5188


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


#define MAX_PAGE_GROUP 8
#define MAX_BANK_GROUP 8


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


bool mod1_read_file_header (FILE *f, mod1_file_header_t *header);

bool mod1_validate_file_header (mod1_file_header_t *header, size_t file_size);

bool mod1_read_page (FILE *f, mod1_file_page_t *page);

bool mod1_validate_page (mod1_file_page_t *page);
