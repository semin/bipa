typedef union{
	long	ival;
	float	fval;
	char	*sval;
	char    cval;
} YYSTYPE;
#define	COMMENT	257
#define	T_BLACK	258
#define	T_SILVER	259
#define	T_GRAY	260
#define	T_WHITE	261
#define	T_MAROON	262
#define	T_RED	263
#define	T_PURPLE	264
#define	T_FUCHSIA	265
#define	T_GREEN	266
#define	T_LIME	267
#define	T_OLIVE	268
#define	T_YELLOW	269
#define	T_NAVY	270
#define	T_BLUE	271
#define	T_TEAL	272
#define	T_AQUA	273
#define	T_UNDERLINE	274
#define	T_OVERLINE	275
#define	T_LINE_THROUGH	276
#define	T_BLINK	277
#define	T_BOLD	278
#define	T_ITALIC	279
#define	T_CEDILLA	280
#define	T_UPPER_CASE	281
#define	T_LOWER_CASE	282
#define	T_TILDE	283
#define	T_BREVE	284
#define	T_INT	285
#define	T_STRING	286
#define	T_CHAR	287
#define	T_FLOAT	288


extern YYSTYPE tplval;
