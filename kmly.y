/*
kmly.y: KML script grammar
$Id$
Copyright 2004 Eric L. Smith

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
#include <stdio.h>

#include "util.h"
#include "kml.h"

/* parser temporaries */
int kml_cur_idx;
%}

%union {
  int integer;
  char *string;
  struct { int a; int b; } intpair;
  kml_command_list_t *cmdlist;
}

%token <integer> INTEGER
%token <string> STRING

%token ANNUNCIATOR AUTHOR      BACKGROUND  BITMAP      BUTTON      CLASS
%token COLOR       DEBUG       DISPLAY     DOWN        ELSE        END
%token GLOBAL      HARDWARE    IFFLAG      IFPRESSED   KEYCODE     LCD
%token MAP         MENUITEM    MODEL       NOHOLD      OFFSET      ONDOWN
%token ONUP        OUTIN       PATCH       PRESS       PRINT       RELEASE
%token RESETFLAG   ROM         SCANCODE    SETFLAG     SIZE        TITLE
%token TYPE        VIRTUAL     ZOOM

%type <intpair> offset_stmt size_stmt down_stmt

%type <cmdlist> command_list command elsepart
%type <cmdlist> map_command press_command release_command setflag_command
%type <cmdlist> resetflag_command menuitem_command ifflag_command
%type <cmdlist> ifpressed_command

%%

/*----------------------------------------------------------------------------
 top level
----------------------------------------------------------------------------*/

kml			:	sections

sections		:	section
			|	section sections
			;

section			:	global_section
			|	background_section
			|	lcd_section
			|	annunciator_section
			|	button_section
			|	scancode_section
			;

/*----------------------------------------------------------------------------
 global section
----------------------------------------------------------------------------*/

global_section		:	GLOBAL global_stmt_list END ;

global_stmt_list	:	global_stmt
			|	global_stmt global_stmt_list
			;

global_stmt		:	title_stmt
			|	author_stmt
			|	hardware_stmt
			|	model_stmt
			|	class_stmt
			|	rom_stmt
			|	patch_stmt
			|	bitmap_stmt
			|	print_stmt
			|	debug_stmt
			;

title_stmt		:	TITLE STRING { kml->title = $2; } ;

author_stmt		:	AUTHOR STRING { kml->author = $2; } ;

hardware_stmt		:	HARDWARE STRING { kml->hardware = $2; } ;

model_stmt		:	MODEL STRING { kml->model = $2; } ;

class_stmt		:	CLASS INTEGER { kml->class = $2; } ;

rom_stmt		:	ROM STRING { kml->rom = $2; } ;

patch_stmt		:	PATCH STRING { kml->patch = $2; } ;

bitmap_stmt		:	BITMAP STRING { kml->bitmap = $2; } ;

print_stmt		:	PRINT STRING { kml->print = $2; } ;

debug_stmt		:	DEBUG INTEGER { kml->debug = $2; } ;

/*----------------------------------------------------------------------------
 common statements, used in several sections
----------------------------------------------------------------------------*/

offset_stmt		:	OFFSET INTEGER INTEGER { $$.a = $2; $$.b = $3; } ;

size_stmt		:	SIZE INTEGER INTEGER { $$.a = $2; $$.b = $3; };

down_stmt		:	DOWN INTEGER INTEGER { $$.a = $2; $$.b = $3; };

/*----------------------------------------------------------------------------
 background section
----------------------------------------------------------------------------*/

background_section	:	BACKGROUND background_stmt_list END ;

background_stmt_list	:	background_stmt
			|	background_stmt background_stmt_list
			;

background_stmt		:	offset_stmt
				{ kml->background_offset.x = $1.a;
				  kml->background_offset.y = $1.b; }
			|	size_stmt
				{ kml->background_size.width = $1.a;
				  kml->background_size.height = $1.b; }
			;

/*----------------------------------------------------------------------------
 lcd section
----------------------------------------------------------------------------*/

lcd_section		:	LCD lcd_stmt_list END ;

lcd_stmt_list		:	lcd_stmt
			|	lcd_stmt lcd_stmt_list
			;

lcd_stmt		:	zoom_stmt
			|	offset_stmt { kml->display_offset.x = $1.a;
					      kml->display_offset.y = $1.b; }
			|	color_stmt
			;

zoom_stmt		:	ZOOM INTEGER { kml->display_zoom = $2; } ;

color_stmt		:	COLOR INTEGER INTEGER INTEGER INTEGER
				{ range_check ($2, 0, KML_MAX_COLOR);
				  kml->display_color [$2] = alloc (sizeof (kml_color_t));
				  kml->display_color [$2]->r = $3;
				  kml->display_color [$2]->g = $4;
				  kml->display_color [$2]->b = $5; } ;

/*----------------------------------------------------------------------------
 annunciator section
----------------------------------------------------------------------------*/

annunciator_section	:	ANNUNCIATOR INTEGER
				{ range_check ($2, 0, KML_MAX_ANNUNCIATOR);
				  kml_cur_idx = $2;
				  kml->annunciator [$2] = alloc (sizeof (kml_annunciator_t)); }
				annunciator_stmt_list END
			 ;

annunciator_stmt_list	:	annunciator_stmt
			|	annunciator_stmt annunciator_stmt_list
			;

annunciator_stmt	:	size_stmt
				{ kml->annunciator [kml_cur_idx]->size.width = $1.a;
				  kml->annunciator [kml_cur_idx]->size.width = $1.b; }
			|	offset_stmt
				{ kml->annunciator [kml_cur_idx]->offset.x = $1.a;
				  kml->annunciator [kml_cur_idx]->offset.y = $1.b; }
			|	down_stmt
				{ kml->annunciator [kml_cur_idx]->down.x = $1.a;
				  kml->annunciator [kml_cur_idx]->down.y = $1.b; }
			;

/*----------------------------------------------------------------------------
 commands (used in button and scancode sections)
----------------------------------------------------------------------------*/

command_list		:	command { $$ = $1; }
			|	command command_list { $$ = $1; $$->next = $2; }
			;

command			:	map_command { $$ = $1; }
			|	press_command { $$ = $1; }
			|	release_command { $$ = $1; }
			|	setflag_command { $$ = $1; }
			|	resetflag_command { $$ = $1; }
			|	menuitem_command { $$ = $1; }
			|	ifflag_command { $$ = $1; }
			|	ifpressed_command { $$ = $1; }
			;

map_command		:	MAP INTEGER INTEGER
				{ $$ = alloc (sizeof (kml_command_list_t));
				  $$->cmd = KML_CMD_MAP;
				  $$->arg1 = $2;
				  $$->arg1 = $3; } ;

press_command		:	PRESS INTEGER
				{ $$ = alloc (sizeof (kml_command_list_t));
				  $$->cmd = KML_CMD_PRESS;
				  $$->arg1 = $2; } ;

release_command		:	RELEASE INTEGER
				{ $$ = alloc (sizeof (kml_command_list_t));
				  $$->cmd = KML_CMD_RELEASE;
				  $$->arg1 = $2; } ;

setflag_command		:	SETFLAG INTEGER
				{ $$ = alloc (sizeof (kml_command_list_t));
				  $$->cmd = KML_CMD_SETFLAG;
				  $$->arg1 = $2; } ;

resetflag_command	:	RESETFLAG INTEGER
				{ $$ = alloc (sizeof (kml_command_list_t));
				  $$->cmd = KML_CMD_RESETFLAG;
				  $$->arg1 = $2; } ;

menuitem_command	:	MENUITEM INTEGER
				{ $$ = alloc (sizeof (kml_command_list_t));
				  $$->cmd = KML_CMD_MENUITEM;
				  $$->arg1 = $2; } ;

elsepart		:	/* null */ { $$ = NULL; }
			|	ELSE command_list { $$ = $2; }
			;

ifflag_command		:	IFFLAG INTEGER command_list elsepart END
				{ $$ = alloc (sizeof (kml_command_list_t));
				  $$->cmd = KML_CMD_IFFLAG;
				  $$->arg1 = $2;
				  $$->then_part = $3;
				  $$->else_part = $4; };

ifpressed_command	:	IFPRESSED INTEGER command_list elsepart END
				{ $$ = alloc (sizeof (kml_command_list_t));
				  $$->cmd = KML_CMD_IFPRESSED;
				  $$->arg1 = $2;
				  $$->then_part = $3;
				  $$->else_part = $4; };


/*----------------------------------------------------------------------------
 button section
----------------------------------------------------------------------------*/

button_section		:	BUTTON INTEGER
				{ range_check ($2, 0, KML_MAX_BUTTON);
				  kml_cur_idx = $2;
				  kml->button [$2] = alloc (sizeof (kml_button_t)); }
				button_stmt_list END ;

button_stmt_list	:	button_stmt
			|	button_stmt button_stmt_list
			;

button_stmt		:	type_stmt
			|	size_stmt
				{ kml->button [kml_cur_idx]->size.width = $1.a;
				  kml->button [kml_cur_idx]->size.height = $1.b; }
			|	offset_stmt
				{ kml->button [kml_cur_idx]->offset.x = $1.a;
				  kml->button [kml_cur_idx]->offset.y = $1.b; }
			|	down_stmt
				{ kml->button [kml_cur_idx]->down.x = $1.a;
				  kml->button [kml_cur_idx]->down.y = $1.b; }
			|	outin_stmt
			|	keycode_stmt
			|	virtual_stmt
			|	nohold_stmt
			|	onup_stmt
			|	ondown_stmt
			;

type_stmt		:	TYPE INTEGER { kml->button [kml_cur_idx]->type = $2; } ;

outin_stmt		:	OUTIN INTEGER INTEGER { yyerror ("OUTIN not supported"); } ;

keycode_stmt		:	KEYCODE INTEGER { kml->button [kml_cur_idx]->keycode = $2; } ;

virtual_stmt		:	VIRTUAL { kml->button [kml_cur_idx]->nohold = 1; } ;

nohold_stmt		:	NOHOLD { kml->button [kml_cur_idx]->nohold = 1; } ;

onup_stmt		:	ONUP command_list END
				{ kml->button [kml_cur_idx]->onup = $2; } ;

ondown_stmt		:	ONDOWN command_list END
				{ kml->button [kml_cur_idx]->ondown = $2; } ;

/*----------------------------------------------------------------------------
 scancode section
----------------------------------------------------------------------------*/

scancode_section	:	SCANCODE INTEGER command_list END
				{ range_check ($2, 0, KML_MAX_SCANCODE);
				  kml->scancode [$2] = $3 ; };

%%
