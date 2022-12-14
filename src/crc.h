/*
Copyright 2008, 2022 Eric Smith <spacewar@gmail.com>

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


// Public definitions, for both sim and GUI threads:


#define CRC_EXT_FLAG_F1 1
#define CRC_EXT_FLAG_F2 2
#define CRC_EXT_FLAG_F3 3
#define CRC_EXT_FLAG_F4 4


#define CRC_WORD_SIZE 28  // size of a card word in bits

#define CRC_MAX_WORD  34  // number of 28-bit words on a side of a card
                          // includes 1 header word, 32 paylad, 1 checksum

// image of a single side of a magnetic card
typedef struct
{
  bool write_protect;
  bool dirty;                    // set by sim thread if card is written
  uint32_t word [CRC_MAX_WORD];  // data [0] is header,
                                 // data [CRC_MAX_WORD - 1] is checksum
                                 // 28 bits per word, 4 MSBs are zero
} crc_card_side_t;


enum
{
  event_crc_card_inserted = first_chip_event,
};


// Private definitions for sim thread only:

#define RAMADDR_CRC_BUFFER_WRITE 0x99
#define RAMADDR_CRC_BUFFER_READ 0x9b


chip_t *crc_install (sim_t           *sim,
		     plugin_module_t *module,
		     chip_type_t     type,
		     int32_t         index,
		     int32_t         flags);
