/*
kml.c: KML parser
$Id$
Copyright 2004 Eric L. Smith <eric@brouhaha.com>

CSIM is a simulator for the processor used in the HP "Classic" series
of calculators, which includes the HP-35, HP-45, HP-55, HP-65, HP-70,
and HP-80.

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
#include <unistd.h>

#include "util.h"
#include "kml.h"


int lineno;
int errors;

char linebuf [MAX_LINE];
char *lineptr;

kml_t *kml;


void yyerror (char *s)
{
  fprintf (stderr, "%s\n", s);
}


void range_check (int val, int min, int max)
{
  if ((val < min) || (val > max))
    yyerror ("value out of range");
}


void read_kml_file (char *fn)
{
  kml_t *kml;

  yyin = fopen (fn, "r");
  if (! yyin)
    fatal (2, "Can't open KML file\n");
 
  kml = alloc (sizeof (kml_t));

  yyparse ();
  
  fclose (yyin);
}
