#!/usr/bin/env python3
"""SCL -> TRD (для эталонных проверок в эмуляторе): python tools/scl2trd.py in.scl out.trd [имя_boot]  (файл с таким именем получает имя boot)"""
import struct, sys
sys.path.insert(0, __file__.rsplit('tools', 1)[0] + 'tools')
from trd import Trd, SPT
d = open(sys.argv[1], 'rb').read()
boot = (sys.argv[3] if len(sys.argv) > 3 else '').ljust(8)
n = d[8]
ents = [d[9 + i * 14:9 + (i + 1) * 14] for i in range(n)]
pos = 9 + n * 14
t = Trd(label='REF', tracks=160)
for e in ents:
    name, typ, start, length, secs = e[:8], chr(e[8]), struct.unpack('<H', e[9:11])[0], struct.unpack('<H', e[11:13])[0], e[13]
    data = d[pos:pos + secs * 256]
    pos += secs * 256
    nm = 'boot' if name.decode('latin1') == boot else name.decode('latin1').strip()
    s = t.alloc(secs)
    t.img[s * 256:s * 256 + len(data)] = data
    t.files.append(nm.encode('latin1').ljust(8) + bytes([e[8]]) + struct.pack('<HH', start, length) + bytes([secs, s % SPT, s // SPT]))
t.save(sys.argv[2])
print(n, 'files')
