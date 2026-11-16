#!/usr/bin/env python3
"""One-off clean-up of the final tree: numbers that are really names of fixed areas become symbols (bytes do not change).
   python tools/symbolize_consts.py work/src_v04/hum
Fixed areas: stack top (#403E), level blocks (MAP #8000, MAP2 #9000, DSCR #A000, BUF512 #B800, KUNGE #7B04), screen (SCR #C000, ATR #D800),
music module internals (WMUSIC+n), the variable isGS at #4000."""
import os, re, sys
NL = chr(10)
TAB = chr(9)
RULES = [
    (r'(?<![\w#])#403E\b', 'STKTOP'),
    (r'(?<![\w#])#7B04\b', 'KUNGE'),
    (r'(?<![\w#])#EEC9\b', 'WMUSIC+#252'),
    (r'(?<![\w#])#F221\b', 'WMUSIC+#5AA'),
]
LDRULES = [
    (r'(?<![\w#])#A000\b', 'DSCR'),
    (r'(?<![\w#])#A016\b', 'DSCR+#16'),
    (r'(?<![\w#])#B0C0\b', 'DSCR+#10C0'),
    (r'(?<![\w#])#B014\b', 'DSCR+#1014'),
    (r'(?<![\w#])#A021\b', 'DSCR+#21'),
    (r'(?<![\w#])#A8B4\b', 'DSCR+#8B4'),
    (r'(?<![\w#])#8000\b', 'MAP'),
    (r'(?<![\w#])#9000\b', 'MAP2'),
    (r'(?<![\w#])#DA1F\b', 'ATR+#1FF+#20'),
]
SCRRULES = [
    (r'(?<![\w#])#C000\b', 'SCR'),
    (r'(?<![\w#])#C098\b', 'SCR+#98'),
    (r'(?<![\w#])#D800\b', 'ATR'),
    (r'(?<![\w#])#D8B0\b', 'ATR+#B0'),
]


def main(tree):
    n = 0
    for fn in sorted(os.listdir(tree)):
        if not fn.endswith('.asm') or fn == 'top.asm':
            continue
        p = os.path.join(tree, fn)
        L = open(p, encoding='utf-8').read().split(NL)
        for i, l in enumerate(L):
            code, sep, com = l.partition(';')
            if not re.search(r'\s(LD|CP|ADD|SBC|ADC|SUB|AND|OR|XOR|JP|CALL)\s', code, re.I) or re.search(r'\bLD\s+BC,#[0-9A-F]{2}(FE|FD|DF|BF|FB|F7|EF|7F)\b', code, re.I):
                continue
            new = code
            rules = RULES + LDRULES + (SCRRULES if fn in ('lib2.asm',) else [])
            for rx, sub in rules:
                new = re.sub(rx, sub, new)
            if re.search(r'LD\s+\(#4000\),A', new):
                new = new.replace('(#4000)', '(isGS)')
            if new != code:
                L[i] = new + sep + com
                n += 1
        open(p, 'w', encoding='utf-8', newline=NL).write(NL.join(L))
    print('lines changed:', n)


if __name__ == '__main__':
    main(sys.argv[1])
