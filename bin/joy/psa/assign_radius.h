/*
 * Assign radius for each atom
 *
 */


/**************START**************/

#define assign_radius_Name "assign_radius.c"

/***********************************************************
 * The default radius DEFAULT_ATOMSIZE is defined in psa.h *
 ***********************************************************/


/*
 * Prototype
 */

MYREAL *assign_radius(PDBREC *MyPdbRec, RADIILIB **Array_RadiiLib,
			int Num_RadiiLib, boolean flag_Verbose);
void free_radius(MYREAL *radius);
void print_radius(PDBREC *MyPdbRec, MYREAL *radius);
