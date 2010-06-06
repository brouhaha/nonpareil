# SConstruct for Nonpareil
# $Id$
# Copyright 2004, 2005, 2006, 2008 Eric Smith <eric@brouhaha.com>

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

#-----------------------------------------------------------------------------
# Release number
#-----------------------------------------------------------------------------

release_major = '0'
release_minor = '79'

#-----------------------------------------------------------------------------
# Options
#-----------------------------------------------------------------------------

conf_file = 'nonpareil.conf'

vars = Variables (conf_file)

vars.AddVariables (EnumVariable ('target',
                                 help = 'execution target platform',
                                 allowed_values = ('posix', 'win32'),
                                 default = 'posix',
                                 ignorecase = 1),

                   PathVariable ('prefix',
                                 'installation path prefix',
                                 '/usr/local'),

                   PathVariable ('bindir',
                                 'path for executable files (default is $prefix/bin)',
                                 '',
                                 PathVariable.PathAccept),

                   PathVariable ('libdir',
                                 'path for library files (default is $prefix/lib/nonpareil)',
                                 '',
                                 PathVariable.PathAccept),

                   PathVariable ('destdir',
                                 'installation virtual root directory (for packaging)',
                                 '',
                                 PathVariable.PathAccept),

                   BoolVariable ('debug',
                                 help = 'compile for debugging',
                                 default = 1),

		 # Feature switches:

                   BoolVariable ('has_debugger_gui',
                                 help = 'enable debugger GUI interface',
                                 default = 0),

                   BoolVariable ('has_debugger_cli',
                                 help = 'enable debugger command-line interface',
                                 default = 0),

                   BoolVariable ('use_tcl',
                                 help = 'use Tcl as debug command interpreter (only when debugger CLI is enabled)',
                                 default = 1),  # only if has_debugger_cli

                   BoolVariable ('use_readline',
                                 help = 'use Readline library for command editing and history (only when debugger CLI is enabled)',
                                 default = 1))  # only if has_debugger_cli

#-----------------------------------------------------------------------------
# Cache options
#-----------------------------------------------------------------------------

env = Environment (variables = vars)
vars.Update (env)
vars.Save (conf_file, env)

#-----------------------------------------------------------------------------
# Generate help text from options
#-----------------------------------------------------------------------------

Help (vars.GenerateHelpText (env))

#-----------------------------------------------------------------------------
# More defaults and variable settings
#-----------------------------------------------------------------------------

# Don't scatter .sconsign files everywhere, and especially don't put them
# into install directories.
SConsignFile ()

release = release_major + '.' + release_minor
env ['RELEASE'] = release
Export ('env')

#-----------------------------------------------------------------------------
# Add some builders to the environment:
#-----------------------------------------------------------------------------
import sys
import os

SConscript ('scons/nui.py')
SConscript ('scons/tarball.py')
SConscript ('scons/zipdist.py')

#-----------------------------------------------------------------------------
# package a release source tarball
#-----------------------------------------------------------------------------

bin_dist_files = Split ("""README COPYING CREDITS""")

src_dist_files = Split ("""INSTALL DEBUGGING TODO SConstruct""")

source_release_tarball = env.Tarball ('nonpareil-' + release + '.tar.gz',
                                      bin_dist_files + src_dist_files)

env ['source_release_tarball'] = source_release_tarball

env.Alias ('srcdist', source_release_tarball)

#-----------------------------------------------------------------------------
# package a source snapshot tarball
#-----------------------------------------------------------------------------

import time

snap_date = time.strftime ("%Y.%m.%d")

source_snapshot_tarball = env.Tarball ('nonpareil-' + snap_date + '.tar.gz',
                                       bin_dist_files + src_dist_files)

env ['source_snapshot_tarball'] = source_snapshot_tarball

env.Alias ('srcsnap', source_snapshot_tarball)

#-----------------------------------------------------------------------------
# package a Windows binary distribution ZIP file
#-----------------------------------------------------------------------------

if env ['target'] == 'win32':
    dist_zip_file = env.ZipDist ('nonpareil-' + release + '.zip',
				 bin_dist_files)
    env ['dist_zip_file'] = dist_zip_file
    env.Alias ('dist', dist_zip_file)

#-----------------------------------------------------------------------------
# Installation paths
#-----------------------------------------------------------------------------

if not env ['bindir']:
	env ['bindir'] = env ['prefix'] + '/bin'

if not env ['libdir']:
	env ['libdir'] = env ['prefix'] + '/lib/nonpareil'

#-----------------------------------------------------------------------------
# Prepare for SConscription
#-----------------------------------------------------------------------------

source_release_dir = 'foo'  # $$$ get rid of this!
snapshot_dir = 'foo'  # $$$ get rid of this!

Export ('source_release_dir snapshot_dir')

host_build_dir = 'build/' + env ['PLATFORM']
target_build_dir = 'build/' + env ['target']

if env ['debug']:
	host_build_dir += '-debug'
	target_build_dir += '-debug'

env ['target_build_dir'] = target_build_dir

#-----------------------------------------------------------------------------
# package a Windows installer
#-----------------------------------------------------------------------------

if env ['target'] == 'win32':
    SConscript ('win32/nsis.py')

    win32_nsis_installer_fn = target_build_dir + '/Nonpareil-' + release + '-setup.exe'
    win32_nsis_installer = env.NSIS (win32_nsis_installer_fn,
                                     bin_dist_files)
    env ['win32_nsis_installer'] = win32_nsis_installer
    env.Alias ('wininst', win32_nsis_installer)

#-----------------------------------------------------------------------------
# sound files
#-----------------------------------------------------------------------------

SConscript ('sound/SConscript')

env.Append (GPLv2 = File ('LICENSES/GPL-2.txt'))

#-----------------------------------------------------------------------------
# host platform code
#-----------------------------------------------------------------------------

env.Append (KML_41CV = File ('nui/nut/41c/41cv.kml'))

native_env = env.Clone ()
native_env ['build_target_only'] = 0
SConscript ('src/SConscript',
            build_dir = host_build_dir,
            duplicate = 0,
	    exports = {'build_env' : native_env,
		       'native_env' : env})

#-----------------------------------------------------------------------------
# Add more builders to the environment:
#-----------------------------------------------------------------------------

SConscript ('scons/uasm.py')
SConscript ('scons/ncd.py')

#-----------------------------------------------------------------------------
# the calculators
#-----------------------------------------------------------------------------

all_calcs = {'classic':    ['35', '45', '55', '67', '80'],
             'woodstock':  ['21', '22', '25', '27', '29c'],
             'sting':      ['19c'],
             'topcat':     ['97'],
	     'spice':      ['32e', '33c', '34c', '37e', '38c', '38e'],
	     'nut':        ['41c', '41cv', '41cx'],
	     'voyager':    ['11c', '12c', '15c', '16c']
	     }

ncd_dir_sub = {'19c':  '19c-29c',
               '25':   '25-25c',
	       '25c':  '25-25c',
               '29c':  '19c-29c',
	       '41cv': '41c',
	       '41cx': '41c',
	       '67':   '67-97',
	       '97':   '67-97'}

nui_dir_sub = {'41cv': '41c',
               '41cx': '41c',
	       '55':   None,
	       '80':   None}

nui_files = []
ncd_files = []

for family in all_calcs:
    for model in all_calcs [family]:
        if model in ncd_dir_sub:
            ncd_dir = ncd_dir_sub [model]
        else:
            ncd_dir = model
        ncd_files += env.NCD (target = 'build/calc/' + model + '.ncd',
                              source = 'ncd/' + ncd_dir + '/' + model + '.ncd.tmpl')

        nui_dir = 'nui/' + family + '/'
        if model in nui_dir_sub:
	    if nui_dir_sub [model] == None:
	        continue
            nui_dir += nui_dir_sub [model]
        else:
            nui_dir += model;
        kml = FindFile (model + '.kml', nui_dir)
	# parse kml to find ROM, image files, etc.
        nui_files += env.NUI (target = 'build/calc/' + model + '.nui',
                              source = nui_dir + '/' + model + '.kml')

Default (ncd_files + nui_files)

env.Alias (target = 'install',
           source = env.Install (dir = env ['destdir'] + env ['libdir'],
                                 source = ncd_files + nui_files))

if env ['target'] == 'win32':
    env.NSIS (win32_nsis_installer, ncd_files + nui_files)

def leaf_dependencies (nodes, abs_launch_dir):
    ld = []
    for node in nodes:
    	if not os.path.abspath (str (node)).startswith (abs_launch_dir):
            continue
        if not node.is_derived ():
            ld += [node]
        ld += leaf_dependencies (node.all_children (), abs_launch_dir)
    return ld

# The source tarballs need to contain the dependencies of the NCD and NUI
# targets.
ncd_ld = leaf_dependencies (ncd_files, os.path.abspath (env.GetLaunchDir ()))
nui_ld = leaf_dependencies (nui_files, os.path.abspath (env.GetLaunchDir ()))
env.Tarball (source_release_tarball,  ncd_ld + nui_ld)
env.Tarball (source_snapshot_tarball, ncd_ld + nui_ld)


#-----------------------------------------------------------------------------
# target platform code if cross-compiling
#-----------------------------------------------------------------------------

if (env ['PLATFORM'] != env ['target']):
	cross_build_env = env.Clone ()
	cross_build_env ['build_target_only'] = 1
	SConscript ('src/SConscript',
		    build_dir = target_build_dir,
		    duplicate = 0,
		    exports = {'build_env': cross_build_env,
			       'native_env' : env})

#-----------------------------------------------------------------------------
# SCons builders
#-----------------------------------------------------------------------------

SConscript ('scons/SConscript')

#-----------------------------------------------------------------------------
# Licenses, DTDs, and documentation
#-----------------------------------------------------------------------------

SConscript ('LICENSES/SConscript')
SConscript ('dtd/SConscript')
SConscript ('doc/SConscript')

#-----------------------------------------------------------------------------
# Windows
#-----------------------------------------------------------------------------

if env ['target'] == 'win32':
    SConscript ('win32/dll/SConscript',
                build_dir = target_build_dir + '/win32/dll',
                duplicate = 0)

    SConscript ('win32/SConscript')
