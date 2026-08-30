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
 * MgcCmd.c --
 *
 * 	This file contains initialization code for the old Magic layout
 *      commands(now part of the Mgc module)
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
 */

#ifndef lint
static char rcsid[] = "$Header$";
#endif  not lint

#include <tcl.h>
#include "magic.h"
#include "commands.h"
#include "layout.h"
#include "mgcint.h"
#include "Mgc.h"
#include "main.h"

/* 
 * LAYOUT COMMAND TABLES
 *
 * mgcLayoutCmds	 - contains three strings for each command:
 *                           [0] name and args
 *                           [1] one line description
 *                           [2] additional documentation of any length.
 *
 * mgcLayoutFuncs - contains pointers to the routines implementing the 
 *                  commands.
*/

static char *mgcLayoutCmds[] =
{
  "*coord",
  "show coordinates of various things",
  "",

  "*extract [args]",
  "debug the circuit extractor",
  "",

  "*psearch plane count",
  "invoke point search over box area",
  "",

  "*showtech [file]",
  "print internal technology tables",
  "",

  "*tilestats [file]",
  "print statistics on tile utilization",
  "",

  "*watch [plane] [groups | types]",
  "enable verbose tile plane redisplay",
  "",

  "array xsize ysize OR :array xlo xhi ylo yhi",
  "array everything in selection",
  "The second form controls instance name subscripting.",

  "calma option",
  "read/write  GDS-II stream file",
  "\":calma help\" for information on options",

  "checkpoint file",
  "save current state of edit cell in file",
  "Does not change file associated with edit cell or clear its modified flag.",

  "cif option",
  "mask layers and layer operation controls",
  "\":cif help\" for information on options",

  "clockwise [deg]",
  "rotate selection (and box) clockwise",
  "
Valid values for deg are multiples of 90:  
  90  (the default), 
  -90 (rotate 90 degrees counterclockwise)
  180 (rotate upside down)
",

  "copy [dir [amount]] or :copy to x y", 
  "copy selection (OBSOLETE use sel_duplicate instead)",
  "
Lower-left of box will be copied to cursor location, or, copy 
will appear amount microns in dir from original.  Valid values 
for dir are:  N, S, E and W.  The second form copys to location x y.
",

  "corner d1 d2 [layers]",
  "make L-shaped wires inside box",
  "
fills first in direction d1, then in d2.  This command is useful 
for turning a bus through a corner.  (The box should contain the 
end points of the bus when this command is issued.)
",

  "delete",
  "delete selection",
  "",
    
  "drc option",
  "design rule checker",
  "
DRC commands have the form \":drc option\", where option is one of:

  catchup                run checker and wait for it to complete
  check                  recheck area under box in all cells
  count                  count error tiles in each cell under box
  find [nth]             locate next (or nth) error in current cell
  off                    turn off background checker
  on                     reenable background checker
  printrules [file]      print out design rules in file or on tty
  rulestats              print out stats about design rule database
  statistics             print out statistics gathered by checker
  why                    print out reasons for errors under box
",

  "dump [-dup_ok] cell [child refPointC] [parent refPointP]",
  "copy contents of cell into edit cell",
  "
Copy is positioned so that refPointC (or lower left) of cell is at
refPointP (or box lower-left).

RefPoints are either labels or a pair of coordinates (e.g, 100 200)

If -dup_ok, allows duplicate instances on top of each other -
useful for interactive drags.  NOTE: -dup_ok should eventually be 
followed by 'sel_move 0 0' to check for duplicates.

See also :getcell.
",

  "edit",
  "make selected cell the edit cell",
  "Only the edit cell can be modified by paint operations etc.",

  "erase [layers]",
  "erase mask information under box",
  "",

  "expand [toggle]",
  "expand/unexpand subcells",
  "
Without 'toggle' option - expands everything under box.
With 'toggle' option - toggles expansion mode of selected cells
",

  "extract option",
  "circuit extractor",
  "\":extract help\" for information on options",

  "feedback option",
  "access/change feedback information attached to layout",
"
Feedback areas are used by Max to show extraction errors.  They
can also be used to show results of external drc, or for other
custom purposes.  

Feedback commands have the form \"feedback option\",
where option is one of:

add text [style]                create new feedback area over box
clear                           clear all feedback info
count                           count # feedback entries
find [nth]                      put box over next [or nth] entry
save file                       save feedback areas in file
why                             print all feedback messages under box

Valid styles for the 'add' command are:  'dotted', 'medium', 'outline', 
'pale', and 'solid'.  'pale' is the default.
",

  "fill dir [layers]",
  "fill layers from one side of box to other",
  "Valid values of dir are:  N, S, E, and W.",

  "findbox [zoom]",
  "center the view on the box and optionally zoom in",
  "",

  "flush [cellname]",
  "flush changes to cellname (edit cell by default)",
  "",

  "getcell cell [-dup_ok] [child refPointC] [parent refPointP]",
  "make cell a subcell of the edit cell (OBSOLETE use db_instance instead)",
"

Cell positioned so that refPointC (or lower left) of cell is at
refPointP (or box lower-left).

RefPoints are either labels or pairs of coordinates (e.g, 100 200)

If -dup_ok, allows duplicate instances on top of each other -
useful for interactive drags.  NOTE: -dup_ok should eventually be 
followed by 'sel_move 0 0' to check for duplicates.

See also :dump
",

  "identify use_id",
  "set the id of the selected cell instance",
  "",

  "label [-kind comment|hidden|local|global|input|output|inout] str [pos [layer]]",
  "add a label",
  "
OBSOLETE:  See db_label

pos defines the position of the text relative to the label point (or box).
Valid values for pos are: 
  nw,  n,  ne,
  w,   c,  e,
  sw,  s,  se
",

  "load [cellname]",
  "load a cell into a window",
  "
Low level command.  
Mostly likely you want cell_load, cell_load_files instead. 
See also db_cell_new.
",

  "move [dir [amount]]",
  "move box and selection (OBSOLETE use sel_move instead)",
  "If no args, moves box lower-left corner to cursor.\n\
If args, moves accordingly.",

  "paint layers",
  "paint layers under box",
  "NOTE: paint operations clears the selection",

    "save [filename]",
    "write edit cell to disk",
    "",

  "see [no] layers|allSame|flyLines|hiddenLabels|instanceNames|instancePorts",
  "adjust which layers are visible",
"
If \"allSame\" is set, non-edit cell paint is not dimmed.

\"instanceNames\" and \"instancePorts\" control the appearance of unexpanded instances.
",

  "sideways",
  "flip selection and box around vertical axis",
  "",

  "stretch [dir [amount]]",
  "stretch box and selection",
  "",

  "unexpand",
  "unexpand subcells under box",
  "",

  "upsidedown",
  "flip selection and box through horizontal axis",
  "",

   0
};

static Void (*mgcLayoutFuncs[])() =
{
    CmdCoord,
    CmdExtractTest,
    CmdPsearch,
    CmdShowtech,
    CmdTilestats,
    CmdWatch,
    CmdArray,
    CmdCalma,
    CmdCheckPoint,
    CmdCif,
    CmdClockwise,
    CmdCopy,
    CmdCorner,
    CmdDelete,
    CmdDrc,
    CmdDump,
    CmdEdit,
    CmdErase,
    CmdExpand,
    CmdExtract,	
    CmdFeedback,
    CmdFill,
    CmdFindBox,
    CmdFlush,
    CmdGetcell,
    CmdIdentify,
    CmdLabel,
    CmdLoad,
    CmdMove,
    CmdPaint,
    CmdSave,
    CmdSee,
    CmdSideways,
    CmdStretch,
    CmdUnexpand,
    CmdUpsidedown,
};

/*
 * ----------------------------------------------------------------------------
 *
 * MgcLayoutCmdWrapper --
 *
 * Tcl command procedure!
 * Called back by tcl interp for magic layout commands
 *
 * Results:
 *	TODO.
 *
 * Side effects:
 *	Command is executed.
 *	
 * ----------------------------------------------------------------------------
 */
int
mgcLayoutCmdWrapper(func,interp,argc,argv)
   void func();
   Tcl_Interp *interp;
   int argc;
   char *argv[];
{
  int i;
  TxCommand cmd;
  Layout *w;

  CMD_BEGIN(interp);

  /* get current layout window */
  w = LayCurWindow();
  ASSERT(w,"mgcLayoutCmdWrapper");  

  /* Increment Magic command number */
  MgcCommandNumber++;

  /* fill argc and argv into command struc. */
  ASSERT(argc<=TX_MAXARGS,"mgcLayoutCmdWrapper");
  cmd.tx_argc = argc;
  for(i=0; i<argc; i++)
  {
      cmd.tx_argv[i] = argv[i];
  }

  /* Finally call the Magic command routine */
  (func)(w, &cmd);

  CMD_RETURN(interp);
}


/*
 * ----------------------------------------------------------------------------
 *
 * MgcLayoutInit --
 *
 * Register the Magic Layout commands in the above tables with tcl.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Register Magic layout commands.
 *	
 * ----------------------------------------------------------------------------
 */

void
mgcLayoutInit(Tcl_Interp *interp)
{
  char **commandp = mgcLayoutCmds;
  Void (**funcp)() = mgcLayoutFuncs; 

  for(;*commandp;commandp += 3,funcp++)
  {
      char c;
      int nameLength;
      Tcl_DString name,doc;

      /* get command name */
      for(nameLength=0; c=(*commandp)[nameLength]; nameLength++)
      {
	if( c==' ' || c=='\t' || c=='\n') break;
      }
      Tcl_DStringInit(&name);
      Tcl_DStringAppend(&name,":",-1);
      Tcl_DStringAppend(&name,*commandp,nameLength);

      /* build doc string */
      Tcl_DStringInit(&doc);
      Tcl_DStringAppend(&doc,"\nUsage:   :",-1);
      Tcl_DStringAppend(&doc,commandp[0],-1);
      Tcl_DStringAppend(&doc,"\n\n",-1);
      Tcl_DStringAppend(&doc,commandp[2],-1);

      /* register with tcl */
      MnDocCreateCommand(interp, 
		  Tcl_DStringValue(&name), 
		  mgcLayoutCmdWrapper,
		  (ClientData) *funcp,
		  (Tcl_CmdDeleteProc *) NULL,
		  commandp[1],  /* desc */
		  Tcl_DStringValue(&doc) 
		  );

      /* clean up */
      Tcl_DStringFree(&name);
      Tcl_DStringFree(&doc);
  }
}


