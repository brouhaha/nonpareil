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
#include <stdlib.h>
#include <string.h>

#include <gdk/gdk.h>
#include <gtk/gtk.h>

#include <gsf/gsf-infile.h>

#include "util.h"
#include "display.h"
#include "kml.h"
#include "chip.h"
#include "proc.h"
#include "crc.h"


typedef struct
{
  sim_t *sim;
  chip_t *chip;

  uint32_t config_flags;

  crc_card_side_t *side;  // active card side, NULL if none inserted
  FILE *f;                // file card came from

  GtkWidget *window;
  GtkWidget *insert_button;
  GtkWidget *insert_new_button;
} gui_card_reader_t;


static void gui_card_reader_set_button_state (gui_card_reader_t *cr,
					      bool state)
{
  gtk_widget_set_sensitive (cr->insert_button, state);
  gtk_widget_set_sensitive (cr->insert_new_button, state);
}


void gui_card_reader_update (sim_t  *sim  UNUSED,
			     chip_t *chip UNUSED,
			     void   *ref,
			     void   *data)
{
  gui_card_reader_t *cr = ref;
  int i;

  if (data != cr->side)
    fatal (3, "card reader returned different card side!\n");

  if (cr->side->dirty)
    {
      cr->side->dirty = false;  // shouldn't be set in file
      rewind (cr->f);
      if (fwrite (cr->side, sizeof (crc_card_side_t), 1, cr->f) != 1)
	fatal (3, "error writing card file\n");
    }
  fclose (cr->f);
  cr->f = NULL;

  free (cr->side);
  cr->side = NULL;

  gui_card_reader_set_button_state (cr, true);
}


static void insert_card (gui_card_reader_t *cr,
			 char *fn,
			 bool new_card)
{
  if (cr->side)
    fatal (3, "card inserted while card reader busy\n");

  cr->f = fopen (fn, new_card ? "w+b" : "r+b");
  g_free (fn);
  if (! cr->f)
    fatal (3, "error opening card file\n");

  cr->side = alloc (sizeof (crc_card_side_t));

  if (! new_card)
    {
      if (fread (cr->side, sizeof (crc_card_side_t), 1, cr->f) != 1)
	fatal (3, "error reading card file\n");
      cr->side->dirty = false;  // shouldn't be set in file
    }

  sim_event (cr->sim,
	     cr->chip,
	     event_crc_card_inserted,
	     0,  // arg1
	     0,  // arg2,
	     cr->side);
}


static void gui_card_reader_insert_card (GtkWidget *widget UNUSED,
					 gpointer data)
{
  gui_card_reader_t *cr = data;
  char *fn;
  GtkWidget *dialog;

  dialog = gtk_file_chooser_dialog_new ("Insert card side file",
					GTK_WINDOW (cr->window),
					GTK_FILE_CHOOSER_ACTION_OPEN,
					GTK_STOCK_CANCEL,
					GTK_RESPONSE_CANCEL,
					GTK_STOCK_OPEN,
					GTK_RESPONSE_ACCEPT,
					NULL);

  if (gtk_dialog_run (GTK_DIALOG (dialog)) != GTK_RESPONSE_ACCEPT)
    return;

  fn = gtk_file_chooser_get_filename (GTK_FILE_CHOOSER (dialog));
  gtk_widget_destroy (dialog);

  gui_card_reader_set_button_state (cr, false);
  insert_card (cr, fn, false);
}

static void gui_card_reader_insert_new_card (GtkWidget *widget UNUSED,
					     gpointer data)
{
  gui_card_reader_t *cr = data;
  char *fn;
  GtkWidget *dialog;

  dialog = gtk_file_chooser_dialog_new ("Create new card side file",
					GTK_WINDOW (cr->window),
					GTK_FILE_CHOOSER_ACTION_SAVE,
					GTK_STOCK_CANCEL,
					GTK_RESPONSE_CANCEL,
					GTK_STOCK_SAVE,
					GTK_RESPONSE_ACCEPT,
					NULL);

  if (gtk_dialog_run (GTK_DIALOG (dialog)) != GTK_RESPONSE_ACCEPT)
    return;

  fn = gtk_file_chooser_get_filename (GTK_FILE_CHOOSER (dialog));
  gtk_widget_destroy (dialog);

  gui_card_reader_set_button_state (cr, false);
  insert_card (cr, fn, true);
}


chip_t *gui_card_reader_install (sim_t *sim,
				 chip_type_t type,
				 int32_t index,
				 int32_t flags)
{
  gui_card_reader_t *cr;
  GtkWidget *box;

  cr = alloc (sizeof (gui_card_reader_t));

  cr->sim = sim;
  cr->config_flags = flags;

  cr->chip = sim_add_chip (sim,
			   type,                    // chip_type
			   index,                   // index
			   flags,                   // flags
			   gui_card_reader_update,  // callback_fn
			   cr);                     // ref
  if (! cr->chip)
    {
      warning ("can't add %s chip\n", get_chip_type_info (type));
      return NULL;
    }

  cr->window = gtk_window_new (GTK_WINDOW_TOPLEVEL);
  box = gtk_hbox_new (FALSE, 0);

  cr->insert_button = gtk_button_new_with_label ("Insert card...");
  g_signal_connect (G_OBJECT (cr->insert_button),
		    "clicked",
		    G_CALLBACK (gui_card_reader_insert_card),
		    cr);
  gtk_box_pack_start (GTK_BOX (box), cr->insert_button, FALSE, FALSE, 0);

  cr->insert_new_button = gtk_button_new_with_label ("Insert new card");
  g_signal_connect (G_OBJECT (cr->insert_new_button),
		    "clicked",
		    G_CALLBACK (gui_card_reader_insert_new_card),
		    cr);
  gtk_box_pack_start (GTK_BOX (box), cr->insert_new_button, FALSE, FALSE, 0);
  gtk_container_add (GTK_CONTAINER (cr->window), box);

  gtk_window_set_title (GTK_WINDOW (cr->window), "Card Reader");
  gtk_widget_show_all (cr->window);

  return (cr->chip);
}
