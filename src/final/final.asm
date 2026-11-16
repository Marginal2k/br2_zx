;*Z80
; *L+
; *O
; *M-

DSCR	EQU	#4000
SCR	EQU	#C000
DATR	EQU	#5800
wid	EQU	14
hgt	EQU	18
xyK0	EQU	#510
xyH0	EQU	#511
IMG	EQU	#C000

	MACRO	PUSH_ 
	PUSH	DE
	PUSH	BC
	PUSH	HL
	ENDM

	MACRO	POP_ 
	POP	HL
	POP	BC
	POP	DE
	ENDM

	MACRO	ATR_ p0,p1,p2
	LD	HL,p0
	LD	BC,p1
	LD	E,p2
	CALL	ATRBAR
	ENDM

;================================================
	ORG	#6F00
	; ENT $

	IF	(01)==0	; ASM80: 01 (true when 0 / equal)
	LD	A,0 ;0/1- победа людей/кунгов
	LD	HL,#7A29 ; #7A29 -код расшифровки текста
	ENDIF

	JP	FCstrt

	DEFS	#7171-$,#EE ;(здесь была таблица IM2, см. IM2HI ниже)
;-----обработка IM2
	LD	A,(vSIDE) ;борд
	INC	A ;RLCA
	OUT	(254),A
	EI
	RETI

	DEFM	"Final Cut for Black Raven - 2 (c)Copper Feet 98"

WT	RLCA
	ADD	A,L
	LD	L,A
	JR	NC,JA_
	INC	H
JA_	LD	A,(HL)
	INC	HL
	LD	H,(HL)
	LD	L,A
	RET
	DEFS	#7200-$,#22
duTONE	DEFS	4*256,#55 ;таблица раскраски ;на границе килобайта!!!


TONE1
	DEFB	#0,#0,#0,#0,#0,#0,#2,#A,#A,#A,#A,#A,#A,#B,#B,#F
	DEFB	#0,#4,#4,#4,#5,#5,#5,#5,#5,#7,#7,#F,#F,#F,#F,#F
	DEFB	#0,#0,#0,#0,#0,#8,#8,#8,#A,#A,#A,#A,#A,#A,#E,#F
	DEFB	#0,#0,#1,#5,#5,#5,#5,#5,#5,#5,#D,#D,#F,#F,#F,#F

TONE2
	DEFB	#0,#0,#0,#0,#0,#0,#0,#1,#1,#1,#1,#3,#3,#7,#7,#F
	DEFB	#0,#0,#0,#1,#1,#1,#1,#1,#1,#3,#7,#7,#7,#7,#F,#F
	DEFB	#0,#0,#1,#1,#1,#3,#3,#3,#7,#7,#7,#7,#F,#F,#F,#F
	DEFB	#0,#3,#3,#3,#7,#7,#F,#F,#F,#F,#F,#F,#F,#F,#F,#F

TONE3
	DEFB	#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#4,#6,#F
	DEFB	#0,#0,#0,#0,#0,#4,#6,#E,#F,#F,#F,#F,#F,#F,#F,#F
	DEFB	#0,#4,#6,#E,#F,#F,#F,#F,#F,#F,#F,#F,#F,#F,#F,#F
	DEFB	#0,#0,#0,#0,#0,#0,#0,#0,#0,#4,#6,#E,#F,#F,#F,#F

TONE4
	DEFB	#0,#0,#0,#0,#0,#0,#A,#A,#A,#A,#A,#A,#A,#F,#F,#F
	DEFB	#0,#0,#0,#5,#5,#5,#5,#5,#5,#5,#F,#F,#F,#F,#F,#F
	DEFB	#0,#0,#0,#0,#0,#0,#A,#A,#A,#A,#A,#A,#A,#F,#F,#F
	DEFB	#0,#0,#0,#5,#5,#5,#5,#5,#5,#5,#F,#F,#F,#F,#F,#F

TONE5
	DEFB	#0,#0,#0,#0,#0,#0,#A,#A,#A,#A,#F,#F,#F,#F,#F,#F
	DEFB	#0,#0,#0,#0,#0,#0,#5,#5,#5,#5,#F,#F,#F,#F,#F,#F
	DEFB	#0,#0,#0,#0,#0,#0,#A,#A,#A,#A,#F,#F,#F,#F,#F,#F
	DEFB	#0,#0,#0,#0,#0,#0,#5,#5,#5,#5,#F,#F,#F,#F,#F,#F


	INCLUDE "xdelpz.asm"
DLPCB	DEFM	"v301"


;-----------вспомогательные п/п
MEM0	XOR	A ;Cтандартная страница-0
	JR	MEM

MEM1	LD	A,1
	JR	MEM
MEM7	LD	A,7
MEM	OR	%10000
	PUSH	BC
	LD	BC,#7FFD
	OUT	(C),A
	POP	BC
	RET

;-----W_GrLib--for intro---------------
SCRADR	DEFB	SCR/256
ATRADR	DEFB	#D8

PCOORD	LD	A,D ;de(0-191,0-255) -- hl
	RRCA
	RRCA
	RRCA
	LD	L,A
	AND	%00011000
	LD	H,A
	LD	A,D
	AND	%00000111
	ADD	A,H
	LD	H,A
	LD	A,(SCRADR)
	ADD	A,H
	LD	H,A
	LD	A,L
	LD	L,E
	RRA
	RR	L
	RRA
	RR	L
	RRA
	RR	L
	RET


SCOORD	LD	A,(SCRADR) ;de(0-23,0-31)--hl
	ADD	A,D
	AND	%11111000
	LD	H,A
	LD	A,D
	RRCA
	RRCA
	RRCA
	AND	%11100000
	OR	E
	LD	L,A
	RET

STD	LD	A,DSCR/256 ;выбор тенев.экрана
	JR	SELSCR
STS	LD	A,SCR/256 ;выб.осн.экр
SELSCR	LD	(SCRADR),A ;A-screen address
	ADD	A,#18
	LD	(ATRADR),A ; A-attr address
	RET

ACOORD	LD	A,L ;коорд атр HL->HL
	RLA
	RLA
	RLA
	SRL	H
	RRA
	SRL	H
	RRA
	SRL	H
	RRA
	LD	L,A
	LD	A,(ATRADR)
	ADD	A,H
	LD	H,A
	RET

ATRBAR ;HL - adr in scr; BC-size(yx) ;E-COLOR
	PUSH_
	CALL	ACOORD
ATRBA0	LD	D,L
	LD	A,C
ATRBA1	LD	(HL),E
	INC	L
	DEC	A
	JR	NZ,ATRBA1
	LD	A,D
	ADD	A,32
	LD	L,A
	JR	NC,ATRBA2
	INC	H
ATRBA2	DJNZ	ATRBA0
	POP_
	RET

;------


;----------------работа с видео

TONETB	DEFW	TONE1,TONE4,TONE5,TONE2,TONE3
CURTON	DEFB	0 ;текущая раскраска
adrXY0	DEFW	0 ;позиция лев. верхн угла

NEWTON	LD	HL,CURTON
	INC	(HL)
	LD	A,(HL)
	CP	5 ;макс число раскрасок
	JR	C,SETTON
	XOR	A
	LD	(HL),A
;
SETTON ;задать таблицу раскраски А
	LD	DE,duTONE
	LD	HL,TONETB
	CALL	WT
;---мл.полубайт
	PUSH	HL
	PUSH	DE
	LD	B,4
sttn1	PUSH	BC
	LD	A,16
sttn0	PUSH	HL
	LD	BC,16
	LDIR
	POP	HL
	DEC	A
	JR	NZ,sttn0
	LD	C,16
	ADD	HL,BC
	POP	BC
	DJNZ	sttn1
	POP	DE
	POP	HL
;---старш.полубайт
	LD	B,64
stts0	PUSH	BC
	LD	A,(HL)
	RLCA
	RLCA
	RLCA
	RLCA
	LD	C,A
	INC	HL
	LD	B,16
stts2	LD	A,(DE)
	OR	C
	LD	(DE),A
	INC	DE
	DJNZ	stts2
	POP	BC
	DJNZ	stts0
	RET



SETXY0 ;в DE - позиция лев верхн угла
	CALL	SCOORD
	LD	(adrXY0),HL
	RET

	MACRO	loop  ;*204тактов
;
	POP	BC
	LD	L,B
	LD	B,duTONE/256 ;вывод 8х4 пикс верхн
;
	LD	A,(BC)
	LD	(DE),A
	INC	B
	INC	D
;
	LD	A,(BC)
	LD	(DE),A
	INC	B
	INC	D
;
	LD	A,(BC)
	LD	(DE),A
	INC	B
	INC	D
;
	LD	A,(BC)
	LD	(DE),A
	INC	D
;
	LD	B,duTONE/256 ;вывод 8х4 пикс нижн
	LD	C,L
;
	LD	A,(BC)
	LD	(DE),A
	INC	B
	INC	D
;
	LD	A,(BC)
	LD	(DE),A
	INC	B
	INC	D
;
	LD	A,(BC)
	LD	(DE),A
	INC	B
	INC	D
;
	LD	A,(BC)
	LD	(DE),A
;
	LD	D,H
	INC	E
;
	ENDM


NOKEY	DEFB	0
isKEY	LD	BC,#FDFE
;"S-нов.раскраска"
	IN	A,(C)
	BIT	1,A
	LD	A,0
	JR	NZ,isK1
	LD	A,(NOKEY)
	OR	A
	CALL	Z,NEWTON
	LD	A,1
isK1	LD	(NOKEY),A
	RET

iFNT
	INCBIN "data/4font.fnt"

BADgay ;против пиратов
;
TV16OU ;вывод кадра HL
;
	PUSH	HL
	LD	(getSP+1),SP
	LD	SP,HL
	LD	DE,(adrXY0)
	LD	A,hgt ;высоты окна вывода в з/м
tvou1	EX	AF,AF'
	LD	H,D
	loop ;wid раз
	loop
	loop
	loop ;
	loop
	loop
	loop
	loop ;
	loop
	loop
	loop
	loop ;
	loop
	loop
	LD	A,E
	ADD	A,32-wid
	LD	E,A
	JR	NC,tvou3
	LD	A,D
	ADD	A,8
	LD	D,A
tvou3	EX	AF,AF'
	DEC	A
	JP	NZ,tvou1
getSP	LD	SP,#eeee
	POP	HL
	RET

WTR	EI
	HALT
	CALL	iMUS+6
	DI
	RET

;---------main code

vSIDE	DEFB	0 ; кто победил
FCstrt ;////set/////////////////////////////////

	DI
	LD	SP,#6EEE
	LD	(vSIDE),A
	LD	(cod2),HL
	LD	A,IM2HI ;таблица IM2 вне "сжимаемой" памяти (было #70: #7000, страница 5)
	LD	I,A
	IM	2
	CALL	SETfrm
	XOR	A
	CALL	SETTON
	CALL	iMUS
;
	LD	B,180
Awt ;wait loop
	PUSH	BC
	CALL	WTR
	POP	BC
	DJNZ	Awt
;
A00	LD	A,#FF
	LD	(isTXT),A
A1 ;txt loop
	CALL	WTR
	CALL	SCROLw
	CALL	OUTtxt
	LD	A,(isTXT)
	OR	A
	JR	NZ,A1
;
	LD	C,24
A2 ;video loop
	LD	B,96
A22	PUSH	BC
	CALL	WTR
	CALL	ifcOUT
	CALL	isKEY
	POP	BC
	DJNZ	A22
	DEC	C
	JR	NZ,A2
	JR	A00



;/////////////////////////////////////////////////

adrFLI	DEFW	#C000
pagFLI	DEFB	0
ticFLI	DEFB	0

ifcOUT ;вывод видео
	LD	HL,ticFLI
	INC	(HL)
	BIT	0,(HL)
	RET	Z
	LD	A,(pagFLI)
	CALL	MEM
	LD	HL,(adrFLI)
	CALL	TV16OU
	LD	DE,(wid*hgt)*2
	ADD	HL,DE
	LD	A,H
	CP	#FF
	JR	C,iff1
	LD	A,(pagFLI)
	ADD	A,3
	CP	7
	JR	C,iff2
	XOR	A
iff2	LD	(pagFLI),A
	LD	HL,SCR
iff1	LD	(adrFLI),HL
	RET

SCROLw ;скроллер окна
	LD	DE,(adrXY0)
	LD	L,E
	LD	H,D
	INC	H
	EXX
	LD	B,(hgt*8)-1
sclw1	EXX
	PUSH	HL
	PUSH	HL
	LDI
	LDI
	LDI
	LDI
	LDI
	LDI
	LDI ;7
	LDI
	LDI
	LDI
	LDI
	LDI
	LDI
	LDI ;14
	POP	HL
	INC	H
	LD	A,H
	AND	7
	JR	NZ,sclw2
	LD	A,L
	ADD	A,32
	LD	L,A
	JR	C,sclw2
	LD	A,H
	SUB	8
	LD	H,A
sclw2	POP	DE
	EXX
	DJNZ	sclw1
	RET

SETfrm ;установка оформления
	LD	A,1
	CALL	MEM
	CALL	STD
;
	LD	HL,DATR
	LD	DE,DATR+1
	LD	BC,#300
	LD	(HL),0
	LDIR
;
	LD	A,(vSIDE) ;муз
	LD	DE,iMUS
	LD	HL,mhum+2
	OR	A
	CALL	Z,DELPZ
;
	LD	A,(vSIDE) ;застав
	LD	DE,DSCR
	LD	HL,phum+2
	OR	A
	JR	Z,sff1
	LD	HL,pkun+2
sff1	CALL	DELPZ
;
	LD	A,(vSIDE) ;поз экрана+окрас
	LD	HL,xyH0
	LD	E,#70
	OR	A
	JR	Z,sff2
	LD	HL,xyK0
	LD	E,#69
sff2	PUSH	HL
	LD	BC,#120E
	CALL	ATRBAR
	POP	DE
	CALL	SETXY0
;
	LD	A,(vSIDE) ;текст
	LD	HL,thum
	LD	DE,#57D1
	OR	A
	JR	Z,sff4
	LD	HL,tkun
	DEC	DE
sff4	LD	(txtBEG),HL
	LD	(txtCUR),HL
	LD	(lastLN),DE
	CALL	deTXT
;
	RET

cod2	DEFB	2
cod1	DEFB	1

deTXT	LD	BC,(cod2)
;	HALT
	LD	A,B
dtt1	ADD	A,C
	INC	C
	INC	C
	LD	B,A
	LD	A,(HL)
	LD	E,A
	SUB	B
	LD	(HL),A
	CP	255
	RET	Z
	INC	HL
	LD	A,E
	JR	dtt1


isTXT	DEFB	1 ;1-текст вкл
txtBEG	DEFW	0 ;начало текста
txtCUR	DEFW	0 ;текущ строка текста
txtTIC	DEFB	0 ;текущ линия строки
fntCUR	DEFW	0 ;текущ линия шрифта
lastLN	DEFW	0 ;адр. последн. линии окна

OUTtxt ;вывод пиксельной строки текста
;вых NC - конец текста
	LD	HL,txtTIC
	LD	A,(HL)
	INC	(HL)
	CP	24
	JR	C,oux0
;нов строка
	LD	(HL),0
	PUSH	HL
	LD	HL,(txtCUR)
	LD	DE,12
	ADD	HL,DE
	LD	(txtCUR),HL
	LD	A,(HL)
	CP	255
	POP	HL
	JR	C,oux0
;конец текста
	LD	HL,(txtBEG)
	LD	(txtCUR),HL
	XOR	A
	LD	(txtTIC),A
	LD	(isTXT),A
	RET
oux0	LD	A,(HL)
	SRL	A
	RET	C
	CP	8
	JR	C,ouxLT
;пустая строка
	LD	HL,(lastLN)
	LD	B,14
ouxCL	LD	(HL),#FF
	INC	L
	DJNZ	ouxCL
	RET
ouxLT ;текст
	LD	E,A
	LD	D,0
	LD	HL,iFNT
	ADD	HL,DE
	LD	(fntCUR),HL
;
	LD	HL,(txtCUR)
	LD	B,12
	LD	DE,(lastLN)
	INC	DE
ouxLT8	LD	A,(HL)
	CP	100
	CALL	NC,BADgay
	CALL	PRI1x8
	DJNZ	ouxLT8
	RET

PRI1x8 ;печать строки символа А по адр DE
	PUSH	HL
	PUSH	BC
	ADD	A,A
	LD	BC,(fntCUR)
	LD	L,A
	LD	H,0
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,BC
	LD	A,(HL)
	LD	(DE),A
	POP	BC
	POP	HL
	INC	HL
	INC	E
	RET


tkun
	INCBIN "data/4victkun.dat"
thum
	INCBIN "data/4victhum.dat"


; Таблица векторов IM2 (257 байт #71: вектор #7171 - обработчик выше): раньше на #7000-#7100 (страница 5, "сжимаемая": на 128K/+2
; при I в #40-#7F ULA рисует "снег"); теперь в свободном промежутке перед музыкой, в странице 2 (она всегда подключена).
IM2HI	EQU	#8C
	ASSERT	$<=IM2HI*256
	DEFS	IM2HI*256-$,#11
	DEFS	257,#71
	DEFS	44000-$,#11
iMUS ;здесь будет музыка
	INCBIN "music/4k_victc.mus"
	DEFM	"  BYE-BYE-BYE  "


	MMU 3,1	; page 1 at #C000 ;----(вспм)---\в этом порядке
	ORG	#C000
pkun
	INCBIN "pictures/4k_end.lpz"
mhum
	INCBIN "music/4h_victc.lpz"
phum
	INCBIN "pictures/4h_end.lpz"

;*P0;----
;	 ORG #C000
;*B ..\TV16\FINAL\h_vict0.T16
;*B ..\TV16\FINAL\K_vict0.T16
;
;*P3;----
;	 ORG #C000
;*B ..\TV16\FINAL\h_vict1.T16
;*B ..\TV16\FINAL\K_vict1.T16
;
;*P6;----
;	 ORG #C000
;*B ..\TV16\FINAL\h_vict2.T16
;*B ..\TV16\FINAL\K_vict2.T16


	MMU 3,0	; page 0 at #C000 ;===================================================
