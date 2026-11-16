#!/usr/bin/env python3
"""Чёрный Ворон 2 (демо v0.04): исходники src/ + assets/ -> диски TR-DOS без защиты.

    python build.py            # всё с нуля (SJASMPLUS=путь к sjasmplus); ресурсы - из assets_src/ (PNG, тексты, CSV)
    python build.py --bin-assets   # ресурсы - из двоичных assets/ (как до появления assets_src/; результат тот же)

Ресурсы: по умолчанию сборка сначала превращает редактируемые исходники assets_src/ в двоичные ресурсы build/assets/
(tools/assets.py import) и берёт все INCBIN и файлы оттуда: assets_src/ - единственный источник, править нужно его
(docs/TOOLS.md). Проверка, что assets_src/ даёт те же байты, что assets/: python tools/check_assets.py.

Результат (build/):  br2_intro.trd (диск 1, 640 КБ), br2_game.trd (диск игры, 640 КБ), br2_1mb.trd (всё на одном диске 1 МБ).
Любое предупреждение sjasmplus - ошибка сборки. Подробно - docs/NOTES.md.

Положение файлов игры (boot, загрузчик, страницы, ресурсы, сохранения) одинаково на диске игры и на диске 1 МБ: поэтому игра
собирается один раз, а загрузчик диска 1 знает, где лежат файлы игры на диске игры (game_layout.inc).
"""
import os
import re
import shutil
import struct
import subprocess
import sys
import time
import uuid

# сообщения сборки по-русски: без этого в консоли cp866/cp1251 текст sys.exit() терялся молча (код 1 без вывода)
for _s in (sys.stdout, sys.stderr):
    try:
        _s.reconfigure(encoding='utf-8', errors='replace')
    except (AttributeError, ValueError):
        pass

ROOT = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(ROOT, 'tools'))
from trd import Trd, basic_program, SPT  # noqa: E402

B = os.path.join(ROOT, 'build')
SRC = os.path.join(ROOT, 'src')
AS = os.path.join(ROOT, 'assets')        # каталог двоичных ресурсов; по умолчанию main() ставит build/assets (из assets_src/)
ASSETS_BIN = os.path.join(ROOT, 'assets')
ASSETS_SRC = os.path.join(ROOT, 'assets_src')
SJ = os.environ.get('SJASMPLUS') or shutil.which('sjasmplus') or r'C:\sjasmplus\sjasmplus.exe'
ZX0 = os.path.join(ROOT, 'tools', 'bin', 'zx0.exe')
NSLOTS = 9              # слот 0 - быстрое сохранение, 1..8 - окно сохранения (Игра-001..008; SAVgam получает номер строки 1..8)
SLOTSEC = 54            # слот сохранения: сверяется с SLOTSEC из src/game/disk.asm
LDR_SECTORS = 6         # загрузчик: #6000..#65FF (одинаково на всех дисках: положение файлов игры тоже одинаково)
GAMEFILES = ['PG0', 'PG1', 'PG7', 'PG6', 'PG3', 'PG4', 'PG5A', 'PG5B']
RESNAMES = {1: 'land4a', 2: 'land4b', 3: 'land5a', 4: 'land5b', 5: 'butt_h', 6: 'butt_k', 7: 'bar', 8: 'lev_h', 9: 'lev_k', 10: 'menu', 11: 'mps'}


def rd(*p):
    with open(os.path.join(*p), 'rb') as f:
        return f.read()


def wr(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'wb' if isinstance(data, bytes) else 'w', **({} if isinstance(data, bytes) else {'newline': '\n', 'encoding': 'utf-8'})) as f:
        f.write(data)


def sjasm(src, out, incs, defs=()):
    """Сборка sjasmplus; любое предупреждение или ошибка - сборка падает. Возвращает таблицу символов."""
    os.makedirs(out, exist_ok=True)
    cmd = [SJ, '--nologo', '--msg=war', '--sym=main.sym', '--lst=main.lst'] + ['-D' + d for d in defs]
    for i in incs:
        cmd += ['-I', i.replace(os.sep, '/')]
    cmd.append(src.replace(os.sep, '/'))
    r = subprocess.run(cmd, cwd=out, capture_output=True, text=True)
    txt = r.stdout + r.stderr
    if r.returncode != 0 or re.search(r'warning|error', txt, re.I):
        sys.exit('sjasmplus: ошибка или предупреждение (%s):\n%s' % (src, txt))
    syms = {}
    with open(os.path.join(out, 'main.sym'), encoding='utf-8', errors='replace') as f:
        for l in f:
            m = re.match(r'(\S+):\s+EQU\s+0x([0-9A-Fa-f]+)', l)
            if m:
                syms[m.group(1)] = int(m.group(2), 16)
    return syms


_zcache = {}


def zx0(data):
    """блок диска: слово длины потока + поток ZX0"""
    key = bytes(data)
    if key not in _zcache:
        # своё (случайное) имя на каждый вызов и несколько попыток: Windows (антивирус) держит
        # только что удалённый файл, и zx0.exe через раз не мог создать выходной файл
        for attempt in range(5):
            tmp = os.path.join(B, 'zx0_%s.tmp' % uuid.uuid4().hex)
            wr(tmp, key)
            r = subprocess.run([ZX0, '-f', tmp, tmp + '.zx0'], capture_output=True, text=True)
            if r.returncode == 0:
                break
            time.sleep(0.2)
        else:
            sys.exit('zx0: ' + (r.stdout + r.stderr).strip())
        s = rd(tmp + '.zx0')
        for f in (tmp, tmp + '.zx0'):
            try:
                os.remove(f)
            except OSError:
                pass
        _zcache[key] = struct.pack('<H', len(s)) + s
    return _zcache[key]


def sectors(n):
    return (n + 255) // 256


def pad(d):
    return d + bytes(-len(d) % 256)


def write_layout(path, tab, savelin):
    t = ['F_LAND4 EQU 1', 'F_LAND5 EQU 3', 'F_BUTTH EQU 5', 'F_BUTTK EQU 6', 'F_BAR EQU 7', 'F_LEVH EQU 8', 'F_LEVK EQU 9',
         'F_MENU EQU 10', 'F_MPS EQU 11', 'NSLOTS EQU %d' % NSLOTS, 'SAVELIN EQU %d' % savelin, 'RESTAB']
    for n in range(1, 12):
        tr, sc, cnt = tab.get(n, (0, 1, 1))
        t.append('\tDEFB\t%d,%d,%d\t; файл %d (%s): дорожка, сектор, число секторов' % (tr, sc, cnt, n, RESNAMES[n]))
    wr(path, '\n'.join(t) + '\n')


# ------------------------------------------------------------------------------------------------ игра
def assemble_game():
    gd = os.path.join(B, 'game')
    if os.path.isdir(gd):
        shutil.rmtree(gd)
    os.makedirs(gd)
    incs = [os.path.join(SRC, 'game'), os.path.join(SRC, 'lib'), AS, gd]
    write_layout(os.path.join(gd, 'disk_layout.inc'), {}, 0)
    g = sjasm(os.path.join(SRC, 'game', 'game.asm'), gd, incs)
    P = {n: rd(gd, 'page%d.bin' % n) for n in range(8)}
    return gd, incs, g, P


def game_files(g, P, gd):
    """упакованные файлы страниц и ресурсов игры"""
    pg = {}
    for k, n in (('PG0', 0), ('PG1', 1), ('PG7', 7), ('PG6', 6), ('PG3', 3), ('PG4', 4)):
        pg[k] = zx0(P[n])
    pg['PG5A'], pg['PG5B'] = zx0(P[5][:0x2000]), zx0(P[5][0x2000:])
    t0 = g['BUF512'] - 0x8000
    v0, v1 = g['LEVVARS'] - 0x4000, g['zzzEND'] + 1 - 0x4000

    def level(p2, p5):             # три блока ZX0: MAP (#8000, 4096 байт), BUF512 (#B800, 512), переменные уровня (страница 5)
        return zx0(p2[:0x1000]) + zx0(p2[t0:t0 + 512]) + zx0(p5[v0:v1])
    lev_h = level(P[2], P[5])
    p2k, p5k = bytearray(P[2]), bytearray(P[5])
    p2k[:0x1000] = rd(AS, 'map', '4_4.map')[:0x1000]
    her = rd(AS, 'map', '4_4.her')
    p2k[t0 + 16:t0 + 16 + len(her)] = her
    p5k[g['COLOR'] - 0x4000] = 0x30     # параметры уровня кунгов из образа v0.04 (у людей #28)
    p5k[g['MASTER'] - 0x4000] = 1
    p5k[g['fsLAND'] - 0x4000] = 4
    lev_k = level(bytes(p2k), bytes(p5k))
    land = {n: rd(AS, 'data', '4%dspr.dat' % n) for n in (4, 5)}
    h = len(land[4]) // 2
    res = {1: zx0(land[4][:h]), 2: zx0(land[4][h:]), 3: zx0(land[5][:h]), 4: zx0(land[5][h:]),
           5: zx0(rd(AS, 'data', '4h_butt.dat')), 6: zx0(rd(AS, 'data', '4k_butt.dat')),
           7: rd(AS, 'data', '4bar.dat'), 8: lev_h, 9: lev_k, 10: rd(gd, 'menu.bin'),
           11: P[6][:128] + rd(AS, 'data', '4num_m4.bin')}   # MPsign: люди (4num_m5, как в нашей странице 6) | кунги
    for n in (1, 2, 3, 4, 5, 6, 8, 9):
        if len(res[n]) > 6144:
            sys.exit('файл %d не помещается в DSCR (READZ)' % n)
    return pg, res


def game_part(disk, pg, res, gd):
    """часть диска, одинаковая на диске игры и на 1 МБ: boot, загрузчик, файлы страниц, ресурсы, сохранения"""
    basic = basic_program([(10, 'CLEAR VAL "24575": RANDOMIZE USR VAL "15619": REM : LOAD "br2" CODE'),
                           (20, 'RANDOMIZE USR VAL "24576"')])
    disk.add_file('boot', 'B', basic, start=len(basic), length=len(basic))
    ldr_at = disk.alloc(LDR_SECTORS)
    ldr_idx = len(disk.files)
    disk.files.append(None)
    gtab = {}
    for i, k in enumerate(GAMEFILES):
        s = disk.add_file('g_' + k.lower(), 'C', pg[k], start=0)
        gtab[i + 1] = (s % SPT + 1, s // SPT, sectors(len(pg[k])))
    tab = {}
    for n in range(1, 12):
        s = disk.add_file(RESNAMES[n], 'C', res[n], start=0)
        tab[n] = (s // SPT, s % SPT + 1, sectors(len(res[n])))
    savelin = disk.alloc(NSLOTS * SLOTSEC)
    nm = b'saves   ' + b'C' + struct.pack('<HH', 0, NSLOTS * SLOTSEC * 256 & 0xFFFF)
    disk.files.append(nm + bytes([NSLOTS * SLOTSEC if NSLOTS * SLOTSEC < 256 else 255, savelin % SPT, savelin // SPT]))
    return ldr_at, ldr_idx, gtab, tab, savelin


def make_loader(g, gtab, defs=()):
    ld = os.path.join(B, 'loader')
    shutil.rmtree(ld, ignore_errors=True)
    os.makedirs(ld)
    lay = ['STARTR EQU 0x%04X' % g['STARTR']]
    for i, k in enumerate(GAMEFILES):
        lay.append('G_%s EQU %d' % (k, i + 1))
    lay.append('GTAB')
    for n in range(1, 9):
        s, t, c = gtab[n]
        lay.append('\tDEFB\t%d,%d,%d' % (s, t, c))
    wr(os.path.join(ld, 'game_layout.inc'), '\n'.join(lay) + '\n')
    sjasm(os.path.join(SRC, 'start1', 'loader_main.asm'), ld, [os.path.join(SRC, 'start1'), os.path.join(SRC, 'lib'), ld, AS], defs)
    data = rd(ld, 'loader.bin')
    if len(data) > LDR_SECTORS * 256:
        sys.exit('загрузчик %d байт, не более %d' % (len(data), LDR_SECTORS * 256))
    return pad(data)


def put_loader(disk, ldr_at, ldr_idx, ldr):
    disk.img[ldr_at * 256:ldr_at * 256 + len(ldr)] = ldr
    disk.files[ldr_idx] = b'br2     C' + struct.pack('<HH', 0x6000, len(ldr)) + bytes([LDR_SECTORS, ldr_at % SPT, ldr_at // SPT])



# ------------------------------------------------------------------------------------------------ диск 1
def flick_names():
    """(номер файла, имя) роликов 16..57: src/start1/flicks.txt (из таблицы F_DAT автора, 4&DISK1.A80)"""
    res = []
    for line in rd(ROOT, 'src', 'start1', 'flicks.txt').decode('utf-8').splitlines():
        line = line.split(';')[0].split()
        if line:
            res.append((int(line[0]), line[1]))
    return res


def tv16_file(name):
    for d in ('moves', 'final'):                   # ролики из ресурсов (assets_src/gfx/tv16 -> build/assets/tv16)
        p = os.path.join(AS, 'tv16', d, name.lower())
        if os.path.exists(p):
            return rd(p)
    for d in ('MOVES', 'FINAL'):                   # --bin-assets: двоичные ресурсы без роликов - берём из архива автора
        p = os.path.join(ROOT, 'archive', 'unz', 'BR2_DEMO', 'TV16', d)
        for f in os.listdir(p):
            if f.lower() == name.lower():
                return rd(p, f)
    sys.exit('нет ролика ' + name)


def assemble_intro_files():
    """файлы диска 1 (номера F_DAT): 0 заставка, 1 B01, 2..5 страницы (LPZ), 14/15 концовка, 16..57 ролики"""
    import lpz
    ld = os.path.join(B, 'intro')
    shutil.rmtree(ld, ignore_errors=True)
    os.makedirs(ld)
    wr(os.path.join(ld, 'disk1_layout.inc'), '\tDEFB\t1,1,1\n' * 58)
    wr(os.path.join(ld, 'game_layout.inc'), 'STARTR EQU 0xFF00\n' + ''.join('G_%s EQU %d\n' % (k, i + 1) for i, k in enumerate(GAMEFILES)) + 'GTAB\n' + '\tDEFB\t1,1,1\n' * 8)
    incs = [os.path.join(SRC, 'start1'), os.path.join(SRC, 'lib'), AS, os.path.join(AS, 'start1'), os.path.join(AS, 'tv16'), ld]
    s = sjasm(os.path.join(SRC, 'start1', 'intro_main.asm'), ld, incs, ['INTRO=1'])
    p6len = s['P6END'] - 0xC000
    files = {0: rd(ld, 'p7.bin'), 1: rd(ld, 'b01.bin'),
             2: rd(AS, 'start1', 'LP2'), 3: rd(AS, 'start1', 'LP3'), 4: rd(AS, 'start1', 'LP4'),
             5: lpz.pack(rd(ld, 'p6.bin')[:p6len])}
    fd = os.path.join(B, 'final')
    shutil.rmtree(fd, ignore_errors=True)
    os.makedirs(fd)
    sjasm(os.path.join(SRC, 'final', 'final_main.asm'), fd, [os.path.join(SRC, 'final'), os.path.join(AS, 'data'), os.path.join(AS, 'music'),
                                                             os.path.join(AS, 'pictures'), AS])
    files[14], files[15] = rd(fd, 'b00.bin'), rd(fd, 'b01.bin')
    for n, nm in flick_names():
        files[n] = tv16_file(nm)
    return files, incs, ld


def intro_loader(files_pos, gtab, g, incs, ld, defs=('INTRO=1',)):
    wr(os.path.join(ld, 'disk1_layout.inc'), ''.join('\tDEFB\t%d,%d,%d\n' % files_pos.get(n, (1, 1, 1)) for n in range(58)))
    glay = ['STARTR EQU 0x%04X' % g['STARTR']] + ['G_%s EQU %d' % (k, i + 1) for i, k in enumerate(GAMEFILES)] + ['GTAB']
    glay += ['\tDEFB\t%d,%d,%d' % gtab[n] for n in range(1, 9)]
    wr(os.path.join(ld, 'game_layout.inc'), '\n'.join(glay) + '\n')
    sjasm(os.path.join(SRC, 'start1', 'intro_main.asm'), ld, incs, list(defs))
    data = rd(ld, 'loader.bin')
    if len(data) > LDR_SECTORS * 256 - 0x30:
        sys.exit('загрузчик диска 1 слишком длинный: %d байт' % len(data))
    return pad(data)


def put_files(disk, files):
    pos = {}
    for n in sorted(files):
        nm = ('f%02d' % n) if n not in (0, 1, 14, 15) else {0: 'title', 1: 'intro', 14: 'final0', 15: 'final1'}[n]
        s = disk.add_file(nm, 'C', files[n], start=0)
        pos[n] = (s % SPT + 1, s // SPT, sectors(len(files[n])))
    return pos


def prepare_assets(bin_assets):
    """выбор источника ресурсов: assets_src/ -> build/assets (по умолчанию) или двоичные assets/"""
    global AS
    if bin_assets:
        AS = ASSETS_BIN
        print('ресурсы: двоичные assets/ (--bin-assets)')
        return
    import assets as A
    AS = os.path.join(B, 'assets')
    shutil.rmtree(AS, ignore_errors=True)
    A.import_all(ASSETS_SRC, AS)


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    if [a for a in argv if a != '--bin-assets']:
        sys.exit('использование: python -I build.py [--bin-assets]')
    os.makedirs(B, exist_ok=True)
    prepare_assets('--bin-assets' in argv or os.environ.get('BR2_BIN_ASSETS') == '1')
    gd = os.path.join(B, 'game')
    shutil.rmtree(gd, ignore_errors=True)
    os.makedirs(gd)
    incs = [os.path.join(SRC, 'game'), os.path.join(SRC, 'lib'), AS, gd]
    tab, savelin = {}, 0
    for it in range(8):             # RESTAB (положение файлов) лежит в странице 5, её упакованная длина влияет на положение: до сходимости
        write_layout(os.path.join(gd, 'disk_layout.inc'), tab, savelin)
        g = sjasm(os.path.join(SRC, 'game', 'game.asm'), gd, incs, [d for d in os.environ.get('BR2_DEFS', '').split() if d])
        P = {n: rd(gd, 'page%d.bin' % n) for n in range(8)}
        pg, res = game_files(g, P, gd)
        d = Trd(label='BR2GAME', tracks=160)
        ldr_at, ldr_idx, gtab, tab2, savelin2 = game_part(d, pg, res, gd)
        if (tab2, savelin2) == (tab, savelin):
            break
        tab, savelin = tab2, savelin2
    else:
        sys.exit('раскладка диска игры не сходится')
    ldr = make_loader(g, gtab)
    put_loader(d, ldr_at, ldr_idx, ldr)
    d.save(os.path.join(B, 'br2_game.trd'))
    print('br2_game.trd: свободно %d секторов, раскладка сошлась за %d проходов' % (160 * 16 - d.next, it + 1))
    # --- диск 1 (intro): boot, загрузчик с заставкой и меню, интро, инструкция, ролики, концовка
    files, iincs, ild = assemble_intro_files()
    di = Trd(label='BR2INTRO', tracks=160)
    basic = basic_program([(10, 'CLEAR VAL "24575": RANDOMIZE USR VAL "15619": REM : LOAD "br2" CODE'),
                           (20, 'RANDOMIZE USR VAL "24576"')])
    di.add_file('boot', 'B', basic, start=len(basic), length=len(basic))
    i_at = di.alloc(LDR_SECTORS)
    i_idx = len(di.files)
    di.files.append(None)
    pos = put_files(di, files)
    put_loader(di, i_at, i_idx, intro_loader(pos, gtab, g, iincs, ild))
    di.save(os.path.join(B, 'br2_intro.trd'))
    print('br2_intro.trd: свободно %d секторов' % (160 * 16 - di.next))
    # --- 1 МБ: часть игры - на тех же местах, что на диске игры, затем файлы диска 1
    dm = Trd(label='BR2GAME', tracks=256)
    m_at, m_idx, gtab_m, tab_m, savelin_m = game_part(dm, pg, res, gd)
    if (gtab_m, tab_m, savelin_m) != (gtab, tab, savelin):
        sys.exit('раскладка игры на диске 1 МБ отличается от диска игры')
    posm = put_files(dm, files)
    put_loader(dm, m_at, m_idx, intro_loader(posm, gtab, g, iincs, ild))
    dm.save(os.path.join(B, 'br2_1mb.trd'))
    print('br2_1mb.trd: свободно %d секторов' % (256 * 16 - dm.next))


if __name__ == '__main__':
    main()
