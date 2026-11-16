#!/usr/bin/env python3
"""One-off: work/src_v04/game -> src/game with the Kunge branch removed (IFDEF KUN / IFNDEF KUN resolved to the Human code).
The tree in src/ is then edited by hand; this script is kept only to document where src/game came from."""
import os, re, sys
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, 'work', 'src_v04', 'game')
DST = os.path.join(ROOT, 'src', 'game')
os.makedirs(DST, exist_ok=True)
rx = re.compile(r'^\s*(IFDEF|IFNDEF|IF|IFN|IFUSED|ELSE|ENDIF)\b\s*(\S*)', re.I)
for fn in sorted(os.listdir(SRC)):
    if not fn.endswith(('.asm', '.inc')):
        continue
    out = []
    stack = []      # entries: ('kun', active) or ('other',)
    for line in open(os.path.join(SRC, fn), encoding='utf-8').read().split('\n'):
        m = rx.match(line)
        if m:
            d, arg = m.group(1).upper(), m.group(2)
            if d in ('IFDEF', 'IFNDEF') and arg == 'KUN':
                stack.append(['kun', d == 'IFNDEF'])     # active branch = Human
                continue
            if d == 'ELSE' and stack and stack[-1][0] == 'kun':
                stack[-1][1] = not stack[-1][1]
                continue
            if d == 'ENDIF':
                if stack and stack[-1][0] == 'kun':
                    stack.pop(); continue
                if stack and stack[-1][0] == 'other':
                    stack.pop()
            elif d != 'ELSE':
                stack.append(['other'])
        if all(s[1] for s in stack if s[0] == 'kun'):
            out.append(line)
    open(os.path.join(DST, fn), 'w', encoding='utf-8', newline='\n').write('\n'.join(out))
print('ok')
