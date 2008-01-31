/*
$Id$
Copyright 1995, 2004, 2005, 2006 Eric L. Smith <eric@brouhaha.com>

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
#include <stdint.h>
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


char *newstrcat (char *orig1, char *orig2)
{
  int len1, len2;
  char *r;

  len1 = strlen (orig1);
  len2 = strlen (orig2);
  r = (char *) alloc (len1 + len2 + 1);
  memcpy (r, orig1, len1);
  memcpy (r + len1, orig2, len2 + 1);
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


void realloc_strcpy (char **dest, char *src)
{
  int len = strlen (src);

  *dest = realloc (*dest, len + 1);
  if (! *dest)
    fatal (2, "Memory allocation failed\n");
  
  strcpy (*dest, src);
}


// strlcpy will copy as much of src into dest as it can, up to one less than
// the maximum length of dest specified by the argument l.  Unlike strncpy(),
// strlcpy() will always leave dest NULL-terminated on return.
char *strlcpy (char *dest, const char *src, size_t l)
{
  strncpy (dest, src, l);
  dest [l - 1] = '\0';
  return dest;
}


// strlncpy will copy up to n characters from src to dest, but not more than
// one less than the maximum length of dest specified by the argument l.
// Unlike strncpy(), strlncpy() will always leave dest NULL-terminated on
// return.
char *strlncpy (char *dest, const char *src, size_t l, size_t n)
{
  if (n < (l - 1))
    {
      strncpy (dest, src, n);
      dest [n] = '\0';
    }
  else
     strlcpy (dest, src, l);
  return dest;
}


// On entry, dest must be NULL-terminated.
char *max_strncat (char *dest, const char *src, size_t n)
{
  size_t len1 = strlen (dest);

  if (len1 < (n - 1))
    strlcpy (dest + len1, src, (n - 1) - len1);
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


void expand_tabs (char *d,
		  size_t dest_size,
		  char *s,
		  unsigned int tab_width)
{
  size_t di = 0;
  while ((*s) && (di < (dest_size - 1)))  // leave space for trailing null
    {
      char c = *(s++);
      if (c == '\t')
	{
	  int n = tab_width - (di % tab_width);  // spaces needed
	  while (n-- && (di < (dest_size - 1)))
	    d [di++] = ' ';
	}
      else
	d [di++] = c;
    }
  d [di] = '\0';  // add trailing null
}


// The following work on Fedora Core 3, both i386 and x86_64 architectures.
// But to do this right I either need to have a compile-time configuration
// test, or code my own implmentation.
 
uint32_t str_to_uint32 (const char *nptr, char **endptr, int base)
{
  return strtoul (nptr, endptr, base);
}

uint64_t str_to_uint64 (const char *nptr, char **endptr, int base)
{
  return strtoull (nptr, endptr, base);
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
#ifdef MINGW
  return mkdir (fn) == 0;
#else
  return mkdir (fn, DEF_DIR_MODE) == 0;
#endif
}


size_t fread_bytes  (FILE *stream,
		     void *ptr,
		     size_t byte_count,
		     bool *eof,
		     bool *error)
{
  size_t total = 0;

  *eof = false;
  *error = false;

  while (byte_count)
    {
      size_t count;

      count = fread (ptr, 1, byte_count, stream);
      ptr += count;
      total += count;
      byte_count -= count;
      if (byte_count)
	{
	  if (ferror (stream))
	    {
              *error = true;
	      return total;
	    }
	  if (feof (stream))
	    {
              *eof = true;
	      return total;
	    }
	}
    }
  return total;
}


size_t fwrite_bytes (FILE *stream,
		     void *ptr,
		     size_t byte_count,
		     bool *eof,
		     bool *error)
{
  size_t total = 0;

  *eof = false;
  *error = false;

  while (byte_count)
    {
      size_t count;

      count = fwrite (ptr, 1, byte_count, stream);
      ptr += count;
      total += count;
      byte_count -= count;
      if (byte_count)
	{
	  if (ferror (stream))
	    {
              *error = true;
	      return total;
	    }
	  if (feof (stream))
	    {
              *eof = true;
	      return total;
	    }
	}
    }
  return total;
}


bool filename_suffix_match (char *name, char *suffix)
{
  int nl = strlen (name);
  int sl = strlen (suffix);
  if (sl > nl)
    return false;
  return strcmp (name + nl - sl, suffix) == 0;
}


char *base_filename_with_suffix (char *name, char *suffix)
{
  char *p1, *p2;
  unsigned int n, sn;
  char *buf;

  if (suffix)
    sn = strlen (suffix) + 1;
  else
    sn = 0;

  p1 = strrchr (name, '/');  // $$$ not portable
  if (p1)
    p1++;
  else
    p1 = name;
  p2 = strchr (p1, '.');
  if (p2)
    n = p2 - p1;
  else
    n = strlen (p1);

  buf = alloc (n + sn + 1);

  strncpy (buf, p1, n);
  if (suffix)
    {
      buf [n] = '.';
      strcpy (buf + n + 1, suffix);
    }
  else
    buf [n] = '\0';
  return buf;
}


// Given a base filename, an optional suffix, and a colon-delimited
// list of directory paths, try to find a file.
char *find_file_in_path_list (char *name, char *opt_suffix, char *path_list)
{
  char buf [PATH_MAX];

  // First look in the current directory, even if it's not in the path.
  strlcpy (buf, name, sizeof (buf));
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

      strlncpy (buf, path_list, sizeof (buf), n);
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


char *find_file_with_suffix (char *name, char *suffix, char *default_path)
{
  char *fn;
  char *p;

  if (name)
    {
      fn = find_file_in_path_list (name, suffix, default_path);
      if (! fn)
	fatal (2, "can't find %s file '%s'\n", suffix, name);
      return fn;
    }

  // $$$ following is not portable!
  p = strrchr (progname, '/');
  if (p)
    p++;
  else
    p = progname;

  name = newstrcat (p, suffix);
  fn = find_file_in_path_list (name, NULL, default_path);
  return fn;
}


void hex_dump (FILE *f, void *p, size_t count)
{
  uint8_t *q = p;
  unsigned int i, j;

  for (i = 0; i < count; i += 16)
    {
      fprintf (f, "%04x:", i);
      for (j = i; j < (i + 16); j++)
	if (j < count)
	  fprintf (f, " %02x", q [j]);
	else
	  fprintf (f, "   ");
      fprintf (f, "\n");
    }
}


int buf_printf (char **buf, int *len, char *fmt, ...)
{
  int l = 0;
  va_list ap;

  va_start (ap, fmt);
  if ((*len) > 0)
    l = vsnprintf (*buf, *len, fmt, ap);
  va_end (ap);

  (*buf) += l;
  (*len) -= l;

  return l;
}
