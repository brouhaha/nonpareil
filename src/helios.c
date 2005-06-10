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


#define HELIOS_BUF_MAX 77


typedef struct
{
  uint8_t  flags;   // NPIC flags, NF_xxx defines above
  uint16_t status;  // status bits for Nut, HS_xxx defines above
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
  //    name      field   bits radix  get   set   arg  array
  PR   ("flags",  flags,   3,   2,    NULL, NULL, 0),
  PR   ("status", status, 16,   2,    NULL, NULL, 0),
  PR   ("count",  count,   8,   16,   NULL, NULL, 0),
  PRA  ("buffer", buffer,  8,   16,   NULL, NULL, 0,   HELIOS_BUF_MAX)
};


static chip_event_fn_t helios_event_fn;


static const chip_detail_t helios_chip_detail =
{
  {
    "Helios printer",
    false  // There can only be one Helios on the bus.
  },
  sizeof (helios_reg_detail) / sizeof (reg_detail_t),
  helios_reg_detail,
  helios_event_fn
};


// Warning - doesn't test for bit number out of range!
static bool helios_get_npic_flag_bit (helios_reg_t *helios, int bit)
{
  return (helios->flags >> bit) != 0;
}


// Warning - doesn't test for bit number out of range!
static void helios_set_npic_flag_bit (helios_reg_t *helios, int bit, bool val)
{
#ifdef HELIOS_DEBUG
  printf ("setting NPIC flag %s (%d) to %d\n", nf_bit_name [bit], bit, val);
#endif

  if (val)
    helios->flags |= (1 << bit);
  else
    helios->flags &= ~(1 << bit);
}


// Warning - doesn't test for bit number out of range!
static bool helios_get_status_bit (helios_reg_t *helios, int bit)
{
  return (helios->status >> bit) != 0;
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

  helios_set_status_bit (helios, HS_IDLE,      true);  // not printing
  helios_set_status_bit (helios, HS_BUF_EMPTY, true);  // nothing in buffer
}


static void helios_event_fn (sim_t *sim,
			      chip_t *chip,
			      int event)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  helios_reg_t *helios = get_chip_data (nut_reg->helios_chip);

  switch (event)
    {
    case event_reset:
      helios_reset (helios);
      break;
    default:
      // warning ("helios: unknown event %d\n", event);
      break;
    }
}


static void helios_npic_write (sim_t *sim)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  helios_reg_t *helios = get_chip_data (nut_reg->helios_chip);
  uint8_t byte;

  byte = (nut_reg->c [1] << 4) + nut_reg->c [0];
  printf ("helios output byte %02x\n", byte);

  if (helios->count < HELIOS_BUF_MAX)
    {
      helios->buffer [helios->count++] = byte;
    }
}


static void helios_npic_read (sim_t *sim)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  helios_reg_t *helios = get_chip_data (nut_reg->helios_chip);
  int i;

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
	return helios_get_npic_flag_bit (helios, flag_bit);
    }

  if (opcode == 0x007)
    helios_npic_write (sim);
  else if (opcode == 0x03a)
    helios_npic_read (sim);
  else
    fatal (2, "Helios unrecognized instruction\n");

  return false;
}


static void helios_init_ops (sim_t *sim)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);

  nut_reg->selprf_fcn [HELIOS_NPIC_PERTCT_ADDR] = helios_pertct_op;
}


void helios_init (sim_t *sim)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  helios_reg_t *helios;

  helios = alloc (sizeof (helios_reg_t));

  nut_reg->helios_chip = install_chip (sim,
				       & helios_chip_detail,
				       helios);

  helios_init_ops (sim);
}
