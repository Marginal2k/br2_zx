"""Read TR-DOS .trd / .scl containers -> [(name, type, start, length, data)]"""
import struct
def scl(p):
    d=open(p,'rb').read(); n=d[8]; pos=9+14*n; out=[]
    for i in range(n):
        e=d[9+14*i:23+14*i]; sec=e[13]; ln=struct.unpack('<H',e[11:13])[0]
        out.append((e[:8].decode('cp866','replace').rstrip(),chr(e[8]),struct.unpack('<H',e[9:11])[0],ln,d[pos:pos+sec*256][:ln] if e[8] not in (0x42,) else d[pos:pos+sec*256])); pos+=sec*256
    return out
def trd(p):
    d=open(p,'rb').read(); out=[]
    for i in range(128):
        e=d[i*16:i*16+16]
        if e[0]==0: break
        if e[0]==1: continue
        sec=e[13]; off=(e[15]*16+e[14])*256; ln=struct.unpack('<H',e[11:13])[0]
        out.append((e[:8].decode('cp866','replace').rstrip(),chr(e[8]),struct.unpack('<H',e[9:11])[0],ln,d[off:off+sec*256]))
    return out
def load(p): return scl(p) if p.lower().endswith('.scl') else trd(p)
