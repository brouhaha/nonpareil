/*
Copyright 2006, 2010, 2022 Eric Smith <spacewar@gmail.com>

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


typedef struct calcdef_t calcdef_t;


calcdef_t *calcdef_load (struct sim_t *sim, char *ncd_fn);

void calcdef_free (calcdef_t *calcdef);


const char *calcdef_get_ncd_copyright (calcdef_t *calcdef);
const char *calcdef_get_ncd_license (calcdef_t *calcdef);

const char *calcdef_get_model_name (calcdef_t *calcdef);

int calcdef_get_platform (calcdef_t *calcdef);

int calcdef_get_arch (calcdef_t *calcdef);
int calcdef_get_arch_variant (calcdef_t *calcdef);

int calcdef_get_ram_size (calcdef_t *calcdef);

double calcdef_get_clock_frequency (calcdef_t *calcdef);  // in Hz

const segment_bitmap_t *calcdef_get_char_gen (calcdef_t *calcdef,
					      char *chip_id);

void calcdef_init_chips (calcdef_t *calcdef);


bool calcdef_get_key_scanner_as_flags(calcdef_t *calcdef);

bool calcdef_get_key (calcdef_t *calcdef,
		      int user_keycode,
		      hw_keycode_t *hw_keycode,
		      struct chip_t **chip,
		      int *ret_line,
		      struct chip_t **extra_chip,
		      int *extra_ret_line);

bool calcdef_get_switch_position_flag  (calcdef_t *calcdef,
					int sw,
					int pos,
					int index,
					struct chip_t **chip,
					int *flag,
					int *value);

bool calcdef_get_lcd_segment(calcdef_t *calcdef,
			     int digit,
			     int segment,
			     uint16_t *reg,
			     uint8_t *bit);
