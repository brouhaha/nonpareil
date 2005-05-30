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

#include "sound.h"
#include "pixbuf_util.h"


#include "canada_goose_wav.h"

#include "rgoose_png.h"
#include "lgoose_png.h"


static int goose_position;
static int goose_positions;
static bool goose_backward;
static GtkWidget *goose_table;
static GtkWidget *rgoose_image;
static GtkWidget *lgoose_image;
static GtkWidget *rgoose_event_box;
static GtkWidget *lgoose_event_box;



static void fly_goose (bool move, bool reverse)
{
  GtkWidget *goose_event_box;

  goose_event_box = goose_backward ? lgoose_event_box : rgoose_event_box;

  if (goose_position >= 0)
    gtk_container_remove (GTK_CONTAINER (goose_table), goose_event_box);

  if (reverse)
    {
      goose_backward ^= 1;
      goose_event_box = goose_backward ? lgoose_event_box : rgoose_event_box;
    }

  if (move)
    {
      if (goose_backward)
	{
	  if ((--goose_position) < 0)
	    goose_position = goose_positions - 1;
	}
      else
	{
	  if ((++goose_position) >= goose_positions)
	    goose_position = 0;
	}
    }

  gtk_table_attach (GTK_TABLE (goose_table),  // table
		    goose_event_box,          // child
		    goose_position,           // left_attach
		    goose_position + 1,       // right_attach
		    0,                        // top_attach
		    1,                        // bottom_attach
		    GTK_FILL,                 // xoptions
		    GTK_FILL,                 // yoptions
		    0,                        // xpadding
		    0);                       // ypadding
}


static void goose_click_callback (GtkWidget *widget,
				  GdkEventButton *event,
				  gpointer data)
{
  fly_goose (false, true);
  play_sound (canada_goose_wav, sizeof (canada_goose_wav));
}


GtkWidget *new_goose (int positions)
{
  GdkPixbuf *rgoose_pixbuf;
  GdkPixbuf *lgoose_pixbuf;

  goose_positions = positions;

  goose_table = gtk_table_new (1, positions, TRUE);

  gtk_widget_show (goose_table);

  rgoose_pixbuf = new_pixbuf_from_png_array (rgoose_png,
					     sizeof (rgoose_png));
  rgoose_image = gtk_image_new_from_pixbuf (rgoose_pixbuf);
  gtk_widget_show (rgoose_image);

  rgoose_event_box = gtk_event_box_new();
  gtk_container_add (GTK_CONTAINER (rgoose_event_box),
		     rgoose_image);
  gtk_widget_show (rgoose_event_box);
  g_object_ref (rgoose_event_box);

  g_signal_connect (G_OBJECT (rgoose_event_box),
		    "button_press_event",
		    G_CALLBACK (goose_click_callback),
		    NULL);


  lgoose_pixbuf = new_pixbuf_from_png_array (lgoose_png,
					     sizeof (lgoose_png));
  lgoose_image = gtk_image_new_from_pixbuf (lgoose_pixbuf);
  gtk_widget_show (lgoose_image);

  lgoose_event_box = gtk_event_box_new();
  gtk_container_add (GTK_CONTAINER (lgoose_event_box),
		     lgoose_image);
  gtk_widget_show (lgoose_event_box);
  g_object_ref (lgoose_event_box);

  g_signal_connect (G_OBJECT (lgoose_event_box),
		    "button_press_event",
		    G_CALLBACK (goose_click_callback),
		    NULL);

  goose_position = -1;
  goose_backward = false;
  fly_goose (true, false);

  return goose_table;
}
