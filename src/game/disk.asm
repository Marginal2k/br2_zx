; Чёрный Ворон 2: дисковый слой игры. Всё, что игра делает с диском, проходит через этот файл:
;   D_READ   D = логическая дорожка (цилиндр*2+сторона), E = сектор 1..16, B = число секторов, HL = адрес;
;            читает B секторов по 256 байт подряд (переходя на следующие дорожки); CY=1 - ошибка (3 попытки на сектор)
;   D_WRITE  то же, пишет
;   TR000    перекалибровка дисковода (перед повтором)
;   READ     A = номер файла ресурса игры (1..NFILES, таблица RESTAB), HL = адрес: загрузить файл целиком (с повтором)
;   SLOTPOS  A = слот сохранения 0..NSLOTS-1 -> D, E = дорожка, сектор первого сектора слота (SLOTSEC секторов)
;   tDRIVE   (переменная в main.asm) номер дисковода 0/1 (A/B) для всех операций
;
; Диск - обычный TR-DOS: секторы по 256 байт 1..16, логическая дорожка = цилиндр*2 + сторона. Где лежит каждый файл,
; записано в disk_layout.inc (его делает build.py); в каталоге TR-DOS файлы видны, но игра читает их по положению.
; (В 1997 году - нестандартный формат 5 x 1024 байта без каталога, метки дисков и "царапина": см. src/original/.)
;
; Игра держит код в области #4000.. (экран и системные переменные TR-DOS), поэтому вход #3D13 использовать нельзя.
; Секторы читаются кусками ПЗУ TR-DOS 5.03 через #3D2F: #2A53 (OUT (C),A), #3EF5 (ждать контроллер), #2090 (чтение
; сектора), #2FC3/#3FCA (запись), #2F5F/#2F65 (на нулевую дорожку). ПЗУ хранит код ошибки в #5CD6 - это байт кода
; игры, он сохраняется и возвращается здесь. Чтобы перенести игру на другую дисковую систему, нужно переписать
; только этот файл.

	INCLUDE "disk_layout.inc"	; RESTAB, SAVELIN, NSLOTS (генерируется build.py)

; Слот сохранения: G_DATA..#9FFF (переменные, герои, MAP, MAP2) + #B800..#BFFF (BUF512, KBUILD, пули, параметры, таблица
; IM2) + LEVVARS (переменные уровня в странице 5; 2 сектора = 512 байт: сами переменные и неизменяемые таблицы за ними).
; Рабочий экран DSCR (#A000..#B7FF) не сохраняется: он перерисовывается каждый кадр.
SAV1SEC	EQU	(DSCR-G_DATA)/256	; 44
SAV2SEC	EQU	(#C000-BUF512)/256	; 8
SAV3SEC	EQU	2
SLOTSEC	EQU	SAV1SEC+SAV2SEC+SAV3SEC	; 54

; позиционирование: D = логическая дорожка
POS	LD	A,(tDRIVE)
	AND	3
	OR	#3C		; сторона 0, MFM, без сброса
	BIT	0,D
	JR	Z,DW_SID
	RES	4,A		; сторона 1
DW_SID	LD	C,#FF
	CALL	RG_DOS
	LD	A,D
	SRL	A
	LD	C,#7F
	CALL	RG_DOS
	LD	A,#18		; seek
	LD	C,#1F
	CALL	RG_DOS
	CALL	COM_EX
	DI
	RET

RD_SCT	LD	BC,RD_SCT
	PUSH	BC
	LD	BC,#17F
	LD	IX,#2090	; чтение сектора (портит #5CD6)
	JR	DOS

RG_DOS	LD	IX,#2A53	; вывод в регистр контроллера (out (C),A: ret)
	JR	DOS

COM_EX	LD	IX,#3EF5	; ждать выполнения команды
DOS	PUSH	IX
	JP	#3D2F

ERR_RW	SCF
	RET

TR000	CALL	TR0
TR0	CALL	TR00
TR00	DI
	LD	IX,#2F5F
	CALL	DOS
	LD	IX,#2F65
	JP	DOS

; следующий сектор: E = 1..16, потом следующая логическая дорожка
NXTSEC	INC	E
	LD	A,E
	CP	17
	RET	C
	LD	E,1
	INC	D
	JP	POS

D_READ	DI ;E-сектор,D-дорожка,B-число секторов,HL-адрес
	CALL	POS
	LD	A,(#5CD6)
	EX	AF,AF'
NXT_S	LD	IXL,3 ;число попыток
NXT_SC	PUSH	HL
	PUSH	BC
	PUSH	IX
	LD	C,#5F
	LD	A,E
	CALL	RG_DOS
	CALL	RD_SCT
	DI ;обязательно
	LD	HL,#5CD6
	EX	AF,AF'
	CP	(HL)
	POP	IX
	JR	Z,GOOD
	LD	(HL),A
	DEC	IXL
	POP	BC
	POP	HL
	JP	Z,ERR_RW
	EX	AF,AF'
	JR	NXT_SC
GOOD	POP	BC
	POP	HL
	EX	AF,AF'
	CALL	NXTSEC
	INC	H
	DJNZ	NXT_S
	XOR	A
	RET

D_WRITE	DI ;запись секторов по 256 байт
	CALL	POS
LOPWR1	PUSH	HL
	PUSH	BC
	LD	C,#5F
	LD	A,E
	CALL	RG_DOS
	CALL	WR_SC
	DI
	POP	BC
	POP	HL
	CALL	NXTSEC
	INC	H
	DJNZ	LOPWR1
	RET

WR_SC	LD	A,#A0
	LD	IX,#2FC3
	CALL	DOS
	LD	IX,#3FCA	; IN A,(#FF): AND #C0: JR Z: RET M: OUTI: JR
	LD	C,#7F
	JP	DOS

; READ: A = номер файла (1..), HL = адрес
READ	PUSH	HL
	LD	L,A
	LD	H,0
	LD	D,H
	LD	E,L
	ADD	HL,HL
	ADD	HL,DE
	LD	DE,RESTAB-3
	ADD	HL,DE
	LD	D,(HL)		; дорожка
	INC	HL
	LD	E,(HL)		; сектор
	INC	HL
	LD	B,(HL)		; число секторов
	POP	HL
READ1	PUSH	HL
	PUSH	DE
	PUSH	BC
	CALL	D_READ
	POP	BC
	POP	DE
	POP	HL
	RET	NC
	CALL	TR000
	JR	READ1

; SLOTPOS: A = слот 0..NSLOTS-1 -> D = дорожка, E = сектор (1..16) первого сектора слота; слот = SLOTSEC секторов подряд
SLOTPOS	LD	HL,SAVELIN
	INC	A
SLP0	DEC	A
	JR	Z,SLP1
	LD	BC,SLOTSEC
	ADD	HL,BC
	JR	SLP0
SLP1	LD	A,L
	AND	15
	INC	A
	LD	E,A		; сектор 1..16
	LD	B,4
SLP2	SRL	H
	RR	L
	DJNZ	SLP2
	LD	D,L		; дорожка (0..255: на диске 1 МБ - до 255)
	RET
