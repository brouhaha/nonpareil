/*
$Id$
Copyright 2005 Eric L. Smith <eric@brouhaha.com>

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


#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include "util.h"


void usage (FILE *f)
{
  fprintf (f, "%s:  Microcode-level calculator simulator\n",
	   nonpareil_release);
  fprintf (f, "Copyright 2005 Eric L. Smith\n");
  fprintf (f, "http://nonpareil.brouhaha.com/\n");
  fprintf (f, "\n");
  fprintf (f, "usage: %s binfile arrayname >cfile\n", progname);
}


#define LINE_MAX_BYTES 8

int main (int argc, char *argv[])
{
  FILE *f;
  bool need_comma = false;
  int line_pos = 0;

  progname = newstr (argv [0]);

  if (argc != 3)
    fatal (1, NULL);

  f = fopen (argv [1], "rb");
  if (! f)
    fatal (2, "Can't open input file\n");

  printf ("const unsigned char %s [] =\n", argv [2]);
  printf ("{\n");

  while (true)
    {
      int b = fgetc (f);
      if (b == EOF)
	{
	  if (ferror (f))
	    fatal (3, "Error reading input file\n");
	  break;
	}
      if (need_comma)
	printf (",");
      if (line_pos == LINE_MAX_BYTES)
	{
	  printf ("\n");
	  line_pos = 0;
	}
      if (line_pos == 0)
	printf ("  ");
      printf ("0x%02x", b & 0xff);
      line_pos++;
      need_comma = true;
    }

  printf ("\n};\n");
  exit (0);
}
