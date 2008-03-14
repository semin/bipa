/*
 *
 * $Id: gen_ps.c,v 1.21 2003/03/25 11:52:02 kenji Exp $
 *
 * joy 5.0 release $Name:  $
 */
/****************************************************************************
* joy: A program for protein sequence-structure representation and analysis *
* Copyright (C) 1988-1997  John Overington                                  *
* Copyright (C) 1997-1999  Kenji Mizuguchi and Charlotte Deane              *
* Copyright (C) 1999-2000  Kenji Mizuguchi                                  *
*                                                                           *
* gen_ps.c                                                                  *
* Produces PostScript output                                                *
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
#include "afm.h"
#include "gen_html.h"
#include "gen_ps.h"
#include "analysis.h"
#include "rddom.h"

#define DEFAULT_DSSP 11   /* not an elegant solution, to be remembered! */

static char *colourCom[] = {
  "0.0 0.0 0.0 setrgbcolor", /* black */
  "-", /* silver */
  "-", /* gray   */
  "-", /* white  */
  "0.4 0.0 0.007 setrgbcolor", /* maroon */
  "1.0 0.0 0.0 setrgbcolor",   /* red    */
  "-", /* purple */
  "-", /* fuchsia */
  "-", /* green   */
  "-", /* lime   */
  "-", /* olive  */
  "-", /* yellow */
  "-", /* navy   */
  "0.0 1.0 1.0 setrgbcolor", /* blue */
  "-", /* teal   */
  "-", /* aqua */
};

static char *fontName[] = {
  "/Times-Roman",
  "/Times-Bold",
  "/Times-Italic",
  "/Times-BoldItalic",
  "/Courier",
  "/Courier-Bold",
  "/Courier-Oblique",
  "/Courier-BoldOblique",
  "/Helvetica",
  "/Helvetica-Bold",
  "/Helvetica-Oblique",
  "/Helvetica-BoldOblique",
  "/Symbol"
};

static html_style colour_style[] = {
  {11, 'H', V_RED, "red", "alpha helix"},
  {11, 'E', V_BLUE, "blue", "beta strand"},
  {11, 'G', V_MAROON, "maroon", "3 - 10 helix"}
};
static html_style font_style[] = {
  {3, 'T', V_BOLD, "bold", "hydrogen bond to main chain amide"},
  {12, 'T', V_ITALIC, "italic", "positive phi"}
};

static int nc = 3;  /* number of colours */
static int nf = 2;  /* number of fonts */
static int ns = 6;  /* number of features represented other ways */

static html_style notag_style[] = {
  {1, 'F', V_UPPER_CASE, "UPPER CASE", "solvent inaccessible"},
  {1, 'T', V_LOWER_CASE, "lower case", "solvent accessible"},
  {8, 'T', V_CEDILLA, "cedilla", "disulphide bond"},
  {2, 'T', V_UNDERLINE, "underline", "hydrogen bond to mainchain carbonyl"},
  {4, 'T', V_TILDE, "tilde", "hydrogen bond to other sidechain/heterogen"},
  {5, 'T', V_BREVE, "breve", "cis-peptide"}
};

static char *domcolour[] = {"green", "yellow", "red", "blue", "pink", "black"};

static struct ColorScheme colorschemes[SCHEME_NUMBER]={
  {   /* CLUSTALX Colours */
    "clustalx",
    4,
    {-1,-1,-1,-1,-1, 2, 0, 1, 3,-1, 1, 3, 3,-1,-1, 0,-1, 1, 0, 0,-1, 3, 2,-1, 2,-1},
    /*  A  B  C  D  E  F  G  H  I  J  K  L  M  N  O  P  Q  R  S  T  U  V  W  X  Y  Z  */
    {"MYorange","MYred","MYblue","MYgreen"},
    /*    0        1     2       3       */
    {"1.0 0.4 0.0", "1.0 0.0 0.0", "0.0 0.0 1.0", "0.0 1.0 0.0"}
    /*    0        1     2       3       */
  },
  {   /* Zappo Colours */
    "Zappo",
    7,
    { 0,-1, 6, 3, 3, 1, 5, 2, 0,-1, 2, 0, 0, 4,-1, 5, 4, 2, 4, 4,-1, 0, 1,-1, 1,-1},
    /*  A  B  C  D  E  F  G  H  I  J  K  L  M  N  O  P  Q  R  S  T  U  V  W  X  Y  Z  */
    {"MYpink","MYorange","MYred","MYgreen","MYmidblue","MYmagenta","MYyellow"},
    /*   0        1      2      3        4         5        6       */
    {"1.0 0.4 0.4","1.0 0.6 0.0","0.8 0.0 0.0","0.2 0.8 0.0","0.1 0.4 1.0","0.8 0.2 0.8","1.0 1.0 0.0"}
  },
  {   /* Taylor Colours */
    "Taylor",
    20,
    {18,-1,17,12,11, 3,15, 6, 1,17, 8, 2,19, 9,-1,16,10, 7,13,14,-1, 0, 5,-1, 4,-1},
  /*  A  B  C  D  E  F  G  H  I  J  K  L  M  N  O  P  Q  R  S  T  U  V  W  X  Y  Z  */
    {"MY1","MY2","MY3","MY4","MY5","MY6","MY7","MY8","MY9","MY10","MY11","MY12","MY13",
       "MY14","MY15","MY16","MY17","MY18","MY19","MY20"},
    {"0.6 1.0 0.0", "0.4 1.0 0.0", "0.2 1.0 0.0", "0.0 1.0 0.4", "0.0 1.0 0.8",
       "0.0 0.8 1.0","0.0 0.4 1.0","0.0 0.0 1.0","0.4 0.0 1.0","0.8 0.0 1.0",
       "1.0 0.0 0.8", "1.0 0.0 0.4", "1.0 0.0 0.0", "1.0 0.2 0.0", "1.0 0.4 0.0",
       "1.0 0.6 0.0", "1.0 0.8 0.0", "1.0 1.0 0.0", "0.8 1.0 0.0", "0.0 1.0 0.0"}
  }
};

static int ss[26]={ 2,-1,-1,-1, 1,-1,-1, 0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1};
                /*  A  B  C  D  E  F  G  H  I  J  K  L  M  N  O  P  Q  R  S  T  U  V  W  X  Y  Z  */
/*  A for clevage site */

static char sscolors[FG_NUMBER][20]={"red","blue","green"};
                                  /*   0      1      2       */
static char cs = 'A';    /* depend whether sequences are displayed in lowercase */

static int current_font;

int gen_ps(ALIFAM *alifam, char **str_code,
	   TEM *temall, PSA *psaall, int *lenseq, int ndom) {
  int nument;
  int nstr;
  int alilen;
  ALI *aliall;
  int scheme;      /* colour scheme for sequences */
  int i, j, k;
  int *pos;        /* index for the current residue position in each sequence  */
                   /* starts from non-zero values when segment is used         */
  int *strtpos = NULL;   /* index for the inital residut position in each structure entry */
  int *endpos = NULL;    /* index for the last residut position in each structure entry */
  int ib, strt, end;
  int nb;          /* number of alignment blocks per page */
  int np;          /* number of pages */
  int ip;
  int font = 0;
  float x, y;
  float dx, dy;
  float harea;     /* hight of the region in a page where alignment is shown */
  int nwidth;      /* width of alignment in characters */
  int nchr;        /* width of protein codes */
  char *ps_filename;
  FILE *ps;
  unsigned char **fflgs = NULL;    /* used to specify fonts for each character */
  unsigned char **cflgs = NULL;    /* used to specify colours for each character */
  char *conss = NULL;   /* consensus secondary structure */
  int **labels = NULL;  /* store referring str and seq numbers for each label */
  int nl = 0;      /* number of label entries */
  int lstr = -1;
  int lseq = -1;
  int inum;
  float sw;
  float xp;
  char str[6];
  char *ic = NULL;  /* insertion code */
  int jl = 0;
  
  aliall = alifam->ali;
  nument = alifam->nument;
  alilen = alifam->alilen;
  nstr =   alifam->nstr;

  current_font = changeFont();

  if (strcmp(VS(V_FONTSIZE), "-") != 0) { /* font size specified */
    fontsize = atof(VS(V_FONTSIZE));
    name_width *= (fontsize * 0.1); /* default fontsize = 10 */
    num_width *= (fontsize * 0.1);
    label_fontsize = fontsize * 0.8;
  }
  if (strcmp(VS(V_SEQFONTSIZE), "-") != 0)
    seq_fontsize = atof(VS(V_SEQFONTSIZE));

  nwidth = alignment_width();

/* determine the width of the sequence names */
  if (VI(V_MAXCODELEN) > 0) {
    nchr = VI(V_MAXCODELEN);
  }
  else {
    nchr = 256;
  }

  ps_filename = mstrcat(alifam->code, PS_SUFFIX);
  ps = fopen(ps_filename, "w");
  if (ps == NULL) {
    fprintf(stderr, "Cannot open %s\n", ps_filename);
    return (-1);
  }

  if (strcmp(VS(V_FEATURE_SET), "default") != 0) {
    fprintf(stderr, "Error: inconsistency between .tem and .ps files\n");
    fprintf(stderr, "       A non-default feature set has been specified, but the\n");
    fprintf(stderr, "       PS typesetting code is for the default feature set.\n");
    fprintf(stderr, "       You must supply your own joytypeset file.\n");
    fclose(ps);
    remove(ps_filename);
    return (-1);
  }

  if (! alifam->family) {
    alifam->family = get_keywd(alifam->comment, FAMILY);
  }

  /* colour scheme for sequence */
  if (VI(V_SEQCOLOUR) == 0) {
    scheme = -1;
  }
  else if (VI(V_SEQCOLOUR) < 0 || VI(V_SEQCOLOUR) > SCHEME_NUMBER) {
    fprintf(stderr,"Warning: unknown colour scheme for sequences: %ld\n", VI(V_SEQCOLOUR));
    fprintf(stderr, "Use black and white\n");
    fprintf(stderr, "(available colours: ");
    for (i=0; i<SCHEME_NUMBER; i++) {
      fprintf(stderr, " (%d) %s", i, colorschemes[i].name);
    }
    fprintf(stderr, ")\n");
    scheme =  -1;
  }
  else {
    scheme = VI(V_SEQCOLOUR)-1;
    fprintf(stderr, "Colour scheme for sequences: %s\n", colorschemes[scheme].name);
  }
  if (VI(V_LC)) cs = 'a';   /* if displayed in lowercase, start from 'a'
			       rather than 'A' */

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
    ic = cvector(nl);

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
    fflgs = ucmatrix(nstr, alilen);
    cflgs = ucmatrix(nstr, alilen);
  }

  for (i=0; i<nstr; i++) {
    assignFonts(nf, font_style, alilen, i,
		temall, fflgs, nwidth);
    assignColours(nc, colour_style, alilen, i,
		  temall, cflgs, nwidth);
  }

  harea = (float)(A4HIGHT - (top_mergin + bottom_mergin));
  nb = (int)(harea /                        /* 2 lines between blocks */
	     ((nument + VI(V_ALIGNMENT_POS) + VI(V_CONSENSUS_SS) + 2)
	      * fontsize * (float)vspace /1000.0));
  if (nb == 0) {
    nb = 1;
    fprintf(stderr, "Warning: too many sequences, alignment may be bigger than page size\n");
    fprintf(stderr, "Use a smaller fontsize, or consider splitting the alignment.\n");
  }
  np = 1;

  x = left_mergin;
  y = A4HIGHT - top_mergin;
  dx = fontsize * (float)ch_space/1000.0;
  dy = fontsize * (float)vspace/1000.0;

/********************* end of preprocessing ***************************/

  write_ps_header(ps, np);

  ib = 0;
  ip = 0;
  while (1) {
    strt = nwidth * (ip*nb + ib);
    if (strt >= alilen) break;   /* finish */

    if (ib == nb) {
      ip++;
      new_page(ps, ip);
      ib = 0;
      x = left_mergin;
      y = A4HIGHT - top_mergin;
    }

    end = strt + nwidth;
    if (end >= alilen) end = alilen;

    k = 0;

/* output alignment posisition */

    if (VI(V_ALIGNMENT_POS)) {
      fprintf(ps, "%s findfont %5.1f scalefont setfont\n",
	      fontName[current_font], label_fontsize);
      x += (name_width + num_width);
      writePSalignpos(x, y, dx, strt, end, ps);
      x = left_mergin;
      y -= dy;
    }

/* domain assignment */

    for (i=0;i<nument; i++) {

/* protein codes and sequence numbers */

      if (aliall[i].type == LABEL) {
	fprintf(ps, "%s findfont %5.1f scalefont setfont\n",
		fontName[current_font], label_fontsize);
	if (VI(V_PSCOLOUR)) setColour(ps, default_colour);
	x += (name_width + num_width);
      }
      else if (aliall[i].type == STRUCTURE && pos[i] < endpos[k]) {
	setFont(ps, current_font);
	if (VI(V_PSCOLOUR)) setColour(ps, default_colour);
	showSubstr(aliall[i].code, x, y, ps, nchr);
/*	showText(aliall[i].code, x, y, ps); */
	x += name_width;
	fprintf(ps, "%5.1f %5.1f moveto ((%s)) show\n", x, y, psaall[k].resnum[pos[i]]);
	x += num_width;
      }
      else if (aliall[i].type == STRUCTURE && pos[i] >= endpos[k]) {
	setFont(ps, current_font);
	if (VI(V_PSCOLOUR)) setColour(ps, default_colour);
	showSubstr(aliall[i].code, x, y, ps, nchr);
	x += (name_width + num_width);
      }
      else if (aliall[i].type == SEQUENCE) {
	setFont(ps, current_font);
	if (VI(V_PSCOLOUR)) setColour(ps, default_colour);
	showSubstr(aliall[i].code, x, y, ps, nchr);
	x += (name_width + num_width);
      }
      else if (aliall[i].type == TEXT && strcmp(aliall[i].title, SS) == 0) { /* text entry (secondary structure) */
	setFont(ps, current_font);
	if (VI(V_PSCOLOUR)) setColour(ps, default_colour);
	showSubstr(aliall[i].code, x, y, ps, nchr);
	x += (name_width + num_width);
      }
      else {
	setFont(ps, current_font);
	if (VI(V_PSCOLOUR)) setColour(ps, default_colour);
	showSubstr(aliall[i].code, x, y, ps, nchr);
	x += (name_width + num_width);
      }

/* amino acids */

      if (aliall[i].type == STRUCTURE) { /* structure entry */

	if (! VI(V_PSCOLOUR))   /* boxshades instead of using colours */
	  col2box(x, y, dx, dy, cflgs, strt, end, k, ps);

	for (j=strt; j<end; j++) {
	  if (fflgs[k][j] < 255) { /* check if a new font begins at this position */
	    setFont(ps, fflgs[k][j]);
	    font = fflgs[k][j];
	  }

	  if (VI(V_PSCOLOUR) && cflgs[k][j] < 255) {   /* check if a new colour begins */
	    setColour(ps, cflgs[k][j]);
	  }

	  if ((pos[i] <= strtpos[k] && aliall[i].sequence[j] == '-') ||
	      pos[i] >= endpos[k] || aliall[i].sequence[j] == '/') {    /* edge gaps not shown */
	    x += dx;    /* show nothing */
	  }
	  else if (aliall[i].sequence[j] == '-') {

	    if (! isBreak(aliall[i].sequence+j, j))
	      centre_show('-', font, fontsize, x, y, ps);
	    x += dx;
	  }
	  else {
/*	    printf("pos %d font %d\n", j, font); */
	    if (show_aa_in_ps(k, temall, j, font,
			      notag_style, ns,
			      aliall[i].sequence[j], ps, x, y) != 0) {
	      /* check features that are represented 
		 without using tags and display amino acid*/
	      
	      fprintf(stderr, "pos %d in %s\n", j+1, aliall[i].code);
	    }
	    x += dx;
	    pos[i]++;
	  }
	}
	k++;
      }
      else if (aliall[i].type == SEQUENCE && scheme == -1) { /* sequence entry (B&W)*/

	fprintf(ps, "%s findfont %5.1f scalefont setfont\n",
		fontName[current_font], seq_fontsize);

	for (j=strt; j<end; j++) {
	  if (aliall[i].sequence[j] == '/') {
	    x += dx;    /* show nothing */
	  }
	  else if (aliall[i].sequence[j] == '-') {
	    if (! isBreak(aliall[i].sequence+j, j))
	      centre_show('-', current_font, seq_fontsize, x, y, ps);
	    x += dx;
	  }
	  else {        /* edge gaps sill shown, can be modified when an elegant solution found */
	    centre_show(aliall[i].sequence[j], current_font, seq_fontsize, x, y, ps);
	    x += dx;
	  }
	}
      }	
      else if (aliall[i].type == SEQUENCE) { /* sequence entry (colour)*/

	fprintf(ps, "%s findfont %5.1f scalefont setfont\n",
		fontName[current_font], seq_fontsize);

	for (j=strt; j<end; j++) {
	  if (aliall[i].sequence[j] == '/') {
	    x += dx;    /* show nothing */
	  }
	  else if (aliall[i].sequence[j] == '-') {
	    if (! isBreak(aliall[i].sequence+j, j))
	      centre_show('-', current_font, seq_fontsize, x, y, ps);
	    x += dx;
	  }
	  else {              /* edge gaps sill shown, can be modified when an elegant solution found */
	    colourPSseq(aliall[i].sequence[j], scheme, x, y, dx, dy, ps);
	    centre_show(aliall[i].sequence[j], current_font, seq_fontsize, x, y, ps);
	    x += dx;
	  }
	}
      }	
      else if (aliall[i].type == TEXT) { /* text entry (other) */
	for (j=strt; j<end; j++) {
	  if (aliall[i].sequence[j] == SPACE_CHAR) {
	    x += dx;    /* show nothing */
	  }
	  else {
	    centre_show(aliall[i].sequence[j], current_font, fontsize, x, y, ps);
	    x += dx;
	  }
	}
      }
      else if (aliall[i].type == LABEL) { /* label entry */
	for (j=0; j<nl; j++) {
	  if (labels[j][0] == i) {
	    lstr = labels[j][1];
	    lseq = labels[j][2];
	    jl = j;
	    break;
	  }
	}
	if (lseq < 0) {
	  x = left_mergin;
	  y -= dy;
	  continue;
	}
	for (j=strt; j<end; j++) {
	  if (aliall[lseq].sequence[j] != '-' && aliall[lseq].sequence[j] != '/') {
	    inum = atoi(psaall[lstr].resnum[pos[i]]);
	    if (fmod(inum, 10) < 1) {
	      sprintf(str, "%-d", inum);
	      sw = stringWidth(str, current_font, label_fontsize);
	      xp = x - sw * 0.5;
	      fprintf(ps, "%5.1f %5.1f moveto (%d) show\n", xp, y, inum);
	    }
	    pos[i]++;
	    ic[jl] = 'A';
	  }
	  else if (pos[i] > strtpos[k] && pos[i] < endpos[k]) {    /* edge gaps not shown */
	    sw = label_fontsize * charWidth[current_font][(int) ic[jl]]/1000.0;
	    xp = x - 0.5 * sw;
	    fprintf(ps, "%5.1f %5.1f moveto ", xp, y);
	    if (ic[jl]== '\\') {
	      fprintf(ps, "(\\%c) show\n", ic[jl]);
	    }
	    else {
	      fprintf(ps, "(%c) show\n", ic[jl]);
	    }
	    ic[jl]++;
	  }
	  x += dx;
	}
      }
      x = left_mergin;
      y -= dy;
    }

    if (VI(V_CONSENSUS_SS) && conss) { /* consensus secondary structure */
      setFont(ps, Symbol);  /* use symbol */
      if (VI(V_PSCOLOUR)) setColour(ps, default_colour);

      x += (name_width + num_width);
      for (j=strt; j<end; j++) {
	centre_show(conss[j], current_font, fontsize, x, y, ps);
	x += dx;
      }
      x = left_mergin;
      y -= dy;
    }

    y -= dy;
    ib++;
  }

  if (VI(V_KEY)) {
    ip++;
    new_page(ps, ip);
    writePSdefaultkey(ps);
  }

  fprintf(ps, "showpage\n");

  fclose(ps);

  free(pos);
  if (strtpos) {
    free(strtpos);
  }
  if (endpos) {
    free(endpos);
  }
  free(ps_filename);
  if (nl > 0) {
    free(labels[0]);
    free(labels);
    free(ic);
  }
  if (fflgs) {
    free(fflgs[0]);
    free(fflgs);
  }
  if (cflgs) {
    free(cflgs[0]);
    free(cflgs);
  }

  return (0);
}

int assignFonts(int nf, html_style *fonts, int alilen, int istr,
		TEM *temall, unsigned char **fflgs, int nwidth) {
  char assign;
  int i, j;
  int ib, strt, end;
  int prev = -1;
  int curr = -1;
  char isBold = 0;
  char isItalic = 0;
  int bold;
  int italic;
  int bolditalic;
  int normal;

  switch (current_font) {  
  case Times:
    normal = 0;     /* change these depending on the font */
    bold =   1;
    italic = 2;
    bolditalic = 3;
    break;
  case Courier:
    normal = 4;     /* change these depending on the font */
    bold =   5;
    italic = 6;
    bolditalic = 7;
    break;
  case Helvetica:
    normal = 8;     /* change these depending on the font */
    bold =   9;
    italic = 10;
    bolditalic = 11;
    break;
  default:
    normal = 0;     /* change these depending on the font */
    bold =   1;
    italic = 2;
    bolditalic = 3;
    break;
  }

  initialize_cvec(alilen, fflgs[istr], 255);

  ib = 0;
  while (1) {
    strt = nwidth * ib;
    if (strt >= alilen) break;

    end = strt + nwidth;
    if (end >= alilen) end = alilen;

    /* initialization */

    isBold = 0;
    isItalic = 0;
    for (i=0; i<nf; i++) {
      assign = temall[istr].feature[fonts[i].feature].assign[strt];
      if (assign == fonts[i].value) {
	if (fonts[i].num == V_BOLD) {
	  isBold = 1;
	}
	else if (fonts[i].num == V_ITALIC) {
	  isItalic = 1;
	}
      }
    }
    if (isBold == 0 && isItalic == 0) {  /* neither bold nor italic assigned */
      fflgs[istr][strt] = normal;
      prev = normal;
    }      
    else if (isBold == 1 && isItalic == 1) {  /* both bold and italic assigned */
      fflgs[istr][strt] = bolditalic;
      prev = bolditalic;
    }
    else if (isBold == 1) {
      fflgs[istr][strt] = bold;
      prev = bold;
    } 
    else if (isItalic == 1) {
      fflgs[istr][strt] = italic;
      prev = italic;
    } 

    /* Loop */

    for (j=strt+1; j<end; j++) {

      isBold = 0;
      isItalic = 0;
      for (i=0; i<nf; i++) {
	assign = temall[istr].feature[fonts[i].feature].assign[j];
	if (assign == fonts[i].value) {
	  if (fonts[i].num == V_BOLD) {
	    isBold = 1;
	  }
	  else if (fonts[i].num == V_ITALIC) {
	    isItalic = 1;
	  }
	}
      }
      if (isBold == 0 && isItalic == 0) {  /* neither bold nor italic assigned */
	curr = normal;
      }
      else if (isBold == 1 && isItalic == 1) {  /* both bold and italic assigned */
	curr = bolditalic;
      }
      else if (isBold == 1) {
	curr = bold;
      }
      else if (isItalic == 1) {
	curr = italic;
      }

      if (curr != prev) {
	fflgs[istr][j] = curr;
      }
      prev = curr;
    }

    /* finishing */
    
    ib++;
  }
  return (1);
}

int assignColours(int nc, html_style *colours,
		  int alilen, int istr,
		  TEM *temall, unsigned char **cflgs, int nwidth) {
  char assign;
  int i, j;
  int ib, strt, end;
  char isColour;
  int prev = V_BLACK;
  int curr = V_BLACK;

  initialize_cvec(alilen, cflgs[istr], 255);

  ib = 0;
  while (1) {
    strt = nwidth * ib;
    if (strt >= alilen) break;

    end = strt + nwidth;
    if (end >= alilen) end = alilen;

    /* initialization */

    isColour = 0;
    for (i=0; i<nc; i++) {
      assign = temall[istr].feature[colours[i].feature].assign[strt];
      if (assign == colours[i].value) {
	cflgs[istr][strt] = colours[i].num;
	prev = colours[i].num;
	isColour = 1;
	break;
      }
    }
    if (isColour == 0) {
      cflgs[istr][strt] = V_BLACK;
      prev = V_BLACK;
    }

    /* Loop */

    for (j=strt+1; j<end; j++) {
      isColour = 0;
      for (i=0; i<nc; i++) {
	assign = temall[istr].feature[colours[i].feature].assign[j];
	if (assign == colours[i].value) {
	  curr = colours[i].num;
	  isColour = 1;
	  break;
	}
      }
      if (isColour == 0) {
	curr = V_BLACK;
      }
      if (curr != prev) {
	cflgs[istr][j] = curr;
      }
      prev = curr;
    }

    /* finishing */
    
    ib++;
  }
  return (1);
}


/*                               */
/* determine the alignment width */
/*                               */
int alignment_width() {
  int nwidth;
  
  if (VI(V_NWIDTH) > 0) {
    nwidth = VI(V_NWIDTH);
    return nwidth;
  }    

  name_width = (int) (name_width * fontsize * 0.1 + 0.5);  /* temporary */
  num_width = (int) (num_width * fontsize * 0.1 + 0.5);  /* temporary */
  nwidth = (int)((float)(A4WIDTH - (left_mergin + name_width + num_width + right_mergin))
		 * 1000.0 / (fontsize * ch_space) + 0.5);
  return nwidth;
}

int write_ps_header(FILE *ps, int np) {

  fprintf(ps, "%%!PS-Adobe-3.0\n");
  fprintf(ps, "%%%%Pages: %d\n", np);
  fprintf(ps, "%%%%Creator: joy 5.0\n");
  fprintf(ps, "%%%%CreationDate:\n");
  fprintf(ps, "%%%%EndComments\n");
  fprintf(ps, "%%%%Page: 1 1\n");
  fprintf(ps, "/PointSize %d def\n",(int)fontsize);
  return (1);
}

int new_page(FILE *ps, int ip) {
  fprintf(ps, "showpage\n");
  fprintf(ps, "%%%%Page: %d %d\n", ip+1, ip+1);
  fprintf(ps, "/PointSize %d def\n",(int)fontsize);
  return (1);
}

int centre_show(char ch, int font, float fontsize,
		float xc, float yc, FILE *fp) {
  float x;
  float w;

  w = fontsize * charWidth[font][(int) ch]/1000.0;
  x = xc - 0.5 * w;
  fprintf(fp, "%5.1f %5.1f moveto ", x, yc);
  fprintf(fp, "(%c) show\n", ch);
  return (1);
}

float stringWidth(char *str, int font, float font_size) {
  float sw = 0.0;
  char *p;
  char ch;

  p = str;
  while(*p != '\0') {
    ch = *p;
    sw += font_size * (float)(charWidth[font][(int) ch])/1000.0;
    p++;
  }
  return sw;
}  

int writePSalignpos(float x, float y, float dx, int strt, int end,
		    FILE *fp) {
  int i=0;
  int j;
  float xp;
  float sw;
  char str[6];

  for (j = strt; j < end; j++) {
    if ((j+1) % 10 == 0) {
      xp = x + i * dx;
      sprintf(str, "%-d", j+1);
      sw = stringWidth(str, current_font, label_fontsize);
      xp -= sw * 0.5;
      fprintf(fp, "%5.1f %5.1f moveto (%d) show\n", xp, y, j+1);
    }
    i++;
  }
  return 0;
}

int show_aa_in_ps(int istr, TEM *temall, int jpos, int font,
		  html_style *style, int ns,
		  char aa, FILE *ps, float xc, float yc) {
  int i;
  char assign;
  char isupper = 0;
  char islower = 0;
  char iscedilla = 0;
  char isunderline = 0;
  char istilde = 0;
  char isbreve = 0;

  for (i=0; i<ns; i++) {
    assign = temall[istr].feature[style[i].feature].assign[jpos];
    if (assign == style[i].value) {
      switch (style[i].num) {
      case V_UPPER_CASE:
	isupper = 1;
	break;
      case V_LOWER_CASE:
	islower = 1;
	aa = tolower(aa);
	break;
      case V_CEDILLA:
	iscedilla = 1;
	break;
      case V_UNDERLINE:
	isunderline = 1;
	break;
      case V_TILDE:
	istilde = 1;
	break;
      case V_BREVE:
	isbreve = 1;
	break;
      default:
	fprintf(stderr, "Unknown PS style: ignored\n");
	break;
      }
    }
  }

  if (iscedilla == 1 && aa != 'c' && aa != 'C') {
    fprintf(stderr, "Error: cedilla assigned for non-cysteine residue ");
    fprintf(stderr, "%c\n", aa);
    fprintf(stderr, "Something is wrong!\n");
    centre_show(aa, font, fontsize, xc, yc, ps);
    return (-1);
  }
  else if (iscedilla == 1 && islower == 1) {  /* Beware of the precedences! */
    showccedilla(aa, font, xc, yc, ps);
  }
  else if (iscedilla == 1) {
    showCcedilla(aa, font, xc, yc, ps);
  }
  else {
    centre_show(aa, font, fontsize, xc, yc, ps);
  }

  /* other type settings */
  if (isunderline == 1) showUnderline(aa, font, xc, yc, ps);
  if (istilde == 1) showTilde(aa, font, xc, yc, isupper, ps);  
  if (isbreve == 1) showBreve(aa, font, xc, yc, isupper, ps);  
  return (0);
}

int changeFont() {
  if (strcmp(VS(V_PSFONT), "-") == 0) {
    return default_font;
  }
  else if (strcmp(VS(V_PSFONT), "times") == 0) {
    return Times;
  }
  else if (strcmp(VS(V_PSFONT), "courier") == 0) {
    return Courier;
  }
  else if (strcmp(VS(V_PSFONT), "helvetica") == 0) {
    return Helvetica;
  }
  else {
    fprintf(stderr, "Unknown font: %s\n", VS(V_PSFONT));
    fprintf(stderr, "use default one\n");
    return default_font;
  }
  return (1);
}

int setFont(FILE *ps, int font) {
  fprintf(ps, "%s findfont PointSize scalefont setfont\n", fontName[font]);  
  return (1);
}

int setColour(FILE *ps, int col) {
  fprintf(ps, "%s\n", colourCom[col]);
  return (1);
}

int showCcedilla(char ch, int font, float xc, float yc, FILE *fp) {
  float x;
  float w;

  w = fontsize * charWidth[font][(int) ch]/1000.0;
  x = xc - 0.5 * w;

  fprintf(fp, "%5.1f %5.1f moveto ", x, yc);
  fprintf(fp, "(%c) show\n", ch);

  x += (float)Ccedilla_dx[font] * fontsize /1000.0;
  fprintf(fp, "%5.1f %5.1f moveto\n", x, yc);
  fprintf(fp, "(\\313) show\n");
  return (1);
}

int showccedilla(char ch, int font, float xc, float yc, FILE *fp) {
  float x;
  float w;

  w = fontsize * charWidth[font][(int) ch]/1000.0;
  x = xc - 0.5 * w;

  fprintf(fp, "%5.1f %5.1f moveto ", x, yc);
  fprintf(fp, "(%c) show\n", ch);

  x += (float)ccedilla_dx[font] * fontsize /1000.0;
  fprintf(fp, "%5.1f %5.1f moveto\n", x, yc);
  fprintf(fp, "(\\313) show\n");
  return (1);
}

int showUnderline(char ch, int font, float xc, float yc, FILE *fp) {
  float x, y;
  float w;

  w = fontsize * charWidth[font][(int) ch]/1000.0;
  x = xc - 0.5 * w;
  y = yc + fontsize * (float)UnderlinePosition[font]/1000.0;

  fprintf(fp, "%5.1f %5.1f moveto\n", x, y);
  fprintf(fp, "%5.1f 0 rlineto\n", w);
  fprintf(fp, "%f setlinewidth\n", fontsize * (float)UnderlineThickness[font]/1000.0);
  fprintf(fp, "stroke\n");
  return (1);
}

int showTilde(char ch, int font, float xc, float yc, 
	      char isupper, FILE *fp) {
  float x, y;
  float w, h;

  w = fontsize * charWidth[font][(int) ch]/1000.0;
  h = fontsize * charHight[font][(int) ch]/1000.0;
  x = xc - 0.5 * fontsize * (float)TildeWx[font]/1000.0;
  y = yc + h + fontsize * (float)Tilde_dy[font]/1000.0;

  fprintf(fp, "%5.1f %5.1f moveto\n", x, y);
  fprintf(fp, "(\\304) show\n");
/*  fprintf(fp, "%5.1f 0 rlineto\n", w);
  fprintf(fp, "%f setlinewidth\n", fontsize * (float)UnderlineThickness[font]/1000.0);
  fprintf(fp, "stroke\n"); */
  return (1);
}

int showBreve(char ch, int font, float xc, float yc, 
	      char isupper, FILE *fp) {
  float x, y;
  float w, h;

  w = fontsize * charWidth[font][(int) ch]/1000.0;
  h = fontsize * charHight[font][(int) ch]/1000.0;

  x = xc - 0.5 * fontsize * (float)BreveWx[font]/1000.0;
  y = yc + h + fontsize * (float)Breve_dy[font]/1000.0;

  fprintf(fp, "%5.1f %5.1f moveto\n", x, y);
  fprintf(fp, "(\\306) show\n");
  return (1);
}

int showText(char *s, float x, float y, FILE *fp) {
  fprintf(fp, "%5.1f %5.1f moveto (%s) show\n", x, y, s);
  return (1);
}

int showSubstr(char *s, float x, float y, FILE *fp, int n) {
  int i=0;
  char *sub;
  sub = s;

  fprintf(fp, "%5.1f %5.1f moveto \n(", x, y);
  while (i<n) {
    if (*sub == '\0') break;
    if (*sub == ')') {
      fprintf(fp, "\\)");
    }
    else if (*sub == '(') {
      fprintf(fp, "\\(");
    }
    else {
      fprintf(fp, "%c", *sub);
    }
    i++;
    sub++;
  }
  fprintf(fp, ") show\n");
  return (1);
}

int col2box(float x, float y, float dx, float dy,
	    unsigned char **cflgs, int strt, int end,
	    int istr, FILE *fp) {
  int i, j;
  char pc = 255;  /* previous colour */
  float xi = -1.0;
  float xt;
  float xo, yo, w, gs;

  i = 0;
  for (j=strt; j<end; j++) {
    if (cflgs[istr][j] < 255) {   /* new colour begins */
      if (xi > 0) {   /* end of previous colour */
	xt = x + dx * (i-1);
	w = xt - xi + dx;
	xo = xi - 0.5 * dx;
	yo = y + boxYoffset * dy;
	gs = col2gray(pc);
	drawGrayBox(xo, yo, w, dy, gs, fp);
	pc = 255;
	xi = -1.0;
      }

      if (cflgs[istr][j] > V_BLACK) {  /* begin */
	xi = x + dx * i;
	pc = cflgs[istr][j];
      }
    }
    i++;
  }
  if (xi > 0) {
    xt = x + dx * (end-strt-1);
    w = xt - xi + dx;
    xo = xi - 0.5 * dx;
    yo = y + boxYoffset * dy;
    gs = col2gray(pc);
    drawGrayBox(xo, yo, w, dy, gs, fp);
  }
  return (1);
}

float col2gray(int col) {
  switch (col) {
  case V_RED:
    return 0.5;
    break;
  case V_BLUE:
    return 0.9;
    break;
  case V_MAROON:
    return 0.7;
    break;
  default:
    return 1.0;
    break;
  }
}

int drawGrayBox(float x, float y, float w, float h, float gs, FILE *fp) {

  fprintf(fp, "gsave\n");
  fprintf(fp, "%5.1f setgray\n", gs);
  fprintf(fp, "%5.1f %5.1f %5.1f %5.1f rectfill\n",
	  x, y, w, h);
  fprintf(fp, "grestore\n");
  fprintf(fp, "0.5 setlinewidth\n");
  fprintf(fp, "%5.1f %5.1f %5.1f %5.1f rectstroke\n",
	  x, y, w, h);
  return (1);
}

int drawColourBox(float x, float y, float w, float h, char *col, FILE *fp) {

  fprintf(fp, "gsave\n");
  fprintf(fp, "%s setrgbcolor\n", col);
  fprintf(fp, "%5.1f %5.1f %5.1f %5.1f rectfill\n",
	  x, y, w, h);
  fprintf(fp, "grestore\n");
  return (1);
}

int colourPSseq(char aa, int scheme, float x, float y,
		float dx, float dy, FILE *fp) {
  int idx;
  int colorcode;
  float xo, yo;

  idx = aa - cs;
  if (idx < 0) return(1);
  colorcode = colorschemes[scheme].residue[idx];
/*  printf("char %c %d\n",aa,  colorcode);
    printf("%c %s\n", aa, colorschemes[scheme].colors[colorcode]); */

  if (colorcode < 0) return(1);

  xo = x - 0.5 * dx;
  yo = y + boxYoffset * dy;
  drawColourBox(xo, yo, dx, dy, colorschemes[scheme].colors[colorcode], fp);
  return (1);
}

int writePSdefaultkey(FILE *fp) {
  float x, y, dx, dy;
  float dx1, dx2;
  float yl, sw;
  int fb, fi;  /* fonts */
  float xo, yo, gs; /* boxes */

  switch (current_font) {  
  case Times:
    fb =   1;
    fi = 2;
    dx1 = fontsize * 16.8;
    break;
  case Courier:
    fb = 5;
    fi = 6;
    dx1 = fontsize * 21.8;
    break;
  case Helvetica:
    fb = 9;
    fi = 10;
    dx1 = fontsize * 17.2;
    break;
  default:
    fb = 1;
    fi = 2;
    dx1 = fontsize * 16.8;
    break;
  }

  dx = fontsize * (float)ch_space/1000.0;
  dy = fontsize * (float)vspace/1000.0;

  x = left_mergin + dx * 12;
  y = A4HIGHT - top_mergin;

  dx2 = dx * 10;

  setFont(fp, fb);
  if (VI(V_PSCOLOUR)) setColour(fp, default_colour);
  showText("Key to JOY", x, y, fp);

  x = left_mergin;
  y -= dy;
  setFont(fp, current_font);
  showText("solvent inaccessible", x, y, fp);
  x += dx1;
  showText("UPPER CASE", x, y, fp);
  x += dx2;
  centre_show('X', current_font, fontsize, x, y, fp);

  y -= dy;
  x = left_mergin;
  showText("solvent accessible", x, y, fp);
  x += dx1;
  showText("lower case", x, y, fp);
  x += dx2;
  centre_show('x', current_font, fontsize, x, y, fp);

  y -= dy;
  x = left_mergin;
  setFont(fp, Symbol);
  showText("a", x, y, fp);
  setFont(fp, current_font);
  fprintf(fp, "(-helix) show\n");
  x += dx1;

  if (VI(V_PSCOLOUR))  {
    setColour(fp, V_RED);
    showText("red", x, y, fp);
    x += dx2;
  }
  else {
    x += dx2;
    xo = x - 0.5 * dx;
    yo = y + boxYoffset * dy * 0.9;
    gs = col2gray(V_RED);
    drawGrayBox(xo, yo, dx, dy * 0.9, gs, fp);
  }
  centre_show('x', current_font, fontsize, x, y, fp);

  y -= dy;
  x = left_mergin;
  setFont(fp, Symbol);
  if (VI(V_PSCOLOUR)) setColour(fp, default_colour);
  showText("b", x, y, fp);
  setFont(fp, current_font);
  fprintf(fp, "(-strand) show\n");
  x += dx1;

  if (VI(V_PSCOLOUR))  {
    setColour(fp, V_BLUE);
    showText("blue", x, y, fp);
    x += dx2;
  }
  else {
    x += dx2;
    xo = x - 0.5 * dx;
    yo = y + boxYoffset * dy * 0.9;
    gs = col2gray(V_BLUE);
    drawGrayBox(xo, yo, dx, dy * 0.9, gs, fp);
  }
  centre_show('x', current_font, fontsize, x, y, fp);

  y -= dy;
  x = left_mergin;
  if (VI(V_PSCOLOUR)) setColour(fp, default_colour);
  showText("3", x, y, fp);
  fprintf(fp, "%s findfont\n", fontName[current_font]);
  fprintf(fp, "[  PointSize 0.65 mul 0 0 PointSize 0.6 mul 0 0 ] makefont\n");
  fprintf(fp, "setfont\n");
  fprintf(fp, "0 -%-5.1f rmoveto (10) show\n", fontsize * 0.25);  /* temporary */
  fprintf(fp, "0 %5.1f rmoveto\n", fontsize * 0.25);
  setFont(fp, current_font);
  fprintf(fp, "(-helix) show\n");

  x += dx1;
  if (VI(V_PSCOLOUR))  {
    setColour(fp, V_MAROON);
    showText("maroon", x, y, fp);
    x += dx2;
  }
  else {
    x += dx2;
    xo = x - 0.5 * dx;
    yo = y + boxYoffset * dy * 0.9;
    gs = col2gray(V_MAROON);
    drawGrayBox(xo, yo, dx, dy * 0.9, gs, fp);
  }
  centre_show('x', current_font, fontsize, x, y, fp);

  y -= dy;
  x = left_mergin;
  if (VI(V_PSCOLOUR)) setColour(fp, default_colour);
  showText("hydrogen bond to main chain amide", x, y, fp);
  x += dx1;
  setFont(fp, fb);
  showText("bold", x, y, fp);
  x += dx2;
  centre_show('x', fb, fontsize, x, y, fp);

  y -= dy;
  x = left_mergin;
  setFont(fp, current_font);
  showText("hydrogen bond to main chain carbonyl", x, y, fp);
  x += dx1;
  showText("underline", x, y, fp);

  yl = y + fontsize * (float)UnderlinePosition[current_font]/1000.0;
  sw = stringWidth("underline", current_font, fontsize);
  fprintf(fp, "%5.1f %5.1f moveto\n", x, yl);
  fprintf(fp, "%5.1f 0 rlineto\n", sw);
  fprintf(fp, "%f setlinewidth\n", fontsize * (float)UnderlineThickness[current_font]/1000.0);
  fprintf(fp, "stroke\n");

  x += dx2;
  centre_show('x', current_font, fontsize, x, y, fp);
  showUnderline('x', current_font, x, y, fp);

  y -= dy;
  x = left_mergin;
  showText("hydrogen bond to other sidechain", x, y, fp);
  x += dx1;
  showText("tilde", x, y, fp);
  x += dx2;
  centre_show('x', current_font, fontsize, x, y, fp);
  showTilde('x', current_font, x, y, 0, fp);  

  y -= dy;
  x = left_mergin;
  showText("disulphide bond", x, y, fp);
  x += dx1;
  showText("cedilla", x, y, fp);
  x += dx2;
  showccedilla('c', current_font, x, y, fp);

  y -= dy;
  x = left_mergin;
  showText("positive ", x, y, fp);
  setFont(fp, Symbol);
  fprintf(fp, "(f) show\n");
  x += dx1;
  setFont(fp, fi);
  showText("italic", x, y, fp);
  x += dx2;
  centre_show('x', current_font, fontsize, x, y, fp);

  y -= dy;
  x = left_mergin;
  setFont(fp, fi);
  showText("cis-", x, y, fp);
  setFont(fp, current_font);
  fprintf(fp, "(peptide) show\n");

  x += dx1;
  showText("breve", x, y, fp);
  x += dx2;
  centre_show('x', current_font, fontsize, x, y, fp);
  showBreve('x', current_font, x, y, 0, fp);  
  return (1);
}
