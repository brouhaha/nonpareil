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
#include "symtab.h"
#include "kml.h"
%}

%union {
    int integer;
    char *string;
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

title_stmt		:	TITLE STRING ;

author_stmt		:	AUTHOR STRING ;

hardware_stmt		:	HARDWARE STRING ;

model_stmt		:	MODEL STRING ;

class_stmt		:	CLASS INTEGER ;

rom_stmt		:	ROM STRING ;

patch_stmt		:	PATCH STRING ;

bitmap_stmt		:	BITMAP STRING ;

print_stmt		:	PRINT STRING ;

debug_stmt		:	DEBUG INTEGER ;

/*----------------------------------------------------------------------------
 common statements, used in several sections
----------------------------------------------------------------------------*/

offset_stmt		:	OFFSET INTEGER INTEGER ;

size_stmt		:	SIZE INTEGER INTEGER ;

down_stmt		:	DOWN INTEGER INTEGER ;

/*----------------------------------------------------------------------------
 background section
----------------------------------------------------------------------------*/

background_section	:	BACKGROUND background_stmt_list END ;

background_stmt_list	:	background_stmt
			|	background_stmt background_stmt_list
			;

background_stmt		:	offset_stmt
			|	size_stmt
			;

/*----------------------------------------------------------------------------
 lcd section
----------------------------------------------------------------------------*/

lcd_section		:	LCD lcd_stmt_list END ;

lcd_stmt_list		:	lcd_stmt
			|	lcd_stmt lcd_stmt_list
			;

lcd_stmt		:	zoom_stmt
			|	offset_stmt
			|	color_stmt
			;

zoom_stmt		:	ZOOM INTEGER ;

color_stmt		:	COLOR INTEGER INTEGER INTEGER INTEGER ;

/*----------------------------------------------------------------------------
 annunciator section
----------------------------------------------------------------------------*/

annunciator_section	:	ANNUNCIATOR INTEGER annunciator_stmt_list END ;

annunciator_stmt_list	:	annunciator_stmt
			|	annunciator_stmt annunciator_stmt_list
			;

annunciator_stmt	:	size_stmt
			|	offset_stmt
			|	down_stmt
			;

/*----------------------------------------------------------------------------
 commands (used in button and scancode sections)
----------------------------------------------------------------------------*/

command_list		:	command
			|	command command_list
			;

command			:	map_command
			|	press_command
			|	release_command
			|	setflag_command
			|	resetflag_command
			|	menuitem_command
			|	ifflag_command
			|	ifpressed_command
			;

map_command		:	MAP INTEGER INTEGER ;

press_command		:	PRESS INTEGER ;

release_command		:	RELEASE INTEGER ;

setflag_command		:	SETFLAG INTEGER ;

resetflag_command	:	RESETFLAG INTEGER ;

menuitem_command	:	MENUITEM INTEGER ;

elsepart		:	/* null */
			|	ELSE command_list
			;

ifflag_command		:	IFFLAG INTEGER command_list elsepart END ;

ifpressed_command	:	IFPRESSED INTEGER command_list elsepart END ;

/*----------------------------------------------------------------------------
 button section
----------------------------------------------------------------------------*/

button_section		:	BUTTON INTEGER button_stmt_list END ;

button_stmt_list	:	button_stmt
			|	button_stmt button_stmt_list
			;

button_stmt		:	type_stmt
			|	size_stmt
			|	offset_stmt
			|	down_stmt
			|	outin_stmt
			|	keycode_stmt
			|	virtual_stmt
			|	nohold_stmt
			|	onup_stmt
			|	ondown_stmt
			;

type_stmt		:	TYPE INTEGER ;

outin_stmt		:	OUTIN INTEGER INTEGER ;

keycode_stmt		:	KEYCODE INTEGER ;

virtual_stmt		:	VIRTUAL ;

nohold_stmt		:	NOHOLD ;

onup_stmt		:	ONUP command_list END ;

ondown_stmt		:	ONDOWN command_list END ;

/*----------------------------------------------------------------------------
 scancode section
----------------------------------------------------------------------------*/

scancode_section	:	SCANCODE INTEGER command_list END ;

%%
