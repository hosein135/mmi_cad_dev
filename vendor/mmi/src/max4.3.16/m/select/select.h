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
 * select.h --
 *
 * Contains definitions for things that are exported by the
 * selection module.
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
 *
 * rcsid="$Header: select.h,v 6.0 90/08/28 18:56:54 mayo Exp $"
 */

#ifndef _SELECT
#define _SELECT

#ifndef	_MAGIC
#include "magic.h"
#endif	_MAGIC

#ifndef	_DATABASE
#include "database.h"
#endif	_DATABASE

/*** Initialization ***/

extern void SelectInit();
extern void SelTclInit(Tcl_Interp *interp);

/*** Procedures to modify the selection. ***/

extern void SelectArea(SearchContext *scx, 
		       TileTypeBitMask *types, 
		       int xMask,
		       int flags,
		       CellUse *noTreeRootUse);  /* null for tree search */
/* active group only */
#define SA_GROUP 1
/* don't select paint tiles */
#define SA_NO_TILES 2
/* don't select polygons */
#define SA_NO_POLY  4
/* don't select wirepaths */
#define SA_NO_WP    8
/* don't select labels */
#define SA_NO_LABELS 16
extern void SelectBuffer(CellDef *buffer,
			 CellDef *selRoot);

extern void SelectChunk(SearchContext *scx, 
			TileType type, 
			int xMask, 
			Rect *pArea, 
			int less,
			bool ActiveGroupOnly, 
			CellUse *noTreeRootUse); /* null for tree search */
extern bool SelectNet(SearchContext *scx, 
		      TileType type, 
		      int xMask, 
		      Rect *pArea, 
		      int less,
		      bool labels,
		      int limit);
extern void SelectRegion(SearchContext *scx, 
			 TileType type, 
			 int xMask, 
			 Rect *pArea, 
			 int less);
extern void SelectClear(void);
extern void SelectCell(CellUse *use, 
		       CellDef *rootDef, 
		       Transform *trans, 
		       int replace);
extern void SelRemoveArea(SearchContext *scx, 
		       TileTypeBitMask *types, 
		       int xMask,
		       bool activeGroupOnly,
		       CellUse *noTreeRootUse); /* null for tree search */

extern int  SelRemoveSel2(void);
extern int  SelectRemoveCellUse(CellUse *use, 
				Transform *trans);

/*** Procedures to enumerate what's in the selection. ***/

extern int SelEnumPaint(TileTypeBitMask *layers, 
			int editOnly, 
			int *foundNonEdit, 
			int (*func) (/* ??? */), 
			int (*polygonFunc) (/* ??? */), 
			int (*wirePathFunc) (/* ??? */), 
			ClientData clientData);


extern int SelEnumCells(int editOnly, 
			int *foundNonEdit, 
			SearchContext *scx, 
			TerminalPath *tPath,
			TerminalPath *tPath2,
			int (*func) (/* ??? */), 
			ClientData clientData);

extern int SelEnumLabels(TileTypeBitMask *layers, 
			 int editOnly, 
			 int *foundNonEdit, 
			 TerminalPath *tPath,
			 int (*func) (/* ??? */), 
			 ClientData clientData);

/* like SelEnumLabels(), but doesn't stop after first match of each label in selection,
 * so if two identical labels ontop of each other in different cells, this version
 * will enumerate them both,
 * NOTE:  USER FUNC MUST NOT ALTER DATABASE - COULD MAKE SEARCH CRASH.
 */
extern int SelEnumLabelsAll(TileTypeBitMask *layers, 
			 int editOnly, 
			 int *foundNonEdit, 
			 TerminalPath *tPath,
			 int (*func) (/* ??? */), 
			 ClientData clientData);

/*** Procedures to operate on the selection. ***/

extern void SelectDelete(char *msg);
extern void SelectCopy(Transform *transform, bool dupOK);
extern void SelectTransform(Transform *transform, bool dupOK);
extern void SelectGroupTransfer(Group *destGroup);
extern void SelectExpand(int mask);
extern void SelInternals(int mask, bool show);
extern void SelectStretch(int x, int y, bool group);
extern void SelectArray(ArrayInfo *arrayInfo);
extern void SelectDump(SearchContext *scx, 
		       bool dupOK, 
		       char *instPrefix,
		       char *labPrefix);

/*** The following is the root cell that contains the current selection. ***/

extern CellDef *SelectRootDef;

/*** The dummy cell that actually holds the selection: ***/

extern CellDef *SelectDef;
extern CellUse *SelectUse;

extern bool SelUndo; /* undo info for selection kept only when this var set */


#endif _SELECT
