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

#include <math.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "SDL/SDL_audio.h"

#include "util.h"
#include "sound.h"


static bool sound_open = false;


#define SAMPLE_RATE 22050

#define MAX_SAMPLE 1024


#define MAX_SOUNDS 4


typedef enum { SOUND_NONE, SOUND_RECORDED, SOUND_SYNTH } sound_type_t;

#define SYNTH_FRAC_BITS 16


typedef struct
{
  sound_type_t type;

  // The following are for SOUND_RECORDED only:
  uint8_t      *data;
  uint32_t     len;        // length of data
  uint32_t     pos;

  // The following are for SOUND_SYNTH only:
  int16_t      *waveform_table;
  uint32_t     waveform_table_length;
  uint32_t     waveform_pos;        // fractional
  uint32_t     waveform_inc;        // fractional
  int32_t      waveform_duration;   // in samples
  float        waveform_amplitude;  // 0..1
} sound_info_t;

sound_info_t sounds [MAX_SOUNDS];

SDL_AudioSpec hw_fmt;


void sinewave_init (void);


static void sound_mix_recorded (sound_info_t *sound,
				uint8_t *stream,
				int len)
{
  int count;

  count = sound->len - sound->pos;
  if (count > len)
    count = len;
  SDL_MixAudio (stream,
		& sound->data [sound->pos],
		count,
		SDL_MIX_MAXVOLUME);
  sound->pos += count;
  if (sound->pos >= sound->len)
    sound->type = SOUND_NONE;
}


static void sound_mix_synth (sound_info_t *sound,
			     uint8_t *stream,
			     int len)
{
  int i;
  int16_t sample [MAX_SAMPLE];

  if (sound->waveform_duration && (len > sound->waveform_duration))
    len = sound->waveform_duration;

  for (i = 0; i < len; i++)
    {
      uint32_t ip = sound->waveform_pos >> SYNTH_FRAC_BITS;  // integer part
      uint32_t wrap = sound->waveform_table_length << SYNTH_FRAC_BITS;
      // $$$ might be nice to interpolate
      sample [i] = sound->waveform_table [ip] * sound->waveform_amplitude + 0.5;
      sound->waveform_pos += sound->waveform_inc;
      if (sound->waveform_pos >= wrap)
	sound->waveform_pos -= wrap;
      
    }
  SDL_MixAudio (stream,
		(uint8_t *) & sample [0],
		len,
		SDL_MIX_MAXVOLUME);
  if (sound->waveform_duration)
    {
      sound->waveform_duration -= len;
      if (! sound->waveform_duration)
	sound->type = SOUND_NONE;
    }
}


static void sound_callback (void *unused UNUSED,
			    uint8_t *stream,
			    int len)
{
  int i;

  for (i = 0; i < MAX_SOUNDS; i++)
    switch (sounds [i].type)
      {
      case SOUND_NONE:
	break;
      case SOUND_RECORDED:
	sound_mix_recorded (& sounds [i], stream, len);
	break;
      case SOUND_SYNTH:
	sound_mix_synth (& sounds [i], stream, len);
	break;
      }
}


bool init_sound (void)
{
  SDL_AudioSpec req_fmt;

  if (sound_open)
    return true;

  req_fmt.freq = SAMPLE_RATE;
  req_fmt.format = SAMPLE_TYPE;
  req_fmt.channels = 1;
  req_fmt.samples = MAX_SAMPLE;
  req_fmt.callback = sound_callback;
  req_fmt.userdata = NULL;

  if (SDL_OpenAudio (& req_fmt, & hw_fmt) < 0)
    return false;

  memset (& sounds, 0, sizeof (sounds));

  sinewave_init ();

  SDL_PauseAudio (0);

  sound_open = true;

  return true;
}


static int find_open_sound_slot (void)
{
  int index;

  if (! sound_open)
    return -1;

  for (index = 0; index < MAX_SOUNDS; index++)
    if (sounds [index].type == SOUND_NONE)
      break;

  if (index >= MAX_SOUNDS)
    return -1;

  if (sounds [index].data)
    {
      free (sounds [index].data);
      sounds [index].data = NULL;
    }

  return index;
}


int play_sound (const uint8_t *buf, size_t len)
{
  int index;
  SDL_AudioCVT cvt;
  int format;
  uint8_t channels;
  int freq;

  index = find_open_sound_slot ();
  if (index < 0)
    return index;

  buf += 44;  // skip wave, data chunk header
  len -= 44;
  // $$$ should parse header
  format = AUDIO_U8;
  channels = 1;
  freq = 22050;

  if (SDL_BuildAudioCVT (& cvt,
			 format, channels, freq,
			 hw_fmt.format, hw_fmt.channels, hw_fmt.freq) < 0)
    return -1;

  cvt.buf = alloc (len * cvt.len_mult);
  cvt.len = len;
  memcpy (cvt.buf, buf, len);

  SDL_ConvertAudio (& cvt);

  SDL_LockAudio ();
  sounds [index].type = SOUND_RECORDED;
  sounds [index].data = cvt.buf;
  sounds [index].len = cvt.len * cvt.len_mult;
  sounds [index].pos = 0;
  SDL_UnlockAudio ();

  SDL_PauseAudio (0);

  return index;
}


// duration can be zero for continuous
int synth_sound (float    frequency,  // Hz
		 float    amplitude,  // 0..1
		 float    duration,   // s, or zero for indefinite
		 sample_t *waveform_table,
		 uint32_t waveform_table_length)
{
  int index;
  float inc;

  index = find_open_sound_slot ();
  if (index < 0)
    return index;

  inc = (waveform_table_length * frequency) / SAMPLE_RATE;

  SDL_LockAudio ();
  sounds [index].type = SOUND_SYNTH;

  sounds [index].waveform_table = waveform_table;
  sounds [index].waveform_table_length  = waveform_table_length;
  sounds [index].waveform_pos = 0;
  sounds [index].waveform_inc = inc * (1 << SYNTH_FRAC_BITS) + 0.5;
  sounds [index].waveform_amplitude = amplitude;
  sounds [index].waveform_duration = duration * SAMPLE_RATE;

#ifdef SYNTH_DEBUG
  printf ("frequency = %f, inc = %f, waveform_inc = %d\n",
	  frequency, inc, sounds [index].waveform_inc);
#endif

  SDL_UnlockAudio ();

  return index;
}


bool stop_sound (int id)
{
  if (id > MAX_SOUNDS)
    return false;

  SDL_LockAudio ();
  sounds [id].type = SOUND_NONE;
  SDL_UnlockAudio ();

  if (sounds [id].data)
    {
      free (sounds [id].data);
      sounds [id].data = NULL;
    }

  return true;
}


sample_t squarewave_waveform_table [] = { -32767, 32767 };
uint32_t squarewave_waveform_table_length = sizeof (squarewave_waveform_table) / sizeof (sample_t);


#define SINEWAVE_SAMPLE_COUNT 256

sample_t sinewave_waveform_table [SINEWAVE_SAMPLE_COUNT];
uint32_t sinewave_waveform_table_length = SINEWAVE_SAMPLE_COUNT;


void sinewave_init (void)
{
  int i;
  double angle;
  double val;

  for (i = 0; i < SINEWAVE_SAMPLE_COUNT; i++)
    {
      angle = i * M_2_PI / SINEWAVE_SAMPLE_COUNT;
      val = sin (angle);
      sinewave_waveform_table [i] = (32767 * val) + 0.5;
    }
}
