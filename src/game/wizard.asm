;--ИСПОЛНЕНИЕ ЗАКЛИНАНИЙ-------

;------ix+9---магия царей-------

stownT ;таблица расположения камней/огней по направлениям (X,Y)
	DEFB	-1,0,1,0,2,0,-2,0 ;Dir0
	DEFB	0,-1,-1,0,1,-1,-1,1 ;Dir1
	DEFB	0,-1,0,1,0,2,0,-2 ;Dir2
	DEFB	-1,0,0,1,-1,-1,1,1 ;Dir3
	DEFB	-1,0,1,0,2,0,-2,0 ;Dir4
	DEFB	0,1,1,0,-1,1,1,-1 ;Dir5
	DEFB	0,-1,0,1,0,2,0,-2 ;Dir6
	DEFB	1,0,0,-1,-1,-1,1,1 ;Dir7

ZZ14 ;пламенная стена
	LD	C,32
	JR	zz20x

ZZ20 ;каменная стена
	LD	C,33
;
zz20x	CALL	ZZdist8
	LD	A,(IX+energy)
	CP	MANA/5 ;нижний предел
; ---- v0.04: changed/new code or data
	JP	C,noMANA
;найти таблицу расположения
	PUSH	BC
	CALL	HL_IXtEX
	EX	DE,HL
	CALL	HL_IX0
	CALL	DIRF8
	ADD	A,A
	ADD	A,A
	ADD	A,A ;*8
	LD	HL,stownT
	CALL	BA
	POP	BC
;
	LD	DE,0
	LD	B,5
;
zz20L0	LD	A,(IX+energy) ;есть энергия?
	CP	MANA/5
; ---- v0.04: changed/new code or data
	JR	C,zz20L0+50
	PUSH	HL
	PUSH	DE
	PUSH	BC
;новые координаты
	CALL	HL_IXtEX
	LD	A,L
	ADD	A,E
	LD	E,A
	CP	63
; ---- v0.04: changed/new code or data
	JR	NC,zz20L0+41
	LD	A,H
	ADD	A,D
	LD	D,A
	CP	63
; ---- v0.04: changed/new code or data
	JR	NC,zz20L0+41
;поставь стену/пламя (Z-ok)
	LD	A,C
; ---- v0.04: code removed
	CALL	NEWBUL
; ---- v0.04: changed/new code or data
	JR	NZ,zz20L0+41
;уменьшить энерг
	LD	A,(IX+energy)
	SUB	MANA/5
	LD	(IX+energy),A
; ---- v0.04: changed/new code or data (4.Z80: zz20E1)
	POP	BC
	POP	DE
	POP	HL
;
zz20E1	; (в v0.04 код удалён, метка сохранена для ссылок)
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	INC	HL
; ---- v0.04: changed/new code or data
	DJNZ	zz20L0
	CALL	STARher
;
zz20E	JR	zz_EnV


ZZ13 ;\чёрное зрение
ZZ19 ;белое зрение
	CALL	HL_IXt
	PUSH	HL
	CALL	GMAP
	LD	A,(HL)
	POP	HL
	OR	A
	JP	Z,IX_stop ;на границе
	LD	C,MANA/2
	CALL	isMANA
	PUSH	HL
	CALL	ONSEEm
	POP	DE
	INC	E
;звёзды
	CALL	STARpos
	DEC	E
	DEC	E
	CALL	STARpos
	INC	E
	INC	D
	CALL	STARpos
	DEC	D
	DEC	D
	CALL	STARpos
	JR	zz_EnV

;----оконч. применения магии

zz_EnVi	PUSH	IY
	POP	IX ;конец действия на позицию
;
zz_EnV	CALL	HL_IXtEX
zz_End ;конец действия мага
	CALL	IX_stop
zz_En2 ;HL-напр колд
	EX	DE,HL
	CALL	HL_IX0
	CALL	DIR_F
	LD	(IX+dir),A
	JP	IMPIX3


;------магия волшебников

ZZ10 ;\дать здоровье людям
ZZ16 ;дать немного здоровья кунгам
	CALL	ZZdist8
	LD	A,(IX+energy)
	CP	MANA/8 ;нижний предел
; ---- v0.04: changed/new code or data
	JP	C,noMANA
;
	XOR	A
	CALL	zzMagLst
	PUSH	IX
	POP	IY
;величина энергии на лечение
	LD	E,2 ;hum
	LD	A,(IY+typ)
	CP	7
	JR	Z,zz16L0
	LD	E,3 ;kun
;
zz16L0	LD	A,(IY+energy) ;есть энергия?
	OR	A
	JR	Z,zz_EnVi
	LD	A,(HL)
	INC	L
	CP	#FF
	JR	Z,zz_EnVi
	PUSH	HL
	CALL	N_IX
;можно лечить?
	LD	A,(IX+typ)
	LD	B,A
	LD	HL,AT_TY2
	CALL	BA
	AND	medic
	JR	Z,zz16E
;здоров?
	LD	A,B
	LD	HL,HEALTH
	CALL	WA
	LD	C,A
	CP	(IX+health)
	JR	Z,zz16E
	LD	B,64 ;макс порция передачи здоровья
zz16He	LD	A,(IX+health)
	CP	C
	JR	NC,zz16sr
	LD	A,(IY+energy)
	SUB	E
	JR	C,zz16sr
;нехватило энергии
	LD	(IY+energy),A
zz16ok ;добавить здоровья
	INC	(IX+health)
	DJNZ	zz16He
;звёзды
zz16sr	PUSH	IY
	PUSH	DE
	CALL	STARher
	POP	DE
	POP	IY
;
zz16E	POP	HL
	JP	zz16L0
; ---- v0.04: code removed


ZZ12
	CALL	ZZdistX
	LD	A,(IX+energy)
	CP	MANA-1 ;нижний предел
; ---- v0.04: changed/new code or data
	JP	C,noMANA
;
	LD	A,1
	CALL	zzMagLst
	PUSH	IX
	POP	IY
;
zz12L0	LD	A,(IY+energy) ;есть энергия?
	CP	MANA-1
	JP	C,zz_EnVi
	LD	A,(HL)
	INC	L
	CP	#FF
	JP	Z,zz_EnVi
;
	PUSH	HL
	CALL	N_IX
;может быть превращён?
	LD	A,(IX+typ)
	LD	HL,AT_TY2
	CALL	BA
	AND	turn
; ---- v0.04: changed/new code or data
	JR	Z,zz12E
;убрать кунга (без трупа)
	CALL	HL_IX0
	PUSH	HL
; ---- v0.04: changed/new code or data
	LD	HL,#0000
	CALL	IX0_HL
	POP	HL
;поставить человека(3,4,7)
	LD	A,(TIC3)
	ADD	A,3
	CP	5
	JR	C,zz12s
	LD	A,7
zz12s	EX	AF,AF'
	LD	A,(SIDE_N)
	CALL	NEWHER
	PUSH	IY
	CALL	Z,STARher
	POP	IY
	LD	A,(IY+energy)
	SUB	MANA-1
	LD	(IY+energy),A
zz12E	POP	HL
	JP	zz12L0
; ---- v0.04: code removed


ZZ18
	CALL	ZZdistX
	LD	A,(IX+energy)
	CP	MANA/2 ;нижний предел
; ---- v0.04: changed/new code or data
	JP	C,noMANA
;
	LD	A,1
	CALL	zzTroLst
	PUSH	IX
	POP	IY
;
zz18L0	LD	A,(IY+energy) ;есть энергия?
	CP	MANA/2
	JP	C,zz_EnVi
	LD	A,(HL)
	INC	L
	CP	#FF
	JP	Z,zz_EnVi
;
	PUSH	HL
	CALL	N_IX
;может быть превращён?
	LD	A,(IX+oldtyp)
	CP	12
	JR	C,zz18E
	CP	21
	JR	NC,zz18E
	CP	15
	JR	NC,zz18s
	LD	A,12
zz18s ;убрать труп
	LD	HL,0
	CALL	IX0_HL
;поставить кунга(12,15..20)
	CALL	HL_IXt
	EX	AF,AF'
	CALL	stayON
	LD	A,(SIDE_N)
	CALL	NEWHER
	PUSH	IY
	CALL	Z,STARher
	POP	IY
	LD	A,(IY+energy)
	SUB	MANA/2
	LD	(IY+energy),A
zz18E	POP	HL
	JP	zz18L0


;----------долгосрочная магия


ZZ11 ;заморозка (тормоз)
	LD	L,46
	LD	A,1 ;на врага
; ---- v0.04: changed/new code or data (4.Z80: (дист))
	JR	ZZtimer
ZZ17 ;хрустальный шар (защита)
	LD	L,50
	XOR	A ;на своих
; ---- v0.04: changed/new code or data (4.Z80: (дист))
	JR	ZZtimer
ZZ15 ;AIDS (поедание здоровья - заразно)
	LD	L,48
	LD	A,1 ;на врага
; ---- v0.04: changed/new code or data (4.Z80: (дист))
	JR	ZZtimer
ZZ21 ;паника (потеря управления - заразно)
	LD	L,52
	LD	A,1 ;на врага
; ---- v0.04: code removed (4.Z80: (дист))
;;
ZZtimer	EX	AF,AF'
	LD	A,L
	LD	(zzXsub),A
	CALL	ZZdistX
	LD	A,(IX+energy)
	CP	MANA/2 ;нижний предел
; ---- v0.04: changed/new code or data
	JP	C,noMANA
;
	EX	AF,AF'
	CALL	zzMagLst
	PUSH	IX
	POP	IY
;
zzX_L0	LD	A,(IY+energy) ;есть энергия?
	CP	MANA/2
	JP	C,zz_EnVi
	LD	A,(HL)
	INC	L
	CP	#FF
	JP	Z,zz_EnVi
	PUSH	HL
	PUSH	IY
	LD	C,A
	CALL	N_IX
	LD	A,(zzXsub)
	CALL	NEWBUL
	POP	IY
	JR	NZ,zzX_E
	PUSH	IY
	CALL	STARher
	POP	IY
	LD	A,(IY+energy)
	SUB	MANA/2
	LD	(IY+energy),A
zzX_E	POP	HL
	JP	zzX_L0


;---------магия юнитов


ZZ31Len	EQU	8 ;макс.длина прыжка

ZZ31 ;прыжок
	CALL	HL_IXtEX ;опредление дистанции
	CALL	DIST2
	CP	2
	JP	C,ZZ2 ;близко
	CP	ZZ31Len+1
	JP	NC,ZZ2 ;далеко
	LD	C,MANA/2
	CALL	isMANA ;нет маны
	CALL	HL_IX0
; ---- v0.04: changed/new code or data
	EX	DE,HL
	CALL	STARpos
; ---- v0.04: changed/new code or data
	EX	DE,HL
	CALL	GMAP2
	LD	(HL),0
	CALL	HL_IXtEX
	CALL	stayON
	CALL	DIST2
	CP	ZZ31Len+2
	JR	C,zz31a
	CALL	HL_IX0 ;некуда прыгать
zz31a	CALL	IX0_HL
	PUSH	HL
	CALL	GMAP2
	LD	A,(HER_N)
	OR	#80
	LD	(HL),A
	POP	HL
	EX	DE,HL
	CALL	STARpos
	EX	DE,HL
	CALL	nH0
	JP	IX_stop

ZZ32 ;\камикадзе 68hum
ZZ35 ;68kun
	LD	C,MANA-1
	CALL	isMANA
	LD	A,14
	CALL	NEWBUL
; ---- v0.04: changed/new code or data
	LD	A,(HER_N)
ZZ35ki ;удалить без трупа
	CALL	deSEL
	CALL	HL_IX0
; ---- v0.04: code removed
	CALL	GMAP2
; ---- v0.04: code removed
	XOR	A
	LD	(HL),A
	LD	L,A
	LD	H,A
	CALL	IX0_HL
	JP	EVENTr
; ---- v0.04: changed/new code or data
ZZ36
	LD	C,#1E

	CALL	isMANA
	LD	B,(IX+energy)
	LD	(IX+energy),0
	LD	A,(HER_N)
	LD	C,A
	LD	A,44
	CALL	NEWBUL
	JP	IX_stop

ZZ33 ;растроение 69kun
	LD	C,MANA-1
	CALL	isMANA
	LD	BC,#303
	LD	HL,ZZ33gn
	LD	A,(HL)
	RRCA
	JR	C,ZZ33b
	DEC	B
	INC	C
ZZ33b	LD	A,R
	LD	(HL),A
;родить 3_десант|2_огнемётч
ZZ33a	PUSH	BC
	PUSH	IX
	LD	A,C
	EX	AF,AF'
	CALL	HL_IX0
	CALL	stayON
	LD	A,(SIDE_N)
	CALL	NEWHER
	CALL	Z,STARher
	POP	IX
	POP	BC
	DJNZ	ZZ33a
	LD	A,23
	CALL	NEWBUL
; ---- v0.04: changed/new code or data
	JR	ZZ32+10

ZZ34 ;дальняя ракета
	CALL	HL_IXtEX
	CALL	DIST2
; ---- v0.04: changed/new code or data
	CP	#08
	JP	C,IX_stop ;слишком близко
	CALL	GMAP
	LD	A,(HL)
	OR	A
	RET	Z ;не стреляй на бордюр
	CP	#80
	RET	NC ;не стреляй в темноту
	LD	C,MANA-1
	CALL	isMANA
	CALL	HL_IXtEX
	EX	DE,HL
	LD	A,13
	CALL	NEWBUL
	JP	zz_EnV
; ---- v0.04: code removed (4.Z80: ZZdist8)



;----допустимость применения магии---

;ZZddin  ;опред дистанции до движ цели (в ЧВ2 - нет)
;	 LD A,(IX+tarN)
;	 PUSH IX
;	 CALL N_IX ;параметры врага
;	 LD (en_IX),HL
;	 CALL HL_IX0
;	 POP IX
;	 CALL IXt_HL
;	 LD A,L
;	 OR A
;	 JR Z,_ex98 ;цель погибла
;	 BIT 7,H
;	 JR NZ,_ex98 ;цель в здании
;	 CALL DIST2
;	 JR ZZd1

ZZdist8
ZZdistX
	CALL	HL_IXtEX
	CALL	DIST2
; ---- v0.04: changed/new code or data
	CP	#09
	RET	C
	POP	HL ;!!
	JP	NC,ZZ2 ;цель далеко

;-------пров.магич.энергии

isMANA ;есть волш энергия? (С)
	LD	A,(IX+energy)
	SUB	C
	JR	C,noMANA
	LD	(IX+energy),A
	RET
noMANA	LD	A,(SIDE_N)
	OR	A
	JR	NZ,_ex98
	LD	A,41 ;сообщ "no mana"
	CALL	dirTX
_ex98	POP	HL ;!!
	JP	IX_stop

;-----список целей (вх:A=0/1 - поиск своих/чужих)
;вых: HL-нач.списка номеров, #FF-конец)

zzMagLst ;составить список объектов в радиусе +-1 от центра магии
;BUF512[0] - #FF или тот, кто в центре
;BUF512[1..N] - номера тех, кто +-1, в конце #FF
;---
	LD	HL,BUF512
	PUSH	HL
	PUSH	IX
	LD	(HL),#FF
	INC	L
	EXX
	LD	C,A
	CALL	HL_IXtEX
	LD	A,(SIDE_N)
	XOR	C
	CALL	Z,loop_H
	CALL	NZ,loop_K
	LD	C,0
	JR	Z,zzMagL
	LD	C,_NHER
;
;жив?
zzMagL	LD	A,(IX+x)
	OR	A
	JR	Z,zzMg1
;в радиусе +-1
	PUSH	BC
	CALL	DIST2
	CP	2
	JR	NC,zzMg2
	OR	A
	JR	NZ,zzMgS
	isAVIA_
	JR	NZ,zzMgS
	LD	A,C
	LD	(BUF512),A
	JR	zzMg2
zzMgS	LD	A,C
	EXX
	LD	(HL),A
	INC	L
	EXX
zzMg2	POP	BC
zzMg1	ADD	IX,DE
	INC	C
	DJNZ	zzMagL
zzMgZ	EXX
	LD	(HL),#FF
;
	POP	IX
	POP	HL
	LD	A,(HL)
	INC	A
	RET	NZ
	INC	L
	RET

;-----список трупов (вых: HL-нач.списка номеров, #FF-конец)

zzTroLst ;составить список объектов в радиусе +-1 от центра магии
;BUF512[0] - #FF или тот, кто в центре
;BUF512[1..N] - номера тех, кто +-1, в конце #FF
;---
	LD	HL,BUF512
	PUSH	HL
	PUSH	IX
	LD	(HL),#FF
	INC	L
	EXX
	CALL	HL_IXtEX
;все трупы
	CALL	loopHb
	LD	BC,(_NALL*256)+0
;
zzToL ;пусто?
	LD	A,(IX+y)
	OR	A
	JR	Z,zzTo1
;труп?
	LD	A,(IX+x)
	OR	A
	JR	NZ,zzTo1
;в радиусе +-1
	PUSH	BC
	CALL	df45+8
	CP	2
	JR	NC,zzTo2
	OR	A
	JR	NZ,zzToS
	LD	A,C
	LD	(BUF512),A
	JR	zzTo2
zzToS	LD	A,C
	EXX
	LD	(HL),A
	INC	L
	EXX
zzTo2	POP	BC
zzTo1	ADD	IX,DE
	INC	C
	DJNZ	zzToL
	JR	zzMgZ

;---------------------

