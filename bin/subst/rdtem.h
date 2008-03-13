/*
 *
 * $Id:
 *
 * subst release $Name:  $
 */
/****************************************************************
* subst: A program to calculate environment-specific            *
*        amino acid substitution tables                         *
* Copyright (C) 1999-2000  Kenji Mizuguchi                      *
*                                                               *
*                                                               *
* rdtem.h                                                       *
* Header for rdtem.c                                            *
****************************************************************/
#ifndef __rdtem
#define __rdtem

typedef struct char_list {
  char data;
  struct char_list *next;
} char_list;

typedef struct PIR {
  char *code;
  char *title;
  char *sequence;
} PIR;

char_list *store_list (char_list *, char);
void free_seq (PIR *, int);
void free_list (char_list *);
char *get_seq (FILE *fp, char );
int check_file (FILE *fp);
void rdseq (FILE *, int, PIR *);
void write_seq (PIR *, int , int);
#endif
