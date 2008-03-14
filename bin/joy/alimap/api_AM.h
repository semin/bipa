/*
 * ALIMAP Head file -- API
 *
 */


/**************START**************/

#define ALIMAP_EXTERNAL

#ifndef GEN
	#include "gen.h"
#endif



/*
 * define structure for AliMap command-line options
 */

typedef struct alimapoption Alimapoption;
struct alimapoption {

	/* input file to be processed (or PDB code) */
	char		*FileName_input;				/* required */

	/* path for PDB files */
	char		*path;

	/* PDB file to be processed */
	char		*FileName_read_pdb;

	/* Output PDB file name */
	char		*FileName_save_atm;

	/* Output new alignment file name */
	char		*FileName_save_ali;

	/* Input is PDB code query rather than sequence file query */
	boolean		flag_PDBCode;

	/* Input is PDB file query rather than sequence file query */
	boolean		flag_PDBFile;

	/* Input is a single entry: either flag_PDBCode or flag_PDBFile is TRUE */
	boolean		flag_PDBSingle;

	/* Save output PDB file ? */
	boolean		flag_SaveAtm;

	/* Save output alignment file ? */
	boolean		flag_SaveAli;

	/* Which model to process when there are multiple model in PDB (starting from 1) */
	int		getmodel;

	/* Which chain to process -- '*' means all chains */
	char		chainID;

	/* Verbose mode */
	boolean		flag_Verbose;

	/* Output to stdout ? */
	boolean		flag_PrintScreen;

	/* Permit overwriting files? */
	boolean		flag_OverwriteYes;

	/* Enable PDB filter ? (If set to false, will disable flag_DelANISOU,
	   flag_DelAltPos, flag_DelHAtom, flag_DelMissMCA, and coordinates
	   range check */
	boolean		flag_CheckPDB;

	/* Delete ANISOU entry ? */
	boolean		flag_DelANISOU;

	/* Delete Alternate position ? */
	boolean		flag_DelAltPos;

	/* Delete hydrogen ? */
	boolean		flag_DelHAtom;

	/* Delete residues with incomplete mainchain coordinates ? */
	boolean		flag_DelMissMCA;

	/* Keep all chains in PDB (will force flag_Map to be FALSE) */
	boolean		flag_AllChain;

	/* Map sequence to PDB and get rid of inconsistant records/AAs */
	boolean		flag_Map;

	/* Keep the original description (do not modify according to PDB file) */
	boolean		flag_KeepDesc;

	/* Output sequence in FASTA format (only valid with flag_PDBCode or flag_PDBFile) */
	boolean		flag_OutputFASTA;

	/* Set chain break symbol in the output sequence */
	boolean		flag_ChainBreak;

	/* Convert PCA ACE FOR from ATOM to HETATM */
	boolean		flag_ConvertPCA;
	};



/*
 * Prototype: parameter init
 */

void init_alimap(Alimapoption *AliMapOption);
void runalimap(Alimapoption *AliMapOption);
