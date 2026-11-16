; корень сборки концовки: файл 14 диска 1 (код и данные #6F00..#BFFF) и файл 15 (страница 1: картинки и музыка победы, LPZ)
	DEVICE ZXSPECTRUM128
	INCLUDE "final.asm"
FINALEND
	SAVEBIN "b00.bin",#6F00,#C000-#6F00
	MMU 3,1
	SAVEBIN "b01.bin",#C000,FINALEND-#C000
