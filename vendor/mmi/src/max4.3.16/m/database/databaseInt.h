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
 * databaseInt.h --
 *
 * Definitions internal to the database module.
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
 * Needs to include: magic.h, tiles.h, database.h
 *
 * rcsid $Header: databaseInt.h,v 6.0 90/08/28 18:10:40 mayo Exp $
 */
#ifndef _DATABASEINT
#define _DATABASEINT

#ifndef	_MAGIC
#include "magic.h"
#endif	_MAGIC
#ifndef	_TILE
#include "tile.h"
#endif	_TILE
#ifndef	_DATABASE
#include "database.h"
#endif	_DATABASE

/* ----------- Argument to area search when writing out cell ---------- */

struct writeArg
{
    FILE	*wa_file;	/* File to which to output */
    TileType	 wa_type;	/* Type of tile being searched for */
    bool	 wa_found;	/* Have any tiles been found yet? */
};

/* --------------------- Undo info for painting ----------------------- */

/* The following is the structure of the undo info saved for each tile */
typedef struct
{
    Rect	 pue_rect;	/* Rectangle painted/erased */
    char	 pue_oldtype;	/* Material erased */
    char	 pue_newtype;	/* Material painted */
    Group        *pue_group;    /* Group affected */      
    char	 pue_plane;	/* Plane index affected */
} paintUE;

/* -------------- Codes for undo of cell use operations --------------- */

#define UNDO_CELL_CLRID		0	/* Clear use id */
#define UNDO_CELL_SETID		1	/* Set use id */
#define UNDO_CELL_PLACE		2	/* Create and place cell use */
#define UNDO_CELL_DELETE	3	/* Delete and destroy cell use */

/* --------------- Default types and planes, and name lists ----------- */

/*
 * Type or plane names.
 * These are invisible outside of the technology module
 * except via DBTechNameType() and DBTechNamePlane().
 * The first name in any list is by convention pointed
 * to by DBTypeLongNameTbl[] or DBPlaneLongNameTbl[]
 * respectively.
 */
typedef struct namelist
{
    struct namelist	*sn_next;	/* Next name in table */
    struct namelist	*sn_prev;	/* Previous name in table */
    char		*sn_name;	/* Text of name */
    ClientData		 sn_value;	/* Value (TileType or plane number) */
    bool		 sn_primary;	/* If TRUE, this is the primary name */
} NameList;

typedef struct
{
    int		 dp_plane;	/* Internal index for this plane */
    char	*dp_names;	/* List of comma-separated names */
} DefaultPlane;

typedef struct
{
    TileType	 dt_type;	/* This type's number */
    int		 dt_plane;	/* Plane on which this type resides */
    char	*dt_names;	/* List of comma-separated names.  The first
				 * is the "long" name of the type.
				 */
    bool	dt_print;	/* TRUE if layer is to be printed by
				 * DBTechPrintTypes.  These are layers
				 * that user would normally paint.
				 */
} DefaultType;

extern NameList dbTypeNameLists;		/* Type abbreviations */
extern NameList dbPlaneNameLists;		/* Plane abbreviations */
extern DefaultPlane dbTechDefaultPlanes[];	/* Builtin planes */
extern DefaultType dbTechDefaultTypes[];	/* Builtin types */

/* ------------------- Plane Dependencies ----------------------- */
/* (This is not used yet) */ 

extern int DBPlaneFlags[];
#define DBF_AUTO_GENERATED 1
#define DBF_TEMP 2
extern TileTypeBitMask DBPlaneDependencies[];

/* --------------------- Composition rule tables ---------------------- */

/* Saved contact compose/erase rules */
typedef struct
{
    TileType	 rp_a, rp_b;	/* Two types in pair */
} TypePair;

typedef struct
{
    int		 r_ruleType;	/* Kind of rule (RULE_* below) */
    TileType	 r_result;	/* Result type */
    int		 r_npairs;	/* Number of type pairs in rule */
    TypePair	 r_pairs[NT];	/* Pairs of types in rule */
} Rule;

/*
 * Types of rules in the compose section of a technology file
 * (represented in the Rule structure above).
 */
#define	RULE_DECOMPOSE	0
#define	RULE_COMPOSE	1
#define	RULE_PAINT	2
#define	RULE_ERASE	3

extern int dbNumSavedRules;
extern Rule dbSavedRules[];

/* used to keep track of file size on ".max" file output */
extern int DBFileOffset;

/* -------------------- Internal procedure headers -------------------- */

/* initialization */
extern void dbCellInit(void);
extern void dbUndoInit(void);
extern void dbLayersInit(void);
extern void dbChunkInit(void);

extern void dbTclSearchInit(Tcl_Interp *interp);

/* add/remove use from subcell bplane */
extern void dbInstancePlace(CellUse *celluse);
extern void dbInstanceUnplace(CellUse *celluse);


void
dbUndoPropSet(CellDef *cellDef,     	/* CellDef being modified */
	      char *name,     	        /* first end point of flyLine */
	      char *old,                /* old property value */
	      char *new);               /* new property value */

void dbFlyLineAdd(CellDef *def,       /* Cell in which flyline is to be added */
	    char *name1,         /* hierarchical name of first label */
	    char *name2,         /* hierarchical name of second label */
	    int  width,          /* width in pixels */
  	    char *text);         /* text to display with flyline (or NULL) */	  
void
dbFlyLineDelete(CellDef *def,       /* Cell in which flyline is to be deleted */
	    char *name1,         /* hierarchical name of first label */
	    char *name2);        /* hierarchical name of second label */
void
dbUndoFlyLineAdd(CellDef *def,       /* Cell in which flyline is to be added */
	    char *name1,         /* hierarchical name of first label */
	    char *name2,         /* hierarchical name of second label */
            int width,           /* width in pixels to draw flyline */ 
            char *text);         /* text to display with flyline */
void
dbUndoFlyLineDelete(CellDef *def,       /* Cell in which flyline is to be deleted */
	    char *name1,         /* hierarchical name of first label */
	    char *name2,         /* hierarchical name of second label */
	    int width,           /* width in pixels */ 		    
	    char *text);         /* text to display */	    

extern bool dbFlyLinesWrite(CellDef *def, FILE *f); 
extern bool dbFlyLinesRead(CellDef *def, char *lineBuf, int bufSize, FILE *f); 
extern void dbFlyLinesCopy(CellDef *srcDef, CellDef *destDef);

extern char *dbReadNextLine(char *line, int len, register FILE *f);
extern bool dbInstancesWrite(CellDef *def, FILE *f);
extern bool dbInstancesRead(CellDef *def, char *lineBuf, int bufSize, FILE *f); 

extern bool dbGroupsWrite(CellDef *def, FILE *f); 
extern bool dbGroupsRead(CellDef *def, char *lineBuf, int bufSize, FILE *f); 
extern void dbGroupsFree(CellDef *def); 

extern bool dbPolyWrite(CellDef *def, FILE *f);
extern bool dbPolyRead(CellDef *def, char *lineBuf, int bufSize, FILE *f); 

extern bool dbPropertiesWrite(CellDef *def, FILE *f);
extern bool dbPropertiesRead(CellDef *def, char *lineBuf, int bufSize, FILE *f); 
extern bool dbWPathWrite(CellDef *def, FILE *f);
extern bool dbWPathRead(CellDef *def, char *lineBuf, int bufSize, FILE *f); 

extern void DBUndoAddPoly(CellDef *def, Polygon *poly); 
extern void DBUndoDeletePoly(CellDef *def, Polygon *poly); 

extern void DBUndoAddWP(CellDef *def, WirePath *wp); 
extern void DBUndoDeleteWP(CellDef *def, WirePath *wp); 

/* label ihash funcs */
int dbLabelKeyHash(void *key);
int dbLabelKeyEq(void *key1, void *key2);

extern void DBUndoEraseLabel(CellDef *cellDef, 
			     register Rect *rect, 
			     int pos, 
			     char *text, 
			     TileType type,
			     Group *group,
			     int flags);

extern void DBUndoPutLabel(CellDef *cellDef, 
			   register Rect *rect, 
			   int pos, 
			   char *text, 
			   TileType type,
			   Group *group,
			   int flags);

extern void DBUndoEraseLabel(CellDef *cellDef, 
			     register Rect *rect, 
			     int pos, 
			     char *text, 
			     TileType type,
			     Group *group,
			     int flags);
extern void DBUndoCellUse(register CellUse *use, int action);

extern void dbBBoxCellCompute(CellDef *cellDef);
extern void dbBBoxSetUserPlanes(TileTypeBitMask *mask);
extern bool dbBBoxUserTypes2S(char *buf, int bufSize);

extern ClientData dbTechNameLookup(char *str, NameList *table);

/* --------------- Internal database technology variables ------------- */

/* if nonzero, paint debugging is on (-DPAINTDEBUG also required) */
extern int dbPaintDebug;

/* scale factor applied when reading .max file (usually 1.0) */
extern double dbRdScaleFile2DB;

/* max rounding error since last reset */
extern double dbRdScaleFile2DBErr;

/* tcl linked, if reset, flylines are treated as annotations only */
extern bool dbFlylinesSave;
/* if non-zero, default Res for Max files 
 * (overridden by __RESOLUTION__ property)
 * linked to tclvar DB_READ_LEGACY_RES
 */
extern double dbReadLegacyRes;

/* tcl linked */
extern bool dbReadReportRoundingErrors;

/* if set, wirepaths are rendered as single polygon,
 * instead of one polygon per edge.
 * (tcl linked)
 */ 
extern bool dbWPathSinglePolygon;

/* if set, identical coincident instances are permitted.
 * (tcl linked)
 */ 
extern bool dbInstanceDupOK;

/*
 * Macros to set the paint result tables.
 * The argument order is different from the index order in
 * the tables, for historical reasons.
 *
 * Usage:
 *	dbSetPaintEntry(oldType, paintType, planeNum, resultType)
p *	dbSetEraseEntry(oldType, paintType, planeNum, resultType)
 *	dbSetWriteEntry(oldType, paintType, resultType)
 */
#define	dbSetPaintEntry(h,t,p,r) 	(DBPaintResultTbl[p][t][h] = r)
#define	dbSetEraseEntry(h,t,p,r)	(DBEraseResultTbl[p][t][h] = r)
#define	dbSetWriteEntry(h,t,r)		(DBWriteResultTbl[t][h] = r)

extern TileTypeBitMask dbNotDefaultEraseTbl[];
extern TileTypeBitMask dbNotDefaultPaintTbl[];

#define	IsDefaultErase(h, e)	(!TTMaskHasType(&dbNotDefaultEraseTbl[h], e))
#define	IsDefaultPaint(h, p)	(!TTMaskHasType(&dbNotDefaultPaintTbl[h], p))

/*
 * Macros to determine whether painting or erasing type s affects
 * type t on its home plane.  The check for t != TT_SPACE is because
 * TT_SPACE has no specific home plane and is handled specially.
 */
#define	PAINTAFFECTS(t, s) \
	((t) != TT_SPACE && DBStdPaintEntry((t), (s), DBPlane(t)) != (t))
#define	ERASEAFFECTS(t, s) \
	((t) != TT_SPACE && DBStdEraseEntry((t), (s), DBPlane(t)) != (t))

#endif _DATABASEINT

