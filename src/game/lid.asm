MOUSE	LD	BC,#FBDF
	LD	DE,(OLDCO)
	LD	A,(isMAP)
	OR	A
	JR	NZ,MSEi
	LD	A,(BENTER)
	OR	A
	JR	NZ,MSRot
MSEi	LD	HL,(COORD)
	IN	A,(C) ;выч X
	LD	(OLDCO),A
	SUB	E
	JR	Z,MSEx0
	JP	P,MSEx1
	NEG
	CALL	MSElog
	NEG
	ADD	A,L
	JR	C,MSExe
	XOR	A
	JR	MSExe
MSEx1	CALL	MSElog
	ADD	A,L
	JR	C,MSEx11
	CP	248
	JR	C,MSExe
MSEx11	LD	A,248
MSExe	LD	L,A
MSEx0	LD	B,#FF ;выч Y
	IN	A,(C)
	LD	(OLDCO+1),A
	SUB	D
	JR	Z,MSEy0
	JP	M,MSEy1
	CALL	MSElog
	NEG
	ADD	A,H
	JR	C,MSEye
	XOR	A
	JR	MSEye
MSEy1	NEG
	CALL	MSElog
	ADD	A,H
	JR	C,MSEy11
	CP	190
	JR	C,MSEye
MSEy11	LD	A,190
MSEye	LD	H,A
MSEy0	LD	(COORD),HL
MSEbut	LD	B,#FA ;кнопки
	LD	HL,CONTRB
	IN	A,(C)
	CPL
	AND	7
	RLCA
	RLCA
	RLCA
	RLCA
	OR	(HL)
	LD	(HL),A
	RET
;
MSRot	LD	HL,(X0) ;скрол по мыши
	IN	A,(C) ;выч X
	LD	(OLDCO),A
	SUB	E
	JR	Z,MSRx0
	SRA	A
	JP	P,MSRx1
	ADD	A,L
	JR	C,MSRxe
	XOR	A
	JR	MSRxe
MSRx1	ADD	A,L
	JR	C,MSRx11
	CP	52
	JR	C,MSRxe
MSRx11	LD	A,52
MSRxe	LD	L,A
MSRx0	LD	B,#FF ;выч Y
	IN	A,(C)
	LD	(OLDCO+1),A
	SUB	D
	JR	Z,MSRy0
	SRA	A
	NEG
	JP	P,MSRy1
	ADD	A,H
	JR	C,MSRye
	XOR	A
	JR	MSRye
MSRy1	ADD	A,H
	JR	C,MSRy11
	CP	52
	JR	C,MSRye
MSRy11	LD	A,52
MSRye	LD	H,A
MSRy0	LD	(X0),HL
	JR	MSEbut

MSElg1	CP	4 ;мышка с ускорением
	RET	C
	ADD	A,A
	JR	C,MSElgC
	CP	8*2
	RET	C
	ADD	A,8
	JR	C,MSElgC
	CP	120
	RET	C
MSElgC	LD	A,120
	RET


;========================Мeнeджер памяти========

MEM4	LD	A,4
	JR	MEM
MEM0	XOR	A
	JR	MEM
MEM1	LD	A,1
	JR	MEM
MEM6	LD	A,6
	JR	MEM
MEM7	LD	A,7
MEM	OR	%11000
_128	LD	BC,#7FFD
	LD	(R128),A
	OUT	(C),A
	RET

;--------scr сlr/mov
OFFD	LD	DE,DSCR+#1AFE
	JR	offx

OFFS	CALL	MEM7
	LD	DE,SCR+#1AFE
offx	PUSH	DE
	POP	HL
	INC	HL
	LD	BC,768
	LD	(HL),0
	LDDR
	LD	BC,6143
	LD	(HL),255
	LDDR
	RET

COPY ;копир.экр
	LD	BC,6144
CY_	LD	HL,DSCR
	LD	DE,SCR
	LDIR
	RET

COPYAT	LD	BC,6912
	JR	CY_

;поиск по таблицам

WT	RLCA
	ADD	A,L
	LD	L,A
	JR	NC,WT_
	INC	H
WT_	LD	A,(HL)
	INC	HL
	LD	H,(HL)
	LD	L,A
	RET


BT	PUSH	HL
	ADD	A,L
	LD	L,A
	JR	NC,BT_
	INC	H
BT_	LD	A,(HL)
	POP	HL
	RET


DA	ADD	A,A
WA	ADD	A,A
BA	ADD	A,L
	LD	L,A
	LD	A,(HL)
	RET	NC
	INC	H
	LD	A,(HL)
	RET

;----------- выполнени таблицы процедур ----

EXE ;в hl - зашифрованый адрес п/п или 0000 - конец таблицы
	POP	HL ;теряем de,hl
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	INC	HL
	LD	A,D
	OR	E
	JR	Z,EXJP
	PUSH	HL
	ADD	HL,DE
	PUSH	HL
	LD	HL,EXE
	EX	(SP),HL
EXJP	JP	(HL)

;-----W_GrLib-------------------------------
;PUTsHL DEFW 0
;SCRADR DEFB SCR/256
;ATRADR DEFB #D8
;FONT	DEFW WFONT

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
	RET

PUTSYM ;HL - adr in scr; DE-adr spr; BC-size(yx)
	PUSH	DE
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
	LD	A,B
YS2	LD	(PUTsHL),HL
	EX	AF,AF'
YS0	LD	(HL),E
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
	INC	H
	LD	(HL),D
	INC	H
	POP	DE
	LD	A,L
	ADD	A,32
	LD	L,A
	JR	C,YS1
	LD	A,H
	SUB	8
	LD	H,A
YS1	DJNZ	YS0
	LD	HL,(PUTsHL)
	INC	L
	EX	AF,AF'
	LD	B,A
	DEC	C
	JR	NZ,YS2
YSR	JP	SET_SP


;;MATHEMATICAL LIBRARY	MATH-ZX
;MULB2	PUSH	HL	 ;HL*E--DE  (C)
;	JR	MULENT
;MULB	PUSH	HL	 ;L*E--DE
;	LD	H,0
;MULENT LD	A,E
;	LD	E,0
;	LD	D,E
;	JR	MMULB2
;MMULB1 ADD	HL,HL
;	JR	C,ENDMUL
;MMULB2 OR	A
;	JR	Z,ENDMUL
;	RRA
;	JR	NC,MMULB1
;	EX	DE,HL
;	ADD	HL,DE
;	EX	DE,HL
;	JR	MMULB1
;ENDMUL POP	HL
;	RET
;MUL	PUSH	HL ;HL*DE--DE
;	XOR	A
;	OR	D
;	JR	Z,MULENT
;	EX	DE,HL
;	XOR	A
;	OR	D
;	JR	Z,MULENT
;	SCF
;	POP	HL
;	RET
DIVB	LD	D,0 ;E/L--E (MOD in D)
DIVB2	PUSH	HL ;DE/L--E
	PUSH	BC
	LD	B,8
	EX	DE,HL
	LD	D,E
	LD	E,0
DIV1B	OR	A
	RR	D
	RR	E
	SBC	HL,DE
	JR	NC,MDIVB
	ADD	HL,DE
MDIVB	RLA
	DJNZ	DIV1B
	CPL
	LD	D,L
	LD	E,A
	POP	BC
	POP	HL
	RET

	MACRO	ATR_ p0,p1,p2
	LD	HL,p0
	LD	BC,p1
	LD	E,p2
	CALL	ATRBAR
	ENDM
PRINTL
;-------------------------------КОНЕЦ W_Gr.Lib

PRINTS ;печать строки HL(конец 127)
	LD	A,(HL)
	CP	#7F
	RET	Z
	CALL	PRINT
	INC	HL
	JR	PRINTS

PRINT ;печать символа А в поз DE(yx)
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
	LD	A,(HL)
	LD	(DE),A
	INC	HL
	INC	D
	LD	A,(HL)
	LD	(DE),A
	INC	HL
	INC	D
	LD	A,(HL)
	LD	(DE),A
	INC	HL
	INC	D
	LD	A,(HL)
	LD	(DE),A
	INC	HL
	INC	D
	LD	A,(HL)
	LD	(DE),A
	INC	HL
	INC	D
	LD	A,(HL)
	LD	(DE),A
	INC	HL
	INC	D
	LD	A,(HL)
	LD	(DE),A
	INC	HL
	INC	D
	LD	A,(HL)
	LD	(DE),A
	INC	HL
	INC	D
	POP_
	INC	E
	RET

;====Важнейшие общие процедуры===

;-----cобытие------

EVENTr ;смена героя - новое меню
	XOR	A
_EXT	LD	(ext_M),A
	LD	A,1
	LD	(F_FUNC),A
EVENT ;произошло событие, возможна смена меню
	LD	A,1
	LD	(_event),A
	RET


;------обновление текстового окна

putTX ;напр на выв сообщ A
	LD	HL,_msg
	CP	(HL)
	RET	Z ;еcли дублируется
	LD	(HL),A
	CALL	TX_ADR
	LD	(pTX_AD),HL
	LD	A,1
	LD	(pTXdel),A
	RET

dirTX	CALL	TX_ADR ;экстр сообщ A
	LD	A,(pTXdel)
	OR	A
	JR	NZ,dtx1
	LD	DE,(TX_AD)
	LD	(pTX_AD),DE
dtx1	LD	(TX_AD),HL
	LD	A,6 ;время задер экстр сообщ
dtx2	LD	(pTXdel),A
	CALL	MEM7
	CALL	otx1
	JP	MEM0

TX_ADR ;выч адр назв (A->HL)
	LD	L,A ;x3
	ADD	A,A
	ADD	A,L
	LD	L,A
	LD	E,A
	XOR	A
	LD	H,A
	LD	D,A
	ADD	HL,HL ;x7
	ADD	HL,DE
	ADD	HL,HL
	ADD	HL,DE
	ADD	HL,HL ;x7
	LD	DE,WNAMES
	ADD	HL,DE
	RET

TX48pre ;копир.надписи
	CALL	MEM1
	LD	DE,BUF512
	PUSH	DE
	LD	BC,42
	LDIR
	POP	HL
	JP	MEM7



;-----
searcB ;поиск здания A и A+8; кол-во построеных->A; Z-нет
	LD	C,A
	XOR	A
	EX	AF,AF'
	LD	HL,HBUILD
	LD	D,0
	LD	B,32
oNi1	LD	A,(HL)
	OR	A
	JR	NZ,oNi2
	LD	E,8
	JR	oNi3
oNi2	INC	L
	INC	L
	LD	A,(HL)
	CP	8
	JR	C,oNi6
	SUB	8
oNi6	CP	C ;то?
	LD	E,6
	JR	NZ,oNi3
	INC	HL
	INC	HL
	LD	E,4
	LD	A,(HL) ;построено?
	INC	A
	CP	253
	JR	NC,oNi3
	EX	AF,AF'
	INC	A
	EX	AF,AF'
oNi3	ADD	HL,DE
	DJNZ	oNi1
	EX	AF,AF'
	OR	A
	RET
;
oNUMh ;число юнитов, которым нужна пища ->C
	LD	HL,HUMAN
	LD	D,0
	LD	C,D
	LD	B,_NHER
oNh1	LD	A,(HL)
	OR	A
	JR	NZ,oNh2
	LD	E,_LHER
	JR	oNh3
oNh2	LD	E,4
	ADD	HL,DE
	LD	A,(HL)
	CP	6
	JR	Z,oNh4 ;кроме пушек/зениток
	CP	18
	JR	Z,oNh4
	INC	C
oNh4	LD	E,_LHER-4
oNh3	ADD	HL,DE
	DJNZ	oNh1
	RET
;
oHOMh	LD	A,6 ;число предост пищи (4*N_ферм)->A
	CALL	searcB
	ADD	A,A
	ADD	A,A
	RET

;-----

mayBLT ;можно разместить здание 3х3? (NC-нет)
	CP	50
	JR	Z,mbb7
	CP	58
	JR	NZ,mbb8
mbb7 ;размещение базы рядом с шахтой запрещено
	LD	A,#BA
	LD	(noPLAT),A
	LD	HL,(PX)
	INC	L
	INC	H
	LD	IX,MINE
	LD	DE,8
	LD	C,8
mbX0	LD	A,(IX+0)
	OR	A
	JR	Z,mbX1
	CALL	DIST2
	CP	8 ;_миним. расст. от шахты до базы+1
	CCF
	RET	NC ;слишком близко
mbX1	ADD	IX,DE
	DEC	C
	JR	NZ,mbX0
;
mbb8 ;близко от края?
	LD	DE,(PX)
	INC	D
	INC	E
	LD	A,#10
	LD	(noPLAT),A
	LD	A,E
	SUB	2
	CP	60
	RET	NC
	LD	A,D
	SUB	2
	CP	60
	RET	NC
;под зданием пусто?
	LD	B,9
mbb1	LD	A,B
	LD	HL,GO_Nt0-2
	CALL	WT
	LD	A,L
	ADD	A,E
	LD	L,A
	LD	A,H
	ADD	A,D
	LD	H,A
	CALL	mblSQ
	RET	NC
	DJNZ	mbb1
;рядом?
	LD	A,#18
	LD	(noPLAT),A
	LD	B,12
mbb5	LD	A,B
	LD	HL,GO_Ntb+14
	CALL	WT
	LD	A,L
	ADD	A,E
	LD	L,A
	LD	A,H
	ADD	A,D
	LD	H,A
	CALL	mbs_0
	RET	NC
	DJNZ	mbb5
	SCF
	RET	C

mblSQ ;на этом квадрате можно строить(NC-нет)?
	LD	A,(LEV_T)
	OR	A
	LD	C,6
	JR	NZ,mbq1
	LD	C,15
mbq1	CALL	GMAP
	LD	A,(HL)
	CP	C
	RET	NC ;NC-непрох|невид
	M1toM2_
	LD	A,(HL)
	CP	1
	RET ;NC-непрох|кто-то есть / C-можно

mbs_0	CALL	GMAP ;квадр.проходим
	LD	A,(HL)
	AND	#7F
	CP	41
	RET

mayBLZ ;можно разместить зенитку 1х1? (nc-нет)
	LD	A,#10
	LD	(noPLAT),A
	LD	HL,(PX)
	PUSH	HL
	LD	C,41
	CALL	mbq1
	POP	DE
	RET	NC
;
	LD	A,#18
	LD	(noPLAT),A
	LD	B,4
mbz5	LD	A,B
	ADD	A,A
	LD	HL,GO_Ntb-4
	CALL	WT
	LD	A,L
	ADD	A,E
	LD	L,A
	LD	A,H
	ADD	A,D
	LD	H,A
	CALL	mbs_0
	RET	NC
	DJNZ	mbz5
;
	LD	A,#8
	LD	(noPLAT),A
	LD	HL,(PX)
	LD	IX,HBUILD
	LD	DE,8
	LD	C,32
mbz0	LD	A,(IX+0)
	OR	A
	JR	Z,mbz1
	CALL	DIST2
	CP	8 ;_макс. расст. от зенитки до здания+1
	RET	C ;ок
mbz1	ADD	IX,DE
	DEC	C
	JR	NZ,mbz0
	RET ;нет

;--------

M_PLAT ;показать площадку под стр-во
	LD	A,(F_FUNC)
	CP	#FF
	JR	NC,ofPLAT
	LD	HL,BUT_N
	CALL	BA
	CP	34
	JR	NZ,plt3x3
;зенитка
	CALL	mayBLZ
	LD	A,1
	JR	pltC
plt3x3 ;здание
	CP	50
	JR	C,ofPLAT
	CP	66
	JR	NC,ofPLAT
	CALL	mayBLT
	LD	A,3
;
pltC	LD	(szPLAT),A
	LD	A,(noPLAT) ;саn't
	JR	NC,plt2
	LD	A,(isCOLR)
	OR	A
	LD	A,#39
	JR	Z,plt2
	LD	A,(COLOR)
	XOR	#8
plt2	EX	AF,AF'
;
	CALL	ofPLAT
	LD	HL,(BX)
	LD	A,L
	CP	24
	RET	NC
	RES	0,L
	RES	0,H
	LD	A,(szPLAT)
	ADD	A,A
	LD	C,A
	LD	B,A
	LD	A,24
	SUB	B
	SUB	L
	JR	NC,plt0
	ADD	A,B
	LD	B,A
plt0	LD	A,24
	SUB	C
	SUB	H
	JR	NC,plt1
	ADD	A,C
	LD	C,A
plt1	LD	(bcPLAT),BC
	CALL	STS
	CALL	ACOORD
	LD	(adPLAT),HL
	LD	(isPLAT),A
	EX	AF,AF'
	JR	PA0

ofPLAT	LD	HL,isPLAT ;cтереть площадку
	LD	A,(HL)
	OR	A
	RET	Z
	XOR	A
	LD	(HL),A
	INC	HL
	INC	HL
	LD	C,(HL) ;szY
	INC	HL
	LD	B,(HL) ;szX
	INC	HL
	LD	A,(HL)
	INC	HL
	LD	H,(HL)
	LD	L,A ;adr in ATR
	LD	A,(isCOLR)
	OR	A
	LD	A,#38
	JR	Z,PA0a
	LD	A,(COLOR)
PA0a	HALT ;??
PA0	LD	E,A ;color
PA1	PUSH	BC
	PUSH	HL
PA2	LD	A,(HL)
	AND	#40
	OR	E
	LD	(HL),A
	INC	L
	DJNZ	PA2
	POP	HL
	LD	BC,32
	ADD	HL,BC
	POP	BC
	DEC	C
	JR	NZ,PA1
	RET
; ---- v0.04: changed/new code or data
HEALTH ;probably: таблица по типу юнита (0..23): пары (здоровье, признаки); код читает признак по HEALTH+1 и здоровье по HEALTH+0 (WA)
; (в образе v0.04 была разобрана как код: слова LD (nn),A с метками INA0FX+6 и maf2+12 - числа #5040 и #4B40, не адреса)
	DEFB	50,#00, 50,#00, 50,#00, 50,#40, 60,#40, 80,#40, 120,#00, 50,#40, 80,#C0, 200,#00, 150,#00, 70,#00
	DEFB	50,#00, 50,#00, 50,#00, 60,#40, 50,#00, 0,#40, 110,#00, 50,#40, 75,#C0, 180,#00, 150,#00, 70,#00


;------------новый герой------


NEWHER ;A-0,1,2:чел/кунг/пленник HL-поз;A'-тип
;вых Z/NZ - O.K./нет места
	PUSH	HL
	CALL	sFREE
	POP	HL
	RET	NZ ;nz ->>
	CALL	IX0_HL ;позиция
	CALL	IXw_HL
; ---- v0.04: code removed (4.Z80: (по умолчанию - идёт в атаку))
;исходная позиц для охранников врага
	EX	AF,AF'
	LD	(IX+4),A
	LD	B,A
;
	PUSH	HL
	CALL	GMAP2
	PUSH	HL
	CALL	IMHER3
	POP	HL
	PUSH	AF
;
	CP	11
	JR	NC,newhe1
	LD	(HL),C ;для наземн
	CALL	RND
	AND	7
	JR	newhe2
newhe1	CALL	RND ;для авиа
	AND	15
	CPL
newhe2	LD	(IX+dir),A
;
	CALL	IX_stop ;параметры движения
	LD	(IX+phase_),A ;фаза
	LD	(IX+speed),A ;шаг
	LD	HL,HEALTH
	LD	A,B
	CALL	WT
	LD	(IX+health),L ;здоровье
; ---- v0.04: changed/new code or data (4.Z80: (обладает энергией?) (/4;для наших) (/3*2;для врагов))
	LD	(IX+#06),#F0
newhe4 ;
	POP	AF
	POP	HL
nH0_	CP	10
	JR	NC,nH1
nH0	PUSH	HL
	LD	H,0
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	LD	(IX-4),L
	LD	(IX-3),H
	POP	AF
	INC	A
	ADD	A,A
	ADD	A,A
	LD	L,A
	LD	H,0
	ADD	HL,HL
	ADD	HL,HL
	DEC	HL ;cмещ -3
	DEC	HL
	DEC	HL
	LD	(IX-2),L
	LD	(IX-1),H
	XOR	A
	RET ;z ->>
nH1	PUSH	AF
	PUSH	HL
	LD	H,0
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	DEC	HL
	DEC	HL
	DEC	HL
	DEC	HL
	LD	(IX-4),L
	LD	(IX-3),H
	POP	AF
	INC	A
	ADD	A,A
	ADD	A,A
	LD	L,A
	LD	H,0
	ADD	HL,HL
	ADD	HL,HL
	POP	AF
	JR	Z,nH3
dyAVIA	EQU	1
dxAVIA	EQU	4
	LD	BC,-dyAVIA ;для авиа (dxAVIA;-dyAVIA)
	ADD	HL,BC
;LD A,(IX-4)
;ADD A,4-dxAVIA ;=0 - не надо
;LD (IX-4),A
	JR	nH2
nH3	INC	HL ;для танка (dx=-4;dy=+4)
	INC	HL
	INC	HL
nH2	LD	(IX-2),L
	LD	(IX-1),H
	XOR	A
	RET ;z ->>

NEWix_ ;вх A=0/1 -(2x2,2x3) /3x3
	OR	A
	JR	Z,nH0
	JR	NZ,nH1

sFREE ;поиск св.места и уст IX (Вх:A-чей)
; (вых z/nz - ok/нет места, C - номер+#80)
	CP	1
	LD	HL,HUMAN
	LD	BC,(_NHER*#100)+0
	LD	DE,_LHER
	JR	C,sF1
	LD	HL,KUNGE
	LD	C,_NHER
	JR	Z,sF1
	LD	HL,SLAVE
	LD	BC,((_NSLAV*#100)+_NHER)+_NHER
sF1	INC	L ;	(IX+y)==0 ;на пустое место
	PUSH	BC
	PUSH	HL
	CALL	sF10
	LD	A,C
	POP	HL
	POP	BC
	JR	Z,sF2
	DEC	L ; (ix)==0  ;вместо трупа
	CALL	sF10
	LD	A,C
	RET	NZ ;nz->нет места
sF2	LD	C,A
	SET	7,C
	CALL	N_IX
	XOR	A
	RET ;z->выделено место (ix,iy)
;
sF10	LD	A,(HL) ;z-ok
	OR	A
	RET	Z
	INC	C
	ADD	HL,DE
	DJNZ	sF10
	RET ;nz

stayON ;поиск места, чтобы поставить героя (hl)
	LD	C,3
sY00	CALL	stay1
	DEC	H
	DEC	L
	LD	B,C
sYupL	CALL	stay1
	INC	L
	DJNZ	sYupL
	DEC	L
	INC	H
	LD	B,C
	DEC	B
	DEC	B
sYrtL	CALL	stay1
	INC	H
	DJNZ	sYrtL
	LD	B,C
sYdwL	CALL	stay1
	DEC	L
	DJNZ	sYdwL
	INC	L
	DEC	H
	LD	B,C
	DEC	B
	DEC	B
sYlfL	CALL	stay1
	DEC	H
	DJNZ	sYlfL
	INC	C
	INC	C
	JR	sY00

stay1 ;пров позиции; вых POP AF!!
	LD	A,L
	CP	63
	RET	NC
	LD	A,H
	CP	63
	RET	NC
	PUSH	HL
	CALL	GMAP2
	LD	A,(HL)
	POP	HL
	OR	A
	RET	NZ
	POP	AF ;!
	RET

CORix_ ;коррекция коорд (E+ix(-4,-3); D+ix(-2,-1)) (-128..+127)
	PUSH	IX
cii_	POP	HL
	CALL	cii0
	DEC	HL
	LD	D,E
;
cii0	DEC	HL
	DEC	HL
	LD	A,(HL)
	ADD	A,D
	LD	(HL),A
	INC	HL
	BIT	7,D
	JR	NZ,cii1
	RET	NC
	INC	(HL)
	RET
cii1	RET	C
	DEC	(HL)
	RET


MANA	EQU	#F0 ;-макс.знач. магич. энергии
;люди
;кунги

