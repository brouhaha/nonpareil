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
#include "printer.h"
#include "printer_gtk.h"


typedef struct
{
  bool tear;
  printer_line_data_t data;
} gui_printer_line_t;


struct gui_printer_t
{
  GtkWidget *window;
  GtkWidget *scrolled_window;  // may be able to make this a local
                               //   in gui_printer_init ()
  GtkWidget *layout;
  GdkGC *white;  // for paper
  GdkGC *black;  // for "ink"

  GdkPixbuf *pixbuf;           // used as a temporary buffer to render
                               //   one line of printer output
  guchar *pixels;
  size_t pixels_size;
  int rowstride;

  int line_count;
  gui_printer_line_t *line [PRINTER_MAX_BUFFER_LINES];
};


static void gui_printer_draw_tear (gui_printer_t *p,
				   int y)
{
  int x;
  GdkPoint points [3];

  // draw a series of white triangles
  for (x = 0; x < PRINTER_WIDTH; x += PRINTER_CHARACTER_WIDTH_PIXELS)
    {
      points [0].x = x;
      points [0].y = y + PRINTER_LINE_HEIGHT_PIXELS / 2;
      points [1].x = x + (PRINTER_CHARACTER_WIDTH_PIXELS / 2);
      points [1].y = y;
      points [2].x = x + PRINTER_CHARACTER_WIDTH_PIXELS - 1;
      points [2].y = y + PRINTER_LINE_HEIGHT_PIXELS / 2;
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
		      y + PRINTER_LINE_HEIGHT_PIXELS / 2,  // y
		      PRINTER_WIDTH,
		      PRINTER_LINE_HEIGHT_PIXELS - (PRINTER_LINE_HEIGHT_PIXELS / 2));
}


static void gui_printer_copy_pixels_to_pixbuf (gui_printer_t *p,
					       gui_printer_line_t *line)
{
  int x, y;
  int val;
  guchar *line_ptr;

  memset (p->pixels, 0, p->pixels_size);
  line_ptr = p->pixels;
  for (y = 0; y < PRINTER_LINE_HEIGHT_PIXELS; y++)
    {
      guchar *pixel_ptr = line_ptr;
      for (x = 0; x < PRINTER_WIDTH; x++)
	{
	  if (y < PRINTER_CHARACTER_HEIGHT_PIXELS)
	    val = (line->data.columns [x] & (1 << y)) ? 0x00 : 0xff;
	  else
	    val = 0xff;
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
  gui_printer_line_t *line;
  int y = line_num * PRINTER_LINE_HEIGHT_PIXELS;

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
		   line_num * PRINTER_LINE_HEIGHT_PIXELS,  // dest_y
		   PRINTER_WIDTH,                          // width
		   PRINTER_LINE_HEIGHT_PIXELS,             // height
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

  first_line = rect.y / PRINTER_LINE_HEIGHT_PIXELS;
  last_line = (rect.y + rect.height - 1) / PRINTER_LINE_HEIGHT_PIXELS;

  for (line = first_line; line <= last_line; line++)
    gui_printer_update_line (p, line);

  return TRUE;
}


void gui_printer_update (gui_printer_t *p,
			 printer_line_data_t *data)
{
  gui_printer_line_t *line;
  GdkRectangle rect;
  int height;

  if (p->line_count >= PRINTER_MAX_BUFFER_LINES)
    {
      return;
      // $$$ scroll here
      // $$$ invalidate entire window
    }

  line = alloc (sizeof (gui_printer_line_t));
  memcpy (& line->data, data, sizeof (printer_line_data_t));

  p->line [p->line_count] = line;

  rect.x = 0;
  rect.y = p->line_count * PRINTER_LINE_HEIGHT_PIXELS;
  rect.width = PRINTER_WIDTH;
  rect.height = PRINTER_LINE_HEIGHT_PIXELS;
  gdk_window_invalidate_rect (GTK_LAYOUT (p->layout)->bin_window,
			      & rect,
			      FALSE);

  p->line_count++;

  height = p->line_count * PRINTER_LINE_HEIGHT_PIXELS;

  if (height > PRINTER_WINDOW_INITIAL_HEIGHT)
    gtk_layout_set_size (GTK_LAYOUT (p->layout),
			 PRINTER_WIDTH,
			 height);
}


static gboolean printer_window_destroy_callback (GtkWidget *widget,
						 GdkEventAny *event)
{
  // $$$ more code needed here
  return FALSE;
}


gui_printer_t * gui_printer_init (void)
{
  gui_printer_t *p;

  p = alloc (sizeof (gui_printer_t));

  // create temp pixbuf used for rendering one printed line
  p->pixbuf = gdk_pixbuf_new (GDK_COLORSPACE_RGB,           // colorspace
			      FALSE,                        // has_alpha
			      8,                            // bits_per_sample
			      PRINTER_WIDTH,                // width,
			      PRINTER_LINE_HEIGHT_PIXELS);  // height
  g_assert (gdk_pixbuf_get_n_channels (p->pixbuf) == 3);
  p->rowstride = gdk_pixbuf_get_rowstride (p->pixbuf);
  p->pixels = gdk_pixbuf_get_pixels (p->pixbuf);
  p->pixels_size = (((PRINTER_LINE_HEIGHT_PIXELS - 1) * p->rowstride) +
		    (3 * PRINTER_WIDTH));

  // create line 0 with tear
  p->line [0] = alloc (sizeof (gui_printer_line_t));
  p->line [0]->tear = true;

  p->line [1] = alloc (sizeof (gui_printer_line_t));

  p->line_count = 2;

  p->layout = gtk_layout_new (NULL, NULL);

  gtk_layout_set_size (GTK_LAYOUT (p->layout),
		       PRINTER_WIDTH,
		       PRINTER_WINDOW_INITIAL_HEIGHT);

  gtk_widget_set_size_request (p->layout,
			       PRINTER_WIDTH,
			       PRINTER_WINDOW_INITIAL_HEIGHT);

  p->scrolled_window = gtk_scrolled_window_new (NULL, NULL);

  gtk_container_add (GTK_CONTAINER (p->scrolled_window), p->layout);

  gtk_scrolled_window_set_policy (GTK_SCROLLED_WINDOW (p->scrolled_window),
				  GTK_POLICY_AUTOMATIC,
				  GTK_POLICY_ALWAYS);


  p->window = gtk_window_new (GTK_WINDOW_TOPLEVEL);

  gtk_window_set_title (GTK_WINDOW (p->window), "Printer");

  gtk_container_add (GTK_CONTAINER (p->window), p->scrolled_window);

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

  return p;
}
