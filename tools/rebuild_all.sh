#!/bin/sh
# Regenerates the single tree work/src_v04/game: Human campaign from game_orig + the hum image, Kunge data under IFDEF KUN, then names.
set -e
cd "$(dirname "$0")/.."
sh tools/rebuild_game.sh > build/v04/rebuild_hum.log 2>&1
python -I tools/mk_kun_level.py
python -I tools/mkv04_symgen.py kun --final --base work/src_v04/game > build/v04/sym_kun.log 2>&1
rm -rf work/src_v04/game && mv work/src_v04/kun_ifdef work/src_v04/game
python -I tools/fix_kun_post.py work/src_v04/game
python -I tools/localize_labels.py work/src_v04/game
python -I tools/frag_list.py > /dev/null
python -I tools/name_frags.py work/src_v04/game
python -I tools/verify_v04.py
python -I tools/check_reloc.py hum 16 | tail -3
python -I tools/check_reloc.py kun 16 | tail -3
