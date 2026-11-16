#!/usr/bin/env python3
"""Fragments of the v0.04 tree that are new relative to the author's sources (headers '; ---- v0.04: ...'): sizes and labels.
   python tools/frag_list.py [min_size]   (data: build/v04/frag_list.json)"""
import difflib, json, os, re, sys
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'tools'))
import mkv04 as M
tree = os.path.join(M.SRC, os.environ.get('V04TREE', 'game'))
orig = os.path.join(M.SRC, 'game_orig')
out = os.path.join(ROOT, 'build', 'v04', 'hum_frag')


def main():
    rc, txt = M.sjasm(tree, out, 'hum')
    pages = {n: open(os.path.join(out, 'page%d.bin' % n), 'rb').read() for n in range(8)}
    ents = M.parse_listing(os.path.join(out, 'main.lst'), pages, tree)
    by = {}
    for e in ents:
        by.setdefault((e.file, e.line), e)
    res = []
    for fn in sorted(os.listdir(tree)):
        if not fn.endswith('.asm') or not os.path.exists(os.path.join(orig, fn)):
            continue
        A = open(os.path.join(orig, fn), encoding='utf-8').read().split(chr(10))
        B = open(os.path.join(tree, fn), encoding='utf-8').read().split(chr(10))
        norm = lambda l: l.split(';')[0].split()
        sm = difflib.SequenceMatcher(None, [tuple(norm(l)) for l in A], [tuple(norm(l)) for l in B], autojunk=False)
        for tag, i1, i2, j1, j2 in sm.get_opcodes():
            if tag == 'equal' or j2 == j1:
                continue
            hd = [j for j in range(j1, j2) if B[j].startswith('; ---- v0.04')]
            if not hd:
                continue
            for k_, h_ in enumerate(hd):
                e_ = hd[k_ + 1] if k_ + 1 < len(hd) else j2
                seg = list(range(h_, e_))
                n = sum(by[(fn, j + 1)].n for j in seg if (fn, j + 1) in by)
                labs = [re.match(r'([A-Za-z_][A-Za-z0-9_.]*)', B[j]).group(1) for j in seg if B[j] and B[j][0] not in ' ' + chr(9) + ';' and re.match(r'[A-Za-z_]', B[j])]
                addr = min((by[(fn, j + 1)].addr for j in seg if (fn, j + 1) in by), default=0)
                res.append({'file': fn, 'line': h_ + 1, 'end': e_, 'bytes': n, 'addr': addr, 'labels': labs, 'head': B[h_],
                            'oldlabels': [l for l in A[i1:i2] if l and l[0] not in ' ' + chr(9) + ';']})
    json.dump(res, open(os.path.join(ROOT, 'build', 'v04', 'frag_list.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    return res


if __name__ == '__main__':
    r = main()
    ms = int(sys.argv[1]) if len(sys.argv) > 1 else 0
    print(len(r), 'fragments,', sum(1 for x in r if x['bytes'] >= 32), '>= 32 bytes,', sum(x['bytes'] for x in r), 'bytes')
    for x in sorted(r, key=lambda x: -x['bytes']):
        if x['bytes'] >= ms:
            print('%5d  %s:%d  #%04X  %s' % (x['bytes'], x['file'], x['line'], x['addr'], ' '.join(x['labels'][:4])))
