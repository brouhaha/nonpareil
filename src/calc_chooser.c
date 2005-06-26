/*
$Id$
Copyright 2005 Eric L. Smith <eric@brouhaha.com>

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
#include "calc_chooser.h"

#include "nonpareil_title_png.h"


char *calculator_chooser (char *path)
{
  GtkWidget *dialog;
  GtkWidget *file_chooser;
  GdkPixbuf *title_pixbuf;
  GtkFileFilter *kml_filter;
  gchar *f;
  char *fn = NULL;

  dialog = gtk_dialog_new_with_buttons ("Choose calculator model",
					NULL,
					0,  // flags
					GTK_STOCK_CANCEL, GTK_RESPONSE_CANCEL,
					GTK_STOCK_OPEN,   GTK_RESPONSE_ACCEPT,
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

  file_chooser = gtk_file_chooser_widget_new (GTK_FILE_CHOOSER_ACTION_OPEN);

  kml_filter = gtk_file_filter_new ();

  gtk_file_filter_add_pattern (kml_filter, "*.kml");

  gtk_file_chooser_set_filter (GTK_FILE_CHOOSER (file_chooser),
			       kml_filter);

  if (path)
    gtk_file_chooser_set_current_folder (GTK_FILE_CHOOSER (file_chooser),
					 path);

  gtk_container_add (GTK_CONTAINER (GTK_DIALOG (dialog)->vbox),
		     file_chooser);

  gtk_widget_show_all (dialog);

  switch (gtk_dialog_run (GTK_DIALOG (dialog)))
    {
    case GTK_RESPONSE_ACCEPT:
      f = gtk_file_chooser_get_filename (GTK_FILE_CHOOSER (file_chooser));
      fn = newstr (f);
      g_free (f);
      break;
    default:  // only other choise is GTK_RESPONSE_CANCEL
      break;
    }

  gtk_widget_destroy (dialog);

  return fn;
}

