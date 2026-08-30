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
 * cifRead.h --
 *
 * This file contains definitions used by the CIF reader, but not
 * by the CIF writing code.  The definitions are only used internally
 * to this module.
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
 * rcsid "$Header: CIFread.h,v 6.1 90/09/12 17:14:22 mayo Exp $
 */
#ifndef _CIFREAD
#define _CIFREAD

#ifndef	_DATABASE
#include database.h
#endif	_DATABASE
#ifndef	_CIFINT
#include cifint.h
#endif	_CIFINT

/* The structures below are built up by CIFreadtech.c to describe
 * various styles for reading CIF.
 */

/* The following structure describes a sequence of geometric
 * operations used to produce information for a single Max DB
 * layer.  There may be several of these structures for the
 * same DB layer;  in that case, the results end up being
 * OR'ed together.
 */
typedef struct
{
    TileType crl_magicType;	/* Magic layer to paint results. */
    CIFOp *crl_ops;		/* List of operations to generate
				 * info for Magic layer.
				 */
} CIFReadStyleLayer;


/* The constant MAXCIFRLAYERS must be less than TT_MAXTYPES.
 * It limits the largest number of distinct CIF layer names
 * over all read styles.
 */
#define MAXCIFRLAYERS (TT_MAXTYPES - 1)

/*
 * The constant MAXCRSLAYERS specifies the maximum number of "layer" commands
 * in a cif read style.  
 */
#define MAXCRSLAYERS MAXCIFRLAYERS

/* The following structure defines a complete CIF read-in style. */
typedef struct cifrstyle
{
    char *crs_name;		/* Name for this style of CIF input. */
    TileTypeBitMask crs_cifLayers;
				/* Mask of CIF layers understood in
				 * this style.
				 */
    int crs_scaleFactor;	/* Number of CIF units per Max DB unit 
				 * (from "scalefactor" line)
				 * normally 0: scale determined from
				 * CifDBRes etc.
				 */
    int crs_iNamePropNum;       /* if non-negative, look for instance names on
				 * given property attribute of gds instance
				 * references (SREF's)
				 */
    int crs_iNameCalmaNum;       /* if non-negative, look for instance names on
				  * this layer
				  */

    int crs_iNameCalmaType;     /* calma type of instance names */

    int crs_bBoxCalmaNum;       /* if non-negative, look for instance bounding
				 * boxes on this layer.
				 */

    int crs_bBoxCalmaType;       /* calma type of instance bounding box */

    int crs_nLayers;		/* Number of CIFReadStyleLayers defined 
				 * for this style
				 */

    CIFReadStyleLayer *crs_layers[MAXCRSLAYERS];
                                /* "layer" statments internalized here
				 * contains sequence of ops and Max DB
				 * layer to copy results to.
				 */

    TileType crs_labelLayer[MAXCIFRLAYERS];
				/* Gives the Max DB tiletype to use for labels
				 * on each possible CIF layer.
				 */

    int crs_labelKind[MAXCIFRLAYERS];
				/* Gives the label kind to assign to labels
				 * on each possible CIF layer.
				 */

    TileType crs_DBType[MAXCIFRLAYERS];
				/* Gives the Max DB tiletype corresponding to
				 * this CIF layer, for CIF layers that 
				 * correspond directly to Max layers and
				 * are not involved in any layer operations.
				 *
				 * Used to avoid double paint operation
				 * during gds reading for directly mapped layers.
				 */


    struct cifrstyle *crs_next;	/* Next in list of styles (NULL for
				 * end of list).
				 */

    HashTable cifCalmaToCif;    /* Table mapping from Calma layer numbers to
                                 * CIF layers
				 */

    HashTable crs_GDSToPort;    /* Table mapping from Calma layer numbers to
                                 * label kinds (ports) 
				 */


} CIFReadStyle;

/* For parsing CIF, we need to keep track of paths (wire locations
 * or polygon boundaries.  These are just linked lists of points.
 */

typedef struct cifpath
{
    Point cifp_point;		/* A point in the path. */
    struct cifpath *cifp_next;	/* The next point in the path, or NULL. */
} CIFPath;

#define cifp_x cifp_point.p_x
#define cifp_y cifp_point.p_y

/* Procedures */
extern void CIFReadError(char *fmt, ...);
extern void CIFFreePath(CIFPath *path);
extern void CIFReadCellFinish(void); 
extern void CIFReadCellInit(int ptrkeys), CIFReadCellCleanup(void);
extern void CIFMakeManhattanPath(CIFPath *pathHead);

extern LinkedRect *CIFPolyToRects(CIFPath *path);
extern Transform *CIFDirectionToTrans(Point *point);
extern int CIFReadNameToType(char *name, int newOK);

/* Variables shared by the CIF-reading modules, see CIFreadutils.c
 * for more details:
 */

extern int cifReadScale1, cifReadScale2;
extern int cifNReadLayers;
extern Plane *cifReadPlane;
extern Plane **cifCurReadPlanes;
extern TileType cifCurLabelType;
extern CIFReadStyle *cifReadStyleList;
extern CIFReadStyle *cifCurReadStyle;
extern bool cifSubcellBeingRead;
extern CellDef *cifReadCellDef;
extern FILE *cifInputFile;
extern bool cifParseLaAvail;
extern int cifParseLaChar;
extern char *cifReadLayers[];

/* constants */

#endif _CIFREAD

