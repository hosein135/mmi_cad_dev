/*
$Id: gemvars.h,v 2.6 1993/09/02 00:21:18 mckenzie Exp $
*/
int MaxHashSize, HashSize;
int (*Streq)();			/* pointer to comparison function */
char CharTran[256];		/* character translation buffer */
char *pCharTran = (char *) -257;/* pointer to character translation table */
				/* don't point there until it's initialized */
unsigned char _argbreak;	/* from nxtarg.c */
int Pass;			/*  The current pass number */
int PassType;			/*  The current pass type: NET/DEVICE */
int Errors;			/*  number of errors encountered so far */
jmp_buf env;			/* for setjmp/longjmp */
char *DebugLevel;		/* string containing multiple attributes */

/*******************************************************************/
/* The following are variables used keep the information that was passed as 
 * flags in the command line
/*******************************************************************/

char MagicFileName[MAXNAMELEN];/* Name of Magic file output */
FILE *MagicFilePtr;	/* Magic file descriptor */
int MagicLambda;	/* Lambda to use on units in sim file */
int MagicDevices, MagicNets;	/* Number of entries in the Magic error file */
char *EqFileName;	/* Name of the name equate file */
FILE *EqFilePtr;	/* Equate file descriptor */
char *DictFileName;	/* Name of dictionary file */
FILE *DictFilePtr;	/* Dictionary file descriptor */
short PrintWarnings;	/* print size mismatch warning messages if true */
short PrintCapWarnings;	/* print capacitor warning messages if true */
float SizePercent;	/* Tolerance allowed in transistor length/widths */
long CapPercent;	/* Tolerance allowed in capacitance */
			/* double the int value to get percent, 10 -> 20% */
int PrintZeroNets;	/* Print nets with zero connections */
int NoProgressCutOff;	/* Number of passes with no work before stopping */
int SuspectCutOff;	/* Number of times to try and clear the suspects */
int ErrorCutOff;	/* Stop if we have fewer than this many nodes left */
int NoOpt;		/* Flag whether to optimize by looking at 
			 * neighbors only */
int SimFormat;	   	/* SIM format or gemini format input file. */
int ChainWarnings;	/* Print warning messages for chains out of order */
int CollapseChains;	/* Collapse chains of transistors into composite 
			   devices */
int CaseFold;	       	/* Case fold all names */
int NetPrintLimit;	/* Only print net connections if net is small */
int MatchedCount;	/* Number of matched nodes so far */

int Verbose;	   	/* be verbose when printing information */
int Trace;		/* Trace progress of labelling */
int Interactive; 	/* Turn on if interactive mode is allowed */

int ForcedMatch;	/* Flags whether we have stepped in to disambiguate 
			 * partitions */
int FindMatch;          /* Deduce matches where possible */
int DeduceNeighbors;	/* Only use local matching if less than this number 
			   of neighbors */
int UseSuffix;		/* Use suffixes to guess at matching names */
int NumDeviceDefs;	/* Number of different devices 	*/
DeviceDefinition *DeviceDefs;	/* List of devices definitions 	*/
int DeducedMatches;	/* Number of matches that Gemini deduced */
short CollapseSameOnly;
short FoldFingers;
