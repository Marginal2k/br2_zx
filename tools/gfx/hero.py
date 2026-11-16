#!/usr/bin/env python3
"""4HERO: рисунок + маска героя (IMAGES/4HERO/*.TIF) -> DATA/HERO/*.DAT.

Порт CPP/4HERO.CPP. В листе 256x192 слева-направо лежат кадры: маска (строки yM..) и картинка (строки ys..).
Файл - пары байт (M, M^I): M - строка маски, I - строка картинки; столбцами (2/3 байта шириной), в каждом столбце
16 или 24 строк. Зеркальные кадры не хранятся (получаются в игре). Тип спрайта (1 цифра) выбирает порядок кадров:

    2: 2x2 (16x16) x15   3: 2x3 (16x24) x24   4: 2x2 x16   5: 2x3 x16   6: 2x2 x32   7: 3x3 (24x24) x3
    8: 3x3 x16   9: 2x2 x6   S: тень 3x2 (24x16) x5

    python -I tools/gfx/hero.py [--images ARCH/IMAGES/4HERO] [--out DIR]
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from gfx import common as C  # noqa: E402

# имя, тип (таблица styp[] автора)
STYP = [("4demon", "3"), ("4fighter", "8"), ("4fireman", "4"), ("4fly_tnk", "8"), ("4flyhome", "7"), ("4intr", "8"),
        ("4krakotn", "9"), ("4kunge", "4"), ("4peon", "6"), ("4shutl", "8"), ("4soldier", "4"), ("4stinger", "5"),
        ("4tank_tr", "8"), ("4tank_hd", "4"), ("4walker", "5"), ("4worker", "6"), ("4zenit", "2"), ("4zerg", "2"),
        ("4kapell", "2"), ("4king", "2"), ("4varlok", "2"), ("4~shadow", "S")]
SHEET = 6144
SIZES = {'2': 960, '3': 2304, '4': 1024, '5': 1536, '6': 2048, '7': 432, '8': 2304, '9': 384, 'S': 480}


class _St:
    """глобальные переменные автора (adr, xs, ys, yM, _xs...)"""

    def __init__(self):
        self.pairs = []
        self.xs = self.ys = self.yM = 0
        self._xs = self._ys = self._yM = 0

    def _push(self):
        self._xs, self._ys, self._yM = self.xs, self.ys, self.yM

    def _pop(self):
        self.xs, self.ys, self.yM = self._xs, self._ys, self._yM

    def _mov(self):
        self.pairs.append((self.yM * 32 + self.xs, self.ys * 32 + self.xs))
        self.yM += 1
        self.ys += 1

    def block(self, rows, cols):    # _2x2 (16,2), _2x3 (24,2), _3x3 (24,3), _3x2 (16,3)
        self._push()
        for c in range(cols):
            for _ in range(rows):
                self._mov()
            self._pop()
            self.xs += c + 1        # +1, +2 (, +3)

    def clr(self, mask):
        self.xs = self.ys = 0
        self.yM = mask


def pairs(typ):
    """список (ячейка маски, ячейка картинки) для типа спрайта: порядок байтов файла"""
    s = _St()
    if typ == '2':
        s.clr(32)
        for _ in range(10):
            s.block(16, 2)
        s.yM, s.ys, s.xs = 48, 16, 0
        for _ in range(5):
            s.block(16, 2)
            s.xs += 2
    elif typ == '3':
        s.clr(48)
        for _ in range(16):
            s.block(24, 2)
        s.yM, s.ys, s.xs = 72, 24, 0
        for _ in range(8):
            s.block(24, 2)
            s.xs += 2
    elif typ == '4':
        s.clr(16)
        for _ in range(16):
            s.block(16, 2)
    elif typ == '6':
        s.clr(64)
        for _ in range(8):
            s.block(16, 2)
        for yM, ys in ((80, 16), (96, 32), (112, 48)):
            s.yM, s.ys, s.xs = yM, ys, 0
            for _ in range(8):
                s.block(16, 2)
    elif typ == '7':
        s.clr(24)
        for _ in range(3):
            s.block(24, 3)
    elif typ == '8':
        s.clr(48)
        for _ in range(8):
            s.block(24, 3)
        s.yM, s.ys, s.xs = 72, 24, 0
        for _ in range(8):
            s.block(24, 3)
    elif typ == '9':
        s.clr(16)
        for _ in range(6):
            s.block(16, 2)
    elif typ == '5':
        s.clr(24)
        for _ in range(16):
            s.block(24, 2)
    elif typ == 'S':
        s.clr(16)
        for _ in range(5):
            s.block(16, 3)
    else:
        raise ValueError('Unknown sprite type!')
    return s.pairs


_cache = {}


def plan(typ):
    if typ not in _cache:
        _cache[typ] = pairs(typ)
    return _cache[typ]


def convert(hero, typ):
    """лист (6144, 1 = чернила) -> .dat"""
    return C.apply_pairs(plan(typ), hero, 2 * len(plan(typ)))


def main(argv=None):
    import argparse
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--images', default=os.path.join(C.ARCH, 'IMAGES', '4HERO'))
    ap.add_argument('--out', default=os.path.join(C.OUT, 'HERO'))
    a = ap.parse_args(argv)
    for name, typ in STYP:
        d = convert(C.read_tif(C.ci_path(a.images, name + '.tif'), SHEET), typ)
        C.wr(os.path.join(a.out, name + '.dat'), d)
        print('%s.dat saved (%u)' % (name, len(d)))


if __name__ == '__main__':
    main()
