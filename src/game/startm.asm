; Чёрный Ворон 2: запуск игры - заставка-демо, стартовое меню (Люди / Кунги / Загрузить), старт уровня, выход в меню.
; Меню - по образцу Чёрного Ворона 1 (окно MU_BOX, шрифт и цвета игры, выбор цифрой). Демо - заставка автора (случайный
; бой, _OLD/__DEMO.A80), выход из неё по любой клавише.
;
; JP_ST (main.asm) -> _wMAIN -> wMAIN:
;   wDEMO:  уровень людей из файла, DEMO (до нажатия клавиши)
;   wMENU:  меню: 1 - люди, 2 - кунги, 3 - загрузить слот; без нажатий MENUTM кадров - снова демо
;   wGAME:  LODlev (A = 0/1 - уровень), LDRES (ландшафт, кнопки, панель), putBAR, SEEonn, setMAP, _start (игровой цикл)
; Из игры в меню возвращают: победа (LODnxt), пункт "выход" меню паузы (toMENU). LODrtr - заново тот же уровень.

MENUTM	EQU	1500	; кадров без нажатия клавиши в меню до запуска демо (30 с)

wMAIN	DI
	LD	SP,STKTOP
wDEMO	XOR	A
	LD	(SIDEnew),A ;демо - на уровне людей
	CALL	DEMO ;DEMOF=1
	JR	wGAME
wMENU	DI
	XOR	A
	LD	(DEMOF),A
	LD	SP,STKTOP
	CALL	LDMENU ;код меню: файл F_MENU диска -> DSCR (MENUOV)
	CALL	MENUOV ;A = 0 - таймаут, 1/2 - люди/кунги, 3 - загрузить
	OR	A
	JR	Z,wDEMO
	CP	3
	JR	Z,wLOAD
	DEC	A
	LD	(SIDEnew),A
wGAME	LD	A,(SIDEnew)
	CALL	LODlev ;A = 0/1: MAP, параметры уровня (в них MASTER, COLOR, fsLAND)
	LD	HL,RESULT ;копия времени игры (для "заново")
	LD	DE,RESULT+7
	LD	BC,6
	LDIR
	CALL	LDRES
	CALL	putBAR
	CALL	MEM0
	CALL	SEEonn
	CALL	setMAP
	JP	_start
wLOAD	CALL	LDMENU
	CALL	MENUOV+3 ;SLOTMENU: A = слот 0..NSLOTS-1 или 255 - отказ
	INC	A
	JR	Z,wMENU
	DEC	A
	CALL	LODgam ;при удаче в меню не возвращается
	CALL	STS
	LD	DE,#E05 ;внутри окна меню (чёрным по чёрному вне окна не видно)
	LD	HL,ITXnot
	CALL	PRINTS
	LD	B,100
wLD1	HALT
	DJNZ	wLD1
	JR	wMENU

; конец игры (победа) и "выход" меню паузы: назад в меню (музыку гасит iMUSIC)
LODnxt
toMENU	DI
	LD	SP,STKTOP
	CALL	MEM6
	CALL	iMUSIC
	JR	wMENU

; "заново" (меню паузы, поражение): тот же уровень сначала
LODrtr	DI
	LD	SP,STKTOP
	CALL	MEM6
	CALL	iMUSIC
	LD	HL,RESULT+7
	LD	DE,RESULT
	LD	BC,6
	LDIR
	JR	wGAME

SIDEnew	DEFB	0 ;0/1 - выбранная сторона (людей/кунги)


; код меню лежит на диске (файл F_MENU) и работает в рабочем экране DSCR: в странице 5 для него нет места
LDMENU	LD	A,F_MENU
	LD	HL,MENUOV
	CALL	READ
	EI ;D_READ оставляет прерывания запрещёнными, а меню ждёт HALT
	RET
