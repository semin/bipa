/*
 * Check chain break and return a 1D matrix with chain
 * break flags.
 */


/**************START**************/

#include "chnbrk.h"
#include <stdlib.h>
#include <string.h>
#include <math.h>
#ifdef MEMDEBUG
	#include "memdebug.h"
#endif



boolean *chnbrk(PDBREC_AM *MyPdbRec, int VerifyLen, boolean flag_Verbose)
{
register int	i;
int		j;
int		index;
int		len;
int		atomnum;
boolean		*ChainBreak;
float		x1, x2;
float		y1, y2;
float		z1, z2;
float		TempFloat1;
float		TempFloat2;
float		TempFloat3;
float		dist;

PDBRESIDUE_AM      **Array_PdbResidue;
PDBRESIDUE_AM      *current_resptr;
PDBATOM_AM         *PdbAtom;

Array_PdbResidue=MyPdbRec->Residues;
len=MyPdbRec->Num_AllResidue;


/* Allocate memory */

ChainBreak=(boolean *)malloc(sizeof(boolean)*len);
if(ChainBreak==NULL) {
	fprintf(stderr,"\n%s%s: %s\n\n",ERROR_Found,chnbrk_Name,ERROR_MemErr);
	exit(ERROR_Code_MemErr);
	}


/* Check C-alpha - C-alpha distence */
/* If the distance between C-alpha atoms is greater than the cutoff, set
   ChainBreak for the first residue as TRUE. If the first residue is invalid,
   it's not recorded at all. If the C-alpha atom of the first residue is missing
   or invalid, or the second residue has something wrong, ChainBreak for the first
   residue is set to TRUE. Always set ChainBreak as FALSE for the last residue. */

index=-1;
for(i=0;i<len-1;i++) {
	current_resptr=Array_PdbResidue[i];
	if(current_resptr->Num_Atom_Valid<1)
		continue;
	index++;
	ChainBreak[index]=TRUE;
	PdbAtom=current_resptr->AtomPtr;
	atomnum=current_resptr->Num_Atom;
	for(j=0;j<atomnum;j++) {
		if(PdbAtom->isCalpha==TRUE && PdbAtom->isValid==TRUE)
			break;
		else
			PdbAtom=PdbAtom->next_ptr;
		}
	if(j==atomnum)
		continue;
	x1=PdbAtom->x;
	y1=PdbAtom->y;
	z1=PdbAtom->z;

	current_resptr=Array_PdbResidue[i+1];
	if(current_resptr->Num_Atom_Valid<1)
		continue;
	PdbAtom=current_resptr->AtomPtr;
	atomnum=current_resptr->Num_Atom;
	for(j=0;j<atomnum;j++) {
		if(PdbAtom->isCalpha==TRUE && PdbAtom->isValid==TRUE)
			break;
		else
			PdbAtom=PdbAtom->next_ptr;
		}
	if(j==atomnum)
		continue;
	x2=PdbAtom->x;
	y2=PdbAtom->y;
	z2=PdbAtom->z;


	TempFloat1=x1-x2;
	TempFloat1*=TempFloat1;
	TempFloat2=y1-y2;
	TempFloat2*=TempFloat2;
	TempFloat3=z1-z2;
	TempFloat3*=TempFloat3;
	dist=sqrt(TempFloat1+TempFloat2+TempFloat3);

	if(dist<=CHNBRK_CUTOFF)
		ChainBreak[index]=FALSE;
	}
ChainBreak[index+1]=FALSE;

if(VerifyLen!=index+2) {
	fprintf(stderr,"\n%s%s: Verify length for chain break failed. (%d/%d)\n\n",
		ERROR_Found,chnbrk_Name,VerifyLen,index+2);
	exit(ERROR_Code_General);
	}

return(ChainBreak);

}



boolean SetChainBreak_Single(Seqinfo *SeqInfo_Single)
{
int		i;
int		index_NewSeq;
int		index_ChainBreak;
int		length;
int		BreakCount;
char		ch;
char		*sequence;
char		*NewSeq;
boolean		*ChainBreak;

length=SeqInfo_Single->length;
ChainBreak=SeqInfo_Single->ChainBreak;
sequence=SeqInfo_Single->sequence;

BreakCount=0;
for(i=0;i<length;i++) {
	if(ChainBreak[i])
		BreakCount++;
	}
NewSeq=(char *)malloc(sizeof(char)*(BreakCount+length+1));
if(NewSeq==NULL) {
	fprintf(stderr,"\n%s%s: %s\n\n",ERROR_Found,chnbrk_Name,ERROR_MemErr);
	exit(ERROR_Code_MemErr);
	}

index_NewSeq=0;
index_ChainBreak=0;
for(i=0;i<length;i++) {
	ch=sequence[i];
	if(ch=='-')	{	/* is a gap */
		NewSeq[index_NewSeq]=ch;
		index_NewSeq++;
		}
	else	{
		if(ChainBreak[index_ChainBreak]) {	/* is a break */
			NewSeq[index_NewSeq]=ch;
			NewSeq[index_NewSeq+1]=CHAINBREAKER;
			index_ChainBreak++;
			index_NewSeq+=2;
			}
		else	{
			NewSeq[index_NewSeq]=ch;
			index_ChainBreak++;
			index_NewSeq++;
			}
		}
	}
NewSeq[index_NewSeq]=EOS;

free(sequence);
SeqInfo_Single->sequence=NewSeq;
SeqInfo_Single->length=index_NewSeq;

return(SUCCESS);

}




boolean SetChainBreak_Multi(Seqinfo **SeqInfo, int SeqNumber)
{
int		i, j, k;
int		size;
int		seq;
int		index_NewSeq;
int		index_ChainBreak;
int		length;
int		BreakCount;
char		ch;
char		*sequence;
char		*seq_ptr;
char		**NewSeq;
char		*newseq_ptr;
boolean		*ChainBreak;
boolean		**NewBreak;
boolean		*AllBreak;
boolean		*NewBreak_ptr;
Seqinfo		*SeqInfo_ptr;

length=SeqInfo[0]->length;


/* Get information about how many columns we need to insert, and where. */

AllBreak=(boolean *)malloc(sizeof(boolean)*length);
NewBreak=(boolean **)malloc(sizeof(boolean *)*SeqNumber);
if(AllBreak==NULL || NewBreak==NULL) {
	fprintf(stderr,"\n%s%s: %s\n\n",ERROR_Found,chnbrk_Name,ERROR_MemErr);
	exit(ERROR_Code_MemErr);
	}

for(i=0;i<SeqNumber;i++) {
	NewBreak_ptr = NewBreak[i] = (boolean *)malloc(sizeof(boolean)*length);
	if(NewBreak_ptr==NULL) {
		fprintf(stderr,"\n%s%s: %s\n\n",ERROR_Found,chnbrk_Name,ERROR_MemErr);
		exit(ERROR_Code_MemErr);
		}
	ChainBreak=SeqInfo[i]->ChainBreak;
	sequence=SeqInfo[i]->sequence;
	index_ChainBreak=0;
	for(j=0;j<length;j++) {
		ch=sequence[j];
		if(ch=='-') {
			NewBreak_ptr[j]=FALSE;
			continue;	/* note that NewBreak_ptr[j] is set to FALSE */
			}
		NewBreak_ptr[j]=ChainBreak[index_ChainBreak];
		index_ChainBreak++;
		}
	}

BreakCount=0;
for(i=0;i<length;i++) {
	for(j=0;j<SeqNumber;j++) {
		if(NewBreak[j][i])
			break;
		}
	if(j!=SeqNumber) {	/* break found */
		AllBreak[i]=TRUE;
		BreakCount++;
		}
	else
		AllBreak[i]=FALSE;
	}


/* Allocate memory for the new sequences */

NewSeq=(char **)malloc(sizeof(char *)*SeqNumber);
if(NewSeq==NULL) {
	fprintf(stderr,"\n%s%s: %s\n\n",ERROR_Found,chnbrk_Name,ERROR_MemErr);
	exit(ERROR_Code_MemErr);
	}
size=sizeof(char)*(BreakCount+length+1);
for(i=0;i<SeqNumber;i++) {
	NewSeq[i]=(char *)malloc(sizeof(char)*(BreakCount+length+1));
	if(NewSeq[i]==NULL) {
		fprintf(stderr,"\n%s%s: %s\n\n",ERROR_Found,chnbrk_Name,ERROR_MemErr);
		exit(ERROR_Code_MemErr);
		}
	}


/* Create the new sequences */

for(seq=0;seq<SeqNumber;seq++) {
	seq_ptr=SeqInfo[seq]->sequence;
	newseq_ptr=NewSeq[seq];
	ChainBreak=NewBreak[seq];

	index_NewSeq=0;
	for(i=0;i<length;i++) {
		ch=seq_ptr[i];
		if(AllBreak[i]) {	/* is a column containing break */
			if(ChainBreak[i]) {	/* this sequence actually has a break here */
				newseq_ptr[index_NewSeq]=ch;
				newseq_ptr[index_NewSeq+1]=CHAINBREAKER;
				index_NewSeq+=2;
				}
			else	{	/* break not in this sequence at this position */
				newseq_ptr[index_NewSeq]=ch;
				newseq_ptr[index_NewSeq+1]='-';
				index_NewSeq+=2;
				}
			}
		else	{		/* no break in this column */
			newseq_ptr[index_NewSeq]=ch;
			index_NewSeq++;
			}
		}
	newseq_ptr[index_NewSeq]=EOS;
	}


/* re-assign sequences */

for(i=0;i<SeqNumber;i++) {
	SeqInfo_ptr=SeqInfo[i];
	free(SeqInfo_ptr->sequence);
	SeqInfo_ptr->sequence=NewSeq[i];
	SeqInfo_ptr->length=strlen(NewSeq[i]);
	}
length=SeqInfo[0]->length;


/****
   change the following:
	AA-AA
	BB/-B
	CC--C
   to:
	AAAA
	BB/B
	CC-C
****/

for(i=0;i<length-2;i++) {
	if(!AllBreak[i])
		continue;
	for(j=0;j<SeqNumber;j++) {
		if(!NewBreak[j][i])
			continue;
		if(NewSeq[j][i+2]!='-')
			break;
		}
	if(j!=SeqNumber)	/* at least one chain break followed by an AA */
		continue;
	for(j=0;j<SeqNumber;j++) {
		if(NewBreak[j][i])
			NewSeq[j][i+2]=CHAINBREAKER;
		}
	for(j=0;j<SeqNumber;j++) {
		newseq_ptr=NewSeq[j];
		for(k=i;k<length-2;k++)
			newseq_ptr[k+1]=newseq_ptr[k+2];
		newseq_ptr[k+1]=EOS;
		(SeqInfo[j]->length)--;
		}
	length--;
	}
	

/* free memory */
free(AllBreak);
for(i=0;i<SeqNumber;i++)
	free(NewBreak[i]);
free(NewBreak);
free(NewSeq);

return(SUCCESS);

}
