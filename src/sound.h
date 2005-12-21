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


#define SAMPLE_TYPE AUDIO_S16
typedef int16_t sample_t;

#define SAMPLE_MAX 32767


bool init_sound (bool enable);
void close_sound (void);


// Convert a WAV file in a memory buffer to a sample buffer and length
// for use by play_sound().  When no longer needed, the sample_buf should
// be freed with free().
bool prepare_samples_from_wav_data (const uint8_t *wav_buf,
				    size_t  wav_len,
				    void    **sample_buf,
				    size_t  *sample_len);


// Returns a non-negative integer reference number for the sound,
// or a negative value for an error condition.
int play_sound (void *sample_buf, size_t sample_len, bool free_data_when_done);


int synth_sound (float    frequency,  // Hz
		 float    amplitude,  // 0..1
		 float    duration,   // s, or zero for indefinite
		 sample_t *waveform_table,
		 uint32_t waveform_table_length);  // samples in table


bool stop_sound (int id);


extern sample_t squarewave_waveform_table [];
extern uint32_t squarewave_waveform_table_length;

extern sample_t sinewave_waveform_table [];
extern uint32_t sinewave_waveform_table_length;
