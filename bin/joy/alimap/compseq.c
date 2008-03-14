/*
 *  Compare sequence with PDB and make consistent
 *  sequence and PDB coordinates.
 */


/**************START**************/

#include "gen.h"
#include "compseq.h"
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <unistd.h>
#include <stdlib.h>
#ifdef MEMDEBUG
	#include "memdebug.h"
#endif



void compare_seq(PDBREC_AM *MyPdbRec, char *sequence, boolean flag_Verbose)
{
register int	i;
int		length;
int		len1, len2;
int		*index1;
char		*seq1, *seq2;
char		**alignment;
char		ch;

PDBRESIDUE_AM      **Array_PdbResidue;
PDBRESIDUE_AM      *current_resptr;
PDBATOM_AM         **Array_PdbAtom;
Aligninfo	*AlignInfo;

Array_PdbAtom=MyPdbRec->Atoms;
Array_PdbResidue=MyPdbRec->Residues;


/* Prepare sequences to be aligned */

length=max(strlen(sequence),MyPdbRec->Num_AllResidue);
seq1=(char *)malloc(sizeof(char)*(length+1));
seq2=(char *)malloc(sizeof(char)*(length+1));
index1=(int *)malloc(sizeof(int)*length);
if(seq1==NULL || seq2==NULL || index1==NULL) {
	fprintf(stderr,"\n%s%s: %s\n\n",ERROR_Found,compseq_Name,ERROR_MemErr);
	exit(ERROR_Code_MemErr);
	}

len1=0;
for(i=0;i<strlen(sequence);i++) {
	ch=toupper(sequence[i]);
	if(ch>='A' && ch<='Z') {
		seq1[len1]=ch;
		index1[len1]=i;
		len1++;
		}
	}
seq1[len1]=EOS;

len2=0;
for(i=0;i<MyPdbRec->Num_AllResidue;i++) {
	current_resptr=Array_PdbResidue[i];
	if(current_resptr->Num_Atom_Valid<1)
		continue;
	seq2[len2]=current_resptr->ShortName;
	len2++;
	}
seq2[len2]=EOS;

/******** done *******/



/* Make the alignment */

AlignInfo=alignseq(seq1,len1,seq2,len2,flag_Verbose);
alignment=AlignInfo->Alignment;

#ifdef DEBUG
	printf("\nOrignal sequences (sequence/PDBseq):\n%s\n%s\n",seq1,seq2);
	printf("\nAligned sequences (sequence/PDBseq):\n%s\n%s\n\n",alignment[0],alignment[1]);
#endif

/******** done *******/




/* Check the alignment. Make sure nothing is wrong */

checkali(alignment,seq1,len1,seq2,len2);

/******** done *******/




/* map the sequence onto PDB according to the alignment
   and mark inconsistancies caused by either the sequence
   or the PDB */

mapit(AlignInfo,MyPdbRec,sequence,index1,flag_Verbose);

#ifdef DEBUG
	printf("Modified sequence:\n%s\n",sequence);
	print_pdb_valid(MyPdbRec, "UNKNOWN");
#endif

/******** done *******/




/* Clean up */

alignclean(AlignInfo,len2);
free(seq1);
free(seq2);
free(index1);

/******** done *******/


return;
}




void checkali(char **alignment, char *seq1, int len1, char *seq2, int len2)
{
int		i, j;
char		*seq_ptr;
char		ch, ch2;


seq_ptr=alignment[0];
j=0;
for(i=0;i<len1;i++) {
	ch=seq1[i];
	if(ch=='-') continue;
	while(seq_ptr[j]!=EOS && seq_ptr[j]=='-') {
		j++;
		}
	if(seq_ptr[j]!=ch) {
		fprintf(stderr,"Something wrong with the alignment. Sequence NOT identical to the original.\n");
		exit(-1);
		}
	j++;
	}
while((ch2=seq_ptr[j])!=EOS) {
	if(ch2!='-') {
		fprintf(stderr,"Something wrong with the alignment. Sequence NOT identical to the original.\n");
		exit(-1);
		}
	j++;
	}

seq_ptr=alignment[1];
j=0;
for(i=0;i<len2;i++) {
	ch=seq2[i];
	if(ch=='-') continue;
	while(seq_ptr[j]!=EOS && seq_ptr[j]=='-') {
		j++;
		}
	if(seq_ptr[j]!=ch) {
		fprintf(stderr,"Something wrong with the alignment. Sequence NOT identical to the original.\n");
		exit(-1);
		}
	j++;
	}
while((ch2=seq_ptr[j])!=EOS) {
	if(ch2!='-') {
		fprintf(stderr,"Something wrong with the alignment. Sequence NOT identical to the original.\n");
		exit(-1);
		}
	j++;
	}

return;
}




Aligninfo *alignseq(char *seq1, int len1, char *seq2, int len2, boolean flag_Verbose)
{
Aligninfo	*AlignInfo;

AlignInfo=init_align(seq1,len1,seq2,len2);
AlignInfo->Score=Global(seq1,len1,seq2,len2,AlignInfo);

return(AlignInfo);
}




void alignclean(Aligninfo *AlignInfo, int len2)
{

free_align(AlignInfo->AlignMatrix,len2);
free_align(AlignInfo->ScoreMatrix,len2);
free_align(AlignInfo->TraceMatrix,len2);
free_trace(AlignInfo->TraceInfo,len2);
free_alignment(AlignInfo->Alignment,2);
free_gap(AlignInfo->GapDel);
free(AlignInfo);
}




Aligninfo *init_align(char *seq1, int len1, char *seq2, int len2)
{
Aligninfo	*AlignInfo;
int		i, j;
int		**ScoreMatrix;
int		*Score_ptr;


AlignInfo=(Aligninfo *)malloc(sizeof(Aligninfo));
if (AlignInfo==NULL) {
	fprintf(stderr,"%s%s: %s\n\n",ERROR_Found,compseq_Name,ERROR_MemErr);
	exit(ERROR_Code_MemErr);
	}
AlignInfo->AlignMatrix=malloc_align(len2,len1);
AlignInfo->ScoreMatrix=malloc_align(len2,len1);
AlignInfo->TraceMatrix=malloc_align(len2,len1);
AlignInfo->TraceInfo=malloc_trace(len2,len1);
AlignInfo->Alignment=malloc_alignment(2,len2+len1);
AlignInfo->GapDel=malloc_gap(len1);


ScoreMatrix=AlignInfo->ScoreMatrix;
for(i=0;i<=len2;i++)
	ScoreMatrix[i][0]=0;
Score_ptr=ScoreMatrix[0];
for(j=1;j<=len1;j++)
	Score_ptr[j]=0;
for(i=1;i<=len2;i++) {
	Score_ptr=ScoreMatrix[i];
	for(j=1;j<=len1;j++) {
		if(seq2[i-1]==seq1[j-1])
			Score_ptr[j]=SCORE_MATCH;
		else
			Score_ptr[j]=SCORE_MISMATCH;
		}
	}

return(AlignInfo);
}



/**********************************
 Allocate memory for scoring matrix
 (PrfLength * SeqLength). 
 **********************************/

int **malloc_align(int PrfLength, int SeqLength)
{
register int    i;
int             size;
int             **AlignMatrix;

AlignMatrix=(int **)malloc(sizeof(int *)*(PrfLength+1));
if (AlignMatrix==NULL) {
        fprintf(stderr,"%s%s: %s\n\n",ERROR_Found,compseq_Name,ERROR_MemErr);
        exit(ERROR_Code_MemErr);
        }

size=sizeof(int)*(SeqLength+1);
for (i=0;i<PrfLength+1;i++) {
        AlignMatrix[i]=(int *)malloc(size);
        if (AlignMatrix[i]==NULL) {
                fprintf(stderr,"%s%s: %s\n\n",ERROR_Found,compseq_Name,ERROR_MemErr);
                exit(ERROR_Code_MemErr);
                }
        }

return(AlignMatrix);
}



/*************************************
 Free memory allocated by malloc_align
 *************************************/

void free_align(int **AlignMatrix, int PrfLength)
{
int i;

for (i=0;i<PrfLength+1;i++)
        free(AlignMatrix[i]);

free(AlignMatrix);

return;
}




/*************************************
 Allocate memory for trace-back matrix
 (PrfLength * SeqLength). 
 *************************************/

Traceinfo **malloc_trace(int PrfLength, int SeqLength)
{
register int    i;
int             size;
Traceinfo       **TraceInfo;

TraceInfo=(Traceinfo **)malloc(sizeof(Traceinfo *)*(PrfLength+1));
if (TraceInfo==NULL) {
        fprintf(stderr,"%s%s: %s\n\n",ERROR_Found,compseq_Name,ERROR_MemErr);
        exit(ERROR_Code_MemErr);
        }

size=sizeof(Traceinfo)*(SeqLength+1);
for (i=0;i<PrfLength+1;i++) {
        TraceInfo[i]=(Traceinfo *)malloc(size);
        if (TraceInfo[i]==NULL) {
                fprintf(stderr,"%s%s: %s\n\n",ERROR_Found,compseq_Name,ERROR_MemErr);
                exit(ERROR_Code_MemErr);
                }
        }

return(TraceInfo);
}




/*************************************
 Free memory allocated by malloc_trace
 *************************************/

void free_trace(Traceinfo **TraceInfo, int PrfLength)
{
int i;

for (i=0;i<PrfLength+1;i++)
        free(TraceInfo[i]);

free(TraceInfo);


return;
}




/********************************************************
 Allocate memory for a one-dimension array (used as P or
 Q matrix described by Gotoh), which stores the temporary
 value for gap penalties.
 (array length defined by 'Length') 
 ********************************************************/

int *malloc_gap(int Length)
{
int *MyGap;

MyGap=(int *)malloc(sizeof(int)*(Length+1));
if (MyGap==NULL) {
        fprintf(stderr,"%s%s: %s\n\n",ERROR_Found,compseq_Name,ERROR_MemErr);
        exit(ERROR_Code_MemErr);
        }

return(MyGap);
}



/***********************************
 Free memory allocated by malloc_gap
 ***********************************/

void free_gap(int *MyGap)
{
free(MyGap);

return;
}





/****************************************
 Allocate memory for the alignment
 (Sequence Number * MAX Alignment Length) 
 ****************************************/

char **malloc_alignment(int AliNumber, int AliLength)
{
register int    i;
int             size;
char            **Alignment;

Alignment=(char **)malloc(sizeof(char *)*(AliNumber));
if (Alignment==NULL) {
        fprintf(stderr,"%s%s: %s\n\n",ERROR_Found,compseq_Name,ERROR_MemErr);
        exit(ERROR_Code_MemErr);
        }

size=sizeof(char)*(AliLength+1);
for (i=0;i<AliNumber;i++) {
        Alignment[i]=(char *)malloc(size);
        if (Alignment[i]==NULL) {
                fprintf(stderr,"%s%s: %s\n\n",ERROR_Found,compseq_Name,ERROR_MemErr);
                exit(ERROR_Code_MemErr);
                }
        }

return(Alignment);
}




/*****************************************
 Free memory allocated by malloc_alignment
 *****************************************/

void free_alignment(char **Alignment, int AliNumber)
{
int i;

for (i=0;i<AliNumber;i++)
        free(Alignment[i]);

free(Alignment);


return;
}




/*******************************
    Local -- Smith & Waterman
 *******************************/

int Local(char *seq1, int len1, char *seq2, int len2, Aligninfo *AlignInfo)
{
int		i, j, k;
int		TempInt;

int             MaxScore=-9999; /* maximum score in the alignment matrix */
int             MaxI=0;         /* location of MaxScore */
int             MaxJ=0;         /* location of MaxScore */
int		TraceI;
int		TraceJ;

int             **AlignMatrix;  /* matrix for the alignment */
int             **ScoreMatrix;
int		*Align_this_ptr;
int		*Align_last_ptr;
int		*Score_ptr;
int		*GapDel_ptr;
int		matchscore;

Traceinfo       **TraceInfo;    /* matrix for trace-back */
Traceinfo       *trace_ptr;

int             *GapDel;        /* temporary values of penalties for gaps in sequence */
int             GapIns;         /* temporary values of penalties for gaps in profile */

AlignMatrix=AlignInfo->AlignMatrix;
ScoreMatrix=AlignInfo->ScoreMatrix;
TraceInfo=AlignInfo->TraceInfo;

GapDel=AlignInfo->GapDel;


/* Initialize matrices */

for(i=0;i<=len2;i++) {
        AlignMatrix[i][0]=0;
	trace_ptr=TraceInfo[i];
	for(j=0;j<=len1;j++)
		trace_ptr[j].dir=-2;    /* Terminal */
        }

Align_this_ptr=AlignMatrix[0];
for(j=1;j<=len1;j++) {
        GapDel[j]=0;
        Align_this_ptr[j]=0;
        }

/* Dynamic programming forward process */

for(i=1;i<=len2;i++) {
        Align_last_ptr=AlignMatrix[i-1];
        Align_this_ptr=AlignMatrix[i];
        Score_ptr=ScoreMatrix[i];
	GapIns=0;

	for(j=1;j<=len1;j++) {
		GapDel_ptr=GapDel+j;

		*GapDel_ptr=max(Align_last_ptr[j],*GapDel_ptr);
		GapIns=max(Align_this_ptr[j-1],GapIns);

		TempInt=max(GapIns,*GapDel_ptr);
                matchscore=Align_last_ptr[j-1]+Score_ptr[j];
                TempInt=max(matchscore,TempInt);
                TempInt=max(TempInt,0);
                Align_this_ptr[j]=TempInt;

                if(TempInt!=0) {
                        /* locate maximum score */
                        if(MaxScore<TempInt) {
                                MaxScore=TempInt;
                                MaxI=i;
                                MaxJ=j;
                                }

			if (TempInt==GapIns)
				TraceInfo[i][j].dir=1;  /* gap in profile */
			else if (TempInt==*GapDel_ptr)
				TraceInfo[i][j].dir=-1;  /* gap in sequence */
			else if (TempInt==matchscore) /* match */
				TraceInfo[i][j].dir=0;
			else    {
				fprintf(stderr,"%s%s: something wrong in calculating score at alignment position (%d,%d) (NOT found)\n\n",
					ERROR_Found,compseq_Name,i,j);
				exit(ERROR_Code_General);
				}
			}
		}
	}


/* Find trace-back path */

TraceI=MaxI;
TraceJ=MaxJ;

while(MaxI>0 && MaxJ>0 && (matchscore=AlignMatrix[MaxI][MaxJ])>0) {
	switch (TraceInfo[MaxI][MaxJ].dir) {
		case 0:         /* no gap */
			TraceInfo[MaxI][MaxJ].len=1;
			MaxI--;
			MaxJ--;
			break;
		case 1:         /* gap in profile */
			for(k=0;k<MaxJ;k++) {
				if (matchscore==AlignMatrix[MaxI][k])
					break;
				}
			if(k==MaxJ) {
				fprintf(stderr,"%s%s: something wrong in calculating score at alignment position (%d,%d) (left)\n\n",
					ERROR_Found,compseq_Name,i,j);
				exit(ERROR_Code_General);
				}
			TraceInfo[MaxI][MaxJ].len=MaxJ-k;
			MaxJ=k;
			break;
		case -1:        /* gap in sequence */
			for(k=0;k<MaxI;k++) {
				if (matchscore==AlignMatrix[k][MaxJ])
					break;
				}
			if(k==MaxI) {
				fprintf(stderr,"%s%s: something wrong in calculating score at alignment position (%d,%d) (up)\n\n",
					ERROR_Found,compseq_Name,i,j);
				exit(ERROR_Code_General);
				}
			TraceInfo[MaxI][MaxJ].len=MaxI-k;
			MaxI=k;
			break;
		}
	}

traceback(TraceI,TraceJ,AlignInfo,seq1,len1,seq2,len2);

return(MaxScore);
}



void traceback(int TraceI, int TraceJ, Aligninfo *AlignInfo, char *seq1, int len1, char *seq2, int len2)
{
char            **Alignment;
char		*Ali_Prf;
char		*Ali_Seq;
char		*seq_ptr;
Traceinfo       **TraceInfo;
int             AlignIndex;
int             TempInt;
int		AlignedLen1;
int		AlignedLen2;
int		Len12;
int             i=0;
int		j=0;
int		dir;
int		gap;

Alignment=AlignInfo->Alignment;
Ali_Prf=Alignment[1];
Ali_Seq=Alignment[0];
TraceInfo=AlignInfo->TraceInfo;

AlignedLen1=0;
AlignedLen2=0;
Len12=len1+len2;
AlignIndex=Len12-1;
gap=0;

while((dir=TraceInfo[TraceI][TraceJ].dir)>-2) {
        switch (dir) {
                case 0:      /* no gap */
                        TraceI--;
                        TraceJ--;
			Ali_Prf[AlignIndex]=seq2[TraceI];
			Ali_Seq[AlignIndex]=seq1[TraceJ];
			AlignIndex--;
			AlignedLen1++;
			AlignedLen2++;
			break;
		case 1:      /* gap in profile */
			TempInt=TraceInfo[TraceI][TraceJ].len;
			for(j=0;j<TempInt;j++) {
				TraceJ--;
				Ali_Prf[AlignIndex]='-';
				Ali_Seq[AlignIndex]=seq1[TraceJ];
				AlignIndex--;
				}
			gap+=TempInt;
			AlignedLen1+=TempInt;
			break;
		case -1:     /* gap in sequence */
			TempInt=TraceInfo[TraceI][TraceJ].len;
			for(j=0;j<TempInt;j++) {
				TraceI--;
				Ali_Prf[AlignIndex]=seq2[TraceI];
				Ali_Seq[AlignIndex]='-';
				AlignIndex--;
				}
			gap+=TempInt;
			AlignedLen2+=TempInt;
			break;
		default:     /* something is wrong */
			fprintf(stderr,"%s%s: TraceInfo[%d][%d]=%d, but the value should be either -1, 0 or 1\n\n",
				 ERROR_Found,compseq_Name,i,j,TraceInfo[i][j].dir);
			exit(ERROR_Code_General);
		}
	}
for(j=0;j<2;j++) {
	seq_ptr=Alignment[j];
	for(i=AlignIndex+1;i<Len12;i++)
		seq_ptr[i-AlignIndex-1]=seq_ptr[i];
	seq_ptr[i-AlignIndex-1]=EOS;
	}

AlignInfo->Length=Len12-AlignIndex-1;
AlignInfo->AlignedLength=AlignInfo->Length-gap;
AlignInfo->AlignedLen2=AlignedLen2;
AlignInfo->AlignedLen1=AlignedLen1;

return;
}




/*******************************
    Global
 *******************************/

int Global(char *seq1, int len1, char *seq2, int len2, Aligninfo *AlignInfo)
{
int		i, j, k;
int		TempInt;

int             MaxScore=-9999; /* maximum score in the alignment matrix */
int             MaxI;           /* location of MaxScore */
int             MaxJ;           /* location of MaxScore */
int		TraceI;
int		TraceJ;

int             **AlignMatrix;  /* matrix for the alignment */
int             **ScoreMatrix;
int		*Align_this_ptr;
int		*Align_last_ptr;
int		*Score_ptr;
int		*GapDel_ptr;
int		matchscore;

Traceinfo       **TraceInfo;    /* matrix for trace-back */
Traceinfo       *trace_ptr;

int             *GapDel;        /* temporary values of penalties for gaps in sequence */
int             GapIns;         /* temporary values of penalties for gaps in profile */

AlignMatrix=AlignInfo->AlignMatrix;
ScoreMatrix=AlignInfo->ScoreMatrix;
TraceInfo=AlignInfo->TraceInfo;

GapDel=AlignInfo->GapDel;


/* Initialize matrices */

AlignMatrix[0][0]=0;

AlignMatrix[1][0]=TempInt=0-GAP_OPEN;
for(i=2;i<=len2;i++) {
	TempInt-=GAP_EXT;
        AlignMatrix[i][0]=TempInt;
        }

Align_this_ptr=AlignMatrix[0];
Align_this_ptr[1]=TempInt=0-GAP_OPEN;
GapDel[1]=TempInt-GAP_OPEN;
for(j=2;j<=len1;j++) {
	TempInt-=GAP_EXT;
        GapDel[j]=TempInt-GAP_OPEN;
        Align_this_ptr[j]=TempInt;
        }

TraceInfo[0][0].dir=-2; /* Terminal */
for(i=1;i<=len2;i++) {
	TraceInfo[i][0].dir=-1;
	TraceInfo[i][0].len=i;
	}
trace_ptr=TraceInfo[0];
for(j=1;j<=len1;j++) {
	trace_ptr[j].dir=1;
	trace_ptr[j].len=j;
	}

/* Dynamic programming forward process */

for(i=1;i<=len2;i++) {
        Align_last_ptr=AlignMatrix[i-1];
        Align_this_ptr=AlignMatrix[i];
        Score_ptr=ScoreMatrix[i];
	GapIns=Align_this_ptr[0]-GAP_OPEN;

	for(j=1;j<=len1;j++) {
		GapDel_ptr=GapDel+j;

		*GapDel_ptr=max(Align_last_ptr[j]-GAP_OPEN,*GapDel_ptr-GAP_EXT);
		GapIns=max(Align_this_ptr[j-1]-GAP_OPEN,GapIns-GAP_EXT);

		TempInt=max(GapIns,*GapDel_ptr);
                matchscore=Align_last_ptr[j-1]+Score_ptr[j];
                TempInt=max(matchscore,TempInt);
                TempInt=max(TempInt,0);
                Align_this_ptr[j]=TempInt;

                if(TempInt!=0) {
			if (TempInt==matchscore && (i<len2/2 || j<len1/2)) /* match at N-terminal preferred */
				TraceInfo[i][j].dir=0;
			else if (TempInt==GapIns)
				TraceInfo[i][j].dir=1;  /* gap in profile */
			else if (TempInt==*GapDel_ptr)
				TraceInfo[i][j].dir=-1;  /* gap in sequence */
			else if (TempInt==matchscore) /* match at C-terminal NOT preferred */
				TraceInfo[i][j].dir=0;
			else    {
				fprintf(stderr,"%s%s: something wrong in calculating score at alignment position (%d,%d) (NOT found)\n\n",
					ERROR_Found,compseq_Name,i,j);
				exit(ERROR_Code_General);
				}
			}
		}
	}

MaxScore=AlignMatrix[len2][len1];


/* Find trace-back path */

TraceI=MaxI=len2;
TraceJ=MaxJ=len1;

while(MaxI>0 && MaxJ>0) {
	matchscore=AlignMatrix[MaxI][MaxJ];

	switch (TraceInfo[MaxI][MaxJ].dir) {
		case 0:         /* no gap */
			TraceInfo[MaxI][MaxJ].len=1;
			MaxI--;
			MaxJ--;
			break;
		case 1:         /* gap in profile */
			for(k=0;k<MaxJ;k++) {
				if (matchscore==AlignMatrix[MaxI][k]-GAP_OPEN-(MaxJ-k-1)*GAP_EXT)
					break;
				}
			if(k==MaxJ) {
				fprintf(stderr,"%s%s: something wrong in calculating score at alignment position (%d,%d) (left)\n\n",
					ERROR_Found,compseq_Name,i,j);
				exit(ERROR_Code_General);
				}
			TraceInfo[MaxI][MaxJ].len=MaxJ-k;
			MaxJ=k;
			break;
		case -1:        /* gap in sequence */
			for(k=0;k<MaxI;k++) {
				if (matchscore==AlignMatrix[k][MaxJ]-GAP_OPEN-(MaxI-k-1)*GAP_EXT)
					break;
				}
			if(k==MaxI) {
				fprintf(stderr,"%s%s: something wrong in calculating score at alignment position (%d,%d) (up)\n\n",
					ERROR_Found,compseq_Name,i,j);
				exit(ERROR_Code_General);
				}
			TraceInfo[MaxI][MaxJ].len=MaxI-k;
			MaxI=k;
			break;
		}
	}

traceback(TraceI,TraceJ,AlignInfo,seq1,len1,seq2,len2);

return(MaxScore);
}



void mapit(Aligninfo *AlignInfo, PDBREC_AM *MyPdbRec, char *sequence, int *index1, boolean flag_Verbose)
{
int		i, j;
int		length;
int		Idx_Seq;
int		Idx_Pro;
char		**alignment;
char		*Ali_Pro;
char		*Ali_Seq;

PDBRESIDUE_AM	**Array_PdbResidue;
PDBATOM_AM		**Array_PdbAtom;

PDBRESIDUE_AM      *current_ptr_res; 


alignment=AlignInfo->Alignment;
Ali_Seq=alignment[0];
Ali_Pro=alignment[1];

Array_PdbResidue=MyPdbRec->Residues;
Array_PdbAtom=MyPdbRec->Atoms;

length=strlen(Ali_Seq);
Idx_Seq=0;
Idx_Pro=0;
for(i=0;i<length;i++) {
	/* if two residues in the same column do NOT match, mask both pdb and seq */
	if(Ali_Seq[i]!=Ali_Pro[i] && Ali_Pro[i]!='-' && Ali_Seq[i]!='-') {
		current_ptr_res=Array_PdbResidue[Idx_Pro];
		current_ptr_res->Num_Atom_Valid=0;
		for(j=current_ptr_res->Index_Atom;j<current_ptr_res->Index_Atom+current_ptr_res->Num_Atom;j++) {
			Array_PdbAtom[j]->isValid=FALSE;
			}
		sequence[index1[Idx_Seq]]='-';
		if(flag_Verbose) {
			printf("Warning: Non-identical residues (%s %c%s in PDB and %c at position %4d in SEQUENCE) are removed.\n",
				current_ptr_res->ResName,current_ptr_res->Chain,current_ptr_res->ResNo,
				sequence[index1[Idx_Seq]],index1[Idx_Seq]+1);
			}
		}
	/* if pdb has extra residues, mask them */
	else if(Ali_Seq[i]=='-' && Ali_Pro[i]!='-') {
		current_ptr_res=Array_PdbResidue[Idx_Pro];
		current_ptr_res->Num_Atom_Valid=0;
		for(j=current_ptr_res->Index_Atom;j<current_ptr_res->Index_Atom+current_ptr_res->Num_Atom;j++) {
			Array_PdbAtom[j]->isValid=FALSE;
			}
		if(flag_Verbose) {
			printf("Warning: residue %s %c%s in the PDB is removed for consistency with SEQUENCE.\n",
				current_ptr_res->ResName,current_ptr_res->Chain,current_ptr_res->ResNo);
			}
		}
	/* if seq has extra residues, change them to gap symbol */
	else if(Ali_Pro[i]=='-' && Ali_Seq[i]!='-') {
		if(flag_Verbose) {
			printf("Warning: residue %c at position %4d in the SEQUENCE is removed for consistency with PDB.\n",
				sequence[index1[Idx_Seq]],index1[Idx_Seq]+1);
			}
		sequence[index1[Idx_Seq]]='-';
		}
	if(Ali_Pro[i]!='-')
		Idx_Pro++;
	if(Ali_Seq[i]!='-')
		Idx_Seq++;
	}

return;
}
