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
 * layPoint.c --
 *
 * rountines to get/set "point" (approximately = cursor location) 
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

#include <stdio.h>
#include <string.h>
#include <math.h>
#include <tcl.h>
#include <tk.h>


#include "magic.h"
#include "main.h"
#include "layout.h"
#include "layint.h"
#include "geometry.h"
#include "graphics.h"
#include "styles.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "message.h"
#include "select.h" 
#include "units.h"
#include "utils.h"

/* point defined by X coords (curPointX) 
 * or DB coords (curPointDB) 
 * depending on PointSourceX */

static int curPointSourceX = FALSE;           
static Point curPointX = {0,0};
static Point curPointDB = {0,0};

/*
 *--------------------------------------------------------------
 *
 * layPointSetX --
 *
 *	Invoked on keyboard events to set Point from X coords.
 *
 *  Result:
 *	None
 *
 * Side Effects:      
 *      Sets point to correspond to X cursor. 
 *
 *--------------------------------------------------------------
 */
void 
layPointSetX(int x, int y)
{
    curPointX.p_x = x;
    curPointX.p_y = y;
    curPointSourceX = TRUE;
}

/*
 *--------------------------------------------------------------
 *
 * layPointSetDB --
 *
 *	Invoked via lay_point tcl command to set point to db coordinates.
 *
 *  Result:
 *	None
 *
 * Side Effects:      
 *      Sets point to correspond to X cursor. 
 *
 *--------------------------------------------------------------
 */
void 
layPointSetDB(Point *p)
{
    curPointDB.p_x = p->p_x;
    curPointDB.p_y = p->p_y;
    curPointSourceX = FALSE;
}


/*
 * ----------------------------------------------------------------------------
 *
 *	layPointXToDB --
 *
 *      rootPoint set to nearst DB point.
 *      rootArea  set to one-by-one rect containing point.
 *
 * 	Returns TRUE on success, FALSE if no current layout widget.
 *       
 * ----------------------------------------------------------------------------
 */

static bool
layPointXToDB(Point *p, 
		           /* X point */
		Point *rootPoint, 
		           /* Modified to contain coordinates of point
			    * in root cell coordinates.  Is unchanged
			    * if NULL is returned.
			    */
		Rect *rootArea)
                 	    /* Modified to contain box around point.  Is
			     * unchanged when NULL is returned.
			     */
{
  Point pMax;
  PointFloat pfDB;
   
  if (layCurrent == NULL) return FALSE;

  /* convert from X to Max Pixel coords (Max origin is lower left) */
  pMax.p_x = p->p_x;
  pMax.p_y = layXToPixel(layCurrent,p->p_y);


  layPointWToDBF(layCurrent, pMax.p_x, pMax.p_y, &pfDB);

  if(rootPoint)
  {
    rootPoint->p_x = ROUND(pfDB.pf_x);
    rootPoint->p_y = ROUND(pfDB.pf_y);
  }

  if(rootArea)
  {
    rootArea->r_xbot = floor(pfDB.pf_x);
    rootArea->r_ybot = floor(pfDB.pf_y);
    rootArea->r_xtop = rootArea->r_xbot + 1;
    rootArea->r_ytop = rootArea->r_ybot + 1;
  }

  return TRUE;
}


/*
 * ----------------------------------------------------------------------------
 *	LayPointGet --
 *
 *      rootPoint set to nearst DB point.
 *      rootArea  set to one-by-one rect containing point.
 * 
 *      returns pointer to Layout window containing point. 
 *
 * ----------------------------------------------------------------------------
 */

Layout *
LayPointGet(Point *rootPoint, 
                     		/* Modified to contain coordinates of point
				 * in root cell coordinates.  Is unchanged
				 * if NULL is returned.
				 */
	    Rect *rootArea)

                   		/* Modified to contain box around point.  Is
				 * unchanged when NULL is returned.
				 */
{
    if(curPointSourceX)
    {
        layPointXToDB(&curPointX, rootPoint, rootArea); 
    }
    else
    {
        if(rootPoint != NULL)
	{
   	    rootPoint->p_x = curPointDB.p_x;
	    rootPoint->p_y = curPointDB.p_y;
	}

	if(rootArea != NULL)
	{
	    rootArea->r_xbot  = curPointDB.p_x; 
	    rootArea->r_ybot  = curPointDB.p_y; 
	    rootArea->r_xtop  = curPointDB.p_x+1; 
  	    rootArea->r_ytop  = curPointDB.p_y+1;
	}
    }

    return layCurrent;
}



