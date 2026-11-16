#!/usr/bin/env python3
"""Symbolic (relocatable) reconstruction of the v0.04 sources.   python tools/mkv04_sym.py hum|kun [--final]

Differences from mkv04_gen.py (which produced a byte-exact but absolute-address tree):
 * the v0.04 address of every label that our sources define is recovered:
     - labels on kept lines: their position in the v0.04 image;
     - labels inside changed/moved code or data: from the operands of kept instructions that refer to them
       (`LD HL,(MX)` is #2A <v0.04 address of MX>), from DEFW tables and from CALL_ tables (majority vote);
 * the label DEFINITIONS are put at those addresses inside the generated blocks (code is cut there, data is split there);
 * every absolute operand of generated code and of repaired lines is written as  label  or  label+offset  (the nearest label),
   addresses of ROM, ports and the screen stay numbers;
 * branch targets inside new code get names  v4_<previous label>_<n>.
--final removes the working marks (CHK_ address checks, "; v0.04 (was: ...)" comments).
"""
import collections, os, re, shutil, sys
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'tools'))
import dz, z80snap, a80conv
import mkv04 as M
import mkv04_gen as G

SRC = M.SRC
BUILD = os.path.join(ROOT, 'build', 'v04')
ASSETS_V = os.path.join(ROOT, 'work', 'assets_v04')
REG = set('A B C D E H L I R AF BC DE HL SP IX IY NZ Z NC PO PE P M IXH IXL IYH IYL'.split())
SCREEN_HI = 0x5AFF


def sjn(n):
    return a80conv.sj_name(n)


class Layout:
    """label <-> v0.04 address tables"""

    def __init__(self):
        self.pos = {}                 # name -> (key, addr)
        self.src = {}                 # name -> 'kept' | 'inferred' | 'asset' | 'v4'
        self.by_key = collections.defaultdict(dict)    # key -> {addr: [names]}
        self.sorted = {}

    def add(self, name, key, addr, how):
        if name in self.pos:
            return
        self.pos[name] = (key, addr)
        self.src[name] = how
        self.by_key[key].setdefault(addr, []).append(name)
        self.sorted.pop(key, None)

    def lst(self, key):
        if key not in self.sorted:
            self.sorted[key] = sorted(self.by_key[key].items())
        return self.sorted[key]


def key_of(addr, page):
    return 'M' if 0x4000 <= addr < 0xC000 else page


def build(variant, final=False, base=None):
    orig = os.path.abspath(base) if base else os.path.join(SRC, 'game_orig')
    out = os.path.join(BUILD, variant + ('_base' if base else '_orig'))
    rc, txt = M.sjasm(orig, out, variant)
    if rc:
        sys.exit('assembly of the original failed:\n' + txt)
    pages = {n: open(os.path.join(out, f'page{n}.bin'), 'rb').read() for n in range(8)}
    ents = M.parse_listing(os.path.join(out, 'main.lst'), pages, orig)
    M.classify(ents, pages)
    V = {n: open(os.path.join(ROOT, 'work', 'v04', f'br2{variant}04.{n}.bin'), 'rb').read() for n in range(8)}
    sym = {}
    for l in open(os.path.join(out, 'main.sym')):
        m = re.match(r'(\S+):\s*EQU 0x([0-9A-F]+)', l)
        if m:
            sym[m.group(1)] = int(m.group(2), 16)
    lst = z80snap.symbols(os.path.join(ROOT, 'archive', 'unz', 'BR2_DEMO', 'ASM80', '4.LST'))
    page_of = {}                                # label name (sjasmplus spelling) -> page of the 4.Z80 sources
    if base:                                    # the base is the finished tree of the other campaign: its labels
        for e in ents:
            if e.label and e.op not in ('EQU', 'MACRO', 'DEFL') and not e.text.lstrip().startswith(';') and e.n >= 0:
                nm = sjn(e.label)
                if nm in sym:
                    page_of[nm] = (5 if e.addr < 0x8000 else 2) if e.stream == 'M' else e.stream
        lst = {}
    for k, (a, w) in lst.items():
        if w.startswith('Main'):
            page_of[sjn(k)] = 5 if a < 0x8000 else 2
        elif w.startswith('Pg'):
            page_of[sjn(k)] = int(w[-2:], 16)
        elif w.startswith('Def in DISP'):
            page_of[sjn(k)] = 6
    # ---------------------------------------------------------------- alignment
    plans = []
    for stream in ('M', 0, 1, 3, 4, 6, 7):
        es = [e for e in ents if e.stream == stream]
        if base and variant == 'kun' and stream == 'M':
            # Kunge campaign: the level block (#8000..) has the same layout as the Human one; only its data differ: it is handled
            # as a block of its own (map, HER, level parameters under IFDEF KUN, the rest is working state, see kun_live.txt)
            es = [e for e in es if e.addr < 0x8000]          # the level block: mk_kun_level.py (overlay) and kun_live.txt
        if base and variant == 'kun' and stream == 7:
            es = [e for e in es if e.addr >= 0xDB00]           # #C000-#DAFF is the screen of the snapshot (working state)
        if not es:
            continue
        v = (V[5] + V[2]) if stream == 'M' else V[stream]
        vbase = 0x4000 if stream == 'M' else 0xC000
        emit, reg = M.align(es, v, vbase)
        reg = M.refine(es, emit, v, vbase, reg)
        if base and variant == 'kun':
            reg = [r for r in reg if not (len(r) > 5 and r[5] == 'gap' and (vbase + r[3] >= 0x8000 or stream == 7))]       # gaps hold working state
            if stream == 'M':
                reg = [r for r in reg if not (r[0] == 'rep' and vbase + r[3] >= 0x8000)]
                reg = [(r[0], r[1], r[2], r[3], min(r[4], 0x8000 - vbase)) + tuple(r[5:]) if r[0] == 'rep' else r for r in reg]
        if base and variant == 'kun':
            import verify_v04
            live = verify_v04.live_ranges('kun')
            def is_live(r):
                if r[0] != 'rep' or r[4] <= r[3]:
                    return False
                for x in range(vbase + r[3], vbase + r[4]):
                    pgx = (5 if x < 0x8000 else 2) if stream == 'M' else stream
                    if (pgx, x) not in live:
                        return False
                return True
            reg = [r for r in reg if not is_live(r)]
            if stream == 'M':
                reg = [r for r in reg if not (r[0] == 'rep' and r[1] == r[2] == len(emit))]       # nothing after the window: working state
        reg = [('rep', 0, len(emit), 0, len(v))] if (stream in (3, 4) and not base) else G.split_jumps(es, emit, reg, vbase)
        plans.append((stream, es, emit, reg, v, vbase))
    # ---------------------------------------------------------------- 1. labels of kept lines
    L = Layout()
    kept_start = {}                               # (stream, ours addr) -> v0.04 address
    kept_entries = []                             # (stream, entry, v0.04 address)
    for stream, es, emit, reg, v, vbase in plans:
        for r in reg:
            if r[0] == 'keep':
                p = r[3]
                for ei in range(r[1], r[2]):
                    e = es[emit[ei]]
                    kept_start[(stream, e.addr)] = vbase + p
                    kept_entries.append((stream, e, vbase + p, v, vbase))
                    p += e.n
    for e in ents:
        if e.label and e.op not in ('EQU', 'MACRO', 'DEFL') and not e.text.lstrip().startswith(';'):
            nm = sjn(e.label)
            if nm in page_of and (e.stream, e.addr) in kept_start:
                va = kept_start[(e.stream, e.addr)]
                L.add(nm, key_of(va, e.stream), va, 'kept')
    # assets: resource files that moved between pages (labels hrh*, hrm*, WNAMES, hr_sh1...) -- found by their bytes
    alabels0 = G.asset_labels(orig)
    aset0 = G.asset_table()
    for nm_, d_ in aset0.items():
        rel_ = ('data/hero/' if '/HERO/' in nm_ else 'data/') + os.path.basename(nm_).lower()
        lab_ = alabels0.get(rel_)
        if not lab_ or len(d_) < 64:
            continue
        for pg_ in (3, 4, 6, 1, 0, 7):
            k_ = V[pg_].find(d_)
            if k_ < 0:
                k_ = V[pg_].find(d_[:48])
            if k_ >= 0:
                L.add(sjn(lab_), pg_, 0xC000 + k_, 'asset')
                break
    # ---------------------------------------------------------------- 2. inference from references in kept lines
    votes = collections.defaultdict(collections.Counter)

    tvotes = collections.defaultdict(collections.Counter)

    def vote(name, ours_val, v_val, thread=False):
        name = sjn(name)
        if name in sym and name in page_of:
            k = ours_val - sym[name]
            (tvotes if thread else votes)[name][(v_val - k) & 0xFFFF] += 1

    def ids_of(expr):
        return [t for t in re.findall(r"[A-Za-z_][A-Za-z0-9_]*", expr) if t.upper() not in REG and sjn(t) in page_of]

    for stream, e, va, v, vbase in kept_entries:
        label, op, args, com = M.split_text(e.text)
        off = va - vbase
        vb = v[off:off + e.n]
        ob = None
        if e.kind == 'code' and e.n >= 3 and e.mask and e.mask[-1] is None and op not in ('JR', 'DJNZ'):
            ids = ids_of(args)
            if len(ids) == 1:
                ob = (stream, e)
                # our bytes: from the faithful page image
                img = pages[5] + pages[2] if stream == 'M' else pages[stream]
                base = 0x4000 if stream == 'M' else 0xC000
                ours = img[e.addr - base:e.addr - base + e.n]
                vote(ids[0], ours[-2] | ours[-1] << 8, vb[-2] | vb[-1] << 8)
        elif e.kind == 'code' and e.n == 2 and op in ('JR', 'DJNZ'):
            ids = ids_of(args)
            if len(ids) == 1:
                img = pages[5] + pages[2] if stream == 'M' else pages[stream]
                base = 0x4000 if stream == 'M' else 0xC000
                ours = img[e.addr - base:e.addr - base + 2]
                so = ours[1] - 256 if ours[1] > 127 else ours[1]
                sv = vb[1] - 256 if vb[1] > 127 else vb[1]
                vote(ids[0], (e.addr + 2 + so) & 0xFFFF, (va + 2 + sv) & 0xFFFF)
        elif e.kind == 'data' and op in ('DEFW', 'DW'):
            img = pages[5] + pages[2] if stream == 'M' else pages[stream]
            base = 0x4000 if stream == 'M' else 0xC000
            ours = img[e.addr - base:e.addr - base + e.n]
            items = [x.strip() for x in args.split(',')]
            if len(items) * 2 == e.n:
                for i, it in enumerate(items):
                    ids = ids_of(it)
                    if len(ids) == 1:
                        vote(ids[0], ours[2 * i] | ours[2 * i + 1] << 8, vb[2 * i] | vb[2 * i + 1] << 8)
        elif e.kind == 'thread' and op == 'CALL_':
            ids = ids_of(args)
            if len(ids) == 1 and e.n == 2:
                img = pages[5] + pages[2] if stream == 'M' else pages[stream]
                base = 0x4000 if stream == 'M' else 0xC000
                ours = img[e.addr - base:e.addr - base + 2]
                ow = ours[0] | ours[1] << 8
                vw = vb[0] | vb[1] << 8
                vote(ids[0], (e.addr + 2 + ow) & 0xFFFF, (va + 2 + vw) & 0xFFFF, thread=True)
    for name, c in tvotes.items():            # CALL_ words match as wildcards: a single vote of them is not trusted
        if sum(c.values()) >= 2 or name in votes:
            for a_, n_ in c.items():
                votes[name][a_] += n_
    st_votes = votes
    conflicts = 0
    for name, c in votes.items():
        if name in L.pos:
            continue
        addr, n = c.most_common(1)[0]
        if len(c) > 1:
            conflicts += 1
        pg = page_of[name]
        key = 'M' if 0x4000 <= addr < 0xC000 else pg if pg not in (5, 2) else None      # a routine may have moved from a page to Main
        if key is None or addr < 0x4000:
            continue
        L.add(name, key, addr, 'inferred')
    for (key, addr), nm in ([] if base else sorted(G.global_names(variant).items(), key=lambda t: (str(t[0][0]), t[0][1]))):
        if nm in page_of:
            L.add(nm, key, addr, 'chunk')
    # asset labels (hrh*, WNAMES...) are placed by the generator when an asset file is recognised
    alabels = G.asset_labels(orig)
    aset = G.asset_table()
    ctx = G.Ctx(V, {})
    info = {'conflicts': conflicts, 'inferred': sum(1 for n in L.src.values() if n == 'inferred'), 'kept': sum(1 for n in L.src.values() if n == 'kept'), 'chunk': sum(1 for n in L.src.values() if n == 'chunk')}
    return dict(votes=votes, kept_entries=kept_entries, variant=variant, orig=orig, out=out, pages=pages, ents=ents, V=V, sym=sym, page_of=page_of, plans=plans, L=L,
                alabels=alabels, aset=aset, ctx=ctx, info=info, lst=lst)


if __name__ == '__main__':
    st = build(sys.argv[1])
    print(st['info'])
    L = st['L']
    miss = [n for n in st['page_of'] if n not in L.pos]
    print('labels of the sources:', len(st['page_of']), ' placed:', len(L.pos), ' not placed:', len(miss))
