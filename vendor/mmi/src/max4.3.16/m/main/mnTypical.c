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
 * mnTypical.c --
 *
 * Estimate typical dimension (wire width).
 * Used for choosing display fonts, for example.
 *
 */

#ifndef lint
static char rcsid[]="$$";
#endif  not lint

#include <math.h>
#include "magic.h"
#include "units.h"
#include "main.h"
#include "mainInt.h"
#include "cif.h"
#include "drc.h"

/* user supplied typical wire width (linked to MN_TYPICAL_WIRE_WIDTH) */ 
double mnTypicalWireWidthUser = -1;
/*
 * ----------------------------------------------------------------------------
 *
 * MnTypicalWireWidth --
 *
 * Return estimate of typical wire width in current technology 
 * (in database units).
 *
 * Results:
 *	estimate of typical wire width in internal units.
 *
 * Side effects:
 *       None.
 *
 * ----------------------------------------------------------------------------
 */
int MnTypicalWireWidth(void)
{
  if(mnTypicalWireWidthUser > 0)
  {
    /* user set MN_TYPICAL_WIRE_WIDTH, use it */
    return ROUND(mnTypicalWireWidthUser/CIFDBRes);
  }
  else if(DRCm1Width>0)
  {
    /* use m1 wire width */
    return DRCm1Width;
  }
  else
  {
    /* otherwise just guess 0.25 microns */
    return ROUND(0.25/CIFDBRes);
  }
}





