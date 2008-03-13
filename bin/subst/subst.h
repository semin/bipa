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
* subst.h                                                       *
* Header file for core funcitons                                *
****************************************************************/
#ifndef __subst
#define __subst

#define MAX_FEATURE (10)
#define MAX_CLASS  (300)
#define MAX_NAMLEN (256)
#define BUFSIZE    (256)
#define DELIMITER  ";"
#define CLASSDEFFILE "classdef.dat"

#define SKIP_CHARACTER 'X'
#define DISULPHIDE_FEATURE "disulphide"

#include "rdtem.h"
#include "slink.h"

typedef struct SCLASS {
  char name[MAX_NAMLEN];
  char var[MAX_NAMLEN];
  char code[MAX_NAMLEN];
  char constrained; /* T or F, if true, substituions are
		       counted only between the same states */
  char silent;      /* T or F, if true, substitutions are
		       not counted (but could be used to 'constrain'
		       the pairs */
} SCLASS;

typedef struct SUBST_TABLE {
  char code[MAX_NAMLEN];  /* name of the class */
  int icode[MAX_FEATURE];
  int n;
  int **incidence_mat;
  double **weighted_mat;
} SUBST_TABLE;

typedef struct score_matrix {
  char code[MAX_NAMLEN];  /* name of the class */
  int icode[MAX_FEATURE];
  int n;
  int m;
  int **value;
} score_matrix;

typedef struct merged_class {
  int n;     /* number of features considered */
  int *nf;   /* list of feature numbers (feature 1,..., feature n) */
  int *nv;   /* nv-th values adoped for these features */
} merged_class;

typedef struct smooth {
  int ndistr;        /* total number of distributions at this smoothing level */
  merged_class *mc;  /* info about features considered and their values */
  double **W;        /* estimated frequencies at this level */
  double **p;        /* smoothed distribution */
  double *E;         /* entropy for each distribution */
} smooth;

typedef struct p1_p4 {
  double *p1;  /* equivalent to normalized frequency of each residue type (Nfreq) */
  double **p4; /* probability of each residue type mutating ANY amino acid in a given structural environment */
} p1_p4;

typedef struct strali{  /* a set of integers to represent a particular
			     residue in its specific environment */
  int *strEnv;  /* index to specify a structural environment */
  int *aaIdx;   /* index to an amino acid */
  int *sstype;  /* index to a specific secondary structure type (optional analysis) */
} strali;

int subst (int, int, char **, int, SCLASS *);
void init_config(char *);
int read_classdef (SCLASS *);
int getNclass(int , SCLASS *);
int getAllclass(int nfeature, SCLASS *sclass,
		 int nclass, SUBST_TABLE *table,
		 char **classVar, int *);
int chk_constraints(int, SCLASS *, int *);

int count_subst(char *, int, PIR *, int, int, SCLASS *,
		char **, int, int *, SUBST_TABLE *, int *, double **, double *);
strali *determine_class(int , int **, int *, PIR *, SCLASS *, char **,
			int, char **, int, int);

void free_strali (int, int, strali *);

int whichClass (char **, int, char *);
int isThisNewcode(char **, int, char *);
int assign_disulphide(int nseq, PIR *seqall, int ncode,
		      int *seqIdx, char **seqCode);
SUBST_TABLE *allocate_subst_table(int, int);
score_matrix *allocate_score_mat(int, int, int, SUBST_TABLE *);

void initialize_itable(int, int, int, SUBST_TABLE *, int);
void initialize_dtable(int, int, int, SUBST_TABLE *, double);
int printOutMatrices (int, SUBST_TABLE *, score_matrix *, int,
		      double **, SCLASS *, int);
int print_prob (int, SUBST_TABLE *, int, double **, FILE *);
int print_logodds (int, score_matrix *, FILE *);

double **p2table(int, int, smooth *);
int print_oldformatted_rawcounts (int, SUBST_TABLE *);
p1_p4 *bg_distrib (int, SUBST_TABLE *, int, SCLASS *, int, int *, smooth *);
p1_p4 *unsmoothed_bg (int, SUBST_TABLE *);

void sumTable(int, SUBST_TABLE *);
void addCounts(int, SUBST_TABLE *, double);
int raw2prob(int, SUBST_TABLE *);
double **totaltable(int, SUBST_TABLE *);

double *calP1 (int, SUBST_TABLE *);
int calP2(int, SUBST_TABLE *, int, double *, smooth *);
int calP3(int, SUBST_TABLE *, int, smooth *);
double **calP4(int, SUBST_TABLE *, int, int, smooth *);
double **calP4unsmooth(int, SUBST_TABLE *);
double **calP4_nonspecific (int, SUBST_TABLE *, double *);

int calPfinal(int, SUBST_TABLE *, int, int, smooth *);

score_matrix *calLogodds(int, SUBST_TABLE *, double **, double *);
int logodds_total(score_matrix *, int, double **, double *);

int entropy_L3(smooth *, int);
double calEntropy (int, double *, double);

int get_merged_class(int, smooth *, SCLASS *, int, int *);
int specify_feature (int *, int, int, SCLASS *, int *);
int generate_allcmb (int, int *, int, int, SCLASS *, int, merged_class *, int *);
double **merge_table (int nfeature, int nclass, SUBST_TABLE *table,
		      merged_class *mc, int ndistr);

void weight_subst(int, SUBST_TABLE *, int, double *);
void weight_subst_clus(int, SUBST_TABLE *, int);

void normalize_table(int, SUBST_TABLE *, int *, double *);
int sum(int, int, int, strali *, SUBST_TABLE *, int *,
	PIR *, char **, int, int *, int **);

int count_between_clusters (int, int, strali *, int,
			    SUBST_TABLE *, int *, int *,
			    PIR *, char **, int, int *, int **);
cluster *clustering (int, PIR *, int *, char **, int *);

int noweight2prob(int, SUBST_TABLE *, int, SCLASS *, int);

int maxCodelen (int, PIR *);

extern char *amino_acid;
extern char **classCode;
extern double gtot;
extern double E;
#endif
