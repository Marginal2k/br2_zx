#!/usr/bin/env python3
"""4INSTR: текст инструкции. DOC/4INSTR.TXT -> DATA/4INSTR.DAT (сжатый текст) + DATA/4INSTRCM.DAT (словарь на 128 пар).

Порт CPP/4INSTR.CPP.
 1. convert_INSTR: '*' -> пробел; пробел перед концом строки выбрасывается; CR LF -> 126; '=' -> 127;
    остальные символы -> номер в таблице code[] (первые 111 знаков шрифта WNF1.FNT; первое совпадение).
 2. search: счёт всех пар соседних знаков (оба < 100), compress_ini: 128 самых частых пар (при равенстве - первая по
    порядку (a, b)) -> словарь cmpr[128][2]; compress: жадная замена пары на байт 127 + номер (128..255).
Обратный ход (decode): байты >= 128 раскрываются по словарю, 126 -> конец строки, 127 -> '='.

    python -I tools/txt/instr.py [--doc ARCH/DOC/4instr.txt] [--out DIR]
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from txt import common as T  # noqa: E402

CODE = (" яазвсьедцрфжтгб"
        "ыхнуймиколпЧэЭюШ"
        "ёЯАЗВЕСДЬЦЖФРТГБ"
        "ХЫУЙНМКИОЛПъшщчЩ"
        "ZЮVNSDFGJLWQRYUI"
        "2513460987,.:;-/"
        ")(!$%\"+?Ё#++++++")
assert len(CODE) == 112                      # автор ищет только среди первых 111 (j<111)
CANON = {i for i, c in enumerate(CODE[:111]) if CODE.index(c) == i}      # поиск автора берёт первое совпадение


def convert_INSTR(text):
    """str (CRLF) -> list кодов (0..127)"""
    m = list(text)
    n = len(m)
    out = []
    p = 0
    ln = n
    ch = lambda i: m[i] if i < n else '\0'  # noqa: E731
    l = n
    while l > 0:
        if ch(p) == '*':
            m[p] = ' '
        if ch(p) == ' ' and ch(p + 1) == '\r':
            l -= 1
            p += 1
            ln -= 1
        c = ch(p)
        if c == '\r':
            out.append(126)
            l -= 1
            p += 1
            ln -= 1
        elif c == '=':
            out.append(127)
        else:
            if c == '{' and text.find('}', p) > p:         # {NN} - код без однозначного символа (только для обратного хода)
                q = text.index('}', p)
                out.append(int(text[p + 1:q]))
                l -= q - p
                p = q
            else:
                j = CODE[:111].find(c)
                if j < 0:
                    raise T.TextError('Неверный символ в тексте (%r,%u)' % (c, ord(c)))
                out.append(j)
        p += 1
        l -= 1
    return out


def make_dict(codes):
    """search + compress_ini -> (cmpr[128] пар, таблица data[100][100] k+1 или 0)"""
    data = [[0] * 100 for _ in range(100)]
    for i in range(len(codes) - 1):
        a, b = codes[i], codes[i + 1]
        if a < 100 and b < 100:
            data[a][b] += 1
    cmpr = []
    for k in range(128):
        mx = mi = mj = 0
        for i in range(100):
            for j in range(100):
                if data[i][j] > mx:
                    mx, mi, mj = data[i][j], i, j
        cmpr.append((mi, mj))
        data[mi][mj] = -(k + 1)
    for i in range(100):
        for j in range(100):
            data[i][j] = 0 if data[i][j] > 0 else -data[i][j]
    return cmpr, data


def compress(codes, data):
    out = []
    n = len(codes)
    p = 0
    while p < n:
        a = codes[p]
        b = codes[p + 1] if p + 1 < n else 255          # за концом буфера - мусор; не <100, замены нет
        k = data[a][b] if a < 100 and b < 100 else 0
        if k > 0:
            out.append(k + 127)
            p += 2
        else:
            out.append(a)
            p += 1
    return bytes(out)


def pack_dict(cmpr):
    return bytes(v for pair in cmpr for v in pair)


def convert(text):
    """-> (4instr.dat, 4instrcm.dat)"""
    codes = convert_INSTR(text)
    cmpr, data = make_dict(codes)
    return compress(codes, data), pack_dict(cmpr)


def encode_with_dict(text, dict_bytes):
    """сжатие по готовому словарю (когда словарь нельзя получить из текста: см. docs/TOOLS.md)"""
    codes = convert_INSTR(text)
    data = [[0] * 100 for _ in range(100)]
    for k in range(128):
        a, b = dict_bytes[2 * k], dict_bytes[2 * k + 1]
        if data[a][b] == 0 or True:
            data[a][b] = k + 1
    return compress(codes, data)


def decode(dat, dict_bytes):
    """-> текст (CRLF)"""
    out = []

    def put(c):
        if c == 126:
            out.append('\r\n')
        elif c == 127:
            out.append('=')
        elif c < 111 and c in CANON:
            out.append(CODE[c])
        else:
            out.append('{%d}' % c)
    for b in dat:
        if b >= 128:
            k = b - 128
            put(dict_bytes[2 * k])
            put(dict_bytes[2 * k + 1])
        else:
            put(b)
    return ''.join(out)


def main(argv=None):
    import argparse
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--doc', default=os.path.join(T.ARCH, 'DOC', '4instr.txt'))
    ap.add_argument('--out', default=T.OUT)
    a = ap.parse_args(argv)
    dat, cm = convert(T.rdcp866(a.doc))
    T.wr(os.path.join(a.out, '4instr.dat'), dat)
    T.wr(os.path.join(a.out, '4instrcm.dat'), cm)
    print('Текст инструкции: %u байт' % len(dat))
    print('O.K.')


if __name__ == '__main__':
    main()
