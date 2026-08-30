/*
$Id: hash.c,v 2.7 1993/12/17 04:49:32 mckenzie Exp mckenzie $
*/
/*******************************************************************/
/* This file contains the functions that compute the values of nodes in
 * the graph and the procedures that enter the nodes in the hash table
 * and determine Unique nodes
/*******************************************************************/

/*******************************************************************/
/*
 *	COPYRIGHT (C) 1983  Carl Ebeling and Ofer Zajicek
 *	COPYRIGHT (C) 1988  Carl Ebeling
 *
/*******************************************************************/

/*******************************************************************/
/* 
 *	HISTORY
 *
/*******************************************************************/

#include "gemini.h"


/*******************************************************************/
/* Compute the hash value for a node from its nodeValue.
 * The node value may be negative, but the hash value must be positive.
 * -value and value should hash to different values.
/*******************************************************************/

#define hash(number,hashSize) 	(number % hashSize)
/*
( (number >= 0) ? number % hashSize : (-number) % hashSize)
*/

/*******************************************************************/
/*  Allocates memory for the hashtable
/*******************************************************************/

void AllocHashTable(graph)
Graph *graph;
{
  graph->hashTable = (Bucket *) 
    malloc((unsigned) MaxHashSize * sizeof(Bucket));
}

/*******************************************************************/
/* Initialize a hash table by setting all the bucket lists to NULL
/*******************************************************************/

void InitHashTable(graph, numberNodes)
register Graph *graph;
register int numberNodes;	/* Nodes inserted in this pass */
{
  register int i;
  
  graph->checkSum = 0;
  if (HashSize == 0) {		/* Only reset HashSize if not initialized */
    /* Calculate appropriate hash table size based on number of entries */
    HashSize = (numberNodes/HASHRATIO) + 1;
    if (HashSize > MaxHashSize) {
      fprintf(stderr, "InitHashTable: Max hash size exceeded: %d > %d\n",
	      HashSize, MaxHashSize);
      HashSize = MaxHashSize;
    }
  }

  for(i = 0; i < HashSize; i++) {
    register Bucket *bucket = &graph->hashTable[i];
    
    bucket->bucketSum = 0;	/* Clear bucket check sum */
    bucket->minPartSize = MAXINT;
    ClearQueue(&bucket->notUnique);
    ClearQueue(&bucket->Unique);
    ClearQueue(&bucket->overflow);
  }
}

/*******************************************************************/
/*  Print the hash table for debugging
/*******************************************************************/

void PrintHashTable(graph)
register Graph *graph;
{
  register int i;

  printf("%d buckets\n", HashSize);
  for (i = 0; i < HashSize; i++)
    { register Bucket *bucket = &graph->hashTable[i];

      printf("Bucket %d:\n", i);
      printf("	%d Unique nodes\n", bucket->Unique.size);
      PrintQueue(&(bucket->Unique));
      printf("	%d Not unique nodes\n", bucket->notUnique.size);
      PrintQueue(&(bucket->notUnique));
      printf("	%d overflow nodes\n", bucket->overflow.size);
      PrintQueue(&(bucket->overflow));
    }
}

/*******************************************************************/
/*  Enter a node in the hash table
 *  If the node value is already present, add node to overflow queue.
 *  Otherwise enter in the Unique queue.  It is possible for the node to knock
 *  a node out of the Unique queue.
 *  All NON-UNIQUE values are added to the bucket checksum and hash table
 *  checksum.
/*******************************************************************/

void EnterHash(aNode, graph)
Node *aNode;
Graph *graph;
{
  register Node *curNode,*prevNode;
  register int thisValue = aNode->nodeValue;
  /* Bucket in which the entry is made */
  register Bucket *bucket =
    &graph->hashTable[hash(aNode->nodeValue, HashSize)];

/*******************************************************************/
/* Values of nodes MUST be positive when the nodes are entered in the table.
 * It is assumed that computeValue yields a positive number.
/*******************************************************************/

/*   look for the node in the non-uniques list
 */
  for (curNode = bucket->notUnique.top; 
       ((curNode != NULL) && (curNode->nodeValue != thisValue));
       curNode = curNode->next) ;

/* If the value is in the non-unique list, insert it to the overflow queue
 * later to be used by the matching routines in case the checksums didn't
 * match
 */
  if (curNode != NULL) {
    graph->checkSum += thisValue;
    bucket->bucketSum += thisValue;
    curNode->partitionSize ++;
    InsertQueue(aNode, &bucket->overflow);
    return;
  }

/* Otherwise, search the unique list */

  debug(ENTERHASH, printf("Value not non-unique\n"); )
  prevNode = NULL;
  curNode = bucket->Unique.top;
  while((curNode != NULL) && (curNode->nodeValue != thisValue)) {
    prevNode = curNode;
    curNode = curNode->next;
  }

/* If the nodeValue is in neither list, then the node is entered as unique
 */
  if (curNode == NULL) { /* Enter new node in hash table */
    InsertQueue(aNode,&bucket->Unique);
    debug(ENTERHASH,
	  printf("value not in hash\n");
	  printf("Table entry: value:%d, hash:%d\n", 
		 thisValue, hash(thisValue, HashSize)); )
    } else { /* The value WAS unique, but is not anymore */
      /* Move entry from unique list to non-unique list */
      debug(ENTERHASH, printf("Unique value now non-unique: value:%d\n", 
			      thisValue); )
      bucket->Unique.size--;
      if (prevNode == NULL) {  /* the node is the first element of the list  */
	bucket->Unique.top = curNode->next;
	if (bucket->Unique.top == NULL) bucket->Unique.bottom = NULL;
      } else {
	prevNode->next = curNode->next;
      }
      if (bucket->Unique.bottom == curNode) {
	bucket->Unique.bottom = prevNode;
      }
	
/* Insert one of the nodes in the non-unique queue and the other in the 
 * NotQueued queue
 */
      graph->checkSum += 2*thisValue;
      bucket->bucketSum += 2*thisValue;
      InsertQueue(aNode,&bucket->overflow);
      InsertQueue(curNode,&bucket->notUnique);
      curNode->partitionSize = 2;
    }
}

/*******************************************************************/
/*  Primes is a vector of values that are used to multiply neighbor
 *  values depending on the terminal class.
 /*******************************************************************/

#define NUMBERPRIMES 256
int PRIMES[NUMBERPRIMES] = {
  2,3,5,7,11,13,17,19,23,29,  /* Version 0 */
/* 2,3,5,7,  /* Version 1 */
/* 2,3,4,5, /* Version 2 */
/* 93187, 98953, 104729, 102329, /* Version N */

31,37,41,43,47,53,59,61,67,71,
73,79,83,89,97,101,103,107,109,113,
127,131,137,139,149,151,157,163,167,173,
179,181,191,193,197,199,211,223,227,229,
233,239,241,251,257,263,269,271,277,281,
283,293,307,311,313,317,331,337,347,349,
353,359,367,373,379,383,389,397,401,409,
419,421,431,433,439,443,449,457,461,463,
467,479,487,491,499,503,509,521,523,541,
547,557,563,569,571,577,587,593,599,601,
607,613,617,619,631,641,643,647,653,659,
661,673,677,683,691,701,709,719,727,733,
739,743,751,757,761,769,773,787,797,809,
811,821,823,827,829,839,853,857,859,863,
877,881,883,887,907,911,919,929,937,941,
947,953,967,971,977,983,991,997,1009,1013,
1019,1021,1031,1033,1039,1049,1051,1061,1063,1069,
1087,1091,1093,1097,1103,1109,1117,1123,1129,1151,
1153,1163,1171,1181,1187,1193,1201,1213,1217,1223,
1229,1231,1237,1249,1259,1277,1279,1283,1289,1291,
297,1301,1303,1307,1319,1321,1327,1361,1367,1369,
1373,1381,1399,1409,1423,1427,1429,1433,1439,1447,
1451,1453,1459,1471,1481,1483,1487,1489,1493,1499,
1511,1517,1523,1531,1543,1549,1553,1559,1567,1571,
1579,1583,1591,1597,1601,1607,
/* 1609,1613,1619,1621,1627,1637, */
};

static int PRIMES2[NUMBERPRIMES] = {
1637,1627,1621,1619,1613,1609,1607,1601,1597,1591, /* Version 0 */

/* 95291, 99877, 101467, 103319, /* Version N */
/*1637,1627,1621,1619, Version N-1 */
/* 2,3,5,7, /* Version 1 */
/* 2,3,4,5, /* Version 2 */
1583,1579,1571,1567,1559,1553,1549,1543,1531,1523,
1517,1511,1499,1493,1489,1487,1483,1481,1471,1459,
1453,1451,1447,1439,1433,1429,1427,1423,1409,1399,
1381,1373,1369,1367,1361,1327,1321,1319,1307,1303,
1301,1297,1291,1289,1283,1279,1277,1259,1249,1237,
1231,1229,1223,1217,1213,1201,1193,1187,1181,1171,
1163,1153,1151,1129,1123,1117,1109,1103,1097,1093,
1091,1087,1069,1063,1061,1051,1049,1039,1033,1031,
1021,1019,1013,1009,997,991,983,977,971,967,
953,947,941,937,929,919,911,907,887,883,
881,877,863,859,857,853,839,829,827,823,
821,811,809,797,787,773,769,761,757,751,
743,739,733,727,719,709,701,691,683,677,
673,661,659,653,647,643,641,631,619,617,
613,607,601,599,593,587,577,571,569,563,
557,547,541,523,521,509,503,499,491,487,
479,467,463,461,457,449,443,439,433,431,
421,419,409,401,397,389,383,379,373,367,
359,353,349,347,337,331,317,313,311,307,
293,283,281,277,271,269,263,257,251,241,
239,233,229,227,223,211,199,197,193,191,
181,179,173,167,163,157,151,149,139,137,
131,127,113,109,107,103,101,97,89,83,
79,73,71,67,61,59,53,47,43,41,
37,31,29,23,19,17,
};

/*
#define primeFactor(x) PRIMES[x & (NUMBERPRIMES-1)]
#define primeFactor2(x) PRIMES2[x & (NUMBERPRIMES-1)]
*/
#define primeFactor(x) PRIMES[x]
#define primeFactor2(x) PRIMES2[x]
/*******************************************************************/
/* random is a variation on the normal rand call: allows us to chain numbers
 * into a random number
/*******************************************************************/

#ifdef HASH_NO_RANDOM
#define random1(x) (x)
#define random2(x) (x)
#else
#define random1(x) (x * 1103515245 + 12345)
#define random2(x) (x * 1015351425 + 12435)
#endif

/*******************************************************************/
/* Computes the new value of the node based on the values of the neighbors
 * If the node is device, the terminals are used to differentiate neighbors.
 * If the node is a net, the terminals of the device to which it is connected
 * is used to differentiate neighbors.
 * computeValue must return a positive value.
/*******************************************************************/

void ComputeValue(aNode)
Node *aNode;
{
register int i;
register unsigned int newValue = aNode->nodeValue;
int numConnects = NumberOfLinks(aNode);

  switch (aNode->nodeType) {
    case DEVICE: {
      NodePt *connections = aNode->connects.netList;
      termClass *cT = DeviceDefs[aNode->n.nodeDef].terminals;

      for (i = 0; i < numConnects; i++) {
	if (connections[i] != (NodePt) NULL)
	  newValue += connections[i]->nodeValue * primeFactor(cT[i]);
      }
    }
    break;

    case NET: {
      register DeviceConnection *connections = aNode->connects.devList;
      for (i = 0; i < numConnects; i++) { 
	if (connections != (DeviceConnection *) NULL)
	  newValue += connections[i].node->nodeValue
		    * primeFactor2(connections[i].class);
      }
      break;
    }
  }
  aNode->nodeValue = newValue;
  debug(COMPUTEVALUE, PrintNode(aNode); )
}

void IncrementValue(aNode, value, class)
Node* aNode;
int value;
int class;
{
  aNode->nodeValue += value * primeFactor(class);
}


/*******************************************************************/
/* Takes a graph and appends all the lists of unique elements into
 * one queue.
/*******************************************************************/

void AppendUniques(graph)
register Graph *graph;
{
register int i;

  ClearQueue(&graph->newUniques);
  debug(HASH, printf("appendUniques: table size = %d\n", HashSize); )
  for (i = 0; i < HashSize ; i++) { 
       debug (HASH,
         printf("    bucket %d: %d uniques, %d not uniques, %d overflow\n",
	     i, graph->hashTable[i].Unique.size,
		graph->hashTable[i].notUnique.size,
		graph->hashTable[i].overflow.size);
	 )
       AppendQueue(&graph->newUniques, &graph->hashTable[i].Unique);
     }
  assert(((graph->newUniques.bottom == NULL) ||
	 (graph->newUniques.bottom->next == NULL)),
        "AppendUniques: queue bottom error"
	);
}

/*******************************************************************/
/* Assign initial values to the nodes in the node list and build the initial
 * queues.
 * NETS: The initial value is the number of connections
 * DEVICES: The initial value is the primeFactor[definition-index]
/*******************************************************************/

void AssignInitialValue(node, circuit)
register Node *node;
int circuit;			/* 1,2 for which circuit */
{
register int value;

  if ((value = FindEqName(node->name, circuit)) == 0) {
    switch(node->nodeType) {
    case DEVICE:
      value = node->n.nodeDef + 1;
      value = random1(value);
      break;

    case NET:
      value = node->n.netConnects;
      value = random2(value);   /* Version 1 */
/*    value = random1(value);	/* Version 0 */
      break;
    }
  } else {
    node->flag = MATCHING;
  }
debug(INITVALUE, 
      printf("Initial value for ");
      PrintNode(node);
      printf("	is: %d\n", value);
      )
  node->nodeValue = value;
}

/*******************************************************************/
/* InitialDeviceValues and InitialNetValues both do the initial labelling of 
 * graph.  This must be done to get the = names matched correctly.
/*******************************************************************/

void InitialDeviceValues(graph)
register Graph *graph;
{
  register NodePt *nodeArray = graph->pendingDevices;
  register int size = graph->numPendingDevices;
  register int i;

  for (i = 0; i < size; i++) {
    nodeArray[i]->pass = -1;
    AssignInitialValue(nodeArray[i], graph->graphNumber);
    nodeArray[i]->flag = PENDING; /* This hack makes sure that devices do not
				     get set to MATCHING */
  }
}

/*******************************************************************/
/* Same as InitialDeviceValues except for Nets.
/*******************************************************************/

void InitialNetValues(graph)
register Graph *graph;
{
  register NodePt *nodeArray = graph->pendingNets;
  register int size = graph->numPendingNets;
  register int i;

  for (i = 0; i < size; i++) {
    nodeArray[i]->flag = PENDING;
    nodeArray[i]->pass = -1;
    AssignInitialValue(nodeArray[i], graph->graphNumber);
    if (nodeArray[i]->flag == MATCHING) { /* Put equated nets in
					     MATCHING queue */
      nodeArray[i]->pass = 0;	/* flag to similarNodes that these are OK */
      InsertQueue(nodeArray[i], &graph->nextEvalQueue);
    }
  }
}
