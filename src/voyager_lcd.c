/*
$Id$
Copyright 1995, 2004, 2005 Eric L. Smith <eric@brouhaha.com>

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

#include "arch.h"
#include "util.h"
#include "display.h"
#include "proc.h"
#include "digit_ops.h"
#include "voyager_lcd.h"
#include "proc_int.h"
#include "proc_nut.h"


#define VOYAGER_DISPLAY_BLINK_DIVISOR 150


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
     OFFSET_OF (voyager_display_reg_t, field),       \
     SIZE_OF (voyager_display_reg_t, field),         \
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
    CHIP_DISPLAY,
    false  // There is normally only one LCD driver on the bus.  There
           // are two R2D2 chips in an HP-15C, but one of the does not
           // have the LCD driver bonded out.
  },
  sizeof (voyager_display_reg_detail) / sizeof (reg_detail_t),
  voyager_display_reg_detail,
  voyager_display_event_fn
};


static void voyager_op_display_off (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  voyager_display_reg_t *display = get_chip_data (nut_reg->display_chip);

  display->enable = 0;
  display->blink = 0;
  display->count = 2;
  // Don't change immediately, as the next instruction might be a
  // display toggle.
}


static void voyager_op_display_toggle (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  voyager_display_reg_t *display = get_chip_data (nut_reg->display_chip);

  display->enable = ! display->enable;
  display->count = 0;  // force immediate display update
}


static void voyager_op_display_blink (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  voyager_display_reg_t *display = get_chip_data (nut_reg->display_chip);

  display->enable = 1;
  display->blink = 1;
  display->blink_state = 1;
  display->blink_count = VOYAGER_DISPLAY_BLINK_DIVISOR;
  display->count = 0;  // force immediate display update
}


static void voyager_display_init_ops (sim_t *sim)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  sim->display_digits = VOYAGER_DISPLAY_DIGITS;
  nut_reg->op_fcn [0x030] = voyager_op_display_blink;
  nut_reg->op_fcn [0x2e0] = voyager_op_display_off;
  nut_reg->op_fcn [0x320] = voyager_op_display_toggle;
}


static void voyager_display_reset (voyager_display_reg_t *display)
{
  display->enable = 0;
  display->blink = 0;
  display->count = 0;
}


typedef struct
{
  int reg;
  int dig;
  int bit;
} voyager_segment_info_t;


// For each of 11 digits, we need segments a-g for the actual digit,
// segment h for the decimal point, segment i for the tail of the comma,
// and segment j for the annunciator.
voyager_segment_info_t voyager_display_map [11] [10] =
  {
    {  /* leftmost position has only segment g for a minus */
      { 0,  0, 0 }, { 0,  0, 0 }, { 0,  0, 0 }, { 0,  0, 0 }, { 0,  0, 0 },
      { 0,  0, 0 }, { 0, 11, 4 }, { 0,  0, 0 }, { 0,  0, 0 },
      { 0,  0, 0 }  // no annunciator
    },
    {
      { 0,  5, 2 }, { 0,  5, 8 }, { 0,  4, 8 }, { 0, 11, 8 }, { 0,  4, 4 },
      { 0,  5, 1 }, { 0,  5, 4 }, { 0,  9, 8 }, { 0,  9, 4 },
      { 0,  0, 0 }  // no annunciator - "*" for low bat in KML, but that's
                    // not controllable by the calculator microcode
    },
    {
      { 0,  6, 8 }, { 0,  7, 2 }, { 0,  6, 2 }, { 0,  4, 2 }, { 0,  6, 1 },
      { 0,  6, 4 }, { 0,  7, 1 }, { 0,  3, 8 }, { 0,  3, 4 },
      { 0,  4, 1 }  // USER annunciator
    },
    {
      { 0, 12, 8 }, { 0, 13, 2 }, { 0, 12, 2 }, { 0,  3, 2 }, { 0, 12, 1 },
      { 0, 12, 4 }, { 0, 13, 1 }, { 0, 13, 8 }, { 0, 13, 4 },
      { 0,  3, 1 }  // f annunciator
    },
    {
      { 0,  8, 2 }, { 0,  8, 8 }, { 0,  7, 8 }, { 0,  2, 2 }, { 0,  7, 4 },
      { 0,  8, 1 }, { 0,  8, 4 }, { 0,  9, 2 }, { 0,  9, 1 },
      { 0,  2, 1 }  // g annunciator
    },
    {
      { 0, 10, 8 }, { 0, 11, 2 }, { 0, 10, 2 }, { 0,  1, 8 }, { 0, 10, 1 },
      { 0, 10, 4 }, { 0, 11, 1 }, { 0,  2, 8 }, { 0,  2, 4 },
      { 0,  1, 4 }  // BEGIN annunciator
    },
    {
      { 1,  2, 8 }, { 1,  3, 2 }, { 1,  2, 2 }, { 1,  3, 8 }, { 1,  2, 1 },
      { 1,  2, 4 }, { 1,  3, 1 }, { 1,  4, 2 }, { 1,  4, 1 },
      { 1,  3, 4 }  // G annunciator (for GRAD, or overflow on 16C)
    },
    {
      { 1,  5, 2 }, { 1,  5, 8 }, { 1,  4, 8 }, { 1,  1, 8 }, { 1,  4, 4 },
      { 1,  5, 1 }, { 1,  5, 4 }, { 1,  6, 2 }, { 1,  6, 1 },
      { 1,  1, 4 }  // RAD annunciator
    },
    {
      { 1,  7, 2 }, { 1,  7, 8 }, { 1,  6, 8 }, { 1,  9, 8 }, { 1,  6, 4 },
      { 1,  7, 1 }, { 1,  7, 4 }, { 1,  9, 2 }, { 1,  9, 1 },
      { 1,  9, 4 }  // D.MY annunciator
    },
    {
      { 1, 11, 8 }, { 1, 12, 2 }, { 1, 11, 2 }, { 1,  8, 2 }, { 1, 11, 1 },
      { 1, 11, 4 }, { 1, 12, 1 }, { 1,  8, 8 }, { 1,  8, 4 },
      { 1,  8, 1 }  // C annunciator (Complex on 15C, Carry on 16C)
    },
    {
      { 1, 13, 2 }, { 1, 13, 8 }, { 1, 12, 8 }, { 1, 10, 2 }, { 1, 12, 4 },
      { 1, 13, 1 }, { 1, 13, 4 }, { 1, 10, 8 }, { 1, 10, 4 },
      { 1, 10, 1 }  // PRGM annunciator
    }
  };


static void voyager_display_update (sim_t *sim, voyager_display_reg_t *display)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  int digit;
  int segment;

  for (digit = 0; digit < VOYAGER_DISPLAY_DIGITS; digit++)
    {
      sim->display_segments [digit] = 0;
      if (display->enable &&
	  ((! display->blink) || (display->blink_state)))
	{
	  for (segment = 0; segment <= 9; segment++)
	    {
	      int vreg = voyager_display_map [digit][segment].reg;
	      int vdig = voyager_display_map [digit][segment].dig;
	      int vbit = voyager_display_map [digit][segment].bit;
	      if (vbit && (nut_reg->ram [9 + vreg][vdig] & vbit))
		{
		  if (segment < 9)
		    sim->display_segments [digit] |= (1 << segment);
		  else
		    sim->display_segments [digit] |= SEGMENT_ANN;
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
	  display->blink_count = VOYAGER_DISPLAY_BLINK_DIVISOR;
	}
    }
}


static void voyager_display_event_fn (sim_t  *sim,
				      chip_t *chip,
				      int    event,
				      int    arg,
				      void   *data)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  voyager_display_reg_t *display = get_chip_data (nut_reg->display_chip);

  switch (event)
    {
    case event_reset:
       voyager_display_reset (display);
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
      voyager_display_update (sim, display);
      sim_send_display_update_to_gui (sim);
      display->count = 15;
      break;
    default:
      // warning ("voyager_lcd: unknown event %d\n", event);
      break;
    }
}


void voyager_display_init (sim_t *sim)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  voyager_display_reg_t *display;

  voyager_display_init_ops (sim);

  display = alloc (sizeof (voyager_display_reg_t));

  nut_reg->display_chip = install_chip (sim,
					& voyager_display_chip_detail,
					display);
}
