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
#include "kml.h"


char *progname;

kml_t *kml;


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
    gdk_draw_rectangle (widget->window, gc, TRUE, x + 2, y + 8, 2, 2);
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
  GtkWidget *widget [KML_MAX_SWITCH_POSITION];
  GtkWidget *image [KML_MAX_SWITCH_POSITION];
  GtkWidget *fixed;
  kml_switch_t *kml_switch;
  gboolean flag [KML_MAX_SWITCH_POSITION];
} switch_info_t;


void switch_toggled (GtkWidget *widget, switch_info_t *sw)
{
  int pos;
  gboolean state;

  for (pos = 0; pos < KML_MAX_SWITCH_POSITION; pos++)
    {
      if (widget == sw->widget [pos])
	break;
    }
  if (pos >= KML_MAX_SWITCH_POSITION)
    fatal (2, "can't find switch position\n");

  state = gtk_toggle_button_get_active (GTK_TOGGLE_BUTTON (widget));

  if (sw->flag [pos])
    sim_set_ext_flag (sw->flag [pos], state);
}


void add_switch (GtkWidget *fixed,
		 GdkPixbuf *window_pixbuf,
		 kml_switch_t *kml_switch,
		 switch_info_t *switch_info)
{
  int i;
  GSList *group = NULL;

  switch_info->fixed = fixed;
  switch_info->kml_switch = kml_switch;
  
  for (i = 0; i < KML_MAX_SWITCH_POSITION; i++)
    if (kml_switch->position [i])
      {
	switch_info->flag [i] = kml_switch->position [i]->flag;
	switch_info->widget [i] = gtk_radio_button_new (group);

	group = gtk_radio_button_get_group (GTK_RADIO_BUTTON (switch_info->widget [i]));

	/* Though it's a radio button, don't display it as one! */
	gtk_toggle_button_set_mode (GTK_TOGGLE_BUTTON (switch_info->widget [i]),
				    FALSE);


	gtk_button_set_relief (GTK_BUTTON (switch_info->widget [i]), GTK_RELIEF_NONE);
	gtk_widget_set_size_request (switch_info->widget [i],
				     kml_switch->size.width,
				     kml_switch->size.height);

	gtk_fixed_put (GTK_FIXED (fixed),
		       switch_info->widget [i],
		       kml_switch->position [i]->offset.x,
		       kml_switch->position [i]->offset.y);

	g_signal_connect (G_OBJECT (switch_info->widget [i]),
			  "toggled",
			  G_CALLBACK (& switch_toggled),
			  (gpointer) switch_info);
      }
}


switch_info_t *switch_info [KML_MAX_SWITCH];


void add_switches (GdkPixbuf *window_pixbuf, GtkWidget *fixed)
{
  int i;

  for (i = 0; i < KML_MAX_SWITCH; i++)
    if (kml->kswitch [i])
      {
	switch_info [i] = alloc (sizeof (switch_info_t));
	add_switch (fixed, window_pixbuf, kml->kswitch [i], switch_info [i]);
      }
}


typedef struct
{
  GtkWidget *widget;
  GtkWidget *fixed;
  kml_button_t *kml_button;
} button_info_t;


void button_pressed (GtkWidget *widget, button_info_t *button)
{
  sim_press_key (button->kml_button->keycode);
#ifdef KEYBOARD_DEBUG
  printf ("pressed %d\n", button->kml_button->keycode);
#endif
}


void button_released (GtkWidget *widget, button_info_t *button)
{
  sim_release_key ();
#ifdef KEYBOARD_DEBUG
  printf ("released %d\n", button->kml_button->keycode);
#endif
}


void add_key (GtkWidget *fixed,
	      GdkPixbuf *window_pixbuf,
	      kml_button_t *kml_button,
	      button_info_t *button_info)
{
  GdkPixbuf *button_pixbuf;
  GtkWidget *button_image;

  button_info->kml_button = kml_button;

  button_pixbuf = gdk_pixbuf_new_subpixbuf (window_pixbuf,
					    kml_button->offset.x,
					    kml_button->offset.y,
					    kml_button->size.width,
					    kml_button->size.height);

  button_image = gtk_image_new_from_pixbuf (button_pixbuf);

  button_info->fixed = fixed;
  
  button_info->widget = gtk_button_new ();

  gtk_button_set_relief (GTK_BUTTON (button_info->widget), GTK_RELIEF_NONE);

  gtk_widget_set_size_request (button_info->widget,
			       kml_button->size.width,
			       kml_button->size.height);

  gtk_fixed_put (GTK_FIXED (fixed),
		 button_info->widget,
		 kml_button->offset.x,
		 kml_button->offset.y);

  g_signal_connect (G_OBJECT (button_info->widget),
		    "pressed",
		    G_CALLBACK (& button_pressed),
		    (gpointer) button_info);
  g_signal_connect (G_OBJECT (button_info->widget),
		    "released",
		    G_CALLBACK (& button_released),
		    (gpointer) button_info);

  gtk_container_add (GTK_CONTAINER (button_info->widget), button_image);
}


button_info_t *button_info [KML_MAX_BUTTON];


void add_keys (GdkPixbuf *window_pixbuf, GtkWidget *fixed)
{
  int i;

  for (i = 0; i < KML_MAX_BUTTON; i++)
    if (kml->button [i])
      {
	button_info [i] = alloc (sizeof (button_info_t));
	add_key (fixed, window_pixbuf, kml->button [i], button_info [i]);
      }
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
  char buf [200];

  dialog = gtk_dialog_new_with_buttons ("About CASMSIM",
					GTK_WINDOW (main_window),
					GTK_DIALOG_MODAL | GTK_DIALOG_DESTROY_WITH_PARENT,
					GTK_STOCK_OK,
					GTK_RESPONSE_NONE,
					NULL);

  gtk_dialog_set_has_separator (GTK_DIALOG (dialog), TRUE);

  sprintf (buf, "CASMSIM relesae %s", MAKESTR(CASMSIM_RELEASE));
  gtk_container_add (GTK_CONTAINER (GTK_DIALOG (dialog)->vbox),
		     gtk_label_new (buf));
  gtk_container_add (GTK_CONTAINER (GTK_DIALOG (dialog)->vbox),
		     gtk_label_new ("Microcode-level calculator simulator\n"
				    "Copyright 1995, 2003, 2004 Eric L. Smith\n"
				    "http://www.brouhaha.com/~eric/software/casmsim/"));
  if (kml->title || kml->author)
    {
      gtk_container_add (GTK_CONTAINER (GTK_DIALOG (dialog)->vbox),
			 gtk_hseparator_new ());
      gtk_container_add (GTK_CONTAINER (GTK_DIALOG (dialog)->vbox),
			 gtk_label_new ("KML:"));
      if (kml->title)
	gtk_container_add (GTK_CONTAINER (GTK_DIALOG (dialog)->vbox),
			   gtk_label_new (kml->title));
      if (kml->author)
	gtk_container_add (GTK_CONTAINER (GTK_DIALOG (dialog)->vbox),
			   gtk_label_new (kml->author));
    }
  gtk_widget_show_all (dialog);
  gtk_dialog_run (GTK_DIALOG (dialog));
  gtk_widget_destroy (dialog);
}


void debug_show_reg (GtkWidget *widget, gpointer data)
{
  /* $$$ not yet implemented */
}


void debug_run (GtkWidget *widget, gpointer data)
{
  /* $$$ not yet implemented */
}


void debug_step (GtkWidget *widget, gpointer data)
{
  /* $$$ not yet implemented */
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
    { "/_Debug",        NULL,         NULL,          0, "<Branch>" },
    { "/Debug/Show Reg", NULL,        debug_show_reg, 0, "<Item>" },
    { "/Debug/Run",     NULL,         debug_run,     0, "<Item>" },
    { "/Debug/Step",    NULL,         debug_step,    0, "<Item>" },
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


typedef struct
{
  char *name;
  int ram_size;
} model_info_t;


model_info_t model_info [] =
  {
    { "35", 0 },
    { "45", 10 },
    { "55", 30 },
    { "80", 0 }
  };


model_info_t *get_model_info (char *model)
{
  int i;

  for (i = 0; i < (sizeof (model_info) / sizeof (model_info_t)); i++)
    {
      if (strcasecmp (model, model_info [i].name) == 0)
	return (& model_info [i]);
    }
  return (NULL);
}


#ifndef PATH_MAX
#define PATH_MAX 256
#endif


int main (int argc, char *argv[])
{
  char *kml_fn = NULL;
  int kml_debug = 0;

  model_info_t *model_info;

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
	  if (strcasecmp (argv [0], "--kmldebug") == 0)
	    kml_debug = 1;
#if 0
	  else if (strcasecmp (argv [0], "--stop") == 0)
	    run = 0;
	  else if (strcasecmp (argv [0], "--trace") == 0)
	    trace = 1;
#endif
	  else
	    fatal (1, "unrecognized option '%s'\n", argv [0]);
	}
      else if (kml_fn)
	fatal (1, "only one KML file may be specified\n");
      else
	kml_fn = argv [0];
    }

  if (! kml_fn)
    {
      strncpy (buf, progname, sizeof (buf));
      strncat (buf, ".kml", sizeof (buf));
      kml_fn = & buf [0];
    }

  kml = read_kml_file (kml_fn);
  if (! kml)
    fatal (2, "can't read KML file '%s'\n", kml_fn);

  if (kml_debug)
    {
      print_kml (stdout, kml);
      exit (0);
    }

  if (! kml->image)
    fatal (2, "No image file spsecified in KML\n");

  if (! kml->rom)
    fatal (2, "No ROM file specified in KML\n");

  if (! kml->model)
    fatal (2, "No hardware model specified in KML\n");

  model_info = get_model_info (kml->model);

  image_pixbuf = gdk_pixbuf_new_from_file (kml->image, & error);
  if (! image_pixbuf)
    fatal (2, "can't load image '%s'\n", kml->image);

  image_width = gdk_pixbuf_get_width (image_pixbuf);
  image_height = gdk_pixbuf_get_height (image_pixbuf);

  main_window = gtk_window_new (GTK_WINDOW_TOPLEVEL);
  gtk_window_set_resizable (GTK_WINDOW (main_window), FALSE);

  gtk_window_set_title (GTK_WINDOW (main_window),
			kml->title ? kml->title : "CASMSIM");

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

  add_switches (image_pixbuf, fixed);

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

  gtk_widget_set_size_request (display,
			       kml->display_size.width,
			       kml->display_size.height);
  gtk_widget_modify_fg (display, GTK_STATE_NORMAL, & red);
  gtk_widget_modify_bg (display, GTK_STATE_NORMAL, & black);
  gtk_fixed_put (GTK_FIXED (fixed),
		 display,
		 kml->display_offset.x,
		 kml->display_offset.y);

  gtk_widget_show_all (main_window);

  g_signal_connect (G_OBJECT (display),
		    "expose_event",
		    G_CALLBACK (display_expose_event_callback),
		    NULL);

  gtk_signal_connect (GTK_OBJECT (main_window),
		      "destroy",
		      GTK_SIGNAL_FUNC (quit_callback),
		      NULL);

  sim_init (model_info->ram_size, & display_update);

  if (! sim_read_listing_file (kml->rom, TRUE))
    fatal (2, "unable to read listing file '%s'\n", kml->rom);

  sim_reset ();

  sim_start ();

  gtk_main ();

  exit (0);
}
