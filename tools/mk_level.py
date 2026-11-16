#!/usr/bin/env python3
"""Rebuild work/src_v04/game/level.asm (the level block #8000-#BFFF) from the author's structure (game_orig/level.asm):
lines whose bytes are the same in the v0.04 image stay as they are; the others carry the data of the image:
    IFDEF KUN / <Kunge data> / ELSE / <Human data> / ENDIF
Data of the Kunge map and HER come from the archive files (4_4.MAP, 4_4.HER): the image holds them after the start of the level.
Working state (work/src_v04/kun_live.txt) is not compared.   python tools/mk_level.py"""
import os, re, sys
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'tools'))
import mkv04 as M
import verify_v04

NL = chr(10)
TAB = chr(9)
SRC = M.SRC


def build(variant):
    out = os.path.join(ROOT, 'build', 'v04', 'lv_' + variant)
    tree = os.path.join(SRC, 'game_orig')
    rc, txt = M.sjasm(tree, out, variant)
    pages = {n: open(os.path.join(out, 'page%d.bin' % n), 'rb').read() for n in range(8)}
    ents = M.parse_listing(os.path.join(out, 'main.lst'), pages, tree)
    M.classify(ents, pages)
    return pages, ents


def main():
    adir_h = os.path.join(ROOT, 'work', 'assets_v04', 'hum')
    adir_k = os.path.join(ROOT, 'work', 'assets_v04', 'kun')
    os.makedirs(adir_h, exist_ok=True)
    os.makedirs(adir_k, exist_ok=True)
    ph, eh = build('hum')
    pk, ek = build('kun')
    Vh = open(os.path.join(ROOT, 'work', 'v04', 'br2hum04.2.bin'), 'rb').read()
    Vk = open(os.path.join(ROOT, 'work', 'v04', 'br2kun04.2.bin'), 'rb').read()
    live = verify_v04.live_ranges('kun')
    src = open(os.path.join(SRC, 'game_orig', 'level.asm'), encoding='utf-8').read().split(NL)
    kmap = {(e.file, e.line): e for e in ek}
    out = []
    changed = 0
    labels_of = {}
    cur = ''
    for i, line in enumerate(src, 1):
        eh_ = None
        for e in eh:
            if e.file == 'level.asm' and e.line == i:
                eh_ = e
                break
        ek_ = kmap.get(('level.asm', i))
        if eh_ is None or eh_.n == 0 or eh_.addr < 0x8000 or eh_.addr >= 0xBE50 or eh_.stream != 'M':
            out.append(line)
            continue
        a, n = eh_.addr, eh_.n
        mine_h = ph[2][a - 0x8000:a - 0x8000 + n] if a >= 0x8000 else b''
        ref_h = Vh[a - 0x8000:a - 0x8000 + n]
        mine_k = pk[2][a - 0x8000:a - 0x8000 + n]
        ref_k = Vk[a - 0x8000:a - 0x8000 + n]
        ok_h = mine_h == ref_h
        ok_k = all((2, a + j) in live for j in range(n)) or all(((2, a + j) in live and (mine_k[j] & live[(2, a + j)][1]) == (ref_k[j] & live[(2, a + j)][1])) or mine_k[j] == ref_k[j] for j in range(n))
        if ok_h and ok_k:
            out.append(line)
            continue
        changed += 1
        label = line.split()[0] if line and line[0] not in ' ' + TAB + ';' else ''
        text = line.split(';')[0]
        tag = label or ('L%04X' % a)

        def data_lines(buf, adir, sub, nm):
            if len(buf) > 40:
                fn = '%s.bin' % nm
                open(os.path.join(adir, fn), 'wb').write(buf)
                return [TAB + 'INCBIN' + TAB + '"%s/%s"' % (sub, fn) + TAB + '; %d bytes of the v0.04 image' % len(buf)]
            return [TAB + 'DEFB' + TAB + ','.join('#%02X' % x for x in buf[k:k + 16]) for k in range(0, len(buf), 16)]
        kun_branch = [line] if ok_k else None
        hum_branch = [line] if ok_h else None
        if kun_branch is None:
            if 'INCBIN' in text and 'map/' in text:
                kun_branch = [TAB + 'INCBIN' + TAB + '"map/4_4.map"' + TAB + '; the map of the Kunge level (4_4.MAP)']
            else:
                kun_branch = data_lines(bytes(ref_k), adir_k, 'kun', tag)
        if hum_branch is None:
            hum_branch = data_lines(bytes(ref_h), adir_h, 'hum', tag)
        pre = [label] if label and line.strip() != label else []
        if label and (kun_branch is not [line]):
            pass
        # a label stays in front of the IFDEF
        def strip_label(br):
            return [TAB + b.lstrip() if (b is line and label) else b for b in br]
        if label:
            out.append(label)
        kb = [TAB + line[len(label):].lstrip() if b is line else b for b in kun_branch] if label else kun_branch
        hb = [TAB + line[len(label):].lstrip() if b is line else b for b in hum_branch] if label else hum_branch
        if ok_k and ok_h:
            out += hb
        else:
            out += [TAB + 'IFDEF' + TAB + 'KUN'] + kb + [TAB + 'ELSE'] + hb + [TAB + 'ENDIF']
    # ---- parameters and script of the level (#BE50...): the layout of v0.04 differs from 4~LEVEL.A80, it is rebuilt from the image
    cut = None
    for i, line in enumerate(src):
        if line.startswith(';*********') and i > 70 and src[i + 4].startswith(';'):
            cut = i - 1
            break
    keep_eq = [l for l in src[cut:] if re.match(r'(BULL|mem_tsk)\s+EQU', l)]
    head = out[:out.index(src[cut])] if src[cut] in out else out
    import mkv04_sym as S
    st = S.build('hum')
    L = st['L']
    fnames = {m.group(1) for l in src[cut:] for m in [re.match(r'([A-Za-z_][A-Za-z0-9_]*)', l)] if m and l[0] not in ' ' + TAB + ';'}
    fnames = {n if n in L.pos else n for n in fnames}
    pos = sorted({(L.pos[n][1], n) for n in fnames if n in L.pos and L.pos[n][0] == 'M' and 0xBE50 <= L.pos[n][1] < 0xC000 and n not in ('BULL', 'mem_tsk')})
    byaddr = {}
    for a, n in pos:
        byaddr.setdefault(a, []).append(n)
    end = max(i for i in range(0x3E50, 0x4000) if Vh[i] or Vk[i]) + 1 + 0x8000
    starts = sorted(byaddr)
    if not starts or starts[0] > 0xBE50:
        starts = [0xBE50] + starts
        byaddr.setdefault(0xBE50, [])
    blk = ['', ';------ parameters and script of the level (v0.04 layout: recovered from the image; labels at their v0.04 addresses)']
    for j, a in enumerate(starts):
        b = starts[j + 1] if j + 1 < len(starts) else end
        if b <= a:
            continue
        hb = bytes(Vh[a - 0x8000:b - 0x8000])
        kb = bytes(Vk[a - 0x8000:b - 0x8000])
        kb = bytes(hb[x] if (2, a + x) in live else kb[x] for x in range(len(kb)))
        names = byaddr.get(a, [])
        for nm in names[:-1] if names else []:
            blk.append(nm)
        def dl(buf):
            res = []
            for k in range(0, len(buf), 16):
                res.append(TAB + 'DEFB' + TAB + ','.join('#%02X' % x for x in buf[k:k + 16]))
            return res
        if names:
            blk.append(names[-1])
        else:
            blk.append(TAB + '; (unnamed part at #%04X)' % a)
        if hb == kb:
            blk += dl(hb)
        else:
            blk += [TAB + 'IFDEF' + TAB + 'KUN'] + dl(kb) + [TAB + 'ELSE'] + dl(hb) + [TAB + 'ENDIF']
    out = out[:out.index(src[cut]) if src[cut] in out else len(out)] + keep_eq + blk
    p = os.path.join(SRC, 'game', 'level.asm')
    open(p, 'w', encoding='utf-8', newline=NL).write(NL.join(out))
    print('lines replaced by data of the image:', changed)


if __name__ == '__main__':
    main()
