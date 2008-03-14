#ifndef __gen_rtf
#define __gen_rtf

#define RTF_SUFFIX ".rtf"

#define T_BLACK      0
#define T_BLUE       1
#define T_RED        2
#define T_MAROON     3
#define T_WHITE      4
#define T_YELLOW     5

#define T_BOLD      10
#define T_UNDERLINE 11
#define T_ITALIC    12

int gen_rtf(ALIFAM *, char **, TEM *, PSA *,
	    int *, int);
int *set_tag(html_style *, int);

int show_aa(int, TEM *, int, html_style *, int, int,
	    char, FILE *);

int show_consensus(FILE *, int, int, char *, int);

int write_rtfheader(FILE *);

#endif
