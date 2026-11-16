#!/usr/bin/env python3
"""Снимок страницы редактора в headless Chrome/Edge:  python -I editor/tools/shot.py 'open=4_10&tab=heroes' img/heroes.png (или 'marking.html?land=5&pane=ring') [ширина высота] [порт]
Поднимает http.server на свободном порту (своим процессом), снимает, завершает только свой процесс."""
import os, subprocess, sys, tempfile, time, shutil, socket

ED = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
q, out = sys.argv[1], os.path.abspath(sys.argv[2])
page = 'index.html'
if '.html' in q.split('?')[0]:        # 'marking.html?land=5' - другая страница
    page, _, q = q.partition('?')
w, h = (int(sys.argv[3]), int(sys.argv[4])) if len(sys.argv) > 4 else (1500, 900)
s = socket.socket(); s.bind(('127.0.0.1', 0)); port = s.getsockname()[1]; s.close()
srv = subprocess.Popen([sys.executable, '-I', '-m', 'http.server', str(port), '--bind', '127.0.0.1', '--directory', ED], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
try:
    time.sleep(1)
    exe = next((p for p in (r'C:\Program Files\Google\Chrome\Application\chrome.exe', r'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe') if os.path.exists(p)), None)
    prof = tempfile.mkdtemp(prefix='br2shot_')
    cmd = [exe, '--headless=new', '--disable-gpu', '--hide-scrollbars', '--no-first-run', '--user-data-dir=' + prof, '--window-size=%d,%d' % (w, h),
           '--virtual-time-budget=4000', '--screenshot=' + out, 'http://127.0.0.1:%d/%s?%s' % (port, page, q)]
    subprocess.run(cmd, capture_output=True, timeout=120)
    shutil.rmtree(prof, ignore_errors=True)
    print(out, os.path.exists(out))
finally:
    srv.terminate()
