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
 * DBvstamp.c --
 *
 * handles version stamps
 */

#include <stdio.h>
#include <time.h>
#include "magic.h"
#include "database.h"
#include "databaseInt.h"

VStamp DBVStampInvalid = {0,0};
VStamp DBVStampFixed = {1,0};     /* used when fake, identical stamps needed */
VStamp DBVStampCurrent = {1,0};  /* updated as necessary (and periodically) */

VStamp DBVStampNew(void)
{
/*  fprintf(stderr,"DEBUG TODO DBVStampNew() - time part bogus!\n"); */
  DBVStampCurrent.vs_rev++;
  return DBVStampCurrent;
}

/* update vstamp to "now" */
void DBVStampUpdate(void)
{
  time_t now;

  /* time in seconds since 0:0 January 1, 1970 UTC */
  time(&now);

  if(now!=DBVStampCurrent.vs_time)
  {
    DBVStampCurrent.vs_time = time(&now);
    DBVStampCurrent.vs_rev = 0;
  }
}

#include <limits.h>
#if (INT_MAX != 2147483647)
  int err = DBVStampHash_code_asumes_four_byte_ints;
#endif

/* macros for bit rotation (end around shifts) */
#define ROT_LEFT(a,i) (((a)<<(i))|((a)>>(32-(i))))

/* generate version stamp by hashing def contents */
static int myPlane;
static unsigned int myAcc;   /* non commutattive accumulation */
static int myN;

static void myHashInit()
{
  ASSERT(sizeof(double)==8,"myHashInit"); 
  myAcc = 0;
  myN = 17;
}

static void myHashIn(int add)
{
  myAcc = ROT_LEFT(myAcc,myN&31) ^ add ^ myN;
  myN++;
}

static void myHashInDouble(double d)
{
  char *s = (char *) &d;
  int i;

  for(i=0;i<sizeof(double);i++) myHashIn(*s++);
} 

static int 
myTileFunc(Tile *tile, unsigned int *sigp)
{
  Rect r;

  TiToRect(tile, &r);

  myHashInit();
  myHashIn(myPlane);
  myHashIn(r.r_xbot);
  myHashIn(r.r_ybot);
  myHashIn(r.r_xtop);
  myHashIn(r.r_ytop);
  *sigp ^= myAcc;

  /* continue enumeration */
    return 0;
}

/* XOR items where order shouldn't matter,
 * noncommutative hash within each item.
 */
VStamp DBVStampHash(CellDef *def) 
{
  VStamp result;
  int i;
  Label *l;
  Polygon *poly;
  WirePath *wp;
  unsigned int planeSig[MAXPLANES]; /* compute plane signatures */
  unsigned int labelsSig = 13;
  unsigned int polysSig = 23;
  unsigned int wpsSig = 57;

  /* compute plane signatures */
  for (i = PL_TECHDEPBASE; i < DBNumPlanes; i++)
  {
    myPlane = i;
    planeSig[i]=i;
    DBPlaneEnumAreaPaint((Tile *) NULL, 
			 def->cd_planes[i],
			 &TiPlaneRect, 
			 &DBAllButSpaceAndDRCBits, 
			 myTileFunc,
			 &planeSig[i]);
  }

  /* compute labels signature */
  for(l=def->cd_labels; l; l=l->lab_next)
  {
    char *s;

    myHashInit();
    myHashIn(l->lab_kind);
    myHashIn(l->lab_type);
    myHashIn(l->lab_rect.r_xbot);
    myHashIn(l->lab_rect.r_xtop);
    myHashIn(l->lab_rect.r_ybot);
    myHashIn(l->lab_rect.r_ytop);
    myHashIn(l->lab_pos);
    for(s=l->lab_text; *s!='\0';s++) myHashIn(*s);
    labelsSig ^= myAcc;
    
  }

  /* compute polygons signature */
  for(poly=def->cd_polygons; poly; poly=poly->poly_next)
  {
    /* skip dependent polygons */
    if(poly->poly_wirePath) continue;

    myHashInit();
    myHashIn(poly->poly_type);
    myHashIn(poly->poly_bbox.r_xbot);
    myHashIn(poly->poly_bbox.r_xtop);
    myHashIn(poly->poly_bbox.r_ybot);
    myHashIn(poly->poly_bbox.r_ytop);
    myHashIn(poly->poly_size);

    /* coordinates */
    {
      int n;
      int size = poly->poly_size;

      for(n=0;n<size;n++)
      {
	myHashInDouble(poly->poly_points[n].pf_x);
	myHashInDouble(poly->poly_points[n].pf_y);
      }
    }
    polysSig ^= myAcc;
  }

  /* hash in wirepaths */

  for(wp=def->cd_wirePaths; wp; wp=wp->wp_next)
  {
    myHashInit();
    myHashIn(wp->wp_type);
    myHashIn(wp->wp_bbox.r_xbot);
    myHashIn(wp->wp_bbox.r_xtop);
    myHashIn(wp->wp_bbox.r_ybot);
    myHashIn(wp->wp_bbox.r_ytop);
    myHashIn(wp->wp_style);
    myHashIn(wp->wp_width);
    myHashIn(wp->wp_size);

    /* coordinates */
    {
      int n;
      int size = wp->wp_size;

      for(n=0;n<size;n++)
      {
	myHashIn(wp->wp_points[n].p_x);
	myHashIn(wp->wp_points[n].p_y);
      }
    }
    wpsSig ^= myAcc;
  }

  /* combine individual signatures to create final hash */
  myHashInit();
  for (i = PL_TECHDEPBASE; i < DBNumPlanes; i++) myHashIn(planeSig[i]);
  myHashIn(labelsSig);
  myHashIn(polysSig);
  myHashIn(wpsSig);

  result.vs_time = myAcc & ~(1<<31);
  result.vs_rev = 1000;
  return result;
}





