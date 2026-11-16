; корень сборки загрузчика (sjasmplus)
	DEVICE ZXSPECTRUM128
	INCLUDE "loader.asm"
LDREND
	SAVEBIN "loader.bin",LOADER,LDREND-LOADER
