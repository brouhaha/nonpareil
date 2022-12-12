/*
Copyright 1995-2022 Eric Smith <spacewar@gmail.com>

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
#include "keyboard.h"
#include "kml.h"
#include "chip.h"
#include "calcdef.h"
#include "proc.h"
#include "csim.h"
#include "cbutton.h"


typedef struct
{
  struct gui_switches_t *switches;
  int switch_number;
  int max_position;
  GdkPixbuf *pixbuf [KML_MAX_SWITCH_POSITION];
  GtkWidget *widget;
  kml_switch_t *kml_switch;
} slide_switch_info_t;


struct gui_switches_t
{
  csim_t *csim;
  slide_switch_info_t *slide_switch_info [KML_MAX_SWITCH];
};


static void slide_switch_clicked (GtkWidget *widget, slide_switch_info_t *si)
{
  int pos;

  pos = cbutton_get_shift_state (CBUTTON (widget));

  if ((++pos) > si->max_position)
    pos = 0;

  sim_set_switch (si->switches->csim->sim, si->switch_number, pos);
  cbutton_set_shift_state (CBUTTON (widget), pos);
}


static void add_slide_switch (gui_switches_t *switches, int i)
{
  slide_switch_info_t *si;
  int pos;
  kml_switch_t *ks;

  ks = switches->csim->kml->kswitch [i];

  si = alloc (sizeof (slide_switch_info_t));
  switches->slide_switch_info [i] = si;

  si->switches = switches;
  si->switch_number = i;
  si->max_position = -1;
  si->widget = cbutton_new ();

  for (pos = 0; pos < KML_MAX_SWITCH_POSITION; pos++)
    if (ks->position [pos])
      {
	si->max_position = pos;

	// should handle case with no image_fn (use subpixbuf of base image)
	si->pixbuf [pos] = load_pixbuf_scaled (switches->csim,
					       ks->position [pos]->image_fn);

	cbutton_set_pixbuf (CBUTTON (si->widget),
			    pos,
			    si->pixbuf [pos]);
      }

  sim_set_switch (switches->csim->sim, i, ks->default_position);
  cbutton_set_shift_state (CBUTTON (si->widget),
			   ks->default_position);

  gtk_fixed_put (GTK_FIXED (switches->csim->fixed),
		 si->widget,
		 ks->offset.x - switches->csim->kml->background_offset.x,
		 ks->offset.y - switches->csim->kml->background_offset.y);

  g_signal_connect (G_OBJECT (si->widget),
		    "clicked",
		    G_CALLBACK (& slide_switch_clicked),
		    (gpointer) si);
}



gui_switches_t *gui_switches_init (csim_t *csim)
{
  gui_switches_t *switches;
  int i;

  switches = alloc (sizeof (gui_switches_t));
  switches->csim = csim;

  for (i = 0; i < KML_MAX_SWITCH; i++)
    if (csim->kml->kswitch [i])
      add_slide_switch (switches, i);
  return switches;
}


// set the GUI switch state to match the simulation switch state
void gui_slide_switches_update_from_sim (gui_switches_t *s)
{
  int i;
  uint8_t position;

  for (i = 0; i < KML_MAX_SWITCH; i++)
    {
      slide_switch_info_t *si = s->slide_switch_info [i];
      if (si && sim_get_switch (s->csim->sim, i, & position))
	cbutton_set_shift_state (CBUTTON (si->widget), position);
    }
}


void set_slide_switch_position (gui_switches_t *s,
				int number,
				int position)
{
  if (! s->slide_switch_info [number])
    return;
  sim_set_switch (s->csim->sim, number, position);
  cbutton_set_shift_state (CBUTTON (s->slide_switch_info [number]->widget),
			   position);
}
