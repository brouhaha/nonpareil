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
#include "arch.h"
#include "platform.h"
#include "model.h"
#include "state_io.h"

#ifdef HAS_DEBUGGER_CLI
  #include "debugger.h"
#endif

#ifndef SHAPE_DEFAULT
#define SHAPE_DEFAULT true
#endif


char *default_path = MAKESTR(DEFAULT_PATH);

char state_fn [255];

gboolean scancode_debug = FALSE;

static kml_t *kml;

sim_t *sim;

#ifdef HAS_DEBUGGER_CLI
gboolean dbg_visible;
dbg_t *dbg;
#endif


static GtkWidget *main_window;

#ifdef HAS_DEBUGGER
static GtkWidget *reg_window;
static gboolean reg_visible;
static int max_reg;
#define MAX_REG 200
static int reg_width [MAX_REG];
static GtkWidget *reg_widget [MAX_REG];
static reg_info_t *reg_info [MAX_REG];
#endif

static GtkWidget *menubar;  /* actually a popup menu in transparency/shape mode */


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
  if (*state_fn)
    {
      printf ("saving '%s'\n", state_fn);
      state_write_xml (sim, state_fn);
    }
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
  GtkWidget *dialog;

  dialog = gtk_dialog_new_with_buttons ("About Nonpareil",
					GTK_WINDOW (main_window),
					GTK_DIALOG_MODAL | GTK_DIALOG_DESTROY_WITH_PARENT,
					GTK_STOCK_OK,
					GTK_RESPONSE_NONE,
					NULL);

  gtk_dialog_set_has_separator (GTK_DIALOG (dialog), TRUE);

  gtk_container_add (GTK_CONTAINER (GTK_DIALOG (dialog)->vbox),
		     gtk_label_new (nonpareil_release));
  gtk_container_add (GTK_CONTAINER (GTK_DIALOG (dialog)->vbox),
		     gtk_label_new ("Microcode-level calculator simulator\n"
				    "Copyright 1995, 2003, 2004, 2005 Eric L. Smith\n"
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


static void binary_to_string (char *buf, int bits, uint64_t val)
{
  int i;

  for (i = bits - 1; i >= 0; i--)
    *(buf++) = (val & (1ull << i)) ? '1' : '0';
  *(buf++) = '\0';
}


static void update_register_window (void)
{
  int reg_num;
  char buf [80];
  uint64_t val;

  for (reg_num = 0; reg_num < max_reg; reg_num++)
    {
      reg_info_t *info = reg_info [reg_num];
      if (sim_read_register (sim,
			     0,  // $$$ CPU only for now
			     reg_num,
			     0,
			     & val))
	{
	  if (info->display_radix == 16)
	    snprintf (buf, sizeof (buf), "%0*" PRIx64, reg_width [reg_num], val);
	  else if (info->display_radix == 10)
	    snprintf (buf, sizeof (buf), "%0*" PRIu64, reg_width [reg_num], val);
	  else if (info->display_radix == 8)
	    snprintf (buf, sizeof (buf), "%0*" PRIo64, reg_width [reg_num], val);
	  else // binary
	    binary_to_string (buf, reg_info [reg_num]->element_bits, val);
	}
      else
	snprintf (buf, sizeof (buf), "err");
      if ((info->display_radix == 2) && (info->element_bits == 1))
	gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (reg_widget [reg_num]), val);
      else
	gtk_entry_set_text (GTK_ENTRY (reg_widget [reg_num]), buf);
    }
}


static int log2tab [17] =
  { 1, 1, 1, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4  };


static bool debug_window_add_register (GtkWidget *table, int reg_num)
{
  int l2radix;
  GtkWidget *hbox;
  int i;
  reg_info_t *r;

  r = sim_get_register_info (sim,
			     0,  // $$$ CPU only for now
			     reg_num);
  if (! r)
    return false;
  reg_info [reg_num] = r;

  gtk_table_attach_defaults (GTK_TABLE (table),
			     gtk_label_new (r->name),
			     0,
			     1,
			     reg_num,
			     reg_num + 1);

  l2radix = log2tab [r->display_radix];

  reg_width [reg_num] = (r->element_bits + l2radix - 1) / l2radix;

  hbox = gtk_hbox_new (FALSE, 1);

  for (i = 0; i < r->array_element_count; i++)
    {
      GtkWidget *w;
      if ((r->display_radix == 2) && (r->element_bits == 1))
	w = gtk_check_button_new ();
      else
	w = gtk_entry_new_with_max_length (reg_width [reg_num]);
      if (i == 0)
	reg_widget [reg_num] = w;
      gtk_box_pack_start (GTK_BOX (hbox), w, FALSE, TRUE, 0);
    }

  gtk_table_attach_defaults (GTK_TABLE (table),
			     hbox,
			     1,
			     2,
			     reg_num,
			     reg_num + 1);
  return true;
}


gboolean on_destroy_reg_window_event (GtkWidget *widget, GdkEventAny *event)
{
  reg_visible = false;
  reg_window = NULL;
  return (FALSE);
}


void debug_show_reg (GtkWidget *widget, gpointer data)
{
  GtkWidget *table;
  int reg_num = 0;
  
  if (! reg_window)
    {
      reg_visible = false;
      reg_window = gtk_window_new (GTK_WINDOW_TOPLEVEL);
      gtk_window_set_title (GTK_WINDOW (reg_window), "registers");

      g_signal_connect (G_OBJECT (reg_window),
			"destroy",
			GTK_SIGNAL_FUNC (on_destroy_reg_window_event),
			NULL);

      table = gtk_table_new (1, 2, FALSE);
      gtk_container_add (GTK_CONTAINER (reg_window), table);
      while (debug_window_add_register (table, reg_num))
	reg_num++;
    }

  max_reg = reg_num;

  reg_visible = ! reg_visible;

  if (reg_visible)
    {
      update_register_window ();
      gtk_widget_show_all (reg_window);
    }
  else
    gtk_widget_hide (reg_window);
}


void debug_run (GtkWidget *widget, gpointer data)
{
  sim_start (sim);
}


void debug_step (GtkWidget *widget, gpointer data)
{
  sim_single_inst (sim);
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
    { "/File/_Quit",    "<CTRL>Q",    quit_callback, 0, "<StockItem>", GTK_STOCK_QUIT },
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


void set_default_state_path (void)
{
  const char *p;
  model_info_t *model_info;

  model_info = get_model_info (sim_get_model (sim));

  p = g_get_home_dir ();
  printf ("home directory is '%s'\n", p);
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

  printf ("default state path '%s'\n", state_fn);
}


int main (int argc, char *argv[])
{
  char *kml_name = NULL;
  char *kml_fn, *image_fn, *rom_fn, *listing_fn;

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

  if (! kml_name)
    kml_name = progname;

  kml_fn = find_file_in_path_list (kml_name, ".kml", default_path);
  if (! kml_fn)
    fatal (2, "can't find KML file '%s'\n", kml_fn);

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

  sim = sim_init (model,
		  model_info->clock_frequency,
		  model_info->ram_size,
		  kml->character_segment_map);

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

  add_switches (background_pixbuf, fixed);

  add_keys (background_pixbuf, fixed);

  // Have to show everything here, or display_init() can't construct the
  // GCs for the annunciators.
  gtk_widget_show_all (main_window);

  display_init (kml, main_window, event_box, fixed, file_pixbuf);

  if (image_mask_bitmap)
    {
      gtk_widget_shape_combine_mask (main_window,
				     image_mask_bitmap,
				     0,
				     0);

      gtk_window_set_decorated (GTK_WINDOW (main_window), FALSE);
    }

  // Have to show everything again, now that we've done display_init()
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

  init_switches ();

  set_default_state_path ();

  if ((*state_fn) && file_exists (state_fn))
    {
      printf ("loading '%s'\n", state_fn);
      state_read_xml (sim, state_fn);
      printf ("loaded\n");
    }

  if (run)
    sim_start (sim);

  gtk_main ();

  exit (0);
}
