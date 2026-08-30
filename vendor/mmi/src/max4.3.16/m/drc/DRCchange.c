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
 * DRCchange.c --
 *
 * Routines in this file are called from DBchange.c to notify drc
 * module of changes in the database that effect the drc.
 *
 */

#include <stdio.h>
#include <magic.h>
#include "debug.h"
#include "drc.h"
#include "drcInt.h"

/* tcl linked variable that controls max number of drc changes before
 * incremental processing is abandoned.
 */
int drcMaxIncremental = 1000;

/*
 * ----------------------------------------------------------------------------
 * DRCChangedArea --
 *
 *	Mark area in def for redrc.
 *
 *      Paints check tile into the DRC_CHECK plane of the cell,
 *	and sets the CD_DRC_PENDING flag.
 *
 *      If too many changes to cell since last time drc looked at
 *      it, gives up on incremental processing (to save change/update)
 *      overhead and sets the CD_DRC_ALL_PENDING flag.
 *
 *      returns:
 *
 *        FALSE - if a DRC_CHECK area was added (incremental processing).
 *        TRUE  - if no check area was added (to signal caller to abort
 *                incremental updates.)
 * 
 *
 * ----------------------------------------------------------------------------
 */
bool
DRCChangedArea(CellDef *def,                 /* def that changed */
	      Rect *area)                    /* area that changed 
					      * NULL = entire cell 
					      */
{
  /* skip internal cells, 
   * cells checked with parents,
   * and cells with DRC_ALL_PENDING
   */
  if(def->cd_flags & (CD_INTERNAL|CD_DRC_WITH_PARENT|CD_DRC_ALL_PENDING)) 
    return TRUE;

  /* DEBUG
  fprintf(stderr,"DEBUG DRCChangedArea: cell=%s, ", def->cd_name);
  if(area) 
  {
    fprintf(stderr,"area=%d %d %d %d\n",
	    area->r_xbot, area->r_ybot, area->r_xtop, area->r_ytop);
  }
  else
  {
    fprintf(stderr,"area=NULL\n");
  }
  */

  def->cd_flags |= CD_DRC_PENDING;

  /* time to drc all? */
  if(!area || ++def->cd_drcNumChanges > drcMaxIncremental)
  {  
    def->cd_flags |= CD_DRC_ALL_PENDING;
    return TRUE;
  }

  /* mark (incremental) change */
  {
    Rect impactArea;

    /* a change in database impacts a larger area */
    GEO_EXPAND(area, TechHalo, &impactArea);
   
    /* don't get interupted! */
    SigDisableInterrupts();
    DBPaintPlane(def->cd_planes[PL_DRC_CHECK], &impactArea,
		 DBStdPaintTbl(TT_CHECKPAINT, PL_DRC_CHECK),
		 (PaintUndoInfo *) NULL);
    SigEnableInterrupts();

    return FALSE;
  }
}

/*
 * ----------------------------------------------------------------------------
 * DRCChangeAddDef --
 *
 *	Call the drc's attention to a def.  (continuous drc will check
 *      for TT_CHECKPAINT areas.
 *
 * ----------------------------------------------------------------------------
 */
void
DRCChangeAddDef(CellDef *def)
{
  /* Don't drc internal cells! */
  if(def->cd_flags & CD_INTERNAL) return;

  /* DEBUG */
  def->cd_flags |= CD_DRC_PENDING;
}
