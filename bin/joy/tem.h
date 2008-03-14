#ifndef __tem
#define __tem

#define TEMEXT ".tem"

/*
 * struct _features
 *
 */
typedef struct _features {
  char *name;
  char *assign;
} _features;

/*
 * struct TEM
 *
 */
typedef struct TEM {
  int nfeature;  /* number of features */
  _features *feature;
} TEM;

TEM *allocate_tem(int, int, int);


TEM *create_tem(int, int, char *, ALI *, int *, SST *, PSA *, HBD *);
int write_tem(int, int, int, char **, char *, ALI *, int *, TEM *, int);
int which_fset(void);

/* The following is automatically updated by the perl script mkjoy
   so please DO NOT modify it by hand */

/* start feature list */
#define _DEFAULT (0)
#define _J216 (1)
#define _J4 (2)
#define _EXT (3)
/* end */
#endif
