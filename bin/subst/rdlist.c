/*
 *
 * $Id: rdlist.c,v 1.4 2000/08/04 10:26:09 kenji Exp $
 *
 * subst release $Name:  $
 */
/****************************************************************
* subst: A program to calculate environment-specific            *
*        amino acid substitution tables                         *
* Copyright (C) 1999-2000  Kenji Mizuguchi                      *
*                                                               *
*                                                               *
* rdlist.c                                                      *
* Reads in a list of filenames                                  *
****************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

#include "getopt.h"
#include "options.h"
#include "utility.h"
#include "rdlist.h"

char **rdlist(char *filename, int *n) {
  char line[MAXFILELEN];
  char **tem_list;
  int i;
  FILE *fp;

  fp = fopen(filename, "r");
  if (fp == NULL) {
    fprintf(stderr, "Error: Unable to open %s\n", filename);
    return NULL;
  }

  tem_list = (char **) malloc(sizeof(char *) * INITIAL_SIZE);
  if (tem_list == NULL) {
    fprintf(stderr, "Error: out of memory\n");
    exit(-1);
  }

  i = 0;
  while (fgets(line, sizeof(line), fp)) {
    if (line[0] == '!' || line[0] == '#')
      continue; /* comment line */

    if (i >= INITIAL_SIZE) {
      fprintf(stderr, "Error: no of tem files read in is currently %d.\n",
	      INITIAL_SIZE);
      exit(-1);
    }
    line[strlen(line)-1] = '\0';
    tem_list[i] = strdup(expand_path(line));
    i++;
  }
  fclose(fp);
  *n = i;
  return tem_list;
}

void show_list(int n, char **tem_list) {
  int i;
  for (i=0; i<n; i++) {
    printf("%s\n", tem_list[i]);
  }
}
