/*
 * Calculate accessible surface area
 *
 */


/**************START**************/

#define contact_Name "contact.c"



/*
 * define constants
 */

#define	PI	3.1415926535898
#define	PIx2	6.2831853071796



/*
 * define smallest number of intersections and the increase number
 * each time re-allocating memory.
 */

#define	MIN_INTERSECTION	500
#define INC_INTERSECTION	200

#define MIN_TAG			500
#define INC_TAG			200

#define INC_NEIGHBOR		100	// also used as MIN_NEIGHBOR


/*
 * define structure for cube information
 */

typedef struct cubeinfo CUBEINFO;
struct cubeinfo {
	int		Num_Atom;	// Number of atoms in this cube
	int		indexI;		// Index along X axis
	int		indexJ;		// Index along Y axis
	int		indexK;		// Index along Z axis
	PDBATOM		**Atom;		// Pointers to atoms in this cube
	PDBATOM		**NeighborAtom;
	int		Num_NeighborAtom;
	};



/*
 * Prototype
 */

MYREAL *contact(PDBREC *MyPdbRec, MYREAL *radius, MYREAL ProbeSize,
		MYREAL IntegrationStep, boolean flag_Verbose);
void free_contact(MYREAL *access);
void print_contact(PDBREC *MyPdbRec, MYREAL *access);
void sorttag(MYREAL *arci, int karc, int *tag);
void Contact2Acc(MYREAL *access, MYREAL *radius, MYREAL ProbeSize,
		int Num_AllAtom, boolean flag_Verbose);
