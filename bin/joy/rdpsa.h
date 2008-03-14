#ifndef __rdpsa
#define __rdpsa

#define PSA_BUFSIZE 80
#define KEY "ACCESS"

typedef struct PSA {
  int naa;
  char **resnum;
  char **sequence;
  int *missing_atom;
  double *side_per;
} PSA;

PSA *get_psa(int, char **, int *);
PSA *_allocate_psa(int, int *);
int _rdpsa(FILE *, int, PSA);

int count_lines(char *);

void write_psa(PSA, int);

#endif
