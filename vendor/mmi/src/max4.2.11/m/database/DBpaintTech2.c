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
 * DBtechpaint2.c --
 *
 * Default composition rules.
 * Pretty complicated, unfortunately, so it's in a separate file.
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
static char rcsid[] = "$Header: DBtpaint2.c,v 6.0 90/08/28 18:10:32 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include <ctype.h>
#include "magic.h"
#include "database.h"
#include "databaseInt.h"
#include "geometry.h"
#include "utils.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "databaseInt.h"
#include "main.h"
#include "message.h"


/* 
 * ----------------------------------------------------------------------------
 *
 * dbTechComponents --
 *
 * Fill in the table that tells for each tile type which
 * other types are "components" of it.
 *
 * Marks a tile type "s" as a component of a type "r" if:
 *	- s and r live on the same plane, and
 *	- the result of painting s on r is still r.
 *
 * Make a second pass and merge the information for all of the
 * images of each contact.  Each type that is a component of a
 * contact's image is also a component of the contact type.
 *
 * ----------------------------------------------------------------------------
 */

Void
dbTechComponents(void)
{
    register TileType image, paint;
    register int n, p;

    /* Components are those types that can be painted without effect */
    for (image = TT_TECHDEPBASE; image < DBNumTypes; image++)
    {
	TTMaskZero(&DBComponentTbl[image]);
	for (paint = TT_TECHDEPBASE; paint < DBNumUserLayers; paint++)
	    if (DBPlane(image) == DBPlane(paint)
		    && DBStdPaintEntry(image, paint, DBPlane(image)) == image)
		TTMaskSetType(&DBComponentTbl[image], paint);
    }
}


/* 
 * ----------------------------------------------------------------------------
 *
 * dbTechComputeSimpleTypes --
 *
 * Fills in the DBIsSimpleType table that tells which types are simple. 
 * 
 * A type is simple if:
 *   painting/erasing it does not effect any other (non space) type, and
 *   painting/erasing any other (non space) type does not effect it.
 *
 * ----------------------------------------------------------------------------
 */

static void 
dbTechComputeSimpleTypes(void)
{
  int type;

  for (type = 0; type < DBNumTypes; type++ )
  {
    int pNum;

    for (pNum = PL_PAINTBASE; pNum < DBNumPlanes; pNum++)
    {
      int other;

      for (other = 0; other < DBNumTypes; other++ )
      {
	if(other == TT_SPACE) continue;
	if(other == type) continue;

	if(DBStdPaintEntry(type,other,pNum) != type) goto not_simple;
	if(DBStdEraseEntry(type,other,pNum) != type) goto not_simple;
	if(DBStdPaintEntry(other,type,pNum) != other) goto not_simple;
	if(DBStdEraseEntry(other,type,pNum) != other) goto not_simple;
      }
    }

    DBIsSimpleType[type] = TRUE;
    continue;

  not_simple:
    DBIsSimpleType[type] = FALSE;
  }
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBTechFinalCompose --
 *
 * Since by the end of this section we've processed all the painting
 * rules, we initialize the tables that say which planes get affected
 * by painting/erasing a given type.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Modifies the paint/erase tables.
 *
 * ----------------------------------------------------------------------------
 */

Void
DBTechFinalCompose(void)
{
    /* Build up exported tables */
    dbTechComponents();
    dbTechComputeSimpleTypes();
}
