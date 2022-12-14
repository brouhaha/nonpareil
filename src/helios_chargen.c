/*
$Id$
Copyright 1995, 2005, 2008, 2010 Eric Smith <eric@brouhaha.com>

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
#include <stdio.h>

#include "arch.h"
#include "util.h"
#include "display.h"
#include "keyboard.h"
#include "chip.h"
#include "calcdef.h"
#include "proc.h"
#include "helios.h"


uint8_t helios_chargen [128][5] =
{
  [0x00] = { 0x08, 0x1c, 0x3e, 0x1c, 0x08 },  // undefined - use diamond
  [0x01] = { 0x00, 0x14, 0x08, 0x14, 0x00 },  // small x
  [0x02] = { 0x44, 0x29, 0x11, 0x29, 0x44 },  // x-bar
  [0x03] = { 0x08, 0x1c, 0x2a, 0x08, 0x08 },  // left arrow
  [0x04] = { 0x38, 0x44, 0x44, 0x38, 0x44 },  // LC alpha
  [0x05] = { 0x7e, 0x15, 0x25, 0x25, 0x1a },  // UC beta
  [0x06] = { 0x7f, 0x01, 0x01, 0x01, 0x03 },  // UC gamma
  [0x07] = { 0x10, 0x30, 0x7f, 0x30, 0x10 },  // down arrow
  [0x08] = { 0x60, 0x18, 0x06, 0x18, 0x60 },  // UC delta
  [0x09] = { 0x38, 0x44, 0x44, 0x3c, 0x04 },  // LC sigma
  [0x0a] = { 0x08, 0x1c, 0x3e, 0x1c, 0x08 },  // diamond
  [0x0b] = { 0x62, 0x14, 0x08, 0x10, 0x60 },  // LC lambda
  [0x0c] = { 0x40, 0x3c, 0x20, 0x20, 0x1c },  // LC mu
  [0x0d] = { 0x60, 0x50, 0x58, 0x64, 0x42 },  // angle
  [0x0e] = { 0x10, 0x18, 0x78, 0x04, 0x02 },  // LC tau
  [0x0f] = { 0x08, 0x55, 0x77, 0x55, 0x08 },  // UC phi
  [0x10] = { 0x3e, 0x49, 0x49, 0x49, 0x3e },  // UC theta
  [0x11] = { 0x5e, 0x61, 0x01, 0x61, 0x5e },  // UC omega
  [0x12] = { 0x30, 0x4a, 0x4d, 0x49, 0x30 },  // LC delta
  [0x13] = { 0x78, 0x14, 0x15, 0x14, 0x78 },  // UC A dot
  [0x14] = { 0x38, 0x44, 0x45, 0x3e, 0x44 },  // LC a dot
  [0x15] = { 0x78, 0x15, 0x14, 0x15, 0x78 },  // UC A umlaut
  [0x16] = { 0x38, 0x45, 0x44, 0x7d, 0x40 },  // LC a umlaut
  [0x17] = { 0x3c, 0x43, 0x42, 0x43, 0x3c },  // UC O umlaut
  [0x18] = { 0x38, 0x45, 0x44, 0x45, 0x38 },  // LC o umlaut
  [0x19] = { 0x3e, 0x41, 0x40, 0x41, 0x3e },  // UC U umlaut
  [0x1a] = { 0x3c, 0x41, 0x40, 0x41, 0x3c },  // LC u umlaut
  [0x1b] = { 0x7e, 0x09, 0x7f, 0x49, 0x49 },  // UC AE
  [0x1c] = { 0x38, 0x44, 0x38, 0x54, 0x58 },  // LC ae
  [0x1d] = { 0x14, 0x34, 0x1c, 0x16, 0x14 },  // not equal
  [0x1e] = { 0x48, 0x7e, 0x49, 0x41, 0x22 },  // pound sterling
  [0x1f] = { 0x55, 0x2a, 0x55, 0x2a, 0x55 },  // ?
  [0x20] = { 0x00, 0x00, 0x00, 0x00, 0x00 },  // space
  [0x21] = { 0x00, 0x00, 0x5f, 0x00, 0x00 },  // bang
  [0x22] = { 0x00, 0x03, 0x00, 0x03, 0x00 },  // double quote
  [0x23] = { 0x14, 0x7f, 0x14, 0x7f, 0x14 },  // hash (pound, octothorpe)
  [0x24] = { 0x24, 0x2a, 0x7f, 0x2a, 0x12 },  // dollar
  [0x25] = { 0x23, 0x13, 0x08, 0x64, 0x62 },  // percent
  [0x26] = { 0x36, 0x49, 0x56, 0x20, 0x50 },  // ampersand
  [0x27] = { 0x00, 0x00, 0x03, 0x00, 0x00 },  // single quote
  [0x28] = { 0x00, 0x1c, 0x22, 0x41, 0x00 },  // left parenthesis
  [0x29] = { 0x00, 0x41, 0x22, 0x1c, 0x00 },  // right parenthesis
  [0x2a] = { 0x14, 0x08, 0x3e, 0x08, 0x14 },  // asterisk
  [0x2b] = { 0x08, 0x08, 0x3e, 0x08, 0x08 },  // plus
  [0x2c] = { 0x00, 0x40, 0x30, 0x00, 0x00 },  // comma
  [0x2d] = { 0x08, 0x08, 0x08, 0x08, 0x08 },  // hyphen
  [0x2e] = { 0x00, 0x60, 0x60, 0x00, 0x00 },  // period
  [0x2f] = { 0x20, 0x10, 0x08, 0x04, 0x02 },  // slash
  [0x30] = { 0x3e, 0x51, 0x49, 0x45, 0x3e },  // zero
  [0x31] = { 0x00, 0x42, 0x7e, 0x40, 0x00 },  // one
  [0x32] = { 0x62, 0x51, 0x49, 0x49, 0x46 },  // two
  [0x33] = { 0x21, 0x41, 0x49, 0x4d, 0x33 },  // three
  [0x34] = { 0x18, 0x14, 0x12, 0x7f, 0x10 },  // four
  [0x35] = { 0x27, 0x45, 0x45, 0x45, 0x39 },  // five
  [0x36] = { 0x3c, 0x4a, 0x49, 0x48, 0x30 },  // six
  [0x37] = { 0x01, 0x71, 0x09, 0x05, 0x03 },  // seven
  [0x38] = { 0x36, 0x49, 0x49, 0x49, 0x36 },  // eight
  [0x39] = { 0x06, 0x49, 0x49, 0x29, 0x1e },  // nine
  [0x3a] = { 0x00, 0x00, 0x24, 0x00, 0x00 },  // colon
  [0x3b] = { 0x00, 0x40, 0x34, 0x00, 0x00 },  // semicolon
  [0x3c] = { 0x08, 0x14, 0x22, 0x41, 0x00 },  // less than
  [0x3d] = { 0x14, 0x14, 0x14, 0x14, 0x14 },  // equal
  [0x3e] = { 0x00, 0x41, 0x22, 0x14, 0x08 },  // greater than
  [0x3f] = { 0x02, 0x01, 0x51, 0x09, 0x06 },  // question mark
  [0x40] = { 0x3e, 0x41, 0x5d, 0x5d, 0x1e },  // at
  [0x41] = { 0x7e, 0x11, 0x11, 0x11, 0x7e },  // UC A
  [0x42] = { 0x7f, 0x49, 0x49, 0x49, 0x36 },  // UC B
  [0x43] = { 0x3e, 0x41, 0x41, 0x41, 0x22 },  // UC C
  [0x44] = { 0x41, 0x7f, 0x41, 0x41, 0x3e },  // UC D
  [0x45] = { 0x7f, 0x49, 0x49, 0x49, 0x41 },  // UC E
  [0x46] = { 0x7f, 0x09, 0x09, 0x09, 0x01 },  // UC F
  [0x47] = { 0x3e, 0x41, 0x41, 0x51, 0x72 },  // UC G
  [0x48] = { 0x7f, 0x08, 0x08, 0x08, 0x7f },  // UC H
  [0x49] = { 0x00, 0x41, 0x7f, 0x41, 0x00 },  // UC I
  [0x4a] = { 0x20, 0x40, 0x40, 0x3f, 0x00 },  // UC J
  [0x4b] = { 0x7f, 0x08, 0x14, 0x22, 0x41 },  // UC K
  [0x4c] = { 0x7f, 0x40, 0x40, 0x40, 0x40 },  // UC L
  [0x4d] = { 0x7f, 0x02, 0x0c, 0x02, 0x7f },  // UC M
  [0x4e] = { 0x7f, 0x04, 0x08, 0x10, 0x7f },  // UC N
  [0x4f] = { 0x3e, 0x41, 0x41, 0x41, 0x3e },  // UC O
  [0x50] = { 0x7f, 0x09, 0x09, 0x09, 0x06 },  // UC P
  [0x51] = { 0x3e, 0x41, 0x51, 0x21, 0x5e },  // UC Q
  [0x52] = { 0x7f, 0x09, 0x19, 0x29, 0x46 },  // UC R
  [0x53] = { 0x26, 0x49, 0x49, 0x49, 0x32 },  // UC S
  [0x54] = { 0x01, 0x01, 0x7f, 0x01, 0x01 },  // UC T
  [0x55] = { 0x3f, 0x40, 0x40, 0x40, 0x3f },  // UC U
  [0x56] = { 0x07, 0x18, 0x60, 0x18, 0x07 },  // UC V
  [0x57] = { 0x7f, 0x20, 0x18, 0x20, 0x7f },  // UC W
  [0x58] = { 0x63, 0x14, 0x08, 0x14, 0x63 },  // UC X
  [0x59] = { 0x03, 0x04, 0x78, 0x04, 0x03 },  // UC Y
  [0x5a] = { 0x61, 0x51, 0x49, 0x45, 0x43 },  // UC Z
  [0x5b] = { 0x00, 0x7f, 0x41, 0x41, 0x00 },  // left bracket
  [0x5c] = { 0x02, 0x04, 0x08, 0x10, 0x20 },  // backslash
  [0x5d] = { 0x00, 0x41, 0x41, 0x7f, 0x00 },  // right bracket
  [0x5e] = { 0x04, 0x02, 0x7f, 0x02, 0x04 },  // up arrow
  [0x5f] = { 0x40, 0x40, 0x40, 0x40, 0x40 },  // underscore
  [0x60] = { 0x00, 0x01, 0x07, 0x01, 0x00 },  // superscript T
  [0x61] = { 0x20, 0x54, 0x54, 0x54, 0x78 },  // LC a
  [0x62] = { 0x7f, 0x48, 0x44, 0x44, 0x38 },  // LC b
  [0x63] = { 0x38, 0x44, 0x44, 0x44, 0x20 },  // LC c
  [0x64] = { 0x38, 0x44, 0x44, 0x48, 0x7f },  // LC d
  [0x65] = { 0x38, 0x54, 0x54, 0x54, 0x08 },  // LC e
  [0x66] = { 0x08, 0x7c, 0x0a, 0x01, 0x02 },  // LC f
  [0x67] = { 0x08, 0x14, 0x54, 0x54, 0x38 },  // LC g
  [0x68] = { 0x7f, 0x10, 0x08, 0x08, 0x70 },  // LC h
  [0x69] = { 0x00, 0x44, 0x7d, 0x40, 0x00 },  // LC i
  [0x6a] = { 0x20, 0x40, 0x40, 0x3d, 0x00 },  // LC j
  [0x6b] = { 0x00, 0x7f, 0x28, 0x44, 0x00 },  // LC k
  [0x6c] = { 0x00, 0x41, 0x7f, 0x40, 0x00 },  // LC l
  [0x6d] = { 0x78, 0x04, 0x18, 0x04, 0x78 },  // LC m
  [0x6e] = { 0x7c, 0x08, 0x04, 0x04, 0x78 },  // LC n
  [0x6f] = { 0x38, 0x44, 0x44, 0x44, 0x38 },  // LC o
  [0x70] = { 0x7c, 0x14, 0x24, 0x24, 0x18 },  // LC p
  [0x71] = { 0x18, 0x24, 0x24, 0x7c, 0x40 },  // LC q
  [0x72] = { 0x7c, 0x08, 0x04, 0x04, 0x08 },  // LC r
  [0x73] = { 0x48, 0x54, 0x54, 0x54, 0x24 },  // LC s
  [0x74] = { 0x04, 0x3e, 0x44, 0x20, 0x00 },  // LC t
  [0x75] = { 0x3c, 0x40, 0x40, 0x20, 0x7c },  // LC u
  [0x76] = { 0x1c, 0x20, 0x40, 0x20, 0x1c },  // LC v
  [0x77] = { 0x3c, 0x40, 0x30, 0x40, 0x3c },  // LC w
  [0x78] = { 0x44, 0x28, 0x10, 0x28, 0x44 },  // LC x
  [0x79] = { 0x44, 0x28, 0x10, 0x08, 0x04 },  // LC y
  [0x7a] = { 0x44, 0x64, 0x54, 0x4c, 0x44 },  // LC z
  [0x7b] = { 0x08, 0x78, 0x08, 0x78, 0x04 },  // LC pi
  [0x7c] = { 0x00, 0x00, 0x7f, 0x00, 0x00 },  // vertical bar
  [0x7d] = { 0x08, 0x08, 0x2a, 0x1c, 0x08 },  // right arrow
  [0x7e] = { 0x63, 0x55, 0x49, 0x41, 0x63 },  // UC sigma
  [0x7f] = { 0x7f, 0x08, 0x08, 0x08, 0x08 },  // lazy T
};
