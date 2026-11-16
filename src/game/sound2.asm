
;звуковые эффекты   (C) Copper Feet [sept.1997,99]
;--------------- Звук2 (в стр #6)-----------------



;форматы нот
;(#ff) - конец мелодии
;(N4,N5,N10,Nшум) - значение 4,5,10  и 6  регистров для С


	RET
ppsC ;
	LD	BC,#FFFD
	LD	A,4 ;частотаМЛ
	OUT	(C),A
	LD	B,#BF
	OUTI
;
	LD	B,#FF
	INC	A ;частотаCT
	OUT	(C),A
	LD	B,#BF
	OUTI
;
	LD	B,#FF
	LD	A,10 ;громкость
	OUT	(C),A
	LD	A,(levSND)
	LD	B,A
	LD	A,(HL)
	INC	HL
	SUB	B ;коррект громкости по расстоянию
	JR	NC,pps1
	XOR	A
pps1	LD	B,#BF
	OUT	(C),A
;
	LD	B,#FF
	LD	A,7 ;управление
	OUT	(C),A
	LD	B,#BF
	LD	A,E ;из протрекера
	BIT	7,(HL)
	JR	Z,pps2
	AND	%11111011 ;без шума
	JR	pps3
pps2	AND	%11011011
pps3	OUT	(C),A
;
	LD	B,#FF
	LD	A,6 ;шум
	OUT	(C),A
	BIT	7,(HL)
	JR	NZ,pps4
	OUTI
	JR	pps5
pps4	INC	HL
pps5	LD	(NOTA),HL
	RET


;-------инициализация музыки

iMUSIC	LD	A,(isGS)
	OR	A
	JP	Z,WMUSIC
	RET

;-------инициализация музыки после загрузки

nMUSIC	LD	A,(isGS)
	OR	A
	JP	Z,WMUSIC
	JP	loadGS
; ---- v0.04: code removed



;-------AY_FX ("эффекты для ЧВ-2")









SO13

SOU3 ;-тень и дальняя ракета
	DEFW	1096
	DEFB	11,31
	DEFW	946
	DEFB	12,20
	DEFW	2096
	DEFB	14,17
SOU4 ;-огнемётчик
	DEFW	796
	DEFB	15,20
	DEFW	3094
	DEFB	15,22
	DEFW	646
	DEFB	15,26
SO12 ;-ланголетта
	DEFW	4094
	DEFB	15,28
	DEFW	596
	DEFB	14,29
SOU1
SOU2
	DEFW	4094
	DEFB	14,30
	DEFW	596
	DEFB	14,27
	DEFW	4094
	DEFB	13,25
	DEFW	596
	DEFB	11,20
	DEFW	3094
	DEFB	09,10
	DEFB	#FF
; ---- v0.04: changed/new code or data
SOU0
SOU7
	DEFB	#1B,#00,#0C,#FF,#19,#00,#0F,#0A,#0F,#00,#0F,#10,#0F,#00,#0F,#14
	DEFB	#0E,#00,#0E,#17,#0E,#00,#0B,#1C,#0E,#00,#07,#1E,#FF
SO10
	DEFB	#04,#06,#0D,#01,#FF
SOU8
SOU9
SO11
SO14
	DEFB	#3C,#05,#0E,#FF,#FF
SOU6
	INCBIN	"hum/SOU6.bin"	; 53 bytes of the v0.04 image (no archive file for them)
SOU5
	DEFB	#1C,#02,#0B,#04,#62,#01,#0D,#04,#38,#02,#0A,#FF,#FF



;
;
;

;
;

SO15 ;-дом взорвали
	DEFW	1000
	DEFB	10,27
	DEFW	1200
	DEFB	14,24
	DEFW	1450
	DEFB	15,18
	DEFW	1650
	DEFB	15,15
	DEFW	1700
	DEFB	15,11
	DEFW	1800
	DEFB	15,16
	DEFW	1950
	DEFB	15,20
	DEFW	2050
	DEFB	15,26
	DEFW	2100
	DEFB	15,22
	DEFW	2200
	DEFB	15,21
	DEFW	2250
	DEFB	15,29
	DEFW	2300
	DEFB	15,23
	DEFW	2350
	DEFB	15,22
	DEFW	2400
	DEFB	15,17
	DEFW	2450
	DEFB	15,14
	DEFW	2500
	DEFB	15,10
	DEFW	2550
	DEFB	15,06
	DEFW	2600
	DEFB	15,07
	DEFW	2650
	DEFB	14,12
	DEFW	2700
	DEFB	14,18
	DEFW	2750
	DEFB	14,22
SO16 ;
SO17 ;-обычный взрыв
	DEFW	2800
; ---- v0.04: the last sound effects and the GS interface of 4_SOUND2 (4.Z80 had other code here)
	DEFB	#0E,#1B,#22,#0B,#0D,#1F,#54,#0B,#0D,#1E,#86,#0B,#0D,#1B,#1C,#0C
	DEFB	#0C,#1A,#80,#0C,#0C,#16,#E4,#0C,#0C,#11,#48,#0D,#0B,#0C,#AC,#0D
	DEFB	#0B,#07,#10,#0E,#0A,#09,#A6,#0E,#0A,#10,#3C,#0F,#08,#15,#FF

SOUNDgs
	; GS: sound C of the object IX: only when its cell is seen (map bit 7 = 0); the volume comes from the distance to the screen centre
	CALL	HL_IX0
	CALL	GMAP
	BIT	7,(HL)
	RET	NZ
	LD	HL,(X0)
	LD	A,L
	ADD	A,6
	LD	L,A
	LD	A,H
	ADD	A,7
	LD	H,A
	CALL	DIST2
	LD	E,A
	LD	A,D
	JP	GS_EFF

setGSvar	; copy the game settings into the variables of the GS driver (GS_VAR...)
	LD	DE,GS_VAR
	LD	A,(isGS)
	LD	(DE),A
	INC	DE
	LD	A,(SAVDSK+2)
	LD	(DE),A
	INC	DE
	LD	A,(MUSONF)
	LD	(DE),A
	INC	DE
	LD	A,(MASTER)
	OR	A
	JR	Z,sgs1
	LD	A,#80
sgs1	LD	HL,LEVEL
	ADD	A,(HL)
	LD	(DE),A
	INC	DE
	LD	A,(DSK_GS)
	LD	(DE),A
	INC	DE
	LD	A,(PMOUSE+1)
	LD	(DE),A
	INC	DE
	LD	A,(MUSONF+1)
	LD	(DE),A
	INC	DE
	LD	A,(SAVDSK+1)
	LD	(DE),A
	RET

loadGS	; GS: variables + function 3 (load), then like setGS from sgs2
	CALL	setGSvar
	LD	A,3
	CALL	GS_FUN
	JR	sgs2
setGS	; GS: variables + function 2, then toggling the two flags of the driver
	CALL	setGSvar
sgs2	LD	A,2
	CALL	GS_FUN
	LD	A,(GS_VAR+2)
	XOR	1
	CALL	GS_FUN
	LD	A,(GS_VAR+6)
	XOR	1
	ADD	A,4
	JP	GS_FUN
	DEFB	#13,#FE,#E4,#D0
; remains of the old code (nobody calls them) up to the music module
	INCBIN	"hum/6_junk_EBC9.bin"	; 174 bytes up to WMUSIC

;---------работа с GS-------

; SOUNDgs: see above
;
;опр видимости источника звука
;опред громкости в зависимости от дальности

;-------

;интерфейс с драйверами GS

GS_INT	EQU	WMUSIC+6
GS_EFF	EQU	WMUSIC+3
GS_FUN	EQU	WMUSIC+0
GS_VAR	EQU	WMUSIC+12










