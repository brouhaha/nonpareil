/*
Copyright 1995, 2003, 2004, 2005, 2008, 2022 Eric Smith spacewar@gmail.com>

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

#ifndef PROC_WOODSTOCK_EXT_FLAGS_H
#define PROC_WOODSTOCK_EXT_FLAGS_H

typedef enum
{
  // External flag outputs
  EXT_FLAG_ACT_F0,          // ACT pin 22, controlled by flag s0

  // External flag inputs
  EXT_FLAG_ACT_F1,          // ACT pin 3, affects flag s5
  EXT_FLAG_ACT_F1_COND_S0,  //   F1, but only while S0 is true
  EXT_FLAG_ACT_F1_PULSE,    //   F1, but pulsed for a single cycle

  EXT_FLAG_ACT_F2,          // ACT pin 4, affects flag s3
  EXT_FLAG_ACT_F2_COND_S0,  //   F2, but only while S0 is true
  EXT_FLAG_ACT_F2_PULSE,    //   F2, but pulsed for a single cycle

  // EXT_FLAG_ACT_KA through _KE should be consecutive
  EXT_FLAG_ACT_KA,          // ACT pin 5
  EXT_FLAG_ACT_KB,          // ACT pin 6
  EXT_FLAG_ACT_KC,          // ACT pin 7
  EXT_FLAG_ACT_KD,          // ACT pin 8
  EXT_FLAG_ACT_KE,          // ACT pin 9

  // EXT_FLAG_ACT_KA_COND_S0 through _KE_ should be consecutive
  EXT_FLAG_ACT_KA_COND_S0,  //   KA, but only while S0 is true
  EXT_FLAG_ACT_KB_COND_S0,  //   KB, but only while S0 is true
  EXT_FLAG_ACT_KC_COND_S0,  //   KC, but only while S0 is true
  EXT_FLAG_ACT_KD_COND_S0,  //   KD, but only while S0 is true
  EXT_FLAG_ACT_KE_COND_S0,  //   KE, but only while S0 is true

  EXT_FLAG_SIZE             // not an actual flag
} ext_flag_num_t;

#endif // PROC_WOODSTOCK_EXT_FLAGS_H
