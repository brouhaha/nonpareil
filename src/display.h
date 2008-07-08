/*
$Id$
Copyright 2004, 2005, 2008 Eric Smith <eric@brouhaha.com>

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


#define MAX_DIGIT_POSITION 15    /* Classic, Topcat, 67, maybe 19C */
/* Digit positions are numbered left to right, starting with 0. */

#define MAX_SEGMENT 35
// Pre-41:    8 (7 segment, 1 punctuation)
// 41C:      18 (14 segment char, 3 segments punctuation, 1 annunciator
// Voyager:   9 (7 segment, 2 punctuation)
// Dot-matrix printers: 35 (5 columns by 7 rows)

typedef uint64_t segment_bitmap_t;
// Segments are stored as a bitmap, with the LSB being segment A.
// See comments at the end of this header file.

// For dot-matrix characters, the pixel at (row, col) is stored in
// bit (row * num_cols) + col
// (zero-based coordinates)


/* 
 * Display segments:
 *
 * For seven-segment displays, by convention the segments are labeled 'a'
 * through 'g'.  We designate the '.' and ',' as 'h' and 'i', respectively.
 *
 *     aaa
 *    f   b
 *    f   b
 *    f   b
 *     ggg
 *    e   c
 *    e   c
 *    e   c  hh
 *     ddd   hh
 *          ii
 *         ii
 *
 * Not all calculators have the comma.  Some calculators, particularly the
 * classic series, put the '.' inside the seven segments, and dedicate a
 * full digit position to the radix mark.
 *
 * For fourteen-segment displays, by convention the segments are
 * labeled 'a' through 'n'.  We designate '.' and ',' as 'o' and 'p',
 * respectively.  The second dot for the ':' is 'q'.  The segment
 * designations do not match the HP 1LA4 documentation, but rather are
 * based on commercial 14-segment displays such as the Noritake
 * AH1616A 14-segment VFD (though that does not have the second dot
 * for the colon).
 *
 *     aaaaaaa
 *    fl  i  kb  qq
 *    f l i k b  qq
 *    f  lik  b
 *     ggg hhh 
 *    e  njm  c
 *    e n j m c
 *    en  j  mc  oo
 *     ddddddd   oo
 *              pp
 *             pp
 *
 */


#define SEGMENTS_PERIOD (1 << 14)
#define SEGMENTS_COMMA  ((1 << 14) | (1 << 15))
#define SEGMENTS_COLON  ((1 << 14) | (1 << 16))

#define SEGMENT_ANN (1 << 17)
