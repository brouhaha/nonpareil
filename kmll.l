/*
kmll.l: KML lexical analyzer specification
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

%{
#include <stdlib.h>
#include <string.h>

#include "kml.h"
#include "kmly.tab.h"

#include "util.h"

int octal_escape (char *p);

#define MAX_STR_CONST 300

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
class		return (CLASS);
color		return (COLOR);
debug		return (DEBUG);
digits		return (DIGITS);
display		return (DISPLAY);
down		return (DOWN);
else		return (ELSE);
end		return (END);
global		return (GLOBAL);
hardware	return (HARDWARE);
ifflag		return (IFFLAG);
image		return (IMAGE);
ifpressed	return (IFPRESSED);
keycode		return (KEYCODE);
lcd		return (LCD);
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
setflag		return (SETFLAG);
size		return (SIZE);
switch		return (SWITCH);
title		return (TITLE);
type		return (TYPE);
virtual		return (VIRTUAL);
zoom		return (ZOOM);

[a-z]+		yyerror ("unknown keyword");

.		yyerror ("invalid character");

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
#ifdef OLD_FLEX
/* Only needed for versions of flex prior to 2.4.1. */
  yyrestart (yyin);
#endif /* OLD_FLEX */
  return (1);
}
