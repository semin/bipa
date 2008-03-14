/*
 * THIS FILE WAS GENERATED AUTOMATICALLY
 * with Where's Your Grammar?, by Lars Kellogg-Stedman <lars@larsshack.org>
 *
 * For more information, see:
 * http://www.larsshack.org/sw/wyg/
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>
#include <stdarg.h>

#include <parse.h>

extern FILE	*yyin;

/* prototypes for local (static) functions */
static void read_config_file(void);
static char *option_of(char *);
static void show_one_var_help(int);

/* options array for getopt_long */
static struct option options[]={

	{"feature-set", required_argument, NULL, OPT_FEATURE_SET},
	{"tem", no_argument, NULL, OPT_TEM},
	{"notem", no_argument, NULL, OPT_TEM_NOT},
	{"html", no_argument, NULL, OPT_HTML},
	{"nohtml", no_argument, NULL, OPT_HTML_NOT},
	{"ps", no_argument, NULL, OPT_PS},
	{"nops", no_argument, NULL, OPT_PS_NOT},
	{"rtf", no_argument, NULL, OPT_RTF},
	{"nortf", no_argument, NULL, OPT_RTF_NOT},
	{"device", required_argument, NULL, OPT_DEVICE},
	{"dir", required_argument, NULL, OPT_DIR},
	{"seg", no_argument, NULL, OPT_SEG},
	{"noseg", no_argument, NULL, OPT_SEG_NOT},
	{"key", no_argument, NULL, OPT_KEY},
	{"nokey", no_argument, NULL, OPT_KEY_NOT},
	{"check", no_argument, NULL, OPT_CHECK},
	{"nocheck", no_argument, NULL, OPT_CHECK_NOT},
	{"seqcolour", required_argument, NULL, OPT_SEQCOLOUR},
	{"domain", no_argument, NULL, OPT_DOMAIN},
	{"nodomain", no_argument, NULL, OPT_DOMAIN_NOT},
	{"consensus-ss", no_argument, NULL, OPT_CONSENSUS_SS},
	{"noconsensus-ss", no_argument, NULL, OPT_CONSENSUS_SS_NOT},
	{"alignment-pos", no_argument, NULL, OPT_ALIGNMENT_POS},
	{"noalignment-pos", no_argument, NULL, OPT_ALIGNMENT_POS_NOT},
	{"psacutoff", required_argument, NULL, OPT_PSACUTOFF},
	{"nwidth", required_argument, NULL, OPT_NWIDTH},
	{"maxcodelen", required_argument, NULL, OPT_MAXCODELEN},
	{"fontsize", required_argument, NULL, OPT_FONTSIZE},
	{"psfont", required_argument, NULL, OPT_PSFONT},
	{"pscolour", no_argument, NULL, OPT_PSCOLOUR},
	{"nopscolour", no_argument, NULL, OPT_PSCOLOUR_NOT},
	{"bgcolor", required_argument, NULL, OPT_BGCOLOR},
	{"lc", no_argument, NULL, OPT_LC},
	{"nolc", no_argument, NULL, OPT_LC_NOT},
	{"seqfontsize", required_argument, NULL, OPT_SEQFONTSIZE},
	{"wyg-float_precision", required_argument, NULL, OPT_WYG_FLOAT_PRECISION},
	{"help", optional_argument, NULL, OPT_HELP},
	{"show-config", no_argument, NULL, OPT_SHOW_CONFIG},
	{NULL, 0, NULL, 0}


};

/* variable array */
struct _vars variables[]={

	{"feature_set", TYPE_STRING, 0, "default", 0, "name of feature set                                              ", 0},
	{"tem", TYPE_BOOL, 1, NULL, 0, "output tem file", 0},
	{"html", TYPE_BOOL, 1, NULL, 0, "output html file", 0},
	{"ps", TYPE_BOOL, 1, NULL, 0, "output PostScript file", 0},
	{"rtf", TYPE_BOOL, 1, NULL, 0, "output RTF file", 0},
	{"device", TYPE_STRING, 0, "html", 0, "typeset device", 0},
	{"dir", TYPE_STRING, 0, "-", 0, "change directory to search for data files", 0},
	{"seg", TYPE_BOOL, 0, NULL, 0, "use segment info", 0},
	{"key", TYPE_BOOL, 0, NULL, 0, "display key to JOY format", 0},
	{"check", TYPE_BOOL, 1, NULL, 0, "check data for consistency", 0},
	{"seqcolour", TYPE_INT, 3, NULL, 0, "sequence colouring scheme", 0},
	{"domain", TYPE_BOOL, 0, NULL, 0, "display domain assignment", 0},
	{"consensus_ss", TYPE_BOOL, 1, NULL, 0, "display consensus secondary structure", 0},
	{"alignment_pos", TYPE_BOOL, 1, NULL, 0, "display alignment position", 0},
	{"psacutoff", TYPE_FLOAT, 0, NULL, 7.0, "accessibility cutoff (7.0)", 0},
	{"nwidth", TYPE_INT, 50, NULL, 0, "width of the output alignment (50)", 0},
	{"maxcodelen", TYPE_INT, 10, NULL, 0, "maximum characters for sequence code (10)", 0},
	{"fontsize", TYPE_STRING, 0, "-", 0, "fontsize for HTML and PostScript output", 0},
	{"psfont", TYPE_STRING, 0, "-", 0, "change font for PostScript output", 0},
	{"pscolour", TYPE_BOOL, 0, NULL, 0, "colour PostScript", 0},
	{"bgcolor", TYPE_STRING, 0, "-", 0, "background colour for HTML output", 0},
	{"lc", TYPE_BOOL, 0, NULL, 0, "display sequences in lowercase", 0},
	{"seqfontsize", TYPE_STRING, 0, "-", 0, "fontsize for sequence only entries", 0},
	{"wyg_float_precision", TYPE_INT, 4, NULL, 0, "precision for converting floats to strings", 0},
	{NULL, 0, 0, NULL, 0, NULL}


};

/* file-global variables */
static int missing_conf = 0;
static char *config_filename = NULL;

/*
 * init_parser
 *
 * call this function with the full pathname of your configuration
 * file, and with one of the following constants:
 *
 *   PARSE_IGNORE_CONF     a missing config file is silently ignored
 *   PARSE_WARN_CONF       a missing config file generates a warning
 *   PARSE_ERR_CONF        a missing config file causes program to exit
 */
void init_parser(char *cf, int msng)
{
	missing_conf = msng;
	config_filename = strdup(cf);
}

/*
 * parse_options(argc,argv)
 *
 * you must call this function if you want to handle command line
 * options.
 *
 * this function parses the command line and then reads the configuration
 * file.  command line options override options in the config file.
 */
int parse_options(int argc, char *argv[])
{
	int	c,
		show_config = 0;

	while ((c = getopt_long(argc, argv, OPTSTRING, options, NULL)) != EOF) {
		switch(c) {

			case OPT_FEATURE_SET:
				setvar(V_FEATURE_SET, 0, 1, optarg);
				break;
			case OPT_TEM:
				setvar(V_TEM, 0, 0, 1);
				break;
			case OPT_TEM_NOT:
				setvar(V_TEM, 0, 0, 0);
				break;
			case OPT_HTML:
				setvar(V_HTML, 0, 0, 1);
				break;
			case OPT_HTML_NOT:
				setvar(V_HTML, 0, 0, 0);
				break;
			case OPT_PS:
				setvar(V_PS, 0, 0, 1);
				break;
			case OPT_PS_NOT:
				setvar(V_PS, 0, 0, 0);
				break;
			case OPT_RTF:
				setvar(V_RTF, 0, 0, 1);
				break;
			case OPT_RTF_NOT:
				setvar(V_RTF, 0, 0, 0);
				break;
			case OPT_DEVICE:
				setvar(V_DEVICE, 0, 1, optarg);
				break;
			case OPT_DIR:
				setvar(V_DIR, 0, 1, optarg);
				break;
			case OPT_SEG:
				setvar(V_SEG, 0, 0, 1);
				break;
			case OPT_SEG_NOT:
				setvar(V_SEG, 0, 0, 0);
				break;
			case OPT_KEY:
				setvar(V_KEY, 0, 0, 1);
				break;
			case OPT_KEY_NOT:
				setvar(V_KEY, 0, 0, 0);
				break;
			case OPT_CHECK:
				setvar(V_CHECK, 0, 0, 1);
				break;
			case OPT_CHECK_NOT:
				setvar(V_CHECK, 0, 0, 0);
				break;
			case OPT_SEQCOLOUR:
				setvar(V_SEQCOLOUR, 0, 1, optarg);
				break;
			case OPT_DOMAIN:
				setvar(V_DOMAIN, 0, 0, 1);
				break;
			case OPT_DOMAIN_NOT:
				setvar(V_DOMAIN, 0, 0, 0);
				break;
			case OPT_CONSENSUS_SS:
				setvar(V_CONSENSUS_SS, 0, 0, 1);
				break;
			case OPT_CONSENSUS_SS_NOT:
				setvar(V_CONSENSUS_SS, 0, 0, 0);
				break;
			case OPT_ALIGNMENT_POS:
				setvar(V_ALIGNMENT_POS, 0, 0, 1);
				break;
			case OPT_ALIGNMENT_POS_NOT:
				setvar(V_ALIGNMENT_POS, 0, 0, 0);
				break;
			case OPT_PSACUTOFF:
				setvar(V_PSACUTOFF, 0, 1, optarg);
				break;
			case OPT_NWIDTH:
				setvar(V_NWIDTH, 0, 1, optarg);
				break;
			case OPT_MAXCODELEN:
				setvar(V_MAXCODELEN, 0, 1, optarg);
				break;
			case OPT_FONTSIZE:
				setvar(V_FONTSIZE, 0, 1, optarg);
				break;
			case OPT_PSFONT:
				setvar(V_PSFONT, 0, 1, optarg);
				break;
			case OPT_PSCOLOUR:
				setvar(V_PSCOLOUR, 0, 0, 1);
				break;
			case OPT_PSCOLOUR_NOT:
				setvar(V_PSCOLOUR, 0, 0, 0);
				break;
			case OPT_BGCOLOR:
				setvar(V_BGCOLOR, 0, 1, optarg);
				break;
			case OPT_LC:
				setvar(V_LC, 0, 0, 1);
				break;
			case OPT_LC_NOT:
				setvar(V_LC, 0, 0, 0);
				break;
			case OPT_SEQFONTSIZE:
				setvar(V_SEQFONTSIZE, 0, 1, optarg);
				break;
			case OPT_WYG_FLOAT_PRECISION:
				setvar(V_WYG_FLOAT_PRECISION, 0, 1, optarg);
				break;


			case OPT_HELP:
				show_var_help(optarg);
				exit(0);
				break;

			case OPT_SHOW_CONFIG:
				show_config=1;
				break;

			default:
				/*
				 * unrecognized options end up here.
				 * you may want to change this code to be
				 * a little more user friendly.
				 */
				fprintf(stderr,"bad usage.\n");
				exit(2);
				break;
		}
	}

	read_config_file();

	if (show_config) {
		printf("#\n# Current configuration\n#\n\n");
		show_var_values();
		exit(0);
	}

	return optind;
}

static void read_config_file()
{
	FILE	*conf;
	int	err;

	/* return if user has not defined a config file */
	if (! config_filename) return;

	/* try and open it */
	conf = fopen(config_filename, "r");

	/* if we succeeded, try and parse it */
	if (conf) {
		yyin=conf;
		err = yyparse();
		fclose(conf);

		if (err) {
			fprintf(stderr, "error parsing config file %s.", config_filename);
			exit(1);
		}
	} else {
		/*
		 * eek, we couldn't open the config file!  decide what to
		 * do based on value passed to init_parser().
		 */
		if (missing_conf == PARSE_WARN_CONF) {
			fprintf(stderr,"warning: config file %s does not exist (using defaults).\n",
				config_filename);
		} else if (missing_conf == PARSE_ERR_CONF) {
			fprintf(stderr,"error: config file %s does not exist.\n",
				config_filename);
			exit(1);
		}
	}

}

/*
 * setvar
 *
 * oo, i'm proud of this one.
 *
 * this is how variables get set -- it is used both by the getopt_long
 * call, above, and by the parser code generated from parse.y.
 *
 * setting 'force' will cause it to overwrite variables that have
 * already been set.  normally, we don't do this because we want the
 * command line to override the config file.
 *
 * set 'cvt' if you're passing it a string (char *) value instead
 * of a numeric value (when you're setting a numeric variable),
 * and setvar will happily convert your string to the appropriate type.
 */
int setvar(int v, int force, int cvt, ...)
{
	va_list	ap;

	if (v >= V_NUM_VARS) {
		fprintf(stderr, "warning: attemp to set unknown variable, v=%d.", v);
		return 0;
	}

	if (LOCKED(v) && ! force)
		return 0;

	va_start(ap, cvt);

	switch (VT(v)) {
		case TYPE_INT:
		case TYPE_BOOL:
			if (cvt) {
				variables[v].ival = atol(va_arg(ap, char *));
			} else {
				variables[v].ival = va_arg(ap, long);
			}
			break;

		case TYPE_STRING:
			variables[v].sval = strdup(va_arg(ap, char *));
			break;

		case TYPE_FLOAT:
			if (cvt) {
				variables[v].fval = atof(va_arg(ap, char *));
			} else {
				variables[v].fval = va_arg(ap, double);
			}
			break;
	}
	va_end(ap);

	LOCKVAR(v);

	return 1;
}

/*
 * show_var_help
 * show_var_values
 *
 * these are two debugging functions that are pretty self
 * explanatory.
 */

void show_var_help(char *opt)
{
	int	i,
		seen = 0;

	printf("This program supports the following options:\n\n");

	for (i=0; i<V_NUM_VARS; i++) {
		if (!opt)
			show_one_var_help(i);
		else {
			if (strncmp(option_of(variables[i].name), opt, strlen(variables[i].name)) == 0)
				show_one_var_help(i);
		}
	}
}

static void show_one_var_help(int v)
{
	if (v >= V_NUM_VARS)
		return;

	printf("--%-*s    %s\n", 
		V_MAX_VARNAME_LENGTH,
		option_of(variables[v].name),
		variables[v].help);
	if (VT(v) == TYPE_BOOL) {
		printf("--no%-*s  %s\n", 
			V_MAX_VARNAME_LENGTH,
			option_of(variables[v].name),
			"");
	}
}

void show_var_values()
{
	int i;

	for (i=0; i<V_NUM_VARS; i++) {
		switch(VT(i)) {
			case TYPE_INT:
				printf("%s = ", variables[i].name);
				printf("%ld", VI(i));
				break;

			case TYPE_BOOL:
				if (VI(i))
					printf("%s", variables[i].name);
				else
					printf("!%s", variables[i].name);
				break;

			case TYPE_FLOAT:
				printf("%s = ", variables[i].name);
				printf("%f", VF(i));
				break;

			case TYPE_STRING:
				printf("%s = ", variables[i].name);
				printf("%s", VS(i));
				break;
		}

		printf("\n");
	}
}

/*
 * returns the value of a variable as a string
 */
char *var_as_string(int v)
{
	char	*val	= NULL;
	int	len	= 0;

	if (v >= V_NUM_VARS)
		return NULL;

	switch(VT(v)) {
		case TYPE_INT:
		case TYPE_BOOL:
			len = (VI(v) % 10) + 1;
			val = (char *)malloc(len);
			sprintf(val,"%d",VI(v));
			break;

		case TYPE_FLOAT:
			len = ((int)VF(v) % 10) + 1 + VI(V_WYG_FLOAT_PRECISION);
			val = (char *)malloc(len);
			sprintf(val,"%.*f",VI(V_WYG_FLOAT_PRECISION),VF(v));
			break;

		case TYPE_STRING:
			val = strdup(VS(v));
			break;
	}

	return val;
}

/*
 * converts config file variable (some_name) to command line argument
 * version (some-name).
 */
static char *option_of(char *name)
{
	char	*newname,
		*c;

	newname=strdup(name);
	c=newname;
	while (*c++)
		if (*c == '_') *c = '-';
	
	return newname;
}


