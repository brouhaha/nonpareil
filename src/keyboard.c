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


#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <gdk/gdk.h>
#include <gtk/gtk.h>

#include "util.h"
#include "display.h"
#include "kml.h"
#include "proc.h"
#include "keyboard.h"


typedef struct
{
  sim_t *sim;
  GtkWidget *widget;
  GtkWidget *fixed;
  kml_button_t *kml_button;
} button_info_t;


static void button_widget_pressed (GtkWidget *widget, button_info_t *button)
{
  sim_press_key (button->sim, button->kml_button->keycode);
#ifdef KEYBOARD_DEBUG
  printf ("pressed %d\n", button->kml_button->keycode);
#endif
}


static void button_widget_released (GtkWidget *widget, button_info_t *button)
{
  sim_release_key (button->sim);
#ifdef KEYBOARD_DEBUG
  printf ("released %d\n", button->kml_button->keycode);
#endif
}


static void add_key (sim_t *sim,
		     kml_t *kml,
		     GtkWidget *fixed,
		     GdkPixbuf *window_pixbuf,
		     kml_button_t *kml_button,
		     button_info_t *button_info)
{
  GdkPixbuf *button_pixbuf;
  GtkWidget *button_image;

  button_info->sim = sim;
  button_info->kml_button = kml_button;

  button_pixbuf = gdk_pixbuf_new_subpixbuf (window_pixbuf,
					    kml_button->offset.x - kml->background_offset.x,
					    kml_button->offset.y - kml->background_offset.y,
					    kml_button->size.width,
					    kml_button->size.height);

  button_image = gtk_image_new_from_pixbuf (button_pixbuf);

  button_info->fixed = fixed;
  
  button_info->widget = gtk_button_new ();

  gtk_button_set_relief (GTK_BUTTON (button_info->widget), GTK_RELIEF_NONE);

  gtk_widget_set_size_request (button_info->widget,
			       kml_button->size.width,
			       kml_button->size.height);

  gtk_fixed_put (GTK_FIXED (fixed),
		 button_info->widget,
		 kml_button->offset.x - kml->background_offset.x,
		 kml_button->offset.y - kml->background_offset.y);

  g_signal_connect (G_OBJECT (button_info->widget),
		    "pressed",
		    G_CALLBACK (& button_widget_pressed),
		    (gpointer) button_info);

  g_signal_connect (G_OBJECT (button_info->widget),
		    "released",
		    G_CALLBACK (& button_widget_released),
		    (gpointer) button_info);

  gtk_container_add (GTK_CONTAINER (button_info->widget), button_image);
}


static button_info_t *button_info [KML_MAX_BUTTON];


void add_keys (sim_t *sim,
	       kml_t *kml,
	       GdkPixbuf *window_pixbuf,
	       GtkWidget *fixed)
{
  int i;

  for (i = 0; i < KML_MAX_BUTTON; i++)
    if (kml->button [i])
      {
	button_info [i] = alloc (sizeof (button_info_t));
	add_key (sim,
		 kml,
		 fixed,
		 window_pixbuf,
		 kml->button [i],
		 button_info [i]);
      }
}


// Presses the specified key.  Returns false if key doesn't exist.
bool set_key_state (int keycode, bool pressed)
{
  if (! button_info [keycode])
    return false;
  if (pressed)
    button_widget_pressed (button_info [keycode]->widget,
			   button_info [keycode]);
  else
    button_widget_released (button_info [keycode]->widget,
			    button_info [keycode]);
  return true;
}
