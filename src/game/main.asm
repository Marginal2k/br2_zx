; *H Чёрный Ворон-2 (С) Медноногов В.С, 1996,97,98
;*L+
;*D-
SCR	EQU	#C000
STARTR	EQU	#FF00 ;старт игры из загрузчика (страница 0, starter.asm)
ATR	EQU	#D800
WMUSIC	EQU	60535
;-----------------------

	MACRO	D_  ;debug
	DI
	PUSH	AF
	LD	A,2
	OUT	(254),A
	POP	AF
	HALT
	EI
	ENDM

	MACRO	M_ p0
	LD	A,p0
	CALL	MEM
	ENDM

	MACRO	EXEX_ 
	DEFB	#00,#00
	ENDM

	MACRO	CALL_ p0
	DEFW	p0-$-2
	ENDM


	MACRO	PUSH_ 
	PUSH	HL
	PUSH	DE
	PUSH	BC
	ENDM
	MACRO	POP_ 
	POP	BC
	POP	DE
	POP	HL
	ENDM

	MACRO	isAVIA_ 
	BIT	7,(IX+dir) ;NZ- авиа
	ENDM

	MACRO	M1toM2_ 
	SET	4,H
	ENDM

	MACRO	M2toM1_ 
	RES	4,H
	ENDM



	ORG	#4000
STKTOP	EQU	#403E	; top of the stack: the 31 words below the IM2 jump #4040
;--------GS----------
typGS	EQU	0
isGS	DEFB	typGS ; GS - подключен: нет-0, иначе-типGS
msgGS	DEFW	0 ;(было: GSinsr - запрос диска с GS; GS-модуль не поддерживается: isGS=0)
;--------/MEM--------
R128	DEFB	%11000
IR128	DEFB	0
;--------- i/o переменные ---
DISK_2	DEFB	1 ;номер дисковода для диска 2
DISK_T	DEFB	0 ;номер дисковода для отгрузок
dSIDE	DEFB	0 ;сторона дискеты
MEM16	DEFW	-1 ;?
tDRIVE	DEFB	1 ;текущ дисковод 0/1
fADR	DEFW	0 ;адр загр ф-ла
;-------- текущ файлы ----
;
_sBUTT	DEFB	0 ; 0-1
_sLAND	DEFB	#FE ; 1-4
_sMUS	DEFB	#FB ; 0-7


	DEFM	"(C)Copper Feet V0.3"

	; ENT $ ;>>>>>
JP_ST	DI
	LD	HL,IM2_TAB ;таблица векторов IM2 (257 байт #40) лежит в странице 2 (не "сжимаемая": нет "снега"), вектор #4040 = JP INTRP
	LD	DE,IM2_TAB+1
	LD	BC,256
	LD	(HL),#40
	LDIR
	LD	A,IM2_I
	LD	I,A
	LD	SP,STKTOP
	IM	2
	JP	_wMAIN

	DEFS	#4040-$ ;стек
	JP	INTRP ;IN #4040
;==================================обслуживание клавиатуры
PRSKEY	PUSH	BC
	LD	C,#FE
	CALL	PRSROW
	POP	BC
	AND	C
	RET

PRSROW	IN	A,(C)
	CPL
	AND	#1F
	RET

CONTR	PUSH_
	LD	A,(KEYJOY)
	OR	A
	JR	Z,CO1
	LD	C,#1F
	CALL	PRSROW
	XOR	#1F
CO2	LD	(CONTRB),A
	LD	A,(PMOUSE)
	OR	A
	CALL	NZ,MOUSE
	POP_
	LD	A,(CONTRB)
	RET
CO1	LD	HL,(KEYS)
	LD	E,0
	LD	D,5
CO3	LD	C,(HL)
	INC	HL
	LD	B,(HL)
	CALL	PRSKEY
	JR	Z,CO4
	SET	5,E
CO4	RRC	E
	DEC	D
	INC	HL
	JR	NZ,CO3
	LD	A,E
	JR	CO2

DELAY	HALT
	DEC	A
	JR	NZ,DELAY
	RET	Z

KBR	DEFW	#DF01,#DF02,#FD01,#FB01,#7F15
INT2	DEFW	#EF08,#EF10,#EF04,#EF02,#EF01
;;KUR	DEFW	#EF04,#F710,#EF10,#EF08,#EF01 ;;;

RND	PUSH	HL
	LD	HL,(RNA)
	INC	HL
;;;	LD	A,R
;;;	ADD	A,H
	LD	A,H ;;;
	AND	#3F ;#1F
	LD	H,A
	LD	A,(RNB)
	RRCA
	XOR	(HL)
	ADD	A,L
	LD	(RNA),HL
	LD	(RNB),A
	POP	HL
	RET

; Переменные уровня (levvars.asm, 268 байт; раньше лежали в странице 2 на #BE50, а там теперь таблица IM2) и сразу за ними таблицы, читаемые со
; сменой только младшего байта адреса (H без изменений: блок TABS..TABSEND обязан целиком лежать в одной 256-байтовой странице). Слот сохранения
; пишет и читает от LEVVARS 2 сектора (512 байт): переменные, таблицы и ещё ~66 байт неизменного кода/данных за ними (как и в v0.04-образе).
TABLEN	EQU	178 ;= TABSEND-TABS (проверяется ASSERT ниже)
	IF	(($ + 268) & #FF) + TABLEN > #100
	DEFS	#100 - (($ + 268) & #FF) ;таблицы начнутся с границы страницы
	ENDIF
	RELOC_	52	; (relocation test hook, see tools/check_reloc.py)
LEVVARS
	INCLUDE "levvars.asm"
	ASSERT	$-LEVVARS==268
;---выровн табл (H-без изменений)------------
TABS
inMAP	DEFW	64,65,1,-63,-64,-65,-1,63 ;for MAKE_R
MLtab1	DEFB	#FF,#7F,#3F,#1F,#F,#7,#3,#1 ;для hLINE
MLtab2	DEFB	#80,#C0,#E0,#F0,#F8,#FC,#FE,#FF
MLtabV	DEFB	#80,#40,#20,#10,#8,#4,#2,#1 ;для vLINE
GO_Nt0	DEFB	0,0 ;центр
GO_Ntb ;смещ по напр y,x;y,x;y,x...  для GO_NXT
	DEFB	0,1,1,1,1,0,1,-1,0,-1,-1,-1,-1,0,-1,1 ; (8)
;---------------------------------------------
GO_Nt2 ;...продолж для расст =2
	DEFB	2,-1,2,0,2,1,-2,1,-2,0,-2,-1
	DEFB	1,2,0,2,-1,2,-1,-2,0,-2,1,-2 ;(20)
;=2max
	DEFB	-2,2,-2,-2,2,-2,2,2 ;(24)
;=3
	DEFB	0,-3,3,0,0,3,-3,0
	DEFB	1,-3,3,1,-1,3,-3,-1
	DEFB	-1,-3,3,-1,1,3,-3,1
	DEFB	2,-3,3,2,-2,3,-3,-2
	DEFB	-2,-3,3,-2,2,3,-3,2 ;(44)
;=3max
	DEFB	-3,3,-3,-3,3,-3,3,3 ;(48)
;=4
	DEFB	0,-4,4,0,0,4,-4,0
	DEFB	1,-4,4,1,-1,4,-4,-1
	DEFB	-1,-4,4,-1,1,4,-4,1
	DEFB	2,-4,4,2,-2,4,-4,-2
	DEFB	-2,-4,4,-2,2,4,-4,2 ;(68)
TABSEND
	ASSERT	TABSEND-TABS==TABLEN
; ---- v0.04 sysTimers (600 bytes at #42B3): probably: SLOWER (delay when SLOW is on), ANIMTR (animation counter, 4 phases), SQROUT: system settings/timers block
	LD	C,L
	LD	H,C
	LD	A,C
	JR	NZ,v4_ANIMTR_1
	ADD	HL,SP
	JR	NZ,v4_SQROUT_1
	INC	SP
	LD	A,(#3934)
	LD	A,(#3630)
	JR	NZ,v4_SQROUT_2
	ADD	HL,SP
	ADD	HL,SP
	ADD	HL,SP
SLOWER
	EI
	XOR	A
	OUT	(#FE),A
	LD	A,(SLOW)
	OR	A
	RET	Z
	LD	HL,MkeDIS+3
	INC	(HL)
	CP	(HL)
	JR	NC,.SLOWER_1
	LD	(HL),#FF
.SLOWER_1
	CCF
	RET
ANIMTR
	LD	A,(isANI)
	OR	A
	RET	Z
	LD	HL,ANIM
	INC	(HL)
	LD	A,(HL)
	CP	#04
	RET	C
	XOR	A
	LD	(HL),A
v4_ANIMTR_1
	RET
SQROUT
	LD	B,D
	LD	C,E
v4_SQROUT_1
	LD	E,(HL)
	INC	L
	LD	D,(HL)
	INC	L
	LD	(SET_SP+1),SP
v4_SQROUT_2
	LD	SP,HL
	LD	L,C
	LD	H,B
	LD	B,#02
.SQROUT_3
	LD	(HL),E
	INC	H
	LD	(HL),D
	INC	H
	POP	DE
	LD	(HL),E
	INC	H
	LD	(HL),D
	INC	H
	POP	DE
	LD	(HL),E
	INC	H
	LD	(HL),D
	INC	H
	POP	DE
	LD	(HL),E
	INC	H
	LD	(HL),D
	POP	DE
	LD	A,L
	ADD	A,#20
	LD	L,A
	LD	A,H
	SUB	#07
	LD	H,A
	LD	(HL),E
	INC	H
	LD	(HL),D
	INC	H
	POP	DE
	LD	(HL),E
	INC	H
	LD	(HL),D
	INC	H
	POP	DE
	LD	(HL),E
	INC	H
	LD	(HL),D
	INC	H
	POP	DE
	LD	(HL),E
	INC	H
	LD	(HL),D
	POP	DE
	LD	A,H
	SUB	#07
	LD	H,A
	LD	A,L
	SUB	#1F
	LD	L,A
	DJNZ	.SQROUT_3
	JP	SET_SP
OU12M1 ;probably: окно карты 12x12 тайлов в DSCR, первый проход (вызов из O12X12)
	LD	HL,(X0)
	CALL	GMAP
	LD	DE,DSCR
	LD	C,#0C
.SQROUT_4
	LD	B,#0C
.SQROUT_5
	PUSH	BC
	PUSH	HL
	PUSH	DE
	CALL	GSADR
	CALL	NC,SQROUT
	POP	DE
	POP	HL
	POP	BC
	INC	E
	INC	E
	INC	HL
	DJNZ	.SQROUT_5
	LD	A,E
	ADD	A,#28
	LD	E,A
	JR	NC,.SQROUT_6
	LD	A,D
	ADD	A,#08
	LD	D,A
.SQROUT_6
	LD	A,L
	ADD	A,#34
	JR	NC,.SQROUT_7
	INC	H
.SQROUT_7
	LD	L,A
	DEC	C
	JR	NZ,.SQROUT_4
	RET
OU12M2 ;probably: окно карты 12x12 тайлов в DSCR, второй проход (вызов из O12X12)
	LD	HL,(X0)
	CALL	GMAP
	LD	DE,DSCR
	LD	C,#0C
.SQROUT_8
	LD	B,#0C
.SQROUT_9
	LD	A,(HL)
	RLA
	JR	NC,.SQROUT_10
	PUSH	BC
	PUSH	HL
	PUSH	DE
	LD	HL,MOVZZ+2
	CALL	SQROUT
	POP	DE
	POP	HL
	POP	BC
.SQROUT_10
	INC	E
	INC	E
	INC	HL
	DJNZ	.SQROUT_9
	LD	A,E
	ADD	A,#28
	LD	E,A
	JR	NC,.SQROUT_11
	LD	A,D
	ADD	A,#08
	LD	D,A
.SQROUT_11
	LD	A,L
	ADD	A,#34
	JR	NC,.SQROUT_12
	INC	H
.SQROUT_12
	LD	L,A
	DEC	C
	JR	NZ,.SQROUT_8
	RET
PXLO
	LD	HL,(X0)
	LD	DE,DSCR+4288
	LD	A,#0B
	ADD	A,H
	LD	H,A
	JR	v4_PXHI_1
PXHI
	LD	HL,(X0)
	LD	DE,DSCR
v4_PXHI_1
	CALL	GMAP
	LD	B,#0C
.PXHI_2
	PUSH	BC
	PUSH	HL
	PUSH	DE
	CALL	GSADR
	CALL	NC,SQROUT
	POP	DE
	POP	HL
	POP	BC
	INC	E
	INC	E
	INC	L
	DJNZ	.PXHI_2
	RET
NXLO
	LD	HL,(X0)
	LD	DE,DSCR+4288
	LD	A,#0B
	ADD	A,H
	LD	H,A
	JR	v4_NXHI_1
NXHI
	LD	HL,(X0)
	LD	DE,DSCR
v4_NXHI_1
	CALL	GMAP
	LD	B,#0C
.NXHI_2
	LD	A,(HL)
	RLA
	JR	NC,.NXHI_3
	PUSH	BC
	PUSH	HL
	PUSH	DE
	LD	HL,MOVZZ+2
	CALL	SQROUT
	POP	DE
	POP	HL
	POP	BC
.NXHI_3
	INC	E
	INC	E
	INC	L
	DJNZ	.NXHI_2
	RET
PYRT
	LD	HL,(X0)
	LD	DE,DSCR+22
	LD	A,L
	ADD	A,#0B
	LD	L,A
	JR	v4_PYLF_1
PYLF
	LD	HL,(X0)
	LD	DE,DSCR
v4_PYLF_1
	CALL	GMAP
	LD	B,#0C
.PYLF_2
	PUSH	BC
	PUSH	HL
	PUSH	DE
	CALL	GSADR
	CALL	NC,SQROUT
	POP	DE
	POP	HL
	POP	BC
	LD	A,E
	ADD	A,#40
	LD	E,A
	JR	NC,.PYLF_3
	LD	A,D
	ADD	A,#08
	LD	D,A
.PYLF_3
	LD	A,L
	ADD	A,#40
	JR	NC,.PYLF_4
	INC	H
.PYLF_4
	LD	L,A
	DJNZ	.PYLF_2
	RET
NYRT
	LD	HL,(X0)
	LD	DE,DSCR+22
	LD	A,L
	ADD	A,#0B
	LD	L,A
	JR	v4_NYLF_1
NYLF
	LD	HL,(X0)
	LD	DE,DSCR
v4_NYLF_1
	CALL	GMAP
	LD	B,#0C
.NYLF_2
	LD	A,(HL)
	RLA
	JR	NC,.NYLF_3
	PUSH	BC
	PUSH	HL
	PUSH	DE
	LD	HL,MOVZZ+2
	CALL	SQROUT
	POP	DE
	POP	HL
	POP	BC
.NYLF_3
	LD	A,E
	ADD	A,#40
	LD	E,A
	JR	NC,.NYLF_4
	LD	A,D
	ADD	A,#08
	LD	D,A
.NYLF_4
	LD	A,L
	ADD	A,#40
	JR	NC,.NYLF_5
	INC	H
.NYLF_5
	LD	L,A
	DJNZ	.NYLF_2
	RET
GMAP
	LD	A,L
	RLCA
	RLCA
	SRL	H
	RRA
	SRL	H
	RRA
	LD	L,A
	LD	A,H
	ADD	A,#80
	LD	H,A
	RET
GMAP2
	LD	A,L
	RLCA
	RLCA
	SRL	H
	RRA
	SRL	H
	RRA
	LD	L,A
	LD	A,H
	ADD	A,#90
	LD	H,A
	RET
shadwS
	LD	A,(isANI+1)
	PUSH	AF
	CALL	MEM1
	POP	AF
	OR	A
	LD	DE,MOVZZ+2
	JR	Z,.shadwS_1
	LD	HL,sbx0+33
	LD	BC,#0020
	LDIR
	RET
.shadwS_1
	LD	A,#FF
	LD	B,#20
.shadwS_2
	LD	(DE),A
	INC	DE
	DJNZ	.shadwS_2
	RET
GSADR
	LD	A,(HL)

;=========================Main procedures================
;*L+
	RELOC_	53
	INCLUDE "lib1a.asm" ;+
	RELOC_	54
	INCLUDE "intv.asm" ;+
	RELOC_	55
	INCLUDE "lid.asm" ;+
	RELOC_	56
	INCLUDE "io.asm" ;диск, загрузка ресурсов, сохранение (disk.asm)
	INCLUDE "startm.asm" ;запуск: стартовое меню, старт уровня
	INCLUDE "demo.asm" ;демо
	RELOC_	57
WFONT
	INCBIN "data/4font.fnt" ;шрифт (912 байт), DATAFONT.FNT автора
	INCLUDE "dzx0.asm"
	INCLUDE "demo2.asm"
	RELOC_	58
	INCLUDE "lib2.asm" ;+
	RELOC_	59
	INCLUDE "sound1.asm" ;+
	INCLUDE "scan.asm"
	RELOC_	60

;-------- переменные -----
;*L+

	INCLUDE "local.asm"
	INCLUDE "var.asm"

; *G
free_m	EQU	#7680-$

	INCLUDE "level.asm"
	NOP



	MMU 3,0	; page 0 at #C000 ;--------------------
	ORG	#C000
	RELOC_	0

	INCLUDE "lia.asm"
	INCLUDE "lic2x.asm"
	INCLUDE "lih.asm"
	INCLUDE "wizard.asm"
	INCLUDE "lif.asm"
	INCLUDE "lig.asm"
	INCLUDE "lib3viz.asm"
	INCLUDE "intel.asm"
	INCLUDE "lib4x.asm"
	INCLUDE "lik1.asm"

; *G
free_0	EQU	0-$

; Стартовая подпрограмма: её вызывает загрузчик (src/start1/loader.asm) со страницей 0 в окне #C000, когда все страницы
; прочитаны. Страница 5 (код игры) лежит в живой странице 2, поэтому они меняются местами; дальше JP_ST.
	ORG	STARTR
	INCLUDE "starter.asm"

;=======================Страницы======================[]
;*L+

	MMU 3,6	; page 6 at #C000 ;--------------------------------------------------6
	ORG	#C000
	INCLUDE "map.asm" ;первый!
;
	INCLUDE "lib3.asm"
	INCLUDE "misc_6.asm" ;доп п/п
	INCLUDE "intel_w.asm"
	INCLUDE "strateg.asm"
;-----


;исполнитель эффектов+AYэффекты
	INCLUDE "sound2.asm"


; *G
free_6	EQU	WMUSIC-$

	IF	typGS==0	; ASM80: typGS=0 (true when 0 / equal)

;*B ..\MUSIC\CROW_B1.MUS ;0
	INCBIN "music/song1c.mus" ;1 +++
;*B ..\MUSIC\SONG2C.MUS ;2 +++
;*B ..\MUSIC\SONG3C.MUS ;3 ++
;*B ..\MUSIC\SONG4C.MUS ;4 ++
;*B ..\MUSIC\SONG5C.MUS ;5 ++
;*B ..\MUSIC\SONG6C.MUS ;6 +
;*B ..\MUSIC\SONG7C.MUS ;7 +++
;*B ..\MUSIC\SONG8C.MUS ;8 +

	ELSE

	INCLUDE "gs_test.asm"

	ENDIF

	MMU 3,7	; page 7 at #C000 ;--------SCR,...-----------------------------------7
	ORG	#C000
;*B ..\pictures\smile.scr

	ORG	#DB00
WBUTT
	IF	(Lmaster)==0	; ASM80: Lmaster (true when 0 / equal)
	INCBIN "data/4h_butt.dat" ;0(*)
	ELSE
	INCBIN "data/4k_butt.dat" ;1
	ENDIF
	INCLUDE "lie.asm" ;+
	INCLUDE "menu2.asm"
; *G
free_7	EQU	0-$

	MMU 3,3	; page 3 at #C000 ;-------спрайты героев ----------------------------3
	ORG	#C000

	INCLUDE "lib2x2i.asm" ;первый!
;---
;---
hr_sh1 ;-- упрощённые тени авиации(1)
hrh9 ;/

; *G
free_3	EQU	0-$

	MMU 3,4	; page 4 at #C000 ;-------спрайты героев ----------------------------4
	ORG	#C000
; ---- v0.04 bullFlameTabs (384 bytes at #C000): probably: page 4: WYbull/vbuXDW/vFLAME: bullet and flame y-tables and drawing code
hrm16
	INCBIN	"data/hero/4krakotn.dat"	; byte-identical to the archive file
hrm12
	INCBIN	"data/hero/4peon.dat"	; byte-identical to the archive file
hrh9_hd
	INCBIN	"data/hero/4tank_hd.dat"	; byte-identical to the archive file
	INCBIN	"hum/4_r0_CD80.bin"	; 2304 bytes of the v0.04 image (no archive file for them)
hrm19
	INCBIN	"hum/hrm19.bin"	; 960 bytes of the v0.04 image (no archive file for them)
	INCBIN	"hum/4_r0_DA40.bin"	; 576 bytes of the v0.04 image (no archive file for them)
hrh0
	INCBIN	"data/hero/4worker.dat"	; byte-identical to the archive file
WM22
	INCBIN	"hum/WM22.bin"	; 2880 bytes of the v0.04 image (no archive file for them)
WM44
	INCBIN	"data/4misc4x4.dat"	; byte-identical to the archive file
WM11
	INCBIN	"data/4misc1x1.dat"	; byte-identical to the archive file
WM33
	INCBIN	"hum/WM33.bin"	; 1296 bytes of the v0.04 image (no archive file for them)
	INCBIN	"hum/4_r0_FA50.bin"	; 432 bytes of the v0.04 image (no archive file for them)
WM12
	INCBIN	"data/4misc1x2.dat"	; byte-identical to the archive file
WYbull
	LD	A,(IX+#00)
	LD	HL,v4_WYbull_13+25
	CALL	DA
	LD	E,A
	INC	HL
	LD	D,(HL)
	INC	HL
	LD	A,(HL)
	INC	HL
	LD	H,(HL)
	LD	L,A
	JP	(HL)
v4_WYbull_1
	LD	A,(TIC)
	AND	#01
	JR	v4_WYbull_4
v4_WYbull_2
	LD	A,(IX+#05)
	DEC	A
	JR	v4_WYbull_4
v4_WYbull_3
	LD	A,(IX+#04)
v4_WYbull_4
	ADD	A,A
	ADD	A,A
	ADD	A,A
	ADD	A,A
	LD	L,A
	LD	H,#00
	ADD	HL,DE
	EX	DE,HL
	LD	BC,#0801
	JP	HeF1
v4_WYbull_5
	LD	A,(IX+#04)
	RRCA
	RRCA
	RRCA
	LD	L,A
	LD	H,#00
	ADD	HL,DE
	EX	DE,HL
	LD	BC,#1001
	JP	HeF1
	LD	A,(TIC3)
	ADD	A,(IX+#01)
	ADD	A,(IX+#02)
.WYbull_6
	CP	#03
	JR	C,v4_WYbull_8
	SUB	#03
	JR	.WYbull_6
v4_WYbull_7
	LD	A,(TIC3)
	JR	v4_WYbull_8
	LD	A,(IX+#05)
	DEC	A
v4_WYbull_8
	RRCA
	RRCA
	LD	L,A
	LD	H,#00
	ADD	HL,DE
	EX	DE,HL
v4_WYbull_9
	LD	BC,#1002
	JP	HeF1
	LD	A,(TIC3)
	JR	v4_WYbull_11
	LD	A,(TIC)
	AND	#01
	JR	v4_WYbull_11
v4_WYbull_10
	LD	A,(IX+#05)
	DEC	A
v4_WYbull_11
	OR	A
	JR	Z,v4_WYbull_13
	CP	#01
	LD	HL,#0090
	JR	Z,.WYbull_12
	ADD	HL,HL
.WYbull_12
	ADD	HL,DE
	EX	DE,HL
	JR	v4_WYbull_13
	LD	A,(TIC)
	RRCA
	RET	C
v4_WYbull_13
	LD	BC,#1803
	JP	HeF1
	LD	A,(TIC3)
	LD	BC,#2004
	OR	A
	JP	Z,HeF1
	INC	D
	DEC	A
	JP	Z,HeF1
	INC	D
	JP	HeF1
	NOP
	ADD	A,B
	NOP
	NOP
	JR	NZ,v4_WYbull_13+19
	RRA
	DEFB	#FD
	NOP
	PUSH	AF
	ADD	HL,DE
	DEFB	#FD
	NOP
	DEFB	#FC,#31,#FD	; data (not code): CALL M,v4_WYbull_5
	RET	NZ
	JP	P,v4_WYbull_3
	NOP
	DEFB	#F4,#12,#FD	; data (not code): CALL P,v4_WYbull_1
	NOP
	DEFB	#F4,#12,#FD	; data (not code): CALL P,v4_WYbull_1
	RET	NZ
	DI
	DEC	HL
	DEFB	#FD
	RET	NZ
	JP	P,v4_WYbull_3
	JR	NZ,v4_WYbull_13+51
	RRA
	DEFB	#FD
	RET	NZ
	DI
	LD	(DE),A
.WYbull_14
	DEFB	#FD
	DEFB	#E0	; data (not code): RET PO
	DI
	DEC	HL
	DEFB	#FD
	RET	NZ
	JP	P,v4_WYbull_3
	JR	NC,.WYbull_14
	DEC	HL
	DEFB	#FD
	LD	D,B
	JP	M,v4_WYbull_10
	NOP
	ADD	A,B
	RRCA
	NOP
	AND	B
	DEFB	#F4,#19,#FD	; data (not code): CALL P,v4_WYbull_2
	AND	B
	DEFB	#F4,#19,#FD	; data (not code): CALL P,v4_WYbull_2
	DEFB	#E0	; data (not code): RET PO
	DEFB	#F4,#19,#FD	; data (not code): CALL P,v4_WYbull_2
	DEFB	#E0	; data (not code): RET PO
	DEFB	#F4,#19,#FD	; data (not code): CALL P,v4_WYbull_2
	RET	NZ
	DEFB	#F4,#19,#FD	; data (not code): CALL P,v4_WYbull_2
	ADD	A,B
	DEFB	#EF	; data (not code): RST #28
	LD	H,E
	DEFB	#FD
	LD	D,B
	JP	M,v4_WYbull_10
	LD	D,B
	JP	M,v4_WYbull_10
	RET	NZ
	XOR	#53
	DEFB	#FD
	RET	NZ
	XOR	#53
	DEFB	#FD
	ADD	A,B
	DEFB	#EC,#53,#FD	; data (not code): CALL PE,v4_WYbull_7
	LD	B,B
	LD	(#00FD),DE
	XOR	#53
	DEFB	#FD
	RET	NZ
	DEFB	#EF	; data (not code): RST #28
	SUB	E
	DEFB	#FD
	RET	P
	DI
	DEC	HL
	DEFB	#FD
	ADD	A,B
	DEFB	#E8	; data (not code): RET PE
	LD	H,E
	DEFB	#FD
	RET	NZ
	DEFB	#E8	; data (not code): RET PE
	LD	B,D
	DEFB	#FD
	ADD	A,B
	JP	(HL)
	LD	H,E
	DEFB	#FD
	RET	NZ
	JP	(HL)
	LD	H,E
	DEFB	#FD
	NOP
	DEFB	#EA,#63,#FD	; data (not code): JP PE,v4_WYbull_9
	LD	B,B
	DEFB	#EA,#53,#FD	; data (not code): JP PE,v4_WYbull_7
	NOP
	EX	DE,HL
	LD	H,E
	DEFB	#FD
	LD	B,B
	EX	DE,HL
	LD	H,E
	DEFB	#FD
	ADD	A,B
	EX	DE,HL
	LD	H,E
	DEFB	#FD
	ADD	A,B
	EX	DE,HL
	LD	H,E
	DEFB	#FD
	RET	NZ
	EX	DE,HL
	LD	E,B
	DEFB	#FD
	LD	B,B
	DEFB	#EC,#63,#FD	; data (not code): CALL PE,v4_WYbull_9
	NOP
	ADD	A,B
	DEC	HL
	NOP
	RET	P
	OR	#69
	DEFB	#FD
	RET	P
	OR	#69
	DEFB	#FD
	LD	B,B
	PUSH	AF
	ADC	A,L
	DEFB	#FD
	LD	B,B
	PUSH	AF
	ADC	A,L
	DEFB	#FD
	AND	B
	RET	M
	LD	L,(HL)
	DEFB	#FD
	AND	B
	RET	M
	LD	L,(HL)
	LD	IYH,B
	OR	#8D
	LD	IYH,B
	OR	#8D
	DEFB	#FD
	RET	NC
	PUSH	AF
	ADC	A,B
	DEFB	#FD
	RET	NC
	PUSH	AF
	ADC	A,B
	DEFB	#FD
vbuSORT
	LD	DE,hrm19+384
	JR	v4_vbuXDW_1
vbuYLF
	LD	A,#D8
	LD	HL,#1000
	JR	v4_vbuYRT_1
vbuYRT
	LD	A,#FF
	LD	HL,hrm16+152
v4_vbuYRT_1
	LD	DE,hrm19+384
	JR	v4_vbuXDW_2
vbuXUP
	LD	DE,#2800
	JR	v4_vbuXDW_1
vbuXDW
	LD	DE,#D8B0
v4_vbuXDW_1
	LD	A,#D8
	LD	HL,hrm16
v4_vbuXDW_2
	CALL	.vbuXDW_9
	LD	IX,KBUILD+260
	LD	B,#2C
.vbuXDW_3
	LD	A,(IX+#00)
	OR	A
	JR	Z,.vbuXDW_7
	LD	L,(IX-#04)
	LD	H,(IX-#03)
	LD	DE,(_X0pos)
	ADD	HL,DE
	LD	A,H
	OR	A
	JR	NZ,.vbuXDW_4
	LD	A,L
	CP	#00
	JR	NC,.vbuXDW_7
	CP	#00
	JR	C,.vbuXDW_7
	JR	.vbuXDW_5
.vbuXDW_4
	INC	A
	JR	NZ,.vbuXDW_7
	LD	A,L
	CP	#00
	JR	C,.vbuXDW_7
.vbuXDW_5
	LD	L,(IX-#02)
	LD	H,(IX-#01)
	LD	DE,(_Y0pos)
	ADD	HL,DE
	LD	A,H
	OR	A
	JR	NZ,.vbuXDW_7
	LD	A,L
	CP	#00
	JR	NC,.vbuXDW_7
	CP	#00
	JR	C,.vbuXDW_7
	LD	E,L
	LD	A,(IX+#00)
	LD	HL,.vbuXDW_9+20
	CALL	BA
	CP	#01
	JR	Z,.vbuXDW_6
	LD	E,A
.vbuXDW_6
	LD	D,#B8
	LD	A,(DE)
	EXX
	PUSH	IX
	POP	DE
	LD	(HL),E
	INC	L
	LD	(HL),D
	INC	L
	LD	(HL),A
	LD	A,L
	INC	L
	EXX
	LD	(DE),A
	JR	Z,.vbuXDW_8
.vbuXDW_7
	LD	DE,#000C
	ADD	IX,DE
	DJNZ	.vbuXDW_3
.vbuXDW_8
	XOR	A
	LD	L,A
	LD	H,A
	LD	D,A
	LD	E,A
.vbuXDW_9
	LD	(.vbuXDW_4+5),A
	LD	A,L
	LD	(.vbuXDW_3+27),A
	LD	A,H
	LD	(.vbuXDW_3+23),A
	LD	A,E
	LD	(.vbuXDW_5+21),A
	LD	A,D
	LD	(.vbuXDW_5+17),A
	RET
	NOP
	LD	BC,#01D8
	RET	C
	RET	C
	RET	C
	RET	C
	JP	C,#D801
	RET	C
	JP	C,#D8D9
	NOP
	RET	C
	JP	C,#DAD8
	RET	C
	RET	C
	RET	C
	JP	C,#DAD8
	RET	C
	RET	C
	RET	C
	RET	C
	RET	C
	LD	BC,#0101
	LD	BC,#0001
	LD	BC,#0101
	LD	BC,#0101
	NOP
	RET	C
	JP	C,#DAD8
	RET	C
	JP	C,#DAD8
	RET	C
	DEFB	#DA
vFLAME
	LD	HL,brNUM
	LD	A,(HL)
	OR	A
	RET	Z
	LD	B,A
v4_vFLAME_1
	INC	HL
	PUSH	BC
	PUSH	HL
	LD	A,(HL)
	CALL	B_IX
	LD	A,(IX+#06)
	SRL	A
	CP	(IX+#03)
	LD	A,#1B
	JR	C,.vFLAME_2
	INC	A
.vFLAME_2
	LD	(datMIN+247),A
	CALL	HL_IX0
	DEC	H
	LD	A,(IX+#02)
	INC	A
	PUSH	AF
	LD	IX,datMIN+247
	XOR	A
	CALL	NEWix_
	POP	AF
	LD	HL,fr3x3H+11
	CALL	WT
	EX	DE,HL
	CALL	CORix_
	LD	A,#02
	OR	A
	CALL	_XPUT
	LD	HL,(datMIN+245)
	LD	DE,fr2x2L+16
	ADD	HL,DE
	LD	(datMIN+245),HL
	LD	A,#1A
	LD	(datMIN+247),A
fr3x3H
	LD	A,#02
	OR	A
	CALL	_XPUT
	POP	HL
	POP	BC
	DJNZ	v4_vFLAME_1
	RET
	NOP
	LD	(BC),A
	NOP
	EX	AF,af'
	RST	#38
	LD	(BC),A
	NOP
fr3x3L
	INC	BC
	RST	#38
	DEC	B
	NOP
	LD	(BC),A
	NOP
	CP	#01
	NOP
	INC	BC
	NOP
	NOP
	LD	(BC),A
	DEC	B
	EX	AF,af'
	NOP
	LD	(BC),A
	EI
fr2x2H
	DJNZ	.fr2x2H_1
.fr2x2H_1
	CP	#00
	NOP
	NOP
	ADD	HL,BC
	RST	#38
	CP	#00
	NOP
	NOP
fr2x2L
	DEFS	32

;----спрайты/вывод пуль, взр, предм
;
	INCLUDE "lik2.asm" ;в одной странице с WMISCxx

;
;селект-рамки----
;

;

; *G
free_4	EQU	0-$

	MMU 3,1	; page 1 at #C000 ;---Cпрайты ландшафта------------------------------1
	ORG	#C000
LAND ;ландшафт
shadwA	EQU	(101*32)+LAND
SHADOW	EQU	(411*32)+LAND
	IF	L_land==0	; ASM80: L_land=0 (true when 0 / equal)
	DEFS	13184,#CF ;0
	ENDIF
	IF	L_land==1	; ASM80: L_land=1 (true when 0 / equal)
	INCBIN "data/41spr.dat" ;1(*)
	ENDIF
	IF	L_land==2	; ASM80: L_land=2 (true when 0 / equal)
	INCBIN "data/42spr.dat" ;2
	ENDIF
	IF	L_land==3	; ASM80: L_land=3 (true when 0 / equal)
	INCBIN "data/43spr.dat" ;3
	ENDIF
	IF	L_land==4	; ASM80: L_land=4 (true when 0 / equal)
	INCBIN "data/44spr.dat" ;4
	ENDIF
	IF	L_land==5	; ASM80: L_land=5 (true when 0 / equal)
	INCBIN "data/45spr.dat" ;5
	ENDIF


hrh3
	INCBIN "data/hero/4soldier.dat"
; ---- v0.04 WNAMES (1890 bytes at #F780): page 1: table of the building/unit names (WNAMES, 1890 bytes, text with the 4FONT codes)
WNAMES
	INCBIN	"hum/WNAMES.bin"	; 1890 bytes of the v0.04 image (no archive file for them)
	INCBIN	"hum/1_r2_FEE2.bin"	; 286 bytes of the v0.04 image (no archive file for them)
hr_sh2 ;-- упрощённые тени авиации(2)

; *G
free_1	EQU	0-$


	MMU 3,0	; page 0 at #C000 ;==================================================[]

; *G
fre_SUM	EQU	free_m+free_0+free_1+free_3+free_4+free_6+free_7

;форматы данных
x	EQU	0
y	EQU	1
dir	EQU	2
phase_	EQU	3
typ	EQU	4
health	EQU	5
energy	EQU	6
speed	EQU	7
move	EQU	8
com	EQU	9
tarX	EQU	10
tarY	EQU	11
tarN	EQU	12
prof	EQU	13
Xwood	EQU	14
Ywood	EQU	15
;
oldtyp	EQU	com
