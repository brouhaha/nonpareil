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

#undef USE_SOUND_THREAD

#include <math.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "SDL/SDL_audio.h"

#include "util.h"
#include "sound.h"


#ifdef USE_SOUND_THREAD
  #include <glib.h>
  typedef gint atomic_bool_t;
  #define atomic_bool_get(x) g_atomic_int_get(x)
  #define atomic_bool_set(x) g_atomic_int_compare_and_exchange (x, 0, 1)
  #define atomic_bool_clear(x) g_atomic_int_compare_and_exchange (x, 1, 0)
#else
  // Assume uint8_t reads and writes are atomic, true on most if not all
  // systems
  typedef uint8_t atomic_bool_t;
  static inline atomic_bool_t atomic_bool_get (atomic_bool_t *b)
  {
    return *b;
  }
  static inline void atomic_bool_set (atomic_bool_t *b)
  {
    *b = 1;
  }
  static inline void atomic_bool_clear (atomic_bool_t *b)
  {
    *b = 0;
  }
#endif


#define SAMPLE_RATE 22050

#define MAX_SAMPLE 2000


#define MAX_SOUNDS 4


typedef enum { SOUND_RECORDED, SOUND_SYNTH } sound_type_t;

#define SYNTH_FRAC_BITS 16


typedef struct
{
  atomic_bool_t run;           // true if sound is active
  atomic_bool_t stop_request;  // true if trying to stop this sound

  sound_type_t  type;

  // For SOUND_RECORDED:
  bool      free_data_when_done;
  uint8_t   *data;
  uint32_t  len;        // length of data
  uint32_t  pos;

  // For SOUND_SYNTH:
  int16_t   *waveform_table;
  uint32_t  waveform_table_length;
  uint32_t  waveform_pos;        // fractional
  uint32_t  waveform_inc;        // fractional
  int32_t   waveform_duration;   // in samples
  float     waveform_amplitude;  // 0..1
} sound_info_t;


struct
{
  atomic_bool_t open;          // true if sound subsystem has been opened
  atomic_bool_t enable;        // true if sound is enabled
#ifdef SOUND_USE_THREAD
  GThread       *thread;
  atomic_bool_t close_request;
  atomic_bool_t sound_thread_error;
#endif
  SDL_AudioSpec hw_fmt;
  sound_info_t  sounds [MAX_SOUNDS];
} sound_v;


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
    atomic_bool_clear (& sound->run);
}


static void sound_mix_synth (sound_info_t *sound,
			     uint8_t *stream,
			     int len)  // bytes, not samples
{
  int i;
  int16_t sample [MAX_SAMPLE];

  if (sound->waveform_duration && (len > sound->waveform_duration))
    len = sound->waveform_duration;

  for (i = 0; i < (len / 2); i++)
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
	atomic_bool_clear (& sound->run);
    }
}


static void sound_callback (void *unused UNUSED,
			    uint8_t *stream,
			    int len)
{
  int i;

  for (i = 0; i < MAX_SOUNDS; i++)
    {
      sound_info_t *sound = & sound_v.sounds [i];
      if (atomic_bool_get (& sound->run))
	{
	  if (atomic_bool_get (& sound->stop_request))
	    {
	      atomic_bool_clear (& sound->stop_request);
	      atomic_bool_clear (& sound->run);
	      continue;
	    }
	  switch (sound->type)
	    {
	    case SOUND_RECORDED:
	      sound_mix_recorded (sound, stream, len);
	      break;
	    case SOUND_SYNTH:
	      sound_mix_synth (sound, stream, len);
	      break;
	    }
	}
    }
}


static bool init_sound_inner (void)
{
  SDL_AudioSpec req_fmt;

  req_fmt.freq = SAMPLE_RATE;
  req_fmt.format = SAMPLE_TYPE;
  req_fmt.channels = 1;
  req_fmt.samples = MAX_SAMPLE;
  req_fmt.callback = sound_callback;
  req_fmt.userdata = NULL;

  if (SDL_OpenAudio (& req_fmt, & sound_v.hw_fmt) < 0)
    return false;

  SDL_PauseAudio (0);

  return true;
}


#ifdef SOUND_USE_THREAD
gpointer sound_thread_func (gpointer data UNUSED)
{
  if (! init_sound_inner ())
    {
      atomic_bool_set (& sound_v.sound_thread_error);
      return NULL;
    }

  atomic_bool_set (& sound_v.open);

  while (! atomic_bool_get (& sound_v.close_request))
    {
      g_usleep (1000000);  // delay 1 second
    }

  atomic_bool_clear (& sound_v.open);

  return NULL;
}
#endif // SOUND_USE_THREAD


bool stop_sound (int id)
{
  if (! (atomic_bool_get (& sound_v.open) &&
	 atomic_bool_get (& sound_v.enable)))
    return false;

  if ((id < 0) || (id > MAX_SOUNDS))
    return false;

  sound_info_t *sound;

  sound = & sound_v.sounds [id];
  if (! atomic_bool_get (& sound->run))
    return true;  // OK to stop a sound that isn't active

#ifdef SOUND_USE_THREAD
  atomic_bool_set (& sound->stop_request);

  while (atomic_bool_get (& sound->run))
    {
      g_usleep (50000);  // delay 0.05 second
    }
#else
  if (atomic_bool_get (& sound->run))
    {
      SDL_LockAudio ();
      atomic_bool_clear (& sound->run);
      SDL_UnlockAudio ();
    }
#endif

  if (sound->data)
    {
      if (sound->free_data_when_done)
	free (sound->data);
      sound->data = NULL;
    }

  return true;
}


void close_sound (void)
{
  int i;

  for (i = 0; i < MAX_SOUNDS; i++)
    (void) stop_sound (i);

#ifdef SOUND_USE_THREAD
  atomic_bool_set (& sound_v.close_request);

  // wait for sound thread to exit
  while (atomic_bool_get (& sound_v.open)
    {
      g_usleep (50000);  // delay 0.05 second
    }
#endif
}


bool init_sound (bool enable)
{
  if (atomic_bool_get (& sound_v.open))
    return true;

  memset (& sound_v, 0, sizeof (sound_v));
  sound_v.enable = enable;
  if (! enable)
    {
      sound_v.open = 1;
      return true;
    }

  sinewave_init ();

#if SOUND_USE_THREAD
  sound_v.thread = g_thread_create (sound_thread_func,
				    NULL,   // data
				    FALSE,  // joinable
				    NULL);  // error
  if (! sound_v.thread)
    return false;

  // wait for sound thread to return init status
  while (! atomic_bool_get (& sound_v.open))
    {
      if (atomic_bool_get (& sound_v.sound_thread_error))
	return false;
      g_usleep (50000);  // delay 0.05 second
    }
  return true;
#else
  if (! init_sound_inner ())
    return false;
  sound_v.open = 1;
  return true;
#endif
}


static int find_open_sound_slot (void)
{
  int index;
  sound_info_t *sound;

  if (! (atomic_bool_get (& sound_v.open) &&
	 atomic_bool_get (& sound_v.enable)))
    return -1;

  for (index = 0; index < MAX_SOUNDS; index++)
    {
      sound = & sound_v.sounds [index];
      if (! atomic_bool_get (& sound->run))
	break;
    }

  if (index >= MAX_SOUNDS)
    return -1;

  if (sound->data)
    {
      if (sound->free_data_when_done)
	free (sound->data);
      sound->data = NULL;
    }

  return index;
}


bool prepare_samples_from_wav_data (const uint8_t *wav_buf,
				    size_t  wav_len,
				    void    **sample_buf,
				    size_t  *sample_len)
{
  SDL_AudioCVT cvt;
  int format;
  uint8_t channels;
  int freq;

  wav_buf += 44;  // skip wave, data chunk header
  wav_len -= 44;
  // $$$ should parse header
  format = AUDIO_U8;
  channels = 1;
  freq = 22050;

  if (SDL_BuildAudioCVT (& cvt,
			 format,
			 channels,
			 freq,
			 sound_v.hw_fmt.format,
			 sound_v.hw_fmt.channels,
			 sound_v.hw_fmt.freq) < 0)
    {
      *sample_buf = NULL;
      *sample_len = 0;
      return false;
    }

  cvt.buf = alloc (wav_len * cvt.len_mult);
  cvt.len = wav_len;
  memcpy (cvt.buf, wav_buf, wav_len);

  SDL_ConvertAudio (& cvt);

  *sample_buf = cvt.buf;
  *sample_len = cvt.len * cvt.len_mult;

  return true;
}


int play_sound (void *sample_buf, size_t sample_len, bool free_data_when_done)
{
  int index;
  sound_info_t *sound;

  index = find_open_sound_slot ();

  if (index < 0)
    return index;
  sound = & sound_v.sounds [index];

  sound->type = SOUND_RECORDED;
  sound->free_data_when_done = free_data_when_done;
  sound->data = sample_buf;
  sound->len = sample_len;
  sound->pos = 0;

  atomic_bool_set (& sound->run);

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
  sound_info_t *sound;
  float inc;

  index = find_open_sound_slot ();
  if (index < 0)
    return index;
  sound = & sound_v.sounds [index];

  inc = (waveform_table_length * frequency) / SAMPLE_RATE;

  sound->type = SOUND_SYNTH;

  sound->waveform_table = waveform_table;
  sound->waveform_table_length  = waveform_table_length;
  sound->waveform_pos = 0;
  sound->waveform_inc = inc * (1 << SYNTH_FRAC_BITS) + 0.5;
  //printf ("frequency %f, inc %f, fixed point %d\n", frequency, inc, sound->waveform_inc);
  sound->waveform_amplitude = amplitude;
  sound->waveform_duration = duration * SAMPLE_RATE;

  atomic_bool_set (& sound->run);

  return index;
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
