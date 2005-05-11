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


#define QMAKESTR(x) #x
#define MAKESTR(x) QMAKESTR(x)


// The OFFSET_OF macro is used to return the offset of a field within
// a structure.
#define OFFSET_OF(type, field) ((int)&( ((type *)0)->field) )


extern char *progname;  /* must be set by main program */

extern char *nonpareil_release;   /* defined in release.c */

void usage (FILE *f);    /* must be implemented in main program */

// generate warning message to stderr
void warning (char *format, ...);

// generate fatal error message to stderr, doesn't return
void fatal (int ret, char *format, ...) __attribute__ ((noreturn));

void *alloc (size_t size);

char *newstr (char *orig);

char *newstrn (char *orig, int max_len);

// max_strncat() is similar to strncat(), except that the size parameter
// is the maximum total length of the destination, not the maximum number
// of characters to concatenate.
char *max_strncat (char *dest, const char *src, size_t n);

void trim_trailing_whitespace (char *s);


bool file_exists (char *fn);

bool dir_exists (char *fn);

bool create_dir (char *fn);


// Given a base filename, an optional suffix, and a colon-delimited
// list of directory paths, try to find a file.  Returns a newly allocated
// string with the filename if found, or NULL otherwise.
char *find_file_in_path_list (char *name, char *opt_suffix, char *path_list);
