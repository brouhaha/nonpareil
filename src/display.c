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


static kml_t *dkml;  // display keeps a pointer to the KML file.  Ugly!

GdkPixbuf *d_file_pixbuf;  // display keeps a pointer to the file pixbuf. Ugly!

static GtkWidget *display;

static GdkGC *annunciator_gc [KML_MAX_ANNUNCIATOR];


static segment_bitmap_t display_segments [KML_MAX_DIGITS];


static void draw_annunciator (GtkWidget *widget, int i)
{
  gdk_draw_rectangle (widget->window,
		      annunciator_gc [i],
		      TRUE,
		      dkml->annunciator [i]->offset.x - dkml->display_offset.x,
		      dkml->annunciator [i]->offset.y - dkml->display_offset.y,
		      dkml->annunciator [i]->size.width,
		      dkml->annunciator [i]->size.height);
}


static void draw_digit (GtkWidget *widget,
			gint x,
			gint y,
			segment_bitmap_t segments)
{
  int i;

  for (i = 0; i < KML_MAX_SEGMENT; i++)
    if ((segments & (1 << i)) && (dkml->segment [i]))
      {
	switch (dkml->segment [i]->type)
	  {
	  case kml_segment_type_line:
	    gdk_draw_line (widget->window,
			   display->style->fg_gc [GTK_WIDGET_STATE (widget)],
			   x + dkml->segment [i]->offset.x,
			   y + dkml->segment [i]->offset.y,
			   x + dkml->segment [i]->offset.x + dkml->segment [i]->size.width - 1,
			   y + dkml->segment [i]->offset.y + dkml->segment [i]->size.height - 1);
	    break;
	  case kml_segment_type_rect:
	    gdk_draw_rectangle (widget->window,
				display->style->fg_gc [GTK_WIDGET_STATE (widget)],
				TRUE,
				x + dkml->segment [i]->offset.x,
				y + dkml->segment [i]->offset.y,
				dkml->segment [i]->size.width,
				dkml->segment [i]->size.height);
	    break;
	  case kml_segment_type_image:
	    gdk_draw_pixbuf (widget->window,                 // drawable
			     display->style->fg_gc [GTK_WIDGET_STATE (widget)],
                             d_file_pixbuf,                  // pixbuf
			     dkml->segment [i]->offset.x,    // src_x
			     dkml->segment [i]->offset.y,    // src_y
			     x,                              // dest_x
			     y,                              // dest_y
			     dkml->segment [i]->size.width,  // width
			     dkml->segment [i]->size.height, // height
			     GDK_RGB_DITHER_NORMAL,          // dither
			     0,                              // x_dither
			     0);                             // y_dither
	    break;
	  }
      }
}


static gboolean display_expose_event_callback (GtkWidget *widget,
					       GdkEventExpose *event,
					       gpointer data)
{
  int i;
  int x;

  /* clear the display */
  gdk_draw_rectangle (widget->window,
		      display->style->bg_gc [GTK_WIDGET_STATE (widget)],
		      TRUE,
		      0, 0,
		      display->allocation.width,
		      display->allocation.height);

  x = dkml->digit_offset.x;
  for (i = 0; i < dkml->display_digits; i++)
    {
      draw_digit (widget, x, dkml->digit_offset.y, display_segments [i]);
      if ((display_segments [i] & SEGMENT_ANN) && dkml->annunciator [i])
	draw_annunciator (widget, i);
      x += dkml->digit_size.width;
    }

  return (TRUE);
}


void display_update (int digit_count,
		     segment_bitmap_t *segments)
{
  int i;
  GdkRectangle rect = { 0, 0, 0, 0 };
  bool changed = 0;

  for (i = 0; i < digit_count; i++)
    {
      if (segments [i] != display_segments [i])
	changed = 1;
    }

  if (! changed)
    return;

  memcpy (display_segments, segments,
	  digit_count * sizeof (segment_bitmap_t));

  rect.width = display->allocation.width;
  rect.height = display->allocation.height;

  /* invalidate the entire drawing area */
  gdk_window_invalidate_rect (display->window,
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

static void init_annunciator (GdkPixbuf *file_pixbuf, int i)
{
  int row_bytes;
  char *xbm_data;
  char *p;
  int bitmask;

  int bit;
  int x, y;
  int r, g, b;
  GdkBitmap *bitmap;

  row_bytes = (dkml->annunciator [i]->size.width + 7) / 8;

  xbm_data = alloc (row_bytes * dkml->annunciator [i]->size.height + 9);
  // $$$ If we don't add at least 9 bytes of padding,
  // gdk_bitmap_create_from_data() will segfault!

  for (y = 0; y < dkml->annunciator [i]->size.height; y++)
    {
      p = & xbm_data [y * row_bytes];
#ifdef XBM_LSB_LEFT
      bitmask = 0x01;
#else
      bitmask = 0x80;
#endif
      for (x = 0; x < dkml->annunciator [i]->size.width; x++)
	{
	  get_pixbuf_pixel (file_pixbuf, 
			    dkml->annunciator [i]->offset.x + x,
			    dkml->annunciator [i]->offset.y + y,
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
					dkml->annunciator [i]->size.width,
					dkml->annunciator [i]->size.height);

  free (xbm_data);

  annunciator_gc [i] = gdk_gc_new (display->window);
  gdk_gc_copy (annunciator_gc [i],
	       display->style->fg_gc [GTK_WIDGET_STATE (display)]);
  gdk_gc_set_clip_mask (annunciator_gc [i], bitmap);
  gdk_gc_set_clip_origin (annunciator_gc [i],
			  dkml->annunciator [i]->offset.x - dkml->display_offset.x,
			  dkml->annunciator [i]->offset.y - dkml->display_offset.y);
  gdk_gc_set_function (annunciator_gc [i], GDK_COPY);
  gdk_gc_set_fill (annunciator_gc [i], GDK_SOLID);
}


static void init_annunciators (GdkPixbuf *file_pixbuf)
{
  int i;

  for (i = 0; i < KML_MAX_ANNUNCIATOR; i++)
    if (dkml->annunciator [i])
      init_annunciator (file_pixbuf, i);
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


void display_init (kml_t *kml,
		   GtkWidget *main_window,
		   GtkWidget *event_box,
		   GtkWidget *fixed,
		   GdkPixbuf *file_pixbuf)
{
  GdkColormap *colormap;
  GdkColor image_bg_color;
  GdkColor display_fg_color, display_bg_color;

  dkml = kml;
  d_file_pixbuf = file_pixbuf;

  display = gtk_drawing_area_new ();

  colormap = gtk_widget_get_colormap (main_window);
  setup_color (colormap, kml->global_color [0], & image_bg_color,
	       "image background", 0x3333, 0x3333, 0x3333);

  gtk_widget_modify_bg (event_box, GTK_STATE_NORMAL, & image_bg_color);

  setup_color (colormap, kml->display_color [0], & display_bg_color,
	       "display background", 0x0000, 0x0000, 0x0000);

  setup_color (colormap, kml->display_color [2], & display_fg_color,
	       "display foreground", 0xffff, 0x1111, 0x1111);

  gtk_widget_set_size_request (display,
			       kml->display_size.width,
			       kml->display_size.height);
  gtk_widget_modify_fg (display, GTK_STATE_NORMAL, & display_fg_color);
  gtk_widget_modify_bg (display, GTK_STATE_NORMAL, & display_bg_color);
  gtk_fixed_put (GTK_FIXED (fixed),
		 display,
		 kml->display_offset.x - kml->background_offset.x,
		 kml->display_offset.y - kml->background_offset.y);

  init_annunciators (file_pixbuf);

  g_signal_connect (G_OBJECT (display),
		    "expose_event",
		    G_CALLBACK (display_expose_event_callback),
		    NULL);
}
