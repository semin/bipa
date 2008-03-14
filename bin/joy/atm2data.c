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
* atm2data.c                                                                *
* Create various datafiles (.psa, .hbd and .sst).                           *
****************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <parse.h>
#include "release.h"
#include "utility.h"
#include "joy.h"
#include "atm2data.h"
#include "gen.h"
#include "psa.h"

char *atm2data(char *atmfile, char *base, 
	       char *suffix) {
  char *filename;
  char *file_shorten;

  if (strcmp(suffix, PSA_SUFFIX) == 0) {
    _generate_psafile(atmfile, base);
  }
  else if (strcmp(suffix, SST_SUFFIX) == 0) {
    _generate_sstfile(base);
  }
  else if (strcmp(suffix, HBD_SUFFIX) == 0) {
    _generate_hbdfile(base);
  }
  else if (strcmp(suffix, COF_SUFFIX) == 0) {
    _generate_coffile(base);
  }

  filename = mstrcat(base, suffix);
  if (access(filename, R_OK) == 0) {
    return(filename);
  }
  else {
    file_shorten = _truncate_name(base, suffix);
    if (access(file_shorten, R_OK) == 0) {
      rename(file_shorten, filename);
      free(file_shorten);
    }

    if (access(filename, R_OK) == 0) {
      return(filename);
    }
    else {
      fprintf(stderr, "Failed to create %s\n", filename);
      free(filename);
    }
  }
  return(NULL);
}

char *_truncate_name(char *base, char *suffix) {
  int i = 0;
  char *newbase;
  char *filename;

  newbase = cvector(strlen(base));
  while (base+i != NULL && base[i] != '\0') {
    if (base[i] == '.') {
      newbase[i] = '\0';
      break;
    }
    newbase[i] = base[i];
    i++;
  }
    
  filename = mstrcat(newbase, suffix);
  free(newbase);
  return filename;
}

int _generate_psafile(char *atmfile, char *code) {
  Psaoption PsaOption;      /* structure for PSA options */
  char *AtmFile[1];

  init_psa(&PsaOption);     /* set default option FIRST */
  AtmFile[0] = strdup(atmfile);

  PsaOption.FileName_PDB = AtmFile;
  PsaOption.Num_InputFile = 1;

  fprintf(stderr, "Generating a .psa file from %s...\n", AtmFile[0]);

  psa(&PsaOption);
  return (1);
}

void _generate_sstfile(char *code) {
  generate_datafile("sstruc s", code);
}

void _generate_hbdfile(char *code) {
  generate_datafile("hbond", code);
}

void _generate_coffile(char *code) {
  generate_datafile("hbond -B", code);
}
  
int generate_datafile(char *command, char *code) {
  char *atmfile;
  char *s;
  atmfile = mstrcat(code, ATM_SUFFIX);

  if (access(atmfile, R_OK) != 0) {
    fprintf(stderr, "Error: %s not found\n", atmfile);
    return -1;
  }
  s = mstrcat(command, " \"");
  s = mstrcat(s, atmfile);
  s = mstrcat(s, "\"");
  fprintf(stderr, "%s\n",s);
  system(s);

  free(s);
  free(atmfile);  
  return (1);
}
