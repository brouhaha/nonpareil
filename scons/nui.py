# SConstruct KML file scanner and NUI file builder for Nonpareil
# $Id$
# Copyright 2006 Eric L. Smith <eric@brouhaha.com>

Import ('env')

import os.path
import re
import zipfile

def unique (list):
    d = {}
    for i in list:
        d [i] = 0
    return d.keys ()

image_re = re.compile (r'image\s+"(\S+)"', re.M)

def kml_scanner_fn (node, env, path):
    contents = node.get_contents ()
    images = image_re.findall (contents)
    nui_files = unique (images)
    fl = []
    for f in nui_files:
        kpath = os.path.dirname (str (node))
        while kpath:
            f1 = kpath + '/' + f
            if os.path.exists (f1):
                fl.append (env.File (f1))
                break
            else:
                kpath = os.path.dirname (kpath)
        else:
            f1 = 'build/' + os.path.dirname (str (node)) + '/' + f
            fl.append (env.File (f1))
    return fl


kml_scanner = env.Scanner (function = kml_scanner_fn,
                           skeys = ['.kml'])


# The following tries to figure out how to build a target file based on
# its extension and the available builders.

# It attempts to determine the source directory that the build
# directory builds from.  Ideally we would find that out from the
# mapping of build_dir to src_dir established by SConscript(), but I
# haven't yet figured out how to extract that.  For Nonpareil, the
# build dir for foo/bar is build/foo/bar, so we just remove the first
# component of the path.

def try_to_build (target_fn, env):
    target_path_and_base, target_suffix = os.path.splitext (target_fn)
    target_path, target_base = os.path.split (target_path_and_base)
    # if the target_fn is in the source tree (not the build tree), we're done
    if target_path [0:6] != 'build/':
        return os.path.exists (target_fn);
    builder_list = env ['BUILDERS']
    for builder_name in builder_list.keys():
        builder = builder_list [builder_name]
        if target_suffix in builder.suffix:
            for src_suffix in builder.src_suffix:
                src_path = target_path.split ('/', 1) [1]
                src_fn = src_path + '/' + target_base + src_suffix
                if os.path.exists (src_fn):
                    builder.__call__ (target = target_fn,
                                      source = src_fn,
                                      env = env,
                                      for_signature = False)
                    return True
                src_fn = target_path + '/' + target_base + src_suffix
                if try_to_build (src_fn, env):
                    builder.__call__ (target = target_fn,
                                      source = src_fn,
                                      env = env,
                                      for_signature = False)
    return False
                

def nui_emitter_fn (target, source, env):
    extra_files = kml_scanner_fn (source [0], env, None)
    fnl = []
    for f in extra_files:
        fn = str (f)
        try_to_build (fn, env)
        fnl.append (fn)
    return (target, source + fnl)


def nui_action_fn (target, source, env):
    zf = zipfile.ZipFile (str (target [0]), 'w', zipfile.ZIP_DEFLATED)
    for s in source:
        zf.write (str (s), os.path.basename (str (s)))
    zf.close ()

nui_builder = env.Builder (action = env.Action (nui_action_fn),
			   src_suffix = '.kml',
			   source_scanner = kml_scanner,
                           suffix = '.nui',
                           emitter = nui_emitter_fn)

env.Append (BUILDERS = {'NUI' : nui_builder})

