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



/* bpMain.c
 *
 * Top-level routines for BPlanes
 * (interface to other modules)
 *
 * See bpEnum.c for enum routines.
 * See bpTcl.c for tcl-level interface.
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
 * BPNew --
 *
 * Return newly created BPlane.
 *
 * ----------------------------------------------------------------------------
 */		 
BPlane *BPNew(void)
{
  BPlane *new;

  MALLOC_TAG(BPlane *, new, sizeof(BPlane), "BPlane");

  new->bp_bbox = GeoNullRect;
  new->bp_count = 0;

  /* ENUMS */
  new->bp_enums = NULL;

  /* HASH TABLE */
  new->bp_hashTable = IHashInit(4, /* initial buckets */
				OFFSET(Element, e_rect), /* key */
				OFFSET(Element, e_hashLink),
				IHash4WordKeyHash,
				IHash4WordKeyEq);

  /* IN BOX */
  new->bp_inBox = NULL;

  /* BINS */
  new->bp_binLife = 0;
  new->bp_inAdds = 0;
  new->bp_binArea = GeoNullRect;
  new->bp_rootNode = NULL;

  return new;
}

/*
 * ----------------------------------------------------------------------------
 * BPFree --
 *
 * free (empty) BPlane
 *
 * ----------------------------------------------------------------------------
 */		 
void BPFree(BPlane *bp)
{
  ASSERT(bp->bp_count == 0,"BPFree");
  IHashFree(bp->bp_hashTable);
  FREE_TAG(bp,"BPlane");    
}

/*
 * ----------------------------------------------------------------------------
 * BPAdd --
 *
 * add element to the given bplane
 *
 * ----------------------------------------------------------------------------
 */		 
void BPAdd(BPlane *bp, void *element)
{
  int size;
  int binDim;
  Element * e = element;
  Rect *r = &e->e_rect;

  /* no add/delete during concurrent enums */
  ASSERT(!bp->bp_enums || !bp->bp_enums->bpe_next,
	 "BPAdd, attempted add during concurrent enumerations");

  bp->bp_count++;

  /* update hash table */
  IHashAdd(bp->bp_hashTable, element);

  /* update bbox */
  if(GEO_RECTNULL(&bp->bp_bbox))
  {
    bp->bp_bbox = *r;
  }
  else
  {
    GeoIncludeRectInBBox(r,&bp->bp_bbox);
  }
    
  /* no bins? */
  if(!bp->bp_rootNode) goto inBox;

  /* doesn't fit inside bins ? */
  if(!GEO_SURROUND(&bp->bp_binArea,r)) goto inBox;

  /* bin element */
  bpBinAdd(bp->bp_rootNode, e);
  return;

  /* add to in box */
 inBox:
  bp->bp_inAdds++;
  e->e_link = bp->bp_inBox;
  bp->bp_inBox = e;

  /* maintain back pointers */
  e->e_linkp = &bp->bp_inBox;
  if(e->e_link) e->e_link->e_linkp = &e->e_link;

}

/*
 * ----------------------------------------------------------------------------
 * BPDelete --
 *
 * remove element from bplane
 *
 * ----------------------------------------------------------------------------
 */		 
void BPDelete(BPlane *bp, void *element)
{
  Element *e = element; 

  ASSERT(e,"BPDelete");
  bp->bp_count--;

  /* advance any nextElement pointers at e */
  {
    BPEnum *bpe;

    for(bpe=bp->bp_enums; bpe; bpe=bpe->bpe_next)
    {
      if(bpe->bpe_nextElement != e) continue;

      if(bpe->bpe_match == BPE_EQUAL)
      {
	bpe->bpe_nextElement = IHashLookUpNext(bp->bp_hashTable, e);
      }
      else
      {
	bpe->bpe_nextElement = e->e_link;
      }
    }
  }

  IHashDelete(bp->bp_hashTable, e);    

  /* next pointer of prev element */
  *e->e_linkp = e->e_link;

  /* back pointer of next element */
  if(e->e_link) e->e_link->e_linkp = e->e_linkp;
}




