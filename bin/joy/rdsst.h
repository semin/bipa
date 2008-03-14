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
* rdsst.h                                                                   *
* Header file for rdsst.c                                                   *
****************************************************************************/
#ifndef __rdsst
#define __rdsst

#define SST_BUFSIZE 256
#define SST_KEY "ACCESS"

typedef struct SST {
  char **resnum;
  char *chain;
  char *sequence;
  char *dssp;
  double *phi;
  double *psi;
  double *omega;
  int *ooi;
} SST;

SST *get_sst(int, char **, int *);
SST *_allocate_sst(int, int *);
int _rdsst(FILE *, int, SST, char *);
void write_sst(SST, int);

#endif
