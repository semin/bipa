/*
 * Check chain breaks.
 *
 */

/**************START**************/


#define chnbrk_Name "chnbrk.c"
#define CHNBRK


#ifndef GEN
	#include "gen.h"
#endif

#ifndef read_pdb_Name
	#include "read_pdb.h"
#endif

#ifndef read_seq_Name
	#include "read_seq.h"
#endif


/*
 * Define threshold for chain break
 */

#define		CHNBRK_CUTOFF		4.2


/*
 * Define chain break symbol
 */

#define		CHAINBREAKER		'/'


/*
 * Prototype: parameter init
 */

boolean *chnbrk(PDBREC_AM *MyPdbRec, int VerifyLen, boolean flag_Verbose);
boolean SetChainBreak_Single(Seqinfo *SeqInfo_Single);
boolean SetChainBreak_Multi(Seqinfo **SeqInfo, int SeqNumber);
