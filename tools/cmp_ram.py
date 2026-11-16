#!/usr/bin/env python3
"""Сверка ОЗУ игры в эмуляторе с образом v0.04 (work/v04/br2{hum,kun}04.N.bin) в момент "уровень инициализирован".
    python -I tools/cmp_ram.py build/emu/kr.json kun|hum
Страницы и адреса образа v0.04 не те, что у нас (образ кунгов: страница 5 после _start на +2 байта; наша - раскладка людей).
Поэтому правила такие:
  * слово-операнд, у которого и наше, и образа значение - адрес одной и той же метки S+смещение) в двух раскладках (наш main.sym и
    main.sym сборки v0.04 из work/src_v04: build/v04/<side>), - чистый сдвиг адресов;
  * маска живого состояния work/src_v04/kun_live.txt (только кунги: образ снят из работающей игры);
  * страница 1 (ландшафт) и 7 (кнопки) - данные из файлов диска; 5 и 2 сверяются по областям (см. ниже).
Выводит число расхождений по страницам и списком те, что не объяснены."""
import sys, json, re, os, collections
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def syms(p):
    d = {}
    for l in open(p, encoding='utf-8', errors='ignore'):
        m = re.match(r'(\S+):\s+EQU\s+0x([0-9A-F]+)', l)
        if m: d[m.group(1)] = int(m.group(2), 16)
    return d

def reloc_table(side):
    """имя -> (наш адрес, адрес в образе): наши метки (build/game/main.sym) и метки сборки v0.04 (build/v04/<side>/main.sym; tools/verify_v04.py)"""
    o = syms(os.path.join(ROOT, 'build', 'game', 'main.sym')); r = syms(os.path.join(ROOT, 'build', 'v04', side, 'main.sym'))
    if side == 'kun':   # в сборке v0.04 из work/src_v04 таблицы AT_TYP/AT_TY2 (данные между мёртвыми таблицами) стоят иначе, чем в образе кунгов (IFNDEF KUN)
        r['AT_TYP'] = 0x4DCC; r['AT_TY2'] = 0x4DE4
    byaddr = collections.defaultdict(list)
    for n, a in o.items():
        if n in r: byaddr[a].append(n)
    return o, r, byaddr

def same_symbol(o, r, byaddr, wo, wr):
    for k in range(-40, 70):
        for n in byaddr.get((wo - k) & 0xFFFF, ()):
            if (r[n] + k) & 0xFFFF == wr: return n, k
    return None

def live(side):
    res = {}
    p = os.path.join(ROOT, 'work', 'src_v04', 'kun_live.txt')
    if side != 'kun': return res
    for l in open(p, encoding='utf-8'):
        if l.startswith('#') or not l.strip(): continue
        t = l.split(None, 4)
        pg, a, b = int(t[0]), int(t[1], 16), int(t[2], 16)
        mask = 0
        if len(t) > 4 and re.fullmatch(r'[0-9A-Fa-f]{2}', t[3]): mask = int(t[3], 16)
        for x in range(a, b + 1):
            for pgx in ((5,) if (pg in (5, 2) and x < 0x8000) else (2,) if pg in (5, 2) else (pg,)):
                res[(pgx, x)] = mask
    return res

def main():
    js, side = sys.argv[1], sys.argv[2]
    mem = json.load(open(js))['data']['mem']
    L = live(side)
    tot = collections.Counter()
    for pg in (0, 3, 4, 6, 7, 1, 2):
        ours = bytes.fromhex(mem['b%d' % pg])
        ref = open(os.path.join(ROOT, 'work', 'v04', 'br2%s04.%d.bin' % (side, pg)), 'rb').read()
        base = 0x4000 if pg == 5 else 0x8000 if pg == 2 else 0xC000
        diffs = [i for i in range(16384) if ours[i] != ref[i]]
        cnt = collections.Counter(); un = []
        used = set()
        o_, r_, ba_ = reloc_table(side)
        for i in diffs:
            if i in used: continue
            a = base + i
            if (pg, a) in L and (ours[i] & L[(pg, a)]) == (ref[i] & L[(pg, a)]):
                cnt['live'] += 1; continue
            hit = False
            for s in (i - 1, i):
                if 0 <= s < 16383:
                    ow = ours[s] | ours[s + 1] << 8; rw = ref[s] | ref[s + 1] << 8
                    if ow != rw and not ({s, s + 1} & used) and same_symbol(o_, r_, ba_, ow, rw):
                        used.update((s, s + 1)); cnt['same symbol'] += 1; hit = True; break
            if not hit: un.append(i)
        runs = []
        for i in un:
            if runs and i - runs[-1][1] <= 2: runs[-1][1] = i
            else: runs.append([i, i])
        print('page %d: differing %d  live %d  same-symbol %d  unexplained %d' % (pg, len(diffs), cnt['live'], cnt['same symbol'], len(un)))
        if runs: print('   ', ' '.join('%04X+%d' % (base + a, b - a + 1) for a, b in runs[:60]), ('...' if len(runs) > 60 else ''))

def cmp5(js, side):
    """страница 5 после перемещения: код сверяется не по адресам (раскладка другая), а косвенно - через слова-адреса в страницах 0, 4, 6, 7 (выше) и
    переменные уровня LEVVARS: значения по меткам (наши в странице 5, в образе v0.04 - в странице 2 на #BE50..) должны совпасть, кроме живого состояния."""
    mem = json.load(open(js))['data']['mem']
    ours = bytes.fromhex(mem['b5'])
    ref2 = open(os.path.join(ROOT, 'work', 'v04', 'br2%s04.2.bin' % side), 'rb').read()
    O = syms(os.path.join(ROOT, 'build', 'game', 'main.sym')); R = syms(os.path.join(ROOT, 'build', 'v04', side, 'main.sym'))
    lv0, lv1 = O['LEVVARS'], O['zzzEND'] + 1
    items = {}
    for n, a in O.items():
        if lv0 <= a < lv1 and '.' not in n and n in R and R[n] >= 0x8000: items.setdefault(a, n)
    keys = sorted(items)
    live = {'MONEY', 'MAZUT', 'LEVRES', 'SEL_T', 'SEL_N', 'sel_en', 'LED', '_msg', 'pTX_AD', 'TX_AD', 'NOTA', 'levSND', 'NOTA2', 'priv_2', 'END_1', 'TheEND', 'seEND'} if side == 'kun' else {'END_1', 'TheEND', 'NOTA', 'NOTA2'}
    bad = []
    for i, a in enumerate(keys):
        n = items[a]; ln = (keys[i + 1] if i + 1 < len(keys) else lv1) - a
        ob = ours[a - 0x4000:a - 0x4000 + ln]; rb = ref2[R[n] - 0x8000:R[n] - 0x8000 + ln]
        if ob != rb and n not in live: bad.append((n, ob.hex(' ')[:30], rb.hex(' ')[:30]))
    print('LEVVARS (%d переменных) против образа v0.04: не совпало вне живых/перенесённых: %d' % (len(keys), len(bad)))
    for x in bad[:12]: print('   ', x)

def fog(js, side):
    """бит 7 клеток карты (#8000-#8FFF) = туман; у людей в образе тумана нет, у кунгов 2324 клетки закрыты (образ снят позже старта: юниты уже открыли часть)"""
    mem = json.load(open(js))['data']['mem']
    o = bytes.fromhex(mem['b2'])[:4096]; r = open(os.path.join(ROOT, 'work', 'v04', 'br2%s04.2.bin' % side), 'rb').read()[:4096]
    print('туман (бит 7 карты): у нас %d клеток, в образе %d; различий в битах 0-6: %d; различий в бите 7: %d; закрыто у нас, открыто в образе: %d, наоборот: %d' % (
        sum(1 for x in o if x & 128), sum(1 for x in r if x & 128), sum(1 for i in range(4096) if (o[i] ^ r[i]) & 127),
        sum(1 for i in range(4096) if (o[i] ^ r[i]) & 128), sum(1 for i in range(4096) if o[i] & 128 and not r[i] & 128),
        sum(1 for i in range(4096) if r[i] & 128 and not o[i] & 128)))

main()
cmp5(sys.argv[1], sys.argv[2])
fog(sys.argv[1], sys.argv[2])
