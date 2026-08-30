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
 * malloc.h --
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

#ifndef _MALLOC
#define _MALLOC

#define MALLOC_TAGGED 0

/* global variables */

/* set by -mm flag on start up to divert malloc/frees to memory monitor (mm.c) */
extern int MemMM;

/* if set, msg printed on every malloc/free */
extern int MemAudit;


/* Statistics 
 * NOTE: only includes Max mallocMagic/freeMagic activity, not
 * for example mallocs done by the tcl/tk code.
 */
extern int MallocNumMalloc;       /* number of malloc calls */
extern int MallocNumFree;       /* number of free calls */
extern int MallocBytes;           /* total bytes malloced 
				* (some may have since been freed!)
				*/
extern int MallocAlignOverhead;   /* bytes 'wasted' by double word alignment */

/* function prototypes */
void mallocReserve(int nbytes);
void *mallocMagic(unsigned nbytes);
void *callocMagic(unsigned nbytes);
void freeMagic(void *cp);
void *mallocMagicTag(unsigned nbytes, char *msg);
void *callocMagicTag(unsigned nbytes, char *msg);
void freeMagicTag(void *cp, char *msg);

/* memory macros */
#define	MALLOC(type, p, n)   (p) = (type) mallocMagic((unsigned) (n))
#define	CALLOC(type, p, n)   (p) = (type) callocMagic((unsigned) (n))
#define	FREE(p) freeMagic((void *) p)

/* memory macros, tagged with msg */

#define MALLOC_TAG(type, p, n, msg) (p) = (MALLOC_TAGGED) ? \
  mallocMagicTag((unsigned) (n), msg) : mallocMagic((unsigned) (n))
#define CALLOC_TAG(type, p, n, msg) (p) = (MALLOC_TAGGED) ? \
  callocMagicTag((unsigned) (n), msg) : callocMagic((unsigned) (n))
#define FREE_TAG(p, msg) (MALLOC_TAGGED) ? \
  freeMagicTag((void *) p, msg),1 : freeMagic((void *) (p)),1


#endif _MALLOC
