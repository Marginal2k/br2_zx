; Чёрный Ворон 2: демонстрационный режим (заставка). Восстановлено по _OLD/__DEMO.A80 автора: случайный бой.
; У автора DEMO вызывал свой игровой цикл NNN_D и не хватало ANIset, IX_93 (= IX_amov: "иди и атакуй"), makTRY (счётчик
; трассировок MAKE_R; в v0.04 он не используется). Здесь демо идёт в обычном игровом цикле (NNN): wDEMO (startm.asm)
; ставит DEMOF и запускает уровень людей; NNNHK (вместо LD SP,STKTOP в начале цикла) при DEMOF
;   - выходит в меню (wMENU) по нажатию любой клавиши,
;   - не даёт кунгам умереть (d_LIFE), приказывает всем людям идти в атаку (d_CTRL) и по TIC=1 вводит новых кунгов (d_NEW).
DEMOF	DEFB	0 ;1 - идёт демо

NNNHK	POP	HL ;адрес возврата
	LD	SP,STKTOP
	LD	A,(DEMOF)
	OR	A
	JP	Z,d_OUT
	PUSH	HL
	LD	BC,#00FE ;любая клавиша: все полуряды разом
	IN	A,(C)
	CPL
	AND	#1F
	JR	NZ,d_EXIT
	CALL	d_LIFE
	CALL	d_CTRL
	CALL	d_NEW
	POP	HL
d_OUT	JP	(HL)
d_EXIT	XOR	A
	LD	(DEMOF),A
	JP	wMENU

d_NEW	LD	A,(TIC)
	CP	1
	RET	NZ
	LD	A,R
	LD	C,13
	AND	2
	JR	Z,d_N1
	DEC	C
d_N1	CALL	RND
	AND	15
	INC	A
	LD	B,A
	LD	A,R
	AND	15
	ADD	A,16
	LD	L,A
	LD	H,16
d_N2	PUSH	HL
	PUSH	BC
	CALL	stayON
	POP	BC
	PUSH	BC
	LD	A,C
	EX	AF,AF'
	LD	A,1 ;кунг
	CALL	NEWHER
	JR	NZ,d_N3
	LD	(IX+10),24
	LD	(IX+11),30
	CALL	IX_amov
d_N3	POP	BC
	POP	HL
	DJNZ	d_N2
	RET

; DEMO: включить демо (дальше wGAME)
DEMO	LD	A,1
	LD	(DEMOF),A
	RET
