/*
Copyright 2008, 2010, 2022 Eric Smith <spacewar@gmail.com>

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
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <gdk/gdk.h>
#include <gtk/gtk.h>

#include <gsf/gsf-infile.h>

#include <libxml/xmlwriter.h>
#include <libxml/SAX.h>

#include "util.h"
#include "xmlutil.h"
#include "display.h"
#include "keyboard.h"
#include "kml.h"
#include "chip.h"
#include "calcdef.h"
#include "proc.h"
#include "crc.h"


typedef struct
{
  sim_t *sim;
  chip_t *chip;

  uint32_t config_flags;

  crc_card_side_t *side;  // active card side, NULL if none inserted
  char *fn;               // filename of card file

  GtkWidget *window;
  GtkWidget *insert_button;
  GtkWidget *insert_new_button;

  // used by SAX parser when reading card file:
  uint32_t word_count;
  uint32_t index;
} gui_card_reader_t;


static xmlSAXHandler cr_sax_handler;


static void gui_card_reader_set_button_state (gui_card_reader_t *cr,
					      bool state)
{
  gtk_widget_set_sensitive (cr->insert_button, state);
  gtk_widget_set_sensitive (cr->insert_new_button, state);
}


static void write_card (char *fn, crc_card_side_t *side)
{
  xmlTextWriterPtr writer;
  int i;

  writer = xml_write_document (fn,
			       "magcard",
			       "http://nonpareil.brouhaha.com/dtd/magcard-1.0.dtd",
			       9);  // max compression

  xml_start_element (writer, "magcard");
  xml_write_attribute_string (writer, "version",    "1.0");
  xml_write_attribute_format (writer, "word-size",  "%d", CRC_WORD_SIZE);
  xml_write_attribute_format (writer, "word-count", "%d", CRC_MAX_WORD);
  xml_write_attribute_format (writer, "write-protect", "%d", side->write_protect);

  for (i = 0; i < CRC_MAX_WORD; i++)
    {
      xml_start_element (writer, "word");
      xml_write_string_format (writer, "%" PRIx32, side->word [i]);
      xml_end_element (writer);  // word
    }

  xml_end_element (writer);  // magcard

  if (xmlTextWriterEndDocument (writer) < 0)
    fatal (2, "can't end document\n");

  xmlFreeTextWriter (writer);
}


void gui_card_reader_update (sim_t  *sim  UNUSED,
			     chip_t *chip UNUSED,
			     void   *ref,
			     void   *data)
{
  gui_card_reader_t *cr = ref;

  if (data != cr->side)
    fatal (3, "card reader returned different card side!\n");

  if (cr->side->dirty)
    {
      cr->side->dirty = false;  // shouldn't be set in file
      write_card (cr->fn, cr->side);
      g_free (cr->fn);
    }

  free (cr->side);
  cr->side = NULL;
  cr->fn = NULL;

  gui_card_reader_set_button_state (cr, true);
}


static void parse_word_data (void *ref,
			     const xmlChar *ch,
			     int len)
{
  gui_card_reader_t *cr = ref;
  uint32_t v = 0;

  while (len--)
    {
      if (isspace (*ch))
	continue;
      v <<= 4;
      if ((*ch >= '0') && (*ch <= '9'))
	v = v + (*ch - '0');
      else if ((*ch >= 'A') && (*ch <= 'F'))
	v = v + 10 + (*ch - 'A');
      else if ((*ch >= 'a') && (*ch <= 'f'))
	v = v + 10 + (*ch - 'a');
      else
	fatal (3, "invalid hex digit in magcard word\n");
      ch++;
    }
  if (cr->index >= cr->word_count)
    fatal (3, "too much data on card\n");
  cr->side->word [cr->index++] = v;
}


static void parse_word (gui_card_reader_t *cr UNUSED,
			char **attrs)
{
  int i;

  for (i = 0; attrs && attrs [i]; i += 2)
    {
      warning ("unknown attribute '%s' in 'magcard' element\n", attrs [i]);
    }
  cr_sax_handler.characters = parse_word_data;
}


static void parse_magcard (gui_card_reader_t *cr,
			   char **attrs)
{
  int i;
  bool got_version = false;
  bool got_word_size = false;
  bool got_word_count = false;

  for (i = 0; attrs && attrs [i]; i += 2)
    {
      if (strcmp (attrs [i], "version") == 0)
	{
	  if (strcmp (attrs [i + 1], "1.0") != 0)
	    warning ("Unrecognized version '%s' of Nonpareil magcard format\n",
		     attrs [i + 1]);
	  got_version = true;
	}
      else if (strcmp (attrs [i], "word-size") == 0)
	{
	  uint32_t word_size = str_to_uint32 (attrs [i + 1], NULL, 0);
	  if (word_size != CRC_WORD_SIZE)
	    fatal (3, "incorrect magcard word size\n");
	  got_word_size = true;
	}
      else if (strcmp (attrs [i], "word-count") == 0)
	{
	  cr-> word_count = str_to_uint32 (attrs [i + 1], NULL, 0);
	  if (cr->word_count != CRC_MAX_WORD)
	    fatal (3, "incorrect magcard word count\n");
	  got_word_count = true;
	}
      else if (strcmp (attrs [i], "write-protect") == 0)
	{
	  cr->side->write_protect = str_to_bool (attrs [i + 1], NULL);
	}
      else
	warning ("unknown attribute '%s' in 'magcard' element\n", attrs [i]);
    }
  if (! got_version)
    warning ("magcard file doesn't have version\n");
  if (! got_word_size)
    fatal (3, "magcard file doesn't have word-size\n");
  if (! got_word_count)
    fatal (3, "magcard file doesn't have word-count\n");
  cr->index = 0;
}


static void cr_sax_start_element (void *ref,
				  const xmlChar *name,
				  const xmlChar **attrs)
{
  gui_card_reader_t *cr = ref;

  if (xml_strcmp (name, "magcard") == 0)
    parse_magcard (cr, (char **) attrs);
  else if (xml_strcmp (name, "word") == 0)
    parse_word (cr, (char **) attrs);
  else
    warning ("unknown element '%s'\n", name);
}


static void cr_sax_end_element (void *ref UNUSED,
				const xmlChar *name UNUSED)
{
  cr_sax_handler.characters = NULL;
}


static xmlSAXHandler cr_sax_handler =
{
  .getEntity     = sax_get_entity,
  .startElement  = cr_sax_start_element,
  .endElement    = cr_sax_end_element,
  .warning       = sax_warning,
  .error         = sax_error,
  .fatalError    = sax_fatal_error,
};


static void insert_card (gui_card_reader_t *cr,
			 char *fn,
			 bool new_card)
{
  if (cr->side)
    fatal (3, "card inserted while card reader busy\n");

  cr->fn = fn;

  cr->side = alloc (sizeof (crc_card_side_t));

  if (! new_card)
    {
      xmlSAXUserParseFile (& cr_sax_handler,
			   cr,
			   fn);
      cr->side->dirty = false;  // shouldn't be set in file
    }

  sim_event (cr->sim,
	     cr->chip,
	     event_crc_card_inserted,
	     0,  // arg1
	     0,  // arg2,
	     cr->side);
}


static void gui_card_reader_insert_card (GtkWidget *widget UNUSED,
					 gpointer data)
{
  gui_card_reader_t *cr = data;
  char *fn;
  GtkWidget *dialog;

  dialog = gtk_file_chooser_dialog_new ("Insert card side file",
					GTK_WINDOW (cr->window),
					GTK_FILE_CHOOSER_ACTION_OPEN,
					GTK_STOCK_CANCEL,
					GTK_RESPONSE_CANCEL,
					GTK_STOCK_OPEN,
					GTK_RESPONSE_ACCEPT,
					NULL);

  if (gtk_dialog_run (GTK_DIALOG (dialog)) != GTK_RESPONSE_ACCEPT)
    {
      gtk_widget_destroy (dialog);
      return;
    }

  fn = gtk_file_chooser_get_filename (GTK_FILE_CHOOSER (dialog));
  gtk_widget_destroy (dialog);

  gui_card_reader_set_button_state (cr, false);
  insert_card (cr, fn, false);
}

static void gui_card_reader_insert_new_card (GtkWidget *widget UNUSED,
					     gpointer data)
{
  gui_card_reader_t *cr = data;
  char *fn;
  GtkWidget *dialog;

  dialog = gtk_file_chooser_dialog_new ("Create new card side file",
					GTK_WINDOW (cr->window),
					GTK_FILE_CHOOSER_ACTION_SAVE,
					GTK_STOCK_CANCEL,
					GTK_RESPONSE_CANCEL,
					GTK_STOCK_SAVE,
					GTK_RESPONSE_ACCEPT,
					NULL);

  if (gtk_dialog_run (GTK_DIALOG (dialog)) != GTK_RESPONSE_ACCEPT)
    {
      gtk_widget_destroy (dialog);
      return;
    }

  fn = gtk_file_chooser_get_filename (GTK_FILE_CHOOSER (dialog));
  gtk_widget_destroy (dialog);

  gui_card_reader_set_button_state (cr, false);
  insert_card (cr, fn, true);
}


chip_t *gui_card_reader_install (sim_t           *sim,
				 plugin_module_t *module,
				 chip_type_t     type,
				 int32_t         index,
				 int32_t         flags)
{
  gui_card_reader_t *cr;
  GtkWidget *box;

  cr = alloc (sizeof (gui_card_reader_t));

  cr->sim = sim;
  cr->config_flags = flags;

  cr->chip = sim_add_chip (sim,
			   module,
			   type,                    // chip_type
			   index,                   // index
			   flags,                   // flags
			   gui_card_reader_update,  // callback_fn
			   cr);                     // ref
  if (! cr->chip)
    {
      warning ("can't add %s chip\n", get_chip_type_info (type));
      return NULL;
    }

  cr->window = gtk_window_new (GTK_WINDOW_TOPLEVEL);
  gtk_window_set_deletable (GTK_WINDOW (cr->window), FALSE);
  gtk_window_set_resizable (GTK_WINDOW (cr->window), FALSE);

  box = gtk_hbox_new (FALSE, 0);

  cr->insert_button = gtk_button_new_with_label ("Insert card...");
  g_signal_connect (G_OBJECT (cr->insert_button),
		    "clicked",
		    G_CALLBACK (gui_card_reader_insert_card),
		    cr);
  gtk_box_pack_start (GTK_BOX (box), cr->insert_button, FALSE, FALSE, 0);

  cr->insert_new_button = gtk_button_new_with_label ("Insert new card");
  g_signal_connect (G_OBJECT (cr->insert_new_button),
		    "clicked",
		    G_CALLBACK (gui_card_reader_insert_new_card),
		    cr);
  gtk_box_pack_start (GTK_BOX (box), cr->insert_new_button, FALSE, FALSE, 0);
  gtk_container_add (GTK_CONTAINER (cr->window), box);

  gtk_window_set_title (GTK_WINDOW (cr->window), "Card Reader");
  gtk_widget_show_all (cr->window);

  return (cr->chip);
}
