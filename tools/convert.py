#!/usr/bin/env python3
"""One-off: ASM80 sources of the archive -> work/src_faithful/<program>/*.asm (via a80conv.py), used binaries -> work/assets_faithful/.

    python tools/convert.py
The hand-written files (work/src_faithful/*/main.asm, lib/) are not touched.
"""
import os, re, shutil, sys
BS = chr(92)
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'tools'))
import a80conv

ASM = os.path.join(ROOT, 'archive', 'unz', 'BR2_DEMO', 'ASM80')
OUT = os.path.join(ROOT, 'work', 'src_faithful')
ASSETS = os.path.join(ROOT, 'work', 'assets_faithful')
used = set()


def incname(n):
    n = n.lower()
    n = re.sub(r'^4', '', n)
    n = re.sub(r'^[_~&]+', '', n)
    return re.sub(r'[^a-z0-9_.]', '_', n) + '.asm'


def binmap_for(srcdir):
    def f(p):
        rel = p.replace(BS, '/')
        while rel.startswith('../'):
            rel = rel[3:]
        src = os.path.normpath(os.path.join(srcdir, p.replace(BS, '/')))
        dst = os.path.join(ASSETS, rel.lower())
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        if not os.path.exists(src):
            print('MISSING', src)
        else:
            shutil.copyfile(src, dst)
        used.add(rel.lower())
        return rel.lower()
    return f


PROGS = {
    'game': ['4MAIN', '4LIB1A', '4_INTV', '4LID', '4_IO', '4_PROTEC', 'XDELPZ', '4LIB2', '4_SOUND1', '4SCAN', '4~LOCAL', '4~VAR',
             '4~LEVEL', '4LIA', '4LIC2X', '4LIH', '4WIZARD', '4LIF', '4LIG', '4LIB3VIZ', '4INTEL', '4LIB4X', '4LIK1', '4MAP',
             '4LIB3', '4MISC_6', '4INTEL_W', '4STRATEG', '4_SOUND2', '4LIE', '4MENU2', '4LIB2X2I', '4LIK2'],
    'start1': ['4&START1', '4&DISK1', 'XDELPZ', '4&INTRO', '4&INSTR', '4TV16'],
    'final': ['4&FINAL', 'XDELPZ'],
}


def run(name, files):
    p = a80conv.Program(ASM, [f + '.A80' for f in files], binmap=binmap_for(ASM), incname=incname)
    for w in dict.fromkeys(p.run(os.path.join(OUT, name))):
        print(name, 'warning:', w)


if __name__ == '__main__':
    for n, fl in PROGS.items():
        run(n, fl)
    print(len(used), 'binary resources copied')
