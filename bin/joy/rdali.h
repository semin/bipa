#ifndef __rdali
#define __rdali

#define LABEL     (0)
#define TEXT      (1)
#define SEQUENCE  (2)
#define STRUCTURE (3)
#define SPACE_CHAR '.'

#define FAMILY "family:"
#define CLASS  "class:"

typedef struct char_list {
  char data;
  struct char_list *next;
} char_list;

typedef struct PIR {
  char *code;
  char *title;
  char *sequence;
} PIR;

typedef struct SEG {
  char strt_chain;
  char strt_pdbres[6];
  char end_chain;
  char end_pdbres[6];
  int  strt_seqnum;
  int  end_seqnum;
} SEG;

typedef struct ALI {
  int  type;
  char *code;
  char *title;
  char *sequence;
  SEG  seg;
} ALI;

typedef struct ALIFAM {
  char *code;
  int nument;   /* number of entries (including label and text) */
  int alilen;   /* alignment length */
  int nstr;     /* number of structure entries */
  int *str_lst; /* list of indices for structure entries */
  int *lenseq;  /* list of sequence lengths for structure entries */
  char *family; /* family name */
  char *class;  /* structural class */
  char *comment; /* contents of comment lines */
  ALI  *ali;
} ALIFAM;

char_list *store_list (char_list *, char);
void free_list (char_list *);
char *get_seq (FILE *fp, char);
int check_file (FILE *fp);

ALIFAM *get_ali (char *, char *);
int rdali (FILE *, ALIFAM *);
int _get_seg (ALIFAM *);
int _get_nstr (ALIFAM *);

void write_seq (PIR *, int , int);
void write_ali (ALI *, int , int);

void format_error (char *, int);
#endif
