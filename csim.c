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

#include <ctype.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <gdk/gdk.h>
#include <gtk/gtk.h>

#include "util.h"
#include "proc.h"


char *progname;


GtkWidget *main_window;


#define DISPLAY_DIGIT_POSITIONS 15
int display_digit [DISPLAY_DIGIT_POSITIONS];


GtkWidget *display;


#define DIGIT_RADIX 10
#define DIGIT_NEG   11
#define DIGIT_BLANK 12

/*
 *     aaa
 *    f   b
 *    f   b
 *    f   b
 *     ggg
 *    e   c
 *    e hhc
 *    e hhc
 *     ddd
 */

typedef int seven_seg_t [8];

seven_seg_t seven_seg [13] =
  {
  /*       a   b  c  d  e  f  g  h */
  /* 0 */ { 1, 1, 1, 1, 1, 1, 0, 0 },
  /* 1 */ { 0, 1, 1, 0, 0, 0, 0, 0 },
  /* 2 */ { 1, 1, 0, 1, 1, 0, 1, 0 },
  /* 3 */ { 1, 1, 1, 1, 0, 0, 1, 0 },
  /* 4 */ { 0, 1, 1, 0, 0, 1, 1, 0 },
  /* 5 */ { 1, 0, 1, 1, 0, 1, 1, 0 },
  /* 6 */ { 1, 0, 1, 1, 1, 1, 1, 0 },
  /* 7 */ { 1, 1, 1, 0, 0, 0, 0, 0 },
  /* 8 */ { 1, 1, 1, 1, 1, 1, 1, 0 },
  /* 9 */ { 1, 1, 1, 1, 0, 1, 1, 0 },
  /* . */ { 0, 0, 0, 0, 0, 0, 0, 1 },
  /* - */ { 0, 0, 0, 0, 0, 0, 1, 0 },
  /*   */ { 0, 0, 0, 0, 0, 0, 0, 0 }
  };


GdkSegment digit_segment [7] =
  {
    { 0,  0, 5,  0 },
    { 5,  0, 5,  5 },
    { 5,  5, 5, 10 },
    { 5, 10, 0, 10 },
    { 0, 10, 0,  5 },
    { 0,  5, 0,  0 },
    { 0,  5, 5,  5 }
  };


GdkPixbuf *digit_pixbuf [13];


GdkPixbuf *create_digit (seven_seg_t *segs,
			 guint32 fg_color,
			 guint32 bg_color)
{
  GdkPixbuf *pixbuf;

  pixbuf = gdk_pixbuf_new (GDK_COLORSPACE_RGB,
			   FALSE,  /* has_alpha */
			   8,  /* bits per sample */
			   5,  /* width */
			   9);  /* height */
  gdk_pixbuf_fill (pixbuf, bg_color);
  return (pixbuf);
}


void create_digits (void)
{
  int i;
  guint32 fg_color = 0xaa111100;
  guint32 bg_color = 0x00000000;

  for (i = 0; i < 13; i++)
    digit_pixbuf [i] = create_digit (& seven_seg [i], fg_color, bg_color);
}


void draw_digit (GtkWidget *widget, gint x, gint y, int val)
{
  int i;
  int seg_count = 0;
  GdkSegment segs [8];
  GdkGC *gc = display->style->fg_gc [GTK_WIDGET_STATE (widget)];

#if 1
  for (i = 0; i < 7; i++)
    {
      if (seven_seg [val] [i])
	{
	  segs [seg_count].x1 = digit_segment [i].x1 + x;
	  segs [seg_count].y1 = digit_segment [i].y1 + y;
	  segs [seg_count].x2 = digit_segment [i].x2 + x;
	  segs [seg_count].y2 = digit_segment [i].y2 + y;
	  seg_count++;
	}
      if (seg_count)
	gdk_draw_segments (widget->window, gc, & segs [0], seg_count);
    }
  if (val == DIGIT_RADIX)
    gdk_draw_rectangle (widget->window, gc, TRUE, x + 2, y + 6, 2, 2);
#else
  gdk_draw_pixbuf (widget->window,
		   NULL, /* gc for clipping */
		   digit_pixbuf [val],
		   0, 0, /* src x, y */
		   x, y, /* dest x, y */
		   5, 9, /* width, height */
		   GDK_RGB_DITHER_NORMAL,
		   0, 0); /* x_dither, y_dither */
#endif
}


gboolean display_expose_event_callback (GtkWidget *widget,
					GdkEventExpose *event,
					gpointer data)
{
  int i;
  gdouble x;

  /* clear the display */
  gdk_draw_rectangle (widget->window,
		      display->style->bg_gc [GTK_WIDGET_STATE (widget)],
		      TRUE,
		      0, 0,
		      display->allocation.width,
		      display->allocation.height);

  x = 0.0;
  for (i = 0; i < DISPLAY_DIGIT_POSITIONS; i++)
    {
      draw_digit (widget, (gint) (x + 0.5), 0, display_digit [i]);
		       
      x += 13.29;
    }

  return (TRUE);
}


static void display_update (char *buf)
{
  int i;
  int l;
  GdkRectangle rect = { 0, 0, 0, 0 };

#ifdef DISPLAY_DEBUG
  printf ("%s\n", buf);
#endif

  l = strlen (buf);

  for (i = 0; i < DISPLAY_DIGIT_POSITIONS; i++)
    {
      if (i >= l)
	{
	  display_digit [i] = DIGIT_BLANK;
	  continue;
	}
      if (isdigit (buf [i]))
	display_digit [i] = buf [i] - '0';
      else
	switch (buf [i])
	  {
	  case '-':
	    display_digit [i] = DIGIT_NEG;
	    break;
	  case '.':
	    display_digit [i] = DIGIT_RADIX;
	    break;
	  case ' ':
	    display_digit [i] = DIGIT_BLANK;
	    break;
	  default:
	    fatal (2, "illegal display char '%c'\n", buf [i]);
	  }
    }

  rect.width = display->allocation.width;
  rect.height = display->allocation.height;
    
  /* invalidate the entire drawing area */
  gdk_window_invalidate_rect (display->window,
			      & rect,
			      FALSE);
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
  GtkWidget *button;
  GtkWidget *fixed;
  int keycode;
} button_info_t;


button_info_t button_info [35];


void button_pressed (GtkWidget *widget, button_info_t *button)
{
  sim_press_key (button->keycode);
#ifdef KEYBOARD_DEBUG
  printf ("pressed %d\n", button->keycode);
#endif
}


void button_released (GtkWidget *widget, button_info_t *button)
{
  sim_release_key ();
#ifdef KEYBOARD_DEBUG
  printf ("released %d\n", button->keycode);
#endif
}


void add_key (GtkWidget *fixed,
	      GdkPixbuf *window_pixbuf,
	      keyinfo *key,
	      button_info_t *button_info)
{
  GdkPixbuf *button_pixbuf;
  GtkWidget *button_image;

  button_pixbuf = gdk_pixbuf_new_subpixbuf (window_pixbuf,
					    key->rect.x,
					    key->rect.y,
					    key->rect.width,
					    key->rect.height);

  button_image = gtk_image_new_from_pixbuf (button_pixbuf);

  button_info->fixed = fixed;
  button_info->keycode = key->keycode;
  
  button_info->button = gtk_button_new ();

  gtk_button_set_relief (GTK_BUTTON (button_info->button), GTK_RELIEF_NONE);

  gtk_widget_set_size_request (button_info->button,
			       key->rect.width,
			       key->rect.height);

  gtk_fixed_put (GTK_FIXED (fixed),
		 button_info->button,
		 key->rect.x,
		 key->rect.y);

  g_signal_connect (G_OBJECT (button_info->button),
		    "pressed",
		    G_CALLBACK (& button_pressed),
		    (gpointer) button_info);
  g_signal_connect (G_OBJECT (button_info->button),
		    "released",
		    G_CALLBACK (& button_released),
		    (gpointer) button_info);

  gtk_container_add (GTK_CONTAINER (button_info->button), button_image);
}


void add_keys (GdkPixbuf *window_pixbuf, GtkWidget *fixed)
{
  int i;

  for (i = 0; i < (sizeof (keys_hp45) / sizeof (keyinfo)); i++)
    add_key (fixed, window_pixbuf, & keys_hp45 [i], & button_info [i]);
}


static void quit_callback (GtkWidget *widget, gpointer data)
{
  gtk_main_quit ();
}


static void file_open (GtkWidget *widget, gpointer data)
{
  /* $$$ not yet implemented */
}


static void file_save (GtkWidget *widget, gpointer data)
{
  /* $$$ not yet implemented */
}


static void file_save_as (GtkWidget *widget, gpointer data)
{
  /* $$$ not yet implemented */
}


static void edit_copy (GtkWidget *widget, gpointer data)
{
  /* $$$ not yet implemented */
}


static void edit_paste (GtkWidget *widget, gpointer data)
{
  /* $$$ not yet implemented */
}


static void help_about (GtkWidget *widget, gpointer data)
{
  GtkWidget *dialog;

  dialog = gtk_dialog_new_with_buttons ("About CASMSIM",
					GTK_WINDOW (main_window),
					GTK_DIALOG_DESTROY_WITH_PARENT,
					GTK_STOCK_OK,
					GTK_RESPONSE_NONE,
					NULL);

  gtk_dialog_set_has_separator (GTK_DIALOG (dialog), FALSE);

  gtk_container_add (GTK_CONTAINER (GTK_DIALOG (dialog)->vbox),
		     gtk_label_new ("CASMSIM"));
  gtk_container_add (GTK_CONTAINER (GTK_DIALOG (dialog)->vbox),
		     gtk_label_new ("Microcode-level calculator simulator\n"
				    "Copyright 1995, 2003, 2004 Eric L. Smith\n"
				    "http://www.brouhaha.com/~eric/software/casmsim/"));
  gtk_widget_show_all (dialog);
  gtk_dialog_run (GTK_DIALOG (dialog));
  gtk_widget_destroy (dialog);
}


static GtkItemFactoryEntry menu_items [] =
  {
    { "/_File",         NULL,         NULL,          0, "<Branch>" },
    { "/File/_Open",    "<control>O", file_open,     0, "<StockItem>", GTK_STOCK_OPEN },
    { "/File/_Save",    "<control>S", file_save,     0, "<StockItem>", GTK_STOCK_SAVE },
    { "/File/Save _As", NULL,         file_save_as,  0, "<Item>" },
    { "/File/sep1",     NULL,         NULL,          0, "<Separator>" },
    { "/File/_Quit",    "<CTRL>Q",    gtk_main_quit, 0, "<StockItem>", GTK_STOCK_QUIT },
    { "/_Edit",         NULL,         NULL,          0, "<Branch>" },
    { "/Edit/_Copy",    "<control>C", edit_copy,     0, "<StockItem>", GTK_STOCK_COPY },
    { "/Edit/_Paste",   "<control>V", edit_paste,    0, "<StockItem>", GTK_STOCK_PASTE },
    { "/_Help",         NULL,         NULL,          0, "<LastBranch>" },
    { "/_Help/About",   NULL,         help_about,    0, "<Item>" }
  };

static gint nmenu_items = sizeof (menu_items) / sizeof (GtkItemFactoryEntry);


static GtkWidget *get_menubar_menu (GtkWidget *window)
{
  GtkAccelGroup *accel_group;
  GtkItemFactory *item_factory;

  accel_group = gtk_accel_group_new ();
  item_factory = gtk_item_factory_new (GTK_TYPE_MENU_BAR,
				       "<main>",
				       accel_group);
  gtk_item_factory_create_items (item_factory, nmenu_items, menu_items, NULL);
  gtk_window_add_accel_group (GTK_WINDOW (window), accel_group);
  return (gtk_item_factory_get_widget (item_factory, "<main>"));
}


#ifndef PATH_MAX
#define PATH_MAX 256
#endif


#define DISPLAY_X 54
#define DISPLAY_Y 58
#define DISPLAY_WIDTH 192
#define DISPLAY_HEIGHT 11


int main (int argc, char *argv[])
{
  char *objfn = NULL;

  int image_width, image_height;

  GtkWidget *vbox;
  GtkWidget *menubar;
  GtkWidget *fixed;

  GdkPixbuf *image_pixbuf;
  GError *error = NULL;
  GtkWidget *image;

  GdkColormap *colormap;
  GdkColor red, black;

  char buf [PATH_MAX];

 
  progname = newstr (argv [0]);

  gtk_init (& argc, & argv);

  while (--argc)
    {
      argv++;
      if (*argv [0] == '-')
	{
#if 0
	  if (strcasecmp (argv [0], "-stop") == 0)
	    run = 0;
	  else if (strcasecmp (argv [0], "-trace") == 0)
	    trace = 1;
	  else
#endif
	    fatal (1, "unrecognized option '%s'\n", argv [0]);
	}
      else if (objfn)
	fatal (1, "only one listing file may be specified\n");
      else
	objfn = argv [0];
    }


  image_pixbuf = gdk_pixbuf_new_from_file ("hp45.jpg", & error);
  if (! image_pixbuf)
    fatal (2, "can't load image\n");

  image_width = gdk_pixbuf_get_width (image_pixbuf);
  image_height = gdk_pixbuf_get_height (image_pixbuf);

  main_window = gtk_window_new (GTK_WINDOW_TOPLEVEL);
  gtk_window_set_resizable (GTK_WINDOW (main_window), FALSE);
  gtk_window_set_title (GTK_WINDOW (main_window), "HP-45");

  vbox = gtk_vbox_new (FALSE, 1);
  gtk_container_add (GTK_CONTAINER (main_window), vbox);

  menubar = get_menubar_menu (main_window);
  gtk_box_pack_start (GTK_BOX (vbox), menubar, FALSE, TRUE, 0);

  fixed = gtk_fixed_new ();
  gtk_widget_set_size_request (fixed, image_width, image_height);
  gtk_box_pack_end (GTK_BOX (vbox), fixed, FALSE, TRUE, 0);

  if (image_pixbuf != NULL)
    {
      image = gtk_image_new_from_pixbuf (image_pixbuf);
      gtk_fixed_put (GTK_FIXED (fixed), image, 0, 0);
    }

  add_keys (image_pixbuf, fixed);

  create_digits ();

  display = gtk_drawing_area_new ();

  colormap = gtk_widget_get_colormap (main_window);
  if (! gdk_color_parse ("#ee1111", & red))
    fatal (2, "can't parse color red\n");
  if (! gdk_colormap_alloc_color (colormap, & red, FALSE, TRUE))
    fatal (2, "can't alloc color red\n");
  if (! gdk_color_parse ("#000000", & black))
    fatal (2, "can't parse color black\n");
  if (! gdk_colormap_alloc_color (colormap, & black, FALSE, TRUE))
    fatal (2, "can't alloc color black\n");

  gtk_widget_set_size_request (display, DISPLAY_WIDTH, DISPLAY_HEIGHT);
  gtk_widget_modify_fg (display, GTK_STATE_NORMAL, & red);
  gtk_widget_modify_bg (display, GTK_STATE_NORMAL, & black);
  gtk_fixed_put (GTK_FIXED (fixed), display, DISPLAY_X, DISPLAY_Y);

  gtk_widget_show_all (main_window);

  g_signal_connect (G_OBJECT (display),
		    "expose_event",
		    G_CALLBACK (display_expose_event_callback),
		    NULL);

  gtk_signal_connect (GTK_OBJECT (main_window),
		      "destroy",
		      GTK_SIGNAL_FUNC (quit_callback),
		      NULL);

  sim_init (10, & display_update);  /* $$$ 10 regs is enough for HP-45 */

  if (! objfn)
    {
      strncpy (buf, progname, sizeof (buf));
      strncat (buf, ".lst", sizeof (buf));
      objfn = & buf [0];
    }

  if (! sim_read_listing_file (objfn, TRUE))
    fatal (2, "unable to read listing file '%s'\n", objfn);

  sim_reset ();

  sim_start ();

  gtk_main ();

  exit (0);
}
