import sys, os, collections, re
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__))))
import mkv04_symgen as g, mkv04_sym as S, mkv04 as M
variant = sys.argv[1] if len(sys.argv) > 1 else 'hum'
st = S.build(variant)
tree, namer, stats, stale = g.generate(st)
out = os.path.join(M.ROOT, 'build', 'v04', variant)
rc, txt = M.sjasm(tree, out, variant)
pages = {n: open(os.path.join(out, 'page%d.bin' % n), 'rb').read() for n in range(8)}
ents = M.parse_listing(os.path.join(out, 'main.lst'), pages, tree)
M.classify(ents, pages)
V = st['V']
sym = {}
for l in open(os.path.join(out, 'main.sym')):
    m = re.match(r'(\S+):\s*EQU 0x([0-9A-F]+)', l)
    if m:
        sym[m.group(1)] = int(m.group(2), 16)
cnt = collections.Counter()
ex = {}
nbad = 0
for e in ents:
    if e.n == 0 or e.kind == 'wild':
        continue
    key = e.stream
    img = (pages[5] + pages[2]) if key == 'M' else pages[key]
    ref = (V[5] + V[2]) if key == 'M' else V[key]
    base = 0x4000 if key == 'M' else 0xC000
    o = img[e.addr - base:e.addr - base + e.n]
    t = ref[e.addr - base:e.addr - base + e.n]
    if o != t:
        nbad += 1
        label, op, args, com = M.split_text(e.text)
        ids = [x for x in re.findall(r'[A-Za-z_][A-Za-z0-9_]*', args) if x in st['L'].pos]
        if not ids:
            ids2 = [x for x in re.findall(r'[A-Za-z_][A-Za-z0-9_]*', args) if x in st['page_of'] or x in ('PROTeC','INI_D2','LOD1st')]
            for i in ids2:
                cnt['<unplaced> ' + i] += 1
                ex.setdefault('<unplaced> ' + i, (e.file, e.line, e.text.strip()[:50], '', ''))
            if not ids2:
                cnt['<none>'] += 1
                ex.setdefault('<none>', (e.file, e.line, e.text.strip()[:50], '', ''))
        for i in ids:
            cnt[i] += 1
            ex.setdefault(i, (e.file, e.line, e.text.strip()[:40], hex(st['L'].pos[i][1]), hex(sym.get(i, 0))))
print(nbad, 'entries differ;', len(cnt), 'labels involved')
for n, c in cnt.most_common(int(sys.argv[2]) if len(sys.argv) > 2 else 25):
    print(n, c, st['L'].src.get(n), ex[n])
