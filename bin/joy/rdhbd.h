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
* rdhbd.h                                                                   *
* Header file for rdhbd.c                                                   *
****************************************************************************/
#ifndef __rdhbd
#define __rdhbd

#define HBD_BUFSIZE 256

typedef struct HBDPAIR {
  int donor_idx;
  char donor_res;
  char donor_atm[4];
  int acceptor_idx;
  char acceptor_res;
  char acceptor_atm[4];
  char type[4];
  struct HBDPAIR *next;
} HBDPAIR;

typedef struct HBD {
  char *sequence;
  char *NH;
  char *CO;
  char *side;
  char *main_mainN;
  char *main_mainO;
  char *disulphide;
  char *main_hetero;
  char *main_water;
  char *side_hetero;
  char *side_water;
  char *cov_hetero;   /* covalent bond to heterogen */
} HBD;

HBD *get_hbd(int, char **, int *);
HBD *_allocate_hbd(int, int *);
HBD *_initialize(HBD *, int, int *);
int _rdhbd(FILE *, HBDPAIR *);
void _init_hbd(HBDPAIR *);
int _store_hbd(char *, HBDPAIR *);
void list_hbdpair(int, HBDPAIR );
int _assign_hbd(HBD, HBDPAIR, int, char *);
void show_assign(int, HBD);
void _disulphide_filter(HBD *);
int _rdcof(FILE *, HBD);

int isMain(char *);
int isSide(char *);

#endif
