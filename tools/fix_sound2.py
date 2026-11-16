#!/usr/bin/env python3
"""The GS interface of 4_SOUND2 (#EB22-#EC76 of page 6) in v0.04 is new code (4.Z80 had other code there); the generator only sees opaque
bytes, here it is written as source (SOUNDgs, setGSvar, loadGS, setGS) with symbolic operands.   python tools/fix_sound2.py work/src_v04/game"""
import os, sys
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
T = chr(9)


def main(tree):
    b = open(os.path.join(ROOT, 'work', 'v04', 'br2hum04.6.bin'), 'rb').read()
    ad = os.path.join(ROOT, 'work', 'assets_v04', 'hum')
    open(os.path.join(ad, '6_junk_EBC9.bin'), 'wb').write(b[0xEBC9 - 0xC000:0xEC77 - 0xC000])
    tab = b[0xEB22 - 0xC000:0xEB51 - 0xC000]
    L = ['; ---- v0.04: the last sound effects and the GS interface of 4_SOUND2 (4.Z80 had other code here)']
    for i in range(0, len(tab), 16):
        L.append(T + 'DEFB' + T + ','.join('#%02X' % x for x in tab[i:i + 16]))
    def I(*x):
        return [T + y for y in x]
    L += ['', 'SOUNDgs', T + '; GS: sound C of the object IX: only when its cell is seen (map bit 7 = 0); the volume comes from the distance to the screen centre']
    L += I('CALL' + T + 'HL_IX0', 'CALL' + T + 'GMAP', 'BIT' + T + '7,(HL)', 'RET' + T + 'NZ', 'LD' + T + 'HL,(X0)', 'LD' + T + 'A,L', 'ADD' + T + 'A,6', 'LD' + T + 'L,A', 'LD' + T + 'A,H', 'ADD' + T + 'A,7', 'LD' + T + 'H,A',
           'CALL' + T + 'DIST2', 'LD' + T + 'E,A', 'LD' + T + 'A,D', 'JP' + T + 'GS_EFF')
    L += ['', 'setGSvar' + T + '; copy the game settings into the variables of the GS driver (GS_VAR...)']
    L += I('LD' + T + 'DE,GS_VAR', 'LD' + T + 'A,(isGS)', 'LD' + T + '(DE),A', 'INC' + T + 'DE', 'LD' + T + 'A,(SAVDSK+2)', 'LD' + T + '(DE),A', 'INC' + T + 'DE',
           'LD' + T + 'A,(MUSONF)', 'LD' + T + '(DE),A', 'INC' + T + 'DE', 'LD' + T + 'A,(MASTER)', 'OR' + T + 'A', 'JR' + T + 'Z,sgs1', 'LD' + T + 'A,#80')
    L += ['sgs1' + T + 'LD' + T + 'HL,LEVEL']
    L += I('ADD' + T + 'A,(HL)', 'LD' + T + '(DE),A', 'INC' + T + 'DE', 'LD' + T + 'A,(DSK_GS)', 'LD' + T + '(DE),A', 'INC' + T + 'DE', 'LD' + T + 'A,(PMOUSE+1)', 'LD' + T + '(DE),A', 'INC' + T + 'DE',
           'LD' + T + 'A,(MUSONF+1)', 'LD' + T + '(DE),A', 'INC' + T + 'DE', 'LD' + T + 'A,(SAVDSK+1)', 'LD' + T + '(DE),A', 'RET')
    L += ['', 'loadGS' + T + '; GS: variables + function 3 (load), then like setGS from sgs2']
    L += I('CALL' + T + 'setGSvar', 'LD' + T + 'A,3', 'CALL' + T + 'GS_FUN', 'JR' + T + 'sgs2')
    L += ['setGS' + T + '; GS: variables + function 2, then toggling the two flags of the driver', T + 'CALL' + T + 'setGSvar', 'sgs2' + T + 'LD' + T + 'A,2']
    L += I('CALL' + T + 'GS_FUN', 'LD' + T + 'A,(GS_VAR+2)', 'XOR' + T + '1', 'CALL' + T + 'GS_FUN', 'LD' + T + 'A,(GS_VAR+6)', 'XOR' + T + '1', 'ADD' + T + 'A,4', 'JP' + T + 'GS_FUN')
    L += ['; remains of the old code (nobody calls them) up to the music module',
          T + 'INCBIN' + T + '"hum/6_junk_EBC9.bin"' + T + '; 174 bytes up to WMUSIC',
          ]
    # the 4 bytes at #EBC5 in the hum image
    L.insert(len(L) - 2, T + 'IFDEF' + T + 'KUN')
    L.insert(len(L) - 2, T + 'DEFB' + T + '#20,#13,#36,#06' + T + '; Kunge image: other remains of the old code')
    L.insert(len(L) - 2, T + 'ELSE')
    L.insert(len(L) - 2, T + 'DEFB' + T + ','.join('#%02X' % x for x in b[0xEBC5 - 0xC000:0xEBC9 - 0xC000]))
    L.insert(len(L) - 2, T + 'ENDIF')
    p = os.path.join(tree, 'sound2.asm')
    s = open(p, encoding='utf-8').read()
    a = s.index('; ---- v0.04: changed/new code or data (4.Z80: (центр экр)')
    e = s.index(chr(10) + ';---------работа с GS-------')
    s = s[:a] + chr(10).join(L) + chr(10) + s[e:]
    for old, new in (('SOUNDgs ;играть звук C (IX+0,IX+1 - коорд источника)' + chr(10), '; SOUNDgs: see above' + chr(10)),
                     ('setGSvar ;установить GS-переменные' + chr(10) + 'sgs1' + T + '; (removed in v0.04; label kept for references)' + chr(10), ''),
                     ('sgs2' + T + '; (removed in v0.04; label kept for references)' + chr(10), '')):
        assert old in s, old
        s = s.replace(old, new, 1)
    open(p, 'w', encoding='utf-8', newline=chr(10)).write(s)


if __name__ == '__main__':
    main(sys.argv[1])
