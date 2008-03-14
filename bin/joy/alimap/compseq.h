/*
 *  Compare sequence with PDB and make consistent
 *  sequence and PDB coordinates.
 *
 */

/**************START**************/


#ifndef read_pdb_Name
	#include "read_pdb.h"
#endif


#define compseq_Name "compseq.c"
#define COMPSEQ


/*
 * Define matching score
 */

#define		SCORE_MISMATCH		-100
#define		SCORE_MATCH		100
#define		GAP_OPEN		1
#define		GAP_EXT			0


/*
 * Define the structure for alignment information
 */

typedef struct traceinfo Traceinfo;
struct traceinfo {
        int     dir;                    /* direction */
        int     len;                    /* length */
        };

typedef struct aligninfo Aligninfo;
struct aligninfo {
        char    **Alignment;            /* store the alignment */
        int     Score;                  /* raw score for the alignment */
        int     Length;                 /* length of the alignment */
        int     AlignedLength;          /* length of the aligned residue pairs */
        int     AlignedLen1;            /* length of the aligned part of sequence excluding gaps */
        int     AlignedLen2;            /* length of the aligned part of profile  excluding gaps */
        int     **AlignMatrix;          /* matrix for the alignment */
        int     **ScoreMatrix;          /* comarison score for each position */
        int     **TraceMatrix;          /* matrix for trace-back */
        Traceinfo **TraceInfo;          /* matrix for trace-back */
        int     *GapDel;                /* temporary values of penalties for gaps in sequence */
        };



/*
 * Prototype: parameter init
 */

void compare_seq(PDBREC_AM *MyPdbRec, char *sequence, boolean flag_Verbose);
Aligninfo *init_align(char *seq1, int len1, char *seq2, int len2);
int **malloc_align(int PrfLength, int SeqLength);
void free_align(int **AlignMatrix, int PrfLength);
Traceinfo **malloc_trace(int PrfLength, int SeqLength);
void free_trace(Traceinfo **TraceInfo, int PrfLength);
int *malloc_gap(int Length);
void free_gap(int *MyGap);
char **malloc_alignment(int AliNumber, int AliLength);
void free_alignment(char **Alignment, int AliNumber);
int Global(char *seq1, int len1, char *seq2, int len2, Aligninfo *AlignInfo);
int Local(char *seq1, int len1, char *seq2, int len2, Aligninfo *AlignInfo);
void traceback(int TraceI, int TraceJ, Aligninfo *AlignInfo, char *seq1, int len1, char *seq2, int len2);
void alignclean(Aligninfo *AlignInfo, int len2);
Aligninfo *alignseq(char *seq1, int len1, char *seq2, int len2, boolean flag_Verbose);
void checkali(char **alignment, char *seq1, int len1, char *seq2, int len2);
void mapit(Aligninfo *AlignInfo, PDBREC_AM *MyPdbRec, char *sequence, int *index1, boolean flag_Verbose);
