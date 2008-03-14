/*
 *
 * $Id: analysis.c,v 1.9 2001/02/09 18:44:56 kenji Exp $
 *
 * joy 5.0 release $Name:  $
 */
/****************************************************************************
* joy: A program for protein sequence-structure representation and analysis *
* Copyright (C) 1988-1997  John Overington                                  *
* Copyright (C) 1997-1999  Kenji Mizuguchi and Charlotte Deane              *
* Copyright (C) 1999-2000  Kenji Mizuguchi                                  *
*                                                                           *
* analysis.c                                                                *
* Performs various analyses                                                 *
****************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <unistd.h>

#include <parse.h>
#include "typeset.h"

#include "utility.h"
#include "rdali.h"
#include "rdpsa.h"
#include "rdsst.h"
#include "rdhbd.h"
#include "tem.h"
#include "gen_html.h"
#include "analysis.h"

int consen(int nseq, char *assign, char type, double cutoff) {
  int ntype = 0;
  int i;

  for (i=0; i<nseq; i++) {
    if (assign[i] == type) ntype++;
  }

  if ((double) ntype / (double) nseq >= cutoff) {
    return 1;
  }
  else {
    return 0;
  }
}

double pid(char *seq1, char *seq2) {
  char *ch1, *ch2;
  int n;
  int id;
  double pid_val;

  n = 0;
  id = 0;
  ch1 = seq1;
  ch2 = seq2;
  while (*ch1 != '\0' && ch1 != NULL && *ch2 != '\0' && ch2 != NULL) {
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

int analshort(ALIFAM *alifam) {
  ALI *aliall;
  int nument;
  int alilen;
  int nstr;
  double pidave = 0.0;
  double pidhigh, pidlow;
  int nhigh[2], nlow[2];
  double **pidmat;
  int np = 0;
  int navelen = 0;
  int i, j, i1, j1;
  
  nument = alifam->nument;
  alilen = alifam->alilen;
  nstr = alifam->nstr;
  aliall = alifam->ali;

  pidmat = dmatrix(nstr, nstr);

  /* Sequence identity of structures with structures */

  pidhigh = -1.0;
  pidlow = 101.0;

  for (i=0; i<nstr-1; i++) {
    i1 = (alifam->str_lst)[i];
    for (j=i+1; j<nstr; j++) {
      j1 = (alifam->str_lst)[j];
      pidmat[i][j] = pid(aliall[i1].sequence, aliall[j1].sequence);
      pidmat[j][i] = pidmat[i][j];
      pidave += pidmat[i][j];
      if (pidmat[i][j] > pidhigh) {
	pidhigh = pidmat[i][j];
	nhigh[0] = i;
	nhigh[1] = j;
      }
      if (pidmat[i][j] < pidlow) {
	pidlow = pidmat[i][j];
	nlow[0] = i;
	nlow[1] = j;
      }
      np++;
    }
  }
  if (np > 0) {
    pidave /=  (double)np;
  }
  else {   /* no pair, something is wrong! */
    return -1;
  }

  for (i=0; i<nstr; i++) {
    pidmat[i][i] = 100.0;
  }

  if (! alifam->family) {
    alifam->family = get_keywd(alifam->comment, FAMILY);
  }
  if (! alifam->class) {
    alifam->class = get_keywd(alifam->comment, CLASS);
  }

  for (i=0; i<nstr; i++) {
    navelen += alifam->lenseq[i];
  }
  navelen = (int) ((double) navelen / (double) nstr + 0.5);

  printf("most similar  - %s   -- %s   %5.1f\n",
	 alifam->ali[nhigh[0]].code, alifam->ali[nhigh[1]].code, pidhigh);
  printf("least similar - %s   -- %s   %5.1f\n",
	 alifam->ali[nlow[0]].code, alifam->ali[nlow[1]].code, pidlow);

  if (alifam->family) {
    printf("# line for families:%s:%d:%3d:%5.1f\n",alifam->family, nstr, navelen, pidave);
  }
  else {
    printf("# line for families::%d:%3d:%5.1f\n", nstr, navelen, pidave);
  }
  if (alifam->class) {
    printf("# line for classes:%s\n", alifam->class);
  }
  else {
    printf("# line for classes:\n");
  }

  printf("pairwise sequence identities\n");
  printf("defined as:\n");
  printf("  no of identical residues / no of aligned, non-gap positions * 100\n");
  printf("(Unlike version 4, no distinction is made between C and J.)\n");
  printf("pid           ");
  for (j=0; j<nstr; j++) {
    printf(" %-5s", aliall[j].code);
  }
  printf("\n");
  for (i=0; i<nstr; i++) {
    i1 = (alifam->str_lst)[i];
    printf("pid      %5s", aliall[i1].code);
    for (j=0; j<nstr; j++) {
      printf("%6.1f", pidmat[i][j]);
    }
    printf("\n");
  }
  free(pidmat[0]);
  free(pidmat);
  return (1);
}

