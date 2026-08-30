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
 * CIFint.h --
 *
 * Defines things shared internally by the cif module of Magic,
 * but not generally needed outside the cif module.
 *
 * See CIFread.h for definitions specific to the CIF reader.
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
 * rcsid "$Header: CIFint.h,v 6.0 90/08/28 18:05:04 mayo Exp $"
 */

#define _CIFINT

#ifndef	_MAGIC
int err0 = Need_to_include_magic_header;
#endif	_MAGIC
#ifndef	_DATABASE
int err1 = Need_to_include_database_header;
#endif	_DATABASE

/* The main data structure used in the cif module is a description
 * of how to generate CIF layers from the Magic tiles.  There may
 * be several different styles for generating CIF from the same Magic
 * information, e.g. for fabricating at different geometries.  Each
 * of these CIF styles involves three kinds of data.  A "CIFStyle"
 * record gives overall information such as the number of layers.
 * One "CIFLayer" gives overall information for each layer, and
 * then a list of one or more "CIFOp" records describes a sequence
 * of geometrical operations to perform to generate the layer.  This
 * data structure is built up by reading the technology file.
 */

/* A CIFOp starts from a partially-completed CIF layer, does something
 * to it, which may possibly involve some existing layers or temporary
 * layers, and creates the next stage of the partially-completed
 * CIF layer.  Example operations are to AND with some existing paint,
 * or to grow by a certain amount.
 */

typedef struct cifop
{
    TileTypeBitMask co_paintMask;/* Zero or more paint layers to consider. */
    TileTypeBitMask co_cifMask;	 /* Zero or more other CIF layers. */
    int co_opcode;		/* Which geometric operation to use.  See
				 * below for the legal ones.
				 */
    int co_distance;		/* Grow or shrink distance (if needed). */
    int co_bloats[TT_MAXTYPES];	/* For CIFOP_BLOAT, CIFOP_BLOATMAX, and
				 * CIFOP_BLOATMIN: distance to grow each
				 * layer.  For CIFOP_SQUARES: [0] is the
				 * border around squares, [1] is the size
				 * of each square, [2] is the separation
				 * between squares, and [3] is nonzero
				 * to specify alignment rather than centering
				 * of squares.  For other operations,
				 * not used.
				 */
    struct cifop *co_next;	/* Next in list of operations to perform. */
} CIFOp;

/* The opcodes defined so far are:
 *
 * CIFOP_AND -		AND current results with the layers indicated by
 *			the masks.
 * CIFOP_ANDNOT -	Wherever there is material indicated by the masks,
 *			erase those areas from the current results.
 * CIFOP_OR -		OR current results with the layers indicated by
 *			the masks.
 * CIFOP_GROW -		Grow the current results uniformly by co_distance.
 * CIFOP_SHRINK -	Shrink the current results uniformly by co_distance.
 * CIFOP_SHRINKX -	Shrink the current results in X only.
 * CIFOP_SHRINKY -	Shrink the current results in Y only.
 * CIFOP_BLOAT -	Find layers in paintMask, then bloat selectively
 *			according to co_bloats, and OR the results into
 *			the current plane.
 * CIFOP_SQUARES -	Generates a pattern of squares (used for making
 *			contact vias.  Each square is co_bloats[1] (size) large,
 *			the squares are separated from each other by
 *			co_bloats[2] (separation), and they are inside the edge of
 *			the material by at least co_bloats[0] (border).  If
 *                      co_bloats[3] (align) is nonzero, the squares are aligned
 *                      to the left and bottom tile edges, rather than centered.
 * CIFOP_BLOATMAX -	Like CIFOP_BLOAT, except whole side of tile gets
 *			bloated by same amount, which is max bloat from
 *			anywhere along side.  Bloats can be negative.
 * CIFOP_BLOATMIN -	Same as CIFOP_BLOAT, except use min bloat from
 *			anywhere along side.
 */

#define CIFOP_AND	1
#define CIFOP_OR	2
#define CIFOP_GROW	3
#define CIFOP_SHRINK	4
#define CIFOP_SHRINKX	5
#define CIFOP_SHRINKY   6
#define CIFOP_BLOAT	7
#define CIFOP_SQUARES	8
#define CIFOP_BLOATMAX	9
#define CIFOP_BLOATMIN	10
#define CIFOP_ANDNOT	11

/* The following data structure contains all the information about
 * a particular CIF layer.
 */

typedef struct
{
    char *cl_name;		/* Name of layer. */
    CIFOp *cl_ops;		/* List of operations.  If NULL, layer is
				 * determined entirely by cl_initial.
				 */
    int cl_growDist;		/* Largest distance material may move in
				 * this layer from its original Magic
				 * position, due to grows.  Expressed
				 * in CIF units.  If this layer uses temp
				 * layers, this distance must include grows
				 * from the temp layers.
				 */
    int cl_shrinkDist;		/* Same as above, except for shrinks. */
    int clay_flags;		/* Bunches of flags:  see below. */
    int cl_calmanum;		/* Number (0-63) of this layer for output as
				 * Calma (GDS-II stream format), or -1 if
				 * this layer should not be output.
				 */
    int cl_calmatype;		/* Data type (0-63) for Calma output, or -1
				 * if this layer should not be output.
				 */
  int cl_labelGDSNum[LAB_MAX_KIND+1];  /* gds number for labels on this layer,
				        * indexed by label kind.
				        */
  int cl_labelGDSType[LAB_MAX_KIND+1]; /* gds type for labels on this layer,
				        * indexed by label kind. 
				        */
} CIFLayer;

/* The CIFLayer flags are:
 *
 * CIF_TEMP:	Means that this is a temporary layer used to build
 *		up CIF information.  It isn't output in the CIF file.
 */

#define CIF_TEMP 1

/* The following data structure describes a complete set of CIF
 * layers.  The number of CIF layers (MAXCIFLAYERS) must not be
 * greater than the number of tile types (TT_MAXTYPES)!!
 */

#define MAXCIFLAYERS (TT_MAXTYPES - 1)
typedef struct cifstyle
{
    char *cs_name;		/* Name used for this kind of CIF. */
    int cs_nLayers;		/* Number of layers. */
    int cs_radius;		/* Radius of interaction for hierarchical
				 * processing (expressed in Max database units).
				 */
    double cs_DBRes;             /* microns per Max database unit */
    double cs_CIFPlaneRes;       /* microns per CifPlane Unit 
				 * (.01 for old "scaleFactor" styles)
				 */
    double cs_CIFRes;            /* microns per CIF output unit.
				 * (.01*reducer for old "scaleFactor styles) 
				 * NOTE: should be multiple of .01, and evenly
				 *       divide DBRes.
				 */
    double cs_GDSRes;            /* microns per GDS output unit.
				 * (.001  for old "scaleFactor styles)
				 * NOTE: some CAD programs assume GDS resolution
				 *       of millimicrons = .001
				 */
    int cs_charSetRestrict;     /* If non-zero, text in output filtered,
				 * converting non-standard chars (such as '.'!)
				 * to 'X'
				 */

    int cs_bBoxCalmaNum;        /* if non-negative, output bounding boxes for
				 * cells on this layer
				 */
    int cs_bBoxCalmaType;       /* calma type for bounding boxes */

    int cs_iNamePropNum;       /* if non-negative, output instance names on
				 * given property attribute of gds instance
				 * references (SREF's)
				 */

    int cs_iNameCalmaNum;        /* if non-negative, output instance names
				  * on this layer
				  */
    int cs_iNameCalmaType;       /* calma type of instance names */
      
    TileTypeBitMask cs_yankLayers;
				/* For hierarchical processing, only these
				 * Magic types need to be yanked.
				 */
    TileTypeBitMask cs_hierLayers;
				/* For hierarchical processing, only these
				 * CIF layers need to be generated.
				 */
    bool cs_hierInteractions;    /* if set, need to process hierarchical 
				  * interactions when writing GDS
				  *
				  * (may be FALSE even when cs_hierLayers
				  *  nonempty, if cs_hierLayers required only
				  *  for temp layers)
				  */

    int cs_labelLayer[TT_MAXTYPES];
				/* Each entry corresponds to one Magic layer,
				 * and gives index of CIF real layer to use
				 * for labels attached to this Magic layer.
				 * -1 means no known CIF layer for this Magic
				 * layer.
				 */

    int cs_polygonLayer[TT_MAXTYPES];
				/* Each entry corresponds to one Max DB layer,
				 * and gives index of CIF real layer to use
				 * for polygons and wirepaths attached to 
				 * this DB layer.
				 * -1 means no known CIF layer for this DB
				 * layer.
				 */
    CIFLayer *cs_layers[MAXCIFLAYERS];
				/* Describes how to generate each layer.*/
    struct cifstyle *cs_next;
				/* Pointer to next in list of styles. */
} CIFStyle;

/**** CIFStyle flags ***/

/* procedures */

extern bool CIFNameToMask(char *name, TileTypeBitMask *result);

extern void CIFGen(CellDef *cellDef, 
		   Rect *area, 
		   Plane **planes, 
		   TileTypeBitMask *layers, 
		   int replace, 
		   int genAllPlanes,
		   bool flattenGCells);
extern void CIFGenSubcells(CellDef *def, 
			   Rect *area, 
			   Plane **output,
			   bool flattenGCells);
extern void CIFGenArrays(CellDef *def, 
			 Rect *area, 
			 Plane **output,
			 bool flattenGCells);

extern void CIFClearPlanes(Plane **planes);
extern Plane *CIFGenLayer(CIFOp *op, 
			  Rect *area, 
			  CellDef *cellDef, 
			  Plane **temps,
			  bool flattenGCells);
extern void CIFInitCells(void);
extern int cifHierCopyFunc(Tile *tile, TreeContext *cxp);

/* Shared variables and structures: */

extern Plane *CIFPlanes[];		/* Normal place to store CIF. */
extern CIFStyle *CIFStyleList;		/* List of all CIF styles. */
extern CIFStyle *CIFCurStyle;		/* Current cif (output) style */
extern CellUse *CIFComponentUse;	/* Flatten stuff in here if needed. */
extern CellDef *CIFComponentDef;	/* Corresponds to CIFComponentUse. */
extern CellUse *CIFDummyUse;		/* Used to dummy up a CellUse for a
					 * def.
					 */

/* scale factors when reading gds or cif, (used by cif and gds module) 
 *
 * normally derived from CIF*Res vaiables (see cif.h), but may vary
 * if cifinput section specifies scalefactor. 
 *
 * CifPlanes = intermediate planes used for geometric processing.
 */
extern double cifRdScaleCIF2CIFPlane; 
extern double cifRdScaleCIFPlane2DB; 
extern double cifRdScaleCIF2DB; 

/* following variables used to keep track of max rounding errors when
 * applying above scale factors.
 */
extern double cifRdScaleCIF2CIFPlaneErr; 
extern double cifRdScaleCIFPlane2DBErr; 
extern double cifRdScaleCIF2DBErr; 

/* Statistics counters: */

extern int CIFTileOps;
extern int CIFHierTileOps;
extern int CIFRects;
extern int CIFHierRects;

/* Tables used for painting and erasing CIF. */

extern PaintResultType CIFPaintTable[], CIFEraseTable[];

/* Procedures and variables for reporting errors. */

extern int CIFErrorLayer;
extern CellDef *CIFErrorDef;
extern void CIFError(Rect *area, char *message);

/* The following determines the tile type used to hold the CIF
 * information on its paint plane.
 */

#define CIF_SOLIDTYPE 1
extern TileTypeBitMask CIFSolidBits;

/* stepsize for hier processing, in typical wire widths 
 * linked to tcl var CIF_HIER_STEP_SIZE 
 */
extern int cifHierStepSizeWidths;

