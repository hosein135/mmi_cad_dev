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
 * layMain.c --
 *
 *	Layout widgets.
 *
 * Copyright (c) 1990-1993 The Regents of the University of California.
 * All rights reserved.
 *
 * Permission is hereby granted, without written agreement and without
 * license or royalty fees, to use, copy, modify, and distribute this
 * software and its documentation for any purpose, provided that the
 * above copyright notice and the following two paragraphs appear in
 * all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 */

#ifndef lint
static char rcsid[] = "$Header$";
#endif

#include <stdlib.h>
#include <tk.h>
#include "magic.h"
#include "main.h"
#include "stack.h"
#include "styles.h"
#include "memory.h"
#include "units.h"
#include "layout.h"
#include "layint.h"
#include "graphics.h"

/* some defaults for layout widgets */
#define DEF_LAYOUT_HEIGHT		"200"
#define DEF_LAYOUT_WIDTH		"200"
#define DEF_LAYOUT_XSCROLL_COMMAND	""
#define DEF_LAYOUT_YSCROLL_COMMAND	""

/*
 * Information used for parsing configuration specs:
 */
/* type argvName dbName dbClass defValue offset flags custom */
static Tk_ConfigSpec configSpecs[] = {
    {TK_CONFIG_INT, "-height", "height", "Height",
	DEF_LAYOUT_HEIGHT, Tk_Offset(Layout, lay_heightReq), 0},
    {TK_CONFIG_INT, "-width", "width", "Width",
	DEF_LAYOUT_WIDTH, Tk_Offset(Layout, lay_widthReq), 0},
    {TK_CONFIG_STRING, "-xscrollcommand", "xScrollCommand", "ScrollCommand",
	DEF_LAYOUT_XSCROLL_COMMAND, Tk_Offset(Layout, lay_xScrollCmd),
	TK_CONFIG_NULL_OK},
    {TK_CONFIG_STRING, "-yscrollcommand", "yScrollCommand", "ScrollCommand",
	DEF_LAYOUT_YSCROLL_COMMAND, Tk_Offset(Layout, lay_yScrollCmd),
	TK_CONFIG_NULL_OK},
    {TK_CONFIG_END, (char *) NULL, (char *) NULL, (char *) NULL,
	(char *) NULL, 0, 0}
};

/* Forward declarations for procedures defined later in this file */ 
static int  layoutConfigure(Tcl_Interp *interp,
			    Layout *layoutPtr, int argc, char **argv,
			    int flags);
static int layoutCmd(ClientData clientData, Tcl_Interp *interp, 
			 int argc, char **argv);
static void layoutDestroy(ClientData clientData);
static void layoutEventProc(ClientData clientData, XEvent *eventPtr);
static int layoutWidgetCmd(ClientData clientData,
			    Tcl_Interp *interp, int argc, char **argv);

/* Internal variables - global within this module */
Layout *layTopWindow = NULL;		/* the topmost layout window */
Layout *layBottomWindow = NULL;	/* ...and the bottom layout window */

/*
 * A mask of the current window IDs, as well as a limit on the number of
 * Layoutwindows we can create.
 *
 * (The limit is needed since expansion masks (see CellUse struc in database.h)
 * need one bit for each layout window.)
 *
 * Special Layout windows share context 1, and are not included in
 * widnCurNumWindows
 */
static layBitMask = 1;
static laySpecialBitMask = 1;

static int windMaxWindows = LAY_MAX_WINDOW_CONTEXTS -1;
static int windCurNumWindows = 0;

/* these vars linked to LAY_SCROLL_UNIT and LAY_SCROLL_PAGE tcl vars */
static double layScrollUnit = .15;  /* fraction of window to more on scroll pump */ 
static double layScrollPage = .85;  /* fraction of window to move on scroll page */


/*
 * ----------------------------------------------------------------------------
 * windUnlink --
 *
 *	Unlink a window from the doubly linked list of windows.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The window is unlinked.
 * ----------------------------------------------------------------------------
 */

void windUnlink(Layout *w)
{
    ASSERT(w != (Layout *) NULL, "windUnlink");
    ASSERT(layTopWindow != (Layout *) NULL, "windUnlink");
    ASSERT(layBottomWindow != (Layout *) NULL, "windUnlink");
    ASSERT(layTopWindow->lay_prev == (Layout *) NULL, "windUnlink");
    ASSERT(layBottomWindow->lay_next == (Layout *) NULL, "windUnlink");

    if ( (layTopWindow == w) || (layBottomWindow == w) )
    {
	if (layTopWindow == w)
	{
	    layTopWindow = w->lay_next;
	    if (layTopWindow != (Layout *) NULL)
		layTopWindow->lay_prev = (Layout *) NULL;
	}
	if (layBottomWindow == w)
	{
	    layBottomWindow = w->lay_prev;
	    if (layBottomWindow != (Layout *) NULL)
		layBottomWindow->lay_next = (Layout *) NULL;
	}
    }
    else
    {
       w->lay_next->lay_prev = w->lay_prev;
       w->lay_prev->lay_next = w->lay_next;
    }

    w->lay_next = (Layout *) NULL;
    w->lay_prev = (Layout *) NULL;
}


/*
 * ----------------------------------------------------------------------------
 * WindSearch --
 *
 *	Search for all of the Layout windows that contain a particular
 *	surface area, whether exposed or not.
 *
 * Results:
 *	if func ever returns non-zero, WindSearch() terminates search and
 *      returns with the same result.  Otherwise WindSearch() returns 0.
 *
 * Side effects:
 *	Calls the function 'func' for each window that matches. 'func' should
 *	be of the form
 *
 *	    int func(window, clientData)
 *		Layout *window;		
 *		ClientData clientData;
 *	    {
 *	    }
 *
 *	Window is the window that matched the search, and clientData is the
 *	clientData parameter supplied to this procedure.
 *	If the function returns a non-zero value the search is aborted, and
 *	that value is returned.  Otherwise the search continues and 0 is
 *	returned.
 * ----------------------------------------------------------------------------
 */

int
WindSearch(CellUse *rootUse, 
                         	/* root use we are looking for.  
				 * If NULL then look for
				 * any root.
				 */
	   Rect *surfaceArea, 
                      		/* The area that we are looking for in surface
				 * coordinates.  If NULL then match without
				 * regard to the area in the window.
				 */
	   int (*func) (/* ??? */), 
                  		/* The function to call with each window
				 * that matches.
				 */
	   ClientData clientData)
                          	/* The client data to be passed to the caller's
				 * function.
				 */
{
    Layout *w;
    int res = 0;

    for (w = layTopWindow; w != (Layout *) NULL; w = w->lay_next)
    {
	if ( !rootUse || w->lay_rootUse==rootUse ) 
	{
	    if (surfaceArea == (Rect *) NULL)
	    {
		res = (*func)(w, clientData);
		if (res != 0) return res;
		continue; /* continue on to next window */
	    }
	    else if (GEO_TOUCH(surfaceArea, &(w->lay_dbArea) ))
	    {
		res = (*func)(w, clientData);
		if (res != 0) return res;
	    }
	}
    }
    return 0;
}


/*
 * ----------------------------------------------------------------------------
 *
 * layInitialLoad --
 *
 * Called by layoutCmd() to load initial cell into new window
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	load view of box if box exists, otherwise new cell.
 *	
 * ----------------------------------------------------------------------------
 */
static void 
layInitialLoad(Layout *window)
{
    CellDef *boxDef;
    Rect box;
    int  expand;
   
    /* if box exists, load view of box into window */
    if (ToolGetBox(&boxDef, &box) && !(boxDef->cd_flags&CD_INTERNAL))
    {
	LayloadWindow(window, boxDef->cd_name);

	/* Zoom in on the box, leaving a 10% border or at least 2 units
	 * on each side.
	 */
	
	expand = (box.r_xtop - box.r_xbot)/20;
	if (expand < 2) expand = 2;
	box.r_xtop += expand;
	box.r_xbot -= expand;
	expand = (box.r_ytop - box.r_ybot)/20;
	if (expand < 2) expand = 2;
	box.r_ytop += expand;
	box.r_ybot -= expand;
	LayFrame(window, &box);
    }
    else
    {
        /* load "UNNAMED" cell */
	LayloadWindow(window, (char *) NULL);
    }
}


/*
 * ----------------------------------------------------------------------------
 *
 * layPaletteLoad --
 *
 * Called by layoutCmd() to load __PALETTE__ into special windows
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	creates __PALETTE__ if it doesn't already exist.
 *	
 * ----------------------------------------------------------------------------
 */
static void 
layPaletteLoad(Layout *window)
{
    CellDef *palDef;

    /* Make sure internal cell __PALETTE__ exists */
    palDef = DBCellLookDef("__PALETTE__");
    if (palDef == (CellDef *) NULL)
    {
        UndoDisable();
        palDef = DBCellNewDef("__PALETTE__",(char *) NULL);
        ASSERT(palDef != (CellDef *) NULL, "SelectInit");
        DBCellSetAvail(palDef);
	palDef->cd_flags |= CD_INTERNAL;
        UndoEnable();
    }

    /* load __PALETTE__ */
    LayloadWindow(window, "__PALETTE__");
}


/*
 *--------------------------------------------------------------
 *
 * layoutCmd --
 *
 *	This procedure is invoked to process the "Layout", Tcl
 *	command.
 *
 * Results:
 *	A standard Tcl result.
 *
 * Side effects:
 *      Open new layout window.
 *
 *--------------------------------------------------------------
 */


#define layout_DESC "Create layout widget" 

#define layout_DOC "
 Usage:
	layout pathName ?options? 

 Builds tcl style widget for layout window.
"

static int
layoutCmd(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
    register Layout *l;
    bool special;

    CMD_BEGIN(interp);

    /* check arg count */
    if (argc < 2) {
	MsgErrorF("wrong # args:  should be \"%s pathName ?options?\"", argv[0]);
	CMD_RETURN(interp);
    }

    /* Check for "-special" arg.  (used for palette entries.) 
     * must immediately follow path (second arg) 
     */ 
    special = (argc >= 3 && (strcmp(argv[2],"-special") == 0));
    
    /* check Layout widget count
     * (one reason for maximum is that expansion-masks in database CellUse strucs 
     *  alloc one bit per Layout widget, hence max of 32 Layout widgets)
     */  
    if (!special && windCurNumWindows + 1 > windMaxWindows) 
    {
        MsgErrorF("Can't have more than %d layout widgets.", windMaxWindows);
	CMD_RETURN(interp);
    }

    /*** alloc and initialize Layout struc ***/
    CALLOC(Layout *, l, sizeof(Layout));

    /*** allocate free bit from context bit mask to window ***/
    if(special)
    {
        /* special windows share reserved context (always set in layBitMask) */
        l->lay_bitmask == laySpecialBitMask;
    }
    else	
    {
      int newBitMask;

      newBitMask = (layBitMask + 1) | layBitMask;
      if (newBitMask > LAY_ALL_WINDOWS) 
      {	
	FREE(l);

	MsgErrorF("Too many Layout windows - can't create new one.\n");
	CMD_RETURN(interp);
      }

      l->lay_bitmask   = newBitMask ^ layBitMask;
      layBitMask = newBitMask;
    }

    /*** Create new Tk window ***/
    l->lay_tkWin = Tk_CreateWindowFromPath(interp, 
					 MainTkWin, 
					 argv[1], 
					 (char *) NULL);
    if (l->lay_tkWin == NULL) 
    {
        if(!special) layBitMask &= ~(l->lay_bitmask);
	FREE(l);
	MsgErrorF("TK Window creation failed.\n");
	CMD_RETURN(interp);
    }
    Tk_SetClass(l->lay_tkWin, "Layout");

    /* have X server keep backing store */
    {
      XSetWindowAttributes attributes;
      attributes.backing_store = WhenMapped; 

      Tk_ChangeWindowAttributes(l->lay_tkWin,
				CWBackingStore, 
				&attributes);
    }

    /*** initialize fields in Layout struc ***/
    l->lay_display = Tk_Display(l->lay_tkWin);
    l->lay_interp = interp;
    l->lay_widthReq = 0;
    l->lay_heightReq = 0;
    l->lay_genOverlay = NULL;
    l->lay_dbAreaReq.r_xbot = 0;
    l->lay_dbAreaReq.r_ybot = 0;
    l->lay_dbAreaReq.r_xtop = 1;
    l->lay_dbAreaReq.r_ytop = 1;
    l->lay_xScrollCmd = NULL;
    l->lay_yScrollCmd = NULL;
    l->lay_rootUse =  NULL;
    l->lay_genRedraw = (ClientData) DBPlaneNew((ClientData) TT_SPACE);

    l->lay_flags = Lay_SEELABELS | Lay_SEEFLYLINES |  Lay_SEEINSTANCENAMES | 
      Lay_SEEINSTANCEPORTS;  
    if(special) l->lay_flags |= Lay_SPECIAL | Lay_ALLSAME;

    l->lay_watchPlane = -1;
    l->lay_labelExtents.r_xbot = 0;
    l->lay_labelExtents.r_ybot = 0;
    l->lay_labelExtents.r_xtop = 0;
    l->lay_labelExtents.r_ytop = 0;
    l->lay_labelMarkSize = 0; 
    l->lay_gridFineRect.r_xbot = 0;
    l->lay_gridFineRect.r_ybot = 0;
    l->lay_gridFineRect.r_xtop = 1;
    l->lay_gridFineRect.r_ytop = 1;
    l->lay_gridCoarseRect.r_xbot = 0;
    l->lay_gridCoarseRect.r_ybot = 0;
    l->lay_gridCoarseRect.r_xtop = 10;
    l->lay_gridCoarseRect.r_ytop = 10;
    l->lay_visibleLayers = DBAllTypeBits;
    l->lay_hlErase = DBPlaneNew((ClientData) TT_SPACE);
    l->lay_hlRedrawDB = DBPlaneNew((ClientData) TT_SPACE);
    l->lay_labelSize = 0;
    l->lay_lastPixelsPerDB = -1;
    l->lay_lastDBArea.r_xbot = 0;
    l->lay_lastDBArea.r_ybot = 0;
    l->lay_lastDBArea.r_xtop = -1;
    l->lay_lastDBArea.r_ytop = -1;
    l->lay_lastLabelSizeFactor = -1;
    l->lay_lastLabelMinSelectedMark = -1;
    {
      int i;
      for(i=0; i<LAY_TEXT_STYLE_TABLE_SIZE; i++)
      {
	l->lay_textAnnotations[i] = NULL;
      }
    }
    l->lay_lineAnnotations = NULL;
    l->lay_dotAnnotations = NULL;

    /* Insert Layout struc in (doubly linked) list, and increment count */
    l->lay_next = layTopWindow;
    l->lay_prev = (Layout *) NULL;
    if (layTopWindow == (Layout *) NULL)
    {
	layBottomWindow = l;
    }
    else
    {
	layTopWindow->lay_prev = l;
    }
    layTopWindow = l;
    if(!special) windCurNumWindows++;

    /* make current */
    layCurSetWindow(l);

    /* setup event handlers */
    /* (mask defs in /usr/include/X11/X.h) */
    if(!special)
    {
        Tk_CreateEventHandler(l->lay_tkWin, 
            ExposureMask |
            StructureNotifyMask |
	    KeyPressMask |
            ButtonPressMask |
            EnterWindowMask |
            LeaveWindowMask |
            PointerMotionMask,
	    layoutEventProc, (ClientData) l);
    }
    else
    {  
        Tk_CreateEventHandler(l->lay_tkWin, 
            ExposureMask |
            StructureNotifyMask,
	    layoutEventProc, (ClientData) l);
    }

    /* create widget tcl command */
    Tcl_CreateCommand(interp, Tk_PathName(l->lay_tkWin), layoutWidgetCmd,
	    (ClientData) l, (void (*)()) NULL);

    /* skip past args already processed */
    if(special)
    {
        argc=argc-3;
	argv=argv+3;
    }
    else
    {
        argc=argc-2;
	argv=argv+2;
    }

    /* configure widget, according to remaining args*/
    if (layoutConfigure(interp, l, argc, argv, 0)  != TCL_OK) 
    {
	Tk_DestroyWindow(l->lay_tkWin);

	/* pass error to caller */
	MsgErrorF(interp->result);
	CMD_RETURN(interp); 
    }

    /* load cell into new window */
    /* (needs to be after layoutConfigure, so that lay_area is correct) */ 
    if(special)
    {
        /* special Layout window, load __PALETTE__ */
        layPaletteLoad(l);
    }
    else
    {
        layInitialLoad(l);
    }

    /* return */
    interp->result = Tk_PathName(l->lay_tkWin);
    CMD_RETURN(interp);
}

/*
 *--------------------------------------------------------------
 *
 * layWidgetVisibleSubCmd --
 *
 *      Called by layoutWidgetCmd() to implement visible subcommand.
 *
 * Results:
 *	A standard Tcl result.
 *
 * Side Effects:
 *      Tcl Result set to list of currently visible layers.
 *
 *--------------------------------------------------------------
 */

static int
layWidgetVisibleSubCmd(Layout *l, Tcl_Interp *interp,int argc, char **argv)
{
    int i;
    TileTypeBitMask *pvis = &(l->lay_visibleLayers);

    /* check arg count */
    if(argc!=2) goto usage;
  
    for (i = TT_SELECTBASE; i < DBNumUserLayers; i++)
    {
        if (TTMaskHasType(pvis, i))
        {
            Tcl_AppendResult(interp, DBTypeLongName(i)," ",NULL);
	}
    }
    return TCL_OK;

    usage:
    Tcl_AppendResult(interp, "Usage: ",	argv[0], " visible", (char *) NULL);

    return TCL_ERROR;
}


/*
 *--------------------------------------------------------------
 *
 * layoutWidgetCmd --
 *
 *	This procedure is invoked to process the Tcl command
 *	that corresponds to a layout widget.
 *
 * Results:
 *	A standard Tcl result.
 *
 * Side effects:
 *      Depends.
 *
 *--------------------------------------------------------------
 */

/* scroll the view */
static void
layScroll(Layout *w, Point *offset)
{
  Rect newArea = w->lay_dbArea;

  newArea.r_xbot += offset->p_x;
  newArea.r_ybot += offset->p_y;
  newArea.r_xtop += offset->p_x;
  newArea.r_ytop += offset->p_y;

  LayFrame(w, &newArea);
}

static int
layoutWidgetCmd(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
    register Layout *l = (Layout *) clientData;
    int result = TCL_OK;
    int length;
    char c;

    /* check arg count */
    if (argc < 2) {
	sprintf(interp->result,
		"wrong # args: should be \"%.50s option [arg arg ...]\"",
		argv[0]);
	return TCL_ERROR;
    }

    Tk_Preserve((ClientData) l);
    c = argv[1][0];
    length = strlen(argv[1]);
    if ((c == 'c') && (strncmp(argv[1], "configure", length) == 0)) {
	if (argc == 2) {
	    result = Tk_ConfigureInfo(interp, l->lay_tkWin, configSpecs,
		    (char *) l, (char *) NULL, 0);
	} else if (argc == 3) {
	    result = Tk_ConfigureInfo(interp, l->lay_tkWin, configSpecs,
		    (char *) l, argv[2],
		    0);
	} else {
	    result = layoutConfigure(interp, l, argc-2, argv+2,
		    TK_CONFIG_ARGV_ONLY);
	}
    }
    else if ((c == 'f') && (strncmp(argv[1], "frame", length) == 0))
    {
        /* check arg count */
        if(argc!=2 && argc!=6) goto frameUsage;
	  
        /* if coords given, reframe */
        if(argc==6)
	{
	  Rect newFrame;
	  
	  /* check for valid coords */
	  if(!UnitsValidS(argv[2]) ||
	     !UnitsValidS(argv[3]) ||
	     !UnitsValidS(argv[4]) ||
	     !UnitsValidS(argv[5])) goto frameUsage;

	  /* reframe */
          newFrame.r_ll.p_x = UnitsS2I(argv[2]);
	  newFrame.r_ll.p_y = UnitsS2I(argv[3]);
          newFrame.r_ur.p_x = UnitsS2I(argv[4]);
          newFrame.r_ur.p_y = UnitsS2I(argv[5]);
	  LayFrame(l, &newFrame); 
	}

	/* return current frame */
	{
          Tcl_AppendResult(interp,UnitsI2S(l->lay_dbArea.r_xbot)," ",NULL);
          Tcl_AppendResult(interp,UnitsI2S(l->lay_dbArea.r_ybot)," ",NULL);
          Tcl_AppendResult(interp,UnitsI2S(l->lay_dbArea.r_xtop)," ",NULL);
          Tcl_AppendResult(interp,UnitsI2S(l->lay_dbArea.r_ytop)," ",NULL);
	}

	result = TCL_OK;
    } 
    else if ((c == 'v') && (strncmp(argv[1], "visible", length) == 0))
    {

	/* return currently visible layers */
	result = layWidgetVisibleSubCmd(l,interp,argc,argv);
    } 
    else if ((c == 'x') && (strncmp(argv[1], "xscroll", length) == 0))
    {
	if(argc<3) goto xscrollUsage;

	if(strcmp(argv[2],"scroll")==0)
	{
	  Point offsetDB;
	  if(argc!=5) goto xscrollUsage;

	  offsetDB.p_x = 
	    (atoi(argv[3]) + 0.0) * 
	      (l->lay_dbArea.r_xtop - l->lay_dbArea.r_xbot) *
		(strcmp(argv[4],"units")==0 ? layScrollUnit : layScrollPage);
	  offsetDB.p_y = 0;


	  /* scroll */
	  layScroll(l, &offsetDB);
	}
	else if(strcmp(argv[2],"moveto")==0)
	{
	  Rect frame = l->lay_dbArea;
	  Rect *bbox = &l->lay_rootUse->cu_def->cd_bbox;
	  int size = bbox->r_xtop - bbox->r_xbot;

	  if(argc!=4) goto xscrollUsage;
	  frame.r_xbot = atof(argv[3]) * (bbox->r_xtop - bbox->r_xbot) 
	    + bbox->r_xbot;
	  frame.r_xtop = (l->lay_dbArea.r_xtop - l->lay_dbArea.r_xbot)
	    + frame.r_xbot;

	  LayFrame(l,&frame);
	}
	else
	{
	  goto xscrollUsage;
	}

	result = TCL_OK;
    }    
    else if ((c == 'y') && (strncmp(argv[1], "yscroll", length) == 0))
    {
	if(argc<3) goto yscrollUsage;

	if(strcmp(argv[2],"scroll")==0)
	{
	  Point offsetDB;
	  if(argc!=5) goto xscrollUsage;

	  offsetDB.p_x = 0;
	  offsetDB.p_y = 
	    (0.0 - atoi(argv[3])) * 
	      (l->lay_dbArea.r_ytop - l->lay_dbArea.r_ybot) *
		(strcmp(argv[4],"units")==0 ? layScrollUnit : layScrollPage);

	  /* scroll */
	  layScroll(l, &offsetDB);
	}
	else if(strcmp(argv[2],"moveto")==0)
	{
	  Rect frame = l->lay_dbArea;
	  Rect *bbox = &l->lay_rootUse->cu_def->cd_bbox;
	  int size = bbox->r_ytop - bbox->r_ybot;

	  if(argc!=4) goto xscrollUsage;

	  frame.r_ytop = bbox->r_ytop 
	    - atof(argv[3]) * (bbox->r_ytop - bbox->r_ybot);
	  frame.r_ybot = frame.r_ytop 
	    - (l->lay_dbArea.r_ytop - l->lay_dbArea.r_ybot);

	  LayFrame(l,&frame);
	}
	else
	{
	  goto yscrollUsage;
	}

	result = TCL_OK;
    }    
    else 
    {
	sprintf(interp->result,
		"bad option \"%.50s\":  must be"
		" configure, frame, mha, visible, xscroll or yscroll", argv[1]);
	goto error;
    }

    Tk_Release((ClientData) l);
    return result;

    /*** error handling ***/

    frameUsage:
    Tcl_AppendResult(interp, "Usage: ",
		argv[0],
		" frame ?lowerLeftX lowerLeftY upperRightX upperRightY?", 
		(char *) NULL);
    goto error;

    xscrollUsage:
    Tcl_AppendResult(interp, 
		     "Usage:\n\t",
		     argv[0], 
		     " xscroll scroll <number> [ unit | page ]\n", 
		     "or\n\t",
		     argv[0], 
		     " xscroll moveto <fraction>\n", 
		     (char *) NULL);
    goto error;

    yscrollUsage:
    Tcl_AppendResult(interp, 
		     "Usage:\n\t",
		     argv[0], 
		     " yscroll scroll <number> [ units | pages ]\n", 
		     "or\n\t",
		     argv[0], 
		     " yscroll moveto <fraction>\n", 
		     (char *) NULL);

    goto error;

    error:
    Tk_Release((ClientData) l);
    return TCL_ERROR;
}

/*
 *----------------------------------------------------------------------
 *
 * layoutDestory --
 *
 *	This procedure is invoked by Tk_EventuallyFree or Tk_Release
 *	to clean up the internal structure of a Layout at a safe time
 *	(when no-one is using it anymore).
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Everything associated with the widget is freed up.
 *
 *----------------------------------------------------------------------
 */

static void
layoutDestroy(clientData)
    ClientData clientData;		/* Info about entry widget. */
{
    register Layout *l = (Layout *) clientData;
    
    if(!(l->lay_flags & Lay_SPECIAL)) layBitMask &= ~(l->lay_bitmask);
    DBFreePaintPlane(l->lay_hlErase);
    DBFreePaintPlane(l->lay_hlRedrawDB);
    TiFreePlane(l->lay_hlErase);
    TiFreePlane(l->lay_hlRedrawDB);
    
    /*
     * Free up all the stuff that requires special handling, then
     * let Tk_FreeOptions handle all the standard option-related
     * stuff.
     */

    Tk_FreeOptions(configSpecs, (char *) l, l->lay_display,0);

    /* TODO: unlink Layout window from list */
    FREE(l);
}


/*
 *----------------------------------------------------------------------
 *
 * layoutConfigure --
 *
 *	This procedure is called to process an argv/argc list, plus
 *	the Tk option database, in order to configure (or
 *	reconfigure) a Layout widget.
 *
 * Results:
 *	The return value is a standard Tcl result.  If TCL_ERROR is
 *	returned, then interp->result contains an error message.
 *
 * Side effects:
 *	Configuration information, such as text string, colors, font,
 *	etc. get set for l;  old resources get freed, if there
 *	were any.  The Layout is redisplayed.
 *
 *----------------------------------------------------------------------
 */

static int
layoutConfigure(interp, l, argc, argv, flags)
    Tcl_Interp *interp;		/* Used for error reporting. */
    register Layout *l;	/* Information about widget;  may or may
				 * not already have values for some fields. */
    int argc;			/* Number of valid entries in argv. */
    char **argv;		/* Arguments. */
    int flags;			/* Flags to pass to Tk_ConfigureWidget. */
{
    unsigned long mask;

    /* parse args, and alloc resources */
    if (Tk_ConfigureWidget(interp, l->lay_tkWin, configSpecs,
	    argc, argv, (char *) l, flags) != TCL_OK) {
	return TCL_ERROR;
    }

    /* set window size  */
    Tk_GeometryRequest(l->lay_tkWin, l->lay_widthReq, l->lay_heightReq);

    /* Set window area in pixel coordinates (reset on ConfigureNotify events) */
    l->lay_area.r_xbot = 0;
    l->lay_area.r_xtop = l->lay_widthReq-1;
    l->lay_area.r_ybot = 0;
    l->lay_area.r_ytop = l->lay_heightReq-1;
    
    return TCL_OK;
}


/*
 *--------------------------------------------------------------
 *
 * layoutEventProc --
 *
 *	This procedure is invoked by the Tk dispatcher for 
 *	various X events in Layout window.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	When the window gets deleted, internal structures get
 *	cleaned up.  When it gets exposed, it is redisplayed.
 *
 *--------------------------------------------------------------
 */

static void
layoutEventProc(clientData, eventPtr)
    ClientData clientData;	/* Information about window. */
    XEvent *eventPtr;		/* Information about event. */
{
    Layout *l = (Layout *) clientData;

    if (l->lay_tkWin==NULL) return;

    switch(eventPtr->type)
    {
        case Expose:
        {
	    Rect changeRect;
	    XExposeEvent *exposeEvent = (XExposeEvent*) eventPtr;

	    changeRect.r_xbot = exposeEvent->x;
            changeRect.r_xtop = exposeEvent->x + exposeEvent->width -1;
	    changeRect.r_ybot = 
	        layXToPixel(l, exposeEvent->y + exposeEvent->height -1);
	    changeRect.r_ytop =
	        layXToPixel(l, exposeEvent->y);
	    /* DEBUG
	    fprintf(stderr,"DEBUG Expose w=%d h=%d\n",
		    exposeEvent->width, exposeEvent->height);
	    */

	    /* Schedule redisplay of changed area */
	    LayChangedWindow(l, &changeRect);
	    break;

	}

        case ConfigureNotify: 
	{
            /* Reset window screen area */
            l->lay_area.r_xbot = 0;
            l->lay_area.r_xtop = Tk_Width(l->lay_tkWin)-1;
            l->lay_area.r_ybot = 0;
            l->lay_area.r_ytop = Tk_Height(l->lay_tkWin)-1;

	    /* reframe (restore map from db to window) */
	    LayFrame(l,NULL);

	    break;
	}

	/* Key press events trigger here only if tcl focus cmd
         * was issued to make this the focus window.
         */
	case KeyPress:
        {
	    XKeyEvent *keyEvent = (XKeyEvent*) eventPtr;
/*	    fprintf(stderr,"DEBUG: Key pressed.\n"); */
	    layPointSetX(keyEvent->x,keyEvent->y);
	    break;
	}

        /* TODO:  redundant now that we are tracking motion? */
	case ButtonPress:
	{
	    XButtonEvent *buttonEvent = (XButtonEvent*) eventPtr;
/*	    fprintf(stderr,"DEBUG:  Button pressed.\n"); */
	    layPointSetX(buttonEvent->x,buttonEvent->y);
	    break;
	}

        case MotionNotify:
	{    
	    XMotionEvent *motionEvent = (XMotionEvent*) eventPtr;
	    layPointSetX(motionEvent->x,motionEvent->y);
	    break;
	}

	case EnterNotify:
	{
/*	    fprintf(stderr,"DEBUG:  Entering Layout window.\n"); */
	    layCurSetWindow(l);
	    break;
	}

	case LeaveNotify:
	{
/*	    fprintf(stderr,"DEBUG:  Leaving Layout window.\n"); */
/*	    layCurSetWindow(NULL); */
	    break;
	}

    }
}


/*
 *--------------------------------------------------------------
 *
 * layCmdCacheFlush --
 *
 * C Result:
 *	A standard Tcl result.
 *
 *
 *--------------------------------------------------------------
 */

#define lay_cache_flush_DESC "flush layout image (pixmap) cache" 

#define lay_cache_flush_DOC "
 Usage:
	lay_cache_flush
"

static int
layCmdCacheFlush(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
    CMD_BEGIN(interp);

    /* check usage */
    if(argc != 1) goto usage;

    layCacheClear(NULL);

    /* normal return */
    CMD_RETURN(interp);

  usage:
    MsgErrorF("Usage:  %s\n",
	      argv[0]); 
    CMD_RETURN(interp);
}

/*
 * ----------------------------------------------------------------------------
 *
 * LayoutTclInit --
 *
 * Initialize tcl commands for this module.  
 *
 *	
 * ----------------------------------------------------------------------------
 */
void
LayoutTclInit(Tcl_Interp *interp)
{
   MnDocCreateCommand(interp, "layout", layoutCmd,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       layout_DESC,
	       layout_DOC
	       );

   layTclInit(interp);
   layStylesTclInit(interp);
   layColorMapTclInit(interp);
   layTextTclInit(interp);

   MnDocCreateCommand(interp, "lay_cache_flush", layCmdCacheFlush, 
	       (ClientData) NULL,  (Tcl_CmdDeleteProc *) NULL,
	       lay_cache_flush_DESC,
	       lay_cache_flush_DOC);
   

   MnDocLinkVar(interp, "LAY_PAINT_ZOT", 
	       (char *) &layPaintZOT, TCL_LINK_INT,
		"zoomed out redisplay threshold (db_units/pixel)",
		"Computed automatically from technology typical feature size"); 


   MnDocLinkVar(interp, "LAY_DB_UNITS_PER_PIXEL", 
	       (char *) &layDBUnitsPerPixel, 
	       TCL_LINK_INT | TCL_LINK_READ_ONLY,
	       "how far we are zoomed out",
	       NULL);
   MnDocLinkVar(interp, "LAY_PIXELS_PER_DB_UNIT", 
	       (char *) &layPixelsPerDBUnit, 
	       TCL_LINK_INT | TCL_LINK_READ_ONLY,
	       "how far we are zoomed out",
	       NULL);

   MnDocLinkVar(interp, "LAY_SINGLE_PIXEL_THRESHOLD", 
	       (char *) &laySinglePixelThreshold, TCL_LINK_INT,
	       "maximum cell diameter (in pixels) that gets painted with"
	       "single pixel value",
	       NULL);

   MnDocLinkVar(interp, "LAY_STIPPLE_GROUPS", 
		(char *) &layStippleGroups, TCL_LINK_BOOLEAN,
		"controls stippling of style groups during zoomed out redisplay",
		"
if set, style groups are stippled (at last moment) during zoomed
out redisplay.

if reset, no stippling during zoomed out redisplay.
");

   /* coarse paint plane parameters */
   MnDocLinkVar(interp, "LAY_COARSE_RES", 
	       (char *) &layCoarseRes, TCL_LINK_INT,
	       "threshold for using coarse paint planes",
	       "
set automatically, used in coarse redisplay code
negative value turns off coarse redisplay.
");

   MnDocLinkVar(interp, "LAY_COARSE_FACTOR", 
	       (char *) &layCoarseFactor, TCL_LINK_DOUBLE,
	       "factor by which successive versions of redisplay planes get coarser",
	       "");

   MnDocLinkVar(interp, "LAY_COARSE_DATA_FACTOR", 
	       (char *) &layCoarseDataFactor, TCL_LINK_DOUBLE,
	       "minimum factor by which a coarse plane must shrink data",
	       "
If this factor is not met between successive coarse planes,
the less coarse plane is removed.");

   MnDocLinkVar(interp, "LAY_COARSE_MAX_OVERHEAD", 
	       (char *) &layCoarseMaxOverhead, TCL_LINK_DOUBLE,
	       "maximum ratio of total coarse data to corresponding paint data",
	       "
If this ratio is exceeded coarse planes are deleted (starting
with least coarse) until we are back in budget.");

   MnDocLinkVar(interp, "LAY_COARSE_FLUSH_FACTOR", 
	       (char *) &layCoarseFlushFactor, TCL_LINK_DOUBLE,
	       "coarse plane regeneration trigger",
	       "
Maximum changes of paint data relative to size (num tiles) prior to 
complete regeneration of corresponding coarse planes.

Regeneration after massive changes provides mechanism for recreating
previously pruned coarse planes.
");

   MnDocLinkVar(interp, "LAY_RES", 
	       (char *) &layRes, TCL_LINK_DOUBLE,
	       "knob for display resolution (in pixels)",
	       "set automatically, used in coarse redisplay code");

   /* pixmap cache parameters */
   MnDocLinkVar(interp, "LAY_CACHE_MAX_DIM", 
	       (char *) &layCacheMaxDim, TCL_LINK_INT,
	       "Maximum cell dimension (in pixels) for which pixmap cache will"
	       "be considered",
	       NULL);

   MnDocLinkVar(interp, "LAY_CACHE_STIPPLE_METHOD", 
	       (char *) &layCacheStippleMethod, TCL_LINK_BOOLEAN,
	       "if set, stippling is used for clearing prior to group 2 copys",
	       "
XFree86 release 4001 crashes unless this variable is set (1). 
Solaris6 X Server requires that this variable is reset (0).");

   /* box parameters */
   MnDocLinkVar(interp, "LAY_BOX_LINE_WIDTH",  
	       (char *) &layBoxLineWidth, TCL_LINK_INT,
		"width of box lines (in pixels)",
		"controls appearance of box");

   MnDocLinkVar(interp, "LAY_BOX_TARGET_THRESHOLD",  
	       (char *) &layBoxTargetThreshold, TCL_LINK_INT,
		"min box dimension (in pixels), before drawn as target",
		"controls appearance of box");

   MnDocLinkVar(interp, "LAY_BOX_HAIR_BEGIN",  
	       (char *) &layBoxHairBegin, TCL_LINK_INT,
		"target cross hair begin radius (in pixels)",
		"controls appearance of box");

   MnDocLinkVar(interp, "LAY_BOX_HAIR_END",  
	       (char *) &layBoxHairEnd, TCL_LINK_INT,
		"target cross hair end radius (in pixels)",
		"controls appearance of box");

   MnDocLinkVar(interp, "LAY_LABEL_SIZE_FACTOR",  
	       (char *) &layLabelSizeFactor, TCL_LINK_DOUBLE,
		"size of label text (in typical wire widths)",
		"After changing this variable, call lay_changed.");

   MnDocLinkVar(interp, "LAY_LABEL_MIN_SELECTED_MARK",  
	       (char *) &layLabelMinSelectedMark, TCL_LINK_INT,
		"minimum cross radius for selected labels (in pixels)",
		"After changing this variable, call lay_changed.");

   MnDocLinkVar(interp, "LAY_ROTATED_TEXT", 
	       (char *) &layRotatedText, TCL_LINK_BOOLEAN,
	       "if set, rotated text is enabled",
		"text rotation, if enabled, is determined by text alignment");

   /* (grid) origin */
   MnDocLinkVar(interp, "LAY_GRID_ORIGIN_RADIUS",  
	       (char *) &layGridOriginRadius, TCL_LINK_INT,
		"radius of rectangle marking editcell origin (in pixels)",
		"controls appearance of (grid) origin");

   /* grid points */
   MnDocLinkVar(interp, "LAY_GRID_POINT_DIAMETER_FINE",  
	       (char *) &layGridPointDiameterFine, TCL_LINK_INT,
		"size of rectangles marking fine grid points (in pixels)",
		">0 defines diameter of grid points, 
                 <=0 displays grid lines instead of points");   

   MnDocLinkVar(interp, "LAY_GRID_POINT_DIAMETER_COARSE",   
	       (char *) &layGridPointDiameterCoarse, TCL_LINK_INT,
		"size of rectangles marking coarse grid points (in pixels)",
		">0 defines diameter of grid points, 
                 <=0 displays grid lines instead of points");   

   MnDocLinkVar(interp, "LAY_GRID_MIN_PIXEL_PITCH_FINE",   
	       (char *) &layGridMinPixelPitchFine, TCL_LINK_INT,
		"threshold for displaying fine grid",
		NULL);   

   MnDocLinkVar(interp, "LAY_GRID_MIN_PIXEL_PITCH_COARSE",   
	       (char *) &layGridMinPixelPitchCoarse, TCL_LINK_INT,
		"threshold for displaying coarse grid",
		NULL);   

   /* flyline appearance */
   MnDocLinkVar(interp, "LAY_FLYLINE_TIC",  
	       (char *) &layFlyLineTic, TCL_LINK_INT,
		"extension of flyline center tic (in pixels)",
		"controls appearance of flylines with associated text");

   /* scroll amounts */
   MnDocLinkVar(interp, "LAY_SCROLL_UNIT",  
	       (char *) &layScrollUnit, TCL_LINK_DOUBLE,
		"layout widget single step scroll amount"
		"(as fraction of window size)",
		NULL);
   MnDocLinkVar(interp, "LAY_SCROLL_PAGE",  
	       (char *) &layScrollPage, TCL_LINK_DOUBLE,
		"layout widget page scroll amount"
		"(as fraction of window size)",
		NULL);

   MnDocLinkVar(interp, "LAY_SUBCELL_SHOW_UNEXPANDED",
	       (char *) &laySubcellShowUnexpanded, TCL_LINK_BOOLEAN,
	       "control display of unexpanded subcells",
               "if set, bboxes and text are shown for unexpanded subcells");

   MnDocLinkVar(interp, "LAY_MAX_FONT_SIZE",
	       (char *) &GrMaxFontSize, TCL_LINK_INT,
	       "maximum font size available",
               "font sizes 0 through this are available");

}

/*
 * ----------------------------------------------------------------------------
 *
 * LayoutInit --
 *
 * Technology independent module initialization.  
 *
 *	
 * ----------------------------------------------------------------------------
 */

void
LayoutInit()
{
   UndoDisable();

   layStylesInit();
   layTextInit();
   layUndoInit();

   UndoEnable();
}





