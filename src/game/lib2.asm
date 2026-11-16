;-----------Вывод спрайтов героев


XY0pos	LD	A,(X0) ;выч смещ _X0pos в пикс
	CALL	_xy0
	LD	(_X0pos),HL
	LD	A,(Y0)
	CALL	_xy0
	LD	(_Y0pos),HL
	RET
_xy0	LD	L,A
	LD	H,0
	LD	D,H
	LD	E,H
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	EX	DE,HL
	XOR	A
	SBC	HL,DE
	RET

; *M+
	MACRO	HEN_ p0
	POP	DE
	DJNZ	$+5
	JP	SET_SP
	INC	H
	LD	A,H
	AND	7
	JP	NZ,p0
	LD	A,L
	ADD	A,32
	LD	L,A
	JR	C,p0
	LD	A,H
	SUB	8
	LD	H,A
	JR	p0
	ENDM

HE_N	DEFW	HE0,HE1,HE2,HE3,HE4,HE5,HE6,HE7
HE_L	DEFW	SET_SP,HE1L,HE2L,HE3L,HE4L,HE5L,HE6L,HE7L

;HE0L	EQU SET_SP

HE0	LD	A,(HL)
	OR	E
	XOR	D
	LD	(HL),A
; ---- v0.04: changed/new code or data
	POP	DE
	DJNZ	HE0nl
	JP	SET_SP
HE0nl ;probably: следующая строка экрана ZX (INC H; при переходе через знакоместо - добавить #20 к L)
	INC	H
	LD	A,H
	AND	#07
	JP	NZ,HE0
	LD	A,L
	ADD	A,#20
	LD	L,A
	JR	C,HE0
	LD	A,H
	SUB	#08
	LD	H,A
	JR	HE0

HE1	LD	A,E
	RRCA
	LD	C,A
	AND	#7F
	OR	(HL)
	LD	(HL),A
	LD	A,C
	AND	#80
	INC	L
	OR	(HL)
	LD	(HL),A
	LD	A,D
	RRCA
	LD	C,A
	AND	#80
	XOR	(HL)
	LD	(HL),A
	LD	A,C
	AND	#7F
	DEC	L
	XOR	(HL)
	LD	(HL),A
; ---- v0.04: changed/new code or data
	POP	DE
	DJNZ	HE1nl
	JP	SET_SP
HE1nl ;probably: следующая строка экрана ZX, как HE0nl
	INC	H
	LD	A,H
	AND	#07
	JP	NZ,HE1
	LD	A,L
	ADD	A,#20
	LD	L,A
	JR	C,HE1
	LD	A,H
	SUB	#08
	LD	H,A
	JR	HE1


HE2	LD	A,E
	RRCA
	RRCA
	LD	C,A
	AND	#3F
	OR	(HL)
	LD	(HL),A
	LD	A,C
	AND	#C0
	INC	L
	OR	(HL)
	LD	(HL),A
	LD	A,D
	RRCA
	RRCA
	LD	C,A
	AND	#C0
	XOR	(HL)
	LD	(HL),A
	LD	A,C
	AND	#3F
	DEC	L
	XOR	(HL)
	LD	(HL),A
; ---- v0.04: changed/new code or data
	POP	DE
	DJNZ	.HE2_1
	JP	SET_SP
.HE2_1
	INC	H
	LD	A,H
	AND	#07
	JP	NZ,HE2
	LD	A,L
	ADD	A,#20
	LD	L,A
	JR	C,HE2
	LD	A,H
	SUB	#08
	LD	H,A
	JR	HE2

HE3	LD	A,E
	RRCA
	RRCA
	RRCA
	LD	C,A
	AND	#1F
	OR	(HL)
	LD	(HL),A
	LD	A,C
	AND	#E0
	INC	L
	OR	(HL)
	LD	(HL),A
	LD	A,D
	RRCA
	RRCA
	RRCA
	LD	C,A
	AND	#E0
	XOR	(HL)
	LD	(HL),A
	LD	A,C
	AND	#1F
	DEC	L
	XOR	(HL)
	LD	(HL),A
; ---- v0.04: changed/new code or data
	POP	DE
	DJNZ	.HE3_1
	JP	SET_SP
.HE3_1
	INC	H
	LD	A,H
	AND	#07
	JP	NZ,HE3
	LD	A,L
	ADD	A,#20
	LD	L,A
	JR	C,HE3
	LD	A,H
	SUB	#08
	LD	H,A
	JR	HE3

HE4	LD	A,E
	RRCA
	RRCA
	RRCA
	RRCA
	LD	C,A
	AND	#F
	OR	(HL)
	LD	(HL),A
	LD	A,C
	AND	#F0
	INC	L
	OR	(HL)
	LD	(HL),A
	LD	A,D
	RRCA
	RRCA
	RRCA
	RRCA
	LD	C,A
	AND	#F0
	XOR	(HL)
	LD	(HL),A
	LD	A,C
	AND	#F
	DEC	L
	XOR	(HL)
	LD	(HL),A
; ---- v0.04: changed/new code or data
	POP	DE
	DJNZ	.HE4_1
	JP	SET_SP
.HE4_1
	INC	H
	LD	A,H
	AND	#07
	JP	NZ,HE4
	LD	A,L
	ADD	A,#20
	LD	L,A
	JR	C,HE4
	LD	A,H
	SUB	#08
	LD	H,A
	JR	HE4

HE5	LD	A,E
	RLCA
	RLCA
	RLCA
	LD	C,A
	AND	#7
	OR	(HL)
	LD	(HL),A
	LD	A,C
	AND	#F8
	INC	L
	OR	(HL)
	LD	(HL),A
	LD	A,D
	RLCA
	RLCA
	RLCA
	LD	C,A
	AND	#F8
	XOR	(HL)
	LD	(HL),A
	LD	A,C
	AND	#7
	DEC	L
	XOR	(HL)
	LD	(HL),A
; ---- v0.04: changed/new code or data
	POP	DE
	DJNZ	.HE5_1
	JP	SET_SP
.HE5_1
	INC	H
	LD	A,H
	AND	#07
	JP	NZ,HE5
	LD	A,L
	ADD	A,#20
	LD	L,A
	JR	C,HE5
	LD	A,H
	SUB	#08
	LD	H,A
	JR	HE5

HE6	LD	A,E
	RLCA
	RLCA
	LD	C,A
	AND	#3
	OR	(HL)
	LD	(HL),A
	LD	A,C
	AND	#FC
	INC	L
	OR	(HL)
	LD	(HL),A
	LD	A,D
	RLCA
	RLCA
	LD	C,A
	AND	#FC
	XOR	(HL)
	LD	(HL),A
	LD	A,C
	AND	#3
	DEC	L
	XOR	(HL)
	LD	(HL),A
; ---- v0.04: changed/new code or data
	POP	DE
	DJNZ	.HE6_1
	JP	SET_SP
.HE6_1
	INC	H
	LD	A,H
	AND	#07
	JP	NZ,HE6
	LD	A,L
	ADD	A,#20
	LD	L,A
	JR	C,HE6
	LD	A,H
	SUB	#08
	LD	H,A
	JR	HE6

HE7	LD	A,E
	RLCA
	LD	C,A
	AND	#1
	OR	(HL)
	LD	(HL),A
	LD	A,C
	AND	#FE
	INC	L
	OR	(HL)
	LD	(HL),A
	LD	A,D
	RLCA
	LD	C,A
	AND	#FE
	XOR	(HL)
	LD	(HL),A
	LD	A,C
	AND	#1
	DEC	L
	XOR	(HL)
	LD	(HL),A
; ---- v0.04: changed/new code or data
	POP	DE
	DJNZ	.HE7_1
	JP	SET_SP
.HE7_1
	INC	H
	LD	A,H
	AND	#07
	JP	NZ,HE7
	LD	A,L
	ADD	A,#20
	LD	L,A
	JR	C,HE7
	LD	A,H
	SUB	#08
	LD	H,A
	JR	HE7

HE1L	LD	A,E
	RRCA
	AND	#80
	OR	(HL)
	LD	(HL),A
	LD	A,D
	RRCA
	AND	#80
	XOR	(HL)
	LD	(HL),A
; ---- v0.04: changed/new code or data
	POP	DE
	DJNZ	.HE1L_1
	JP	SET_SP
.HE1L_1
	INC	H
	LD	A,H
	AND	#07
	JP	NZ,HE1L
	LD	A,L
	ADD	A,#20
	LD	L,A
	JR	C,HE1L
	LD	A,H
	SUB	#08
	LD	H,A
	JR	HE1L


HE2L	LD	A,E
	RRCA
	RRCA
	AND	#C0
	OR	(HL)
	LD	(HL),A
	LD	A,D
	RRCA
	RRCA
	AND	#C0
	XOR	(HL)
	LD	(HL),A
; ---- v0.04: changed/new code or data
	POP	DE
	DJNZ	.HE2L_1
	JP	SET_SP
.HE2L_1
	INC	H
	LD	A,H
	AND	#07
	JP	NZ,HE2L
	LD	A,L
	ADD	A,#20
	LD	L,A
	JR	C,HE2L
	LD	A,H
	SUB	#08
	LD	H,A
	JR	HE2L

HE3L	LD	A,E
	RRCA
	RRCA
	RRCA
	AND	#E0
	OR	(HL)
	LD	(HL),A
	LD	A,D
	RRCA
	RRCA
	RRCA
	AND	#E0
	XOR	(HL)
	LD	(HL),A
; ---- v0.04: changed/new code or data
	POP	DE
	DJNZ	.HE3L_1
	JP	SET_SP
.HE3L_1
	INC	H
	LD	A,H
	AND	#07
	JP	NZ,HE3L
	LD	A,L
	ADD	A,#20
	LD	L,A
	JR	C,HE3L
	LD	A,H
	SUB	#08
	LD	H,A
	JR	HE3L

HE4L	LD	A,E
	RRCA
	RRCA
	RRCA
	RRCA
	AND	#F0
	OR	(HL)
	LD	(HL),A
	LD	A,D
	RRCA
	RRCA
	RRCA
	RRCA
	AND	#F0
	XOR	(HL)
	LD	(HL),A
; ---- v0.04: changed/new code or data
	POP	DE
	DJNZ	.HE4L_1
	JP	SET_SP
.HE4L_1
	INC	H
	LD	A,H
	AND	#07
	JP	NZ,HE4L
	LD	A,L
	ADD	A,#20
	LD	L,A
	JR	C,HE4L
	LD	A,H
	SUB	#08
	LD	H,A
	JR	HE4L

HE5L	LD	A,E
	RLCA
	RLCA
	RLCA
	AND	#F8
	OR	(HL)
	LD	(HL),A
	LD	A,D
	RLCA
	RLCA
	RLCA
	AND	#F8
	XOR	(HL)
	LD	(HL),A
; ---- v0.04: changed/new code or data
	POP	DE
	DJNZ	.HE5L_1
	JP	SET_SP
.HE5L_1
	INC	H
	LD	A,H
	AND	#07
	JP	NZ,HE5L
	LD	A,L
	ADD	A,#20
	LD	L,A
	JR	C,HE5L
	LD	A,H
	SUB	#08
	LD	H,A
	JR	HE5L

HE6L	LD	A,E
	RLCA
	RLCA
	AND	#FC
	OR	(HL)
	LD	(HL),A
	LD	A,D
	RLCA
	RLCA
	AND	#FC
	XOR	(HL)
	LD	(HL),A
; ---- v0.04: changed/new code or data
	POP	DE
	DJNZ	.HE6L_1
	JP	SET_SP
.HE6L_1
	INC	H
	LD	A,H
	AND	#07
	JP	NZ,HE6L
	LD	A,L
	ADD	A,#20
	LD	L,A
	JR	C,HE6L
	LD	A,H
	SUB	#08
	LD	H,A
	JR	HE6L

HE7L	LD	A,E
	RLCA
	AND	#FE
	OR	(HL)
	LD	(HL),A
	LD	A,D
	RLCA
	AND	#FE
	XOR	(HL)
	LD	(HL),A
; ---- v0.04: changed/new code or data
	POP	DE
	DJNZ	.HE7L_1
	JP	SET_SP
.HE7L_1
	INC	H
	LD	A,H
	AND	#07
	JP	NZ,HE7L
	LD	A,L
	ADD	A,#20
	LD	L,A
	JR	C,HE7L
	LD	A,H
	SUB	#08
	LD	H,A
	JR	HE7L

BCOORD	LD	A,D ;de(0-191,0-31) -- hl
	RRCA
	RRCA
	RRCA
	AND	%00011000
	LD	H,A
	LD	A,D
	AND	%00000111
	ADD	A,H
	ADD	A,DSCR/256
	LD	H,A
	LD	A,D
	RLA
	RLA
	AND	%11100000
	OR	E
	LD	L,A
	RET

_XSEL ;выв.рамки героя IX
	XOR	A
	INC	A
	JR	_XPUT

XPUT ;формированиe вывода для героя IX
	XOR	A
_XPUT	EX	AF,AF' ;Z-герой, NZ-(A=1:рамка/A=2:снаряд)
	LD	L,(IX-2) ;получение Xh Yh SHIFTh
	LD	H,(IX-1)
	LD	DE,(_Y0pos)
	ADD	HL,DE
	LD	A,H
	OR	A
	RET	NZ
	LD	A,L
	CP	192+32 ;24
	RET	NC
	LD	(Yh),A
	LD	L,(IX-4)
	LD	H,(IX-3)
	LD	DE,(_X0pos)
	ADD	HL,DE
	LD	A,H
	OR	A
	JR	NZ,UT3
	LD	A,L
	CP	192
	RET	NC
	LD	L,A
	SRL	L
	JR	UT2
UT3	INC	A
	RET	NZ
	LD	A,L
	CP	192+32 ;40
	RET	C
	LD	L,A
	SRA	L
UT2	AND	7
	LD	(SHIFTh),A
	SRA	L
	SRA	L
	LD	A,L
	JP	M,UT21
	CP	24
	RET	NC
	JR	UT22
UT21	CP	-8
	RET	C
UT22	LD	(Xh),A
;получть Wh,Hh,IMGh, выбрать страницу
;	--------------------
	EX	AF,AF'
; ---- v0.04: changed/new code or data
	JR	Z,WY_0
	DEC	A
	JR	Z,UT22+15
	CALL	MEM4
	JP	WYbull ;->обр снарядов
; ---- v0.04: changed/new code or data
	LD	A,#03
;для рамки
WYrama	CALL	MEM
	CALL	IMHER3
	CP	10
	JR	NC,WYr33
	CP	7
	LD	L,14
	JR	C,WYr22
	LD	L,22
WYr22	LD	BC,#302
	LD	DE,fr2x2L
	PUSH	BC
	PUSH	HL
	LD	HL,(Xh)
	PUSH	HL
	CALL	HeF1
	POP	HL
	LD	(Xh),HL
	LD	A,H
	POP	HL
	SUB	L
	LD	(Yh),A
	POP	BC
	RET	C
	LD	DE,fr2x2H
	JP	HeF1
WYr33	LD	BC,#303
	LD	DE,fr3x3L
	PUSH	BC
	LD	HL,(Xh)
	PUSH	HL
	CALL	HeF1
	POP	HL
	LD	A,H
	SUB	22
	LD	H,A
	LD	(Xh),HL
	POP	BC
	RET	C
	LD	DE,fr3x3H
	JP	HeF1
WY_0	LD	A,(IX+x)
	OR	A
	LD	A,(IX+typ)
	JR	NZ,WY2
;для трупа
	CP	16
	JR	C,WYTr
	CALL	MEM4 ;труп танка
	LD	DE,WM33+1152
	LD	BC,#1803
	JP	HeF1
WYTr	ADD	A,A
	ADD	A,A
	ADD	A,A
	LD	L,A
	LD	H,0
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	LD	DE,WM22
	ADD	HL,DE
	EX	DE,HL
	CALL	MEM4
	LD	BC,#1002
	JP	HeF1
;
WY2 ;----для героев
	LD	HL,IM_HER
	CALL	DA
	LD	E,(HL)
	INC	HL
	LD	D,(HL) ;изображение -> DE
	INC	HL
	LD	A,(HL)
	OR	A ;тень?
	CALL	NZ,MEM
	INC	HL
	LD	A,(HL)
	LD	HL,IM_TYP
	CALL	WT
	LD	A,(IX+3) ;фаза -> A
	LD	C,(IX+dir) ;напр -> C
	JP	(HL)

IMHER3	LD	A,(IX+4) ;тип объекта
_MHER3	LD	HL,IM_HER+3
	JP	DA

IM_HER ;парам. спрайтов героев - адр2,стр1,тип1

	DEFW	hrh0,#004,hrh0+1024,#104,hrh0+1536,#104,hrh3,#201
	DEFB	#00,#C0,#03,#02,#B0,#ED,#03,#09,#B0,#E7,#03,#08,#B0,#CE,#03,#05,#B0,#D4,#03,#04
	DEFB	#80,#CD,#04,#0A,#B0,#C5,#03,#0C,#B0,#DE,#03,#0C

	DEFB	#80,#C1,#04,#06,#80,#C5,#04,#01,#80,#C7,#04,#01,#B0,#DA,#03,#02
	DEFB	#00,#C0,#04,#03,#8F,#DF,#06,#07,#B0,#F9,#03,#05,#80,#D6,#04,#04,#B0,#F3,#03,#04
	DEFB	#8F,#D6,#06,#0C,#8F,#CD,#06,#0C,#00,#C4,#03,#0B
	DEFB	#00,#B8,#00,#0D,#80,#C9,#04,#0E

IM_TYP ;обработка спрайтов героев по типу
	DEFW	IM_T0,IM_T1,IM_T2,IM_T3,IM_T4,IM_T5
	DEFW	IM_T6,IM_T7,IM_T8,IM_T9,IM_TA,IM_TB,IM_TC,IS_TD,Ib_TE ;тень

;------2x2--

IM_T6 ;\
IM_T0 ;работники
	CP	#A0
	JR	C,IM_T1
	LD	A,%10
im_t00	ADD	A,D
	LD	D,A
;
IM_T1 ;работники с грузом
	LD	L,0
	SRL	C
	RR	L
	SRL	C
	RR	L
	LD	H,C
	ADD	HL,DE
	EX	DE,HL
	LD	BC,#1002
	JP	HeF1

IM_T2 ;автоматчики/огнемётчики/кунги
	CP	#80
	JR	C,im_t21
im_t20	XOR	A
im_t21	AND	1
	ADD	A,C
	ADD	A,C
	LD	C,A
	JR	IM_T1

IM_T3 ;кракотун
	LD	A,(TIC6)
	LD	C,A
	JR	IM_T1
; ---- v0.04: changed/new code or data
IM_T4
IM_T5
	CP	#80
	JR	C,im_t21
	CP	#A0
	JR	C,im_t20
	LD	A,#04
	JR	im_t00

;;IM_T5   ;\ланголетта
;;IM_T4   ;волшебники/предводители
;;	  CP #80
;;	  JR C,im_t21
;;	  CP #A0
;;	  JR C,im_t20
;;	  LD A,%100
;;	  JR im_t00

;-----3x3--

IM_TC ;авиация
	LD	A,C
	CPL
	LD	C,A
im_tc0	ADD	A,A
	ADD	A,A
	ADD	A,A
	ADD	A,C ;x9
	LD	L,A
	LD	H,0
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL ;x144
	ADD	HL,DE
	EX	DE,HL
	LD	BC,#1803
	JP	HeF1

IM_TB ;гнездолёт
	LD	A,(TIC3)
	LD	C,A
	JR	im_tc0

IM_TA ;танк
	CP	#80
	JR	C,im_tA1
	XOR	A
im_tA1	AND	1
	ADD	A,C
	ADD	A,C
	LD	C,A
	CALL	im_tc0
	LD	(IX+typ),25
	LD	A,(IX+dir)
	LD	HL,I_dBOD
	CALL	WT
	EX	DE,HL
	LD	A,(IX+dir)
	ADD	A,A
	ADD	A,(IX+energy) ;башн
	AND	15
	LD	HL,I_dTOW
	CALL	WT
	LD	A,L
	ADD	A,E
	LD	E,A
	LD	A,H
	ADD	A,D
	LD	D,A
	PUSH	DE
	XOR	A
	CALL	CORix_
	CALL	XPUT
	POP	DE
	LD	A,E
	NEG
	LD	E,A
	LD	A,D
	NEG
	LD	D,A
	XOR	A
	CALL	CORix_
	LD	(IX+typ),9
	RET

I_dTOW ;смещение башни  X,Y
	DEFB	0,0,2,0,2,0,2,0,3,0,2,-5,2,-5,2,-5
	DEFB	0,-5,-2,-5,-2,-5,-2,-5,-3,0,-2,0,-2,0,-2,0
I_dBOD ;смещ. на корпусe
	DEFB	4,-2,4+1,-1-2,4,-2-2,1+4,-2-4
	DEFB	4,-2-3,-1+4,-2-4,-1+4,-2-2,4-1,-2-1

Ib_TE ;башня
	LD	A,(IX+dir)
	ADD	A,A
	ADD	A,(IX+energy) ;здесь - напр башни
	AND	15
	LD	C,A
	JP	IM_T1

;----тень-3x3--


IS_TD ;в (BUF512) - адрес тени
	LD	A,(aviSHD)
; ---- v0.04: changed/new code or data
	CP	#03
	JR	NZ,IS_TD+22
	LD	HL,(BUF512)
	CALL	is_tdp
	LD	DE,BUF512
	LD	BC,#1803
	JP	HeF1
; ---- v0.04: changed/new code or data
	DEC	A
	JR	NZ,is_t0x+14
is_td0 ;упрощённые тени
	BIT	0,(IX-4)
	JR	Z,is_t0x
	BIT	0,(IX-2)
	DEFB	#11,#8F,#E8
; ---- v0.04: changed/new code or data
	JR	Z,is_td2+5
	LD	DE,v4_mmf1_23
; ---- v0.04: changed/new code or data
	JR	is_td2+5
is_t0x	BIT	0,(IX-2)
	DEFB	#11,#4F,#E9
; ---- v0.04: changed/new code or data
	JR	Z,is_td2+5
	LD	DE,#FEE2
	JR	is_td2
	LD	DE,#FF42
is_td2	CALL	MEM1
; ---- v0.04: changed/new code or data (4.Z80: is_td1)
	JR	is_tdS
is_td1	; (в v0.04 код удалён, метка сохранена для ссылок)
	CALL	MEM6
is_tdS	LD	BC,#1003
	JR	HeF1

is_tdp	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	INC	HL
	LD	(SET_SP+1),SP
	LD	SP,HL
	LD	HL,BUF512
	XOR	A
	LD	B,18
is_tdL	LD	(HL),E
	INC	L
	INC	L
	POP	DE
	LD	(HL),E
	INC	L
	INC	L
	POP	DE
	LD	(HL),E
	INC	L
	INC	L
	POP	DE
	LD	(HL),E
	INC	L
	INC	L
	POP	DE
	DJNZ	is_tdL
	LD	(BUF512+1),A
	JP	SET_SP
;-----2x3--

IM_T8 ;стингер
	LD	A,(IX+com)
	OR	A
	JR	NZ,im_t81
	LD	A,(TIC)
	XOR	(IX+dir)
	RRCA
	JR	C,im_t81
	INC	(IX+dir)
	RES	4,(IX+dir)
im_t81	LD	A,C

im_t80	ADD	A,A
	ADD	A,C ;x3
	ADD	A,A ;
	ADD	A,A ;x12
	LD	L,A
	LD	H,0
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL ;96
	ADD	HL,DE
	EX	DE,HL
	LD	BC,#1802
	JR	HeF1

IM_T9 ;walker
	CP	#80
	JR	C,im_t91
im_t90	XOR	A
im_t91	AND	1
	ADD	A,C
	ADD	A,C
	LD	C,A
	JR	im_t80

IM_T7 ;демон
	CP	#80
	JR	C,im_t91
	CP	#A0
	JR	C,im_t90
	LD	A,%110
	ADD	A,D
	LD	D,A
	JR	IM_T8

;	--------------------
HeF1 ;корректировка ширины,длины и др. по границам окна
	LD	(Wh),BC
	LD	HL,(Xh)
	LD	A,H
	SUB	B
	LD	(Yh),A
	LD	A,L
	CP	24
	JR	NC,eF3
	SUB	24
	NEG
	CP	C
	JR	NC,eF4
	LD	C,A
	JR	eF4
eF3	INC	A
	LD	L,A
	ADD	A,C
	RET	M
	RET	Z
	LD	C,A
	LD	A,-1
	LD	(Xh),A
	LD	A,L
	NEG
	LD	L,A
	JR	Z,eF4
	XOR	A
eF5	ADD	A,B
	ADD	A,B
	DEC	L
	JR	NZ,eF5
	ADD	A,E
	LD	E,A
	JR	NC,eF4
	INC	D
eF4	LD	A,(Yh)
	CP	192
	JR	NC,eF1
	SUB	192
	NEG
	CP	B
	JR	NC,eF2
	LD	B,A
	JR	eF2
eF1	LD	L,A
	ADD	A,B
	RET	M
	RET	Z
	LD	B,A
	XOR	A
	LD	(Yh),A
	LD	A,L
	NEG
	ADD	A,A
	ADD	A,E
	LD	E,A
	JR	NC,eF2
	INC	D
eF2 ;собств вывод
	PUSH	DE
	LD	HL,HE_N
	LD	DE,(Xh)
	BIT	7,E
	JR	Z,HRU8
	LD	HL,HE_L
	LD	E,0
HRU8	EX	AF,AF'
	LD	A,(SHIFTh)
	CALL	WT
	LD	(JP_SUB+1),HL
	CALL	BCOORD
	POP	DE
HRU0	PUSH	HL
	PUSH	DE
	PUSH	BC
	LD	(IMGh),HL
	CALL	HRUp
	POP	BC
	POP	DE
	POP	HL
	DEC	C
	JR	Z,HRU5
	EX	AF,AF'
	JR	NZ,HRUm
	INC	L
	JR	HRUm1
HRUm	LD	A,(SHIFTh)
	PUSH	HL
	LD	HL,HE_N
	CALL	WT
	LD	(JP_SUB+1),HL
	POP	HL
HRUm1	XOR	A
	EX	AF,AF'
	LD	A,(Hh)
	ADD	A,A
	ADD	A,E
	LD	E,A
	JR	NC,HRU0
	INC	D
	JR	HRU0

HRU5	RET

HRUp	EX	DE,HL
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	INC	HL
	LD	(SET_SP+1),SP
	LD	SP,HL
	LD	HL,(IMGh)
	JP	JP_SUB

;/////////////////////видеосортировка/////////////////////

;vBUF	EQU BUF512 ;выровнен на #100!
;256 - eсть в строке?(ptr+1/0); 256 - 1..2:IX, 3й:next+1/null
vSORT ;видео сортировка
	LD	HL,vBUF
	LD	DE,vBUF+1
	LD	BC,255
	LD	(HL),0
	LDIR
;
	EXX
	LD	HL,vBUF+1+256
	EXX
	LD	IX,HUMAN ;сортировка персонажей
	LD	B,_NALL
vS0	LD	A,(IX+x)
	OR	A
	JR	Z,vS6
	LD	L,(IX-4)
	LD	H,(IX-3)
	LD	DE,(_X0pos)
	ADD	HL,DE
	LD	A,H
	OR	A
	JR	NZ,vS3
	LD	A,L
	CP	192
	JR	NC,vS1
	JR	vS4
vS6	LD	A,(IX+y)
	OR	A
	JR	Z,vS1
	LD	L,0
	JR	vS4_
vS3	INC	A
	JR	NZ,vS1
	LD	A,L
	CP	192+40
	JR	C,vS1
vS4	LD	L,(IX-2)
	LD	H,(IX-1)
	LD	DE,(_Y0pos)
	ADD	HL,DE
	LD	A,H
	OR	A
	JR	NZ,vS1
	LD	A,L
	CP	192+24
	JR	NC,vS1
vS4_	isAVIA_
	JR	Z,vS7
	LD	L,_avia ;авиа - выше всех
vS7	LD	H,vBUF/256
	LD	A,(HL) ;вставить первым эл-том списка
	EXX
	PUSH	IX
	POP	DE
	LD	(HL),E
	INC	L
	LD	(HL),D
	INC	L
	LD	(HL),A
	LD	A,L
	INC	L
	EXX
	LD	(HL),A
	RET	Z ;более 83 героев в экране
vS1	LD	DE,_LHER
	ADD	IX,DE
	DJNZ	vS0
	RET


vXPUT ;------------------- отсорт вывод
	LD	HL,vBUF
vX0	LD	A,(HL)
	OR	A
	JR	Z,vX1
	PUSH	HL
	LD	H,(vBUF/256)+1
vX2	LD	L,A
	PUSH	HL
	DEC	L
	LD	D,(HL)
	DEC	L
	LD	E,(HL)
	PUSH	DE
	POP	IX
	BIT	7,D
	JR	NZ,vXB
	CALL	XPUT ;вывод героев
vX3	POP	HL
	LD	A,(HL)
	OR	A
	JR	NZ,vX2
	POP	HL
vX1	LD	A,L
	INC	L
	CP	_gbul
	JR	C,vX0
	CALL	Z,vXF
	CP	_abul
	JR	C,vX0
	RET
;
vXB	LD	A,2 ;nz
	CALL	_XPUT ;вывод снарядов
	JR	vX3

vXF	PUSH	AF
	PUSH	HL
	CALL	MEM4
	CALL	vFLAME ;выв огня пожаров
	POP	HL
	POP	AF
	RET

vrYLF	LD	A,#D8 ;---------- сортировка с ограничителями
	LD	HL,#1000
	JR	vrYs
vrYRT	LD	A,#FF
	LD	HL,SCR+#98
vrYs	LD	DE,ATR
	JR	vr_
vrXUP	LD	DE,#2800
	JR	vrXs
vrXDW	LD	DE,ATR+#B0
vrXs	LD	A,#D8
	LD	HL,SCR
vr_	CALL	vrSET
;сортировка по окну
	LD	HL,vBUF
	LD	DE,vBUF+1
	LD	BC,255
	LD	(HL),0
	LDIR
;
	EXX
	LD	HL,vBUF+256
	EXX
	LD	IX,HUMAN
	LD	B,_NALL
vrS0	LD	A,(IX)
	OR	A
	JR	Z,vrS6
	LD	L,(IX-4)
	LD	H,(IX-3)
	LD	DE,(_X0pos)
	ADD	HL,DE
	LD	A,H
	OR	A
	JR	NZ,vrS3
	LD	A,L
vrH	CP	0 ;<-H
	JR	NC,vrS1
vrL	CP	0 ;<-L
	JR	C,vrS1
	JR	vrS4
vrS6	LD	A,(IX+y)
	OR	A
	JR	Z,vrS1
	LD	L,0
	JR	vrS4_
vrS3	INC	A
	JR	NZ,vrS1
	LD	A,L
vrA	CP	0 ;<-A
	JR	C,vrS1
vrS4	LD	L,(IX-2)
	LD	H,(IX-1)
	LD	DE,(_Y0pos)
	ADD	HL,DE
	LD	A,H
	OR	A
	JR	NZ,vrS1
	LD	A,L
vrD	CP	0 ;<-D
	JR	NC,vrS1
vrE	CP	0 ;<-E
	JR	C,vrS1
vrS4_	isAVIA_
	JR	Z,vrS7
	LD	L,_avia ;авиа - выше всех
vrS7	LD	H,vBUF/256
	LD	A,(HL)
	EXX
	PUSH	IX
	POP	DE
	LD	(HL),E
	INC	L
	LD	(HL),D
	INC	L
	LD	(HL),A
	LD	A,L
	INC	L
	EXX
	LD	(HL),A
	JR	Z,vrS51 ;более 83 героев в экране
vrS1	LD	DE,_LHER
	ADD	IX,DE
	DJNZ	vrS0
vrS51	XOR	A
	LD	L,A
	LD	H,A
	LD	D,A
	LD	E,A
;
vrSET	LD	(vrA+1),A
	LD	A,L
	LD	(vrL+1),A
	LD	A,H
	LD	(vrH+1),A
	LD	A,E
	LD	(vrE+1),A
	LD	A,D
	LD	(vrD+1),A
	RET

outSEL ;выв выбр об'ектов и рамки цели
	CALL	STD
	LD	HL,sel_ti
	LD	A,(HL)
	OR	A
	JR	Z,uS3
	DEC	(HL)
	LD	A,(TIC)
	RRCA
	JR	C,uS3
	DEC	HL
	LD	A,(HL)
	BIT	7,A
	JR	NZ,uS5
;рамка героя-цели
	CALL	N_IX
	OR	A
	JR	Z,uS3
	CALL	_XSEL
	JR	uS3
uS5 ;рамка здания-цели
	AND	#7F
	CALL	uS6
uS3	LD	A,(SEL_T) ;объекты
	OR	A
	RET	Z
	LD	HL,SEL_N
	CP	7
	JR	C,uS4
	JR	NZ,uS1
	LD	A,1
uS4	LD	B,A
uS0	PUSH	BC
	PUSH	HL
	LD	A,(HL)
	CALL	N_IX
	CALL	_XSEL
	POP	HL
	INC	HL
	POP	BC
	DJNZ	uS0
	RET
uS1 ;выд.здания
	LD	A,(HL)
uS6	CALL	B_IX
	LD	A,(IX+x)
	OR	A
	JP	NZ,_BPUT
	RET

B_IX ;получить IX здания по номеру А (7й бит отбрасывается)
;в A - возвращается (IX+x)
	PUSH	HL
	PUSH	DE
	ADD	A,A
	LD	L,A
	LD	H,0
	ADD	HL,HL
	ADD	HL,HL
	LD	DE,MINE
	ADD	HL,DE
	PUSH	HL
	POP	IX
	LD	A,(HL)
	POP	DE
	POP	HL
	RET

N_IX ;получить IX героя по номеру А
;в А - возвращается (IX+x), в IX,HL - адрес данных героя
	LD	H,0
	LD	L,A
	ADD	A,A ;x2
	ADD	A,L ;x3
	LD	L,A
	RL	H
	ADD	HL,HL ;x6
	ADD	HL,HL ;x12
	ADD	HL,HL ;х24
	LD	A,HUMAN%256
	ADD	A,L
	LD	L,A
	DEFB	#DD ;
	LD	L,A ;IXl<-A
	LD	A,HUMAN/256
	ADC	A,H
	LD	H,A
	DEFB	#DD ;
	LD	H,A ;IXh<-A
	LD	A,(HL)
	RET

_BPUT ;выв рамки выбора зд
	CALL	HL_IX0
	LD	A,(IX+2)
	DEC	L
	INC	H ;/8
	PUSH	HL
	LD	DE,#40C0
	CALL	bJ0v
	LD	DE,MAP
	CALL	C,bJ1h_
	POP	HL
	INC	L ;/7
	PUSH	HL
	LD	D,#00
	CALL	bJ0h_
	POP	HL
	INC	L ;/6
	PUSH	HL
	LD	DE,#0203
	CALL	bJ1v
	LD	DE,#0001
	DEC	L
	CALL	C,bJ1h_
	POP	HL
	DEC	H ;/5
	PUSH	HL
	LD	DE,#0203
	CALL	bJ1v
	POP	HL
	DEC	H ;/4
	PUSH	HL
	CALL	bJ1v
	LD	DE,#0001
	DEC	L
	CALL	C,bJ1h
	POP	HL
	DEC	L ;/3
	PUSH	HL
	LD	DE,#0000
	CALL	bJ0h
	POP	HL
	DEC	L ;/2
	PUSH	HL
	LD	DE,#40C0
	CALL	bJ0v
	LD	DE,MAP
	CALL	C,bJ1h
	POP	HL
	INC	H ;/1
	LD	DE,#40C0
	JR	bJ0v

bJ0h_ ;снизу
	CALL	bJadr
	RET	NC
bJ1h_	LD	A,L
	ADD	A,32
	LD	L,A
	LD	A,H
	ADD	A,6
	LD	H,A
	CALL	bJ100
	LD	D,E
	DEC	H
	INC	L
bJ100	XOR	A
	XOR	D
	LD	(HL),A
	INC	H
	LD	(HL),#FF
	SCF
	RET

bJ0h	CALL	bJadr ;выв гориз
	RET	NC
bJ1h	CALL	bJ200
	LD	D,E
	DEC	H
	INC	L
bJ200	LD	(HL),#FF
	INC	H
	XOR	A
	XOR	D
	LD	(HL),A
	SCF
	RET

bJ1v	CALL	bJadr
	RET	NC
	INC	L
	JR	bJ002
bJ0v ;выв верт лин для здан (HL-adr в map;DE-изобр/маска)
	CALL	bJadr
	RET	NC
bJ002	PUSH	HL
	CALL	bJ000
	LD	A,H
	SUB	8
	LD	H,A
	LD	A,L
	ADD	A,32
	LD	L,A
	CALL	bJ000
	POP	HL
	SCF
	RET
bJ000	LD	B,2
bJ001	LD	A,(HL) ;
	OR	E
	XOR	D
	LD	(HL),A
	INC	H
	LD	A,(HL) ;
	OR	E
	XOR	D
	LD	(HL),A
	INC	H
	LD	A,(HL) ;
	OR	E
	XOR	D
	LD	(HL),A
	INC	H
	LD	A,(HL) ;
	OR	E
	XOR	D
	LD	(HL),A
	INC	H
	DJNZ	bJ001
	RET

bJadr	LD	BC,(X0) ;выч адр (NC/C-out/ok)
	LD	A,L
	SUB	C
	CP	12
	RET	NC
	LD	L,A
	LD	A,H
	SUB	B
	CP	12
	RET	NC
	LD	H,A
	ADD	HL,HL
	PUSH	DE
	EX	DE,HL
	CALL	SCOORD
	POP	DE
	XOR	A
	CCF
	RET

;вывод теней авиации
avSHDW	LD	DE,ATR
	JR	avXs
avYLF	LD	A,#D8 ;ограничители
	LD	HL,#1000
	JR	avYs
avYRT	LD	HL,SCR+#98
	LD	A,#FF
avYs	LD	DE,ATR
	JR	av_
avXUP	LD	DE,#2800
	JR	avXs
avXDW	LD	DE,ATR+#B0
avXs	LD	A,#D8
	LD	HL,SCR
av_	CALL	avSET
	CALL	XY0pos
	LD	A,(aviSHD)
	OR	A
	JP	Z,avNSET
;очистка маски
	LD	HL,BUF512+1
	XOR	A
	LD	B,24
avc_	LD	(HL),A
	INC	L
	INC	L
	LD	(HL),A
	INC	L
	INC	L
	LD	(HL),A
	INC	L
	INC	L
	DJNZ	avc_
;обрезание по окну
	LD	IX,HUMAN
	LD	B,_NALL
avS0	isAVIA_
	JP	Z,avS1L ;не самолёт
;смещение тени
	LD	A,(IX-4)
	ADD	A,10
	LD	(IX-4),A
	JR	NC,avSh0
	INC	(IX-3)
avSh0	LD	A,(IX-2)
	ADD	A,15
	LD	(IX-2),A
	JR	NC,avShd
	INC	(IX-1)
avShd	LD	L,(IX-4)
	LD	H,(IX-3)
	LD	DE,(_X0pos)
	ADD	HL,DE
	LD	A,H
	OR	A
	JR	NZ,avS3
	LD	A,L
avH	CP	0 ;<-H
	JR	NC,avS1
avL	CP	0 ;<-L
	JR	C,avS1
	JR	avS4
avS3	INC	A
	JR	NZ,avS1
	LD	A,L
avA	CP	0 ;<-A
	JR	C,avS1
avS4	LD	L,(IX-2)
	LD	H,(IX-1)
	LD	DE,(_Y0pos)
	ADD	HL,DE
	LD	A,H
	OR	A
	JR	NZ,avS1
	LD	A,L
avD	CP	0 ;<-D
	JR	NC,avS1
avE	CP	0 ;<-E
	JR	C,avS1
;вывести тень
	LD	C,(IX+4)
	PUSH	BC
;тип 24-тень
	LD	(IX+4),24
;выв тени
	LD	A,(aviSHD)
; ---- v0.04: changed/new code or data
	CP	#03
	LD	A,C
	CALL	Z,avsh_
	CALL	XPUT
	POP	BC
	LD	(IX+4),C
avS1 ;отменить смещение тени
	LD	A,(IX-4)
	SUB	10
	LD	(IX-4),A
	JR	NC,avS2L
	DEC	(IX-3)
avS2L	LD	A,(IX-2)
	SUB	15
	LD	(IX-2),A
	JR	NC,avS1L
	DEC	(IX-1)
avS1L	LD	DE,_LHER
	ADD	IX,DE
	DEC	B
	JP	NZ,avS0
avNSET	XOR	A
	LD	L,A
	LD	H,A
	LD	D,A
	LD	E,A
;
avSET	LD	(avA+1),A
	LD	A,L
	LD	(avL+1),A
	LD	A,H
	LD	(avH+1),A
	LD	A,E
	LD	(avE+1),A
	LD	A,D
	LD	(avD+1),A
	RET

avsh_	LD	HL,IM_HER
	CALL	DA
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	INC	HL
	LD	A,(HL)
	CALL	MEM
	INC	HL
	LD	A,(HL)
	CP	12
	JR	Z,avst12
;гнездолёт
	LD	A,(TIC3)
	LD	C,A
	JR	avst11
avst12 ;авиация
	LD	A,(IX+dir)
	CPL
	LD	C,A
avst11	ADD	A,A
	ADD	A,A
	ADD	A,A
	ADD	A,C ;x9
	LD	L,A
	LD	H,0
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL ;x144
	ADD	HL,DE
;
	LD	(BUF512),HL
	RET

