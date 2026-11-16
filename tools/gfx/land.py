#!/usr/bin/env python3
"""4LAND: листы ландшафта 4?CITY/4?BUILD/4?LAND.TIF -> DATA/4?SPR.DAT (412 тайлов 16x16 по 32 байта = 13184 байт).

Порт CPP/4LAND.CPP. Тайл: 2 байта (16 точек) в ширину, 16 строк; в файле сначала левый столбец (16 байт), потом правый.
Номера тайлов (0..411) задают таблицы l1s1/l1s2 (город, здания: 1 тайл-лист "здание" = 9 кусков по 16x16) и l1s3 (земля 12x16).

    python -I tools/gfx/land.py [--images ARCH/IMAGES] [--out DIR]   (по умолчанию build/author_out)     # 4?CITY/BUILD/LAND.TIF -> 4?SPR.DAT (41..45)
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from gfx import common as C  # noqa: E402

LAND = 13184
SHEET = 6144            # 256x192 точек = 32 байта x 192 строк

l1s1 = [104, 105, 106, 107, 103, 255,
        108, 109, 110, 111, 102, 255,
        112, 113, 114, 115, 255,
        116, 117, 118, 119, 0]
l1s2 = [1000, 1001, 1002, 1003, 255,
        1004, 1005, 1006, 255,
        1007, 1008, 1009, 1010, 255,
        1011, 1012, 1013, 0]
l1s3 = [[411, 0, 1, 2, 3, 4, 5, 15, 16, 17, 18, 38, 39, 40, -1, -1],
        [41, 42, 43, 44, 45, 46, 47, 48, -1, -1, -1, -1, -1, -1, -1, -1],
        [8, 9, 10, 32, 19, 20, 21, 49, 28, 55, 30, 35, 36, 37, -1, -1],
        [7, 6, 11, 33, 22, 23, 24, 50, 53, 96, 52, -4, -11, -18, -1, -1],
        [14, 13, 12, 34, 25, 26, 27, 51, 29, 54, 31, -1, -1, -1, -1, -1],
        [97, 99, -5, -7, -12, -14, -19, -21, 94, -2, -9, -16, -1, -1, -1, -1],
        [98, 100, -6, -8, -13, -15, -20, -22, 95, -3, -10, -17, -1, -1, -1, -1],
        [57, 58, 56, 62, 64, 63, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
        [60, 61, 59, 65, 67, 66, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
        [-1] * 16,
        [68, 70, 72, 74, 76, 78, 80, 82, 84, 86, 88, 90, 92, -1, -1, -1],
        [69, 71, 73, 75, 77, 79, 81, 83, 85, 87, 89, 91, 93, -1, -1, -1]]

SETS = (1, 2, 3, 4, 5)
KINDS = ('city', 'build', 'land')


def convert(city, build, land_sheet, fill=0xA5, warn=None):
    """три листа (по 6144, индексируемых как buff[y*32+x]) -> список из 13184 значений (байт либо, при трассировке, номер)"""
    land = [fill] * LAND

    def one_qu(buff, x, y, nn):
        adr = nn * 32
        if land[adr] != fill and warn is not None:
            warn.append('накладка #%u' % nn)
        for k in range(2):
            for l in range(16):
                land[adr] = buff[(y + l) * 32 + x + k]
                adr += 1

    def conv_t1(buff, formm):
        x = 2
        y = 16
        i = 0

        def ring(n):                # 8 соседних кусков здания; (x,y) - центр
            nonlocal x, y
            for dx, dy in ((-2, 0), (0, -16), (2, 0), (2, 0), (0, 16), (0, 16), (-2, 0), (-2, 0)):
                x += dx
                y += dy
                one_qu(buff, x, y, n)
                n += 1

        while formm[i] != 0:        # end
            n = formm[i]
            i += 1
            if n == 255:            # next line
                x = 2
                y += 48
                continue
            if n == -1:             # dummy
                x += 6
                continue
            if n < 1000:            # здания
                one_qu(buff, x, y, n)
                n = 120 + (n - 102) * 8
            else:                   # стройка 2
                n = 264 + (n - 1000) * 9
                one_qu(buff, x, y, n)
                n += 1
            ring(n)
            x += 8
            y -= 16

    def conv_t2(buff, form):
        yy = 0
        x = 0
        for i in range(12):
            for j in range(16):
                nn = form[i][j]
                if nn != -1:
                    n = nn if nn > -1 else 390 - nn - 2     # обычные / анимированные
                    one_qu(buff, x, yy, n)
                x += 2
            x = 0
            yy += 16

    conv_t1(city, l1s1)
    conv_t1(build, l1s2)
    conv_t2(land_sheet, l1s3)
    return land


def plan():
    """таблица: байт 4?SPR.DAT <- номер ячейки (лист*6144 + y*32 + x) или None"""
    ids = [list(range(k * SHEET, (k + 1) * SHEET)) for k in range(3)]
    p = convert(ids[0], ids[1], ids[2], fill=None)
    return p


def load_sheets(images, n):
    return [C.read_tif(C.ci_path(images, '%d%s.tif' % (n, k)), SHEET) for k in KINDS]


def main(argv=None):
    import argparse
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--images', default=os.path.join(C.ARCH, 'IMAGES'))
    ap.add_argument('--out', default=C.OUT)
    a = ap.parse_args(argv)
    for n in SETS:
        warn = []
        d = bytes(convert(*load_sheets(a.images, 40 + n), warn=warn))
        C.wr(os.path.join(a.out, '4%dspr.dat' % n), d)
        print('4%dspr.dat' % n, len(d), 'bytes', '; '.join(warn))


if __name__ == '__main__':
    main()
