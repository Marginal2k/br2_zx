#!/bin/sh
# Regenerates work/src_v04/game (the HUM-exact, symbolic tree) from game_orig + the v0.04 hum image, then cleans it.
set -e
cd "$(dirname "$0")/.."
python -I tools/mkv04_symgen.py hum --final > build/v04/sym_hum.log 2>&1
rm -rf work/src_v04/game && cp -r work/src_v04/hum work/src_v04/game && rm -rf work/src_v04/hum
python -I tools/symbolize_consts.py work/src_v04/game
python - <<'PY'
p='work/src_v04/game/main.asm'
s=open(p,encoding='utf-8').read()
if 'STKTOP\tEQU' not in s:
    s=s.replace("\tORG\t#4000\n","\tORG\t#4000\nSTKTOP\tEQU\t#403E\t; top of the stack: the 31 words below the IM2 jump #4040\n",1)
open(p,'w',encoding='utf-8',newline='\n').write(s)
PY
python -I tools/defb_junk.py work/src_v04/game hum
python -I tools/fix_sound2.py work/src_v04/game
python -I tools/verify_v04.py hum
