/*
 *
 * $Id: gen_rtf.c,v 1.8 2003/03/25 11:52:02 kenji Exp $
 *
 * joy 5.0 release $Name:  $
 */
/****************************************************************************
* joy: A program for protein sequence-structure representation and analysis *
* Copyright (C) 1988-1997  John Overington                                  *
* Copyright (C) 1997-1999  Kenji Mizuguchi and Charlotte Deane              *
* Copyright (C) 1999-2000  Kenji Mizuguchi                                  *
*                                                                           *
* gen_rtf.c                                                                 *
* Produces RTF output                                                       *
****************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <unistd.h>
#include <math.h>

#include <parse.h>
#include "typeset.h"

#include "utility.h"
#include "rdali.h"
#include "rdpsa.h"
#include "rdsst.h"
#include "rdhbd.h"
#include "tem.h"
#include "tag.h"
#include "gen_html.h"
#include "gen_rtf.h"
#include "analysis.h"
#include "rddom.h"

#define DEFAULT_DSSP 11   /* not an elegant solution, to be remembered! */

static char *taglist[] = {
  "\\cf0",
  "\\cf1",
  "\\cf2",
  "\\cf3",
  "\\cf4",
  "\\cf5",
  "\\cf6",
  "\\cf7",
  "\\cf8",
  "\\cf9",
  "\\b",
  "\\ul",
  "\\i"
};

static html_style tagged_style[] = {
  {11, 'H', V_RED, "red", "alpha helix"},
  {11, 'E', V_BLUE, "blue", "beta strand"},
  {11, 'G', V_MAROON, "maroon", "3 - 10 helix"},
  {3, 'T', V_BOLD, "bold", "hydrogen bond to main chain amide"},
  {2, 'T', V_UNDERLINE, "underline", "hydrogen bond to mainchain carbonyl"},
  {12, 'T', V_ITALIC, "italic", "positive phi"},
};

static int nt = 6;  /* number of different tags */
static int ns = 3;  /* number of features represented without using tags */

static html_style notag_style[] = {
  {1, 'F', V_UPPER_CASE, "UPPER CASE", "solvent inaccessible"},
  {1, 'T', V_LOWER_CASE, "lower case", "solvent accessible"},
  {8, 'T', V_CEDILLA, "cedilla", "disulphide bond"},
};

static char *dummy = "";

int gen_rtf(ALIFAM *alifam, char **str_code,
	    TEM *temall, PSA *psaall, int *lenseq, int ndom) {
  int nument;
  int nstr;
  int alilen;
  ALI *aliall;
  int i, j, k, l;
  int *pos;        /* index for the current residue position in each sequence  */
                   /* starts from non-zero values when segment is used         */
  int *strtpos = NULL;   /* index for the inital residut position in each structure entry */
  int *endpos = NULL;    /* index for the last residut position in each structure entry */
  html_style *style;
  int ib, strt, end;
  int nwidth;      /* width of alignment */
  int nchr;        /* width of protein codes */
  char seq;
  char *rtf_filename;
  FILE *rtf;
  int *itag;       /* to link the structure style and the array taglist */
  int it;
  TagAll *alltag = NULL;
  Tag *tg;
  char *conss = NULL;  /* consensus secondary structure */
  int **labels = NULL; /* store referring str and seq numbers for each label */
  int nl = 0;      /* number of label entries */
  int lstr = -1;
  int lseq = -1;
  int inum;
  int s;
  
  aliall = alifam->ali;
  nument = alifam->nument;
  alilen = alifam->alilen;
  nstr =   alifam->nstr;

  rtf_filename = mstrcat(alifam->code, RTF_SUFFIX);
  rtf = fopen(rtf_filename, "w");
  if (rtf == NULL) {
    fprintf(stderr, "Cannot open %s\n", rtf_filename);
    return (-1);
  }

  if (! alifam->family) {
    alifam->family = get_keywd(alifam->comment, FAMILY);
  }

  if (!(style = set_default(tagged_style, notag_style, nt, ns))) {
    fprintf(stderr, "Error in assigning the RTF typesetting code\n");
    fprintf(stderr, "(no RTF output)\n");
    fclose(rtf);
    remove(rtf_filename);
    return (-1);
  }

  itag = set_tag(style, nt);

/* defining conseneus secondary structures */

  if (VI(V_CONSENSUS_SS) && (strcmp(VS(V_FEATURE_SET), "default") == 0) &&
      nstr > 0) {
    conss = consensus_ss(alifam, nstr, str_code, temall, DEFAULT_DSSP);

    /* currently consensus SS is shown only when the default feature set is selected */
  }

/* check label entries */

  for (i=0; i<nument; i++) {
    if (aliall[i].type == LABEL) {
      nl++;
    }
  }
  if (nl > 0) {
    labels = imatrix(nl, 3);
    nl = 0;
    for (i=0; i<nument; i++) {
      if (aliall[i].type == LABEL) {
	lstr = get_label_strnum(nstr, str_code, aliall[i].code);
	lseq = get_label_seqnum(nument, aliall, aliall[i].code);
	if (lstr < 0 || lseq < 0) {
	  fprintf(stderr, "Warning: entry %s specified for numbering but does not exist! (ignored)\n",
		  aliall[i].code);
	}
	labels[nl][0] = i;
	labels[nl][1] = lstr;
	labels[nl][2] = lseq;
	nl++;
      }
    }
  }

  nwidth = VI(V_NWIDTH);

/* determine the width of the sequence names */
  nchr = code_width (nument, aliall);

/* index for the residue position in each sequence */
  pos = ivector(nument);
  for (i=0; i<nument; i++) {
    pos[i] = 0;
  }
  if (nstr > 0) {
    strtpos = ivector(nstr);
    endpos = ivector(nstr);
  }
  if (VI(V_SEG)) {
    for (i=0; i<nstr; i++) {
      j = (alifam->str_lst)[i];   /* index for a structure entry */
      strtpos[i] = aliall[j].seg.strt_seqnum;   /* start pos in the segment */
      endpos[i] = aliall[j].seg.end_seqnum + 1; /* end pos in the segmen */
      pos[j] = strtpos[i];
    }
    for (i=0; i<nl; i++) {
      j = labels[i][2];                                    /* index for a structure entry */
      strtpos[labels[i][0]] = aliall[j].seg.strt_seqnum;   /* start pos in the segment */
      endpos[labels[i][0]] = aliall[j].seg.end_seqnum + 1; /* end pos in the segmen */
      pos[labels[i][0]] = strtpos[labels[i][0]];
    }     
  }
  else {
    for (i=0; i<nstr; i++) {
      strtpos[i] = 0;
      endpos[i] = lenseq[i];
    }
  }

/* determine the start and end position of tags */

  if (nstr > 0) {
    alltag = (TagAll *) malloc(sizeof(TagAll) * nstr);
    if (alltag == NULL) {
      fprintf(stderr, "Error: out of memory\n");
      exit(-1);
    }

    for (i=0; i<nstr; i++) {
      alltag[i].tags = assignTag(nt, alilen, i, temall, tagged_style, nwidth);
    }
  }

/********************* end of preprocessing ***************************/

  write_rtfheader(rtf);

  ib = 0;
  while (1) {
    strt = nwidth * ib;
    if (strt >= alilen) break;

    end = strt + nwidth;
    if (end >= alilen) end = alilen;

    k = 0;     /* sequential number of structures */

/* output alignment position */
    if (VI(V_ALIGNMENT_POS)) {
      fprintf(rtf, "{%s ",taglist[T_BLACK]);
      write_alignpos(rtf, nchr, strt, end);
      fprintf(rtf, "}");
      fprintf(rtf, "\\line\n");
    }

/* output domain assignment */

    for (i=0;i<nument; i++) {

/* protein codes and sequence numbers */

      if (aliall[i].type == LABEL) {
	fprintf(rtf, "{%s %-*s             ", taglist[T_BLACK], nchr, dummy);
      }
      else if (aliall[i].type == STRUCTURE && pos[i] < endpos[k]) {
	fprintf(rtf, "{%s %-*s  (%5s)    }", taglist[T_BLACK],
		nchr, aliall[i].code, psaall[k].resnum[pos[i]]);
      }
      else if (aliall[i].type == STRUCTURE && pos[i] >= endpos[k]) {
	fprintf(rtf, "{%s %-*s  (%5s)    }", taglist[T_BLACK],
		nchr, aliall[i].code, dummy);
      }
      else if (aliall[i].type == SEQUENCE) {
	fprintf(rtf, "{%s %-*s             }", taglist[T_BLACK],
		nchr, aliall[i].code);
      }
      else {
	fprintf(rtf, "{%s %-*s             }", taglist[T_BLACK],
		nchr, aliall[i].code);
      }

/* amino acids */

      if (aliall[i].type == STRUCTURE) { /* structure entry */

	tg = alltag[k].tags;

	for (j=strt; j<end; j++) {
	  seq = aliall[i].sequence[j];

	  if ((pos[i] <= strtpos[k] && seq == '-') ||
	      pos[i] >= endpos[k] ||  /* edge gaps not shown */
	      seq == '/') {
	    fprintf(rtf, " ");
	  }
	  else if (seq == '-') {
	    if (isBreak(aliall[i].sequence+j, j)) {
	      fprintf(rtf, " ");
	    }
	    else {
	      fprintf(rtf, "-");
	    }
	  }
	  else {
	    for (l=0; l<tg[j].nb; l++) { /* check if any tag begins at this position */
	      it = tg[j].begin[l];
	      fprintf(rtf, "{%s", taglist[itag[it]]);
	    }
	    if (tg[j].nb > 0) fprintf(rtf, " ");

/*	    it = 0;
	    for (l=0; l<nt; l++) {  
	      if (tags[k].strt[l][j] == 1) {
		fprintf(rtf, "{%s", taglist[itag[l]]);
		it = 1;
	      }
	    }
	    if (it == 1) fprintf(rtf, " ");  */

	    show_aa(k, temall, j, style, nt, ns,
		    aliall[i].sequence[j], rtf);  /* check features that are represented 
						     without using tags and display amino acid*/

	    for (l=0; l<tg[j].ne; l++) { /* check if any tag ends at this position */
	      fprintf(rtf, "}");
	    }

/*	    for (l=0; l<nt; l++) {
	      if (tags[k].end[l][j] == 1) {
		fprintf(rtf, "}");
	      }
	    } */

	    pos[i]++;
	  }
	}
	k++;
      }
      else if (aliall[i].type == SEQUENCE) { /* sequence entry (B&W)*/
	for (j=strt; j<end; j++) {
	  if (aliall[i].sequence[j] == '/') {
	    fprintf(rtf, " ");
	  }
	  else if (aliall[i].sequence[j] == '-') {
	    if (isBreak(aliall[i].sequence+j, j)) {
	      fprintf(rtf, " ");
	    }
	    else {
	      fprintf(rtf, "-");
	    }
	  }
	  else {            /* edge gaps sill shown, can be modified when an elegant solution found */
	    fprintf(rtf, "%c", aliall[i].sequence[j]);
	  }
	}
      }	
      else if (aliall[i].type == TEXT) { /* text entry (other) */
	for (j=strt; j<end; j++) {
	  if (aliall[i].sequence[j] == SPACE_CHAR) {
	    fprintf(rtf, " ");
	  }
	  else {
	    fprintf(rtf, "%c", aliall[i].sequence[j]);
	  }
	}
      }	
      else if (aliall[i].type == LABEL) { /* label entry */
	for (j=0; j<nl; j++) {
	  if (labels[j][0] == i) {
	    lstr = labels[j][1];
	    lseq = labels[j][2];
	    break;
	  }
	}
	if (lseq < 0) {
	  fprintf(rtf, "}\\line\n");
	  continue;
	}
	s = 0;
	for (j=strt; j<end; j++) {
	  if (aliall[lseq].sequence[j] == '-' || aliall[lseq].sequence[j] == '/') {
	    s++;
	  }
	  else {
	    inum = atoi(psaall[lstr].resnum[pos[i]]);
	    if (fmod(inum, 10) < 1) {
	      fprintf(rtf, "%-*s%d", s, dummy, inum);
	      if (inum < 100) {
		s = -1;
	      }
	      else if (inum < 1000) {
		s = -2;
	      }
	      else {
		s = -3;
	      }
	    }
	    else {
	      s++;
	    }
	    pos[i]++;
	  }
	}
	fprintf(rtf, "}\n");
      }

      fprintf(rtf, "\\line\n");
    }

    if (VI(V_CONSENSUS_SS) && conss) { /* consensus secondary structure */
      show_consensus(rtf, strt, end, conss, nchr);
    }

    fprintf(rtf, "\\line\n");
    ib++;
  }

  fprintf(rtf, "}\n");
  fclose(rtf);

  free(pos);
  if (strtpos) {
    free(strtpos);
  }
  if (endpos) {
    free(endpos);
  }
  free(rtf_filename);
  if (nl > 0) {
    free(labels[0]);
    free(labels);
  }
  free(style);
  free(itag);

  return (0);
}

int *set_tag(html_style *style, int nt) {
  int i;
  int *itag;

  itag = ivector(nt);

  for (i=0; i<nt; i++) {
    switch (style[i].num) {
    case V_RED:
      itag[i] = T_RED;
      break;
    case V_BLUE:
      itag[i] = T_BLUE;
      break;
    case V_MAROON:
      itag[i] = T_MAROON;
      break;
    case V_BOLD:
      itag[i] = T_BOLD;
      break;
    case V_UNDERLINE:
      itag[i] = T_UNDERLINE;
      break;
    case V_ITALIC:
      itag[i] = T_ITALIC;
      break;
    default:
      fprintf(stderr, "Unknown RTF style: ignored\n");
      itag[i] = -1;
    }
  }
  return(itag);
}

int show_aa(int istr, TEM *temall, int jpos, html_style *style, int nt, int ns,
	    char aa, FILE *rtf) {
  int i;
  char assign;
  char isupper = 0;
  char islower = 0;
  char iscedilla = 0;

  for (i=0; i<ns; i++) {
    assign = temall[istr].feature[style[i+nt].feature].assign[jpos];
    if (assign == style[i+nt].value) {
      switch (style[i+nt].num) {
      case V_UPPER_CASE:
	isupper = 1;
	break;
      case V_LOWER_CASE:
	islower = 1;
	break;
      case V_CEDILLA:
	iscedilla = 1;
	break;
      default:
	fprintf(stderr, "Unknown RTF style: ignored\n");
	break;
      }
    }
  }
  
  if (iscedilla == 1 && islower == 1) {  /* Beware of the precedences! */
    fprintf(rtf, "{\\i0\\f2 \\'e7}");
  }
  else if (iscedilla == 1) {
    fprintf(rtf, "{\\f2 \\'c7}");
  }
  else if (islower == 1) {
    fprintf(rtf, "%c", tolower(aa));
  }
  else {
    fprintf(rtf, "%c", aa);
  }
  return (1);
}

int show_consensus(FILE *rtf, int strt, int end, char *conss,
		   int nchr) {
  int j;

  fprintf(rtf, "%-*s             ", nchr, dummy);
  fprintf(rtf, "{%s ",taglist[T_BLACK]);
  for (j=strt; j<end; j++) {
    fprintf(rtf, "%c", conss[j]);
  }
  fprintf(rtf, "}");
  fprintf(rtf, "\\line\n");
  return (1);
}


int write_rtfheader(FILE *rtf) {

  fprintf(rtf, "{\\rtf1\\ansi\\deff0\n");
  fprintf(rtf, "{\\fonttbl{\\f0\\fmodern Courier New;}{\\f1\\fnil\\fpreq2\\fcharset2 symbol;}");
  fprintf(rtf, "{\\f2\\fmodern\\fpreq1\\fcharset0 courier;}}\n");
  fprintf(rtf, "{\\colortbl\\red0\\green0\\blue0;\\red0\\green0\\blue255;\\red255\\green51\\blue102;\\red102\\green0\\blue18;}\n");
  fprintf(rtf, "{\\info{\\author JOY}}\n");

  fprintf(rtf, "\\paperw11880\\paperh16820\\margl1000\\margr500\n");
  fprintf(rtf, "\\margt910\\margb910\\sectd\\cols1\\pard\\plain\n");
  fprintf(rtf, "\\fs20\n");
  return (1);
}
