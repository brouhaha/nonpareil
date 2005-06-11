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


#define HELIOS_BUF_MAX 43


typedef struct
{
  uint8_t  flags;   // NPIC flags, NF_xxx defines above
  uint16_t status;  // status bits for Nut, HS_xxx defines above
  uint8_t  count;   // count of bytes in buffer
  uint8_t buffer [HELIOS_BUF_MAX];
  uint16_t sstatus; // print mode status bits in effect at start of buffer
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
  PR   ("count",   count,    8,   16,   NULL, NULL, 0),
  PRA  ("buffer",  buffer,   8,   16,   NULL, NULL, 0,   HELIOS_BUF_MAX),
  PR   ("sstatus", sstatus, 16,   2,    NULL, NULL, 0)
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


// Warning - doesn't test for bit number out of range!
static bool helios_get_sstatus_bit (helios_reg_t *helios, int bit)
{
#if 0
#ifdef HELIOS_DEBUG
  printf ("Getting Helios sstatus %s (%d): %d\n", hs_bit_name [bit], bit,
	  (helios->sstatus >> bit) & 1);
#endif
#endif
  return (helios->sstatus >> bit) & 1;
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


static void print_mode_delta (int old_mode, int mode)
{
  if ((old_mode & 4) != (mode & 4))
    {
      if (mode & 4)
	printf (" (double wide)");
      else
	printf (" (single wide)");
    }
  if ((old_mode & 2) != (mode & 2))
    {
      if (mode & 2)
	printf (" (graphics)");
      else
	printf (" (text)");
    }
  if ((old_mode & 1) != (mode & 1))
    {
      if (mode & 1)
	printf (" (lc)");
      else
	printf (" (uc)");
    }
}


static void helios_eol (sim_t *sim, bool right_justify)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  helios_reg_t *helios = get_chip_data (nut_reg->helios_chip);
  int old_mode = 0;
  int mode;
  int i;
  uint8_t byte;

  printf ("Helios buffer: ");
  mode = ((helios_get_sstatus_bit (helios, HS_DOUBLE_WIDE) << 2) +
	  (helios_get_sstatus_bit (helios, HS_GRAPHICS) << 1) +
	  helios_get_status_bit (helios, HS_LOWER_CASE));
  print_mode_delta (old_mode, mode);
  for (i = 0; i < helios->count; i++)
    {
      byte = helios->buffer [i];
      if (byte < 0x80)
	printf (" %02x", byte);
      else if ((byte >= 0xa0) && (byte <= 0xb7))
	printf (" (skip %d char)", byte - 0xa0);
      else if ((byte >= 0xb8) && (byte <= 0xbf))
	printf (" (skip %d col)", byte - 0xb8);
      else
	{
	  old_mode = mode;
	  mode = byte & 7;
	  print_mode_delta (old_mode, mode);
	  if (byte >= 0xe0)
	    printf (" (EOL %cj)", ((byte >> 3) & 1) ? 'r' : 'l');
	}
    }
  printf ("\n");
  helios->count = 0;
  helios_set_status_bit (helios, HS_BUF_EMPTY, true);
}


static void helios_set_mode (helios_reg_t *helios, uint8_t mode)
{
  helios_set_status_bit (helios, HS_DOUBLE_WIDE, mode & 1);
  helios_set_status_bit (helios, HS_GRAPHICS,    (mode >> 1) & 1);
  helios_set_status_bit (helios, HS_LOWER_CASE,  (mode >> 2) & 1);
}


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

  eol = (byte >= 0xe0) && (byte <= 0xef);
  right_just = (byte >> 3) & 1;
  
  helios_set_status_bit (helios, HS_LAST_BYTE_EOL, eol);

  if (byte < 0xf0)
    {
      if (! helios->count)
	{
	  helios->sstatus = helios->status;
	  helios_set_status_bit (helios, HS_BUF_EMPTY, false);
	}
      helios->buffer [helios->count++] = byte;

      if ((byte >= 0xd0) && (byte <= 0xef))
	helios_set_mode (helios, byte & 7);

      if (helios->count == HELIOS_BUF_MAX)
	{
	  eol = true;
	  right_just = helios_get_status_bit (helios, HS_RIGHT_JUST);
	}

      if (eol)
	helios_eol (sim, right_just);
    }
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
