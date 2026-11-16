#!/usr/bin/env python3
"""4INTRO: картинки для интро (TV16/INTRO/00.TIF..11.TIF, по 160x128) -> DATA/4INTROF0.DAT, 4INTROF1.DAT (6 кадров по 2560 байт).

Порт CPP/4INTRO.CPP: файл - просто 6 листов подряд (первые 2560 байт каждого TIF).

    python -I tools/gfx/intro.py [--images ARCH/TV16/INTRO] [--out DIR]
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from gfx import common as C  # noqa: E402

FRAME = 2560            # 160x128 точек: 20 байт x 128 строк


def convert(frames):
    """6 кадров (по 2560 байт) -> блок 15360 байт"""
    return b''.join(bytes(f[:FRAME]) for f in frames)


def main(argv=None):
    import argparse
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--images', default=os.path.join(C.ARCH, 'TV16', 'INTRO'))
    ap.add_argument('--out', default=C.OUT)
    a = ap.parse_args(argv)
    for nb in (0, 1):
        fr = [C.read_tif(C.ci_path(a.images, '%02u.tif' % i), FRAME) for i in range(nb * 6, nb * 6 + 6)]
        C.wr(os.path.join(a.out, '4introf%u.dat' % nb), convert(fr))
    print('Картинки для интро конвертированы успешно.')


if __name__ == '__main__':
    main()
