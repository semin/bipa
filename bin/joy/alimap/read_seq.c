/*
 * Function:   1. Check the format of the sequence file.
 *             2. Read in the sequence from the sequence file.
 *
 * Usage:      Seqinfo **read_seq(int *SeqNumber, boolean *flag_SeqAligned, int *SeqFormat,
 *                               char *FileName_Sequence, boolean flag_Verbose);
 *
 *             SeqNumber:          Number of the sequences found.
 *             flag_SeqAligned:    Whether the sequences are aligned. ( TRUE for single sequence )
 *             SeqFormat:          Format of the sequence file.
 *             FileName_Sequence:  Input filename.
 *             flag_Verbose:       Verbose output.
 *
 *             The return value is the pointer to pointer to an array of sequence information.
 *
 */


/********************START**************************/

#define READ_SEQ

/* #include "gen.h" -- included in read_seq.h */
#include "read_seq.h"
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <stdlib.h>
#ifdef MEMDEBUG
        #include "memdebug.h"
#endif


/* Prototype */

Seqinfo **read_FASTA  (int *SeqNumber, boolean *flag_SeqAligned, FILE *in_file, boolean flag_Verbose);
Seqinfo **read_PIR    (int *SeqNumber, boolean *flag_SeqAligned, FILE *in_file, boolean flag_Verbose);
Seqinfo **read_MSF    (int *SeqNumber, boolean *flag_SeqAligned, FILE *in_file, boolean flag_Verbose);
Seqinfo **read_CLUSTAL(int *SeqNumber, boolean *flag_SeqAligned, FILE *in_file, boolean flag_Verbose);
Seqinfo **read_SLX    (int *SeqNumber, boolean *flag_SeqAligned, FILE *in_file, boolean flag_Verbose);



Seqinfo **read_seq(int *SeqNumber, boolean *flag_SeqAligned, int *SeqFormat, char *FileName_Sequence,
		   boolean flag_Verbose)
{

FILE		*in_file=NULL;
int		TempInt;
int		i ,j;
int		Length;
boolean		flag_SameSeqLength;
char		*ch_ptr;
char		TempStr[TempStr_Length];
Seqinfo		**SeqInfo=NULL;
Seqinfo		*SeqInfo_ptr=NULL;

#define		NUM_SEQFORMAT	5

char Format_Name[NUM_SEQFORMAT][MEDIUM_STRING_LEN]={
		"FASTA",
		"PIR",
		"MSF",
		"CLUSTAL",
		"SLX"
	};



if(flag_Verbose)
	printf("Reading target sequence(s) from file %s.\n\n",FileName_Sequence);


/*
 * Open the input file.
 */

if ((in_file=fopen(FileName_Sequence,"r"))==NULL) {
	fprintf(stderr,"%s%s: cannot open file %s\n\n",
		ERROR_Found,read_seq_Name,FileName_Sequence);
	exit(ERROR_Code_FileNotFound);
	}



/*
 * Find the format of the sequence file
 */

if (*SeqFormat>=NUM_SEQFORMAT) {
	fprintf(stderr,"%s%s: sequence format code %d not supported. Use -h option to see the supported formats.\n\n",
		ERROR_Found,read_seq_Name,*SeqFormat);
	exit(ERROR_Code_UnknownSeqFormat);
	}

if (*SeqFormat<0) {
	i=0;
	while (fgets(TempStr,TempStr_Length,in_file)!=NULL) {
		trim_AM(TempStr);
		if ((TempInt=strlen(TempStr))<1) continue;
		i++;

		if (i==1&& (!strncasecmp(TempStr,"#=AU",4) || !strncasecmp(TempStr,"#=RF",4))) {
			*SeqFormat=SEQFORMAT_SLX;
			break;
			}

		if (i==1&&!strncasecmp(TempStr,"CLUSTAL",7)) {
			*SeqFormat=SEQFORMAT_CLUSTAL;
			break;
			}

		if (strstr(TempStr,"//")!=NULL||!strncasecmp(TempStr,"!AA_MULTIPLE_ALIGNMENT 1.0",26)) {
			*SeqFormat=SEQFORMAT_MSF;
			break;
			}

		if (TempStr[0]=='>') {
			if (!strncmp(TempStr,">P1;",4)) {
				*SeqFormat=SEQFORMAT_PIR;
				break;
				}
			else	{
				*SeqFormat=SEQFORMAT_FASTA;
				break;
				}
			}
		}

	if (*SeqFormat<0) {
		fprintf(stderr,"%s%s: cannot determine sequence format automatically in %s. Wrong format?\n",
				ERROR_Found,read_seq_Name,FileName_Sequence);
		fprintf(stderr,"Try specifying sequence format in the command line.\n\n");
		exit(ERROR_Code_UnknownSeqFormat);
		}

	rewind(in_file);
	}

if(flag_Verbose)
	printf("Sequence format expected from file %s: %d  %s\n",
		FileName_Sequence,*SeqFormat,Format_Name[*SeqFormat]);


switch (*SeqFormat) {

	case 0:
		SeqInfo=read_FASTA(SeqNumber, flag_SeqAligned, in_file, flag_Verbose);
		break;

	case 1:
		SeqInfo=read_PIR(SeqNumber, flag_SeqAligned, in_file, flag_Verbose);
		break;

	case 2:
		SeqInfo=read_MSF(SeqNumber, flag_SeqAligned, in_file, flag_Verbose);
		break;

	case 3:
		SeqInfo=read_CLUSTAL(SeqNumber, flag_SeqAligned, in_file, flag_Verbose);
		break; 

	case 4:
		SeqInfo=read_SLX(SeqNumber, flag_SeqAligned, in_file, flag_Verbose);
		break;

	default:
		fprintf(stderr,"%s%s: sequence format code %d not supported. Use -h option to see the supported formats.\n\n",
			ERROR_Found,read_seq_Name,*SeqFormat);
		exit(ERROR_Code_UnknownSeqFormat);
	}


#ifdef DEBUG
printf("Printing the original sequence(s) read in from %s:\n",FileName_Sequence);
for(i=0;i<(*SeqNumber);i++) {
	printf("Sequence %d, length = %d, residue number(excluding X) = %d\n",
		i+1,SeqInfo[i]->length,SeqInfo[i]->length_nogap);
	print_PIR(SCREEN,TRUE,SeqInfo[i]->name,SeqInfo[i]->description,SeqInfo[i]->sequence,FALSE);
	}
#endif


/* Calculate sequence length excluding gaps and set gap symbol to '-' */
/* Change 'J' 'U' 'O' to 'X' */

flag_SameSeqLength=TRUE;
Length=SeqInfo[0]->length;
for(i=0;i<(*SeqNumber);i++) {
	SeqInfo_ptr=SeqInfo[i];
	if (Length!=SeqInfo_ptr->length)
		flag_SameSeqLength=FALSE;

	TempInt=0;
	ch_ptr=SeqInfo_ptr->sequence;
	for(j=0;j<SeqInfo_ptr->length;j++) {
		if(!isalpha(*ch_ptr))
			*ch_ptr='-';
		else if (*ch_ptr=='J' || *ch_ptr=='U' || *ch_ptr=='O') {
			if(flag_Verbose)
				printf("%c found at position %d in sequence %s. Change it to %c.\n",
					*ch_ptr,j+1,SeqInfo_ptr->name,'X');
			*ch_ptr='X';
			}
		else
			TempInt++;

		ch_ptr++;
		}
	SeqInfo_ptr->length_nogap=TempInt;
	}
if (!flag_SameSeqLength)
	*flag_SeqAligned=FALSE;


/* If the sequences are aligned, check whether any column contains only gaps. If true, remove that column. */

if (*flag_SeqAligned) {
	rm_gaponly_column(SeqInfo,*SeqNumber,flag_Verbose);
	}


if (flag_Verbose) {
	printf("\nRead sequence successfully.\n");
	for (i=0;i<(*SeqNumber);i++)
		printf("      %-20s   Length=%d     Residue=%d\n",
			SeqInfo[i]->name,SeqInfo[i]->length,SeqInfo[i]->length_nogap);
	}


/* init chain break */

for(i=0;i<(*SeqNumber);i++)
	SeqInfo[i]->ChainBreak=NULL;


#ifdef DEBUG
printf("Printing the parsed sequence(s) read in from %s:\n",FileName_Sequence);
for(i=0;i<(*SeqNumber);i++) {
	printf("Sequence %d, length = %d, residue number(excluding X) = %d\n",
		i+1,SeqInfo[i]->length,SeqInfo[i]->length_nogap);
	print_PIR(SCREEN,TRUE,SeqInfo[i]->name,SeqInfo[i]->description,SeqInfo[i]->sequence,FALSE);
	}
#endif

fclose(in_file);

return(SeqInfo);

}






/************************************
 * Reading sequence in FASTA format *
 ************************************/

Seqinfo **read_FASTA(int *SeqNumber, boolean *flag_SeqAligned, FILE *in_file, boolean flag_Verbose)
{

int		index;
int		Length;
int		MaxLength;
int		LineLength;
int		i;
int		size;
char		TempStr[TempStr_Length];
char		TempStr2[TempStr_Length];
Seqinfo		**SeqInfo=NULL;
Seqinfo		*SeqInfo_ptr=NULL;

/* find out the number of sequences in the file and the maximum length */

MaxLength=0;
Length=0;
index=0;  /* index for the sequence */
while(fgets(TempStr,TempStr_Length,in_file)!=NULL) {
	trim_AM(TempStr);
	LineLength=strlen(TempStr);
	if (LineLength<1) continue;

	if (TempStr[0]=='>') {    /* find a new sequence */
		if (MaxLength<Length)
			MaxLength=Length;
		Length=0;
		index++;
		continue;
		}

	for (i=0;i<LineLength;i++) {
		if (isgraph(TempStr[i]))
			Length++;
		}
	}

if (index<1) {
	fprintf(stderr,"%s%s: no sequence found!\n\n",ERROR_Found,read_seq_Name);
	exit(ERROR_Code_NoSeqFound);
	}
*SeqNumber=index;
if (MaxLength<Length)     /* deal with the last sequence */
	MaxLength=Length;

if (flag_Verbose)
	printf("Sequence(s) found: %d\n",*SeqNumber);



/* Allocate memory */

SeqInfo=(Seqinfo **)malloc(sizeof(Seqinfo *)*index);
if (SeqInfo==NULL) {
	fprintf(stderr,"%s%s: %s\n\n",ERROR_Found,read_seq_Name,ERROR_MemErr);
	exit(ERROR_Code_MemErr);
	}

size=sizeof(char)*(MaxLength+1);
for (i=0;i<index;i++) {
	SeqInfo[i]=(Seqinfo *)malloc(sizeof(Seqinfo));
	SeqInfo_ptr=SeqInfo[i];
	if (SeqInfo_ptr==NULL) {
		fprintf(stderr,"%s%s: %s\n\n",ERROR_Found,read_seq_Name,ERROR_MemErr);
		exit(ERROR_Code_MemErr);
		}
	SeqInfo_ptr->sequence=(char *)malloc(size);
	if (SeqInfo_ptr->sequence==NULL) {
		fprintf(stderr,"%s%s: %s\n\n",ERROR_Found,read_seq_Name,ERROR_MemErr);
		exit(ERROR_Code_MemErr);
		}

	strcpy(SeqInfo_ptr->description,"sequence"); /* no description in FASTA format */
	}

if (flag_Verbose)
	printf("Memory allocated successfully.\n");



/* Read sequences */

rewind(in_file);

index=-1;
Length=0;
while(fgets(TempStr,TempStr_Length,in_file)!=NULL) {
	trim_AM(TempStr);
	LineLength=strlen(TempStr);
	if (LineLength<1) continue;

	if (TempStr[0]=='>') {    /* find a new sequence */
		if(index>-1) {
			TempStr2[Length]=EOS;
			strcpy(SeqInfo_ptr->sequence,TempStr2);
			SeqInfo_ptr->length=Length;
			}
		Length=0;
		index++;
		SeqInfo_ptr=SeqInfo[index];
		strcpy(SeqInfo_ptr->name,TempStr+1);
		continue;
		}

	for (i=0;i<LineLength;i++) {
		if (isgraph(TempStr[i])) {
			TempStr2[Length]=TempStr[i];
			Length++;
			}
		}
	}

TempStr2[Length]=EOS;          /* deal with the last sequence */
strcpy(SeqInfo_ptr->sequence,TempStr2);
SeqInfo_ptr->length=Length;


return(SeqInfo);

}




/************************************
 * Reading sequence in PIR format   *
 ************************************/

Seqinfo **read_PIR(int *SeqNumber, boolean *flag_SeqAligned, FILE *in_file, boolean flag_Verbose)
{

int		index;
int		Length;
int		MaxLength;
int		LineLength;
int		size;
int		i;
char		TempStr[TempStr_Length];
char		TempStr2[TempStr_Length];
Seqinfo		**SeqInfo=NULL;
Seqinfo		*SeqInfo_ptr=NULL;

/* find out the number of sequences in the file and the maximum length */

MaxLength=0;
Length=0;
index=0;  /* index for the sequence */
while(fgets(TempStr,TempStr_Length,in_file)!=NULL) {
	trim_AM(TempStr);
	LineLength=strlen(TempStr);
	if (LineLength<1) continue;

	if (TempStr[0]=='>') {    /* find a new sequence */
		if (MaxLength<Length)
			MaxLength=Length;
		Length=0;
		index++;
		continue;
		}

	for (i=0;i<LineLength;i++) {
		if (isgraph(TempStr[i]))
			Length++;
		}
	}

if (index<1) {
	fprintf(stderr,"%s%s: no sequence found!\n\n",ERROR_Found,read_seq_Name);
	exit(ERROR_Code_NoSeqFound);
	}
*SeqNumber=index;
if (MaxLength<Length)     /* deal with the last sequence */
	MaxLength=Length;

if (flag_Verbose)
	printf("Sequence(s) found: %d\n",*SeqNumber);



/* Allocate memory */

SeqInfo=(Seqinfo **)malloc(sizeof(Seqinfo *)*index);
if (SeqInfo==NULL) {
	fprintf(stderr,"%s%s: %s\n\n",ERROR_Found,read_seq_Name,ERROR_MemErr);
	exit(ERROR_Code_MemErr);
	}

size=sizeof(char)*(MaxLength+1);
for (i=0;i<index;i++) {
	SeqInfo[i]=(Seqinfo *)malloc(sizeof(Seqinfo));
	SeqInfo_ptr=SeqInfo[i];
	if (SeqInfo_ptr==NULL) {
		fprintf(stderr,"%s%s: %s\n\n",ERROR_Found,read_seq_Name,ERROR_MemErr);
		exit(ERROR_Code_MemErr);
		}
	SeqInfo_ptr->sequence=(char *)malloc(size);
	if (SeqInfo_ptr->sequence==NULL) {
		fprintf(stderr,"%s%s: %s\n\n",ERROR_Found,read_seq_Name,ERROR_MemErr);
		exit(ERROR_Code_MemErr);
		}
	}

if (flag_Verbose)
	printf("Memory allocated successfully.\n");



/* Read sequences */

rewind(in_file);

index=-1;
Length=0;
while(fgets(TempStr,TempStr_Length,in_file)!=NULL) {
	trim_AM(TempStr);
	LineLength=strlen(TempStr);
	if (LineLength<1) continue;

	if (!strncmp(TempStr,PIR_ENTERY,PIR_ENTERY_LEN)) {    /* find a new sequence */
		if(index>-1) {
			Length--;
			if (TempStr2[Length]!='*') {
				fprintf(stderr,"%s%s: PIR format sequence must end with '*'\n\n",ERROR_Found,read_seq_Name);
				exit(ERROR_Code_UnknownSeqFormat);
				}
			TempStr2[Length]='\0';
			strcpy(SeqInfo_ptr->sequence,TempStr2);
			SeqInfo_ptr->length=Length;
			}
		Length=0;
		index++;
		SeqInfo_ptr=SeqInfo[index];
		strcpy(SeqInfo_ptr->name,TempStr+PIR_ENTERY_LEN);
		fgets(SeqInfo_ptr->description,MAX_SeqInfoLength,in_file);
		continue;
		}

	for (i=0;i<LineLength;i++) {
		if (isgraph(TempStr[i])) {
			TempStr2[Length]=TempStr[i];
			Length++;
			}
		}
	}

Length--;
if (TempStr2[Length]!='*') {
	fprintf(stderr,"%s%s: PIR format sequence must end with '*'\n\n",ERROR_Found,read_seq_Name);
	exit(ERROR_Code_UnknownSeqFormat);
	}
TempStr2[Length]='\0';          /* deal with the last sequence */
strcpy(SeqInfo_ptr->sequence,TempStr2);
SeqInfo_ptr->length=Length;


return(SeqInfo);

}




/************************************
 * Reading sequence in SLX format   *
 ************************************/

Seqinfo **read_SLX(int *SeqNumber, boolean *flag_SeqAligned, FILE *in_file, boolean flag_Verbose)
{

int		index;
int		MaxLength;
int		i, j, k;
int		iteration;
int		size;
int		TempInt;
char		TempStr[TempStr_Length];
char		TempStr2[TempStr_Length];
char		ch;
char		*seq_ptr=NULL;
Seqinfo		**SeqInfo=NULL;
Seqinfo		*SeqInfo_ptr=NULL;


/* find out the number of sequences in the file */

while(fgets(TempStr,TempStr_Length,in_file)!=NULL&&strncmp(TempStr,"#=RF",4)) ; /* get to the leading line */
if (feof(in_file)) {
	fprintf(stderr,"%s%s: unexpected end of SLX format (cannot find '#=RF') \n\n",ERROR_Found,read_seq_Name);
	exit(ERROR_Code_UnknownSeqFormat);
	}

index=0;  /* index for the sequence */
while(fgets(TempStr,TempStr_Length,in_file)!=NULL&&isgraph(TempStr[0])) {  /* get to the next blank line */
	index++;
	}
*SeqNumber=index;

if (flag_Verbose)
	printf("Sequence(s) found: %d\n",*SeqNumber);



/* Allocate memory Part 1 */

SeqInfo=(Seqinfo **)malloc(sizeof(Seqinfo *)*index);
if (SeqInfo==NULL) {
	fprintf(stderr,"%s%s: %s\n\n",ERROR_Found,read_seq_Name,ERROR_MemErr);
	exit(ERROR_Code_MemErr);
	}

for (i=0;i<index;i++) {
	SeqInfo[i]=(Seqinfo *)malloc(sizeof(Seqinfo));
	SeqInfo_ptr=SeqInfo[i];
	if (SeqInfo_ptr==NULL) {
		fprintf(stderr,"%s%s: %s\n\n",ERROR_Found,read_seq_Name,ERROR_MemErr);
		exit(ERROR_Code_MemErr);
		}
	strcpy(SeqInfo_ptr->description,"sequence");
	SeqInfo_ptr->length=0;
	}

if (flag_Verbose)
	printf("Memory Part 1 allocated successfully.\n");



/* Get the sequence name and sequence length */

rewind(in_file);
iteration=0;
while(fgets(TempStr,TempStr_Length,in_file)!=NULL) {
	if(strncmp(TempStr,"#=RF",4)) continue;

	iteration++;
	for (i=0;i<(*SeqNumber);i++) {
		if(fgets(TempStr,TempStr_Length,in_file)==NULL) {
			fprintf(stderr,"%s%s: reading SLX format error\n\n",ERROR_Found,read_seq_Name);
			exit(ERROR_Code_UnknownSeqFormat);
			}

		SeqInfo_ptr=SeqInfo[i];

		if(!isgraph(TempStr[0])) {
			fprintf(stderr,"%s%s: reading SLX format error\n\n",ERROR_Found,read_seq_Name);
			exit(ERROR_Code_UnknownSeqFormat);
			}
		if(iteration==1)
			sscanf(TempStr,"%s",SeqInfo_ptr->name);
		else	{
			sscanf(TempStr,"%s",TempStr2);
			if(strcmp(TempStr2,SeqInfo_ptr->name)) {
				fprintf(stderr,"%s%s: sequence name NOT consistant (%s / %s)\n\n",
					ERROR_Found,read_seq_Name,SeqInfo[i]->name,TempStr2);
				exit(ERROR_Code_UnknownSeqFormat);
				}
			}
		k=0;
		for(j=strlen(SeqInfo_ptr->name);j<strlen(TempStr);j++) {
			if(isgraph(TempStr[j]))
				k++;
			}
		SeqInfo_ptr->length+=k;

		}
	}

MaxLength=0;
for(i=0;i<(*SeqNumber);i++) {
	TempInt=SeqInfo[i]->length;
	MaxLength=max(MaxLength,TempInt);
	}
for(i=0;i<(*SeqNumber);i++)
	SeqInfo[i]->length=MaxLength;


/* Allocate memory Part 2 */

size=sizeof(char)*(MaxLength+1);
for(i=0;i<(*SeqNumber);i++) {
	SeqInfo[i]->sequence=(char *)malloc(size);
	seq_ptr=SeqInfo[i]->sequence;
	if (seq_ptr==NULL) {
		fprintf(stderr,"%s%s: %s\n\n",ERROR_Found,read_seq_Name,ERROR_MemErr);
		exit(ERROR_Code_MemErr);
		}
	seq_ptr[0]=EOS;
	}

if (flag_Verbose)
	printf("Memory Part 2 allocated successfully.\n");



/* Read sequences */

rewind(in_file);
while(fgets(TempStr,TempStr_Length,in_file)!=NULL) {
	if(strncmp(TempStr,"#=RF",4)) continue;

	for (i=0;i<(*SeqNumber);i++) {
		if(fgets(TempStr,TempStr_Length,in_file)==NULL) {
			fprintf(stderr,"%s%s: reading SLX format error\n\n",ERROR_Found,read_seq_Name);
			exit(ERROR_Code_UnknownSeqFormat);
			}

		k=0;
		SeqInfo_ptr=SeqInfo[i];
		for(j=strlen(SeqInfo_ptr->name);j<strlen(TempStr);j++) {
			ch=TempStr[j];
			if(isgraph(ch)) {
				TempStr2[k]=ch;
				k++;
				}
			}
		TempStr2[k]='\0';
		strcat(SeqInfo_ptr->sequence,TempStr2);

		}
	}


/* Verify sequence length */

for (i=0;i<(*SeqNumber);i++) {
	seq_ptr=SeqInfo[i]->sequence;
	TempInt=strlen(seq_ptr);
	memset(seq_ptr+TempInt,'-',MaxLength-TempInt);
	seq_ptr[MaxLength]=EOS;
	}

return(SeqInfo);

}




/************************************
 * Reading sequence in MSF format *
 ************************************/

Seqinfo **read_MSF(int *SeqNumber, boolean *flag_SeqAligned, FILE *in_file, boolean flag_Verbose)
{

int		index;
int		MaxLength;
long		flocation;
int		i, j, k;
int		iteration;
int		TempInt;
int		size;
char		TempStr[TempStr_Length+1];
char		TempStr2[TempStr_Length+1];
char		ch;
char		*seq_ptr;
Seqinfo		**SeqInfo;
Seqinfo		*SeqInfo_ptr;


/* find out the number of sequences in the file */

while(fscanf(in_file,"%s",TempStr)!=0 && strcmp(TempStr,"//")) ;  /* get to the separation bar */
flocation=ftell(in_file);

TempStr[0]='\0';
while(fgets(TempStr,TempStr_Length,in_file)!=NULL) {
	trim_AM(TempStr);
	if(isgraph(TempStr[0]))
		break;
	}	 /* get to the first line of sequences */
if (feof(in_file)) {
	fprintf(stderr,"%s%s: unexpected end of MSF format (cannot find '//') \n\n",ERROR_Found,read_seq_Name);
	exit(ERROR_Code_UnknownSeqFormat);
	}

index=0;  /* index for the sequence */
do	{
	trim_AM(TempStr);
	if(!isgraph(TempStr[0]))
		break;
	index++;
	}
while(fgets(TempStr,TempStr_Length,in_file)!=NULL); 	/* get to the next blank line */
*SeqNumber=index;

if (flag_Verbose)
	printf("Sequence(s) found: %d\n",*SeqNumber);



/* Allocate memory Part 1 */

SeqInfo=(Seqinfo **)malloc(sizeof(Seqinfo *)*index);
if (SeqInfo==NULL) {
	fprintf(stderr,"%s%s: %s\n\n",ERROR_Found,read_seq_Name,ERROR_MemErr);
	exit(ERROR_Code_MemErr);
	}

for (i=0;i<index;i++) {
	SeqInfo[i]=(Seqinfo *)malloc(sizeof(Seqinfo));
	SeqInfo_ptr=SeqInfo[i];
	if (SeqInfo_ptr==NULL) {
		fprintf(stderr,"%s%s: %s\n\n",ERROR_Found,read_seq_Name,ERROR_MemErr);
		exit(ERROR_Code_MemErr);
		}
	strcpy(SeqInfo_ptr->description,"sequence");
	SeqInfo_ptr->length=0;
	}

if (flag_Verbose)
	printf("Memory Part 1 allocated successfully.\n");



/* Get the sequence name and sequence length */

fseek(in_file,flocation,SEEK_SET);
TempStr[0]=EOS;
while(fgets(TempStr,TempStr_Length,in_file)!=NULL) {
	trim_AM(TempStr);
	if(isgraph(TempStr[0]))
		break;
	}	/* get to the first line of sequences */
iteration=0;
do	{
	trim_AM(TempStr);
	if(!isgraph(TempStr[0])) continue;

	iteration++;
	for (i=0;i<(*SeqNumber);i++) {
		SeqInfo_ptr=SeqInfo[i];

		if(!isgraph(TempStr[0])) {
			fprintf(stderr,"%s%s: reading MSF format error\n\n",ERROR_Found,read_seq_Name);
			exit(ERROR_Code_UnknownSeqFormat);
			}
		if(iteration==1)
			sscanf(TempStr,"%s",SeqInfo_ptr->name);
		else	{
			sscanf(TempStr,"%s",TempStr2);
			if(strcmp(TempStr2,SeqInfo_ptr->name)) {
				fprintf(stderr,"%s%s: sequence name NOT consistant (%s / %s)\n\n",
					ERROR_Found,read_seq_Name,SeqInfo_ptr->name,TempStr2);
				exit(ERROR_Code_UnknownSeqFormat);
				}
			}
		k=0;
		for(j=strlen(SeqInfo_ptr->name);j<strlen(TempStr);j++) {
			if(isgraph(TempStr[j]))
				k++;
			}
		SeqInfo_ptr->length+=k;

		if(i<(*SeqNumber-1)) {
			if(fgets(TempStr,TempStr_Length,in_file)==NULL) {
				fprintf(stderr,"%s%s: reading MSF format error\n\n",ERROR_Found,read_seq_Name);
				exit(ERROR_Code_UnknownSeqFormat);
				}
			trim_AM(TempStr);
			}
		}
	}
while(fgets(TempStr,TempStr_Length,in_file)!=NULL);

MaxLength=0;
for(i=0;i<(*SeqNumber);i++) {
	TempInt=SeqInfo[i]->length;
	MaxLength=max(TempInt,MaxLength);
	}


/* Allocate memory Part 2 */

size=sizeof(char)*(MaxLength+1);
for(i=0;i<(*SeqNumber);i++) {
	SeqInfo[i]->sequence=(char *)malloc(size);
	seq_ptr=SeqInfo[i]->sequence;
	if (seq_ptr==NULL) {
		fprintf(stderr,"%s%s: %s\n\n",ERROR_Found,read_seq_Name,ERROR_MemErr);
		exit(ERROR_Code_MemErr);
		}
	seq_ptr[0]=EOS;
	}

if (flag_Verbose)
	printf("Memory Part 2 allocated successfully.\n");



/* Read sequences */

fseek(in_file,flocation,SEEK_SET);
TempStr[0]=EOS;
while(fgets(TempStr,TempStr_Length,in_file)!=NULL) {
	trim_AM(TempStr);
	if(isgraph(TempStr[0]))
		break;
	}	/* get to the first line of sequences */

do	{
	trim_AM(TempStr);
	if(!isgraph(TempStr[0])) continue;

	for (i=0;i<(*SeqNumber);i++) {
		k=0;
		SeqInfo_ptr=SeqInfo[i];
		for(j=strlen(SeqInfo_ptr->name);j<strlen(TempStr);j++) {
			ch=toupper(TempStr[j]);
			if(isgraph(ch)) {
				TempStr2[k]=ch;
				k++;
				}
			}
		TempStr2[k]='\0';
		strcat(SeqInfo_ptr->sequence,TempStr2);

		if(i<(*SeqNumber-1)) {
			if(fgets(TempStr,TempStr_Length,in_file)==NULL) {
				fprintf(stderr,"%s%s: reading MSF format error\n\n",ERROR_Found,read_seq_Name);
				exit(ERROR_Code_UnknownSeqFormat);
				}
			trim_AM(TempStr);
			}
		}
	}
while(fgets(TempStr,TempStr_Length,in_file)!=NULL);


/* Verify sequence length */

for (i=0;i<(*SeqNumber);i++) {
	SeqInfo_ptr=SeqInfo[i];
	if(strlen(SeqInfo_ptr->sequence)!=SeqInfo_ptr->length) {
		fprintf(stderr,"%s%s: sequence length for %s NOT consistant (%d / %d)\n\n",ERROR_Found,
			read_seq_Name,SeqInfo_ptr->name,SeqInfo_ptr->length,strlen(SeqInfo_ptr->sequence));
		exit(ERROR_Code_UnknownSeqFormat);
		}
	}


return(SeqInfo);

}


/************************************
 * Reading sequence in CLUSTAL format *
 ************************************/

Seqinfo **read_CLUSTAL(int *SeqNumber, boolean *flag_SeqAligned, FILE *in_file, boolean flag_Verbose)
{

int		index;
int		MaxLength;
long		flocation;
int		i, j, k;
int		iteration;
int		size;
int		TempInt;
char		TempStr[TempStr_Length+1];
char		TempStr2[TempStr_Length+1];
char		ch;
char		*seq_ptr=NULL;
Seqinfo		**SeqInfo=NULL;
Seqinfo		*SeqInfo_ptr=NULL;


/* find out the number of sequences in the file */

while(fgets(TempStr,TempStr_Length,in_file)!=NULL&&strncmp(TempStr,"CLUSTAL",7)) ; /* get to the leading line */
flocation=ftell(in_file);

TempStr[0]=EOS;
while(fgets(TempStr,TempStr_Length,in_file)!=NULL&&!isgraph(TempStr[0])) ; /* get to the first line of sequences */
if (feof(in_file)) {
	fprintf(stderr,"%s%s: unexpected end of CLUSTAL format (cannot find the first sequence) \n\n",ERROR_Found,read_seq_Name);
	exit(ERROR_Code_UnknownSeqFormat);
	}

index=0;  /* index for the sequence */
do	{
	index++;
	}
while(fgets(TempStr,TempStr_Length,in_file)!=NULL&&isgraph(TempStr[0]));  /* get to the next blank line */
*SeqNumber=index;

if (flag_Verbose)
	printf("Sequence(s) found: %d\n",*SeqNumber);



/* Allocate memory Part 1 */

SeqInfo=(Seqinfo **)malloc(sizeof(Seqinfo *)*index);
if (SeqInfo==NULL) {
	fprintf(stderr,"%s%s: %s\n\n",ERROR_Found,read_seq_Name,ERROR_MemErr);
	exit(ERROR_Code_MemErr);
	}

for (i=0;i<index;i++) {
	SeqInfo[i]=(Seqinfo *)malloc(sizeof(Seqinfo));
	SeqInfo_ptr=SeqInfo[i];
	if (SeqInfo_ptr==NULL) {
		fprintf(stderr,"%s%s: %s\n\n",ERROR_Found,read_seq_Name,ERROR_MemErr);
		exit(ERROR_Code_MemErr);
		}
	strcpy(SeqInfo_ptr->description,"sequence");
	SeqInfo_ptr->length=0;
	}

if (flag_Verbose)
	printf("Memory Part 1 allocated successfully.\n");



/* Get the sequence name and sequence length */

fseek(in_file,flocation,SEEK_SET);
TempStr[0]='\0';
while(fgets(TempStr,TempStr_Length,in_file)!=NULL&&!isgraph(TempStr[0]));  /* get to the first line of sequences */
iteration=0;
do	{
	if(!isgraph(TempStr[0])) continue;

	iteration++;
	for (i=0;i<(*SeqNumber);i++) {
		SeqInfo_ptr=SeqInfo[i];

		if(!isgraph(TempStr[0])) {
			fprintf(stderr,"%s%s: reading CLUSTAL format error\n\n",ERROR_Found,read_seq_Name);
			exit(ERROR_Code_UnknownSeqFormat);
			}
		if(iteration==1)
			sscanf(TempStr,"%s",SeqInfo_ptr->name);
		else	{
			sscanf(TempStr,"%s",TempStr2);
			if(strcmp(TempStr2,SeqInfo_ptr->name)) {
				fprintf(stderr,"%s%s: sequence name NOT consistant (%s / %s)\n\n",
					ERROR_Found,read_seq_Name,SeqInfo[i]->name,TempStr2);
				exit(ERROR_Code_UnknownSeqFormat);
				}
			}
		k=0;
		for(j=strlen(SeqInfo_ptr->name);j<strlen(TempStr);j++) {
			if(isgraph(TempStr[j]))
				k++;
			}
		SeqInfo_ptr->length+=k;

		if(i<(*SeqNumber-1)) {
			if(fgets(TempStr,TempStr_Length,in_file)==NULL) {
				fprintf(stderr,"%s%s: reading CLUSTAL format error\n\n",ERROR_Found,read_seq_Name);
				exit(ERROR_Code_UnknownSeqFormat);
				}
			}
		}
	}
while(fgets(TempStr,TempStr_Length,in_file)!=NULL);

MaxLength=0;
for(i=0;i<(*SeqNumber);i++) {
	TempInt=SeqInfo[i]->length;
	MaxLength=max(MaxLength,TempInt);
	}


/* Allocate memory Part 2 */

size=sizeof(char)*(MaxLength+1);
for(i=0;i<(*SeqNumber);i++) {
	SeqInfo[i]->sequence=(char *)malloc(size);
	seq_ptr=SeqInfo[i]->sequence;
	if (seq_ptr==NULL) {
		fprintf(stderr,"%s%s: %s\n\n",ERROR_Found,read_seq_Name,ERROR_MemErr);
		exit(ERROR_Code_MemErr);
		}
	seq_ptr[0]=EOS;
	}

if (flag_Verbose)
	printf("Memory Part 2 allocated successfully.\n");



/* Read sequences */

fseek(in_file,flocation,SEEK_SET);
TempStr[0]='\0';
while(fgets(TempStr,TempStr_Length,in_file)!=NULL&&!isgraph(TempStr[0]));  /* get to the first line of sequences */
do	{
	if(!isgraph(TempStr[0])) continue;

	for (i=0;i<(*SeqNumber);i++) {
		k=0;
		SeqInfo_ptr=SeqInfo[i];
		for(j=strlen(SeqInfo_ptr->name);j<strlen(TempStr);j++) {
			ch=toupper(TempStr[j]);
			if(isgraph(ch)) {
				TempStr2[k]=ch;
				k++;
				}
			}
		TempStr2[k]='\0';
		strcat(SeqInfo_ptr->sequence,TempStr2);

		if(i<(*SeqNumber-1)) {
			if(fgets(TempStr,TempStr_Length,in_file)==NULL) {
				fprintf(stderr,"%s%s: reading CLUSTAL format error\n\n",ERROR_Found,read_seq_Name);
				exit(ERROR_Code_UnknownSeqFormat);
				}
			}
		}
	}
while(fgets(TempStr,TempStr_Length,in_file)!=NULL);


/* Verify sequence length */

for (i=0;i<(*SeqNumber);i++) {
	SeqInfo_ptr=SeqInfo[i];
	if(strlen(SeqInfo_ptr->sequence)!=SeqInfo_ptr->length) {
		fprintf(stderr,"%s%s: sequence length for %s NOT consistant (%d / %d)\n\n",ERROR_Found,
			read_seq_Name,SeqInfo_ptr->name,SeqInfo_ptr->length,strlen(SeqInfo_ptr->sequence));
		exit(ERROR_Code_UnknownSeqFormat);
		}
	}


return(SeqInfo);

}





char **SeqArray(Seqinfo **SeqInfo, int SeqNumber)
{
int		i;
char		**sequence;

sequence=(char **)malloc(sizeof(char *)*SeqNumber);
if (sequence==NULL) {
	fprintf(stderr,"%s%s: %s\n\n",ERROR_Found,read_seq_Name,ERROR_MemErr);
	exit(ERROR_Code_MemErr);
	}
for (i=0;i<SeqNumber;i++)
	sequence[i]=SeqInfo[i]->sequence;

return(sequence);
}


void free_SeqArray(char **sequence)
{
free(sequence);
}


void free_seqinfo(Seqinfo **SeqInfo, int SeqNumber)
{
int		i;
Seqinfo		*SeqInfo_ptr;

for (i=0;i<SeqNumber;i++) {
	SeqInfo_ptr=SeqInfo[i];
	if(SeqInfo_ptr->ChainBreak!=NULL)
		free(SeqInfo_ptr->ChainBreak);
	free(SeqInfo_ptr->sequence);
	free(SeqInfo_ptr);
	}
free(SeqInfo);
}




void rm_gaponly_column(Seqinfo **SeqInfo, int SeqNumber, boolean flag_Verbose)
{
int		i, j, k;
int		TempInt;
char		*ch_ptr;
Seqinfo		*SeqInfo_ptr;

for(j=0;j<SeqInfo[0]->length;j++) {
	TempInt=0;
	for(i=0;i<SeqNumber;i++) {
		if(SeqInfo[i]->sequence[j]=='-')
			TempInt++;
		}
	if(TempInt==SeqNumber) {       /* all gaps in the column! */
		for(i=0;i<SeqNumber;i++) {
			SeqInfo_ptr=SeqInfo[i];
			ch_ptr=SeqInfo_ptr->sequence+j;
			for(k=j;k<SeqInfo_ptr->length-1;k++) {
				*ch_ptr=*(ch_ptr+1);
				ch_ptr++;
				}
			*ch_ptr=EOS;
			(SeqInfo_ptr->length)--;
			}
		if(flag_Verbose) {
			printf("Warning: column %d in the alignment consists of only gap symbol. Column removed.\n",
				j+1);
			printf("Alignment position re-assigned due to the removal of the gap column.\n");
			}
		j--;
		}
	}

return;
}


void rm_gaponly_column_single(Seqinfo *SeqInfo, boolean flag_Verbose)
{
int		i, j, k;
int		TempInt;
int		SeqNumber=1;
char		*ch_ptr;

for(j=0;j<SeqInfo->length;j++) {
	TempInt=0;
	for(i=0;i<SeqNumber;i++) {
		if(SeqInfo->sequence[j]=='-')
			TempInt++;
		}
	if(TempInt==SeqNumber) {       /* all gaps in the column! */
		for(i=0;i<SeqNumber;i++) {
			ch_ptr=SeqInfo->sequence+j;
			for(k=j;k<SeqInfo->length-1;k++) {
				*ch_ptr=*(ch_ptr+1);
				ch_ptr++;
				}
			*ch_ptr=EOS;
			(SeqInfo->length)--;
			}
		if(flag_Verbose) {
			printf("Warning: column %d in the alignment consists of only gap symbol. Column removed.\n",
				j+1);
			printf("Alignment position re-assigned due to the removal of the gap column.\n");
			}
		j--;
		}
	}

return;
}
