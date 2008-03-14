/*
 * PSA Head file
 *
 */


/**************START**************/

#define PSA_Name "psa.c"
/*#define PSA */



/*
 * define default file extension name for residue accessibility output
 * define default file extension name for atom    accessibility output
 */

#define RESIDUEACC_EXT	".psa"
#define ATOMACC_EXT	".sol"
#define	PERRESACC_EXT	".spa"



/*
 * define default options
 */

#define DEFAULT_HETATM		TRUE
#define DEFAULT_WATER		FALSE
#define DEFAULT_VERBOSE		FALSE
#define DEFAULT_RESIDUEACC	TRUE
#define DEFAULT_ATOMACC		FALSE
#define	DEFAULT_RESPERACC	FALSE
#define DEFAULT_CONTACTSURFACE	TRUE
#define DEFAULT_OVERWRITE	TRUE
#define	DEFAULT_PRINTSCREEN	FALSE
#define DEFAULT_UNK		TRUE

#define DEFAULT_ATOMSIZE	1.6
#define DEFAULT_PROBESIZE	1.4
#define MIN_PROBESIZE		0.001
#define MAX_PROBESIZE		10.0
#define DEFAULT_INTEGRATIONSTEP	0.05
#define MIN_INTEGRATIONSTEP	0.00001
#define MAX_INTEGRATIONSTEP	1.0



/*
 * define the maximum number of PDB files to be processed in a single
 * command line
 */

#define MAX_INPUTFILE	500



/*
 * define structure for PSA command-line options
 */

typedef struct psaoption Psaoption;
struct psaoption {

	/* Array of PDB files to be processed */
	char		**FileName_PDB;				/* required */
	/* Number of PDB files in the array */
	int		Num_InputFile;				/* required */

	/* Radii library file. */
	char		*FileName_RadiiLib;

	/* Which model to process when there are multiple model in PDB (starting from 1) */
	int		getmodel;

	/* Probe size */
	MYREAL		ProbeSize;

	/* Integration Step */
	MYREAL		IntegrationStep;

	/* Verbose mode */
	boolean		flag_Verbose;

	/* Include Hetatm ? */
	boolean		flag_Hetatm;

	/* Include Water ? */
	boolean		flag_Water;

	/* Output UNK ? */
	boolean		flag_UNK;

	/* Output residue Acc ? */
	boolean		flag_ResidueAcc;

	/* Output atom Acc ? */
	boolean		flag_AtomAcc;

	/* Output residue percentage Acc in Temperature format ? */
	boolean		flag_ResPerAcc;

	/* Use contact surface type ? */
	boolean		flag_ContactTypeSurface;

	/* Output to stdout ? */
	boolean		flag_PrintScreen;

	/* Permit overwriting files? */
	boolean		flag_OverwriteYes;
	};



/*
 * define version
 */

#define VER "2.0 (Feb 2000)"



/*
 * Prototype: parameter init
 */

int psa(Psaoption *);
void init_psa(Psaoption *PsaOption);
