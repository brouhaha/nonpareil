/*
$Id$
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

#include <ctype.h>
#include <inttypes.h>
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
#include "kml.h"
#include "display_gtk.h"
#include "proc.h"
#include "keyboard.h"
#include "slide_switch.h"
#include "arch.h"
#include "platform.h"
#include "model.h"
#include "state_io.h"
#include "about.h"

#ifdef HAS_DEBUGGER_GUI
  #include "debugger_gui.h"
#endif

#ifdef HAS_DEBUGGER_CLI
  #include "debugger_cli.h"
#endif

#ifndef SHAPE_DEFAULT
#define SHAPE_DEFAULT true
#endif


char *default_path = MAKESTR(DEFAULT_PATH);

char state_fn [255];

gboolean scancode_debug = FALSE;

static kml_t *kml;

sim_t *sim;

static GtkWidget *main_window;


static GtkWidget *menubar;  /* actually a popup menu in transparency/shape mode */


gui_display_t *gui_display;


void usage (FILE *f)
{
  fprintf (f, "%s:  Microcode-level calculator simulator\n",
	   nonpareil_release);
  fprintf (f, "Copyright 1995, 2003, 2004, 2005 Eric L. Smith\n");
  fprintf (f, "http://nonpareil.brouhaha.com/\n");
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
      if (! set_key_state (command->arg2, pressed))
	{
	  fprintf (stderr, "scancode %d has map command for nonexistent key %d\n",
		   scancode, command->arg2);
	  return;
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
  if (*state_fn)
    state_write_xml (sim, state_fn);
  gtk_main_quit ();
}


static void file_open (GtkWidget *widget, gpointer data)
{
  GtkWidget *dialog;

  dialog = gtk_file_chooser_dialog_new ("Load Calculator State",
					GTK_WINDOW (main_window),
					GTK_FILE_CHOOSER_ACTION_OPEN,
					GTK_STOCK_CANCEL,
					GTK_RESPONSE_CANCEL,
					GTK_STOCK_OPEN,
					GTK_RESPONSE_ACCEPT,
					NULL);

  if (gtk_dialog_run (GTK_DIALOG (dialog)) == GTK_RESPONSE_ACCEPT)
    {
      char *fn = gtk_file_chooser_get_filename (GTK_FILE_CHOOSER (dialog));
      strncpy (state_fn, fn, sizeof (state_fn));
      g_free (fn);
      state_read_xml (sim, state_fn);
    }

  gtk_widget_destroy (dialog);
}


static void file_save_as (GtkWidget *widget, gpointer data)
{
  GtkWidget *dialog;

  dialog = gtk_file_chooser_dialog_new ("Save Calculator State",
					GTK_WINDOW (main_window),
					GTK_FILE_CHOOSER_ACTION_SAVE,
					GTK_STOCK_CANCEL,
					GTK_RESPONSE_CANCEL,
					GTK_STOCK_SAVE,
					GTK_RESPONSE_ACCEPT,
					NULL);

  if (gtk_dialog_run (GTK_DIALOG (dialog)) == GTK_RESPONSE_ACCEPT)
    {
      char *fn = gtk_file_chooser_get_filename (GTK_FILE_CHOOSER (dialog));
      strncpy (state_fn, fn, sizeof (state_fn));
      g_free (fn);
      state_write_xml (sim, state_fn);
    }

  gtk_widget_destroy (dialog);
}


static void file_save (GtkWidget *widget, gpointer data)
{
  if (*state_fn)
    state_write_xml (sim, state_fn);
  else
    file_save_as (widget, data);
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
  about_dialog (main_window, kml);
}


static GtkItemFactoryEntry menu_items [] =
  {
    { "/_File",         NULL,         NULL,          0, "<Branch>" },
    { "/File/_Open",    "<control>O", file_open,     0, "<StockItem>", GTK_STOCK_OPEN },
    { "/File/_Save",    "<control>S", file_save,     0, "<StockItem>", GTK_STOCK_SAVE },
    { "/File/Save _As", NULL,         file_save_as,  0, "<Item>" },
    { "/File/sep1",     NULL,         NULL,          0, "<Separator>" },
    { "/File/_Quit",    "<CTRL>Q",    quit_callback, 0, "<StockItem>", GTK_STOCK_QUIT },
    { "/_Edit",         NULL,         NULL,          0, "<Branch>" },
    { "/Edit/_Copy",    "<control>C", edit_copy,     0, "<StockItem>", GTK_STOCK_COPY },
    { "/Edit/_Paste",   "<control>V", edit_paste,    0, "<StockItem>", GTK_STOCK_PASTE },
#ifdef HAS_DEBUGGER
    { "/_Debug",        NULL,         NULL,          0, "<Branch>" },
#endif
#ifdef HAS_DEBUGGER_GUI
    { "/Debug/Show Reg", NULL,        debug_show_reg, 0, "<Item>" },
    { "/Debug/Show RAM", NULL,        debug_show_ram, 0, "<Item>" },
    { "/Debug/Run",     NULL,         debug_run,     0, "<Item>" },
    { "/Debug/Step",    NULL,         debug_step,    0, "<Item>" },
    { "/Debug/Trace",   NULL,         debug_trace,   0, "<ToggleItem>" },
    { "/Debug/Key Trace", NULL,     debug_key_trace, 0, "<ToggleItem>" },
    { "/Debug/RAM Trace", NULL,     debug_ram_trace, 0, "<ToggleItem>" },
#endif // HAS_DEBUGGER
#ifdef HAS_DEBUGGER_CLI
    { "/Debug/Command Window", NULL,     debug_cmd_win, 0, "<ToggleItem>" },
#endif // HAS_DEBUGGER_CLI
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


void set_default_state_path (void)
{
  const char *p;
  model_info_t *model_info;

  model_info = get_model_info (sim_get_model (sim));

  p = g_get_home_dir ();
  strcpy (state_fn, p);
  // $$$ not sure whether we're supposed to g_free() the home dir string

  max_strncat (state_fn, "/.nonpareil", sizeof (state_fn));
  if (! dir_exists (state_fn))
    {
      if (! create_dir (state_fn))
	warning ("can't create directory '%s'\n", state_fn);
    }

  max_strncat (state_fn, "/", sizeof (state_fn));
  max_strncat (state_fn, model_info->name, sizeof (state_fn));
  max_strncat (state_fn, ".nst", sizeof (state_fn));
}


int main (int argc, char *argv[])
{
  char *kml_name = NULL;
  char *kml_fn, *image_fn, *rom_fn;
#ifdef HAS_DEBUGGER
  char *listing_fn;
#endif

  gboolean shape = SHAPE_DEFAULT;
  gboolean kml_dump = FALSE;
  gboolean run = TRUE;

  int model;
  model_info_t *model_info;

  GtkWidget *event_box;

  GtkWidget *vbox;
  GtkWidget *fixed;

  GdkPixbuf *file_pixbuf;  /* the entire image loaded from the file */

  GdkPixbuf *background_pixbuf;  /* window background (subset of file_pixbuf) */
  GError *error = NULL;
  GtkWidget *image;

  GdkBitmap *image_mask_bitmap = NULL;

  progname = newstr (argv [0]);

  g_thread_init (NULL);

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
      else if (kml_name)
	fatal (1, "only one KML file may be specified\n");
      else
	kml_name = argv [0];
    }

  if (kml_name)
    {
      kml_fn = find_file_in_path_list (kml_name, ".kml", default_path);
      if (! kml_fn)
	fatal (2, "can't find KML file '%s'\n", kml_name);
    }
  else
    {
      char *p = strrchr (progname, '/');
      if (p)
	p++;
      else
	p = progname;
      kml_name = newstrcat (p, ".kml");
      kml_fn = find_file_in_path_list (kml_name, NULL, default_path);
      if (! kml_fn)
	fatal (1, "can't find KML file '%s'\n", kml_name);
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

  model = find_model_by_name (kml->model);
  if (model == MODEL_UNKNOWN)
    fatal (2, "Unrecognized model specified in KML\n");

  model_info = get_model_info (model);

  image_fn = find_file_in_path_list (kml->image, NULL, default_path);
  if (! image_fn)
    fatal (2, "can't find image file '%s'\n", kml->image);

  file_pixbuf = gdk_pixbuf_new_from_file (image_fn, & error);
  if (! file_pixbuf)
    fatal (2, "can't load image '%s'\n", image_fn);

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

  // Have to show everything here, or gui_display_init() can't construct the
  // GCs for the annunciators.
  gtk_widget_show_all (main_window);

  gui_display = gui_display_init (kml,
				  main_window,
				  event_box,
				  fixed,
				  file_pixbuf);
  if (! gui_display)
    fatal (2, "can't initialize display\n");

  sim = sim_init (model,
		  model_info->clock_frequency,
		  model_info->ram_size,
		  kml->character_segment_map,
		  gui_display_update,
		  gui_display);

#ifdef HAS_DEBUGGER_GUI
  init_debugger_gui (sim);
#endif

  add_slide_switches (sim, kml, background_pixbuf, fixed);
  add_keys (sim, kml, background_pixbuf, fixed);

  if (image_mask_bitmap)
    {
      gtk_widget_shape_combine_mask (main_window,
				     image_mask_bitmap,
				     0,
				     0);

      gtk_window_set_decorated (GTK_WINDOW (main_window), FALSE);
    }

  // Have to show everything again, now that we've done gui_display_init()
  // and combined the shape mask.
  gtk_widget_show_all (main_window);

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

  rom_fn = find_file_in_path_list (kml->rom, NULL, default_path);
  if (! rom_fn)
    fatal (2, "can't find ROM file '%s'\n", kml->rom);

  if (! sim_read_object_file (sim, rom_fn))
    fatal (2, "can't read object file '%s'\n", rom_fn);

#ifdef HAS_DEBUGGER
  if (kml->rom_listing)
    {
      listing_fn = find_file_in_path_list (kml->rom_listing, NULL, default_path);
      if (! listing_fn)
	warning ("can't find ROM listing file '%s'\n", kml->rom_listing);
      else if (! sim_read_listing_file (sim, listing_fn))
	warning ("can't read ROM listing file '%s'\n", listing_fn);
    }
#endif

  sim_reset (sim);

  init_slide_switches ();

  set_default_state_path ();

  if ((*state_fn) && file_exists (state_fn))
    state_read_xml (sim, state_fn);

  if (run)
    sim_start (sim);

  gtk_main ();

  exit (0);
}
