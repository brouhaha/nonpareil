/*
Copyright 1995, 2004-2006, 2008, 2010, 2022 Eric Smith <spacewar@gmail.com>

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

#include "arch.h"
#include "util.h"
#include "display.h"
#include "keyboard.h"
#include "chip.h"
#include "calcdef.h"
#include "proc.h"
#include "digit_ops.h"
#include "voyager_lcd.h"
#include "proc_int.h"
#include "proc_nut.h"


#define VOYAGER_LCD_DIGITS 11

#define VOYAGER_LCD_SEGMENTS 10
#define VOYAGER_LCD_SEGMENT_ANN 9

#define VOYAGER_LCD_BLINK_DIVISOR 150


typedef struct
{
  bool enable;
  int count;

  bool blink;
  bool blink_state;
  int blink_count;
} voyager_display_reg_t;


#define VLR(name, field, bits, radix, get, set, arg) \
    {{ name, bits, 1, radix },                       \
     offsetof (voyager_display_reg_t, field),        \
     FIELD_SIZE_OF (voyager_display_reg_t, field),   \
     get, set, arg }


static reg_detail_t voyager_display_reg_detail [] =
{
  //    name      field   bits radix get   set   arg
  VLR  ("enable", enable, 1,   2,    NULL, NULL, 0),
  VLR  ("blink",  blink,  1,   2,    NULL, NULL, 0)
};


static chip_event_fn_t voyager_display_event_fn;


static chip_detail_t voyager_display_chip_detail =
{
  {
    "Voyager LCD",
    CHIP_VOYAGER_R2D2,
    false  // There is normally only one LCD driver on the bus.  There
           // are two R2D2 chips in an HP-15C, but one of the does not
           // have the LCD driver bonded out.
  },
  sizeof (voyager_display_reg_detail) / sizeof (reg_detail_t),
  voyager_display_reg_detail,
  voyager_display_event_fn
};


static void voyager_set_display_state (sim_t *sim,
				       bool new_state)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  voyager_display_reg_t *display = get_chip_data (nut_reg->display_chip);

  display->enable = new_state;
  chip_event (sim,
	      NULL,
	      event_display_state_change,
	      new_state,
	      0,
	      NULL);
}


static void voyager_op_display_off (sim_t *sim,
				    int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  voyager_display_reg_t *display = get_chip_data (nut_reg->display_chip);

  voyager_set_display_state (sim, false);
  display->blink = 0;
  display->count = 2;
  // Don't change immediately, as the next instruction might be a
  // display toggle.
}


static void voyager_op_display_toggle (sim_t *sim,
				       int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  voyager_display_reg_t *display = get_chip_data (nut_reg->display_chip);

  voyager_set_display_state (sim, ! display->enable);
  display->count = 0;  // force immediate display update
}


static void voyager_op_display_blink (sim_t *sim,
				      int opcode UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  voyager_display_reg_t *display = get_chip_data (nut_reg->display_chip);

  voyager_set_display_state (sim, true);
  display->blink = 1;
  display->blink_state = 1;
  display->blink_count = VOYAGER_LCD_BLINK_DIVISOR;
  display->count = 0;  // force immediate display update
}


static void voyager_display_init_ops (sim_t *sim)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  sim->display_digits = VOYAGER_LCD_DIGITS;
  nut_reg->op_fcn [0x030] = voyager_op_display_blink;
  nut_reg->op_fcn [0x2e0] = voyager_op_display_off;
  nut_reg->op_fcn [0x320] = voyager_op_display_toggle;
}


static void voyager_display_reset (sim_t *sim)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  voyager_display_reg_t *display = get_chip_data (nut_reg->display_chip);

  voyager_set_display_state (sim, false);
  display->enable = 0;
  display->blink = 0;
  display->count = 0;
}


typedef struct
{
  bool valid;
  uint16_t reg;
  uint8_t bit;
} voyager_segment_info_t;

static voyager_segment_info_t voyager_display_map[VOYAGER_LCD_DIGITS][VOYAGER_LCD_SEGMENTS];

static void voyager_display_update (sim_t *sim, voyager_display_reg_t *display)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  int digit;
  int segment;

  for (digit = 0; digit < VOYAGER_LCD_DIGITS; digit++)
    {
      sim->display_segments [digit] = 0;
      if (display->enable &&
	  ((! display->blink) || (display->blink_state)))
	{
	  for (segment = 0; segment <= 9; segment++)
	    {
	      if (! voyager_display_map[digit][segment].valid)
		continue;
	      int vreg = voyager_display_map [digit][segment].reg;
	      int vdig = voyager_display_map [digit][segment].bit / 4;
	      int vbit = 1 << (voyager_display_map [digit][segment].bit & 0x03);
	      if (nut_reg->ram[vreg][vdig] & vbit)
		{
		  if (segment == VOYAGER_LCD_SEGMENT_ANN)
		    sim->display_segments [digit] |= SEGMENT_ANN;
		  else
		    sim->display_segments [digit] |= (1 << segment);
		}
	    }
	}
    }

  if (display->blink)
    {
      display->blink_count--;
      if (! display->blink_count)
	{
	  display->blink_state ^= 1;
	  display->blink_count = VOYAGER_LCD_BLINK_DIVISOR;
	}
    }
}


static void voyager_display_event_fn (sim_t  *   sim,
				      chip_t     *chip UNUSED,
				      event_id_t event,
				      int        arg1 UNUSED,
				      int        arg2 UNUSED,
				      void       *data UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  voyager_display_reg_t *display = get_chip_data (nut_reg->display_chip);

  switch (event)
    {
    case event_reset:
       voyager_display_reset (sim);
       break;
    case event_cycle:
      if (display->count == 0)
	{
	  voyager_display_update (sim, display);
	  sim_send_display_update_to_gui (sim);
	  display->count = 15;
	}
      else
	display->count --;
      break;
    case event_sleep:
      // force display update
      voyager_display_update (sim, display);
      sim_send_display_update_to_gui (sim);
      display->count = 15;

      if (display->enable)
	{
	  /* going to light sleep */
#ifdef AUTO_POWER_OFF
	  // $$$ how does display timer work on Voyager?
	  /* start display timer if LCD chip is selected */
	  if (nut_reg->pf_addr == PFADDR_LCD_DISPLAY)
	    display->timer = DISPLAY_TIMEOUT;
#endif /* AUTO_POWER_OFF */
	}
      else
	/* going to deep sleep */
	nut_reg->carry = 1;
      break;
    case event_wake:
    case event_restore_completed:
      // force display update
      voyager_set_display_state (sim, display->enable);
      voyager_display_update (sim, display);
      sim_send_display_update_to_gui (sim);
      display->count = 15;
      break;
    default:
      // warning ("voyager_lcd: unknown event %d\n", event);
      break;
    }
}


static void voyager_display_bitmap_read (nut_reg_t *nut_reg UNUSED,
					 int addr           UNUSED,
					 reg_t *reg)
{
  int i;
  for (i = 0; i < WSIZE; i++)
    (*reg) [i] = nut_reg->ram [addr] [i];

  // The least significant 6 bits of the register (bits 5..0) don't really
  // exist
  (*reg) [1] &= 0xc;
  (*reg) [0] =  0x0;
#if 0
  // Someone said back in 2005 that the low 6 bits read back as the
  // complement of bit 7, but I don't think that is correct, as it makes
  // the Voyager on-divide display test yield incorrect displays.
  if (! ((* reg) [1] & 0x8))
    {
      (*reg) [1] |= 0x3;
      (*reg) [0] =  0xf;
    }
#endif
}


static void voyager_display_init_lcd_map(sim_t *sim)
{
  calcdef_t *calcdef = sim->calcdef;
  for (int digit = 0; digit < VOYAGER_LCD_DIGITS; digit++)
    for (int segment = 0; segment < VOYAGER_LCD_SEGMENTS; segment++)
      {
	voyager_segment_info_t *info = & voyager_display_map[digit][segment];
	info->valid = calcdef_get_lcd_segment(calcdef,
					      digit,
					      segment,
					      & info->reg,
					      & info->bit);
      }
}

chip_t *voyager_r2d2_install (sim_t           *sim,
			      plugin_module_t *module,
			      chip_type_t     type  UNUSED,
			      int32_t         index,
			      int32_t         flags UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  int io_base;
  chip_t *chip = NULL;

  voyager_display_reg_t *display;

  // Extra R2D2 chips, e.g., second chip in 15C, only provide memory,
  // so other than the memory, we don't "install" them.
  if (index == 0)
    {
      voyager_display_init_lcd_map(sim);

      voyager_display_init_ops (sim);

      display = alloc (sizeof (voyager_display_reg_t));

      chip = install_chip (sim,
			   module,
			   & voyager_display_chip_detail,
			   display);

      nut_reg->display_chip = chip;
    }

  io_base = index * 0x10 + 0x08;
  
  sim->proc->create_ram (sim, io_base, 3);
  nut_reg->ram_read_fn  [io_base    ] = nut_ram_read_zero;
  nut_reg->ram_write_fn [io_base    ] = nut_ram_write_ignore;
  nut_reg->ram_read_fn  [io_base + 1] = voyager_display_bitmap_read;
  nut_reg->ram_read_fn  [io_base + 2] = voyager_display_bitmap_read;

  return chip;
}
