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
 * TODO. change/update detail!
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


/*
 * --------------------------------------------------------------------
 *
 * dbChangePropagate --
 *
 * set CD_CHANGED_INSTANCE flags in all ancestors of changed def.
 *
 * --------------------------------------------------------------------
 */

static void
dbChangePropagate(CellDef *def)
{
  CellPar *cellpar;

  /*
  fprintf(stderr,"DEBUG dbChangePropagate.  cell=%s  changes=%d\n",
	  def->cd_name, changes);
  */

  /* only need to propagate new changes */
  if(def->cd_flags&CD_CHANGED_INSTANCE) return;

  /* propagate new changes through parents */
  for(cellpar = def->cd_pars; cellpar; cellpar=cellpar->cp_next)
  {
    CellDef *parent =cellpar->cp_def;

    dbChangePropagate(parent);
    parent->cd_flags |= CD_CHANGED_INSTANCE;

    /* notify layout module of need for redisplay in windows 
     * containing parent def (as root def) 
     */
    LayChangedScheduleDef(parent);
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
  bool internal = def->cd_flags & CD_INTERNAL;
  bool read = flags & DBCF_DEFREAD;


  if(Debug1) fprintf(stderr,"DEBUG dbChangedArea.  cell=%s flags=%o TOP\n",
	  def->cd_name,flags);

  /* update def version */
  def->cd_version = DBVStampNew();

  /* if display flag set, skip main/drc/bbox stuff. */
  if(flags & DBCF_DISPLAY_ONLY) goto display;

  /* if drc error flag set (change is to drc error layer)
   * skip main/drc stuff
   */
  if(flags & DBCF_DRC_ERROR_ONLY) goto bbox;

  /* if read, skip main stuff. */
  if(read) 
  {
    DRCChangeAddDef(def);
    goto drc;
  }

 main:
  if(layers==NULL || TTMaskIntersect(layers,&DBNonTempTypes))
  {
    def->cd_flags |= CD_MODIFIED;
  }

 drc:

  if(flags & DBCF_NODRC)
  {
    /* pretend cell is DRC up-to-date, used on gds read */
    def->cd_vDRC = DBVStampFixed;
  }
  else
  {
    if(!read || !DBVStampValid(&def->cd_vDRC))  
    {
      if(!internal &&
	 (layers== NULL || TTMaskIntersect(layers, &DBAllButSpaceAndDRCBits)))
      {
	def->cd_vDRC = def->cd_version;

	DRCChangedArea(def, area);
	/* Note DRC will be notified of change in parents at update time */
      }
    }
  }

 bbox:
  /* (real bbox always contains user bbox) 
   * 
   */
  if(!read && 
     !(def->cd_flags & CD_CHANGED_BBOX) && 
     (!area || !GEO_SURROUND_STRONG(&def->cd_userBBox, area)))
  { 
    /* bbox will be recumputed at update time */
    def->cd_flags |= CD_CHANGED_BBOX;
  }

 coarse:
  /* coarse paint plane database */
  if(def->cd_coarseDB) 
  {
    if(!(flags & 
	 (DBCF_LABEL_ONLY|DBCF_INSTANCE_ONLY|DBCF_POLYGON_ONLY|DBCF_WIREPATH_ONLY|DBCF_LABEL_ONLY)))
    {
      LayCoarseChange(def, area);
    }
  }

 display:
  /* redisplay */
  LayChangedDef(def, area, layers); 

 propagate:
  /* set CD_CHANGED_INSTANCE flags in all ancestors of this def */
  dbChangePropagate(def);
  /* if def just read from .max file, instance versions may
   * not be up-to-date, so need to check.
   */
  if(read) def->cd_flags |= CD_CHANGED_INSTANCE;

  /* DEBUG
  if(Debug1) fprintf(stderr,"DEBUG dbChangedArea.  cell=%s BOT\n",
	  def->cd_name);
  */
}
