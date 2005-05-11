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

#include <stdarg.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// POSIX for fstat:
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

#include "util.h"


char *progname;


// generate warning message to stderr
void warning (char *format, ...)
{
  va_list ap;

  fprintf (stderr, "warning: ");
  va_start (ap, format);
  vfprintf (stderr, format, ap);
  va_end (ap);
}


// generate fatal error message to stderr, doesn't return
void fatal (int ret, char *format, ...)
{
  va_list ap;

  if (format)
    {
      fprintf (stderr, "fatal error: ");
      va_start (ap, format);
      vfprintf (stderr, format, ap);
      va_end (ap);
    }
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


char *max_strncat (char *dest, const char *src, size_t n)
{
  size_t len1 = strlen (dest);

  if (len1 < (n - 1))
    strncpy (dest + len1, src, (n - 1) - len1);
  return dest;
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


#ifndef PATH_MAX
#define PATH_MAX 256
#endif


bool file_exists (char *fn)
{
  struct stat stat_buf;
  return (stat (fn, & stat_buf) == 0) && S_ISREG (stat_buf.st_mode);
}


bool dir_exists (char *fn)
{
  struct stat stat_buf;
  return (stat (fn, & stat_buf) == 0) && S_ISDIR (stat_buf.st_mode);
}


#define DEF_DIR_MODE (S_IRUSR|S_IWUSR|S_IXUSR|S_IRGRP|S_IXGRP|S_IROTH|S_IXOTH)


bool create_dir (char *fn)
{
  return mkdir (fn, DEF_DIR_MODE) == 0;
}


// Given a base filename, an optional suffix, and a colon-delimited
// list of directory paths, try to find a file.
char *find_file_in_path_list (char *name, char *opt_suffix, char *path_list)
{
  char buf [PATH_MAX];

  // First look in the current directory, even if it's not in the path.
  strncpy (buf, name, sizeof (buf));
  if (file_exists (buf))
    goto found;
  if (opt_suffix)
    {
      max_strncat (buf, opt_suffix, sizeof (buf));
      if (file_exists (buf))
	goto found;
    }

  while (path_list && *path_list)
    {
      char *p = strchr (path_list, ':');
      size_t n = p ? (p - path_list) : strlen (path_list);
      strncpy (buf, path_list, n);
      max_strncat (buf, "/", sizeof (buf));
      max_strncat (buf, name, sizeof (buf));
      if (file_exists (buf))
	goto found;
      if (opt_suffix)
	{
	  max_strncat (buf, opt_suffix, sizeof (buf));
	  if (file_exists (buf))
	    goto found;
	}
      if (p)
	path_list = p + 1;
      else
	path_list = NULL;
    }

  return NULL;

 found:
  return (newstr (buf));
}
