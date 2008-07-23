# Source tarball builder for Nonpareil
# $Id$
# Copyright 2008 Eric Smith <eric@brouhaha.com>

#-----------------------------------------------------------------------------
# The compressed target tarball (with a .tar.gz suffix) will contain all
# of the sources, with their archive names prefixed by a directory named
# after the base name of the tarball.  For example, if the target is
# 'foomatron-3.6.tar.gz', the source 'src/bar/quux.c' would appear in
# the archive as 'foomatron-3.6/src/bar/quux.c'.
#
# Inspired by a source tarball builder Paul Davis posted to scons-users
# on 1-May-2005:
#
#     http://osdir.com/ml/programming.tools.scons.user/2005-03/msg00014.html
#
#  However, this builder has several advantages:
#
# * only needs one builder (Tarball), rather than two (Distribute and
#   Tarball)
#
# * doesn't need to copy the files into a temporary directory
#
# * uses the Python tarball library rather than invoking an extternal
#   tar program
#
# * compresses the tarball as appropriate based on extension 
#
# Example usage in an Sconstruct file:
#
# pkg_name = 'frobulator'
# release_ver = '1.62'
#
# env = Environment ()
#
# Export ('env')
# SConscript ('tarball.py')
#
# source_tarball = env.Tarball (pkg_name + '-' + release_ver,
#                               ['SConstruct', 'tarball.py'])
#
# sources = ['frobulator.c']
# headers = ['frobulator.h']
#
# frobulator = env.Program (sources)
#
# # add more files to the tarball
# env.Tarball (source_tarball, sources)
# env.Tarball (source_tarball, headers)
#
#-----------------------------------------------------------------------------

Import ('env')

import tarfile

tarball_extensions = { '.tar'     : '',
                       '.tar.gz'  : 'gz',
                       '.tgz'     : 'gz',
                       '.tar.bz2' : 'bz2',
                       '.tbz'     : 'bz2' }

# determine the base filename of a tarball and the suitable compression mode
def tarball_split (path):
    for extension in tarball_extensions:
        if path.endswith (extension):
            return (path [0:-len (extension)], tarball_extensions [extension])
    # if no match, use full path with no compression
    return (path, '')

def tarball_builder_fn (target, source, env):
    (dir_prefix, compression_mode) = tarball_split (str (target [0]))
    tf = tarfile.open (str (target [0]), 'w:' + compression_mode)
    for s in source:
        tf.add (str (s), dir_prefix + '/' + str (s))
    tf.close ()

tarball_builder = env.Builder (action = tarball_builder_fn,
                               suffix = '.tar.gz',
                               multi = 1)

env.Append (BUILDERS = {'Tarball' : tarball_builder})
