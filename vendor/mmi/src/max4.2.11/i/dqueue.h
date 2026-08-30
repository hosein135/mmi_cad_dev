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
 * dqueue.h --
 *
 * Utility module for double ended queues (dqueus).
 * DQueues are stored in a malloced array which grows when it overflows.
 * The head of the queue grows towards lower addresses, and the tail grows
 * up.  The array is treated like a cirular ring of size dq_maxSize.
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
 *
 * rcsid "$Header: dqueue.h,v 6.0 90/08/28 19:00:34 mayo Exp $"
 *
 */

#ifndef _DQUEUE
#define	_DQUEUE

#ifndef	_MAGIC
#include "magic.h"
#endif	_MAGIC

/* The dqueue structure, to be manipulated only by the 
 * procedures declared in this file.
 */
typedef struct {
    int dq_size;	    /* number of elements in this dqueue */
    int dq_maxSize;	    /* max capacity of this dqueue */
    int dq_front;	    /* next empty location at head of dqueue */
    int dq_rear;	    /* next empty location at tail of dqueue */
    ClientData *dq_data;    /* points to an array (filled in by DQInit) */
} DQueue;

/* Housekeeping for DQueues */
extern void DQInit(DQueue *q, int capacity);	    /* Sets up data in an already allocated DQueue */
extern void DQFree(DQueue *q);
extern void DQChangeSize(DQueue *q, int newSize);
extern void DQCopy(DQueue *dst, DQueue *src);
#define DQIsEmpty(q)	((q)->dq_size == 0)

/* Adding and deleting */
extern void DQPushFront(DQueue *q, ClientData elem);
extern void DQPushRear(DQueue *q, ClientData elem);
extern ClientData DQPopFront(DQueue *q);
extern ClientData DQPopRear(DQueue *q);

#endif _DQUEUE
