; Чёрный Ворон 2: код стартового меню. Собирается по адресу MENUOV (DSCR = #A000, рабочий экран: в меню он свободен),
; хранится на диске файлом F_MENU и читается туда перед показом меню (startm.asm: LDMENU).
; Вход: MENUOV = MENU (A = 0 - таймаут, 1/2 - люди/кунги, 3 - загрузить), MENUOV+3 = SLOTMENU (A = слот или 255).
; Меню - по образцу Чёрного Ворона 1: окно MU_BOX, шрифт и цвета игры, выбор цифрой.
	JP	MENU
	JP	SLOTMENU
; ---- меню
MENU	CALL	menuSCR
mn0	CALL	NUMBER ;(1-8) или 0 - таймаут
	OR	A
	RET	Z
	CP	4
	JR	NC,mn0
	PUSH	AF
	CALL	INImg2
	CALL	NO_NUM
	POP	AF
	RET

menuSCR	CALL	MEM7
	CALL	_V_OFF
	CALL	OFFS
	CALL	STS
	LD	DE,#703
	LD	BC,#1C09
	CALL	MU_BOX
	ATR_	#703,#091C,#71
	LD	DE,#905
	PUSH	DE
	LD	HL,ITX01
	CALL	INIprn
	LD	HL,ITX02
	CALL	INIprn
	LD	HL,ITX03
	CALL	INIprn
	POP	HL
	RET

; INImg2: A = 1..3 - подсветить выбранную строку
INImg2	PUSH	AF
	LD	HL,#905
	DEC	A
	ADD	A,H
	LD	H,A
	LD	BC,#118
	LD	E,#72
	CALL	ATRBAR
	POP	AF
	RET

INIprn	PUSH	DE
	CALL	PRINTS
	POP	DE
	INC	D
	RET

; меню слотов: A = слот 0..NSLOTS-1, 255 - отказ (таймаут). Клавиши 1-8 = слоты "Игра-001..008" окна сохранения (слот = номер: окно
; сохранения передаёт SAVgam номер строки 1..8, как и в v0.04), клавиша 9 = слот 0 ("быстрое сохранение", qSAVE/qLOAD).
SLOTMENU	CALL	menuSCR2
sl0	CALL	NUMBER
	OR	A
	JR	Z,slX
	CP	9
	JR	NZ,sl1
	XOR	A
sl1	PUSH	AF
	CALL	NO_NUM
	POP	AF
	RET
slX	LD	A,255
	RET

menuSCR2	CALL	menuSCR
	LD	DE,#D05 ;внутри окна (строки 7-15)
	LD	HL,ITXslt
	JP	PRINTS

; NUMBER: ждёт цифру 1..9 (A), 0 - таймаут (MENUTM кадров)
NUMBER	LD	DE,MENUTM
nm0	HALT
	LD	BC,#F7FE
	IN	A,(C)
	CPL
	AND	%11111
	JR	NZ,nmr1
	LD	B,#EF
	IN	A,(C)
	CPL
	AND	%11110
	JR	NZ,nmr2
	DEC	DE
	LD	A,D
	OR	E
	JR	NZ,nm0
	RET
nmr2	LD	E,A ;6-9
	LD	A,9
	RR	E
	RR	E
	RET	C
	DEC	A
	RR	E
	RET	C
	DEC	A
	RR	E
	RET	C
	DEC	A
	RET
nmr1	LD	E,A ;1-5
	LD	A,1
nmr3	RR	E
	RET	C
	INC	A
	JR	nmr3

; NO_NUM: ждать, пока отпустят цифры
NO_NUM	LD	BC,#7000
nnU0	DEC	BC
	LD	A,C
	OR	B
	JR	NZ,nnU0
	LD	BC,#F7FE
	IN	A,(C)
	CPL
	AND	%11111
	JR	NZ,NO_NUM
	LD	B,#EF
	IN	A,(C)
	CPL
	AND	%11111
	JR	NZ,NO_NUM
	RET


	INCLUDE "menu_text.inc"
MENUEND
