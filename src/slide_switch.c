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
#include "printer.h"
#include "kml.h"
#include "proc.h"
#include "slide_switch.h"


typedef struct
{
  sim_t *sim;
  GtkWidget *widget [KML_MAX_SWITCH_POSITION];
  GtkWidget *image [KML_MAX_SWITCH_POSITION];
  GtkWidget *fixed;
  kml_switch_t *kml_switch;
  int flag [KML_MAX_SWITCH_POSITION];
} slide_switch_info_t;


static void slide_switch_toggled (GtkWidget *widget, slide_switch_info_t *sw)
{
  int pos;
  gboolean state;

  for (pos = 0; pos < KML_MAX_SWITCH_POSITION; pos++)
    {
      if (widget == sw->widget [pos])
	break;
    }
  if (pos >= KML_MAX_SWITCH_POSITION)
    fatal (2, "can't find switch position\n");

  state = gtk_toggle_button_get_active (GTK_TOGGLE_BUTTON (widget));

  if (sw->flag [pos])
    sim_set_ext_flag (sw->sim, sw->flag [pos], state);
}


static void add_slide_switch (sim_t *sim,
			      kml_t *kml,
			      GtkWidget *fixed,
			      GdkPixbuf *window_pixbuf,
			      kml_switch_t *kml_switch,
			      slide_switch_info_t *slide_switch_info)
{
  int i;
  GSList *group = NULL;

  slide_switch_info->sim = sim;
  slide_switch_info->fixed = fixed;
  slide_switch_info->kml_switch = kml_switch;
  
  for (i = 0; i < KML_MAX_SWITCH_POSITION; i++)
    if (kml_switch->position [i])
      {
	slide_switch_info->flag [i] = kml_switch->position [i]->flag;
	slide_switch_info->widget [i] = gtk_radio_button_new (group);

	group = gtk_radio_button_get_group (GTK_RADIO_BUTTON (slide_switch_info->widget [i]));

	/* Though it's a radio button, don't display it as one! */
	gtk_toggle_button_set_mode (GTK_TOGGLE_BUTTON (slide_switch_info->widget [i]),
				    FALSE);


	gtk_button_set_relief (GTK_BUTTON (slide_switch_info->widget [i]),
			       GTK_RELIEF_NONE);
	gtk_widget_set_size_request (slide_switch_info->widget [i],
				     kml_switch->size.width,
				     kml_switch->size.height);

	gtk_fixed_put (GTK_FIXED (fixed),
		       slide_switch_info->widget [i],
		       kml_switch->position [i]->offset.x - kml->background_offset.x,
		       kml_switch->position [i]->offset.y - kml->background_offset.y);

	if (i == kml_switch->default_position)
	  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (slide_switch_info->widget [i]),
					TRUE);

	g_signal_connect (G_OBJECT (slide_switch_info->widget [i]),
			  "toggled",
			  G_CALLBACK (& slide_switch_toggled),
			  (gpointer) slide_switch_info);
      }
}


static slide_switch_info_t *slide_switch_info [KML_MAX_SWITCH];


void add_slide_switches (sim_t *sim,
			 kml_t *kml,
			 GdkPixbuf *window_pixbuf,
			 GtkWidget *fixed)
{
  int i;

  for (i = 0; i < KML_MAX_SWITCH; i++)
    if (kml->kswitch [i])
      {
	slide_switch_info [i] = alloc (sizeof (slide_switch_info_t));
	add_slide_switch (sim,
			  kml,
			  fixed,
			  window_pixbuf,
			  kml->kswitch [i],
			  slide_switch_info [i]);
      }
}


static void init_slide_switch (slide_switch_info_t *sw)
{
  int pos;
  gboolean state;

  for (pos = 0; pos < KML_MAX_SWITCH_POSITION; pos++)
    if (sw->flag [pos])
      {
	state = gtk_toggle_button_get_active (GTK_TOGGLE_BUTTON (sw->widget [pos]));
	sim_set_ext_flag (sw->sim, sw->flag [pos], state);
      }
}


void init_slide_switches (void)
{
  int i;

  for (i = 0; i < KML_MAX_SWITCH; i++)
    if (slide_switch_info [i])
      init_slide_switch (slide_switch_info [i]);
}


void set_slide_switch_position (int number, int position)
{
  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (slide_switch_info [number]->widget [position]), TRUE);
  init_slide_switch (slide_switch_info [number]);
}


bool get_slide_switch_position (int number, int *position)
{
  int i;

  if (! slide_switch_info [number])
    return false;
  for (i = 0; i < KML_MAX_SWITCH_POSITION; i++)
    {
      slide_switch_info_t *sw = slide_switch_info [number];
      if (sw->widget [i] &&
	  gtk_toggle_button_get_active (GTK_TOGGLE_BUTTON (sw->widget [i])))
	{
	  *position = i;
	  return true;
	}
    }
  fatal (3, "Can't find active slide switch position\n");
}
