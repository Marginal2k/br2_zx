#!/usr/bin/env python3
"""Where do the known resource files lie inside a v0.04 page?  python tools/v04layout.py hum|kun PAGE..."""
import glob, os, sys
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
A = os.path.join(ROOT, 'archive', 'unz', 'BR2_DEMO')
BS = chr(92)


def load_assets():
    files = [f for pat in ('DATA/*', 'DATA/HERO/*', 'MUSIC/SONG1C.MUS', 'MUSIC/*.MUS', 'TASK/*', 'MAP/*.MAP', 'MAP/*.HER') for f in glob.glob(os.path.join(A, pat)) if os.path.isfile(f)]
    return {os.path.relpath(f, A).replace(BS, '/'): open(f, 'rb').read() for f in files}


def layout(P, assets, base=0xC000):
    found = []
    for nm, d in sorted(assets.items(), key=lambda t: -len(t[1])):
        if len(d) < 64:
            continue
        k = P.find(d)
        if k >= 0:
            found.append((k, k + len(d), nm))
        else:
            k = P.find(d[:48])
            if k >= 0:
                found.append((k, k + len(d), nm + ' (head matches, body differs)'))
    found.sort()
    out = []
    last = 0
    for a, b, nm in found:
        if a > last:
            out.append((last, a, None))
        out.append((a, b, nm))
        last = max(last, b)
    if last < len(P):
        out.append((last, len(P), None))
    return out


if __name__ == '__main__':
    assets = load_assets()
    side = sys.argv[1]
    for n in [int(x) for x in sys.argv[2:]]:
        P = open(os.path.join(ROOT, 'work', 'v04', f'br2{side}04.{n}.bin'), 'rb').read()
        print('== page', n)
        for a, b, nm in layout(P, assets):
            print('   %04X-%04X %6d %s' % (0xC000 + a, 0xC000 + b, b - a, nm or 'gap'))
