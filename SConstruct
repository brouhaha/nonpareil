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

params = {}

#-----------------------------------------------------------------------------
# Conditionals 
#-----------------------------------------------------------------------------

params['has_debugger'] = 1
params['has_debugger_cli'] = 1
params['use_tcl'] = 1
params['use_readline'] = 1


#-----------------------------------------------------------------------------

params['package'] = "nonpareil"
params['release'] = "0.45"

common_cflags = ['-g', '-Wall']

n_env = Environment (CFLAGS = common_cflags,
		     CPPPATH= ['.'])

w_env = Environment (CCFLAGS = common_cflags + ['-mms-bitfields', '-DSHAPE_DEFAULT=false'],
		     CPPPATH=['.'],
                     CC = '/usr/local/mingw/bin/i586-mingw32-gcc')

builds = [('linux',   n_env, 'build')]
# builds += [('windows', w_env, 'wbuild')]

for arch,env,builddir in builds:
	params['arch'] = arch
	Export('env params')
	SConscript('src/SConscript', build_dir=builddir, duplicate=0)

#-----------------------------------------------------------------------------
# Assemble ROM sources
#-----------------------------------------------------------------------------

SConscript ('asm/SConscript', build_dir='obj', duplicate=0)

#-----------------------------------------------------------------------------
# Install
#-----------------------------------------------------------------------------

prefix = "/usr/local"

n_env.Alias (target = 'install',
             source = n_env.Install (dir = prefix + "/bin",
                                     source = "build/uasm"))

n_env.Alias (target = 'install',
             source = n_env.Install (dir = prefix + "/bin",
                                     source = "build/nonpareil"))

# $$$ Need to install KML and image files as well.
