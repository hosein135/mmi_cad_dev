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
 * grTcl.c -- Tcl command interface to this module
 */

static char rcsid[] = "$Header$";

#include "magic.h"
#include "main.h"
#include "graphics.h"
#include "graphicsInt.h"

/*
 *--------------------------------------------------------------
 *
 * grTclCmdRGBToPixel--
 *
 * implements tcl command. 
 *
 * C Result:
 *	A standard Tcl result.
 *
 *--------------------------------------------------------------
 */

#define gr_rgb_to_pixel_DESC "convert RGB to corresponding pixel value"

#define gr_rgb_to_pixel_DOC "
Usage:  gr_rgb_to_pixel red green blue

Red, green and blue must have integer values between 0 and 255.

Returns: integer pixel value
"

static int
grTclCmdRGBToPixel(ClientData clientData, 
		   Tcl_Interp *interp, 
		   int argc, 
		   char **argv)
{
  char *cmdName;
  int red,green,blue;
  int result;

  CMD_BEGIN(interp);

  /* parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* Parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];

    /* no switchs yet */

    /* bad switch */
    goto usage;
  } /* end while(argc>0 && **argv=='-')  */

  /* parse red */
  {
    if(argc<1) goto usage;
    if(sscanf(*argv,"%i", &red)!=1) goto usage;

    if (red < 0 || red > 255)
    {
      MsgErrorF("red %d is out of range (0 <= red <= 255)\n", 
		red);
      CMD_RETURN(interp);
    }
    argc--; argv++;
  }


  /* parse green */
  {
    if(argc<1) goto usage;
    if(sscanf(*argv,"%i", &green)!=1) goto usage;

    if (green < 0 || green > 255)
    {
      MsgErrorF("green %d is out of range (0 <= green <= 255)\n", 
		green);
      CMD_RETURN(interp);
    }
    argc--; argv++;
  }

  /* parse blue */
  {
    if(argc<1) goto usage;
    if(sscanf(*argv,"%i", &blue)!=1) goto usage;

    if (blue < 0 || blue > 255)
    {
      MsgErrorF("blue %d is out of range (0 <= blue <= 255)\n", 
		blue);
      CMD_RETURN(interp);
    }
    argc--; argv++;
  }

  /* should be no args left */
  if(argc != 0) goto usage;

  if(GrColorMapped)
  {
    MsgErrorF("%s only valid in direct mode (GR_COLOR_MAPPED reset)\n",
       	      cmdName);
    CMD_RETURN(interp);
  }

  /* get result */
  result = GrRGBToPixel(red,green,blue);

  /* set tcl result */
  {
    char buf[BUFSIZ];

    /* NOTE:  format must match lay_style color format, since
     * vaules are used in assoc array by tcl code.
     */
    sprintf(buf,"%#04o", result);
    Tcl_SetResult(interp, buf, TCL_VOLATILE);
  }
  

  CMD_RETURN(interp);

usage:
    MsgErrorF("usage:  %s red green blue\n",
       	      cmdName);
    CMD_RETURN(interp);
}



/*
 * ----------------------------------------------------------------------------
 *
 * GrTclInit --
 *
 * Initialize tcl commands for this module
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Registers command(s) with tcl.
 *	
 * ----------------------------------------------------------------------------
 */

void
GrTclInit(Tcl_Interp *interp)
{
   MnDocCreateCommand(interp, "gr_rgb_to_pixel", grTclCmdRGBToPixel,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       gr_rgb_to_pixel_DESC,
	       gr_rgb_to_pixel_DOC);

   MnDocLinkVar(interp, "GR_COLOR_MAPPED",
		(char *) &GrColorMapped, TCL_LINK_BOOLEAN | TCL_LINK_READ_ONLY,
		 "Set if graphics indirected through colormap (\"pseudocolor\")",
		 NULL);

   MnDocLinkVar(interp, "GR_DEPTH",
		(char *) &GrDepth, TCL_LINK_INT | TCL_LINK_READ_ONLY,
		 "bits per pixel",
		 NULL);
}







