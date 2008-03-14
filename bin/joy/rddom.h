#ifndef __rddom
#define __rddom

#define DOM_SUFFIX ".dom"

/* Define the structure for domain -- start */

#define MAXSEGMENT 9
#define MAXDOMAIN  9

typedef struct segment {
  int startno;
  char startchain;
  int endno;
  char endchain;
} segment;

typedef struct domain {
  int id;
  int segno;
  segment seg[MAXSEGMENT];
} domain;

extern domain dom[MAXDOMAIN],domtmp[MAXDOMAIN];

/* Define the structure for domain -- end   */

int rddomain(ALIFAM *);

#endif
