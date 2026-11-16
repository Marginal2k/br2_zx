"""Все русские строки интерфейса (ключи перевода) должны быть в js/i18n.js:  python -I editor/test/i18n_check.py [--dump ФАЙЛ]
--dump ФАЙЛ записывает недостающие ключи (JSON-строки, UTF-8)."""
import html
import json
import os
import re
import sys

ED = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
keys = []
RU = re.compile('[А-Яа-яЁё]')


def add(k):
    k = k.strip()
    if k and RU.search(k) and k not in keys:
        keys.append(k)


def strings_of(src, name):
    m = re.search(r'const ' + name + r' = (\[.*?\]);', src, re.S)
    return re.findall(r"'((?:[^'\\]|\\.)*)'", m.group(1)) if m else []


for f in ['js/app.js', 'js/core.js']:
    s = open(os.path.join(ED, f), encoding='utf-8').read()
    for m in re.finditer(r"\b(?:t|tr)\('((?:[^'\\]|\\.)*)'", s):
        add(m.group(1).replace("\\'", "'"))
app = open(os.path.join(ED, 'js/app.js'), encoding='utf-8').read()
for name in ['HNAME', 'ONAME', 'LANDS']:
    for x in strings_of(app, name):
        add(x)
for x in re.findall(r"\[\d+, \d+, '([^']*)'\]", app):                      # TILE_GROUPS
    add(x)
m = re.search(r'const SAMPLE_NOTE = \{(.*?)\};', app, re.S)
for x in re.findall(r": '([^']*)'", m.group(1)):
    add(x)
m = re.search(r'const OWNER_NAME = \{(.*?)\};', app, re.S)
for x in re.findall(r"'([^']*)'", m.group(1)):
    add(x)
h = open(os.path.join(ED, 'index.html'), encoding='utf-8').read()
body = h[h.index('<body>'):h.index('<script')]
for m in re.finditer(r'(?:title|placeholder)="([^"]*)"', body):
    add(html.unescape(m.group(1)))
for m in re.finditer(r'>([^<]+)<', body):
    add(html.unescape(m.group(1)))

src = open(os.path.join(ED, 'js/i18n.js'), encoding='utf-8').read()
have = json.loads(re.search(r'const EN = (\{.*?\n\});', src, re.S).group(1))
miss = [k for k in keys if k not in have]
extra = [k for k in have if k not in keys]
print('keys', len(keys), 'missing', len(miss), 'unused', len(extra))
if '--dump' in sys.argv:
    with open(sys.argv[sys.argv.index('--dump') + 1], 'w', encoding='utf-8') as f:
        f.write(chr(10).join(json.dumps(k, ensure_ascii=False) for k in miss) + chr(10))
else:
    for k in miss:
        print('MISSING:', k.encode('ascii', 'replace').decode())
for k in extra:
    print('UNUSED:', k.encode('ascii', 'replace').decode())
sys.exit(1 if miss else 0)
