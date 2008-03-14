/*
 *  PSA  --  Protein Solvent Accessibility calculation 
 *
 */


/**************START**************/

#include "gen.h"
#include "psa.h"
#include "read_RadiiLib.h"
#include "read_pdb.h"
#include "assign_radius.h"
#include "contact.h"
#include "resacc.h"
#include "output.h"
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <unistd.h>
#include <stdlib.h>
#ifdef MEMDEBUG
	#include "memdebug.h"
#endif



psa(Psaoption *PsaOption)
{
register int	i;

int	Num_InputFile;		// number of PDB files to be processed
int	Num_SucessFile;		// number of PDB files successfully processed
int	Num_RadiiLib;		// number of residue type in the library
int	SkipRes;

MYREAL	ProbeSize;		// probe size
MYREAL	IntegrationStep;	// integration step
MYREAL	*radius;		// radius of each atom
MYREAL	*access;		// atom accessibility
MYREAL	**ResAcc;		// residue accessibility

boolean flag_Hetatm;		// include HETATM ?
boolean flag_Water;		// include Water  ?
boolean flag_ResidueAcc;	// output residue accessibility ?
boolean flag_AtomAcc;		// output atom accessibility in PDB format ?
boolean	flag_ResPerAcc;		// output residue side-chain per. accessibility in PDB format ?
boolean flag_ContactTypeSurface;// use contact type surface (otherwise use accessible type surface) ?
boolean flag_Verbose;		// verbose mode ?
boolean flag_OverwriteYes;	// Answer Yes to file overwriting confirmation ?
boolean flag_PrintScreen;	// Send output to stdout ?
boolean flag_UNK;		// Output UNK ?

char	**FileName_PDB=NULL;
char	*FileName_RadiiLib=NULL;

RADIILIB	**Array_RadiiLib;
RADIILIB2	MyRadiiLib2;
PDBREC		MyPdbRec;
RESACC2		ResAcc2;




/* Set options and initialize parameters */

Num_SucessFile		=0;
Num_InputFile		=PsaOption->Num_InputFile;
ProbeSize		=PsaOption->ProbeSize;
IntegrationStep		=PsaOption->IntegrationStep;
MyPdbRec.getmodel	=PsaOption->getmodel;
flag_Hetatm		=PsaOption->flag_Hetatm;
flag_Water		=PsaOption->flag_Water;
flag_ResidueAcc		=PsaOption->flag_ResidueAcc;
flag_AtomAcc		=PsaOption->flag_AtomAcc;
flag_ResPerAcc		=PsaOption->flag_ResPerAcc;
flag_ContactTypeSurface	=PsaOption->flag_ContactTypeSurface;
flag_Verbose		=PsaOption->flag_Verbose;
flag_OverwriteYes	=PsaOption->flag_OverwriteYes;
flag_PrintScreen	=PsaOption->flag_PrintScreen;
flag_UNK		=PsaOption->flag_UNK;
FileName_PDB		=PsaOption->FileName_PDB;
FileName_RadiiLib	=PsaOption->FileName_RadiiLib;


// Check the probe size and step value
if(ProbeSize < MIN_PROBESIZE) {
	fprintf(stderr,"Warning: probe size (%5.3f) too small, using default value (%5.3f)\n",
		ProbeSize, DEFAULT_PROBESIZE);
	ProbeSize=DEFAULT_PROBESIZE;
	}
else if(ProbeSize >= MAX_PROBESIZE) {
	fprintf(stderr,"Warning: probe size (%5.3f) too large, using default value (%5.3f)\n",
		ProbeSize, DEFAULT_PROBESIZE);
	ProbeSize=DEFAULT_PROBESIZE;
	}
if(IntegrationStep < MIN_INTEGRATIONSTEP) {
	fprintf(stderr,"Warning: step size (%7.5f) too small, using default value (%7.5f)\n",
		IntegrationStep, DEFAULT_INTEGRATIONSTEP);
	IntegrationStep=DEFAULT_INTEGRATIONSTEP;
	}
else if(IntegrationStep >= MAX_INTEGRATIONSTEP) {
	fprintf(stderr,"Warning: step size (%7.5f) too large, using default value (%7.5f)\n",
		IntegrationStep, DEFAULT_INTEGRATIONSTEP);
	IntegrationStep=DEFAULT_INTEGRATIONSTEP;
	}
	
if(flag_Verbose) {
	printf("\n");
	printf("Probe_Radius		%5.3f\n",ProbeSize);
	printf("Integration_Step	%7.5f\n",IntegrationStep);
	printf("Atom_Acc_Output		");
	if(flag_AtomAcc)
		printf("TRUE\n");
	else
		printf("FALSE\n");
	printf("Residue_Acc_Output	");
	if(flag_ResidueAcc)
		printf("TRUE\n");
	else
		printf("FALSE\n");
	printf("Include_Water		");
	if(flag_Water)
		printf("TRUE\n");
	else
		printf("FALSE\n");
	printf("Include_Hetatm		");
	if(flag_Hetatm)
		printf("TRUE\n");
	else
		printf("FALSE\n");
	printf("Accessibility_Type	");
	if(flag_ContactTypeSurface)
		printf("CONTACT\n");
	else
		printf("SURFACE\n");
	printf("\n");
	}



/* Read in the van der Wall's radii library */

read_RadiiLib(&MyRadiiLib2, &Num_RadiiLib, FileName_RadiiLib, flag_Verbose);
Array_RadiiLib=MyRadiiLib2.Array_MyRadiiLib;

#ifdef DEBUG
print_RadiiLib(Array_RadiiLib, Num_RadiiLib);
#endif

/***** Done *****/



/*****************************************************
 * Do calculation for individual PDB file one by one *
 *****************************************************/

for(i=0;i<Num_InputFile;i++) {

	// read PDB file
	if((read_pdb(&MyPdbRec,FileName_PDB[i],flag_Hetatm,flag_Water,flag_UNK,flag_Verbose))!=SUCCESS) {
		printf("Skip PDB file %s\n",FileName_PDB[i]);
		continue;
		}
	check_pdb(&MyPdbRec);
	#ifdef DEBUG
	print_pdb(&MyPdbRec, FileName_PDB[i]);
	#endif

	// assign radius for each atom
	radius=assign_radius(&MyPdbRec, Array_RadiiLib, Num_RadiiLib, flag_Verbose);
	#ifdef DEBUG
	print_radius(&MyPdbRec, radius);
	#endif

	// Calculate atom accessibility
	access=contact(&MyPdbRec, radius, ProbeSize, IntegrationStep, flag_Verbose);
	if(!flag_ContactTypeSurface) // transfer to surface type
		Contact2Acc(access, radius, ProbeSize, MyPdbRec.Num_AllAtom, flag_Verbose);

	#ifdef DEBUG
	print_contact(&MyPdbRec, access);
	#endif

	// Print Atom accessibility
	if(flag_AtomAcc) {
		WriteAtomAcc(&MyPdbRec, ProbeSize, IntegrationStep, flag_Water, flag_Hetatm,
			flag_ContactTypeSurface, flag_Verbose, &flag_OverwriteYes,
			FileName_PDB[i], access, flag_PrintScreen);
		}

	// Calculate and print Residue accessibility
	if(flag_ResidueAcc || flag_ResPerAcc) {
		resacc(&ResAcc2, &MyPdbRec, access, &SkipRes, flag_ContactTypeSurface, flag_UNK, flag_Verbose);
		ResAcc=ResAcc2.resacc;
		}
	if(flag_ResidueAcc) {
		WriteResAcc(&MyPdbRec, ProbeSize, IntegrationStep, flag_Water, flag_Hetatm,
			flag_ContactTypeSurface, flag_Verbose, &flag_OverwriteYes,
			FileName_PDB[i], ResAcc, SkipRes, flag_PrintScreen, flag_UNK);
		}
	if(flag_ResPerAcc) {
		WritePerResAcc(&MyPdbRec, ProbeSize, IntegrationStep, flag_Water, flag_Hetatm,
			flag_ContactTypeSurface, flag_Verbose, &flag_OverwriteYes,
			FileName_PDB[i], ResAcc, flag_PrintScreen);
		}
	if(flag_ResidueAcc || flag_ResPerAcc) {
		free_resacc(ResAcc, &MyPdbRec);
		}

	// finalize
	Num_SucessFile++;
	free_pdb(&MyPdbRec);
	free_radius(radius);
	free_contact(access);
	}



/* Clean up rest of the allocated memory */

free_RadiiLib(Array_RadiiLib, Num_RadiiLib);

if(flag_Verbose) {
	printf("\n\nPSA finished successfully.\nPDB files processed: %d\n",Num_SucessFile);
	printf("PDB files skipped:   %d\n\n",Num_InputFile-Num_SucessFile);
	}

return(0);
}



void init_psa(Psaoption *PsaOption)
{

PsaOption->ProbeSize			=DEFAULT_PROBESIZE;
PsaOption->IntegrationStep		=DEFAULT_INTEGRATIONSTEP;
PsaOption->getmodel			=DEFAULT_GETMODEL;
PsaOption->flag_Hetatm			=DEFAULT_HETATM;
PsaOption->flag_Water			=DEFAULT_WATER;
PsaOption->flag_ResidueAcc		=DEFAULT_RESIDUEACC;
PsaOption->flag_AtomAcc			=DEFAULT_ATOMACC;
PsaOption->flag_ResPerAcc		=DEFAULT_RESPERACC;
PsaOption->flag_ContactTypeSurface	=DEFAULT_CONTACTSURFACE;
PsaOption->flag_Verbose			=DEFAULT_VERBOSE;
PsaOption->flag_OverwriteYes		=DEFAULT_OVERWRITE;
PsaOption->flag_PrintScreen		=DEFAULT_PRINTSCREEN;
PsaOption->flag_UNK			=DEFAULT_UNK;
PsaOption->FileName_RadiiLib		=NULL;
PsaOption->Num_InputFile		=0;

return;
}

