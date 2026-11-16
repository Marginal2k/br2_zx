#!/usr/bin/env python3
"""Append the data of the Kunge level to work/src_v04/game/level.asm (under IFDEF KUN), symbolically:
   * the map: INCBIN "map/4_4.map" over MAP (the image has the "seen" bit 7 set in many cells: working state, kun_live.txt);
   * datHER: INCBIN "map/4_4.her" (the image has it only before the start of the level: BUF512 is cleared afterwards);
   * the level parameters (hHERO ... fsMUS ...): the bytes that differ from the Human level, as  ORG label+offset / DEFB.
The overlay writes over the Human data (the assembler device is a memory image) and returns to the old address."""
import os, re, sys
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'tools'))
import mkv04 as M
import verify_v04

NL = chr(10)
TAB = chr(9)


def main():
    tree = os.path.join(M.SRC, 'game')
    out = os.path.join(ROOT, 'build', 'v04', 'lvk')
    rc, txt = M.sjasm(tree, out, 'hum')
    sym = {}
    for l in open(os.path.join(out, 'main.sym')):
        m = re.match(r'(\S+):\s*EQU 0x([0-9A-F]+)', l)
        if m:
            sym[m.group(1)] = int(m.group(2), 16)
    Vh = open(os.path.join(ROOT, 'work', 'v04', 'br2hum04.2.bin'), 'rb').read()
    Vk = open(os.path.join(ROOT, 'work', 'v04', 'br2kun04.2.bin'), 'rb').read()
    live = verify_v04.live_ranges('kun')
    labs = sorted((a, n) for n, a in sym.items() if 0xBE50 <= a < 0xC000 and not n.startswith(('_', 'v4_')) and n not in ('BULL',))
    # differing bytes of the parameter block that are not working state
    d = [i for i in range(0xBE50, 0xBF74) if Vh[i - 0x8000] != Vk[i - 0x8000] and (2, i) not in live]
    runs = []
    for i in d:
        if runs and i <= runs[-1][1] + 2:
            runs[-1][1] = i
        else:
            runs.append([i, i])
    lines = ['', '; ================= Kunge campaign: data of the level (the Human data above are overwritten) =================',
             TAB + 'IFDEF' + TAB + 'KUN', '_lvl_end' + TAB + 'EQU' + TAB + '$',
             TAB + 'ORG' + TAB + 'MAP', TAB + 'INCBIN' + TAB + '"map/4_4.map",0,4096' + TAB + '; 4_4.MAP: the map of the Kunge level (bit 7 of the cells = "seen", set while playing: kun_live.txt)',
             TAB + 'ORG' + TAB + 'BUF512+16', TAB + 'INCBIN' + TAB + '"map/4_4.her"' + TAB + '; 4_4.HER: placement of the heroes (the image has lost it: BUF512 is cleared after the start)']
    for a, b in runs:
        base = [x for x in labs if x[0] <= a][-1]
        off = a - base[0]
        data = Vk[a - 0x8000:b - 0x8000 + 1]
        lines.append(TAB + 'ORG' + TAB + (base[1] if off == 0 else '%s+%d' % (base[1], off)))
        lines.append(TAB + 'DEFB' + TAB + ','.join('#%02X' % x for x in data) + TAB + '; Kunge level parameters (Human: ' + ','.join('#%02X' % x for x in Vh[a - 0x8000:b - 0x8000 + 1]) + ')')
    lines += [TAB + 'ORG' + TAB + '_lvl_end', TAB + 'ENDIF']
    p = os.path.join(tree, 'level.asm')
    t = open(p, encoding='utf-8').read()
    if '_lvl_end' in t:
        t = t[:t.index(NL + '; ================= Kunge campaign')]
    open(p, 'w', encoding='utf-8', newline=NL).write(t.rstrip(NL) + NL + NL.join(lines) + NL)
    print('parameter runs:', len(runs), 'bytes', len(d))


if __name__ == '__main__':
    main()
