;-----ЧВ Работа со спрайтами ---
step_B	EQU	0 ;нач шаг курс
oumDEL	EQU	3 ;задержка на вывод карты
ouFAST	EQU	5 ;ускорение вывода экрана

;


;---выв.спрайтов карты----



N12X12 ;покрытие невидимых полей





;------------------




	SLA	A
	RET	C
	CP	94*2
	JR	NC,GSA2
GSA0	LD	L,A ;обычн спрайты/центры зданий
	LD	H,LAND/4096
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	RET
GSA2	CP	120*2
	JR	NC,GSA3
	CP	101*2
	JR	Z,GSA5
	JR	NC,GSA0
	EX	AF,AF' ;анимированые
	LD	A,(ANIM)
	OR	A
	JR	NZ,GSA2A
	EX	AF,AF'
	JR	GSA0
GSA2A	LD	L,A ;
	ADD	A,A ;
	LD	H,A ;
	ADD	A,A ;
	ADD	A,H ;
	ADD	A,L ;x7
	LD	L,A
	EX	AF,AF'
	RRCA
	ADD	A,L
	PUSH	DE
	LD	DE,((390-101)*32)+LAND
	JR	GSA33
GSAT	DEFW	1,65,64,63,-1,-65,-64,-63
GSA3	RRCA ;углы зданий
	SUB	120
	PUSH	DE
	PUSH	AF
	PUSH	HL
	LD	HL,GSAT
	CALL	WT
	POP	DE
	ADD	HL,DE
	LD	A,(HL)
	AND	#7F
	SUB	101
	JR	Z,GSA4
	ADD	A,A
	ADD	A,A
	ADD	A,A
	POP	DE
	ADD	A,D
	LD	DE,(112*32)+LAND
GSA33	LD	L,A
	LD	H,0
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,DE
	POP	DE
	RET
GSA4 ;углы стр-ва 50%
	CALL	GSA5
	INC	A
	POP	DE
	ADD	A,D
	JR	GSA5B
GSA5 ;центры стр-ва 50%
	PUSH	DE
	CALL	GSA5A
GSA5B	LD	DE,(264*32)+LAND
	JR	GSA33

GSA5A	M1toM2_
	LD	A,(HL)
	SUB	#38
	CALL	B_IX
	LD	A,(IX+2)
	CP	8
	JR	C,GSA5C
	DEC	A
GSA5C	LD	L,A ;
	ADD	A,A ;
	ADD	A,L ;
	LD	L,A ;
	ADD	A,A ;
	ADD	A,L ;x9
	RET


ScorrP	LD	A,L
	ADD	A,32
	LD	L,A
	JR	C,Sco1
	LD	A,H
	SUB	8
	LD	H,A
Sco1	LD	A,E
	ADD	A,32
	LD	E,A
	RET	C
	LD	A,D
	SUB	8
	LD	D,A
	RET

ScorrM	LD	A,L
	SUB	32
	LD	L,A
	JR	C,Sco3
	LD	A,H
	ADD	A,8
	LD	H,A
Sco3	LD	A,E
	SUB	32
	LD	E,A
	RET	C
	LD	A,D
	ADD	A,8
	LD	D,A
	RET

;---------------

SdUR	CALL	ScU1
	JP	Z,ScRT
	CALL	ScR1
	JP	Z,ScUP1
	CALL	SW_OFF
;--CALL ScU2+ScR2
	CALL	PXLO
	CALL	PYLF
	CALL	SXLO
	CALL	SYLF
	CALL	NXLO
	CALL	NYLF
	CALL	MEM7
	CALL	ScUR_
	JP	ScNZ

SdDL	CALL	ScD1
	JP	Z,ScLF
	CALL	ScL1
	JR	Z,ScDW1
	CALL	SW_OFF
;--CALL ScD2+ScL2
	CALL	PXHI
	CALL	PYRT
	CALL	SXHI
	CALL	SYRT
	CALL	NXHI
	CALL	NYRT
	CALL	MEM7
	CALL	ScDL_
	JP	ScNZ


SdUL	CALL	ScU1
	JP	Z,ScLF
	CALL	ScL1
	JR	Z,ScUP1
	CALL	SW_OFF
;--CALL ScU2+ScL2
	CALL	PXLO
	CALL	PYRT
	CALL	SXLO
	CALL	SYRT
	CALL	NXLO
	CALL	NYRT
	CALL	MEM7
	CALL	ScUL_
	JR	ScNZ


SdDR	CALL	ScD1
	JP	Z,ScRT
	CALL	ScR1
	JR	Z,ScDW1
	CALL	SW_OFF
;--CALL ScD2+ScR2
	CALL	PXHI
	CALL	PYLF
	CALL	SXHI
	CALL	SYLF
	CALL	NXHI
	CALL	NYLF
	CALL	MEM7
	CALL	ScDR_
	JR	ScNZ

ScDW	CALL	ScD1
	JP	Z,noROT
ScDW1	CALL	SW_OFF
	CALL	ScD2
	CALL	MEM7
	JP	ScD_
ScD1	LD	HL,Y0
	LD	A,(HL)
	OR	A
	RET	Z
	DEC	(HL)
	OR	A
	RET
ScD2	CALL	PXHI
	CALL	SXHI
	CALL	NXHI
	JR	ScNZ

ScUP	CALL	ScU1
	JP	Z,noROT
ScUP1	CALL	SW_OFF
	CALL	ScU2
	CALL	MEM7
	JP	ScU_
ScU1	LD	HL,Y0
	LD	A,(HL)
	CP	52
	RET	Z
	INC	(HL)
	RET
ScU2	CALL	PXLO
	CALL	SXLO
	CALL	NXLO
ScNZ	CALL	MEM7
	CALL	BMOV
	LD	HL,isROT
	LD	(HL),1
	RET

ScLF	CALL	ScL1
	JP	Z,noROT
	CALL	SW_OFF
	CALL	ScL2
	CALL	MEM7
	JP	ScL_
ScL1	LD	HL,X0
	LD	A,(HL)
	CP	52
	RET	Z
	INC	(HL)
	RET
ScL2	CALL	PYRT
	CALL	SYRT
	CALL	NYRT
	JR	ScNZ

ScRT	CALL	ScR1
	JP	Z,noROT
	CALL	SW_OFF
	CALL	ScR2
	CALL	MEM7
	JP	ScR_
ScR1	LD	HL,X0
	LD	A,(HL)
	OR	A
	RET	Z
	DEC	(HL)
	OR	A
	RET
ScR2	CALL	PYLF
	CALL	SYLF
	CALL	NYLF
	JR	ScNZ

ScD_	CALL	B_SETI
	LD	HL,SCR+#17A0
	LD	DE,SCR+#17E0
	LD	BC,#1602
ScD0	PUSH	BC
	CALL	B_NXTI
	LD	A,8
ScD10	PUSH	HL
	PUSH	DE
	LDI ;
	LDI
	LDI
	LDI
	LDI
	LDI
	LDI
	LDI
	LDI ;
	LDI
	LDI
	LDI
	LDI
	LDI
	LDI
	LDI
	LDI ;
	LDI
	LDI
	LDI
	LDI
	LDI
	LDI
	LDI
	POP	DE
	POP	HL
	DEC	H
	DEC	D
	DEC	A
	JP	NZ,ScD10
	CALL	ScorrM
	CALL	BL_ONN
	POP	BC
	DJNZ	ScD0
	DEC	C
	JP	Z,B_U2B
	LD	L,E
	LD	A,D
	XOR	#60 ;!
	LD	H,A
	LD	B,2
	JR	ScD0

ScDR_	CALL	B_SETI
	LD	HL,SCR+#17A0+21
	LD	DE,SCR+#17E0+23
	LD	BC,#1602
ScDR0	PUSH	BC
	CALL	B_NXTI
	LD	A,8
ScDR1	EX	AF,AF'
	PUSH	HL
	PUSH	DE
	LD	BC,22
	LDDR
	LD	L,E
	LD	A,D
	XOR	#60 ;!
	LD	H,A
	LDD
	LDD
	POP	DE
	POP	HL
	DEC	H
	DEC	D
	EX	AF,AF'
	DEC	A
	JP	NZ,ScDR1
	CALL	ScorrM
	CALL	BL_ONN
	POP	BC
	DJNZ	ScDR0
	DEC	C
	JP	Z,B_U2B
	LD	L,E
	LD	A,D
	XOR	#60
	LD	H,A
	LD	B,2
	JR	ScDR0

ScDL_	CALL	B_SETI
	LD	HL,SCR+#17A0+2
	LD	DE,SCR+#17E0
	LD	BC,#1602
ScDL0	PUSH	BC
	CALL	B_NXTI
	LD	A,8
ScDL1	EX	AF,AF'
	PUSH	HL
	PUSH	DE
	LD	BC,22
	LDIR
	LD	L,E
	LD	A,D
	XOR	#60 ;!
	LD	H,A
	LDI
	LDI
	POP	DE
	POP	HL
	DEC	H
	DEC	D
	EX	AF,AF'
	DEC	A
	JP	NZ,ScDL1
	CALL	ScorrM
	CALL	BL_ONN
	POP	BC
	DJNZ	ScDL0
	DEC	C
	JP	Z,B_U2B
	LD	L,E
	LD	A,D
	XOR	#60
	LD	H,A
	LD	B,2
	JR	ScDL0

ScU_	CALL	B_SETN
	LD	HL,SCR+#0040
	LD	DE,SCR
	LD	BC,#1602
ScU0	PUSH	BC
	CALL	B_NXTN
	LD	A,8
ScU10	PUSH	HL
	PUSH	DE
	LDI ;
	LDI
	LDI
	LDI
	LDI
	LDI
	LDI
	LDI
	LDI ;
	LDI
	LDI
	LDI
	LDI
	LDI
	LDI
	LDI
	LDI ;
	LDI
	LDI
	LDI
	LDI
	LDI
	LDI
	LDI
	POP	DE
	POP	HL
	INC	H
	INC	D
	DEC	A
	JP	NZ,ScU10
	CALL	ScorrP
	CALL	BL_ONN
	POP	BC
	DJNZ	ScU0
	DEC	C
	JP	Z,B_U2B
	LD	L,E
	LD	A,D
	XOR	#60 ;!
	LD	H,A
	LD	B,2
	JR	ScU0

ScUR_	CALL	B_SETN
	LD	HL,SCR+#0040+21
	LD	DE,SCR+23
	LD	BC,#1602
ScUR0	PUSH	BC
	CALL	B_NXTN
	LD	A,8
ScUR1	EX	AF,AF'
	PUSH	HL
	PUSH	DE
	LD	BC,22
	LDDR
	LD	L,E
	LD	A,D
	XOR	#60 ;!
	LD	H,A
	LDD
	LDD
	POP	DE
	POP	HL
	INC	H
	INC	D
	EX	AF,AF'
	DEC	A
	JP	NZ,ScUR1
	CALL	ScorrP
	CALL	BL_ONN
	POP	BC
	DJNZ	ScUR0
	DEC	C
	JP	Z,B_U2B
	LD	L,E
	LD	A,D
	XOR	#60 ;!
	LD	H,A
	LD	B,2
	JR	ScUR0

ScUL_	CALL	B_SETN
	LD	HL,SCR+#0040+2
	LD	DE,SCR
	LD	BC,#1602
ScUL0	PUSH	BC
	CALL	B_NXTN
	LD	A,8
ScUL1	EX	AF,AF'
	PUSH	HL
	PUSH	DE
	LD	BC,22
	LDIR
	LD	L,E
	LD	A,D
	XOR	#60 ;!
	LD	H,A
	LDI
	LDI
	POP	DE
	POP	HL
	INC	H
	INC	D
	EX	AF,AF'
	DEC	A
	JP	NZ,ScUL1
	CALL	ScorrP
	CALL	BL_ONN
	POP	BC
	DJNZ	ScUL0
	DEC	C
	JP	Z,B_U2B
	LD	L,E
	LD	A,D
	XOR	#60 ;!
	LD	H,A
	LD	B,2
	JR	ScUL0


ScL_	CALL	B_SET0
	LD	HL,SCR+2
	LD	DE,SCR
	LD	B,24
ScL00	PUSH	BC
	CALL	B_NXT0
	LD	A,8
ScL0	EX	AF,AF'
	PUSH	HL
	PUSH	DE
	LDI ;
	LDI
	LDI
	LDI
	LDI
	LDI
	LDI
	LDI
	LDI ;
	LDI
	LDI
	LDI
	LDI
	LDI
	LDI
	LDI
	LDI ;
	LDI
	LDI
	LDI
	LDI
	LDI
	LD	L,E
	LD	A,D
	XOR	#60 ;!
	LD	H,A
	LDI
	LDI
	POP	DE
	POP	HL
	INC	H
	INC	D
	EX	AF,AF'
	DEC	A
	JR	NZ,ScL0
	CALL	ScorrP
	CALL	BL_ONN
	POP	BC
	DJNZ	ScL00
	JP	B_U2B

ScR_	CALL	B_SET0
	LD	HL,SCR+21
	LD	DE,SCR+23
	LD	B,24
ScR00	PUSH	BC
	CALL	B_NXT0
	LD	A,8
ScR0	EX	AF,AF'
	PUSH	HL
	PUSH	DE
	LDD ;
	LDD
	LDD
	LDD
	LDD
	LDD
	LDD
	LDD
	LDD ;
	LDD
	LDD
	LDD
	LDD
	LDD
	LDD
	LDD
	LDD ;
	LDD
	LDD
	LDD
	LDD
	LDD
	LD	L,E
	LD	A,D
	XOR	#60 ;!
	LD	H,A
	LDD
	LDD
	POP	DE
	POP	HL
	INC	H
	INC	D
	EX	AF,AF'
	DEC	A
	JR	NZ,ScR0
	CALL	ScorrP
	CALL	BL_ONN
	POP	BC
	DJNZ	ScR00
	JP	B_U2B


ROTsub	DEFW	ScLF,ScRT,000,ScUP,SdUL,SdUR,000,ScDW,SdDL,SdDR
ROTATE	LD	A,(BENTER)
	OR	A
	JR	Z,rotCOR
ROt1	LD	A,(CONTRB)
	AND	%1111
	JR	ROt2
rotCOR	LD	C,0
	LD	HL,(MX)
	LD	A,L
	OR	A
	JR	NZ,rC1
	SET	1,C
rC1	CP	248
	JR	C,rC2
	SET	0,C
rC2	LD	A,H
	OR	A
	JR	NZ,rC3
	SET	3,C
rC3	CP	184
	JR	C,rC5
	SET	2,C
rC5	LD	A,(PMOUSE)
	OR	A
	LD	A,C
	JR	NZ,ROt2
	LD	A,(CONTRB)
	AND	C
ROt2	OR	A
	JR	Z,noRO1
	CP	%1011
	JR	NC,noRO1
	LD	HL,ROTsub-2
	CALL	WT
	LD	A,L
	OR	H
	JR	Z,noRO1
	PUSH	HL
	LD	A,(isROT)
	OR	A
	JR	NZ,RO_ON
	INC	A
	LD	(isSWFF),A
	JR	RO_1
RO_ON ;HALT
RO_1	CALL	MEM1
	POP	HL
	JP	(HL)
noRO1	LD	A,(isROT)
	OR	A
	RET	Z
noROT	CALL	MEM7
	CALL	B_OFF
	LD	A,(isSWFF)
	OR	A
	JR	NZ,noRO2
	CALL	V_GET1
	CALL	V_GET2
noRO2	XOR	A
	LD	(V_FLAG),A
	LD	(isROT),A
	RET

SW_OFF	LD	A,(isSWFF)
	OR	A
	RET	Z
	XOR	A
	LD	(isSWFF),A
	LD	A,2
	LD	(V_FLAG),A
	CALL	MEM7
	CALL	V_PUT1
	CALL	V_PUT2
	JP	MEM1


;-------

OUMAIN ;выв карты/поля
	LD	A,(isMAP)
	OR	A
	JR	Z,OU_SCR

OU_MAP ;режим-карта
	LD	HL,delMAP
	LD	A,(HL)
	OR	A
	JR	Z,oum1
	DEC	(HL)
	RET
oum1	LD	(HL),oumDEL ;велич, задержки
	CALL	MEM6
	CALL	MP_OUT ;6
	CALL	BLITER ;7
	LD	HL,G_MAP1
	LD	(G_IMG),HL
	RET

OU_SCR ;режим-экран
	LD	BC,#FDFE ;'F'-fast
	IN	A,(C)
	AND	%1000
	JR	NZ,OU_S1
	LD	HL,fram
	INC	(HL)
	LD	A,(HL)
	CP	ouFAST
	RET	C
	LD	(HL),0
;
OU_S1	CALL	O12X12
	LD	A,(begBOX)
	OR	A
	RET	NZ
OU_RT	CALL	ROTATE
	LD	A,(isROT)
	OR	A
	JR	NZ,OU_RT
	RET	Z

O12X12	CALL	MEM7
	CALL	M_PLAT ;(в образе - CALL_ с искусственной меткой: слова таблицы вызовов вместо адресов)
	CALL	MEM1
	CALL	OU12M1 ;probably: окно карты 12x12 тайлов в рабочий экран DSCR (первый проход)
	CALL	S12X12
	CALL	OU12M2 ;probably: второй проход
	CALL	MEM6
	CALL	MAPCUR ;страница 6: probably: рамка/курсор окна карты
	CALL	MEM0
	CALL	flpSEL
	CALL	BLITER
	LD	HL,G_IMG1
	LD	(G_IMG),HL
	RET


MAPon	XOR	A
	LD	(delMAP),A
	CALL	MP_OFF
	CALL	BLITER
	CALL	STS
	LD	E,%00101001
	LD	HL,0
	LD	BC,#1818
	CALL	ATRBAR
	CALL	OU_MAP
	CALL	MAPwin
	LD	(isMAP),A
	RET

MAPoff	XOR	A
	LD	(isMAP),A
	CALL	O12X12
	CALL	MEM7
	JP	FRAME

MAPwin ;выв окна видимости
	CALL	STS
	LD	DE,(X0)
	LD	A,E
	ADD	A,E
	ADD	A,E
	RRCA
	RRCA
	RRCA
	AND	%11111
	LD	L,A
	LD	A,D
	ADD	A,D
	ADD	A,D
	RRCA
	RRCA
	RRCA
	AND	%11111
	LD	H,A
	CALL	ACOORD
	LD	DE,27
	LD	C,5
mwi0	LD	B,5
mwi1	LD	A,(HL)
	XOR	%01010001
	LD	(HL),A
	INC	L
	DJNZ	mwi1
	ADD	HL,DE
	DEC	C
	JR	NZ,mwi0
	RET

movWIN ;перемещ окна в карте по enter (BC-центр окна)
	LD	A,C
	CALL	iW
	LD	L,A
	LD	A,B
	CALL	iW
	LD	H,A
	LD	(X0),HL
	RET
iW	SUB	5
	JR	NC,iW1
	XOR	A
iW1	CP	52
	RET	C
	LD	A,51
	RET

MP_OFF	CALL	MP_OF1 ;очистка map в DSCR
	LD	(DSCR),HL
	RET
MP_OF1	LD	HL,#FFFF
	LD	(SET_SP+1),SP
	LD	SP,DSCR+#1800-6
	LD	B,236
mp09	DEFS	13,#E5 ;PUSH HL
	DJNZ	mp09
	JP	SET_SP

MANUAL ;обработка управляющ воздейств
	CALL	BMOV
;"H"-вкл паузу
	LD	BC,#BFFE
	IN	A,(C)
	AND	%10000
	JR	NZ,maz0
	LD	(onPAUS),A
	CPL
	JR	mau0ht
maz0 ;"Z"-вкл/выкл карту
	LD	A,(BENTER)
	OR	A
	JR	NZ,mau4
	LD	B,#FE
	IN	A,(C)
	AND	%111
	CP	%101
	LD	A,(Z_LOCK)
	JR	NZ,mau2
	OR	A
	JR	NZ,mau1
mau0	LD	A,(isMAP)
mau0ht	OR	A
	PUSH	AF
	CALL	Z,MAPon
	POP	AF
	CALL	NZ,MAPoff
	LD	A,1
	JR	mau1
mau2	XOR	A
mau1	LD	(Z_LOCK),A
mau4 ;нажатый FIRE (0-none,1-space,2-caps)
	LD	A,(CONTRB)
	BIT	4,A
	JR	NZ,maf1
	AND	%100000
	JR	NZ,maf2
	LD	BC,#FEFE
	IN	A,(C)
	AND	%1111
	CP	%1110
	JR	Z,maf2
	XOR	A
	JR	maf0
maf1	LD	A,1
	JR	maf0
maf2	LD	A,(BX)
	CP	24
	JR	C,maf2_
	LD	A,(begBOX)
	OR	A
	JR	Z,maf1 ;CAP->SPACE
maf2_	LD	A,2
maf0	LD	(T_FIRE),A ;(0-none,1-space,2-caps)
	CP	1
	RET	Z
	XOR	A
	LD	(fixTAR),A ;расфиксировать цель/поз
	LD	(fixPOS),A
	RET


SEEonn ;подключить onsee/onsee2
	LD	A,#C3 ;код jp
	JR	SEExx
SEEoff ;отключть их
	LD	A,#C9 ;код ret
SEExx	LD	(ONSEE),A
	LD	(ONSEE2),A
	RET

;-----------для работы с меню
gmMENU	CALL	MEM7
	XOR	A
	LD	(isMAP),A
	CALL	M_MENU
	CALL	aSETUP
	JP	MEM0
HlpBOX

MU_BOX ;бох меню DE-coord,bc-размер
	PUSH	HL
	DEC	B
	DEC	B
	LD	H,B
	DEC	C
	DEC	C
	LD	L,E
	LD	A,99
	CALL	PRINT
meb1	LD	A,100
	CALL	PRINT
	DJNZ	meb1
	LD	A,101
	CALL	PRINT
meb2	LD	B,H
	LD	E,L
	INC	D
	LD	A,103
	CALL	PRINT
meb4	LD	A,10
	CALL	PRINT
	DJNZ	meb4
	LD	A,104
	CALL	PRINT
	DEC	C
	JR	NZ,meb2
	LD	B,H
	LD	E,L
	INC	D
	LD	A,105
	CALL	PRINT
meb5	LD	A,106
	CALL	PRINT
	DJNZ	meb5
	LD	A,107
	CALL	PRINT
	POP	HL
	RET

_oSani ;анимация для Setup (A->DE)
_oSA1	EX	AF,AF'
	CALL	MEM1
	EX	AF,AF'
	CALL	GSADR+1
	CALL	SQROUT
	JP	MEM7

_shdw ;уст темноты (A)
	CALL	shadwS+3
	LD	DE,DSCR+#8B4
	LD	HL,shadwA
	CALL	SQROUT
	JP	MEM7


aSETUP ;исполнение установок
	CALL	FIREUP
	CALL	shadwS ;--1
	CALL	MEM6 ;--6
	CALL	setGS
	LD	A,(MUSONF)
	OR	A
	JR	NZ,aSS1
	CALL	iMUSIC ;6
aSS1	CALL	MEM0
	JP	MAPoff




;------часто используемые п/п------
IX0_HL	LD	(IX+x),L
	LD	(IX+y),H
	RET

HL_IX0	LD	L,(IX+x)
	LD	H,(IX+y)
	RET
IX_start
IX_strt_

IXt_HL	LD	(IX+tarX),L
	LD	(IX+tarY),H
	RET

HL_IXt	LD	L,(IX+tarX)
	LD	H,(IX+tarY)
	RET

HL_IXtEX	LD	A,(IX+16)
; ---- v0.04: changed/new code or data
	CP	#FF
	JR	Z,HL_IXt
	LD	L,A
	LD	H,(IX+17)
	RET

IXw_HL	LD	(IX+Xwood),L
	LD	(IX+Ywood),H
	RET

HL_IXw	LD	L,(IX+Xwood)
	LD	H,(IX+Ywood)
	RET

IX_stop	XOR	A ;стой
	LD	(IX+com),A
	LD	(IX+move),A
	LD	(IX+16),#FF
	RET

IX_amov	LD	(IX+com),3 ;иди и атакуй
	JR	ix_93a
IX_mov	LD	(IX+com),2 ;иди
ix_93a	LD	(IX+move),#80
	LD	(IX+16),#FE
	RET
; ---- v0.04: code removed (4.Z80: IX_start IX_strt_)


Aspeed0	LD	A,(IX+speed)
	AND	%11110000
	LD	(IX+speed),A
	RET

IMPIX3	LD	A,%11000000 ;начни удар/выстрел
	LD	(IX+3),A
	JP	HERMOV
GPART

loop_K	LD	B,_NHER
loopKb	LD	IX,KUNGE
	LD	DE,_LHER
	RET

loop_H	LD	B,_NHER
loopHb	LD	IX,HUMAN
	LD	DE,_LHER
	RET

DIST2 ;расст по ф-ле: max(|L-ix0|,|H-ix1|) Вх.XY-HL;Вых.A
	LD	A,L
	SUB	(IX+x)
	JR	NC,d2t1
	NEG
d2t1	LD	B,A
	LD	A,H
	SUB	(IX+y)
	JR	NC,d2t2
	NEG
d2t2	CP	B
	RET	NC
	LD	A,B
	RET

DISTde ;расст по ф-ле: max(|E-L|,|D-H|) ;Вых.A
	LD	A,L
	SUB	E
	JR	NC,d2e1
	NEG
d2e1	LD	B,A
	LD	A,H
	SUB	D
	JR	NC,d2e2
	NEG
d2e2	CP	B
	RET	NC
	LD	A,B
	RET
; ---- v0.04: changed/new code or data (4.Z80: dt1 dt2 RNDshf7 (нов коорд при убегании (вхC->выхA)))
gPAR
	LD	A,(IX+#04)
	JP	BA
RNDshf3
RNDshf7
	CALL	RND
	AND	#0F
	SUB	#07
	ADD	A,C
	CP	#3F
	JR	NC,RNDshf3
	RET
; здесь были LODrtr, LODnxt (загрузка следующего уровня: запрос диска 2, LODlev) - теперь в startm.asm; место (56 байт) занято
; небольшими новыми подпрограммами (страница 5 без запаса: адреса после #4201 закреплены, см. NOTES.md)
LVTAIL	CALL	mkIM2 ;конец LODlev: таблица IM2, массивы зданий и пули - нули
	LD	HL,MINE
	LD	DE,MINE+1
	LD	BC,64+256+784-1
	LD	(HL),0
	LDIR
	RET
; LDMPS: MPsign (страница 6 #C000, 128 байт: номера спрайтов миникарты, зависят от ландшафта: у людей 4num_m5, у кунгов 4num_m4 - как в
; образах v0.04) по MASTER; файл F_MPS = [людей 128 | кунгов 128]. Вызывает LDRES (и при старте уровня, и при загрузке сохранения).
LDMPS	LD	A,F_MPS
	LD	HL,DSCR
	CALL	READ
	LD	A,(MASTER)
	LD	HL,DSCR
	OR	A
	JR	Z,ldm1
	LD	L,128
ldm1	CALL	MEM6 ;портит BC
	LD	DE,MPsign
	LD	BC,128
	LDIR
	RET
_start
	CALL	EXE
	CALL_	shadwS
	CALL_	MEM6
	CALL_	iniBLT
	CALL_	setBLT
	CALL_	KUNFOG ;(в v0.04 людей здесь CALL_ LVSTART; в v0.04 кунгов CALL_ FOGALL и потом CALL_ LVSTART: см. KUNFOG)
	CALL_	MEM0
	CALL_	pCBr+5
	CALL_	TheEND+9
	CALL_	XY1st
	CALL_	NOPROC
	CALL_	MEM6
	CALL_	MAPLAND
	CALL_	nMUSIC
	CALL_	AICOUNT
	EXEX_
	XOR	A
	LD	(_Y0pos+2),A
ENTRY2	;вход после чтения сохранённой игры (CONTgm): перерисовать экран и в игровой цикл
	XOR	A
	LD	(isMAP),A
	CALL	EXE
	CALL_	MEM0
	CALL_	BUTCLR
	CALL_	MEM7
	CALL_	FRAME ;(страница 7)
	CALL_	OUMAIN
	EXEX_
	CALL	NNNHK ;(было LD SP,STKTOP) стек и демо-режим (demo.asm)
	CALL	EXE
	CALL_	MANUAL
	CALL_	MEM0
	CALL_	ACTION
	CALL_	mi2+6
	CALL_	setBOX
	CALL_	swpSEL
	CALL_	capSEL
	CALL_	SELECT
	CALL_	selGRP
	EXEX_
	CALL	SLOWER
	JR	C,OUTLIST
	CALL	NOPROC
	CALL	EXE
	CALL_	SPLIN
	CALL_	ANIMTR
	CALL_	impANS+39
	CALL_	SEEoff
	CALL_	SHED_K
	CALL_	SHED_p
	CALL_	v4_FX_N_3+20
	CALL_	SEEonn
	CALL_	TheEND+7
	CALL_	MEM6
	CALL_	AIGROW
	CALL_	RNDMIX
	CALL_	TICADV
	CALL_	AISEL
	CALL_	AIHEAL
	CALL_	AIREPR
	CALL_	AIPEON
	CALL_	AIDEFEND
	CALL_	HOMER
	EXEX_
OUTLIST ;probably: список кадра: MEM0, wa10c+9, MEM7, OUTBAR, OUMAIN, PAUSE и возврат в цикл игры (запись _start+56)
	CALL	EXE
	CALL_	MEM0
	CALL_	wa10c+9
	CALL_	MEM7
	CALL_	OUTBAR
	CALL_	OUMAIN
	CALL_	PAUSE
	CALL_	_start+56
; KUNFOG: запись списка _start для кунгов в v0.04: ...setBLT, FOGALL, LVSTART, MEM0...; для людей: ...setBLT, LVSTART, MEM0... Одна общая запись
; выбирает по MASTER (1 - кунги): FOGALL закрывает карту туманом (у людей в v0.04 тумана нет).
KUNFOG	LD	A,(MASTER)
	OR	A
	CALL	NZ,FOGALL ;страница 6 включена (MEM6 в списке выше)
	JP	LVSTART
NOPROC	RET ;пустая подпрограмма: записи списка _start и CALL ниже вызывали сюда (в v0.04 - RET в середине мёртвой таблицы CALL_, адреса OUTLIST+51, +110)
AT_TYP
	JR	v4_AT_TY2_1
	JR	.AT_TYP_1
	EX	AF,af'
	LD	(DE),A
	LD	(DE),A
	EX	AF,af'
	EX	AF,af'
	LD	DE,#0505
.AT_TYP_1
	EX	AF,af'
	EX	AF,af'
	EX	AF,af'
	EX	AF,af'
	EX	AF,af'
	LD	(BC),A
	EX	AF,af'
	EX	AF,af'
	EX	AF,af'
	DEC	B
	DEC	B
	DEC	B
AT_TY2
	INC	B
	INC	B
v4_AT_TY2_1
	INC	B
	LD	E,#1E
	NOP
	NOP
	LD	E,#1E
	NOP
	LD	B,#06
	LD	A,#3E
	LD	A,#3E
	JR	NC,hcTIME+24
	JR	NC,SYLF
	LD	E,#02
	LD	B,#00
bHEALT
	RET	Z
	LD	D,B
	SUB	(HL)
	LD	H,H
	AND	B
	LD	A,B
	LD	D,B
	JP	M,HE2
	LD	H,H
	AND	B
	ADC	A,H
	ADC	A,H
	INC	A
	DEFB	#FA

DISTt ;расст по ф-ле max(|L-Xtar|,|h-Ytar|) Вх.XY-HL;Вых.A (Портит B)
dt1	; (в v0.04 код удалён, метка сохранена для ссылок)
dt2	; (в v0.04 код удалён, метка сохранена для ссылок)









;*********** главн цикл *************


;CONTgm CALL INI_D2 ;загрузка отл игры
;	CALL LOD1st
;	SCF
;	CALL LOADms ;C=1
;	CALL shadwS ;--1
;	CALL MEM6   ;--6
;	CALL nMUSIC ;6
;	EI
;	JP ENTRY


LODnew ;новая игра
;загрузка и иниц. данных ур-ня
;	CALL$ bWAIT	 ;0
ENTRY ;общая точка входа для нов. игры и отгрузки
;	CALL$ putBAR ;--7
NNN ;---------игровой цикл--
;;	CALL$ isRUN  ;0
NNslow ;вывод графики
;===========================конец главного блока

;debug

DEBM1 ;
	IF	(1)==0	; ASM80: 1 (true when 0 / equal)

	CALL	MEM7
	CALL	STS
	LD	HL,ATR
	LD	DE,ATR+1
	LD	BC,#2FF
	LD	(HL),#45
	LDIR
	LD	DE,#203
	LD	BC,#1206
	CALL	MU_BOX
	LD	DE,#404
	LD	HL,DG1
	CALL	PRINTS
	LD	DE,#504
	LD	HL,DGAY
	CALL	PRINTS
	CALL	YES_NO
	LD	A,1
	JR	Z,dbb1
	DEC	A
dbb1	LD	(isGS),A
	RET
DG1	DEFB	28,82,17,83,83,10,98,86,98,10,85,26,82,10,110,83,127
DGAY	DEFB	28,82,17,83,83,10,98,81,98,10,85,26,82,10,12,86,127

	ENDIF

DEBUG ;мои отладочные процедуры


;-----------------------------
;конец DEBUG


;-----------------------------
siz2x2	EQU	%00 ;размер 2х2
siz3x3	EQU	%01 ;размер 3х3
siz2x3	EQU	%10 ;размер 2х3
avia	EQU	%100 ;авиация
carry	EQU	%1000 ;можно ли перевезти в десантном корабле
rem	EQU	%10000 ;можно ли отремонтировать
av_fear	EQU	%100000 ;не может ответить авиации
gn_fear	EQU	%1000000 ;не может ответить наземным


;h00 робот
;h01 робот(мет)
;h02 робот(цикл)
;h03 десантник
;h04 огнемётчик
;h05 волкер
;h06 зенитка
;h07 капеллан
;h08 князь
;h09 танк
;h10 штурмовик
;h11 транспорт


;k12 пеон
;k13 пеон (мет)
;k14 пеон (цикл)
;k15 кунг
;k16 кракотун
;k17 демон
;k18 ланголетта
;k19 варлок
;k20 зерг
;k21 тень
;k22 ворон
;k23 гнездолёт

;=======================

sleep	EQU	%00000010 ;когда ничего не делает, может крутиться на месте
f9	EQU	%00000100 ;умеет выполнять ф-цию #9 (отойти-вернуться)
cry	EQU	%00001000 ;кричит при смерти
medic	EQU	%00010000 ;можно подлечить
turn	EQU	%00100000 ;может превратиться в человека
pushd	EQU	%01000000 ;может быть занесён в стек охраны

;h00 робот
;h01 робот(мет)
;h02 робот(цикл)
;h03 десантник
;h04 огнемётчик
;h05 волкер
;h06 зенитка
;h07 капеллан
;h08 князь
;h09 танк
;h10 штурмовик
;h11 транспорт


;k12 пеон
;k13 пеон (мет)
;k14 пеон (цикл)
;k15 кунг
;k16 кракотун
;k17 демон
;k18 ланголетта
;k19 варлок
;k20 зерг
;k21 тень
;k22 ворон
;k23 гнездолёт

;======

bHmine	EQU	255 ;здоровье шахты

bcTIME ;время на стр-во зданий /2
	DEFB	120,80,50,100,80,60,100,40
	DEFB	110,70,60,100,60,80,100,40

;NN производств: 255-none
;0..9 наши
;10..19 враги
;20..25 заклинания
;26..31 апргрейды

hcTIME ;время на пр-во
	DEFB	80,100,100,140,#F0,140,#F0,180,200,150 ;наши
	DEFB	85,100,100,140,180,135,#F0,220,190,130 ;враги
;время на разр. закл
	DEFB	220,180,140,150,170,200

hcTUPG	EQU	204 ;время на апргрейды

;=======================

SYLF	CALL	avYLF
	CALL	outSEL
	CALL	vrYLF
	CALL	MEM4
	CALL	vbuYLF
	JR	SxS
SYRT	CALL	avYRT
	CALL	outSEL
	CALL	vrYRT
	CALL	MEM4
	CALL	vbuYRT
	JR	SxS
SXHI	CALL	avXUP
	CALL	outSEL
	CALL	vrXUP
	CALL	MEM4
	CALL	vbuXUP
	JR	SxS
SXLO	CALL	avXDW
	CALL	outSEL
	CALL	vrXDW
	CALL	MEM4
	CALL	vbuXDW
	JR	SxS
S12X12	CALL	avSHDW
	CALL	outSEL
	CALL	vSORT
	CALL	MEM4
	CALL	vbuSORT
SxS	CALL	vXPUT
	JP	MEM1
; ---- v0.04: code removed


; (здесь был wMAIN - отладочный вход v0.04: putBAR, SEEonn, setC1, setMAP, _start; теперь wGAME в startm.asm)
go_Max	EQU	41 ;номер макс прох поля
setMAP	LD	HL,MAP2 ;заполнение мап2
	LD	DE,MAP
	LD	C,64
tE1	LD	B,64
tE0	LD	A,(DE)
	OR	A
	JR	Z,tE2
	CP	go_Max
	LD	A,0
	JR	C,tE3
	INC	A
tE2	INC	A
tE3	LD	(HL),A
	INC	DE
	INC	HL
	DJNZ	tE0
	DEC	C
	JR	NZ,tE1
	RET
HlpCOL

bWAIT	CALL	CONTR
	LD	A,(CONTRB)
	AND	%10000
	JR	Z,bWAIT
	RET	NZ

putBAR ;выв панели
	CALL	OFFS
	LD	DE,DSCR ;панель прочитана в DSCR (LDRES)
	LD	HL,#0018
	LD	BC,#1808
	JP	PUTSYM

ONSEE1	CALL	MEM0 ;newall и onsee - в разн. страницах
	CALL	onsee
	JP	MEM6

BLTNEWh ;новое (C) здание для людей (A=0)
	PUSH	BC
	CALL	MEM6
	POP	BC
	XOR	A
	CALL	BLTNEW
	JP	MEM0
; ---- v0.04: code removed (4.Z80: TMOM MU_EN_ (окончание))

TMOM	; (в v0.04 код удалён, метка сохранена для ссылок)

;---------межстраничные п/п---------------

MU_EN_	; (в v0.04 код удалён, метка сохранена для ссылок)


;-----работа со стеком погибших--

PUSHdfndr ;занести данные погибшего охранника в стек
;может быть занесён в стек?
;
;
;
PUSHnew ;занести данные нового охранника в стек(A-тип, HL-коорд)
;есть место в стеке
;для шатлов - стек максимален+2
;занести в стек
;наростить стек


;----получение координат стратегической цели
getTARXY ;вых:z - цель погибла/невыбрана
;вых:nz - HL=xy_цели
;
;
;
;
; цель погибла/в здании(транспорте)


