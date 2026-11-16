#!/usr/bin/env python3
"""Z80 snapshot (v2/v3, 128K) reader: pages() -> {ram page 0..7: 16384 bytes}; symbols of ASM80 listing (4.LST)."""
import re
import struct


def decomp(b, n=16384):
    out = bytearray()
    i = 0
    while i < len(b) and len(out) < n:
        if b[i] == 0xED and i + 3 < len(b) + 0 and b[i + 1] == 0xED:
            c, v = b[i + 2], b[i + 3]
            out += bytes([v]) * c
            i += 4
        else:
            out.append(b[i])
            i += 1
    return bytes(out)


def read(path):
    d = open(path, 'rb').read()
    h = d[:30]
    ext = struct.unpack('<H', d[30:32])[0]
    e = d[32:32 + ext]
    info = {'pc': struct.unpack('<H', e[0:2])[0], 'hw': e[2], 'p7ffd': e[3], 'i': h[10], 'raw': h, 'ext': e}
    p = 32 + ext
    pages = {}
    while p < len(d):
        ln, pg = struct.unpack('<HB', d[p:p + 3])
        blk = d[p + 3:p + 3 + (16384 if ln == 0xFFFF else ln)]
        pages[pg - 3] = bytes(blk) if ln == 0xFFFF else decomp(blk)
        p += 3 + (16384 if ln == 0xFFFF else ln)
    return info, pages


def symbols(lst):
    t = open(lst, 'rb').read().decode('cp866').splitlines()
    i = [k for k, l in enumerate(t) if 'ТАБЛИЦА СИМВОЛОВ' in l][0]
    s = {}
    for l in t[i + 1:]:
        m = re.match(r'(?:UNUSED|\s|GLOBAL)*\s*(\S+)\s+(#[0-9A-F]+)\s+(\d+)\s+(.*?)\s*$', l)
        if m:
            s[m.group(1)] = (int(m.group(3)), m.group(4))
    return s
