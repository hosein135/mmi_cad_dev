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
 * DBlabel2.c --
 *
 * pathname search primitives for labels (and uses).
 * (See also DBSearchLabels() and DBSearchLabelsGlob() in DBsearch.c)
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

#ifndef lint
static char rcsid[] = "$Header: DBlabel2.c,v 6.0 90/08/28 18:09:59 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include <string.h>
#include "magic.h"
#include "database.h"
#include "databaseInt.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "databaseInt.h"
#include "malloc.h"


/*
 * ----------------------------------------------------------------------------
 *
 * dbParseArray --
 *
 * Pull off the array subscripts starting at 'cp' (there may be none),
 * checking to ensure that there are the correct number for 'use' and that
 * they are in range.  Store these in scx->scx_x and scx->scx_y, and use them
 * to update scx->scx_trans to be use->cu_trans (as adjusted for the indicated
 * array element) followed by the old value of scx->scx_trans.
 *
 * If defaultSubscripts TRUE, and subscripts not given, default to minimum values
 * instead of returning error.
 *
 * Results:
 *	Returns TRUE on success, FALSE on error.
 *
 * Side effects:
 *	See above.
 *
 * ----------------------------------------------------------------------------
 */

static bool
dbParseArray(register char *cp, 
	     CellUse *use, 
	     SearchContext *scx, 
	     bool defaultSubscripts)
{
    int xdelta, ydelta, i1, i2, indexCount;
    Transform trans, trans2;

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
 * DBTreeFindUse --
 *
 * This procedure finds the cell use with the given hierarchical name.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Sets scx->scx_use to the cell use found, with scx->scx_trans
 *	and scx->scx_x, scx->scx_y also valid.  If the cell was not
 *	found, leaves scx->scx_use set to NULL.
 *
 * ----------------------------------------------------------------------------
 */

void DBTreeFindUse(char *name, 
		   CellUse *use, /* NOTE: modified by routine!? */
		   SearchContext *scx, 
		   bool defaultSubscripts,
		   bool noLoad)  /* if set does not read in cells */       
{
    register char *cp;
    HashEntry *he;
    CellDef *def;
    char csave;

    def = use->cu_def;
    scx->scx_use = (CellUse *) NULL;
    scx->scx_trans = GeoIdentityTransform;
    scx->scx_x = scx->scx_y = 0;

    /* special case "." = toplevel use */
    if(name[0]=='.' && name[1]=='\0') goto done;

    while (*name)
    {
	/*
	 * Make sure that the cell whose children are being searched
	 * is read in from disk.
	 */
	if ((def->cd_flags & CDAVAILABLE) == 0)
	{
	  if(noLoad) return;
	  (void) DBCellRead(def, (char *) NULL, TRUE);
	}

	/*
	 * Pull off the next component of path up to but not including
	 * any array subscripts.
	 */
	for (cp = name; *cp && *cp != '[' && *cp != '/'; cp++)
	    /* Nothing */;
	csave = *cp;
	*cp = '\0';
	he = HashLookOnly(&def->cd_idHash, name);
	*cp = csave;
	if (he == NULL || HashGetValue(he) == NULL)
	    return;
	use = (CellUse *) HashGetValue(he);
	def = use->cu_def;

	/*
	 * Pull off array subscripts and build next stage in transform.
	 * Return NULL if the number of subscripts specified doesn't
	 * match the number that are implied by the array, if use is
	 * an array.
	 */
	if (!dbParseArray(cp, use, scx, defaultSubscripts))
	    return;
	while (*cp && *cp++ != '/')
	    /* Nothing */;
	name = cp;
    }

done:
    scx->scx_use = use;
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBLabelFindByPathName --
 *
 * This procedure finds the locations of all labels with a given
 * hierarchical name.  For each label found, a client-supplied
 * search function is called.  The search function has the form:
 *
 *	int
 *	func(scx, rect, name, label, cdarg)
 *          SearchContext *scx;
 *	    Rect *rect;
 *	    char *name;
 *	    Label *label;
 *	    ClientData cdarg;
 *
 * Rect is the location of the label, in the coordinates of rootUse->cu_def,
 * name is the label's hierarchical name (just the parameter passed to us),
 * label is a pointer to the label, and cdarg is the client data passed in
 * to us by the client.  Note that there can be more than one label with the
 * same name.  Func should normally return 0.  If it returns 1, then the
 * search is aborted.
 *
 * Results:
 *	The return value is 0, unless func returned a non-zero value,
 *	in which case the return value is 1.
 *
 * Side effects:
 *	Whatever the search function does.
 *
 * ----------------------------------------------------------------------------
 */

int
DBLabelFindByPathName(CellUse *rootUse, 
                     	/* Cell in which to search. */
	     char *name, 
               		/* A hierarchical label name consisting of zero or more
			 * use-ids followed by a label name (fields separated
			 * with slashes).
			 */
	     int (*func) (SearchContext *scx, 
			  Rect *rect, 
			  char *name, 
			  Label *label, 
			  ClientData cdarg), 
                  	/* Applied to each instance of the label name */
	     ClientData cdarg,
                     	/* Data to pass through to (*func)() */
	     bool noLoad) /* if set don't read in cells */ 
{
    CellDef *def;
    SearchContext scx;
    register char *cp;
    register Label *lab;
    char csave;
    Rect r;

    if (cp = strrchr(name, '/'))
    {
	csave = *cp;
	*cp = '\0';
	DBTreeFindUse(name, 
		      rootUse, 
		      &scx, 
		      FALSE, /* require subscripts on arrays */
		      noLoad);
	*cp = csave;
	if (scx.scx_use == NULL)
	    return 0;
	cp++;
    }
    else
    {
	scx.scx_use = rootUse;
	scx.scx_trans = GeoIdentityTransform;
	cp = name;
    }

    /* handle special names */
    if(cp[0] == '{' && cp[1] == '*')
    {
      if(strcmp(cp,"{*center*}") == 0)
      {
	def = scx.scx_use->cu_def;
        GeoTransRect(&scx.scx_trans, &def->cd_bbox, &r);
        if ((*func)(&scx, &r, name, NULL, cdarg)) return 1;
        return 0;
      }
      if(strcmp(cp,"{*left*}") == 0)
      {
	Rect tmp;

	def = scx.scx_use->cu_def;
	tmp.r_xbot = tmp.r_xtop = def->cd_bbox.r_xbot;
	tmp.r_ybot = def->cd_bbox.r_ybot;
	tmp.r_ytop = def->cd_bbox.r_ytop;

        GeoTransRect(&scx.scx_trans, &tmp, &r);
        if ((*func)(&scx, &r, name, NULL, cdarg)) return 1;
        return 0;
      }
      if(strcmp(cp,"{*right*}") == 0)
      {
	Rect tmp;

	def = scx.scx_use->cu_def;
	tmp.r_xbot = tmp.r_xtop = def->cd_bbox.r_xtop;
	tmp.r_ybot = def->cd_bbox.r_ybot;
	tmp.r_ytop = def->cd_bbox.r_ytop;

        GeoTransRect(&scx.scx_trans, &tmp, &r);
        if ((*func)(&scx, &r, name, NULL, cdarg)) return 1;
        return 0;
      }
      if(strcmp(cp,"{*bottom*}") == 0)
      {
	Rect tmp;

	def = scx.scx_use->cu_def;
	tmp.r_xbot = def->cd_bbox.r_xbot;
	tmp.r_xtop = def->cd_bbox.r_xtop;
	tmp.r_ybot = tmp.r_ytop = def->cd_bbox.r_ybot;

        GeoTransRect(&scx.scx_trans, &tmp, &r);
        if ((*func)(&scx, &r, name, NULL, cdarg)) return 1;
        return 0;
      }
      if(strcmp(cp,"{*top*}") == 0)
      {
	Rect tmp;

	def = scx.scx_use->cu_def;
	tmp.r_xbot = def->cd_bbox.r_xbot;
	tmp.r_xtop = def->cd_bbox.r_xtop;
	tmp.r_ybot = tmp.r_ytop = def->cd_bbox.r_ytop;

        GeoTransRect(&scx.scx_trans, &tmp, &r);
        if ((*func)(&scx, &r, name, NULL, cdarg)) return 1;
        return 0;
      }
    }

    /* Ensure that the leaf cell is read in */
    def = scx.scx_use->cu_def;
    if ((def->cd_flags & CDAVAILABLE) == 0)
    {
      if(noLoad) return 0;
      (void) DBCellRead(def, (char *) NULL, TRUE);
    }

    for(lab = IHashLookUp(def->cd_labelHash,cp);
	lab;
	lab = IHashLookUpNext(def->cd_labelHash,lab))
    {
      GeoTransRect(&scx.scx_trans, &lab->lab_rect, &r);
      if ((*func)(&scx, &r, name, lab, cdarg)) return 1;
    }

    return 0;
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBLabelFindByPathNameDef --
 *
 * Just like DBSrlabelLoc() except first arg is def not use!
 *
 * This procedure finds the locations of all labels with a given
 * hierarchical name.  For each label found, a client-supplied
 * search function is called.  The search function has the form:
 *
 *	int
 *	func(scx, rect, name, label, cdarg)
 *          SearchContext *scx;
 *	    Rect *rect;
 *	    char *name;
 *	    Label *label;
 *	    ClientData cdarg;
 *
 * Rect is the location of the label, in the coordinates of rootUse->cu_def,
 * name is the label's hierarchical name (just the parameter passed to us),
 * label is a pointer to the label, and cdarg is the client data passed in
 * to us by the client.  Note that there can be more than one label with the
 * same name.  Func should normally return 0.  If it returns 1, then the
 * search is aborted.
 *
 * Results:
 *	The return value is 0, unless func returned a non-zero value,
 *	in which case the return value is 1.
 *
 * Side effects:
 *	Whatever the search function does.
 *
 * ----------------------------------------------------------------------------
 */

int
DBLabelFindByPathNameDef(CellDef *rootDef, 
                     	/* Cell in which to search. */
		char *name, 
               		/* A hierarchical label name consisting of zero or more
			 * use-ids followed by a label name (fields separated
			 * with slashes).
			 */
		int (*func) (SearchContext *scx, 
			     Rect *rect, 
			     char *name, 
			     Label *label, 
			     ClientData cdarg), 
		        /* Applied to each instance of the label name */
		ClientData cdarg,
                     	/* Data to pass through to (*func)() */
		bool noLoad) /* if set don't read in cells */ 
{
  CellUse tempUse;
  CellUse *use = rootDef->cd_uses;

  /* if no use setup a temporary one */ 
  if(!use) 
  {
    DBCellInitTempUse(rootDef, &tempUse);
    use = &tempUse;
  }

  return DBLabelFindByPathName(use, name, func, cdarg, noLoad);
}


