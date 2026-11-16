#!/usr/bin/env python3
"""Справочная сверка адресов меток новой сборки (build/game) с образом v0.04 (build/v04/hum). С фазы 2b-4 страница 5 ПЕРЕМЕЩАЕМА (docs/NOTES.md 10.3):
расхождения адресов в ней ожидаемы и не ошибка; проверка перемещаемости - tools/check_reloc.py. Печатает только число расхождений.  python tools/cmp_syms.py [каталог]"""
import os, re, sys
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
def load(p):
    S = {}
    for l in open(p, encoding='utf-8', errors='replace'):
        m = re.match(r'(\S+):\s+EQU\s+0x([0-9A-Fa-f]+)', l)
        if m and '.' not in m.group(1):
            S[m.group(1)] = int(m.group(2), 16)
    return S
old = load(os.path.join(ROOT, 'build', 'v04', 'hum', 'main.sym'))
new = load(os.path.join(ROOT, sys.argv[1] if len(sys.argv) > 1 else 'build/g', 'main.sym'))
SKIP = [(0x5794, 0x5B3A), (0x5ECA, 0x5F55), (0xBA00, 0xC000)]  # новые модули; старые массивы и переменные уровня страницы 2 (теперь IM2_TAB, массивы выше, переменные - в странице 5)          # области новых модулей
bad = 0
for k, v in sorted(old.items(), key=lambda x: x[1]):
    if k in new and new[k] != v and not any(a <= v < b for a, b in SKIP) and 0x4000 <= v < 0xC000:
        bad += 1
print('расхождений:', bad)
