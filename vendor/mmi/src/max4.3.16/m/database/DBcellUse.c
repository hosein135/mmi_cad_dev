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
 * DBcellUse.c --
 *
 * CellUse creation, deletion.
 *
 * Mostly celluses are for instances, but some are "handles" for cells
 * e.g. toplevel cells in windows, the selection etc.
 *
 * Instances, are created by:
 *   1. creating and setting up a celluse (using funcs in DBcellUse.c),
 *   2. calling DBInstanceAdd() (in DBinstance.c)
 *
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

#include <sys/types.h>
#include <stdio.h>
#include <stdio.h>
#include <string.h>
#include "magic.h"
#include "database.h"
#include "databaseInt.h"
#include "memory.h"
#include "hash.h"
#include "utils.h"
#include "geometry.h"
#include "tile.h"
#include "signals.h"
#include "undo.h"
#include "memory.h"
#include "layout.h"
#include "message.h"
#include "main.h"
#include "ihash.h"
#include "debug.h"


/*
 * ----------------------------------------------------------------------------
 *
 * dbCellUseSetBBox --
 *
 * Compute the bounding box for a CellUse in coordinates of its parent.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *
 *	Sets cellUse->cu_bbox to be the bounding box for the indicated CellUse
 *	in coordinates of that CellUse's parent.
 *
 * ----------------------------------------------------------------------------
 */

void
dbCellUseSetBBox(register CellUse *use, 
		 Rect *result)  /* if non-null, place result here 
				 * and don't change cu_bbox  
				 */
{
    Rect *box;
    Rect childRect;

    box = DBBBoxCellDef(use->cu_def);

    
    if(!DBIsArray(use))
    {
      childRect = *box;
    }
    else
    {

      int xdelta = use->cu_xsep * (use->cu_xhi - use->cu_xlo);
      int ydelta = use->cu_ysep * (use->cu_yhi - use->cu_ylo);

      if (xdelta < 0) xdelta = (-xdelta);
      if (ydelta < 0) ydelta = (-ydelta);

      if (use->cu_xsep < 0)
      {
	childRect.r_xbot = box->r_xbot - xdelta;
	childRect.r_xtop = box->r_xtop;
      }
      else
      {
	childRect.r_xbot = box->r_xbot;
	childRect.r_xtop = box->r_xtop + xdelta;
      }

      if (use->cu_ysep < 0)
      {
	childRect.r_ybot = box->r_ybot - ydelta;
	childRect.r_ytop = box->r_ytop;
      }
      else
      {
	childRect.r_ybot = box->r_ybot;
	childRect.r_ytop = box->r_ytop + ydelta;
      }
    }

    if(result)
    {
      /* return result, leaving celluse bbox alone! */
      GeoTransRect(&use->cu_transform, &childRect, result);
    }
    else  
    {
      /* Can't change bbox while linked into cellPlane */
      ASSERT(!use->cu_bpLinks[0],"dbCellUseSetBBox");

      /* sets celluse bbox */
      GeoTransRect(&use->cu_transform, &childRect, &use->cu_bbox);
    }
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBCellUseSetArray --
 *
 * Copy the array information from fromCellUse to toCellUse
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The array information if toCellUse is modified.
 *
 * ----------------------------------------------------------------------------
 */

void
DBCellUseSetArray(CellUse *fromCellUse, CellUse *toCellUse)
{
  ASSERT(DBIsArray(fromCellUse),"DBCellUseSetArray");
  ASSERT(DBIsArray(toCellUse),"DBCellUseSetArray");

  toCellUse->cu_xlo = fromCellUse->cu_xlo;
  toCellUse->cu_ylo = fromCellUse->cu_ylo;
  toCellUse->cu_xhi = fromCellUse->cu_xhi;
  toCellUse->cu_yhi = fromCellUse->cu_yhi;
  toCellUse->cu_xsep = fromCellUse->cu_xsep;
  toCellUse->cu_ysep = fromCellUse->cu_ysep;
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBCellUseSetTrans --
 *
 * Change the transform for cellUse to that supplied.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	Updates cellUse->cu_trans and cellUse->cu_bbox
 *
 * ----------------------------------------------------------------------------
 */

void
DBCellUseSetTrans(CellUse *cellUse, Transform *trans)
{
    cellUse->cu_transform = *trans;
    dbCellUseSetBBox(cellUse, NULL);
}

/* initial use structure 
 * (common to DBCellUseNew() and DBCellUseNewTemp() below) 
 */
static __inline__ void dbInitUse(CellDef *cellDef, CellUse *cellUse)
{
    cellUse->cu_def = cellDef;

    cellUse->cu_bpLinks[0] = 0; 
    cellUse->cu_bbox.r_xbot = 0;
    cellUse->cu_bbox.r_ybot = 0;
    cellUse->cu_bbox.r_xtop = 1;
    cellUse->cu_bbox.r_ytop = 1;

    cellUse->cu_transform = GeoIdentityTransform;
    cellUse->cu_expandMask = 0;
    cellUse->cu_flags = 0;

    cellUse->cu_kid = (CellKid*) NULL;
    cellUse->cu_next = NULL;
    cellUse->cu_prev = NULL;
    cellUse->cu_client = 0;
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBCellUseNew --
 *
 * Create a new cell use of the supplied CellDef.
 *
 * See also DBCellUseNewArray(), DBCellUseNewTop() and DBCellUseNewTemp()
 *
 * Results:
 *	Returns a pointer to the new CellUse.  The CellUse is initialized
 *	to reflect that cellDef is its definition.  The transform is
 *	initialized to the identity, and the parent pointer initialized
 *	to NULL.
 *
 * Side effects:
 *	Updates the use list for cellDef.
 *
 * ----------------------------------------------------------------------------
 */

CellUse *
DBCellUseNew(CellDef *cellDef, 
                     	/* Pointer to definition of the cell */
	     char *useName)
                  	/* Pointer to use identifier for the cell.  This may
			 * be NULL, in which case a unique use identifier is
			 * generated automatically when the cell use is linked
			 * into a parent def.
			 */
{
    CellUse *cellUse;

    /* note not allocating space for cu_array! */
    MALLOC_TAG(CellUse *, 
	       cellUse, sizeof (CellUse) - sizeof (ArrayInfo),
	       "CellUse");
    dbInitUse(cellDef, cellUse);

    cellUse->cu_id = StrDup((char **) NULL, useName);

    cellDef->cd_refCnt++;
    return (cellUse);
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBCellUseNewArray --
 *
 * Create a new arrayed cell use of the supplied CellDef.
 *
 * See also DBCellUseNewTop() and DBCellUseNewTemp()
 *
 * Results:
 *	Returns a pointer to the new CellUse.  The CellUse is initialized
 *	to reflect that cellDef is its definition.  The transform is
 *	initialized to the identity, and the parent pointer initialized
 *	to NULL.
 *
 * Side effects:
 *	Updates the use list for cellDef.
 *
 * ----------------------------------------------------------------------------
 */

CellUse *
DBCellUseNewArray(CellDef *cellDef, 
		  /* Pointer to definition of the cell */
		  char *useName)
                  	/* Pointer to use identifier for the cell.  This may
			 * be NULL, in which case a unique use identifier is
			 * generated automatically when the cell use is linked
			 * into a parent def.
			 */
{
    CellUse *cellUse;

    MALLOC_TAG(CellUse *, cellUse, sizeof (CellUse),"CellUse");
    dbInitUse(cellDef, cellUse);

    cellUse->cu_id = StrDup((char **) NULL, useName);
    cellUse->cu_flags |= CU_ARRAY;

    cellUse->cu_xlo = 0;
    cellUse->cu_ylo = 0;
    cellUse->cu_xhi = 0;
    cellUse->cu_yhi = 0;
    cellUse->cu_xsep = 0;
    cellUse->cu_ysep = 0;

    cellDef->cd_refCnt++;
    return (cellUse);
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBCellUseNewTop --
 *
 * Create a new cell use of the supplied CellDef.
 *
 * Use the this func for top level uses (uses that do not belong to defs).
 *
 * See also DBCellUseNew() and DBCellUseNewTemp()
 *
 * Results:
 *	Returns a pointer to the new CellUse.  The CellUse is initialized
 *	to reflect that cellDef is its definition.  The transform is
 *	initialized to the identity, and the parent pointer initialized
 *	to NULL.
 *
 * Side effects:
 *	Updates the use list for cellDef.
 *
 * ----------------------------------------------------------------------------
 */

CellUse *
DBCellUseNewTop(CellDef *cellDef, 
                     	/* Pointer to definition of the cell */
	     char *useName)
                  	/* Pointer to use identifier for the cell.  This may
			 * be NULL, in which case a unique use identifier is
			 * generated automatically when the cell use is linked
			 * into a parent def.
			 */
{
    CellUse *cellUse;

    MALLOC_TAG(CellUse *, cellUse, sizeof (CellUse),"CellUse");
    dbInitUse(cellDef, cellUse);

    cellUse->cu_id = StrDup((char **) NULL, useName);

    cellDef->cd_refCnt++;
    return (cellUse);
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBCellUseNewTemp --
 *
 * Initialize a temporary use.  
 *
 * See also DBCellUseNew() and DBCellUseNewTop() 
 *
 * This is bascially a light weight alternative to DBCellUseNew, for use
 * in DBSearch routines to create initial use (handle) from which to start 
 * search.  Avoids Malloc (can be passed a use from stack), and does not
 * inc cd_refCnt list, so DBCellUseDelete() call is not needed. 
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Initializes use. 
 *
 * ----------------------------------------------------------------------------
 */

CellUse *
DBCellUseNewTemp(CellDef *cellDef,
		 CellUse *cellUse)
                     	/* Cell Use to initialize  */
{
    dbInitUse(cellDef, cellUse);
    return cellUse;
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBCellUseNewCopy --
 *
 * Create a new celluse, and initialize from old use.
 *
 * See also DBCellUseNew() etc.
 *
 * Results:
 *	Returns a pointer to the new CellUse.  The CellUse is initialized
 *	to match old.  The parent pointer is initialized to NULL. 
 *
 * Side effects:
 *	Updates the use list for cellDef.
 *
 * ----------------------------------------------------------------------------
 */

CellUse *
DBCellUseNewCopy(CellUse *old,
		   /* Pointer to use to copy */
		 char *id,
		   /* Try to use id for use id.  If NULL,
		    * try to use same id as old.
		    */
		 Transform *t)
		   /* if non-null use this transform instead
		    * of old transform
		    */
{
  CellUse *new;
  CellDef *def = old->cu_def;

  if(!id) id = old->cu_id;
  if(!t) t = &old->cu_transform;


  if(!DBIsArray(old))
  {
    new = DBCellUseNew(def, id);
  }
  else
  {
    new = DBCellUseNewArray(def, id);
    DBCellUseSetArray(old, new);
  }

  DBCellUseSetTrans(new, t);
  new->cu_expandMask = old->cu_expandMask;

  return (new);
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBCellUseDelete --
 *
 * Remove a CellUse.
 * Frees the storage allocated to the CellUse, 
 * Decrements reference count for the def CellUse pointed to.
 *
 * It is required that the CellUse first be removed from the 
 * subcell plane of its parent.  The parent pointer for this
 * CellUse must therefore be NULL.
 *
 * Results:
 *	TRUE if the CellUse was successfully removed, FALSE if
 *	the parent pointer were not NULL.
 *
 * Side effects:
 *	All storage for the CellUse is freed.
 *      The reference cnt of the def pointed to by use is decremented.
 * ----------------------------------------------------------------------------
 */

bool
DBCellUseDelete(CellUse *cellUse)
                     		/* Pointer to CellUse to be deleted */
{
  CellDef *cellDef = cellUse->cu_def;

  if (DBCellUseParent(cellUse)) return (FALSE);

  /* decrement ref cnt */
  ASSERT(cellDef->cd_refCnt, "DBCellUseDelete");
  cellDef->cd_refCnt--;
    
  if (cellUse->cu_id) FREE_TAG(cellUse->cu_id,"char *cu_id");

  /* catch any errant future ref. to use */
  cellUse->cu_id = (char *) NULL;
  cellUse->cu_def = (CellDef *) NULL;

  FREE_TAG((char *) cellUse,"CellUse");
  return (TRUE);
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbCellUseParseArray --
 *
 * Called by DBCellUseFindByPathName() to handle array subscripts.
 *
 * Pulls off the array subscripts starting at 'cp'.
 * checking to ensure that there are the correct number for 'use' and that
 * they are in range.  Store these in scx->scx_x and scx->scx_y, and use them
 * to update scx->scx_trans to be use->cu_trans (as adjusted for the indicated
 * array element) followed by the old value of scx->scx_trans.
 *
 * If defaultSubscripts TRUE, and subscripts not given, default to 
 * minimum values instead of returning error.
 *
 * Results:
 *	Returns TRUE on success, FALSE on error.
 *
 * ----------------------------------------------------------------------------
 */

static bool
dbCellUseParseArray(register char *cp, 
		    CellUse *use, 
		    SearchContext *scx, 
		    bool defaultSubscripts)
{
    int xdelta, ydelta, i1, i2, indexCount;
    Transform trans, trans2;

    if(!DBIsArray(use)) return FALSE;

    /*
     * The transform stuff is a little tricky because if there
     * was only one index given we don't know whether it's the
     * x- or y-index.  Make sure the number of indices specified
     * matches the number of dimensions in an array, and that
     * the indices are in range.
     */
    indexCount = 0;
    if (*cp == '[')
    {
	if (sscanf(cp, "[%d][%d]", &i1, &i2) == 2)
	{
	    indexCount = 2;
	    while (*cp++ != ']') /* Nothing */;
	    while (*cp++ != ']') /* Nothing */;
	}
	else if (sscanf(cp, "[%d,%d]", &i1, &i2) == 2)
	{
	    indexCount = 2;
	    while (*cp++ != ']') /* Nothing */;
	}
	else if (sscanf(cp, "[%d]", &i1) == 1)
	{
	    indexCount = 1;
	    while (*cp++ != ']') /* Nothing */;
	}

	if (indexCount && *cp != '\0' && *cp != '/')
	    return FALSE;
    }

    switch (indexCount)
    {
    case 0:
      if(!defaultSubscripts &&
	 (use->cu_xlo != use->cu_xhi || use->cu_ylo != use->cu_yhi))
	return FALSE;

      scx->scx_x = use->cu_xlo;
      scx->scx_y = use->cu_ylo;
      break;

    case 1:
      if (use->cu_xlo == use->cu_xhi)
      {
	scx->scx_x = use->cu_xlo;
	scx->scx_y = i1;
      }
      else if (use->cu_ylo == use->cu_yhi)
      {
	scx->scx_x = i1;
	scx->scx_y = use->cu_ylo;
      }
      else return FALSE;
      break;

    case 2:
      if (use->cu_xlo == use->cu_xhi || use->cu_ylo == use->cu_yhi)
	return FALSE;
      scx->scx_y = i1;
      scx->scx_x = i2;
      break;
    }

    if (use->cu_xhi > use->cu_xlo)
    {
      if (scx->scx_x < use->cu_xlo || scx->scx_x > use->cu_xhi)
	return FALSE;
      xdelta = use->cu_xsep * (scx->scx_x - use->cu_xlo);
    }
    else
    {
      if (scx->scx_x > use->cu_xlo || scx->scx_x < use->cu_xhi)
	return FALSE;
      xdelta = use->cu_xsep * (use->cu_xlo - scx->scx_x);
    }
    if (use->cu_yhi > use->cu_ylo)
    {
      if (scx->scx_y < use->cu_ylo || scx->scx_y > use->cu_yhi)
	return FALSE;
      ydelta = use->cu_ysep * (scx->scx_y - use->cu_ylo);
    }
    else
    {
      if (scx->scx_y > use->cu_ylo || scx->scx_y < use->cu_yhi)
	return FALSE;
      ydelta = use->cu_ysep * (use->cu_ylo - scx->scx_y);
    }

    GeoTransTranslate(xdelta, ydelta, &use->cu_transform, &trans);
    GeoTransTrans(&trans, &scx->scx_trans, &trans2);
    scx->scx_trans = trans2;
    return TRUE;
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBCellUseFindByPathName --
 *
 * Find CellUse with given hierarchical name.
 *
 * Sets scx to point to result:
 *   scx_use, scx_trans, scx_x, and scx_y set.
 *   
 * If use not found, scx_use is set to NULL.
 *
 * ----------------------------------------------------------------------------
 */

void DBCellUseFindByPathName(char *name, 
		                 /* use path name  
				  * (components separated by spaces)
				  */
			     CellUse *use, 
		                 /* root search here */
			     SearchContext *scx, 
			         /* filled in with result */
			     bool defaultSubscripts,
		                 /* supply default array subscripts */
			     bool noLoad)  
                                 /* Don't auto-load cells */
{
  CellDef *def = use->cu_def;

  scx->scx_use = (CellUse *) NULL;
  scx->scx_trans = GeoIdentityTransform;
  scx->scx_x = scx->scx_y = 0;

  /* special case "." = toplevel use */
  if(name[0]=='.' && name[1]=='\0') goto done;

  while (*name)
  {
    char *end;
    char save;
    
    /* make sure def is loaded */
    if(!noLoad) DBReadCell(def);
    if(!(def->cd_flags & CD_AVAILABLE)) return;

    /* find end of next component in name */
    for(end=name; *end!='\0' && *end!=' '; end++) /* empty */;

    /* lookup */
    save = *end;
    *end = '\0';
    use = IHashLookUp(def->cd_idHash, &name);
    *end = save;

    if(use)
    {
      Transform trans;

      def = use->cu_def;
      GeoTransTrans(&use->cu_transform, &scx->scx_trans, &trans);
      scx->scx_trans = trans;
    }
    else
    if(!use)
    {
      /* try again with any array subscripts stripped */

      for(; end>name && *end!='['; end--) /* empty */;

      /* no subscripts found, give up */
      if(end==name) return;

      /* lookup id with subscripts stripped. */
      *end = '\0';
      use = IHashLookUp(def->cd_idHash, &name);

      *end ='[';

      /* if not found this time, give up */
      if (!use) return;

      def = use->cu_def;

      /* parse subscripts */
      if (!dbCellUseParseArray(end, use, scx, defaultSubscripts)) return;

      /* skip over subscripts (again)  */
      while (*end && *end != ' ') end++;
    }

    /* skip over separator */
    if(*end) end++;

    name = end; 
  }

  /* success */
 done:
  scx->scx_use = use;
}

