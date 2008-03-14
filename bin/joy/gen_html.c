/*
 *
 * $Id: gen_html.c,v 1.23 2003/03/25 11:52:02 kenji Exp $
 *
 * joy 5.0 release $Name:  $
 */
/****************************************************************************
* joy: A program for protein sequence-structure representation and analysis *
* Copyright (C) 1988-1997  John Overington                                  *
* Copyright (C) 1997-1999  Kenji Mizuguchi and Charlotte Deane              *
* Copyright (C) 1999-2000  Kenji Mizuguchi                                  *
*                                                                           *
* gen_html.c                                                                *
* Produces HTML output                                                      *
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
#include "analysis.h"
#include "rddom.h"

#define DEFAULT_DSSP 11   /* not an elegant solution, to be remembered! */

static char *taglist[] = {
  "black","silver","gray","white","maroon","red","purple","fuchsia",
  "green","lime","olive","yellow","navy","blue","teal","aqua",
  "bgblack","bgsilver","bggray","bgwhite","bgmaroon","bgred",
  "bgpurple","bgfuchsia","bggreen","bglime","bgolive","bgyellow",
  "bgnavy","bgblue","bgteal","bgaqua",
  "overline","linethrough","blink",
  "U","B","I"
};

static html_style tagged_style[] = {
  {11, 'H', V_RED, "red", "alpha helix"},
  {11, 'E', V_BLUE, "blue", "beta strand"},
  {11, 'G', V_MAROON, "maroon", "3 - 10 helix"},
  {3, 'T', V_BOLD, "bold", "hydrogen bond to main chain amide"},
  {2, 'T', V_UNDERLINE, "underline", "hydrogen bond to mainchain carbonyl"},
  {12, 'T', V_ITALIC, "italic", "positive phi"}
};

static int nt = 6;  /* number of different tags */
static int ns = 3;  /* number of features represented without using tags */

static html_style notag_style[] = {
  {1, 'F', V_UPPER_CASE, "UPPER CASE", "solvent inaccessible"},
  {1, 'T', V_LOWER_CASE, "lower case", "solvent accessible"},
  {8, 'T', V_CEDILLA, "cedilla", "disulphide bond"}
};

static char *dummy = "";

html_style default_style[] = {
  {1, 'F', V_UPPER_CASE, "UPPER CASE", "solvent inaccessible"},
  {1, 'T', V_LOWER_CASE, "lower case", "solvent accessible"},
  {11, 'H', V_RED, "red", "alpha helix"},
  {11, 'E', V_BLUE, "blue", "beta strand"},
  {11, 'G', V_MAROON, "maroon", "3 - 10 helix"},
  {3, 'T', V_BOLD, "bold", "hydrogen bond to main chain amide"},
  {2, 'T', V_UNDERLINE, "underline", "hydrogen bond to mainchain carbonyl"},
  {4, 'T', V_OVERLINE, "overline", "hydrogen bond to other sidechain"},
  {8, 'T', V_CEDILLA, "cedilla", "disulphide bond"},
  {12, 'T', V_ITALIC, "italic", "positive phi"},
  {7, 'T', V_BG_YELLOW, "background yellow", "covalent bond to heterogen"}
};

int nstyle = 11;

static char *domcolour[] = {"green", "yellow", "red", "blue", "pink", "black"};

static struct ColorScheme colorschemes[SCHEME_NUMBER]={
  {   /* CLUSTALX Colours */
    "clustalx",
    4,
    {-1,-1,-1,-1,-1, 2, 0, 1, 3,-1, 1, 3, 3,-1,-1, 0,-1, 1, 0, 0,-1, 3, 2,-1, 2,-1},
    /*  A  B  C  D  E  F  G  H  I  J  K  L  M  N  O  P  Q  R  S  T  U  V  W  X  Y  Z  */
    {"MYorange","MYred","MYblue","MYgreen"},
    /*    0        1     2       3       */
    {"orange","red","blue","green"}
    /*    0        1     2       3       */
  },
  {   /* Zappo Colours */
    "Zappo",
    7,
    { 0,-1, 6, 3, 3, 1, 5, 2, 0,-1, 2, 0, 0, 4,-1, 5, 4, 2, 4, 4,-1, 0, 1,-1, 1,-1},
    /*  A  B  C  D  E  F  G  H  I  J  K  L  M  N  O  P  Q  R  S  T  U  V  W  X  Y  Z  */
    {"MYpink","MYorange","MYred","MYgreen","MYmidblue","MYmagenta","MYyellow"},
    /*   0        1      2      3        4         5        6       */
    {"#FF6666","#FF9900","#CC0000","#33CC00","#3366FF","#CC33CC","#FFFF00"}
  },
  {   /* Taylor Colours */
    "Taylor",
    20,
    {18,-1,17,12,11, 3,15, 6, 1,17, 8, 2,19, 9,-1,16,10, 7,13,14,-1, 0, 5,-1, 4,-1},
    /*  A  B  C  D  E  F  G  H  I  J  K  L  M  N  O  P  Q  R  S  T  U  V  W  X  Y  Z  */
    {"MY1","MY2","MY3","MY4","MY5","MY6","MY7","MY8","MY9","MY10","MY11","MY12","MY13",
       "MY14","MY15","MY16","MY17","MY18","MY19","MY20"},
    {"#99FF00","#66FF00","#33FF00","#00FF66","#00FFCC","#00CCFF","#0066FF","#0000FF",
       "#6600FF","#CC00FF","#FF00CC","#FF0066","#FF0000","#FF3300","#FF6600",
       "#FF9900","#FFCC00","#FFFF00","#CCFF00","#00FF00"}
  }
};

static int ss[26]={ 2,-1,-1,-1, 1,-1,-1, 0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1};
                /*  A  B  C  D  E  F  G  H  I  J  K  L  M  N  O  P  Q  R  S  T  U  V  W  X  Y  Z  */
/*  A for clevage site */

static char sscolors[FG_NUMBER][20]={"red","blue","green"};
                                  /*   0      1      2       */

static char cs = 'A';    /* depend whether sequences are displayed in lowercase */

int gen_html(ALIFAM *alifam, char **str_code,
	     TEM *temall, PSA *psaall, int *lenseq, int ndom) {
  int nument;
  int nstr;
  int alilen;
  ALI *aliall;
  int scheme;      /* colour scheme for sequences */
  int i, j, k, l;
  int *pos;        /* index for the current residue position in each sequence  */
                   /* starts from non-zero values when segment is used         */
  int *strtpos = NULL;  /* index for the inital residut position in each structure entry */
  int *endpos = NULL;   /* index for the last residut position in each structure entry */
  html_style *style;
  int ib, strt, end;
  int nwidth;      /* width of alignment */
  int nchr;        /* width of protein codes */
  char seq;
  char *html_filename;
  FILE *html;
  int *itag;       /* to link the structure style and the array taglist */
  int it;
  TagAll *alltag = NULL;
  Tag *tg;
  char *conss = NULL;    /* consensus secondary structure */
  int *domassign = NULL; /* domain assignment */
  int **labels = NULL;   /* store referring str and seq numbers for each label */
  int nl = 0;      /* number of label entries */
  int lstr = -1;
  int lseq = -1;
  int inum;
  int s;
  
  aliall = alifam->ali;
  nument = alifam->nument;
  alilen = alifam->alilen;
  nstr =   alifam->nstr;

  html_filename = mstrcat(alifam->code, HTML_SUFFIX);
  html = fopen(html_filename, "w");
  if (html == NULL) {
    fprintf(stderr, "Cannot open %s\n", html_filename);
    return (-1);
  }

  if (! alifam->family) {
    alifam->family = get_keywd(alifam->comment, FAMILY);
  }

  if (!(style = set_default(tagged_style, notag_style, nt, ns))) {
    fprintf(stderr, "Error in assigning the HTML typesetting code\n");
    fprintf(stderr, "(no HTML output)\n");
    fclose(html);
    remove(html_filename);
    return (-1);
  }

  itag = set_tag_html(style, nt);

/* defining conseneus secondary structures */

  if (VI(V_CONSENSUS_SS) && (strcmp(VS(V_FEATURE_SET), "default") == 0) &&
      nstr > 0) {
    conss = consensus_ss(alifam, nstr, str_code, temall, DEFAULT_DSSP);

    /* currently consensus SS is shown only when the default feature set is selected */
  }
  if (ndom > 0) domassign = domain_display(ndom, alifam->alilen);

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

  scheme = write_htmlheader(html, style, ndom, alifam->family);

  ib = 0;
  while (1) {
    strt = nwidth * ib;
    if (strt >= alilen) break;

    end = strt + nwidth;
    if (end >= alilen) end = alilen;

    k = 0;

/* output alignment posisition */
    if (VI(V_ALIGNMENT_POS)) write_alignpos(html, nchr, strt, end);

/* domain assignment */
    if (ndom > 0) write_dom(html, nchr, strt, end, domassign);

    for (i=0;i<nument; i++) {

/* protein codes and sequence numbers */

      if (aliall[i].type == LABEL) {
	fprintf(html, "%-*s             ", nchr, dummy);
      }
      else if (aliall[i].type == STRUCTURE && pos[i] < endpos[k]) {
	show_substr(aliall[i].code, nchr, html);
	fprintf(html, "  (%5s)    ", psaall[k].resnum[pos[i]]);
/*	fprintf(html, "%-*s  (%5s)    ", nchr, aliall[i].code, psaall[k].resnum[pos[i]]); */
      }
      else if (aliall[i].type == STRUCTURE && pos[i] >= endpos[k]) {
	show_substr(aliall[i].code, nchr, html);
	fprintf(html, "             ");
      }
      else if (aliall[i].type == SEQUENCE) {
	fprintf(html, "%s%s>", FONT_FG_BEGIN, COLOUR_SEQTITLE);
	show_substr(aliall[i].code, nchr, html);
	fprintf(html, "             ");
/*	fprintf(html, "%-*s             ", nchr, aliall[i].code); */
	fprintf(html, FONT_END);
      }
      else if (aliall[i].type == TEXT && strcmp(aliall[i].title, SS) == 0) { /* text entry (secondary structure) */
	fprintf(html, "%s%s>", FONT_FG_BEGIN, COLOUR_SSTITLE);
	show_substr(aliall[i].code, nchr, html);
	fprintf(html, "             ");
	fprintf(html, FONT_END);
      }
      else {
	show_substr(aliall[i].code, nchr, html);
	fprintf(html, "             ");
      }

/* amino acids */

      if (aliall[i].type == STRUCTURE) { /* structure entry */

	tg = alltag[k].tags;

	for (j=strt; j<end; j++) {
	  seq = aliall[i].sequence[j];

	  if ((pos[i] <= strtpos[k] && seq == '-') ||
	      pos[i] >= endpos[k] ||  /* edge gaps not shown */
	      seq == '/') {
	    fprintf(html, " ");
	  }
	  else if (seq == '-') {
	    if (isBreak(aliall[i].sequence+j, j)) {
	      fprintf(html, " ");
	    }
	    else {
	      fprintf(html, "-");
	    }
	  }
	  else {
	    for (l=0; l<tg[j].nb; l++) { /* check if any tag begins at this position */
	      it = tg[j].begin[l];
	      if (itag[it] <= V_AQUA) {
		fprintf(html, "<FONT color=%s>", taglist[itag[it]]);
	      }
	      else if (itag[it] <= V_BG_AQUA + 2) {
		fprintf(html, "<FONT CLASS=%s>", taglist[itag[it]]);
	      }
	      else {
		fprintf(html, "<%s>", taglist[itag[it]]);
	      }
	    }

	    if (show_aa_in_html(k, temall, j, style, nt, ns,
				aliall[i].sequence[j], html) != 0) {
	      /* check features that are represented 
		 without using tags and display amino acid*/

	      fprintf(stderr, "pos %d in %s\n", j+1, aliall[i].code);
	    }

	    for (l=0; l<tg[j].ne; l++) { /* check if any tag ends at this position */
	      it = tg[j].end[l];
	      if (itag[it] <= V_BG_AQUA + 2) {
		fprintf(html, "</FONT>");
	      }
	      else {
		fprintf(html, "</%s>", taglist[itag[it]]);
	      }
	    }

	    pos[i]++;
	  }
	}
	k++;
      }
      else if (aliall[i].type == SEQUENCE && scheme == -1) { /* sequence entry (B&W)*/
	for (j=strt; j<end; j++) {
	  if (aliall[i].sequence[j] == '/') {
	    fprintf(html, " ");
	  }
	  else if (aliall[i].sequence[j] == '-') {
	    if (isBreak(aliall[i].sequence+j, j)) {
	      fprintf(html, " ");
	    }
	    else {
	      fprintf(html, "-");
	    }
	  }
	  else {      /* edge gaps sill shown, can be modified when an elegant solution found */
	    fprintf(html, "%c", aliall[i].sequence[j]);
	  }
	}
      }	
      else if (aliall[i].type == SEQUENCE) { /* sequence entry (colour)*/
	for (j=strt; j<end; j++) {
	  if (aliall[i].sequence[j] == '/') {
	    fprintf(html, " ");
	  }
	  else if (aliall[i].sequence[j] == '-') {
	    if (isBreak(aliall[i].sequence+j, j)) {
	      fprintf(html, " ");
	    }
	    else {
	      fprintf(html, "-");
	    }
	  }
	  else {                              /* edge gaps sill shown, can be modified when an elegant solution found */
	    colour_seq(aliall[i].sequence[j], scheme, html);
	  }
	}
      }	
      else if (aliall[i].type == TEXT && strcmp(aliall[i].title, SS) == 0) { /* text entry (secondary structure) */
	for (j=strt; j<end; j++) {
	  if (aliall[i].sequence[j] == SPACE_CHAR) {
	    fprintf(html, " ");
	  }
	  else if (aliall[i].sequence[j] == '-') {
	    fprintf(html, "-");
	  }
	  else {                              /* edge gaps sill shown, can be modified when an elegant solution found */
	    colour_ss(aliall[i].sequence[j], html);
	  }
	}
      }
      else if (aliall[i].type == TEXT) { /* text entry (other) */
	for (j=strt; j<end; j++) {
	  if (aliall[i].sequence[j] == SPACE_CHAR) {
	    fprintf(html, " ");
	  }
	  else {
	    fprintf(html, "%c", aliall[i].sequence[j]);
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
	  fprintf(html, "\n");
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
	      fprintf(html, "%-*s%d", s, dummy, inum);
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
	fprintf(html, "\n");
      }
      fprintf(html, "\n");
    }

    if (VI(V_CONSENSUS_SS) && conss) { /* consensus secondary structure */
      fprintf(html, "%-*s             ", nchr, dummy);
      for (j=strt; j<end; j++) {
	fprintf(html, "%c", conss[j]);
      }
      fprintf(html, "\n");
    }

    fprintf(html, "\n");
    ib++;
  }

  fprintf(html, "</PRE>\n");

  if (VI(V_KEY)) {
    write_key(style, ndom, html);
  }

  fprintf(html, "</BODY>\n");
  fprintf(html, "</HTML>\n");

  fclose(html);

  free(pos);
  if (strtpos) {
    free(strtpos);
  }
  if (endpos) {
    free(endpos);
  }
  free(html_filename);
  free(style);
  free(itag);
  if (nl > 0) {
    free(labels[0]);
    free(labels);
  }

  return (0);
}

int *set_tag_html(html_style *style, int nt) {
  int i;
  int *itag;

  itag = ivector(nt);

  for (i=0; i<nt; i++) {
    if (style[i].num <= V_BG_AQUA) {  /* font colour */
      itag[i] = style[i].num;
    }
    else if (style[i].num == V_OVERLINE) {
      itag[i] = V_BG_AQUA + 1;
    }
    else if (style[i].num == V_LINE_THROUGH) {
      itag[i] = V_BG_AQUA + 2;
    }
    else if (style[i].num == V_BLINK) {
      itag[i] = V_BG_AQUA + 3;
    }
    else if (style[i].num == V_UNDERLINE) {
      itag[i] = V_BG_AQUA + 4;
    }
    else if (style[i].num == V_BOLD) {
      itag[i] = V_BG_AQUA + 5;
    }
    else if (style[i].num == V_ITALIC) {
      itag[i] = V_BG_AQUA + 6;
    }
    else {
      fprintf(stderr, "Unknown HTML style: ignored\n");
      itag[i] = -1;
    }
  }
  return(itag);
}

/* determine the width of the sequence names */
int code_width (int nument, ALI *aliall) {
  int i;
  int n, nw;

  nw = -1;
  for (i=0; i<nument; i++) {
    if (aliall[i].type == LABEL) continue;
    n = strlen(aliall[i].code);
    if (nw < n) nw = n;
  }
  if (nw < 0) nw = 8;

  if (VI(V_MAXCODELEN) > 0 && VI(V_MAXCODELEN) < nw) {
    nw = VI(V_MAXCODELEN);
  }
  return nw;
}

html_style *set_style(TEM *temall) {
  int i, j;
  int k = 0;
  html_style *style;

  if (access("joytypeset", R_OK) == 0) { /* config file found */
    read_conf("joytypeset");
    fprintf(stderr, "%d styles read in\n", nlines);
    style = (html_style *)malloc((size_t) (nlines * sizeof(html_style)));
    if (style == NULL) {
      fprintf(stderr, "Error: out of memory\n");
      exit(-1);
    }
    for (i=0; i<temall[0].nfeature; i++) {
      for (j=0; j<nlines; j++) {
	if (strcmp(Conf[j].feature, temall[0].feature[i].name) == 0) {
	  style[j].feature = i;
	  style[j].value = Conf[j].value;
	  style[j].num = Conf[j].style;
	  style[j].name = strdup(Conf[j].name);
	  style[j].description = strdup(Conf[j].description);
	  k++;
	}
	if (k == nlines) break;
      }
      if (k == nlines) break;
    }
    nstyle = nlines;
  }
  else {
    style = (html_style *)malloc((size_t) (nstyle * sizeof(html_style)));
    if (style == NULL) {
      fprintf(stderr, "Error: out of memory\n");
      exit(-1);
    }
    if (strcmp(VS(V_FEATURE_SET), "default") != 0) {
      fprintf(stderr, "Error: inconsistency between .tem and .html files\n");
      fprintf(stderr, "       A non-default feature set has been specified, but the\n");
      fprintf(stderr, "       HTML typesetting code is for the default feature set.\n");
      fprintf(stderr, "       You must supply your own joytypeset file.\n");
      return NULL;
    }
    for (i=0; i<nstyle; i++) {
      style[i].feature = default_style[i].feature;
      style[i].value = default_style[i].value;
      style[i].num = default_style[i].num;
      style[i].name = strdup(default_style[i].name);
      style[i].description = strdup(default_style[i].description);
    }
  }
  return style;
}

int write_key(html_style *style, int ndom, FILE *fp) {
/*  int i;
  int nw;
  char *s1, *s2; */

  fprintf(fp, "<table width=60%% cellpadding=3 cellborder=0>\n");
  fprintf(fp, "<tr><th colspan=3 align=center bgcolor=lightblue>Key to JOY</th></tr>\n");
  fprintf(fp, "<tr><td>solvent inaccessible</td><td>UPPER CASE</td><td><tt>X</tt></td>\n");
  fprintf(fp, "<tr><td>solvent accessible</td><td>lower case</td><td><tt>x</tt></td>\n");
  fprintf(fp, "<tr><td>alpha helix</td><td><font color=red>red</font></td><td><tt><font color=red>x</font></tt></td>\n");
  fprintf(fp, "<tr><td>beta strand</td><td><font color=blue>blue</font></td><td><tt><font color=blue>x</font></tt></td>\n");
  fprintf(fp, "<tr><td>3<sub>10</sub> helix</td><td><font color=maroon>maroon</font></td><td><tt><font color=maroon>x</font></tt></td>\n");
  fprintf(fp, "<tr><td>hydrogen bond to main chain amide</td><td><B>bold</b></td><td><tt><b>x</b></tt></td>\n");
  fprintf(fp, "<tr><td>hydrogen bond to main chain carbonyl</td><td><u>underline</u></td><td><tt><u>x</u></tt></td>\n");
  fprintf(fp, "<tr><td>disulphide bond</td><td>cedilla</td><td><tt>&ccedil;</tt></td>\n");
  fprintf(fp, "<tr><td>positive phi</td><td><I>italic</i></td><td><tt><i>x</I></tt></td>\n");
  fprintf(fp, "</table>\n");

/*
  for (i=0; i<nstyle; i++) {
    if (style[i].num == V_CEDILLA) {
      s1 = strdup(style[i].name);
      s2 = generate_tag("c", style[i].num);

    }
    else if (style[i].num == V_UPPER_CASE) {
      s1 = strdup(style[i].name);
      s2 = generate_tag("X", style[i].num);
    }
    else {
      s1 = generate_tag(style[i].name, style[i].num);
      s2 = generate_tag("x", style[i].num);
    }
    
    nw = strlen(s1) - strlen(style[i].name) + 18;
    fprintf(fp, "%-*s %-*s %s\n", 39, style[i].description,
	    nw, s1, s2);
  }

  if (ndom > 0) fprintf(fp, "\n");
  for (i=0; i<ndom; i++) {
    fprintf(fp, "domain %-33d<FONT CLASS=domain%-d>     </FONT>\n",
	    i+1, i+1);
  }

  fprintf(fp, "</PRE>\n");
  */
  return (1);
}


int get_label_strnum(int nstr, char **str_code, char *code) {
  int i;
  for (i=0; i<nstr; i++) {
    if (strcmp(str_code[i], code) == 0) {
      return i;
    }
  }
  return -1;
}

int get_label_seqnum(int nument, ALI *aliall, char *code) {
  int i;
  for (i=0; i<nument; i++) {
    if (strcmp(aliall[i].code, code) == 0 && aliall[i].type == STRUCTURE) {
      return i;
    }
  }
  return -1;
}

char *consensus_ss(ALIFAM *alifam, int nstr, char **str_code,
		   TEM *temall, int ifeature) {
  int alilen;
  ALI *aliall;
  int nument;
  int i, j, k;
  char *sse;
  char *consensus;

  aliall = alifam->ali;
  alilen = alifam->alilen;
  nument = alifam->nument;

  sse = cvector(nstr);
  consensus = cvector(alilen+1);

  for (i=0; i<alilen; i++) {
    k = -1;

    for (j=0; j<nument; j++) {
      if (aliall[j].type != STRUCTURE) continue;
      k++;
      sse[k] = temall[k].feature[ifeature].assign[i];
    }
    if (consen(nstr, sse, 'H', 0.7) == 1) {
      consensus[i] = 'a';
    }
    else if (consen(nstr, sse, 'E', 0.7) == 1) {
      consensus[i] = 'b';
    }
    else if (consen(nstr, sse, 'G', 0.7) == 1) {
      consensus[i] = '3';
    }
    else {
      consensus[i] = ' ';
    }
  }
  consensus[alilen] = '\0';
  free(sse);
  return consensus;
}

int write_htmlheader(FILE *html, html_style *style, int ndom, char *famname) {
  int scheme;

  fprintf(html, "<HTML>\n");
  fprintf(html, "<STYLE TYPE=\"text/css\">\n");
  fprintf(html, "<!--\n");
  if (strcmp(VS(V_FONTSIZE), "-") != 0)  {
    fprintf(html, "H3 { font-family: serif; font-size: %s}\n", VS(V_FONTSIZE));
    fprintf(html, "PRE { font-family: monospace; font-size: %s}\n", VS(V_FONTSIZE));
  }
  define_bgcolour(style, html);
  scheme = define_bgcolour_for_seq(html);
  define_text_decoration(style, html);
  define_domcolour(html, ndom);

  fprintf(html, "-->\n");
  fprintf(html, "</STYLE>\n");

  if (famname) {
    fprintf(html, "<TITLE>%s</TITLE>\n",famname);
  }

  fprintf(html, "<META HTTP-EQUIV=\"Content-Type\" CONTENT=\"text/html; charset=ISO-8859-1\">\n");

  if (strcmp(VS(V_BGCOLOR), "-") != 0)  {
    fprintf(html, "<BODY BGCOLOR=%s>\n", VS(V_BGCOLOR));
  }
  else {
    fprintf(html, "<BODY BGCOLOR=white>\n");
  }

  if (famname) {
    fprintf(html, "<H3>%s</H3>\n", famname);
  }
  fprintf(html, "<PRE>\n");

  return scheme;
}

int *domain_display(int ndom, int alilen) {

  int i, j, k;
  int *domassign;

  domassign = ivector(alilen);
  initialize_ivec(alilen, domassign, 0);

  for (i=0; i<ndom; i++) {
    for (j=1; j<=dom[i].segno; j++) {
      domassign[dom[i].seg[j].startno-1] = i + 1 + 100;
      for (k = dom[i].seg[j].startno; k < dom[i].seg[j].endno-1; k++) {
	domassign[k] = i + 1;
      }
      domassign[dom[i].seg[j].endno-1] = i + 1 + 200;
    }
  }
  return domassign;
}

int define_domcolour(FILE *fp, int ndom) {
  int i;

  if (ndom <= 0) return -1;
  for (i=0; i<ndom; i++) {
    fprintf(fp, "FONT.domain%-d {background: %s}\n", i+1, domcolour[i]);
  }
  return 0;
}

int define_bgcolour(html_style *style, FILE *fp) {
  int i;
  for (i=0; i<nstyle; i++) {
    switch (style[i].num) {
    case V_BG_BLACK:
      fprintf(fp, "FONT.bgblack {background: black }\n");
      continue;
    case V_BG_SILVER:
      fprintf(fp, "FONT.bgsliver {background: sliver }\n");
      continue;
    case V_BG_GRAY:
      fprintf(fp, "FONT.bggray {background: gray }\n");
      continue;
    case V_BG_WHITE:
      fprintf(fp, "FONT.bgwhite {background: white }\n");
      continue;
    case V_BG_MAROON:
      fprintf(fp, "FONT.bgmaroon {background: maroon }\n");
      continue;
    case V_BG_RED:
      fprintf(fp, "FONT.bgred {background: red }\n");
      continue;
    case V_BG_PURPLE:
      fprintf(fp, "FONT.bgpurple {background: purple }\n");
      continue;
    case V_BG_FUCHSIA:
      fprintf(fp, "FONT.bgfuchsia {background: fuchsia }\n");
      continue;
    case V_BG_GREEN:
      fprintf(fp, "FONT.bggreen {background: green }\n");
      continue;
    case V_BG_LIME:
      fprintf(fp, "FONT.bglime {background: lime }\n");
      continue;
    case V_BG_OLIVE:
      fprintf(fp, "FONT.bgolive {background: olive }\n");
      continue;
    case V_BG_YELLOW:
      fprintf(fp, "FONT.bgyellow {background: yellow }\n");
      continue;
    case V_BG_NAVY:
      fprintf(fp, "FONT.bgnavy {background: navy }\n");
      continue;
    case V_BG_BLUE:
      fprintf(fp, "FONT.bgblue {background: blue }\n");
      continue;
    case V_BG_TEAL:
      fprintf(fp, "FONT.bgteal {background: teal }\n");
      continue;
    case V_BG_AQUA:
      fprintf(fp, "FONT.bgaqua {background: aqua }\n");
      continue;
    default:
      continue;
    }
  }
  return 0;
}

int define_bgcolour_for_seq(FILE *fp) {
  int i;
  int scheme;
  
  if (VI(V_SEQCOLOUR) == 0) return -1;

  if (VI(V_SEQCOLOUR) < 0 || VI(V_SEQCOLOUR) > SCHEME_NUMBER) {
    fprintf(stderr,"Warning: unknown colour scheme for sequences: %ld\n", VI(V_SEQCOLOUR));
    fprintf(stderr, "Use black and white\n");
    fprintf(stderr, "(available colours: ");
    for (i=0; i<SCHEME_NUMBER; i++) {
      fprintf(stderr, " (%d) %s", i, colorschemes[i].name);
    }
    fprintf(stderr, ")\n");
    return -1;
  }
  scheme = VI(V_SEQCOLOUR)-1;

  fprintf(stderr, "Colour scheme for sequences: %s\n", colorschemes[scheme].name);
  if (VI(V_LC)) cs = 'a';   /* if displayed in lowercase, start from 'a'
			       rather than 'A' */

  for (i=0; i<colorschemes[scheme].bg_number; i++) {
    fprintf(fp, "FONT.bg%s {background: %s }\n",colorschemes[scheme].colorname[i],
	    colorschemes[scheme].colors[i]);
  }
  return scheme;
}

int define_text_decoration(html_style *style, FILE *fp) {
  int i;
  for (i=0; i<nstyle; i++) {
    switch (style[i].num) {
    case V_OVERLINE:
      fprintf(fp, "FONT.overline {text-decoration: overline }\n");
      continue;
    case V_LINE_THROUGH:
      fprintf(fp, "FONT.linethrough {text-decoration: linethrough }\n");
      continue;
    default:
      continue;
    }
  }
  return 0;
}

int write_dom(FILE *html, int nchr, int strt, int end,
	      int *domassign) {
  char *dummy = "";
  int j;

  fprintf(html, "%-*s             ", nchr, dummy);

  if (domassign[strt] > 200) {
    fprintf(html, "<FONT CLASS=domain%-d> ", domassign[strt]-200);
    fprintf(html, "</FONT>");
  }
  else if (domassign[strt] > 100) {
    fprintf(html, "<FONT CLASS=domain%-d> ", domassign[strt]-100);
  }
  else if (domassign[strt] > 0) {
    fprintf(html, "<FONT CLASS=domain%-d> ", domassign[strt]);
  }
  else {
    fprintf(html, " ");
  }

  for (j=strt+1; j<end-1; j++) {
    if (domassign[j] > 200) {
      fprintf(html, " </FONT>");
    }
    else if (domassign[j] >100) {
      fprintf(html, "<FONT CLASS=domain%-d> ", domassign[j]-100);
    }
    else {
      fprintf(html, " ");
    }
  }

  if (end - 1 <= strt) {
    fprintf(html, "\n");
    return 0;
  }

  if (domassign[end-1] > 100 && domassign[end-1] < 200) {
    fprintf(html, "<FONT CLASS=domain%-d> ", domassign[end-1]-100);
    fprintf(html, "</FONT>");
  }
  else if (domassign[end-1] > 0) {
    fprintf(html, " </FONT>");
  }
  else {
    fprintf(html, " ");
  }

  fprintf(html, "\n");
  return 0;
}

int write_alignpos(FILE *html, int nchr, int strt, int end) {

  char *dummy = "";
  int j;

  fprintf(html, "%-*s             ", nchr, dummy);

  j = strt;
  while (j < end) {
    if ((j+1) % 10 == 0) {
      fprintf(html, "%-4d", j+1);
      j += 4;
      continue;
    }
    fprintf(html, " ");
    j++;
  }
  fprintf(html, "\n");

  return 0;
}

int show_aa_in_html(int istr, TEM *temall, int jpos, 
		    html_style *style, int nt, int ns,
		    char aa, FILE *html) {
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
	fprintf(stderr, "Unknown HTML style: ignored\n");
	break;
      }
    }
  }
  
  if (iscedilla == 1 && islower == 1) {  /* Beware of the precedences! */

    if (aa != 'C' && aa != 'c') {
      fprintf(stderr, "Error: cedilla assigned for non-cysteine residue ");
      fprintf(stderr, "%c\n", aa);
      fprintf(stderr, "Something is wrong!\n");
      fprintf(html, "%c", aa);
      return (-1);
    }
    else {
      fprintf(html, "&ccedil;");
    }
  }
  else if (iscedilla == 1) {
    fprintf(html, "&Ccedil;");
  }
  else if (islower == 1) {
    fprintf(html, "%c", tolower(aa));
  }
  else {
    fprintf(html, "%c", aa);
  }
  return (0);
}

void colour_seq(char aa, int scheme, FILE *fp) {
  int colorcode;

  colorcode = colorschemes[scheme].residue[aa-cs];
  if (colorcode >= 0) {
    fprintf(fp, "<FONT CLASS=bg%s>%c</FONT>",
	    colorschemes[scheme].colorname[colorcode], aa);
  }
  else {
    fprintf(fp, "%c",aa);
  }
}

int colour_ss(char s, FILE *fp) {
  int colorcode;

  colorcode=ss[s-cs];
  if(colorcode < 0) {
    putchar(s);
    return (0);
  }
  fprintf(fp, "%s%s>%c%s",FONT_FG_BEGIN, sscolors[colorcode],
	  s, FONT_END);
  return (1);
}

char isBreak(char *seq, int n) {
  char *s;
  s = seq;

  while (n >= 0) {
    if (*s != '-') break;
    s--;
    n--;
  }
  if (*s == '/') return 1;
  return 0;
}

int show_substr(char *code, int n, FILE *fp) {
  int i=0;
  char *s;
  s = code;

  while (i<n) {
    if (*s == '\0') break;
    fprintf(fp, "%c", *s);
    i++;
    s++;
  }
  while (i<n) {
    fprintf(fp, " ");
    i++;
  }
  return 0;
}
