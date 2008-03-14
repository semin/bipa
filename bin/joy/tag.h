#ifndef __tag_rtf
#define __tag_rtf

#include "gen_html.h"

typedef struct Tag {
  int nb;   /* number of tags beginning at this position */
  int ne;   /*                ending */
  char *begin; /* list of tag (style) numbers */
  char *end;
} Tag;      /* defines an array for the entire alignment length */

typedef struct TagAll {
  Tag *tags;
} TagAll;   /* defines an array for all structures */

Tag *assignTag(int, int, int, TEM *, html_style *, int);
void sortLst(char *, int, int, int *);
void swap(char *, int *, int, int);

html_style *set_default(html_style *, html_style *, int, int);

#endif
