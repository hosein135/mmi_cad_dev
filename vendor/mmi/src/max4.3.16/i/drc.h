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
 * drc.h --
 *
 * Definitions for the DRC module.
 *
 * Copyright (C) 1983 Regents of the University of California
 * All rights reserved.
 *
 * Needs to include: magic.h database.h
 *
 * rcsid $Header: drc.h,v 4.10 92/07/20 13:34:17 mayo Exp $
 */

#ifndef _DRC
#define	_DRC

#ifndef	_MAGIC
#include "magic.h"
#endif	_MAGIC
#ifndef	_DATABASE
#include "database.h"
#endif	_DATABASE


/* ----------------- component of DRC rule table ---------------------------- */

typedef struct drccookie
{
    int    	       drcc_dist;	/* Extent of rule from edge. */
    TileTypeBitMask       drcc_mask;	/* Legal types on RHS */
    TileTypeBitMask       drcc_corner;	/* Types that trigger corner check */
    struct drccookie * drcc_next;
    char             * drcc_why;	/* Explanation of error found */
    int		       drcc_cdist;	/* Size of corner extension. */
    int		       drcc_flags;	/* Miscellaneous flags, see below. */
    int		       drcc_plane;	/* Index of plane on which to check
					 * legal types.
					 */
} DRCCookie;

/* DRCCookie flags:
 * DRC_FORWARD:		Rule applies from left to right (or bottom to top).
 * DRC_REVERSE:		Rule applies from right to left (or top to bottom).
 * DRC_BOTHCORNERS:	Must make corner extensions in both directions.
 * DRC_XPLANE:		Means check areas for rule are on different plane
 *			than edges from which rule triggers.
 */

#define		DRC_FORWARD		0
#define		DRC_REVERSE		1
#define		DRC_BOTHCORNERS		2
#define		DRC_XPLANE		4
#define		DRC_CHECKCONNECT	010
#define		DRC_ZEROSPACERULE	0x20
#define		DRC_LEFT		0x100
#define		DRC_RIGHT		0x200
#define		DRC_TOP			0x400
#define		DRC_BOTTOM		0x800
#define		DRC_AREA		0x8000
#define		DRC_MAXWIDTH		0x10000
#define		DRC_BENDS		0x20000
#define		DRC_RECTSIZE		0x40000
#define 	DRC_WEIRDONES		(DRC_AREA|DRC_MAXWIDTH|DRC_RECTSIZE)

#define	DRC_PENDING			0
#define DRC_UNPROCESSED 		MINFINITY
#define DRC_PROCESSED 			1

/* export m1 width as feature size hint */
extern int DRCm1Width;

/*
 * Design rule table
 */

extern DRCCookie        *DRCRulesTbl[TT_MAXTYPES][TT_MAXTYPES];

				/*  macro to determine if two TileTypes
				 *  are in the same plane
				 */
#define SamePlane(i,j)	((i == TT_SPACE) || (j == TT_SPACE) || \
			 (DBPlane(i) == DBPlane(j)))

/* This is client data passed down through the various DRC checking
 * routines, and contains information about the area and rule being
 * checked.
 */
struct drcClientData
{
    CellDef	* dCD_celldef;		/* CellDef, plane and area to DRC. */
    Plane	* dCD_plane;
    Rect	* dCD_rect;
    Tile 	* dCD_initial;		/* Initial tile for search (left side
					 * for forward rules, right for reverse 
					 * rules).
					 */
    Rect	* dCD_clip;		/* Clip error tiles against this. */
    int		* dCD_errors;		/* Count of errors found. */
    int		  dCD_which;		/* tells which edge of initial we 
    					   started from */
    DRCCookie	* dCD_cptr;		/* Rule being checked. */
    Rect	* dCD_constraint;	/* Constraint area from rule. */
    void	(* dCD_function)(); 	/* Function to call for each
				    	 * error found. */
    ClientData	dCD_clientData;		/* Parameter for dCD_function */
};

/* Things shared between DRC functions, but not used by the
 * outside world:
 */
extern int  dbDRCDebug;

extern int  TechHalo;	      	/* largest action distance of design rules */
extern PaintResultType DRCPaintTable[NP][NT][NT];
extern TileTypeBitMask DRCExactOverlapTypes;
extern TileTypeBitMask DRCTypes;


extern int  DRCstatEdges;	/* counters for statistics gathering */
extern int  DRCstatSlow;
extern int  DRCstatRules;
extern int  DRCstatTiles;
extern int  DRCstatInteractions;
extern int  DRCstatIntTiles;
extern int  DRCstatCifTiles;
extern int  DRCstatSquares;
extern int  DRCstatArrayTiles;

#ifdef	DRCRULESHISTO
#	define	DRC_MAXRULESHISTO 30	/* Max rules per edge for statistics */
extern int  DRCstatHRulesHisto[DRC_MAXRULESHISTO];
extern int  DRCstatVRulesHisto[DRC_MAXRULESHISTO];
#endif	DRCRULESHISTO

extern void drcPaintError(CellDef *celldef, Rect *rect, DRCCookie *cptr, Plane *plane);
extern void drcPrintError(CellDef *celldef, Rect *rect, DRCCookie *cptr, Rect *area);
extern int drcIncludeArea(Tile *tile, Rect *rect);
extern int drcExactOverlapTile(Tile *tile, TreeContext *cxp);

extern CellUse *DRCuse;
extern CellDef *DRCdef;

/*
 * Exported procedures and variables.
 */

extern Void DRCTechInit(void);
extern void DRCTclInit(Tcl_Interp *interp);
extern bool DRCTechAddRule(char *sectionName, int argc, char **argv);
extern Void DRCTechFinal(void);
extern void DRCTechRuleStats(void);

extern void DRCInit(void);

extern bool DRCChangedArea(CellDef *celldef, Rect *area);
extern void DRCChangeAddDef(CellDef *celldef);


extern int DRCContinuous(bool background);

extern void DRCPrintRulesTable(FILE *fp);
extern void DRCWhy(CellUse *use, Rect *area);
extern void DRCPrintStats(void);
extern void DRCCheck(CellUse *use, Rect *area);
extern void DRCCount(CellUse *use, Rect *area);
extern void DRCClean(CellDef *def);
extern int DRCFind(CellDef *def, Rect *rect, int indx);
extern void DRCCatchUp(void);
extern bool DRCBackGround;	/* global flag to enable/disable
				 * continuous DRC
			     	 */
extern int DRCPriority;
extern CellDef *DRCdef;
extern bool DRCFindInteractions(CellDef *def, 
				Rect *area, 
				int radius, 
				Rect *interaction, 
				TileTypeBitMask *layersToCheck,
				int caller);

/* DRCFindInteraction caller codes */
/* set when called from drc */ 
#define DRCFI_DRC 1
/* set when called from cif gen code */
#define DRCFI_CIF 2
/* set when called from cif gen code, when flattening gcells */
#define DRCFI_CIF_FLATTEN_GCELLS 4
/* set when called from extractor */
#define DRCFI_EXT 8

extern CellDef *DRCErrorDef;
extern TileType DRCErrorType;

/* process drc version stamp mismatches between uses (refs) and the
 * referenced cell definitions.
 */

#endif _DRC


