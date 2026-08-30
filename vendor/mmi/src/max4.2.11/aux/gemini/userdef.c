/*
$Id: userdef.c,v 2.7 1993/12/17 04:49:32 mckenzie Exp mckenzie $
*/
/*******************************************************************/
/*
 *	COPYRIGHT (C) 1993  Carl Ebeling and Neil McKenzie
 *
/*******************************************************************/

/*******************************************************************/
/* This program reads in user defined devices.
/*
/* To denote equivalence classes (symmetry), the same name is used
/* to denote multiple pins in the device definition.  Example: drain
/* and source in an N-type transistor are symmetrical.
/*
/* Format:
/*	DEFINE usertype pin1 pin2 ...
/*
/* Example:
/*	DEFINE xornor in in out1 out2
/*
/* Instantiation of user defined device:
/*	xornor a b x y ; this is a comment
/*
/* Restrictions:
/*	Max # of pins is NUMTERMINALS
/*
/*******************************************************************/

/*******************************************************************/
/*
 * HISTORY
 *
 * 3-9-1993  Neil McKenzie.   Created.
 *
/*******************************************************************/

/* include files */
#include "gemini.h"

#define NUMTERMINALS 1024
#define LINESIZE 4096
#define UDError printf("Fatal error at line %d: ",linenum)

int num_userdefs = 0;

/* data structures */
typedef struct TAGGED_TYPE {
    long hval;
    short index;
    short weight;
    unsigned char *string;
} TAGGED_TYPE;

/* this is a simple hash function that uses only xors and shifts */
unsigned long
SimpleHash(buf)
unsigned char *buf;
{
  short i;
  unsigned long h1 = 0, h2 = 0;

  for (i=0; buf[i]; i++) {
    h1 ^= (unsigned long) toupper(buf[i]);
    h1 <<= 1;
    h2 ^= (unsigned long) toupper(buf[i]);
  }
  return h1 ^ (h2 << 16);
}

/*
** comphval and compindex are used by qsort to sort the argument list
** in the DEFINE statement.  If the strings hash to the same value,
** the strings are compared to ensure that the strings are indeed equal
** and not the result of a hash collision.
** If they hash to different values, they must be different.
*/
int comphval(x,y)
TAGGED_TYPE *x;
TAGGED_TYPE *y;
{
    int r = x->hval - y->hval;

    if (r)
      return r;
    return strncasecmp((char *)x->string, (char *)y->string,LINESIZE);
}

int compindex(x,y)
TAGGED_TYPE *x;
TAGGED_TYPE *y;
{
    return x->index - y->index;
}

/*
** UserDefLine: enter or verify user-defined device (don't instantiate yet)
** Input: argument count
** Input: argument vector representing line of input
** Input: line number (for error reporting)
** Returns: nothing
** Side effect: enters or verifies a type in DeviceDefs[]
** Error report: illegal format, consistency mismatch
*/
void
UserDefLine(numargs, devargs, linenum)
int numargs;
unsigned char *devargs[LINESIZE];
int linenum;
{
  TAGGED_TYPE sortarray[NUMTERMINALS];	/* array for determining pin weights */
  int i = 0;				/* all purpose index variables */
  int j = 0;
  int ac;				/* arg count for pins; ac=numargs-2 */
  int nn;
  static short firsttime = 1;

  if (firsttime) {
    firsttime = 0;
    printf("User-defined device types:\n");
  }
  if (NumDeviceDefs >= MAXDEVICETYPES) {
    UDError;
    printf("too many user-defined devices.\n");
    longjmp(env,1);
  }
  if (numargs < 3) {
    UDError;
    printf("empty DEFINE statement.\n");
    longjmp(env,1);
  }
  if (strlen((char *)devargs[1]) < 2) {
    UDError;
    printf("User-defined device type '%s' is illegal.\n", devargs[1]);
    printf("User-defined type names must have two or more characters.\n");
    longjmp(env,1);
  }
  for (ac=0; ac<numargs-2; ac++) {
    sortarray[ac].string = devargs[ac+2];/* skip DEFINE and devtype */
    sortarray[ac].weight = ac;
    sortarray[ac].index = ac;
    sortarray[ac].hval = SimpleHash(sortarray[ac].string);
  }

/* sort the array to put similar strings next to each other */
  qsort(sortarray, ac, sizeof(TAGGED_TYPE), comphval);

/*
** if the strings in adjacent entries match,
** make sure the weights are identical
*/
  for (i=0; i<ac-1; i++) {
    if (!comphval (&sortarray[i], &sortarray[i+1]))
      sortarray[i+1].weight = sortarray[i].weight;
  }

/* sort the array by index, to put it back into the original order */
  qsort(sortarray, ac, sizeof(TAGGED_TYPE), compindex);

#ifdef DEBUG
  printf("%12s: ",devargs[1]);
/* print weights to verify proper functionality */
  for (i=0; i<ac; i++) printf("%d ", sortarray[i].weight); printf("\n");
#endif

  nn = num_userdefs + NUMBERTYPES;
/* perform linear search through DeviceDefs to match device name */
  for (i=NUMBERTYPES; i<nn; i++) {
    if (strncasecmp((char *)devargs[1],DeviceDefs[i].name,LINESIZE)) {
      continue;
    } else {  /* got a match: verify */
      if (DeviceDefs[i].numTerminals != ac) {
	UDError;
	printf("inconsistent pin counts for user-defined type '%s'.\n",
	  devargs[1]);
	longjmp(env,1);
      }
      for (j=0; j<ac; j++) {
        if (DeviceDefs[i].terminals[j] != sortarray[j].weight) {
	  UDError;
	  printf("inconsistent pin names for user-defined type '%s'.\n",
	    devargs[1]);
	  longjmp(env,1);
	}
      }
    }
    return;		/* good match, no errors */
  }
/*
** no match: therefore it's a new definition.
** don't allow if transistor chains have already been collapsed,
** because the device data structures would get hosed.
*/
  if (NumDeviceDefs > (num_userdefs + NUMBERTYPES)) {
    printf("Warning: ignoring definition of '%s'.\n", devargs[1]);
    printf("All definitions must appear first in the first input file.\n");
    return;
  }
  DeviceDefs[nn].name = CopyString((char *)devargs[1]);
  DeviceDefs[nn].numTerminals = ac;
  DeviceDefs[nn].terminals = (termClass *)
    FastAlloc((unsigned)
      DeviceDefs[nn].numTerminals * sizeof(termClass));
  for (i=0; i<ac; i++) {
    DeviceDefs[nn].terminals[i] = sortarray[i].weight;
  }
  printf("%12s: ID %d, %d pins\n", devargs[1],NumDeviceDefs,ac);
  NumDeviceDefs++;	/* to keep consistent with chains.c */
  num_userdefs++;
}

/*
**  Test for match of device name to user defined name
**  If match is good, create an instance of the device,
**  otherwise report that device type does not exist.
**  Inputs: buf = pointer to line from input file
**          p_index = pointer to device identifier
**  Outputs: none
**  Side effects: add new device to device queue
**                increment *p_index
*/
void
MatchUserDef(buf, linenum, p_index)
unsigned char *buf;
int linenum;
int *p_index;
{
  unsigned char *devargs[LINESIZE];	/* ptrs to args in line buffer */
  unsigned char mybuf[BUFSIZE];		/* scratchpad */
  int nn = num_userdefs + NUMBERTYPES;
  int i;
  int ac = 0;				/* argument count */
  int devtype;
  Device *device;
  Net *net;
  SIMdevConnect *connect;

  strncpy((char *)mybuf, (char *)buf, BUFSIZE);
  mybuf[BUFSIZE-1] = 0;			/* null terminate to be sure */
  devargs[0] = (unsigned char *) strtok((char *)mybuf, " \t");
					/* get and ignore first token */
  if (devargs[0] == NULL) {
    return;				/* null statement */
  }
/* use strtok to create pointers to all args in the line */
  while (devargs[ac] != NULL) {
    if (devargs[ac][0] == ';') {
      break;
    }
    ac++;
    devargs[ac] = (unsigned char *) strtok(NULL, " \t\n");
  }
  if (ac < 2) {
    UDError;
    printf("illegal statement\n");
    longjmp(env,1);
  }
  if (!strcasecmp((char *)devargs[0],"define")) {/* DEFINE statement? */
    UserDefLine(ac, devargs, linenum);	/* use DEFINE handler and return */
    return;
  }
  for (devtype=NUMBERTYPES; devtype<nn; devtype++) {
    if (!strcasecmp((char *)devargs[0],DeviceDefs[devtype].name)) {
      if ((ac-1) != DeviceDefs[devtype].numTerminals) {
	UDError;
	printf("%d nets declared for %d-pin device '%s'.\n",
	   ac-1, DeviceDefs[devtype].numTerminals, devargs[0]);
	longjmp(env,1);
      }
      goto got_a_match; 
    }
  }
  UDError;
  printf("device '%s' not defined.\n",devargs[0]);
  longjmp(env,1);

got_a_match:
  device = NewDevice(*p_index, devtype, ac-1);
  AddDevice(device);
  for (i=0; i<ac-1; i++) {
    net = FindOrAllocNet((char *)devargs[i+1]);
    device->connections[i] = net;
    while (net->index < 0) {
      net = net->connections.equalNet;
    }
    connect = NewConnection();
    connect->dev = *p_index;
    connect->terminal = i;
    connect->next = net->connections.list;
    net->connections.list = connect;
    net->numConnects++;
  }
/*
** could add something here for device attributes, but omit for now
*/
  device->property = NULL;

  (*p_index)++;
}
