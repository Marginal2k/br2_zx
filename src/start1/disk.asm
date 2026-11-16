; Загрузчик диска 1: чтение секторов TR-DOS (кусками ПЗУ TR-DOS 5.03 через #3D2F; подробнее - src/game/disk.asm).
;   READ     D = логическая дорожка (цилиндр*2+сторона, 0..255), E = сектор 1..16, B = число секторов, HL = адрес;
;            CY=1 - ошибка (3 попытки на сектор)
;   POS      позиционировать дорожку D;  TR00  на нулевую дорожку;  DRIVE  дисковод 0/1 (A/B)
;   (раньше - 1024-байтовые секторы #C0..#C4 нестандартного диска; см. src/original/)
READ	DI
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
	DI
	XOR	A
	RET

NXTSEC	INC	E
	LD	A,E
	CP	17
	RET	C
	LD	E,1
	INC	D
	JP	POS

DRIVE	DEFB	0 ;текущий дисковод

POS	LD	A,(DRIVE)
	AND	3
	OR	#3C
	BIT	0,D
	JR	Z,DW_SID
	RES	4,A
DW_SID	LD	C,#FF
	CALL	RG_DOS
	LD	A,D
	SRL	A
	LD	C,#7F
	CALL	RG_DOS
	LD	A,#18
	LD	C,#1F
	CALL	RG_DOS
	CALL	COM_EX
	DI
	RET

RD_SCT	LD	BC,RD_SCT
	PUSH	BC
	LD	BC,#17F
	LD	IX,#2090
	JR	DOS

RG_DOS	LD	IX,#2A53
	JR	DOS

COM_EX	LD	IX,#3EF5
DOS	PUSH	IX
	JP	#3D2F

ERR_RW	SCF
	RET

TR00	DI
	LD	IX,#2F5F
	CALL	DOS
	LD	IX,#2F65
	JP	DOS
