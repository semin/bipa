/*
 * General purpose head file
 */

/************START*************/


#define GEN

#undef MEMDEBUG 


#undef DEBUG 



/*
 * Define boolean type
 */

typedef short int boolean;
#define TRUE 1
#define FALSE 0


/*
 * Using double or float
 * Remember to change %f/%lf
 */

#define MYREAL	float


/* Define error code */

#define SUCCESS				0
#define FAIL				-1

#define ERROR_Found "Error reported by "
#define ERROR_MemErr "Memory allocation error"
#define ERROR_MemcpyErr "Memory copy error"
#define ERROR_FileNotFound "File not found"

#define ERROR_Code_General		-1
#define ERROR_Code_FileNotFound		1
#define ERROR_Code_RadiiLibFormatError	2
#define ERROR_Code_MemErr		3
#define ERROR_Code_TooManyInputFile	4
#define ERROR_Code_Usage		5
#define ERROR_Code_UnknownOption	6
#define ERROR_Code_NoAtomFound		7
#define ERROR_Code_BadFileName		8



/* Define macro to compare two numbers */

#define max(a,b) (((a)>(b))?(a):(b))
#define min(a,b) (((a)<(b))?(a):(b))



/* Define EndOfLine symbol */

#define EOL	'\n'



/* Define EndOfString symbol */

#define EOS	'\0'



/* Define medium string length */

#define MEDIUM_STRING_LEN 300



/* Define maximum length of file name */

#define MAX_FileNameLen 300



/* Define temporary string */

#define TempStr_Length 4000



/* prototype: trim the space and non-printable character at both ends of the input string */

void trim(char *line);



/* prototype: Get rid of the redundent characters. For same characters in a given line,
              only the first one is kept. */

void NoRedundentChar(char *line);



/* prototype: Get the filename without the extension from the full path.
   eg.  /user1/fugue/aat1/aat.tem  -->  aat   */

void ShortFilename(char *line);


/* prototype: Check whether overwriting is allowed */

boolean OverwriteCheck(char *FileName_Output, boolean *flag_OverwriteYes);
