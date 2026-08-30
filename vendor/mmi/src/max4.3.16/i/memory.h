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
 * memory.h --
 *
 * malloc/free accessed through these routines
 *
 *     ********************************************************************* 
 *     * Copyright (C) 1985, 1990 Regents of the University of California. * 
 *     * Permission to use, copy, modify, and distribute this              * 
 *     * software and its documentation for any purpose and without        * 
 *     * fee is hereby granted, provided that the above copyright          * 
 *     * notice appear in all copies.  The University of California        * 
 *     * makes no representations about the suitability of this            * 
 *     * software for any purpose.  It is provided "as is" without         * 
 *     * express or implied warranty.  Export of this software outside     * 
 *     * of the United States of America may require an export license.    * 
 *     *********************************************************************
 */

#ifndef _MEMORY
#define _MEMORY

#ifndef _MEMORYINT
#include "memoryInt.h"
#endif _MEMORYINT


/*** GLOBAL VARIABLES ***/

/* set by -mm flag on start up to divert malloc/frees 
 * to memory monitor (mm.c) 
 */
extern int MemMM;

/* Linked to tcl variable MEM_AUDIT
 * if set, msg printed on every malloc/free 
 */
extern int MemAudit;

/* if set, all MALLOC/FREE macros tagged for memory audit */
#define MEM_TAGGED 0

/*** FUNCTIONS AND MACROS ***/

/* called on startup to reserve memory to allow orderly
 * exit on out of memory condition.
 */
extern void MemReserve(int nbytes);

/* get current malloc heap size */
extern unsigned long MemStatHeapSize(void);

/* memory macros */
#define	MALLOC(type, p, n)   (p) = (MEM_TAGGED) ? \
  memMallocTag((unsigned) n, __FILE__ " __LINE__") : memMalloc((unsigned) (n))
#define	CALLOC(type, p, n)   (p) = (MEM_TAGGED) ? \
  memCallocTag((unsigned) n, __FILE__ " __LINE__") : memCalloc((unsigned) (n))
#define	FREE(p) (MEM_TAGGED) ? \
  memFreeTag((void *) (p), __FILE__ " __LINE__"),1 : memFree((void *) (p)),1

/* memory macros, tagged with msg 
 * for auditing MALLOC/FREE activity.
 * msg should describe what is being malloced/freed.
 */
#define MALLOC_TAG(type, p, n, msg) (p) = (MEM_TAGGED) ? \
  memMallocTag((unsigned) (n), msg) : memMalloc((unsigned) (n))
#define CALLOC_TAG(type, p, n, msg) (p) = (MEM_TAGGED) ? \
  memCallocTag((unsigned) (n), msg) : memCalloc((unsigned) (n))
#define FREE_TAG(p, msg) (MEM_TAGGED) ? \
  memFreeTag((void *) p, msg),1 : memFree((void *) (p)),1

#endif _MEMORY
