/*
CSIM is a simulator for the processor used in the HP "Classic" series
of calculators, which includes the HP-35, HP-45, HP-55, HP-65, HP-70,
and HP-80.

$Id$
Copyright 1995, 2004 Eric L. Smith

CSIM is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License version 2 as published by the Free
Software Foundation.  Note that I am not granting permission to redistribute
or modify CSIM under the terms of any later version of the General Public
License.

This program is distributed in the hope that it will be useful (or at least
amusing), but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with
this program (in the file "COPYING"); if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <gdk/gdk.h>
#include <gtk/gtk.h>


char * progn;


/* generate fatal error message to stderr, doesn't return */
void fatal (int ret, char *format, ...)
{
  va_list ap;

  fprintf (stderr, "fatal error: ");
  va_start (ap, format);
  vfprintf (stderr, format, ap);
  va_end (ap);
  if (ret == 1)
    fprintf (stderr, "usage: %s objectfile\n", progn);
  exit (ret);
}


char *newstr (char *orig)
{
  int len;
  char *r;

  len = strlen (orig);
  r = (char *) malloc (len + 1);
  
  if (! r)
    fatal (2, "memory allocation failed\n");

  memcpy (r, orig, len + 1);
  return (r);
}


typedef struct
{
  GdkRectangle rect;
  int keycode;
} keyinfo;


keyinfo (*keys)[35];


keyinfo keys_hp35 [35] =
{
  {{  24, 120, 30, 24 }, 006 },
  {{  72, 120, 30, 24 }, 004 },
  {{ 120, 120, 30, 24 }, 003 },
  {{ 168, 120, 30, 24 }, 002 },
  {{ 216, 120, 30, 24 }, 000 },

  {{  24, 168, 30, 24 }, 056 },
  {{  72, 168, 30, 24 }, 054 },
  {{ 120, 168, 30, 24 }, 053 },
  {{ 168, 168, 30, 24 }, 052 },
  {{ 216, 168, 30, 24 }, 050 },

  {{  24, 216, 30, 24 }, 016 },
  {{  72, 216, 30, 24 }, 014 },
  {{ 120, 216, 30, 24 }, 013 },
  {{ 168, 216, 30, 24 }, 012 },
  {{ 216, 216, 30, 24 }, 010 },

  {{  24, 264, 78, 24 }, 076 },
  {{ 120, 264, 30, 24 }, 073 },
  {{ 168, 264, 30, 24 }, 072 },
  {{ 216, 264, 30, 24 }, 070 },

  {{  24, 312, 24, 24 }, 066},
  {{  73, 312, 37, 24 }, 064 },
  {{ 141, 312, 37, 24 }, 063 },
  {{ 209, 312, 37, 24 }, 062 },

  {{  24, 360, 24, 24 }, 026},
  {{  73, 360, 37, 24 }, 024 },
  {{ 141, 360, 37, 24 }, 023 },
  {{ 209, 360, 37, 24 }, 022 },

  {{  24, 408, 24, 24 }, 036 },
  {{  73, 408, 37, 24 }, 034 },
  {{ 141, 408, 37, 24 }, 033 },
  {{ 209, 408, 37, 24 }, 032 },

  {{  24, 456, 24, 24 }, 046 },
  {{  73, 456, 37, 24 }, 044 },
  {{ 141, 456, 37, 24 }, 043 },
  {{ 209, 456, 37, 24 }, 042 },
};

keyinfo keys_hp45 [35] =
{
  {{  48, 156, 32, 24 }, 006 },
  {{  91, 156, 32, 24 }, 004 },
  {{ 134, 156, 32, 24 }, 003 },
  {{ 176, 156, 32, 24 }, 002 },
  {{ 219, 156, 32, 24 }, 000 },

  {{  48, 201, 32, 24 }, 056 },
  {{  91, 201, 32, 24 }, 054 },
  {{ 134, 201, 32, 24 }, 053 },
  {{ 176, 201, 32, 24 }, 052 },
  {{ 219, 201, 32, 24 }, 050 },

  {{  48, 246, 32, 24 }, 016 },
  {{  91, 246, 32, 24 }, 014 },
  {{ 134, 246, 32, 24 }, 013 },
  {{ 176, 246, 32, 24 }, 012 },
  {{ 219, 246, 32, 24 }, 010 },

#if ENTER_KEY_MOD
  {{  48, 291, 74, 24 }, 074 },
#else
  {{  48, 291, 74, 24 }, 075 },
#endif /* ENTER_KEY_MOD */
  {{ 134, 291, 32, 24 }, 073 },
  {{ 176, 291, 32, 24 }, 072 },
  {{ 219, 291, 32, 24 }, 070 },

  {{  48, 336, 24, 24 }, 066 },
  {{  92, 336, 36, 24 }, 064 },
  {{ 153, 336, 36, 24 }, 063 },
  {{ 214, 336, 36, 24 }, 062 },

  {{  48, 381, 24, 24 }, 026 },
  {{  92, 381, 36, 24 }, 024 },
  {{ 153, 381, 36, 24 }, 023 },
  {{ 214, 381, 36, 24 }, 022 },

  {{  48, 425, 24, 24 }, 036 },
  {{  92, 425, 36, 24 }, 034 },
  {{ 153, 425, 36, 24 }, 033 },
  {{ 214, 425, 36, 24 }, 032 },

  {{  48, 470, 24, 24 }, 046 },
  {{  92, 470, 36, 24 }, 044 },
  {{ 153, 470, 36, 24 }, 043 },
  {{ 214, 470, 36, 24 }, 042 },
};

keyinfo keys_hp55 [35] =
{
  {{  28, 120, 36, 24 }, 006 },
  {{  85, 120, 36, 24 }, 004 },
  {{ 142, 120, 36, 24 }, 003 },
  {{ 199, 120, 36, 24 }, 002 },
  {{ 256, 120, 36, 24 }, 000 },

  {{  28, 168, 36, 24 }, 056 },
  {{  85, 168, 36, 24 }, 054 },
  {{ 142, 168, 36, 24 }, 053 },
  {{ 199, 168, 36, 24 }, 052 },
  {{ 256, 168, 36, 24 }, 050 },

  {{  28, 216, 36, 24 }, 016 },
  {{  85, 216, 36, 24 }, 014 },
  {{ 142, 216, 36, 24 }, 013 },
  {{ 199, 216, 36, 24 }, 012 },
  {{ 256, 216, 36, 24 }, 010 },

  {{  28, 264, 92, 24 }, 075 },
  {{ 142, 264, 36, 24 }, 073 },
  {{ 199, 264, 36, 24 }, 072 },
  {{ 256, 264, 36, 24 }, 070 },

  {{  28, 312, 28, 24 }, 066 },
  {{  87, 312, 44, 24 }, 064 },
  {{ 167, 312, 44, 24 }, 063 },
  {{ 248, 312, 44, 24 }, 062 },

  {{  28, 360, 28, 24 }, 026 },
  {{  87, 360, 44, 24 }, 024 },
  {{ 167, 360, 44, 24 }, 023 },
  {{ 248, 360, 44, 24 }, 022 },

  {{  28, 408, 28, 24 }, 036 },
  {{  87, 408, 44, 24 }, 034 },
  {{ 167, 408, 44, 24 }, 033 },
  {{ 248, 408, 44, 24 }, 032 },

  {{  28, 456, 28, 24 }, 046 },
  {{  87, 456, 44, 24 }, 044 },
  {{ 167, 456, 44, 24 }, 043 },
  {{ 248, 456, 44, 24 }, 042 },
};


typedef struct
{
  GtkWidget *fixed;
  int keycode;
} button_info_t;


void button_pressed (GtkWidget *widget, button_info_t *button)
{
  printf ("pressed %d\n", button->keycode);
}


void button_released (GtkWidget *widget, button_info_t *button)
{
  printf ("released %d\n", button->keycode);
}


void add_key (GtkWidget *fixed,
	      GdkPixbuf *window_pixbuf,
	      keyinfo *key)
{
  GtkWidget *button;
  GdkPixbuf *button_pixbuf;
  GtkWidget *button_image;
  button_info_t *button_info;

  button_pixbuf = gdk_pixbuf_new_subpixbuf (window_pixbuf,
					    key->rect.x,
					    key->rect.y,
					    key->rect.width,
					    key->rect.height);

  button_image = gtk_image_new_from_pixbuf (button_pixbuf);
  gtk_widget_show (button_image);

  button_info = calloc (1, sizeof (button_info_t));
  /* $$$ check for failed */

  button_info->fixed = fixed;
  button_info->keycode = key->keycode;
  
  button = gtk_button_new ();

  gtk_button_set_relief (GTK_BUTTON (button), GTK_RELIEF_NONE);

  gtk_widget_set_size_request (button, key->rect.width, key->rect.height);

  gtk_fixed_put (GTK_FIXED (fixed), button, key->rect.x, key->rect.y);

  g_signal_connect (G_OBJECT (button),
		    "pressed",
		    G_CALLBACK (& button_pressed),
		    (gpointer) button_info);
  g_signal_connect (G_OBJECT (button),
		    "released",
		    G_CALLBACK (& button_released),
		    (gpointer) button_info);

  gtk_widget_show (button);

  gtk_container_add (GTK_CONTAINER (button), button_image);
}


void add_keys (GdkPixbuf *window_pixbuf, GtkWidget *fixed)
{
  int i;

  for (i = 0; i < (sizeof (keys_hp45) / sizeof (keyinfo)); i++)
    add_key (fixed, window_pixbuf, & keys_hp45 [i]);
}


#if 0
void repaint_display (void *d)
{
  GtkWidget *drawing_area = (GtkWidget *) d;
  if (! drawing_area)
    fatal (2, "where'd the display drawing area go?\n");
  if (! font)
    font = gdk_font_load ("fixed");

  gdk_draw_rectangle (pixmap,
		      drawing_area->style->white_gc,
		      x,
		      y,
		      width,
		      height);
  gdk_draw_string (pixmap, font, s);

  update_rect.x = 0;
  update_rect.y = 0;
  update_rect.width = drawing_area->allocation.width;
  update_rect.height = drawing_area->allocation.height;

  gtk_widget_draw (drawing_area, & update_rect);
}
#endif


#ifndef PATH_MAX
#define PATH_MAX 256
#endif


int main (int argc, char *argv[])
{
#if 0
  char *objfn = NULL;
  FILE *f;
  char buf [PATH_MAX];
#endif

  int window_width, window_height;

  GtkWidget *window;
  GtkWidget *fixed;
  GtkWidget *display;

  GdkPixbuf *image_pixbuf;
  GError *error = NULL;
  GtkWidget *image;

 
  progn = newstr (argv [0]);

#if 0
  while (--argc)
    {
      argv++;
      if (*argv [0] == '-')
	{
	  if (strcasecmp (argv [0], "-stop") == 0)
	    run = 0;
	  else if (strcasecmp (argv [0], "-trace") == 0)
	    trace = 1;
	  else
	    fatal (1, "unrecognized option '%s'\n", argv [0]);
	}
      else if (objfn)
	fatal (1, "only one listing file may be specified\n");
      else
	objfn = argv [0];
    }

  if (objfn)
    {
      f = fopen (objfn, "r");
      if (! f)
	fatal (2, "unable to read listing file '%s'\n", objfn);
    }
  else
    {
      strcpy (buf, progn);
      strcat (buf, ".lst");
      objfn = & buf [0];
      f = fopen (buf, "r");
      if (! f)
	fatal (2, "listing file must be specified\n");
    }
#endif

  gtk_init (& argc, & argv);

  image_pixbuf = gdk_pixbuf_new_from_file ("hp45.jpg", & error);
  if (! image_pixbuf)
    fatal (2, "can't load image\n");

  window_width = gdk_pixbuf_get_width (image_pixbuf);
  window_height = gdk_pixbuf_get_height (image_pixbuf);

  window = gtk_window_new (GTK_WINDOW_TOPLEVEL);
  gtk_widget_set_size_request (window, window_width, window_height);
  gtk_window_set_resizable (GTK_WINDOW (window), FALSE);
  gtk_window_set_title (GTK_WINDOW (window), "HP-45");

  fixed = gtk_fixed_new ();
  gtk_container_add (GTK_CONTAINER (window), fixed);
  gtk_widget_show (fixed);

  if (image_pixbuf != NULL)
    {
      image = gtk_image_new_from_pixbuf (image_pixbuf);
      gtk_fixed_put (GTK_FIXED (fixed), image, 0, 0);
      gtk_widget_show (image);
    }

  add_keys (image_pixbuf, fixed);

  gtk_widget_show (window);

#if 0
  display = gtk_label_new ("HP-55 Display");
  gtk_widget_set_size_request (display, WINDOW_WIDTH, DISPLAY_HEIGHT);
  gtk_widget_modify_fg (display, GTK_STATE_NORMAL, & color [red]);
  gtk_widget_modify_bg (display, GTK_STATE_NORMAL, & color [dk_red]);
  gtk_fixed_put (GTK_FIXED (fixed), display, 0, 0);
  gtk_widget_show (display);
#endif

#if 0
  gtk_signal_connect (GTK_OBJECT (window), "destroy",
		      GTK_SIGNAL_FUNC (quit), NULL);
#endif

#if 1
  gtk_main ();
#else

  display = gtk_drawing_area_new ();
  gtk_drawing_area_size (GTK_DRAWING_AREA (display),
			 DISPLAY_WIDTH, DISPLAY_HEIGHT);
  gtk_box_pack_start (GTK_BOX (vbox), display, TRUE, TRUE, 0);




  init_breakpoints ();
  init_source ();
  read_listing_file (objfn, f, trace);
  fclose (f);

  init_ops ();

  debugger ();
#endif
  exit (0);
}
