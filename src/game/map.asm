; ---- v0.04 (removed) (128 bytes at #C000): code of 4.Z80 that does not exist in v0.04
;этот файл должен быть первым в странице

;------------Работа с картой (c #C100) и миникартой (c #C000)

MiniMAP ;миникарта (256) (**)

MPsign ;номера спрайтов ( зависит от ландшафта ) (128) (**)
	IF	L_land==0	; ASM80: L_land=0 (true when 0 / equal)
	DEFS	128,#99
	ENDIF
	IF	L_land==1	; ASM80: L_land=1 (true when 0 / equal)
	INCBIN "data/4num_m1.bin"
	ENDIF
	IF	L_land==2	; ASM80: L_land=2 (true when 0 / equal)
	INCBIN "data/4num_m2.bin"
	ENDIF
	IF	L_land==3	; ASM80: L_land=3 (true when 0 / equal)
	INCBIN "data/4num_m3.bin"
	ENDIF
	IF	L_land==4	; ASM80: L_land=4 (true when 0 / equal)
	INCBIN "data/4num_m4.bin"
	ENDIF
	IF	L_land==5	; ASM80: L_land=5 (true when 0 / equal)
	INCBIN "data/4num_m5.bin"
	ENDIF

; 00 ... 06 ... 12 ... 18 ... 24 ... 30?.## 36?..# 42 ..# 48 ... 54 .#.
;    .##    .##    .#.	  ...	 .#.	.##    .#.    .##    .#.    #.#
;    .## ani..# ani..#	  ...	 ...	.##    #..    ### ani#.#    .#.
;
; 60 ### 66 .## 72 #.# 78 ###
;    #.#    #.#    ##.	  #..
;    ###    #.#    #.#	  ###

MP_IMG	DEFW	#E0,#80,#80 ;00 люди
	DEFW	#E0,#80,#A0 ;06 кунги
	DEFW	#E0,#C0,#A0 ;12 пленник
	DEFW	#E0,#E0,#E0 ;18 пусто
	DEFW	#E0,#A0,#E0 ;24 дорожки
	DEFW	#00,#00,#E0 ;30 стена
	DEFW	#40,#A0,#40 ;36 циклофреновые россыпи
	DEFW	#C0,#80,#00 ;42 лес
water	DEFW	#E0,#A0,#40 ;48 вода
	DEFW	#A0,#40,#A0 ;54 забор
	DEFW	#00,#40,#00 ;60 рамка
	DEFW	#80,#40,#40 ;66 здания люди
	DEFW	#40,#20,#40 ;72 здания кунги
	DEFW	#00,#60,#00 ;78 строительство
	DEFW	#A0,#A0,#A0 ;84 |
	DEFW	#E0,#80,#A0 ;90 |~
	DEFW	#E0,#00,#E0 ;96  ~
	DEFW	#E0,#00,#C0 ;102 ~|
	DEFW	#C0,#C0,#C0 ;108  |
	DEFW	#C0,#C0,#00 ;114 _|
	DEFW	#E0,#E0,#00 ;120 _
	DEFW	#A0,#A0,#80 ;126|_
MP_LEN	EQU	$-MP_IMG


;----работа с картой----------

MP_ANI	LD	A,(isANI)
	OR	A
	RET	Z
	LD	B,3
	LD	HL,water
mpa0	SLA	(HL)
	JR	NC,mpa1
	SET	5,(HL)
mpa1	INC	HL
	INC	HL
	DJNZ	mpa0
;аним. враг/пленник
	LD	HL,MP_IMG+10
	CALL	MP_an
	LD	HL,MP_IMG+14
	CALL	MP_an
	INC	HL
	INC	HL
MP_an	LD	A,(HL)
	XOR	#60
	LD	(HL),A
	RET

MP_R1	PUSH	HL
	LD	HL,MP_IMG
	LD	B,MP_LEN/2
mp01	SRL	(HL)
	INC	HL
	INC	HL
	DJNZ	mp01
	POP	HL
	RET

MP_R2	PUSH	HL
	LD	HL,MP_IMG
	LD	B,MP_LEN/2
mp02	SRL	(HL)
	INC	HL
	RR	(HL)
	INC	HL
	DJNZ	mp02
	POP	HL
	RET


MP_OU1 ;HL -адр экр
	LD	C,64
mp03	CALL	MP_SPA ;->de адр спр
	JR	Z,mp041
	LD	B,3
mp05	LD	A,(DE)
	XOR	(HL)
	LD	(HL),A
	INC	DE
	INC	DE
	INC	H
	LD	A,H
	AND	7
	JR	NZ,mp04
	LD	A,L
	ADD	A,32
	LD	L,A
	JR	C,mp04
	LD	A,H
	SUB	8
	LD	H,A
mp04	DJNZ	mp05
mp041	DEC	C
	JR	NZ,mp03
	RET

MP_OU2 ;HL -адр экр
	LD	C,64
mp43	CALL	MP_SPA ;->de адр спр
	JR	Z,mp441
	LD	B,3
mp45	LD	A,(DE)
	XOR	(HL)
	LD	(HL),A
	INC	DE
	INC	L
	LD	A,(DE)
	XOR	(HL)
	LD	(HL),A
	DEC	L
	INC	DE
	INC	H
	LD	A,H
	AND	7
	JR	NZ,mp44
	LD	A,L
	ADD	A,32
	LD	L,A
	JR	C,mp44
	LD	A,H
	SUB	8
	LD	H,A
mp44	DJNZ	mp45
mp441	DEC	C
	JR	NZ,mp43
	RET

MP_OU8	PUSH	HL
	PUSH	DE
	LD	B,8
mp11	PUSH	BC
	PUSH	HL
	PUSH	DE
	CALL	MP_SET
MP_sub	CALL	MP_OU1
	POP	DE
	POP	HL
	POP	BC
	INC	L
	INC	L
	INC	L
	LD	A,E
	ADD	A,8
	LD	E,A
	DJNZ	mp11
	POP	DE
	POP	HL
	RET

MP_OUT	CALL	MP_OFF
	CALL	MP_ANI
	CALL	MAAVon
	LD	HL,DSCR
	LD	DE,MAP
	LD	B,6
mp19	PUSH	BC
	CALL	MP_OU8
	INC	L
	INC	E
	INC	E
	INC	E
	POP	BC
	PUSH	BC
	LD	A,B
	CP	1
	PUSH	AF
	CALL	NZ,MP_R1
	POP	AF
	CALL	Z,MP_R2
	POP	BC
	LD	A,B
	CP	4
	JR	Z,mp17
	CP	1
	JR	NZ,mp18
mp17	DEC	L
	DEC	L
	DEC	L
	LD	A,E
	SUB	8
	LD	E,A
mp18	DJNZ	mp19
	LD	BC,MP_OU2
	LD	(MP_sub+1),BC
	CALL	MP_OU8
	CALL	MP_R2
	INC	L
	INC	E
	INC	E
	INC	E
	CALL	MP_OU8
	CALL	MP_R2
	LD	HL,MP_OU1
	LD	(MP_sub+1),HL
MP_Re	LD	HL,MP_IMG+1
	LD	DE,MP_IMG
	LD	BC,MP_LEN-1
	LDIR
	XOR	A
	LD	(DE),A
	JP	MAAVof


MP_SET ;уст.на карту (DE-адрес)
	PUSH	DE
	EXX
	POP	HL
	LD	BC,64
	EXX
	RET


MP_SPA	EXX ;Z-невид; NZ-видим ;->DE adr
	LD	A,(HL)
	RLCA
	JR	C,mpsN
	M1toM2_ ;MAP->MAP2
	LD	A,(HL)
	M2toM1_
	CP	#80
	JR	NC,mpHE
	LD	A,(HL)
	ADD	HL,BC
	EXX
; ---- v0.04: changed/new code or data
	LD	D,#C0
	LD	E,A
	LD	A,(DE)
	ADD	A,#80
	LD	E,A
	RET
mpHE ;герои
	ADD	HL,BC
	CP	#80+_NHER
	JR	NC,mpH1
	EXX
	LD	DE,MP_IMG
	RET
mpH1	CP	#80+_NHER+_NHER
	JR	NC,mpH2
	EXX
	LD	DE,MP_IMG+6
	RET
mpH2	EXX
	LD	DE,MP_IMG+12
	AND	A
	RET
mpsN	ADD	HL,BC ;невидим поле
	EXX
	LD	A,H
	ADD	A,3
	LD	H,A
	AND	7
	CP	3
	JR	NC,mps4
	LD	A,L
	ADD	A,32
	LD	L,A
	JR	C,mps4
	LD	A,H
	SUB	8
	LD	H,A
mps4	XOR	A
	RET


MAAVon ;установить авиацию на карту
	CALL	loopHb
	LD	BC,(_NALL*#100)+#80
mva1	LD	A,(IX+x)
	OR	A
	JR	Z,mva0
	isAVIA_
	JR	Z,mva0
	CP	64
	JR	NC,mva0
	LD	L,A
	LD	A,(IX+y)
	CP	64
	JR	NC,mva0
	LD	H,A
	CALL	GMAP2
	LD	A,(HL)
	LD	(IX+16),A
	LD	(HL),C
mva0	INC	C
	ADD	IX,DE
	DJNZ	mva1
	RET


MAAVof ;удалить авиацию с карты
	LD	IX,((_NALL*_LHER)+HUMAN)-_LHER
	LD	DE,-_LHER
	LD	B,_NALL
mvo1	LD	A,(IX+x)
	OR	A
	JR	Z,mvo0
	isAVIA_
	JR	Z,mvo0
	CALL	HL_IX0
	CALL	GMAP2
	LD	A,(IX+16)
	LD	(HL),A
mvo0	ADD	IX,DE
	DJNZ	mvo1
	RET

;;---------работа с миникартой областей-----

;;--загрузка/выгрузка миникарты
LOADMM	LD	A,(JP_SUB+3)
; ---- v0.04: changed/new code or data
	OR	A
	PUSH	AF
	JR	NZ,.LOADMM_1
	LD	A,#0D
.LOADMM_1
	LD	(DEFENC+99),A
	POP	AF
	CALL	NZ,v4_LOADMM_85+5
	LD	A,#FF
	LD	(pntX+2),A
	LD	A,(kPARM+19)
	LD	(isDIVMAP),A
	LD	HL,isDIVMAP+4
; ---- v0.04: changed/new code or data
	LD	B,#05
.LOADMM_2
	LD	(HL),#00
	INC	HL
	DJNZ	.LOADMM_2
	LD	A,(#0000)
	CP	#04
	JR	NC,.LOADMM_3
	CP	#03
	JR	NC,.LOADMM_4
	CP	#02
	JR	NC,.LOADMM_5
	JR	.LOADMM_6
.LOADMM_3
	LD	(isDIVMAP+7),A
.LOADMM_4
	LD	(isDIVMAP+8),A
.LOADMM_5
	LD	(isDIVMAP+3),A
.LOADMM_6
	LD	(isDIVMAP+4),A
	LD	A,(#0000)
	LD	(isDIVMAP+5),A
	LD	A,(#0000)
	LD	(isDIVMAP+6),A
	LD	HL,(KBUILD)
.LOADMM_7
	LD	A,L
	OR	A
	JR	Z,.LOADMM_8
	LD	(pntX),HL
	RET
.LOADMM_8
	LD	HL,(KUNGE)
	JR	.LOADMM_7
	LD	A,(TIC)
	AND	#07
	CP	#05
	RET	NZ
	LD	HL,isDIVMAP
	LD	A,(HL)
	DEC	(HL)
	OR	A
	RET	NZ
	LD	HL,pntX+2
	LD	A,(HL)
	DEC	(HL)
	OR	A
	JP	Z,.LOADMM_23
	CP	#80
	JP	NC,.LOADMM_35
	LD	A,(isDIVMAP+2)
	OR	A
	JR	NZ,.LOADMM_9
	CALL	.LOADMM_44
.LOADMM_9
	LD	C,A
	LD	A,(MASTER)
	OR	A
	JR	Z,.LOADMM_13
	LD	HL,.LOADMM_22+2
	LD	A,C
	CP	#05
	JR	Z,.LOADMM_10
	CP	#06
	JR	NZ,.LOADMM_14
.LOADMM_10
	PUSH	AF
	CALL	loop_K
.LOADMM_11
	LD	A,(IX+#00)
	OR	A
	JR	Z,.LOADMM_12
	LD	A,(IX+#04)
	CP	C
	JR	NZ,.LOADMM_12
	LD	A,(IX+#0D)
	CP	#0C
	JP	NC,.LOADMM_22
.LOADMM_12
	ADD	IX,DE
	DJNZ	.LOADMM_11
	POP	AF
	JR	.LOADMM_14
.LOADMM_13
	LD	HL,.LOADMM_21+1
	LD	A,C
	ADD	A,#09
	LD	C,A
	CP	#0E
	JR	Z,.LOADMM_10
	CP	#0F
	JR	Z,.LOADMM_10
.LOADMM_14
	LD	(isDIVMAP+9),A
	CALL	BA
	LD	C,A
	LD	B,#28
	LD	IX,KBUILD
	LD	HL,(pntX)
	LD	DE,#FFFF
	EXX
	LD	B,#20
	LD	DE,#0008
.LOADMM_15
	EXX
	LD	A,(IX+#00)
	OR	A
	JR	Z,.LOADMM_16
	LD	A,(IX+#02)
	CP	C
	JR	NZ,.LOADMM_16
	PUSH	BC
	CALL	DIST2
	POP	BC
	CP	E
	JR	NC,.LOADMM_16
	LD	E,A
	LD	D,B
.LOADMM_16
	INC	B
	EXX
	ADD	IX,DE
	DJNZ	.LOADMM_15
	EXX
	LD	A,D
	CP	#FF
	JR	NZ,.LOADMM_18
.LOADMM_17
	LD	A,#02
	LD	(isDIVMAP),A
	RET
.LOADMM_18
	LD	A,D
	CALL	B_IX
	LD	A,(IX+#02)
	LD	HL,hcTIME
	CALL	BA
	SRL	A
	SRL	A
	SRL	A
	LD	(isDIVMAP),A
	CALL	HL_IX0
	CALL	stayON
	LD	A,(isDIVMAP+9)
	PUSH	AF
	EX	AF,af'
	LD	A,#01
	CALL	NEWHER
	JR	NZ,.LOADMM_21
.LOADMM_19
	LD	(IX+#0D),#02
	LD	HL,(pntX)
	CALL	IXt_HL
	IFDEF TRAPS
	CALL	TRA0
	ELSE
	CALL	IX_amov ;(в v0.04: CALL #0000 - символ не определён)
	ENDIF
	POP	AF
	CP	#07
	JR	Z,.LOADMM_20
	CP	#10
	RET	NZ
.LOADMM_20
	LD	(IX+#0D),#03
	IFDEF TRAPS
	JP	TRA1
	ELSE
	JP	IX_amov ;(в v0.04: JP #0000)
	ENDIF
.LOADMM_21
	POP	AF
	RET
.LOADMM_22
	CALL	.LOADMM_17
	JR	.LOADMM_19
	LD	BC,#0301
	LD	B,#01
	LD	BC,#0B0B
	DEC	C
	DJNZ	.LOADMM_24+1
	DEC	BC
.LOADMM_23
	LD	A,(kPARM+20)
	CP	#02
	JR	NZ,.LOADMM_26
	LD	B,#0A
.LOADMM_24
	CALL	RND
	AND	#3F
	CP	#30
	JR	NC,.LOADMM_24
	ADD	A,#30
	CALL	N_IX
	OR	A
	JR	Z,.LOADMM_25
	LD	(IX+#0D),#03
	LD	B,#01
.LOADMM_25
	DJNZ	.LOADMM_24
.LOADMM_26
	CALL	loop_K
.LOADMM_27
	LD	A,(IX+#00)
	OR	A
	JR	Z,.LOADMM_33
	LD	A,(IX+#0D)
	CP	#02
	JR	NZ,.LOADMM_33
	LD	(IX+#0D),#03
	LD	A,(IX+#04)
	CP	#09
	JR	C,.LOADMM_28
	SUB	#09
.LOADMM_28
	CP	#05
	JR	Z,.LOADMM_29
	CP	#06
	JR	NZ,.LOADMM_31
	LD	C,#0F
	JR	.LOADMM_30
.LOADMM_29
	LD	C,#0C
.LOADMM_30
	CALL	.LOADMM_34
	LD	(IX+#0D),C
.LOADMM_31
	LD	A,(IX+#03)
	OR	A
	JR	NZ,.LOADMM_32
	CALL	RND
	AND	#07
	OR	#80
	LD	(IX+#03),A
.LOADMM_32
	IFDEF TRAPS
	CALL	TRA2
	ELSE
	CALL	IXSTRT ;(в v0.04: CALL #0000)
	ENDIF
.LOADMM_33
	ADD	IX,DE
	DJNZ	.LOADMM_27
	CALL	RND
	AND	#1F
	LD	HL,(kPARM+18)
	ADD	A,L
	LD	(isDIVMAP),A
	RET
.LOADMM_34
	LD	A,R
	RRCA
	RET	C
	INC	C
	RRCA
	RET	C
	INC	C
	RET
.LOADMM_35
	LD	B,#10
.LOADMM_36
	CALL	RND
	AND	#1F
	ADD	A,#28
	CALL	B_IX
	LD	A,(IX+#00)
	OR	A
	JR	NZ,.LOADMM_37
	DJNZ	.LOADMM_36
	JR	.LOADMM_38+26
.LOADMM_37
	CALL	HL_IX0
	EX	DE,HL
	LD	B,#10
.LOADMM_38
	LD	C,E
	CALL	RNDshf3
	LD	L,A
	LD	C,D
	CALL	RNDshf3
	LD	H,A
	PUSH	HL
	CALL	GMAP2
	LD	A,(HL)
	POP	HL
	OR	A
	JR	Z,.LOADMM_38+23
	DJNZ	.LOADMM_38
	JR	.LOADMM_38+26
; ---- v0.04 mapSpecials (353 bytes at #C4CC): probably: LOADMM part: random set-up of isDIVMAP/pntX (the "diversion" points of the level)
	LD	(pntX),HL
	LD	A,(kPARM+17)
	CP	#02
	JR	C,.LOADMM_41
	DEC	A
	LD	B,A
	LD	C,#01
.LOADMM_39
	CALL	RND
	RLCA
	JR	C,.LOADMM_40
	INC	C
.LOADMM_40
	DJNZ	.LOADMM_39
	LD	A,C
.LOADMM_41
	LD	(pntX+2),A
	CALL	RND
	CP	#C9
	LD	A,#00
	JR	C,.LOADMM_43
.LOADMM_42
	CALL	.LOADMM_44
	CP	#05
	JR	Z,.LOADMM_42
	CP	#06
	JR	Z,.LOADMM_42
.LOADMM_43
	LD	(isDIVMAP+2),A
	LD	A,#01
	LD	(isDIVMAP),A
	LD	A,R
	AND	#14
	RET	NZ
	JR	Z,.LOADMM_47
.LOADMM_44
	CALL	.LOADMM_45
	LD	A,C
	LD	HL,isDIVMAP
	CALL	BA
	OR	A
	JR	Z,.LOADMM_44
	LD	A,C
	RET
.LOADMM_45
	CALL	RND
	LD	C,#03
	SUB	#46
	RET	C
	INC	C
	SUB	#32
	RET	C
	INC	C
	SUB	#14
	RET	C
	INC	C
	SUB	#19
	RET	C
	INC	C
	SUB	#0A
	RET	C
	INC	C
	RET
	LD	A,(isDIVMAP+1)
	CP	#FF
	JR	Z,.LOADMM_47
	CP	#80
	JR	NC,.LOADMM_46
	CALL	N_IX
	OR	A
	JR	Z,.LOADMM_47
	LD	A,(IX+#01)
	CP	#80
	JR	NC,.LOADMM_47
	RET
.LOADMM_46
	AND	#7F
	CALL	B_IX
	LD	A,(IX+#00)
	OR	A
	RET	NZ
.LOADMM_47
	LD	B,#10
.LOADMM_48
	CALL	RND
	AND	#1F
	ADD	A,#08
	LD	C,A
	CALL	B_IX
	LD	A,(IX+#00)
	OR	A
	JR	NZ,.LOADMM_50
	DJNZ	.LOADMM_48
	LD	B,#18
.LOADMM_49
	CALL	RND
	AND	#3F
	CP	#30
	JR	NC,.LOADMM_49
	LD	C,A
	CALL	N_IX
	OR	A
	JR	NZ,.LOADMM_51
	DJNZ	.LOADMM_49
	LD	C,#FF
	JR	.LOADMM_51
.LOADMM_50
	SET	7,C
.LOADMM_51
	LD	A,C
	LD	(isDIVMAP+1),A
	RET
MAPLAND	EQU	$ ;probably: номер ландшафта из клетки MAP[0] (клетка обнуляется) -> fsLAND, LEV_T (запись списка _start)
	LD	HL,MAP
	LD	A,(HL)
	LD	(HL),#00
	INC	A
	LD	(fsLAND),A
	LD	C,#46
.LOADMM_52
	DEC	A
	JR	Z,.LOADMM_53
	RR	C
	JR	.LOADMM_52
.LOADMM_53
	LD	A,C
	AND	#01
	LD	(LEV_T),A
	RET
; FOGALL (probably): закрыть туманом всю карту - SET 7 у клеток 62x62 (бит 7 клетки карты = туман, юниты открывают его вокруг себя: onsee).
; В v0.04 кунгов вызывается отдельной записью списка _start (CALL_ #C5A4 между setBLT и расстановкой героев), в v0.04 людей - нет
; (в образе людей флагов тумана нет, в образе кунгов 2324 клетки). Здесь вызывается из KUNFOG (lib1a.asm) только при MASTER=1.
FOGALL	EQU	$
	LD	HL,MAP+65
	LD	C,#3E
.LOADMM_54
	LD	B,#3E
.LOADMM_55
	SET	7,(HL)
	INC	HL
	DJNZ	.LOADMM_55
	INC	HL
	INC	HL
	DEC	C
	JR	NZ,.LOADMM_54
	RET
AIGROW	EQU	$ ;probably: раз в #61 тиков наращивает уровень развития компьютера (_Y0pos+2, LEVEL)
	LD	A,(TIC)
	CP	#61
	RET	NZ
	LD	HL,_Y0pos+2
	INC	(HL)
	LD	A,(LEVEL)
	ADD	A,(HL)
	CP	#35
	JR	C,.LOADMM_56
	LD	(HL),#00
	CALL	v4_LOADMM_83
.LOADMM_56
	LD	HL,RESULT+5
	CALL	.LOADMM_57
	LD	HL,LEVRES+5
.LOADMM_57
	INC	(HL)
	LD	A,(HL)
	CP	#0A
	RET	C
	LD	(HL),#00
	DEC	HL
	INC	(HL)
	LD	A,(HL)
	CP	#06
	RET	C
	LD	(HL),#00
	DEC	HL
	DEC	HL
	INC	(HL)
	LD	A,(HL)
	CP	#0A
	RET	C
	LD	(HL),#00
	DEC	HL
	INC	(HL)
	LD	A,(HL)
	CP	#0A
	RET	C
	LD	(HL),#00
	DEC	HL
	INC	(HL)
	RET
RNDMIX	EQU	$ ;случайность: RNB ^= R (запись списка _start)
	LD	A,R
	LD	HL,RNB
	XOR	(HL)
	LD	(HL),A
	RET
AIHEAL	EQU	$ ;probably: каждый тик&#3F<#30: восстановление/развитие юнитов компьютера по таблице HEALTH
	LD	A,(TIC)
	AND	#3F
	CP	#30
	RET	NC
	PUSH	AF
	LD	DE,hPARM+4
	CALL	.LOADMM_58
	POP	AF
	ADD	A,#30
	LD	DE,kPARM+4
.LOADMM_58
	CALL	N_IX
	LD	A,(IX+#00)
	OR	A
	RET	Z
	LD	A,(IX+#04)
	LD	C,A
	LD	HL,HEALTH+1
	CALL	WA
	OR	A
	JR	Z,.LOADMM_61
	LD	A,(IX+#06)
	CP	#F0
	JR	NC,.LOADMM_61
	ADD	A,#0C
	JR	C,.LOADMM_59
	CP	#F0
	JR	C,.LOADMM_60
.LOADMM_59
	LD	A,#F0
.LOADMM_60
	LD	(IX+#06),A
.LOADMM_61
	LD	A,C
	SUB	#0C
	CP	#09
	RET	NC
	DEC	HL
	LD	A,(DE)
	ADD	A,#02
	ADD	A,(IX+#05)
	CP	(HL)
	JR	C,.LOADMM_62
	LD	A,(HL)
.LOADMM_62
	LD	(IX+#05),A
	RET
AIREPR	EQU	$ ;probably: компьютер: юниты рядом с точкой (расстояние <4) подлечиваются по таблице HEALTH
	LD	A,(TIC)
	AND	#3F
	LD	C,A
	CALL	B_IX
	LD	A,(IX+#00)
	OR	A
	RET	Z
	LD	A,(IX+#02)
	CP	#03
	JR	Z,.LOADMM_63
	CP	#0B
	RET	NZ
.LOADMM_63
	CALL	HL_IX0
	LD	A,C
	DEFB	#DD,#21,#84,#76
	CP	#20
	JR	C,.LOADMM_64
	LD	IX,KUNGE
.LOADMM_64
	LD	DE,#0018
	LD	B,#30
.LOADMM_65
	LD	A,(IX+#00)
	OR	A
	JR	Z,.LOADMM_69
	BIT	7,(IX+#02)
	JR	Z,.LOADMM_69
	PUSH	BC
	CALL	DIST2
	CP	#04
	JR	NC,.LOADMM_68
	PUSH	HL
	LD	A,(IX+#04)
	LD	HL,HEALTH
	CALL	WA
	LD	A,(IX+#05)
	CP	(HL)
	JR	NC,.LOADMM_67
	ADD	A,#0C
	CP	(HL)
	JR	C,.LOADMM_66
	LD	A,(HL)
.LOADMM_66
	LD	(IX+#05),A
.LOADMM_67
	POP	HL
.LOADMM_68
	POP	BC
.LOADMM_69
	ADD	IX,DE
	DJNZ	.LOADMM_65
	RET
AICOUNT	EQU	$ ;probably: подсчёт пеонов/роботов компьютера в peon_W
	CALL	.LOADMM_70
	LD	(peon_W),HL
	RET
.LOADMM_70
	LD	HL,#0000
	CALL	loop_K
.LOADMM_71
	LD	A,(IX+#00)
	OR	A
	JR	Z,.LOADMM_73
	LD	A,(IX+#0D)
	CP	#07
	JR	Z,.LOADMM_72
	CP	#06
	JR	NZ,.LOADMM_73
	INC	L
	JR	.LOADMM_73
.LOADMM_72
	INC	H
.LOADMM_73
	ADD	IX,DE
	DJNZ	.LOADMM_71
	RET
AIPEON	EQU	$ ;probably: каждый #35-й тик: если пеонов меньше, чем роботов (или наоборот), произвести нового (NEWHER)
	LD	A,(TIC)
	AND	#3F
	CP	#35
	RET	NZ
	CALL	AICOUNT.LOADMM_70
	LD	DE,(peon_W)
	LD	A,L
	CP	E
	JR	C,.LOADMM_74
	LD	A,H
	CP	D
	RET	NC
	LD	C,#07
	JR	.LOADMM_75
.LOADMM_74
	LD	C,#06
.LOADMM_75
	PUSH	BC
	LD	B,#10
.LOADMM_76
	CALL	RND
	AND	#1F
	ADD	A,#28
	CALL	B_IX
	LD	A,(IX+#00)
	OR	A
	JR	Z,.LOADMM_77
	LD	A,(IX+#02)
	OR	A
	JR	Z,.LOADMM_78
	CP	#08
	JR	Z,.LOADMM_78
.LOADMM_77
	DJNZ	.LOADMM_76
	POP	BC
	RET
.LOADMM_78
	CALL	HL_IX0
	CALL	stayON
	LD	A,(MASTER)
	OR	A
	LD	A,#0C
	JR	Z,.LOADMM_79
	XOR	A
.LOADMM_79
	EX	AF,af'
	LD	A,#01
	CALL	NEWHER
	POP	BC
	RET	NZ
	LD	(IX+#0D),C
	LD	A,(isDIVMAP)
	ADD	A,#14
	LD	(isDIVMAP),A
	RET
TICADV	EQU	$ ;счётчики TIC6, +1, +2 (по модулю 6 и 3)
	LD	HL,TIC6
	INC	(HL)
	LD	A,(HL)
	CP	#06
	JR	C,.LOADMM_80
	LD	(HL),#00
.LOADMM_80
	INC	HL
	INC	(HL)
	LD	A,(HL)
	CP	#03
	JR	C,.LOADMM_81
	LD	(HL),#00
.LOADMM_81
	INC	HL
	INC	(HL)
	RET
AISEL	EQU	$ ;probably: компьютер: выбор действия по TIC&7 (таблица переходов)
	LD	A,(TIC)
	AND	#07
	LD	C,A
	LD	HL,kPARM
	CALL	BA
	EX	DE,HL
	LD	A,C
	LD	HL,hPARM
	CALL	BA
	LD	A,(MASTER)
	OR	A
	JR	Z,.LOADMM_82
	EX	DE,HL
.LOADMM_82
	LD	A,C
	EXX
	LD	HL,.LOADMM_82+9
	CALL	WT
	JP	(HL)
	SBC	A,E
	RST	#00
	DEFB	#E2,#C7,#FA	; data (not code): JP PO,#FAC7
	RST	#00
	ADD	A,A
	RST	#00
	OR	C
	RST	#00
	CP	L
	RST	#00
	RET	NC
	RST	#00
	SBC	A,D
	RST	#00
	EXX
	LD	A,(HL)
	INC	A
	LD	(HvTDs+9),A
	INC	A
	LD	(DfSTACK+33),A
	LD	A,(DE)
	INC	A
	INC	A
	LD	(HvTDs+16),A
	LD	(DfSTACK+40),A
	RET
	EXX
	LD	A,(HL)
	LD	(DEFENC+3),A
	LD	(DEFENC+4),A
	LD	A,(DE)
	LD	(DEFENC+15),A
	LD	(DEFENC+16),A
	LD	(DEFENC+17),A
	LD	(DEFENC+18),A
	RET
	EXX
	LD	A,(HL)
	LD	(DEFENC+5),A
	LD	(DEFENC+6),A
	LD	(DEFENC+9),A
	RET
	EXX
	LD	A,(HL)
	LD	(DEFENC+10),A
	LD	(DEFENC+11),A
	LD	A,(DE)
	LD	(DEFENC+21),A
	LD	(DEFENC+22),A
	LD	(DEFENC+23),A
	RET
	EXX
	LD	A,#02
	SUB	(HL)
	LD	(BFORCE+17),A
	EX	DE,HL
	LD	A,#02
	SUB	(HL)
	LD	(BFORCE+23),A
	LD	(BFORCE+25),A
	RET
	EXX
	LD	A,#02
	SUB	(HL)
	LD	(BFORCE+3),A
	LD	(BFORCE+7),A
	LD	(BFORCE+9),A
	EX	DE,HL
	LD	A,#02
	SUB	(HL)
	LD	(BFORCE+19),A
	LD	(BFORCE+21),A
	RET
	EXX
	LD	A,#02
	SUB	(HL)
	LD	(BFORCE+5),A
	LD	(BFORCE+15),A
	EX	DE,HL
	LD	A,#02
	SUB	(HL)
	LD	(FORCE+1),A
	LD	(FORCE+5),A
	RET
	INC	BC
	LD	(BC),A
	LD	(BC),A
	LD	(BC),A
	INC	BC
	INC	BC
	LD	(BC),A
	INC	BC
v4_LOADMM_83
	LD	DE,kPARM
	LD	HL,scx3
	LD	B,#08
v4_LOADMM_84
	LD	A,(DE)
	INC	A
	CP	(HL)
	JR	C,v4_LOADMM_85
	LD	A,(HL)
v4_LOADMM_85
	LD	(DE),A
	INC	HL
	INC	DE
	DJNZ	v4_LOADMM_84
	LD	HL,kPARM+17
	INC	(HL)
	LD	HL,kPARM+19
	CALL	.LOADMM_86
	LD	HL,kPARM+18
.LOADMM_86
	SRL	(HL)
	LD	A,(HL)
	SRL	(HL)
	ADD	A,(HL)
	LD	(HL),A
	RET
MAPCUR	EQU	$ ;probably: страница 6: положение/рамка курсора окна карты (вызов из O12X12)
	LD	A,(begBOX)
	OR	A
	RET	Z
	LD	HL,(COORD)
	LD	A,L
	CP	#BE
	JR	C,.LOADMM_87
	LD	L,#BE
.LOADMM_87
	LD	DE,(BOXX)
	XOR	A
	PUSH	HL
	SBC	HL,DE
	POP	HL
	RET	Z
	CALL	STD
	PUSH	DE
	LD	E,L
	CALL	.LOADMM_98
	POP	DE
	PUSH	DE
	LD	D,H
	CALL	.LOADMM_88
	POP	DE
	CALL	.LOADMM_98
	CALL	.LOADMM_88
	LD	HL,LMask
	RRC	(HL)
	RET
.LOADMM_88
	LD	A,(LMask)
	LD	(LMask+1),A
	LD	A,L
	CP	E
	RET	Z
	PUSH	HL
	PUSH	DE
	JR	NC,.LOADMM_89
	LD	L,E
	LD	E,A
.LOADMM_89
	PUSH	HL
	PUSH	DE
	LD	A,E
	AND	#F8
	LD	E,A
	LD	A,L
	AND	#F8
	SUB	E
	CP	#08
	JR	C,.LOADMM_94
	JR	NZ,.LOADMM_90
	LD	B,#00
	JR	.LOADMM_91
.LOADMM_90
	RRCA
	RRCA
	RRCA
	LD	B,A
	DEC	B
.LOADMM_91
	POP	DE
	PUSH	DE
	CALL	PCOORD
	POP	DE
	LD	A,E
	AND	#07
	LD	DE,MLtab1
	ADD	A,E
	LD	E,A
	LD	A,(DE)
	CALL	.LOADMM_96
	LD	A,B
	OR	A
	JR	Z,.LOADMM_93
.LOADMM_92
	LD	A,#FF
	CALL	.LOADMM_96
	DJNZ	.LOADMM_92
.LOADMM_93
	POP	DE
	LD	A,E
	AND	#07
	LD	DE,MLtab2
	ADD	A,E
	LD	E,A
	LD	A,(DE)
	JR	.LOADMM_95
.LOADMM_94
	POP	DE
	PUSH	DE
	CALL	PCOORD
	POP	DE
	LD	A,E
	AND	#07
	LD	DE,MLtab1
	ADD	A,E
	LD	E,A
	LD	A,(DE)
	LD	C,A
	POP	DE
	LD	A,E
	AND	#07
	LD	DE,MLtab2
	ADD	A,E
	LD	E,A
	LD	A,(DE)
	AND	C
.LOADMM_95
	CALL	.LOADMM_96
	POP	DE
	POP	HL
	RET
.LOADMM_96
	LD	C,A
	OR	(HL)
	LD	(HL),A
	LD	A,(LMask+1)
	AND	C
	XOR	(HL)
	LD	(HL),A
	INC	L
	RET
.LOADMM_97
	LD	A,C
	OR	(HL)
	LD	(HL),A
	LD	A,(LMask+1)
	RLCA
	LD	(LMask+1),A
	AND	C
	XOR	(HL)
	LD	(HL),A
	INC	H
	LD	A,H
	AND	#07
	RET	NZ
	LD	A,L
	ADD	A,#20
	LD	L,A
	RET	C
	LD	A,H
	SUB	#08
	LD	H,A
	RET
.LOADMM_98
	LD	A,(LMask)
	LD	(LMask+1),A
	LD	A,D
	CP	H
	RET	Z
	PUSH	HL
	PUSH	DE
	JR	C,.LOADMM_99
	LD	D,H
	LD	H,A
.LOADMM_99
	PUSH	DE
	LD	A,H
	SUB	D
	LD	B,A
	POP	DE
	PUSH	DE
	CALL	PCOORD
	POP	DE
	LD	A,E
	AND	#07
	LD	DE,MLtabV
	ADD	A,E
	LD	E,A
	LD	A,(DE)
	LD	C,A
.LOADMM_100
	CALL	.LOADMM_97
	DJNZ	.LOADMM_100
	POP	DE
	POP	HL
	RET
AIDEFEND	EQU	$ ;probably: каждый #7F+ тик: защита базы - ближайшие юниты получают приказ атаковать
	LD	A,(TIC)
	CP	#7F
	RET	C
	AND	#1F
	ADD	A,#28
	CALL	B_IX
	LD	A,(IX+#00)
	OR	A
	RET	Z
	LD	A,(IX+#02)
	LD	HL,bHEALT
	CALL	BA
	LD	A,(IX+#03)
	CP	(HL)
	RET	NC
	CALL	HL_IX0
	CALL	loop_K
.LOADMM_101
	LD	A,(IX+#00)
	OR	A
	JR	Z,.LOADMM_103
	LD	A,(IX+#04)
	OR	A
	JR	Z,.LOADMM_102
	CP	#09
	JR	NZ,.LOADMM_103
.LOADMM_102
	LD	A,(IX+#09)
	CP	#08
	JR	NC,.LOADMM_103
	LD	(IX+#08),#80
	LD	(IX+#09),#08
	JP	IXt_HL
.LOADMM_103
	ADD	IX,DE
	DJNZ	.LOADMM_101
	RET
; LVSTART (probably): расстановка героев уровня по datHER (EXCHMM, затем разбор datMIN+16...); запись списка _start "CALL_ #C984"
LVSTART	EQU	$
	CALL	EXCHMM
	CALL	esmm_+11
	LD	HL,datMIN+16
.LOADMM_104
	LD	A,(HL)
	CP	#FF
	JR	Z,esmm_+11
	PUSH	HL
	CP	#04
	JR	C,.LOADMM_105
	INC	HL
	LD	A,(HL)
	INC	HL
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	CALL	.LOADMM_108
	JR	.LOADMM_107
.LOADMM_105
	CP	#02
	JR	NC,.LOADMM_106
	LD	A,(MASTER)
	XOR	(HL)
.LOADMM_106
	PUSH	AF
	EX	AF,af'
	INC	HL
	LD	A,(HL)
	EX	AF,af'
	INC	HL
	LD	E,(HL)
	INC	HL
	LD	H,(HL)
	LD	L,E
	CALL	NEWHER
	POP	AF
	OR	A
	CALL	Z,ONSEE1
.LOADMM_107
	POP	HL
	LD	DE,#0004
	ADD	HL,DE
	JR	.LOADMM_104
	LD	(#2423),HL
	DEC	H
	DAA
	JR	Z,esmm_+30
.LOADMM_108
	LD	HL,go_cc1
	CALL	BA
	JP	NEWBUL

EXCHMM	LD	HL,WBAR
esmm_	DEFB	#11,#81,#76
; ---- v0.04: changed/new code or data (4.Z80: esmm0)
	LD	BC,#0977
	LD	(HL),#00
	LDIR
	RET
	LD	B,#90
	LD	HL,KBUILD+256
	LD	A,(HL)
	XOR	#0F
esmm0	; (в v0.04 код удалён, метка сохранена для ссылок)
	LD	(HL),A
; ---- v0.04: code removed
	INC	HL
; ---- v0.04: changed/new code or data
	DJNZ	esmm_+16
	RET
; ---- v0.04: code removed (4.Z80: gtnp2 gtnp1)

;----------определние номера части карты
;вх: %00YYYYY* 00XXXNN*
;вых: %11111111 YYYYYXXX ->пара бит NN
;
gtnp2	; (в v0.04 код удалён, метка сохранена для ссылок)
gtnp1	; (в v0.04 код удалён, метка сохранена для ссылок)




cmpPARTde ;сравнение частей [HL] и [DE]
	CALL	GPART
; ---- v0.04 esmmEnemy (60 bytes at #C9F1): probably: esmm_: the enemy units are set up at the start (IX+13/IX+4 state per type)
	LD	A,(IX+#00)
	OR	A
	JR	Z,cmppr_
	LD	(IX+#0D),#01
	LD	A,(IX+#04)
	CP	#09
	JR	C,.esmm__1
	SUB	#09
.esmm__1
	CP	#03
	JR	NC,.esmm__3+5
	CP	#01
	LD	(IX+#0D),#08
	JR	C,cmppr_
	JR	Z,.esmm__2
	DEC	(IX+#0D)
	DEC	(IX+#04)
	JR	.esmm__3
.esmm__2
	LD	(IX+#0D),#06
.esmm__3
	DEC	(IX+#04)
	JR	cmppr_
; ---- v0.04: changed/new code or data
	CP	#05
	JR	NZ,.esmm__3+15
	LD	(IX+#0D),#0A

cmpPARTt ;сравнение частей [HL] и IX[x_tar,y_tar]
	JR	cmppr_
; ---- v0.04: changed/new code or data (4.Z80: cmppr_)
	CP	#06
	JR	NZ,cmppr_
	LD	(IX+#0D),#0B
cmppr_
	ADD	IX,DE
	DJNZ	esmm_+27

cmpPART ;сравнение частей [HL] и IX[x,y]
	RET ;z/nz-на одной/на разных частях



