
;--------работа со зданиями-------

;поиск зданий и запoлн данных
iniBLT	LD	HL,MINE
	PUSH	HL
	LD	(HL),0
	LD	DE,MINE+1
	LD	BC,64+511 ;MINE, HBUILD и KBUILD (подряд, как в v0.04)
	LDIR
	EXX
	LD	DE,8
	LD	HL,datMIN
	EXX
	LD	HL,HBUILD
	LD	DE,KBUILD
	LD	A,(MASTER)
	OR	A
	JR	Z,iTs
	EX	DE,HL
iTs	PUSH	HL
	PUSH	DE
	POP	IY
	POP	IX
	POP	HL
	LD	DE,MAP
	LD	C,0
iT0	LD	B,0
iT1	LD	A,(DE)
	CP	103
	JP	C,iT2
	JR	NZ,iT3
	LD	(HL),B ;шахта
	INC	L
	LD	(HL),C
	INC	L
	LD	(HL),255 ;здоровье
	INC	L
	LD	(HL),bHmine
	INC	L
	EXX
	LD	A,(HL)
	INC	L
	EXX
;деньги
	LD	(HL),A
	INC	L
	EXX
	LD	A,(HL)
	INC	L
	EXX
	LD	(HL),A
	INC	L
	LD	(HL),127 ;здоровье/2
	INC	L
	INC	L
	JR	iT2
;
iT3	CP	120
	JR	NC,iT2
	SUB	104
	CP	8
	JR	NC,iT4
iT30	LD	(IX),B ;зд.наших
	LD	(IX+y),C
	LD	(IX+2),A
	PUSH	HL
	LD	HL,bHEALT
	CALL	BA
	POP	HL
	LD	(IX+3),A
	CALL	bHE75p
	LD	(IX+6),A
	LD	(IX+4),255
	EXX
	ADD	IX,DE
	EXX
	JR	iT2
;
iT4	LD	(IY),B ;зд.врагов
	LD	(IY+1),C
	LD	(IY+2),A
	PUSH	HL
	LD	HL,bHEALT
	CALL	BA
	POP	HL
	LD	(IY+3),A
	CALL	bHE75p
	LD	(IY+6),A
	LD	(IY+4),255
	EXX
	ADD	IY,DE
	EXX
;
iT2	INC	DE
	INC	B
	LD	A,B
	CP	64
	JP	C,iT1
	INC	C
	LD	A,C
	CP	64
	JP	C,iT0
	RET

setBLT	LD	IX,MINE ;расст здан в мап2
	LD	BC,#4838
	LD	DE,8
sBL0	LD	A,(IX)
	OR	A
	JR	Z,sBL1
	LD	L,A
	LD	H,(IX+y)
	CALL	GMAP2
	LD	(HL),C
sBL1	INC	C
	ADD	IX,DE
	DJNZ	sBL0
	RET

bHE75p ;получить 75% от A
	PUSH	HL
	LD	L,A
	SRL	L
	SRL	L
	SUB	L
	POP	HL
	RET

BLTNEW ;новое здание (Вх: HL-coord,C-type,A=0/1-наш/не наш)
	EXX
	LD	DE,8
	LD	HL,HBUILD
	LD	BC,#2008
	OR	A
	JR	Z,bNW0
	LD	HL,KBUILD
	LD	C,40
bNW0	LD	A,(HL)
	OR	A
	JR	Z,bNW1
	ADD	HL,DE
	INC	C
	DJNZ	bNW0
	RET ;нет места
bNW1	PUSH	HL
	POP	IX
	EXX
	CALL	IX0_HL
	LD	(IX+2),C
	LD	A,C
	LD	HL,bHEALT
	CALL	BA
	LD	(IX+3),A
	CALL	bHE75p
	LD	(IX+6),A
	LD	A,C
	LD	HL,bcTIME
	CALL	BA
	LD	(IX+5),A
	LD	(IX+4),253
	LD	(IX+7),255
	EXX
;
placeB ;разместить на карте здание No.C/IX
	CALL	HL_IX0
	CALL	GMAP2
	LD	A,C
	ADD	A,#38
	LD	(HL),A ;# в MAP2
	PUSH	HL
	LD	B,2
	LD	DE,-64
	INC	L ;3x3
	LD	(HL),B ;вокруг - непрох
	DEC	L
	DEC	L
	LD	(HL),B
	ADD	HL,DE
	LD	(HL),B
	INC	L
	LD	(HL),B
	INC	L
	LD	(HL),B
	LD	DE,126
	ADD	HL,DE
	LD	(HL),B
	INC	L
	LD	(HL),B
	INC	L
	LD	(HL),B
	POP	HL
	M2toM1_
	LD	A,(IX+4)
	LD	B,102 ; нач
	CP	253
	JR	Z,pBB30
	DEC	B ;cеред
	CP	254
	JR	Z,pBB30
	LD	A,(IX+2)
	ADD	A,104
	LD	B,A
pBB30	LD	(HL),B
	INC	L
	LD	(HL),124
	DEC	L
	DEC	L
	LD	(HL),120
	LD	DE,-64
	ADD	HL,DE
	LD	(HL),121
	INC	L
	LD	(HL),122
	INC	L
	LD	(HL),123
	LD	DE,126
	ADD	HL,DE
	LD	(HL),127
	INC	L
	LD	(HL),126
	INC	L
	LD	(HL),125
	RET


;------главный цикл обработки зданий ------------------------

HOMER ;обработка шахт
	XOR	A
	LD	(brNUM),A ;очистить список горящих зданий
	LD	IX,MINE
	LD	DE,8
	LD	B,E ;8
	LD	C,D ;0
Mim0	LD	A,(IX)
	OR	A
	JR	Z,Mim1
;шахты не подвержены ударам
	LD	(IX+3),255
;;LD A,(IX+3)
;;OR A
;;JR Z,KilMim
;;CP (IX+6)
;;CALL C,HomBrk
;деньги есть?
	LD	A,(IX+4)
	OR	(IX+5)
; ---- v0.04: changed/new code or data
	JR	Z,KilMim
Mim1	ADD	IX,DE
	INC	C
	DJNZ	Mim0
;
;обработка зданий
	LD	HL,SIDE_N
	LD	(HL),D ;свои здания
	PUSH	HL
	CALL	HOMER_
	POP	HL
	INC	(HL) ;здания врага
HOMER_	LD	B,32 ;в С - номер
Hom0	LD	A,(IX)
	OR	A
	JR	Z,Hom1
	LD	A,(IX+3)
	OR	A
; ---- v0.04: changed/new code or data
	JR	Z,KilHom
	CP	(IX+6)
	CALL	C,HomBrk
	LD	A,(IX+4)
	INC	A
	JR	Z,Hom1
	CP	#80
	PUSH	AF
	CALL	NC,HomBld
	POP	AF
	CALL	C,HomFct
Hom1	ADD	IX,DE
	INC	C
	DJNZ	Hom0
	RET

HomBrk ;занести повреждённое здание C в список brHom для vFLAME
	LD	HL,brNUM
	LD	A,(HL)
	CP	24
	RET	NC
	INC	(HL)
	INC	HL
	CALL	BA
	LD	(HL),C
	LD	A,C
	CP	8
	RET	C
	CP	8+32
	RET	NC
	LD	A,(TIC)
	AND	#7
	JR	NZ,Hmbr1
	DEC	(IX+3) ;наши здания сгорают
; ---- v0.04: changed/new code or data (4.Z80: Hmbr1)
Hmbr1
	LD	A,#01
	LD	(LED+5),A ;on индик5
; ---- v0.04: code removed
	RET

KilHom ;разрушть здание
	CALL	DESTRY
; ---- v0.04: changed/new code or data
	JR	Hom1

KilMim ;разрушить шахту
	CALL	DESTRY
; ---- v0.04: changed/new code or data
	JR	Mim1
DESTRY
	PUSH	HL
	PUSH	DE
	PUSH	BC
	LD	A,#15
	LD	(LED+2),A


	CALL	EVENT
;отменить пометку
	LD	HL,SEL_T
	LD	A,(HL)
	CP	8
	JR	C,pec4
	INC	HL
	LD	A,(HL)
	CP	C
	JR	NZ,pec4
	DEC	HL
	LD	(HL),0
pec4 ;выпустить строителя, если он там
	LD	A,(IX+4)
	CP	253
	JR	C,pec0
	INC	A
	JR	Z,pec0
	LD	A,(IX+7)
	INC	A
	CALL	NZ,outMAN
pec0 ;вызвать облако
	LD	A,29
	CALL	NEWBUL_6
;разрушить зд
	CALL	HL_IX0
; ---- v0.04: code removed (4.Z80: (on индик2))
	LD	(IX+0),0
	CALL	GMAP
	LD	A,(LEV_T)
	OR	A
	LD	C,6
	JR	Z,pecx6
	LD	C,1
	XOR	A
	LD	(pecDD1),A
pecx6	CALL	pecDES
	DEC	HL
	CALL	pecDES
	LD	DE,-64
	ADD	HL,DE
	CALL	pecDES
	INC	HL
	CALL	pecDES
	INC	HL
	CALL	pecDES
	LD	DE,64
	ADD	HL,DE
	CALL	pecDES
	ADD	HL,DE
	CALL	pecDES
	DEC	HL
	CALL	pecDES
	DEC	HL
	CALL	pecDES
	LD	A,#0C ;inc C
	LD	(pecDD1),A
; ---- v0.04: changed/new code or data
	POP	BC
	POP	DE
	POP	HL
	RET
;
pecDES ;уничт кусочек здания с учётом видим
	M1toM2_
	LD	(HL),0
	M2toM1_
	LD	A,(HL)
	AND	#80
	OR	C
	LD	(HL),A
pecDD1	INC	C
	RET

HomBld ;строительство
	LD	A,(IX+7)
	INC	A
	RET	Z ;нет строителя
	DEC	(IX+5)
	RET	NZ
	PUSH	BC
	PUSH	DE
	INC	(IX+4)
	LD	A,(IX+4)
	INC	A
	CALL	Z,outMA_
	LD	A,(IX+2)
	LD	HL,bcTIME
	CALL	BA
	LD	(IX+5),A
	CALL	placeB
	POP	DE
	POP	BC
	JP	EVENT

outMA_	LD	A,(SIDE_N)
	OR	A
; ---- v0.04: changed/new code or data
	JR	NZ,outMAN
	LD	A,#0F
	LD	(LED+1),A ;on индик1
; ---- v0.04: code removed
	LD	A,30
	CALL	SOUNDX ;"стр-во зак"
outMAN	CALL	HL_IX0
	PUSH	IX ;отпусти строителя
	PUSH	BC
	LD	A,(IX+7)
	PUSH	AF
	PUSH	HL
	CALL	N_IX
	POP	HL
	CALL	stayON
	CALL	IX0_HL
	CALL	IX_stop
	PUSH	HL
	XOR	A
	CALL	NEWix_
	POP	HL
	CALL	GMAP2
	POP	AF
	ADD	A,#80
	LD	(HL),A
	POP	BC
	POP	IX
	RET

;0..9 наши
;10..19 враги
;20..25 заклинания
;26..31 апргрейды

HomFct ;пр_во/иссл (для компа - другая П/П)
	LD	A,(TIC)
	RRA
	RET	NC
	DEC	(IX+5)
	RET	NZ
	CALL	EVENT
	LD	A,(IX+4)
	LD	(IX+4),255
	CP	20
	JR	C,HFChum
	SUB	20
	CP	6
	JR	NC,HFCupg
	LD	HL,hMAGIC
	JR	HFCup1
HFCupg	SUB	6
	LD	HL,hPARM
HFCup1	CALL	BA
	INC	(HL)
	LD	A,32
	JP	SOUNDX ;"иссл.вып"

HFChum ;появляется новый член общества A
	OR	A
	JR	Z,hFC0
	ADD	A,2
	CP	13
	JR	C,hFC0
	ADD	A,2
hFC0 ;
	CALL	HL_IX0
	PUSH	IX
	PUSH_
	PUSH	AF
	CALL	stayON
	LD	A,(SIDE_N)
	OR	A
; ---- v0.04 heroSprites4 (16535 bytes at #CD75): probably: page 4: sprite sets of the heroes (fighter, fly_tnk, demon ...) + the GS sound-effect call pSOUND
	JR	NZ,hrm22_1 ;(относительный переход)
	LD	A,#0B
	LD	(LED+4),A ;(было #BF20: адрес в старой раскладке страницы 2)
	LD	A,#1F
	CALL	SOUNDX
hrm22_1	POP	AF
	EX	AF,AF'
	LD	A,(SIDE_N)
	CALL	NEWHER
	POP	BC
	POP	DE
	POP	HL
	POP	IX
	RET
hrm22
	INCBIN	"data/hero/4fighter.dat"	; byte-identical to the archive file
hrm21
	INCBIN	"data/hero/4fly_tnk.dat"	; byte-identical to the archive file
hrm17
	INCBIN	"data/hero/4demon.dat"	; byte-identical to the archive file
	INCBIN	"hum/6_r775_E88F.bin"	; 288 bytes of the v0.04 image (no archive file for them)
pSOUND ;эффект на AY: NOTA - указатель на пары (период, громкость, шум), priv_S - признак "играет"; при isGS<>0 - модуль музыки
	LD	A,(isGS)
	OR	A
	JP	NZ,WMUSIC+6
	LD	A,(priv_S) ;(было #BF37: адрес в старой раскладке страницы 2)
	OR	A
	RET	Z
	LD	A,(WMUSIC+#252) ;копия регистра 7 AY модуля музыки (INAR0 пишет в WMUSIC+#252)
	LD	E,A
	LD	HL,(NOTA) ;(было #BF30)
	LD	A,(HL)
	CP	#FF
	JR	NZ,ppsC
	XOR	A
	LD	(priv_S),A ;(было #BF37)



