/*
casm.h

CASM is an assembler for the processor used in the HP "Classic" series
of calculators, which includes the HP-35, HP-45, HP-55, HP-65, HP-70,
and HP-80.

Copyright 1995 Eric L. Smith

CASM is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License version 2 as published by the Free
Software Foundation.  Note that I am not granting permission to redistribute
or modify CASM under the terms of any later version of the General Public
License.

This program is distributed in the hope that it will be useful (or at least
amusing), but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with
this program (in the file "COPYING"); if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

extern int pass;
extern int lineno;
extern int errors;

extern int group;	/* current rom group */
extern int rom;		/* current rom */
extern int pc;		/* current pc */

extern int dsr;		/* delayed select rom */
extern int dsg;		/* delayed select group */

extern char flag_char;  /* used to mark jumps across rom banks */

#define MAX_LINE 256
extern char linebuf [MAX_LINE];
extern char *lineptr;

void do_label (char *s);

void emit (int op);
void etarget (int targrom, int targpc);  /* for branch target info */

void endline (void);

void range (int val, int min, int max);

char *newstr (char *orig);
