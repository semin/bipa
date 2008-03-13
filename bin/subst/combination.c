/*
 *
 * $Id: combination.c,v 1.5 2000/08/04 10:26:09 kenji Exp $
 *
 * subst release $Name:  $
 */
/****************************************************************
* subst: A program to calculate environment-specific            *
*        amino acid substitution tables                         *
* Copyright (C) 1999-2000  Kenji Mizuguchi                      *
*                                                               *
*                                                               *
* combination.c                                                 *
* Math functions to generate combinations                       *
****************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
//#include <values.h>
#include <float.h>
#include <limits.h>

#include "utility.h"
#include "options.h"
#include "combination.h"

int *combination (int *j, int n, int k) {
/*
 * Generates the next combination of N integers taken K 
 * at a time upon being given N, K and the previous
 * combination. The K integers in the vector J[1] ...J[K]
 * range in value from 0 to N-1, and are always
 * monotonically strictly increasing with respect
 * to themselves in input and output format.
 * If the vector J is set equal to zero, the first combination
 * produced is N-K, ..., N-1. That initial combination
 * is also produced after 0,1,...,N-1, the last value
 * in that cycle */

  int a;
  int b;
  int l;

  b = 1;

  while (1) {
    if (j[b] >= b) {
      a = j[b] - b - 1;
      for (l=1; l<=b; l++) {
	j[l] = l + a;
      }
      return 0;
    }

    if (b == k) break;
    b++;
  }
  for (b=1; b<=k; b++) {
    j[b] = n - k - 1 + b;
  }
  return 0;
}

int factorial (int n) {
  if (n == 0) return (1);

  return (n * factorial(n-1));
}

int vcomb(int *vl, int k, int *vmax) {
/*
 * Suppose there are k integer variables, each of which can adopt
 * the values 0,...,vamx[0], 0,...,vmax[1],...0,...,vmax[k]
 * and given a previous combination of values
 * specified by vl[0],...,vl[k],
 * generates the next combination */

  int i;
  int j;

  i = k-1;  /* start from the right most variable */

  while (1) {
    if (vl[i] < vmax[i]-1) { /* Can this vaibalbe be incremented? */
      vl[i]++;
      for(j=i+1; j<k; j++) { /* reset the variables right to this one */
	vl[j] = 0;
      }
      return 1;
    }
    if (i==0) {
      return 0;
    }
    i--;
  }
}      

/* test driver program 
main() {
  int *vl;
  int *vmax;
  int k;
  int i;
  int n = 1;

  k = 3;
  vl = ivector(k);
  vmax = ivector(k);

  for (i=0; i<k; i++) {
    vl[0] = 0;
  }
  vmax[0] = 1;
  vmax[1] = 5;
  vmax[2] = 2;

  if (opt_verbose == 1) {
  printf("#%d: %d %d %d\n", n, vl[0], vl[1], vl[2]);
  }

  while (1) {
    if (vcomb(vl, k, vmax)) {
      n++;
      printf("#%d: %d %d %d\n", n, vl[0], vl[1], vl[2]);
    }
    else {
      break;
    }
  }
}


main() {
  int *j;
  int n;
  int k;
  int i;
  int nc;
  int m;

  n = 5;
  k = 3;
  j = ivector(n+1);

  for (i=1; i<=n; i++) {
    j[i] = 0;
  }

  nc = factorial(n);
  nc /= (factorial(n-k) * factorial(k));


  printf("initial ");
  for (i=1; i<=n; i++) {
    printf("%d ", j[i]);
  }
  printf("\n");


  for (m = 0; m < nc; m++) {
    combination(j, n, k);

    printf("#%d: ", m);
    for (i=1; i<=k; i++) {
      printf("%d ", j[i]);
    }
    printf("\n");
  }
}

*/
