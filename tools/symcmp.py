import sys,os,re; sys.path.insert(0,os.path.dirname(__file__))
import z80snap as z
A='archive/unz/BR2_DEMO/ASM80/'
S=z.symbols(A+'4.LST')
mine={}
for l in open(sys.argv[1] if len(sys.argv)>1 else 'build/faithful/game/main.sym'):
    m=re.match(r'(\S+):\s*EQU 0x([0-9A-F]+)',l) or re.match(r'(\S+)\s*:?\s*equ\s*0x([0-9A-Fa-f]+)',l,re.I)
    if m: mine[m.group(1)]=int(m.group(2),16)
print(len(mine),len(S))
bad=[(a,k,mine.get(k)) for k,(a,w) in S.items() if w.startswith(('Main','Pg')) and k in mine and mine[k]!=a]
bad.sort()
print(len(bad)); 
for a,k,m in bad[:15]: print(hex(a),k,hex(m))
missing=[k for k in S if k not in mine and S[k][1].startswith(('Main','Pg'))]
print('missing',missing[:20])
