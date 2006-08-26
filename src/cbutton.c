/*
$Id$
Copyright 2006 Eric L. Smith <eric@brouhaha.com>
Based on GTK+ 2.8.20 gtk/gtkbutton.c

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

#include <stdint.h>
#include <string.h>

#include <gtk/gtk.h>
#include <gtk/gtkmarshal.h>
#include <gdk/gdk.h>
#include <gdk-pixbuf/gdk-pixbuf.h>

#include "cbutton.h"
#include "pixbuf_util.h"

enum {
  PRESSED,
  RELEASED,
  CLICKED,
  ENTER,
  LEAVE,
  LAST_SIGNAL
};


static void cbutton_class_init         (CbuttonClass          *klass);
static void cbutton_init               (Cbutton               *cbutton);
static void cbutton_destroy            (GtkObject             *object);
static void cbutton_realize            (GtkWidget             *widget);
static void cbutton_unrealize          (GtkWidget             *widget);
static void cbutton_map                (GtkWidget             *widget);
static void cbutton_unmap              (GtkWidget             *widget);
static void cbutton_size_request       (GtkWidget             *widget,
					GtkRequisition        *requisition);
static void cbutton_size_allocate      (GtkWidget             *widget,
					GtkAllocation         *allocation);
static gint cbutton_expose             (GtkWidget             *widget,
					GdkEventExpose        *event);
static gboolean cbutton_button_press   (GtkWidget             *widget,
					GdkEventButton        *event);
static gboolean cbutton_button_release (GtkWidget             *widget,
				        GdkEventButton        *event);
static gint cbutton_grab_broken        (GtkWidget             *widget,
					GdkEventGrabBroken    *event);
static gint cbutton_enter_notify       (GtkWidget             *widget,
				        GdkEventCrossing      *event);
static gint cbutton_leave_notify       (GtkWidget             *widget,
				        GdkEventCrossing      *event);
static void real_cbutton_pressed       (Cbutton *cbutton);
static void real_cbutton_released      (Cbutton *cbutton);
static void cbutton_update_state       (Cbutton               *cbutton);

static GObject*	cbutton_constructor    (GType                  type,
				        guint                  n_construct_properties,
				        GObjectConstructParam *construct_params);
static void cbutton_state_changed      (GtkWidget             *widget,
				        GtkStateType           previous_state);



static GtkWidgetClass *parent_class = NULL;
static guint cbutton_signals[LAST_SIGNAL] = { 0 };


GType
cbutton_get_type (void)
{
  static GType cbutton_type = 0;

  if (!cbutton_type)
    {
      static const GTypeInfo cbutton_info =
      {
	sizeof (CbuttonClass),
	NULL,		/* base_init */
	NULL,		/* base_finalize */
	(GClassInitFunc) cbutton_class_init,
	NULL,		/* class_finalize */
	NULL,		/* class_data */
	sizeof (Cbutton),
	16,		/* n_preallocs */
	(GInstanceInitFunc) cbutton_init,
      };

      cbutton_type = g_type_register_static (GTK_TYPE_WIDGET, "Cbutton",
					    &cbutton_info, 0);
    }

  return cbutton_type;
}

static void
cbutton_class_init (CbuttonClass *klass)
{
  GObjectClass *gobject_class;
  GtkObjectClass *object_class;
  GtkWidgetClass *widget_class;

  gobject_class = G_OBJECT_CLASS (klass);
  object_class = (GtkObjectClass*) klass;
  widget_class = (GtkWidgetClass*) klass;
  
  parent_class = g_type_class_peek_parent (klass);

  gobject_class->constructor = cbutton_constructor;

  object_class->destroy = cbutton_destroy;

  widget_class->realize = cbutton_realize;
  widget_class->unrealize = cbutton_unrealize;
  widget_class->map = cbutton_map;
  widget_class->unmap = cbutton_unmap;
  widget_class->size_request = cbutton_size_request;
  widget_class->size_allocate = cbutton_size_allocate;
  widget_class->expose_event = cbutton_expose;
  widget_class->button_press_event = cbutton_button_press;
  widget_class->button_release_event = cbutton_button_release;
  widget_class->grab_broken_event = cbutton_grab_broken;
  widget_class->enter_notify_event = cbutton_enter_notify;
  widget_class->leave_notify_event = cbutton_leave_notify;
  widget_class->state_changed = cbutton_state_changed;

  klass->pressed = real_cbutton_pressed;
  klass->released = real_cbutton_released;
  klass->clicked = NULL;
  klass->enter = cbutton_update_state;
  klass->leave = cbutton_update_state;
  
  /**
   * Cbutton::pressed:
   * @cbutton: the object that received the signal
   *
   * Emitted when the button is pressed.
   * 
   * @Deprecated: Use the GtkWidget::button-press-event signal.
   */ 
  cbutton_signals[PRESSED] =
    g_signal_new ("pressed",
		  G_OBJECT_CLASS_TYPE (object_class),
		  G_SIGNAL_RUN_FIRST,
		  G_STRUCT_OFFSET (CbuttonClass, pressed),
		  NULL, NULL,
		  gtk_marshal_VOID__VOID,
		  G_TYPE_NONE, 0);

  /**
   * GtkButton::released:
   * @button: the object that received the signal
   *
   * Emitted when the button is released.
   * 
   * @Deprecated: Use the GtkWidget::button-release-event signal.
   */ 
  cbutton_signals[RELEASED] =
    g_signal_new ("released",
		  G_OBJECT_CLASS_TYPE (object_class),
		  G_SIGNAL_RUN_FIRST,
		  G_STRUCT_OFFSET (CbuttonClass, released),
		  NULL, NULL,
		  gtk_marshal_VOID__VOID,
		  G_TYPE_NONE, 0);

  /**
   * Cbutton::clicked:
   * @cbutton: the object that received the signal
   *
   * Emitted when the cbutton has been activated (pressed and released).
   */ 
  cbutton_signals[CLICKED] =
    g_signal_new ("clicked",
		  G_OBJECT_CLASS_TYPE (object_class),
		  G_SIGNAL_RUN_FIRST | G_SIGNAL_ACTION,
		  G_STRUCT_OFFSET (CbuttonClass, clicked),
		  NULL, NULL,
		  gtk_marshal_VOID__VOID,
		  G_TYPE_NONE, 0);

  /**
   * Cbutton::enter:
   * @cbutton: the object that received the signal
   *
   * Emitted when the pointer enters the button.
   * 
   * @Deprecated: Use the GtkWidget::enter-notify-event signal.
   */ 
  cbutton_signals[ENTER] =
    g_signal_new ("enter",
		  G_OBJECT_CLASS_TYPE (object_class),
		  G_SIGNAL_RUN_FIRST,
		  G_STRUCT_OFFSET (CbuttonClass, enter),
		  NULL, NULL,
		  gtk_marshal_VOID__VOID,
		  G_TYPE_NONE, 0);

  /**
   * Cbutton::leave:
   * @cbutton: the object that received the signal
   *
   * Emitted when the pointer leaves the button.
   * 
   * @Deprecated: Use the GtkWidget::leave-notify-event signal.
   */ 
  cbutton_signals[LEAVE] =
    g_signal_new ("leave",
		  G_OBJECT_CLASS_TYPE (object_class),
		  G_SIGNAL_RUN_FIRST,
		  G_STRUCT_OFFSET (CbuttonClass, leave),
		  NULL, NULL,
		  gtk_marshal_VOID__VOID,
		  G_TYPE_NONE, 0);
}

static void
cbutton_init (Cbutton *cbutton)
{
  GTK_WIDGET_SET_FLAGS (cbutton, GTK_RECEIVES_DEFAULT);

  cbutton->constructed = FALSE;
  cbutton->in_button = FALSE;
  cbutton->button_down = FALSE;
  cbutton->depressed = FALSE;
}

static void
cbutton_destroy (GtkObject *object)
{
  //Cbutton *cbutton = CBUTTON (object);
  
  // $$$ deal with images here?
  
  (* GTK_OBJECT_CLASS (parent_class)->destroy) (object);
}

static GObject*
cbutton_constructor (GType                  type,
		     guint                  n_construct_properties,
		     GObjectConstructParam *construct_params)
{
  GObject *object;
  Cbutton *cbutton;

  object = (* G_OBJECT_CLASS (parent_class)->constructor) (type,
							   n_construct_properties,
							   construct_params);

  cbutton = CBUTTON (object);
  cbutton->constructed = TRUE;

  return object;
}


GtkWidget*
cbutton_new (void)
{
  return g_object_new (TYPE_CBUTTON, NULL);
}

void
cbutton_pressed (Cbutton *cbutton)
{
  g_return_if_fail (IS_CBUTTON (cbutton));
  
  g_signal_emit (cbutton, cbutton_signals[PRESSED], 0);
}

void
cbutton_released (Cbutton *cbutton)
{
  g_return_if_fail (IS_CBUTTON (cbutton));

  g_signal_emit (cbutton, cbutton_signals[RELEASED], 0);
}

void
cbutton_clicked (Cbutton *cbutton)
{
  g_return_if_fail (IS_CBUTTON (cbutton));

  g_signal_emit (cbutton, cbutton_signals[CLICKED], 0);
}

void
cbutton_enter (Cbutton *cbutton)
{
  g_return_if_fail (IS_CBUTTON (cbutton));

  g_signal_emit (cbutton, cbutton_signals[ENTER], 0);
}

void
cbutton_leave (Cbutton *cbutton)
{
  g_return_if_fail (IS_CBUTTON (cbutton));

  g_signal_emit (cbutton, cbutton_signals[LEAVE], 0);
}

static void
cbutton_realize (GtkWidget *widget)
{
  Cbutton *cbutton;
  GdkWindowAttr attributes;
  gint attributes_mask;

  cbutton = CBUTTON (widget);
  GTK_WIDGET_SET_FLAGS (widget, GTK_REALIZED);

  attributes.window_type = GDK_WINDOW_CHILD;
  attributes.x = widget->allocation.x;
  attributes.y = widget->allocation.y;
  attributes.width = widget->allocation.width;
  attributes.height = widget->allocation.height;
  attributes.wclass = GDK_INPUT_OUTPUT;
  attributes.event_mask = gtk_widget_get_events (widget);
  attributes.event_mask |= (GDK_EXPOSE |
			    GDK_BUTTON_PRESS_MASK |
			    GDK_BUTTON_RELEASE_MASK |
			    GDK_ENTER_NOTIFY_MASK |
			    GDK_LEAVE_NOTIFY_MASK);

  attributes_mask = GDK_WA_X | GDK_WA_Y;

  widget->window = gdk_window_new (gtk_widget_get_parent_window (widget),
				   & attributes,
				   attributes_mask);

  gdk_window_shape_combine_mask (widget->window,
				 cbutton->mask,
				 0,
				 0);

  gdk_window_set_user_data (widget->window, cbutton);

  widget->style = gtk_style_attach (widget->style, widget->window);
}

static void
cbutton_unrealize (GtkWidget *widget)
{
  Cbutton *cbutton;

  g_return_if_fail (IS_CBUTTON (widget));
  cbutton = CBUTTON (widget);

  gdk_window_destroy (widget->window);
  widget->window = NULL;

  if (GTK_WIDGET_CLASS (parent_class)->unrealize)
    (* GTK_WIDGET_CLASS (parent_class)->unrealize) (widget);
}

static void
cbutton_map (GtkWidget *widget)
{
  Cbutton *cbutton = CBUTTON (widget);
  
  GTK_WIDGET_CLASS (parent_class)->map (widget);

  if (widget->window)
    gdk_window_show (widget->window);
}

static void
cbutton_unmap (GtkWidget *widget)
{
  Cbutton *cbutton = CBUTTON (widget);
    
  if (widget->window)
    gdk_window_hide (widget->window);

  GTK_WIDGET_CLASS (parent_class)->unmap (widget);
}

static void
cbutton_size_request (GtkWidget      *widget,
		      GtkRequisition *requisition)
{
  Cbutton *cbutton = CBUTTON (widget);

  requisition->width = cbutton->width;
  requisition->height = cbutton->height;
}

static void
cbutton_size_allocate (GtkWidget     *widget,
		       GtkAllocation *allocation)
{
  //Cbutton *cbutton = CBUTTON (widget);

  widget->allocation = *allocation;

  if (GTK_WIDGET_REALIZED (widget))
    gdk_window_move_resize (widget->window,
			    widget->allocation.x,
			    widget->allocation.y,
			    widget->allocation.width,
			    widget->allocation.height);
}

void
_cbutton_paint (Cbutton      *cbutton)
{
  GtkWidget *widget;
   
  if (GTK_WIDGET_DRAWABLE (cbutton))
    {
      widget = GTK_WIDGET (cbutton);
	
      gdk_draw_pixbuf (widget->window,
		       widget->style->fg_gc [0],
		       cbutton->pixbuf [cbutton->shift_state] [widget->state],
		       0,  // src_x
		       0,  // src_y
		       0,
		       0,
		       widget->allocation.width,
		       widget->allocation.height,
		       GDK_RGB_DITHER_NONE,
		       0,  // x_dither
		       0);  // y_dither
    }
}

static gboolean
cbutton_expose (GtkWidget      *widget,
		GdkEventExpose *event)
{
  Cbutton *cbutton = CBUTTON (widget);
  if (GTK_WIDGET_DRAWABLE (widget))
    {
      _cbutton_paint (cbutton);
      if (GTK_WIDGET_CLASS (parent_class)->expose_event)
	(* GTK_WIDGET_CLASS (parent_class)->expose_event) (widget, event);
    }
  
  return FALSE;
}

static gboolean
cbutton_button_press (GtkWidget      *widget,
		      GdkEventButton *event)
{
  if (event->type == GDK_BUTTON_PRESS)
    {
      Cbutton *cbutton = CBUTTON (widget);

      if (event->button == 1)
	cbutton_pressed (cbutton);
    }

  return TRUE;
}

static gboolean
cbutton_button_release (GtkWidget      *widget,
			GdkEventButton *event)
{
  if (event->button == 1)
    {
      Cbutton *cbutton = CBUTTON (widget);
      cbutton_released (cbutton);
    }

  return TRUE;
}

static gboolean
cbutton_grab_broken (GtkWidget          *widget,
			GdkEventGrabBroken *event)
{
  Cbutton *cbutton = CBUTTON (widget);
  gboolean save_in;
  
  /* Simulate a cbutton release without the pointer in the cbutton */
  if (cbutton->button_down)
    {
      save_in = cbutton->in_button;
      cbutton->in_button = FALSE;
      cbutton_released (cbutton);
      if (save_in != cbutton->in_button)
	{
	  cbutton->in_button = save_in;
	  cbutton_update_state (cbutton);
	}
    }

  return TRUE;
}

static gboolean
cbutton_enter_notify (GtkWidget        *widget,
			 GdkEventCrossing *event)
{
  Cbutton *cbutton;
  GtkWidget *event_widget;

  cbutton = CBUTTON (widget);
  event_widget = gtk_get_event_widget ((GdkEvent*) event);

  if ((event_widget == widget) &&
      (event->detail != GDK_NOTIFY_INFERIOR))
    {
      cbutton->in_button = TRUE;
      cbutton_enter (cbutton);
    }

  return FALSE;
}

static gboolean
cbutton_leave_notify (GtkWidget        *widget,
			 GdkEventCrossing *event)
{
  Cbutton *cbutton;
  GtkWidget *event_widget;

  cbutton = CBUTTON (widget);
  event_widget = gtk_get_event_widget ((GdkEvent*) event);

  if ((event_widget == widget) &&
      (event->detail != GDK_NOTIFY_INFERIOR))
    {
      cbutton->in_button = FALSE;
      cbutton_leave (cbutton);
    }

  return FALSE;
}

static void
real_cbutton_pressed (Cbutton *cbutton)
{
  cbutton->button_down = TRUE;
  cbutton_update_state (cbutton);
}

static void
real_cbutton_released (Cbutton *cbutton)
{
  if (cbutton->button_down)
    {
      cbutton->button_down = FALSE;

      if (cbutton->in_button)
	cbutton_clicked (cbutton);

      cbutton_update_state (cbutton);
    }
}

/**
 * _cbutton_set_depressed:
 * @cbutton: a #Cbutton
 * @depressed: %TRUE if the cbutton should be drawn with a recessed shadow.
 * 
 * Sets whether the cbutton is currently drawn as down or not. This is 
 * purely a visual setting, and is meant only for use by derived widgets
 * such as #GtkToggleCbutton.
 **/
void
_cbutton_set_depressed (Cbutton *cbutton,
			   gboolean   depressed)
{
  GtkWidget *widget = GTK_WIDGET (cbutton);

  depressed = depressed != FALSE;

  if (depressed != cbutton->depressed)
    {
      cbutton->depressed = depressed;
      gtk_widget_queue_resize (widget);
    }
}

static void
cbutton_update_state (Cbutton *cbutton)
{
  gboolean depressed;
  GtkStateType new_state;

  depressed = cbutton->in_button && cbutton->button_down;

  if (cbutton->in_button && (!cbutton->button_down || !depressed))
    new_state = GTK_STATE_PRELIGHT;
  else
    new_state = depressed ? GTK_STATE_ACTIVE : GTK_STATE_NORMAL;

  _cbutton_set_depressed (cbutton, depressed); 
  gtk_widget_set_state (GTK_WIDGET (cbutton), new_state);
}

static void
cbutton_state_changed (GtkWidget    *widget,
		       GtkStateType  previous_state)
{
  Cbutton *cbutton = CBUTTON (widget);

  //printf ("state changed, prev = %d, new = %d\n", previous_state, widget->state);

  _cbutton_paint (cbutton);

  if (!GTK_WIDGET_IS_SENSITIVE (widget))
    {
      cbutton->in_button = FALSE;
      real_cbutton_released (cbutton);
    }
}


/**
 * cbutton_set_pixbuf:
 * @cbutton: a #Cbutton
 * @pixbuf: a pixbuf to set as the pixbuf for the cbutton
 *
 * Set the pixbuf of @cbutton to the given pixbuf.
 */ 
void
cbutton_set_pixbuf (Cbutton   *cbutton,
		    int        shift_state,
		    GdkPixbuf *pixbuf)
{
  double prelight_intensity_factor = 1.2;
  double active_intensity_factor = 0.5;

  g_return_if_fail (IS_CBUTTON (cbutton));
  g_return_if_fail (GDK_IS_PIXBUF (pixbuf));

#if 0
  if (cbutton->pixbuf [shift_state] [GTK_STATE_NORMAL])
    {
      // $$$ deref the old one
    }
#endif

  if (shift_state == 0)
    {
      cbutton->width = gdk_pixbuf_get_width (pixbuf);
      cbutton->height = gdk_pixbuf_get_height (pixbuf);

      cbutton->mask = (GdkBitmap *) gdk_pixmap_new (NULL,
						    cbutton->width,
						    cbutton->height,
						    1);

      gdk_pixbuf_render_threshold_alpha (pixbuf,
					 cbutton->mask,
					 0,  // src_x
					 0,  // src_y
					 0,  // dest_x
					 0,  // dest_y
					 cbutton->width,
					 cbutton->height,
					 128);  // threshold
    }

  cbutton->pixbuf [shift_state] [GTK_STATE_NORMAL] = pixbuf;

  cbutton->pixbuf [shift_state] [GTK_STATE_PRELIGHT] = gdk_pixbuf_copy (pixbuf);

  pixbuf_map_all_pixels (cbutton->pixbuf [shift_state] [GTK_STATE_PRELIGHT],
			 pixbuf_map_intensify,
			 & prelight_intensity_factor);

  cbutton->pixbuf [shift_state] [GTK_STATE_ACTIVE] =  gdk_pixbuf_copy (pixbuf);

  pixbuf_map_all_pixels (cbutton->pixbuf [shift_state] [GTK_STATE_ACTIVE],
			 pixbuf_map_intensify,
			 & active_intensity_factor);

  //g_object_notify (G_OBJECT (cbutton), "pixbuf");
}

void           cbutton_set_shift_state   (Cbutton      *cbutton,
					  int           shift_state)
{
  if (shift_state == cbutton->shift_state)
    return;

  cbutton->shift_state = shift_state;
  _cbutton_paint (cbutton);
}

int            cbutton_get_shift_state   (Cbutton      *cbutton)
{
  return cbutton->shift_state;
}

#define __CBUTTON_C__
