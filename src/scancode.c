/*
$Id$
Copyright 2005 Eric L. Smith <eric@brouhaha.com>

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

#include <gdk/gdk.h>
#include <gdk/gdkkeysyms.h>

#include "scancode.h"


int get_scancode_from_name (char *scancode_name)
{
  int scancode;

  scancode = gdk_keyval_from_name (scancode_name);

  if ((scancode == 0) || (scancode == GDK_VoidSymbol))
    {
      printf ("No keyval for '%s'\n", scancode_name);
      scancode = 0;
    }

  return scancode;
}
