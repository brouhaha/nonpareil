# SConstruct KML file scanner and NCZ file builder for Nonpareil
# $Id$
# Copyright 2006 Eric L. Smith <eric@brouhaha.com>

Import ('env')

import os.path
import re
import zipfile

image_re = re.compile (r'image\\s+"(\\S+)"', re.M)
rom_re = re.compile (r'rom\\s+"(\\S+)"', re.M)

def kml_scanner_fn (node, env, path):
    contents = node.get_contents ()
    images = image_re.findall (contents)
    roms = rom_re.findall (contents)
    return images + roms

kml_scanner = env.Scanner (function = kml_scanner_fn,
                           skeys = ['.kml'])
env.Append (SCANNERS = kml_scanner)

def ncz_action_fn (target, source, env):
    zf = zipfile.ZipFile (str (target [0]), 'w', zipfile.ZIP_DEFLATED)
    for s in source:
        zf.write (str (s), os.path.basename (str (s)))
    zf.close ()

ncz_builder = env.Builder (action = env.Action (ncz_action_fn),
			   src_suffix = '.kml',
			   source_scanner = kml_scanner,
                           suffix = '.ncz')

env.Append (BUILDERS = {'NCZ' : ncz_builder})

