;----ВЫБОР ГЕРОЕВ--------

mxybox ; установить в BC',DE' - лев.верхн.угол захвата
;

;
onSEL_ ;выбор одного героя
;выбор юнитов
	XOR	A
ons0	PUSH	AF
	LD	A,(IX)
	OR	A
	JR	Z,ons1
	BIT	7,(IX+y)
	JR	NZ,ons1
;попал в зону?
	CALL	onsX
	JR	NZ,ons1
;ближе предыдущего?
	EXX
	LD	A,(diXSEL)
	SRL	A
	SUB	L
	JR	NC,ons4
	NEG
ons4	LD	L,A
	LD	A,(diYSEL)
	SRL	A
	SUB	H
	JR	NC,ons5
	NEG
ons5	ADD	A,L ;summ dx+dy
	EXX
	LD	HL,minSEL
	CP	(HL)
	JR	NC,ons1
	LD	(HL),A
;юнит выбран
	POP	AF
	LD	HL,SEL_T
	CP	_NHER
	LD	(HL),1
	JR	C,ons2
	LD	(HL),7
ons2	INC	HL
	LD	(HL),A
	PUSH	AF
;
ons1	POP	AF
	ADD	IX,DE
	INC	A
	CP	_NALL
	JR	C,ons0
	RET

onsX ;проверить одного (вх: BC',DE' - лев.верхн.угол захвата)
;(вых: NZ/Z - no seL/sel, H,L - dY,dX)
	LD	A,(IX+4)
	LD	HL,AT_TYP
	CALL	BA
	AND	siz3x3
	LD	BC,8 ;смещ. до центра
	JR	Z,onsX2
	LD	C,12
onsX2 ;
	LD	L,(IX-2) ;по Y
	LD	H,(IX-1)
	SBC	HL,BC
	PUSH	HL
	EXX
	POP	HL
	XOR	A
	SBC	HL,DE
	OR	H
	JR	NZ,onsXN
	LD	A,(diYSEL)
	CP	L
	JR	C,onsXN
	LD	A,L
	EX	AF,AF'
	EXX
;
	LD	L,(IX-4) ;по X
	LD	H,(IX-3)
	ADD	HL,BC
	PUSH	HL
	EXX
	POP	HL
	XOR	A
	SBC	HL,BC
	OR	H
	JR	NZ,onsXN
	LD	A,(diXSEL)
	CP	L
	JR	C,onsXN
	EX	AF,AF'
	LD	H,A
	XOR	A
onsXN	EXX
	RET

homSEL ; выбор зданий (HL-adr in MAP)
	M1toM2_
	LD	A,(HL)
	CP	2
	RET	C
	CP	#80
	RET	NC
	SUB	#38
	JR	NC,hmS1
	M2toM1_
	LD	A,(HL)
	AND	#7F
	SUB	120
	RET	C
	M1toM2_
	PUSH	HL
	LD	HL,GSAT
	CALL	WT
	POP	DE
	ADD	HL,DE
	LD	A,(HL)
	AND	#7F
	SUB	#38
hmS1	LD	HL,SEL_T ;здание выбрано
	LD	(HL),8
	INC	HL
	LD	(HL),A
	RET

sngTB	DEFB	#CC,#F0,#C0
setBOX ;изменить тип выбора в рамке (клавиша "I")
	LD	A,(begBOX)
	OR	A
	JR	NZ,sngB1
	XOR	A
	JR	sngSet
sngB1	LD	HL,I_LOCK
	LD	BC,#DFFE
	IN	A,(C)
	AND	%11111
	CP	%11011
	JR	Z,sngB2
	LD	(HL),0
	RET
sngB2	LD	A,(HL)
	OR	A
	RET	NZ
	INC	(HL)
	LD	A,(typBOX)
	INC	A
	CP	3
	JR	C,sngSet
	XOR	A
sngSet	LD	(typBOX),A
	LD	HL,sngTB
	CALL	BA
	LD	(LMask),A
	RET



advBOX	EQU	5 ;приращение размеров бокса (<8)
selBOX ;выбор в боксе
	LD	A,(typBOX)
	CP	2
	JP	Z,sbxLND ;без авиации
	LD	HL,(BOXX)
	LD	BC,(BMX)
	LD	A,C
	CP	192
	JR	C,sbX4
	LD	C,192
sbX4	PUSH	HL
	XOR	A
	SBC	HL,BC
	POP	DE
	RET	Z
	XOR	A
	LD	(SEL_T),A
;найти BC',DE' - лев.верхн.угол и размеры рамки в diXYSEL
	LD	A,C
	SUB	E
	JR	NC,sbX5
	NEG
sbX5	PUSH	AF
	ADD	A,advBOX*2
	LD	(diXSEL),A
	POP	AF
	LD	A,E
	JR	NC,sbX51
	LD	A,C
sbX51	EXX
	LD	HL,(X0)
	LD	H,0
	LD	B,H
	LD	C,A
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	LD	DE,-advBOX
	ADD	HL,BC
	ADD	HL,DE
	PUSH	HL
	POP	BC
	EXX
	LD	A,B
	SUB	D
	JR	NC,sbX6
	NEG
sbX6	PUSH	AF
	ADD	A,advBOX*2
	LD	(diYSEL),A
	POP	AF
	LD	A,D
	JR	NC,sbX61
	LD	A,B
sbX61	EXX
	LD	HL,(Y0)
	LD	H,0
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,DE
	LD	E,A
	LD	D,0
	ADD	HL,DE
	EX	DE,HL
	EXX
;
	CALL	loopHb
;выбор авиации в боксе
	XOR	A
sbx0	PUSH	AF
	LD	A,(IX)
	OR	A
	JR	Z,sbx1
	isAVIA_ ;авиа?
	JR	Z,sbx1
;попал в зону?
	CALL	onsX
	JR	NZ,sbx1
;а он видимый?
	CALL	HL_IX0
	CALL	GMAP
	BIT	7,(HL)
	JR	NZ,sbx1
;выбрать юнита?
	POP	AF
	PUSH	AF
	LD	C,A
	CP	_NHER
	LD	HL,SEL_T
	LD	A,(HL)
	JR	C,sbxH0
;кунг/пленник
sbxK0	OR	A
	JR	NZ,sbx1
	LD	(HL),7
	INC	HL
	LD	(HL),C
	JR	sbx1
sbxH0	CP	7
	JR	C,sbxH1
	LD	(HL),0
sbxH1	INC	(HL)
	LD	A,(HL)
	PUSH	AF
	CALL	BA
	LD	(HL),C
	POP	AF
	CP	6
	JR	C,sbx1
	POP	AF ;группа=6
	RET
sbx1	POP	AF
	ADD	IX,DE
	INC	A
	CP	_NALL
	JR	C,sbx0
	LD	A,(typBOX)
	DEC	A
	RET	Z ;без сухопутных
	JR	sbxLN_
;
sbxLND	XOR	A
	LD	(SEL_T),A
sbxLN_	LD	(SET_SP+1),SP
	LD	HL,(BOXX) ;опред. размеров бокса /16
	SRL	L
	SRL	L
	SRL	L
	SRL	L
	SRL	H
	SRL	H
	SRL	H
	SRL	H
	LD	BC,(X0)
	ADD	HL,BC
	LD	DE,(PX)
	LD	A,E ;PX-в экране?
	SUB	C
	CP	12
	JR	C,sbb0
	LD	A,11
	ADD	A,C
	LD	E,A
sbb0	LD	A,E ;L ? E
	CP	L
	JR	NC,sbb1
	LD	E,L
	LD	L,A
sbb1	LD	A,D ;D ? H
	CP	H
	JR	NC,sbb2
	LD	D,H
	LD	H,A
sbb2	LD	A,E
	SUB	L
	LD	B,A
	LD	A,D
	SUB	H
	LD	C,A
	INC	C
	INC	B
	PUSH	BC ;\0
	PUSH	HL ;\1
;выбор наземной техники
	CALL	GMAP2
	LD	DE,64
sbgr0	PUSH	BC ;\2
	PUSH	HL ;\3
sbgr1	LD	A,(HL)
	SUB	#80
	JR	C,sbgr5
	M2toM1_
	BIT	7,(HL)
	M1toM2_
	JR	NZ,sbgr5
;
	PUSH	HL ;\4
	LD	HL,SEL_T
	LD	C,A
	CP	_NHER
	JR	NC,sbgK ;кунг/плен?
	PUSH	HL
	CALL	N_IX
	POP	HL
	CALL	isCANN
	JR	Z,sbgK ;пушка?
	LD	A,(HL)
	CP	7
	JR	C,sbgH1
	LD	(HL),0
sbgH1	INC	(HL)
	LD	A,(HL)
	PUSH	AF
	CALL	BA
	LD	(HL),C
	POP	AF
	CP	6
	JR	C,sbgr2
	JR	sb_EXI
sbgK ;кунги/пушки
	LD	A,(HL)
	OR	A
	JR	NZ,sbgr2
	LD	(HL),7
	INC	HL
	LD	(HL),C
sbgr2	POP	HL ;/4
;
sbgr5	INC	L
	DJNZ	sbgr1
	POP	HL ;/3
	ADD	HL,DE
	POP	BC ;/2
	DEC	C
	JR	NZ,sbgr0
;
	LD	HL,SEL_T
	LD	A,(HL)
	OR	A
	JR	Z,sbxBU
	CP	7
	JR	C,sb_EXI
	LD	A,(SEL_N) ;коррекция для пушек
	CP	_NHER
	JR	NC,sb_EXI
	LD	(HL),1
sb_EXI	JP	SET_SP ;!!
;
isCANN	LD	A,(IX+4) ;зенитка/ланголетта?
	CP	6
	RET	Z
	CP	18
	RET

sbxBU ;выбор зданий в боксе
	POP	HL ;/1
	POP	BC ;/0
	INC	B
	INC	C
	LD	A,H
	OR	A
	JR	Z,sbb3
	DEC	H
sbb3	LD	A,L
	OR	A
	JR	Z,sbb4
	DEC	L
sbb4 ;hl..de - абс окно просмотра
	LD	IX,MINE
	LD	DE,8
	LD	A,0
sbc10	PUSH	AF ;осмотреть все здания
	LD	A,(IX+x)
	OR	A
	JR	Z,sbc11
	SUB	L
	CP	B
	JR	NC,sbc11
	LD	A,(IX+y)
	SUB	H
	CP	C
	JR	NC,sbc11
;найдено
	PUSH	HL
	CALL	HL_IX0
	CALL	GMAP
	BIT	7,(HL)
	POP	HL
	JR	NZ,sbc11
	POP	HL ; A->H
	LD	L,8
	LD	(SEL_T),HL
	RET
sbc11	POP	AF
	ADD	IX,DE
	INC	A
	CP	32+32+8
	JR	C,sbc10
	RET

XY1st ;первонач X0,Y0
	LD	IX,HUMAN
	JR	ces0

centrS ;поместить в центр
	LD	A,(isMAP)
	OR	A
	RET	NZ
	LD	A,(SEL_T)
	OR	A
	RET	Z
	CP	8
	LD	A,(SEL_N)
	PUSH	AF
	CALL	NC,B_IX
	POP	AF
	CALL	C,N_IX
ces0	LD	A,(IX+x)
	CALL	cesS
	LD	L,A
	LD	A,(IX+y)
	CALL	cesS
	LD	H,A
	LD	(X0),HL
	RET
;
cesS	SUB	6
	JR	NC,ces1
	XOR	A
	RET
ces1	CP	52
	RET	C
	LD	A,52
	RET


flpSEL ;flip пометки селект
	LD	HL,SyLOCK
	LD	BC,#7FFE ;SYM Shift
	IN	A,(C)
	AND	%1111
	CP	%1101
	JR	Z,fP1
	LD	(HL),0
	RET
fP1	LD	A,(HL)
	OR	A
	RET	NZ
	INC	(HL)
	CALL	EVENTr
	LD	HL,(SEL_T)
	LD	A,L
	OR	A
	JP	Z,oneSEL
;поиск для отмены пометки
	PUSH	HL
	LD	HL,SEL_T
	LD	(HL),0
	PUSH	HL
	LD	HL,#1414 ;габариты зоны захвата
	CALL	oneSEL
	POP	HL
	LD	A,(HL)
	CP	1
	JR	Z,fP2
	POP	DE ;enem/home
	CP	E
	JR	NZ,fPE
	INC	HL
	LD	A,(HL)
	CP	D
	JR	NZ,fPE
	LD	E,0
fPE	LD	(SEL_T),DE
	RET
;
fP2	INC	HL
	LD	A,(HL)
	POP	HL
	LD	(SEL_T),HL
	LD	B,L
	LD	C,L
	LD	HL,SEL_N
fPL0	CP	(HL)
	JR	Z,deSEL ;outsel
	INC	HL
	DJNZ	fPL0
;addsel A
	LD	B,A
	LD	A,C
	CP	6
	RET	NC ;no mem
	LD	A,(SEL_N)
	CALL	N_IX
	CALL	isCANN
	RET	Z
	LD	A,B
	CALL	N_IX
	CALL	isCANN ;пушки?
	RET	Z
	LD	HL,SEL_T ;ins
	INC	(HL)
	LD	A,(HL)
	CALL	BA
	LD	(HL),B
	RET

deSEL ;исключить A из SEL_N и SEL2_N
	PUSH	AF
	CALL	swpSE1
	POP	AF
	PUSH	AF
	CALL	deSE1
	CALL	swpSE1
	POP	AF
;
deSE1 ;исключить А из SEL_N
	EX	AF,AF'
	LD	HL,SEL_T
	LD	A,(HL)
	OR	A
	RET	Z
	INC	HL
	CP	7
	JR	C,dL1
	RET	NZ
;враг
	EX	AF,AF'
	CP	(HL)
	RET	NZ
	DEC	HL
	LD	(HL),0
	RET
dL1 ;наш
	LD	B,A
	EX	AF,AF'
dL0	CP	(HL)
	JR	Z,dL2
	INC	HL
	DJNZ	dL0
	RET
dL2	DEC	B
	JR	Z,dL3
	PUSH	HL
	POP	DE
	INC	HL
	LD	C,B
	LD	B,0
	LDIR
dL3	LD	HL,SEL_T
	DEC	(HL)
	RET

swpSEL ;swap выбранных наборов (клавиша "W")
	LD	BC,#FBFE
	LD	HL,W_LOCK
	IN	A,(C)
	AND	%11111
	CP	%11101
	JR	Z,sww0
	LD	(HL),0
	RET
sww0	LD	A,(HL)
	OR	A
	RET	NZ
	INC	(HL)
	CALL	swpSE1
;сменить индик
	LD	A,(indSEL)
; ---- v0.04: changed/new code or data
	XOR	#18
	LD	(indSEL),A
	CALL	EVENTr
;попадает ли выборка в экран
	LD	HL,SEL_T
	LD	A,(HL)
	OR	A
	RET	Z
	CP	7
	RET	Z
	JP	NC,centrS
	LD	B,A
	LD	DE,(X0)
swwL	INC	HL
	PUSH	HL
	LD	A,(HL)
	CALL	N_IX
	SUB	E
	JR	C,sww5
	CP	12
	JR	NC,sww5
	INC	HL
	LD	A,(HL)
	SUB	D
	JR	C,sww5
	CP	12
	JR	NC,sww5
	POP	HL
	RET
sww5	POP	HL
	DJNZ	swwL
	JP	centrS

swpSE1 ;swap наборов SEL_ и SEL2_
	LD	HL,SEL_T
	LD	DE,SEL2_T
	LD	B,7
sws0	LD	A,(DE)
	LD	C,(HL)
	LD	(HL),A
	LD	A,C
	LD	(DE),A
	INC	HL
	INC	DE
	DJNZ	sws0
	RET


;процедуры выбора
capSEL ;Выбор/рамка по CAPS
	LD	HL,(BMX)
	LD	A,(T_FIRE)
	CP	2
	JR	Z,BB1
	LD	A,(isMAP)
	OR	A
	JR	NZ,BB0
	LD	A,(begBOX)
	OR	A
	RET	Z
	CALL	EVENTr
	CALL	selBOX
BB0	XOR	A
	LD	(begBOX),A
	RET
BB1 ;pCAPS
	LD	A,L
	CP	192
	RET	NC
	LD	A,(isMAP)
	OR	A
	RET	NZ
	LD	A,(begBOX)
	OR	A
	RET	NZ
	INC	A
	LD	(begBOX),A
	LD	A,L
	CP	192
	JR	C,BB4
	LD	L,191
BB4	LD	(BOXX),HL
	LD	HL,(PX)
	CALL	EVENTr
	JP	oneSEL

selGRP ;для группы - смена меню
	LD	HL,selGR1
	LD	A,(HL)
	LD	(HL),0
	INC	HL
	OR	A
	JR	NZ,slg1
	LD	(HL),A
	RET
slg1	LD	A,(HL)
	OR	A
	RET	NZ
	LD	(HL),H
	LD	HL,ext_M ;0<->3
	LD	A,3
	SUB	(HL)
	JP	_EXT



SELECT ;=========Выбор ф-ции на панели упр========
;функц кнопки
	LD	BC,#F7FE
	IN	A,(C)
	LD	DE,#500
fun0	RRCA
	JR	NC,fun1
	INC	E
	DEC	D
	JR	NZ,fun0
	LD	B,#FD
	IN	A,(C)
	AND	7
	CP	E
	JR	Z,fun1
	LD	E,#FF
fun1	LD	A,E
	LD	(_n_FUN),A
	CP	#FF
	RET	C
;fire на панели
	LD	A,(T_FIRE)
	DEC	A
	RET	NZ
	LD	HL,(BX)
	LD	A,L
; ---- v0.04: changed/new code or data
	CP	#19
	RET	C
	LD	A,H
	CP	19
	RET	Z
; ---- v0.04: changed/new code or data
	JR	NC,dwnPP
	CP	9
	RET	Z
; ---- v0.04: changed/new code or data
	JR	NC,midPP
upPP ;кнопка героя/группы
	CP	4
; ---- v0.04: code removed
	RET	C
	LD	A,(BUT_H)
	CP	17 ;группа?
	JP	NZ,centrS
	LD	(selGR1),A
	RET
dwnPP ;нижняя панель
	LD	A,L
	CP	30
; ---- v0.04: changed/new code or data
	RET	C
;вход в гл.меню
	XOR	A
	LD	(T_FIRE),A
	JP	gmMENU
midPP ;шесть кнопок управления
	LD	A,L
	SUB	25
; ---- v0.04: code removed
	CP	6
	RET	NC
	LD	L,0
	LD	E,L
	CP	3
	JR	C,mi1
	INC	L
mi1	LD	A,H
	SUB	10
	CP	3
	JR	C,mi2
	LD	E,2
	CP	6
	JR	C,mi2
	LD	E,4
mi2	LD	A,E
	ADD	A,L
	LD	(_n_FUN),A
	RET
; ---- v0.04: changed/new code or data (4.Z80: indpptb (нет информации) (нет информации))
	LD	A,#FF
	LD	(N_FUN1),A
	LD	HL,_n_FUN
	CP	(HL)
	JR	NZ,.mi2_1
	INC	HL
	LD	(HL),A
	RET
.mi2_1
	LD	A,(N_FUNC)
	CP	#FF
	RET	C
	LD	A,(HL)
	INC	HL
	LD	(HL),A
	INC	HL
	LD	(HL),A
	LD	B,A
	LD	HL,BUT_N
	CALL	BA
	LD	C,A
indpptb	; (в v0.04 код удалён, метка сохранена для ссылок)
indPP ;нажатие на индикаторы
ii1 ;переместить экран по индикатору

;==============================================

FIRBUT ;обработка нажатия иконки + подсветка
	CALL	spc_DO
	CP	1
	JR	C,IMMED
	JR	Z,nSQ1
	LD	A,(SEL_T)
	CP	7
	JR	NC,IMMED
nSQ1	LD	A,B
	LD	(F_FUNC),A ;выбор без немедл. действия
	RET


IMMED ;НЕМЕДЛЕННАЯ обработка нажатий на кнопки
;(B-#кн (0..5), C-её тип (0..75))
	LD	A,(SEL_T)
	CP	7
	RET	Z
	JP	NC,prcBLT
	DEC	A
	JR	Z,prcHER
	LD	A,(ext_M)
	OR	A
	JR	Z,prcHER
;выделить одного из отряда
	LD	A,B
	LD	HL,SEL_N
	PUSH	HL
	CALL	BA
	POP	HL
	LD	(HL),A
	DEC	HL
	LD	(HL),1
	CALL	NOlamp
	JP	EVENTr

prcHtb	DEFB	2
	DEFW	pcH2
	DEFB	3
	DEFW	pcH3
	DEFB	4
	DEFW	pcH4
	DEFB	5
	DEFW	pcH5
	DEFB	8
	DEFW	pcH8
	DEFB	9
	DEFW	pcH9
	DEFB	15
	DEFW	pcH15
	DEFB	19
	DEFW	pcH19
	DEFB	68
	DEFW	pcH68
	DEFB	69
	DEFW	pcH69
	DEFB	76
	DEFW	pcH76

	DEFB	0



prcHER ;обработка немедл действ для героев
;действия 2,3,4,5, 8,9, 15, 19, 68,69, 76

	LD	HL,prcHtb
prcHE0	LD	A,(HL)
	OR	A
	JR	Z,NOlamp
	INC	HL
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	INC	HL
	CP	C
	JR	NZ,prcHE0
	EX	DE,HL
	JP	(HL)

NOlamp ;-=кнопка не засвечивается=-
	LD	A,#FF
	LD	(N_FUN1),A
	RET

pcH8 ;осн меню стр-ва
	LD	A,1
pch8_	CALL	_EXT
	LD	A,#FF
	LD	(F_FUNC),A
	RET
pcH9 ;доп меню стр-ва
	LD	A,2
	JR	pch8_
pcH2 ;возвр в меню0
	JP	EVENTr
pcH5 ;сбросить груз
	LD	HL,SEL_T
	LD	B,(HL)
pch5a	INC	HL
	PUSH	BC
	PUSH	HL
	LD	A,(HL)
	CALL	N_IX
	LD	A,(IX+4)
	CP	3
	LD	A,12
	JR	NC,pch5b
	XOR	A
pch5b	LD	(IX+4),A
	CALL	IX_stop
	POP	HL
	POP	BC
	DJNZ	pch5a
	JP	EVENTr
pcH4 ;идти на базу
	XOR	A
	LD	(SIDE_N),A
	LD	HL,SEL_T
	LD	B,(HL)
pch4a	INC	HL
	PUSH	BC
	PUSH	HL
	LD	A,(HL)
	CALL	N_IX
	CALL	basTAR
	POP	HL
	POP	BC
	DJNZ	pch4a
	RET
pcH3 ;стоять на смерть
	LD	C,1
	JR	pch15a
pcH15 ;остановиться
	LD	C,0
pch15a	LD	HL,SEL_T
	LD	B,(HL)
pch15b	INC	HL
	PUSH	HL
	LD	A,(HL)
	CALL	N_IX
	CALL	HL_IX0
	isAVIA_
	JR	NZ,pch15b+21
	LD	(IX+move),0 ;наземн стоп
; ---- v0.04: changed/new code or data
	JR	pch15c
	LD	A,(IX+#08)
	OR	A
	JR	Z,pch15c
	INC	A
	JR	Z,pch15c
pch15d ;авиа стоп
	CALL	IXt_HL
pch15c	CALL	IXw_HL
	LD	(IX+com),C
	POP	HL
; ---- v0.04: changed/new code or data
	DJNZ	pch15b
	RET


pcH19 ;высадить десант
	LD	HL,SEL_T
	LD	B,(HL)
pch19a	INC	HL
	PUSH	BC
	PUSH	HL
	LD	A,(HL)
	LD	C,A
	CALL	N_IX
	CALL	IX_stop
	CALL	HL_IX0
	CALL	GMAP2 ;ищем место для высадки
	LD	A,(HL)
	OR	A
	JR	Z,pch19ex
	EX	DE,HL
	LD	B,7
pch19c	LD	A,B
	LD	HL,inMAP
	CALL	WT
	ADD	HL,DE
	LD	A,(HL)
	OR	A
	JR	Z,pch19ex
	DJNZ	pch19c
	JR	pch19b ;нет места
pch19ex ;поиск членов экипажа
	CALL	HL_IX0
	INC	H
	LD	(IX+17),0
	LD	IX,HUMAN
	LD	B,0
pch19e0	PUSH	HL
	LD	A,(IX+x)
	OR	A
	JR	Z,pch19e1
	LD	A,(IX+com)
	CP	30
	JR	NZ,pch19e1
	LD	A,(IX+tarN)
	CP	C
	JR	NZ,pch19e1
;высадка
	PUSH	BC
	RES	7,(IX+y)
	RES	7,(IX-3)
;найти позицию от HL
	CALL	stayON
	CALL	IX0_HL
	PUSH	HL
	XOR	A
	CALL	NEWix_
	POP	HL
	CALL	GMAP2
	POP	BC
	LD	A,B
	ADD	A,#80
	LD	(HL),A
	CALL	IX_stop
pch19e1	POP	HL
	LD	DE,_LHER
	ADD	IX,DE
	INC	B
	LD	A,B
	CP	_NALL
	JR	C,pch19e0
pch19b	POP	HL
	POP	BC
	DJNZ	pch19a
	JP	EVENT

pcH69 ;закл69 (огн.кольцо/утроение)
	LD	C,33
	JR	pcH68a
;
pcH68 ;взрыв камикадзе
	LD	C,32
pcH68a	LD	A,(MASTER)
	OR	A
	JR	Z,pch68h
	INC	C
	INC	C
	INC	C
pch68h	LD	HL,SEL_T
	LD	B,(HL)
pch68b	INC	HL
	PUSH	HL
	LD	A,(HL)
	CALL	N_IX
	CALL	IX_stop
	LD	(IX+com),C
pch68c	POP	HL
	DJNZ	pch68b
	RET


pcH76 ;отправь самолёты на ремонт
	LD	A,(SEL_N)
	CALL	N_IX
	CALL	HL_IX0
;поиск ближ. авиапорт (к первому в группе)
	LD	BC,#20FF ;C=миним расст
	LD	DE,8
	LD	IX,HBUILD
;;LD A,(SIDE_N)
;;OR A
;;JR Z,asb0
;;LD IX,KBUILD
asb0	LD	A,(IX+2)
;это авиапорт?
	CP	3
	JR	Z,asb1
asb4	CP	3+8
	JR	NZ,asb2
;расст меньше минимального?
asb1	LD	A,(IX+x)
	OR	A
	JR	Z,asb2
	PUSH	BC
	CALL	DIST2
	POP	BC
	CP	C
	JR	NC,asb2
	LD	C,A
	EXX
	CALL	HL_IX0
	EXX
asb2	ADD	IX,DE
	DJNZ	asb0
	LD	A,C
	CP	#FF
	RET	Z ;некуда
;лететь к а-порту
	LD	HL,SEL_T
	LD	B,(HL)
pch76a	INC	HL
	PUSH	HL
	LD	A,(HL)
	CALL	N_IX
	POP	HL
	EXX
	CALL	IXt_HL
	EXX
	CALL	IX_mov
; ---- v0.04: changed/new code or data
	CALL	Aspeed0
	DJNZ	pch76a
	RET

;---кнопки зданий--------------

nMN_WD ;дать сообщ, если нехв ресурсов
;вх:A=0/1
	LD	A,43
	CALL	dirTX
	LD	A,29
	JP	SOUNDX


prcBLT ;C-k.typ
	LD	A,C
	CP	44
	JR	Z,pCB4
	CP	30
	JR	C,pCB4
	CP	50
	JR	NC,pCB4
;для ПР-ВА юнитов проверить наличе пищи (4*N+1)
	PUSH	BC
	CALL	oNUMh ;едоки->C
	PUSH	BC
	CALL	oHOMh ;пища->A
	POP	BC
	INC	C
	CP	C
	POP	BC
	JR	NC,pCB4
	LD	A,40 ;"нет пищи!"
	CALL	dirTX
	LD	A,33
	JP	SOUNDX
;
pCB4	PUSH	BC ;проверить наличие средств
	LD	A,(N_FUNC)
	CALL	GETmw
	CALL	dMN_WD
	POP	BC
	JP	C,nMN_WD
	CALL	EVENT
	LD	A,(SEL_N)
	CALL	B_IX
	LD	A,C
	CP	2
	JR	Z,pCstop
pCB0	CP	30
	JR	C,pCB7
;люди/заклинания
	CP	50
	JR	C,pCB8
	SUB	67-30-20
	JP	C,NOlamp
pCB8	SUB	30
	LD	(IX+4),A
	LD	HL,hcTIME
	CALL	BA
	JR	pcB10
pCB7	SUB	22
	JP	C,NOlamp
	ADD	A,26
	LD	(IX+4),A
	LD	A,hcTUPG
pcB10 ;начать пр-во/иссл
	LD	(IX+5),A
	RET
pCstop ;кнопка останова (2)
	LD	A,(IX+4)
	CP	#80
	JR	NC,pCBr
;прекр.разработку
	LD	(IX+4),255
	RET
;уничт.здание
pCBr	LD	(IX+3),0
	RET


