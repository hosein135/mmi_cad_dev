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



#ifndef _DEF
#define _DEF

#ifndef _TCL
#include <tcl.h>
#endif

/*
 * def.h --
 *
 * This file defines the interface between the def
 * module and the rest of max.
 *
 * This module (will) contain code to write and possibly read def.
 *                      
 */     

/* module initialization (called once at Max startup) */
extern void DefTclInit(Tcl_Interp *interp);


enum DFDefOri {
    DFDefOri_null,	// unused
    DFDefOri_normal,
    DFDefOri_N,
    DFDefOri_S,
    DFDefOri_E,
    DFDefOri_W,
    DFDefOri_FN,
    DFDefOri_FS,
    DFDefOri_FE,
    DFDefOri_FW,
};

#endif _DEF

