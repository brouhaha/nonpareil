/*
$Id$
Copyright 2004 Eric L. Smith <eric@brouhaha.com>

Nonpareil is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License version 2 as
published by the Free Software Foundation.  Note that I am not
granting permission to redistribute or modify Nonpareil under the
terms of any later version of the General Public License.

Nonpareil is distributed in the hope that it will be useful (or at
least amusing), but WITHOUT ANY WARRANTY; without even the implied
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See
the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program (in the file "COPYING"); if not, write to the
Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
MA 02111, USA.
*/


#define MAX_DIGIT_POSITION 15    /* Classic, Topcat, 67, maybe 19C */
/* Digit positions are numbered left to right, starting with 0. */

#define MAX_SEGMENT 18           /* 41C: 14 segment char,
                                          3 segments punctuation,
			                  1 annunciator */

/* Segments are stored as a bitmap, with the LSB being segment A.
   See comments at the end of this header file. */
typedef uint32_t segment_bitmap_t;



typedef struct display_handle_t display_handle_t;


display_handle_t *init_display (int digit_count);


typedef void display_update_fn_t (display_handle_t *display_handle,
				  int digit_count,
				  segment_bitmap_t *segments);


/* 
 * Display segments:
 *
 * For seven-segment displays, by convention the segments are labelled 'a'
 * through 'g'.  We designate the '.' and ',' as 'o' and 'p', respectively.
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
 * For fourteen-segment dsiplays, by convention the segments are labelled
 * 'a' through 'n'.  We designate '.' and ',' as 'o' and 'p', respectively.
 * The second dot for the ':' is 'q'.  For instance, see the data sheet for
 * the Noritake AH1616A 14-segment VFD, though that does not have the second
 * dot for the colon.
 *
 *     aaaaaaa
 *    fl  i  kb
 *    f l i k b
 *    f  lik  b  qq
 *     ggg hhh   qq
 *    e  njm  c
 *    e n j m c
 *    en  j  mc  oo
 *     ddddddd   oo
 *              pp
 *             pp
 *
 */
