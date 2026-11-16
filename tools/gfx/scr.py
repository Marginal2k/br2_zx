#!/usr/bin/env python3
"""4SCR_SC_ и работа с экранами Спектрума: SCR (6912 байт) -> .SC_; SCR/ч-б экран <-> PNG.

Порт CPP/4SCR_SC_.CPP: "для лучшей компрессии" точки экрана переставляются в столбцы: buf2[столбец 32][строка 192] =
buf[j/64*2048 + j%8*256 + (j%64)/8*32 + i] (линейная раскладка строк вместо экранной), затем 768 байт атрибутов как есть.

    python -I tools/gfx/scr.py [--pictures ARCH/PICTURES] [--out DIR]       # 32 картинки списка автора -> SC_/*.SC_

PNG цветного экрана: индексный, 16 цветов (индекс = цвет + 8*яркость; flash не виден). В ячейке 8x8 - не более 2 цветов одной
яркости (как в железе). Байты, которые PNG выразить не может (flash, порядок ink/paper при одном цвете в ячейке), берутся
из исходного файла, пока ячейка не изменена (scr_import(path, ref)).
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from gfx import common as C  # noqa: E402
from PIL import Image  # noqa: E402

LIST = ['airvoron', 'alarm!', 'colonel', 'cow', 'fireman', 'fly_home', 'holypl_2', 'joystik', 'kayuta', 'knife', 'kunge', 'mountan',
        'pilot', 'planeta', 'raketa', 'rose', 'seasun', 'shadow', 'shuttle', 'skelt', 'sky', 'smile', 'stinger1', 'supergun',
        'tank_mod', 'tunel', 'voron_s', 'walker1', 'wall', 'win98', 'xusha', 'zenitka']


def conv_scr(buf):
    """экранная раскладка 6144 байта -> столбцы (conv_scr автора)"""
    buf2 = bytearray(6144)
    for i in range(32):
        for j in range(192):
            buf2[i * 192 + j] = buf[j // 64 * 2048 + j % 8 * 256 + (j % 64) // 8 * 32 + i]
    return bytes(buf2)


def scr_to_sc_(scr):
    return conv_scr(scr[:6144]) + bytes(scr[6144:6912])


def sc__to_scr(sc):
    """обратный ход: столбцы -> экранная раскладка"""
    out = bytearray(6912)
    for i in range(32):
        for j in range(192):
            out[j // 64 * 2048 + j % 8 * 256 + (j % 64) // 8 * 32 + i] = sc[i * 192 + j]
    out[6144:] = sc[6144:6912]
    return bytes(out)


# ----------------------------------------------------------------------------- экран Спектрума <-> PNG
def _addr(y, x):
    return (y // 64) * 2048 + (y % 8) * 256 + ((y % 64) // 8) * 32 + x


PAL = []
for _b in (0, 1):
    for _c in range(8):
        _v = 255 if _b else 205
        PAL.append((_v if _c & 2 else 0, _v if _c & 4 else 0, _v if _c & 1 else 0))     # бит0 - синий, бит1 - красный, бит2 - зелёный


def _cell_colors(scr, cy, cx):
    """цвета (0..15) 64 точек ячейки (cy, cx), строка за строкой"""
    a = scr[6144 + cy * 32 + cx]
    ink, paper, br = a & 7, (a >> 3) & 7, (a >> 6) & 1
    res = []
    for r in range(8):
        b = scr[_addr(cy * 8 + r, cx)]
        for k in range(8):
            res.append(ink + 8 * br if (b >> (7 - k)) & 1 else paper + 8 * br)
    return res


def scr_export(scr, path):
    """6912 байт -> PNG"""
    px = [0] * (256 * 192)
    for cy in range(24):
        for cx in range(32):
            cc = _cell_colors(scr, cy, cx)
            for r in range(8):
                for k in range(8):
                    px[(cy * 8 + r) * 256 + cx * 8 + k] = cc[r * 8 + k]
    im = Image.new('P', (256, 192))
    pal = []
    for c in PAL:
        pal += list(c)
    im.putpalette(pal + [0, 0, 0] * (256 - 16))
    im.putdata(px)
    d = os.path.dirname(path)
    if d:
        os.makedirs(d, exist_ok=True)
    im.save(path, optimize=True)


def _png_indices(path):
    im = Image.open(path)
    if im.size != (256, 192):
        raise ValueError('%s: размер %s, нужен (256, 192)' % (path, im.size))
    if im.mode == 'P':
        pal = im.getpalette()
        idx = list(im.getdata())
        if max(idx) < 16 and all(tuple(pal[3 * i:3 * i + 3]) == PAL[i] for i in range(16)):
            return idx                                  # родная палитра: индекс = цвет + 8*яркость
        rgb = [tuple(pal[3 * v:3 * v + 3]) for v in idx]
    else:
        rgb = [p[:3] for p in im.convert('RGB').getdata()]
    cache = {}
    out = []
    for c in rgb:
        if c not in cache:
            cache[c] = min(range(16), key=lambda i: (sum((a - b) ** 2 for a, b in zip(c, PAL[i])), i))
        out.append(cache[c])
    return out


def scr_import(path, ref=None):
    """PNG -> 6912 байт. ref - исходный экран: ячейки, не менявшиеся, берутся из него дословно (с flash и порядком ink/paper)."""
    idx = _png_indices(path)
    out = bytearray(6912)
    if ref is not None:
        out[:] = ref[:6912]
    for cy in range(24):
        for cx in range(32):
            cells = [idx[(cy * 8 + r) * 256 + cx * 8 + k] for r in range(8) for k in range(8)]
            if ref is not None and _cell_colors(ref, cy, cx) == cells:
                continue
            c3 = [c & 7 for c in cells]
            used = sorted(set(c3))
            br = {c >> 3 for c in cells if c & 7}               # чёрный одинаков при любой яркости
            if len(used) > 2 or len(br) > 1:
                raise ValueError('%s: ячейка x=%d y=%d: больше двух цветов или разная яркость (%s)'
                                 % (path, cx * 8, cy * 8, sorted(set(cells))))
            a0 = out[6144 + cy * 32 + cx] if ref is not None else None
            br = br.pop() if br else ((a0 >> 6) & 1 if a0 is not None else 0)
            if a0 is not None and set(used) <= {a0 & 7, (a0 >> 3) & 7} and (((a0 >> 6) & 1) == br or not any(c3)):
                ink, paper, flash = a0 & 7, (a0 >> 3) & 7, a0 & 0x80      # прежние цвета, если подходят
                br = (a0 >> 6) & 1
            else:
                flash = 0
                if len(used) == 2:
                    n0 = c3.count(used[0])
                    paper, ink = (used[0], used[1]) if n0 >= 32 else (used[1], used[0])    # большинство - фон
                else:
                    paper = used[0]
                    ink = 0 if paper != 0 else 7
            out[6144 + cy * 32 + cx] = flash | (br << 6) | (paper << 3) | ink
            for r in range(8):
                v = 0
                for k in range(8):
                    v = (v << 1) | (1 if c3[r * 8 + k] == ink and ink != paper else 0)
                out[_addr(cy * 8 + r, cx)] = v
    return bytes(out)


def lin_to_scr(lin):
    """6144 байта, строка за строкой (как в TIF) -> экранная раскладка Спектрума (то, что делает 6144.EXE автора)"""
    out = bytearray(6144)
    for y in range(192):
        a = _addr(y, 0)
        out[a:a + 32] = lin[y * 32:(y + 1) * 32]
    return bytes(out)


def scr_to_lin(scr):
    out = bytearray(6144)
    for y in range(192):
        a = _addr(y, 0)
        out[y * 32:(y + 1) * 32] = scr[a:a + 32]
    return bytes(out)


def tif_to_scr6144(path):
    """TIF 256x192 -> 6144 байт экрана (6144.EXE: исходника нет; порт выведен сравнением с DATA/4INSTR0.DAT, 4INTRO.DAT, MAINFRAM.DAT)"""
    return lin_to_scr(C.read_tif(path, 6144))


def mono_export(data, path):
    """ч/б экран 6144 байта в экранной раскладке Спектрума (4INTRO/4INSTR0/MAINFRAM) -> PNG 256x192"""
    C.save_mono(path, scr_to_lin(data), 32, 192)


def mono_import(path):
    return lin_to_scr(C.load_mono(path, 32, 192))


def main(argv=None):
    import argparse
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--pictures', default=os.path.join(C.ARCH, 'PICTURES'))
    ap.add_argument('--out', default=os.path.join(C.OUT, 'SC_'))
    a = ap.parse_args(argv)
    for n in LIST:
        C.wr(os.path.join(a.out, n + '.sc_'), scr_to_sc_(C.rd(C.ci_path(a.pictures, n + '.scr'))))
    print('...успешно (%i files).' % len(LIST))


if __name__ == '__main__':
    main()
