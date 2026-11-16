import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__)))
import z80snap as z
A='archive/unz/BR2_DEMO/ASM80/'
info,pg=z.read(A+'4.Z80')
B=sys.argv[3] if len(sys.argv)>3 else 'build/faithful/game/'
p=int(sys.argv[1]); n=int(sys.argv[2])
base={5:0x4000,2:0x8000}.get(p,0xC000)
ours=open(B+f'page{p}.bin','rb').read(); ref=pg[p]
d=[i for i in range(16384) if ours[i]!=ref[i]]
runs=[]
for i in d:
    if runs and i<=runs[-1][1]+2: runs[-1][1]=i
    else: runs.append([i,i])
S=z.symbols(A+'4.LST')
inv={}
for k,(a,w) in S.items():
    inv.setdefault(a,[]).append(k)
for a,b in runs[:n]:
    lab=''
    for q in range(base+a,base+a-40,-1):
        if q in inv: lab=f'{inv[q][0]}+{base+a-q}'; break
    print(hex(base+a),b-a+1,'ref',ref[a:b+1][:12].hex(' '),'ours',ours[a:b+1][:12].hex(' '),lab)
