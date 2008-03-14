#include "gen.h"
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <stdlib.h>
#include <math.h>

#ifdef DOS
	#include <io.h>
#else
	#include <unistd.h>
#endif

#ifdef MEMDEBUG
	#include "memdebug.h"
#endif


/*
 * Get rid of the non-printable characters and space at both ends
 * of the input string.
 */

void trim_AM(char *line)
{
int i, j, length;

/* trim right */
length=strlen(line);
for (i=length-1;i>=0;i--)
	if (isgraph(line[i])) break;
line[i+1]=EOS;

/* trim left */
length=i+1;
for (i=0;i<length;i++)
	if (isgraph(line[i])) break;
for (j=i;j<=length;j++)
	line[j-i]=line[j];

return;
}




/*
 * Get rid of the non-alnum characters (excluding '(' and ')') and space at both ends
 * of the input string.
 */

void trimalnum(char *line)
{
int i, j, length;
char ch;

/* trim right */
length=strlen(line);
for (i=length-1;i>=0;i--) {
	ch=line[i];
	if (isalnum(ch) || ch=='(' || ch==')') break;
	}
line[i+1]=EOS;

/* trim left */
length=i+1;
for (i=0;i<length;i++) {
	ch=line[i];
	if (isalnum(ch) || ch=='(' || ch==')') break;
	}
for (j=i;j<=length;j++)
	line[j-i]=line[j];

return;
}





/*
 * Print FASTA format to file or standerd output. The sequence length in each line is
 * defined in gen.h as PIR_Width.
 */

void print_FASTA(char *outfile, boolean flag_Append, char *name, char *description, char *sequence,
		boolean flag_ChangeJU)
{
int	i;
boolean	isstdout;
char	mode[2];
char	ch;
FILE	*out;

isstdout=!strcmp(outfile,SCREEN);	/* standerd output ? */

if(isstdout) {
	out=stdout;
	}
else	{
	if (flag_Append)
		strcpy(mode,"a");
	else
		strcpy(mode,"w");

	if ((out=fopen(outfile,mode))==NULL) {
		fprintf(stderr,"\ncannot open output file (%s) for the alignment.\n",outfile);
		exit(ERROR_Code_CreateFileFail);
		}
	}


trim_AM(name);
if (name[0]!='>')
	fputc('>',out);
for (i=0;i<strlen(name);i++)
	if (isprint(name[i])) putc(name[i],out);
putc(' ',out);

trim_AM(description);
for (i=0;i<strlen(description);i++)
	if (isprint(description[i])) putc(description[i],out);
putc(EOL,out);

for (i=0;i<strlen(sequence);i++) {
	ch=sequence[i];
	if(flag_ChangeJU) {
		if(ch=='j' || ch=='u')
			ch='c';
		else if(ch=='J' || ch=='U')
			ch='C';
		}
	if (isgraph(ch)) {
		putc(ch,out);
		if ((i+1)%PIR_Width==0) putc(EOL,out);
		}
	}
putc(EOL,out);

if(!isstdout)
	fclose(out);

return;
}




/*
 * Print PIR format to file or standerd output. The sequence length in each line is
 * defined in gen.h as PIR_Width.
 */

void print_PIR(char *outfile, boolean flag_Append, char *name, char *description, char *sequence,
		boolean flag_ChangeJU)
{
int	i;
boolean	isstdout;
char	lastchar=EOS;
char	mode[2];
char	ch;
FILE	*out;

isstdout=!strcmp(outfile,SCREEN);	/* standerd output ? */

if(isstdout) {
	out=stdout;
	}
else	{
	if (flag_Append)
		strcpy(mode,"a");
	else
		strcpy(mode,"w");

	if ((out=fopen(outfile,mode))==NULL) {
		fprintf(stderr,"\ncannot open output file (%s) for the alignment.\n",outfile);
		exit(ERROR_Code_CreateFileFail);
		}
	}


trim_AM(name);
if (strncmp(name,">P1;",4))
	fprintf(out,">P1;");
for (i=0;i<strlen(name);i++)
	if (isprint(name[i])) putc(name[i],out);
putc(EOL,out);

trim_AM(description);
for (i=0;i<strlen(description);i++)
	if (isprint(description[i])) putc(description[i],out);
putc(EOL,out);

for (i=0;i<strlen(sequence);i++) {
	ch=sequence[i];
	if(flag_ChangeJU) {
		if(ch=='j' || ch=='u')
			ch='c';
		else if(ch=='J' || ch=='U')
			ch='C';
		}
	if (isgraph(ch)) {
		putc(ch,out);
		lastchar=ch;
		if ((i+1)%PIR_Width==0) putc(EOL,out);
		}
	}
if (lastchar!='*') putc('*',out);
putc(EOL,out);

if(!isstdout)
	fclose(out);

return;
}




/*
 * Print PIR format to file or standerd output excluding residues masked.
 * The sequence length in each line is defined in gen.h as PIR_Width.
 */

void print_PIR_mask(char *outfile, boolean flag_Append, char *name, char *description, char *sequence,
		boolean *mask, boolean flag_ChangeJU)
{
int	i;
int	index;
boolean	isstdout;
char	lastchar=EOS;
char	mode[2];
char	ch;
FILE	*out;

isstdout=!strcmp(outfile,SCREEN);	/* standerd output ? */

if(isstdout) {
	out=stdout;
	}
else	{
	if (flag_Append)
		strcpy(mode,"a");
	else
		strcpy(mode,"w");

	if ((out=fopen(outfile,mode))==NULL) {
		fprintf(stderr,"\ncannot open output file (%s) for the alignment.\n",outfile);
		exit(ERROR_Code_CreateFileFail);
		}
	}


trim_AM(name);
if (strncmp(name,">P1;",4))
	fprintf(out,">P1;");
for (i=0;i<strlen(name);i++)
	if (isprint(name[i])) putc(name[i],out);
putc(EOL,out);

trim_AM(description);
for (i=0;i<strlen(description);i++)
	if (isprint(description[i])) putc(description[i],out);
putc(EOL,out);

index=0;
for (i=0;i<strlen(sequence);i++) {
	if(mask[i]) continue;

	ch=sequence[i];
	if(flag_ChangeJU) {
		if(ch=='j' || ch=='u')
			ch='c';
		else if(ch=='J' || ch=='U')
			ch='C';
		}
	if (isgraph(ch)) {
		putc(ch,out);
		lastchar=ch;
		if ((index+1)%PIR_Width==0) putc(EOL,out);
		}
	index++;
	}
if (lastchar!='*') putc('*',out);
putc(EOL,out);

if(!isstdout)
	fclose(out);

return;
}




/*
 * Print PIR format to file or standerd output for aligned sequences.
 * The sequence length in each line is defined in gen.h as PIR_Width.
 */

void print_PIR_multi(char *outfile, boolean flag_Append, char **name, char **description, char **sequence,
		int SeqNumber, int SeqLength, boolean flag_ChangeJU, boolean flag_RmGapOnlyCol)
{
int	i, j;
char	ch;
boolean	*rm_mask;
boolean flag_remove;


/* Allocate memory for gap-only column mask */

rm_mask=(boolean *)malloc(sizeof(boolean)*SeqLength);
if (rm_mask==NULL) {
	fprintf(stderr,"%s%s: %s\n\n",ERROR_Found,gen_Name,ERROR_MemErr);
	exit(ERROR_Code_MemErr);
	}


/* Check gap-only columns */

if(flag_RmGapOnlyCol) {
	for(i=0;i<SeqLength;i++) {
		flag_remove=TRUE;
		for(j=0;j<SeqNumber;j++) {
			ch=sequence[j][i];
			if(!isgraph(ch)) {
				fprintf(stderr,"%s%s: invalid character (%c) found!\n",ERROR_Found,gen_Name,ch);
				fprintf(stderr,"%s\n%s\n%s\n\n",name[j],description[j],sequence[j]);
				exit(ERROR_Code_General);
				}
			if(ch!='-')
				flag_remove=FALSE;
			}
		rm_mask[i]=flag_remove;
		}
	}
else	{
	for(i=0;i<SeqLength;i++)
		rm_mask[i]=FALSE;
	}


/* Print out */

for(i=0;i<SeqNumber;i++)
	print_PIR_mask(outfile,flag_Append,name[i],description[i],sequence[i],rm_mask,flag_ChangeJU);
	

free(rm_mask);

return;
}




/*
 * Print PIR format to file or standerd output. The sequence length in each line is
 * defined in gen.h as PIR_Width. The first parameter is a file handle.
 */

void print_PIR2(FILE *out, char *name, char *description, char *sequence, boolean flag_ChangeJU)
{
int	i;
char	lastchar=EOS;
char	ch;

trim_AM(name);
if (strncmp(name,">P1;",4))
	fprintf(out,">P1;");
for (i=0;i<strlen(name);i++)
	if (isprint(name[i])) putc(name[i],out);
putc(EOL,out);

trim_AM(description);
for (i=0;i<strlen(description);i++)
	if (isprint(description[i])) putc(description[i],out);
putc(EOL,out);

for (i=0;i<strlen(sequence);i++) {
	ch=sequence[i];
	if(flag_ChangeJU) {
		if(ch=='j' || ch=='u')
			ch='c';
		else if(ch=='J' || ch=='U')
			ch='C';
		}
	if (isgraph(ch)) {
		putc(ch,out);
		lastchar=ch;
		if ((i+1)%PIR_Width==0) putc(EOL,out);
		}
	}
if (lastchar!='*') putc('*',out);
putc(EOL,out);

return;
}




/*
 * Print PIR format to file or standerd output excluding residues masked.
 * The sequence length in each line is defined in gen.h as PIR_Width.
 * The first parameter is a file handle.
 */

void print_PIR_mask2(FILE *out, char *name, char *description, char *sequence, boolean *mask,
		boolean flag_ChangeJU)
{
int	i;
int	index;
char	lastchar=EOS;
char	ch;

trim_AM(name);
if (strncmp(name,">P1;",4))
	fprintf(out,">P1;");
for (i=0;i<strlen(name);i++)
	if (isprint(name[i])) putc(name[i],out);
putc(EOL,out);

trim_AM(description);
for (i=0;i<strlen(description);i++)
	if (isprint(description[i])) putc(description[i],out);
putc(EOL,out);

index=0;
for (i=0;i<strlen(sequence);i++) {
	if(mask[i]) continue;

	ch=sequence[i];
	if(flag_ChangeJU) {
		if(ch=='j' || ch=='u')
			ch='c';
		else if(ch=='J' || ch=='U')
			ch='C';
		}
	if (isgraph(ch)) {
		putc(ch,out);
		lastchar=ch;
		if ((index+1)%PIR_Width==0) putc(EOL,out);
		}
	index++;
	}
if (lastchar!='*') putc('*',out);
putc(EOL,out);

return;
}




/*
 * Print PIR format to file or standerd output for aligned sequences.
 * The sequence length in each line is defined in gen.h as PIR_Width.
 * The first parameter is a file handle.
 */

void print_PIR_multi2(FILE *out, char **name, char **description, char **sequence, int SeqNumber,
		int SeqLength, boolean flag_ChangeJU, boolean flag_RmGapOnlyCol)
{
int	i, j;
char	ch;
boolean	*rm_mask;
boolean flag_remove;


/* Allocate memory for gap-only column mask */

rm_mask=(boolean *)malloc(sizeof(boolean)*SeqLength);
if (rm_mask==NULL) {
	fprintf(stderr,"%s%s: %s\n\n",ERROR_Found,gen_Name,ERROR_MemErr);
	exit(ERROR_Code_MemErr);
	}


/* Check gap-only columns */

if(flag_RmGapOnlyCol) {
	for(i=0;i<SeqLength;i++) {
		flag_remove=TRUE;
		for(j=0;j<SeqNumber;j++) {
			ch=sequence[j][i];
			if(!isgraph(ch)) {
				fprintf(stderr,"%s%s: invalid character (%c) found!\n",ERROR_Found,gen_Name,ch);
				fprintf(stderr,"%s\n%s\n%s\n\n",name[j],description[j],sequence[j]);
				exit(ERROR_Code_General);
				}
			if(ch!='-')
				flag_remove=FALSE;
			}
		rm_mask[i]=flag_remove;
		}
	}
else	{
	for(i=0;i<SeqLength;i++)
		rm_mask[i]=FALSE;
	}


/* Print out */

for(i=0;i<SeqNumber;i++)
	print_PIR_mask2(out,name[i],description[i],sequence[i],rm_mask,flag_ChangeJU);
	

free(rm_mask);

return;
}




/* 
 * Get rid of the redundent characters.
 * For same characters in a given line, only the first one is kept.
 */

void NoRedundentChar_AM(char *line)
{
int i, j, k;
int length;

length=strlen(line);
for(i=0;i<length;i++) {
	for (j=0;j<i;j++) {
		if (line[i]==line[j]) {
			for (k=i+1;k<length;k++) {
				line[k-1]=line[k];
				}
			length--;
			i--;
			break;
			}
		}
	}
line[length]=EOS;

return;
}



/* 
 * Get the filename without the extension from the full path.
 * eg.  /user1/fugue/aat1/aat.tem  -->  aat
 *
 * First scan the input string from right to left,
 * stop when the first '/' or '\' is found. Keep
 * the part of string that has been scaned (excluding
 * '/' or '\'). If neither '/' nor '\' is found, keep
 * the whole string.
 *
 * Then scan the new string from right to left again,
 * stop when the first '.' is found. Get rid of the part
 * that has been scaned, including '.'. If no '.' is found,
 * keep the whole string.
 *
 */

void ShortFilename_AM(char *line)
{
int i, j;
int length;

length=strlen(line);
for (i=length-1;i>=0;i--) {
	if ( line[i]=='/' || line[i]=='\\' ) break;
	}
if (i==length-1) {
	fprintf(stderr,"\nStrange file name. The last character cannot be '/' or '\\'.\n");
	exit(ERROR_Code_BadFileName);
	}
if (i>=0) {
	for (j=i+1;j<length;j++)
		line[j-i-1]=line[j];
	line[j-i-1]=EOS;
	}

length=strlen(line);
for (i=length-1;i>=0;i--) {
	if (line[i]=='.') break;
	}
if (i>=0)
	line[i]=EOS;

return;
}



/* 
 * Get the path and filename without the extension.
 * eg.  /user1/fugue/aat1/aat.tem  -->  /user1/fugue/aat1/aat
 *
 * Scan the new string from right to left again,
 * stop when the first '.' is found. Get rid of the part
 * that has been scaned, including '.'. If no '.' is found,
 * keep the whole string.
 *
 */

void NoExtFilename(char *line)
{
int i;
int length;

length=strlen(line);
for (i=length-1;i>=0;i--) {
	if (line[i]=='.') break;
	}
if (i>=0)
	line[i]=EOS;

return;
}



boolean OverwriteCheck_AM(char *FileName_Output, boolean *flag_OverwriteYes)
{
char	TempStr[TempStr_Length+1];

if((!*flag_OverwriteYes)&&access(FileName_Output,F_OK)==0) { /* file exists, confirm overwriting */
	printf("\nOutput file %s already exists, overwrite (Yes/No/All)? ",FileName_Output);
	fgets(TempStr,TempStr_Length,stdin);
	if (toupper(TempStr[0])=='Y')
		;  /* go through */
	else if (toupper(TempStr[0])=='A')
		(*flag_OverwriteYes)=TRUE;
	else
		return(FALSE);
        }
return(TRUE);
}




/*
 * Transform N x M sequence matrix to M x N.
 */

char **trans_SeqArray(char **sequence, int SeqNumber, int SeqLength)
{
int		i, j;
int		size;
char		**seqtrans;
char		*seq_ptr;

seqtrans=(char **)malloc(sizeof(char *)*SeqLength);
if (seqtrans==NULL) {
	fprintf(stderr,"%s%s: %s\n\n",ERROR_Found,gen_Name,ERROR_MemErr);
	exit(ERROR_Code_MemErr);
	}

size=sizeof(char)*(1+SeqNumber);
for(i=0;i<SeqLength;i++) {
	seqtrans[i]=(char *)malloc(size);
	if(seqtrans[i]==NULL) {
		fprintf(stderr,"%s%s: %s\n\n",ERROR_Found,gen_Name,ERROR_MemErr);
		exit(ERROR_Code_MemErr);
		}
	seq_ptr=seqtrans[i];
	for(j=0;j<SeqNumber;j++)
		seq_ptr[j]=sequence[j][i];
	seq_ptr[j]=EOS;
	}

return(seqtrans);
}



/*
 * Free the memory allocated by calling trans_SeqArray
 */

void free_seqtrans(char **seqtrans, int SeqLength)
{
int		i;

for(i=0;i<SeqLength;i++)
	free(seqtrans[i]);
free(seqtrans);
}



/*
 * Calculate standard deviation
 */

float iStdDev(int *data, int ndata)
{
int		i;
int		sum;
float		average;
float		t;
float		St;
float		Stt;
float		sd;

if(ndata<2) {
	fprintf(stderr,"%s%s: too few data to calculate SD (ndata=%d)\n\n",
		ERROR_Found,gen_Name,ndata);
	exit(ERROR_Code_General);
	}

sum=0;
for(i=0;i<ndata;i++)
	sum+=data[i];
average=(float)sum/(float)ndata;

St=Stt=0.0;
for(i=0;i<ndata;i++) {
	t=(float)data[i]-average;
	St+=t;
	Stt+=(t*t);
	}
sd=sqrt((Stt-St*St/(float)ndata)/(float)(ndata-1));

return(sd);
}
