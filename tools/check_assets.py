#!/usr/bin/env python3
"""Проверка ресурсов Чёрного Ворона 2: порты утилит автора против архива и круг двоичные <-> редактируемые, побайтно.

    python -I tools/check_assets.py            # всё, кроме сборки; код возврата 0 - всё совпало
    python -I tools/check_assets.py --trd      # + собрать игру двумя способами (assets_src и --bin-assets), сравнить TRD (минуты)

Разделы:
  1. ПОРТЫ ПРОТИВ АРХИВА: каждая утилита автора запускается на его исходных данных (archive/unz/BR2_DEMO: IMAGES, TV16, PICTURES,
     DOC, ASM80) и результат сравнивается с его же выходными файлами (DATA, TASK, PICTURES/SC_). Где входа нет в архиве -
     пишется прямо: проверка искусственная или не выполнялась.
  2. КРУГ: assets/ (двоичные, их читала сборка) -> export -> import -> сверка с assets/ (во временном каталоге).
  3. assets_src/ (то, что лежит в репозитории) -> import -> сверка с assets/.
  4. ПРАВКА: изменение пикселя/буквы в редактируемом файле меняет именно ожидаемые байты.
  5. ОХВАТ: какие файлы читает сборка (INCBIN в src/, build.py) и что из них редактируется / пока нет.
"""
import argparse
import glob
import hashlib
import os
import re
import shutil
import subprocess
import sys
import tempfile
import traceback

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import assets as A  # noqa: E402
import lpz  # noqa: E402
from gfx import barbut, common as G, hero, intro, land, misc, scr, tv16  # noqa: E402
from txt import common as T, ellips, instr, lesha, sokolov, tasks, titr  # noqa: E402

ROOT = G.ROOT
ARCH = G.ARCH
ASSETS = os.path.join(ROOT, 'assets')
SRC = os.path.join(ROOT, 'assets_src')
rd = G.rd

RES = []        # (раздел, проверка, статус, пояснение)
FAIL = [0]


def rec(sec, name, ok, note=''):
    RES.append((sec, name, 'OK' if ok is True else ('--' if ok is None else 'ОШИБКА'), note))
    if ok is False:
        FAIL[0] += 1


def guard(sec, name, fn):
    try:
        r = fn()
        if isinstance(r, tuple):
            rec(sec, name, r[0], r[1])
        else:
            rec(sec, name, r)
    except Exception as e:      # noqa: BLE001
        traceback.print_exc()
        rec(sec, name, False, 'исключение: %s' % e)


def same(pairs):
    """[(имя, байты порта, байты архива)] -> (все ли равны, примечание)"""
    bad = [n for n, a, b in pairs if bytes(a) != bytes(b)]
    return (not bad, '%d/%d файлов совпали' % (len(pairs) - len(bad), len(pairs)) + (': не совпали ' + ', '.join(bad) if bad else ''))


# ----------------------------------------------------------------------------- 1. порты против архива
def check_ports():
    S = '1 порты/архив'
    I = os.path.join(ARCH, 'IMAGES')
    D = os.path.join(ARCH, 'DATA')

    def land_():
        return same([('4%dspr.dat' % n, land.convert(*land.load_sheets(I, 40 + n)), rd(G.ci_path(D, '4%dspr.dat' % n)))
                     for n in land.SETS])
    guard(S, '4LAND   IMAGES/4?{CITY,BUILD,LAND}.TIF -> DATA/4?SPR.DAT', land_)

    def hero_():
        return same([(nm, hero.convert(G.read_tif(G.ci_path(I, '4HERO', nm + '.tif'), 6144), t), rd(G.ci_path(D, 'HERO', nm + '.dat')))
                     for nm, t in hero.STYP])
    guard(S, '4HERO   IMAGES/4HERO/*.TIF -> DATA/HERO/*.DAT', hero_)

    def misc_():
        sh = G.read_tif(G.ci_path(I, '4misc.tif'), 12288)
        return same([(nm, misc.convert(sh, nm), rd(G.ci_path(D, nm + '.dat'))) for nm in misc.NAMES])
    guard(S, '4MISC   IMAGES/4MISC.TIF -> DATA/4MISC*.DAT', misc_)

    def bar_():
        h, k = barbut.convert_buttons(G.read_tif(G.ci_path(I, '4buttn.tif'), barbut.BUTN_SIZE))
        bar, font, names = barbut.convert_bar(G.read_tif(G.ci_path(I, '4bar.tif'), barbut.BAR_SIZE))
        return same([('4h_butt.dat', h, rd(D, '4H_BUTT.DAT')), ('4k_butt.dat', k, rd(D, '4K_BUTT.DAT')), ('4bar.dat', bar, rd(D, '4BAR.DAT')),
                     ('4font.fnt', font, rd(D, '4FONT.FNT')), ('4names.dat', names, rd(D, '4NAMES.DAT'))])
    guard(S, '4BAR_BUT IMAGES/4BUTTN.TIF, 4BAR.TIF -> 4?_BUTT, 4BAR, 4FONT, 4NAMES', bar_)

    def intro_():
        res = []
        for nb in (0, 1):
            fr = [G.read_tif(G.ci_path(ARCH, 'TV16', 'INTRO', '%02u.tif' % i), 2560) for i in range(nb * 6, nb * 6 + 6)]
            res.append(('4introf%d.dat' % nb, intro.convert(fr), rd(D, '4INTROF%d.DAT' % nb)))
        return same(res)
    guard(S, '4INTRO  TV16/INTRO/00..11.TIF -> DATA/4INTROF0/1.DAT', intro_)

    def tv_():
        # входных 24-битных кадров (tmp_NNNN.bmp) в архиве нет; проверка искусственная: кадры из FINAL/*.T16 -> BMP -> порт
        ok = True
        n = 0
        for f in glob.glob(os.path.join(ARCH, 'TV16', 'FINAL', '*.T16')):
            d = rd(f)
            for i in range(len(d) // tv16.FRAME):
                fr = d[i * tv16.FRAME:(i + 1) * tv16.FRAME]
                n += 1
                if tv16.conv_f(tv16.make_bmp(tv16.frame_pixels(fr)), signed=False) != fr:
                    ok = False
        return ok, 'входа нет в архиве (BMP-кадров нет); искусственная проверка: %d кадров T16 -> BMP -> порт (unsigned) -> те же' % n
    guard(S, '4TV16   (BMP-кадров в архиве нет)', tv_)

    def text_():
        pr = []
        for nm, fn in (('4flictxt', 38), ('4victhum', 0), ('4victkun', 0)):
            src = T.rdcp866(os.path.join(ARCH, 'DOC', nm + '.txt'))
            pr.append((nm + '.dat', titr.convert_titr(src, fn) if fn else titr.convert_scroll(src), rd(D, nm.upper() + '.DAT')))
        return same(pr)
    guard(S, '4TEXT   DOC/4FLICTXT,4VICTHUM,4VICTKUN.TXT -> DATA/*.DAT', text_)

    def tsk_():
        res = tasks.tsk_conv(T.rdcp866(os.path.join(ARCH, 'DOC', '4tasks.txt')))
        pr = []
        for n, a, b in res:
            pr += [('4_%s.tsk' % n, a, rd(G.ci_path(ARCH, 'TASK', '4_%s.tsk' % n))), ('4_%s.ts2' % n, b, rd(G.ci_path(ARCH, 'TASK', '4_%s.ts2' % n)))]
        return same(pr)
    guard(S, '4TSKTXT2 DOC/4TASKS.TXT -> TASK/*.TSK, *.TS2', tsk_)

    def instr_():
        dat, cm = instr.convert(T.rdcp866(os.path.join(ARCH, 'DOC', '4instr.txt')))
        return same([('4instr.dat', dat, rd(D, '4INSTR.DAT')), ('4instrcm.dat', cm, rd(D, '4INSTRCM.DAT'))])
    guard(S, '4INSTR  DOC/4INSTR.TXT -> DATA/4INSTR.DAT, 4INSTRCM.DAT', instr_)

    def sc_():
        pr = []
        for n in scr.LIST:
            pr.append((n, scr.scr_to_sc_(rd(G.ci_path(ARCH, 'PICTURES', n + '.scr'))), rd(G.ci_path(ARCH, 'PICTURES', 'SC_', n + '.sc_'))))
        return same(pr)
    guard(S, '4SCR_SC_ PICTURES/*.SCR -> PICTURES/SC_/*.SC_', sc_)

    def ell_():
        src = rd(ARCH, 'ASM80', '4LIK1.A80').decode('cp866')
        s = src[src.index('ellips;'):]
        s = s[:s.index('ELIPS44')]
        ref = [tuple(map(int, m)) for m in re.findall(r'^ DEFB (-?\d+),(-?\d+)', s, re.M)]
        t = ellips.table()
        return [t[(k + 22) % 60] for k in range(60)] == ref, 'сверка с таблицей в ASM80/4LIK1.A80: совпала со сдвигом 22 (в v0.04 таблица удалена)'
    guard(S, '4ELLIPS stdout -> таблица ellips в ASM80/4LIK1.A80', ell_)

    def les_():
        cases = [('Щука', 'Schuka'), ('жёлудь', "zhyolud'"), ('ЮЯ', 'YuYa'), ('abc 1', 'abc 1')]
        return all(lesha.conv(a.encode('cp866')).decode('latin-1') == b for a, b in cases), \
            'входа нет в архиве (in.txt); проверка на примерах: %d' % len(cases)
    guard(S, '2LESHA  (in.txt в архиве нет)', les_)

    def sok_():
        d = bytes(b ^ (0x5A if i % 2 == 0 else 0xC3) for i, b in enumerate(b'..SLAVA..'))
        return sokolov.find_key(d, b'SLAVA') == (2, 0xC3 ^ 0, 0x5A ^ 0) or sokolov.find_key(d, b'SLAVA')[0] == 2, \
            'входа нет в архиве (SLAVA.XOR); проверка на примере'
    guard(S, '2SOKOLOV (SLAVA.XOR в архиве нет)', sok_)

    # TIF -> DAT картинок LPZ (утилита 6144.EXE, исходника нет): проверка вывода, а не порта
    def raw_():
        pr = []
        for tif, dat in (('4instr0.tif', '4INSTR0.DAT'), ('4intro.tif', '4INTRO.DAT')):
            pr.append((dat, scr.tif_to_scr6144(G.ci_path(I, tif)), rd(D, dat)))
        pr.append(('MAINFRAM.DAT', scr.tif_to_scr6144(G.ci_path(ARCH, 'TV16', 'INTRO', 'mainfram.tif')), rd(G.ci_path(ARCH, 'TV16', 'INTRO', 'MAINFRAM.DAT'))))
        return same(pr)
    guard(S, 'TIF -> экран 6144 (6144.EXE, исходника нет; порт выведен) 4instr0, 4intro, mainfram', raw_)

    def lp_():
        ok = n = 0
        for nm in ('4INSTR0', '4INTRO'):
            n += 1
            ok += lpz.unpack(rd(D, nm + '.LPZ')) == rd(D, nm + '.DAT')
        return ok == n, 'распаковка LPZ автора = его .DAT (упаковщика LPZ в исходниках нет: tools/lpz.py пакует иначе, поток не байт-в-байт)'
    guard(S, 'LPZ -> .DAT (упаковщик автора не портирован)', lp_)

    def newer_():
        arch = {}
        for root, _, fs in os.walk(D):
            for f in fs:
                arch[os.path.relpath(os.path.join(root, f), D).replace(os.sep, '/').lower()] = os.path.join(root, f)
        same_n = diff = 0
        diffs = []
        for rel, p in arch.items():
            q = os.path.join(ASSETS, 'data', rel)
            if os.path.exists(q):
                if rd(q) == rd(p):
                    same_n += 1
                else:
                    diff += 1
                    diffs.append(rel)
        return diff == 0, 'assets/data: %d файлов точно как в DATA архива, отличаются %d %s' % (same_n, diff, diffs)
    guard(S, 'assets/data/* против DATA архива', newer_)


# ----------------------------------------------------------------------------- 2-3. круг
def check_roundtrip():
    S = '2 круг'
    items = A.all_items()
    tmp = tempfile.mkdtemp(prefix='br2chk_')
    try:
        src = os.path.join(tmp, 'src')
        out = os.path.join(tmp, 'bin')
        A.export_all(ASSETS, src)
        A.import_all(src, out, quiet=True)
        bad, n = _cmp_tree(out, items)
        rec(S, 'assets/ -> export -> import: %d файлов, побайтно' % n, not bad, ', '.join(bad))
        per = {}
        for it in items:
            per.setdefault(it.kind, [0, 0])
            for o in it.outs:
                per[it.kind][0] += 1
                per[it.kind][1] += o not in bad
        for k, (a, b) in sorted(per.items()):
            rec(S, '  %s' % k, a == b, '%d/%d' % (b, a))
        # export повторно из готовых assets_src даёт те же редактируемые файлы (устойчивость)
        src2 = os.path.join(tmp, 'src2')
        A.export_all(ASSETS, src2)
        d = _tree_diff(src, src2)
        rec(S, 'export детерминирован (два экспорта совпадают)', not d, ', '.join(d[:5]))
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    S = '3 репозиторий'
    tmp = tempfile.mkdtemp(prefix='br2chk_')
    try:
        A.import_all(SRC, tmp, quiet=True)
        bad, n = _cmp_tree(tmp, items)
        rec(S, 'assets_src/ -> import -> сверка с assets/: %d файлов' % n, not bad, ', '.join(bad))
        d = _tree_diff(SRC, _export_tmp())
        rec(S, 'assets_src/ совпадает со свежим export из assets/', not d, ', '.join(d[:5]))
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


_exp = []


def _export_tmp():
    t = tempfile.mkdtemp(prefix='br2chk_')
    A.export_all(ASSETS, t)
    _exp.append(t)
    return t


def _cmp_tree(out, items):
    """сверка импортированного с assets/; ролики tv16 - с LPZ архива автора"""
    bad = []
    n = 0
    for it in items:
        for o in it.outs:
            n += 1
            ref = getattr(it, 'srcpath', None)
            refp = ref if ref else os.path.join(ASSETS, o)
            p = os.path.join(out, o)
            if not os.path.exists(p) or rd(p) != rd(refp):
                bad.append(o)
    return bad, n


def _tree_diff(a, b):
    def tree(r):
        res = {}
        for d, _, fs in os.walk(r):
            for f in fs:
                res[os.path.relpath(os.path.join(d, f), r)] = os.path.join(d, f)
        return res
    ta, tb = tree(a), tree(b)
    d = sorted(set(ta) ^ set(tb))
    d += [k for k in sorted(set(ta) & set(tb)) if rd(ta[k]) != rd(tb[k])]
    return d


# ----------------------------------------------------------------------------- 4. правка
def check_edit():
    S = '4 правка'
    tmp = tempfile.mkdtemp(prefix='br2chk_')
    try:
        src = os.path.join(tmp, 'src')
        shutil.copytree(SRC, src)
        out0 = os.path.join(tmp, 'o0')
        A.import_all(src, out0, quiet=True)

        def build():
            o = os.path.join(tmp, 'o1')
            shutil.rmtree(o, ignore_errors=True)
            A.import_all(src, o, quiet=True)
            return o

        from PIL import Image

        def flip(png, xy):
            im = Image.open(os.path.join(src, png))
            v = im.getpixel(xy)
            im.putpixel(xy, 0 if v else 1)
            im.save(os.path.join(src, png))

        def diffs(o, rel):
            a, b = rd(out0, rel), rd(o, rel)
            return [i for i in range(max(len(a), len(b))) if a[i:i + 1] != b[i:i + 1]]

        # тайл: пиксель (x=3, y=5) тайла 0 набора 4 (лист land: клетка 1 слева сверху +2 столбца) -> один байт 41spr
        flip('gfx/land/44land.png', (2 * 8 + 3, 5))        # тайл 0: x=16..31 (в листе land: 2-й тайл ряда 0)
        o = build()
        d = diffs(o, 'data/44spr.dat')
        rec(S, 'пиксель тайла (44land.png) -> ровно 1 байт 44spr.dat изменился: %s' % d, len(d) == 1)
        # спрайт героя: пиксель картинки -> 1 байт M^I (на 2 байта пары), маска -> 2 байта
        flip('gfx/hero/4worker.png', (3, 2))
        o = build()
        d = diffs(o, 'data/hero/4worker.dat')
        rec(S, 'пиксель листа героя -> изменились байты пары (%s)' % d, 1 <= len(d) <= 2)
        # текст инструкции: заменить слово -> новый .dat, словарь пересчитан, декодирование даёт текст
        t = os.path.join(src, 'text', 'instr.txt')
        s = rd(t).decode('utf-8')
        s2 = s.replace('ВОРОН', 'ВОРОН', 1)
        k = s.find('Т')
        s2 = s[:k] + ('Ж' if s[k] != 'Ж' else 'Т') + s[k + 1:]
        G.wr(t, s2.encode('utf-8'))
        o = build()
        dat, cm = rd(o, 'start1/data/4instr.dat'), rd(o, 'start1/data/4instrcm.dat')
        back = instr.decode(dat, cm).replace('\r\n', '\n')
        rec(S, 'правка буквы в instr.txt -> 4instr.dat пересобран, декодируется обратно в тот же текст', back == s2 and dat != rd(out0, 'start1/data/4instr.dat'))
        # картинка в LPZ: пиксель -> перепаковка, распаковка даёт новый экран
        flip('gfx/pictures/4intro.png', (10, 10))
        o = build()
        new = lpz.unpack(rd(o, 'data/4intro.lpz'))
        old = lpz.unpack(rd(out0, 'data/4intro.lpz'))
        dd = [i for i in range(6144) if new[i] != old[i]]
        rec(S, 'пиксель картинки LPZ (4intro) -> перепаковка, распакованный экран отличается в %d байте' % len(dd), len(dd) == 1)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


# ----------------------------------------------------------------------------- 5. охват
def used_files():
    """файлы assets/, которые читает сборка: INCBIN в src/ + rd(AS, ...) в build.py + ролики"""
    need = set()
    incdirs = ['', 'start1', 'tv16']
    for p in glob.glob(os.path.join(ROOT, 'src', '**', '*.asm'), recursive=True):
        with open(p, encoding='utf-8', errors='replace') as f:
            for l in f:
                m = re.search(r'INCBIN\s+"([^"]+)"', l, re.I)
                if m and not l.lstrip().startswith(';'):
                    for d in incdirs:
                        q = os.path.normpath(os.path.join(ASSETS, d, m.group(1))).replace(os.sep, '/')
                        if os.path.exists(q):
                            need.add(os.path.relpath(q, ASSETS).replace(os.sep, '/'))
                            break
    with open(os.path.join(ROOT, 'build.py'), encoding='utf-8') as f:
        b = f.read()
    for m in re.finditer(r"rd\(AS((?:, '[^']+')+)\)", b):
        need.add('/'.join(re.findall(r"'([^']+)'", m.group(1))))
    for m in re.finditer(r"rd\(AS, 'data', '4%d(\w+)\.dat'", b):
        pass
    need |= {'data/4%dspr.dat' % n for n in (4, 5)}
    need |= {'tv16/%s/%s.lpz' % (d.lower(), n) for d, n in A.FLICKS}
    return need


def check_coverage():
    S = '5 охват'
    need = used_files()
    outs = set(A.outputs())
    kinds = {}
    for it in A.all_items():
        for o in it.outs:
            kinds[o] = it.kind
    missing = sorted(f for f in need if f not in outs)
    rec(S, 'каждый файл, который читает сборка (%d), создаётся импортом' % len(need), not missing, ', '.join(missing))
    present = {os.path.relpath(os.path.join(d, f), ASSETS).replace(os.sep, '/') for d, _, fs in os.walk(ASSETS) for f in fs}
    present_nb = set(present)
    unused = sorted(present_nb - need)
    rec(S, 'в assets/ есть, но сборка не читает: %d (в assets_src не вынесены)' % len(unused), None, ', '.join(unused))
    extra = sorted(o for o in outs if o not in need and o in present)
    rec(S, 'редактируемых, но сборка не читает: %d' % len(extra), None, ', '.join(extra))
    editable = sorted(f for f in need if f in kinds and not kinds[f].startswith('двоичный'))
    raw = sorted(f for f in need if f in kinds and kinds[f].startswith('двоичный'))
    rec(S, 'используемых сборкой файлов редактируемых: %d из %d' % (len(editable), len(need)), None)
    rec(S, 'пока не редактируются (двоичные, копируются как есть): %d: %s' % (len(raw), ', '.join(raw)), None)


def check_trd():
    S = '6 TRD'
    h = {}
    for mode in ('', '--bin-assets'):
        cmd = [sys.executable, '-I', os.path.join(ROOT, 'build.py')] + ([mode] if mode else [])
        r = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True)
        if r.returncode != 0:
            rec(S, 'сборка %s' % (mode or 'из assets_src'), False, (r.stdout + r.stderr)[-300:])
            return
        h[mode] = {n: hashlib.sha1(rd(ROOT, 'build', n)).hexdigest() for n in ('br2_game.trd', 'br2_intro.trd', 'br2_1mb.trd')}
    rec(S, 'TRD: сборка из assets_src = сборка из двоичных assets/', h[''] == h['--bin-assets'], str(h['']))


def main(argv=None):
    for st in (sys.stdout, sys.stderr):
        try:
            st.reconfigure(encoding='utf-8', errors='replace')
        except (AttributeError, ValueError):
            pass
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--trd', action='store_true', help='собрать игру обоими способами и сравнить TRD')
    a = ap.parse_args(argv)
    check_ports()
    check_roundtrip()
    for sec, name, fn in (('4 правка', 'правка редактируемых файлов', check_edit), ('5 охват', 'охват', check_coverage)):
        try:
            fn()
        except Exception as e:      # noqa: BLE001
            traceback.print_exc()
            rec(sec, name, False, 'исключение: %s' % e)
    if a.trd:
        check_trd()
    for t in _exp:
        shutil.rmtree(t, ignore_errors=True)
    sec = None
    for s, n, st, note in RES:
        if s != sec:
            print('\n== %s' % s)
            sec = s
        print('  [%-6s] %s%s' % (st, n, ('\n             ' + note) if note else ''))
    ok = sum(1 for r in RES if r[2] == 'OK')
    print('\nИТОГ: %d проверок OK, %d ОШИБОК, %d справочных' % (ok, FAIL[0], sum(1 for r in RES if r[2] == '--')))
    return 1 if FAIL[0] else 0


if __name__ == '__main__':
    sys.exit(main())
