/*
 * Calculate residue accessible surface area
 *
 */


/**************START**************/

#define	NRT		20
#define	NP		19
#define NM		3
#define NUM_RESACC	10

#ifdef RESACC
	#undef RESACC


	// --- New standard accessibilities by Simon Hubbard (Dec. 1989) ------------

	MYREAL ATOTAL[2][NRT]= {
	// TOTAL CONTACT AREA IN FULLY EXTENDED open CHAIN FORM
			{ 33.27, 72.58, 40.91, 39.38, 41.90,
			  51.60, 48.53, 23.75, 54.98, 55.52,
			  56.53, 61.45, 61.86, 60.81, 44.58,
			  33.77, 41.85, 75.22, 62.17, 47.71 },
	// TOTAL ACCESSIBLE SURFACE AREA IN FULLY EXTENDED open CHAIN FORM
			{ 109.19,243.03,144.93,141.31,136.20,
			  180.60,174.46, 81.20,183.87,177.22,
			  180.35,204.10,197.05,199.73,140.92,
			  118.24,142.04,248.09,212.29,153.33 }
			};

	MYREAL ANPOLSIDE[2][NRT]= {
	// TOTAL NON POLAR AREA OF SIDECHAIN IN EXTENDED FORM (INCLUDING CA)
			{ 23.16, 25.92, 14.56, 15.95, 31.96,
			  17.00, 19.75, 10.84, 30.43, 45.71,
			  46.61, 38.72, 51.94, 51.54, 39.28,
			  15.76, 24.92, 58.15, 42.35, 37.89 },
	// TOTAL NON-POLAR ACCESSIBLE SURFACE AREA OF SIDECHAIN IN EXTENDED
	// FORM (INCLUDING CA)
			{ 70.81, 79.70, 45.01, 49.50, 98.3,
			  52.53, 61.20, 33.14, 96.38,139.76,
			  142.52,118.39,159.23,164.49,120.12,
			  48.19, 76.21,185.88,134.89,115.87 }
			};

	MYREAL APOLSIDE[2][NRT]= {
	// TOTAL POLAR AREA OF SIDE CHAIN IN EXTENDED CONFORMATION
			{ 0.0, 36.74, 16.38, 13.44,  0.0,
			  24.68, 18.86,   0.0, 15.18,  0.0,
			  0.0, 12.81,   0.0,   0.0,  0.0,
			  7.86,  7.01,  6.93, 10.56,  0.0 },
	// TOTAL POLAR ACCESSIBLE SURFACE AREA OF SIDECHAIN IN EXTENDED CONFORM
			{ 0.00,125.54, 61.88, 53.78,   0.0,
			  90.25, 75.42,   0.0, 51.88,   0.0,
			  0.0, 47.88,   0.0,  0.00,  0.00,
			  31.44, 28.04, 23.69, 42.22,  0.00 }
			};

	MYREAL ASIDE[2][NRT]= {
	// TOTAL SIDE CHAIN AREA (INCLUDING CA)
			{ 23.16,62.66,30.93,29.40,31.96,
			  41.67,38.61,10.84,45.61,45.71,
			  46.61,51.53,51.94,51.54,39.28,
			  23.62,31.93,65.08,52.91,37.89 },
	// TOTAL SIDE CHAIN ACCESSIBLE SURFACE AREA (INCLUDING CA)
			{ 70.81,205.23,106.90,103.28, 98.3,
			  142.78,136.63, 33.14,148.25,139.76,
			  142.52,166.28,159.23,164.49,120.12,
			  79.63,104.24,209.56,177.11,115.87 }
			};

	MYREAL AMAIN[2][NRT]= {
	// MAIN CHAIN AREAS IN EXTENDED FORM (NOT INCLUDING CA)
			{ 10.11, 9.92, 9.98, 9.98, 9.94,
			  9.92, 9.92,12.91, 9.37, 9.81,
			  9.92, 9.92, 9.92, 9.28, 5.29,
			  10.15, 9.92,10.14, 9.26, 9.82 },
	// MAIN CHAIN ACCESSIBLE SURFACE AREA IN EXTENDED FORM (NOT INCLUDING CA)
			{ 38.38,37.83,38.03,38.03,37.90,
			  37.83,37.83,48.06,35.62,37.45,
			  37.83,37.83,37.83,35.24,20.80,
			  38.61,37.80,38.53,35.18,37.46 }
			};

	// change to single letter code
	char RESLIST[NRT+3][4]= {
				"ALA","ARG","ASN","ASP","CYS","GLN",
				"GLU","GLY","HIS","ILE","LEU","LYS",
				"MET","PHE","PRO","SER","THR","TRP",
				"TYR","VAL","ASX","GLX","UNK" };


	char POLATM[NP][5]= {
			" AD1", " AD2", " AE1", " AE2",
			" ND1", " ND2", " NE ", " NE1",
			" NE2", " NH1", " NH2", " NZ ",
			" OD1", " OD2", " OE1", " OE2",
			" OG ", " OG1", " OH " };

	char MNCHATM[NM+1]="NCO";

#endif


#define resacc_Name "resacc.c"



typedef struct resacc2 RESACC2;
struct resacc2 {
	MYREAL		**resacc;
	};


/*
 * Prototype
 */

void resacc(RESACC2 *ResAcc2, PDBREC *MyPdbRec, MYREAL *access, int *SkipRes, boolean flag_ContactTypeSurface,
		boolean flag_UNK, boolean flag_Verbose);
void free_resacc(MYREAL **ResAcc, PDBREC *MyPdbRec);
MYREAL percent(MYREAL x, MYREAL y);
int icode(char *ResName, boolean flag_UNK);
