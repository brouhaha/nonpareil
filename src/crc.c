/*
$Id$
Copyright 2008 Eric Smith <eric@brouhaha.com>

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
#include "crc.h"


#undef DEBUG_CRC


#define MAX_CRC_FLAG 12

#define CRC_FLAG_BUFFER_READY            0
#define CRC_FLAG_SWITCH_PROGRAM_MODE     1
#define CRC_FLAG_SWITCH_PRINTER_MAN      2 // 97, different use in 67?
#define CRC_FLAG_SWITCH_PRINTER_NORM     3 // 97, unused in 67
#define CRC_FLAG_DEFAULT_FUNCTION_ENABLE 4
#define CRC_FLAG_MERGE                   5
#define CRC_FLAG_PAUSE                   6
// flag 8 function unknown
// flag 9 function unknown
#define CRC_FLAG_MOTOR_ENABLE            9
#define CRC_FLAG_CARD_INSERTED          10
#define CRC_FLAG_WRITE_MODE             11

typedef struct
{
  bool flag        [MAX_CRC_FLAG];

  bool ext_flag    [MAX_CRC_FLAG];
  // Some flags can be overridden by hardware, e.g., by a slide switch
  // wired to a flag input.

  crc_card_side_t *card_side;  // card side image - storage owned by caller
  int head_position;  // head position on card, from 0 to CRC_MAX_WORD + 2
                      // (CRC_MAX_WORD + 2 means card is done)
} crc_reg_t;


static reg_detail_t crc_reg_detail [] =
{
};


static chip_event_fn_t crc_event_fn;


static chip_detail_t crc_chip_detail =
{
  {
    "CRC",
    CHIP_WOODSTOCK_CRC,
    false
  },
  sizeof (crc_reg_detail) / sizeof (reg_detail_t),
  crc_reg_detail,
  crc_event_fn
};


static void crc_update_flags (sim_t *sim)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  crc_reg_t *crc_reg = get_chip_data (act_reg->crc_chip);

  crc_reg->flag [CRC_FLAG_BUFFER_READY] = 
    (crc_reg->card_side &&
     crc_reg->flag [CRC_FLAG_MOTOR_ENABLE] &&
     (crc_reg->head_position < CRC_MAX_WORD));

  if (crc_reg->card_side &&
      crc_reg->head_position >= CRC_MAX_WORD)
    {
      // $$$ notify GUI of completion
      crc_reg->card_side = NULL;
      crc_reg->head_position = 0;
    }
}


static void crc_insert_card (sim_t *sim,
			     crc_card_side_t *card_side)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  crc_reg_t *crc_reg = get_chip_data (act_reg->crc_chip);

  if (crc_reg->card_side)
    fatal (3, "crc: card already inserted\n");

  if (crc_reg->flag [CRC_FLAG_MOTOR_ENABLE])
    fatal (3, "crc: card inserted while motor running\n");

  crc_reg->card_side = card_side;
  crc_reg->head_position = 0;
  crc_reg->flag [CRC_FLAG_CARD_INSERTED] = true;

  crc_update_flags (sim);
}


static bool crc_read (sim_t *sim)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  crc_reg_t *crc_reg = get_chip_data (act_reg->crc_chip);
  int i;
  uint32_t w;

  if (! crc_reg->card_side)
    fatal (3, "crc: read with no card\n");

  if (! crc_reg->flag [CRC_FLAG_MOTOR_ENABLE])
    fatal (3, "crc: read with motor off\n");

  if (crc_reg->head_position >= CRC_MAX_WORD)
    fatal (3, "crc: read past end of card\n");

  reg_zero (act_reg->c, 0, WSIZE - 1);

  w = crc_reg->card_side->word [crc_reg->head_position++];
  for (i = 0; i < 7; i++)
    {
      int d = w & 0xf;
      w >>= 4;
      act_reg->c [7 + i] = d;
      act_reg->c [0 + i] = d;
    }

  crc_update_flags (sim);

  return true;
}

static bool crc_write (sim_t *sim)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  crc_reg_t *crc_reg = get_chip_data (act_reg->crc_chip);
  int i;
  uint32_t w = 0;

  if (! crc_reg->card_side)
    fatal (3, "crc: write with no card\n");

  if (crc_reg->card_side->write_protect)
    fatal (3, "crc: write to write-protected card\n");

  if (! crc_reg->flag [CRC_FLAG_MOTOR_ENABLE])
    fatal (3, "crc: write with motor off\n");

  if (crc_reg->head_position >= CRC_MAX_WORD)
    fatal (3, "crc: write past end of card\n");

  for (i = 6; i > 0; i--)
    {
      w <<= 4;
      w |= act_reg->c [7 + i];
    }
  crc_reg->card_side->word [crc_reg->head_position++] = w;

  crc_update_flags (sim);

  return true;
}


static inline int crc_flag_num_from_opcode (int opcode)
{
  return (opcode >> 7) + ((opcode & 020) >> 1);
}


static void crc_op_set_flag (sim_t *sim,
			     int opcode)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  crc_reg_t *crc_reg = get_chip_data (act_reg->crc_chip);
  int flag = crc_flag_num_from_opcode (opcode);

#if 0
  printf ("setting CRC flag %d\n", flag);
#endif

  crc_reg->flag [flag] = true;
}


static void crc_op_test_flag_and_clear (sim_t *sim,
					int opcode)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  crc_reg_t *crc_reg = get_chip_data (act_reg->crc_chip);
  int flag = crc_flag_num_from_opcode (opcode);

#if 0
  printf ("testing CRC flag %d: %d, clearing\n", flag, crc_reg->flag [flag] | crc_reg->ext_flag [flag]);
#endif

  if (crc_reg->flag [flag] || crc_reg->ext_flag [flag])
    act_reg->s [3] = 1;
  crc_reg->flag [flag] = false;
}


static void crc_reset (sim_t *sim)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  crc_reg_t *crc_reg = get_chip_data (act_reg->crc_chip);
  int i;

  crc_reg->flag [CRC_FLAG_WRITE_MODE] = false;
  crc_reg->flag [CRC_FLAG_BUFFER_READY] = false;
  for (i = 0; i < MAX_CRC_FLAG; i++)
    crc_reg->flag [i] = false;
}


static void crc_event_fn (sim_t      *sim,
			  chip_t     *chip UNUSED,
			  event_id_t event,
			  int        arg1,
			  int        arg2 UNUSED,
			  void       *data)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  crc_reg_t *crc_reg = get_chip_data (act_reg->crc_chip);

  switch (event)
    {
    case event_reset:
    case event_wake:
    case event_restore_completed:
       crc_reset (sim);
       break;
    case event_cycle:
    case event_sleep:
      break;
    case event_flag_out_change:
      break;
    case event_crc_card_inserted:
      crc_insert_card (sim, data);
      break;
    case event_set_flag:
      crc_reg->ext_flag [arg1] = arg2;
      break;
    default:
      // warning ("crc: unknown event %d\n", event);
      break;
    }
}

static void crc_init_ops (sim_t *sim)
{
  act_reg_t *act_reg = get_chip_data (sim->first_chip);
  int i;

#if 1
  for (i = 0; i <= 7; i++)
    {
      if (i != 0)
	act_reg->op_fcn [i << 7] = crc_op_set_flag;
      act_reg->op_fcn [(i << 7) + 00100] = crc_op_test_flag_and_clear;
    }
  for (i = 0; i <= 3; i++)
    {
      act_reg->op_fcn [(i << 7) + 00060] = crc_op_set_flag;
      act_reg->op_fcn [(i << 7) + 00160] = crc_op_test_flag_and_clear;
    }
#endif

#if 0
  // CRC chip in 67/97
  // flag 0 is buffer ready flag
  act_reg->op_fcn [00100] = crc_op_teset_flag_and_clear;

  // flag 1 is the PROG/RUN switch.
  // act_reg->op_fcn [00200] = crc_op_unknown;  // not used, probably sets flag
  act_reg->op_fcn [00500] = crc_op_test_flag_and_clear;

  // flag 2 is ??? in 67
  // flag 2 is the MAN (?) printer mode switch in 97
  act_reg->op_fcn [00400] = crc_op_set_flag;
  act_reg->op_fcn [00500] = crc_op_test_flag_and_clear;

  // flag 3 is the TRACE (?) printer mode switch in 97
  act_reg->op_fcn [00600] = crc_op_unknown;
  act_reg->op_fcn [00700] = crc_op_unknown;

  // flag 4 used for default function enable
  act_reg->op_fcn [01000] = crc_op_set_flag;
  act_reg->op_fcn [01100] = crc_op_test_flag_and_clear;

  // flag 5 is the MERGE flag
  act_reg->op_fcn [01200] = crc_op_set_flag;
  act_reg->op_fcn [01300] = crc_op_test_flag_and_clear;

  // flag 6 is the PAUSE flag
  act_reg->op_fcn [01400] = crc_op_set_flag;
  act_reg->op_fcn [01500] = crc_op_test_flag_and_clear;

  // flag 7 is ???
  act_reg->op_fcn [01600] = crc_op_unknown;  // not used
  act_reg->op_fcn [01700] = crc_op_unknown;  // sometimes followed by test S3

  // flag 8 is ???
  act_reg->op_fcn [00060] = crc_op_unknown;  // no test
  act_reg->op_fcn [00160] = crc_op_unknown;  // no test

  // flag 9 is card reader motor enable
  act_reg->op_fcn [00260] = crc_op_unknown;  // set motor enable
  act_reg->op_fcn [00360] = crc_op_unknown;  // test and clear motor enable

  // flag 10 is card inserted switch
  act_reg->op_fcn [00460] = crc_op_unknown;  // unused
  act_reg->op_fcn [00560] = crc_op_unknown;  // test card inserted switch

  // flag 11 is write mode
  act_reg->op_fcn [00660] = crc_op_unknown;  // set write mode
  act_reg->op_fcn [00760] = crc_op_unknown;  // test and clear write mode
					     //   (not used as test)
#endif
}

chip_t *crc_install (sim_t *sim,
		     int32_t index,
		     int32_t flags)
{
  act_reg_t *act_reg;
  crc_reg_t *crc_reg;

  if (sim->arch != ARCH_WOODSTOCK)
    {
      fprintf (stderr, "CRC only supports Woodstock architecture\n");
      return NULL;
    }

  act_reg = get_chip_data (sim->first_chip);
  crc_reg = alloc (sizeof (crc_reg_t));

  act_reg->crc_chip = install_chip (sim,
				    & crc_chip_detail,
				    crc_reg);

  crc_init_ops (sim);

  act_reg->ram_exists [RAMADDR_CRC_BUFFER_WRITE] = true;
  act_reg->ram_wr_fcn [RAMADDR_CRC_BUFFER_WRITE] = & crc_write;
  act_reg->ram_rd_fcn [RAMADDR_CRC_BUFFER_WRITE] = NULL;

  act_reg->ram_exists [RAMADDR_CRC_BUFFER_READ] = true;
  act_reg->ram_wr_fcn [RAMADDR_CRC_BUFFER_READ] = NULL;
  act_reg->ram_rd_fcn [RAMADDR_CRC_BUFFER_READ] = & crc_read;

  return act_reg->crc_chip;
}
