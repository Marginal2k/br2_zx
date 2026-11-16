#!/usr/bin/env python3
"""Match the procedures of our sources (work/src_faithful, = 4.Z80 build of 17.11.1999) against the released demo v0.04.

    python tools/match_v04.py [hum|kun] [--detail]

Our image is cut at every label into chunks (small chunks are merged to >= 12 bytes, never across a page); the instruction stream is
decoded (skoolkit via dz.py), every 16-bit absolute operand (CALL/JP/LD nn/(nn)/rr,nn, IX/IY forms) is masked (the addresses shift),
the chunk is searched as a wildcard pattern in all 8 pages of the v0.04 image.
  SAME     whole chunk found (masked)
  PART     the first 8..N bytes are found, the rest differs (procedure changed; N = longest masked match from the found start)
  ABSENT   not found at all
"""
import os, re, sys
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'tools'))
import dz

B = os.path.join(ROOT, 'build', 'faithful', 'game')
BASE = {5: 0x4000, 2: 0x8000}


def masked_stream(mem, start, end):
    """-> (masked pattern as list[int|None]) for [start,end) decoding linearly; undecodable byte -> kept literal."""
    pat = []
    a = start
    while a < end:
        try:
            i = dz.dis(mem, a, a + 1)[0]
            b = list(i.bytes)
        except Exception:
            b = [mem[a]]
        if a + len(b) > end:
            b = b[:end - a]
        op = (i.operation if len(b) and 'i' in dir() else '').lower()
        m = list(b)
        n = len(b)
        pre = 0
        if b and b[0] in (0xDD, 0xFD, 0xED):
            pre = 1
        o0 = b[pre] if len(b) > pre else 0
        # 16-bit operand = last two bytes of the instruction when it has one
        has16 = False
        if pre == 0:
            has16 = n == 3
        elif b[0] == 0xED:
            has16 = n == 4
        else:                                              # DD/FD: LD IX,nn (4), LD (nn),IX / LD IX,(nn) (4), others have d,n (8-bit) -> only those
            has16 = n == 4 and o0 in (0x21, 0x22, 0x2A)
        if has16 and 'jr' not in op:
            m[-2] = m[-1] = None
        pat += m
        a += len(b)
    return pat


def to_regex(pat):
    return re.compile(b''.join(re.escape(bytes([x])) if x is not None else b'.' for x in pat), re.S)


def load_v04(side):
    pg = {}
    for n in range(8):
        pg[n] = open(os.path.join(ROOT, 'work', 'v04', f'br2{side}04.{n}.bin'), 'rb').read()
    return pg


def our_chunks():
    syms = {}
    for l in open(os.path.join(B, 'main.sym')):
        m = re.match(r'(\S+):\s*EQU 0x([0-9A-F]+)', l)
        if m:
            syms[m.group(1)] = int(m.group(2), 16)
    pages = {n: open(os.path.join(B, f'page{n}.bin'), 'rb').read() for n in range(8)}
    import z80snap
    lst = z80snap.symbols(os.path.join(ROOT, 'archive', 'unz', 'BR2_DEMO', 'ASM80', '4.LST'))
    out = []
    for n in range(8):
        base = BASE.get(n, 0xC000)
        a0 = base
        a1 = base + 0x4000
        labs = sorted({a for k, (a, w) in lst.items() if a0 <= a < a1 and ((n in (5, 2) and w.startswith('Main')) or w == 'Pg #%02X' % n)})
        if not labs or labs[0] != a0:
            labs = [a0] + labs
        labs = labs + [a1]
        cuts = [labs[0]]
        for l in labs[1:]:
            if l - cuts[-1] >= 12 or l == a1:
                cuts.append(l)
        for s, e in zip(cuts, cuts[1:]):
            out.append((n, s, e, pages[n][s - base:e - base]))
    return out, syms, pages


def compute_rows(side):
    v = load_v04(side)
    chunks, syms, pages = our_chunks()
    rev = {}
    for k, a in syms.items():
        rev.setdefault(a, k)
    stat = {}
    rows = []
    for n, s, e, data in chunks:
        base = BASE.get(n, 0xC000)
        if not any(data):
            kind = 'ZERO'
            rows.append((n, s, e, kind, '', 0))
            continue
        mem = [0] * 65536
        mem[s:e] = data
        pat = masked_stream(mem, s, e)
        pat = pat[:e - s]
        rx = to_regex(pat)
        found = None
        for pn in range(8):
            m = rx.search(v[pn])
            if m:
                found = (pn, m.start() + BASE.get(pn, 0xC000))
                break
        if found:
            rows.append((n, s, e, 'SAME', found, e - s))
            continue
        # partial: longest prefix (>=8 bytes) found
        best = 0
        loc = None
        L = len(pat)
        for cut in (L - 1, L * 3 // 4, L // 2, L // 3, 16, 8):
            if cut < 8 or cut >= L:
                continue
            rx2 = to_regex(pat[:cut])
            for pn in range(8):
                m = rx2.search(v[pn])
                if m:
                    best, loc = cut, (pn, m.start() + BASE.get(pn, 0xC000))
                    break
            if best:
                break
        rows.append((n, s, e, 'PART' if best else 'ABSENT', loc or '', best))
    return rows, v, syms, rev


def main():
    side = 'hum' if len(sys.argv) < 2 or sys.argv[1] not in ('kun',) else 'kun'
    detail = '--detail' in sys.argv
    rows, v, syms, rev = compute_rows(side)
    tot = {}
    for n, s, e, k, f, b in rows:
        t = tot.setdefault(n, {'SAME': 0, 'PART': 0, 'ABSENT': 0, 'ZERO': 0, 'cnt': {'SAME': 0, 'PART': 0, 'ABSENT': 0, 'ZERO': 0}})
        t[k] += e - s
        t['cnt'][k] += 1
    print(f'v0.04 {side}: coverage of our image (bytes; chunks), pages = RAM pages')
    allb = {'SAME': 0, 'PART': 0, 'ABSENT': 0, 'ZERO': 0}
    for n in sorted(tot):
        t = tot[n]
        print(f'  page {n}: SAME {t["SAME"]:6} ({t["cnt"]["SAME"]}), PART {t["PART"]:6} ({t["cnt"]["PART"]}), ABSENT {t["ABSENT"]:6} ({t["cnt"]["ABSENT"]}), zero {t["ZERO"]}')
        for k in allb:
            allb[k] += t[k]
    nz = allb['SAME'] + allb['PART'] + allb['ABSENT']
    print(f'  total non-zero bytes {nz}: SAME {allb["SAME"]} ({100*allb["SAME"]/nz:.1f}%), PART {allb["PART"]}, ABSENT {allb["ABSENT"]}')
    # shifts
    sh = {}
    for n, s, e, k, f, b in rows:
        if k == 'SAME' and f:
            sh.setdefault((n, f[0]), []).append(f[1] - s)
    print('  page map (ours -> v0.04) and most common address shift:')
    for (n, pn), l in sorted(sh.items()):
        from collections import Counter
        c = Counter(l).most_common(1)[0]
        print(f'    ours {n} -> v0.04 {pn}: {len(l)} chunks, shift {c[0]:+d} ({c[1]})')
    # reverse view: which bytes of the v0.04 image are explained by our code
    cov = {n: bytearray(16384) for n in range(8)}
    for n, s_, e_, k, fo, b in rows:
        if k in ('SAME', 'PART') and fo:
            pn, ad = fo
            base = BASE.get(pn, 0xC000)
            ln = (e_ - s_) if k == 'SAME' else b
            for i in range(ad - base, min(16384, ad - base + ln)):
                cov[pn][i] = 1
    print('  v0.04 image: bytes NOT explained by our code (non-zero), by page:')
    tu = 0
    with open(os.path.join(ROOT, 'build', f'v04_unmatched_{side}.txt'), 'w') as f:
        for pn in range(8):
            base = BASE.get(pn, 0xC000)
            un = [i for i in range(16384) if v[pn][i] and not cov[pn][i]]
            tu += len(un)
            runs = []
            for i in un:
                if runs and i <= runs[-1][1] + 8:
                    runs[-1][1] = i
                else:
                    runs.append([i, i])
            big = [(a, b) for a, b in runs if b - a >= 12]
            print(f'    page {pn}: {len(un)} bytes in {len(runs)} runs ({len(big)} runs >= 12 B, {sum(b - a + 1 for a, b in big)} B)')
            for a, b in runs:
                f.write(f'{pn} {base + a:04X}-{base + b:04X} {b - a + 1}\n')
    print(f'    total unexplained non-zero bytes: {tu}')
    out = os.path.join(ROOT, 'build', f'match_v04_{side}.txt')
    with open(out, 'w') as f:
        for n, s, e, k, fo, b in rows:
            if k != 'ZERO':
                f.write(f'{n} {s:04X}-{e:04X} {rev.get(s, "?"):12} {k:6} {("%d:%04X" % fo) if fo else "":8} {b}\n')
    print('  detail:', out)


if __name__ == '__main__':
    main()
