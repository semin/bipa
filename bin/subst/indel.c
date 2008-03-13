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
*                                                               *
* indel.c                                                       *
* Optional analysis on insertions and deletions                 *
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
#include "subst.h"
#include "rdtem.h"
#include "analysis.h"
#include "slink.h"
#include "combination.h"
#include "indel.h"

/*   IMPORTANT NOTE:                                             */
/*                                                               */
/* For this analysis, the following requirements must satisfied: */
/* 1. The first line of the classdef.dat file is                 */
/*     secondary structure and phi angle;HEPC;HEPC;F;F           */
/* 2. The seconeary structure records in the .tem file has no 'X'*/
/*    characters (nomask).                                       */

int indel (int naa, int ncode, strali *sali, int nclass,
	   int *ncounts, int *seqIdx,
	   PIR *seqall, char **seqCode, int **iwork,
	   double **findel, double *ssefreq) {

  cluster *clus;
  int nc;          /* number of clusters */
  int i, j;
  int ii, jj;
  int i1, j1;
  int **iindel;
  int *ifreq;

  iindel = imatrix(2, NTYPE + 6);
  ifreq = ivector(NTYPE + 6);

  clus = clustering (ncode, seqall, seqIdx, seqCode, &nc);
  
  if (opt_verbose == 1) {
    printf("no. clusters %d\n", nc);
    for (i=0; i<nc; i++) {
      for (j=0; j<clus[i].nmem; j++) {
	printf("%d ", clus[i].memlist[j]);
      }
      printf("\n");
    }
  }

  for (i=0; i<nc; i++) {   /* obtain frequencies of each ssetype */
    initialize_ivec(NTYPE+6, ifreq, 0);
    for (i1=0; i1 < clus[i].nmem; i1++) {
      count_freq(clus[i].memlist[i1], naa, sali, ifreq);
    }
    weight_freq(ifreq, ssefreq, clus[i].nmem);
  }

  for (i=0; i<nc-1; i++) {   /* all pairs between clusters */
    for (j=i+1; j<nc; j++) {

      initialize_imat(2, NTYPE+6, iindel, 0);

      for (i1=0; i1 < clus[i].nmem; i1++) {
	for (j1=0; j1 < clus[j].nmem; j1++) {
	
	  count_indel(clus[i].memlist[i1], clus[j].memlist[j1], naa, sali,
		      ncounts, seqall, seqCode, iwork, iindel);
	  }
      }
      weight_indel(iindel, findel, clus[i].nmem*clus[j].nmem);

      if (opt_verbose == 1) {
	printf ("count between clusters %d and %d\n", i, j);
	printf("indel\n");
	for (jj=0; jj<2; jj++) {
	  for (ii=0; ii<NTYPE+6; ii++) {
	    printf("%5d ", iindel[jj][ii]);
	  }
	  printf("\n");
	}
	for (jj=0; jj<2; jj++) {
	  for (ii=0; ii<NTYPE; ii++) {
	    printf("%5.1f ", findel[jj][ii]);
	  }
	  printf("\n");
	}
      }
    }
  }

  if (opt_verbose == 1) {
    for (i=0; i<nc-1; i++) {   /* all pairs between clusters */
      for (j=i+1; j<nc; j++) {
	printf ("#clus %d and %d\n", i, j);
	printf ("weight 1/%d\n", clus[i].nmem*clus[j].nmem );
      }
    }
  }
  free(clus);
  return(1);
}


int count_indel(int i, int j, int naa, strali *sali,
		int *ncounts,
		PIR *seqall, char **seqCode, int **iwork,
		int **iindel) {

/* Count a.a. substitutions between (i,j) pair and sum them up for the entire
   alignment (position 0 to naa) */

  int k, l;
  int is, js;

  for (k=0; k<naa; k++) {
    if (sali[i].aaIdx[k] < 0 && sali[j].aaIdx[k] < 0) { /* both gaps */
      continue;
    }
    if (sali[i].aaIdx[k] >= 0 && sali[j].aaIdx[k] >= 0) { /* match */
      continue;
    }
    if (sali[i].aaIdx[k] < 0) {  /* '-' in sequence i */
      if (isTerminalGap(sali[i].aaIdx, k, naa) == 1) {
	continue;
      }
      else if (isGapOpening(sali[i].aaIdx, sali[j].aaIdx, k-1) == 0) {
	continue;
      }
      l = Nflank(sali[j].sstype, k);

      /* deletion with respect to the sequence j */
      js = sali[j].sstype[l];
      iindel[DEL_N][js]++;

      /* insertion with respect to the sequence i */
      is = sali[i].sstype[l];
      iindel[IN_N][is]++;

      if (opt_verbose == 1) {
	printf("Gap at %d ", k);
	printf("    deltion at %c  of seq %d ",
	       amino_acid[sali[j].aaIdx[l]], j);
	printf("  type %d ", js);
	printf("    insertion at %c  of seq %d",
	       amino_acid[sali[i].aaIdx[l]], i);
	printf("   type %d\n", is);
      }
    }
    else {   /* '-' in sequence j */
      if (isTerminalGap(sali[j].aaIdx, k, naa) == 1) {
	continue;
      }
      else if (isGapOpening(sali[j].aaIdx, sali[i].aaIdx, k-1) == 0) {
	continue;
      }

      l = Nflank(sali[i].sstype, k);

      /* deletion with respect to the sequence i */
      is = sali[i].sstype[l];
      iindel[DEL_N][is]++;

      /* insertion with respect to the sequence j */
      js = sali[j].sstype[l];
      iindel[IN_N][js]++;

      if (opt_verbose == 1) {
	printf("Gap at %d ", k);
	printf("    deltion at %c  of seq %d ",
	       amino_acid[sali[i].aaIdx[l]], i);
	printf("  type %d ", is);
	printf("    insertion at %c  of seq %d",
	       amino_acid[sali[j].aaIdx[l]], j);
	printf("   type %d\n", js);
      }
    }
  }
  return(1);
}

int isTerminalGap(int *aaIdx, int pos, int naa) {
  int i;
  int nflg;

  nflg = 1;
  for (i=pos; i>=0; i--) {   /* check the N-terminus */
    if (aaIdx[i] >= 0) {
      nflg = 0;     /* not an N-terminal hangout */
      break;
    }
  }
  if (nflg == 1) {   /* N-terminal hangout */
    return 1;
  }

  for (i=pos; i<naa; i++) {   /* check the C-terminus */
    if (aaIdx[i] >= 0) {
      return 0;      /* not a C-terminal hangout */
    }
  }
  return 1;   /* C-terminal hangout */
}

int isGapOpening(int *aaIdx1, int *aaIdx2, int pos) {


  while (aaIdx1[pos] < 0 && aaIdx2[pos] < 0) { /* eliminate gap-only columns */
    pos--;
  }

  if (aaIdx1[pos] < 0 || aaIdx2[pos] < 0) {
    return 0;     /* gap already there  or */
                  /* eliminate the following case */
                  /* 1   LN-                       */
                  /* 2   --N                       */
                  /*       ^                       */
  }
  else {
    return 1;     /* this is a gap opening site */
  }
}

/* this assignment is based on the 'secndary structure and phi angle'
   defined by JOY (HEPC). Since, the type 'P' has a higher precedence
   than E or H, there can be segments like CEEPECCC, where the
   second strand has length 1!. the function deals with these
   cases properly and assumes that no residue can be both N and C cap
   (which is reasonable). N cap is defined first, so the number of
   N-cap residues can be higher than that of C cap! */

int assign_sstype (char *sse, int pos, int naa) {


  int i;
  int ib, ie;
  int hn1, hc1, en1, ec1;

  if (sse[pos] == 'H') { /* helix */
    ib = 0;
    for (i=pos-1; i>=0; i--) {
      if (sse[i] == '-') {
	continue;
      }
      if (sse[i] != 'H') {
	break;
      }
      ib--;
    }

    if (ib == 0) {   /* N-cap */
      return H_N_CAP;
    }

    ie = 0;
    for (i=pos+1; i<naa ; i++) {
      if (sse[i] == '-') {
	continue;
      }
      if (sse[i] != 'H') {
	break;
      }
      ie++;
    }
    if (ie == 0) { /* C-cap */
      return H_C_CAP;
    }
    else if (ib == -1 && ie == 1) { /* N1 or C1*/
      return H_N1_OR_H_C1;
    }
    else if (ib == -1) { /* N1 */
      return H_N1;
    }
    else if (ie == 1) { /* C1 */
      return H_C1;
    }
    /* middle of helix */
    return H_MIDDLE;
  }

  if (sse[pos] == 'E') { /* strand */
    ib = 0;
    for (i=pos-1; i>=0; i--) {
      if (sse[i] == '-') {
	continue;
      }
      if (sse[i] != 'E') {
	break;
      }
      ib--;
    }

    if (ib == 0) {  /* N-cap */
      return E_N_CAP;
    }

    ie = 0;
    for (i=pos+1; i<naa ; i++) {
      if (sse[i] == '-') {
	continue;
      }
      if (sse[i] != 'E') {
	break;
      }
      ie++;
    }
    if (ie == 0) {  /* C-cap */
      return E_C_CAP;
    }
    else if (ib == -1 && ie == 1) {
      return E_N1_OR_E_C1;
    }
    else if (ib == -1) {  
      return E_N1;
    }
    else if (ie == 1) {  
      return E_C1;
    }
    return E_MIDDLE;
  }

  /* this is a loop, but can be N-1 or C+1 of a helix or a strand */

  hn1 = hc1 = en1 = ec1 = 0;
  for (i=pos+1; i<naa ; i++) {
    if (sse[i] == '-') {
      continue;
    }
    if (sse[i] == 'H') { /* N-1 of a helix */
      hn1 = 1;
    }
    else if (sse[i] == 'E') { /* N-1 of a strand */
      en1 = 1;
    }
    else {
      break;
    }
  }
  
  for (i=pos-1; i>=0; i--) {
    if (sse[i] == '-') {
      continue;
    }
    if (sse[i] == 'H') {  /* C+1 of a helix */
      hc1 = 1;
    }
    else if (sse[i] == 'E') { /* C+1 of a strand */
      ec1 = 1;
    }
    else {
      break;
    }
  }

  if (hn1 == 1 && hc1 == 1) {
    return H_N_MINUS1_OR_H_C_PLUS1;
  }
  else if (hn1 == 1 && ec1 == 1) {
    return H_N_MINUS1_OR_E_C_PLUS1;
  }
  else if (en1 == 1 && hc1 == 1) {
    return E_N_MINUS1_OR_H_C_PLUS1;
  }
  else if (en1 == 1 && ec1 == 1) {
    return E_N_MINUS1_OR_E_C_PLUS1;
  }
  else if (hn1 ==1) {
    return H_N_MINUS1;
  }
  else if (en1 ==1) {
    return E_N_MINUS1;
  }
  else if (hc1 == 1) {
    return H_C_PLUS1;
  }
  else if (ec1 == 1) {
    return E_C_PLUS1;
  }

  return LOOP;
}

int Nflank(int *sse, int pos) {
  int i;

  for (i=pos-1; i>=0; i--) {
    if (sse[i] < 0) {
      continue;
    }
    return i;
  }
  fprintf(stderr, "Error: cannot locate the N-flank residue!\n");
  exit (-1);
}

int weight_indel(int **iindel, 
		 double **findel, int np) {
  double weight;
  int i, j;

  if (np == 1) {    /* each cluster contains only one member, so the weight is unity */
    
    for (i=0; i<NTYPE; i++) {
      for (j=0; j<2; j++) {
	if (iindel[j][i] > 0) {
	  findel[j][i] += (double) iindel[j][i];
	}
      }
    }
    for (j=0; j<2; j++) {
      if (iindel[j][H_N1_OR_H_C1] > 0) {
	findel[j][H_N1] += (double) iindel[j][H_N1_OR_H_C1] * 0.5;
	findel[j][H_C1] += (double) iindel[j][H_N1_OR_H_C1] * 0.5;
      }
      if (iindel[j][E_N1_OR_E_C1] > 0) {
	findel[j][E_N1] += (double) iindel[j][E_N1_OR_E_C1] * 0.5;
	findel[j][E_C1] += (double) iindel[j][E_N1_OR_E_C1] * 0.5;
      }
      if (iindel[j][H_N_MINUS1_OR_H_C_PLUS1] > 0) {
	findel[j][H_N_MINUS1] += (double) iindel[j][H_N_MINUS1_OR_H_C_PLUS1] * 0.5;
	findel[j][H_C_PLUS1] += (double) iindel[j][H_N_MINUS1_OR_H_C_PLUS1] * 0.5;
      }
      if (iindel[j][E_N_MINUS1_OR_E_C_PLUS1] > 0) {
	findel[j][E_N_MINUS1] += (double) iindel[j][E_N_MINUS1_OR_E_C_PLUS1] * 0.5;
	findel[j][E_C_PLUS1] += (double) iindel[j][E_N_MINUS1_OR_E_C_PLUS1] * 0.5;
      }
      if (iindel[j][H_N_MINUS1_OR_E_C_PLUS1] > 0) {
	findel[j][H_N_MINUS1] += (double) iindel[j][H_N_MINUS1_OR_E_C_PLUS1] * 0.5;
	findel[j][E_C_PLUS1] += (double) iindel[j][H_N_MINUS1_OR_E_C_PLUS1] * 0.5;
      }
      if (iindel[j][E_N_MINUS1_OR_H_C_PLUS1] > 0) {
	findel[j][E_N_MINUS1] += (double) iindel[j][E_N_MINUS1_OR_H_C_PLUS1] * 0.5;
	findel[j][H_C_PLUS1] += (double) iindel[j][E_N_MINUS1_OR_H_C_PLUS1] * 0.5;
      }
    }
    return 0;
  }

  weight = 1.0 / (double) np;

  for (i=0; i<NTYPE; i++) {
    for (j=0; j<2; j++) {
      if (iindel[j][i] > 0) {
	findel[j][i] += (double) iindel[j][i] * weight;
      }
    }
  }
      
  /* ambiguous cases */
  for (j=0; j<2; j++) {
    if (iindel[j][H_N1_OR_H_C1] > 0) {
      findel[j][H_N1] += (double) iindel[j][H_N1_OR_H_C1] * 0.5 * weight;
      findel[j][H_C1] += (double) iindel[j][H_N1_OR_H_C1] * 0.5 * weight;
    }
    if (iindel[j][E_N1_OR_E_C1] > 0) {
      findel[j][E_N1] += (double) iindel[j][E_N1_OR_E_C1] * 0.5 * weight;
      findel[j][E_C1] += (double) iindel[j][E_N1_OR_E_C1] * 0.5 * weight;
    }
    if (iindel[j][H_N_MINUS1_OR_H_C_PLUS1] > 0) {
      findel[j][H_N_MINUS1] += (double) iindel[j][H_N_MINUS1_OR_H_C_PLUS1] * 0.5 * weight;
      findel[j][H_C_PLUS1] += (double) iindel[j][H_N_MINUS1_OR_H_C_PLUS1] * 0.5 * weight;
    }
    if (iindel[j][E_N_MINUS1_OR_E_C_PLUS1] > 0) {
      findel[j][E_N_MINUS1] += (double) iindel[j][E_N_MINUS1_OR_E_C_PLUS1] * 0.5 * weight;
      findel[j][E_C_PLUS1] += (double) iindel[j][E_N_MINUS1_OR_E_C_PLUS1] * 0.5 * weight;
    }
    if (iindel[j][H_N_MINUS1_OR_E_C_PLUS1] > 0) {
      findel[j][H_N_MINUS1] += (double) iindel[j][H_N_MINUS1_OR_E_C_PLUS1] * 0.5 * weight;
      findel[j][E_C_PLUS1] += (double) iindel[j][H_N_MINUS1_OR_E_C_PLUS1] * 0.5 * weight;
    }
    if (iindel[j][E_N_MINUS1_OR_H_C_PLUS1] > 0) {
      findel[j][E_N_MINUS1] += (double) iindel[j][E_N_MINUS1_OR_H_C_PLUS1] * 0.5 * weight;
      findel[j][H_C_PLUS1] += (double) iindel[j][E_N_MINUS1_OR_H_C_PLUS1] * 0.5 * weight;
    }
  }
  return 0;
}

int count_freq(int i, int naa, strali *sali, int *ifreq) {
  int j,k;

  for (k=0; k<naa; k++) {
    if (sali[i].aaIdx[k] < 0) continue;    
    j = sali[i].sstype[k];
    ifreq[j]++;
  }
  if (opt_verbose == 1) {
    printf("ssetype of seq %d\n", i);
    for (j=0; j<NTYPE+6; j++) {
      printf("%5d ",ifreq[j]);
    }
    printf("\n");
  }
  return(1);
}

int weight_freq(int *ifreq, double *ssefreq, int nmem) {
  double weight;
  int i;

  if (nmem == 1) {    /* each cluster contains only one member, so the weight is unity */
    
    for (i=0; i<NTYPE; i++) {
      if (ifreq[i] > 0) {
	ssefreq[i] += (double) ifreq[i];
      }
    }      
    /* ambiguous cases */
    if (ifreq[H_N1_OR_H_C1] > 0) {
      ssefreq[H_N1] += (double) ifreq[H_N1_OR_H_C1] * 0.5;
      ssefreq[H_C1] += (double) ifreq[H_N1_OR_H_C1] * 0.5;
    }
    if (ifreq[E_N1_OR_E_C1] > 0) {
      ssefreq[E_N1] += (double) ifreq[E_N1_OR_E_C1] * 0.5;
      ssefreq[E_C1] += (double) ifreq[E_N1_OR_E_C1] * 0.5;
    }
    if (ifreq[H_N_MINUS1_OR_H_C_PLUS1] > 0) {
      ssefreq[H_N_MINUS1] += (double) ifreq[H_N_MINUS1_OR_H_C_PLUS1] * 0.5;
      ssefreq[H_C_PLUS1] += (double) ifreq[H_N_MINUS1_OR_H_C_PLUS1] * 0.5;
    }
    if (ifreq[E_N_MINUS1_OR_E_C_PLUS1] > 0) {
      ssefreq[E_N_MINUS1] += (double) ifreq[E_N_MINUS1_OR_E_C_PLUS1] * 0.5;
      ssefreq[E_C_PLUS1] += (double) ifreq[E_N_MINUS1_OR_E_C_PLUS1] * 0.5;
    }
    if (ifreq[H_N_MINUS1_OR_E_C_PLUS1] > 0) {
      ssefreq[H_N_MINUS1] += (double) ifreq[H_N_MINUS1_OR_E_C_PLUS1] * 0.5;
      ssefreq[E_C_PLUS1] += (double) ifreq[H_N_MINUS1_OR_E_C_PLUS1] * 0.5;
    }
    if (ifreq[E_N_MINUS1_OR_H_C_PLUS1] > 0) {
      ssefreq[E_N_MINUS1] += (double) ifreq[E_N_MINUS1_OR_H_C_PLUS1] * 0.5;
      ssefreq[H_C_PLUS1] += (double) ifreq[E_N_MINUS1_OR_H_C_PLUS1] * 0.5;
    }
    return 0;
  }

  weight = 1.0 / (double) nmem;

  for (i=0; i<NTYPE; i++) {
    if (ifreq[i] > 0) {
      ssefreq[i] += (double) ifreq[i] * weight;
    }
  }
  if (ifreq[H_N1_OR_H_C1] > 0) {
    ssefreq[H_N1] += (double) ifreq[H_N1_OR_H_C1] * 0.5 * weight;
    ssefreq[H_C1] += (double) ifreq[H_N1_OR_H_C1] * 0.5 * weight;
  }
  if (ifreq[E_N1_OR_E_C1] > 0) {
    ssefreq[E_N1] += (double) ifreq[E_N1_OR_E_C1] * 0.5 * weight;
    ssefreq[E_C1] += (double) ifreq[E_N1_OR_E_C1] * 0.5 * weight;
  }
  if (ifreq[H_N_MINUS1_OR_H_C_PLUS1] > 0) {
    ssefreq[H_N_MINUS1] += (double) ifreq[H_N_MINUS1_OR_H_C_PLUS1] * 0.5 * weight;
    ssefreq[H_C_PLUS1] += (double) ifreq[H_N_MINUS1_OR_H_C_PLUS1] * 0.5 * weight;
  }
  if (ifreq[E_N_MINUS1_OR_E_C_PLUS1] > 0) {
    ssefreq[E_N_MINUS1] += (double) ifreq[E_N_MINUS1_OR_E_C_PLUS1] * 0.5 * weight;
    ssefreq[E_C_PLUS1] += (double) ifreq[E_N_MINUS1_OR_E_C_PLUS1] * 0.5 * weight;
  }
  if (ifreq[H_N_MINUS1_OR_E_C_PLUS1] > 0) {
    ssefreq[H_N_MINUS1] += (double) ifreq[H_N_MINUS1_OR_E_C_PLUS1] * 0.5 * weight;
    ssefreq[E_C_PLUS1] += (double) ifreq[H_N_MINUS1_OR_E_C_PLUS1] * 0.5 * weight;
  }
  if (ifreq[E_N_MINUS1_OR_H_C_PLUS1] > 0) {
    ssefreq[E_N_MINUS1] += (double) ifreq[E_N_MINUS1_OR_H_C_PLUS1] * 0.5 * weight;
    ssefreq[H_C_PLUS1] += (double) ifreq[E_N_MINUS1_OR_H_C_PLUS1] * 0.5 * weight;
  }
  return 0;
}

int output_indel(double **findel, double *ssefreq) {
  int i,j;
  double nfreq[NTYPE];
  double pindel[2][NTYPE];
  double pmerge[3][7];
  double freqmerge[7];
  double sum;

  sum = 0.0;
  for (i=0; i<NTYPE; i++) {
    sum += ssefreq[i];
  }
  for (i=0; i<NTYPE; i++) {
    nfreq[i] = ssefreq[i]/sum;
  }

  for (j=0; j<2; j++) {
    sum = 0.0;
    for (i=0; i<NTYPE; i++) {
      sum += findel[j][i];
    }
    for (i=0; i<NTYPE; i++) {
      pindel[j][i] = findel[j][i]/sum;
    }
  }

  printf("ssetype\n");
  printf("count ");
  for (i=0; i<NTYPE; i++) {
    printf("%7.1f ", ssefreq[i]);
  }
  printf("\n");
  printf("prob  ");
  for (i=0; i<NTYPE; i++) {
    printf("%7.3f ", nfreq[i]);
  }
  
  printf("\n");
  printf("indel\n");
  for (j=0; j<2; j++) {
    printf("count ");
    for (i=0; i<NTYPE; i++) {
      printf("%7.1f ", findel[j][i]);
    }
    printf("\n");
    printf("prob  ");
    for (i=0; i<NTYPE; i++) {
      printf("%7.3f ", pindel[j][i]);
    }
    printf("\n");
    printf("pref  ");
    for (i=0; i<NTYPE; i++) {
      printf("%7.3f ", pindel[j][i]/nfreq[i]);
    }
    printf("\n");
  }

  /* treat insertion first */
  /* VL (very low gap penalty)  */
  /* H  (high)                  */

  /* VL = LOOP + N_MINUS1 * 2 + C_CAP * 2 + C_PLUS1 * 2 */
  /* H =  N_CAP + N1 + MIDDLE + C1 */
 
  freqmerge[0] = ssefreq[LOOP]
               + ssefreq[H_N_MINUS1] + ssefreq[H_C_CAP] + ssefreq[H_C_PLUS1] +
               + ssefreq[E_N_MINUS1] + ssefreq[E_C_CAP] + ssefreq[E_C_PLUS1];

  freqmerge[1] = ssefreq[H_N_CAP] + ssefreq[H_N1] +
                 ssefreq[H_MIDDLE] + ssefreq[H_C1];

  freqmerge[2] = ssefreq[E_N_CAP] + ssefreq[E_N1] +
                 ssefreq[E_MIDDLE] + ssefreq[E_C1];

  sum = 0;
  for (i=0; i<3; i++) {
    sum += freqmerge[i];
  }
  printf("INSERTIONS\n");
  printf("background frequencies\n");
  printf("       VL      H(h)    H(e)\n");
  printf("       ");
  for (i=0; i<3; i++) {
    printf("%7.1f ", freqmerge[i]);
    freqmerge[i] /= sum;
  }
  printf("\n");
  printf("       ");
  for (i=0; i<3; i++) {
    printf("%7.3f ", freqmerge[i]);
  }
  printf("\n\n");

  pmerge[IN_N][0] = findel[IN_N][LOOP]
                  + findel[IN_N][H_N_MINUS1] + findel[IN_N][H_C_CAP] + findel[IN_N][H_C_PLUS1] +
                  + findel[IN_N][E_N_MINUS1] + findel[IN_N][E_C_CAP] + findel[IN_N][E_C_PLUS1];
  pmerge[IN_N][1] = findel[IN_N][H_N_CAP] + findel[IN_N][H_N1] +
                    findel[IN_N][H_MIDDLE] + findel[IN_N][H_C1];
  pmerge[IN_N][2] = findel[IN_N][E_N_CAP] + findel[IN_N][E_N1] +
                    findel[IN_N][E_MIDDLE] + findel[IN_N][E_C1];

  pmerge[INDEL_N][0] = pmerge[IN_N][0];   /* very low */
  pmerge[INDEL_N][3] = pmerge[IN_N][1];   /* high for helices */
  pmerge[INDEL_N][4] = pmerge[IN_N][2];   /* high for helices */

  sum = 0.0;
  printf("count ");
  for (j=0; j<3; j++) {
    sum += pmerge[IN_N][j];
    printf("%7.1f ", pmerge[IN_N][j]);
  }
  printf("\n");
  printf("prob  ");
  for (j=0; j<3; j++) {
    pmerge[IN_N][j] /= sum;
    printf("%7.3f ", pmerge[IN_N][j]);
  }
  printf("\n");
  printf("pref  ");
  for (j=0; j<3; j++) {
    printf("%7.3f ", pmerge[IN_N][j]/freqmerge[j]);
  }
  printf("\n");

  /* treat deletion */
  /* VL (very low gap penalty)  */
  /* L  (low)                   */
  /* H  (high)                  */

  /* VL = LOOP + C_CAP * 2 + C_PLUS1 * 2 */
  /*  L  = N_MINUS1 + C1                 */
  /*  H =  N_CAP + N1 + MIDDLE           */

  freqmerge[0] = ssefreq[LOOP]
               + ssefreq[H_C_CAP] + ssefreq[H_C_PLUS1] +
               + ssefreq[E_C_CAP] + ssefreq[E_C_PLUS1];

  freqmerge[1] = ssefreq[H_N_MINUS1] + ssefreq[H_C1];

  freqmerge[2] = ssefreq[E_N_MINUS1] + ssefreq[E_C1];

  freqmerge[3] = ssefreq[H_N_CAP] + ssefreq[H_N1] + ssefreq[H_MIDDLE];

  freqmerge[4] = ssefreq[E_N_CAP] + ssefreq[E_N1] + ssefreq[E_MIDDLE];

  sum = 0.0;
  for (i=0; i<5; i++) {
    sum += freqmerge[i];
  }
  printf("DELETIONS\n");
  printf("background frequencies\n");
  printf("       VL      L(h)    L(e)    H(h)    H(e)\n");
  printf("       ");
  for (i=0; i<5; i++) {
    printf("%7.1f ", freqmerge[i]);
    freqmerge[i] /= sum;
  }
  printf("\n");
  printf("       ");
  for (i=0; i<5; i++) {
    printf("%7.3f ", freqmerge[i]);
  }
  printf("\n\n");
  
  pmerge[DEL_N][0] = findel[DEL_N][LOOP]
                   + findel[DEL_N][H_C_CAP] + findel[DEL_N][H_C_PLUS1] +
                   + findel[DEL_N][E_C_CAP] + findel[DEL_N][E_C_PLUS1];
  pmerge[DEL_N][1] = findel[DEL_N][H_N_MINUS1] + findel[DEL_N][H_C1];
  pmerge[DEL_N][2] = findel[DEL_N][E_N_MINUS1] + findel[DEL_N][E_C1];
  pmerge[DEL_N][3] = findel[DEL_N][H_N_CAP] + findel[DEL_N][H_N1] + findel[DEL_N][H_MIDDLE];
  pmerge[DEL_N][4] = findel[DEL_N][E_N_CAP] + findel[DEL_N][E_N1] + findel[DEL_N][E_MIDDLE];

  pmerge[INDEL_N][0] += pmerge[DEL_N][0];   /* very low */
  pmerge[INDEL_N][1] = pmerge[DEL_N][1];   /* low for helices */
  pmerge[INDEL_N][2] = pmerge[DEL_N][2];   /* low for strands */
  pmerge[INDEL_N][3] += pmerge[DEL_N][3];   /* high for helices */
  pmerge[INDEL_N][4] += pmerge[DEL_N][4];   /* high for strands */

  sum = 0.0;
  printf("count ");
  for (j=0; j<5; j++) {
    sum += pmerge[DEL_N][j];
    printf("%7.1f ", pmerge[DEL_N][j]);
  }
  printf("\n");
  printf("prob  ");
  for (j=0; j<5; j++) {
    pmerge[DEL_N][j] /= sum;
    printf("%7.3f ", pmerge[DEL_N][j]);
  }
  printf("\n");
  printf("pref  ");
  for (j=0; j<5; j++) {
    printf("%7.3f ", pmerge[DEL_N][j]/freqmerge[j]);
  }
  printf("\n");
  return(1);
}
