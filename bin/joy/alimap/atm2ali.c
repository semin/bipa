/*
 * atm2ali -- retrieve sequence information from ATM or PDB file
 *
 */


/**************START**************/

#include "api_AM.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#ifdef MEMDEBUG
	#include "memdebug.h"
#endif


#define ATM2ALI_VER "0.10 (JUNE 2000)"


int main(int argc, char *argv[])
{
void usage(void);		// print out the usage of this program

int		i;
Alimapoption	AliMapOption;


/* Initialize parameters */

init_alimap(&AliMapOption);

AliMapOption.flag_CheckPDB=FALSE;
AliMapOption.flag_Map=FALSE;
AliMapOption.flag_PDBFile=TRUE;
AliMapOption.flag_PDBSingle=TRUE;
AliMapOption.flag_SaveAtm=FALSE;


/* Get options */

if (argc==1) usage();

for(i=1;i<argc;i++) {
	if(!strcmp(argv[i],"-model"))	{	// select model
		i++;
		if(i==argc) usage();
		AliMapOption.getmodel=atoi(argv[i]);
		}
	else if(!strcmp(argv[i],"-chain"))	{	// select chain
		i++;
		if(i==argc) usage();
		AliMapOption.chainID=toupper(argv[i][0]);
		}
	else if(!strcmp(argv[i],"-ali")){	// output ali file name
		i++;
		if(i==argc) usage();
		AliMapOption.FileName_save_ali=argv[i];
		}
	else if(!strcmp(argv[i],"-F"))	{	// output sequence in FASTA format
		AliMapOption.flag_OutputFASTA=TRUE;
		}
	else if(!strcmp(argv[i],"-B"))  {       // output chain break symbol in the sequence
		AliMapOption.flag_ChainBreak=TRUE;
		}
	else if(!strcmp(argv[i],"-nB"))  {       // do not output chain break symbol in the sequence
		AliMapOption.flag_ChainBreak=FALSE;
		}
	else if(!strcmp(argv[i],"-C"))  {       // Convert PCA ACE FOR from ATOM to HETATM
		AliMapOption.flag_ConvertPCA=TRUE;
		}
	else if(!strcmp(argv[i],"-nC"))  {       // do not convert PCA ACE FOR from ATOM to HETATM
		AliMapOption.flag_ConvertPCA=FALSE;
		}
	else if(!strcmp(argv[i],"-v"))	{	// verbose mode
		AliMapOption.flag_Verbose=TRUE;
		}
	else if(!strcmp(argv[i],"-p"))	{	// write output to stdout
		AliMapOption.flag_PrintScreen=TRUE;
		AliMapOption.FileName_save_ali=SCREEN;
		}
	else if(!strcmp(argv[i],"-y"))	{	// Allow overwriting existing files
		AliMapOption.flag_OverwriteYes=TRUE;
		}
	else if(!strcmp(argv[i],"-ver")){	// Version
		printf("atm2ali %s\n\n",ATM2ALI_VER);
		exit(0);
		}
	else if(argv[i][0]=='-')	{	// Unknown option
		fprintf(stderr,"\nUnknown option: %s\nType 'alimap' to list the supported options.\n",argv[i]);
		exit(ERROR_Code_UnknownOption);
		}
	else	{				// Input file
		AliMapOption.FileName_input=argv[i];
		}
	}


/* pass parameters to runalimap */

runalimap(&AliMapOption);


return(0);
}



void usage(void)
{
fprintf(stderr,"\n\n");
fprintf(stderr," atm2ali   version %s\n\n",ATM2ALI_VER);
fprintf(stderr," atm2ali [ -options ]  { PDB or ATM file }\n\n");

fprintf(stderr," -ali   file      output alignment file name\n");
fprintf(stderr," -chain C         process chain C only\n");
fprintf(stderr," -model N         process N-th model in PDB (default: model 1)\n");
fprintf(stderr," -F               output alignment in FASTA format\n");
fprintf(stderr," -B               output alignment with chain break symbol\n");
fprintf(stderr," -nB              do not output alignment with chain break symbol\n");
fprintf(stderr," -C               convert PCA ACE FOR from ATOM to HETATM\n");
fprintf(stderr," -nC              do not convert PCA ACE FOR from ATOM to HETATM\n");
fprintf(stderr," -p               send output to stdout\n");
fprintf(stderr," -y               allow overwriting existing files\n");
fprintf(stderr," -v               verbose mode\n");
fprintf(stderr," -ver             version info\n");
fprintf(stderr,"\n\n");

exit(ERROR_Code_Usage);
}
