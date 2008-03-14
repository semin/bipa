/*
 * Read atom coordinates from PDB file
 *
 */


/**************START**************/

#define pdb

#define read_pdb_Name "read_pdb.c"


#define	DEFAULT_GETMODEL	1	/* get the first model */

/*
 * define length and position of records read in from PDB.
 */

#define PDB_ATOMNAME_LEN	4
#define PDB_ATOMNO_LEN		5
#define PDB_RESNAME_LEN		3
#define PDB_RESNO_LEN		5

#define PDB_ATOMNAME_POS	13
#define PDB_ATOMNO_POS		7
#define PDB_RESNAME_POS		18
#define PDB_RESNO_POS		23
#define PDB_CHAIN_POS		22
#define PDB_ALTERLOC_POS	17
#define PDB_X_POS		31
#define PDB_Y_POS		39
#define PDB_Z_POS		47
#define	PDB_TEMP_POS		61


/*
 * define structure for the PDB records
 */

typedef struct pdbatom    PDBATOM;
typedef struct pdbresidue PDBRESIDUE;
typedef struct pdbrec     PDBREC;

struct pdbatom {
	char		AtomNo[PDB_ATOMNO_LEN+1];
	char		AtomName[PDB_ATOMNAME_LEN+1];
	char		AlterLoc;
	MYREAL		x;
	MYREAL		y;
	MYREAL		z;
	MYREAL		SurfaceRadiusSQR;
	int		index;
	int		ID_mainchain;
	int		ID_polarside;
	PDBRESIDUE	*ResiduePtr;
	PDBATOM		*next_ptr;
	boolean		flag_isatom;	// with leading 'ATOM  '
	};

struct pdbresidue {
	char		ResName[PDB_RESNAME_LEN+1];
	char		ResNo[PDB_RESNO_LEN+1];
	char		ShortName;	// U=UNK  B=ASX  Z=GLX  X=other unknown residue
	char		Chain;
	PDBATOM		*AtomPtr;	// pointer to the first atom of this residue
	PDBRESIDUE	*next_ptr;
	int		Num_Atom;	// number of atoms in this residue
	int		Index_Atom;	// index number of the first atom (start from 0)
	boolean		flag_missing;
	boolean		flag_isaminoacid; // is standard amino acid ?
	boolean		flag_isterm;	// is C-terminal ?
	boolean		flag_isOXT;	// is last atom OXT ?
	boolean		flag_ishetatm;	// is HETATM group ?
	};

struct pdbrec {
	PDBATOM		**Atoms;
	PDBRESIDUE	**Residues;
	int		Num_AllResidue;
	int		Num_AllAtom;
	int		getmodel;
	boolean		ismultimodel;
	};


/*
 * Prototype
 */

int read_pdb(PDBREC *MyPdbRec, char *FileName_read_pdb, boolean flag_Hetatm,
		boolean flag_Water, boolean flag_UNK, boolean flag_Verbose);
void free_pdb(PDBREC *MyPdbRec);
void print_pdb(PDBREC *MyPdbRec, char *FileName_read_pdb);
void check_pdb(PDBREC *MyPdbRec);
int imnch(char *AtomName);
int ipolsdch(char *AtomName);
