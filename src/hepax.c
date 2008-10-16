/*
$Id$
Copyright 2008 Eric Smith <eric@brouhaha.com>

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
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "arch.h"
#include "util.h"
#include "display.h"
#include "keyboard.h"
#include "chip.h"
#include "proc.h"
#include "digit_ops.h"
#include "calcdef.h"
#include "proc_int.h"
#include "proc_nut.h"
#include "hepax.h"


#undef HEPAX_DEBUG


typedef struct
{
  uint8_t port;
  uint8_t rom_page;  // The HEPAX ROM is at a dynamic address, rather than
                     // port-based.
} hepax_reg_t;


#define PR(name, field, bits, radix, get, set, arg)        \
    {{ name, bits, 1, radix },                             \
     offsetof (hepax_reg_t, field),                        \
     FIELD_SIZE_OF (hepax_reg_t, field),                  \
     get, set, arg } 


static const reg_detail_t hepax_reg_detail [] =
{
  //    name        field       bits radix  get   set   arg  array
  PR   ("port",     port,       4,   16,    NULL, NULL, 0),
  PR   ("rom_page", rom_page,   4,   16,    NULL, NULL, 0)
};


static chip_event_fn_t hepax_event_fn;


static const chip_detail_t hepax_chip_detail =
{
  {
    "HEPAX",
    CHIP_HEPAX,
    false  // There can only be one HEPAX on the bus.
  },
  sizeof (hepax_reg_detail) / sizeof (reg_detail_t),
  hepax_reg_detail,
  hepax_event_fn
};


static bool nut_move_rom_page (sim_t *sim,
			       uint8_t from_page,
			       bank_t  from_bank,
			       uint8_t to_page,
			       bank_t  to_bank,
			       bool    preflight)  // if true, don't actually move
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  if (! nut_page_exists (sim, from_bank, from_page))
    return false;
  if (nut_page_exists (sim, to_bank, to_page))
    return false;
  if (preflight)
    return true;
  nut_reg->prog_mem_page [to_bank][to_page] = nut_reg->prog_mem_page [from_bank][from_page];
  nut_reg->prog_mem_page [from_bank][from_page] = NULL;
  return true;
}


static bool hepax_move_rom_to_page (sim_t   *sim,
				    uint8_t new_page)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  hepax_reg_t *hepax_reg = get_chip_data (nut_reg->hepax_chip);

  bank_t bank;

#ifdef HEPAX_DEBUG
  fprintf (stderr, "HEPAX moving its ROM from page %x to page %x\n",
	   hepax_reg->rom_page, new_page);
#endif

  if (new_page == hepax_reg->rom_page)
    {
#ifdef HEPAX_DEBUG
      fprintf (stderr, "HEPAX not moved!\n");
#endif
      return false;
    }

  // If we're moving the ROM back to the port it came from,
  // hide the RAM.
  if (new_page == (8 + 2 * (hepax_reg->port - 1)))
    {
      nut_move_rom_page (sim,
			 new_page, 0,
			 new_page, HIDDEN_BANK,
			 false);
    }
  else
    {
      // preflight HEPAX ROM move
      for (bank = 0; bank < 4; bank++)
	if (! nut_move_rom_page (sim,
				 hepax_reg->rom_page, bank,
				 new_page, bank,
				 true))
	  {
	    fprintf (stderr, "HEPAX ROMBLK instruction failed\n");
	    return false;
	  }
    }


  // more HEPAX ROM
  for (bank = 0; bank < 4; bank++)
    nut_move_rom_page (sim,
		       hepax_reg->rom_page, bank,
		       new_page, bank,
		       false);

  // is there a hidden RAM page?
  if (nut_page_exists (sim, HIDDEN_BANK, hepax_reg->rom_page))
    {
      // yes, unhide
      nut_move_rom_page (sim,
			 hepax_reg->rom_page, HIDDEN_BANK,
			 hepax_reg->rom_page, 0,
			 false);
    }

  hepax_reg->rom_page = new_page;

  return true;
}

static void hepax_op_move_hepax_rom (sim_t *sim,
				     int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  hepax_move_rom_to_page (sim, nut_reg->c [0]);
}


static void hepax_op_write_protect_toggle (sim_t *sim,
					   int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  uint8_t ram_page = nut_reg->c [0];
  prog_mem_page_t *prog_mem_page = nut_reg->prog_mem_page [0][ram_page];

  if ((! prog_mem_page) || ! (prog_mem_page->ram))
    {
#ifdef HEPAX_DEBUG
      fprintf (stderr, "HEPAX WPTOG to non-RAM page %x\n", ram_page);
#endif
      return;
    }

#ifdef HEPAX_DEBUG
  fprintf (stderr, "HEPAX WPTOG to of RAM page %x\n",
	   prog_mem_page->write_enable ? "disabling" : "enabling",
	   ram_page);
#endif
  prog_mem_page->write_enable ^= 1;
}


static void hepax_init_ops (sim_t *sim)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  nut_reg->op_fcn [0x030] = hepax_op_move_hepax_rom;
  nut_reg->op_fcn [0x1f0] = hepax_op_write_protect_toggle;
}


static void hepax_reset (sim_t *sim)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  hepax_reg_t *hepax_reg = get_chip_data (nut_reg->hepax_chip);

  uint8_t page;

  page = 8 + 2 * (hepax_reg->port - 1);
  if (hepax_reg->rom_page != page)
    hepax_move_rom_to_page (sim, page);
}


static void hepax_event_fn (sim_t      *sim,
			    chip_t     *chip UNUSED,
			    event_id_t event,
			    int        arg1 UNUSED,
			    int        arg2 UNUSED,
			    void       *data UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  switch (event)
    {
    case event_reset:
      hepax_reset (sim);
      break;
    case event_wake:
      // waking up from deep sleep?
      if (! nut_reg->display_enable)
	hepax_reset (sim);
      break;
    default:
      // warning ("hepax: unknown event %d\n", event);
      break;
    }
}


chip_t *hepax_install (sim_t       *sim,
		       chip_type_t type  UNUSED,
		       int32_t     index,  // port number, 1-4
		       int32_t     flags UNUSED)
{
  nut_reg_t *nut_reg;
  hepax_reg_t *hepax_reg;

  if (sim->arch != ARCH_NUT)
    {
      fprintf (stderr, "HEPAX only supports Nut architecture\n");
      return NULL;
    }

  nut_reg = get_chip_data (sim->first_chip);

  hepax_reg = alloc (sizeof (hepax_reg_t));

#ifdef HEPAX_DEBUG
  fprintf (stderr, "HEPAX ROM in page %x\n", index);
#endif
  hepax_reg->port = index;
  hepax_reg->rom_page = 8 + 2 * (hepax_reg->port - 1);

  nut_reg->hepax_chip = install_chip (sim,
				      & hepax_chip_detail,
				      hepax_reg);

  hepax_init_ops (sim);
  hepax_reset (sim);

  return nut_reg->hepax_chip;
}
