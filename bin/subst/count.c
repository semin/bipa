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
* count.c                                                       *
* Count amino acid replacements                                 *
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

int count_subst(char *filename, int nseq, PIR *seqall,
		int nfeature, int nclass,
		SCLASS *sclass,
		char **classVar, 
		int nconst, int *list_of_constrained,
		SUBST_TABLE *table, int *ncounts,
		double **findel, double *ssefreq) {
  int i, j;
  int ncode;
  int icode;
  int **iwork;
  int n;
  int *seqIdx;
  char **seqCode;
  strali *sali;   /* structural alignment
		     (a sequence of integers to represent a.a.sequnce
		     and a sequence of integers to represent the
		     asssignment of structural environments) */
  int naa;        /* length of alignment*/
  double pid_val; /* pairwise PID */

/* Preparation for assigning the structural class for each amino acid residue
   and counting amino acid substitutions. This is to access various elements of
   the structure PIR more efficiently. */

  n = maxCodelen(nseq, seqall);
  seqIdx = ivector(nseq);    /* indices for the position of sequence entries in the .tem file */
  seqCode = cmatrix(nseq, n+1);
  iwork = imatrix(nseq, nfeature); /* 2D matrix used for extracting info from
				      the .tem file */
  initialize_ivec(nseq, seqIdx, -1);
  initialize_imat(nseq, nfeature, iwork, -1);

  ncode = 0;
  for (i=0; i<nseq; i++) {
    if (strcmp(seqall[i].title, "sequence") == 0) {
      icode = isThisNewcode(seqCode, ncode, seqall[i].code);
      if (icode == -1) { /* code not stored in the list seqCode */
	(void)strcpy(seqCode[ncode], seqall[i].code);
	seqIdx[ncode] = i;
	ncode++;
      }
      else {
	if (seqIdx[icode] > 0) {  /* this code already found */
	  fprintf(stderr, "Corrupted data: >P1;%s appeared twice in the .tem file.\n", seqall[i].code);
	  fprintf(stderr, "Use different codes.\n");
	  exit (-1);
	}
	seqIdx[icode] = i;
      }
      continue;
    }
    for (j=0; j<nfeature; j++) {
      if (strcmp(seqall[i].title, sclass[j].name) == 0) { /* select feature */
	icode = isThisNewcode(seqCode, ncode, seqall[i].code);
	if (icode == -1) { /* new code */
	  (void)strcpy(seqCode[ncode], seqall[i].code);
	  iwork[ncode][j] = i;
	  ncode++;
	}
	else {
	  if (iwork[icode][j] > 0) {  /* this code already found */
	    fprintf(stderr, "Corrupted data: >P1;%s appeared twice in the .tem file.\n", seqCode[i]);
	    fprintf(stderr, "Use different codes.\n");
	    exit (-1);
	  }
	  iwork[icode][j] = i;
	}
	break;
      }
    }
  }
/**************  Main part of the calculation *************************/

  naa = strlen(seqall[seqIdx[0]].sequence);

  if (opt_verbose == 1) {
    printf("Number of proteins: %d\n", ncode);
    printf("Examining disulphide bonds...\n");  
  }
  assign_disulphide(nseq, seqall, ncode, seqIdx, seqCode); /* change C to J for
							      non disulphide-bonded cysteins */

  sali = determine_class(nfeature, iwork, seqIdx,  /* assign strEnv and aaIdx */
			 seqall, sclass, seqCode,
			 nclass, classVar, naa, ncode);

/**************  Count indels *************************/
  if (opt_anal == 1) {
    indel (naa, ncode, sali, nclass,
	   ncounts, seqIdx, seqall, seqCode, iwork,
	   findel, ssefreq);
  }


/**************  Count amino acid substitutions *************************/

  if (pclust > 0) {
    count_between_clusters (naa, ncode, sali, nclass,
			    table, ncounts, seqIdx,
			    seqall, seqCode, nconst, list_of_constrained, iwork);
  }
  else if (opt_pidmin >= 0.0 || opt_pidmax <= 100.0) {
    /* counts made only for sequence pairs falling between 
       these two PID values */

    for (i=0; i<ncode-1; i++) {
      for (j=i+1; j<ncode; j++) {

	/* calculate PID */
	pid_val = pid(seqall[seqIdx[i]].sequence, seqall[seqIdx[j]].sequence);

	if (pid_val >= opt_pidmin && pid_val < opt_pidmax) {
	  printf("%s %5.1f %s %s\n", filename, pid_val,
		 seqCode[i], seqCode[j]);
	  sum(i, j, naa, sali,
	      table, ncounts, seqall, seqCode, nconst, list_of_constrained, iwork);
	}
      }
    }
  }
  else if (opt_anal == 1) {   /*---- calculate PID (optional analysis) ---*/
    for (i=0; i<ncode-1; i++) {
      for (j=i+1; j<ncode; j++) {
	pid_val = pid(seqall[seqIdx[i]].sequence, seqall[seqIdx[j]].sequence);
	sum(i, j, naa, sali,
	    table, ncounts, seqall, seqCode, nconst, list_of_constrained, iwork);
      }
    }
  }
  else {
    for (i=0; i<ncode-1; i++) {
      for (j=i+1; j<ncode; j++) {
	sum(i, j, naa, sali,
	    table, ncounts, seqall, seqCode, nconst, list_of_constrained, iwork);
      }
    }
  }
  free_strali(ncode, naa, sali);
  return ncode;
}

int count_between_clusters (int naa, int ncode, strali *sali, int nclass,
			    SUBST_TABLE *table, int *ncounts, int *seqIdx,
			    PIR *seqall, char **seqCode, int nconst,
			    int *list_of_constrained, int **iwork) {

  cluster *clus;
  int nc;          /* number of clusters */
  int i, j;
  int i1, j1;

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

  for (i=0; i<nc-1; i++) {   /* all pairs between clusters */
    for (j=i+1; j<nc; j++) {
      if (opt_weight_not == 0) /* if use weight, clear incidence matrix
				  for each cluster-cluster comparison 
				  (bug fixed on 17 Jan 2000)
				  */
	initialize_itable(nclass, 22, 22, table, 0);

      for (i1=0; i1 < clus[i].nmem; i1++) {
	for (j1=0; j1 < clus[j].nmem; j1++) {
/*	  printf("  %d %d\n", clus[i].memlist[i1], clus[j].memlist[j1]); */

	  sum(clus[i].memlist[i1], clus[j].memlist[j1], naa, sali,
	      table, ncounts, seqall, seqCode, nconst, list_of_constrained, iwork);
	  }
      }
      weight_subst_clus(nclass, table, clus[i].nmem*clus[j].nmem);
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

cluster *clustering (int ncode, PIR *seqall, int *seqIdx,
		     char **seqCode, int *nc_ptr) {
  cluster *clus;
  double **dist;   /* distance matrix for clustering */
  double pid_val;
  int nc;          /* number of clusters */

  int i, j;

  dist = dmatrix(ncode, ncode);

  for (i=0; i<ncode-1; i++) {     /* generate a distance matrix for SL-clustering */
    for (j=i+1; j<ncode; j++) {
      pid_val = pid(seqall[seqIdx[i]].sequence, seqall[seqIdx[j]].sequence);
      if (pid_val >= pclust) {
	dist[i][j] = 0.0;
      }
      else {
	dist[i][j] = 1.0;
      }
      dist[j][i] = dist[i][j];
    }
  }
  for (i=0; i<ncode; i++) {
    dist[i][i] = 0.0;
  }
  
  clus = slinkc(ncode, dist, seqCode, nc_ptr); /* single-linkage clustering */
  nc = *nc_ptr;

  free(dist);
  return (clus);
}

int sum(int i, int j, int naa, strali *sali,
	SUBST_TABLE *table, int *ncounts,
	PIR *seqall, char **seqCode, int nconst, int *list_of_constrained, int **iwork) {

/* Count a.a. substitutions between (i,j) pair and sum them up for the entire
   alignment (position 0 to naa) */

  int k,l;
  int is, js;
  int skip;
  int ienv, jenv;

  for (k=0; k<naa; k++) {
    if (sali[i].aaIdx[k] < 0 || sali[j].aaIdx[k] < 0) {
      continue;
    }

    skip = 0;
    for (l=0; l<nconst; l++) { /* check 'constrained' features */
                               /* if a feature is not found in the .tem file, ignore it! */

      is = iwork[i][list_of_constrained[l]];  /* Where is ith code and (..[l])th feature in TEM? */
      js = iwork[j][list_of_constrained[l]];
      if (is < 0 || js < 0) continue;

      if (seqall[is].sequence[k] != seqall[js].sequence[k]) {
	skip = 1;
	break;
      }
    }
    if (skip == 1) {
      continue;
    }

    ienv = sali[i].strEnv[k];
    if (ienv < 0) {
      fprintf(stderr, "Warning: corrupted data\n");
      fprintf(stderr, "Protein %s amino acid %d at %d\n", seqCode[i], sali[i].aaIdx[k], k);
      fprintf(stderr, "no class assigned\n");
      continue;
    }
    /* amino acid i in Env i -> aino acid j (ith column) */

    table[ienv].incidence_mat[sali[j].aaIdx[k]][sali[i].aaIdx[k]]++;
    ncounts[ienv]++;

    jenv = sali[j].strEnv[k];
    if (jenv < 0) {
      fprintf(stderr, "Warning: corrupted data\n");
      fprintf(stderr, "Protein %s amino acid %d at %d\n", seqCode[j], sali[j].aaIdx[k], k);
      fprintf(stderr, "no class assigned\n");
      continue;
    }
    /* amino acid j in Env j -> aino acid i (jth column) */

    table[jenv].incidence_mat[sali[i].aaIdx[k]][sali[j].aaIdx[k]]++;
    ncounts[jenv]++;

    /*--- count change of states (optional analysis) */
    if (opt_anal == 1) {
      if (ienv < jenv) {
	printf("### %s %s %c -> %c at %d ( %s %s )\n",
	       classCode[ienv], classCode[jenv], 
	       amino_acid[sali[i].aaIdx[k]], amino_acid[sali[j].aaIdx[k]],
	       k, seqCode[i], seqCode[j]);
      }
      else if (ienv > jenv) {
	printf("### %s %s %c -> %c at %d ( %s %s )\n",
	       classCode[jenv], classCode[ienv],
	       amino_acid[sali[j].aaIdx[k]], amino_acid[sali[i].aaIdx[k]],
	       k, seqCode[j], seqCode[i]);
      }
    }
    /*--- optional analysis */
  }
  return(1);
}

strali *determine_class(int nfeature, int **ilist, int *seqIdx,
			PIR *seqall, SCLASS *sclass, char **seqCode,
			int nclass, char **classVar,
			int naa, int ncode) {
  
  strali *sali;   /* structural alignment
		     (a sequence of integers to represent a.a.sequnce
		     and a sequence of integers to represent the
		     asssignment of structural environments) */  

  int i, j, k, ii;
  int aa_idx;
  int class_idx;
  int skip;
  char s[MAX_FEATURE];

  sali = (strali *)malloc((size_t) (ncode * sizeof(strali)));
  if (!sali) {
    fprintf(stderr, "Can't allocate memory\n");
    exit(1);
  }
  for (i=0; i<ncode; i++) {
    sali[i].strEnv = ivector(naa);
    sali[i].aaIdx = ivector(naa);
  }

  for (i=0; i<ncode; i++) {
    if (seqIdx[i] < 0) {
      fprintf(stderr, "Corrupted data: There is no sequence record for protein %s\n", seqCode[i]);
      exit (-1);
    }

    j = 0;
    while (seqall[seqIdx[i]].sequence+j != NULL &&
	   seqall[seqIdx[i]].sequence[j] != '\0') {

      if (seqall[seqIdx[i]].sequence[j] == '-' ||
	  seqall[seqIdx[i]].sequence[j] == '/') {  /* skip gap positions */

	sali[i].strEnv[j] = -1;
	sali[i].aaIdx[j] = -1;
	j++;
	continue;
      }

      k = 0;
      skip = 0;
      for (ii=0; ii<nfeature; ii++) {

	if (sclass[ii].silent == 'T') {  /* 'silent' feature */
	  continue;
	}
	if (ilist[i][ii] < 0) {
	  fprintf(stderr, "Warning: No \"%s\" record was found for protein %s\n",
		  sclass[ii].name, seqCode[i]);
	  fprintf(stderr, "maybe the .tem file is corrupted\n");
	  s[k] = '?';
	}
	else {
	  s[k] = seqall[ilist[i][ii]].sequence[j];
	  if (s[k] == SKIP_CHARACTER) {         /* Skip if the feature value is
						   SKIP_CAHRACTER ('X') */
	    skip = 1;
	    break;
	  }
	}
	k++;
      }
      if (skip == 1) {
	sali[i].strEnv[j] = -1;
	sali[i].aaIdx[j] = -1;
	j++;
	continue;
      }      
      s[k] = '\0';

      class_idx = whichClass(classVar, nclass, s);
      if (class_idx < 0) {
	fprintf(stderr, "Warning: Cannot assign structural class (corrupted data?)\n");
	fprintf(stderr, "protein %s at %d ", seqall[seqIdx[i]].code, j);
	fprintf(stderr, "(%s)\n", s);
	continue;
      }
      aa_idx = cindex(amino_acid, seqall[seqIdx[i]].sequence[j]);

      sali[i].aaIdx[j] = aa_idx;
      sali[i].strEnv[j] = class_idx;
      j++;
    }
  }

  /* assumes the secondary structure is the FIRST feature in the list */
  /* (this has to be checked!!!) */

  if (opt_anal == 1) {
    for (i=0; i<ncode; i++) {
      sali[i].sstype = ivector(naa);
      for (j=0; j<naa; j++) {
	if (sali[i].aaIdx[j] < 0) {
	  sali[i].sstype[j] = -1;
	}
	else {
	  sali[i].sstype[j] = assign_sstype(seqall[ilist[i][0]].sequence,
					    j, naa);	  
	}
      }
      if (opt_verbose == 1) {
	printf("sse type assignment for sequence %d\n", i);
	for (j=0; j<naa; j++) {
	  if (sali[i].aaIdx[j] < 0) {
	    continue;
	  }
	  printf("%c %d\n", amino_acid[sali[i].aaIdx[j]], sali[i].sstype[j]);
	}
      }
    }
  }
  return sali;
}

void free_strali (int ncode, int naa, strali *sali) {
  int i;
  for (i=0; i<ncode; i++) {
    free(sali[i].aaIdx);
    free(sali[i].strEnv);
  }
  if (opt_anal == 1) {
    for (i=0; i<ncode; i++) {
      free(sali[i].sstype);
    }
  }
  free(sali);
}
