/*
 * THIS FILE WAS GENERATED AUTOMATICALLY
 * with Where's Your Grammar?, by Lars Kellogg-Stedman <lars@larsshack.org>
 *
 * For more information, see:
 * http://www.larsshack.org/sw/wyg/
 */

#ifndef _genvars
#define _genvars

#include <getopt.h>

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

/*
 * LOCKVAR locks a variable
 * UNLOCKVAR unlocks a variable
 * LOCKED tests whether or not a variable is set.
 */
#define LOCKVAR(x)	variables[(x)].locked=1
#define UNLOCKVAR(x)	variables[(x)].locked=0
#define LOCKED(x)	(variables[(x)].locked == 1)

/*
 * some accessor macros that might reduce your typing
 * a little bit.
 */
#define VI(x)		(variables[(x)].ival)
#define VF(x)		(variables[(x)].fval)
#define VS(x)		(variables[(x)].sval)
#define VT(x)		(variables[(x)].type)

/*
 * used in calls to init_parser to control how errors opening the
 * config file are handled.
 */
#define PARSE_IGNORE_CONF	0
#define PARSE_WARN_CONF		1
#define PARSE_ERR_CONF		2

/* extern declaration so everyone knows where the variables are */
extern struct _vars variables[];

/* prototypes for public functions */
void init_parser(char *, int);
int parse_options(int, char *[]);
void show_var_help(char *);
void show_var_values(void);
char *var_as_string(int);
int setvar(int, int, int, ...);

#define WYG_VERSION_MAJOR 1
#define WYG_VERSION_MINOR 1
#define WYG_VERSION_REVISION 3

#define V_FEATURE_SET 0
#define V_TEM 1
#define V_HTML 2
#define V_PS 3
#define V_RTF 4
#define V_DEVICE 5
#define V_DIR 6
#define V_SEG 7
#define V_KEY 8
#define V_CHECK 9
#define V_SEQCOLOUR 10
#define V_DOMAIN 11
#define V_CONSENSUS_SS 12
#define V_ALIGNMENT_POS 13
#define V_PSACUTOFF 14
#define V_NWIDTH 15
#define V_MAXCODELEN 16
#define V_FONTSIZE 17
#define V_PSFONT 18
#define V_PSCOLOUR 19
#define V_BGCOLOR 20
#define V_LC 21
#define V_SEQFONTSIZE 22
#define V_WYG_FLOAT_PRECISION 23

#define OPT_FEATURE_SET 'f'
#define OPT_TEM 't'
#define OPT_TEM_NOT 1000
#define OPT_HTML 1001
#define OPT_HTML_NOT 1002
#define OPT_PS 1003
#define OPT_PS_NOT 1004
#define OPT_RTF 1005
#define OPT_RTF_NOT 1006
#define OPT_DEVICE 'd'
#define OPT_DIR 1007
#define OPT_SEG 'g'
#define OPT_SEG_NOT 1008
#define OPT_KEY 1009
#define OPT_KEY_NOT 1010
#define OPT_CHECK 1011
#define OPT_CHECK_NOT 1012
#define OPT_SEQCOLOUR 1013
#define OPT_DOMAIN 1014
#define OPT_DOMAIN_NOT 1015
#define OPT_CONSENSUS_SS 1016
#define OPT_CONSENSUS_SS_NOT 1017
#define OPT_ALIGNMENT_POS 1018
#define OPT_ALIGNMENT_POS_NOT 1019
#define OPT_PSACUTOFF 'S'
#define OPT_NWIDTH 1020
#define OPT_MAXCODELEN 1021
#define OPT_FONTSIZE 1022
#define OPT_PSFONT 1023
#define OPT_PSCOLOUR 1024
#define OPT_PSCOLOUR_NOT 1025
#define OPT_BGCOLOR 1026
#define OPT_LC 1027
#define OPT_LC_NOT 1028
#define OPT_SEQFONTSIZE 1029
#define OPT_WYG_FLOAT_PRECISION 1030
#define OPT_HELP 1031
#define OPT_SHOW_CONFIG 1032

#define OPTSTRING "f:td:gS:"

#define V_NUM_VARS 24
#define V_MAX_VARNAME_LENGTH 19

#define TYPE_INT 0
#define TYPE_STRING 1
#define TYPE_FLOAT 2
#define TYPE_BOOL 3


#endif /* _genvars */
