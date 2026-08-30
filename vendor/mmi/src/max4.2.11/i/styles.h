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
 * styles.h --
 *
 * Definitions of display styles used for system purposes.
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
 * rcsid:  $Header: styles.h,v 6.0 90/08/28 18:47:45 mayo Exp $
 */

#ifndef _STYLES
#define _STYLES 

/*
 * first MAXTILESTYLES reserved for rendering edit cell 'paint' 
 *
 * second MAXTILESTYLES reserved for dimmed versions (n -> n+MAXTILESTYLES)
 * of paint (used for paint not in edit cell).
 *
 * third, named styles (defined below) follow.
 *
 */
#define STYLE_NAMED_BASE            (2*MAXTILESTYLES)

/* background */
#define	STYLE_BACKGROUND            STYLE_NAMED_BASE

/* box */
#define	STYLE_BOX	            (STYLE_NAMED_BASE+1)
 
/* labels */
#define	STYLE_LABEL	            (STYLE_NAMED_BASE+2)
#define	STYLE_LABEL_DIM	            (STYLE_NAMED_BASE+3)

/* unexpanded instances */
#define	STYLE_UNEXPANDED_INSTANCE     (STYLE_NAMED_BASE+4)
#define	STYLE_UNEXPANDED_INSTANCE_DIM (STYLE_NAMED_BASE+5)

/* grid */
#define	STYLE_GRID_FINE		    (STYLE_NAMED_BASE+6) 
#define	STYLE_GRID_COARSE	    (STYLE_NAMED_BASE+7)
#define STYLE_GRID_ORIGIN	    (STYLE_NAMED_BASE+8)

/* *watch (debugging) */
#define	STYLE_WATCHED_TILE          (STYLE_NAMED_BASE+10)

/* feedback */
#define STYLE_FEEDBACK_SOLID        (STYLE_NAMED_BASE+11)
#define STYLE_FEEDBACK_MEDIUM       (STYLE_NAMED_BASE+12)
#define STYLE_FEEDBACK_PALE         (STYLE_NAMED_BASE+13)
#define STYLE_FEEDBACK_OUTLINE      (STYLE_NAMED_BASE+14) 
#define STYLE_FEEDBACK_DOTTED       (STYLE_NAMED_BASE+15) 

/* selection */
#define STYLE_SELECTION_STIPPLED    (STYLE_NAMED_BASE+16)
#define STYLE_SELECTION_SOLID       (STYLE_NAMED_BASE+17)
#define STYLE_SELECTION_OUTLINE     (STYLE_NAMED_BASE+18)

/* flylines */
#define STYLE_FLYLINE               (STYLE_NAMED_BASE+19)
#define STYLE_FLYLINE_DIM           (STYLE_NAMED_BASE+20)

/* annotations */
#define STYLE_ANNOTATION            (STYLE_NAMED_BASE+21)

/* num styles */
#define STYLE_TABLE_SIZE            (STYLE_NAMED_BASE+22)                  

#endif _STYLES







