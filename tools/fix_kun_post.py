#!/usr/bin/env python3
"""After the kun stage: the music module of the Kunge image differs from SONG1C.MUS only by the working state of the player (kun_live.txt),
so the plain INCBIN stays.   python tools/fix_kun_post.py work/src_v04/game"""
import os, re, sys
tree = sys.argv[1]
p = os.path.join(tree, 'main.asm')
s = open(p, encoding='utf-8').read()
s2 = re.sub(r'\tIFDEF\tKUN\n; ---- Kunge campaign only[^\n]*\n\tINCBIN\t"kun/6_r\d+_EC77.bin"[^\n]*\n\tELSE\n(\tINCBIN "music/song1c.mus"[^\n]*\n)\tENDIF\n', r'\1', s)
open(p, 'w', encoding='utf-8', newline='\n').write(s2)
print('music wrapper removed' if s2 != s else 'music wrapper not found')
refs = set()
for f in os.listdir(tree):
    if f.endswith(('.asm', '.inc')):
        refs |= {m.group(1).replace(chr(92), '/') for m in re.finditer(r'INCBIN\s+"([^"]+)"', open(os.path.join(tree, f), encoding='utf-8', errors='replace').read())}
root = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'work', 'assets_v04')
n = 0
for d in ('hum', 'kun'):
    for f in os.listdir(os.path.join(root, d)):
        if d + '/' + f not in refs:
            os.remove(os.path.join(root, d, f))
            n += 1
print('unused assets removed:', n)
