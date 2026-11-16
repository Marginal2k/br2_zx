#!/usr/bin/env python3
"""4TSKTXT2: тексты заданий уровней. DOC/4TASKS.TXT -> TASK/4_NNN.TSK (малое задание, 4x20) и 4_NNN.TS2 (полное, 24x32).

Порт CPP/4TSKTXT2.CPP. Формат DOC/4TASKS.TXT:

    #NNN                 номер уровня (3 знака)
    малое задание        до 4 строк, до 20 знаков
    ##
    полное задание       до 24 строк, до 32 знаков
    ...
    #END

Строки центруются по горизонтали ((max_x-x)/2) и по вертикали ((max_y-y)/2); в файле каждая строка заканчивается байтом 127.
Полное задание хранится "через строку" (для вывода с чересстрочным заполнением): строка j файла = строка i листа,
i = j/2 для чётных j и 23 - j/2 для нечётных. Знаки - таблица code[] (txt/common.py).

    python -I tools/txt/tasks.py [--doc ARCH/DOC/4tasks.txt] [--out DIR]
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from txt import common as T  # noqa: E402

CR, LF = '\r', '\n'


def _is_end(m, p, line):
    if m[p:p + 2] == CR + LF:
        return p + 2, line + 1
    raise T.TextError('Не обнаружен конец строки %u' % line)


def conv_one_task(m, p, line, max_y, max_x):
    """читает строки с позиции p до '#'; возвращает (байты файла, p, line)"""
    ps = []
    while m[p:p + 1] != '#':
        if p >= len(m):
            raise T.TextError('конец файла в задании (line=%u)' % line)
        if len(ps) >= max_y:
            raise T.TextError('Cлишком много строк в задании (line=%u)' % line)
        q = m.index(CR, p)
        codes = T.enc_text(m[p:q], line)
        if len(codes) > max_x:
            raise T.TextError('Cлишком много букв в строке %u' % line)
        row = [T.SPACE] * max_x
        x1 = (max_x - len(codes)) // 2
        row[x1:x1 + len(codes)] = codes
        ps.append(row)
        p, line = _is_end(m, q, line)
    y = len(ps)
    y1 = (max_y - y) // 2
    out = bytearray()
    for j in range(max_y):
        if max_y == 4:
            i = j
        else:
            i = j // 2 if j % 2 == 0 else 23 - j // 2
        out += bytes(ps[i - y1]) if y1 <= i < y + y1 else bytes([T.SPACE] * max_x)
        out.append(127)
    return bytes(out), p, line


def tsk_conv(m):
    """весь файл заданий -> [(номер, .tsk, .ts2)]"""
    res = []
    p, line = 0, 1
    if m[p:p + 1] != '#':
        raise T.TextError('Ошибочное начало файла')
    while True:
        p += 1
        if m[p:p + 3] == 'END':
            return res
        n = m[p:p + 3]
        p += 3
        p, line = _is_end(m, p, line)
        tsk, p, line = conv_one_task(m, p, line, 4, 20)
        p += 1
        if m[p:p + 1] != '#':
            raise T.TextError('Ошибочный разделитель заданий в строке %u' % line)
        p += 1
        p, line = _is_end(m, p, line)
        ts2, p, line = conv_one_task(m, p, line, 24, 32)
        res.append((n, tsk, ts2))


# ----------------------------------------------------------------------------- обратный ход
def _rows(data, max_y, max_x):
    if len(data) != max_y * (max_x + 1):
        raise T.TextError('длина %d, нужна %d' % (len(data), max_y * (max_x + 1)))
    lines = [None] * max_y
    for j in range(max_y):
        row = data[j * (max_x + 1):(j + 1) * (max_x + 1)]
        if row[max_x] != 127:
            raise T.TextError('нет байта 127 в конце строки %d' % j)
        i = j if max_y == 4 else (j // 2 if j % 2 == 0 else 23 - j // 2)
        lines[i] = list(row[:max_x])
    return lines


def decode_task(data, max_y, max_x):
    """файл задания -> строки текста (так, чтобы порт дал те же байты)"""
    lines = _rows(data, max_y, max_x)
    nb = [i for i, r in enumerate(lines) if any(c != T.SPACE for c in r)]
    if not nb:
        return []
    for y in range(nb[-1] - nb[0] + 1, max_y + 1):          # y1 = (max_y-y)//2 - позиция первой строки
        y1 = (max_y - y) // 2
        if y1 <= nb[0] and y1 + y > nb[-1]:
            break
    else:
        raise T.TextError('задание не получено центровкой')
    return [T.dec_row(lines[i]) for i in range(y1, y1 + y)]


def decode_tasks(items):
    """[(номер, .tsk, .ts2)] -> текст DOC/4TASKS.TXT (CRLF)"""
    out = []
    for n, tsk, ts2 in items:
        out += ['#' + n] + decode_task(tsk, 4, 20) + ['##'] + decode_task(ts2, 24, 32)
    return '\r\n'.join(out + ['#END']) + '\r\n'


def main(argv=None):
    import argparse
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--doc', default=os.path.join(T.ARCH, 'DOC', '4tasks.txt'))
    ap.add_argument('--out', default=T.OUT)
    a = ap.parse_args(argv)
    for n, tsk, ts2 in tsk_conv(T.rdcp866(a.doc)):
        T.wr(os.path.join(a.out, '4_%s.tsk' % n), tsk)
        T.wr(os.path.join(a.out, '4_%s.ts2' % n), ts2)
        print('4_%s.tsk 4_%s.ts2' % (n, n))


if __name__ == '__main__':
    main()
