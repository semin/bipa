/*
 *
 * $Id:
 *
 * joy 5.0 release $Name:  $
 */
/****************************************************************************
* joy: A program for protein sequence-structure representation and analysis *
* Copyright (C) 1988-1997  John Overington                                  *
* Copyright (C) 1997-1999  Kenji Mizuguchi and Charlotte Deane              *
* Copyright (C) 1999-2000  Kenji Mizuguchi                                  *
*                                                                           *
* rdsst                                                                     *
*                                                                           *
* Reads in a .sst file                                                      *
* Stores data in a SST variable (see rdsst.h) and does                      *
* nothing else.                                                             *
*                                                                           *
* Author: Kenji Mizuguchi                                                   *
*                                                                           *
* Note                                                                      *
*                                                                           *
* Date:	       15 Feb 1999                                                  *
* Last update: 22 Apr 1999                                                  *
*                                                                           *
****************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <parse.h>
#include "joy.h"
#include "utility.h"
#include "findfile.h"
#include "rdsst.h"

/***************************************************
* get_sst
*
***************************************************/
SST *get_sst(int n, char **code, int *lenseq) {
  SST *sstall;
  char *sst_filename;
  FILE *fp;
  int i;

  sstall = _allocate_sst(n, lenseq);

  for (i=0; i<n; i++) {
    sst_filename = find_datafile(code[i], SST_SUFFIX);
    if (sst_filename == NULL) {
      fprintf(stderr, "Error: cannot find or create .sst file for %s\n",
	      code[i]);
      return NULL;
    }

    fp = fopen(sst_filename, "r");
    if (fp != NULL) {
      if (_rdsst(fp, lenseq[i], sstall[i], sst_filename) != 0) {
	fprintf(stderr, "Error in reading %s\n", sst_filename);
	return NULL;
      }
      fclose(fp);
    }
    else {
      fprintf(stderr, "Error: cannot open %s\n", sst_filename);
      exit(-1);
    }      
    free(sst_filename);
  }
  return sstall;
}

/***************************************************
* _rdsst: Main function to read in a .sst file
*
***************************************************/
int _rdsst(FILE *in_file, int nseq, SST sst, char *sst_filename) {
  char line[SST_BUFSIZE];
  int nrestot;
  int i;

  for (i=0; i<4; i++) {
    if (! fgets(line, sizeof(line), in_file)) {
      fprintf(stderr, "Format error in .sst file (line %d empty?)\n",
	      i+1);
      return(1);
    }
  }
  if (sscanf(line+18, "%d", &nrestot) == 0) {
    fprintf(stderr, "Format error in .sst file ");
    fprintf(stderr, "(no sequence length in line 4)\n");
    return(1);
  }
  if (nrestot != nseq) {
    fprintf(stderr, "Warning in reading %s\n", sst_filename);
    fprintf(stderr, "  No of sequences to read in is %d, while ",nseq);
    fprintf(stderr, "the Sequence length line indicates %d residues.\n", nrestot);
  }
  for (i=0; i<3; i++) {
    fgets(line, sizeof(line), in_file);
  }

  i = 0;
  while (fgets(line, sizeof(line), in_file) != NULL) {
    if (i >= nseq) {
      break;
    }
/* non-standard amino acid */
/*
    if (line[18] == '-' || line[18] == 'X') { 
      fprintf(stderr, "Ignored non standard amino acid %c\n", line[18]);
      continue;
    }
*/
    sst.chain[i] = *(line+5);
    strncpy(sst.resnum[i], line+6, 5);
    sst.resnum[i][5] = '\0';

    sst.sequence[i] = *(line+18);
    sst.dssp[i] = *(line+22);

    if (sscanf(line+46, "%lf %lf %lf",
	       &sst.phi[i], &sst.psi[i], &sst.omega[i]) < 3) {
      fprintf(stderr, "Error: incorrect format\n");
      fprintf(stderr, "%s", line+46);
      fprintf(stderr, "Can't read phi, psi and omega.\n");
      fprintf(stderr, "%f %f %f\n", sst.phi[i], sst.psi[i], sst.omega[i]);
      return (-1);
    }
    if (sscanf(line+128, "%3d", &sst.ooi[i]) == 0) { /* Ooi N=14 */
      fprintf(stderr, "Error: incorrect format\n");
      fprintf(stderr, "   %s", line);
      fprintf(stderr, "Can't read Ooi.\n");
      return (-1);
    }
    i++;
  }
  return 0;
}

SST *_allocate_sst(int nstr, int *lenseq) {
  SST *sst;
  int i;

  sst = (SST *) malloc(sizeof(SST) * nstr);
  if (sst == NULL) {
    fprintf(stderr, "Error: out of memory\n");
    exit(-1);
  }

  for (i=0; i<nstr; i++) {
    sst[i].resnum = cmatrix(lenseq[i], 6);
    sst[i].chain = cvector(lenseq[i]+1);
    sst[i].sequence = cvector(lenseq[i]+1);
    sst[i].dssp = cvector(lenseq[i]+1);
    sst[i].phi = dvector(lenseq[i]);
    sst[i].psi = dvector(lenseq[i]);
    sst[i].omega = dvector(lenseq[i]);
    sst[i].ooi = ivector(lenseq[i]);
  }
  return sst;
}
/***************************************************
* write_sst This is for debugging (comment lines not reproduced)
*
***************************************************/
void write_sst (SST sst, int n) {
  int i;
  for (i=0; i<n; i++) {
    printf("%3d %c %c ", i+1, sst.sequence[i], sst.dssp[i]);
    printf("%6.1f %6.1f %6.1f %3d\n", sst.phi[i], sst.psi[i], sst.omega[i],
	   sst.ooi[i]);
  }
}
