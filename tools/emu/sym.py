#!/usr/bin/env python3
"""адрес метки из build/game/main.sym (hex): python tools/emu/sym.py NNNHK SAVgam"""
import re, sys, os
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
S = {}
for l in open(os.path.join(ROOT, 'build', 'game', 'main.sym'), encoding='utf-8', errors='replace'):
    m = re.match(r'(\S+):\s+EQU\s+0x([0-9A-Fa-f]+)', l)
    if m:
        S[m.group(1)] = int(m.group(2), 16)
print(' '.join('%X' % S[k] for k in sys.argv[1:]))
