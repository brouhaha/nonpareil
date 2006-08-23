/*
$Id$
Copyright 2006 Eric L. Smith <eric@brouhaha.com>
Based on GTK+ 2.8.20 gtk/gtkbutton.h

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

/* GTK - The GIMP Toolkit
 * Copyright (C) 1995-1997 Peter Mattis, Spencer Kimball and Josh MacDonald
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

/*
 * Modified by the GTK+ Team and others 1997-2001.  See the AUTHORS
 * file for a list of people on the GTK+ Team.  See the ChangeLog
 * files for a list of changes.  These files are distributed with
 * GTK+ at ftp://ftp.gtk.org/pub/gtk/. 
 */

#ifndef __CBUTTON_H__
#define __CBUTTON_H__


#include <gdk/gdk.h>
#include <gtk/gtkenums.h>


// GTK_STATE_NORMAL, GTK_STATE_PRELIGHT, GTK_STATE_ACTIVE
#define CBUTTON_MAX_BUTTON_STATE 3

// none, f, g, etc.
#define CBUTTON_MAX_SHIFT_STATE 8


G_BEGIN_DECLS

#define TYPE_CBUTTON                 (cbutton_get_type ())
#define CBUTTON(obj)                 (G_TYPE_CHECK_INSTANCE_CAST ((obj), TYPE_CBUTTON, Cbutton))
#define CBUTTON_CLASS(klass)         (G_TYPE_CHECK_CLASS_CAST ((klass), TYPE_CBUTTON, CbuttonClass))
#define IS_CBUTTON(obj)              (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TYPE_CBUTTON))
#define IS_CBUTTON_CLASS(klass)      (G_TYPE_CHECK_CLASS_TYPE ((klass), TYPE_CBUTTON))
#define CBUTTON_GET_CLASS(obj)       (G_TYPE_INSTANCE_GET_CLASS ((obj), TYPE_CBUTTON, CbuttonClass))

typedef struct _Cbutton        Cbutton;
typedef struct _CbuttonClass   CbuttonClass;

struct _Cbutton
{
  GtkWidget widget;

  guint constructed : 1;
  guint in_button : 1;
  guint button_down : 1;
  guint depressed : 1;

  gint         width;
  gint         height;
  int          shift_state;

  GdkBitmap   *mask;
  GdkPixbuf   *pixbuf [CBUTTON_MAX_SHIFT_STATE] [CBUTTON_MAX_BUTTON_STATE];
};

struct _CbuttonClass
{
  GtkWidgetClass        parent_class;

  void (* pressed)  (Cbutton *button);
  void (* released) (Cbutton *button);
  void (* clicked)  (Cbutton *button);
  void (* enter)    (Cbutton *button);
  void (* leave)    (Cbutton *button);
  void (* activate) (GtkButton *button);
};


GType          cbutton_get_type          (void) G_GNUC_CONST;
GtkWidget*     cbutton_new               (void);

void           cbutton_set_pixbuf        (Cbutton      *cbutton,
					  int           shift_state,
					  GdkPixbuf    *pixbuf);

void           cbutton_set_shift_state   (Cbutton      *cbutton,
					  int           shift_state);

G_END_DECLS

#endif /* __CBUTTON_H__ */
