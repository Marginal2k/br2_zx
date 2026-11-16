#!/usr/bin/env python3
"""2SOKOLOV: поиск двухбайтового ключа XOR (SLAVA.XOR) по известной строке.

Порт CPP/2SOKOLOV.CPP. Ищет в файле позицию i, где строка s (не короче 4 знаков) совпадает с данными, зашифрованными
ключом из двух байт (ключ[j&1], j - номер знака в строке): key0 = x[0]^s[0], key1 = x[1]^s[1], дальше проверяется
s[j] == x[j]^key[j&1]. (Исходник печатал "Привет Славе Соколову от Славы Медноногова".)

    python -I tools/txt/sokolov.py FILE STRING
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from txt import common as _T  # noqa: E402,F401  (кодировка консоли)


def find_key(mem, s):
    """-> (смещение, key[0], key[1]) или None; s - bytes длиной >= 4"""
    n = len(s)
    if n < 4:
        raise ValueError('Введите строку не менее, чем из 4-х символов')
    for i in range(len(mem) - n + 1):
        k0 = mem[i] ^ s[0]
        k1 = mem[i + 1] ^ s[1]
        key = (k0, k1)
        if all(s[j] == (mem[i + j] ^ key[j & 1]) for j in range(2, n)):
            return i, k0, k1
    return None


def main(argv=None):
    a = argv or sys.argv[1:]
    if len(a) != 2:
        print(__doc__)
        return
    with open(a[0], 'rb') as f:
        mem = f.read()
    r = find_key(mem, a[1].encode('cp866'))
    if r is None:
        print(' ключ не найден :(')
    else:
        print(' ключ найден!!\nСтрока "%s" расположена по адресу #%06X\nЗначение ключа - #%02X%02X' % (a[1], r[0], r[2], r[1]))


if __name__ == '__main__':
    main()
