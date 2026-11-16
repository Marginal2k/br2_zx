#!/usr/bin/env python3
"""Текст игры -> номера глифов шрифта 4FONT.FNT (таблица CODE_MAIN из ЧВ1/tools/text.py).  python tools/gtext.py "1 - Люди" ..."""
import sys
CODE_MAIN = ("012345" "6789 _" "АБВГДЕ" "ЖЗИЙКЛ" "МНОПРС" "ТУФХЦЧ" "ШЩЬЫЭЮ" "Я:?.,!" "абвгде" "жзийкл" "мнопрс"
             "туфхцч" "шщьыъэ" "юяёNRS" "IFY()%" "/-^^^^" "^*'abc" "Ddefgh" "<>GJLU")
ENC = {c: i for i, c in enumerate(CODE_MAIN)}
ENC[' '] = 10
def enc(s):
    return [ENC[c] for c in s] + [127]
if __name__ == '__main__':
    for s in sys.argv[1:]:
        print('\tDEFB\t' + ','.join(str(x) for x in enc(s)) + ' ;' + s)
