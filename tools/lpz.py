#!/usr/bin/env python3
"""LPZ - the packer XLPZ.EXE of Black Raven (1997); the unpacker is DELPZ in ASM80/XDELPZ.A80 (v3.01).

File:   word N (little endian, = size of the stream), then the stream (N bytes).
Stream: 4 bytes = the LAST four bytes of the unpacked data, then tokens, ended by the byte #00.
Token by the low bits of its first byte b (a literal is stored XORed with the byte that follows it, see below):
  xxxxxxx1          copy: bits 7-5 = number of literals that follow the copy (0..7), bits 4-2 = length-2 (1..7;
                    0 -> the length is the next byte + 2, 2..257), bit 1 = bit 8 of the distance, then the
                    distance low byte.  Length 3..9 (or 2..257), distance 0..511.
  xxxxx110          long copy: bits 7-3 = length-2 (1..31; 0 -> next byte + 2), second byte: bits 7-5 literals
                    that follow (0..7), bits 4-0 = high part of the distance (13 bits in total), third byte (after
                    the optional length byte) = low byte of the distance
  xxxxx010          2 bytes from the distance (b>>3)+1 (1..32)
  llll0100          run: the previous byte repeated (l+2) times (2..17), no literals
  lll d 1100 +byte  run: previous byte repeated ((d<<8 | byte) + 2) times (2..513), lll literals follow
  lllll000          lllll literals (1..31) follow
  00000000          end
Literals: the n-th literal byte of a run is stored as  lit XOR next stream byte  (the byte after the last literal is the
header of the next token, or #00 at the end), i.e. the stream byte at that position is shared with the next header.

    python tools/lpz.py d in.lpz out.bin     python tools/lpz.py c in.bin out.lpz
"""
import struct
import sys


def unpack_stream(s, pos=0):
    """Returns (data, position after the end byte)."""
    tail = s[pos:pos + 4]
    p = pos + 4
    out = bytearray()

    def lits(p, n):
        for i in range(n):
            out.append(s[p + i] ^ s[p + i + 1])
        return p + n

    while True:
        b = s[p]
        if b & 1:                                   # short copy
            nl = b >> 5
            f = (b >> 2) & 7
            hi = (b >> 1) & 1
            p += 1
            if f == 0:
                ln = s[p] + 2
                p += 1
            else:
                ln = f + 2
            dist = (hi << 8) | s[p]
            p += 1
            for _ in range(ln):
                out.append(out[-dist])
            p = lits(p, nl)
        elif b == 0:
            p += 1
            break
        elif (b & 7) == 0:                          # literals
            p = lits(p + 1, b >> 3)
        elif (b & 7) == 2:                          # two bytes
            dist = (b >> 3) + 1
            out.append(out[-dist]); out.append(out[-dist])
            p += 1
        elif (b & 7) == 4:                          # run
            ln = (b >> 4) + 2
            if (b & 8):
                nl = b >> 5
                ln = (((b >> 4) & 1) << 8 | s[p + 1]) + 2
                p += 1
            else:
                nl = 0
            p += 1
            out.extend([out[-1]] * ln)
            p = lits(p, nl)
        else:                                       # (b & 7) == 6, long copy
            f = b >> 3
            b2 = s[p + 1]
            nl = b2 >> 5
            hi = b2 & 0x1F
            p += 2
            if f == 0:
                ln = s[p] + 2
                p += 1
            else:
                ln = f + 2
            dist = (hi << 8) | s[p]
            p += 1
            for _ in range(ln):
                out.append(out[-dist])
            p = lits(p, nl)
    out += tail
    return bytes(out), p


def unpack(f):
    n = struct.unpack_from('<H', f)[0]
    return unpack_stream(f[2:2 + n])[0]


def _matches(body):
    """For every position: best match length with distance <= 31, <= 511 and <= 8191 -> (len, dist)."""
    n = len(body)
    res = [None] * n
    heads = {}
    prev = [-1] * n
    for i in range(n):
        b31 = b511 = b8k = (0, 0)
        if i + 2 <= n:
            key = body[i:i + 2]
            j = heads.get(key, -1)
            tries = 0
            lim = min(257 if True else 0, n - i)
            while j >= 0 and i - j <= 8191 and tries < 400:
                d = i - j
                m = 0
                while m < lim and body[j + m] == body[i + m]:
                    m += 1
                if m >= 2:
                    if m > b8k[0]:
                        b8k = (m, d)
                    if d <= 511 and m > b511[0]:
                        b511 = (m, d)
                    if d <= 31 and m > b31[0]:
                        b31 = (m, d)
                    if m >= lim:
                        break
                j = prev[j]
                tries += 1
            prev[i] = heads.get(key, -1)
            heads[key] = i
        res[i] = (b31, b511, b8k)
    return res


def pack_stream(data):
    assert len(data) >= 4
    body, tail = bytes(data[:-4]), bytes(data[-4:])
    n = len(body)
    M = _matches(body)
    INF = 1 << 60
    cost = [INF] * (n + 1)
    choice = [None] * (n + 1)
    cost[n] = 1                                         # the end byte
    for i in range(n - 1, -1, -1):
        c, ch = INF, None
        for l in range(1, min(31, n - i) + 1):          # literal run
            v = 1 + l + cost[i + l]
            if v < c:
                c, ch = v, ('L', l)
        b31, b511, b8k = M[i]
        # two bytes, distance 1..31 (b31 has the longest match; length 2 is always possible if m >= 2)
        if b31[0] >= 2 and i + 2 <= n:
            v = 1 + cost[i + 2]
            d = b31[1]
            if v < c:
                c, ch = v, ('T', d)
        prev_byte_runs = b31[1] == 1 and b31[0] >= 2

        def tries(cands):
            for (m, d, kind) in cands:
                lens = {m}
                for lim in (9, 33, 17, 257, 513):
                    if m > lim:
                        lens.add(lim)
                lens.update(x for x in (2, 3) if x <= m)
                for ln in lens:
                    yield ln, d, kind

        for (m, d, kind) in ((b511[0], b511[1], 'S'), (b8k[0], b8k[1], 'G')):
            if m < 2:
                continue
            for ln in {m, min(m, 9), min(m, 33), min(m, 257), min(m, 8), min(m, 32), 2, 3}:
                if ln < 2 or ln > m:
                    continue
                # cost of the token itself
                if kind == 'S':
                    base = 2 if 3 <= ln <= 9 else 3
                else:
                    if 3 <= ln <= 33:
                        base = 3
                    else:
                        base = 4
                for nl in range(0, min(7, n - i - ln) + 1):
                    v = base + nl + cost[i + ln + nl]
                    if v < c:
                        c, ch = v, (kind, ln, d, nl)
        if prev_byte_runs or (b31[0] >= 2 and b31[1] == 1):
            m = b31[0]
            for ln in {m, min(m, 17), 2, min(m, 257)}:
                if ln < 2 or ln > m:
                    continue
                if ln <= 17:
                    v = 1 + cost[i + ln]
                    if v < c:
                        c, ch = v, ('R', ln, 0)
                for nl in range(0, min(7, n - i - ln) + 1):
                    v = 2 + nl + cost[i + ln + nl]
                    if v < c:
                        c, ch = v, ('R2', ln, nl)
        cost[i], choice[i] = c, ch
    # build the token list
    toks = []
    i = 0
    while i < n:
        ch = choice[i]
        k = ch[0]
        if k == 'L':
            toks.append(('L', ch[1], 0, 0, i + 0))
            i += ch[1]
        elif k == 'T':
            toks.append(('T', 2, ch[1], 0, i))
            i += 2
        elif k in ('S', 'G'):
            toks.append((k, ch[1], ch[2], ch[3], i))
            i += ch[1] + ch[3]
        elif k == 'R':
            toks.append(('R', ch[1], 1, 0, i))
            i += ch[1]
        else:
            toks.append(('R2', ch[1], 1, ch[2], i))
            i += ch[1] + ch[2]
    # emit from the end
    out = []                                            # reversed list of bytes
    nextb = 0
    out.append(0)
    for kind, ln, d, nl, pos in reversed(toks):
        if kind == 'L':
            lits = body[pos:pos + ln]
            hdr = [ln << 3]
        else:
            lits = body[pos + ln:pos + ln + nl]
            if kind == 'T':
                hdr = [((d - 1) << 3) | 2]
            elif kind == 'R':
                hdr = [(ln - 2) << 4 | 4]
            elif kind == 'R2':
                v = ln - 2
                hdr = [(nl << 5) | ((v >> 8) << 4) | 0xC, v & 255]
            elif kind == 'S':
                hi = d >> 8
                if 3 <= ln <= 9:
                    hdr = [(nl << 5) | ((ln - 2) << 2) | (hi << 1) | 1, d & 255]
                else:
                    hdr = [(nl << 5) | (hi << 1) | 1, ln - 2, d & 255]
            else:
                if 3 <= ln <= 33:
                    hdr = [((ln - 2) << 3) | 6, (nl << 5) | (d >> 8), d & 255]
                else:
                    hdr = [6, (nl << 5) | (d >> 8), ln - 2, d & 255]
        nb = nextb
        enc = []
        for b in reversed(lits):
            nb = b ^ nb
            enc.append(nb)
        # enc is reversed literal stream bytes; the byte after the literals is nextb (not emitted here)
        out.extend(enc)
        out.extend(reversed(hdr))
        nextb = hdr[0]
    # the first token's header is already out; the literal chain of the previous token used nextb of the following
    out.reverse()
    return tail + bytes(out)


def pack(data):
    s = pack_stream(data)
    assert unpack_stream(s)[0] == bytes(data), 'pack/unpack mismatch'
    return struct.pack('<H', len(s)) + s


if __name__ == '__main__':
    mode, a, b = sys.argv[1:4]
    src = open(a, 'rb').read()
    open(b, 'wb').write(unpack(src) if mode == 'd' else pack(src))
