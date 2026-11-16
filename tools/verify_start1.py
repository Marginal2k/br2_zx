#!/usr/bin/env python3
"""start1 of the released BR2DISK1.TRD: work/src_v04/start1 (the archive source + the newer data of B01) must give B01 of the TRD byte for byte
(the other B0x as in the archive: tools/verify_original.py).   python tools/verify_start1.py     -> UNEXPLAINED N"""
import os, re, subprocess, sys
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'tools'))
import shutil
SJ = shutil.which('sjasmplus') or r'C:\sjasmplus\sjasmplus.exe'
TREE = os.path.join(ROOT, 'work', 'src_v04', 'start1')
OUT = os.path.join(ROOT, 'build', 'v04', 'start1')
V1 = os.path.join(ROOT, 'archive', 'unz', 'BR2_DEMO', 'VDISK01')
TRD = os.path.join(ROOT, 'reference', 'zxart', 'x_BR2DISK1', 'BR2DISK1.TRD')
B01_OFF, B01_LEN = 9472, 18711      # sector of the loader table (disk1.asm) ; ends with DEFM "This is the End" + NOP


def rd(*p):
    return open(os.path.join(*p), 'rb').read()


def main():
    os.makedirs(OUT, exist_ok=True)
    cmd = [SJ, '--nologo', '--msg=err', '--sym=main.sym', '--lst=main.lst', '-I', TREE, '-I', os.path.join(ROOT, 'work', 'src_faithful', 'lib'),
           '-I', os.path.join(ROOT, 'work', 'src_v04', 'lib'), '-I', os.path.join(ROOT, 'work', 'assets_faithful'), '-I', os.path.join(ROOT, 'work', 'assets_v04'), os.path.join(TREE, 'top.asm')]
    r = subprocess.run(cmd, cwd=OUT, capture_output=True, text=True)
    txt = r.stdout + r.stderr
    print('sjasmplus errors:', len(re.findall('error', txt)))
    regs = [(int(pg), int(a, 16), int(n)) for k, pg, a, n in re.findall(r'(DEFR|UNDEF) (\d+) 0x([0-9A-F]+) (\d+)', txt)]
    mask = set()
    for pg, a, n in regs:
        if pg == 5 or True:
            mask |= {a + i for i in range(n)}
    main_bin = rd(OUT, 'main.bin')
    mine = main_bin[0x6200 - 0x5D25:][:B01_LEN]
    ref = rd(TRD)[B01_OFF:B01_OFF + B01_LEN]
    bad = [i for i in range(max(len(mine), len(ref))) if i >= len(mine) or i >= len(ref) or mine[i] != ref[i]]
    unexpl = [i for i in bad if (0x6200 + i) not in mask]
    print('B01 (#6200): %d bytes (TRD %d), differing %d, assembler junk (DEFR/UNDEF) %d, UNEXPLAINED %d' % (len(mine), len(ref), len(bad), len(bad) - len(unexpl), len(unexpl)))
    if unexpl:
        print('  first at', ', '.join('%04X' % (0x6200 + i) for i in unexpl[:8]))
    # the other blocks and B00 as in the archive
    tot = len(unexpl)
    b00 = rd(V1, '4&START1.B00')
    mm = [i for i in range(len(b00)) if main_bin[i] != b00[i] and (0x5D25 + i) not in mask]
    print('B00 (#5D25) equal to the archive: %s (%d unexplained)' % (not mm, len(mm)))
    tot += len(mm)
    for n, pg, b in ((2, 1, 0xC000), (3, 3, 0xC000), (4, 4, 0xC000), (5, 6, 0xC000), (6, 7, 0xDB00)):
        a_ = rd(V1, '4&START1.B0%d' % n)
        m_ = rd(OUT, 'page%d.bin' % pg)[b - 0xC000:]
        bd = [i for i in range(len(a_)) if m_[i] != a_[i] and (b + i) not in mask]
        print('B0%d equal to the archive: %s (%d unexplained)' % (n, not bd, len(bd)))
        tot += len(bd)
    print()
    print('UNEXPLAINED', tot)
    return tot


if __name__ == '__main__':
    sys.exit(1 if main() else 0)
