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

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "util.h"


char *progname;


/* generate fatal error message to stderr, doesn't return */

void fatal (int ret, char *format, ...)
{
  va_list ap;

  fprintf (stderr, "fatal error: ");
  va_start (ap, format);
  vfprintf (stderr, format, ap);
  va_end (ap);
  if (ret == 1)
    usage (stderr);
  exit (ret);
}


void *alloc (size_t size)
{
  void *p;

  p = calloc (1, size);
  if (! p)
    fatal (2, "Memory allocation failed\n");
  return (p);
}


char *newstr (char *orig)
{
  int len;
  char *r;

  len = strlen (orig);
  r = (char *) alloc (len + 1);
  memcpy (r, orig, len + 1);
  return (r);
}


char *newstrn (char *orig, int max_len)
{
  int len;
  char *r;

  len = strlen (orig);
  if (len > max_len)
    len = max_len;
  r = (char *) alloc (len + 1);
  memcpy (r, orig, len);
  return (r);
}


void trim_trailing_whitespace (char *s)
{
  int i;
  char c;

  i = strlen (s);
  while (--i >= 0)
    {
      c = s [i];
      if ((c == '\n') || (c == '\r') || (c == ' ') || (c == '\t'))
	s [i] = '\0';
      else
	break;
    }
}