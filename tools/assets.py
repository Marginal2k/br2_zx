#!/usr/bin/env python3
"""Ресурсы Чёрного Ворона 2: двоичные (assets/) <-> редактируемые (assets_src/: PNG, UTF-8 .txt, CSV, JSON).

    python -I tools/assets.py export [--assets assets] [--src assets_src]    # двоичные -> редактируемые (разово, для проверки)
    python -I tools/assets.py import [--src assets_src] [--out build/assets] # редактируемые -> двоичные, которые читает сборка
    python -I tools/assets.py list                                           # что во что превращается

Конвертеры - порты утилит автора: tools/gfx/*.py (графика), tools/txt/*.py (тексты). Подробно - docs/TOOLS.md.

Принципы:
  * графика - листы автора (как в его TIF: рисунок и маска отдельно), 1 бит = 1 точка, чёрный = чернила; PNG 1 бит;
  * то, что автор пакал упаковщиком LPZ (в архиве его исходника нет), хранится как PNG + исходный поток NAME.lpz:
    пока картинка не изменена, в сборку идёт исходный поток дословно; изменённая - упаковывается tools/lpz.py
    (поток получается другой по байтам и может быть другой длины);
  * тексты - UTF-8; обратный ход всегда проверен: текст -> байты даёт ровно исходные байты.
"""
import argparse
import json
import os
import re
import shutil
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lpz  # noqa: E402
from gfx import barbut, common as G, hero, land, misc, scr, tv16  # noqa: E402
from txt import common as T, instr, tasks, titr  # noqa: E402

ROOT = G.ROOT
ARCH = G.ARCH

# ролики диска 1 (номера F_DAT 16..57 из src_v04/start1/disk1.asm): (каталог TV16, имя файла)
FLICKS = [('MOVES', n) for n in
          ('cfeetr0 cfeetr1 cfeetr2 cfeetl0 cfeetl1 cfeetl2 union1 h_base airatack ef_tank bombes end_base union2 plakat stinger '
           'kunges1 kunges2 h_tank walk_fir walk_mov walk_air walk_rot walk_dwn walk_flm rocket1 rocket2 openfire h_intr e_explos '
           'h_space battler0 battler1 desant battlel0 battlel1 end4').split()] + \
         [('FINAL', n) for n in 'h_vict0 h_vict1 h_vict2 k_vict0 k_vict1 k_vict2'.split()]


def rd(*p):
    return G.rd(*p)


def wr(path, data):
    if isinstance(data, str):
        data = data.encode('utf-8')
    G.wr(path, data)


def rdtxt(path):
    """UTF-8 текст -> str с '\\n'"""
    return rd(path).decode('utf-8-sig').replace('\r\n', '\n').replace('\r', '\n')


def crlf(s):
    return s.replace('\n', '\r\n')


class Item:
    name = ''
    outs = ()           # выходные двоичные файлы (относительно assets/)
    kind = ''           # для вывода: графика, текст, ...

    def export(self, a, s):
        raise NotImplementedError

    def build(self, s, o):
        raise NotImplementedError

    def sources(self):
        """файлы assets_src/, из которых строятся выходы (для list)"""
        return []


# ----------------------------------------------------------------------------- листы (PNG 1 бит)
class SheetItem(Item):
    """Несколько двоичных файлов <-> один набор листов PNG. outs_spec: [(файл, 'copy'|'pairs', plan(), fill)]"""
    kind = 'графика (листы автора)'

    def __init__(self, name, sheets, outs_spec, meta):
        self.name = name
        self.sheets = sheets                # [(png относительно assets_src, байт в строке, строк)]
        self.spec = outs_spec
        self.meta = meta                    # json относительно assets_src
        self.outs = tuple(o[0] for o in outs_spec)

    def sources(self):
        return [p for p, _, _ in self.sheets] + [self.meta]

    def export(self, a, s):
        inv = G.Inverter(sum(wb * h for _, wb, h in self.sheets))
        meta = {}
        for out, kind, plan, fill in self.spec:
            d = rd(a, out)
            rest = inv.add_copy(plan, d, out) if kind == 'copy' else inv.add_pairs(plan, d, out)
            rest = {i: b for i, b in rest.items() if b != (fill if kind == 'copy' else 0)}
            meta[out] = {'len': len(d)}
            if rest:
                meta[out]['rest'] = G.runs(rest)
        pos = 0
        for png, wb, h in self.sheets:
            G.save_mono(os.path.join(s, png), bytes(inv.sheet[pos:pos + wb * h]), wb, h)
            pos += wb * h
        wr(os.path.join(s, self.meta), json.dumps({'outputs': meta}, indent=1, ensure_ascii=False) + '\n')

    def build(self, s, o):
        sheet = b''.join(bytes(G.load_mono(os.path.join(s, png), wb, h)) for png, wb, h in self.sheets)
        meta = json.loads(rdtxt(os.path.join(s, self.meta)))['outputs']
        for out, kind, plan, fill in self.spec:
            m = meta[out]
            rest = G.unruns(m.get('rest', []))
            n = m['len']
            if kind == 'copy':
                d = G.apply_plan(plan, sheet, n, fill, rest)
            else:
                d = G.apply_pairs(plan, sheet, n, rest)
            wr(os.path.join(o, out), d)


def _font_plan(nglyph, per_row):
    """шрифт 8x8: знак g - в клетке (g % per_row, g // per_row) листа; байт k знака - строка k клетки"""
    return [((g // per_row) * 8 + k) * per_row + g % per_row for g in range(nglyph) for k in range(8)]


def sheet_items():
    it = []
    for n in land.SETS:                        # ландшафт: 3 листа на набор
        it.append(SheetItem('ландшафт %d' % n, [('gfx/land/4%d%s.png' % (n, k), 32, 192) for k in land.KINDS],
                            [('data/4%dspr.dat' % n, 'copy', land.plan(), 0xA5)], 'gfx/land/4%dspr.json' % n))
    for name, typ in hero.STYP:                # герои из архива
        it.append(SheetItem('герой ' + name, [('gfx/hero/%s.png' % name, 32, 192)],
                            [('data/hero/%s.dat' % name, 'pairs', hero.plan(typ), 0)], 'gfx/hero/%s.json' % name))
    # блоки героев из образа v0.04 (в архиве автора файлов нет): раскладка по размеру/типу, см. docs/TOOLS.md
    for fn, typ in (('hrh7', '2'), ('hrh8', '2'), ('hrm19', '2'), ('hrm20', '2'), ('4_r0_CD80', '8'), ('4_r0_FA50', '7'),
                    ('6_r775_E88F', 'S')):
        it.append(SheetItem('герой v0.04 ' + fn, [('gfx/hero/hum_%s.png' % fn.lower(), 32, 192)],
                            [('hum/%s.bin' % fn, 'pairs', hero.plan(typ), 0)], 'gfx/hero/hum_%s.json' % fn.lower()))
    for fn, size, h in (('3_r0_D270', 576, 24), ('3_r0_D870', 576, 24), ('3_r0_F770', 576, 24), ('4_r0_DA40', 576, 24), ('hrm18', 1616, 16)):
        pr, wb, hh = G.strip_pairs(size, h)
        it.append(SheetItem('герой v0.04 (геометрия неизвестна) ' + fn, [('gfx/hero/hum_%s.png' % fn.lower(), wb, hh)],
                            [('hum/%s.bin' % fn, 'pairs', pr, 0)], 'gfx/hero/hum_%s.json' % fn.lower()))
    # мелкие спрайты: образ v0.04 WM22/WM33 (новее архива) + 4misc4x4/1x1/1x2 архива, один лист автора 4MISC.TIF
    it.append(SheetItem('мелкие спрайты (4MISC)', [('gfx/misc/4misc.png', 32, 384)],
                        [('hum/WM22.bin', 'pairs', misc.plan('4misc2x2'), 0), ('data/4misc4x4.dat', 'pairs', misc.plan('4misc4x4'), 0),
                         ('data/4misc1x1.dat', 'pairs', misc.plan('4misc1x1'), 0), ('data/4misc1x2.dat', 'pairs', misc.plan('4misc1x2'), 0),
                         ('hum/WM33.bin', 'pairs', misc.plan('4misc3x3'), 0)], 'gfx/misc/4misc.json'))
    it.append(SheetItem('кнопки', [('gfx/ui/4buttn.png', 32, 336)],
                        [('data/4h_butt.dat', 'copy', barbut.plan_butt(0), 0), ('data/4k_butt.dat', 'copy', barbut.plan_butt(1), 0)],
                        'gfx/ui/4buttn.json'))
    bar, font, names = barbut.plan_bar()
    it.append(SheetItem('панель, шрифт, названия', [('gfx/ui/4bar.png', 32, 192)],
                        [('data/4bar.dat', 'copy', bar, 0), ('data/4font.fnt', 'copy', font, 0), ('hum/WNAMES.bin', 'copy', names, 0)],
                        'gfx/ui/4bar.json'))
    for nb in (0, 1):                          # кадры интро: 6 листов 160x128
        it.append(SheetItem('кадры интро %d' % nb, [('gfx/intro/f%02d.png' % i, 20, 128) for i in range(nb * 6, nb * 6 + 6)],
                            [('data/4introf%d.dat' % nb, 'copy', list(range(15360)), 0)], 'gfx/intro/f%d.json' % nb))
    it.append(SheetItem('шрифт инструкции wnf1 (96 знаков)', [('gfx/fonts/wnf1.png', 16, 48)],
                        [('data/wnf1.fnt', 'copy', _font_plan(96, 16), 0)], 'gfx/fonts/wnf1.json'))
    it.append(SheetItem('шрифт инструкции wnf2 (12 знаков)', [('gfx/fonts/wnf2.png', 12, 8)],
                        [('data/wnf2.fnt', 'copy', _font_plan(12, 12), 0)], 'gfx/fonts/wnf2.json'))
    return it


# ----------------------------------------------------------------------------- картинки и ролики в LPZ
class LpzItem(Item):
    def __init__(self, name, out, png, srcpath=None):
        self.name, self.out, self.png = name, out, png
        self.outs = (out,)
        self.srcpath = srcpath               # откуда брать исходный .lpz при экспорте (по умолчанию assets/)

    def sources(self):
        return [self.png, self.png[:-4] + '.lpz']

    def _orig(self, a):
        return rd(self.srcpath) if self.srcpath else rd(a, self.out)

    def export(self, a, s):
        orig = self._orig(a)
        self.png_export(lpz.unpack(orig), os.path.join(s, self.png))
        wr(os.path.join(s, self.png[:-4] + '.lpz'), orig)

    def build(self, s, o):
        orig = rd(s, self.png[:-4] + '.lpz')
        ref = lpz.unpack(orig)
        new = self.png_import(os.path.join(s, self.png), ref)
        if new == ref:
            wr(os.path.join(o, self.out), orig)
        else:
            print('  %s: рисунок изменён, перепаковка tools/lpz.py (%d -> %d байт)' % (self.out, len(orig), len(lpz.pack(new))), file=sys.stderr)
            wr(os.path.join(o, self.out), lpz.pack(new))


class MonoPic(LpzItem):
    kind = 'графика (ч/б экран 256x192, LPZ)'

    def png_export(self, data, path):
        if len(data) != 6144:
            raise ValueError('%s: %d байт, ждали 6144' % (self.out, len(data)))
        scr.mono_export(data, path)

    def png_import(self, path, ref):
        return scr.mono_import(path)


class ColorPic(LpzItem):
    kind = 'графика (цветной SCR 6912, LPZ)'

    def png_export(self, data, path):
        if len(data) != 6912:
            raise ValueError('%s: %d байт, ждали 6912' % (self.out, len(data)))
        scr.scr_export(data, path)

    def png_import(self, path, ref):
        return scr.scr_import(path, ref)


class ClipPic(LpzItem):
    kind = 'видео TV16 (32 кадра 28x36, 16 градаций, LPZ)'

    def png_export(self, data, path):
        tv16.clip_export(data, path)

    def png_import(self, path, ref):
        return tv16.clip_import(path, len(ref) // tv16.FRAME)


def lpz_items():
    it = [MonoPic('картинка инструкции 4instr0', 'data/4instr0.lpz', 'gfx/pictures/4instr0.png'),
          MonoPic('картинка интро 4intro', 'data/4intro.lpz', 'gfx/pictures/4intro.png'),
          MonoPic('рамка интро mainfram', 'tv16/intro/mainfram.lpz', 'gfx/pictures/mainfram.png')]
    for n in ('4_ussr', '4title', '4h_end', '4k_end'):
        it.append(ColorPic('экран ' + n, 'pictures/%s.lpz' % n, 'gfx/pictures/%s.png' % n))
    for d, n in FLICKS:
        it.append(ClipPic('ролик ' + n, 'tv16/%s/%s.lpz' % (d.lower(), n), 'gfx/tv16/%s/%s.png' % (d.lower(), n),
                          srcpath=G.ci_path(ARCH, 'TV16', d, n + '.lpz')))
    return it


# ----------------------------------------------------------------------------- тексты
class TextItem(Item):
    kind = 'текст'

    def __init__(self, name, outs, txt, dec, enc):
        self.name, self.outs, self.txt, self.dec, self.enc = name, tuple(outs), txt, dec, enc

    def sources(self):
        return [self.txt]

    def export(self, a, s):
        text = self.dec(*[rd(a, o) for o in self.outs])
        # проверка: текст -> байты даёт исходные
        back = self.enc(text)
        for o, b in zip(self.outs, back):
            if b != rd(a, o):
                raise ValueError('%s: текст не даёт исходные байты' % o)
        wr(os.path.join(s, self.txt), text)

    def build(self, s, o):
        res = self.enc(rdtxt(os.path.join(s, self.txt)))
        for out, b in zip(self.outs, res):
            wr(os.path.join(o, out), b)


def _flic_dec(d):
    return titr.decode_titr(d).replace('\r\n', '\n')


def _flic_enc(t):
    return (titr.convert_titr(crlf(t), None),)


def _scroll_dec(d):
    return titr.decode_scroll(d).replace('\r\n', '\n')


def _scroll_enc(t):
    return (titr.convert_scroll(crlf(t)),)


def _instr_dec(dat, cm):
    return instr.decode(dat, cm).replace('\r\n', '\n')


def _instr_enc(t):
    dat, cm = instr.convert(crlf(t))
    return dat, cm


def _taskm_dec(d):
    return '\n'.join(tasks.decode_task(d, 4, 20)) + '\n'


def _taskm_enc(t):
    lines = t.split('\n')
    if lines and lines[-1] == '':
        lines.pop()
    return (tasks.conv_one_task(crlf('\n'.join(lines) + '\n#'), 0, 1, 4, 20)[0],)


def _nums(text):
    return [int(x) for x in re.sub(r'#[^\n]*', '', text).split()]


def _sou6_dec(d):
    if len(d) % 4 != 1 or d[-1] != 0xFF:
        raise ValueError('SOU6: не четвёрки + #FF')
    rows = ['%3d %3d %3d %3d' % tuple(d[i:i + 4]) for i in range(0, len(d) - 1, 4)]
    return ('# звуковой эффект 6: период4 период5 громкость шум (по строке на шаг; конец - #FF; формат: src/game/sound2.asm)\n'
            + '\n'.join(rows) + '\n')


def _sou6_enc(t):
    v = _nums(t)
    if len(v) % 4:
        raise ValueError('SOU6: число значений не кратно 4')
    return (bytes(v) + b'\xff',)


NUM_M = 5


def _nummap_dec(*ds):
    out = ['# 4NUM_M1..5.BIN: по 128 байт (номера спрайтов миникарты; 16 в строке); 4NUM_M4 - кунги, 4NUM_M5 - люди (build.py, ресурс 11)']
    for i, d in enumerate(ds):
        out.append('[4num_m%d]' % (i + 1))
        for r in range(0, 128, 16):
            out.append(' '.join('%3d' % b for b in d[r:r + 16]))
    return '\n'.join(out) + '\n'


def _nummap_enc(t):
    parts = re.split(r'^\[4num_m\d\]\s*$', t, flags=re.M)[1:]
    if len(parts) != NUM_M:
        raise ValueError('4num_m: нужно %d разделов' % NUM_M)
    res = []
    for p in parts:
        v = _nums(p)
        if len(v) != 128:
            raise ValueError('4num_m: %d значений вместо 128' % len(v))
        res.append(bytes(v))
    return tuple(res)


def text_items():
    it = [TextItem('титры роликов 4flictxt', ['data/4flictxt.dat'], 'text/flictxt.txt', _flic_dec, _flic_enc),
          TextItem('титры людей 4victhum', ['data/4victhum.dat'], 'text/victhum.txt', _scroll_dec, _scroll_enc),
          TextItem('титры кунгов 4victkun', ['data/4victkun.dat'], 'text/victkun.txt', _scroll_dec, _scroll_enc),
          TextItem('инструкция 4instr (+ словарь)', ['start1/data/4instr.dat', 'start1/data/4instrcm.dat'], 'text/instr.txt',
                   _instr_dec, _instr_enc),
          TextItem('задание уровня (4 строки)', ['hum/TASK_M.bin'], 'text/task_m.txt', _taskm_dec, _taskm_enc),
          TextItem('звуковой эффект 6', ['hum/SOU6.bin'], 'text/sou6.txt', _sou6_dec, _sou6_enc),
          TextItem('таблицы миникарты 4num_m1..5', ['data/4num_m%d.bin' % i for i in range(1, 6)], 'text/num_m.txt',
                   _nummap_dec, _nummap_enc)]
    return it


# ----------------------------------------------------------------------------- карты и расстановка
def csv_dec(d, w=64):
    return '\n'.join(','.join('%d' % b for b in d[r:r + w]) for r in range(0, len(d), w)) + '\n'


def csv_enc(t):
    v = _nums(t.replace(',', ' '))
    return bytes(v)


class MapItem(Item):
    """карта 64x64 (CSV, номера клеток) + хвост файла в JSON"""
    kind = 'карта (CSV)'

    def __init__(self, name, out, csv, tail_json=None):
        self.name, self.out, self.csv, self.tj = name, out, csv, tail_json
        self.outs = (out,)

    def sources(self):
        return [self.csv] + ([self.tj] if self.tj else [])

    def export(self, a, s):
        d = rd(a, self.out)
        wr(os.path.join(s, self.csv), '# карта 64x64 клеток: номер тайла/объекта на клетку (бит 7 - туман); строка = ряд сверху вниз\n'
            + csv_dec(d[:4096]))
        if self.tj:
            wr(os.path.join(s, self.tj), json.dumps({'tail': d[4096:].hex(), 'len': len(d)}, indent=1) + '\n')
        elif len(d) != 4096:
            raise ValueError('карта %s не 4096 байт' % self.out)

    def build(self, s, o):
        d = csv_enc(rdtxt(os.path.join(s, self.csv)))
        if len(d) != 4096:
            raise ValueError('%s: %d клеток вместо 4096' % (self.csv, len(d)))
        if self.tj:
            d += bytes.fromhex(json.loads(rdtxt(os.path.join(s, self.tj)))['tail'])
        wr(os.path.join(o, self.out), d)


class HerItem(Item):
    """расстановка героев: записи по 4 байта (владелец, тип, x, y), владелец 255 - конец; перед ней - необязательные 16 байт параметров шахт"""
    kind = 'расстановка героев (текст)'

    def __init__(self, name, out, txt, head=0):
        self.name, self.out, self.txt, self.head = name, out, txt, head
        self.outs = (out,)

    def sources(self):
        return [self.txt]

    def export(self, a, s):
        d = rd(a, self.out)
        h, body = d[:self.head], d[self.head:]
        if len(body) % 4:
            raise ValueError('%s: длина не кратна 4' % self.out)
        out = ['# расстановка героев: владелец тип x y (4 байта на запись; десятичные числа; владелец 255 - пустая запись/конец)']
        if self.head:
            out += ['# параметры шахт (16 байт)', 'mines ' + ' '.join('%d' % b for b in h)]
        out += [' '.join('%3d' % b for b in body[i:i + 4]) for i in range(0, len(body), 4)]
        wr(os.path.join(s, self.txt), '\n'.join(out) + '\n')

    def build(self, s, o):
        lines = [re.sub(r'#.*', '', l).strip() for l in rdtxt(os.path.join(s, self.txt)).split('\n')]
        d = bytearray()
        for l in lines:
            if not l:
                continue
            if l.startswith('mines'):
                d += bytes(int(x) for x in l.split()[1:])
            else:
                d += bytes(int(x) for x in l.split())
        wr(os.path.join(o, self.out), bytes(d))


def map_items():
    return [MapItem('карта людей (v0.04, MAP_10)', 'hum/M_r6161_8000.bin', 'maps/hum_map.csv'),
            MapItem('карта кунгов 4_4.map', 'map/4_4.map', 'maps/4_4.csv', 'maps/4_4.json'),
            HerItem('расстановка людей (datMIN: шахты + герои)', 'hum/datMIN.bin', 'maps/hum_her.txt', head=16),
            HerItem('расстановка кунгов 4_4.her', 'map/4_4.her', 'maps/4_4_her.txt')]


# ----------------------------------------------------------------------------- без редактора (пока)
RAW = ['music/4h_victc.lpz', 'music/4k_victc.mus', 'music/j38fc.lpz', 'music/jam_gimn.lpz', 'music/lfantc.mus', 'music/song1c.mus',
       'start1/LP2', 'start1/LP3', 'start1/LP4', 'hum/1_r2_FEE2.bin', 'hum/6_junk_EBC9.bin']


class RawItem(Item):
    kind = 'двоичный (пока не редактируется)'

    def __init__(self, rel):
        self.name, self.outs = 'файл ' + rel, (rel,)

    def sources(self):
        return ['raw/' + self.outs[0]]

    def export(self, a, s):
        wr(os.path.join(s, 'raw', self.outs[0]), rd(a, self.outs[0]))

    def build(self, s, o):
        wr(os.path.join(o, self.outs[0]), rd(s, 'raw', self.outs[0]))


def all_items():
    return sheet_items() + lpz_items() + text_items() + map_items() + [RawItem(r) for r in RAW]


# ----------------------------------------------------------------------------- команды
def export_all(a, s):
    n = 0
    for it in all_items():
        it.export(a, s)
        n += len(it.outs)
    return n


def import_all(s, o, quiet=False):
    """assets_src -> каталог двоичных ресурсов o (оттуда сборка берёт INCBIN и файлы)"""
    n = 0
    for it in all_items():
        it.build(s, o)
        n += len(it.outs)
    if not quiet:
        print('assets_src -> %s: %d файлов' % (os.path.relpath(o, ROOT), n))
    return n


def outputs():
    return [o for it in all_items() for o in it.outs]


def main(argv=None):
    for st in (sys.stdout, sys.stderr):
        try:
            st.reconfigure(encoding='utf-8', errors='replace')
        except (AttributeError, ValueError):
            pass
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('cmd', choices=('export', 'import', 'list'))
    ap.add_argument('--assets', default=os.path.join(ROOT, 'assets'))
    ap.add_argument('--src', default=os.path.join(ROOT, 'assets_src'))
    ap.add_argument('--out', default=os.path.join(ROOT, 'build', 'assets'))
    a = ap.parse_args(argv)
    if a.cmd == 'export':
        print('assets -> assets_src: %d файлов' % export_all(a.assets, a.src))
    elif a.cmd == 'import':
        if os.path.isdir(a.out):
            shutil.rmtree(a.out)
        import_all(a.src, a.out)
    else:
        for it in all_items():
            print('%-52s %-40s -> %s' % (it.name, it.kind, ', '.join(it.outs)))


if __name__ == '__main__':
    main()
