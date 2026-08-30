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
 * DBchange.c --
 *
 * Handles bookkeeping for database changes 
 * .e.g. notifys layout module what needs to be redisplayed,
 *       notifys drc module what needs to be rechecked.
 *       propagates bounding box changes up hierarchy.
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

#include "magic.h"
#include "database.h"
#include "databaseInt.h"
#include "layout.h"
#include "debug.h"

/* last time the database changed */
VStamp DBChangeLast = {0,0};


/*
 * --------------------------------------------------------------------
 *
 * dbChangePropagate --
 *
 * propagate change info up cell hierarchy.
 * (does not modify cd_changes in toplevel def)
 *
 *
 *
 * --------------------------------------------------------------------
 */

static void
dbChangePropagate(CellDef *def,             /* def to propagate from */
		  int changes)              /* types of changes */

{
  CellPar *cellpar;


  /*
  fprintf(stderr,"DEBUG dbChangePropagate.  cell=%s  changes=%d\n",
	  def->cd_name, changes);
  */

  /* only need to propagate new changes */
  changes &= ~def->cd_changes;
  if(!changes) return;

  /* propagate new changes through parents */
  for(cellpar = def->cd_pars; cellpar; cellpar=cellpar->cp_next)
  {
    CellDef *parent =cellpar->cp_def;

    dbChangePropagate(parent, changes);

    /* notify layout module of need for redisplay in windows 
     * containing parent def (as root def) */
    if(changes&DBC_DISPLAY && !parent->cd_changes&DBC_DISPLAY) 
    {
      LayChangedScheduleDef(parent);
    }

    cellpar->cp_def->cd_changes |= changes;
  }
}


/*
 * --------------------------------------------------------------------
 *
 * DBChangedArea --
 *
 * Handle all the bookkeeping necessary when a change has been made
 * to the database, including:
 *
 * redisplay scheduling   
 * drc notification
 * keeping bounding box info up to date.
 *
 * --------------------------------------------------------------------
 */

void
DBChangedArea(CellDef *def,                 /* def that changed */
	      Rect *area,                   /* area that changed 
					     * NULL = entire cell 
					     */
	      TileTypeBitMask *layers,      /* layers that changed  
					     * NULL = all+labels
					     */
	      int flags)                    /* as needed :-) */
{
  bool internal = def->cd_flags & CDINTERNAL;
  int changes = 0;
  bool defRead = flags & DBCF_DEFREAD;
  bool noDRC = flags & DBCF_NODRC;
  VStamp now;
  now = DBVStampNew();

  if(Debug1) fprintf(stderr,"DEBUG dbChangedArea.  cell=%s TOP\n",
	  def->cd_name);

  /* update last change stamp */ 
  DBChangeLast = now;

  /* if display flag set, skip main/drc/bbox stuff. */
  if(flags & DBCF_DISPLAY) goto display;

  /* if drc error flag set, skip main/drc stuff */
  if(flags & DBCF_DRC_ERROR) goto bbox;

  /* Mark cell as modified */
  if(!defRead) def->cd_flags |= CDMODIFIED;

  /* main */
  if(!defRead || !DBVStampValid(&def->cd_vDRC))  
  {
    changes |= DBC_MAIN;
    def->cd_vMAIN = now;
  }

  /* drc */
  if(noDRC)
  {
    def->cd_vDRC = DBVStampFixed;
  }
  else
  {
    if(defRead) DRCChangeAddDef(def);
    if(!defRead || !DBVStampValid(&def->cd_vDRC))  
    {
      if(!internal &&
	 (layers== NULL || TTMaskIntersect(layers, &DBAllButSpaceAndDRCBits)))
      {
	changes |= DBC_DRC;
	def->cd_vDRC = now;

	DRCChangedArea(def, area);
	/* Note DRC will be notified of change in parents at update time */
      }
    }
  }

bbox:
  /* bbox 
   * NOTE: this is one of only a few places outside of DBbbox.c where
   *       cd_bbox should be referenced directly, normally should
   *       use DBBBoxCellUse() to ensure up-to-date version.
   */
  if(!defRead && 
     !(def->cd_flags & CD_BBOX_BAD) && 
     (!area || !GEO_SURROUND_STRONG(&def->cd_bbox, area)))
  { 
    def->cd_vBBOX = now;
    def->cd_flags |= CD_BBOX_BAD;
    changes |= DBC_BBOX;
  }

  /* coarse paint plane database */
  /* TODO would be nice if we wouldn't recompute coarse db everytime
   * an instance has been added/deleted/moved.
   */
  if(def->cd_coarseDB) LayCoarseChange(def, area);

display:
  changes |= DBC_DISPLAY;
  def->cd_vDISPLAY = now;
  LayChangedDef(def, area, layers); 

  /* if def just read in, preexisting instances of def may have inconsistent
   * versions, so  propagate full set of change flags to force version
   * check.
   */
  if(defRead) changes |= (DBC_MAIN|DBC_DRC|DBC_BBOX|DBC_DISPLAY);
   
  /* set change flags up the hierarchy 
   * (but not in this def change flags are hints that descendents
   *  may be inconsistent)
   *
   * propagating changes from this call to DBChangedArea()  
   *  + 
   * changesPending from version inconsistencies for instances added to this cell 
   * (reported by calls toDBChangeNewInstance()) since last call to DBChangedArea()
   * for this def.
   */
  dbChangePropagate(def, changes|def->cd_changesPending);

  /* flag changesPending for this def and clear changesPending */
  def->cd_changes |= def->cd_changesPending;
  def->cd_changesPending = 0;

  /* DEBUG
  if(Debug1) fprintf(stderr,"DEBUG dbChangedArea.  cell=%s BOT\n",
	  def->cd_name);
  */
}


/*
 * --------------------------------------------------------------------
 *
 * DBChangeNewInstance --
 *
 * Called by DBInstanceAdd()
 *
 * Checks versions on new instance and sets cd_changesPending in
 * parent as required (to be propagated on next DBChangedArea())
 *
 * Assumes DBChangedArea() will be called on the 
 * area including the instance!
 *
 * --------------------------------------------------------------------
 */
void DBChangeNewInstance(CellUse *use)
{
  CellDef *def = use->cu_def;
  CellDef *parent = use->cu_parent;
  int OldChanges = parent->cd_changes | parent->cd_changesPending;
  int changes = 0;

/*  
   fprintf(stderr,"DEBUG DBChangeNewInstance() parent=%s subcell=%s\n",
	  use->cu_parent->cd_name, use->cu_def->cd_name); 
*/

  /* if subcell def is not in memory, nothing to be inconsistent with */
  if(!(def->cd_flags & CDAVAILABLE)) return; 

  /* add changes due to MAIN version inconsistency */
  if(!(OldChanges&DBC_MAIN) && 
     !DBVStampSame(&def->cd_vMAIN,&use->cu_vMAIN))
  {
    parent->cd_changesPending |= DBC_MAIN;
  }

  /* add changes due to DRC version inconsistency */
  if(!(OldChanges&DBC_DRC) && 
     !(parent->cd_flags&CDINTERNAL) &&
     !DBVStampSame(&def->cd_vDRC,&use->cu_vDRC))
  {
    parent->cd_changesPending |= DBC_DRC;
  }

  /* add changes due to BBOX version inconsistency */
  if(!(OldChanges&DBC_BBOX) && 
     !DBVStampSame(&def->cd_vBBOX,&use->cu_vBBOX))
  {
    parent->cd_changesPending |= DBC_BBOX;
  }

  /* add changes due to DISPLAY version inconsistency */
  /* NOTE:  DISPLAY version not propagated, since area will be
   * redisplayed anyway when DBChangedArea() is called.
   */
}
