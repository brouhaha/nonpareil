/*
Copyright 1995-2022 Eric Smith <spacewar@gmail.com>

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

#include <gsf/gsf-input-stdio.h>
#include <gsf/gsf-infile.h>
#include <gsf/gsf-infile-zip.h>

#include "util.h"
#include "display.h"
#include "keyboard.h"
#include "kml.h"
#include "chip.h"
#include "calcdef.h"
#include "proc.h"
#include "arch.h"
#include "platform.h"
#include "state_io.h"
#include "about.h"
#include "sound.h"
#include "printer.h"
#include "csim.h"
#include "calc_chooser.h"


#ifdef HAS_DEBUGGER_GUI
  #include "debugger_gui.h"
#endif

#ifdef HAS_DEBUGGER_CLI
  #include "debugger_cli.h"
#endif

#ifndef SHAPE_DEFAULT
#define SHAPE_DEFAULT false
#endif

#ifndef SOUND_DEFAULT
#define SOUND_DEFAULT true
#endif


#ifdef DEFAULT_PATH
char *default_path = MAKESTR(DEFAULT_PATH);
#else
char *default_path = NULL;
#endif


#define MAX_GUI_SCALE 4
static int gui_scale = 1;


void print_usage_toggle_option (FILE *f, char *name, bool default_setting)
{
  fprintf (f, "   --%s", name);
  if (default_setting)
    fprintf (f, " (default)");
  fprintf (f, "\n   --no%s", name);
  if (! default_setting)
    fprintf (f, " (default)");
  fprintf (f, "\n");
}

void usage (FILE *f)
{
  fprintf (f, "%s:  Microcode-level calculator simulator\n",
	   nonpareil_release);
  fprintf (f, "Copyright 1995, 2003, 2004, 2005, 2006 Eric L. Smith\n");
  fprintf (f, "http://nonpareil.brouhaha.com/\n");
  fprintf (f, "\n");
  fprintf (f, "usage: %s [options...] nuifile\n", progname);
  fprintf (f, "options:\n");

  print_usage_toggle_option (f, "shape", SHAPE_DEFAULT);
  print_usage_toggle_option (f, "sound", SOUND_DEFAULT);

  fprintf (f, "   --kmldebug\n");
  fprintf (f, "   --kmldump\n");
  fprintf (f, "   --scancodedebug\n");
  fprintf (f, "   --scale <n>\n");
#ifdef HAS_DEBUGGER
  fprintf (f, "   --stop\n");
#endif
}


void process_commands (csim_t *csim,
		       kml_command_list_t *commands,
		       int scancode,
		       int pressed);


void process_command (csim_t *csim,
		      kml_command_list_t *command,
		      int scancode,
		      int pressed)
{
  switch (command->cmd)
    {
    case KML_CMD_MAP:
      if (command->arg1 && (scancode != command->arg1))
	{
	  fprintf (stderr, "scancode %d has map command for scancode %d\n",
		   scancode, command->arg1);
	  return;
	}
      if (! set_key_state (csim, command->arg2, pressed))
	{
	  fprintf (stderr, "scancode %d has map command for nonexistent key %d\n",
		   scancode, command->arg2);
	  return;
	}
      break;
    case KML_CMD_IFPRESSED:
      if (pressed)
	process_commands (csim, command->then_part, scancode, pressed);
      else if (command->else_part)
	process_commands (csim, command->else_part, scancode, pressed);
      break;
    default:
      fprintf (stderr, "unimplemented command %d\n", command->cmd);
    }
}

void process_commands (csim_t *csim,
		       kml_command_list_t *commands,
		       int scancode,
		       int pressed)
{
  while (commands)
    {
      process_command (csim, commands, scancode, pressed);
      commands = commands->next;
    }
}


gboolean key_event_callback (GtkWidget *widget UNUSED,
			     GdkEventKey *event,
			     gpointer data)
{
  csim_t *csim = data;
  kml_scancode_t *scancode;

  if ((event->type != GDK_KEY_PRESS) && 
      (event->type != GDK_KEY_RELEASE))
    return (FALSE);  /* why are we here? */

#if 0
  printf ("key_event_callback, keycode=%d, type=%s\n",
	  event->keyval, (event->type == GDK_KEY_PRESS) ? "press" : "release");
#endif

  for (scancode = csim->kml->first_scancode; scancode; scancode = scancode->next)
    {
      if (event->keyval == scancode->scancode)
	{
	  process_commands (csim,
			    scancode->commands,
			    event->keyval,
			    event->type == GDK_KEY_PRESS);
	  return (TRUE);
	}
    }
  if (csim->scancode_debug)
    fprintf (stderr, "unrecognized scancode %d\n", event->keyval);
  return (FALSE);
}


static void main_window_destroy_callback (GtkWidget *widget UNUSED,
					  gpointer data)
{
  csim_t *csim = data;

  if (csim->state_fn [0])
    state_write_xml (csim->sim, csim->state_fn);
  gtk_main_quit ();
}


static void quit_callback (gpointer callback_data,
			   guint    callback_action UNUSED,
			   GtkWidget *widget        UNUSED)
{
  csim_t *csim = callback_data;

  if (csim->state_fn [0])
    state_write_xml (csim->sim, csim->state_fn);
  gtk_main_quit ();
}


static void file_open (gpointer callback_data,
		       guint    callback_action UNUSED,
		       GtkWidget *widget        UNUSED)
{
  csim_t *csim = callback_data;
  GtkWidget *dialog;

  dialog = gtk_file_chooser_dialog_new ("Load Calculator State",
					GTK_WINDOW (csim->main_window),
					GTK_FILE_CHOOSER_ACTION_OPEN,
					GTK_STOCK_CANCEL,
					GTK_RESPONSE_CANCEL,
					GTK_STOCK_OPEN,
					GTK_RESPONSE_ACCEPT,
					NULL);

  if (gtk_dialog_run (GTK_DIALOG (dialog)) == GTK_RESPONSE_ACCEPT)
    {
      char *fn = gtk_file_chooser_get_filename (GTK_FILE_CHOOSER (dialog));
      strlcpy (csim->state_fn, fn, sizeof (csim->state_fn));
      g_free (fn);
      state_read_xml (csim->sim, csim->state_fn);
      gui_slide_switches_update_from_sim (csim->gui_switches);
    }

  gtk_widget_destroy (dialog);
}


// handles save (action==1) and save as (action==2)
static void file_save (gpointer callback_data,
		       guint    callback_action,
		       GtkWidget *widget UNUSED)
{
  csim_t *csim = callback_data;
  GtkWidget *dialog;

  if ((callback_action == 1) && (csim->state_fn [0]))
    {
      state_write_xml (csim->sim, csim->state_fn);
      return;
    }

  dialog = gtk_file_chooser_dialog_new ("Save calculator state",
					GTK_WINDOW (csim->main_window),
					GTK_FILE_CHOOSER_ACTION_SAVE,
					GTK_STOCK_CANCEL,
					GTK_RESPONSE_CANCEL,
					GTK_STOCK_SAVE,
					GTK_RESPONSE_ACCEPT,
					NULL);

  if (gtk_dialog_run (GTK_DIALOG (dialog)) == GTK_RESPONSE_ACCEPT)
    {
      char *fn = gtk_file_chooser_get_filename (GTK_FILE_CHOOSER (dialog));
      strlcpy (csim->state_fn, fn, sizeof (csim->state_fn));
      g_free (fn);
      state_write_xml (csim->sim, csim->state_fn);
    }

  gtk_widget_destroy (dialog);
}


static void edit_copy (gpointer callback_data   UNUSED,
		       guint    callback_action UNUSED,
		       GtkWidget *widget        UNUSED)
{
  // csim_t *csim = callback_data;
  // $$$ not yet implemented
}


static void edit_paste (gpointer callback_data   UNUSED,
			guint    callback_action UNUSED,
			GtkWidget *widget        UNUSED)
{
  // csim_t *csim = callback_data;
  // $$$ not yet implemented
}


static void reset (sim_t *sim, bool obdurate)
{
  bool run_flag;

  run_flag = sim_running (sim);
  if (run_flag)
    sim_stop (sim);

  sim_reset (sim);
  if (obdurate)
    sim_clear_memory (sim);
  
  if (run_flag)
    sim_start (sim);
}


static char reset_message [] =
  "Resetting the calculator may erase any data and programs you have "
  "entered.  Are you sure you want to reset the calculator?";

static void edit_reset (gpointer callback_data,
			guint    callback_action,
			GtkWidget *widget UNUSED)
{
  csim_t *csim = callback_data;
  GtkWidget *dialog;
  bool obdurate = callback_action != 0;
  GtkResponseType response;

  dialog = gtk_message_dialog_new (GTK_WINDOW (csim->main_window),
				   GTK_DIALOG_DESTROY_WITH_PARENT,
				   GTK_MESSAGE_QUESTION,
				   GTK_BUTTONS_YES_NO,
				   reset_message);

  response = gtk_dialog_run (GTK_DIALOG (dialog));

  gtk_widget_destroy (dialog);

  if (response == GTK_RESPONSE_YES)
    reset (csim->sim, obdurate);
}


static uint8_t get_port_mask (sim_t *sim)
{
  int port;
  uint8_t mask = 0;

  for (port = 1; port <= 4; port++)
    if (plugin_module_get_by_port (sim, port))
      mask |= (1 << (port - 1));
  return mask;
}


static void set_menu_enable (csim_t *csim,
			     const gchar *path,
			     gboolean enable)
{
  GtkWidget *menu_item;

  menu_item = gtk_item_factory_get_widget (csim->main_menu_item_factory, path);
  gtk_widget_set_sensitive (GTK_WIDGET (menu_item), enable);
}


static void configure_configure_menu (csim_t *csim)
{
  uint8_t port_mask = get_port_mask (csim->sim);

  set_menu_enable (csim,
		   "<main>/Configure/Load Module",
		   port_mask != 0xf);

  set_menu_enable (csim,
		   "<main>/Configure/Unload Module",
		   port_mask != 0x0);
}


static void port_number_label_callback (GtkWidget *widget, gpointer data)
{
  int *port = data;
  const gchar *text = gtk_label_get_text (GTK_LABEL (widget));
  *port = atoi (text);
}


static void port_number_radio_button_callback (GtkWidget *widget, gpointer data)
{
  gtk_container_foreach (GTK_CONTAINER (widget),
			 port_number_label_callback,
			 data);
}


typedef struct module_t
{
  char *path;
  int port;
  plugin_module_t *module;  // opaque
} module_t;


GList *module_list;


static GtkWidget *create_port_frame (csim_t *csim,
				     uint8_t port_mask,
				     int *result_port)
{
  GtkWidget *port_frame;
  GtkWidget *port_box;
  GtkWidget *first_port_radio_button = NULL;
  GtkWidget *first_enabled_port_radio_button = NULL;
  int port;

  port_frame = gtk_frame_new ("Port");
  port_box = gtk_vbutton_box_new ();

  for (port = 1; port <= 4; port++)
    {
      GtkWidget *button;
      plugin_module_t *module;
      char label [48];

      module = plugin_module_get_by_port (csim->sim, port);
      snprintf (label, sizeof (label), "%d: %s", port,
		module ? plugin_module_get_name (module) : "<empty>");

      if (! first_port_radio_button)
	{
	  button = gtk_radio_button_new_with_label (NULL, label);
	  first_port_radio_button = button;
	}
      else
	button = gtk_radio_button_new_with_label_from_widget (GTK_RADIO_BUTTON (first_port_radio_button), label);

      if (! (port_mask & (1 << (port - 1))))
	gtk_widget_set_sensitive (button, false);
      else if (! first_enabled_port_radio_button)
	first_enabled_port_radio_button = button;

      g_signal_connect (G_OBJECT (button),
			"clicked",
			G_CALLBACK (port_number_radio_button_callback),
			result_port);
      gtk_container_add (GTK_CONTAINER (port_box), button);
    }

  *result_port = 1;

  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (first_enabled_port_radio_button),
				true);

  gtk_container_add (GTK_CONTAINER (port_frame), port_box);
  gtk_widget_show_all (port_frame);
  return port_frame;
}


static void configure_load_module (gpointer callback_data,
				   guint    callback_action UNUSED,
				   GtkWidget *widget        UNUSED)
{
  csim_t *csim = callback_data;
  GtkWidget *dialog;
  uint8_t port_mask;
  int port;
  GtkWidget *port_frame;
  GtkFileFilter *mod_filter;
  char *fn;
  module_t *module;

  dialog = gtk_file_chooser_dialog_new ("Load Module",
					GTK_WINDOW (csim->main_window),
					GTK_FILE_CHOOSER_ACTION_OPEN,
					GTK_STOCK_CANCEL,
					GTK_RESPONSE_CANCEL,
					GTK_STOCK_OPEN,
					GTK_RESPONSE_ACCEPT,
					NULL);

  // get mask of empty ports
  port_mask = get_port_mask (csim->sim) ^ 0xf;

  port_frame = create_port_frame (csim, port_mask, & port);

  gtk_file_chooser_set_extra_widget (GTK_FILE_CHOOSER (dialog),
				     port_frame);

  mod_filter = gtk_file_filter_new ();

  gtk_file_filter_add_pattern (mod_filter, "*.mod");

  gtk_file_chooser_set_filter (GTK_FILE_CHOOSER (dialog), mod_filter);

  if (gtk_dialog_run (GTK_DIALOG (dialog)) != GTK_RESPONSE_ACCEPT)
    {
      gtk_widget_destroy (dialog);
      return;
    }
  
  fn = gtk_file_chooser_get_filename (GTK_FILE_CHOOSER (dialog));
  gtk_widget_destroy (dialog);

  // $$$ should check whether module is already loaded, most modules
  // only allow a single instance

  module = alloc (sizeof (module_t));
  module->module = sim_install_module (csim->sim, fn, port, false);

  if (! module->module)
    {
      dialog = gtk_message_dialog_new (GTK_WINDOW (csim->main_window),
				       GTK_DIALOG_DESTROY_WITH_PARENT,
				       GTK_MESSAGE_ERROR,
				       GTK_BUTTONS_CLOSE,
				       "Error loading module file '%s'",
				       fn);
      gtk_dialog_run (GTK_DIALOG (dialog));
      gtk_widget_destroy (dialog);
      free (module);
    }

  module->path = newstr (fn);
  g_free (fn);

  module->port = port;

  module_list = g_list_append (module_list, module);

  configure_configure_menu (csim);
}


static void configure_unload_module (gpointer callback_data,
				     guint    callback_action UNUSED,
				     GtkWidget *widget        UNUSED)
{
  csim_t *csim = callback_data;
  GtkWidget *dialog;
  GtkWidget *content_area;
  GtkWidget *label;
  uint8_t port_mask;
  int port;
  GtkWidget *port_frame;

  dialog = gtk_dialog_new_with_buttons ("Unload module",
					GTK_WINDOW (csim->main_window),
					GTK_DIALOG_DESTROY_WITH_PARENT,
					GTK_STOCK_CANCEL,
					GTK_RESPONSE_CANCEL,
					GTK_STOCK_OK,
					GTK_RESPONSE_OK,
					NULL);

#if 0
  content_area = GTK_WIDGET (GTK_DIALOG (dialog)->vbox);
#else
  content_area = gtk_dialog_get_content_area (GTK_DIALOG (dialog));
#endif

  label = gtk_label_new ("Unload module");

  gtk_container_add (GTK_CONTAINER (content_area), label);

  g_signal_connect_swapped (dialog,
			    "response",
			    G_CALLBACK (gtk_widget_destroy),
			    dialog);

  port_mask = get_port_mask (csim->sim);
  port_frame = create_port_frame (csim, port_mask, & port);

  gtk_container_add (GTK_CONTAINER (content_area), port_frame);

  gtk_widget_show_all (dialog);

  configure_configure_menu (csim);
}


static void help_about (gpointer callback_data,
			guint    callback_action UNUSED,
			GtkWidget *widget        UNUSED)
{
  csim_t *csim = callback_data;

  about_dialog (csim->main_window, csim->kml);
}


static GtkItemFactoryEntry menu_items [] =
  {
    { "/_File",         NULL,         NULL,          0, "<Branch>", 0 },
    { "/File/_Open",    "<control>O", file_open,     1, "<StockItem>", GTK_STOCK_OPEN },
    { "/File/_Save",    "<control>S", file_save,     1, "<StockItem>", GTK_STOCK_SAVE },
    { "/File/Save _As", NULL,         file_save,     2, "<Item>", 0 },
    { "/File/sep1",     NULL,         NULL,          0, "<Separator>", 0 },
    { "/File/_Quit",    "<CTRL>Q",    quit_callback, 1, "<StockItem>", GTK_STOCK_QUIT },
    { "/_Edit",         NULL,         NULL,          0, "<Branch>", 0 },
    { "/Edit/_Copy",    "<control>C", edit_copy,     1, "<StockItem>", GTK_STOCK_COPY },
    { "/Edit/_Paste",   "<control>V", edit_paste,    1, "<StockItem>", GTK_STOCK_PASTE },
    { "/Edit/sep1",     NULL,         NULL,          0, "<Separator>", 0 },
    { "/Edit/Hard Reset", NULL,       edit_reset,    0, "<Item>", 0 },
    { "/Edit/Obdurate Reset", NULL,   edit_reset,    1, "<Item>", 0 },
    { "/_Configure",    NULL,         NULL,          0, "<Branch>", 0 },
    { "/Configure/Load Module", NULL, configure_load_module, 1, "<Item>", 0 },
    { "/Configure/Unload Module", NULL, configure_unload_module, 1, "<Item>", 0 },
#ifdef HAS_DEBUGGER
    { "/_Debug",        NULL,         NULL,          0, "<Branch>", 0 },
#endif
#ifdef HAS_DEBUGGER_GUI
    { "/Debug/Show reg", NULL,        debug_show_reg, 1, "<Item>", 0 },
    { "/Debug/Show RAM", NULL,        debug_show_ram, 1, "<Item>", 0 },
    { "/Debug/Run",     NULL,         debug_run,     1, "<Item>", 0 },
    { "/Debug/Step",    NULL,         debug_step,    1, "<Item>", 0 },
    { "/Debug/Reset cycle count", NULL, debug_reset_cycle_count, 1, "<Item>", 0 },
    { "/Debug/sep1",     NULL,         NULL,          0, "<Separator>", 0 },
    { "/Debug/Log file", NULL,        debug_log,     2, "<ToggleItem>", 0 },
    { "/Debug/Trace",   NULL,         debug_trace,   1, "<ToggleItem>", 0 },
    { "/Debug/Key trace", NULL,     debug_key_trace, 1, "<ToggleItem>", 0 },
    { "/Debug/RAM trace", NULL,     debug_ram_trace, 1, "<ToggleItem>", 0 },
    { "/Debug/Dump ROM", NULL,      debug_dump_rom,  1, "<Item>", 0 },
#endif // HAS_DEBUGGER
#ifdef HAS_DEBUGGER_CLI
    { "/Debug/Command window", NULL,     debug_cli_window, 1, "<ToggleItem>", 0 },
#endif // HAS_DEBUGGER_CLI
    { "/_Help",         NULL,         NULL,          0, "<Branch>", 0 },
    { "/_Help/About",   NULL,         help_about,    1, "<Item>", 0 }
  };

static gint nmenu_items = sizeof (menu_items) / sizeof (GtkItemFactoryEntry);


static GtkWidget *create_menus (csim_t *csim,
				GtkType container_type)
{
  GtkAccelGroup *accel_group;

  accel_group = gtk_accel_group_new ();
  csim->main_menu_item_factory = gtk_item_factory_new (container_type,
						       "<main>",
						       accel_group);
  gtk_item_factory_create_items (csim->main_menu_item_factory,
				 nmenu_items,
				 menu_items,
				 csim);

  set_menu_enable (csim, "<main>/Configure/Unload Module", false);
  //configure_configure_menu (csim);

  gtk_window_add_accel_group (GTK_WINDOW (csim->main_window), accel_group);
  return (gtk_item_factory_get_widget (csim->main_menu_item_factory,
				       "<main>"));
}


gboolean move_window_callback (GtkWidget *widget UNUSED,
			       GdkEventButton *event,
			       gpointer data)
{
  csim_t *csim = data;

  if (event->type == GDK_BUTTON_PRESS)
    {
      switch (event->button)
	{
	case 1:  /* left button */
	  gtk_window_begin_move_drag (GTK_WINDOW (csim->main_window),
				      event->button,
				      event->x_root,
				      event->y_root,
				      event->time);
	  break;
	case 3:  /* right button */
	  gtk_menu_popup (GTK_MENU (csim->menubar),
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


void set_default_state_path (csim_t *csim)
{
  const char *p;
  const char *model_name;

  model_name = calcdef_get_model_name (sim_get_calcdef (csim->sim));

  p = g_get_home_dir ();
  strcpy (csim->state_fn, p);
  // $$$ not sure whether we're supposed to g_free() the home dir string

  max_strncat (csim->state_fn, G_DIR_SEPARATOR_S, sizeof (csim->state_fn));

#ifdef MS_WINDOWS
  max_strncat (csim->state_fn, "nonpareil", sizeof (csim->state_fn));
#else
  max_strncat (csim->state_fn, ".nonpareil", sizeof (csim->state_fn));
#endif

  if (! dir_exists (csim->state_fn))
    {
      if (! create_dir (csim->state_fn))
	warning ("can't create directory '%s'\n", csim->state_fn);
    }

  max_strncat (csim->state_fn, "/", sizeof (csim->state_fn));
  max_strncat (csim->state_fn, model_name, sizeof (csim->state_fn));
  max_strncat (csim->state_fn, ".nst", sizeof (csim->state_fn));
}


bool gui_remove_hardware (void *ref             UNUSED,
			  chip_type_t chip_type UNUSED)
{
  return false;  // $$$ not yet implemented
}


GdkPixbuf *load_pixbuf_from_file (char *image_name)
{
  GError *error = NULL;
  char *image_fn;
  GdkPixbuf *pixbuf;

  image_fn = find_file_in_path_list (image_name, NULL, default_path);
  if (! image_fn)
    fatal (2, "can't find image file '%s'\n", image_name);
  pixbuf = gdk_pixbuf_new_from_file (image_fn, & error);
  if (! pixbuf)
    fatal (2, "can't load image '%s'\n", image_fn);
  free (image_fn);
  return pixbuf;
}

GdkPixbuf *load_pixbuf_from_nui (GsfInfile *nui, char *image_name)
{
  GsfInput *image_input;
  GdkPixbufLoader *loader;
  GdkPixbuf *pixbuf;
  unsigned char buf [1024];

  image_input = gsf_infile_child_by_name (nui, image_name);
  if (! image_input)
    return NULL;

  loader = gdk_pixbuf_loader_new ();

  while (1)
    {
      size_t count = gsf_input_remaining (image_input);
      if (! count)
	break;
      if (count > sizeof (buf))
	count = sizeof (buf);
      unsigned char const *rp = gsf_input_read (image_input, count, buf);
      if (! rp)
	fatal (2, "error reading image\n");
      if (! gdk_pixbuf_loader_write (loader, buf, count, NULL))
	fatal (2, "error loading image\n");
    }

  if (! gdk_pixbuf_loader_close (loader, NULL))
    fatal (2, "error loading image\n");

  pixbuf = gdk_pixbuf_loader_get_pixbuf (loader);
  if (pixbuf)
    g_object_ref (G_OBJECT (pixbuf));

  g_object_unref (G_OBJECT (image_input));
  g_object_unref (G_OBJECT (loader));
  return pixbuf;
}


GdkPixbuf *load_pixbuf (csim_t *csim, char *image_name)
{
  GdkPixbuf *pixbuf = NULL;

  if (csim->nui)
    pixbuf = load_pixbuf_from_nui (csim->nui, image_name);

  if (! pixbuf)
    pixbuf = load_pixbuf_from_file (image_name);

  if (! pixbuf)
    fatal (2, "Can't load image '%s'\n", image_name);

  return pixbuf;
}



GdkPixbuf *load_pixbuf_scaled (csim_t *csim, char *image_name)
{
  GdkPixbuf *pixbuf = NULL;

  pixbuf = load_pixbuf (csim, image_name);

  if (gui_scale != 1)
    {
      pixbuf = gdk_pixbuf_scale_simple (pixbuf,
					gdk_pixbuf_get_width (pixbuf) * gui_scale,
					gdk_pixbuf_get_height (pixbuf) * gui_scale,
					GDK_INTERP_NEAREST);
      if (! pixbuf)
	fatal (2, "can't scale image '%s'\n", image_name);
    }
    
  return pixbuf;
}



GsfInfile *open_zip_file (char *zip_fn)
{
  GsfInput *zip_input;
  GsfInfile *zip_infile;
  GError *err = NULL;

  zip_input = gsf_input_stdio_new (zip_fn, & err);
  if (! zip_input)
    return NULL;

  zip_infile = gsf_infile_zip_new (zip_input, & err);
  if (! zip_infile)
    return NULL;

  g_object_unref (G_OBJECT (zip_input));

  return (zip_infile);
}


void close_zip_file (GsfInfile *infile)
{
  g_object_unref (G_OBJECT (infile));
}


void setup_path (void)
{
  char *p = getenv ("NONPAREIL_PATH");
  if (p)
    default_path = p;
}


int main (int argc, char *argv[])
{
  csim_t *csim;
  char *cmd_line_filename = NULL;
  char *kml_fn = NULL;
  char *nui_fn = NULL;
  char *ncd_fn = NULL;

  csim = alloc (sizeof (csim_t));

  gboolean shape = SHAPE_DEFAULT;
  gboolean kml_dump = FALSE;
  gboolean run = TRUE;
  bool sound_enabled = TRUE;

  GtkWidget *vbox;

  GdkBitmap *image_mask_bitmap = NULL;

  progname = newstr (argv [0]);

  setup_path ();

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
	  else if (strcasecmp (argv [0], "--sound") == 0)
	    sound_enabled = true;
	  else if (strcasecmp (argv [0], "--nosound") == 0)
	    sound_enabled = false;
	  else if (strcasecmp (argv [0], "--kmldump") == 0)
	    kml_dump = 1;
	  else if (strcasecmp (argv [0], "--scale") == 0)
	    {
	      if (! --argc)
		  fatal (1, "--scale argument needs argument\n");
	      argv++;
	      gui_scale = atoi(argv [0]);
	      if ((gui_scale < 1) || (gui_scale > MAX_GUI_SCALE))
		fatal (1, "--scale needs integer argument between 1 and %d\n", MAX_GUI_SCALE);
	    }
	  else if (strcasecmp (argv [0], "--scancodedebug") == 0)
	    csim->scancode_debug = 1;
#ifdef HAS_DEBUGGER
	  else if (strcasecmp (argv [0], "--stop") == 0)
	    run = FALSE;
#endif
	  else
	    fatal (1, "unrecognized option '%s'\n", argv [0]);
	}
      else if (cmd_line_filename)
	fatal (1, "only one NUI or KML file may be specified\n");
      else
	cmd_line_filename = argv [0];
    }

  init_sound (sound_enabled);

  if (! cmd_line_filename)
    {
      cmd_line_filename = calculator_chooser (default_path);
      if (! cmd_line_filename)
	fatal (2, "No NUI or KML file specified.\n");
    }

  if (filename_suffix_match (cmd_line_filename, ".nui"))
    nui_fn = find_file_with_suffix (cmd_line_filename, ".nui", default_path);
  else
    {
      nui_fn = find_file_with_suffix (cmd_line_filename, ".nui", default_path);
      if (! nui_fn)
	fatal (2, "Can't find NUI or KML file\n");
    }


  if (nui_fn)
    {
      csim->nui = open_zip_file (nui_fn);
      if (! csim->nui)
	fatal (2, "Error opening or reading NUI file\n");

      kml_fn = base_filename_with_suffix (nui_fn, "kml");

      csim->kml = read_kml_file_from_gsfinfile (csim->nui, kml_fn);
      if (! csim->kml)
	fatal (2, "can't read KML '%s' from NUI file '%s'\n", kml_fn, nui_fn);
    }
  else if (kml_fn)
    {
      csim->kml = read_kml_file (kml_fn);
      if (! csim->kml)
	fatal (2, "can't read KML file '%s'\n", kml_fn);
    }
  else
    {
      fatal (1, "no KML file\n");
    }

  if (gui_scale != 1)
    {
      rescale_kml_file(csim->kml, gui_scale);
    }

  if (kml_dump)
    {
      print_kml (stdout, csim->kml);
      exit (0);
    }

  if (! csim->kml->image_fn)
    fatal (2, "No image file spsecified in KML\n");

  csim->file_pixbuf = load_pixbuf_scaled (csim, csim->kml->image_fn);

  if (! csim->kml->has_background_size)
    {
      csim->kml->background_size.width = gdk_pixbuf_get_width (csim->file_pixbuf) - csim->kml->background_offset.x;
      csim->kml->background_size.height = gdk_pixbuf_get_height (csim->file_pixbuf) - csim->kml->background_offset.y;
    }

  csim->background_pixbuf = gdk_pixbuf_new_subpixbuf (csim->file_pixbuf,
						      csim->kml->background_offset.x,
						      csim->kml->background_offset.y,
						      csim->kml->background_size.width,
						      csim->kml->background_size.height);

  csim->main_window = gtk_window_new (GTK_WINDOW_TOPLEVEL);

  if (csim->kml->has_transparency && shape)
    {
      image_mask_bitmap = (GdkBitmap *) gdk_pixmap_new (NULL,
							csim->kml->background_size.width,
							csim->kml->background_size.height,
							1);
      gdk_pixbuf_render_threshold_alpha (csim->file_pixbuf,
					 image_mask_bitmap,
					 csim->kml->background_offset.x,  /* src_x */
					 csim->kml->background_offset.y,  /* src_y */
					 0, 0,  /* dest_x, _y */
					 csim->kml->background_size.width,
					 csim->kml->background_size.height,
					 csim->kml->transparency_threshold);
    }

  gtk_window_set_resizable (GTK_WINDOW (csim->main_window), FALSE);

  gtk_window_set_title (GTK_WINDOW (csim->main_window),
			csim->kml->title ? csim->kml->title : "Nonpareil");

  csim->event_box = gtk_event_box_new ();
  gtk_container_add (GTK_CONTAINER (csim->main_window), csim->event_box);

  vbox = gtk_vbox_new (FALSE, 1);
  gtk_container_add (GTK_CONTAINER (csim->event_box), vbox);

  if (image_mask_bitmap)
    {
      csim->menubar = create_menus (csim, GTK_TYPE_MENU);
    }
  else
    {
      csim->menubar = create_menus (csim, GTK_TYPE_MENU_BAR);
      gtk_box_pack_start (GTK_BOX (vbox), csim->menubar, FALSE, TRUE, 0);
    }

  csim->fixed = gtk_fixed_new ();
  gtk_widget_set_size_request (csim->fixed,
			       csim->kml->background_size.width,
			       csim->kml->background_size.height);
  gtk_box_pack_end (GTK_BOX (vbox), csim->fixed, FALSE, TRUE, 0);

  if (csim->background_pixbuf != NULL)
    {
      csim->background_image = gtk_image_new_from_pixbuf (csim->background_pixbuf);
      gtk_fixed_put (GTK_FIXED (csim->fixed), csim->background_image, 0, 0);
    }

  if (csim->kml->default_overlay_image_fn)
    csim->overlay_pixbuf = load_pixbuf_scaled (csim,
					       csim->kml->default_overlay_image_fn);

  if (csim->overlay_pixbuf != NULL)
    {
      csim->overlay_image = gtk_image_new_from_pixbuf (csim->overlay_pixbuf);
      gtk_fixed_put (GTK_FIXED (csim->fixed), csim->overlay_image, 0, 0);
    }

  // Have to show everything here, or gui_display_init() can't construct the
  // GCs for the annunciators.
  gtk_widget_show_all (csim->main_window);

  csim->gui_display = gui_display_init (csim);
  if (! csim->gui_display)
    fatal (2, "can't initialize display\n");

  ncd_fn = find_file_with_suffix (csim->kml->model, ".ncd", default_path);
  if (! ncd_fn)
    fatal (2, "can't find .ncd file\n");

  csim->sim = sim_init (ncd_fn,
			(display_update_callback_fn_t *) gui_display_update,
			csim->gui_display);  // display_update_callback_ref

  // Only the Coconut platform (41C family) is configurable, so remove
  // the Configure menu if the platform isn't a Coconut.
  if (calcdef_get_platform (sim_get_calcdef (csim->sim)) != PLATFORM_COCONUT)
    gtk_container_remove (GTK_CONTAINER (csim->menubar),
			  gtk_item_factory_get_item (csim->main_menu_item_factory,
						     "/Configure"));

#ifdef HAS_DEBUGGER_GUI
  init_debugger_gui (csim);
#endif

#ifdef HAS_DEBUGGER_CLI
  init_debugger_cli (csim->sim);
#endif

  csim->gui_switches = gui_switches_init (csim);

  add_keys (csim);

  if (image_mask_bitmap)
    {
      gtk_widget_shape_combine_mask (csim->main_window,
				     image_mask_bitmap,
				     0,
				     0);

      gtk_window_set_decorated (GTK_WINDOW (csim->main_window), FALSE);
    }

  // Have to show everything again, now that we've done gui_display_init()
  // and combined the shape mask.
  gtk_widget_show_all (csim->main_window);

  g_signal_connect (G_OBJECT (csim->main_window),
		    "key_press_event",
		    G_CALLBACK (key_event_callback),
		    csim);

  g_signal_connect (G_OBJECT (csim->main_window),
		    "key_release_event",
		    G_CALLBACK (key_event_callback),
		    csim);

  if (image_mask_bitmap)
    {
      g_signal_connect (G_OBJECT (csim->main_window),
			"button_press_event",
			G_CALLBACK (move_window_callback),
			csim);
    }

  g_signal_connect (G_OBJECT (csim->main_window),
		    "destroy",
		    GTK_SIGNAL_FUNC (main_window_destroy_callback),
		    csim);

  sim_reset (csim->sim);

  set_default_state_path (csim);

  if ((csim->state_fn [0]) && file_exists (csim->state_fn))
    state_read_xml (csim->sim, csim->state_fn);

  gui_slide_switches_update_from_sim (csim->gui_switches);

  if (run)
    sim_start (csim->sim);

  gtk_main ();

  exit (0);
}
