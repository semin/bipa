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
* indel.h                                                       *
* Header for indel.c                                            *
****************************************************************/
#ifndef __indel
#define __indel

#define IN_N (0)
#define DEL_N (1)
#define INDEL_N (2)
#define IN_C (3)
#define DEL_C (4)

#define H_N_MINUS1  (0)  /* helix N-1           */
#define H_N_CAP     (1)  /*       Ncap position */
#define H_N1        (2)  /*       N1            */
#define H_MIDDLE    (3)  /*       else          */
#define H_C1        (4)  /*       C1            */
#define H_C_CAP     (5)  /*       Ccap          */
#define H_C_PLUS1   (6)  /*       C+1           */

#define E_N_MINUS1  (7)  /* strand N-1           */
#define E_N_CAP     (8)  /*        Ncap position */
#define E_N1        (9)  /*        N1            */
#define E_MIDDLE    (10) /*        else          */
#define E_C1        (11)  /*       C1            */
#define E_C_CAP     (12)  /*        Ccap          */
#define E_C_PLUS1   (13)  /*        C+1           */

#define LOOP        (14)

#define H_N1_OR_H_C1  (15)
#define E_N1_OR_E_C1  (16)

#define H_N_MINUS1_OR_H_C_PLUS1  (17)
#define E_N_MINUS1_OR_E_C_PLUS1  (18)
#define H_N_MINUS1_OR_E_C_PLUS1  (19)
#define E_N_MINUS1_OR_H_C_PLUS1  (20)

#define NTYPE (15) /* + 6 ambiguous cases */

int indel (int, int, strali *, int,
	   int *, int *, PIR *, char **, int **, double **, double *);

int count_indel(int, int, int, strali *,
		int *, PIR *, char **, int **, int **);

int count_freq(int, int, strali *, int *);
int weight_freq(int *, double *, int);
int isTerminalGap(int *, int, int);
int isGapOpening(int *, int *, int);
int assign_sstype (char *, int, int);
int Nflank(int *, int);
int weight_indel(int **, double **, int);
int output_indel(double **, double *);

#endif
