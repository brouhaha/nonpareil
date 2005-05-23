# SConstruct for Nonpareil
# $Id$
# Copyright 2004, 2005 Eric L. Smith <eric@brouhaha.com>

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

release = '0.67'  # should get from a file, and use only if a release option
                  # is specified

conf_file = 'nonpareil.conf'

#-----------------------------------------------------------------------------
# Options
#-----------------------------------------------------------------------------

opts = Options (conf_file)

opts.AddOptions (EnumOption ('target',
			     help = 'execution target',
			     allowed_values = ('native', 'windows'),
			     default = 'native',
			     ignorecase = 1),

		 PathOption ('prefix',
			     'installation path prefix',
			     '/usr/local'),

		 # Don't use PathOption for other paths, because we don't
		 # require the directories to preexist.
		 ('bindir',
		  'path for executable files (default is $prefix/bin)',
		  ''),

		 ('libdir',
		  'path for library files (default is $prefix/lib/nonpareil)',
		  ''),

		 ('destdir',
		  'installation virtual root directory (for packaging)',
		  ''),

		 BoolOption ('debug',
			     help = 'compile for debugging',
			     default = 1),

		 # Feature switches:

		 BoolOption ('has_debugger_gui',
			     help = 'enable debugger GUI interface',
			     default = 0),

		 BoolOption ('has_debugger_cli',
			     help = 'enable debugger command-line interface',
			     default = 0),

		 BoolOption ('use_tcl',
			     help = 'use Tcl as debug command interpreter (only when debugger CLI is enabled)',
			     default = 1),  # only if has_debugger_cli

		 BoolOption ('use_readline',
			     help = 'use Readline library for command editing and history (only when debugger CLI is enabled)',
			     default = 1))  # only if has_debugger_cli

#-----------------------------------------------------------------------------
# Cache options
#-----------------------------------------------------------------------------

env = Environment (options = opts)
opts.Update (env)
opts.Save (conf_file, env)

#-----------------------------------------------------------------------------
# Generate help text from options
#-----------------------------------------------------------------------------

Help (opts.GenerateHelpText (env))

#-----------------------------------------------------------------------------
# More defaults and variable settings
#-----------------------------------------------------------------------------

# Don't scatter .sconsign files everywhere, and especially don't put them
# into install directories.
SConsignFile ()

env ['RELEASE'] = release

if env ['target'] == 'windows':
	build_dir = 'wbuild'
else:
	build_dir = 'build'

if not env ['bindir']:
	env ['bindir'] = env ['prefix'] + '/bin'

if not env ['libdir']:
	env ['libdir'] = env ['prefix'] + '/lib/nonpareil'

#-----------------------------------------------------------------------------
# Source tar file builder by Paul Davis
# Posted to scons-users on 1-May-2005
# Changed to use "-z" option to tar rather than "-j", to get gzip output.
# Removed the exclude of '*~' (emacs backup files), not needed since we
# explicitly list exactly what files we want packaged.
#-----------------------------------------------------------------------------

import os, errno, time, SCons

def distcopy (target, source, env):
    treedir = str (target[0])

    try:
        os.mkdir (treedir)
    except OSError, (errnum, strerror):
        if errnum != errno.EEXIST:
            print 'mkdir ', treedir, ':', strerror

    cmd = 'tar cf - '
    #
    # we don't know what characters might be in the file names
    # so quote them all before passing them to the shell
    #
    all_files = ([ str(s) for s in source ])
    cmd += " ".join ([ "'%s'" % quoted for quoted in all_files])
    cmd += ' | (cd ' + treedir + ' && tar xf -)'
    p = os.popen (cmd)
    return p.close ();

def tarballer (target, source, env):            
    cmd = 'tar -czf ' + str (target[0]) +  ' ' + str(source[0])
    print 'running ', cmd, ' ... '
    p = os.popen (cmd)
    return p.close ()

dist_bld = Builder (action = distcopy,
                    target_factory = SCons.Node.FS.default_fs.Entry,
                    source_factory = SCons.Node.FS.default_fs.Entry,
                    multi = 1)

tarball_bld = Builder (action = tarballer,
                       target_factory = SCons.Node.FS.default_fs.Entry,
                       source_factory = SCons.Node.FS.default_fs.Entry)

env.Append (BUILDERS = {'Distribute' : dist_bld})
env.Append (BUILDERS = {'Tarball' : tarball_bld})

#-----------------------------------------------------------------------------
# package a release source tarball
#-----------------------------------------------------------------------------

files = Split ("""README COPYING INSTALL DEBUGGING TODO SConstruct""")

source_release_dir = env.Distribute ('nonpareil-' + release, files)

# Not only does this preaction not work, it causes the files from the root
# directory to not get included in the release!
# env.AddPreAction (source_release_dir, Delete (source_release_dir))

source_release_tarball = env.Tarball ('nonpareil-' + release + '.tar.gz',
                                      source_release_dir)

env.Alias ('dist', source_release_tarball)

env.AddPostAction (source_release_tarball, Delete (source_release_dir))

#-----------------------------------------------------------------------------
# package a source snapshot tarball
#-----------------------------------------------------------------------------

snap_date = time.strftime ("%Y.%m.%d")

snapshot_dir = env.Distribute ('nonpareil-' + snap_date, files)

# Not only does this preaction not work, it causes the files from the root
# directory to not get included in the snapshot!
# env.AddPreAction (snapshot_dir, Delete (snapshot_dir))

snapshot_tarball = env.Tarball ('nonpareil-' + snap_date + '.tar.gz',
                                snapshot_dir)

env.Alias ('snap', snapshot_tarball)

env.AddPostAction (snapshot_tarball, Delete (snapshot_dir))

#-----------------------------------------------------------------------------
# code
#-----------------------------------------------------------------------------

Export ('env source_release_dir snapshot_dir')

SConscript ('src/SConscript',
            build_dir=build_dir,
            duplicate=0)

#-----------------------------------------------------------------------------
# ROM sources
#-----------------------------------------------------------------------------

SConscript ('asm/SConscript',
	    build_dir='obj',
	    duplicate=0)

#-----------------------------------------------------------------------------
# KML, image, firmware files
#-----------------------------------------------------------------------------

SConscript ('rom/SConscript')
SConscript ('kml/SConscript')
SConscript ('image/SConscript')

#-----------------------------------------------------------------------------
# documentation
#-----------------------------------------------------------------------------

SConscript ('doc/SConscript')

#-----------------------------------------------------------------------------
# scons-local, in case the user doesn't want to install scons
#-----------------------------------------------------------------------------

SConscript ('scons-local/SConscript')
