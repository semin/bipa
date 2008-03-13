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
* rdlist.h                                                      *
* Header for rdlist.c                                           *
****************************************************************/
#ifndef __rdlist
#define __rdlist

#define MAXFILELEN 255
#define INITIAL_SIZE 500

char **rdlist(char *, int *);

#endif
