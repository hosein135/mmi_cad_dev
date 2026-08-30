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
 * DBpolygon.c --
 *
 * non-orthogonal geometries
 *
 * for geometric operations on poygons, see DBpolygon2.c 
 *
 */

#ifndef lint
static char rcsid[] = "$Header$";
#endif  not lint

#include <stdio.h>
#include <string.h>
#include "magic.h"
#include "database.h"
#include "databaseInt.h"
#include "malloc.h"
#include "message.h"
#include "geometry.h"
#include "utils.h"
#include "layout.h"

/* size 2 "polygons" are full arcs inscribed inside bbox of the two points */
/*
 * ----------------------------------------------------------------------------
 *
 * DBPolyNew --
 *
 * Create new polygon.  
 * If def is not null, links polygon into def.
 * if def non-null, and not part of wirepath (notifies undo)
 *
 * Returns:
 *      pointer to new polygon  
 *
 * Side effects:
 *	Calls the undo package.
 *
 * NOTE: points array will be FREEd when polygon is deleted!
 *
 * ----------------------------------------------------------------------------
 */
Polygon *DBPolyNew(CellDef *def,  
		                    /* if null, polygon created but not linked
				     * into any def.
				     */
		   TileType type,
		   int size,  
		   PointFloat *points,
		   WirePath *wp,    /* NULL for independent polygons */
		   bool notify)  
                        /* if set notify redisplay etc., 
			 * if not set, notify must be done by caller.
			 */
{
  Polygon *poly;
  int i;
  
  /* polygon */
  MALLOC_TAG(Polygon *, poly, sizeof(Polygon),"Polygon");
  poly->poly_client = (ClientData) -1;
  poly->poly_type = type;
  poly->poly_bbox = *DBPointsFBBox(size,points);
/*
  DBPointsFDump("DEBUG DBPolyNew points = ", size, points);
  DumpRect("DEBUG DBPolyNew bbox = ", &poly->poly_bbox);
*/
  poly->poly_size = size;
  poly->poly_points = points;
  poly->poly_wirePath = wp; 

  /* if no def, don't link into celldef */
  if(!def)
  {
    poly->poly_group = NULL;
    poly->poly_next = NULL;
    return poly;
  }

  /* new stuff "always" added to defs activeGroup */
  poly->poly_group = def->cd_activeGroup;

  /* link polygon into def */
  poly->poly_next =  def->cd_polygons;
  def->cd_polygons = poly;
  if(!wp) DBUndoAddPoly(def,poly);

  /* change notification */
  if(notify)
  {
    TileTypeBitMask mask;

    TTMaskZero(&mask);
    TTMaskSetType(&mask, poly->poly_type);
    DBChangedArea(def, &poly->poly_bbox, &mask, DBCF_POLYGON);
  }

  return poly;
}

/*
 * ----------------------------------------------------------------------------
 *
 * DBPolyDelete --
 *
 * Delete polygon.  
 * If def is not null, unlinks polygon from def.
 * if def non null (and not part of wirepath) undo is notified.
 *
 * NOTE: frees polygons point array. 
 *
 * ----------------------------------------------------------------------------
 */
void DBPolyDelete(CellDef *def, 
		  Polygon *poly,
		  bool notify)
                        /* if set notify redisplay etc. */
{
  Polygon *cur;
  Polygon **prevPointer;

  /* handle unlinked polygons separately */
  if(!def)
  {
    ASSERT(poly->poly_next == NULL, "DBPolyDelete");
    ASSERT(!notify, "DBPolyDelete");

    DBPointsFFree(poly->poly_points);
    FREE_TAG((char *) poly,"Polygon");
    return;
  }

  /* locate polygon in def list */
  cur = def->cd_polygons;
  prevPointer = &def->cd_polygons;
  while(cur && cur!= poly)
  {
    prevPointer = &cur->poly_next;
    cur = cur->poly_next;
  }

  /* unlink and free it */
  if(cur) 
  {
    if(!poly->poly_wirePath) DBUndoDeletePoly(def, poly);

    if(notify)
    {
      TileTypeBitMask mask;

      TTMaskZero(&mask);
      TTMaskSetType(&mask, poly->poly_type);
      DBChangedArea(def, &poly->poly_bbox, &mask, DBCF_POLYGON);
    }

    /* free polygon */
    *prevPointer = poly->poly_next;
    DBPointsFFree(poly->poly_points);
    FREE_TAG(poly, "Polygon");
  }
}

/* delete all polygons in cell def */
void DBPolyClear(CellDef *def)
{
  while(def->cd_polygons)
  {
    DBPolyDelete(def, def->cd_polygons, FALSE);
  }
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbPolyWrite --
 *
 * write polygons to .max file
 *
 * Results:
 *	Normally returns TRUE; returns FALSE on I/O error.
 *
 * Side effects:
 *	Writes to the disk file.
 *
 * ----------------------------------------------------------------------------
 */

#define OUTS(s)\
{\
     if (fputs(s,f) == EOF) goto ioerror;\
     DBFileOffset += strlen(s);\
}

bool
dbPolyWrite(CellDef *def, FILE *f)
{
    char buf[1000];
    register Polygon *poly;
    
    for (poly = def->cd_polygons; poly; poly = poly->poly_next)
    {
      int i;
      int size = poly->poly_size;

      /* don't write out dependent polygons */
      if(poly->poly_wirePath) continue;

      sprintf(buf, "poly %s %d {\n",
	      DBTypeLongName(poly->poly_type),
	      size);
      OUTS(buf);

      for(i=0; i<size; i++)
      {
        sprintf(buf, "\t%g %g\n",
	      poly->poly_points[i].pf_x,
	      poly->poly_points[i].pf_y);
	OUTS(buf);
      }

      OUTS("\t}\n");
    }
    return TRUE;

ioerror:
    return FALSE;
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbPolyRead --
 *
 * Starting with the line "SECTION POLYGONS {", read the POLYGONS section.
 *
 * Results:
 *	Returns TRUE normally, or FALSE on error or EOF.
 *
 * Side effects:
 *	See above.
 *
 * ----------------------------------------------------------------------------
 */

/* helper func - reads one polygon */
static __inline__ bool
dbPolyRead1(CellDef *def, 
                     	/* Cell being read */
	     char *lineBuf, 
               		/* Line buffer */
	     int bufSize, 
            		/* Size of lineBuf */	     
	     FILE *f)
            		/* Input file */
{
    char layerName[50];
    TileType type;
    int size, i;
    PointFloat *points;

    /* read "poly" line */
    if (sscanf(lineBuf, "poly %49s %d {", layerName, &size) != 2)
    {
	MsgErrorF("Bad poly line: '%s'\n", lineBuf);
	return FALSE;
    }

    /* lookup type */
    type = DBTechNameType(layerName);
    if (type < 0)
    {
      MsgErrorF("Unknown type %s\n",layerName);
      return FALSE;
    }

    if (size < 2)
    {
      MsgErrorF("Bad poly size:  %d\n",size);
      return FALSE;
    }

    /* read points (path) */
    points = DBPointsFAlloc(size, NULL, NULL);
    for(i=0; i<size; i++)
    {
      if (!dbReadNextLine(lineBuf, bufSize, f)) 
      {
	FREE(points);
	return FALSE;
      }
      
      if(sscanf(lineBuf, "%lf %lf", &points[i].pf_x, &points[i].pf_y) != 2)
      {
	MsgErrorF("Bad poly point: '%s'\n", lineBuf);
	return FALSE;
      }

      /* scale to internal DB coords */
      GeoScalePointF(&points[i], dbRdScaleFile2DB, &dbRdScaleFile2DBErr);
    }
    
    /* read closing brace line */
    if (!dbReadNextLine(lineBuf, bufSize, f)) 
    {
      FREE(points);
      return FALSE;
    }

    /* create new polygon */
    DBPolyNew(def, type, size, points, NULL /* independent */, FALSE);
    return TRUE;
}

bool
dbPolyRead(CellDef *cellDef, 
                     	/* Cell whose groups are being read */
	     char *lineBuf, 
               		/* Line buffer */
	     int bufSize, 
            		/* Size of lineBuf */	     
	     FILE *f)
            		/* Input file */
{
    while (dbReadNextLine(lineBuf, bufSize, f))
    {

        if (lineBuf[0]== '}' && 
	    strcmp(lineBuf,"} SECTION POLYGONS\n") == 0) return TRUE;
        if(!dbPolyRead1(cellDef, lineBuf, bufSize, f)) return FALSE;
    }
    return (FALSE);
}

/* copy polygon into def */
/*
 * ----------------------------------------------------------------------------
 *
 * DBPolygonCopy --
 *
 * Copy polygon. 
 * If def is not null, links polygon into def.
 * If trans, not null, transforms polygon while copying.
 *
 * Returns:
 *      pointer to new polygon  
 *
 * Side effects:
 *	Notifys undo package (if polygon is linked into def)
 *
 * ----------------------------------------------------------------------------
 */
Polygon *DBPolygonCopy(Polygon *poly, 
		       CellDef *def,
		       Transform *trans) 
{
  Polygon *new;
  PointFloat *newPoints;
  int i;
  int size = poly->poly_size;

  newPoints = DBPointsFAlloc(size,poly->poly_points,trans);

  /* create (and return) dest polygon */
  new = DBPolyNew(def, 
		  poly->poly_type,
		  size,
		  newPoints,
		  NULL,    /* independent polygon */
		  FALSE);  /* don't do notify */

  /* preserve wirePath field for selection code */
  new->poly_wirePath = poly->poly_wirePath;

  return new;
} 

/*
 * ----------------------------------------------------------------------------
 *
 * DBPolygonsCopy --
 *
 * Copy independent polygons in srcDef to destDef  

 * Side effects:
 *	Notifys undo package.
 *
 * ----------------------------------------------------------------------------
 */
void DBPolygonsCopy(CellDef *srcDef, CellDef *destDef, Transform *trans)
{
  Polygon *poly;

  for (poly = srcDef->cd_polygons; poly; poly=poly->poly_next)
  {
    if(poly->poly_wirePath) continue;
    DBPolygonCopy(poly, destDef, trans);
  }
}

/*
 *-----------------------------------------------------------------------------
 *
 * DBPolyFind --
 *
 * Find polygon in def matching the given specification
 *	
 * Returns pointer to matching Polygon (NULL if none found).
 *
 *-----------------------------------------------------------------------------
 */ 
Polygon *DBPolyFind(CellDef *def,   /* def to search */
		    TileType type, 
		    Group *group,
		    int size,  
		    PointFloat *points,
                    WirePath *wp,
                    Transform *trans) /* if not NULL, transform from points to def */
{
  Polygon *poly;
  int i;

  if(trans)
  {
    for (poly=def->cd_polygons; poly; poly=poly->poly_next)
    {

      if(poly->poly_type != poly->poly_type) continue;
      if(poly->poly_size != poly->poly_size) continue;

      for(i=0;i<size;i++)
      {
	PointFloat pf;

	GeoTransPointF(trans,&points[i],&pf);
	if(!GEO_SAMEPOINTF(pf,poly->poly_points[i])) break;
      }
      
      if(i==size) return poly;
    }
  }
  else
  {
    for (poly=def->cd_polygons; poly; poly=poly->poly_next)
    {

      if(poly->poly_type != poly->poly_type) continue;
      if(poly->poly_size != poly->poly_size) continue;

      for(i=0;i<size;i++)
      {
	if(!GEO_SAMEPOINTF(points[i],poly->poly_points[i])) break;
      }

      if(i==size) return poly;
    }
  } 

  return NULL;
}











