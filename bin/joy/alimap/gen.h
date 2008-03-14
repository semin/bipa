/*
 * General purpose head file
 */

/************START*************/

#define	gen_Name	"gen.c"

#include <stdio.h>


#define GEN

#undef	MEMDEBUG 

#undef	DEBUG 



#undef	DOS

#ifdef	DOS
	#define		strcasecmp	strcmpi
	#define		strncasecmp	strncmpi
	#define		R_OK		06
	#define		W_OK		02
	#define		F_OK		00
#endif



/* Define boolean type */

typedef short int boolean;
#define TRUE		1
#define FALSE		0

#define	SUCCESS		TRUE
#define	FAIL		FALSE


/* Define stdout */

#define	SCREEN		"screen"


/* Define EndOfLine and EndOfString */

#define EOL		'\n'
#define	EOS		'\0'


/* Define error code */

#define ERROR_Found			"Error reported by "
#define ERROR_MemErr			"Memory allocation error"
#define ERROR_MemcpyErr			"Memory copy error"
#define ERROR_FileNotFound		"File not found"

#define ERROR_Code_General		-1
#define ERROR_Code_FileNotFound		1
#define ERROR_Code_ClassdefFormatError	2
#define ERROR_Code_MemErr		3
#define ERROR_Code_NoValidClassdef	4
#define ERROR_Code_Usage		5
#define ERROR_Code_TemFormatWrong	6
#define ERROR_Code_TemDuplicateSeq	7
#define ERROR_Code_UnknownSymbol	8
#define ERROR_Code_PIDErr		9
#define ERROR_Code_WeightAlgorithm	10
#define ERROR_Code_WeightParameter	11
#define ERROR_Code_Cluster		12
#define ERROR_Code_MemcpyErr		14
#define ERROR_Code_RandomNumber		15
#define ERROR_Code_SubstFormatError	16
#define ERROR_Code_ProfileFormat	17
#define ERROR_Code_SprofEnvNotFound	18
#define ERROR_Code_EnvNotFound		19
#define ERROR_Code_CreateFileFail	20
#define ERROR_Code_UnknownOption	21
#define ERROR_Code_BadFileName		22
#define ERROR_Code_FileExist		23
#define ERROR_Code_PrfFormatError	24
#define ERROR_Code_UnknownSeqFormat	25
#define ERROR_Code_NoSeqFound		26
#define ERROR_Code_AlignAlgorithm	27
#define ERROR_Code_JumbleNumber		28
#define ERROR_Code_SSSYMBOLMISSING	29
#define ERROR_Code_GAPPENALTYMETHOD	30
#define ERROR_Code_SeqProfileFormat	31
#define ERROR_Code_NoAtomFound		32
#define ERROR_Code_SstFormatWrong	33



/* Define macro to compare two numbers */

#define max(a,b) (((a)>(b))?(a):(b))
#define min(a,b) (((a)<(b))?(a):(b))



/* Define symbol for secodary structure elements */

#define HELIX			'H'
#define STRAND			'E'
#define COIL			'C'
#define POSPHI			'P'
#define ACCESIBLE		'A'  /* should be 'T' for the original definition found in tem file */
#define NOT_ACCESIBLE		'a'



/* Define the default classes to be read in */

#define MAX_CLASS_LEN		200  /* Largest length in the following strings */

#define Class_Seq		"sequence;ACDEFGHIKLMNPQRSTVWYJU;ACDEFGHIKLMNPQRSTVWYJU;F;F"
#define Class_Disulphide	"disulphide;TF;Jj;F;F"
#define Class_PercentAcc	"percentage accessibility;0123456789abcdefg;0123456789abcdefg;F;F"
#define Class_Ooi		"Ooi number;0123456789abcdefg;0123456789abcdefg;F;F"

#define Class_Seq_Name		"sequence"
#define Class_SSE_Name		"secondary structure and phi angle"
#define Class_Acc_Name		"solvent accessibility"
#define Class_Disulphide_Name	"disulphide"
#define Class_PercentAcc_Name	"percentage accessibility"
#define Class_Ooi_Name		"Ooi number"

#define Disulphide_Original	'C'
#define Disulphide_General	'U'
#define Disulphide_TRUE		'C'
#define Disulphide_FALSE	'J'
#define Disulphide_Flag_TRUE	'J'
#define Disulphide_Flag_FALSE	'j'



/* Define maximum number of amino acid symbols */

#define MAX_AALETTER		26



/* Define medium string length */

#define MEDIUM_STRING_LEN	100



/* Define maximum length of file name */

#define MAX_FileNameLen		200



/* Define maximum length of sequence name and description line */

#define MAX_SeqNameLength	200
#define MAX_SeqInfoLength	300



/* Define temporary string */

#define TempStr_Length		60000


/* Define the width of PIR print-out */

#define PIR_Width		70


/* Define the number of default classes to read in. */
/* The actual definition is in read_classdef.c      */

#define DEFAULT_Class_Number	4



#ifndef ALIMAP_EXTERNAL
	#include "gen_func.h"
#endif
