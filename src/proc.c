/*
$Id$
Copyright 1995, 2004 Eric L. Smith <eric@brouhaha.com>

Nonpareil is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License version 2 as
published by the Free Software Foundation.  Note that I am not
granting permission to redistribute or modify Nonpareil under the
terms of any later version of the General Public License.

Nonpareil is distributed in the hope that it will be useful (or at
least amusing), but WITHOUT ANY WARRANTY; without even the implied
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See
the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program (in the file "COPYING"); if not, write to the
Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
MA 02111, USA.
*/

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <glib.h>

#include "arch.h"
#include "util.h"
#include "display.h"
#include "proc.h"
#include "proc_int.h"


/* we try to schedule execution in "jiffies": */
#define JIFFY_PER_SEC 30

#define JIFFY_USEC (1.0e6 / JIFFY_PER_SEC)


struct sim_thread_t
{
  GThread  *thread;
  GCond    *sim_cond;
  GCond    *ui_cond;
  GMutex   *sim_mutex;

  GTimeVal tv;
  GTimeVal prev_tv;
};


/*
 * allocate space for microcode ROM, as well as source code and breakpoints.
 * Set breakpoints at every location so we know if we hit uninitialized ROM.
 */
static void allocate_ucode (sim_t *sim)
{
  int size, i;

  size = sim->proc->max_bank * sim->proc->max_rom;

  sim->ucode      = alloc (size * sizeof (rom_word_t));
  sim->source     = alloc (size * sizeof (char *));
  sim->breakpoint = alloc (size * sizeof (bool));

  for (i = 0; i < size; i++)
    sim->breakpoint [i] = true;
}


bool sim_read_object_file (sim_t *sim, char *fn)
{
  FILE *f;
  int bank, addr, i;
  rom_word_t opcode;
  int count = 0;
  char buf [80];

  f = fopen (fn, "r");
  if (! f)
    {
      fprintf (stderr, "error opening object file\n");
      return (false);
    }

  while (fgets (buf, sizeof (buf), f))
    {
      trim_trailing_whitespace (buf);
      if (! buf [0])
	continue;
      if (sim->proc->parse_object_line (buf, & bank, & addr, & opcode))
	{
	  i = bank * sim->proc->max_rom + addr;
	  if (! sim->breakpoint [i])
	    {
	      fprintf (stderr, "duplicate object code for bank %d address %o\n",
		       bank, addr);
	      // fprintf (stderr, "orig: %s\n", sim->source [i]);
	      fprintf (stderr, "dup:  %s\n", buf);
	    }
	  sim->ucode      [i] = opcode;
	  sim->breakpoint [i] = 0;
	  count++;
	}
    }

#if 0
  fprintf (stderr, "read %d words from '%s'\n", count, fn);
#endif
  return (true);
}


bool sim_read_listing_file (sim_t *sim, char *fn)
{
  FILE *f;
  int bank, addr, i;
  rom_word_t opcode;
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
      if (sim->proc->parse_listing_line (buf, & bank, & addr, & opcode))
	{
	  i = bank * sim->proc->max_rom + addr;
	  if (sim->breakpoint [i])
	    {
	      fprintf (stderr, "listing line for which there was no code in object file, bank %d address %o\n",
		       bank, addr);
	      fprintf (stderr, "src: %s\n", sim->source [i]);
	    }
	  if (sim->ucode [i] != opcode)
	    {
	      fprintf (stderr, "listing line for which object code does not match object file, bank %d address %o\n",
		       bank, addr);
	      fprintf (stderr, "src: %s\n", sim->source [i]);
	      fprintf (stderr, "object file: %04o\n", sim->ucode [i]);
	    }
	  sim->source   [i] = newstr (& buf [0]);
	  count++;
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
      g_mutex_lock (sim->thread->sim_mutex);
      if (sim->state != sim->prev_state)
	{
	  if (sim->state == SIM_RUN)
	    g_get_current_time (& sim->thread->prev_tv);
	}
      sim->prev_state = sim->state;
      switch (sim->state)
	{
	case SIM_QUIT:
	  g_mutex_unlock (sim->thread->sim_mutex);
	  g_thread_exit (0);

	case SIM_RESET:
	  sim->proc->reset_processor (sim);
	  sim->state = SIM_IDLE;
	  g_cond_signal (sim->thread->ui_cond);
	  g_cond_wait (sim->thread->sim_cond, sim->thread->sim_mutex);
	  break;

	case SIM_IDLE:
	  g_cond_wait (sim->thread->sim_cond, sim->thread->sim_mutex);
	  break;

	case SIM_STEP:
	  sim->proc->execute_instruction (sim);
	  /* handle_io (sim); */
	  sim->state = SIM_IDLE;
	  g_cond_signal (sim->thread->ui_cond);
	  g_cond_wait (sim->thread->sim_cond, sim->thread->sim_mutex);
	  break;

	case SIM_RUN:
	  /* find out how much time has elapsed, saturated at one second */
	  g_get_current_time (& sim->thread->tv);

	  /* compute how many microinstructions we want to execute */
	  usec = sim->thread->tv.tv_usec - sim->thread->prev_tv.tv_usec;
	  switch (sim->thread->tv.tv_sec - sim->thread->prev_tv.tv_sec)
	    {
	    case 0: break;
	    case 1: usec += 1000000; break;
	    default: usec = 1000000;
	    }
	  i = usec * sim->words_per_usec;
#if 0
	  printf ("tv %d.%06d, usec %d, i %d\n", sim->thread->tv.tv_sec,
		  sim->thread->tv.tv_usec, usec, i);
#endif

	  /* execute the microinstructions */
	  while (i--)
	    {
	      if (! sim->proc->execute_instruction (sim))
		break;
	    }

	  /* update the display */
	  /* handle_io (sim); */

	  /* remember when we ran */
	  memcpy (& sim->thread->prev_tv, & sim->thread->tv, sizeof (GTimeVal));

	  /* sleep a while */
	  g_time_val_add (& sim->thread->tv, JIFFY_USEC);
	  g_cond_timed_wait (sim->thread->sim_cond, sim->thread->sim_mutex,
			     & sim->thread->tv);
	  break;

	default:
	  fatal (2, "bad simulator state\n");
	}
      g_mutex_unlock (sim->thread->sim_mutex);
    }

  return (NULL);  /* $$$ Hmmm... what are we supposed to return? */
}


/* The following functions can be called from the main thread: */

sim_t *sim_init  (int platform,
		  int arch,
		  int clock_frequency,  /* Hz */
		  int ram_size,
		  segment_bitmap_t *char_gen,
		  display_handle_t *display_handle,
		  display_update_fn_t *display_update_fn)
{
  sim_t *sim;
  arch_info_t *arch_info;

  sim = alloc (sizeof (sim_t));
  sim->thread = alloc (sizeof (sim_thread_t));

  sim->arch = arch;
  sim->proc = processor_dispatch [arch];
  arch_info = get_arch_info (arch);

  sim->platform = platform;

  sim->words_per_usec = clock_frequency / (1.0e6 * arch_info->word_length);

  sim->prev_state = SIM_UNKNOWN;
  sim->state = SIM_IDLE;

  g_thread_init (NULL);  /* $$$ has Gtk already done this? */

  sim->thread->sim_cond = g_cond_new ();
  sim->thread->ui_cond = g_cond_new ();
  sim->thread->sim_mutex = g_mutex_new ();

  g_mutex_lock (sim->thread->sim_mutex);

  sim->proc->new_processor (sim, ram_size);

  allocate_ucode (sim);

  sim->char_gen = char_gen;
  sim->display_handle = display_handle;
  sim->display_update_fn = display_update_fn;

  sim->state = SIM_IDLE;

  sim->cycle_count = 0;

  sim->thread->thread = g_thread_create (sim_thread_func, sim, TRUE, NULL);

  g_mutex_unlock (sim->thread->sim_mutex);

  return (sim);
}


void sim_quit (sim_t *sim)
{
  g_mutex_lock (sim->thread->sim_mutex);
  sim->state = SIM_QUIT;

  g_thread_join (sim->thread->thread);

  free (sim);
}


void sim_reset (sim_t *sim)
{
  g_mutex_lock (sim->thread->sim_mutex);
  if (sim->state != SIM_IDLE)
    fatal (2, "can't reset when not idle\n");
  sim->state = SIM_RESET;
  g_cond_signal (sim->thread->sim_cond);
  while (sim->state != SIM_IDLE)
    g_cond_wait (sim->thread->ui_cond, sim->thread->sim_mutex);
  g_mutex_unlock (sim->thread->sim_mutex);
}


void sim_step (sim_t *sim)
{
  g_mutex_lock (sim->thread->sim_mutex);
  if (sim->state != SIM_IDLE)
    fatal (2, "can't step when not idle\n");
  sim->state = SIM_STEP;
  g_cond_signal (sim->thread->sim_cond);
  while (sim->state != SIM_IDLE)
    g_cond_wait (sim->thread->ui_cond, sim->thread->sim_mutex);
  g_mutex_unlock (sim->thread->sim_mutex);
}


void sim_start (sim_t *sim)
{
  g_mutex_lock (sim->thread->sim_mutex);
  if (sim->state != SIM_IDLE)
    fatal (2, "can't start when not idle\n");
  sim->state = SIM_RUN;
  g_cond_signal (sim->thread->sim_cond);
  g_mutex_unlock (sim->thread->sim_mutex);
}


void sim_stop (sim_t *sim)
{
  g_mutex_lock (sim->thread->sim_mutex);
  if (sim->state == SIM_IDLE)
    goto done;
  if (sim->state != SIM_RUN)
    fatal (2, "can't stop when not running\n");
  sim->state = SIM_IDLE;
  g_cond_signal (sim->thread->sim_cond);
done:
  g_mutex_unlock (sim->thread->sim_mutex);
}


uint64_t sim_get_cycle_count (sim_t *sim)
{
  uint64_t count;
  g_mutex_lock (sim->thread->sim_mutex);
  count = sim->cycle_count;
  g_mutex_unlock (sim->thread->sim_mutex);
  return (count);
}


void sim_set_cycle_count (sim_t *sim, uint64_t count)
{
  g_mutex_lock (sim->thread->sim_mutex);
  sim->cycle_count = count;
  g_mutex_unlock (sim->thread->sim_mutex);
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
  g_mutex_lock (sim->thread->sim_mutex);
  result = (sim->state == SIM_RUN);
  g_mutex_unlock (sim->thread->sim_mutex);
  return (result);
}


sim_env_t *sim_get_env (sim_t *sim)
{
  sim_env_t *env;

  g_mutex_lock (sim->thread->sim_mutex);
  env = sim->proc->get_env (sim);
  g_mutex_unlock (sim->thread->sim_mutex);
  return (env);
}


void sim_set_env (sim_t *sim, sim_env_t *env)
{
  g_mutex_lock (sim->thread->sim_mutex);
  sim->proc->set_env (sim, env);
  g_mutex_unlock (sim->thread->sim_mutex);
}


void sim_free_env (sim_t *sim, sim_env_t *env)
{
  g_mutex_lock (sim->thread->sim_mutex);
  sim->proc->free_env (sim, env);
  g_mutex_unlock (sim->thread->sim_mutex);
}


rom_word_t sim_read_rom (sim_t *sim, int addr)
{
  /* The ROM is read-only, so we don't have to grab the mutex. */
  /* $$$ not yet implemented */
  return (0);
}


void sim_read_ram (sim_t *sim, int addr, reg_t *val)
{
  g_mutex_lock (sim->thread->sim_mutex);
  sim->proc->read_ram (sim, addr, val);
  g_mutex_unlock (sim->thread->sim_mutex);
}

void sim_write_ram (sim_t *sim, int addr, reg_t *val)
{
  g_mutex_lock (sim->thread->sim_mutex);
  sim->proc->write_ram (sim, addr, val);
  g_mutex_unlock (sim->thread->sim_mutex);
}


void sim_press_key (sim_t *sim, int keycode)
{
  g_mutex_lock (sim->thread->sim_mutex);
  sim->proc->press_key (sim, keycode);
  g_mutex_unlock (sim->thread->sim_mutex);
}


void sim_release_key (sim_t *sim)
{
  g_mutex_lock (sim->thread->sim_mutex);
  sim->proc->release_key (sim);
  g_mutex_unlock (sim->thread->sim_mutex);
}


void sim_set_ext_flag (sim_t *sim, int flag, bool state)
{
  g_mutex_lock (sim->thread->sim_mutex);
  sim->proc->set_ext_flag (sim, flag, state);
  g_mutex_unlock (sim->thread->sim_mutex);
}


#ifdef HAS_DEBUGGER

void sim_set_debug_flag (sim_t *sim, int debug_flag, bool val)
{
  if (val)
    sim->debug_flags |= (1 << debug_flag);
  else
    sim->debug_flags &= ~ (1 << debug_flag);
}

bool sim_get_debug_flag (sim_t *sim, int debug_flag)
{
  return ((sim->debug_flags & (1 << debug_flag)) != 0);
}

#endif /* HAS_DEBUGGER */


extern processor_dispatch_t classic_processor;
extern processor_dispatch_t woodstock_processor;
extern processor_dispatch_t nut_processor;

processor_dispatch_t *processor_dispatch [ARCH_MAX] =
  {
    [ARCH_UNKNOWN]   = NULL,
    [ARCH_CLASSIC]   = & classic_processor,
    [ARCH_WOODSTOCK] = & woodstock_processor,
    [ARCH_CRICKET]   = NULL,
    [ARCH_NUT]       = & nut_processor,
    [ARCH_CAPRICORN] = NULL,
    [ARCH_SATURN]    = NULL
  };
