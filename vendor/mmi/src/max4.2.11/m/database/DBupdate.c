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
  CellKid *kid;
  CellUse *use;
  VStamp now;


  if (Debug1) fprintf(stderr,"DEBUG DBUpdate1() called on cell=%s\n",
		      def->cd_name);

  /* no interrupts or undo of updates */
  SigDisableInterrupts();
  UndoDisable();

  now = DBVStampNew();

  /* If def has zero BBOX version, force bbox recomputation, 
   * and give valid stamp.
   */
  if(!DBVStampValid(&def->cd_vBBOX))
  {
    def->cd_flags |= CD_BBOX_BAD;
    def->cd_vBBOX = now;
  }

  /* If def has zero MAIN version give valid stamp */ 
  if(!DBVStampValid(&def->cd_vMAIN))
  {
    def->cd_vMAIN = now;
  }

  /* If def has zero DRC version, force drc of whole cell,
   * and give valid stamp
   */
  if(!DBVStampValid(&def->cd_vDRC))
  {
    def->cd_flags |= CD_DRC_ALL;
    def->cd_vDRC = now;
  }

  /* handle changes in instances */
  if(def->cd_changes&(DBC_BBOX | DBC_DRC | DBC_DISPLAY))
  {

    /* recursively update children */
    for(kid=def->cd_kids; kid; kid=kid->ck_next)
    {
      DBUpdate(kid->ck_def);
    }

    /* update use info:
     * bboxes in def 
     * drc check propagation
     * redisplay due to changes in descendents 
     * version stamp updates
     */
    for(kid=def->cd_kids; kid; kid=kid->ck_next)
    {
      CellDef *subcell = kid->ck_def;

      for(use=kid->ck_sibUses; use; use=use->cu_nextSib)
      {

	/*** HANDLE MAIN VERSION MISMATCHES ***/
	if(!DBVStampSame(&use->cu_vMAIN,&subcell->cd_vMAIN))
	{
	  def->cd_vMAIN = now;
	  use->cu_vMAIN = subcell->cd_vMAIN;
	}

	/*** HANDLE BBOX VERSION MISMATCHES ***/
	if(!DBVStampSame(&use->cu_vBBOX,&subcell->cd_vBBOX))
        {
	  Rect newBBox;

	  /* compute new bbox */
	  dbCellUseComputeBBox(use,&newBBox);

	  /* bbox actually changed? */ 
	  if(!GEO_SAMERECT(use->cu_bbox, newBBox))
	  {
	    /* mark def for bbox recomputation - if necessary */
	    if(!(def->cd_flags&CD_BBOX_BAD) &&
	       (!GEO_SURROUND_STRONG(&def->cd_bbox, &newBBox) ||
		!GEO_SURROUND_STRONG(&def->cd_bbox, &use->cu_bbox)))
  	    { 
	      def->cd_flags |= CD_BBOX_BAD;
	      def->cd_vBBOX = now;
	    }

	    /* need to recheck area of old bbox 
	     * (new bbox handled by drc mismatch processing below)
	     */
	    DRCChangedArea(def, &use->cu_bbox);
            def->cd_vDRC = now;

	    /* need to redisplay area of old bbox 
	     * (new bbox handled by display mismatch processing below)
	     */
	    LayChangedDef(def, &use->cu_bbox, NULL);
            def->cd_vDISPLAY = now;

	    /* reposition instance */
	    DBInstanceUnplace(use);
	    use->cu_bbox = newBBox;
	    DBInstancePlace(use, def);
	  }
	  use->cu_vBBOX = subcell->cd_vBBOX;
	}

	/*** HANDLE DRC VERSION MISMATCHES ***/
	if(!DBVStampSame(&use->cu_vDRC,&subcell->cd_vDRC))
        {
	  DRCChangedArea(def, &use->cu_bbox);
	  def->cd_vDRC = now;
	  use->cu_vDRC = subcell->cd_vDRC;
	}

	/*** HANDLE DISPLAY VERSION MISMATCHES ***/
	if(!DBVStampSame(&use->cu_vDISPLAY,&subcell->cd_vDISPLAY))
        {
	  LayChangedDef(def, &use->cu_bbox, NULL);
	  def->cd_vDISPLAY = now;
	  use->cu_vDISPLAY = subcell->cd_vDISPLAY;
	}
      }  /* for kid uses */
    } /* for kids */

    /* all changes to descendents have been processed, so clear change flags */
    def->cd_changes = 0;
  }

  /* Recompute bbox of this cell (if necessary) */
  if(def->cd_flags&CD_BBOX_BAD)
  {
     dbBBoxCellCompute(def);
     def->cd_flags &= ~CD_BBOX_BAD;
  }

  /* now that we have a valid bbox, handle  DRC_ALL case */
  if(def->cd_flags&CD_DRC_ALL)
  {
    DRCChangedArea(def, &def->cd_bbox);
    def->cd_flags &= ~CD_DRC_ALL;
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
  fprintf(stderr,"DEBUG changes=0%o, flags=0%o\n",
	  def->cd_changes,
	  def->cd_flags);
  fprintf(stderr,"DEBUG vs times: main=%d, drc=%d bbox=%d display=%d\n",
	  def->cd_vMAIN.vs_time,
	  def->cd_vDRC.vs_time,
	  def->cd_vBBOX.vs_time,
	  def->cd_vDISPLAY.vs_time);

  ASSERT(!def->cd_changesPending,"DBUpdate1");
  if(def->cd_changes & (DBC_MAIN|DBC_DRC|DBC_BBOX|DBC_DISPLAY) ||
     def->cd_vMAIN.vs_time == 0 ||
     def->cd_vDRC.vs_time == 0 ||
     def->cd_vBBOX.vs_time == 0 ||
     def->cd_vDISPLAY.vs_time == 0 ||
     def->cd_flags &(CD_BBOX_BAD|CD_DRC_ALL)) DBUpdate1(def);
}
