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
* classdef.c                                                    *
* Defines structural environments                               *
*                                                               *
* At the moment, the program requires the file 'classde.dat' in *
* the current working directory. This file specifies the        *
* structural environments in the following way:                 *
*                                                               *
* Each line corresponds to a particular structural feature      *
* whose attributes are specified in the semi-colon-separated    *
* fields.                                                       *
* 1st field: name of feature (string)                           *
* 2nd      : values adopted in .tem file (string)               *
* 3rd      : class labels assigned for each value (string)      *
* 4th      : constrained or not (T or F)                        *
* 5th      : silent or not (T or F)                             *
*                                                               *
* For example, the line                                         *
* secondary structure and phi angle;HEPC;HEPC;F;F               *
* indicates:                                                    *
* 1) the name of the feature as in .tem file is                 *
*    'secondary structure'                                      *
* 2) this feature has four values H, E, P and C                 *
*    (secondary structure assignments in .tem file would look   *
*    like CCCCHHHHHH--EEEPCCCCCCC--)                            *
* 3) to specify the secondary structure state H, we use H       *
*    in this program, and so on                                 *
* 4) this feature is not constrained, meaning that all          *
*    alignment positions are used to count amino acid           *
*    replacements even if the secondary structure states are    *
*    not conserved                                              *
* 5) this feature is not silent.                                *
*                                                               *
* Similarly, if the second feature 'solvent accessibility'      *
* adopts two values (T or F), the total number of structural    *
* environments is 4 * 2 = 8, and they are labeled               *
* HA (helix buried                                              *
* Ha (helix accessible)                                         *
* EA (strand buried)                                            *
* Ea (strand accessible)                                        *
* and so on.                                                    *
*                                                               *
****************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "subst.h"
#include "utility.h"
#include "options.h"
#include "combination.h"

static char *classdef_filename = NULL;

void init_config(char *filename) {
  char *tmp_char;

  if (access(filename, R_OK) == 0) {
    classdef_filename = strdup(filename);
    return;
  }
  else {
    tmp_char = mstrcat(getenv("HOME"), "/");
    classdef_filename = mstrcat(tmp_char, filename);
    if (access(classdef_filename, R_OK) == 0) {
      return;
    }
    else {
      fprintf(stderr, "Error: %s not found\n", filename);
      exit (-1);
    }
  }
}

int read_classdef(SCLASS *sclass) {
  FILE *fp;
  char line[BUFSIZE];
  char *tmp;
  int i;

  fp = fopen(classdef_filename, "r");
  if (fp == NULL) {
    fprintf(stderr, "Error: Unable to open %s\n", classdef_filename);
    return (-1);
  }

  i = 0;
  while (fgets(line, sizeof(line), fp)) {
    if (line[0] == '!' || line[0] == '#')
      continue; /* comment line */
    tmp = (char *)strtok(line, DELIMITER);
    if (tmp==NULL) {
      fprintf(stderr, "Syntax error:%s", line);
      exit (-1);
    }
    strcpy(sclass[i].name, tmp);

    if((tmp=strtok(NULL, DELIMITER))==NULL) {
      fprintf(stderr, "Syntax error:%s", line);
      exit (-1);
    }
    strcpy(sclass[i].var, tmp);

    if((tmp=strtok(NULL, DELIMITER))==NULL) {
      fprintf(stderr, "Syntax error:%s", line);
      exit (-1);
    }
    strcpy(sclass[i].code, tmp);

    if((tmp=strtok(NULL, DELIMITER))==NULL) {
      fprintf(stderr, "Syntax error:%s", line);
      exit (-1);
    }
    sclass[i].constrained = *tmp;

    if((tmp=strtok(NULL, "\n"))==NULL) {
      fprintf(stderr, "Syntax error:%s", line);
      exit (-1);
    }
    sclass[i].silent = *tmp;

    i++;
    if (i== MAX_FEATURE) {
      fprintf(stderr, "Erorr: too many features, increase MAX_FEATURE\n");
      exit (-1);
    }
  }
  return i;
}

/*************************************************************
  obtain total number of structural classes (environments)

  if there are n structural features considered and each adopts
  N1, N2, ..., Nn valus, then

  nclass = N1 x N2 x .. Nn
**************************************************************/
int getNclass(int nfeature, SCLASS *sclass) {
  int i;
  int nclass = 1;

  for (i=0; i<nfeature; i++) {
    if (sclass[i].silent == 'T') {
      continue;
    }
    nclass *= strlen(sclass[i].var);
  }

  if (opt_verbose == 1) {
    printf("Analyzing structural classes...\n");
    printf("  (feature name in the input .tem file)\n");
    printf("  (possible values adopted)\n");
    printf("  (lable string for each state)\n");

    for (i=0; i<nfeature; i++) {
      if (sclass[i].silent == 'T') {
	continue;
      }
      printf("#%d", i+1);
      if (sclass[i].constrained == 'T') {
	printf(" (constrained)\n");
      }
      else {
	printf("\n");
      }
      printf("  %s\n", sclass[i].name);
      printf("  %s\n", sclass[i].var);
      printf("  %s\n", sclass[i].code);
    }
  }
  return nclass;
}

int getAllclass(int nfeature, SCLASS *sclass,
		int nclass, SUBST_TABLE *table,
		char **classVar, int *list_no_silent) {
/* Suppose feature 1 adopts values H, E and C (stord as HEC in sclass[0].var)
   and we want label each state a, b and c (stored as abc in sclass[0].code).
   Similary feature 2 adopts TF and we label each state N and n.
   The total number of structural classes then is 3 x 2 = 6 and they are
     HT  (labelled aN)
     HF  (         an)
     ET  (         bN)
     EF
     CT
     CF
  This function constructs a list of strings for the first and second columns
  in this example and stores them in classVar and classCode, respectively. */

  int *vl; /* specifies values each feature adopts
            * e.g., feature 0 adopts value vl[0]
            * feature 1 adopts value vl[1].     */
  int *vmax; /* number of different values each feature can adopts */
  int i;
  int nf;      /* nfeature - nsilent */
  int ic=0;

  nf = 0;
  for (i=0; i<nfeature; i++) {
    if (sclass[i].silent == 'T') {  /* 'silent' feature */
      continue;
    }
    list_no_silent[nf] = i;
    nf++;
  }    
  vl = ivector(nf);
  vmax = ivector(nf);

  /* initial values */
  for (i=0; i<nf; i++) {
    vl[i] = 0;
    vmax[i] = strlen(sclass[list_no_silent[i]].code);

    table[ic].icode[i] = 0;
    table[ic].code[i] = sclass[list_no_silent[i]].code[0];
    classCode[ic][i] = sclass[list_no_silent[i]].code[0];
    classVar[ic][i] = sclass[list_no_silent[i]].var[0];
  }
  table[ic].code[nf] = '\0';
  classCode[ic][nf] = '\0';
  classVar[ic][nf] = '\0';
  ic++;

  while (1) {
    if (vcomb(vl, nf, vmax)) {
      for (i=0; i<nf; i++) {
	table[ic].icode[i] = vl[i];
	table[ic].code[i] = sclass[list_no_silent[i]].code[vl[i]];
	classVar[ic][i] = sclass[list_no_silent[i]].var[vl[i]];
	classCode[ic][i] = sclass[list_no_silent[i]].code[vl[i]];
      }
      table[ic].code[nf] = '\0';
      classCode[ic][nf] = '\0';
      classVar[ic][nf] = '\0';
      ic++;
    }
    else {
      break;
    }
  }
  free(vl);
  free(vmax);
  return(nf);
}

int chk_constraints(int nfeature, SCLASS *sclass, int *list) {
  int i, j;
  
  j = 0;
  for (i=0; i<nfeature; i++) {
    if (sclass[i].constrained == 'T') {
      list[j] = i;
      j++;
    }
  }
  return j;
}
