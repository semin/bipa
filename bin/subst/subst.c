/*
*
* $Id:
* subst release $Name:  $
*/
/****************************************************************
* subst: A program to calculate environment-specific            *
*        amino acid substitution tables                         *
* Copyright (C) 1999-2000  Kenji Mizuguchi                      *
*                                                               *
*                                                               *
* subst.c                                                       *
* Core functions for the subst program                          *
*                                                               *
* The program reads in a file ('classdef.dat') that specifies   *
* structural features used (e.g., secondary structure,          *
* solvent accessibility) and defines all possible structural    *
* environments (e.g., env1 - helix, accessible, env2 - helix,   *
* buried, env3 - strand, accessible). It reads in formatted     *
* alignments produced by the program JOY and counts amino acid  *
* replacements at structurally aligned positions in a specific  *
* environment. If there are N environments, the results can be  *
* summarized in N 21x21 amino acid substitution matrices. SUBST * 
* can produce 1) raw substitution counts, 2) conservation       *
* probability of individual amino acids and 3) log-odds         *
* substitution scores. See each source file for more details.   *
*                                                               *
* Author: Kenji Mizuguchi                                       *
*                                                               *
* Date:         5 Mar 1999                                      *
*                                                               *
****************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
/* #include <values.h> */
#include <float.h>
#include <limits.h>
#include <time.h>

#include "utility.h"
#include "options.h"
#include "subst.h"
#include "rdtem.h"
#include "analysis.h"
#include "slink.h"
#include "combination.h"
#include "indel.h"
#include "release.h"

char *amino_acid = "ACDEFGHIKLMNPQRSTVWYJ";
char **classCode;    /* this is a tricky variable, needs to be moved to SUBST_TABLE? */
double gtot;     /* grand total of all incidence matrices */
double E;        /* expected score */

static double Etot;  /* Expected score for the total matrix */
static double Htot;  /* Entropy for the total matrix */
/* static double q[22][22]; for debugiing */

int subst (int optind, int ntem, char **tem_list, int nfeature, SCLASS *sclass) {
  /* nfeature:   # of structural features */
  /* SCLASS sclass[MAX_FEATURE]: store information about residue structural classes */

  FILE *tem_file;   /* input .tem file */

  char **classVar;
  SUBST_TABLE *table;  /* substitution tables */
  smooth W_all[2];     /* aggregated frequency tables (each *ROW* corresponds to one distribution) */
  score_matrix *smat = NULL;

  int nclass;
  PIR *seqall;
  int nseq;
  int nconst;    /* number of features 'constrained' */
  int *list_of_constrained;
  int nnsf;        /* number of features that are not 'silent' (therefore used for calculation) */
  int *list_no_silent; /* stores feature numbers that are not 'silent' */
  int *ncounts;  /* stores the total number of counts for each structural environment */
  double *factors; /* to normalize the weighted counts */
  int ncode;     /* number of proteins in each alignment */
  p1_p4 *p1_p4distr;
  double **pall;  /* matrix for all environments */
  double **findel = NULL;
  double *ssefreq = NULL;
  double add;    /* add this value to all raw counts when calculating non-smoothed log-odds */

  int i;

/*************************************************************
      check options
**************************************************************/
  if (opt_pidmin >= 0.0 || opt_pidmax <= 100.0) {
    /* counts made only for sequence pairs falling between 
       these two PID values.

       NO WEIGHTS AND NO CLUSTERING in this case */
    
    opt_weight_not = 1;
  }

  if (opt_weight_not == 1 && opt_output > 1) {
    /* no weight but log-odds output specified */
    fprintf(stderr, "Error: output format not supported\n\n");
    fprintf(stderr, "You have to add an option either --output 0 (raw counts) or\n");
    fprintf(stderr, "--output 1 (substitution probabilities).\n");
    fprintf(stderr, "(When the noweight option is specified, only raw counts or\n");
    fprintf(stderr, "substitution probabilities can be produced.)\n");
    exit(-1);
  }
  else if (opt_weight_not == 1) {
    pclust = -1; /* no weight, thus no clustering and no smoothing */
    opt_smooth_not = 1;
  }
/*************************************************************
      initialization
**************************************************************/
  nclass = getNclass(nfeature, sclass);
  classVar = cmatrix(nclass, nfeature+1);
  classCode = cmatrix(nclass, nfeature+1);

  table = allocate_subst_table(nclass, 22);

  if (opt_weight_not == 0) {   /* use weight */
    initialize_dtable(nclass, 22, 22, table, 0.0);
  }
  else {
    initialize_itable(nclass, 22, 22, table, 0);
  }

  list_of_constrained = ivector(nfeature);
  nconst = chk_constraints(nfeature, sclass, list_of_constrained);

  list_no_silent = ivector(nfeature);
  nnsf = getAllclass(nfeature, sclass, nclass, table,
		     classVar, list_no_silent);
  
  if (opt_verbose == 1) {
    printf("%d features (%d classes) read in\n", nfeature, nclass);
    if (nconst > 0) {
      for (i=0; i<nconst; i++) {
	printf("Feature %d constrained\n", list_of_constrained[i]+1);
      }
      printf("(substitution counted only for pairs with same states of this feature)\n");
    }
  }

  ncounts = ivector(nclass);
  initialize_ivec(nclass, ncounts, 0);
  factors = dvector(nclass);
  initialize_dvec(nclass, factors, 0.0);

  if (opt_anal == 1) {
    findel = dmatrix(2, NTYPE);
    ssefreq = dvector(NTYPE);

    initialize_dvec(NTYPE, ssefreq, 0.0);
    initialize_dmat(2, NTYPE, findel, 0.0);
  }
/*************************************************************
      read in .tem files and obtain substitution counts
**************************************************************/
  for (i=optind; i<ntem; i++) {
    if (opt_weight_not == 0) {   /* if use weight, clear incidence matrix for each family */
      initialize_itable(nclass, 22, 22, table, 0);
    }

    tem_file = fopen(tem_list[i], "r");
    if (tem_file == NULL) {
      fprintf(stderr, "Error: Unable to open %s\n", tem_list[i]);
      return(-1);
    }
    nseq = check_file(tem_file);   /* total no. of records to read in */
    if (nseq == 0) {
      fprintf(stderr, "Error: no sequence in %s\n", tem_list[i]);
      return(-1);
    }      
  
    seqall = (PIR *) malloc(sizeof(PIR) * nseq);
    if (seqall == NULL) {
      fprintf(stderr, "Error: out of memory\n");
      exit(-1);
    }
    rdseq(tem_file, nseq, seqall);
    fclose(tem_file);

    if (opt_verbose == 1) {
      printf("### %s\n", tem_list[i]);
      printf("%d records read in\n", nseq);
    }

    ncode = count_subst(tem_list[i], nseq, seqall, nfeature, nclass, sclass, 
			classVar, nconst, list_of_constrained,
			table, ncounts, findel, ssefreq);

    /* old weighting scheme (now obsolete!) */
    if (opt_weight_not == 0 && pclust <= 0) {
      weight_subst(nclass, table, ncode, factors);
    }
    free_seq(seqall, nseq);
  }

/*************************************************************
      end of generaring raw count (incidence) tables 
**************************************************************/
  if (opt_anal == 1) {
    output_indel(findel, ssefreq);
    return(1);
  }

  /* old weighting scheme (now obsolete!) */
  if (opt_weight_not == 0 && pclust <= 0) {
    fprintf(stderr, "normalizing tables...\n");
    normalize_table(nclass, table, ncounts, factors);
  }

  if (opt_weight_not == 1 && opt_output == 0) { /* no weight, output raw count */
    fprintf(stderr, "Output raw counts with no weight\n");
    print_oldformatted_rawcounts (nclass, table);
    return(1);
  }
  else if (opt_weight_not == 1 && opt_output == 1) {
    /* no weight, output substitution probabilities */
    fprintf(stderr, "Output substitution probabilities with no weight\n");
    noweight2prob(nclass, table, nfeature, sclass, ntem);
    return(1);
  }
  else if (opt_output == 0) { /* no smoothing, output raw counts */
    fprintf(stderr, "Output weighted raw counts (no smoothing)\n");
    if ( pclust > 0)
      fprintf(stderr, "weighting scheme: clustering at PID %d level\n", pclust);

    print_oldformatted_rawcounts (nclass, table);
    return(1);
  }
/*************************************************************
  smoothing
**************************************************************/
  if (opt_smooth_not == 1) {   /* even with no smoothing, probablity calculation is required */

    if (opt_add > 0) {
      add = opt_add;
    }
    else {
      add = 1.0/(double)nclass;
    }
    
    addCounts(nclass, table, add);    /* add a constant value to all the counts (is this ok?) */
    sumTable(nclass, table);  /* obtain column and row sums */

    pall = totaltable(nclass, table);  /* summed probability table (all environments) */

    p1_p4distr = unsmoothed_bg(nclass, table);
  }
  else {                      /* smoothing */
    W_all[0].E = NULL;
    W_all[1].E = NULL;

    p1_p4distr = bg_distrib (nclass, table, nfeature, sclass,
			     nnsf, list_no_silent, W_all);

    /* matrix for all environments */
    pall = p2table(21, nfeature, W_all);
  }

/*************************************************************
  log-odds matrices
**************************************************************/
  if (opt_output == 2) {
    smat = calLogodds(nclass, table, p1_p4distr->p4, p1_p4distr->p1);
    logodds_total(smat, nclass, pall, p1_p4distr->p1);
  }
/*************************************************************
  output substitution tables
**************************************************************/
  printOutMatrices(nclass, table, smat, nfeature,
		   pall, sclass, ntem);
  return(1);
}


SUBST_TABLE *allocate_subst_table(int nclass, int n) {

  SUBST_TABLE *table;
  int i;
  
  table = (SUBST_TABLE *)malloc((size_t) (nclass * sizeof(SUBST_TABLE)));
  if (!table) {
    fprintf(stderr, "Can't allocate memory\n");
    exit(1);
  }
  for (i=0; i<nclass; i++) {
    table[i].n = n;
    table[i].incidence_mat = imatrix(n, n);
    table[i].weighted_mat = dmatrix(n, n);
  }
  return table;
}  

void initialize_itable(int nclass, int n, int m, 
		       SUBST_TABLE *table, int init_val) {
  int i;
  for (i=0; i<nclass; i++) {
    initialize_imat(n, m, table[i].incidence_mat, init_val);
  }
}

void initialize_dtable(int nclass, int n, int m, 
		       SUBST_TABLE *table, double dinit_val) {
  int i;
  for (i=0; i<nclass; i++) {
    initialize_dmat(n, m, table[i].weighted_mat, dinit_val);
  }
}



void weight_subst(int nclass, SUBST_TABLE *table, int ncode,
		  double *factors) {
  double weight;
  int iclass;
  int total;
  int i, j, n;

  weight = 2.0 / (double) (ncode * (ncode - 1));

  printf("weight is %f\n", weight);
  for (iclass = 0; iclass < nclass; iclass++) {
    n = table[iclass].n;
    total = 0;
    for (i=0; i<n; i++) {
      for (j=0; j<n; j++) {
        table[iclass].weighted_mat[i][j] += 
	  ((double)table[iclass].incidence_mat[i][j] * weight);
	total += table[iclass].incidence_mat[i][j];
      }
    }
    factors[iclass] += (double) total * weight;
  }
}

void weight_subst_clus(int nclass, SUBST_TABLE *table, int np) {
  
  double weight;
  int iclass;
  int i, j, n;

  if (np == 1) {    /* each cluster contains only one member, so the weight is unity */

    for (iclass = 0; iclass < nclass; iclass++) {
      n = table[iclass].n;
      for (i=0; i<n; i++) {
	for (j=0; j<n; j++) {
	  if (table[iclass].incidence_mat[i][j] == 0) continue;
	  
	  table[iclass].weighted_mat[i][j] += 
	    (double)table[iclass].incidence_mat[i][j];
	}
      }
    }
    return;
  }

  weight = 1.0 / (double) np;

  for (iclass = 0; iclass < nclass; iclass++) {
    n = table[iclass].n;
    for (i=0; i<n; i++) {
      for (j=0; j<n; j++) {
	if (table[iclass].incidence_mat[i][j] == 0) continue;

        table[iclass].weighted_mat[i][j] += 
	  ((double)table[iclass].incidence_mat[i][j] * weight);
      }
    }
  }
}

void normalize_table(int nclass, SUBST_TABLE *table,
		     int *ncounts, double *factors) {
  int i, j, n;
  double factor;
  double dval;
  int iclass;

  for (iclass = 0; iclass < nclass; iclass++) {

    if (ncounts[iclass] == 0) continue;  /* do nothing if there is no counts */

    n = table[iclass].n;
    factor = (double) ncounts[iclass]/factors[iclass];
    for (i=0; i<n; i++) {
      for (j=0; j<n; j++) {
	dval = table[iclass].weighted_mat[i][j] * factor;
	table[iclass].weighted_mat[i][j] = mrint(dval);
      }
    }
  }
}

int isThisNewcode(char **seqCode, int ncode, char *code) {
  int i;
  for (i=0; i<ncode; i++) {
    if (strcmp(seqCode[i], code) == 0) {
      return i;
    }
  }
  return -1;
}

/* change C to J for non disulphide-bonded cysteins */

int assign_disulphide(int nseq, PIR *seqall, int ncode,
		      int *seqIdx, char **seqCode) {
  int i, j, k;
  int *disulphide_Idx;

  disulphide_Idx = ivector(ncode);    /* indices for the position of disulhpide entries in the .tem file */
  for (i=0; i<ncode; i++) {
    disulphide_Idx[i] = -1;
  }

  for (i=0; i<nseq; i++) {
    if (strcmp(seqall[i].title, DISULPHIDE_FEATURE) != 0) {
      continue;
    }
   /* 'disulhpide' found! */

    for (j=0; j<ncode; j++) {
      if (strcmp(seqCode[j], seqall[i].code) == 0) {

	if (opt_verbose == 1) {
	  printf("%s...\n", seqCode[j]);
	}
	disulphide_Idx[j] = i;
	k = 0;
	while (seqall[seqIdx[j]].sequence+k != NULL &&
	       seqall[seqIdx[j]].sequence[k] != '\0') {
	  if (seqall[seqIdx[j]].sequence[k] == 'C') {
	    if (seqall[i].sequence[k] == 'F') {   /* disulhpide FALSE */
	      seqall[seqIdx[j]].sequence[k] = 'J';
	      if (opt_verbose == 1) {
		printf("  C at %d changed to J\n", k);
	      }
	    }
	  }
	  k++;
	}
      }
    }
  }
  for (i=0; i<ncode; i++) {
    if (disulphide_Idx[i] < 0) {
      fprintf(stderr, "Warning: No disulphide information for %s\n", seqCode[i]);
      fprintf(stderr, "All the Cys in this protein are regarded as C (disulhpide bonded)\n");
    }
  }
  free(disulphide_Idx);
  return 0;
}

int printOutMatrices (int nclass, SUBST_TABLE *table,
		      score_matrix *smat,
		      int nfeature, double **pall,
		      SCLASS *sclass, int ntem) {
  FILE *outfile;
  char *filename;
  struct tm *date;
  time_t timep;
  int i;

  if (outputfile) {
    filename = strdup(outputfile);
  }
  else {
    filename = strdup("allmat.dat");
  }
  outfile = fopen(filename, "w");
  if (outfile == NULL) {
    fprintf(stderr, "Error: Unable to open %s\n", filename);
    return (-1);
  }

  time(&timep);
  date = localtime(&timep);

  fprintf(outfile, "#\n");
  fprintf(outfile, "# Environment-specific amino acid substitution matrices\n");
  fprintf(outfile, "# Creator: subst version ");
  fprintf(outfile, MAINVERSION);
  fprintf(outfile, ".");
  fprintf(outfile, SUBVERSION);
  fprintf(outfile, "\n");
  fprintf(outfile, "# CreationDate: ");
  fprintf(outfile, "%d/%d/%d %d:%d:%d\n",
	  date->tm_mday, date->tm_mon+1,
	  date->tm_year+1900, date->tm_hour,
	  date->tm_min, date->tm_sec);
  fprintf(outfile, "#\n");
  fprintf(outfile, "# Definitions for structural environments:\n");
  fprintf(outfile, "# %d features used\n", nfeature);
  fprintf(outfile, "#\n");
  for(i=0; i<nfeature; i++) {
    fprintf(outfile, "# ");
    fprintf(outfile, "%s;", (sclass+i)->name);
    fprintf(outfile, "%s;", (sclass+i)->var);
    fprintf(outfile, "%s;", (sclass+i)->code);
    fprintf(outfile, "%c;", (sclass+i)->constrained);
    fprintf(outfile, "%c\n", (sclass+i)->silent);
  }
  fprintf(outfile, "#\n");
  fprintf(outfile, "# (read in from classdef.dat)\n");
  fprintf(outfile, "#\n");

  fprintf(outfile, "# Number of alignments: %d\n", ntem);
  if (listfilename) {
    fprintf(outfile, "# (list of .tem files read in from %s)\n", listfilename);
  }
  else {
    fprintf(outfile, "# (.tem files specified as command line arguments)\n");
  }
  fprintf(outfile, "#\n");
  fprintf(outfile, "# Total number of environments: %d\n", nclass);
  if ( pclust > 0) {
    fprintf(outfile, "# Weighting scheme: clustering at PID %d level\n", pclust);
  }
  fprintf(outfile, "#\n");
  fprintf(outfile, "# Smoothing:\n");
  if (opt_smooth_not == 1) {
    fprintf(outfile, "# none\n");
    fprintf(outfile, "#\n");
  }
  else {
    fprintf(outfile, "# p1(ri) (i.e., amino acid composition) is estimated by summing over\n");
    fprintf(outfile, "# each row in all matrices (no smoothing)\n");
    fprintf(outfile, "#                           ^^^^^^^^^^^^\n");
    fprintf(outfile, "# p2(ri|Rj) is estimated as:\n");
    fprintf(outfile, "#    p2(ri|Rj) = omega1 * p1(ri) + omega2 * W2(ri|Rj)\n");
    fprintf(outfile, "# \n");
    fprintf(outfile, "# p3(ri|Rj,fq) is estimated as:\n");
    fprintf(outfile, "#    p3(ri|Rj,fq) = omega1 * A2(ri|fq) + omega2 * W3(ri|Rj,fq)\n");
    fprintf(outfile, "# where\n");
    fprintf(outfile, "#    A2(ri|fq) = p2(ri|fq) (fixed fq; partial smoothing)\n");
    fprintf(outfile, "# \n");
    fprintf(outfile, "# The smoothing procedure is curtailed here and finally\n");
    fprintf(outfile, "# p5(ri|Rj,...) is estimated as:\n");
    fprintf(outfile, "#    p5(ri|Rj,...) = omega1 * A3(ri|Rj,fq) + omega2 * W5(ri|Rj...)\n");
    fprintf(outfile, "# where\n");
    fprintf(outfile, "#    A3(ri|Rj,fq) = sum over fq omega_c * pc3(Rj,fq)\n");
    fprintf(outfile, "# \n");
    fprintf(outfile, "# Weights (omegas) are calculated as in Topham et al. 1993)\n");
    fprintf(outfile, "# \n");
    fprintf(outfile, "# sigma value used is: %5.2f\n",opt_sigma);
    fprintf(outfile, "# \n");
  }

  if (opt_output == 1) { /* substitution probablity */
    print_prob(nclass, table, nfeature, pall, outfile);
  }
  else if (opt_output == 2) { /* log-odds in 1/opt_scale bit rounded to the nearest integer */
    print_logodds(nclass, smat, outfile);
  }
  fclose(outfile);
  return(1);
}

int print_prob(int nclass, SUBST_TABLE *table,
	       int nfeature, double **pall, FILE *outfile) {
  int n;
  int iclass;
  int i,j;

  n = table[0].n -1;

  fprintf(outfile, "# Each column (j) represents the probability distribution for the \n");
  fprintf(outfile, "# likelihood of acceptance of a mutational event by a residue type j in \n");
  fprintf(outfile, "# a particular structural environment (specified after >) leading to \n");
  fprintf(outfile, "# any other residue type (i) and sums up to 100.\n");
  fprintf(outfile, "#\n");
  fprintf(outfile, "# There are %d amino acids considered.\n", n);
  fprintf(outfile, "# %s\n", amino_acid);
  fprintf(outfile, "#\n");

  for (iclass = 0; iclass < nclass; iclass++) {
    fprintf(outfile, ">%s %d\n",classCode[iclass], iclass);
    fprintf(outfile, "#   ");
    for (j=0; j<n; j++) {
      fprintf(outfile, "     %c ", amino_acid[j]);
    }
    fprintf(outfile, "\n");

    for (i=0; i<n; i++) {
      fprintf(outfile, "%c   ", amino_acid[i]);
      for (j=0; j<n; j++) {
	fprintf(outfile, "%6.2f ", table[iclass].weighted_mat[i][j]);
      }
      fprintf(outfile, "\n");
    }
  }

  fprintf(outfile, ">total %d\n",nclass);
  fprintf(outfile, "#   ");
  for (j=0; j<n; j++) {
    fprintf(outfile, "     %c ", amino_acid[j]);
  }
  fprintf(outfile, "\n");

  for (i=0; i<n; i++) {
    fprintf(outfile, "%c   ", amino_acid[i]);
    for (j=0; j<n; j++) {
      fprintf(outfile, "%6.2f ", pall[i][j]);
    }
    fprintf(outfile, "\n");
  }
  return(1);
}

int print_logodds(int nclass, score_matrix *smat,
		  FILE *outfile) {
  int n;
  int iclass;
  int i,j;

  if (opt_cys == 0) {
    n = smat[0].n-1;
  }
  else {
    n = smat[0].n;
  }

  fprintf(outfile, "# Each column (j) represents the probability distribution for the \n");
  fprintf(outfile, "# likelihood of acceptance of a mutational event by a residue type j in \n");
  fprintf(outfile, "# a particular structural environment (specified after >) leading to \n");
  fprintf(outfile, "# any other residue type (i).\n");
  fprintf(outfile, "#\n");
  fprintf(outfile, "# The probabilities were then divided by the background probabilities\n");
  if (opt_penv == 0) {
    fprintf(outfile, "# which were derived from the environment-independent amino acid frequencies.\n");
    fprintf(outfile, "#                             ^^^^^^^^^^^^^^^^^^^^^^^\n");
  }
  else {
    fprintf(outfile, "# which were derived from the environment-dependent amino acid frequencies.\n");
    fprintf(outfile, "#                             ^^^^^^^^^^^^^^^^^^^^^\n");
  }
  fprintf(outfile, "#\n");
  fprintf(outfile, "# Shown here are logarithms of these values multiplied by %d/log(2) \n", opt_scale);
  fprintf(outfile, "# rounded to the nearest integer (log-odds scores in 1/%d bit units).\n", opt_scale);
  fprintf(outfile, "#\n");
  fprintf(outfile, "# There are %d amino acids considered.\n", n);
  fprintf(outfile, "# %s\n", amino_acid);
  fprintf(outfile, "#\n");
  fprintf(outfile, "# For total (composite) matrix, Entropy = %6.4f bits, Expected score = %7.4f\n",
	  Htot, Etot);
  fprintf(outfile, "#\n");

  for (iclass = 0; iclass < nclass; iclass++) {
    fprintf(outfile, ">%s %d\n",classCode[iclass], iclass);
    fprintf(outfile, "#   ");
    for (j=0; j<n; j++) {
      fprintf(outfile, "   %c ", amino_acid[j]);
    }
    fprintf(outfile, "\n");

    for (i=0; i<n; i++) {
      fprintf(outfile, "%c   ", amino_acid[i]);
      for (j=0; j<n; j++) {
	fprintf(outfile, "%4d ", smat[iclass].value[i][j]);
      }
      fprintf(outfile, "\n");
    }
    if (opt_cys == 0) {
      fprintf(outfile, "U   ");
      for (j=0; j<n; j++) {
	fprintf(outfile, "%4d ", smat[iclass].value[n][j]);
      }
      fprintf(outfile, "\n");
    }
  }

  fprintf(outfile, ">total %d\n",nclass);
  fprintf(outfile, "#   ");
  for (j=0; j<n; j++) {
    fprintf(outfile, "   %c ", amino_acid[j]);
  }
  fprintf(outfile, "\n");

  for (i=0; i<n; i++) {
    fprintf(outfile, "%c   ", amino_acid[i]);
    for (j=0; j<n; j++) {
      fprintf(outfile, "%4d ", smat[nclass].value[i][j]);
    }
    fprintf(outfile, "\n");
  }
  if (opt_cys == 0) {
    fprintf(outfile, "U   ");
    for (j=0; j<n; j++) {
      fprintf(outfile, "%4d ", smat[nclass].value[n][j]);
    }
    fprintf(outfile, "\n");
  }
  return(1);
}

/*************************************************************
   calculate p1 and p4 distributions for unsmoothed data
**************************************************************/
p1_p4 *unsmoothed_bg (int nclass, SUBST_TABLE *table) {
  
  p1_p4 *p1_p4distr;

  p1_p4distr = (p1_p4 *)malloc((size_t) sizeof(p1_p4));

  p1_p4distr->p1 = calP1(nclass, table);
  
  if (opt_penv == 0) {
    p1_p4distr->p4 = calP4_nonspecific(nclass, table, p1_p4distr->p1);
  }
  else {
    p1_p4distr->p4 = calP4unsmooth(nclass, table);
  }

  raw2prob(nclass, table);   /* table will be modified here */

  return (p1_p4distr);
}					      
/*************************************************************
   calculate the background distributions
**************************************************************/
p1_p4 *bg_distrib (int nclass, SUBST_TABLE *table,
		   int nfeature, SCLASS *sclass,
		   int nnsf, int *list_no_silent,
		   smooth *W_all) {
  int ks;
  p1_p4 *p1_p4distr;

  p1_p4distr = (p1_p4 *)malloc((size_t) sizeof(p1_p4));

  /* printf("summing up tables...\n")  */
  sumTable(nclass, table);   /* obtain column and row sums */
  
  /* printf("calculating p1...\n"); */
  p1_p4distr->p1 = calP1(nclass, table);   /* obtain the distribution p1 
					    (unlike the Topham paper, no smoothing
					    has been performed at this level) */

  get_merged_class(nfeature, W_all, sclass, nnsf, list_no_silent);

  for (ks=1; ks<=2; ks++) {
    W_all[ks-1].W = merge_table (nfeature, nclass, table, W_all[ks-1].mc, W_all[ks-1].ndistr);
  }

  calP2(nclass, table, nfeature, p1_p4distr->p1, W_all);

  calP3(nclass, table, nfeature, W_all);

  if (opt_output == 2 && opt_penv == 1) {   /* only for log-odds */
    p1_p4distr->p4 = calP4(nclass, table, nfeature, nnsf, W_all);
  }
  else if (opt_output == 2) {
    p1_p4distr->p4 = calP4_nonspecific(nclass, table, p1_p4distr->p1);    
  }

  calPfinal(nclass, table, nfeature, nnsf, W_all);   /* table will be modified here */

  return p1_p4distr;
}

int noweight2prob(int nclass, SUBST_TABLE *table,
		  int nfeature, SCLASS *sclass,
		  int ntem) {

  /* convert raw counts with no weight into 
     substitution probabilites and print them out */

  int ic;
  int i;
  int j;
  int n;
  double cs; /* column sum */
  double factor;
  int **count_all; /* composite matrix */
  double **pmat;
  score_matrix *smat = NULL; /* not used */

  n = table[0].n - 1;
  for (ic=0; ic<nclass; ic++) {
    for (j=0; j<n; j++) {
      cs = 0;
      for (i=0; i<n; i++) {
	cs += table[ic].incidence_mat[i][j];
      }
      if (cs == 0) { /* column sum is zero */
	for (i=0; i<n; i++) {
	  table[ic].weighted_mat[i][j] = 0.0;
	}
      }
      else {
	factor = 100.0/ (double)cs;
	for (i=0; i<n; i++) {
	  table[ic].weighted_mat[i][j] =
	    (double)table[ic].incidence_mat[i][j] * factor;
	}
      }
    }
  }
  /* produce total counts (environment-independent matrix) */

  count_all = imatrix(n, n);
  initialize_imat(n, n, count_all, 0);
  for (ic=0; ic<nclass; ic++) {
    for (i=0; i<n; i++) {
      for (j=0; j<n; j++) {
	count_all[i][j] += table[ic].incidence_mat[i][j];
      }
    }
  }

  pmat = dmatrix(n, n);  /* including row and column sums */
  initialize_dmat(n, n, pmat, 0.0);

  for (j=0; j<n; j++) {
    cs = 0;
    for (i=0; i<n; i++) {
      cs += count_all[i][j];
    }
    if (cs == 0) { /* column sum is zero */
      for (i=0; i<n; i++) {
	pmat[i][j] = 0.0;
      }
    }
    else {
      factor = 100.0/ (double)cs;
      for (i=0; i<n; i++) {
	pmat[i][j] =
	  (double)count_all[i][j] * factor;
      }
    }
  }
/*************************************************************
  output substitution tables
**************************************************************/
  printOutMatrices(nclass, table, smat, nfeature,
		   pmat, sclass, ntem);
  return(1);
}

void sumTable(int nclass, SUBST_TABLE *table) {
  /* obtain column and row sums */
  int ic;
  int i;
  int j;
  int n;
  double cs;  /* column sum */
  double rs;  /* row sum */
  double gt;  /* grand total */

  n = table[0].n - 1;
  gtot = 0.0;
  for (ic=0; ic<nclass; ic++) {
    for (i=0; i<n; i++) {
      cs = 0.0;
      for (j=0; j<n; j++) {
	cs += table[ic].weighted_mat[i][j];
      }
      table[ic].weighted_mat[i][n] = cs;
    }

    for (j=0; j<n; j++) {
      rs = 0.0;
      for (i=0; i<n; i++) {
	rs += table[ic].weighted_mat[i][j];
      }
      table[ic].weighted_mat[n][j] = rs;
    }

    gt = 0.0;
    for (i=0; i<n; i++) {
      gt += table[ic].weighted_mat[i][n];
    }
    table[ic].weighted_mat[n][n] = gt;

    gtot += gt;
  }
}

/* add one to all the counts (Laplace's rule) 
   for unsmoothed data                       */
void addCounts(int nclass, SUBST_TABLE *table, double a) {

  int ic;
  int i;
  int j;
  int n;

  n = table[0].n - 1;
  for (ic=0; ic<nclass; ic++) {
    for (i=0; i<n; i++) {
      for (j=0; j<n; j++) {
	table[ic].weighted_mat[i][j] += a;
      }
    }
  }
}

int raw2prob(int nclass, SUBST_TABLE *table) {
  /* table will be modified here */

  int ic;
  int i;
  int j;
  int n;
  double factor;

  n = table[0].n - 1;
  for (ic=0; ic<nclass; ic++) {
    for (j=0; j<n; j++) {
      factor = 	100.0 / table[ic].weighted_mat[n][j];
      for (i=0; i<n; i++) {
	table[ic].weighted_mat[i][j] *= factor;
      }
    }
  }
  return(1);
}

double **totaltable(int nclass, SUBST_TABLE *table) {

  double **pmat;
  int ic;
  int i,j,n;
  double factor;
  /*  double tot; */

  n = table[0].n - 1;
  pmat = dmatrix(n+1, n+1);  /* including row and column sums */
  initialize_dmat(n+1, n+1, pmat, 0.0);

  for (ic=0; ic<nclass; ic++) {
    for (i=0; i<n+1; i++) {
      for (j=0; j<n+1; j++) {
	pmat[i][j] += table[ic].weighted_mat[i][j];
      }
    }
  }

/* debug
  tot = 0.0;
  for (i=0; i<n; i++) {
    for (j=0; j<i; j++) {
      tot += pmat[i][j];
    }
    tot += pmat[i][i] * 0.5;
  }
  printf("triangle total %f original total %f\n", tot, gtot);
  printf("m00 m01 m02 %f %f %f\n", pmat[0][0], pmat[0][1], pmat[0][2]);
  printf("column sum(0) row sum(0) %f %f\n", pmat[n][0], pmat[0][n]);
  for (i=0; i<n; i++) {
    for (j=0; j<i; j++) {
      q[i][j] = pmat[i][j]/tot;
    }
    q[i][i] = pmat[i][i]*0.5/tot;
  }
*/

  if (opt_verbose == 1) {
    printf("######\n");
    for (i=0; i<=n; i++) {
      for (j=0; j<=n; j++) {
	printf("%6d.", (int) pmat[i][j]);
      }
      printf("\n");
    }
    printf("######\n");
  }

  for (j=0; j<n; j++) {
    factor = 100.0 / pmat[n][j];
    for (i=0; i<n; i++) {
      pmat[i][j] *= factor;
    }
  }

  return (pmat);
}

score_matrix *calLogodds(int nclass, SUBST_TABLE *table,
			 double **p4, double *p1) {
  int n;
  int ic;
  int C_idx = 1;
  int J_idx = 20;   /* indices for C and J */
  int i;
  int j;
  double odds;
  double factor;
  double p4cj = 1.0;  /* background frequency for C or J 
		         (initial value not used) */
  double p4inv[25];
  score_matrix *smat;
  double pAa;        /* prob of amino acid A in environment a:
			(sum of column A in matrix a)/ grand_total */

  n = table[0].n -1;
  factor = ((double) opt_scale)/log(2);

  if (opt_cys == 0) { /* use C and J for structure only */
                      /* score matrix is 22 x 21 (20 amino acid + J + Z(C or J) */
    smat = allocate_score_mat(nclass+1, n+1, n, table);
    C_idx = cindex(amino_acid, 'C');
    J_idx = cindex(amino_acid, 'J');
  }
  else {
    smat = allocate_score_mat(nclass+1, n, n, table);
  }

  E = 0.0;   /* initialize expected score */
  for (ic=0; ic<nclass; ic++) {
    if (opt_verbose == 1) {
      printf("logodds...\n");
      printf("%s\n",table[ic].code);
    }

    if (opt_cys == 0) {
      p4cj = p4[C_idx][ic] + p4[J_idx][ic];
      p4cj = 1.0/p4cj;
    }

    for (i=0; i<n; i++) {
      p4inv[i] = 1.0/p4[i][ic];
    }

    for (j=0; j<n; j++) {
      pAa = table[ic].weighted_mat[n][j]/gtot;   /* column_sum / grand_total */
      if (opt_verbose == 1) {
	printf("From %c\n", amino_acid[j]);
	printf("column_sum %-7.1f grand_total %-8.1f prob %6.2f\n",
	       table[ic].weighted_mat[n][j], gtot, pAa*100.0);
	printf("   prob       p4    odds  ln(odds)  final   E\n");
      }

      for (i=0; i<n; i++) {
	odds = table[ic].weighted_mat[i][j] * p4inv[i];
	smat[ic].value[i][j] = custom_round(log(odds) * factor);

	E += smat[ic].value[i][j] * pAa * p4[i][ic] * 0.01;
	if (opt_verbose == 1) {
	  printf("%c ", amino_acid[i]);
	  printf("%8.2f ",table[ic].weighted_mat[i][j]);
	  printf("%6.2f ",p4[i][ic]);
	  printf("%6.2f ",odds);
	  printf("%6.2f ", log(odds));
	  printf("%5d ", smat[ic].value[i][j]);
	  printf("%f", E);
	  printf("\n");
	}
      }
    }

    if (opt_cys == 0) {
      for (j=0; j<n; j++) {
	odds = (table[ic].weighted_mat[C_idx][j] +  table[ic].weighted_mat[J_idx][j])
	  * p4cj;
	smat[ic].value[n][j] = custom_round(log(odds) * factor);
      }
    }
  }
  return smat;
}

int logodds_total(score_matrix *smat, int nclass, 
		  double **pall, double *p1) {
  int n;
  int i, j;
  int C_idx = 1;
  int J_idx = 20;   /* indices for C and J */
  double odds;
  double factor;
  double p1cj = 1.0;
  double qij;
  double O[25][25];  /* store odds to calculate mutual entropy */

  if (opt_cys == 0) {
    n = smat[0].n-1;
    C_idx = cindex(amino_acid, 'C');
    J_idx = cindex(amino_acid, 'J');
    p1cj = p1[C_idx] + p1[J_idx];
    p1cj = 1.0/p1cj;
  }
  else {
    n = smat[0].n;
  }

  factor = ((double) opt_scale)/log(2);

  for (j=0; j<n; j++) {
    for (i=0; i<n; i++) {
      odds = pall[i][j] / p1[i];
      O[i][j] = odds;
      smat[nclass].value[i][j] = custom_round(log(odds) * factor);
    }
  }
  if (opt_cys == 0) {
    for (j=0; j<n; j++) {
      odds = (pall[C_idx][j] +  pall[J_idx][j])
	* p1cj;
      smat[nclass].value[n][j] = custom_round(log(odds) * factor);
    }
  }

  Etot = 0.0;   /* Entropy and Expected value */
  Htot = 0.0;
  factor = 1.0/log(2);

  for (i=0; i<n; i++) {
    for (j=0; j<=i; j++) {
      Etot += smat[nclass].value[i][j] * p1[i] * p1[j];

/*      if (i == C_idx || j == C_idx) continue;  */

      qij = p1[j] * pall[i][j];  /* pall; P(j->i) */
      if (i != j) qij *= 2.0;

      Htot += qij * log(O[i][j]) * factor;  /* entropy always shown in bits */

/* debug 
      printf("(i j) %d %d\n", i, j);
      if (i != j) {
	odds = q[i][j]/(2.0*p1[i]*p1[j]) * 10000;
      }
      else {
	odds = q[i][j]/(p1[i]*p1[j]) * 10000;
      }
      printf("qij  sij  smat %f %d %d\n",
	     q[i][j], round(log(odds) * factor), smat[nclass].value[i][j]);
      printf("new qij        %f\n", qij/10000);
      if (fabs(qij/10000 - q[i][j]) > 0.00001) printf("DISCREPANCY!!!\n");
*/

    }
  }
  Htot /= 10000;   /* due to the internal scaling factor to store probabilities */
  Etot /= 10000;

  if (opt_verbose == 1) {
    printf("logodds...\n");
    printf("total\n");
    for (j=0; j<n; j++) {
      printf("From %c\n", amino_acid[j]);
      printf("P(A) %6.2f\n", p1[j]);
      printf("   prob       p4    odds  ln(odds)  final\n");
      for (i=0; i<n; i++) {
	odds = pall[i][j] / p1[i];
	printf("%c ", amino_acid[i]);
	printf("%8.2f ",pall[i][j]);
	printf("%6.2f ",p1[i]);
	printf("%6.2f ",odds);
	printf("%6.2f ", log(odds));
	printf("%5d ", smat[nclass].value[i][j]);
	printf("\n");
      }
    }
  }
  return(1);
}

score_matrix *allocate_score_mat(int nclass, int n, int m,
				 SUBST_TABLE *table) {

  score_matrix *smat;
  int i;
  
  smat = (score_matrix *)malloc((size_t) (nclass * sizeof(score_matrix)));
  if (!smat) {
    fprintf(stderr, "Can't allocate memory\n");
    exit(1);
  }
  for (i=0; i<nclass; i++) {
    smat[i].n = n;
    smat[i].m = m;
    strcpy(smat[i].code, table[i].code);
    smat[i].value = imatrix(n, m);
  }
  return smat;
}  

/*************************************************************
  Calculate entropy for all the level3 distributions
**************************************************************/
int entropy_L3(smooth *W_all, int n) {
  int m;
  
  W_all[1].E = dvector(W_all[1].ndistr);
  for (m=0; m<W_all[1].ndistr; m++) {
//    if (W_all[1].W[m][n] < MINFLOAT) {  /* no count in this distribution */
    if (W_all[1].W[m][n] < FLT_MIN) {  /* no count in this distribution */
      W_all[1].E[m] = -1.0;
    }
    else {
      W_all[1].E[m] = calEntropy(n, W_all[1].p[m], 0.01);
    }
  }
  return(1);
}


double calEntropy (int n, double *p, double factor) {

/* If the probabilities are expressed in 1/100th, 
   you have to multiply all the values by 0.01 
   to get the correctly normalized distribution */

  int i;
  double *Ptmp;
  double sum = 0.0;

  Ptmp = dvector(n);
  for (i=0; i<n; i++) {
    Ptmp[i] = p[i]*factor;
  }    

  for (i=0; i<n; i++) {
    if (Ptmp[i] < FLT_MIN) continue;
    sum -= (Ptmp[i] * log(Ptmp[i]));
/*
   printf("&&%d %8.4f %8.4f %8.4f\n", i, Ptmp[i], log(Ptmp[i]), sum);
*/
  }

  free(Ptmp);
  return sum;
}

int print_oldformatted_rawcounts (int nclass, SUBST_TABLE *table) {
  int iclass;
  int ic;
  int i;
  int j;
  int n;
  int ival;
  int **count_all;
  char outfilename[10];
  FILE *outfile;

  ic = 0;
  for (iclass = 0; iclass < nclass; iclass++) {
    ic++;
    sprintf(outfilename, "rawc%03d", ic);
    printf("#%d %s %s\n",ic, classCode[iclass], outfilename);

    outfile = fopen(outfilename, "w");
    if (outfile == NULL) {
      fprintf(stderr, "Error: Unable to open %s\n", outfilename);
      return (-1);
    }
    n = table[iclass].n - 1;  /* exclude the summed raw and colum */
    for (i=0; i<n; i++) {
      for (j=0; j<n; j++) {
	if (opt_weight_not == 0) {
/* DEBUG */
	  if (table[iclass].weighted_mat[i][j] < 0.5 && table[iclass].weighted_mat[i][j] > 0.000) {
	    printf("class %d: (%d %d) %f\n", iclass+1, i, j, table[iclass].weighted_mat[i][j]);
	  }

	  ival = (int) table[iclass].weighted_mat[i][j];
	}
	else {
	  ival = table[iclass].incidence_mat[i][j];
	}
	fprintf(outfile, "%6d.", ival);
      }
      fprintf(outfile, "\n");
    }
    fclose(outfile);
  }

  if (opt_weight_not == 0) return(0);  /* for the moment, don't produce
					  total counts when weights are used */
    
  /* produce total counts (environment-independent matrix) */

  n = table[0].n - 1;
  count_all = imatrix(n, n);
  initialize_imat(n, n, count_all, 0);
  for (ic=0; ic<nclass; ic++) {
    for (i=0; i<n; i++) {
      for (j=0; j<n; j++) {
	count_all[i][j] += table[ic].incidence_mat[i][j];
      }
    }
  }
  strcpy(outfilename, "rawc000");
  printf("#0  total %s\n", outfilename);
  outfile = fopen(outfilename, "w");
  if (outfile == NULL) {
    fprintf(stderr, "Error: Unable to open %s\n", outfilename);
    return (-1);
  }
  for (i=0; i<n; i++) {
    for (j=0; j<n; j++) {
      fprintf(outfile, "%6d.", count_all[i][j]);
    }
    fprintf(outfile, "\n");
  }
  fclose(outfile);
  return(1);
}

int whichClass (char **classVar, int nclass, char *var) {
  int i;
  for (i=0; i<nclass; i++) {
    if (strcmp(classVar[i], var) == 0) {
      return i;
    }
  }
  return -1;
}

int maxCodelen (int nseq, PIR *seqall) {
  int i;
  int n = -1;
  int l;

  for (i=0; i<nseq; i++) {
    l = strlen(seqall[i].code);
    if (l > n) n=l;
  }
  return n;
}
