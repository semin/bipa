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
* combination.h                                                 *
* Header for combination functions                              *
****************************************************************/
#ifndef __combination
#define __combination

int *combination (int *, int, int);
int factorial (int);
int vcomb(int *vl, int k, int *vmax);

#endif
