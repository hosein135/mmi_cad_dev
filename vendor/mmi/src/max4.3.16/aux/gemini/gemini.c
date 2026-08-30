/*
$Id: gemini.c,v 2.7.2.1 1994/03/16 04:32:41 mckenzie Exp mckenzie $
*/
/*******************************************************************/
/* This files contains the main program and driving routines for Gemini
/*******************************************************************/

/*******************************************************************/
/*
 *	COPYRIGHT (C) 1983  Carl Ebeling and Ofer Zajicek
 *	COPYRIGHT (C) 1988  Carl Ebeling
 *
/*******************************************************************/

/*******************************************************************/
/* HISTORY
 *
 * Modified 1/22/89 by Martin Harriman.  Add -F option to suppress
 * finger collapsing.
 *
 * Modified 12/21/89 Pete Johnson to add CollapseSameOnly option and
 * change help message to print out proper message for '-M' option.
 * The docs said it was -C, but it really is '-M' in the code and 
 * -C is now used for CollapseSameOnly.  So there!
 */
/*******************************************************************/

#include "gemini.h"
#include "gemvars.h"
#include <ctype.h>

static char *useString = 
"gemini {-[CFGIcfhmotvz]} {-[DEM]filename} {-[enpswy]number} file1 file2\n";
static char *version_string = "Gemini 2.7.2	1994/3/15\n";

void main(argc, argv)
int argc;
char *argv[];
{
  register int i;

  Graph *graph1 = AllocGraph(),
  *graph2 = AllocGraph();

/* perform a longjmp here and write the dict file if an assertion fails */
  printf(version_string);
  if (setjmp(env)) {
    if (DictFilePtr) WriteDictionary(graph1, graph2);
#ifdef DEBUG
    printf("Longjmp returned to main(); terminating.\n");
#endif
    exit(1);
  }

/*******************************************************************
* Initialize the flag variables
*******************************************************************/

  MagicFileName[0] = '\0';
  MagicFilePtr = NULL;
  MagicLambda = 100;		/* Default lambda = 1 micron */
  MagicDevices = 0;		/* Number of devices/nets written to the */
  MagicNets = 0;		/* Magic error file */
  EqFileName = NULL;
  DictFileName = NULL;
  DictFilePtr = NULL;
  PrintWarnings = FALSE;
  PrintCapWarnings = FALSE;
  SizePercent = .1;		/* 10% tolerance by default */
  CapPercent = 10;		/* 20% by default (double the int value) */
  PrintZeroNets = FALSE;
  NoProgressCutOff = 2;
  SuspectCutOff = 1;
  ErrorCutOff = 0;
  MatchedCount = 0;
  NoOpt = FALSE;
  Trace = FALSE;
  NetPrintLimit = 10;  
  CollapseChains = TRUE;
  CollapseSameOnly = FALSE;
  ChainWarnings = FALSE;
  SimFormat = MIT;
  Verbose = FALSE;
  CaseFold = FALSE;
  Interactive = FALSE;
  ForcedMatch = FALSE;
  DeducedMatches = 0;
  FindMatch = TRUE;
  DeduceNeighbors = DEDUCEHTSIZE/10;
  DebugLevel = "                    ";	/* Debug level defaults to null */
  FoldFingers = TRUE;
  UseSuffix = TRUE;
  sRandom(1);
  /*    sRandom(time(0));*/
  
  /*******************************************************************/
  /* Parse command line options
  /*******************************************************************/

    for (i = 1; i < argc; i++) {
	 if (argv[i][0] == '-') {
	switch (argv[i][1]) {
	case 'd':	
#ifdef DEBUG
	  if (argv[i][2] == '\0') {
	    if (++i < argc)
		 DebugLevel = argv[i];
	    else break;
	  }
	  else strncpy(DebugLevel,&argv[i][2],20);
	  continue;
#else
	  break;		/* Illegal flag */
#endif
	  
	case 'c':
	  if (argv[i][2] == 'w') ChainWarnings = TRUE;
	  else CollapseChains = FALSE;
	  continue;

	case 'C':
	  CollapseSameOnly = TRUE;
	  PrintWarnings = TRUE;	/* Need to load the sizes */
	  continue;

	case 'D':
	  if (argv[i][2] == '\0') {
	    if (++i < argc)
		 DictFileName = CopyString(argv[i]);
	    else break;
	  } else DictFileName = CopyString(&argv[i][2]);
	  continue;

	case 'e':
	  if (argv[i][2] == '\0') {
	    if (++i < argc)
		 ErrorCutOff = atoi(argv[i]);
	    else break;
	  } else ErrorCutOff = atoi(&argv[i][2]);
	  continue;

	case 'E':
	  if (argv[i][2] == '\0') {
	    if (++i < argc)
		 EqFileName = CopyString(argv[i]);
	    else break;
	  } else EqFileName = CopyString(&argv[i][2]);
	  continue;

	case 'f': CaseFold = TRUE; continue;

	case 'F': FoldFingers = FALSE; continue;

	case 'G': SimFormat = GEM; continue;

	case 'h':
	  fprintf(stderr, useString);
	  fprintf(stderr, "-C : Collapse like sized devices (-w is implied)\n");
	  fprintf(stderr, "-F : Do not collapse fingered transistors\n");
	  fprintf(stderr, "-G : Use Gemini file format instead of SIM format\n");
	  fprintf(stderr, "-I : Interactive mode\n");
	  fprintf(stderr, "-c : Do not collapse transistor chains\n");
	  fprintf(stderr, "-cw: Print warnings for out-of-order chains\n");
	  fprintf(stderr, "-f : Case-fold net names (ABC==abc)\n");
	  fprintf(stderr, "-h : Help: print this usage summary\n");
	  fprintf(stderr, "-m : Do not use local matching\n");
	  fprintf(stderr, "-o : Do not optimize labeling procedure\n");
	  fprintf(stderr, "-t : Trace execution\n");
	  fprintf(stderr, "-v : Verbose output\n");
	  fprintf(stderr, "-z : Print nets with zero connections\n");
	  fprintf(stderr, "-D<filename> : Output file of name equivalences\n");
	  fprintf(stderr, "-E<filename> : Input file of name equivalences\n");
	  fprintf(stderr, "-M<filename> : Output Magic file with error tiles at mismatched device locations\n");
	  fprintf(stderr, "-e<number> : Set error limit\n");
	  fprintf(stderr, "-n<number> : Set net size limit when printing connections\n");
	  fprintf(stderr, "-p<number> : Set no-progress limit\n");
	  fprintf(stderr, "-s<number> : Set suspect-node limit\n");
	  fprintf(stderr, "-w<number> : Compare transistor sizes using number as tolerance percentage\n");
	  fprintf(stderr, "-y<number> : Compare capacitance using number as tolerance percentage\n");
	  exit(1);

	case 'I': Interactive = TRUE; continue;

	case 'm': FindMatch = FALSE; continue;

	case 'M':
	  if (argv[i][2] == '\0') {
	    if (++i < argc)
		 strcpy(MagicFileName, argv[i]);
	    else break;
	  } else strcpy(MagicFileName, &argv[i][2]);
	  continue;

	case 'n':
	  if (argv[i][2] == '\0') {
	    if (++i < argc)
		 NetPrintLimit = atoi(argv[i]);
	    else break;
	  } else NetPrintLimit = atoi(&argv[i][2]);
	  continue;

	case 'N':
	  if (argv[i][2] == '\0') {
	    if (++i < argc)
		 DeduceNeighbors = atoi(argv[i]);
	    else break;
	  } else DeduceNeighbors = atoi(&argv[i][2]);
	  if (DeduceNeighbors > DEDUCEHTSIZE) {
	    fprintf(stderr, "Deduce neighborhood value too large, using default value: %d\n", DEDUCEHTSIZE/10);
	    DeduceNeighbors = DEDUCEHTSIZE/10;
	  }
	  continue;

	case 'o': NoOpt= TRUE; continue;

	case 'p':
	  if (argv[i][2] == '\0') {
	    if (++i < argc)
		 NoProgressCutOff = atoi(argv[i]);
	    else break;
	  } else NoProgressCutOff = atoi(&argv[i][2]);
	  continue;

	case 's':
	  if (argv[i][2] == '\0') {
	    if (++i < argc)
		 SuspectCutOff = atoi(argv[i]);
	    else break;
	  } else SuspectCutOff = atoi(&argv[i][2]);
	  continue;

	case 'S': SimFormat = MIT; continue;
	case 't': Trace = TRUE; continue;

	case 'w':
	  PrintWarnings = TRUE;
	  if (argv[i][2] == '\0') {
	    if (((i+1) < argc) &&
		isdigit(argv[i+1][0])) {
		 SizePercent = atof(argv[++i])/100.;
	    }
	  } else {
	    SizePercent = atof(&argv[i][2])/100.;
	  }
	  continue;

	case 'v': Verbose = TRUE; continue;

	case 'y':
	  PrintCapWarnings = TRUE;
	  if (argv[i][2] == '\0') {
	    if (((i+1) < argc) &&
		isdigit(argv[i+1][0])) {
		 CapPercent = atol(argv[++i])/2;
	    }
	  } else {
	    CapPercent = atol(&argv[i][2])/2;
	  }
	  continue;

	case 'z': PrintZeroNets = TRUE; continue;

	default:	break;
	}
	fprintf(stderr, useString);
	exit(1);

/*******************************************************************/
/*  Arguments that are not flags are filenames
/*******************************************************************/

	} else if (graph1->graphName == NULL)
	  graph1->graphName = argv[i];
	else
	  graph2->graphName = argv[i];
	continue;
    }

  if (FindMatch && NoOpt) {
    fprintf(stderr, "Cannot deduce matches and turn off optimization too!\n");
    exit(1);
  }
  if (graph1->graphName == NULL) {
    fprintf(stderr, useString);
    exit(1);
  }
  InitCharTran();		/* Set up case translation */
  if (MagicFileName[0] != '\0') {
    unsigned char *p = (unsigned char *) MagicFileName;
    unsigned char *arg = nxtarg(&p, (unsigned char *) ":");
    char tempName[MAXNAMELEN];

    if (*p != '\0') {
	 MagicLambda = atoi((char *)p);
    }
    strncpy(tempName, MagicFileName, MAXNAMELEN);
    strcat(MagicFileName, ".err.mag");
    if ((MagicFilePtr = fopen(MagicFileName, "w")) != NULL) {
	 fprintf(MagicFilePtr, "magic\ntech scmos\nuse %s %s_0\n",
		 tempName, tempName);
	 fprintf(MagicFilePtr, "transform 1 0 0 0 1 0\nbox 0 0 10 10\n");
    } else {
	 fprintf(stderr, "Cannot open: %s\n", MagicFileName);
	 fprintf(stderr, "No Magic error file output will be generated\n");
    }
  }
  if (DictFileName != NULL) {
    if ((DictFilePtr = fopen(DictFileName, "w")) != NULL) {
	 fprintf(DictFilePtr, "; Dictionary file for matching names in\n");
	 fprintf(DictFilePtr, "; %s and %s\n", 
		graph1->graphName, graph2->graphName);
	 fflush(DictFilePtr);
    } else {
	 fprintf(stderr, "Cannot open: %s\n", DictFileName);
	 fprintf(stderr, "No dictionary will be generated\n");
    }
  }
  ReadEqFile(EqFileName);

  Errors = 0;

/*******************************************************************/
/* Depending on the number of graphs filenames given, label one or two
   graphs.  (Two graphs must be labeled in parallel)
/*******************************************************************/

  graph1->graphNumber = 1;
  graph2->graphNumber = 2;
    
  if (graph2->graphName != NULL ) 
    twoGraphs(graph1, graph2);
  else {
    fprintf(stderr, "Two graphs must be given\n");
    exit(1);
  }
/*
    oneGraph(graph1);
*/

/*******************************************************************/
/* End of labelling: try to determine what happened.
/*******************************************************************/

  fprintf(stderr, "\n");	/* Finish off the progress report */
  if (DictFilePtr)	WriteDictionary(graph1, graph2);
  if (CollapseChains)	CheckChains(graph1, graph2);
  if (PrintWarnings)	CompareProperties(graph1, graph2);
  if (PrintCapWarnings)	CompareNetProperties(graph1, graph2);
  if (graph1->numNets) {
    if (FindMatch) {
      printf("%d (%d%%) matches were found by local matching\n",
	   DeducedMatches/2,
	   (100*DeducedMatches/(2*(graph1->numDevices+graph1->numNets))));
    }
  } else {
    printf("Warning: input file '%s' is null\n",graph1->graphName);
  }

  if ( DoneGraph(graph1) && DoneGraph(graph2)) {

/*******************************************************************/
/* Both Graphs were uniquely labelled.
/*******************************************************************/

    printf("All nodes were matched in %d passes\n", Pass);
#ifdef DEBUG
    for (i=0; i<NumDeviceDefs; i++) {
      printf("%3d: %s, %d\n",
        i, DeviceDefs[i].name, DeviceDefs[i].numTerminals);
    }
#endif

  } else {

/*******************************************************************/
/* Graphs were not labelled uniquely 
/*******************************************************************/

    if (! DoneGraph(graph1) ) {
     printf("\n	Graph number 1: %s \n",graph1->graphName);
     printf("	--------------------------\n");
     if (graph1->badNets.size) {
	printf("%d NETS definitely do not match:\n", graph1->badNets.size);
	PrintQueue(&graph1->badNets);
     }
     if (graph1->suspectNets.size) {
	printf("%d NETS could not be matched, possibly because of other unmatched nets:\n",
    	graph1->suspectNets.size);
	PrintQueue(&graph1->suspectNets);
     }
     CleanPendingArray(graph1, NET, &graph1->nets);
     if (graph1->nets.size) {
	printf("%d NETS were not matched because of symmetries:\n", graph1->nets.size);
	PrintQueue(&graph1->nets);
     }

     if (graph1->badDevices.size) {
	printf("\n%d DEVICES definitely do not match:\n", graph1->badDevices.size);
	PrintQueue(&graph1->badDevices);
     }
     if (graph1->suspectDevices.size) {
	printf("%d DEVICES could not be matched, possibly because of other unmatched devices:\n",
    	graph1->suspectDevices.size);
	PrintQueue(&graph1->suspectDevices);
     }
     CleanPendingArray(graph1, DEVICE, &graph1->devices);
     if (graph1->devices.size) {
	printf("%d DEVICES were not matched because of symmetries:\n", graph1->devices.size);
	PrintQueue(&graph1->devices);
     }

/*******************************************************************/
/* If a MAGIC file name was given, mark the error nets.  Make sure the SUSPECT 
 * and  BAD nets are included.
/*******************************************************************/

     ResetSuspects(graph1);
     ResetBad(graph1);
     CleanPendingArray(graph1, NET, &graph1->nets);
     CleanPendingArray(graph1, DEVICE, &graph1->devices);
     if (MagicFilePtr != NULL) {
	if (graph1->SimFormat == GEM) {
	  fprintf(stderr,
	    "Gemini file format not compatible with -M option\n");
	  fclose(MagicFilePtr);
	  MagicFilePtr = NULL;
	}
	MagicOutQueue(&graph1->nets);
	MagicOutQueue(&graph1->devices);
      }
    }

    if (! DoneGraph(graph2) ) {
	 printf("\n	Graph number 2: %s \n",graph2->graphName);
	 printf("	--------------------------\n");
	 if (graph2->badNets.size) {
	printf("%d NETS definitely do not match:\n", graph2->badNets.size);
	PrintQueue(&graph2->badNets);
	 }
	 if (graph2->suspectNets.size) {
	printf("%d NETS could not be matched, possibly because of other unmatched nets:\n",
		graph2->suspectNets.size);
	PrintQueue(&graph2->suspectNets);
	 }
	 CleanPendingArray(graph2, NET, &graph2->nets);
	 if (graph2->nets.size) {
	printf("%d NETS were not matched because of symetries:\n", graph2->nets.size);
	PrintQueue(&graph2->nets);
	 }

	 if (graph2->badDevices.size) {
	printf("\n%d DEVICES definitely do not match:\n", graph2->badDevices.size);
	PrintQueue(&graph2->badDevices);
	 }
	if (graph2->suspectDevices.size) {
	printf("%d DEVICES could not be matched, possibly because of other unmatched devices:\n",
		graph2->suspectDevices.size);
	PrintQueue(&graph2->suspectDevices);
	 }
	CleanPendingArray(graph2, DEVICE, &graph2->devices);
	 if (graph2->devices.size) {
	printf("%d DEVICES were not matched because of symetries:\n", graph2->devices.size);
	PrintQueue(&graph2->devices);
	 }

/*******************************************************************/
/* If a MAGIC file name was given, mark the error nets.  Make sure the SUSPECT 
 * and  BAD nets are included.

	 ResetSuspects(graph2);
	 ResetBad(graph2);
	 CleanPendingArray(graph2, NET, &graph2->nets);
	 CleanPendingArray(graph2, DEVICE, &graph2->devices);
	 if (MagicFilePtr != NULL)
	  MagicOutQueue(&graph2->nets);
	 if (MagicFilePtr != NULL)
	  MagicOutQueue(&graph2->devices);
/*******************************************************************/
    }
  }
  if (MagicFilePtr != NULL) {
    fprintf(MagicFilePtr, "<< end >>\n");
    fclose(MagicFilePtr);
    printf("%d devices and %d nets displayed in %s\n",
	   MagicDevices, MagicNets, MagicFileName);
  }
  exit(0);
}

STATIC void askContinue()
{
  char answer[20];

  if (Interactive) {
    printf("Do you want to continue? [yes] ");
    gets(answer);
    if (answer[0] == 'n') {
      printf("Are you sure? ");
      gets(answer);
      if (answer[0] == 'y') {
	printf("Bye...\n");
	exit(0);
      }
    }
  }
}

/*******************************************************************/
/*	Main program for the case of two graphss.
/*******************************************************************/

STATIC void twoGraphs(graph1, graph2)
Graph *graph1, *graph2;
{
  int suspectTry;	/*  Number of tries to disambiguate suspects with
			 *  no progress: -1 : no progress seen yet 
			 *  		  0 : means some progress seen
			 *		  >0: number of tries since progress */
  int progress;		/*  number of nodes that became unique */

/*******************************************************************/
/*  Initialization:  Assign initial values to all nodes and run one pass.
/*******************************************************************/

  Pass = 0;		
  ClearQueue(&graph1->nextEvalQueue);
  ClearQueue(&graph2->nextEvalQueue);

/* InitTwoGraphs may set up the nextEvalQueue with MATCHING nodes */

  InitTwoGraphs(graph1, graph2);

/*******************************************************************/
/* Always start by labeling the Nets.  Nets with initial bad values can
 * spread harm a long ways.
/*******************************************************************/

  PassType = NET;		/* start with the Nets. */
  suspectTry = -1;		/* -1 means we have not made any progress yet*/

/*******************************************************************/
/* refinePartitions will relabel the graph until it can make no 
 * further progress and return how many nodes it was able to label
 * uniquely.
/*******************************************************************/

  while ( (! DoneGraph(graph1)) || (! DoneGraph(graph2)) ) {
    progress = refinePartitions(graph1, graph2);

    if (progress < 0) break;	/* Signal that it is done */
    else if (progress > 0)
      suspectTry = 0;		/* Made some progress */
    else if (suspectTry < 0)
      suspectTry = SuspectCutOff; /* No more labeling will help */
    else suspectTry++;

    /* Check if we've done enough */
    if (NumNodesLeft(graph1) < ErrorCutOff) break;

/*******************************************************************/
/*  Redeem any suspect or bad nodes found when refining partitions.
 *  Assign initial values and hash instead of relabeling in the usual way.
/*******************************************************************/

   if (graph1->suspectNets.size + graph1->suspectDevices.size +
      graph2->suspectNets.size + graph2->suspectDevices.size
      + graph1->badNets.size + graph1->badDevices.size +
      graph2->badNets.size + graph2->badDevices.size 
      != 0) {
	ClearQueue(&graph1->nextEvalQueue);
	ClearQueue(&graph2->nextEvalQueue);
	ResetSuspects(graph1); ResetSuspects(graph2);
	ResetBad(graph1); ResetBad(graph2);
	if (Trace) printf("Releasing suspects: try no. %d\n", suspectTry);

	PassType = DEVICE;	/* Always start labelling graph with NETS */
   }

/*******************************************************************/
/*  If we have already tried refining the graph enough (SuspectCutOff) times,
 *  then try to assign a mathing.  If forcing a match on one type of node 
 *  doesn't work, then toggle pass types and try the other type.
/*******************************************************************/

    if (suspectTry >= SuspectCutOff) { /* Force a match */
     int result;
     static int warningPrinted = FALSE;
     int percent = 
	(NumNodesLeft(graph1)*100) / (graph1->numNets+graph1->numDevices);

     if (Trace) {
	printf("%d of %d (%d%%) nodes left to be matched: ", 
		  NumNodesLeft(graph1), graph1->numNets + graph1->numDevices, 
		  percent);
     }
     if (!warningPrinted) {
	warningPrinted = TRUE;
	printf("\nThese circuits contain some symmetry (%d%% nodes not yet matched).\n", percent);
	printf("Gemini will attempt to find a valid match for symmetrical nodes.\n");
	askContinue();
     }
     debug(FORCE,
        PrintGraphStats(graph1);
        PrintGraphStats(graph2);
        )
     if (Trace) printf("guessing nodes that match\n");
#if 0
     if (PrintWarnings)
       PassType = DEVICE;		/* Use properties */
     else
#endif
       PassType = NET;		/* Less chance screwing up */
     result = AssignMatch(graph1, graph2);
     if (result <= 0) {		/* Match failed? */
	PassType = ToggleType(PassType);
	result = AssignMatch(graph1, graph2);
	if (result <= 0) {		/* Match failed? */
	  if (Trace) printf(" none found.\n");
	  return;	/* For now, later try something stronger */
	}
     }
     suspectTry = -1;	/* Means that we haven't made any progress */
     ForcedMatch = TRUE;	/* Signal that we have forced a match */
     if (Trace) printf(" success.\n");
    }
    PassType = ToggleType(PassType);
  }
}

/*******************************************************************/
/*
 * refinePartitions
 * ----------------
 *	Repeatedly label the two graphs until no progress (as measured by the
 *	NoProgressCutOff flag) is being made.
 *
 *	Runs passes, alternating between NETs and DEVICEs, until no progress
 *	is detected.
 *
 *	refinePartitions returns the total number of nodes that became
 *	unique or -1 if it is done processing the graphs.
/*******************************************************************/

STATIC int refinePartitions(graph1, graph2)
Graph *graph1, *graph2;
{
  int sizeNew;			/*  number of new unique nodes this round */
  int noProgress = 0;		/*  number of passes with no progress */
  int numLeft = NumNodesLeft(graph1);
  static errorsFound = FALSE;	/* Set as soon as errors are found */

  while ( (! DoneGraph(graph1)) || (! DoneGraph(graph2)) ) {
    sizeNew = RelabelGraphs(graph1, graph2);
    if (sizeNew > 0) noProgress = 0;
    else  noProgress++;

    if ((Errors > 0) && (! errorsFound)) {
     errorsFound = TRUE;	/* So we print message only once */
     if (ForcedMatch) {
	printf("\nThe circuits are probably different (but Gemini may have made an error\n");
	printf("when matching symmetrical nodes).  Try using the -E option for node labels.\n");
	askContinue();
     } else {
	printf("The circuits are different.\n");
	askContinue();
     }
    }
    if (noProgress >= NoProgressCutOff) {
     debug(PROGRESS, printf("refinePartitions: %d new uniques\n", 
    	   numLeft - NumNodesLeft(graph1));
	  )
     return(numLeft - NumNodesLeft(graph1));  /* measure of progress */
    }
    PassType = ToggleType(PassType);	/*  toggle the pass type  */
  }
  debug(PROGRESS, printf("refinePartitions: DONE\n");)
  return(-1);	/* Signals that the graphs are uniquely labelled */
}

/*******************************************************************/
/*
 * RelabelGraphs
 * -------------
 *	Perform one relabeling on the two graphs:
 *		1) Assign new values to nodes in both graphs (and set the 
 *		   nextEvalQueue to the frontier nodes)
 *		2) Match the new unique nodes (weeding out BAD & SUSPECT nodes)
 *		3) Match the non-singleton partitions (weeding out SUSPECTs)
 *
 *	The number of nodes found unique in the current pass is returned.
/*******************************************************************/

int RelabelGraphs(graph1, graph2)
register Graph *graph1, *graph2;
{
  int nodesLeft = NumNodesLeft(graph1);
  int currentMatched = MatchedCount;

  MatchedCount = graph1->uniqueDevices.size + graph1->uniqueNets.size;
  if (MatchedCount/1000 != currentMatched/1000) {
    fprintf(stderr, " %d", MatchedCount/1000);
    fflush(stderr);
  }
  Pass++;
  if (Trace) {
    printf("Pass %d) Relabeling %s: %d in next eval queue\n",
	   Pass, (PassType == NET) ? "NETS" : "DEVICES", 
	   graph1->nextEvalQueue.size);
  }
  debug(TRACE, 
	PrintGraphStats(graph1);
	PrintGraphStats(graph2);
	)
  if (FindMatch &&
	 (graph1->nextEvalQueue.size != 0) &&
	 (graph1->nextEvalQueue.top->flag == MATCHING)) {
    LocalMatchUniques(graph1, graph2);
  } else {
    HashSize = 0;		/* Reset hash table size => recalculated by 
				 * first graph that initializes hash table */
    AssignNewValues(graph1);
    AssignNewValues(graph2);
    debug(CHECKSUM, printf("main: checksum for %s: %d\n", 
			   graph1->graphName, graph1->checkSum);  )
    debug(CHECKSUM, printf("main: checksum for %s: %d\n", 
				graph2->graphName, graph2->checkSum);  )

    MatchUniques(graph1, graph2);
    MatchPartitions(graph1, graph2);
  }

  ProcessUniques(graph1);
  ProcessUniques(graph2);

  switch (PassType) {
  case DEVICE : 
    AppendQueue(&graph1->uniqueDevices, &graph1->newUniques);
    AppendQueue(&graph2->uniqueDevices, &graph2->newUniques);
    break;
  case NET :
    AppendQueue(&graph1->uniqueNets, &graph1->newUniques);
    AppendQueue(&graph2->uniqueNets, &graph2->newUniques);
    break;
  }	        
  nodesLeft = nodesLeft - NumNodesLeft(graph1);	/*  measures the progress  */

  /* If we did not match anything this time, check to see if we are about
	to match
	*/
  if ((nodesLeft == 0) &&
     (graph1->nextEvalQueue.size != 0) &&
     (graph1->nextEvalQueue.top->flag == MATCHING)) {
    fprintf(stderr, "Matching nodes coming up\n");
    return 1;    /* Progress will be made next pass */
  }
  return nodesLeft;
}

/*******************************************************************/
/*
 * InitTwoGraphs
 * -------------
 *	Initialize the two graphs:
 *	  Read the graphs from files.
 *	  Allocate the hash tables.
 *	  Assign the initial values to all nodes and detect unique ones.
/*******************************************************************/

STATIC void InitTwoGraphs(graph1, graph2)
register Graph *graph1, *graph2;
{
  if (FoldFingers)
    AllocFingerHash();
  ReadGraph(graph1, SimFormat);
  ReadGraph(graph2, SimFormat);

  MaxHashSize = Max( 	Max( graph1->numNets, graph1->numDevices),
			Max( graph2->numNets, graph2->numDevices) );
  MaxHashSize = MaxHashSize / HASHRATIO;
  MaxHashSize += 1;	/* Make sure there is at least one bucket */
  debug(TRACE, printf("Maximum hash size: %d\n", MaxHashSize);  )
  AllocHashTable(graph1);
  AllocHashTable(graph2);

  InitialDeviceValues(graph1);	/*  Assign initial values to devices  */
  InitialDeviceValues(graph2);

  InitialNetValues(graph1);	/* Assign initial values to Nets */
  InitialNetValues(graph2);
  SortQueue(&graph1->nextEvalQueue);
  SortQueue(&graph2->nextEvalQueue);

  CheckEquates();		/* Check whether all names were used */
 }
