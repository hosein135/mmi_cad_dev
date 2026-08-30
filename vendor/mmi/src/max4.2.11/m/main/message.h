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
 * message.h --
 *
 * External inteface to message module (main/message.h)
 *
 * Message Types:
 *      info - messages during normal processing (defaults to stdout)
 *      warn - abnormal conditions, but command not aborted (default: stderr)
 *      error - abnormal condition, command aborting (messages passed up call stack
 *              as tcl result, according to tcl error mechanism)
 *      panic - internal inconsistency, Max aborting (not handled here).
 *
 * rcsid $Header$
 */

#ifndef _STDIO_H
#include <stdio.h>
#endif

#ifndef _TCL_H
#include <tcl.h>
#endif

#ifndef _STDARG_H
#include <stdarg.h>
#endif

#ifndef _MESSAGE
#define _MESSAGE

#ifndef _MAGIC
#include "magic.h"
#endif

/* message procedures */
extern void MsgInfoF(char *fmt, ...);
extern void MsgInfoV(char *fmt, va_list args);
extern void MsgWarnF(char *fmt, ...);
extern void MsgWarnV(char *fmt, va_list args);
extern void MsgErrorF(char *fmt, ...);
extern void MsgErrorV(char *fmt, va_list args);

/* procedures for bracketing commands (for proper error processing) 
 * (should not be called directly use CMD_BEGIN and CMD_RETURN macros instead)
 */
void MsgCmdBegin();
int MsgCmdEnd(Tcl_Interp *interp);

/* input procedures ANACHRONISM - TODO: eliminate! */
extern char *TxGetLine(char *dest, int maxChars);

#endif _MESSAGE
