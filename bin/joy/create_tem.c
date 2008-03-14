/*
*
* $Id:
* joy 5.0 release $Name:  $
*/
/****************************************************************************
* joy: A program for protein sequence-structure representation and analysis *
* Copyright (C) 1988-1997  John Overington                                  *
* Copyright (C) 1997-1999  Kenji Mizuguchi and Charlotte Deane              *
* Copyright (C) 1999-2000  Kenji Mizuguchi                                  *
*                                                                           *
* create_tem.c                                                              *
* Define structural features and assign a structural environ-ment for each  *
* amino acid residue.                                                       *
*                                                                           *
* Author: Kenji Mizuguchi                                                   *
*                                                                           *
* Note: This file is updated AUTOMATICLLY by the utility MKJOYF.            *
*       DO NOT MODIFY BY HAND.                                              *
*                                                                           *
* Date:        16 Apr 1999                                                  *
* Last update: 17 Apr 1999                                                  *
*                                                                           *
****************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <parse.h>

#include "rdali.h"
#include "rdsst.h"
#include "rdpsa.h"
#include "rdhbd.h"
#include "utility.h"

#include "tem.h"
#include "tem_j216.h"
#include "tem_default.h"
#include "tem_j4.h"
#include "tem_ext.h"
/* end of include files */

TEM *create_tem(int nstr, int alilen, char *alibase,
		ALI *aliall, int *str_lst,
		SST *sstall, PSA *psaall, HBD *hbdall) {

  TEM *temall = NULL;
  int nfeature;
  int fset;

  fset = which_fset();

  switch (fset) {

/* begin case default */
  case _DEFAULT:
    nfeature = 15;
    temall = allocate_tem(nstr, nfeature, alilen);

    assign_default_features (nstr, alilen, aliall, str_lst,
                        sstall, psaall, hbdall, temall);
    fprintf(stderr, "%d features assigned\n", nfeature);
    write_tem(nstr, alilen, nfeature, default_feature_name, alibase, aliall, str_lst, temall, 75);
    break;
/* end case default */

/* begin case j216 */
  case _J216:
    nfeature = 14;
    temall = allocate_tem(nstr, nfeature, alilen);

    assign_j216_features (nstr, alilen, aliall, str_lst,
                        sstall, psaall, hbdall, temall);
    fprintf(stderr, "%d features assigned\n", nfeature);
    write_tem(nstr, alilen, nfeature, j216_feature_name, alibase, aliall, str_lst, temall, 75);
    break;
/* end case j216 */

/* begin case j4 */
  case _J4:
    nfeature = 14;
    temall = allocate_tem(nstr, nfeature, alilen);

    assign_j4_features (nstr, alilen, aliall, str_lst,
                        sstall, psaall, hbdall, temall);
    fprintf(stderr, "%d features assigned\n", nfeature);
    write_tem(nstr, alilen, nfeature, j4_feature_name, alibase, aliall, str_lst, temall, 75);
    break;
/* end case j4 */
/* begin case ext */
  case _EXT:
    nfeature = 18;
    temall = allocate_tem(nstr, nfeature, alilen);

    assign_ext_features (nstr, alilen, aliall, str_lst,
                        sstall, psaall, hbdall, temall);
    fprintf(stderr, "%d features assigned\n", nfeature);
    write_tem(nstr, alilen, nfeature, ext_feature_name, alibase, aliall, str_lst, temall, 75);
    break;
/* end case ext */
/* add new features between here */

/* and here */

  default:
    fprintf(stderr, "Warning: unrecognized feature set:\n");
    fprintf(stderr, "no .tem will be written\n");
    break;
  }    

  return temall;
}

/*
 * *allocate_tem(int, int, int)
 *
 * allocate memory for the variable temall
 *
 */
TEM *allocate_tem(int nstr, int nfeature, int alilen) {
  TEM *tem;
  int i;
  int j;

  tem = (TEM *) malloc(sizeof(TEM) * nstr);
  if (tem == NULL) {
    fprintf(stderr, "Error: out of memory\n");
    exit(-1);
  }

  for (i=0; i<nstr; i++) {
    tem[i].feature = (_features *) malloc(sizeof(_features) * nfeature);
    if (tem[i].feature == NULL) {
      fprintf(stderr, "Error: out of memory\n");
      exit(-1);
    }
    tem[i].nfeature = nfeature;
    for (j=0; j<nfeature; j++) {
      tem[i].feature[j].assign = (char *) malloc(sizeof(char) * (alilen+1));
      if (tem[i].feature[j].assign == NULL) {
        fprintf(stderr, "Error: out of memory\n");
        exit(-1);
      }
    }
  }
  return tem;
}


int write_tem(int nstr, int alilen, int nfeature, char **feature_name,
	      char *alibase, ALI *aliall, int *str_lst, TEM *temall, int nwidth) {

  int i, j, k;
  char ch;
  char *tem_filename;
  FILE *fout;

  tem_filename = mstrcat(alibase, TEMEXT);
  fout = fopen(tem_filename, "w");
  if (fout == NULL) {
    fprintf(stderr, "Cannot open %s\n", tem_filename);
    return (-1);
  }
  for (j=0; j<nstr; j++) {
    fprintf(fout, ">P1;%s\n", aliall[str_lst[j]].code);
    fprintf(fout, "sequence\n");
    k = 0;
    ch = aliall[str_lst[j]].sequence[0];
    while (ch !=  '\0') {
      k++;
      if (ch == '/') ch = '-';
      fprintf(fout, "%c", ch);
      if ((k % nwidth) == 0) {
	fprintf(fout, "\n");
      }
      ch = aliall[str_lst[j]].sequence[k];
    }
    fprintf(fout, "*\n");
  }

  for (i=0; i<nfeature; i++) {
    for (j=0; j<nstr; j++) {
      fprintf(fout, ">P1;%s\n", aliall[str_lst[j]].code);
      fprintf(fout, "%s\n", feature_name[i]);
      k = 0;
      ch = temall[j].feature[i].assign[0];
      while (ch !=  '\0') {
	k++;
	fprintf(fout, "%c", ch);
	if ((k % nwidth) == 0) {
	  fprintf(fout, "\n");
	}
	ch = temall[j].feature[i].assign[k];
      }
      fprintf(fout, "*\n");
    }
  }
  fclose(fout);
  return (0);
}

int which_fset() {
  char *fsetc;
  
  fsetc = strdup(VS(V_FEATURE_SET));

  if (strcmp(fsetc, "default") == 0) {
    fprintf(stderr, "feature set: %s\n", fsetc);
    return _DEFAULT;
  }

  if (strcmp(fsetc, "j216") == 0) {
    fprintf(stderr, "feature set: %s\n", fsetc);
    return _J216;
  }

  if (strcmp(fsetc, "j4") == 0) {
    fprintf(stderr, "feature set: %s\n", fsetc);
    return _J4;
  }

  if (strcmp(fsetc, "ext") == 0) {
    fprintf(stderr, "feature set: %s\n", fsetc);
    return _EXT;
  }

/* which_fset */

  fprintf(stderr, "Unknown feature set %s\n", fsetc);
  fprintf(stderr, "default feature set is used instead\n");
  return _DEFAULT;
}
