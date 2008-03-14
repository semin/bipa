/*
 *
 * $Id: chkseq.c,v 1.8 2000/08/01 10:19:35 kenji Exp $
 *
 * joy 5.0 release $Name:  $
 */
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
#include "chkseq.h"

int chkseq(ALIFAM *alifam, PSA *psaall, 
	   SST *sstall, HBD *hbdall) {
  int nstr;
  ALI *aliall;
  char *c;
  char *csst;
  char *chbd;
  char *cpsa;
  int i;
  int is;
  int np;  /* alignment position */
  int n;   /* position within a sequence */

  nstr = alifam->nstr;
  aliall = alifam->ali;

  for (i=0; i<nstr; i++) {
    is = (alifam->str_lst)[i];

/*    printf("#%d %s\n", is, aliall[is].code); */
    np = 0;
    n = 0;
    c = aliall[is].sequence; 

    cpsa = throne(psaall[i].naa, psaall[i].sequence);
    csst = sstall[i].sequence;
    chbd = hbdall[i].sequence;

    while (c != NULL && *c != '\0') {
      np++;
      if (isgap(*c) == 0) {
	n++;

/* checks for consistency between the alignment sequence and the
   .sst file  */

	if (*c != *csst && *csst != 'X' &&
	    ((*c != 'C' && *c != 'J') || (*csst != 'C' && *csst != 'J'))) {
	  fprintf(stderr, "Error: inconsistency between .ali and .sst files\n");
	  fprintf(stderr, "sequence %s at %d (alignment position %d)\n",
		  aliall[is].code, n, np);
	  fprintf(stderr, "%c (.ali) <->  %c (.sst)\n", *c, *csst);
	  return 0;
	}

/* checks for consistency between the alignment sequence and the
   .hbd file  */

	if (*c != *chbd && *chbd != 'X' &&
	    ((*c != 'C' && *c != 'J') || (*chbd != 'C' && *chbd != 'J'))) {
	  fprintf(stderr, "Error: inconsistency between .ali and .hbd files\n");
	  fprintf(stderr, "sequence %s at %d (alignment position %d)\n",
		  aliall[is].code, n, np);
	  fprintf(stderr, "%c (.ali) <-> %c (.hbd)\n", *c, *chbd);
	  return 0;
	}

/* checks for consistency between the alignment sequence and the
   .psa file  */

	if (*c != cpsa[n-1] && cpsa[n-1] != 'X' &&
	    ((*c != 'C' && *c != 'J') || (cpsa[n-1] != 'C' && cpsa[n-1] != 'J'))) {
	  fprintf(stderr, "Error: inconsistency between .ali and .psa files\n");
	  fprintf(stderr, "sequence %s at %d (alignment position %d)\n",
		  aliall[is].code, n, np);
	  fprintf(stderr, "%c (.ali) <-> %c (.psa)\n", *c, cpsa[n-1]);
	  return 0;
	}
/*	printf("%d %d %c %c %c %c\n", np, n, *c, *csst, *chbd, cpsa[n-1]); */
	csst++;
	chbd++;
      }
      c++;
    }
    free(cpsa);
  }
  return 1;
}

int isgap (char c) {
  if (c == '-' || c == '/') {
    return(1);
  }
  return(0);
}

/*
Converts three letter code to one letter code
*/
char *throne (int n, char **seqthree) {
  char aa1[] = "SGVTALDIPKQNFYERCHWMBZXJ";
  char aa3[][4] = {
      "SER","GLY","VAL","THR","ALA",
      "LEU","ASP","ILE","PRO","LYS",
      "GLN","ASN","PHE","TYR","GLU",
      "ARG","CYS","HIS","TRP","MET",
      "ASX","GLX","UNK","CYH" };
  char *seqone;
  int naa = 24;
  int i, j;
  int found;

  seqone = cvector(n+1);
  for (i=0; i<n; i++) {
    found = 0;
    for (j=0; j<naa; j++) {
      if (strcmp(seqthree[i], aa3[j]) == 0) {
	seqone[i] = aa1[j];
	found = 1;
	break;
      }
    }
    if (found == 0) {
      seqone[i] = 'X';
    }
  }
  seqone[n] = '\0';
  return seqone;
}

int toLowerCase(ALIFAM *alifam) {
  ALI *aliall;
  int nument;
  int alilen;
  int i, j;

  nument = alifam->nument;
  alilen = alifam->alilen;
  aliall = alifam->ali;

  for (i=0; i<nument; i++) {
    if (aliall[i].type != SEQUENCE) continue;
    for (j=0; j<alilen; j++) {
      aliall[i].sequence[j] = tolower(aliall[i].sequence[j]);
    }
  }
  return (1);
}
