/*
 *
 * $Id: main.c,v 1.24 2003/03/25 11:52:02 kenji Exp $
 *
 * joy 5.0 release $Name:  $
 */
/****************************************************************************
* joy: A program for protein sequence-structure representation and analysis *
* Copyright (C) 1988-1997  John Overington                                  *
* Copyright (C) 1997-1999  Kenji Mizuguchi and Charlotte Deane              *
* Copyright (C) 1999-2000  Kenji Mizuguchi                                  *
*                                                                           *
* main.c                                                                    *
* Main function for joy                                                     *
****************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <parse.h>
#include "joy.h"
#include "release.h"
#include "utility.h"
#include "findfile.h"
#include "rdali.h"
#include "rdpsa.h"
#include "rdsst.h"
#include "rdhbd.h"
#include "tem.h"
#include "gen_html.h"
#include "gen_rtf.h"
#include "gen_ps.h"
#include "analysis.h"
#include "rddom.h"
#include "chkseq.h"

int banner(void);
void chk_seg(ALIFAM *, SST *, int *);
int *get_seqlen(int, int *, ALI *);
char **get_strcode(int, ALI *, int *);

int main (int argc, char *argv[]) {
  char *inpfile;
  char *alibase;
  ALIFAM *alifam;
  PSA *psaall = NULL;
  SST *sstall = NULL;
  HBD *hbdall = NULL;
  TEM *temall = NULL;

  int nument;       /* total number of entries */
  int alilen;       /* length of the alignment (including gaps) */
  int nstr;         /* number of structure entries */
  char **str_code = NULL;
                    /* list of codes for structure entries */
  int ndom = -1;    /* number of domains (optional) */
  int i;

  init_parser("joyconf",PARSE_IGNORE_CONF);
  i = parse_options(argc,argv);

  banner();
  if (!argv[i]) {
    show_var_help(NULL);
    exit (0);
  }
/****************
  Read ALI file
*****************/
  alibase = chkAli(argv[i]);
  if (alibase) { /* .ali found all right */
    inpfile = mstrcat(alibase, ALI_SUFFIX);
  }
  else {
    fprintf(stderr, "Error: Cannot find .ali file\n");
    exit (-1);
  }

  alifam = get_ali(inpfile, alibase);

  /* the following variables remain for historical reasons */
  nument = alifam->nument;
  alilen = alifam->alilen;
  nstr = alifam->nstr;

  if (nstr > 0) {
    str_code = get_strcode(nstr, alifam->ali, alifam->str_lst);
    alifam->lenseq = get_seqlen (nstr, alifam->str_lst, alifam->ali);
  }
  else {
    alifam->lenseq = NULL;
  }
  fprintf(stderr, "number of structure entries: %d\n", nstr);

/****************
  Read DOM file
*****************/
  if (VI(V_DOMAIN)) ndom = rddomain(alifam);

  /* Translate sequences into lowercase characters */

  if (VI(V_LC)) toLowerCase(alifam);


  if (nstr > 0) {
/****************
  Get PSA data 
*****************/
    psaall = get_psa(nstr, str_code, alifam->lenseq);
    if (!psaall) {
      fprintf(stderr, "Failed to read in the PSA data\n");
      exit(-1);
    }

/****************
  Get SST data 
*****************/
    sstall = get_sst(nstr, str_code, alifam->lenseq);
    if (!sstall) {
      fprintf(stderr, "Failed to read in the SST data\n");
      exit(-1);
    }

/****************
  Get HBD data 
*****************/
    hbdall = get_hbd(nstr, str_code, alifam->lenseq);
    if (!hbdall) {
      fprintf(stderr, "Failed to read in the HBD data\n");
      exit(-1);
    }

/*
  for (i=0; i<nstr; i++) {
    printf("%s\n", alifam->ali[i].code);
    write_psa(psaall[i], lenseq[i]); 
    write_sst(sstall[i], lenseq[i]); 
    show_assign(alifam->lenseq[i], hbdall[i]); 
  }
*/
    if (VI(V_SEG)) {
      chk_seg(alifam, sstall, alifam->lenseq);
    }

/****************
  Check consistency
*****************/
    if (VI(V_CHECK) && !VI(V_SEG)) {
      if (chkseq(alifam, psaall, sstall, hbdall) == 0) {
	exit(-1);
      }
    }

/****************
  Create TEM
*****************/

    temall = create_tem(nstr, alilen, alibase,
			alifam->ali, alifam->str_lst, sstall, psaall, hbdall);

/****************
  Optional analysis
*****************/
    analshort(alifam);
  }

/****************
  Generate HTML
*****************/

  if (VI(V_HTML)) {
    fprintf(stderr, "HTML output\n");
    gen_html(alifam, str_code, temall, psaall,
	     alifam->lenseq, ndom);
  }
/****************
  Generate RTF
*****************/

  if (VI(V_RTF)) {
    fprintf(stderr, "RTF output\n");
    gen_rtf(alifam, str_code, temall, psaall,
	    alifam->lenseq, ndom);
  }
/****************
  Generate PS
*****************/

  if (VI(V_PS)) {
    fprintf(stderr, "PS output\n");
    gen_ps(alifam, str_code, temall, psaall,
	   alifam->lenseq, ndom);
  }

  return (1);
}

/***************************************************
* get_strcode
*
* Make a list of codes for structure entries
***************************************************/
char **get_strcode (int nstr, ALI *aliall, int *str_lst) {
  int i;
  char **str_code;

  str_code = (char **)malloc((size_t) (nstr * sizeof(char *)));
  if (str_code == NULL) {
    fprintf(stderr, "Can't allocate memory\n");
    exit(1);
  }
  for (i=0; i<nstr; i++) {
    str_code[i] = strdup(aliall[str_lst[i]].code);
  }
  return str_code;
}

/***************************************************
* get_seqlen
*
* Given an array of the structure ALI and an array 
* of indices to specify structure entries,
* calculates the sequence length for each of
* them and makes a list.
***************************************************/
int *get_seqlen (int nstr, int * str_lst, ALI *aliall) {
  int *lenseq;      /* list of sequence lengths for structure entries */
  int i;
  int n;
  char *c;

  lenseq = ivector(nstr);

  for (i=0; i<nstr; i++) {
    if (VI(V_SEG)) {   /* use segment, thereofore cannot determine the 
			  length of the protein from the alignment.
			  For the moment, count the ACCESS lines in the PSA file...*/
      lenseq[i] = count_lines(aliall[str_lst[i]].code);
      continue;
    }

    n = 0;
    c = aliall[str_lst[i]].sequence; 

    while (c != NULL && *c != '\0') {
      if (*c != '-' && *c != '/') {   /* allowed gap characters 
					 (Everything else is taken as an
					  amino acid code. Maybe this
					  should be changed.) */
	n++;
      }
      c++;
    }
    lenseq[i] = n;
  }
  return lenseq;
}

/***************************************************
* chk_seg
*
* Converts the start and end PDB residue numbers for each 
* structure to sequential numbers (by using the 
* information from SST).
***************************************************/
void chk_seg(ALIFAM *alifam, SST *sstall, int *lenseq) {
  int nument;
  ALI *aliall;
  int i, j, k;
  int found_strt, found_end;
  char strtres[6], endres[6], tmp[6];
  char strtchn, endchn;
  
  nument = alifam->nument;
  aliall = alifam->ali;

  for (i=0; i<alifam->nstr; i++) {
    j = (alifam->str_lst)[i];
    strcpy(strtres, aliall[j].seg.strt_pdbres);
    strcpy(endres, aliall[j].seg.end_pdbres);
    strtchn = aliall[j].seg.strt_chain;
    endchn = aliall[j].seg.end_chain;

    aliall[j].seg.strt_seqnum = 0;
    aliall[j].seg.end_seqnum = lenseq[i]-1;
    found_strt = 0;
    found_end = 0;

    for (k=0; k<lenseq[i]; k++) {
      strcpy(tmp, sstall[i].resnum[k]);
      strcpy(tmp, trim_space(tmp));

      if (strcmp(strtres, tmp) == 0 && strtchn == sstall[i].chain[k]) {
	aliall[j].seg.strt_seqnum = k;
	found_strt = 1;
      }
      else if (strcmp(endres, tmp) == 0 && endchn == sstall[i].chain[k]) {
	aliall[j].seg.end_seqnum = k;
	found_end = 1;
	break;
      }
    }

    if (found_strt == 0) {
      fprintf(stderr, "Warning: residue %s of chain '%c' specified in the .ali file ", strtres, strtchn);
      fprintf(stderr, "not found in the file %s.sst\n", aliall[j].code);
      fprintf(stderr, "         starting from postion 0 insted\n");
      fprintf(stderr, "         This is likely to cause problems!\n");
    }
    if (found_end == 0) {
      fprintf(stderr, "Warning: residue %s of chain '%c' specified in the .ali file ", endres, endchn);
      fprintf(stderr, "not found in the file %s.sst\n", aliall[j].code);
      fprintf(stderr, "         stop at postion %d insted\n", lenseq[i]);
      fprintf(stderr, "         This is likely to cause problems!\n");
    }
  }
}

int banner() {
  printf("JOY ");
  printf(MAINVERSION);
  printf(".");
  printf(SUBVERSION);
  printf(" (");
  printf(UPDATE);
  printf(")\n");
  printf("Copyright (C) 1988-1997  John Overington\n");
  printf("Copyright (C) 1997-1999  Kenji Mizuguchi and Charlotte Deane\n");
  printf("Copyright (C) 1999-2002  Kenji Mizuguchi\n");
  printf("Reference: Mizuguchi, K., Deane, C.M., Blundell, T.L., Johnson, M.S.\n");
  printf("Overington, J.P. (1998) JOY: protein sequence-structure\n");
  printf("representation and analysis. Bioinformatics 14:617-623.\n");
  printf("http://www-cryst.bioc.cam.ac.uk/~joy/\n\n");
  return (1);
}
