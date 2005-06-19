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


typedef struct
{
  gboolean scancode_debug;
  kml_t *kml;
  sim_t *sim;
  GtkWidget *main_window;
  GdkPixbuf *background_pixbuf;  // window background (subset of file_pixbuf)
  GtkWidget *fixed;
  GtkItemFactory *main_menu_item_factory;
  GtkWidget *menubar;  // actually a popup menu in transparency/shape mode
  gui_display_t *gui_display;
  char state_fn [255];

  // keyboard vars:
  int button_pressed_count;    // how many keyboard buttons are pressed
  int button_pressed_first;  // 0..KML_MAX_BUTTON-1, remembers which button
                             // was pressed first if multiple are pressed
                             // simultaneusly, used for two-key rollover
  struct button_info_t *button_info [KML_MAX_BUTTON];
} csim_t;


typedef struct button_info_t
{
  csim_t *csim;
  kml_button_t *kml_button;
  int number;  // 0..KML_MAX_BUTTON-1
  GtkWidget *widget;
  bool pressed;
} button_info_t;
