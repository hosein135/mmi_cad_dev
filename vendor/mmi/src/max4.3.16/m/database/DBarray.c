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
 * DBarray.c --
 *
 * Procedures for manipulating arrays of cells.
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

#include <stdio.h>
#include "magic.h"
#include "database.h"
#include "databaseInt.h"
#include "geometry.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "databaseInt.h"
#include "layout.h"
#include "layout.h"
#include "undo.h"
#include "debug.h"


/*
 * ----------------------------------------------------------------------------
 *
 * DBArrayTransformInfo
 *
 * transform celluse array info 
 * ----------------------------------------------------------------------------
 */

void
DBArrayTransformInfo(Transform *t,
		     ArrayInfo *in,
		     ArrayInfo *out) 
{
  /* transform separations */
  out->ar_xsep = t->t_a*in->ar_xsep + t->t_b*in->ar_ysep;
  out->ar_ysep = t->t_d*in->ar_xsep + t->t_e*in->ar_ysep;

  /* transform indices */ 
  if (t->t_a == 0)
  {
    /* x and y swapped */
    out->ar_xlo = in->ar_ylo;
    out->ar_ylo = in->ar_xlo;
    out->ar_xhi = in->ar_yhi;
    out->ar_yhi = in->ar_xhi;
  }
  else
  {
    out->ar_xlo = in->ar_xlo;
    out->ar_ylo = in->ar_ylo;
    out->ar_xhi = in->ar_xhi;
    out->ar_yhi = in->ar_yhi;
  }
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBMakeArray --
 *
 * Turn cellUse into an array whose X indices run from xlo through xhi
 * and whose Y indices run from ylo through yhi.  The separation between
 * adjacent array elements is xsep in the X direction, and ysep in the
 * Y direction.
 *
 * The X and Y information is in coordinates of the root cell def.
 * It gets transformed down to the def of cellUse according to the
 * transform supplied.  What we do guarantee is that the array
 * indices will appear, in root coordinates, to run from xlo to xhi
 * left-to-right, and from ylo to yhi bottom-to-top.
 *
 * The celluse bbox is set to bbox of entire array.
 *
 * NOTE:  This routine should only be called on a new (unlinked) use, 
 * after DBCellUseNewArray() BUT before DBInstanceAdd().
 *
 * ----------------------------------------------------------------------------
 */

void
DBMakeArray(CellUse *cellUse, 
	    Transform *rootToCell, 
	    int xlo, 
	    int ylo, 
	    int xhi, 
	    int yhi, 
	    int xsep, 
	    int ysep)
{
  ArrayInfo in;

  /* celluse must already be array, or array fields not allocated */
  ASSERT(DBIsArray(cellUse),"DBMakeArray");

  in.ar_xlo = xlo;
  in.ar_ylo = ylo;
  in.ar_xhi = xhi;
  in.ar_yhi = yhi;
  in.ar_xsep = xsep;
  in.ar_ysep = ysep;

  DBArrayTransformInfo(rootToCell, &in, &cellUse->cu_array);
  dbCellUseSetBBox(cellUse,NULL);
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBArrayOverlap --
 *
 * Determine which elements of an array overlap the supplied clipping
 * rectangle.  Assumes that the clipping rectangle overlaps at least
 * some part of the array area.
 *
 * Results:
 *	None.
 *
 * WARNING:
 *	This code is very sensitive to being changed.  Make sure you
 *	understand it before you change it.
 *
 * Side Effects:
 *	Sets *pxlo, *pxhi, *pylo, *pyhi to be the inclusive range of array
 *	indices which overlay the given clipping rectangle.
 *
 *	If there is any overlap in X, *pxlo <= *pxhi; similarly, if there
 *	is any overlap in Y, *pylo <= *pyhi.
 *
 * ----------------------------------------------------------------------------
 */

void
DBArrayOverlap(register CellUse *cu, 
                         	/* Pointer to cell use which may be an array */
	       Rect *parentRect, 
                     		/* Clipping rectangle in parent coords */
	       int *pxlo, 
	       int *pxhi, 
	       int *pylo, 
	       int *pyhi)
{
    int outxlo, outxhi, outylo, outyhi, t;
    int xlo, ylo, xhi, yhi, xsep, ysep;
    Transform parentToCell;
    Rect box, childR;

    /* For a non-arrayed element, return 0 indices. */
    if (!DBIsArray(cu))
    {
      *pxlo = *pxhi = 0;
      *pylo = *pyhi = 0;
      return;
    }

    box = *DBBBoxCellDef(cu->cu_def);

    GEOINVERTTRANS(&cu->cu_transform, &parentToCell);
    GEOTRANSRECT(&parentToCell, parentRect, &childR);
    xsep = cu->cu_xsep;
    ysep = cu->cu_ysep;

    /*
     * Canonicalize the array indices so that the base element
     * of the array has the minimum x and y coordinate, ie,
     * so that xlo <= xhi and ylo <= yhi.
     */
    if (cu->cu_xlo > cu->cu_xhi) xlo = cu->cu_xhi, xhi = cu->cu_xlo;
    else			 xlo = cu->cu_xlo, xhi = cu->cu_xhi;

    if (cu->cu_ylo > cu->cu_yhi) ylo = cu->cu_yhi, yhi = cu->cu_ylo;
    else			 ylo = cu->cu_ylo, yhi = cu->cu_yhi;


    /*
     * If the separation along one of the coordinate axes is negative,
     * flip everything about that axis.
     */
    if (xsep < 0)
    {
	xsep = (-xsep);
	t = childR.r_xbot; childR.r_xbot = -childR.r_xtop; childR.r_xtop = -t;
	t = box.r_xbot; box.r_xbot = -box.r_xtop; box.r_xtop = -t;
    }

    if (ysep < 0)
    {
	ysep = (-ysep);
	t = childR.r_ybot; childR.r_ybot = -childR.r_ytop; childR.r_ytop = -t;
	t = box.r_ybot; box.r_ybot = -box.r_ytop; box.r_ytop = -t;
    }

    /*
     * The following inequalities are used to derive the equations
     * computed below.  "Blo" is the lower coordinate of the incident
     * box, and "Bhi" is the upper coordinate.
     *
     *	  min outlo : (outlo - lo) * sep + top >= Blo
     *	  max outhi : (outhi - lo) * sep + bot <= Bhi
     *
     * The intent is that "outlo" will be the smaller of the two
     * coordinates, and "outhi" the larger.
     */
    
    /* Even though it should never happen, handle zero spacings
     * gracefully.
     */

    if (xsep != 0)
    {
	outxlo = xlo + (childR.r_xbot - box.r_xtop + xsep - 1) / xsep;
	outxhi = xlo + (childR.r_xtop - box.r_xbot) / xsep;
    }
    else
    {
	outxlo = xlo;
	outxhi = xhi;
    }
    if (ysep != 0)
    {
	outylo = ylo + (childR.r_ybot - box.r_ytop + ysep - 1) / ysep;
	outyhi = ylo + (childR.r_ytop - box.r_ybot) / ysep;
    }
    else
    {
	outylo = ylo;
	outyhi = yhi;
    }

    /*
     * Clip against the canonicalized array indices.
     * Note that this may result in rxlo > rxhi or rylo > ryhi, in which
     * case the rectangle doesn't intersect the array at all.
     */
    if (outxlo < xlo) outxlo = xlo;
    if (outxhi > xhi) outxhi = xhi;
    if (outylo < ylo) outylo = ylo;
    if (outyhi > yhi) outyhi = yhi;

    /*
     * Convert canonicalized array indices back into actual
     * array indices for output.
     */
    if (cu->cu_xlo > cu->cu_xhi)
    {
	*pxhi = cu->cu_xhi + cu->cu_xlo - outxlo;
	*pxlo = cu->cu_xhi + cu->cu_xlo - outxhi;
    }
    else
    {
	*pxlo = outxlo;
	*pxhi = outxhi;
    }

    if (cu->cu_ylo > cu->cu_yhi)
    {
	*pyhi = cu->cu_yhi + cu->cu_ylo - outylo;
	*pylo = cu->cu_yhi + cu->cu_ylo - outyhi;
    }
    else
    {
	*pylo = outylo;
	*pyhi = outyhi;
    }
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBComputeArrayArea --
 *
 * Given an area in native coordinates of a celldef, computes the
 * corresponding area in a parent's coordinates, for a particular
 * celluse and a particular element of an array.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	Sets *prect to the given area in the given array instance,
 *	subject to the arraying and transformation inforamtion in
 *	the given cellUse.
 *
 * ----------------------------------------------------------------------------
 */

void
DBComputeArrayArea(Rect *area, 
               		/* Area to be transformed. */
		   CellUse *cellUse, 
                     	/* Cell use whose bounding box is to be computed */
		   int x, 
		   int y, 
             		/* Indexes of array element whose box is being found */
		   Rect *prect)
                	/* Pointer to rectangle to be set to bounding
			 * box of the given array element, in coordinates
			 * of the def of cellUse.
			 */
{
    int xdelta, ydelta;

    if(!DBIsArray(cellUse))
    {
      xdelta = 0;
      ydelta = 0;
    }
    else
    {
      x = (cellUse->cu_xlo > cellUse->cu_xhi) ?	
	cellUse->cu_xlo - x : x - cellUse->cu_xlo;

      y = (cellUse->cu_ylo > cellUse->cu_yhi) ?
	cellUse->cu_ylo - y : y - cellUse->cu_ylo;

      xdelta = cellUse->cu_xsep * x;
      ydelta = cellUse->cu_ysep * y;
    }

    prect->r_xbot = area->r_xbot + xdelta;
    prect->r_xtop = area->r_xtop + xdelta;
    prect->r_ybot = area->r_ybot + ydelta;
    prect->r_ytop = area->r_ytop + ydelta;
}

/*
 * ----------------------------------------------------------------------------
 *
 * DBGetArrayTransform --
 *
 * 	This procedure computes the transform from a particular element
 *	of an array to the coordinates of the array as a whole.
 *
 * Results:
 *	The return result is a pointer to a transform describing how
 *	coordinates of use->cu_def must be transformed in order to
 *	appear in the (x,y) element location.  In other words, if the
 *	transform for the whole array (use->cu_transform) were
 *	GeoIdentityTransform, this is the transform from use->cu_def
 *	to the parent use for the (x,y) element.  By the way, the
 *	return result is a locally-allocated transform that goes away
 *	the next time this procedure is called, so use it carefully.
 *
 * Side effects:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */

Transform *
DBGetArrayTransform(CellUse *use, int x, int y)
                 
             			/* Array indices of the desired element.
				 * These must fall within the range of
				 * use's array indices.
				 */
{
    static Transform result;
    int xbase, ybase;
    
    if(!DBIsArray(use))
    {
      xbase = 0;
      ybase = 0;
    }
    else
    {
      int xsep, ysep;

      xsep = (use->cu_xlo > use->cu_xhi)?
	-use->cu_xsep : use->cu_xsep;
      ysep = (use->cu_ylo > use->cu_yhi) ?
	-use->cu_ysep : use->cu_ysep;
      xbase = xsep * (x - use->cu_xlo);
      ybase = ysep * (y - use->cu_ylo);
    }

    GeoTransTranslate(xbase, 
		      ybase, 
		      &GeoIdentityTransform, 
		      &result);
    return &result;
}

