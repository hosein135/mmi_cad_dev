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
 * units.h --
 *
 * This file defines the interface provided to the units.c,
 * which gives the user a choice of dimensional units used in commands.
 *
 * rcsid $$
 */

#ifndef _UNITS
#define _UNITS

#ifndef _LAYOUT
#include "layout.h"
#endif

#ifndef _TXCOMMANDS
#endif

/* Interface procedures */
extern int UnitsValidS(char *s);
extern int UnitsS2I(char *s);
extern char *UnitsI2S(int i);

extern int UnitsValidSF(char *s);
extern char *UnitsF2S(float i);
extern float UnitsS2F(char *s);


extern double UnitsI2D(int i);  /* internal int to user double */
extern double UnitsF2D(float i);  /* internal float to uer double */


#endif _UNITS
