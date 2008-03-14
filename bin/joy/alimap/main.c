/*
 * AliMap -- Map sequence onto its PDB file and retrieve the coordinates.
 *
 */


/**************START**************/

#include "gen.h"
#include "runalimap.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#ifdef MEMDEBUG
	#include "memdebug.h"
#endif



int main(int argc, char *argv[])
{
void usage(void);		// print out the usage of this program

int		i;
Alimapoption	AliMapOption;


/* Initialize parameters */

init_alimap(&AliMapOption);


/* Get options */

if (argc==1) usage();

for(i=1;i<argc;i++) {
	if(!strcmp(argv[i],"-N"))	{	// delete ANISOU
		AliMapOption.flag_DelANISOU=TRUE;
		}
	else if(!strcmp(argv[i],"-nN"))	{	// Not delete ANISOU 
		AliMapOption.flag_DelANISOU=FALSE;
		}
	else if(!strcmp(argv[i],"-A"))	{	// delete Alternate atoms
		AliMapOption.flag_DelAltPos=TRUE;
		}
	else if(!strcmp(argv[i],"-nA"))  {	// Not delete Alternate atoms
		AliMapOption.flag_DelAltPos=FALSE;
		}
	else if(!strcmp(argv[i],"-H"))	{	// delete hydrogen
		AliMapOption.flag_DelHAtom=TRUE;
		}
	else if(!strcmp(argv[i],"-nH"))	{	// Not delete hydrogen
		AliMapOption.flag_DelHAtom=FALSE;
		}
	else if(!strcmp(argv[i],"-M"))	{	// delete residues with incomplete mainchain
		AliMapOption.flag_DelMissMCA=TRUE;
		}
	else if(!strcmp(argv[i],"-nM"))  {	// Not delete residues with incomplete mainchain
		AliMapOption.flag_DelMissMCA=FALSE;
		}
	else if(!strcmp(argv[i],"-nocheck"))  {	// Disable ALL PDB filters
		AliMapOption.flag_CheckPDB=FALSE;
		}
	else if(!strcmp(argv[i],"-model"))	{	// select model
		i++;
		if(i==argc) usage();
		AliMapOption.getmodel=atoi(argv[i]);
		}
	else if(!strcmp(argv[i],"-chain"))	{	// select chain
		i++;
		if(i==argc) usage();
		AliMapOption.chainID=toupper(argv[i][0]);
		}
	else if(!strcmp(argv[i],"-path"))	{	// select PDB path
		i++;
		if(i==argc) usage();
		AliMapOption.path=argv[i];
		}
	else if(!strcmp(argv[i],"-nmap"))	{	// do NOT map sequence to PDB
		AliMapOption.flag_Map=FALSE;
		}
	else if(!strcmp(argv[i],"-all"))	{	// get all chains (set flag_Map to FALSE as well)
		AliMapOption.flag_AllChain=TRUE;
		AliMapOption.flag_Map=FALSE;
		}
	else if(!strcmp(argv[i],"-code"))	{	// input single PDB code (set flag_Map to FALSE as well)
		AliMapOption.flag_PDBCode=TRUE;
		AliMapOption.flag_PDBSingle=TRUE;
		AliMapOption.flag_Map=FALSE;
		}
	else if(!strcmp(argv[i],"-file"))	{	// input single PDB file (set flag_Map to FALSE as well)
		AliMapOption.flag_PDBFile=TRUE;
		AliMapOption.flag_PDBSingle=TRUE;
		AliMapOption.flag_Map=FALSE;
		}
	else if(!strcmp(argv[i],"-ali")){	// output ali file name
		i++;
		if(i==argc) usage();
		AliMapOption.FileName_save_ali=argv[i];
		}
	else if(!strcmp(argv[i],"-atm")){	// output atm file name
		i++;
		if(i==argc) usage();
		AliMapOption.FileName_save_atm=argv[i];
		}
	else if(!strcmp(argv[i],"-noali")){	// do not output ali file
		AliMapOption.flag_SaveAli=FALSE;
		}
	else if(!strcmp(argv[i],"-noatm")){	// do not output atm file
		AliMapOption.flag_SaveAtm=FALSE;
		}
	else if(!strcmp(argv[i],"-K"))	{	// Keep original description (do not modify according to PDB file)
		AliMapOption.flag_KeepDesc=TRUE;
		}
	else if(!strcmp(argv[i],"-F"))	{	// output sequence in FASTA format (only valid with -code or -file option)
		AliMapOption.flag_OutputFASTA=TRUE;
		}
	else if(!strcmp(argv[i],"-B"))	{	// output chain break symbol in the sequence
		AliMapOption.flag_ChainBreak=TRUE;
		}
	else if(!strcmp(argv[i],"-nB"))	{	// do not output chain break symbol in the sequence
		AliMapOption.flag_ChainBreak=FALSE;
		}
	else if(!strcmp(argv[i],"-C"))	{	// convert PCA ACE FOR records from ATOM to HETATM
		AliMapOption.flag_ConvertPCA=TRUE;
		}
	else if(!strcmp(argv[i],"-nC"))	{	// do not convert PCA ACE FOR records from ATOM to HETATM
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
		printf("ALIMAP %s\n\n",ALIMAP_VER);
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

if(AliMapOption.flag_AllChain)
	AliMapOption.flag_Map=FALSE;


/* pass parameters to runalimap */

runalimap(&AliMapOption);


return(0);
}



void usage(void)
{
fprintf(stderr,"\n\n");
fprintf(stderr," ALIMAP   version %s\n\n",ALIMAP_VER);
fprintf(stderr," alimap [ -options ]  { sequence file | PDB file | PDB code }\n\n");

fprintf(stderr," File I/O Options:\n\n");
fprintf(stderr," -path  S set path for PDB file (eg. /pubdata/pdb/allpdb/pdb#.ent, # will be\n");
fprintf(stderr,"          automatically replaced by the PDB code found in the input sequence file)\n");
fprintf(stderr," -code    input is a PDB code rather than a sequence file (will enable -nmap option)\n");
fprintf(stderr," -file    input is a PDB file rather than a sequence file (will enable -nmap option)\n");
fprintf(stderr," -atm   S output PDB coordinates file name (only valid with -code option)\n");
fprintf(stderr," -ali   S output alignment file name\n");
fprintf(stderr," -noatm   do NOT output PDB coordinates file\n");
fprintf(stderr," -noali   do NOT output alignment file\n");
fprintf(stderr," -p       send output to stdout\n");
fprintf(stderr,"\n");

fprintf(stderr," Filter Options:\n\n");
fprintf(stderr," -nmap    do NOT map sequence to PDB\n");
fprintf(stderr," -all     get all chains (will enable -nmap option)\n");
fprintf(stderr," -chain C process chain C only\n");
fprintf(stderr," -model N process N-th model in PDB (default: model 1)\n");
fprintf(stderr," -nocheck disable ALL the following filters\n");
fprintf(stderr," -N       delete ANISOU record\n");
fprintf(stderr," -nN      keep   ANISOU record\n");
fprintf(stderr," -A       delete alternate atoms\n");
fprintf(stderr," -nA      keep   alternate atoms\n");
fprintf(stderr," -H       delete hydrogen\n");
fprintf(stderr," -nH      keep   hydrogen\n");
fprintf(stderr," -M       delete residues with incomplete mainchain\n");
fprintf(stderr," -nM      keep   residues with incomplete mainchain\n");
fprintf(stderr,"\n");

fprintf(stderr," Other Options:\n\n");
fprintf(stderr," -K       keep the original description line (do not modify according to PDB file)\n");
fprintf(stderr," -F       output sequence in FASTA format (only valid with -code or -file option)\n");
fprintf(stderr," -B       output chain break symbol in the alignment\n");
fprintf(stderr," -nB      do not output chain break symbol in the alignment\n");
fprintf(stderr," -C       convert PCA ACE FOR from ATOM to HETATM\n");
fprintf(stderr," -nC      do not convert PCA ACE FOR from ATOM to HETATM\n");
fprintf(stderr," -y       allow overwriting existing files\n");
fprintf(stderr," -v       verbose mode\n");
fprintf(stderr," -ver     version info\n");
fprintf(stderr,"\n");

fprintf(stderr," Note of symbols:\n\n");
fprintf(stderr," S        string\n");
fprintf(stderr," C        character\n");
fprintf(stderr," N        positive integar\n");
fprintf(stderr,"\n");

exit(ERROR_Code_Usage);
}
