/*
 * Print out the result
 *
 */


/**************START**************/

#include "gen.h"
#include "read_RadiiLib.h"
#include "read_pdb.h"
#include "output.h"
#include "psa.h"
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#ifdef MEMDEBUG
	#include "memdebug.h"
#endif


boolean WriteAtomAcc(PDBREC *MyPdbRec, MYREAL ProbeSize, MYREAL IntegrationStep,
		 boolean flag_Water, boolean flag_Hetatm, boolean flag_ContactTypeSurface,
		 boolean flag_Verbose, boolean *flag_OverwriteYes, char *FileName_PDB,
		 MYREAL *access, boolean flag_PrintScreen)
{
int 		i;
int		index;
PDBATOM		**Array_PdbAtom;
PDBATOM		*current_ptr;
FILE		*outfile;
FILE		*pdbfile;
char		FileName_Output[MAX_FileNameLen];
char		ResName[PDB_RESNAME_LEN+1];
char		AlterLoc;
char		*ch_ptr;
char		TempStr[TempStr_Length];
MYREAL		acc;
MYREAL		x;
MYREAL		y;
MYREAL		z;
boolean		isatom;
boolean		iswater;
boolean		ishetatm;
boolean		isvalid;
boolean		ismultimodel;
int		getmodel;
int		model;


// Initialization
Array_PdbAtom=MyPdbRec->Atoms;
ismultimodel=MyPdbRec->ismultimodel;
getmodel=MyPdbRec->getmodel;

if(flag_PrintScreen) {
	outfile=stdout;
	}
else	{
	strcpy(FileName_Output,FileName_PDB);
	ShortFilename(FileName_Output);
	strcat(FileName_Output,ATOMACC_EXT);
	if (!OverwriteCheck(FileName_Output,flag_OverwriteYes)) {
		fprintf(stderr,"Don't overwrite. Skip writing file.\n");
		return(FAIL);
		}
	if ((outfile=fopen(FileName_Output,"w"))==NULL) {
		fprintf(stderr,"%s%s: cannot create output file %s\n",
			ERROR_Found,output_Name,FileName_Output);
		return(FAIL);
		}
	}

if ((pdbfile=fopen(FileName_PDB,"r"))==NULL) {
	fprintf(stderr,"PDB file %s NOT found.\n",FileName_PDB);
	return(FAIL);
	}


// Print header
fprintf(outfile,"REMARK     Produced by psa, version %s\n",VER);
fprintf(outfile,"REMARK     Probe_Radius            %5.3f\n",ProbeSize);
fprintf(outfile,"REMARK     Integration_Step        %7.5f\n",IntegrationStep);
fprintf(outfile,"REMARK     Include_Water           ");
if(flag_Water)
	fprintf(outfile,"TRUE\n");
else
	fprintf(outfile,"FALSE\n");
fprintf(outfile,"REMARK     Include_Hetatm          ");
if(flag_Hetatm)
	fprintf(outfile,"TRUE\n");
else
	fprintf(outfile,"FALSE\n");
fprintf(outfile,"REMARK     Accessibility_Type      ");
if(flag_ContactTypeSurface)
	fprintf(outfile,"CONTACT\n");
else
	fprintf(outfile,"SURFACE\n");



/*
 * Print result. Note the temperature factor in the PDB file
 * is replaced by the atom accessibility. If accessibility is
 * not available, it's set to DEFAULT_ACCOUT.
 */

// go to the requested model
if(ismultimodel) {
	while(fgets(TempStr,TempStr_Length,pdbfile)!=NULL) {
		sscanf(TempStr+6,"%d",&model);
		if(model==getmodel && !strncmp(TempStr,"MODEL ",6))
			break;
		}
	if(feof(pdbfile)) {
		fprintf(stderr,"Error in parsing PDB.\n");
		exit(-1);
		}
	}

index=0;
while(fgets(TempStr,TempStr_Length,pdbfile)!=NULL) {
	if(ismultimodel && !strncmp(TempStr,"ENDMDL",6))
		break;

	// is atom or hetatm ?
	isatom=!strncmp(TempStr,"ATOM  ",6);
	ishetatm=!strncmp(TempStr,"HETATM",6);
	if(!(isatom||ishetatm)) {
		fprintf(outfile,"%s",TempStr);
		continue;	// not atom record, print as it is.
		}

	isvalid=TRUE;
	// is Alternate atom ?
	AlterLoc=TempStr[PDB_ALTERLOC_POS-1];
	if(AlterLoc!=' ' && AlterLoc!='A') {
		isvalid=FALSE;
		}
	else	{
		// water or other hetatm ?
		strncpy(ResName,TempStr-1+PDB_RESNAME_POS,PDB_RESNAME_LEN);
		ResName[PDB_RESNAME_LEN]=EOS;
		iswater=!(strcmp(ResName,"WAT") && strcmp(ResName,"HOH") && strcmp(ResName,"MOH"));
		if (iswater) {
			if(!flag_Water) isvalid=FALSE;
			}
		else	{
			if(ishetatm && (!flag_Hetatm)) isvalid=FALSE;
			}
		}

	// set accessibility
	if(isvalid) {	// accessibility already calculated
		// Verify atom coordinates
		current_ptr=Array_PdbAtom[index];
		sscanf(TempStr-1+PDB_X_POS,"%f%f%f",&x,&y,&z);
		if(x!=current_ptr->x || y!=current_ptr->y || z!=current_ptr->z) {
			fprintf(stderr,"Unknown error occurs when writing atom accessibility.\n");
			fprintf(stderr,"Current  coordinates: %8.3f%8.3f%8.3f\n",x,y,z);
			fprintf(stderr,"Expected coordinates: %8.3f%8.3f%8.3f\n",
				current_ptr->x,current_ptr->y,current_ptr->z);
			exit(ERROR_Code_General);
			}
		// set accessibility
		acc=access[index];
		if(acc<0.0 & acc>-0.01)
			acc=0.0;
		index++;
		}
	else	{	// accessibility not available
		acc=DEFAULT_ACCOUT;
		}

	// Print atom accessibility
	ch_ptr=TempStr;
	for(i=0;i<PDB_TEMP_POS-1;i++) {
		putc(*ch_ptr,outfile);
		ch_ptr++;
		}
	fprintf(outfile,"%6.2f",acc);
	fprintf(outfile,"%s",TempStr+PDB_TEMP_POS+5);	// 5=6-1
	}

fclose(pdbfile);
if(!flag_PrintScreen)
	fclose(outfile);

return(SUCCESS);
}



boolean WriteResAcc(PDBREC *MyPdbRec, MYREAL ProbeSize, MYREAL IntegrationStep,
		 boolean flag_Water, boolean flag_Hetatm, boolean flag_ContactTypeSurface,
		 boolean flag_Verbose, boolean *flag_OverwriteYes, char *FileName_PDB,
		 MYREAL **ResAcc, int SkipRes, boolean flag_PrintScreen, boolean flag_UNK)
{
int		i, j;
int		ityp;
int		Num_AllResidue;
PDBRESIDUE      **Array_PdbResidue;
PDBRESIDUE      *current_ptr_res;
FILE		*outfile;
char		FileName_Output[MAX_FileNameLen];
char		flag;
MYREAL		TempDouble;
MYREAL		*ResAcc_ptr;


// Initialization
Array_PdbResidue=MyPdbRec->Residues;
Num_AllResidue=MyPdbRec->Num_AllResidue;

if(flag_PrintScreen) {
	outfile=stdout;
	}
else	{
	strcpy(FileName_Output,FileName_PDB);
	ShortFilename(FileName_Output);
	strcat(FileName_Output,RESIDUEACC_EXT);
	if (!OverwriteCheck(FileName_Output,flag_OverwriteYes)) {
		fprintf(stderr,"Don't overwrite. Skip writing file.\n");
		return(FAIL);
		}
	if ((outfile=fopen(FileName_Output,"w"))==NULL) {
		fprintf(stderr,"%s%s: cannot create output file %s\n",
			ERROR_Found,output_Name,FileName_Output);
		return(FAIL);
		}
	}


// Print header
fprintf(outfile,"# produced by psa, version %s\n#\n",VER);
fprintf(outfile,"# File of summed (Sum) and %% (per.) accessibilities\n");
fprintf(outfile,"# probe radius       : %7.3f\n",ProbeSize);
fprintf(outfile,"# integration step   : %7.3f\n",IntegrationStep);
fprintf(outfile,"# water included     :       ");
if(flag_Water)
	fprintf(outfile,"T\n");
else
	fprintf(outfile,"F\n");
fprintf(outfile,"# hetatom included   :       ");
if(flag_Hetatm)
	fprintf(outfile,"T\n");
else
	fprintf(outfile,"F\n");
fprintf(outfile,"# accessibility type : ");
if(flag_ContactTypeSurface)
	fprintf(outfile,"CONTACT\n");
else
	fprintf(outfile,"SURFACE\n");
fprintf(outfile,"# number of residues : %7d\n",Num_AllResidue-SkipRes);
fprintf(outfile,"#\n");
fprintf(outfile,"#       Res   Res   All atoms   Non P side  Polar Side  Total Side  Main Chain\n");
fprintf(outfile,"#       Num  type    Sum  Per.   Sum  Per.   Sum  Per.   Sum  Per.   Sum  Per.\n");


// Print residue accessibility
for(i=0;i<Num_AllResidue;i++) {
	current_ptr_res=Array_PdbResidue[i];
	ResAcc_ptr=ResAcc[i];
	ityp=icode(current_ptr_res->ResName,flag_UNK);
	if(ityp>=20 || current_ptr_res->flag_ishetatm) continue;

	if(current_ptr_res->flag_missing)
		flag='!';
	else
		flag=' ';

	for(j=0;j<10;j++) {
		TempDouble=ResAcc_ptr[j];
		if(TempDouble<0.0 && TempDouble>-0.01)
			ResAcc_ptr[j]=0.0;
		}

	if(icode(current_ptr_res->ResName,FALSE)>=20) {
		fprintf(outfile,"ACCESS %5s  %s %c%6.2f%5.1f %6.2f%5.1f %6.2f%5.1f %6.2f%5.1f %6.2f%5.1f\n",
				current_ptr_res->ResNo,"UNK",'!',
				ResAcc_ptr[0],ResAcc_ptr[1],ResAcc_ptr[2],ResAcc_ptr[3],ResAcc_ptr[4],
				ResAcc_ptr[5],ResAcc_ptr[6],ResAcc_ptr[7],ResAcc_ptr[8],ResAcc_ptr[9]);
		}
	else	{
		fprintf(outfile,"ACCESS %5s  %s %c%6.2f%5.1f %6.2f%5.1f %6.2f%5.1f %6.2f%5.1f %6.2f%5.1f\n",
				current_ptr_res->ResNo,current_ptr_res->ResName,flag,
				ResAcc_ptr[0],ResAcc_ptr[1],ResAcc_ptr[2],ResAcc_ptr[3],ResAcc_ptr[4],
				ResAcc_ptr[5],ResAcc_ptr[6],ResAcc_ptr[7],ResAcc_ptr[8],ResAcc_ptr[9]);
		}
	}

if(!flag_PrintScreen)
	fclose(outfile);

return(SUCCESS);
}




boolean WritePerResAcc(PDBREC *MyPdbRec, MYREAL ProbeSize, MYREAL IntegrationStep,
		 boolean flag_Water, boolean flag_Hetatm, boolean flag_ContactTypeSurface,
		 boolean flag_Verbose, boolean *flag_OverwriteYes, char *FileName_PDB,
		 MYREAL **ResAcc, boolean flag_PrintScreen)
{
int 		i, j;
int		index;
int		Num_AllAtom;
int		Num_AllResidue;
PDBATOM		**Array_PdbAtom;
PDBATOM		*current_ptr;
PDBRESIDUE	**Array_PdbRes;
FILE		*outfile;
FILE		*pdbfile;
char		FileName_Output[MAX_FileNameLen];
char		ResName[PDB_RESNAME_LEN+1];
char		AlterLoc;
char		*ch_ptr;
char		TempStr[TempStr_Length];
MYREAL		*access;
MYREAL		acc;
MYREAL		x;
MYREAL		y;
MYREAL		z;
boolean		isatom;
boolean		iswater;
boolean		ishetatm;
boolean		isvalid;
boolean		ismultimodel;
int		getmodel;
int		model;



// Initialization
ismultimodel=MyPdbRec->ismultimodel;
getmodel=MyPdbRec->getmodel;
Array_PdbAtom=MyPdbRec->Atoms;
Array_PdbRes=MyPdbRec->Residues;
Num_AllAtom=MyPdbRec->Num_AllAtom;
Num_AllResidue=MyPdbRec->Num_AllResidue;
access=(MYREAL *)malloc(sizeof(MYREAL) * Num_AllAtom);
if(access==NULL) {
	fprintf(stderr,"\n%s%s: %s\n\n",ERROR_Found,output_Name,ERROR_MemErr);
	exit(ERROR_Code_MemErr);
	}

if(flag_PrintScreen) {
	outfile=stdout;
	}
else	{
	strcpy(FileName_Output,FileName_PDB);
	ShortFilename(FileName_Output);
	strcat(FileName_Output,PERRESACC_EXT);
	if (!OverwriteCheck(FileName_Output,flag_OverwriteYes)) {
		fprintf(stderr,"Don't overwrite. Skip writing file.\n");
		return(FAIL);
		}
	if ((outfile=fopen(FileName_Output,"w"))==NULL) {
		fprintf(stderr,"%s%s: cannot create output file %s\n",
			ERROR_Found,output_Name,FileName_Output);
		return(FAIL);
		}
	}

if ((pdbfile=fopen(FileName_PDB,"r"))==NULL) {
	fprintf(stderr,"PDB file %s NOT found.\n",FileName_PDB);
	return(FAIL);
	}


// set access info
index=0;
for(i=0;i<Num_AllResidue;i++) {
	acc=ResAcc[i][7];
	for(j=0;j<Array_PdbRes[i]->Num_Atom;j++) {
		access[index]=acc;
		index++;
		}
	}


// Print header
fprintf(outfile,"REMARK     Produced by psa, version %s\n",VER);
fprintf(outfile,"REMARK     Probe_Radius            %5.3f\n",ProbeSize);
fprintf(outfile,"REMARK     Integration_Step        %7.5f\n",IntegrationStep);
fprintf(outfile,"REMARK     Include_Water           ");
if(flag_Water)
	fprintf(outfile,"TRUE\n");
else
	fprintf(outfile,"FALSE\n");
fprintf(outfile,"REMARK     Include_Hetatm          ");
if(flag_Hetatm)
	fprintf(outfile,"TRUE\n");
else
	fprintf(outfile,"FALSE\n");
fprintf(outfile,"REMARK     Accessibility_Type      ");
if(flag_ContactTypeSurface)
	fprintf(outfile,"CONTACT\n");
else
	fprintf(outfile,"SURFACE\n");



/*
 * Print result. Note the temperature factor in the PDB file
 * is replaced by the atom accessibility. If accessibility is
 * not available, it's set to DEFAULT_ACCOUT.
 */

// go to the requested model
if(ismultimodel) {
	while(fgets(TempStr,TempStr_Length,pdbfile)!=NULL) {
		sscanf(TempStr+6,"%d",&model);
		if(model==getmodel && !strncmp(TempStr,"MODEL ",6))
			break;
		}
	if(feof(pdbfile)) {
		fprintf(stderr,"Error in parsing PDB.\n");
		exit(-1);
		}
	}

index=0;
while(fgets(TempStr,TempStr_Length,pdbfile)!=NULL) {
	if(ismultimodel && !strncmp(TempStr,"ENDMDL",6))
		break;

	// is atom or hetatm ?
	isatom=!strncmp(TempStr,"ATOM  ",6);
	ishetatm=!strncmp(TempStr,"HETATM",6);
	if(!(isatom||ishetatm)) {
		fprintf(outfile,"%s",TempStr);
		continue;	// not atom record, print as it is.
		}

	isvalid=TRUE;
	// is Alternate atom ?
	AlterLoc=TempStr[PDB_ALTERLOC_POS-1];
	if(AlterLoc!=' ' && AlterLoc!='A') {
		isvalid=FALSE;
		}
	else	{
		// water or other hetatm ?
		strncpy(ResName,TempStr-1+PDB_RESNAME_POS,PDB_RESNAME_LEN);
		ResName[PDB_RESNAME_LEN]=EOS;
		iswater=!(strcmp(ResName,"WAT") && strcmp(ResName,"HOH") && strcmp(ResName,"MOH"));
		if (iswater) {
			if(!flag_Water) isvalid=FALSE;
			}
		else	{
			if(ishetatm && (!flag_Hetatm)) isvalid=FALSE;
			}
		}

	// set accessibility
	if(isvalid) {	// accessibility already calculated
		// Verify atom coordinates
		current_ptr=Array_PdbAtom[index];
		sscanf(TempStr-1+PDB_X_POS,"%f%f%f",&x,&y,&z);
		if(x!=current_ptr->x || y!=current_ptr->y || z!=current_ptr->z) {
			fprintf(stderr,"Unknown error occurs when writing atom accessibility.\n");
			fprintf(stderr,"Current  coordinates: %8.3f%8.3f%8.3f\n",x,y,z);
			fprintf(stderr,"Expected coordinates: %8.3f%8.3f%8.3f\n",
				current_ptr->x,current_ptr->y,current_ptr->z);
			exit(ERROR_Code_General);
			}
		// set accessibility
		acc=access[index];
		if(acc<0.0 & acc>-0.01)
			acc=0.0;
		index++;
		}
	else	{	// accessibility not available
		acc=DEFAULT_ACCOUT;
		}

	// Print atom accessibility
	ch_ptr=TempStr;
	for(i=0;i<PDB_TEMP_POS-1;i++) {
		putc(*ch_ptr,outfile);
		ch_ptr++;
		}
	fprintf(outfile,"%6.2f",acc);
	fprintf(outfile,"%s",TempStr+PDB_TEMP_POS+5);	// 5=6-1
	}

free(access);
fclose(pdbfile);
if(!flag_PrintScreen)
	fclose(outfile);

return(SUCCESS);
}
