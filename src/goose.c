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
#include <stdlib.h>

#include <gdk/gdk.h>
#include <gtk/gtk.h>

#include "util.h"
#include "sound.h"
#include "pixbuf_util.h"

#include "canada_goose_wav.h"
#include "rgoose_png.h"
#include "lgoose_png.h"


typedef struct
{
  int  positions;
  int  position;
  bool backward;
  GtkWidget *event_box [2];
  GtkWidget *table;
  guint timeout_source_id;
} goose_t;


static void *canada_goose_sample_ptr;
static size_t canada_goose_sample_len;


static void fly_goose (goose_t *goose, bool move, bool reverse)
{
  if (goose->position >= 0)
    gtk_container_remove (GTK_CONTAINER (goose->table),
			  goose->event_box [goose->backward]);

  if (reverse)
    goose->backward ^= 1;

  if (move)
    {
      if (goose->backward)
	{
	  if ((--goose->position) < 0)
	    goose->position = goose->positions - 1;
	}
      else
	{
	  if ((++goose->position) >= goose->positions)
	    goose->position = 0;
	}
    }

  gtk_table_attach (GTK_TABLE (goose->table), // table
		    goose->event_box [goose->backward], // child
		    goose->position,          // left_attach
		    goose->position + 1,      // right_attach
		    0,                        // top_attach
		    1,                        // bottom_attach
		    GTK_FILL,                 // xoptions
		    GTK_FILL,                 // yoptions
		    0,                        // xpadding
		    0);                       // ypadding
}


static void goose_click_callback (GtkWidget *widget     UNUSED,
				  GdkEventButton *event UNUSED,
				  gpointer data)
{
  goose_t *goose = data;

  fly_goose (goose, false, true);
  if (canada_goose_sample_ptr)
    play_sound (canada_goose_sample_ptr, canada_goose_sample_len, false);
}


static gboolean goose_timeout_callback (gpointer data)
{
  goose_t *goose = data;

  fly_goose (goose, true, false);
  return TRUE;
}



static GtkWidget *init_goose_from_image (const uint8_t *p, size_t size)
{
  GdkPixbuf *pixbuf;
  GtkWidget *image;
  GtkWidget *event_box;

  pixbuf = new_pixbuf_from_png_array (p, size);

  image = gtk_image_new_from_pixbuf (pixbuf);
  gtk_widget_show (image);

  event_box = gtk_event_box_new();
  gtk_container_add (GTK_CONTAINER (event_box), image);
  gtk_widget_show (event_box);
  g_object_ref (event_box);

  return event_box;
}


static void init_goose_sound (void)
{
  if (! canada_goose_sample_ptr)
    (void) prepare_samples_from_wav_data (canada_goose_wav,
					  canada_goose_wav_size,
					  & canada_goose_sample_ptr,
					  & canada_goose_sample_len);
}


static void destroy_goose (gpointer data)
{
  goose_t *goose = data;
  int i;

  g_source_remove (goose->timeout_source_id);

  for (i = 0; i < 2; i++)
    g_object_unref (goose->event_box [i]);

  free (goose);
}


GtkWidget *new_goose (int positions)
{
  int i;
  goose_t *goose;

  init_goose_sound ();

  goose = alloc (sizeof (goose_t));

  goose->positions = positions;
  goose->position = -1;
  goose->backward = false;

  goose->table = gtk_table_new (1, positions, TRUE);
  gtk_widget_show (goose->table);

  g_object_set_data_full (G_OBJECT (goose->table), "goose", goose, destroy_goose);

  goose->event_box [0] = init_goose_from_image (rgoose_png, rgoose_png_size);

  goose->event_box [1] = init_goose_from_image (lgoose_png, lgoose_png_size);

  for (i = 0; i < 2; i++)
    g_signal_connect (G_OBJECT (goose->event_box [i]),
		      "button_press_event",
		      G_CALLBACK (goose_click_callback),
		      goose);

  fly_goose (goose, true, false);

  goose->timeout_source_id = g_timeout_add (250,
					    goose_timeout_callback,
					    goose);

  return goose->table;
}
