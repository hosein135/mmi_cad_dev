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
 * gdsReadPaint.c --
 *
 * Input of GDS-II stream format.
 * Processing of paint (paths, boxes, and boundaries) and text.
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
static char rcsid[]="$Header: CalmaRdpt.c,v 6.2 90/09/03 15:29:59 stark Exp $";
#endif  not lint

#include <stdio.h>
#include <sys/types.h>

#include "magic.h"
#include "geometry.h"
#include "geometry.h"
#include "tile.h"
#include "utils.h"
#include "hash.h"
#include "database.h"
#include "databaseInt.h"
#include "malloc.h"
#include "main.h"
#include "cif.h"
#include "cifInt.h"
#include "cifRead.h"
#include "signals.h"
#include "layout.h"
#include "styles.h"
#include "message.h"
#include "debug.h"
#include "gdsInt.h"

/*
 * ----------------------------------------------------------------------------
 *
 * gdsLayerWarning --
 *
 * This procedure is called when (layer, dt) doesn't map to a valid
 * Calma layer.  The first time this procedure is called for a given
 * (layer, dt) pair, we print an error message; on subsequent times,
 * no error message is printed.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	A warning message is printed if the first time for this (layer, dt).
 *	Adds an entry to the HashTable calmaLayerHash if one is not
 *	already present for this (layer, dt) pair.
 *
 * ----------------------------------------------------------------------------
 */

static Void
gdsLayerWarning(char *mesg, int layer, int dt)
{
    CalmaLayerType clt;
    HashEntry *he;

    if(!gdsReadReportUnmappedLayers) return;

    clt.clt_layer = layer;
    clt.clt_type = dt;
    he = HashFind(&calmaLayerHash, (char *) &clt);
    if (HashGetValue(he) == (ClientData) NULL)
    {
	HashSetValue(he, (ClientData) 1);
	gdsReadMsgWarn("%s, layer=%d type=%d", mesg, layer, dt);
    }
}

/*
 * ----------------------------------------------------------------------------
 *
 * gdsCIFLayerWarning --
 *
 * This procedure is called when a ciflayer is not mapped for non-manhattan
 * output.
 *
 * An error message is only printed on the first occurance.
 *
 * ----------------------------------------------------------------------------
 */

static Void
gdsCIFLayerWarning(char *mesg, int ciftype)
{
  if(gdsReadCIFWarning[ciftype]) return;
  gdsReadMsgWarn("%s, mask layer = %s", 
		 mesg, 
		 cifReadLayers[ciftype]);
  gdsReadCIFWarning[ciftype] = TRUE;
}


/*
 * ----------------------------------------------------------------------------
 *
 * calmaReadPath --
 *
 * This procedure parses a Calma path (point list), which is an XY record
 * containing one or more points.  
 *
 * Calma paths are used to define boundary (or polygon) vertices, and
 * (wire) path center lines.
 *
 * Results:
 *	A newly malloced path, or null on error
 *
 *
 * ----------------------------------------------------------------------------
 */

CIFPath *
calmaReadPath(bool *nonManp) 
                      /* gets set to indicate whether path is manhattan,
                       *
		       * If NULL, nonManhattan paths are converted to manhattan
		       * by stair stepping.
		       */
{
    CIFPath path, *pathtailp, *newpathp, *result; 
    int nbytes, rtype, npoints;
    bool nonManhattan = FALSE;

    if(nonManp) *nonManp = FALSE;

    pathtailp = (CIFPath *) NULL;
    path.cifp_next = (CIFPath *) NULL;

    /* Read the record header */
    READRH(nbytes, rtype);
    if (nbytes < 0)
    {
	gdsReadMsgWarn("EOF when reading coordinate list.");
	return NULL;
    }
    if (rtype != CALMA_XY)
    {
	gdsReadMsgUnexpectedRecord(CALMA_XY, rtype);
	return NULL;
    }

    /* Read this many points (pairs of four-byte integers) */
    result = NULL;
    npoints = (nbytes - CALMAHEADERLENGTH) / 8;
    while (npoints--)
    {
	READPOINT(&path.cifp_point);
	if (gdsRdEOF)
	{
	    CIFFreePath(result);
	    return NULL;
	}

	MALLOC(CIFPath *, newpathp, sizeof (CIFPath));
	*newpathp = path;
	if (result)
	{
	    /* Check for manhattan */
	    if (pathtailp->cifp_x != newpathp->cifp_x &&
		pathtailp->cifp_y != newpathp->cifp_y)	nonManhattan = TRUE;

	    pathtailp->cifp_next = newpathp;
	}
	else 
	{
	  result = newpathp;
	}
	pathtailp = newpathp;
    }

    if (nonManhattan)
    {
      if(nonManp)
      {
	*nonManp = TRUE;
      }
      else
      {
	CIFMakeManhattanPath(result);
	calmaStairSteps++;
      }
    }
    return result;
}


/*
 * ----------------------------------------------------------------------------
 *
 * gdsReadLayer --
 *
 * This procedure parses GDSII layer and type records 
 * (for boundary/box/path elements) 
 *
 * Returns corresponding cif type in current read style,
 * or -1 on error.
 *
 * ----------------------------------------------------------------------------
 */
static int gdsReadLayer(void)
{
  int layer,dt;
  int cifType;

  /* Read layer and data type */
  if (!calmaReadI2Record(CALMA_LAYER, &layer)
      || !calmaReadI2Record(CALMA_DATATYPE, &dt))
  {
    gdsReadMsgWarn("Missing layer or datatype in GDSII boundary/box/path.");
    return -1;
  }

  /* convert to cif type */
  cifType = CIFCalmaLayerToCifLayer(layer, dt, cifCurReadStyle);
  if (cifType < 0)
  {
    /* skip warning on bbox layer
     * TODO: can be removed once bbox properly implemented 
     */
    int bLayer = cifCurReadStyle->crs_bBoxCalmaNum;
    int bType = cifCurReadStyle->crs_bBoxCalmaType;

    if(bLayer==-1 || bLayer!=layer || bType!=dt)  
    {
      gdsLayerWarning("Unknown layer/datatype", layer, dt);
    }
    return -1;
  }

  return cifType;
}



/*
 * ----------------------------------------------------------------------------
 *
 * gdsPolygonDBType --
 *
 * figure out DB layer for non-manhattan geometrys for given ciftype
 * (for boundary/box/path elements) 
 *
 * Returns corresponding DB type, or -1 if none.
 *
 * ----------------------------------------------------------------------------
 */
static int gdsPolygonDBType(int ciftype)
{
  int dbType;

  /* direct map from input layer to database layer? */
  dbType = cifCurReadStyle->crs_DBType[ciftype];
  if(dbType>0) return dbType;

  /* try label layer */ 
  dbType = cifCurReadStyle->crs_labelLayer[ciftype];

  /* warn user */
  if(dbType<=0)
  {
    gdsCIFLayerWarning("Could not map non-manhattan geometry", 
		       ciftype);
    dbType = -1;
  }
  else
  {
    gdsCIFLayerWarning("Mask operations ignored for non-manhattan geometry", 
		       ciftype);
  }

  return dbType;
}


/*
 * ----------------------------------------------------------------------------
 *
 * calmaElementBoundary --
 *
 * Read a polygon.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Paints one or more rectangles into one of the CIF planes.
 *
 * ----------------------------------------------------------------------------
 */

Void
calmaElementBoundary(void)
{
    int ciftype;
    TileType dbType;
    CIFPath *pathheadp;
    LinkedRect *rectList;
    bool nonManhattan;
    
    /* Skip CALMA_ELFLAGS, CALMA_PLEX */
    calmaSkipSet(calmaElementIgnore);

    /* read GDS layer and type (and map to cifType) */
    ciftype = gdsReadLayer();
    if(ciftype<0) return;

    /* Read the path itself, building up a path structure 
     * If no dbTypePolygon exists for this layer, convert to manhattan by stair
     * stepping
     */
    pathheadp = calmaReadPath(&nonManhattan);
    if(!pathheadp)
    {
      gdsReadMsgError("Error while reading path for boundary/box; ignored.");
      return;
    }

    /* if nonManhattan convert to polygon */
    if(nonManhattan)
    {
      CIFPath *cifp;
      PointFloat *points, *pp;
      int numPoints = 0;

      /* get database type */
      dbType = gdsPolygonDBType(ciftype);
      if(dbType<0) return;

      /* count vertices (excluding last one = repetition of first) */
      for(cifp = pathheadp; cifp->cifp_next; cifp=cifp->cifp_next) numPoints++;

      /* malloc point array */
      MALLOC(PointFloat *, points, sizeof(PointFloat)*numPoints);

      /* copy points to point array, transforming from cifplane 
       * to database coords */
      pp = points;
      for(cifp = pathheadp; cifp->cifp_next; cifp=cifp->cifp_next)
      {
	/* copy points, transforming to (floating point) database coordinates */
	pp->pf_x = cifp->cifp_point.p_x * cifRdScaleCIFPlane2DB;
	pp->pf_y = cifp->cifp_point.p_y * cifRdScaleCIFPlane2DB;
	pp++;
      }

      /* create polygon */
      gdsReadNumPolygons++; 
      DBPolyNew(cifReadCellDef, 
		dbType, 
		numPoints, 
		points, 
		NULL,  /* not part of WirePath */
		TRUE); /* do change notication */

      CIFFreePath(pathheadp);
      return;
    }

    /* Convert manhattan boundary polygon to rectangles. */

    /* direct map? */
    dbType = cifCurReadStyle->crs_DBType[ciftype];

    rectList = CIFPolyToRects(pathheadp);
    if (rectList == NULL)
    {
      /* if conversion failed, print warning and return. */

      char buf[BUFSIZ];
      sprintf(buf,"Couldn't convert manhattan polygon"
	      " into rects; ignored.\n"
	      "\tPolygon:  ");

      /* add polygon points to output */
      {
	CIFPath *cifp;

        for(cifp = pathheadp; cifp->cifp_next; cifp=cifp->cifp_next)
        {
	  char buf2[BUFSIZ];

	  sprintf(buf2," (%g,%g)",
		  cifp->cifp_point.p_x*CIFDBRes, 
		  cifp->cifp_point.p_y*CIFDBRes);

	  strcat(buf,buf2);
	}
      }

      /* terminate message */
      strcat(buf,"\n");       		

      gdsReadMsgWarn(buf);

      CIFFreePath(pathheadp);
      return;
    }
    CIFFreePath(pathheadp);

    /* Paint the rectangles */
    if(dbType)
    {
      LinkedRect *rp;
      int pNum = DBTypePlaneTbl[dbType];

      /* Scale rects to DB coordinates */
      for (rp = rectList; rp != NULL ; rp = rp->r_next)
      {
	Rect rDB;
	int pNum;

	GeoScaleRect(&rp->r_r, 
		     cifRdScaleCIFPlane2DB,
		     &cifRdScaleCIFPlane2DBErr);
      }

      /* paint directly to relevant plane in current cell */
      for (rp = rectList; rp != NULL ; rp = rp->r_next)
      {
	DBPaintPlane(cifReadCellDef->cd_planes[pNum], 
		     &rp->r_r,
		     DBStdPaintTbl(dbType, pNum), 
		     (PaintUndoInfo *) NULL);
      }
    }
    else
    {
      LinkedRect *rp;
      Plane *cifPlane = cifCurReadPlanes[ciftype];
      ASSERT(cifPlane,"calmaElementBoundary");
      
      /* paint rects to relevant cif plane */
      for (rp = rectList; rp != NULL ; rp = rp->r_next)
      {
	DBPaintPlane(cifPlane, 
		     &rp->r_r, 
		     CIFPaintTable, 
		     (PaintUndoInfo *)NULL);
      }
    }

    /* free the rect list */
    for (; rectList != NULL ; rectList = rectList->r_next)
    {
      FREE((char *) rectList);
    }
}


/*
 * ----------------------------------------------------------------------------
 *
 * calmaElementBox --
 *
 * Read a box.
 * This is an optimized version of calmaElementBoundary
 * that handles rectangular polygons.  These polygons each
 * have five vertex points, with the first and last point
 * being the same, and all sides parallel to one of the two
 * coordinate axes.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Paints one rectangle into one of the CIF planes.
 *
 * ----------------------------------------------------------------------------
 */

Void
calmaElementBox(void)
{
    int ciftype;
    TileType dbType;
    int nbytes, rtype, npoints;
    Point p;
    Rect r;

    /* Skip CALMA_ELFLAGS, CALMA_PLEX */
    calmaSkipSet(calmaElementIgnore);

    /* read GDS layer and type (and map to cifType) */
    ciftype = gdsReadLayer();
    if(ciftype<0) return;

    /* direct map from input layer to database layer? */
    dbType = cifCurReadStyle->crs_DBType[ciftype];

    /*
     * Read the path itself.
     * Since it is Manhattan, we can build our rectangle directly.
     */
    r.r_xbot = r.r_ybot = INFINITY;
    r.r_xtop = r.r_ytop = MINFINITY;

    /* Read the record header */
    READRH(nbytes, rtype);
    if (nbytes < 0)
    {
	gdsReadMsgError("EOF when reading box.");
	return;
    }
    if (rtype != CALMA_XY)
    {
	gdsReadMsgUnexpectedRecord(CALMA_XY, rtype);
	return;
    }

    /* Read this many points (pairs of four-byte integers) */
    npoints = (nbytes - CALMAHEADERLENGTH) / 8;
    if (npoints != 5)
    {
	gdsReadMsgError("Box doesn't have 5 points.");
	(void) calmaSkipBytes(nbytes - CALMAHEADERLENGTH);
	return;
    }
    while (npoints-- > 0)
    {
	READPOINT(&p);
	if (p.p_x < r.r_xbot) r.r_xbot = p.p_x;
	if (p.p_y < r.r_ybot) r.r_ybot = p.p_y;
	if (p.p_x > r.r_xtop) r.r_xtop = p.p_x;
	if (p.p_y > r.r_ytop) r.r_ytop = p.p_y;
    }

    /* Paint the rectangle */
    if(dbType)
    {
      int pNum = DBTypePlaneTbl[dbType];

      /* Scale to DB coordinates */
      GeoScaleRect(&r, 
		   cifRdScaleCIFPlane2DB,
		   &cifRdScaleCIFPlane2DBErr);

      /* paint directly to relevant DB plane in current cell */
      DBPaintPlane(cifReadCellDef->cd_planes[pNum], 
		   &r,
		   DBStdPaintTbl(dbType, pNum), 
		   (PaintUndoInfo *) NULL);
    }
    else
    {
      Plane *cifPlane = cifCurReadPlanes[ciftype];
      ASSERT(cifPlane,"calmaElementBox");

      DBPaintPlane(cifPlane, &r, CIFPaintTable, (PaintUndoInfo *)NULL);
    }
}



/*
 * ----------------------------------------------------------------------------
 *
 * gdsPaintPathRect --
 *
 * paints single rectangle for gdsPaintPath
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	May paint rectangles into CIF planes.
 *
 * ----------------------------------------------------------------------------
 */
static __inline__ void gdsPaintPathRect(int cifType,
					TileType dbType,
					int x0,
					int y0,
					int x1,
					int y1)
{
  Rect r;

  r.r_xbot = MIN(x0,x1);
  r.r_xtop = MAX(x0,x1);
  r.r_ybot = MIN(y0,y1);
  r.r_ytop = MAX(y0,y1);

  if(dbType)
  {
    /* PAINT DIRECTLY TO DATABASE */

    int pNum = DBTypePlaneTbl[dbType];

    /* Scale to DB coordinates */
    GeoScaleRect(&r, 
		 cifRdScaleCIFPlane2DB,
		 &cifRdScaleCIFPlane2DBErr);

    /* paint directly to relevant plane in current cell */
    DBPaintPlane(cifReadCellDef->cd_planes[pNum], 
		 &r,
		 DBStdPaintTbl(dbType, pNum), 
		 (PaintUndoInfo *) NULL);
  }
  else
  {
    /* PAINT TO CIFPLANE */

    Plane *cifPlane = cifCurReadPlanes[cifType];
    ASSERT(cifPlane,"gdsPaintPathRect");

    DBPaintPlane(cifPlane, 
		 &r, 
		 CIFPaintTable, 
		 (PaintUndoInfo *)NULL);
  }
}


/*
 * ----------------------------------------------------------------------------
 *
 * gdsExtendMVector --
 *
 * Modifys second point of manhattan vector to extend vector by given distance
 * (in direction from p0 to p1)
 *
 * ----------------------------------------------------------------------------
 */
static __inline__ void gdsExtendMVector(int dist,  /* amount to extend vector */
					int x0,    /* first point */
					int y0,
					int *x1,  /* second point (gets modified) */
					int *y1)
{	
  ASSERT((x0 == *x1)|| (y0 == *y1),"gdsExtendManhattanVector"); 

  
  if(*x1<x0) 
  {
    *x1 -= dist;
  }
  else if (*x1>x0)
  {
    *x1 += dist;
  }
  else if (*y1<y0) 
  {
    *y1 -= dist;
  }
  else if (*y1>y0) 
  {
    *y1 += dist;
  }
}


/*
 * ----------------------------------------------------------------------------
 *
 * gdsPaintPath --
 *
 * paint a manhattan path (as rectangles).
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Paints directly into database if possible,
 *      otherwise to intermediate cif planes.
 *
 * ----------------------------------------------------------------------------
 */
static void gdsPaintPath(int cifType,      /* layer */
			 int pathType,     /* end extension type */
			 int width,        /* path width */
			 CIFPath *path)    /* path points */
{
  /* direct map from input layer to database layer? */
  TileType dbType = cifCurReadStyle->crs_DBType[cifType];

  int radius = width/2;
  CIFPath  *cifp;      /* current point in path */
  int xPrev, yPrev;    /* coordinates of previous point in path */

  /* start loop on second point = first segment */ 
  cifp=path->cifp_next;
  ASSERT(cifp,"gdsPaintPath");

  /* set 'previous' point to first point in path */
  xPrev = path->cifp_x;
  yPrev = path->cifp_y;

  /* adjust for initial extension */
  if(pathType != CALMAPATH_SQUAREFLUSH)
  {
    /* extend end by the wire radius */
    ASSERT(pathType == CALMAPATH_SQUAREPLUS,"gdsPaintPath");
    gdsExtendMVector(radius, cifp->cifp_x, cifp->cifp_y, &xPrev, &yPrev);
  }
    
  /* loop through path starting with second point.
   * draws segment ending at current point.
   * miters to following segment (if any).
   */
  for(;cifp;cifp=cifp->cifp_next)
  {
    int x = cifp->cifp_x;
    int y = cifp->cifp_y;
    CIFPath *next = cifp->cifp_next;

    /* handle final segment extension */
    if(!next && pathType != CALMAPATH_SQUAREFLUSH)
    {
      /* extend end by the wire radius */
      ASSERT(pathType == CALMAPATH_SQUAREPLUS,"gdsPaintPath");
      gdsExtendMVector(radius, xPrev, yPrev, &x, &y);
    }

    /* paint this segment */
    if(x==xPrev)
    {
      /* vertical segment */
      gdsPaintPathRect(cifType,dbType,x-radius,yPrev,x+radius,y);
    }
    else
    {
      /* horizontal segment */
      gdsPaintPathRect(cifType,dbType,xPrev,y-radius,x,y+radius);
    }

    /* if following segment, miter to it
     * (corners of miter rect defined by extending current and
     * next segment.)
     */
    if(next)
    {
      int miterX0 = x;
      int miterY0 = y; 
      int miterX1 = x;
      int miterY1 = y; 

      gdsExtendMVector(radius, xPrev, yPrev, &miterX0, &miterY0);
      gdsExtendMVector(radius, next->cifp_x, next->cifp_y, &miterX1, &miterY1);
      gdsPaintPathRect(cifType,dbType,miterX0,miterY0,miterX1,miterY1);
    } 

    xPrev = x;
    yPrev = y;

  } /* for */
}


/*
 * ----------------------------------------------------------------------------
 *
 * gdsAddWP --
 *
 * add a wirepath to database.
 *
 * ----------------------------------------------------------------------------
 */
static void gdsAddWP(int ciftype, 
		     int pathtype, 
		     int width, 
		     CIFPath *path)
{
  int dbType;
  int size;
  CIFPath *cifp;
  Point *points, *p;
  int i;

  /* get database type */
  dbType = gdsPolygonDBType(ciftype);
  if(dbType<0) return;

  /* determine size */
  size = 0;
  for(cifp=path; cifp; cifp=cifp->cifp_next) size++;
  if (size < 2)
  {
    gdsReadMsgWarn("Bad path size:  %d (path ignored)",size);
    return; 
  }

  /* convert width to DB units */
  GeoScaleInt(&width, 
	      cifRdScaleCIFPlane2DB,
	      &cifRdScaleCIFPlane2DBErr);

  /* create points */
  points = DBPointsAlloc(size, NULL, NULL);
  for(cifp=path,p=points; 
      cifp; 
      cifp=cifp->cifp_next,p++) 
  {
    p->p_x = cifp->cifp_x;
    p->p_y = cifp->cifp_y;
    GeoScalePoint(p, 
		  cifRdScaleCIFPlane2DB,
		  &cifRdScaleCIFPlane2DBErr);
  }

  /* create wirepath */
  DBWPathNew(cifReadCellDef, 
	     dbType, 
	     pathtype, 
	     width, 
	     size, 
	     points, 
	     FALSE, 
	     NULL);
}


/*
 * ----------------------------------------------------------------------------
 *
 * calmaElementPath --
 *
 * Read a centerline wire.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	May paint rectangles into CIF planes.
 *
 * ----------------------------------------------------------------------------
 */

Void
calmaElementPath(void)
{
    static int ignore[] = { CALMA_BGNEXTN, CALMA_ENDEXTN, -1 };
    int ciftype;
    int nbytes, rtype;
    int width, pathtype;
    CIFPath *path;
    bool nonManhattan;

    /* Skip CALMA_ELFLAGS, CALMA_PLEX */
    calmaSkipSet(calmaElementIgnore);

    /* read GDS layer and type (and map to cifType) */
    ciftype = gdsReadLayer();
    if(ciftype<0) return;

    /* read pathtype (Describes the shape of the ends of the path) */
    pathtype = CALMAPATH_SQUAREFLUSH;
    PEEKRH(nbytes, rtype);
    if (nbytes > 0 && rtype == CALMA_PATHTYPE)
    {
      if(!calmaReadI2Record(CALMA_PATHTYPE, &pathtype))
      {
	gdsReadMsgWarn("error reading pathtype (path ignored)"); 
	return;
      }
    }

    /* variable extensions not yet supported. */
    if (pathtype == CALMAPATH_VARIABLE)
    {
	gdsReadMsgWarn("pathtype %d not suppported (path ignored)\n", 
		       pathtype);
	return;
    }

    /*
     * Read path width
     * (zero-width paths rejected later)
     */
    width = 0;
    PEEKRH(nbytes, rtype) 
    if (nbytes > 0 && rtype == CALMA_WIDTH)
    {
	if (!calmaReadI4Record(CALMA_WIDTH, &width)) 
	{
	    gdsReadMsgError("Error in reading GDSII path width") ;
	    return;
	}
    }

    /* Skip BGNEXTN, ENDEXTN (define variable endcap extensions) */
    calmaSkipSet(ignore);

    /* Read the points in the path */
    path = calmaReadPath(&nonManhattan);
    if(!path)
    {
	gdsReadMsgWarn("Improper path; ignored.");
	return;
    }

    /* Don't process zero-width paths any further */
    if (width <= 0)
    {
      gdsReadMsgWarn("Zero width path; ignored.");
      goto freeit;
    }

    /* scale width */
    GeoScaleIntGrid(&width, 
		    gdsRdScaleGDS2CIFPlane, 
		    &gdsRdScaleGDS2CIFPlaneErr,
		    gdsRdRoundRes);

    if(pathtype == CALMAPATH_ROUND || nonManhattan || ODD(width)) 
    {
      /* add wirepath */
      gdsAddWP(ciftype, pathtype, width, path);
    }
    else
    {
      /* paint manhattan path */
      gdsPaintPath(ciftype, pathtype, width, path);
    }

freeit:
    CIFFreePath(path);
}


/*
 * ----------------------------------------------------------------------------
 *
 * calmaElementText --
 *
 * Read labels 
 *
 * Results:
 *	None.
 *
 * Side effects:
 *      Add labels.
 *      Add Iname text to Iname list.
 *
 * ----------------------------------------------------------------------------
 */
void
calmaElementText(void)
{
    static int ignore[] = { CALMA_PRESENTATION, CALMA_PATHTYPE, CALMA_WIDTH,
			    CALMA_STRANS, CALMA_MAG, CALMA_ANGLE, -1 };
    char textbody[GDS_STRING_LENGTH + 2];
    int nbytes, rtype;
    int layer, textt, cifnum;
    TileType type = -1;  /* initialize to avoid compiler warnings */
    int labKind = LAB_LOCAL;
    Rect r;

    /* Skip CALMA_ELFLAGS, CALMA_PLEX */
    calmaSkipSet(calmaElementIgnore);

    /* Grab layer and texttype */
    if (!calmaReadI2Record(CALMA_LAYER, &layer)) return;
    if (!calmaReadI2Record(CALMA_TEXTTYPE, &textt)) return;

    /* if label (i.e. not iname) 
     * get cif layer index (cifnum) and 
     * Max type. 
     */
    if( layer != cifCurReadStyle->crs_iNameCalmaNum)
    {
      cifnum = CIFCalmaLayerToCifLayer(layer, textt, cifCurReadStyle);
      if (cifnum < 0)
      {
	gdsLayerWarning("Label on unknown layer/datatype", layer, textt);
	type = TT_SPACE;
      }
      else type = cifCurReadStyle->crs_labelLayer[cifnum];
    }

    /* Skip presentation, pathtype, width, and transform */
    calmaSkipSet(ignore);

    /* Coordinates of text */
    READRH(nbytes, rtype);
    if (nbytes < 0) return;
    if (rtype != CALMA_XY)
    {
	gdsReadMsgUnexpectedRecord(CALMA_XY, rtype);
	return;
    }
    nbytes -= CALMAHEADERLENGTH;
    if (nbytes < 8)
    {
	gdsReadMsgError("Not enough bytes in point record.");
    }
    else
    {
	READPOINT(&r.r_ll);
	nbytes -= 8;
    }
    if (!calmaSkipBytes(nbytes)) return;
    GeoScalePoint(&r.r_ll, 
		  cifRdScaleCIFPlane2DB,
		  &cifRdScaleCIFPlane2DBErr);
    r.r_ur = r.r_ll;

    /* String itself */
    if (!calmaReadStringRecord(CALMA_STRING, 
			       textbody,
			       GDS_STRING_LENGTH)) return;

    /* Eliminate strange characters. */
    {
	static bool algmsg = FALSE;
	bool changed = FALSE;
	char *cp;
	for (cp = textbody; *cp; cp++)
	{
	  if ( gdsMapSlashHack && *cp == '/' )
	  {
	    /* temporary hack, no warning in this case */
	    *cp = '|';
	  }
	  else if ( gdsMapSlashHack && *cp == '|' )
	  {
	    gdsReadMsgWarn("label text ('%s' contains '|', WILL BE REMAPPED TO '/' ON GDS OUTPUT!\n",
			   textbody);
	  }
	  else if (*cp <= ' ' | *cp > '~') 
	  {
	    changed = TRUE;
	    if (*cp == '\r' && *(cp+1) == '\0')
	      *cp = '\0';
	    else if (*cp == '\r') 
	      *cp = '_';
	    else if (*cp == ' ')
	      *cp = '_';
	    else
	      *cp = '?';
	  }
	}
	if (changed) 
	{
	  gdsReadMsgWarn("Bad chars in label or instance name remapped: '%s'", 
			 textbody);
	  if (!algmsg) 
	  {
	    algmsg = TRUE;
	    gdsReadMsgWarn("Character remap algorithm:\n\t"  
			   "trailing <CR> dropped,\n\t"
			   "<CR> and ' ' changed to '_',\n\t"
			   "other non-printables changed to '?')");
	  }
	}
    }

    /* determine label kind (port type) */
    if( layer != cifCurReadStyle->crs_iNameCalmaNum)
    {
      CalmaLayerType clt;
      HashEntry *he;

      clt.clt_layer = layer;
      clt.clt_type = textt;
      if (he = HashLookOnly(&(cifCurReadStyle->crs_GDSToPort), (char *) &clt))
      {
	labKind = (int) HashGetValue(he);
      }
      else
      {
	labKind = LAB_LOCAL;
      }
    }

    if( layer != cifCurReadStyle->crs_iNameCalmaNum)
    /* Label - place it */
    {
      if (type >= 0)
      {
    	 (void) DBLabelAdd(cifReadCellDef, 
			   &r, 
			   GEO_CENTER, /* -1 would force bbox ref possibly
					* after DBInstanceAdd() but before  
					* corresponding DBChangedArea().
					*/
			   textbody, 
			   type, 
			   labKind);
      }
    }
    else
    /* Instance name - stash it for use when the following SREF is processed */
    {
      gdsNoisyFreeInstanceName();
      gdsInstanceName = StrDup(0,textbody);
    }
}


