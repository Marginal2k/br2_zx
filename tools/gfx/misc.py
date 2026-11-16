#!/usr/bin/env python3
"""4MISC: спрайты трупов, взрывов, снарядов (IMAGES/4MISC.TIF, 256x384) -> DATA/4MISC{1X1,1X2,2X2,3X3,4X4}.DAT.

Порт CPP/4MISC.CPP. Лист - две картинки 256x192 подряд: первая - рисунок (SPR), вторая - маска (MASK). Как у героев,
в файле пары байт (M, M^I); столбцами по 8 строк на ячейку 8x8: 1x1 - 8 пар, 1x2 - 16, 2x2 - 32 на столбец и т. д.

    python -I tools/gfx/misc.py [--images ARCH/IMAGES] [--out DIR]
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from gfx import common as C  # noqa: E402

SHEET = 6144 * 2
SPR, MASK = 0, 1
NAMES = ('4misc2x2', '4misc4x4', '4misc1x1', '4misc1x2', '4misc3x3')


class _St:
    def __init__(self, x, y):
        self.x, self.y = x, y
        self.pairs = []
        self._xs = self._ys = 0

    def _mov(self):
        for i in range(8):
            o = (self.y * 8 + i) * 32 + self.x
            self.pairs.append((6144 * MASK + o, 6144 * SPR + o))
        self.y += 1

    def conv(self, rows, cols, n, step_double=False):
        """conv11/12/22/33/44: n раз по cols столбцов высотой rows ячеек"""
        self._xs, self._ys = self.x, self.y
        for _ in range(n):
            for _c in range(cols):
                for _r in range(rows):
                    self._mov()
                self.y -= rows
                self.x += 1
        self.x, self.y = self._xs, self._ys
        self.y += rows


def pairs(name):
    if name == '4misc2x2':
        s = _St(0, 0)
        for n in (16, 16, 14):
            s.conv(2, 2, n)
    elif name == '4misc4x4':
        s = _St(0, 6)
        s.conv(4, 4, 3)
    elif name == '4misc1x1':
        s = _St(0, 10)
        s.conv(1, 1, 30)
        s.conv(1, 1, 10)
    elif name == '4misc1x2':
        s = _St(0, 12)
        s.conv(2, 1, 8)
    elif name == '4misc3x3':
        s = _St(0, 14)
        s.conv(3, 3, 9)
    else:
        raise ValueError(name)
    return s.pairs


_cache = {}


def plan(name):
    if name not in _cache:
        _cache[name] = pairs(name)
    return _cache[name]


def convert(sheet, name):
    return C.apply_pairs(plan(name), sheet, 2 * len(plan(name)))


def main(argv=None):
    import argparse
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--images', default=os.path.join(C.ARCH, 'IMAGES'))
    ap.add_argument('--out', default=C.OUT)
    a = ap.parse_args(argv)
    sheet = C.read_tif(C.ci_path(a.images, '4misc.tif'), SHEET)
    total = 0
    for nm in NAMES:
        d = convert(sheet, nm)
        total += len(d)
        C.wr(os.path.join(a.out, nm + '.dat'), d)
        print('%s.dat saved (%u)' % (nm, len(d)))
    print('Всё успешно (всего %u байт).' % total)


if __name__ == '__main__':
    main()
