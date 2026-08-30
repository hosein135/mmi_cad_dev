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
 * drcInt.h --
 *
 * Definitions internal to DRC module 
 * (but shared between files in drc module)
 *
 */

#ifndef _DRCINT
#define	_DRCINT

#ifndef	_DRC
#include "drc.h"
#endif	_DRC

/* current cell to paint errors to */
extern CellDef *DRCErrorDef;
extern TileType DRCErrorType;

/* set when drc had work last time DRCContinous was called.
 * linked to tcl var drc_busy and used to give drc status.
 */
extern bool DRCBusy;

/* The size of chunks into which to decompose large DRC areas.  
 * Recomputed on each call to checker by drcSetup() from MnTypicalWireWidth()
 */
extern int drcStepSize;

/* stepsize for processing, in typical wire widths 
 * linked to tcl var DRC_STEP_SIZE 
 */
extern int drcStepSizeWidths;

/* called on each invocation of checker */
extern void drcSetup(void);

#endif _DRCINT

