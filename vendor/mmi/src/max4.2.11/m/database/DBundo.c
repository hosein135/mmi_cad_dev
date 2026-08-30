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
 * DBundo.c --
 *
 * Interface to the undo package for the database.
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

#ifndef lint
static char rcsid[] = "$Header: DBundo.c,v 6.0 90/08/28 18:10:34 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include "magic.h"
#include "database.h"
#include "databaseInt.h"
#include "malloc.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "databaseInt.h"
#include "undo.h"
#include "layout.h"
#include "layout.h"
#include "main.h"
#include "utils.h"
#include "drc.h"
#include "debug.h"

/**** Structures local to this file ****/

    typedef struct
    {
        TileType pyue_type;      
	Group    *pyue_group;
        int      pyue_size;        /* number of vertices */
        PointFloat pyue_points[1]; /* var size */
    } polyUE;

    typedef struct
    {
        TileType wpue_type;      
	Group    *wpue_group;
        char     wpue_style;       /* how end points are handled */
        int      wpue_width;
        int      wpue_size;        /* number of vertices */
        Point    wpue_points[1];   /* var size */
    } wirePathUE;

    typedef struct
    {
        int    flue_width;
	char   flue_strings[3];     /* enough space is allocated for names 
				     * and, text if any.
				     */
    } FlyLineUE;

    typedef struct
    {
      char     pue_flags;       /* see below */ 
      char     pue_strings[3];  /* enouch space is allocated for
				 * property name and old value, and new
				 * value strings.
				 */
    } PropUE;

/* pue_flags, indicates whether old, new values are non-null */
#define UPF_OLD 1
#define UPF_NEW 2

    typedef struct
    {
	Rect	 lue_rect;	/* Location of label */
	char     lue_kind;     /* Label kind, e.g. inout */
	char	 lue_pos;	/* Relative position of label */
	char	 lue_type;	/* Type of tile labelled */
	Group    *lue_group;	/* Group of tile labelled */
	char	 lue_text[4];	/* Text of label.  This is a place
				 * holder only; the actual structure
				 * is allocated to hold all the bytes
				 * in the label, plus the null byte.
				 */
    } labelUE;


    typedef struct
    {
	char	 eue_name[4];	/* Name of cell def edited.  This is
				 * a place holder only, the actual
				 * structure is allocated to hold all
				 * the bytes in the def name, plus
				 * the null byte.
				 */
    } editUE;

    typedef struct
    {
	/* Type of this event */
	int		 cue_action;

	/*
	 * The remainder contains a copy of the important
	 * information from the CellUse.
	 */
	unsigned	 cue_expandMask;
	Transform	 cue_transform;
	ArrayInfo	 cue_array;
	CellDef		*cue_def;
	CellDef		*cue_parent;
	Rect		 cue_bbox;
	char		 cue_id[4];
    } cellUE;

/***
 *** Identifiers for each of the clients defined here
 ***/
UndoType dbUndoIDPaint;
UndoType dbUndoIDAddPoly, dbUndoIDDeletePoly;
UndoType dbUndoIDAddWP, dbUndoIDDeleteWP;
UndoType dbUndoIDPutLabel, dbUndoIDEraseLabel;
UndoType dbUndoIDAddFlyLine, dbUndoIDDeleteFlyLine;
UndoType dbUndoIDSetProp;
UndoType dbUndoIDOpenCell, dbUndoIDCloseCell;
UndoType dbUndoIDCellUse;

/***
 *** Functions to play events forward/backward.
 ***/
    /* Paint */
static void dbUndoPaintForw(register paintUE *up);
static void dbUndoPaintBack(register paintUE *up);

    /* Polygons */
static void dbUndoPolyForw(register polyUE *up);
static void dbUndoPolyBack(register polyUE *up);

    /* WirePaths */
static void dbUndoWPForw(register wirePathUE *up);
static void dbUndoWPBack(register wirePathUE *up);

    /* Labels */
static void dbUndoLabelForw(register labelUE *up);
static void dbUndoLabelBack(register labelUE *up);

    /* FlyLines */
static void dbUndoFlyLineForw(register FlyLineUE *up);
static void dbUndoFlyLineBack(register FlyLineUE *up);

    /* Properties */
static void dbUndoPropForw(register PropUE *up);
static void dbUndoPropBack(register PropUE *up);

    /* Change in edit cell def */
static void dbUndoOpenCell(editUE *eup);
static void dbUndoCloseCell(void);

    /* Cell uses */
static void dbUndoCellForw(register cellUE *up);
static void dbUndoCellBack(register cellUE *up);

/***
 *** Functions invoked at beginning and end
 *** of an undo/redo command.
 ***/
void dbUndoInitPaint(void);

/***
 *** The following points to the CellDef specified in the most
 *** recent database undo operation.  If, when recording the undo
 *** information for a new database operation, the cell def being
 *** modified is different from dbUndoLastCell, we record a special
 *** record on the undo list.
 ***
 *** This strategy "differentially encodes" changes in the cell def
 *** affected during the course of undo.
 ***/
CellDef *dbUndoLastCell;

/*
 * Redisplay for undoing database changes:  
 * USED FOR "paint" OPERATIONS ONLY
 *
 * As we play the undo log backwards or forwards, we keep track
 * of a bounding rectangle, dbUndoAreaChanged for the area changed.
 * We rely on the fact that most database operations are over a
 * compact local area, so keeping around a single rectangular area
 * isn't too bad a compromise.
 *
 * When the edit cell changes, though, we need to call the redisplay
 * package with what we've accumulated, recompute the bounding box of
 * the old edit cell, and then start from scratch again.  The cell def
 * we will pass to the redisplay package is dbUndoLastCell.
 *
 * The flag dbUndoUndid records whether there have been any undo
 * events processed since the last time redisplay and bounding box
 * recomputation were done.
 */
Rect dbUndoAreaChanged;
bool dbUndoUndid;

/*
 * ----------------------------------------------------------------------------
 *
 * dbUndoInit --
 *
 * Initialize the database part of the undo package.
 * Makes the functions contained in here known to the
 * undo module.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Calls the undo package.
 *
 * ----------------------------------------------------------------------------
 */
void
dbUndoInit(void)
{
    void (*nullProc)() = NULL;

    /* Paint: only one client is needed since paint/erase are inverses */
    dbUndoIDPaint = UndoAddClient(dbUndoInitPaint, 
				  dbUndoCloseCell,
				  dbUndoPaintForw, 
				  dbUndoPaintBack, 
				  "paint");

    /* Polygons */
    dbUndoIDAddPoly = UndoAddClient(nullProc, 
				    nullProc,
				    dbUndoPolyForw, 
				    dbUndoPolyBack, 
				    "add polygon");
    dbUndoIDDeletePoly = UndoAddClient(nullProc, 
				       nullProc,
				       dbUndoPolyBack, 
				       dbUndoPolyForw, 
				       "delete polygon");


    /* WirePaths */
    dbUndoIDAddWP = UndoAddClient(nullProc, 
				  nullProc,
				  dbUndoWPForw, 
				  dbUndoWPBack, 
				  "add wirepath");

    dbUndoIDDeleteWP = UndoAddClient(nullProc, 
				     nullProc,
				     dbUndoWPBack, 
				     dbUndoWPForw, 
				     "delete wirepath");

    /* Labels */
    dbUndoIDPutLabel = UndoAddClient(nullProc, 
				     nullProc,
				     dbUndoLabelForw, 
				     dbUndoLabelBack, 
				     "put label");
    dbUndoIDEraseLabel = UndoAddClient(nullProc, 
				       nullProc,
				       dbUndoLabelBack, 
				       dbUndoLabelForw, 
				       "delete label");

    /* FlyLines */
    dbUndoIDAddFlyLine = UndoAddClient(nullProc, 
				       nullProc,
				       dbUndoFlyLineForw, 
				       dbUndoFlyLineBack, 
				       "add flyLine");
    dbUndoIDDeleteFlyLine = UndoAddClient(nullProc, 
					  nullProc,
					  dbUndoFlyLineBack, 
					  dbUndoFlyLineForw, 
					  "delete flyLine");

    /* Properties */
    dbUndoIDSetProp = UndoAddClient(nullProc, 
				    nullProc,
				    dbUndoPropForw, 
				    dbUndoPropBack, 
				    "set property");

    /*
     * Changes in the current target cell of undo for paint/erase/labels.
     * This client is used only inside this file.  Its purpose is
     * to let us save space and time in paint, erase and label undo
     * events.  We maintain dbUndoLastCell to be a pointer to the
     * CellDef last passed to the database undo package when recording
     * a paint, erase, or label undo event.  Only when this changes
     * is it necessary to record the fact on the undo list.  Hence
     * we avoid having to store the cell def affected with each paint,
     * erase, and label undo event.
     */
    dbUndoIDOpenCell = UndoAddClient(nullProc, nullProc,
			dbUndoOpenCell, dbUndoCloseCell, "open cell");
    dbUndoIDCloseCell = UndoAddClient(nullProc, nullProc,
			dbUndoCloseCell, dbUndoOpenCell, "close cell");

    /*
     * Celluses: one client is used for all purposes since we store
     * the action in the undo event.  (We let the undo client encode
     * this information for paint and labels only because there are
     * so many of them that saving space is important).
     */
    dbUndoIDCellUse = UndoAddClient(nullProc, nullProc,
			dbUndoCellForw, dbUndoCellBack, "modify cell use");
    dbUndoLastCell = (CellDef *) NULL;
}



/*
 * ============================================================================
 *
 *			    CHANGE IN "EDIT" CELL
 *
 * ============================================================================
 */

/*
 * ----------------------------------------------------------------------------
 *
 * dbUndoEdit --
 *
 * Record a change in the cell currently being modified by database
 * operations.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Updates the undo list.
 *	Sets dbUndoLastCell to the CellDef supplied.
 *
 * ----------------------------------------------------------------------------
 */

void dbUndoEdit(register CellDef *new)
{
    register editUE *up;
    register CellDef *old = dbUndoLastCell;

    ASSERT(new != old, "dbUndoEdit");

    /*
     * The old cell def can be NULL, eg, when we're at the beginning
     * of the undo log.  If it is NULL, we don't want to create a close
     * record to close the old cell.
     */
    if (old)
    {
	up = (editUE *) UndoNewEvent(dbUndoIDCloseCell,
			(unsigned) strlen(old->cd_name) + 1);
	if (up == (editUE *) NULL)
	    return;
	strcpy(up->eue_name, old->cd_name);
    }

    up = (editUE *) UndoNewEvent(dbUndoIDOpenCell,
		(unsigned) strlen(new->cd_name) + 1);
    if (up == (editUE *) NULL)
	return;
    strcpy(up->eue_name, new->cd_name);
    dbUndoLastCell = new;
}

/*
 * ----------------------------------------------------------------------------
 *
 * dbUndoOpenCell --
 *
 * Set dbUndoLastCell
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Sets dbUndoLastCell
 *
 * ----------------------------------------------------------------------------
 */

void
dbUndoOpenCell(editUE *eup)
{
    CellDef *newDef;

    newDef = DBCellLookDef(eup->eue_name);
    ASSERT(newDef != (CellDef *) NULL, "dbUndoOpenCell");
    dbUndoLastCell = newDef;
}

/*
 * ----------------------------------------------------------------------------
 *
 * dbUndoCloseCell --
 *
 * If any undo events have been played for dbUndoLastCell,
 * process database changes.
 * 
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Changes the bounding box on dbUndoLastCell and propagates this
 *	information to all uses of dbUndoLastCell.  Also, marks any area
 *	changed in dbUndoLastCell as needing redisplay.
 *
 *	Resets dbUndoDid to FALSE and dbUndoAreaChanged to an empty
 *	rectangle.
 *
 * ----------------------------------------------------------------------------
 */

void
dbUndoCloseCell(void)
{
    if (dbUndoUndid && dbUndoLastCell != NULL)
    {
        DBChangedArea(dbUndoLastCell, &dbUndoAreaChanged, &DBAllButSpaceBits, 0);
	dbUndoAreaChanged.r_xbot = dbUndoAreaChanged.r_xtop = 0;
	dbUndoAreaChanged.r_ybot = dbUndoAreaChanged.r_ytop = 0;
	dbUndoUndid = FALSE;
    }
}



/*
 * ----------------------------------------------------------------------------
 *
 * dbUndoInitPaint --
 *
 * Initialize for playing undo events forward/backward for the
 * database module.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Resets the changed area.
 *
 * ----------------------------------------------------------------------------
 */

void
dbUndoInitPaint(void)
{
    dbUndoUndid = FALSE;
    dbUndoAreaChanged.r_xbot = dbUndoAreaChanged.r_xtop = 0;
    dbUndoAreaChanged.r_ybot = dbUndoAreaChanged.r_ytop = 0;
}

/*
 * ----------------------------------------------------------------------------
 *
 * DBUndoFlush --
 *
 * Called by undo module whenever the undo stack is flushed.
 * database module.
 *
 * ----------------------------------------------------------------------------
 */

void
DBUndoFlush(void)
{
  /* no previous edit cell */
  dbUndoLastCell = NULL;
}



/*
 * ============================================================================
 *
 *				PAINT
 *
 * ============================================================================
 */

/***
 *** The procedures to record paint undo events have been expanded
 *** in-line in DBPaintPlaneG() for speed.
 ***/

/*
 * ----------------------------------------------------------------------------
 *
 * dbUndoPaintForw --
 * dbUndoPaintBack --
 *
 * Play forward/backward a paint undo event.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Modifies the database.
 *
 * ----------------------------------------------------------------------------
 */

static void
dbUndoPaintForw(register paintUE *up)
{
    DBPaintPlaneG(dbUndoLastCell->cd_planes[up->pue_plane], &up->pue_rect,
			DBStdEraseTbl(up->pue_oldtype, up->pue_plane),
			up->pue_group,(PaintUndoInfo *) NULL);
    DBPaintPlaneG(dbUndoLastCell->cd_planes[up->pue_plane], &up->pue_rect,
			DBStdPaintTbl(up->pue_newtype, up->pue_plane),
			up->pue_group,(PaintUndoInfo *) NULL);
    dbUndoUndid = TRUE;
    GeoInclude(&up->pue_rect, &dbUndoAreaChanged);
}

static void
dbUndoPaintBack(register paintUE *up)
{
    DBPaintPlaneG(dbUndoLastCell->cd_planes[up->pue_plane], &up->pue_rect,
			DBStdEraseTbl(up->pue_newtype, up->pue_plane),
			up->pue_group, (PaintUndoInfo *) NULL);
    DBPaintPlaneG(dbUndoLastCell->cd_planes[up->pue_plane], &up->pue_rect,
			DBStdPaintTbl(up->pue_oldtype, up->pue_plane),
			up->pue_group, (PaintUndoInfo *) NULL);

    dbUndoUndid = TRUE;
    (void) GeoInclude(&up->pue_rect, &dbUndoAreaChanged);
}

/*
 * ============================================================================
 *
 *				LABELS
 *
 * ============================================================================
 */

    /*
     * labelSize(n) is the size of a labelUE large enough to hold
     * a string of n characters.  Space for the trailing NULL byte
     * is allocated automatically.
     */

#define	labelSize(n)	(sizeof (labelUE) - 3 + (n))

/*
 * ----------------------------------------------------------------------------
 *
 * DBUndoPutLabel --
 *
 * Record on the undo list the painting of a new label.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Updates the undo list.
 *
 * ----------------------------------------------------------------------------
 */

void
DBUndoPutLabel(CellDef *cellDef,       	/* CellDef being modified */
	       register Rect *rect,     /* Box definining label.  The lower left coordinate
					 * of the box determines the tile to which the label
					 * is attached, although it needn't be the physically
					 * lower left coordinate of the box.
					 */
	       int pos,        		/* Relative position to point */
	       char *text,     		/* Text of label */
	       TileType type,          	/* Type of tile being labelled */
	       Group *group,            /* Group label belongs to */
	       int kind)
{
    register labelUE *lup;

    if (!UndoIsEnabled(cellDef))
	return;

    if (cellDef != dbUndoLastCell) dbUndoEdit(cellDef);
    lup = (labelUE *) UndoNewEvent(dbUndoIDPutLabel,
			(unsigned) labelSize(strlen(text)));
    if (lup == (labelUE *) NULL)
	return;

    lup->lue_rect = *rect;
    lup->lue_pos = pos;
    lup->lue_type = type;
    lup->lue_group = group;
    lup->lue_kind = kind;
    strcpy(lup->lue_text, text);
}

/*
 * ----------------------------------------------------------------------------
 *
 * DBUndoEraseLabel --
 *
 * Record on the undo list the erasing of an existing label
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Updates the undo list.
 *
 * ----------------------------------------------------------------------------
 */

void
DBUndoEraseLabel(CellDef *cellDef,    	/* Cell being modified */
		 register Rect *rect,   /* Box definining label.  The lower left coordinate
					 * of the box determines the tile to which the label
					 * is attached, although it needn't be the physically
					 * lower left coordinate of the box.
					 */
		 int pos,      		/* Relative position to point */
		 char *text,   		/* Text of label */
		 TileType type,       	/* Type of tile being labelled */
		 Group *group,
		 int kind)
{
    register labelUE *lup;

    if (!UndoIsEnabled(cellDef))
	return;

    if (cellDef != dbUndoLastCell) dbUndoEdit(cellDef);
    lup = (labelUE *) UndoNewEvent(dbUndoIDEraseLabel,
			(unsigned) labelSize(strlen(text)));
    if (lup == (labelUE *) NULL)
	return;

    lup->lue_rect = *rect;
    lup->lue_pos = pos;
    lup->lue_type = type;
    lup->lue_group = group;
    lup->lue_kind = kind;
    strcpy(lup->lue_text, text);
}

/*
 * ----------------------------------------------------------------------------
 *
 * dbUndoLabelForw --
 * dbUndoLabelBack --
 *
 * Play forward/backward a label undo event.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Modifies the database.
 *
 * ----------------------------------------------------------------------------
 */

static void
dbUndoLabelForw(register labelUE *up)
{
    (void) DBLabelAddG(dbUndoLastCell, &up->lue_rect, up->lue_pos,
	up->lue_text, up->lue_type, up->lue_group,up->lue_kind);
    DBChangedArea(dbUndoLastCell, &up->lue_rect, NULL, DBCF_LABEL);

    /* record that this cell def has been changed, for
     * bounding box recomputation.
     */

    dbUndoUndid = TRUE;
}

static void
dbUndoLabelBack(register labelUE *up)
{
    (void) DBLabelsEraseByContentG(dbUndoLastCell, &up->lue_rect,
		up->lue_pos, up->lue_type, up->lue_text, up->lue_group);

    /*
     * Record that this cell def has changed, for bounding box
     * recomputing.  See the comments in dbUndoLabelForw above.
     */
    if (up->lue_type == TT_SPACE)
	dbUndoUndid = TRUE;
}


/*
 * ============================================================================
 *
 *				POLYGONS
 *
 * ============================================================================
 */

    /*
     * polyUESize(n) is the size of a polyUE large enough to hold
     * a polygon of n vertices. 
     */

#define	polyUESize(n)	(sizeof(polyUE) + (n-1)*sizeof(PointFloat))

/*
 * ----------------------------------------------------------------------------
 *
 * DBUndoAddPoly --
 *
 * Record a polygon add on the undo list.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Updates the undo list.
 *
 * ----------------------------------------------------------------------------
 */

void
DBUndoAddPoly(CellDef *def,       	/* CellDef being modified */
	      Polygon *poly)            /* the new polygon */
{
    register polyUE *pyue;
    int i;
    int size = poly->poly_size;

    if (!UndoIsEnabled(def)) return;
    if (def != dbUndoLastCell) dbUndoEdit(def);

    pyue = (polyUE *) UndoNewEvent(dbUndoIDAddPoly,
				   polyUESize(size));

    if (pyue == NULL) return;

    pyue->pyue_type = poly->poly_type;
    pyue->pyue_group = poly->poly_group;
    pyue->pyue_size = size;

    /* copy points */
    for(i=0; i<size; i++)
    {
      pyue->pyue_points[i] = poly->poly_points[i];
    }
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBUndoDeletePoly --
 *
 * Record polygon deletion on undo list.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Updates the undo list.
 *
 * ----------------------------------------------------------------------------
 */

void
DBUndoDeletePoly(CellDef *def,    	/* Cell being modified */
		 Polygon *poly)         /* polygon being deleted */

{
    register polyUE *pyue;
    int i;
    int size = poly->poly_size;

    if (!UndoIsEnabled(def)) return;
    if (def != dbUndoLastCell) dbUndoEdit(def);

    pyue = (polyUE *) UndoNewEvent(dbUndoIDDeletePoly,
				   polyUESize(size));

    if (pyue == NULL) return;

    pyue->pyue_type = poly->poly_type;
    pyue->pyue_group = poly->poly_group;
    pyue->pyue_size = size;

    /* copy points */
    for(i=0; i<size; i++)
    {
      pyue->pyue_points[i] = poly->poly_points[i];
    }
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbUndoPolyForw --
 * dbUndoPolyBack --
 *
 * Play a polygon add/delete event forward/backward.
 *
 * NOTE: forward delete = backward add, and backward delete = forward add.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Modifies the database.
 *
 * ----------------------------------------------------------------------------
 */

static void
dbUndoPolyForw(polyUE *pyue)
{
  Polygon *poly;
  PointFloat *points;

  points = DBPointsFAlloc(pyue->pyue_size, &pyue->pyue_points[0], NULL);
  poly = DBPolyNew(dbUndoLastCell, 
		   pyue->pyue_type, 
		   pyue->pyue_size, 
		   points,
		   NULL, /* not part of wirepath */ 
		   TRUE /* notify */);   /* TODO, don't do notify here! */
  poly->poly_group = pyue->pyue_group;

  /* TODO: 
     adjust change area and set dbUndoUndd
     dbUndoUndid = TRUE;
  */
}

static void
dbUndoPolyBack(polyUE *pyue)
{
  Polygon *poly;

  /* TODO change DBPolyFindDup to DBPolyFind - get rid of temp below */

  /* find matching polygon in def */
  poly = DBPolyFind(dbUndoLastCell,
		    pyue->pyue_type,
		    pyue->pyue_group,
		    pyue->pyue_size,
		    &pyue->pyue_points[0],
		    NULL,  /* not part of wirepath */
		    NULL); /* no need to transform */

  ASSERT(poly,"dbUndoPolyBack");

  /* delete the polygon */
  DBPolyDelete(dbUndoLastCell,
	       poly,
	       TRUE /* notify */);  /* TODO don't do notify here! */

    /* TODO: 
       adjust change area and set dbUndoUndd
       dbUndoUndid = TRUE;
    */
}



/*
 * ============================================================================
 *
 *				WIREPATHS
 *
 * ============================================================================
 */

    /*
     * wirePathUESize(n) is the size of a wirePathUE large enough to hold
     * a wirepath of n points. 
     */

#define	wirePathUESize(n) (sizeof(wirePathUE) + (n-1)*sizeof(Point))

/*
 * ----------------------------------------------------------------------------
 *
 * DBUndoAddWP --
 *
 * Record a wirepath add on the undo list.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Updates the undo list.
 *
 * ----------------------------------------------------------------------------
 */

void
DBUndoAddWP(CellDef *def,       	/* CellDef being modified */
	    WirePath *wp)                /* the new wirepath */
{
    register wirePathUE *wpue;
    int i;
    int size = wp->wp_size;

    if (!UndoIsEnabled(def)) return;
    if (def != dbUndoLastCell) dbUndoEdit(def);

    wpue = (wirePathUE *) UndoNewEvent(dbUndoIDAddWP,
				       wirePathUESize(size));

    if (wpue == NULL) return;

    wpue->wpue_type = wp->wp_type;
    wpue->wpue_group = wp->wp_group;
    wpue->wpue_style = wp->wp_style;
    wpue->wpue_width = wp->wp_width;
    wpue->wpue_size = size;
 
    /* copy points */
    for(i=0; i<size; i++)
    {
      wpue->wpue_points[i] = wp->wp_points[i];
    }
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBUndoDeleteWP --
 *
 * Record wirepath deletetion on undo list.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Updates the undo list.
 *
 * ----------------------------------------------------------------------------
 */

void
DBUndoDeleteWP(CellDef *def,    	/* Cell being modified */
	       WirePath *wp)             /* wirepath being deleted */

{
    register wirePathUE *wpue;
    int i;
    int size = wp->wp_size;

    if (!UndoIsEnabled(def)) return;

    if (def != dbUndoLastCell) dbUndoEdit(def);

    wpue = (wirePathUE *) UndoNewEvent(dbUndoIDDeleteWP,
				       wirePathUESize(size));

    if (wpue == NULL) return;

    wpue->wpue_type = wp->wp_type;
    wpue->wpue_group = wp->wp_group;
    wpue->wpue_style = wp->wp_style;
    wpue->wpue_width = wp->wp_width;
    wpue->wpue_size = size;
 
    /* copy points */
    for(i=0; i<size; i++)
    {
      wpue->wpue_points[i] = wp->wp_points[i];
    }
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbUndoWPForw --
 * dbUndoWPBack --
 *
 * Play a wirepath add/delete event forward/backward.
 *
 * NOTE: forward delete = backward add, and backward delete = forward add.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Modifies the database.
 *
 * ----------------------------------------------------------------------------
 */

static void
dbUndoWPForw(wirePathUE *wpue)
{
  WirePath *wp;
  Point *points;

  points = DBPointsAlloc(wpue->wpue_size,
			 &wpue->wpue_points[0],
			 NULL);

  wp = DBWPathNew(dbUndoLastCell, 
		  wpue->wpue_type, 
		  wpue->wpue_style,
		  wpue->wpue_width,
		  wpue->wpue_size, 
		  points,
		  TRUE,  /* TODO don't do notify here */
		  NULL);
  wp->wp_group = wpue->wpue_group;

  /* TODO: 
     adjust change area and set dbUndoUndd
     dbUndoUndid = TRUE;
  */
}

static void
dbUndoWPBack(wirePathUE *wpue)
{
  WirePath *temp;
  WirePath *wp;

  /* find matching wirepath in def */
  wp = DBWPathFind(dbUndoLastCell, 
		   wpue->wpue_type, 
		   wpue->wpue_group,
		   wpue->wpue_style,
		   wpue->wpue_width,
		   wpue->wpue_size, 
		   &wpue->wpue_points[0],
		   NULL /* no need to  transform points */);

  ASSERT(wp,"dbUndoWPBack");

  /* delete it */
  DBWPathDelete(dbUndoLastCell,
		wp,
		TRUE /* notify */);  /* TODO don't do notify here! */


    /* TODO: 
       adjust change area and set dbUndoUndd
       dbUndoUndid = TRUE;
    */
}


/*
 * ============================================================================
 *
 *				FLYLINES
 *
 * ============================================================================
 */

/*
 * ----------------------------------------------------------------------------
 *
 * dbUndoFlyLineAdd --
 *
 * Record on the undo list the creation of a new flyLine.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Updates the undo list.
 *
 * ----------------------------------------------------------------------------
 */

void
dbUndoFlyLineAdd(CellDef *cellDef,     	/* CellDef being modified */
		 char *name1,     	/* first end point of flyLine */
		 char *name2,     	/* second end point of flyLine */
		 int width,             /* width in pixels */  	 
		 char *text)            /* text to display with flyline */   	 
{


    FlyLineUE *flue;
    char *dst;

    if (!UndoIsEnabled(cellDef)) return;

    if (cellDef != dbUndoLastCell) dbUndoEdit(cellDef);

    if(text == NULL) text="";

    flue = (FlyLineUE *) UndoNewEvent(dbUndoIDAddFlyLine,
				      (unsigned) sizeof(FlyLineUE) +
				      strlen(name1) +
				      strlen(name2) +
				      strlen(text));
    if (flue == (FlyLineUE *) NULL) return;

    flue->flue_width = width; 
    for(dst=flue->flue_strings; *name1; name1++) *dst++=*name1;
    *dst++='\0';
    for(; *name2; name2++) *dst++=*name2;
    *dst++='\0';
    for(; *text; text++) *dst++=*text;
    *dst='\0';
}

/*
 * ----------------------------------------------------------------------------
 *
 * dbUndoFlyLineDelete --
 *
 * Record on the undo list the deletion of a flyline
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Updates the undo list.
 *
 * ----------------------------------------------------------------------------
 */

void
dbUndoFlyLineDelete(CellDef *cellDef,  	/* Cell being modified */
	       char *name1,     	/* first end point of flyLine */
	       char *name2,     	/* second end point of flyLine */
	       int width,
	       char *text) 	    
{
    register FlyLineUE *flue;
    char *dst;

    if (!UndoIsEnabled(cellDef)) return;

    if (cellDef != dbUndoLastCell) dbUndoEdit(cellDef);

    if(text == NULL) text="";

    flue = (FlyLineUE *) UndoNewEvent(dbUndoIDDeleteFlyLine,
				      (unsigned) sizeof(FlyLineUE) +
				      strlen(name1) +
				      strlen(name2) +
				      strlen(text));
    if (flue == (FlyLineUE *) NULL) return;

    flue->flue_width = width; 
    for(dst=flue->flue_strings; *name1; name1++) *dst++=*name1;
    *dst++='\0';
    for(; *name2; name2++) *dst++=*name2;
    *dst++='\0';
    for(; *text; text++) *dst++=*text;
    *dst='\0';
}

/*
 * ----------------------------------------------------------------------------
 *
 * dbUndoFlyLineForw --
 * dbUndoFlyLineBack --
 *
 * Play forward/backward a flyLine undo event.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Modifies the database.
 *
 * ----------------------------------------------------------------------------
 */

static void
dbUndoFlyLineForw(register FlyLineUE *up)
{
  char *name1, *name2, *text;

  name2 = name1 = up->flue_strings;
  while(*name2) name2++;
  name2++;
  text=name2;
  while(*text) text++;
  text++;
  
  dbFlyLineAdd(dbUndoLastCell, name1, name2, up->flue_width, text);
}

static void
dbUndoFlyLineBack(register FlyLineUE *up)
{
  char *name1, *name2;

  name2 = name1 = up->flue_strings;
  while(*name2) name2++;
  name2++;
  
  dbFlyLineDelete(dbUndoLastCell, name1, name2);
}



/*
 * ============================================================================
 *
 *				PROPERTIES
 *
 * ============================================================================
 */

/*
 * ----------------------------------------------------------------------------
 *
 * dbUndoPropSet
 *
 * Record a property set op on the undo list
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Updates the undo list.
 *
 * ----------------------------------------------------------------------------
 */

void
dbUndoPropSet(CellDef *cellDef,     	/* CellDef being modified */
	      char *name,     	        /* first end point of flyLine */
	      char *old,                /* old property value */
	      char *new)                /* new property value */
{
    PropUE *pue;
    char *dst;
    char flags = 0;

    if (!UndoIsEnabled(cellDef)) return;

    if (cellDef != dbUndoLastCell) dbUndoEdit(cellDef);


    if(old) flags |= UPF_OLD;  
    if(new) flags |= UPF_NEW;

    if(!old) old = "";
    if(!new) new = "";

    pue = (PropUE *) UndoNewEvent(dbUndoIDSetProp,
				  (unsigned) sizeof(PropUE) +
				  strlen(name) +
				  strlen(old) +
				  strlen(new));
    if (!pue) return;

    pue->pue_flags = flags; 
    for(dst=pue->pue_strings; *name; name++) *dst++=*name;
    *dst++='\0';
    for(; *old; old++) *dst++=*old;
    *dst++='\0';
    for(; *new; new++) *dst++=*new;
    *dst='\0';
}

/*
 * ----------------------------------------------------------------------------
 *
 * dbUndoPropSet --
 * dbUndoPropSet --
 *
 * Play forward/backward a property undo event.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Modifies the database.
 *
 * ----------------------------------------------------------------------------
 */

static void
dbUndoPropForw(register PropUE *up)
{
  char *name, *old, *new;

  old = name = up->pue_strings;
  while(*old) old++;
  old++;
  new=old;
  while(*new) new++;
  new++;
  
  DBPropSet(dbUndoLastCell, 
	    name,
	    up->pue_flags&UPF_NEW ? new : NULL);

}

static void
dbUndoPropBack(register PropUE *up)
{
  char *name, *old, *new;

  old = name = up->pue_strings;
  while(*old) old++;
  old++;
  new=old;
  while(*new) new++;
  new++;
  
  DBPropSet(dbUndoLastCell, 
	    name,
	    up->pue_flags&UPF_OLD ? old : NULL);

}


/*
 * ============================================================================
 *
 *				CELL MANIPULATION
 *
 * ============================================================================
 */

    /*
     * Compute the size of a cellUE, with sufficient space
     * at the end to store the use id.
     */
#define	cellSize(n)	(sizeof (cellUE) - 3 + (n))

/*
 * ----------------------------------------------------------------------------
 *
 * DBUndoCellUse --
 *
 * Record one of the following subcell actions:
 *	UNDO_CELL_PLACE		placement in a parent
 *	UNDO_CELL_DELETE	removal from a parent
 *	UNDO_CELL_CLRID		deleting the use id
 *	UNDO_CELL_SETID		setting the use id
 *
 * The last two, deleting and setting the use id, normally occur in
 * pairs except when the name is set for the first time.
 *
 * Because both the parent and child cell uses are stored
 * in the def, we don't bother to use or update dbUndoLastCell.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Updates the undo list.
 *
 * ----------------------------------------------------------------------------
 */

void
DBUndoCellUse(register CellUse *use, int action)
{
    register cellUE *up;

    /* DEBUG
    static char *actions[] = { "CLRID","SETID","PLACE","DELETE" };
    fprintf(stderr,"DEBUG DBUndoCellUse, action=%s subcell=%s parent=%s\n",
	    actions[action], use->cu_def->cd_name, use->cu_parent->cd_name);
    */

	    
    if (!UndoIsEnabled(use->cu_parent)) return;
    /*    fprintf(stderr,"DEBUG DBUndoCellUse, undoenabled.\n"); */

    up = (cellUE *) UndoNewEvent(dbUndoIDCellUse,
			(unsigned) cellSize(strlen(use->cu_id)));

    up->cue_action = action;
    up->cue_transform = use->cu_transform;
    up->cue_array = use->cu_array;
    up->cue_def = use->cu_def;
    up->cue_parent = use->cu_parent;
    up->cue_expandMask = use->cu_expandMask;
    up->cue_bbox = use->cu_bbox;
    strcpy(up->cue_id, use->cu_id);
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbUndoCellForw --
 * dbUndoCellBack --
 *
 * Play a celluse undo event forward or backward.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Modifies the database.
 *
 * ----------------------------------------------------------------------------
 */

static void
dbUndoCellForw(register cellUE *up)
{
    register CellUse *use;
    static CellUse *renameUse; /* pass use between CLRID and SETID */

    /***
    static char *actions[] = { "CLRID","SETID","PLACE","DELETE" };
    fprintf(stderr,"DEBUG DBUndoCellForw, action=%s subcell=%s parent=%s\n",
	    actions[up->cue_action], up->cue_id, up->cue_parent->cd_name);
    ***/

    switch (up->cue_action)
    {
	case UNDO_CELL_PLACE:
	    use = DBCellNewUse(up->cue_def, (char *) NULL);
	    use->cu_transform = up->cue_transform;
	    use->cu_array = up->cue_array;
	    use->cu_expandMask = up->cue_expandMask;
	    use->cu_bbox = up->cue_bbox;
	    use->cu_id = StrDup((char **) NULL, up->cue_id);
	    DBInstanceAdd(use, up->cue_parent, 
			  DBIA_INFOMSG_ON_RENAME|DBIA_DUP_OK);
	    DBChangedArea(up->cue_parent, &up->cue_bbox, NULL, DBCF_INSTANCE);
	    if(up->cue_def->cd_flags&CD_GENERATED) 
	      DBExpand(use, LAY_ALL_WINDOWS, TRUE); 
	    break;
        case UNDO_CELL_DELETE:
	    use = DBInstanceFindByName(up->cue_id, 
				       up->cue_parent);
	    DBInstanceUnlink(use, up->cue_parent);
	    DBInstanceUnplace(use);
	    DBCellDeleteUse(use);
	    DBChangedArea(up->cue_parent, &up->cue_bbox, NULL, DBCF_INSTANCE);
	    break;
	/*
	 * use Renames generate a UNDO_CELL_CLRID immediately
	 * followed by a UNDO_CELL_SETID event.
	 */
        case UNDO_CELL_SETID:
	    ASSERT(renameUse!=NULL,"dbUndoCellForw");
	    (void) DBInstanceRename(renameUse, up->cue_id);
	    DBChangedArea(up->cue_parent, 
			  &up->cue_bbox, 
			  &DBAllButSpaceBits,
			  DBCF_DISPLAY);
	    break;
	case UNDO_CELL_CLRID:
	  /* just find use (with current name, 
	   * rename is done on immediately following SETID op 
	   */
	  renameUse = DBInstanceFindByName(up->cue_id, 
					   up->cue_parent);
	  break;
    }
}

void
dbUndoCellBack(register cellUE *up)
{
    register CellUse *use;
    static CellUse *renameUse; /* pass use between CLRID and SETID */

    /*** DEBUG
    static char *actions[] = { "CLRID","SETID","PLACE","DELETE" };
    fprintf(stderr,
	    "DEBUG DBUndoCellBack, action=%s subcell=%s parent=%s\n",
	    actions[up->cue_action], 
	    up->cue_id, 
	    up->cue_parent->cd_name);
    ***/

    switch (up->cue_action)
    {
	case UNDO_CELL_DELETE:
	    use = DBCellNewUse(up->cue_def, (char *) NULL);
	    use->cu_transform = up->cue_transform;
	    use->cu_array = up->cue_array;
	    use->cu_expandMask = up->cue_expandMask;
	    use->cu_bbox = up->cue_bbox;
	    use->cu_id = StrDup((char **) NULL, up->cue_id);
	    DBInstanceAdd(use, up->cue_parent, 
			  DBIA_INFOMSG_ON_RENAME|DBIA_DUP_OK);
	    DBChangedArea(up->cue_parent, &up->cue_bbox, NULL, DBCF_INSTANCE);
	    if(up->cue_def->cd_flags&CD_GENERATED) 
	      DBExpand(use, LAY_ALL_WINDOWS, TRUE); 
	    break;
        case UNDO_CELL_PLACE:
	    use = DBInstanceFindByName(up->cue_id, 
				       up->cue_parent);
	    DBInstanceUnlink(use, up->cue_parent);
	    DBInstanceUnplace(use);
	    DBCellDeleteUse(use);
	    DBChangedArea(up->cue_parent, &up->cue_bbox, NULL, DBCF_INSTANCE);
	    break;
	/*
	 * use Renames generate a UNDO_CELL_CLRID immediately
	 * followed by a UNDO_CELL_SETID event.
	 */
        case UNDO_CELL_CLRID:
	  /* since we are going backwards, this is the set */
	  ASSERT(renameUse!=NULL,"dbUndoCellForw");
	  (void) DBInstanceRename(renameUse, up->cue_id);
	  DBChangedArea(up->cue_parent, 
			&up->cue_bbox, 
			&DBAllButSpaceBits,
			DBCF_DISPLAY);
	  break;
	case UNDO_CELL_SETID:
	  /* since we are going backwards, this is the clear */ 
	  /* just find use (with current name, 
	   * rename is done on immediately following SETID op 
	   */
	  renameUse = DBInstanceFindByName(up->cue_id, 
					   up->cue_parent);
	  break;
    }
}











