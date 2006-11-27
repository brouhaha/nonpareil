/*
$Id$
Copyright 2004, 2005, 2006 Eric L. Smith <eric@brouhaha.com>

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

%{
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <gsf/gsf-infile.h>

#include "display.h"
#include "util.h"
#include "kml.h"
#include "kmly.h"


int octal_escape (char *p);

#define MAX_STR_CONST 300

#if 0
#define MAX_INCLUDE_DEPTH 10

int include_stack_ptr = 0;
GsfInput *include_stack [MAX_INCLUDE_DEPTH];
#endif

#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) (result = kml_yyinput (buf, max_size))
%}

%option case-insensitive

octaldig	[0-7]
hexdig		[0-9a-fA-F]
digit		[0-9]
alpha		[a-zA-Z]

%%

\-?[1-9]{digit}*	{ yylval.integer = atoi (yytext); return INTEGER; }
0{octaldig}*	{ sscanf (yytext, "%o", &yylval.integer); return INTEGER; }
@{octaldig}+	{ sscanf (yytext+1, "%o", &yylval.integer); return INTEGER; }
0x{hexdig}+	{ sscanf (yytext, "%x", &yylval.integer); return INTEGER; }
'.'		{ yylval.integer = yytext [1]; return CHAR; }

\"[^\"\n]*\"	{ yylval.string = newstrn (yytext + 1, strlen (yytext + 1) - 1);
                  return STRING; }

[ \t\n]+	;		/* whitespace */

\n.*		{ strncpy (kml_linebuf, yytext + 1, sizeof (kml_linebuf));
		  kml_lineno++;
		  yyless (1);  /* give back all but the \n to rescan */
		}

#.*		;		/* comment */

annunciator	return (ANNUNCIATOR);
author		return (AUTHOR);
background	return (BACKGROUND);
bitmap		return (BITMAP);
button		return (BUTTON);
color		return (COLOR);
credit		return (CREDIT);
debug		return (DEBUG);
default		return (DEFAULT);
digits		return (DIGITS);
display		return (DISPLAY);
down		return (DOWN);
else		return (ELSE);
end		return (END);
flag		return (FLAG);
global		return (GLOBAL);
ifflag		return (IFFLAG);
ifpressed	return (IFPRESSED);
image		return (IMAGE);
lcd		return (LCD);
map		return (MAP);
menuitem	return (MENUITEM);
model		return (MODEL);
nohold		return (NOHOLD);
offset		return (OFFSET);
ondown		return (ONDOWN);
onup		return (ONUP);
outin		return (OUTIN);
overlay         return (OVERLAY);
position	return (POSITION);
press		return (PRESS);
print		return (PRINT);
release		return (RELEASE);
resetflag	return (RESETFLAG);
scancode	return (SCANCODE);
segment		return (SEGMENT);
segments	return (SEGMENTS);
setflag		return (SETFLAG);
size		return (SIZE);
switch		return (SWITCH);
title		return (TITLE);
transparency	return (TRANSPARENCY);
type		return (TYPE);
virtual		return (VIRTUAL);
zoom		return (ZOOM);

[a-z]+		yyerror ("unknown keyword");

.		yyerror ("invalid character");

<<EOF>>		{
#if 0
		  if (kml_include_end () < 0)
#endif
		    yyterminate ();
		}

%%

int octal_escape (char *p)
{
  char buf [4];
  strncpy (buf, p, 3);
  buf [3] = '\0';
  return (strtoul (buf, NULL, 8));
}

int yywrap (void)
{
  return (1);
}

#if 0
void kml_include (char *fn)
{
  if (include_stack_ptr >= MAX_INCLUDE_DEPTH)
    fatal (2, "includes nexted too deeply\n");
  include_stack_ptr++;
  if (kml_gsfinfile)
    include_stack [include_stack_ptr] = gsf_infile_child_by_name (kml_gsfinfile, fn);
  else
    include_stack [include_stack_ptr] = ???;
  if (! include_stack [include_stack_ptr])
    fatal (2, "error opening include file '%s'\n", fn);
  yy_switch_to_buffer (yy_create_buffer (yyin, YY_BUF_SIZE));
}

int kml_include_end (void)
{
  if ((--include_stack_ptr) <= 0)
    return include_stack_ptr;

  yy_delete_buffer (YY_CURRENT_BUFFER);
  yy_switch_to_buffer (include_stack [include_stack_ptr]);
  return include_stack_ptr;
}
#endif
