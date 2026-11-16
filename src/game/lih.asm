;------главный цикл обработки персонажей

MOVZZ ;п/п обр действий ix+9 в чв-1
	DEFW	ZZ0,ZZ1,ZZ2,ZZ3,ZZ4,ZZ5,ZZ6,ZZ7,ZZ8,ZZ9
	DEFW	ZZ10,ZZ11,ZZ12,ZZ13,ZZ14,ZZ15
	DEFW	ZZ16,ZZ17,ZZ18,ZZ19,ZZ20,ZZ21
	DEFW	ZZ22,ZZ23,ZZ24,ZZ25,ZZ26,ZZ27
	DEFW	ZZ28
;добавлено для чв-2
	DEFW	ZZ29,ZZ30
	DEFW	ZZ31,ZZ32,ZZ33,ZZ34,ZZ35,ZZ36
	DEFW	ZZ37,ZZ38

impANS ;ответ на удар (0/х-нет/функция) при действии N
;для врага - все не 0 ->28
	DEFB	04,26,00,04,00,04,04,04,04,04
	DEFB	00,00,00,00,00,00
	DEFB	00,00,00,00,00,00
	DEFB	00,00,00,04,00,00
	DEFB	04
;добавлено
	DEFB	04,00
	DEFB	00,00,00,00,00,00
; ---- v0.04: changed/new code or data (4.Z80: SHED_H)
	INC	B
	NOP
	DEFB	#DD,#21,#84,#76
	XOR	A
	LD	(HER_N),A


SHED_H	; (в v0.04 код удалён, метка сохранена для ссылок)
	LD	(SIDE_N),A
;init
	LD	A,#C9 ;ret
	LD	(ZZ00),A ;intel=off
;
She0	LD	A,(IX+y)
	OR	A
	JR	Z,She1
	LD	A,(IX+x)
	OR	A
	CALL	Z,SheTro
	CALL	NZ,MOVING
She1	LD	BC,_LHER
	ADD	IX,BC
	LD	HL,HER_N
	INC	(HL)
	LD	A,(HL)
	CP	_NHER
	JP	C,She0
	RET

SHED_K ;К*У*Н*Г*И
	LD	HL,SIDE_N
	INC	(HL)
;init
	LD	A,#C3 ;jp: intel=ON
	LD	(ZZ00),A
;
Ske0	LD	A,(IX+y)
	OR	A
	JR	Z,Ske1
	LD	A,(IX+x)
	OR	A
	CALL	Z,SheTro
	CALL	NZ,MOVING
Ske1	LD	BC,_LHER
	ADD	IX,BC
	LD	HL,HER_N
	INC	(HL)
	LD	A,(HL)
	CP	_NHER+_NHER
	JP	C,Ske0
	RET

NxtTro ;след  фаза трупа
	DEFB	#FF,0,1,2,#FF,4,5,6,#FF,8,8,8,8,#FF,#FF,#FF,#FF
SheTro ;гниение трупов
	DEC	(IX+3)
	JR	NZ,ShtRt
	LD	HL,NxtTro
	CALL	gPAR
	CP	#FF
	JR	NZ,SheT1
	LD	(IX+y),0
	JR	ShtRt
SheT1	CALL	NZ,TrooTi
ShtRt	XOR	A
	RET


;------------обработка пленников
SHED_p ;П*Л*Е*Н*Н*И*К*И
	LD	A,#C9 ;ret - intel off
	LD	(ZZ00),A
;
	LD	A,(TIC)
	DEC	A
	AND	%11
	RET	NZ ;раз в 4 такта
Spe0	LD	A,(IX+y)
	OR	A
	JR	Z,Spe1
	LD	A,(IX+x)
	OR	A
	CALL	Z,SheTro
	CALL	NZ,PRISON
Spe1	LD	BC,_LHER
	ADD	IX,BC
	LD	HL,HER_N
	INC	(HL)
	LD	A,(HL)
	CP	_NALL
	JP	C,Spe0
	RET

isFRND ;по адр HL в GMAP2 - свой? (вых через POP)
	LD	A,(HL)
	INC	L
	CP	#80
	RET	C
	CP	#80+_NHER
	RET	NC
	POP	AF ;!!
	LD	C,(IX+health)
	LD	B,(IX+dir)
	PUSH	IX
	PUSH	BC
	LD	A,(HER_N)
	CALL	deSEL
	LD	A,(IX+4)
	EX	AF,AF'
	CALL	HL_IX0
	CALL	IXt_HL
	XOR	A
	CALL	NEWHER
	POP	BC
	JR	NZ,iFRn ;mem?
	LD	(IX+health),C
	LD	(IX+dir),B
iFRn	POP	IX
	RET	NZ ;нет памяти
;звёзды-пленник свободен
	CALL	STARher
	LD	HL,0
	CALL	IX0_HL
	LD	(IX+dir),L
	JP	EVENT

PRISON	LD	L,A
	LD	H,(IX+y)
	LD	A,(IX+health)
	OR	A
	JR	Z,Kill ;убитый
	DEC	L
	DEC	H
	CALL	GMAP2
	CALL	isFRND
	CALL	isFRND
	CALL	isFRND
	LD	DE,61
	ADD	HL,DE
	CALL	isFRND
	INC	L
	CALL	isFRND
	ADD	HL,DE
	CALL	isFRND
	CALL	isFRND
	CALL	isFRND ;!!
	RET

;---------------------------
TrooAv ;гибель авиации
	LD	A,23
	CALL	NEWBUL
;кто в транспорте - умер
	LD	A,(IX+4)
	CP	11
	JR	Z,TrA2
	CP	23
	JR	NZ,TrA1
TrA2	LD	A,(HER_N)
	LD	C,A
	PUSH	IX
	CALL	loop_H
	LD	B,_NALL
TrA2a	LD	A,(IX+x)
	OR	A
	JR	Z,TrA2b
	LD	A,(IX+com)
	CP	30
	JR	NZ,TrA2b
	LD	A,(IX+tarN)
	CP	C
	JR	NZ,TrA2b
	LD	HL,0
	CALL	IX0_HL
TrA2b	ADD	IX,DE
	DJNZ	TrA2a
	POP	IX
TrA1 ;без трупа
	LD	HL,0
	JP	IX0_HL


KilNxt	DEFB	15,15,15,3,3,14,13,3,3,16,-1,-1
	DEFB	12,12,12,7,10,9,11,7,7,-1,-1,-1
Kill ;убить героя по состоянию здоровья
	LD	A,(IX+speed) ;проверить магию 'хруст. шара'
	AND	%11110000
	CP	%01000000
	JR	NZ,Ki3
	LD	(IX+health),5
; ---- v0.04: changed/new code or data (4.Z80: (запомнить погибшего охранника))
	JR	noKill
;/LD A,(SIDE_N)
;/OR A
;/CALL NZ,actRUN
Ki3
	LD	A,(HER_N)
	CALL	deSEL ;отменить пометку
	CALL	EVENT ;событие
	isAVIA_
	LD	(IX+dir),0
; ---- v0.04: changed/new code or data
	JR	NZ,TrooAv
	CALL	HL_IX0
	RES	7,H ;если смерть наступила в здании
	CALL	IXt_HL
	CALL	GMAP2
	XOR	A
	LD	(HL),A
	LD	(IX+x),A
;
	LD	A,(IX+typ)
	LD	(IX+com),A ;кем был при жизни
	LD	C,A ;кричит, умирая?
	LD	HL,AT_TY2
	CALL	BA
	AND	cry
	JR	Z,Ki1
	LD	A,C ;кунг/чел
	CP	12
	LD	A,20
	JR	C,Ki0
	INC	A
Ki0	CALL	SOUNDXn
Ki1	LD	A,C
	LD	HL,KilNxt ;нач ф гниения
	CALL	BA
; ---- v0.04: code removed (4.Z80: KivN)
;
;зенитка - взрываются
KivN	; (в v0.04 код удалён, метка сохранена для ссылок)
;
TrooTi ;время гниения фазы A
	LD	(IX+4),A
	LD	HL,TimTro
	CALL	BA
	LD	(IX+3),A
	RET


TimTro ;время гниения фазы
	DEFB	40,50,50,60,40,50,50,60,80,99,99,99,99,99,99,80,99


;------------------------------
MOVING ;обр.команд живых людей
	LD	A,(IX+health)
	OR	A
; ---- v0.04: changed/new code or data (4.Z80: (убитый))
	JR	Z,Kill
noKill	isAVIA_
	JP	NZ,IXA3_0 ;для авиа
	LD	A,(IX+typ)
	CP	9
	CALL	Z,twnTNK ;башня танка
	LD	A,(IX+phase_)
	OR	A
	JR	Z,IX3_0
	CALL	HERMOV
	LD	A,(IX+phase_)
	OR	A
	RET	NZ
IX3_0	LD	A,(IX+com) ;для сухопутных
	LD	HL,MOVZZ
	CALL	WT
	JP	(HL)

;---верни башню прямо

twnTNK	LD	A,(HER_N)
	LD	C,A
	LD	A,(TIC)
	ADD	A,C
	ADD	A,C
	AND	%110000
	RET	NZ
	LD	A,(IX+phase_)
	RLCA
	RET	C
	LD	A,(IX+6)
	OR	A
	RET	Z
	CP	8
	JR	C,twt1
	LD	A,(IX+6)
	INC	A
	AND	#F
	LD	(IX+6),A
	RET
twt1	DEC	(IX+6)
	RET


;-----скука/повороты----
SPLIN	CALL	RND
	AND	63
	CP	_NHER
	RET	NC
	LD	B,A
	CALL	N_IX
	OR	A
	RET	Z
	LD	A,(IX+move)
	INC	A
	RET	NZ ;не #FF
	LD	A,(TIC)
	AND	7
	LD	A,(IX+4)
	LD	HL,AT_TY2
	JR	Z,SPLINm
	CALL	BA
	LD	C,A
	AND	sleep
	RET	Z
	isAVIA_
	JR	NZ,splA1
	LD	A,B
	RRCA
	LD	A,(IX+dir)
	JR	C,spli2
	INC	A
	JR	spli3
spli2	DEC	A
spli3	AND	7
spli5	LD	(IX+dir),A
	RET
;
splA1	LD	A,B
	RRCA
	JR	C,splA4
	INC	(IX+dir)
	RET	NZ
	LD	(IX+dir),-16
	RET
splA4	LD	A,(IX+dir)
	DEC	A
	CP	-16
	JR	NC,spli5
	LD	A,-1
	JR	spli5

SPLINm ;отойти вернуться
	CALL	BA
	AND	f9
	RET	Z
; ---- v0.04: code removed (4.Z80: (ходить, если com=0))
	CALL	HL_IX0
	isAVIA_
	JR	NZ,splmA
	LD	A,(IX+dir)
splm2	CALL	GO_NXT
	RET	NC
splm3	CALL	IXw_HL
	EX	DE,HL
	CALL	IXt_HL
	LD	(IX+move),#80
	LD	(IX+com),9
	RET
; ---- v0.04: code removed (4.Z80: splmA)
;
splmA
	CALL	RND
	AND	7
	CALL	GO_NXT
	RET	NC
; ---- v0.04: changed/new code or data
	CALL	splm3
	JP	Aspeed0


;-----параметры удара/защиты--

gB_FRC ;получить силу снаряда (для ЧВ2)
	LD	HL,BFORCE+1
	LD	A,(IY+#0)
gff ;посчитать силу с учётом попадания
	CALL	WA
; ---- v0.04: changed/new code or data
	LD	A,R
	AND	%11
	CP	(HL)
	DEC	HL
	LD	A,(HL)
	RET	NC
	SRL	A
	SRL	A
	RET

gFORCE ;получить знач силы удара (для ЧВ2)
	LD	HL,FORCE+1
	LD	A,(IX+4)
	CP	16
	LD	A,1 ;кракот16->[1]
; ---- v0.04: changed/new code or data
	JR	Z,gff
	LD	A,2 ;демон17->[2]
; ---- v0.04: changed/new code or data
	JR	NC,gff
	XOR	A ;пеон12->[0]
; ---- v0.04: changed/new code or data
	JR	gff


gDEFEN ;получить знач защиты  (Вх/вых: C-удар)
	LD	HL,DEFENC
	CALL	gPAR
	LD	L,A
; ---- v0.04: changed/new code or data
	LD	A,R
	AND	%11
	CP	L
	RET	NC
	INC	C ;уменьш силу удара на 50%
	SRA	C
	RET


;------нанесение ударов ---
kmkadze ;камикадзе уничт.здания
	LD	L,(IY+#1)
	LD	H,(IY+#2)
kkM0	DEC	L
	DEC	H
	LD	C,3
kkM1	PUSH	HL
	LD	B,3
kkM2	PUSH	BC
	PUSH	HL
	CALL	HLcorr
	CALL	_sMPAC
	POP	HL
	POP	BC
	INC	L
	DJNZ	kkM2
	POP	HL
	INC	H
	DEC	C
	JR	NZ,kkM1
	RET	Z


BMPACT ;пуля наносит удар
	LD	A,(IY+#3)
	LD	(HER_N),A
	CALL	N_IX
	LD	A,(IY+#1)
	BIT	7,A
; ---- v0.04: changed/new code or data (4.Z80: (по здан))
	JR	NZ,smpp2
	JR	smpp0


cMPACT ;удар снаряда танка (9клеток)
	LD	L,(IY+#1)
	LD	H,(IY+#2)
	PUSH	HL
	CALL	GMAP2
	LD	A,(HL)
	POP	HL
	CP	#38
	JR	C,ccM0
	CP	#80
	RET	C ;при ударе в здание - только в центр
ccM0	DEC	L
	DEC	H
	LD	C,3
ccM1	PUSH	HL
	LD	B,3
ccM2	PUSH	BC
	PUSH	HL
	CALL	_sMPAC
	POP	HL
	POP	BC
	INC	L
	DJNZ	ccM2
	POP	HL
	INC	H
	DEC	C
	JR	NZ,ccM1
	RET	Z

sMPACT ;одиночн.удар снаряда
	LD	L,(IY+#1)
	LD	H,(IY+#2)
;
_sMPAC	LD	A,(IY+#3)
	LD	(HER_N),A
; ---- v0.04: code removed
	CALL	GMAP2
	LD	A,(HL)
	CP	#80
	JR	C,smpp1
	SUB	#80 ;для врагов
smpp0	PUSH	IX
	LD	(en_A),A
	CALL	N_IX
	LD	(en_IX),HL
	CALL	gB_FRC
	LD	C,A
; ---- v0.04: changed/new code or data
	JR	IMPACT+18
;
smpp1	SUB	#38
	RET	C ;в пустое место
smpp2 ;для враж.зданий
	PUSH	IX
	CALL	B_IX
	LD	(en_IX),IX ;/для FX
	CALL	gB_FRC
	LD	C,A
	JR	buPA_

buPACT ;контактный удар по зданию
	CALL	gFORCE
	LD	C,A
	PUSH	IX
	LD	IX,(en_IX)
; ---- v0.04: changed/new code or data (4.Z80: (здание уже мертво))
buPA_
	LD	A,R
	AND	#7
	ADD	A,C
	LD	C,A
	SRL	C
	SRL	C
	SRL	C
	LD	A,(IX+3)
	SUB	C
	JR	NC,smpi0
	XOR	A
smpi0	LD	(IX+3),A
	LD	A,(HER_N) ;on индик0|3
; ---- v0.04: changed/new code or data (4.Z80: (никто))
	LD	D,A
	AND	#7F
; ---- v0.04: code removed (4.Z80: (для HELPme))
	CP	_NHER
; ---- v0.04: changed/new code or data
	LD	A,#01
	JR	NC,smpi31
	LD	(LED+3),A
; ---- v0.04: changed/new code or data (4.Z80: (обижают здание врага))
	LD	A,R
	AND	#0F
	JR	smpi3
smpi31	LD	(LED+0),A
; ---- v0.04: code removed
	LD	A,27
	CALL	SOUNDX ;"нас атакуют"
smpi3	POP	IX
	RET


IMPACT ;контактный удар
	LD	A,(en_A)
	CP	#80 ;здание?
	JP	NC,buPACT
;контактный удар врагу (en_IX)
	CALL	gFORCE
	LD	C,A
	PUSH	IX
	LD	IX,(en_IX)
; ---- v0.04: code removed (4.Z80: IMPA_ (трупы не отвечают))
IMPA_	; (в v0.04 код удалён, метка сохранена для ссылок)
	CALL	gDEFEN ; - защита
;понизить здоровье
	LD	A,(IX+health)
	SUB	C
	JR	NC,ipt1
	XOR	A
ipt1	LD	(IX+health),A
ipt2	POP	IX
;следует ли отвечать потерпевшему?
	RET	Z ;трупы не отвечают
; ---- v0.04: changed/new code or data
	RET
;
;
	LD	A,(en_A) ;кого?
	CP	_NHER
	LD	A,(HER_N) ;кто?
; ---- v0.04: changed/new code or data
	JR	NC,ipt11+3
;
;ударили нашего
	CP	_NHER
	RET	C ;ударил наш нашего
; ---- v0.04: changed/new code or data (4.Z80: (ударивший - мёртв))
	PUSH	IX
	LD	IX,(en_IX)
	CP	#80
	PUSH	AF
	LD	A,#01
	LD	(LED+0),A ;индик0 on
	LD	A,27
	CALL	SOUNDX
; ---- v0.04: changed/new code or data
	POP	AF
	JR	C,H_ANSW
; ударило заклинание - убегать
	LD	A,(IX+com)
	CP	2
	JR	Z,ipt11 ;уже убегает
	LD	A,R
	RRCA ;in 50%
	CALL	C,R_away
	JR	ipt11
H_ANSW ; ответн удар нашего
	CALL	_ANSW
	CALL	HL_IX0
	DEC	L
	DEC	H
	CALL	GMAP2
	CALL	ANSW1
	CALL	ANSW1
	CALL	ANSW1
	LD	DE,61
	ADD	HL,DE
	CALL	ANSW1
	INC	L
	CALL	ANSW1
	ADD	HL,DE
	CALL	ANSW1
	CALL	ANSW1
	CALL	ANSW1
ipt11	POP	IX
	RET
; ---- v0.04: changed/new code or data
	AND	#7F
	CP	#30
	RET	NC
	LD	A,#01
	LD	(LED+3),A
	CALL	HL_IX0
	PUSH	IX
	LD	IX,(en_IX)
	LD	A,(IX+#09)
	CP	#04
	JR	NZ,.ipt11_1
	CALL	DIST2
	INC	A
	LD	C,A
	CALL	HL_IXtEX
	CALL	DIST2
	CP	C
	JR	C,ipt11
	CALL	_ANSW+15
	JR	ipt11
.ipt11_1
	CALL	_ANSW+3
	JR	ipt11
;
ANSW1 ;по адр HL в GMAP2 - свой? (вых через POP)
	LD	A,(HL)
	INC	L
	SUB	#80
	RET	C ;нет (здание)
	CP	_NHER
	RET	NC ;нет (чужак)
	EXX ;сохр hl
	CALL	N_IX
_ANSW ;направить ответный удар на обидчика (HER_N)
	LD	A,(IX+com)
	LD	HL,impANS ;возможен ответ на удар?
	CALL	BA
	OR	A
; ---- v0.04: changed/new code or data (4.Z80: (земля против неба = ОК?))
	JR	Z,answ11
	LD	(IX+com),A
	LD	A,(HER_N)
	AND	#7F ;%1...
	LD	(IX+tarN),A
; ---- v0.04: changed/new code or data
	LD	(IX+#08),#80
	LD	(IX+#10),#FF
	CALL	HL_IX0
	CALL	IX_start
answ11	EXX
	RET
; ---- v0.04: code removed (4.Z80: (атакующий жив?) (атакующий - авиа/наземн?) (нельзя ответить на атаку с воздуха?))

AVvsGND ;земля против неба = ОК? (Z-no/NZ-yes)
;атака с воздуха
avvg1 ;атака с земли

K_ANSW ;ответ врага
;
;возможен ответ на удар?
;земля против неба = ОК?
;
;уже воюешь? - продолжай
;воюешь со зданием?
;не можешь ответить - сматывайся
;
knsw05 ;можешь ответить
;//для обычных воинов смена цели проводится через intel.a80
;для работников - сразу убегать
;для волшебников - атаковать, если не колдуешь
;

;цель вышла из зоны досягаемости



;ZZxx-----собств обработка
ZZ0 ;стоять
	CALL	ZZsee0
	JP	ZZ00 ;вызов интеллекта врагов

ZZ1 ;\стоять насмерть
ZZsee0	LD	A,#FF ;осмотреться после останова
	CP	(IX+move)
	RET	Z
	LD	(IX+move),A
	JP	ONSEE

ZZ27 ;танк атакует пустое место
	LD	HL,WW09
	LD	(JP_SUB+1),HL
	CALL	HL_IXtEX
	JP	ZZ4_

ZZ38 ;вернуться и стоять насмерть
	CALL	GO_MAN
	LD	A,(IX+move)
	OR	A
	JP	NZ,ONSEE2
	LD	(IX+com),1
	RET

ZZ3 ;идти в атаку
ZZ2 ;просто идти
	CALL	GO_MAN
	LD	A,(IX+move)
	OR	A
	JP	NZ,ONSEE2
	LD	(IX+com),A
	RET	Z

ZZ9 ;отойти-вернуться
	CALL	GO_MAN
	LD	A,(IX+move)
	OR	A
	JP	NZ,ONSEE2
	CALL	HL_IXw
	CALL	IXt_HL
	JP	IX_mov

ZZ29 ;патруль
	CALL	GO_MAN
	LD	A,(IX+move)
	OR	A
	JP	NZ,ONSEE2
	CALL	HL_IXw
	EX	DE,HL
	CALL	HL_IXtEX
	PUSH	HL
	SBC	HL,DE ;патруль в точке?
	POP	HL
	JP	Z,IX_stop
	CALL	IXw_HL
	EX	DE,HL
	CALL	IX_strt_
; ---- v0.04: changed/new code or data (4.Z80: (постоять) (не слишком ли далеко ушли?) (дист))
	CALL	ix_93a
	LD	(IX+3),#82
	RET
WATACK
	DEFB	#95,#D3,#A9,#D3,#A9,#D3,#BB,#D4,#99,#D4,#A7,#D4,#6A,#D4,#79,#D4
	DEFB	#8A,#D4,#C7,#D4,#91,#DA,#A9,#D3,#12,#D4,#A9,#D3,#A9,#D3,#B1,#D4
	DEFB	#3D,#D4,#12,#D4,#50,#D4,#79,#D4,#8A,#D4,#81,#DA,#8B,#DA,#A9,#D3
ZZ26
	CALL	HL_IXw
	CALL	DIST2
	CP	#06
	DEFB	#30,#7D ;JR NC,... (относительный переход)


;
ZZ37 ;Робот лечит издалека
;
ZZ4 ;Атака на цель
;
ZZ28 ;Атака на цель, которая м.быть прервана
	LD	A,(IX+typ)
	LD	HL,WATACK
	CALL	WT
	LD	(JP_SUB+1),HL
	LD	A,(IX+tarN)
;атака на врага/здание?
	PUSH	IX
	LD	(en_A),A
	BIT	7,A
	JR	Z,ZZ4a
;
	CALL	B_IX ;параметры вражеского здания
	LD	(en_IX),IX
	CALL	HL_IX0
	POP	IX
	CALL	DIST_H
	LD	B,A
	LD	C,0
	JR	ZZ4b
;
ZZ4a	CALL	N_IX ;параметры врага
	LD	(en_IX),HL
	CALL	HL_IX0
	LD	C,(IX+dir)
	POP	IX
	BIT	7,H
; ---- v0.04: changed/new code or data (4.Z80: (враг в здании))
	JR	NZ,IX_stox
ZZ4_	CALL	DIST2
	LD	B,A
;
ZZ4b	LD	A,L
	AND	A
; ---- v0.04: changed/new code or data (4.Z80: (враг мёртв))
	JR	Z,IX_stox
	LD	A,B
;в A-дистанция, в HL-коорд цели, bit7,C=0/1-наземн/авиа.юнит
	CALL	JP_SUB ;!! м.быть вых.через POP, если враг рядом (оружие применено)
	PUSH	HL ;преследовать,если цель далеко
	CALL	GO_MAN
	POP	HL
; ---- v0.04: code removed
;занести новые координаты цели
	LD	A,(IX+16)
	INC	A
	JR	Z,ZZ4em
	CALL	IXt_HL ; "я умный!"
	JR	ZZ4m
ZZ4em	LD	(IX+16),L
	LD	(IX+17),H
ZZ4m	LD	A,(IX+move)
	OR	A
	JP	NZ,ONSEE2
	LD	(IX+move),#80
	CALL	GO_MAN
	LD	A,(IX+move)
	OR	A
	JP	NZ,ONSEE2
;цель слишком далеко и дороги к ней нет
;
IX_stox	LD	A,(IX+com)
	CP	26
	JP	NZ,IX_stop
ZZ4_26 ;конец атаки на месте (26)
;если цель мертва/далеко - вернуться/стоять насмерть
	CALL	IX_mov
	LD	(IX+com),38
	CALL	HL_IXw
	JP	IXt_HL

;------процедуры ремонта

incREP	EQU	3 ;величина надбавки для техники
BREPA ;процесс лечения роботом
;
	LD	A,(IY+#1)
	BIT	7,A
	JR	NZ,bBREPA
;леч.тех
	CALL	N_IX
	OR	A
	JR	Z,noREPA
;здоров?
	LD	A,(IX+typ)
	LD	HL,HEALTH
	CALL	WA
	SUB	(IX+health)
	JR	Z,noREPA
	CP	incREP
	JR	C,brp1
	LD	A,incREP
brp1 ;средства есть?
	PUSH	AF
	LD	A,(IY+#3)
	CP	_NHER
	JR	NC,brp7 ;враги - бесплатно
	CALL	remRES ;для наших - уменьшить MN/WD
	JR	C,noREP_
brp7	POP	AF
	ADD	A,(IX+health)
	LD	(IX+health),A
	RET
;
noREP_	POP	HL
noREPA ;конец лечения
	LD	A,(IY+#3)
	CALL	N_IX
	OR	A
	RET	Z
	JP	IX_stop
;
bBREPA ;робот ремонтир. здания
	LD	C,(IY+#3)
	CALL	_REPA
	JR	Z,noREPA
	RET	NZ

peREPA ;пеон ремонт. здания
	LD	A,(HER_N)
	LD	C,A
	LD	A,(IX+tarN)
	AND	#7F
	PUSH	IX
	CALL	_REPA
	POP	IX
	RET	NZ
	JP	IX_stop

_REPA ;рем.здания IX (вх: C/A-кто/кого ремонтирует; вых: Z-конец рем)
	CALL	B_IX
	LD	A,(IX+2)
	LD	HL,bHEALT
	CALL	BA
	CP	(IX+3)
	RET	Z ;ремонт не нужен
	LD	A,C
	CP	_NHER
	JR	NC,_RP1 ;для врага - бесплатно
	CALL	remRES ;для наших - уменьшить MN/WD
	JP	NC,_RP1
	XOR	A ;=0
	RET	Z
_RP1	INC	(IX+3)
	RET

remRES ;уменьшение ресурсов при лечении
	LD	DE,0002 ;метл
	LD	BC,0001 ;маз
	JP	dMN_WD

;///////////////////////////////////
;WWxx - обработка действия 4 - атака
;///////////////////////////////////


	MACRO	wwA_  ;не может атаковать авиа юнитов
	BIT	7,C
	JR	NZ,wwAvsG
	ENDM

	MACRO	wwG_  ;не может атаковать наземных юнитов
	BIT	7,C
	JR	Z,wwAvsG
	ENDM

WW00 ;роботы
	EX	AF,AF'
	LD	A,(IX+com)
	CP	37
; ---- v0.04: changed/new code or data (4.Z80: (убегать))
	JR	NZ,WA23
;лечить ремонтом
	EX	AF,AF'
	CP	4+1
	RET	NC
	CALL	WWFire
; ---- v0.04: code removed
;ремонтируется?
;
	LD	A,30 ;в DE -коорд
	JP	ww3a

WA23 ;гнездолёт
WA11 ;шаттл
WW13 ;пеоны с грузом
WW14 ;\
WW01 ;роботы с грузом
WW02 ;\
	LD	A,(SIDE_N) ;убегать от обидчика
	OR	A
	JR	Z,R_away
	LD	A,R
	AND	3
	JR	NZ,R_away
	LD	HL,(pntX) ;в 25% бежать к точке сбора
	CALL	IXt_HL
	JP	IX_mov
;
R_away ;убегать от врага/отбегать случайно
	LD	(IX+com),2
;получить координаты врага в HL
R_awayX	PUSH	IX
	LD	A,(IX+tarN)
	BIT	7,A
	JR	Z,rawx2
	CALL	B_IX
	JR	rawx3
rawx2	CALL	N_IX
rawx3	CALL	HL_IX0
	POP	IX
;поиск точки побега, макс.удалённой от врага
	LD	BC,10*256 ;B -к-во попыток, C=0 -макс.дист
rawa0	PUSH	BC
	LD	C,(IX+x)
	CALL	RNDshf3
	LD	E,A
	LD	C,(IX+y)
	CALL	RNDshf3
	LD	D,A
	CALL	DISTde
	POP	BC
	CP	C
	JR	C,rawa1
	LD	C,A
	LD	(IX+tarX),E
	LD	(IX+tarY),D
rawa1	DJNZ	rawa0
;побежал
	JP	ix_93a

R_awa_ ;отбежать случайно
	LD	C,(IX+x)
	CALL	RNDshf7
	LD	(IX+tarX),A
	LD	C,(IX+y)
	CALL	RNDshf7
	LD	(IX+tarY),A
	JP	IX_mov

;........................
WW12 ;пеон
WW17 ;демон
	CP	2 ;дальность оружия
	RET	NC
	wwA_
	EX	DE,HL ;применить оружие
	CALL	HL_IX0
	CALL	DIR
	CALL	WWDir ;развернуться?
	JR	C,ww17a
ww17b	CALL	IMPIX3
	LD	(IX+move),0
	LD	A,(IX+com)
	CP	37
	PUSH	AF
	CALL	NZ,IMPACT ;атака
	POP	AF
	CALL	Z,peREPA ;пеон на ремонте
ww17a	POP	AF ;!
	JP	ONSEE ;надо бы один раз :(

WW16 ;кракотун
	CP	2 ;дальность оружия
	RET	NC
	wwA_
	EX	DE,HL ;применить оружие
	CALL	HL_IX0
	CALL	DIR
	LD	(IX+dir),A
	JR	ww17b ;без разворота

WW18 ;ланголетта (пушка)
	CP	8
	JR	NC,ww18a
	EX	DE,HL ;без разворота
	CALL	HL_IX0
	CALL	DIRF8
	EX	DE,HL
	LD	(IX+dir),A
	CALL	WWFire
	LD	A,10
	JR	ww3a
wwAvsG ;назем не атак авиа / авиа не атак наземн
ww18a ;! не двигается
	POP	AF ;!
	JP	IX_stop
; ---- v0.04: changed/new code or data
	CP	#09

WW06 ;зенитка (стингер)
	JR	NC,ww18a
	wwG_
	CALL	WZFire
	LD	A,4
	JR	ww3a

WW19 ;\.................
WW07 ;капел/варл
	CP	3
	RET	NC
	wwA_
	CALL	WWmana
	CALL	WWFire
	LD	A,5
	JR	ww08a
WW20 ;\
WW08 ;князь/зерг
	CP	5
	RET	NC
	CALL	WWmana
	CALL	WWFire
	LD	A,6
ww08a	POP	HL ;!
	JP	NEWBUL

WW04 ;огнемётчик
	CP	2
	RET	NC
	wwA_
	CALL	WWFire
	LD	A,2
	JR	ww3a

WW05 ;волкер
	CP	5
	RET	NC
	CALL	WWFire
	LD	A,3
	JR	ww3a

WW15 ;кунг
	CP	4
	RET	NC
	CALL	WWFire
	LD	A,9
	JR	ww3a

WW03 ;десантник
	CP	4
	RET	NC
	CALL	WWFire
	LD	A,1
ww3a	POP	HL ;!
	JP	NEWBUL
;
WW09 ;танк.............
	CP	7
	RET	NC
; ---- v0.04: changed/new code or data
	CP	#03
	JR	C,ww09b
;слишком близко?
	wwA_
;атака на позицию?
	LD	A,(IX+com)
	CP	27
	JR	Z,ww09c
;проверь вокруг
	LD	A,(SIDE_N)
	OR	A
	JR	NZ,ww09d
;наша кат не порань наших
	BIT	7,(IX+tarN)
	JR	NZ,ww09c
	PUSH	HL
	CALL	v4_mmf2_12+3
	POP	HL
	JR	NZ,ww09c
; ---- v0.04: changed/new code or data (4.Z80: (смени цель))
	JR	Z,ww09a1
ww09d ;враг не порань врага
	BIT	7,(IX+tarN)
	JR	NZ,ww09c ;огонь по зданию
	PUSH	HL
	CALL	isHERcell+14
	POP	HL
	CALL	NC,IX_stop
; ---- v0.04: changed/new code or data (4.Z80: (cмени цель))
	JR	NC,ww09a
ww09c	CALL	WWTank
	LD	A,7
; ---- v0.04: changed/new code or data
	CALL	NEWBUL
	CALL	onsee2
	JR	ww09a
;//LD A,(IX+com)
;//CP 27 ;режим одиночного выстрела?
ww09a1	CALL	Z,IX_stox
ww09a	POP	HL ;!dec sp
	RET
;
ww09b ;ближе к цели, чем надо
	LD	A,(SIDE_N)
	OR	A
	JR	Z,ww09a1 ;наш не умеет
; ---- v0.04: code removed
	CALL	R_away
; ---- v0.04: changed/new code or data
	JR	ww09a


;----

WWtDir ;выровнять напр (NC-ок,C-поворот)
	LD	A,(IX+dir)
	ADD	A,A
	ADD	A,(IX+6) ;башн
	AND	15
	SUB	L
wwtd_	RET	Z
	AND	15
	CP	8
	LD	A,(IX+6)
	JR	NC,wwt1
	DEC	A
	JR	wwt2
wwt1	INC	A
wwt2	AND	15
	LD	(IX+6),A
	SCF
	RET

WWTank	EX	DE,HL ;подготовиться танку
	PUSH	DE
	CALL	HL_IX0
	PUSH	HL
	CALL	DIRF16
	LD	L,A
	CALL	WWtDir
	JR	C,WWnFT
	JR	WWFi1
;........................


WWDir ;выровнять напр (NC-ок,C-поворот)
	SUB	(IX+dir)
	RET	Z
	AND	7
	CP	4
	LD	A,(IX+dir)
	JR	C,wwd1
	DEC	A
	JR	wwd2
wwd1	INC	A
wwd2	AND	7
	LD	(IX+dir),A
	SCF
	RET

WWFire	EX	DE,HL ;подготовиться применить оружие
	PUSH	DE
	CALL	HL_IX0
	PUSH	HL
	CALL	DIRF8
	CALL	WWDir
	JR	C,WWnF
WWFi1	CALL	Z,ONSEEx ;надо бы один раз :(
	POP	HL
	CALL	IMPIX3
	LD	(IX+move),0
	POP	DE
	RET
WWnFT	LD	(IX+phase_),#80 ;шобы башня круиТлась
WWnF	POP	HL
	POP	DE
	POP	AF ;! - разворот не окончен
	POP	AF ;!
	RET

;------

WWmana ;уменьш маны при стрельбе (no mana - 2xPOP,RET)
	LD	A,(IX+energy)
	OR	A
	JR	Z,WWma1
	SUB	2 ;декремент mana
	JR	NC,WWma2
	XOR	A
WWma2	LD	(IX+energy),A
	RET
WWma1	POP	HL ;!!
	POP	DE ;!!
	RET

;-------

WZFire	EX	DE,HL ;подготовиться применить зенитку
	PUSH	DE
	CALL	HL_IX0
	PUSH	HL
	CALL	DIRF16
	CALL	WZDir
	JR	C,WWnF
; ---- v0.04: changed/new code or data
	JR	WWFi1+3

WZDir ;выровнять напр (NC-ок,C-поворот)
	SUB	(IX+dir)
	RET	Z
	AND	15
	CP	8
	LD	A,(IX+dir)
	JR	C,wzd1
	DEC	A
	JR	wzd2
wzd1	INC	A
wzd2	AND	15
	LD	(IX+dir),A
	SCF
	RET
; ---- v0.04: code removed




;---ix+9-ф-ции-крестьян---
ZZ5 ;идти на базу
	CALL	HL_IXtEX
	CALL	DIST2
	CP	3
	JP	NC,ZZ2
	CALL	GMAP
	LD	A,(HL)
	AND	#7F
;база ещё не разрушена?
	CP	104
	JR	Z,ZZ5a
	CP	105
	JR	Z,ZZ5a
	CP	112
	JR	Z,ZZ5a
	CP	113
	JP	NZ,IX_stop
ZZ5a ;чья база?
	LD	A,(SIDE_N)
	OR	A
	JR	Z,ZZ5hum
;кунгов
	CALL	deGRUZ
;(принять ресурсы врага)
	JR	ZZ5ex
ZZ5hum ;людей
	CALL	deGRUZ
	LD	DE,#100
	PUSH	AF
	CALL	NZ,aMAZUT
	POP	AF
	CALL	Z,aMONEY
ZZ5ex	LD	(IX+com),24
	LD	(IX+3),#80+10 ;время нахожд. на базе
ZZ57	CALL	HL_IX0
	CALL	GMAP2
	LD	(HL),0
	LD	A,(HER_N)
	CALL	deSEL
	CALL	EVENT
	JP	unseeM


deGRUZ ;разгрузить (Z/NZ - был лес/золото)
	LD	A,(IX+4)
	CP	12
	JR	C,dgu1
	SUB	12
dgu1	DEC	A
	RET

ZZ6 ;идти за мазутом
	LD	A,(IX+4)
	OR	A
	JR	Z,ZZ6M
;пеоны
	CALL	HL_IXtEX
	CALL	DIST2
	CP	1
	JR	NZ,ZZ6M
	EX	DE,HL
	CALL	HL_IX0
	CALL	DIR
	LD	(IX+dir),A
	CALL	isMAZUT
	JP	C,ZZ6B
;
ZZ6M	CALL	GO_MAN
	LD	A,(IX+move)
	OR	A
	JP	NZ,ONSEE2
;
;есть ли рядом мазут?
	LD	A,(IX+4)
	OR	A
	JR	NZ,ZZ6A
;роботы
	CALL	HL_IX0
	CALL	isMAZU_
	JP	C,ZZ6B
	LD	B,5
ZZ6ar1	CALL	RND ;случайный поиск
	AND	7
	LD	C,A
	CALL	isMAZUT
	JR	NC,ZZ6ar2
	LD	A,C
	LD	HL,GO_Ntb
	CALL	WT
	LD	A,(IX+x)
	ADD	A,L
	LD	L,A
	LD	A,(IX+y)
	ADD	A,H
	LD	H,A
	CALL	IXt_HL
	LD	(IX+move),#80
	PUSH	BC
	CALL	GO_MAN
	POP	BC
	LD	A,(IX+move)
	OR	A
	RET	NZ
ZZ6ar2	DJNZ	ZZ6ar1
	LD	BC,(68*256)+0
	JR	ZZ6a2
;пеоны
ZZ6A	LD	A,(IX+dir)
	CALL	isMAZUT
	JR	C,ZZ6B ;он перед носом
	LD	B,8
ZZ6a1	LD	A,B
	DEC	A
	CALL	isMAZUT
	JR	C,ZZ6B_
	DJNZ	ZZ6a1
;поискать поблизости

	LD	BC,(60*256)+8
ZZ6a2	LD	A,C
	CALL	isMAZUT
	JR	C,ZZ6a4
ZZ6a6	INC	C
	DJNZ	ZZ6a2
;не нашли - стоп
	JP	IX_stop
ZZ6a4	LD	A,C ;нашли рядом - идти
	LD	HL,GO_Ntb
	CALL	WT
	LD	A,(IX+x)
	ADD	A,L
	LD	L,A
	CP	63
	JR	NC,ZZ6a6 ;вне карты
	LD	A,(IX+y)
	ADD	A,H
	LD	H,A
	CP	63
	JR	NC,ZZ6a6 ;вне карты
	CALL	IXt_HL
	LD	(IX+move),#80 ;надо бы +call SEARCM
	CALL	GO_MAN
	LD	A,(IX+move) ;перед циклофр препятствие
	OR	A
	JP	Z,IX_stop
	RET
ZZ6B_	DEC	B
	LD	(IX+dir),B
ZZ6B ;приступить к рубке леса
	CALL	ONSEE
	LD	(IX+com),25
	LD	(IX+move),0
	LD	A,(BrMAZUT) ;кол_во ударов по дереву
	LD	(IX+tarN),A
	RET

ZZ7 ;идти за золотом в шахту
	CALL	HL_IXtEX
	CALL	DIST2
	CP	3
	JP	NC,ZZ2
	CALL	GMAP
	LD	A,(HL)
	AND	#7F
;шахта ещё не разрушена?
	CP	103
	JP	NZ,IX_stop
;вычет денег из шахты
	M1toM2_
	PUSH	IX
	LD	A,(HL)
	SUB	#38
	CALL	B_IX
	LD	L,(IX+4)
	LD	H,(IX+5)
	DEC	HL
	LD	(IX+4),L
	LD	(IX+5),H
	LD	A,L
	OR	H
	JR	NZ,ZZ7b
	LD	(IX+3),A ;разрушЬ шахту
ZZ7b	CALL	HL_IX0
	POP	IX
	CALL	IXw_HL ;запомнить коорд шахты
	LD	(IX+com),23
	LD	(IX+3),#80+15 ;время нахожд. в шахте
	JP	ZZ57

ZZ8 ;идти на стр-во
	CALL	DISTpH
;подошли к зданию?
	CP	2
	JP	NC,ZZ2
;начать стройку/ремонт
	PUSH	IX
	CALL	HL_IXtEX
	CALL	GMAP2
	LD	A,(HL)
	SUB	#40 ;шахты не чинить
	JR	C,ZZ8_0
	CP	64
	JR	NC,ZZ8_0
	ADD	A,8
	LD	B,A
	CALL	B_IX
	LD	A,(IX+x)
	OR	A
	JR	NZ,ZZ8_1
;здания нет
ZZ8_0	POP	IX
	JP	IX_stop
ZZ8_1	LD	A,(IX+4)
	CP	253
	JR	NZ,ZZ8_0
ZZ8_2 ;cтройка
	LD	A,(IX+7)
	INC	A
	JR	NZ,ZZ8_0 ;строитель уже есть
	LD	A,(HER_N)
	LD	(IX+7),A
	POP	IX
	CALL	HL_IX0
	CALL	GMAP2
	LD	(HL),0
	CALL	HL_IXtEX
	CALL	IX0_HL
	LD	(IX+com),22
unseeM ;сделать человека невидимым
	SET	7,(IX+y)
	SET	7,(IX-3)
	RET

DISTpH ;расст до здания для крестьян
	CALL	HL_IXtEX
DIST_H	CALL	DIST2 ;-""- для воинов
; ---- v0.04: changed/new code or data
	OR	A
	RET	Z
	DEC	A
	RET


;-----ix+9---крестьяне работают---------------
ZZ22 ;строит дом
ZZ30 ;находится в истребителе
	RET ;none
ZZ23 ;выйти из шахты
	INC	(IX+4)
	LD	C,5
	CALL	basOUT
	JP	basTAR

ZZ24 ;выйти из базы
	LD	A,(IX+4)
	CP	12
	LD	A,0
	JR	C,ZZ24a
	LD	A,12
ZZ24a	BIT	0,(IX+4)
	LD	(IX+4),A
	LD	C,6
	JR	Z,ZZ24c
	INC	C
ZZ24c ;\
basOUT ;выйти из базы/шахты (C-нов действие)
	CALL	IX_mov
	LD	(IX+com),C
	LD	A,(IX+dir) ;развернись
	ADD	A,4
	AND	7
	LD	(IX+dir),A
;попробуй выйти, где вошёл
	RES	7,(IX+y)
	RES	7,(IX-3)
	CALL	HL_IX0
	CALL	GMAP2
	LD	A,(HL)
	OR	A
	JR	Z,bos11
;найти другую позицию
	CALL	HL_IXt
	CALL	stayON
	CALL	IX0_HL
	PUSH	HL
	XOR	A
	CALL	NEWix_
	POP	HL
	CALL	GMAP2
bos11	LD	A,(HER_N)
	ADD	A,#80
	LD	(HL),A
	CALL	HL_IXw
	JP	IXt_HL

ZZ25 ;добыча мазута
	LD	A,(IX+typ)
	CP	12
	LD	A,(IX+dir)
;роботы
	JR	NC,ZZ25p
	INC	A
	AND	7
	LD	(IX+dir),A
	CALL	HL_IX0
	CALL	GMAP
	JR	ZZ25r
ZZ25p ;пеоны
	CALL	isMAZUT
	JR	NC,noMAZUT
ZZ25r	DEC	(IX+tarN) ;удар по пятну
	JP	NZ,IMPIX3
ZZ25a ;уменьшить пятно
	CALL	deMAZUT
	CALL	HL_IXt
	CALL	IXw_HL
;идти на базу
	CALL	basTAR
	INC	(IX+4)
	INC	(IX+4)
	JP	EVENT
noMAZUT ;нет циклофр перед носом
	LD	(IX+com),6
	LD	(IX+move),#80
	RET

isMAZUT ;в направлении A - циклофреновые пятна? (С-да/NC-нет)
	LD	HL,GO_Ntb
	CALL	WT
	LD	A,(IX+x)
	ADD	A,L
	LD	L,A
	LD	A,(IX+y)
	ADD	A,H
	LD	H,A
isMAZU_	CALL	GMAP
	LD	A,(HL)
	AND	#7F
	SUB	15 ;циклофр - 15..18
	CP	4
	RET

deMAZUT ;взять циклофр ;HL-адр в мап
	LD	A,(HL)
	CP	#80+18
	JR	Z,deZ2
	CP	18
	JR	Z,deZ2
	INC	(HL)
	RET
deZ2	LD	A,(LEV_T)
	OR	A
	LD	A,-17 ;->1
	JR	Z,deZ1
	LD	A,20 ;->38
deZ1	ADD	A,(HL)
	LD	(HL),A
	RET


basTAR ;найти базу/газификатор (B=0/1) и направить на неё
	LD	A,(IX+4)
	CPL
	AND	1
	LD	B,A
	EXX
	CALL	HL_IX0
	LD	C,#FF ;миним расст
	PUSH	IX
	LD	B,32
	LD	DE,8
	LD	IX,HBUILD
	LD	A,(SIDE_N)
	OR	A
	JR	Z,bst0
	LD	IX,KBUILD
bst0	LD	A,(IX+2)
;это база?
	CP	8
	JR	C,bst4
	SUB	8
bst4	EXX
	CP	B ;определи здание
	EXX
	JR	NZ,bst2
;расст меньше минимального?
bst1	LD	A,(IX+x)
	OR	A
	JR	Z,bst2
	PUSH	BC
	CALL	DIST2
	POP	BC
	CP	C
	JR	NC,bst2
	LD	C,A
	LD	(en_IX),IX
bst2	ADD	IX,DE
	DJNZ	bst0
	LD	A,C
	CP	#FF
	JR	NZ,bstt
;некуда идти
	POP	IX
	JP	IX_stop
bstt ;идти на ближайшую базу
	LD	IX,(en_IX)
	CALL	HL_IX0
	POP	IX
	CALL	IXt_HL
	CALL	IX_mov
	LD	(IX+com),5
	RET


;-------------действия авиации---

IXA3_0	LD	A,(IX+phase_)
	OR	A
; ---- v0.04 aviaShot (101 байт #D8E0..#D944; раньше INCBIN образа): продолжение IXA3_0 - выбор действия авиации по IX+9 через таблицу
; переходов IXA3_t, затем AA29, AA27, AA26 (probably; в 4.Z80 этого кода нет, разобрано из образа)
	JR	NZ,IXA3_1
	LD	A,(IX+9)
	CP	#0A
	JR	C,IXA3x1
	SUB	#10
IXA3x1	LD	HL,IXA3_t
	CALL	WT
	JP	(HL)
IXA3_1	DEC	(IX+3)
	RET
ixa3P
IXA3_t ;таблица переходов (слова 5, 7, 8 - не адреса, а числа образа)
	DEFW	AA0,AAmov0,AAmov0,AAmov0,AA4X,#0005,AA6,#0007,#0008,AA9,AA26,AA27,AA4X,AA29

MOVAA ;п/п обр действий ix+9 для авиации

AA29 ;патруль
	CALL	GO_AVI
	LD	A,(IX+8)
	OR	A
	RET	NZ
	CALL	HL_IXw
	EX	DE,HL
	CALL	HL_IXt
	PUSH	HL
	SBC	HL,DE
	POP	HL
	CALL	Z,dXYpm2A
	CALL	IXw_HL
	EX	DE,HL
	CALL	IXt_HL
	LD	(IX+8),#80
	CALL	Aspeed0
	JR	AA29

AA27 ;тень атакует пустое место
	CALL	HL_IXt
	DEFB	#18,#39 ;JR #D976: относительный переход в AA4X-код ниже

AA26 ;стоять насмерть
	CALL	HL_IXw
	CALL	DIST2
	CP	#0C
	JP	NC,wad2+5
;
AA4 ;атаковать врага
AA28 ;\
AA4X ;атаковать врага
	LD	A,(IX+tarN)
	PUSH	IX
	LD	(en_A),A
	BIT	7,A
	JR	Z,AA4a
	CALL	B_IX ;параметры враж здания
	LD	(en_IX),IX
	CALL	HL_IX0
	POP	IX
	CALL	DIST_H
	LD	B,A
	JR	AA4b
AA4a	CALL	N_IX ;параметры врага
	LD	(en_IX),HL
	CALL	HL_IX0
	POP	IX
	BIT	7,H
	JP	NZ,wad2+5
AA4_	CALL	DIST2
	LD	B,A
AA4b	LD	A,L
; ---- v0.04: changed/new code or data
	AND	A
	JP	Z,wad2+5
	CALL	IXt_HL
	EX	DE,HL
	LD	A,(IX+typ)
	LD	HL,WATACK
	CALL	WT
	LD	A,B
;в A-дистанция, в DE-коорд цели
	JP	(HL) ;-->

AA0 ;зависнуть
	CALL	AAmov0
	JP	ZZ00 ;вызов интеллекта врагов
AA38 ;вернуться после атаки с места
AA1 ;зависнуть насмерть
AA3 ;лететь в атаку
AA2 ;просто лететь
;
AAmov0	CALL	GO_AVI
	LD	A,(IX+move)
	INC	A
	JP	Z,ON_AVI ;#FF
	DEC	A
	RET	NZ ;не 0, не #FF
;осмотреться после зависа
	CALL	cmpAVI
	LD	A,(IX+move)
	CP	#80
	JR	Z,AAmov0
; ---- v0.04: changed/new code or data (4.Z80: (0-стоп для остальных) (1-стоп для атаки с места) aamv00)
	LD	(IX+#09),#00
aamv00	; (в v0.04 код удалён, метка сохранена для ссылок)
aamv01	LD	(IX+move),#FF
	CALL	ONSEE
	JP	ON_AVI

AA9 ;туда-обратно
	CALL	GO_AVI
	LD	A,(IX+move)
	OR	A
	RET	NZ
	CALL	HL_IXw
	CALL	IXt_HL
	CALL	Aspeed0
; ---- v0.04: changed/new code or data
	CALL	IX_mov
	JR	AA0

AA5 ;доставка десанта

AA6 ;лететь и принять на борт
	PUSH	IX
	LD	A,(IX+tarN)
	CALL	N_IX
	LD	(en_IX),HL
	CALL	HL_IX0
	POP	IX
	LD	A,L
	OR	A ;уже убили
; ---- v0.04: changed/new code or data (4.Z80: (уже кто-то подобрал))
	JR	Z,AA0
	CALL	IXt_HL
	CALL	GO_AVI
	LD	A,(IX+move)
	OR	A
	RET	NZ
;принять на борт
	INC	(IX+17)
	LD	A,(IX+tarN)
	CALL	deSEL ;исключить из гр
	PUSH	IX
	LD	IX,(en_IX)
	CALL	HL_IX0 ;
	CALL	GMAP2 ;
	LD	(HL),0 ;
	CALL	unseeM ;убрать с карты
	CALL	IX_stop
	LD	(IX+com),30 ;находится в шаттле
	LD	A,(HER_N)
	LD	(IX+tarN),A ;No. шаттла
	POP	IX
	CALL	EVENT
	JP	AA0

;------атаки авиации

WAFire ;подготовиться применить оружие
	CALL	HL_IX0
	PUSH_
	CALL	DIRF16
	CALL	WADir
	JP	C,WAnF
	CALL	Z,ONSEEx ;надо бы один раз :(
	LD	A,(IX+typ)
	LD	HL,TimDEL
	CALL	BA
	LD	(IX+phase_),A
	CALL	Aspeed0
	POP_
	RET
WAnF	POP_
	POP	AF ;!
	RET

WADir ;выровнять напр (NC-ок,C-поворот)
	CPL
	SUB	(IX+dir)
	RET	Z
	CPL
	AND	15
	CP	8
	LD	A,(IX+dir)
	JR	C,wad1
	INC	A
	JR	NZ,wad2
	LD	A,-16
	JR	wad2
wad1	DEC	A
	CP	-16
	JR	NC,wad2
	LD	A,-1
wad2	LD	(IX+dir),A
	SCF
	RET
; ---- v0.04: changed/new code or data
	CALL	HL_IX0

AX_stox ;цель потеряна
	LD	A,(IX+com)
	CP	26
; ---- v0.04: changed/new code or data (4.Z80: (вернуться на место после))
	JR	NZ,ax01+3
ax01	CALL	HL_IXw
	CALL	IXt_HL
ax02	CALL	IX_stop
	CALL	Aspeed0
ax0x	JP	AAmov0
; ---- v0.04: code removed (4.Z80: WATAex (цель убегает) (преследуй цель))

WATAex	; (в v0.04 код удалён, метка сохранена для ссылок)


WA21 ;............тень
	LD	C,11
; ---- v0.04: changed/new code or data (4.Z80: (удары по месту?) (цель наземная?) wa2127)
	CP	#03
	JR	C,wad2+5
wa2127	; (в v0.04 код удалён, метка сохранена для ссылок)
	CP	7
; ---- v0.04: changed/new code or data
	JR	wa10c
wa21a ;цель слишком близка
WA22 ;............ворон
	LD	C,12
	CP	5
	JR	wa10c
WA10 ;............истр
	LD	C,8
	CP	5
; ---- v0.04: changed/new code or data (4.Z80: wa10c)
wa10c
	JR	NC,ax0x
	CALL	WAFire
	LD	A,C
	JP	NEWBUL
; ---- v0.04 menuWindow (1310 bytes at #DA9E): probably: in-game menu window drawing (dMN_WD), aMONEY/aMAZUT: add to the money / fuel counters (BCD) and the helpers of the menu text (spc_DO)
	CALL	v4_dMN_WD_12
	LD	A,(_BUT_H+7)
	CALL	putTX
	CALL	v4_spc_DO_4
	CALL	v4_dMN_WD_6
	JP	v4_mmf0_22+26
aMONEY
	DEFS	3 ;(было CALL chkCRC) страница 0: размер кода сохранён (в странице 0 есть абсолютные ссылки в таблицах)
	LD	HL,MONEY+5
	CALL	addBCD
	RET ;(было JP setCRC)
	NOP
	NOP
aMAZUT
	LD	HL,MAZUT+5
addBCD
	CALL	.aMAZUT_2
	LD	E,D
	CALL	.aMAZUT_2
	LD	E,#00
.aMAZUT_2
	LD	A,E
	CALL	.aMAZUT_3
	LD	A,E
	RLCA
	RLCA
	RLCA
	RLCA
.aMAZUT_3
	AND	#0F
	ADD	A,(HL)
	LD	(HL),A
	DEC	HL
	CP	#0A
	RET	C
	SUB	#0A
	INC	HL
	LD	(HL),A
	DEC	HL
	INC	(HL)
	RET
dMN_WD
	PUSH	DE
	LD	HL,MONEY
	CALL	.dMN_WD_4
	POP	DE
	LD	A,#00
	RET	C
	PUSH	DE
	LD	E,C
	LD	D,B
	LD	HL,MAZUT
	CALL	.dMN_WD_4
	POP	DE
	LD	A,#01
	RET	C
	LD	HL,MONEY+5
	DEFS	3 ;(было CALL chkCRC)
	CALL	.dMN_WD_1
	DEFS	3 ;(было CALL setCRC)
	LD	E,C
	LD	D,B
	LD	HL,MAZUT+5
	CALL	.dMN_WD_1
	XOR	A
	RET
.dMN_WD_1
	CALL	.dMN_WD_2
	LD	E,D
	CALL	.dMN_WD_2
	LD	E,#00
.dMN_WD_2
	LD	A,E
	CALL	.dMN_WD_3
	LD	A,E
	RLCA
	RLCA
	RLCA
	RLCA
.dMN_WD_3
	AND	#0F
	SUB	(HL)
	NEG
	LD	(HL),A
	DEC	HL
	OR	A
	RET	P
	INC	HL
	LD	A,#0A
	ADD	A,(HL)
	LD	(HL),A
	DEC	HL
	DEC	(HL)
	RET
.dMN_WD_4
	LD	A,(HL)
	INC	HL
	OR	(HL)
	RET	NZ
	CALL	.dMN_WD_5
	RET	NZ
	LD	D,E
	CALL	.dMN_WD_5
	RET	NZ
	CCF
	RET	Z
	CCF
	RET
.dMN_WD_5
	INC	HL
	LD	A,D
	RLCA
	RLCA
	RLCA
	RLCA
	AND	#0F
	CP	(HL)
	INC	HL
	CCF
	RET	NZ
	LD	A,D
	AND	#0F
	CP	(HL)
	CCF
	RET
v4_dMN_WD_6
	LD	A,#FF
	LD	(INDNbu),A
	LD	HL,(BX)
	LD	A,L
	CP	#19
	RET	C
	CP	#1F
	RET	NC
	LD	L,#00
	CP	#1C
	JR	C,.dMN_WD_7
	INC	L
.dMN_WD_7
	LD	A,H
	CP	#0A
	RET	C
	CP	#13
	RET	NC
	CP	#0D
	JR	NC,.dMN_WD_8
	XOR	A
	JR	.dMN_WD_9
.dMN_WD_8
	CP	#10
	LD	A,#02
	JR	C,.dMN_WD_9
	LD	A,#04
.dMN_WD_9
	ADD	A,L
	LD	C,A
	LD	(INDNbu),A
	LD	HL,BUT_N
	CALL	BA
	OR	A
	JR	Z,.dMN_WD_11
	LD	A,C
	LD	HL,BUT_N+6
	CALL	WT
	LD	(MONEY1),HL
	LD	A,C
	LD	HL,BUT_N+18
	CALL	WT
.dMN_WD_10
	LD	(MAZUT1),HL
	RET
.dMN_WD_11
	LD	H,A
	LD	L,H
	LD	(MONEY1),HL
	JR	.dMN_WD_10
v4_dMN_WD_12
	LD	HL,ext_M
	LD	DE,(BX)
	LD	A,E
	SUB	#19
	CP	#03
	JR	NC,.dMN_WD_13
	LD	A,D
	SUB	#05
	CP	#03
	JR	NC,.dMN_WD_13
	LD	A,(SEL_T)
	DEC	A
	JR	NZ,.dMN_WD_13
	LD	A,(HL)
	OR	A
	RET	NZ
	LD	A,#04
	JP	_EXT
.dMN_WD_13
	LD	A,(HL)
	CP	#04
	RET	NZ
	JP	EVENTr
GETmw
	LD	HL,BUT_N+6
	CALL	WA
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	LD	BC,#000B
	ADD	HL,BC
	LD	C,(HL)
	INC	HL
	LD	B,(HL)
	RET
	NOP
	DEC	B
	NOP
	LD	(BC),A
	NOP
	DEC	B
	NOP
	NOP
	NOP
	LD	B,#00
	INC	BC
	NOP
	DJNZ	.GETmw_1
.GETmw_1
	LD	B,#00
	ADD	HL,BC
	NOP
	INC	B
	NOP
	DJNZ	v4_GETmw_2
v4_GETmw_2
	INC	B
	LD	D,B
	INC	BC
	NOP
	NOP
	LD	D,B
	EX	AF,af'
	NOP
	NOP
	NOP
	LD	B,#00
	LD	B,#00
	DEC	B
	NOP
	INC	BC
	NOP
	RLCA
	NOP
	LD	BC,#0500
	LD	D,B
	LD	(BC),A
	NOP
	LD	(DE),A
	NOP
	NOP
	NOP
	DEC	B
	NOP
	NOP
	LD	D,B
	RLCA
	LD	(HL),L
	NOP
	NOP
	DEC	H
	LD	D,B
	LD	(BC),A
	NOP
	DEC	B
	LD	D,B
	LD	(BC),A
	LD	D,B
	RLCA
	NOP
	DEC	B
	NOP
	JR	NZ,v4_GETmw_8
	RLCA
	LD	D,B
	INC	BC
	NOP
	NOP
	NOP
	INC	B
	NOP
	NOP
	NOP
	INC	B
	LD	D,B
	NOP
	LD	D,B
	LD	B,#00
	LD	(BC),A
	NOP
	DEC	B
	LD	D,B
	LD	(BC),A
	NOP
	ADD	HL,BC
	NOP
	LD	BC,datSCR
	NOP
	SUB	B
	LD	D,B
	EX	AF,af'
	LD	D,B
	LD	BC,#1200
	NOP
	LD	B,#50
	EX	AF,af'
	NOP
	LD	B,#50
	EX	AF,af'
	DEC	H
	DEC	B
	NOP
	DJNZ	.GETmw_3
.GETmw_3
	ADD	HL,BC
	LD	D,B
	RLCA
	LD	D,B
	RLCA
v4_GETmw_4
	LD	A,(SEL_T)
	OR	A
	RET	Z
	CP	#07
	RET	Z
	JR	NC,.GETmw_5
	LD	A,(ext_M)
	OR	A
	RET	Z
	CP	#03
	RET	NC
.GETmw_5
	LD	A,#06
	EXX
	LD	DE,BUT_N+18
	EXX
	LD	DE,BUT_N+6
	LD	BC,BUT_N
v4_GETmw_6
	PUSH	AF
	LD	A,(BC)
	INC	BC
	CP	#16
	JR	C,.GETmw_7
	CP	#1E
	JR	C,v4_GETmw_10
	CP	#32
	JR	C,v4_GETmw_14
	CP	#43
	JR	C,v4_GETmw_12
	CP	#49
	JR	NC,.GETmw_7
	SUB	#43
	LD	HL,v4_GETmw_2+5
	JR	v4_GETmw_16
.GETmw_7
	INC	DE
	INC	DE
	EXX
v4_GETmw_8
	INC	DE
	INC	DE
	EXX
v4_GETmw_9
	POP	AF
	DEC	A
	JR	NZ,v4_GETmw_6
	RET
v4_GETmw_10
	SUB	#16
	LD	HL,v4_GETmw_2+29
	CP	#05
	JR	C,.GETmw_11
	LD	HL,v4_GETmw_2+41
.GETmw_11
	PUSH	HL
	LD	HL,hPARM
	CALL	BA
	POP	HL
	JR	v4_GETmw_16
v4_GETmw_12
	SUB	#32
	CP	#08
	JR	C,.GETmw_13
	SUB	#08
.GETmw_13
	LD	HL,GETmw+17
	JR	v4_GETmw_16
v4_GETmw_14
	SUB	#1E
	CP	#0A
	JR	C,.GETmw_15
	SUB	#0A
	CP	#07
	JR	C,.GETmw_15
	ADD	A,#03
.GETmw_15
	LD	HL,v4_GETmw_2+53
v4_GETmw_16
	CALL	DA
	LD	(DE),A
	INC	HL
	INC	DE
	LD	A,(HL)
	LD	(DE),A
	INC	HL
	INC	DE
	LD	A,(HL)
	EXX
	LD	(DE),A
	INC	DE
	EXX
	INC	HL
	LD	A,(HL)
	EXX
	LD	(DE),A
	INC	DE
	EXX
	INC	HL
	JR	v4_GETmw_9
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	LD	BC,#0706
	EX	AF,af'
	ADD	HL,BC
	RRCA
	LD	BC,#0504
	EX	AF,af'
	ADD	HL,BC
	RRCA
	LD	BC,#0310
	DEC	D
	LD	C,H
	RRCA
	LD	BC,#0310
	DEC	D
	LD	B,E
	RRCA
	LD	BC,#0310
	DEC	D
	LD	B,H
	RRCA
	LD	BC,#0310
	DEC	D
	LD	B,L
	RRCA
	LD	BC,#4610
	LD	B,A
	LD	C,B
	RRCA
	LD	BC,#4910
	LD	C,D
	LD	C,E
	RRCA
	LD	BC,#1214
	INC	DE
	LD	C,H
	RRCA
	LD	BC,#0000
	NOP
	NOP
	RRCA
	LD	BC,#0310
	DEC	D
	LD	C,L
	RRCA
	LD	BC,#0310
	LD	C,L
	LD	C,H
	RRCA
	LD	B,#0C
	INC	C
	JR	v4_GETmw_18+1
	INC	H
	NOP
	LD	HL,(GO_Ntb+5)
	LD	(DE),A
	LD	(HL),#06
	INC	C
	INC	C
	JR	v4_GETmw_19
	INC	H
	INC	A
	LD	HL,(ScUL_)
	LD	(DE),A
	DEFB	#36 ;(последний байт предыдущего фрагмента: образ v0.04 разобран со сдвигом)
BUTCLR ;probably: _BUT_H[0..6] = #FF (вход из списка _start, запись v4_GETmw_16+126)
	LD	HL,_BUT_H ;(в образе: байты #21,#F3,#74 - адрес переменной без метки)
	LD	B,#07
.GETmw_17
	LD	(HL),#FF
	INC	HL
	DJNZ	.GETmw_17
v4_GETmw_18
	LD	HL,BUT_H
	LD	DE,BUT_N
	LD	(HL),#00
	LD	BC,#001E
	LDIR
v4_GETmw_19
	RET
	LD	BC,#0706
	DJNZ	.GETmw_20
	DEC	D
	LD	(#FDFE),HL
	LD	(#3433),A
	DEC	(HL)
	LD	(HL),#37
	JR	C,v4_spc_DO_5
	DEC	SP
	INC	A
	DEC	A
	LD	A,#3F
	LD	B,B
.GETmw_20
	LD	C,L
	NOP
spc_DO
	CP	#4C
	JR	NC,.spc_DO_1
	CP	#43
	JR	NC,.spc_DO_3
.spc_DO_1
	LD	D,A
	LD	HL,v4_GETmw_19+1
.spc_DO_2
	LD	A,(HL)
	INC	HL
	OR	A
	RET	Z
	CP	D
	JR	NZ,.spc_DO_2
	LD	A,#01
	RET
.spc_DO_3
	SUB	#44
	RET	Z
	DEC	A
	RET	Z
	LD	A,#02
	RET
v4_spc_DO_4
	LD	A,(_event)
	OR	A
	RET	Z
	XOR	A
	LD	(_event),A
	CALL	v4_spc_DO_8
	CALL	v4_GETmw_4
	LD	A,(F_FUNC)
	CP	#FF
v4_spc_DO_5
	RET	Z
	LD	HL,BUT_N
	CALL	BA
	CALL	spc_DO
	CP	#01
	RET	Z
	JR	C,.spc_DO_6
	LD	A,(SEL_T)
	CP	#07
	RET	C
.spc_DO_6
	LD	A,(BUT_N)
	DEC	A
	JR	Z,.spc_DO_7
	LD	A,#FF
.spc_DO_7
	LD	(F_FUNC),A
	RET
v4_spc_DO_8
	CALL	v4_GETmw_18
	LD	A,(SEL_T)
	CP	#01
	JR	Z,.spc_DO_12
	JR	NC,.spc_DO_9
	LD	(_BUT_H+7),A
	RET
.spc_DO_9
	CP	#07
	JP	C,v4_spc_DO_31
	JP	NZ,v4_mmf0_5+6
	LD	A,(SEL_N)
	CP	#60
	JR	C,.spc_DO_10
	LD	A,#15
	LD	(_BUT_H+7),A
	LD	A,#0A
	JR	.spc_DO_11
.spc_DO_10
	CALL	N_IX
	LD	A,(IX+#04)
	LD	HL,DfSTACK
	CALL	BA
	LD	(_BUT_H+7),A
	ADD	A,#1D
.spc_DO_11
	LD	(BUT_H),A
	RET
.spc_DO_12
	LD	A,(SEL_N)
	CALL	N_IX
	LD	A,(IX+#04)
	LD	C,A
	LD	HL,DfSTACK
	CALL	BA
	LD	(_BUT_H+7),A
	ADD	A,#1D
	LD	(BUT_H),A
	LD	A,(ext_M)
	CP	#01
	JP	NC,v4_spc_DO_20
	LD	A,C
	LD	HL,v4_GETmw_16+102
	CALL	BA
	LD	L,A
	LD	H,#00
	LD	DE,v4_GETmw_16+24
	ADD	HL,DE
	EX	DE,HL
	LD	HL,BUT_N
	LD	B,#06
.spc_DO_13
	LD	A,(DE)
	CP	#12
	JR	Z,.spc_DO_16
	CP	#13
	JR	Z,.spc_DO_17
	CP	#4C
	JR	NC,.spc_DO_14
	CP	#43
	JR	NC,.spc_DO_18
.spc_DO_14
	LD	A,(DE)
	LD	(HL),A
.spc_DO_15
	INC	HL
	INC	DE
	DJNZ	.spc_DO_13
	RET
.spc_DO_16
	LD	A,(IX+#11)
	CP	#06
	JR	C,.spc_DO_14
	JR	.spc_DO_15
.spc_DO_17
	LD	A,(IX+#11)
	OR	A
	JR	NZ,.spc_DO_14
	JR	.spc_DO_15
.spc_DO_18
	CALL	v4_spc_DO_19
	JR	NZ,.spc_DO_14
	JR	.spc_DO_15
v4_spc_DO_19
	PUSH	HL
	SUB	#43
	LD	HL,hMAGIC
	CALL	BA
	POP	HL
	OR	A
	RET
	NOP
	LD	B,#01
	LD	(BC),A
	INC	B
	DEC	B
	INC	BC
v4_spc_DO_20
	CP	#03
	JP	NC,v4_mmf0_14+16
	PUSH	AF
	CALL	.spc_DO_26
	EXX
	LD	A,#02
	CALL	searcB
	EXX
	LD	D,A
	EXX
	LD	A,#04
	CALL	searcB
	EXX
	LD	E,A
	LD	HL,BUT_N
	LD	A,(MASTER)
	LD	B,#32
	OR	A
	JR	Z,.spc_DO_21
	LD	B,#3A
.spc_DO_21
	EXX
	LD	B,#03
	LD	DE,v4_spc_DO_19+12
	POP	AF
	CP	#01
	JR	Z,.spc_DO_22
	LD	DE,v4_spc_DO_19+15
	INC	B
.spc_DO_22
	LD	A,(DE)
	LD	HL,hBLDty
	CALL	BA
	OR	A
	JR	Z,.spc_DO_25
	LD	A,(DE)
	CP	#03
	JR	C,.spc_DO_24
	CP	#06
	JR	C,.spc_DO_23
	EXX
	LD	A,C
	EXX
	CP	#0A
	JR	C,.spc_DO_24
	JR	.spc_DO_25
.spc_DO_23
	EXX
	LD	A,D
	EXX
	OR	A
	JR	Z,.spc_DO_25
	LD	A,(DE)
	CP	#03
	JR	NZ,.spc_DO_24
	EXX
	LD	A,E
	EXX
	OR	A
	JR	Z,.spc_DO_25
.spc_DO_24
	LD	A,(DE)
	EXX
	ADD	A,B
	LD	(HL),A
	EXX
.spc_DO_25
	INC	DE
	EXX
	INC	HL
	EXX
	DJNZ	.spc_DO_22
	JP	v4_mmf0_5
.spc_DO_26
	LD	D,#00
	LD	HL,HBUILD
	LD	BC,#2000
.spc_DO_27
	LD	A,(HL)
	OR	A
	JR	NZ,.spc_DO_28
	LD	E,#08
	JR	.spc_DO_30
.spc_DO_28
	INC	L
	INC	L
	LD	E,#06
	LD	A,(HL)
	CP	#06
	JR	Z,.spc_DO_29
	CP	#0E
	JR	NZ,.spc_DO_30
.spc_DO_29
	INC	C
.spc_DO_30
	ADD	HL,DE
	DJNZ	.spc_DO_27
	RET
v4_spc_DO_31
	LD	B,A
	LD	HL,SEL_N
	LD	A,(ext_M)
	OR	A
	JR	NZ,v4_MINEo__6+19


;------------------------------

MINEoff	LD	C,#00 ;отключение проходимости (опасности) мин для врагов
; ---- v0.04: changed/new code or data (4.Z80: MINEon (включение проходимости (опасности) мин для врагов))
	PUSH	BC
	PUSH	HL
	LD	A,(HL)
	CALL	N_IX
	LD	A,(IX+#04)
MINEon	; (в v0.04 код удалён, метка сохранена для ссылок)
MINEo_ ;---
	LD	HL,v4_GETmw_16+102
; ---- v0.04 MINEoff (100 bytes at #DF41): MINEoff/MINEo_: switch the mine danger for the enemy on/off in the BUT_N table of the cells (CALL BA)
	CALL	BA
	LD	L,A
	LD	H,#00
	LD	DE,v4_GETmw_16+24
	ADD	HL,DE
	EX	DE,HL
	LD	HL,BUT_N
	LD	B,#06
v4_MINEo__1
	LD	A,(DE)
	CP	#08
	JR	Z,v4_MINEo__4
	CP	#09
	JR	Z,v4_MINEo__4
	CP	#12
	JR	Z,v4_MINEo__4
	CP	#14
	JR	Z,v4_MINEo__4
	CP	#43
	JR	C,v4_MINEo__2
	CP	#4C
	JR	NC,v4_MINEo__2
	CALL	v4_spc_DO_19
	JR	Z,v4_MINEo__4
	JR	v4_MINEo__3
v4_MINEo__2
	CP	#13
	JR	NZ,v4_MINEo__3
	LD	A,(IX+#11)
	OR	A
	JR	Z,v4_MINEo__4
v4_MINEo__3
	LD	A,C
	OR	A
	LD	A,(DE)
	JR	Z,v4_MINEo__5
	CP	(HL)
	JR	Z,v4_MINEo__6
v4_MINEo__4
	XOR	A
v4_MINEo__5
	LD	(HL),A
v4_MINEo__6
	INC	HL
	INC	DE
	DJNZ	v4_MINEo__1
	POP	HL
	POP	BC
	INC	HL
	INC	C
	LD	A,C
	CP	B
	JR	C,MINEoff+2
	LD	HL,#1116
	LD	(_BUT_H+7),HL
	RET
	LD	DE,BUT_N
mmf0	LD	A,(HL)
; ---- v0.04: code removed (4.Z80: (мина?))
	PUSH	HL
; ---- v0.04 mmf0Cells (193 bytes at #DF9D): probably: mmf0: the cells near the unit that it may use (HBUILD/KBUILD lookups)
	CALL	N_IX
	LD	A,(IX+#04)
	LD	HL,DfSTACK
	CALL	BA
	ADD	A,#1D
	POP	HL
	LD	(DE),A
	INC	HL
	INC	DE
	DJNZ	mmf0
	JR	v4_MINEo__6+12
	NOP
	RST	#38
	LD	B,#0C
	LD	(DE),A
	JR	mmf0+61
	RST	#38
	INC	H
	RST	#38
	LD	HL,(#1230)
	JR	.mmf0_1
	RST	#38
	LD	E,#00
	NOP
	NOP
	NOP
	LD	(#201F),HL
	LD	HL,#2325
	NOP
	LD	H,#27
	DEC	DE
	INC	E
	DEC	E
	NOP
	LD	D,#17
	JR	.mmf0_3
	LD	A,(DE)
	NOP
	LD	B,(HL)
	LD	B,A
	LD	C,B
	LD	B,L
	LD	B,H
.mmf0_1
	LD	B,E
	DEC	C
	LD	C,#0C
	LD	C,#00
	NOP
	JR	Z,.mmf0_2
.mmf0_2
	NOP
	NOP
	NOP
	NOP
	ADD	HL,HL
	LD	HL,(#2B2C)
	DEC	L
.mmf0_3
	NOP
	JR	NC,v4_mmf0_5+32
	CPL
	DEC	DE
	INC	E
	DEC	E
v4_mmf0_4
	LD	HL,#4217
	LD	(_BUT_H+7),HL
	LD	HL,#0B0B
	LD	(BUT_N+2),HL
	RET
v4_mmf0_5
	LD	A,#02
	LD	(BUT_N+5),A
	RET
	LD	A,(SEL_N)
	CALL	B_IX
	LD	A,(IX+#02)
	CP	#FF
	JP	Z,v4_mmf0_4
	LD	C,A
	ADD	A,#18
	LD	L,A
	ADD	A,#1A
	LD	H,A
	LD	(_BUT_H+7),HL
	LD	A,(SEL_N)
	CP	#28
	RET	NC
	LD	A,(IX+#04)
	INC	A
	JR	NZ,v4_mmf0_5
	LD	A,C
	LD	HL,mmf0+24
	CALL	BA
	INC	A
	RET	Z
	DEC	A
	LD	HL,mmf0+40
	CALL	BA
	LD	DE,BUT_N
	LD	B,#06
	LD	A,(HL)
	LD	C,A
	CP	#1E
	JR	C,.mmf0_6+5
	CP	#32
	JR	C,.mmf0_6+28
	SUB	#43
	JR	C,.mmf0_11
	PUSH	HL
; ---- v0.04: changed/new code or data
	LD	HL,hMAGty
	CALL	BA
; ---- v0.04 mmfScan (1468 bytes at #E05A): probably: second half of the map-cell filter mmf0: sight/passability tests of the cells (isRUNL, hPARM, searcB) writing the allowed cells of the unit
	OR	A
	JR	Z,.mmf0_6
	PUSH	DE
	LD	DE,#FFEF
	ADD	HL,DE
	LD	A,(HL)
	DEC	A
	POP	DE
.mmf0_6
	POP	HL
	JR	Z,v4_mmf0_12
	JR	.mmf0_11
	SUB	#16
	JR	C,.mmf0_11
	PUSH	HL
	PUSH	DE
	LD	HL,hPARM
	CALL	BA
	LD	DE,#0011
	ADD	HL,DE
	CP	(HL)
	POP	DE
	POP	HL
	JR	C,.mmf0_11
	JR	v4_mmf0_12
	SUB	#1E
	CP	#0A
	JR	C,.mmf0_7
	SUB	#0A
.mmf0_7
	PUSH	HL
	LD	HL,isRUNL+1
	CALL	BA
	POP	HL
	OR	A
	JR	Z,v4_mmf0_12
	LD	A,C
	CP	#21
	JR	Z,.mmf0_9
	CP	#2B
	JR	Z,.mmf0_9
	CP	#25
	JR	Z,.mmf0_9
	CP	#23
	JR	Z,.mmf0_8
	CP	#2D
	JR	NZ,.mmf0_11
.mmf0_8
	LD	A,#05
	JR	.mmf0_10
.mmf0_9
	LD	A,#04
.mmf0_10
	PUSH	HL
	PUSH	DE
	PUSH	BC
	CALL	searcB
	POP	BC
	POP	DE
	POP	HL
	JR	Z,v4_mmf0_12
.mmf0_11
	LD	A,C
	LD	(DE),A
v4_mmf0_12
	INC	HL
	INC	DE
	DJNZ	v4_mmf0_5+63
	RET
	NOP
	NOP
	NOP
	ADD	HL,BC
	INC	C
	DEC	DE
	DEC	DE
	NOP
	NOP
	LD	(DE),A
	INC	BC
	LD	B,#0F
	RRCA
	RRCA
	ADD	HL,BC
	DEC	D
	JR	.mmf0_13
	NOP
	NOP
	LD	E,#03
	LD	B,#02
	NOP
	NOP
	INC	E
.mmf0_13
	DEC	DE
	DEC	E
	DEC	E
	DEC	DE
	NOP
	RLA
	LD	D,#00
	JR	v4_mmf0_14+19
	NOP
	JR	v4_mmf0_14
v4_mmf0_14
	NOP
	JR	v4_mmf0_14+29
	ADD	HL,DE
	ADD	HL,DE
	LD	D,#00
	JR	.mmf0_15
	NOP
	RLA
	LD	A,(DE)
	NOP
	INC	E
	DEC	DE
	NOP
	LD	A,#2A
	LD	(_BUT_H+7),A
	LD	A,(SEL_N)
	LD	C,A
	CALL	N_IX
	LD	A,(IX+#04)
.mmf0_15
	CP	#0B
	JR	Z,.mmf0_19
	CP	#17
	JR	Z,.mmf0_19
.mmf0_16
	LD	A,(IX+#04)
	PUSH	AF
	LD	HL,v4_mmf0_12+5
	CALL	BA
	LD	HL,v4_mmf0_12+29
	CALL	BA
	LD	DE,BUT_N
	LDI
	LDI
	LDI
	POP	AF
	PUSH	AF
	LD	HL,AT_TYP
	CALL	BA
	LD	HL,#0000
	AND	#08
	JR	Z,.mmf0_17
	LD	A,(isRUNL+10)
	OR	A
	JR	Z,.mmf0_17
	LD	H,#12
.mmf0_17
	POP	AF
	CP	#0C
	JR	C,.mmf0_18
	CP	#15
	JR	NC,.mmf0_18
	LD	L,H
	LD	H,#1A
.mmf0_18
	LD	(BUT_N+4),HL
	RET
.mmf0_19
	LD	A,(IX+#11)
	OR	A
	JR	Z,.mmf0_16
	LD	A,#2C
	LD	(_BUT_H+7),A
	EXX
	LD	HL,BUT_N
	EXX
	CALL	loop_H
.mmf0_20
	LD	A,(IX+#00)
	OR	A
	JR	Z,.mmf0_21
	LD	A,(IX+#09)
	CP	#1E
	JR	NZ,.mmf0_21
	LD	A,(IX+#0C)
	CP	C
	JR	NZ,.mmf0_21
	LD	A,(IX+#04)
	LD	HL,DfSTACK
	CALL	BA
	ADD	A,#1D
	EXX
	LD	(HL),A
	INC	HL
	EXX
.mmf0_21
	ADD	IX,DE
	DJNZ	.mmf0_20
	RET
v4_mmf0_22
	LD	A,(ext_M)
	CP	#03
	JR	NZ,.mmf0_23
	LD	A,(INDNbu)
	INC	A
	JR	Z,.mmf0_23
	DEC	A
	LD	HL,SEL_T
	CP	(HL)
	JR	NC,.mmf0_23
	INC	HL
	CALL	BA
	JR	.mmf0_27
	LD	A,(SEL_T)
	CP	#01
	JR	Z,.mmf0_26
	JR	NC,.mmf0_31
.mmf0_23
	LD	HL,#0100
	LD	(IND1),HL
	LD	(IND2),HL
.mmf0_24
	XOR	A
.mmf0_25
	LD	(IND2TP),A
	RET
.mmf0_26
	LD	A,(SEL_N)
.mmf0_27
	CALL	N_IX
	LD	B,(IX+#06)
.mmf0_28
	LD	C,(IX+#05)
	LD	A,(IX+#04)
	LD	HL,HEALTH
	CALL	WT
	EX	DE,HL
	LD	A,D
	OR	A
	JR	Z,.mmf0_29
	LD	D,#F0
.mmf0_29
	LD	HL,IND1
	LD	(HL),C
	INC	HL
	LD	(HL),E
	INC	HL
	LD	(HL),B
	INC	HL
	LD	(HL),D
	INC	HL
	LD	A,D
	OR	A
	JR	Z,.mmf0_30
	LD	A,#01
.mmf0_30
	LD	(HL),A
	RET
.mmf0_31
	CP	#07
	JR	C,v4_mmf0_22
	JR	Z,.mmf0_39
	LD	A,(SEL_N)
	LD	C,A
	CALL	B_IX
	LD	A,(IX+#02)
	LD	HL,bHEALT
	CALL	BA
	LD	E,A
	LD	A,C
	CP	#08
	JR	C,.mmf0_37
	CP	#28
	JR	NC,.mmf0_38
	LD	A,(IX+#04)
	CP	#FF
	JR	NC,.mmf0_38
	CP	#FD
	JR	C,.mmf0_33
	EX	AF,af'
	LD	A,(IX+#02)
	LD	HL,bcTIME
	CALL	BA
	LD	C,A
	ADD	A,C
	LD	H,A
	EX	AF,af'
	JR	Z,.mmf0_32
	LD	C,#00
.mmf0_32
	EX	AF,af'
	SUB	C
	JR	.mmf0_36
.mmf0_33
	CP	#1A
	JR	C,.mmf0_34
	LD	A,#CC
	JR	.mmf0_35
.mmf0_34
	LD	HL,hcTIME
	CALL	BA
.mmf0_35
	LD	H,A
.mmf0_36
	SUB	(IX+#05)
	LD	L,A
	LD	(IND2),HL
	LD	H,E
	LD	L,(IX+#03)
	LD	(IND1),HL
	LD	A,#02
	JP	.mmf0_25
.mmf0_37
	LD	E,#FF
.mmf0_38
	LD	C,(IX+#03)
	LD	B,#00
	LD	D,B
	JR	.mmf0_29
.mmf0_39
	LD	A,(SEL_N)
	CALL	N_IX
	LD	B,#00
	CALL	.mmf0_28
	JP	.mmf0_24
v4_mmf0_40
	LD	DE,HBUILD
	LD	BC,#2088
	LD	A,#07
	LD	(v4_mmf0_47+2),A
	CALL	v4_mmf0_42
	LD	A,#0F
	LD	(v4_mmf0_47+2),A
	RET
v4_mmf0_41
	DEFB	#11,#84,#76
	LD	BC,#3000
v4_mmf0_42
	LD	HL,datMIN+64
	XOR	A
.mmf0_43
	DEC	L
	LD	(HL),A
	JR	NZ,.mmf0_43
	PUSH	BC
	EXX
	POP	BC
	LD	HL,datMIN+256
v4_mmf0_44
	EXX
	LD	A,(DE)
	INC	E
	OR	A
	JR	Z,v4_mmf0_47
	LD	L,A
	SRA	L
	SRA	L
	SRA	L
	LD	A,(DE)
	CP	#80
	JR	NC,v4_mmf0_47
	AND	#38
	OR	L
	LD	L,A
	LD	H,#B8
	LD	A,(HL)
	OR	A
	JR	Z,.mmf0_46
	LD	H,#B9
.mmf0_45
	LD	L,A
	LD	A,(HL)
	OR	A
	JR	NZ,.mmf0_45
.mmf0_46
	EXX
	LD	(HL),C
	INC	L
	LD	(HL),#00
	LD	A,L
	INC	L
	EXX
	LD	(HL),A
v4_mmf0_47
	LD	A,E
	ADD	A,#0F
	LD	E,A
	JR	NC,.mmf0_48
	INC	D
.mmf0_48
	EXX
	INC	C
	DJNZ	v4_mmf0_44
	RET
v4_mmf0_49
	LD	DE,KBUILD
	LD	BC,#20A8
	LD	A,#07
	LD	(v4_mmf0_56+2),A
	CALL	v4_mmf0_51
	LD	A,#0F
	LD	(v4_mmf0_56+2),A
	RET
v4_mmf0_50
	LD	DE,KUNGE
	LD	BC,#3030
v4_mmf0_51
	LD	HL,datMIN+64
	XOR	A
.mmf0_52
	DEC	L
	LD	(HL),A
	JR	NZ,.mmf0_52
	PUSH	BC
	EXX
	POP	BC
	LD	HL,datMIN+256
v4_mmf0_53
	EXX
	LD	A,(DE)
	INC	E
	OR	A
	JR	Z,v4_mmf0_56
	LD	L,A
	LD	A,(DE)
	CP	#80
	JR	NC,v4_mmf0_56
	LD	H,A
	PUSH	HL
	CALL	GMAP
	LD	A,(HL)
	POP	HL
	RLA
	JR	C,v4_mmf0_56
	SRA	L
	SRA	L
	SRA	L
	LD	A,H
	AND	#38
	OR	L
	LD	L,A
	LD	H,#B8
	LD	A,(HL)
	OR	A
	JR	Z,.mmf0_55
	LD	H,#B9
.mmf0_54
	LD	L,A
	LD	A,(HL)
	OR	A
	JR	NZ,.mmf0_54
.mmf0_55
	EXX
	LD	(HL),C
	INC	L
	LD	(HL),#00
	LD	A,L
	INC	L
	EXX
	LD	(HL),A
v4_mmf0_56
	LD	A,E
	ADD	A,#0F
	LD	E,A
	JR	NC,v4_mmf0_57
	INC	D
v4_mmf0_57
	EXX
	INC	C
	DJNZ	v4_mmf0_53
	RET
	LD	L,(IX+#00)
	SRA	L
	SRA	L
	SRA	L
	LD	A,(IX+#01)
	AND	#38
	OR	L
	LD	L,A
	LD	H,#B8
	RET
	LD	A,(TIC)
	RRCA
	CALL	v4_mmf0_50
	LD	HL,v4_mmf2_4+11
	LD	(QSC+1),HL
	CALL	loop_H
.mmf0_58
	LD	A,(IX+#00)
	OR	A
	JR	Z,.mmf0_62
	LD	A,(IX+#09)
	CP	#1C
	JR	Z,.mmf0_59
	CP	#02
	JR	NC,.mmf0_62
.mmf0_59
	LD	E,#FF
	CALL	v4_mmf1_2+64
	LD	A,E
	CP	#FF
	JR	NC,.mmf0_61
	LD	A,(IX+#09)
	DEC	A
	LD	A,#04
	JR	NZ,.mmf0_60
	LD	A,#1A
.mmf0_60
	LD	(IX+#09),A
	LD	(IX+#0C),D
	CALL	HL_IX0
	CALL	IXt_HL
.mmf0_61
	LD	DE,#0018
.mmf0_62
	ADD	IX,DE
	DJNZ	.mmf0_58
	LD	A,(TIC)
	RRCA
	RET	C
	CALL	v4_mmf0_49
	LD	HL,mmf2+8
	LD	(QSC+1),HL
	CALL	loop_H
.mmf0_63
	LD	A,(IX+#00)
	OR	A
	JR	Z,.mmf0_66
	LD	A,(IX+#09)
	CP	#02
	JR	NC,.mmf0_66
	LD	E,#FF
	CALL	v4_mmf1_2+64
	LD	A,E
	CP	#FF
	JR	NC,.mmf0_65
	LD	A,(IX+#09)
	OR	A
	LD	A,#1C
	JR	Z,.mmf0_64
	LD	A,#1A
.mmf0_64
	LD	(IX+#09),A
	LD	(IX+#0C),D
	CALL	HL_IX0
	CALL	IXt_HL
.mmf0_65
	LD	DE,#0018
.mmf0_66
	ADD	IX,DE
	DJNZ	.mmf0_63
	RET
	CALL	v4_mmf0_41
	CALL	loop_K
.mmf0_67
	LD	A,(IX+#00)
	OR	A
	JR	Z,.mmf0_72
	LD	A,(IX+#09)
	OR	A
	JR	Z,.mmf0_69
	CP	#03
	JR	Z,.mmf0_68
	CP	#1C
	JR	NZ,.mmf0_72
.mmf0_68
	LD	HL,v4_mmfon_6+14
	LD	A,(IX+#0D)
	CP	#06
	JR	C,.mmf0_70
	CALL	.mmf0_76
	JR	.mmf0_71
.mmf0_69
	LD	A,(IX+#04)
	CP	#07
	JR	Z,.mmf0_68
	CP	#10
	JR	Z,.mmf0_68
	LD	HL,v4_mmfon_4+8
.mmf0_70
	LD	(QSC+1),HL
	LD	E,#FF
	CALL	v4_mmf1_2+64
	LD	A,E
	CP	#FF
	JR	NC,.mmf0_71
	CALL	.mmf0_78
.mmf0_71
	LD	DE,#0018
.mmf0_72
	ADD	IX,DE
	DJNZ	.mmf0_67
	LD	A,(TIC)
	RRCA
	RET	NC
	CALL	v4_mmf0_40
	LD	HL,v4_mmfon_3+7
	LD	(QSC+1),HL
	CALL	loop_K
.mmf0_73
	LD	A,(IX+#00)
	OR	A
	JR	Z,.mmf0_75
	LD	A,(IX+#09)
	OR	A
	JR	NZ,.mmf0_75
	LD	A,(IX+#0D)
	CP	#06
	JR	NC,.mmf0_75
	LD	E,#FF
	CALL	v4_mmf1_2+64
	LD	A,E
	CP	#FF
	JR	NC,.mmf0_74
	LD	(IX+#09),#1C
	LD	(IX+#0C),D
	CALL	HL_IX0
	CALL	IXt_HL
.mmf0_74
	LD	DE,#0018
.mmf0_75
	ADD	IX,DE
	DJNZ	.mmf0_73
	RET
.mmf0_76
	CP	#0A
	RET	C
	LD	HL,v4_mmfon_6+8
	LD	(QSC+1),HL
	LD	E,#FF
	CALL	v4_mmf1_2+64
	LD	A,E
	CP	#FF
	JR	Z,.mmf0_77
	CP	#0A
	JP	NC,IX_stop
	LD	A,R
	LD	HL,DEFENC+99
	AND	(HL)
	JP	NZ,IX_stop
	LD	HL,(pntX)
	CALL	IXt_HL
	JP	IX_amov
.mmf0_77
	LD	A,R
	AND	#1D
	RET	NZ
	JP	IX_stop
.mmf0_78
	LD	A,(JP_SUB+3)
	ADD	A,A
	ADD	A,A
	ADD	A,#06
	LD	(DEFENC+97),A
	PUSH	BC
	PUSH	IX
	CALL	HL_IX0
	LD	C,D
	CALL	loop_K
.mmf0_79
	LD	A,(IX+#00)
	OR	A
	JR	Z,.mmf0_83
	LD	A,(IX+#0D)
	CP	#06
	JR	C,.mmf0_80
	LD	A,(IX+#09)
	CP	#04
	JR	NC,.mmf0_83
	CALL	IX_stop
	JR	.mmf0_83
.mmf0_80
	LD	A,(IX+#09)
	OR	A
	JR	Z,.mmf0_81
	CP	#03
	JR	Z,.mmf0_81
	CP	#1C
	JR	NZ,.mmf0_83
.mmf0_81
	PUSH	BC
	CALL	DIST2
	CALL	DEFENC+96
	JR	NC,.mmf0_82
	LD	(IX+#0C),C
	LD	(IX+#09),#04
	PUSH	HL
	CALL	HL_IX0
	CALL	IXt_HL
	POP	HL
	LD	A,(IX+#0D)
	CP	#01
	CALL	Z,v4_mmfon_1+15
	LD	A,(kPARM+20)
	OR	A
	JR	Z,.mmf0_82
	LD	(IX+#0D),#03
.mmf0_82
	POP	BC
.mmf0_83
	ADD	IX,DE
	DJNZ	.mmf0_79
	POP	IX
	POP	BC
	RET
	LD	A,(kPARM+20)
	OR	A
	RET	NZ
	LD	A,(JP_SUB+3)
	XOR	#37
	LD	L,A
	LD	A,R
	AND	L
	RET	NZ
	JR	v4_mmf0_84
	LD	A,(TIC)
	AND	#3F
	CP	#30
	RET	NC
	ADD	A,#30
	CALL	N_IX
	OR	A
	RET	Z
	LD	A,(IX+#0D)
	CP	#01
	RET	NZ
	LD	L,(IX+#0E)
	LD	H,(IX+#0F)
	CALL	DIST2
	CP	#06
	RET	C
	LD	A,R
	AND	#2E
	RET	NZ
v4_mmf0_84
	PUSH	IX
	CALL	HL_IX0
	CALL	loop_K
	LD	A,(IX+#00)
	OR	A
	JR	Z,v4_mmfon_1+8
	LD	A,(IX+#04)
	CP	#12
	JR	NC,v4_mmfon_1+8
	PUSH	BC
	CALL	DIST2
	CP	#09
	JR	NC,v4_mmfon_1+7
	LD	A,(IX+#0D)
	CP	#06
	JR	NC,v4_mmfon_1+7
	PUSH	HL
	CP	#01
	JR	NZ,mmfon
; ---- v0.04 mmfon (108 bytes at #E563): mmfon: group move: sends every unit of the group (loop with IXt_HL / IX_mov) to the cell, state IX+13 = 2
	LD	L,(IX+#0E)
	LD	H,(IX+#0F)
	JR	v4_mmfon_1
mmfon
	LD	(IX+#0D),#02
	LD	HL,(pntX)
v4_mmfon_1
	CALL	IXt_HL
	POP	HL
	CALL	IX_mov
	POP	BC
	ADD	IX,DE
	DJNZ	v4_mmf0_84+8
	POP	IX
	RET
	PUSH	IX
	LD	L,(IX+#0E)
	LD	H,(IX+#0F)
	LD	C,(IX+#04)
	CALL	loop_K
v4_mmfon_2
	LD	A,(IX+#00)
	OR	A
	JR	Z,v4_mmfon_3
	LD	A,(IX+#04)
	CP	C
	JR	NZ,v4_mmfon_3
	LD	A,(IX+#0D)
	CP	#02
	JR	NZ,v4_mmfon_3
	LD	(IX+#0E),L
	LD	(IX+#0F),H
	DEC	(IX+#0D)
	POP	IX
	LD	(IX+#0D),#03
	RET
v4_mmfon_3
	ADD	IX,DE
	DJNZ	v4_mmfon_2
	POP	IX
	RET
	PUSH	HL
	PUSH	BC
	INC	H
	LD	L,A
	PUSH	HL
	DEC	L
	LD	A,(HL) ;откл
; ---- v0.04 mmfonFar (92 bytes at #E5C0): probably: mmfon continuation: the nearest free cell search for the group (DIST2, B_IX)
	LD	C,A
	PUSH	IX
	AND	#7F
	CALL	B_IX
	CALL	HL_IX0
	LD	A,(IX+#02)
	POP	IX
	CALL	v4_mmf2_9
	CP	E
	JR	NC,v4_mmfon_4
	CP	#07
	JR	NC,v4_mmfon_4
	LD	E,A
	LD	D,C
v4_mmfon_4
	POP	HL
	LD	A,(HL)
	OR	A
	JR	NZ,v4_mmfon_3+10
	POP	BC
	POP	HL
	RET
	PUSH	HL
	PUSH	BC
	INC	H
v4_mmfon_5
	LD	L,A
	PUSH	HL
	DEC	L
	LD	A,(HL)
	LD	C,A
	PUSH	IX
	CALL	N_IX
	LD	HL,DEFENC+72
	CALL	gPAR
	LD	B,A
	CALL	HL_IX0
	POP	IX
	PUSH	BC
	CALL	DIST2
	POP	BC
	CP	B
	JR	NC,v4_mmfon_6
	CP	E
	JR	NC,v4_mmfon_6
	LD	E,A
	LD	D,C
v4_mmfon_6
	POP	HL
	LD	A,(HL)
	OR	A
	JR	NZ,v4_mmfon_5
	POP	BC
	POP	HL
	RET
	PUSH	HL
	PUSH	BC
	LD	B,#0B
	JR	v4_mmfon_6+18
; ---- v0.04 mmf2Near (35 bytes at #E618): probably: mmf2: loop over the cells: keep the nearest (DIST2) unit in D/E
	PUSH	HL
	PUSH	BC
	LD	B,#09
	INC	H
	LD	L,A
	PUSH	HL
	DEC	L
	LD	A,(HL)
	LD	C,A
	PUSH	IX
	CALL	N_IX
	CALL	HL_IX0
	POP	IX
	PUSH	BC
	CALL	DIST2
	POP	BC
	CP	B
	JR	NC,mmf2
	CP	E
	JR	NC,mmf2
	LD	E,A
	LD	D,C
mmf2	POP	HL
; ---- v0.04 mmf2Pick (198 bytes at #E63A): probably: mmf2: choose the nearest target of the group (DIST2, DEFENC+48 table, type limits)
	LD	A,(HL)
	OR	A
	JR	NZ,v4_mmfon_6+19
	POP	BC
	POP	HL
	RET
	PUSH	HL
	PUSH	BC
	INC	H
v4_mmf2_1
	LD	L,A
	PUSH	HL
	DEC	L
	LD	A,(HL)
	LD	C,A
	PUSH	IX
	AND	#7F
	CALL	B_IX
	CALL	HL_IX0
	LD	A,(IX+#02)
	POP	IX
	CALL	v4_mmf2_9
	CP	E
	JR	NC,v4_mmf2_3
	LD	B,A
	LD	A,(IX+#04)
	LD	HL,DEFENC+48
	CALL	BA
	CP	#08
	JR	NC,v4_mmf2_4
	CP	B
	JR	C,v4_mmf2_3
v4_mmf2_2
	LD	E,B
	LD	D,C
v4_mmf2_3
	POP	HL
	LD	A,(HL)
	OR	A
	JR	NZ,v4_mmf2_1
	POP	BC
	POP	HL
	RET
v4_mmf2_4
	LD	A,B
	CP	#03
	JR	C,v4_mmf2_3
	CP	#09
	JR	NC,v4_mmf2_3
	JR	v4_mmf2_2
	PUSH	HL
	PUSH	BC
	INC	H
v4_mmf2_5
	LD	L,A
	PUSH	HL
	DEC	L
	LD	A,(HL)
	LD	C,A
	PUSH	IX
	CALL	N_IX
	CALL	HL_IX0
	LD	(en_IX),HL
	POP	IX
	CALL	DIST2
	CP	E
	JR	NC,.mmf2_7
	LD	B,A
	LD	A,(IX+#04)
	LD	HL,DEFENC+48
	CALL	BA
	CP	#08
	JR	NC,.mmf2_8
	CP	B
	JR	C,.mmf2_7
.mmf2_6
	LD	E,B
	LD	D,C
.mmf2_7
	POP	HL
	LD	A,(HL)
	OR	A
	JR	NZ,v4_mmf2_5
	POP	BC
	POP	HL
	RET
.mmf2_8
	LD	A,B
	CP	#03
	JR	C,.mmf2_7
	CP	#09
	JR	NC,.mmf2_7
	PUSH	DE
	CALL	v4_mmf2_12
	POP	DE
	JR	Z,.mmf2_7
	JR	NZ,.mmf2_6
v4_mmf2_9
	CP	#08
	JR	Z,.mmf2_11
	CP	#12
	JR	Z,.mmf2_11
.mmf2_10
	CALL	DIST2
	DEC	A
	RET
.mmf2_11
	LD	A,L
	CP	(IX+#00)
	JP	C,DIST2
	LD	A,H
	CP	(IX+#01)
	JP	C,DIST2
	JR	.mmf2_10
v4_mmf2_12
	LD	HL,(en_IX)
	DEC	H
	DEC	L
	CALL	GMAP2
	CALL	isHERcell
	CALL	isHERcell
	CALL	isHERcell
	LD	DE,#003D
mmf1	ADD	HL,DE
; ---- v0.04: changed/new code or data
	CALL	isHERcell
	INC	L
	CALL	isHERcell
	ADD	HL,DE
	CALL	isHERcell
	CALL	isHERcell
	CALL	isHERcell
	INC	A
	RET
isHERcell ;probably: клетка карты в HL содержит юнита? (A=(HL); INC L; C - ниже #80, NC - от #AC)
	LD	A,(HL)
	INC	L
	CP	#80
	RET	C
	CP	#AC
	RET	NC
	POP	HL
	XOR	A
	RET
	LD	HL,(en_IX)
	DEC	H
	DEC	L
	CALL	GMAP2
	LD	A,(HL)
	CP	#AC
	RET	NC
	INC	L
	LD	A,(HL)
	CP	#AC
	RET	NC
	INC	L
	LD	A,(HL)
	CP	#AC
	RET	NC
	LD	DE,#003E
	ADD	HL,DE
	LD	A,(HL)
	CP	#AC
	RET	NC
	INC	L
	INC	L
	LD	A,(HL)
	CP	#AC
	RET	NC
	ADD	HL,DE
	LD	A,(HL)
	CP	#AC
	RET	NC
	INC	L
	LD	A,(HL)
	CP	#AC
	RET	NC
	INC	L
	LD	A,(HL)
	CP	#B0
	RET
v4_mmf1_2
	LD	A,L
	SUB	#09
	LD	L,A
	LD	A,(HL)
	OR	A
	CALL	NZ,QSC
	INC	L
	LD	A,(HL)
	OR	A
	CALL	NZ,QSC
	INC	L
	LD	A,(HL)
	OR	A
	CALL	NZ,QSC
	LD	A,L
	ADD	A,#06
	LD	L,A
	LD	A,(HL)
	OR	A
	CALL	NZ,QSC
	INC	L
	LD	A,(HL)
	OR	A
	CALL	NZ,QSC
	INC	L
	LD	A,(HL)
	OR	A
	CALL	NZ,QSC
	LD	A,L
	ADD	A,#06
	LD	L,A
	LD	A,(HL)
	OR	A
	CALL	NZ,QSC
	INC	L
	LD	A,(HL)
	OR	A
	CALL	NZ,QSC
	INC	L
	LD	A,(HL)
	OR	A
	CALL	NZ,QSC
	RET
	CALL	v4_mmf0_57+5
	CP	#08
	JR	C,.mmf1_3
	CP	#38
	JR	NC,.mmf1_4
	AND	#07
	JR	Z,.mmf1_6
	CP	#07
	JR	NZ,v4_mmf1_2
	JR	.mmf1_5
.mmf1_3
	OR	A
	JP	Z,.mmf1_14
	CP	#07
	JR	NZ,.mmf1_8
	JR	.mmf1_13
.mmf1_4
	JR	Z,.mmf1_12
	CP	#3F
	JR	C,.mmf1_9
	JR	.mmf1_11
.mmf1_5
	LD	A,L
	SUB	#09
	JR	.mmf1_7
.mmf1_6
	LD	A,L
	SUB	#08
.mmf1_7
	LD	L,A
	LD	A,(HL)
	OR	A
	CALL	NZ,QSC
	INC	L
	LD	A,(HL)
	OR	A
	CALL	NZ,QSC
	LD	A,L
	ADD	A,#07
	LD	L,A
	LD	A,(HL)
	OR	A
	CALL	NZ,QSC
	INC	L
	LD	A,(HL)
	OR	A
	CALL	NZ,QSC
	LD	A,L
	ADD	A,#07
	LD	L,A
	LD	A,(HL)
	OR	A
	CALL	NZ,QSC
	INC	L
	LD	A,(HL)
	OR	A
	CALL	NZ,QSC
	RET
.mmf1_8
	DEC	L
	JR	.mmf1_10
.mmf1_9
	SUB	#09
	LD	L,A
.mmf1_10
	LD	A,(HL)
	OR	A
	CALL	NZ,QSC
	INC	L
	LD	A,(HL)
	OR	A
	CALL	NZ,QSC
	INC	L
	LD	A,(HL)
	OR	A
	CALL	NZ,QSC
	LD	A,L
	ADD	A,#06
	LD	L,A
	LD	A,(HL)
	OR	A
	CALL	NZ,QSC
	INC	L
	LD	A,(HL)
	OR	A
	CALL	NZ,QSC
	INC	L
	LD	A,(HL)
	OR	A
	CALL	NZ,QSC
	RET
.mmf1_11
	SUB	#09
	LD	L,A
	JR	.mmf1_14
.mmf1_12
	SUB	#08
	LD	L,A
	JR	.mmf1_14
.mmf1_13
	DEC	L
.mmf1_14
	LD	A,(HL)
	OR	A
	CALL	NZ,QSC
	INC	L
	LD	A,(HL)
	OR	A
	CALL	NZ,QSC
	LD	A,L
	ADD	A,#07
	LD	L,A
	LD	A,(HL)
	OR	A
	CALL	NZ,QSC
	INC	L
	LD	A,(HL)
	OR	A
	CALL	NZ,QSC
	RET
	LD	L,D
	DEFB	#E8	; data (not code): RET PE
	LD	L,D
	DEFB	#E8	; data (not code): RET PE
	LD	A,E
	DEFB	#E8	; data (not code): RET PE
	LD	A,H
	DEFB	#E8	; data (not code): RET PE
	LD	A,E
	DEFB	#E8	; data (not code): RET PE
	LD	A,E
	DEFB	#E8	; data (not code): RET PE
	XOR	B
	DEFB	#E8	; data (not code): RET PE
	JP	NC,DSCR+2024
	DEFB	#E8	; data (not code): RET PE
	LD	A,E
	DEFB	#E8	; data (not code): RET PE
	INC	L
	DEFB	#ED
	INC	A
	DEFB	#ED,#5B,#ED,#5B ; (данные; в v0.04 разобраны как LD DE,(#5BED))
	IN	L,(C)
	DEFB	#ED,#7C
	DEFB	#ED
	ADD	A,A
	DEFB	#ED
	SBC	A,E
	DEFB	#ED
	LD	A,(IX+#0D)
	LD	HL,.mmf1_14+27
	CALL	WT
	JP	(HL)
	LD	L,(IX+#0E)
	LD	H,(IX+#0F)
	CALL	DIST2
	OR	A
	RET	Z
	CALL	IXt_HL
	JP	IX_amov
	RET
	CALL	v4_mmf1_15
	RET	Z
	JP	ZZ3
v4_mmf1_15
	LD	A,(isDIVMAP+1)
	CP	#FF
	RET	Z
	PUSH	IX
	CP	#80
	JR	NC,.mmf1_16
	CALL	N_IX
	JR	.mmf1_17
.mmf1_16
	AND	#7F
	CALL	B_IX
.mmf1_17
	CALL	HL_IX0
	LD	A,L
	OR	A
	POP	IX
	RET	Z
	CALL	IXt_HL
	JP	IX_amov
	RET
	LD	A,(IX+#04)
	CP	#09
	JR	C,.mmf1_18
	SUB	#09
.mmf1_18
	OR	A
	JP	NZ,basTAR
	LD	B,#08
.mmf1_19
	CALL	R_awa_
	CALL	HL_IXt
	CALL	GMAP
	LD	A,(HL)
	AND	#7F
	CP	#3D
	JR	C,.mmf1_20
	CP	#3F
	JR	C,.mmf1_21
.mmf1_20
	DJNZ	.mmf1_19
.mmf1_21
	LD	(IX+#09),#06
	RET
	LD	A,(IX+#04)
	CP	#09
	JR	C,.mmf1_22
	SUB	#09
.mmf1_22
	OR	A
	JP	NZ,basTAR
	CALL	HL_IX0
	LD	C,#FF
	PUSH	IX
	LD	B,#08
	LD	DE,#0008
	LD	IX,MINE
v4_mmf1_23
	LD	A,(IX+#00)
	OR	A
	JR	Z,.mmf1_24
	PUSH	BC
	CALL	DIST2
	POP	BC
	CP	C
	JR	NC,.mmf1_24
	LD	C,A
	LD	(en_IX),IX
.mmf1_24
	ADD	IX,DE
	DJNZ	v4_mmf1_23
	LD	A,C
	CP	#FF
	JR	NZ,.mmf1_25
	POP	IX
	LD	(IX+#0D),#06
	JP	IX_stop
.mmf1_25
	LD	IX,(en_IX)
	CALL	HL_IX0
	POP	IX
	CALL	IXt_HL
	LD	(IX+#09),#07
	LD	(IX+#08),#80
	RET






