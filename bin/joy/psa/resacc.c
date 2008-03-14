/*
 * Calculate residue accessible surface area
 *
 */


/**************START**************/

#define RESACC

#include "gen.h"
#include "read_RadiiLib.h"
#include "read_pdb.h"
#include "contact.h"
#include "resacc.h"
#include <stdio.h>
#include <string.h>
#ifdef MEMDEBUG
	#include "memdebug.h"
#endif


void resacc(RESACC2 *ResAcc2, PDBREC *MyPdbRec, MYREAL *access, int *SkipRes, boolean flag_ContactTypeSurface,
		boolean flag_UNK, boolean flag_Verbose)
{
register int 	i, j;

PDBRESIDUE      **Array_PdbResidue;
PDBRESIDUE      *current_ptr_res;
PDBATOM		**Array_PdbAtom;

int		Num_AllResidue;
int		Index_Atom;
int		ia;
int		ityp;
int		skip;

MYREAL		acc;
MYREAL		**ResAcc;
MYREAL		*ResAcc_ptr;


// CALCULATE ABSOLUTE AND PERCENTAGE ACCESSIBILITIES FOR:
//	WHOLE RESIDUE
//	NON POLAR SIDECHAIN ATOMS (INCLUDING CA)
//	POLAR SIDECHAIN ATOMS
//	TOTAL SIDECHAIN ATOMS
//	TOTAL MAINCHAIN ATOMS (EXCLUDING CA)
//
// SUMMATION FOR SIDE CHAIN includeS CA: GLY then HAS A SIDECHAIN AND THERE
// IS NO SPECIAL CASE.

// Initialization
Array_PdbResidue=MyPdbRec->Residues;
Num_AllResidue=MyPdbRec->Num_AllResidue;
Array_PdbAtom=MyPdbRec->Atoms;

ResAcc=(MYREAL **)malloc(sizeof(MYREAL *)*Num_AllResidue);
if(ResAcc==NULL) {
	fprintf(stderr,"\n%s%s: %s\n\n",ERROR_Found,resacc_Name,ERROR_MemErr);
	exit(ERROR_Code_MemErr);
	}
for(i=0;i<Num_AllResidue;i++) {
	ResAcc[i]=(MYREAL *)malloc(sizeof(MYREAL)*NUM_RESACC);
	ResAcc_ptr=ResAcc[i];
	if(ResAcc_ptr==NULL) {
		fprintf(stderr,"\n%s%s: %s\n\n",ERROR_Found,resacc_Name,ERROR_MemErr);
		exit(ERROR_Code_MemErr);
		}
	for(j=0;j<NUM_RESACC;j++) {
		ResAcc_ptr[j]=0.0;
		}
	}

if(flag_ContactTypeSurface)
	ia=0;	// contact surface
else
	ia=1;	// accessible surface



// is the current residue one of the 20 standard residue types (ASX,
// and GLX are used as ASN, and GLN respectively): UNK used to be treated
// the same as GLY, not now

skip=0;
for(i=0;i<Num_AllResidue;i++) {
	current_ptr_res=Array_PdbResidue[i];
	if(current_ptr_res->flag_ishetatm) {
		skip++;
		continue;
		}
	ityp=icode(current_ptr_res->ResName,flag_UNK);

	// if yes, process and write a line to output file, otherwise ignore it
	if(ityp>=20) {
		skip++;
		continue;
		}

	// add an area of each atom to the appropriate bin:
	ResAcc_ptr=ResAcc[i];
	Index_Atom=current_ptr_res->Index_Atom;
	for(j=Index_Atom;j<Index_Atom+current_ptr_res->Num_Atom;j++) {
		acc=access[j];
		if(Array_PdbAtom[j]->ID_mainchain > 0) {

			// it is a main chain atom:
			ResAcc_ptr[8]+=acc;
			ResAcc_ptr[0]+=acc;
			}

			// it is a polar side chain atom:
		else	{
			if(Array_PdbAtom[j]->ID_polarside > 0) {
				ResAcc_ptr[6]+=acc;
				ResAcc_ptr[4]+=acc;
				ResAcc_ptr[0]+=acc;
				}

			// it must be a non-polar side chain atom then:
			else	{
				ResAcc_ptr[6]+=acc;
				ResAcc_ptr[2]+=acc;
				ResAcc_ptr[0]+=acc;
				}
			}
		}

// get the percentages of contact areas for this residue:

	ResAcc_ptr[1]=percent(ResAcc_ptr[0], ATOTAL[ia][ityp]);
	ResAcc_ptr[3]=percent(ResAcc_ptr[2], ANPOLSIDE[ia][ityp]);
	ResAcc_ptr[5]=percent(ResAcc_ptr[4], APOLSIDE[ia][ityp]);
	ResAcc_ptr[7]=percent(ResAcc_ptr[6], ASIDE[ia][ityp]);
	ResAcc_ptr[9]=percent(ResAcc_ptr[8], AMAIN[ia][ityp]);

	}

(*SkipRes)=skip;
ResAcc2->resacc=ResAcc;

return;
}



void free_resacc(MYREAL **ResAcc, PDBREC *MyPdbRec)
{
int	i;
int	Num_AllResidue;

Num_AllResidue=MyPdbRec->Num_AllResidue;
for(i=0;i<Num_AllResidue;i++)
	free(ResAcc[i]);
free(ResAcc);
}



MYREAL percent(MYREAL x, MYREAL y)
{
if(y>0.0)
	return(100.0 * x / y);
else
	return(0.0);
}



int icode(char *ResName, boolean flag_UNK)
{
int i;

for(i=0;i<NRT+3;i++) {
	if(!strcmp(RESLIST[i],ResName))
		break;
	}

if(flag_UNK && i>=22)
	i=7;	// UNK => GLY

if(i==20)
	i=2;	// ASX => ASN
else if(i==21)
	i=5;	// GLX => GLN
else if(i>=22)
	i=20;	// XXX => GAP

return(i);
}
