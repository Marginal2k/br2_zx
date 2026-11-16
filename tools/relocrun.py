#!/usr/bin/env python3
"""Динамическая проверка перемещаемости: собирает игру со вставкой N байт в точке k (BR2_DEFS=RELOCN=.. RELOCW=..), запускает в эмуляторе (люди и кунги:
до первого прохода игрового цикла и ещё 100 кадров) и сравнивает снимки экрана с обычной сборкой.
    python -I tools/relocrun.py 56 [N]      (EMU_PORT задаёт среда, по умолчанию 8861)"""
import os, re, subprocess, sys, shutil, json, hashlib
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
k = sys.argv[1]; N = sys.argv[2] if len(sys.argv) > 2 else "7"
env = dict(os.environ, EMU_PORT=os.environ.get('EMU_PORT', '8861'), PYTHONIOENCODING='utf-8')

def build(defs):
    e = dict(env)
    if defs: e['BR2_DEFS'] = defs
    else: e.pop('BR2_DEFS', None)
    r = subprocess.run([sys.executable, '-I', 'build.py'], cwd=ROOT, env=e, capture_output=True, text=True)
    if r.returncode: sys.exit(r.stdout + r.stderr)
    syms = {}
    for l in open(os.path.join(ROOT, 'build', 'game', 'main.sym'), encoding='utf-8', errors='replace'):
        m = re.match(r'(\S+):\s+EQU\s+0x([0-9A-Fa-f]+)', l)
        if m: syms[m.group(1)] = int(m.group(2), 16)
    return syms

def run(tag, trd, loop, side):
    steps = ['boot', 'w1000', 'Kx', 'w300', 'd' + side, 'w6', 'u' + side, 'rt:%04X:1500' % loop, 's:a', 'w100', 's:b']
    r = subprocess.run([sys.executable, '-I', 'tools/emu/run_emu.py', 'play', 'name=' + tag, 'trd=' + trd, 'machine=128k', 'beta=1', 'snow=1', 'steps=' + ','.join(steps)],
                       cwd=ROOT, env=env, capture_output=True, text=True)
    out = r.stdout + r.stderr
    hit = re.search(r'rt \w+ (hit|NOT hit)', out)
    sh = {}
    for n in ('a', 'b'):
        p = os.path.join(ROOT, 'build', 'emu', '%s_%s.png' % (tag, n))
        sh[n] = hashlib.md5(open(p, 'rb').read()).hexdigest() if os.path.exists(p) else None
    return (hit.group(0) if hit else 'no rt'), sh

def diff_pixels(p1, p2):
    from PIL import Image, ImageChops
    a, b = Image.open(p1).convert('RGB'), Image.open(p2).convert('RGB')
    d = ImageChops.difference(a, b).convert('L').point(lambda v: 255 if v else 0)
    return sum(1 for v in d.getdata() if v), a.size[0] * a.size[1]

# эталон: обычная сборка (снимки rl_base_*), строится один раз; расхождения в позах юнитов - случайность (R, RND), поэтому сравнивается доля отличающихся точек
refs = {}
need_base = not all(os.path.exists(os.path.join(ROOT, 'build', 'emu', 'rl_base_%s_a.png' % sd)) for sd in ('1', '2'))
if need_base:
    syms = build('')
    shutil.copy(os.path.join(ROOT, 'build', 'br2_game.trd'), os.path.join(ROOT, 'build', 'rel_base_game.trd'))
    for sd in ('1', '2'):
        print('base', sd, run('rl_base_' + sd, 'rel_base_game.trd', syms['_start'] + 56, sd)[0])
syms = build('RELOCN=%s RELOCW=%s' % (N, k))
shutil.copy(os.path.join(ROOT, 'build', 'br2_game.trd'), os.path.join(ROOT, 'build', 'rel_%s_game.trd' % k))
ok = True
for sd in ('1', '2'):
    hit, sh = run('rl_%s_%s' % (k, sd), 'rel_%s_game.trd' % k, syms['_start'] + 56, sd)
    n, tot = diff_pixels(os.path.join(ROOT, 'build', 'emu', 'rl_base_%s_a.png' % sd), os.path.join(ROOT, 'build', 'emu', 'rl_%s_%s_a.png' % (k, sd)))
    good = 'NOT' not in hit and n * 100 < tot * 3
    ok = ok and good
    print('точка %s, сторона %s: %s; отличающихся точек в снимке %d из %d (%.2f%%): %s' % (k, 'люди' if sd == '1' else 'кунги', hit, n, tot, 100.0 * n / tot, 'OK' if good else 'ОШИБКА'))
build('')
sys.exit(0 if ok else 1)
