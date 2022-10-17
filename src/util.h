/*
Copyright 1995, 2004, 2005, 2006, 2008, 2022 Eric Smith <spacewar@gmail.h>

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

#ifndef UTIL_H
#define UTIL_H

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

#define UNUSED __attribute__ ((unused))


#define QMAKESTR(x) #x
#define MAKESTR(x) QMAKESTR(x)


#define FIELD_SIZE_OF(type, field) sizeof(((type *)0)->field)


typedef struct
{
  int r;
  int g;
  int b;
} color_t;


extern char *progname;  /* must be set by main program */

extern char *nonpareil_release;   /* defined in release.c */

void usage (FILE *f);    /* must be implemented in main program */

// generate warning message to stderr
void warning (char *format, ...);

// generate fatal error message to stderr, doesn't return
void fatal (int ret, char *format, ...) __attribute__ ((noreturn));

void *alloc (size_t size);

char *newstr (char *orig);

char *newstrcat (char *orig1, char *orig2);

char *newstrcatn (int count, ...);

char *newstrn (char *orig, int max_len);

void realloc_strcpy (char **dest, char *src);


// strlcpy will copy as much of src into dest as it can, up to one less than
// the maximum length of dest specified by the argument l.  Unlike strncpy(),
// strlcpy() will always leave dest NULL-terminated on return.
char *strlcpy (char *dest, const char *src, size_t l);


// strlncpy will copy up to n characters from src to dest, but not more than
// one less than the maximum length of dest specified by the argument l.
// Unlike strncpy(), strlncpy() will always leave dest NULL-terminated on
// return.
char *strlncpy (char *dest, const char *src, size_t l, size_t n);


// max_strncat() is similar to strncat(), except that the size parameter
// is the maximum total length of the destination, not the maximum number
// of characters to concatenate.
// On entry, dest must be NULL-terminated.
char *max_strncat (char *dest, const char *src, size_t n);

void trim_trailing_whitespace (char *s);

void strip_whitespace (char *s);

// copy a string from s to d, expanding tabs
// may truncate if source string is too long
void expand_tabs (char *d,
		  size_t dest_size,
		  char *s,
		  unsigned int tab_width);


// Replacements for strtoul and strtoull:

int32_t  str_to_int32  (const char *nptr, char **endptr, int base);
uint32_t str_to_uint32 (const char *nptr, char **endptr, int base);

uint64_t str_to_uint64 (const char *nptr, char **endptr, int base);

bool str_to_bool (const char *nptr, char **endptr);


// File and directory handling:

bool file_exists (char *fn);

bool dir_exists (char *fn);

bool create_dir (char *fn);


// The normal stdio fread() and fwrite() may transfer less than the number
// of requested bytes even in the absence of EOF and error conditions, thus
// it is necessary to iterate.  These wrapper functions perform the
// iteration, as well as returning the EOF and error status.  Upon return,
// either the complete transfer was successful, or there was an EOF or error
// condition.

size_t fread_bytes  (FILE *stream,
		     void *ptr,
		     size_t byte_count,
		     bool *eof,
		     bool *error);

size_t fwrite_bytes (FILE *stream,
		     void *ptr,
		     size_t byte_count,
		     bool *eof,
		     bool *error);


// Returns the directory portion of the name, or NULL if none is present
char *path_prefix (char *name);

// Concatenates path elements, inserting separators
// NULL elements OK, will not get double separators
char *path_cat_n (int count, ...);

bool filename_suffix_match (char *name, char *suffix);

char *base_filename_with_suffix (char *name, char *suffix);


// Given a base filename, an optional suffix, and a colon-delimited
// list of directory paths, try to find a file.  Returns a newly allocated
// string with the filename if found, or NULL otherwise.
char *find_file_in_path_list (char *name, char *opt_suffix, char *path_list);

char *find_file_with_suffix (char *name, char *suffix, char *default_path);


// Useful for debugging.
void hex_dump (FILE *f, void *p, size_t count);

int buf_printf (char **buf, int *len, const char *fmt, ...);

#endif // UTIL_H
