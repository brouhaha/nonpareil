/*
$Id$
Copyright 1995, 2004, 2005 Eric L. Smith <eric@brouhaha.com>

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


#include <inttypes.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <gdk/gdk.h>
#include <gtk/gtk.h>

#include "util.h"
#include "display.h"
#include "proc.h"


static sim_t *dsim;  // $$$ ugly!

static GtkWidget *reg_window;
static gboolean reg_visible;
static int max_reg;
#define MAX_REG 200
static int reg_width [MAX_REG];
static GtkWidget *reg_widget [MAX_REG];
static reg_info_t *reg_info [MAX_REG];


static void binary_to_string (char *buf, int bits, uint64_t val)
{
  int i;

  for (i = bits - 1; i >= 0; i--)
    *(buf++) = (val & (1ull << i)) ? '1' : '0';
  *(buf++) = '\0';
}


static void update_register_window (void)
{
  int reg_num;
  char buf [80];
  uint64_t val;

  for (reg_num = 0; reg_num < max_reg; reg_num++)
    {
      reg_info_t *info = reg_info [reg_num];
      if (sim_read_register (dsim,
			     0,  // $$$ CPU only for now
			     reg_num,
			     0,
			     & val))
	{
	  if (info->display_radix == 16)
	    snprintf (buf, sizeof (buf), "%0*" PRIx64, reg_width [reg_num], val);
	  else if (info->display_radix == 10)
	    snprintf (buf, sizeof (buf), "%0*" PRIu64, reg_width [reg_num], val);
	  else if (info->display_radix == 8)
	    snprintf (buf, sizeof (buf), "%0*" PRIo64, reg_width [reg_num], val);
	  else // binary
	    binary_to_string (buf, reg_info [reg_num]->element_bits, val);
	}
      else
	snprintf (buf, sizeof (buf), "err");
      if ((info->display_radix == 2) && (info->element_bits == 1))
	gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (reg_widget [reg_num]), val);
      else
	gtk_entry_set_text (GTK_ENTRY (reg_widget [reg_num]), buf);
    }
}


static int log2tab [17] =
  { 1, 1, 1, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4  };


static bool debug_window_add_register (GtkWidget *table, int reg_num)
{
  int l2radix;
  GtkWidget *hbox;
  int i;
  reg_info_t *r;

  r = sim_get_register_info (dsim,
			     0,  // $$$ CPU only for now
			     reg_num);
  if (! r)
    return false;
  reg_info [reg_num] = r;

  gtk_table_attach_defaults (GTK_TABLE (table),
			     gtk_label_new (r->name),
			     0,
			     1,
			     reg_num,
			     reg_num + 1);

  l2radix = log2tab [r->display_radix];

  reg_width [reg_num] = (r->element_bits + l2radix - 1) / l2radix;

  hbox = gtk_hbox_new (FALSE, 1);

  for (i = 0; i < r->array_element_count; i++)
    {
      GtkWidget *w;
      if ((r->display_radix == 2) && (r->element_bits == 1))
	w = gtk_check_button_new ();
      else
	w = gtk_entry_new_with_max_length (reg_width [reg_num]);
      if (i == 0)
	reg_widget [reg_num] = w;
      gtk_box_pack_start (GTK_BOX (hbox), w, FALSE, TRUE, 0);
    }

  gtk_table_attach_defaults (GTK_TABLE (table),
			     hbox,
			     1,
			     2,
			     reg_num,
			     reg_num + 1);
  return true;
}


static gboolean on_destroy_reg_window_event (GtkWidget *widget,
					     GdkEventAny *event)
{
  reg_visible = false;
  reg_window = NULL;
  return (FALSE);
}


void debug_show_reg (GtkWidget *widget, gpointer data)
{
  GtkWidget *table;
  int reg_num = 0;
  
  if (! reg_window)
    {
      reg_visible = false;
      reg_window = gtk_window_new (GTK_WINDOW_TOPLEVEL);
      gtk_window_set_title (GTK_WINDOW (reg_window), "registers");

      g_signal_connect (G_OBJECT (reg_window),
			"destroy",
			GTK_SIGNAL_FUNC (on_destroy_reg_window_event),
			NULL);

      table = gtk_table_new (1, 2, FALSE);
      gtk_container_add (GTK_CONTAINER (reg_window), table);
      while (debug_window_add_register (table, reg_num))
	reg_num++;
    }

  max_reg = reg_num;

  reg_visible = ! reg_visible;

  if (reg_visible)
    {
      update_register_window ();
      gtk_widget_show_all (reg_window);
    }
  else
    gtk_widget_hide (reg_window);
}


void debug_run (GtkWidget *widget, gpointer data)
{
  sim_start (dsim);
}


void debug_step (GtkWidget *widget, gpointer data)
{
  sim_single_inst (dsim);
}


void debug_trace (GtkWidget *widget, gpointer data)
{
  sim_set_debug_flag (dsim, SIM_DEBUG_TRACE,
		      ! sim_get_debug_flag (dsim, SIM_DEBUG_TRACE));
}


void debug_key_trace (GtkWidget *widget, gpointer data)
{
  sim_set_debug_flag (dsim, SIM_DEBUG_KEY_TRACE,
		      ! sim_get_debug_flag (dsim, SIM_DEBUG_KEY_TRACE));
}


void debug_ram_trace (GtkWidget *widget, gpointer data)
{
  sim_set_debug_flag (dsim, SIM_DEBUG_RAM_TRACE,
		      ! sim_get_debug_flag (dsim, SIM_DEBUG_RAM_TRACE));
}


void init_debugger_gui (sim_t *sim)
{
  dsim = sim;  // $$$ ugly!
}
