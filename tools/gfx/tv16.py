#!/usr/bin/env python3
"""4TV16: 24-битные кадры (BMP) -> видео TV16 (.T16). Плюс чтение/запись кадров .T16 для редактирования.

Порт CPP/4TV16.CPP. Кадр - 28x36 точек в 16 градациях серого, 2 точки в байте (старшая тетрада - левая); 504 байта.
BMP-кадр 28x36 (24 бита, строки снизу вверх). Порядок байт кадра: out[i 18][j 14][k 2]: пара строк картинки (2i, 2i+1),
k=0 - строка 2i, k=1 - строка 2i+1, j - пара точек (2j, 2j+1) строки.
Яркость: g = 15 - (29*B + 77*R + 150*G) / 4096 (g=0 - белый, 15 - чёрный). ВАЖНО: в исходнике R,G,B читаются из знакового char
(Turbo C), поэтому компоненты >=128 превращаются в отрицательные числа; порт повторяет это (--unsigned даёт беззнаковое чтение).
Ролик - 32 кадра подряд (16128 байт); в игре лежит сжатым (.LPZ).

    python -I tools/gfx/tv16.py [--bmp DIR] [--out DIR]      # tmp_0000.bmp.. -> k_vict0/1/2.t16 (кадры 0-31, 32-63, 64-95)
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from gfx import common as C  # noqa: E402

WID, HGT = 14, 18
FRAME = WID * HGT * 2           # 504
W, H = WID * 2, HGT * 2         # 28x36 точек


def _sgn(v, signed):
    return v - 256 if signed and v > 127 else v


def _cdiv(a, b):
    """деление C (к нулю)"""
    q = abs(a) // abs(b)
    return q if (a >= 0) == (b > 0) else -q


def conv_f(bmp, signed=True):
    """BMP-файл (24 бита, 28x36, строки снизу вверх) -> 504 байта кадра (conv_f автора)"""
    out = bytearray(FRAME)
    pos = len(bmp) - WID * 4 * 3
    for i in range(HGT):
        tb = pos
        for k in (1, 0):
            for j in range(WID):
                gs = []
                for _ in range(2):
                    r, g, b = _sgn(bmp[tb], signed), _sgn(bmp[tb + 1], signed), _sgn(bmp[tb + 2], signed)
                    tb += 3
                    gs.append(15 - _cdiv(b * 29 + r * 77 + g * 150, 256 * 16))
                out[(i * WID + j) * 2 + k] = (gs[1] + gs[0] * 16) & 0xFF
        pos -= WID * 2 * 2 * 3
    return bytes(out)


def read_conv_f(bmps, signed=True):
    return b''.join(conv_f(b, signed) for b in bmps)


# ---- кадр <-> яркости g=0..15
def frame_pixels(fr):
    """504 байта -> 36 строк по 28 значений g"""
    rows = [[0] * W for _ in range(H)]
    for i in range(HGT):
        for j in range(WID):
            for k in (0, 1):
                v = fr[(i * WID + j) * 2 + k]
                rows[2 * i + k][2 * j] = v >> 4
                rows[2 * i + k][2 * j + 1] = v & 15
    return rows


def pixels_frame(rows):
    out = bytearray(FRAME)
    for i in range(HGT):
        for j in range(WID):
            for k in (0, 1):
                out[(i * WID + j) * 2 + k] = (rows[2 * i + k][2 * j] << 4) | rows[2 * i + k][2 * j + 1]
    return bytes(out)


def make_bmp(rows):
    """для проверки: BMP 28x36x24 из g (серый Y=(15-g)*16)"""
    import struct
    body = bytearray()
    for row in reversed(rows):
        for g in row:
            y = (15 - g) * 16
            body += bytes((y, y, y))
    hdr = b'BM' + struct.pack('<IHHIIiiHHIIiiII', 54 + len(body), 0, 0, 54, 40, W, H, 1, 24, 0, len(body), 0, 0, 0, 0)
    return hdr + bytes(body)


# ---- ролик (много кадров) <-> PNG
COLS = 8
GAP = 2


def clip_export(data, path):
    """ролик (N кадров по 504 байта) -> PNG: кадры 28x36 в сетке по 8, между ними полоса (индекс 16). Палитра: индекс g -> серый (15-g)*17."""
    from PIL import Image
    n = len(data) // FRAME
    if n * FRAME != len(data):
        raise ValueError('длина ролика %d не кратна %d' % (len(data), FRAME))
    rows_n = (n + COLS - 1) // COLS
    w, h = COLS * (W + GAP) + GAP, rows_n * (H + GAP) + GAP
    im = Image.new('P', (w, h), 16)
    pal = []
    for g in range(16):
        v = (15 - g) * 17
        pal += [v, v, v]
    pal += [255, 0, 255]
    im.putpalette(pal + [0, 0, 0] * (256 - 17))
    for f in range(n):
        px = frame_pixels(data[f * FRAME:(f + 1) * FRAME])
        x0, y0 = GAP + (f % COLS) * (W + GAP), GAP + (f // COLS) * (H + GAP)
        for y in range(H):
            for x in range(W):
                im.putpixel((x0 + x, y0 + y), px[y][x])
    d = os.path.dirname(path)
    if d:
        os.makedirs(d, exist_ok=True)
    im.save(path, optimize=True)


def clip_import(path, n):
    """PNG -> ролик из n кадров. Яркость: индекс палитры 0..15 берётся как есть, если палитра "родная"; иначе по серому."""
    from PIL import Image
    im = Image.open(path)
    rows_n = (n + COLS - 1) // COLS
    if im.size != (COLS * (W + GAP) + GAP, rows_n * (H + GAP) + GAP):
        raise ValueError('%s: размер %s, ожидался %s' % (path, im.size, (COLS * (W + GAP) + GAP, rows_n * (H + GAP) + GAP)))
    native = False
    if im.mode == 'P':
        pal = im.getpalette()
        native = all(pal[3 * g:3 * g + 3] == [(15 - g) * 17] * 3 for g in range(16))
        pl = [round(255 - (pal[3 * i] * 77 + pal[3 * i + 1] * 150 + pal[3 * i + 2] * 29) / 256) for i in range(256)]
    out = bytearray()
    for f in range(n):
        x0, y0 = GAP + (f % COLS) * (W + GAP), GAP + (f // COLS) * (H + GAP)
        rows = []
        for y in range(H):
            row = []
            for x in range(W):
                v = im.getpixel((x0 + x, y0 + y))
                if im.mode == 'P':
                    g = v if native else min(15, max(0, round(pl[v] / 17)))
                else:
                    r, gg, b = im.convert('RGB').getpixel((x0 + x, y0 + y))
                    g = min(15, max(0, round((255 - (r * 77 + gg * 150 + b * 29) / 256) / 17)))
                if g > 15:
                    g = 15
                row.append(g)
            rows.append(row)
        out += pixels_frame(rows)
    return bytes(out)


def main(argv=None):
    import argparse
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--bmp', default=os.path.join(C.ARCH, 'TV16'))
    ap.add_argument('--out', default=C.OUT)
    ap.add_argument('--unsigned', action='store_true', help='читать компоненты как unsigned char (в оригинале - знаковый)')
    a = ap.parse_args(argv)
    for name, n1, n2 in (('k_vict0', 0, 31), ('k_vict1', 32, 63), ('k_vict2', 64, 95)):
        frames = [C.rd(a.bmp, 'tmp_%04u.bmp' % n) for n in range(n1, n2 + 1)]
        C.wr(os.path.join(a.out, name + '.t16'), read_conv_f(frames, not a.unsigned))
    print('Всё успешно.')


if __name__ == '__main__':
    main()
