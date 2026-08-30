/*
$Id: alloc.c,v 2.5 1993/04/24 03:51:09 mckenzie Exp $
*/
/*******************************************************************/
/* This file contains a swifter allocation routine base on the fact that 
 * we never free storage
/*******************************************************************/


/*******************************************************************/
/*
 *	COPYRIGHT (C) 1988  Carl Ebeling
 *	COPYRIGHT (C) 1983  Carl Ebeling and Ofer Zajicek
 *
/*******************************************************************/

/*******************************************************************/
/*
 *  HISTORY
 *
/*******************************************************************/


#include "gemini.h"
#include <ctype.h>
extern char CharTran[256];


/*******************************************************************/
/* An alternative to malloc: space is not released however.
 * FastAlloc should only be used for getting small pieces of storage.
 * And for storage that cannot be released.
/*******************************************************************/

static char *storeBuffer = NULL;
static int storeSize = 0;
#define STORE_INCREMENT (1<<18)	     /* 256K increments */
#define INT_ALIGN (sizeof(void *)-1) /* sizeof(void*) must be a power of 2 */

char *FastAlloc(size)
register unsigned int size;
{
  register char *result;
  int flag;

  if (storeSize < size) {
    storeSize = (size > STORE_INCREMENT) ? size : STORE_INCREMENT;
#ifdef USE_SBRK
    storeBuffer = sbrk(storeSize);
    flag = ((int)storeBuffer) < 0;
#else
    storeBuffer = (char *) malloc(storeSize);
    flag = storeBuffer == NULL;
#endif
    if (flag) {
      fprintf(stderr, "FastAlloc unable to allocate sufficient memory\n");
      fprintf(stderr, "Use the limit datasize command to increase allocation\n");
      exit(1);
    }
  }
  result = storeBuffer;
  size = (size + INT_ALIGN) & ~INT_ALIGN;	/* Round up to int align */
  storeBuffer += size;
  storeSize -= size;
  return result;
}

/*******************************************************************/
/* Allocate and initialize space for a graph
 * ReadGraph actually allocates and reads the device and net vectors.
/*******************************************************************/

  Graph *AllocGraph()
{
  Graph *result = (Graph *) FastAlloc((unsigned) sizeof(Graph));
  
  result->graphName = NULL;
  result->hashTable = NULL;
  result->checkSum = 0;
  ClearQueue(&result->newUniques);
  ClearQueue(&result->nextEvalQueue);
  result->lastUniquePass = 0;
  ClearQueue(&result->devices);
  ClearQueue(&result->nets);	
  result->deviceVector = result->netVector = NULL;
  result->numDevices = result->numNets = 0;
  result->pendingDevices = result->pendingNets = NULL;
  result->numPendingDevices = result->numPendingNets = 0;
  ClearQueue(&result->uniqueDevices);
  ClearQueue(&result->uniqueNets);
  ClearQueue(&result->suspectDevices);
  ClearQueue(&result->suspectNets);
  ClearQueue(&result->badDevices);
  ClearQueue(&result->badNets);
  return(result);
}

/*******************************************************************/
/* Allocate space for and save a copy of a string: use with care since space
 * can be wasted.  Use strcpy for ordinary copies.
 * This routine assumes that there is enough space: if there isn't then it
 * allocates enough and starts over.
 * Note that this puts strings on their own pages.
/*******************************************************************/

static char *stringBuffer = NULL;
static int stringSpace = 0;
#define STRING_INCREMENT 8192

char *CopyString(string)
char *string;
{
char *result = stringBuffer;
register int space = stringSpace;
register char *oldString;
register char *newString = stringBuffer;

  oldString = string;
  while (TRUE)
    { while ((--space >= 0) && ((*newString++ = *oldString++) != '\0')) ;
      if (space >= 0) break;
      result = (char *) malloc((unsigned) STRING_INCREMENT);
      if (result == NULL) {
	  fprintf(stderr, "CopyString unable to allocate sufficient memory\n");
	  exit(1);
	}
      space = STRING_INCREMENT;
      oldString = string;
      newString = result;
    }
  stringSpace = space;
  stringBuffer = newString;
  return(result);
}

int casestreq(s1, s2)
register char *s1, *s2;
{
  while (*s1 || *s2) {
    if (*s1 != *s2) {	/* Assume case matches */
      if (CharTran[*s1] != CharTran[*s2]) return FALSE;
    }
    s1++, s2++;
  }
  return TRUE;
}

int nocasestreq(s1, s2)
register char *s1, *s2;
{
  while (*s1 || *s2) {
    if (*s1++ != *s2++) return FALSE;
  }
  return TRUE;
}

void InitCharTran()
{
  register int i;

  if (CaseFold)		/* set up pointer to comparison function */
    Streq = casestreq;
  else
    Streq = nocasestreq;
  for (i = 0; i < 256; i++) {
    if (CaseFold && (i >= 'A') && (i <= 'Z')) {
      CharTran[i] = tolower(i);
    } else {
      CharTran[i] = i;
    }
  }
  pCharTran = CharTran;
}
