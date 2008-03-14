/*
 * General purpose head file (for functions)
 */

/************START*************/

#include <stdio.h>


#define GEN_FUNCTION



/* prototype: trim the space and non-printable character at both ends of the input string */

void trim_AM(char *line);


/* prototype: trim the space and non-alnum (excluding '(' and ')') character at both ends of the input string */

void trimalnum(char *line);


/* prototype: Print FASTA format. The sequence length in each line is defined in gen.h as PIR_Width */

void print_FASTA(char *outfile, boolean flag_Append, char *name, char *description, char *sequence,
		boolean flag_ChangeJU);


/* prototype: Print PIR format. The sequence length in each line is defined in gen.h as PIR_Width */

void print_PIR(char *outfile, boolean flag_Append, char *name, char *description, char *sequence,
		boolean flag_ChangeJU);

void print_PIR2(FILE *out, char *name, char *description, char *sequence, boolean flag_ChangeJU);


/* prototype: Print PIR format excluding the marked residues. */

void print_PIR_mask(char *outfile, boolean flag_Append, char *name, char *description, char *sequence,
	boolean *mask, boolean flag_ChangeJU);

void print_PIR_mask2(FILE *out, char *name, char *description, char *sequence, boolean *mask,
	boolean flag_ChangeJU);


/* prototype: Print PIR format for aligned sequences */

void print_PIR_multi(char *outfile, boolean flag_Append, char **name, char **description, char **sequence,
	int SeqNumber, int SeqLength, boolean flag_ChangeJU, boolean flag_RmGapOnlyCol);

void print_PIR_multi2(FILE *out, char **name, char **description, char **sequence, int SeqNumber,
	int SeqLength, boolean flag_ChangeJU, boolean flag_RmGapOnlyCol);


/* prototype: Get rid of the redundent characters. For same characters in a given line,
              only the first one is kept. */

void NoRedundentChar_AM(char *line);


/* prototype: Get the filename without the extension from the full path.
   eg.  /user1/fugue/aat1/aat.tem  -->  aat   */

void ShortFilename_AM(char *line);


/* prototype: Get the path and filename without the extension
   eg.  /user1/fugue/aat1/aat.tem  -->  /user1/fugue/aat1/aat */

void NoExtFilename(char *line);


/* prototype: Overwrite check. */

boolean OverwriteCheck_AM(char *FileName_Output, boolean *flag_OverwriteYes);


/* prototype: Transform N x M sequence matrix to M x N. */

char **trans_SeqArray(char **sequence, int SeqNumber, int SeqLength);

/* prototype: Free the memory allocated by calling trans_SeqArray. */

void free_seqtrans(char **seqtrans, int SeqLength);


/* prototype: Calculate standard deviation */

float iStdDev(int *data, int ndata);
