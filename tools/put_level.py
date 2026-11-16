#!/usr/bin/env python3
"""Уровень из веб-редактора (editor/) -> диск TR-DOS с этим уровнем вместо уровня людей или кунгов.  python -I tools/put_level.py ...

    python -I tools/put_level.py --side hum --map мой.MAP --her мой.HER [--out build/put/hum_мой]
    python -I tools/put_level.py --side kun --map 4_4.MAP --her 4_4.HER

build.py НЕ правится и не запускается на месте: скрипт собирает во временном каталоге копию нужного (build.py, src/, assets/, tools/*.py, tools/bin,
work/src_v04/start1, archive/.../TV16), подменяет в копии файлы уровня и запускает там `python build.py`. Результат: br2_1mb.trd, br2_game.trd, br2_intro.trd
в каталоге --out (по умолчанию build/put/<сторона>_<имя>/). Файлы проекта (assets/, build/) не меняются.

Как build.py берёт уровни (сверено по build.py и src/game/level.asm, io.asm):
  люди  - карта (4096 байт) из assets/hum/M_r6161_8000.bin (INCBIN в level.asm, страница 2 #8000) и BUF512 из assets/hum/datMIN.bin
          (16 байт параметров шахт + 496 байт .HER). Подменяются первые 4096 байт .MAP и байты 16..511 datMIN (шахты остаются).
  кунги - assets/map/4_4.map (первые 4096 байт) и assets/map/4_4.her (в BUF512+16): подменяются сами файлы.
Миникарта (256 байт) и байт типа из .MAP в файл уровня не попадают - игра v0.04 берёт карту и героев. Ландшафт игры задаётся не картой, а
переменной fsLAND (люди 5 -> 45SPR, кунги 4 -> 44SPR): байт [0][0] карты для игры значения не имеет, редактор предупреждает, если он другой.
"""
import argparse
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def main():
    for st in (sys.stdout, sys.stderr):
        try:
            st.reconfigure(encoding='utf-8', errors='replace')
        except (AttributeError, ValueError):
            pass
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--side', required=True, choices=['hum', 'kun'], help='hum - уровень людей, kun - уровень кунгов')
    ap.add_argument('--map', required=True, help='файл .MAP (4353 байта; можно и 4096)')
    ap.add_argument('--her', required=True, help='файл .HER (496 байт)')
    ap.add_argument('--out', help='каталог результата (по умолчанию build/put/<сторона>_<имя>)')
    ap.add_argument('--keep', action='store_true', help='не удалять временный каталог сборки')
    a = ap.parse_args()
    m = open(a.map, 'rb').read()
    h = open(a.her, 'rb').read()
    if len(m) not in (4096, 4353):
        sys.exit('.MAP: %d байт, нужно 4353 (или 4096)' % len(m))
    if len(h) != 496:
        sys.exit('.HER: %d байт, нужно 496' % len(h))
    name = os.path.splitext(os.path.basename(a.map))[0]
    out = os.path.abspath(a.out or os.path.join(ROOT, 'build', 'put', '%s_%s' % (a.side, name)))
    tmp = tempfile.mkdtemp(prefix='br2_put_')
    try:
        cp = lambda *p: shutil.copytree(os.path.join(ROOT, *p), os.path.join(tmp, *p))
        shutil.copy(os.path.join(ROOT, 'build.py'), tmp)
        for d in ('src', 'assets'):
            cp(d)
        # весь tools/ (gfx/, txt/, bin/ нужны build.py), кроме харнесса эмулятора и кэшей
        shutil.copytree(os.path.join(ROOT, 'tools'), os.path.join(tmp, 'tools'), ignore=shutil.ignore_patterns('emu', '__pycache__'))
        cp('work', 'src_v04', 'start1')
        cp('archive', 'unz', 'BR2_DEMO', 'TV16')
        if a.side == 'hum':
            p = os.path.join(tmp, 'assets', 'hum')
            old = open(os.path.join(p, 'datMIN.bin'), 'rb').read()
            assert len(old) == 512
            open(os.path.join(p, 'M_r6161_8000.bin'), 'wb').write(m[:4096])
            open(os.path.join(p, 'datMIN.bin'), 'wb').write(old[:16] + h)
        else:
            p = os.path.join(tmp, 'assets', 'map')
            open(os.path.join(p, '4_4.map'), 'wb').write(m[:4096])
            open(os.path.join(p, '4_4.her'), 'wb').write(h)
        print('сборка во временном каталоге', tmp)
        r = subprocess.run([sys.executable, '-I', 'build.py', '--bin-assets'], cwd=tmp, capture_output=True, text=True, encoding='utf-8', errors='replace')
        if r.returncode:
            print(r.stdout[-3000:], r.stderr[-3000:])
            sys.exit('build.py: ошибка (код %d)' % r.returncode)
        os.makedirs(out, exist_ok=True)
        for f in ('br2_1mb.trd', 'br2_game.trd', 'br2_intro.trd'):
            shutil.copy(os.path.join(tmp, 'build', f), out)
        print('готово:', out)
        for f in ('br2_1mb.trd', 'br2_game.trd', 'br2_intro.trd'):
            print('  ', os.path.join(out, f))
    finally:
        if not a.keep:
            shutil.rmtree(tmp, ignore_errors=True)


if __name__ == '__main__':
    main()
