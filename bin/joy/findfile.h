/*
 *
 * $Id:
 *
 * joy 5.0 release $Name:  $
 */
/****************************************************************************
* joy: A program for protein sequence-structure representation and analysis *
* Copyright (C) 1988-1997  John Overington                                  *
* Copyright (C) 1997-1999  Kenji Mizuguchi and Charlotte Deane              *
* Copyright (C) 1999-2000  Kenji Mizuguchi                                  *
*                                                                           *
* findfile.h                                                                *
* Header file for findfile.c                                                *
****************************************************************************/
#ifndef __findfile
#define __findfile

char *chkAli(char *filename);
int atm2ali(char *filename, char *base);
int pdb2ali(char *filename, char *base, char chain, short int generate_ali);
char *find_datafile(char *base, char *suffix);

#endif
