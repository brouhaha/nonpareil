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
#include <string.h>
#include <gdk/gdk.h>
#include <gtk/gtk.h>

#include "util.h"
#include "display.h"
#include "kml.h"
#include "proc.h"
#include "helios.h"
#include "printer.h"


#define PRINTER_MODE_BUTTONS
#undef  PRINTER_MODE_MENU

#if defined(PRINTER_MODE_BUTTONS) && defined(PRINTER_MODE_MENU)
  #error "PRINTER_MODE_BUTTONS and PRINTER_MODE_MENU are mutually exclusive."
#endif


typedef struct
{
  sim_t *sim;
  chip_t *chip;

  int scale;  // magnification of output, e.g., 2 for double size

  GtkWidget *window;
  GtkWidget *layout;
  GdkGC *white;  // for paper
  GdkGC *black;  // for "ink"

  GdkPixbuf *pixbuf;           // used as a temporary buffer to render
                               //   one line of printer output
  guchar *pixels;
  size_t pixels_size;
  int rowstride;

  int line_count;
  printer_line_data_t *line [PRINTER_MAX_BUFFER_LINES];
} gui_printer_t;


void gui_printer_create_pixbuf (gui_printer_t *p)
{
  int full_lines;
  int pixels_per_line;

  // If there already is one (for instance, if we're turning double_size
  // on or off), free it.
  if (p->pixbuf)
    g_object_unref (p->pixbuf);

  // create temp pixbuf used for rendering one printed line
  p->pixbuf = gdk_pixbuf_new (GDK_COLORSPACE_RGB,           // colorspace
			      FALSE,                        // has_alpha
			      8,                            // bits_per_sample
			      p->scale * PRINTER_WIDTH_WITH_MARGINS,   // width,
			      p->scale * PRINTER_LINE_HEIGHT_PIXELS);  // height
  g_assert (gdk_pixbuf_get_n_channels (p->pixbuf) == 3);
  p->rowstride = gdk_pixbuf_get_rowstride (p->pixbuf);
  p->pixels = gdk_pixbuf_get_pixels (p->pixbuf);

  // Computing the total size of the raw data in the pixbuf is tricky because
  // the last row of pixels may not have the full rowstride allocated.
  full_lines = p->scale * PRINTER_LINE_HEIGHT_PIXELS - 1;
  pixels_per_line = p->scale * PRINTER_WIDTH_WITH_MARGINS;
  p->pixels_size = (full_lines * p->rowstride) + (pixels_per_line * 3);
}


void gui_printer_set_scale (gui_printer_t *p, int scale)
{
  int height;
  GdkRectangle rect;

  if (scale == p->scale)
    return;  // no change

  p->scale = scale;

  gui_printer_create_pixbuf (p);  // resize the pixbuf

  height = p->line_count * PRINTER_LINE_HEIGHT_PIXELS;
  if (height < PRINTER_WINDOW_INITIAL_HEIGHT_PIXELS)
    height = PRINTER_WINDOW_INITIAL_HEIGHT_PIXELS;

  gtk_layout_set_size (GTK_LAYOUT (p->layout),
		       p->scale * PRINTER_WIDTH_WITH_MARGINS,
		       p->scale * height);

  gtk_widget_set_size_request (p->layout,
			       p->scale * PRINTER_WIDTH_WITH_MARGINS,
			       p->scale * PRINTER_WINDOW_INITIAL_HEIGHT_PIXELS);
  // During initialization, there isn't yet a window to invalidate.
  if (! GTK_LAYOUT (p->layout)->bin_window)
    return;

  // invalidate entire layout
  rect.x = 0;
  rect.y = 0;
  rect.width = p->scale * PRINTER_WIDTH_WITH_MARGINS;
  rect.height = p->line_count *  p->scale * PRINTER_LINE_HEIGHT_PIXELS;
  gdk_window_invalidate_rect (GTK_LAYOUT (p->layout)->bin_window,
			      & rect,
			      FALSE);
}


static void gui_printer_draw_tear (gui_printer_t *p,
				   int y)
{
  int x;
  GdkPoint points [3];

  // draw a series of white triangles
  for (x = 0;
       x < p->scale * PRINTER_WIDTH_WITH_MARGINS;
       x += p->scale * PRINTER_CHARACTER_WIDTH_PIXELS)
    {
      points [0].x = x;
      points [0].y = y + p->scale * PRINTER_LINE_HEIGHT_PIXELS / 2;
      points [1].x = x + p->scale * PRINTER_CHARACTER_WIDTH_PIXELS / 2;
      points [1].y = y;
      points [2].x = x + p->scale * PRINTER_CHARACTER_WIDTH_PIXELS - 1;
      points [2].y = y + p->scale * PRINTER_LINE_HEIGHT_PIXELS / 2;
      gdk_draw_polygon (GTK_LAYOUT (p->layout)->bin_window,
			p->white,   // gc
			TRUE,       // filled
			points,
			3);         // npoints
			
    }
  gdk_draw_rectangle (GTK_LAYOUT (p->layout)->bin_window,
		      p->white,    // gc
		      TRUE,        // filled
		      0,           // x
		      y + p->scale * PRINTER_LINE_HEIGHT_PIXELS / 2,  // y
		      p->scale * PRINTER_WIDTH_WITH_MARGINS,
		      p->scale * (PRINTER_LINE_HEIGHT_PIXELS - (PRINTER_LINE_HEIGHT_PIXELS / 2)));
}


static void gui_printer_copy_pixels_to_pixbuf (gui_printer_t *p,
					       printer_line_data_t *line)
{
  int x, y;
  guchar *line_ptr;

  memset (p->pixels, 0, p->pixels_size);
  line_ptr = p->pixels;
  for (y = 0; y < p->scale * PRINTER_LINE_HEIGHT_PIXELS; y++)
    {
      guchar *pixel_ptr = line_ptr;
      for (x = 0; x < p->scale * PRINTER_WIDTH_WITH_MARGINS; x++)
	{
	  uint8_t col, val;
	  if (((y / p->scale) < PRINTER_CHARACTER_HEIGHT_PIXELS) &&
	      (((x / p->scale) >= PRINTER_LEFT_MARGIN_PIXELS) &&
	       ((x / p->scale) < PRINTER_WIDTH + PRINTER_LEFT_MARGIN_PIXELS)))
	    col = line->columns [(x / p->scale) - PRINTER_LEFT_MARGIN_PIXELS];
	  else
	    col = 0x00;  // white
	  val = (col & (1 << (y / p->scale))) ? 0x00 : 0xff;
	  *(pixel_ptr++) = val;
	  *(pixel_ptr++) = val;
	  *(pixel_ptr++) = val;
	}
      line_ptr += p->rowstride;
    }
}


static void gui_printer_update_line (gui_printer_t *p,
				     int line_num)
{
  printer_line_data_t *line;
  int y = line_num * p->scale * PRINTER_LINE_HEIGHT_PIXELS;

  line = p->line [line_num];

  if (! line)
    return;  // leave background

  if (line->tear)
    {
      gui_printer_draw_tear (p, y);
      return;
    }

  gui_printer_copy_pixels_to_pixbuf (p, line);

  gdk_draw_pixbuf (GTK_LAYOUT (p->layout)->bin_window,     // drawable
		   p->white,    // gc
		   p->pixbuf,   // pixbuf
		   0,           // src_x
		   0,           // src_y
		   0,           // dest_x
		   line_num * p->scale * PRINTER_LINE_HEIGHT_PIXELS, // dest_y
		   p->scale * PRINTER_WIDTH_WITH_MARGINS,            // width
		   p->scale * PRINTER_LINE_HEIGHT_PIXELS,            // height
		   GDK_RGB_DITHER_NONE,                    // dither
		   0,                                      // x_dither
		   0);                                     // y_dither
}


static gboolean printer_window_expose_callback (GtkWidget *widget,
						GdkEventExpose *event,
						gpointer data)
{
  gui_printer_t *p = data;
  GdkRectangle rect;
  int first_line, last_line;
  int line;

  gdk_region_get_clipbox (event->region, & rect);

#if 0
  printf ("printer expose x=%d, y=%d, width=%d, height=%d\n",
	  rect.x, rect.y, rect.width,rect.height);
#endif

  first_line = rect.y / (p->scale * PRINTER_LINE_HEIGHT_PIXELS);
  last_line = (rect.y + rect.height - 1) / (p->scale * PRINTER_LINE_HEIGHT_PIXELS);

  for (line = first_line; line <= last_line; line++)
    gui_printer_update_line (p, line);

  return TRUE;
}


void gui_printer_update (sim_t  *sim,
			 chip_t *chip,
			 void   *ref,
			 void   *data)
{
  gui_printer_t *p = ref;
  printer_line_data_t *line = data;
  GdkRectangle rect;
  int height;

  if (p->line_count >= PRINTER_MAX_BUFFER_LINES)
    {
      return;
      // $$$ scroll here
      // $$$ invalidate entire window
    }

  p->line [p->line_count] = line;

  rect.x = 0;
  rect.y = p->line_count * p->scale * PRINTER_LINE_HEIGHT_PIXELS;
  rect.width = p->scale * PRINTER_WIDTH_WITH_MARGINS;
  rect.height = p->scale * PRINTER_LINE_HEIGHT_PIXELS;
  gdk_window_invalidate_rect (GTK_LAYOUT (p->layout)->bin_window,
			      & rect,
			      FALSE);

  p->line_count++;

  height = p->line_count * PRINTER_LINE_HEIGHT_PIXELS;

  if (height > PRINTER_WINDOW_INITIAL_HEIGHT_PIXELS)
    gtk_layout_set_size (GTK_LAYOUT (p->layout),
			 p->scale * PRINTER_WIDTH_WITH_MARGINS,
			 p->scale * height);
}


static gboolean printer_window_destroy_callback (GtkWidget *widget,
						 GdkEventAny *event)
{
  // $$$ more code needed here
  return FALSE;
}


static void gui_printer_set_mode (gui_printer_t *p, int mode)
{
  sim_event (p->sim,
	     event_printer_set_mode,
	     p->chip,
	     mode,
	     NULL);
}


#ifdef PRINTER_MODE_BUTTONS
static void gui_printer_set_mode_man (GtkWidget *widget, gpointer data)
{
  gui_printer_t *p = data;
  if (gtk_toggle_button_get_active (GTK_TOGGLE_BUTTON (widget)))
    gui_printer_set_mode (p, PRINTER_MODE_MAN);
}


static void gui_printer_set_mode_trace (GtkWidget *widget, gpointer data)
{
  gui_printer_t *p = data;
  if (gtk_toggle_button_get_active (GTK_TOGGLE_BUTTON (widget)))
    gui_printer_set_mode (p, PRINTER_MODE_TRACE);
}


static void gui_printer_set_mode_norm (GtkWidget *widget, gpointer data)
{
  gui_printer_t *p = data;
  if (gtk_toggle_button_get_active (GTK_TOGGLE_BUTTON (widget)))
    gui_printer_set_mode (p, PRINTER_MODE_NORM);
}


static GtkWidget *gui_printer_create_mode_frame (gui_printer_t *p)
{
  GtkWidget *mode_frame;
  GtkWidget *box;
  GtkWidget *man, *trace, *norm;

  mode_frame = gtk_frame_new ("Mode");

  man = gtk_radio_button_new_with_label (NULL, "MAN");
  g_signal_connect (G_OBJECT (man),
		    "clicked",
		    G_CALLBACK (gui_printer_set_mode_man),
		    p);

  trace = gtk_radio_button_new_with_label_from_widget (GTK_RADIO_BUTTON (man),
						       "TRACE");
  g_signal_connect (G_OBJECT (trace),
		    "clicked",
		    G_CALLBACK (gui_printer_set_mode_trace),
		    p);

  norm = gtk_radio_button_new_with_label_from_widget (GTK_RADIO_BUTTON (man),
						      "NORM");
  g_signal_connect (G_OBJECT (norm),
		    "clicked",
		    G_CALLBACK (gui_printer_set_mode_norm),
		    p);


  box = gtk_vbox_new (FALSE, 0);  // $$$ Should we use a Gtk[HV]ButtonBox?
  gtk_box_pack_start (GTK_BOX (box), man, FALSE, FALSE, 0);
  gtk_box_pack_start (GTK_BOX (box), trace, FALSE, FALSE, 0);
  gtk_box_pack_start (GTK_BOX (box), norm, FALSE, FALSE, 0);

  gtk_container_add (GTK_CONTAINER (mode_frame), box);

  return mode_frame;
}
#endif // PRINTER_MODE_BUTTONS


static void gui_printer_print_button_pressed (GtkWidget *widget,
					      gpointer data)
{
  gui_printer_t *p = data;
  sim_event (p->sim,
	     event_printer_print_button,
	     p->chip,
	     1,
	     NULL);
}


static void gui_printer_print_button_released (GtkWidget *widget,
					       gpointer data)
{
  gui_printer_t *p = data;
  sim_event (p->sim,
	     event_printer_print_button,
	     p->chip,
	     0,
	     NULL);
}


static void gui_printer_advance_button_pressed (GtkWidget *widget,
						gpointer data)
{
  gui_printer_t *p = data;
  sim_event (p->sim,
	     event_printer_paper_advance_button,
	     p->chip,
	     1,
	     NULL);
}


static void gui_printer_advance_button_released (GtkWidget *widget,
						 gpointer data)
{
  gui_printer_t *p = data;
  sim_event (p->sim,
	     event_printer_paper_advance_button,
	     p->chip,
	     0,
	     NULL);
}


static GtkWidget *gui_printer_create_buttons (gui_printer_t *p)
{
  GtkWidget *box;
  GtkWidget *print, *advance;

  print = gtk_button_new_with_label ("Print");
  advance = gtk_button_new_with_label ("Paper Advance");

  g_signal_connect (G_OBJECT (print),
		    "pressed",
		    G_CALLBACK (gui_printer_print_button_pressed),
		    p);

  g_signal_connect (G_OBJECT (print),
		    "released",
		    G_CALLBACK (gui_printer_print_button_released),
		    p);

  g_signal_connect (G_OBJECT (advance),
		    "pressed",
		    G_CALLBACK (gui_printer_advance_button_pressed),
		    p);

  g_signal_connect (G_OBJECT (advance),
		    "released",
		    G_CALLBACK (gui_printer_advance_button_released),
		    p);

#ifdef PRINTER_MODE_BUTTONS
  box = gtk_vbox_new (FALSE, 0);  // $$$ Should we use a Gtk[HV]ButtonBox?
#else
  box = gtk_hbox_new (FALSE, 0);  // $$$ Should we use a Gtk[HV]ButtonBox?
#endif

  gtk_box_pack_start (GTK_BOX (box), print, FALSE, FALSE, 0);
  gtk_box_pack_start (GTK_BOX (box), advance, FALSE, FALSE, 0);
 
  return box;
}


static GtkWidget *gui_printer_create_controls (gui_printer_t *p)
{
#ifdef PRINTER_MODE_BUTTONS
  GtkWidget *mode_frame;
#endif // PRINTER_MODE_BUTTONS
  GtkWidget *buttons;
  GtkWidget *box;

  box = gtk_hbox_new (FALSE, 1);

#ifdef PRINTER_MODE_BUTTONS
  mode_frame = gui_printer_create_mode_frame (p);
  gtk_box_pack_start (GTK_BOX (box), mode_frame, FALSE, FALSE, 0);
#endif // PRINTER_MODE_BUTTONS

  buttons = gui_printer_create_buttons (p);
  gtk_box_pack_start (GTK_BOX (box), buttons, FALSE, FALSE, 0);

  return box;
}


static void gui_printer_size_toggle_callback (gpointer callback_data,
					      guint    callback_action,
					      GtkWidget *widget)
{
  gui_printer_t *p = callback_data;

  gui_printer_set_scale (p, 3 - p->scale);
}


static void gui_printer_edit_copy_callback (gpointer callback_data,
					    guint    callback_action,
					    GtkWidget *widget)
{
  gui_printer_t *p = callback_data;
  // $$$ not yet implemented
}


#ifdef PRINTER_MODE_MENU
static void gui_printer_mode_man (gpointer  callback_data,
				  guint     callback_action,
				  GtkWidget *widget)
{
  gui_printer_t *p = callback_data;
  gui_printer_set_mode (p, PRINTER_MODE_MAN);
}


static void gui_printer_mode_trace (gpointer  callback_data,
				    guint     callback_action,
				    GtkWidget *widget)
{
  gui_printer_t *p = callback_data;
  gui_printer_set_mode (p, PRINTER_MODE_TRACE);
}


static void gui_printer_mode_norm (gpointer  callback_data,
				   guint     callback_action,
				   GtkWidget *widget)
{
  gui_printer_t *p = callback_data;
  gui_printer_set_mode (p, PRINTER_MODE_NORM);
}
#endif // PRINTER_MODE_MENU


static GtkItemFactoryEntry gui_printer_menu_items [] =
  {
    { "/_File",         NULL,         NULL,          0, "<Branch>" },
    { "/File/Double size", NULL,      gui_printer_size_toggle_callback,
      1, "<ToggleItem>" },
    { "/_Edit",         NULL,         NULL,          0, "<Branch>" },
    { "/Edit/_Copy",    "<control>C", gui_printer_edit_copy_callback,
      1, "<StockItem>", GTK_STOCK_COPY },
#ifdef PRINTER_MODE_MENU
    { "/_Mode",         NULL,         NULL,          0, "<Branch>" },
    { "/Mode/_Man",     NULL,         gui_printer_mode_man,
      1, "<RadioItem>" },
    { "/Mode/_Trace",   NULL,         gui_printer_mode_trace,
      1, "/Mode/Man" },
    { "/Mode/_Norm",    NULL,         gui_printer_mode_norm,
      1, "/Mode/Trace" },
#endif // PRINTER_MODE_MENU
  };

static gint n_gui_printer_menu_items = (sizeof (gui_printer_menu_items) /
					sizeof (GtkItemFactoryEntry));


GtkWidget *gui_printer_create_menubar (gui_printer_t *p)
{
  GtkAccelGroup *accel_group;
  GtkItemFactory *item_factory;

  accel_group = gtk_accel_group_new ();
  item_factory = gtk_item_factory_new (GTK_TYPE_MENU_BAR,
				       "<printer>",
				       accel_group);
  gtk_item_factory_create_items (item_factory,
				 n_gui_printer_menu_items,
				 gui_printer_menu_items,
				 p);
  gtk_window_add_accel_group (GTK_WINDOW (p->window), accel_group);
  return gtk_item_factory_get_widget (item_factory, "<printer>");
}


void gui_printer_init (sim_t *sim)
{
  gui_printer_t *p;
  GtkWidget *menubar;
  GtkWidget *controls;
  GtkWidget *scrolled_window;
  GtkWidget *vbox;

  p = alloc (sizeof (gui_printer_t));

  p->sim = sim;

  p->chip = sim_add_chip (sim,
			  CHIP_HELIOS,         // chip_type
			  gui_printer_update,  // callback_fn
			  p);                  // ref
  if (! p->chip)
    fatal (3, "can't add Helios chip\n");

#if 0
  sim_set_printer_callback (csim->sim,
			    (printer_callback_fn_t *) gui_printer_update,
			    csim->gui_printer);  // ref
#endif

  // create line 0 with tear
  p->line [0] = alloc (sizeof (printer_line_data_t));
  p->line [0]->tear = true;

  p->line [1] = alloc (sizeof (printer_line_data_t));

  p->line_count = 2;

  p->window = gtk_window_new (GTK_WINDOW_TOPLEVEL);

  p->layout = gtk_layout_new (NULL, NULL);

  gui_printer_set_scale (p, 1);  // default 1x scale

  scrolled_window = gtk_scrolled_window_new (NULL, NULL);
  gtk_container_add (GTK_CONTAINER (scrolled_window), p->layout);
  gtk_scrolled_window_set_policy (GTK_SCROLLED_WINDOW (scrolled_window),
				  GTK_POLICY_AUTOMATIC,
				  GTK_POLICY_ALWAYS);


  menubar = gui_printer_create_menubar (p);

  controls = gui_printer_create_controls (p);

  vbox = gtk_vbox_new (FALSE, 1);
  gtk_box_pack_start (GTK_BOX (vbox), menubar, FALSE, FALSE, 0);
  gtk_box_pack_start (GTK_BOX (vbox), controls, FALSE, FALSE, 0);
  gtk_box_pack_start_defaults (GTK_BOX (vbox), scrolled_window);

  gtk_window_set_title (GTK_WINDOW (p->window), "Printer");
  gtk_container_add (GTK_CONTAINER (p->window), vbox);

  g_signal_connect (G_OBJECT (p->layout),
		    "expose_event",
		    G_CALLBACK (printer_window_expose_callback),
		    p);

  g_signal_connect (G_OBJECT (p->window),
		    "destroy",
		    GTK_SIGNAL_FUNC (printer_window_destroy_callback),
		    p);

  gtk_widget_show_all (p->window);

  p->black = p->layout->style->black_gc;
  g_object_ref (p->black);

  p->white = p->layout->style->white_gc;
  g_object_ref (p->white);
}
