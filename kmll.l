/*
$Id$
Copyright 2004 Eric L. Smith <eric@brouhaha.com>

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

%{
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "display.h"
#include "kml.h"
#include "kmly.tab.h"

#include "util.h"

int octal_escape (char *p);

#define MAX_STR_CONST 300

#define MAX_INCLUDE_DEPTH 10

int include_stack_ptr = 0;
YY_BUFFER_STATE include_stack [MAX_INCLUDE_DEPTH];

%}

%option case-insensitive

octaldig	[0-7]
hexdig		[0-9a-fA-F]
digit		[0-9]
alpha		[a-zA-Z]

%%

[1-9]{digit}*	{ yylval.integer = atoi (yytext); return INTEGER; }
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
character	return (CHARACTER);
class		return (CLASS);
color		return (COLOR);
debug		return (DEBUG);
default		return (DEFAULT);
digits		return (DIGITS);
display		return (DISPLAY);
down		return (DOWN);
else		return (ELSE);
end		return (END);
flag		return (FLAG);
global		return (GLOBAL);
hardware	return (HARDWARE);
ifflag		return (IFFLAG);
ifpressed	return (IFPRESSED);
image		return (IMAGE);
include		return (INCLUDE);
keycode		return (KEYCODE);
lcd		return (LCD);
listing		return (LISTING);
map		return (MAP);
menuitem	return (MENUITEM);
model		return (MODEL);
nohold		return (NOHOLD);
offset		return (OFFSET);
ondown		return (ONDOWN);
onup		return (ONUP);
outin		return (OUTIN);
patch		return (PATCH);
position	return (POSITION);
press		return (PRESS);
print		return (PRINT);
release		return (RELEASE);
resetflag	return (RESETFLAG);
rom		return (ROM);
scancode	return (SCANCODE);
segment		return (SEGMENT);
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
		  if (--include_stack_ptr < 0)
		    yyterminate ();
		  else
		    {
		      yy_delete_buffer (YY_CURRENT_BUFFER);
		      yy_switch_to_buffer (include_stack [include_stack_ptr]);
		    }
		}

%%

void kml_include (char *fn)
{
  if (include_stack_ptr >= MAX_INCLUDE_DEPTH)
    fatal (2, "includes nexted too deeply\n");
  include_stack [include_stack_ptr++] = YY_CURRENT_BUFFER;
  yyin = fopen (fn, "r");
  if (! yyin)
    fatal (2, "error opening include file '%s'\n", fn);
  yy_switch_to_buffer (yy_create_buffer (yyin, YY_BUF_SIZE));
}

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
