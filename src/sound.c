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
#include <stdlib.h>
#include <string.h>

#include "SDL_audio.h"

#include "util.h"
#include "sound.h"


static bool sound_open = false;


#define MAX_SOUNDS 4
typedef struct
{
  uint8_t  *data;
  uint32_t pos;
  uint32_t len;
} sound_info_t;

sound_info_t sounds [MAX_SOUNDS];

SDL_AudioSpec hw_fmt;


void sound_callback (void *unused, uint8_t *stream, int len)
{
  int i;
  int count;

  for (i = 0; i < MAX_SOUNDS; i++)
    {
      count = sounds [i].len - sounds [i].pos;
      if (count > len)
	count = len;
      SDL_MixAudio (stream,
		    & sounds [i].data [sounds [i].pos],
		    count,
		    SDL_MIX_MAXVOLUME);
      sounds [i].pos += count;
    }
}


bool init_sound (void)
{
  SDL_AudioSpec req_fmt;

  if (sound_open)
    return true;

  req_fmt.freq = 22050;
  req_fmt.format = AUDIO_S16,
  req_fmt.channels = 1;
  req_fmt.samples = 8192;
  req_fmt.callback = sound_callback;
  req_fmt.userdata = NULL;

  if (SDL_OpenAudio (& req_fmt, & hw_fmt) < 0)
    return false;

  memset (& sounds, 0, sizeof (sounds));

  SDL_PauseAudio (0);

  return true;
}


bool play_sound (const uint8_t *buf, size_t len)
{
  int index;
  SDL_AudioCVT cvt;
  int format;
  uint8_t channels;
  int freq;

  for (index = 0; index < MAX_SOUNDS; index++)
    if (sounds [index].pos == sounds [index].len)
      break;

  if (index >= MAX_SOUNDS)
    return false;

  if (sounds [index].data)
    free (sounds [index].data);

  buf += 44;  // skip wave, data chunk header
  len -= 44;
  // $$$ should parse header
  format = AUDIO_U8;
  channels = 1;
  freq = 22050;

  if (SDL_BuildAudioCVT (& cvt,
			 format, channels, freq,
			 hw_fmt.format, hw_fmt.channels, hw_fmt.freq) < 0)
    return false;

  cvt.buf = alloc (len * cvt.len_mult);
  cvt.len = len;
  memcpy (cvt.buf, buf, len);

  SDL_ConvertAudio (& cvt);

  SDL_LockAudio ();
  sounds [index].data = cvt.buf;
  sounds [index].len = cvt.len * cvt.len_mult;
  sounds [index].pos = 0;
  SDL_UnlockAudio ();

  SDL_PauseAudio (0);

  return true;
}
