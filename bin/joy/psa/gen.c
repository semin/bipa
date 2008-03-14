#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <unistd.h>
#include "gen.h"


/*
 * Get rid of the non-printable characters and space at both ends
 * of the input string.
 */

void trim(char *line)
{
int i, j, length;

/* trim right */
length=strlen(line);
for (i=length-1;i>=0;i--)
	if (isgraph(line[i])) break;
line[i+1]='\0';

/* trim left */
length=i+1;
for (i=0;i<length;i++)
	if (isgraph(line[i])) break;
for (j=i;j<=length;j++)
	line[j-i]=line[j];

return;
}




/* 
 * Get rid of the redundent characters.
 * For same characters in a given line, only the first one is kept.
 */

void NoRedundentChar(char *line)
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
line[length]='\0';

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

void ShortFilename(char *line)
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
	line[j-i-1]='\0';
	}

length=strlen(line);
for (i=length-1;i>=0;i--) {
	if (line[i]=='.') break;
	}
if (i>=0)
	line[i]='\0';

return;
}

boolean OverwriteCheck(char *FileName_Output, boolean *flag_OverwriteYes)
{
char	TempStr[TempStr_Length];

if((!*flag_OverwriteYes)&&access(FileName_Output,F_OK)==0) { // file exists, confirm overwriting
	printf("\nOutput file %s already exists, overwrite (Yes/No/All)? ",FileName_Output);
	fgets(TempStr,TempStr_Length,stdin);
	if (toupper(TempStr[0])=='Y')
		;  // go through
	else if (toupper(TempStr[0])=='A')
		(*flag_OverwriteYes)=TRUE;
	else
		return(FALSE);
	}
return(TRUE);
}
		
