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
 * stack.h --
 *
 * General purpose stack manipulation routines.
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
 * Needs to include magic.h
 *
 * sccsid @(#)stack.h	4.1 MAGIC (Berkeley) 7/4/85
 */

#ifndef _STACK
#define	_STACK

#ifndef	_MAGIC
#include "magic.h"
#endif	_MAGIC

struct stackBody
{
    struct stackBody	*sb_next;	/* Next block on stack chain */
    ClientData		 sb_data[1];	/* Size determined when malloc'd */
};

/*
 * The following macro determines the size of the region to malloc
 * for a stack body able to hold sincr elements.
 */

#define sHDRSIZE		(sizeof (struct stackBody *))
#define stackSize(sincr)	(sHDRSIZE + (sizeof (ClientData)) * (sincr))

typedef struct stack
{
    int			 st_incr;	/* Amount by which to grow stack */
    ClientData		*st_ptr;	/* Stack pointer */
    struct stackBody	*st_body;	/* First stack block on chain */
} Stack;

/* --------------------- Procedure headers ---------------------------- */

Stack *StackNew(int sincr);
ClientData StackPop(Stack *stack);
ClientData StackLook(Stack *stack);
void StackPush(ClientData arg, Stack *stack);
void StackFree(Stack *stack);
void StackEnum(Stack *stack, int (*func) (/* ??? */), ClientData cd);
void StackCopy(Stack *src, Stack **dest, int copystr);

#define	stackBodyEmpty(st)	((st)->st_ptr <= (st)->st_body->sb_data)

/*
 * bool StackEmpty(st) Stack *st;	returns TRUE if stack is empty
 */
#define	StackEmpty(st)	(stackBodyEmpty(st) && (st)->st_body->sb_next == NULL)

/*
 * Macro interfaces to StackLook(), StackPop(), and StackPush().
 */
#define	STACKLOOK(st) \
	(stackBodyEmpty(st) ? StackLook(st) : *((st)->st_ptr - 1))

#define	STACKPOP(st) \
	(stackBodyEmpty(st) ? StackPop(st)  : *--((st)->st_ptr))

#define	STACKPUSH(a, st) \
	if (1) { \
	    if ((st)->st_ptr >= &(st)->st_body->sb_data[(st)->st_incr]) \
		StackPush(a, st); \
	    else \
		*((st)->st_ptr++) = (ClientData) (a); \
	} else

#endif _STACK
