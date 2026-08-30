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
 * DBgcell.c --
 *
 * Gcell processing.
 *
 */

#ifndef lint
static char rcsid[] = "$Header$";
#endif  not lint

#include <stdio.h>
#include <string.h>
#include "magic.h"
#include "memory.h"
#include "message.h"
#include "geometry.h"
#include "utils.h"
#include "layout.h"
#include "database.h"
#include "databaseInt.h"


/*
 * ----------------------------------------------------------------------------
 *
 * DBGCellProcessInstances --
 *
 * Expand instances of generated cells and process version mismatches. 
 *
 * Called by calmaParseStructure() and dbReadSections() to process
 * gcell instances of newly read in cell.
 *
 * ----------------------------------------------------------------------------
 */
void
DBGCellProcessInstances(CellDef *cellDef, bool processMismatches)
{
  CellKid *kid;
  CellUse *use;
  CellUse *mismatchs = NULL;

  for(kid = cellDef->cd_kids; kid; kid = kid->ck_next)
  {
    CellDef *subcell = kid->ck_def;
    if(!(subcell->cd_flags&CD_GENERATED)) continue;

    for(use = kid->ck_uses; use; use = use->cu_next)
    {
      DBExpand(use, LAY_ALL_WINDOWS, TRUE); 

      /* using _vDRC since _version is ephemeral: changed to
       * force redisplay.
       * _vDRC should always be version hash for gcells. 
       */
      if(processMismatches && 
	 kid->ck_vDRC.vs_time != subcell->cd_vDRC.vs_time) 
      {
	/* add to list of mismatches */
	use->cu_client = (ClientData) mismatchs;
	mismatchs = use; 
      }
    }
  }

  /* fix mismatches by replacing with saved versions (-_version) */
  while(mismatchs)
  {
    CellUse *oldUse;
    CellUse *newUse;
    CellDef *parent;
    CellDef *savedDef;

    /* pop mismatch list */
    oldUse = mismatchs;
    mismatchs = (CellUse *) oldUse->cu_client;
    oldUse->cu_client = 0; 

    parent = DBCellUseParent(oldUse);

    /* find saved def ( '-_version' ) */
    {
      char name[BUFSIZ];

      /* tack version to name */
      /* using _vDRC since _version is ephemeral: changed to
       * force redisplay.
       * _vDRC should always be version hash for gcells. 
       */
      sprintf(name,"%s!-_version!%d",
	      oldUse->cu_def->cd_name,
	      oldUse->cu_kid->ck_vDRC.vs_time);
      
      savedDef = DBCellLookDef(name);
      if(!savedDef)
      {
	char buf[BUFSIZ];

	/* Only complain if not already referencing a saved version! 
	 *  
	 * This wierd case happens if the hash function changed, e.g. 
	 * we are using a variant technology with a different layer list.
	 */
	if(!StrPropGet(oldUse->cu_def->cd_name,"-_version",buf))
	{
	  MsgErrorF("Saved gcell %s missing from %s\n", name, parent->cd_name);
	}
	continue;
      }
    }
				
    /* setup new use (just like old, except points to savedDef) */
    if(DBIsArray(oldUse))
    {
      newUse = DBCellUseNewArray(savedDef,oldUse->cu_id);
      DBCellUseSetArray(oldUse,newUse);
    }
    else
    {
      newUse = DBCellUseNew(savedDef,oldUse->cu_id);
    }
      
    DBCellUseSetTrans(newUse,&oldUse->cu_transform);
    
    /* delete old instance */
    DBInstanceDelete(oldUse);

    /* add new one */
    DBInstanceAdd(newUse, parent, DBIA_ERROR_ON_RENAME);

    /* expand it */
    DBExpand(newUse, LAY_ALL_WINDOWS, TRUE); 
  }
}








