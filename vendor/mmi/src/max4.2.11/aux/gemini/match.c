/*
$Id: match.c,v 2.7 1993/12/17 04:49:32 mckenzie Exp mckenzie $
*/
/******************************************************************/
/* This file contains the functions used to find nodes of the graphs
 * unique and to match them
/*******************************************************************/

/*******************************************************************/
/*
 *	COPYRIGHT (C) 1983  Carl Ebeling and Ofer Zajicek
 *	COPYRIGHT (C) 1988  Carl Ebeling
/*******************************************************************/

/*******************************************************************/
/* 	HISTORY
/*******************************************************************/

#include "gemini.h"
/*******************************************************************/
/*
 * processUniques
 * --------------
 *	Runs through the queue of new unique nodes ( graph->newUniques )
 *	and sets the flag of all the nodes to UNIQUE.
 *
 *	For each of those nodes, it inserts all its neighbors that are
 *	neither SUSPECT nor UNIQUE to the nextEvalQueue.
 *	The neighbors will be processed in the next pass.
 *
/*******************************************************************/

void ProcessUniques(graph)
register Graph *graph;
{
  register  Node *uNode;	/* Current unique node to be processed */
  int noMatches = (graph->nextEvalQueue.top == NULL);

/*******************************************************************/
/* Just pass through the list turning each node into a 'Unique' node.
/*******************************************************************/

/*  ClearQueue(&graph->nextEvalQueue);	/* Now has MATCHING nodes */

  if (! noMatches) DeducedMatches += graph->nextEvalQueue.size;
  if (Trace) {
    printf("%s: %d new unique nodes\n", 
	   graph->graphName, graph->newUniques.size);
    if (! noMatches) {
      printf("%s: %d all ready to be matched\n",
	     graph->graphName, graph->nextEvalQueue.size);
    }
  }
  for(uNode = graph->newUniques.top; uNode != NULL; uNode = uNode->next) {  
    uNode->flag = UNIQUE;	/* Sign flags unique node */
    uNode->pass = Pass;		/* Pass on which node became unique */
    if (noMatches) queueNeighbors(uNode, &graph->nextEvalQueue);
    debug(TRACEALL, PrintNode(uNode);)       		
  }
}

/*******************************************************************/
/*
 * queueNeighbors
 * ---------------
 *	Inserts all the neighbors of the node that are PENDING
 *	into the queue (nextEval queue)
 *
 *	The node neighbors are found in the node's connection list.
 *	The current pass value is assigned as the node's pass value to
 *	mark that the node has already
 *	been inserted in the nextEval queue.  This must be done since a node
 *	may be the neighbor of several unique nodes.
 *	
/*******************************************************************/

STATIC void queueNeighbors(anode, queue)
Node *anode;		/* Unique node */
register Queue *queue;		/* (nextEval) queue */
{
register int i;
register int numlinks = NumberOfLinks(anode);	/*  number of neighbors */
int value = anode->nodeValue;	/* 6/19/88 */

  switch(anode->nodeType) {
  case DEVICE:
    { register Node **connections = anode->connects.netList;

      for (i=0; i < numlinks; i++)
	if ( (connections[i]->pass != Pass) &&  /* not in the queue */ 
	    (pendingNode(connections[i]))) {    /* and pending */
	  connections[i]->pass = Pass;
	  connections[i]->nodeValue += value; /* 6/19/88 */
	  InsertQueue(connections[i], queue);
	  debug(MATCH,
		printf("Inserting - ");
		PrintNode(connections[i]);
		)
	  }
      break;
    }

  case NET:
    { register DeviceConnection *connections = anode->connects.devList;

      for (i = 0; i < numlinks; i++)
	if ((connections[i].node->pass != Pass) && /* not in the queue */
	    (pendingNode(connections[i].node))) {   /* and pending */
	  connections[i].node->pass = Pass;
	  connections[i].node->nodeValue += value; /* 6/19/88 */
	  InsertQueue(connections[i].node, queue);
	}
      break;
    }	 /*  case NET */
  }	 /*  switch   */
}

/*******************************************************************/
/*
 * CleanPendingArray
 * -----------------
 *	Clean up the pendingNet/Device arrays by removing all except
 *	pending Nodes.  If queue is not NULL, set it to all the pending nodes.
 *	If the result queue is not given and it is seen that all the nodes in
 *	the Pending array are indeed Pending, then don't do anything.
 *
 *	All nodes should be in the pending queue, the Suspect queues,
 *	the Bad queues or the Unique queues.
/*******************************************************************/

void CleanPendingArray(graph, whichNodes, queue)
Graph *graph;
int whichNodes;			/* Insert nets or devices into nextEvalQueue */
register Queue *queue;		/* Queue to be formed */
{ 
  register int i;
  register NodePt *nodeArray;	/* Array of pending nodes */
  register Node *node;
  register int size;		/* Size of node array */

  switch (whichNodes) {
  case NET:
    if ((queue == NULL) && PendingNetsAreClean(graph)) return; /* Already OK*/
    nodeArray = graph->pendingNets;
    size = graph->numPendingNets;
    break;
  case DEVICE:
    if ((queue == NULL) && PendingDevicesAreClean(graph)) return; /* OK */
    nodeArray = graph->pendingDevices;
    size = graph->numPendingDevices;
    break;
  }

  debug( CLEAN, printf("Clean %s %s: begin size = %d\n", 
		       graph->graphName,
		       (whichNodes == NET) ? "NETS" : "DEVICES", size);
	)
  if (queue != NULL) {
    ClearQueue(queue);
    for (i = 0; i < size; ) {
      if ( pendingNode(nodeArray[i])) {
	node = nodeArray[i++];
	ComputeValue(node);
	InsertQueue(node, queue);
      } else if (nodeArray[i]->flag == MATCHING) {
#ifdef DEBUG
	printf("MATCHING->PENDING: ");
	PrintNode(nodeArray[i]);
#endif
	nodeArray[i]->flag = PENDING;
	node = nodeArray[i++];
	ComputeValue(node);
	InsertQueue(node, queue);
      } else { /*  Replace the non-pending node with the one 
		*  at the end of the array */
	nodeArray[i] = nodeArray[--size];
      }
    }
  } else {
    for (i = 0; i < size; ) {
      if (nodeArray[i]->flag == MATCHING) {
	printf("Error: MATCHING->PENDING: ");
	PrintNode(nodeArray[i]);
	nodeArray[i]->flag = PENDING;
      }
      if ( pendingNode(nodeArray[i])) {
	i++;
      } else { /*  Replace the non-pending node with the one 
		*  at the end of the array */
	nodeArray[i] = nodeArray[--size];
      }
    }
  }  
  debug (CLEAN, printf("Clean: end size = %d\n", size);)

  switch (whichNodes) {
  case NET:
    graph->numPendingNets = size;
    assert(PendingNetsAreClean(graph),
	   "CleanPending: Nets lost or gained");
    break;
  case DEVICE:
    graph->numPendingDevices = size;
    assert(PendingDevicesAreClean(graph),
	   "CleanPending: Devices lost or gained");
    break;
  }
  debug (CLEAN, printf("After cleaning:	");)
}

/*******************************************************************/
/*
 * setSuspectQueue
 * ---------------
 *	Take a queue of nodes that are now suspect (newQueue) and append
 *	it to the correct suspect queue in graph.
/*******************************************************************/

STATIC void setSuspectQueue(newQueue, graph)
register Queue *newQueue;	/* Queue of nodes to set suspect */
register Graph *graph;
{
  register Node *nextNode;    

  for(nextNode = newQueue->top; nextNode != NULL; nextNode = nextNode->next ) {
    setSuspectNode(nextNode);
  }

  if (newQueue->top != NULL) {
    switch (newQueue->top->nodeType) {
      case NET:
	AppendQueue(&graph->suspectNets, newQueue);
	break;
      case DEVICE:
	AppendQueue(&graph->suspectDevices, newQueue);
	break;
    }
  }
}

/*******************************************************************/
/* Insert a bad node into the appropriate bad queue of the graph
/*******************************************************************/

#define InsertBadNode(node, graph)\
   switch(node->nodeType)	\
     { case NET:    InsertQueue(node, &graph->badNets);	\
     		    break;	\
       case DEVICE: InsertQueue(node, &graph->badDevices);	\
       		    break;	\
     }

/*******************************************************************/
/*
 * resetSuspects
 * -------------
 *	Redeem all the suspect nodes in a graph.
 *	First clean the pending node arrays then add the suspect nodes to
 *	the pending arrays and queues.
/*******************************************************************/

void ResetSuspects(graph)
register Graph *graph;
{
  register Node *node;
  register int size;

  debug(SUSPECTS, printf("Resetting suspect nodes\n");)
  CleanPendingArray(graph, NET, (Queue *) NULL);

  size = graph->numPendingNets;
  for (node = graph->suspectNets.top; node != NULL; node = node->next) {
    graph->pendingNets[size++] = node;
/*      ComputeValue(node);*/
    AssignInitialValue(node, graph->graphNumber);
    node->flag = PENDING;	/* Forced nodes should not be here */
  }
  graph->numPendingNets = size;
  ClearQueue(&graph->suspectNets);

  CleanPendingArray(graph, DEVICE, (Queue *) NULL);
  size = graph->numPendingDevices;
  for (node = graph->suspectDevices.top; node != NULL; node = node->next) {
    graph->pendingDevices[size++] = node;
/*      ComputeValue(node);*/
    AssignInitialValue(node, graph->graphNumber);
    node->flag = PENDING;	/* Forced nodes should not be here */
  }
  graph->numPendingDevices = size;
  ClearQueue(&graph->suspectDevices);

  assert(PendingNetsAreClean(graph) && PendingDevicesAreClean(graph),
    "resetSuspects: nets/devices lost or gained"
  )
  debug(TRACE,
    printf("resetSuspects: pending devices: %d, pending nets:%d\n",
    graph->numPendingDevices, graph->numPendingNets);
  )
}

/*******************************************************************/
/*
 * resetBad
 * -------------
 *	Redeem all the bad nodes in a graph.
 *	First clean the pending node arrays then add the bad nodes to
 *	the pending arrays and queues.
/*******************************************************************/

void ResetBad(graph)
register Graph *graph;
{
  register Node *node;
  register int size;

  CleanPendingArray(graph, NET, (Queue *) NULL);
  size = graph->numPendingNets;
  for (node = graph->badNets.top; node != NULL; node = node->next) {
    graph->pendingNets[size++] = node;
/*      ComputeValue(node);*/
    AssignInitialValue(node, graph->graphNumber);
    node->flag = PENDING;	/* Forced nodes should not be here */
  }
  graph->numPendingNets = size;
  ClearQueue(&graph->badNets);

  CleanPendingArray(graph, DEVICE, (Queue *) NULL);

  size = graph->numPendingDevices;
  for (node = graph->badDevices.top; node != NULL; node = node->next) {
    graph->pendingDevices[size++] = node;
/*      ComputeValue(node);*/
    AssignInitialValue(node, graph->graphNumber);
    node->flag = PENDING;	/* Forced nodes should not be here */
  }
  graph->numPendingDevices = size;
  ClearQueue(&graph->badDevices);

  assert(PendingNetsAreClean(graph) && PendingDevicesAreClean(graph),
    "resetBad: nets/devices lost or gained"
	  )
  debug(TRACE, printf("resetBad: pending devices: %d, pending nets:%d\n",
    graph->numPendingDevices, graph->numPendingNets);
	 )
}

/*******************************************************************/
/*
 * AssignNewValues
 * ---------------
 *	Relabel either the Net or Device (passType) nodes in the graph.
 *
 *	If noOpt is non zero, the nextEvalQueue is cleared which causes all
 *	the nodes to be relabeled in the pass
 *
 *	This routine assigns a value to all the nodes in nextEvalQueue.
 *	It then appends all the unique queues from the hash table to
 *	graph->newUniques and sorts the newUniques queue.
 *	 
 *	All the new uniques are processed, setting their flag to UNIQUE
 *	and inserting their neighbors to the nextEvalQueue for the next 
 *	pass.
 *
/*******************************************************************/

void AssignNewValues(graph)
register Graph *graph;
{
  register Node *node;
  int recomputeFlag = FALSE;	/* Assume recomputation is not needed.  We must
				   recompute if we have no EvalQueue to work
				   with */
  if (Trace) printf("Pass %d), %d nodes left in %s\n", Pass, 
  		NumNodesLeft(graph), graph->graphName);

  if (NoOpt) {
    ClearQueue(&graph->nextEvalQueue);
    recomputeFlag = TRUE;
  }

/*******************************************************************/
/*  Check that the nextEvalQueue has nodes of the right type.
 *  (It is assumed that all the nodes in the queue are of the same type.)
/*******************************************************************/

   assert(((graph->nextEvalQueue.top == NULL) ||
	   (graph->nextEvalQueue.top->nodeType == PassType)),
	  "Wrong type of nodes in nextEvalQueue");

  if (graph->nextEvalQueue.top == NULL) { 
    recomputeFlag = FALSE;	/* CleanPending will recompute */
    switch (PassType) {
    case NET:
      CleanPendingArray(graph, NET, &graph->nextEvalQueue);
      break;
    case DEVICE:
      CleanPendingArray(graph, DEVICE, &graph->nextEvalQueue);
      break;
    }
    if (Trace) printf("Insert %d nodes into next eval queue\n",
		      graph->nextEvalQueue.size);
  }
  
/************************************************************************/
/* Relabel nodes in the nextEvalQueue
/************************************************************************/

/* If we have an EvalQueue, then allocate a larger hash table on the assumption
 * that we will not have as many collisions
 */
/*  if (recomputeFlag) */
  if (TRUE) {
    InitHashTable(graph, graph->nextEvalQueue.size);
  } else {
    InitHashTable(graph, HASHRATIO * graph->nextEvalQueue.size);
  }
  for (node = PopQueue(&graph->nextEvalQueue);
       node != NULL;
       node = PopQueue(&graph->nextEvalQueue)) {
    if (node->flag == MATCHING) {
      node->flag = PENDING;     /* Change back, but do not relabel */
    } else {
      debug(ALWAYS,
	    assert(pendingNode(node), "AssignValues: node not Pending");)
/*    if (!(pendingNode(node))) PrintNode(node); */
      if (recomputeFlag) ComputeValue(node);
    }
    EnterHash(node, graph);
  }

  debug(HASHTABLE, PrintHashTable(graph);)
  AppendUniques(graph);   	/*  append the queues of unique nodes */
  SortQueue(&graph->newUniques);
}

/*******************************************************************/
/* Compare two nodes: they are 'similar' if:
 *	1. They have the same type
 *	2. They have the same number of connections
 * Only nodes with the same node values will be checked for similarity
 *
 * Two nodes are 'identical' if they are similar and their neighbors have
 * the same node values.
/*******************************************************************/

#define similarNodes(node1, node2)	\
(((node1)->nodeType == (node2)->nodeType)   &&	\
 ((node1)->n.nodeDef == (node2)->n.nodeDef))

/*******************************************************************/
/* Use a random value when matching two nodes
/*******************************************************************/

#define newUniqueValue()  Random()

/*******************************************************************/
/*
 * MatchUniques
 * ------------
 *	Match the new unique node queues of two graphs.  The queues are
 *	assumed to be sorted so that a simple merge-match is sufficient.
 *	Nodes that do not match are BAD: their values are set to zero so that
 *	they don't pollute neighboring values.
 *
 *	  If the two corresponding nodes are similar but have different
 *	properties  a warning is issued (if PrintWarnings is true)
 *
 *      For each pair of matching nodes, deduce which neighbors must match.
 *      These are put in the nextEvalQueue.  If this is not empty, then nodes
 *      do not need to be relabeled and this process continues apace.
/*******************************************************************/

void MatchUniques(graph1, graph2)
Graph *graph1, *graph2;
{
  Queue queue1, queue2;
  register Node *node1, *node2;		/*  Index pointers */

  queue1 = graph1->newUniques;
  queue2 = graph2->newUniques;
  ClearQueue(&graph1->newUniques);
  ClearQueue(&graph2->newUniques);
  ClearQueue(&graph1->nextEvalQueue);
  ClearQueue(&graph2->nextEvalQueue);
  node1 = PopQueue(&queue1);
  node2 = PopQueue(&queue2);
  while ( (node1 != NULL) && (node2 != NULL)) {/* Neither queue empty */
    if (node1->nodeValue == node2->nodeValue) {/* Node values match */

/************************************************************************/
/* Make sure nodes match: recompute values.  This is done because we may go
 * a long time without relabelling and two nodes may still have the same
 * value even though the neighbors have been labelled differently
/************************************************************************/
    debug(DOUBLECHECK,
	 ComputeValue(node1);
	 ComputeValue(node2);
	 if (node1->nodeValue != node2->nodeValue) {
	   fprintf(stderr, "Nodes with same value do not match!!\n");
	   PrintNode(node1);
	   debug(PRINTBAD, PrintNodeNeighbors(node1);)
	     PrintNode(node2);
	   debug(PRINTBAD, PrintNodeNeighbors(node2);)
	     setBadNode(node1);
	   setBadNode(node2);
	 })
      if (badNode(node1) || badNode(node2)) {
	InsertBadNode(node1, graph1); 
	InsertBadNode(node2, graph2);
      } else { 
	node1->nodeValue = node2->nodeValue = newUniqueValue();

	/* Now try to find neighbors that we can call unique */
	if (FindMatch) LocalMatch(graph1, node1, graph2, node2);
	InsertQueue(node1,&graph1->newUniques);
	InsertQueue(node2,&graph2->newUniques);
	debug(UNIQUES,
		printf("Matched: ");
		PrintNode(node1);
		printf("	 ");
		PrintNode(node2);
		)
	}
      node1 = PopQueue(&queue1);
      node2 = PopQueue(&queue2);
    } else {
      /* Node values do not match: the node with lesser value is BAD */
      if (node1->nodeValue < node2->nodeValue) {
	/* First queue has bad node */
	debug(PRINTBAD, 
	      printf("Bad node in %s:\n", graph1->graphName); 
	      PrintNode(node1);
	      )
	setBadNode(node1);
	InsertBadNode(node1, graph1);
	node1 = PopQueue(&queue1);
      } else { /* Second queue has bad node */
	debug(PRINTBAD, 
		  printf("Bad node in %s:\n", graph2->graphName); 
		  PrintNode(node2);
		  )
	setBadNode(node2);
	InsertBadNode(node2, graph2);
	node2 = PopQueue(&queue2);
      }
    }
  }

/*******************************************************************/
/*  Finish off unmatched queues
/*******************************************************************/

    for ( ; node1 != NULL; node1 = PopQueue(&queue1))
      { setBadNode(node1);
	debug(PRINTBAD, 
	   printf("Bad node in %s:\n", graph1->graphName);
	   PrintNode(node1);
	   )
	InsertBadNode(node1, graph1);
      }

    for ( ; node2 != NULL; node2 = PopQueue(&queue2))
      { setBadNode(node2);
	debug(PRINTBAD, 
	   printf("Bad node in %s:\n", graph2->graphName); 
	   PrintNode(node2);
	 )
	InsertBadNode(node2, graph2);
      }
/*
  printf("Graph1 nextEvalQueue:");
  PrintQueue(&graph1->nextEvalQueue);
  printf("Graph2 nextEvalQueue:");
  PrintQueue(&graph2->nextEvalQueue);
*/
}

/*******************************************************************/
/*
 * extractQueue
 * ------------
 *	The input queue is assume to be sorted. 
 *	Extract the first set of nodes with the same value and return 
 *	as the result queue.
 *	(This routine can easily be optimized)
/*******************************************************************/

STATIC void extractQueue(inQueue, result)
register Queue *inQueue;
register Queue *result;
{
  register Node *tempNode;
  register int value;

  ClearQueue(result);
  if (inQueue->top != NULL) {
    value = inQueue->top->nodeValue;
    while ((inQueue->top != NULL) && (value == inQueue->top->nodeValue)) {
      tempNode = PopQueue(inQueue);
      InsertQueue(tempNode, result);
    }
  }
}
	 
/*******************************************************************/
/*
 * MatchPartitions
 * ---------------
 *	Match the non-singular partitions in the two graphs.
 *	Only the partitions with non-matching checksums need to be matched.
 *	(The PARTITIONS debug flag can force all partitions to be matched)
/*******************************************************************/

void MatchPartitions(graph1,graph2)
Graph *graph1,*graph2;
  {
    Queue partition1,
    	  partition2;
    register int index;	     
    register Bucket *bucket1, *bucket2;
    register Node *node;
    Queue stillNotQueued1,	/* Nodes that are not queued and not */ 
    	  stillNotQueued2;	/* suspect */

    debug(CHECKSUM, printf("main: checksum for %s: %d\n",
  		graph2->graphName, graph2->checkSum);  )

/*
    if (graph1->checkSum == graph2->checkSum) return;
 */
/*
    printf("Before checking Partitions\n");
    PrintHashTable(graph1);
    PrintHashTable(graph2);
*/

    for (index = 0; index < HashSize; index++)
      {	/* loop through hash table buckets */
	
        bucket1 = &graph1->hashTable[index];
	bucket2 = &graph2->hashTable[index];
	debug(CHECKSUM,
	  if ((bucket1->bucketSum != 0) || (bucket2->bucketSum != 0))
 		printf("bucketSums: %d, %d\n",
			bucket1->bucketSum, bucket2->bucketSum);
	)

	if (bucket1->bucketSum == bucket2->bucketSum) continue;

/*******************************************************************/
/*  For each entry in the hash table, append all the nodes that are
 *  not unique, sort them and compare the partitions of the two graphs
/*******************************************************************/

	ClearQueue(&stillNotQueued1);
	ClearQueue(&stillNotQueued2);

	AppendQueue(&bucket1->notUnique, &bucket1->overflow);
	ClearQueue(&bucket1->overflow);
	SortQueue(&bucket1->notUnique);

	AppendQueue(&bucket2->notUnique, &bucket2->overflow);
	ClearQueue(&bucket2->overflow);
	SortQueue(&bucket2->notUnique);

	extractQueue(&bucket1->notUnique, &partition1);
        extractQueue(&bucket2->notUnique, &partition2);
	bucket1->minPartSize = MAXINT;
	bucket2->minPartSize = MAXINT;
        while ( (partition1.top != NULL) && 
		(partition2.top != NULL) )
          { /* loop through partitions in one bucket */
	    if (partition1.top->nodeValue == partition2.top->nodeValue)
	      {	/*  values are the same */
	        if (partition1.size != partition2.size)
		  { /* sizes differ */

/*******************************************************************/
/*  Partitions have the same value but different sizes.
 *  All the nodes in both are Suspect.
/*******************************************************************/

		    setSuspectQueue(&partition1, graph1);
		    debug(SUSPECTS,
		    		printf("%s:partition found suspect:\n",
					graph1->graphName);
				PrintQueue(&partition1);
			 )

		    setSuspectQueue(&partition2, graph2);
		    debug(SUSPECTS,
		    		printf("%s:partition found suspect:\n",
					graph2->graphName);
				PrintQueue(&partition2);
			 )
		  }
		else 
		  {  /*  The partitions match: reinsert into queues */
		    node = PopQueue(&partition1);
		    node->partitionSize = partition1.size + 1;
		    if (node->partitionSize < bucket1->minPartSize) {
		      bucket1->minPartSize = node->partitionSize;
		    }
		    InsertQueue(node, &stillNotQueued1);
		    AppendQueue(&bucket1->overflow, &partition1);

		    node = PopQueue(&partition2);
		    node->partitionSize = partition2.size + 1;
		    if (node->partitionSize < bucket2->minPartSize) {
		      bucket2->minPartSize = node->partitionSize;
		    }
		    InsertQueue(node, &stillNotQueued2);
		    AppendQueue(&bucket2->overflow, &partition2);
		  }

		extractQueue(&bucket1->notUnique, &partition1);
		extractQueue(&bucket2->notUnique, &partition2);
	      }

	    else 
	      { /* partitions out of sync */
	        if (partition1.top->nodeValue < partition2.top->nodeValue)
		  { /* Partition from graph 1 is suspect */
		    setSuspectQueue(&partition1, graph1);
		    debug(SUSPECTS,
		    		printf("%s:partition found suspect:\n",
					graph1->graphName);
				PrintQueue(&partition1);
			 )
		    extractQueue(&bucket1->notUnique, &partition1);
		  }
		else

		  { /* Partition from graph 2 is suspect */
		    setSuspectQueue(&partition2, graph2);
		    debug(SUSPECTS,
		    		printf("%s:partition found suspect:\n",
					graph2->graphName);
				PrintQueue(&partition2);
			 )
		    extractQueue(&bucket2->notUnique, &partition2);
		  }		    
	      }
	   } /* end of partition loop */

/*******************************************************************/
/* Finish off unmatched partitions at end 
/*******************************************************************/

	 setSuspectQueue(&partition1, graph1);
	 setSuspectQueue(&partition2, graph2);

         setSuspectQueue(&bucket1->notUnique, graph1);
	 setSuspectQueue(&bucket2->notUnique, graph2);
	 
	 bucket1->notUnique = stillNotQueued1;
	 bucket2->notUnique = stillNotQueued2;

       } /* end of hash table loop */

/*
    printf("After checking Partitions\n");
    PrintHashTable(graph1);
    PrintHashTable(graph2);
*/
  }

/*******************************************************************/
/* EqPartition returns true if all the nodes in the partition are equivalent,
   ie. they really are connected to the same nodes.  This uses a similar hash
   function as in hash.c but the pointers are used instead of the values of
   the neighbor nodes.
/*******************************************************************/

STATIC int computeEqValue(aNode)
Node *aNode;
{
register int i;
register bigint newValue = 1;
int numConnects = NumberOfLinks(aNode);
extern int PRIMES[];

  switch (aNode->nodeType) {
    case DEVICE: 
      { register NodePt *connections = aNode->connects.netList;
	register termClass *cT = TerminalList(aNode);

	for (i = 0; i < numConnects; i++) { 
	  newValue += ((bigint) connections[i]) * PRIMES[cT[i]];
	}
      }
      break;
    case NET:
      { register DeviceConnection *connections = aNode->connects.devList;
/*	register Node *node;*/

	for (i = 0; i < numConnects; i++) {
	  newValue += ((bigint) connections[i].node)
		      * PRIMES[connections[i].class];
	}
      }
      break;
  }
  return(newValue);
}

int EqPartition(partition)
Queue *partition;
{
  register Node *node;
  register int value = computeEqValue(partition->top);
  
  for (node = partition->top->next; node != NULL; node = node->next) {
    if (value != computeEqValue(node)) {
      return (FALSE);
    }
  }
  return (TRUE);
}

/*******************************************************************/
/*  AssignMatch guesses a pair of nodes in the two graphs to match.
 *  An arbitrary node from the smallest partitions is chosen as having the 
 *  best chance of matching.  These two nodes are assigned a random value so 
 *  that labeling can continue.
 *  Although this routine does not assume that the partitions match, they will
 *  in practice since MatchPartitions is called by RelabelGraphs.
 *
 *  The two new unique nodes are then placed in the Unique queue and processed
 *  as normal new unique nodes.
 *  If there are no neighbors of the unique nodes, then the AssignMatch process
 *  is done again until there are some neighbors for the relabeling process.
 *  Nodes are taken from the notUnique queues and put back into the overflow
 *  queues.  Since the nodes are likely to be sorted the next time around,
 *  SortQueue should be able recognize this (eg. unlike quicksort)
/*******************************************************************/

int AssignMatch(graph1, graph2)
Graph *graph1, *graph2;
{
  register Node *node1, *node2;
  register Bucket *minBucket1, *minBucket2;
  register Node *firstNode;
  Queue partition1, partition2, tmpPartition;
  int index, firstIndex;
  int minSize, minValue;	/* Size of smallest partition found */
  int minIndex;			/* Bucket from which minPartitions came*/
  int success = 0;		/* Number of nodes matched */
  int size;			/* Size of partitions to be matched */

  index = RelabelGraphs(graph1, graph2);
  if (index < 0) return(0);
  if (index > 0) {
    if (Trace) {
      fprintf(stderr, "Relabeling before guessing found matching nodes: matching aborted\n");
    } else {
      fprintf(stderr, "x");
    }
    return(index);
  }

  minIndex = 0;
  while (TRUE) { /* until there are neighbors of the unique nodes */
    minSize = MAXINT;
    debug(FORCE, printf("AssignMatch: %d buckets\n", HashSize););
/************************************************************************/
/* First find the smallest partition size
 * We always start at the same bucket in which we last looked to avoid
 * painfully wending our way back to where we were if there are partitions
 * of size 2.  (We could use a heap to keep track of the smallest partitions.)
 * (Also, we should extract the partitions being matched and sort by 
 * reversed name.  This would tend to match nodes with the same suffixes.)
 ************************************************************************/
    firstIndex = index = minIndex;	/* Marks start bucket */
    do {
      minBucket1 = &graph1->hashTable[index];
      minBucket2 = &graph2->hashTable[index];
      
      /* Compute min partition sizes if not already done */
      if (minBucket1->minPartSize == MAXINT) {
	if (minBucket1->notUnique.size == 0) continue; /* Empty bucket */
	QForEach(node1, minBucket1->notUnique) {
	  if (node1->partitionSize < minBucket1->minPartSize) {
	    minBucket1->minPartSize = node1->partitionSize;
	    if (node1->partitionSize == 2) break; /* Can't be smaller */
	  }
	}
      }
      if (minBucket2->minPartSize == MAXINT) {
	if (minBucket2->notUnique.size == 0) continue;
	QForEach(node2, minBucket2->notUnique) {
	  if (node2->partitionSize < minBucket2->minPartSize) {
	    minBucket2->minPartSize = node2->partitionSize;
	    if (node2->partitionSize == 2) break;
	  }
	}
      }
      assert((minBucket1->minPartSize == minBucket2->minPartSize), 
	     "minPartSize Error");
      if (minBucket1->minPartSize < minSize) { /* Update global min size */
	minSize = minBucket1->minPartSize;
	minIndex = index;
	if (minSize == 2) break;
      }
    } while ((index = (index + 1) % HashSize) != firstIndex);

/************************************************************************/
/* minSize == MAXINT ==> no partitions left to be matched.  We are done */
/************************************************************************/
    if (minSize == MAXINT) return(success);

    if (Trace) printf("Matching nodes from partitions of size %d:\n", minSize);
    ClearQueue(&graph1->newUniques);
    ClearQueue(&graph2->newUniques);
    minBucket1 = &graph1->hashTable[minIndex];
    minBucket2 = &graph2->hashTable[minIndex];
    debug(FORCE,
	  printf("minSize = %d, minIndex = %d\n", minSize, minIndex);
	  printf("notUnique.size = %d, overflow.size = %d\n",
		 minBucket1->notUnique.size, minBucket1->overflow.size);
	  );

/* If each partition contains equivalent nodes (ie. connected to the same
   things) then all can be set to the same value

   if (EqPartition(&minPartition1) && EqPartition(&minPartition2)) {
      int value = newUniqueValue();
 */

/************************************************************************/
/* Now find a node from the smallest partition in graph 1 */
/************************************************************************/
    firstNode = PopQueue(&minBucket1->notUnique);
    node1 = firstNode;
    while (TRUE) {
      assert(node1 != NULL, "notUnique 1 empty");
      if (node1->partitionSize == minSize) break;
      InsertQueue(node1, &minBucket1->notUnique);
      node1 = PopQueue(&minBucket1->notUnique);
      assert(node1 != firstNode, "AssignMatch: Partition 1 error");
    }
    minValue = node1->nodeValue;
    ClearQueue(&partition1);
    InsertQueue(node1, &partition1);

/************************************************************************/
/* Now find a node from the matching partition in graph 2 */
/************************************************************************/
    firstNode = PopQueue(&minBucket2->notUnique);
    node2 = firstNode;
    while (TRUE) {
      assert(node2 != NULL, "notUnique 2 empty");
      if (node2->nodeValue == minValue) break;
      InsertQueue(node2, &minBucket2->notUnique);
      node2 = PopQueue(&minBucket2->notUnique);
      assert(node2 != firstNode, "AssignMatch: Partition 2 error");
    }
    ClearQueue(&partition2);
    InsertQueue(node2, &partition2);

/************************************************************************/
/* Grab the remaining nodes from the two partitions
 ************************************************************************/
    ClearQueue(&tmpPartition);
    for (node1 = PopQueue(&minBucket1->overflow); node1 != NULL;
	 node1 = PopQueue(&minBucket1->overflow)) {
      if (node1->nodeValue == minValue) {
	InsertQueue(node1, &partition1);
      } else {
	InsertQueue(node1, &tmpPartition);
      }
    }
    minBucket1->overflow = tmpPartition;

    ClearQueue(&tmpPartition);
    for (node2 = PopQueue(&minBucket2->overflow); node2 != NULL;
	 node2 = PopQueue(&minBucket2->overflow)) {
      if (node2->nodeValue == minValue) {
	InsertQueue(node2, &partition2);
      } else {
	InsertQueue(node2, &tmpPartition);
      }
    }
    minBucket2->overflow = tmpPartition;

    /* MatchBySuffix is very expensive: don't use for large partitions */
    if (UseSuffix && (PassType == NET) &&
       (minSize < 20) && MatchBySuffix(&partition1,&partition2)) {
      printf("M");		/* success */
    } else {			/* try sorting by attribute */
      InserSortQ(&partition1);
      InserSortQ(&partition2);
    }

/************************************************************************/
/* Match the two first nodes from the smallest partition
 ************************************************************************/
    node1 = PopQueue(&partition1);
    node2 = PopQueue(&partition2);

/* the following code comes from David Chenevert, dc@sobchak.Eng.Sun.COM */
/* it is activated iff the -w option is selected */
#if 0
   if ( PrintWarnings && (DEVICE == node1->nodeType) )
   if ((node1->p.property) &&
     (node1->p.property->length) && (node1->p.property->width) ) {
      Node *node2orig = node2;		/* original guess for second node */
      int length1, width1, length2, width2;
      length1 = node1->p.property->length;
      width1 = node1->p.property->width;
      while (TRUE) {
	if (node2->p.property) {
	  length2 = node2->p.property->length;
	  width2 = node2->p.property->width;
	  if ( (width2 == width1) && (length2 == length1) )
	    break;			/* matches, so accept it */
	  if ( ((fabs((float)(width2 - width1))/(float)width1) <= SizePercent)
	    && ((fabs((float)(length2 - length1))/(float)length2) <=
	    SizePercent) )
	    break;			/* within tolerance, accept it */
	} /* if */
	InsertQueue(node2, &partition2); /* poor match, try another */
	node2 = PopQueue(&partition2);
	if(node2 == node2orig) break;
      }
    }
#endif
/* end of code by David Chenevert */

    node1->nodeValue = node2->nodeValue = newUniqueValue();
    InsertQueue(node1, &graph1->newUniques);
    InsertQueue(node2, &graph2->newUniques);
    LocalMatch(graph1, node1, graph2, node2); /* Match neighbors */
    /* if (Trace) */
    printf("#");	/* Indicates nodes were matched */
    success++;
    node1 = PopQueue(&partition1);
    node2 = PopQueue(&partition2);

/*******************************************************************/
/* If the partition size was 2, then the other pair of nodes must match too 
 * Otherwise, just add the next pair to notUnique
 ************************************************************************/
    if (minSize == 2) {
      node1->nodeValue = node2->nodeValue = newUniqueValue();
      InsertQueue(node1, &graph1->newUniques);
      InsertQueue(node2, &graph2->newUniques);
      LocalMatch(graph1, node1, graph2, node2);	/* Match neighbors */
      /* if (Trace) */
      printf("#");	/* Indicates nodes were matched */
      success++;
    } else {
      node1->partitionSize = node2->partitionSize = minSize - 1;
      InsertQueue(node1, &minBucket1->notUnique);
      InsertQueue(node2, &minBucket2->notUnique);
      AppendQueue(&minBucket1->overflow, &partition1);
      AppendQueue(&minBucket2->overflow, &partition2);
    }
/************************************************************************/
/* Force recomputation of the size of the smallest partition in the bucket
 ************************************************************************/
    
    minBucket1->minPartSize = minBucket2->minPartSize = MAXINT;
    fflush(stdout);		/* Send out those messages */
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
/************************************************************************/
/* If we were able to do some local matching on the opposite node type, then
 * do another local matching:  If this does not produce anything then we
 * will continue through the partitions.  The nodes that are matched here are
 * guaranteed not to be the same type and so do not conflict with the
 * partition matching algorithm.
 ************************************************************************/
    if ((graph1->nextEvalQueue.size != 0) &&
	(graph1->nextEvalQueue.top->flag == MATCHING)) {
      PassType = ToggleType(PassType);
      LocalMatchUniques(graph1, graph2);
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
      /* If we did not find anything and must continue matching partitions
       * then reset the PassType
       */
      if ((graph1->nextEvalQueue.size + graph2->nextEvalQueue.size) == 0) {
	PassType = ToggleType(PassType);
      }
    }
/************************************************************************/
/* At this point, there will be nodes in the nextEvalQueue if:
 * 1) There are neighbors of the matched partition (but not locally matched)
 * 2) There are locally matching neighbors of locally matching neighbors of
 *    matched partition.
 * In either case we exit and continue with the normal algorithm
 ************************************************************************/
    if ((graph1->nextEvalQueue.size + graph2->nextEvalQueue.size) > 0) {
      break;
    }
    continue;
  }

/* succeeded in matching nodes: return number of nodes matched */
  return(success);
}

#ifdef DELETE
/* Debugging partitions */

WritePartitionFile(graph1, graph2)
Graph *graph1, *graph2;
{
  register Bucket *bucket;
  register int index;
  Queue partition;
  FILE *PartFile;
  int symbol = 1;
  
  PartFile = fopen("gemini.part", "w");
  RelabelGraphs(graph1, graph2);
  for (index = 0; index < HashSize; index++) {
    bucket = &graph1->hashTable[index];
    AppendQueue(&bucket->notUnique, &bucket->overflow);
    ClearQueue(&bucket->overflow);
    SortQueue(&bucket->notUnique);
    for (extractQueue(&bucket->notUnique, &partition);
         partition.size != 0;
	 extractQueue(&bucket->notUnique, &partition)) {
      fprintf(PartFile, "DS %d;\nL NX;\n", symbol++);
      MagicOutQueue(PartFile, &partition);
      fprintf(PartFile, "DF;\n");
    }
  }
  for (index = 1; index < symbol; index++) {
    fprintf(PartFile, "C %d;\n", index);
  }
  fprintf(PartFile, "End\n");
  fclose(PartFile);
}
#endif /* DELETE */

/************************************************************************/
/* This procedure is used when there are locally matched nodes to be
 * processed.  These are presumed in order, but not sorted.  We will never
 * find unmatched nodes.  These matched nodes start out in the nextEvalQueues
 * and are first turned into Unique nodes while at the same time performing
 * more local matching.
/************************************************************************/

void LocalMatchUniques(graph1, graph2)
Graph *graph1, *graph2;
{
  Queue queue1, queue2;
  register Node *node1, *node2;		/*  Index pointers */

  if (Trace) printf("LocalMatchUniques\n");
/*  printf("nextEvalQueue1: %d, nextEvalQueue2: %d\n",
	 graph1->nextEvalQueue.size, graph2->nextEvalQueue.size);
*/
  queue1 = graph1->nextEvalQueue;
  queue2 = graph2->nextEvalQueue;
  ClearQueue(&graph1->newUniques);
  ClearQueue(&graph2->newUniques);
  ClearQueue(&graph1->nextEvalQueue);
  ClearQueue(&graph2->nextEvalQueue);

  node1 = PopQueue(&queue1);
  node2 = PopQueue(&queue2);
  while ( (node1 != NULL) && (node2 != NULL)) {
/*    printf("LM: %d, %d\n", node1->nodeValue, node2->nodeValue);*/
    /* Neither queue empty */
    if ((node1->nodeValue != node2->nodeValue)) {
      fprintf(stderr, "LocalMatchUniques: Nodes do not match??\nPanic Halt\n");
      PrintNode(node1);
      PrintNode(node2);
/*      exit(1);*/
    }
    node1->nodeValue = node2->nodeValue = newUniqueValue();

    /* Now try to find neighbors that we can call unique */
    if (FindMatch) {
      LocalMatch(graph1, node1, graph2, node2);
    }
    InsertQueue(node1,&graph1->newUniques);
    InsertQueue(node2,&graph2->newUniques);
    debug(UNIQUES,
	  printf("Matched: ");
	  PrintNode(node1);
	  printf("	 ");
	  PrintNode(node2);
	  );
    node1 = PopQueue(&queue1);
    node2 = PopQueue(&queue2);
  }
  if ((node1 != NULL) || (node2 != NULL)) {
    printf("Local Match Error: Queues are not empty!!!\n");
    exit(1);
  }
}
