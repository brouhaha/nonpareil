/*
$Id$
Copyright 1995, 2005 Eric L. Smith <eric@brouhaha.com>

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
#include <string.h>

#include "arch.h"
#include "util.h"
#include "display.h"
#include "proc.h"
#include "digit_ops.h"
#include "proc_int.h"
#include "proc_nut.h"
#include "helios.h"


// NPIC flags:
#define NF_DD3     2  // peripheral powered on
#define NF_RFF     1  // data available to be read
#define NF_BUSY    0  // data has been written to peripheral

#define NF_COUNT   3


// Bits in Helios status register:
#define HS_MODE_TRACE    15  // if HS_MODE_TRACE and HS_MODE_NORM are both
#define HS_MODE_NORM     14  //     zero, the switch is set to MAN
#define HS_PRT_KEY       13  // PRinT KEY is pressed
#define HS_ADV_KEY       12  // paper ADVance KEY is pressed
#define HS_PAPER_OUT     11  // paper out
#define HS_LOW_BAT       10  // low battery
#define HS_IDLE           9  // not printing or advancing paper
#define HS_BUF_EMPTY      8  // Buffer Empty
#define HS_LOWER_CASE     7  // Lower Case mode
#define HS_GRAPHICS       6  // Graphics mode (bit-mapped columns)
#define HS_DOUBLE_WIDE    5  // Double Wide mode
#define HS_RIGHT_JUST     4  // Type of End of Line is Right Justify
#define HS_LAST_BYTE_EOL  3  // Last byte was End Of Line
#define HS_IGNORE_ADV     2  // IGNore paper advance key
#define HS_UNUSED_1       1  // unused
#define HS_UNUSED_0       0  // unused


#define HS_COUNT         16
// 16 flag bits, but only 14 used
// Note that NPIC actually supports 56 bits of data, but Helios printer
// only supplies most significant 14 bits.  So the Helios flags are really
// bits 55 through 42.  It's convenient for us to treat them as four digits
// with small indexes.


#undef HELIOS_DEBUG

#ifdef HELIOS_DEBUG
static char *nf_bit_name [NF_COUNT] =
{
  [NF_DD3]  = "DD3",
  [NF_RFF]  = "RFF",
  [NF_BUSY] = "BUSY"
};

static char *hs_bit_name [HS_COUNT] =
{
  [HS_MODE_TRACE]    = "MODE_TRACE",
  [HS_MODE_NORM]     = "MODE_NORM",
  [HS_PRT_KEY]       = "PRT_KEY",
  [HS_ADV_KEY]       = "ADV_KEY",
  [HS_PAPER_OUT]     = "PAPER_OUT",
  [HS_LOW_BAT]       = "LOW_BAT",
  [HS_IDLE]          = "IDLE",
  [HS_BUF_EMPTY]     = "BUF_EMPTY",
  [HS_LOWER_CASE]    = "LOWER_CASE",
  [HS_GRAPHICS]      = "GRAPHICS",
  [HS_DOUBLE_WIDE]   = "DOUBLE_WIDE",
  [HS_RIGHT_JUST]    = "RIGHT_JUST",
  [HS_LAST_BYTE_EOL] = "LAST_BYTE_EOL",
  [HS_IGNORE_ADV]    = "IGNORE_ADV",
  [HS_UNUSED_1]      = "UNUSED_1",
  [HS_UNUSED_0]      = "UNUSED_0"
};
#endif


// Bit weights in Helios print mode:
#define HM_LOWER_CASE  1
#define HM_GRAPHICS    2
#define HM_DOUBLE_WIDE 4


#define HELIOS_BUF_MAX 43


typedef struct
{
  uint8_t  flags;   // NPIC flags, NF_xxx defines above
  uint16_t status;  // status bits for Nut, HS_xxx defines above

  uint8_t  mode;     // print mode in effect at start of buffer
  uint8_t  count;   // count of bytes in buffer
  uint8_t  buffer [HELIOS_BUF_MAX];

} helios_reg_t;


#define PR(name, field, bits, radix, get, set, arg)        \
    {{ name, bits, 1, radix },                             \
     OFFSET_OF (helios_reg_t, field),                      \
     SIZE_OF (helios_reg_t, field),                        \
     get, set, arg } 


#define PRA(name, field, bits, radix, get, set, arg, array) \
    {{ name, bits, array, radix },                          \
     OFFSET_OF (helios_reg_t, field[0]),                    \
     SIZE_OF (helios_reg_t, field[0]),                      \
     get, set, arg } 


static const reg_detail_t helios_reg_detail [] =
{
  //    name       field    bits radix  get   set   arg  array
  PR   ("flags",   flags,    3,   2,    NULL, NULL, 0),
  PR   ("status",  status,  16,   2,    NULL, NULL, 0),
  PR   ("mode",    mode,     3,   16,   NULL, NULL, 0),
  PR   ("count",   count,    8,   16,   NULL, NULL, 0),
  PRA  ("buffer",  buffer,   8,   16,   NULL, NULL, 0,   HELIOS_BUF_MAX),
};


static chip_event_fn_t helios_event_fn;


static const chip_detail_t helios_chip_detail =
{
  {
    "Helios printer",
    CHIP_HELIOS,
    false  // There can only be one Helios on the bus.
  },
  sizeof (helios_reg_detail) / sizeof (reg_detail_t),
  helios_reg_detail,
  helios_event_fn
};


// Warning - doesn't test for bit number out of range!
static bool helios_get_npic_flag_bit (helios_reg_t *helios, int bit)
{
#ifdef HELIOS_DEBUG
  printf ("Getting Helios NPIC flag %s (%d): %d\n", nf_bit_name [bit], bit,
	  (helios->flags >> bit) & 1);
#endif
  return (helios->flags >> bit) & 1;
}


// Warning - doesn't test for bit number out of range!
static void helios_set_npic_flag_bit (helios_reg_t *helios, int bit, bool val)
{
#ifdef HELIOS_DEBUG
  printf ("setting Helios NPIC flag %s (%d) to %d\n", nf_bit_name [bit], bit, val);
#endif

  if (val)
    helios->flags |= (1 << bit);
  else
    helios->flags &= ~(1 << bit);
}


// Warning - doesn't test for bit number out of range!
static bool helios_get_status_bit (helios_reg_t *helios, int bit)
{
#if 0
#ifdef HELIOS_DEBUG
  printf ("Getting Helios status %s (%d): %d\n", hs_bit_name [bit], bit,
	  (helios->status >> bit) & 1);
#endif
#endif
  return (helios->status >> bit) & 1;
}


// Warning - doesn't test for bit number out of range!
static void helios_set_status_bit (helios_reg_t *helios, int bit, bool val)
{
#ifdef HELIOS_DEBUG
  printf ("setting Helios status %s (%d) to %d\n", hs_bit_name [bit], bit, val);
#endif

  if (val)
    helios->status |= (1 << bit);
  else
    helios->status &= ~(1 << bit);
}


static void helios_update_ext_flags (nut_reg_t *nut_reg,
				     helios_reg_t *helios)
{
#if 0
  // I have a hard time believing that the  NPIC can set an external
  // flag, since the chip isn't even wired to the flag line!
  nut_reg->ext_flag = helios_get_npic_flag_bit (helios, NF_BUSY);
#endif

  if (helios_get_status_bit (helios, HS_PRT_KEY) ||
      helios_get_status_bit (helios, HS_ADV_KEY))
    nut_reg->awake = true;  // wake up CPU if asleep
}


static void helios_reset (helios_reg_t *helios)
{
  int i;

  for (i = 0; i < NF_COUNT; i++)
    helios_set_npic_flag_bit (helios, i, false);

  for (i = 0; i < HS_COUNT; i++)
    helios_set_status_bit (helios, i, false);

  helios->count = 0;  // empty buffer

  helios_set_npic_flag_bit (helios, NF_DD3, true);  // powered on
  helios_set_npic_flag_bit (helios, NF_RFF, true);  // status valid

  //helios_set_status_bit (helios, HS_MODE_TRACE, true);  // trace mode
  //helios_set_status_bit (helios, HS_MODE_NORM, true);  // normal mode

  helios_set_status_bit (helios, HS_IDLE,      true);  // not printing
  helios_set_status_bit (helios, HS_BUF_EMPTY, true);  // nothing in buffer
}


static void helios_event_fn (sim_t  *sim,
			     chip_t *chip UNUSED,
			     int    event,
			     int    arg,
			     void   *data UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  helios_reg_t *helios = get_chip_data (nut_reg->helios_chip);

  switch (event)
    {
    case event_reset:
      helios_reset (helios);
      break;
    case event_printer_set_mode:
      switch (arg)
	{
	case PRINTER_MODE_MAN:
	  helios_set_status_bit (helios, HS_MODE_TRACE, false);
	  helios_set_status_bit (helios, HS_MODE_NORM,  false);
	  break;
	case PRINTER_MODE_TRACE:
	  helios_set_status_bit (helios, HS_MODE_TRACE, true);
	  helios_set_status_bit (helios, HS_MODE_NORM,  false);
	  break;
	case PRINTER_MODE_NORM:
	  helios_set_status_bit (helios, HS_MODE_TRACE, false);
	  helios_set_status_bit (helios, HS_MODE_NORM,  true);
	  break;
	default:
	  warning ("helios: invalid mode %d\n", arg);
	}
      break;
    case event_printer_print_button:
      helios_set_status_bit (helios, HS_PRT_KEY, arg != 0);
      helios_update_ext_flags (nut_reg, helios);
      break;
    case event_printer_paper_advance_button:
      helios_set_status_bit (helios, HS_ADV_KEY, arg != 0);
      helios_update_ext_flags (nut_reg, helios);
      break;
    default:
      // warning ("helios: unknown event %d\n", event);
      break;
    }
}


static bool helios_add_column (printer_line_data_t *line,
			       int *col_idx,
			       uint8_t col)
{
  if (((*col_idx) + 1) > PRINTER_WIDTH)
    return false;

  line->columns [(*col_idx)++] = col;

  return true;
}


static bool helios_add_char (printer_line_data_t *line,
			     int *col_idx,
			     uint8_t c,
			     uint8_t mode)
{
  int col;

  if (((* col_idx) + ((mode & HM_DOUBLE_WIDE) ? 14 : 7)) >
      PRINTER_WIDTH)
    return false;

  if ((mode & HM_LOWER_CASE) &&
      ((c >= 'A') && (c <= 'Z')))
    c += 0x20;

  line->columns [(* col_idx)++] = 0;
  if (mode & HM_DOUBLE_WIDE)
    line->columns [(* col_idx)++] = 0;

  for (col = 0; col < 5; col++)
    {
      uint8_t col_data = helios_chargen [c] [col];
      line->columns [(* col_idx)++] = col_data;
      if (mode & HM_DOUBLE_WIDE)
	line->columns [(* col_idx)++] = col_data;
    }

  line->columns [(* col_idx)++] = 0;
  if (mode & HM_DOUBLE_WIDE)
    line->columns [(* col_idx)++] = 0;

  return true;
}


static void helios_eol (sim_t *sim, bool right_justify)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  helios_reg_t *helios = get_chip_data (nut_reg->helios_chip);
  int old_mode, mode;
  int buf_idx;  // index into printer buffer
  int col_idx;  // index into graphic line buffer
  printer_line_data_t *line;  // graphic line buffer

  // init graphic output buffer
  line = alloc (sizeof (printer_line_data_t));
  col_idx = 0;

  // get saved mode from start of buffer
  old_mode = 0;
  mode = helios->mode;

  buf_idx = 0;
  while (buf_idx < helios->count)
    {
      uint8_t byte = helios->buffer [buf_idx];

      if (byte < 0x80)
	{
	  if (mode & HM_GRAPHICS)
	    {
	      if (! helios_add_column (line, & col_idx, byte))
		break;  // not room for another column
	      buf_idx++;
	    }
	  else
	    {
	      if (! helios_add_char (line, & col_idx, byte, mode))
		break;
	      buf_idx++;
	    }
	}
      else if ((byte == 0xa0) || (byte == 0xb8))
	{
	  // skip zero chars or columns - just eat the byte
	  buf_idx++;
	}
      else if ((byte > 0xa0) && (byte <= 0xb7))
	{
	  if (! helios_add_char (line, & col_idx, ' ', mode))
	    break;
	  helios->buffer [buf_idx]--;
	}
      else if ((byte > 0xb8) && (byte <= 0xbf))
	{
	  if (! helios_add_column (line, & col_idx, 0x00))
	    break;
	  helios->buffer [buf_idx]--;
	}
      else
	{
	  // mode change
	  old_mode = mode;
	  mode = byte & 7;
	  buf_idx++;
	}
    }

  if (right_justify && (col_idx < PRINTER_WIDTH))
    {
      // shift output data to right justify
      memmove (line->columns + (PRINTER_WIDTH - col_idx),
	       line->columns,
	       col_idx);
      memset (line->columns, 0, PRINTER_WIDTH - col_idx);
    }

  sim_send_chip_msg_to_gui (sim, nut_reg->helios_chip, line);

  if (buf_idx != helios->count)
    {
      // shift remaining contents of buffer to beginning
      memmove (helios->buffer,
	       helios->buffer + buf_idx,
	       helios->count - buf_idx);
    }

  helios->count -= buf_idx;
  if (! helios->count)
    helios_set_status_bit (helios, HS_BUF_EMPTY, true);
}


static void helios_set_mode (helios_reg_t *helios, uint8_t mode)
{
  helios_set_status_bit (helios, HS_DOUBLE_WIDE, (mode & HM_DOUBLE_WIDE) != 0);
  helios_set_status_bit (helios, HS_GRAPHICS,    (mode & HM_GRAPHICS) != 0);
  helios_set_status_bit (helios, HS_LOWER_CASE,  (mode & HM_LOWER_CASE) != 0);
}


static uint8_t helios_get_mode (helios_reg_t *helios)
{
  uint8_t mode = 0;

  if (helios_get_status_bit (helios, HS_DOUBLE_WIDE))
    mode += HM_DOUBLE_WIDE;
  if (helios_get_status_bit (helios, HS_GRAPHICS))
    mode += HM_GRAPHICS;
  if (helios_get_status_bit (helios, HS_LOWER_CASE))
    mode += HM_LOWER_CASE;

  return mode;
}


#undef HELIOS_EOL_HAS_MODE_BITS

#ifdef HELIOS_EOL_HAS_MODE_BITS
#define HIGHEST_VAL_TO_BUFFER 0xef
#else
#define HIGHEST_VAL_TO_BUFFER 0xdf
#endif

static void helios_npic_write (sim_t *sim)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  helios_reg_t *helios = get_chip_data (nut_reg->helios_chip);
  uint8_t byte;
  bool eol;
  bool right_just;

  byte = (nut_reg->c [1] << 4) + nut_reg->c [0];

#ifdef HELIOS_DEBUG
  printf ("helios output byte %02x\n", byte);
#endif

#ifdef HELIOS_EOL_HAS_MODE_BITS
  eol = (byte >= 0xe0) && (byte <= 0xef);
#else
  eol = (byte == 0xe0) || (byte == 0xe8);
#endif

  right_just = (byte >> 3) & 1;
  
  helios_set_status_bit (helios, HS_LAST_BYTE_EOL, eol);

  if (byte <= HIGHEST_VAL_TO_BUFFER)
    {
      if (! helios->count)
	{
	  helios->mode = helios_get_mode (helios);
	  helios_set_status_bit (helios, HS_BUF_EMPTY, false);
	}
      helios->buffer [helios->count++] = byte;

      if (byte >= 0xd0)
	helios_set_mode (helios, byte & 7);

      if (helios->count == HELIOS_BUF_MAX)
	{
	  eol = true;
	  right_just = helios_get_status_bit (helios, HS_RIGHT_JUST);
	}

      if (eol)
	helios_eol (sim, right_just);
    }
  else if (eol)
    helios_eol (sim, right_just);
  else if (byte >= 0xfe)
    helios_set_status_bit (helios, HS_IGNORE_ADV, byte & 1);
  else if (byte >= 0xfc)
    printf ("Helios: ROM self-test command %02x\n", byte);
  else
    printf ("Helios: unknown command %02x\n", byte);
}


static void helios_npic_read (sim_t *sim)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  helios_reg_t *helios = get_chip_data (nut_reg->helios_chip);
  int i;

#if 0
#ifdef HELIOS_DEBUG
  printf ("Getting Helios status: %04x\n", helios->status);
#endif
#endif

  reg_zero (nut_reg->c, 0, WSIZE);

  for (i = 3; i >= 0; i--)
    nut_reg->c [i + 10] = ((helios_get_status_bit (helios, i * 4 + 3) << 3) +
			   (helios_get_status_bit (helios, i * 4 + 2) << 2) +
			   (helios_get_status_bit (helios, i * 4 + 1) << 1) +
			   (helios_get_status_bit (helios, i * 4    )     ));
}


static bool helios_pertct_op (sim_t *sim, rom_word_t opcode)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  helios_reg_t *helios = get_chip_data (nut_reg->helios_chip);

  if ((opcode & 0x03f) == 0x003)
    {
      int flag_bit = opcode >> 6;
      if (flag_bit < NF_COUNT)
	{
	  return helios_get_npic_flag_bit (helios, flag_bit);
	}
      else
	{
	  printf ("Helios testing unknown flag %d\n", flag_bit);
	}
    }

  if (opcode == 0x007)
    helios_npic_write (sim);
  else if (opcode == 0x03a)
    helios_npic_read (sim);
  else if (opcode == 0x005)
    ;  // just a return 
  else
    fatal (2, "Helios unrecognized instruction %04x at addr %04x\n",
	   opcode, nut_reg->prev_pc);

  return false;
}


static void helios_init_ops (sim_t *sim)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  nut_reg->selprf_fcn [HELIOS_NPIC_PERTCT_ADDR] = helios_pertct_op;
}


chip_t *helios_init (sim_t *sim)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  helios_reg_t *helios;

  helios = alloc (sizeof (helios_reg_t));

  nut_reg->helios_chip = install_chip (sim,
				       & helios_chip_detail,
				       helios);

  helios_init_ops (sim);
  helios_reset (helios);

  return (nut_reg->helios_chip);
}
