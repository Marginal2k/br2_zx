; ---- v0.04 zzMove (455 bytes at #ED2C): probably: zzTo1: the unit moves one step towards its target (random pauses, speed limit from IX+6, 3 directions)
	LD	A,R
	AND	#0F
	JR	NZ,v4_zzTo1_1
	LD	A,(IX+#06)
	CP	#3C
	JR	C,v4_zzTo1_1
	JP	v4_zzTo1_10
	LD	A,(IX+#06)
	CP	#F0
	JR	C,v4_zzTo1_1
	LD	A,(#0000)
	CP	#03
	JR	C,v4_zzTo1_5
	JR	v4_zzTo1_7
v4_zzTo1_1
	LD	L,(IX+#0E)
	LD	H,(IX+#0F)
	CALL	IXt_HL
	IFDEF TRAPS
	JP	TRA3
	ELSE
	JP	IX_mov ;(в v0.04: JP #0000)
	ENDIF
v4_zzTo1_2
	JP	v4_mmf1_15
v4_zzTo1_3
	LD	A,(IX+#06)
	CP	#3C
	JR	C,v4_zzTo1_2
	CALL	v4_zzTo1_10
	RET	NC
	JR	v4_zzTo1_2
	LD	A,(#0000)
	CP	#03
	JR	C,v4_zzTo1_3
	LD	A,(IX+#06)
	CP	#F0
	JR	C,v4_zzTo1_2
	CALL	v4_zzTo1_18
	RET	NC
	JR	v4_zzTo1_2
v4_zzTo1_4
	LD	A,(IX+#06)
	CP	#3C
	JR	C,v4_zzTo1_2
v4_zzTo1_5
	LD	A,#01
	JR	v4_zzTo1_8
.zzTo1_6
	LD	A,(#0000)
	CP	#02
	JR	C,v4_zzTo1_4
	LD	A,(IX+#06)
	CP	#78
	JR	C,v4_zzTo1_2
	CALL	v4_zzTo1_21
	RET	NC
	JR	v4_zzTo1_2
	LD	A,(#0000)
	CP	#03
	JR	C,.zzTo1_6
	LD	A,(IX+#06)
	CP	#F0
	JR	C,v4_zzTo1_2
v4_zzTo1_7
	LD	A,#03
	JR	v4_zzTo1_8
v4_zzTo1_8
	LD	C,A
	LD	A,(IX+#04)
	CP	#06
	LD	A,#09
	JR	Z,.zzTo1_9
	LD	A,#0C
.zzTo1_9
	ADD	A,C
	LD	(IX+#09),A
	RET
v4_zzTo1_10
	CALL	HL_IX0
	LD	A,(IX+#04)
	CP	#05
	JR	NZ,.zzTo1_13
	EXX
	PUSH	IX
	CALL	loopKb
	LD	C,#30
.zzTo1_11
	LD	A,(IX+#00)
	OR	A
	JR	Z,.zzTo1_12
	LD	A,(IX+#04)
	LD	HL,HEALTH
	CALL	WT
	LD	A,L
	CP	(IX+#05)
	JR	Z,.zzTo1_12
	EXX
	CALL	df45+8
	EXX
	CP	#10
	JR	NC,.zzTo1_12
	LD	A,(HER_N)
	CP	C
	JR	Z,.zzTo1_12
	CALL	HL_IX0
	POP	IX
	LD	A,#10
	JR	v4_zzTo1_17
.zzTo1_12
	ADD	IX,DE
	INC	C
	LD	A,C
	CP	#60
	JR	C,.zzTo1_11
	JR	v4_zzTo1_16
.zzTo1_13
	PUSH	IX
	CALL	loopHb
	LD	C,#00
.zzTo1_14
	LD	A,(IX+#00)
	OR	A
	JR	NZ,.zzTo1_15
	LD	A,(IX+#01)
	OR	A
	JR	Z,.zzTo1_15
	LD	A,(IX+#04)
	CP	#08
	JR	NC,.zzTo1_15
	CALL	df45+8
	CP	#14
	JR	NC,.zzTo1_15
	CALL	HL_IXt
	POP	IX
	LD	A,#13
	JR	v4_zzTo1_17
.zzTo1_15
	ADD	IX,DE
	INC	B
	LD	A,B
	CP	#60
	JR	C,.zzTo1_14
v4_zzTo1_16
	POP	IX
	SCF
	RET
v4_zzTo1_17
	LD	(IX+#09),A
	LD	(IX+#0C),C
	LD	(IX+#08),#80
	XOR	A
	JP	IXt_HL
v4_zzTo1_18
	PUSH	IX
	CALL	loopKb
	LD	C,#30
.zzTo1_19
	LD	A,(IX+#00)
	OR	A
	JR	Z,.zzTo1_20
	LD	A,(IX+#09)
	CP	#04
	JR	NZ,.zzTo1_20
	CALL	HL_IX0
	POP	IX
	LD	A,(IX+#04)
	CP	#05
	LD	A,#12
	JR	Z,v4_zzTo1_17
	LD	A,#15
	JR	v4_zzTo1_17
.zzTo1_20
	ADD	IX,DE
	INC	C
	LD	A,C
	CP	#60
	JR	C,.zzTo1_19
	JR	v4_zzTo1_16
v4_zzTo1_21
	PUSH	IX
	LD	A,(TIC)
	RRCA
	JR	C,.zzTo1_22
	LD	A,R
	AND	#1F
	ADD	A,#08
	CALL	B_IX
	CALL	HL_IX0
	POP	IX
	JR	.zzTo1_23
.zzTo1_22
	LD	A,R
	AND	#3F
	CP	#30
	JP	NC,.zzTo1_22
	CALL	N_IX
	CALL	HL_IX0
	LD	A,(IX+#09)
	CP	#01
	POP	IX
	RET	C
.zzTo1_23
	LD	A,L
	CP	#01
	RET	C
	LD	A,(IX+#04)
	CP	#06
	LD	A,#0B
	JR	Z,v4_zzTo1_17
	LD	A,#0E
	JP	v4_zzTo1_17
;---ОБРАБОТКА НАЖАТИЯ FIRE

ACTION ;реакция на управл ***********
	LD	A,(T_FIRE)
	DEC	A
	RET	NZ
ACT_F	LD	A,(BX)
	CP	24
	RET	NC
	LD	A,(SEL_T)
	OR	A
	RET	Z
	CP	7
	RET	Z
	LD	A,(fixTAR) ;цель зафиксирована?
	OR	A
	JR	Z,acNfx
	LD	HL,G_MAP1
	LD	A,(TIC)
	RRA
	JR	C,acFx
	LD	HL,G_FIX1
acFx	LD	(G_IMG),HL
	RET
;
acNfx	LD	A,(ext_M)
	CP	3
	RET	NC
	LD	A,(F_FUNC)
;для людей/группы
	CP	#FF
	RET	NC
	LD	HL,BUT_N
	CALL	BA
;--------на цель и на поз.
	CP	16
	JP	Z,ac_BAT ;
	CP	18
	JP	Z,ac_TRN
	CP	7
	JP	Z,ac_REM ;
	EX	AF,AF'
	LD	HL,fixPOS
	LD	A,(HL)
	OR	A
	RET	NZ
	INC	(HL)
	LD	HL,G_MAP1 ;сменить курсор
	LD	(G_IMG),HL
	EX	AF,AF' ;----на поз
	CP	1
	JR	Z,ac_MOV ;
	CP	6
	JP	Z,ac_WRK ;
	CP	21
	JP	Z,ac_PAT ;
	CP	34
	JP	Z,ac_ZEN
	CP	50
	RET	C
	CP	67
	JP	C,ac_BLT ;
	CP	76
	JP	C,ac_MAG
	JR	ac_UDA

;-------------обработка возможных действий---

ac_PAT ;----патруль (C=29)
	LD	C,29
	CALL	ACTpat
	JP	preMOV

ac_MOV ;----move (C=2)
	LD	C,2
ac_MO_	CALL	ACTpos
	JP	preMOV

ac_UDA ;----атака позиции (C=27)
	LD	C,27
	JR	ac_MO_


ac_REM ;ремонт/стр-во (C=2,4,37,8)
	CALL	acXSEL
	OR	A
; ---- v0.04: changed/new code or data
	JR	Z,ac_FIX
	CP	8
; ---- v0.04: changed/new code or data
	JR	NC,ac_REb
	LD	A,(MASTER)
	OR	A
;пеон - атака
	LD	C,4
; ---- v0.04: changed/new code or data
	JR	NZ,ac_b1
	LD	A,(IX+#04)
;робот - добавь здоровья
	PUSH	HL
	LD	HL,AT_TYP
	CALL	BA
	POP	HL
	AND	rem
; ---- v0.04: changed/new code or data
	JR	Z,ac_MOV
	LD	C,37
	JR	ac_b1
ac_REb ;на рем зданий
	LD	C,37
	LD	A,(IX+4)
	CP	253
	JR	NZ,ac_bB
	LD	A,(IX+7)
	INC	A
	JR	NZ,ac_bB
;нач. стр-во
	LD	C,8
; ---- v0.04: changed/new code or data
	JR	ac_MO_


ac_BAT ;-----атака (C=3,4)
	CALL	acXSEL
	LD	C,3
	CP	7
	JR	C,ac_FI3 ;своих не атакуем/none
	LD	C,4
	JR	Z,ac_b1 ;атакуем врага
ac_bB	SET	7,H ;атакуем здание
ac_b1	LD	A,H
	EX	AF,AF'
	CALL	ACTtar
	EX	AF,AF'
	LD	L,A
	LD	H,6 ;время мигания кв. цели
ac_b2	LD	(sel_en),HL
	LD	A,H
	LD	(fixTAR),A ;цель зафиксрована
	JP	preMOV

ac_FIX	LD	C,2 ;если поз.фикс - ноне
ac_FI3	LD	HL,fixPOS
	LD	A,(HL)
	OR	A
	RET	NZ
	INC	(HL)
	LD	HL,G_MAP1 ;сменить курсор
	LD	(G_IMG),HL
	JP	ac_MO_

ac_WRK ;идти в лес/шахту (C=6,7)
	CALL	PXcorr
	CALL	GMAP
	LD	A,(HL)
	AND	#7F
	CP	103 ;штольня?
	LD	C,6
	JR	NZ,ac_wr1
	INC	C ;7
	M1toM2_
	LD	A,(HL)
	SUB	#38
	OR	#80
	LD	L,A
	LD	H,2
	CALL	ac_b2
ac_wr1	CALL	ACTwrk
	JP	preMOV

ac_BLT ;строительство для крестьян
	SUB	50
	LD	C,A
	PUSH	BC
	CALL	mayBLT
	POP	BC
	RET	NC
	PUSH	BC
	LD	A,(F_FUNC)
	CALL	GETmw
	CALL	dMN_WD
	POP	BC
	JP	C,nMN_WD
	LD	HL,(PX)
	INC	H
	INC	L
	CALL	BLTNEWh
	CALL	onsee2
	LD	C,8
	CALL	ac_MO_
	CALL	preMOV
	EX	DE,HL
	CALL	EVENTr
	JP	oneSEL

ac_TRN ;загрузи юнита в транспорт
	CALL	acXSEL
	CP	1
	JP	NZ,ac_FIX ;чужих не берём
	LD	A,H
	EX	AF,AF'
	LD	A,(IX+typ)
	LD	HL,AT_TYP
	CALL	BA
	AND	carry
	JP	Z,ac_FIX
	LD	C,6
	CALL	ACTtar
	EX	AF,AF'
	LD	L,A
	LD	H,4 ;время мигания кв. цели
	JP	ac_b2

ac_ZEN ;для базы - строить пушку
	CALL	mayBLZ
	RET	NC
	LD	A,(F_FUNC)
	CALL	GETmw
	CALL	dMN_WD
	JP	C,nMN_WD
	XOR	A
	LD	(SEL_T),A
	CALL	EVENTr
	LD	DE,(PX)
	LD	A,31
	JP	NEWBUL


ac_MAG ;магия
	SUB	67
	CP	3
	JR	NC,ac_mmg
	LD	A,(MASTER)
	OR	A
	LD	C,31
	JR	Z,ac_m3
	LD	C,34
	JR	ac_m3
ac_mmg	SUB	3
	LD	C,A
	LD	A,(MASTER)
	OR	A
	LD	B,10
	JR	Z,ac_m2
	LD	B,16
ac_m2 ;
	LD	A,C
	ADD	A,B
	LD	C,A
ac_m3	CALL	ACTpos
	JP	ac_MO_

;------------------ общ. п/п исполнения заданий

xacINI	CALL	PXcorr
xacIN_	LD	HL,SEL_T ;нач.перебора
	LD	B,(HL)
	INC	HL
	XOR	A
	LD	(SEL_Av),A
	RET

xacLOO	CALL	N_IX ;перебор
	LD	(IX+com),C
	LD	(IX+move),#80
	isAVIA_
	JR	NZ,xacLOa
	LD	(IX+tarX),E ;наземн
	LD	(IX+tarY),D
	LD	(IX+16),#FE
	LD	A,(IX+phase_) ;исполнение не сразу
	OR	A
	RET	NZ
	CALL	RND
	AND	3
	RET	Z
	ADD	A,#80-1
	LD	(IX+phase_),A
	RET
xacLOa	PUSH	DE ;авиа
	CALL	dXYpm2
	LD	(IX+tarX),E
	LD	(IX+tarY),D
	POP	DE
; ---- v0.04: changed/new code or data
	JP	Aspeed0

;---------
ACTwrk ;исполнить действие C для рабочих
ACTpos ;исполнить действие C
	CALL	xacINI
actp1	LD	A,(HL)
	INC	HL
	PUSH	HL
	CALL	xacLOO
	POP	HL
	DJNZ	actp1
	RET

ACTpat ;исполнить действие C для патруля
	CALL	xacINI
actZ1	LD	A,(HL)
	INC	HL
	PUSH	HL
	CALL	xacLOO
	CALL	HL_IX0
	CALL	IXw_HL
	POP	HL
	DJNZ	actZ1
	RET

ACTtar ;исполнить действие C на объект A'
	CALL	xacIN_
actt1	EX	AF,AF'
	CP	(HL) ;сам себя?
	JR	Z,actt7
	EX	AF,AF'
	LD	A,(HL)
	PUSH	HL
	CALL	xacLOO
	POP	HL
	EX	AF,AF'
	LD	(IX+tarN),A
actt7	EX	AF,AF'
	INC	HL
	DJNZ	actt1
	RET

;-------

preMOV ;действия перед началом движения
;*none*
	RET


acXSEL ;выбор цели для задания
;вых: A/L-тип 0(Z),1,7,8 (нет, наш, враг, дом)
;вых: H-номер цели, DE-координаты,IX -описание цели
	LD	HL,(SEL_T)
	PUSH	HL
; ---- v0.04: code removed
	CALL	oneSEL
	LD	HL,(SEL_T)
	EX	(SP),HL
	LD	(SEL_T),HL
	POP	HL
	LD	A,L
	OR	A
	RET	Z ;на пустое место
	CP	8
	PUSH	HL
	LD	A,H
	JR	C,acxs2 ;коррекция координат цели
	CALL	B_IX
	JR	acxs3
acxs2	CALL	N_IX
acxs3	CALL	HL_IX0
	EX	DE,HL
	POP	HL
	LD	A,L
	OR	A
	RET

PXcorr ;коррекция PX,если указывает на край здания (вых: HL=DE)
	LD	HL,(PX)
HLcorr ;то же для HL
	PUSH	HL
	CALL	GMAP
	LD	A,(HL)
	AND	#7F
	SUB	120
	POP	HL
	JR	C,PXcr1
	PUSH	HL
	LD	HL,PXcrT
	CALL	WT
	POP	DE
	LD	A,L
	ADD	A,E
	LD	L,A
	LD	A,H
	ADD	A,D
	LD	H,A
PXcr1	LD	E,L
	LD	D,H
	RET
;
PXcrT	DEFB	1,0,1,1,0,1,-1,1,-1,0
	DEFB	-1,-1,0,-1,1,-1

dXYpm2A	PUSH	HL ;смещение de +-2
	JR	dpm2
dXYpm2 ;смещение цели DE +-2 для авиации
	PUSH	HL
	LD	HL,SEL_Av
	LD	A,(HL)
	OR	A
	JR	NZ,dpm2
	INC	(HL)
	LD	H,A
	LD	L,A
	JR	dyp4
dpm2	CALL	RND ;смещение +-2
	AND	#1F
	CP	20
	JR	NC,dpm2
	LD	HL,GO_Ntb
	CALL	WT
dyp4	LD	A,E
	ADD	A,L
	CALL	dXYdpz
	LD	E,A
	LD	A,D
	ADD	A,H
	CALL	dXYdpz
	LD	D,A
	POP	HL
	RET
;
dXYdpz ;проверка диапазона цели авиации 1-62
	CP	1
	JR	C,dzp0
	CP	63
	RET	C
	CP	128
	JR	NC,dzp0
	LD	A,62
	RET
dzp0	LD	A,1
	RET






