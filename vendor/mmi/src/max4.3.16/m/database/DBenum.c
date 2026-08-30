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

/*
 * DBenum.c --
 *
 * Miscellaneous database enumerations (searches) that do not use 
 * Search Context (scx) data structures.
 *
 * See also:
 *
 *  DBsearch.c - main search functions (use Search Context).
 *  DBnext.c   - finding nearby edges, and width changes. 
 *  DBplane.c  - searches involving single tile planes.
 *  Tile1.c    - tile plane primitives. 
 *
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
#include "message.h"
#include "signals.h"


/*
 *-----------------------------------------------------------------------------
 *
 * DBEnumRoots --
 *
 * Apply the supplied procedure to each root CellUse that contains the baseDef
 * either as rootdef or descendent.
 *
 * A root is a CellUse with no parent def.
 *
 * The procedure should be of the following form:
 *	int func(CellUse *rootDef, Transform *transform, ClientData cdarg);
 *
 * Transform is from coordinates of baseDef to those of the def of cellUse.
 * Func normally returns 0.  If it returns 1 then the search is aborted.
 *
 * Results:
 *	0 is returned if the search terminated normally.  1 is returned
 *	if it was aborted.
 *
 * Side effects:
 *	Whatever side effects are brought about by applying the
 *	procedure supplied.
 *
 *-----------------------------------------------------------------------------
 */

int
DBEnumRoots(CellDef *baseDef, 
                     		/* Base CellDef, all of whose ancestors are
				 * searched for.
				 */
	  Transform *transform, 
                         	/* Transform from original baseDef to current
				 * baseDef.
				 */
	  int (*func) (/* ??? */), 
                  		/* Function to apply at each root cellUse */
	  ClientData cdarg)
                     		/* Client data for above function */
{
  register CellUse *parentUse;
  int xoff, yoff, x, y;
  Transform baseToParent, t;
  CellPar *par;

  if (baseDef == (CellDef *) NULL) return 0;
  
  /* root use ? */
  if(!baseDef->cd_pars)
  {
    if ((*func)(baseDef, transform, cdarg)) return 1;
    fprintf(stderr,"DBEnumRoots, TODO, DEBUG: handle rootuse specially.");
    return 0;
  }

  for (par = baseDef->cd_pars; par; par = par->cp_next) 
  {
    CellKid *kid;
    for(kid = par->cp_def->cd_kids; kid; kid = kid->ck_next)
    {
      CellUse *parentUse;
      for (parentUse = kid->ck_uses;  
	   parentUse;
	   parentUse = parentUse->cu_next)
      {
	if (SigInterruptPending) return 1;
	if (!DBCellUseParent(parentUse))
	{
	    GeoTransTrans(transform, &parentUse->cu_transform, &baseToParent);
	    if ((*func)(parentUse, &baseToParent, cdarg)) return 1;
	}
	else
	{
	  if(!DBIsArray(parentUse))
	  {
	    /* non array case */
	    GeoTransTrans(transform, &parentUse->cu_transform, &baseToParent);
	    if (DBEnumRoots(DBCellUseParent(parentUse), 
			    &baseToParent,
			    func, 
			    cdarg)) return 1;
	  }
	  else  
	  {
	    for (x = parentUse->cu_xlo; x <= parentUse->cu_xhi; x++)
	    {
	      for (y = parentUse->cu_ylo; y <= parentUse->cu_yhi; y++)
	      {
		if (SigInterruptPending) return 1;

		xoff = (x - parentUse->cu_xlo) * parentUse->cu_xsep;
		yoff = (y - parentUse->cu_ylo) * parentUse->cu_ysep;
		GeoTranslateTrans(transform, xoff, yoff, &t);
		GeoTransTrans(&t, &parentUse->cu_transform, &baseToParent);
		if (DBEnumRoots(DBCellUseParent(parentUse), 
				&baseToParent,
				func, 
				cdarg)) return 1;
	      } /* y */
	    } /* x */
	  } /* if DBIsArray */
	} /* if */
      } /* parentUse */
    } /* kid */
  } /* par */
  return 0;
}
      

/*
 *-----------------------------------------------------------------------------
 *
 * DBEnumChildren --
 *
 * Apply the supplied procedure once to each CellUse of def.
 *
 * Note differs from DBSrChildren in that this is not an area search and
 * does not use scx.
 * 
 *
 * The procedure should be of the following form:
 *	int
 *	func(use, cdarg)
 *	    CellUse *use;
 *	    ClientData cdarg;
 *	{
 *	}
 *
 * Func returns 0 normally, 1 to abort the search.
 *
 * Results:
 *	0 if search terminated normally, 1 if it aborted.
 *
 * Side effects:
 *	Whatever side effects are brought about by applying the
 *	procedure supplied.
 *
 * TODO: 
 *   This function is OBSOLETE.  Simpler and more efficient to use
 *   kid strucs or cellplane enumeration directly.
 * 
 *-----------------------------------------------------------------------------
 */

int
DBEnumChildren(CellDef *cellDef, 
                     	/* Def whose subcell plane is to be searched */
	   int (*func) (/* ??? */), 
                  	/* Function to apply at every tile found */
	   ClientData cdarg)
                     	/* Argument to pass to function */
{
  CellKid *kid;
  CellUse *use;


  /* read cell in if necessary */
  if (!DBReadCell(cellDef)) return 0;

  /* make sure everything is up-to-date */
  DBUpdate(cellDef);

  for(kid=cellDef->cd_kids; kid; kid=kid->ck_next)
    for(use=kid->ck_uses; use; use=use->cu_next)
      if ((*func)(use, cdarg)) return 1;

  return 0;

}


/*
 * ----------------------------------------------------------------------------
 *
 * DBEnumArrayElements --
 *
 * 	Finds all elements of an array that fall in a particular area
 *	of the parent, and calls func for each element found.
 *
 *	The procedure should be of the following form:
 *	int
 *	func(cellUse, trans, x, y, cdarg)
 *	    CellUse *celluse;
 *	    Transform *trans;
 *	    int x, y;
 *	    ClientData cdarg;
 *	{}
 *
 *	In the above, cellUse is the original cellUse, trans is
 *	a transformation from the coordinates of the cell def to
 *	the coordinates of the use (for this array element), x and
 *	y are the indices of this array element, and cdarg is
 *	the ClientData supplied to us.	If 1 is returned by func,
 *	it is a signal to abort the search.
 *
 * Results:
 *	0 is returned if the search finished normally.  1 is returned
 *	if the search was aborted.
 *
 * Side effects:
 *	Whatever func does.
 *
 * ----------------------------------------------------------------------------
 */

int
DBEnumArrayElements(CellUse *use, 
                 		/* CellUse of array to be searched. */
		    Rect *searchArea, 

                     		/* Area of interest, given in the
				 * coordinates of the parent (i.e. the
				 * cell use, not def).  Must overlap
				 * the array bounding box.
				 */
		    int (*func) (/* ??? */), 
                  		/* Function to apply for each overlapping
				 * array element.
				 */
		    ClientData cdarg)
                     		/* Client-specific info to give to func. */
{
    int xlo, xhi, ylo, yhi, x, y;
    int xsep, ysep, xbase, ybase;
    Transform t;

    DBArrayOverlap(use, searchArea, &xlo, &xhi, &ylo, &yhi);

    /* non-array case */
    if (!DBIsArray(use))
    {
      if ((*func)(use, &use->cu_transform, 0, 0, cdarg)) return 1;
    }
    return 0;

    /* array case */
    if (use->cu_xlo > use->cu_xhi) xsep = -use->cu_xsep;
    else xsep = use->cu_xsep;
    if (use->cu_ylo > use->cu_yhi) ysep = -use->cu_ysep;
    else ysep = use->cu_ysep;
    for (y = ylo; y <= yhi; y++)
	for (x = xlo; x <= xhi; x++)
	{
	    if (SigInterruptPending) return 1;
	    xbase = xsep * (x - use->cu_xlo);
	    ybase = ysep * (y - use->cu_ylo);
	    GeoTransTranslate(xbase, ybase, &use->cu_transform, &t);
	    if ((*func)(use, &t, x, y, cdarg)) return 1;
	}
    return 0;
}


