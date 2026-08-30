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
 * commands.h --
 *
 * Definitions for the commands module.
 *
 * The commands module parses and excutes commands (using tcl interpeter).
 * (Commands are collected from low level events such as key presses and
 *  mouse button pushes in the textio module).
 *
 * For historical reasons the command module also contains the top level
 * routines for original magic commands specific to layout windows.
 * These commands are in the files cmd_mgcL*.c 
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
 * Needs to include: tiles.h, database.h
 *
 * rcsid $Header: commands.h,v 6.0 90/08/28 18:07:33 mayo Exp $
 */

#ifndef _COMMANDS
#define	_COMMANDS

#ifndef _TCL
#include <tcl.h>
#endif _TCL

#ifndef	_LAYOUT
#include "layout.h"
#endif	_LAYOUT

#ifndef	_DATABASE
#include "database.h"
#endif	_DATABASE

/*
 * Name of default yank buffer
 */

#define YANKBUFFERNAME	"y"

/*
 * Manipulation of user-supplied "layer" masks.
 * These may include both layers specifiable in a TileTypeMask,
 * and pseudo-layers such as "subcells" and "labels".
 *
 * These are treated just like other TileTypes, except they
 * reside in the uppermost TT_RESERVEDTYPES tile type numbers.
 *
 * L_CELL = subcell "layer"
 */
#define	L_CELL	(TT_MAXTYPES-1)	  
#define	L_LABEL	(TT_MAXTYPES-2)	  
#define	L_FLYLINE (TT_MAXTYPES-3) 


/* --------------------- Global procedure headers --------------------- */
extern Layout *CmdGetRootPoint(Point *point, Rect *rect);
extern Layout *CmdGetEditPoint(Point *point, Rect *rect);
extern bool CmdParseLayers(char *s, TileTypeBitMask *mask);
extern CellUse *CmdGetSelectedCell(Transform *pTrans);
extern void cmdSaveCell(CellDef *cellDef, 
                     	/* Pointer to def of cell to be saved */
	    char *newName, 
                  	/* Pointer to name of file in which cell is to be
			 * saved.  May be NULL, in which case the name from
			 * the CellDef is taken.
			 */
	    int tryRename);
                   	/* We should rename the cell to the name of the
			 * place where it was saved.
			 */

#endif _COMMANDS
