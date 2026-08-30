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
 * mgcint.h --
 *
 * Internal interface for Mgc package.
 *
 * This package consists of original Magic commands.
 *
 * rcsid $Header$
 */

#ifndef _MGCINT
#define	_MGCINT

#ifndef _TCL_H
#include <tcl.h>
#endif

#ifndef _LAYOUT
#include "layout.h"
#endif

/* Structure for passing args to old Magic commands */
#define	TX_MAXARGS	50
#define TX_MAX_CMDLEN	1000

typedef struct {		
    int tx_argc;		
    char *tx_argv[TX_MAXARGS];	
    char tx_argstring[TX_MAX_CMDLEN];
} TxCommand;

/* ---- procedure headers ---- */
extern void mgcLayoutInit(Tcl_Interp *interp);
extern void mgcGlobalInit(Tcl_Interp *interp);

/* Magic layout commands */
extern Void CmdArray(Layout *w, TxCommand *cmd);
extern Void CmdCalma(Layout *w, TxCommand *cmd);
extern Void CmdCif(Layout *w, TxCommand *cmd);
extern Void CmdCheckPoint(Layout *w, TxCommand *cmd);
extern Void CmdCif(Layout *w, TxCommand *cmd);
extern Void CmdClockwise(Layout *w, TxCommand *cmd);
extern Void CmdCopy(Layout *w, TxCommand *cmd);
extern Void CmdCorner(Layout *w, TxCommand *cmd);
extern Void CmdDelete(Layout *w, TxCommand *cmd);
extern Void CmdDrc(Layout *w, TxCommand *cmd);
extern Void CmdDump(Layout *w, TxCommand *cmd);
extern Void CmdEdit(Layout *w, TxCommand *cmd);
extern Void CmdErase(Layout *w, TxCommand *cmd);
extern Void CmdExpand(Layout *w, TxCommand *cmd);
extern Void CmdExtract(Layout *w, TxCommand *cmd);
extern Void CmdExtractTest(Layout *w, TxCommand *cmd);
extern Void CmdFeedback(Layout *w, TxCommand *cmd);
extern Void CmdFill(Layout *w, TxCommand *cmd);
extern Void CmdFindBox(Layout *w, TxCommand *cmd);
extern Void CmdFlush(Layout *w, TxCommand *cmd);
extern Void CmdGetcell(Layout *w, TxCommand *cmd);
extern Void CmdGetnode(Layout *w, TxCommand *cmd);
extern Void CmdGrid(Layout *w, TxCommand *cmd);
extern Void CmdIdentify(Layout *w, TxCommand *cmd);
extern Void CmdLabel(Layout *w, TxCommand *cmd);
extern Void CmdLoad(Layout *w, TxCommand *cmd);
extern Void CmdMove(Layout *w, TxCommand *cmd);
extern Void CmdPaint(Layout *w, TxCommand *cmd);
extern Void CmdRsim(Layout *w, TxCommand *cmd);
extern Void CmdSave(Layout *w, TxCommand *cmd);
extern Void CmdSee(Layout *w, TxCommand *cmd);
extern Void CmdSideways(Layout *w, TxCommand *cmd);
extern Void CmdSimCmd(Layout *w, TxCommand *cmd);
extern Void CmdStartRsim(Layout *w, TxCommand *cmd);
extern Void CmdStretch(Layout *w, TxCommand *cmd);
extern Void CmdUnexpand(Layout *w, TxCommand *cmd);
extern Void CmdUpsidedown(Layout *w, TxCommand *cmd);

/* Wizard commands */
extern Void CmdCoord(Layout *w, TxCommand *cmd);
extern Void CmdExtractTest(Layout *w, TxCommand *cmd);
extern Void CmdExtResis();
extern Void CmdPsearch(Layout *w, TxCommand *cmd);
extern Void CmdExtResis();
extern Void CmdSeeFlags();
extern Void CmdShowtech(Layout *w, TxCommand *cmd);
extern Void CmdTilestats(Layout *w, TxCommand *cmd);
extern Void CmdTsearch(Layout *w, TxCommand *cmd);
extern Void CmdWatch(Layout *w, TxCommand *cmd);

#endif _MGCINT

