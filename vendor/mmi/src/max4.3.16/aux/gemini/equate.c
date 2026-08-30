/*
$Id: equate.c,v 2.7 1993/12/17 04:49:32 mckenzie Exp mckenzie $
*/
/*******************************************************************/
/*
 *	COPYRIGHT (C) 1988  Carl Ebeling
 *
/*******************************************************************/

/*******************************************************************/
/*
 * HISTORY
 *  4-May-84  Carl Ebeling (ce) at Carnegie-Mellon University
 *	Changed the equate file semantics so that the first name on the
 *	line names a node in the first circuit (first on command line)
 *	and the second name, a node in the second circuit.  I couldn't
 *	figure whether the original method meant anything.
 *
 *  7-Apr-84  Carl Ebeling (ce) at Carnegie-Mellon University
 *	Created.
/*******************************************************************/

/*******************************************************************/
/* This file maintains a simple hash table that is used to equate names
 * via a equated names file.  The first name on the line names a node in the
 * first circuit, and the second name a node from the second.  Both names are
 * given the same random value.
 * We assume that only a few names are actually entered.
/*******************************************************************/

#include <ctype.h>
#include "gemini.h"

typedef struct eqNamesStruct {
  char *name;			/* The name equated */
  short circuit;		/* Which circuit? */
  short used;			/* Flags whether name was used */
  int hashValue;		/* The hash value for speed */
  int value;			/* The random value of the name */
  struct eqNamesStruct *next;
} eqNames;

static eqNames **hashTable;
static int hashSize;
static int anyEquates = FALSE;	/* Turn on if there is an equate file */

STATIC void initEqHash(size)
register int size;
{
  hashTable = (eqNames **) malloc((unsigned) size * sizeof(eqNames *));
  hashSize = size;
  while (size) {
    hashTable[--size] = NULL;
  }
  anyEquates = TRUE;
}

STATIC unsigned int hash(name)
register unsigned char *name;
{
  register unsigned int value = 0;

  if (CaseFold) {
    while (*name) {
      value = (value << 1) + pCharTran[*name++];
    }
  } else {
    while (*name) value = (value << 1) + *name++;
  }
  return (value % hashSize);
}

int InsertEqName(name, circuit, value)
register unsigned char *name;
int circuit, value;
{
  register unsigned int hashValue = hash((unsigned char *) name);
  register eqNames *p;
  
  debug(EQUATE,
    printf("Inserting %s into %d:", name, circuit);
  )
  for (p = hashTable[hashValue]; p != NULL; p = p->next) {
    if ((p->hashValue == hashValue) &&
    	(p->circuit == circuit) &&
	(* Streq)(p->name, name)) {
      return(FALSE);		/* Insert failed */
    }
  }
  p = (eqNames *) malloc((unsigned) sizeof(eqNames));
  p->next = hashTable[hashValue];
  hashTable[hashValue] = p;
  p->hashValue = hashValue;
  p->name = CopyString((char *) name);
  p->circuit = circuit;
  p->used = FALSE;
  p->value = value;
  debug(EQUATE, printf("OK\n");)
  return(TRUE);			/* Insert succeeded */
}

int FindEqName(name, circuit)
char *name;
int circuit;
{
  register unsigned int hashValue;
  register eqNames *p;
  
  if (! anyEquates) return (FALSE);
  debug(EQUATE, printf("Finding %s in %d:", name, circuit);)
  hashValue = hash((unsigned char *) name);
  for (p = hashTable[hashValue]; p!= NULL; p = p->next) {
    if ((p->hashValue == hashValue) &&
    	(p->circuit == circuit) &&
    	(* Streq)(p->name, name)) {
      p->used = TRUE;		/* Name was touched */
      debug(EQUATE, printf("OK\n");)
      return(p->value);
    }
  }
debug(EQUATE, printf("Not found\n");)
  return (FALSE);		/* No value */
}

/*******************************************************************/
/* Read the equate file and enter the equated names into the hash table
/*******************************************************************/

void ReadEqFile(EqFileName)
char *EqFileName;
{
  FILE *EqFilePtr;
  char buffer[BUFSIZE];
  char *line;
  unsigned char *arg;
  int randValue;

  initEqHash(1000); 	/* ?? This constant obviously should be fixed */
  randValue = Random();
  InsertEqName(NO_CONNECT_NAME, 1, randValue);
  InsertEqName(NO_CONNECT_NAME, 2, randValue);

  if (EqFileName == NULL) {
    return;
  }
  if ((EqFilePtr = fopen(EqFileName, "r")) == NULL) {
    fprintf(stderr,
        "The file '%s' cannot be read and is being ignored.\n", EqFileName);
    return;
  }
  while ((line = fgets(buffer, sizeof(buffer), EqFilePtr)) != NULL) {
    if (*line == ';') continue;
    if (*line == '\n') continue;
    if (*line != '=') {
      fprintf(stderr, "Format error in equate file %s:\n", EqFileName);
      fprintf(stderr, "\t%s", line);
      continue;
    }
    randValue = Random();
    line++;
    arg = nxtarg((unsigned char **) &line, WHITESPACE);
    if (*arg == '\0') {
      fprintf(stderr, "Format error in equate file\n");
      break;
    }
    if (!InsertEqName(arg, 1, randValue)) {
      fprintf(stderr, "Duplicate equate name for circuit 1: %s\n", arg);
    }
    arg = nxtarg((unsigned char **) &line, WHITESPACE);
    if (*arg == '\0') {
      fprintf(stderr, "Format error in equate file\n");
      break;
    }
    if (!InsertEqName(arg, 2, randValue)) {
      fprintf(stderr, "Duplicate equate name for circuit 2: %s\n", arg);
    }
  }
  fclose(EqFilePtr);
}

/* Check whether all the equated names were used */
/* ignore 'No connect' */

void CheckEquates()
{
  register int i;
  register eqNames *p;
  
  for (i = 0; i < hashSize; i++) {
    for (p = hashTable[i]; p != NULL; p = p->next) {
      if (! p->used && strcmp(p->name,NO_CONNECT_NAME)) {
	printf("Warning: equate name \"%s\" from circuit %d not used\n",
		p->name, p->circuit);
      }
    }
  }
}
