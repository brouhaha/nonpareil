/*
$Id$
Copyright 2004, 2005 Eric L. Smith <eric@brouhaha.com>

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

#include <stdbool.h>
#include <stdint.h>

#include "SDL_mixer.h"

#include "sound.h"


bool init_sound (void)
{
  return Mix_OpenAudio (22050,
			AUDIO_U8,
			1,
			32768) == 0;
}


bool play_sound (const uint8_t *buf, size_t len)
{
  Mix_Chunk *chunk;

  chunk = Mix_QuickLoad_WAV (buf);

  return Mix_PlayChannel (-1, // any channel,
			  chunk,
			  0) >= 0; // loops - 0 means play once

}
