/*
$Id: proc.c 442 2005-02-12 01:35:58Z eric $
Copyright 2005 Eric L. Smith <eric@brouhaha.com>

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

#include <glib.h>

#include "glib_async_queue_source.h"


struct GAsyncQueueSource
{
  GSource      source;
  GAsyncQueue  *msg_q;
  GAsyncQueue  *free_q;
  GMainContext *context;
};


static gboolean g_async_queue_source_prepare (GSource *source, gint *timeout)
{
  GAsyncQueueSource *s = (GAsyncQueueSource *) source;

  *timeout = -1;
  return (g_async_queue_length (s->msg_q) > 0);
}


static gboolean g_async_queue_source_check (GSource *source)
{
  GAsyncQueueSource *s = (GAsyncQueueSource *) source;

  return (g_async_queue_length (s->msg_q) > 0);
}


static gboolean g_async_queue_source_dispatch (GSource *source,
					       GSourceFunc callback,
					       gpointer user_data)
{
  GAsyncQueueSource *s = (GAsyncQueueSource *) source;
  gpointer msg = g_async_queue_pop (s->msg_q);
  gboolean result;

  result = callback (msg);

  // put message back on free list
  if (s->free_q)
    g_async_queue_push (s->free_q, msg);

  return (result);
}


static GSourceFuncs g_async_queue_source_fns =
{
  g_async_queue_source_prepare,
  g_async_queue_source_check,
  g_async_queue_source_dispatch,
  NULL
};


GAsyncQueueSource *g_async_queue_source_add (GAsyncQueue  *msg_q,
					     GAsyncQueue  *free_q,
					     GMainContext *context,
					     GSourceFunc  callback)
{
  GAsyncQueueSource *s = (GAsyncQueueSource *) g_source_new (& g_async_queue_source_fns,
							     sizeof (GAsyncQueueSource));

  s->msg_q   = msg_q;
  s->free_q  = free_q;
  s->context = context;

  g_source_set_callback (& s->source,
			 callback,
			 NULL,
			 NULL);
  g_source_attach (& s->source, context);

  return (s);
}


void g_async_queue_source_push (GAsyncQueueSource *source, gpointer data)
{
  g_async_queue_push (source->msg_q, data);
  g_main_context_wakeup (source->context);
}

