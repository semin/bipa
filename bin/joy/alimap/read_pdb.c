/*
 * Read atom coordinates from PDB file
 *
 */


/**************START**************/

#include "read_pdb.h"
#include <string.h>
#include <unistd.h>
#include <stdlib.h>
#include <ctype.h>
#ifdef MEMDEBUG
	#include "memdebug.h"
#endif


#define		MAX_AATYPE	26
static char ShortIndex[MAX_AATYPE]=	"ABCDEFGHIJKLMNOPQRSTUVWXYZ";
static char LongIndex[MAX_AATYPE][4]=	{"ALA","ASX","CYS","ASP","GLU","PHE","GLY","HIS",
				 "ILE","XXX","LYS","LEU","MET","ASN","XXX","PRO",
				 "GLN","ARG","SER","THR","XXX","VAL","TRP","XXX",
				 "TYR","GLX"};
// Expected number of atoms in each residue type
static int  ExpAtomNum[MAX_AATYPE]=	{  5  ,  8  ,  6  ,  8  ,  9  , 11  ,  4  , 10  ,
				   8  ,  0  ,  9  ,  8  ,  8  ,  8  ,  0  ,  7  ,
				   9  , 11  ,  6  ,  7  ,  0  ,  7  ,  14 ,  0  ,
				  12  ,  9  };


int read_pdb_AM(PDBREC_AM *MyPdbRec, FILE *in_file, boolean flag_Verbose)
{

int		Num_AllResidue;
int		Num_AllAtom;
int		Num_Atom;
int		getmodel;
int		model;
register int 	i;

char		TempStr[TempStr_Length]; 
char		TempChar;
char		chainID;
char		OldChain;
char		Chain;
char		AlterLoc;
char		ResName[PDB_RESNAME_LEN+1];
char		ResNo[PDB_RESNO_LEN+1];
char		OldResNo[PDB_RESNO_LEN+1];
char		OldResName[PDB_RESNAME_LEN+1];
char		AtomName[PDB_ATOMNAME_LEN+1];

boolean		isatom;
boolean		isnewres;
boolean		isfirstres;
boolean		isfirstatom;

PDBRESIDUE_AM	**Array_PdbResidue;
PDBATOM_AM		**Array_PdbAtom;

PDBRESIDUE_AM	*MyPdbResidue;
PDBRESIDUE_AM	*current_ptr_res; 
PDBATOM_AM		*MyPdbAtom;
PDBATOM_AM		*current_ptr_atom;



/* Initialization */

MyPdbResidue=(PDBRESIDUE_AM *)malloc(sizeof(PDBRESIDUE_AM));
MyPdbAtom=(PDBATOM_AM *)malloc(sizeof(PDBATOM_AM));
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
chainID=MyPdbRec->chainID;
MyPdbRec->ismultimodel=FALSE;
OldChain=EOS;
OldResNo[0]=EOS;
OldResName[0]=EOS;



/* Get header information */

GetPDBHeader(MyPdbRec,in_file,flag_Verbose);


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
				rewind(in_file);
				while (fgets(TempStr,TempStr_Length,in_file)!=NULL && strncmp(TempStr,"MODEL ",6));
				sscanf(TempStr+6,"%d",&model);
				if(flag_Verbose)
					printf("\nCannot find model %d. Using the first model (model %d).\n",getmodel,model);
				MyPdbRec->getmodel=getmodel=model;
				break;
				}
			}
		continue;
		}
	if(MyPdbRec->ismultimodel && !strncmp(TempStr,"ENDMDL",6)) {
		if(flag_Verbose)
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

	// is atom ?
	isatom=!strncmp(TempStr,"ATOM  ",6);
	if(!isatom) continue;

	// is the chain we want (chainID) ?
	Chain=TempStr[PDB_CHAIN_POS-1];
	if(chainID!='*') {	// '*' means we accept all chains
		if(Chain!=chainID)
			continue;
		}

	// get residue name
	strncpy(ResName,TempStr-1+PDB_RESNAME_POS,PDB_RESNAME_LEN);
	ResName[PDB_RESNAME_LEN]=EOS;

	// is Alternate atom ?
	AlterLoc=TempStr[PDB_ALTERLOC_POS-1];

	// is the first atom?
	if(isfirstatom) {
		isfirstatom=FALSE;
		}
	else	{	// NOT the first atom in the PDB file. Allocate memory for it.
		current_ptr_atom->next_ptr=(PDBATOM_AM *)malloc(sizeof(PDBATOM_AM));
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
	current_ptr_atom->isValid=TRUE;
	sscanf(TempStr-1+PDB_X_POS,"%f%f%f",&(current_ptr_atom->x),
		&(current_ptr_atom->y),&(current_ptr_atom->z));
	if(strcmp(current_ptr_atom->AtomName," CA "))
		current_ptr_atom->isCalpha=FALSE;
	else
		current_ptr_atom->isCalpha=TRUE;

	// is OXT ?
	strcpy(AtomName,current_ptr_atom->AtomName);
	trim_AM(AtomName);
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
		isnewres=( strcmp(OldResNo,ResNo) || strcmp(OldResName,ResName) ||
			OldChain!=Chain );	// TRUE if both NOT equal
		if(isnewres) {	// NOT the first residue, allocate memory for the new residue
			current_ptr_res->Num_Atom_Valid=current_ptr_res->Num_Atom=Num_Atom; // number of atoms in the old residue
			Num_Atom=0;
			current_ptr_res->next_ptr=(PDBRESIDUE_AM *)malloc(sizeof(PDBRESIDUE_AM));
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
		strcpy(OldResName,ResName);
		OldChain=Chain;

		// translate the 3-letter AA name to 1-letter AA name
		// B=ASX, Z=GLX, X=other unknown AA type
		TempChar='X';
		for(i=0;i<MAX_AATYPE;i++) {
			if(!strcmp(LongIndex[i],ResName)) {
				TempChar=ShortIndex[i];
				break;
				}
			}
		current_ptr_res->ShortName=TempChar;
		current_ptr_res->flag_isaminoacid=(TempChar!='X');
		current_ptr_res->Index_Atom=Num_AllAtom;
		}
	else	{
		// double check -- slower but more reliable
		if(strcmp(current_ptr_res->ResName,ResName)) {
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
current_ptr_res->Num_Atom_Valid=current_ptr_res->Num_Atom=Num_Atom;
if(Num_AllAtom<1) {
	fprintf(stderr,"\n%s%s: No atom found in the PDB file\n\n",
		ERROR_Found,read_pdb_Name);
	return(ERROR_Code_NoAtomFound);
	}
MyPdbRec->Num_AllResidue=Num_AllResidue;
MyPdbRec->Num_AllAtom=Num_AllAtom;
		


/* Transfer the linked structure to an array. */
Array_PdbResidue=(PDBRESIDUE_AM **)malloc(sizeof(PDBRESIDUE_AM *)*Num_AllResidue);
Array_PdbAtom=(PDBATOM_AM **)malloc(sizeof(PDBATOM_AM *)*Num_AllAtom);
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


/* record start residue and end residue */
strcpy((MyPdbRec->description).start_r,Array_PdbResidue[0]->ResNo);
(MyPdbRec->description).start_c=Array_PdbResidue[0]->Chain;
strcpy((MyPdbRec->description).end_r,Array_PdbResidue[Num_AllResidue-1]->ResNo);
(MyPdbRec->description).end_c=Array_PdbResidue[Num_AllResidue-1]->Chain;


if(flag_Verbose)
	printf("Found %d residues and %d atoms in the PDB file.\n",
		Num_AllResidue,Num_AllAtom);	

return(SUCCESS);

}




void free_pdb_AM(PDBREC_AM *MyPdbRec)
{
int i;
PDBRESIDUE_AM	**Array_PdbResidue;
PDBATOM_AM		**Array_PdbAtom;

Array_PdbResidue=MyPdbRec->Residues;
Array_PdbAtom=MyPdbRec->Atoms;

for(i=0;i<MyPdbRec->Num_AllResidue;i++)
	free(Array_PdbResidue[i]);
free(Array_PdbResidue);

for(i=0;i<MyPdbRec->Num_AllAtom;i++)
	free(Array_PdbAtom[i]);
free(Array_PdbAtom);

}



void print_pdb_AM(PDBREC_AM *MyPdbRec, char *FileName_read_pdb)
{
int i;
PDBATOM_AM		**Array_PdbAtom;
PDBATOM_AM		*current_ptr;

Array_PdbAtom=MyPdbRec->Atoms;

printf("\nNow print the coordinate data found in PDB file %s:\n\n", FileName_read_pdb);
for(i=0;i<MyPdbRec->Num_AllAtom;i++) {
	current_ptr=Array_PdbAtom[i];
	printf("ATOM  ");
	printf("%s %s%c",current_ptr->AtomNo,current_ptr->AtomName,current_ptr->AlterLoc);
	printf("%s %c%s   ",current_ptr->ResiduePtr->ResName,
		current_ptr->ResiduePtr->Chain,current_ptr->ResiduePtr->ResNo);
	printf("%8.3f%8.3f%8.3f\n",current_ptr->x,current_ptr->y,current_ptr->z);
	}
printf("\n\n");
}



void print_pdb_valid(PDBREC_AM *MyPdbRec, char *FileName_read_pdb)
{
int i;
PDBATOM_AM		**Array_PdbAtom;
PDBATOM_AM		*current_ptr;

Array_PdbAtom=MyPdbRec->Atoms;

printf("\nNow print the coordinate data found in PDB file %s:\n\n", FileName_read_pdb);
for(i=0;i<MyPdbRec->Num_AllAtom;i++) {
	current_ptr=Array_PdbAtom[i];
	if(!(current_ptr->isValid))
		continue;
	printf("ATOM  ");
	printf("%s %s%c",current_ptr->AtomNo,current_ptr->AtomName,current_ptr->AlterLoc);
	printf("%s %c%s   ",current_ptr->ResiduePtr->ResName,
		current_ptr->ResiduePtr->Chain,current_ptr->ResiduePtr->ResNo);
	printf("%8.3f%8.3f%8.3f\n",current_ptr->x,current_ptr->y,current_ptr->z);
	}
printf("\n\n");
}



void check_pdb_AM(PDBREC_AM *MyPdbRec, boolean flag_Verbose)
{

if(flag_Verbose)
	printf("Checking coordinate range ...\n");
check_XYZRange(MyPdbRec,flag_Verbose);

if(MyPdbRec->flag_DelAltPos) {
	if(flag_Verbose)
		printf("Checking alternative atoms ...\n");
	check_AltPos(MyPdbRec,flag_Verbose);
	}

if(MyPdbRec->flag_DelHAtom) {
	if(flag_Verbose)
		printf("Checking hydrogen atoms ...\n");
	check_hydrogen(MyPdbRec,flag_Verbose);
	}

if(MyPdbRec->flag_DelMissMCA) {
	if(flag_Verbose)
		printf("Checking completion of mainchain coordinates ...\n");
	check_MainChainAtom(MyPdbRec,flag_Verbose);
	}

if(flag_Verbose)
	printf("Now performing the final checking ...\n");
check_ResAtomNum(MyPdbRec,flag_Verbose);

}



void check_hydrogen(PDBREC_AM *MyPdbRec, boolean flag_Verbose)
{
int		i;
char		ch1, ch2;
PDBATOM_AM		**Array_PdbAtom;
PDBATOM_AM		*current_ptr;

Array_PdbAtom=MyPdbRec->Atoms;

for(i=0;i<MyPdbRec->Num_AllAtom;i++) {
	current_ptr=Array_PdbAtom[i];
	ch1=current_ptr->AtomName[1];
	ch2=current_ptr->AtomName[2];
	if((ch1=='H' || ch1=='Q' || (ch1=='D' && ch2=='D')) && current_ptr->isValid) {	// hydrogen
		current_ptr->ResiduePtr->Num_Atom_Valid--;
		current_ptr->isValid=FALSE;
		if(flag_Verbose) {
			printf("Warning: hydrogen atom record %s %s removed from residue %s %c%s\n",
				current_ptr->AtomNo,current_ptr->AtomName,current_ptr->ResiduePtr->ResName,
				current_ptr->ResiduePtr->Chain,current_ptr->ResiduePtr->ResNo);
			}
		}
	}
}



void check_XYZRange(PDBREC_AM *MyPdbRec, boolean flag_Verbose)
{
int		i;
float		temp1, temp2, temp3;
PDBATOM_AM		**Array_PdbAtom;
PDBATOM_AM		*current_ptr;

Array_PdbAtom=MyPdbRec->Atoms;

for(i=0;i<MyPdbRec->Num_AllAtom;i++) {
	current_ptr=Array_PdbAtom[i];
	if(!(current_ptr->isValid))
		continue;
	temp1=current_ptr->x;
	temp2=current_ptr->y;
	temp3=current_ptr->z;
	if(temp1<MIN_XYZ || temp1>MAX_XYZ ||
	   temp2<MIN_XYZ || temp2>MAX_XYZ ||
	   temp3<MIN_XYZ || temp3>MAX_XYZ ) {
		current_ptr->ResiduePtr->Num_Atom_Valid--;
		current_ptr->isValid=FALSE;
		if(flag_Verbose) {
			printf("Warning: atom %s %s removed from residue %s %c%s due to strange coordinates\n",
				current_ptr->AtomNo,current_ptr->AtomName,current_ptr->ResiduePtr->ResName,
				current_ptr->ResiduePtr->Chain,current_ptr->ResiduePtr->ResNo);
			}
		}
	}
}



void check_AltPos(PDBREC_AM *MyPdbRec, boolean flag_Verbose)
{
int		i, j, k;
int		index;
PDBRESIDUE_AM      **Array_PdbResidue;
PDBRESIDUE_AM      *current_resptr;
PDBATOM_AM         **Array_PdbAtom;

Array_PdbAtom=MyPdbRec->Atoms;
Array_PdbResidue=MyPdbRec->Residues;

for(i=0;i<MyPdbRec->Num_AllResidue;i++) {
	current_resptr=Array_PdbResidue[i];
	index=current_resptr->Index_Atom;
	for(j=0;j<current_resptr->Num_Atom-1;j++) {
		if(!(Array_PdbAtom[index+j]->isValid))  /* --jiye || Array_PdbAtom[index+j]->AlterLoc==' ') */
			continue;
		for(k=j+1;k<current_resptr->Num_Atom;k++) {
			if(!Array_PdbAtom[index+k]->isValid)
				continue;
			if(!strcmp(Array_PdbAtom[index+j]->AtomName,Array_PdbAtom[index+k]->AtomName)) {
				current_resptr->Num_Atom_Valid--;
				Array_PdbAtom[index+k]->isValid=FALSE;
				if(flag_Verbose) {
					printf("Warning: alternative atom %s %s%c removed from residue %s %c%s\n",
						Array_PdbAtom[index+k]->AtomNo,Array_PdbAtom[index+k]->AtomName,
						Array_PdbAtom[index+k]->AlterLoc,current_resptr->ResName,
						current_resptr->Chain,current_resptr->ResNo);
					}
				}
			}
		}
	}
}




void check_ResAtomNum(PDBREC_AM *MyPdbRec, boolean flag_Verbose)
{
int		i;
int		index;
int		ExpAtom;
int		FoundAtom;
PDBRESIDUE_AM	**Array_PdbResidue;
PDBRESIDUE_AM	*current_ptr;

Array_PdbResidue=MyPdbRec->Residues;

for(i=0;i<MyPdbRec->Num_AllResidue;i++) {
	current_ptr=Array_PdbResidue[i];
	index=current_ptr->ShortName-'A';
	ExpAtom=ExpAtomNum[index];
	FoundAtom=current_ptr->Num_Atom_Valid;
	if(ExpAtom==0) continue; // Unknown residue
	if(current_ptr->flag_isOXT) FoundAtom--;	// ignore OXT
	if(FoundAtom<1) {				// all atoms removed
		current_ptr->flag_missing=TRUE;
		continue;
		}
	if(ExpAtom>FoundAtom) {
		current_ptr->flag_missing=TRUE;
		if(flag_Verbose) {
			printf("Warning: too few atoms in %s %c%s",
				current_ptr->ResName,current_ptr->Chain,current_ptr->ResNo);
			printf(" -- found %3d expected %3d\n",
				FoundAtom,ExpAtom);
			}
		}
	else if(ExpAtom<FoundAtom) {
		current_ptr->flag_missing=TRUE;
		if(flag_Verbose) {
			printf("Warning: too many atoms in %s %c%s",
				current_ptr->ResName,current_ptr->Chain,current_ptr->ResNo);
			printf(" -- found %3d expected %3d\n",
				FoundAtom,ExpAtom);
			}
		}
	else	{
		current_ptr->flag_missing=FALSE;
		}
	}
}
		

void check_MainChainAtom(PDBREC_AM *MyPdbRec, boolean flag_Verbose)
{
int		i, j;
int		index;
char		*seq_ptr;
PDBRESIDUE_AM      **Array_PdbResidue;
PDBRESIDUE_AM      *current_resptr;
PDBATOM_AM         **Array_PdbAtom;
boolean		flag_C;
boolean		flag_N;
boolean		flag_O;
boolean		flag_CA;
boolean		flag_FullMainChain;

Array_PdbAtom=MyPdbRec->Atoms;
Array_PdbResidue=MyPdbRec->Residues;

for(i=0;i<MyPdbRec->Num_AllResidue;i++) {
	current_resptr=Array_PdbResidue[i];
	if(current_resptr->ShortName=='X') {
		current_resptr->flag_missingMCA=FALSE;
		continue;
		}
	index=current_resptr->Index_Atom;
	flag_C=FALSE;
	flag_N=FALSE;
	flag_O=FALSE;
	flag_CA=FALSE;
	for(j=0;j<current_resptr->Num_Atom;j++) {
		if(!Array_PdbAtom[index+j]->isValid)
			continue;
		seq_ptr=Array_PdbAtom[index+j]->AtomName;
		if(!strcmp(seq_ptr," C  "))
			flag_C=TRUE;
		else if(!strcmp(seq_ptr," N  "))
			flag_N=TRUE;
		else if(!strcmp(seq_ptr," O  ") || !strcmp(seq_ptr," OXT"))
			flag_O=TRUE;
		else if(!strcmp(seq_ptr," CA "))
			flag_CA=TRUE;
		}
	flag_FullMainChain=flag_C && flag_N && flag_O && flag_CA;
	current_resptr->flag_missingMCA=!flag_FullMainChain;
	if(!flag_FullMainChain) {
		current_resptr->Num_Atom_Valid=0;
		for(j=0;j<current_resptr->Num_Atom;j++)
			Array_PdbAtom[index+j]->isValid=FALSE;
		if(flag_Verbose) {
			printf("Warning: residue %s %c%s removed due to incomplete mainchain coordinates\n",
				current_resptr->ResName,current_resptr->Chain,current_resptr->ResNo);
			}
		}
	}
}



boolean GetPDBHeader(PDBREC_AM *MyPdbRec, FILE *in_file, boolean flag_Verbose)
{
#define		MAX_POOL	50

PDBDESC		*description;
char		MyChain;
char		*seq_ptr;
char		TempStr[TempStr_Length+1];
char		Pool[MAX_POOL][MAX_SeqInfoLength];
char		ch;
int		PoolID;
int		count_MOL_ID;
int		count_MOLECULE;
int		count_CHAIN;
int		count_SCIENTIFIC;
int		count_COMMON;
int		left, right;
int		left_pos=0, right_pos=0;
int		i, j;
int		molID=1;
int		index;
float		TempFloat;
boolean		flag_found;


description=&(MyPdbRec->description);


/* find the header and retrieve the PDB code */

rewind(in_file);
while (fgets(TempStr,TempStr_Length,in_file)!=NULL) {
	if(!strncmp(TempStr,"HEADER",6)) {
		seq_ptr=description->code;
		for(i=0;i<PDB_IDCODE_LEN;i++)
			seq_ptr[i]=TempStr[i+PDB_IDCODE_POS-1];
		seq_ptr[i]=EOS;
		break;
		}
	}

/******* done *******/



/* continue to the COMPND section to get protein name */

/* first we store all COMPND lines in the pool */
rewind(in_file);
while (fgets(TempStr,TempStr_Length,in_file)!=NULL) {
	if(!strncmp(TempStr,"COMPND",6))
		break;
	}
if(!strncmp(TempStr,"COMPND",6)) {	/* we found COMPND section */
	/* Now we are at the first line of COMPND section.
   	Keep reading until no COMPND tag found. */
	PoolID=0;
	while (!strncmp(TempStr,"COMPND",6)) {		/* still in COMPND section */
		seq_ptr=Pool[PoolID];
		strcpy(seq_ptr,TempStr+PDB_COMPND_POS-1);
		seq_ptr[PDB_COMPND_LEN]=EOS;
		trimalnum(seq_ptr);
		PoolID++;
		if(fgets(TempStr,TempStr_Length,in_file)==NULL)
			break;
		}
	/* Check the pool to see whether three tags are available*/
	count_MOL_ID=0;
	count_MOLECULE=0;
	count_CHAIN=0;
	for(i=0;i<PoolID;i++) {
		seq_ptr=Pool[i];
		if(strstr(seq_ptr,"MOL_ID:")!=NULL)
			count_MOL_ID++;
		else if(strstr(seq_ptr,"MOLECULE:")!=NULL)
			count_MOLECULE++;
		else if(strstr(seq_ptr,"CHAIN:")!=NULL && strstr(seq_ptr,"NULL")==NULL)
			count_CHAIN++;	/* CHAIN tag which is not followed by 'NULL' */
		}
	if(count_MOLECULE==0) {	/* seems to be an old PDB file, take protein name from 1st line */
		molID=1;
		strcpy(description->ProteinName,Pool[0]);
		}
	else	{
		if(count_MOL_ID<2) {	/* find the first MOLECULE tag and copy the protein name */
			molID=1;
			for(i=0;i<PoolID;i++) {
				if(strstr(Pool[i],"MOLECULE:")!=NULL) {
					strcpy(description->ProteinName,Pool[i]+strlen("MOLECULE:"));
					trimalnum(description->ProteinName);
					break;
					}
				}
			}
		else	{	/* more than 1 MOL_ID tag found. If no 'chain' specified, get the first MOLECULE */
			if(MyPdbRec->chainID=='*' || count_CHAIN<1) {
				molID=1;
				for(i=0;i<PoolID;i++) {
					if(strstr(Pool[i],"MOLECULE:")!=NULL) {
						strcpy(description->ProteinName,Pool[i]+strlen("MOLECULE:"));
						trimalnum(description->ProteinName);
						break;
						}
					}
				}
			else	{	/* find correct MOL_ID for the specific chain */
				MyChain=toupper(MyPdbRec->chainID);
				molID=0;
				for(i=0;i<PoolID;i++) {
					seq_ptr=Pool[i];
					flag_found=FALSE;
					if(strstr(seq_ptr,"CHAIN:")!=NULL && strstr(seq_ptr,"NULL")==NULL) {
						molID++;
						flag_found=FALSE;
						for(j=strlen("CHAIN:");j<strlen(seq_ptr);j++) {
							if(MyChain==seq_ptr[j]) {
								flag_found=TRUE;
								break;
								}
							}
						if(flag_found)
							break;
						}
					}
				j=0;
				for(i=0;i<PoolID;i++) {
					if(strstr(Pool[i],"MOLECULE:")!=NULL) {
						j++;
						if(j==molID)
							break;
						}
					}
				strcpy(description->ProteinName,Pool[i]+strlen("MOLECULE:"));
				trimalnum(description->ProteinName);
				}
			}
		}

	/* format it */
	seq_ptr=description->ProteinName;
	for(i=0;i<strlen(seq_ptr);i++)
		seq_ptr[i]=tolower(seq_ptr[i]);
		
	if((seq_ptr=strstr(description->ProteinName,"complex"))!=NULL) {
		seq_ptr[0]=EOS;
		trimalnum(description->ProteinName);
		}

	if((seq_ptr=strstr(description->ProteinName,"mutant"))!=NULL) {
		seq_ptr[0]=EOS;
		trimalnum(description->ProteinName);
		}

	if((seq_ptr=strstr(description->ProteinName,"recombinant"))!=NULL) {
		seq_ptr[0]=EOS;
		trimalnum(description->ProteinName);
		}

	seq_ptr=description->ProteinName;
	for(i=strlen(seq_ptr)-1;i>=0;i--) {
		ch=seq_ptr[i];
		if(isalnum(ch))
			break;
		if(ch==')') {
			for(j=i-1;j>=0;j--) {
				if(seq_ptr[j]=='(') {	/* delete (...) */
					if(j!=0) {
						seq_ptr[j]=EOS;
						i=j;
						}
					break;
					}
				}
			if(j<0) {	/* '(' not found */
				seq_ptr[i]=EOS;
				}
			}
		if(ch=='(' && i!=0)
			seq_ptr[i]=EOS;
		}

	if((seq_ptr=strstr(description->ProteinName,"dna"))!=NULL) {
		if(!isalpha(*(seq_ptr-1)) && !isalpha(seq_ptr[3])) {
			for(i=0;i<3;i++)
				seq_ptr[i]=toupper(seq_ptr[i]);
			}
		}
	if((seq_ptr=strstr(description->ProteinName,"rna"))!=NULL) {
		if(!isalpha(*(seq_ptr-1)) && !isalpha(seq_ptr[3])) {
			for(i=0;i<3;i++)
				seq_ptr[i]=toupper(seq_ptr[i]);
			}
		}

	trimalnum(description->ProteinName);
	index=0;
	seq_ptr=description->ProteinName;
	for(i=0;i<strlen(seq_ptr);i++) {
		ch=seq_ptr[i];
		if(ch!='$' && ch!=':') {
			TempStr[index]=ch;
			index++;
			}
		}
	TempStr[index]=EOS;
	strcpy(seq_ptr,TempStr);
	}


/******* done *******/



/* continue to the SOURCE section to get source name */

/* first we store all SOURCE lines in the pool */
rewind(in_file);
while (fgets(TempStr,TempStr_Length,in_file)!=NULL) {
	if(!strncmp(TempStr,"SOURCE",6))
		break;
	}
if(!strncmp(TempStr,"SOURCE",6)) {	/* We found SOURCE section */
	/* Now we are at the first line of SOURCE section.
   	Keep reading until no SOURCE tag found. */
	PoolID=0;
	while (!strncmp(TempStr,"SOURCE",6)) {		/* still in SOURCE section */
		seq_ptr=Pool[PoolID];
		strcpy(seq_ptr,TempStr+PDB_SOURCE_POS-1);
		seq_ptr[PDB_SOURCE_LEN]=EOS;
		trimalnum(seq_ptr);
		PoolID++;
		if(fgets(TempStr,TempStr_Length,in_file)==NULL)
			break;
		}
	/* Check the pool to see whether two tags are available*/
	count_SCIENTIFIC=0;
	count_COMMON=0;
	for(i=0;i<PoolID;i++) {
		seq_ptr=Pool[i];
		if(strstr(seq_ptr,"ORGANISM_SCIENTIFIC:")!=NULL)
			count_SCIENTIFIC++;
		else if(strstr(seq_ptr,"ORGANISM_COMMON:")!=NULL)
			count_COMMON++;
		}
	if(count_SCIENTIFIC==0 && count_COMMON==0) {	/* seems to be an old PDB file, take source from 1st line */
		seq_ptr=Pool[0];
		left=right=0;
		left_pos=0;
		for(i=0;i<strlen(seq_ptr);i++) {
			if(seq_ptr[i]=='(') {
				left++;
				if(left_pos==0)
					left_pos=i;
				}
			else if(seq_ptr[i]==')') {
				right++;
				right_pos=i;
				}
			if(left!=0 && left==right)
				break;
			}
		if(left==0)
			strcpy(description->source,seq_ptr);
		else if(left==right) {
			strncpy(description->source,seq_ptr+left_pos+1,right_pos-left_pos-1);
			description->source[right_pos-left_pos-1]=EOS;
			}
		else	{
			strcpy(description->source,seq_ptr+left_pos+1);
			}
		}
	else	{
		if(count_SCIENTIFIC>0) {
			if(count_SCIENTIFIC<molID)
				molID=count_SCIENTIFIC;	/* WARNING: this is an error, but we take the last entry anyway */
			j=0;	
			for(i=0;i<PoolID;i++) {
				if(strstr(Pool[i],"ORGANISM_SCIENTIFIC:")!=NULL) {
					j++;
					if(j==molID)
						break;
					}
				}
			strcpy(description->source,Pool[i]+strlen("ORGANISM_SCIENTIFIC:"));
			trimalnum(description->source);
			}
		else	{
			if(count_COMMON<molID)
				molID=count_COMMON;	/* WARNING: this is an error, but we take the last entry anyway */
			j=0;    
			for(i=0;i<PoolID;i++) {
				if(strstr(Pool[i],"ORGANISM_COMMON")!=NULL) {
					j++;
					if(j==molID)
						break;
					}
				}
			strcpy(description->source,Pool[i]+strlen("ORGANISM_COMMON:"));
			trimalnum(description->source);
			}
		}
	seq_ptr=description->source;
	for(i=1;i<strlen(seq_ptr);i++)
		seq_ptr[i]=tolower(seq_ptr[i]);
	seq_ptr[0]=toupper(seq_ptr[0]);

	if(!strncasecmp(seq_ptr,"human",5) || !strncasecmp(seq_ptr,"man ",4))
		strcpy(seq_ptr,"Homo sapiens");
	else if(!strncasecmp(seq_ptr,"chicken",7))
		strcpy(seq_ptr,"Gallus gallus");
	else if(!strncasecmp(seq_ptr,"mouse",5))
		strcpy(seq_ptr,"Mus musculus");
	else if(!strncasecmp(seq_ptr,"horse",5))
		strcpy(seq_ptr,"Equus caballus");
	else if(!strncasecmp(seq_ptr,"porcine",7) || !strncasecmp(seq_ptr,"pig ",4))
		strcpy(seq_ptr,"Sus scrofa");

	if((seq_ptr=strstr(description->source,"recombinant"))!=NULL) {
		seq_ptr[0]=EOS;
		trimalnum(description->source);
		}

	seq_ptr=description->source;
	for(i=strlen(seq_ptr)-1;i>=0;i--) {
		ch=seq_ptr[i];
		if(isalnum(ch))
			break;
		if(ch==')') {
			for(j=i-1;j>=0;j--) {
				if(seq_ptr[j]=='(') {	/* delete (...) */
					if(j!=0) {
						seq_ptr[j]=EOS;
						i=j;
						}
					break;
					}
				}
			if(j<0) {	/* '(' not found */
				seq_ptr[i]=EOS;
				}
			}
		if(ch=='(' && i!=0)
			seq_ptr[i]=EOS;
		}

	trimalnum(description->source);
	index=0;
	seq_ptr=description->source;
	for(i=0;i<strlen(seq_ptr);i++) {
		ch=seq_ptr[i];
		if(ch!='$' && ch!=':') {
			TempStr[index]=ch;
			index++;
			}
		}
	TempStr[index]=EOS;
	strcpy(seq_ptr,TempStr);
	}

/******* done *******/




/* continue to the EXPDTA section to get method */

rewind(in_file);
while (fgets(TempStr,TempStr_Length,in_file)!=NULL) {
	if(!strncmp(TempStr,"EXPDTA",6))
		break;
	}
if(strncmp(TempStr,"EXPDTA",6))	/* not found */
	TempStr[0]=EOS;

if(strstr(TempStr,"X-RAY")!=NULL || strstr(TempStr,"X RAY")!=NULL)
	description->method='X';
else if(strstr(TempStr,"NMR")!=NULL)
	description->method='N';
else if(strstr(TempStr,"MODEL")!=NULL)
	description->method='M';
else
	description->method=EOS;

/******* done *******/




/* continue to the 'REMARK   2 RESOLUTION.' section to get resolution */

rewind(in_file);
strcpy(description->resolution,"-1");
while (fgets(TempStr,TempStr_Length,in_file)!=NULL) {
	if(!strncmp(TempStr,"REMARK   2 RESOLUTION.",22)) {
		if(strstr(TempStr,"ANGSTROM")!=NULL) {
			if((sscanf(TempStr+22,"%f",&TempFloat))==1) {
				sscanf(TempStr+22,"%s",description->resolution);
				if(description->method==EOS)
					description->method='X';
				}
			}
		break;
		}
	}

/******* done *******/




/* continue to the REMARK 3 section to get R-factor*/

if((TempFloat=atof(description->resolution))<0.0)
	strcpy(description->Rfactor,"-1");
else	{
	rewind(in_file);
	strcpy(description->Rfactor,"-1");
	while (fgets(TempStr,TempStr_Length,in_file)!=NULL) {
		if(!strncmp(TempStr,"REMARK   3",10))
			break;
		}
	while(!strncmp(TempStr,"REMARK   3",10)) {
		if(strstr(TempStr,"R VALUE")!=NULL && strstr(TempStr,"FREE")==NULL &&
		   strstr(TempStr,"NULL")==NULL) {
			if((seq_ptr=strstr(TempStr,":"))!=NULL) {
				if(sscanf(seq_ptr+1,"%f",&TempFloat)==1) {
					sscanf(seq_ptr+1,"%s",description->Rfactor);
					break;
					}
				else
					strcpy(description->Rfactor,"-1");
				}
			else	{	/* old format ? */
				seq_ptr=strstr(TempStr,"R VALUE");
				if(sscanf(seq_ptr+strlen("R VALUE"),"%f",&TempFloat)==1) {
					sscanf(seq_ptr+strlen("R VALUE"),"%s",description->Rfactor);
					break;
					}
				else
					strcpy(description->Rfactor,"-1");
				}
			}
		if(fgets(TempStr,TempStr_Length,in_file)==NULL)
			break;
		}

	if((TempFloat=atof(description->Rfactor))<1.0 && TempFloat>0.0) {	/* if less than 1.0, multiply it by 100 */
		TempFloat*=100.0;
		sprintf(description->Rfactor,"%.1f",TempFloat);
		}
			
	}

/******* done *******/


rewind(in_file);

return(SUCCESS);
}
