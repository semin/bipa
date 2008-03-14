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
* atm2data.h                                                                *
* Header file for atm2data.c                                                *
****************************************************************************/
#ifndef __atm2data
#define __atm2data

char *atm2data(char *atmfile, char *base, 
	       char *suffix);
int _generate_psafile(char *atmfile, char *code);
void _generate_sstfile(char *);
void _generate_hbdfile(char *);
void _generate_coffile(char *);
int generate_datafile(char *, char *);
char *_truncate_name(char *, char *);

#endif
