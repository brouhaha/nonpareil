/*
$Id: csim.c 417 2004-06-15 07:34:30Z eric $
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
#include "display_gtk.h"
//#include "proc.h"
//#include "arch.h"
//#include "platform.h"
//#include "model.h"


struct gui_display_t
{
  kml_t *kml;
  GdkPixbuf *file_pixbuf;
  GtkWidget *drawing_area;
  GdkGC *annunciator_gc [KML_MAX_ANNUNCIATOR];
  segment_bitmap_t display_segments [KML_MAX_DIGITS];
};


static void draw_annunciator (gui_display_t *d, GtkWidget *widget, int i)
{
  gdk_draw_rectangle (widget->window,
		      d->annunciator_gc [i],
		      TRUE,
		      d->kml->annunciator [i]->offset.x - d->kml->display_offset.x,
		      d->kml->annunciator [i]->offset.y - d->kml->display_offset.y,
		      d->kml->annunciator [i]->size.width,
		      d->kml->annunciator [i]->size.height);
}


static void draw_digit (gui_display_t *d,
			GtkWidget *widget,
			gint x,
			gint y,
			segment_bitmap_t segments)
{
  int i;

  for (i = 0; i < KML_MAX_SEGMENT; i++)
    if ((segments & (1 << i)) && (d->kml->segment [i]))
      {
	switch (d->kml->segment [i]->type)
	  {
	  case kml_segment_type_line:
	    gdk_draw_line (widget->window,
			   d->drawing_area->style->fg_gc [GTK_WIDGET_STATE (widget)],
			   x + d->kml->segment [i]->offset.x,
			   y + d->kml->segment [i]->offset.y,
			   x + d->kml->segment [i]->offset.x + d->kml->segment [i]->size.width - 1,
			   y + d->kml->segment [i]->offset.y + d->kml->segment [i]->size.height - 1);
	    break;
	  case kml_segment_type_rect:
	    gdk_draw_rectangle (widget->window,
				d->drawing_area->style->fg_gc [GTK_WIDGET_STATE (widget)],
				TRUE,
				x + d->kml->segment [i]->offset.x,
				y + d->kml->segment [i]->offset.y,
				d->kml->segment [i]->size.width,
				d->kml->segment [i]->size.height);
	    break;
	  case kml_segment_type_image:
	    gdk_draw_pixbuf (widget->window,                   // drawable
			     d->drawing_area->style->fg_gc [GTK_WIDGET_STATE (widget)],
                             d->file_pixbuf,                   // pixbuf
			     d->kml->segment [i]->offset.x,    // src_x
			     d->kml->segment [i]->offset.y,    // src_y
			     x,                                // dest_x
			     y,                                // dest_y
			     d->kml->segment [i]->size.width,  // width
			     d->kml->segment [i]->size.height, // height
			     GDK_RGB_DITHER_NORMAL,            // dither
			     0,                                // x_dither
			     0);                               // y_dither
	    break;
	  }
      }
}


static gboolean display_expose_event_callback (GtkWidget *widget,
					       GdkEventExpose *event,
					       gpointer data)
{
  gui_display_t *d = data;
  int i;
  int x;

  /* clear the display */
  gdk_draw_rectangle (widget->window,
		      d->drawing_area->style->bg_gc [GTK_WIDGET_STATE (widget)],
		      TRUE,
		      0, 0,
		      d->drawing_area->allocation.width,
		      d->drawing_area->allocation.height);

  x = d->kml->digit_offset.x;
  for (i = 0; i < d->kml->display_digits; i++)
    {
      draw_digit (d, widget, x, d->kml->digit_offset.y, d->display_segments [i]);
      if ((d->display_segments [i] & SEGMENT_ANN) && d->kml->annunciator [i])
	draw_annunciator (d, widget, i);
      x += d->kml->digit_size.width;
    }

  return (TRUE);
}


void gui_display_update (gui_display_t *d,
			 int digit_count,
			 segment_bitmap_t *segments)
{
  int i;
  GdkRectangle rect = { 0, 0, 0, 0 };
  bool changed = 0;

  for (i = 0; i < digit_count; i++)
    {
      if (segments [i] != d->display_segments [i])
	changed = 1;
    }

  if (! changed)
    return;

  memcpy (d->display_segments, segments,
	  digit_count * sizeof (segment_bitmap_t));

  rect.width = d->drawing_area->allocation.width;
  rect.height = d->drawing_area->allocation.height;

  /* invalidate the entire drawing area */
  gdk_window_invalidate_rect (d->drawing_area->window,
			      & rect,
			      FALSE);
}


static void get_pixbuf_pixel (GdkPixbuf *pixbuf, int x, int y,
			      int *r, int *g, int *b)
{
  int width, height, rowstride, n_channels;
  guchar *pixels, *p;

  n_channels = gdk_pixbuf_get_n_channels (pixbuf);

  g_assert (gdk_pixbuf_get_colorspace (pixbuf) == GDK_COLORSPACE_RGB);
  g_assert (gdk_pixbuf_get_bits_per_sample (pixbuf) == 8);
  // g_assert (gdk_pixbuf_get_has_alpha (pixbuf));
  g_assert (n_channels >= 3);

  width = gdk_pixbuf_get_width (pixbuf);
  height = gdk_pixbuf_get_height (pixbuf);

  g_assert (x >= 0 && x < width);
  g_assert (y >= 0 && y < height);

  rowstride = gdk_pixbuf_get_rowstride (pixbuf);
  pixels = gdk_pixbuf_get_pixels (pixbuf);

  p = pixels + y * rowstride + x * n_channels;
  *r = p[0];
  *g = p[1];
  *b = p[2];
}


#define XBM_LSB_LEFT
// XBM bit order is defined as being MSB left, but
// gdk_bitmap_create_from_data() uses the data as LSB left.

static void init_annunciator (gui_display_t *d, GdkPixbuf *file_pixbuf, int i)
{
  int row_bytes;
  char *xbm_data;
  char *p;
  int bitmask;

  int bit;
  int x, y;
  int r, g, b;
  GdkBitmap *bitmap;

  row_bytes = (d->kml->annunciator [i]->size.width + 7) / 8;

  xbm_data = alloc (row_bytes * d->kml->annunciator [i]->size.height + 9);
  // $$$ If we don't add at least 9 bytes of padding,
  // gdk_bitmap_create_from_data() will segfault!

  for (y = 0; y < d->kml->annunciator [i]->size.height; y++)
    {
      p = & xbm_data [y * row_bytes];
#ifdef XBM_LSB_LEFT
      bitmask = 0x01;
#else
      bitmask = 0x80;
#endif
      for (x = 0; x < d->kml->annunciator [i]->size.width; x++)
	{
	  get_pixbuf_pixel (file_pixbuf, 
			    d->kml->annunciator [i]->offset.x + x,
			    d->kml->annunciator [i]->offset.y + y,
			    & r, & g, & b);

	  bit = (r == 0) && (g == 0) && (b == 0);
	  // $$$ This needs to be improved!  Perhaps we should compute
	  // the Euclidian distance in the color space between this pixel
	  // value and the display foreground and background colors?

	  if (bit)
	    (*p) |= bitmask;
#ifdef XBM_LSB_LEFT
	  bitmask <<= 1;
	  if (bitmask == 0x100)
	    {
	      p++;
	      bitmask = 0x01;
	    }
#else
	  bitmask >>= 1;
	  if (! bitmask)
	    {
	      p++;
	      bitmask = 0x80;
	    }
#endif
	}
    }

  bitmap = gdk_bitmap_create_from_data (NULL,
					xbm_data,
					d->kml->annunciator [i]->size.width,
					d->kml->annunciator [i]->size.height);

  free (xbm_data);

  d->annunciator_gc [i] = gdk_gc_new (d->drawing_area->window);
  gdk_gc_copy (d->annunciator_gc [i],
	       d->drawing_area->style->fg_gc [GTK_WIDGET_STATE (d->drawing_area)]);
  gdk_gc_set_clip_mask (d->annunciator_gc [i], bitmap);
  gdk_gc_set_clip_origin (d->annunciator_gc [i],
			  d->kml->annunciator [i]->offset.x - d->kml->display_offset.x,
			  d->kml->annunciator [i]->offset.y - d->kml->display_offset.y);
  gdk_gc_set_function (d->annunciator_gc [i], GDK_COPY);
  gdk_gc_set_fill (d->annunciator_gc [i], GDK_SOLID);
}


static void init_annunciators (gui_display_t *d, GdkPixbuf *file_pixbuf)
{
  int i;

  for (i = 0; i < KML_MAX_ANNUNCIATOR; i++)
    if (d->kml->annunciator [i])
      init_annunciator (d, file_pixbuf, i);
}


static void setup_color (GdkColormap *colormap,
			 kml_color_t *kml_color,
			 GdkColor *gdk_color,
			 char *name,
			 guint16 default_red,
			 guint16 default_green,
			 guint16 default_blue)
{
  if (kml_color)
    {
      gdk_color->red   = (kml_color->r << 8) + kml_color->r;
      gdk_color->green = (kml_color->g << 8) + kml_color->g;
      gdk_color->blue  = (kml_color->b << 8) + kml_color->b;
    }
  else
    {
#if 0
      if (kml_debug)
	fprintf (stderr, "KML doesn't specify %s color, using default\n", name);
#endif
      gdk_color->red   = default_red;
      gdk_color->green = default_green;
      gdk_color->blue  = default_blue;
    }
  if (! gdk_colormap_alloc_color (colormap, gdk_color, FALSE, TRUE))
    fatal (2, "can't alloc %s color\n", name);
}


gui_display_t * gui_display_init (kml_t *kml,
				  GtkWidget *main_window,
				  GtkWidget *event_box,
				  GtkWidget *fixed,
				  GdkPixbuf *file_pixbuf)
{
  gui_display_t *d;
  GdkColormap *colormap;
  GdkColor image_bg_color;
  GdkColor display_fg_color, display_bg_color;

  d = alloc (sizeof (gui_display_t));

  d->kml = kml;
  d->file_pixbuf = file_pixbuf;

  d->drawing_area = gtk_drawing_area_new ();

  colormap = gtk_widget_get_colormap (main_window);
  setup_color (colormap, kml->global_color [0], & image_bg_color,
	       "image background", 0x3333, 0x3333, 0x3333);

  gtk_widget_modify_bg (event_box, GTK_STATE_NORMAL, & image_bg_color);

  setup_color (colormap, kml->display_color [0], & display_bg_color,
	       "display background", 0x0000, 0x0000, 0x0000);

  setup_color (colormap, kml->display_color [2], & display_fg_color,
	       "display foreground", 0xffff, 0x1111, 0x1111);

  gtk_widget_set_size_request (d->drawing_area,
			       kml->display_size.width,
			       kml->display_size.height);
  gtk_widget_modify_fg (d->drawing_area, GTK_STATE_NORMAL, & display_fg_color);
  gtk_widget_modify_bg (d->drawing_area, GTK_STATE_NORMAL, & display_bg_color);
  gtk_fixed_put (GTK_FIXED (fixed),
		 d->drawing_area,
		 kml->display_offset.x - kml->background_offset.x,
		 kml->display_offset.y - kml->background_offset.y);

  init_annunciators (d, file_pixbuf);

  g_signal_connect (G_OBJECT (d->drawing_area),
		    "expose_event",
		    G_CALLBACK (display_expose_event_callback),
		    d);

  return d;
}
