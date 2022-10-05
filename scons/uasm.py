# SCons builder for Nonpareil microassembler
# $Id$
# Copyright 2006, 2008 Eric Smith <eric@brouhaha.com>

Import ('env')

import os.path
import re

asm_image_re = re.compile (r'\.include\s+"(\S+)"', re.M)

def asm_scanner_fn (node, env, path):
    contents = node.get_text_contents ()
    includes = asm_image_re.findall (contents)
    inc_dir = os.path.dirname (str (node))
    return [env.File (inc_dir + '/' + inc) for inc in includes]

asm_scanner = env.Scanner (function = asm_scanner_fn,
                           skeys = ['.asm'],
                           recursive = True)

uasm_path = str (env ['UASM'])

def uasm_emitter_fn (target, source, env):
    target.append (os.path.splitext (str (target [0])) [0] + '.lst')
    env.Depends (target, env ['UASM'])
    return (target, source)

def uasm_generator_fn (source, target, env, for_signature):
    return '%s %s -o %s -l %s' % (uasm_path, source [0], target [0], target [1])

uasm_builder = env.Builder (generator = uasm_generator_fn,
                            suffix = ".obj",
                            src_suffix = '.asm',
                            source_scanner = asm_scanner,
                            emitter = uasm_emitter_fn)

env.Append (BUILDERS = { 'UASM': uasm_builder })
