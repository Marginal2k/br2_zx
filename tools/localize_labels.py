#!/usr/bin/env python3
"""v4_* labels that are only jump targets inside one procedure become local labels (.NAME, sjasmplus): fewer global names.
Conditions: all uses in the same file and in the same scope (between two global labels), the scope has no IF block with labels of its own.
   python tools/localize_labels.py work/src_v04/game"""
import os, re, sys, collections
TAB = chr(9)
NL = chr(10)
IDENT = re.compile(r'(?<![A-Za-z0-9_.@])v4_[A-Za-z0-9_]+(?![A-Za-z0-9_])')
LABEL0 = re.compile(r'^([A-Za-z_@][A-Za-z0-9_.@]*)')


def main(tree):
    files = [f for f in sorted(os.listdir(tree)) if f.endswith('.asm')]
    text = {f: open(os.path.join(tree, f), encoding='utf-8').read().split(NL) for f in files}
    allrefs = collections.defaultdict(lambda: collections.defaultdict(list))   # name -> file -> [line index]
    for f, L in text.items():
        for i, l in enumerate(L):
            code = l.split(';')[0]
            for m in IDENT.finditer(code):
                allrefs[m.group(0)][f].append(i)
    cand = {}
    for nm, d in allrefs.items():
        if len(d) != 1:
            continue
        f = next(iter(d))
        L = text[f]
        defs = [i for i in d[f] if LABEL0.match(L[i]) and LABEL0.match(L[i]).group(1) == nm]
        uses = [i for i in d[f] if i not in defs]
        if len(defs) != 1 or not uses:
            continue
        if any(re.search(r'\b(CALL_|EXEX_)\b', L[i].split(';')[0]) or re.match(r'\s*(DEFW|DW)\b', L[i]) for i in uses):
            continue
        cand[nm] = (f, defs[0], uses)
    changed = True
    conv = set(cand)
    while changed:
        changed = False
        for f in files:
            L = text[f]
            bounds = []
            for i, l in enumerate(L):
                m = LABEL0.match(l)
                if m and not (m.group(1) in conv and cand[m.group(1)][0] == f and cand[m.group(1)][1] == i):
                    bounds.append(i)
            bounds.append(len(L) + 1)
            import bisect
            for nm in [n for n in conv if cand[n][0] == f]:
                _, d0, uses = cand[nm]
                s = bisect.bisect_right(bounds, d0) - 1
                lo, hi = (bounds[s] if s >= 0 else -1), bounds[s + 1] if s + 1 < len(bounds) else len(L) + 1
                if s < 0 or not all(lo <= u < hi for u in uses):
                    conv.discard(nm)
                    changed = True
    n = 0
    for f in files:
        names = [nm for nm in conv if cand[nm][0] == f]
        if not names:
            continue
        L = text[f]
        for nm in names:
            loc = '.' + nm[3:]
            for i in {cand[nm][1]} | set(cand[nm][2]):
                code, sep, com = L[i].partition(';')
                code = re.sub(r'(?<![A-Za-z0-9_.@])' + re.escape(nm) + r'(?![A-Za-z0-9_])', loc, code)
                L[i] = code + sep + com
            n += 1
        open(os.path.join(tree, f), 'w', encoding='utf-8', newline=NL).write(NL.join(L))
    left = set(allrefs) - conv
    print('v4_ labels: %d, made local: %d, left global: %d' % (len(allrefs), n, len(left)))


if __name__ == '__main__':
    main(sys.argv[1])
