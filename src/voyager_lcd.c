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
#include "voyager_lcd.h"
#include "proc_int.h"
#include "proc_nut.h"


#define VOYAGER_LCD_DEBUG
#define VOYAGER_DISPLAY_BLINK_DIVISOR 150


typedef struct
{
  bool enable;
  int count;

  bool blink;
  bool blink_state;
  int blink_count;
} voyager_display_reg_t;


static reg_detail_t voyager_display_reg_detail [] =
{
  {{ "enable", 1, 1, 2 }, OFFSET_OF (voyager_display_reg_t, enable), NULL, NULL },
  {{ "blink",  1, 1, 2 }, OFFSET_OF (voyager_display_reg_t, blink),  NULL, NULL }
};


static chip_fn_t voyager_display_fn;


static chip_detail_t voyager_display_chip_detail =
{
  {
    "Voyager LCD",
    0
  },
  sizeof (voyager_display_reg_detail) / sizeof (reg_detail_t),
  voyager_display_reg_detail,
  voyager_display_fn
};


static void voyager_op_display_off (sim_t *sim, int opcode)
{
  voyager_display_reg_t *display = sim->chip_data [PFADDR_LCD_DISPLAY];

#ifdef VOYAGER_LCD_DEBUG
  printf ("display off\n");
#endif
  display->enable = 0;
  display->blink = 0;
  display->count = 2;
  // Don't change immediately, as the next instruction might be a
  // display toggle.
}


static void voyager_op_display_toggle (sim_t *sim, int opcode)
{
  voyager_display_reg_t *display = sim->chip_data [PFADDR_LCD_DISPLAY];

#ifdef VOYAGER_LCD_DEBUG
  printf ("display toggle\n");
#endif
  display->enable = ! display->enable;
  display->count = 0;  // force immediate display update
}


static void voyager_op_display_blink (sim_t *sim, int opcode)
{
  voyager_display_reg_t *display = sim->chip_data [PFADDR_LCD_DISPLAY];

#ifdef VOYAGER_LCD_DEBUG
  printf ("display blink\n");
#endif
  display->enable = 1;
  display->blink = 1;
  display->blink_state = 1;
  display->blink_count = VOYAGER_DISPLAY_BLINK_DIVISOR;
  display->count = 0;  // force immediate display update
}


void voyager_display_init_ops (sim_t *sim)
{
  sim->display_digits = VOYAGER_DISPLAY_DIGITS;
  sim->op_fcn [0x030] = voyager_op_display_blink;
  sim->op_fcn [0x2e0] = voyager_op_display_off;
  sim->op_fcn [0x320] = voyager_op_display_toggle;
}


void voyager_display_reset (sim_t *sim)
{
  voyager_display_reg_t *display = sim->chip_data [PFADDR_LCD_DISPLAY];

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


voyager_segment_info_t voyager_display_map [11] [9] =
  {
    {  /* leftmost position has only segment g for a minus */
      {  0, 0, 0 }, { 0,  0, 0 }, { 0,  0, 0 }, { 0,  0, 0 }, { 0,  0, 0 },
      {  0, 0, 0 }, { 0, 11, 4 }, { 0,  0, 0 }, { 0,  0, 0 }
    },
    {
      { 0,  5, 2 }, { 0,  5, 8 }, { 0,  4, 8 }, { 0, 11, 8 }, { 0,  4, 4 },
      { 0,  5, 1 }, { 0,  5, 4 }, { 0,  9, 8 }, { 0,  9, 4 }
    },
    {
      { 0,  6, 8 }, { 0,  7, 2 }, { 0,  6, 2 }, { 0,  4, 2 }, { 0,  6, 1 },
      { 0,  6, 4 }, { 0,  7, 1 }, { 0,  3, 8 }, { 0,  3, 4 }
    },
    {
      { 0, 12, 8 }, { 0, 13, 2 }, { 0, 12, 2 }, { 0,  3, 2 }, { 0, 12, 1 },
      { 0, 12, 4 }, { 0, 13, 1 }, { 0, 13, 8 }, { 0, 13, 4 }
    },
    {
      { 0,  8, 2 }, { 0,  8, 8 }, { 0,  7, 8 }, { 0,  2, 2 }, { 0,  7, 4 },
      { 0,  8, 1 }, { 0,  8, 4 }, { 0,  9, 2 }, { 0,  9, 1 }
    },
    {
      { 0, 10, 8 }, { 0, 11, 2 }, { 0, 10, 2 }, { 0,  1, 8 }, { 0, 10, 1 },
      { 0, 10, 4 }, { 0, 11, 1 }, { 0,  2, 8 }, { 0,  2, 4 }
    },
    {
      { 1,  2, 8 }, { 1,  3, 2 }, { 1,  2, 2 }, { 1,  3, 8 }, { 1,  2, 1 },
      { 1,  2, 4 }, { 1,  3, 1 }, { 1,  4, 2 }, { 1,  4, 1 }
    },
    {
      { 1,  5, 2 }, { 1,  5, 8 }, { 1,  4, 8 }, { 1,  1, 8 }, { 1,  4, 4 },
      { 1,  5, 1 }, { 1,  5, 4 }, { 1,  6, 2 }, { 1,  6, 1 }
    },
    {
      { 1,  7, 2 }, { 1,  7, 8 }, { 1,  6, 8 }, { 1,  9, 8 }, { 1,  6, 4 },
      { 1,  7, 1 }, { 1,  7, 4 }, { 1,  9, 2 }, { 1,  9, 1 }
    },
    {
      { 1, 11, 8 }, { 1, 12, 2 }, { 1, 11, 2 }, { 1,  8, 2 }, { 1, 11, 1 },
      { 1, 11, 4 }, { 1, 12, 1 }, { 1,  8, 8 }, { 1,  8, 4 }
    },
    {
      { 1, 13, 2 }, { 1, 13, 8 }, { 1, 12, 8 }, { 1, 10, 2 }, { 1, 12, 4 },
      { 1, 13, 1 }, { 1, 13, 4 }, { 1, 10, 8 }, { 1, 10, 4 }
    }
  };


void voyager_display_update (sim_t *sim)
{
  nut_reg_t *nut_reg = sim->chip_data [0];
  voyager_display_reg_t *display = sim->chip_data [PFADDR_LCD_DISPLAY];

  int digit;
  int segment;

  for (digit = 0; digit < VOYAGER_DISPLAY_DIGITS; digit++)
    {
      sim->display_segments [digit] = 0;
      if (display->enable &&
	  ((! display->blink) || (display->blink_state)))
	{
	  for (segment = 0; segment < 8; segment++)
	    {
	      int vreg = voyager_display_map [digit][segment].reg;
	      int vdig = voyager_display_map [digit][segment].dig;
	      int vbit = voyager_display_map [digit][segment].bit;
	      if (vbit && (nut_reg->ram [9 + vreg][vdig] & vbit))
		sim->display_segments [digit] |= (1 << segment);
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


void voyager_display_fn (sim_t *sim, int chip_num, int event)
{
  nut_reg_t *nut_reg = sim->chip_data [0];
  voyager_display_reg_t *display = sim->chip_data [PFADDR_LCD_DISPLAY];

  switch (event)
    {
    case nut_event_cycle:
      if (display->count == 0)
	{
	  voyager_display_update (sim);
	  gui_display_update (sim);
	  display->count = 15;
	}
      else
	display->count --;
      break;
    case nut_event_power_down:
      display->count = 0;  // force display update
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
    case nut_event_power_up:
      break;
    default:
      fatal (3, "voyager_lcd: unknown event %d\n", event);
    }
}
