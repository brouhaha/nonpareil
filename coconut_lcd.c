/*
NSIM is a simulator for the processor used in the HP-41 (Nut) and in the HP
Series 10 (Voyager) calculators.

$Id$
Copyright 1995, 2003 Eric Smith <eric@brouhaha.com>

NSIM is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License version 2 as published by the Free
Software Foundation.  Note that I am not granting permission to redistribute
or modify NSIM under the terms of any later version of the General Public
License.

This program is distributed in the hope that it will be useful (or at least
amusing), but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with
this program (in the file "COPYING"); if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

#include "arch.h"
#include "display.h"
#include "proc.h"
#include "coconut_lcd.h"
#include "proc_int.h"
#include "proc_nut.h"


static void coconut_op_display_off (sim_t *sim, int opcode)
{
  sim->env->display_enable = 0;
  sim->env->display_count = 2;
  // Don't change immediately, as the next instruction might be a
  // display toggle.
}


static void coconut_op_display_toggle (sim_t *sim, int opcode)
{
  sim->env->display_enable = ! sim->env->display_enable;
  sim->env->display_count = 0;  /* force immediate display update */
}


#define A 1
#define B 2
#define C 4
#define AB 3
#define ABC 7


#define LEFT (DISPLAY_DIGITS - 1)
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


static void coconut_lcd_rd_reg (sim_t *sim, int reg, int chars, int dir)
{
  int i, j;
  j = 0;
  for (i = 0; i < chars; i++)
    {
      if (reg & A)
	{
	  sim->env->c [j++] = sim->env->lcd_a [dir];
	  coconut_lcd_rot (& sim->env->lcd_a [0], dir);
	}
      if (reg & B)
	{
	  sim->env->c [j++] = sim->env->lcd_b [dir];
	  coconut_lcd_rot (& sim->env->lcd_b [0], dir);
	}
      if (reg & C)
	{
	  sim->env->c [j++] = sim->env->lcd_c [dir];
	  coconut_lcd_rot (& sim->env->lcd_c [0], dir);
	}
    }
}


static void coconut_lcd_wr_reg (sim_t *sim, int reg, int chars, int dir)
{
  int i, j;
  j = 0;
  for (i = 0; i < chars; i++)
    {
      if (reg & A)
	{
	  coconut_lcd_rot (& sim->env->lcd_a [0], LEFT - dir);
	  sim->env->lcd_a [dir] = sim->env->c [j++];
	}
      if (reg & B)
	{
	  coconut_lcd_rot (& sim->env->lcd_b [0], LEFT - dir);
	  sim->env->lcd_b [dir] = sim->env->c [j++];
	}
      if (reg & C)
	{
	  coconut_lcd_rot (& sim->env->lcd_c [0], LEFT - dir);
	  sim->env->lcd_c [dir] = sim->env->c [j++] & 1;
	}
    }
}


static void coconut_lcd_rd_ann (sim_t *sim)
{
  sim->env->c [2] = sim->env->lcd_ann >> 8;
  sim->env->c [1] = (sim->env->lcd_ann >> 4) & 0x0f;
  sim->env->c [0] = sim->env->lcd_ann & 0x0f;
}


static void coconut_lcd_wr_ann (sim_t *sim)
{
  sim->env->lcd_ann = ((sim->env->c [2] << 8) | 
		       (sim->env->c [1] << 4) |
		       (sim->env->c [0]));
}


static void coconut_lcd_rd_n (sim_t *sim, int n)
{
  switch (n)
    {
    case 0x0:  coconut_lcd_rd_reg (sim, A,   12, LEFT);  break;
    case 0x1:  coconut_lcd_rd_reg (sim, B,   12, LEFT);  break;
    case 0x2:  coconut_lcd_rd_reg (sim, C,   12, LEFT);  break;
    case 0x3:  coconut_lcd_rd_reg (sim, AB,   6, LEFT);  break;
    case 0x4:  coconut_lcd_rd_reg (sim, ABC,  4, LEFT);  break;
    case 0x5:  coconut_lcd_rd_ann (sim);             break;
    case 0x6:  coconut_lcd_rd_reg (sim, C,    1, LEFT);  break;
    case 0x7:  coconut_lcd_rd_reg (sim, A,    1, RIGHT); break;
    case 0x8:  coconut_lcd_rd_reg (sim, B,    1, RIGHT); break;
    case 0x9:  coconut_lcd_rd_reg (sim, C,    1, RIGHT); break;
    case 0xa:  coconut_lcd_rd_reg (sim, A,    1, LEFT);  break;
    case 0xb:  coconut_lcd_rd_reg (sim, B,    1, LEFT);  break;
    case 0xc:  coconut_lcd_rd_reg (sim, AB,   1, RIGHT); break;
    case 0xd:  coconut_lcd_rd_reg (sim, AB,   1, LEFT);  break;
    case 0xe:  coconut_lcd_rd_reg (sim, ABC,  1, RIGHT); break;
    case 0xf:  coconut_lcd_rd_reg (sim, ABC,  1, LEFT);  break;
    }
}

static void coconut_lcd_wr_n (sim_t *sim, int n)
{
  switch (n)
    {
    case 0x0:  coconut_lcd_wr_reg (sim, A,   12, LEFT);  break;
    case 0x1:  coconut_lcd_wr_reg (sim, B,   12, LEFT);  break;
    case 0x2:  coconut_lcd_wr_reg (sim, C,   12, LEFT);  break;
    case 0x3:  coconut_lcd_wr_reg (sim, AB,   6, LEFT);  break;
    case 0x4:  coconut_lcd_wr_reg (sim, ABC,  4, LEFT);  break;
    case 0x5:  coconut_lcd_wr_reg (sim, AB,   6, RIGHT); break;
    case 0x6:  coconut_lcd_wr_reg (sim, ABC,  4, RIGHT); break;
    case 0x7:  coconut_lcd_wr_reg (sim, A,    1, LEFT);  break;
    case 0x8:  coconut_lcd_wr_reg (sim, B,    1, LEFT);  break;
    case 0x9:  coconut_lcd_wr_reg (sim, C,    1, LEFT);  break;
    case 0xa:  coconut_lcd_wr_reg (sim, A,    1, RIGHT); break;
    case 0xb:  coconut_lcd_wr_reg (sim, B,    1, RIGHT); break;
    case 0xc:  coconut_lcd_wr_reg (sim, C,    1, RIGHT); break;
    case 0xd:  coconut_lcd_wr_reg (sim, AB,   1, RIGHT); break;
    case 0xe:  coconut_lcd_wr_reg (sim, ABC,  1, LEFT);  break;
    case 0xf:  coconut_lcd_wr_reg (sim, ABC,  1, RIGHT); break;
    }
}

static void coconut_lcd_wr (sim_t *sim)
{
  coconut_lcd_wr_ann (sim);
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
  sim->op_fcn [0x2e0] = coconut_op_display_off;
  sim->op_fcn [0x320] = coconut_op_display_toggle;
}


void coconut_display_reset (sim_t *sim)
{
  int i;

  sim->env->display_enable = 0;
  sim->env->display_count = 0;

  sim->pf_exists [LCD_DISPLAY] = 1;
  sim->rd_n_fcn [LCD_DISPLAY] = & coconut_lcd_rd_n;
  sim->wr_n_fcn [LCD_DISPLAY] = & coconut_lcd_wr_n;
  sim->wr_fcn   [LCD_DISPLAY] = & coconut_lcd_wr;

  sim->pf_exists [HALFNUT] = 1;
  sim->rd_n_fcn  [HALFNUT] = & halfnut_lcd_rd_n;
  sim->wr_n_fcn  [HALFNUT] = & halfnut_lcd_wr_n;
  sim->wr_fcn    [HALFNUT] = & halfnut_lcd_wr;

  for (i = 0; i < DISPLAY_DIGITS; i++)
    {
      sim->env->lcd_a [i] = 0;
      sim->env->lcd_b [i] = 0;
      sim->env->lcd_c [i] = 0;
    }
  sim->env->lcd_ann = 0;
}


void coconut_display_update (sim_t *sim)
{
  int i;
  for (i = LEFT; i >= RIGHT; i--)
    {
      int segments = 0;
      if (sim->env->display_enable)
	{
	  int b = sim->env->lcd_b [i];
	  int c = ((b & 3) << 4) + sim->env->lcd_a [i];
	  segments = sim->char_gen [c];
	  switch (b >> 2)
	    {
	    case 0:  break;  /* no punctuation */
	    case 1:  segments |= SEGMENTS_PERIOD; break;
	    case 2:  segments |= SEGMENTS_COLON;  break;
	    case 3:  segments |= SEGMENTS_COMMA;  break;
	    }
	  if (sim->env->lcd_ann & (1 << i))
	    segments |= SEGMENT_ANN;
	}
      sim->display_segments [i] = segments;
    }

  sim->display_update_fn (sim->display_handle, DISPLAY_DIGITS,
			  sim->display_segments);
}

