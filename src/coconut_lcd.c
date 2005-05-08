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
#include "coconut_lcd.h"
#include "proc_int.h"
#include "proc_nut.h"


typedef struct
{
  bool enable;
  int count;

  bool blink;
  bool blink_state;
  int blink_count;

  digit_t a [COCONUT_DISPLAY_DIGITS];
  digit_t b [COCONUT_DISPLAY_DIGITS];
  digit_t c [COCONUT_DISPLAY_DIGITS];
  uint16_t ann;
} coconut_display_reg_t;


static reg_accessor_t get_coconut_lcd_4, set_coconut_lcd_4;
static reg_accessor_t get_coconut_lcd_1, set_coconut_lcd_1;


static reg_detail_t coconut_display_reg_detail [] =
{
  {{ "enable", 1, 1, 2 }, OFFSET_OF (coconut_display_reg_t, enable), NULL, NULL },
  {{ "blink",  1, 1, 2 }, OFFSET_OF (coconut_display_reg_t, blink),  NULL, NULL },
  {{ "a",      COCONUT_DISPLAY_DIGITS * 4,  1, 16 }, OFFSET_OF (coconut_display_reg_t, a),    get_coconut_lcd_4, set_coconut_lcd_4 },
  {{ "b",      COCONUT_DISPLAY_DIGITS * 4,  1, 16 }, OFFSET_OF (coconut_display_reg_t, b),    get_coconut_lcd_4, set_coconut_lcd_4 },
  {{ "c",      COCONUT_DISPLAY_DIGITS * 1,  1, 16 }, OFFSET_OF (coconut_display_reg_t, c),    get_coconut_lcd_1, set_coconut_lcd_1 },
  {{ "ann",    COCONUT_DISPLAY_DIGITS,      1,  2 }, OFFSET_OF (coconut_display_reg_t, ann),  NULL, NULL },
};


static bool get_coconut_lcd_4 (void *data, size_t offset, uint64_t *p)
{
  uint64_t val;
  uint8_t *d;
  int i;

  d = ((uint8_t *) data) + offset + COCONUT_DISPLAY_DIGITS;
  val = 0;
  for (i = 0; i < COCONUT_DISPLAY_DIGITS; i++)
    val = (val << 4) + *(--d);

  *p = val;

  return true;
}


static bool set_coconut_lcd_4 (void *data, size_t offset, uint64_t *p)
{
  uint64_t val;
  uint8_t *d;
  int i;

  val = *p;
  d = ((uint8_t *) data) + offset;
  for (i = 0; i < COCONUT_DISPLAY_DIGITS; i++)
    {
      *(d++) = val & 0x0f;
      val >>= 4;
    }

  return true;
}


static bool get_coconut_lcd_1 (void *data, size_t offset, uint64_t *p)
{
  uint64_t val;
  uint8_t *d;
  int i;

  d = ((uint8_t *) data) + offset + COCONUT_DISPLAY_DIGITS;
  val = 0;
  for (i = 0; i < COCONUT_DISPLAY_DIGITS; i++)
    val = (val << 1) + *(--d);

  *p = val;

  return true;
}


static bool set_coconut_lcd_1 (void *data, size_t offset, uint64_t *p)
{
  uint64_t val;
  uint8_t *d;
  int i;

  val = *p;
  d = ((uint8_t *) data) + offset;
  for (i = 0; i < COCONUT_DISPLAY_DIGITS; i++)
    {
      *(d++) = val & 0x01;
      val >>= 1;
    }

  return true;
}


static void coconut_op_display_off (sim_t *sim, int opcode)
{
  coconut_display_reg_t *display = sim->chip_data [PFADDR_LCD_DISPLAY];

  display->enable = false;
  display->count = 2;
  // Don't change immediately, as the next instruction might be a
  // display toggle.
}


static void coconut_op_display_toggle (sim_t *sim, int opcode)
{
  coconut_display_reg_t *display = sim->chip_data [PFADDR_LCD_DISPLAY];

  display->enable = ! display->enable;
  display->count = 0;  // force immediate display update
}


static void coconut_op_display_compensation (sim_t *sim, int opcode)
{
  /* The real hardware uses this instruction for temperature compensation.
     For the simulator, don't do anything. */
}


#define A 1
#define B 2
#define C 4
#define AB 3
#define ABC 7


#define LEFT (COCONUT_DISPLAY_DIGITS - 1)
#define RIGHT 0


static void coconut_lcd_rot (digit_t *reg, int dir)
{
  int i, t;
  if (dir == LEFT)
    {
      t = reg [LEFT];
      for (i = LEFT; i > RIGHT; i--)
	reg [i] = reg [i - 1];
      reg [RIGHT] = t;
    }
  else
    {
      t = reg [0];
      for (i = RIGHT; i < LEFT; i++)
	reg [i] = reg [i + 1];
      reg [LEFT] = t;
    }
}


static void coconut_lcd_rd_reg (nut_reg_t *nut_reg,
				coconut_display_reg_t *display,
				int reg,
				int chars,
				int dir)
{
  int i, j;
  j = 0;
  // $$ should zero Nut C register digits not read
  for (i = 0; i < chars; i++)
    {
      if (reg & A)
	{
	  nut_reg->c [j++] = display->a [dir];
	  coconut_lcd_rot (& display->a [0], dir);
	}
      if (reg & B)
	{
	  nut_reg->c [j++] = display->b [dir];
	  coconut_lcd_rot (& display->b [0], dir);
	}
      if (reg & C)
	{
	  nut_reg->c [j++] = display->c [dir];
	  coconut_lcd_rot (& display->c [0], dir);
	}
    }
}


static void coconut_lcd_wr_reg (nut_reg_t *nut_reg,
				coconut_display_reg_t *display,
				int reg,
				int chars,
				int dir)
{
  int i, j;
  j = 0;
  for (i = 0; i < chars; i++)
    {
      if (reg & A)
	{
	  coconut_lcd_rot (& display->a [0], LEFT - dir);
	  display->a [dir] = nut_reg->c [j++];
	}
      if (reg & B)
	{
	  coconut_lcd_rot (& display->b [0], LEFT - dir);
	  display->b [dir] = nut_reg->c [j++];
	}
      if (reg & C)
	{
	  coconut_lcd_rot (& display->c [0], LEFT - dir);
	  display->c [dir] = nut_reg->c [j++] & 1;
	}
    }
}


static void coconut_lcd_rd_ann (nut_reg_t *nut_reg, coconut_display_reg_t *display)
{
  // $$ should zero Nut C register digits not read
  nut_reg->c [2] = display->ann >> 8;
  nut_reg->c [1] = (display->ann >> 4) & 0x0f;
  nut_reg->c [0] = display->ann & 0x0f;
}


static void coconut_lcd_wr_ann (nut_reg_t *nut_reg, coconut_display_reg_t *display)
{
  display->ann = ((nut_reg->c [2] << 8) | 
		  (nut_reg->c [1] << 4) |
		  (nut_reg->c [0]));
}


static void coconut_lcd_rd_n (sim_t *sim, int n)
{
  nut_reg_t *nut_reg = sim->chip_data [0];
  coconut_display_reg_t *display = sim->chip_data [PFADDR_LCD_DISPLAY];

  switch (n)
    {
    case 0x0:  coconut_lcd_rd_reg (nut_reg, display, A,   12, LEFT);  break;
    case 0x1:  coconut_lcd_rd_reg (nut_reg, display, B,   12, LEFT);  break;
    case 0x2:  coconut_lcd_rd_reg (nut_reg, display, C,   12, LEFT);  break;
    case 0x3:  coconut_lcd_rd_reg (nut_reg, display, AB,   6, LEFT);  break;
    case 0x4:  coconut_lcd_rd_reg (nut_reg, display, ABC,  4, LEFT);  break;
    case 0x5:  coconut_lcd_rd_ann (nut_reg, display);             break;
    case 0x6:  coconut_lcd_rd_reg (nut_reg, display, C,    1, LEFT);  break;
    case 0x7:  coconut_lcd_rd_reg (nut_reg, display, A,    1, RIGHT); break;
    case 0x8:  coconut_lcd_rd_reg (nut_reg, display, B,    1, RIGHT); break;
    case 0x9:  coconut_lcd_rd_reg (nut_reg, display, C,    1, RIGHT); break;
    case 0xa:  coconut_lcd_rd_reg (nut_reg, display, A,    1, LEFT);  break;
    case 0xb:  coconut_lcd_rd_reg (nut_reg, display, B,    1, LEFT);  break;
    case 0xc:  coconut_lcd_rd_reg (nut_reg, display, AB,   1, RIGHT); break;
    case 0xd:  coconut_lcd_rd_reg (nut_reg, display, AB,   1, LEFT);  break;
    case 0xe:  coconut_lcd_rd_reg (nut_reg, display, ABC,  1, RIGHT); break;
    case 0xf:  coconut_lcd_rd_reg (nut_reg, display, ABC,  1, LEFT);  break;
    }
}

static void coconut_lcd_wr_n (sim_t *sim, int n)
{
  nut_reg_t *nut_reg = sim->chip_data [0];
  coconut_display_reg_t *display = sim->chip_data [PFADDR_LCD_DISPLAY];

  switch (n)
    {
    case 0x0:  coconut_lcd_wr_reg (nut_reg, display, A,   12, LEFT);  break;
    case 0x1:  coconut_lcd_wr_reg (nut_reg, display, B,   12, LEFT);  break;
    case 0x2:  coconut_lcd_wr_reg (nut_reg, display, C,   12, LEFT);  break;
    case 0x3:  coconut_lcd_wr_reg (nut_reg, display, AB,   6, LEFT);  break;
    case 0x4:  coconut_lcd_wr_reg (nut_reg, display, ABC,  4, LEFT);  break;
    case 0x5:  coconut_lcd_wr_reg (nut_reg, display, AB,   6, RIGHT); break;
    case 0x6:  coconut_lcd_wr_reg (nut_reg, display, ABC,  4, RIGHT); break;
    case 0x7:  coconut_lcd_wr_reg (nut_reg, display, A,    1, LEFT);  break;
    case 0x8:  coconut_lcd_wr_reg (nut_reg, display, B,    1, LEFT);  break;
    case 0x9:  coconut_lcd_wr_reg (nut_reg, display, C,    1, LEFT);  break;
    case 0xa:  coconut_lcd_wr_reg (nut_reg, display, A,    1, RIGHT); break;
    case 0xb:  coconut_lcd_wr_reg (nut_reg, display, B,    1, RIGHT); break;
    case 0xc:  coconut_lcd_wr_reg (nut_reg, display, C,    1, RIGHT); break;
    case 0xd:  coconut_lcd_wr_reg (nut_reg, display, AB,   1, RIGHT); break;
    case 0xe:  coconut_lcd_wr_reg (nut_reg, display, ABC,  1, LEFT);  break;
    case 0xf:  coconut_lcd_wr_reg (nut_reg, display, ABC,  1, RIGHT); break;
    }
}

static void coconut_lcd_wr (sim_t *sim)
{
  nut_reg_t *nut_reg = sim->chip_data [0];
  coconut_display_reg_t *display = sim->chip_data [PFADDR_LCD_DISPLAY];

  coconut_lcd_wr_ann (nut_reg, display);
}

static void halfnut_lcd_rd_n (sim_t *sim, int n)
{
}

static void halfnut_lcd_wr_n (sim_t *sim, int n)
{
}

static void halfnut_lcd_wr (sim_t *sim)
{
}


void coconut_display_init_ops (sim_t *sim)
{
  sim->display_digits = COCONUT_DISPLAY_DIGITS;
  sim->op_fcn [0x2e0] = coconut_op_display_off;
  sim->op_fcn [0x320] = coconut_op_display_toggle;
  sim->op_fcn [0x3fc] = coconut_op_display_compensation;
}


void coconut_display_fn (sim_t *sim, int chip_num, int event)
{
  nut_reg_t *nut_reg = sim->chip_data [0];
  coconut_display_reg_t *display = sim->chip_data [PFADDR_LCD_DISPLAY];

  switch (event)
    {
    case event_cycle:
      if (display->count == 0)
	{
	  coconut_display_update (sim);
	  gui_display_update (sim);
	  display->count = 15;
	}
      else
	display->count --;
      break;
    case event_sleep:
      // force display update
      coconut_display_update (sim);
      gui_display_update (sim);
      display->count = 15;

      if (display->enable)
	{
	  /* going to light sleep */
#ifdef AUTO_POWER_OFF
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
      coconut_display_update (sim);
      gui_display_update (sim);
      display->count = 15;
      break;
    default:
      // warning ("coconut_lcd: unknown event %d\n", event);
      break;
    }
}


static chip_detail_t coconut_display_chip_detail =
{
  {
    "Coconut LCD",
    PFADDR_LCD_DISPLAY
  },
  sizeof (coconut_display_reg_detail) / sizeof (reg_detail_t),
  coconut_display_reg_detail,
  coconut_display_fn
};


void coconut_display_reset (sim_t *sim)
{
  nut_reg_t *nut_reg = sim->chip_data [0];
  coconut_display_reg_t *display;
  int i;

  display = alloc (sizeof (coconut_display_reg_t));

  display->enable = false;
  display->blink = false;
  display->count = 0;

  nut_reg->pf_exists [PFADDR_LCD_DISPLAY] = 1;
  sim->rd_n_fcn [PFADDR_LCD_DISPLAY] = & coconut_lcd_rd_n;
  sim->wr_n_fcn [PFADDR_LCD_DISPLAY] = & coconut_lcd_wr_n;
  sim->wr_fcn   [PFADDR_LCD_DISPLAY] = & coconut_lcd_wr;

  install_chip (sim,
		PFADDR_LCD_DISPLAY, 
		& coconut_display_chip_detail,
		display);

  nut_reg->pf_exists [PFADDR_HALFNUT] = 1;
  sim->rd_n_fcn  [PFADDR_HALFNUT] = & halfnut_lcd_rd_n;
  sim->wr_n_fcn  [PFADDR_HALFNUT] = & halfnut_lcd_wr_n;
  sim->wr_fcn    [PFADDR_HALFNUT] = & halfnut_lcd_wr;

  for (i = 0; i < COCONUT_DISPLAY_DIGITS; i++)
    {
      display->a [i] = 0;
      display->b [i] = 0;
      display->c [i] = 0;
    }
  display->ann = 0;
}


void coconut_display_update (sim_t *sim)
{
  coconut_display_reg_t *display = sim->chip_data [PFADDR_LCD_DISPLAY];
  int i;
  int j = 0;

  for (i = LEFT; i >= RIGHT; i--)
    {
      int segments = 0;
      if (display->enable)
	{
	  int b = display->b [i];
	  int c = ((display->c [i] << 6) +
		   ((b & 3) << 4) +
		   display->a [i]);
	  segments = sim->char_gen [c];
	  switch (b >> 2)
	    {
	    case 0:  break;  /* no punctuation */
	    case 1:  segments |= SEGMENTS_PERIOD; break;
	    case 2:  segments |= SEGMENTS_COLON;  break;
	    case 3:  segments |= SEGMENTS_COMMA;  break;
	    }
	  if (display->ann & (1 << i))
	    segments |= SEGMENT_ANN;
	}
      sim->display_segments [j++] = segments;
    }
}

