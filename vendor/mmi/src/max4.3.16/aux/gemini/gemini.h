/*
$Id: gemini.h,v 2.7 1993/12/17 04:50:10 mckenzie Exp mckenzie $
*/
/*******************************************************************/
/* Definition for GEMINI
 *	COPYRIGHT (C) 1988   Carl Ebeling
 *	COPYRIGHT (C) 1993   Neil McKenzie
/*******************************************************************/

#ifdef NOLABS
#define labs abs
#endif

/*
** rand() under System V is an extremely poor RNG; rand() repeats
** numbers after only about 210 calls, and causes a bug in Gemini.
** random() is a superior RNG with a much larger period than rand and
** thereby does not exhibit the bug.   If your run-time system does
** not support random(), DO NOT globally replace it with rand().
** Instead use the compiler flag NO_RANDOM to invoke the following
** sequence.
*/
#ifdef NO_RANDOM
#define Random (rand() << 16L) + rand
#define sRandom srand
#else
#define Random random
#define sRandom srandom
#endif

#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include <setjmp.h>
#include <string.h>
#include "queue.h"
#include "graph.h"
#include "properties.h"
#include "debug.h"
#include "simread.h"

#define STATIC          /* used when profiling */
#undef NOSTATIC

#define BUFSIZE 4096
#define MAXNAMELEN 256
#define WHITESPACE (unsigned char *) " \n\t"
#define TRUE 	1
#define FALSE 	0
#define MAXINT	0x7fffffff
#define MININT  0x80000000
#define Max(a,b) ((a > b) ? a : b)

/* long long int = 64 bit integer (as seen on DEC AXP) */
#ifdef _LONGLONG
typedef unsigned long long bigint;
#else
typedef unsigned long bigint;
#endif

#define ToggleType(type)	(type == DEVICE ? NET : DEVICE)

/*******************************************************************/
/* Calculate the number of nodes that have not been uniquely labelled
/*******************************************************************/

#define NumNodesLeft(graph)						\
	(((graph)->numDevices - (graph)->uniqueDevices.size)	+	\
	 ((graph)->numNets - (graph)->uniqueNets.size))

/*******************************************************************/
/* Determine whether graph has been completely uniquely labelled
/*******************************************************************/

#define DoneGraph(graph) 						\
	(DoneNets(graph) && (DoneDevices(graph)))

/*******************************************************************/
/* Determine if nets are all uniquely labelled
/*******************************************************************/

#define DoneNets(graph)						\
	( (graph)->uniqueNets.size == (graph)->numNets )

/*******************************************************************/
/* Determine if devices are all uniquely labelled
/*******************************************************************/

#define DoneDevices(graph)					\
	( (graph)->uniqueDevices.size == (graph)->numDevices )

/*******************************************************************/
/* Print relevant statistics on the two graphs for debugging purposes
/*******************************************************************/

#define PrintGraphStats(graph)		\
printf("Graph %s:\n", graph->graphName);	\
printf("%d nets, %d pending, %d suspect, %d bad, %d unique\n",\
  graph->numNets, graph->numPendingNets, graph->suspectNets.size,\
  graph->badNets.size, graph->uniqueNets.size);\
printf("%d devices, %d pending, %d suspect, %d bad, %d unique\n",\
  graph->numDevices, graph->numPendingDevices, graph->suspectDevices.size,\
  graph->badDevices.size, graph->uniqueDevices.size);\
printf("%d nodes in nextEvalQueue\n", graph->nextEvalQueue.size);

/*******************************************************************/
/* The hash table sizes must be the same for all graphs
/*******************************************************************/

#define HASHRATIO 4	  /*  # elements / # buckets in hash table */
#define MIN_NUM_BUCKETS 1 /*  Minimum number of buckets in the hash table */
#define MAX_NUM_BUCKETS 10000000  /*  Maximum number of buckets in the table */
#define DEDUCEHTSIZE 310

extern int MaxHashSize, HashSize;

extern int Pass;
extern int PassType;
extern int Errors;
extern jmp_buf env;			/* for setjmp/longjmp */
/*******************************************************************
 * see gemvars.h for descriptions
 *******************************************************************/
extern char MagicFileName[];
extern FILE *MagicFilePtr;
extern int MagicLambda;	
extern int MagicDevices, MagicNets;
extern char *EqFileName;
extern FILE *EqFilePtr;
extern char *DictFileName;
extern FILE *DictFilePtr;
extern short PrintWarnings;
extern short PrintCapWarnings;
extern float SizePercent;
extern long CapPercent;
extern int PrintZeroNets;
extern int NoProgressCutOff;
extern int SuspectCutOff;
extern int ErrorCutOff;	
extern int NoOpt;
extern int SimFormat;
extern int ChainWarnings;
extern int CollapseChains;
extern int CaseFold;
extern int NetPrintLimit;
extern int MatchedCount;
extern int Verbose;
extern int Trace;
extern int Interactive;
extern int ForcedMatch;
extern int FindMatch;
extern int DeduceNeighbors;
extern int UseSuffix;
extern int NumDeviceDefs;
extern DeviceDefinition *DeviceDefs;
extern int DeducedMatches;
extern int (*Streq)();
extern char *pCharTran;
extern unsigned char _argbreak;	/* from nxtarg.c */
extern short CollapseSameOnly;
extern short FoldFingers;

#ifdef __GNUC__
#include "prototypes.h"
#else
#include "oldprotos.h"
#endif
