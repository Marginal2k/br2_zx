#!/usr/bin/env python3
"""Rebuild every program of the BR2 demo archive from work/src_faithful with sjasmplus and compare it byte for byte with
what the author's ASM80 produced (archive/unz/BR2_DEMO):

  game    -> ASM80/4.Z80 (all 8 RAM pages) + the symbol table 4.LST (3100 labels) + entry point #4023
  start1  -> VDISK01/4&START1.B00..B06 (+ LP2..LP5 = XLPZ packed B02..B05, checked by unpacking) + 4&START1.LST
  final   -> VDISK01/FINALCUT/4&FINAL.B00, B01

    python tools/verify_original.py

Classes of differences (everything else is printed as OTHER and counted as UNEXPLAINED):
  DEFR    "DEFR n": n bytes of what the assembler happened to have in its memory (junk: pieces of code, tables of an earlier run)
  UNDEF   "DEFB ?" / "DEFW ?": the space is reserved, the value is not written (same kind of junk)
  FONT    4&FINAL.B00 carries the OLD font of 4FONT.FNT (the file was changed after the B00 was built); the bytes are
          proved to be the font of the demo v0.00 snapshot (_DEMO/BR2DEMO.000/BR2DM000.Z80)
"""
import os, re, shutil, subprocess, sys
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'tools'))
import lpz, z80snap

SJ = shutil.which('sjasmplus') or r'C:\sjasmplus\sjasmplus.exe'
ARC = os.path.join(ROOT, 'archive', 'unz', 'BR2_DEMO')
ASM = os.path.join(ARC, 'ASM80')
V1 = os.path.join(ARC, 'VDISK01')
SRC = os.path.join(ROOT, 'work', 'src_faithful')
B = os.path.join(ROOT, 'build', 'faithful')


def rd(*p):
    with open(os.path.join(*p), 'rb') as f:
        return f.read()


def asm(name):
    out = os.path.join(B, name)
    os.makedirs(out, exist_ok=True)
    src = os.path.join(SRC, name)
    r = subprocess.run([SJ, '--nologo', '--msg=err', '--sym=main.sym', '-I', src, '-I', os.path.join(SRC, 'lib'),
                        '-I', os.path.join(ROOT, 'work', 'assets_faithful'), os.path.join(src, 'top.asm')],
                       cwd=out, capture_output=True, text=True)
    txt = r.stdout + r.stderr
    if r.returncode or 'error' in txt:
        sys.exit(f'assembly of {name} failed:\n{txt}')
    regs = [(k, int(pg), int(a, 16), int(n)) for k, pg, a, n in re.findall(r'(DEFR|UNDEF) (\d+) 0x([0-9A-F]+) (\d+)', txt)]
    syms = {}
    for l in open(os.path.join(out, 'main.sym')):
        m = re.match(r'(\S+):\s*EQU 0x([0-9A-F]+)', l)
        if m:
            syms[m.group(1)] = int(m.group(2), 16)
    return out, regs, syms


def runs(idx):
    res = []
    for i in idx:
        if res and i <= res[-1][1] + 1:
            res[-1][1] = i
        else:
            res.append([i, i])
    return res


def compare(title, rel, mine, base, cls=None, tail_zero=True):
    """rel, mine: bytes; cls: {absolute address: class}. Returns (n_diffs, n_unexplained, text)."""
    cls = cls or {}
    n = len(rel)
    diffs = [i for i in range(n) if rel[i] != mine[i]]
    expl, other = {}, []
    for i in diffs:
        a = base + i
        if a in cls:
            expl[cls[a]] = expl.get(cls[a], 0) + 1
        else:
            other.append(a)
    extra = [i for i in range(n, len(mine)) if mine[i]] if tail_zero else []      # something assembled beyond the reference?
    lines = []
    for x, y in runs(other):
        lines.append(f'      OTHER {x:04X}-{y:04X} ({y - x + 1}) ref={rel[x - base:x - base + 8].hex()} ours={mine[x - base:x - base + 8].hex()}')
    if extra:
        lines.append(f'      OTHER: {len(extra)} non-zero bytes of ours after the end of the reference ({base + extra[0]:04X}..)')
    head = f'{title:36} {"IDENTICAL" if not diffs else f"{len(diffs)} differing"} ({n} B)'
    if expl:
        head += '  explained: ' + ', '.join(f'{k} {v}' for k, v in sorted(expl.items()))
    bad = len(other) + len(extra)
    if bad:
        head += f'  UNEXPLAINED {bad}'
    return len(diffs), bad, '\n'.join([head] + lines)


def main():
    report, bad = [], 0

    # ------------------------------------------------------------- game
    out, regs, syms = asm('game')
    info, ref = z80snap.read(os.path.join(ASM, '4.Z80'))
    lst = z80snap.symbols(os.path.join(ASM, '4.LST'))
    pages = {n: rd(out, f'page{n}.bin') for n in range(8)}
    base = {5: 0x4000, 2: 0x8000}
    known = {n: {} for n in range(8)}
    for k, pg, a, n in regs:
        for i in range(a, a + n):
            known[pg].setdefault(i, k)
    names = {0: 'page 0 (#C000)', 1: 'page 1 (#C000)', 2: 'page 2 (#8000)', 3: 'page 3 (#C000)', 4: 'page 4 (#C000)',
             5: 'page 5 (#4000)', 6: 'page 6 (#C000)', 7: 'page 7 (#C000)'}
    for p in (5, 2, 0, 1, 3, 4, 6, 7):
        t, o, txt = compare('game ' + names[p] + ' vs 4.Z80', ref[p], pages[p], base.get(p, 0xC000), known[p], tail_zero=False)
        report.append(txt)
        bad += o
    tot = [k for k, (a, w) in lst.items() if w.startswith(('Main', 'Pg'))]
    miss = [k for k in tot if syms.get(k) != lst[k][0]]
    report.append(f'game labels vs 4.LST: {len(tot) - len(miss)} of {len(tot)} equal' + (f', DIFFER: {miss[:8]}' if miss else ''))
    bad += len(miss)
    pc = syms.get('JP_ST')
    report.append(f'game entry point: ours JP_ST=#{pc:04X}, snapshot PC=#{info["pc"]:04X}' + ('' if pc == info['pc'] else '  UNEXPLAINED 1'))
    bad += pc != info['pc']
    report.append(f'      (DEFR regions: {sum(1 for r in regs if r[0] == "DEFR")}, {sum(r[3] for r in regs if r[0] == "DEFR")} bytes; '
                  f'UNDEF "DEFB ?" regions: {sum(1 for r in regs if r[0] == "UNDEF")}, {sum(r[3] for r in regs if r[0] == "UNDEF")} bytes)')

    # ------------------------------------------------------------- start1
    out, regs, syms = asm('start1')
    lst = z80snap.symbols(os.path.join(ASM, '4&START1.LST'))
    cls = {}
    for k, pg, a, n in regs:
        for i in range(a, a + n):
            cls[i] = k
    main_bin = rd(out, 'main.bin')
    ref = rd(V1, '4&START1.B00')
    t, o, txt = compare('start1 B00 (boot, #5D25)', ref, main_bin[:0x6200 - 0x5D25], 0x5D25, cls)
    report.append(txt); bad += o
    ref = rd(V1, '4&START1.B01')
    t, o, txt = compare('start1 B01 (#6200)', ref, main_bin[0x6200 - 0x5D25:], 0x6200, cls)
    report.append(txt); bad += o
    for n, pg, b in ((2, 1, 0xC000), (3, 3, 0xC000), (4, 4, 0xC000), (5, 6, 0xC000), (6, 7, 0xDB00)):
        ref = rd(V1, f'4&START1.B0{n}')
        t, o, txt = compare(f'start1 B0{n} (page {pg} #{b:04X})', ref, rd(out, f'page{pg}.bin')[b - 0xC000:], b)
        report.append(txt); bad += o
        if n <= 5:
            u = lpz.unpack(rd(V1, f'4&START1.LP{n}'))
            report.append(f'      LP{n} (XLPZ of B0{n}) unpacks to {len(u)} B: ' + ('equal to B0%d' % n if u == ref else 'DIFFERENT  UNEXPLAINED 1'))
            bad += u != ref
    old = {}
    for l in open(os.path.join(ASM, '4&START1.LST'), 'rb').read().decode('cp866').splitlines():
        m = re.match(r'	(\S+)\s+#([0-9A-F]+)\s+\d+$', l)
        if m:
            old[m.group(1)] = int(m.group(2), 16)
    miss = [k for k, a in old.items() if syms.get(k, syms.get(k + '_')) != a]      # a, e, WORD: renamed by a80conv (sjasmplus keywords)
    report.append(f'start1 labels vs 4&START1.LST: {len(old) - len(miss)} of {len(old)} equal' + (f', DIFFER: {miss[:8]}' if miss else ''))
    bad += len(miss)
    report.append(f'start1 entry point: ours S=#{syms["S"]:04X}, LST start address #5EFE' + ('' if syms['S'] == 0x5EFE else '  UNEXPLAINED 1'))
    bad += syms['S'] != 0x5EFE

    # ------------------------------------------------------------- final
    out, regs, syms = asm('final')
    cls = {}
    for k, pg, a, n in regs:
        for i in range(a, a + n):
            cls[i] = k
    ref = rd(V1, 'FINALCUT', '4&FINAL.B00')
    fnt = rd(ROOT, 'work', 'assets_faithful', 'data', '4font.fnt')
    a0 = syms['iFNT']
    old = ref[a0 - 0x6F00:a0 - 0x6F00 + len(fnt)]
    dinfo, dpages = z80snap.read(os.path.join(ARC, '_DEMO', 'BR2DEMO.000', 'BR2DM000.Z80'))
    proof = any(old in pg_ for pg_ in dpages.values())
    if proof:
        for i in range(a0, a0 + len(fnt)):
            cls.setdefault(i, 'FONT')
    t, o, txt = compare('final B00 (#6F00)', ref, rd(out, 'main.bin'), 0x6F00, cls)
    report.append(txt); bad += o
    report.append(f'      FONT: the font inside B00 ({len(fnt)} B at #{a0:04X}) is {"found in" if proof else "NOT found in"} BR2DM000.Z80 (demo v0.00)')
    ref = rd(V1, 'FINALCUT', '4&FINAL.B01')
    t, o, txt = compare('final B01 (page 1 #C000)', ref, rd(out, 'page1.bin'), 0xC000)
    report.append(txt); bad += o

    # ---- author's disk image vs the released BR2DISK1.TRD (information, not counted)
    D = rd(V1, 'DISK1.BIN')
    fdi = rd(ARC, 'UKV', '401.FDI')
    off = int.from_bytes(fdi[10:12], 'little')
    report.append('UKV/401.FDI payload == VDISK01/DISK1.BIN: ' + str(fdi[off:off + len(D)] == D))
    trd = rd(ROOT, 'reference', 'zxart', 'x_BR2DISK1', 'BR2DISK1.TRD')
    for n in ('4&START1.B06', '4&START1.LP2', '4&START1.LP3', '4&START1.LP4', '4&START1.LP5', 'FINALCUT/4&FINAL.B00', 'FINALCUT/4&FINAL.B01'):
        report.append(f'released BR2DISK1.TRD contains {n} byte-identical: {rd(V1, *n.split("/")) in trd}')
    b = rd(V1, '4&START1.B01')
    k = trd.find(b[:300])
    t = trd[k:k + len(b)] if k >= 0 else b''
    nd = sum(1 for i in range(len(b)) if b[i] != t[i]) if t else -1
    report.append(f'released BR2DISK1.TRD: 4&START1.B01 differs from the archive in {nd} bytes (newer intro/instruction, from #7924)')

    print('\n'.join(report))
    print(f'\nUNEXPLAINED {bad}')
    return bad


if __name__ == '__main__':
    sys.exit(1 if main() else 0)
