;чв2*********************************************************
;**************** локальные переменные	*********************
;;*L+
;Interupt entry
INTRS	LD	SP,#0000
	EI
INTRQ	JP	#0000
;/CONTRL
CONTRB	DEFS	1	; DEFB ? ;0
;/RND
RNA	DEFW	911
RNB	DEFB	22
;/XDLPZ
DLPCB	DEFM	"Xuxu"

;/ROTATE
isROT	DEFB	0 ;идёт скролл?
;/SW_OFF
isSWFF	DEFB	0 ;1-погасить курсор

;/OU_MAP
delMAP	DEFB	0 ;задержка на выв карты

;/MANUAL
Z_LOCK	DEFB	1 ;"Z" нажата?
T_FIRE	DEFB	0 ;тип нажатого FIRE (0-none,1-space,2-caps)
fixTAR	DEFB	0 ;1-цель зафиксирована
fixPOS	DEFB	0 ;1-позиция зафиксирована

;/BLITER
V_LINE	DEFS	1	; DEFB ? ;0 ;текущ выв линия
V_FLAG	DEFB	0 ;режим отобр курсора: 0-norm, 1-refresh, 2-none
P_FLAG	DEFB	0 ;если 1, выполнить отображение курсора
;/V_...
G_MX	DEFS	1	; DEFB ? ; 010
G_MY	DEFS	1	; DEFB ? ; 010
G_SIZE	DEFB	8 ;высота курс
G_IMG	DEFW	G_MAP1 ;изобр курс
GBU1	DEFS	16	; ASM80 DEFR: random fill ;копия из SCR
; ---- v0.04 gameVars (1116 bytes at #7462): probably: variables of the game (GBAD1 ... Yh): initial values of v0.04 (assembler fill in the places marked DEFR)
GBAD1
	DEFB	#01,#00
GBU2
	DEFB	#20,#3B,#36,#07,#CD,#A5,#DA,#CD,#07,#CC,#CD,#C3,#21,#22,#FA,#7E
GBAD2
	DEFB	#01,#00
SHIFTh
	DEFB	#00
IMGh
	DEFB	#00,#FE,#00,#00
Xh
	DEFB	#0A
Yh
	DEFB	#0B
Wh
	DEFB	#02
Hh
	DEFB	#10,#10
DEEP
	DEFB	#40
MINLEN
	DEFB	#00
MINDIS
	DEFB	#00
NROUND
	DEFB	#02
DEEP_2
	DEFB	#00
ss_num
	DEFB	#05
ss_pos
	DEFB	#04,#00
ss_dir
	DEFB	#00
srcTYP
	DEFB	#00
srcIXt
	DEFB	#00,#00
MAXSRC
	DEFB	#00
MAXDIR
	DEFB	#01
MAXDIS
	DEFB	#00
MAXPOS
	DEFB	#00,#00
MAXTRU
	DEFB	#01
s2_num
	DEFB	#05
s2_pos
	DEFB	#04,#00
MkeDIS
	DEFB	#FE,#04,#C9,#00
SCRADR
	DEFB	#C0
ATRADR
	DEFB	#D8
PUTsHL
	DEFB	#00,#00
FONT
	DEFW	WFONT
HER_N
	DEFB	#09
SIDE_N
	DEFB	#00
en_IX
	DEFB	#00,#00
en_A
	DEFB	#00
COORD
	DEFB	#7F,#88
OLDCO
	DEFB	#0E,#00
MXOLD
	DEFB	#00,#00
ENDX
	DEFB	#F8
MtSTEP
	DEFB	#01
PX
	DEFB	#01,#02
BCAP
	DEFB	#00
BENTER
	DEFB	#01
BXOLD
	DEFB	#13,#63
UBY
	DEFB	#02
BATR
	DEFB	#00,#00
BADR
	DEFB	#00,#00
B_ABUF
	DEFB	#00,#35,#B7,#28,#CE,#DD,#7E,#0F,#B7
BX
	DEFB	#02
BY
	DEFB	#00
UATR
	DEFB	#01,#00
UADR
	DEFB	#00,#00
U_ABUF
	DEFB	#00
U_BUF
	DEFB	#CA,#08,#41,#4F,#21,#61,#71,#35
B_ONOF
	DEFB	#00
BMX
	DEFB	#00,#01
LMask
	DEFB	#CC,#0A
SyLOCK
	DEFB	#00
begBOX
	DEFB	#00
BOXX
	DEFB	#1E,#28
typBOX
	DEFB	#01
I_LOCK
	DEFB	#00
diXSEL
	DEFB	#05
diYSEL
	DEFB	#05
minSEL
	DEFB	#F1
indSEL
	DEFB	#78
W_LOCK
	DEFB	#00
selGR1
	DEFB	#00,#00
_n_FUN
	DEFB	#FF
N_FUNC
	DEFB	#FF
N_FUN1
	DEFB	#FF
F_FUNC
	DEFB	#FF
SEL_Av
	DEFB	#00
MONEY1
	DEFB	#00,#50
MAZUT1
	DEFB	#50,#01
IND1
	DEFB	#7F,#91
IND2
	DEFB	#0A,#43
IND2TP
	DEFB	#02
INDNbu
	DEFB	#FF
MSElog
	DEFB	#C9,#4E,#52
_BUT_H
	DEFB	#FF,#FF,#FF,#FF,#FF,#FF,#FF,#00
BUT_H
	DEFB	#00
BUT_N
	DEFB	#00,#00,#00,#00,#00,#00,#50,#01,#50,#01,#00,#48,#10,#01,#01,#00
	DEFB	#50,#00,#50,#02,#01,#10,#50,#21,#00,#00,#10,#00,#01,#00
ext_M
	DEFB	#00
_event
	DEFB	#00
ONSEE
ONSEEx
	DEFB	#C3,#61,#F9
ONSEE2
	DEFB	#C3,#55,#F9
MNYcrc
	DEFB	#03
ZZ00
	DEFB	#C3,#60,#E8

;/X_PUT - параметры спрайта

;/MAKE_R/MAKE_X


;/SEARCM

;/SLOWER

;/wGrLib


;/SHEDUL

;/MOVING

;/hSCAN/kSCAN

;/MMOV
MX	EQU	COORD
MY	EQU	MX+1

;/работа с курсором


;/hLINE

;/flpSEL
;/capSEL
;/oneSEL
;/swpSEL
;/selGRP

;/SELECT

;/dXYpm2

;/ресурсы

;/oINDY

;/MOUSE


;/Кнопки: внутр. перем
;/Кнопки: номера
;/Кнопки: деньги&леc			  ]

;/BUTING

;/ONSEE/ONSEE2

;/aMONEY/dMONEY/setCRC/chkCRC

;/ZZ0

;/MAGICIAN


;/ZZ6
BrMAZUT	DEFB	20 ;число ударов при добыче мазута

;/QSC
QSC	JP	v4_mmfon_4+8

;/BCD
DCstr	DEFB	#91,#8B,#80,#82,#80	; "СЛАВА"
	DEFB	#7F
;/SAVlev
TXMgme	DEFB	20,51,64,48,91,0,0,0,127

;/peonN
peon_W	DEFS	1	; DEFB ? ;число мазутчиков врага	\
	DEFS	1	; DEFB ? ;число металлодобытчиков /


;/ZZ33
ZZ33gn	DEFS	1	; DEFB ? ;rand  -поколение при утроении

;/ZZtimer
zzXsub	DEFS	1	; DEFB ? ;номер п/п обработки долгого заклинания

;/vFLAME
brNUM	DEFB	0 ;к-во поврежд зданий
brBLT	DEFS	24	; ASM80 DEFR: random fill ;список повреждённых зданий

;PUSHdfndr/POPdfndr
DfSTlen	EQU	10 ;макс размер стека
;формат: +0-тип, +1,+2-XY
DfSTACK	DEFS	DfSTlen*3	; ASM80 DEFR: random fill ;основной стек запоминания погибшей охраны
	DEFS	2*3	; ASM80 DEFR: random fill ;дополнительный (для запоминания шатлов)
; ---- v0.04: code removed

;----------параметры героев----

;/BUTING

hMSG ;назв героев

;/HERMOV
HvTHs ;скорость гориз перемещ
	DEFB	3,2,2,2,#2,3,1,2,2,-1,-1,-1
HvTDs ;cкорость диаг перемещ
	DEFB	2,2,2,2,2,2,0,2,2,#1,-1,-1
	DEFB	2,2,2,2,#2,3,1,2,2,-1,-1,-1
; ---- v0.04: changed/new code or data (4.Z80: ([0]пеон(12)) ([1]кракотун(16)) ([2]демон(17)))
FORCE
	DEFB	#01,#00,#03,#00,#07,#00
BFORCE
	DEFB	#00,#00,#02,#00,#04,#00,#02,#00,#07,#00,#02,#00,#07,#00,#0A,#00
	DEFB	#04,#00,#02,#00,#06,#00,#10,#00,#04,#00,#32,#00,#96,#00,#02,#00
	DEFB	#DC,#00
DEFENC ;probably: параметры защиты (10 байт на тип, 10 типов; части перезаписываются по улучшениям: LD (DEFENC+n),A в map.asm AI-блоке); данные образа v0.04, не код
	DEFB	0,0,0,0,0,0,0,0,2,0
	DEFB	0,0,0,0,0,0,0,0,0,0
	DEFB	2,0,0,0,0,0,0,1,0,2
	DEFB	3,0,1,2,2,1,0,0,0,1
	DEFB	0,2,3,0,1,2,2,1,0,0
	DEFB	0,3,1,4,6,2,3,5,3,0
	DEFB	1,0,0,3,1,4,6,2,3,5
	DEFB	3,0,5,4,4,6,5,5,7,#0A
	DEFB	5,5,5,5,5,4,4,6,5,5
	DEFB	7,#0A,5,9,9,9,#FE,6,#C9,#0E
fram
	DEFB	#00
X0
	DEFB	#14
Y0
	DEFB	#28
_X0pos
	DEFB	#00,#00
_Y0pos
	DEFB	#05,#00,#00
ANIM
	DEFB	#01
COLRsc
	DEFB	#60
MCOLOR
	DEFB	#05
LEV_T
	DEFB	#00
TIC6
	DEFB	#05
TIC3
	DEFB	#01
TIC
	DEFB	#00
isMAP
	DEFB	#00
SET_SP
	DEFB	#31,#00,#00,#C9
JP_SUB
	DEFB	#C3,#00,#00,#00
RESULT
	DEFB	#00,#00,#00,#2B,#00,#00,#7F,#00,#00,#00,#2B,#00,#00
KEYS
	DEFB	#92,#40
KEYJOY
	DEFB	#00
PMOUSE
	DEFB	#00,#00
MUSONF
	DEFB	#00,#01
isCOLR
	DEFB	#01
aviSHD
	DEFB	#01
SAVDSK
	DEFB	#00,#01,#28
M_STEP
	DEFB	#03
SLOW
	DEFB	#00
isANI
	DEFB	#01,#01
DSK_GS
	DEFS	33
WBAR	EQU	#7680	;(раньше здесь был рисунок панели 4bar.dat, 1536 байт: теперь читается с диска в DSCR, putBAR; на его месте HUMAN)
	ASSERT	$<=WBAR
	IFDEF TRAPS ;отладочная сборка: счётчики прохода через бывшие CALL #0000 (см. docs/NOTES.md)
HITS	DEFS	4
TRA0	LD	A,HITS/256
	LD	(HITS),A
	JP	IX_amov
TRA1	LD	(HITS+1),A
	JP	IX_amov
TRA2	LD	(HITS+2),A
	JP	IXSTRT
TRA3	LD	(HITS+3),A
	JP	IX_mov
	ENDIF
	DEFS	#8000-$ ;переменные ниже (RESUL_, TIC_UP ...) лежат с #8000, в MAP, как в v0.04

;/IMPACT
;DATA: defb max_force, defb level (0..max, 2..min)

;/SHED_p /BMPACT
;DATA: defb max_force, defb level (0..max, 2..min)
;
;--------------
;---advanced


;/(x/4-вероятность снижения силы удара в двое)


;/ONSEE
sRANGE ;дальность видимости(+2)

sSCAN ;дальность сканирования  (0-не сканир)


;------------технические параметры-----

TIC_UP	; (в v0.04 код удалён, метка сохранена для ссылок)

;-------- общие параметры игры -------

;наличие заклинаний - передаются от уровня к уровню

RESUL_	; (в v0.04 код удалён, метка сохранена для ссылок)

;--------------Параметры настройки игры---





;-------
