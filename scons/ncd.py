# SConstruct NCD file builder for Nonpareil
# $Id$
# Copyright 2006 Eric L. Smith <eric@brouhaha.com>

Import ('env')

import sys
import os.path
from xml.dom.ext.reader.Sax import FromXmlFile
#from xml.dom.ext import PrettyPrint

def ncd_tmpl_scanner_fn (node, env, path):
    fl = []
    if os.path.splitext (str (node)) [1] != '.tmpl':
        return fl
    try:
        doc = FromXmlFile (str (node))
    except:
        print "XML parsing of '%s' failed!" % (str (node),)
        print sys.exc_info () [0]
        return fl
    for obj_file_node in doc.getElementsByTagName ('obj_file'):
        f = obj_file_node.firstChild.nodeValue.strip()
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


ncd_tmpl_scanner = env.Scanner (function = ncd_tmpl_scanner_fn,
                                skeys = ['.ncd.tmpl'])


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
                

def ncd_emitter_fn (target, source, env):
    extra_files = ncd_tmpl_scanner_fn (source [0], env, None)
    fnl = []
    for f in extra_files:
        fn = str (f)
        try_to_build (fn, env)
        fnl.append (fn)
    return (target, source + fnl)

build_ncd_path = str (env ['BUILD_NCD'])

def ncd_generator_fn (source, target, env, for_signature):
    #$$$ need to handle generating path from multiple object files
    obj_path = os.path.dirname (str (source [1]))
    s = '%s %s --obj-path %s -o %s' % (build_ncd_path,
                                   source [0],
                                   obj_path,
                                   target[0])
    return s

ncd_builder = env.Builder (generator = ncd_generator_fn,
			   src_suffix = '.ncd.tmpl',
			   source_scanner = ncd_tmpl_scanner,
                           suffix = '.ncd',
                           emitter = ncd_emitter_fn)

env.Append (BUILDERS = {'NCD' : ncd_builder})

