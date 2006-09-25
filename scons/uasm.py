# SCons builder for Nonpareil microassembler
# $Id$
# Copyright 2006 Eric L. Smith <eric@brouhaha.com>

Import ('env')

import os.path

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
                            emitter = uasm_emitter_fn)

env.Append (BUILDERS = { 'UASM': uasm_builder })
