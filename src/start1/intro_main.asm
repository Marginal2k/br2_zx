; корень сборки диска 1 (INTRO): загрузчик #6000.., интро + инструкция (B01ORG..), страницы 1, 3, 4, 6, 7 (файлы LP2..LP5, заставка)
	DEVICE ZXSPECTRUM128
B01ORG	EQU	#6600
	INCLUDE "loader.asm"
LDREND
	ORG	B01ORG
	INCLUDE "b01head.asm"
	INCLUDE "intro.asm"
	INCLUDE "instr.asm"
	NOP
B01END
	MMU 3,1
	ORG	#C000
J38m
	INCBIN "music/j38fc.lpz"
GIMNm
	INCBIN "music/jam_gimn.lpz"
GIMNs
	INCBIN "pictures/4_ussr.lpz"
	DEFS	57000-$,#D0
fMUS
	INCBIN "music/lfantc.mus"
P1END
	MMU 3,3
	ORG	#C000
	INCBIN "data/4introf0.dat"
P3END
	MMU 3,4
	ORG	#C000
	INCBIN "data/4introf1.dat"
P4END
	MMU 3,6
	ORG	#C000
	DISP	#7000
	INCLUDE "tv16.asm"
	ENT
	DEFW	$
P6END
	MMU 3,7
	ORG	#DB00
SWORD
	INCBIN "pictures/4title.lpz"
P7END
	MMU 3,0
	SAVEBIN "loader.bin",LOADER,LDREND-LOADER
	SAVEBIN "b01.bin",B01ORG,B01END-B01ORG
	MMU 3,1
	SAVEBIN "p1.bin",#C000,P1END-#C000
	MMU 3,3
	SAVEBIN "p3.bin",#C000,P3END-#C000
	MMU 3,4
	SAVEBIN "p4.bin",#C000,P4END-#C000
	MMU 3,6
	SAVEBIN "p6.bin",#C000,#4000
	MMU 3,7
	SAVEBIN "p7.bin",#DB00,P7END-#DB00
