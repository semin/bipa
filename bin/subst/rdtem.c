/*
 *
 * $Id:
 *
 * subst release $Name:
 */
/****************************************************************
* subst: A program to calculate environment-specific            *
*        amino acid substitution tables                         *
* Copyright (C) 1999-2000  Kenji Mizuguchi                      *
*                                                               *
*                                                               *
* rdtem.c                                                       *
* Reads in a .tem file produced by JOY                          *
****************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "rdtem.h"
#include "utility.h"

void free_list (char_list *list_ptr)
{
  char_list *last_ptr;
  while (list_ptr != NULL) {
    last_ptr = list_ptr->next;
    free(list_ptr);
    list_ptr = last_ptr;
  }
}

void free_seq (PIR *seqall, int nseq) {
  int i;
  for (i=0; i<nseq; i++) {
    free(seqall[i].code);
    free(seqall[i].title);
    free(seqall[i].sequence);
  }
  free(seqall);
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
* until it finde the specified stop character.
* returns the sequence.
***************************************************/
char *get_seq (FILE *fp, char stop) {
  char_list *init_ptr = NULL;
  char_list *last_ptr;
  char *seq;
  char *tmp;
  int c;
  int i;

  c = getc(fp);
  init_ptr = store_list(init_ptr, c);
  last_ptr = init_ptr;
  i = 1;

  while ((c=getc(fp)) != stop) {
    if (c == '\n') {
      continue;
    }
    last_ptr = store_list(last_ptr, c);
    i++;
  }
/*   printf("read in %d char\n", i); */
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
    if (isBofLine == 1) {
      if (c == '>') {
	i++;
      }
      isBofLine = 0;
      continue;
    }
    if (c ==  '\n') {
      isBofLine = 1;
      continue;
    }
  }
  fseek(fp,0,0);
  return i;
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

void rdseq (FILE *in_file, int nseq, PIR *seqall) {
  int c;
  int isBofLine = 1;
  int iseq = 0;

  while ((c=getc(in_file)) != EOF) {
    if (isBofLine == 1) {
      if (c == '>') {
	c=getc(in_file);  /* P */
	c=getc(in_file);  /* 1 */
	c=getc(in_file);  /* ; */
	seqall[iseq].code = get_seq(in_file, '\n');
	seqall[iseq].title = get_seq(in_file, '\n');
	seqall[iseq].sequence = get_seq(in_file, '*');
	
	trim_space(seqall[iseq].code);    /* trim trailing space */
	trim_space(seqall[iseq].title);
	trim_space(seqall[iseq].sequence);

	iseq++;
	isBofLine = 0;
	continue;
      }
      isBofLine = 0;
    }
    if (c ==  '\n') {
      isBofLine = 1;
      continue;
    }
  }
  if (iseq != nseq) {
    fprintf(stderr, "Something is wrong with the input file\n");
    fprintf(stderr, "no. of > %d, no. of * %d\n", nseq, iseq);
    exit (-1);
  }
}
