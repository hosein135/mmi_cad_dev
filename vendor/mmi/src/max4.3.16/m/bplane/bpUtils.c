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




/* bpUtils.c --
 *
 * shared low-level routines for this module.
 *
 */

#include <stdio.h>
#include "utils.h"
#include "message.h"
#include "database.h"
#include "geometry.h"
#include "bplane.h"
#include "bplaneInt.h"
#include "debug.h"


/*
 * ----------------------------------------------------------------------------
 * bpRectDim --
 *
 * return dimension of rectangle in xDir
 *
 * ----------------------------------------------------------------------------
 */		 
int bpRectDim(Rect *r, bool xDir)
{
  return xDir ? r->r_xtop - r->r_xbot : r->r_ytop - r->r_ybot;
}

/*
 * ----------------------------------------------------------------------------
 * bpBinIndices --
 *
 * compute bin indices corresponding to area.
 *
 * ----------------------------------------------------------------------------
 */		 
static __inline__ void 
bpBinIndices(Rect area,        /* area */
	     Rect binArea,     /* lower left corner of bin system */
	     int indexBits,
	     int dim,
	     bool  xDir,       /* TRUE for x bin, FALSE for y bin */
	     int *min,         /* results go here */
	     int *max)
{
  int ref, coord; 
  int index;

#ifdef HIDE
  if(xDir)
  {

    /* min */ 
    coord = area.r_xbot - coord.r_xtop;
    area.r_xbot - origin.r_xbot : 
    area.r_ybot - origin.r_ybot;
  if(coord
  

  /* compute bin dimension */
  if(xDir)
  {
    ref = origin.r_xbot;
    dim = (binArea.r_xtop - ref) >> indexBits
  }
  else
  {  
    ref = binArea.rf_ybot;
    dim = (binArea.r_ytop - ref) / BN_BINS;
  }

  /* min */

  index = ((coord - ref) / dim) - 1;  /* -1 since elements can overlap into
				       * next bin up.
				       */
  index = MAX(0,index);
  index = MIN(index,BN_BINS);
  *min = index;

  /* max */
  coord = (xDir) ? area.rf_xtop : area.rf_ytop;
  index = (coord - ref) / dim;
  index = MAX(0,index);
  index = MIN(index,BN_BINS-1);
  *max = index;
#endif HIDE

}
