typedef union{
	long	ival;
	float	fval;
	char	*sval;
} YYSTYPE;
#define	COMMENT	257
#define	T_FEATURE_SET	258
#define	T_TEM	259
#define	T_HTML	260
#define	T_PS	261
#define	T_RTF	262
#define	T_DEVICE	263
#define	T_DIR	264
#define	T_SEG	265
#define	T_KEY	266
#define	T_CHECK	267
#define	T_SEQCOLOUR	268
#define	T_DOMAIN	269
#define	T_CONSENSUS_SS	270
#define	T_ALIGNMENT_POS	271
#define	T_PSACUTOFF	272
#define	T_NWIDTH	273
#define	T_MAXCODELEN	274
#define	T_FONTSIZE	275
#define	T_PSFONT	276
#define	T_PSCOLOUR	277
#define	T_BGCOLOR	278
#define	T_LC	279
#define	T_SEQFONTSIZE	280
#define	T_WYG_FLOAT_PRECISION	281
#define	T_INT	282
#define	T_STRING	283
#define	T_FLOAT	284


extern YYSTYPE yylval;
