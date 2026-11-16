#!/usr/bin/env python3
"""Build work/src_v04/<variant> (hum, kun) with sjasmplus and compare the 8 pages with the released images
work/v04/br2<variant>04.N.bin (= BR2D004.SCL).  Prints the differences per page and  UNEXPLAINED N  (goal: 0).

    python tools/verify_v04.py [hum] [kun]

Explained (masked) differences:
  DEFR / UNDEF   junk of the author's assembler memory (same masks as verify_original.py)
  LIVE (kun only, listed in work/src_v04/kun_live.txt when present): the Kunge image is an emulator snapshot (registers in the loader,
         stack at #401C..#403E, variables/self-modified operands); every masked range must be listed there with its reason.
Also builds the start1/final trees of work/src_faithful (verify_original.py) when --all is given.
"""
import os, re, sys
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'tools'))
import mkv04 as M

BASE = {5: 0x4000, 2: 0x8000}


def live_ranges(variant):
    """{(page, addr): mask} from work/src_v04/kun_live.txt:  'page from to [maskhex] reason'; mask = bits that are still compared"""
    res = {}
    p = os.path.join(ROOT, 'work', 'src_v04', 'kun_live.txt')
    if variant == 'kun' and os.path.exists(p):
        for l in open(p, encoding='utf-8'):
            if l.startswith('#') or not l.strip():
                continue
            t = l.split(None, 4)
            pg, a, b = int(t[0]), int(t[1], 16), int(t[2], 16)
            mask = 0
            if re.fullmatch(r'[0-9A-Fa-f]{2}', t[3]) and len(t) > 4:
                mask = int(t[3], 16)
            for x in range(a, b + 1):
                for pgx in ((5,) if (pg in (5, 2) and x < 0x8000) else (2,) if pg in (5, 2) else (pg,)):
                    res[(pgx, x)] = ('LIVE', mask)
    return res


def verify(variant):
    tree = os.path.join(ROOT, 'work', 'src_v04', os.environ.get('V04TREE', 'game'))
    out = os.path.join(ROOT, 'build', 'v04', variant)
    for n in range(8):
        try:
            os.remove(os.path.join(out, f'page{n}.bin'))
        except OSError:
            pass
    rc, txt = M.sjasm(tree, out, variant)
    errs = [l for l in txt.split(chr(10)) if 'error' in l]
    regs = [(k, int(pg), int(a, 16), int(n)) for k, pg, a, n in re.findall(r'(DEFR|UNDEF) (\d+) 0x([0-9A-F]+) (\d+)', txt)]
    cls = {}
    for k, pg, a, n in regs:
        for i in range(a, a + n):
            cls.setdefault((pg, i), k)
    live = live_ranges(variant)

    bad = 0
    print(f'== {variant}: sjasmplus errors: {len(errs)}', ('; first: ' + errs[0]) if errs else '')
    for pg in (5, 2, 0, 1, 3, 4, 6, 7):
        fn = os.path.join(out, f'page{pg}.bin')
        if not os.path.exists(fn):
            print(f'  page {pg}: no output'); bad += 16384
            continue
        ours = open(fn, 'rb').read()
        ref = open(os.path.join(ROOT, 'work', 'v04', f'br2{variant}04.{pg}.bin'), 'rb').read()
        base = BASE.get(pg, 0xC000)
        diffs = [i for i in range(16384) if ours[i] != ref[i]]
        expl = {}
        other = []
        for i in diffs:
            c = cls.get((pg, base + i))
            lv = live.get((pg, base + i))
            if c:
                expl[c] = expl.get(c, 0) + 1
            elif lv and (ours[i] & lv[1]) == (ref[i] & lv[1]):
                expl['LIVE'] = expl.get('LIVE', 0) + 1
            elif lv and lv[1] == 0:
                expl['LIVE'] = expl.get('LIVE', 0) + 1
            else:
                other.append(i)
        runs = []
        for i in other:
            if runs and i <= runs[-1][1] + 1:
                runs[-1][1] = i
            else:
                runs.append([i, i])
        line = f'  page {pg} (#{base:04X}): ' + ('IDENTICAL' if not diffs else f'{len(diffs)} differing')
        if expl:
            line += '  explained: ' + ', '.join(f'{k} {v}' for k, v in sorted(expl.items()))
        if other:
            line += f'  UNEXPLAINED {len(other)} in {len(runs)} runs, first: ' + ', '.join('%04X(%d)' % (base + a, b - a + 1) for a, b in runs[:6])
        print(line)
        bad += len(other)
    return bad


def main():
    vs = [a for a in sys.argv[1:] if a in ('hum', 'kun')] or ['hum', 'kun']
    total = 0
    for v in vs:
        if not os.path.isdir(os.path.join(ROOT, 'work', 'src_v04', 'game')):
            print(f'== {v}: tree work/src_v04/{v} does not exist (run tools/mkv04_gen.py {v})')
            total += 16384 * 8
            continue
        total += verify(v)
    if '--all' in sys.argv:
        import subprocess
        r = subprocess.run([sys.executable, '-I', os.path.join(ROOT, 'tools', 'verify_original.py')], capture_output=True, text=True)
        tail = [l for l in r.stdout.split(chr(10)) if l.startswith('UNEXPLAINED')]
        print('start1/final (verify_original.py):', tail[-1] if tail else r.stdout[-200:])
        if not tail or tail[-1] != 'UNEXPLAINED 0':
            total += 1
    print(f'\nUNEXPLAINED {total}')
    return total


if __name__ == '__main__':
    sys.exit(1 if main() else 0)
