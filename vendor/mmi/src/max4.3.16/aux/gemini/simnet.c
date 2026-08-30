/*
$Id: simnet.c,v 2.7 1993/12/17 04:49:32 mckenzie Exp mckenzie $
*/
/*******************************************************************/
/* This file maintains the hash table used to keep track of net names
 * These routines are used by the procedures that read SIM format files.
/*******************************************************************/

/*******************************************************************/
/*
 *	COPYRIGHT (C) 1983  Carl Ebeling and Ofer Zajicek
 *	COPYRIGHT (C) 1988  Carl Ebeling
 *
/*******************************************************************/

/*******************************************************************/
/*
 * HISTORY
 *
/*******************************************************************/

#include "gemini.h"
#include <ctype.h>
 
/*******************************************************************/
/* Queue of nets in order of allocation: used for printing nets at end */
/*******************************************************************/

static Net *firstNet = NULL, *lastNet = NULL;
static Device *firstDevice = NULL, *lastDevice = NULL;
int NetIndex = 0;

static Net **hashTable;
static int hashSize;

/*******************************************************************/
/*	Initialize the nets and devices
/*******************************************************************/

void InitNets()
{ 
  firstNet = lastNet = NULL;
  firstDevice = lastDevice = NULL;
  NetIndex = 0;
}

/*******************************************************************/
/* Allocate a hash table with the appropriate size
/*******************************************************************/

void InitHash(size)
register int size;
{
/* If the table has been already allocated, just reuse on the assumption it 
   has about the right size */

  if (hashTable == NULL) {
    hashTable = (Net **) malloc((unsigned) size * sizeof(Net *));
    hashSize = size;
  }
  size = hashSize;
  while (size) {
    hashTable[--size] = NULL;
  }
}
/*
STATIC unsigned int simhash(name)
register char *name;
{
  register int value = 0;

  if (CaseFold) {
    while (*name) {
      value = (value << 1) + pCharTran[*name++];
    }
  } else {
    while (*name) value = (value + 337351) * *name++;
  }
  return (((unsigned int) value) % hashSize);
}
*/

/*******************************************************************/
/* Keep track of net indices.  When two nets are equated, all of the indices
 * of the nets following in order are pushed up (decremented) to fill in the
 * gap.
/*******************************************************************/

STATIC void popUpIndex(net)
Net *net;
{
  register Net *p;

  for (p = net; p != NULL; p = p->nextInOrder) {
    if (p->index == 0) {
      fprintf(stderr,
    "Fatal internal error: changing net index from 0 to -1\n");
      fprintf(stderr,
    "Send bug report to Gemini maintainer (mckenzie@cs.washington.edu)\n");
      longjmp(env,1);
    }
    if (p->index > 0) {
      p->index--;
    }
  }
  NetIndex--;
}

/*******************************************************************/
/* Returns the net, with non negative index that 
 * this net is equated to
/*******************************************************************/

Net *RealNet(net)
Net *net;
{
  assert (net != NULL, "RealNet, Null Net passed.  FATAL!!!");
  while (net->index == -1) {
    net = net->connections.equalNet;
  }
  return net;
}

#define newIndex() NetIndex++

/************************************************************************/
/* FindNet finds the named net in the hashtable and returns in.  NULL is
 * returned if not found
/************************************************************************/

Net *FindNet(name)
register char *name;
{
  register int hashValue;
  register Net *netP;
  
  simhash(name, hashValue);
/*  debug(SIMFORMAT, printf("FindNet: %s", name); ) */
  for (netP = hashTable[hashValue]; netP != NULL; netP = netP->next) {
      if ((*Streq)(netP->name, name)) {    /* Optimize?? */
/*	debug(SIMFORMAT, printf(" - found\n");)*/
	while (netP->index == -1) {
	  netP = netP->connections.equalNet;
	}
	return netP;
/*	 return RealNet(netP);*/
      }
    }
  return NULL;
}

/*******************************************************************/
/* FindOrAllocNet finds the named net in the hashtable and returns the Net.
 * If the name is not found, then one is allocated and assigned a new index
 * Aliased names are always dealiased first.
/*******************************************************************/

Net *FindOrAllocNet(name)
register char *name;		/* either char * or uchar * */
{
  register int hashValue;
  register Net *netP;
  
  netP = FindNet(name);
  if (netP == NULL) {
    netP = NewNet(name, newIndex());
    simhash(name, hashValue);
    netP->next = hashTable[hashValue];
    hashTable[hashValue] = netP;
    if (firstNet == NULL) {
      firstNet = lastNet = netP;
    } else {
      lastNet->nextInOrder = netP;
      lastNet = netP;
    }
    debug(SIMFORMAT, printf("Index of %20s is %d\n", name, netP->index); )
  }
  return netP;
}

/*******************************************************************/
/* add a device to the linked list of devices;
/*******************************************************************/

void AddDevice(device)
Device *device;
{
  if (firstDevice == NULL) {
    firstDevice = lastDevice = device;
  } else {
    lastDevice->next = device; 
    lastDevice = device;
  }
}

/*******************************************************************/
/* Add a connections to a net: If the Net is equated to another, then add
 * the connection to that net.
/*******************************************************************/
/*
AddConnection(net, devIndex, terminal)
register Net *net;
int devIndex, terminal;
{
  register SIMdevConnect *connect = NewConnection();

  while (net->index == -1) {
    net = net->connections.equalNet;
  }
  connect->dev = devIndex;
  connect->terminal = terminal;
  connect->next = net->connections.list;
  net->connections.list = connect;
  net->numConnects++;
}
*/

/*******************************************************************/
/*  Returns a pointer to the first device and the first net
 *  in the list.
/*******************************************************************/

void GetNodes(devices, nets)
Device **devices;
Net **nets;
{ 
  *devices = firstDevice;
  *nets = firstNet;
}

/*******************************************************************/
/* Print all the nets in the hash table
/*******************************************************************/

void PrintAllNets()
{
  register Net *netP;
  register SIMdevConnect *conP;
  register int count;
  
  for (netP = firstNet; netP != NULL; netP = netP->nextInOrder) {
    if (netP->index >= 0) { /* Only print non-equal nets */
      printf("%s	%d", netP->name, netP->numConnects);
      count = 0;
      for (conP = netP->connections.list; conP != NULL; conP = conP->next) {
	if (count++ >= 7) {
	  printf("\n"); count = 0;
	}
	printf("	%d,%d", conP->dev, conP->terminal);
      }
      printf("\n");
    }
  }
}

/*******************************************************************/
/* Equate two nets:  The index of one of the nets may have to be reused
 * On return, each net will either be aliased to a non-aliased net OR will
 * be a normal net and not aliased at all.
/*******************************************************************/

void EquateNets(graph, net1, net2)
Graph *graph;
register Net *net1, *net2;
{
/*******************************************************************/
/* Make sure first that the nets are distinct
/*******************************************************************/

/*  printf("Equating %s = %s\n", net1->name, net2->name); */
  if (net1 == net2)  return;

/*******************************************************************/
/* Check first if nets are already aliased and find root net
/*******************************************************************/
  while (net1->index == -1) {
    net1 = net1->connections.equalNet;
  }
  while (net2->index == -1) {
    net2 = net2->connections.equalNet;
  }

/************************************************************************/
/* If the eq file refers to one of the equate names, make sure we keep that
 * one since it will be the one the user wants to see
/************************************************************************/
   if (FindEqName(net2->name, graph->graphNumber)) {
     Net *tmp = net1;		/* Interchange nets */
     net1 = net2;
     net2 = tmp;
   }

/*******************************************************************/
/* Alias the second net to the first net
/*******************************************************************/

  if (net2->connections.list == NULL) {
    net1->np->capacitance += net2->np->capacitance;
  } else {
    register SIMdevConnect *conP;
    register Net *tmp;
    if (net1->connections.list == NULL) {
      net1->connections.list = net2->connections.list;
      net1->numConnects = net2->numConnects;
      net1->np->capacitance += net2->np->capacitance;
    } else {
      for (conP = net1->connections.list; /* Find end of list */
      conP->next != NULL; conP = conP->next) ;
      conP->next = net2->connections.list; /* Append net connections */
      net1->numConnects += net2->numConnects;
      net1->np->capacitance += net2->np->capacitance;
    }
  }
  net2->np->capacitance = 0;
  net2->numConnects = -1;
  net2->connections.equalNet = net1; /* Attach alias */
  popUpIndex(net2);
  net2->index = -1;
}

#ifdef DELETE
    } else if (net1->connections.list == NULL) {
      net1->numConnects = -1;
      net1->connections.equalNet = net2;
      popUpIndex(net1);
      net1->index = -1;
    } else {
/* Add the connections of the higher indexed net to the lower indexed one.*/
      register SIMdevConnect *conP;
      register Net *tmp;
      if (net1->index > net2->index) {
	tmp = net1;
	net1 = net2;
	net2 = tmp;
      }
      for (conP = net1->connections.list;
	   conP->next != NULL; conP = conP->next) ;
      conP->next = net2->connections.list;
      net1->numConnects += net2->numConnects;
      net2->numConnects = -1;
      net2->connections.equalNet = net1;
      popUpIndex(net2);
      net2->index = -1;
    }
}
#endif /* DELETE */

/*******************************************************************/
/*  Print all the devices
/*******************************************************************/

void PrintAllDevices()
{
  register Device *device;
  register int i;
  char *line;
  char *arg;
    
  for (device = firstDevice; device != NULL; device = device->next) {
    printf("*	%d", device->type);
    for (i = 0; i < DeviceDefs[device->type].numTerminals; i++) {
      printf("	%d", IndexOfNet(device->connections[i]));
    }

#if 0
    if (! noProp) {
      double number;
      double atof();

      line = device->p.property;
      arg = nxtarg(&line, " \n\t");
      number = atof(arg);
      printf("	%.1f", number);
      arg = nxtarg(&line, " \n\t");
      number = atof(arg);
      printf(" %.1f", number);
    }
#endif

    printf("\n");
  }
}
