# ZIP distribution builder for Nonpareil
# $Id$
# Copyright 2008 Eric Smith <eric@brouhaha.com>

Import ('env')

import os.path
import zipfile

def zipdist_split (path):
    if path.endswith ('.zip'):
        return (path [0:-4], '.zip')
    return (path, '')

def zipdist_builder_fn (target, source, env):
    dir_prefix = zipdist_split (str (target [0])) [0]
    zf = zipfile.ZipFile (str (target [0]), 'w', zipfile.ZIP_DEFLATED)
    for s in source:
        s = str (s)
        # $$$ Hack alert!
        if s.startswith ('build/win32-debug/'):
            s2 = s [18:]
        elif s.startswith ('build/win32-debug/dll/'):
            s2 = s [22:]
        else:
            s2 = s
        zf.write (str (s), dir_prefix + '/' + s2)
    zf.close ()

zipdist_builder = env.Builder (action = zipdist_builder_fn,
                               suffix = '.zip',
                               multi = 1)

env.Append (BUILDERS = {'ZipDist' : zipdist_builder})
