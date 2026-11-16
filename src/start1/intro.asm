
;---Цифра 2 с планетками (c) Слава Медноногов 98
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

	MMU 3,0	; page 0 at #C000 ;--------MAIN--



;---------
bSTARS	DI
	IM	1
	LD	A,#3F ;I - как в ПЗУ (после роликов он указывал на таблицу IM2 ролика)
	LD	I,A
	CALL	MEM7
	LD	DE,SCR
	LD	HL,SWORD+2
	CALL	DELPZ
	CALL	SW7
	CALL	MEM1
	CALL	fMUS
;оформление
	CALL	STD
	LD	HL,0
	LD	BC,#1820
	LD	E,n
	CALL	ATRBAR
	LD	HL,MNFRM+2
	LD	DE,DSCR
	CALL	DELPZ
	LD	HL,MNFRat
	LD	DE,((32*5)+DSCR)+#1800
	LD	BC,32*12
	LDIR
;старт
	LD	HL,((64*6)*4)+10
fSSx	LD	(fTIMER),HL
fSS2	CALL	PRESS
	XOR	A
	OUT	(#FE),A
	CALL	fLDIR
	CALL	MEM1
	CALL	fMUS+6
	DI
	LD	HL,(fTIMER)
	DEC	HL
	LD	(fTIMER),HL
	LD	A,H
	CP	-7
	JR	NZ,fSS4
	CALL	Z,SW7
	LD	HL,((64*6)*4)-1
	JR	fSSx
fSS4	OR	L
	JR	NZ,fSS2
	CALL	Z,SW5
	JR	fSS2

fTIMER	DEFW	0 ;время вывода начальн заставки
fFRAME	DEFB	0 ; (#кадра - 1..12)
fFDELY	DEFB	0 ;задержка
fLDIR	LD	HL,fFDELY
	INC	(HL)
	LD	A,(HL)
	CP	3
	LD	A,(fFRAME)
	JR	C,fMM1
	LD	(HL),0
	DEC	HL
	INC	(HL)
	LD	A,(HL)
	CP	12
	JR	C,fMM1
	XOR	A
	LD	(HL),A
fMM1	CP	6
	JR	C,fMM2
	SUB	6
	PUSH	AF
	LD	A,4
	JR	fMM3
fMM2	PUSH	AF
	LD	A,3
fMM3	CALL	MEM
	POP	AF
	LD	HL,#C000
	OR	A
	JR	Z,fMM4
	LD	DE,2560
fMM5	ADD	HL,DE
	DEC	A
	JR	NZ,fMM5
fMM4 ;
	LD	DE,#4066
	EXX
	LD	B,16
	CALL	fEM0
	EI
	HALT
	DI
	LD	B,112

fEM0	EXX
	LDI
	LDI
	LDI
	LDI
	LDI ;
	LDI
	LDI
	LDI
	LDI
	LDI ;
	LDI
	LDI
	LDI
	LDI
	LDI ;
	LDI
	LDI
	LDI
	LDI
	LDI ;
	LD	A,E
	SUB	20
	LD	E,A
	INC	D
	LD	A,D
	AND	7
	JP	NZ,fEM1

	LD	A,E
	ADD	A,32
	LD	E,A
	JR	C,fEM1
	LD	A,D
	SUB	8
	LD	D,A
fEM1	EXX
	DJNZ	fEM0
	RET

PRESS ;нажатие клавиши 1-2-3
	PUSH	BC
	LD	BC,#F7FE
	IN	A,(C)
	BIT	4,A
	CALL	Z,bGIMN
	POP	BC
	CPL
	AND	7
	OR	A
	RET	Z
	LD	E,1
	RRA
	JR	C,PRE1
	INC	E
	RRA
	JR	C,PRE1
	INC	E
PRE1	LD	A,E
	PUSH	AF
	CALL	MEM1
	CALL	fMUS
	POP	AF
	CP	2
	JP	C,bFLICK
	JP	Z,bGAME
	CALL	YELLOW
	JP	bINSTR



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

n	EQU	#70
a_	EQU	#58
e_	EQU	#58
x	EQU	#70
MNFRat
	DEFB	a_,a_,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,e_,e_
	DEFB	a_,a_,a_,a_,a_,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,e_,e_,e_,e_
	DEFB	a_,a_,a_,a_,a_,a_,a_,n,n,n,n,n,n,n,n,x,x,n,n,n,n,n,n,n,n,e_,e_,e_,e_,e_,e_,e_
	DEFB	a_,a_,a_,a_,a_,a_,a_,a_,n,n,n,n,n,x,x,x,x,x,x,n,n,n,n,n,e_,e_,e_,e_,e_,e_,e_,e_
	DEFB	a_,a_,a_,a_,a_,a_,a_,a_,n,n,n,x,x,x,x,x,x,x,x,x,x,n,n,n,e_,e_,e_,e_,e_,e_,e_,e_
	DEFB	a_,a_,a_,a_,a_,a_,a_,a_,n,x,x,x,x,x,x,x,x,x,x,x,x,x,x,n,e_,e_,e_,e_,e_,e_,e_,e_
	DEFB	a_,a_,a_,a_,a_,a_,a_,a_,n,x,x,x,x,x,x,x,x,x,x,x,x,x,x,n,e_,e_,e_,e_,e_,e_,e_,e_
	DEFB	a_,a_,a_,a_,a_,a_,a_,a_,n,n,n,x,x,x,x,x,x,x,x,x,x,n,n,n,e_,e_,e_,e_,e_,e_,e_,e_
	DEFB	a_,a_,a_,a_,a_,a_,a_,a_,n,n,n,n,n,x,x,x,x,x,x,n,n,n,n,n,e_,e_,e_,e_,e_,e_,e_,e_
	DEFB	a_,a_,a_,a_,a_,a_,a_,n,n,n,n,n,n,n,n,x,x,n,n,n,n,n,n,n,n,e_,e_,e_,e_,e_,e_,e_
	DEFB	a_,a_,a_,a_,a_,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,e_,e_,e_,e_
	DEFB	a_,a_,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,e_,e_
MNFRM
	INCBIN "tv16/intro/mainfram.lpz"

;--------------

gMUS	EQU	59500
bGIMN ;гимн СССР
	DI
	CALL	SW5
	CALL	MEM1
	LD	HL,GIMNs+2
	LD	DE,#4000
	CALL	DELPZ
	LD	HL,GIMNm+2
	LD	DE,gMUS
	CALL	DELPZ
	CALL	gMUS
AXX	EI
	HALT
	CALL	gMUS+6
	DI
	JR	AXX
