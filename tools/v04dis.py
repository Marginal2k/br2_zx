#!/usr/bin/env python3
"""Disassemble a range of the released demo v0.04 with names of matched procedures.
   python tools/v04dis.py hum|kun START END   (addresses in the 64K map: #4000 page5, #8000 page2, #C000 page given by -pN)"""
import sys, os
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'tools'))
import dz
side = sys.argv[1]
a, b = int(sys.argv[2], 16), int(sys.argv[3], 16)
win = int(sys.argv[4]) if len(sys.argv) > 4 else 0
P = {n: open(os.path.join(ROOT, 'work', 'v04', f'br2{side}04.{n}.bin'), 'rb').read() for n in range(8)}
mem = [0] * 65536
mem[0x4000:0x8000] = P[5]; mem[0x8000:0xC000] = P[2]; mem[0xC000:] = P[win]
names = {}
for l in open(os.path.join(ROOT, 'build', f'match_v04_{side}.txt')):
    p = l.split()
    if p[3] in ('SAME', 'PART') and len(p) >= 6 and ':' in p[4]:
        pg, ad = p[4].split(':'); names[(int(pg), int(ad, 16))] = p[2]
for i in dz.dis(mem, a, b):
    ad = i.address
    pg = 5 if ad < 0x8000 else 2 if ad < 0xC000 else win
    nm = names.get((pg, ad))
    print('%04X %-9s %-26s%s' % (ad, bytes(i.bytes).hex(), i.operation, ('  ; <' + nm + '>') if nm else ''))
