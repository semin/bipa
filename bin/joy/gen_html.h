#ifndef __gen_html
#define __gen_html

#define HTML_SUFFIX ".html"

typedef struct html_style {
  int feature;
  char value;
  int num;
  char *name;
  char *description;
} html_style;

int gen_html(ALIFAM *, char **, TEM *, PSA *, int *, int);
int *set_tag_html(html_style *, int);
int write_htmlheader(FILE *, html_style *, int, char *);
int show_aa_in_html(int, TEM *, int, html_style *, int, int,
		    char, FILE *);
char isBreak(char *, int);

html_style *set_style(TEM *);
int code_width (int, ALI *);
int write_key(html_style *, int, FILE *);

int get_label_strnum(int, char **, char *);
int get_label_seqnum(int, ALI *, char *);
char *consensus_ss(ALIFAM *, int, char **, TEM *, int);
int *domain_display(int, int);
int define_domcolour(FILE *, int);
int define_bgcolour(html_style *, FILE *);
int define_text_decoration(html_style *, FILE *);
int write_dom(FILE *, int, int, int, int *);
int write_alignpos(FILE *, int, int, int);
int show_substr(char *, int, FILE *);

struct ColorScheme {
  char *name;             /* name of the colour scheme */
  int bg_number;          /* number of colors used */
  int residue[26];        /* group information for 26 letters */
  char colorname[26][20]; /* name of background color */
  char colors[26][20];    /* definition of background color */
};

#define SCHEME_NUMBER 3
#define FG_NUMBER 3
#define FONT_FG_BEGIN  "<FONT color="
#define FONT_END       "</FONT>"
#define SS             "secondary structure"
#define COLOUR_SEQTITLE "blue"
#define COLOUR_SSTITLE  "red"

int define_bgcolour_for_seq(FILE *);
void colour_seq(char, int, FILE *);
int colour_ss(char, FILE *);

#endif
