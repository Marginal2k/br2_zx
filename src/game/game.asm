; Чёрный Ворон 2 - игра (одна сборка для людей и кунгов). Корень сборки sjasmplus; страницы 128K сохраняются build.py.
	DEVICE ZXSPECTRUM128
	MACRO RELOC_ where ; проверка перемещаемости (tools/check_reloc.py): -DRELOCN=n -DRELOCW=k вставляет n байт в точке k (0 - начало страницы 0,
	; 52..60 - границы модулей страницы 5; метка RELOCHOOK = адрес вставки)
	IFDEF RELOCN
	IFNDEF RELOCW
	DEFINE RELOCW 0
	ENDIF
	IF where == RELOCW
RELOCHOOK	EQU $
	DS RELOCN
	ENDIF
	ENDIF
	ENDM
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
; код меню - в рабочий экран (страница 2, DSCR): на диск идёт отдельным файлом
	MMU 3,0
	ORG MENUOV
	INCLUDE "menu.asm"
	SAVEBIN "menu.bin",MENUOV,MENUEND-MENUOV
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
