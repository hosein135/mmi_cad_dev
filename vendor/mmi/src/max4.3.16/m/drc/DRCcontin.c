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
 * DRCcontin.c --
 *
 * This file provides the facilities for continuously keeping
 * design-rule violation information up to date.  It
 * records areas that need to be rechecked, and provides a
 * routine to perform those checks in the background.
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

#ifndef	lint
static char rcsid[] = "$Header: DRCcontin.c,v 1.3 92/07/08 14:46:17 mayo Exp $";
#endif	not lint

#include <stdio.h>
#include <sys/types.h>
#include <tk.h>
#include "magic.h"
#include "message.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "layout.h"
#include "main.h"
#include "commands.h"
#include "drc.h"
#include "drcInt.h"
#include "signals.h"
#include "undo.h"
#include "memory.h"
#include "mm.h"

/* Global variable, settable by outside world, that enables
 * and disables the background checker.  If disabled, check
 * tiles pile up but nothing is checked.
 */

bool DRCBackGround = TRUE;

/* n=DRCPriority if positive do n events between drc checks,
 * if negative, do -n drc checks between events.
 */
int DRCPriority = 10;

/* set when drc had work last time DRCContinous was called.
 * linked to tcl var drc_busy and used to give drc status.
 */
bool DRCBusy = FALSE;

/* The size of chunks into which to decompose large DRC areas.  
 * Recomputed on each call to checker by drcSetup() from MnTypicalWireWidth()
 */
int drcStepSize;

/*--- Things used by other files in DRC modules but not outside world. ---*/

/*  Pointers to yank buffer's use and def */
CellDef * DRCdef = (CellDef *) NULL;
CellUse * DRCuse = (CellUse *) NULL;

/* mask of the DRC types */
TileTypeBitMask DRCTypes;

/*------- "globals" used only within this file. -------*/

/* initilization flag */

static bool drcInitialized = FALSE;

/* Boolean indicating whether or not check tiles are being displayed. */

static bool drcDisplayCheckTiles = FALSE;

/* In order to reduce the amount of DRC redisplay, whenever an area
 * is rechecked we log all the previous violations in that area,
 * XOR them with all of the new violations in the area, and only
 * redisplay the bounding box of the changes.  The plane and paint
 * tables below are used for storing the information and doing the
 * XOR.
 */

static Plane *drcDisplayPlane;

#define DRC_SOLID 1

static PaintResultType drcXorTable[] = {DRC_SOLID, TT_SPACE};

/* When computing DRC violations, they don't get painted directly
 * into the database.  Instead, they get painted first into a
 * temporary plane.  That way, if DRC is interrupted we can exit
 * quickly without leaving error information in a weird state.
 * Once everything has been computed, then it's painted into the
 * cell in one fell swoop.
 */

static Plane *drcTempPlane;


/*
 * ----------------------------------------------------------------------------
 *
 * DRCInit --
 *
 * 	This procedure initializes DRC data.  It must be called after
 *	the technology file has been read.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	initializes __DRC__ cell buffer.
 *
 * ----------------------------------------------------------------------------
 */

void
DRCInit(void)
{
    int i;
    TileTypeBitMask displayedTypes;

    /* Only do initialization once. */

    if (drcInitialized) return;
    drcInitialized = TRUE;

    /* Create a cell use to use for holding yank data in interaction checks. */
    DBNewYank("__DRC__",&DRCuse,&DRCdef);

    /* See if check tiles are being displayed. */

    TTMaskZero(&displayedTypes);
    for (i = 0; i < MAXTILESTYLES; i++)
	TTMaskSetMask(&displayedTypes, LayStyleToTypes(i));

    drcDisplayCheckTiles = TTMaskHasType(&displayedTypes, TT_CHECKPAINT)
			|| TTMaskHasType(&displayedTypes, TT_CHECKSUBCELL);

    /* Initialize mask of DRC layer types. */

    TTMaskZero(&DRCTypes);
    TTMaskSetType(&DRCTypes, TT_ERROR_P);
    TTMaskSetType(&DRCTypes, TT_ERROR_S);
    TTMaskSetType(&DRCTypes, TT_ERROR_PS);

    /* Create planes to hold error areas to redisplay and to hold
     * temporary error information.
     */

    drcDisplayPlane = DBPlaneNew((ClientData) TT_SPACE);
    drcTempPlane = DBPlaneNew((ClientData) TT_SPACE);
}

/*
 * ----------------------------------------------------------------------------
 * drcCheckTile --
 *
 *	This procedure is called to process a check tile is found in
 *	the PL_CHECK plane of a cell.
 *      This procedure is the heart of Max's continuous drc checker.
 *
 *	For DRC purposes, each cell is divided up checkerboard-style
 *	into areas drcStepSize on each side.  All checking is done
 *	in terms of these squares.  When a check tile is found, we
 *	find the outer area of all check tiles in the square containing
 *	the original check tile's lower-left corner.  Errors within
 *	this area are regenerated, then all check tiles in that area
 *	are erased.  The checkerboard approach serves three purposes.
 *	First, it allows nearby small tiles to be combined for checking
 *	purposes.  Second, it limits the maximum amount of work that
 *	is done at once, so if we're getting interrupted by new commands
 *	there is still some hope of eventually getting the DRC caught up.
 *	And third, it provides a canonical form for the checks, particularly
 *	those involving subcells, so the same results are produced no
 *	matter what the original check area is.
 *
 *	The three DRC meta-rules are:
 *		(1) paint in one CellDef must be consistent by itself,
 *			that is, without regard to subcells
 *		(2) subtrees must be consistent -- this includes both
 *			paint interacting with subcells, and subcells
 *			interacting with each other.
 *		(3) an arrayed use of a CellDef must be consistent by itself,
 *			that is, without regard to paint or other subcells
 *			in the parent.  This check happens automatically as
 *			part of the subtree check.
 *
 *	Two types of error tiles are kept independently in the
 *	DRC_ERROR plane:	(1) paint
 *				(2) subtree
 *
 *	This function is passed to DBPlaneEnumAreaPaint().
 *
 * Results:
 *	Always returns one.  This function is only called on non-space
 *	(CHECK) tiles, so if it is called a CHECK tile must have been
 *	processed and we want DBPlaneEnumAreaPaint to abort the search.
 *
 * Side effects:
 *	Modifies both DRC planes of the CellDef at the front of the
 *	DRCPending list.
 * ----------------------------------------------------------------------------
 */

CellDef *drcCheckTileDef;       /* global used to pass def "arg" to 
				 * drcCheckTile() */ 
	/* ARGSUSED */
static int
drcCheckTile(Tile *tile, 
                       			/* tile in DRC_CHECK plane */
	     ClientData cdarg)
               	      			/* area being searched */
{
    Rect srAreaPlus;            /* slightly expanded search area,
				 * want to only check squares in here,
				 * so we focus on area of interest,
				 * e.g. search area = window frame.
				 */
    Rect squares;               /* area to check squares in */
    Rect square;		/* Square area of the checkerboard
				 * being processed right now.
				 */
    Rect erasebox;		/* erase old ERROR tiles in this
				 * region and clip new ERRORs to it
				 */
    Rect checkbox;		/* apply rules across all edges in
				 * this region
				 */
    CellDef * celldef;		/* cell being checked  */
    Rect redisplayArea;		/* Area to be redisplayed. */

    /* forward declarations */
    extern int drcXorFunc(Tile *tile);	
    extern int drcPutBackFunc(Tile *tile, CellDef *cellDef);
    extern int drcEraseInteractionArea(Rect *area, Plane *plane);

    celldef = drcCheckTileDef;
    DRCErrorDef = celldef;

    /*
    fprintf(stderr,"DEBUG drcCheckTile() def=%s tile = %d %d %d %d\n",
	    celldef->cd_name,
	    LEFT(tile), BOTTOM(tile), RIGHT(tile), TOP(tile));
    */

    /* clip tile area to srArea + a little slop
     * slop makes sure we actually clean out search area, so
     * caller doesn't go into infinite loop.
     */
    {
      Rect *r = (Rect *) cdarg;

      srAreaPlus.r_xbot = r->r_xbot - 1;
      srAreaPlus.r_ybot = r->r_ybot - 1;
      srAreaPlus.r_xtop = r->r_xtop + 1;
      srAreaPlus.r_ytop = r->r_ytop + 1;

      squares.r_xbot = LEFT(tile);
      squares.r_xtop = RIGHT(tile);
      squares.r_ybot = BOTTOM(tile);
      squares.r_ytop = TOP(tile);
      GeoClip(&squares, &srAreaPlus);
    }

/*
    {
      Rect *r = &squares;
      fprintf(stderr,"DEBUG drcCheckTile() def=%s squares = %d %d %d %d\n",
	      celldef->cd_name,
	      r->r_xbot, r->r_ybot, r->r_xtop, r->r_ytop);
    }
*/

    if(GEO_RECTNULL(&squares)) return 0;

    /* Find the checkerboard square containing the lower-left corner
     * of the check tile, then find all check tiles within that square.
     */
    
    DRCstatSquares += 1;
    square.r_xbot = (squares.r_xbot/drcStepSize) * drcStepSize;
    if (square.r_xbot > squares.r_xbot) square.r_xbot -= drcStepSize;
    square.r_ybot = (squares.r_ybot/drcStepSize) * drcStepSize;
    if (square.r_ybot > squares.r_ybot) square.r_ybot -= drcStepSize;
    square.r_xtop = square.r_xbot + drcStepSize;
    square.r_ytop = square.r_ybot + drcStepSize;

    /*
    {
      Rect *r = &square;
      fprintf(stderr,"DEBUG drcCheckTile() def=%s square = %d %d %d %d\n",
	      celldef->cd_name,
	      r->r_xbot, r->r_ybot, r->r_xtop, r->r_ytop);
    }
    */

    erasebox = GeoNullRect;
    (void) DBPlaneEnumAreaPaint((Tile *) NULL, celldef->cd_planes[PL_DRC_CHECK],
	&square, &DBAllButSpaceBits, drcIncludeArea, (ClientData) &erasebox);
    GeoClip(&erasebox, &square);

    /*
     MsgInfoF("Check area = (%d, %d) (%d, %d)\n",
	erasebox.r_xbot, erasebox.r_ybot,
	erasebox.r_xtop, erasebox.r_ytop);
    */

    /* Compute area to recheck in order to recompute all errors in
     * erasebox.
     */

    GEO_EXPAND(&erasebox, TechHalo, &checkbox);

    /* Use drcDisplayPlane to save all the current errors in the
     * area we're about to recheck.
     */
    DBPlaneClearPaint(drcDisplayPlane);
    (void) DBPlaneEnumAreaPaint((Tile *) NULL, celldef->cd_planes[PL_DRC_ERROR],
	&square, &DBAllButSpaceBits, drcXorFunc, (ClientData) NULL);
    
    /* Check #1:  recheck the paint of the cell, ignoring subcells. */

    DRCErrorType = TT_ERROR_P;
    DBPlaneClearPaint(drcTempPlane);
    (void) DRCBasicCheck (celldef, &checkbox, &erasebox, drcPaintError,
	(ClientData) drcTempPlane);

    /* Check #2:  check interactions between paint and subcells, and
     * also between subcells and other subcells.  If any part of a
     * square is rechecked for interactions, the whole thing has to
     * be rechecked.  We use TT_ERROR_S tiles for this so that we
     * don't have to recheck paint and array errors over the whole
     * square.
     */

    DRCErrorType = TT_ERROR_S;

    (void) DRCInteractionCheck(celldef, &square, 
	drcPaintError, (ClientData) drcTempPlane, 
	drcEraseInteractionArea, (ClientData) drcTempPlane);
    
    /* Check #3:  check for array formation errors in the area. */

    DRCErrorType = TT_ERROR_P;
    (void) DRCArrayCheck(celldef, &erasebox, drcPaintError,
	(ClientData) drcTempPlane);

    /* If there was an interrupt, return without modifying the cell
     * at all.
     */

    if (SigInterruptPending) return 1;

    /* Erase the check tile from the check plane, erase the pre-existing
     * error tiles, and paint back in the new error tiles.  Do this all
     * with interrupts disabled to be sure that it won't be aborted.
     */

    SigDisableInterrupts();

    DBPaintPlane(celldef->cd_planes[PL_DRC_CHECK], &erasebox,
	DBStdEraseTbl(DBgetTileType(tile), PL_DRC_CHECK),
	(PaintUndoInfo *) NULL);
    DBPaintPlane(celldef->cd_planes[PL_DRC_ERROR], &erasebox,
	DBStdEraseTbl(TT_ERROR_P, PL_DRC_ERROR),
	(PaintUndoInfo *) NULL);
    DBPaintPlane(celldef->cd_planes[PL_DRC_ERROR], &square,
	DBStdEraseTbl(TT_ERROR_S, PL_DRC_ERROR),
	(PaintUndoInfo *) NULL);
    (void) DBPlaneEnumAreaPaint((Tile *) NULL, drcTempPlane, &TiPlaneRect,
	&DBAllButSpaceBits, drcPutBackFunc, (ClientData) celldef);

    /* XOR the new errors in the tile with the old errors we
     * saved in drcDisplayPlane.  Where information has changed,
     * clip to square and redisplay.  If check tiles are being
     * displayed, then always redisplay the entire area.
     */
    
    (void) DBPlaneEnumAreaPaint((Tile *) NULL, celldef->cd_planes[PL_DRC_ERROR],
	&square, &DBAllButSpaceBits, drcXorFunc, (ClientData) NULL);
    if (DBBoundPlane(drcDisplayPlane, &redisplayArea))
    {
	GeoClip(&redisplayArea, &square);
	if (!GEO_RECTNULL(&redisplayArea))
	    DBChangedArea(celldef, 
			 &redisplayArea, 
			 &DRCTypes,
			 DBCF_DRC_ERROR_ONLY);
    }
    if (drcDisplayCheckTiles)
	DBChangedArea(celldef, 
		      &square, 
		      &DRCTypes,
		      DBCF_DRC_ERROR_ONLY);
    SigEnableInterrupts();

    return (1);		/* stop the area search: we modified the database! */
}

/* returns 0 if no checks found, 1 if check found or interrupted */
static int drcConDoChecks(CellDef *def,
			   Rect *area,
			   bool background)  /* if set interrupt on user input */
{

/*
  fprintf(stderr, "DEBUG drcConDoChecks def=%s area=%d %d %d %d\n",
	  def->cd_name, 
	  area->r_xbot, area->r_ybot, area->r_xtop, area->r_ytop);
*/

  int count = 0;

  /* reset change count */
  def->cd_drcNumChanges = 0;

  /* handle DRC_ALL flag */
  if(def->cd_flags & CD_DRC_ALL_PENDING)
  {
    SigDisableInterrupts();

    def->cd_flags &= ~CD_DRC_ALL_PENDING;

    /* replace current check tiles with a single tile 
     * over entire bbox.
     */
    DBPlaneClearPaint(def->cd_planes[PL_DRC_CHECK]);
    DBPaintPlane(def->cd_planes[PL_DRC_CHECK], 
		 &def->cd_bbox,
		 DBStdPaintTbl(TT_CHECKPAINT, PL_DRC_CHECK),
		 (PaintUndoInfo *) NULL);

    SigEnableInterrupts();
  }

  /* Process TT_CHECKPAINT tiles in def */
  drcCheckTileDef = def;
  while (DBPlaneEnumAreaPaint ((Tile *) NULL,
			def->cd_planes[PL_DRC_CHECK],
			area, 
			&DBAllButSpaceBits, 
			drcCheckTile, 
			(ClientData) area))

  {
    count++;
 
    /* check for async event (without blocking) */
    UndoEnable();

    if(SigInterruptPending) goto interrupt;

    if (background && 
	count+DRCPriority>0 &&
	Tcl_DoOneEvent(TK_X_EVENTS |
			TCL_FILE_EVENTS |
			TCL_TIMER_EVENTS |
			TCL_DONT_WAIT)) 
    {
      goto interrupt;
    }

    UndoDisable();
  }

  return 0;

interrupt:
  return 1;
}


/*
 * ----------------------------------------------------------------------------
 * drcConDoDescendents--
 *
 * Process check areas in descendents of def.
 *
 * returns 0 if there was nothing to do, 1 otherwise.
 * ----------------------------------------------------------------------------
 */
static int
drcConDoDescendents (CellDef *def, bool background)
{
  CellKid *kid;

  /* TODO: put "current" kid at front to speed up repeated calls to this */
  for (kid=def->cd_kids; kid; kid=kid->ck_next)
  {
    CellDef *child = kid->ck_def;

    /* do this kid */
    if(child->cd_flags & CD_DRC_PENDING)
    {
      if(drcConDoChecks(child, DBBBoxCellDef(child),background)) goto interrupt;

      child->cd_flags &= ~CD_DRC_PENDING;
    }

    /* recursively process descendents of kid */
    if(drcConDoDescendents(child, background)) goto interrupt;
  }

  return 0;

 interrupt:
  return 1;
}


/*
 * ----------------------------------------------------------------------------
 * DRCContinuous --
 *
 * Called by toplevel event loop in main(), prior to blocking to
 * wait for new events.
 *
 * This routine checks to see if there are any areas of the layout that
 * need to be design-rule-checked.  If so, it does the appropriate checks.
 * This procedure will abort itself at the earliest convenient moment
 * if events pending.
 *
 * NOTE:  Tcl_DoOneEvent called to check for new events, 
 *        events may be processed "inside" this procedure, but no
 *        "do when idle" events (such as redisplay) 
 *        will be processed before exiting this procedure.
 *
 * Results:
 *	Returns 0 if off or nothing to do, 1 otherwise.
 *
 * Side effects:
 *	Modifies the DRC_CHECK and DRC_ERROR planes 
 *	of the CellDefs on the DRCPending list.
 * ----------------------------------------------------------------------------
 */

int
DRCContinuous (bool background) /* if true, interrupts on user input */
{
    Rect box;				/* Area of DRC def that changed. */
    Layout *w;
    CellDef *def;
    
    /* if DRC off, just return */
    if (DRCBackGround == FALSE)	return 0;

    /* setup checker (e.g. compute stepsize) */
    drcSetup();

    /* get def currently being viewed by user */
    w = LayCurWindow();
    def = w->lay_rootUse->cu_def;

    /* bring bboxes and drc info in tree rooted at def up-to-date */
    DBUpdate(def);

    /* Don't want to undo error info. */
    UndoDisable();		

    if(def->cd_flags & CD_DRC_PENDING)
    {
      /* give priority to checks in users current view */
      if(drcConDoChecks(def, &w->lay_dbArea, background)) goto interrupt;

      /* check rest of def currently being viewed by user */
      if(drcConDoChecks(def, DBBBoxCellDef(def), background)) goto interrupt; 

      def->cd_flags &= ~CD_DRC_PENDING;
    }

    /* check descendents of current root def */
    if(drcConDoDescendents(def, background)) goto interrupt;

    /* NOTE: if you add checks to other cells, 
     * remember you need to do DBUpdate() first, and this could slow down
     * interactive response!
     */

    DRCBusy = FALSE;
    UndoEnable();
    return 0;

  interrupt:
    DRCBusy = TRUE;
    UndoEnable();
    return 1;
}


/* The utility function below gets called for each error tile in a
 * region.  It just XOR's the area of the tile into drcDisplayPlane.
 */

int
drcXorFunc(Tile *tile)
{
    Rect area;

    TiToRect(tile, &area);
    DBPaintPlane(drcDisplayPlane, &area, drcXorTable, (PaintUndoInfo *) NULL);
    return 0;
}

/* Erases a region of the temp error plane.  For less strict checking, we
 * remove any errors from the basic checker in the area of subcells
 * interactions, replacing those errors with any errors produced by
 * the interaction check.
 */

int
drcEraseInteractionArea(Rect *area, Plane *plane)
               			/* Area to erase (the area that DRC errors
				 * from the interaction check will be clipped
				 * to -- 1 halo bigger than the 
				 * interaction area.)
				 */
                 		/* Plane to erase from. */
{
    DBPaintPlane(plane, area, DBStdWriteTbl(TT_SPACE), (PaintUndoInfo *) NULL);
    return 0;
}

/* This procedure is the one that actually paints error tiles into the
 * database cells.
 */

int
drcPutBackFunc(Tile *tile, CellDef *cellDef)
               			/* Error tile, from drcTempPlane. */
                     		/* Celldef in which to paint error. */
{
    Rect area;

    TiToRect(tile, &area);
    DBPaintPlane(cellDef->cd_planes[PL_DRC_ERROR], &area,
	DBStdPaintTbl(DBgetTileType(tile), PL_DRC_ERROR),
	(PaintUndoInfo *) NULL);
    return 0;
}

/*
 * ----------------------------------------------------------------------------
 *
 * drcIncludeArea --
 *
 * 	This is a drc utility procedure called by DBPlaneEnumAreaPaint.  It
 *	merely computes the total area of non-space tiles in the
 *	given area of the plane.  It is only called for non-space
 *	tiles.
 *
 * Results:
 *	Always returns 0 so the search continues.
 *
 * Side effects:
 *	The client data must be a pointer to a rectangle.  The
 *	rectangle is enlarged to include the area of this tile.
 *
 * ----------------------------------------------------------------------------
 */

int
drcIncludeArea(Tile *tile, Rect *rect)
               
               			/* Rectangle in which to record total area. */
{
    Rect dum;

    TiToRect(tile, &dum);
    (void) GeoInclude(&dum, rect);
    return 0;
}

