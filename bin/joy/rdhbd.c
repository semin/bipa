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
* rdhbd                                                                     *
*                                                                           *
* Reads in a .hbd file                                                      *
*                                                                           *
* Author: Kenji Mizuguchi                                                   *
*                                                                           *
* Note                                                                      *
*                                                                           *
* Date:        15 Mar 1999                                                  *
* Last update: 22 Apr 1999                                                  *
*                                                                           *
****************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <parse.h>
#include "joy.h"
#include "utility.h"
#include "findfile.h"
#include "rdhbd.h"

#ifdef DMALLOC
#include "dmalloc.h"
#endif

static HBDPAIR *last_ptr;

/***************************************************
* get_hbd
*
***************************************************/
HBD *get_hbd(int n, char **code, int *lenseq) {
  HBD *hbdall;
  HBDPAIR hbdpair;
  char *hbd_filename;
  char *cof_filename;
  FILE *fp;
  int i;
  int nhbp;
  int ncv;

  hbdall = _allocate_hbd(n, lenseq);
  (void) _initialize(hbdall, n, lenseq);
  hbdpair.next = NULL;

  for (i=0; i<n; i++) {
    hbd_filename = find_datafile(code[i], HBD_SUFFIX);
    if (hbd_filename == NULL) {
      fprintf(stderr, "Error: cannot find or create .hbd file for %s\n",
	      code[i]);
      return NULL;
    }

    fp = fopen(hbd_filename, "r");
    if (fp != NULL) {
      nhbp = _rdhbd(fp, &hbdpair);
      if (nhbp <= 0) {
	fprintf(stderr, "Warning: no hydrogen bonds read in from %s\n", hbd_filename);
      }
      fclose(fp);
    }
    else {
      fprintf(stderr, "Error: cannot open %s\n", hbd_filename);
      exit(-1);
    }
    
    if (nhbp > 0) {
/*      printf("%s\n", hbd_filename);
      list_hbdpair(nhbp, hbdpair);  
      show_assign(lenseq[i], hbdall[i]);
      printf("\n");  */

      _assign_hbd(hbdall[i], hbdpair, lenseq[i], hbd_filename);

/*      show_assign(lenseq[i], hbdall[i]);  */
    }
    free(hbd_filename);

    cof_filename = find_datafile(code[i], COF_SUFFIX);
    if (cof_filename == NULL) {
      fprintf(stderr, "Error: cannot find or create .cof file for %s\n",
	      code[i]);
      return NULL;
    }

    fp = fopen(cof_filename, "r");
    if (fp != NULL) {
      ncv = _rdcof(fp, hbdall[i]);
      fclose(fp);
    }
    else {
      fprintf(stderr, "Error: cannot open %s\n", cof_filename);
      exit(-1);
    }
    free(cof_filename);

  }
  if (dir) free(dir);
  return hbdall;
}

/***************************************************
* _rdhbd: Main function to read in a .hbd file
*
***************************************************/
int _rdhbd(FILE *in_file, HBDPAIR *hbd_ptr) {
  char line[HBD_BUFSIZE];
  int i;
  
  if (hbd_ptr->next != NULL) {
    _init_hbd(hbd_ptr);
  }
  last_ptr = NULL;
  i = 0;
  while (fgets(line, sizeof(line), in_file) != NULL) {
    if (line[0] == '#') continue;   /* skip comment lines */
    _store_hbd(line, hbd_ptr);
    i++;
  }

  if (i > 0) { /* at least one record has been read in */
    last_ptr->next = NULL;
  }
  return i;
}

/*************************************************************
* _store_hbd -- store a given record from a .hbd file in     *
*                  a linked list                             *
*                                                            *
* Parameter                                                  *
*      line -- line from input file                          *
*      hbdpair - HBDPAIR                                     *
*************************************************************/
int _store_hbd(char *line, HBDPAIR *hbd_ptr)
{

  if (last_ptr == NULL) {      /* 1st record */
    last_ptr = hbd_ptr;
  }
  else {
    last_ptr->next = (HBDPAIR *) malloc(sizeof(HBDPAIR));
    if (last_ptr->next == NULL) {
      fprintf(stderr, "Error:Out of memory\n");
      return -1;
    }
    last_ptr = last_ptr->next;
  }
  last_ptr->donor_res = line[13];
  (void) strncpy(last_ptr->donor_atm, line+15, 3);
  last_ptr->donor_atm[3] = '\0';
  last_ptr->acceptor_res = line[31];
  (void) strncpy(last_ptr->acceptor_atm, line+33, 3);  
  last_ptr->acceptor_atm[3] = '\0';
  (void) strncpy(last_ptr->type,line+37,3);
  last_ptr->type[3] = '\0';

  (void) sscanf(line,"%d",&(last_ptr->donor_idx));
  (void) sscanf(line+18,"%d",&(last_ptr->acceptor_idx));

/*  printf("%d ", last_ptr->donor_idx);
  printf("%c ", last_ptr->donor_res);
  printf("%s ", last_ptr->donor_atm);
  printf("%d ", last_ptr->acceptor_idx);
  printf("%c ", last_ptr->acceptor_res);
  printf("%s ", last_ptr->acceptor_atm);
  printf("%s ", last_ptr->type);
  printf("\n"); */

  return (1);
}

/*************************************************************
* _init_hbd-- initialization necessary for reading in a new  *
*            .hbd file.                                      *
*                                                            *
* Parameter                                                  *
*      hbdpair  -- HBDPAIR                                   *
*                              ^^^^^^^^^^^^^^^^^^            *
*************************************************************/
void _init_hbd(HBDPAIR *hbd_ptr)
{
  HBDPAIR *current_ptr;
  HBDPAIR *next_ptr;

  /* free the memory space previously allocated for HBD records */
  for (current_ptr=hbd_ptr->next; current_ptr != NULL; current_ptr=next_ptr) {
    next_ptr = current_ptr->next;
    free (current_ptr);
  }
}
/*************************************************************
* _allocate_hbd-- 
*            
*                                                            *
* Parameter                                                  *

*************************************************************/
HBD *_allocate_hbd(int nstr, int *lenseq) {
  HBD *hbd;
  int i;

  hbd = (HBD *) malloc(sizeof(HBD) * nstr);
  if (hbd == NULL) {
    fprintf(stderr, "Error: out of memory\n");
    exit(-1);
  }

  for (i=0; i<nstr; i++) {
    hbd[i].sequence = cvector(lenseq[i]+1);
    hbd[i].NH = cvector(lenseq[i]+1);
    hbd[i].CO = cvector(lenseq[i]+1);
    hbd[i].side = cvector(lenseq[i]+1);
    hbd[i].main_mainN = cvector(lenseq[i]+1);
    hbd[i].main_mainO = cvector(lenseq[i]+1);
    hbd[i].disulphide = cvector(lenseq[i]+1);
    hbd[i].main_hetero = cvector(lenseq[i]+1);
    hbd[i].main_water = cvector(lenseq[i]+1);
    hbd[i].side_hetero = cvector(lenseq[i]+1);
    hbd[i].side_water = cvector(lenseq[i]+1);
    hbd[i].cov_hetero = cvector(lenseq[i]+1);
  }
  return hbd;
}

/*************************************************************
* _initialize
*            
*                                                            *
* Parameter                                                  *

*************************************************************/
HBD *_initialize(HBD *hbd, int nstr, int *lenseq) {
  int i;
  int j;

  for (i=0; i<nstr; i++) {
    for (j=0; j<lenseq[i]; j++) {
      hbd[i].sequence[j] = 'X';
      hbd[i].NH[j] = 'F';
      hbd[i].CO[j] = 'F';
      hbd[i].side[j] = 'F';
      hbd[i].main_mainN[j] = 'F';
      hbd[i].main_mainO[j] = 'F';
      hbd[i].disulphide[j] = 'F';
      hbd[i].main_hetero[j] = 'F';
      hbd[i].main_water[j] = 'F';
      hbd[i].side_hetero[j] = 'F';
      hbd[i].side_water[j] = 'F';
      hbd[i].cov_hetero[j] = 'F';
    }
    hbd[i].sequence[lenseq[i]] = '\0';
    hbd[i].NH[lenseq[i]] = '\0';
    hbd[i].CO[lenseq[i]] = '\0';
    hbd[i].side[lenseq[i]] = '\0';
    hbd[i].main_mainN[lenseq[i]] = '\0';
    hbd[i].main_mainO[lenseq[i]] = '\0';
    hbd[i].disulphide[lenseq[i]] = '\0';
    hbd[i].main_hetero[lenseq[i]] = '\0';
    hbd[i].main_water[lenseq[i]] = '\0';
    hbd[i].side_hetero[lenseq[i]] = '\0';
    hbd[i].side_water[lenseq[i]] = '\0';
    hbd[i].cov_hetero[lenseq[i]] = '\0';
  }
  return hbd;
}

/*************************************************************
* _asign_hbd-- 
*            
*                                                            *
* Parameter                                                  *

*************************************************************/
int _assign_hbd(HBD hbd_assign, HBDPAIR hbd_record, int n,
		char *hbd_filename) {
  HBDPAIR *current_ptr;
  char type[4];
  int d_idx, a_idx;   /* sequential numbers for donor and acceptor
			 residues (ignore negative values in the sloop
			 files) */
  int index = 0;

  current_ptr = &hbd_record;

  while (1) {
    if (current_ptr == NULL) break;

    index++;
    d_idx = current_ptr->donor_idx - 1;
    a_idx = current_ptr->acceptor_idx -1;

    if ((d_idx < 0 && a_idx < 0) ||
	(d_idx >=n && a_idx >= n) ) {
      fprintf(stderr, "Warning: negative or too large indices for both donor and acceptor residues\n");
      fprintf(stderr, "         in %s (line %d)\n", hbd_filename, index);
      fprintf(stderr, "Ignore this hydrogen bond\n");
      continue;
    }

    strcpy(type, current_ptr->type);

    if (d_idx >= 0 && d_idx < n) {   /* check donor */

      if (type[1] == 'M' || type[1] == 'N' ||
	  type[1] == 'O' || type[1] == 'S') {     /* ignore h-bonds to
						   hetatom(H), water(W) or other (X)
						   groups (others include ACE, PCA and FOR) */
	hbd_assign.sequence[d_idx] = current_ptr->donor_res;
      }

      /* Skip sidechain to mainchain amide (SN or SMN),
	 as mainchain amide is always donor */

      if (strcmp(type, "SO ") == 0 ||  /* sidechain to mainchain carbonyl */
	  strcmp(type, "SMO") == 0) {

	hbd_assign.CO[d_idx] = 'T';    /* mainchain carbonyl is always acceptor
					  (see hbond.f) */
      }
      else if (strcmp(type, "SS ") == 0) {  /* sidechain to sidechain */
	hbd_assign.side[d_idx] = 'T';
      }
      else if (strcmp(type, "MM ") == 0) {  /* mainchain to mainchain */
	hbd_assign.main_mainN[d_idx] = 'T';
      }
      else if (strcmp(type, "DS ") == 0) {  /* disulphide bond */
	hbd_assign.disulphide[d_idx] = 'T';

	if (hbd_assign.sequence[d_idx] != 'C') {
	  fprintf(stderr, "Error: disulphide bond assignd for %c\n",
		  hbd_assign.sequence[d_idx]);
	  fprintf(stderr, "         (file %s line %d)\n", hbd_filename, index);
	}
      }

      /*  NOTE: The current version of hbond assigns both 
	        donor (residue)-acceptor (heterogen) and 
		donor (heterogen)-acceptor (residue) hbonds
		(residues can be either mainchain or sidechain).
		However, residue ALWAYS appears as donor and
		heterogen as acceptor.

                This is not a desirable feature (for example,
		hbplus distinguishes MS and SM) and could be
		corrected in the future (when I integrate hbond
		into joy!). At the moment,  the following code assumes
		this feature and ignores acceptor indices for
		hbonds to heterogen.
       */
	  
      else if (strcmp(type, "MH ") == 0) {  /* mainchain to heterogen */
	hbd_assign.main_hetero[d_idx] = 'T';
      }
      else if (strcmp(type, "MW ") == 0) {  /* mainchain to water */
	hbd_assign.main_water[d_idx] = 'T';
      }
      else if (strcmp(type, "SH ") == 0) {  /* sidechain to heterogen */
	hbd_assign.side_hetero[d_idx] = 'T';
      }
      else if (strcmp(type, "SW ") == 0) {  /* sidechain to water */
	hbd_assign.side_water[d_idx] = 'T';
      }
      else if (strcmp(type, "SN ") != 0  &&
	       strcmp(type, "MX ") != 0) {  /* mainchain to unknown */
	fprintf(stderr, "Warning: unknown class of H-bond %s file ignored\n", type);
	fprintf(stderr, "         (file %s line %d)\n", hbd_filename, index);
      }
    }
    else if (type[1] == 'M' || type[1] == 'N' ||
	     type[1] == 'O' || type[1] == 'S') {

      fprintf(stderr, "Warning: negative or too large donor index %d in %s (line %d)\n",
	      d_idx+1, hbd_filename, index);
    }

    if (a_idx >= 0 && a_idx < n) {   /* check acceptor */

      if (type[1] == 'M' || type[1] == 'N' ||
	  type[1] == 'O' || type[1] == 'S') {     /* ignore h-bonds to
						   hetatom(H), water(W) or other (X)
						   groups (others include ACE, PCA and FOR) */
	hbd_assign.sequence[a_idx] = current_ptr->acceptor_res;      
      }

      if (strcmp(type, "SN ") == 0 ||      /* sidechain to mainchain amide */
	  strcmp(type, "SMN") == 0) {
      
	hbd_assign.NH[a_idx] = 'T';        /* (mainchain amide is always donor) */
      }

      /* Skip sidechain to mainchain carbonyl (SO or SMO),
	 as mainchain carbonyl is always acceptor */

      else if (strcmp(type, "SS ") == 0) {  /* sidechain to sidechain */
	hbd_assign.side[a_idx] = 'T';
      }
      else if (strcmp(type, "MM ") == 0) {  /* mainchain to mainchain */
	hbd_assign.main_mainO[a_idx] = 'T';
      }
      else if (strcmp(type, "DS ") == 0) {  /* disulphide bond */
	hbd_assign.disulphide[a_idx] = 'T';

	if (hbd_assign.sequence[a_idx] != 'C') {
	  fprintf(stderr, "Error: disulphide bond assignd for %c\n",
		  hbd_assign.sequence[a_idx]);
	  fprintf(stderr, "         (file %s line %d)\n", hbd_filename, index);
	}
      }

      /* The rest is ignored (see the NOTE above ). */

      else if (strcmp(type, "SO ") != 0 && 
	       strcmp(type, "MH ") != 0 && /* mainchain to heterogen */
	       strcmp(type, "MW ") != 0 && /* mainchain to water */
	       strcmp(type, "MX ") != 0 && /* mainchain to unknown */
	       strcmp(type, "SH ") != 0 && /* sidechain to heterogen */
	       strcmp(type, "SW ") != 0)  { /* sidechain to water */
	fprintf(stderr, "Warning: unknown class of H-bond %s file ignored\n", type);
	fprintf(stderr, "         (file %s line %d)\n", hbd_filename, index);
      }
    }
    else if (type[1] == 'M' || type[1] == 'N' ||
	     type[1] == 'O' || type[1] == 'S') {

      fprintf(stderr, "Warning: negative or too large acceptor index %d in %s (line %d)\n",
	      a_idx+1, hbd_filename, index);
    }

    _disulphide_filter(&hbd_assign);

/* combine side_hetero and side (side-side) here if you merge
   these two categories (HETTOSIDE) */

/* ASP GLU filter (default off) */

    current_ptr = current_ptr->next;
  }
  return (1);
}
/*************************************************************
* _disulphide_filter
*            
* Reset all H-bonds for a disulphide-bonded Cys (cystine)    *
*
*************************************************************/
void _disulphide_filter(HBD *hbd_assign) {
  int n;
  int i;
  
  n = strlen(hbd_assign->disulphide);
  for (i=0; i<n; i++) {
    if (hbd_assign->disulphide[i] == 'T') {
      hbd_assign->NH[i] = 'F';
      hbd_assign->CO[i] = 'F';
      hbd_assign->side[i] = 'F';
      hbd_assign->side_hetero[i] = 'F';
      hbd_assign->side_water[i] = 'F';
    }
  }  
}

int isMain(char *atom_type) {
  char n[] = "N  ";
  char o[] = "O  ";
  char oxt[] = "OXT";
  
  if (strcmp(atom_type, n) == 0 ||
      strcmp(atom_type, o) == 0 ||
      strcmp(atom_type, oxt) == 0) {
    return 1;
  }
  else {
    return 0;
  }
}

int isSide(char *atom_type) {
  if (isMain(atom_type)) {
    return 0;
  }
  else {
    return 1;
  }
}
/*************************************************************
* list_hbdpair -- output the contents of the data stored in the *
*                 structure hbdpair                             *
*                 (used only for debugging)                     *
* Parameter                                                     *
*         num_record -- no of records                           *
*         hbd_record -- HBDPAIR                                  *
*************************************************************/
void list_hbdpair(int num_record, HBDPAIR hbd_record)
{
  HBDPAIR *current_ptr;
  int index=0;

  printf("no of records is %d\n",num_record);

  current_ptr = &hbd_record;

  while (1) {
    if (current_ptr == NULL) break;

    printf("%d ", current_ptr->donor_idx);
    printf("%c ", current_ptr->donor_res);
    printf("%s ", current_ptr->donor_atm);
    printf("%d ", current_ptr->acceptor_idx);
    printf("%c ", current_ptr->acceptor_res);
    printf("%s ", current_ptr->acceptor_atm);
    printf("%s ", current_ptr->type);
    printf("\n");

    current_ptr = current_ptr->next;
    index++;
  }
}

/***************************************************
* _rdcof: function to read in a .cof file (covalent bonds to heterogen
*         produced by hbond with joy4 - hbond -B)
***************************************************/
int _rdcof(FILE *in_file, HBD hbd_assign) {
  char line[HBD_BUFSIZE];
  int n=0;
  int i;
  
  while (fgets(line, sizeof(line), in_file) != NULL) {
    if (line[0] == '#') continue;   /* skip comment lines */
    (void) sscanf(line+1,"%d",&i);
    hbd_assign.cov_hetero[i-1] = 'T';
    n++;
  }
  return i;
}

/*************************************************************
* show_assign -- output the HBD assignment                      *
*                 (used only for debugging)                     *
* Parameter                                                     *
*         hbd_record -- HBDPAIR                                  *
*************************************************************/
void show_assign(int n, HBD hbd_assign)
{
  int i;
  
  for (i=0; i<n; i++) {
    printf("%c %c %c %c %c %c %c %c %c %c %c\n",
	   hbd_assign.sequence[i],
	   hbd_assign.NH[i], hbd_assign.CO[i],
	   hbd_assign.side[i], hbd_assign.main_mainN[i],
	   hbd_assign.main_mainO[i], hbd_assign.disulphide[i],
	   hbd_assign.main_hetero[i], hbd_assign.main_water[i],
	   hbd_assign.side_hetero[i], hbd_assign.side_water[i]);
  }
}
