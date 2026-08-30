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
 * MgcMain.c --
 *
 * Global data, and initialization code for the Mgc package.
 *
 * This package conists of the original Magic commands.
 *
 */

#ifndef lint
static char rcsid[] = "$Header: irMain.c,v 6.1 90/08/28 19:23:56 mayo Exp $";
#endif  not lint

/*--- includes --- */

#include "magic.h"
#include "mgcint.h"
#include "Mgc.h"

/* Globals */
int MgcCommandNumber = 0;


/*
 * ----------------------------------------------------------------------------
 *
 * MgcTclInit --
 *
 * This procedure is called to register the Magic commands with the tcl
 * interpreter.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Register Magic commands with tcl.
 *	
 * ----------------------------------------------------------------------------
 */

void
MgcTclInit(Tcl_Interp *interp)
{
  /* register layout commands */
  mgcLayoutInit(interp);

  /* register global commands */
  mgcGlobalInit(interp);
}

