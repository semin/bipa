/*
 * AliMap -- Map sequence onto its PDB file and retrieve the coordinates.
 *
 */


/**************START**************/

#include "gen.h"
#include "runalimap.h"
#include "chnbrk.h"
#ifndef read_seq_Name
	#include "read_seq.h"
#endif
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <stdlib.h>
#include <unistd.h>
#ifdef MEMDEBUG
	#include "memdebug.h"
#endif



void runalimap(Alimapoption *AliMapOption)
{
int		i, j, k;
int		index;
int		AlimapStatus;
int		SeqNumber;
int		SeqLength;
int		SeqFormat;
char		ch;
boolean		flag_SeqAligned;
boolean		flag_PDBSingle;
boolean		flag_PDBCode;
boolean		flag_PDBFile;
boolean		flag_Verbose;
Seqinfo		**SeqInfo=NULL;
Seqinfo		*SeqInfo_ptr=NULL;
Seqinfo		SeqInfo_Single;
char		TempStr[TempStr_Length];
char		*path=NULL;
char		*FileName_input=NULL;
char		FileName_read_pdb[MAX_FileNameLen];
char		FileName_save_atm[MAX_FileNameLen];
char		FileName_save_ali[MAX_FileNameLen];
FILE		*seqfile=NULL;
FILE		*outfile=NULL;



/* Initialize */

path=AliMapOption->path;
flag_Verbose=AliMapOption->flag_Verbose;
FileName_input=AliMapOption->FileName_input;
flag_PDBCode=AliMapOption->flag_PDBCode;
flag_PDBFile=AliMapOption->flag_PDBFile;
flag_PDBSingle=AliMapOption->flag_PDBSingle;
SeqFormat=AUTOSEQFORMAT;

/***** Done *****/



/* Validate the options */

if(!AliMapOption->flag_CheckPDB) {
	AliMapOption->flag_DelMissMCA=FALSE;
	AliMapOption->flag_DelHAtom=FALSE;
	AliMapOption->flag_DelAltPos=FALSE;
	AliMapOption->flag_DelANISOU=FALSE;
	}
if(flag_PDBCode || flag_PDBFile)
	flag_PDBSingle = AliMapOption->flag_PDBSingle = TRUE;
else
	AliMapOption->flag_OutputFASTA=FALSE;
if(AliMapOption->flag_AllChain || AliMapOption->flag_PDBSingle)
	AliMapOption->flag_Map=FALSE;

/***** Done *****/



/* Reading the input sequence file */

if(!flag_PDBSingle) {
	SeqInfo=read_seq(&SeqNumber, &flag_SeqAligned, &SeqFormat, FileName_input, flag_Verbose);

	#ifdef DEBUG
	printf("\nNow print the sequences got from %s ...\n\n",FileName_Sequence);
	for (i=0;i<SeqNumber;i++) {
        	print_PIR(SCREEN,TRUE,SeqInfo[i]->name,SeqInfo[i]->description,SeqInfo[i]->sequence,FALSE);
		}
	printf("\nPrinting finished successfully. Total sequence(s): %d\n\n",SeqNumber);
	#endif

	SeqLength=SeqInfo[0]->length;
	}
else	{
	SeqInfo_ptr=&SeqInfo_Single;
	strcpy(SeqInfo_Single.description,"structure");
	SeqInfo_Single.sequence=NULL;
	SeqInfo_Single.ChainBreak=NULL;
	SeqNumber=1;
	if(flag_PDBCode)
		strcpy(SeqInfo_Single.name,FileName_input);
	else	{	/* retrieve PDB code from the file name */
		strcpy(TempStr,FileName_input);
		ShortFilename_AM(TempStr);
		if(!strncasecmp(TempStr,"pdb",3)) {
			for(i=0;i<strlen(TempStr)-3;i++)
				TempStr[i]=TempStr[i+3];
			TempStr[i]=EOS;
			}
		strcpy(SeqInfo_Single.name,TempStr);
		}
	}

/***** Done *****/




/* Derive output new alignment file name */

if(AliMapOption->flag_PrintScreen) {
	AliMapOption->FileName_save_ali=SCREEN;
	strcpy(FileName_save_ali,SCREEN);
	}
else	{
	if(AliMapOption->FileName_save_ali==NULL) {
		if(!flag_PDBSingle) {
			strcpy(TempStr,FileName_input);
			ShortFilename_AM(TempStr);
			strcpy(FileName_save_ali,TempStr);
			strcat(FileName_save_ali,NEWALI_EXT);
			}
		else	{
			strcpy(FileName_save_ali,SeqInfo_Single.name);
			strcat(FileName_save_ali,ALI_EXT);
			}
		AliMapOption->FileName_save_ali=FileName_save_ali;
		}
	else	{
		strcpy(FileName_save_ali,AliMapOption->FileName_save_ali);
		}
	/* Overwrite ? */
	if(AliMapOption->flag_SaveAli) {
		if (!OverwriteCheck_AM(AliMapOption->FileName_save_ali,&AliMapOption->flag_OverwriteYes)) {
			fprintf(stderr,"Don't overwrite. Skip working on sequence %s\n",
				SeqInfo_ptr->name);
			}
		else	{
			if(access(AliMapOption->FileName_save_ali,F_OK)==0)
				unlink(AliMapOption->FileName_save_ali);
			}
		}
	}

/***** Done *****/



/* Process each sequence */

for(i=0;i<SeqNumber;i++) {
	if(!flag_PDBSingle)
		SeqInfo_ptr=SeqInfo[i];
	else
		SeqInfo_ptr=&SeqInfo_Single;

	/* derive PDB file name */
	if(flag_PDBFile) {
		strcpy(FileName_read_pdb,FileName_input);
		}
	else	{
		index=0;
		for(j=0;j<strlen(path);j++) {
			if(path[j]!='#') {
				FileName_read_pdb[index]=path[j];
				index++;
				}
			else	{
				for(k=0;k<4;k++) {
					FileName_read_pdb[index]=SeqInfo_ptr->name[k];
					index++;
					}
				}
			}
		FileName_read_pdb[index]=EOS;
		}
	AliMapOption->FileName_read_pdb=FileName_read_pdb;

	/* derive chainID -- skip when flag_PDBFile==TRUE */
	if(!flag_PDBSingle || (flag_PDBCode && AliMapOption->chainID=='*')) {
		if(strlen(SeqInfo_ptr->name)>4) {
			ch=toupper(SeqInfo_ptr->name[4]);
			if((ch>='A' && ch<='Z') || (ch>='0' && ch<='9'))
				AliMapOption->chainID=ch;
			else
				AliMapOption->chainID='*';
			}
		else	{
			AliMapOption->chainID='*';
			}
		}

	/* derive output PDB file name */
	if(AliMapOption->flag_PrintScreen) {
		AliMapOption->FileName_save_atm=SCREEN;
		}
	else	{
		if(AliMapOption->FileName_save_atm==NULL || !AliMapOption->flag_PDBSingle) {
			strcpy(FileName_save_atm,SeqInfo_ptr->name);
			strcat(FileName_save_atm,OUTPUT_EXT);
			AliMapOption->FileName_save_atm=FileName_save_atm;
			}
		else	{
			strcpy(FileName_save_atm,AliMapOption->FileName_save_atm);
			}

		/* Overwrite ? */
		if(AliMapOption->flag_SaveAtm) {
			if (!OverwriteCheck_AM(FileName_save_atm,&AliMapOption->flag_OverwriteYes)) {
				fprintf(stderr,"Don't overwrite. Skip working on sequence %s\n",
					SeqInfo_ptr->name);
				continue;
				}
			else	{
				if(access(FileName_save_atm,F_OK)==0)
					unlink(FileName_save_atm);
				}
			}
		}

	if(AliMapOption->flag_AllChain)
		AliMapOption->chainID='*';


	/* Run alimap */
	AlimapStatus=alimap(AliMapOption,SeqInfo_ptr);
	if(AlimapStatus!=SUCCESS) {
		fprintf(stderr,"Error found when processing sequence %s\n",
			SeqInfo_ptr->name);
		}
	else if(flag_Verbose && !AliMapOption->flag_PrintScreen) {
		printf("Parsed PDB coordinates have been saved in file %s\n\n",FileName_save_atm);
		}

	}

if(flag_Verbose)
	printf("\nFinished parsing PDB file.\n");


/* Write new alignment to file */

if(AliMapOption->flag_SaveAli) {
	if(flag_Verbose)
		printf("Start writing new alignment ...\n");

	if(!flag_PDBSingle) {
		rm_gaponly_column(SeqInfo,SeqNumber,flag_Verbose);

		if(!AliMapOption->flag_PrintScreen)
			outfile=fopen(FileName_save_ali,"w");
		else
			outfile=stdout;

		seqfile=fopen(FileName_input,"r");
		while(fgets(TempStr,TempStr_Length,seqfile)!=NULL) {
			if(!strncmp(TempStr,"C;",2)) {
				fprintf(outfile,"%s",TempStr);
				}
			}
		fclose(seqfile);
		if(!AliMapOption->flag_PrintScreen)
			fclose(outfile);

		if(AliMapOption->flag_ChainBreak)
			SetChainBreak_Multi(SeqInfo, SeqNumber);

		for (i=0;i<SeqNumber;i++)
			print_PIR(FileName_save_ali,TRUE,SeqInfo[i]->name,SeqInfo[i]->description,
				SeqInfo[i]->sequence,FALSE);
		}
	else	{
		if(SeqInfo_Single.sequence!=NULL) {
			rm_gaponly_column_single(&SeqInfo_Single,flag_Verbose);
			if(AliMapOption->flag_ChainBreak)
				SetChainBreak_Single(&SeqInfo_Single);
			if(AliMapOption->flag_OutputFASTA)
       				print_FASTA(FileName_save_ali,TRUE,SeqInfo_Single.name,
					SeqInfo_Single.description,SeqInfo_Single.sequence,FALSE);
			else
       				print_PIR(FileName_save_ali,TRUE,SeqInfo_Single.name,
					SeqInfo_Single.description,SeqInfo_Single.sequence,FALSE);
			free(SeqInfo_Single.sequence);
			}
		}
	if(flag_Verbose && !AliMapOption->flag_PrintScreen)
		printf("New alignment file has been saved in file %s\n\n",FileName_save_ali);

	}


if(!flag_PDBSingle)
	free_seqinfo(SeqInfo, SeqNumber);
else	{
	if(SeqInfo_Single.ChainBreak!=NULL)
		free(SeqInfo_Single.ChainBreak);
	}

return;
}
