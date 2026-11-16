; Чёрный Ворон 2: загрузчик (файл "br2" TR-DOS, #6000..). Boot-BASIC делает LOAD "br2" CODE и RANDOMIZE USR 24576.
;   диск игры (без INTRO):  #6000 JP START = bGAME - загрузить игру и запустить
;   диск 1 и диск 1 МБ (INTRO): START - заставка и меню диска 1 (1 - ролик, 2 - игра, 3 - инструкция, 5 - "в духе времени"),
;                               F_CUT - вход из инструкции (чит) и из игры в концовку
; В 1997 году - boot-сектор (1 КБ на #5D25) нестандартного диска (5 x 1024 байта, метки дисков, "царапина"; src/original/start1_1997.asm);
; теперь обычный файл TR-DOS; диск читается через disk.asm по таблицам положения файлов, которые строит build.py.
; Распаковка: страницы игры - ZX0 (dzx0.asm), заставки, ролики и музыка диска 1 остались в формате LPZ автора (xdelpz.asm).

LOADER	EQU	#6000
	ORG	LOADER

SCR	EQU	#C000
	IFNDEF	INTRO
DSCR	EQU	#4000 ;(в варианте INTRO он определён в tv16.asm)
	ENDIF

	JP	START ;#6000
	JP	F_CUT ;#6003: вход в концовку (B = 0/1 победа людей/кунгов, HL = код текста)
	DEFB	#19,#99 ;#6006: метка диска 1 (концовка проверяет, что прочитан загрузчик)
	DEFM	" Black Raven 2 StartUp Manager "

	INCLUDE "dzx0.asm" ;ZX0: HL = поток (после слова длины), DE = куда
DELPZ0	EQU	DELPC

	IFDEF	INTRO
DLPCB	DEFM	"v001"
	INCLUDE "xdelpz.asm" ;LPZ автора: DELPZ, HL = откуда, DE = куда
DELPZF	LD	DE,#FFFE
;Декомпрессор
;HL - ОТКУДА И КУДА, DE - ВЕРХНЯЯ ГРАНИЦА ОБЛАСТИ
DELPZX	PUSH	HL
	LD	C,(HL)
	INC	HL
	LD	B,(HL)
	ADD	HL,BC
	LDDR
	EX	DE,HL
	INC	HL
	POP	DE
	JP	DELPZ
	ENDIF

MEM0	XOR	A ;Cтандартная страница-0
	JR	MEM
MEM1	LD	A,1
	JR	MEM
MEM7	LD	A,7
MEM	OR	%10000
	PUSH	BC
	LD	BC,#7FFD
	OUT	(C),A
	POP	BC
	RET

OFFD	XOR	A
OFFD__	LD	DE,DSCR+#1AFE
	LD	HL,DSCR+#1AFF
	LD	BC,768
	LD	(HL),A
	LDDR
	RET

OFFS	CALL	MEM7
OFFS_	LD	DE,SCR+#1AFE
	LD	HL,SCR+#1AFF
	LD	BC,768
	LD	(HL),0
	LDDR
	RET

SW5	LD	A,%10000 ;норм экр
	JR	SW_
SW7	LD	A,%11000
SW_	LD	(MEM+1),A ;доп экр
	RET

	INCLUDE "disk.asm" ;чтение секторов TR-DOS (READ, POS, TR00, DRIVE)

; Таблица файлов игры (build.py: game_layout.inc): сектор 1..16, дорожка, число секторов - по 3 байта на файл 1..
	INCLUDE "game_layout.inc"

	IFDEF	INTRO
; Таблица файлов диска 1 (build.py: disk1_layout.inc): сектор 1..16, дорожка, число секторов - по 3 байта на файл 0..57
F_DAT
	INCLUDE "disk1_layout.inc"
ST_ADR	DEFB	#DB,B01ORG/256,#C0,#C0,#C0,#C0 ;куда читать файлы 0..15 (старший байт адреса): картинка в страницу 7, B01 интро, страницы
	DEFB	0,0,0,0,0,0,0,0 ;6..13 (в 1997 году - страницы игры; теперь они в таблице игры)
	DEFB	#6F,#C0 ;14, 15: концовка (#6F00 и страница 1); файлы 16.. (ролики) - #C0

START	DI
	IM	1
	LD	A,#3F ;I - как в ПЗУ (не "сжимаемая" память: нет "снега")
	LD	I,A
	LD	SP,LOADER+#5FE
	LD	A,(23798) ;дисковод (системная переменная TR-DOS)
	LD	(DRIVE),A
;Заставка
	XOR	A
	OUT	(254),A
	CALL	OFFD
	CALL	MEM7
	XOR	A
	CALL	LOADF
	LD	DE,SCR
	LD	HL,SWORD+2
	CALL	DELPZ
	CALL	SW7
	CALL	MEM0
	LD	A,1
	CALL	LOADF ;B01: интро, инструкция
	LD	A,1
	CALL	MEM
	LD	A,2
	CALL	LOADG
	LD	A,3
	CALL	MEM
	LD	A,3
	CALL	LOADG
	LD	A,4
	CALL	MEM
	LD	A,4
	CALL	LOADG
	LD	A,6
	CALL	MEM
	LD	A,5
	CALL	LOADG
	CALL	bSTARS ;-->
LOADG	CALL	LOADF
	LD	HL,#C000
	JP	DELPZF

WA	RLCA
BA	ADD	A,L
	LD	L,A
	JR	NC,B1
	INC	H
B1	LD	A,(HL)
	RET

LOADF ;A-N ф-ла (0..57)
	PUSH	AF
	LD	D,A
	ADD	A,A
	ADD	A,D
	LD	HL,F_DAT
	CALL	BA
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	INC	HL
	LD	B,(HL)
	POP	AF
	LD	H,#C0 ;флики
	CP	16
	JR	NC,LL16
	LD	HL,ST_ADR ;остальные файлы
	CALL	BA
	LD	H,A
LL16	XOR	A
	LD	L,A
RETRY0	PUSH	HL
	PUSH	DE
	PUSH	BC
	CALL	READ
	POP	BC
	POP	DE
	POP	HL
	RET	NC
	DI
	CALL	TR00
	CALL	TR00
	CALL	TR00
	JR	RETRY0

;--------------загрузка final-cut (из инструкции по чит-коду; B=0/1 - победа людей/кунгов, HL - код текста)
F_CUT	DI
	LD	A,#3F ;I - как в ПЗУ: игра могла оставить IM2
	LD	I,A
	IM	1
	PUSH	HL
	PUSH	BC
	LD	D,0
	CALL	POS
	CALL	TR00
	CALL	TR00
	CALL	MEM1
	LD	A,14
	CALL	LOADF ;концовка: код на #6F00
	LD	A,15
	CALL	LOADF ;страница 1
	POP	AF
	PUSH	AF
;загр блок мультиков: A
	OR	A
	LD	A,52
	JR	Z,fcc0
	LD	A,55
fcc0	LD	C,0
	CALL	LOA1fc
	CALL	LOA1fc
	CALL	LOA1fc ;декомпрессия - позднее
	DI
	POP	AF
	POP	HL
	JP	#6F00
LOA1fc	PUSH	BC
	PUSH	AF
	LD	A,C
	CALL	MEM
	POP	AF
	PUSH	AF
	CALL	LOADG
	POP	AF
	POP	BC
	INC	C
	INC	C
	INC	C
	INC	A
	RET
	ELSE
START	LD	A,(23798) ;дисковод (системная переменная TR-DOS)
	LD	(DRIVE),A
	JR	bGAME
F_CUT	RET
	ENDIF

; ---------------------------------------------------------------------------------------------------------------- игра
; Загрузка игры: страницы 1,7,6,3,4,0 (файлы G_PG..), код страницы 5 двумя половинами (в страницу 2), старт.
; Читаем файл в буфер, распаковываем ZX0 в окно #C000 нужной страницы. Буфер BUF1 (#8000) - страница 2, пока свободна;
; страницу 5 (код) читаем двумя половинами в BUF2 (#6400.., за загрузчиком; #5C00-#5CFF - системные переменные TR-DOS,
; их портить нельзя) и распаковываем в живую страницу 2 (#8000 и #A000): стартовая подпрограмма STARTR (последняя
; страница 0: обмен страниц 5 и 2) поставит код на место. build.py проверяет пересечения всех шагов (check_loader).
BUF1	EQU	#8000
BUF2	EQU	LOADER+#600

	MACRO	LDPG page,file,buf
	LD	A,file
	LD	HL,buf
	CALL	LOADFB
	LD	A,page
	CALL	MEM
	LD	HL,buf+2
	LD	DE,#C000
	CALL	DELPZ0
	ENDM

bGAME	DI
	IM	1
	LD	A,#3F
	LD	I,A
	LD	SP,LOADER+#5FE ;(выше кода загрузчика, ниже BUF2)
	CALL	CHKGAME ;в дисководе должен быть диск игры (на диске 1 МБ он же)
	CALL	SW7
	LDPG	1,G_PG1,BUF1
	LDPG	7,G_PG7,BUF1
	CALL	OFFD
	CALL	SW5
	XOR	A
	OUT	(254),A
	CALL	SW7
	LDPG	6,G_PG6,BUF1
	LDPG	3,G_PG3,BUF1
	LDPG	4,G_PG4,BUF1
	LDPG	0,G_PG0,BUF1
; код страницы 5 -> живая страница 2
	LD	A,G_PG5A
	LD	HL,BUF2
	CALL	LOADFB
	LD	HL,BUF2+2
	LD	DE,#8000
	CALL	DELPZ0
	LD	A,G_PG5B
	LD	HL,BUF2
	CALL	LOADFB
	LD	HL,BUF2+2
	LD	DE,#A000
	CALL	DELPZ0
	CALL	MEM0
	LD	A,(DRIVE) ;игра узнаёт дисковод загрузки (в 1997 году спрашивала)
	JP	STARTR

; LOADFB: A = номер файла (1..), HL = куда; читает файл с повтором
LOADFB	PUSH	HL
	LD	L,A
	LD	H,0
	LD	D,H
	LD	E,L
	ADD	HL,HL
	ADD	HL,DE
	LD	DE,GTAB-3
	ADD	HL,DE
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	INC	HL
	LD	B,(HL)
	POP	HL
RETRY1	PUSH	HL
	PUSH	DE
	PUSH	BC
	CALL	READ
	POP	BC
	POP	DE
	POP	HL
	RET	NC
	DI
	CALL	TR00
	CALL	TR00
	CALL	TR00
	JR	RETRY1

; CHKGAME: ждать, пока в дисководе окажется диск игры (метка "BR2GAME " в системном секторе: дорожка 0, сектор 9, +#F5)
CHKGAME	CALL	TR00
	LD	DE,#0009
	LD	B,1
	LD	HL,BUF2
	PUSH	HL
	CALL	READ
	POP	HL
	JR	C,CHKbad
	LD	DE,#F5
	ADD	HL,DE
	LD	DE,GAMELBL
	LD	B,8
CHKg1	LD	A,(DE)
	CP	(HL)
	JR	NZ,CHKbad
	INC	DE
	INC	HL
	DJNZ	CHKg1
	RET
CHKbad	CALL	MEM7
	CALL	SW7
	LD	HL,TXTins ;запрос диска
	LD	DE,SCR+#0820
	CALL	ROMPR
CHKw	LD	BC,#BFFE ;ждать ENTER
	IN	A,(C)
	RRA
	JR	C,CHKw
CHKr	IN	A,(C)
	RRA
	JR	NC,CHKr
	JR	CHKGAME
GAMELBL	DEFM	"BR2GAME "
TXTins	DEFM	"Insert GAME disk, press ENTER",0

; ROMPR: HL = строка (0 в конце), DE = адрес в экране; шрифт ПЗУ (#3D00, символы 32..127)
ROMPR	LD	A,(HL)
	INC	HL
	OR	A
	RET	Z
	PUSH	HL
	PUSH	DE
	LD	L,A
	LD	H,0
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	LD	BC,#3C00
	ADD	HL,BC
	LD	B,8
ROMp1	LD	A,(HL)
	LD	(DE),A
	INC	HL
	INC	D
	DJNZ	ROMp1
	POP	DE
	POP	HL
	INC	E
	JR	ROMPR
