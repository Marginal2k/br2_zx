;*Z80
;*L+
;*O
;*M-

;;;	ORG #7000

DSCR	EQU	#4000
DATR	EQU	#5800
wid	EQU	14
hgt	EQU	18
xyR0	EQU	#411
xyL0	EQU	#502
IMG	EQU	#C000

	MACRO	ATR_ p0,p1,p2
	LD	HL,p0
	LD	BC,p1
	LD	E,p2
	CALL	ATRBAR
	ENDM

	DEFS	#7171-$,#71 ;(здесь была таблица IM2, см. IM2HI ниже; вектор по-прежнему #7171)
;-----обработка IM2
	LD	A,2
	OUT	(254),A
;(music)
	EI
	RETI

	DEFM	"Video for Black Raven - 2 (c)Copper Feet 98"
COLOR	ATR_ 0,#1820,#3A ;поле
	LD	A,2
	OUT	(254),A
;;	ATR$ xyR0,hgt*256+wid,#30 ;окна
;;	ATR$ xyL0,hgt*256+wid,#28 ;
	ATR_ #51F,#1101,#38 ;кн
	ATR_ #E1F,#501,#29
	ATR_ #700,#E02,#31
	ATR_ #1612,#20C,#39
	RET
	DEFS	#7200-$,11

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


;;*F XDELPZ
;;DLPCB   DEFM "v301"

FRM
	INCBIN "data/4intro.lpz"

;-----------вспомогательные п/п

PRINT ;печать символа А в поз DE(yx)
	PUSH	HL
	PUSH	DE
	PUSH	BC
	LD	C,A
	CALL	SCOORD
	EX	DE,HL
	LD	A,C
	ADD	A,A
	LD	BC,iFNT
	LD	L,A
	LD	H,0
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,BC
	LD	B,4
iPR1	LD	A,(HL)
	LD	(DE),A
	INC	HL
	INC	D
	LD	A,(HL)
	LD	(DE),A
	INC	HL
	INC	D
	DJNZ	iPR1
	POP	BC
	POP	DE
	POP	HL
	RET


;----рамка
FRAME	LD	HL,FRM+2
	LD	DE,DSCR
	JP	DELPZ

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
;"E-exit"
	LD	B,#FB
	IN	A,(C)
	BIT	2,A
	JR	NZ,isK2
	CALL	iMUSst
	JP	START
;"N-новый блок видео"
isK2	LD	B,#7F
	IN	A,(C)
	BIT	3,A
	RET	NZ
	CALL	iMUSst
	LD	B,20
isK2L	EI
	HALT
	DI
	DJNZ	isK2L
	JP	skpBLK

iTXT
	INCBIN "data/4flictxt.dat"
iFNT
	INCBIN "data/4font.fnt"

preTV	EQU	3 ;к-во строк упреждающего вывода

TV16OU ;вывод кадра HL
;
	PUSH	HL
	LD	A,preTV
	LD	DE,(adrXY0)
	CALL	TV16L ;упреждающий вывод
	CALL	MUZAK
	LD	A,hgt-preTV
	CALL	TV16L ;остальной вывод
	POP	HL
	RET


TV16L ;вывод A строк окна
	LD	(getSP+1),SP
	LD	SP,HL
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
	LD	(HLSP),SP
	LD	HL,(HLSP)
getSP	LD	SP,#eeee
	RET

HLSP	DEFW	#FFFF


;---------main code

tvSTRT ;////set/////////////////////////////////

	DI
	LD	A,IM2HI ;таблица IM2 вне "сжимаемой" памяти (было #70: #7000, страница 5)
	LD	I,A
	IM	2
	XOR	A
	CALL	MEM
	CALL	STD
	CALL	OFFD
	CALL	FRAME
	CALL	COLOR
	CALL	SW5
	XOR	A
	CALL	SETTON
	CALL	newBLK
	CALL	iMUSst
;
A1 ;main loop
	CALL	deSCRP
	CALL	IMGout
	CALL	isKEY
	CALL	IMGout
	JR	A1

MUZAK	PUSH_
	PUSH	IX
	EI
	HALT
	CALL	iMUSpl
	DI
	POP	IX
	POP_
	RET

;/////////////////////////////////////////////////

_ATR0	DEFW	1998

COLWIN	LD	A,(IX+1) ;закрасить окно
	CP	7
	RET	C
	PUSH	DE
	LD	E,A
	LD	D,A
	AND	7
	LD	(IX+1),A
	LD	HL,(_ATR0)
	LD	B,18
	LD	(colexi+1),SP
	LD	SP,HL
colloo	PUSH	DE
	PUSH	DE
	PUSH	DE
	PUSH	DE
	PUSH	DE
	PUSH	DE
	PUSH	DE
	LD	HL,32+14
	ADD	HL,SP
	LD	SP,HL
	DJNZ	colloo
colexi	LD	SP,0
	POP	DE
	RET


;-----------проигрывание видео---
blockV	DEFB	0 ;текущий блок video

Ltyp	DEFB	0 ;тип окна слева ;0
Lcolor	DEFB	#44 ;цвет окна ;1
Lpgnum	DEFB	0 ;страница с видео слева/текущ. столбец текста ;2
Ldel	DEFW	iTXT ;адрес изображения или текста ;3,4

Rtyp	DEFB	0
Rcolor	DEFB	#44
Rpgnum	DEFB	0 ;справа
Rdel	DEFW	iTXT

IMGout	LD	HL,tmTIC
	DEC	(HL)
	BIT	0,(HL)
	LD	IX,Ltyp
	LD	DE,xyL0
	LD	HL,DATR+176
	JR	Z,desc1
	LD	IX,Rtyp
	LD	DE,xyR0
	LD	HL,DATR+159
desc1	LD	(_ATR0),HL
	LD	A,(IX)
	LD	HL,deSCt
	CALL	WT
	JP	(HL)
deSCt	DEFW	DEC0,DEC1,DEC2,DEC3,DEC4


DEC0 ;txt
	CALL	MUZAK
	CALL	COLWIN
	LD	A,(IX+2)
	INC	(IX+2)
	CP	12
	CALL	C,COLUMN
;пауза для текста (40000т)
	LD	BC,1500
p401	DEC	BC
	LD	A,C
	OR	B
	JR	NZ,p401
	RET

COLUMN	LD	C,A
	ADD	A,E
	LD	E,A
	INC	E
	INC	D
	PUSH	DE
	EXX
	POP	HL
	CALL	ACOORD
	LD	DE,32
	LD	A,(IX+1)
	AND	#7
	LD	B,A
	EXX
	LD	A,C
	ADD	A,A
	ADD	A,A
	ADD	A,A
	ADD	A,A
	LD	L,A
	LD	H,0
	LD	C,(IX+3)
	LD	B,(IX+4)
	ADD	HL,BC
	LD	B,16
dec01	LD	A,(HL)
;atr
	EXX
	CP	48
	LD	C,#78
	JR	C,dec02
	LD	C,#70
	CP	81
	JR	C,dec02
	LD	C,#68
dec02	LD	A,B
	ADD	A,C
	LD	(HL),A
	ADD	HL,DE
	EXX
;sym
	LD	A,(HL)
	CALL	PRINT
	INC	D
	INC	HL
	DJNZ	dec01
	RET

DEC1 ;tv16
	CALL	SETXY0
	XOR	A
	CALL	MEM
;
	LD	L,(IX+3) ;C/NC
	LD	H,(IX+4)
	CALL	TV16OU
	LD	DE,(hgt*wid)*2
	ADD	HL,DE
	LD	A,(IX+2)
	OR	A
	JR	Z,dec1e
	LD	A,H
	CP	#FF
	JR	C,dec11
	LD	HL,IMG+#1F80
	JR	dec11
dec1e	LD	A,H
	CP	#DF
	JR	C,dec11
	LD	HL,IMG
dec11	LD	(IX+3),L
	LD	(IX+4),H
	JP	COLWIN

DEC3 ;tv64
	CALL	DEC2
	RET	C
	LD	A,(IX+2)
	ADD	A,3
	CP	6
	JR	C,dec31
	SUB	6
dec31	LD	(IX+2),A
	RET

DEC4 ;tv96
	CALL	DEC2
	RET	C
	LD	A,(IX+2)
	ADD	A,3
	CP	9
	JR	C,dec41
	SUB	9
dec41	LD	(IX+2),A
	RET

DEC2 ;tv32
	CALL	SETXY0
	LD	A,(IX+2)
	CALL	MEM
;
	LD	L,(IX+3) ;C/NC
	LD	H,(IX+4)
	CALL	TV16OU
	LD	DE,(hgt*wid)*2
	ADD	HL,DE
	LD	A,H
	CP	#FF
	JR	C,dec21
	LD	HL,IMG
dec21	LD	(IX+3),L
	LD	(IX+4),H
	PUSH	AF
	PUSH	HL
	CALL	COLWIN
	POP	HL
	POP	AF
	RET

;--------------------------
tmSCRP	DEFW	1 ;время до след события
tmTIC	DEFB	0 ;счётчик
pSCRP	DEFW	SCRIPT ;указатель на текущ поз в сценарии

deSCRP ;интерпретатор сценария
	LD	HL,(tmSCRP)
	DEC	HL
	LD	A,L
	OR	H
	EX	AF,AF'
	LD	(tmSCRP),HL
	EX	AF,AF'
	RET	NZ
;
nwSCRP ;считать новую команду
	LD	HL,(pSCRP)
nlsnxt	LD	A,(HL)
	INC	HL
	BIT	7,A
	LD	IX,Ltyp
	JR	Z,nlsc
	LD	IX,Rtyp
nlsc	RES	7,A
	CP	6
	JR	NC,COM6
	LD	(IX),A
	PUSH	HL
	LD	HL,nwSCRt
	CALL	WT
	LD	(nlsjp+1),HL
	POP	HL
nlsjp	CALL	0
	JR	nlsnxt
;
COM6 ;new delay
	LD	A,(HL)
	INC	HL
	LD	(pSCRP),HL
	LD	L,A
	LD	H,0
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	LD	(tmSCRP),HL
	RET

nwSCRt	DEFW	COM0,COM1,COM2,COM3,COM4,COM5

COM0 ;текст
	XOR	A
	LD	(IX+2),A
	LD	A,(HL)
	INC	HL
	PUSH	HL ;12*16*A
	LD	L,A
	ADD	A,A
	ADD	A,L ;x3
	LD	L,A
	LD	H,0
	ADD	HL,HL ;x6
	ADD	HL,HL ;x12
	ADD	HL,HL ;x24
	ADD	HL,HL ;x48
	ADD	HL,HL ;x96
	ADD	HL,HL ;x192
	LD	DE,iTXT
	ADD	HL,DE
	LD	(IX+3),L
	LD	(IX+4),H
	POP	HL
	JR	com3tx
COM1 ;V16
	LD	A,(HL)
	LD	(IX+2),A
	INC	HL
	OR	A
	LD	DE,#C000
	JR	Z,com1a
	LD	DE,#DF80
com1a	LD	(IX+4),D
	LD	(IX+3),E
	JR	com3tx
COM2 ;V32
COM3 ;V64
COM4 ;V96
	LD	A,(HL)
	INC	HL
	LD	(IX+2),A
	LD	(IX+4),#C0
	LD	(IX+3),#00
com3tx	LD	A,(HL)
	INC	HL
	LD	(IX+1),A
	RET
COM5 ;stop/new
	LD	A,(HL)
	OR	A ;музыка?
	CALL	Z,iMUSst ;с начала
	DI
skpBLK	CALL	notMUS
	CALL	FRAME
	ATR_ xyR0,(hgt*256)+wid,#3A ;окна
	ATR_ xyL0,(hgt*256)+wid,#3A ;
;
newBLK	LD	HL,blockV ;загр след видео-блока
	LD	A,(HL)
	INC	(HL)
	CP	5
	JR	C,nb5a
	LD	(HL),0
nb5a	PUSH	AF
	CALL	LOAD_M
	XOR	A
	LD	(tmTIC),A
	LD	HL,1
	LD	(tmSCRP),HL
	POP	AF
	LD	HL,SCRItb
	CALL	WT
	LD	(pSCRP),HL
	RET

SCRItb	DEFW	SCRIPT,SCRIP1,SCRIP2,SCRIP3,SCRIP4,SCRIP5

notMUS	LD	BC,#FFFD
	LD	A,7
	OUT	(C),A
	LD	B,#BF
	LD	A,#FF
	OUT	(C),A
	RET

LOAD_M ;загр блок мультиков: A
	LD	C,A
	ADD	A,A
	ADD	A,C
	ADD	A,A
	ADD	A,16
	LD	C,0
	CALL	LOA1_M
	CALL	LOA1_M
	CALL	LOA1_M
	LD	C,1
	CALL	LOA1_M
	CALL	LOA1_M
	CALL	LOA1_M
	LD	B,8
DPZ1	PUSH	BC
	LD	A,B
	DEC	A
	CP	2
	JR	Z,DPZ0
	CP	5
	JR	Z,DPZ0
	CALL	MEM
	LD	HL,#C000
	CALL	DELPZF
DPZ0	POP	BC
	DJNZ	DPZ1
	RET


LOA1_M	PUSH	BC
	PUSH	AF
	LD	A,C
	CALL	MEM
	POP	AF
	PUSH	AF
	CALL	LOADF
	POP	AF
	POP	BC
	INC	C
	INC	C
	INC	C
	INC	A
	RET

;-----сам сценарий (#0x - левое окно, #8x - правое)
;txt: 0,(n=0..37),(col=#40,#49,#52,#5B)
;v16: 1,(n=0,1),col
;v32: 2,(p=0,1,3,4,6,7),col
;v64: 3,(p1=0,1),col
;v96: 4,(p1=0,1),col
;new: 5,(newmus=0/1)
;del: 6,(delay/16)

BLU	EQU	#49
RED	EQU	#52
BLA	EQU	#40
ROS	EQU	#5B

	MACRO	DEL p0 ;delay
	DEFB	6,p0
	ENDM

	MACRO	LTX p0,p1
	DEFB	#00,p0,p1
	ENDM

	MACRO	RTX p0,p1
	DEFB	#80,p0,p1
	ENDM

	MACRO	_NXT_ p0
	DEFB	5,p0
	ENDM

	MACRO	L16 p0,p1
	DEFB	#01,p0,p1
	ENDM

	MACRO	R16 p0,p1
	DEFB	#81,p0,p1
	ENDM

	MACRO	L32 p0,p1
	DEFB	#02,p0,p1
	ENDM

	MACRO	R32 p0,p1
	DEFB	#82,p0,p1
	ENDM

	MACRO	L64 p0,p1
	DEFB	#03,p0,p1
	ENDM

	MACRO	R64 p0,p1
	DEFB	#83,p0,p1
	ENDM

	MACRO	L96 p0,p1
	DEFB	#04,p0,p1
	ENDM

	MACRO	R96 p0,p1
	DEFB	#84,p0,p1
	ENDM


; *M+
SCRIPT
;===PART0===
	RTX 0,BLU
	L96 1,#70
	DEL 24

	LTX 1,BLU
	R96 0,#60
	DEL 24

	RTX 2,BLA
	L96 1,#68
	DEL 24

	LTX 3,RED
	R96 1,#69
	DEL 24

	RTX 4,BLA
	L96 0,#71
	DEL 24

	LTX 5,BLA
	R96 1,#72
	DEL 24

	RTX 6,BLU
	L96 0,#78
	DEL 24

	LTX 7,BLA
	R96 1,#70
	DEL 24

	L96 0,#70
	DEL 48
	_NXT_ 0

SCRIP1
;===PART1===
	RTX 8,BLU
	L32 3,#60
	DEL 24

	RTX 9,BLA
	L16 1,#69
	DEL 24

	LTX 10,RED
	R32 6,#70
	DEL 24

	RTX 11,BLA
	L16 0,#72
	DEL 24

	LTX 12,RED
	R32 1,#70
	DEL 24

	RTX 13,BLU
	L32 4,#70
	DEL 24

	RTX 14,RED
	L32 7,#68
	DEL 24

	LTX 15,BLA
	R32 7,#72
	DEL 24
	_NXT_ 1

SCRIP2
;===PART2===
	RTX 16,BLA
	L32 4,#70
	DEL 24

	RTX 17,RED
	L32 1,#70
	DEL 24

	R32 4,#70
	DEL 24

	LTX 18,BLU
	DEL 24

	RTX 19,BLA
	L32 3,#79
	DEL 24

	LTX 20,BLA
	R32 6,#70
	DEL 24

	LTX 21,BLA
	R32 7,#60
	DEL 24

	L32 7,#68
	R16 0,#38
	DEL 24

	L16 1,#79
	RTX 22,BLA
	DEL 24

	R16 1,#79
	L32 1,#72
	DEL 24

	_NXT_ 1

SCRIP3
;===PART3===

	LTX 23,BLA ;--24
	R32 3,#70
	DEL 24

	LTX 24,RED ;--24
	R32 3,#70
	DEL 4
;
	R96 0,#70
	DEL 12
;
	R32 0,#70
	DEL 4
;
	R32 6,#70
	DEL 4

	RTX 25,BLU ;--24
	L32 3,#68
	DEL 4
;
	L64 1,#68
	DEL 4
;
	L32 3,#68
	DEL 4
;
	L64 1,#68
	DEL 8
;
	L64 1,#68
	DEL 4

	L32 3,#68 ;--72
	R32 3,#79
	DEL 12
;
	R32 0,#79
	DEL 4
;
	L32 6,#68
	DEL 4
;
	L32 7,#68
	R32 1,#79
	DEL 4
;
	R32 3,#79
	DEL 4
;
	R32 6,#79
	DEL 4
;
	R32 4,#79
	DEL 4
;
	L32 3,#68
	R32 7,#79
	DEL 8
;
	L32 6,#68
	R32 0,#79
	DEL 4
;
	L32 0,#68
	R32 6,#79
	DEL 4
;
	L32 3,#68
	R32 1,#79
	DEL 4
;
	L32 1,#68
	R32 4,#79
	DEL 4
;
	L32 4,#68
	R32 3,#79
	DEL 4
;
	L32 7,#68
	R32 7,#79
	DEL 4
;
	R32 3,#79
	DEL 4

	LTX 26,ROS ;---48
	DEL 4
;
	R32 0,#79
	DEL 8
;
	R32 6,#79
	DEL 4
;
	R32 7,#79
	DEL 4
;
	R96 0,#79
	DEL 12
;
	R32 4,#79
	DEL 4
;
	R32 1,#79
	DEL 4
;
	R32 7,#79
	DEL 4
;
	R32 0,#79
	DEL 4

	_NXT_ 0

SCRIP4
;===PART4===
	RTX 27,BLA
	L32 1,#68
	DEL 24

	LTX 28,BLU
	R32 6,#71
	DEL 24

	RTX 29,BLA
	L64 0,#7A
	DEL 20
;
	R64 0,#70
	DEL 24
;
	LTX 30,BLA
	DEL 4

	R32 4,#72
	DEL 12
;
	R32 6,#78
	DEL 4
;
	R64 0,#68
	DEL 8
;
	R32 4,#72
	DEL 12
;
	R32 6,#69
	DEL 8
;
	R64 0,#60
	DEL 8
;
	R32 4,#70
	DEL 16

	RTX 31,RED
	L32 7,#70
	DEL 28

	_NXT_ 1

SCRIP5
;===PART5===

	RTX 32,BLA
	L32 6,#70
	DEL 24

	LTX 33,BLU
	R64 0,#72
	DEL 24

	RTX 34,RED
	L64 1,#70
	DEL 24

	R64 0,#70
	DEL 48

	LTX 35,BLA
	DEL 24

	RTX 36,BLA
	DEL 24

	L32 7,#79
	DEL 24

	RTX 37,BLU
	DEL 26

	R32 7,#7A
	DEL 22

	_NXT_ 0

;-----конец сценария

preMUS	DEFB	0
iMUSst	LD	A,7
	LD	(preMUS),A
	JP	iMUS

iMUSpl	LD	A,(preMUS)
	OR	A
	JP	Z,iMUS+6
	DEC	A
	LD	(preMUS),A
	RET

; Таблица векторов IM2 (257 байт #71: вектор #7171 - обработчик выше): раньше на #7000-#7100 (страница 5, "сжимаемая": на 128K/+2
; при I в #40-#7F ULA рисует "снег"); теперь в свободном промежутке перед музыкой, в странице 2 (она всегда подключена).
IM2HI	EQU	#AA
	ASSERT	$<=IM2HI*256
	DEFS	IM2HI*256-$,#11
	DEFS	257,#71
	DEFS	44100-$,#11
iMUS ;здесь будет музыка
	NOP

;*P0;---
;	ORG #C000
;0
;*B ..\tv16\MOVES\cfeetR0.t16 ;32
;1
;*B ..\tv16\MOVES\alarm.t16 ;16
;*B ..\tv16\MOVES\roulette.t16 ;16
;2
;*B ..\tv16\MOVES\ttrack.t16 ;16
;*B ..\tv16\MOVES\faces.t16 ;16
;3
;*B ..\tv16\MOVES\walk_FIR.t16 ;32
;4
;*B ..\TV16\MOVES\ROCKET1.T16;32
;5
;*B ..\TV16\MOVES\battleR0.T16;32
;*P3;---
;	ORG #C000
;0
;*B ..\tv16\MOVES\cfeetR1.t16 ;32
;1
;*B ..\tv16\MOVES\h_base.t16 ;32
;2
;*B ..\tv16\MOVES\plakat.t16 ;32
;3
;*B ..\tv16\MOVES\walk_MOV.t16 ;32
;4
;*B ..\TV16\MOVES\ROCKET2.T16;32
;5
;*B ..\tv16\MOVES\battleR1.t16 ;32
;*P6;---
;	ORG #C000
;0
;*B ..\tv16\MOVES\cfeetR2.t16 ;32
;1
;*B ..\tv16\MOVES\AIRATACK.t16 ;32
;2
;*B ..\tv16\MOVES\STINGER.t16 ;32
;3
;*B ..\tv16\MOVES\walk_AIR.t16 ;32
;4
;*B ..\tv16\MOVES\openfire.t16 ;32
;5
;*B ..\tv16\MOVES\desant.t16 ;32
;
;
;*P1;---
;	ORG #C000
;0
;*B ..\tv16\MOVES\cfeetL0.t16 ;32
;1
;*B ..\tv16\MOVES\ef_tank.t16 ;32
;2
;*B ..\TV16\MOVES\kunges1.T16;32
;3
;*B ..\tv16\MOVES\walk_ROT.t16 ;32
;4
;*B ..\tv16\MOVES\H_INTR.t16 ;32
;5
;*B ..\tv16\MOVES\battleL0.t16 ;32
;
;*P4;---
;	ORG #C000
;0
;*B ..\tv16\MOVES\cfeetL1.t16 ;32
;1
;*B ..\tv16\MOVES\bombes.t16 ;32
;2
;*B ..\TV16\MOVES\kunges2.T16;32
;3
;*B ..\tv16\MOVES\walk_dwn.t16 ;32
;4
;*B ..\tv16\MOVES\e_explos.t16 ;32
;5
;*B ..\tv16\MOVES\battleL1.t16 ;32
;*P7;---
;	ORG #C000
;0
;*B ..\tv16\MOVES\cfeetL2.t16 ;32
;1
;*B ..\tv16\MOVES\end_base.t16 ;32
;2
;*B ..\tv16\MOVES\h_tank.t16 ;32
;3
;*B ..\tv16\MOVES\walk_flm.t16 ;32
;4
;*B ..\tv16\MOVES\h_space.t16 ;32
;5
;*B ..\tv16\MOVES\end4.t16 ;32
;
	MMU 3,0	; page 0 at #C000
