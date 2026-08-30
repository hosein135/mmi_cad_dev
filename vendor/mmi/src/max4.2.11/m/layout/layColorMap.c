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



/* layColorMap.c -
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
 * Procedure to read in technology specific colormap layout graphics 
 * "logical" colormap from file. 
 *
 * The logical layout colormap is  mapped into the
 * actual colormap inside the graphics module.
 */

#ifndef lint
static char rcsid[]="$Header: grCMap.c,v 6.0 90/08/28 18:40:37 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include <X11/Xlib.h>
#include <tk.h>
#include "magic.h"
#include "main.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "utils.h"
#include "message.h"
#include "layout.h"
#include "layint.h"
#include "graphics.h"

/*-----------------------------------------------------------------------------
 * layColorMapInit --
 *
 *	This routine initializes the layout graphics colormap, 
 *      (all values set to white)
 *
 *-----------------------------------------------------------------------------
 */

void
layColorMapInit(void) 
{
  int color;

  if(!GrColorMapped) return;

  for (color = 0; color<128; color ++) 
    GrColorMapWrite(color, 255, 255, 255); 
}

/*
 *--------------------------------------------------------------
 *
 * layCMapCmd --
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Tcl Result:

 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define lay_cmap_DESC "set layout color map entry" 

#define lay_cmap_DOC "
 Usage:
	lay_cmap entry r g b 

 entry is integer between 0 and 127 
 r/g/b are integers between 0 and 256
"

int
layCMapCmd(ClientData clientData, Tcl_Interp *interp, 
		     int argc, char **argv)
{

  char *cmdName;
  int entry, r, g, b;
  
  CMD_BEGIN(interp);
    
  /* parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* Parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];

    /* no switches yet */

    /* unrecognized option */
    goto usage;
  } 

  /* entry */
  if (argc<1) goto usage;
  if (sscanf(*argv,"%i",&entry) != 1) goto usage;
  if (entry<0 || entry>127) goto usage; 
  argc--; argv++;

  /* r */
  if (argc<1) goto usage;
  if (sscanf(*argv,"%d",&r) != 1) goto usage;
  if (r<0 || r>256) goto usage; 
  argc--; argv++;

  /* g */
  if (argc<1) goto usage;
  if (sscanf(*argv,"%d",&g) != 1) goto usage;
  if (g<0 || g>256) goto usage; 
  argc--; argv++;

  /* b */
  if (argc<1) goto usage;
  if (sscanf(*argv,"%d",&b) != 1) goto usage;
  if (b<0 || b>256) goto usage; 
  argc--; argv++;

  if(argc !=0) goto usage;
  
  /* write into colormap */
  GrColorMapWrite(entry,r,g,b);

  /* redisplay everything */
  LayChangedDisplay(NULL);
   
  CMD_RETURN(interp);

usage:
  MsgErrorF("Usage:  %s entry r g b\n\n"
	    "\twhere,"
	    "\tentry is integer between 0 and 127\n"
	    "\tr/g/b are intergers between 0 and 256\n",
	    cmdName);


  CMD_RETURN(interp);
}

/*
 * ----------------------------------------------------------------------------
 *
 * layColorMapTclInit --
 *
 * Register Tcl command interface to this file.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Registers commands with tcl.
 *	
 * ----------------------------------------------------------------------------
 */

void
layColorMapTclInit(Tcl_Interp *interp)
{
   MnDocCreateCommand(interp, "lay_cmap", layCMapCmd, 
	       (ClientData) NULL,  (Tcl_CmdDeleteProc *) NULL,
	       lay_cmap_DESC,
	       lay_cmap_DOC);
}

