# SConstruct for Nonpareil
# $Id$
# Copyright 2005 Eric L. Smith <eric@brouhaha.com>

# Nonpareil is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.  Note that I am not
# granting permission to redistribute or modify Nonpareil under the
# terms of any later version of the General Public License.

# Nonpareil is distributed in the hope that they will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program (in the file "COPYING"); if not, write to
# the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
# Boston, MA 02111, USA.

release = '0.45'  # should get from a file, and use only if a release option
                  # is specified

#-----------------------------------------------------------------------------
# Conditionals 
#-----------------------------------------------------------------------------

opts = Options ('local.py')

opts.AddOptions (EnumOption ('target',
			     help = 'execution target',
			     allowed_values = ('native', 'windows'),
			     default = 'native',
			     ignorecase = 1),

		 ('prefix',
		  'installation path prefix',
		  '/usr/local'),

		 BoolOption ('debug',
			     help = 'compile for debugging',
			     default = 1))

opts.AddOptions (BoolOption ('has_debugger',
			     help = 'has_debugger',
			     default = 0),

		 BoolOption ('has_debugger_cli',
			     help = 'has_debugger_cli',
			     default = 0),

		 BoolOption ('use_tcl',
			     help = 'use_tcl',
			     default = 1),  # only if has_debugger_cli

		 BoolOption ('use_readline',
			     help = 'use_readline',
			     default = 1))  # only if has_debugger_cli

#-----------------------------------------------------------------------------

opts.AddOptions (('PACKAGE', 'package name', 'nonpareil'),
		 ('RELEASE', 'release number', release))


env = Environment (options = opts)

if env ['target'] == 'windows':
	build_dir = 'wbuild'
else:
	build_dir = 'build'

Export('env')
SConscript('src/SConscript',
	   build_dir=build_dir,
	   duplicate=0)
#	   exports = 'env')

#-----------------------------------------------------------------------------
# Assemble ROM sources
#-----------------------------------------------------------------------------

SConscript ('asm/SConscript',
	    build_dir='obj',
	    duplicate=0)

#-----------------------------------------------------------------------------
# Install KML, image, firmware files
#-----------------------------------------------------------------------------

SConscript ('rom/SConscript')
SConscript ('kml/SConscript')
SConscript ('image/SConscript')
