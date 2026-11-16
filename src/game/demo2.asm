; демо: d_LIFE, d_CTRL (вызываются из NNNHK, demo.asm); лежат после ZX0 - в основном месте не хватило 40 байт
d_LIFE	LD	HL,KUNGE+5 ;первые 10 кунгов бессмертны (здоровье 200)
	LD	DE,_LHER
	LD	B,10
d_L1	LD	(HL),200
	ADD	HL,DE
	DJNZ	d_L1
	RET

d_CTRL	CALL	loop_H ;люди без приказа идут в атаку на (24,30)
d_C2	LD	A,(IX+9)
	OR	A
	JR	NZ,d_C1
	LD	(IX+10),24
	LD	(IX+11),30
	PUSH	BC
	PUSH	DE
	CALL	IX_amov
	POP	DE
	POP	BC
d_C1	ADD	IX,DE
	DJNZ	d_C2
	RET


; IX_start из 4.Z80 (в v0.04 его тело удалено, а CALL #0000 остались): цель героя IX := его позиция и "иди" (без смены com)
IXSTRT	CALL	HL_IX0
	CALL	IXt_HL
	JP	ix_93a
