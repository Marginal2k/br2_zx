#!/usr/bin/env python3
"""Generation half of the symbolic v0.04 reconstruction.   python tools/mkv04_symgen.py hum|kun [--final]
See mkv04_sym.py (alignment, label recovery).  Writes work/src_v04/<variant>/, assembles it, repairs it symbolically.
--final removes the working marks (CHK_ address checks and '; v0.04 (was: ...)' comments)."""
import collections, os, re, shutil, sys
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'tools'))
import dz, a80conv
import mkv04 as M
import mkv04_gen as G
import mkv04_sym as S

SRC = M.SRC
BUILD = os.path.join(ROOT, 'build', 'v04')
ASSETS_V = os.path.join(ROOT, 'work', 'assets_v04')
FORCE_CODE = [(4, 0xFD00, 0xFFB0)]            # SOUNDgs, setGSvar, loadGS, setGS (the GS interface of 4_SOUND2): code between data tables
PRIO = {'kept': 0, 'inferred': 1, 'asset': 2, 'chunk': 3, 'v4': 4}
SCREEN_HI = 0x5AFF
NL = chr(10)
TAB = chr(9)
BS = chr(92)


def sjn(n):
    return a80conv.sj_name(n)


class Namer:
    def __init__(self, L):
        self.L = L

    def exact(self, key, addr):
        names = self.L.by_key[key].get(addr)
        if names:
            return sorted(names, key=lambda n: (PRIO[self.L.src[n]], len(n)))[0]
        return None

    def lookup(self, page, addr, mode):
        """label text for an absolute v0.04 address, or None (stay numeric)"""
        if addr < 0x4000:
            return None
        pg = 0 if page == 'M' else page
        keys = ['M'] if addr < 0xC000 else [pg] + [k for k in (0, 6, 7, 1, 3, 4) if k != pg]
        for key in keys:
            nm = self.exact(key, addr)
            if nm:
                return nm
        if mode == 'imm' and addr <= SCREEN_HI:
            return None
        best = None
        lo = 0x8000 if 0x8000 <= addr < 0xC000 else 0           # level data (ORG #8000) is a block of its own
        for a, names in self.L.lst(keys[0]):
            if a > addr:
                break
            if a >= lo:
                best = (a, names)
        if lo == 0x8000 and (not best or addr - best[0] > 0x180):
            for nm_, base_ in (('BUF512', 0xB800), ('DSCR', 0xA000), ('MAP2', 0x9000), ('MAP', 0x8000)):
                if addr >= base_:
                    return nm_ if addr == base_ else '%s+%d' % (nm_, addr - base_)
        if best and addr - best[0] <= 0x180:
            nm = sorted(best[1], key=lambda n: (PRIO[self.L.src[n]], len(n)))[0]
            return '%s+%d' % (nm, addr - best[0])
        return None


def fmt_ins(ins, namer, page):
    op = ins.operation
    parts = op.split(None, 1)
    mn = parts[0].upper()
    args = parts[1] if len(parts) > 1 else ''

    def sub(m, mode):
        a = int(m.group(1), 16)
        nm = namer.lookup(page, a, mode)
        return nm if nm else '#%04X' % a
    if mn in ('JP', 'CALL', 'JR', 'DJNZ'):
        args = re.sub(r'\$([0-9a-f]{4})$', lambda m: sub(m, 'mem'), args)
    elif mn == 'LD':
        args = re.sub(r'\(\$([0-9a-f]{4})\)', lambda m: '(' + sub(m, 'mem') + ')', args)
        args = re.sub(r'(?<![\w(])\$([0-9a-f]{4})(?!\))', lambda m: sub(m, 'imm'), args)
    args = re.sub(r'\$([0-9a-fA-F]+)', lambda mm: '#' + mm.group(1).upper(), args)
    # upper case registers/conditions, keep our label names untouched
    def up(m):
        w = m.group(0)
        return w.upper() if w.upper() in ('A', 'B', 'C', 'D', 'E', 'H', 'L', 'I', 'R', 'AF', 'BC', 'DE', 'HL', 'SP', 'IX', 'IY', 'NZ', 'Z', 'NC', 'PO', 'PE', 'P', 'M', 'IXH', 'IXL', 'IYH', 'IYL') else w
    args = re.sub(r"[A-Za-z_][A-Za-z0-9_]*'?", lambda m: up(m) if m.group(0).lower() == m.group(0) and len(m.group(0)) <= 3 else m.group(0), args)
    return mn + (TAB + args if args else '')


def decode(ctx, key, base, data, cuts, exe=None):
    """-> [(addr, n, ins | None | 'ZERO')]; decoding restarts at every address of cuts"""
    mem = ctx.memory(key)
    end = base + len(data)
    mem[base:end] = list(data)
    out = []
    bounds = sorted({c for c in cuts if base < c < end} | {end})
    a = base
    for stop in bounds:
        while a < stop:
            z = a
            while z < stop and mem[z] == 0:
                z += 1
            if z - a >= 16:
                out.append((a, z - a, 'ZERO'))
                a = z
                continue
            try:
                lst = dz.dis(mem, a, min(stop, a + 1))
                ins = lst[0] if lst else None
            except Exception:
                ins = None
            if ins is None or a + len(ins.bytes) > stop or ins.operation.lower().startswith(('defb', 'defw', 'defm', 'defs')):
                out.append((a, 1, None))
                a += 1
            else:
                out.append((a, len(ins.bytes), ins))
                a += len(ins.bytes)
                if exe is not None and ins.operation.lower() == 'call $%04x' % exe:
                    while a + 2 <= stop:                              # threaded code: words of CALL_ x until EXEX_ (0)
                        w = mem[a] | mem[a + 1] << 8
                        out.append((a, 2, ('T', w)))
                        a += 2
                        if w == 0:
                            break
    return out


def gen_code(st, namer, key, base, data, label_at, newl):
    items = decode(st['ctx'], key, base, data, set(label_at), st['exe'])
    starts = {a for a, n, i in items}
    for a, n, i in items:
        if i not in (None, 'ZERO') and not isinstance(i, tuple) and i.operation.split()[0].lower() in ('jr', 'djnz', 'jp', 'call'):
            m = re.search(r'\$([0-9a-f]{4})$', i.operation)
            if m:
                t = int(m.group(1), 16)
                if base <= t < base + len(data) and t in starts and t not in label_at and t not in newl:
                    newl[t] = None
    lines = []
    for a, n, i in items:
        names = list(label_at.get(a, []))
        if a in newl and newl[a] is None:
            prev = None
            for ad, nm in namer.L.lst(key):
                if ad > a:
                    break
                good = [x for x in nm if namer.L.src[x] != 'v4']
                if good:
                    prev = good[0]
            cnt = st['v4cnt'][prev]
            st['v4cnt'][prev] += 1
            nm = 'v4_%s_%d' % (prev if prev else key, cnt + 1)
            newl[a] = nm
            namer.L.add(nm, key, a, 'v4')
        if newl.get(a):
            names.append(newl[a])
        lines += names
        if isinstance(i, tuple):
            w = i[1]
            if w == 0:
                lines.append(TAB + 'EXEX_')
            else:
                t = (a + 2 + w) & 0xFFFF
                nm = namer.lookup(key, t, 'mem')
                lines.append(TAB + 'CALL_' + TAB + (nm if nm else '#%04X' % t))
        elif i == 'ZERO':
            lines.append(TAB + 'DEFS' + TAB + str(n))
        elif i is None:
            lines.append(TAB + 'DEFB' + TAB + '#%02X' % data[a - base])
        else:
            lines.append(TAB + fmt_ins(i, namer, key))
    return lines


def gen_thread(st, namer, key, base, data, label_at):
    lines = []
    for i in range(0, len(data) - 1, 2):
        a = base + i
        lines += label_at.get(a, [])
        w = data[i] | data[i + 1] << 8
        if w == 0:
            lines.append(TAB + 'EXEX_')
        else:
            t = (a + 2 + w) & 0xFFFF
            nm = namer.lookup(key, t, 'mem')
            lines.append(TAB + 'CALL_' + TAB + (nm if nm else '#%04X' % t))
    if len(data) % 2:
        lines.append(TAB + 'DEFB' + TAB + '#%02X' % data[-1])
    return lines


def gen_data(st, key, base, data, label_at, tag):
    variant = st['variant']
    adir = os.path.join(ASSETS_V, variant)
    os.makedirs(adir, exist_ok=True)
    lines = []
    cuts = sorted(a for a in label_at if base < a < base + len(data))
    pieces = []
    last = 0
    for c in cuts:
        pieces.append((last, c - base))
        last = c - base
    pieces.append((last, len(data)))
    for a, b in pieces:
        if b <= a:
            continue
        lines += label_at.get(base + a, [])
        chunk = data[a:b]
        if not any(chunk) and len(chunk) >= 8:
            lines.append(TAB + 'DEFS' + TAB + str(len(chunk)))
        elif len(chunk) > 48:
            nm = (label_at.get(base + a) or [None])[0]
            fn = '%s.bin' % (nm if nm else '%s_%04X' % (tag, base + a))
            open(os.path.join(adir, fn), 'wb').write(chunk)
            lines.append(TAB + 'INCBIN' + TAB + '"%s/%s"' % (variant, fn) + TAB + '; %d bytes of the v0.04 image (no archive file for them)' % len(chunk))
        else:
            for i in range(0, len(chunk), 16):
                lines.append(TAB + 'DEFB' + TAB + ','.join('#%02X' % x for x in chunk[i:i + 16]))
    return lines


def asset_rel(nm):
    return ('data/hero/' if '/HERO/' in nm else 'data/') + os.path.basename(nm).lower()


def region_lines(st, namer, stream, base, data, kinds, tag, label_at, newl, force_data):
    stats = collections.Counter()
    lines = []
    segs = G.find_segments(data, st['aset']) if len(data) >= 64 else [(0, len(data), None, False)]
    for a, b, nm, exact in segs:
        piece = data[a:b]
        la = {k: v for k, v in label_at.items() if base + a <= k < base + b}
        if nm and exact:
            rel = asset_rel(nm)
            lab = st['alabels'].get(rel)
            if lab and lab not in la.get(base + a, []) and lab not in st['L'].pos:
                st['L'].add(lab, stream, base + a, 'asset')
                la.setdefault(base + a, []).append(lab)
            lines += la.get(base + a, [])
            lines.append(TAB + 'INCBIN' + TAB + '"%s"' % rel + TAB + '; byte-identical to the archive file')
            stats['data'] += b - a
            continue
        mode = 'code'
        forced = any(stream == pg_ and a0_ <= base + a < a1_ for pg_, a0_, a1_ in FORCE_CODE)
        if force_data or nm:
            mode = 'data'
        elif kinds['thread'] and kinds['thread'] >= kinds['code']:
            mode = 'thread'
        elif kinds['data'] > kinds['code'] or (kinds['code'] == 0 and (kinds['data'] or kinds['wild'])):
            mode = 'data'
        if forced:
            mode = 'code'
        if mode == 'code' and len(piece) >= 24 and not forced:
            ck = (stream, base + a, len(piece))
            if ck not in st.setdefault('modecache', {}):
                items = decode(st['ctx'], stream, base + a, piece, set(la), st['exe'])
                bad = sum(1 for x in items if x[2] is None)
                calls = exact = odd = 0
                for ad, n, i in items:
                    if i in (None, 'ZERO') or isinstance(i, tuple):
                        continue
                    o = i.operation.lower()
                    mn = o.split()[0]
                    if mn in ('call', 'jp') and '($' not in o and 'hl' not in o and 'ix' not in o and 'iy' not in o:
                        m = re.search(r'\$([0-9a-f]{4})$', o)
                        if m:
                            t = int(m.group(1), 16)
                            calls += 1
                            if t < 0x4000 or namer.exact(0 if t >= 0xC000 and stream == 'M' else ('M' if t < 0xC000 else stream), t) or any(namer.exact(k, t) for k in (0, 6, 7, 1, 3, 4)) or base + a <= t < base + a + len(piece):
                                exact += 1
                    if mn in ('daa', 'ccf', 'scf', 'rst', 'halt', 'exx') or (mn in ('ret', 'jp', 'call') and re.match(r'(m|p|po|pe),', o.split(None, 1)[1] if len(o.split()) > 1 else '')):
                        odd += 1
                good = len(items) and bad * 6 <= len(items) and odd * 10 <= len(items) and (calls < 3 or exact * 2 >= calls)
                st['modecache'][ck] = 'code' if good else 'data'
            mode = st['modecache'][ck]
        if mode == 'code':
            lines += gen_code(st, namer, stream, base + a, piece, la, newl)
        elif mode == 'thread':
            lines += gen_thread(st, namer, stream, base + a, piece, la)
        else:
            lines += gen_data(st, stream, base + a, piece, la, tag)
        stats[mode] += len(piece)
    return lines, stats


def describe(dent):
    """what the replaced 4.Z80 code was: the author's first labels / comments"""
    labs = []
    for e in dent:
        if e.label:
            labs.append(e.label)
        c = e.text.split(';', 1)
        if len(c) > 1 and re.search('[A-Za-z]{4}|[' + chr(0x400) + '-' + chr(0x4FF) + ']{4}', c[1]) and len(c[1]) < 60:
            labs.append('(' + c[1].strip() + ')')
        if len(labs) >= 3:
            break
    return ' '.join(labs)


def generate(st, final=False):
    variant = st['variant']
    L, plans = st['L'], st['plans']
    st['v4cnt'] = collections.Counter()
    namer = Namer(L)
    exe_l = L.pos.get('EXE')
    st['exe'] = exe_l[1] if exe_l else None
    kept_labels = {n for n, h in L.src.items() if h == 'kept'}
    deleted = collections.defaultdict(set)
    inserts = collections.defaultdict(lambda: collections.defaultdict(list))
    tails = collections.defaultdict(list)
    asserts = collections.defaultdict(lambda: collections.defaultdict(list))
    stats = collections.Counter()
    regions = []
    for stream, es, emit, reg, v, vbase in plans:           # asset labels first, so that code can refer to them
        for r in reg:
            if r[0] != 'rep':
                continue
            data = bytes(v[r[3]:r[4]])
            if len(data) >= 64:
                for a, b, nm, exact in G.find_segments(data, st['aset']):
                    if nm and exact:
                        lab = st['alabels'].get(asset_rel(nm))
                        if lab and lab not in L.pos:
                            L.add(lab, stream, vbase + r[3] + a, 'asset')
    for stream, es, emit, reg, v, vbase in plans:
        for r in reg:
            if r[0] == 'keep' and r[2] > r[1] and stream not in (3, 4) and not final:
                e0 = es[emit[r[1]]]
                asserts[e0.file][e0.line].append(TAB + 'CHK_' + TAB + '#%04X' % (vbase + r[3]))
            if r[0] != 'rep':
                continue
            k0, k1, p0, p1 = r[1:5]
            gap = len(r) > 5
            data = bytes(v[p0:p1])
            dent = [es[emit[i]] for i in range(k0, k1)]
            base = vbase + p0
            if st.get('ifdef') and dent and sum(e.n for e in dent) == len(data):
                # working state of the snapshot is not put into the source: at live positions the Human bytes of the base build stay
                import verify_v04
                live = verify_v04.live_ranges('kun')
                ours = b''.join(bytes((st['pages'][5] + st['pages'][2] if stream == 'M' else st['pages'][stream])[e.addr - (0x4000 if stream == 'M' else 0xC000):e.addr - (0x4000 if stream == 'M' else 0xC000) + e.n]) for e in dent)
                dd = bytearray(data)
                for i_ in range(len(dd)):
                    x_ = base + i_
                    pgx = (5 if x_ < 0x8000 else 2) if stream == 'M' else stream
                    lv = live.get((pgx, x_))
                    if lv is not None:
                        dd[i_] = ours[i_] if lv[1] == 0 else (ours[i_] & ~lv[1] & 0xFF) | (dd[i_] & lv[1])
                data = bytes(dd)
                if data == ours:
                    continue
            if not dent and not data:
                continue
            kinds = collections.Counter()
            for e in dent:
                kinds[e.kind] += e.n
            anchor = dent[0] if dent else (es[emit[k0]] if k0 < len(emit) else es[emit[-1]])
            label_at = {}
            for ad in range(base, base + len(data)):
                for nm in L.by_key[stream].get(ad, ()):
                    if nm not in kept_labels:
                        label_at.setdefault(ad, []).append(nm)
            regions.append((stream, r, dent, kinds, anchor, label_at, base, data, gap, k0 < len(emit)))
    newls = [dict() for _ in regions]
    blocks = []
    for pas in (1, 2):
        blocks = []
        stats.clear()
        for rg, newl in zip(regions, newls):
            stream, r, dent, kinds, anchor, label_at, base, data, gap, has_next = rg
            la = dict(label_at)
            if not data:
                body, stt = [], collections.Counter()
            else:
                body, stt = region_lines(st, namer, stream, base, data, kinds, '%s_r%d' % (stream, r[1]), la, newl, stream in (3, 4) or gap)
            for k_, n_ in stt.items():
                stats['rep_' + k_] += n_
            blocks.append((rg, body))
    emitted = set()
    ifdef = bool(st.get('ifdef'))
    wraps = collections.defaultdict(list)             # file -> [(first line, last line, kun block or None)]
    for rg, body in blocks:
        stream, r, dent, kinds, anchor, label_at, base, data, gap, has_next = rg
        for line in body:
            if line and line[0] not in ' ' + TAB + ';':
                emitted.add(line.split()[0])
        desc = describe(dent)
        hdr = '; ---- v0.04: ' + ('changed/new code or data' if data else 'code removed') + ((' (4.Z80: ' + desc + ')') if desc else '')
        if ifdef:
            hdr = '; ---- Kunge campaign only: ' + ('changed/new code or data' if data else 'code removed') + ((' (hum: ' + desc + ')') if desc else '')
        if gap:
            lines = [hdr, TAB + 'ORG' + TAB + '#%04X' % base] + body + [TAB + 'ORG' + TAB + '#%04X' % (base + len(data))]
        elif final:
            lines = [hdr] + body
        else:
            lines = [hdr, TAB + 'CHK_' + TAB + '#%04X' % base] + body + [TAB + 'CHK_' + TAB + '#%04X' % (base + len(data))]
        if ifdef:
            files = collections.defaultdict(list)
            for e in dent:
                files[e.file].append(e.line)
            if dent:
                for fn_, ls_ in files.items():
                    wraps[fn_].append((sorted(set(ls_)), lines if fn_ == anchor.file else None))
                if anchor.file not in files:
                    inserts[anchor.file][anchor.line].append(TAB + 'IFDEF' + TAB + 'KUN' + NL + NL.join(lines) + NL + TAB + 'ENDIF')
            elif has_next:
                inserts[anchor.file][anchor.line].append(TAB + 'IFDEF' + TAB + 'KUN' + NL + NL.join(lines) + NL + TAB + 'ENDIF')
            else:
                tails[anchor.file].append(TAB + 'IFDEF' + TAB + 'KUN' + NL + NL.join(lines) + NL + TAB + 'ENDIF')
        elif dent:
            for e in dent:
                deleted[e.file].add(e.line)
            inserts[anchor.file][anchor.line].append(NL.join(lines))
        elif has_next:
            inserts[anchor.file][anchor.line].append(NL.join(lines))
        else:
            tails[anchor.file].append(NL.join(lines))
    # labels whose v0.04 address is the start of a KEPT line (not inside generated code): put them in front of that line
    by_addr = {}
    for stream_, e_, va_, v_, vb_ in st['kept_entries']:
        by_addr.setdefault((stream_, va_), e_)
    orphans = 0
    for nm, (key, addr) in list(L.pos.items()):
        if L.src[nm] != 'kept' and nm not in emitted and not (ifdef and key == 'M' and addr >= 0x8000):
            e_ = by_addr.get((key, addr))
            if e_ is not None:
                inserts[e_.file][e_.line].append((TAB + 'IFDEF' + TAB + 'KUN' + NL + nm + NL + TAB + 'ENDIF') if ifdef else nm)
                emitted.add(nm)
                orphans += 1
    st['aliased'] = orphans
    tree = os.path.join(SRC, variant if not ifdef else variant + '_ifdef')
    shutil.rmtree(tree, ignore_errors=True)
    shutil.copytree(st['orig'], tree)
    stale = []
    for fn in sorted(os.listdir(tree)):
        if not fn.endswith('.asm') or fn == 'top.asm':
            continue
        Ls = open(os.path.join(tree, fn), encoding='utf-8').read().split(NL)
        out_l = []
        ins_at = collections.defaultdict(list)
        for i, blk in inserts.get(fn, {}).items():
            j = i
            while j > 1 and (not Ls[j - 2].strip() or Ls[j - 2].lstrip().startswith(';') or re.match(r'[A-Za-z_][A-Za-z0-9_]*\s*(;.*)?$', Ls[j - 2])):
                j -= 1
            ins_at[j] += blk
        starts = {}                    # line -> kun block / None (first line of a run of replaced lines)
        ends = collections.defaultdict(int)
        inside = set()
        for ls_, blk in sorted(wraps.get(fn, []), key=lambda t: t[0][0]):
            run = [ls_[0]]
            first = True
            for x in ls_[1:] + [None]:
                if x is not None and x == run[-1] + 1:
                    run.append(x)
                    continue
                starts[run[0]] = blk if first else None
                ends[run[-1]] += 1
                inside.update(run)
                first = False
                run = [x] if x is not None else []
        for i, line in enumerate(Ls, 1):
            if i in ins_at:
                out_l += ins_at[i]
            if i in asserts.get(fn, {}):
                out_l += asserts[fn][i]
            lab = re.match(r'([A-Za-z_][A-Za-z0-9_]*)', line) if line and line[0] not in ' ' + TAB + ';' else None
            nm = sjn(lab.group(1)) if lab else None
            if ifdef:
                if i in starts:
                    blk = starts[i]
                    if blk is not None:
                        out_l.append(TAB + 'IFDEF' + TAB + 'KUN')
                        out_l += blk
                        out_l.append(TAB + 'ELSE')
                    else:
                        out_l.append(TAB + 'IFNDEF' + TAB + 'KUN')
                if nm and i not in inside and re.match(r'([A-Za-z_][A-Za-z0-9_]*)\s*(;.*)?$', line) and nm in emitted:
                    out_l += [TAB + 'IFNDEF' + TAB + 'KUN', line, TAB + 'ENDIF']       # defined at another place in the Kunge build
                else:
                    out_l.append(line)
                for _ in range(ends.get(i, 0)):
                    out_l.append(TAB + 'ENDIF')
                continue
            if i in deleted.get(fn, ()):
                if nm and nm not in emitted and nm not in L.pos:
                    out_l.append(lab.group(1) + TAB + '; (removed in v0.04; label kept for references)')
                    stale.append(nm)
                continue
            if nm and re.match(r'([A-Za-z_][A-Za-z0-9_]*)\s*(;.*)?$', line) and nm in emitted:
                continue
            out_l.append(line)
        out_l += tails.get(fn, [])
        open(os.path.join(tree, fn), 'w', encoding='utf-8', newline=NL).write(NL.join(out_l))
    return tree, namer, stats, stale


def kun_state(Ls):
    """per line: True when the line is inside the KUN branch of one of our IFDEF KUN blocks"""
    stack = []
    res = []
    for l in Ls:
        t = l.strip()
        m = re.match(r'(IFDEF|IFNDEF|IF)\s*(\S*)', t, re.I)
        if m:
            kind = m.group(1).upper()
            stack.append('k' if (kind == 'IFDEF' and m.group(2) == 'KUN') else 'n' if (kind == 'IFNDEF' and m.group(2) == 'KUN') else 'x')
            res.append(any(x == 'k' for x in stack[:-1]))
            continue
        if t.upper() == 'ELSE' and stack:
            stack[-1] = {'k': 'n', 'n': 'k', 'x': 'x'}[stack[-1]]
            res.append(any(x == 'k' for x in stack[:-1]))
            continue
        if t.upper() == 'ENDIF' and stack:
            res.append(any(x == 'k' for x in stack[:-1]))
            stack.pop()
            continue
        res.append(any(x == 'k' for x in stack))
    return res


def stage2(st, tree, namer, maxit=6):
    variant = st['variant']
    V = st['V']
    out = os.path.join(BUILD, variant)
    fixed = set()
    for it in range(maxit):
        for n_ in range(8):
            try:
                os.remove(os.path.join(out, 'page%d.bin' % n_))
            except OSError:
                pass
        rc, txt = M.sjasm(tree, out, variant)
        errs = [l for l in txt.split(NL) if 'error' in l]
        if not os.path.exists(os.path.join(out, 'page0.bin')):
            print('no output:', errs[:5])
            return False
        pages = {n: open(os.path.join(out, 'page%d.bin' % n), 'rb').read() for n in range(8)}
        ents = M.parse_listing(os.path.join(out, 'main.lst'), pages, tree)
        M.classify(ents, pages)
        bad = []
        for e in ents:
            if e.n == 0 or e.kind == 'wild' or (st.get('ifdef') and e.stream == 'M' and e.addr >= 0x8000):
                continue
            key = e.stream
            img = (pages[5] + pages[2]) if key == 'M' else pages[key]
            ref = (V[5] + V[2]) if key == 'M' else V[key]
            base = 0x4000 if key == 'M' else 0xC000
            o = img[e.addr - base:e.addr - base + e.n]
            t = ref[e.addr - base:e.addr - base + e.n]
            if o != t:
                bad.append((e, t))
        print('stage 2 iteration', it, ':', len(bad), 'entries differ;', len(errs), 'assembler errors', errs[:2])
        if not bad:
            return True
        fixes = collections.defaultdict(dict)
        for e, t in bad:
            fixes[e.file][e.line] = (e, t)
        for fn, fx in fixes.items():
            p = os.path.join(tree, fn)
            Ls = open(p, encoding='utf-8').read().split(NL)
            kst = kun_state(Ls)
            for ln, (e, t) in sorted(fx.items(), reverse=True):
                line = Ls[ln - 1]
                label = line.split()[0] if line and line[0] not in ' ' + TAB + ';' else ''
                key = e.stream
                again = (fn, e.addr) in fixed
                fixed.add((fn, e.addr))
                com = ' ; v0.04 (was: %s)' % ' '.join(e.text.split(';')[0].split())
                new = None
                if e.kind == 'code' and e.n <= 4 and not again:
                    mem = st['ctx'].memory(key)
                    mem[e.addr:e.addr + e.n] = list(t)
                    ins = dz.dis(mem, e.addr, e.addr + 1)[0]
                    if len(ins.bytes) == e.n and not ins.operation.lower().startswith('def') and not (t[0] == 0xED and len(t) > 1 and t[1] in (0x63, 0x6B)):
                        new = fmt_ins(ins, namer, key)
                elif e.kind == 'thread' and e.n == 2 and not again:
                    w = t[0] | t[1] << 8
                    tg = (e.addr + 2 + w) & 0xFFFF
                    nm = namer.lookup(key, tg, 'mem')
                    new = ('CALL_' + TAB + nm) if nm and w else None
                if new is None and st.get('ifdef') and e.n > 8:
                    st.setdefault('unfixed', []).append((fn, ln, e.addr, e.n, e.text.strip()[:40]))
                    continue
                if new is None:
                    if e.n > 40:
                        adir = os.path.join(ASSETS_V, variant)
                        fn2 = 'fix_%s_%04X.bin' % (key, e.addr)
                        open(os.path.join(adir, fn2), 'wb').write(t)
                        new = 'INCBIN' + TAB + '"%s/%s"' % (variant, fn2)
                    else:
                        new = 'DEFB' + TAB + ','.join('#%02X' % x for x in t)
                newline = (label + TAB if label else TAB) + new + com
                inplace = kst[ln - 1] or (ln >= 2 and Ls[ln - 2].strip().replace(TAB, ' ') == 'IFDEF KUN')
                if st.get('ifdef') and not inplace:
                    Ls[ln - 1] = NL.join([TAB + 'IFDEF' + TAB + 'KUN', newline, TAB + 'ELSE', line, TAB + 'ENDIF'])
                else:
                    Ls[ln - 1] = newline
            open(p, 'w', encoding='utf-8', newline=NL).write(NL.join(Ls))
    return False


def finalise(tree):
    n_chk = n_was = 0
    for fn in os.listdir(tree):
        if not fn.endswith('.asm') or fn == 'top.asm':
            continue
        p = os.path.join(tree, fn)
        Ls = open(p, encoding='utf-8').read().split(NL)
        out = []
        for l in Ls:
            if re.match(r'\s+CHK_\s', l):
                n_chk += 1
                continue
            if ' ; v0.04 (was:' in l:
                l = l[:l.index(' ; v0.04 (was:')]
                n_was += 1
            out.append(l)
        open(p, 'w', encoding='utf-8', newline=NL).write(NL.join(out))
    return n_chk, n_was


def count_absolute(tree):
    res = []
    for fn in sorted(os.listdir(tree)):
        if not fn.endswith('.asm') or fn == 'top.asm':
            continue
        for i, l in enumerate(open(os.path.join(tree, fn), encoding='utf-8').read().split(NL), 1):
            code = l.split(';')[0]
            m = re.match(r'(?:\S+)?\s+(LD|JP|CALL|JR|DJNZ|ADD|SBC|CP|ADC|SUB|AND|OR|XOR)\s+(.*)$', code, re.I)
            if m and re.search(r'(?<![\w])#([4-9A-F][0-9A-F]{3})\b', m.group(2)):
                res.append((fn, i, l.strip()[:60]))
    return res


def main():
    variant = sys.argv[1]
    final = '--final' in sys.argv
    base = None
    if '--base' in sys.argv:
        base = sys.argv[sys.argv.index('--base') + 1]
    st = S.build(variant, final, base)
    st['ifdef'] = bool(base) and variant == 'kun'
    print('layout:', st['info'])
    tree, namer, stats, stale = generate(st, final)
    print('generated', tree, dict(stats), 'stale labels kept:', len(stale), stale[:8])
    ok = True if '--nostage2' in sys.argv else stage2(st, tree, namer)
    print('stage 2:', 'ok' if ok else 'NOT converged')
    if final:
        print('removed CHK_ lines / was-comments:', finalise(tree))
    a = count_absolute(tree)
    print('numeric operands >= #4000 left in the tree:', len(a))
    for x in a[:12]:
        print('   ', x)


if __name__ == '__main__':
    main()
