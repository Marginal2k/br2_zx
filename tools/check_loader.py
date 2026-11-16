#!/usr/bin/env python3
"""Проверка пересечений загрузчика (как check_loader в ЧВ1): для каждого шага загрузки игры (bGAME, src/start1/loader.asm) проверяется,
что читаемый файл (буфер), распаковываемый результат, код загрузчика и его стек не затирают друг друга и что чтение не заходит в
системные переменные TR-DOS (#5C00-#5CFF).  Размеры берутся из последней сборки (build/br2_game.trd): python tools/check_loader.py"""
import os, re, struct, sys
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
d = open(os.path.join(ROOT, 'build', 'br2_game.trd'), 'rb').read()
files = {}
for i in range(128):
    e = d[i * 16:i * 16 + 16]
    if e[0] == 0:
        break
    files[e[:8].decode('latin1').strip()] = (e[14] + 16 * e[15], e[13], int.from_bytes(e[11:13], 'little'))
src = open(os.path.join(ROOT, 'src', 'start1', 'loader.asm'), encoding='utf-8').read()
LOADER = 0x6000
ldr_len = os.path.getsize(os.path.join(ROOT, 'build', 'loader', 'loader.bin'))
BUF1, BUF2 = 0x8000, LOADER + 0x600
SP_TOP = LOADER + 0x5FE
bad = 0


def blk(name):                 # размер упакованного блока (слово длины + поток) в секторах
    s, n, ln = files[name]
    return n * 256


def check(step, buf, nbytes, dest, dlen):
    global bad
    rng = [('файл', buf, buf + nbytes), ('результат', dest, dest + dlen)]
    for nm, a, b in rng:
        for nm2, a2, b2, ok in (('загрузчик', LOADER, LOADER + ldr_len, False), ('стек', SP_TOP - 64, SP_TOP, False), ('сист.пер. TR-DOS', 0x5C00, 0x5D00, False)):
            if a < b2 and a2 < b and not (nm == 'результат' and dest >= 0xC000):
                print('ОШИБКА %-24s %s #%04X-#%04X пересекает %s' % (step, nm, a, b, nm2)); bad += 1
    print('ok     %-24s файл #%04X+%d -> #%04X+%d' % (step, buf, nbytes, dest, dlen))


for name, buf, dest, dlen in (('g_pg1', BUF1, 0xC000, 0x4000), ('g_pg7', BUF1, 0xC000, 0x4000), ('g_pg6', BUF1, 0xC000, 0x4000),
                              ('g_pg3', BUF1, 0xC000, 0x4000), ('g_pg4', BUF1, 0xC000, 0x4000), ('g_pg0', BUF1, 0xC000, 0x4000),
                              ('g_pg5a', BUF2, 0x8000, 0x2000), ('g_pg5b', BUF2, 0xA000, 0x2000)):
    n = blk(name)
    if buf + n > (0xC000 if buf == BUF1 else 0x10000):
        print('ОШИБКА %s: файл %d байт не помещается в буфер' % (name, n)); bad += 1
    check(name, buf, n, dest, dlen)
if SP_TOP - 64 < LOADER + ldr_len:
    print('ОШИБКА: стек загрузчика заходит на его код (%d байт)' % ldr_len); bad += 1
print('загрузчик #6000-#%04X, стек до #%04X, BUF2 #%04X' % (LOADER + ldr_len, SP_TOP, BUF2))
print('ПРОВЕРКА', 'НЕ ПРОЙДЕНА (%d)' % bad if bad else 'ПРОЙДЕНА')
sys.exit(1 if bad else 0)
