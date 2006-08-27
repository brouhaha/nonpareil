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

#define KML_MAX_GLOBAL_COLOR 2
#define KML_MAX_DISPLAY_COLOR 16

#define KML_MAX_DIGITS 15

/* For details of display segments, see the comments at the bottom of
 * the header file display.h.  */
#define KML_FIRST_SEGMENT 'a'
#define KML_MAX_SEGMENT 17

#define KML_MAX_CHARACTER 128
#define KML_MAX_ANNUNCIATOR 16

#define KML_MAX_BUTTON 256

#define KML_MAX_SWITCH 4
#define KML_MAX_SWITCH_POSITION 4

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
  int foo;
  int bar;
} kml_down_t;

typedef struct
{
  kml_size_t size;
  kml_offset_t offset;
  kml_offset_t down;
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
  int flag;
  char *image_fn;
  kml_command_list_t *onselect;
  kml_command_list_t *ondeselect;
} kml_switch_position_t;

typedef struct
{
  kml_size_t size;
  kml_offset_t offset;
  int default_position;
  kml_switch_position_t *position [KML_MAX_SWITCH_POSITION];
} kml_switch_t;

typedef struct
{
  int type;
  char *image_fn;
  kml_size_t size;
  kml_offset_t offset;
  kml_offset_t down;
  int keycode;
  int virtual;
  int nohold;
  kml_command_list_t *onup;
  kml_command_list_t *ondown;
} kml_button_t;


typedef struct kml_scancode_t
{
  struct kml_scancode_t *next;
  int scancode;
  kml_command_list_t *commands;
} kml_scancode_t;


typedef struct
{
  color_t  color;  // used for "scaled" segment type, which extracts
                       // only the portion of the image in this color
} kml_segment_t;


typedef struct
{
  char *title;
  char *author;
  char *hardware;
  char *model;
  int  class;
  char *rom_fn;
  char *rom_listing_fn;
  char *patch_fn;
  char *image_fn;
  char *image_cr;
  char *default_overlay_image_fn;
  int has_transparency;
  int transparency_threshold;
  color_t *global_color [KML_MAX_GLOBAL_COLOR];
  int debug;

  bool has_background_offset;
  kml_offset_t background_offset;
  bool has_background_size;
  kml_size_t background_size;

  int display_digits;
  kml_size_t digit_size;
  kml_offset_t digit_offset;

  segment_bitmap_t character_segment_map [KML_MAX_CHARACTER];

  char *segment_image_fn;             // used for "scaled" segment type
  bool has_segment_image_offset;
  kml_offset_t segment_image_offset;  // used for "scaled" segment type
  bool has_segment_image_size;
  kml_size_t segment_image_size;      // used for "scaled" segment type
  kml_segment_t *segment [KML_MAX_SEGMENT];

  int display_zoom;
  kml_size_t display_size;
  kml_offset_t display_offset;
  color_t *display_color [KML_MAX_DISPLAY_COLOR];

  kml_annunciator_t *annunciator [KML_MAX_ANNUNCIATOR];

  kml_switch_t *kswitch [KML_MAX_SWITCH];
  kml_button_t *button [KML_MAX_BUTTON];

  kml_scancode_t *first_scancode;
  kml_scancode_t *last_scancode;
} kml_t;

kml_t *read_kml_file (char *fn);

kml_t *read_kml_file_from_gsfinfile (GsfInfile *ncz, char *fn);

void free_kml (kml_t *kml);

void print_kml (FILE *f, kml_t *kml);


// for use in kml.c, kmll.l, and kmly.y only:

extern FILE *yyin;

GsfInfile *kml_gsfinfile;

extern int kml_lineno;
extern int kml_tokenpos;
extern int kml_errors;

#define KML_LINEBUF_SIZE 500
extern char kml_linebuf [KML_LINEBUF_SIZE];

int yylex (void);
int yyparse (void);
void yyerror (char *fmt, ...);

void range_check (int val, int min, int max);
void range_check_char (int val, int min, int max);

void kml_include (char *fn);
//int kml_include_end (void);

int kml_yyinput (unsigned char *buf, size_t max_size);
