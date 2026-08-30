/*
$Id: deduce.c,v 2.7 1993/12/17 04:49:32 mckenzie Exp mckenzie $
*/
/***************************************************************************/
/*	COPYRIGHT (C) 1988  Carl Ebeling
/* This file contains code that tries to deduce new unique nodes by looking
 * at the neighbors of old unique nodes.
/***************************************************************************/

#include "gemini.h"

typedef struct Hentry {
  Node *node;
  unsigned int value;	/* This includes class and value */
  short int count;	/* The number of entries with this hash */
  short int used;	/* Flags whether the entry was found on 2nd node */
  unsigned int version;	/* Used to mark empty entry */
} Hentry;

Hentry HTable[10*DEDUCEHTSIZE];  /* This size should be determined dynamically */
static int currentVersion = 0;	/* Indicates if empty entry */
static int currentSize = 0;

void StartNewHT(size)
int size;
{
  register int i;

  if (size < (2*DEDUCEHTSIZE/3 - 1)) {
    currentSize = 3*size/2 + 1;
  } else {
    currentSize = DEDUCEHTSIZE;
  }
  if (currentVersion == 0) {
    for (i = 0; i < DEDUCEHTSIZE; i++) {
      HTable[i].version = 0;
    }
  }
  if (++currentVersion == 0) {
    fprintf(stderr, "Overflow in StartNewHT\n");
  }
}

int InsertHT(node, class)
Node *node;
unsigned class;
{
  register unsigned int value = node->nodeValue + class;
  register int i, count;
  register unsigned int index = value % (unsigned) currentSize;
  
  for (count = 0, i = index;
       count < currentSize;
       count++, i = ((i == (currentSize-1)) ? 0 : i + 1)) {
    if (HTable[i].version != currentVersion) { /* Empty entry */
/*    fprintf(stderr, "insert %d\n", i); */
      HTable[i].node = node;
      HTable[i].value = value;
      HTable[i].count = 1;
      HTable[i].version = currentVersion;
      HTable[i].used = FALSE;
      return FALSE;
    } else if (value != HTable[i].value) { /* collision: continue */
      continue;
    } else {			/* Same value */
      HTable[i].count++;
      HTable[i].used = TRUE;
      return FALSE;
    }
  }
  printf("[DHT full]\n");
  return TRUE;	/* Return TRUE if the table is filled up */
}

Node *MatchHT(node, class)
Node *node;
unsigned class;
{
  register unsigned int value = node->nodeValue + class;
  register int i, count;
  register unsigned int index = value % (unsigned) currentSize;
  
  for (count = 0, i = index;
       count < currentSize;
       count++, i = ((i == (currentSize-1)) ? 0 : i + 1)) {
/* Empty entry? */
    if (HTable[i].version != currentVersion) {
      return (Node *) -1;
/* Collision? */
    } else if (value != HTable[i].value) {
      continue;
/* Entry found: Already used ==> value not unique */
    } else if (HTable[i].used) {
      return NULL;
/* First time use of entry */
    } else {
      HTable[i].used = TRUE;
/* Unique value? */
      if (HTable[i].count == 1) { /* Nodes must match */
	return HTable[i].node;
      } else {
	return NULL;	/* Matching entry, but not unique */
      }
    }
  }
  fprintf(stderr, "Program error in MatchHT\n");
  return NULL;   /* Should never happen */
}

/************************************************************************/
/* This procedure examines the hash table for entries that were not used
 * by MatchHT.  There are 3 cases:
 *   1) The entry is empty.
 *   2) The entry was used (Match or non-Unique)
 *   3) The entry contains a duplicate node.
/************************************************************************/

void FinishHT(graph)
register Graph *graph;		/* Graph to which the nodes in HT belong */
{
  register int i;
  
  for (i = 0; i < currentSize; i++) {
    if ((HTable[i].version == currentVersion) &&
	(HTable[i].used == FALSE) &&
	(HTable[i].node->flag == PENDING)) {
      HTable[i].node->nodeValue = Random();
      debug(DEDUCE,
	    printf("Unmatched node in circuit 1:");
	    PrintNode(HTable[i].node);)
    }
  }
}

/************************************************************************/
/* Try to match neighbors of nodes that have been matched.  We must add in
 * the new value of the nodes because, while they will make no difference
 * now, they may in the future.
/************************************************************************/

void LocalMatch(graph1, node1, graph2, node2)
Graph *graph1, *graph2;
register Node *node1, *node2;
{
  register int i;
  int numNeighbors;
  NodePt node;
  
  numNeighbors = NumberOfLinks(node1);
  if (numNeighbors < DeduceNeighbors) { /* Make sure all neighbors 
					   fit in hash table */
    StartNewHT(numNeighbors);
    if (node1->nodeType == DEVICE) {
      register NodePt *connections;
      register termClass *cT = TerminalList(node1);
      
      connections = node1->connects.netList;
      for (i = 0; i < numNeighbors; i++) {
	if (pendingNode(connections[i])) {
	  IncrementValue(connections[i], node1->nodeValue, cT[i]);
	  if (InsertHT(connections[i], cT[i])) break;
	}
      }
      connections = node2->connects.netList;
      for (i = 0; i < numNeighbors; i++) {
	if (pendingNode(connections[i])) {
	  IncrementValue(connections[i], node2->nodeValue, cT[i]);
	  if (node = MatchHT(connections[i], cT[i])) {
	    if (node == (Node *) -1) { /* Node not matched: value is set to
					  unique value */
	      connections[i]->nodeValue = Random();
	      debug(DEDUCE,
		    printf("Unmatched node in circuit 2:");
		    PrintNode(connections[i]);)
	    } else {
	      connections[i]->nodeValue = node->nodeValue = Random();
	      connections[i]->flag = node->flag = MATCHING;
	      debug(DEDUCE,
		    printf("FM:");
		    PrintNode(node);
		    PrintNode(connections[i]);)
	      InsertQueue(connections[i], &graph2->nextEvalQueue);
	      InsertQueue(node, &graph1->nextEvalQueue);
	    }
	  }
	}
      }
    } else { /* NET */
      register DeviceConnection *connections;
      
      connections = node1->connects.devList;
      for (i = 0; i < numNeighbors; i++) {
	if (pendingNode(connections[i].node)) {
	  IncrementValue(connections[i].node, node1->nodeValue, connections[i].class); /* Update neighbor value */
	  if (InsertHT(connections[i].node, connections[i].class))
	    break;
	}
      }
      connections = node2->connects.devList;
      for (i = 0; i < numNeighbors; i++) {
	if (pendingNode(connections[i].node)) {
	  IncrementValue(connections[i].node, node2->nodeValue, connections[i].class); /* Update neighbor value */
	  if (node = MatchHT(connections[i].node,
			     connections[i].class)) {
	    if (node == (Node *) -1) { /* Node not matched: value is set to
					  unique value */
	      connections[i].node->nodeValue = Random();
	      debug(DEDUCE,
		    printf("Unmatched node in circuit 2:");
		    PrintNode(connections[i].node);)
	    } else {
	      connections[i].node->nodeValue = node->nodeValue = Random();
	      connections[i].node->flag = node->flag = MATCHING;
	      debug(DEDUCE,
		    printf("FM:");
		    PrintNode(node);
		    PrintNode(connections[i].node);)
	      InsertQueue(connections[i].node, &graph2->nextEvalQueue);
	      InsertQueue(node, &graph1->nextEvalQueue);
	    }
	  }
	}
      }
    }
    FinishHT(graph1);	/* Find unmatched nodes in first graph */
  }
}
