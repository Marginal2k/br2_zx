#!/usr/bin/env python3
"""Names and one-line descriptions of the new fragments of v0.04 that are >= 32 bytes (headers '; ---- v0.04: ...'); renames of the global v4_* labels.
Applied to work/src_v04/game after the generation (rebuild_all.sh).   python tools/name_frags.py work/src_v04/game"""
import json, os, re, sys
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
NL = chr(10)
# (file, first label of the fragment or its address) -> description (the header text after "v0.04 NAME:")
DESC = {
    ('lib2x2i.asm', 0xC000): ('heroSprites3', 'page 3: sprite sets of the heroes/vehicles (fireman, flyhome, intr, shuttle, stinger, walker, kunge ...): files 4*.dat of the archive + 5 sets that changed in v0.04'),
    ('lib3.asm', 0xCD75): ('heroSprites4', 'page 4: sprite sets of the heroes (fighter, fly_tnk, demon ...) + the GS sound-effect call pSOUND'),
    ('protec.asm', 0x5B3A): ('protectDELPZ', 'DELPZ (LPZ unpacker), the protection / key-disk block (W200, number of tries) as of v0.04: image bytes'),
    ('main.asm', 0xF780): ('WNAMES', 'page 1: table of the building/unit names (WNAMES, 1890 bytes, text with the 4FONT codes)'),
    ('lih.asm', 0xE05A): ('mmfScan', 'second half of the map-cell filter mmf0: sight/passability tests of the cells (isRUNL, hPARM, searcB) writing the allowed cells of the unit'),
    ('lih.asm', 0xDA9E): ('menuWindow', 'in-game menu window drawing (dMN_WD), aMONEY/aMAZUT: add to the money / fuel counters (BCD) and the helpers of the menu text (spc_DO)'),
    ('var.asm', 0x7462): ('gameVars', 'variables of the game (GBAD1 ... Yh): initial values of v0.04 (assembler fill in the places marked DEFR)'),
    ('main.asm', 0x42B3): ('sysTimers', 'SLOWER (delay when SLOW is on), ANIMTR (animation counter, 4 phases), SQROUT: system settings/timers block'),
    ('lif.asm', 0xED2C): ('zzMove', 'zzTo1: the unit moves one step towards its target (random pauses, speed limit from IX+6, 3 directions)'),
    ('lih.asm', 0xD8E0): ('aviaShot', 'IXA3x1/ixa3P: shot delay of the aircraft (image bytes, the 4.Z80 code was removed)'),
    ('main.asm', 0xC000): ('bullFlameTabs', 'page 4: WYbull/vbuXDW/vFLAME: bullet and flame y-tables and drawing code'),
    ('map.asm', 0xC4CC): ('mapSpecials', 'LOADMM part: random set-up of isDIVMAP/pntX (the "diversion" points of the level)'),
    ('lih.asm', 0xE63A): ('mmf2Pick', 'mmf2: choose the nearest target of the group (DIST2, DEFENC+48 table, type limits)'),
    ('lih.asm', 0xDF9D): ('mmf0Cells', 'mmf0: the cells near the unit that it may use (HBUILD/KBUILD lookups)'),
    ('lik1.asm', 0xF955): ('onsee', 'onsee/ONSEEm/onsee2: the unit opens the fog around itself: clears bit 7 of the 5x5 map cells (sight radius from DEFENC)'),
    ('map.asm', 0xC000): ('(removed)', 'code of 4.Z80 that does not exist in v0.04'),
    ('lih.asm', 0xE563): ('mmfon', 'mmfon: group move: sends every unit of the group (loop with IXt_HL / IX_mov) to the cell, state IX+13 = 2'),
    ('lih.asm', 0xDF41): ('MINEoff', 'MINEoff/MINEo_: switch the mine danger for the enemy on/off in the BUT_N table of the cells (CALL BA)'),
    ('lig.asm', 0xF18B): ('selWindow', 'dzp0 helpers: screen corners of the selection window from diXSEL/diYSEL, BMX, X0/Y0 (selFrameCorners, selCoord), oneSEL'),
    ('lih.asm', 0xE5C0): ('mmfonFar', 'mmfon continuation: the nearest free cell search for the group (DIST2, B_IX)'),
    ('lie.asm', 0xF564): ('TU_text', 'texts TU_3/TU_4 of the level end statistics (font codes of 4FONT: "Время", "Общее")'),
    ('map.asm', 0xC9F1): ('esmmEnemy', 'esmm_: the enemy units are set up at the start (IX+13/IX+4 state per type)'),
    ('lih.asm', 0xE618): ('mmf2Near', 'mmf2: loop over the cells: keep the nearest (DIST2) unit in D/E'),
}
UNSURE = {'mmfScan', 'mmf0Cells', 'mmf2Pick', 'mmf2Near', 'mmfonFar', 'esmmEnemy', 'mapSpecials', 'zzMove', 'bullFlameTabs', 'sysTimers', 'menuWindow', 'aviaShot', 'protectDELPZ', 'heroSprites4', 'heroSprites3', 'gameVars'}
RENAME = {'v4_aMAZUT_1': 'addBCD', 'v4_dzp0_1': 'selFrameCorners', 'v4_dzp0_2': 'selCoord'}


def main(tree):
    r = json.load(open(os.path.join(ROOT, 'build', 'v04', 'frag_list.json'), encoding='utf-8'))
    byfile = {}
    for x in r:
        if x['bytes'] >= 32 and (x['file'], x['addr']) in DESC:
            byfile.setdefault(x['file'], []).append(x)
    n = 0
    for fn, xs in byfile.items():
        p = os.path.join(tree, fn)
        L = open(p, encoding='utf-8').read().split(NL)
        for x in sorted(xs, key=lambda x: -x['line']):
            nm, d = DESC[(fn, x['addr'])]
            if nm in UNSURE:
                d = 'probably: ' + d
            i = x['line'] - 1
            if not L[i].startswith('; ---- v0.04'):
                continue
            old = L[i][len('; ---- v0.04: '):]
            L[i] = '; ---- v0.04 %s (%d bytes at #%04X): %s' % (nm, x['bytes'], x['addr'], d)
            n += 1
        open(p, 'w', encoding='utf-8', newline=NL).write(NL.join(L))
    for fn in os.listdir(tree):
        if fn.endswith('.asm'):
            p = os.path.join(tree, fn)
            s = open(p, encoding='utf-8').read()
            s2 = s
            for a, b in RENAME.items():
                s2 = re.sub(r'(?<![A-Za-z0-9_.])' + a + r'(?![A-Za-z0-9_])', b, s2)
            if s2 != s:
                open(p, 'w', encoding='utf-8', newline=NL).write(s2)
    print('headers described:', n)


if __name__ == '__main__':
    main(sys.argv[1])
