/*
 *  AliMap -- Map sequence onto its PDB file and retrieve the coordinates.
 */


/**************START**************/

#include "gen.h"
#include "alimap.h"
#include "compseq.h"
#include "chnbrk.h"
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <unistd.h>
#include <stdlib.h>
#ifdef MEMDEBUG
	#include "memdebug.h"
#endif



boolean alimap(Alimapoption *AliMapOption, Seqinfo *SeqInfo)
{

boolean flag_Verbose;		// verbose mode ?
boolean flag_PrintScreen;	// Send output to stdout ?
boolean	flag_Map;		// map sequence to PDB ?
boolean	flag_KeepDesc;		// keep the original description line (do not modify according to PDB) ?

char	*sequence;
char	*FileName_read_pdb=NULL;
char	*FileName_save_atm=NULL;
PDBREC_AM	MyPdbRec;
PDBDESC	*description;
FILE	*in_file;




/* Set options and initialize parameters */

MyPdbRec.getmodel	=AliMapOption->getmodel;
MyPdbRec.chainID	=AliMapOption->chainID;
MyPdbRec.flag_DelANISOU	=AliMapOption->flag_DelANISOU;
MyPdbRec.flag_DelAltPos	=AliMapOption->flag_DelAltPos;
MyPdbRec.flag_DelHAtom	=AliMapOption->flag_DelHAtom;
MyPdbRec.flag_DelMissMCA=AliMapOption->flag_DelMissMCA;
MyPdbRec.flag_CheckPDB	=AliMapOption->flag_CheckPDB;
MyPdbRec.flag_ConvertPCA=AliMapOption->flag_ConvertPCA;
flag_Verbose		=AliMapOption->flag_Verbose;
flag_PrintScreen	=AliMapOption->flag_PrintScreen;
flag_Map		=AliMapOption->flag_Map;
flag_KeepDesc		=AliMapOption->flag_KeepDesc;
FileName_read_pdb	=AliMapOption->FileName_read_pdb;
FileName_save_atm	=AliMapOption->FileName_save_atm;
sequence		=SeqInfo->sequence;

description		=&(MyPdbRec.description);
description->method	=' ';
description->start_r[0]	=' ';
description->start_c	=' ';
description->end_r[0]	=' ';
description->end_c	=' ';
strncpy(description->code,SeqInfo->name,4);
description->code[4]=EOS;
strcpy(description->ProteinName,"unknown");
strcpy(description->source,"unknown");
strcpy(description->Rfactor,"-1");


/* Check existence of the PDB file and open it */

if((in_file=fopen(FileName_read_pdb,"r"))==NULL) {
	fprintf(stderr,"\nPDB file %s NOT found. Skip this entry (%s).\n",
		FileName_read_pdb,SeqInfo->name);
	return(ERROR_Code_FileNotFound);
        }
if(flag_Verbose)
	printf("\n===================================\nProcessing PDB file: %s\n",FileName_read_pdb);

/***** Done *****/



/* read PDB file */

if((read_pdb_AM(&MyPdbRec,in_file,flag_Verbose))!=SUCCESS) {
	fprintf(stderr,"Reading PDB file %s failed. Skip.\n",FileName_read_pdb);
	return(FAIL);
	}

#ifdef DEBUG
	print_pdb_AM(&MyPdbRec, FileName_read_pdb);
#endif

/***** Done *****/



/* Check PDB entery */

if(MyPdbRec.flag_CheckPDB) {
	check_pdb_AM(&MyPdbRec,flag_Verbose);
	#ifdef DEBUG
		print_pdb_valid(&MyPdbRec, FileName_read_pdb);
	#endif
	}

/***** Done *****/




/* Compare the sequence derived from PDB coordinates
   with the original input sequence. */

if(flag_Map)
	compare_seq(&MyPdbRec,sequence,flag_Verbose);

/***** Done *****/




/* Print the modified PDB coordinates */

if(AliMapOption->flag_SaveAtm) {
	if(write_atm(&MyPdbRec,in_file,FileName_save_atm,flag_PrintScreen,flag_Verbose)!=SUCCESS) {
		fprintf(stderr,"Writing coordinates failed. Skip.\n");
		}
	}

/***** Done *****/




/* modify SeqInfo according to the PDB file, if neccessary */

ModSeqInfo(&MyPdbRec,SeqInfo,flag_KeepDesc);

/***** Done *****/




/* Get chain break information */

if(AliMapOption->flag_ChainBreak)
	SeqInfo->ChainBreak=chnbrk(&MyPdbRec,SeqInfo->length_nogap,flag_Verbose);

/***** Done *****/




/* Clean up allocated memory and file handles */

free_pdb_AM(&MyPdbRec);
fclose(in_file);


return(SUCCESS);
}



void init_alimap(Alimapoption *AliMapOption)
{

AliMapOption->getmodel			=DEFAULT_GETMODEL;
AliMapOption->chainID			=DEFAULT_CHAINID;
AliMapOption->path			=DEFAULT_PATH;
AliMapOption->flag_DelANISOU		=DEFAULT_DELANISOU;
AliMapOption->flag_DelAltPos		=DEFAULT_DELALTPOS;
AliMapOption->flag_DelHAtom		=DEFAULT_DELHATOM;
AliMapOption->flag_DelMissMCA		=DEFAULT_DELMISSMCA;
AliMapOption->flag_Verbose		=DEFAULT_VERBOSE;
AliMapOption->flag_OverwriteYes		=DEFAULT_OVERWRITEYES;
AliMapOption->flag_PrintScreen		=DEFAULT_PRINTSCREEN;
AliMapOption->flag_AllChain		=DEFAULT_ALLCHAIN;
AliMapOption->flag_Map			=DEFAULT_MAP;
AliMapOption->flag_KeepDesc		=DEFAULT_KEEPDESC;
AliMapOption->flag_OutputFASTA		=DEFAULT_OUTPUTFASTA;
AliMapOption->flag_ChainBreak		=DEFAULT_CHAINBREAK;
AliMapOption->flag_ConvertPCA		=DEFAULT_CONVERTPCA;
AliMapOption->flag_CheckPDB		=DEFAULT_CHECKPDB;
AliMapOption->flag_PDBCode		=DEFAULT_PDBCODE;
AliMapOption->flag_PDBFile		=DEFAULT_PDBFILE;
AliMapOption->flag_PDBSingle		=DEFAULT_PDBSINGLE;
AliMapOption->flag_SaveAli		=DEFAULT_SAVEALI;
AliMapOption->flag_SaveAtm		=DEFAULT_SAVEATM;
AliMapOption->FileName_read_pdb		=NULL;
AliMapOption->FileName_save_atm		=NULL;
AliMapOption->FileName_save_ali		=NULL;

if(AliMapOption->flag_AllChain || AliMapOption->flag_PDBSingle)
	AliMapOption->flag_Map=FALSE;

return;
}




boolean write_atm(PDBREC_AM *MyPdbRec, FILE *in_file, char *FileName_save_atm, boolean flag_PrintScreen, boolean flag_Verbose)
{
int		model;
int		TempInt;
int		getmodel;
float		x, y, z;
char            TempStr[TempStr_Length]; 
char            chainID;
char		ch;
char		*ResName;
PDBATOM_AM         **Array_PdbAtom;
PDBRESIDUE_AM      *current_ptr_res; 
PDBATOM_AM         *current_ptr_atom;
PDBRESIDUE_AM      *temp_ptr_res=NULL; 
PDBATOM_AM         *temp_ptr_atom=NULL;
FILE		*out_file;
boolean		flag_DelANISOU;
boolean		flag_StartAtom;
boolean		flag_DelHAtom;
boolean		flag_ConvertPCA;

chainID=MyPdbRec->chainID;
getmodel=MyPdbRec->getmodel;
Array_PdbAtom=MyPdbRec->Atoms;
flag_DelANISOU=MyPdbRec->flag_DelANISOU;
flag_DelHAtom=MyPdbRec->flag_DelHAtom;
flag_ConvertPCA=MyPdbRec->flag_ConvertPCA;


if(!flag_PrintScreen) {
	out_file=fopen(FileName_save_atm,"w");
	if(out_file==NULL) {
		fprintf(stderr,"Unable to create output file %s\n",FileName_save_atm);
		return(FAIL);
		}
	}
else	{
	out_file=stdout;
	}

fprintf(out_file,"REMARK   1 PARSED BY ALIMAP %s\n",ALIMAP_VER);
fprintf(out_file,"REMARK   1  FILTERS APPLIED:  (1 -- ENABLED, 0 -- DISABLED)\n");
fprintf(out_file,"REMARK   1   ANISOU     RECORD      FILTER -- %d\n",MyPdbRec->flag_DelANISOU);
fprintf(out_file,"REMARK   1   ALTERNATE  LOCATION    FILTER -- %d\n",MyPdbRec->flag_DelAltPos);
fprintf(out_file,"REMARK   1   INCOMPLETE MAINCHAIN   FILTER -- %d\n",MyPdbRec->flag_DelMissMCA);
fprintf(out_file,"REMARK   1   HYDROGEN   COORDINATES FILTER -- %d\n",MyPdbRec->flag_DelHAtom);
fprintf(out_file,"REMARK   1   STRANGE    COORDINATES FILTER -- %d\n",MyPdbRec->flag_CheckPDB);
fprintf(out_file,"REMARK   1   PCA ACE FOR TITLE CONV FILTER -- %d\n",MyPdbRec->flag_ConvertPCA);


current_ptr_atom=Array_PdbAtom[0];
current_ptr_res=current_ptr_atom->ResiduePtr;
flag_StartAtom=FALSE;

rewind(in_file);
while (fgets(TempStr,TempStr_Length,in_file)!=NULL) {
	// ignore models which we don't want
	if(!strncmp(TempStr,"MODEL ",6)) {
		sscanf(TempStr+6,"%d",&model);
		if(model!=getmodel) {
			while (fgets(TempStr,TempStr_Length,in_file)!=NULL) {
				if(!strncmp(TempStr,"ENDMDL",6))
					break;
				}
			}
		continue;
		}
	if(!strncmp(TempStr,"ENDMDL",6))
		continue;

	// is ANISOU record ?
	if(!strncmp(TempStr,"ANISOU",6)) {
		if(!flag_DelANISOU)
			fprintf(out_file,"%s",TempStr);
		continue;
		}

	// is hetatm? if yes, check coordinate range and hydrogen record and print.
	if(!strncmp(TempStr,"HETATM",6)) {
		sscanf(TempStr-1+PDB_X_POS,"%f%f%f",&x,&y,&z);
		if(x<MIN_XYZ || x>MAX_XYZ || y<MIN_XYZ || y>MAX_XYZ ||
		   z<MIN_XYZ || z>MAX_XYZ ) {
			if(flag_Verbose) {
				fprintf(stderr,"Warning: HETATM record below removed due to strange coordinates\n     %s",
					TempStr);
				}
			continue;
			}
		if(flag_DelHAtom && (TempStr[13]=='H' || TempStr[13]=='Q' ||
		   (TempStr[13]=='D' && TempStr[14]=='D')) &&
		   strncmp(TempStr-1+PDB_RESNAME_POS,"WAT",PDB_RESNAME_LEN) &&
		   strncmp(TempStr-1+PDB_RESNAME_POS,"HOH",PDB_RESNAME_LEN) &&
		   strncmp(TempStr-1+PDB_RESNAME_POS,"HOH",PDB_RESNAME_LEN) ) {
			if(flag_Verbose) {
				fprintf(stderr,"Warning: HETATM record below removed due to hydrogen-excision\n     %s",
					TempStr);
				}
			continue;
			}
		if(chainID!='*') {      // '*' means we accept all chains
			ch=TempStr[PDB_CHAIN_POS-1];
			if(ch!=chainID && ch!=' ')
				continue;
			}
		ch=TempStr[PDB_ALTERLOC_POS-1];
		if(ch!=' ' && ch!='A' && ch!='1')
			continue;
 
		fprintf(out_file,"%s",TempStr);
		continue;
		}

	// is C-terminal ? if yes, change the residue name and No according to current residue/atom and print.
	if(!strncmp(TempStr,"TER   ",6)) {
		if(!flag_StartAtom)
			continue;
		if(strlen(TempStr)>=PDB_CHAIN_POS) {
			ch=TempStr[PDB_CHAIN_POS-1];
			if(temp_ptr_atom!=NULL) {
				if(temp_ptr_res->Chain!=ch)
					continue;
				}
			}
			
		if(temp_ptr_atom!=NULL) {
			TempInt=atoi(temp_ptr_atom->AtomNo)+1;
			if(strlen(TempStr)>=PDB_ALTERLOC_POS)
				ch=TempStr[PDB_ALTERLOC_POS-1];
			else
				ch=' ';
			fprintf(out_file,"TER   %5d     %c%3s %c%4s",TempInt,ch,temp_ptr_res->ResName,
				temp_ptr_res->Chain,temp_ptr_res->ResNo);
			fprintf(out_file,"%s",TempStr+27);
			}
		else	{
			fprintf(out_file,"%s",TempStr);
			}
		continue;
		}

	// is atom ? if not, print and go to next loop.
	if(strncmp(TempStr,"ATOM  ",6)) {
		fprintf(out_file,"%s",TempStr);
		continue;
		}

	// is the chain we want (chainID) ?
	if(chainID!='*') {      // '*' means we accept all chains
		if(TempStr[PDB_CHAIN_POS-1]!=chainID)
			continue;
		}

	// is this valid atom ?
	if(!current_ptr_atom->isValid) {
		if(current_ptr_atom->next_ptr!=NULL) {
			current_ptr_atom=current_ptr_atom->next_ptr;
			current_ptr_res=current_ptr_atom->ResiduePtr;
			}
		continue;
		}

	// is PCA ACE FOR ?
	if(flag_ConvertPCA) {
		ResName=current_ptr_res->ResName;
		if(strstr(ResName,"PCA")!=NULL ||strstr(ResName,"ACE")!=NULL ||
		   strstr(ResName,"FOR")!=NULL) {
			TempStr[0]='H';
			TempStr[1]='E';
			TempStr[2]='T';
			TempStr[3]='A';
			TempStr[4]='T';
			TempStr[5]='M';
			}
		}

	// write out
	flag_StartAtom=TRUE;
	TempStr[PDB_ALTERLOC_POS-1]=' ';
	fprintf(out_file,"%s",TempStr);
	temp_ptr_atom=current_ptr_atom;
	temp_ptr_res=current_ptr_res;
	if(current_ptr_atom->next_ptr!=NULL) {
		current_ptr_atom=current_ptr_atom->next_ptr;
		current_ptr_res=current_ptr_atom->ResiduePtr;
		}
	continue;

	}

if(!flag_PrintScreen)
	fclose(out_file);

return(SUCCESS);
}



boolean ModSeqInfo(PDBREC_AM *MyPdbRec, Seqinfo *SeqInfo, boolean flag_KeepDesc)
{
int		i;
int		index;
int		first;
int		last;
int		TempInt;
int		length;
char		*sequence;
char		*desc;
char		*ResName;
PDBRESIDUE_AM	*current_resptr;
PDBRESIDUE_AM	**Array_PdbResidue;


Array_PdbResidue=MyPdbRec->Residues;
length=MyPdbRec->Num_AllResidue;

if(SeqInfo->sequence==NULL) {	/* copy sequence derived from the PDB file */
	sequence = SeqInfo->sequence = (char *)malloc(sizeof(char)*(length+1));
	if(sequence==NULL) {
		fprintf(stderr,"\n%s%s: %s\n\n",ERROR_Found,alimap_Name,ERROR_MemErr);
		exit(ERROR_Code_MemErr);
		}
	
	index=0;
	for(i=0;i<length;i++) {
        	current_resptr=Array_PdbResidue[i];
        	if(current_resptr->Num_Atom_Valid<1)
                	continue;
        	sequence[index]=current_resptr->ShortName;
        	index++;
        	}
	sequence[index]=EOS;
	SeqInfo->length = SeqInfo->length_nogap = index;
	flag_KeepDesc=FALSE;
	}


/* get description line */
first=-1;
last=-1;
for(i=0;i<length;i++) {
	if(Array_PdbResidue[i]->Num_Atom_Valid<1)
		continue;
	if(first==-1)
		first=i;
	if(last<i)
		last=i;
	}
strcpy((MyPdbRec->description).start_r,Array_PdbResidue[first]->ResNo);
(MyPdbRec->description).start_c=Array_PdbResidue[first]->Chain;
strcpy((MyPdbRec->description).end_r,Array_PdbResidue[last]->ResNo);
(MyPdbRec->description).end_c=Array_PdbResidue[last]->Chain;

desc=(MyPdbRec->description).desc;
strcpy(desc,"structure");
desc[9]=(MyPdbRec->description).method;
desc[10]=EOS;
strcat(desc,":");
for(i=0;i<strlen((MyPdbRec->description).code);i++)
	(MyPdbRec->description).code[i]=tolower((MyPdbRec->description).code[i]);
strcat(desc,(MyPdbRec->description).code);
strcat(desc,":");
strcat(desc,(MyPdbRec->description).start_r);
strcat(desc,":");
TempInt=strlen(desc);
desc[TempInt]=(MyPdbRec->description).start_c;
desc[TempInt+1]=EOS;
strcat(desc,":");
strcat(desc,(MyPdbRec->description).end_r);
strcat(desc,":");
TempInt=strlen(desc);
desc[TempInt]=(MyPdbRec->description).end_c;
desc[TempInt+1]=EOS;
strcat(desc,":");
strcat(desc,(MyPdbRec->description).ProteinName);
strcat(desc,":");
strcat(desc,(MyPdbRec->description).source);
strcat(desc,":");
strcat(desc,(MyPdbRec->description).resolution);
strcat(desc,":");
strcat(desc,(MyPdbRec->description).Rfactor);

if(!flag_KeepDesc)
	strcpy(SeqInfo->description,desc);


/* Convert PCA ACE FOR from ATOM to HETATM and do NOT include them in the sequence */

if(MyPdbRec->flag_ConvertPCA) {
	sequence=SeqInfo->sequence;
	for(i=0;i<length;i++) {
		if(sequence[i]!='X')
			continue;
		ResName=Array_PdbResidue[i]->ResName;
		if(strstr(ResName,"PCA")!=NULL || strstr(ResName,"ACE")!=NULL ||
		   strstr(ResName,"FOR")!=NULL)
			sequence[i]='-';
		}
	}

return(SUCCESS);
}
