/*
proc.c
$Id$
Copyright 1995, 2004 Eric L. Smith

Nonpareil is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License version 2 as
published by the Free Software Foundation.  Note that I am not
granting permission to redistribute or modify CASM under the terms of
any later version of the General Public License.

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
#include <stdlib.h>
#include <string.h>

#include <glib.h>

#include "arch.h"
#include "util.h"
#include "proc.h"
#include "proc_int.h"


/* The real hardware executes a fixed number of microinstructions per
   second.  The HP-55 uses a crystal, but the other models use an LC
   oscillator that is not adjusted.  We try to run at nominally the
   same rate. */
#define UINST_PER_SEC 3500

/* we try to schedule execution in "jiffies": */
#define JIFFY_PER_SEC 30

#define UINST_USEC (1.0e6 / UINST_PER_SEC)
#define JIFFY_USEC (1.0e6 / JIFFY_PER_SEC)


/*
 * set breakpoints at every location so we know if we hit
 * uninitialized ROM
 */
static void init_breakpoints (sim_t *sim)
{
  int g, r, p;

  for (g = 0; g < MAX_GROUP; g++)
    for (r = 0; r < MAX_ROM; r++)
      for (p = 0; p < ROM_SIZE; p++)
	sim->bpt [g] [r] [p] = 1;
}


static int parse_octal (char *oct, int digits, int *val)
{
  *val = 0;

  while (digits--)
    {
      if (((*oct) < '0') || ((*oct) > '7'))
	return (0);
      (*val) = ((*val) << 3) + ((*(oct++)) - '0');
    }
  return (1);
}


static void init_source (sim_t *sim)
{
  int g, r, p;

  for (g = 0; g < MAX_GROUP; g++)
    for (r = 0; r < MAX_ROM; r++)
      for (p = 0; p < ROM_SIZE; p++)
	sim->source [g] [r] [p] = NULL;
}


bool sim_read_object_file (sim_t *sim, char *fn)
{
  int i;
  FILE *f;
  int g, r, p, opcode;
  int count = 0;
  char buf [80];

  f = fopen (fn, "r");
  if (! f)
    {
      fprintf (stderr, "error opening listing file\n");
      return (false);
    }

  while (fgets (buf, sizeof (buf), f))
    {
      i = sscanf (buf, "%1o%1o%3o:%3x", & g, & r, & p, & opcode);
      if (i != 4)
	fprintf (stderr, "only converted %d items\n", i);
      else if ((g >= MAX_GROUP) || (r >= MAX_ROM) || (p >= ROM_SIZE))
	fprintf (stderr, "bad address\n");
      else
	{
	  sim->ucode [g][r][p] = opcode;
	  sim->bpt   [g][r][p] = 0;
	  count ++;
	}
    }
  fprintf (stderr, "read %d words from '%s'\n", count, fn);
  return (true);
}


bool sim_read_listing_file (sim_t *sim, char *fn, int keep_src)
{
  FILE *f;
  int addr, g, r, p, opcode;
  int count = 0;
  char buf [80];

  f = fopen (fn, "r");
  if (! f)
    {
      fprintf (stderr, "error opening listing file\n");
      return (false);
    }

  while (fgets (buf, sizeof (buf), f))
    {
      trim_trailing_whitespace (buf);
      if ((strlen (buf) >= 18) &&
	  parse_octal (& buf [15], 4, & addr) &&
	  parse_octal (& buf [ 9], 4, & opcode))
	{
	  g = 0;
	  r = addr >> 8;
	  p = addr & 0377;
	  if ((g >= MAX_GROUP) || (r >= MAX_ROM) || (p >= ROM_SIZE))
	    fprintf (stderr, "bad address\n");
	  else if (! sim->bpt [g][r][p])
	    {
	      fprintf (stderr, "duplicate listing line for address %1o%1o%03o\n",
		       g, r, p);
	      fprintf (stderr, "orig: %s\n", sim->source [g][r][p]);
	      fprintf (stderr, "dup:  %s\n", buf);
	    }
	  else
	    {
	      sim->ucode  [g][r][p] = opcode;
	      sim->bpt    [g][r][p] = 0;
	      if (keep_src)
		sim->source [g][r][p] = newstr (& buf [0]);
	      count ++;
	    }
	}
    }
#if 0
  fprintf (stderr, "read %d words from '%s'\n", count, fn);
#endif
  return (true);
}


gpointer sim_thread_func (gpointer data)
{
  int i;
  long usec;

  sim_t *sim = (sim_t *) data;

  for (;;)
    {
      g_mutex_lock (sim->sim_mutex);
      if (sim->state != sim->prev_state)
	{
	  if (sim->state == SIM_RUN)
	    g_get_current_time (& sim->prev_tv);
	}
      sim->prev_state = sim->state;
      switch (sim->state)
	{
	case SIM_QUIT:
	  g_mutex_unlock (sim->sim_mutex);
	  g_thread_exit (0);

	case SIM_RESET:
	  sim->proc->reset_processor (sim);
	  sim->state = SIM_IDLE;
	  g_cond_signal (sim->ui_cond);
	  g_cond_wait (sim->sim_cond, sim->sim_mutex);
	  break;

	case SIM_IDLE:
	  g_cond_wait (sim->sim_cond, sim->sim_mutex);
	  break;

	case SIM_STEP:
	  sim->proc->execute_instruction (sim);
	  /* handle_io (sim); */
	  sim->state = SIM_IDLE;
	  g_cond_signal (sim->ui_cond);
	  g_cond_wait (sim->sim_cond, sim->sim_mutex);
	  break;

	case SIM_RUN:
	  /* find out how much time has elapsed, saturated at one second */
	  g_get_current_time (& sim->tv);

	  /* compute how many microinstructions we want to execute */
	  usec = sim->tv.tv_usec - sim->prev_tv.tv_usec;
	  switch (sim->tv.tv_sec - sim->prev_tv.tv_sec)
	    {
	    case 0: break;
	    case 1: usec += 1000000; break;
	    default: usec = 1000000;
	    }
	  i = usec / UINST_USEC;
#if 0
	  printf ("tv %d.%06d, usec %d, i %d\n", sim->tv.tv_sec, sim->tv.tv_usec, usec, i);
#endif

	  /* execute the microinstructions */
	  while (i--)
	    {
	      sim->proc->execute_instruction (sim);
	    }

	  /* update the display */
	  /* handle_io (sim); */

	  /* remember when we ran */
	  memcpy (& sim->prev_tv, & sim->tv, sizeof (GTimeVal));

	  /* sleep a while */
	  g_time_val_add (& sim->tv, JIFFY_USEC);
	  g_cond_timed_wait (sim->sim_cond, sim->sim_mutex, & sim->tv);
	  break;

	default:
	  fatal (2, "bad simulator state\n");
	}
      g_mutex_unlock (sim->sim_mutex);
    }

  return (NULL);  /* $$$ Hmmm... what are we supposed to return? */
}


/* The following functions can be called from the main thread: */

sim_t *sim_init (int arch,
		 int ram_size,
		 void (*display_update_fn)(char *buf))
{
  sim_t *sim;

  sim = alloc (sizeof (sim_t));

  sim->arch = arch;
  sim->proc = processor_dispatch [arch];

  sim->prev_state = SIM_UNKNOWN;
  sim->state = SIM_IDLE;

  g_thread_init (NULL);  /* $$$ has Gtk already done this? */

  sim->sim_cond = g_cond_new ();
  sim->ui_cond = g_cond_new ();
  sim->sim_mutex = g_mutex_new ();

  g_mutex_lock (sim->sim_mutex);

  sim->proc->new_processor (sim, ram_size);

  init_breakpoints (sim);
  init_source (sim);

  sim->display_update = display_update_fn;

  sim->state = SIM_IDLE;

  sim->cycle_count = 0;

  sim->thread = g_thread_create (sim_thread_func, sim, TRUE, NULL);

  g_mutex_unlock (sim->sim_mutex);

  return (sim);
}


void sim_quit (sim_t *sim)
{
  g_mutex_lock (sim->sim_mutex);
  sim->state = SIM_QUIT;

  g_thread_join (sim->thread);

  free (sim);
}


void sim_reset (sim_t *sim)
{
  g_mutex_lock (sim->sim_mutex);
  if (sim->state != SIM_IDLE)
    fatal (2, "can't reset when not idle\n");
  sim->state = SIM_RESET;
  g_cond_signal (sim->sim_cond);
  while (sim->state != SIM_IDLE)
    g_cond_wait (sim->ui_cond, sim->sim_mutex);
  g_mutex_unlock (sim->sim_mutex);
}


void sim_step (sim_t *sim)
{
  g_mutex_lock (sim->sim_mutex);
  if (sim->state != SIM_IDLE)
    fatal (2, "can't step when not idle\n");
  sim->state = SIM_STEP;
  g_cond_signal (sim->sim_cond);
  while (sim->state != SIM_IDLE)
    g_cond_wait (sim->ui_cond, sim->sim_mutex);
  g_mutex_unlock (sim->sim_mutex);
}


void sim_start (sim_t *sim)
{
  g_mutex_lock (sim->sim_mutex);
  if (sim->state != SIM_IDLE)
    fatal (2, "can't start when not idle\n");
  sim->state = SIM_RUN;
  g_cond_signal (sim->sim_cond);
  g_mutex_unlock (sim->sim_mutex);
}


void sim_stop (sim_t *sim)
{
  g_mutex_lock (sim->sim_mutex);
  if (sim->state == SIM_IDLE)
    goto done;
  if (sim->state != SIM_RUN)
    fatal (2, "can't stop when not running\n");
  sim->state = SIM_IDLE;
  g_cond_signal (sim->sim_cond);
done:
  g_mutex_unlock (sim->sim_mutex);
}


uint64_t sim_get_cycle_count (sim_t *sim)
{
  uint64_t count;
  g_mutex_lock (sim->sim_mutex);
  count = sim->cycle_count;
  g_mutex_unlock (sim->sim_mutex);
  return (count);
}


void sim_set_cycle_count (sim_t *sim, uint64_t count)
{
  g_mutex_lock (sim->sim_mutex);
  sim->cycle_count = count;
  g_mutex_unlock (sim->sim_mutex);
}


void sim_set_breakpoint (sim_t *sim, int address)
{
  /* $$$ not yet implemented */
}


void sim_clear_breakpoint (sim_t *sim, int address)
{
  /* $$$ not yet implemented */
}


bool sim_running (sim_t *sim)
{
  bool result;
  g_mutex_lock (sim->sim_mutex);
  result = (sim->state == SIM_RUN);
  g_mutex_unlock (sim->sim_mutex);
  return (result);
}


sim_env_t *sim_get_env (sim_t *sim)
{
  sim_env_t *env;

  g_mutex_lock (sim->sim_mutex);
  env = sim->proc->get_env (sim);
  g_mutex_unlock (sim->sim_mutex);
  return (env);
}


void sim_set_env (sim_t *sim, sim_env_t *env)
{
  g_mutex_lock (sim->sim_mutex);
  sim->proc->set_env (sim, env);
  g_mutex_unlock (sim->sim_mutex);
}


void sim_free_env (sim_t *sim, sim_env_t *env)
{
  g_mutex_lock (sim->sim_mutex);
  sim->proc->free_env (sim, env);
  g_mutex_unlock (sim->sim_mutex);
}


romword sim_read_rom (sim_t *sim, int addr)
{
  /* The ROM is read-only, so we don't have to grab the mutex. */
  /* $$$ not yet implemented */
  return (0);
}


void sim_read_ram (sim_t *sim, int addr, reg_t *val)
{
  g_mutex_lock (sim->sim_mutex);
  sim->proc->read_ram (sim, addr, val);
  g_mutex_unlock (sim->sim_mutex);
}

void sim_write_ram (sim_t *sim, int addr, reg_t *val)
{
  g_mutex_lock (sim->sim_mutex);
  sim->proc->write_ram (sim, addr, val);
  g_mutex_unlock (sim->sim_mutex);
}


void sim_press_key (sim_t *sim, int keycode)
{
  g_mutex_lock (sim->sim_mutex);
  sim->proc->press_key (sim, keycode);
  g_mutex_unlock (sim->sim_mutex);
}


void sim_release_key (sim_t *sim)
{
  g_mutex_lock (sim->sim_mutex);
  sim->proc->release_key (sim);
  g_mutex_unlock (sim->sim_mutex);
}


void sim_set_ext_flag (sim_t *sim, int flag, bool state)
{
  g_mutex_lock (sim->sim_mutex);
  sim->proc->set_ext_flag (sim, flag, state);
  g_mutex_unlock (sim->sim_mutex);
}


extern processor_dispatch_t classic_processor;
extern processor_dispatch_t woodstock_processor;

processor_dispatch_t *processor_dispatch [ARCH_MAX] =
  {
    [ARCH_UNKNOWN]   = NULL,
    [ARCH_CLASSIC]   = NULL, /* & classic_processor, */
    [ARCH_WOODSTOCK] = & woodstock_processor,
    [ARCH_CRICKET]   = NULL,
    [ARCH_NUT]       = NULL,
    [ARCH_CAPRICORN] = NULL,
    [ARCH_SATURN]    = NULL
  };
