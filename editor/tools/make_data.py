#!/usr/bin/env python3
"""Данные веб-редактора BR2 -> editor/data/br2data.js.   python -I editor/tools/make_data.py

Источники (только чтение): archive/unz/BR2_DEMO/MAP (*.MAP, *.HER), assets/data (ландшафты 41..45SPR,
спрайты героев hero/*.dat, 4misc2x2.dat, шрифт 4font.fnt), archive/.../TASK (*.TSK, *.TS2).
Спрайты героев и предметов приводятся так же, как это делает MAPPER (GAMELOOP.CPP, load_img/conv/conv_obj):
  герой  - 2 столбца по 16 строк пар байт (маска, маска^рисунок); берётся начало листа по правилу из styp (код '2','3','4','x','z');
  предмет - спрайт 2x2 из 4misc2x2.dat с номерами objtyp = 21,22,23,26,29,30,31.
"""
import base64, glob, json, os, sys

ED = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROOT = os.path.dirname(ED)
MAPD = os.path.join(ROOT, 'archive', 'unz', 'BR2_DEMO', 'MAP')
TASKD = os.path.join(ROOT, 'archive', 'unz', 'BR2_DEMO', 'TASK')
AD = os.path.join(ROOT, 'assets', 'data')

# GAMELOOP.CPP: styp[] (файл, код выбора) в порядке типов 0..23
STYP = [('4worker', '2'), ('4worker', 'x'), ('4worker', 'z'), ('4soldier', '2'), ('4fireman', '2'), ('4walker', '3'), ('4stinger', '3'),
        ('4kapell', '2'), ('4king', '2'), ('4tank_tr', '4'), ('4intr', '4'), ('4shutl', '4'), ('4peon', '2'), ('4peon', 'x'), ('4peon', 'z'),
        ('4kunge', '2'), ('4krakotn', '2'), ('4demon', '3'), ('4zenit', '2'), ('4varlok', '2'), ('4zerg', '2'), ('4fly_tnk', '4'),
        ('4fighter', '4'), ('4flyhome', '4')]
SEL = {'2': (0, 0), '3': (0, 16), '4': (16, 16), 'x': (512 * 2 + 64, 0), 'z': (512 * 3 + 64, 0)}
OBJTYP = [21, 22, 23, 26, 29, 30, 31]


def b64(b):
    return base64.b64encode(bytes(b)).decode('ascii')


def conv(buf, start, ndx):
    """-> (маска 32 байта, рисунок 32 байта): [столбец][строка]; рисунок = adr[0]^adr[1], как conv() в MAPPER"""
    mask, img, adr = bytearray(), bytearray(), start
    for _ in range(2):
        for _ in range(16):
            mask.append(buf[adr])
            img.append(buf[adr] ^ buf[adr + 1])
            adr += 2
        adr += ndx
    return bytes(mask), bytes(img)


def main():
    for st in (sys.stdout, sys.stderr):
        st.reconfigure(encoding='utf-8', errors='replace')
    rd = lambda p: open(p, 'rb').read()
    levels = []
    for f in sorted(glob.glob(os.path.join(MAPD, '*.MAP')), key=lambda p: int(os.path.basename(p)[2:-4])):
        n = os.path.basename(f)[:-4]
        levels.append(dict(name=n, src='MAP', map=b64(rd(f)), her=b64(rd(f[:-3] + 'HER'))))
    # 4_MAP.ZIP (4_0, 40_S1, 4301_S1 и старые версии) - другой, более ранний формат .HER (типы до 124): не встраивается, см. README
    data = {
        'levels': levels,
        'land': {str(n): b64(rd(os.path.join(AD, '4%dspr.dat' % n))) for n in range(1, 6)},
        'font': b64(rd(os.path.join(AD, '4font.fnt'))),
        # MPsign: номер клетки -> смещение значка 3x3 в MP_IMG (src/game/map.asm), по ландшафту 41..45SPR
        'mps': {str(n): b64(rd(os.path.join(AD, '4num_m%d.bin' % n))) for n in range(1, 6)},
        'tasks': [dict(name=os.path.basename(f)[:-4], tsk=b64(rd(f)), ts2=b64(rd(f[:-3] + 'TS2')))
                  for f in sorted(glob.glob(os.path.join(TASKD, '*.TSK')))],
    }
    heroes = []
    for f, s in STYP:
        buf = rd(os.path.join(AD, 'hero', f + '.dat')).ljust(2048, b'\0')
        m, i = conv(buf, *SEL[s])
        heroes.append(dict(mask=b64(m), img=b64(i)))
    data['heroes'] = heroes
    misc = rd(os.path.join(AD, '4misc2x2.dat')).ljust(512 * 8, b'\0')
    objs = []
    for o in OBJTYP:
        m, i = conv(misc, o * 64, 0)
        objs.append(dict(mask=b64(m), img=b64(i)))
    data['objects'] = objs
    out = os.path.join(ED, 'data', 'br2data.js')
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, 'w', encoding='utf-8', newline='\n') as f:
        f.write('// создано editor/tools/make_data.py - не править вручную\nwindow.BR2_DATA = ')
        json.dump(data, f, ensure_ascii=False, separators=(',', ':'))
        f.write(';\n')
    print('записан', out, os.path.getsize(out), 'байт; уровней', len(levels), [l['name'] for l in levels])


if __name__ == '__main__':
    main()
