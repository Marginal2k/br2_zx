#!/usr/bin/env python3
"""Проверка редактора уровней BR2:  python -I editor/test/run_tests.py

1. node editor/test/roundtrip.js - все пары .MAP/.HER архива: открыть -> сохранить -> побайтно то же; миникарта и тип по алгоритму MAPPER = записанные
   автором; проект JSON; задания .TSK/.TS2; правки (здания, кисть, патруль, туман).
2. встроенные данные data/br2data.js совпадают с файлами архива (часть roundtrip.js) и с тем, что собирает tools/make_data.py (сверка без записи).
3. перевод интерфейса: у каждой русской строки есть английская (test/i18n_check.py).
4. синтаксис js/app.js (node --check).
Код возврата 0 - всё совпало.
"""
import os
import subprocess
import sys
import tempfile

ED = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
T = os.path.join(ED, 'test')


def run(title, cmd):
    print('---', title)
    sys.stdout.flush()
    r = subprocess.run(cmd, cwd=ED)
    return r.returncode


def main():
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    fails = 0
    fails += bool(run('node test/roundtrip.js', ['node', os.path.join(T, 'roundtrip.js')]))
    # make_data.py во временный файл: сравнить с data/br2data.js
    tmp = tempfile.mkdtemp(prefix='br2ed_')
    src = open(os.path.join(ED, 'tools', 'make_data.py'), encoding='utf-8').read().replace(
        "out = os.path.join(ED, 'data', 'br2data.js')", "out = " + repr(os.path.join(tmp, 'br2data.js')))
    p = os.path.join(tmp, 'md.py')
    open(p, 'w', encoding='utf-8').write(src.replace("ED = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))", "ED = " + repr(ED)))
    print('--- make_data.py: br2data.js воспроизводится')
    r = subprocess.run([sys.executable, '-I', p], capture_output=True)
    same = open(os.path.join(tmp, 'br2data.js'), 'rb').read() == open(os.path.join(ED, 'data', 'br2data.js'), 'rb').read() if r.returncode == 0 else False
    print('br2data.js совпадает с результатом make_data.py:', same)
    fails += 0 if same else 1
    fails += bool(run('i18n_check.py', [sys.executable, '-I', os.path.join(T, 'i18n_check.py')]))
    fails += bool(run('node --check js/app.js', ['node', '--check', os.path.join(ED, 'js', 'app.js')]))
    fails += bool(run('node --check js/i18n.js', ['node', '--check', os.path.join(ED, 'js', 'i18n.js')]))
    print('ИТОГО:', 'всё совпало' if not fails else 'ошибок: %d' % fails)
    return 1 if fails else 0


if __name__ == '__main__':
    sys.exit(main())
