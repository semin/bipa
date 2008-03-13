/*
 *
 * $Id: analysis.c,v 1.5 2000/08/04 10:26:09 kenji Exp $
 *
 * subst release $Name:  $
 */
/****************************************************************
* subst: A program to calculate environment-specific            *
*        amino acid substitution tables                         *
* Copyright (C) 1999-2000  Kenji Mizuguchi                      *
*                                                               *
*                                                               *
* analysis.c                                                    *
* Performs various analyses                                     *
****************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
//#include <values.h>
#include <float.h>
#include <limits.h>

#include "utility.h"
#include "analysis.h"

double pid(char *seq1, char *seq2) {
  char *ch1, *ch2;
  int n;
  int id;
  double pid_val;

  n = 0;
  id = 0;
  ch1 = seq1;
  ch2 = seq2;
  while (ch1 != NULL && *ch1 != '\0' && ch2 != NULL && *ch2 != '\0') {
    if (*ch1 == '-' || *ch1 == '/' ||   /* skip gap positions */
	*ch2 == '-' || *ch2 == '/') {
      ch1++;
      ch2++;
      continue;
    }
    if (*ch1 == *ch2) {
      id++;
    }
    n++;
    ch1++;
    ch2++;
  }
  if (n > 0) {
    pid_val = 100.0 * (double) id / (double) n;
  }
  else {
    pid_val = 0.0;
  }
  return pid_val;
}
