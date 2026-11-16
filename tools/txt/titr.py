#!/usr/bin/env python3
"""4TEXT: титры. DOC/4FLICTXT.TXT -> DATA/4FLICTXT.DAT (38 блоков по 16 строк x 12 знаков),
DOC/4VICTHUM.TXT, 4VICTKUN.TXT -> DATA/4VICTHUM.DAT, 4VICTKUN.DAT (бегущая строка по 12 знаков, зашифрованная).

Порт CPP/4TEXT.CPP.
Формат текста: строка <= 12 знаков центруется ((12-k)/2); блок титров - до 16 строк, заканчивается строкой '#' (или '$'),
недостающие строки - пустые; для скролла - строки до строки '#'. Знаки - таблица code[] (см. txt/common.py).
Файл блока: bu[12][16] (по столбцам: 16 байт столбца 0, потом столбца 1...). Скролл: 12 байт на строку, шифр "сумма"
(COD1 += COD2; COD2 += 2; c = x + COD1; COD1 = c), состояние сквозное на весь файл, в конце 10 байт (255 + остаток строки).

    python -I tools/txt/titr.py [--doc ARCH/DOC] [--out DIR]
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from txt import common as T  # noqa: E402

BLK_FLIC = 38


def _line_len(m, p):
    k = 0
    while True:
        if p + k >= len(m):
            raise T.TextError('конец файла: нет конца строки')
        if m[p + k] == '\r':
            return k
        k += 1


def convert_titr(m, blk):
    """текст (CRLF) -> bytes (blk блоков по 192 байта; blk=None - сколько блоков в тексте)"""
    out = bytearray()
    p = 0
    ch = lambda i: m[i] if i < len(m) else '\0'  # noqa: E731
    l = -1
    while (l + 1 < blk) if blk is not None else (p < len(m)):       # blk=None: все блоки текста
        l += 1
        bu = [[T.SPACE] * 16 for _ in range(12)]
        for j in range(16):
            for i in range(12):
                bu[i][j] = T.SPACE
            if ch(p) != '#' and ch(p) != '$':
                k = _line_len(m, p)
                codes = T.enc_text(m[p:p + k], '%d:%d' % (l, j))
                if len(codes) > 12:
                    raise T.TextError('Длинная строка! (блок %d, строка %d)' % (l, j))
                abzac = (12 - len(codes)) // 2
                for i, c in enumerate(codes):
                    bu[i + abzac][j] = c
                p += k + 2
        if ch(p) != '#' and ch(p) != '$':
            raise T.TextError('Длинный блок! (блок %d)' % l)
        p += 3
        out += bytes(bu[i][j] for i in range(12) for j in range(16))
    return bytes(out)


def script(bb, st):
    """зашифровать 12 байт на месте (st = [COD1, COD2])"""
    for i in range(12):
        c = bb[i]
        st[0] = (st[0] + st[1]) & 255
        st[1] = (st[1] + 2) & 255
        c = (c + st[0]) & 255
        st[0] = c
        bb[i] = c


def convert_scroll(m):
    """текст (CRLF) -> bytes"""
    out = bytearray()
    st = [0x7A, 0x29]
    p = 0
    ch = lambda i: m[i] if i < len(m) else '\0'  # noqa: E731
    bu = [T.SPACE] * 12
    while ch(p) != '#':
        bu = [T.SPACE] * 12
        k = _line_len(m, p)
        codes = T.enc_text(m[p:p + k], 'скролл')
        if len(codes) > 12:
            raise T.TextError('Длинная строка! %r' % m[p:p + k])
        abzac = (12 - len(codes)) // 2
        for i, c in enumerate(codes):
            bu[i + abzac] = c
        p += k + 2
        script(bu, st)
        out += bytes(bu)
    bu[0] = 255
    script(bu, st)
    out += bytes(bu[:10])
    return bytes(out)


# ----------------------------------------------------------------------------- обратный ход (DAT -> текст)
def decode_titr(data):
    """bytes (блоки по 192) -> текст (CRLF); для каждого блока строки до последней непустой и строка '#'"""
    if len(data) % 192:
        raise T.TextError('длина %d не кратна 192' % len(data))
    lines = []
    for b in range(len(data) // 192):
        blk = data[b * 192:(b + 1) * 192]
        rows = [T.dec_row([blk[i * 16 + j] for i in range(12)]) for j in range(16)]
        while rows and not rows[-1]:
            rows.pop()
        lines += rows + ['#']
    return '\r\n'.join(lines) + '\r\n'


def decode_scroll(data):
    """bytes -> текст (CRLF)"""
    if len(data) < 10 or (len(data) - 10) % 12:
        raise T.TextError('длина скролла %d' % len(data))
    c1, c2 = 0x7A, 0x29
    plain = []
    for y in data:
        c1 = (c1 + c2) & 255
        c2 = (c2 + 2) & 255
        plain.append((y - c1) & 255)
        c1 = y
    n = (len(data) - 10) // 12
    if plain[12 * n] != 255:
        raise T.TextError('нет признака конца (255)')
    lines = [T.dec_row(plain[i * 12:(i + 1) * 12]) for i in range(n)]
    return '\r\n'.join(lines + ['#']) + '\r\n'


def main(argv=None):
    import argparse
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--doc', default=os.path.join(T.ARCH, 'DOC'))
    ap.add_argument('--out', default=T.OUT)
    a = ap.parse_args(argv)
    T.wr(os.path.join(a.out, '4flictxt.dat'), convert_titr(T.rdcp866(os.path.join(a.doc, '4flictxt.txt')), BLK_FLIC))
    T.wr(os.path.join(a.out, '4victhum.dat'), convert_scroll(T.rdcp866(os.path.join(a.doc, '4victhum.txt'))))
    T.wr(os.path.join(a.out, '4victkun.dat'), convert_scroll(T.rdcp866(os.path.join(a.doc, '4victkun.txt'))))
    print('O.K.')


if __name__ == '__main__':
    main()
