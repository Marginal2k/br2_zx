;РАБОТА С АВИАЦИЕЙ (С)Copper Feet 1999

DIR_A ;напр HL->DE для авиации (-1 вниз, далее против часовой до -16)
	PUSH	HL
	LD	A,L
	SUB	E
; ---- v0.04: changed/new code or data
	JR	C,dRa1
	JP	NZ,dRa2
	POP	HL
	LD	A,H
	CP	D
	LD	A,-1
	RET	C
	LD	A,-9
; ---- v0.04: code removed
;//	LD A,#FF
	RET
;
dRa1	NEG
	LD	L,A
	LD	A,H
	SUB	D
	LD	H,-5
	JR	Z,dRa0
	JR	C,dRa3
	CP	L
	LD	A,-7
	JR	Z,dRa10
	LD	A,-8
	JR	NC,dRa10
	LD	A,-6
dRa10	POP	HL
	RET
;
dRa3	NEG
	CP	L
	LD	A,-3
	JR	Z,dRa10
	LD	A,-2
	JR	NC,dRa10
	LD	A,-4
	POP	HL
	RET
;
dRa0	LD	A,H
	POP	HL
	RET
;
dRa2	LD	L,A
	LD	A,H
	SUB	D
	LD	H,-13
	JR	Z,dRa0
	JR	C,dRa4
	CP	L
	LD	A,-11
	JR	Z,dRa20
	LD	A,-10
	JR	NC,dRa20
	LD	A,-12
dRa20	POP	HL
	RET
;
dRa4	NEG
	CP	L
	LD	A,-15
	JR	Z,dRa20
	LD	A,-16
	JR	NC,dRa20
	LD	A,-14
	POP	HL
	RET

AVspeed ;cкорость 0
	DEFB	0,2,1,2,2,2,2,1,2,0,2,-1,2,-2,1,-2
	DEFB	0,-2,-1,-2,-2,-2,-2,-1,-2,0,-2,1,-2,2,-1,2
;скорость 1
	DEFB	0,3,1,3,2,2,3,1,3,0,3,-1,2,-2,1,-3
	DEFB	0,-3,-1,-3,-2,-2,-3,-1,-3,0,-3,1,-2,2,-1,3
;скорость 2
	DEFB	0,4,2,4,3,3,4,2,4,0,4,-2,3,-3,2,-4
	DEFB	0,-4,-2,-4,-3,-3,-4,-2,-4,0,-4,2,-3,3,-2,4
;скорость 3
	DEFB	0,6,2,5,4,4,5,2,6,0,5,-2,4,-4,2,-5
	DEFB	0,-6,-2,-5,-4,-4,-5,-2,-6,0,-5,2,-4,4,-2,5


GAstop	LD	(IX+move),0
GAsto1	LD	A,(IX+speed)
	OR	#7
	LD	(IX+speed),A
	RET

GO_AVI ;перемещение авиации
	LD	A,(IX+speed)
	AND	%11110000
	JR	Z,go_avi_
;заторможен?
	CP	%00100000
	JR	NZ,go_avi_
	LD	A,(TIC3)
	OR	A
	RET	NZ
go_avi_	LD	A,(IX+move)
	OR	A
	JR	Z,GAsto1
	CP	#FF
	JR	Z,GAsto1
;
	CP	#80
	JP	C,GAdown ; торможение включено

;
	CALL	HL_IXt ;над целью?
	EX	DE,HL
	CALL	HL_IX0
	PUSH	HL
	XOR	A
	SBC	HL,DE
	POP	HL
	JP	Z,GAslow ;начать торможение
;
;разгон
	LD	A,(IX+typ) ;"тени" не разгоняются
	CP	21
	LD	A,0
; ---- v0.04: changed/new code or data
	JR	Z,gavMax
;
	LD	A,(TIC3)
	OR	A
; ---- v0.04: changed/new code or data
	JR	NZ,gavNx
	LD	A,(SIDE_N)
	OR	A
	LD	A,(hPARM+7)
	JR	Z,gavMxS1
	LD	A,(kPARM+7)
; ---- v0.04: code removed (4.Z80: gavMxS1 (для шаттлов (11/23) - разгон на 1 больше))
gavMxS1
gavMax	LD	C,A
	LD	A,(IX+speed)
	AND	%1111
	CP	C
	JR	NC,gavNx
	INC	(IX+speed)
;
gavNx ;найти следующее направление
	CALL	DIR_A
	BIT	0,A
	JR	NZ,gavD2 ;не 22.5 град
	LD	C,A
	LD	A,(IX+dir)
	AND	%11
	CP	%01
	LD	A,C
	JR	NZ,gavD2 ;предыдущее не 45 град
	NEG
	AND	#C
	CP	4
	JR	Z,gavM4
	CP	8
	JR	Z,gavM8
	CP	12
	JR	Z,gavM12
	INC	H
	JR	gavD0
gavM4	INC	L ;+
	JR	gavD0
gavM8	DEC	H
	JR	gavD0
gavM12	DEC	L
gavD0	CALL	DIR_A
	CP	C
	JR	Z,gavD2
	CP	(IX+dir)
	JR	Z,gavD2
	LD	A,C
;
gavD2 ;вырулить к направлению А
	SUB	(IX+dir)
	JR	Z,gAA1
	AND	#F
	CP	8
	JR	Z,gavRTX
	JR	C,gavRTR
gavRTL	DEC	(IX+dir)
	LD	A,(IX+dir)
	CP	-16
	JR	NC,gAA1
	LD	(IX+dir),-1
	JR	gAA1
gavRTR	INC	(IX+dir)
	JR	NZ,gAA1
	LD	(IX+dir),-16
	JR	gAA1
gavRTX	CALL	RND
	RRA
	JR	C,gavRTL
	JR	NC,gavRTR
;
GAslow ;начать торможение
	LD	A,(IX+speed)
	AND	%1111
	CP	7
	JP	C,GAstop
	LD	(IX+move),3
	CALL	Aspeed0
	JR	gAA1
;
GAdown	DEC	(IX+move) ;тормозить
; ---- v0.04: code removed
;если (speed & %1111 == 7), то speed:=0
gAA1
;найти новые пикс. коорд
	LD	A,(IX+dir)
	CPL
	LD	E,A
	LD	A,(IX+speed)
	ADD	A,A
	ADD	A,A
	ADD	A,A
	ADD	A,A ;%XXXX0000
	ADD	A,E
	LD	HL,AVspeed
	CALL	WA
	PUSH	HL
	LD	D,0
	LD	E,A
	BIT	7,E
	JR	Z,gav1X
	DEC	D ;-1
gav1X	LD	L,(IX-4)
	LD	H,(IX-3)
	ADD	HL,DE
	BIT	7,H ;пров. левой границы
	JR	NZ,gavBrX
	LD	A,H
	OR	A
	JR	NZ,gav2X
	LD	A,L
	CP	8-dxAVIA
	JR	NC,gav2X
gavBrX	LD	HL,dxAVIA
gav2X	LD	DE,1023-32+dxAVIA ;проверка правой
	PUSH	HL
	SBC	HL,DE
	POP	HL
	JR	C,gav2XR
	EX	DE,HL
gav2XR	LD	(IX-4),L
	LD	(IX-3),H
	EX	(SP),HL
	LD	D,0
	INC	HL
	LD	E,(HL)
	BIT	7,E
	JR	Z,gav1Y
	DEC	D ;-1
gav1Y	LD	L,(IX-2)
	LD	H,(IX-1)
	ADD	HL,DE
	BIT	7,H ;пров верхней
	JR	NZ,gavBrY
	LD	A,H
	OR	A
	JR	NZ,gav2Y
	LD	A,L
	CP	24+dyAVIA
	JR	NC,gav2Y
gavBrY	LD	HL,24-dyAVIA
gav2Y	LD	DE,1023-12+dyAVIA ;проверка нижней
	PUSH	HL
	SBC	HL,DE
	POP	HL
	JR	C,gav2YR
	EX	DE,HL
gav2YR	LD	(IX-2),L
	LD	(IX-1),H
;найти новые коорд (ix+0,+1)
	LD	C,0
	LD	DE,dyAVIA-8
	ADD	HL,DE
	LD	A,L
	SRL	H
	RRA
	SRL	H
	RRA
	SRL	H
	RRA
	SRL	A
	CP	(IX+y)
	JR	Z,gavSE1
	INC	C
	LD	(IX+y),A
gavSE1	POP	HL
	LD	DE,dxAVIA+8
	ADD	HL,DE
	LD	A,L
	SRL	H
	RRA
	SRL	H
	RRA
	SRL	H
	RRA
	SRL	A
	CP	(IX+x)
	JR	Z,gavSE0
	INC	C
	LD	(IX+x),A
gavSE0	LD	A,C
	OR	A
	RET	Z
	JP	ONSEE2

;-----------------

cmpAVI ;не занимает ли он одну позицию с кем-то?

	PUSH	IX
	CALL	loopHb
	LD	A,(HER_N)
	LD	B,A
	LD	C,0
onvL0	LD	A,(IX+x)
	CP	L
	JR	NZ,onvL1
	isAVIA_
	JR	Z,onvL1
	LD	A,(IX+y)
	CP	H
	JR	NZ,onvL1
	LD	A,(IX+move)
	CP	#80
	JR	Z,onvL1
	LD	A,C
	CP	B
	JR	Z,onvL1
;
	POP	IX
	EX	DE,HL
	CALL	dXYpm2A
	EX	DE,HL
	CALL	IXt_HL
onvLB	LD	(IX+move),#80
	JP	Aspeed0
;
onvL1	ADD	IX,DE
	INC	C
	LD	A,C
	CP	_NALL
	JR	C,onvL0
	POP	IX
	RET

;-----------------

ON_AVI ;зависание и выравнивание авиации после останова
	CALL	onvDXY
	LD	A,(TIC)
	RRCA
	RET	NC
	LD	A,B
	ADD	A,A
	ADD	A,A
	ADD	A,C
	OR	A
	RET	Z
	LD	HL,onvTB
	CALL	BA
;вырулить к направлению А
	SUB	(IX+dir)
	JR	Z,onv8
	AND	#F
	CP	8
	JR	C,onv7
	DEC	(IX+dir)
	LD	A,(IX+dir)
	CP	-16
	JR	NC,onv8
	LD	(IX+dir),-1
	JR	onv8
onv7	INC	(IX+dir)
	JR	NZ,onv8
	LD	(IX+dir),-16
onv8 ;
	RET

onvTB ;направления при выравнивании
	DEFB	0,-9,-1,0,-13,-11,-15,0,-5,-7,-3

onvDXY ;выравн
	LD	C,0
	LD	L,(IX-4)
	LD	H,(IX-3)
	LD	A,L
	AND	%1111
	SUB	#C ; dxAVIA+8
	JR	Z,onv0
	CALL	onvDC
	LD	(IX-4),L
	LD	(IX-3),H
onv0 ;
	LD	B,C
	LD	C,0
	LD	L,(IX-2)
	LD	H,(IX-1)
	LD	A,L
	AND	%1111
	SUB	#F ;dyAVIA-16+3&%1111
	RET	Z
	CALL	onvDC
	LD	(IX-2),L
	LD	(IX-1),H
	RET
;
onvDC	AND	%1111 ;выравнять по корд
	CP	2
	RET	C
	CP	15
	RET	NC
	CP	8
	JR	C,onvd1
	INC	HL
	INC	C
	INC	C
	RET
onvd1	DEC	HL
	INC	C
	RET
