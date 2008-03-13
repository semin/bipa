/*
 *
 * $Id:
 *
 * subst release $Name:  $
 */
/****************************************************************
* subst: A program to calculate environment-specific            *
*        amino acid substitution tables                         *
* Copyright (C) 1999-2000  Kenji Mizuguchi                      *
*                                                               *
*                                                               *
* utility.h                                                     *
* Header for utility.c                                          *
****************************************************************/
#ifndef __utility
#define __utility

int cindex (char *, char);
int **imatrix(int, int );
double **dmatrix(int, int );
char **cmatrix(int, int );
char *cvector(int);
int *ivector(int);
double *dvector(int);

char realhex(float);
char inthex(int);

char *mbasename(char *, char *);
char *mstrcat(char *, char *);
char *expand_path(char *);

int initialize_imat(int, int, int **, int);
int initialize_ivec(int, int *, int);
int initialize_dvec(int, double *, double);
int initialize_cvec(int, char *, char);
int initialize_dmat(int, int, double **, double);
int initialize_cmat(int, int, char **, char);

double mrint(double);
int custom_round(double);

char *trim_space (char *);

#endif
