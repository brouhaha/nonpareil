/*
$Id$
Copyright 2004, 2005, 2006 Eric L. Smith <eric@brouhaha.com>

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

#include <gdk/gdk.h>
#include <gtk/gtk.h>

#include <gsf/gsf-infile.h>

#include "util.h"
#include "pixbuf_util.h"
#include "display.h"
#include "kml.h"
#include "goose.h"

#include "nonpareil_title_png.h"
#include "gpl_v2_txt.h"


static char *credits_people [] =
{
  "Maciej Bartosiak",
  "Timothee Basset",
  "Les Bell",
  "Paul Davis",
  "Bob Edelen",
  "Mike Elkins",
  "Steven Ellis",
  "Florian Engelhardt",
  "Bernhard Engl",
  "Christoph Gie\u00dfelink",
  "Christophe Gottheimer",
  "Warren Furlow",
  "David Hicks",
  "John Hogerhuis",
  "HrastProgrammer",
  "Steven Knight",
  "Allen Kossow",
  "Wlodek Mier-J\u0119drzejowicz",
  "Peter Monta",
  "Richard Nelson",
  "Thomas Olesen",
  "Richard Ottosen",
  "Howard Owen",
  "Jim Phillips",
  "Tony Phillips",
  "Hedley Rainnie",
  "Chris Rocatti",
  "Adam Sampson",
  "Jake Schwartz",
  "Nelson Sicuro",
  "Randy Sloyer",
  "Kenneth Sumrall",
};


static GtkWidget *intro_page (kml_t *kml)
{
  GtkWidget *vbox;

  vbox = gtk_vbox_new (FALSE, 0);

  gtk_box_pack_start (GTK_BOX (vbox),
		      gtk_label_new ("Nonpareil achieves high simulation fidelity by simulating\n"
				     "the actual processor architectures that were used in the\n"
				     "original calculators, and running identical or very slightly\n"
				     "modified calculator firmware."),
		      FALSE,  // expand
		      FALSE,  // fill
		      0);     // padding

  if (kml && (kml->title || kml->author))
    {
      gtk_container_add (GTK_CONTAINER (vbox),
			 gtk_hseparator_new ());
      gtk_container_add (GTK_CONTAINER (vbox),
			 gtk_label_new ("KML:"));
      if (kml->title)
	gtk_container_add (GTK_CONTAINER (vbox),
			   gtk_label_new (kml->title));
      if (kml->author)
	gtk_container_add (GTK_CONTAINER (vbox),
			   gtk_label_new (kml->author));
    }

  if (kml && kml->image_cr)
    {
      gtk_container_add (GTK_CONTAINER (vbox),
			 gtk_hseparator_new ());
      gtk_container_add (GTK_CONTAINER (vbox),
			 gtk_label_new ("Images by:"));
      gtk_container_add (GTK_CONTAINER (vbox),
			 gtk_label_new (kml->image_cr));
    }

  return vbox;
}


#define CREDITS_COLUMNS 3

static GtkWidget *credits_page (void)
{
  GtkWidget *vbox;
  GtkWidget *table;
  int count;
  int rows;
  int row, column, index;

  vbox = gtk_vbox_new (FALSE, 0);

  gtk_box_pack_start (GTK_BOX (vbox),
		      gtk_label_new ("The Nonpareil project has received assistance and contributions from:"),
		      FALSE,  // expand
		      FALSE,  // fill
		      0);     // padding

  count = sizeof (credits_people) / sizeof (char *);
  rows = (count + CREDITS_COLUMNS - 1) / CREDITS_COLUMNS;

  table = gtk_table_new (rows + 2, CREDITS_COLUMNS, true);

  index = 0;
  for (column = 0; column < CREDITS_COLUMNS; column++)
    for (row = 0; row < rows; row++)
      if (index < count)
	gtk_table_attach_defaults (GTK_TABLE (table),
				   gtk_label_new (credits_people [index++]),
				   column,
				   column + 1,
				   row + 1,
				   row + 2);

  gtk_box_pack_start (GTK_BOX (vbox),
		      table,
		      FALSE,  // expand
		      FALSE,  // fill
		      0);     // padding

  gtk_box_pack_start (GTK_BOX (vbox),
		      gtk_label_new ("My apologies if I've forgotten to list anyone!"),
		      FALSE,  // expand
		      FALSE,  // fill
		      0);     // padding

  return vbox;
}


static GtkWidget *license_page (void)
{
  GtkWidget *vbox;
  GtkWidget *scrolled_window;
  GtkWidget *label;

  vbox = gtk_vbox_new (FALSE, 0);

  gtk_box_pack_start (GTK_BOX (vbox),
		      gtk_label_new ("Nonpareil is licensed under the terms of the Free Software\n"
				     "Foundation's General Public License:"),
		      FALSE,  // expand
		      FALSE,  // fill
		      0);     // padding

  scrolled_window = gtk_scrolled_window_new (NULL, NULL);

  label = gtk_label_new ("GPL v2");

  gtk_label_set_text (GTK_LABEL (label), gpl_v2_txt);

  gtk_scrolled_window_add_with_viewport (GTK_SCROLLED_WINDOW (scrolled_window),
					 label);

  gtk_box_pack_start (GTK_BOX (vbox),
		      scrolled_window,
		      TRUE,   // expand
		      TRUE,  // fill
		      0);     // padding

  return vbox;
}


void about_dialog (GtkWidget *main_window, kml_t *kml)
{
  GtkWidget *dialog;
  GtkWidget *notebook;
  GdkPixbuf *title_pixbuf;

  dialog = gtk_dialog_new_with_buttons ("About Nonpareil",
					GTK_WINDOW (main_window),
					GTK_DIALOG_MODAL | GTK_DIALOG_DESTROY_WITH_PARENT,
					GTK_STOCK_OK,
					GTK_RESPONSE_NONE,
					NULL);

  gtk_dialog_set_has_separator (GTK_DIALOG (dialog), TRUE);

  title_pixbuf = new_pixbuf_from_png_array (nonpareil_title_png,
					    nonpareil_title_png_size);

  gtk_container_add (GTK_CONTAINER (GTK_DIALOG (dialog)->vbox),
		     gtk_image_new_from_pixbuf (title_pixbuf));

  gtk_container_add (GTK_CONTAINER (GTK_DIALOG (dialog)->vbox),
		     gtk_label_new (nonpareil_release));

  gtk_container_add (GTK_CONTAINER (GTK_DIALOG (dialog)->vbox),
		     gtk_label_new ("High-fidelity calculator simulator\n"
				    "Copyright 1995, 2003, 2004, 2005 Eric L. Smith\n"
				    "http://nonpareil.brouhaha.com/"));

  notebook = gtk_notebook_new ();

  // I'd like to put the tabs on the left, but with the text rotated.
  // But this won't rotate the labels for me.
  //
  // gtk_notebook_set_tab_pos (GTK_NOTEBOOK (notebook),
  //			       GTK_POS_LEFT);

  gtk_notebook_append_page (GTK_NOTEBOOK (notebook),
			    intro_page (kml),
			    gtk_label_new ("Introduction"));

  gtk_notebook_append_page (GTK_NOTEBOOK (notebook),
			    credits_page (),
			    gtk_label_new ("Credits"));

  gtk_notebook_append_page (GTK_NOTEBOOK (notebook),
			    license_page (),
			    gtk_label_new ("License"));

  gtk_container_add (GTK_CONTAINER (GTK_DIALOG (dialog)->vbox),
		     notebook);

  gtk_container_add (GTK_CONTAINER (GTK_DIALOG (dialog)->vbox),
		     gtk_hseparator_new ());

  gtk_container_add (GTK_CONTAINER (GTK_DIALOG (dialog)->vbox),
		     new_goose (12));

  gtk_widget_show_all (dialog);

  gtk_dialog_run (GTK_DIALOG (dialog));
  gtk_widget_destroy (dialog);
}


