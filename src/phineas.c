/*
$Id$
Copyright 1995, 2005, 2006 Eric L. Smith <eric@brouhaha.com>

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
#include "proc.h"
#include "digit_ops.h"
#include "calcdef.h"
#include "proc_int.h"
#include "proc_nut.h"
#include "phineas.h"


// Every PHINEAS_UPDATE_CYCLES, we service the Phineas.
#define PHINEAS_UPDATE_CYCLES 67


// Bits in Phineas status register:
#define PS_ALMA    0  // ALarM A
#define PS_DTZA    1  // Decrement Through Zero A
#define PS_ALMB    2  // ALarM B
#define PS_DTZB    3  // Decrement Through Zero B
#define PS_DTZIT   4  // Decrement Through Zero Interval Timer
#define PS_PUS     5  // Power Up Status
#define PS_CKAEN   6  // ClocK A ENable
#define PS_CKBEN   7  // ClocK B ENable
#define PS_ALAEN   8  // ALarm A ENable
#define PS_ALBEN   9  // ALarm B ENable
#define PS_ITEN   10  // Interval Timer ENable
#define PS_TESTA  11
#define PS_TESTB  12

#define PS_COUNT  13


#define INTERVAL_WIDTH 5  // digits in interval timer
#define STATUS_WIDTH   4  // digits in status register (13 bits)
#define AF_WIDTH       4  // digits in accuracy factor (13 bits)


#define TIMER_A 0
#define TIMER_B 1
#define TIMER_MAX 2


#undef PHINEAS_DEBUG

#ifdef PHINEAS_DEBUG
static char *ps_bit_name [13] =
{
  [PS_ALMA]  = "ALMA",
  [PS_DTZA]  = "DTZA",
  [PS_ALMB]  = "ALMB",
  [PS_DTZB]  = "DTZB",
  [PS_DTZIT] = "DTZIT",
  [PS_PUS]   = "PUS",
  [PS_CKAEN] = "CKAEN",
  [PS_CKBEN] = "CKBEN",
  [PS_ALAEN] = "ALAEN",
  [PS_ALBEN] = "ALBEN",
  [PS_ITEN]  = "ITEN",
  [PS_TESTA] = "TESTA",
  [PS_TESTB] = "TESTB",
};
#endif


static const reg_t TIME_MODULE_ALMB_WARMSTART_CONSTANT =
{ 0, 0, 0, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 0 };


typedef struct
{
  bool timer_sel;
  bool hold;

  digit_t status [STATUS_WIDTH];  // least significant 13 bits used
  reg_t clock   [TIMER_MAX];
  reg_t alarm   [TIMER_MAX];
  reg_t scratch [TIMER_MAX];
  digit_t interval_timer    [INTERVAL_WIDTH];
  digit_t it_terminal_count [INTERVAL_WIDTH];
  digit_t accuracy_factor [AF_WIDTH];  // least significant 13 bits used

  bool selected;       // True if a PERIPH SLCT for PFADDR_PHINEAS has been
                       // seen, but cleared if a RAM SLCT is seen.
  int update_counter;  // counts down from PHINEAS_UPDATE_CYCLES
} phineas_reg_t;


#define PR(name, field, bits, radix, get, set, arg)        \
    {{ name, bits, 1, radix },                             \
     OFFSET_OF (phineas_reg_t, field),                     \
     SIZE_OF (phineas_reg_t, field),                       \
     get, set, arg } 


#define PRA(name, field, bits, radix, get, set, arg, array) \
    {{ name, bits, array, radix },                          \
     OFFSET_OF (phineas_reg_t, field[0]                     \
     SIZE_OF (phineas_reg_t, field[0]),                     \
     get, set, arg } 


#define PRD(name, field, digits) \
    {{ name, digits * 4, 1, 16 },   \
     OFFSET_OF (phineas_reg_t, field),  \
     SIZE_OF (phineas_reg_t, field),    \
     get_digits, set_digits, digits } 


#define PRAD(name, field, digits, array) \
    {{ name, digits * 4, array, 16 },   \
     OFFSET_OF (phineas_reg_t, field[0]),  \
     SIZE_OF (phineas_reg_t, field[0]),    \
     get_digits, set_digits, digits } 


static const reg_detail_t phineas_reg_detail [] =
{
  //    name               field            bits radix  get   set   arg
  PR   ("timer_sel",       timer_sel,       1,   2,     NULL, NULL, 0),
  PR   ("hold",            hold,            1,   2,     NULL, NULL, 0),

  //    name               field            digits          array
  PRAD ("clock",           clock,           WSIZE,          TIMER_MAX),
  PRAD ("alarm",           alarm,           WSIZE,          TIMER_MAX),
  PRAD ("scratch",         scratch,         WSIZE,          TIMER_MAX),

  //    name                 field              digits
  PRD  ("status",            status,            STATUS_WIDTH),
  PRD  ("interval_timer",    interval_timer,    INTERVAL_WIDTH),
  PRD  ("it_terminal_count", it_terminal_count, INTERVAL_WIDTH),
  PRD  ("accuracy_factor",   accuracy_factor,   AF_WIDTH)
};


static chip_event_fn_t phineas_event_fn;


static const chip_detail_t phineas_chip_detail =
{
  {
    "Phineas clock",
    CHIP_PHINEAS,
    false  // There can only be one Phineas on the bus.
  },
  sizeof (phineas_reg_detail) / sizeof (reg_detail_t),
  phineas_reg_detail,
  phineas_event_fn
};


// Warning - doesn't test for bit number out of range!
static bool phineas_get_status_bit (phineas_reg_t *phineas, int bit)
{
  int dig = bit / 4;
  uint8_t mask = 1 << (bit & 3);

  return (phineas->status [dig] & mask) != 0;
}


// Warning - doesn't test for bit number out of range!
static void phineas_set_status_bit (phineas_reg_t *phineas, int bit, bool val)
{
  int dig = bit / 4;
  uint8_t mask = 1 << (bit & 3);

#ifdef PHINEAS_DEBUG
  printf ("setting Phineas status %s (%d) to %d\n", ps_bit_name [bit], bit, val);
#endif

  if (val)
    phineas->status [dig] |= mask;
  else
    phineas->status [dig] &= ~ mask;
}


static void phineas_update_ext_flags (nut_reg_t *nut_reg,
				      phineas_reg_t *phineas)
{
  bool flag;

  flag = ((! phineas_get_status_bit (phineas, PS_PUS)) &&
	  (phineas_get_status_bit (phineas, PS_ALMA) ||
	   phineas_get_status_bit (phineas, PS_DTZA) ||
	   phineas_get_status_bit (phineas, PS_ALMB) ||
	   phineas_get_status_bit (phineas, PS_DTZB) ||
	   phineas_get_status_bit (phineas, PS_DTZIT)));

  if (flag)
    {
      nut_reg->ext_flag [EF_SERVICE_REQUEST] = true;
      nut_reg->awake = true;  // wake up CPU if asleep
      if (phineas->selected)
	nut_reg->ext_flag [EF_TIMER] = true;
    }
}


static bool phineas_rd_n (sim_t *sim, int n)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  phineas_reg_t *phineas = get_chip_data (nut_reg->phineas_chip);

  if (! phineas->selected)
    return false;

  reg_zero (nut_reg->c, 0, WSIZE - 1);

  switch (n)
    {
    case 0x0: // Read Clock
      reg_copy (nut_reg->c, phineas->clock [phineas->timer_sel], 0, WSIZE - 1);
      break;
    case 0x1: // Read Clock and Hold
      reg_copy (nut_reg->c, phineas->clock [phineas->timer_sel], 0, WSIZE - 1);
      phineas->hold = true;
      break;
    case 0x2: // Read Alarm
      reg_copy (nut_reg->c, phineas->alarm [phineas->timer_sel], 0, WSIZE - 1);
      break;
    case 0x3: // Read Status/Accuracy Factor
      if (phineas->timer_sel)
	{
	  // Read Accuracy Factor
          reg_copy (nut_reg->c + 1, phineas->accuracy_factor, 0, AF_WIDTH - 1);
	}
      else
	{
	  // Read Status
          reg_copy (nut_reg->c, phineas->status, 0, STATUS_WIDTH - 1);
	}
      break;
    case 0x4: // Read Scratch
      reg_copy (nut_reg->c, phineas->scratch [phineas->timer_sel], 0, WSIZE - 1);
      break;
    case 0x5: // Read Interval Timer
      reg_copy (nut_reg->c, phineas->interval_timer, 0, INTERVAL_WIDTH - 1);
      break;
    case 0x6: // unused
    case 0x7: // unused
    case 0x8: // unused
    case 0x9: // unused
    case 0xa: // unused
    case 0xb: // unused
    case 0xc: // unused
    case 0xd: // unused
    case 0xe: // unused
    case 0xf: // unused
      break;
    }
  return true;
}

static bool phineas_wr_n (sim_t *sim, int n)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  phineas_reg_t *phineas = get_chip_data (nut_reg->phineas_chip);

  if (! phineas->selected)
    return false;

  switch (n)
    {
    case 0x0: // Write Clock
#ifdef PHINEAS_DEBUG
      printf ("write clock %c\n", 'A' + phineas->timer_sel);
#endif
      reg_copy (phineas->clock [phineas->timer_sel], nut_reg->c, 0, WSIZE - 1);
      break;
    case 0x1: // Write Clock & Correct
#ifdef PHINEAS_DEBUG
      printf ("write clock and correct %c\n", 'A' + phineas->timer_sel);
#endif
      reg_copy (phineas->clock [phineas->timer_sel], nut_reg->c, 0, WSIZE - 1);
      phineas->hold = false;
      // $$$ add in any deferred increment here
      break;
    case 0x2: // Write Alarm
#ifdef PHINEAS_DEBUG
      printf ("write alarm %c\n", 'A' + phineas->timer_sel);
#endif
      reg_copy (phineas->alarm [phineas->timer_sel], nut_reg->c, 0, WSIZE - 1);
      break;
    case 0x3:
      if (phineas->timer_sel)
	{
	  // Write Accuracy Factor
#ifdef PHINEAS_DEBUG
	  printf ("write accuracy factor\n");
#endif
          reg_copy (phineas->accuracy_factor, nut_reg->c + 1, 0, AF_WIDTH - 1);
	  phineas->accuracy_factor [AF_WIDTH - 1] &= 1;
	}
      else
	{
          // Write Status - can only turn off bits 0-5
#ifdef PHINEAS_DEBUG
	  printf ("write status\n");
#endif
	  if (! (nut_reg->c [0] & 0x01))
	    phineas_set_status_bit (phineas, PS_ALMA, false);
	  if (! (nut_reg->c [0] & 0x02))
	    phineas_set_status_bit (phineas, PS_DTZA, false);
	  if (! (nut_reg->c [0] & 0x04))
	    phineas_set_status_bit (phineas, PS_ALMB, false);
	  if (! (nut_reg->c [0] & 0x08))
	    phineas_set_status_bit (phineas, PS_DTZB, false);
	  if (! (nut_reg->c [1] & 0x01))
	    phineas_set_status_bit (phineas, PS_DTZIT, false);
	  if (! (nut_reg->c [1] & 0x02))
	    phineas_set_status_bit (phineas, PS_PUS, false);
	  phineas_update_ext_flags (nut_reg, phineas);
	}
      break;
    case 0x4: // Write Scratch
#ifdef PHINEAS_DEBUG
      printf ("write scratch %c\n", 'A' + phineas->timer_sel);
#endif
      reg_copy (phineas->scratch [phineas->timer_sel], nut_reg->c, 0, WSIZE - 1);
      break;
    case 0x5: // Write Interval Timer and Start
#ifdef PHINEAS_DEBUG
      printf ("write interval timer and start\n");
#endif
      reg_copy (phineas->it_terminal_count, nut_reg->c, 0, INTERVAL_WIDTH - 1);
      reg_zero (phineas->interval_timer, 0, INTERVAL_WIDTH - 1);
      phineas_set_status_bit (phineas, PS_ITEN, true);
      break;
    case 0x6: // unused
      break;
    case 0x7: // Stop Interval Timer
#ifdef PHINEAS_DEBUG
      printf ("stop interval timer\n");
#endif
      phineas_set_status_bit (phineas, PS_ITEN, false);
      break;
    case 0x8: // Clear Test Mode
      phineas_set_status_bit (phineas, PS_TESTA + phineas->timer_sel, false);
      break;
    case 0x9: // Set Test Mode
      phineas_set_status_bit (phineas, PS_TESTA + phineas->timer_sel, true);
      break;
    case 0xa: // Disable Alarm
      phineas_set_status_bit (phineas, PS_ALAEN + phineas->timer_sel, false);
      break;
    case 0xb: // Enable Alarm
      phineas_set_status_bit (phineas, PS_ALAEN + phineas->timer_sel, true);
      break;
    case 0xc: // Stop Clock
      phineas_set_status_bit (phineas, PS_CKAEN + phineas->timer_sel, false);
      break;
    case 0xd: // Start Clock
      phineas_set_status_bit (phineas, PS_CKAEN + phineas->timer_sel, true);
      break;
    case 0xe: // Set Pointer to B
      phineas->timer_sel = 1;
      break;
    case 0xf: // Set Pointer to A
      phineas->timer_sel = 0;
      break;
    }
  return true;
}


static bool phineas_wr (sim_t *sim UNUSED)
{
  return false; // Phineas doesn't use the generic write
}


// Increments a clock register by specified number of ticks,
// and compares to alarm register.  Returns overflow and alarm
// indications.
static void phineas_increment_clock (phineas_reg_t *phineas,
				     bool sel,
				     uint32_t ticks)
{
  uint64_t old_val, new_val, alarm_val;
  bool overflow, alarm;

  // clock running?
  if (! phineas_get_status_bit (phineas, PS_CKAEN + sel))
    return;  // no, done

  // read old_val from clock
  old_val = bcd_reg_to_binary (phineas->clock [sel], WSIZE);

  new_val = old_val + ticks;
  overflow = (new_val > 99999999999999ull);
  if (overflow)
    {
      new_val -= 100000000000000ull;
      phineas_set_status_bit (phineas, PS_DTZA + 2 * sel, true);
    }

  // write new_val back to clock
  binary_to_bcd_reg (new_val, phineas->clock [sel], WSIZE);

  // alarm enabled?
  if (! phineas_get_status_bit (phineas, PS_ALAEN + sel))
    return;  // no, done

  // read alarm from clock
  alarm_val = bcd_reg_to_binary (phineas->alarm [sel], WSIZE);

  if (overflow)
    alarm = (alarm_val > old_val) || (alarm_val <= new_val);
  else
    alarm = (alarm_val > old_val) && (alarm_val <= new_val);

  if (alarm)
    phineas_set_status_bit (phineas, PS_ALMA + 2 * sel, true);
}


// Increments the interval timer by the specified number of ticks.
// Returns overflow indication.
static void phineas_increment_interval_timer (phineas_reg_t *phineas,
					      uint32_t ticks)
{
  uint32_t val, tc;

  // clock running?
  if (! phineas_get_status_bit (phineas, PS_ITEN))
    return;  // no, done

  // read interval_timer and terminal count
  val = bcd_reg_to_binary (phineas->interval_timer,    INTERVAL_WIDTH);
  tc  = bcd_reg_to_binary (phineas->it_terminal_count, INTERVAL_WIDTH);

#ifdef PHINEAS_DEBUG
  printf ("incrementing interval timer from %u by %u, tc=%u", val, ticks, tc);
#endif

  val += ticks;
  if (val >= tc)
    {
      val = 0;
      phineas_set_status_bit (phineas, PS_DTZIT, true);
    }

#ifdef PHINEAS_DEBUG
  printf (", result %u\n", val);
#endif

  // write val back to interval timer
  binary_to_bcd_reg (val, phineas->interval_timer, INTERVAL_WIDTH);
}


static void phineas_update (nut_reg_t *nut_reg, phineas_reg_t *phineas)
{
  uint32_t ticks = 1;
  int sel;

  for (sel = TIMER_A; sel <= TIMER_B; sel++)
    phineas_increment_clock (phineas, sel, ticks);
  phineas_increment_interval_timer (phineas, ticks);
  phineas_update_ext_flags (nut_reg, phineas);
}


static void phineas_reset (phineas_reg_t *phineas)
{
  phineas_set_status_bit (phineas, PS_PUS, true);  // initial power-up
}


static void phineas_event_fn (sim_t  *sim,
			      chip_t *chip UNUSED,
			      int    event,
			      int    arg UNUSED,
			      void   *data UNUSED)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  phineas_reg_t *phineas = get_chip_data (nut_reg->phineas_chip);

  switch (event)
    {
    case event_reset:
      phineas_reset (phineas);
      break;
    case event_cycle:
      if ((--phineas->update_counter) == 0)
	{
	  phineas_update (nut_reg, phineas);
	  phineas->update_counter = PHINEAS_UPDATE_CYCLES;
	}
      break;
    case event_sleep:
      phineas->update_counter = PHINEAS_UPDATE_CYCLES;
      break;
    case event_wake:
    case event_restore_completed:
      phineas_update (nut_reg, phineas);
      phineas->update_counter = PHINEAS_UPDATE_CYCLES;
      break;
    case event_ram_select:
      phineas->selected = false;
      phineas_update_ext_flags (nut_reg, phineas); 
      break;
    case event_periph_select:
      phineas->selected = nut_reg->pf_addr == PFADDR_PHINEAS;
      phineas_update_ext_flags (nut_reg, phineas);
      break;
    default:
      // warning ("phineas: unknown event %d\n", event);
      break;
    }
}


static void phineas_init_ops (sim_t *sim UNUSED)
{
}


chip_t *phineas_init (sim_t *sim)
{
  nut_reg_t *nut_reg = get_chip_data (sim->first_chip);
  phineas_reg_t *clock;

  clock = alloc (sizeof (phineas_reg_t));

  nut_reg->pf_exists [PFADDR_PHINEAS] = 1;
  nut_reg->rd_n_fcn  [PFADDR_PHINEAS] = & phineas_rd_n;
  nut_reg->wr_n_fcn  [PFADDR_PHINEAS] = & phineas_wr_n;
  nut_reg->wr_fcn    [PFADDR_PHINEAS] = & phineas_wr;

  nut_reg->phineas_chip = install_chip (sim,
					& phineas_chip_detail,
					clock);

  phineas_init_ops (sim);

  return nut_reg->phineas_chip;
}
