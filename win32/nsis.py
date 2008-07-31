# NSIS distribution builder for Nonpareil
# $Id$
# Copyright 2008 Eric Smith <eric@brouhaha.com>

Import ('env')

import string
import os.path
import SCons.Errors

def remove_prefixes (s, prefix):
    for p in prefix:
        if s.startswith (p):
            s = s [len (p):]
    return s

nsis_build_prefixes = [env ['target_build_dir'] + '/',
                       'build/calc/',
                       'win32/dll/']

def nsis_target_path (p):
    if p == '':
        return '$INSTDIR'
    return '$INSTDIR\\%s' % p.replace ('/', '\\')

def nsis_write_set_out_path_cmd (fl, path):
    fl.write ('  ${SetOutPath} "%s"\n' % nsis_target_path (path))

def nsis_write_file_cmd (fl, path, spn):
    fn = os.path.split (spn) [1]
    if path == '':
        fl.write ('  ${File} "" %s %s\n' % (fn, spn))
    else:
        fl.write ('  ${File} "%s/" %s %s\n' % (path, fn, spn))

def nsis_write_file_commands (out_file, source):
    fl = open (nsis_build_prefixes [0] + out_file, 'w')
    op = ''
    nsis_write_set_out_path_cmd (fl, '');
    for sp in source:
        spn = str (sp)
        dpn = remove_prefixes (spn, nsis_build_prefixes)
        (dp, dfn) = os.path.split (dpn)
        if dp != op:
            op = dp
            nsis_write_set_out_path_cmd (fl, op);
        nsis_write_file_cmd (fl, dp, spn)
    nsis_write_set_out_path_cmd (fl, '');
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
