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
* rdpsa                                                                     *
* Reads in a .psa file                                                      *
*                                                                           *
* Currently, only the relative sidechain accessibility and a                *
* flag ('!') to indicate missing atoms are read in.                         *
* Stores these data into a PSA variable (see rdpsa.h) and                   *
* does nothing else.                                                        *
*                                                                           *
* Author: Kenji Mizuguchi                                                   *
*                                                                           *
* Note                                                                      *
*                                                                           *
* Date:        29 Jan 1999                                                  *
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
#include "rdpsa.h"
#include "findfile.h"

/***************************************************
* get_psa
*
***************************************************/
PSA *get_psa(int n, char **code, int *lenseq) {
  PSA *psaall;
  char *psa_filename;
  FILE *fp;
  int i;

  psaall = _allocate_psa(n, lenseq);

  for (i=0; i<n; i++) {
    psa_filename = find_datafile(code[i], PSA_SUFFIX);
    if (psa_filename == NULL) {
      fprintf(stderr, "Error: cannot find or create .psa file for %s\n",
	      code[i]);
      return NULL;
    }

    fp = fopen(psa_filename, "r");
    if (fp != NULL) {
      if (_rdpsa(fp, lenseq[i], psaall[i]) != 0) {
	fprintf(stderr, "Error in reading %s\n", psa_filename);
	return NULL;
      }
      psaall[i].naa = lenseq[i];
      fclose(fp);
    }
    else {
      fprintf(stderr, "Error: cannot open %s\n", psa_filename);
      exit(-1);
    }      
    free(psa_filename);
  }
  return psaall;
}

/***************************************************
* _rdpsa: Main function to read in a .psa file
*
***************************************************/
int _rdpsa(FILE *in_file, int nseq, PSA psa) {
  char line[PSA_BUFSIZE];
  int i;

  i = 0;
  while (fgets(line, sizeof(line), in_file) != NULL) {
    /* read in records beggining with the keyword */

    if (strncmp(line, KEY, sizeof(KEY)-1) == 0) {
      if (i >= nseq) {
	fprintf(stderr, "No of records beginning with ");
	fprintf(stderr, KEY);
	fprintf(stderr, " is larger than no of residues to read in (%d)\n", nseq);
	return 1;
      }

      strncpy(psa.resnum[i], line+7, 5);
      psa.resnum[i][5] = '\0';
      strncpy(psa.sequence[i], line+14, 3);
      psa.sequence[i][3] = '\0';

      if (sscanf(line+61, "%lf", &psa.side_per[i]) == 0) {
	psa.side_per[i] = 100.0;    /* read error */
	fprintf(stderr, "Warning: incorrect format\n");
	fprintf(stderr, "   %s", line);
	fprintf(stderr, "The value 100.0 has been set for the sidechain accessibility of this residue.\n");
      }
      if (strncmp(line+18, "!", 1) == 0) {
	psa.missing_atom[i] = 1;
      }
      else {
	psa.missing_atom[i] = 0;
      }
      i++;
    }
  }
  if (nseq == i) {
    return 0;
  }
  else {
    return 1;
  }
}

PSA *_allocate_psa(int nstr, int *lenseq) {
  PSA *psa;
  int i;

  psa = (PSA *) malloc(sizeof(PSA) * nstr);
  if (psa == NULL) {
    fprintf(stderr, "Error: out of memory\n");
    exit(-1);
  }

  for (i=0; i<nstr; i++) {
    psa[i].sequence = cmatrix(lenseq[i], 4);
    psa[i].resnum = cmatrix(lenseq[i], 6);
    psa[i].side_per = dvector(lenseq[i]);
    psa[i].missing_atom = ivector(lenseq[i]);
  }
  return psa;
}

int count_lines(char *code) { /* count the ACCESS lines in the .psa file
				 to determine the necessary array size */
  char *psa_filename;
  FILE *fp;
  char line[PSA_BUFSIZE];
  int i = 0;
		
  psa_filename = mstrcat(code, PSA_SUFFIX);
  if (access(psa_filename, R_OK) != 0) {
    fprintf(stderr, "%s not found\n", psa_filename);
    psa_filename = find_datafile(code, PSA_SUFFIX);
  }
  fp = fopen(psa_filename, "r");
  if (fp != NULL) {
    while (fgets(line, sizeof(line), fp) != NULL) {
    /* read in records beggining with the keyword */

      if (strncmp(line, KEY, sizeof(KEY)-1) == 0)
	i++;
    }
    fclose(fp);
  }
  else {
    fprintf(stderr, "Error: cannot open %s\n", psa_filename);
    exit(-1);
  }      
  free(psa_filename);
  return i;
}
  
/***************************************************
* write_psa This is for debugging (comment lines not reproduced)
*
***************************************************/
void write_psa (PSA psa, int n) {
  int i;
  for (i=0; i<n; i++) {
    printf("%3d %5.1f ", i+1, psa.side_per[i]);
    if (psa.missing_atom[i] == 1) {
      printf("!\n");
    }
    else {
      printf("\n");
    }
  }
}
