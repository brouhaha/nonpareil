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


typedef enum
  { black,
    dk_grey,
    med_grey,
    lt_grey,
    white,
    gold,
    blue,
    dk_red,
    red,
    max_color 
  } color_e;


char *color_name [max_color] =
  {
#if 0
    "rgb:0000/0000/0000",  /* black */
    "rgb:3800/3800/3800",  /* dk_grey */
    "rgb:5800/5800/5800",  /* med_grey */
    "rgb:a000/a000/a000",  /* lt_grey */
    "rgb:ffff/ffff/ffff",  /* white */
    "rgb:ffff/d7d7/0000",  /* gold */
    "rgb:4000/4000/ffff",  /* blue */
    "rgb:5000/0000/0000",  /* dk_red */
    "rgb:ffff/4000/0000"   /* red */
#else
    "black",
    "grey22",
    "grey38",
    "grey63",
    "white",
    "gold",
    "blue",
    "darkred",
    "red"
#endif
  };


GdkColor color [max_color];


void init_colors (GdkColormap *colormap)
{
  int i;

  for (i = 0; i < max_color; i++)
    {
      if (! gdk_color_parse (color_name [i], & color [i]))
	fatal (2, "can't parse color '%s'\n", color_name [i]);
      if (! gdk_colormap_alloc_color (colormap, & color [i], FALSE, TRUE))
	fatal (2, "can't alloc color '%s'\n", color_name [i]);
    }
}


typedef struct
{
  GdkRectangle rect;
  char *label;
  char *flabel;
  char *glabel;
  int keycode;
  int fg, bg;
} keyinfo;


keyinfo (*keys)[35];


keyinfo keys_hp35 [35] =
{
  {{  24, 120, 30, 24 }, "x^y",     NULL, NULL, 006, white, black },
  {{  72, 120, 30, 24 }, "log",     NULL, NULL, 004, white, black },
  {{ 120, 120, 30, 24 }, "ln",      NULL, NULL, 003, white, black },
  {{ 168, 120, 30, 24 }, "e^x",     NULL, NULL, 002, white, black },
  {{ 216, 120, 30, 24 }, "CLR",     NULL, NULL, 000, white, blue },

  {{  24, 168, 30, 24 }, "sqrt(x)", NULL, NULL, 056, white, black },
  {{  72, 168, 30, 24 }, "arc",     NULL, NULL, 054, white, med_grey },
  {{ 120, 168, 30, 24 }, "sin",     NULL, NULL, 053, white, med_grey },
  {{ 168, 168, 30, 24 }, "cos",     NULL, NULL, 052, white, med_grey },
  {{ 216, 168, 30, 24 }, "tan",     NULL, NULL, 050, white, med_grey },

  {{  24, 216, 30, 24 }, "1/x",     NULL, NULL, 016, white, black },
  {{  72, 216, 30, 24 }, "x<>y",    NULL, NULL, 014, white, black },
  {{ 120, 216, 30, 24 }, "RDN",     NULL, NULL, 013, white, black },
  {{ 168, 216, 30, 24 }, "STO",     NULL, NULL, 012, white, black },
  {{ 216, 216, 30, 24 }, "RCL",     NULL, NULL, 010, white, black },

  {{  24, 264, 78, 24 }, "ENTER^",  NULL, NULL, 076, white, blue },
  {{ 120, 264, 30, 24 }, "CHS",     NULL, NULL, 073, white, blue },
  {{ 168, 264, 30, 24 }, "EEX",     NULL, NULL, 072, white, blue },
  {{ 216, 264, 30, 24 }, "CLX",     NULL, NULL, 070, white, blue },

  {{  24, 312, 24, 24 }, "-",       NULL, NULL, 066, white, blue },
  {{  73, 312, 37, 24 }, "7",       NULL, NULL, 064, black, white },
  {{ 141, 312, 37, 24 }, "8",       NULL, NULL, 063, black, white },
  {{ 209, 312, 37, 24 }, "9",       NULL, NULL, 062, black, white },

  {{  24, 360, 24, 24 }, "+",       NULL, NULL, 026, white, blue },
  {{  73, 360, 37, 24 }, "4",       NULL, NULL, 024, black, white },
  {{ 141, 360, 37, 24 }, "5",       NULL, NULL, 023, black, white },
  {{ 209, 360, 37, 24 }, "6",       NULL, NULL, 022, black, white },

  {{  24, 408, 24, 24 }, "x",       NULL, NULL, 036, white, blue },
  {{  73, 408, 37, 24 }, "1",       NULL, NULL, 034, black, white },
  {{ 141, 408, 37, 24 }, "2",       NULL, NULL, 033, black, white },
  {{ 209, 408, 37, 24 }, "3",       NULL, NULL, 032, black, white },

  {{  24, 456, 24, 24 }, "/",       NULL, NULL, 046, white, blue },
  {{  73, 456, 37, 24 }, "0",       NULL, NULL, 044, black, white },
  {{ 141, 456, 37, 24 }, ".",       NULL, NULL, 043, black, white },
  {{ 209, 456, 37, 24 }, "Pi",      NULL, NULL, 042, black, white },
};

keyinfo keys_hp45 [35] =
{
  {{  48, 156, 32, 24 }, "1/x",    "y^x",     NULL, 006, white, med_grey },
  {{  91, 156, 32, 24 }, "ln",     "log",     NULL, 004, white, med_grey },
  {{ 134, 156, 32, 24 }, "e^x",    "10^x",    NULL, 003, white, med_grey },
  {{ 176, 156, 32, 24 }, "FIX",    "SCI",     NULL, 002, white, med_grey },
  {{ 219, 156, 32, 24 }, NULL,     NULL,      NULL, 000, gold,  gold },

  {{  48, 201, 32, 24 }, "x^2",    "sqrt(x)", NULL, 056, white, med_grey },
  {{  91, 201, 32, 24 }, "->P",    "->R",     NULL, 054, white, black },
  {{ 134, 201, 32, 24 }, "SIN",    "SIN^-1",  NULL, 053, white, black },
  {{ 176, 201, 32, 24 }, "COS",    "COS^-1",  NULL, 052, white, black },
  {{ 219, 201, 32, 24 }, "TAN",    "TAN^-1",  NULL, 050, white, black },

  {{  48, 246, 32, 24 }, "x<>y",   "n!",      NULL, 016, black, lt_grey },
  {{  91, 246, 32, 24 }, "RDN",    "x,s",     NULL, 014, black, lt_grey },
  {{ 134, 246, 32, 24 }, "STO",    "->D.MS",  NULL, 013, black, lt_grey },
  {{ 176, 246, 32, 24 }, "RCL",    "D.MS->",  NULL, 012, black, lt_grey },
  {{ 219, 246, 32, 24 }, "%",      "delta %", NULL, 010, white, med_grey },

#if ENTER_KEY_MOD
  {{  48, 291, 74, 24 }, "ENTER^", "DEG",     NULL, 074, black, lt_grey },
#else
  {{  48, 291, 74, 24 }, "ENTER^", "DEG",     NULL, 075, black, lt_grey },
#endif /* ENTER_KEY_MOD */
  {{ 134, 291, 32, 24 }, "CHS",    "RAD",     NULL, 073, black, lt_grey },
  {{ 176, 291, 32, 24 }, "EEX",    "GRD",     NULL, 072, black, lt_grey },
  {{ 219, 291, 32, 24 }, "CLX",    "CLEAR",   NULL, 070, black, lt_grey },

  {{  48, 336, 24, 24 }, "-",      NULL,      NULL, 066, black, lt_grey },
  {{  92, 336, 36, 24 }, "7",      "cm/in",   NULL, 064, black, white },
  {{ 153, 336, 36, 24 }, "8",      "kg/lb",   NULL, 063, black, white },
  {{ 214, 336, 36, 24 }, "9",      "ltr/gal", NULL, 062, black, white },

  {{  48, 381, 24, 24 }, "+",      NULL,      NULL, 026, black, lt_grey },
  {{  92, 381, 36, 24 }, "4",      NULL,      NULL, 024, black, white },
  {{ 153, 381, 36, 24 }, "5",      NULL,      NULL, 023, black, white },
  {{ 214, 381, 36, 24 }, "6",      NULL,      NULL, 022, black, white },

  {{  48, 425, 24, 24 }, "x",      NULL,      NULL, 036, black, lt_grey },
  {{  92, 425, 36, 24 }, "1",      NULL,      NULL, 034, black, white },
  {{ 153, 425, 36, 24 }, "2",      NULL,      NULL, 033, black, white },
  {{ 214, 425, 36, 24 }, "3",      NULL,      NULL, 032, black, white },

  {{  48, 470, 24, 24 }, "/",      NULL,      NULL, 046, black, lt_grey },
  {{  92, 470, 36, 24 }, "0",      "LASTX",   NULL, 044, black, white },
  {{ 153, 470, 36, 24 }, ".",      "Pi",      NULL, 043, black, white },
  {{ 214, 470, 36, 24 }, "SIG+",   "SIG-",    NULL, 042, black, white },
};

keyinfo keys_hp55 [35] =
{
  {{  28, 120, 36, 24 }, "SIG+",   "SIG-",    NULL,    006, black, lt_grey },
  {{  85, 120, 36, 24 }, "y^x",    "sin",     "-1",    004, black, lt_grey },
  {{ 142, 120, 36, 24 }, "1/x",    "cos",     "-1",    003, black, lt_grey },
  {{ 199, 120, 36, 24 }, "%",      "tan",     "-1",    002, black, lt_grey },
  {{ 256, 120, 36, 24 }, "BST",    NULL,      NULL,    000, white, med_grey },

  {{  28, 168, 36, 24 }, "y^",     "L.R.",    NULL,    056, black, lt_grey },
  {{  85, 168, 36, 24 }, "x<>y",   "ln",      "e^x",   054, black, lt_grey },
  {{ 142, 168, 36, 24 }, "RDN",    "log",     "10^x",  053, black, lt_grey },
  {{ 199, 168, 36, 24 }, "FIX",    "SCI",     NULL,    052, black, lt_grey },
  {{ 256, 168, 36, 24 }, "SST",    NULL,      NULL,    050, white, med_grey },

  {{  28, 216, 36, 24 }, "f",      NULL,      NULL,    016, black, gold },
  {{  85, 216, 36, 24 }, "g",      NULL,      NULL,    014, black, blue },
  {{ 142, 216, 36, 24 }, "STO",    "x",       "s",     013, black, lt_grey },
  {{ 199, 216, 36, 24 }, "RCL",    "LASTx",   NULL,    012, black, lt_grey },
  {{ 256, 216, 36, 24 }, "GTO",    "x<=y",    "x=y",   010, white, black },

  {{  28, 264, 92, 24 }, "ENTER^", "H.MS+",   "H.MS-", 075, black, lt_grey },
  {{ 142, 264, 36, 24 }, "CHS",    "sqrt(x)", "x^2",   073, black, lt_grey },
  {{ 199, 264, 36, 24 }, "EEX",    "n!",      NULL,    072, black, lt_grey },
  {{ 256, 264, 36, 24 }, "CLX",    "CLR",     "CL.R",  070, black, lt_grey },

  {{  28, 312, 28, 24 }, "-",      "DEG",     NULL,    066, black, lt_grey },
  {{  87, 312, 44, 24 }, "7",      "in",      "mm",    064, black, white },
  {{ 167, 312, 44, 24 }, "8",      "ft",      "m",     063, black, white },
  {{ 248, 312, 44, 24 }, "9",      "gal",     "l",     062, black, white },

  {{  28, 360, 28, 24 }, "+",      "RAD",     NULL,    026, black, lt_grey },
  {{  87, 360, 44, 24 }, "4",      "lbm",     "kg",    024, black, white },
  {{ 167, 360, 44, 24 }, "5",      "lbf",     "N",     023, black, white },
  {{ 248, 360, 44, 24 }, "6",      "degF",    "degC",  022, black, white },

  {{  28, 408, 28, 24 }, "x",      "GRD",     NULL,    036, black, lt_grey },
  {{  87, 408, 44, 24 }, "1",      "H",       "H.MS",  034, black, white },
  {{ 167, 408, 44, 24 }, "2",      "D",       "R",     033, black, white },
  {{ 248, 408, 44, 24 }, "3",      "Btu",     "J",     032, black, white },

  {{  28, 456, 28, 24 }, "/",      NULL,      NULL,    046, black, lt_grey },
  {{  87, 456, 44, 24 }, "0",      "R",       "P",     044, black, white },
  {{ 167, 456, 44, 24 }, ".",      "Pi",      NULL,    043, black, white },
  {{ 248, 456, 44, 24 }, "R/S",    NULL,      NULL,    042, white, black },
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


void add_key_graphic (GtkWidget *fixed,
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


void add_key (GtkWidget *fixed,
	      keyinfo *key,
	      PangoAttrList *pattrs)
{
  GtkWidget *button;
  GtkWidget *label;  /* part of the button */
  GtkWidget *flabel;
  GtkWidget *glabel;
  button_info_t *button_info;

  int x, width;

  button_info = calloc (1, sizeof (button_info_t));
  /* $$$ check for failed */

  button_info->fixed = fixed;
  button_info->keycode = key->keycode;

  button = gtk_button_new ();

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

  gtk_widget_modify_bg (button, GTK_STATE_NORMAL, & color [key->bg]);
  gtk_widget_modify_bg (button, GTK_STATE_ACTIVE, & color [key->bg]);
  gtk_widget_modify_bg (button, GTK_STATE_PRELIGHT, & color [key->bg]);

  label = gtk_label_new (key->label);
  gtk_label_set_attributes (GTK_LABEL (label), pattrs);

  gtk_widget_set_size_request (label, key->rect.width, key->rect.height);
  gtk_widget_modify_fg (label, GTK_STATE_NORMAL, & color [key->fg]);
  gtk_widget_modify_fg (label, GTK_STATE_ACTIVE, & color [key->fg]);
  gtk_widget_modify_fg (label, GTK_STATE_PRELIGHT, & color [key->fg]);
  gtk_widget_show (label);
  gtk_container_add (GTK_CONTAINER (button), label);


  if (key->flabel)
    {
      x = key->rect.x;
      if (key->glabel)
	width = key->rect.width / 2;
      else
	width = key->rect.width;

      flabel = gtk_label_new (key->flabel);
      gtk_label_set_attributes (GTK_LABEL (flabel), pattrs);
      gtk_widget_set_size_request (flabel, width, key->rect.height);
      gtk_widget_modify_fg (flabel, GTK_STATE_NORMAL, & color [gold]);
      gtk_widget_modify_bg (flabel, GTK_STATE_NORMAL, & color [dk_grey]);
      gtk_fixed_put (GTK_FIXED (fixed), flabel, x, key->rect.y - key->rect.height);
      gtk_widget_show (flabel);
    }

  if (key->glabel)
    {
      width = key->rect.width / 2;
      x = key->rect.x + width;

      glabel = gtk_label_new (key->glabel);
      gtk_label_set_attributes (GTK_LABEL (glabel), pattrs);
      gtk_widget_set_size_request (glabel, width, key->rect.height);
      gtk_widget_modify_fg (glabel, GTK_STATE_NORMAL, & color [blue]);
      gtk_widget_modify_bg (glabel, GTK_STATE_NORMAL, & color [dk_grey]);
      gtk_fixed_put (GTK_FIXED (fixed), glabel, x, key->rect.y - key->rect.height);
      gtk_widget_show (glabel);
    }
}


void add_keys (GdkPixbuf *window_pixbuf, GtkWidget *fixed)
{
  int i;
  PangoAttribute *pfont;
  PangoAttribute *psize;
  PangoAttrList *pattrs;

  pfont = pango_attr_family_new ("Sans");
  psize = pango_attr_size_new (1000*7);
  psize->start_index = 0;
  psize->end_index = G_MAXINT;

  pattrs = pango_attr_list_new ();
  /* pango_attr_list_insert (pattrs, pfont); */
  pango_attr_list_insert (pattrs, psize);

  for (i = 0; i < (sizeof (keys_hp45) / sizeof (keyinfo)); i++)
    {
      if (window_pixbuf)
	add_key_graphic (fixed, window_pixbuf, & keys_hp45 [i]);
      else
	add_key (fixed, & keys_hp45 [i], pattrs);
    }
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

#define WINDOW_WIDTH  320
#define WINDOW_HEIGHT 580

#define DISPLAY_HEIGHT 72

int main (int argc, char *argv[])
{
#if 0
  char *objfn = NULL;
  FILE *f;
  char buf [PATH_MAX];
#endif

  GtkWidget *window;
  GtkWidget *fixed;
  GtkWidget *display;

  GdkPixbuf *image_pixbuf;
  GError *error = NULL;
  GtkWidget *image;

  GdkColormap *colormap;

 
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

  window = gtk_window_new (GTK_WINDOW_TOPLEVEL);
  gtk_widget_set_size_request (window, WINDOW_WIDTH, WINDOW_HEIGHT);
  gtk_window_set_resizable (GTK_WINDOW (window), FALSE);
  gtk_window_set_title (GTK_WINDOW (window), "HP-55");

  colormap = gtk_widget_get_colormap (window);

  init_colors (colormap);

  gtk_widget_modify_bg (window, GTK_STATE_NORMAL, & color [dk_grey]);

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

  display = gtk_label_new ("HP-55 Display");
  gtk_widget_set_size_request (display, WINDOW_WIDTH, DISPLAY_HEIGHT);
  gtk_widget_modify_fg (display, GTK_STATE_NORMAL, & color [red]);
  gtk_widget_modify_bg (display, GTK_STATE_NORMAL, & color [dk_red]);
  gtk_fixed_put (GTK_FIXED (fixed), display, 0, 0);
  gtk_widget_show (display);

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
