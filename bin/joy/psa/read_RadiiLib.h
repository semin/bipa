/*
 * Read van der Wall's radii from the library
 *
 */


/**************START**************/

#define RadiiLib

#define read_RadiiLib_Name "read_RadiiLib.c"


/*
 * define default library location
 *
 * Use the library file specified in command line first,
 * then try DEFAULT_RADIILIB1 (in current directory) and
 * DEFAULT_RADIILIB2. If none of those three is available,
 * report error.
 */

#define DEFAULT_RADIILIB1	"psa.dat"
#define DEFAULT_RADIILIB2	"psa.dat"


/*
 * define length of residue name and atom name
 * read in from the library.
 */

#define RADIILIB_RESIDUE_LEN	3
#define RADIILIB_ATOM_LEN	4


/*
 * define structure for the radii library
 */

typedef struct radiilib RADIILIB;
struct radiilib {
	char		Residue[RADIILIB_RESIDUE_LEN+1];
	int		Num_Atom;
	char		**Atom;
	MYREAL		*Radii;
	RADIILIB	*next_ptr;
	};

typedef struct radiilib2 RADIILIB2;
struct radiilib2 {
	RADIILIB	**Array_MyRadiiLib;
	};


/*
 * Define environment name for library location
 */

#define ENV_RADIILIB	"PSA2"


/*
 * Prototype
 */

void read_Radiilib(RADIILIB2 *MyRadiiLib2, int *Num_RadiiLib, char *FileName_read_RadiiLib, boolean flag_Verbose);
void print_RadiiLib(RADIILIB **Array_RadiiLib, int Num_RadiiLib);
void free_RadiiLib(RADIILIB **Array_RadiiLib, int Num_RadiiLib);
void read_RadiiLib2(RADIILIB2 *MyRadiiLib2, int *Num_RadiiLib, boolean flag_Verbose);
