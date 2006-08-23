/*
$Id$
Copyright 2005, 2006 Eric L. Smith <eric@brouhaha.com>

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

#include <gdk/gdk.h>
#include <gtk/gtk.h>

#include "util.h"
#include "pixbuf_util.h"


GdkPixbuf* new_pixbuf_from_png_array (const uint8_t *p, size_t len)
{
  GError *error = NULL;
  GdkPixbuf *pixbuf;
  GdkPixbufLoader *loader;

  loader = gdk_pixbuf_loader_new ();
  if (! loader)
    return NULL;
  if (! gdk_pixbuf_loader_write (loader, p, len, & error))
    return NULL;
  if (! gdk_pixbuf_loader_close (loader, & error))
    return NULL;

  pixbuf = gdk_pixbuf_loader_get_pixbuf (loader);

  return (pixbuf);
}


// Iterate over all pixels in a pixbuf, applying a mapping function to
// the pixel value.
void pixbuf_map_all_pixels (GdkPixbuf *pixbuf,
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


void pixbuf_map_color_key (uint8_t *r,
			   uint8_t *g,
			   uint8_t *b,
			   uint8_t *a UNUSED,
			   void *data)
{
  color_t *color = data;

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


void pixbuf_map_grey_to_alpha (uint8_t *r,
			       uint8_t *g,
			       uint8_t *b,
			       uint8_t *a,
			       void *data)
{
  color_t *color = data;
  uint16_t level;

  // Compute luminance value by averaging R, G, and B (not ideal!).
  level = (*r);
  level += (*b);
  level += (*g);
  level /= 3;

  // Turn luminance into opacity of black.
  (*r) = color ? color->r : 0;
  (*b) = color ? color->g : 0;
  (*g) = color ? color->b : 0;
  (*a) = 255 - level;
}
