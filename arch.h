/*
arch.h
$Id$
Copyright 2004 Eric L. Smith

Nonpareil is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License version 2 as
published by the Free Software Foundation.  Note that I am not
granting permission to redistribute or modify CASM under the terms of
any later version of the General Public License.

This program is distributed in the hope that it will be useful (or at least
amusing), but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with
this program (in the file "COPYING"); if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/


#define ARCH_UNKNOWN   0
#define ARCH_CLASSIC   1
#define ARCH_WOODSTOCK 2
#define ARCH_CRICKET   3
#define ARCH_NUT       4
#define ARCH_CAPRICORN 5
#define ARCH_SATURN    6

#define ARCH_MAX       7

extern char *arch_name [ARCH_MAX];
