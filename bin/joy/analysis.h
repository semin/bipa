/*
 *
 * $Id: analysis.h,v 1.5 2000/08/01 10:19:34 kenji Exp $
 *
 * joy 5.0 release $Name:  $
 */
/****************************************************************************
* joy: A program for protein sequence-structure representation and analysis *
* Copyright (C) 1988-1997  John Overington                                  *
* Copyright (C) 1997-1999  Kenji Mizuguchi and Charlotte Deane              *
* Copyright (C) 1999-2000  Kenji Mizuguchi                                  *
*                                                                           *
* analysis.h                                                                *
* Header file for analysis.c                                                *
****************************************************************************/
#ifndef __analysis
#define __analysis

#include "rdali.h"

int consen(int, char *, char, double);
double pid(char *, char *);
int analshort(ALIFAM *);

#endif
