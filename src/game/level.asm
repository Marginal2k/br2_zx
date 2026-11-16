Lmaster	EQU	0	; v0.04 Human campaign (BR2HUM04)
L_land	EQU	5	; landscape 45SPR.DAT

;*D-
;уровень xx-xx

LEVDAT	EQU	#8000 ;адр. нач данных уровня
IM2_I	EQU	#BA ;I = старший байт IM2_TAB (#BA00)
	ORG	LEVDAT

_NHER	EQU	48 ;число героев
_NSLAV	EQU	5 ;число пленников
_NALL	EQU	(_NHER*2)+_NSLAV
_LHER	EQU	24 ;длина записи героя

_NBUL	EQU	44 ;макс число пуль/снарядов/предметов
_LBUL	EQU	12 ;длина записи пули
;------ Основных структуры данных ---

_HUMAN	EQU	#7680 ; DEFS 48*_LHER   ;from #7680
_KUNGE	EQU	#7B00 ; DEFS 48*_LHER   ;from #7B00
_SLAVE	EQU	#7F80 ; DEFS 5*_LHER    ;from #7F80
;from #7FF8 <место для проверки легальности уровня>
MAP	EQU	#8000 ; DEFS #1000	    ;from #8000
MAP2	EQU	#9000 ; DEFS #1000	    ;from #9000
DSCR	EQU	#A000 ; DEFS #1800	    ;from #A000

HUMAN	EQU	_HUMAN+4
KUNGE	EQU	_KUNGE+4
SLAVE	EQU	_SLAVE+4
	INCBIN	"hum/M_r6161_8000.bin"	; MAP: карта уровня людей (4096 байт; уровень MAP_10 в редакции v0.04)
datSCR	EQU	MAP2	; (раньше здесь лежал рисунок и задание уровня 10240 байт - в v0.04 не показываются)
	DEFS	10240
datMIN
	INCBIN	"hum/datMIN.bin"	; BUF512: 16 байт параметров шахт + datHER (расстановка героев уровня)
; Таблица векторов IM2 (257 байт #40) - в странице 2: она не "сжимаемая", поэтому ULA не рисует "снег" (I = IM2_I). Вектор #4040 = JP INTRP.
; Раньше таблица лежала на #4100 (страница 5, сжимаемая); а здесь, на #BA00, были MINE, HBUILD, KBUILD, пули и переменные уровня:
; массивы сдвинуты вверх (до #BF90), переменные уровня (isRUNL ... zzzEND, 268 байт) перенесены в страницу 5 (levvars.asm).
IM2_TAB	DEFS	257,#40
	DEFS	63
MINE	DEFS	64 ;шахты (8 записей по 8 байт), здания людей HBUILD (32), кунгов KBUILD (32): номер здания 0..71 - подряд, поэтому лежат вместе
HBUILD	DEFS	256
KBUILD	DEFS	784 ;дальше (KBUILD+256) - пули _BULL

; *G
mem_tsk	EQU	#C000-pcLOOP

; ================= Kunge campaign: data of the level (the Human data above are overwritten) =================
MENUOV	EQU	DSCR ;код меню (menu.asm) на диске; читается в рабочий экран, пока идёт меню
