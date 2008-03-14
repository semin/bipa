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
* findfile.c                                                                *
* Finds or creates alignment and various data files                         *
****************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <ctype.h>

#include <parse.h>
#include "release.h"
#include "utility.h"
#include "joy.h"
#include "findfile.h"
#include "atm2data.h"
#include "alimap/api_AM.h"

#define DEFAULT_PDBDIR "/BiO/Store/PDB/UNCLEAN/Structures"

char *dir = NULL; /* directory to search data files for */

char *chkAli(char *filename) {
  char *base;
  char chain = '*';
  char *newfile;
  static char *PDBDIR = NULL;
  int n;

  base = mbasename(filename, ALI_SUFFIX);
  if (base)
    return(base); /* .ali specified */

  base = mbasename(filename, ".seq");
  if (base)
    return(base); /* .seq specified */

  base = mbasename(filename, ATM_SUFFIX);
  if (base) {  /* .atm specified */
    if (atm2ali(filename, base)) {
      return(base);
    }
    else {
      fprintf(stderr,"Couldn't create .ali from .atm\n");
      return(NULL);
    }
  }
  base = mbasename(filename, ".pdb");
  if (base) {  /* .pdb specified */
    if (pdb2ali(filename, base, chain, YES)) {
      return(base);
    }
    else {
      fprintf(stderr,"Couldn't create .ali from .pdb\n");
      return(NULL);
    }
  }

  /* assuming no suffix */
  fprintf(stderr, "Assuming %s has no suffix...\n", filename);
  newfile = cvector(strlen(filename) + 5);
  strcpy(newfile, filename);
  strcat(newfile, ALI_SUFFIX); /* first try .ali */
  if (access(newfile, R_OK) == 0) {
    fprintf(stderr, "%s found\n", newfile);
    return(filename);   /* return the basename */
  }

  strcpy(newfile, filename);
  strcat(newfile, ATM_SUFFIX); /* then try .atm */
  if (access(newfile, R_OK) == 0) {
    if (atm2ali(newfile, filename)) {
      return(filename); /* return the basename */
    }
  }

  strcpy(newfile, filename);
  strcat(newfile, ".pdb"); /* then try .pdb */
  if (access(newfile, R_OK) == 0) {
    if (pdb2ali(newfile, filename, chain, YES)) {
      return(filename); /* return the basename */
    }
  }

  /* finally try the default PDB directory */
  if (strlen(filename) < 4) return(NULL);   /* Can't be a PDB code */

  fprintf(stderr, "Searching the default PDB directory for %s...\n", filename);
  if (strlen(filename) > 4) {
    chain = filename[4];
    if (chain < '0' || chain > 'z') {
      fprintf(stderr, "Incorrect chain identifier %c\n", chain);
      return(NULL);
    }
    chain = toupper(chain);
  }

  free(newfile);

  if (PDBDIR == NULL) {
    PDBDIR = getenv ("JOY_PDBDIR");
    if (PDBDIR == NULL || *PDBDIR == '\0') {
      PDBDIR = DEFAULT_PDBDIR;
    }
  }
  n = strlen(PDBDIR) + strlen(PDB_PREFIX) + 6;
  newfile = cvector(n + strlen(PDB_SUFFIX));
  strcpy(newfile, PDBDIR);
  strcat(newfile, "/");
  strcat(newfile, PDB_PREFIX);
  strncat(newfile, filename, 4);
  newfile[n-1] = '\0';
  strcat(newfile, PDB_SUFFIX);

  if (access(newfile, R_OK) == 0) {
    fprintf(stderr, "%s found\n", newfile);
    if (pdb2ali(newfile, filename, chain, YES)) {
      return(filename); /* return the basename */
    }
  }
  return(NULL);
}

int atm2ali(char *filename, char *base) {
  Alimapoption    AliMapOption;
  char *alifile;

  alifile = mstrcat(base, ALI_SUFFIX);

/* Initialize parameters */

  init_alimap(&AliMapOption);

  AliMapOption.flag_CheckPDB=FALSE;
  AliMapOption.flag_Map=FALSE;
  AliMapOption.flag_PDBFile=TRUE;
  AliMapOption.flag_PDBSingle=TRUE;
  AliMapOption.flag_SaveAtm=FALSE;
  AliMapOption.flag_OverwriteYes=TRUE;
  AliMapOption.flag_ChainBreak=TRUE;
  AliMapOption.FileName_input = filename;
  AliMapOption.FileName_save_ali= alifile;
  AliMapOption.flag_ChainBreak = TRUE;

  runalimap(&AliMapOption);

  if (access(alifile, R_OK) == 0) {
    fprintf(stderr, "%s created\n", alifile);
  }
  else {
    return 0;
  }
  return(1);
}

/*
 * generate .atm and (optionally) .ali from .pdb file
 */
int pdb2ali(char *filename, /* input .pdb file */
	    char *base, char chain,
	    short int generate_ali) {
  Alimapoption    AliMapOption;
  char *atmfile;
  char *alifile;

  atmfile = mstrcat(base, ATM_SUFFIX);
  alifile = mstrcat(base, ALI_SUFFIX);

/* Initialize parameters */

  init_alimap(&AliMapOption);

  AliMapOption.flag_CheckPDB=TRUE;
  AliMapOption.flag_Map=FALSE;
  AliMapOption.flag_PDBFile=TRUE;
  AliMapOption.flag_PDBSingle=TRUE;
  AliMapOption.flag_SaveAtm=TRUE;
  AliMapOption.flag_OverwriteYes=TRUE;
  AliMapOption.chainID=chain;
  AliMapOption.FileName_input = filename;
  AliMapOption.flag_SaveAli = FALSE;
  AliMapOption.FileName_save_atm = atmfile;
  /*  AliMapOption.FileName_save_ali= alifile; */
  /*  AliMapOption.flag_ChainBreak = TRUE; */

  runalimap(&AliMapOption);

  if (access(atmfile, R_OK) == 0) {
    fprintf(stderr, "%s created\n", atmfile);
  }
  else {
    return 0;
  }

  if (generate_ali == NO) return(1);

  if (atm2ali(atmfile, base)) {
    return(1);
  }
  return(0);
}

char *find_datafile(char *base, char *suffix) {
  char *ch;
  char *filename;
  char chain = '*';
  char *atmfile=NULL;
  char *pdbfile=NULL;
  char *atmfile_remote=NULL;

  if (strcmp(VS(V_DIR), "-") != 0 && /* search directory specified */  
      dir == NULL) {
    if (VS(V_DIR)[strlen(VS(V_DIR))-1] != '/') {
      dir = mstrcat(expand_path(VS(V_DIR)), "/");
    }
    else {
      dir = strdup(expand_path(VS(V_DIR)));
    }
  }
  
  if (dir) { /* 1) search specified directory for datafile */
    ch = mstrcat(dir, base);
    filename = mstrcat(ch, suffix);
    free(ch);
    if (access(filename, R_OK) == 0) { /* datafile found in the
 					  specified directory */
      return(filename);
    }
    free(filename);
  }

  /* 2) check the current directory */
  
  filename = mstrcat(base, suffix);
  if (access(filename, R_OK) == 0) { /* datafile found in the
					current directory */
    return(filename);
  }

  /* need to create the datafile */
  free(filename);

  if (dir) { /* 3) search specified directory for .atm and .pdb files */
    ch = mstrcat(dir, base);
    atmfile_remote = mstrcat(ch, ATM_SUFFIX);
    atmfile = mstrcat(base, ATM_SUFFIX);
    if (access(atmfile_remote, R_OK) == 0) { /* .atm file found in the
						specified directory */

      if (symlink(atmfile_remote, atmfile) == 0) {

	/* First, create a symbolic link to .atm in the current directory.
	   Otherwise, HBOND and SSTRUC may not work. */

	filename = atm2data(atmfile, base, suffix);
	unlink (atmfile);
      }
      else {
	fprintf(stderr, "Failed to create a symbolic to %s in the current directory",
		atmfile_remote);
	filename = atm2data(atmfile_remote, base, suffix);
      }

      if (filename) {
	free(atmfile_remote);
	free(atmfile);
	free(ch);
	return(filename); /* successfully created */
      }
      fprintf(stderr, "Failed to create %s file from %s\n",
	      suffix, atmfile);
    }
    pdbfile = mstrcat(ch, ".pdb");
    free(atmfile_remote);
    free(atmfile);
    free(ch);
    atmfile = mstrcat(base, ATM_SUFFIX);
    if (access(pdbfile, R_OK) == 0) { /* .pdb file found in the
					 specified directory */

      if (! pdb2ali(pdbfile, base, chain, NO)) {
	fprintf(stderr, "Failed to create %s from %s\n",
		atmfile, pdbfile);
      }
      else {
	filename = atm2data(atmfile, base, suffix);
	if (filename) {
	  free(pdbfile);
	  free(atmfile);
	  return(filename); /* successfully created */
	}
	fprintf(stderr, "Failed to create %s file from %s\n",
		suffix, atmfile);
	free(atmfile);
	return(NULL);
      }
    }
  }

  /* 4) check the current directory */

  free(atmfile);
  atmfile = mstrcat(base, ATM_SUFFIX);
  if (access(atmfile, R_OK) == 0) { /* .atm file found in the
				       current directory */
    filename = atm2data(atmfile, base, suffix);
    if (filename) {
      free(atmfile);
      return(filename); /* successfully created */
    }
    fprintf(stderr, "Failed to create %s file from %s\n",
	    suffix, atmfile);
    free(atmfile);
    return(NULL);
  }

  pdbfile = mstrcat(base, ".pdb");
  if (access(pdbfile, R_OK) == 0) { /* .pdb file found in the
				       current directory */

    if (! pdb2ali(pdbfile, base, chain, NO)) {
      fprintf(stderr, "Failed to create %s from %s\n",
	      atmfile, pdbfile);
      free(pdbfile);
      return(NULL);
    }
    free(pdbfile);
    filename = atm2data(atmfile, base, suffix);
    if (filename) {
      free(atmfile);
      return(filename); /* successfully created */
    }
    fprintf(stderr, "Failed to create %s file from %s\n",
	    suffix, atmfile);
  }
  else {
    fprintf(stderr, "Neither %s nor %s can be found.\n",
	    pdbfile, atmfile);
    fprintf(stderr, "Cannot create %s file\n", suffix);
  }
  return(NULL);
}
