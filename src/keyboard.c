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


struct button_info_t
{
  csim_t *csim;
  kml_button_t *kml_button;
  kml_size_t size;
  int number;  // 0..KML_MAX_BUTTON-1
  GtkWidget *widget;
  bool pressed;
};


// NOTE: keyboard rollover support needs to move into simulator core,
// as it is model-specific.  A general rollover framework should be
// implemented there.


// The real hardware has two-key rollover.  If one key is pressed, the
// hardware recognizes it immediately.  But if additional keys are
// pressed before the first key is released, none are recognized until
// all but one are released, and if all but the first one are released,
// the first one is not recognized a second time.


static void button_widget_pressed (GtkWidget *widget UNUSED,
				   button_info_t *button)
{
  csim_t *csim = button->csim;

  if (! button->pressed)
    {
      button->pressed = true;
      if (++csim->button_pressed_count == 1)
	{
#ifdef KEYBOARD_DEBUG
	  printf ("first button press, keycode %d\n", button->kml_button->user_keycode);
#endif
	  csim->button_pressed_first = button->kml_button->user_keycode;
	  sim_key (csim->sim, button->kml_button->user_keycode, true);
	}
#ifdef KEYBOARD_DEBUG
      else
	printf ("additional button press, keycode=%d\n", button->kml_button->user_keycode);
#endif
    }
}


static int find_pressed_button (csim_t *csim)
{
  int i;
  for (i = 0; i < KML_MAX_BUTTON; i++)
    if (csim->button_info [i] && csim->button_info [i]->pressed)
      return csim->button_info [i]->number;
  fatal (3, "keyboard rollover error\n");
}

static void button_widget_released (GtkWidget *widget UNUSED,
				    button_info_t *button)
{
  csim_t *csim = button->csim;
  int i;

  if (! button->pressed)
    return;  // should never happen

  button->pressed = false;
  switch (--csim->button_pressed_count)
    {
    case 0:
      // Released the last (or only) key that was pressed.
#ifdef KEYBOARD_DEBUG
      printf ("last key release, keycode=%d\n", button->kml_button->user_keycode);
#endif
      i = csim->button_pressed_first;
      sim_key (csim->sim, i, false);
      break;
    case 1:
      // There were multiple keys pressed, and all but one have been
      // released.  If that one was the first one pressed, do nothing,
      // but if it's a different one, release the first one and press then
      // last remaining one.
#ifdef KEYBOARD_DEBUG
      printf ("next-to-last key release, keycode=%d\n", button->kml_button->user_keycode);
#endif
      i = find_pressed_button (csim);
      if (i != csim->button_pressed_first)
	{
#ifdef KEYBOARD_DEBUG
	  printf ("rollover pressing keycode=%d\n", 
		  csim->button_info [i]->kml_button->user_keycode);
#endif
	  sim_key (csim->sim, csim->button_pressed_first, false);  // release the first one
	  csim->button_pressed_first = csim->button_info [i]->kml_button->user_keycode;
	  sim_key (csim->sim, csim->button_info [i]->kml_button->user_keycode, true);
	}
      break;
    default:
      // There are still at least two keys pressed.  Do nothing.
#ifdef KEYBOARD_DEBUG
      printf ("key release, keycode=%d\n", button->kml_button->user_keycode);
#endif
      break;
    }
}


static void add_key (csim_t *csim,
		     kml_button_t *kml_button,
		     int number,
		     button_info_t *button_info)
{
  GdkPixbuf *button_pixbuf;

  button_info->csim = csim;
  button_info->kml_button = kml_button;
  button_info->number = number;

  if (kml_button->image_fn)
    button_pixbuf = load_pixbuf_scaled (csim, kml_button->image_fn);
  else
    button_pixbuf = gdk_pixbuf_new_subpixbuf (csim->background_pixbuf,
					      kml_button->offset.x - csim->kml->background_offset.x,
					      kml_button->offset.y - csim->kml->background_offset.y,
					      kml_button->size.width,
					      kml_button->size.height);

  button_info->size.width  = gdk_pixbuf_get_width  (button_pixbuf);
  button_info->size.height = gdk_pixbuf_get_height (button_pixbuf);

  button_info->widget = cbutton_new ();
  cbutton_set_pixbuf (CBUTTON (button_info->widget),
		      0,  // shift_state
		      button_pixbuf);

  gtk_fixed_put (GTK_FIXED (csim->fixed),
		 button_info->widget,
		 kml_button->offset.x - csim->kml->background_offset.x,
		 kml_button->offset.y - csim->kml->background_offset.y);

  g_signal_connect (G_OBJECT (button_info->widget),
		    "pressed",
		    G_CALLBACK (& button_widget_pressed),
		    (gpointer) button_info);

  g_signal_connect (G_OBJECT (button_info->widget),
		    "released",
		    G_CALLBACK (& button_widget_released),
		    (gpointer) button_info);
}


void add_keys (csim_t *csim)
{
  int i;

  for (i = 0; i < csim->kml->button_count; i++)
    if (csim->kml->button [i])
      {
	csim->button_info [i] = alloc (sizeof (button_info_t));
	add_key (csim,
		 csim->kml->button [i],
		 i,
		 csim->button_info [i]);
      }
}


static int find_button_by_keycode (csim_t *csim, int keycode)
{
  int i;

  for (i = 0; i < csim->kml->button_count; i++)
    if (csim->kml->button [i]->user_keycode == keycode)
      return i;
  return -1;
}


// Presses the specified key.  Returns false if key doesn't exist.
bool set_key_state (csim_t *csim, int keycode, bool pressed)
{
  int button_index;

  button_index = find_button_by_keycode (csim, keycode);
  if (button_index < 0)
    return false;
  if (! csim->button_info [button_index])
    return false;
  if (pressed)
    button_widget_pressed (csim->button_info [button_index]->widget,
			   csim->button_info [button_index]);
  else
    button_widget_released (csim->button_info [button_index]->widget,
			    csim->button_info [button_index]);
  return true;
}
