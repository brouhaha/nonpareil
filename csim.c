/*
$Id$
Copyright 1995, 2004 Eric L. Smith <eric@brouhaha.com>

Nonpareil is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License version 2 as
published by the Free Software Foundation.  Note that I am not
granting permission to redistribute or modify Nonpareil under the
terms of any later version of the General Public License.

Nonpareil is distributed in the hope that it will be useful (or at
least amusing), but WITHOUT ANY WARRANTY; without even the implied
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See
the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program (in the file "COPYING"); if not, write to the
Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
MA 02111, USA.
*/

#include <ctype.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <gdk/gdk.h>
#include <gtk/gtk.h>

#include "util.h"
#include "display.h"
#include "proc.h"
#include "kml.h"
#include "arch.h"
#include "platform.h"
#include "model.h"

#ifdef HAS_DEBUGGER_CLI
  #include "debugger.h"
#endif

#ifndef SHAPE_DEFAULT
#define SHAPE_DEFAULT true
#endif


gboolean scancode_debug = FALSE;
gboolean kml_debug = FALSE;

kml_t *kml;

sim_t *sim;

#ifdef HAS_DEBUGGER_CLI
gboolean dbg_visible;
dbg_t *dbg;
#endif


GtkWidget *main_window;
GtkWidget *menubar;  /* actually a popup menu in transparency/shape mode */


static segment_bitmap_t display_segments [KML_MAX_DIGITS];

GtkWidget *display;

GdkBitmap *annunciator_bitmap [KML_MAX_ANNUNCIATOR];


void usage (FILE *f)
{
  fprintf (f, "Nonpareil release %s:  Microcode-level calculator simulator\n",
	   MAKESTR(NONPAREIL_RELEASE));
  fprintf (f, "Copyright 1995, 2003, 2004 Eric L. Smith\n");
  fprintf (f, "http://nonpareil.brouhaha.com//\n");
  fprintf (f, "\n");
  fprintf (f, "usage: %s [options...] kmlfile\n", progname);
  fprintf (f, "options:\n");
  fprintf (f, "   --shape");
  if (SHAPE_DEFAULT)
    fprintf (f, " (default)");
  fprintf (f, "\n");
  fprintf (f, "   --noshape");
  if (! (SHAPE_DEFAULT))
    fprintf (f, " (default)");
  fprintf (f, "\n");
  fprintf (f, "   --kmldebug\n");
  fprintf (f, "   --kmldump\n");
  fprintf (f, "   --scancodedebug\n");
#ifdef HAS_DEBUGGER
  fprintf (f, "   --stop\n");
#endif
}


void draw_digit (GtkWidget *widget, gint x, gint y, segment_bitmap_t segments)
{
  int i;

  for (i = 0; i < KML_MAX_SEGMENT; i++)
    if (segments & (1 << i))
      {
	switch (kml->segment [i]->type)
	  {
	  case kml_segment_type_line:
	    gdk_draw_line (widget->window,
			   display->style->fg_gc [GTK_WIDGET_STATE (widget)],
			   x + kml->segment [i]->offset.x,
			   y + kml->segment [i]->offset.y,
			   x + kml->segment [i]->offset.x + kml->segment [i]->size.width - 1,
			   y + kml->segment [i]->offset.y + kml->segment [i]->size.height - 1);
	    break;
	  case kml_segment_type_rect:
	    gdk_draw_rectangle (widget->window,
				display->style->fg_gc [GTK_WIDGET_STATE (widget)],
				TRUE,
				x + kml->segment [i]->offset.x,
				y + kml->segment [i]->offset.y,
				kml->segment [i]->size.width,
				kml->segment [i]->size.height);
	    break;
	  }
      }
}


gboolean display_expose_event_callback (GtkWidget *widget,
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

  x = kml->digit_offset.x;
  for (i = 0; i < kml->display_digits; i++)
    {
      draw_digit (widget, x, kml->digit_offset.y, display_segments [i]);
      x += kml->digit_size.width;
    }

  return (TRUE);
}


static void display_update (display_handle_t *display_handle,
			    int digit_count,
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


static void init_annunciator (GdkPixbuf *file_pixbuf, int i)
{
  int row_bytes;
  char *xbm_data;
  char *p;
  int bit;
  int x, y;
  int r, g, b;

  row_bytes = (kml->annunciator [i]->size.width + 7) / 8;

  xbm_data = alloc (row_bytes * kml->annunciator [i]->size.height + 9);
  // $$$ If we don't add at least 9 bytes of padding,
  // gdk_bitmap_create_from_data() will segfault!

#ifdef ANN_DEBUG
  printf ("Annunciator %d:\n", i);
  printf ("height: %d  width: %d  row_bytes: %d\n",
	  kml->annunciator [i]->size.height,
	  kml->annunciator [i]->size.width,
	  row_bytes);
#endif

  for (y = 0; y < kml->annunciator [i]->size.height; y++)
    {
      p = & xbm_data [y * row_bytes];
      bit = 0x80;
      for (x = 0; x < kml->annunciator [i]->size.width; x++)
	{
	  get_pixbuf_pixel (file_pixbuf, 
			    kml->annunciator [i]->offset.x + x,
			    kml->annunciator [i]->offset.y + y,
			    & r, & g, & b);

	  bit = (r == 0) && (g == 0) && (b == 0);
	  // $$$ This needs to be improved!  Perhaps we should compute
	  // the Euclidian distance in the color space between this pixel
	  // value and the display foreground and background colors?

#ifdef ANN_DEBUG
	  printf (bit ? "*" : ".");
#endif
	  if (bit)
	    {
	      (*p) |= bit;
	    }
	  bit >>= 1;
	  if (! bit)
	    {
	      p++;
	      bit = 0x80;
	    }
	}
#ifdef ANN_DEBUG
      printf ("\n");
#endif
    }

  annunciator_bitmap [i] = gdk_bitmap_create_from_data (NULL,
							xbm_data,
							kml->annunciator [i]->size.width,
							kml->annunciator [i]->size.height);

  free (xbm_data);
}


static void init_annunciators (GdkPixbuf *file_pixbuf)
{
  int i;

  for (i = 0; i < KML_MAX_ANNUNCIATOR; i++)
    if (kml->annunciator [i])
      init_annunciator (file_pixbuf, i);
}


typedef struct
{
  GtkWidget *widget [KML_MAX_SWITCH_POSITION];
  GtkWidget *image [KML_MAX_SWITCH_POSITION];
  GtkWidget *fixed;
  kml_switch_t *kml_switch;
  int flag [KML_MAX_SWITCH_POSITION];
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
    sim_set_ext_flag (sim, sw->flag [pos], state);
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
		       kml_switch->position [i]->offset.x - kml->background_offset.x,
		       kml_switch->position [i]->offset.y - kml->background_offset.y);

	if (i == kml_switch->default_position)
	  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (switch_info->widget [i]),
					TRUE);

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


static void init_switch (switch_info_t *sw)
{
  int pos;
  gboolean state;

  for (pos = 0; pos < KML_MAX_SWITCH_POSITION; pos++)
    if (sw->flag [pos])
      {
	state = gtk_toggle_button_get_active (GTK_TOGGLE_BUTTON (sw->widget [pos]));
	sim_set_ext_flag (sim, sw->flag [pos], state);
      }
}

static void init_switches (void)
{
  int i;

  for (i = 0; i < KML_MAX_SWITCH; i++)
    if (switch_info [i])
      init_switch (switch_info [i]);
}


typedef struct
{
  GtkWidget *widget;
  GtkWidget *fixed;
  kml_button_t *kml_button;
} button_info_t;


void button_pressed (GtkWidget *widget, button_info_t *button)
{
  sim_press_key (sim, button->kml_button->keycode);
#ifdef KEYBOARD_DEBUG
  printf ("pressed %d\n", button->kml_button->keycode);
#endif
}


void button_released (GtkWidget *widget, button_info_t *button)
{
  sim_release_key (sim);
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
					    kml_button->offset.x - kml->background_offset.x,
					    kml_button->offset.y - kml->background_offset.y,
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
		 kml_button->offset.x - kml->background_offset.x,
		 kml_button->offset.y - kml->background_offset.y);

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


void process_commands (kml_command_list_t *commands,
		       int scancode,
		       int pressed);


void process_command (kml_command_list_t *command,
		      int scancode,
		      int pressed)
{
  switch (command->cmd)
    {
    case KML_CMD_MAP:
      if (scancode != command->arg1)
	{
	  fprintf (stderr, "scancode %d has map command for scancode %d\n",
		   scancode, command->arg1);
	  return;
	}
      if (! button_info [command->arg2])
	{
	  fprintf (stderr, "scancode %d has map command for nonexistent key %d\n",
		   scancode, command->arg2);
	  return;
	}
      if (pressed)
	{
	  button_pressed (button_info [command->arg2]->widget,
			  button_info [command->arg2]);
	}
      else
	{
	  button_released (button_info [command->arg2]->widget,
			   button_info [command->arg2]);
	}
      break;
    case KML_CMD_IFPRESSED:
      if (pressed)
	process_commands (command->then_part, scancode, pressed);
      else if (command->else_part)
	process_commands (command->else_part, scancode, pressed);
      break;
    default:
      fprintf (stderr, "unimplemented command %d\n", command->cmd);
    }
}

void process_commands (kml_command_list_t *commands,
		       int scancode,
		       int pressed)
{
  while (commands)
    {
      process_command (commands, scancode, pressed);
      commands = commands->next;
    }
}


gboolean on_key_event (GtkWidget *widget, GdkEventKey *event)
{
  kml_scancode_t *scancode;

  if ((event->type != GDK_KEY_PRESS) && 
      (event->type != GDK_KEY_RELEASE))
    return (FALSE);  /* why are we here? */

  for (scancode = kml->first_scancode; scancode; scancode = scancode->next)
    {
      if (event->keyval == scancode->scancode)
	{
	  process_commands (scancode->commands, event->keyval, event->type == GDK_KEY_PRESS);
	  return (TRUE);
	}
    }
  if (scancode_debug)
    fprintf (stderr, "unrecognized scancode %d\n", event->keyval);
  return (FALSE);
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

  dialog = gtk_dialog_new_with_buttons ("About Nonpareil",
					GTK_WINDOW (main_window),
					GTK_DIALOG_MODAL | GTK_DIALOG_DESTROY_WITH_PARENT,
					GTK_STOCK_OK,
					GTK_RESPONSE_NONE,
					NULL);

  gtk_dialog_set_has_separator (GTK_DIALOG (dialog), TRUE);

  sprintf (buf, "Nonpareil release %s", MAKESTR(NONPAREIL_RELEASE));
  gtk_container_add (GTK_CONTAINER (GTK_DIALOG (dialog)->vbox),
		     gtk_label_new (buf));
  gtk_container_add (GTK_CONTAINER (GTK_DIALOG (dialog)->vbox),
		     gtk_label_new ("Microcode-level calculator simulator\n"
				    "Copyright 1995, 2003, 2004 Eric L. Smith\n"
				    "http://nonpareil.brouhaha.com/"));
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


#ifdef HAS_DEBUGGER
void debug_show_reg (GtkWidget *widget, gpointer data)
{
  /* $$$ not yet implemented */
}


void debug_run (GtkWidget *widget, gpointer data)
{
  sim_start (sim);
}


void debug_step (GtkWidget *widget, gpointer data)
{
  sim_step (sim);
}


void debug_trace (GtkWidget *widget, gpointer data)
{
  sim_set_debug_flag (sim, SIM_DEBUG_TRACE,
		      ! sim_get_debug_flag (sim, SIM_DEBUG_TRACE));
}


void debug_key_trace (GtkWidget *widget, gpointer data)
{
  sim_set_debug_flag (sim, SIM_DEBUG_KEY_TRACE,
		      ! sim_get_debug_flag (sim, SIM_DEBUG_KEY_TRACE));
}


void debug_ram_trace (GtkWidget *widget, gpointer data)
{
  sim_set_debug_flag (sim, SIM_DEBUG_RAM_TRACE,
		      ! sim_get_debug_flag (sim, SIM_DEBUG_RAM_TRACE));
}


#ifdef HAS_DEBUGGER_CLI
void debug_cmd_win (GtkWidget *widget, gpointer data)
{
  if (! dbg)
    dbg = init_debugger (sim);

  dbg_visible = ! dbg_visible;

  show_debugger (dbg, dbg_visible);
}
#endif /* HAS_DEBUGGER_CLI */
#endif /* HAS_DEBUGGER */


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
#ifdef HAS_DEBUGGER
    { "/_Debug",        NULL,         NULL,          0, "<Branch>" },
    { "/Debug/Show Reg", NULL,        debug_show_reg, 0, "<Item>" },
    { "/Debug/Run",     NULL,         debug_run,     0, "<Item>" },
    { "/Debug/Step",    NULL,         debug_step,    0, "<Item>" },
    { "/Debug/Trace",   NULL,         debug_trace,   0, "<ToggleItem>" },
    { "/Debug/Key Trace", NULL,     debug_key_trace, 0, "<ToggleItem>" },
    { "/Debug/RAM Trace", NULL,     debug_ram_trace, 0, "<ToggleItem>" },
#ifdef HAS_DEBUGGER_CLI
    { "/Debug/Command Window", NULL,     debug_cmd_win, 0, "<ToggleItem>" },
#endif
#endif
    { "/_Help",         NULL,         NULL,          0, "<LastBranch>" },
    { "/_Help/About",   NULL,         help_about,    0, "<Item>" }
  };

static gint nmenu_items = sizeof (menu_items) / sizeof (GtkItemFactoryEntry);


static GtkWidget *create_menus (GtkWidget *window,
				GtkType container_type)
{
  GtkAccelGroup *accel_group;
  GtkItemFactory *item_factory;

  accel_group = gtk_accel_group_new ();
  item_factory = gtk_item_factory_new (container_type,
				       "<main>",
				       accel_group);
  gtk_item_factory_create_items (item_factory, nmenu_items, menu_items, NULL);
  gtk_window_add_accel_group (GTK_WINDOW (window), accel_group);
  return (gtk_item_factory_get_widget (item_factory, "<main>"));
}


gboolean on_move_window (GtkWidget *widget, GdkEventButton *event)
{
  if (event->type == GDK_BUTTON_PRESS)
    {
      switch (event->button)
	{
	case 1:  /* left button */
	  gtk_window_begin_move_drag (GTK_WINDOW (main_window),
				      event->button,
				      event->x_root,
				      event->y_root,
				      event->time);
	  break;
	case 3:  /* right button */
	  gtk_menu_popup (GTK_MENU (menubar),
			  NULL,  /* parent_menu_shell */
			  NULL,  /* parent_menu_item */
			  NULL,  /* func */
			  NULL,  /* data */
			  event->button,
			  event->time);
	  break;
	}
    }
  return (FALSE);
}


void setup_color (GdkColormap *colormap,
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
      if (kml_debug)
	fprintf (stderr, "KML doesn't specify %s color, using default\n", name);
      gdk_color->red   = default_red;
      gdk_color->green = default_green;
      gdk_color->blue  = default_blue;
    }
  if (! gdk_colormap_alloc_color (colormap, gdk_color, FALSE, TRUE))
    fatal (2, "can't alloc %s color\n", name);
}


#ifndef PATH_MAX
#define PATH_MAX 256
#endif


int main (int argc, char *argv[])
{
  char *kml_fn = NULL;

  gboolean shape = SHAPE_DEFAULT;
  gboolean kml_dump = FALSE;
  gboolean run = TRUE;

  model_info_t *model_info;

  GtkWidget *event_box;

  GtkWidget *vbox;
  GtkWidget *fixed;

  GdkPixbuf *file_pixbuf;  /* the entire image loaded from the file */

  GdkPixbuf *background_pixbuf;  /* window background (subset of file_pixbuf) */
  GError *error = NULL;
  GtkWidget *image;

  GdkBitmap *image_mask_bitmap = NULL;

  GdkColormap *colormap;
  GdkColor display_fg_color, display_bg_color;
  GdkColor image_bg_color;

  char buf [PATH_MAX];

  void *display_handle = NULL;
 
  progname = newstr (argv [0]);

  gtk_init (& argc, & argv);

  while (--argc)
    {
      argv++;
      if (*argv [0] == '-')
	{
	  if (strcasecmp (argv [0], "--shape") == 0)
	    shape = true;
	  else if (strcasecmp (argv [0], "--noshape") == 0)
	    shape = false;
	  else if (strcasecmp (argv [0], "--kmldebug") == 0)
	    kml_debug = 1;
	  else if (strcasecmp (argv [0], "--kmldump") == 0)
	    kml_dump = 1;
	  else if (strcasecmp (argv [0], "--scancodedebug") == 0)
	    scancode_debug = 1;
#ifdef HAS_DEBUGGER
	  else if (strcasecmp (argv [0], "--stop") == 0)
	    run = FALSE;
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

  if (kml_dump)
    {
      print_kml (stdout, kml);
      exit (0);
    }

  if (! kml->image)
    fatal (2, "No image file spsecified in KML\n");

  if (! kml->rom)
    fatal (2, "No ROM file specified in KML\n");

  if (! kml->model)
    fatal (2, "No model specified in KML\n");

  model_info = get_model_info (kml->model);
  if (! model_info)
    fatal (2, "Unrecognized model specified in KML\n");

  sim = sim_init (model_info->platform,
		  model_info->cpu_arch,
		  model_info->clock_frequency,
		  model_info->ram_size,
		  kml->character_segment_map,
		  display_handle,
		  & display_update);

  file_pixbuf = gdk_pixbuf_new_from_file (kml->image, & error);
  if (! file_pixbuf)
    fatal (2, "can't load image '%s'\n", kml->image);

  if (! kml->has_background_size)
    {
      kml->background_size.width = gdk_pixbuf_get_width (file_pixbuf) - kml->background_offset.x;
      kml->background_size.height = gdk_pixbuf_get_height (file_pixbuf) - kml->background_offset.y;
    }

  background_pixbuf = gdk_pixbuf_new_subpixbuf (file_pixbuf,
						kml->background_offset.x,
						kml->background_offset.y,
						kml->background_size.width,
						kml->background_size.height);

  main_window = gtk_window_new (GTK_WINDOW_TOPLEVEL);

  if (kml->has_transparency && shape)
    {
      image_mask_bitmap = (GdkBitmap *) gdk_pixmap_new (NULL,
							kml->background_size.width,
							kml->background_size.height,
							1);
      gdk_pixbuf_render_threshold_alpha (file_pixbuf,
					 image_mask_bitmap,
					 kml->background_offset.x,  /* src_x */
					 kml->background_offset.y,  /* src_y */
					 0, 0,  /* dest_x, _y */
					 kml->background_size.width,
					 kml->background_size.height,
					 kml->transparency_threshold);
    }

  gtk_window_set_resizable (GTK_WINDOW (main_window), FALSE);

  gtk_window_set_title (GTK_WINDOW (main_window),
			kml->title ? kml->title : "Nonpareil");

  event_box = gtk_event_box_new ();
  gtk_container_add (GTK_CONTAINER (main_window), event_box);

  vbox = gtk_vbox_new (FALSE, 1);
  gtk_container_add (GTK_CONTAINER (event_box), vbox);

  if (image_mask_bitmap)
    {
      menubar = create_menus (main_window, GTK_TYPE_MENU);
    }
  else
    {
      menubar = create_menus (main_window, GTK_TYPE_MENU_BAR);
      gtk_box_pack_start (GTK_BOX (vbox), menubar, FALSE, TRUE, 0);
    }

  fixed = gtk_fixed_new ();
  gtk_widget_set_size_request (fixed,
			       kml->background_size.width,
			       kml->background_size.height);
  gtk_box_pack_end (GTK_BOX (vbox), fixed, FALSE, TRUE, 0);

  if (background_pixbuf != NULL)
    {
      image = gtk_image_new_from_pixbuf (background_pixbuf);
      gtk_fixed_put (GTK_FIXED (fixed), image, 0, 0);
    }

  add_switches (background_pixbuf, fixed);

  add_keys (background_pixbuf, fixed);

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

  if (image_mask_bitmap)
    {
      gtk_widget_shape_combine_mask (main_window,
				     image_mask_bitmap,
				     0,
				     0);

      gtk_window_set_decorated (GTK_WINDOW (main_window), FALSE);
    }

  gtk_widget_show_all (main_window);

  init_annunciators (file_pixbuf);

  g_signal_connect (G_OBJECT (display),
		    "expose_event",
		    G_CALLBACK (display_expose_event_callback),
		    NULL);

  g_signal_connect (G_OBJECT (main_window),
		    "key_press_event",
		    G_CALLBACK (on_key_event),
		    NULL);

  g_signal_connect (G_OBJECT (main_window),
		    "key_release_event",
		    G_CALLBACK (on_key_event),
		    NULL);

  if (image_mask_bitmap)
    {
      g_signal_connect (G_OBJECT (main_window),
			"button_press_event",
			G_CALLBACK (on_move_window),
			NULL);
    }

  g_signal_connect (G_OBJECT (main_window),
		    "destroy",
		    GTK_SIGNAL_FUNC (quit_callback),
		    NULL);

  if (! sim_read_object_file (sim, kml->rom))
    fatal (2, "unable to read object file '%s'\n", kml->rom);

#ifdef HAS_DEBUGGER
  if (kml->rom_listing)
    if (! sim_read_listing_file (sim, kml->rom_listing))
      fatal (2, "unable to read listing file '%s'\n", kml->rom_listing);
#endif

  sim_reset (sim);

  init_switches ();

  if (run)
    sim_start (sim);

  gtk_main ();

  exit (0);
}
