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
        print "looking for", f
        # look for the file in the hierarchy
        kpath = os.path.dirname (str (node))
        while kpath:
            f2 = kpath + '/' + f
            if os.path.exists (f2):
                print "found", f2
                break
            else:
                kpath = os.path.dirname (kpath)
        else:
            f2 = 'build/' + os.path.dirname (str (node)) + '/' + f
            print "using", f2
            # The following ugly hack deals with the lack of automatic
            # implicit dependency handling in SCons.  Hopefully we'll get
            # a better solution eventually.
            if f2 [-4:] == '.rom':
                print "it's a .rom file"
                sf = os.path.dirname (str (node)) + '/' + f [:-3] + 'asm'
                print "try to build from", sf
                env.UASM (target = f2, source = sf)
        fl.append (env.File (f2))
    return fl


kml_scanner = env.Scanner (function = kml_scanner_fn,
                           skeys = ['.kml'])


def ncz_emitter_fn (target, source, env):
    extra_files = kml_scanner_fn (source [0], env, None)
    fnl = []
    for f in extra_files:
        fn = env.File (f)
        # create dependency for fn based on available builders
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

