#!/usr/bin/env python3
"""Reconstruct readable sources of the released demo v0.04 from our faithful sources (4.Z80 build) and the v0.04 page images.

    python tools/mkv04.py hum|kun [--iter N]

Pipeline (per variant):
 1. assemble work/src_v04/game_orig (+ -DKUN for the Kunge campaign) with a listing; cut our image into "entries" (one per source line that
    emits bytes), decode each instruction and mask its 16-bit operands;
 2. align the entries with the v0.04 pages (greedy, with re-synchronisation): runs that match are KEPT (the original source line, with the
    author's label and comment); runs that do not match (changed/new/removed code, data of the other level) are REPLACED by a disassembly of
    the v0.04 bytes (readable: operands are replaced by the names of known labels; branch targets inside get v4_XXXX labels);
 3. the generated tree work/src_v04/<variant>/ is assembled; every entry whose bytes still differ from v0.04 (operands that are literals,
    odd encodings) is rewritten from the v0.04 bytes; repeated until the pages agree.
The result for one variant is a complete source tree; tools/merge_v04.py then merges hum and kun into one tree with IFDEF KUN.
"""
import os, re, shutil, subprocess, sys, collections
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'tools'))
import dz

SJ = shutil.which('sjasmplus') or r'C:\sjasmplus\sjasmplus.exe'
SRC = os.path.join(ROOT, 'work', 'src_v04')
ASSETS = os.path.join(ROOT, 'work', 'assets_faithful')
V04 = os.path.join(ROOT, 'work', 'v04')
DATAOPS = {'DEFB', 'DEFW', 'DEFM', 'DEFS', 'INCBIN', 'DB', 'DW', 'DS'}
WILD = {'DEFR_', 'UNDEF_'}
LSTRE = re.compile(r'^\s*(\d+)(\+*)\s*([0-9A-F]{4})(?: ((?:[0-9A-F]{2} ?){0,4}))?\s*(>)?\t?(.*)$')


def sjasm(treedir, outdir, variant, extra_inc=(), defs=()):
    os.makedirs(outdir, exist_ok=True)
    cmd = [SJ, '--nologo', '--msg=err', '--lst=main.lst', '--sym=main.sym']
    if variant == 'kun':
        cmd.append('-DKUN=1')
    cmd += ['-D' + d for d in defs]
    for d in (treedir, os.path.join(SRC, 'lib'), ASSETS, os.path.join(ROOT, 'work', 'assets_v04')) + tuple(extra_inc):
        cmd += ['-I', d]
    cmd.append(os.path.join(treedir, 'top.asm'))
    r = subprocess.run(cmd, cwd=outdir, capture_output=True, text=True)
    return r.returncode, (r.stdout + r.stderr)


class Entry:
    __slots__ = ('file', 'line', 'addr', 'n', 'text', 'stream', 'mask', 'kind', 'label', 'op', '_rx')


def parse_listing(path, pagebins, srcdir=None):
    """-> list[Entry] of top-level source lines that emit bytes (n>0) or are macro calls, in assembly order; plus label positions."""
    stack = []
    cur_page = 0
    disp = None
    ents = []
    labels = []                      # (addr, stream, name, file, line)
    top = []                         # all top-level lines (file, line, addr, text, page)
    for raw in open(path, encoding='utf-8', errors='replace'):
        raw = raw.rstrip('\n')
        if raw.startswith('# file opened: '):
            stack.append(raw[15:])
            continue
        if raw.startswith('# file closed: '):
            stack.pop()
            continue
        m = LSTRE.match(raw)
        if not m or not stack:
            continue
        fname = stack[-1]
        if fname in ('top.asm', 'defr.inc', 'undefined.inc'):
            continue
        ln, depth, addr, byt, exp, text = m.groups()
        if exp == '>' or text.startswith('~') or re.match(r'\.\.\.\s*>', text) or (byt is None and text == '' and depth) or (text.strip() == '' and byt):
            continue
        addr = int(addr, 16)
        t = text
        if re.match(r'\s*DISP\b', t):
            disp = ['pending', addr, None]
        elif re.match(r'\s*ENT\b', t):
            disp = None
        elif disp:
            if disp[0] == 'pending':
                disp = ['on', disp[1], addr]            # physical base, logical base
            addr = disp[1] + (addr - disp[2])
        mm = re.match(r'\s*MMU\s+3\s*,\s*(\d)', t)
        if mm:
            cur_page = int(mm.group(1))
        top.append((fname, int(ln), addr, t, cur_page))
    # entries: length = distance to the next line with a larger address in the same stream
    res = []
    for i, (f, ln, a, t, pg) in enumerate(top):
        stream = 'M' if 0x4000 <= a < 0xC000 else pg
        res.append([f, ln, a, t, stream])
    # compute lengths
    out = []
    cache = {}
    for i, (f, ln, a, t, stream) in enumerate(res):
        if srcdir is not None:
            if f not in cache:
                cache[f] = open(os.path.join(srcdir, f), encoding='utf-8').read().split(chr(10))
            if ln - 1 < len(cache[f]):
                t = cache[f][ln - 1]
        n = 0
        for j in range(i + 1, len(res)):
            if res[j][4] == stream and res[j][2] != a:
                n = res[j][2] - a
                break
            if res[j][4] != stream and res[j][2] != a:
                # stream change: the entry runs to the end only if nothing else; use 0 when next is another stream and this line has no bytes
                pass
        if n < 0 or n > 0x8000:
            n = 0
        # an entry in front of an ORG/section jump gets a too long n: use the real size for INCBIN / DEFS
        mm_ = re.match(r'\s*(?:[^\s;]+\s+)?(INCBIN|DEFS)\s+(.*)', t)
        if mm_:
            if mm_.group(1) == 'INCBIN':
                am = re.match(r'"([^"]+)"(?:\s*,\s*(\d+)(?:\s*,\s*(\d+))?)?', mm_.group(2))
                if am:
                    for d in (ASSETS, os.path.join(ROOT, 'work', 'assets_v04')):
                        fp = os.path.join(d, am.group(1))
                        if os.path.exists(fp):
                            sz = os.path.getsize(fp)
                            off = int(am.group(2) or 0)
                            ln_ = int(am.group(3)) if am.group(3) else sz - off
                            n = min(n, ln_) if n else ln_      # the last entry of a stream has no successor: the file size
                            break
            else:
                am = re.match(r'(#[0-9A-Fa-f]+|\d+)\s*(?:,|;|$)', mm_.group(2))
                if am:
                    v_ = am.group(1)
                    nn_ = int(v_[1:], 16) if v_[0] == '#' else int(v_)
                    n = min(n, nn_) if n else nn_
        e = Entry()
        e.file, e.line, e.addr, e.text, e.stream = f, ln, a, t, stream
        e.n = n
        out.append(e)
    return out


def split_text(text):
    """-> (label or '', op uppercased, operands, comment)"""
    code = text
    com = ''
    q = False
    for k, ch in enumerate(text):
        if ch == '"':
            q = not q
        elif ch == ';' and not q:
            code, com = text[:k], text[k:]
            break
    label = ''
    if code and code[0] not in ' \t':
        label = re.match(r'\S+', code).group(0).rstrip(':')
        code = code[len(re.match(r'\S+', code).group(0)):]
    parts = code.split(None, 1)
    op = parts[0].upper() if parts else ''
    return label, op, (parts[1] if len(parts) > 1 else ''), com


def classify(entries, pages_ours):
    """fill kind/mask/label/op for every entry"""
    def img(e):
        if e.stream == 'M':
            return pages_ours[5] + pages_ours[2], 0x4000
        return pages_ours[e.stream], 0xC000
    for e in entries:
        label, op, args, com = split_text(e.text)
        e.label, e.op = label, op
        if e.n == 0 or op == '':
            e.n = 0
            e.kind = 'none'
            e.mask = []
            continue
        data, base = img(e)
        b = list(data[e.addr - base:e.addr - base + e.n])
        if len(b) < e.n:
            e.n = len(b)
        if e.n == 0:
            e.kind = 'none'
            e.mask = []
            continue
        if op in WILD:
            e.kind = 'wild'
            e.mask = [None] * e.n
        elif op in DATAOPS:
            e.kind = 'data'
            m = list(b)
            if op in ('DEFW', 'DW') and re.search(r'[A-Za-z_]', args):
                m = [None] * len(b)
            e.mask = m
        elif op.startswith('CALL_') or (op == 'CALL_'):
            e.kind = 'thread'
            e.mask = [None] * e.n
        elif op in ('CHK_', 'RELOC_', 'ASSERT', 'MACRO', 'ENDM', 'EQU', 'ORG', 'MMU', 'INCLUDE', 'DEVICE', 'IF', 'ELSE', 'ENDIF', 'IFDEF', 'ENT', 'DISP'):
            e.kind = 'none'
            e.n = 0
            e.mask = []
        else:
            e.kind = 'code'
            m = list(b)
            if e.n >= 3 and op not in ('JR', 'DJNZ'):
                pre = 1 if b[0] in (0xDD, 0xFD, 0xED) else 0
                o = b[pre] if len(b) > pre else 0
                if pre == 0 and e.n == 3 or (b[0] == 0xED and e.n == 4) or (b[0] in (0xDD, 0xFD) and e.n == 4 and o in (0x21, 0x22, 0x2A)):
                    m[-2] = m[-1] = None
            e.mask = m
    return entries


def match_at(e, v, p, base_v=0):
    n = e.n
    if p < 0 or p + n > len(v):
        return False
    mk = e.mask
    for k in range(n):
        x = mk[k]
        if x is not None and x != v[p + k]:
            return False
    return True


def informative(e):
    return sum(1 for x in e.mask if x is not None and x not in (0, 0xFF))


CANDS = None


def cands(dmax, pmax):
    global CANDS
    key = (dmax, pmax)
    if CANDS is None or CANDS[0] != key:
        lst = [(dp + 3 * di, di, dp) for di in range(dmax + 1) for dp in range(pmax + 1)]
        lst.sort()
        CANDS = (key, lst)
    return CANDS[1]


def getrx(e):
    r = getattr(e, '_rx', None)
    if r is None:
        r = re.compile(b'(?=' + b''.join(re.escape(bytes([x])) if x is not None else b'.' for x in e.mask) + b')', re.S)
        try:
            e._rx = r
        except AttributeError:
            pass
    return r


def anchor_ok(ents, i, v, p):
    """>= 3 consecutive emitting entries, >= 10 informative bytes, all matching at p"""
    k = 0
    cnt = 0
    inf = 0
    pp = p
    j = i
    while j < len(ents) and cnt < 6:
        e = ents[j]
        if e.n == 0:
            j += 1
            continue
        if e.kind == 'wild':
            pp += e.n
            j += 1
            continue
        if not match_at(e, v, pp):
            return False
        inf += informative(e)
        pp += e.n
        cnt += 1
        j += 1
        if cnt >= 3 and inf >= 10:
            return True
    return cnt >= 2 and inf >= 10 or (j >= len(ents) and cnt >= 1)


def align(ents, v, vbase):
    """ents: entries of one stream (emitting ones used), v: bytes of the v0.04 stream starting at address vbase.
    -> list of regions: ('keep', i0, i1, p0) / ('rep', i0, i1, p0, p1)  (entries i0..i1-1 index into ents)"""
    emit = [i for i, e in enumerate(ents) if e.n > 0]
    regions = []
    k = 0                                             # index in emit
    p = ents[emit[0]].addr - vbase if emit else 0     # position in v
    keep_start = None
    prev_end = None
    while k < len(emit):
        i = emit[k]
        e = ents[i]
        if (prev_end is not None and e.addr != prev_end) or (prev_end is None and k == 0 and e.addr - vbase > 0):
            # ORG / section jump in our sources: the v0.04 image has the same absolute address here
            if keep_start is not None:
                regions.append(('keep', keep_start[0], k, keep_start[1]))
                keep_start = None
            g1 = e.addr - vbase
            lo = 0 if prev_end is None else p
            if g1 > lo and any(v[lo:g1]):
                regions.append(('rep', k, k, lo, g1, 'gap'))          # bytes of v0.04 in a gap that our sources skip with ORG
            p = g1
        prev_end = e.addr + e.n
        if e.kind == 'wild' or match_at(e, v, p):
            if keep_start is None:
                keep_start = (k, p)
            p += e.n
            k += 1
            continue
        # mismatch: close the keep run
        if keep_start is not None:
            regions.append(('keep', keep_start[0], k, keep_start[1]))
            keep_start = None
        found = None
        for dmax, pmax in ((30, 300), (120, 1500), (500, 8000), (2500, 32768)):
            best = None
            for di in range(dmax + 1):
                if k + di >= len(emit):
                    break
                e2 = ents[emit[k + di]]
                if e2.kind == 'wild' or (informative(e2) < 1 and e2.n < 3):
                    continue
                rx = getrx(e2)
                lo = p
                hi = min(len(v), p + pmax + e2.n)
                for m_ in rx.finditer(v, lo, hi):
                    dp = m_.start() - p
                    cost = dp + 3 * di
                    if best is not None and cost >= best[0]:
                        break
                    if anchor_ok(ents, emit[k + di], v, p + dp):
                        best = (cost, di, dp)
                        break
                if best is not None and best[0] <= 3 * di:
                    break
            if best:
                found = (best[1], best[2])
                break
        if not found:
            regions.append(('rep', k, len(emit), p, len(v)))
            k = len(emit)
            break
        di, dp = found
        if di == 0 and dp == 0:
            di, dp = 1, 1                              # cannot happen; avoid endless loop
        regions.append(('rep', k, k + di, p, p + dp))
        k += di
        p += dp
        prev_end = None
    if keep_start is not None:
        regions.append(('keep', keep_start[0], len(emit), keep_start[1]))
        keep_start = None
    # bytes of v0.04 behind the last entry of ours (new code appended at the end of a page)
    if emit and (not regions or regions[-1][0] == 'keep'):
        last = ents[emit[-1]]
        pend = p if regions and regions[-1][0] == 'keep' else None
        if pend is not None:
            tail = v[pend:]
            nz = [i for i, x in enumerate(tail) if x]
            if nz and pend < len(v):
                regions.append(('rep', len(emit), len(emit), pend, pend + nz[-1] + 1))
    return emit, regions


# ---------------------------------------------------------------- refinement of replaced regions at instruction level
import difflib


def v_tokens(mem, a0, a1, vbase):
    """linear decode of mem[a0:a1] -> list of (offset relative to vbase, length, token)"""
    out = []
    a = a0
    while a < a1:
        try:
            ins = dz.dis(mem, a, a + 1)[0]
        except Exception:
            ins = None
        if ins is None or a + len(ins.bytes) > a1:
            out.append((a - vbase, 1, '%02x' % mem[a]))
            a += 1
            continue
        b = list(ins.bytes)
        n = len(b)
        op = ins.operation.lower()
        t = list(b)
        if n >= 3 and not op.startswith(('jr', 'djnz')):
            pre = 1 if b[0] in (0xDD, 0xFD, 0xED) else 0
            o = b[pre]
            if (pre == 0 and n == 3) or (b[0] == 0xED and n == 4) or (b[0] in (0xDD, 0xFD) and n == 4 and o in (0x21, 0x22, 0x2A)):
                t[-2] = t[-1] = None
        out.append((a - vbase, n, ''.join('..' if x is None else '%02x' % x for x in t)))
        a += n
    return out


def refine(ents, emit, v, vbase, regions):
    """split every 'rep' region into keep/rep pieces by an instruction-level diff (only plain code regions)"""
    mem = [0] * 65536
    mem[vbase:vbase + len(v)] = list(v)
    res = []
    for r in regions:
        if r[0] != 'rep':
            res.append(r)
            continue
        k0, k1, p0, p1 = r[1:5]
        es = [ents[emit[i]] for i in range(k0, k1)]
        if (not es) or p1 - p0 == 0 or any(e.kind != 'code' for e in es):
            res.append(r)
            continue
        A = [''.join('..' if x is None else '%02x' % x for x in e.mask) for e in es]
        vt = v_tokens(mem, vbase + p0, vbase + p1, vbase)
        B = [t for o, n, t in vt]
        voff = [o for o, n, t in vt] + [p1]
        sm = difflib.SequenceMatcher(None, A, B, autojunk=False)
        for tag, i1, i2, j1, j2 in sm.get_opcodes():
            if tag == 'equal':
                res.append(('keep', k0 + i1, k0 + i2, voff[j1]))
            else:
                res.append(('rep', k0 + i1, k0 + i2, voff[j1], voff[j2]))
    return res
