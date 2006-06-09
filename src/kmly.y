/*
$Id$
Copyright 2004, 2006 Eric L. Smith <eric@brouhaha.com>

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
#include <stdio.h>

#include <gsf/gsf-infile.h>

#include "util.h"
#include "display.h"
#include "kml.h"
#include "scancode.h"

/* parser temporaries */
kml_t *yy_kml;
int kml_cur_idx;
int kml_cur_idx2;
%}

%union {
  int integer;
  char *string;
  struct { int a; int b; } intpair;
  kml_command_list_t *cmdlist;
}

%token <integer> INTEGER
%token <string> STRING
%token <integer> CHAR

%token ANNUNCIATOR  AUTHOR       BACKGROUND   BITMAP       BUTTON
%token CHARACTER    CLASS        COLOR        DEBUG        DEFAULT
%token DIGITS       DISPLAY      DOWN         ELSE         END
%token FLAG         GLOBAL       HARDWARE     IFFLAG       IFPRESSED
%token IMAGE        INCLUDE      KEYCODE      LCD          LISTING
%token MAP          MENUITEM     MODEL        NOHOLD       OFFSET
%token ONDOWN       ONUP         OUTIN        PATCH        POSITION
%token PRESS        PRINT        RELEASE      RESETFLAG    ROM
%token SCANCODE     SEGMENT      SEGMENTS     SETFLAG      SIZE
%token SWITCH       TITLE        TRANSPARENCY TYPE         VIRTUAL
%token ZOOM


%type <string>  image_stmt

%type <intpair> offset_stmt size_stmt down_stmt

%type <cmdlist> command_list command elsepart
%type <cmdlist> map_command press_command release_command setflag_command
%type <cmdlist> resetflag_command menuitem_command ifflag_command
%type <cmdlist> ifpressed_command

%type <integer> char_id
%type <integer> segment_list
%type <integer> scancode_id

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
			|	display_section
			|	annunciator_section
			|	switch_section
			|	button_section
			|	scancode_section
			|	include_stmt
			;

include_stmt		:	INCLUDE STRING { kml_include ($2); }
			;

scancode_id		:	INTEGER { $$ = $1; }
			|	STRING { $$ = get_scancode_from_name ($1); }
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
			|	listing_stmt
			|	patch_stmt
			|	image_stmt { yy_kml->image_fn = newstr ($1); }
			|	transparency_stmt
			|	global_color_stmt
			|	print_stmt
			|	debug_stmt
			;

title_stmt		:	TITLE STRING { yy_kml->title = newstr ($2); } ;

author_stmt		:	AUTHOR STRING { yy_kml->author = newstr ($2); } ;

hardware_stmt		:	HARDWARE STRING { yy_kml->hardware = newstr ($2); } ;

model_stmt		:	MODEL STRING { yy_kml->model = newstr ($2); } ;

class_stmt		:	CLASS INTEGER { yy_kml->class = $2; } ;

rom_stmt		:	ROM STRING { yy_kml->rom_fn = newstr ($2); } ;

listing_stmt		:	LISTING STRING { yy_kml->rom_listing_fn = newstr ($2); } ;

patch_stmt		:	PATCH STRING { yy_kml->patch_fn = newstr ($2); } ;

transparency_stmt	:	TRANSPARENCY INTEGER
				{ yy_kml->has_transparency = 1;
				  yy_kml->transparency_threshold = $2; } ;

global_color_stmt	:	COLOR INTEGER INTEGER INTEGER INTEGER
				{ range_check ($2, 0, KML_MAX_GLOBAL_COLOR - 1);
				  yy_kml->global_color [$2] = alloc (sizeof (kml_color_t));
				  yy_kml->global_color [$2]->r = $3;
				  yy_kml->global_color [$2]->g = $4;
				  yy_kml->global_color [$2]->b = $5; } ;

print_stmt		:	PRINT STRING { printf ("%s\n", $2); } ;

debug_stmt		:	DEBUG INTEGER { yy_kml->debug = $2; } ;

/*----------------------------------------------------------------------------
 common statements, used in several sections
----------------------------------------------------------------------------*/

offset_stmt		:	OFFSET INTEGER INTEGER { $$.a = $2; $$.b = $3; } ;

size_stmt		:	SIZE INTEGER INTEGER { $$.a = $2; $$.b = $3; };

down_stmt		:	DOWN INTEGER INTEGER { $$.a = $2; $$.b = $3; };

image_stmt		:	image_stmt_name STRING { $$ = newstr ($2); } ;

image_stmt_name		:	IMAGE
			|	BITMAP /* backward compatability */
			;

/*----------------------------------------------------------------------------
 background section
----------------------------------------------------------------------------*/

background_section	:	BACKGROUND background_stmt_list END ;

background_stmt_list	:	background_stmt
			|	background_stmt background_stmt_list
			;

background_stmt		:	offset_stmt
				{ yy_kml->has_background_offset = 1;
				  yy_kml->background_offset.x = $1.a;
				  yy_kml->background_offset.y = $1.b; }
			|	size_stmt
				{ yy_kml->has_background_size = 1;
				  yy_kml->background_size.width = $1.a;
				  yy_kml->background_size.height = $1.b; }
			;

/*----------------------------------------------------------------------------
 display section
----------------------------------------------------------------------------*/

display_section		:	display_section_name display_stmt_list END ;

display_section_name	:	DISPLAY
			|	LCD	/* backward compatability */
			;

display_stmt_list		:	display_stmt
			|	display_stmt display_stmt_list
			;

display_stmt		:	zoom_stmt
			|	digits_stmt
			|	size_stmt { yy_kml->display_size.width = $1.a;
				            yy_kml->display_size.height = $1.b; }
			|	offset_stmt { yy_kml->display_offset.x = $1.a;
					      yy_kml->display_offset.y = $1.b; }
			|	display_color_stmt
			|	character_stmt
			|	segments_section
			|	annunciator_section
			;

zoom_stmt		:	ZOOM INTEGER { yy_kml->display_zoom = $2; } ;

display_color_stmt	:	COLOR INTEGER INTEGER INTEGER INTEGER
				{ range_check ($2, 0, KML_MAX_DISPLAY_COLOR - 1);
				  yy_kml->display_color [$2] = alloc (sizeof (kml_color_t));
				  yy_kml->display_color [$2]->r = $3;
				  yy_kml->display_color [$2]->g = $4;
				  yy_kml->display_color [$2]->b = $5; } ;

digits_stmt		:	DIGITS INTEGER digit_param_list END
				{ range_check ($2, 1, KML_MAX_DIGITS);
				  yy_kml->display_digits = $2; } ;

digit_param_list	:	digit_param
			|	digit_param digit_param_list
			;

digit_param		:	size_stmt { yy_kml->digit_size.width = $1.a;
					    yy_kml->digit_size.height = $1.b; }
			|	offset_stmt { yy_kml->digit_offset.x = $1.a;
					      yy_kml->digit_offset.y = $1.b; }
			;

character_stmt		:	CHARACTER char_id SEGMENT segment_list END
				{
				  if ($2 >= 0)
				    {
				      range_check ($2, 0, KML_MAX_CHARACTER - 1);
				      yy_kml->character_segment_map [$2] = $4;
				    }
				  else
				    {
				      int i;
				      for (i = 0; i < KML_MAX_CHARACTER; i++)
					yy_kml->character_segment_map [i] = $4;
				    }
				}
			;

char_id			:	CHAR { $$ = $1 }
			|	INTEGER { $$ = $1; }
			|	DEFAULT { $$ = -1; }
			;

segment_list		:	{ $$ = 0; }
			|	CHAR segment_list { range_check_char ($1, KML_FIRST_SEGMENT, KML_FIRST_SEGMENT + KML_MAX_SEGMENT - 1);
						    $$ = (1 << ($1 - KML_FIRST_SEGMENT)) + $2; }
			;

segments_section	:	SEGMENTS segments_stmt_list END ;

segments_stmt_list	:	segments_stmt
			|	segments_stmt segments_stmt_list
			;

segments_stmt		:	image_stmt { yy_kml->segment_image_fn = $1 }
			|	offset_stmt
				{ yy_kml->has_segment_image_offset = 1;
				  yy_kml->segment_image_offset.x = $1.a;
				  yy_kml->segment_image_offset.y = $1.b; }
			|	size_stmt
				{ yy_kml->has_segment_image_size = 1;
				  yy_kml->segment_image_size.width = $1.a;
				  yy_kml->segment_image_size.height = $1.b; }
			|	segment_stmt
			;

segment_stmt		:	SEGMENT CHAR
				{
				  range_check ($2, KML_FIRST_SEGMENT, KML_FIRST_SEGMENT + KML_MAX_SEGMENT - 1);
				  kml_cur_idx = $2 - KML_FIRST_SEGMENT;
				  yy_kml->segment [kml_cur_idx] = alloc (sizeof (kml_segment_t));
				}
				segment_param_list END ;

segment_param_list	:	segment_param
			|	segment_param segment_param_list
			;

segment_param		:	COLOR INTEGER INTEGER INTEGER
				{ yy_kml->segment [kml_cur_idx]->color.r = $2;
				  yy_kml->segment [kml_cur_idx]->color.g = $3;
				  yy_kml->segment [kml_cur_idx]->color.b = $4; }
			;

/*----------------------------------------------------------------------------
 annunciator section
----------------------------------------------------------------------------*/

annunciator_section	:	ANNUNCIATOR INTEGER
				{ range_check ($2, 0, KML_MAX_ANNUNCIATOR - 1);
				  kml_cur_idx = $2;
				  yy_kml->annunciator [$2] = alloc (sizeof (kml_annunciator_t)); }
				annunciator_stmt_list END
			 ;

annunciator_stmt_list	:	annunciator_stmt
			|	annunciator_stmt annunciator_stmt_list
			;

annunciator_stmt	:	size_stmt
				{ yy_kml->annunciator [kml_cur_idx]->size.width = $1.a;
				  yy_kml->annunciator [kml_cur_idx]->size.height = $1.b; }
			|	offset_stmt
				{ yy_kml->annunciator [kml_cur_idx]->offset.x = $1.a;
				  yy_kml->annunciator [kml_cur_idx]->offset.y = $1.b; }
			|	down_stmt
				{ yy_kml->annunciator [kml_cur_idx]->down.x = $1.a;
				  yy_kml->annunciator [kml_cur_idx]->down.y = $1.b; }
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

map_command		:	MAP scancode_id INTEGER
				{ $$ = alloc (sizeof (kml_command_list_t));
				  $$->cmd = KML_CMD_MAP;
				  $$->arg1 = $2;
				  $$->arg2 = $3; } ;

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
 switch section
----------------------------------------------------------------------------*/

switch_section		:	SWITCH INTEGER
				{ range_check ($2, 0, KML_MAX_SWITCH - 1);
				  kml_cur_idx = $2;
				  yy_kml->kswitch [$2] = alloc (sizeof (kml_switch_t)); }
			        switch_stmt_list END ;

switch_stmt_list	:	switch_stmt
			|	switch_stmt switch_stmt_list
			;


switch_stmt		:	size_stmt
				{ yy_kml->kswitch [kml_cur_idx]->size.width = $1.a;
				  yy_kml->kswitch [kml_cur_idx]->size.height = $1.b; }
			|	default_stmt
			|	position_section
			;

default_stmt		:	DEFAULT INTEGER { yy_kml->kswitch [kml_cur_idx]->default_position = $2; } ;


position_section	:	POSITION INTEGER
				{ range_check ($2, 0, KML_MAX_SWITCH_POSITION - 1);
				  kml_cur_idx2 = $2;
				  yy_kml->kswitch [kml_cur_idx]->position [$2] = alloc (sizeof (kml_switch_position_t)); }
				position_stmt_list END ;

position_stmt_list	:	position_stmt
			|	position_stmt position_stmt_list
			;

position_stmt		:	flag_stmt
			|	offset_stmt
				{ yy_kml->kswitch [kml_cur_idx]->position [kml_cur_idx2]->offset.x = $1.a;
				  yy_kml->kswitch [kml_cur_idx]->position [kml_cur_idx2]->offset.y = $1.b; }
			;

flag_stmt		:	FLAG INTEGER { yy_kml->kswitch [kml_cur_idx]->position [kml_cur_idx2]->flag = $2; } ;


/*----------------------------------------------------------------------------
 button section
----------------------------------------------------------------------------*/

button_section		:	BUTTON INTEGER
				{ range_check ($2, 0, KML_MAX_BUTTON - 1);
				  kml_cur_idx = $2;
				  yy_kml->button [$2] = alloc (sizeof (kml_button_t)); }
				button_stmt_list END ;

button_stmt_list	:	button_stmt
			|	button_stmt button_stmt_list
			;

button_stmt		:	type_stmt
			|	image_stmt
				{ yy_kml->button [kml_cur_idx]->image_fn = $1; }
			|	size_stmt
				{ yy_kml->button [kml_cur_idx]->size.width = $1.a;
				  yy_kml->button [kml_cur_idx]->size.height = $1.b; }
			|	offset_stmt
				{ yy_kml->button [kml_cur_idx]->offset.x = $1.a;
				  yy_kml->button [kml_cur_idx]->offset.y = $1.b; }
			|	down_stmt
				{ yy_kml->button [kml_cur_idx]->down.x = $1.a;
				  yy_kml->button [kml_cur_idx]->down.y = $1.b; }
			|	outin_stmt
			|	keycode_stmt
			|	virtual_stmt
			|	nohold_stmt
			|	onup_stmt
			|	ondown_stmt
			;

type_stmt		:	TYPE INTEGER { yy_kml->button [kml_cur_idx]->type = $2; } ;

outin_stmt		:	OUTIN INTEGER INTEGER { yyerror ("OUTIN not supported"); } ;

keycode_stmt		:	KEYCODE INTEGER { yy_kml->button [kml_cur_idx]->keycode = $2; } ;

virtual_stmt		:	VIRTUAL { yy_kml->button [kml_cur_idx]->virtual = 1; } ;

nohold_stmt		:	NOHOLD { yy_kml->button [kml_cur_idx]->nohold = 1; } ;

onup_stmt		:	ONUP command_list END
				{ yy_kml->button [kml_cur_idx]->onup = $2; } ;

ondown_stmt		:	ONDOWN command_list END
				{ yy_kml->button [kml_cur_idx]->ondown = $2; } ;

/*----------------------------------------------------------------------------
 scancode section
----------------------------------------------------------------------------*/

scancode_section	:	SCANCODE scancode_id command_list END
				{ kml_scancode_t *s = alloc (sizeof (kml_scancode_t));
				  s->scancode = $2;
				  s->commands = $3;
				  if (yy_kml->last_scancode)
				    {
				      yy_kml->last_scancode->next = s;
				      yy_kml->last_scancode = s;
				    }
				  else
				    {
				      yy_kml->first_scancode = s;
				      yy_kml->last_scancode = s;
				    }
				};

%%
