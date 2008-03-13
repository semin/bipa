/*
 *
 * $Id: options.h,v 1.12 2000/08/04 10:26:09 kenji Exp $
 *
 * subst release $Name:  $
 */
/****************************************************************
* subst: A program to calculate environment-specific            *
*        amino acid substitution tables                         *
* Copyright (C) 1999-2000  Kenji Mizuguchi                      *
*                                                               *
*                                                               *
* options.h                                                     *
* Defines command-line options                                  *
****************************************************************/
#ifndef __options
#define __options
/*
 * struct _vars
 *
 * this is the structure that stores all you variables.
 */

struct _vars {
	char	*name;
	int	type;

	long	ival;
	char	*sval;
	float	fval;

	char	*help;

	int	locked;
};

#define OPT_HELP 'h'
#define OPT_TEM_LIST 'f'
#define OPT_OUTFILE 'o'
#define OPT_ANAL 'D'
#define OPT_WEIGHT 1000
#define OPT_WEIGHT_NOT 1001
#define OPT_OUTPUT 1002
#define OPT_SIGMA 1003
#define OPT_ADD 1004
#define OPT_VERBOSE 1005
#define OPT_CYS 1006
#define OPT_SMOOTH_NOT 1007
#define OPT_PENV 1008
#define OPT_SCALE 1009
#define OPT_PIDMIN 1010
#define OPT_PIDMAX 1011

#define OPTSTRING "hf:o:D"
#define V_MAX_VARNAME_LENGTH 10

#define TYPE_INT 0
#define TYPE_STRING 1
#define TYPE_FLOAT 2
#define TYPE_BOOL 3

extern char *listfilename;
extern char *outputfile;
extern int pclust;
extern int opt_anal;
extern int opt_verbose;
extern int opt_output;
extern int opt_cys;
extern double opt_sigma;
extern double opt_add;
extern int opt_weight_not;
extern int opt_smooth_not;
extern int opt_penv;
extern int opt_scale;
extern double opt_pidmin;
extern double opt_pidmax;

int get_options(int, char **);
void show_help();
int banner();

#endif
