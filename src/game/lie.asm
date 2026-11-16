;==ВЫВОД ИНДИКАТОРОВ, КНОПОК, НАДПИСЕЙ...

;-------------индикаторы здоровья/энергии/прогресса

indSYM	DEFB	#00,#AA,#D5,#AA,#55,#AA
	DEFB	#3E,#C1,#DF,#C2,#5F,#C1
	DEFB	#32,#CD,#CB,#F7,#69,#D9

oINDY ;выв инд
	LD	HL,SCR+189
	LD	BC,IND1
	CALL	oIND_
	LD	A,(IND1)
	CP	7 ;покрась индик
	LD	HL,#6058
	JR	NC,oinC
	LD	L,#50
oinC	LD	(ATR+189),HL
	LD	(ATR+221),HL
	LD	A,(IND2TP)
	OR	A
	PUSH	AF
	LD	DE,indSYM
	CP	1
	JR	C,oiL1
	LD	DE,indSYM+6
	JR	Z,oiL1
	LD	DE,indSYM+12
oiL1	LD	HL,SCR+158
	LD	B,6
oinL	LD	A,(DE)
	LD	(HL),A
	INC	DE
	INC	H
	DJNZ	oinL
	POP	AF
	LD	HL,SCR+190
	JR	NZ,oin0
	LD	B,16
	LD	DE,%0000100011111111
	JR	oin3
oin0	LD	BC,IND2
oIND_	PUSH	HL
	LD	A,(BC)
	INC	BC
	LD	L,A
	LD	H,0
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL ;x16
	EX	DE,HL
	LD	A,(BC)
	LD	L,A
	CALL	DIVB2 ;->E
	LD	A,E
	OR	A
	JR	NZ,oin1
	DEC	BC
	LD	A,(BC)
	OR	A
	JR	Z,oin1
	LD	A,1
oin1	LD	C,A
	LD	A,16
	SUB	C
	POP	HL
	JR	Z,oin2
	LD	B,A
	LD	DE,%0000100011111111
	CALL	oin3
oin2	LD	A,C
	LD	(IND1),A
	OR	A
	RET	Z
	LD	B,C
	LD	DE,%0010001011100011
oin3	LD	(HL),E
	LD	A,E
	XOR	D
	LD	E,A
	INC	H
	LD	A,H
	AND	7
	JR	NZ,oin31
	LD	A,H
	SUB	8
	LD	H,A
	LD	A,L
	ADD	A,32
	LD	L,A
oin31	DJNZ	oin3
	RET

;----выв.надписи
outTX	LD	HL,pTXdel
	LD	A,(HL)
	OR	A
	RET	Z
	DEC	(HL)
	RET	NZ
	LD	HL,(pTX_AD)
	LD	(TX_AD),HL
otx1	LD	BC,#207
	LD	HL,#819
	LD	A,2
	LD	(V_FLAG),A
	CALL	isOVER
	JR	NC,otx2
	CALL	V_PUT1
	CALL	TX48x7
	CALL	V_GET1
	CALL	V_MRK1
	JR	otx0
otx2	CALL	TX48x7
otx0	XOR	A
	LD	(V_FLAG),A
	RET

;---------индикаторы событий

colorL ;цвета индикаторов
	DEFB	#58,#60,#70,#28,#60,#58

outLED ;подсветка 6-и индикаторов + swapLED
;+0-атакует враг
;+1-здание построено
;+2-здание/шахта разрушены
;+3-атакуем мы
;+4-появился новый человек
;+5-наше здание горит
	LD	HL,colorL
	EXX
	LD	HL,LED
	LD	DE,ATR+664
	PUSH	DE
	CALL	oLL_
	LD	DE,ATR+728
	PUSH	DE
	CALL	oLL_
	POP	HL
	LD	DE,ATR+760
	LD	C,6
	LDIR
	POP	HL
	LD	DE,ATR+696
	LD	C,6
	LDIR
;подсветка индик. набора
	LD	A,(indSEL)
	LD	(ATR+543),A
	RET
;
oLL_	LD	B,3
oLL0	LD	A,(HL)
; ---- v0.04: changed/new code or data
	OR	A
	JR	Z,oLL2b
	DEC	(HL)
	AND	1
; ---- v0.04: changed/new code or data
	JR	Z,oLL2b
	EXX
	LD	A,(HL)
	EXX
; ---- v0.04: code removed (4.Z80: oLL2)
oLL2	; (в v0.04 код удалён, метка сохранена для ссылок)
	JR	oLL1
oLL2b	LD	A,#8
oLL1	INC	HL
	LD	(DE),A
	INC	E
	LD	(DE),A
	INC	E
	EXX
	INC	HL
	EXX
; ---- v0.04: changed/new code or data
	DJNZ	oLL0
	RET

;---------кнопки----------

oBUT	LD	HL,_BUT_H ;выв кнопок
	EXX
	LD	DE,BUT_H ;выв кнопки гер
	LD	HL,#519
	CALL	BUT_1
	LD	HL,#A19 ;выв 6 кноп
	LD	B,3
obu1	PUSH	BC
	PUSH	HL
	PUSH	HL
	CALL	BUT_1
	POP	HL
	INC	L
	INC	L
	INC	L
	CALL	BUT_1
	POP	HL
	INC	H
	INC	H
	INC	H
	POP	BC
	DJNZ	obu1
	RET
;
BUT_1	LD	A,(DE)
	INC	DE
	EXX
	CP	(HL)
	LD	(HL),A
	INC	HL
	EXX
	RET	Z
	PUSH	DE
	PUSH	HL
	LD	L,A
	LD	H,0
	ADD	HL,HL
	PUSH	HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	POP	DE
	ADD	HL,DE ;x66
	LD	DE,WBUTT
	ADD	HL,DE
	EX	DE,HL
	POP	HL
	PUSH	HL
	PUSH	DE
	LD	BC,#404
	LD	A,2
	LD	(V_FLAG),A
	CALL	isOVER
	JR	NC,btt1
	CALL	V_PUT1
	POP	DE
	POP	HL
	CALL	PUTbut
	CALL	V_GET1
	CALL	V_MRK1
	JR	btt0
btt1	POP	DE
	POP	HL
	CALL	PUTbut
btt0	XOR	A
	LD	(V_FLAG),A
	POP	DE
	RET

CLASSN ;цифры уровня развития 0-3 (1-4)
	DEFB	#D9,#C9,#C9,#C9,#DD
	DEFB	#DD,#C5,#C9,#D1,#DD
	DEFB	#DD,#C5,#C9,#C5,#DD
	DEFB	#C5,#D5,#D5,#DD,#C5
;5,6
	DEFB	#DD,#D1,#DD,#C5,#DD
	DEFB	#DD,#D1,#DD,#D5,#DD

PUTbut ;HL - adr in scr; DE-adr spr; BC-size(yx)
	PUSH	DE ;вывод одной кнопки
	EX	DE,HL
	CALL	SCOORD
	LD	(PUTsHL),HL
	POP	HL
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	INC	HL
	LD	(SET_SP+1),SP
	LD	SP,HL
	LD	HL,(PUTsHL)
	LD	B,3
Yb2	LD	(PUTsHL),HL
Yb0	INC	H
	LD	(HL),E
	INC	H
	LD	(HL),D
	INC	H
	POP	DE
	LD	(HL),E
	INC	H
	LD	(HL),D
	INC	H
	POP	DE
	LD	(HL),E
	INC	H
	LD	(HL),D
	INC	H
	POP	DE
	LD	(HL),E
;-
	LD	HL,(PUTsHL)
	LD	A,L
	ADD	A,32
	LD	L,A
	LD	(HL),D
	INC	H
	POP	DE
	LD	(HL),E
	INC	H
	LD	(HL),D
	INC	H
	POP	DE
	LD	(HL),E
	INC	H
	LD	(HL),D
	INC	H
	POP	DE
	LD	(HL),E
	INC	H
	LD	(HL),D
	INC	H
	POP	DE
	LD	(HL),E
;-
	LD	HL,(PUTsHL)
	LD	A,L
	ADD	A,64
	LD	L,A
	LD	(HL),D
	INC	H
	POP	DE
	LD	(HL),E
	INC	H
	LD	(HL),D
	INC	H
	POP	DE
	LD	(HL),E
	INC	H
	LD	(HL),D
	INC	H
	POP	DE
	LD	(HL),E
	INC	H
	LD	(HL),D
	POP	DE
	LD	HL,(PUTsHL)
	INC	L
	DJNZ	Yb2
	JP	SET_SP



isOVER ;?перкр курcор и обл вывода? NC-не перекр
;HL-угол,BC-размер окна+1
	LD	A,(G_MX)
	RRA
	RRA
	RRA
	AND	%11111
	INC	A
	SUB	L
	CP	C
	RET	NC
	LD	A,(G_MY)
	RRA
	RRA
	RRA
	AND	%11111
	INC	A
	SUB	H
	CP	B
	RET


outNUM ;выв чисел для шахты/избы/апгрейдов
	LD	A,(BUT_N+2)
	SUB	11
	JR	Z,oNmine
	DEC	A ;12
	JR	NZ,oNparm
;казарма
	CALL	oNUMh
	LD	E,C
	LD	HL,#E1D
	CALL	oNbcd
	CALL	oHOMh
	LD	E,A
	LD	HL,#B1D
oNbcd	PUSH	HL
	CALL	BCD
	POP	DE
	LD	A,(DCstr+3)
	CALL	iPRINT
	LD	A,(DCstr+4)
	JP	iPRINT
;
oNmine ;шахта
	LD	A,(SEL_T)
	CP	8
	RET	NZ
	LD	A,(SEL_N)
	CALL	B_IX
	LD	E,(IX+4)
	LD	D,(IX+5)
	CALL	BCD
	LD	DE,#E19
	LD	HL,DCstr+1
	LD	B,4
oNm1	LD	A,(HL)
	INC	HL
	CALL	iPRINT
	DJNZ	oNm1
	XOR	A
	CALL	iPRINT
	XOR	A
	JP	iPRINT
;
oNparm ;циферки на кнопках
	XOR	A
oNparL	PUSH	AF
	CALL	oNpar_
	POP	AF
	INC	A
	CP	5
	JR	C,oNparL
;

oNpar_	LD	C,A
	LD	HL,BUT_N
	CALL	BA
	SUB	22
	RET	C
	CP	8
	RET	NC
	LD	HL,hPARM
	CALL	BA
oNpa_	LD	B,A ;x5
	ADD	A,A
	ADD	A,A
	ADD	A,B
	LD	HL,SEL_T
	BIT	3,(HL)
	JR	Z,oNpa2 ;добавить +1 для зданий
	ADD	A,5
oNpa2	LD	HL,CLASSN
	CALL	BA ;получить номер изображения
	EX	DE,HL
	LD	A,C
	LD	HL,oNpPOS
	CALL	WT
	LD	B,5
oNpa0	INC	H
	LD	A,(DE)
	INC	DE
	LD	(HL),A
	DJNZ	oNpa0
	RET

oNgrp ;к-во объектов в группе
	LD	A,(BUT_H)
	CP	17
	RET	NZ
	LD	C,6
	LD	A,(SEL_T)
	DEC	A
	JR	oNpa_

oNcrew ;кол-во экипажа
	LD	A,(BUT_N+1)
	CP	20
	RET	NZ
	LD	A,(SEL_N)
	CALL	N_IX
	LD	A,(IX+17)
	OR	A
	JR	NZ,oNcw1
	LD	A,11
oNcw1	LD	DE,#B1D
	JP	PRINT

oNpPOS ;позиции цифр по кнопкам
	DEFW	#C89B,#C89E,#C8FB,#C8FE,#D05B,#D05E
	DEFW	#C0FB


DCMM	DEFW	10000,1000,100,10,1
;DCstr	DEFM "roXet"
;	DEFB #7F

BCD ;BCD-конв DE->DCstr
	EXX
	LD	HL,DCstr
	EXX
	LD	HL,DCMM
	LD	B,5
bcd0	LD	A,(HL)
	INC	HL
	PUSH	HL
	LD	H,(HL)
	LD	L,A
	EX	DE,HL
	XOR	A
bcd1	AND	A
	SBC	HL,DE
	JR	C,bcd2
	INC	A
	JR	bcd1
bcd2	ADD	HL,DE
	EX	DE,HL
	EXX
	LD	(HL),A
	INC	HL
	EXX
	POP	HL
	INC	HL
	DJNZ	bcd0
	RET

iPRINT ;inv печать символа А в поз DE(yx)
	PUSH_
	LD	C,A
	CALL	SCOORD
	EX	DE,HL
	LD	A,C
	ADD	A,A
	LD	BC,(FONT)
	LD	L,A
	LD	H,0
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,BC
	LD	B,4
iPR1	LD	A,(HL)
	CPL
	LD	(DE),A
	INC	HL
	INC	D
	LD	A,(HL)
	CPL
	LD	(DE),A
	INC	HL
	INC	D
	DJNZ	iPR1
	POP_
	INC	E
	RET

;-------------------


sq1	EQU	ATR+345
sqrADR	DEFW	sq1,sq1+3,sq1+96,sq1+99,sq1+192,sq1+195


outSQR ;раскраска 6и кнопок
	LD	A,(ext_M)
	CP	3
	JR	C,oQ0a ;для расширенных меню 3 и 4
	LD	A,#FF
	JR	NZ,oQ0b
	LD	A,(INDNbu)
	LD	C,A
	LD	HL,BUT_N
	CALL	BA
	OR	A
	LD	A,C
	JR	NZ,oQ0b
	LD	A,#FF
oQ0b	LD	(N_FUN1),A
;
oQ0a	LD	HL,BUT_N
	EXX
	LD	A,(F_FUNC)
	LD	B,A
	LD	DE,sqrADR
	XOR	A
oQ0	PUSH	AF
	EXX
	LD	A,(HL)
	INC	HL
	EXX
	OR	A
	LD	C,#38
	JR	Z,oQ1a
	POP	AF
	PUSH	AF
	CP	B
	LD	A,(MCOLOR) ;текущ действие?
	JR	NZ,oQ1
	INC	A
	INC	A
	XOR	%11000
oQ1	LD	C,A
	LD	A,(ext_M)
	CP	3
	JR	C,oQ1a
	LD	C,#60
	JR	Z,oQ1a
	LD	C,#39
oQ1a	LD	A,(DE)
	INC	DE
	LD	L,A
	LD	A,(DE)
	INC	DE
	LD	H,A
	LD	A,(HL)
	CP	C
	LD	A,C
	CALL	NZ,sqrCOL
	POP	AF
	INC	A
	CP	6
	JR	C,oQ0
	LD	A,(N_FUN1) ;нажатый квдр
	CP	#FF
	JR	Z,oQ5
	LD	HL,sqrADR
	CALL	WT
	LD	A,(HL)
	OR	%01111001
	CALL	sqrCOL
;
oQ5	LD	A,(SEL_T) ;квдр героя
	CP	7
	JR	Z,oQ7
	JR	NC,oQ8
	OR	A
	LD	A,#78 ;наш
	JR	NZ,oQS
	LD	A,#39 ;none
	JR	oQS
oQ7	LD	A,(SEL_N)
	CP	_NHER+_NHER
	LD	A,#72 ;враг
	JR	C,oQS
	LD	A,#60 ;пленник
	JR	oQS
oQ8	LD	A,(SEL_N)
	CP	#8
	JR	C,oQ255
	CP	#28
	LD	A,#79 ;наше зд
	JR	C,oQS
	LD	A,#7A ;вражье зд
	JR	oQS
oQ255	LD	A,#69 ;шахта
oQS	LD	HL,ATR+185
	CP	(HL)
	RET	Z
;
sqrCOL ;закрасить квадр. c HL цветом A
	PUSH	DE
	LD	DE,30
	LD	(HL),A
	INC	L
	LD	(HL),A
	INC	L
	LD	(HL),A
	ADD	HL,DE
	LD	(HL),A
	INC	L
	LD	(HL),A
	INC	L
	LD	(HL),A
	ADD	HL,DE
	LD	(HL),A
	INC	L
	LD	(HL),A
	INC	L
	LD	(HL),A
	POP	DE
	RET

;----- п/п вывода панели

oMN_WD ;вывод денег/леcа
	LD	HL,(MONEY1)
	LD	A,L
	OR	H
	JR	NZ,oMN1WD
	LD	HL,(MAZUT1)
	LD	A,L
	OR	H
	JR	NZ,oMN1WD
	LD	HL,ATR+57
	LD	C,2
	EXX
	LD	DE,#119
	LD	HL,MONEY
	CALL	outmw
	LD	HL,ATR+121
	LD	C,1
	EXX
	LD	DE,#319
	LD	HL,MAZUT
outmw	LD	C,0
om0	LD	A,(HL)
	INC	HL
	OR	A
	JR	NZ,om2
	CP	C
	JR	NZ,om2
	LD	A,11
	LD	B,#40
	JR	om1
om2	INC	C
	LD	B,#78
om1	CALL	PRINT
	LD	A,B
	EXX
	OR	C
	LD	(HL),A
	INC	HL
	EXX
	LD	A,E
	CP	#1E
	JR	C,om0
	RET	NZ
	LD	A,(HL)
	JR	om2

oMN1WD	LD	HL,ATR+57 ;альт.вывод
	EXX
	LD	DE,#119
	LD	HL,MONEY1+1
	CALL	out1mw
	LD	HL,ATR+121
	EXX
	LD	DE,#319
	LD	HL,MAZUT1+1
;
out1mw	LD	C,0
	LD	A,11
	CALL	PRINT
	LD	A,11
	CALL	PRINT
	EXX
	LD	(HL),#74
	INC	HL
	LD	(HL),#74
	INC	HL
	EXX
o1m8	CALL	o1m0
o1m0	LD	A,(HL)
	RLCA
	RLCA
	RLCA
	RLCA
	CALL	o1m7
	LD	A,(HL)
	LD	(HL),0
	DEC	HL
o1m7	AND	#F
	OR	A
	JR	NZ,o1m2
	CP	C
	JR	NZ,o1m2
	LD	A,E
	CP	#1E
	LD	A,0
	JR	NC,o1m2
	LD	A,11
	LD	B,#74
	JR	o1m1
o1m2	INC	C
	LD	B,#44
o1m1	CALL	PRINT
	LD	A,B
	EXX
	LD	(HL),A
	INC	HL
	EXX
	RET

TX48x7	LD	HL,(TX_AD) ; выв.назв.героя
	CALL	TX48pre
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	INC	HL
	LD	(SET_SP+1),SP
	LD	SP,HL
	LD	HL,SCR+#900+25
	LD	B,3
T4S0	LD	(HL),E
	INC	H
	LD	(HL),D
	INC	H
	POP	DE
	LD	(HL),E
	INC	H
	LD	(HL),D
	INC	H
	POP	DE
	LD	(HL),E
	INC	H
	LD	(HL),D
	INC	H
	POP	DE
	LD	(HL),E
	LD	H,(SCR/256)+9
	INC	L
	LD	(HL),D
	INC	H
	POP	DE
	LD	(HL),E
	INC	H
	LD	(HL),D
	INC	H
	POP	DE
	LD	(HL),E
	INC	H
	LD	(HL),D
	INC	H
	POP	DE
	LD	(HL),E
	INC	H
	LD	(HL),D
	POP	DE
	LD	H,(SCR/256)+9
	INC	L
	DJNZ	T4S0
	JP	SET_SP

OUTBAR ;общий вывод панели
	CALL	STS
	DEFB	#CD,#3E
	DEFB	#F3,#CD ;(был CALL_ gavBrY: слово-приманка, байты кода: CALL #F33E, CALL #EFC0... внутри страницы 7)
	DEFB	#C0,#EF
	DEFB	#CD,#2E
	DEFB	#EF,#CD
	DEFB	#7D,#F2
	DEFB	#CD,#43
	DEFB	#F0,#CD
	DEFB	#F4,#F1
	DEFB	#CD,#E6
; ---- v0.04: changed/new code or data
	POP	AF
	CALL	outNUM
	JP	outLED


;-----нач раскрас панели--

FRAME ;выв игр оформл
	CALL	STS
fra01	LD	A,(isCOLR) ;выбор цвета
	OR	A
	JR	Z,fra02
	LD	A,(MASTER)
	OR	A
	LD	E,#30
	LD	A,#28
	LD	C,#79
	JR	Z,fra03
	LD	E,#28
	LD	A,#30
	LD	C,#7A
	JR	fra03
fra02	LD	E,#38
	LD	A,#30
	LD	C,#69
fra03	LD	(MCOLOR),A
;панели
	PUSH	BC
	PUSH	AF
	LD	HL,#18
	LD	BC,#1808
	CALL	ATRBAR
	POP	AF
;кнопки
	LD	E,A
	LD	HL,#A19
	LD	BC,#906
	CALL	ATRBAR
;колонка
	POP	DE
	LD	HL,#C18
	LD	BC,#501
	CALL	ATRBAR
; ---- v0.04: changed/new code or data
	LD	HL,#1418
	LD	BC,#0406
	LD	E,#08
	CALL	ATRBAR
;индикаторы
;курсор
	LD	A,(COLOR)
	AND	%00111000
	CP	#18
	LD	A,#58
	JR	NZ,FRA_Ls
	LD	A,#68
FRA_Ls	LD	(COLRsc),A
;игровое поле
FRA_L	LD	A,(isCOLR)
	OR	A
	LD	A,#38
	JR	Z,FRA_L1
	LD	A,(COLOR)
FRA_L1	PUSH	AF
	LD	E,A
	LD	HL,0
	LD	BC,#118
	CALL	STS
	CALL	ATRBAR
	LD	HL,#017
	LD	BC,#1801
	CALL	ATRBAR
	POP	AF
	OR	#40
	LD	E,A
	LD	HL,#100
	LD	BC,#1717
	JP	ATRBAR


;----

PAUSE ;пауза с выводом задания по "H"
	LD	HL,onPAUS
	LD	A,(HL)
	OR	A
	RET	NZ
	INC	(HL)
; ---- v0.04: changed/new code or data
	LD	DE,#0301
	LD	BC,#1612
;параметры
	CALL	HlpBOX
	LD	DE,#0503
	PUSH	DE ;N ур
	LD	HL,TU_1
	CALL	tuPR
	LD	A,(MASTER)
	OR	A
	LD	HL,TU_7
	JR	Z,tu2
	LD	HL,TU_8
tu2	CALL	PRINTS
	LD	A,(LEVEL)
	CP	10
; ---- v0.04: changed/new code or data
	JR	C,tu3+7
	SUB	10
tu3	PUSH	AF
; ---- v0.04: changed/new code or data
	LD	A,#01
	CALL	PRINT
	POP	AF
; ---- v0.04: changed/new code or data
	CALL	PRINT
	POP	DE
	INC	D
	INC	D
	PUSH	DE
	LD	HL,dL2
	CALL	tuPR
	LD	A,(JP_SUB+3)
	OR	A
	LD	HL,TU_4+6
	JR	Z,tu3+32
	LD	HL,TU_4+11
	CALL	PRINTS
	POP	DE
	INC	D
	INC	D
	CALL	TUtime
	INC	D
	INC	D
	PUSH	DE
	LD	E,8
	LD	HL,TU_9
	CALL	PRINTS
	POP	DE
	INC	D
	INC	D
	DEC	E
;задание
	LD	B,4
	LD	HL,TASK_M
aus1	PUSH	DE
	PUSH	BC
	CALL	PRINTS
	POP	BC
	POP	DE
	INC	HL
	INC	D
	DJNZ	aus1
	CALL	BLITER
	CALL	HlpCOL
; ---- v0.04: code removed (4.Z80: HlpBOX)

	JP	FIREUP


TUarr	DEFB	10,109,10,127 ;_>_
TU_1	DEFB	31,64,62,50,53,61,74,127 ;Уровень
; ---- v0.04 TU_text (64 bytes at #F564): texts TU_3/TU_4 of the level end statistics (font codes of 4FONT: "Время", "Общее")
	DEFB	#1D,#3B,#3E,#36,#3D,#3E,#41,#42,#4A,#7F
TU_3
	DEFB	#0E,#40,#35,#3C,#4F,#7F
TU_4
	DEFB	#1A,#31,#49,#35,#35,#7F,#51,#1A,#52,#18,#7F,#19,#54,#6E,#19,#7F
TU_7	DEFB	23,78,52,56,91,127 ;Люди-
TU_8	DEFB	22,67,61,51,56,91,127 ;Кунги-
TU_9	DEFB	19,48,52,48,61,56,53,43,127 ;Задание:

TUtime ;выв.времени ур-ня/игры
	PUSH	DE ;вр ур
	LD	HL,TU_3
	CALL	tuPR
	LD	HL,LEVRES
	CALL	PRINTS
	POP	DE
	INC	D
	INC	D
	PUSH	DE ;общ вр
	LD	HL,TU_4
	CALL	tuPR
	LD	HL,RESULT
	CALL	PRINTS
	POP	DE
	RET

tuPR	CALL	PRINTS
	LD	HL,TUarr
	JP	PRINTS


;--------РАБОТА С КУРСОРОМ---

G_IMG1	DEFB	%11111100,%11111100 ;обычн курсор
	DEFB	%11111100,%10000100
	DEFB	%11111110,%10001110
	DEFB	%11111111,%10000011
	DEFB	%11111111,%10100001
	DEFB	%11111111,%11100111
	DEFB	%00111100,%00110100
	DEFB	%00011100,%00011100

G_MAP_	DEFB	%11111100,%00000000 ;курсор на карте/при нажатом FIRE
	DEFB	%11111100,%01111000
	DEFB	%11111110,%01110000
	DEFB	%11111111,%01111100
	DEFB	%11111111,%01011110
	DEFB	%11111111,%00011000
	DEFB	%00111100,%00001000
	DEFB	%00011100,%00000000


G_FIX_	DEFB	%00000000,%00000000 ;курсор при зафикс. цели
	DEFB	%01111100,%00000000
	DEFB	%01111100,%00111000
	DEFB	%01111110,%00110000
	DEFB	%01111111,%00101100
	DEFB	%01111111,%00001110
	DEFB	%00011111,%00000100
	DEFB	%00001110,%00000000

G_MAP1	EQU	G_MAP_ ;против перекрёстн.ссылок
G_FIX1	EQU	G_FIX_ ;

MMOV ;обр.управл
	CALL	CONTR
	LD	BC,#BFFE ;'Enter' || 'x'
	IN	A,(C)
	RRA
	JR	NC,eMOV
	LD	B,#FE
	IN	A,(C)
	BIT	2,A
	JR	Z,eMOV
	XOR	A
	LD	(BENTER),A
_422	LD	A,(CONTRB)
	LD	D,A
	AND	#20 ;'Caps' || R.butt?
	LD	E,A
	LD	BC,#FEFE
	IN	A,(C)
	AND	1
	OR	E
	LD	(BCAP),A
	LD	C,D
	LD	DE,(ENDX) ;move
	LD	B,D
	LD	HL,(MX)
	LD	(MXOLD),HL
	RR	C
	JR	NC,_1
	LD	A,L
	ADD	A,B
	JR	C,_11A
	CP	E
	JR	C,_11
_11A	LD	A,E
_11	LD	L,A
	LD	D,0
_1	RR	C
	JR	NC,_2
	LD	A,L
	SUB	B
	JR	NC,_21
	XOR	A
_21	LD	L,A
	LD	D,0
_2	RR	C
	JR	NC,_3
	LD	A,H
	ADD	A,B
	CP	189
	JR	C,_31
	LD	A,189
_31	LD	H,A
	LD	D,0
_3	RR	C
	JR	NC,_4
	LD	A,H
	SUB	B
	JR	NC,_41
	XOR	A
_41	LD	H,A
	LD	D,0
_4	LD	(MX),HL
	LD	C,(HL) ;ложное чтение [**]
	INC	L
	LD	B,(HL)
	LD	A,D
	OR	A
	LD	A,step_B ;нач шаг
	JR	NZ,_42
	LD	A,(MtSTEP)
	LD	DE,(M_STEP)
	ADD	A,1
	CP	E
	JR	C,_42
	LD	A,E
_42	LD	(MtSTEP),A
	RET
eMOV	LD	A,1
	LD	(BENTER),A
	LD	A,(isMAP)
	OR	A
	JR	Z,_42 ;в A=0
	CALL	MEM7
	CALL	MAPwin
	CALL	MX3PX
	CALL	movWIN
	CALL	MAPwin
	JP	_422

B_OFF	LD	HL,B_ONOF
	LD	A,(HL)
	OR	A
	RET	Z
	LD	(HL),0
	LD	HL,(BATR)
	LD	DE,B_ABUF
	LD	A,(DE)
	INC	DE
	LD	(HL),A
	LD	HL,(BADR)
	LD	B,8
B_o1	LD	A,(DE)
	LD	(HL),A
	INC	DE
	INC	H
	DJNZ	B_o1
	RET

B_IMGM	DEFB	#55,#81,#3D,#BD,#3D,#BD,#01,#FF

BL_ONN	EXX
	LD	A,(BY)
	CP	B
	JR	NZ,_BL
	PUSH	BC
	LD	HL,(BX) ;модиф B_ONN
	LD	(BXOLD),HL
	PUSH	HL
	CALL	STS
	CALL	ACOORD
	LD	(UATR),HL
	LD	A,(HL)
	LD	(U_ABUF),A
	LD	A,(COLRsc)
	LD	(HL),A
	POP	DE
	CALL	SCOORD
	LD	(UADR),HL
	LD	DE,U_BUF
	LD	BC,B_IMGM
	LD	A,8
B_n4	PUSH	AF
	LD	A,(HL)
	LD	(DE),A
	LD	A,(BC)
	LD	(HL),A
	INC	H
	INC	BC
	INC	DE
	POP	AF
	DEC	A
	JR	NZ,B_n4
	POP	BC
_BL	EXX
	RET

B_U2B	LD	HL,BY
	LD	DE,UBY
	LD	BC,14
	LDIR
	LD	A,1
	LD	(B_ONOF),A
	RET

B_SET0	EXX
	LD	B,-1
	EXX
	RET

B_SETI	EXX
	LD	B,26
	EXX
	CALL	B_NXTI
B_NXTI	EXX
	DEC	B
	LD	A,(UBY)
	SUB	-2
	JR	b_n_

B_SETN	EXX
	LD	B,-3
	EXX
	CALL	B_NXTN
B_NXTN	EXX
	INC	B
	LD	A,(UBY)
	SUB	2
b_n_	SUB	B
	JR	NZ,_BL
	PUSH	BC
	CALL	B_OFF
	POP	BC
	EXX
	RET

B_NXT0	EXX
	INC	B
	LD	A,(UBY)
	JR	b_n_

BMOV	LD	HL,(MX) ;преобр MX->BMX->BX->PX
	LD	(BMX),HL
	INC	H ;коррекция, т.к. спрайты сдвинуты вверх
	SRL	L
	SRL	L
	SRL	L
	SRL	H
	SRL	H
	SRL	H
	LD	(BX),HL
	LD	A,(isMAP)
	OR	A
	JR	NZ,mB1
	SRL	L
	SRL	H
	LD	DE,(X0)
	ADD	HL,DE
	LD	(PX),HL
	RET
mB1	CALL	MX3PX
	LD	(PX),BC
	RET


MX3PX	LD	HL,(MX) ;MX/3->PX
	LD	E,L
	LD	L,3
	CALL	DIVB
	LD	A,E
	CP	64
	JR	C,mB2
	LD	A,63
mB2	LD	C,A
	LD	E,H
	CALL	DIVB
	LD	B,E
	RET


