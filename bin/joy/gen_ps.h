/*
 *
 * $Id: gen_ps.h,v 1.13 2000/08/01 10:19:35 kenji Exp $
 *
 * joy 5.0 release $Name:  $
 */
/****************************************************************************
* joy: A program for protein sequence-structure representation and analysis *
* Copyright (C) 1988-1997  John Overington                                  *
* Copyright (C) 1997-1999  Kenji Mizuguchi and Charlotte Deane              *
* Copyright (C) 1999-2000  Kenji Mizuguchi                                  *
*                                                                           *
* gen_ps.h                                                                  *
* Header file for gen.c                                                     *
****************************************************************************/
#ifndef __gen_ps
#define __gen_ps

#include "tag.h"

#define A4WIDTH (595)
#define A4HIGHT (842)

#define PS_SUFFIX ".ps"

#define Times     (0)
#define Courier   (4)
#define Helvetica (8)
#define Symbol    (12)

static int ch_space = 800;    /* horizontal character space
			       in units of the charcter coordinate system */
static int vspace =  1500;    /* line space */
static float boxYoffset = -0.3; /* box origin at y + (vspace * this_value) */

static int left_mergin  = 72;
static int right_mergin = 60;
static int top_mergin =  137; /* These are shown in PostScript units */
static int bottom_mergin =15;
static int name_width =   30;
static int num_width  =   33;

static float fontsize = 10.0;
static int default_font = 0; /* Times-Roman */
static float label_fontsize = 8.0;
static float seq_fontsize = 8.0;
static int default_colour = 0; /* black */

int gen_ps(ALIFAM *, char **, TEM *, PSA *, int *, int);
int alignment_width(void);
int changeFont(void);

int assignFonts(int, html_style *,
		int, int, TEM *, unsigned char **, int);
int assignColours(int, html_style *,
		  int, int, TEM *, unsigned char **, int);

int writePSalignpos(float, float, float, int, int, FILE *);
int write_ps_header(FILE *, int);
int new_page(FILE *, int);
int writePSdefaultkey(FILE *);

int centre_show(char, int, float, float, float, FILE *);
int showCcedilla(char, int, float, float, FILE *);
int showccedilla(char, int, float, float, FILE *);
int showUnderline(char, int, float, float, FILE *);
int showTilde(char, int, float, float, char, FILE *);
int showBreve(char, int, float, float, char, FILE *);
int show_aa_in_ps(int, TEM *, int, int, html_style *, int, char,
		  FILE *, float, float);

int setFont(FILE *, int);
int setColour(FILE *, int);
int showText(char *, float, float, FILE *);
int showSubstr(char *, float, float, FILE *, int);

int col2box(float, float, float, float, unsigned char **, int, int, int, FILE *);
int drawGrayBox(float, float, float, float, float, FILE *);
int drawColourBox(float, float, float, float, char *, FILE *);

float col2gray(int);
int colourPSseq(char, int, float, float, float, float, FILE *);

float stringWidth(char *, int, float);

#endif
