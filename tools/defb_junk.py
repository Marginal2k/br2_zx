#!/usr/bin/env python3
"""Data that was decoded as code by the reconstruction: improbable instructions (CALL M/P/PE/PO, JP PE/PO, RST #08/#20/#28/#30, DAA...)
become DEFB again (same bytes).   python tools/defb_junk.py work/src_v04/game hum"""
import os, re, sys
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'tools'))
import mkv04 as M

NL = chr(10)
TAB = chr(9)
BAD = re.compile(r'^\s*(?:\S+\s+)?(CALL\s+(M|P|PE|PO),|JP\s+(PE|PO),|RST\s+#(08|20|28|30)\b|RET\s+(PE|PO)\b)', re.I)


def main(tree, variant):
    tree = os.path.abspath(tree)
    out = os.path.join(ROOT, 'build', 'v04', variant + '_junk')
    rc, txt = M.sjasm(tree, out, variant)
    pages = {n: open(os.path.join(out, 'page%d.bin' % n), 'rb').read() for n in range(8)}
    ents = M.parse_listing(os.path.join(out, 'main.lst'), pages, tree)
    n = 0
    byfile = {}
    for e in ents:
        if e.n and BAD.match(e.text.split(';')[0]) and e.file != 'top.asm':
            img = (pages[5] + pages[2]) if e.stream == 'M' else pages[e.stream]
            base = 0x4000 if e.stream == 'M' else 0xC000
            b = img[e.addr - base:e.addr - base + e.n]
            byfile.setdefault(e.file, {})[e.line] = (e, b)
    for fn, d in byfile.items():
        p = os.path.join(tree, fn)
        L = open(p, encoding='utf-8').read().split(NL)
        for ln, (e, b) in d.items():
            line = L[ln - 1]
            label = line.split()[0] if line and line[0] not in ' ' + TAB + ';' else ''
            L[ln - 1] = (label + TAB if label else TAB) + 'DEFB' + TAB + ','.join('#%02X' % x for x in b) + TAB + '; data (not code): ' + ' '.join(e.text.split(';')[0].split())
            n += 1
        open(p, 'w', encoding='utf-8', newline=NL).write(NL.join(L))
    print('lines turned into DEFB:', n)


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
