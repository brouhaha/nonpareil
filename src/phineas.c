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

/*
 * Phineas clock chip in Time Module and 41CX
 */

#include <stdio.h>
#include "nsim.h"
#include "phineas.h"

#define TIMER_MAX 2
#define TIMER_A 0
#define TIMER_B 1

int timer_reg_sel = TIMER_A;

int clock_enable [TIMER_MAX];
int alarm_enable [TIMER_MAX];
int clock_decr [TIMER_MAX];  /* count up */
int sec_wakeup = 0;
int min_wakeup = 0;
int interval_running = 0;

reg clock_reg [TIMER_MAX];
reg alarm_reg [TIMER_MAX];
reg timer_status;
reg accuracy_factor;
reg interval_timer;
reg timer_scratch;

static void phineas_rd_n (int n)
{
  switch (n)
    {
    case 0x0: /* 038: RTIME */
      reg_copy (c, clock_reg [timer_reg_sel]);
      break;
    case 0x1: /* 078: RTIMEST */
      reg_copy (c, clock_reg [timer_reg_sel]);
      /* start correction count ??? */
      break;
    case 0x2: /* 0b8: RALM */
      reg_copy (c, alarm_reg [timer_reg_sel]);
      break;
    case 0x3: /* 0f8: RSTS */
      reg_copy (c, timer_reg_sel ? accuracy_factor : timer_status);
      break;
    case 0x4: /* 138: RSCR */
      reg_copy (c, timer_scratch);
      break;
    case 0x5: /* 178: RINT */
      reg_copy (c, interval_timer);
      break;
    case 0x6: /* 1b8: ??? */
    case 0x7: /* 1f8: ??? */
    case 0x8: /* 238: ??? */
    case 0x9: /* 278: ??? */
    case 0xa: /* 2b8: ??? */
    case 0xb: /* 2f8: ??? */
    case 0xc: /* 338: ??? */
    case 0xd: /* 378: ??? */
    case 0xe: /* 3b8: ??? */
    case 0xf: /* 3f8: ??? */
      reg_zero (c);
      break;
    }
}

static void phineas_wr_n (int n)
{
  switch (n)
    {
    case 0x0: /* 028: WTIME   write C to clock register */
      reg_copy (clock_reg [timer_reg_sel], c);
      clock_decr [timer_reg_sel] = 0;
      break;
    case 0x1: /* 068: WTIME-  write C to clock register and set to decr */ 
      reg_copy (clock_reg [timer_reg_sel], c);
      clock_decr [timer_reg_sel]= 1;
      break;
    case 0x2: /* 0a8: WALM    write C to alarm register */
      reg_copy (alarm_reg [timer_reg_sel], c);
      break;
    case 0x3: /* 0e8: WSTS */
      reg_copy (timer_reg_sel ? accuracy_factor : timer_status, c);
      break;
    case 0x4: /* 128: WSCR    write C to scratch register */
      reg_copy (timer_scratch, c);
      break;
    case 0x5: /* 168: WINTST  write C to interval timer and start */
      reg_copy (interval_timer, c);
      interval_running = 1;
      break;
    case 0x6: /* 1a8: ??? */
      break;
    case 0x7: /* 1e8: STPINT  stop interval timer */
      interval_running = 0;
      break;
    case 0x8: /* 228: WKUPOFF */
      if (timer_reg_sel == TIMER_A)
	sec_wakeup = 0;
      else
	min_wakeup = 0;
      break;
    case 0x9: /* 268: WKUPON */ break;
      if (timer_reg_sel == TIMER_A)
	sec_wakeup = 1;
      else
	min_wakeup = 1;
      break;
    case 0xa: /* 2a8: ALMOFF */ 
      alarm_enable [timer_reg_sel] = 0;
      break;
    case 0xb: /* 2e8: ALMON */
      alarm_enable [timer_reg_sel] = 1;
      break;
    case 0xc: /* 328: STOPC */
      clock_enable [timer_reg_sel] = 0; 
      break;
    case 0xd: /* 368: STARTC */
      clock_enable [timer_reg_sel] = 1;
      break;
    case 0xe: /* 3a8: TIMER=A */
      timer_reg_sel = TIMER_A;
      break;
    case 0xf: /* 3e8: TIMER=B */
      timer_reg_sel = TIMER_B;
      break;
    }
}

static void phineas_wr (void)
{
  /* don't do anything?  write selected register? */
}

void init_phineas (void)
{
  int i, t;

  pf_exists [PHINEAS] = 1;
  rd_n_fcn  [PHINEAS] = & phineas_rd_n;
  wr_n_fcn  [PHINEAS] = & phineas_wr_n;
  wr_fcn    [PHINEAS] = & phineas_wr;

  for (t = 0; t < TIMER_MAX; t++)
    {
      clock_enable [t] = 0;
      alarm_enable [t] = 0;
      clock_decr [t] = 0;
      for (i = 0; i < WSIZE; i++)
	{
	  clock_reg [t][i] = 0;
	  alarm_reg [t][i] = 0;
	}
    }
  for (i = 0; i < WSIZE; i++)
    {
      timer_status [i] = 0;
      accuracy_factor [i] = 0;
      interval_timer [i] = 0;
      timer_scratch [i] = 0;
    }
}

