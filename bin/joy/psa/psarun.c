/*
 *  PSA  --  Protein Solvent Accessibility calculation 
 *
 */


/**************START**************/

#include "gen.h"
#include "psa.h"
#include <stdio.h>
#include <string.h>
#ifdef MEMDEBUG
	#include "memdebug.h"
#endif



main(int argc, char *argv[])
{
void usage(void);		// print out the usage of this program

register int	i;
Psaoption	PsaOption;
char		*InputFile[MAX_INPUTFILE];
int		Num_InputFile=0;


/* Initialize parameters */

init_psa(&PsaOption);


/* Get options */

if (argc==1) usage();

for(i=1;i<argc;i++) {
	if(!strcmp(argv[i],"-c"))	{	// contact type surface
		PsaOption.flag_ContactTypeSurface=TRUE;
		}
	else if(!strcmp(argv[i],"-s"))	{	// accessible type surface 
		PsaOption.flag_ContactTypeSurface=FALSE;
		}
	else if(!strcmp(argv[i],"-p"))	{	// probe size
		i++;
		if(i==argc) usage();
		sscanf(argv[i],"%f",&PsaOption.ProbeSize);
		PsaOption.flag_ContactTypeSurface=FALSE;
		}
	else if(!strcmp(argv[i],"-e"))  {	// integration step
		i++;
		if(i==argc) usage();
		sscanf(argv[i],"%f",&PsaOption.IntegrationStep);
		}
	else if(!strcmp(argv[i],"-R"))	{	// radius library file
		i++;
		if(i==argc) usage();
		PsaOption.FileName_RadiiLib=argv[i];
		}
	else if(!strcmp(argv[i],"-m"))	{	// select model
		i++;
		if(i==argc) usage();
		PsaOption.getmodel=atoi(argv[i]);
		}
	else if(!strcmp(argv[i],"-v"))	{	// verbose mode
		PsaOption.flag_Verbose=TRUE;
		}
	else if(!strcmp(argv[i],"-t"))	{	// write output to stdout
		PsaOption.flag_PrintScreen=TRUE;
		}
	else if(!strcmp(argv[i],"-y"))	{	// Allow overwriting existing files
		PsaOption.flag_OverwriteYes=TRUE;
		}
	else if(!strcmp(argv[i],"-r"))	{	// set residue accessibility output to TRUE
		PsaOption.flag_ResidueAcc=TRUE;
		}
	else if(!strcmp(argv[i],"-d"))	{	// set residue side-chain per. accessibility output to TRUE
		PsaOption.flag_ResPerAcc=TRUE;
		}
	else if(!strcmp(argv[i],"-h"))	{	// include hetatms
		PsaOption.flag_Hetatm=TRUE;
		}
	else if(!strcmp(argv[i],"-a"))	{	// set atom accessibility output to TRUE
		PsaOption.flag_AtomAcc=TRUE;
		}
	else if(!strcmp(argv[i],"-w"))	{	// include water atoms
		PsaOption.flag_Water=TRUE;
		}
	else if(!strcmp(argv[i],"-nr"))	{	// set residue accessibility output to FALSE
		PsaOption.flag_ResidueAcc=FALSE;
		}
	else if(!strcmp(argv[i],"-nd"))	{	// set residue side-chain per. accessibility output to FALSE
		PsaOption.flag_ResPerAcc=FALSE;
		}
	else if(!strcmp(argv[i],"-nh"))	{	// NOT include hetatms
		PsaOption.flag_Hetatm=FALSE;
		}
	else if(!strcmp(argv[i],"-na"))	{	// set atom accessibility output to FALSE
		PsaOption.flag_AtomAcc=FALSE;
		}
	else if(!strcmp(argv[i],"-nw"))	{	// NOT include water atoms
		PsaOption.flag_Water=FALSE;
		}
	else if(!strcmp(argv[i],"-unk")){	// Output UNK
		PsaOption.flag_UNK=TRUE;
		}
	else if(!strcmp(argv[i],"-nunk")){	// NOT output UNK
		PsaOption.flag_UNK=FALSE;
		}
	else if(!strcmp(argv[i],"-ver")){	// Version
		printf("PSA %s\n\n",VER);
		exit(0);
		}
	else if(argv[i][0]=='-')	{	// Unknown option
		fprintf(stderr,"\nUnknown option: %s\nType 'psa' to list the supported options.\n",argv[i]);
		exit(ERROR_Code_UnknownOption);
		}
	else	{				// Input PDB file name
		if(Num_InputFile<MAX_INPUTFILE) {
			InputFile[Num_InputFile]=argv[i];
			Num_InputFile++;
			}
		else	{
			fprintf(stderr,"\n%s%s: too many input files in the command line.\n",
				ERROR_Found,PSA_Name);
			fprintf(stderr,"Try increase MAX_INPUTFILE in psa.h and re-compile the program.\n");
			exit(ERROR_Code_TooManyInputFile);
			}
		}
	}

PsaOption.FileName_PDB=InputFile;
PsaOption.Num_InputFile=Num_InputFile;


/* Run psa */

psa(&PsaOption);


return(0);
}



void usage(void)
{
fprintf(stderr,"\n\n");
fprintf(stderr," psa   version %s\n",VER);
fprintf(stderr," psa [ -options ] file.atm [file2.atm file3.atm ...]\n");
fprintf(stderr," -p  N.n  set probe size\n");
fprintf(stderr," -e  N.n  set integration step\n");
fprintf(stderr," -c       contact type surface                      (default)\n");
fprintf(stderr," -s       accessible type surface\n");
fprintf(stderr," -R  file radius library file\n");
fprintf(stderr," -a       set atom    accessibility output to TRUE\n");
fprintf(stderr," -r       set residue accessibility output to TRUE  (default)\n");
fprintf(stderr," -d       set residue side-chain per. accessibility output to TRUE\n");
fprintf(stderr," -h       include hetatms                           (default)\n");
fprintf(stderr," -w       include water atoms\n");
fprintf(stderr," -na      set atom    accessibility output to FALSE\n");
fprintf(stderr," -nr      set residue accessibility output to FALSE\n");
fprintf(stderr," -nd      set residue side-chain per. accessibility output to FALSE\n");
fprintf(stderr," -nh      DO NOT include hetatms\n");
fprintf(stderr," -nw      DO NOT include water atoms\n");
fprintf(stderr," -unk     Output UNK info\n");
fprintf(stderr," -nunk    DO NOT output UNK info\n");
fprintf(stderr," -m  N    Process N-th model in PDB (by default process 1st model if PDB contains multi-models)\n");
fprintf(stderr," -t       send output to stdout\n");
fprintf(stderr," -y       allow overwriting existing files\n");
fprintf(stderr," -v       verbose mode\n");
fprintf(stderr," -ver     version info\n");
fprintf(stderr,"\n\n");
exit(ERROR_Code_Usage);
}
