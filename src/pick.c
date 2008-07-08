/*
$Id$
Copyright 2007, 2008 Eric Smith <eric@brouhaha.com>

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
#include "keyboard.h"
#include "chip.h"
#include "proc.h"
#include "digit_ops.h"
#include "calcdef.h"
#include "proc_int.h"
#include "proc_woodstock.h"
#include "pick.h"


typedef struct
{
  int count;
  int head;
  int tail;
  int keycode [PICK_KEY_BUFFER_SIZE];
} key_buffer_t;

typedef struct
{
  key_buffer_t key_buffer;
  const segment_bitmap_t *printer_char_gen;
} pick_reg_t;


static reg_detail_t pick_reg_detail [] =
{
};


static chip_event_fn_t pick_event_fn;


static chip_detail_t pick_chip_detail =
{
  {
    "PICK",
    CHIP_WOODSTOCK_PICK,
    false
  },
  sizeof (pick_reg_detail) / sizeof (reg_detail_t),
  pick_reg_detail,
  pick_event_fn
};


// PICK keyboard mapping
//
// cathode    cathode    keycode
// driver     driver     high
// pin        column     digit
// (1-22)     (1-14)     C[2]
// -------    -------    -------
//    21          1         1
//    22          2         2
//     1          3         5
//     2          4         a
//     3          5         4
//     4          6         9
//     5          7         3
//     6          8         6
//     7          9         d
//     8         10         b
//     9         11         7
//    11         12         e
//    12         13         c
//    13         14         8
//
//
//                   keycode
//          PICK     low
// PICK     return   digit
// pin      line     C[1]
// ------   ------   -------
//   24       KBA       4
//  none      KBB       ?
//   25       KBC       1
//   26       KBD       8
//   27       KBE       0


static void pick_press_key (sim_t *sim, int keycode)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  pick_reg_t *pick_reg = get_chip_data (act_reg->pick_chip);

  if (pick_reg->key_buffer.count < PICK_KEY_BUFFER_SIZE)
    {
      pick_reg->key_buffer.keycode [pick_reg->key_buffer.tail] = keycode;
      pick_reg->key_buffer.count++;
      pick_reg->key_buffer.tail++;
      if (pick_reg->key_buffer.tail >= PICK_KEY_BUFFER_SIZE)
	pick_reg->key_buffer.tail = 0;
#ifdef PICK_DEBUG
      fprintf (stdout, "PICK: key %02x pressed, count=%d\n", keycode, pick_reg->key_buffer.count);
#endif
    }
  else
    {
      fprintf (stdout, "PICK key buffer overflow, key %02x discarded\n", keycode);
    }
}

static void pick_release_key (sim_t *sim UNUSED, int keycode UNUSED)
{
  // nothing happens on release
}


static bool pick_read (sim_t *sim)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  pick_reg_t *pick_reg = get_chip_data (act_reg->pick_chip);

  int keycode = pick_reg->key_buffer.keycode [pick_reg->key_buffer.head];
#ifdef PICK_DEBUG
  fprintf (stdout, "PICK read, returning keycode 0x%02x, count was %d\n", keycode, pick_reg->key_buffer.count);
#endif
  if (pick_reg->key_buffer.count)
    {
      pick_reg->key_buffer.count--;
      pick_reg->key_buffer.head++;
      if (pick_reg->key_buffer.head >= PICK_KEY_BUFFER_SIZE)
	pick_reg->key_buffer.head = 0;
    }
  else
    {
      fprintf (stdout, "PICK key buffer underflow\n");
    }

  reg_zero (act_reg->c, 0, WSIZE - 1);
  act_reg->c [1] = (keycode >> 4) & 0xf;
  act_reg->c [0] = keycode & 0xf;

  return true;
}

static bool pick_write (sim_t *sim UNUSED)
{
  return false;
}

static void pick_pulse_act_f1 (sim_t *sim)
{
  chip_event (sim,
	      sim->first_chip,  // ACT only
	      event_pulse_flag,
	      EXT_FLAG_ACT_F1,
	      0,                // arg2 unused
	      NULL);
}

static void pick_op_check_keycode_available (sim_t *sim,
					    int opcode UNUSED)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  pick_reg_t *pick_reg = get_chip_data (act_reg->pick_chip);

#ifdef PICK_DEBUG
  fprintf (stdout, "PICK: key buffer check: count=%d\n", pick_reg->key_buffer.count);
#endif

  if (pick_reg->key_buffer.count > 0)
    pick_pulse_act_f1 (sim);
}

static void pick_op_home (sim_t *sim,
			  int opcode UNUSED)
{
  // act_reg_t *act_reg = get_chip_data (sim->first_chip);
  // pick_reg_t *pick_reg = get_chip_data (act_reg->pick_chip);

  // HOME?  currently assume it always is
  pick_pulse_act_f1 (sim);
}

static void pick_op_cr (sim_t *sim,
			  int opcode UNUSED)
{
  // act_reg_t *act_reg = get_chip_data (sim->first_chip);
  // pick_reg_t *pick_reg = get_chip_data (act_reg->pick_chip);

  // CR seen?  currently assume yes
  pick_pulse_act_f1 (sim);
}

static void pick_op_print_0123 (sim_t *sim UNUSED,
			  int opcode UNUSED)
{
  // PRINT 3
}

static void pick_op_print6 (sim_t *sim UNUSED,
			  int opcode UNUSED)
{
  // PRINT 6
}

static void pick_reset (sim_t *sim)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  pick_reg_t *pick_reg = get_chip_data (act_reg->pick_chip);

  pick_reg->key_buffer.count = 0;
  pick_reg->key_buffer.head = 0;
  pick_reg->key_buffer.tail = 0;
}


static void pick_event_fn (sim_t      *sim,
			   chip_t     *chip UNUSED,
			   event_id_t event,
			   int        arg1,
			   int        arg2,
			   void       *data UNUSED)
{
  //act_reg_t *act_reg = get_chip_data (sim->first_chip);
  //pick_reg_t *pick_reg = get_chip_data (act_reg->pick_chip);

  switch (event)
    {
    case event_reset:
    case event_wake:
    case event_restore_completed:
       pick_reset (sim);
       break;
    case event_cycle:
    case event_sleep:
      break;
    case event_key:
      if (arg2)
	pick_press_key (sim, arg1);
      else
	pick_release_key (sim, arg1);
      break;
    case event_flag_out_change:
      if (arg1)
	chip_event (sim,
		    sim->first_chip,  // ACT only
		    event_key,
		    0162,             // $$$ chosen randomly
		    true,             // press
		    NULL);

      else
	chip_event (sim,
		    sim->first_chip,  // ACT only
		    event_key,
		    0162,             // doesn't matter
		    false,            // release
		    NULL);

      break;
    default:
      // warning ("pick: unknown event %d\n", event);
      break;
    }
}

static void pick_init_ops (sim_t *sim)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);

  act_reg->op_fcn [01120] = pick_op_home;
  act_reg->op_fcn [01220] = pick_op_cr;
  act_reg->op_fcn [01320] = pick_op_check_keycode_available;
  act_reg->op_fcn [01420] = pick_op_print_0123;
  act_reg->op_fcn [01520] = pick_op_print_0123;
  act_reg->op_fcn [01620] = pick_op_print_0123;
  act_reg->op_fcn [01720] = pick_op_print_0123;
  act_reg->op_fcn [01660] = pick_op_print6;

  act_reg->ram_exists [RAMADDR_PICK] = true;
  act_reg->ram_rd_fcn [RAMADDR_PICK] = & pick_read;
  act_reg->ram_wr_fcn [RAMADDR_PICK] = & pick_write;
}


chip_t *pick_install (sim_t *sim,
		      int32_t index UNUSED,
		      int32_t flags UNUSED)
{
  act_reg_t *act_reg;
  pick_reg_t *pick_reg;

  if (sim->arch != ARCH_WOODSTOCK)
    {
      fprintf (stderr, "PICK only supports Woodstock architecture\n");
      return NULL;
    }

  act_reg = get_chip_data (sim->first_chip);
  pick_reg = alloc (sizeof (pick_reg_t));

  pick_reg->printer_char_gen = calcdef_get_char_gen (sim->calcdef,
						     "woodstock_pick");

  act_reg->pick_chip = install_chip (sim,
				     & pick_chip_detail,
				     pick_reg);

  pick_init_ops (sim);

  return act_reg->pick_chip;
}
