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
    kpath = os.path.dirname (str (node))
    contents = node.get_contents ()
    images = image_re.findall (contents)
    roms = rom_re.findall (contents)
    files = unique (images + roms)
    fn = []
    for f in files:
        fn.append (env.File (kpath + '/' + f))
    return fn

kml_scanner = env.Scanner (function = kml_scanner_fn,
                           skeys = ['.kml'])

def ncz_emitter_fn (target, source, env):
    return (target, source + kml_scanner_fn (source [0], env, None))


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

