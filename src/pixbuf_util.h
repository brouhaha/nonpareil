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

GdkPixbuf* new_pixbuf_from_png_array (const uint8_t *p, size_t len);

typedef void pixel_map_fn_t (uint8_t *r,
			     uint8_t *g,
			     uint8_t *b,
			     uint8_t *a,
			     void *data);

void pixbuf_map_all_pixels (GdkPixbuf *pixbuf,
			    pixel_map_fn_t *map_fn,
			    void *data);

pixel_map_fn_t pixbuf_map_color_key;
pixel_map_fn_t pixbuf_map_grey_to_alpha;
