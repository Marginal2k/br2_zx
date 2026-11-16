#!/usr/bin/env python3
"""4ELLIPS: таблица траектории (эллипс, 60 точек DEFB x,y) для ELIPS44 в ASM80/4LIK1.A80.

Порт CPP/4ELLIPS.CPP (активная часть main; первый, закомментированный вариант автор оставил в /* */).
Вычисления как в Turbo C: float (32 бита) для переменных, double для sin/cos, (int) - усечение к нулю.
В 4LIK1.A80 таблица вставлена со сдвигом: строка k таблицы автора = точка (k+22) mod 60 вывода программы (i=0 - строка 38).
В сборке v0.04 таблица удалена вместе с ELIPS44.

    python -I tools/txt/ellips.py [--shift 22]
"""
import math
import os
import struct
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from txt import common as _T  # noqa: E402,F401  (кодировка консоли)


def f32(v):
    return struct.unpack('<f', struct.pack('<f', v))[0]


def table():
    """-> [(x, y)] для i = 0..59"""
    pi = f32(3.1415926)
    r = f32(60.0)
    r0 = f32(38.0)
    res = []
    for i in range(60):
        fi = float(i)
        a = (2. * pi * fi) / 12.
        a0 = (2. * pi * fi) / 20.
        x = f32(math.sin(a) * r + math.cos(a0) * r0)
        y = f32(math.cos(a) * r - math.sin(a0) * r0)
        x = f32(x + 4)                 # корректировка для игры
        y = f32(y * 0.75 - 2)
        res.append((int(x), int(y)))
    return res


def main(argv=None):
    import argparse
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--shift', type=int, default=0, help='начать вывод с точки i=SHIFT (22 - как в 4LIK1.A80)')
    a = ap.parse_args(argv)
    t = table()
    for k in range(60):
        x, y = t[(k + a.shift) % 60]
        print(' DEFB %i,%i' % (x, y))


if __name__ == '__main__':
    main()
