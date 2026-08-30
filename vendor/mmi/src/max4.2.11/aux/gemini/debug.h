/*
$Id: debug.h,v 2.6 1993/09/02 00:21:18 mckenzie Exp $
*/
/*******************************************************************/
/* Debugging macros: these are defined if DEBUG is defined
/*******************************************************************/

/*******************************************************************/
/*
 *	COPYRIGHT (C) 1983  Carl Ebeling and Ofer Zajicek
 *	COPYRIGHT (C) 1988  Carl Ebeling
 *
/*******************************************************************/

/*******************************************************************/
/* Very simple assertions: this could be easily changed to arbitrary statements
 * instead of just a simple comment
/*******************************************************************/

#ifdef ASSERTIONS
#define assert(assertion,comment)	\
 if ( ! (assertion) )			\
   { fprintf(stderr,"\nAssertion failed: %s\n",comment); longjmp(env,1); }
#else
#define assert(assertion,comment)
#endif

/*******************************************************************/
/* The global variable DebugLevel defines which debugging information is
 * printed.  See flags below.
 * DebugLevel is set to a string of debugging chars via the -d flag
/*******************************************************************/

extern char *DebugLevel;

#ifdef DEBUG

#define debug(level, remaining)			\
 if (DebugLevel != NULL)			\
   { register char *p = DebugLevel;		\
     while ((*p != '\0') && (*p != level)) p++;	\
     if (*p == level)				\
        { remaining }				\
   }
#else
#define debug(level,remaining)
#endif

#define ALWAYS		'\0'	/* Matches null at end of string */
#define FORCE		'f'
#define PROGRESS	'P'
#define CLEAN		'C'
#define TRACE		't'
#define INITVALUE	'I'
#define TRACEALL	'T'
#define PRINTBAD	'b'
#define UNIQUES		'u'
#define SUSPECTS	'q'
#define CHECKSUM	'X'
#define ENTERHASH	'e'
#define COMPUTEVALUE	'v'
#define HASH		'h'
#define HASHTABLE	'H'
#define MATCH		'm'
#define SORT		's'
#define INPUT		'i'
#define PARTITIONS	'p'
#define NEWVALUES	'n'
#define SIMFORMAT	'S'
#define TEMPTEST	'x'
#define EQUATE		'E'
#define CHAIN		'c'
#define DEDUCE		'D'
#define DOUBLECHECK	'd'
