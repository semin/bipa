/*
 * Print out the result
 *
 */


/**************START**************/

#define output_Name "output.c"


// Output value if atom accessibility not calculated
#define	DEFAULT_ACCOUT		0.0


/*
 * Prototype
 */

boolean WriteAtomAcc(PDBREC *MyPdbRec, MYREAL ProbeSize, MYREAL IntegrationStep,
			boolean flag_Water, boolean flag_Hetatm, boolean flag_ContactTypeSurface,
			boolean flag_Verbose, boolean *flag_OverwriteYes, char *FileName_PDB,
			MYREAL *access, boolean flag_PrintScreen);

boolean WriteResAcc(PDBREC *MyPdbRec, MYREAL ProbeSize, MYREAL IntegrationStep,
			boolean flag_Water, boolean flag_Hetatm, boolean flag_ContactTypeSurface,
			boolean flag_Verbose, boolean *flag_OverwriteYes, char *FileName_PDB,
			MYREAL **ResAcc, int SkipRes, boolean flag_PrintScreen, boolean flag_UNK);
boolean WritePerResAcc(PDBREC *MyPdbRec, MYREAL ProbeSize, MYREAL IntegrationStep,
			boolean flag_Water, boolean flag_Hetatm, boolean flag_ContactTypeSurface,
			boolean flag_Verbose, boolean *flag_OverwriteYes, char *FileName_PDB,
			MYREAL **ResAcc, boolean flag_PrintScreen);
