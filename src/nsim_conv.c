/*
$Id$
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


#include <inttypes.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "util.h"
#include "nsim_conv.h"


void usage (FILE *f)
{
  fprintf (stderr, "usage:\n");
  fprintf (stderr, "  %s [options] infile [options] outfile\n", progname);
  fprintf (stderr, "\n");
  fprintf (stderr, "options:\n");
  fprintf (stderr, "  -n or --nsim         following file is an NSIM state file\n");
  fprintf (stderr, "  -x or --nonpareil    following file is a Nonpareil state file\n");
  fprintf (stderr, "\n");
  fprintf (stderr, "If no input option is given, the default is NSIM format.\n");
  fprintf (stderr, "If no output option is given, the default is Nonpareil format.\n");
}


regs_t regs;

bool ram_used [MAX_RAM];
uint64_t ram [MAX_RAM];


bool got_in_mode;
bool got_out_mode;
bool in_xml;
bool out_xml;

char *in_fn;
char *out_fn;


void set_mode (bool xml)
{
  if (! in_fn)
    {
      if (got_in_mode)
	fatal (1, "Only one input file type may be specified.\n");
      in_xml = xml;
      got_in_mode = true;
    }
  else if (! out_fn)
    {
      if (got_out_mode)
	fatal (1, "Only one input file type may be specified.\n");
      out_xml = xml;
      got_out_mode = true;
    }
  else
    fatal (1, "File type options may only appear before filenames.\n");
}


void set_fn (char *fn)
{
  if (! in_fn)
    in_fn = fn;
  else if (! out_fn)
    out_fn = fn;
  else
    fatal (1, "Only two files (one input and one output) may be specified.\n");
}


int main (int argc, char *argv[])
{
  progname = argv [0];

  in_fn = NULL;
  got_in_mode = false;
  in_xml = false;

  out_fn = NULL;
  got_out_mode = false;
  out_xml = true;

  while (--argc)
    {
      argv++;
      if (argv [0][0] == '-')
	{
	  if ((strcmp (argv [0], "--nsim") == 0) ||
	      (strcmp (argv [0], "-n") == 0))
	    set_mode (false);
	  else if ((strcmp (argv [0], "--nonpareil") == 0) ||
		   (strcmp (argv [0], "-x") == 0))
	    set_mode (true);
	  else
	    fatal (1, "unrecognized option '%s'\n", argv [0]);
	}
      else
	set_fn (argv [0]);
    }

  if (! (in_fn && out_fn))
    fatal (1, "Both the input and output filenames must be specified.\n");

  memset (& regs, 0, sizeof (regs));
  memset (ram_used, 0, sizeof (ram_used));

  if (in_xml)
    state_read_xml (in_fn);
  else
    state_read_nsim (in_fn);

  if (out_xml)
    state_write_xml (out_fn);
  else
    state_write_nsim (out_fn);

  exit (0);
}
