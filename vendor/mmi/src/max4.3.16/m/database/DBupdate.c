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
 * DBupdate.c --
 *
 * handle bbox and drc version mismatches between instances and the referenced
 * defs.
 */

#include "magic.h"
#include "database.h"
#include "databaseInt.h"
#include "geometry.h"
#include "tile.h"
#include "debug.h"


/*
 * --------------------------------------------------------------------
 *
 * dbUpdateInstanceKid --
 *
 *   Called by DBUpdateInstances to process bbox changes, and redisplay
 *   for one 'kid'
 *
 * --------------------------------------------------------------------
 */
static __inline__ void dbUpdateInstanceKid(CellDef *def, 
					    CellKid *kid,
					    VStamp *now)
{
  Rect newBBox;
  CellUse *use = kid->ck_uses;
  bool bboxUnchanged;
  bool bboxUserUnchanged;

  dbCellUseSetBBox(use,&newBBox);
  bboxUnchanged = GEO_SAMERECT(use->cu_bbox, newBBox);
  
  /* parents need to know descendents changed */
  def->cd_version = *now;
  def->cd_vMAIN = *now;

  /* if instance user bbox changed, mark def for bbox recomputation */
  if(!GEO_SAMERECT(kid->ck_userBBox, use->cu_def->cd_userBBox))
  {
    def->cd_flags |= CD_CHANGED_BBOX;
    kid->ck_userBBox = use->cu_def->cd_userBBox;
  }

  /* process use by use */
  for(use=kid->ck_uses; use; use=use->cu_next)
  {
    if(bboxUnchanged) continue;

    /* redisplay old bbox area */
    LayChangedDef(def, &use->cu_bbox, NULL);
    
    /* compute new bbox */
    dbCellUseSetBBox(use,&newBBox);

    /* mark def for bbox recomputation - if necessary */
    if(!(def->cd_flags&CD_CHANGED_BBOX) &&
       (!GEO_SURROUND_STRONG(&def->cd_bbox, &newBBox) ||
	!GEO_SURROUND_STRONG(&def->cd_bbox, &use->cu_bbox)))
    { 
      def->cd_flags |= CD_CHANGED_BBOX;
    }

    /* need to recheck area of old bbox 
     * (new bbox handled by drc mismatch processing below)
     */
    DRCChangedArea(def, &use->cu_bbox);

    /* reposition instance */
    dbInstanceUnplace(use);
    use->cu_bbox = newBBox;
    dbInstancePlace(use);
  }

  /* update version */
  kid->ck_version = def->cd_version;
}


/*
 * --------------------------------------------------------------------
 *
 * dbUpdateInstances --
 *
 *   Called by DBUpdate1 if descendents have changed. 
 *
 * --------------------------------------------------------------------
 */
static __inline__ void dbUpdateInstances(CellDef *def, VStamp *now)
{
  CellKid *kid;

  /* propagate changes in instances.
   */
  for(kid=def->cd_kids; kid; kid=kid->ck_next)
  {
    CellDef *subcell = kid->ck_def;
    CellUse *use;

    /* recursively update subcell */
    DBUpdate(subcell);

    /* skip subcells that havn't changed */
    if(DBVStampSame(&kid->ck_version,&subcell->cd_version)) continue;

    /* update bboxes for this kid */
    dbUpdateInstanceKid(def,kid,now);

    /* update drc */
    if(!DBVStampSame(&kid->ck_vDRC,&subcell->cd_vDRC))
    {
      for(use=kid->ck_uses; use; use=use->cu_next)
      {
	if(DRCChangedArea(def, &use->cu_bbox)) break;
      }

      kid->ck_vDRC = subcell->cd_vDRC;
    }

    /* update redisplay */
    for(use=kid->ck_uses; use; use=use->cu_next)
    {
      if(LayChangedDef(def, &use->cu_bbox, NULL)) 
      {
	/* terminate loop if no incremental redisplay needed
	 * for this def.
	 */
	break;
      }
    }

    kid->ck_version = subcell->cd_version;
  } 
}



/*
 * --------------------------------------------------------------------
 *
 * DBUpdate1 --
 *
 *   Does the real work for inline DBUpdate().
 *   Make all bboxes in cell tree rooted at def up-to-date
 *   Make drc change areas up-to-date for tree rooted at def
 *
 * --------------------------------------------------------------------
 */

void DBUpdate1(CellDef *def)
{
  VStamp now;
  if (Debug1) fprintf(stderr,"DEBUG DBUpdate1() called on cell=%s\n",
		      def->cd_name);

  /* no interrupts or undo of updates */
  SigDisableInterrupts();
  UndoDisable();

  now = DBVStampNew();
  
  /* If def has invalid stamp
   * force bbox recomputation, and drc of whole cell.
   * (and give valid stamp.)
   */
  if(!DBVStampValid(&def->cd_version))
  {
    def->cd_flags |= (CD_CHANGED_BBOX);
    DRCChangedArea(def, NULL);
    def->cd_version = now;
    def->cd_vMAIN = now;
    def->cd_vDRC = now;

  }

  /* handle changes in instances */
  if(def->cd_flags&CD_CHANGED_INSTANCE) 
  {
    dbUpdateInstances(def,&now); 
    def->cd_flags &= ~CD_CHANGED_INSTANCE;
  }

  /* Recompute bbox of this cell (if necessary) */
  if(def->cd_flags&CD_CHANGED_BBOX)
  {
    Rect oldUserBBox = def->cd_userBBox;
    dbBBoxCellCompute(def);
    def->cd_flags &= ~CD_CHANGED_BBOX;

    /* if user bbox changed, flylines to bbox edges need
     * recomputation.
     */
    if(!GEO_SAMERECT(def->cd_userBBox, oldUserBBox))
    {
      DBFlyLineNotifyLabelChange(def,NULL);
    }
  }

  /* take our hold off interrupts and undo */
  UndoEnable();
  SigEnableInterrupts();

  if (Debug1) fprintf(stderr,"DEBUG DBUpdate1() END, cell=%s\n",
	  def->cd_name);
}


/*
 * --------------------------------------------------------------------
 *
 * DBUpdate0 --
 *
 *   Called by inline DBUpdate() for DEBUG!
 *
 * --------------------------------------------------------------------
 */

void DBUpdate0(CellDef *def)
{

  /* DEBUG */
  fprintf(stderr,"DEBUG DBUpdate0 cell=%s\n",def->cd_name);
  fprintf(stderr,"DEBUG flags=0%o\n",
	  def->cd_flags);
  fprintf(stderr,"DEBUG version = %d %d\n",
	  def->cd_version.vs_time,
	  def->cd_version.vs_rev);

  if(def->cd_version.vs_time == 0 ||
     def->cd_flags &(CD_CHANGED_INSTANCE|CD_CHANGED_BBOX)) DBUpdate1(def);
}
