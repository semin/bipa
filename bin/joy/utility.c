/*
*
* $Id:
* joy 5.0 release $Name:  $
*/
/****************************************************************************
* joy: A program for protein sequence-structure representation and analysis *
* Copyright (C) 1988-1997  John Overington                                  *
* Copyright (C) 1997-1999  Kenji Mizuguchi and Charlotte Deane              *
* Copyright (C) 1999-2000  Kenji Mizuguchi                                  *
*                                                                           *
* utility                                                                   *
* Various conversion functions                                              *
*                                                                           *
*                                                                           *
*                                                                           *
* Author: Kenji Mizuguchi                                                   *
*                                                                           *
* Note                                                                      *
*                                                                           *
* Date:        16 Apr 1999                                                  *
* Last update: 16 Apr 1999                                                  *
*                                                                           *
****************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <pwd.h>
#include <sys/types.h>
#include <unistd.h>

#include "utility.h"

char *trim_space (char s[]) {
  int n;
  int i;

  if (! s) {
    return NULL;
  }
  for (n=strlen(s)-1; n >= 0; n--) {
    if (s[n] != ' ' && s[n] != '\t' && s[n] != '\n')
      break;
    s[n] = '\0';
  }
  for (i=0; i<n; i++) {
    if (s[i] != ' ' && s[i] != '\t' && s[i] != '\n')
      return s+i;
  }
  return s;
}

int initialize_imat(int n, int m, int **imat, int init_val) {
  int i;
  int j;
  for (i=0; i<n; i++) {
    for (j=0; j<m; j++) {
      imat[i][j] = init_val;
    }
  }
  return (1);
}

int initialize_ivec(int n, int *ivec, int init_val) {
  int i;
  for (i=0; i<n; i++) {
    ivec[i] = init_val;
  }
  return (1);
}

int initialize_cvec(int n, char *cvec, char init_val) {
  int i;
  for (i=0; i<n; i++) {
    cvec[i] = init_val;
  }
  return (1);
}

int initialize_dvec(int n, double *dvec, double init_val) {
  int i;
  for (i=0; i<n; i++) {
    dvec[i] = init_val;
  }
  return (1);
}

int initialize_dmat(int n, int m, double **dmat, double init_val) {
  int i;
  int j;
  for (i=0; i<n; i++) {
    for (j=0; j<m; j++) {
      dmat[i][j] = init_val;
    }
  }
  return (1);
}

int initialize_cmat(int n, int m, char **cmat, char init_val) {
  int i;
  int j;
  for (i=0; i<n; i++) {
    for (j=0; j<m; j++) {
      cmat[i][j] = init_val;
    }
  }
  return (1);
}

int cindex (char *t, char c) {
  int i;
  i = 0;
  while (t[i] != '\0') {
    if (t[i] == c) {
      return i;
    }
    i++;
  }
  return -1;
}

int **imatrix(int n, int m) { /* allocate memory for a 2D matrix */

  int **mat;
  int i;

  mat = (int **)malloc((size_t) (n * sizeof(int *)));
  mat[0] = (int *)malloc((size_t) (n*m*sizeof(int)));

  if (!mat[0]) {
    fprintf(stderr, "Can't allocate memory\n");
    exit(1);
  }

  for (i=1; i<n; i++) {
    mat[i] = mat[i-1] + m;
  }

  return mat;
}

char **cmatrix(int n, int m) { /* allocate memory for a 2D matrix */

  char **mat;
  int i;

  mat = (char **)malloc((size_t) (n * sizeof(char *)));
  mat[0] = (char *)malloc((size_t) (n*m*sizeof(char)));

  if (!mat[0]) {
    fprintf(stderr, "Can't allocate memory\n");
    exit(1);
  }

  for (i=1; i<n; i++) {
    mat[i] = mat[i-1] + m;
  }

  return mat;
}

unsigned char **ucmatrix(int n, int m) { /* allocate memory for a 2D matrix */

  unsigned char **mat;
  int i;

  mat = (unsigned char **)malloc((size_t) (n * sizeof(unsigned char *)));
  mat[0] = (unsigned char *)malloc((size_t) (n*m*sizeof(unsigned char)));

  if (!mat[0]) {
    fprintf(stderr, "Can't allocate memory\n");
    exit(1);
  }

  for (i=1; i<n; i++) {
    mat[i] = mat[i-1] + m;
  }

  return mat;
}

char *cvector(int n) { /* allocate memory for a 1D vector */

  char *vec;
  vec = (char *)malloc((size_t) (n * sizeof(char)));

  if (!vec) {
    fprintf(stderr, "Can't allocate memory\n");
    exit(1);
  }
  return vec;
}

int *ivector(int n) { /* allocate memory for a 1D vector */

  int *vec;
  vec = (int *)malloc((size_t) (n * sizeof(int)));

  if (!vec) {
    fprintf(stderr, "Can't allocate memory\n");
    exit(1);
  }
  return vec;
}

double **dmatrix(int n, int m) { /* allocate memory for a 2D matrix */

  double **mat;
  int i;

  mat = (double **)malloc((size_t) (n * sizeof(double *)));
  mat[0] = (double *)malloc((size_t) (n*m*sizeof(double)));

  if (!mat[0]) {
    fprintf(stderr, "Can't allocate memory\n");
    exit(1);
  }

  for (i=1; i<n; i++) {
    mat[i] = mat[i-1] + m;
  }

  return mat;
}

double *dvector(int n) { /* allocate memory for a 1D vector */

  double *vec;
  vec = (double *)malloc((size_t) (n * sizeof(double)));

  if (!vec) {
    fprintf(stderr, "Can't allocate memory\n");
    exit(1);
  }
  return vec;
}

char realhex(float fval) {
  if (fval < 10.0) {
    return '0';
  }
  else if (fval < 20.0) {
    return '1';
  }
  else if (fval < 30.0) {
    return '2';
  }
  else if (fval < 40.0) {
    return '3';
  }
  else if (fval < 50.0) {
    return '4';
  }
  else if (fval < 60.0) {
    return '5';
  }
  else if (fval < 70.0) {
    return '6';
  }
  else if (fval < 80.0) {
    return '7';
  }
  else if (fval < 90.0) {
    return '8';
  }
  else if (fval < 100.0) {
    return '9';
  }
  else if (fval < 110.0) {
    return 'a';
  }
  else if (fval < 120.0) {
    return 'b';
  }
  else if (fval < 130.0) {
    return 'c';
  }
  else if (fval < 140.0) {
    return 'd';
  }
  else if (fval < 150.0) {
    return 'e';
  }
  else {
    return 'f';
  }
}

char inthex(int ival) {
  return realhex((float) ival);
}

char *mbasename(char *path, char *suffix) {
  char *s;
  int i;
  int n;
  int l;

  s = strdup(path);
  n = strlen(s)-1;
  l = strlen(suffix)-1;

  for (i=0; i<strlen(suffix); i++) {
    if (suffix[l-i] != s[n-i]) {
      return NULL;
    }
  }
  s[n-l] = '\0';
  return s;
}

char *mstrcat(char *s1, char *s2) {
  char *s;

  if (s1 && !s2) {
    s = strdup(s1);
  }
  else if (!s1 && s2) {
    s = strdup(s2);
  }
  else if (!s1 && !s2) {
    return NULL;
  }
  else {
    s = cvector(strlen(s1) + strlen(s2) + 1);
    strcpy(s, s1);
    strcat(s, s2);
  }
  return s;
}

char *expand_path(char *s) {
  char *path;
  char *pfx = NULL;
  int pos;
  struct passwd *pw;
  char *user;

  if (strlen(s) == 0 || s[0] != '~') {
    path = strdup(s);
    return path;
  }

  pos = cindex(s, '/');
  if (strlen(s) == 1 || pos == 1) {
    pfx = getenv("HOME");
    if (!pfx) {
      pw = getpwuid(getuid());
      if (pw) pfx = strdup(pw->pw_dir);
    }
  }
  else {
    user = strdup(s+1);
    if (pos > 1) user[pos-1] = '\0';
    pw = getpwnam(user);
    if (pw) {
      pfx = strdup(pw->pw_dir);
    }
  }

  if (!pfx) {
    path = strdup(s);
    return path;
  }

  if (pos < 0) {
    return pfx;
  }

  path = mstrcat(pfx, s+pos);
  return path;
}

double mrint(double x) {
  int i;

  i = (int) (x + 5.000000001e-1);
  return (double) i;
 
}

char *get_keywd(char *comment, char *key) {
  char *word;
  char *s1;
  int i;

  if (comment == NULL) return NULL;
  s1 = strstr(comment, key);
  if (s1 == NULL) return NULL;

  s1 += strlen(key);
  while (*s1 == ' ') {
    s1++;
  }
  i = cindex(s1, '\n');
  if (i <= 0) i = strlen(s1);

  while (s1[i] == ' ' || s1[i] == '\n' || s1[i] == '\0') {
    i--;
    if (i < 0) break;
  }
  if (i < 0) return NULL;

  word = cvector(i+2);
  strncpy(word, s1, i+1);
  word[i+1] = '\0';
  return word;
}
