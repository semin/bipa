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
* slink.h                                                       *
* Header for slink.cp                                           *
****************************************************************/
#ifndef __slink
#define __slink

typedef struct cluster {
  int nmem;
  int *memlist;
} cluster;

cluster *slinkc(int, double **, char **, int *);
cluster *_partition(int, char **, char **, int **, double *, int *);
char **copy_names(int, char **);
int where_is_string(char *, int, char **);
void free_names(int, char **);

#endif
