/*
 * Read atom coordinates from PDB file
 *
 */


/**************START**************/

#include <stdio.h>

#ifndef gen_Name
	#include "gen.h"
#endif


#define pdb

#define read_pdb_Name "read_pdb.c"


#define	DEFAULT_GETMODEL	1	/* get the first model */



/*
 * define coordinate range
 */

#define         MAX_XYZ         900.0
#define         MIN_XYZ         -900.0




/*
 * define length and position of records read in from PDB.
 */

#define PDB_ATOMNAME_LEN	4
#define PDB_ATOMNO_LEN		5
#define PDB_RESNAME_LEN		3
#define PDB_RESNO_LEN		5
#define	PDB_IDCODE_LEN		4
#define	PDB_COMPND_LEN		60
#define	PDB_SOURCE_LEN		60

#define PDB_ATOMNAME_POS	13
#define PDB_ATOMNO_POS		7
#define PDB_RESNAME_POS		18
#define PDB_RESNO_POS		23
#define PDB_CHAIN_POS		22
#define PDB_ALTERLOC_POS	17
#define PDB_X_POS		31
#define PDB_Y_POS		39
#define PDB_Z_POS		47
#define PDB_REST_POS		55
#define	PDB_TEMP_POS		61
#define PDB_IDCODE_POS		63
#define PDB_COMPND_POS		11
#define PDB_SOURCE_POS		11


/*
 * define structure for the PDB records
 */

typedef struct pdbatom_AM    	PDBATOM_AM;
typedef struct pdbresidue_AM	PDBRESIDUE_AM;
typedef struct pdbrec_AM	PDBREC_AM;
typedef struct pdbdesc		PDBDESC;

struct pdbatom_AM {
	char		AtomNo[PDB_ATOMNO_LEN+1];
	char		AtomName[PDB_ATOMNAME_LEN+1];
	char		AlterLoc;
	float		x;
	float		y;
	float		z;
	int		index;
	PDBRESIDUE_AM	*ResiduePtr;
	PDBATOM_AM		*next_ptr;
	boolean		isValid;	// whether we accept this atom ?
	boolean		isCalpha;	// is this C-alpha ?
	};

struct pdbresidue_AM {
	char		ResName[PDB_RESNAME_LEN+1];
	char		ResNo[PDB_RESNO_LEN+1];
	char		ShortName;	// B=ASX  Z=GLX  X=other unknown residue
	char		Chain;
	PDBATOM_AM		*AtomPtr;	// pointer to the first atom of this residue
	PDBRESIDUE_AM	*next_ptr;
	int		Num_Atom;	// number of atoms in this residue
	int		Index_Atom;	// index number of the first atom (start from 0)
	int		Num_Atom_Valid;	// number of valid atoms in this residue
	boolean		flag_missing;	// any missing atoms ?
	boolean		flag_missingMCA;  // main chain atom missing ?
	boolean		flag_isaminoacid; // is standard amino acid ?
	boolean		flag_isterm;	// is C-terminal ?
	boolean		flag_isOXT;	// is last atom OXT ?
	};

struct pdbdesc {
	char	method;				// X for X-ray ; N for NMR; M for Model; EOS for unknown
	char	code[PDB_IDCODE_LEN+1];		// PDB code (4 letters)
	char	start_r[PDB_RESNO_LEN+1];	// start residue no
	char	start_c;			// start chain
	char	end_r[PDB_RESNO_LEN+1];		// end residue no
	char	end_c;				// end chain
	char	ProteinName[MAX_SeqInfoLength];	// Protein name
	char	source[MAX_SeqInfoLength];	// Source of the protein
	char	resolution[MAX_SeqInfoLength];
	char	Rfactor[MAX_SeqInfoLength];

	char	desc[MAX_SeqInfoLength];	// summary description line
	};

struct pdbrec_AM {
	PDBATOM_AM		**Atoms;
	PDBRESIDUE_AM	**Residues;
	PDBDESC		description;
	int		Num_AllResidue;
	int		Num_AllAtom;
	int		getmodel;
	char		chainID;
	boolean		ismultimodel;
	boolean		flag_DelANISOU;
	boolean		flag_DelAltPos;
	boolean		flag_DelHAtom;
	boolean		flag_DelMissMCA;
	boolean		flag_CheckPDB;
	boolean		flag_ConvertPCA;
	};


/*
 * Prototype
 */

int read_pdb_AM(PDBREC_AM *MyPdbRec, FILE *in_file, boolean flag_Verbose);
void free_pdb_AM(PDBREC_AM *MyPdbRec);
void check_pdb_AM(PDBREC_AM *MyPdbRec, boolean flag_Verbose);
void print_pdb_AM(PDBREC_AM *MyPdbRec, char *FileName_read_pdb);
void print_pdb_valid(PDBREC_AM *MyPdbRec, char *FileName_read_pdb);
void check_hydrogen(PDBREC_AM *MyPdbRec, boolean flag_Verbose);
void check_XYZRange(PDBREC_AM *MyPdbRec, boolean flag_Verbose);
void check_AltPos(PDBREC_AM *MyPdbRec, boolean flag_Verbose);
void check_ResAtomNum(PDBREC_AM *MyPdbRec, boolean flag_Verbose);
void check_MainChainAtom(PDBREC_AM *MyPdbRec, boolean flag_Verbose);
boolean GetPDBHeader(PDBREC_AM *MyPdbRec, FILE *in_file, boolean flag_Verbose);
