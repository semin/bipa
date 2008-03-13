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
* smooth.c                                                      *
* Performs the smoothing procedure                              *
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

/****************************************************************
*                                                               
* Obtains the definitions for marginal distributions
*
* These represent the likelihood of mutational events leading to
* residue type j (j=1,...,21), under conditions ignoring several
* structural features (e.g., substituion of amino acid i in 
* a helix, irrespective of its accessibility, to amino acid j).
*
*
*****************************************************************/
int get_merged_class(int nfeature, smooth *W_all, SCLASS *sclass,
		     int nnsf, int *list_no_silent) {
  int is;
  int ns;
  int nc;    /* number of combinations */
  int ks;
  int *js;
  int ndistr;
  int m;
  int id;

  ns = nnsf + 1;  /* total number of independent variables
		   (all features - silent features + mutated amino acids).
                    ------------------------------
                              (nnsf)                        1
		   smoothing level is this number plus one */
  js = ivector(ns+1);

  for (ks=1; ks<=2; ks++) {
    nc = factorial(ns);
    nc /= (factorial(ns - ks) * factorial(ks));

    for (is=1; is<=ks; is++) { /* initialization */
      js[is] = 0;
    }
    ndistr = 0;

    for (m=0; m<nc; m++) {
      combination(js, ns, ks);
      ndistr += specify_feature(js, ns, ks, sclass, list_no_silent);
    }

    if (opt_verbose == 1) {
      printf("++++taking into account %d features out of %d...\n", ks, ns);
      printf("  (total number of combinations is %d)\n", nc);
      printf("total %d distributions\n", ndistr);
    }

    W_all[ks-1].ndistr = ndistr;

    W_all[ks-1].mc = (merged_class *)malloc((size_t) (ndistr * sizeof(merged_class)));

    if (! W_all[ks-1].mc) {
      fprintf(stderr, "Can't allocate memory\n");
      exit(1);
    }

    id = -1;
    for (m=0; m<nc; m++) {
      combination(js, ns, ks);

      if (opt_verbose == 1) {
	for (is=1; is<=ks; is++) {
	  printf("%d ", js[is]);
	}
	printf("\n");
      }
      id = generate_allcmb(nfeature, js, ns, ks, sclass, id,
			   W_all[ks-1].mc, list_no_silent);
    }
  }
  return(1);
}

/****************************************************************
*                                                               
* Select k features out of n (with feature numbers specified 
* by a vector j), examine how many values each feature can adopt
* and obtain the total number of combinations.
*
*****************************************************************/
int specify_feature (int *j, int n, int k, SCLASS *sclass, int *list_no_silent) {
  int i;
  int nv;  /* number of values adopted */
  int nt = 1;

  for (i=1; i<=k; i++) {
    if (j[i] < n-1) {
      nv = strlen(sclass[list_no_silent[j[i]]].code);
    }
    else {
      nv = 21;
    }
    nt *= nv;
  }
  return nt;
}

int generate_allcmb (int nfeature, int *j, int n, int k, SCLASS *sclass,
		     int id, merged_class *mc, int *list_no_silent) {
/*
 * vector j specifies the features considered
 * Total k (out of n) features considered) and
 * there indices are j[0],...j[k].

 */

  int i;
  int nv;
  int *vl; /* specifies values each feature adopts
            * e.g., feature j[0] adopts value vl[0]
            * feature j[1] adopts value vl[1].     */
  int *vmax;

  vl = ivector(k);
  vmax = ivector(k);

  for (i=1; i<=k; i++) {
    if (j[i] < n-1) {
      vmax[i-1] = strlen(sclass[list_no_silent[j[i]]].code);
    }
    else {
      vmax[i-1] = 21;
    }
  }

  if (opt_verbose == 1) {
    for (i=1; i<=k; i++) {
      if (j[i] < n-1) {
	printf(" %s ",sclass[list_no_silent[j[i]]].name);
	printf(" %s ",sclass[list_no_silent[j[i]]].code);
	nv = strlen(sclass[list_no_silent[j[i]]].code);
	printf(" %d\n", nv);
      }
      else {
	printf(" amino acids 21\n");
	nv = 21;
      }
    }
  }

  id++;
  mc[id].n = k;
  mc[id].nf = ivector(k);
  mc[id].nv = ivector(k);

  /* initial values */
  for (i=0; i<k; i++) {
    vl[i] = 0;

    if (j[i+1] < n-1) {    /* no-silent normal feature */
      mc[id].nf[i] = j[i+1];
    }
    else {
      mc[id].nf[i] = nfeature;
    }
    mc[id].nv[i] = vl[i];
  }

  while (1) {
    if (vcomb(vl, k, vmax)) {
      id++;
      mc[id].n = k;
      mc[id].nf = ivector(k);
      mc[id].nv = ivector(k);

      for (i=0; i<k; i++) {
	if (j[i+1] < n-1) {    /* no-silent normal feature */
	  mc[id].nf[i] = j[i+1];
	}
	else {                 /* mutated amino acid */
	  mc[id].nf[i] = nfeature;
	}
	mc[id].nv[i] = vl[i];
      }
    }
    else {
      break;
    }
  }
  free(vl);
  free(vmax);
  return id;
}

/****************************************************************
*                                                               
* Obtains marginal distributions (actually weighted raw counts, 
* not normalized yet).
*
* These represent the likelihood of mutational events leading to
* residue type j (j=1,...,21), under conditions ignoring several
* structural features (e.g., substituion of amino acid i in 
* a helix, irrespective of its accessibility, to amino acid j).
* So if there are m distributions,
* the final results consist of m  21-dimensional vectors.
*
* The definition of each distribution is obtained from the structure
* mc (see generate_allcmb) and appropriate substitution tables
* are summed up.
*
*****************************************************************/
double **merge_table (int nfeature, int nclass, SUBST_TABLE *table,
		      merged_class *mc, int ndistr) {

  int n;
  int m;
  int ii;
  int ic;
  int i;
  int chk;
  int mutated_aa;
  double **W;

  n = table[0].n - 1;
  W = dmatrix(ndistr, n+1);
  initialize_dmat(ndistr, n+1, W, 0.0);

  for (m=0; m<ndistr; m++) {   /* loop for merged distributions */
    for (ic=0; ic<nclass; ic++) { /* scan if each environment contributes to this distrib */
      chk = 1;
      mutated_aa = n;
      
      for (ii=0; ii<mc[m].n; ii++) {   /* this distribution is specified by a set of mc[m].n 
					  (feature, value) pairs */
	if (mc[m].nf[ii] > nfeature) {
	  fprintf(stderr, "Error in merge_table: feature number %d does not exist!\n", mc[m].nf[ii]);
	  exit(-1);
	}
	else if (mc[m].nf[ii] == nfeature) { /* mutated amino acid */
	  mutated_aa = mc[m].nv[ii];
	  continue;
	}
	if (table[ic].icode[mc[m].nf[ii]] != mc[m].nv[ii]) {
	  chk = 0;
	  break;
	}
      }
      if (chk == 1) {
	for (i=0; i<n; i++) {
	  W[m][i] += table[ic].weighted_mat[i][mutated_aa];

/*debug
	  if (mc[m].nf[0] == nfeature && mutated_aa == 0 && i==0) {
	    printf("distrib %d table %d\n", m, ic);
	    printf("%f ",table[ic].weighted_mat[i][mutated_aa]);
	    printf("%f\n",W[m][i]);
	  }
 */
	}
      }
    }

    for (i=0; i<n; i++) {
      W[m][n] += W[m][i];
    }
  }
  return(W);
}

double *calP1 (int nclass, SUBST_TABLE *table) {
  int ic;
  int i;
  int n;
  double *p1;
  double factor;

  ic = 0;
  n = table[0].n - 1;  /* last index of the table (now 21 because 
			  it includes a row/column sum) */
  p1 = dvector(n);
  initialize_dvec(n, p1, 0.0);

  for (ic=0; ic<nclass; ic++) {
    for (i=0; i<n; i++) {
      p1[i] += table[ic].weighted_mat[i][n];  /* take the row sum */
    }
  }

  factor = 100.0 / gtot;
  for (i=0; i<n; i++) {
    p1[i] *= factor;
  }
  return (p1);
}

double **calP4unsmooth (int nclass, SUBST_TABLE *table) {
  int ic;
  int i;
  int n;
  double **p4;
  double factor;

  ic = 0;
  n = table[0].n - 1;  /* last index of the table (now 21 because 
			  it includes a row/column sum) */
  p4 = dmatrix(n, nclass);

  for (ic=0; ic<nclass; ic++) {
    factor = 100.0 / table[ic].weighted_mat[n][n];
    for (i=0; i<n; i++) {
      p4[i][ic] = table[ic].weighted_mat[i][n] * factor;  /* take the row sum */
    }
  }
  return (p4);
}

double **calP4_nonspecific (int nclass, SUBST_TABLE *table, double *p1) {
  int ic;
  int i;
  int n;
  double **p4;

  n = table[0].n - 1;  /* last index of the table (now 21 because 
			  it includes a row/column sum) */
  p4 = dmatrix(n, nclass);

  for (ic=0; ic<nclass; ic++) {
    for (i=0; i<n; i++) {
      p4[i][ic] = p1[i];
    }
  }
  return (p4);
}

double **p2table(int n, int nfeature, smooth *W_all) {
  int m;
  int ndistr;
  double **pmat;
  int i;
  int j;

  ndistr = W_all[0].ndistr;
  pmat = dmatrix(n, n);

  for (m=0; m<ndistr; m++) {
    if (W_all[0].mc[m].nf[0] != nfeature) {
      continue;
    }
    j = W_all[0].mc[m].nv[0]; /* mutated amino acid */
    for (i=0; i<n; i++) {
      pmat[i][j] = W_all[0].p[m][i];
    }
  }
  return(pmat);
}

int calP2(int nclass, SUBST_TABLE *table, int nfeature,
	  double *p1, smooth *W_all) {

  int ndistr;
  int n;
  double dNj;       /* number of observed counts (but double because it is a weighted sum) */
  double omega1;    /* weights */
  double omega2;
  double total;
  double *w2prime;

  int m;
  int i;

  n = table[0].n -1;

  /************ partial Level 2 smoothing *********************/
  /* only p2(ri|Rj) required (no p2(ri|Mk), p2(ri|al) and p2(ri|hm) */

  ndistr = W_all[0].ndistr;
  
  if (opt_verbose == 1) {
    printf("P2\n");
    printf("total %d distributions\n", ndistr);
  }

  W_all[0].p = dmatrix(ndistr, n);
  w2prime = dvector(n);

  for (m=0; m<ndistr; m++) {
    if (W_all[0].W[m][n] < FLT_MIN) {
      if (opt_verbose == 1) {
	printf(" zero column...\n");
      }
      continue;
    }

   /* calculate P here */

    dNj = W_all[0].W[m][n];
    total = 100.0 / dNj;
    omega1 = 1.0 / (1.0 + dNj/(double)(opt_sigma * (double)n));
    omega2 = 1.0 - omega1;

    for (i=0; i<n; i++) {
      w2prime[i] = W_all[0].W[m][i] * total;
      W_all[0].p[m][i] = omega1 * p1[i] + omega2 * w2prime[i];
    }

    if (opt_verbose == 1) {
      if (W_all[0].mc[m].nf[0] != nfeature) {
	printf("#%d substitutions from any in the environment where feature %d adopts value %d\n",
	       m, W_all[0].mc[m].nf[0], W_all[0].mc[m].nv[0]);
	printf("      p1    W2    p2    Nj(%6.2f) omega1(%8.3f)\n", dNj, omega1);
      }
      else {
	printf("#%d substitutions from %c in any environment\n", m, amino_acid[W_all[0].mc[m].nv[0]]);
	printf("%c     p1    W2    p2    Nj(%6.2f) omega1(%8.3f)\n", amino_acid[m], dNj, omega1);
      }
      for (i=0; i<n; i++) {
	printf("%c %6.2f %6.2f %6.2f\n", amino_acid[i], p1[i], w2prime[i], W_all[0].p[m][i]);
      }
    }

  }
  free(w2prime);
  return(1);
}

int calP3(int nclass, SUBST_TABLE *table, int nfeature,
	  smooth *W_all) {

  int ndistr;
  int n;
  double dNj;       /* number of observed counts (but double because it is a weighted sum) */
  double omega1;    /* weights */
  double omega2;
  double total;
  double *w3prime;

  int m;
  int i;
  int iaa;

  n = table[0].n -1;

 /************ partial Level 3 smoothing *********************/

  ndistr = W_all[1].ndistr;

  if (opt_verbose == 1) {
    printf("P3...\n");
    printf("total %d distributions\n", ndistr);
  }

  W_all[1].p = dmatrix(ndistr, 21);
  w3prime = dvector(n);

  for (m=0; m<ndistr; m++) {
    if (W_all[1].mc[m].nf[1] != nfeature) {
      continue;
    }
    iaa = W_all[1].mc[m].nv[1];  /* mutated amino acid */

    if (W_all[1].W[m][n] < FLT_MIN) {
      continue;
    }

   /* calculate P here */

    dNj = W_all[1].W[m][n];
    total = 100.0 / dNj;
    omega1 = 1.0 / (1.0 + dNj/(double)(opt_sigma * (double)n));
    omega2 = 1.0 - omega1;

    for (i=0; i<n; i++) {
      w3prime[i] = W_all[1].W[m][i] * total;
      W_all[1].p[m][i] = omega1 * W_all[0].p[iaa][i] + omega2 * w3prime[i];
    }

    if (opt_verbose == 1) {
      printf("#%d mutated from %c in the environment where feature %d adopts value %d\n",
	     m, amino_acid[iaa], W_all[1].mc[m].nf[0], W_all[1].mc[m].nv[0]);
      
      if (W_all[1].W[m][n] < FLT_MIN) {
	printf(" zero column...\n");
	continue;
      }

      printf("%c     p2    W3    p3    Nj(%6.2f) omega1(%8.3f)\n", amino_acid[iaa], dNj, omega1);
      for (i=0; i<n; i++) {
	printf("%c %6.2f %6.2f %6.2f\n", amino_acid[i], 
	       W_all[0].p[iaa][i], w3prime[i], W_all[1].p[m][i]);
      }
    }

  }
  free(w3prime);
  return(1);
}

int calPfinal(int nclass, SUBST_TABLE *table, int nfeature, int nnsf,
	      smooth *W_all) {
  int n;
  double dNj;       /* number of observed counts (but double because it is a weighted sum) */
  double omega1;    /* weights */
  double omega2;
  double total;
  double *w5prime;
  double p5;

  int m;
  int i;
  int j;
  int iaa;
  int ic;
  int nf;  /* feature number */
  int nv;  /* feature value */
  int nf1;
  int ii;
  int *idlist; /* store indices for the relevant p3 distributions */
  double *wc;  /* weight for each backbround distribution */
  double wcsum;
  double Emax; /* maximum entropy (corresponding to a uniform distribution) */

  n = table[0].n -1;

  idlist = ivector(nnsf);
  wc = dvector(nnsf);
  Emax = log((double) n);

  /************ Final level smoothing *********************/

  /* only partial smoothing will be implemented */

  w5prime = dvector(n);

  if (!W_all[1].E) {   /* entropy for all the level3 distributions */
    entropy_L3(W_all, n);
  }

  for (ic=0; ic<nclass; ic++) {
    for (j=0; j<n; j++) {

/*************************************************************
  observed substitution frequencies from each amino acid j
  in environment ic
**************************************************************/
      total = table[ic].weighted_mat[n][j];
      if (total < FLT_MIN) {
	total = 0.0;
	for (i=0; i<n; i++) {
	  w5prime[i] = 0.0;
	}
      }
      else {
	total = 100.0 / table[ic].weighted_mat[n][j];
	for (i=0; i<n; i++) {
	  w5prime[i] = table[ic].weighted_mat[i][j] * total;
	}
      }
/*************************************************************
  select relevant level 3 distributions for the calculation
  of the background probabilities
**************************************************************/
      ii = 0;
      for (m=0; m<W_all[1].ndistr; m++) {
	nf = W_all[1].mc[m].nf[0];    /* feature nf adopting value nv */
	nv = W_all[1].mc[m].nv[0];
	iaa = W_all[1].mc[m].nv[1];   /* and mutating from amino acid iaa */
	nf1 = W_all[1].mc[m].nf[1];
	if (nf1 != nfeature || j != iaa ||
	    table[ic].icode[nf] != nv)
	  continue;

	if (ii >= nnsf) {
	  fprintf(stderr, "Erorr in calPfinal: something is wrong!\n");
	  break;
	}
	idlist[ii] = m;
	ii++;
      }

      if (opt_verbose == 1) {
	printf("Pfinal\n");
	printf("%s ",table[ic].code);
	for (i=0; i<nnsf; i++) {
	  printf("%1d", table[ic].icode[i]);
	}
	printf("\n");

	for (ii=0; ii<nnsf; ii++) {
	  m = idlist[ii];
	  nf = W_all[1].mc[m].nf[0];
	  nv = W_all[1].mc[m].nv[0];
	  iaa = W_all[1].mc[m].nv[1];   /* amino acid number */
	  printf("select p3[%d] value %d of feature %d (aa %d)\n", m, nv, nf, iaa);
	}
      }
/*************************************************************
  weights for the level 3 distributions based on their entropy
  (weighted sum for estimating the background probablilities)
**************************************************************/
      wcsum = 0.0;
      for (ii=0; ii<nnsf; ii++) {
	if (W_all[1].E[idlist[ii]] > 0.0) {
	  wc[ii] = (Emax - W_all[1].E[idlist[ii]])/Emax;
	  wcsum += wc[ii];
	}
	else {
	  wc[ii] = -1.0;
	}
      }

      if (wcsum < FLT_MIN) {
	fprintf(stderr, "Warning: no suitable background distribuion ");
	fprintf(stderr, "for substitutions from %c in %s\n",
		amino_acid[j], table[ic].code);
      }
      else {
	wcsum = 1.0/wcsum;
      }

      for (ii=0; ii<nnsf; ii++) {
	wc[ii] *= wcsum;
      }

/*************************************************************
  relative contributions from the observed and estimated
  (background) frequencies
**************************************************************/
      dNj = table[ic].weighted_mat[n][j];
      total = 1.0 / dNj;
      omega1 = 1.0 / (1.0 + dNj/(double)(opt_sigma * (double)n));
      omega2 = 1.0 - omega1;

      if (opt_verbose == 1) {
	printf("From %c\n", amino_acid[j]);
	printf("  entropy     ");
	for (ii=0; ii<nnsf; ii++) {
	  printf("%6.2f ",W_all[1].E[idlist[ii]]);
	}
	printf("\n");
	printf("  weights     ");
	for (ii=0; ii<nnsf; ii++) {
	  printf("%6.2f ",wc[ii]);
	}
	printf("\n");
	printf("       omega1(%8.3f)\n", omega1);
	printf("      rawc  W5'     (relevant W3 distributions)        A3    p5\n"); 
      }

      for (i=0; i<n; i++) {

/***********************************************************************************
  final probability p5
 **********************************************************************************/
	p5 = 0.0;
	for (ii=0; ii<nnsf; ii++) {
	  if (wc[ii] > 0.0)
	    p5 += (wc[ii] * W_all[1].p[idlist[ii]][i]);
	}

	if (opt_verbose == 1) {
	  printf("%c ", amino_acid[i]);
	  printf("%8.2f ",table[ic].weighted_mat[i][j]);
	  printf("%6.2f ",w5prime[i]);
	  for (ii=0; ii<nnsf; ii++) {
	    if (wc[ii] > 0) {
	      printf("%6.2f ",W_all[1].p[idlist[ii]][i]);
	    }
	    else {
	      printf("  0.00 ");
	    }
	  }
	  printf("%6.2f ",p5);
	}
/***********************************************************************************
    replace raw counts with probabilities (normalized so that each column sum is 100 
 **********************************************************************************/
	table[ic].weighted_mat[i][j] = omega1 * p5 + omega2 * w5prime[i];

	if (opt_verbose == 1) {
	  printf("%6.2f ",table[ic].weighted_mat[i][j]);
	  printf("\n");
	}
      }
    }
  }
  free(idlist);
  free(wc);
  free(w5prime);
  return(1);
}

double **calP4(int nclass, SUBST_TABLE *table, int nfeature, int nnsf,
	       smooth *W_all) {
  int n;
  double dNj;       /* number of observed counts (but double because it is a weighted sum) */
  double omega1;    /* weights */
  double omega2;
  double total;
  double *w4prime;
  double p;
  double **p4;

  int m;
  int i;
  int iaa;
  int ic;
  int nf;  /* feature number */
  int nv;  /* feature value */
  int nf1;
  int ii;
  int is;  /* no of distributions appearing in the sum for A3 */
  int *idlist; /* store indices for the relevant p3 distributions */
  double *wc;  /* weight for each backbround distribution */
  double wcsum;
  double Emax; /* maximum entropy (corresponding to a uniform distribution) */

  n = table[0].n -1;

  idlist = ivector(n * nnsf);
  wc = dvector(n * nnsf);
  Emax = log((double) n);

  /************ Level 4 smoothing (only for log-odds) *********************/

  /* only partial smoothing will be implemented */

  w4prime = dvector(n);          /* observed frequencies (for verbose output) */
  p4 = dmatrix(n, nclass);       /* final probabilities */

  if (!W_all[1].E) {   /* entropy for all the level3 distributions */
    entropy_L3(W_all, n);
  }

/* LOOP for all structural environments */

  for (ic=0; ic<nclass; ic++) {
/*************************************************************
  observed substitution frequencies from ANY amino acid
  in environment ic
**************************************************************/
    total = table[ic].weighted_mat[n][n];   
    if (total < FLT_MIN) {
      total = 0.0;
      for (i=0; i<n; i++) {
	w4prime[i] = 0.0;
      }
    }
    else {
      total = 100.0 / total;
      for (i=0; i<n; i++) {
	w4prime[i] = table[ic].weighted_mat[i][n] * total;
      }
    }
/*************************************************************
  select relevant level 3 distributions for the calculation
  of the background probabilities
**************************************************************/
    is = 0;
    for (m=0; m<W_all[1].ndistr; m++) {
      nf = W_all[1].mc[m].nf[0];    /* feature nf adopting value nv */
      nv = W_all[1].mc[m].nv[0];
      nf1 = W_all[1].mc[m].nf[1];
      if (nf1 != nfeature || table[ic].icode[nf] != nv)
	continue;
      
      if (is >= (n * nfeature)) {
	fprintf(stderr, "Erorr in calP4: something is wrong!\n");
	fprintf(stderr, "n : is : nf : nv %d %d %d %d\n", n, is, nf, nv);
	break;
      }
      idlist[is] = m;
      is++;
    }

    if (opt_verbose == 1) {
      printf("P4...\n");
      printf("%s ",table[ic].code);
      for (i=0; i<nnsf; i++) {
	printf("%1d", table[ic].icode[i]);
      }
      printf("\n");
      for (ii=0; ii<is; ii++) {
	m = idlist[ii];
	nf = W_all[1].mc[m].nf[0];
	nv = W_all[1].mc[m].nv[0];
	iaa = W_all[1].mc[m].nv[1];   /* amino acid number */
	nf1 = W_all[1].mc[m].nf[1];
	printf("select p3[%d] value %d of feature %d (aa %d)\n", m, nv, nf, iaa);
      }
    }
/*************************************************************
  weights for the level 3 distributions based on their entropy
  (weighted sum for estimating the background probablilities)
**************************************************************/
    wcsum = 0.0;
    for (ii=0; ii<is; ii++) {
      if (W_all[1].E[idlist[ii]] > 0.0) {
	wc[ii] = (Emax - W_all[1].E[idlist[ii]])/Emax;
	wcsum += wc[ii];
      }
      else {
	wc[ii] = -1.0;
      }
    }

    if (wcsum < FLT_MIN) {
      fprintf(stderr, "Warning: no suitable background distribuion ");
      fprintf(stderr, "for substitutions from anything in %s\n",
	      table[ic].code);
    }
    else {
      wcsum = 1.0/wcsum;
    }

    for (ii=0; ii<is; ii++) {
      wc[ii] *= wcsum;
    }

/*************************************************************
  relative contributions from the observed and estimated
  (background) frequencies
**************************************************************/
    dNj = table[ic].weighted_mat[n][n];
    total = 1.0 / dNj;
    omega1 = 1.0 / (1.0 + dNj/(double)(opt_sigma * (double)n));
    omega2 = 1.0 - omega1;

    if (opt_verbose == 1) {
      printf("       omega1(%8.3f)\n", omega1);
      printf("      rawc  W4'    A3    p4\n"); 
    }
/***********************************************************************************
  final probability p4
 **********************************************************************************/
    for (i=0; i<n; i++) {   /* mutating residues */    
      p = 0.0;
      for (ii=0; ii<is; ii++) {
	if (wc[ii] > 0.0)
	  p += (wc[ii] * W_all[1].p[idlist[ii]][i]);
      }
      p4[i][ic] = omega1 * p + omega2 * w4prime[i];

      if (opt_verbose == 1) {
	printf("%c ", amino_acid[i]);
	printf("%8.2f ",table[ic].weighted_mat[i][n]);
	printf("%6.2f ",w4prime[i]);
	printf("%6.2f ",p);
	printf("%6.2f ",p4[i][ic]);
	printf("\n");
      }
    }
  }
  free(idlist);
  free(wc);
  free(w4prime);
  return p4;
}

