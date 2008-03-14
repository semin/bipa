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
* joy.h                                                                     *
* General header file                                                       *
****************************************************************************/
#ifndef __joy
#define __joy

#define YES 1
#define NO 0

/*#define DEFAULT_PDBDIR "/upbdata/pdb/allpdb"*/
#define PDB_PREFIX "pdb"
#define PDB_SUFFIX ".ent"

#define ATM_SUFFIX ".atm"
#define ALI_SUFFIX ".ali"
#define PSA_SUFFIX ".psa"
#define SST_SUFFIX ".sst"
#define HBD_SUFFIX ".hbd"
#define COF_SUFFIX ".cof"

/* global variables */

extern char *dir;   /* directory to search data files for */

#endif
