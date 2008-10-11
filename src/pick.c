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
#include "printer.h"


#define PRINTER_COLUMNS 20


typedef struct
{
  int count;
  int head;
  int tail;
  int keycode [PICK_KEY_BUFFER_SIZE];
} key_buffer_t;

typedef struct
{
  int left_ptr;  // buffer fills from right
  uint8_t buffer [PRINTER_COLUMNS];
  int cr_seen_timer;  // non-zero and counts down when CR not yet seen
  int home_timer;     // non-zero and counts down when not in HOME position
  const segment_bitmap_t *char_gen;
} pick_printer_t;

typedef struct
{
  key_buffer_t key_buffer;
  pick_printer_t printer;
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
#ifdef PICK_KEYBOARD_DEBUG
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
#ifdef PICK_KEYBOARD_DEBUG
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
      // On an error the microcode blindly reads the buffer a fixed
      // number of times, causing underflows, so we don't consider it
      // to be a problem.
    }

  reg_zero (act_reg->c, 0, WSIZE - 1);
  act_reg->c [2] = (keycode >> 4) & 0xf;
  act_reg->c [1] = keycode & 0xf;

  return true;
}

static bool pick_write (sim_t *sim UNUSED)
{
  return false;
}

static void pick_pulse_act_f2 (sim_t *sim)
{
  chip_event (sim,
	      sim->first_chip,  // ACT only
	      event_pulse_flag,
	      EXT_FLAG_ACT_F2,
	      0,                // arg2 unused
	      NULL);
}


static void pick_op_check_keycode_available (sim_t *sim,
					    int opcode UNUSED)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  pick_reg_t *pick_reg = get_chip_data (act_reg->pick_chip);

#ifdef PICK_KEYBOARD_DEBUG
  fprintf (stdout, "PICK: key buffer check: count=%d\n", pick_reg->key_buffer.count);
#endif

  if (pick_reg->key_buffer.count > 0)
    pick_pulse_act_f2 (sim);
}

static void pick_op_home (sim_t *sim,
			  int opcode UNUSED)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  pick_reg_t *pick_reg = get_chip_data (act_reg->pick_chip);
  pick_printer_t *printer = & pick_reg->printer;

  if (printer->home_timer == 0)
    pick_pulse_act_f2 (sim);
}

static void pick_op_cr (sim_t *sim,
			  int opcode UNUSED)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  pick_reg_t *pick_reg = get_chip_data (act_reg->pick_chip);
  pick_printer_t *printer = & pick_reg->printer;

  if (printer->cr_seen_timer == 0)
    pick_pulse_act_f2 (sim);
}


#ifdef PICK_PRINTER_DEBUG
char *printer_char_map [64] =
{
  "N",     "L",  "G",   "O",  "P",   "R", "S",    "T",
  "%",     "W",  "A",   "B",  "C",   "D", "E",    "I",
  "Y",     "M",  "^-1", "H",  "sqrt","F", "?",    "->",
  "^2",    "^x", "a",   "b",  "c",   "d", "e",    "i",
  "=",     "!=", ">",   "<=", "X",   "Z", "xbar", "<->",
  "Sigma", "<",  "!",   "/",  "div", "^", "v",    "x",
  "0",     "1",  "2",   "3",  "4",   "5", "6",    "7",
  "8",     "9",  ".",   "-",  "+",   "*", " ",    "<cr>"
};
#endif


static void pick_line_add_char (printer_line_data_t *line,
				int *col_idx,
				segment_bitmap_t bitmap)
{
  int i;

  for (i = 0; i < 5; i++)
    {
      line->columns [--(*col_idx)] = (((bitmap << 6)  & 0x40) +
				      ((bitmap)       & 0x20) +
				      ((bitmap >> 6)  & 0x10) +
				      ((bitmap >> 12) & 0x08) +
				      ((bitmap >> 18) & 0x04) +
				      ((bitmap >> 24) & 0x02) +
				      ((bitmap >> 30) & 0x01));
      bitmap >>= 1;
    }
  (*col_idx) -= 2;
}


static void pick_printer_print_line (sim_t *sim)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  pick_reg_t *pick_reg = get_chip_data (act_reg->pick_chip);
  pick_printer_t *printer = & pick_reg->printer;

  printer_line_data_t *line;  // graphic line buffer
  int col_idx;
  int i;

  // init graphic output buffer
  col_idx = PRINTER_COLUMNS * 7;
  line = alloc (sizeof (printer_line_data_t) + col_idx * sizeof (uint8_t));
  line->col_count = col_idx;

  for (i = PRINTER_COLUMNS - 1; i >= printer->left_ptr; i--)
    {
      pick_line_add_char (line,
			  & col_idx,
			  printer->char_gen [printer->buffer [i]]);
    }

  sim_send_chip_msg_to_gui (sim, act_reg->pick_chip, line);

  pick_reg->printer.left_ptr = PRINTER_COLUMNS;
}


static void pick_cycle (sim_t *sim)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  pick_reg_t *pick_reg = get_chip_data (act_reg->pick_chip);
  pick_printer_t *printer = & pick_reg->printer;

  if (printer->cr_seen_timer != 0)
    printer->cr_seen_timer--;
  if (printer->home_timer != 0)
    {
      printer->home_timer--;
      if (printer->home_timer == 0)
	pick_printer_print_line (sim);
    }
}


#define PICK_DELAY_CR_SEEN 50
#define PICK_DELAY_HOME    100

static void pick_print_char (sim_t *sim, uint8_t ch)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  pick_reg_t *pick_reg = get_chip_data (act_reg->pick_chip);
  pick_printer_t *printer = & pick_reg->printer;

  if (printer->left_ptr == 0)
    {
      warning ("PICK printer buffer overflow\n");
      return;
    }

  printer->buffer [--printer->left_ptr] = ch;
  printer->cr_seen_timer += PICK_DELAY_CR_SEEN;
  printer->home_timer = printer->home_timer + PICK_DELAY_HOME;
}


static void pick_op_print_0123 (sim_t *sim,
				int opcode)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  pick_reg_t *pick_reg = get_chip_data (act_reg->pick_chip);
  pick_printer_t *printer = & pick_reg->printer;

  int top_bits = (opcode >> 6) & 3;
  uint64_t all_bits;

  if (printer->cr_seen_timer != 0)
    printf ("PICK: printing chars while CR not seen?\n");

#ifdef PICK_PRINTER_DEBUG
  printf ("PICK print %d: ", top_bits);
#endif
  for (all_bits = reg_to_binary (act_reg->c, WSIZE);
       (all_bits & 0xf) != 0xf;
       all_bits >>= 4)
    {
      uint8_t ch = (top_bits << 4) | (all_bits & 0xf);
      pick_print_char (sim, ch);
#ifdef PICK_PRINTER_DEBUG
      printf ("%s", printer_char_map [ch]);
#endif
    }
#ifdef PICK_PRINTER_DEBUG
  printf ("\n");
#endif
}

static void pick_op_print6 (sim_t *sim,
			    int opcode UNUSED)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  pick_reg_t *pick_reg = get_chip_data (act_reg->pick_chip);
  pick_printer_t *printer = & pick_reg->printer;

  uint64_t all_bits;

  if (printer->cr_seen_timer != 0)
    printf ("PICK: printing chars while CR not seen?\n");

#ifdef PICK_PRINTER_DEBUG
  printf ("PICK print 6: ");
#endif
  for (all_bits = reg_to_binary (act_reg->c, WSIZE);
       (all_bits & 0x3f) != 0x3f;
       all_bits >>= 6)
    {
      uint8_t ch = ((all_bits & 0x03) << 4) | ((all_bits >> 2) & 0x0f);
      pick_print_char (sim, ch);
#ifdef PICK_PRINTER_DEBUG
      printf ("%s", printer_char_map [ch]);
#endif
    }
#ifdef PICK_PRINTER_DEBUG
  printf ("\n");
#endif
}


static void pick_paper_advance_button (sim_t *sim, int state)
{
  chip_event (sim,
	      sim->first_chip,  // ACT only
	      event_set_flag,
	      EXT_FLAG_ACT_F1,
	      ! state,
	      NULL);
}


static void pick_keyboard_reset (sim_t *sim)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  pick_reg_t *pick_reg = get_chip_data (act_reg->pick_chip);

  pick_reg->key_buffer.count = 0;
  pick_reg->key_buffer.head = 0;
  pick_reg->key_buffer.tail = 0;
}


static void pick_printer_reset (sim_t *sim)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  pick_reg_t *pick_reg = get_chip_data (act_reg->pick_chip);
  pick_printer_t *printer = & pick_reg->printer;

  printer->cr_seen_timer = 0;
  printer->home_timer = 0;
  printer->left_ptr = PRINTER_COLUMNS;
}


static void pick_reset (sim_t *sim)
{
  pick_keyboard_reset (sim);
  pick_printer_reset (sim);
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
      pick_cycle (sim);
      break;
    case event_sleep:
      break;
    case event_key:
      if (arg2)
	pick_press_key (sim, arg1);
      else
	pick_release_key (sim, arg1);
      break;
    case event_printer_paper_advance_button:
      pick_paper_advance_button (sim, arg1);
      break;
    case event_flag_out_change:
      // ??? in 91
      // ??? in 92
      // ??? in 95C
      // not used in 97
      // ??? in 19C
#if 0
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
#endif
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


chip_t *pick_install (sim_t       *sim,
		      chip_type_t type  UNUSED,
		      int32_t     index UNUSED,
		      int32_t     flags UNUSED)
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

  pick_reg->printer.char_gen = calcdef_get_char_gen (sim->calcdef, "pick");

  act_reg->pick_chip = install_chip (sim,
				     & pick_chip_detail,
				     pick_reg);

  pick_init_ops (sim);

  pick_paper_advance_button (sim, false);  // paper advance not pressed!

  return act_reg->pick_chip;
}
