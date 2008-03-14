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
* rdali.c                                                                   *
* Reads in a multiple alignemnt in the ALI format.                          *
* Default filename is .ali. For the format of this file, see                *
* the manual or the Bioinformatics paper.                                   *
*                                                                           *
* There is no restircion for the number of entries or the                   *
* length of each line, but no rigorous format check is                      *
* performed.                                                                *
*                                                                           *
* Author: Kenji Mizuguchi                                                   *
*                                                                           *
* Note                                                                      *
*                                                                           *
* Date:        29 Jan 1999                                                  *
* Last update: 29 Jan 1999                                                  *
*                                                                           *
****************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include "parse.h"
#include "utility.h"
#include "rdali.h"

void free_list (char_list *list_ptr)
{
  char_list *last_ptr;
  while (list_ptr != NULL) {
    last_ptr = list_ptr->next;
    free(list_ptr);
    list_ptr = last_ptr;
  }
}

char_list *store_list (char_list *list_ptr, char ch)
{
  char_list *current_ptr;

  if (list_ptr == NULL) {
    current_ptr = (char_list *) malloc(sizeof(char_list));
  }
  else {
    list_ptr->next = (char_list *) malloc(sizeof(char_list));
    current_ptr = list_ptr->next;
  }
  if (current_ptr == NULL) {
    fprintf(stderr, "Error: out of memory\n");
    exit(-1);
  }
  current_ptr->data = ch;
  current_ptr->next = NULL;
  return current_ptr;
}

/***************************************************
* get_seq
*
* Reads in a sequence of characters (not necessarily
* amino acids) from a given file pointer
* until it finds the specified stop character.
* returns the sequence.
*
* (modified on	24 Mar 2003)
* If the stop character is '\n', it skipps only
* ' ' and '\t', otherwise, it skipps ' ', '\t' and '\n'.
***************************************************/
char *get_seq (FILE *fp, char stop) {
  char_list *init_ptr = NULL;
  char_list *last_ptr;
  char *seq;
  char *tmp;
  int c;
  int i;
  int found = 0;

  if (stop == '\n') {
    while ((c=getc(fp)) != EOF) {
      if (c == ' ' || c == '\t') {
	continue;
      }
      break;  /* first non-space (but '\n') charactre  */
    }
  }
  else {
    while ((c=getc(fp)) != EOF) {
      if (isspace(c)) { /* skip blank, tab and new line */
	continue;
      }
      break;
    }
  }

  if (c == stop) { /* first character read in is the stop character */
    return NULL;
  }
  init_ptr = store_list(init_ptr, c);
  last_ptr = init_ptr;
  i = 1;

  while ((c=getc(fp)) != EOF) {
    if (stop != '\n' && isspace(c)) {
      continue;
    }
    if (c == stop) {
      found = 1;
      break;
    }
    last_ptr = store_list(last_ptr, c);
    i++;
  }
  if (found == 0) { /* stop character not found */
    return NULL;
  }

  seq = (char *) malloc(sizeof(char) * (i + 1));
  if (seq == NULL) {
    fprintf(stderr, "Error: out of memory\n");
    exit(-1);
  }

  tmp = seq;
  last_ptr = init_ptr;
  while (last_ptr != NULL) {
    *seq = last_ptr->data;
    last_ptr = last_ptr->next;
    seq++;
  }
  *seq = '\0';
  free_list (init_ptr);
  return tmp;
}
/***************************************************
* check_file
*
* Counts the occurances of '>' at the beginning of
* a line in a given file.
* This corresponds to the total number of sequences.
*
***************************************************/
int check_file (FILE *fp) {
  int c;
  int i=0;
  int isBofLine = 1;

  while ((c=getc(fp)) != EOF) {
    if (isBofLine == 1 && c == '>') {
      i++;
      isBofLine = 0;
    }
    else if (c== '\n') {
      isBofLine = 1;
    }
    else {
      isBofLine = 0;
    }
  }
  fseek(fp,0,0);
  return i;
}
/***************************************************
* get_ali
*
***************************************************/
ALIFAM *get_ali(char *alifile, char *alibase) {
  FILE *in_file;    /* input file */
  ALIFAM *alifam;

  in_file = fopen(alifile, "r");
  if (in_file == NULL) {
    fprintf(stderr, "Error: Unable to open %s\n", alifile);
    exit (-1);
  }

  alifam = (ALIFAM *) malloc(sizeof(ALIFAM));
  if (alifam == NULL) {
    fprintf(stderr, "Error: out of memory\n");
    exit(-1);
  }

  alifam->code = strdup(alibase);
  alifam->nument = check_file(in_file);   /* total no. of entries to read in */
  alifam->comment = NULL;   /* initialization necessary !! */
  alifam->family = NULL;
  alifam->class = NULL;
  alifam->ali = (ALI *) malloc(sizeof(ALI) * alifam->nument);
  if (alifam->ali == NULL) {
    fprintf(stderr, "Error: out of memory\n");
    exit(-1);
  }

  alifam->alilen = rdali(in_file, alifam);
  fprintf(stderr, "%d entrie(s) read in\n", alifam->nument);
  fprintf(stderr, "Alignment length: %d\n", alifam->alilen);
  if (alifam->nument == 0 || alifam->alilen <= 0) {
    fprintf(stderr, "Error: no data in %s\n", alifile);
    fprintf(stderr, "Check the file format\n");
    exit(-1);
  }
  fclose(in_file);

  if (VI(V_SEG)) {
    _get_seg(alifam);
  }
  _get_nstr (alifam);

/*  write_ali(aliall, nument, 75); */

  return alifam;
}
/***************************************************
* rdali: Main function to read in a .ali file
*
***************************************************/
int rdali (FILE *in_file, ALIFAM *alifam) {

  ALI *aliall;
  int nument;
  int c;
  char *tmp_code;
  char code[4];
  int isBofLine = 1;

  char *tmp_comment;
  char chead[2];
  int alilen;           /* alignment length (return) */
  int i, j, tmplen;
  int iseq = 0;

  aliall = alifam->ali;
  nument = alifam->nument;

  while ((c=getc(in_file)) != EOF) {
    if (c == ' ' || c == '\t') { /* skip space or tab */
      isBofLine = 0;
      continue;
    }

    if (isBofLine == 1 && (c == 'C' || c == '#')) { /* comment line */
      chead[0] = c;
      chead[1] = '\0';
      tmp_comment = mstrcat(chead, get_seq(in_file, '\n'));

      if (alifam->comment != NULL) {
	alifam->comment = mstrcat(alifam->comment, "\n");
	alifam->comment = mstrcat(alifam->comment, tmp_comment);
      }
      else {
	alifam->comment = strdup(tmp_comment);
      }
      free(tmp_comment);
      continue;
    }
    if (isBofLine == 1 && c == '>') {

      /* Introduced format check  (24 Mar 2003) */
      for (i=0; i<3; i++) {
	code[i] = getc(in_file);
	if (isspace(code[i])) {
	  code[i] = '\0';
	  format_error(code, i);
	}
      }
      code[3] = '\0';
      /* P (sequence), F (fragment), T (text) or N (label) */
      if ((code[0] != 'P' && code[0] != 'F' && code[0] != 'T' && code[0] != 'N') ||
	  code[1] != '1' ||
	  code[2] != ';') {
	format_error(code, 0);
      }

      if (code[0] == 'N') { /* label entry */
	tmp_code = trim_space(get_seq(in_file, '\n'));
	if (!tmp_code || tmp_code[0] != '!') {
	  fprintf(stderr, "Error in reading .ali file\n");
	  fprintf(stderr, ">N1;");
	  if (tmp_code) {
	    fprintf(stderr, "%s", tmp_code);
	  }
	  fprintf(stderr, "\n");
	  fprintf(stderr, "    ^\n");
	  fprintf(stderr, ">N1; must be followed by '!', followed by a code.\n");
	  exit (-1);
	}
	aliall[iseq].type = LABEL;
	aliall[iseq].code = strdup(tmp_code+1);
	free(tmp_code);
	if (!aliall[iseq].code) {
	  format_error(code, 3);
	}
	iseq++;
	continue;
      }
      else if (code[0] == 'T') { /* text entry */
	aliall[iseq].type = TEXT;
      }
      else {
	aliall[iseq].type = STRUCTURE;  /* assuming structure for now */
      }

      aliall[iseq].code = trim_space(get_seq(in_file, '\n'));
      if (!aliall[iseq].code) {
	format_error(code, 3);
      }

      aliall[iseq].title = trim_space(get_seq(in_file, '\n'));
      if (! aliall[iseq].title) {
	fprintf(stderr, "Error in reading .ali file\n");
	fprintf(stderr, ">%s%s\n",code, aliall[iseq].code);
	fprintf(stderr, "\n");
	fprintf(stderr, "^^^\n");
	fprintf(stderr, "This line must begin with either 'structure' or 'sequence'.\n");
	exit (-1);
      }

      aliall[iseq].sequence = get_seq(in_file, '*');
      if (! aliall[iseq].sequence) {
	fprintf(stderr, "Error in reading .ali file\n");
	fprintf(stderr, "Trying to read in the sequence of %s\n",aliall[iseq].code);
	fprintf(stderr, "but there is no amino acid character or\n");
	fprintf(stderr, "the sequence is not terminated by an asterisk (*).\n");
	exit (-1);
      }

      if (aliall[iseq].type != TEXT) {
	if (strncmp("sequence", aliall[iseq].title, 8) == 0) { /* sequence entry */
	  aliall[iseq].type = SEQUENCE;
	}
	else if (strncmp("structure", aliall[iseq].title, 9) == 0) { /* structure entry */
	  aliall[iseq].type = STRUCTURE;
	}
	else {
	  fprintf(stderr, "Error in reading .ali file\n");
	  fprintf(stderr, ">%s%s\n",code,aliall[iseq].code);
	  fprintf(stderr, "%s\n", aliall[iseq].title);
	  fprintf(stderr, "^^^\n");
	  fprintf(stderr, "This line must begin with either 'structure' or 'sequence'.\n");
	  exit (-1);
	}
      }
      iseq++;
      isBofLine = 0;
      continue;

      /* Starting from '>', finished reading in until '*' */
      /* Continues the loop and the next charactre should */
      /* be a new-line. */
    }
    else if (c == '\n') { /* new-line char found */
      isBofLine = 1;
      continue;
    }
    else { /* format error */
      fprintf(stderr, "Error in reading .ali file\n");
      if (iseq > 0) {
	fprintf(stderr, "The last sequence read in: %s%s\n", code, aliall[iseq-1].code);
      }
      fprintf(stderr, "Unexpected character '%c' found \n", c);
	fprintf(stderr, "after the asterisk that terminates the previous sequence.\n");
	exit (-1);
    }
  }

  if (iseq != nument) {
    fprintf(stderr, "Something is wrong with the input file\n");
    fprintf(stderr, "no. of >P1; %d, no. of * %d\n", nument, iseq);
    exit (-1);
  }

  alilen = -1;  /* check the alignment length */
  j = -1;
  for (i=0; i<nument; i++) {
    if (aliall[i].type == LABEL) {
      continue;
    }
    tmplen = strlen(aliall[i].sequence);
    if (alilen > 0 && alilen != tmplen) {
      fprintf(stderr, "Format error in .ali file\n");
      fprintf(stderr, "The length of %dth entry is %d\n", i, tmplen);
      fprintf(stderr, "whereas the length of %dth entry is %d\n",j, alilen);
      exit (-1);
    }
    j = i;
    alilen = tmplen;
  }
  return alilen;
}

/***************************************************
* _get_seg   Get segment info from the structure lines
*
***************************************************/
int _get_seg (ALIFAM *alifam) {
  int nument;
  ALI *aliall;
  int i;
  char strtres[10], strtchn[10];
  char endres[10], endchn[10];
  
  nument = alifam->nument;
  aliall = alifam->ali;

  for (i=0; i<nument; i++) {
    if (aliall[i].type != STRUCTURE) continue;
    if (sscanf(aliall[i].title, "%*[^:]:%*[^:]:%[^:]:%[^:]:%[^:]:%[^:]",
	       strtres, strtchn, endres, endchn) != 4) {
      fprintf(stderr, "Error: Incorrect segment information for %s\n", aliall[i].code);
      fprintf(stderr, " %s\n", aliall[i].title);
      fprintf(stderr, " ^^^^^^^^^\n");
      fprintf(stderr, " The correct format of this line is:\n");
      fprintf(stderr, " structure[X|N]:PDB_code:start_res:start_chain:end_res:end_chain\n");
      exit (-1);
    }

    strcpy(aliall[i].seg.strt_pdbres, trim_space(strtres));
    strcpy(aliall[i].seg.end_pdbres, trim_space(endres));
    strcpy(strtchn, trim_space(strtchn));
    if (strtchn[0] == '\0') {
      aliall[i].seg.strt_chain = ' ';
    }
    else {
      aliall[i].seg.strt_chain = strtchn[0];
    }
    strcpy(endchn, trim_space(endchn));
    if (endchn[0] == '\0') {
      aliall[i].seg.end_chain = ' ';
    }
    else {
      aliall[i].seg.end_chain = endchn[0];
    }

    fprintf(stderr, "%s from #%s# #%c# to #%s# #%c#\n", aliall[i].code,
	    aliall[i].seg.strt_pdbres, aliall[i].seg.strt_chain,
	    aliall[i].seg.end_pdbres, aliall[i].seg.end_chain);
  }
  return (1);
}

/***************************************************
* _get_nstr
*
* Counts the number of structure entries and makes
* a list of indices for these entries.
***************************************************/
int _get_nstr (ALIFAM *alifam) {
  int nument;
  ALI *aliall;
  int i, j;
  
  nument = alifam->nument;
  aliall = alifam->ali;

  alifam->nstr = 0;
  for (i=0; i<nument; i++) {
    if (aliall[i].type == STRUCTURE) { /* structure entry */
      (alifam->nstr)++;
    }
  }
  if (alifam->nstr > 0) {
    alifam->str_lst = ivector(alifam->nstr);/* list of indices for structure entries */
  }

  j = 0;
  for (i=0; i<nument; i++) {
    if (aliall[i].type == STRUCTURE) { /* structure entry */
      (alifam->str_lst)[j] = i;
      j++;
    }
  }
  return (1);
}

/***************************************************
* write_ali This is for debugging (comment lines not reproduced)
*
***************************************************/
void write_ali (ALI *aliall, int nument, int nwidth) {
  int i;
  int j;
  char ch;

  for (i=0; i<nument; i++) {
    if (aliall[i].type == 0) { /* label entry */
      printf(">N1;!%s\n", aliall[i].code);
      continue;
    }
    else if (aliall[i].type == 1) { /* text entry */
      printf(">T1;%s\n", aliall[i].code);
    }
    else { /* sequence or structure entry */
      printf(">P1;%s\n", aliall[i].code);
    }
      
    printf("%s\n", aliall[i].title);
    j = 0;
    ch = aliall[i].sequence[0];
    while (ch !=  '\0') {
      j++;
      printf("%c", ch);
      if ((j % nwidth) == 0) {
	printf("\n");
      }
      ch = aliall[i].sequence[j];
    }
    printf("*\n");
  }
}

/***************************************************
* write_seq
*
***************************************************/
void write_seq (PIR *seqall, int nseq, int nwidth) {
  int i;
  int j;
  char ch;

  for (i=0; i<nseq; i++) {
    printf(">P1;%s\n", seqall[i].code);
    printf("%s\n", seqall[i].title);
    j = 0;
    ch = seqall[i].sequence[0];
    while (ch !=  '\0') {
      j++;
      printf("%c", ch);
      if ((j % nwidth) == 0) {
	printf("\n");
      }
      ch = seqall[i].sequence[j];
    }
    printf("*\n");
  }
}

/***************************************************
* format_error
*
***************************************************/
 void format_error (char *code, int pos) {
   fprintf(stderr, "Error in reading .ali file\n");
   fprintf(stderr, ">%s\n", code);
   if (pos < 3) {
     fprintf(stderr, " ^^^\n");
   }
   else {
     fprintf(stderr, "    ^^^\n");
   }
   fprintf(stderr, "In this line, a '>' sign must be followed by\n");
   fprintf(stderr, "  a two-letter code (one of 'P1', 'F1', 'T1' or 'N1'), followed by\n");
   fprintf(stderr, "  a semicolon, followed by\n");
   fprintf(stderr, "  a sequence identification code\n");
   fprintf(stderr, "(e.g., >P1;1abc).\n");
   exit (-1);
 }   
