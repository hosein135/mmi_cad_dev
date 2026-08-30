/*
$Id: readgraph.c,v 2.7.2.1 1994/03/16 04:32:41 mckenzie Exp mckenzie $
*/
/*******************************************************************/
/* This file contains the main program that reads a graph from a file.
 * There are several different file formats that can be used.
 * The data structures for the graph are constructed.
/*******************************************************************/


/*******************************************************************/
/*
 *	COPYRIGHT (C) 1983  Carl Ebeling and Ofer Zajicek
 *	COPYRIGHT (C) 1988  Carl Ebeling
 *
/*******************************************************************/


/*******************************************************************/
/* HISTORY
 * 28-Jan-83  Carl Ebeling (saffron) at Carnegie-Mellon University
 *	Changed ReadGraph to allocate space for a new name of a graph if
 *	the old one was in error.
/*******************************************************************/

#include "gemini.h"

/****************************************************************/
/* Read device definitions from the file.  There is a definition for each
 * different device.  The format is:
 *     device-type-name  #-of-terminals  terminal-class*
 *
 * Terminals that are functionally identical have the same terminal class
 * (Nothing is now done with the device type name)??
 ****************************************************************/

STATIC void readType(FilePt, aType)
FILE *FilePt;
register DeviceDefinition *aType;
{
  register int i, j;
  char name[20];

  fscanf(FilePt, "%s %d", name, &(aType->numTerminals));
  aType->name = CopyString(name);
  aType->terminals = 
    (termClass *)FastAlloc((unsigned) aType->numTerminals * sizeof(termClass));
  for (i = 0; i < aType->numTerminals; i++) {
    fscanf(FilePt,"%d", &(aType->terminals[i]));
  }
}

/*******************************************************************/
/* A debug routine to print the device types
/*******************************************************************/

void PrintTypes(defs, numDefs)
DeviceDefinition *defs;
int numDefs;
{
  register int i;

  for (i = 0; i < numDefs; i++) { 
    int j;

    printf("Type '%s' (%d):", defs[i].name, i);
    printf(" Number of terminals: %d\n", defs[i].numTerminals);
    printf("	terminal classes: ");
    for (j = 0; j < defs[i].numTerminals; j++) {
	 printf("%d ", defs[i].terminals[j]);
    }
    printf("\n");
  }
}

/*******************************************************************/
/*  Read one node from the file.
 *  nodetype is the type of the nodes it is reading, either DEVICE or NET.
/*******************************************************************/

STATIC short readNode(FilePt, aNode, nodetype, graph)
FILE *FilePt;
register Node  *aNode;
int nodetype;
Graph *graph;			/* Node will be inserted into this graph */
{
  char buffer[BUFSIZE];	/* Name of node */
  unsigned char *line;
  register unsigned char *arg;
  register int i;
  int numlinks;		/* Number of connections to node */
  register int index;

  if ((line = (unsigned char *) fgets(buffer, BUFSIZE, FilePt)) == NULL) {
    fprintf(stderr, "Bad File format: premature EOF\n");
    exit(1);
  }

  aNode->nodeType = nodetype;
  arg = nxtarg(&line, (unsigned char *) " \t");	/* Find name */
  aNode->name = CopyString((char *)arg);

  switch(nodetype) {
  case DEVICE:
    arg = nxtarg(&line, WHITESPACE);/* Find device definition index */
    index = atoi((char *)arg);
    aNode->n.nodeDef = index;
    if ((index >= NumDeviceDefs) || (index < 0)) {  
	 printf("Device index out of range!\n");
	 printf("Index of : %d found in DEVICE %s, device index was: %d\n",
		index, aNode->name, aNode - graph->deviceVector);
	 return(1);
    }
    numlinks = DeviceDefs[index].numTerminals;
    aNode->connects.netList = 
	 (NodePt *) FastAlloc((unsigned) numlinks * sizeof(NodePt));
    for (i=0; i < numlinks; i++) {
	 if (_argbreak == '\n')
	if ((line = (unsigned char *) fgets(buffer, BUFSIZE, FilePt)) == NULL) {
	  fprintf(stderr, "File format error: premature EOF\n");
	  exit (1);
	}
	 arg = nxtarg(&line, WHITESPACE);
	 index = atoi((char *)arg);
	 if ((index >= graph->numNets) || (index < 0)) {  
	printf("Device index to net out of range!\n");
	printf("Index of : %d found in DEVICE %s, device index was: %d\n",
		  index,aNode->name,aNode - graph->deviceVector);
	return(1);
	 }
	 aNode->connects.netList[i] = &(graph->netVector[index]);
    }
    break;

   case NET:
    arg = nxtarg(&line, WHITESPACE);
    numlinks = atoi((char *)arg);
    aNode->n.netConnects = numlinks;
    aNode->connects.devList
	 = (DeviceConnection *) FastAlloc((unsigned) numlinks * sizeof(DeviceConnection));
    for (i=0; i < numlinks; i++) { 
      Node *devNode;
      int devTerminal;

      if (_argbreak == '\n')
	if ((line = (unsigned char *) fgets(buffer, BUFSIZE, FilePt)) == NULL) {
	  fprintf(stderr, "File format error: premature EOF\n");
	  exit (1);
	}
      arg = nxtarg(&line, (unsigned char *) " ,");
      index = atoi((char *)arg);
      arg = nxtarg(&line, WHITESPACE);
      devTerminal = aNode->connects.devList[i].terminal = atoi((char *)arg);
      if ((index >= graph->numDevices) || (index < 0)) {  
	printf("Net index out of range!\n");
	printf("Index of : %d found in NET %s, net index was: %d\n",
		  index,aNode->name,aNode - graph->netVector);
	return(1);
      }
      devNode = 
         aNode->connects.devList[i].node = &(graph->deviceVector[index]);
      aNode->connects.devList[i].class = TerminalList(devNode)[devTerminal];
      assert (devNode != NULL, "Net connected to empty device ")
      if (devNode->connects.netList[devTerminal] != aNode) {
	printf("Net does not match the device\n");
	printf("%s:  ",graph->graphName);
	printf("NET '%s': ", aNode->name);
	printf("Net index: %d\n",aNode - (graph->netVector));
	printf("Connection to device: ");PrintNode(devNode);
	return(1);
      }
    }
    break;
  }
  if (*line != '\n') {
    arg = nxtarg(&line, (unsigned char *) "\n");
/*    aNode->p.property = CopyString(arg); /* This is tech dependent ?? */
  } else aNode->p.property = NULL;

  return (0);
}


void
PrintDevice(node)
Node *node;
{
  register int j;

    if (!strcmp(DeviceDefs[node->n.nodeDef].name, "n") ||
	!strcmp(DeviceDefs[node->n.nodeDef].name, "p")) {
      printf("(index %d) [g] %s", node->SimIndex,
	node->connects.netList[3]->name);
      for (j = 4; j < NumberOfLinksD(node); j++) {
        printf(", %s", node->connects.netList[j]->name);
      }
      if (TerminalList(node)[2] == SUBSTRATE) {
        printf(" :: [s,d,sub] %s, %s, %s\n",
	  node->connects.netList[0]->name,
	  node->connects.netList[1]->name,
	  node->connects.netList[2]->name);
      } else {
        printf(" :: [s,d] %s, %s\n",
	  node->connects.netList[0]->name,
	  node->connects.netList[1]->name);
      }
    } else {
      for (j = 0; j < NumberOfLinksD(node); j++)
	printf(" %s,", node->connects.netList[j]->name);
      printf("\n");
    }
}

/*******************************************************************/
/* Print a node
/*******************************************************************/

void PrintNode(node)
register Node *node;
{
  register int i;

  assert( node != NULL, "Empty node to PrintNode" );
  switch (node->nodeType) {
  case DEVICE:
    if (!strcmp(DeviceDefs[node->n.nodeDef].name, "")) {
      fprintf(stderr,
"Fatal internal error in PrintNode: device has empty string for name\n");
      longjmp(env,1);
    }
    printf("DEVICE %s: ", DeviceDefs[node->n.nodeDef].name); 
    fflush(stdout);
    if ((node->name[0] != '*') || (node->name[1] != '\0'))
      printf("\"%s\" ", node->name);
    if (Verbose) {
      if (node->p.property != NULL) {
	printf("Prop: [%d,%d] (%d,%d), ",
	  node->p.property->length, node->p.property->width,
	  node->p.property->xLoc, node->p.property->yLoc);
      }
      printf("[%d,%d", node->nodeValue, node->pass);
      switch (node->flag) {
        case UNIQUE: 	printf(" UNIQUE");	break;
        case SUSPECT:	printf(" SUSPECT");	break;
        case BAD:	printf(" BAD");		break;
        default:	printf(" PENDING");	break;
      }
      printf("]\n");
    }
    printf("    connections: ");
    PrintDevice(node);
    break;

  case NET:
    printf("NET ");
    if ((node->name[0] != '*') || (node->name[1] != '\0'))
      printf("\"%s\" (index %d)", node->name, node->SimIndex);
    if (Verbose) {
      printf("[%d,%d,", node->nodeValue, node->pass);
      switch (node->flag) {
	case UNIQUE: 	printf(" UNIQUE"); break;
	case SUSPECT: 	printf(" SUSPECT"); break;
	case BAD:	printf(" BAD"); break;
	default:	printf(" PENDING");
      }
      printf("]");
    }
    printf(" %d connections\n", node->n.netConnects);
    if (node->n.netConnects <= NetPrintLimit) {
      for (i = 0; i < node->n.netConnects; i++) {
	register Node *nNode = node->connects.devList[i].node;
	printf("  %s: ", DeviceDefs[nNode->n.nodeDef].name);
	PrintDevice(nNode);
      }
    }
    break;
  }
}

/*******************************************************************/
/* Print a vector of nodes
/*******************************************************************/

void PrintNodes(nodes, numNodes)
register Node *nodes;
register int numNodes;
{
  register int i;

  for (i = 0; i < numNodes; i++)
	PrintNode(&nodes[i]);
}
/*******************************************************************/
/* Print the neighbors of a node
/*******************************************************************/

void PrintNodeNeighbors(node)
register Node* node;
{ 
  register int i;

  switch (node->nodeType)
    {
	 case DEVICE:
	for (i = 0; i < NumberOfLinksD(node); i++)
		PrintNode(node->connects.netList[i]);
	break;

	 case NET:
	for (i = 0; i < node->n.netConnects; i++) 
	   PrintNode(node->connects.devList[i].node);
   }      	
}

/*******************************************************************/
/*  Initialize by reading a graph from a file.
 *  File format:
 *  # of device types
 *    device definitions (# connects, (connect type)*)
 *  # of devices , # of nets
 *    devices (device type, connections*) (device/terminal??)
 *    nets (# connects, connections*)
/*******************************************************************/

void ReadGraph(graph, simFormat)
register Graph *graph;
char simFormat;
{
  FILE *infilePT = NULL;

  if ((infilePT = fopen(graph->graphName, "r")) == NULL) {
    fprintf(stderr, "Fatal error: cannot open '%s'\n", graph->graphName);
    longjmp(env,1);
  }
  printf("\nGraph \"%s\": ", graph->graphName);
  if (simFormat != GEM) {
    ReadSimFormat(infilePT, graph);
  } else {
    ReadGemFormat(infilePT, graph);
  }

  ClearQueue(&graph->newUniques);
  ClearQueue(&graph->nextEvalQueue);
  ClearQueue(&graph->uniqueDevices);
  ClearQueue(&graph->uniqueNets);

/*
** Don't count hidden net 'No connect'
*/
/*  printf("\tNumber of device types: %d\n", NumDeviceDefs); */
  printf("\tNumber of devices: %d\n", graph->numDevices);
  printf("\tNumber of nets: %d\n",
    (graph->SimFormat) == LBL ? graph->numNets : graph->numNets - 1);
  fflush(stdout);
  fclose(infilePT);
}

/*******************************************************************/
/*
 *	Read a file in gemini format
 *
/*******************************************************************/

void ReadGemFormat(infilePT, graph)
FILE *infilePT;
Graph *graph;
{	/*    Read a file in Gemini format.	*/
  register int i;
  fscanf(infilePT, "%d", &NumDeviceDefs);
  DeviceDefs = (DeviceDefinition *) 
		FastAlloc((unsigned) MAXDEVICETYPES*sizeof(DeviceDefinition));
  for (i=0;i<NumDeviceDefs;i++)
    { readType(infilePT,&DeviceDefs[i]); }
  debug(INPUT, PrintTypes(DeviceDefs, NumDeviceDefs); )

  fscanf(infilePT, "%d %d\n", &graph->numDevices, &graph->numNets);
  graph->deviceVector = (Node *) 
    malloc((unsigned) graph->numDevices * sizeof(Node));
  graph->numPendingDevices = graph->numDevices;
  graph->pendingDevices = (NodePt *)
    malloc((unsigned) graph->numDevices * sizeof(NodePt));
  ClearQueue(&graph->devices);
  graph->netVector = (Node *) malloc((unsigned) graph->numNets * sizeof(Node));
  graph->numPendingNets = graph->numNets;
  graph->pendingNets = (NodePt *) 
    malloc((unsigned) graph->numNets * sizeof(NodePt));
  ClearQueue(&graph->nets);

/* Read all the Devices
 */
  for (i = 0; i < graph->numDevices; i++) { 
    if ( readNode(infilePT, &(graph->deviceVector[i]), DEVICE, graph) ) { 
      fprintf(stderr,"Fatal input error reading a node, cannot recover\n");
      longjmp(env,1);
    }
    graph->pendingDevices[i] = &(graph->deviceVector[i]);
  }

/*  Read all the Nets
 */
  for (i = 0; i < graph->numNets; i++) { 
    if ( readNode(infilePT, &(graph->netVector[i]), NET, graph)) { 
      fprintf(stderr,"Fatal input error reading a node, cannot recover\n");
      longjmp(env,1);
    }
    graph->pendingNets[i] = &(graph->netVector[i]);
  }

  debug(INPUT,
    PrintNodes(graph->deviceVector, graph->numDevices);
    printf("\n");
    PrintNodes(graph->netVector, graph->numNets);
  )
}

/*******************************************************************/
/* Print out an entire Queue
/*******************************************************************/

void PrintQueue(queue)
Queue *queue;
{
Node *nodePt;

  for( nodePt = queue->top; nodePt != NULL; nodePt = nodePt->next) {
	PrintNode(nodePt);
  }
}
