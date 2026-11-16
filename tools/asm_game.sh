#!/bin/sh
# сборка игры для проверки: tools/asm_game.sh [-Dxxx] ; результат build/g
cd "$(dirname "$0")/.."
mkdir -p build/g
cd build/g
sjasmplus --nologo --msg=err --lst=main.lst --sym=main.sym -I ../../src/game -I ../../src/lib -I ../../assets -I . "$@" ../../src/game/game.asm
