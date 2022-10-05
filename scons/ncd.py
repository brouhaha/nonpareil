# SConstruct NCD file builder for Nonpareil
# $Id$
# Copyright 2006 Eric L. Smith <eric@brouhaha.com>

Import ('env')

import sys
import os.path
from xml.dom import minidom

def ncd_tmpl_scanner_fn (node, env, path):
    fl = []
    if os.path.splitext (str (node)) [1] != '.tmpl':
        return fl
    try:
        doc = minidom.parse(str(node))
    except:
        print("XML parsing of '%s' failed!" % (str (node),))
        print(sys.exc_info () [0])
        return fl
    obj_filenames = [e.firstChild.nodeValue.strip() for e in doc.getElementsByTagName ('obj_file')]
    return obj_filenames


ncd_tmpl_scanner = env.Scanner(function = ncd_tmpl_scanner_fn,
                               skeys = ['.ncd.tmpl'])
# BUG: even with "recursive = False", the scanner function is being called
# for the .obj files, rather than only for the .ncd.tmpl files


def ncd_emitter_fn (target, source, env):
    extra_files = ncd_tmpl_scanner_fn (source [0], env, None)
    fnl = []
    for f in extra_files:
        fn = str (f)
        fnl.append (fn)
    return (target, source + fnl)

build_ncd_path = str (env ['BUILD_NCD'])

def ncd_generator_fn (source, target, env, for_signature):
    obj_path = os.path.dirname (str (source [1]))
    l = 'xmllint --noout --valid %s' % source [0]
    s = '%s %s --obj-path %s -o %s' % (build_ncd_path,
                                   source [0],
                                   obj_path,
                                   target[0])
    return [s]

ncd_builder = env.Builder (generator = ncd_generator_fn,
			   src_suffix = '.ncd.tmpl',
			   source_scanner = ncd_tmpl_scanner,
                           suffix = '.ncd',
                           emitter = ncd_emitter_fn)

env.Append (BUILDERS = {'NCD' : ncd_builder})

