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

#include "tcl.h"
#include "tk.h"
#include "mem.h"
#include "ar.h"
#define nl_object void *
#define UI_NO_FIND_FNS
#include "ui.h"
#include "nlsh_version.h"


static
int
nlsh_app_init (Tcl_Interp *interp)
{
  void *context;
  int status = ui_app_init (interp, "nl_", &context, NLSH_VERSION);

  if ( status != TCL_OK )
    return status;

  status = ui_alias_init (interp, "nl_", context);

  return status;
}


int
main (int argc, char *argv[])
{
  putenv ("TK_LIBRARY=" TK_LIBRARY);
  Tk_Main (argc, argv, (Tcl_AppInitProc *)nlsh_app_init);

  return 0;
}
