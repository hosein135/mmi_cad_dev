/*
$Id: queue.c,v 2.7 1993/12/17 04:49:32 mckenzie Exp mckenzie $
*/
/*******************************************************************/
/* Routines to manage the Queues used by gemini
/*******************************************************************/


/*******************************************************************/
/*
 *	COPYRIGHT (C) 1983  Carl Ebeling and Ofer Zajicek
 *	COPYRIGHT (C) 1988  Carl Ebeling
 *
/*******************************************************************/


/*******************************************************************/
/* HISTORY
 * 19-Jan-83  Ofer Zajicek (saffron) at Carnegie-Mellon University
 *	SortQueue is now Quick Sort.
 * 16-Mar-84  Carl Ebeling at CMU
 *	Fixed InserSortQ to check for NULL queue
 *	Changed SortQueue so that a sorted queue will not cause in
 *		N**2 behavior.
/*******************************************************************/

#include "gemini.h"
#include <ctype.h>

/*******************************************************************/
/* Check the consistency of a queue
/*******************************************************************/

int QueueOK(queue)
register Queue *queue;
{
  register Node *node;
  register Node *bottomNode = NULL;
  register int count;

  count = 0;
  for (node = queue->top; node != NULL; node = node->next)
      { 
	bottomNode = node;
	count++;
	if (count > queue->size) break;
      }

  if (count != queue->size) return(FALSE);
  if (bottomNode != queue->bottom) return(FALSE);
  return(TRUE);
}

/*******************************************************************/
/* Allocate a new queue and return its value
/*******************************************************************/

Queue *NewQueue()
{
  Queue *result = (Queue *) (malloc((unsigned) sizeof(struct Queue)));
  result->top = result->bottom = NULL;
  result->size = 0;
  return result;
}

#define SUFFIXLENGTH 15

/************************************************************************/
/* Compare the suffixes of two strings, ignoring special chars and case
 * This is used to divine whether two names from different circuits might
 * be the same.  (Why suffix?  Well it's easier than trying to compute the
 * distance between two strings and suffixes tend to be same.)
 ************************************************************************/

STATIC short cmpSuffix(str1, len1, str2, len2)
register char *str1, *str2;
int len1, len2;
{
  register int i;
  register char *s1, *s2;
  register char *limit;
  char c1, c2;

/*  fprintf(stderr, "%s=?=%s\n", str1, str2); */
  s1 = str1 + len1;
  s2 = str2 + len2;
  while (TRUE) {
    c1 = 0;
    while (len1--) {		/* Get next rightmost significant char */
      if (isalnum(*(--s1))) {
	c1 = isupper(*s1) ? tolower(*s1) : *s1;
	break;
      }
    }
    c2 = 0;
    while (len2--) {		/* Get next rightmost significant char */
      if (isalnum(*(--s2))) {
	c2 = isupper(*s2) ? tolower(*s2) : *s2;
	break;
      }
    }
    if ((c1 == 0) || (c2 == 0) || (c1 == c2)) 
      return 0; /* Matched to end of one string */
    if (c1 < c2) return -1;
    if (c1 > c2) return 1;
  }
}

/*******************************************************************/
/* Look through the two queues for two suffixes that match.
 * This is quadratic in the length of the queues!!
 * Return value: TRUE if a match is found and FALSE otherwise.
 *******************************************************************/

int MatchBySuffix(queue1, queue2)
Queue *queue1, *queue2;
{
  register Node *trail1, *trail2;
  register Node *node1, *node2;
  size_t len1;

  for (trail1 = NULL,
       node1 = queue1->top;
       node1 != NULL;
       trail1 = node1,
       node1 = node1->next) {
    len1 = strlen(node1->name); /* Do not recompute */
    for (trail2 = NULL,
	 node2 = queue2->top;
	 node2 != NULL;
	 trail2 = node2,
	 node2 = node2->next) {
      if (!cmpSuffix(node1->name, len1, node2->name, strlen(node2->name))) {
	if (trail1 != NULL) {
	  trail1->next = node1->next;
	  node1->next = queue1->top; /* Insert node1 at front of queue */
	  queue1->top = node1;
	  if (queue1->bottom == node1)
	    queue1->bottom = trail1;
	}
	if (trail2 != NULL) {
	  trail2->next = node2->next;
	  node2->next = queue2->top; /* Insert node2 at front of queue */
	  queue2->top = node2;
	  if (queue2->bottom == node2)
	    queue2->bottom = trail2;
	}
	return TRUE;
      }
    }
  }
  return FALSE;
}

/*******************************************************************/
/* Sort a Queue using insertion sort
/*******************************************************************/

void InserSortQ(queue)
register Queue *queue;
{
  register Node *uNode;
  Queue newQueue;
  register Node *nodePt;
  long attrib1, attrib2;
  short doit;

  if (queue->size == 0) return;	/* Fix CE (3/16/84) */
  newQueue.size =  queue->size;
  newQueue.top = newQueue.bottom = PopQueue(queue);
/* Fix CE (3/16/84) */
  debug(ALWAYS, assert( newQueue.top != NULL, "InserSorting a NULL Queue!!"))
  newQueue.top->next = NULL;

  for (uNode = PopQueue(queue); uNode != NULL; uNode =  PopQueue(queue)) {
/*  insert the node in the new queue in order */
/*    if (uNode->nodeValue >= newQueue.bottom->nodeValue)  */
    if (uNode->p.property != NULL) {
      attrib1 = (uNode->nodeType == DEVICE) ?
        (long) uNode->p.property->width : uNode->p.netprop->capacitance;
    } else {
      attrib1 = 0;
    }
    doit = (uNode->nodeValue > newQueue.bottom->nodeValue);
    if (!doit && (uNode->nodeValue == newQueue.bottom->nodeValue)) {
      if (newQueue.bottom->p.property != NULL) {
        attrib2 = (newQueue.bottom->nodeType == DEVICE) ?
          (long) newQueue.bottom->p.property->width :
	  newQueue.bottom->p.netprop->capacitance;
      } else {
        attrib2 = 0;
      }
      doit = (attrib1 <= attrib2);
    }
    if (doit) {
      newQueue.bottom->next = uNode;
      newQueue.bottom = uNode;
      uNode->next = NULL;
      continue;
    }
    doit = (uNode->nodeValue < newQueue.top->nodeValue);
    if (!doit && (uNode->nodeValue == newQueue.top->nodeValue)) {
      if (newQueue.top->p.property != NULL) {
        attrib2 = (newQueue.top->nodeType == DEVICE) ?
          (long) newQueue.top->p.property->width :
	  newQueue.top->p.netprop->capacitance;
      } else {
        attrib2 = 0;
      }
      doit = (attrib1 > attrib2);
    }

    if (doit) {
      uNode->next = newQueue.top;
      newQueue.top = uNode;
      continue;
    }
    nodePt = newQueue.top;             /* always not NULL */
    while (1) {
      if (nodePt->next == NULL)
	break;
      doit = (uNode->nodeValue > nodePt->next->nodeValue);
      if (!doit && (uNode->nodeValue == nodePt->next->nodeValue)) {
        if (nodePt->next->p.property != NULL) {
          attrib2 = (nodePt->next->nodeType == DEVICE) ?
            (long) nodePt->next->p.property->width :
	    nodePt->next->p.netprop->capacitance;
        } else {
          attrib2 = 0;
        }
        doit = (attrib1 < attrib2);
      }
      if (!doit)
	break;
      nodePt = nodePt->next;
    }
    uNode->next = nodePt->next;
    nodePt->next = uNode;
  }
  queue->top = newQueue.top;
  queue->bottom = newQueue.bottom;
  queue->size = newQueue.size;
/*
  assert(QueueOK(queue), "InsertSortQ mangled a queue");
 */
}

/*******************************************************************/
/* Sort a Queue using quick sort
 * This has been changed extensively. (CE 3/16/84)
/*******************************************************************/
void SortQueue(queue)
register Queue *queue;
{
/*
  int minValue1, minValue2, maxValue1, maxValue2;
  Node *minNode1, *minNode2, *maxNode1, *maxNode2;
*/
  int sorted1, sorted2;
  unsigned int lastValue1, lastValue2;
  register unsigned int partitionValue;
  Queue LessQ,MoreQ;
  register Node *aNode;
      
  if (queue->size <= 1) {
    return;
  } else if (queue->size <= INSERT_SORT_SIZE ) {
    InserSortQ(queue);
    return;
  } else {
    ClearQueue(&LessQ);
    ClearQueue(&MoreQ);

/************************************************************************/
/* Change the way the partitioning is done: Take the average of the first and 
 * last values in the list, instead of simply the first value.  This should 
 * take care of an almost sorted list which blows quicksort away.
 * Also check whether the split queues are already sorted.
 ************************************************************************/
    partitionValue = queue->top->nodeValue/2 + queue->bottom->nodeValue/2;
    sorted1 = sorted2 = TRUE;
    lastValue1 = lastValue2 = 0;
/* If the values are the same, make sure that one of the queues is not empty */
    if (queue->top->nodeValue == queue->bottom->nodeValue) {
      aNode = PopQueue(queue);
      partitionValue = lastValue2 = aNode->nodeValue;
      InsertQueue(aNode, &MoreQ);	/* Make sure MoreQ is not Empty */
    }
    while ((aNode = PopQueue(queue)) != NULL) {
      if (aNode->nodeValue <= partitionValue ) {
	if (aNode->nodeValue < lastValue1) sorted1 = FALSE;
	lastValue1 = aNode->nodeValue;
	InsertQueue(aNode, &LessQ);
      } else { /* Insert into second queue */
	if (aNode->nodeValue < lastValue2) sorted2 = FALSE;
	lastValue2 = aNode->nodeValue;
	InsertQueue(aNode, &MoreQ);
      }
    }
    if (! sorted1) {
      debug(ALWAYS, assert(MoreQ.size > 0, "SortQueue does not converge"))
/*      if (MoreQ.size <= 0) PrintQueue(&LessQ);*/
      if (LessQ.size > 1) SortQueue(&LessQ);
    }
    if (! sorted2) {
      debug(ALWAYS, assert(MoreQ.size > 0, "SortQueue does not converge"))
/*      if (MoreQ.size <= 0) PrintQueue(&MoreQ);*/
      if (MoreQ.size > 1) SortQueue(&MoreQ);
    }
    AppendQueue(&LessQ,&MoreQ);
    queue->top = LessQ.top;
    queue->bottom = LessQ.bottom;
    queue->size = LessQ.size;
    /* 
      assert(QueueOK(queue), "SortQueue: Bad result Queue");
      */
    debug (SORT, printf("SortQueue: The sorted queue\n");PrintQueue(queue);)
  }
}

/*
	Removes a node from a queue. 
 */
void removeFromQueue(queue, node)
Queue *queue;
Node *node;
{
  assert( (queue != NULL) && (node != NULL), 
    "removeFromQueue: Null pointer received");
  if ((queue == NULL) || (node == NULL)) return;
  if (queue->top == NULL) return;
  if (queue->top == node) {
    queue->top = node->next;
    queue->size --;
  } else {
    register Node *previous = queue->top;

    while ((previous->next != node) && (previous->next != NULL))
      previous = previous->next;
    if (previous->next == node) {
      previous->next = node->next;
      queue->size --;
      if (previous->next == NULL) queue->bottom = previous;
    }
  }
  if (queue->top == NULL) queue->bottom = NULL;
}


/*******************************************************************/
/* Insert a node at the end of a Queue of nodes.
/*******************************************************************/

InsertQueue(newNode, queue)
Node *newNode;
register Queue *queue;
{
    InsertQ(newNode, queue);
}

#ifdef SLOWQUEUE
	 
/*******************************************************************/
/*  Returns the node at the head of the queue.
/*******************************************************************/

Node *PopQueue(queue)
register Queue *queue;
{
register Node *new;

  if (queue->top == NULL) return NULL;
  queue->numberOfElememts--;
  new = queue->top;
  queue->top = queue->top->next;
  if (queue->top == NULL) queue->bottom = NULL;  /*  the queue is empty  */
  return(new);
}

/*******************************************************************/
/* Append the second Queue onto the end of the first Queue
/*******************************************************************/

AppendQueue(first, second)
register Queue *first, *second;
{
  if (second->top == NULL) return;	/* Null queue to append */
  first->size += second->size;
  if (first->top == NULL)
    {
      first->top = second->top;
      first->bottom = second->bottom;
    }
  else
    {
      first->bottom->next = second->top;
      first->bottom = second->bottom;
    }
}
#endif
