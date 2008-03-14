/*
 * Assign radius for each atom
 *
 */


/**************START**************/

#include "gen.h"
#include "psa.h"
#include "read_RadiiLib.h"
#include "read_pdb.h"
#include "assign_radius.h"
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#ifdef MEMDEBUG
	#include "memdebug.h"
#endif


MYREAL *assign_radius(PDBREC *MyPdbRec, RADIILIB **Array_RadiiLib, int Num_RadiiLib, boolean flag_Verbose)
{
register int 	i, j, k;

PDBRESIDUE      **Array_PdbResidue;
PDBRESIDUE      *current_ptr_res;
PDBATOM		**Array_PdbAtom;
RADIILIB	*current_ptr_lib;
char		*Atom;
char		**LibAtoms;
char		**LibResidue;
char		*ResName;
int		Num_Atom;
int		Index_Atom;
int		AllResidue;
int		Index_RadiiLib;
MYREAL		*radius;

/* Initialization */
Array_PdbResidue=MyPdbRec->Residues;
AllResidue=MyPdbRec->Num_AllResidue;
Array_PdbAtom=MyPdbRec->Atoms;

radius=(MYREAL *)malloc(sizeof(MYREAL)*MyPdbRec->Num_AllAtom);
LibResidue=(char **)malloc(sizeof(char *)*Num_RadiiLib);
if(radius==NULL || LibResidue==NULL) {
	fprintf(stderr,"\n%s%s: %s\n\n",ERROR_Found,assign_radius_Name,ERROR_MemErr);
	exit(ERROR_Code_MemErr);
	}
for(Index_RadiiLib=0;Index_RadiiLib<Num_RadiiLib;Index_RadiiLib++)
	LibResidue[Index_RadiiLib]=Array_RadiiLib[Index_RadiiLib]->Residue;



/* Assign radius */

// for each residue
for(i=0;i<AllResidue;i++) {
	current_ptr_res=Array_PdbResidue[i];
	ResName=current_ptr_res->ResName;
	Num_Atom=current_ptr_res->Num_Atom;
	Index_Atom=current_ptr_res->Index_Atom;

	for(Index_RadiiLib=0;Index_RadiiLib<Num_RadiiLib;Index_RadiiLib++) {
		if(!strcmp(LibResidue[Index_RadiiLib],ResName))
			break;
		}
	if(Index_RadiiLib==Num_RadiiLib) {	// residue NOT found in the library
		for(j=0;j<Num_Atom;j++) {
			radius[Index_Atom+j]=DEFAULT_ATOMSIZE;
			}
		fprintf(stderr,"Warning: unknown residue type %s at position %d, using default radius\n",
			current_ptr_res->ResName, i+1);
		}
	else	{				// Found the residue in the library
		// for each atom in the residue
		current_ptr_lib=Array_RadiiLib[Index_RadiiLib];
		LibAtoms=current_ptr_lib->Atom;
		for(j=0;j<Num_Atom;j++) {
			Atom=Array_PdbAtom[Index_Atom+j]->AtomName;
			for(k=0;k<current_ptr_lib->Num_Atom;k++) {
				if(!strcmp(Atom,LibAtoms[k]))
					break;
				}
			if(k==current_ptr_lib->Num_Atom) {	// Atom NOT found
				radius[Index_Atom+j]=DEFAULT_ATOMSIZE;
				fprintf(stderr,"Warning: unknown atom type %s in residue %s at position %d, using default radius\n",
					Atom,current_ptr_res->ResName,i+1);
				}
			else	{				// Atom found in the library
				radius[Index_Atom+j]=current_ptr_lib->Radii[k];
				}
			}
		}
	}

free(LibResidue);

#ifdef DEBUG
	printf("%-5d: %s  %s  %c\n",Num_AllAtom,ResName,ResNo,current_ptr_res->ShortName);
#endif

return(radius);
}




void free_radius(MYREAL *radius)
{
free(radius);
}



void print_radius(PDBREC *MyPdbRec, MYREAL *radius)
{
int i;
PDBATOM		**Array_PdbAtom;
PDBATOM		*current_ptr;

Array_PdbAtom=MyPdbRec->Atoms;

printf("\nNow print the radius of each atom:\n\n");
for(i=0;i<MyPdbRec->Num_AllAtom;i++) {
	current_ptr=Array_PdbAtom[i];
	if(current_ptr->flag_isatom)
		printf("ATOM  ");
	else
		printf("HETATM");
	printf("%s %s%c",current_ptr->AtomNo,current_ptr->AtomName,current_ptr->AlterLoc);
	printf("%s %c%s   ",current_ptr->ResiduePtr->ResName,
		current_ptr->ResiduePtr->Chain,current_ptr->ResiduePtr->ResNo);
	printf("%6.3f\n",radius[i]);
	}
printf("\n\n");

}
