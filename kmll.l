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
#include <string.h>

#include "kmly.tab.h"
#include "kml.h"

#include "util.h"

#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
  { \
    int r = strlen (lineptr); \
    if (r > max_size) \
      r = max_size; \
    memcpy (buf, lineptr, r); \
    lineptr += r; \
    result = r; \
  }
%}

octaldig	[0-7]
digit		[0-9]
alpha		[a-zA-Z]
%%

[1-9]{digit}+	{ yylval.integer = atoi (yytext); return INTEGER; }
0{octaldig}+	{ sscanf (yytext+1, "%o", &yylval.integer); return INTEGER; }
@{octaldig}+	{ sscanf (yytext+1, "%o", &yylval.integer); return INTEGER; }

{alpha}*	{
                          if ((yylval.integer = keyword (yytext)))
                            return yylval.integer;
			/* $$$ identifiers not allowed! */
                        }

".*"		{
			return STRING;
		}

[ \t]+		;
\n		;

%%

struct keyword
{
  char *name;
  int value;
}
keywords [] =
{
  { "annunciator", ANNUNCIATOR },
  { "author",      AUTHOR },
  { "background",  BACKGROUND },
  { "bitmap",      BITMAP },
  { "button",      BUTTON },
  { "class",       CLASS },
  { "color",       COLOR },
  { "debug",       DEBUG },
  { "down",        DOWN },
  { "else",        ELSE },
  { "end",         END },
  { "global",      GLOBAL },
  { "hardware",    HARDWARE },
  { "ifflag",      IFFLAG },
  { "ifpressed",   IFPRESSED },
  { "lcd",         LCD },
  { "map",         MAP },
  { "menuitem",    MENUITEM },
  { "model",       MODEL },
  { "nohold",      NOHOLD },
  { "offset",      OFFSET },
  { "ondown",      ONDOWN },
  { "onup",        ONUP },
  { "outin",       OUTIN },
  { "patch",       PATCH },
  { "press",       PRESS },
  { "print",       PRINT },
  { "release",     RELEASE },
  { "resetflag",   RESETFLAG },
  { "rom",         ROM },
  { "scancode",    SCANCODE },
  { "setflag",     SETFLAG },
  { "size",        SIZE },
  { "title",       TITLE },
  { "type",        TYPE },
  { "virtual",     VIRTUAL },
  { "zoom",        ZOOM },
  { NULL,          0 }
};

int keyword (char *string)
{
  struct keyword *ptr;

  for (ptr = keywords; ptr->name; ptr++)
    if (strcasecmp (string, ptr->name) == 0)
      return ptr->value;
  return 0;
}

int yywrap (void)
{
#ifdef OLD_FLEX
/* Only needed for versions of flex prior to 2.4.1. */
  yyrestart (yyin);
#endif /* OLD_FLEX */
  return (1);
}
