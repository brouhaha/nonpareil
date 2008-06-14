/*
$Id$
Copyright 2004, 2005, 2006, 2008 Eric Smith <eric@brouhaha.com>

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


#define SA 0x0001
#define SB 0x0002
#define SC 0x0004
#define SD 0x0008
#define SE 0x0010
#define SF 0x0020
#define SG 0x0040
#define SH 0x0080
#define SI 0x0100
#define SJ 0x0200
#define SK 0x0400
#define SL 0x0800
#define SM 0x1000
#define SN 0x2000

segment_bitmap_t character_segment_map [128] =
  {
//  [0xxx] = SA+SB+SC+SD+SE+SF+SG+SH+SI+SJ+SK+SL+SM+SN,
    [0x00] = SA+SB+   SD+SE+SF+   SH+SI,
    [0x01] = SA+SB+SC+   SE+SF+SG+SH,
    [0x02] = SA+SB+SC+SD+         SH+SI+SJ,
    [0x03] = SA+      SD+SE+SF,
    [0x04] = SA+SB+SC+SD+            SI+SJ,
    [0x05] = SA+      SD+SE+SF+SG+SH,
    [0x06] = SA+         SE+SF+SG+SH,
    [0x07] = SA+   SC+SD+SE+SF+   SH,

    [0x08] =    SB+SC+   SE+SF+SG+SH,
    [0x09] = SA+      SD+            SI+SJ,
    [0x0a] =    SB+SC+SD+SE,
    [0x0b] =             SE+SF+SG+         SK+   SM,
    [0x0c] =          SD+SE+SF,
    [0x0d] =    SB+SC+   SE+SF+            SK+SL,
    [0x0e] =    SB+SC+   SE+SF+               SL+SM,
    [0x0f] = SA+SB+SC+SD+SE+SF,

    [0x10] = SA+SB+      SE+SF+SG+SH,
    [0x11] = SA+SB+SC+SD+SE+SF+                  SM,
    [0x12] = SA+SB+      SE+SF+SG+SH+            SM,
    [0x13] = SA+   SC+SD+   SF+SG+SH,
    [0x14] = SA+                     SI+SJ,
    [0x15] =    SB+SC+SD+SE+SF,
    [0x16] =             SE+SF+            SK+      SN,
    [0x17] =    SB+SC+   SE+SF+                  SM+SN,

    [0x18] =                               SK+SL+SM+SN,
    [0x19] =                            SJ+SK+SL,
    [0x1a] = SA+      SD+                  SK+      SN,
    [0x1b] = SA+      SD+SE+SF,
    [0x1c] =                                  SL+SM,
    [0x1d] = SA+SB+SC+SD,
    [0x1e] = SA+SB+                        SK+      SN,
    [0x1f] =          SD,

    [0x20] = 0,
    [0x21] =                         SI+SJ,
    [0x22] =                SF+      SI,
    [0x23] =    SB+SC+SD+      SG+SH+SI+SJ,
    [0x24] = SA+   SC+SD+   SF+SG+SH+SI+SJ,
    [0x25] =       SC+      SF+SG+SH+      SK+SL+SM+SN,
    [0x26] = SA+   SC+SD+                  SK+SL+SM+SN,
    [0x27] =                         SI,

    [0x28] =                               SK+   SM,
    [0x29] =                                  SL+   SN,
    [0x2a] =                   SG+SH+SI+SJ+SK+SL+SM+SN,
    [0x2b] =                   SG+SH+SI+SJ,
    [0x2c] =                   SG+SH+      SK+   SM,
    [0x2d] =                   SG+SH,
    [0x2e] =                   SG+SH+         SL+   SN,
    [0x2f] =                               SK+      SN,

    [0x30] = SA+SB+SC+SD+SE+SF+            SK+      SN,
    [0x31] =    SB+SC,
    [0x32] = SA+SB+   SD+SE+   SG+SH,
    [0x33] = SA+SB+SC+SD+      SG+SH,
    [0x34] =    SB+SC+      SF+SG+SH,
    [0x35] = SA+   SC+SD+         SH+         SL,
    [0x36] = SA+   SC+SD+SE+SF+SG+SH,
    [0x37] = SA+SB+SC,

    [0x38] = SA+SB+SC+SD+SE+SF+SG+SH,
    [0x39] = SA+SB+SC+SD+   SF+SG+SH,
    [0x3a] = SA+SB+SC+SD+SE+SF+SG+SH+SI+SJ+SK+SL+SM+SN,  // FUL starburst (all segs)
    [0x3b] =                   SG+                  SN,  // SEM ;
    [0x3c] =          SD+                  SK+      SN,  // <
    [0x3d] =          SD+      SG+SH,                    // =
    [0x3e] =          SD+                     SL+SM,     // >
    [0x3f] = SA+SB+         SF+   SH+   SJ,              // ?

    [0x40] =             SE+SF+SG+SH,                    // APP lazy T
    [0x41] =       SC+SD+SE+   SG+               SM,     // a
    [0x42] =       SC+SD+SE+SF+SG+SH,                    // b
    [0x43] =          SD+SE+   SG+SH,                    // c
    [0x44] =    SB+SC+SD+SE+   SG+SH,                    // d
    [0x45] =          SD+SE+   SG+                  SN,  // e
    [0x46] = SA,                                         // OVE overbar (hangman head only)
    [0x47] = SA+                     SI,                 // SUP high-T (hangman neck)

    [0x48] = SA+                     SI+            SN,  // HAN left leg
    [0x49] = SA+                     SI+         SM+SN,  // HAN right leg
    [0x4a] = SA+               SG+   SI+         SM+SN,  // HAN left arm
    [0x4b] = SA+               SG+SH+SI+         SM+SN,  // HAN right arm (full hangman)
    [0x4c] =    SB+               SH+SI+            SN,  // MIC Greek mu
    [0x4d] =          SD+      SG+SH+      SK+      SN,  // NOT not equal
    [0x4e] = SA+      SD+                     SL+   SN,  // SIG Greek Sigma
    [0x4f] =          SD+               SJ+SK+      SN,  // ANG angle symbol

    // Halfnut models have additonal characters 0x50 through 0x7f, which
    // display as spaces on fullnuts.  See CHHU Chronicle V2N4 for
    // details.

    [0x50] =                   SG+SH+            SM+SN,  // DC1 pi          (user 0x11)
    [0x51] =          SD+                        SM+SN,  // BEL Greek alpha (user 0x07)
    [0x52] = SA+      SD+         SH+      SK+   SM+SN,  // BAC Greek beta  (user 0x08)
    [0x53] =                   SG+SH+   SJ,              // HTA Greek gamma (user 0x09)
    [0x54] =                SF+SG+SH+   SJ+      SM,     // UN
    [0x55] =             SE+   SG+SH+               SN,  // VTA Greek sigma (user 0x0b)
    [0x56] = SA,                                         // OVE overbar (dupl. 0x46)
    [0x57] = SA+SB+      SE+SF,                          // ESC Greek Gamma (user 0x1b)

    [0x58] = SA+                     SI+            SN,  // HAN left leg  (dupl. 0x48)
    [0x59] = SA+                     SI+         SM+SN,  // HAN rigth leg (dupl. 0x49)
    [0x5a] = SA+               SG+   SI+         SM+SN,  // HAN left arm  (dupl. 0x4a)
    [0x5b] = SA+               SG+SH+SI+         SM+SN,  // HAN rigth arm (dupl. 0x4b)
    [0x5c] =    SB+               SH+SI+            SN,  // MIC Greek mu  (dupl. 0x4c)
    [0x5d] =          SD+      SG+SH+      SK+      SN,  // NOT not equal (dupl. 0x4d)
    [0x5e] =                                  SL+SM+SN,  // DC3 Greek lamda (user 0x13)
    [0x5f] =          SD+               SJ+SK+      SN,  // ANG angle sym (dupl 0x4f)

    [0x60] = SA+                     SI,                 // SUP high-T    (dupl 0x47)
    [0x61] =       SC+SD+SE+   SG+               SM,     // a             (dupl 0x41)
    [0x62] =       SC+SD+SE+SF+SG+SH,                    // b             (dupl 0x42)
    [0x63] =          SD+SE+   SG+SH,                    // c             (dupl 0x43)
    [0x64] =    SB+SC+SD+SE+   SG+SH,                    // d             (dupl 0x44)
    [0x65] =          SD+SE+   SG+                  SN,  // e             (dupl 0x45)
    [0x66] =                      SH+   SJ+SK,           // f
    [0x67] =       SC+SD+         SH+            SM,     // g

    [0x68] =       SC+   SE+SF+SG+SH,                    // h
    [0x69] =             SE,                             // i
    [0x6a] =       SC+SD,                                // j
    [0x6b] =             SE+SF+SG+SH+            SM,     // k
    [0x6c] =             SE+SF,                          // l
    [0x6d] =       SC+   SE+   SG+SH+   SJ,              // m
    [0x6e] =       SC+   SE+   SG+SH,                    // n
    [0x6f] =       SC+SD+SE+   SG+SH,                    // o

    [0x70] =             SE+SF+SG+            SL,        // p
    [0x71] =                SF+SG+            SL+SM,     // q
    [0x72] =             SE+   SG+SH,                    // r
    [0x73] =          SD+         SH+            SM,     // s
    [0x74] =                SG+SH+SI+            SM,     // t
    [0x75] =       SC+SD+SE,                             // u
    [0x76] =             SE+                        SN,  // v
    [0x77] =       SC+   SE+                     SM+SN,  // w

    [0x78] =                   SG+SH+   SJ+         SN,  // x
    [0x79] =       SC+SD+                        SM,     // y
    [0x7a] =          SD+      SG+                  SN,  // z
    [0x7b] =                      SH+      SK+   SM,     // LEF {
    [0x7c] =          SD+                  SK+   SM+SN,  // DEL Greek Delta
    [0x7d] =                   SG+            SL+   SN,  // RIG }
    [0x7e] = SA+      SD+                     SL+   SN,  // SIG Greek Sigma (dupl. 0x4e)
    [0x7f] =             SE+SF+SG+SH                     // APP lazy T (dupl. 0x40)
  };


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

  segments = character_segment_map [m];

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

  g_type_init ();

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

  if ((! kml->segment_image_fn) && (! kml->image_fn))
    fatal (2, "No image file spsecified in KML\n");

  image_path = newstr (kml_name);
  chop_tail (image_path);

  if (kml->segment_image_fn)
    image_fn = find_file_in_path_list (kml->segment_image_fn, NULL, image_path);
  else
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
