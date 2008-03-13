/*
 *
 * $Id: options.c,v 1.14 2000/08/04 10:26:09 kenji Exp $
 *
 * subst release $Name:
 */
/****************************************************************
* subst: A program to calculate environment-specific            *
*        amino acid substitution tables                         *
* Copyright (C) 1999-2000  Kenji Mizuguchi                      *
*                                                               *
*                                                               *
* options.c                                                     *
* Defines command-line options                                  *
****************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

#include "getopt.h"
#include "options.h"
#include "release.h"

static void show_one_var_help(int);

char *listfilename;
char *outputfile = NULL;
int pclust = 60;       /* default clustering level PID 60*/
int opt_anal = 0;
int opt_verbose = 0;
int opt_output = 2;
int opt_cys = 0;
double opt_sigma = 5.0;
double opt_add = -1.0;
int opt_weight_not = 0;
int opt_smooth_not = 0;
int opt_penv = 0;
int opt_scale = 3;      /* matrix in 1/3 bit units */
double opt_pidmin = -1.0;
double opt_pidmax = 110.0;

int n_vars = 21;

static struct option options[]={

  {"tem-list", required_argument, NULL, OPT_TEM_LIST},
  {"weight", required_argument, NULL, OPT_WEIGHT},
  {"noweight", no_argument, NULL, OPT_WEIGHT_NOT},
  {"nosmooth", no_argument, NULL, OPT_SMOOTH_NOT},
  {"output", required_argument, NULL, OPT_OUTPUT},
  {"outfile", required_argument, NULL, OPT_OUTFILE},
  {"scale", required_argument, NULL, OPT_SCALE},
  {"cys", required_argument, NULL, OPT_CYS},
  {"sigma", required_argument, NULL, OPT_SIGMA},
  {"add", required_argument, NULL, OPT_ADD},
  {"penv", no_argument, NULL, OPT_PENV},
  {"pidmin", required_argument, NULL, OPT_PIDMIN},
  {"pidmax", required_argument, NULL, OPT_PIDMAX},
  {"analysis", no_argument, NULL, OPT_ANAL},
  {"verbose", no_argument, NULL, OPT_VERBOSE},
  {"help", no_argument, NULL, OPT_HELP},
  {NULL, 0, NULL, 0}
};

/* variable array */
struct _vars variables[]={
  {"tem-list", TYPE_STRING, 0, NULL, 0.0, "file     specify a file containing a list of .tem files (also -f)"},
  {"outfile", TYPE_STRING, 0, NULL, 0.0,  "file     output filename (\"allmat.dat\" if not specified) (also -o)"},
  {"weight", TYPE_INT, 0, NULL, 0.0,      "int      clustering level for the BLOSUM-like weighting (default 60)"},
  {"noweight", TYPE_BOOL, 0, NULL, 0.0,   "         calculate substitution counts with no weights"},
  {"", TYPE_BOOL, 0, NULL, 0.0,           "         (must specify --output 0 or --output 1)"},
  {"nosmooth", TYPE_BOOL, 0, NULL, 0.0,   "         perform no smoothing operation"},
  {"cys", TYPE_INT, 0, NULL, 0.0,         "int      0 for using C and J only for structure, 1 for both structure and sequence"},
  {"output", TYPE_INT, 0, NULL, 0.0,      "int      0 for raw counts (no-smoothing performed)"},
  {"", TYPE_INT, 0, NULL, 0.0,            "         1 for probabilities"},
  {"", TYPE_INT, 0, NULL, 0.0,            "         2 for log-odds (default)"},
  {"scale", TYPE_INT, 0, NULL, 0.0,       "int      log-odds matrices in 1/n bit units (default 3)"},
  {"sigma", TYPE_FLOAT, 0, NULL, 0.0,     "double   change the sigma value for smoothing (default 5)"},
  {"add", TYPE_FLOAT, 0, NULL, 0.0,       "double   add this value to raw counts when deriving log-odds without smoothing"},
  {"", TYPE_FLOAT, 0, NULL, 0.0,          "         (default 1/#classes)"},
  {"penv", TYPE_BOOL, 0, NULL, 0.0,       "         use environment-dependent frequencies for log-odds calculation (default false)"},
  {"pidmin", TYPE_FLOAT, 0, NULL, 0.0,    "double   count substitutions only for pairs with PID equal to or"},
  {"", TYPE_INT, 0, NULL, 0.0,            "         greater than this value (default none)"},
  {"pidmax", TYPE_FLOAT, 0, NULL, 0.0,    "double   count substitutions only for pairs with PID smaller than this value (default none)"},
  {"analysis", TYPE_BOOL, 0, NULL, 0.0,   "         analyze structural environments (also -D)"},
  {"verbose", TYPE_BOOL, 0, NULL, 0.0,    "         very verbose output"},
  {"help", TYPE_STRING, 0, NULL, 0.0,     "         help (also -h)"}
};

int get_options(int argc, char *argv[]) {
  int c;
  while ((c = getopt_long(argc, argv, OPTSTRING, options, NULL)) != EOF) {
    switch(c) {
    case OPT_TEM_LIST:
      if ((listfilename = strdup(optarg)) == NULL) {
	fprintf(stderr, "Can't allocate memory\n");
	exit(1);
      }
      break;
    case OPT_OUTFILE:
      if ((outputfile = strdup(optarg)) == NULL) {
	fprintf(stderr, "Can't allocate memory\n");
	exit(1);
      }
      break;
    case OPT_WEIGHT:
      pclust = atoi(optarg);
      break;
    case OPT_OUTPUT:
      opt_output = atoi(optarg);
      break;
    case OPT_CYS:
      opt_cys = atoi(optarg);
      break;
    case OPT_SIGMA:
      opt_sigma = atof(optarg);
      break;
    case OPT_ADD:
      opt_add = atof(optarg);
      break;
    case OPT_ANAL:
      opt_anal = 1;
      break;
    case OPT_WEIGHT_NOT:
      opt_weight_not = 1;
      break;
    case OPT_SMOOTH_NOT:
      opt_smooth_not = 1;
      break;
    case OPT_PENV:
      opt_penv = 1;
      break;
    case OPT_SCALE:
      opt_scale = atoi(optarg);
      break;
    case OPT_PIDMIN:
      opt_pidmin = atof(optarg);
      break;
    case OPT_PIDMAX:
      opt_pidmax = atof(optarg);
      break;
    case OPT_VERBOSE:
      opt_verbose = 1;
      break;
    case OPT_HELP:
      show_help();
      exit(0);
      break;

    default:
      fprintf(stderr,"Unknown option %c\n", c);
      exit(0);
      break;
    }
  }
  return optind;
}

void show_help() {
  int i;

  banner();
  printf("Usage: subst [ options ] temfile...\n");
  printf("         or\n");
  printf("       subst [ options ] -f file\n\n");
  printf("Available options:\n\n");

  for (i=0; i<n_vars; i++) {
    show_one_var_help(i);
  }
}

static void show_one_var_help(int v) {
  
  if (v >= n_vars) return;

  if (strlen(variables[v].name) > 0) {
    printf("--%-*s %s\n", V_MAX_VARNAME_LENGTH,
	   variables[v].name, variables[v].help);
  }
  else {
    printf("  %-*s %s\n", V_MAX_VARNAME_LENGTH,
	   variables[v].name, variables[v].help);
  }    
}

int banner() {
  fprintf(stderr, "subst: A program to calculate environment-specific\n");
  fprintf(stderr, "       amino acid substitution tables\n");
  fprintf(stderr, "Copyright (C) 1999-2000  Kenji Mizuguchi\n");
  fprintf(stderr, "version ");
  fprintf(stderr, MAINVERSION);
  fprintf(stderr, ".");
  fprintf(stderr, SUBVERSION);
  fprintf(stderr, " (");
  fprintf(stderr, UPDATE);
  fprintf(stderr, ")\n\n");
  return (1);
}

