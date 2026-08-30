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
 * memoryInt.h --
 *
 * Internal interface of memory module.  
 * Should be treated as opaque, outside of memory module.
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

#ifndef _MEMORYINT
#define _MEMORYINT

/* memory monitor, for debugging malloc problems */
#ifndef _MM
#include "mm.h"
#endif _MM

/* Jay's memory manager, efficient front-end to malloc. 
 * Contents of mem.h should be treated as OPAQUE outside malloc module.
 *
 * NOTE:  Defines some macros (e.g. MALLOC, CALLOC, FREE) that we redefine
 *        below. 
 */
#include "mem.h"
#undef MALLOC
#undef CALLOC
#undef FREE

/* Statistics 
 * NOTE: only includes Max memMalloc/memFree activity, not
 * for example mallocs done by the tcl/tk code.
 */

extern int memNumMalloc;       /* number of malloc calls */
extern int memNumFree;         /* number of free calls */
extern int memMallocedBytes;   /* total bytes malloced 
				* (some may have since been freed!)
				*/

/* function prototypes */
extern void *memMalloc(unsigned nbytes);
extern void *memCalloc(unsigned nbytes);
extern void memFree(void *cp);
extern void *memMallocTag(unsigned nbytes, char *msg);
extern void *memCallocTag(unsigned nbytes, char *msg);
extern void memFreeTag(void *cp, char *msg);

#endif _MEMORYINT
