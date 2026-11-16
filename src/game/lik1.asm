; ---- v0.04: changed/new code or data (4.Z80: GObj2 (для BFORCE) vv7x)
	LD	IX,HBUILD
	LD	B,#20
v4_pCBr_1
	PUSH	BC
	LD	A,(IX+#00)
	OR	A
	LD	A,#01
	CALL	NZ,onsee+9
	LD	BC,#0008
	ADD	IX,BC
	POP	BC
	DJNZ	v4_pCBr_1
;-------РАБОТА СО СНАРЯДАМИ/ВЗРЫВАМИ/ЗАКЛИНАНИЯМИ/ДЫМОМ------

;----------СНАРЯД ПЕРЕМЕЩАЕТСЯ/ДОСТИГ ЦЕЛИ---
GObj2	; (в v0.04 код удалён, метка сохранена для ссылок)

VV14 ;взр.камикадз

VObj42 ;мина

VV7 ;снр танк
;взрыв
vv7x	; (в v0.04 код удалён, метка сохранена для ссылок)

VV11 ;снр тень

VV29 ;облако после пожара

VV10 ;огонь ланг
VV5 ;огонь волш
VV6 ;огонь свящ
;обжечь врага


VV9 ;кун
;
VV3 ;волк
VV1 ;дес
;разить врага N

VV4 ;зенит
VV8 ;\
VV12 ;ист/вор
VV2 ;огнм
;разить врага N


BULLER ;-----обработчик пуль
VVdec ;различн взрывы

;----------предметы


VV30 ;леч роб
;лечить

VObj34 ;м-конц

VObj35 ;ц-конц

VObj33 ;кам

VObj32 ;огн


VObj37 ;выключ
;нач. опуск забор
;сделать прох
;

VObj36 ;телеп
;он перемещ?
;найти нов.телеп
;
v36tel ;поиск
;убрать на стар месте
;останов
;поставь на нов месте
;если выбран - в центр

VV13 ;полёт ракеты кунгов
vv13a ;обжечь врага
;найти новые коорд (DE)
;

;-----

;
;



VV48 ;закл "AiDS"
VV49 ;\

VV52 ;закл "ПАНИКА"
VV53 ;\
;
Zaraza ;распространение болезни
;выбрать случайно
;находится в контакте?
;заразить

VV46 ;закл "ТОРМОЗ"
VV47 ;\
VV50 ;закл "хрст шар"
VV51 ;\


VV44 ;закл "защита демона"
VV45 ;\



;--------расчёты перемещения снарядов----

SHFT8 ;выч смещения-8 для снарядов
;hl--->de  вых:iy6,7

SHFT16 ;выч смещения-16 для снарядов
;hl--->de  вых:iy6,7




;-----какие из объектов можно удалить при НЕХВАТКЕ ПАМЯТИ
;--- 0-низкий 1-средний 2-высокий 3-высший

B_PRIOR ;снаряды
;


;проч

;предм

;закл

;--------
;----------------------------------------------
;---------------ПОРОЖДЕНИЕ--СНАРЯДОВ-----------

;
;
;--выделение места в памяти (IY)
;нет места - попробуй удалить с меньшим приоритетом
;всё равно нет места - используй последний
;
NEWBU_ ;на выделенную память

;------------------------п/п порождения


NB29 ;взр здания IX


nb3corr ;кор выст для волк X,Y

NB3 ;волк
NB9 ;кунг
NB1 ;десант

NB2 ;огнемёт
;
;
;


nb1corr ;кор выст для дес/кун X,Y




NBtar ;;
;

NB10 ;лангол
NB30 ;лечен роб
NB6 ;\
NB5 ;огонь волш


NB11 ;тень

NB4 ;зенитка

NB8 ;\
NB12 ;истр/воро

NB7 ;танк

NB16 ;поп дес/волк
NB18 ;поп кун


NB31 ;стр-во зенит (DE)

NB37 ;выключ

NB32 ;волш.пламя
;тут уже есть пламя?

NB33 ;камень
;получить координаты
;небольшой разброс
;


NB39 ;заборА

NB40 ;заборБ
;

NB42 ;мина
NB34 ;мет-конц
NB35 ;цик-конц
NB36 ;телеп

NB23 ;гибель авиа
NB22 ;утроение.волкера

NB14 ;взрыв камикадзе

NB13 ;дальняя ракета

NB25 ;звёзды волшебников (на цель)

NB24 ;звёзды волшебников на DE

;----------
NB46 ;тормоз
NB48 ;aids
NB50 ;хруст шар
NB52 ;паника


NB44 ;огн.кольцо
nb44a ;пушки не подвержены этой магии
;общая магия
;нельзя использовать последнюю ячейку!
;нет других заклинаний?
;
zzX_NO ;нельзя применить заклинание



;---------

NEWBtb ;---проц.порождения
;снар


;про

;пре

;зак

;///



COPYiy_ ;ix(-4..-1)->iy(-4..-1)


COR24iy_ ;3х3 выровнять по цели

COR16iy_ ;2х2 выровнять по цели

COR8iy_ ;1х1 выровнять по цели
;
CORiy_ ;коррекция коорд (E+iy(-4,-3); D+iy(-2,-1)) (-128..+127)



GETiyXY_ ;получить X,Y в (IY+1,2) и в DE из (IY-1,2,3,4)
;

BULLty ;---проц обработки
;снар


;про

;пре

;зак

ellips ;---траектория-60

;---


ELIPS44 ;обработка с расчётом по эллипсу
;
;найти новые коорд
;
;вероятность удара - 50%
;кто атакует - наш/не наш?
elps05 ;попытка удара
;
	RET

; ---- v0.04 onsee (139 bytes at #F955): onsee/ONSEEm/onsee2: the unit opens the fog around itself: clears bit 7 of the 5x5 map cells (sight radius from DEFENC)
onsee2
	CALL	HL_IX0
	LD	D,#00
	JR	v4_onsee_1
ONSEEm
	LD	D,#00
	JP	v4_onsee_8
onsee
	LD	A,(IX+#04)
	LD	HL,DEFENC+24
	CALL	BA
	CALL	HL_IX0
	LD	D,#00
	CP	#01
	JP	NC,v4_onsee_7
v4_onsee_1
	LD	A,H
	SUB	#02
	LD	H,A
	JR	C,v4_onsee_5
	CP	#3C
	JR	NC,v4_onsee_5
	LD	A,L
	SUB	#02
	JR	C,v4_onsee_5
	CP	#3C
	JR	NC,v4_onsee_5
	DEC	L
v4_onsee_2
	CALL	GMAP
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	LD	E,#3D
	ADD	HL,DE
v4_onsee_3
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	DEC	E
	ADD	HL,DE
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
v4_onsee_4
	ADD	HL,DE
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	LD	E,#3D
	ADD	HL,DE
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	RET
v4_onsee_5
	LD	A,L
	SUB	#02
	LD	L,A
	CP	H
	RET	Z
	LD	A,H
	CP	#FF
	JR	C,.onsee_6
	INC	H
	CALL	GMAP
	LD	E,#3D
	JR	v4_onsee_3
.onsee_6
	INC	L
	CP	#3C
	JR	C,v4_onsee_2
	CALL	GMAP
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	LD	E,#3D
	ADD	HL,DE
	DEC	E
	CALL	v4_onsee_19
	JP	v4_onsee_19
v4_onsee_7
	JP	NZ,v4_onsee_10
v4_onsee_8
	LD	A,H
	SUB	#03
	LD	H,A
	JR	C,.onsee_9
	CP	#3A
	JR	NC,.onsee_9
	LD	A,L
	SUB	#03
	JR	C,.onsee_9
	CP	#3A
	JR	NC,.onsee_9
	DEC	L
	CALL	GMAP
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	LD	E,#3D
	ADD	HL,DE
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	DEC	E
	DEC	E
	ADD	HL,DE
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	DEC	E
	ADD	HL,DE
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	ADD	HL,DE
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	INC	E
	JP	v4_onsee_4
.onsee_9
	DEC	L
	LD	B,#03
	CALL	v4_onsee_20
	DEC	L
	LD	B,#05
	CALL	v4_onsee_20
	DEC	L
	LD	B,#07
	CALL	v4_onsee_20
	CALL	v4_onsee_20
	CALL	v4_onsee_20
	INC	L
	LD	B,#05
	CALL	v4_onsee_20
	INC	L
	LD	B,#03
	JP	v4_onsee_20
v4_onsee_10
	CP	#02
	JP	NZ,v4_onsee_13
	LD	A,H
	SUB	#04
	LD	H,A
	JR	C,.onsee_11
	CP	#38
	JR	NC,.onsee_11
	LD	A,L
	SUB	#04
	JR	C,.onsee_11
	CP	#38
	JR	NC,.onsee_11
	DEC	L
	DEC	L
	CALL	GMAP
	LD	E,#3B
	CALL	v4_onsee_19
	LD	E,#39
	CALL	v4_onsee_18
	DEC	E
	CALL	v4_onsee_17
	CALL	v4_onsee_17
	CALL	v4_onsee_17
	CALL	v4_onsee_17
	INC	E
	CALL	v4_onsee_17
	INC	E
	INC	E
	CALL	v4_onsee_18
	INC	E
	INC	E
	JP	v4_onsee_19
.onsee_11
	DEC	L
	DEC	L
	LD	B,#05
	CALL	v4_onsee_20
	DEC	L
	LD	B,#07
	CALL	v4_onsee_20
	DEC	L
	LD	BC,#0905
.onsee_12
	CALL	v4_onsee_20
	DEC	C
	JR	NZ,.onsee_12
	INC	L
	LD	B,#07
	CALL	v4_onsee_20
	INC	L
	LD	B,#05
	JP	v4_onsee_20
v4_onsee_13
	LD	A,H
	SUB	#05
	LD	H,A
	JR	C,.onsee_14
	CP	#36
	JR	NC,.onsee_14
	LD	A,L
	SUB	#05
	JR	C,.onsee_14
	CP	#36
	JR	NC,.onsee_14
	DEC	L
	DEC	L
	DEC	L
	CALL	GMAP
	LD	E,#39
	CALL	v4_onsee_18
	DEC	E
	DEC	E
	CALL	v4_onsee_17
	DEC	E
	CALL	.onsee_16
	CALL	.onsee_16
	CALL	.onsee_16
	CALL	.onsee_16
	CALL	.onsee_16
	CALL	.onsee_16
	INC	E
	CALL	.onsee_16
	INC	E
	INC	E
	CALL	v4_onsee_17
	INC	E
	INC	E
	JP	v4_onsee_18
.onsee_14
	DEC	L
	DEC	L
	DEC	L
	LD	B,#07
	CALL	v4_onsee_20
	DEC	L
	LD	B,#09
	CALL	v4_onsee_20
	DEC	L
	LD	BC,#0B07
.onsee_15
	CALL	v4_onsee_20
	DEC	C
	JR	NZ,.onsee_15
	INC	L
	LD	B,#09
	CALL	v4_onsee_20
	INC	L
	LD	B,#07
	JR	v4_onsee_20
.onsee_16
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	INC	HL
v4_onsee_17
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	INC	HL
v4_onsee_18
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	INC	HL
v4_onsee_19
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	INC	HL
	RES	7,(HL)
	ADD	HL,DE
	RET
v4_onsee_20
	LD	A,H
	CP	#3F
	JR	NC,seeRet
	PUSH	HL
	PUSH	BC
	LD	A,L
	OR	A
	LD	A,B
	JP	P,.onsee_21
	ADD	A,L
	LD	B,A
	LD	L,#00
	JR	.onsee_22
.onsee_21
	ADD	A,L
	SUB	#3F
	JR	C,.onsee_22
	LD	C,A
	LD	A,B
	SUB	C
	LD	B,A
.onsee_22
	CALL	GMAP
.onsee_23
	RES	7,(HL)
	INC	L
	DJNZ	.onsee_23
	POP	BC
	POP	HL
seeRet ;onsee: INC H; RET - общий конец (на следующую строку клеток)
	INC	H
	RET