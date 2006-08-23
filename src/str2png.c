/*
$Id$
Copyright 2004, 2005, 2006 Eric L. Smith <eric@brouhaha.com>

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

#include <inttypes.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <gdk/gdk.h>

#include <gsf/gsf-infile.h>

#include "util.h"
#include "display.h"
#include "kml.h"
#include "scancode.h"
#include "pixbuf_util.h"


char *default_path = MAKESTR(DEFAULT_PATH);


void usage (FILE *f)
{
  fprintf (f, "%s:  Microcode-level calculator simulator\n",
	   nonpareil_release);
  fprintf (f, "Copyright 2004, 2005 Eric L. Smith\n");
  fprintf (f, "http://nonpareil.brouhaha.com/\n");
  fprintf (f, "\n");
  fprintf (f, "usage: %s [options] kmlfile \"string\" pngfile\n", progname);
  fprintf (f, "options:\n");
  fprintf (f, "  -x <size>      horizontal character size in pixels\n");
  fprintf (f, "  -y <size>      vertical character size in pixels\n");
  fprintf (f, "  -m <size>      margin in pixels\n");
}


kml_t *kml;
GError *error = NULL;
GdkPixbuf *file_pixbuf;  /* the entire image loaded from the file */
GdkPixbuf *segment_pixbuf [KML_MAX_SEGMENT];
GdkPixbuf *render_pixbuf;


// We don't care about scancodes.
int get_scancode_from_name (char *scancode_name)
{
  return 0;
}


static void fill_pixbuf (GdkPixbuf *dest,
			 uint8_t r,
			 uint8_t g,
			 uint8_t b,
			 uint8_t a)
{
  int width, height;
  int x, y;

  int dest_n_channels, dest_rowstride;
  guchar *dest_pixels;

  g_assert (gdk_pixbuf_get_colorspace (dest) == GDK_COLORSPACE_RGB);
  g_assert (gdk_pixbuf_get_bits_per_sample (dest) == 8);

  width = gdk_pixbuf_get_width (dest);
  height = gdk_pixbuf_get_height (dest);

  dest_n_channels = gdk_pixbuf_get_n_channels (dest);
  dest_rowstride = gdk_pixbuf_get_rowstride (dest);
  dest_pixels = gdk_pixbuf_get_pixels (dest);

  for (y = 0; y < height; y++)
    {
      guchar *dp = dest_pixels;
      for (x = 0; x < width; x++)
	{
	  dp [0] = r;
	  dp [1] = g;
	  dp [2] = b;
	  if (dest_n_channels >= 4)
	    dp [3] = a;
	  dp += dest_n_channels;
	}
      dest_pixels += dest_rowstride;
    }
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


// Used only for segments of type "scaled".  Extracts the segment image
// from the template based on color, and scales it down into a new
// pixbuf.
static void init_segment (int i)
{
  GdkPixbuf *full_size_pixbuf;
  double scale_x, scale_y;

  full_size_pixbuf = copy_subpixbuf_with_alpha (file_pixbuf,
						kml->segment_image_offset.x,
						kml->segment_image_offset.y,
						kml->segment_image_size.width,
						kml->segment_image_size.height);

#ifdef SCALED_SEGMENT_DEBUG
  show_pixbuf (d, "full size orig", full_size_pixbuf);
#endif

  pixbuf_map_all_pixels (full_size_pixbuf,
			 pixbuf_map_color_key,
			 & kml->segment [i]->color);

#ifdef SCALED_SEGMENT_DEBUG
  show_pixbuf (d, "full size mapped", full_size_pixbuf);
#endif

  segment_pixbuf [i] = gdk_pixbuf_new (GDK_COLORSPACE_RGB,
				       TRUE,   // has_alpha
				       8,      // bits_per_sample
				       kml->digit_size.width,
				       kml->digit_size.height);

  scale_x = (kml->digit_size.width * 1.0) / kml->segment_image_size.width;
  scale_y = (kml->digit_size.height * 1.0) / kml->segment_image_size.height;

  // Scale the pixbuf down to the final size.
  // Note that GDK_INTERP_HYPER is slow but results in high quality.
  // This is OK since we're only pre-rendering the segments once at
  // startup.
  gdk_pixbuf_scale (full_size_pixbuf,            // src
		    segment_pixbuf [i],       // dest
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
  show_pixbuf (d, "scaled", segment_pixbuf [i]);
#endif

  // Convert pixbuf grey level to alpha
  pixbuf_map_all_pixels (segment_pixbuf [i],
			 pixbuf_map_grey_to_alpha,
			 NULL);

#ifdef SCALED_SEGMENT_DEBUG
  show_pixbuf (d, "mapped", segment_pixbuf [i]);
#endif

  g_object_unref (full_size_pixbuf);
}


static void init_segments (void)
{
  int i;

  for (i = 0; i < KML_MAX_SEGMENT; i++)
    /* if (kml->segment [i]->type == kml_segment_type_scaled) */
      init_segment (i);
}


void draw_char (int x, int y, char c)
{
  unsigned char m;
  int i;
  segment_bitmap_t segments;

  // map from ASCII to 41 char set, sort of
  if ((c >= '@') && (c <= '_'))
    m = c - '@';
  else if ((c >= ' ') && (c <= '?'))
    m = c;
  else if ((c >= 'a') && (c <= '~'))
    m = c;

  segments = kml->character_segment_map [m];

  for (i = 0; i < KML_MAX_SEGMENT; i++)
    {
      if ((segments & (1 << i)) && (kml->segment [i]))
	gdk_pixbuf_composite (segment_pixbuf [i],
			      render_pixbuf,
			      x,
			      y,
			      kml->digit_size.width,
			      kml->digit_size.height,
			      x,  // offset_x
			      y,  // offset_y
			      1,  // scale_x
			      1,  // scale_y
			      GDK_INTERP_NEAREST,  // scale is 1:1
			      255);  // overall_alpha
    }
}


void chop_tail (char *p)
{
  char *p2 = strrchr (p, '/');
  if (p2)
    *p2 = '\0';
}


int main (int argc, char *argv[])
{
  char *kml_name = NULL;
  char *str = NULL;
  char *png_fn = NULL;
  int x_size = 0;
  int y_size = 0;
  int margin = 0;

  char *kml_fn;
  char *image_fn;
  char *image_path;
  int i;

  progname = newstr (argv [0]);

  gdk_init (& argc, & argv);

  while (--argc)
    {
      argv++;
      if (*argv [0] == '-')
	{
	  if (strcmp (argv [0], "-x") == 0)
	    {
	      if (! --argc)
		fatal (1, NULL);
	      argv++;
	      x_size = atoi (argv [0]);
	    }
	  else if (strcmp (argv [0], "-y") == 0)
	    {
	      if (! --argc)
		fatal (1, NULL);
	      argv++;
	      y_size = atoi (argv [0]);
	    }
	  else if (strcmp (argv [0], "-m") == 0)
	    {
	      if (! --argc)
		fatal (1, NULL);
	      argv++;
	      margin = atoi (argv [0]);
	    }
	  else
	    fatal (1, "unrecognized option '%s'\n", argv [0]);
	}
      else if (! kml_name)
	kml_name = argv [0];
      else if (! str)
	str = argv [0];
      else if (! png_fn)
	png_fn = argv [0];
      else
	fatal (1, NULL);
    }

  if (! (kml_name && str && png_fn))
    fatal (1, NULL);

  kml_fn = find_file_in_path_list (kml_name, ".kml", default_path);
  if (! kml_fn)
    fatal (2, "can't find KML file '%s'\n", kml_name);

  kml = read_kml_file (kml_fn);
  if (! kml)
    fatal (2, "can't read KML file '%s'\n", kml_fn);

  if (x_size)
    kml->digit_size.width = x_size;

  if (y_size)
    kml->digit_size.height = y_size;

  if (! kml->image_fn)
    fatal (2, "No image file spsecified in KML\n");

  image_path = newstr (kml_name);
  chop_tail (image_path);

  chop_tail (image_path);  // HACK: 41c.png is in directory above 41cv.kml

  image_fn = find_file_in_path_list (kml->image_fn, NULL, image_path);
  if (! image_fn)
    fatal (2, "can't find image file '%s'\n", kml->image_fn);

  file_pixbuf = gdk_pixbuf_new_from_file (image_fn, & error);
  if (! file_pixbuf)
    fatal (2, "can't load image '%s'\n", image_fn);

  init_segments ();

  render_pixbuf = gdk_pixbuf_new (GDK_COLORSPACE_RGB,
				  TRUE,
				  8,
				  2 * margin + strlen (str) * kml->digit_size.width,
				  2 * margin + kml->digit_size.height);

  // fill pixbuf with color kml->display_color [0]
  fill_pixbuf (render_pixbuf,
	       kml->display_color [0]->r,
	       kml->display_color [0]->g,
	       kml->display_color [0]->b,
	       0);  // alpha 0 = transparent, 255 = opaque

  // render segments with color kml->display_color [2]
  for (i = 0; str [i]; i++)
    draw_char (margin + i * kml->digit_size.width, margin, str [i]);

  gdk_pixbuf_save (render_pixbuf,
		   png_fn,
		   "png",
		   & error,
		   NULL);

  exit (0);
}
