; ---- v0.04 heroSprites3 (30448 bytes at #C000): probably: page 3: sprite sets of the heroes/vehicles (fireman, flyhome, intr, shuttle, stinger, walker, kunge ...): files 4*.dat of the archive + 5 sets that changed in v0.04
hrh4
	INCBIN	"data/hero/4fireman.dat"	; byte-identical to the archive file
hrm23
	INCBIN	"data/hero/4flyhome.dat"	; byte-identical to the archive file
hrh10
	INCBIN	"data/hero/4intr.dat"	; byte-identical to the archive file
hrh7
	INCBIN	"hum/hrh7.bin"	; 960 bytes of the v0.04 image (no archive file for them)
	INCBIN	"hum/3_r0_D270.bin"	; 576 bytes of the v0.04 image (no archive file for them)
hrh8
	INCBIN	"hum/hrh8.bin"	; 960 bytes of the v0.04 image (no archive file for them)
	INCBIN	"hum/3_r0_D870.bin"	; 576 bytes of the v0.04 image (no archive file for them)
hrm15
	INCBIN	"data/hero/4kunge.dat"	; byte-identical to the archive file
hrh11
	INCBIN	"data/hero/4shutl.dat"	; byte-identical to the archive file
hrh6
	INCBIN	"data/hero/4stinger.dat"	; byte-identical to the archive file
hrh5
	INCBIN	"data/hero/4walker.dat"	; byte-identical to the archive file
hrm20
	INCBIN	"hum/hrm20.bin"	; 960 bytes of the v0.04 image (no archive file for them)
	INCBIN	"hum/3_r0_F770.bin"	; 576 bytes of the v0.04 image (no archive file for them)
hrm18
	INCBIN	"hum/hrm18.bin"	; 1616 bytes of the v0.04 image (no archive file for them)
;этот файл должен быть первым в странице

invTAB ;табл зеркальных.байт	(256) (**)
;
invSUB ;постр табл инв байтов для монстров (эта п/п будет затёрта) (**)
;
invBUF	EQU	invSUB+2 ;буфер зеркальных отображений (64) (**)

;выв спрайтов 2х2 с зеркальным отображением
;
;
;
;инвертирование
inVLOO ;цикл инвертирования
;

