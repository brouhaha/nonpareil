/*
$Id$
Copyright 1995, 2004, 2005, 2006 Eric L. Smith <eric@brouhaha.com>

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


static GtkWidget *reg_window;
static gboolean reg_window_visible;

#define MAX_REG 200

typedef struct
{
  sim_t *sim;
  chip_t *chip;
  int reg_num;
  const reg_info_t *info;
  int index;  // for arrays
  int width;
  GtkWidget *widget;
} reg_display_t;

static int max_reg;
static reg_display_t reg_display [MAX_REG];

static GtkWidget *ram_window;
static gboolean ram_visible;
static int max_ram;
#define MAX_RAM 1024
static GtkWidget *ram_widget [MAX_RAM];
static int ram_addr [MAX_RAM];


static void binary_to_string (char *buf, int bits, uint64_t val)
{
  int i;

  for (i = bits - 1; i >= 0; i--)
    *(buf++) = (val & (1ull << i)) ? '1' : '0';
  *(buf++) = '\0';
}


static void update_register_window (void)
{
  int i;
  char buf [80];
  uint64_t val;

  for (i = 0; i < max_reg; i++)
    {
      sim_t *sim = reg_display [i].sim;
      chip_t *chip = reg_display [i].chip;
      const reg_info_t *info = reg_display [i].info;

      if (sim_read_register (sim,
			     chip,
			     reg_display [i].reg_num,
			     reg_display [i].index,
			     & val))
	{
	  if (info->display_radix == 16)
	    snprintf (buf, sizeof (buf), "%0*" PRIx64, reg_display [i].width, val);
	  else if (info->display_radix == 10)
	    snprintf (buf, sizeof (buf), "%0*" PRIu64, reg_display [i].width, val);
	  else if (info->display_radix == 8)
	    snprintf (buf, sizeof (buf), "%0*" PRIo64, reg_display [i].width, val);
	  else // binary
	    binary_to_string (buf, reg_display [i].info->element_bits, val);
	}
      else
	snprintf (buf, sizeof (buf), "err");
      if ((info->display_radix == 2) && (info->element_bits == 1))
	gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (reg_display [i].widget), val);
      else
	gtk_entry_set_text (GTK_ENTRY (reg_display [i].widget), buf);
    }
}


static int log2tab [17] =
  { 1, 1, 1, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4  };


static bool debug_window_add_register (sim_t *sim,
				       chip_t *chip,
				       int reg_num,
				       GtkWidget *table)
{
  const reg_info_t *r;
  int index;
  int l2radix, width;
  char reg_name [80];

  r = sim_get_register_info (sim, chip, reg_num);
  if (! r)
    return false;

  l2radix = log2tab [r->display_radix];
  width = (r->element_bits + l2radix - 1) / l2radix;

  for (index = 0; index < r->array_element_count; index++)
    {
      reg_display [max_reg].sim = sim;
      reg_display [max_reg].chip = chip;
      reg_display [max_reg].reg_num = reg_num;
      reg_display [max_reg].info = r;
      reg_display [max_reg].index = index;
      reg_display [max_reg].width = width;

      if (r->array_element_count > 1)
	sprintf (reg_name, "%s [%d]", r->name, index);
      else
	sprintf (reg_name, "%s", r->name);

      gtk_table_attach_defaults (GTK_TABLE (table),
				 gtk_label_new (reg_name),
				 0,
				 1,
				 max_reg,
				 max_reg + 1);

      if ((r->display_radix == 2) && (r->element_bits == 1))
	reg_display [max_reg].widget = gtk_check_button_new ();
      else
	reg_display [max_reg].widget = gtk_entry_new_with_max_length (width);

      gtk_table_attach_defaults (GTK_TABLE (table),
				 reg_display [max_reg].widget,
				 1,
				 2,
				 max_reg,
				 max_reg + 1);

      max_reg++;
    }


  return true;
}


static gboolean on_destroy_reg_window_event (GtkWidget *widget,
					     GdkEventAny *event)
{
  reg_window_visible = false;
  reg_window = NULL;
  return (FALSE);
}


void debug_add_reg_chip (sim_t *sim,
			 chip_t *chip,
			 GtkWidget *table)
{
  int reg_num = 0;

  while (debug_window_add_register (sim, chip, reg_num, table))
    reg_num++;
}


void debug_add_reg_all_chips (sim_t *sim,
			      GtkWidget *notebook)
{
  GtkWidget *table;
  GtkWidget *scrolled_window;
  chip_t *chip = NULL;
  const chip_info_t *chip_info;

  while ((chip = sim_get_next_chip (sim, chip)))
    {
      chip_info = sim_get_chip_info (sim, chip);

      table = gtk_table_new (1, 2, FALSE);

      scrolled_window = gtk_scrolled_window_new (NULL, NULL);

      gtk_scrolled_window_add_with_viewport (GTK_SCROLLED_WINDOW (scrolled_window),
					     table);
      
      gtk_notebook_append_page (GTK_NOTEBOOK (notebook),
				scrolled_window,
				gtk_label_new (chip_info->name));

      debug_add_reg_chip (sim, chip, table);
    }
}
			  


static sim_t *dg_sim;  // $$$ ugly!


void debug_show_reg  (gpointer callback_data,
		      guint    callback_action,
		      GtkWidget *widget)
{
  GtkWidget *notebook;
  
  if (! reg_window)
    {
      reg_window_visible = false;
      reg_window = gtk_window_new (GTK_WINDOW_TOPLEVEL);
      gtk_window_set_title (GTK_WINDOW (reg_window), "registers");

      g_signal_connect (G_OBJECT (reg_window),
			"destroy",
			GTK_SIGNAL_FUNC (on_destroy_reg_window_event),
			NULL);

      notebook = gtk_notebook_new ();

      gtk_container_add (GTK_CONTAINER (reg_window), notebook);

      max_reg = 0;

      debug_add_reg_all_chips (dg_sim, notebook);
    }

  reg_window_visible = ! reg_window_visible;

  if (reg_window_visible)
    {
      update_register_window ();
      gtk_widget_show_all (reg_window);
    }
  else
    gtk_widget_hide (reg_window);
}


static void update_ram_window (void)
{
  int index;
  char buf [15];
  uint64_t val;

  for (index = 0; index < max_ram; index++)
    {
      if (sim_read_ram (dg_sim, ram_addr [index], & val))
	snprintf (buf, sizeof (buf), "%014" PRIx64, val);
      else
	snprintf (buf, sizeof (buf), "err");
      gtk_entry_set_text (GTK_ENTRY (ram_widget [index]), buf);
    }
}


static bool debug_window_add_ram (GtkWidget *table, int addr)
{
  char addr_str [4];

  ram_addr [max_ram] = addr;

  sprintf (addr_str, "%03x", addr);

  gtk_table_attach_defaults (GTK_TABLE (table),
			     gtk_label_new (addr_str),
			     0,
			     1,
			     max_ram,
			     max_ram + 1);

  ram_widget [max_ram] = gtk_entry_new_with_max_length (14);

  gtk_table_attach_defaults (GTK_TABLE (table),
			     ram_widget [max_ram],
			     1,
			     2,
			     max_ram,
			     max_ram + 1);

  max_ram++;

  return true;
}


static gboolean on_destroy_ram_window_event (GtkWidget *widget,
					     GdkEventAny *event)
{
  ram_visible = false;
  ram_window = NULL;
  return (FALSE);
}


void debug_show_ram  (gpointer callback_data,
		      guint    callback_action,
		      GtkWidget *widget)
{
  GtkWidget *table;
  GtkWidget *scrolled_window;
  int addr = 0;
  int limit;
  uint64_t val;
  
  if (! ram_window)
    {
      max_ram = 0;
      ram_visible = false;
      ram_window = gtk_window_new (GTK_WINDOW_TOPLEVEL);
      gtk_window_set_title (GTK_WINDOW (ram_window), "RAM");

      g_signal_connect (G_OBJECT (ram_window),
			"destroy",
			GTK_SIGNAL_FUNC (on_destroy_ram_window_event),
			NULL);

      table = gtk_table_new (1, 2, FALSE);

      scrolled_window = gtk_scrolled_window_new (NULL, NULL);

      gtk_scrolled_window_add_with_viewport (GTK_SCROLLED_WINDOW (scrolled_window), table);

      gtk_container_add (GTK_CONTAINER (ram_window), scrolled_window);

      limit = sim_get_max_ram (dg_sim);
      for (addr = 0; addr < limit; addr++)
	if (sim_read_ram (dg_sim, addr, & val))
	  debug_window_add_ram (table, addr);
    }

  ram_visible = ! ram_visible;

  if (ram_visible)
    {
      update_ram_window ();
      gtk_widget_show_all (ram_window);
    }
  else
    gtk_widget_hide (ram_window);
}


void debug_run       (gpointer callback_data,
		      guint    callback_action,
		      GtkWidget *widget)
{
  sim_start (dg_sim);
}


void debug_step      (gpointer callback_data,
		      guint    callback_action,
		      GtkWidget *widget)
{
  sim_single_inst (dg_sim);
}


void debug_trace     (gpointer callback_data,
		      guint    callback_action,
		      GtkWidget *widget)
{
  sim_set_debug_flag (dg_sim, SIM_DEBUG_TRACE,
		      ! sim_get_debug_flag (dg_sim, SIM_DEBUG_TRACE));
}


void debug_key_trace (gpointer callback_data,
		      guint    callback_action,
		      GtkWidget *widget)
{
  sim_set_debug_flag (dg_sim, SIM_DEBUG_KEY_TRACE,
		      ! sim_get_debug_flag (dg_sim, SIM_DEBUG_KEY_TRACE));
}


void debug_ram_trace (gpointer callback_data,
		      guint    callback_action,
		      GtkWidget *widget)
{
  sim_set_debug_flag (dg_sim, SIM_DEBUG_RAM_TRACE,
		      ! sim_get_debug_flag (dg_sim, SIM_DEBUG_RAM_TRACE));
}


void init_debugger_gui (sim_t *sim)
{
  dg_sim = sim;  // $$$ ugly!
}
