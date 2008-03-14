typedef struct psaoption Psaoption;
struct psaoption {

	/* Array of PDB files to be processed */
	char		**FileName_PDB;		/* required */
	/* Number of PDB files in the array */
	int		Num_InputFile;		/* required */

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
