/*
 * ALIMAP Head file
 *
 */


/**************START**************/

#define alimap_Name "alimap.c"
#define ALIMAP

#include "api_AM.h"


#ifndef read_pdb_Name
	#include "read_pdb.h"
#endif

#ifndef read_seq_Name
	#include "read_seq.h"
#endif


/*
 * define default file extension name for the output
 */

#define OUTPUT_EXT	".atm"
#define NEWALI_EXT	"_new.ali"
#define ALI_EXT		".ali"



/*
 * define default options
 */

#define DEFAULT_DELANISOU		FALSE
#define DEFAULT_DELALTPOS		TRUE
#define DEFAULT_DELHATOM		TRUE
#define DEFAULT_DELMISSMCA		FALSE
#define DEFAULT_VERBOSE			FALSE
#define DEFAULT_OVERWRITEYES		FALSE
#define	DEFAULT_PRINTSCREEN		FALSE
#define DEFAULT_CHAINID			'*'
#define DEFAULT_PATH			"/pubdata/pdb/allpdb/pdb#.ent"
#define DEFAULT_ALLCHAIN		FALSE
#define DEFAULT_MAP			TRUE
#define DEFAULT_KEEPDESC		FALSE
#define	DEFAULT_OUTPUTFASTA		FALSE
#define	DEFAULT_CHAINBREAK		FALSE
#define	DEFAULT_CONVERTPCA		TRUE
#define DEFAULT_CHECKPDB		TRUE
#define	DEFAULT_PDBCODE			FALSE
#define	DEFAULT_PDBFILE			FALSE
#define	DEFAULT_PDBSINGLE		FALSE
#define	DEFAULT_SAVEALI			TRUE
#define	DEFAULT_SAVEATM			TRUE



/*
 * define version
 */

#define ALIMAP_VER "0.71 (JUNE 2000)"



/*
 * Prototype: parameter init
 */

#ifndef ALIMAP_EXTERNAL
	void init_alimap(Alimapoption *AliMapOption);
#endif

boolean	alimap(Alimapoption *AliMapOption, Seqinfo *SeqInfo);
boolean write_atm(PDBREC_AM *MyPdbRec, FILE *in_file, char *FileName_save_atm,
		boolean flag_PrintScreen, boolean flag_Verbose);
boolean ModSeqInfo(PDBREC_AM *MyPdbRec, Seqinfo *SeqInfo, boolean flag_KeepDesc);
