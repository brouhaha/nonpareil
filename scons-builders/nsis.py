# NSIS Support for SCons
# Written by Mike Elkins, January 2004
# Provided 'as-is', it works for me!
# Modified for use building Nonpareil, by Eric Smith, July 2005

Import ('env')

import os.path


def nsis_parse( sources, keyword, multiple ):
    """
    A function that knows how to read a .nsi file and figure
    out what files are referenced, or find the 'OutFile' line.

    sources is a list of nsi files.
    keyword is the command ('File' or 'OutFile') to look for
    multiple is true if you want all the args as a list, false if you
    just want the first one.
    """
    stuff = []
    for s in sources:
        c = s.get_contents()
        for l in c.split('\n'):
            semi = l.find(';')
            if (semi != -1):
                l = l[:semi]
            hash = l.find('#')
            if (hash != -1):
                l = l[:hash]
            # Look for the keyword
            l = l.strip()
            spl = l.split(None,1)
            if len(spl) > 1:
                if spl[0].capitalize() == keyword.capitalize():
                    arg = spl[1]
                    if arg.startswith('"') and arg.endswith('"'):
                        arg = arg[1:-1]
                    if multiple:
                        stuff += [ arg ]
                    else:
                        return arg
    return stuff


def nsis_scanner( node, env, path ):
    """
    The scanner that looks through the source .nsi files and finds all lines
    that are the 'File' command, fixes the directories etc, and returns them.
    """
    x = SCons.Util.mapPaths(nsis_parse(node.sources,'file',1),'#'+os.path.sep+str(node.get_parents()[0]))
    x = map(os.path.normpath,x)
    return x


def nsis_emitter( source, target, env ):
    """
    The emitter changes the target name to match what the command actually will
    output, which is the argument to the OutFile command.
    """
    x = (
        [str(source[0].get_parents()[0])+os.path.sep+nsis_parse(source,'outfile',0)],
        source)
    return x


nsis_builder = env.Builder (action = '$NSISCOM',
                            src_suffix = '.nsi',
                            source_scanner = env.Scanner (function = nsis_scanner,
                                                          skeys = ['.nsis']),
                            emitter = nsis_emitter)

env.Append (BUILDERS = {'MakeNSISInstaller' : nsis_builder })

env['NSIS'] = '/usr/local/nsis/makensis'
env['NSISCOM'] = '$NSIS $SOURCES'
