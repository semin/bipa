/*
 * Read atom coordinates from PDB file
 *
 */


/**************START**************/

#include "gen.h"
#include "read_pdb.h"
#include "resacc.h"
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#ifdef MEMDEBUG
	#include "memdebug.h"
#endif

#define		MAX_AATYPE	26
char ShortIndex[MAX_AATYPE]=	"ABCDEFGHIJKLMNOPQRSTUVWXYZ";
char LongIndex[MAX_AATYPE][4]=	{"ALA","ASX","CYS","ASP","GLU","PHE","GLY","HIS",
				 "ILE","XXX","LYS","LEU","MET","ASN","XXX","PRO",
				 "GLN","ARG","SER","THR","UNK","VAL","TRP","XXX",
				 "TYR","GLX"};
// Expected number of atoms in each residue type
int  ExpAtomNum[MAX_AATYPE]=	{  5  ,  8  ,  6  ,  8  ,  9  , 11  ,  4  , 10  ,
				   8  ,  0  ,  9  ,  8  ,  8  ,  8  ,  0  ,  7  ,
				   9  , 11  ,  6  ,  7  ,  4  ,  7  ,  14 ,  0  ,
				  12  ,  9  };


int read_pdb(PDBREC *MyPdbRec, char *FileName_read_pdb, boolean flag_Hetatm,
		boolean flag_Water, boolean flag_UNK, boolean flag_Verbose)
{
FILE		*in_file;
int		Num_AllResidue;
int		Num_AllAtom;
int		Num_Atom;
int		getmodel;
int		model;
register int 	i;

char		TempStr[TempStr_Length]; 
char		TempChar;
char		AlterLoc;
char		ResName[PDB_RESNAME_LEN+1];
char		ResNo[PDB_RESNO_LEN+1];
char		OldResNo[PDB_RESNO_LEN+1];
char		AtomName[PDB_ATOMNAME_LEN+1];

boolean		isatom;
boolean		iswater;
boolean		ishetatm;
boolean		isnewres;
boolean		isfirstres;
boolean		isfirstatom;

PDBRESIDUE	**Array_PdbResidue;
PDBATOM		**Array_PdbAtom;

PDBRESIDUE	*MyPdbResidue;
PDBRESIDUE	*current_ptr_res; 
PDBATOM		*MyPdbAtom;
PDBATOM		*current_ptr_atom;


/* Check existence of the PDB file and open it */

if((in_file=fopen(FileName_read_pdb,"r"))==NULL) {
	fprintf(stderr,"\nPDB file %s NOT found.\n",FileName_read_pdb);
	return(ERROR_Code_FileNotFound);
	}

if(flag_Verbose)
	printf("Processing PDB file: %s\n",FileName_read_pdb);



/* Initialization */

MyPdbResidue=(PDBRESIDUE *)malloc(sizeof(PDBRESIDUE));
MyPdbAtom=(PDBATOM *)malloc(sizeof(PDBATOM));
if(MyPdbResidue==NULL || MyPdbAtom==NULL ) {
	fprintf(stderr,"\n%s%s: %s\n\n",ERROR_Found,read_pdb_Name,ERROR_MemErr);
	exit(ERROR_Code_MemErr);
	}
current_ptr_res=MyPdbResidue;
current_ptr_atom=MyPdbAtom;
current_ptr_res->flag_isterm=FALSE;
current_ptr_res->flag_isOXT=FALSE;

Num_AllResidue=0;	// store the number of residues read from the PDB file
Num_AllAtom=0;		// store the number of atoms read from the PDB file
Num_Atom=0;		// store the number of atoms of the current residue

isfirstres=TRUE;	// set to true for the first residue
isfirstatom=TRUE;	// set to true for the first atom

getmodel=MyPdbRec->getmodel;
MyPdbRec->ismultimodel=FALSE;



/* Read and parse the data */

while (fgets(TempStr,TempStr_Length,in_file)!=NULL) {
	// is multi-model ?
	if(!strncmp(TempStr,"MODEL ",6)) {
		MyPdbRec->ismultimodel=TRUE;
		sscanf(TempStr+6,"%d",&model);
		while(model!=getmodel) {	/* go to requested model */
			while (fgets(TempStr,TempStr_Length,in_file)!=NULL) {
				if(!strncmp(TempStr,"MODEL ",6)) break;
				}
			sscanf(TempStr+6,"%d",&model);
			if(feof(in_file)) {
				fprintf(stderr,"\nPDB file %s parse error. Cannot find model %d.\n",
					FileName_read_pdb, getmodel);
				exit(-1);
				}
			}
		continue;
		}
	if(MyPdbRec->ismultimodel && !strncmp(TempStr,"ENDMDL",6)) {
		fprintf(stderr,"Warning: only MODEL %d processed.\n",getmodel);
		break;
		}
		

	// is C-terminal ?
	if(!strncmp(TempStr,"TER   ",6)) {
		if(!isfirstres) {
			current_ptr_res->flag_isterm=TRUE;
			OldResNo[0]=EOS;	// Start a new residue
			}
		continue;
		}

	// is atom or hetatm ?
	isatom=!strncmp(TempStr,"ATOM  ",6);
	ishetatm=!strncmp(TempStr,"HETATM",6);
	if(!(isatom||ishetatm)) continue;

	// water or other hetatm ?
	strncpy(ResName,TempStr-1+PDB_RESNAME_POS,PDB_RESNAME_LEN);
	ResName[PDB_RESNAME_LEN]=EOS;
	iswater=!(strcmp(ResName,"WAT") && strcmp(ResName,"HOH") && strcmp(ResName,"MOH"));
	if (iswater) {
		if(!flag_Water) continue;
		}
	else	{
		if(ishetatm && (!flag_Hetatm)) continue;
		}

	// is Alternate atom ?
	AlterLoc=TempStr[PDB_ALTERLOC_POS-1];
	if(AlterLoc!=' ' && AlterLoc!='A') {
		if(flag_Verbose) {
			printf("Warning: ignore alternate atom coordinates in residue %s (AlterLoc=%c).\n",
				ResName,AlterLoc);
			}
		continue;
		}

	// is the first atom?
	if(isfirstatom) {
		isfirstatom=FALSE;
		}
	else	{	// NOT the first atom in the PDB file. Allocate memory for it.
		current_ptr_atom->next_ptr=(PDBATOM *)malloc(sizeof(PDBATOM));
		current_ptr_atom=current_ptr_atom->next_ptr;
		if(current_ptr_atom==NULL ) {
			fprintf(stderr,"\n%s%s: %s\n\n",ERROR_Found,read_pdb_Name,ERROR_MemErr);
			exit(ERROR_Code_MemErr);
			}
		}

	// read data of this atom
	strncpy(current_ptr_atom->AtomNo,TempStr-1+PDB_ATOMNO_POS,PDB_ATOMNO_LEN);
	current_ptr_atom->AtomNo[PDB_ATOMNO_LEN]=EOS;
	strncpy(current_ptr_atom->AtomName,TempStr-1+PDB_ATOMNAME_POS,PDB_ATOMNAME_LEN);
	current_ptr_atom->AtomName[PDB_ATOMNAME_LEN]=EOS;
	current_ptr_atom->AlterLoc=AlterLoc;
	current_ptr_atom->flag_isatom=isatom;
	sscanf(TempStr-1+PDB_X_POS,"%f%f%f",&(current_ptr_atom->x),
		&(current_ptr_atom->y),&(current_ptr_atom->z));

	// is mainchain atom?
	current_ptr_atom->ID_mainchain=imnch(current_ptr_atom->AtomName);

	// is polar sidechain atom?
	current_ptr_atom->ID_polarside=ipolsdch(current_ptr_atom->AtomName);

	// is OXT ?
	strcpy(AtomName,current_ptr_atom->AtomName);
	trim(AtomName);
	if(!strcmp(AtomName,"OXT"))
		current_ptr_res->flag_isOXT=TRUE;

	// is a new residue ?  is the first residue ?
	strncpy(ResNo,TempStr-1+PDB_RESNO_POS,PDB_RESNO_LEN);
	ResNo[PDB_RESNO_LEN]=EOS;
	if(isfirstres) {		// this is the first residue
		isfirstres=FALSE;
		isnewres=TRUE;
		}
	else	{
		isnewres=strcmp(OldResNo,ResNo);	// TRUE if both NOT equal
		if(isnewres) {	// NOT the first residue, allocate memory for the new residue
			current_ptr_res->Num_Atom=Num_Atom; // number of atoms in the old residue
			Num_Atom=0;
			current_ptr_res->next_ptr=(PDBRESIDUE *)malloc(sizeof(PDBRESIDUE));
			current_ptr_res=current_ptr_res->next_ptr;
			if(current_ptr_res==NULL ) {
				fprintf(stderr,"\n%s%s: %s\n\n",ERROR_Found,read_pdb_Name,ERROR_MemErr);
				exit(ERROR_Code_MemErr);
				}
			current_ptr_res->flag_isterm=FALSE;
			current_ptr_res->flag_isOXT=FALSE;
			}
		}

	// read data for the new residue
	if(isnewres) {
		isnewres=FALSE;
		strcpy(current_ptr_res->ResName,ResName);
		strcpy(current_ptr_res->ResNo,ResNo);
		current_ptr_res->Chain=TempStr[PDB_CHAIN_POS-1];
		current_ptr_res->AtomPtr=current_ptr_atom; // point to 1st atom of this residue
		Num_AllResidue++;
		strcpy(OldResNo,ResNo);

		// translate the 3-letter AA name to 1-letter AA name
		// U=UNK, B=ASX, Z=GLX, X=other unknown AA type
		TempChar='X';
		for(i=0;i<MAX_AATYPE;i++) {
			if(!strcmp(LongIndex[i],ResName)) {
				TempChar=ShortIndex[i];
				break;
				}
			}
		current_ptr_res->ShortName=TempChar;
		current_ptr_res->flag_isaminoacid=(TempChar!='X');
		current_ptr_res->flag_ishetatm=ishetatm;
		current_ptr_res->Index_Atom=Num_AllAtom;
		}
	else	{
		// double check -- slower but more reliable
		if(strcmp(current_ptr_res->ResName,ResName) && current_ptr_res->ShortName!='U') {
			fprintf(stderr,"Warning: atom %s %s has inconsistent residue name (%s / %s)",
				current_ptr_atom->AtomNo, current_ptr_atom->AtomName,
				current_ptr_res->ResName, ResName);
			fprintf(stderr," -- Using the first one\n");
			}
		}

	current_ptr_atom->ResiduePtr=current_ptr_res;	// point to the residue to which the atom belongs
	Num_Atom++;	// increase the number of atoms in the current residue
	Num_AllAtom++;

#ifdef DEBUG
	printf("%-5d: %s  %s  %c\n",Num_AllAtom,ResName,ResNo,current_ptr_res->ShortName);
#endif
	}

// finalization
current_ptr_res->next_ptr=NULL;
current_ptr_atom->next_ptr=NULL;
current_ptr_res->Num_Atom=Num_Atom;
if(Num_AllAtom<1) {
	fprintf(stderr,"\n%s%s: No atom found in the PDB file: %s\n\n",
		ERROR_Found,read_pdb_Name,FileName_read_pdb);
	return(ERROR_Code_NoAtomFound);
	}
MyPdbRec->Num_AllResidue=Num_AllResidue;
MyPdbRec->Num_AllAtom=Num_AllAtom;
		


/* Transfer the linked structure to an array. */
Array_PdbResidue=(PDBRESIDUE **)malloc(sizeof(PDBRESIDUE *)*Num_AllResidue);
Array_PdbAtom=(PDBATOM **)malloc(sizeof(PDBATOM *)*Num_AllAtom);
if(Array_PdbAtom==NULL || Array_PdbResidue==NULL) {
	fprintf(stderr,"\n%s%s: %s\n\n",ERROR_Found,read_pdb_Name,ERROR_MemErr);
	exit(ERROR_Code_MemErr);
	}
current_ptr_res=MyPdbResidue;
for(i=0;i<Num_AllResidue;i++) {
	Array_PdbResidue[i]=current_ptr_res;
	current_ptr_res=current_ptr_res->next_ptr;
	}
current_ptr_atom=MyPdbAtom;
for(i=0;i<Num_AllAtom;i++) {
	current_ptr_atom->index=i;
	Array_PdbAtom[i]=current_ptr_atom;
	current_ptr_atom=current_ptr_atom->next_ptr;
	}
MyPdbRec->Residues=Array_PdbResidue;
MyPdbRec->Atoms=Array_PdbAtom;



if(flag_Verbose)
	printf("Found %d residues and %d atoms in the PDB file %s.\n",
		Num_AllResidue,Num_AllAtom,FileName_read_pdb);	

fclose(in_file);
return(SUCCESS);

}




void free_pdb(PDBREC *MyPdbRec)
{
int i;
PDBRESIDUE	**Array_PdbResidue;
PDBATOM		**Array_PdbAtom;

Array_PdbResidue=MyPdbRec->Residues;
Array_PdbAtom=MyPdbRec->Atoms;

for(i=0;i<MyPdbRec->Num_AllResidue;i++)
	free(Array_PdbResidue[i]);
free(Array_PdbResidue);

for(i=0;i<MyPdbRec->Num_AllAtom;i++)
	free(Array_PdbAtom[i]);
free(Array_PdbAtom);

}



void print_pdb(PDBREC *MyPdbRec, char *FileName_read_pdb)
{
int i;
PDBATOM		**Array_PdbAtom;
PDBATOM		*current_ptr;

Array_PdbAtom=MyPdbRec->Atoms;

printf("\nNow print the coordinate data found in PDB file %s:\n\n", FileName_read_pdb);
for(i=0;i<MyPdbRec->Num_AllAtom;i++) {
	current_ptr=Array_PdbAtom[i];
	if(current_ptr->flag_isatom)
		printf("ATOM  ");
	else
		printf("HETATM");
	printf("%s %s%c",current_ptr->AtomNo,current_ptr->AtomName,current_ptr->AlterLoc);
	printf("%s %c%s   ",current_ptr->ResiduePtr->ResName,
		current_ptr->ResiduePtr->Chain,current_ptr->ResiduePtr->ResNo);
	printf("%8.3f%8.3f%8.3f\n",current_ptr->x,current_ptr->y,current_ptr->z);
	}
printf("\n\n");

}



void check_pdb(PDBREC *MyPdbRec)
{
int i;
int index;
int ExpAtom;
int FoundAtom;
PDBRESIDUE	**Array_PdbResidue;
PDBRESIDUE	*current_ptr;

Array_PdbResidue=MyPdbRec->Residues;

for(i=0;i<MyPdbRec->Num_AllResidue;i++) {
	current_ptr=Array_PdbResidue[i];
	index=current_ptr->ShortName-'A';
	ExpAtom=ExpAtomNum[index];
	FoundAtom=current_ptr->Num_Atom;
	if(ExpAtom==0) continue; // Unknown residue (except UNK)
	if(current_ptr->flag_isOXT) FoundAtom--;	// ignore OXT
	if(ExpAtom>FoundAtom) {
		fprintf(stderr,"Warning: too few atoms in %c position %4d",
			current_ptr->ShortName,i+1);
		fprintf(stderr," -- found %3d expected %3d\n",
			FoundAtom,ExpAtom);
		current_ptr->flag_missing=TRUE;
		}
	else if(ExpAtom<FoundAtom) {
		fprintf(stderr,"Warning: too many atoms in %c position %4d",
			current_ptr->ShortName,i+1);
		fprintf(stderr," -- found %3d expected %3d\n",
			FoundAtom,ExpAtom);
		current_ptr->flag_missing=TRUE;
		}
	else	{
		current_ptr->flag_missing=FALSE;
		}
	}
}
		

int imnch(char *AtomName)
{
extern	char MNCHATM[NM+1];

char	name[PDB_ATOMNAME_LEN+1];
char	ch;
int	i;

strcpy(name,AtomName);
trim(name);
if(strlen(name)==1) {
	ch=name[0];
	for(i=0;i<NM;i++) {
		if(ch==MNCHATM[i])
			return(i+1);
		}
	}
return(0);
}


int ipolsdch(char *AtomName)
{
extern  char POLATM[NP][5];

int	i;

for(i=0;i<NP;i++) {
	if(!strcmp(POLATM[i],AtomName)) {
		return(i+1);
		}
	}

return(0);
}
