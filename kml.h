/*
kml.h: KML parser definitions
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

extern FILE *yyin;

extern int lineno;
extern int errors;

#define MAX_LINE 256
extern char linebuf [MAX_LINE];
extern char *lineptr;


int yylex (void);
int yyparse (void);
void yyerror (char *s);


#define KML_MAX_COLOR 16
#define KML_MAX_ANNUNCIATOR 16
#define KML_MAX_BUTTON 256
#define KML_MAX_SCANCODE 256

typedef struct
{
  int x;
  int y;
} kml_offset_t;

typedef struct
{
  int width;
  int height;
} kml_size_t;

typedef struct
{
  int r;
  int g;
  int b;
} kml_color_t;

typedef struct
{
  int foo;
  int bar;
} kml_down_t;

typedef struct
{
  kml_size_t size;
  kml_offset_t offset;
  kml_down_t down;
} kml_annunciator_t;

typedef enum
  {
    KML_CMD_MAP = 1,
    KML_CMD_PRESS,
    KML_CMD_RELEASE,
    KML_CMD_SETFLAG,
    KML_CMD_RESETFLAG,
    KML_CMD_MENUITEM,
    KML_CMD_IFFLAG,
    KML_CMD_IFPRESSED
  } kml_cmd_t;

typedef struct kml_command_list_t
{
  struct kml_command_list_t *next;
  kml_cmd_t cmd;
  int arg1;
  int arg2;
  struct kml_command_list_t *then_part;
  struct kml_command_list_t *else_part;
} kml_command_list_t;

typedef struct
{
  int type;
  kml_offset_t offset;
  kml_size_t size;
  int keycode;
  int virtual;
  int nohold;
  kml_command_list_t *onup;
  kml_command_list_t *ondown;
} kml_button_t;

typedef struct
{
  char *title;
  char *author;
  char *hardware;
  char *model;
  int  class;
  char *rom;
  char *patch;
  char *bitmap;
  char *print;
  int debug;

  kml_offset_t background_offset;
  kml_size_t background_size;

  int display_zoom;
  kml_offset_t display_offset;
  kml_color_t *display_color [KML_MAX_COLOR];

  kml_annunciator_t *annunciator [KML_MAX_ANNUNCIATOR];

  kml_button_t *button [KML_MAX_BUTTON];

  kml_command_list_t *scancode [KML_MAX_SCANCODE];
} kml_t;

extern kml_t *kml;

void read_kml_file (char *fn);
