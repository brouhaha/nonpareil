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
    contents = node.get_text_contents ()
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


def nui_emitter_fn (target, source, env):
    extra_files = kml_scanner_fn (source [0], env, None)
    fnl = []
    for f in extra_files:
        fn = str (f)
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

