; Чёрный Ворон 2: ввод-вывод игры - загрузка ресурсов, уровней, сохранение. Сам диск - в disk.asm.
; (Оригинал 1997 года, с защитой, шифрованием и 1К-секторами: src/original/io_1997.asm.)

	INCLUDE "disk.asm"
DELPZ	EQU	DELPC ;ZX0 (dzx0.asm, после шрифта): HL = поток (после слова длины), DE = куда
LANDH	EQU	13184/2	;ландшафт (13184 байт) лежит на диске двумя блоками: упакованный блок должен поместиться в DSCR

; READZ: A = номер файла, HL = куда: читает файл (блок "слово длины + поток ZX0") в рабочий экран DSCR и распаковывает в HL.
; Упакованный блок должен быть короче DSCR (6144 байта).
READZ	PUSH	HL
	LD	HL,DSCR
	PUSH	HL
	CALL	READ
	POP	HL
	INC	HL
	INC	HL
	POP	DE
	JP	DELPZ

; LDRES: ландшафт (fsLAND: 4 - кунги, 5 - люди), кнопки (MASTER: 0 - люди, 1 - кунги) и панель (в DSCR; рисует putBAR).
; Что уже загружено, помнят _sLAND и _sBUTT. Нужна страница 1 (ландшафт), 7 (кнопки).
LDRES	CALL	MEM1
	LD	A,(fsLAND)
	LD	HL,_sLAND
	CP	(HL)
	JR	Z,lad2 ;загружено
	LD	(HL),A
	LD	B,F_LAND5
	CP	5
	JR	Z,lad1a
	LD	B,F_LAND4
lad1a	PUSH	BC
	LD	A,B
	LD	HL,LAND
	CALL	READZ ;1-я половина (файл B)
	POP	BC
	LD	A,B
	INC	A
	LD	HL,LAND+LANDH
	CALL	READZ ;2-я половина (файл B+1)
lad2	CALL	MEM7 ;--кнопки
	LD	A,(MASTER)
	LD	HL,_sBUTT
	CP	(HL)
	JR	Z,lad3
	LD	(HL),A
	ADD	A,F_BUTTH
	LD	HL,WBUTT
	CALL	READZ
lad3	CALL	LDMPS ;--MPsign (страница 6) по стороне
	CALL	MEM0 ;--панель: из файла в DSCR
	LD	A,F_BAR
	LD	HL,DSCR
	JP	READ

; LODlev: A = 0/1 - уровень людей/кунгов: читает файл уровня в DSCR и распаковывает три блока ZX0: MAP (#8000), BUF512 (#B800) и
; переменные уровня (LEVVARS, страница 5). В 1997 году - файл диска 2 с упаковкой LPZ на весь #8000-#BFFF.
; Затем создаёт таблицу IM2 и обнуляет массивы зданий и пули.
LODlev	ADD	A,F_LEVH
	LD	HL,DSCR
	PUSH	HL
	CALL	READ
	POP	HL
	CALL	lev1 ;MAP -> #8000
	LD	DE,BUF512
	CALL	lev2 ;BUF512 (datMIN, datHER) -> #B800
	LD	DE,LEVVARS
	CALL	lev2 ;переменные уровня -> страница 5
	JP	LVTAIL ;mkIM2, MINE/HBUILD/KBUILD/пули - нули (lib1a.asm: в свободном месте)
lev1	LD	DE,MAP
lev2	LD	C,(HL)
	INC	HL
	LD	B,(HL)
	INC	HL
	PUSH	HL
	ADD	HL,BC
	EX	(SP),HL
	PUSH	DE
	CALL	DELPZ
	POP	DE
	POP	HL
	RET

; таблица векторов IM2 (257 байт #40 в странице 2, I = IM2_I): вектор #4040 = JP INTRP
mkIM2	LD	HL,IM2_TAB
	LD	DE,IM2_TAB+1
	LD	BC,256
	LD	(HL),#40
	LDIR
	RET

;----------сохранение игры--
; Слот = SLOTSEC секторов: G_DATA..#9FFF (SAV1SEC), BUF512..#BFFF (SAV2SEC), MINE..(SAV3SEC) - см. disk.asm.
; Записи не шифруются (в 1997 году ENCODE/DECODE + контрольная сумма): вместо суммы - признак SAVSIG в SAVSIGA
; (внутри сохраняемого диапазона); пустой слот (нули) загрузкой отвергается.
SAVSIGA	EQU	#BFFA
SAVSIG	EQU	#A55A

SAVgam	PUSH	AF ;сохр A=0..NSLOTS-1
	CALL	MEM6
	CALL	iMUSIC
	CALL	MEM7
	DI
	LD	HL,SAVSIG
	LD	(SAVSIGA),HL
Srtry	POP	AF
	PUSH	AF
	CALL	SLOTPOS
	PUSH	DE
	CALL	TR000
	POP	DE
	PUSH	DE
	LD	HL,G_DATA
	LD	B,SAV1SEC
	CALL	D_WRITE
	LD	HL,BUF512
	LD	B,SAV2SEC
	CALL	D_WRITE
	LD	HL,LEVVARS
	LD	B,SAV3SEC
	CALL	D_WRITE
;----пров перв сект (читается в DSCR как в буфер: он не сохраняется)
	POP	DE
	LD	HL,DSCR
	PUSH	HL
	LD	B,1
	CALL	D_READ
	POP	HL
	JR	C,Srtry
	LD	DE,G_DATA
	LD	B,255
svvCP0	LD	A,(DE)
	CP	(HL)
	JR	NZ,Srtry ;--err
	INC	HL
	INC	DE
	DJNZ	svvCP0
	POP	AF
	EI
	RET

; LODgam: A = слот 0..NSLOTS-1. Сначала читается сектор слота с признаком SAVSIG (в DSCR как в буфер); если признака нет или
; чтение не удалось - слот пуст, игра не тронута, возврат с CY=1. Иначе слот читается целиком, ресурсы, панель и экран
; восстанавливаются (CONTgm), и управление не возвращается (игра продолжается).
LODgam	DI
	LD	(lggSLT),A
	LD	A,5 ;к_во ретрай-попыток
	LD	(lggTRY),A
lgg0	LD	A,(lggSLT)
	CALL	SLOTPOS
	PUSH	DE
	CALL	TR000
	POP	DE
	PUSH	DE
	LD	B,SAV1SEC+(SAVSIGA-BUF512)/256 ;сектор слота с признаком
lgg1	PUSH	BC ;POS (ПЗУ TR-DOS) портит B
	CALL	NXTSEC
	POP	BC
	DJNZ	lgg1
	LD	HL,DSCR
	LD	B,1
	CALL	D_READ
	POP	DE
	JR	C,lggERR
	LD	HL,(DSCR+(SAVSIGA&255))
	LD	BC,SAVSIG
	OR	A
	SBC	HL,BC
	JR	NZ,lggBAD ;нет данных об игре
	PUSH	DE
	LD	HL,G_DATA
	LD	B,SAV1SEC
	CALL	D_READ
	JR	C,lggER1
	LD	HL,BUF512
	LD	B,SAV2SEC
	CALL	D_READ
	JR	C,lggER1
	LD	HL,LEVVARS
	LD	B,SAV3SEC
	CALL	D_READ
	JR	C,lggER1
	POP	DE
	JR	CONTgm
lggER1	POP	DE
lggERR	CALL	TR000
	LD	A,(lggTRY)
	DEC	A
	LD	(lggTRY),A
	JR	NZ,lgg0
lggBAD	SCF
	EI ;слот пуст: игра продолжается (меню паузы / стартовое меню ждут HALT)
	RET
lggSLT	DEFB	0
lggTRY	DEFB	0

; продолжение прочитанной игры: ресурсы стороны, панель, экран, музыка
CONTgm	LD	SP,STKTOP
	LD	A,2
	LD	(V_FLAG),A
	CALL	LDRES
	CALL	MEM7
	CALL	STS ;рисовать на экран (в сохранении SCRADR мог быть и рабочим экраном)
	CALL	putBAR
	CALL	MEM1
	CALL	shadwS
	CALL	MEM6
	CALL	nMUSIC
	CALL	EVENT ;выделение/портрет: ENTRY2 (BUTCLR) обнуляет BUT_H, пересчёт идёт только по _event (был жёлтый квадрат вместо портрета)
	EI
	JP	ENTRY2
qLOAD	XOR	A
	JP	LODgam
