/*
$Id: queue.h,v 2.6 1993/09/02 00:21:18 mckenzie Exp $
*/
/*******************************************************************/
/* Structure definition and macros for Queues
/*******************************************************************/

/*******************************************************************/
/*
 *	COPYRIGHT (C) 1983  Carl Ebeling and Ofer Zajicek
 *	COPYRIGHT (C) 1988  Carl Ebeling
 *
/*******************************************************************/


/*******************************************************************/
/* HISTORY
/*******************************************************************/

/*******************************************************************/
/* Structure for a Queue of Nodes
/*******************************************************************/

typedef struct Queue
   { struct Node *top, *bottom;
     int size;
   } Queue;

/************************************************************************/
/* Define a Queue iterator
 ************************************************************************/
#define QForEach(element, queue)	\
  for (element = queue.top; element != NULL; element = element->next)


/*******************************************************************/
/* Set a Queue to null
/*******************************************************************/

#define ClearQueue(queue)			\
  (queue)->top = (queue)->bottom = NULL,	\
  (queue)->size = 0

/*******************************************************************/
/* Insert a node at the end of a Queue of nodes.
/*******************************************************************/

#define InsertQ(newNode, queue)			\
{ (newNode)->next = NULL;			\
  (queue)->size++;				\
  if ((queue)->bottom == NULL)			\
      (queue)->bottom = (queue)->top = newNode;	\
  else 						\
    { (queue)->bottom->next = newNode;		\
      (queue)->bottom = newNode;		\
    }						\
}
	 
/*******************************************************************/
/*  Returns the node at the head of the queue.
/*******************************************************************/

/* Temporary pointer to allow macro to return value */
static struct Node *__queueTMP;

#define PopQueue(queue)					\
( ((__queueTMP = (queue)->top) == NULL) ? __queueTMP :	\
  (((queue)->size--,					\
    ((queue)->top = (queue)->top->next) == NULL) ? 	\
     ((queue)->bottom = NULL, __queueTMP) : __queueTMP ))

/*******************************************************************/
/* Append the second Queue onto the end of the first Queue
/*******************************************************************/

#define AppendQueue(first, second)		\
{ if ((second)->top != NULL)			\
  { (first)->size += (second)->size;		\
    if ((first)->top == NULL)			\
	 (first)->top = (second)->top;		\
    else (first)->bottom->next = (second)->top;	\
    (first)->bottom = (second)->bottom;		\
  }}
#define INSERT_SORT_SIZE 7
