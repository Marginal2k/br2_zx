;------ПЕРЕМЕЩЕНИЯ
;---------п/п перемещения и поиска маршрута c использованием
;---------оптимизации через удалённую точку

;DIR,DIR_F,DIR_A,DIRF8,DIRF16 used in BR2

DIR ;напр HL->DE
	LD	A,L
	CP	E
	LD	A,H
	JR	C,di1
	JR	NZ,di2
	CP	D
	LD	A,0
	RET	C
	LD	A,4
;//	RET NZ
;//	LD A,#FF
	RET
di1	CP	D
	LD	A,1
	RET	C
	LD	A,3
	RET	NZ
	DEC	A
	RET
di2	CP	D
	LD	A,7
	RET	C
	LD	A,5
	RET	NZ
	INC	A
	RET

	MACRO	RND_  ;псевдослучайная ф-ция выбора направления
;LD A,R;/вариант1
	LD	A,(HL) ;/новый_варинат2
	ENDM

DIR_F ;напр HL->DE  с учётом наклона
	PUSH	HL
	LD	A,L
	SUB	E
	JR	C,df1
	JP	NZ,df2
	POP	HL
	LD	A,H
	CP	D
	LD	A,0
	RET	C
	LD	A,4
;//	RET NZ
;//	LD A,#FF
	RET
df1	NEG
	LD	L,A
	LD	A,H
	SUB	D
	LD	H,2
	JR	Z,df0
	JR	C,df11
	CP	L
	LD	H,3
	JR	Z,df0
	JR	NC,df12
	ADD	A,A ;--3|2
	CP	L
	POP	HL
	JR	C,df14
	RND_
	RRA
	LD	A,3
	RET	C
	DEC	A
	RET
df14	RND_
	AND	%11
	LD	A,3
	RET	Z
	DEC	A
	RET
df12	SLA	L ;--3|4
	CP	L
	POP	HL
	JR	NC,df15
	RND_
	RRA
	LD	A,3
	RET	C
	INC	A
	RET
df15	RND_
	AND	%11
	LD	A,3
	RET	Z
	INC	A
	RET
df11	NEG
	CP	L
	LD	H,1
	JR	Z,df0
	JR	NC,df32
	ADD	A,A ;--1|2
	CP	L
	POP	HL
	JR	C,df34
	RND_
	RRA
	LD	A,1
	RET	C
	INC	A
	RET
df34	RND_
	AND	%11
	LD	A,1
	RET	Z
	INC	A
	RET
df32	SLA	L ;--1|0
	CP	L
	POP	HL
	JR	NC,df35
	RND_
	RRA
	LD	A,1
	RET	C
	XOR	A
	RET
df35	RND_
	AND	%11
	LD	A,1
	RET	Z
	XOR	A
	RET
df0	LD	A,H
	POP	HL
	RET
df2	LD	L,A
	LD	A,H
	SUB	D
	LD	H,6
	JR	Z,df0
	JR	C,df21
	CP	L
	LD	H,5
	JR	Z,df0
	JR	NC,df22
	ADD	A,A ;--5|6
	CP	L
	POP	HL
	JR	C,df24
	RND_
	RRA
	LD	A,5
	RET	C
	INC	A
	RET
df24	RND_
	AND	%11
	LD	A,5
	RET	Z
	INC	A
	RET
df22	SLA	L ;--5|4
	CP	L
	POP	HL
	JR	NC,df25
	RND_
	RRA
	LD	A,5
	RET	C
	DEC	A
	RET
df25	RND_
	AND	%11
	LD	A,5
	RET	Z
	DEC	A
	RET
df21	NEG
	CP	L
	LD	H,7
	JR	Z,df0
	JR	NC,df42
	ADD	A,A ;--7|6
	CP	L
	POP	HL
	JR	C,df44
	RND_
	RRA
	LD	A,7
	RET	C
	DEC	A
	RET
df44	RND_
	AND	%11
	LD	A,7
	RET	Z
	DEC	A
	RET
df42	SLA	L ;--7|0
	CP	L
	POP	HL
	JR	NC,df45
	RND_
	RRA
	LD	A,7
	RET	C
	XOR	A
	RET
df45	RND_
	AND	%11
	LD	A,7
	RET	Z
	XOR	A
	RET
; ---- v0.04: changed/new code or data
	LD	A,L
	SUB	(IX+#0A)
	JR	NC,.df45_1
	NEG
.df45_1
	LD	B,A
	LD	A,H
	SUB	(IX+#0B)
	JR	NC,.df45_2
	NEG
.df45_2
	CP	B
	RET	NC
	LD	A,B
	RET

;--------------------

MAKE_X ;универсальный выбор направления обхода
;Вх:hl,(ix+0,1) -start, (ss_dir)-нач.напр,
;  (ix+10,11)-цель
	CALL	HL_IX0
	PUSH	HL
	LD	A,L ; вхHL-XY, выхHL-pos in map
	RLCA
	RLCA
	SRL	H
	RRA
	SRL	H
	RRA
	LD	E,A
	LD	A,H
	ADD	A,MAP2/256
	LD	D,A
	LD	B,8 ;нач поз окружена?
MKstr	LD	HL,inMAP ;выровн
	LD	A,B
	DEC	A
	ADD	A,A
	ADD	A,L
	LD	L,A
	LD	A,(HL)
	INC	L
	LD	H,(HL)
	LD	L,A
	ADD	HL,DE
	LD	A,(HL)
	OR	A ;пров на прох
	JR	Z,MKst0
	DJNZ	MKstr
	LD	B,8 ;есть ли рядом движущиеся?
MKany	LD	HL,inMAP ;выровн
	LD	A,B
	DEC	A
	ADD	A,A
	ADD	A,L
	LD	L,A
	LD	A,(HL)
	INC	L
	LD	H,(HL)
	LD	L,A
	ADD	HL,DE
	LD	A,(HL)
	CP	#80 ;пров движ обj рядом
	JR	C,MKan1
	CALL	GO_NXe
	JR	NZ,MKst0
MKan1	DJNZ	MKany
	POP	HL
	XOR	A
	LD	(MINLEN),A
	RET ;вых - поз окружена - стоп
MKst0	POP	HL
	LD	A,(DE)
	LD	(ss_num),A
	LD	(ss_pos),DE
	XOR	A
	LD	(DE),A
	LD	(MINLEN),A
	CALL	df45+8
	LD	(MINDIS),A
	PUSH	HL
	PUSH	DE
	EXX
	LD	A,(ss_dir)
	LD	C,A
	BIT	0,A
	JR	NZ,Mk1
	DEC	C
	INC	A
Mk1	DEC	C
	INC	A
	POP	DE
	POP	HL
	EXX
	LD	C,A
;HL-коорд DE-адр C-cdir/exx-против часовой
	LD	A,1
	EX	AF,AF' ;A'-текущ. длина обхода
MkLOOP ;обх в 2 стороны
Mk_cw	BIT	0,C
	JR	Z,Mk7
	DEC	C
Mk7	DEC	C
	PUSH	HL
CWrep	LD	HL,inMAP ; (выровн)
	LD	A,C
	AND	7
	LD	C,A
	ADD	A,A
	ADD	A,L
	LD	L,A
	LD	A,(HL)
	INC	L
	LD	H,(HL)
	LD	L,A
	ADD	HL,DE
	LD	A,(HL)
	CP	1 ;пров на прох
	JR	C,Mk4
	JP	Z,CWstop
	RLCA
	JR	NC,Mk4n
	CALL	Mk_her
	JR	C,Mk4
Mk4n	INC	C
	JR	CWrep
Mk4	EX	(SP),HL
	LD	DE,GO_Ntb
	LD	A,C
	ADD	A,A
	ADD	A,E
	LD	E,A
	LD	A,(DE)
	ADD	A,L
	LD	L,A
	INC	DE
	LD	A,(DE)
	ADD	A,H
	LD	H,A
	POP	DE
	EXX
	CP	H
	EXX
	JR	NZ,Mk5
	EXX
	LD	A,L
	EXX
	CP	L
	JR	NZ,Mk5
;узкий проход?
	LD	A,(MINLEN)
	OR	A
	JP	NZ,MK_RET
;или цель внутри препятствия?
	LD	A,C
	EXX
	SUB	C
	EXX
	INC	A ;-1,0,1,2 - продолжать
	INC	A
	AND	7
	CP	4
	JP	NC,MK_RET
Mk5	CALL	df45+8
	LD	B,A
	LD	A,(MINDIS)
	CP	B
	JR	C,Mk_ccw
	JR	Z,Mk_ccw
	LD	A,B
	LD	(MINDIS),A
	EX	AF,AF'
	LD	(MINLEN),A
	EX	AF,AF'
	XOR	A
	LD	(NROUND),A
Mk_ccw	EXX
	BIT	0,C
	JR	Z,M1k7
	INC	C
M1k7	INC	C
	PUSH	HL
CCWrep	LD	HL,inMAP ;/(выровн)
	LD	A,C
	AND	7
	LD	C,A
	ADD	A,A
	ADD	A,L
	LD	L,A
	LD	A,(HL)
	INC	L
	LD	H,(HL)
	LD	L,A
	ADD	HL,DE
	LD	A,(HL)
	CP	1 ;пров на прох
	JR	C,M1k4
	JP	Z,CCWstp
	RLCA
	JR	NC,M1k4n
	CALL	Mk_her
	JR	C,M1k4
M1k4n	DEC	C
	JR	CCWrep
M1k4	EX	(SP),HL
	LD	DE,GO_Ntb
	LD	A,C
	ADD	A,A
	ADD	A,E
	LD	E,A
	LD	A,(DE)
	ADD	A,L
	LD	L,A
	INC	DE
	LD	A,(DE)
	ADD	A,H
	LD	H,A
	POP	DE
	EXX
	CP	H
	JR	NZ,M1k5
	EXX
	LD	A,L
	EXX
	CP	L
	JR	NZ,M1k5
;узкий проход?
	LD	A,(MINLEN)
	OR	A
	JP	NZ,MK_RET
;или цель внутри препятствия?
	LD	A,C
	EXX
	SUB	C
	EXX
	INC	A ;-2,-1,0,1 - продолжать
	AND	7
	CP	4
	JP	NC,MK_RET
M1k5	EXX
	CALL	df45+8
	LD	B,A
	LD	A,(MINDIS)
	CP	B
	JR	C,Mk_eol
	JR	Z,Mk_eol
	LD	A,B
	LD	(MINDIS),A
	EX	AF,AF'
	LD	(MINLEN),A
	EX	AF,AF'
	LD	A,#80
	LD	(NROUND),A
Mk_eol	EXX
	EX	AF,AF'
	INC	A
	LD	B,A
	EX	AF,AF'
	LD	A,(DEEP)
	CP	B
	JP	NC,MkLOOP
MK_RET	LD	HL,(ss_pos)
	LD	A,(ss_num)
	LD	(HL),A
	RET ;вых MINLEN, NROUND
;/(MINLEN=0 - окружено(если NROUND=#FF)/нет дороги/далеко)

MK_REp	POP	HL
	JR	MK_RET

CWstop	POP	HL ;лев рука
	EXX
	EX	AF,AF'
	LD	B,A
	LD	A,(DEEP)
	ADD	A,A
	SUB	B
	LD	(DEEP_2),A
	LD	A,B
	EX	AF,AF'
MkLOO3	BIT	0,C
	JR	Z,M3k7
	INC	C
M3k7	INC	C
	PUSH	HL
CCWre1	LD	HL,inMAP ;выровн
	LD	A,C
	AND	7
	LD	C,A
	ADD	A,A
	ADD	A,L
	LD	L,A
	LD	A,(HL)
	INC	L
	LD	H,(HL)
	LD	L,A
	ADD	HL,DE
	LD	A,(HL)
	CP	1 ;пров на прох
	JR	C,M3k4
	JR	Z,MK_REp
	RLCA
	JR	NC,M3k4n
	CALL	Mk_her
	JR	C,M3k4
M3k4n	DEC	C
	JR	CCWre1
M3k4	EX	(SP),HL
	LD	DE,GO_Ntb
	LD	A,C
	ADD	A,A
	ADD	A,E
	LD	E,A
	LD	A,(DE)
	ADD	A,L
	LD	L,A
	INC	DE
	LD	A,(DE)
	ADD	A,H
	LD	H,A
	POP	DE
	CP	(IX+y)
	JR	NZ,M3kk
	LD	A,L
	CP	(IX+x)
	JP	Z,MK_RET
M3kk	CALL	df45+8
	LD	B,A
	LD	A,(MINDIS)
	CP	B
	JR	C,Mk_eo3
	JR	Z,Mk_eo3
	LD	A,B
	LD	(MINDIS),A
	EX	AF,AF'
	LD	(MINLEN),A
	EX	AF,AF'
	LD	A,#80
	LD	(NROUND),A
Mk_eo3	EX	AF,AF'
	INC	A
	LD	B,A
	EX	AF,AF'
	LD	A,(DEEP_2)
	CP	B
	JP	NC,MkLOO3
	JP	MK_RET
;
CCWstp	POP	HL ;прав рука
	EXX
	EX	AF,AF'
	LD	B,A
	LD	A,(DEEP)
	ADD	A,A
	SUB	B
	LD	(DEEP_2),A
	LD	A,B
	EX	AF,AF'
MkLOO2	BIT	0,C
	JR	Z,M2k7
	DEC	C
M2k7	DEC	C
	PUSH	HL
CWrep2	LD	HL,inMAP ;выровн
	LD	A,C
	AND	7
	LD	C,A
	ADD	A,A
	ADD	A,L
	LD	L,A
	LD	A,(HL)
	INC	L
	LD	H,(HL)
	LD	L,A
	ADD	HL,DE
	LD	A,(HL)
	CP	1 ;пров на прох
	JR	C,M2k4
	JP	Z,MK_REp
	RLCA
	JR	NC,M2k4n
	CALL	Mk_her
	JR	C,M2k4
M2k4n	INC	C
	JR	CWrep2
M2k4	EX	(SP),HL
	LD	DE,GO_Ntb
	LD	A,C
	ADD	A,A
	ADD	A,E
	LD	E,A
	LD	A,(DE)
	ADD	A,L
	LD	L,A
	INC	DE
	LD	A,(DE)
	ADD	A,H
	LD	H,A
	POP	DE
	CP	(IX+y)
	JR	NZ,M2kk
	LD	A,L
	CP	(IX+x)
	JP	Z,MK_RET
M2kk	CALL	df45+8
	LD	B,A
	LD	A,(MINDIS)
	CP	B
	JR	C,Mk_eo2
	JR	Z,Mk_eo2
	LD	A,B
	LD	(MINDIS),A
	EX	AF,AF'
	LD	(MINLEN),A
	EX	AF,AF'
	XOR	A
	LD	(NROUND),A
Mk_eo2	EX	AF,AF'
	INC	A
	LD	B,A
	EX	AF,AF'
	LD	A,(DEEP_2)
	CP	B
	JR	NC,MkLOO2
	JP	MK_RET

Mk_her ;препятствие - герой
;/(CF: чужаки/движущиеся - прозрачны для трассировки)
	RRCA
	PUSH	AF
	PUSH	HL
	PUSH	IX
	AND	#7F
	CALL	N_IX
	LD	A,(IX+move)
	POP	IX
	POP	HL
	OR	A
	JR	Z,Mk_h2 ;/00
	INC	A
	JR	Z,Mk_h2 ;/FF
	POP	AF ;движущийся прозрачен
	SCF
	RET
Mk_h2	EX	AF,AF'
	CALL	MkeDIS ;миним дальность-1 на которой враг не проходим
	JR	C,Mk_h3
	EX	AF,AF'
	LD	A,(SIDE_N)
	OR	A
	JR	NZ,Mk_h1
	POP	AF
	SUB	#B0
	CP	#30
	RET ;враг прозрачен
Mk_h1	POP	AF
	SUB	#80
	CP	#30
	RET ;наш прозрачен
Mk_h3	EX	AF,AF' ;противник близко (непрозрачен)
	POP	AF
	XOR	A
	RET

;-----процедуры поиска удалённой точки


SEARCM ;search_max() //===Оценочное перемещение юнита======
	XOR	A
	LD	(srcTYP),A ;нормальный поиск
SEARC1 ;---//луч свободного перемещения (вх:none)
	XOR	A
	LD	(MkeDIS+1),A ;все герои проходимы
	CALL	HL_IX0
	EX	DE,HL
	CALL	HL_IXt
	LD	(srcIXt),HL

src101	EX	DE,HL
	OR	A
	PUSH	HL
	LD	DE,(srcIXt)
	SBC	HL,DE
	POP	HL
	JP	Z,srR000 ;прямо к цели
	CALL	DIR_F
	LD	C,A
	CALL	GO_NXT
	JP	C,src101 ;(возможно ограничить макс длину луча)
src102	BIT	7,A ;препятствие
	JR	NZ,src101
	EX	DE,HL

SEARC2 ;---//предварительная трассировка (вх: c-dir,DE-xy)
	LD	A,C
	LD	(ss_dir),A
	CALL	HL_IX0
	PUSH	HL
	PUSH	DE
	CALL	GMAP2 ;сделать самого героя проходимым при трассировке
	LD	A,(HL)
	LD	(s2_num),A
	LD	(s2_pos),HL
	EX	DE,HL
	CALL	IX0_HL
	CALL	MAKE_X ;//вызов трассировщика
	LD	A,(s2_num)
	LD	HL,(s2_pos)
	LD	(HL),A
	POP	DE
	POP	HL
	CALL	IX0_HL
	EX	DE,HL
;
	LD	A,(MINLEN)
	LD	C,A
	OR	A
	JP	Z,srR000
	LD	A,(NROUND)
	LD	B,A
	OR	A
	LD	A,(ss_dir)
	JR	NZ,src203
	INC	A
	BIT	0,A
	JR	Z,src204
	INC	A
	JR	src204
src203	DEC	A
	BIT	0,A
	JR	Z,src204
	DEC	A
src204	AND	7
	LD	(ss_dir),A
	EX	AF,AF'
	LD	A,C
	OR	B
	LD	C,A

SEARC3 ;---//предварительный поиск наиболее удалённой точки
;/(вх: HL - xy, (ss_dir)/A' - dir, C,A=NROUND|MINLEN)
	LD	(MAXSRC),A
	EX	AF,AF'
	LD	(MAXDIR),A
	XOR	A
	LD	(MAXTRU),A
	CALL	df45+8
	EXX
	LD	HL,MAXDIS
	LD	(HL),A
	EXX
	LD	(MAXPOS),HL

;A'-xr_len, (HL')-max_dist,
;HL-pos, DE-nextpos, C-old_dir, A-dir

	LD	A,C
	CP	#80
	LD	A,(ss_dir)
	LD	C,#FF ;C=old_dir
	JR	NC,sc_CCW
;
sr_CW ;/////////обход пo часовой
	EX	AF,AF'
;
sr_re0	EX	AF,AF' ;/цикл обхода
	DEC	A
	AND	7
	BIT	0,A
	JR	NZ,sr_re1
	DEC	A
sr_re1 ;//выбрать новое направление
	AND	7
	LD	B,A
	CALL	GO_NXT
	JR	C,srx3
	BIT	7,A
	JR	NZ,srx3
sr_re5	LD	A,B
	INC	A ;rot_dir=+1
	JR	sr_re1
;
srx3 ;//поиск зациклен?
	LD	A,L
	CP	(IX+x)
	JR	NZ,srx31
	LD	A,H
	CP	(IX+y)
	JR	NZ,srx31
	LD	A,B
	CP	(IX+dir)
	JR	NZ,srx31
	LD	A,C
	CP	#FF
	JP	NZ,srRET1 ;//зациклен
;
srx31	PUSH	BC ;B=dir
	CALL	df45+8
	EXX
	CP	(HL)
	EXX
	JR	C,srx4
	JR	Z,srx4
;//найдена новая удалённая точка
	EXX
	LD	(HL),A ;max_dist
	EXX
	LD	(MAXPOS),HL ;maxx,maxy
	LD	A,C
	LD	(MAXDIR),A ;maxdir
	EX	AF,AF'
	LD	(MAXSRC),A
	EX	AF,AF'
;//это ложная точка?
	POP	AF
	PUSH	AF
	SUB	C
	DEC	A
	AND	7
	CP	5-1
	LD	A,0
	JR	C,srxF
	INC	A
srxF	LD	(MAXTRU),A
;
srx4	EX	DE,HL
	POP	AF
	LD	C,A
	EX	AF,AF'
	DEC	A
	JR	NZ,sr_re0
	JR	srSOLV

sc_CCW ;//////////обход против часовой
	EX	AF,AF'
;
sc_re0	EX	AF,AF' ;/цикл обхода
	INC	A
	AND	7
	BIT	0,A
	JR	NZ,sc_re1
	INC	A
sc_re1 ;//выбрать новое направление
	AND	7
	LD	B,A
	CALL	GO_NXT
	JR	C,scx3
	BIT	7,A
	JR	NZ,scx3
sc_re5	LD	A,B
	DEC	A ;rot_dir=-1
	JR	sc_re1
;
scx3 ;//поиск зациклен?
	LD	A,L
	CP	(IX+x)
	JR	NZ,scx31
	LD	A,H
	CP	(IX+y)
	JR	NZ,scx31
	LD	A,B
	CP	(IX+dir)
	JR	NZ,scx31
	LD	A,C ;нач точка - не в счёт
	CP	#FF
	JP	NZ,srRET1 ;//зациклен
;
scx31	PUSH	BC ;B=dir
	CALL	df45+8
	EXX
	CP	(HL)
	EXX
	JR	C,scx4
	JR	Z,scx4
;//найдена новая удалённая точка
	EXX
	LD	(HL),A ;max_dist
	EXX
	LD	(MAXPOS),HL ;maxx,maxy
	LD	A,C
	LD	(MAXDIR),A ;maxdir
	EX	AF,AF'
	LD	(MAXSRC),A
	EX	AF,AF'
;//это ложная точка?
	POP	AF
	PUSH	AF
	SUB	C
	AND	7
	CP	4
	LD	A,0
	JR	NC,scxF
	INC	A
scxF	LD	(MAXTRU),A
;
scx4	EX	DE,HL
	POP	AF
	LD	C,A
	EX	AF,AF'
	DEC	A
	CP	#80
	JR	NZ,sc_re0

srSOLV ;/////принятие решений
	LD	A,(srcTYP)
	OR	A
	JR	NZ,srR000
	LD	HL,(MAXPOS)
	LD	A,L
	CP	(IX+x)
	JR	NZ,srSL1
	LD	A,H
	CP	(IX+y)
;//нормальный обход
	JR	Z,srR000
srSL1	LD	A,(MAXTRU)
	OR	A
	JR	Z,srR000
M_LOCK ;move lock - //включить перемещение к удалённой точке
	LD	A,(IX+tarX) ;tarX
	LD	(IX+16),A
	LD	A,(IX+tarY) ;tarY
	LD	(IX+17),A
	LD	A,(MAXDIR) ;dir+try
	ADD	A,maxtry*16
	LD	(IX+18),A
	LD	A,(MAXSRC)
	LD	(IX+19),A ;len
	CALL	IXt_HL ;new_tarXY, _ON_
;
srR000	XOR	A ;//ret=0
	JR	srRETU
srRET1	LD	A,1 ;//ret=1
srRETU	PUSH	AF
	LD	A,4
	LD	(MkeDIS+1),A ;восстановить радиус прох.героев
	POP	AF
	RET

maxtry	EQU	5 ;макс число попыток срезать (до 15)

M_UNLK ;move unlock - включить нормальное перемещение
	LD	A,(IX+16) ;tarX
	LD	(IX+tarX),A
	LD	A,(IX+17) ;tarY
	LD	(IX+tarY),A
	LD	A,(IX+18) ;dir
	AND	7
	LD	(IX+dir),A
	LD	A,(IX+19) ;len
	LD	(IX+move),A
	LD	(IX+16),#FF ;_OFF_
	JR	GO_MAN

;----- иниц обхода после старта

INI_GO	LD	A,(IX+16)
	CP	#FE ;init?
	RET	NZ
;ini
	POP	AF ;!
	INC	(IX+16)
	JP	SEARCM

;-----обычный поиск обхода------------------

MAKE_R	LD	A,(IX+dir)
	LD	(ss_dir),A
	CALL	MAKE_X ;make_round - выбор направления обхода
	LD	A,(MINLEN)
	OR	A
	JP	NZ,Mkr1
	LD	A,(IX+move) ;обхода нет или слишком далеко
	OR	A
	JP	NZ,G_stop
	JP	G_free ;(?)если остановка при ложном обходе
Mkr1	CP	126
	JR	C,Mkr2
	LD	A,126
Mkr2	LD	B,A
	LD	A,(IX+move)
	OR	A
	JR	NZ,Mkr2a
	LD	B,1
Mkr2a ;^если (IX+move)==0, уменьшить длину прохода до 1 (против ложного обхода)
	LD	A,(NROUND)
	LD	C,A
	OR	B
	LD	(IX+move),A
	LD	A,C
	OR	A
	LD	A,(IX+dir)
	JR	NZ,Mkr3
	INC	A
	BIT	0,A
	JR	Z,Mkr4
	INC	A
	JR	Mkr4
Mkr3	DEC	A
	BIT	0,A
	JR	Z,Mkr4
	DEC	A
Mkr4	AND	7
	LD	(IX+dir),A
;;;JR GO_MAN
;
GO_MAN ;перемещение сухопутных сил
	LD	A,(IX+move)
	OR	A
	RET	Z
	CALL	HL_IXt
	EX	DE,HL
	CALL	HL_IX0
	PUSH	HL
	SBC	HL,DE
	POP	HL
	JP	Z,G_stop ;пришли к цели - стоп
	CP	#80
	JR	C,GO_CW
	JP	NZ,GO_CCW
;cвободное перемещение
	CALL	INI_GO
	CALL	DIR_F
	LD	C,A
	CALL	GO_NXT
	JR	C,GO_rot
	LD	(IX+dir),C
	BIT	7,A
	JP	Z,MAKE_R
	CALL	GO_NXe
	JP	Z,MAKE_R
	LD	(IX+move),0 ;против ложного обхода
	JP	MAKE_R
;
GO_rot	LD	A,C ;повернуться по напр движ
	SUB	(IX+dir)
	AND	7
	JR	Z,go_nr0
	CP	4
	JR	C,go_nr1
	CP	7
	JR	Z,go_nr0
	LD	A,(IX+dir)
	DEC	A
	JR	go_nr3
go_nr2	LD	A,(IX+dir)
	INC	A
go_nr3	AND	7
	LD	(IX+dir),A
	RET ;ждём разворота
go_nr1	DEC	A
	JR	NZ,go_nr2
go_nr0	LD	(IX+dir),C
	JP	GO_go
;
GO_CW ;обход по часовой
	DEC	(IX+move)
	CALL	DIR ;в DE - XYt
	LD	B,A ;B=dirT/#FF флаг совпадения направления (gofree)
	LD	C,1 ;rot_dir
	LD	A,(IX+dir)
	DEC	A
	AND	7
	BIT	0,A
	JR	NZ,GO_rep
	CP	B ;напр совпало?
	JR	NZ,go_cw1
	LD	B,#FF
go_cw1	DEC	A
	PUSH	AF ;против закручивания
	DEC	A
	AND	7
	CALL	GO_NXT
	JR	NC,GO_re2
	LD	A,(IX+move)
	CP	#80
	JR	Z,GO_re2
	CP	#02
	JR	C,GO_re2
	LD	(IX+move),#01
	JR	GO_re2
;
GO_CCW ;обход против часовой
	DEC	(IX+move)
	CALL	DIR ;в DE - XYt
	LD	B,A ;B=dirT/#FF флаг совпадения направления (gofree)
	LD	C,-1
	LD	A,(IX+dir)
	INC	A
	BIT	0,A
	JR	NZ,GO_rep
	CP	B ;напр совпало?
	JR	NZ,go_cc1
	LD	B,#FF
go_cc1	INC	A
	PUSH	AF ;против закручивания
	INC	A
	AND	7
	CALL	GO_NXT
	JR	NC,GO_re2
	LD	A,(IX+move)
	CP	#82
	JR	C,GO_re2
	LD	(IX+move),#81
GO_re2	POP	AF
;
GO_rep	PUSH	BC ;выбрать новое направление
	LD	B,8
GO_re1	AND	7
	LD	(IX+dir),A
	CALL	GO_NXT
	JR	C,Gx3
	BIT	7,A
	JR	Z,G_re5
	CALL	GO_NXe ;против заторов
	JR	Z,G_re5
	LD	A,B
	CP	8 ;?7
	JR	NC,G_re5a
	LD	A,R ;для b=6..1
	AND	#15 ;вероятность 1/8
	JR	NZ,G_reX
G_re5a	LD	(IX+move),#80 ;для b=7..8
G_re5	LD	A,(IX+dir)
	ADD	A,C
	DJNZ	GO_re1
	POP	BC
	JR	G_wait ;! временно заперт - ждать
G_reX	POP	BC
	LD	A,(IX+move)
	AND	#80
	INC	A
	LD	(IX+move),A
	RET
;
Gx3	POP	AF ;A=B
	CP	(IX+dir)
	JR	Z,GxFr
	CP	#FF
GxFr	PUSH	DE
	CALL	Z,GZfree ;направление совпало - срезать путь
	POP	DE
	CALL	GO_go
	LD	A,(IX+move)
	AND	#7F ;конец обхода
	RET	NZ
;
GXfree ;//обход окончен - новая оценка
	BIT	7,(IX+16) ;если (ix+16)<>#ff
	CALL	NZ,SEARCM
G_free	LD	(IX+move),#80 ;своб. перемещ
	RET

GZfree ;//попытка срезать
	BIT	7,(IX+16) ;если (ix+16)<>#ff
	JR	Z,Gzfr01
	CALL	SEARCM ;при норм обходе
	CP	1
	JR	NZ,G_free
	RET
Gzfr01	LD	A,1
	LD	(srcTYP),A
	CALL	SEARC1 ;при уд обходе
	CP	1
	RET	Z ;обход зациклен
	LD	A,(IX+18)
	SUB	%00010000
	RET	C ;нет попыток
	LD	(IX+18),A
	JR	G_free

G_wait ;ждать прохода
	LD	(IX+phase_),#80+6 ;величина ожидания
	JR	G_free

G_stop	BIT	7,(IX+16) ;если (ix+16)<>#ff
	JP	Z,M_UNLK ;пришли к уд.точке - продолжаем
	XOR	A ;СТОП
	LD	(IX+move),A
	RET


GO_NXT ;Вх:HL-исх точка, А-напр
;Вых: DE-след точка, NC/C - непрох/прох
	PUSH	HL
	LD	DE,GO_Ntb
	ADD	A,A
	ADD	A,E
	LD	E,A
	LD	A,(DE)
	ADD	A,L
	LD	L,A
	INC	DE
	LD	A,(DE)
	ADD	A,H
	LD	H,A
	LD	D,H
	LD	E,L
	LD	A,L
	RLCA
	RLCA
	SRL	H
	RRA
	SRL	H
	RRA
	LD	L,A
	LD	A,H
	ADD	A,MAP2/256
	LD	H,A
	LD	A,(HL) ;проработать!
	POP	HL
	CP	1
	RET

GO_NXe ;против заторов
	AND	#7F
	PUSH	IX ;впереди герой
	PUSH	HL
	CALL	N_IX
	LD	A,(IX+move)
	POP	HL
	POP	IX
	OR	A
	RET	Z ;он стоит/00
	INC	A
	RET ;/Z ;он стоит/FF  /NZ-двигается


GO_go ; ВПЕРЁД
go_IX3 ;------задать нач знач фазы IX+3  (вх: DE - следущ XY)
	CALL	HL_IX0 ;сместить ук в map2 (в DE)
	CALL	GMAP2
	LD	C,(HL)
	LD	(HL),0
	EX	DE,HL
	CALL	IX0_HL
	CALL	GMAP2
	LD	(HL),C
	LD	HL,DfSTACK+24 ;(был DEFB #21,#6E,#75: адрес без метки)
	LD	A,(IX+dir)
	RRCA
	JR	NC,gX0
	LD	HL,HvTDs ;diag
gX0	LD	A,(IX+typ)
	CALL	BA
	LD	C,8
	CP	2
	JR	Z,gX1
	LD	C,16
	JR	C,gX1
	CP	3
	LD	C,6
	JR	Z,gX1
	LD	C,4
gX1	LD	(IX+3),C
	LD	C,A
	LD	A,(IX+speed)
	AND	%11111000
	OR	C
	LD	(IX+speed),A
	RET



;-----герои ходят и дерутся ----------------------------------
TimIMP ;задержка удара (-1 - нет фазы)
	DEFB	1,-1,-1,-1,-1,-1,-1,1,1,-1,-1,-1
	DEFB	1,-1,-1,-1,1,1,2,1,1,-1,-1,-1

TimDEL ;задержка после удара
	DEFB	1,1,1,1,3,1,2,1,1,25,+5,1
	DEFB	1,1,1,1,1,2,2,1,1,+20,+5,1

HvA ; %1ibttttt //начать удар/выстрел = %11000000
	JR	NZ,HvAA
	LD	(IX+phase_),0 ;конец удара
	RET
HvAA	LD	L,A
	AND	%11111
	JR	Z,HvAim
	DEC	(IX+phase_) ;задержка
	RET
HvAim	BIT	6,L
	JR	Z,HvAdel
;
	LD	A,(IX+typ)
	LD	HL,TimIMP
	CALL	BA
	CP	255
	JR	C,HvAi1
	LD	HL,TimDEL ;без фазы удара
	LD	A,(IX+typ)
	CALL	BA
	ADD	A,%10000000
	LD	(IX+phase_),A
	JP	Hv_FX ;FX
;
HvAi1	ADD	A,%10100000 ;удар
	LD	(IX+phase_),A
	LD	A,(IX+dir)
	JR	HvA1
;
HvAdel	CALL	Hv_FX ;FX
	LD	A,(IX+typ)
	LD	HL,TimDEL
	CALL	BA
	ADD	A,%10000000 ;обратно
	LD	(IX+phase_),A
	LD	A,(IX+dir)
	ADD	A,4
	AND	7
HvA1	EX	AF,AF'
	LD	A,(IX+typ)
	OR	A
	RET	Z
	CP	18
	RET	Z
	EX	AF,AF'
	JP	Hv2_

HvT1	DEFW	0,1,1,1,1,0,1,-1
	DEFW	0,-1,-1,-1,-1,0,-1,1

HERMOV ;.LD A,(IX+phase) ;-----перемещение (п/п нижн. уровня)
;.OR A
;.RET Z
	CP	#80 ;в А IX+phase
	JP	NC,HvA ;в атаку
	BIT	5,(IX+speed)
	JR	Z,HvNoFRZ
;объект затоморожен?
	LD	L,A
	LD	A,(IX+speed)
	AND	%11110000
	CP	%00100000
	JR	NZ,HvNZ1
	LD	A,(TIC6)
	OR	A
	RET	NZ
HvNZ1	LD	A,L
HvNoFRZ	EX	AF,AF'
	DEC	(IX+phase_)
	LD	A,(IX+speed)
	AND	%111
	CP	2
	JR	Z,Hv2
	JP	C,Hv1
	CP	3
	JP	NZ,Hv4
	EX	AF,AF'
	CP	2
	JR	Z,Hv2
	CP	5
	JR	Z,Hv2
Hv3	LD	A,(IX+dir)
	LD	HL,HvT1
	CALL	DA
	INC	HL
	PUSH	HL
	LD	D,(HL)
	LD	E,A
	LD	L,(IX-4)
	LD	H,(IX-3)
	ADD	HL,DE
	ADD	HL,DE
	ADD	HL,DE
	LD	(IX-4),L
	LD	(IX-3),H
	POP	HL
	INC	HL
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	LD	L,(IX-2)
	LD	H,(IX-1)
	ADD	HL,DE
	ADD	HL,DE
	ADD	HL,DE
	LD	(IX-2),L
	LD	(IX-1),H
	RET
Hv2	LD	A,(IX+dir)
Hv2_	LD	HL,HvT1
	CALL	DA
	INC	HL
	PUSH	HL
	LD	D,(HL)
	LD	E,A
	LD	L,(IX-4)
	LD	H,(IX-3)
	ADD	HL,DE
	ADD	HL,DE
	LD	(IX-4),L
	LD	(IX-3),H
	POP	HL
	INC	HL
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	LD	L,(IX-2)
	LD	H,(IX-1)
	ADD	HL,DE
	ADD	HL,DE
	LD	(IX-2),L
	LD	(IX-1),H
	RET
Hv1	LD	A,(IX+typ)
	CP	18 ; ланголетта - очень медленно
	JR	NZ,Hv1a
	LD	A,(TIC)
	AND	3
	JR	Z,Hv1a
	INC	(IX+phase_)
	RET
Hv1a	LD	A,(IX+dir)
	LD	HL,HvT1
	CALL	DA
	INC	HL
	PUSH	HL
	LD	D,(HL)
	LD	E,A
	LD	L,(IX-4)
	LD	H,(IX-3)
	ADD	HL,DE
	LD	(IX-4),L
	LD	(IX-3),H
	POP	HL
	INC	HL
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	LD	L,(IX-2)
	LD	H,(IX-1)
	ADD	HL,DE
	LD	(IX-2),L
	LD	(IX-1),H
	RET
Hv4	LD	A,(IX+dir)
	LD	HL,HvT1
	CALL	DA
	INC	HL
	PUSH	HL
	LD	D,(HL)
	LD	E,A
	LD	L,(IX-4)
	LD	H,(IX-3)
	ADD	HL,DE
	ADD	HL,DE
	ADD	HL,DE
	ADD	HL,DE
	LD	(IX-4),L
	LD	(IX-3),H
	POP	HL
	INC	HL
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	LD	L,(IX-2)
	LD	H,(IX-1)
	ADD	HL,DE
	ADD	HL,DE
	ADD	HL,DE
	ADD	HL,DE
	LD	(IX-2),L
	LD	(IX-1),H
	RET


