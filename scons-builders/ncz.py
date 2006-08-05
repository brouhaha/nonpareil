# SConstruct KML file scanner and NCZ file builder for Nonpareil
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
rom_re = re.compile (r'rom\s+"(\S+)"', re.M)

def kml_scanner_fn (node, env, path):
    contents = node.get_contents ()
    images = image_re.findall (contents)
    roms = rom_re.findall (contents)
    files = unique (images + roms)
    fl = []

    for f in files:
        #print "scanner looking for ", f
        kpath = os.path.dirname (str (node))
        while kpath:
            f1 = kpath + '/' + f
            #print "scanner trying", f1
            if os.path.exists (f1):
                #print "found", f1
                fl.append (env.File (f1))
                break
            else:
                kpath = os.path.dirname (kpath)
        else:
            f1 = 'build/' + os.path.dirname (str (node)) + '/' + f
            #print "not found, using", f1
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
    #print "trying to figure out how to build", target_fn
    target_path_and_base, target_suffix = os.path.splitext (target_fn)
    target_path, target_base = os.path.split (target_path_and_base)
    #print "target path", target_path, "target base", target_base, "target suffix", target_suffix
    # if the target_fn is in the source tree (not the build tree), we're done
    #print "target_path [0:6]", target_path [0:6]
    if target_path [0:6] != 'build/':
        return os.path.exists (target_fn);
    builder_list = env ['BUILDERS']
    for builder_name in builder_list.keys():
        builder = builder_list [builder_name]
        if target_suffix in builder.suffix:
            #print "matched builder", builder_name
            for src_suffix in builder.src_suffix:
                #print "possible source suffix", src_suffix
                src_path = target_path.split ('/', 1) [1]
                #print "src path", src_path
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
                

def ncz_emitter_fn (target, source, env):
    extra_files = kml_scanner_fn (source [0], env, None)
    fnl = []
    for f in extra_files:
        fn = str (f)
        try_to_build (fn, env)
        fnl.append (fn)
    return (target, source + fnl)


def ncz_action_fn (target, source, env):
    zf = zipfile.ZipFile (str (target [0]), 'w', zipfile.ZIP_DEFLATED)
    for s in source:
        zf.write (str (s), os.path.basename (str (s)))
    zf.close ()

ncz_builder = env.Builder (action = env.Action (ncz_action_fn),
			   src_suffix = '.kml',
			   source_scanner = kml_scanner,
                           suffix = '.ncz',
                           emitter = ncz_emitter_fn)

env.Append (BUILDERS = {'NCZ' : ncz_builder})

