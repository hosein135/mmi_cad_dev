/*
$Id: chains.c,v 2.7 1993/12/17 04:48:51 mckenzie Exp mckenzie $
*/
/*******************************************************************/
/*
 *	COPYRIGHT (C) 1988  Carl Ebeling
 *
/*******************************************************************/
/* The code in this module finds chains of similar transistors and merges
   them into composite devices.  This has all been done quickly: in particular
   space used by devices thrown away is not reused.
   This stuff cannot be used unless the input file is a sim file.
/*******************************************************************/

#include "gemini.h"

/* Cross reference the composite types: Use the number of gates to index
   into these arrays
 */

static int PTypeChains[MAXCOMPOSITETYPES];
static int NTypeChains[MAXCOMPOSITETYPES];

/*******************************************************************/
/* Create a new device type which combines type1 and type2.  The device types
   known are wired in by name.
/*******************************************************************/

STATIC int newDeviceType(type1, type2)
int type1, type2;
{
  register int i;
/* Subtract 3 for the terminals that are now internal */
  register int numTerminals = DeviceDefs[type1].numTerminals + 
				 DeviceDefs[type2].numTerminals - 3;
/*
  debug(CHAIN,
    printf("Combining device types: %s(%d)<->%s(%d)\n",
	DeviceDefs[type1].name, DeviceDefs[type1].numTerminals,
	DeviceDefs[type2].name, DeviceDefs[type2].numTerminals);
  )
*/
  if (numTerminals >= MAXCOMPOSITETYPES) {
    fprintf(stderr,
      "Fatal internal error in FindChain: transistor chain too long\n");
    longjmp(env,1);
  }
  if (strlen(DeviceDefs[type1].name) > 1) {
    fprintf(stderr,
      "Attempting to combine user-defined devices; fatal error.\n");
    longjmp(env,1);
  }
  switch (*(DeviceDefs[type1].name)) {
  case 'd':
  case 'p':
    if (PTypeChains[numTerminals] != 0)
      return PTypeChains[numTerminals];
    break;
  case 'e':
  case 'n':
    if (NTypeChains[numTerminals] != 0)
      return NTypeChains[numTerminals];
    break;
  }
/* Make a new device type */
  if (NumDeviceDefs >= MAXDEVICETYPES) {
    fprintf(stderr, "Fatal internal error in FindChain: too many types\n");
    longjmp(env,1);
  }
  DeviceDefs[NumDeviceDefs].name = DeviceDefs[type1].name;
  DeviceDefs[NumDeviceDefs].numTerminals = numTerminals;
  DeviceDefs[NumDeviceDefs].terminals = (termClass *) 
    FastAlloc((unsigned) numTerminals * sizeof (termClass));

/*
** copy the first four pin types, then all others are gates 
*/
  for (i=0; i<4; i++) {
    DeviceDefs[NumDeviceDefs].terminals[i] = DeviceDefs[type1].terminals[i];
  }
  for (i=4; i<numTerminals; i++) {
    DeviceDefs[NumDeviceDefs].terminals[i] = GATE;
  }

  switch (*(DeviceDefs[type1].name)) {
  case 'd':
  case 'p':
    PTypeChains[numTerminals] = NumDeviceDefs++;
    return PTypeChains[numTerminals];
  case 'e':
  case 'n':
    NTypeChains[numTerminals] = NumDeviceDefs++;
    return NTypeChains[numTerminals];
  default:
    fprintf(stderr, "Fatal error in newDeviceType: unknown type\n");
    longjmp(env,1);
  }
}

/*******************************************************************/
/* Delete a device: move the last device in the vector to this spot, changing
   the net references to it
/*******************************************************************/
#ifdef DELETE
STATIC deleteDevice(graph, device)
Graph *graph;
register Node *device;
{
  register DeviceConnection *dev, *lastDev;
  register Node **net, **lastNet;
  register Node *lastDevice = &graph->deviceVector[--graph->numDevices];

  debug(CHAIN, printf("Deleting device:\n"); PrintNode(device);)
/* For each net connected to the device:
	For each device connected to the net:
	  If the device is the same as the original device, swing the pointer.
	  */
    for (net = lastDevice->connects.netList,
	 lastNet = net + NumberOfLinksD(lastDevice);
	 net < lastNet;
	 net++) {
	 for (dev = (*net)->connects.devList,
	   lastDev = dev + NumberOfLinksN(*net);
	   dev < lastDev;
	   dev++) {
	if (dev->node == lastDevice) {
	  dev->node = device;
	}
	 }
    }
  *device = *lastDevice;	/* Move entire structure */
}
#endif /* DELETE */

/* Delete a net in the netVector by replacing it by the last net in the vector
 */
void DeleteNet(graph, net)
Graph *graph;
register Node* net;
{
  register Node *lastNet = &graph->netVector[--graph->numNets];
  register Node *device;
  register int d, n;

/*  debug(CHAIN, printf("Deleting net: "); PrintNode(net);)*/
/* For each device connected to the net:
	For each net conneted to the net:
	  If the net is the same as the orignal net, swing the pointer.
*/
  for (d = 0; d < NumberOfLinksN(lastNet); d++) {
    device = lastNet->connects.devList[d].node;
    for (n = 0; n < NumberOfLinksD(device); n++) {
	 if (device->connects.netList[n] == lastNet) {
	device->connects.netList[n] = net;
	 }
    }
  }
  *net = *lastNet;		/* Move entire structure */
}

/*******************************************************************/
/* Reconnect a net from an old device to a new device at the specified
   terminal.  The class of the terminal should remain the same.  oldDevice
   may be the same as newDevice.
/*******************************************************************/

STATIC void reconnectNet(net, oldDevice, oldTerminal, newDevice, newTerminal)
Node *net, *newDevice;
register Node *oldDevice;
int oldTerminal, newTerminal;
{
  register DeviceConnection *dev, *lastDev;

/*  debug(CHAIN, printf("Reconnecting net: "); PrintNode(net);)*/
/* First, set the newDevice net list to point to the new net */
  newDevice->connects.netList[newTerminal] = net;
  if ((oldDevice == newDevice) && (oldTerminal == newTerminal)) return;

/* Find the net connection to the old device and change it to point to the new
 * device and terminal.
 */
/*  printf("%d\n", NumberOfLinksN(net));*/
  for (dev = net->connects.devList,
      lastDev = dev + NumberOfLinksN(net);
      dev < lastDev;
      dev++) {
    if ((dev->node == oldDevice) &&
      (dev->terminal == oldTerminal)) {
       dev->node = newDevice;
       dev->terminal = newTerminal;
	 return;
    }
  }
  fprintf(stderr, "Fatal internal error in 'reconnectNet'\n");
  longjmp(env,1);
}

/*******************************************************************/
/* Combine the two devices, replacing newDevice with the new one and deleting
 * oldDevice.  The device pointers point into the device array.
/*******************************************************************/

STATIC void combineDevices(graph, net, newDevice, oldDevice)
Graph *graph;
Node *net, *newDevice;
Node *oldDevice;
{
  int lastNumNets;
  Node *tmpDevice;
  register Node **newNetList = newDevice->connects.netList;
  register Node **oldNetList = oldDevice->connects.netList;
  register int numlinks;
  register int i;
  int cases;			/* Indicates which nets are connected */

  debug(CHAIN,
    printf("Combining devices:\n"); PrintNode(newDevice);PrintNode(oldDevice);
    printf(" through net: "); PrintNode(net);

 )
/*    printf("%d,%d : %d,%d ==> ", 
	   NumberOfLinksN(newNetList[0]),NumberOfLinksN(newNetList[1]),
	   NumberOfLinksN(oldNetList[0]),NumberOfLinksN(oldNetList[1]));
*/
/* Figure out cases and which device should be kept and which deleted */
  if (newNetList[0] == net) {	
    if (oldNetList[0] == net) {
      if (NumberOfLinksN(newNetList[1]) > NumberOfLinksN(oldNetList[1])) {
        cases = 11;
      } else {
        cases = 11;
        tmpDevice = newDevice; newDevice = oldDevice; oldDevice = tmpDevice;
      }
    } else {
      if (NumberOfLinksN(newNetList[1]) > NumberOfLinksN(oldNetList[0])) {
        cases = 10;
      } else {
        cases = 01;		/* devices swapped */
	tmpDevice = newDevice; newDevice = oldDevice; oldDevice = tmpDevice;
      }
    }
  } else {
    if (oldNetList[0] == net) {
      if (NumberOfLinksN(newNetList[0]) > NumberOfLinksN(oldNetList[1])) {
        cases = 01;
      } else {
        cases = 10;		/* devices swapped */
	tmpDevice = newDevice; newDevice = oldDevice; oldDevice = tmpDevice;
      }
    } else {
      if (NumberOfLinksN(newNetList[0]) > NumberOfLinksN(oldNetList[0])) {
        cases = 00;
      } else {
	cases = 00;
	tmpDevice = newDevice; newDevice = oldDevice; oldDevice = tmpDevice;
      }
    }
  }

  newNetList = newDevice->connects.netList;
  lastNumNets = NumberOfLinksD(newDevice);
  oldNetList = oldDevice->connects.netList;

/* Get the new combined device type and reallocate the connection list based 
 * on the new device
 */
  newDevice->n.nodeDef = newDeviceType(newDevice->n.nodeDef,
					  oldDevice->n.nodeDef);
/* This throws away the old net list: not clear how to save the space */
  newDevice->connects.netList =
    (NodePt *)FastAlloc((unsigned) NumberOfLinksD(newDevice) * sizeof(NodePt));

/* reconnect substrate contact */
  reconnectNet(newNetList[2], newDevice, 2, newDevice, 2);

/* Find first device drain connection, put on terminal 0 and copy other links
 * in the correct order
 */
  numlinks = 3;
  if (cases == 00) {
    reconnectNet(newNetList[0], newDevice, 0, newDevice, 0);
    for (i = 3; i < lastNumNets; i++) {
      reconnectNet(newNetList[i], newDevice, i, newDevice, numlinks++);
    }
    reconnectNet(oldNetList[0], oldDevice, 0, newDevice, 1);
    for (i = NumberOfLinksD(oldDevice)-1; i >= 3; i--) {
      reconnectNet(oldNetList[i], oldDevice, i, newDevice, numlinks++);
    }
  } else if (cases == 01) {
    reconnectNet(newNetList[0], newDevice, 0, newDevice, 0);
    for (i = 3; i < lastNumNets; i++) {
      reconnectNet(newNetList[i], newDevice, i, newDevice, numlinks++);
    }
    reconnectNet(oldNetList[1], oldDevice, 1, newDevice, 1);
    for (i = 3; i < NumberOfLinksD(oldDevice); i++) {
      reconnectNet(oldNetList[i], oldDevice, i, newDevice, numlinks++);
    }
  } else if (cases == 10) {
    numlinks = NumberOfLinksD(oldDevice);
    reconnectNet(newNetList[1], newDevice, 1, newDevice, 1);
    for (i = 3; i < lastNumNets; i++) {
      reconnectNet(newNetList[i], newDevice, i, newDevice, numlinks++);
    }
    numlinks = 3;
    reconnectNet(oldNetList[0], oldDevice, 0, newDevice, 0);
    for (i = 3; i < NumberOfLinksD(oldDevice); i++) {
      reconnectNet(oldNetList[i], oldDevice, i, newDevice, numlinks++);
    }
    numlinks += lastNumNets - 3;
  } else if (cases == 11) {
    numlinks = NumberOfLinksD(oldDevice);
    reconnectNet(newNetList[1], newDevice, 1, newDevice, 1);
    for (i = 3; i < lastNumNets; i++) {
      reconnectNet(newNetList[i], newDevice, i, newDevice, numlinks++);
    }
    numlinks = 3;
    reconnectNet(oldNetList[1], oldDevice, 1, newDevice, 0);
    for (i = NumberOfLinksD(oldDevice)-1; i >= 3; i--) {
      reconnectNet(oldNetList[i], oldDevice, i, newDevice, numlinks++);
    }
    numlinks += lastNumNets - 3;
  }
/* Append property list from oldDevice to newDevice */
  if (MagicFilePtr || PrintWarnings) {
    Property *oldProp, *newProp, *tp;

#if 0
    if ((cases == 00) || (cases == 11)) {
      newProp = oldDevice->p.property;
      if (newProp != NULL) {
	oldProp = newProp->next;
	newProp->next = NULL;
	while (oldProp != NULL) {
	  tp = oldProp;
	  oldProp = oldProp->next;
	  tp->next = newProp;
	  newProp = tp;
	}
      }
    } else {
      oldProp = oldDevice->p.property;
    }
#endif

    oldProp = oldDevice->p.property;

    if (newDevice->p.property == NULL) {
      newDevice->p.property = oldDevice->p.property;
    } else {
      for (newProp = newDevice->p.property; newProp->next != NULL;
        newProp = newProp->next)
	;
      newProp->next = oldProp;
    }
  }

/***************************************/
#ifdef DELETE
  if (newNetList[1] == net) {	/* drain is on 0: copy to new list */
    reconnectNet(newNetList[0], newDevice, 0, newDevice, 0);
    for (i = 3; i < numNets; i++) {
      reconnectNet(newNetList[i], newDevice, i, newDevice, numlinks++);
    }
  } else {			/* drain is on 1: reconnect to 0 */
    reconnectNet(newNetList[1], newDevice, 1, newDevice, 0);
    for (i = numNets-1; i >= 3; i--) {
      reconnectNet(newNetList[i], newDevice, i, newDevice, numlinks++);
    }
  }
/* Find the second device drain connection, put on terminal 1 and copy other
 * links in the correct order
 */
  numNets = NumberOfLinksD(oldDevice);
  if (oldNetList[0] == net) {/* drain on 1: copy to newDev */
    reconnectNet(oldNetList[1], oldDevice, 1, newDevice, 1);
    for (i = 3; i < numNets; i++) {
      reconnectNet(oldNetList[i], oldDevice, i, newDevice, numlinks++);
    }
  } else {			/* drain on 0: copy to newDevice */
    reconnectNet(oldNetList[0], oldDevice, 0, newDevice, 1);
    for (i = numNets-1; i >= 3; i--) {
      reconnectNet(oldNetList[i], oldDevice, i, newDevice, numlinks++);
    }
  }
#endif /* DELETE */
/***************************************/

  if (numlinks != NumberOfLinksD(newDevice)) {
    fprintf(stderr, "Internal error while chaining devices: %d -> %d\n",
	NumberOfLinksD(newDevice), numlinks);
  }
  debug(CHAIN,
    printf("New device is:\n");
    PrintNode(newDevice);
  )
/* Old device and net connecting the two devices are no longer needed */
  DeleteNet(graph, net);
  oldDevice->flag = DELETED;
/*  deleteDevice(graph, oldDevice);*/
}

/*******************************************************************/
/* Go through vector of nets finding those with 2 connections.  If it
   connects the source/drain terminals of two similar devices, then combine
   them.
/*******************************************************************/

void FindChains(graph)
Graph *graph;
{
  Node *net;
  DeviceConnection *connect0, *connect1;
  register int i;

  for (i = 0; i < graph->numNets; i++) {
    if (NumberOfLinksN(&graph->netVector[i]) == 2) {
/* Process serially connected transistors */
      net = &graph->netVector[i];
      connect0 = &net->connects.devList[0];
      connect1 = &net->connects.devList[1];
      /* Must connect to source/drains */
      if (connect0->class != DRAIN) continue;
      if (connect1->class != DRAIN) continue;

      if (connect0->node->connects.netList[2] !=
	  connect1->node->connects.netList[2]) {
	  continue; /* substrate connection doesn't match */
      }

      /* Make sure the devices are not user-defined */
      if (strlen(DeviceDefs[connect1->node->n.nodeDef].name) > 1) {
	continue;
      }
      /* Make sure the devices are different */
      if (connect0->node == connect1->node) continue;
      /* Make sure the devices are the same type */
      if (!(* Streq)(DeviceDefs[connect0->node->n.nodeDef].name,
        DeviceDefs[connect1->node->n.nodeDef].name))
        continue;
      /* Make sure sizes are the same */
      if (CollapseSameOnly &&
       ((connect0->node->p.property->width !=
         connect1->node->p.property->width) ||
        (connect0->node->p.property->length !=
         connect1->node->p.property->length)))
         continue;
      combineDevices(graph, net, connect0->node, connect1->node);
      i--;	/* If we got here, the net we were looking at
		   was deleted and replaced by a new one */
    }
  }
}

/*******************************************************************/
/* Run through the unique node queues of both graphs and make sure composite
   devices have their gates in the same order
/*******************************************************************/
void CheckChains(graph1, graph2)
Graph *graph1, *graph2;
{
  register Node *node1, *node2;
  register int count = graph1->uniqueDevices.size;
  int errorCount = 0;

  node1 = graph1->uniqueDevices.top;
  node2 = graph2->uniqueDevices.top;
  while (count--) {
    if ((NumberOfLinksD(node1) > 3) &&
	((strcmp(DeviceDefs[node1->n.nodeDef].name, "n") == 0) ||
	 (strcmp(DeviceDefs[node1->n.nodeDef].name, "p") == 0))) {
	 register Node **netList1 = node1->connects.netList;
	 register Node **netList2 = node2->connects.netList;
	 register int i, j, k;

/*    if (netList1[0]->nodeValue &
	  (netList1[0]->nodeValue == netList1[1]->nodeValue)) {
	printf("Warning: Source connected to drain\n");
	PrintNode(netList1[0]); PrintNode(netList1[1]);
	 }
*/
	 if (netList1[0]->nodeValue == netList2[0]->nodeValue) {
	/* Drains in same order */
	for (i = 3; i < NumberOfLinksD(node1); i++) {
	  if (netList1[i]->nodeValue != netList2[i]->nodeValue) {
	    errorCount++;
	    if (ChainWarnings) {
		 if (MagicFilePtr) MagicOutNode(node1, "CHAIN");
		 printf("Warning: transistors in chains out of order\n");
		 printf("DEVICE %s:", DeviceDefs[node1->n.nodeDef].name);
		 for (k = 3; k < NumberOfLinksD(node1); k++) {
		printf(" %s,", netList1[k]->name);
		 }
		 printf(" :: %s,", netList1[0]->name);
		 printf(" %s\n", netList1[1]->name);
		 printf("DEVICE %s:", DeviceDefs[node2->n.nodeDef].name);
		 for (k = 3; k < NumberOfLinksD(node2); k++) {
		printf(" %s,", netList2[k]->name);
		 }
		 printf(" :: %s,", netList2[0]->name);
		 printf(" %s\n", netList2[1]->name);
		 break;		/* We know there's a problem here */
	    }
	  }
	}
	 } else { /* Drains in opposite order */
	for (i = 3, j = NumberOfLinksD(node1) - 1;
		i < NumberOfLinksD(node1);
		i++, j--) {
	  if (netList1[i]->nodeValue != netList2[j]->nodeValue) {
	    errorCount++;
	    if (ChainWarnings) {
		 if (MagicFilePtr) MagicOutNode(node1, "CHAIN");
		 printf("Warning: transistors in chains out of order\n");
		 printf("DEVICE %s:", DeviceDefs[node1->n.nodeDef].name);
		 for (k = 3; k < NumberOfLinksD(node1); k++) {
		printf(" %s,", netList1[k]->name);
		 }
		 printf(":: %s,", netList1[0]->name);
		 printf(" %s\n", netList1[1]->name);
		 printf("DEVICE %s:", DeviceDefs[node2->n.nodeDef].name);
		 for (k = NumberOfLinksD(node2) - 1; k >= 3; k--) {
		printf(" %s,", netList2[k]->name);
		 }
		 printf(":: %s,", netList2[1]->name);
		 printf(" %s\n", netList2[0]->name);
		 break;		/* We know there's a problem here */
	    }
	  }
	}
	 }
    }
    node1 = node1->next;
    node2 = node2->next;
  }
  if (errorCount) {
    printf("A total of %d transistor chains were out of order\n", errorCount);
  }
}
