; Black Raven 2 (demo), ASM80 -> sjasmplus. Root of the faithful build: 4.A80 -> *F 4MAIN
	DEVICE ZXSPECTRUM128
	INCLUDE "defr.inc"
; sjasmplus' ZXSPECTRUM128 device starts with ROM-font junk in the tail of page 0: clear every page first
	ORG #4000
	DS #8000,0
	DUP 8,pgn
	MMU 3,pgn
	ORG #C000
	DS #4000,0
	EDUP
	INCLUDE "undefined.inc"
	INCLUDE "main.asm"
	MMU 3,0
	SAVEBIN "page0.bin",#C000,#4000
	SAVEBIN "page5.bin",#4000,#4000
	SAVEBIN "page2.bin",#8000,#4000
	MMU 3,1
	SAVEBIN "page1.bin",#C000,#4000
	MMU 3,3
	SAVEBIN "page3.bin",#C000,#4000
	MMU 3,4
	SAVEBIN "page4.bin",#C000,#4000
	MMU 3,6
	SAVEBIN "page6.bin",#C000,#4000
	MMU 3,7
	SAVEBIN "page7.bin",#C000,#4000
