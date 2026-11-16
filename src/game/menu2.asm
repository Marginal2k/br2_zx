; ---- v0.04: changed/new code or data (4.Z80: bSE1 eSE1 SETUP)
FIREUP ;ждать, пока кнопка огня (CONTRB бит 4) не отпущена; возврат с Z, если и не была нажата
	LD	A,(CONTRB)
	AND	#10
	RET	Z
	JR	NZ,FIREUP
v4_mB2_2
	LD	A,#C8
	LD	(MkeDIS+3),A
	XOR	A
	LD	(_S_CFt),A
	LD	HL,TXC1+20
	LD	(_S_CFx),HL
	LD	HL,KEYJOY
	PUSH	HL
	LD	DE,S_kj
	LD	BC,#000E
	LDIR
	LD	HL,S_gSPD
	LD	A,#12
	SUB	(HL)
	LD	(HL),A
	DEC	HL
	DEC	(HL)
	LD	HL,#0000
	LD	(S_kb),HL
	POP	HL
	LD	A,(HL)
	OR	A
	RET	NZ
	LD	HL,(KEYS)
	LD	DE,KBR
	SBC	HL,DE
	LD	HL,S_kb
	JR	Z,.mB2_3
	INC	HL
.mB2_3
	INC	(HL)
	RET
v4_mB2_4
	LD	HL,S_kj
	PUSH	HL
	LD	DE,KEYJOY
	LD	BC,#000E
	LDIR
	LD	HL,SLOW
	LD	A,#12
	SUB	(HL)
	LD	(HL),A
	DEC	HL
	INC	(HL)
	POP	HL
	LD	A,(HL)
	OR	A
	RET	NZ
	DEC	HL
	LD	A,(HL)
	OR	A
	LD	HL,KBR
	JR	Z,v4_mB2_5
	LD	HL,INT2
v4_mB2_5
	LD	(KEYS),HL
	RET
	CALL	v4_mB2_2
	CALL	FIREUP
	CALL	oSETUP
	JP	v4_mB2_4
setuTB
	NOP
	NOP
	RLCA
	DEFB	#18
;cтраница 7

;----работа с меню
bSETUP ;нач
;
bSE1	; (в v0.04 код удалён, метка сохранена для ссылок)

eSETUP ;out menu
eSE1	; (в v0.04 код удалён, метка сохранена для ссылок)

SETUP	; (в v0.04 код удалён, метка сохранена для ссылок)

	DEFB	#72
	DEFW	#0B01,#170D
	DEFB	#D
	DEFW	#0800,#1609
	DEFB	#79
	DEFW	#0302,#1506
	DEFB	#70
	DEFW	#0C13,#0407
	DEFB	#60

oSETUP ;блок настроек
	LD	HL,(86*256)+12 ;AY
	LD	A,(isGS)
	OR	A
	JR	Z,supA
	LD	HL,(83*256)+110 ;GS
supA	LD	(TX_MUS),HL
	LD	(TX_EFF),HL
;
	CALL	STD
	LD	HL,setuTB
	LD	B,5
sup1	PUSH	BC
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	INC	HL
	LD	C,(HL)
	INC	HL
	LD	B,(HL)
	INC	HL
	INC	HL
	CALL	MU_BOX
	POP	BC
	DJNZ	sup1
;выв текстов
	LD	DE,#102
	LD	HL,TXC1
	CALL	PRINTS
	LD	DE,#403
	LD	HL,TXM2
	CALL	PRINTL
; ---- v0.04: changed/new code or data
	LD	DE,#0503
	LD	HL,TXM3
	CALL	PRINTL
; ---- v0.04: changed/new code or data
	LD	DE,#0603
	LD	HL,TXM4
	CALL	PRINTL
; ---- v0.04: changed/new code or data
	LD	DE,#0703
	LD	HL,TXM5
	CALL	PRINTL
;
	LD	DE,#902
	LD	HL,TXchan
	LD	A,(isGS)
	OR	A
	CALL	NZ,PRINTS
	LD	DE,#A02
	LD	HL,TX_MUS
	CALL	PRINTL
; ---- v0.04: changed/new code or data
	LD	DE,#0B02
	LD	HL,TX_EFF
	CALL	PRINTL
; ---- v0.04: changed/new code or data
	LD	DE,#0C02
	LD	HL,TXcolr
	CALL	PRINTL
; ---- v0.04: changed/new code or data
	LD	DE,#0D02
	LD	HL,TXshdw
	CALL	PRINTL
; ---- v0.04: changed/new code or data
	LD	DE,#0E02
	LD	HL,TXdisc
	CALL	PRINTL
; ---- v0.04: changed/new code or data
	LD	DE,#0F02
	LD	HL,TXgMSG
	LD	A,(isGS)
	OR	A
	CALL	NZ,PRINTS
	LD	DE,#1202
	LD	HL,TXM9
	CALL	PRINTS
	LD	DE,#1502
	LD	HL,TXM10
	CALL	PRINTS
;раскрас
	LD	HL,setuTB
	CALL	STS
	LD	B,5
sup2	PUSH	BC
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	INC	HL
	LD	B,(HL)
	INC	HL
	LD	C,(HL)
	INC	HL
	LD	A,(HL)
	INC	HL
	PUSH	HL
	EX	DE,HL
	LD	E,A
	LD	A,(isCOLR)
	OR	A
	JR	NZ,sup3
	LD	E,#45
sup3	CALL	ATRBAR
	POP	HL
	POP	BC
	DJNZ	sup2
	LD	HL,#3030
	LD	(ATR+532),HL
	LD	(ATR+564),HL
	LD	HL,#7A7A
	LD	(ATR+468),HL
	LD	(ATR+436),HL
Setup0	CALL	BLITE2
	CALL	oSETpr
	CALL	Copper
	CALL	BMOV
	CALL	fSzone
	HALT
	JR	Setup0

BLITE2	CALL	BLITER
	JP	V_PUT2

TXM2	DEFB	22,59,48,50,56,48,66,67,64,48,10,32,12,26,28,24,127
TXM3	DEFB	20,61,66,53,64,68,53,57,65,10,02,127
TXM4	DEFB	22,53,60,63,65,66,62,61,10,52,54,62,57,65,66,56,58,127
TXM5	DEFB	22,53,60,63,65,66,62,61,10,60,75,72,58,48,127
TX_MUS	DEFB	12,86,10,24,67,55,75,58,48,127
TX_EFF	DEFB	12,86,10,40,68,68,53,58,66,75,127
TXcolr	DEFB	34,50,53,66,61,48,79,10,56,51,64,48,127
TXdisc	DEFB	26,66,51,64,67,55,58,56,10,61,48,10,87,10,88,127
TXshdw	DEFB	30,53,61,56,10,48,50,56,48,70,56,56,127
TXchan	DEFB	85,33,10,58,48,61,48,59,75,127
TXgMSG	DEFB	29,62,62,49,73,53,61,56,79,127
TXlevM	DEFB	108,29,85,109,127
TXM9	DEFB	24,84,81,10,10,22,67,64,65,62,64,10,10,24,12,33,127
TXM10	DEFB	24,84,81,10,29,58,62,64,62,65,66,74,10
	DEFB	56,51,64,75,10,24,12,33,127


;врем парм - порядок неизm
S_kb	DEFB	1 ;
S_in2	DEFB	0 ;
S_kj	DEFB	0
S_km	DEFB	0

S_GScn	DEFB	1
S_Mus	DEFB	1
S_Eff	DEFB	0
S_colr	DEFB	1
S_shd	DEFB	1
S_disk	DEFB	0
S_GSms	DEFB	0
S_GSml	DEFB	40

S_cSPD	DEFB	4
S_gSPD	DEFB	16
S_ani	DEFB	1
S_vis	DEFB	0

;
_S_cnt	DEFB	1
_S_cn_	DEFB	1
_S_CFx	DEFW	0
_S_CFt	DEFB	0
_S_CFc	DEFB	0

_oSpx	LD	A,96
_oSpx1	ADD	A,(HL)
_oSpx2	INC	HL
	CALL	PRINT
	INC	D
	DEC	E
	RET

_oSlev	LD	A,(HL) ;уров gs
	LD	E,A
	LD	D,0
	CALL	BCD
	LD	HL,(DCstr+3)
	LD	(TXlevM+1),HL
	LD	HL,TXlevM
	LD	DE,#A11
	JP	PRINTS

_oSdsk	LD	A,(HL)
	PUSH	HL
	LD	HL,_nSds
	CALL	BA
	POP	HL
	JR	_oSpx2
_nSds	DEFB	12,14,29,102

oSETpr ;выв парм. сетупа
	CALL	STD
	LD	DE,#415
	LD	HL,S_kb
	LD	B,4
oSP1	CALL	_oSpx
	DJNZ	oSP1
	LD	DE,#90F
	LD	A,(isGS)
	OR	A
	JR	Z,oSP2a
	LD	A,1
	CALL	_oSpx1
	JR	oSP2b
oSP2a	INC	HL
	INC	D
oSP2b	LD	B,3
oSP2	CALL	_oSpx
	DJNZ	oSP2
	LD	A,(HL)
	OR	A
	JR	NZ,oSP21
	LD	A,91
oSP21	CALL	_oSpx2
	CALL	_oSdsk
	LD	A,(isGS)
	OR	A
	JR	Z,oSP4
	CALL	_oSpx
	CALL	_oSlev
oSP4	LD	HL,S_cSPD
	LD	DE,#1302
	LD	B,14
	CALL	_oSlin
	LD	DE,#1602
	LD	B,19
	CALL	_oSlin
	LD	HL,S_gSPD
	LD	A,18
	SUB	(HL)
	LD	(SLOW),A
	CALL	SLOWER
	JR	C,oSP3
	LD	A,(S_ani)
	LD	(isANI),A
	LD	A,96
	LD	DE,DSCR+#1014
	CALL	_oSani
	CALL	ANIMTR
oSP3	LD	A,(S_vis)
	JP	_shdw

_oSlin ;выв рулера (B-длина)
	LD	A,92
	CALL	PRINT
_oSl1	LD	A,93
	CALL	PRINT
	DJNZ	_oSl1
	LD	A,95
	CALL	PRINT
	LD	A,(HL)
	INC	HL
	ADD	A,3
	LD	E,A
	LD	A,94
	JP	PRINT

SzoneT ;X,widhtX, Y,widhtY
	DEFB	3,20,4,3
	DEFB	3,20,7,1
	DEFB	2,15,9,7
	DEFB	3,14,18,3
	DEFB	3,19,21,3
	DEFB	19,4,12,3
	DEFB	19,4,16,3
	DEFB	24,8,0,24
;
	DEFB	17,2,9,3
	DEFB	19,2,9,3


SFU5	LD	HL,S_vis ;темнота
	JR	SFU_

SFU6	LD	HL,S_ani ;анимация
	JR	SFU_

SFU0	LD	HL,S_kb ;тип упр
	PUSH	HL
	LD	(HL),0
	INC	HL
	LD	(HL),0
	INC	HL
	LD	(HL),0
	POP	HL
	CALL	BA
	INC	(HL)
	RET

SFU1	LD	HL,S_km ;мыша
SFU_	LD	A,(_S_cnt)
	OR	A
	RET	NZ
	LD	A,(HL)
	XOR	1
	LD	(HL),A
	RET

SFU2	EX	AF,AF' ;основной набор параметров
	LD	A,(_S_cnt)
	OR	A
	RET	NZ
	EX	AF,AF'
	LD	HL,S_GScn
; ---- v0.04: changed/new code or data (4.Z80: sfu2b sfu2gs (немедл ини))
	CP	#06
	JR	Z,.SFU2_1
	CP	#04
	JR	NC,v4_SFU2_3
.SFU2_1
	CALL	BA
	XOR	#01
	LD	(HL),A
	LD	A,(isGS)
	OR	A
	RET	Z
v4_SFU2_2
	JP	SOUNDXn+10
v4_SFU2_3
	CALL	BA
	INC	(HL)
	LD	A,(HL)
	CP	#04
	RET	C
	LD	(HL),#00
	RET
	LD	A,(BX)
	SUB	#03
	LD	(S_cSPD),A
	RET
	LD	A,(BX)
	SUB	#03
	LD	(S_gSPD),A
	RET
	LD	A,(_S_cnt)
	OR	A
	RET	NZ
	POP	AF
	RET
	LD	HL,S_GSml
	LD	A,(HL)
	OR	A
	RET	Z
	DEC	(HL)
	JR	v4_SFU2_2
	LD	HL,S_GSml
	LD	A,(HL)
	CP	#40
	RET	NC
	INC	(HL)
	JR	v4_SFU2_2
	POP	HL
	JP	M,SFU1
	NOP
	EI
	DEC	HL
	EI
	INC	(HL)
	EI
	RST	#10
	JP	M,SFU6
	DEC	A
	EI
	LD	B,H
	EI
	LD	C,L
	EI
fSzone
	LD	HL,_S_cn_
	LD	A,(HL)
	LD	(_S_cnt),A
	LD	A,(CONTRB)
	LD	(HL),A
	AND	#10
	RET	Z
	LD	B,#00
	LD	HL,SzoneT
.fSzone_1
	PUSH	HL
	CALL	.fSzone_3
	POP	HL
	JR	C,.fSzone_2
	INC	HL
	INC	HL
	INC	HL
	INC	HL
	INC	B
	LD	A,B
	CP	#0A
	JR	C,.fSzone_1
	RET	NC
.fSzone_2
	PUSH	AF
	LD	A,B
	LD	HL,v4_SFU2_3+55
	CALL	WT
	POP	AF
	JP	(HL)
.fSzone_3
	LD	DE,(BX)
	LD	A,E
	SUB	(HL)
	INC	HL
	CP	(HL)
	RET	NC
	LD	A,D
sfu2b	; (в v0.04 код удалён, метка сохранена для ссылок)
sfu2gs	; (в v0.04 код удалён, метка сохранена для ссылок)









	INC	HL
	SUB	(HL)
	INC	HL
	CP	(HL)
	RET

TXC1	DEFB	10,10,35,80,64,61,75,57,10
	DEFB	14,62,64,62,61,10,91,10,2,10,10,127
TXC2	DEFB	12,50,66,62,64,10
	DEFB	14,45,29,45,24,53,52,61,62,61,62,51,62,50,127
TXC3	DEFB	29,26,28,28,17,82,10,85,17,17,30,10,10,87,65,88,1,9,9,9,127
TXC4	DEFB	10,10,10,29,48,61,58,66,91,27,53,66,53,64,49,67,64,51
	DEFB	10,10,10,127,126

;-----pM

Copper	LD	HL,(_S_CFx)
	LD	A,(HL)
	CP	127
	JR	NZ,Cop1
	LD	HL,_S_CFt
	INC	(HL)
	LD	A,(HL)
	CP	60
	RET	C
	LD	A,2
	LD	(_S_CFc),A
	LD	(_S_CFt),A
	LD	HL,(_S_CFx)
	INC	HL
	LD	A,(HL)
	CP	126
	JR	NZ,Cop2
	LD	HL,TXC1
Cop2	LD	(_S_CFx),HL
	RET
Cop1	LD	HL,_S_CFc
	LD	E,(HL)
	INC	(HL)
	LD	D,1
	LD	HL,(_S_CFx)
	LD	A,(HL)
	INC	HL
	LD	(_S_CFx),HL
	CALL	PRINT
	RET



TXMM1	DEFB	10,31,65,66,48,61,62,50,56,66,74,10,62,63,70,56,56,127 ;setup
TXMM2	DEFB	10,10,29,62,69,64,48,61,56,66,74,10,56,51,64,67,127 ;save
TXMM3	DEFB	10,17,73,80,10,62,52,61,48,10,63,62,63,75,66,58,48,127 ;restart
TXMQS5	DEFB	13,75,65,66,64,62,53,10,65,62,69,64,48,61,53,61,56,53,127 ;q-sav
TXMQL6	DEFB	10,13,75,65,66,64,48,79,10,55,48,51,64,67,55,58,48,127 ;q-load
TXMM4	DEFB	10,10,19,48,58,62,61,71,56,66,74,10,56,51,64,67,127 ;exit

M_MENU ;>>главное меню
	CALL	_V_OFF
	CALL	STS
;пункты
	LD	HL,#402
	PUSH	HL
	LD	BC,#0F14
	LD	E,#69
	CALL	ATRBAR
	LD	BC,#140F
	POP	DE
	CALL	MU_BOX
;
	LD	HL,TXMM1
	LD	DE,#603
	LD	B,6
; ---- v0.04: changed/new code or data (4.Z80: M_M2 M_M3 M_M30)
.M_MENU_1
	PUSH	DE
	CALL	PRINTS
	INC	HL
	POP	DE
	INC	D
	INC	D
	DJNZ	.M_MENU_1
	XOR	A
	LD	(V_FLAG),A
	CALL	FIREUP
.M_MENU_2
	CALL	Mfunc
	LD	B,#06
	LD	HL,#1003
.M_MENU_3
	LD	A,D
	INC	A
	CP	B
	LD	E,#79
	JR	NZ,.M_MENU_4
	LD	E,#72
.M_MENU_4
	PUSH	HL
	PUSH	DE
	PUSH	BC
	LD	BC,#0112
	CALL	ATRBAR
	POP	BC
	POP	DE
	POP	HL
	DEC	H
	DEC	H
	DJNZ	.M_MENU_3
	HALT
	LD	A,(CONTRB)
	AND	#10
	JR	Z,.M_MENU_2
	LD	HL,(BX)
	LD	BC,#101F
	SBC	HL,BC
	JR	NZ,v4_M_MD_1
	LD	HL,MSElog
	LD	A,(HL)
	XOR	#0A
	LD	(HL),A
	LD	A,#50
	LD	(ATR+#1FF+#20),A
	JP	DELAY
M_MD
	LD	A,(SAVDSK)
	LD	HL,_nSds
	CALL	BA
	LD	(TXMsav+8),A
	LD	(TXMqsv+12),A
	LD	(TXMqld+12),A
	RET
v4_M_MD_1
	PUSH	DE
	CALL	M_MD
	CALL	_V_OFF
	POP	DE
	LD	A,D
	CP	#FF
	RET	Z
	OR	A
	JP	Z,v4_mB2_5+4
	SUB	#02
	JP	C,M_M9
	PUSH	AF
	ADD	A,A
	ADD	A,#09
	LD	D,A
	LD	E,#01
	PUSH	DE
	LD	BC,#1603
	CALL	MU_BOX
	POP	HL
	POP	AF
	PUSH	AF
	PUSH	HL
	LD	BC,#0316
	LD	E,#72
	DEC	A
	JR	NZ,.M_MD_2
	LD	E,#44
.M_MD_2
	CALL	ATRBAR
	POP	DE
	INC	D
	INC	E
	POP	AF
	PUSH	AF
	LD	HL,TXMx
	CALL	WT
	CALL	PRINTS
	CALL	PRINTYN
	CALL	YES_NO
	JR	Z,.M_MD_3
	POP	AF
	RET
.M_MD_3
	POP	AF
	LD	HL,.M_MD_3+8
	CALL	WT
	JP	(HL)
; пункты меню паузы: заново, быстро сохранить, быстро загрузить, выход в меню (в v0.04 здесь были адреса данных: пункты не работали)
	DEFW	LODrtr,qSAVE,qLOAD,toMENU
	DEFS	16 ;(здесь была процедура, затиравшая переменные: место сохранено - страница 7 не перемещается)
M_M2	; (в v0.04 код удалён, метка сохранена для ссылок)
;опрос гл.меню
;
M_M3	; (в v0.04 код удалён, метка сохранена для ссылок)
M_M30	; (в v0.04 код удалён, метка сохранена для ссылок)


M_M33 ;по ф-циям
;exit menu


eXXi ;exit

YES_NO	LD	BC,#DFFE ;Z-Yes/NZ-No
	IN	A,(C)
	AND	#10
	RET	Z
	LD	B,#7F
	IN	A,(C)
	CPL
	AND	8
	RET	NZ
; ---- v0.04: changed/new code or data
	JR	YES_NO

qSAVE	XOR	A
	JP	SAVgam

Mfunc	CALL	BMOV ;(D:=#FF,0-3)
	LD	D,#FF
	LD	A,(BX)
	CP	3
	RET	C
	CP	21
	RET	NC
	LD	A,(BY)
	SUB	6
	RET	C
	CP	11
	RET	NC
	BIT	0,A
	RET	NZ
	LD	D,A
	SRL	D
	RET


TXMMex	DEFB	10,10,27,64,62,73,48,53,60,65,79,10,127
TXMqsv	DEFB	19,48,63,56,65,48,66,74,10,61,48,10,12,43,127
TXMqld	DEFB	19,48,51,64,67,55,56,66,74,10,65,10,12,43,127
TXMrst	DEFB	10,10,10,28,53,65,66,48,64,66,10,127
TXMsav	DEFB	61,48,10,52,56,65,58,10,00,43,127 ;на диск Х
TXMx	DEFW	TXMrst,TXMqsv,TXMqld,TXMMex

M_M9 ;меню save
	CALL	M_MD
	LD	HL,#306
	PUSH	HL
	LD	BC,#C0C
	PUSH	BC
	LD	E,#6
	CALL	ATRBAR
	POP	BC
	POP	DE
	CALL	MU_BOX
	LD	B,8
	LD	DE,#C08
	LD	HL,TXMgme
M_M90	PUSH	HL
; ---- v0.04: changed/new code or data
	PUSH	DE
	PUSH	BC
	LD	A,B
	LD	(TXMgme+7),A
	CALL	PRINTL
	POP	BC
; ---- v0.04: changed/new code or data
	POP	DE
	POP	HL
	DEC	D
; ---- v0.04: changed/new code or data
	DJNZ	M_M90
	CALL	V_GET1
	XOR	A
	LD	(V_FLAG),A
	CALL	FIREUP
M_M91	HALT
	CALL	BMOV
	LD	D,#FF
	LD	HL,(BX)
	LD	A,L
	SUB	6
	CP	12
	JR	NC,M_M92
	LD	A,H
	SUB	5
	CP	8
	JR	NC,M_M92
	LD	D,A
M_M92	LD	B,8
	LD	HL,#C07
M_M94	PUSH_
	LD	A,D
	INC	A
	CP	B
	LD	E,#6
	JR	NZ,M_M93
	LD	E,#73
M_M93	LD	BC,#10A
	CALL	ATRBAR
	POP_
	DEC	H
	DJNZ	M_M94
	LD	A,(CONTRB)
	AND	%10000
	JR	Z,M_M91
	CALL	FIREUP
	LD	A,D
	CP	#FF
	RET	Z
	PUSH	AF
	CALL	_V_OFF
	LD	BC,#0416
	LD	HL,#1001
	LD	E,#44
	PUSH	HL
	CALL	ATRBAR
	POP	DE
	LD	BC,#1604
	CALL	MU_BOX
	LD	HL,TXMM2
	LD	DE,#1103
	CALL	PRINTL
; ---- v0.04: changed/new code or data
	LD	DE,#1204
	LD	HL,TXMsav
	CALL	PRINTS
	CALL	PRINTYN
	CALL	YES_NO
	POP	BC
	RET	NZ
	LD	A,B
	INC	A
	JP	SAVgam

;----окончание
MU_END ;A=1/2 -победа/поражение
	PUSH	AF
	CALL	STS
	CALL	_V_OFF
	POP	AF
	DEC	A
	JR	NZ,meMIS
;победа
	LD	DE,#702
	PUSH	DE
	LD	BC,#140C
	CALL	MU_BOX
	POP	HL
	LD	BC,#0C14
	LD	E,%01010101
	CALL	ATRBAR
	LD	DE,#909
	LD	HL,Evic1
	CALL	PRINTS
	LD	DE,#A03
	LD	HL,Evic2
	CALL	PRINTS
	LD	DE,#C05
	CALL	TUtime
	LD	DE,#1003
	LD	HL,TXMM2
	CALL	PRINTS
	LD	DE,#1109
	CALL	PRINTYN
; ---- v0.04: changed/new code or data
	LD	HL,#0903
	LD	BC,#0612
	LD	E,#4D
	CALL	ATRBAR
	CALL	YES_NO
	CALL	Z,M_M9
	JP	LODnxt
meMIS ;поражение
	LD	DE,#802
	PUSH	DE
	LD	BC,#140A
	CALL	MU_BOX
	POP	HL
	LD	BC,#A14
	LD	E,%01111010
	CALL	ATRBAR
	LD	DE,#A06
	LD	HL,Emis1
	CALL	PRINTS
	LD	DE,#C07
	LD	HL,Emis2
	CALL	PRINTS
	LD	DE,#F05
	PUSH	DE
	LD	HL,Emis3
	CALL	PRINTS
	POP	HL
	LD	BC,#10F
	LD	E,%01110010
	CALL	ATRBAR
	CALL	bWAIT
	CALL	FIREUP
	JP	LODrtr

Evic1	DEFB	27,26,13,17,16,12,47,127 ;ПОБЕДА!
Evic2	DEFB	19,48,52,48,61,56,53,10,50,75,63,62,59,61,53,61,62,47,127
Emis1	DEFB	14,75,10,63,62,66,53,64,63,53,59,56,127
Emis2	DEFB	63,62,64,48,54,53,61,56,53,47,127
Emis3	DEFB	27,62,63,75,66,48,57,66,53,65,74,10,53,73,80,127 ;try again
Ey_n	DEFB	87,86,90,81,88,44,127

_V_OFF ;отруби курсор
	LD	A,2
	LD	(V_FLAG),A
	JP	V_PUT1

PRINTYN	LD	HL,Ey_n
	JP	PRINTS
; ---- v0.04: changed/new code or data (4.Z80: PRINTL)
	DEFS	72






