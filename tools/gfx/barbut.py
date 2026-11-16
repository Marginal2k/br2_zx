#!/usr/bin/env python3
"""4BAR_BUT: кнопки, шрифт, названия, панель управления.

Порт CPP/4BAR_BUT.CPP:
    IMAGES/4BUTTN.TIF (256x336) -> DATA/4H_BUTT.DAT, DATA/4K_BUTT.DAT  (78 кнопок по 66 байт: 24x24 точек без верхней и нижней
                                                                       строки, 3 байта x 22 строки, столбцами; для людей и кунгов
                                                                       порядок кнопок в листе разный: таблица bset)
    IMAGES/4BAR.TIF   (256x192) -> DATA/4BAR.DAT   (панель: 8 байт x 192 строки, столбцами, из правых 64 точек листа)
                               -> DATA/4FONT.FNT   (114 знаков 8x8, по 6 в строке листа, левый столбец байт 18)
                               -> DATA/4NAMES.DAT  (47 названий 48x7 точек, 6 байт x 7 строк, по 24 в столбце листа)

    python -I tools/gfx/barbut.py [--images ARCH/IMAGES] [--out DIR]
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from gfx import common as C  # noqa: E402

NBUTT = 78
NFONT = 114
NNAME = 47
BUTN_SIZE = 10752
BAR_SIZE = 6144

_ = -1
bset = [[     # кнопки для людей
    [30, 31, 32, 33, 34, 35, 36, 37, 38, 39],
    [40, 41, 42, 43, 44, 45, 46, 47, 48, 49],
    [50, 51, 52, 53, 54, 55, 56, 57, 66, _],
    [58, 59, 60, 61, 62, 63, 64, 65, _, _],
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    [_] * 10,
    [10, 11, 12, 13, 14, 15, 16, 17, 18, 19],
    [_] * 10,
    [20, 21, 22, 23, 24, 25, 26, 27, 28, 29],
    [_] * 10,
    [67, 68, 69, 70, 71, 72, 73, 74, 75, _],
    [_] * 10,
    [76, 77, _, _, _, _, _, _, _, _],
    [_] * 10],
    [     # кунги
    [30, 31, 32, 33, 34, 35, 36, 37, 38, 39],
    [40, 41, 42, 43, 44, 45, 46, 47, 48, 49],
    [50, 51, 52, 53, 54, 55, 56, 57, _, _],
    [58, 59, 60, 61, 62, 63, 64, 65, 66, _],
    [_] * 10,
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    [_] * 10,
    [10, 11, 12, 13, 14, 15, 16, 17, 18, 19],
    [_] * 10,
    [20, 21, 22, 23, 24, 25, 26, 27, 28, 29],
    [_] * 10,
    [67, 68, 69, 70, 71, 72, 73, 74, 75, _],
    [_] * 10,
    [76, 77, _, _, _, _, _, _, _, _]]]


def conv_butt(buf, n, data=None):
    """лист кнопок -> 5148 байт. data - предыдущее содержимое буфера автора (глобальный data[], одна на оба вызова)"""
    data = data if data is not None else [0] * (NBUTT * 66)
    ix = iy = 0
    for y in range(14):
        for x in range(10):
            if bset[n][y][x] != -1:
                d_len = bset[n][y][x] * 66
                for j in range(3):
                    for k in range(1, 23):
                        data[d_len] = buf[iy + k * 32 + ix + j]
                        d_len += 1
                ix += 3
        ix = 0
        iy += 768
    return data


def conv_names(buf):
    data = []
    ix = iy = 0
    for n in range(NNAME):
        for j in range(6):
            for k in range(1, 8):
                data.append(buf[iy * 256 + k * 32 + ix + j])
        iy += 1
        if iy >= 24:
            iy = 0
            ix += 6
    return data


def conv_bar(buf):
    return [buf[24 + k * 32 + j] for j in range(8) for k in range(192)]


def conv_font(buf):
    data = []
    ix = iy = 0
    for n in range(NFONT):
        for k in range(8):
            data.append(buf[18 + iy * 256 + k * 32 + ix])
        ix += 1
        if ix >= 6:
            ix = 0
            iy += 1
    return data


def convert_buttons(buttn):
    """-> (4h_butt, 4k_butt) как у автора (буфер data общий: байты, не затронутые вторым вызовом, остаются от первого)"""
    data = conv_butt(buttn, 0)
    h = bytes(data)
    data = conv_butt(buttn, 1, data)
    return h, bytes(data)


def convert_bar(bar):
    return bytes(conv_bar(bar)), bytes(conv_font(bar)), bytes(conv_names(bar))


# ---- планы (номер ячейки листа для каждого байта файла)
def plan_butt(n):
    return conv_butt(list(range(BUTN_SIZE)), n, [None] * (NBUTT * 66))


def plan_bar():
    ids = list(range(BAR_SIZE))
    return conv_bar(ids), conv_font(ids), conv_names(ids)


def main(argv=None):
    import argparse
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--images', default=os.path.join(C.ARCH, 'IMAGES'))
    ap.add_argument('--out', default=C.OUT)
    a = ap.parse_args(argv)
    h, k = convert_buttons(C.read_tif(C.ci_path(a.images, '4buttn.tif'), BUTN_SIZE))
    C.wr(os.path.join(a.out, '4h_butt.dat'), h)
    C.wr(os.path.join(a.out, '4k_butt.dat'), k)
    bar, font, names = convert_bar(C.read_tif(C.ci_path(a.images, '4bar.tif'), BAR_SIZE))
    C.wr(os.path.join(a.out, '4bar.dat'), bar)
    C.wr(os.path.join(a.out, '4font.fnt'), font)
    C.wr(os.path.join(a.out, '4names.dat'), names)
    print('4h_butt.dat 4k_butt.dat 4bar.dat 4font.fnt 4names.dat: %d %d %d %d %d байт' % (len(h), len(k), len(bar), len(font), len(names)))


if __name__ == '__main__':
    main()
