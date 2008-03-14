/*
 * Function:   1. Check the format of the sequence file.
 *             2. Read in the sequences from the file.
 */


/********************START**************************/


#ifndef gen_Name
	#include "gen.h"
#endif



/*
 * Define file name of this function
 */

#define read_seq_Name		"read_seq.c"




/*
 * Define the structure to store sequence information
 */

typedef struct seqinfo Seqinfo;
struct seqinfo {
	char	name[MAX_SeqNameLength];
	char	description[MAX_SeqInfoLength];
	char	*sequence;
	int	length;
	int	length_nogap;
	boolean	*ChainBreak;
	};



/*
 * Define the index code for sequence format
 */

#define SEQFORMAT_FASTA			0
#define SEQFORMAT_PIR			1
#define SEQFORMAT_MSF			2
#define SEQFORMAT_CLUSTAL		3
#define	SEQFORMAT_SLX			4

#define SEQEXT_FASTA			".fa"
#define SEQEXT_PIR			".pir"
#define SEQEXT_MSF			".msf"
#define SEQEXT_CLUSTAL			".aln"
#define SEQEXT_SLX			".slx"

#define AUTOSEQFORMAT			-1


/*
 * Define the entery code for PIR format
 */

#define PIR_ENTERY			">P1;"
#define PIR_ENTERY_LEN			4



/*
 * Prototype definition
 */

Seqinfo **read_seq(int *SeqNumber, boolean *flag_SeqAligned, int *SeqFormat,
		char *FileName_Sequence, boolean flag_Verbose);
void free_seqinfo(Seqinfo **SeqInfo, int SeqNumber);

char **SeqArray(Seqinfo **SeqInfo, int SeqNumber);
void free_SeqArray(char **sequence);

void rm_gaponly_column(Seqinfo **SeqInfo, int SeqNumber, boolean flag_Verbose);
void rm_gaponly_column_single(Seqinfo *SeqInfo, boolean flag_Verbose);
