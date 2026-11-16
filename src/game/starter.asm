; STARTR: A = дисковод, с которого загружена игра (от загрузчика); страница 0 в окне #C000, прерывания запрещены.
	DI
	EX	AF,AF'
	LD	HL,#4000
	LD	DE,#8000
swp5_2	LD	C,(HL) ;обмен страниц 5 и 2
	LD	A,(DE)
	LD	(HL),A
	LD	A,C
	LD	(DE),A
	INC	HL
	INC	DE
	LD	A,D
	CP	#C0
	JR	C,swp5_2
	EX	AF,AF'
	LD	(tDRIVE),A
	JP	JP_ST
