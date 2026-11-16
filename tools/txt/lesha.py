#!/usr/bin/env python3
"""2LESHA: транслитерация русского текста (cp866) в латиницу ("перекодировка писем для Лёхи").

Порт CPP/2LESHA.CPP: in.txt -> 2lesha.txt. Заглавные: А -> A, Ж -> Zh, Щ -> Sch ...; строчные - то же с маленькой первой буквой;
Ё -> YO, ё -> yo; остальные байты без изменений. (Комментарий автора говорит "koi8", но сравнения в исходнике идут с
буквами cp866, поэтому вход - cp866.)

    python -I tools/txt/lesha.py in.txt 2lesha.txt
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from txt import common as _T  # noqa: E402,F401  (кодировка консоли)

CODE = ("A..B..V..G..D..E..Zh.Z..I..J..K..L..M..N..O..P.."
        "R..S..T..U..F..H..Ts.Ch.Sh.Sch'..Y..'..Ye.Yu.Ya.")


def _copy(n):
    """buf[i] = code[n*3+i] до '.'; возвращает (строка, длина)"""
    buf = []
    i = 0
    while i < 3:
        buf.append(CODE[n * 3 + i])
        if buf[i] == '.':
            break
        i += 1
    return buf, i


def conv(data):
    """bytes (cp866) -> bytes"""
    out = bytearray()
    for c in data:
        buf = [chr(c)]
        ln = 1
        if c == 0xF0:                         # Ё
            buf, ln = ['Y', 'O'], 2
        if c == 0xF1:                         # ё
            buf, ln = ['y', 'o'], 2
        if 0x80 <= c <= 0x9F:                 # А..Я
            buf, ln = _copy(c - 0x80)
        if 0xA0 <= c <= 0xAF or 0xE0 <= c <= 0xEF:     # а..п, р..я
            n = c - 0xA0
            if n > 32:
                n -= 48
            buf, ln = _copy(n)
            if buf[0] != "'":
                buf[0] = chr(ord(buf[0]) + 32)
        out += ''.join(buf[:ln]).encode('latin-1')
    return bytes(out)


def main(argv=None):
    if len(argv or sys.argv[1:]) != 2:
        print(__doc__)
        return
    a = argv or sys.argv[1:]
    with open(a[0], 'rb') as f:
        d = f.read()
    with open(a[1], 'wb') as f:
        f.write(conv(d))
    print('ok')


if __name__ == '__main__':
    main()
