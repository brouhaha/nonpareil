# SConstruct for Nonpareil
# $Id$
# Copyright 2004 Eric L. Smith <eric@brouhaha.com>

# Nonpareil is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.  Note that I am not
# granting permission to redistribute or modify Nonpareil under the
# terms of any later version of the General Public License.

# Nonpareil is distributed in the hope that they will be useful (or at
# least amusing), but WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program (in the file "COPYING"); if not, write to
# the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
# Boston, MA 02111, USA.


env = Environment ()
env ['YACCFLAGS'] = [ '-d', '-v' ]

env.ParseConfig('pkg-config --cflags --libs gtk+-2.0 gdk-2.0 gdk-pixbuf-2.0 glib-2.0 gthread-2.0')

uasm_srcs = Split ("""asm.c symtab.c util.c
                      arch.c
            	      asml.l asmy.y
                      casml.l casmy.y
                      wasml.l wasmy.y""")

nonpareil_srcs = Split ("""csim.c util.c proc.c kmll.l kmly.y kml.c
                           arch.c platform.c model.c
                           proc_classic.c
                           proc_woodstock.c dis_woodstock.c
                           proc_nut.c dis_nut.c coconut_lcd.c voyager_lcd.c""")

uasm = env.Program (target='uasm', source=uasm_srcs)

nonpareil = env.Program (target='nonpareil', source=nonpareil_srcs)

Default ([uasm, nonpareil])
