/*
*
* $Id:
* subst release $Name:  $
*/
/****************************************************************
* subst: A program to calculate environment-specific            *
*        amino acid substitution tables                         *
* Copyright (C) 1999-2000  Kenji Mizuguchi                      *
*                                                               *
*                                                               *
* main.c                                                        *
* Main function for the subst program                           *
*                                                               *
* The program reads in a file ('classdef.dat') that specifies   *
* structural features used (e.g., secondary structure,          *
* solvent accessibility) and defines all possible structural    *
* environments (e.g., env1 - helix, accessible, env2 - helix,   *
* buried, env3 - strand, accessible). It reads in formatted     *
* alignments produced by the program JOY and counts amino acid  *
* replacements at structurally aligned positions in a specific  *
* environment. If there are N environments, the results can be  *
* summarized in N 21x21 amino acid substitution matrices. SUBST * 
* can produce 1) raw substitution counts, 2) conservation       *
* probability of individual amino acids and 3) log-odds         *
* substitution scores. See each source file for more details.   *
*                                                               *
* Author: Kenji Mizuguchi                                       *
*                                                               *
* Date:         5 Mar 1999                                      *
*                                                               *
****************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "utility.h"
#include "options.h"
#include "rdlist.h"
#include "subst.h"

int main (int argc, char *argv[]) {
  SCLASS sclass[MAX_FEATURE]; /* store information about residue structural classes */
  char **tem_list;
  int ntem;
  int optind;
  int nfeature;

  optind = get_options(argc, argv);
  if (optind == argc && listfilename == NULL) {
    show_help();
    exit(0);
  }

  banner();

  init_config(CLASSDEFFILE);

  nfeature = read_classdef(sclass);

  if (listfilename != NULL) {
    tem_list = rdlist(listfilename, &ntem);

/*  show_list(ntem, tem_list); */

    subst(0, ntem, tem_list, nfeature, sclass);
  }
  else {
    if (optind == argc) {
      exit(0);
    }
    subst(optind, argc, argv, nfeature, sclass);
  }
  return(0);
}
