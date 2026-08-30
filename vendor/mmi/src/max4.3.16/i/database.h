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
 * database.h --
 *
 * Definitions for the database module.
 * This file defines everything that is visible to clients
 * outside the database module.
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
 * Needs to include: magic.h, tiles.h
 *
 * rcsid "$Header: database.h,v 6.0 90/08/28 18:10:36 mayo Exp $"
 */

#ifndef _DATABASE
#define	_DATABASE

#ifndef _TCL
#include <tcl.h>
#endif

#ifndef	_MAGIC
#include "magic.h"
#endif	_MAGIC
#ifndef	_TILE
#include "tile.h"
#endif	_TILE
#ifndef	_HASH
#include "hash.h"
#endif	_HASH
#ifndef	_IHASH
#include "ihash.h"
#endif	_IHASH
#ifndef	_BPLANE
#include "bplane.h"
#endif	_BPLANE
#ifndef	_MEMORY
#include "memory.h"
#endif	_MEMORY
#ifndef	_MESSAGE
#include "message.h"
#endif	_MESSAGE

#define BIT(n) (1<<(n)) 

/* ----------------------- Tunable constants -------------------------- */

#define	MAXPLANES	128	/* Maximum number of planes per cell */

    /*
     * The "unnamed" cell.
     * This is visible only within Magic, and just determines the
     * name by which the initial cell-without-a-name appears.
     */
#define	UNNAMED	"UNNAMED"


/* --------------------- Tile types and masks ------------------------- */

/*
 * Tile types are small integers (currently from 0 to TT_MAXTYPES-1).
 * They are used in constructing TileTypeBitMask bitmasks with the
 * operators defined below.  A TileTypeBitMask contains one bit for
 * each possible TileType.
 *
 * The last TT_RESERVEDTYPES tile types are reserved for use by clients.
 * Because unsigned chars are used to hold tile types (PaintResultType),
 * this number should not be increased without changing the definition
 * of PaintResultType later in this file.
 *
 * If TT_MASKWORDS changes, the macros TTMaskAndMask(), etc. must also
 * be changed.
 *
 * TT_MAXTYPES SHOULD BE LESS THAN 128 to avoid sign extension problems 
 */

/* can't make TileType unsigned since  small neg integers
 * used to signal exceptional condition by DBTechNameTypes()
 */
typedef int TileType;

#define	DBgetTileType(tp)       (((TileType) (tp)->ti_body) & 0xff)  
#define	DBsetTileType(tp, b) ( (tp)->ti_body = \
   (ClientData) (((TileType) (tp)->ti_body) & ~0xff | ((TileType) (b))) )
#define DBisSetTileFlag(tp,f)      (((int) (tp)->ti_body) & (f))    
#define DBsetTileFlag(tp,f)	(((int) (tp)->ti_body) |= (f))
#define DBresetTileFlag(tp,f)   (((int) (tp)->ti_body) &= ~(f))

#define	TT_MAXTYPES		127			/* See above! */
#define	TT_RESERVEDTYPES	3			/* See above! */

#define	TT_BPW			(8 * sizeof (unsigned))
#define	TT_WORDMASK		(TT_BPW - 1)
#define	TT_WORDSHIFT		5			/* LOG2(TT_BPW) */
#define	TT_MASKWORDS		((TT_MAXTYPES + TT_BPW - 1) / TT_BPW)

/* tile flags */
#define TF_MULTIGROUP 0x100

typedef struct
{
    unsigned	tt_words[TT_MASKWORDS];
} TileTypeBitMask;

/*
 * Although some tile types are assigned on a technology-specific basis,
 * certain types are independent of the technology used, and are
 * defined below:
 */
#define	TT_SPACE	0	/* Space tile */
#define	TT_PAINTBASE	1	/* First non-space type */
#define TT_CHECKPAINT   1       /* DRC -- paint has changed */
#define TT_CHECKSUBCELL 2	/* DRC -- subcells have changed */
#define TT_ERROR_P      3       /* DRC -- paint error */
#define TT_ERROR_S      4       /* DRC -- subcell error */
#define TT_ERROR_PS     5       /* DRC -- paint & subcell error */
#define TT_SELECTBASE 	6       /* First selectable type */
#define	TT_TECHDEPBASE	6       /* First technology-dependent type */

/* Pseudo type signifying unexpanded subcells.  Never painted.  -  Only
   used in a few places, e.g.  DBSrTouchingTypes() and mzrouter spacing arrays.
 */
#define TT_SUBCELL	TT_MAXTYPES-1  

/* The following type is used in the paint result tables to save space*/
typedef unsigned char PaintResultType;

/* Which word in a mask contains the bit for type 't'? */
#define	ttWord(t)	((t) >> TT_WORDSHIFT)

/* Which bit in the above word is for type 't'? */
#define	ttBit(t)	((t) & TT_WORDMASK)

/* Mask for above word with only bit 't' set */
#define	ttMask(t)	((unsigned int)1 << ttBit(t))

/* Operations for manipulating TileTypeBitMasks */
#define TTMaskSetType(m, t)	((m)->tt_words[ttWord(t)] |= ttMask(t))
#define	TTMaskClearType(m, t)	((m)->tt_words[ttWord(t)] &= ~ttMask(t))
#define	TTMaskHasType(m, t)	(((m)->tt_words[ttWord(t)] & ttMask(t)) != 0)
#define	TTMaskSetOnlyType(m, t)	(TTMaskZero(m), TTMaskSetType(m, t))

/* If TT_MASKWORDS (currently 3) changes, the following must also change */
#define	TTMaskZero(m)		((m)->tt_words[0] = 0, \
				 (m)->tt_words[1] = 0, \
				 (m)->tt_words[2] = 0, \
				 (m)->tt_words[3] = 0)
     
#define	TTMaskIsZero(m)		((m)->tt_words[0] == 0 && \
				 (m)->tt_words[1] == 0 && \
				 (m)->tt_words[2] == 0 && \
				 (m)->tt_words[3] == 0)

#define	TTMaskEqual(m, n)	((m)->tt_words[0] == (n)->tt_words[0] && \
				 (m)->tt_words[1] == (n)->tt_words[1] && \
				 (m)->tt_words[2] == (n)->tt_words[2] && \
				 (m)->tt_words[3] == (n)->tt_words[3]) 

#define TTMaskIntersect(m, n)	(((m)->tt_words[0] & ((n)->tt_words[0])) || \
				 ((m)->tt_words[1] & ((n)->tt_words[1])) || \
				 ((m)->tt_words[2] & ((n)->tt_words[2])) || \
				 ((m)->tt_words[3] & ((n)->tt_words[3])))

#define	TTMaskCom(m)		(((m)->tt_words[0] = ~(m)->tt_words[0]), \
				 ((m)->tt_words[1] = ~(m)->tt_words[1]), \
				 ((m)->tt_words[2] = ~(m)->tt_words[2]), \
				 ((m)->tt_words[3] = ~(m)->tt_words[3]))

#define	TTMaskCom2(m, n)	(((m)->tt_words[0] = ~(n)->tt_words[0]), \
				 ((m)->tt_words[1] = ~(n)->tt_words[1]), \
				 ((m)->tt_words[2] = ~(n)->tt_words[2]), \
				 ((m)->tt_words[3] = ~(n)->tt_words[3]))

#define	TTMaskSetMask(m, n)	(((m)->tt_words[0] |= (n)->tt_words[0]), \
				 ((m)->tt_words[1] |= (n)->tt_words[1]), \
				 ((m)->tt_words[2] |= (n)->tt_words[2]), \
				 ((m)->tt_words[3] |= (n)->tt_words[3]))

#define	TTMaskSetMask3(m, n, o) \
	(((m)->tt_words[0] = (n)->tt_words[0] | (o)->tt_words[0]), \
	 ((m)->tt_words[1] = (n)->tt_words[1] | (o)->tt_words[1]), \
	 ((m)->tt_words[2] = (n)->tt_words[2] | (o)->tt_words[2]), \
	 ((m)->tt_words[3] = (n)->tt_words[3] | (o)->tt_words[3]))

#define	TTMaskAndMask(m, n) \
	(((m)->tt_words[0] &= (n)->tt_words[0]), \
	 ((m)->tt_words[1] &= (n)->tt_words[1]), \
	 ((m)->tt_words[2] &= (n)->tt_words[2]), \
	 ((m)->tt_words[3] &= (n)->tt_words[3]))

#define	TTMaskAndMask3(m, n, o) \
	(((m)->tt_words[0] = (n)->tt_words[0] & (o)->tt_words[0]), \
	 ((m)->tt_words[1] = (n)->tt_words[1] & (o)->tt_words[1]), \
	 ((m)->tt_words[2] = (n)->tt_words[2] & (o)->tt_words[2]), \
	 ((m)->tt_words[3] = (n)->tt_words[3] & (o)->tt_words[3]))

#define	TTMaskClearMask(m, n) \
	(((m)->tt_words[0] &= ~(n)->tt_words[0]), \
         ((m)->tt_words[1] &= ~(n)->tt_words[1]), \
         ((m)->tt_words[2] &= ~(n)->tt_words[2]), \
 	 ((m)->tt_words[3] &= ~(n)->tt_words[3]))

#define	TTMaskClearMask3(m, n, o) \
	(((m)->tt_words[0] = (n)->tt_words[0] & ~(o)->tt_words[0]), \
	 ((m)->tt_words[1] = (n)->tt_words[1] & ~(o)->tt_words[1]), \
	 ((m)->tt_words[2] = (n)->tt_words[2] & ~(o)->tt_words[2]), \
	 ((m)->tt_words[3] = (n)->tt_words[3] & ~(o)->tt_words[3]))

/* ---------------------- Planes, masks, and lists ------------------------ */
/*
 * Plane numbers are also small integers.  Certain planes are
 * technology-specific, but others are always present independent
 * of the technology used.
 *
 * Note that the CELL plane and the DRC_CHECK plane are invisible
 * as far as normal painting operations are concerned, but that the
 * DRC_CHECK plane does get written out to the .max file.
 *
 * The following macros are used for converting between plane numbers
 * and masks of same.
 *
 * NOTE: moving from plane masks to plane lists (to accomodate >32 planes)
 *
 */

#define	PL_MAXPLANES	MAXPLANES	/* Maximum number of planes per cell */
/* 0 plane was used for instances.  Could be reclaimed by adjusting 
 * values below, but BEWARE I am pretty sure there are implicit assumptions
 * about plane bases somewhere in the code! 
 */
#define PL_DRC_CHECK	1		/* DRC plane for CHECK tiles */
#define PL_PAINTBASE	1		/* Base of paint planes */
#define PL_DRC_ERROR	2		/* DRC plane for ERROR tiles */
#define PL_SELECTBASE	3	        /* First plane with selectable types */
#define	PL_TECHDEPBASE	3		/* First technology-dependent plane */

/* set to index of active plane (if one is defined for this technology) */
extern int DBPlaneActive;

typedef struct planelist
{
  int pll_num;                  /* plane index */
  struct planelist *pll_next;   /* list link */
} PlaneList;

/* manage own freelist to avoid potential performance hit from malloc() */
extern PlaneList *PlaneListFreeList;
static __inline__ PlaneList *PlaneListAlloc(void)
{ 
  PlaneList *pll = PlaneListFreeList;

  if(pll) 
  {
    /* pop free list */
    PlaneListFreeList = pll->pll_next;
  }
  else  
  {
    /* free list empty, malloc */
    MALLOC_TAG(PlaneList *, pll, sizeof(PlaneList), "PlaneList");
  }

  return pll;
}  

/* free entire plane list */
static __inline__ void PlaneListFree(PlaneList *pll)
{ 
  while(pll)
  {
    PlaneList *cur;

    /* pop pll */
    cur = pll;
    pll = cur->pll_next;

    /* push freelist */ 
    cur->pll_next = PlaneListFreeList;
    PlaneListFreeList = cur;
  }
}

extern bool DBPlaneListHasPlane(PlaneList *pll, int num);
extern void DBPlaneListAdd(PlaneList **pllp, int num);
extern void DBPlaneListAddUnique(PlaneList **pllp, int num);
extern PlaneList *DBPlaneListFromTypes(TileTypeBitMask *mask);
extern TileTypeBitMask DBPlaneListToTypes(PlaneList *pll);
extern void DBPlaneListAddList(PlaneList **pllp, PlaneList *addList);
extern bool DBPlaneList2String(PlaneList *pll, char *buf, int bufSize);

/* --------------------- version stamps --------------------------------------- */
/* used to track consistency between cells */

typedef struct vstamp
{
     int vs_time;  /* time */ 
     int vs_rev;   /* incremented for each "revision" during fixed vs_time */
} VStamp;

/* invalid stamp used to force recomputation of dependent data */
static __inline__ bool DBVStampValid(VStamp *vs)
{
  return (vs->vs_time != 0);
}

/* --------------------- Groups --------------------------------------- */

typedef struct groupclass
{
    char *gc_name;
    struct group *gc_hashLink;
} GroupClass;

typedef struct group
{
    char *g_name;
    struct group *g_hashLink;
    GroupClass *g_class;
    ClientData g_attributes; 
} Group;

/* --------------------------- Labels --------------------------------- */

/*
 * Cells have lists of labels.
 * Each label contains a location (rectangle) and a layer that it
 * is "attached" to.
 */

typedef struct label
{
    TileType            lab_type;       /* Type of material to which this label
                                         * is attached.  This material, or
                                         * other materials that connect it,
                                         * must be present everywhere under
                                         * the area of the label (Magic
                                         * enforces this).  If there isn't
                                         * any such material, lab_type is
                                         * TT_SPACE.
                                         */
  
    Group                *lab_group;    /* group label belongs to */
    Rect                 lab_rect;      /* Area of label. */
    struct label        *lab_hashLink;  /* link for text-keyed hash table */
    struct label        *lab_hashLoc;   /* link for location based hash */
    struct label        *lab_prev;      /* Previous label in list */
    struct label        *lab_next;      /* Next label in list */
    ClientData           lab_client;    /* This space for rent, return to
					 * 0 when done.
					 */
    char                 lab_kind;      /* kinds of labels defined below */
    char                 lab_pos;       /* Position at which text is to be
                                         * displayed relative to the box.
					 */
    char                 lab_text[2];   /* Actual text of label.  This field
                                         * is just a place-holder: the actual
                                         * field will be large enough to
                                         * contain the label name.  This
                                         * MUST be the last field in the
                                         * structure.
                                         */
} Label;

/* Kinds of Labels */
#define LAB_COMMENT 0
/* hidden labels not normally displayed */
#define LAB_HIDDEN 1 
#define LAB_LOCAL 2
#define LAB_GLOBAL 3
/* ports */
#define LAB_INPUT 4
#define LAB_OUTPUT 5
#define LAB_INOUT 6
#define LAB_MAX_KIND 6

/*
 * Macros for dealing with label rectangles.
 */

#define	LABELTOUCHPOINT(p, r) \
			((p)->p_x >= (r)->r_xbot && (p)->p_x <= (r)->r_xtop \
		      && (p)->p_y >= (r)->r_ybot && (p)->p_y <= (r)->r_ytop)


/* --------------------------- WirePaths --------------------------------- */
/*
 * For nonorthogonal geometries.  points define centerline.
 *
 * equivalent to gds path elements, or cif wires
 *
 * In max paths generate "derived" off-grid Polygons to implement them, 
 * but higher level wirepath structure is retained for i/o etc.
 */
typedef struct wirepath
{
  TileType wp_type;
  Group *wp_group;              /* paint group */ 
  Rect wp_bbox;                 /* bounding box */  
  ClientData wp_client;         /* this space for various temporary purposes
				 * return to -1 when done */ 
  char wp_style;                /* how end points are handled (see below) */
  int wp_width;
  int wp_size;                  /* number of points in path */
  Point *wp_points;             /* array of points defining centerline */
  struct wirepath *wp_next;      /* Next wirepath in list */
} WirePath;

/* NOTE WP_STYLE values must correspond exactly to GDSII PATHTYPE */
	/* no end cap */
#define WP_STYLE_FLUSH 0
	/* semi circle end cap */
#define WP_STYLE_ROUNDED 1
	/* square 1/2 wire width extension */
#define WP_STYLE_HALFWIDTH 2
	/* variable extension */
#define WP_STYLE_VARIABLE 4

/* --------------------------- Polygons --------------------------------- */
/*
 * For nonorthogonal geometries.  Points are vertices.
 *
 * equivalent to gds boundary elements, or cif polygons
 *
 * SPECIAL CASE:  2 point "polygons" are round or oval flashes inside
 * box defined by 2 points.
 */
typedef struct polygon
{
  TileType poly_type;             
  Group *poly_group;              /* paint group */ 
  Rect poly_bbox;                 /* bounding box */  
  ClientData poly_client;         /* this space for various temp. purposes
				   * return to -1 when done.
				   */
  int poly_size;                  /* number of vertices in polygon */
  PointFloat *poly_points;        /* array of vertices */
  WirePath *poly_wirePath;        /* points to wire path this polygon
                                   * belongs to.
				   * NULL, for independent polygons.
				   */
  struct polygon *poly_next;      /* Next polygon in list */
} Polygon;


/* --------------------------- Flylines --------------------------------- */

/*
 * Cells have lists of fly lines.
 * A fly line is used to indicate paint that needs to be connected
 * (i.e. is logically in the same net.)
 */

typedef struct flyline
{
  int flay_flags;
  char *fl_name1;
  char *fl_name2;
  struct celldef *fl_def1;  /* definition containing first label */
  struct celldef *fl_def2;  /* definition containing second label */
  int fl_width;             /* flyline width in pixels */
  char *fl_text;            /* text to label flyline with (if any) */
  
  PointFloat fl_p1;
  PointFloat fl_p2;

  Rect  fl_bbox;
  struct flyline        *fl_next;      /* Next fly line in list */
} FlyLine;

/* flyline flags */
#define FL_P1_VALID 1
#define FL_P2_VALID 2

/* ------------------- Cell definitions and uses ---------------------- */

/*
 * There are two main structures used for cells:
 *
 *	CellDef -- one for the definition of the cell
 *	CellUse -- one for each instantiation of the cell.
 *
 * Two auxiliary structures are used to allow per/def rather than per/use
 * processing when ever possible (for efficiency):
 *
 *	CellKid -- one for each definition that this cell has an instance of.
 *	CellPar -- one for each definition that has an instance of this cell.
 *
 * The CellDef is shared by all of the CellUses of that cell.
 */

typedef struct celldef
{
    int                  cd_refCnt;     /* number of current, in memory,
					 * references (CellUses of this def)
					 * includes CellUses in other
					 * cells, and uses outside of defs, 
					 * such as in layout widgets (to
					 * point at toplevel cell in window).
					 *
					 * Used to check if it is safe
					 * to delete the def.
					 *
					 * DOES NOT INCLUDE temp uses
					 * (uses initialized with
					 *  DBCellUseNewTemp)
					 */

    int			 cd_flags;	/* See definitions below */

    VStamp               cd_version;    /* last time this cell (or subcells)
					 * changed in a way that can impact
					 * parents (e.g. redrc needed, or bbox 
					 * changed)
					 *
					 * NOTE: internal, not written to
					 * .max files.
					 */

    VStamp               cd_vMAIN;     /* EXTERNAL stamp: like cd_version,
					* but excludes changes that only
					* impact redisplay of parents.
					*/ 

    VStamp               cd_vDRC;      /* last time this cell (or subcells)
					* changed in a way that can impact
					* drc of parents.
					*/ 

    Rect		 cd_bbox;	/* Bounding box for cell 
					 * IMPORTANT:  DO NOT REFERENCE DIRECTLY
					 * INSTEAD USE ROUTINES IN DBbbox.c
					 * Direct references may get 
					 * out-of-date bbox.
					 */
    Rect                cd_userBBox;    /* bbox to display (may or maynot
					 * be actual bbox)
					 */
    char		*cd_file;	/* File containing cell definition */
    char		*cd_name;	/* Name of cell */
    char                *cd_showName;    /* if non-null display instead of
					  * cellname (used for generated
					  * cells)
					  * NOT SAVED TO DISK
					  */
    char                *cd_showInst;  /* if non-null display instead of
				        * instance name (used for generated
				        * cells)
                                        * NOT SAVED TO DISK
				        */

    struct cellpar	*cd_pars;	/* one element per def that has an 
					 * instance of this cell (i.e parent) 
					 */
    IHashTable		*cd_parHash;	
                                        /* Maps cell def pointer to entrys.
					 * Used to quickly check whether a cell
					 * is on the parentDefs list.
					 */
    struct cellkid	*cd_kids;	/* one element per def that is a use of
					 * this cell
					 */
    IHashTable     	*cd_kidHash;	/* Maps def pointers to cellkid entrys */

    BPlane              *cd_cellPlane;          /* instance locations */
                                        
    Plane		*cd_planes[MAXPLANES];	/* Tiles */

    Polygon             *cd_polygons;           /* Non orthogonal geometries 
						 *  defined by vertices 
						 */
    WirePath            *cd_wirePaths;          /* Non orthogonal geometries
						 * defined by width and centerline
						 * (each wirePath generates 
						 *  associated off_grid polygons 
						 *  implementing it)
						 */
    IHashTable		 *cd_idHash;	/* Maps cell use ids to cell uses.
					 * Indexed by cell use id; value
					 * is a pointer to the CellUse.
					 */

    Label		*cd_labels;	/* Label list for this cell */
    IHashTable		*cd_labelHash; /* hash table for labels 
					* (based on text and location) 
					*/
    IHashTable		*cd_labelTextHash; /* hash table for labels by text */

    Label		*cd_lastLabel; 	/* Last label in list for this cell. */
    FlyLine		*cd_flyLines;	/* fly lines for this cell */
    IHashTable		*cd_groupTable;	/* groups for this cell  */
    Group               *cd_activeGroup; /* current active group for this cell */

    IHashTable		 *cd_props;	/* hashtable for propertys.
					 * Properties are name-value pairs. 
					 * (Where values are strings).
					 * They provide a flexible way 
					 * for arbitrary data to be
					 * associated with a celldef.
					 */

    ClientData           cd_coarseDB;    /* layout module maintains 
					  * coarse-resolution paint planes 
					  * for zoomed out redisplay.
					  *
					  *  (in future may keep coarse versions 
					  *  of other cell data
					  *  e.g. polygons/labels ...)
					  */

    ClientData           cd_pixelValue; /* layout module caches single
					 * pixel "image" of def here.
					 * (used when zoomed WAY out)
					 */

    ClientData           cd_imageCache; /* layout module caches pixmap
					 * "images" of def here.
					 * (used when zoomed out)
					 */

    int                  cd_drcNumChanges;  /* number of changes reported to
					     * drc since the last time this
					     * cell was examined by drc.
					     *
					     * If this number exceeds a
					     * threshold, we give up on
					     * incremental drc (to avoid
					     * undo (change/update overhead)
					     * and set CD_DRC_ALL_PENDING. 
					     */

    ClientData		 cd_client;	/* This space used for various temporary
					 * purposes - return to 0 when done!
					 *
					 * Use DBCellClearClients(TRUE)
					 * to 'assert' that all cd_clients
					 * are clear.
					 */

    /* following five fields for netlister */
    ClientData 		*cd_nodes;
    ClientData 		*cd_trans;
    ClientData 		*cd_portList;	/* list of port-type labels */
    int			cd_nodeCount;
    int			cd_portCount;

    struct celldef      *cd_next;       /* links all cell defs */
} CellDef;

/*** CellDef flags ***/

/* cell loaded (into memory) */
#define	CD_AVAILABLE	           BIT(0)

/* last attempt to read from disk failed, so: 
 *   1.  don't retry read unless CD_READ_RETRY set
 *   2.  don't give any more error messages.
 */
#define	CD_NOT_FOUND	           BIT(1)

/* retry reading from disk even if CD_NOT_FOUND set 
 * set every time cell search path is modified,
 * (tcl code tickles cell path after every top-level command, 
 *  so we retry reading in case something changed on disk)
 */
#define CD_READ_RETRY              BIT(2)

/* do not modify buffer or write to disk */
#define CD_READ_ONLY	           BIT(3)

/* buffer modified 
 * (needs to be written to disk to avoid losing changes)
 */
#define	CD_MODIFIED	           BIT(4)

/* buffer used internally (not linked to disk file)
 * (drc, undo etc. do not apply to internal cells)
 */
#define CD_INTERNAL	           BIT(5)

/* cell generated from properties (encoded in name), 
 * not saved to disk 
 */
#define CD_GENERATED               BIT(6)

/* don't keep undo info for this cell */
#define CD_NO_UNDO                 BIT(7)

/* bounding box needs recomputation */
#define CD_CHANGED_BBOX	           BIT(8)

/* update processing needed (some instance changed) */
#define CD_CHANGED_INSTANCE        BIT(9)

/* only drc uses */
#define CD_DRC_WITH_PARENT         BIT(10)

/* drc checks pending */
#define CD_DRC_PENDING             BIT(11)

/* entire cell needs rechecking */
#define CD_DRC_ALL_PENDING         BIT(12)

/* don't netlist independently of parents */
#define  CD_NETLIST_WITH_PARENT    BIT(13)

/* following used by netlister */ 
#define CD_ALLFEEDTHRUS            BIT(14)
#define CD_NOFEEDTHRUS             BIT(15)

/* used to temporarily tag cells during gds read */
#define CD_GDS_TAG                 BIT(16)

/*
 * Description of an array.
 * The bounds xlo .. xhi and ylo .. yhi are transformed versions
 * of the bounds xlo' .. xhi' and ylo' .. yhi' supplied by the
 * user:
 *
 * User supplies:
 *	xlo'	index of leftmost array element in root coordinates
 *	xhi'	index of rightmost array element in root coordinates
 *	ylo'	index of bottommost array element in root coordinates
 *	yhi'	index of topmost array element in root coordinates
 *
 * There is no constraint on the order of any of these indices; xlo' may
 * be less than, equal to, or greater than xhi', and similarly for ylo'
 * and yhi'.
 *
 * In addition, the separations xsep and ysep are transformed versions
 * of the separations xsep' and ysep' supplied by the user:
 *
 * User supplies:
 *	xsep'	(positive) X spacing between array elements in root coords
 *	ysep'	(positive) Y spacing between array elements in root coords
 *
 * When the array is made via DBMakeArray, both the indices and the spacings
 * are transformed down to the coordinates of the CellDef that is the child
 * of the use containing the ArrayInfo.
 *
 * The significance of the various values is as follows:  the [xlo, ylo]	
 * element of the array is gotten by transforming the celldef by the
 * transformation in the celluse.  the [x, y] element is gotten by
 * transforming the celldef by xsep*abs(x-xlo) in x, ysep*abs(y-ylo) in
 * y, and then transforming by the transformation in the celluse.
 */

typedef struct
{
    int		ar_xlo, ar_xhi;		/* Inclusive low/high X bounds */
    int		ar_ylo, ar_yhi;		/* Inclusive low/high Y bounds */
    int		ar_xsep, ar_ysep;	/* X,Y sep between array elements */
} ArrayInfo;

/*
 * Since a cell may be used in an orientation different from that
 * in which it was defined, each cell use contains a transform
 * that will generate coordinates in the world of the parent from
 * the coordinates in the world of the child.  Cells may also be
 * arrayed.  Note:  arraying occurs before the transformation, then
 * the entire array is transformed.
 */

typedef struct celluse
{
  /* BPLANE ELEMENT HEADER */
    void          *cu_bpLinks[BP_NUM_LINKS]; /* link field(s) for bplane */
    Rect	   cu_bbox;	        /*
					 *  Bounding box of this use, with
					 *  arraying taken into account, in
					 *  coordinates of the parent def.
					 *
					 *  MUST BE SECOND ELEMENT IN STRUCT
					 *  SINCE REFERENCED BY BPLANE CODE.
					 *
					 * NOTE SHOULD GENERALLY 
					 * NOT BE REFERENCED
					 * DIRECTLY, INSTEAD USE DBBBoxCellUse()
					 * or DBBBoxCellUseNoUp() - to ensure
					 * up-to-date value.
					 */

  /* REMAINING FIELDS ARE OPAQUE TO BPLANE CODE */

    char		*cu_id;		/* Unique identifier of this use */
    CellDef             *cu_def;        /* child def.   
					 * TODO:  redundant, with ck_def,
					 * but a little tricky to eliminate.  
					 */
    Transform		 cu_transform;	/* Transform to parent coordinates */

    unsigned		 cu_expandMask;	/* Mask of windows in which this use
					 * is expanded.
					 */
    int 		 cu_flags;    

    struct cellkid      *cu_kid;        /* pointer to common structure
					 * for all uses of this child def
					 * in this parent def.
					 */

    struct celluse      *cu_hashLink;   /* link for id-keyed hash table */ 
    struct celluse	*cu_next;	/* Next in list of uses belonging
					 * belonging to a CellKid 
					 * (referencing a particular def)
					 */

    struct celluse      *cu_prev;       /* doubly linked list for quick
					 * deletion.
					 */

    ClientData           cu_client;     /* this space for rent, return to
					 * 0 when done.  
					 */

    /* following field used by netlister - TODO:  use cu_client instead? */
    ClientData		**cu_elementConns; /* really 
					    * PortConns *cu_elementConns[] 
					    * (array of pointers to PortConns)
					    */
    ArrayInfo		 cu_array;         /* WARNING:  This field ONLY EXISTS
					    * FOR ARRAYS.
					    */
} CellUse;

/* cu_flags */
#define CU_ARRAY 01
#define CU_NTL_CHECKED 02
#define CU_NTL_CHECKED2 04

/*  WARNING:  THESE FIELDS ONLY EXIST FOR ARRAYS, 
 *  test for array with DBIsArray() before referencing   
 */
#define	cu_xlo	cu_array.ar_xlo
#define	cu_ylo	cu_array.ar_ylo
#define	cu_xhi	cu_array.ar_xhi
#define	cu_yhi	cu_array.ar_yhi
#define	cu_xsep	cu_array.ar_xsep
#define	cu_ysep	cu_array.ar_ysep

/* TODO:  eventually remove cu_transform and compute
 * on demand from bboxes and orientation.
 */
static __inline__ Transform *DBCellUseGetTrans(CellUse *use)
{
  return &use->cu_transform;
}

/*
 * The field cu_expandMask contains an expansion mask with one bit set
 * for each window in which the cellUse is to be displayed as expanded.
 */

#define	DBIsExpand(use, mask)	(((use)->cu_expandMask & (mask)) == (mask))

/* one of these for every def for which this cell has an instance */
typedef struct cellkid
{
    CellDef         *ck_def;             /* child def */
    CellDef         *ck_parent;	         /* Cell def containing this use */
    CellUse         *ck_uses;         /* list of all uses of ck_def in this
					  * parent. 
					  */
    CellDef         *ck_hashLink;

    int             ck_idLastSuffix;     /* last suffix of automatically 
					  * generated instance id
					  */

    /* TIME STAMPS */
    VStamp          ck_version;        /* version of def for which parent
					* is up-to-date.
					*/
    VStamp          ck_vDRC;           /* version of def for which 
					* drc info in parent is up-to-date */ 

    Rect ck_userBBox;                   /* last seen user bbox of kid
					 * def.  Used by change/update 
					 * processing.
					 */
    struct cellkid  *ck_next;
} CellKid;

/* one of these for every def that has this cell as an instance */
typedef struct cellpar
{
    CellDef *cp_def;             /* parent def */
    CellDef *cp_hashLink;       
    struct cellpar *cp_next;
} CellPar;

/* -------------------- Search context information -------------------- */

/* Search contexts are used in hierarchical searches */
typedef struct
{
    CellUse	*scx_use;	/* Pointer to cell use currently searched */
    int		 scx_x, scx_y;	/* X and Y array elementS if scx_use is array */
    Rect	 scx_area;	/* Area searched in scx_use->cu_def coords */
    Transform	 scx_trans;	/* Composite transform from coordinates
				 * of the cell use (scx_use) all the way
				 * back to those of the "root" of the
				 * search.
				 */
} SearchContext;

/* ------------------- Pathname of a terminal (label) ----------------- */

/* The following structure is used to build hierarchical label names */
typedef struct
{
    char	*tp_first;	/* Pointer to first character in pathname */
    char	*tp_next;	/* Pointer to next character to be filled in */
    char	*tp_last;	/* Pointer to last available character slot
				 * in pathname.
				 */
} TerminalPath;

/* --------------- Contexts for hierarchical tile searches ------------ */

/*
 * The TreeContext is the glue which holds together the SearchContext
 * of a given search (which varies depending on where in the search we
 * happen to be) and the TreeFilter (see below) which does not.
 */
typedef struct treeContext
{
    SearchContext *tc_scx;		/* Search context (varies) */
    struct treeFilter *tc_filter;	/* Constant search criteria */
} TreeContext;

/*
 * The TreeFilter is that portion of the argument to the
 * filter procedures associated with tree searches that does
 * not change during the entire search, but serves mainly to
 * pass the search criteria down to the filter functions.
 */
typedef struct treeFilter
{
    int (*tf_func)();		/* Client's filter function */
    int (*tf_polygonFunc)();	/* Client's filter function for polygons */
    int (*tf_wirePathFunc)();	/* Client's filter function for wirePaths */
    ClientData tf_arg;		/* Client's argument to pass to filter */
    TileTypeBitMask *tf_mask;	/* Only process tiles with these types */
    char *tf_text;              /* text must match this (used for labels) */
    Rect *tf_loc;               /* loc must match this (used for labels) */
    int tf_xmask;		/* Expand mask */
    PlaneList *tf_planes;	/* list of planes which will be visited */
    TerminalPath *tf_tpath;	/* Buffer to hold hierarchical label names */
    int tf_flags;               /* flags passed from caller */
} TreeFilter;

/* -------------- Undo information passed to DBPaintPlane ------------- */

typedef struct
{
    CellDef *pu_def;	/* Cell definition being modified */
    int pu_pNum;	/* Index of plane within cell def */
} PaintUndoInfo;

/* ---------------------- Codes for paint/erase ----------------------- */

    /* The following are obsolete and will go away */
#define	ERASE	0	/* Erase type from existing tiles */
#define	PAINT	1	/* Paint type over existing tiles */
#define	WRITE	2	/* Write type unconditionally */

/* -------------------- Exported procedure headers -------------------- */

    /**** Initialization ****/
extern void DBInit();
extern void DBTclInit(Tcl_Interp *interp);

     /****  CellUse access ****/
static __inline__ CellDef *DBCellUseParent(CellUse *use)
{
  if(!use->cu_kid) return NULL;
  return use->cu_kid->ck_parent;
}


   /**** Database consistency (version stamps and change processing) ****/

/* invalid vstamp */
extern VStamp DBVStampInvalid;

/* fixed vstamp - used to create identical (fake) stamps */
extern VStamp DBVStampFixed;

/* current vstamp */
extern VStamp DBVStampCurrent;

/* update vstamp time (to now) */
extern void DBVStampUpdate(void);

/* return new vstamp (increments current vs_rev) */
extern VStamp DBVStampNew(void);

/* return vstamp based on def contents */
extern VStamp DBVStampHash(CellDef *def);

/* returns true if stamps are identical and not invalid */

static __inline__ bool DBVStampSame(VStamp *vs1, VStamp *vs2)
{
  if(vs1->vs_time != vs2->vs_time) return FALSE;
  if(vs1->vs_time == 0) return FALSE;
  if(vs1->vs_rev  != vs2->vs_rev) return FALSE;
  return TRUE;
}

static __inline__ bool DBBBoxValid(CellDef *def)
{
  if(def->cd_flags&(CD_CHANGED_INSTANCE|CD_CHANGED_BBOX)) return FALSE;
  if(def->cd_version.vs_time == 0) return FALSE;
  return TRUE;
}

/* resolve all inconsistencies in cell tree rooted at def 
 * make all bboxes in cell tree rooted at def up-to-date. 
 * and update drc check areas.
 */
extern void DBUpdate1(CellDef *def);
extern void DBUpdate0(CellDef *def);        /* for debugging */ 
static __inline__ void DBUpdate(CellDef *def)
{
  extern int Debug0;

  if(Debug0) 
  {
    DBUpdate0(def);
    return;
  }

  if(def->cd_version.vs_time == 0 ||
     def->cd_flags &(CD_CHANGED_INSTANCE|CD_CHANGED_BBOX)) 
    DBUpdate1(def);
}

/* returns up-to-date bounding box for cell def */
static __inline__ Rect *DBBBoxCellDef(CellDef *def)
{
/*
   fprintf(stderr,"DEBUG DBBBoxCellDef() called on cell=%s\n", 
	  def->cd_name);
*/

  if(!DBBBoxValid(def)) DBUpdate(def);
  return &(def->cd_bbox);
}


/* returns up-to-date user bounding box for cell def */
static __inline__ Rect *DBUserBBoxCellDef(CellDef *def)
{
/*
   fprintf(stderr,"DEBUG DBUserBBoxCellDef() called on cell=%s\n", 
	  def->cd_name);
*/

  if(!DBBBoxValid(def)) DBUpdate(def);
  return &(def->cd_userBBox);
}

static __inline__ Rect *DBBBoxCellUse(CellUse *use) 
{
  CellDef *parent = DBCellUseParent(use);

/*
  fprintf(stderr,"DEBUG DBBBoxCellUse() called on use='%s' of cell '%s'\n",
	  use->cu_id, use->cu_def->cd_name);
*/

  /* handle root uses (e.g. window) specially */
  if(!parent)
  {
    /* use top-level defs bbox */
    /* NOTE: assumes top-level use transform is identity, 
     *       and that top-level use is not arrayed!
     */
    return DBBBoxCellDef(use->cu_def);
  }

  /* make sure cu_bbox is up-to-date */ 
  if(parent->cd_flags&CD_CHANGED_INSTANCE) DBUpdate(parent);
  return &(use->cu_bbox);
}

/* dbCellUseSetBBox() is private to database module */
extern void dbCellUseSetBBox(register CellUse *use, Rect *result);

/* get bbox of celluse (but don't update parent) 
 * 
 * Used inside recursive searches where modifying bboxes could
 * mess up parent enumerations.
 */
static __inline__ Rect *DBBBoxCellUseNoUp(CellUse *use) 
{
  CellDef *parent = DBCellUseParent(use);

  ASSERT(DBBBoxValid(use->cu_def),"DBBBoxCellUseNoUp");

  if(!parent)
  {
    /* root use */
    return &use->cu_def->cd_bbox;
  }
  else if (!parent->cd_flags&CD_CHANGED_INSTANCE)
  {
    /* bbox valid */
    return &use->cu_bbox;
  }
  else
  {
    static Rect result;

    /* recompute bbox but don't actually set in use */
    dbCellUseSetBBox(use, &result);
    return &result;
  }
}

extern bool DBBBoxPlane(Plane *plane, register Rect *rect);

extern void
DBChangedArea(CellDef *def,                 /* def that changed */
	      Rect *area,                   /* area that changed 
					     * NULL = entire cell 
					     */
	      TileTypeBitMask *layers,      /* layers that changed  
					     * NULL = all+labels
					     */
	      int flags);                    /* as needed :-) */

/* temporary layers */
extern TileTypeBitMask DBTempTypes;
extern TileTypeBitMask DBNonTempTypes;
extern void DBLayerTempSet(int Plane);
extern void DBLayerTempReset(int Plane);

/* called by MsgCmdEnd() to reset dbAccessMsgs (count). */
extern void DBAccessMsgsClear(void);

/* called before modifications to database.
 * returns TRUE if not read-only, else 
 * prints error message etc. and returns FALSE.
 */
static __inline__ bool
DBAccessModify(CellDef *def)
{
  extern int dbAccessMsgs;

  if (!(def->cd_flags & CD_READ_ONLY)) return TRUE;

  dbAccessMsgs++; 
  
  if(dbAccessMsgs <= 11)
  {  
    if(dbAccessMsgs == 11)
    {
      MsgErrorF("More attempts to modify read-only cells!!!\n");
    }
    else
    {
      MsgErrorF("Attempt to modify read-only cell:  %s\n",
		def->cd_name);
    }
  }

  return FALSE;				     
}

/* check if ok to modify layer in cell 
 * (temp layers can be modified even in read-only cells)
 */
static __inline__ bool 
DBAccessModifyType(CellDef *def, TileType type)
{
  return TTMaskHasType(&DBTempTypes,type) || DBAccessModify(def);
}

/* check if ok to modify layers in cell 
 * (temp layers can be modified even in read-only cells)
 */
static __inline__ bool 
DBAccessModifyMask(CellDef *def, TileTypeBitMask *mask)
{
  return !TTMaskIntersect(&DBNonTempTypes, mask) || DBAccessModify(def); 
}

/* flag definitions for DBChangedArea */
#define DBCF_DEFREAD        BIT(0)
#define DBCF_NODRC          BIT(1)
#define DBCF_DRC_ERROR_ONLY BIT(2)
#define DBCF_DISPLAY_ONLY   BIT(3)
#define DBCF_LABEL_ONLY     BIT(4)
#define DBCF_INSTANCE_ONLY  BIT(5)
#define DBCF_POLYGON_ONLY   BIT(6)
#define DBCF_WIREPATH_ONLY  BIT(7) 

    /**** Painting/erasing ****/
extern void DBPaint(CellDef *cellDef, Rect *rect, TileType type);
extern void DBErase(CellDef *cellDef, Rect *rect, TileType type);
extern void DBPaintPlane(Plane *plane, register Rect *area, PaintResultType *resultTbl, PaintUndoInfo *undo);
extern void DBPaintPlaneG(Plane *plane, register Rect *area, PaintResultType *resultTbl, Group *group, PaintUndoInfo *undo);
extern void DBPaintPlaneByProc(Plane *plane, register Rect *area, int (*proc) (/* ??? */), PaintUndoInfo *undo);
extern void DBPaintPlaneMergeOnce(Plane *plane, register Rect *area, PaintResultType *resultTbl, PaintUndoInfo *undo);
extern void DBPaintMask(CellDef *cellDef, Rect *rect, TileTypeBitMask *mask);
extern void DBEraseMask(CellDef *cellDef, Rect *rect, TileTypeBitMask *mask);
extern void DBEraseMaskG(CellDef *cellDef, Rect *rect, TileTypeBitMask *mask, bool activeGroupOnly);
extern void DBPlaneClearPaint(Plane *plane);

    /**** all angle  geometry ****/
extern Point *DBPointsAlloc(int num, Point *in, Transform *trans);
extern PointFloat *DBPointsFAlloc(int num, PointFloat *in, Transform *trans);

extern void DBPointsFree(Point *p);
extern void DBPointsFFree(PointFloat *p);

extern Rect *DBPointsBBox(int size, Point *points);
extern Rect *DBPointsFBBox(int size, PointFloat *points);

extern void DBPointsDump(char *msg, int size, Point *points);
extern void DBPointsFDump(char *msg, int size, PointFloat *points);

extern Polygon *DBPolyNew(CellDef *def, 
			  TileType type,
			  int size, 
			  PointFloat *points, 
			  WirePath *wp,
			  bool notify);

extern WirePath *DBWPathNew(CellDef *def, 
			    TileType type, 
			    int style,
			    int width,
			    int size, 
			    Point *points, 
			    bool notify,
			    void (*func)(CellDef *def, 
					 WirePath *wp, 
					 Polygon *poly));

extern void DBPolyDelete(CellDef *def, Polygon *poly, bool notify);
extern void DBWPathDelete(CellDef *def, WirePath *wp, bool notify);

extern void DBPolyClear(CellDef *def);
extern void DBWPathsClear(CellDef *def);

extern Polygon *DBPolygonCopy(Polygon *poly, 
			      CellDef *destDef, 
			      Transform *trans);
extern WirePath *DBWPathCopy(WirePath *wp, 
			     CellDef *destDef, 
			     Transform *trans,
			     void (*func)(CellDef *def, 
					  WirePath *wp, 
					  Polygon *poly));

extern void DBPolygonsCopy(CellDef *srcDef, 
			   CellDef *destDef,
			   Transform *trans);


extern void DBWPathsCopy(CellDef *srcDef, 
			 CellDef *destDef,
			 Transform *trans);

extern Polygon *DBPolyFind(CellDef *def, 
			   TileType type, 
			   Group *group,
			   int size,  
			   PointFloat *points,
			   WirePath *wp,
			   Transform *trans);

extern WirePath *DBWPathFind(CellDef *def, 
			     TileType type, 
			     Group *group,
			     int style,
			     int width,
			     int size,  
			     Point *points,
			     Transform *trans);

extern int DBWPathEnumPolygons(WirePath *wp,
			       int (*func)(int size, 
					   PointFloat *points));

/*
 *-----------------------------------------------------------------------------
 *
 * DBPolygonIntersectRectQ --
 *	
 * Check for intersection between polygon and rect.
 *
 * Returns TRUE if "poly" intersected with the closed rectangle
 * "rect" is non-empty and FALSE otherwise.
 *
 * NOTE: assumes rect is not inverted:  "ll.x < ur.x" and "ll.y < ur.y"
 *
 *-----------------------------------------------------------------------------
 */
static __inline__ bool DBPolygonIntersectRectQ(Polygon *poly, Rect *rect)
{
  Rect *bbox = &poly->poly_bbox;

  /* special case containment (for speed) */
  if(GEO_SURROUND(rect,bbox)) return TRUE;
  
  /* special case disjoint bounding boxes (for speed) */
  if(!GEO_TOUCH(rect,bbox)) return FALSE;

  /* special case two point polygon (circle in Max)
   * where rect edge passes entirely through circle bbox (bisects it)
   */
  if(poly->poly_size == 2)
  {
    if(rect->r_xbot <= bbox->r_xbot && 
       rect->r_xtop >= bbox->r_xtop) return TRUE;

    if(rect->r_ybot <= bbox->r_ybot && 
       rect->r_ytop >= bbox->r_ytop) return TRUE;
  }

  return DBPolygonIntersectRectQ1(poly, rect);
}

/*
 *-----------------------------------------------------------------------------
 *
 * DBPolygonIntersectRect --
 *	
 * Compute intersection between polygon and rect.
 *
 * RETURNS:  number of polygons in result.
 *
 * storage is allocated for and:
 *   dbPolyPoints is filled in with points for the clipped polygon(s).
 *   dbPolyList is filled in with pointers to the start of the points 
 *            for each polygon in the result.  An additional final entry 
 *            in "list" points one beyond the end of the points in clip.
 *	      This is so "list[i+1] - list[i]" always gives the number 
 *            of points in polygon i (which start at "list[i]").
 *   THESE DATA AREAS ARE REUSED ON NEXT CALL.
 *
 * listp is set to point to dbPolyList.
 *
 * NOTE: assumes rect is not inverted:  "ll.x < ur.x" and "ll.y < ur.y"
 *
 * NOTE: currently, in special cases, we point directly to a polygons
 *       point array instead of copying to dbPolyPoints, so UNSAFE
 *       TO MODIFY POINTS.
 *
 *-----------------------------------------------------------------------------
 */
static __inline__ int DBPolygonIntersectRect(Polygon *poly, 
					     Rect *rect,
					     PointFloat ***listp)
{
  extern PointFloat **dbPolyList;

  Rect *bbox = &poly->poly_bbox;

  /* special case containment (for speed) */
  if(GEO_SURROUND(rect,bbox)) 
  {


    if (!dbPolyList)
    {
      MALLOC_TAG(PointFloat **, 
		 dbPolyList, 
		 2*sizeof(PointFloat), 
		 "dbPolyList");
    }

    /* not copying points, for speed - potential booby trap! */
    dbPolyList[0] = poly->poly_points;
    dbPolyList[1] = poly->poly_points + poly->poly_size;
    *listp = dbPolyList;

    return 1;
  }
  
  /* special case disjoint bounding boxes (for speed) */
  if(!GEO_TOUCH(rect,bbox)) return 0;

  /* special case two point polygon (circle in Max)
   * where rect edge passes entirely through circle bbox (bisects it)
   */
  if(poly->poly_size == 2)
  {
    /* don't clip circles for now */
    /* TODO: what to do about clipping circles! */

    if (!dbPolyList)
    {
      MALLOC_TAG(PointFloat **, 
		 dbPolyList, 
		 2*sizeof(PointFloat), 
		 "dbPolyList");
    }

    dbPolyList[0] = poly->poly_points;
    dbPolyList[1] = poly->poly_points + poly->poly_size;
    *listp = dbPolyList;
    return 1;
  }

  return DBPolygonIntersectRect1(poly, rect, listp);
}

extern bool DBPWirePathIntersectRectQ1(CellDef *def, WirePath *wp, Rect *rect);
/*
 *-----------------------------------------------------------------------------
 *
 * DBWirePathIntersectRectQ --
 *	
 * Check for intersection between wirepath and rect.
 *
 * Returns TRUE if "wp" intersected with the closed rectangle
 * "rect" is non-empty and FALSE otherwise.
 *
 * NOTE: assumes rect is not inverted:  "ll.x < ur.x" and "ll.y < ur.y"
 *
 *-----------------------------------------------------------------------------
 */
static __inline__ bool DBWirePathIntersectRectQ(CellDef *def, 
						WirePath *wp, 
						Rect *rect)
{
  /* special case containment (for speed) */
  if(GEO_SURROUND(rect,&wp->wp_bbox)) return TRUE;
  
  /* special case disjoint bounding boxes (for speed) */
  if(!GEO_TOUCH(rect,&wp->wp_bbox)) return FALSE;

  return DBWirePathIntersectRectQ1(def, wp, rect);
}

/*
 *-----------------------------------------------------------------------------
 *
 * DBWirePathIntersectPolygonQ --
 *	
 * Check for intersection between wirepath and polygon.
 *
 * Returns TRUE if "wp" intersected with the closed polygon "poly"
 * is non-empty and FALSE otherwise.
 *
 *-----------------------------------------------------------------------------
 */
extern bool DBWirePathIntersectPolygonQ1(WirePath *wp, 
					 Polygon *poly,
					 Transform *trans);

static __inline__ bool DBWirePathIntersectPolygonQ(WirePath *wp, 
						   Polygon *poly,
						   Transform *trans)
{
  /* special case disjoint bounding boxes (for speed) */
  if(!GEO_TOUCH(&poly->poly_bbox,&wp->wp_bbox)) return FALSE;

  /* wirepath intersects polygon iff one of its polygons does */
  return DBWirePathIntersectPolygonQ1(wp,poly,trans);
}


/*
 *-----------------------------------------------------------------------------
 *
 * DBPolygonIntersectPolygonQ --
 *
 * Check for intersection between two polygons.
 *	
 * Returns TRUE iff the polygons intersect.
 *
 *-----------------------------------------------------------------------------
 */

static __inline__ bool DBPolygonIntersectPolygonQ(Polygon *poly1, 
						  Polygon *poly2,
						  Transform *trans) 
     /* if trans non-null, its transform from poly2 coords to poly1 coords */
{
  extern bool DBPolygonIntersectPolygonQ1(Polygon *poly1, Polygon *poly2);

  if(!trans)
  {
    /* special case disjoint bounding boxes (for speed) */
    if(!GEO_TOUCH(&poly1->poly_bbox,&poly2->poly_bbox)) return FALSE;

    return DBPolygonIntersectPolygonQ1(poly1, poly2);
  }
  else
  {
    Rect bbox2T;
    Polygon *poly2T;
    bool result;

    /* special case disjoint bounding boxes (for speed) */
    GEOTRANSRECT(trans,&poly2->poly_bbox, &bbox2T);
    if(!GEO_TOUCH(&poly1->poly_bbox, &bbox2T)) return FALSE;

    /* special case 2nd poly circle (two point polygon) approximate as bbox for now. TODO rm this */
    if(poly2->poly_size == 2)
    {
      return DBPolygonIntersectRectQ(poly1, &bbox2T);
    }
       
    poly2T = DBPolygonCopy(poly2, NULL, trans); /* transform poly2 */

    /* special case 1st poly circle (two point polygon) approximate as bbox for now. TODO rm this */
    if(poly1->poly_size == 2)
    {
      return DBPolygonIntersectRectQ(poly2T, &poly1->poly_bbox);
    }

    result = DBPolygonIntersectPolygonQ1(poly1, poly2T);
    DBPolyDelete(NULL, poly2T, FALSE);
    
    return result;
  }
}

    /**** I/O ****/
extern int DBReadMaxFormat;
extern int DBReadOpenQuiet;
extern char *DBGetTech(char *cellName);
extern void DBReadCellTree(CellDef *cellDef);
extern void DBReadCellArea(CellUse *rootUse, Rect *rootRect);
extern bool DBCellWrite(CellDef *cellDef, char *fileName, char *suffix);
extern void DBPanicSave(void);


/*
 * ----------------------------------------------------------------------------
 *
 * dbReadCell --
 *
 * If the cell is already in memory (CD_AVAILABLE), do nothing.
 *
 * If the cell is generated (a gcell) call tcl proc "gcell_load name"   
 * to generate it.
 * 
 * Otherwise, call tcl procedure cell_load_hook, and then read in 
 * the cell from its associated disk file (cd_file).
 *
 * If cd_file is NULL, search the cell path (MN_PATH_CELL)
 * for a <cell>.max  (<cell> = cd_name).
 *
 * Marks the cell definition as "read in" (CD_AVAILABLE), and
 * calls DBChangedArea() to process database changes.
 *
 * Results:
 *	TRUE if the cell loaded successfully, FALSE
 *	otherwise.  
 *
 * Side effects:
 *	Cell contents set to match file.
 *      cd_file is set to the full name of the file read.
 *	The cell definition is marked as available.
 *	The cell's MODIFIED bit is cleared.
 *      DBChangedArea() is called to process database changes.
 *
 *	In the event of an error while reading in the cell,
 *	the external integer errno is set to the UNIX error
 *	encountered.
 *
 * ----------------------------------------------------------------------------
 */
static __inline__ bool DBReadCell(CellDef *def)
{
  extern bool dbReadCell1(CellDef *cellDef);
  int flags = def->cd_flags;
 
  /* if cell already in memory, just return */
  if(flags&CD_AVAILABLE) return TRUE;

  /* if last read failed, give it up. */
  if((flags&CD_NOT_FOUND) && !(flags&CD_READ_RETRY)) return FALSE;

  def->cd_flags &=~CD_READ_RETRY; 
  return dbReadCell1(def);
}

    /**** Labels ****/
extern bool DBLabelNameCheck(char *name);
extern Label *DBLabelAlloc(char *text);
extern Label *DBLabelDup(Label *lab); 
extern void DBLabelLink(CellDef *def, Label *label, int flags);
/* DBLabelLink() normally appends new label, give flag below to
 * prepend  */
#define DBLL_PREPEND 1 
extern Label *DBLabelErase(CellDef *def, Label *lab);

char *DBLabelKindName(int kind);
void DBLabelTypedText(char *text, int kind, char *nameBuf, int bufSize);
int DBLabelKindParse(char *name);

extern Label *DBLabelAddG(CellDef *cellDef, 
			  Rect *rect, 
			  int align, 
			  char *text, 
			  TileType type,
			  Group *group,
			  int kind);
extern Label *DBLabelAdd(CellDef *cellDef, 
			 Rect *rect, 
			 int align, 
			 char *text, 
			 TileType type,
			 int kind);

extern bool DBLabelsEraseArea(CellDef *cellDef, 
			      Rect *area, 
			      TileTypeBitMask *mask);

extern void DBLabelsEraseByContentG(CellDef *def, 
				    register Rect *rect, 
				    register TileType type, 
				    char *text,
				    Group *group);

extern void DBLabelsEraseByContent(CellDef *def, 
				   register Rect *rect, 
				   register TileType type, 
				   char *text);

    /**** Technology initialization ****/
extern void DBTechInit(void);
extern bool DBTechSetTech(char *sectionName, int argc, char **argv);
extern bool DBTechSetVersion(char *sectionName, int argc, char **argv);
extern bool DBTechAddPlane(char *sectionName, int argc, char **argv);
extern bool DBTechAddType(char *sectionName, int argc, char **argv);
extern void DBTechFinalType(void);
extern bool DBTechAddConnect(char *sectionName, int argc, char **argv);
extern bool DBTechAddCompose(char *sectionName, int argc, char **argv);
extern TileType DBTechNameType(char *typename), DBTechNoisyNameType(char *typename);
extern int DBTechNamePlane(char *planename), DBTechNoisyNamePlane(char *planename);
extern void DBTechNoisyNameMask(char *layers, TileTypeBitMask *mask);
extern bool DBTechSubsetLayers(TileTypeBitMask src, TileTypeBitMask mask, TileTypeBitMask *result);
extern Void DBTechInitCompose(void);
extern Void DBTechFinalCompose(void);
extern Void DBTechInitConnect(void);
extern Void DBTechFinalConnect(void);

    /**** Cell symbol table ****/
extern bool DBCellNameCheck(char *name);
extern void DBCellName2File(char *name,	char *buf);
extern FILE *DBCellFileOpen(CellDef *def, char* fileName, char *ext, char *mode, char **realnamep);
extern CellDef *DBCellLookDef(char *cellName);
extern CellDef *DBCellNewDef(char *cellName, char *cellFileName);
extern CellDef *DBCellDefAlloc(void);
extern void DBNewYank(char *yname, 
                	/* Name of yank buffer */
		      CellUse **pyuse, 
                    	/* Pointer to new cell use is stored in *pyuse */
		      CellDef **pydef);
extern bool DBCellRenameDef(CellDef *cellDef, char *newName);
extern bool DBCellDeleteDef(CellDef *cellDef);
extern int DBCellSrDefs(int pattern, int (*func) (/* ??? */), ClientData cdata);

     /**** cell uses - creation/deletion ****/
extern CellUse *DBCellUseNew(CellDef *cellDef, char *useName);
extern CellUse *DBCellUseNewArray(CellDef *cellDef, char *useName);
extern CellUse *DBCellUseNewTop(CellDef *cellDef, char *useName);
extern CellUse *DBCellUseNewTemp(CellDef *cellDef, CellUse *cellUse);
extern CellUse *DBCellUseNewCopy(CellUse *old, char *useName, Transform* t);
extern bool DBCellUseDelete(CellUse *cellUse);

    /**** instances ****/
extern bool DBInstanceNameCheck(char *name);
extern bool DBInstanceParsePath(char *in, char *buf);
extern bool DBInstanceAdd(CellUse *use, CellDef *parentDef, int flags);

/* flags for DBInstanceAdd */
  /* complain when renaming instance id for uniqueness */
#define DBIA_INFOMSG_ON_RENAME 1
  /* generate error if instance id not unique */
#define DBIA_ERROR_ON_RENAME 2
  /* complain when not linking instance since exact duplicate already present */
#define DBIA_INFOMSG_ON_DUP 4
  /* generate error if exact duplicate instance already present */
#define DBIA_ERROR_ON_DUP 8
  /* complain when not linking since would create circular structure 
   * (if not set, infomsg is generated)
   */
#define DBIA_DUP_OK 16
  /* allow duplicate instances (useful when itneractively dragging stuff,
   * so an instance doesn't disappear when it is dragged over its cousin.
   */
#define DBIA_ERROR_ON_CIRCULAR 32

extern void DBInstanceDelete(CellUse *use);
extern CellUse *DBInstanceFindByName(char *id, CellDef *parentDef);

    /* Cell selection */
extern CellUse *DBSelectCell(CellUse *rootUse, CellUse *lastUse, Point *lastP, Rect *rootRect, int xMask, Transform *transform, Point *selp, TerminalPath *tpath);

    /* Bounding boxes */
extern void DBBoxCellInitial(CellDef *def);
extern bool DBBoundPlane(Plane *plane, register Rect *rect);

   /* Arrays */
static __inline__ bool DBIsArray(CellUse *use)
{
  return use->cu_flags&CU_ARRAY;
}

extern void DBMakeArray(CellUse *cellUse, 
			Transform *rootToCell, 
			int xlo, 
			int ylo, 
			int xhi, 
			int yhi, 
			int xsep, 
			int ysep);

extern void DBArrayTransformInfo(Transform *t,
				 ArrayInfo *in,
				 ArrayInfo *out);
extern void DBCellUseSetArray(CellUse *fromCellUse, CellUse *toCellUse);
extern void DBCellUseSetTrans(CellUse *cellUse, Transform *trans);
extern void DBArrayOverlap(register CellUse *cu, Rect *parentRect, int *pxlo, int *pxhi, int *pylo, int *pyhi);
extern void DBComputeArrayArea(Rect *area, CellUse *cellUse, int x, int y, Rect *prect);
extern Transform *DBGetArrayTransform(CellUse *use, int x, int y);
extern char *DBSrPrintUseId(SearchContext *scx, char *name, int size);

    /* Massive copying */

extern void
DBCopyPaint(SearchContext *scx, 
                       		/* Describes cell to search, area to
				 * copy, transform from cell to coords
				 * of targetUse.
				 */
	    TileTypeBitMask *mask, 
                          	/* Types of tiles to be yanked/stuffed */
	    int xMask, 
              			/* Expansion state mask to be used in search */
	    CellUse *targetUse,
                       		/* Cell into which material is to be stuffed */
	    int flags);
                                /* DBCP_*, see database.h for list */
#define DBCP_NON_RECURSIVE 1
#define DBCP_ACTIVE_GROUP_ONLY 2
#define DBCP_NO_TILES 4
#define DBCP_NO_POLY 8
#define DBCP_NO_WP 16

static __inline__ void DBCellCopyPaint(SearchContext *scx, 
			    TileTypeBitMask *mask, 
			    int xMask, 
			    CellUse *targetUse)
{
  DBCopyPaint(scx,mask,xMask,targetUse,DBCP_NON_RECURSIVE);
}

static __inline__ void DBCellCopyPaintG(SearchContext *scx, 
			     TileTypeBitMask *mask, 
			     int xMask, 
			     CellUse *targetUse, 
			     bool activeGroupOnly)
{
  DBCopyPaint(scx,mask,xMask,targetUse,
	      DBCP_NON_RECURSIVE |
	      (activeGroupOnly ? DBCP_ACTIVE_GROUP_ONLY : 0));
}

static __inline__ void DBCellCopyAllPaint(SearchContext *scx, 
			    TileTypeBitMask *mask, 
			    int xMask, 
			    CellUse *targetUse)
{
  DBCopyPaint(scx,mask,xMask,targetUse,0);
}

static __inline__ void DBCellCopyAllPaintG(SearchContext *scx, 
			     TileTypeBitMask *mask, 
			     int xMask, 
			     CellUse *targetUse, 
			     bool activeGroupOnly)
{
  DBCopyPaint(scx,mask,xMask,targetUse,
	      activeGroupOnly ? DBCP_ACTIVE_GROUP_ONLY : 0);
}

extern void DBCellCopyLabels(SearchContext *scx, 
			     TileTypeBitMask *mask, 
			     int xMask, 
			     CellUse *targetUse, 
			     Rect *pArea);

extern void DBCellCopyLabelsG(SearchContext *scx, 
			      TileTypeBitMask *mask, 
			      int xMask, 
			      CellUse *targetUse, 
			      Rect *pArea, 
			      bool activeGroupOnly);

extern void DBCellCopyAllLabels(SearchContext *scx, 
				TileTypeBitMask *mask, 
				int xMask, 
				CellUse *targetUse, 
				Rect *pArea,
				char *prefix);

extern void DBCellCopyAllLabelsG(SearchContext *scx, 
				 TileTypeBitMask *mask, 
				 int xMask, 
				 CellUse *targetUse, 
				 Rect *pArea, 
				 bool ActiveGroupOnly,
				 char *prefix);

extern void DBCellCopyCells(SearchContext *scx, 
			    CellUse *targetUse, 
			    Rect *pArea);

extern void DBCellCopyAllCells(SearchContext *scx, 
			       int xMask, 
			       CellUse *targetUse, 
			       Rect *pArea, 
			       CellUse **list,
			       bool dupOK,
			       char *prefix);

extern void DBCellCopyDefNotify(register CellDef *sourceDef, 
				register CellDef *destDef,
				Transform *trans);

    /* Miscellaneous */
extern bool DBIsAncestor(CellDef *cellDef1, CellDef *cellDef2);
extern void DBUndoFlush(void); /* called by UndoFlush() */
extern void DBCellClearContents(CellDef *cellDef);
extern void DBCellClearContentsUp(CellDef *cellDef); 

extern void DBExpandAll(CellUse *rootUse, Rect *rootRect, int expandMask, int expandFlag, int (*func) (/* ??? */), ClientData cdarg), DBExpand(CellUse *cellUse, int expandMask, int expandFlag);
extern bool DBIsChild(CellUse *cu1, CellUse *cu2);
extern void DBCellSetAvail(CellDef *cellDef);
extern void DBCellClearAvail(CellDef *cellDef);
/* clear/check all cd_client fields */ 
extern void DBCellClearDefClients(bool check);  
extern bool DBFlyLinesExist;
extern void DBFlyLineNotifyLabelChange(CellDef *def, char *labName);
extern void DBFlyLineNotifyInstanceChanged(CellUse *use, CellDef *parentDef);
extern bool DBTreeCopyConnect(SearchContext *scx, 
			      TileTypeBitMask *mask, 
			      int xMask, 
			      TileTypeBitMask *connect, 
			      CellUse *destUse,
			      int limit);
extern void DBChunk(SearchContext *scx,
		    TileType type,
		    int xMask,    
		    bool group,
		    CellUse *noTreeRootUse);
extern void DBTechPrintTypes(void);
extern void DBGCellProcessInstances(CellDef *cellDef, bool processMismatches);

/* planes */
extern Plane *DBPlaneNew(ClientData body);
extern bool DBPlaneEmptyQ(Plane *plane);
extern PaintResultType (*DBNewPaintTable())[TT_MAXTYPES][TT_MAXTYPES];
typedef void (*VoidProc)();
VoidProc DBNewPaintPlane(void (*newProc) (/* ??? */));
extern void DBPlaneClearPaint(Plane *plane);
extern void DBFreePaintPlane(Plane *plane);

    /* Deallocation */

    /* Cell properties */
extern void DBPropInitDef(CellDef *def);
extern void DBPropClearDef(CellDef *def);
extern void DBPropFreeDef(CellDef *def);
extern void DBPropSet(CellDef *def, char *name, char *value);
extern char *DBPropGet(CellDef *def, char *name);
extern void DBPropEnum(CellDef *def, void (*func) (/* ??? */));
extern bool DBPropsQ(CellDef *def);

    /* Searching */

extern int DBSearchPaintNew2(SearchContext *scx, 
			     TileTypeBitMask *mask, 
			     int xMask, 
			     TerminalPath *tpath,
			     int (*func) (/* ??? */), 
			     int (*polygonFunc) (/* ??? */), 
			     int (*wirePathFunc) (/* ??? */), 
			     ClientData cdarg,
			     int flags);
     /* flags for DBSearchPaintNew */
/* don't search subcells */
#define DBSP_NON_RECURSIVE 1
/* active group only */
#define DBSP_GROUP 2
/* visit dependent polygons */
#define DBSP_DEPENDENT_POLYGONS 4

static __inline__ 
int DBSearchPaintNew(SearchContext *scx, 
		     TileTypeBitMask *mask, 
		     int xMask, 
		     int (*func) (/* ??? */), 
		     int (*funcPoly) (/* ??? */), 
		     int (*funcWP) (/* ??? */), 
		     ClientData cdarg,
		     int flags)
{
  return DBSearchPaintNew2(scx, 
			   mask, 
			   xMask, 
			   NULL, /* terminal path */
			   func, /* paint func */
			   funcPoly, /* polygon func */ 
			   funcWP,  /* wirepath func */ 
			   cdarg, 
			   flags);
}

static __inline__ 
int DBSearchPaint(SearchContext *scx, 
		  TileTypeBitMask *mask, 
		  int xMask, 
		  int (*func) (/* ??? */), 
		  ClientData cdarg)
{
  return DBSearchPaintNew2(scx, 
			   mask, 
			   xMask, 
			   NULL, /* terminal path */
			   func, /* paint func */
			   NULL  /* polygon func */, 
			   NULL  /* wirepath func */, 
			   cdarg, 
			   0);   /* flags */
}

static __inline__ 
int DBSearchPaintNR(SearchContext *scx, 
		  TileTypeBitMask *mask, 
		  int xMask, 
		  int (*func) (/* ??? */), 
		  ClientData cdarg)
{
  return DBSearchPaintNew(scx, mask, xMask, 
			  func, /* paint func */
			  NULL, /* polygon func */
			  NULL, /* wirepath func */
			  cdarg, DBSP_NON_RECURSIVE);
}
     /* flags for DBSearchInstances2 */
/* don't search subcells */
#define DBSI_NON_RECURSIVE 1

/* in addition to unexpanded instances, visit expanded ones */
#define DBSI_INCLUDE_EXPANDED 2

extern int DBSearchInstances2(SearchContext *scx, 
			     int xMask, 
			     TerminalPath *tpath,
			     int (*func) (/* ??? */), 
			     ClientData cdarg,
			     int flags);

static __inline__
int DBSearchInstances(SearchContext *scx, 
		      int xMask, 
		      int (*func) (), 
		      ClientData cdarg)
{
  return DBSearchInstances2(scx, xMask, NULL, func, cdarg, 0);
}
    /* flags for DBSearchLabels2 */
/* don't search subcells */
#define DBSL_NON_RECURSIVE 1

extern int DBSearchLabels2(SearchContext *scx, 
			   TileTypeBitMask *mask, 
			   Rect *loc,
			   char *text,
			   int xMask, 
			   TerminalPath *tpath, 
			   int (*func) (/* ??? */), 
			   ClientData cdarg,
			   int flags);
static __inline__
int DBSearchLabels(SearchContext *scx, 
			   TileTypeBitMask *mask, 
			   int xMask, 
			   TerminalPath *tpath, 
			   int (*func) (/* ??? */), 
			   ClientData cdarg)
{
  return DBSearchLabels2(scx, mask, NULL, NULL, xMask, tpath, func, cdarg, 0);
}

extern int DBSearchLabelsGlob(SearchContext *scx, 
			     TileTypeBitMask *mask, 
			     int xMask, 
			     char *pattern, 
			     int (*func) (/* ??? */), 
			     ClientData cdarg,
			     int flag);  /* search labels flags */

extern int DBSearchFlyLines(SearchContext *scx, 
			    int xMask, 
			    int (*func)(SearchContext *scx, 
					FlyLine *flyline, 
					ClientData arg), 
			    ClientData cdarg);


extern int DBSrChildrenNested(SearchContext *scx, 
			      int (*func)(), 
			      ClientData cdarg);


static __inline__ int DBSrChildren(SearchContext *scx, 
				   int (*func)(), 
				   ClientData cdarg)
{
  return DBSrChildrenNested(scx, func, cdarg); 
}

extern int DBEnumRoots(CellDef *baseDef, 
		       Transform *transform, 
		       int (*func) (/* ??? */), 
		       ClientData cdarg); 

extern int DBEnumChildren(CellDef *cellDef, 
		      int (*func) (/* ??? */), 
		      ClientData cdarg);

extern int DBEnumArrayElements(CellUse *use, 
		     Rect *searchArea, 
		     int (*func) (/* ??? */), 
		     ClientData cdarg);

/* search area of paint plane */ 
extern int DBPlaneEnumAreaPaint(Tile *hintTile, 
			 register Plane *plane, 
			 register Rect *rect, 
			 TileTypeBitMask *mask, 
			 int (*func) (/* ??? */), 
			 ClientData arg);


/* search area of paint plane for given group */ 
extern int DBPlaneEnumAreaPaintG(Tile *hintTile, 
			 register Plane *plane, 
			 register Rect *rect, 
			 TileTypeBitMask *mask, 
			 Group *group,
			 int (*func) (/* ??? */), 
			 ClientData arg);

/* search area of paint plane restricting to matching client fields */ 
extern int DBPlaneEnumAreaPaintClient(Tile *hintTile, 
			 register Plane *plane, 
			 register Rect *rect, 
			 TileTypeBitMask *mask, 
                         ClientData client,				      
			 int (*func) (/* ??? */), 
			 ClientData arg);

extern void DBCellUseFindByPathName(char *name, 
			  CellUse *use, /* NOTE: modified by routine!? */
			  SearchContext *scx, 
			  bool defaultSubscripts,
			  bool noLoad);  /* if set does not read in cells */

/* === label search functions === */

extern int DBLabelFindByPathName(CellUse *rootUse, 
			char *name, 
			int (*func) (/* ??? */), 
			ClientData cdarg,
			bool noLoad);

extern int DBLabelFindByPathNameDef(CellDef *rootDef, 
			   char *name, 
			   int (*func) (/* ??? */), 
			   ClientData cdarg,
			   bool noLoad);

/* === "Next" functions === */

extern Point DBNextEdge(Plane *plane,
			Point *p, 
			int direction,
			int maxd);

extern Point DBNextEdgeH(CellUse *use, 
			TileType type, 
			Point *p, 
			int direction,
			int maxd,
			int xMask); 

extern Point DBNextDistance(Plane *plane, 
			    Point *p, 
			    int direction, 
			    Rect *area,
			    Point *dists);

extern Point DBNextDistanceH(CellUse *use, 
			     TileType type, 
			     Point *p, 
			     int direction, 
			     Rect *area,
			     int xMask);

extern TileTypeBitMask DBSrTouchingTypes(CellUse *cellUse, 
					 int expansionMask, 
					 Point *point,
					 int flags);
/* don't search subcells */
#define DBSTT_NON_RECURSIVE 1
/* active group only */
#define DBSTT_GROUP 2

					 

/* -------------- Groups --------------------------------------------- */
/* linked list pointed to by ti_groups to give groups tile belongs to.
 * NOTE:  SHOULD NOT be accessed directly outside of database module. 
 */

typedef struct glist
{
    TileType             gl_type;     
    Group                *gl_group;   
    struct glist         *gl_next;   
} GroupList;

/* helper func for DBsetTypeG */
extern void DBsetTypeG_multiGroup(Tile *tile, TileType newType, Group *group);

static __inline__ TileType DBgetTypeG(Tile *tile, Group *group) 
{
    if (!DBisSetTileFlag(tile,TF_MULTIGROUP))
    {
        if(group == (Group *) TiGetGroups(tile)) 
	{
	    return DBgetTileType(tile);
	}
    }
    else
    {
      TileType type = DBgetTileType(tile);
      GroupList *gl;
    
      for(gl=(GroupList *) TiGetGroups(tile); gl; gl=gl->gl_next)
      {
        if(gl->gl_group == group) return gl->gl_type;
      }
    }

    /* group not found */
    return TT_SPACE;
}

static __inline__ void DBsetTypeG(Tile *tile, TileType newType, Group *group) 
{
    TileType oldType = DBgetTypeG(tile,group);

    if(oldType == newType) return;

    /* multi-group case - handle in helper procedure */
    if (DBisSetTileFlag(tile,TF_MULTIGROUP)) 
    {
        DBsetTypeG_multiGroup(tile, newType, group);
        return;
    }

    /* non-multigroup "erase" */ 
    if(newType == TT_SPACE)
    {
        if((Group *) TiGetGroups(tile) == group)
	{
            DBsetTileType(tile, TT_SPACE);
	    TiSetGroups(tile, NULL); 
	 }
         return;
    }

    /* tile contents in SAME group */
    if(oldType != TT_SPACE)
    {
         DBsetTileType(tile,newType);
         return;
    }

    /* no groups currently present in tile */
    if(DBgetTileType(tile) == TT_SPACE)
    {
         DBsetTileType(tile,newType);
	 TiSetGroups(tile, group);
	 return;
    }

    /* different group and tile has content, need to make multi group */
    {
      GroupList *new1, *new2;

      DBsetTileFlag(tile, TF_MULTIGROUP);

      MALLOC(GroupList *, new1, sizeof(GroupList));
	new1->gl_type = DBgetTileType(tile);
	new1->gl_group = (Group *) TiGetGroups(tile);

      MALLOC(GroupList *, new2, sizeof(GroupList));
	new2->gl_type = newType;
	new2->gl_group = group;

      /* add new group to head of group list */
      TiSetGroups(tile, new2);
      new2->gl_next = new1;
      new1->gl_next = NULL;
      DBsetTileType(tile,new2->gl_type);
    }
}

/* lookup group by name */
extern Group *DBGroupFromName(CellDef *cellDef, char *name);

/* create new group in specified cell */
extern Group *DBGroupNew(CellDef *cellDef, char *name);

/* return mask of types of tile (for all groups) */
extern TileTypeBitMask *DBGroupTileTypesMask(Tile *tile);

/* convert tiles groups/types to string. */
extern void DBGroupTileTypes2S(char *buf, int bufSize, Tile *tile);

/* group classes (types) */
extern GroupClass *DBGroupClassNew(char *name);
GroupClass *DBGroupClassFromName(char *name);

/* group attributes */
extern char *DBGroupAttributeGet(Group *group, char *name);
extern void DBGroupAttributeSet(Group *group, char *name, char *value);

/* existance query */
extern bool DBGroupsQ(CellDef *def);

/* statistics */
int DBstatPaintPlane(Plane *pl, int* byType);
int DBstatCellPlane(CellDef *def, int *numTiles, int *numBodies);

/* -------------------- Exported max file suffix -------------------- */

extern char *DBSuffix;		/* Suffix for cell files */
extern char *DBPanicSuffix;	/* Suffix for cell panic saves */

/* -------------------- User Interface Stuff -------------------------- */

extern bool DBVerbose;		/* If FALSE, don't print warning messages */

/* ------------------ Exported technology variables ------------------- */

/***
 *** The following variables should be considered
 *** read-only to all clients of the database module.
 ***/

    /* Name, version, and description of the current technology */
extern char *DBTechName;
extern char *DBTechVersion;
extern char *DBTechDescription;

    /* list of all celldefs */
extern CellDef *DBCellDefs;    

    /*
     * Predefined masks of tile types.
     * The number of built-in types is just TT_TECHDEPBASE.
     */
extern TileTypeBitMask DBZeroTypeBits;		/* All zeroes */
extern TileTypeBitMask DBAllTypeBits;		/* All ones */
extern TileTypeBitMask DBBuiltinLayerBits;	/* All built-in types */
extern TileTypeBitMask DBAllButSpaceBits;	/* All but space */
extern TileTypeBitMask DBAllButSpaceAndDRCBits;	/* All but space and drc */
extern TileTypeBitMask DBSpaceBits;		/* Space only */
extern TileTypeBitMask DBFlyLineBits;		/* Flyline bit */

    /*
     * Number of tile types, including those specied by the technology
     * file and those built-in to Magic, but not including those automatically
     * generated to represent contact images.  Also, a mask of those
     * types contained in the technology file.
     *
     * NOTE: even though Magic style contacts and their image types are 
     * history, decided to preserve these as they may prove useful
     * when implementing auto generated (derived types?) 
     */
extern int DBNumUserLayers;
extern TileTypeBitMask DBUserLayerBits;		/* Including space */
extern TileTypeBitMask DBNonSpaceUserLayerBits;	/* Excluding space */

    /* Total number of Magic tile types in this technology */
extern int DBNumTypes;

    /* Total number of tile planes */
extern int DBNumPlanes;

/* Abbreviations */
#define	NT	TT_MAXTYPES
#define	NP	PL_MAXPLANES

    /* Gives the official long name of each plane: */
extern char		*DBPlaneLongNameTbl[NP];

    /* Gives a short name for each plane: */
extern char		*DBPlaneShortName(int pNum);

    /* Gives for each plane a mask of all tile types stored in that plane: */
extern TileTypeBitMask	DBPlaneTypes[NP];

    /* Gives a TileTypeBitMask for everything that connects to a type. */
extern TileTypeBitMask	DBConnectTbl[NT];

    /* Complement of above: everything not connected to a type */
extern TileTypeBitMask	DBNotConnectTbl[NT];

    /* table of masks with only the index type itself set */
extern TileTypeBitMask	DBSelfOnlyTbl[NT];

    /* Mask of all types that are components of a given type.  If
     * TTMaskHasType(&DBComponentTbl[r], s), then painting s over
     * r gives r.  For example, each of the residues of a contact
     * is a component of the contact.
     */
extern TileTypeBitMask DBComponentTbl[NT];

    /* list of planes connecting to each type 
     * (does not include types home plane).
     */
extern PlaneList *DBConnectPlanes[NT];

    /*
     * Each TileType has a home plane.  The TileType only appears on
     * its home plane.  The only exception is TT_SPACE, which can appear
     * on any plane.  
     *
     * DBTypePlaneTbl gives the home plane for a given TileType,
     */
extern int		DBTypePlaneTbl[TT_MAXTYPES];

/*
 * 
 * A type t is simple if:
 *   painting/erasing it does not effect any other (non space) type, and
 *   painting/erasing any other (non space) type does not effect it.
 *
 * Simple types are special cased in various places for efficiency.
 *
 * DBIsSimpleType is set to TRUE for simple types and FALSE for non-simple types.
 */ 
extern bool DBIsSimpleType[TT_MAXTYPES];

    /* Gives the long name for each tile type: */
extern char		*DBTypeLongNameTbl[TT_MAXTYPES];

    /* Gives a short name for a tile type: */
extern char		*DBTypeShortName(TileType type);

    /*
     * Gives the resulting tile type when one tile type is painted over
     * another in a given plane:
     *
     *	newType = DBPaintResult[pNum][paintType][oldType]
     */
extern PaintResultType	DBPaintResultTbl[NP][NT][NT];

    /*
     * Gives the resulting tile type when one tile type is erased over
     * another in a given plane:
     *
     *	newType = DBEraseResult[pNum][paintType][oldType]
     */
extern PaintResultType	DBEraseResultTbl[NP][NT][NT];

    /*
     * Gives the resulting tile type when one tile type is 'written'
     * over a given plane.  This corresponds to the case where the
     * written type replaces the old tile without regard to the type
     * of the old tile.
     *
     *	paintType = DBWriteResultTbl[paintType][oldType]
     */
extern PaintResultType	DBWriteResultTbl[NT][NT];

/* biggest label encountered (used by redisplay code) */
extern int DBLabelMaxDim;

/* --------------------- Exported macros ------------------------------ */

    /*
     * Macros for reading the paint/erase tables:
     *	resultType = DBStdPaintEntry(oldType, paintType, planeNum)
     *	resultType = DBStdEraseEntry(oldType, paintType, planeNum)
     */
#define	DBStdPaintEntry(h,t,p) 	(DBPaintResultTbl[p][t][h])
#define	DBStdEraseEntry(h,t,p)	(DBEraseResultTbl[p][t][h])

    /*
     * Macros for constructing the pointer to pass to DBPaintPlane
     * as the result table.
     */
#define	DBStdPaintTbl(t,p)	(&DBPaintResultTbl[p][t][0])
#define	DBStdEraseTbl(t,p)	(&DBEraseResultTbl[p][t][0])
#define DBStdWriteTbl(t)	(&DBWriteResultTbl[t][0])

    /*
     * int DBPlane(type) TileType type;
     * Returns the home plane of 'type'.
     */
#define	DBPlane(type)		(DBTypePlaneTbl[type])

    /*
     * char *DBTypeLongName(type) TileType type;
     * Returns the long name of 'type'.
     */
#define	DBTypeLongName(type)	(DBTypeLongNameTbl[type])

    /*
     * char *DBPlaneLongName(p) int p;
     * Returns the long name of plane 'plane'.
     */
#define	DBPlaneLongName(p)	(DBPlaneLongNameTbl[p])

    /*
     * bool DBConnectsTo(t1, t2) TileType t1, t2;
     * Returns TRUE if types 't1' and 't2' are electrically connected.
     */
#define	DBConnectsTo(t1, t2)	(TTMaskHasType(&DBConnectTbl[t1], t2))

#endif "database.h"
