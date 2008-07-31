# NSIS distribution builder for Nonpareil
# $Id$
# Copyright 2008 Eric Smith <eric@brouhaha.com>

Import ('env')

import string
import SCons.Errors

def remove_prefixes (s, prefix):
    for p in prefix:
        if s.startswith (p):
            s = s [len (p):]
    return s

nsis_build_prefixes = [env ['target_build_dir'] + '/',
                       'build/calc/',
                       'win32/dll/']

def nsis_write_file_commands (out_file, source):
    fl = open (nsis_build_prefixes [0] + out_file, 'w')
    for f in source:
        fn = str (f)
        fn2 = remove_prefixes (fn, nsis_build_prefixes)
        fn2 = fn2.replace ('/', '\\');
        fl.write ("  File /oname=%s %s\n" % (fn2, fn))
    fl.close

def nsis_write_delete_commands (out_file, source):
    fl = open (nsis_build_prefixes [0] + out_file, 'w')
    for f in source:
        fn = str (f)
        fn2 = remove_prefixes (fn, nsis_build_prefixes)
        fn2 = fn2.replace ('/', '\\');
        fl.write ("  Delete %s\n" % fn2)
    fl.close

def nsis_builder_fn (target, source, env):
    nsi = None
    files = []
    for s in source:
        if str (s).endswith ('.nsi'):
            if nsi:
                raise SCons.Errors.UserError ('can only have one .nsi file among the sources for an NSIS Builder')
            nsi = s
        else:
            files += [s]
    if not nsi:
        raise SCons.Errors.UserError ('must have an .nsi file among the sources for an NSIS Builder')
    nsis_write_file_commands ('inst_file_cmds.nsh', files)
    nsis_write_delete_commands ('uninst_file_cmds.nsh', files)
    nsis_defs = { 'RELEASE' : env ['RELEASE'],
                  'BUILD_DIR' : env ['target_build_dir'] }
    nsis_cmd = 'makensis';
    for k in nsis_defs:
        nsis_cmd += ' -D%s=%s' % (k, nsis_defs [k])
    nsis_cmd += ' %s' % str (nsi)
    Execute (nsis_cmd)

nsis_builder = env.Builder (action = nsis_builder_fn,
                            multi = 1)

env.Append (BUILDERS = {'NSIS' : nsis_builder})
