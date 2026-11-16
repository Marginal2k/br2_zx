#!/usr/bin/env python3
"""Run a harness script in headless Chrome/Edge against ZX-M8XXX and save the result.

    python tools/emu/run_emu.py play name=t trd=br_1mb.trd machine=pentagon steps=@boot png=1

Everything after the script name is passed to the script as URL query parameters.
Results: build/emu/<name>.json; shots -> build/emu/<name>_<shot>.png; log lines printed.
"""
import base64, json, os, shutil, subprocess, sys, tempfile, time, urllib.parse

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
EDGE = os.environ.get('EDGE') or next((p for p in (
    r'C:\Program Files\Google\Chrome\Application\chrome.exe',
    r'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe') if os.path.exists(p)), 'msedge')
PORT = int(os.environ.get('EMU_PORT', '8851'))


def scr_to_png(scr, path):
    """6912-byte ZX screen (bitmap + attrs) -> PNG 256x192 (x2)."""
    from PIL import Image
    pal = [(0, 0, 0), (0, 0, 205), (205, 0, 0), (205, 0, 205), (0, 205, 0), (0, 205, 205), (205, 205, 0), (205, 205, 205)]
    br = [(0, 0, 0), (0, 0, 255), (255, 0, 0), (255, 0, 255), (0, 255, 0), (0, 255, 255), (255, 255, 0), (255, 255, 255)]
    im = Image.new('RGB', (256, 192))
    px = im.load()
    for y in range(192):
        base = ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2)
        for xc in range(32):
            b = scr[base + xc]
            a = scr[6144 + (y >> 3) * 32 + xc]
            ink, paper, bright = a & 7, (a >> 3) & 7, (a >> 6) & 1
            p = br if bright else pal
            for bit in range(8):
                px[xc * 8 + bit, y] = p[ink] if b & (0x80 >> bit) else p[paper]
    im.resize((512, 384), Image.NEAREST).save(path)


def main(argv):
    script = argv[0]
    params = dict(a.split('=', 1) for a in argv[1:])
    for k in ('trd', 'drive2', 'drive3'):   # bare file names (relative to build/); avoids git-bash path mangling of '/media/..'
        if k in params:
            v = params[k].replace(chr(92), '/')
            params[k] = '/ref/' + v[4:] if v.startswith('ref/') else '/media/' + v.split('/media/')[-1].lstrip('/')   # ref/BR_1.TRD -> reference/BR_1.TRD
    budget = int(params.pop('budget', '300000'))
    params['script'] = script
    params.setdefault('name', script)
    out = os.path.join(ROOT, 'build', 'emu')
    os.makedirs(out, exist_ok=True)
    name = params['name']
    res = os.path.join(out, name + '.json')
    if os.path.exists(res):
        os.remove(res)
    srv = subprocess.Popen([sys.executable, os.path.join(ROOT, 'tools', 'emu', 'serve_emu.py'), str(PORT)])
    prof = tempfile.mkdtemp(prefix='zxrun')
    try:
        time.sleep(0.8)
        url = f'http://127.0.0.1:{PORT}/h/harness.html?' + urllib.parse.urlencode(params)
        cmd = [EDGE, '--headless=new', '--disable-gpu', f'--user-data-dir={prof}', '--no-first-run',
               f'--virtual-time-budget={budget}', '--dump-dom', url]
        for attempt in range(4):     # the page sometimes does not come up in time (busy machine): try again
            p = subprocess.run(cmd, capture_output=True, text=True, timeout=1800)
            dom = p.stdout
            if "reading 'ready'" not in dom and 'id="out">starting' not in dom:
                break
            print('harness did not start, retry', attempt + 1)
        i = dom.find('id="out">')
        print(dom[i + 9:i + 700].split('</pre>')[0] if i >= 0 else 'no DOM output: ' + dom[:300] + p.stderr[-200:])
    except subprocess.TimeoutExpired:
        print('TIMEOUT')
    finally:
        srv.terminate()
        shutil.rmtree(prof, ignore_errors=True)
    if not os.path.exists(res):
        print('no result file')
        return 1
    data = json.load(open(res, encoding='utf-8'))
    payload = data.get('data', data)
    for shot, scr in (payload.pop('shots', None) or {}).items():
        png = os.path.join(out, f'{name}_{shot}.png')
        scr_to_png(scr, png)
    for shot, url in (payload.pop('canvas', None) or {}).items():
        png = os.path.join(out, f'{name}_{shot}.png')
        open(png, 'wb').write(base64.b64decode(url.split(',', 1)[1]))
    for line in payload.get('log', []):
        print(line)
    if 'regs' in payload:
        print('final regs:', json.dumps(payload['regs']))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
