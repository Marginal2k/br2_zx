#!/usr/bin/env python3
"""Проверка перемещаемости кода (страницы 0 и 5).  python -I tools/check_reloc.py

Игра собирается как есть и с вставкой N байт в одной из точек (макрос RELOC_ в src/game/main.asm, game.asm; -DRELOCN=N -DRELOCW=k):
  k = 0      начало страницы 0 (#C000);
  k = 52..60 границы модулей страницы 5: 52 перед LEVVARS и таблицами, 53 lib1a, 54 intv, 55 lid, 56 io/startm/demo, 57 шрифт/dzx0/demo2,
             58 lib2, 59 sound1/scan, 60 local/var.
После вставки каждый адрес выше точки сдвигается на N. Проверяется:
  1. все различия образов - 16-битные слова, и каждое слово ровно на N-сдвинутый адрес (абсолютный адрес на метку выше точки), либо слово
     таблицы вызовов CALL_ (относительное смещение: меняется на N*(цель выше точки) - N*(слово выше точки));
  2. "не сдвинутые адреса": слова, которые должны были сдвинуться, но не изменились, - числа вместо меток. Ищутся в строках листинга: операнды
     LD/CALL/JP с числом вместо метки, коды в DEFB (опкод + слово), код в INCBIN-кусках (список CODE_CHUNKS). Известные исключения - в OK_*;
  3. записи списков _start (CALL_): запись после MEM6 не должна менять значение при вставке в страницу 0 (цель в странице 6), после MEM0 - должна.
Код возврата 1 - есть расхождения.  (Границы: страницы 1,3,4,7 - данные и спрайты, внутренние абсолютные адреса страницы 7/6 не проверяются.)"""
import os, re, shutil, subprocess, sys
sys.stdout.reconfigure(encoding='utf-8')
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'tools'))
SJ = os.environ.get('SJASMPLUS') or shutil.which('sjasmplus') or r'C:\sjasmplus\sjasmplus.exe'
N = 7
HOOKS5 = [52, 53, 54, 55, 56, 57, 58, 59, 60]
END5 = 0x7680           # выше - массивы героев (адреса закреплены в level.asm)
HEAD = re.compile(r'^\s*(\d+)\+*\s*([0-9A-F]{4})(?:\s(.*))?$')
OPS = {0xCD, 0xC3, 0xCA, 0xC2, 0xD2, 0xDA, 0xE2, 0xEA, 0xF2, 0xFA, 0xC4, 0xCC, 0xD4, 0xDC, 0xE4, 0xEC, 0xF4, 0xFC, 0x21, 0x11, 0x01, 0x31, 0x22, 0x2A, 0x32, 0x3A}

# числа вместо меток, которые проверены и являются константами (не адресами): (файл, значение) -> причина
OK_LITERAL = {
    ('lih.asm', 0x4217): 'LD HL,#4217: координаты/размер текста пункта (данные кнопки), не адрес',
    ('lih.asm', 0x4400): 'LD BC,(68*256)+0: счётчик/константа цикла (число 68, 0)',
    ('menu2.asm', 0x560C): 'LD HL,(86*256)+12: пара чисел (координаты), не адрес',
    ('menu2.asm', 0x536E): 'LD HL,(83*256)+110: пара чисел (координаты), не адрес',
    ('lih.asm', 0x4610): 'LD BC,#4610: пара байт-констант (в образе - данные таблицы, разобранные как код)',
    ('lih.asm', 0x4910): 'LD BC,#4910: то же',
    ('lie.asm', 0x6058): 'LD HL,#6058: атрибуты индикатора (цвет), не адрес',
    ('lib3.asm', 0x4838): 'LD BC,#4838: размеры/смещение цикла setBLT (число)',
    ('sound1.asm', 0x5000): 'LD DE,#5000: сумма BCD (+5000), не адрес',
}
OK_WORD = {}   # (файл, значение) числа в DEFW, не являющиеся адресами
# DEFB-код/данные, похожие на "опкод + адрес", но являющиеся данными: (файл, адрес-в-образе) -> причина
OK_RAW = {   # (файл, строка DEFB в src/game)
    ('lib1a.asm', 1292): 'bHEALT: таблица байтов-констант (здоровье/шаги), не код',
    ('lid.asm', 849): 'HEALTH: таблица пар (здоровье, признак), не код',
    ('lie.asm', 823): 'OUTBAR: DEFB-байты вызовов внутри страницы 7 (CALL #F33E...) и слова-приманки, адреса страницы 7',
}


def sjasm(tag, defs):
    out = os.path.join(ROOT, 'build', 'reloc_' + tag)
    shutil.rmtree(out, ignore_errors=True)
    os.makedirs(out)
    shutil.copy(os.path.join(ROOT, 'build', 'game', 'disk_layout.inc'), out)
    cmd = [SJ, '--nologo', '--msg=err', '--sym=main.sym', '--lst=main.lst'] + defs + [
        '-I', os.path.join(ROOT, 'src', 'game'), '-I', os.path.join(ROOT, 'src', 'lib'), '-I', os.path.join(ROOT, 'assets'), '-I', out,
        os.path.join(ROOT, 'src', 'game', 'game.asm').replace(os.sep, '/')]
    r = subprocess.run(cmd, cwd=out, capture_output=True, text=True)
    if r.returncode:
        sys.exit(r.stdout + r.stderr)
    pages = {p: open(os.path.join(out, 'page%d.bin' % p), 'rb').read() for p in range(8)}
    sym = {}
    for l in open(os.path.join(out, 'main.sym'), encoding='utf-8', errors='replace'):
        m = re.match(r'(\S+):\s+EQU\s+0x([0-9A-Fa-f]+)', l)
        if m:
            sym[m.group(1)] = int(m.group(2), 16)
    return pages, sym, os.path.join(out, 'main.lst')


def listing(path):
    """[(файл, строка, адрес, байты, текст)] из листинга sjasmplus (с учётом вложенных INCLUDE)"""
    out, stack, fil = [], [], ''
    for l in open(path, encoding='utf-8', errors='replace').read().split('\n'):
        if l.startswith('# file opened:'):
            stack.append(l.split(':', 1)[1].strip()); fil = stack[-1]; continue
        if l.startswith('# file closed:'):
            if stack: stack.pop()
            fil = stack[-1] if stack else ''
            continue
        m = HEAD.match(l)
        if not m: continue
        ln, addr, rest = m.groups(); rest = rest or ''
        toks = rest.split('\t', 1)
        txt = toks[1] if len(toks) > 1 else ''
        parts = toks[0].strip().split(); bs = []; i = 0
        while i < len(parts) and re.fullmatch(r'[0-9A-F]{2}', parts[i]):
            bs.append(int(parts[i], 16)); i += 1
        if i < len(parts): txt = (' '.join(parts[i:]) + ' ' + txt).strip()
        out.append((fil, int(ln), int(addr, 16), bytes(bs), txt.strip()))
    return out


def shifted(addr, hook_addr, n=N):
    return addr + n if hook_addr <= addr < END5 else addr


def check_hook5(k, A, SA, LA):
    """вставка N байт в точку k страницы 5"""
    B, SB, _ = sjasm('b%d' % k, ['-DRELOCN=%d' % N, '-DRELOCW=%d' % k])[0:3]
    H = SB['RELOCHOOK']
    bad = []
    stat = {'abs': 0, 'rel': 0}
    for p in range(8):
        base = 0x4000 if p == 5 else 0x8000 if p == 2 else 0xC000
        a, b = A[p], B[p]
        i = 0
        while i < 16384:
            addr = base + i
            j = i + N if (p == 5 and H <= addr < END5) else i
            if j >= 16384:
                i += 1; continue
            if a[i] == b[j]:
                i += 1; continue
            # слово с началом в i-1 или i
            ok = False
            for s in (i - 1, i):
                if s < 0 or s + 1 >= 16384 or j - (i - s) + 1 >= 16384: continue
                sj = j - (i - s)
                wa = a[s] | a[s + 1] << 8; wb = b[sj] | b[sj + 1] << 8
                if H - 16 <= wa < END5 and wb == wa + N and wa != wb:   # H-16: метка+смещение назад (RESTAB-3) у самой точки
                    stat['abs'] += 1; ok = True; i = s + 2; break
                # относительное слово CALL_ (цель - адрес слова - 2)
                pos_a = base + s
                t_a = (pos_a + 2 + wa) & 0xFFFF
                t_b = (shifted(pos_a, H) + 2 + wb) & 0xFFFF
                if t_b == shifted(t_a, H) and (p == 5 or True) and abs(wb - wa) == N:
                    stat['rel'] += 1; ok = True; i = s + 2; break
            if not ok:
                bad.append((p, addr, a[i], b[j]))
                i += 1
    return H, bad, stat


def literal_operands(L, H, lo, hi):
    """операнды LD/CALL/JP, записанные числом, значение которых лежит в [lo,hi): подозрительные места"""
    res = []
    for fil, ln, a, bs, t in L:
        tt = t.split(';')[0].strip()
        mm = re.match(r'(LD|CALL|JP)\s+(.*)$', tt, re.I)
        if not mm or len(bs) not in (3, 4): continue
        op = mm.group(2)
        ids = [x for x in re.findall(r'[A-Za-z_.][A-Za-z_0-9.]*', op) if x.upper() not in ('A', 'B', 'C', 'D', 'E', 'H', 'L', 'HL', 'DE', 'BC', 'SP', 'IX', 'IY', 'AF', 'NZ', 'Z', 'NC', 'PE', 'PO', 'P', 'M')]
        w = bs[-2] | bs[-1] << 8
        if not ids and lo <= w < hi:
            res.append((fil, ln, a, tt, w))
    return res


def raw_code(L, lo, hi):
    """DEFB/DEFW-строки: последовательности "опкод, слово" со словом в [lo,hi)"""
    runs, cur, prev = [], None, None
    for fil, ln, a, bs, t in L:
        tt = t.split(';')[0].strip()
        if tt == '' and prev is not None: isd = prev
        else: isd = bool(re.match(r'(DEFB|DB|DEFM)\b', tt, re.I))
        prev = isd
        if not bs: continue
        if isd:
            if cur and cur['end'] == a and cur['file'] == fil:
                cur['b'] += bs; cur['end'] = a + len(bs)
            else:
                cur = {'start': a, 'end': a + len(bs), 'b': bytearray(bs), 'file': fil, 'ln': ln}; runs.append(cur)
        else:
            cur = None
    out = []
    for r in runs:
        b = r['b']
        for i in range(len(b) - 2):
            if b[i] in OPS:
                w = b[i + 1] | b[i + 2] << 8
                if lo <= w < hi: out.append((r['file'], r['ln'], r['start'] + i, b[i], w))
    return out


def literal_words(L, lo, hi):
    """DEFW-строки: числа вместо меток в диапазоне [lo,hi)"""
    res = []
    for fil, ln, a, bs, t in L:
        tt = t.split(';')[0].strip()
        m = re.match(r'(DEFW|DW)\s+(.*)$', tt, re.I)
        if not m: continue
        for k, tok in enumerate(x.strip() for x in m.group(2).split(',')):
            if re.fullmatch(r'#[0-9A-Fa-f]+|\d+', tok) and 2 * k + 1 < len(bs):
                w = bs[2 * k] | bs[2 * k + 1] << 8
                if lo <= w < hi and (fil, w) not in OK_WORD: res.append((fil, ln, a + 2 * k, tt[:60], w))
    return res


def lists_check(A, S, H0_changed):
    """записи списков CALL EXE: после MEM6 (стр. 6), MEM7 (стр. 7) цель >= #C000 не должна менять значение при вставке в страницу 0"""
    pg = A[5]
    exe = S['EXE']
    mem = {S['MEM0']: 0, S['MEM1']: 1, S['MEM4']: 4, S['MEM6']: 6, S['MEM7']: 7}
    bad = []
    n = 0
    a = 0x4000
    while a < END5:
        o = a - 0x4000
        if pg[o] == 0xCD and (pg[o + 1] | pg[o + 2] << 8) == exe:
            a += 3
            state = 0
            while True:
                w = pg[a - 0x4000] | pg[a - 0x4000 + 1] << 8
                if w == 0: a += 2; break
                t = (a + 2 + w) & 0xFFFF
                if t in mem: state = mem[t]
                elif t >= 0xC000:
                    n += 1
                    ch = a in H0_changed
                    if (state == 0) != ch:
                        bad.append((a, t, state, 'слово %s при вставке в страницу 0, а цель - в странице %d' % ('изменилось' if ch else 'не изменилось', state)))
                a += 2
                if a >= END5: break
        else:
            a += 1
    return n, bad


def main():
    A, SA, lstA = sjasm('a', ['-DRELOCN=0', '-DRELOCW=999'])
    LA = listing(lstA)
    total_bad = 0
    # --- страница 0 (как раньше): слова-адреса внутри страницы 0 сдвигаются ровно на N
    B0, SB0, _ = sjasm('b0', ['-DRELOCN=16', '-DRELOCW=0'])
    bad, words, i, end = [], 0, 0, 0x4000 - 0x300
    h0 = set()
    while i < end:
        if A[0][i] == B0[0][i + 16]:
            i += 1; continue
        a = A[0][i] | A[0][i + 1] << 8; b = B0[0][i + 16] | B0[0][i + 17] << 8
        if b - a == 16 and a >= 0xC000:
            words += 1; i += 2; continue
        bad.append((0xC000 + i, A[0][i], B0[0][i + 16])); i += 1
    print('страница 0: сдвинутых адресов %d, прочих различий %d' % (words, len(bad)))
    for x in bad[:15]: print('  #%04X: %02X -> %02X' % x)
    total_bad += len(bad)
    # слова страницы 5, изменившиеся при вставке в страницу 0 (ссылки на метки страницы 0)
    ch = set()
    for i in range(0, 0x3C00):
        pass
    for i in range(16383):
        if A[5][i] != B0[5][i]:
            ch.add(0x4000 + i); ch.add(0x4000 + i - 1)
    n, lb = lists_check(A, SA, ch)
    print('списки _start: записей с целью в #C000..: %d, не на той странице: %d' % (n, len(lb)))
    for a, t, st, msg in lb: print('  запись #%04X -> #%04X: %s' % (a, t, msg))
    total_bad += len(lb)
    # --- страница 5
    for k in HOOKS5:
        H, bad, st = check_hook5(k, A, SA, LA)
        print('вставка %d байт в точке %d (#%04X): сдвинуто абсолютных адресов %d, относительных слов %d, не объяснено различий %d' % (N, k, H, st['abs'], st['rel'], len(bad)))
        for p, addr, x, y in bad[:12]: print('  страница %d #%04X: %02X -> %02X' % (p, addr, x, y))
        total_bad += len(bad)
    # --- числа вместо адресов
    lo, hi = 0x4201, END5
    lit = [x for x in literal_operands(LA, 0, lo, hi) if (x[0], x[4]) not in OK_LITERAL]
    print('операнды-числа в диапазоне #%04X..#%04X, не внесённые в OK_LITERAL: %d' % (lo, hi, len(lit)))
    for fil, ln, a, tt, w in lit: print('  %s:%d #%04X %s' % (fil, ln, a, tt))
    total_bad += len(lit)
    rc = raw_code(LA, lo, hi)
    rc = [x for x in rc if (x[0], x[1]) not in OK_RAW and x[0] != 'var.asm' and not (x[0] == 'lih.asm' and 0xCE00 <= x[2] < 0xCF00)]
    print('DEFB-код/данные вида "опкод, адрес" в #%04X..#%04X: %d' % (lo, hi, len(rc)))
    for fil, ln, a, op, w in rc: print('  %s:%d #%04X op=%02X -> #%04X' % (fil, ln, a, op, w))
    total_bad += len(rc)
    lw = literal_words(LA, lo, hi)
    print('DEFW с числом вместо метки в #%04X..#%04X: %d' % (lo, hi, len(lw)))
    for fil, ln, a, tt, w in lw: print('  %s:%d #%04X %s' % (fil, ln, a, tt))
    total_bad += len(lw)
    print('ИТОГО замечаний: %d' % total_bad)
    return 1 if total_bad else 0


if __name__ == '__main__':
    sys.exit(main())
