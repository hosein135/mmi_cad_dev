/*
$Id: simread.c,v 2.7.2.1 1994/03/16 04:32:41 mckenzie Exp mckenzie $
*/
/*******************************************************************/
/*
 *	COPYRIGHT (C) 1983  Carl Ebeling and Ofer Zajicek
 *	COPYRIGHT (C) 1988  Carl Ebeling
 *
/*******************************************************************/

/*******************************************************************/
/* This program converts from SIM format to gemini format
 * sim:		[e/d] net1-name net2-name net3-name property
 *		= net1-name net2-name
 *
 * gemini:	type-index dev-name property (net-# . . .)
 *		net-name net-connections (dev-#,term-# . . .)
 *
/*******************************************************************/

/*******************************************************************/
/*
 * HISTORY
 *
 * Modified 1/22/89 by Martin Harriman; fingers may fold (see
 *   fingers.c, gemini.c).
 *
/*******************************************************************/

#include "gemini.h"
#include <sys/types.h>
#include <sys/stat.h>
static char spaces[256] = { 0 };   /* Break character table */
Net *no_connect_net;

/*******************************************************************/
/*
 *	Read a file in SIM format
 *
/*******************************************************************/

void ReadSimFormat(infilePT, graph)
FILE *infilePT;
register Graph *graph;
{
  Device *devices;
  Net *nets;
  register int i;
  register int count;

  spaces[' '] = spaces['\t'] = spaces['\n'] = 1;
  debug (SIMFORMAT,
	printf("Reading file in SIM format\n"); )
  graph->SimUnits = 1.0;
  /* SIMSetDeviceDefs();	*/	/* Initialize device types */
  ReadSimFile(infilePT, graph, &devices, &nets);
  debug( INPUT, 
	printf("Number of devices: %d, number of nets: %d\n", 
	  graph->numDevices, graph->numNets); )
  graph->deviceVector = 
    (Node *) malloc((unsigned) graph->numDevices * sizeof(Node));
  if (graph->deviceVector == NULL) {
    fprintf(stderr, "Not enough space for malloc\n");
    exit(1);
  }
  ClearQueue(&graph->devices);
  graph->netVector = (Node *) malloc((unsigned) graph->numNets * sizeof(Node));
  if (graph->netVector == NULL) {
    fprintf(stderr, "Not enough space for malloc\n");
    exit(1);
  }
  ClearQueue(&graph->nets);
  SIMSetDevices(graph, devices);
  SIMSetNets(graph, nets);

  debug( INPUT, PrintAllDevices(); );

/* Get rid of nodes that are not used */
  { int flag = 0;

    for (i = 0; i < graph->numNets; i++) {
      if (NumberOfLinksN(&graph->netVector[i]) == 0) {
	if (PrintZeroNets) {
	  if (flag == 0) {
	    printf("Ignoring the following nets which have no connections\n");
	    flag++;
	  }
	  printf("\t%s\n", graph->netVector[i].name);
	}
	DeleteNet(graph, &graph->netVector[i]);
	i--;	/* Sleazy hack: the current net is replaced by deleteNet */
      }
    }
  }

  if (FoldFingers)
    CombineFingers(graph);

/* Find transistor chains and combine into single devices: this will create
 * new types and reduce the number of devices and nets
 */
  if (CollapseChains) FindChains(graph);

/* Now put all devices and nets into the pending arrays */
  graph->pendingDevices = 
	  (NodePt *) malloc((unsigned) graph->numDevices * sizeof(NodePt));
  count = 0;
  for (i = 0; i < graph->numDevices; i++) {
    if (graph->deviceVector[i].flag == DELETED) continue;
    graph->pendingDevices[count++] = &graph->deviceVector[i];
  }
  graph->numDevices =
    graph->numPendingDevices = count;	/* Exclude DELETED nodes */

  graph->numPendingNets = graph->numNets;
  graph->pendingNets = 
		(NodePt *) malloc((unsigned) graph->numNets * sizeof(NodePt));
  for (i = 0; i < graph->numNets; i++) {
    graph->pendingNets[i] = &graph->netVector[i];
  }

  debug(INPUT, PrintTypes(DeviceDefs, NumDeviceDefs); )
  debug(INPUT,
    PrintGraphStats(graph);
    printf("Device vector\n");
    PrintNodes(graph->deviceVector, graph->numDevices);
    printf("Net vector\n");
    PrintNodes(graph->netVector, graph->numNets);
  )
}

STATIC void SIMSetDeviceDefs(simFormat) /* LBL 11/29/93 added parameter */
char simFormat;
{
  register int i;

  if (NumDeviceDefs) return;	/* Only do this once!! */
  NumDeviceDefs = NUMBERTYPES;
  DeviceDefs = (DeviceDefinition *)
    FastAlloc((unsigned) MAXDEVICETYPES*sizeof(DeviceDefinition));
  for (i = 0; i < NumDeviceDefs; i++) {
    switch (i) {
    case PTYPE:	
      DeviceDefs[i].name = CopyString("p");
      break;
    case NTYPE:
      DeviceDefs[i].name = CopyString("n");
      break;
    }
    DeviceDefs[i].numTerminals = 4;
    DeviceDefs[i].terminals = (termClass *)
      FastAlloc((unsigned) DeviceDefs[i].numTerminals * sizeof(termClass));
    DeviceDefs[i].terminals[0] = DRAIN;
    DeviceDefs[i].terminals[1] = DRAIN;
    DeviceDefs[i].terminals[3] = GATE;
    if (simFormat == LBL) {
      DeviceDefs[i].terminals[2] = SUBSTRATE;
    } else {
      DeviceDefs[i].terminals[2] = NO_CONNECTION;
    }
  }
}

STATIC void SIMSetDevices(graph, devices)
register Graph *graph;
register Device *devices;
{	/* SIMSetDevices	*/
  register int deviceIndex,i;

  Node *node;
  int numlinks;

  deviceIndex = -1;
  while (devices != NULL) {
    deviceIndex++;
    node = &graph->deviceVector[deviceIndex];
    node->nodeType = DEVICE;
    node->n.nodeDef = devices->type;
    node->name = "*";
    node->SimIndex = deviceIndex;

    assert( ((devices->index < graph->numDevices) && devices->type >= 0),
    "Device index out of range!\nInternal problem reading SIM format\n")
/* fprintf(stderr, "index=%x, numDevices=%x\n",
   devices->index, graph->numDevices);
 */
    numlinks = DeviceDefs[devices->type].numTerminals;
    node->connects.netList = 
      (NodePt *) FastAlloc((unsigned) numlinks * sizeof(NodePt));
    for (i=0; i<numlinks; i++) { 
      node->connects.netList[i] = 
	&(graph->netVector[IndexOfNet(devices->connections[i])]);
    }
    node->p.property = devices->property;
    devices = devices->next; 
  }
}

STATIC void SIMSetNets(graph, nets)
Graph *graph;
register Net *nets;
{
  register SIMdevConnect *conP;
  register int netIndex;
  register Node *node;
  int numlinks;
  int i;

  netIndex = -1;
  while (nets != NULL) {
    if (nets->numConnects >= 0) {
      netIndex++;
      node = &graph->netVector[netIndex];
      node->nodeType = NET;
      node->name = nets->name;
      numlinks = nets->numConnects;
      node->n.netConnects = numlinks;
      node->p.netprop = nets->np;
      node->SimIndex = netIndex;
      debug(INPUT,
         printf("NET:%20s, number of links: %4d, capacitance = %5ld\n",
	   node->name, numlinks, node->p.netprop->capacitance);
         )
      node->connects.devList = (DeviceConnection *)
      FastAlloc((unsigned) numlinks * sizeof(DeviceConnection));
      conP = nets->connections.list;
      for (i=0; i < numlinks; i++) { 
	Node *devNode;
	int devTerminal;

	devTerminal = node->connects.devList[i].terminal = conP->terminal;
	devNode = node->connects.devList[i].node = 
	  &graph->deviceVector[conP->dev];
	node->connects.devList[i].class = TerminalList(devNode)[devTerminal];
	conP = conP->next;
      }
      nets = nets->nextInOrder;
    } else if (nets->numConnects < 0) {
/*      printf("Aliased net: %s\n", nets->name);*/
      nets = nets->nextInOrder; 
      continue;			/* Aliased net: ignore */
    }
  }
}


void ReadSimFile(infile, graph, devices, nets)
Graph *graph;
Device **devices;
Net **nets;
FILE *infile;			/* Input file pointer */
{
  char buffer[BUFSIZE];
  register unsigned char *line;
  register unsigned char *arg;
  unsigned char *aline;
  int lineNumber = 0;

  int devIndex;
  extern int NetIndex;

  register Net *net;		/* 4 connections for each device */
  Net *gateNet;			/* gate of cmos transistor */
  Device *device;
  int deviceType;
  register int i;
  struct stat statbuf;

  char SimFormatFlag;

/*  DebugLevel = "";	*/

  if (fstat(fileno(infile), &statbuf) < 0) {
    fprintf(stderr, "Fstat failed\n");
    exit(0);
  }
/*  printf("File size = %d\n", statbuf.st_size);*/
  InitHash(statbuf.st_size/80 + 1);	/* 80 chars per net?? */
  InitNets();

  devIndex = 0;
  SimFormatFlag = FALSE;
  graph->SimFormat = MIT; /* Assume MIT, may change later */

  while ((line = (unsigned char *) fgets(buffer, BUFSIZE, infile)) != NULL) {

    /* Pass 1: Read next line */
    lineNumber++;
/*    arg = nxtarg(&line, WHITESPACE);*/
    while (spaces[*line]) line++;
    arg = line++;
    deviceType = -1;
    if (!spaces[arg[1]]) {	/* try to match user defined type */
      if (devIndex == 0) {
        SIMSetDeviceDefs(graph->SimFormat);
      }
      MatchUserDef(arg, lineNumber, &devIndex);
      continue;
    } else {
      switch (*arg) {
      case 'e':	/* enhancement */
      case 'n':
        deviceType = NTYPE;
        break;
      case 'd':   /* depletion (NMOS anachronism) */
      case 'p':
        deviceType = PTYPE;
        break;
      }
    }
    if (deviceType != -1) {
      if (devIndex == 0) {
        SIMSetDeviceDefs(graph->SimFormat);
      }
      device = NewDevice(devIndex, deviceType, 4);
      AddDevice(device);

/*
** Sim file format: gate, drain, drain, substrate
** Internal format: drain, drain, substrate, gate
** Therefore rotate left by using i%4 (goes 3,0,1,2)
*/
      for (i = 3; i < 7; i++) {
	int indx = i%4;
	register SIMdevConnect *connect;

/*
** if LBL format, process substrate connection
** otherwise just declare substrate net to be "no_connect_net"
*/
	if ((indx == 2) && (graph->SimFormat != LBL)) {
	    net = FindOrAllocNet(NO_CONNECT_NAME);
	} else {
	    nextarg(); argerror();
	    net = FindOrAllocNet((char *) arg);
	}
	device->connections[indx] = net;
/*	AddConnection(net, devIndex, i%4);*/

	while (net->index == -1) {
	  net = net->connections.equalNet;
	}
	if (i == 3) {
	  gateNet = net;
	}

	connect = NewConnection();
	connect->dev = devIndex;
	connect->terminal = indx;
	connect->next = net->connections.list;
	net->connections.list = connect;
	net->numConnects++;
      }

      device->property = NULL;
      if (PrintWarnings || (MagicFilePtr != NULL)) {
	if (graph->SimFormat == GEM) {
	  fprintf(stderr,
	    "SIM file format not recognized: -w and -M options ignored\n");
	  PrintWarnings = FALSE;
	  MagicFilePtr = NULL;
	} else {
	  device->property = AllocProperty();
	  device->property->gatenet = gateNet;
	  nextarg(); argerror();
	  device->property->length = atoi((char *)arg) * graph->SimUnits;
	  nextarg(); argerror();
	  device->property->width = atoi((char *)arg) * graph->SimUnits;
	  if (graph->SimFormat == MIT) {
	    /* No location information */
	  } else if (graph->SimFormat == UCB || graph->SimFormat == LBL) {
	    nextarg(); argerror();
	    device->property->xLoc = atoi((char *)arg) * graph->SimUnits;
	    nextarg(); argerror();
	    device->property->yLoc = atoi((char *)arg) * graph->SimUnits;
	  }
	}
      }
      devIndex++;
    } else {			/* Not a device line */
      switch (*arg) {
      case '|':		/* First line of file: look for units */
	if (devIndex != 0) {
	  fprintf(stderr, "Format line not on first line of SIM file\n");
	} else {
	  SimFormatFlag = TRUE;
	  aline = line;
	  arg = nxtarg(&aline, WHITESPACE);
	  if (strcasecmp((char *)arg, "units:") == 0) {
	    arg = nxtarg(&aline, WHITESPACE);
	    graph->SimUnits = atof((char *)arg);
	    printf("unit scale = %g, ", graph->SimUnits);
	    arg = nxtarg(&aline, WHITESPACE);
	  }
	  while (TRUE) {
	    if (*arg == '\0') {
	      printf("format = NULL (assume MIT)\n");
	      break;
	    }
	    if (!strcasecmp((char *)arg, "format:")) {
	      arg = nxtarg(&aline, WHITESPACE);
	      if (!strcasecmp((char *)arg, "ucb")) {
	        graph->SimFormat = UCB;
	      } else if (!strcasecmp((char *)arg, "lbl")) {
	        graph->SimFormat = LBL; /* LBL 11/22/93 added 4th terminal */
	      } else if (!strcasecmp((char *)arg, "mit")) {
	        graph->SimFormat = MIT; /* redundant, adds readability */
	      } else {
	        printf("format '%s' is unknown (assume MIT)\n", arg);
		break;
	      }
	      printf("format = %s\n", arg);
	      break;
	    }
	    arg = nxtarg(&aline, WHITESPACE);
	  }
	}
	continue;

      case '=':
	{ Net *net1, *net2;

	  aline = line;
	  arg = nxtarg(&aline, WHITESPACE);
	  net1 = FindOrAllocNet((char *) arg);
	  while (*(arg = nxtarg(&aline, WHITESPACE)) != '\0') {
	    net2 = FindOrAllocNet((char *) arg);
	    EquateNets(graph, net1, net2);
	  }
	}
	continue;

/* Allocate nets that appear as capacitances */
      case 'N':			/* Some bogon writes Node lines */
      case 'L':			/* Berkeley Node lines */
      case 'c':			/* non-mextra capacitor lines */
	aline = line;
	arg = nxtarg(&aline, WHITESPACE);
	FindOrAllocNet((char *) arg);	/* Just make sure net exists */
        continue;

/*
** Mextra capacitor lines
** Assumed format:
** C netname GND xx.yyyyyy
** Bad format may generate fatal errors
** Float value converted to a long (scaled up by 1000)
** NM 8-3-1992
*/
      case 'C':
	aline = line;
	arg = nxtarg(&aline, WHITESPACE);
	if (!strcasecmp("gnd",(char *)arg)) {
	  continue;		/* ignore caps between GND & GND */
	  			/* print warning? */
	}
	net = FindOrAllocNet((char *) arg);
	arg = nxtarg(&aline, WHITESPACE);
	assert (!strcasecmp("gnd",(char *)arg),
	  "GND missing in third column in capacitor entry");
	arg = nxtarg(&aline, WHITESPACE);
	net->np->capacitance += labs ((long) (1000L * atof((char *) arg)));
        continue;

      case 'v':			/* COSMOS vector lines */
      case 'A':			/* COSMOS attribute lines */
      case 'B':			/* COSMOS attribute lines */
      case 'R':			/* Magic resistor lines */
      case ';':
      case '\n':
      case '\0':
	continue;		/* Ignore null lines */

      default:
	fprintf(stderr, "Format error line: %d\n", lineNumber);
	break;
      }
    }

    if ((devIndex != 0) && (SimFormatFlag == FALSE)) {
	printf("format line was omitted (assume MIT)\n");
	SimFormatFlag = TRUE;
    }
  }

/************************************************************************/
/* Read the aliased file if any (standard for .sim files)
/************************************************************************/
  { char aliasName[256];
    FILE *aliasFile;
    char *cp1, *cp2, *rp;

    rp = NULL;
    cp1 = aliasName;
    cp2 = graph->graphName;
    while (*cp1++ = *cp2++) {
	if (*(cp1-1) == '.') rp = cp1;
    }
    if (rp) {
      *rp++ = 'a';
      *rp++ = 'l';
      *rp++ = '\0';
      if ((aliasFile = fopen(aliasName, "r")) != NULL) {
	printf("Reading alias file \"%s\"\n", aliasName);
	while ((aline =
	  (unsigned char *) fgets(buffer, BUFSIZE, aliasFile)) != NULL) {
	  arg = nxtarg(&aline, WHITESPACE);
	  switch (*arg) {
	  case '=': {
	      Net *net1, *net2;

              arg = nxtarg(&aline, WHITESPACE);
              net1 = FindOrAllocNet((char *) arg);
	      while (*(arg = nxtarg(&aline, WHITESPACE)) != '\0') {
		net2 = FindOrAllocNet((char *) arg);
		EquateNets(graph, net1, net2);
	      }
	    }
	    break;

	  case '|':
	  case ';':
	  case '\n':
	  case '\0':
	    continue;		/* Ignore null lines */

	  default:
	    fprintf(stderr, "Format error in alias file\n");
	    continue;
	  }
	}
      }
    }
  }

/* An efficient way to get around the problem of differing capitalization 
 * of Vdd and GND */
  { 
    Net *gnds[7], *vdds[7];
    Net *tmp = NULL;

    gnds[0] = FindNet("gND");
    gnds[1] = FindNet("GND");
    gnds[2] = FindNet("gnd");
    gnds[3] = FindNet("Gnd");
    gnds[4] = FindNet("gNd");
    gnds[5] = FindNet("gnD");
    gnds[6] = FindNet("GNd");

    vdds[0] = FindNet("Vdd");
    vdds[1] = FindNet("vdd");
    vdds[2] = FindNet("vDd");
    vdds[3] = FindNet("vdD");
    vdds[4] = FindNet("VDd");
    vdds[5] = FindNet("vDD");
    vdds[6] = FindNet("VDD");

    for (i = 0; i < 7; i++) {
      if (tmp != NULL) {
	if (gnds[i] != NULL)
	  EquateNets(graph, tmp, gnds[i]);
      } else if (gnds[i] != NULL)
	tmp = gnds[i];
    }
    tmp = NULL;
    for (i = 0; i < 7; i++) {
      if (tmp != NULL) {
	if (vdds[i] != NULL)
	  EquateNets(graph, tmp, vdds[i]);
      } else if (vdds[i] != NULL)
	tmp = vdds[i];
    }
  }
  graph->numDevices = devIndex;
  graph->numNets = NetIndex;
  GetNodes(devices, nets);
}
