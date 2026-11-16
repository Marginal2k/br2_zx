#!/usr/bin/env python3
"""Second half of the v0.04 reconstruction (see mkv04.py): generate the source tree of one variant.

    python tools/mkv04_gen.py hum|kun

Writes work/src_v04/<variant>/ (complete tree), work/assets_v04/<variant>/*.bin, assembles it and repairs it (stage 2) until the
pages agree with work/v04/br2<variant>04.N.bin (except the explained DEFR/UNDEF/live-state masks, see verify_v04.py).
"""
import json, os, re, shutil, sys, collections
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'tools'))
import dz, z80snap, a80conv
import mkv04 as M
import v04layout

SRC = M.SRC
BUILD = os.path.join(ROOT, 'build', 'v04')
ASSETS_V = os.path.join(ROOT, 'work', 'assets_v04')
BS = chr(92)


# ------------------------------------------------------------------ names of our labels found anywhere in v0.04
def global_names(side):
    cache = os.path.join(BUILD, f'names_{side}.json')
    if os.path.exists(cache):
        return {((k.split(':')[0] if k.split(':')[0] == 'M' else int(k.split(':')[0])), int(k.split(':')[1])): v
                for k, v in json.load(open(cache)).items()}
    import match_v04
    rows, v, syms, rev = match_v04.compute_rows(side)
    lst = z80snap.symbols(os.path.join(ROOT, 'archive', 'unz', 'BR2_DEMO', 'ASM80', '4.LST'))
    per = {}
    for k, (a, w) in lst.items():
        if w.startswith('Main'):
            pg = 5 if a < 0x8000 else 2
        elif w.startswith('Pg'):
            pg = int(w[-2:], 16)
        else:
            continue
        per.setdefault(pg, []).append((a, a80conv.sj_name(k)))
    names = {}
    for (n, s, e, kind, found, b) in rows:
        if kind not in ('SAME', 'PART') or not found:
            continue
        ln = (e - s) if kind == 'SAME' else b
        pn, vaddr = found
        for a, nm in per.get(n, []):
            if s <= a < s + ln:
                va = vaddr + (a - s)
                key = 'M' if 0x4000 <= va < 0xC000 else pn
                names.setdefault((key, va), nm)
    os.makedirs(BUILD, exist_ok=True)
    json.dump({f'{k[0]}:{k[1]}': v for k, v in names.items()}, open(cache, 'w'))
    return names


# ------------------------------------------------------------------ disassembly of v0.04 bytes
class Ctx:
    def __init__(self, V, names):
        self.V, self.names = V, names

    def memory(self, key):
        mem = [0] * 65536
        mem[0x4000:0x8000] = list(self.V[5])
        mem[0x8000:0xC000] = list(self.V[2])
        if key != 'M':
            mem[0xC000:] = list(self.V[key])
        return mem

    def name(self, key, addr, local):
        if addr in local:
            return local[addr]
        return self.names.get(('M' if 0x4000 <= addr < 0xC000 else key, addr))


def fmt_ins(ins, ctx, key, local):
    op = ins.operation
    b = bytes(ins.bytes)
    parts = op.split(None, 1)
    mn = parts[0].upper()
    args = parts[1] if len(parts) > 1 else ''
    if mn in ('JR', 'DJNZ', 'JP', 'CALL'):
        m = re.search(r'\$([0-9a-f]{4})$', args)
        if m:
            tgt = int(m.group(1), 16)
            nm = ctx.name(key, tgt, local)
            return '%s\t%s' % (mn, args[:m.start()].upper() + (nm if nm else '#%04X' % tgt))
    if mn == 'LD' and len(b) in (3, 4) and not (b[0] in (0xDD, 0xFD) and len(b) == 3) and not (b[0] == 0xED and len(b) == 3):
        m = re.search(r'\$([0-9a-f]{4})', args)
        if m:
            val = int(m.group(1), 16)
            nm = ctx.name(key, val, local) if val >= 0x4000 else None
            if nm:
                s = args[:m.start()].upper() + nm + args[m.end():].upper()
                return 'LD\t' + re.sub(r'\$([0-9A-F]+)', lambda mm: '#' + mm.group(1), s)
    s = re.sub(r'\$([0-9A-F]+)', lambda mm: '#' + mm.group(1), args.upper())
    return mn + ('\t' + s if s else '')


def disasm_items(ctx, key, base, data, local):
    mem = ctx.memory(key)
    end = base + len(data)
    mem[base:end] = list(data)
    out = []
    a = base
    while a < end:
        z = a
        while z < end and mem[z] == 0:
            z += 1
        if z - a >= 16:
            out.append((a, z - a, 'DEFS	%d' % (z - a)))
            a = z
            continue
        # next long zero run (or the end) bounds one linear decode
        stop = a
        while stop < end:
            if mem[stop] == 0:
                z = stop
                while z < end and mem[z] == 0:
                    z += 1
                if z - stop >= 16:
                    break
                stop = z
            else:
                stop += 1
        try:
            ins = dz.dis(mem, a, stop)
        except Exception:
            ins = []
        pos = a
        for i in ins:
            if i.address != pos:
                break
            if pos + len(i.bytes) > stop or i.operation.lower().startswith(('defb', 'defw', 'defm', 'defs')):
                out.append((pos, 1, 'DEFB	#%02X' % mem[pos]))
                pos += 1
                # resynchronise: decode again from here
                break
            out.append((pos, len(i.bytes), fmt_ins(i, ctx, key, local)))
            pos += len(i.bytes)
        else:
            pass
        if pos == a:
            out.append((a, 1, 'DEFB	#%02X' % mem[a]))
            pos = a + 1
        a = pos
    return out


def gen_code(ctx, key, base, data, defs):
    """list of text lines for a code piece; defs = {addr: name} labels (emitted names recorded by caller)"""
    items = disasm_items(ctx, key, base, data, {})
    starts = {a for a, n, s in items}
    local = {}
    for a, n, s in items:
        if s.split('\t')[0] in ('JR', 'DJNZ', 'JP', 'CALL'):
            m = re.search(r'#([0-9A-F]{4})$', s)
            if m:
                v = int(m.group(1), 16)
                if base <= v < base + len(data) and v in starts and not ctx.name(key, v, {}):
                    local[v] = ('v4_%04X' % v) if key == 'M' else ('v4p%s_%04X' % (key, v))
    items = disasm_items(ctx, key, base, data, local)
    lines = []
    for a, n, s in items:
        nm = ctx.names.get(('M' if 0x4000 <= a < 0xC000 else key, a))
        if nm and nm in defs.get('allowed', ()):
            lines.append(nm)
            defs['emitted'].add(nm)
        if a in local:
            lines.append(local[a])
        lines.append('\t' + s)
    return lines


def gen_thread(ctx, key, base, data, defs):
    """words of CALL_/EXEX_ tables: DEFW target-$-2"""
    lines = []
    for i in range(0, len(data) - 1, 2):
        a = base + i
        w = data[i] | data[i + 1] << 8
        if w == 0:
            lines.append('\tEXEX_')
        else:
            t = (a + 2 + w) & 0xFFFF
            nm = ctx.name(key, t, {})
            lines.append('\tCALL_\t' + (nm if nm else '#%04X' % t))
    if len(data) % 2:
        lines.append('\tDEFB\t#%02X' % data[-1])
    return lines


ASSET_FILES = None
LITERAL = True
FIXED = set()


def asset_table():
    global ASSET_FILES
    if ASSET_FILES is None:
        a = v04layout.load_assets()
        ASSET_FILES = {k: d for k, d in a.items() if k.startswith(('DATA/', 'MUSIC/SONG1C'))}
    return ASSET_FILES


def asset_labels(treedir):
    """asset path (as written in INCBIN) -> label placed in front of it in main.asm"""
    res = {}
    lines = open(os.path.join(treedir, 'main.asm'), encoding='utf-8').read().split('\n')
    last = None
    for l in lines:
        if l and l[0] not in ' \t;':
            tok = l.split()
            if len(tok) == 1 or (len(tok) > 1 and tok[1].startswith(';')):
                last = tok[0]
            else:
                last = None
        m = re.match(r'\s+INCBIN\s+"([^"]+)"', l)
        if m and last:
            k_ = m.group(1).lower()
            res[k_] = None if k_ in res else last          # the same file twice (~SHADOW: offset 0 and 192): ambiguous
            last = None
    return res


def find_segments(data, aset):
    marks = []
    for nm, d in sorted(aset.items(), key=lambda t: -len(t[1])):
        if len(d) < 64:
            continue
        k = data.find(d)
        exact = k >= 0
        if not exact:
            k = data.find(d[:48])
        if k < 0:
            continue
        end = k + len(d) if exact else None
        if any(not (k >= (b or a + 1) or (end or k + 1) <= a) for a, b, *_ in marks):
            continue
        marks.append((k, end, nm, exact))
    marks.sort()
    segs = []
    last = 0
    for i, (a, b, nm, exact) in enumerate(marks):
        if b is None:
            nxt = marks[i + 1][0] if i + 1 < len(marks) else len(data)
            b = min(nxt, a + len(aset[nm]))
        if a > last:
            segs.append((last, a, None, False))
        segs.append((a, b, nm, exact))
        last = b
    if last < len(data):
        segs.append((last, len(data), None, False))
    return segs


def gen_data_seg(base, data, a, b, nm, exact, variant, tag, alabels, defs):
    lines = []
    adir = os.path.join(ASSETS_V, variant)
    os.makedirs(adir, exist_ok=True)
    rel = ('data/hero/' + os.path.basename(nm).lower()) if nm and '/HERO/' in nm else ('data/' + os.path.basename(nm).lower() if nm else None)
    lab = alabels.get(rel) if rel else None
    if lab and lab in defs['allowed'] and lab not in defs['emitted']:
        lines.append(lab)
        defs['emitted'].add(lab)
    if nm and exact:
        lines.append('	INCBIN	"%s"	; v0.04: byte-identical to the archive file' % rel)
        return lines
    chunk = data[a:b]
    if len(chunk) > 40:
        fn = '%s_%04X.bin' % (tag, base + a)
        open(os.path.join(adir, fn), 'wb').write(chunk)
        why = 'v0.04 version of %s (the archive file is older)' % os.path.basename(nm) if nm else 'taken from the v0.04 image'
        lines.append('	INCBIN	"%s/%s"	; %d bytes at #%04X: %s' % (variant, fn, len(chunk), base + a, why))
    else:
        for i in range(0, len(chunk), 16):
            lines.append('	DEFB	' + ','.join('#%02X' % x for x in chunk[i:i + 16]))
    return lines


def gen_region(ctx, key, base, data, kinds, variant, tag, aset, alabels, defs, force_data=False):
    """-> (lines, stats)"""
    st = collections.Counter()
    lines = []
    segs = find_segments(data, aset) if len(data) >= 64 else [(0, len(data), None, False)]
    for a, b, nm, exact in segs:
        piece = data[a:b]
        if nm or force_data:
            lines += gen_data_seg(base, data, a, b, nm, exact, variant, tag, alabels, defs)
            st['data'] += b - a
            continue
        mode = 'code'
        if kinds['thread'] and kinds['thread'] >= kinds['code']:
            mode = 'thread'
        elif kinds['data'] > kinds['code'] or (kinds['code'] == 0 and (kinds['data'] or kinds['wild'])):
            mode = 'data'
        if mode == 'code' and len(piece) >= 48:
            items = disasm_items(ctx, key, base + a, piece, {})
            bad = sum(1 for x in items if x[2].startswith('DEFB'))
            if bad * 6 > len(items):
                mode = 'data'
        if mode == 'code':
            lines += gen_code(ctx, key, base + a, piece, defs)
        elif mode == 'thread':
            lines += gen_thread(ctx, key, base + a, piece, defs)
        else:
            lines += gen_data_seg(base, data, a, b, None, False, variant, tag, alabels, defs)
        st[mode] += len(piece)
    return lines, st


def split_jumps(es, emit, reg, vbase):
    """a replaced region must not contain an ORG jump of our sources (the generated block would run over it)"""
    out = []
    for r in reg:
        if r[0] != 'rep' or r[2] - r[1] < 2:
            out.append(r)
            continue
        k0, k1, p0, p1 = r[1:5]
        cuts = []
        for j in range(k0 + 1, k1):
            a, b = es[emit[j - 1]], es[emit[j]]
            if b.addr != a.addr + a.n:
                cuts.append((j, b.addr - vbase))
        ok = bool(cuts) and all(p0 <= c[1] <= p1 for c in cuts) and all(cuts[i][1] <= cuts[i + 1][1] for i in range(len(cuts) - 1))
        if not ok:
            out.append(r)
            continue
        ks = [k0] + [c[0] for c in cuts] + [k1]
        ps = [p0] + [c[1] for c in cuts] + [p1]
        for i in range(len(ks) - 1):
            out.append(('rep', ks[i], ks[i + 1], ps[i], ps[i + 1]))
    return out


# ------------------------------------------------------------------ plan -> edited tree
def build_tree(variant):
    orig = os.path.join(SRC, 'game_orig')
    out = os.path.join(BUILD, variant + '_orig')
    rc, txt = M.sjasm(orig, out, variant)
    if rc:
        sys.exit('assembly of the original failed:\n' + txt)
    pages = {n: open(os.path.join(out, f'page{n}.bin'), 'rb').read() for n in range(8)}
    ents = M.parse_listing(os.path.join(out, 'main.lst'), pages, orig)
    M.classify(ents, pages)
    V = {n: open(os.path.join(ROOT, 'work', 'v04', f'br2{variant}04.{n}.bin'), 'rb').read() for n in range(8)}
    names = dict(global_names(variant))
    ctx = Ctx(V, names)
    alabels = asset_labels(orig)
    aset = asset_table()
    # names from kept entries are added while walking (labels of kept lines)
    plans = []
    for stream in ('M', 0, 1, 3, 4, 6, 7):
        es = [e for e in ents if e.stream == stream]
        if not es:
            continue
        v = (V[5] + V[2]) if stream == 'M' else V[stream]
        vbase = 0x4000 if stream == 'M' else 0xC000
        emit, reg = M.align(es, v, vbase)
        reg = M.refine(es, emit, v, vbase, reg)
        if stream in (3, 4):
            reg = [('rep', 0, len(emit), 0, len(v))]
        else:
            reg = split_jumps(es, emit, reg, vbase)
        plans.append((stream, es, emit, reg, v, vbase))
        for r in reg:
            if r[0] == 'keep':
                p = r[3]
                for ei in range(r[1], r[2]):
                    e = es[emit[ei]]
                    if e.label:
                        names.setdefault((stream if stream != 'M' else 'M', vbase + p), a80conv.sj_name(e.label))
                    p += e.n
    # labels defined in kept lines
    kept_labels = set()
    deleted_lines = collections.defaultdict(set)
    inserts = collections.defaultdict(lambda: collections.defaultdict(list))
    tails = collections.defaultdict(list)
    asserts = collections.defaultdict(lambda: collections.defaultdict(list))
    allowed = {nm for nm in names.values()}
    blocks = []
    stats = {'keep': 0, 'rep_code': 0, 'rep_data': 0, 'rep_thread': 0}
    for stream, es, emit, reg, v, vbase in plans:
        for r in reg:
            if r[0] == 'keep':
                for ei in range(r[1], r[2]):
                    e = es[emit[ei]]
                    stats['keep'] += e.n
                    if e.label:
                        kept_labels.add(a80conv.sj_name(e.label))
        pass
    for stream, es, emit, reg, v, vbase in plans:
        if stream in (3, 4):
            continue
        for r in reg:
            if r[0] == 'keep' and r[2] > r[1]:
                e0 = es[emit[r[1]]]
                if True:
                    asserts[e0.file][e0.line].append('	CHK_	#%04X	; keep-run check' % (vbase + r[3]))
    allowed |= {a80conv.sj_name(x) for x in alabels.values()}
    defs = {'allowed': allowed - kept_labels, 'emitted': set()}
    for stream, es, emit, reg, v, vbase in plans:
        for r in reg:
            if r[0] != 'rep':
                continue
            k0, k1, p0, p1 = r[1:5]
            gap = len(r) > 5
            data = bytes(v[p0:p1])
            dent = [es[emit[i]] for i in range(k0, k1)]
            base = vbase + p0
            kinds = collections.Counter()
            for e in dent:
                kinds[e.kind] += e.n
            if not dent and not data:
                continue
            if k1 > k0:
                anchor = dent[0]
            elif k0 < len(emit):
                anchor = es[emit[k0]]
            else:
                anchor = es[emit[-1]]
            hdr = '; ---- v0.04: %s (was %d bytes in the 4.Z80 sources%s)' % (
                'new/changed' if data else 'removed', sum(e.n for e in dent), ', %d..%d' % (dent[0].line, dent[-1].line) if dent else '')
            tag = '%s_%s' % (str(stream), 'r%d' % k0)
            stream_key = stream
            if not data:
                lines = [hdr]
            else:
                body, st = gen_region(ctx, stream_key, base, data, kinds, variant, tag, aset, alabels, defs, force_data=(stream in (3, 4) or gap))
                for k_, n_ in st.items():
                    stats['rep_' + k_] += n_
                if gap:
                    lines = [hdr, '	ORG	#%04X' % base] + body + ['	ORG	#%04X' % (base + len(data))]
                else:
                    lines = [hdr, '	CHK_	#%04X	; v0.04 address check' % base] + body + ['	CHK_	#%04X' % (base + len(data))]
            if anchor is not None:
                if k1 > k0:
                    for e in dent:
                        deleted_lines[e.file].add(e.line)
                    inserts[anchor.file][anchor.line].append('\n'.join(lines))
                elif k0 < len(emit):
                    inserts[anchor.file][anchor.line].append('\n'.join(lines))
                else:
                    tails[anchor.file].append('\n'.join(lines))
    # ---- write the tree
    tree = os.path.join(SRC, variant)
    shutil.rmtree(tree, ignore_errors=True)
    shutil.copytree(orig, tree)
    E = defs['emitted']
    for fn in os.listdir(tree):
        if not fn.endswith('.asm') or fn == 'top.asm':
            continue
        L = open(os.path.join(tree, fn), encoding='utf-8').read().split('\n')
        out_l = []
        for i, line in enumerate(L, 1):
            if i in inserts.get(fn, {}):
                out_l += inserts[fn][i]
            if i in asserts.get(fn, {}):
                out_l += asserts[fn][i]
            if i in deleted_lines.get(fn, ()):
                lab = re.match(r'([A-Za-z_][A-Za-z0-9_]*)', line) if line and line[0] not in ' \t;' else None
                if lab and a80conv.sj_name(lab.group(1)) not in E:
                    out_l.append(lab.group(1) + '\t; (v0.04: code removed/moved; label kept for references)')
                continue
            m = re.match(r'([A-Za-z_][A-Za-z0-9_]*)\s*(;.*)?$', line)
            if m and a80conv.sj_name(m.group(1)) in E:
                continue                              # label re-emitted at its v0.04 position inside generated code
            out_l.append(line)
        out_l += tails.get(fn, [])
        open(os.path.join(tree, fn), 'w', encoding='utf-8', newline='\n').write('\n'.join(out_l))
    return tree, stats


# ------------------------------------------------------------------ stage 2
def fmt_fix(variant, ctx, key, addr, n, V):
    mem = ctx.memory(key)
    data = V
    return None


def stage2(variant, tree, ctx, V, maxit=8):
    out = os.path.join(BUILD, variant)
    for it in range(maxit):
        for n_ in range(8):
            try:
                os.remove(os.path.join(out, f'page{n_}.bin'))
            except OSError:
                pass
        rc, txt = M.sjasm(tree, out, variant)
        errs = [l for l in txt.split(chr(10)) if 'error' in l]
        if rc:
            print('assembly reported', len(errs), 'errors (first):', errs[:4])
            if not os.path.exists(os.path.join(out, 'page0.bin')) or any('Label not found' in l or 'Duplicate' in l or 'opening file' in l for l in errs):
                return False
        pages = {n: open(os.path.join(out, f'page{n}.bin'), 'rb').read() for n in range(8)}
        ents = M.parse_listing(os.path.join(out, 'main.lst'), pages, tree)
        M.classify(ents, pages)
        wild = set()
        bad = []
        for e in ents:
            if e.n == 0:
                continue
            key = e.stream
            ours = (pages[5] + pages[2])[e.addr - 0x4000:e.addr - 0x4000 + e.n] if key == 'M' else pages[key][e.addr - 0xC000:e.addr - 0xC000 + e.n]
            theirs = (V[5] + V[2])[e.addr - 0x4000:e.addr - 0x4000 + e.n] if key == 'M' else V[key][e.addr - 0xC000:e.addr - 0xC000 + e.n]
            if e.kind == 'wild' or ours == theirs:
                continue
            bad.append((e, theirs))
        print('stage 2 iteration', it, ':', len(bad), 'entries differ')
        if not bad:
            return True
        fixes = collections.defaultdict(dict)
        skipped = []
        for e, theirs in bad:
            fixes[e.file][e.line] = (e, theirs)
        syms = {}
        for l in open(os.path.join(out, 'main.sym')):
            m = re.match(r'(\S+):\s*EQU 0x([0-9A-F]+)', l)
            if m:
                syms.setdefault(int(m.group(2), 16), m.group(1))
        for fn, fx in fixes.items():
            p = os.path.join(tree, fn)
            L = open(p, encoding='utf-8').read().split('\n')
            for ln, (e, theirs) in fx.items():
                line = L[ln - 1]
                label = ''
                if line and line[0] not in ' \t;':
                    t = line.split()[0]
                    label = t
                com = ' ; v0.04 (was: %s)' % ' '.join(e.text.split(';')[0].split())
                key = e.stream
                mem = ctx.memory(key)
                again = (fn, ln) in FIXED
                FIXED.add((fn, ln))
                if e.kind == 'code' and e.n <= 4 and not again:
                    mem[e.addr:e.addr + e.n] = list(theirs)
                    ins = dz.dis(mem, e.addr, e.addr + 1)[0]
                    if len(ins.bytes) == e.n and not ins.operation.lower().startswith('def') and not (theirs[0] == 0xED and len(theirs) > 1 and theirs[1] in (0x63, 0x6B)):
                        nm_ctx = Ctx(V, {} if LITERAL else {k: v for k, v in ((('M' if 0x4000 <= a < 0xC000 else key, a), n) for a, n in syms.items())})
                        txt = fmt_ins(ins, nm_ctx, key, {})
                        L[ln - 1] = (label + ('\t' if label else '\t')) + txt + com
                        continue
                if (e.kind == 'code' and e.n > 4) or (e.kind == 'thread' and e.n != 2):
                    skipped.append((e.file, e.line, e.addr, e.n, e.text.strip()[:30]))
                    continue
                if e.n > 40:
                    adir = os.path.join(ASSETS_V, variant)
                    os.makedirs(adir, exist_ok=True)
                    fn2 = 'fix_%s_%04X.bin' % (key, e.addr)
                    open(os.path.join(adir, fn2), 'wb').write(theirs)
                    L[ln - 1] = (label + '\t' if label else '\t') + 'INCBIN\t"%s/%s"' % (variant, fn2) + com
                else:
                    L[ln - 1] = (label + '\t' if label else '\t') + 'DEFB\t' + ','.join('#%02X' % x for x in theirs) + com
            open(p, 'w', encoding='utf-8', newline='\n').write('\n'.join(L))
    return False


def main():
    variant = sys.argv[1]
    tree, stats = build_tree(variant)
    print('generated tree', tree, stats)
    V = {n: open(os.path.join(ROOT, 'work', 'v04', f'br2{variant}04.{n}.bin'), 'rb').read() for n in range(8)}
    ctx = Ctx(V, global_names(variant))
    ok = stage2(variant, tree, ctx, V)
    print('result:', 'pages equal (up to wildcards)' if ok else 'NOT converged')


if __name__ == '__main__':
    main()
