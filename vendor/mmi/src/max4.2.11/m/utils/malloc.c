// ************************************************************************
// 
// Copyright (c) 1995-2002 Juniper Networks, Inc. All rights reserved.
// 
// Permission is hereby granted, without written agreement and without
// license or royalty fees, to use, copy, modify, and distribute this
// software and its documentation for any purpose, provided that the
// above copyright notice and the following three paragraphs appear in
// all copies of this software.
// 
// IN NO EVENT SHALL JUNIPER NETWORKS, INC. BE LIABLE TO ANY PARTY FOR
// DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
// ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF
// JUNIPER NETWORKS, INC. HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
// DAMAGE.
// 
// JUNIPER NETWORKS, INC. SPECIFICALLY DISCLAIMS ANY WARRANTIES,
// INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND
// NON-INFRINGEMENT.
// 
// THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND JUNIPER
// NETWORKS, INC. HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
// UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
// 
// ************************************************************************



/*
 * malloc.c -- malloc/free accessed through routines in this file.
 */
#include <stdlib.h>
#include <string.h>
#include "magic.h"
#include "message.h"
#include "mm.h"
#include "malloc.h"

/* if set memory monitoring enabled (for debugging MALLOC/FREE calls) 
 * enabled by -mm command line option.
 * must be enabled prior to first MALLOC.
 */
int MemMM = FALSE;

/* if set, msg printed on every malloc/free */
int MemAudit = FALSE;

/* An extra block of Memory is reserved here on startup, to give
 * us a chance to backup files before exiting, if we run out of
 * memory.
 */
static char *memReserve = NULL;

/* Delay free'ing by one call (to either FREE or MALLOC, to allow
 * a next pointer to be followed immediately after freeing 
 * an object 
 */
static char *memDelayedFree = NULL;


/* statistics 
 * NOTE only includes Max mallocMagic/freeMagic activity, not
 * for example mallocs done by the tcl/tk code.
 */
int MallocNumMalloc = 0;       /* number of malloc calls */
int MallocNumFree = 0;       /* number of free calls */
int MallocBytes = 0;           /* total bytes malloced 
				* (some may have since been freed!)
				*/
int MallocAlignOverhead = 0;   /* bytes 'wasted' by double word alignment */


/*
 * ----------------------------------------------------------------------------
 *
 * mallocReserve --
 *
 * called once at startup to reserve memory for graceful exit if we
 * run out of memory.
 *
 * ----------------------------------------------------------------------------
 */
void mallocReserve(int nbytes)
{
  ASSERT(!memReserve, "mallocInit");
  memReserve = malloc(nbytes);
}

/*
 * ----------------------------------------------------------------------------
 *
 * mallocMagic --
 *
 * Max's malloc().  Normally invoked by MALLOC() macro.
 *
 * ----------------------------------------------------------------------------
 */
void *
mallocMagic(unsigned nbytes)
{
  void *p; 

  /* keep statistics */
  MallocNumMalloc++;
  MallocBytes += nbytes;       
  MallocAlignOverhead += ((nbytes+7)/8)*8 - nbytes;
  
  /* DEBUG */
  if (MemAudit) fprintf(stderr,"malloc %d bytes\n", nbytes);

  /* free delayed item, if any */
  if (memDelayedFree) 
  {
    MemMM ? MM_Free(memDelayedFree) : free(memDelayedFree);
    memDelayedFree=NULL;
  }

  /* do the malloc */
  p = MemMM ? MM_Malloc(nbytes) : malloc(nbytes);

  if (p) return p;

  /* free up reserved memory so we can write out error message,
   * and save backup files
   */
  if(memReserve) free(memReserve);

  fprintf(stderr,
	  "\nMax:  Out of Memory!\n"
	  "Your data space requirements have exceeded the available system memory.\n" 
          "Max will attempt to backup files before exiting.\n\n");

  /* backup on exit is default */ 
  exit(1);
}

/*
 * ----------------------------------------------------------------------------
 *
 * callocMagic --
 *
 * return magicMalloc'ed and zeroed block. 
 *
 * ----------------------------------------------------------------------------
 */
void *
callocMagic(unsigned nbytes)
{
    void *p;

    p = mallocMagic(nbytes);
    memset(p, 0, nbytes);

    return p;
}

/*
 * ----------------------------------------------------------------------------
 *
 * freeMagic --
 *
 * Max's free().  Normally invoked by FREE() macro.
 *
 * ----------------------------------------------------------------------------
 */
void freeMagic(void *p)
{
  ASSERT(p, "freeMagic, passed 0 pointer\n");   

  /* keep statistics */

  MallocNumFree++;
  /* DEBUG */
  if (MemAudit) fprintf(stderr,"free\n");

  /* free delayed item, if any */
  if (memDelayedFree) 
  {
    MemMM ? MM_Free(memDelayedFree) : free(memDelayedFree);
    memDelayedFree=NULL;
  }

  /* queue new item */
  memDelayedFree=p;
}


/*
 * ----------------------------------------------------------------------------
 *
 * mallocMagicTag --
 *
 * Max's malloc(), tagged with msg.  Normally invoked by MALLOC_TAG() macro.
 *
 * ----------------------------------------------------------------------------
 */
void *
mallocMagicTag(unsigned nbytes, char *msg)
{
  if(MemAudit) fprintf(stderr, "%s: ", msg);
  
  return mallocMagic(nbytes);
}

/*
 * ----------------------------------------------------------------------------
 *
 * callocMagicTag --
 *
 * return magicMalloc'ed and zeroed block. 
 *
 * ----------------------------------------------------------------------------
 */
void *
callocMagicTag(unsigned nbytes, char *msg)
{
  if(MemAudit) fprintf(stderr, "%s: ", msg);
  
  return callocMagic(nbytes);
}

/*
 * ----------------------------------------------------------------------------
 *
 * freeMagicTag --
 *
 * Max's free().  Normally invoked by FREE() macro.
 *
 * ----------------------------------------------------------------------------
 */
void freeMagicTag(void *p, char *msg)
{
  if(MemAudit) fprintf(stderr, "%s: ", msg);

  freeMagic(p);
}
