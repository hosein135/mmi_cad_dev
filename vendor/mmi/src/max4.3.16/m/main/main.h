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
 * main.h --
 *
 * Header file containing global variables for all MAGIC modules and a 
 * couple of global procedures.
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
 *
 *
 * rcsid="$Header: main.h,v 6.0 90/08/28 18:47:22 mayo Exp $"
 */

#ifndef _MAIN
#define _MAIN

#ifndef _STDIO_H
#include <stdio.h>
#endif _STDIO_H

#ifndef _TIME_H
#include <time.h>
#endif

#ifndef _TK
#include <tk.h>
#endif _TK

#ifndef	_DATABASE
#include "database.h"
#endif	_DATABASE

#ifndef	_LAYOUT
#include "layout.h"
#endif	_LAYOUT

extern char *MnMMITools;        /* Toplevel dir for mmi tools installation */
extern char *MnMMIToolsMax;     /* system max lib */

extern char *MnMMILocal;        /* Toplevel dir for site specific mmi tools
				 * files. 
				 */
extern char *MnMMILocalMax;     /* site specific max lib */

extern char *MnMMIPrivate;      /* User specific site for mmi tools files */
extern char *MnMMIPrivateMax;   /* User specific max lib */

extern char *MnPathSysLib;	/* Search path for runtime system files, such
				 * as color maps, styles, technology files
				 * etc.
				 */

extern char *MnPathCell;       /* user controlled cell search path */

extern Tcl_Interp *MnInterp;          /* tcl interpreter */
extern Tk_Window MainTkWin;    /* Token for the main Tk window */

extern char *MnTech;           /* name of tech files to load */
extern char *MnTechVar;        /* var name for tech file */

/*
 * The following information is kept about the Edit cell:
 *
 * EditCellUse		pointer to the CellUse from which the edit
 *			cell was selected.
 * EditRootDef		pointer to root def of window in which edit cell
 *			was selected.
 * EditToRootTransform	transform from coordinates of the Def of edit cell
 *			to those of EditRootDef.
 * RootToEditTransform	transform from coordinates EditRootDef to those
 *			of the Def of the edit cell.
 */
extern CellUse	*EditCellUse;
extern CellDef	*EditRootDef;
extern Transform EditToRootTransform;
extern Transform RootToEditTransform;

/* args max was started with */
extern int MnArgC;
extern char **MnArgV;

/* set for developer mode */
extern bool MnDeveloper;

/* macros for bracketing commands - use in all tcl commands! */
extern int MnCmdNesting;
#define CMD_BEGIN(interp) (MnCmdNesting++,MsgCmdBegin())
#define CMD_RETURN(interp) return (MnCmdNesting--,MsgCmdEnd(interp))  
#define CMD_RETURN_UNWIND(interp) return (MnCmdNesting=0,MsgCmdEndUnwind(interp))  
#define CMD_INSIDEQ(interp) (MnCmdNesting)
/* MnTic() is called periodically during potentially long computations, 
 * to allow "periodic" services, such as reading the X event socket, 
 * so that the socket doesn't time out on us, and checking for 
 * "interrupt" events.
 */  
 
#define MN_TIC_INTERVAL 100000 
#define MN_TIC_SECS 1

extern time_t MnLastTic;  
extern int MnTicCount;
extern void MnTicService(void);

static __inline__ void MnTic(int weight) 
     /* approximately how much time went by relative to a paint operation */ 
{

  MnTicCount += weight;
  if(MnTicCount >= MN_TIC_INTERVAL) 
  {
    time_t now = time(NULL);

    MnTicCount = 0;

    if(now - MnLastTic < MN_TIC_SECS) return;
    MnLastTic = now;
    MnTicService();
  }
}

/* exported procedures */
extern void MnTechError(char *fmt, ...);

extern void MnTclSetLinkedString(char **sp, char *value);
extern bool MnTclEvalBg(char *script, char *errMsg);

extern void 
MnDocCreateCommand(Tcl_Interp *interp, 
	    char *name, 
	    int func(ClientData clientData, Tcl_Interp *interp, int argc, char *argv[]),
	    ClientData cData,
	    Tcl_CmdDeleteProc *deleteP,
	    char *desc,
	    char *doc);

extern void
MnDocCreateObjCommand(Tcl_Interp *interp,
              char *name,
              int func(ClientData clientData, Tcl_Interp *interp, int objc,
Tcl_Obj *objv[]),
              ClientData cData,
              Tcl_CmdDeleteProc *deleteP,
              char *desc,
              char *doc);

extern void
MnDocVar(Tcl_Interp *interp, 
	 char *name1,              
	 char *name2,              /* null unless array */
	 int flags,             
	 char *desc,               /* one line desc */
	 char *doc);               /* detailed documentation */

extern void
MnDocLinkVar(Tcl_Interp *interp, 
	     char *name,               /* tcl var name */
	     char *addr,               /* address of corresponding C variable */
	     int type,                 /* variable type */
	     char *desc,               /* one line desc */
	     char *doc);               /* detailed documentation */

extern void
MnDocSetVar(Tcl_Interp *interp, 
	    char *name,              
	    char *newValue,             
	    int flags,             
	    char *desc,               /* one line desc */
	    char *doc);               /* detailed documentation */

extern void
MnDocSetVar2(Tcl_Interp *interp, 
	     char *part1,              
	     char *part2,              
	     char *newValue,             
	     int flags,             
	     char *desc,               /* one line desc */
	     char *doc);               /* detailed documentation */

extern int
MnTypicalWireWidth(void);
#endif _MAIN





