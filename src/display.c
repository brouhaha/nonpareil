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
#include "proc.h"
#include "csim.h"


struct gui_display_t
{
  csim_t *csim;
  GtkWidget *drawing_area;
  int digit_count;  // how many digits the sim thread asked us to display
  GdkGC *annunciator_gc [KML_MAX_ANNUNCIATOR];
  GdkPixbuf *segment_pixbuf [KML_MAX_SEGMENT];
  segment_bitmap_t display_segments [KML_MAX_DIGITS];
};


static void draw_annunciator (gui_display_t *d,
			      GtkWidget *widget,
			      int i,
			      bool state)
{
  kml_t *kml;
  GdkGC *bg_gc;

  kml = d->csim->kml;

  bg_gc = d->drawing_area->style->bg_gc [GTK_WIDGET_STATE (widget)];

  // first clear annunciator rect to bg color
  gdk_draw_rectangle (widget->window,
		      bg_gc,
		      TRUE,
		      kml->annunciator [i]->offset.x,
		      kml->annunciator [i]->offset.y,
		      kml->annunciator [i]->size.width,
		      kml->annunciator [i]->size.height);
		      
  // then if annunciator is active, draw it
  if (state)
    gdk_draw_rectangle (widget->window,
			d->annunciator_gc [i],  // fg color clipped to annunciator shape
			TRUE,
			kml->annunciator [i]->offset.x,
			kml->annunciator [i]->offset.y,
			kml->annunciator [i]->size.width,
			kml->annunciator [i]->size.height);
}


static void draw_digit (gui_display_t *d,
			GtkWidget *widget,
			gint x,
			gint y,
			segment_bitmap_t segments)
{
  int i;
  kml_t *kml = d->csim->kml;
  GdkGC *fg_gc;

  fg_gc = d->drawing_area->style->fg_gc [GTK_WIDGET_STATE (widget)];

  // $$$ (erase first if segments aren't using "scaled" mode
  for (i = 0; i < KML_MAX_SEGMENT; i++)
    if ((segments & (1 << i)) && (kml->segment [i]))
      {
	switch (kml->segment [i]->type)
	  {
	  case kml_segment_type_line:
	    gdk_draw_line (widget->window,
			   fg_gc,
			   x + kml->segment [i]->offset.x,
			   y + kml->segment [i]->offset.y,
			   x + kml->segment [i]->offset.x + kml->segment [i]->size.width - 1,
			   y + kml->segment [i]->offset.y + kml->segment [i]->size.height - 1);
	    break;
	  case kml_segment_type_rect:
	    gdk_draw_rectangle (widget->window,
				fg_gc,
				TRUE,
				x + kml->segment [i]->offset.x,
				y + kml->segment [i]->offset.y,
				kml->segment [i]->size.width,
				kml->segment [i]->size.height);
	    break;
	  case kml_segment_type_image:
	    // grab segment images from individual templates in image file
	    gdk_draw_pixbuf (widget->window,                   // drawable
			     fg_gc,
                             d->csim->file_pixbuf,                   // pixbuf
			     kml->segment [i]->offset.x,    // src_x
			     kml->segment [i]->offset.y,    // src_y
			     x,                                // dest_x
			     y,                                // dest_y
			     kml->segment [i]->size.width,  // width
			     kml->segment [i]->size.height, // height
			     GDK_RGB_DITHER_NORMAL,            // dither
			     0,                                // x_dither
			     0);                               // y_dither
	    break;
	  case kml_segment_type_scaled:
	    // pre-rendered images extracted from a single template in
            // image file and scaled down
	    gdk_draw_pixbuf (widget->window,                   // drawable
			     fg_gc,
                             d->segment_pixbuf [i],            // pixbuf
			     0,                                // src_x
			     0,                                // src_y
			     x,                                // dest_x
			     y,                                // dest_y
			     kml->digit_size.width,         // width
			     kml->digit_size.height,        // height
			     GDK_RGB_DITHER_NORMAL,            // dither
			     0,                                // x_dither
			     0);                               // y_dither
	    break;
	  }
      }
}


static void region_subtract_rect (GdkRegion *region, GdkRectangle *rect)
{
  GdkRegion *subtrahend;

  subtrahend = gdk_region_rectangle (rect);
  gdk_region_subtract (region, subtrahend);
  gdk_region_destroy (subtrahend);
}

static gboolean display_expose_event_callback (GtkWidget *widget,
					       GdkEventExpose *event,
					       gpointer data)
{
  gui_display_t *d = data;
  kml_t *kml = d->csim->kml;
  int i;
  GdkRectangle rect;
  GdkGC *bg_gc;

  bg_gc = d->drawing_area->style->bg_gc [GTK_WIDGET_STATE (widget)];


  rect.x = kml->digit_offset.x;
  rect.y = kml->digit_offset.y;
  rect.width = kml->digit_size.width;
  rect.height = kml->digit_size.height;

  for (i = 0; (i < d->digit_count) && ! gdk_region_empty (event->region); i++)
    {
      if (gdk_region_rect_in (event->region, & rect) != GDK_OVERLAP_RECTANGLE_OUT)
	{
	  draw_digit (d,
		      widget,
		      rect.x,
		      rect.y,
		      d->display_segments [i]);
	  region_subtract_rect (event->region, & rect);
	}
      rect.x += kml->digit_size.width;
    }

  for (i = 0; (i < d->digit_count) && ! gdk_region_empty (event->region); i++)
    {
      if (! kml->annunciator [i])
	continue;
      rect.x = kml->annunciator [i]->offset.x;
      rect.y = kml->annunciator [i]->offset.y;
      rect.width  = kml->annunciator [i]->size.width;
      rect.height = kml->annunciator [i]->size.height;
      if (gdk_region_rect_in (event->region, & rect) != GDK_OVERLAP_RECTANGLE_OUT)
	{
	  draw_annunciator (d,
			    widget,
			    i,
			    (d->display_segments [i] & SEGMENT_ANN) != 0);
	  region_subtract_rect (event->region, & rect);
	}
    }

  // GDK automatically draws the background for us.
#if 0
  if (! gdk_region_empty (event->region))
  {
    // draw background clipped to the remaining expose region
    gdk_gc_set_clip_region (bg_gc, event->region);
    gdk_draw_rectangle (widget->window,  // drawable
			bg_gc,           // gc
			TRUE,            // filled
			0,               // x
			0,               // y
			d->drawing_area->allocation.width,    // width
			d->drawing_area->allocation.height);  // height
    region_subtract_rect (event->region, & rect);
  }
#endif

  return (TRUE);
}


void gui_display_update (gui_display_t *d,
			 int digit_count,
			 segment_bitmap_t *segments)
{
  int i;
  kml_t *kml = d->csim->kml;
  GdkRectangle rect;
  bool prev_digit_changed = false;

  d->digit_count = digit_count;

  rect.x = kml->digit_offset.x;
  rect.y = kml->digit_offset.y;
  rect.width  = kml->digit_size.width;
  rect.height = kml->digit_size.height;

  for (i = 0; i < digit_count; i++)
    {
      if ((segments [i] & ~ SEGMENT_ANN) ==
	  (d->display_segments [i] & ~ SEGMENT_ANN))
	{
	  if (prev_digit_changed)
	    gdk_window_invalidate_rect (d->drawing_area->window,
					& rect,
					FALSE);
	  prev_digit_changed = false;
	}
      else
	{
	  if (prev_digit_changed)
	    {
	      // grow the rect to include this digit
	      rect.width += kml->digit_size.width;
	    }
	  else
	    {
	      // start a new rect
	      rect.x = (kml->digit_offset.x + i * kml->digit_size.width);
	      rect.width = kml->digit_size.width;
	    }
	  prev_digit_changed = true;
	}
    }

  if (prev_digit_changed)
    {
      gdk_window_invalidate_rect (d->drawing_area->window,
				  & rect,
				  FALSE);
    }

  for (i = 0; i < digit_count; i++)
    if (kml->annunciator [i] &&
	((segments [i] & SEGMENT_ANN) !=
	 (d->display_segments [i] & SEGMENT_ANN)))
      {
	// invalidate annunciator
	rect.x = kml->annunciator [i]->offset.x;
	rect.y = kml->annunciator [i]->offset.y;
	rect.width =  kml->annunciator [i]->size.width;
	rect.height = kml->annunciator [i]->size.height;
	gdk_window_invalidate_rect (d->drawing_area->window,
				    & rect,
				    FALSE);
      }

  // save current segments for comparison next time
  memcpy (d->display_segments, segments,
	  digit_count * sizeof (segment_bitmap_t));

  rect.width = d->drawing_area->allocation.width;
  rect.height = d->drawing_area->allocation.height;
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

static void init_annunciator (gui_display_t *d, int i)
{
  kml_t *kml = d->csim->kml;
  int row_bytes;
  char *xbm_data;
  int xbm_data_size;

  char *p;
  int bitmask;

  int bit;
  int x, y;
  int r, g, b;
  GdkBitmap *bitmap;

  row_bytes = (kml->annunciator [i]->size.width + 7) / 8;

  xbm_data_size = row_bytes * kml->annunciator [i]->size.height + 9;
  // $$$ If we don't add at least 9 bytes of padding,
  // gdk_bitmap_create_from_data() will segfault!
  xbm_data = alloc (xbm_data_size);

  for (y = 0; y < kml->annunciator [i]->size.height; y++)
    {
      p = & xbm_data [y * row_bytes];
#ifdef XBM_LSB_LEFT
      bitmask = 0x01;
#else
      bitmask = 0x80;
#endif
      for (x = 0; x < kml->annunciator [i]->size.width; x++)
	{
	  get_pixbuf_pixel (d->csim->file_pixbuf, 
			    kml->display_offset.x + kml->annunciator [i]->offset.x + x,
			    kml->display_offset.y + kml->annunciator [i]->offset.y + y,
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
					kml->annunciator [i]->size.width,
					kml->annunciator [i]->size.height);

  free (xbm_data);

  d->annunciator_gc [i] = gdk_gc_new (d->drawing_area->window);
  gdk_gc_copy (d->annunciator_gc [i],
	       d->drawing_area->style->fg_gc [GTK_WIDGET_STATE (d->drawing_area)]);
  gdk_gc_set_clip_origin (d->annunciator_gc [i],
			  kml->annunciator [i]->offset.x,
			  kml->annunciator [i]->offset.y);

  gdk_gc_set_clip_mask (d->annunciator_gc [i], bitmap);

  gdk_gc_set_function (d->annunciator_gc [i], GDK_COPY);
  gdk_gc_set_fill (d->annunciator_gc [i], GDK_SOLID);
}


static void init_annunciators (gui_display_t *d)
{
  int i;

  for (i = 0; i < KML_MAX_ANNUNCIATOR; i++)
    if (d->csim->kml->annunciator [i])
      init_annunciator (d, i);
}


static void copy_pixels (GdkPixbuf *src,
			 GdkPixbuf *dest)
{
  int width, height;
  int x, y;

  int src_n_channels, src_rowstride;
  guchar *src_pixels;

  int dest_n_channels, dest_rowstride;
  guchar *dest_pixels;

  g_assert (gdk_pixbuf_get_colorspace (src) == GDK_COLORSPACE_RGB);
  g_assert (gdk_pixbuf_get_bits_per_sample (src) == 8);

  width = gdk_pixbuf_get_width (src);
  height = gdk_pixbuf_get_height (src);

  src_n_channels = gdk_pixbuf_get_n_channels (src);
  src_rowstride = gdk_pixbuf_get_rowstride (src);
  src_pixels = gdk_pixbuf_get_pixels (src);

  dest_n_channels = gdk_pixbuf_get_n_channels (dest);
  dest_rowstride = gdk_pixbuf_get_rowstride (dest);
  dest_pixels = gdk_pixbuf_get_pixels (dest);


  for (y = 0; y < height; y++)
    {
      guchar *sp = src_pixels;
      guchar *dp = dest_pixels;
      for (x = 0; x < width; x++)
	{
	  dp [0] = sp [0];
	  dp [1] = sp [1];
	  dp [2] = sp [2];
	  if (dest_n_channels >= 4)
	    {
	      if (src_n_channels >= 4)
		dp [3] = sp [3];
	      else
		dp [3] = 0xff;
	    }
	  sp += src_n_channels;
	  dp += dest_n_channels;
	}
      src_pixels += src_rowstride;
      dest_pixels += dest_rowstride;
    }
}


static GdkPixbuf *copy_subpixbuf_with_alpha (GdkPixbuf *src_pixbuf,
					     int src_x,
					     int src_y,
					     int width,
					     int height)
{
  GdkPixbuf *sub, *copy;

  sub = gdk_pixbuf_new_subpixbuf (src_pixbuf, src_x, src_y, width, height);
  if (! sub)
    fatal (3, "copy_subpixbuf: error creating subpixbuf\n");

  if (gdk_pixbuf_get_has_alpha (sub))
    {
      copy = gdk_pixbuf_copy (sub);
      if (! copy)
	fatal (3, "copy_subpixbuf: error copying pixbuf\n");
    }
  else
    {
      copy = gdk_pixbuf_new (GDK_COLORSPACE_RGB,
			     TRUE,   // has_alpha
			     8,      // bits_per_sample
			     width,
			     height);
      copy_pixels (sub, copy);
    }

  g_object_unref (sub);

  return copy;
}


typedef void pixel_map_fn_t (uint8_t *r,
			     uint8_t *g,
			     uint8_t *b,
			     uint8_t *a,
			     void *data);


// Iterate over all pixels in a pixbuf, applying a mapping function to
// the pixel value.
static void pixbuf_map_all_pixels (GdkPixbuf *pixbuf,
				   pixel_map_fn_t *map_fn,
				   void *data)
{
  int width, height;
  int rowstride;
  int n_channels;
  int x, y;
  guchar *pixels;

  g_assert (gdk_pixbuf_get_colorspace (pixbuf) == GDK_COLORSPACE_RGB);
  g_assert (gdk_pixbuf_get_bits_per_sample (pixbuf) == 8);

  n_channels = gdk_pixbuf_get_n_channels (pixbuf);

  width = gdk_pixbuf_get_width (pixbuf);
  height = gdk_pixbuf_get_height (pixbuf);

  rowstride = gdk_pixbuf_get_rowstride (pixbuf);
  pixels = gdk_pixbuf_get_pixels (pixbuf);

  for (y = 0; y < height; y++)
    {
      guchar *p = pixels;
      for (x = 0; x < width; x++)
	{
	  if (n_channels >= 4)
	    map_fn (& p[0], & p[1], & p[2], & p[3], data);
	  else
	    {
	      uint8_t dummy = 0xff;
	      map_fn (& p[0], & p[1], & p[2], & dummy, data);
	    }
	  p += n_channels;
	}
      pixels += rowstride;
    }
}


static void color_key (uint8_t *r,
		       uint8_t *g,
		       uint8_t *b,
		       uint8_t *a,
		       void *data)
{
  kml_color_t *color = data;

  if (((*r) == color->r) && ((*g) == color->g) && ((*b) == color->b))
    {
      // match - set pixel to black
      (*r) = 0;
      (*b) = 0;
      (*g) = 0;
    }
  else
    {
      // non-match - set pixel to white
      (*r) = 255;
      (*b) = 255;
      (*g) = 255;
    }
}


static void grey_to_alpha (uint8_t *r,
			   uint8_t *g,
			   uint8_t *b,
			   uint8_t *a,
			   void *data)
{
  uint16_t level;

  // Compute luminance value by averaging R, G, and B (not ideal!).
  level = (*r);
  level += (*b);
  level += (*g);
  level /= 3;

  // Turn luminance into opacity of black.
  (*r) = 0;
  (*b) = 0;
  (*g) = 0;
  (*a) = 255 - level;
}


#ifdef SCALED_SEGMENT_DEBUG
static void show_pixbuf (gui_display_t *d, char *s, GdkPixbuf *pixbuf)
{
  GtkWidget *dialog;
  GtkWidget *image;

  dialog = gtk_dialog_new_with_buttons (s,
					NULL,  // d->main_window,
					GTK_DIALOG_MODAL,
					GTK_STOCK_OK,
					GTK_RESPONSE_NONE,
					NULL);

  image = gtk_image_new_from_pixbuf (pixbuf);

  gtk_container_add (GTK_CONTAINER (GTK_DIALOG (dialog)->vbox), image);

  gtk_widget_show_all (dialog);

  gtk_dialog_run (GTK_DIALOG (dialog));

  gtk_widget_destroy (dialog);
}
#endif


// Used only for segments of type "scaled".  Extracts the segment image
// from the template based on color, and scales it down into a new
// pixbuf.
static void init_segment (gui_display_t *d, int i)
{
  kml_t *kml = d->csim->kml;
  GdkPixbuf *full_size_pixbuf;
  double scale_x, scale_y;

  full_size_pixbuf = copy_subpixbuf_with_alpha (d->csim->file_pixbuf,
						kml->segment [i]->offset.x,
						kml->segment [i]->offset.y,
						kml->segment [i]->size.width,
						kml->segment [i]->size.height);

#ifdef SCALED_SEGMENT_DEBUG
  show_pixbuf (d, "full size orig", full_size_pixbuf);
#endif

  pixbuf_map_all_pixels (full_size_pixbuf,
			 color_key,
			 & kml->segment [i]->color);

#ifdef SCALED_SEGMENT_DEBUG
  show_pixbuf (d, "full size mapped", full_size_pixbuf);
#endif

  d->segment_pixbuf [i] = gdk_pixbuf_new (GDK_COLORSPACE_RGB,
					  TRUE,   // has_alpha
					  8,      // bits_per_sample
					  kml->digit_size.width,
					  kml->digit_size.height);

  scale_x = (kml->digit_size.width * 1.0) / kml->segment [i]->size.width;
  scale_y = (kml->digit_size.height * 1.0) / kml->segment [i]->size.height;

  // Scale the pixbuf down to the final size.
  // Note that GDK_INTERP_HYPER is slow but results in high quality.
  // This is OK since we're only pre-rendering the segments once at
  // startup.
  gdk_pixbuf_scale (full_size_pixbuf,            // src
		    d->segment_pixbuf [i],       // dest
		    0,                           // dest_x
		    0,                           // dest_y
		    kml->digit_size.width,    // dest_width
		    kml->digit_size.height,   // dest_height
		    0,                           // offset_x
		    0,                           // offset_y
		    scale_x,
		    scale_y,
		    GDK_INTERP_HYPER);           // interp_type

#ifdef SCALED_SEGMENT_DEBUG
  show_pixbuf (d, "scaled", d->segment_pixbuf [i]);
#endif

  // Convert pixbuf grey level to alpha
  pixbuf_map_all_pixels (d->segment_pixbuf [i],
			 grey_to_alpha,
			 NULL);

#ifdef SCALED_SEGMENT_DEBUG
  show_pixbuf (d, "mapped", d->segment_pixbuf [i]);
#endif

  g_object_unref (full_size_pixbuf);
}


static void init_segments (gui_display_t *d)
{
  int i;

  for (i = 0; i < KML_MAX_SEGMENT; i++)
    if (d->csim->kml->segment [i] &&
	(d->csim->kml->segment [i]->type == kml_segment_type_scaled))
      init_segment (d, i);
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


gui_display_t * gui_display_init (csim_t *csim)
{
  gui_display_t *d;
  GdkColormap *colormap;
  GdkColor image_bg_color;
  GdkColor display_fg_color, display_bg_color;

  d = alloc (sizeof (gui_display_t));

  d->csim = csim;

  d->drawing_area = gtk_drawing_area_new ();

  colormap = gtk_widget_get_colormap (csim->main_window);
  setup_color (colormap, csim->kml->global_color [0], & image_bg_color,
	       "image background", 0x3333, 0x3333, 0x3333);

  gtk_widget_modify_bg (csim->event_box, GTK_STATE_NORMAL, & image_bg_color);

  setup_color (colormap, csim->kml->display_color [0], & display_bg_color,
	       "display background", 0x0000, 0x0000, 0x0000);

  setup_color (colormap, csim->kml->display_color [2], & display_fg_color,
	       "display foreground", 0xffff, 0x1111, 0x1111);

  gtk_widget_set_size_request (d->drawing_area,
			       csim->kml->display_size.width,
			       csim->kml->display_size.height);
  gtk_widget_modify_fg (d->drawing_area, GTK_STATE_NORMAL, & display_fg_color);
  gtk_widget_modify_bg (d->drawing_area, GTK_STATE_NORMAL, & display_bg_color);
  gtk_fixed_put (GTK_FIXED (csim->fixed),
		 d->drawing_area,
		 csim->kml->display_offset.x - csim->kml->background_offset.x,
		 csim->kml->display_offset.y - csim->kml->background_offset.y);

  init_annunciators (d);

  init_segments (d);

  g_signal_connect (G_OBJECT (d->drawing_area),
		    "expose_event",
		    G_CALLBACK (display_expose_event_callback),
		    d);

  return d;
}
