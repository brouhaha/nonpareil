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
#include "coconut_lcd.h"
#include "proc_int.h"
#include "proc_nut.h"


typedef struct
{
  uint8_t pfaddr;
  uint8_t pfaddr_halfnut;

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


#define CLR(name, field, bits, radix, get, set, arg) \
    {{ name, bits, 1, radix },                       \
     OFFSET_OF (coconut_display_reg_t, field),       \
     SIZE_OF (coconut_display_reg_t, field),         \
     get, set, arg } 


#define CLRD(name, field, digits)              \
    {{ name, digits * 4, 1, 16 },              \
     OFFSET_OF (coconut_display_reg_t, field), \
     SIZE_OF (coconut_display_reg_t, field),   \
     get_digits, set_digits, digits } 


static reg_detail_t coconut_display_reg_detail [] =
{
  //    name      field   bits radix get   set   arg
  CLR  ("enable", enable, 1,   2,    NULL, NULL, 0),
  CLR  ("blink",  blink,  1,   2,    NULL, NULL, 0),

  //    name     field  digits
  CLRD ("a",     a,     COCONUT_DISPLAY_DIGITS),
  CLRD ("b",     b,     COCONUT_DISPLAY_DIGITS),
  CLRD ("c",     c,     COCONUT_DISPLAY_DIGITS),

  //    name     field  bits                    radix get   set   arg
  CLR  ("ann",   ann,   COCONUT_DISPLAY_DIGITS, 2,    NULL, NULL, 0)
};


static void coconut_op_display_off (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  coconut_display_reg_t *display = get_chip_data (nut_reg->display_chip);

  display->enable = false;
  display->count = 2;
  // Don't change immediately, as the next instruction might be a
  // display toggle.
}


static void coconut_op_display_toggle (sim_t *sim, int opcode)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  coconut_display_reg_t *display = get_chip_data (nut_reg->display_chip);

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
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  coconut_display_reg_t *display = get_chip_data (nut_reg->display_chip);

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
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  coconut_display_reg_t *display = get_chip_data (nut_reg->display_chip);

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
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  coconut_display_reg_t *display = get_chip_data (nut_reg->display_chip);

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


static void coconut_display_init_ops (sim_t *sim)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  sim->display_digits = COCONUT_DISPLAY_DIGITS;
  nut_reg->op_fcn [0x2e0] = coconut_op_display_off;
  nut_reg->op_fcn [0x320] = coconut_op_display_toggle;
  nut_reg->op_fcn [0x3fc] = coconut_op_display_compensation;
}


static chip_event_fn_t coconut_display_event_fn;


static chip_detail_t coconut_display_chip_detail =
{
  {
    "Coconut LCD",
    false  // There can only be one set of LCD drivers on the bus.
  },
  sizeof (coconut_display_reg_detail) / sizeof (reg_detail_t),
  coconut_display_reg_detail,
  coconut_display_event_fn
};


static void coconut_display_reset (coconut_display_reg_t *display)
{
  int i;

  display->enable = false;
  display->blink = false;
  display->count = 0;

  for (i = 0; i < COCONUT_DISPLAY_DIGITS; i++)
    {
      display->a [i] = 0;
      display->b [i] = 0;
      display->c [i] = 0;
    }
  display->ann = 0;
}


static void coconut_display_update (sim_t *sim,
				    coconut_display_reg_t *display)
{
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


static void coconut_display_event_fn (sim_t *sim, chip_t *chip, int event)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  coconut_display_reg_t *display = get_chip_data (nut_reg->display_chip);

  switch (event)
    {
    case event_reset:
       coconut_display_reset (display);
       break;
    case event_cycle:
      if (display->count == 0)
	{
	  coconut_display_update (sim, display);
	  gui_display_update (sim);
	  display->count = 15;
	}
      else
	display->count --;
      break;
    case event_sleep:
      // force display update
      coconut_display_update (sim, display);
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
      coconut_display_update (sim, display);
      gui_display_update (sim);
      display->count = 15;
      break;
    default:
      // warning ("coconut_lcd: unknown event %d\n", event);
      break;
    }
}


void coconut_display_init (sim_t *sim)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  coconut_display_reg_t *display;

  coconut_display_init_ops (sim);

  display = alloc (sizeof (coconut_display_reg_t));

  display->pfaddr         = PFADDR_LCD_DISPLAY;
  display->pfaddr_halfnut = PFADDR_HALFNUT;

  nut_reg->pf_exists [display->pfaddr] = 1;
  nut_reg->rd_n_fcn  [display->pfaddr] = & coconut_lcd_rd_n;
  nut_reg->wr_n_fcn  [display->pfaddr] = & coconut_lcd_wr_n;
  nut_reg->wr_fcn    [display->pfaddr] = & coconut_lcd_wr;

  nut_reg->display_chip = install_chip (sim,
					& coconut_display_chip_detail,
					display);

  nut_reg->pf_exists [display->pfaddr_halfnut] = 1;
  nut_reg->rd_n_fcn  [display->pfaddr_halfnut] = & halfnut_lcd_rd_n;
  nut_reg->wr_n_fcn  [display->pfaddr_halfnut] = & halfnut_lcd_wr_n;
  nut_reg->wr_fcn    [display->pfaddr_halfnut] = & halfnut_lcd_wr;
}
