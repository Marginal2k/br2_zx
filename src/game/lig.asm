; ---- v0.04 selWindow (94 bytes at #F18B): dzp0 helpers: screen corners of the selection window from diXSEL/diYSEL, BMX, X0/Y0 (selFrameCorners, selCoord), oneSEL
selFrameCorners
	LD	A,(diXSEL)
	SRL	A
	LD	C,A
	LD	B,#00
	LD	A,(BMX)
	LD	E,A
	LD	D,B
	LD	A,(X0)
	CALL	selCoord
	PUSH	HL
	EXX
	POP	BC
	EXX
	LD	A,(diYSEL)
	SRL	A
	LD	C,A
	LD	A,(BMX+1)
	LD	E,A
	LD	A,(Y0)
	CALL	selCoord
	PUSH	HL
	EXX
	POP	DE
	EXX
	RET
selCoord
	LD	L,A
	LD	H,D
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,DE
	OR	A
	SBC	HL,BC
	RET
oneSEL
	LD	HL,(PX)
	CALL	GMAP
	BIT	7,(HL)
	RET	NZ
	CALL	homSEL
	LD	HL,#1E1E
	LD	(diXSEL),HL
	CALL	selFrameCorners
	LD	A,#FF
	LD	(minSEL),A
	CALL	loopHb
;--СТРАНИЦА 0

;--подсчёты--
COMPUT ;подгот данных для выв панели

;---операц с деньгами/лесом




BUTmw ;уcт знач денег/леc по кнопкам

parBUT ;выдать меню параметров героя




;------цены для кнопок (металл/мазут)

vpHOME ;цены на здания

vpMAGI ;стоимость заклинаний
;

vpUPGR ;апгрейды наземные

vpUPAV ;апгрейды воздушные

vpHERO ;стоимость пр-ва героев
;стоимость танка и авиации людей
;стоимость авиации кунгов


BUTval ;дать значения ресурсов кнопкам
;
;bVmagic
;
;
;
;
bVset ;HL-таб, A-номер


;---------кнопки----------

ICONS0 ; наборы кнопок героев


N_ICON ;наборы иконок по типам


cBUini ;очиcтка кнопок с обновлением
;
cBUT ;очиcтка кнопок

spcTB1 ;кнопки типа 1
;вых:A=1/2-команда иcп по space (2-для закл);0-остальные

BUTING ;занеcение кнопок героя в BUT_N

;none
;враги/плен
hUfrnd ; наш (не группа)
;
;
;разрешена ли кнопка (18,19,67..75,76)?
;
isBt18 ;посадка в транспорт
;
isBt19 ;высадка из транспорта
;
isBt67 ;магия и заклинания
;


hU_ext ;-------другие меню
;другие меню пеонов
;
cp21 ;есть ли завод (2) для 3,4,5
;есть ли мастерская (4) для 3

searBB ;поиск казарм/гнёзд(6,14); кол-во построеных+строящихся ->C;


hUgrp ;------группа (к-во=A)
;разрешена ли кнопка в группе (8,9,18,19,20,67..75)?
;



;=======работа со зданиями
hUBtb ;наборы кнопок зданий

hUBbut ;Здания 1,7,9,15 ректификар - none
;

hUMIN ;шахты
;
hUb_FF ;стр-во/пр-во

hUblt ;-------------здания-----
;
;магические кнопки
;кнопки улучшения боевых качеств
hUbcs3 ;кнопки героев
hUbcs5 ;для магов надо академию (5)
;для демона,валкера,танка надо мастерскую(4)
;


hUpICO ;иконки параметров

hUparm ;выдать параметры героя #1 в окне иконок
;можно ли посадить в шатлл?
;для кунгов +парам роста здоровья

hUcrew ;показать экипаж


;------------------------------

gYGR ;группа

gtINDY ;получить значения для индикаторов здоровья/энергии/пр-ва
gY1 ;один чел
;здания
;у наших
;cтадия стр_ва
gY4_1 ;пр_во/иссл

gY2_2 ;шахты
gY2_3 ;здан врагов
gY4 ;враг


