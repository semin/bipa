/*
 * Read van der Wall's radii from the library
 *
 */


/**************START**************/

#include "gen.h"
#include "read_RadiiLib.h"
#include "mklib.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#ifdef MEMDEBUG
	#include "memdebug.h"
#endif


void read_RadiiLib(RADIILIB2 *MyRadiiLib2, int *Num_RadiiLib, char *FileName_read_RadiiLib, boolean flag_Verbose)
{
FILE		*in_file;
int		Num_Residue;
char		TempStr[TempStr_Length]; 
char		*env;
char		envloc[TempStr_Length];
RADIILIB	*MyRadiiLib;
RADIILIB	*current_ptr; 
RADIILIB	**Array_MyRadiiLib;
register int 	i;



/* Check existence of the library file and open it */

// Check library file specified in command line
if(FileName_read_RadiiLib!=NULL && access(FileName_read_RadiiLib,R_OK)!=0) {
	fprintf(stderr,"\nvan der Wall's radii library file %s NOT found. Try default library...\n",
		FileName_read_RadiiLib);
	FileName_read_RadiiLib=NULL;	// set file name to empty
	}

// Check current directory
if(FileName_read_RadiiLib==NULL) {
	if(access(DEFAULT_RADIILIB1,R_OK)==0) {		// Found in current directory
		FileName_read_RadiiLib=DEFAULT_RADIILIB1;
		}
	}

// Check environment setting
if(FileName_read_RadiiLib==NULL) {
	env=getenv(ENV_RADIILIB);
	if(env!=NULL) {
		strcpy(envloc,env);
		strcat(envloc,"/psa.dat");
		if(access(envloc,R_OK)==0)
			FileName_read_RadiiLib=envloc;
		}
	else	{
		strcpy(envloc,"Not Available");
		}
	}

// Check another default library
if(FileName_read_RadiiLib==NULL) {
	if(access(DEFAULT_RADIILIB2,R_OK)!=0) {
		#ifdef REMOVED
		fprintf(stderr,"\n%s%s: Cannot find default van der Wall's radii library.\n",
			ERROR_Found,read_RadiiLib_Name);
		fprintf(stderr,"\nRadius library cannot be found at any of the following locations:\n");
		fprintf(stderr,"Default library in current directory: %s\n",DEFAULT_RADIILIB1);
		fprintf(stderr,"Default library defined in environment %s: %s\n",
				ENV_RADIILIB,envloc);
		fprintf(stderr,"Default library location 2: %s\n",DEFAULT_RADIILIB2);
		fprintf(stderr,"\n");
		exit(ERROR_Code_FileNotFound);
		#endif
		if(flag_Verbose)
			printf("External van der Wall's radii library NOT found. Use internal library.\n");
		read_RadiiLib2(MyRadiiLib2, Num_RadiiLib, flag_Verbose);
		return;
		}
	else	{
		FileName_read_RadiiLib=DEFAULT_RADIILIB2;
		}
	}

if(flag_Verbose)
	printf("Using van der Wall's radii library file %s\n",FileName_read_RadiiLib);

in_file=fopen(FileName_read_RadiiLib,"r");




/* Initialization */

MyRadiiLib=(RADIILIB *)malloc(sizeof(RADIILIB));
if(MyRadiiLib==NULL) {
	fprintf(stderr,"\n%s%s: %s\n\n",ERROR_Found,read_RadiiLib_Name,ERROR_MemErr);
	exit(ERROR_Code_MemErr);
	}
current_ptr=MyRadiiLib;
Num_Residue=0;	// store the number of residue types retrieved from the library




/* Read and parse the data */

while (fgets(TempStr,TempStr_Length,in_file)!=NULL) {
	if(TempStr[0]=='#') continue;

	// Found one residue, get residue name and atom type number
	Num_Residue++;
	strncpy(current_ptr->Residue,TempStr,RADIILIB_RESIDUE_LEN);
	current_ptr->Residue[RADIILIB_RESIDUE_LEN]=EOS;
	sscanf(TempStr+RADIILIB_RESIDUE_LEN,"%d",&(current_ptr->Num_Atom));
	if(current_ptr->Num_Atom<1) {
		fprintf(stderr,"\n%s%s: invalid number of atom type for residue %s in library %s\n",
			ERROR_Found,read_RadiiLib_Name,current_ptr->Residue,FileName_read_RadiiLib);
		exit(ERROR_Code_RadiiLibFormatError);
		}

	// Allocate memory for the storage of atom type and radii
	current_ptr->Atom=(char **)malloc(sizeof(char *)*current_ptr->Num_Atom);
	current_ptr->Radii=(MYREAL *)malloc(sizeof(MYREAL)*current_ptr->Num_Atom);
	if(current_ptr->Atom==NULL || current_ptr->Radii==NULL) {
		fprintf(stderr,"\n%s%s: %s\n\n",ERROR_Found,read_RadiiLib_Name,ERROR_MemErr);
		exit(ERROR_Code_MemErr);
		}

	// Get VDW radii for each atom
	for(i=0;i<current_ptr->Num_Atom;i++) {
		if(fgets(TempStr,TempStr_Length,in_file)==NULL) {
			fprintf(stderr,"\n%s%s: bad format for residue %s in library %s\n",
				ERROR_Found,read_RadiiLib_Name,current_ptr->Residue,
				FileName_read_RadiiLib);
			exit(ERROR_Code_RadiiLibFormatError);
			}
		if(TempStr[0]=='#') {
			i--;
			continue;
			}

		current_ptr->Atom[i]=(char *)malloc(sizeof(char)*(RADIILIB_ATOM_LEN+1));
		if(current_ptr->Atom[i]==NULL) {
			fprintf(stderr,"\n%s%s: %s\n\n",ERROR_Found,read_RadiiLib_Name,ERROR_MemErr);
			exit(ERROR_Code_MemErr);
			}
		strncpy(current_ptr->Atom[i],TempStr,RADIILIB_ATOM_LEN);
		current_ptr->Atom[i][RADIILIB_ATOM_LEN]=EOS;
		sscanf(TempStr+RADIILIB_ATOM_LEN,"%f",&(current_ptr->Radii[i]));
		}

	// Allocate memory for the next residue
	current_ptr->next_ptr=(RADIILIB *)malloc(sizeof(RADIILIB));
	if(current_ptr->next_ptr==NULL) {
		fprintf(stderr,"\n%s%s: %s\n\n",ERROR_Found,read_RadiiLib_Name,ERROR_MemErr);
		exit(ERROR_Code_MemErr);
		}
	current_ptr=current_ptr->next_ptr;

	}

// The last structure RADIILIB is NOT used. Free it.
free(current_ptr);
current_ptr=NULL;
		
// Transfer the linked structure to an array.
Array_MyRadiiLib=(RADIILIB **)malloc(sizeof(RADIILIB *)*Num_Residue);
if(Array_MyRadiiLib==NULL) {
	fprintf(stderr,"\n%s%s: %s\n\n",ERROR_Found,read_RadiiLib_Name,ERROR_MemErr);
	exit(ERROR_Code_MemErr);
	}
current_ptr=MyRadiiLib;
for(i=0;i<Num_Residue;i++) {
	Array_MyRadiiLib[i]=current_ptr;
	current_ptr=current_ptr->next_ptr;
	}

if(flag_Verbose)
	printf("Found %d residue types from library file %s.\n\n",
		Num_Residue,FileName_read_RadiiLib);	
	
*Num_RadiiLib=Num_Residue;
MyRadiiLib2->Array_MyRadiiLib=Array_MyRadiiLib;

fclose(in_file);

return;

}




void free_RadiiLib(RADIILIB **Array_RadiiLib, int Num_RadiiLib)
{
int i,j;
RADIILIB *current_ptr;

for(i=0;i<Num_RadiiLib;i++) {
	current_ptr=Array_RadiiLib[i];
	for(j=0;j<current_ptr->Num_Atom;j++)
		free(current_ptr->Atom[j]);
	free(current_ptr->Atom);
	free(current_ptr->Radii);
	free(current_ptr);
	}
free(Array_RadiiLib);
}



void print_RadiiLib(RADIILIB **Array_RadiiLib, int Num_RadiiLib)
{
int i,j;
RADIILIB *current_ptr;

printf("\nNow print the van der Wall's radii library:\n\n");

for(i=0;i<Num_RadiiLib;i++) {
	current_ptr=Array_RadiiLib[i];
	printf("%3s%3d\n",current_ptr->Residue,current_ptr->Num_Atom);
	for(j=0;j<current_ptr->Num_Atom;j++)
		printf("%4s%6.2f\n",current_ptr->Atom[j],current_ptr->Radii[j]);
	}
}




void read_RadiiLib2(RADIILIB2 *MyRadiiLib2, int *Num_RadiiLib, boolean flag_Verbose)
{
int		Num_Residue;
int		index;
char		*TempStr; 
RADIILIB	*MyRadiiLib;
RADIILIB	*current_ptr; 
RADIILIB	**Array_MyRadiiLib;
register int 	i;



/* Initialization */

MyRadiiLib=(RADIILIB *)malloc(sizeof(RADIILIB));
if(MyRadiiLib==NULL) {
	fprintf(stderr,"\n%s%s: %s\n\n",ERROR_Found,read_RadiiLib_Name,ERROR_MemErr);
	exit(ERROR_Code_MemErr);
	}
current_ptr=MyRadiiLib;
Num_Residue=0;	// store the number of residue types retrieved from the library




/* Read and parse the data */

for (index=0;index<LIBITEM;index++) {
	TempStr=psalib[index];
	if(TempStr[0]=='#') continue;

	// Found one residue, get residue name and atom type number
	Num_Residue++;
	strncpy(current_ptr->Residue,TempStr,RADIILIB_RESIDUE_LEN);
	current_ptr->Residue[RADIILIB_RESIDUE_LEN]=EOS;
	sscanf(TempStr+RADIILIB_RESIDUE_LEN,"%d",&(current_ptr->Num_Atom));
	if(current_ptr->Num_Atom<1) {
		fprintf(stderr,"\n%s%s: invalid number of atom type for residue %s in internal library\n",
			ERROR_Found,read_RadiiLib_Name,current_ptr->Residue);
		exit(ERROR_Code_RadiiLibFormatError);
		}

	// Allocate memory for the storage of atom type and radii
	current_ptr->Atom=(char **)malloc(sizeof(char *)*current_ptr->Num_Atom);
	current_ptr->Radii=(MYREAL *)malloc(sizeof(MYREAL)*current_ptr->Num_Atom);
	if(current_ptr->Atom==NULL || current_ptr->Radii==NULL) {
		fprintf(stderr,"\n%s%s: %s\n\n",ERROR_Found,read_RadiiLib_Name,ERROR_MemErr);
		exit(ERROR_Code_MemErr);
		}

	// Get VDW radii for each atom
	for(i=0;i<current_ptr->Num_Atom;i++) {
		index++;
		if(index>=LIBITEM) {
			fprintf(stderr,"\n%s%s: bad format for residue %s in internal library\n",
				ERROR_Found,read_RadiiLib_Name,current_ptr->Residue);
			exit(ERROR_Code_RadiiLibFormatError);
			}
		TempStr=psalib[index];
		if(TempStr[0]=='#') {
			i--;
			continue;
			}

		current_ptr->Atom[i]=(char *)malloc(sizeof(char)*(RADIILIB_ATOM_LEN+1));
		if(current_ptr->Atom[i]==NULL) {
			fprintf(stderr,"\n%s%s: %s\n\n",ERROR_Found,read_RadiiLib_Name,ERROR_MemErr);
			exit(ERROR_Code_MemErr);
			}
		strncpy(current_ptr->Atom[i],TempStr,RADIILIB_ATOM_LEN);
		current_ptr->Atom[i][RADIILIB_ATOM_LEN]=EOS;
		sscanf(TempStr+RADIILIB_ATOM_LEN,"%f",&(current_ptr->Radii[i]));
		}

	// Allocate memory for the next residue
	current_ptr->next_ptr=(RADIILIB *)malloc(sizeof(RADIILIB));
	if(current_ptr->next_ptr==NULL) {
		fprintf(stderr,"\n%s%s: %s\n\n",ERROR_Found,read_RadiiLib_Name,ERROR_MemErr);
		exit(ERROR_Code_MemErr);
		}
	current_ptr=current_ptr->next_ptr;

	}

// The last structure RADIILIB is NOT used. Free it.
free(current_ptr);
current_ptr=NULL;
		
// Transfer the linked structure to an array.
Array_MyRadiiLib=(RADIILIB **)malloc(sizeof(RADIILIB *)*Num_Residue);
if(Array_MyRadiiLib==NULL) {
	fprintf(stderr,"\n%s%s: %s\n\n",ERROR_Found,read_RadiiLib_Name,ERROR_MemErr);
	exit(ERROR_Code_MemErr);
	}
current_ptr=MyRadiiLib;
for(i=0;i<Num_Residue;i++) {
	Array_MyRadiiLib[i]=current_ptr;
	current_ptr=current_ptr->next_ptr;
	}

if(flag_Verbose)
	printf("Found %d residue types from internal library.\n\n",
		Num_Residue);	
	
*Num_RadiiLib=Num_Residue;
MyRadiiLib2->Array_MyRadiiLib=Array_MyRadiiLib;

return;
}
