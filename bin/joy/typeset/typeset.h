#ifndef _typeset
#define _typeset

#define MAXCONF 10

#define V_BLACK      0
#define V_SILVER     1
#define V_GRAY       2
#define V_WHITE      3
#define V_MAROON     4
#define V_RED        5
#define V_PURPLE     6
#define V_FUCHSIA    7
#define V_GREEN      8
#define V_LIME       9
#define V_OLIVE     10
#define V_YELLOW    11
#define V_NAVY      12
#define V_BLUE      13
#define V_TEAL      14
#define V_AQUA      15

#define V_BG_BLACK     16
#define V_BG_SILVER    17
#define V_BG_GRAY      18
#define V_BG_WHITE     19
#define V_BG_MAROON    20
#define V_BG_RED       21
#define V_BG_PURPLE    22
#define V_BG_FUCHSIA   23
#define V_BG_GREEN     24
#define V_BG_LIME      25
#define V_BG_OLIVE     26
#define V_BG_YELLOW    27
#define V_BG_NAVY      28
#define V_BG_BLUE      29
#define V_BG_TEAL      30
#define V_BG_AQUA      31

#define V_OVERLINE     (101)
#define V_LINE_THROUGH (102)
#define V_BLINK        (103)

#define V_UNDERLINE    (104)
#define V_BOLD         (105)
#define V_ITALIC       (106)
#define V_CEDILLA      (107)

#define V_UPPER_CASE   (108)
#define V_LOWER_CASE   (109)

#define V_TILDE   (110)
#define V_BREVE   (111)

/*
 * struct config
 *
 */
typedef struct config {
  char *feature;
  char value;
  int style;
  char *name;
  char *description;
} config;

int read_conf(char *);
int set_config(int, char *, char *, int, char *);
int show_config();

extern config *Conf;
extern int nlines;

#endif /* _typeset */
