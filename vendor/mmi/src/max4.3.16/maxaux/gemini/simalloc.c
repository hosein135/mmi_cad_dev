/*
$Id: simalloc.c,v 2.7 1993/12/17 04:49:32 mckenzie Exp mckenzie $
*/
/*******************************************************************/
/* This file contains the allocation routines for the routines that
 * read SIM format files
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

/*******************************************************************/
/* Allocate a Net
/*******************************************************************/

static Net *netBuffer = NULL;
static int netCount = 0;
#define NET_INCREMENT 256

Net *NewNet(name, index)
register char *name;
register int index;
{
register Net *result;

  if (netCount <= 0) {
    netBuffer = (Net *) malloc((unsigned) NET_INCREMENT * sizeof(Net));
    if (netBuffer == NULL) {
      fprintf(stderr, "NewNet unable to allocate sufficient memory\n");
      exit(1);
    }
    netCount = NET_INCREMENT;
  }

  result = netBuffer++;
  netCount--;
  result->name = CopyString(name);
  result->index = index;
  result->numConnects = 0;
  result->connections.list = NULL;
  result->next = NULL;
  result->nextInOrder = NULL;
  result->np = (NetProp *) FastAlloc(sizeof(NetProp));
  result->np->capacitance = 0;
  return result;
}

/*******************************************************************/
/* Allocate a Device
/*******************************************************************/

Device *NewDevice(index, deviceType, numpins)
register int index;
register int deviceType;
int numpins;
{
register Device *result;
register int i;

/*
** to accomodate user-defined devices with more than 4 terminals,
** allocate extra space for pointers (one pointer per terminal)
** Assume there are always at least 4 terminals.
*/
  if (numpins < 4) numpins = 4; 
  result = (Device *) malloc(sizeof(Device) + (sizeof(void *) * (numpins-4)));
  if (result == NULL) {
    fprintf(stderr, "NewDevice unable to allocate sufficient memory\n");
    exit(1);
  }
  result->index = index;
  result->type = deviceType;
  result->property = NULL;
  result->next = NULL;
  for (i=0; i<numpins; i++)
    result->connections[i] = NULL;
  return result;
}

/*******************************************************************/
/* Allocate a SIMdevConnect
/*******************************************************************/

static SIMdevConnect *conBuffer = NULL;
static int conCount = 0;

#define CON_INCREMENT 256

SIMdevConnect *NewConnection()
{
  register SIMdevConnect *result;

  if (conCount <= 0) {
    conBuffer = (SIMdevConnect *) 
      malloc((unsigned) CON_INCREMENT * sizeof(SIMdevConnect));
    if (conBuffer == NULL) {
      fprintf(stderr, "SIMdevConnect unable to allocate sufficient memory");
      exit(1);
    }
    conCount = CON_INCREMENT;
  }

  result = conBuffer++;
  conCount--;
  return result;
}
