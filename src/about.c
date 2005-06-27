/*
$Id$
Copyright 2004, 2005 Eric L. Smith <eric@brouhaha.com>

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

#include "util.h"
#include "pixbuf_util.h"
#include "display.h"
#include "kml.h"
#include "goose.h"

#include "nonpareil_title_png.h"


static char *credits_people [] =
{
  "Maciej Bartosiak",
  "Timothee Basset",
  "Les Bell",
  "Paul Davis",
  "Bob Edelen",
  "Steven Elllis",
  "Florian Engelhardt",
  "Bernhard Engl",
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


#define CREDITS_COLUMNS 4

static void add_credits (GtkWidget *widget)
{
  GtkWidget *table;
  int count;
  int rows;
  int row, column, index;

  gtk_container_add (GTK_CONTAINER (widget),
		     gtk_label_new ("The Nonpareil project has received assistance and contributions from:"));

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

  gtk_container_add (GTK_CONTAINER (widget), table);

  gtk_container_add (GTK_CONTAINER (widget),
		     gtk_label_new ("My apologies if I've forgotten to list anyone!"));

}


void about_dialog (GtkWidget *main_window, kml_t *kml)
{
  GtkWidget *dialog;
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
		     gtk_label_new ("Microcode-level calculator simulator\n"
				    "Copyright 1995, 2003, 2004, 2005 Eric L. Smith\n"
				    "http://nonpareil.brouhaha.com/"));

  gtk_container_add (GTK_CONTAINER (GTK_DIALOG (dialog)->vbox),
		     gtk_hseparator_new ());

  add_credits (GTK_DIALOG (dialog)->vbox);

  if (kml && (kml->title || kml->author))
    {
      gtk_container_add (GTK_CONTAINER (GTK_DIALOG (dialog)->vbox),
			 gtk_hseparator_new ());
      gtk_container_add (GTK_CONTAINER (GTK_DIALOG (dialog)->vbox),
			 gtk_label_new ("KML:"));
      if (kml->title)
	gtk_container_add (GTK_CONTAINER (GTK_DIALOG (dialog)->vbox),
			   gtk_label_new (kml->title));
      if (kml->author)
	gtk_container_add (GTK_CONTAINER (GTK_DIALOG (dialog)->vbox),
			   gtk_label_new (kml->author));
    }

  gtk_container_add (GTK_CONTAINER (GTK_DIALOG (dialog)->vbox),
		     gtk_hseparator_new ());

  gtk_container_add (GTK_CONTAINER (GTK_DIALOG (dialog)->vbox),
		     new_goose (12));

  gtk_widget_show_all (dialog);

  gtk_dialog_run (GTK_DIALOG (dialog));
  gtk_widget_destroy (dialog);
}


