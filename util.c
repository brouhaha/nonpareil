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

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "util.h"


/* generate fatal error message to stderr, doesn't return */

void fatal (int ret, char *format, ...)
{
  va_list ap;

  fprintf (stderr, "fatal error: ");
  va_start (ap, format);
  vfprintf (stderr, format, ap);
  va_end (ap);
  if (ret == 1)
    fprintf (stderr, "usage: %s objectfile\n", progname);
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
