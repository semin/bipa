/*
 *
 * $Id:
 *
 * subst release $Name:
 */
/****************************************************************
* subst: A program to calculate environment-specific            *
*        amino acid substitution tables                         *
* Copyright (C) 1999-2000  Kenji Mizuguchi                      *
*                                                               *
****************************************************************/

/*************************************************************
*                                                            *
* slink -- computes single linkage tree from distance matrix *
*                                                            *
* ns number of objects                                       *
* dist[0...ns][0...ns] distance matrix (symmetric array)     *
*                                                            *
* Author: Kenji Mizuguchi                                    *
*                                                            *
* Note                                                       *
*   1. The algorithm is found on pages 191-195 of:           *
*                                                            *
*     HARTIGAN, J. A. (1975).  CLUSTERING ALGORITHMS,        *
*        JOHN WILEY & SONS, INC., NEW YORK.                  *
*                                                            *
* Date:         2 Feb 1998                                   *
* Last update:  6 Feb 1998
*                                                            *
*************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
//#include <values.h>
#include <float.h>
#include <limits.h>
#include "utility.h"
#include "slink.h"

cluster *slinkc(int ns, double **dist, char **snames, int *nclus) {
  cluster *clus;
  int nc;
  char **snamenew;
  int **iwork;
  double *work;
  double dmin;
  int imin;
  int i, j, k, next;
  double tmp;
  int itmp;
  char *tmplabel = NULL;
  int m1, l, mm2;
  int ll = 0;
  double xmax;

/* initialise arrays */
  iwork = imatrix(4, ns+1);
  work = dvector(ns+1);

  snamenew = copy_names(ns, snames);

#ifdef DEBUG
  for (i=0; i<ns; i++) {
    printf("%s\n", snamenew[i]);
  }
  printf("\n");
  for (i=0; i<ns; i++) {
    for (j=0; j<ns; j++) {
      printf("%6.3f", dist[i][j]);
    }
    printf("\n");
  }
#endif

  for (i=0; i<ns; i++) { /* obj i is closed to obj iwork[3][i] */
    iwork[3][i] = i;
  }
  dist[0][0] = DBL_MAX;

  for (k=1; k<ns; k++) { /* find the obj closest to the first obj */
    if (dist[0][k] < dist[0][0]) {
      dist[0][0] = dist[0][k];
      iwork[3][0] = k;
    }
  }

  for (next = 0; next < ns-1; next++) {
    j = next + 1;
    dmin = DBL_MAX;
    imin = next;

    for (i=0; i<=next; i++) {    /*select object closest to on of O(1),
				   O(2),...,O(next) */
      if (dist[i][i] < dmin) {
        dmin = dist[i][i];
        imin = i;
      }
    }
    work[j+1] = 100. * dmin;
    i = iwork[3][imin];

/* swap i and j */

    for (k=0; k<ns; k++) {
      tmp = dist[i][k];
      dist[i][k] = dist[j][k];
      dist[j][k] = tmp;
    }
    tmplabel = strdup(snamenew[i]);
    strcpy(snamenew[i], snamenew[j]);
    strcpy(snamenew[j], tmplabel);
    for (k=0; k<ns; k++) {
      tmp = dist[k][i];
      dist[k][i] = dist[k][j];
      dist[k][j] = tmp;
    }
    itmp = iwork[3][i];
    iwork[3][i] = iwork[3][j];
    iwork[3][j] = itmp;

    for (k=0; k<=next; k++) {
      if (iwork[3][k] == i) {
        iwork[3][k] = 0;
      }
      if (iwork[3][k] == j) {
        iwork[3][k] = i;
      }
    }

    for(i=0; i<=j; i++) {      /* updated distances */
      iwork[3][j] = j;
      if (iwork[3][i] <= j) {
        iwork[3][i] = i;
        dist[i][i] = DBL_MAX;  /* eliminate distances among O(1),O(2),
				    ...,O(j) */
        for (k=j; k<ns; k++) {
          if (k != j && dist[i][k] < dist[i][i]) {
            dist[i][i] = dist[i][k];
            iwork[3][i] = k;
          }
        }
      }
    }
  }

  work[1] = DBL_MAX;   /* work[k+1] is G(k) */
  m1 = ns + 1;
  for (k=1; k<m1; k++) {
    iwork[0][k] = k;
    iwork[1][k] = k;
    for (l=k; l<m1; l++) {
      if (l != k) {
        if (work[l] > work[k]) {
          break;
        }
      }
      iwork[1][k] = l;
    }
    for (l=1; l<=k; l++) {
      ll = k - l + 1;
      if (l != 1) {
	if (work[ll] > work[k]) {
	  break;
	}
      }
    }
    iwork[0][k] = ll;
  }
  mm2 = ns -1;
  for (k=0; k<mm2; k++) {
    iwork[0][k] = iwork[0][k+2];
    iwork[1][k] = iwork[1][k+2];
    work[k] = work[k+2];
  }

  xmax = 0.0;
  for (k=0; k<mm2; k++) {
    if (xmax < work[k]) {
      xmax = work[k];
    }
  }
  for (k=0; k<mm2; k++) {
    if (xmax > DBL_MIN) {
      iwork[2][k] = floor(work[k]*100/xmax);
    }
    else {
      iwork[2][k] = 0;
    }
  }

#ifdef DEBUG
  for (i=0; i<ns; i++) {
    printf("%d %s\n", i+1, snamenew[i]);
  }
  printf("clus from to diameter\n");
  for (k=0; k<(ns-1); k++) {
    printf("%3d %3d %3d %3d %6.2f\n",
           k+1, iwork[0][k], iwork[1][k], iwork[2][k],
           work[k]);
  }
#endif

  clus = _partition(ns, snamenew, snames, iwork, work, &nc);
  *nclus = nc;
  free(tmplabel);
  free_names(ns, snamenew);
  return clus;
}

cluster *_partition(int ns, char **snamenew, char **snames,
		    int **iwork, double *work, int *nclus) {
  int i, j, k;
  int isInclus;
  int nc = 0;
  int nmc;
  cluster *clus;
  int **tmpclus;
  int *flag, *order;

  tmpclus = imatrix(2, ns-1);
  flag = ivector(ns);
  order = ivector(ns);
  initialize_ivec(ns, flag, -1);

  for (i=0; i<(ns-1); i++) {
    if (iwork[2][i] > 0) {      /* select clusters with distance = 0 */
      continue;
    }

    isInclus = 0;
    for (j=0; j<nc; j++) {
      if (tmpclus[0][j] == iwork[0][i] &&
	  tmpclus[1][j] == iwork[1][i]) {
	isInclus = 1;
	break;
      }
    }
    if (isInclus == 0) {
      tmpclus[0][nc] = iwork[0][i];
      tmpclus[1][nc] = iwork[1][i];
      nc++;
    }
  }

  for (i=0; i<nc; i++) {   /* cluster i includes cases tmpclus[0][i]-1 to tmpclus[1][i]-1
			    * but this numbering is for the permuted cases! */
    for (j = tmpclus[0][i]-1; j < tmpclus[1][i]; j++) {
      flag[j] = i;
    }
  }

  nmc = nc;
  for (i=0; i<ns; i++) {
    if (flag[i] < 0) {
      flag[i] = nc;
      nc++;
    }
  }

  for (i=0; i<ns; i++) {
    order[i] = where_is_string(snamenew[i], ns, snames);
  }

#ifdef DEBUG
  printf("order new org\n");
  for (i=0; i<ns; i++) {
    printf("%d %s %s\n", order[i], snamenew[i], snames[i]);
  }
  printf("number of multi-member clusters %d\n", nmc);
  printf("ns %d\n", ns);
  printf("number of clusters %d\n", nc);
#endif

  clus = (cluster *) malloc((size_t) (nc * sizeof(cluster)));
  if (!clus) {
    fprintf(stderr, "Can't allocate memory\n");
    exit(1);
  }

  for (i=0; i<nmc; i++) {
    clus[i].nmem = tmpclus[1][i] - tmpclus[0][i] + 1;
    clus[i].memlist = ivector(clus[i].nmem);
    k = 0;
    for (j = tmpclus[0][i]-1; j < tmpclus[1][i]; j++) {
      clus[i].memlist[k] = order[j];
      k++;
    }
  }
    
  for (i=0; i<ns; i++) {
    if (flag[i] >= nmc) {
      clus[flag[i]].nmem = 1;
      clus[flag[i]].memlist = ivector(1);
      clus[flag[i]].memlist[0] = order[i];
      continue;
    }
  }

  *nclus = nc;
  return clus;
}

char **copy_names(int n, char **names) {
  char **newnames;
  int i;

  newnames = (char **)malloc((size_t) (n * sizeof(char *)));
  if (!newnames) {
    fprintf(stderr, "Can't allocate memory\n");
    exit(1);
  }

  for (i=0; i<n; i++) {
    newnames[i] = strdup(names[i]);
  }

  return newnames;
}

int where_is_string(char *s, int n, char **names) {
  int i;

  for (i=0; i<n; i++) {
    if (strcmp(s, names[i]) == 0) {
      return i;
    }
  }
  return -1;
}

void free_names(int n, char **names) {
  int i;
  for (i=0; i<n; i++) {
    free(names[i]);
  }
}
