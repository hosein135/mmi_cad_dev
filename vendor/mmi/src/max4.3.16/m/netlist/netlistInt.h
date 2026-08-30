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
 * netlistInt.h --
 *
 * Internal to netlist module.
 */

#ifndef _NETLISTINT
#define _NETLISTINT

#ifndef _NETLIST
#include "netlist.h"
#endif _NETLIST

#ifndef _STACK
#include "stack.h"
#endif _STACK

/* CONNECTIVITY */
extern TileTypeBitMask *ntlConnectTbl;

/* 
 * ----------------------------------------------------------------------------
 * ntlConnect --
 *
 * Results: returns TRUE iff the given layers connect to each other
 *
 *
 * ----------------------------------------------------------------------------
 */
static __inline__ bool ntlConnect(TileType layer1,
				  TileType layer2) 
{
  return TTMaskHasType(&ntlConnectTbl[layer1],layer2);
}


/* -------------------------- Label lists ----------------------------- */

/*
 * List of labels for a node.
 *"N"  prefix avoids collision with extract files, 
 * not needed after extract stuff removed
 * pointer to port is used to find port number when making connections
 */
typedef struct nll
{
    Label 	*ll_label;	/* Actual Label in the source CellDef */
    struct nll	*ll_next;	/* Next LabelList in this region */
    int		ll_uniq;	/*  > 0  for duplicated names */
    int		ll_attr;	/* used for transistor "attributes", from extractor*/
    struct po 	*ll_port;	/* this label's port */
    int		ll_flag;	/* flag labels added for netlisting */
} NLabelList;


#define NLL_NOATTR       -1      /* Value for ll_attr above if the label is
                                 * not a transistor attribute.
                                 */
#define NLL_GATEATTR     -2      /* Value for ll_attr if the label is a gate
                                 * attribute, rather than one of the diffusion
                                 */

/*
 * Types of labels.
 * These can be or'd into a mask and passed to ntlLabType().
 */
#define NLABTYPE_NAME            0x01    /* Normal node name */
#define NLABTYPE_NODEATTR        0x02    /* Node attribute */
#define NLABTYPE_GATEATTR        0x04    /* Transistor gate attribute */
#define NLABTYPE_TERMATTR        0x08    /* Transistor terminal (source/drain)
                                         * attribute.
					 */
   /*
     * GENERIC Region struct.
     * All this provides is a pointer to the next Region.
     * This is the type passed to functions like ExtFreeRegions,
     * and is the type returned by ExtFindRegions.  Clients should
     * cast pointers of this type to their own, client type.
     */
typedef struct nlgenreg
{
    struct reg  *reg_next;      /* Next region in list */
} NRegion;


 /*
     * GENERIC region with labels.
     * Any other structure that wants to reference node names
     * must include the same fields as this one as its first part.
     */
typedef struct nlreg
{
    struct nlreg *lreg_next;     /* Next region in list */
    int          lreg_pnum;     /* Lowest numbered plane in this region */
    int          lreg_class;    /* Type of tile that contains lreg_ll */
    Point        lreg_ll;       /* Lower-leftmost point in this region on
                                 * plane lreg_pnum.  We take the min first
                                 * in X, then in Y.
                                 */
    NLabelList   *lreg_labels;   /* List of labels for this region.  These are
                                 * any labels connected to the geometry making
                                 * up this region.  If the list is empty, make
                                 * up a name from lreg_pnum and lreg_ll.
                                 */
} NLabRegion;

#define ntlSetRegion(tp,r)	( (tp)->ti_client = (ClientData) (r) )
#define ntlGetRegion(tp)	( (tp)->ti_client )
#define ntlHasRegion(tp,und)	( (tp)->ti_client != (und) )


typedef struct nrec
{
    struct nrec	*nrec_next;	/* Next region in list */
    struct nrec ** nrec_alias;	/* if not null, contains the address of the nrec *
    				 * that this node has been merged with
				 */
    int		 nrec_pnum;	/* Lowest numbered plane in this region */
    int		 nrec_class;	/* Type of tile that contains nrec_ll */
    Point	 nrec_ll;	/* Lower-leftmost point in this region on
				 * plane nreg_pnum.  We take the min first
				 * in X, then in Y.
				 */
    struct nll	*nrec_labels;	/* */
    /* CapValue	 nrec_cap;	 */ /* Capacitance to ground */
    int		 nrec_nodenum;
    int		nrec_type;	/* global or port type */
    int	 nrec_area[1];		/* Dummy; each node actually has
				 * ExtCurStyle->exts_numResistClasses
				 * array elements allocated to it.
				 */
} NodeRecord;

#define ntlBaseNode(np)	((np->nrec_alias == NULL) ? np : *(np->nrec_alias))

    /*
     * Transistor region: labelled region with perimeter and area.
     * Used for each transistor in the flat extraction of a cell.
     */
typedef struct nltreg
{
    struct nltreg *treg_next;	/* Next region in list */
    int		 treg_pnum;	/* UNUSED */
    int		 treg_class;	/* Type of tile that contains treg_ll */
    Point	 treg_ll;	/* UNUSED */
    NLabelList	*treg_labels;	/* Attribute list */
    Tile	*treg_tile;	/* Some tile in the channel */
    int		 treg_area;	/* Area of channel */
} NTransRegion;

/* -------------------------------------------------------------------- */

#define ntlSetRegion(tp,r)      ( (tp)->ti_client = (ClientData) (r) )
#define ntlGetRegion(tp)        ( (tp)->ti_client )
#define ntlHasRegion(tp,und)    ( (tp)->ti_client != (und) )


/* For non-recursive flooding algorithm */
#define VISITPENDING    ((ClientData) NULL)     /* Marks tiles on stack */
#define NPUSHTILE(tp) \
    if (1) { \
        (tp)->ti_client = VISITPENDING; \
        STACKPUSH((ClientData) (tp), ntlNodeStack); \
    } else

    /* 
     * a port connector contains a connection for each port of the cellUse
     * one is used for each array element with in the use
     */
typedef struct pc
{
    int		pc_numAlloced;
    NodeRecord * pc_conns[1];	/* actual size kept in pc_numAlloced */
}PortConnector;

    /*
     * ports are kept in a list rooted in each celldef
     * the portnum is used to access this ports' entry in
     * the connection array that is rooted in each celluse
     *
     * the name used for the port is the name of the node 
     * that is connected to, hence po_node
     * a port list is necessary because there may be multiple ports
     * on a single node (feedthroughs)
     */
typedef struct po
{
    struct po  * po_next;    
    struct po  * po_nextFt;
    int          po_portnum;  
    int          po_flags;  
    NodeRecord * po_node;	
} Port;

#define NTL_PORT_FT_HEAD 1
#define NTL_PORT_FT_ELEM 2

typedef struct ha
{
    Tile *  ha_extTile;
    Rect *  ha_extRect;
    Rect *  ha_intRect;
    bool ha_pass2;

    CellUse *  ha_use1;
    PortConnector ** ha_elementConns1;

    CellUse *  ha_use2;
    PortConnector ** ha_elementConns2;
} HierArg;


extern Transform *ntlTransUse1toParent;
extern Transform *ntlTransUse2toParent;
extern NodeRecord *ntlNewNode(void);

extern CellDef * ntlCurDef;

/*
 * the issue with this at present is that polygons are not ordered, 
 * so we don't know their LL point, and just use the first set
 * if we treat the polys just like tiles, then:
 * if the poly is on a lower plane number, it will
 * be used as the new location, even if a previously chosen 
 * tile has a more accurate LL corner, but is on a higher plane
 *
 * to avoid this, the poly location is only used if there are no other
 * tiles or polys on this node, 
 * OR if the LL corner is really to the left of the current point
 * and on the same or lower plane
 *
 * the result is that the ll point recorded may not account for poly points
 *
 */
#define	ntlSetNodeLLPoly(reg, pn, poly) \
    if (1) { \
	if ((reg)->nrec_pnum == DBNumPlanes) \
	{ \
	    (reg)->nrec_class = (poly)->poly_type; \
	    (reg)->nrec_pnum = (pn); \
	    (reg)->nrec_ll.p_x = (int)(poly)->poly_points[0].pf_x; \
	    (reg)->nrec_ll.p_y = (int)(poly)->poly_points[0].pf_y; \
	} \
	else if ((pn) <= (reg)->nrec_pnum) \
	{ \
	    if ((int)poly->poly_points[0].pf_x < (reg)->nrec_ll.p_x) \
	    { \
		(reg)->nrec_ll.p_x = (int)(poly)->poly_points[0].pf_x; \
		(reg)->nrec_ll.p_y = (int)(poly)->poly_points[0].pf_y; \
		(reg)->nrec_class = (poly)->poly_type; \
	    } \
	    else if ((int)poly->poly_points[0].pf_x == (reg)->nrec_ll.p_x \
		    && (reg)->nrec_ll.p_y < (int)poly->poly_points[0].pf_y) \
	    { \
		(reg)->nrec_ll.p_y = (int)(poly)->poly_points[0].pf_y; \
		(reg)->nrec_class = (poly)->poly_type; \
	    } \
	} \
    } else

/*
 * The following updates reg->lreg_ll and reg->lreg_pnum so that
 * they are always the lowest leftmost coordinate in a cell, on
 * the plane with the lowest number.
 */
#define	ntlSetNodeNum(reg, pn, tp) \
    if (1) { \
	if ((pn) < (reg)->lreg_pnum) \
	{ \
	    (reg)->lreg_class = DBgetTileType(tp); \
	    (reg)->lreg_pnum = (pn); \
	    (reg)->lreg_ll = (tp)->ti_ll; \
	} \
	else if ((pn) == (reg)->lreg_pnum) \
	{ \
	    if (LEFT(tp) < (reg)->lreg_ll.p_x) \
	    { \
		(reg)->lreg_ll = (tp)->ti_ll; \
		(reg)->lreg_class = DBgetTileType(tp); \
	    } \
	    else if (LEFT(tp) == (reg)->lreg_ll.p_x \
		    && BOTTOM(tp) < (reg)->lreg_ll.p_y) \
	    { \
		(reg)->lreg_ll.p_y = BOTTOM(tp); \
		(reg)->lreg_class = DBgetTileType(tp); \
	    } \
	} \
    } else

/*
 * Argument passed to filter functions for finding regions.
 */
typedef struct
{
    TileTypeBitMask     *nfra_connectsTo; /* Array of TileTypeBitMasks.  The
                                          * element fra_connectsTo[t] has a
                                          * bit set for each type that
                                          * connects to 't'.
                                          */
    CellDef             *nfra_def;        /* Def being searched */
    int                  nfra_pNum;       /* Plane currently searching */
    ClientData           nfra_uninit;     /* This value appears in the ti_client
                                          * field of a tile if it's not yet
                                          * been visited.
                                          */
    NRegion           *(*nfra_first)();   /* Function to init new region */
    int                (*nfra_each)();    /* Function for each tile in region */
    NRegion            *nfra_region;     /* Ptr to Region struct for current
                                          * region.  May be set by fra_first
                                          * and used by fra_each.
                                          */
} NFindRegion;

#define NTILEAREA(tp)    ((TOP(tp) - BOTTOM(tp)) * (RIGHT(tp) - LEFT(tp)))

/* -------------------- Perimeter of a region ------------------------- */

/*
 * Segment of the boundary of a region whose perimeter
 * is being traced by ExtTracePerimeter() and extEnumTilePerim().
 */
typedef struct
{
    Tile        *b_inside;      /* Pointer to tile just inside segment */
    Tile        *b_outside;     /* Pointer to tile just outside segment */
    Rect         b_segment;     /* Actual coordinates of segment */
    int          b_direction;   /* Direction following segment (see below) */
    int          b_plane;       /* extract argument for extSideOverlap   */
} NBoundary;

#define NBoundaryLength(bp) \
        ((bp)->b_segment.r_xtop - (bp)->b_segment.r_xbot \
    +    (bp)->b_segment.r_ytop - (bp)->b_segment.r_ybot)

/* Directions in which we can be following the boundary of a perimeter */

#define NBD_UP           0       /* Inside is to right */
#define NBD_LEFT         1       /* Inside is below */
#define NBD_DOWN         2       /* Inside is to left */
#define NBD_RIGHT        3       /* Inside is above */

extern bool ntlOutputAsComment;

/* switchs */
extern bool ntlUseGlobals;
extern bool ntlOutputToplevelAsSubckt;
extern bool ntlNoImplicitPorts;
extern bool ntlVerbose;
extern bool ntlReportBadDevices;
extern bool ntlReportSplitNets;

extern int ntlNumWarnings;

/* --- PROCEDURES SHARED BETWEEN FILES IN THIS MODULE --- */

extern void 
ntlMnNetlist(CellUse *rootUse, char *outName);

extern void 
ntlHierInstances(CellDef * def);

extern int 
ntlHierInstFunc(CellUse * use1, ClientData none);

extern void
ntlInst2InstPorts(NodeRecord  * intNode,
		  TileType intType,
		  Rect * overlapRect,
		  HierArg * ha);

extern int 
ntlTile2ElementFunc(CellUse * use, 
		    Transform * trans, 
		    int x, 
		    int y, 
		    HierArg * ha);

extern PortConnector * 
ntlAllocPortCons(PortConnector *curConns,
		 int numConns);

extern char *
ntlNodeName(NodeRecord *node);

extern void 
ntlLabelNodes(CellDef *def); 

extern void
ntlFindDuplicateLabels(CellDef *def, 
		       NodeRecord *nodeList);

extern void
ntlFreeNodeRecs(CellDef  *def); 

extern void 
ntlNumberNodes(CellDef * cd);

extern int
ntlFindNeighbors(Tile *tile, 
		 int tilePlaneNum, 
		 NFindRegion *arg);

extern NodeRecord *
ntlFindNodes( CellDef * def);

extern void
ntlOutputSbcktDecl(CellDef * cd, 
		   FILE * f);

extern int
ntlOutputInstancesFn(CellUse * use, 
		     FILE * f);

extern void
ntlOutputGlobals(Stack *stack, 
		 FILE * f);

extern void 
ntlOutputNodes(CellDef *cd, 
	       FILE * f);

extern char *
ntlNodeName(NodeRecord * node);

extern char *
ntlNodeNameG(NodeRecord * node);

extern char *
ntlNodeNameNoAlias(NodeRecord * node);

extern int
ntlEnumTilePerim(Tile *tpIn, 
		 TileTypeBitMask mask, 
                         	/* Note: this is not a pointer */
		 int (*func) (/* ??? */), 
		 ClientData cdata);

extern int 
ntlAllocPortConsFn(CellUse * use, ClientData none);

extern int 
ntlFreePortConsFn(CellUse * use, ClientData none);

extern int
ntlAddPort(CellDef * def, NodeRecord * node, TileType type, Rect * bbox);

extern int 
ntlMergeDefNodesFn(CellUse * use, CellDef * def);

extern void 
ntlMarkFTPorts(CellDef * def);

extern NRegion *
ntlFindRegions(CellDef *def, 
	       Rect *area, 
	       TileTypeBitMask *mask, 
	       TileTypeBitMask *connectsTo, 
	       NRegion *(*first) (/* ??? */),
	       int (*each) (/* ??? */));


/*** devices.c ***/

extern void
ntlTransInit(void);

extern void
ntlTransDefineFet(TileType gateLayer,
		  TileType sdLayer,
		  char *fetName,
		  char *subNode);

extern void
ntlTransDump(void);

extern NRegion *
ntlTransFind(CellDef *def);

#endif _NETLISTINT
