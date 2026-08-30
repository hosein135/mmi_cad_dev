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
 * layTcl.c -- Tcl command interface to layout module. 
 * 
 * NOTE: additional tcl commands in:
 *         layMain.c, 
 *         layStyles.c, 
 *         and layColorMap.c
 */

#include <stdio.h>
#include <string.h>
#include <tcl.h>
#include <tk.h>

#include "magic.h"
#include "main.h"
#include "layout.h"
#include "layint.h"
#include "geometry.h"
#include "graphics.h"
#include "styles.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "message.h"
#include "select.h" 
#include "units.h"
#include "utils.h"
#include "debug.h"


/*
 *--------------------------------------------------------------
 *
 * layTextCommand --
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Tcl Result:
 *      Depends on option. 
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define lay_text_DESC "add temporary text annotation to layout widget"

#define lay_text_DOC "
Usage:  lay_text [-tag tag] [-size n] [-text_style name] [-align pos] x y text
        or 
        lay_text [-tag tag] [-clear]

NOTE:  Coordinates need not be on grid.

If no args, lists current text annotations.
-clear to clear all text annotations.
-tag on clear  restricts operation to annotations with matching tag.
-tag on create assigns tag to annotation.

pos is: nw, n, ne, w, c (DEFAULT), e, sw, s or se. 

-size gives small integer specifying text style as follows:
  0 - annotation_small
  1 - annotation_medium (DEFAULT) 
  2 - annotation_large
  3 - annotation_extra_large
NOTE: -size is OBSOLETE, use -text_style instead.

-text_style defines text style to use.  
If no -text_style, -size is used.
If no -text_style or -size, defaults to annotation_medium.
"

static int
layTextCmd(ClientData clientData, 
	   Tcl_Interp *interp, 
	   int argc, 
	   char **argv)
{
    char *cmdName;
    char *tag = NULL;
    int size = 1;
    char *textStyleName = NULL;
    bool clear = FALSE;
    int pos = GEO_CENTER;

    CMD_BEGIN(interp);

    cmdName = *argv;
    argv++; argc--;

    /* Parse command line switchs */
    while(argc>0 && **argv=='-')
    {
      int length = strlen(*argv);
      char c = (*argv)[1];
	
      if(c=='a' && strncmp(*argv,"-align",length)==0)
      {
        argc--; argv++;
      
	if(argc==0) goto usage;
	pos = GeoNameToPos(*argv, FALSE, TRUE);
	if(pos<0) goto usage;
	argc--; argv++;

	continue;
      }
	
      if(c=='c' && strncmp(*argv,"-clear",length)==0)
      {
	argc--; argv++;
	clear = TRUE;
	continue;
      }
	
      if(c=='s' && strncmp(*argv,"-size",length)==0)
      {
	argc--; argv++;

	if(argc==0) goto usage;
	if(sscanf(*argv,"%d",&size)!=1) goto usage;
	argc--; argv++;
        if(size<0 || size>3) goto usage;

	continue;
      }

	
      if(c=='t' && strncmp(*argv,"-text_style",length)==0)
      {
	argc--; argv++;

	if(argc==0) goto usage;
	textStyleName = *argv;
	argc--; argv++;

	continue;
      }
	
      if(c=='t' && strncmp(*argv,"-tag",length)==0)
      {
	argc--; argv++;
	
	if(argc==0) goto usage;
	tag = *argv;
	argc--; argv++;

	continue;
      }

      /* looks like a number not an option */
      if(isdigit(c)) break;

      /* bad switch */
      goto usage;
    }

    /* CLEAR CASE */
    if(clear)
    {
      if(argc>0) goto usage;
      layAnnotateTextClear(layCurrent, tag);
      CMD_RETURN(interp);
    }

    /* LIST CASE */
    if (argc==0)
    {
      int i;

      for(i=0;i <=layTextStyleMax;i++)
      {
	TextAnnotation *ta;

	for(ta = layCurrent->lay_textAnnotations[i];
	    ta;
	    ta = ta->ta_next)
        {

	  /* text style */
	  Tcl_AppendElement(interp, layTextStyleTable[i].ts_name);
	
	  /* location */
	  Tcl_AppendResult(interp, " {", (char *) NULL);
	  Tcl_AppendElement(interp, UnitsF2S(ta->ta_location.pf_x));
	  Tcl_AppendElement(interp, UnitsF2S(ta->ta_location.pf_y));
	  Tcl_AppendResult(interp, "}", (char *) NULL);

	  /* output pos (alignment) */
	  Tcl_AppendElement(interp, GeoPosToName(ta->ta_pos));

	  /* text */
	  Tcl_AppendElement(interp, ta->ta_text);
	
	  /* tag */
	  if(ta->ta_tag) Tcl_AppendElement(interp, ta->ta_tag);

	  Tcl_AppendResult(interp,"\n", (char *) NULL);
	}
      }

      CMD_RETURN(interp);
    }

    /* ADD CASE */
    {
      PointFloat location;
      char *text;
      TextStyle *ts;

      /* x */
      if(argc==0) goto usage;
      if (!UnitsValidSF(*argv)) 
      {
	MsgErrorF("bad coordinate: %s\n", *argv);
	goto usage;
      }
      location.pf_x = UnitsS2F(*argv);
      argv++; argc--;

      /* y */
      if(argc==0) goto usage;
      if (!UnitsValidSF(*argv)) 
      {
	MsgErrorF("bad coordinate: %s\n", *argv);
	goto usage;
      }
      location.pf_y = UnitsS2F(*argv);
      argv++; argc--;

      /* text */
      if(argc == 0) goto usage;
      text = *argv;
      argv++; argc--;

      if(argc>0) goto usage;

      /* get text style */
      if(!textStyleName)
      {
	switch(size)
	{
  	  case 0: 
	    textStyleName = "annotation_small";
	    break;

  	  case 1: 
	    textStyleName = "annotation_medium";
	    break;

  	  case 2: 
	    textStyleName = "annotation_large";
	    break;

  	  case 3: 
	    textStyleName = "annotation_extra_large";
	    break;
	    
	  default:
	    ASSERT(FALSE,"lay_text");
	}
      }
      ts = layTextStyleLookup(textStyleName);
      if(!ts)
      {
	MsgErrorF("Could not find text style '%s'\n", 
		  textStyleName);
	CMD_RETURN(interp);
      }

      /* do it */
      layAnnotateTextAdd(layCurrent,
			 location, 
			 pos,
			 ts->ts_index,
			 text,
			 tag);

      CMD_RETURN(interp);
    }

 usage:
    MsgErrorF("Usage:  %s [-tag tag] [-size n] [-align pos] x y text\nor\n"
	      "%s [-tag tag] [-clear]\n",
	      cmdName, cmdName); 

    CMD_RETURN(interp);
}



/*
 *--------------------------------------------------------------
 *
 * layLineCommand --
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Tcl Result:
 *      Depends on option. 
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define lay_line_DESC "add temporary line annotation to layout widget"

#define lay_line_DOC "
Usage:  lay_line [-tag tag] x1 y1 x2 y2
        or
        lay_line [-tag tag] [-delete n | -clear] 

NOTE:  Coordinates need not be on grid.

If no args, lists current line annotations.
-delete n deletes n-1th text annotation in list (first annotation is 0)
-clear to clear all text annotations.
-tag on clear restricts operation to annotations with matching tag.
-tag on create assigns tag to annotation.
"

static int
layLineCmd(ClientData clientData, 
	   Tcl_Interp *interp, 
	   int argc, 
	   char **argv)
{
    char *cmdName;
    char *tag = NULL;
    bool clear = FALSE;
    bool delete = FALSE;
    int deleteNum;

    CMD_BEGIN(interp);

    cmdName = *argv;
    argv++; argc--;

    /* Parse command line switchs */
    while(argc>0 && **argv=='-')
    {
      int length = strlen(*argv);
      char c = (*argv)[1];
	
      if(c=='c' && strncmp(*argv,"-clear",length)==0)
      {
	argc--; argv++;
	clear = TRUE;
	continue;
      }

      if(c=='d' && strncmp(*argv,"-delete",length)==0)
      {
	argc--; argv++;
	delete = TRUE;

	if(argc==0) goto usage;
	if(sscanf(*argv,"%d",&deleteNum)!=1) goto usage;
	argc--; argv++;
        if(deleteNum<0) goto usage;

	continue;
      }
	
      if(c=='t' && strncmp(*argv,"-tag",length)==0)
      {
	argc--; argv++;
	
	if(argc==0) goto usage;
	tag = *argv;
	argc--; argv++;

	continue;
      }

      /* looks like a number not an option */
      if(isdigit(c)) break;

      /* bad switch */
      goto usage;
    }

    /* CLEAR CASE */
    if(clear)
    {
      if(argc>0) goto usage;
      layAnnotateLineClear(layCurrent, tag);
      CMD_RETURN(interp);
    }

    /* DELETE CASE */
    if(delete)
    {
      if(argc>0) goto usage;

      layAnnotateLineDelete(layCurrent, deleteNum, TRUE /* notify */);
      CMD_RETURN(interp);
    }

    /* LIST CASE */
    if (argc==0)
    {
      LineAnnotation *la;

      for(la = layCurrent->lay_lineAnnotations;
	  la;
	  la = la->la_next)
      {
	
	/* p1 */
	Tcl_AppendResult(interp, " {", (char *) NULL);
	Tcl_AppendElement(interp, UnitsF2S(la->la_p1.pf_x));
	Tcl_AppendElement(interp, UnitsF2S(la->la_p1.pf_y));
	Tcl_AppendResult(interp, "}", (char *) NULL);

	/* p2 */
	Tcl_AppendResult(interp, " {", (char *) NULL);
	Tcl_AppendElement(interp, UnitsF2S(la->la_p2.pf_x));
	Tcl_AppendElement(interp, UnitsF2S(la->la_p2.pf_y));
	Tcl_AppendResult(interp, "}", (char *) NULL);

	/* tag */
	if(la->la_tag) Tcl_AppendElement(interp, la->la_tag);

	Tcl_AppendResult(interp,"\n", (char *) NULL);
      }

      CMD_RETURN(interp);
    }

    /* ADD CASE */
    {
      PointFloat p0,p1;
      char *text;

      /* x1 */
      if(argc==0) goto usage;
      if (!UnitsValidSF(*argv)) 
      {
	MsgErrorF("bad coordinate: %s\n", *argv);
	goto usage;
      }
      p0.pf_x = UnitsS2F(*argv);
      argv++; argc--;

      /* y1 */
      if(argc==0) goto usage;
      if (!UnitsValidSF(*argv)) 
      {
	MsgErrorF("bad coordinate: %s\n", *argv);
	goto usage;
      }
      p0.pf_y = UnitsS2F(*argv);
      argv++; argc--;

      /* x2 */
      if(argc==0) goto usage;
      if (!UnitsValidSF(*argv)) 
      {
	MsgErrorF("bad coordinate: %s\n", *argv);
	goto usage;
      }
      p1.pf_x = UnitsS2F(*argv);
      argv++; argc--;

      /* y2 */
      if(argc==0) goto usage;
      if (!UnitsValidSF(*argv)) 
      {
	MsgErrorF("bad coordinate: %s\n", *argv);
	goto usage;
      }
      p1.pf_y = UnitsS2F(*argv);
      argv++; argc--;

      if(argc>0) goto usage;

      layAnnotateLineAdd(layCurrent, p0, p1, tag); 
      CMD_RETURN(interp);
    }

 usage:
    MsgErrorF("Usage:  %s [-tag tag] x0 y0 x1 y1\nor\n"
	      "%s [-tag tag] [-delete n | -clear]\n",
	      cmdName, cmdName); 

    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * layDotCommand --
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Tcl Result:
 *      Depends on option. 
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define lay_dot_DESC "add temporary dot annotation to layout widget"

#define lay_dot_DOC "
Usage:  lay_dot [-tag tag] [-diameter n] x y 
        or 
        lay_dot [-tag tag] [-delete n | -clear]


NOTE:  Coordinates need not be on grid.

If no args, lists current dot annotations.

-clear to clear all dot annotations 
-delete n deletes n-1th dot annotation in list (first annotation is 0)
-tag on clear restricts operation to annotations with matching tag.
-tag on create assigns tag to annotation.

diameter is in pixels
"

static int
layDotCmd(ClientData clientData, 
	   Tcl_Interp *interp, 
	   int argc, 
	   char **argv)
{
    char *cmdName;
    char *tag = NULL;
    int diameter = 4;
    bool clear = FALSE;
    bool delete = FALSE;
    int deleteNum;

    CMD_BEGIN(interp);

    cmdName = *argv;
    argv++; argc--;

    /* Parse command line switchs */
    while(argc>0 && **argv=='-')
    {
      int length = strlen(*argv);
      char c = (*argv)[1];
	
      if(c=='c' && strncmp(*argv,"-clear",length)==0)
      {
	argc--; argv++;
	clear = TRUE;

	continue;
      }

      if(c=='d' && strncmp(*argv,"-delete",MIN(length,3))==0)
      {
	argc--; argv++;
	delete = TRUE;

	if(argc==0) goto usage;
	if(sscanf(*argv,"%d",&deleteNum)!=1) goto usage;
	argc--; argv++;
        if(deleteNum<0) goto usage;

	continue;
      }
	
      if(c=='d' && strncmp(*argv,"-diameter",MIN(length,3))==0)
      {
	argc--; argv++;

	if(argc==0) goto usage;
	if(sscanf(*argv,"%d",&diameter)!=1) goto usage;
	argc--; argv++;
        if(diameter<1 ) goto usage;

	continue;
      }
	
      if(c=='t' && strncmp(*argv,"-tag",length)==0)
      {
	argc--; argv++;
	
	if(argc==0) goto usage;
	tag = *argv;
	argc--; argv++;

	continue;
      }

      /* looks like a number not an option */
      if(isdigit(c)) break;

      /* bad switch */
      goto usage;
    }

    /* CLEAR CASE */
    if(clear)
    {
      if(argc>0) goto usage;
      layAnnotateDotClear(layCurrent, tag);
      CMD_RETURN(interp);
    }

    /* DELETE CASE */
    if(delete)
    {
      if(argc>0) goto usage;

      layAnnotateDotDelete(layCurrent, deleteNum, TRUE /* notify */);
      CMD_RETURN(interp);
    }

    /* LIST CASE */
    if (argc==0)
    {
      DotAnnotation *da;

      for(da = layCurrent->lay_dotAnnotations;
	  da;
	  da = da->da_next)
      {

	/* diameter */
	{
	  char buf[BUFSIZ];
	  sprintf(buf,"%d",da->da_diameter);
	  Tcl_AppendElement(interp, buf);
	}
	
	/* center */
	Tcl_AppendResult(interp, " {", (char *) NULL);
	Tcl_AppendElement(interp, UnitsF2S(da->da_center.pf_x));
	Tcl_AppendElement(interp, UnitsF2S(da->da_center.pf_y));
	Tcl_AppendResult(interp, "}", (char *) NULL);

	/* tag */
	if(da->da_tag) Tcl_AppendElement(interp, da->da_tag);

	Tcl_AppendResult(interp,"\n", (char *) NULL);
      }

      CMD_RETURN(interp);
    }

    /* ADD CASE */
    {
      PointFloat center;
      char *text;

      /* x */
      if(argc==0) goto usage;
      if (!UnitsValidSF(*argv)) 
      {
	MsgErrorF("bad coordinate: %s\n", *argv);
	goto usage;
      }
      center.pf_x = UnitsS2F(*argv);
      argv++; argc--;

      /* y */
      if(argc==0) goto usage;
      if (!UnitsValidSF(*argv)) 
      {
	MsgErrorF("bad coordinate: %s\n", *argv);
	goto usage;
      }
      center.pf_y = UnitsS2F(*argv);
      argv++; argc--;

      if(argc>0) goto usage;

      layAnnotateDotAdd(layCurrent,
			diameter,
			center,
			tag);
      CMD_RETURN(interp);
    }

 usage:
    MsgErrorF("Usage:  %s [-tag tag] [-diameter n] x y\nor\n"
	      "%s [-tag tag] [-delete n | -clear]\n",
	      cmdName, cmdName); 

    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * layCurBoundingBoxCmd --
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

#define lay_bbox_DESC "get bounding box of rootcell" 

#define lay_bbox_DOC "
 Usage:
	lay_bbox 

  Result:
        xbot ybot xtop ytop 

  Bounding box of (current) rootcell in rootcell coordinates.

  NOTE:  Max commands generally use rootcell coordinates.  These
  differ from the editcell coordinates when doing an edit-in-place.
"

int
layCurBoundingBoxCmd(ClientData clientData, Tcl_Interp *interp, 
		     int argc, char **argv)
{
    Rect *bbox;

    CMD_BEGIN(interp);

    /* check arg count */
    if (argc != 1) 
    {
	Tcl_AppendResult(interp, 
               "Usage:  ", argv[0], (char *) NULL);
	return TCL_ERROR;
    }

    if (layCurrent == NULL) return TCL_OK;
    bbox = DBBBoxCellDef(layCurrent->lay_rootUse->cu_def);
    
    /* return current bounding box in RootCell/user-unit coords */
    Tcl_AppendResult(interp,UnitsI2S(bbox->r_xbot)," ",NULL);
    Tcl_AppendResult(interp,UnitsI2S(bbox->r_ybot)," ",NULL);
    Tcl_AppendResult(interp,UnitsI2S(bbox->r_xtop)," ",NULL);
    Tcl_AppendResult(interp,UnitsI2S(bbox->r_ytop),NULL);

    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * layCurPointCmd --
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Tcl Result:
 *      list of longnames of types adjacent to point.
 *
 * Side Effects:      
 *      if x,y args given, set Current Point accordingly
 *
 *--------------------------------------------------------------
 */


#define lay_point_DESC "get/set coordinates of cursor" 

#define lay_point_DOC "
 Usage:
	lay_point [-no_clip] [-warp] [x y] 

  Returns (root cell) coordinates of cursor (old value on set).  

  If -no_clip, cursor location is not clipped to window.
  If -warp, set X cursor is actually moved to new location
"

int
layCurPointCmd(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
    CellUse *curUse;
    char *cmdName;
    char **coordArgs = NULL;
    bool noClip = FALSE;
    bool warp = FALSE;
    int x = 0;  /* initialize to avoid compiler warnings */
    int y = 0;  /* initialize to avoid compiler warnings */

  CMD_BEGIN(interp);

  /* parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* Parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];
    
    if(c=='n' && strncmp(*argv,"-no_clip",length) == 0) 
    {
      noClip = TRUE;
      argc--;
      argv++;
      continue;
    }

    if(c=='w' && strncmp(*argv,"-warp",length) == 0) 
    {
      warp = TRUE;
      argc--;
      argv++;
      continue;
    }

    if(isdigit(c) || c=='.')
    {
      /* negative coordinate! */
      break;
    }

    /* unrecognized option */
    goto usage;

  } /* end while(argc>0 && **argv=='-')  */

  /* parse coords */
  if(argc!=0)
  {
     if(argc<2) goto usage;
     coordArgs = argv;
     argc -= 2; argv += 2;

     /* check for valid coords */
     if(!UnitsValidS(coordArgs[0]) || 
	!UnitsValidS(coordArgs[1])
	)
     {
       goto usage;
     }

     x = UnitsS2I(coordArgs[0]);
     y = UnitsS2I(coordArgs[1]);
  }

  /* there should be no args left */
  if(argc!=0) goto usage;

  /* if no current layout window 
   * (this should only happen before first layout window created on startup)
   */
  if(!layCurrent) CMD_RETURN(interp);

  /* return current (old) point in RootCell/user-unit coords */
  {
    Point rootPoint;

    LayPointGet(&rootPoint, NULL);

    if(!noClip)
    {
      Rect frame;
      layRectWToDB(layCurrent,&(layCurrent->lay_area),&frame);
      GeoClipPoint(&rootPoint, &frame);
    }

    Tcl_AppendResult(interp,UnitsI2S(rootPoint.p_x)," ",NULL);
    Tcl_AppendResult(interp,UnitsI2S(rootPoint.p_y),NULL);	
  }

  /* If coords given set current point accordingly */
  if (coordArgs) 
  {
    Point newPoint;
	
    if(!layCurrent)
    {
      MsgErrorF("Point not set.  No current root cell!\n");
      CMD_RETURN(interp);
    }

    newPoint.p_x = x;
    newPoint.p_y = y;

    /* set point internally to Max */
    layPointSetDB(&newPoint);

    /* if "warp" set, move X cursor to correspond to point */
    if ( warp ) 
    {
      Point newPointX;
      Tk_Window tkwin = layCurrent->lay_tkWin;
      
      /* compute X-coords for point */ 
      layPointToWindowInt(layCurrent, &newPoint, &newPointX);
      newPointX.p_y = Tk_Height(tkwin) - newPointX.p_y;

      /* move the X cursor */
      XWarpPointer(
		   Tk_Display(tkwin),     /* display */
		   None,                  /* src window */
		   Tk_WindowId(tkwin),    /* dest window */
		   0,                     /* src x */
		   0,                     /* src y */
		   0,                     /* src width */
		   0,                     /* src height */
		   newPointX.p_x,         /* dest x */
		   newPointX.p_y          /* dest y */
		   );
    }
  }
   
  CMD_RETURN(interp);

usage:
  MsgErrorF("Usage:  %s [-no_clip] [-warp] [x y]\n",cmdName);
  CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * layCurBoxCmd --
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Side Effects:      
 *      if 4 args given, set box accordingly.
 *
 *--------------------------------------------------------------
 */

#define lay_box_DESC "get/set box" 

#define lay_box_DOC "
 Usage:
	lay_box ?xbot ybot xtop ytop? 

  Result:
        xbot ybot xtop ytop 

  box location in rootcell coordinates.  (Old location on set.)
"

static int
layCurBoxCmd(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
    CMD_BEGIN(interp);

    /* check usage */
    if ( (argc != 1 && argc != 5)  ||
	 (argc==5 && 
	    ( !UnitsValidS(argv[1]) || 
	      !UnitsValidS(argv[2]) ||
	      !UnitsValidS(argv[3]) || 
	      !UnitsValidS(argv[4]) 
	    )
	 )
       )
    {
        MsgErrorF("Usage:  %s ?lowerLeftX lowerLeftY upperRightX upperRightY?\n",
		  argv[0]); 
	CMD_RETURN(interp);
    }

    /* return current box in CurRoot user-unit coordinates 
     * NOTE: old value returned when setting! 
     */
    {
        Rect rootBox;
	CellDef *boxDef;

	if (layCurrent &&
	    ToolGetBox(&boxDef, &rootBox) && 
	    (boxDef==WINDOW_DEF(layCurrent)))
	{
	  Tcl_AppendResult(interp,UnitsI2S(rootBox.r_ll.p_x)," ",NULL);
	  Tcl_AppendResult(interp,UnitsI2S(rootBox.r_ll.p_y)," ",NULL);
	  Tcl_AppendResult(interp,UnitsI2S(rootBox.r_ur.p_x)," ",NULL);
	  Tcl_AppendResult(interp,UnitsI2S(rootBox.r_ur.p_y),NULL);
	  
	}
    }    

    /* If args present, set box accordingly */
    if (argc == 5) 
    {
        Rect newBox;
	Rect newBoxCanonical;
	
	if(!layCurrent)
	{
	  MsgErrorF("Box not set.  No current root cell!\n");
	  CMD_RETURN(interp);
        }

	newBox.r_ll.p_x = UnitsS2I(argv[1]);
	newBox.r_ll.p_y = UnitsS2I(argv[2]);
	newBox.r_ur.p_x = UnitsS2I(argv[3]);
	newBox.r_ur.p_y = UnitsS2I(argv[4]);

	/* make sure lower left is really lower left */
	GeoCanonicalRect(&newBox,&newBoxCanonical);
       
	LaySetBox(WINDOW_DEF(layCurrent),&newBoxCanonical);
     }

    /* normal return */
    CMD_RETURN(interp);
}



/*
 *--------------------------------------------------------------
 *
 * layFrameCmd --
 *
 * C Result:
 *	A standard Tcl result.
 *
 *--------------------------------------------------------------
 */

#define lay_frame_DESC "get/set view in current window" 

#define lay_frame_DOC "
 Usage:
	lay_frame [xbot ybot xtop ytop] 

  Result:
        xbot ybot xtop ytop 

  current view in rootcell coordinates.  (Old view on set.)
"

static int
layFrameCmd(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
  Layout *l;
  CMD_BEGIN(interp);


  /* check usage */
  if ((argc != 1 && argc != 5)  ||
      (argc==5 && 
       ( !UnitsValidS(argv[1]) || 
	 !UnitsValidS(argv[2]) ||
	 !UnitsValidS(argv[3]) || 
	 !UnitsValidS(argv[4]) 
       )
      )
     )
   {
     MsgErrorF("Usage:  %s [lowerLeftX "
	       "lowerLeftY upperRightX upperRightY]\n",
	       argv[0]); 
     CMD_RETURN(interp);
   }

  /* operate on current window */
  l = LayCurWindow();

  /* return current (old) frame */
  Tcl_AppendResult(interp,UnitsI2S(l->lay_dbArea.r_xbot)," ",NULL);
  Tcl_AppendResult(interp,UnitsI2S(l->lay_dbArea.r_ybot)," ",NULL);
  Tcl_AppendResult(interp,UnitsI2S(l->lay_dbArea.r_xtop)," ",NULL);
  Tcl_AppendResult(interp,UnitsI2S(l->lay_dbArea.r_ytop)," ",NULL);
	  
  /* reframe */
  if(argc==5)
  {
    Rect newFrame;

    /* reframe */
    newFrame.r_ll.p_x = UnitsS2I(argv[1]);
    newFrame.r_ll.p_y = UnitsS2I(argv[2]);
    newFrame.r_ur.p_x = UnitsS2I(argv[3]);
    newFrame.r_ur.p_y = UnitsS2I(argv[4]);
    LayFrame(l, &newFrame); 
  }

  CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * layCurChangedCmd --
 *
 * C Result:
 *	A standard Tcl result.
 *
 *--------------------------------------------------------------
 */

#define lay_changed_DESC "mark current window for redisplay" 

#define lay_changed_DOC "
 Usage:
	lay_changed [-highlights]

 If -highlights, only marks highlights (selection etc.) for redisplay. 

 Note:  Differs from lay_redisplay, in that it does not block for redisplay.
"

static int
layCurChangedCmd(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
  char *cmdName;
  bool highlights = FALSE;

  CMD_BEGIN(interp);

  /* parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];
	
    if(c=='h' && strncmp(*argv,"-highlights",length)==0)
    {
      highlights = TRUE;
      argc--; argv++;

      continue;
    }

    /* unrecognized option */
    goto usage;
  }

  if (argc) goto usage; 

  if(layCurrent)
  {
    if(highlights)
    {
      layChangedWindowHL(layCurrent, NULL, TRUE);
    }
    else
    {
      LayChangedWindow(layCurrent, NULL);
    }
  }
  CMD_RETURN(interp);

usage:    
  MsgErrorF("usage: %s [-highlights]\n", cmdName);
  CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * layCurEditCellCmd --
 *
 * C Result:
 *	A standard Tcl result.
 *
 *--------------------------------------------------------------
 */

#define lay_editcell_DESC "get current edit cell" 

#define lay_editcell_DOC "
 Usage:
	lay_editcell 

  Result:
        name of current edit cell

  NOTE: to set edit cell, use \":edit\" command.
"

static int
layCurEditCellCmd(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
    CellUse *curUse;

    CMD_BEGIN(interp);

    if (argc != 1) goto usage;

    /* if no edit cell, just return "" */
    if (!EditRootDef) 
    {
      CMD_RETURN(interp);
    }

    /* return name of current edit cell def */
    Tcl_AppendResult(interp, EditCellUse->cu_def->cd_name, NULL);
    CMD_RETURN(interp);

usage:
    MsgErrorF("usage: %s", argv[0]);
    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * layCurRedisplayCmd --
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Side Effects:      
 *      if arg given, sets current cell to cell with that name.
 *
 *--------------------------------------------------------------
 */

#define lay_redisplay_DESC "force redisplay of current window (for debugging)" 

#define lay_redisplay_DOC "
 Usage:
	lay_redisplay 

 Note:  Doesn't just schedule redisplay, actually does redisplay before
        returning.
"

static int
layCurRedisplayCmd(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
  CellUse *curUse;
  char *cmdName = argv[0];

  CMD_BEGIN(interp);

  /* check arg count */
  if (argc != 1) goto usage; 

  if(layCurrent)
  {
/*
    fprintf(stderr,"DEBUG before redisplay: QLength = %d\n", 
	    QLength(layCurrent->lay_display));
*/

    /* mark entire window for redisplay */
    LayChangedWindow(layCurrent, NULL);

    /* actually do the redisplay */
    layDisplay((ClientData) layCurrent);
/*
    fprintf(stderr,"DEBUG after redisplay: QLength = %d\n", 
	    QLength(layCurrent->lay_display));
*/

  }
  CMD_RETURN(interp);

usage:    
  MsgErrorF("usage: %s\n", cmdName);
  CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * layCurRootCellCmd --
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Side Effects:      
 *      if arg given, sets current cell to cell with that name.
 *
 *--------------------------------------------------------------
 */

#define lay_rootcell_DESC "get current rootcell" 

#define lay_rootcell_DOC "
 Usage:
	lay_rootcell 

  Result:
        cellName 

  Returns Name of top-level cell in current layout window.
"

static int
layCurRootCellCmd(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
    CellUse *curUse;

    CMD_BEGIN(interp);

    /* check arg count */
    if (argc > 2) 
    {
	MsgErrorF("wrong # args:  should be \"%s ?cellName?\"\n", argv[0]);
	CMD_RETURN(interp);
    }

    /* If arg present set current cell accordingly */
    if (argc > 1) 
    {
	MsgErrorF("layCurRootCellCmd:  TODO, take arg and set\n");
	CMD_RETURN(interp);
    }

    /* return name of current root cell, empty string if none */
    if( layCurrent && (curUse=layCurrent->lay_rootUse) )
    {
	Tcl_AppendResult(interp, curUse->cu_def->cd_name, NULL);
    }
    else
    {
	Tcl_AppendResult(interp, "", NULL);
    }
    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * layStatCoarseCmd --
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define lay_stat_coarse_DESC "get statistics on coarse redisplay planes"

#define lay_stat_coarse_DOC "
usage:  lay_stat_coarse [-cell cell_name] [-verbose]

If no -cell option, defaults to edit cell.

Returns,
   'coarse_summary' mem_usage num_tiles num_space_tiles

If -verbose, returns, for each coarse plane, a line of the form:
   plane_name resolution mem_usage num_tiles num_space_tiles

resolution = resolution of plane in data base units. 
mem_usage = total memory usage of the paint plane (in bytes)
num_tiles = total number of tiles in the paint planes 
num_space_tiles = number of space tiles in the paint plane 

NOTE:  4 tiles at infinity for each plane are included in num_tiles
but not num_space_tiles.
"

static int
layStatCoarseCmd(ClientData clientData, 
		   Tcl_Interp *interp, 
		   int argc, 
		   char **argv)
{
    char *cmdName;
    CellDef *def = NULL;
    bool verbose = FALSE;
    Coarse *c;
    CoarseDB *cdb;

    int grandMem = 0;
    int grandTiles = 0;
    int grandSpace = 0;

    CMD_BEGIN(interp);

    /* parse command name */
    cmdName = *argv;
    argc--; argv++;

    /* parse command line switchs */
    while(argc>0 && **argv=='-')
    {
      int length = strlen(*argv);
      char c = (*argv)[1];
	
      if(c=='c' && strncmp(*argv,"-cell",length)==0)
      {
	argc--; argv++;

	if(argc==0) goto usage;
	def = DBCellLookDef(*argv);
	if(!def)
	{
	  MsgErrorF("%s:  Couldn't find cell '%s'!\n",
		  cmdName, *argv);
	  CMD_RETURN(interp);
	}
	argc--; argv++;

	continue;
      }
	
      if(c=='v' && strncmp(*argv,"-verbose",length)==0)
      {
	argc--; argv++;

	verbose = TRUE;
	continue;
      }

      /* unrecognized option */
      goto usage;
    }

    /* should be no args left */
    if(argc) goto usage;

    /* default def to edit cell */
    if(!def) def = EditCellUse->cu_def;

    cdb = def->cd_coarseDB;
    if(!cdb) CMD_RETURN(interp);

    for(c=cdb->cdb_coarse;c;c=c->c_next)
    {
      int pNum;

      /* for each paint plane ... */
      for (pNum = PL_DRC_ERROR; pNum < DBNumPlanes; pNum++)
      {
	char buf[BUFSIZ];
	int counts[TT_MAXTYPES];
	int mem = 0;
	int total=0;
	int t;

	if(!(c->c_flags[pNum] & CFLG_COPY))
	{
	  Plane *plane;
	  plane= c->c_planes[pNum];
	  mem = DBstatPaintPlane(plane,counts);
	  for(t=0;t<DBNumTypes;t++) total += counts[t];
	  total += 4; /* tiles at infinity */

	  grandMem += mem;
	  grandTiles += total;
	  grandSpace += counts[TT_SPACE];

	}

	if(verbose)
	{
	  sprintf(buf,"%s %d %d %d tot %d\n",
		  DBPlaneShortName(pNum),
		  c->c_res,
		  mem,
		  total,
		  /* counts[TT_SPACE] */
		  cdb->cdb_totTiles[pNum]);
	  

	  Tcl_AppendResult(interp,buf,NULL);
	}
      }
    }

    /* summary */
    {
      char buf[BUFSIZ];
      
      sprintf(buf,"coarse_summary %d %d %d\n",
	      grandMem,
	      grandTiles,
	      grandSpace);

      Tcl_AppendResult(interp,buf,NULL);
    }

    CMD_RETURN(interp);

usage:
    MsgErrorF("usage: %s [-cell def_name] [-verbose]\n",
	      cmdName);
    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * layCurInternalsCmd --
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Side Effects:      
 *      if arg given, sets current cell to cell with that name.
 *
 *--------------------------------------------------------------
 */

#define lay_internals_DESC "show (or hide) instance internals" 

#define lay_internals_DOC "
 Usage:
	lay_internals [-area] [-hide] 

 If -area is specified all instances under box are expanded/unexpanded,
 else selected instances are expanded/unexpanded
 
 If -hide is specified, instances are unexpanded,
 else instances are expanded.
"

/* called for each instance in selection, updates expansion modes of instances
 * in selection.
 */
static int
layCurInternalsCmdFunc2(CellUse *selUse, 
               			/* Use from selection */
		CellUse *use, 
                 		/* Use from layout that corresponds to
				 * selUse (could be an array!).
				 */
		Transform *transform, 
                         	/* Transform from use->cu_def to root coords. */
		    		/* Not Used */
		TerminalPath *tPath, 
		    		/* Not Used */
		ClientData cdata)
               			/* Not Used */
{
  selUse->cu_expandMask = use->cu_expandMask;
    
  /* keep searching */
  return 0;
}

/* This function is called for each cell whose expansion status changed.
 * It forces the cells area to be redisplayed.
 */

int
layCurInternalsCmdFunc(CellUse *use, 
                 		/* Use that was just expanded. */
		    int windowMask)
                   		/* Window where it was expanded. */
{
    if (!DBCellUseParent(use)) return 0;

    DBChangedArea(DBCellUseParent(use),
		  &use->cu_bbox, 
		  NULL,
		  DBCF_DISPLAY_ONLY);

    /* continue search */
    return 0;
}

static int
layCurInternalsCmd(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
  CellUse *curUse;
  char *cmdName;
  Rect rootRect;
  int boxMask;
  Layout *w = layCurrent;
  int winMask = w->lay_bitmask;
  bool hide = FALSE;
  bool area = FALSE;

  CMD_BEGIN(interp);

  /* parse command name */
  cmdName = *argv;
  
  argc--; argv++;

  /* Parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];

    if(c=='a' && strncmp(*argv,"-area",length)==0)
    {
      argc--; argv++;
      area = TRUE;
      continue;
    }

    if(c=='h' && strncmp(*argv,"-hide",length)==0)
    {
      argc--; argv++;
      hide = TRUE;
      continue;
    }

    /* unrecognized option */
    goto usage;
  } /* end while(argc>0 && **argv=='-')  */

  /*** parse cmdline switchs ***/

  /* there should be no args left */
  if(argc!=0) goto usage;

  /*** do it ***/
  if (!area)
  {
    SelInternals(winMask,!hide);	
    CMD_RETURN(interp);
  }

  ToolGetBoxWindow(&rootRect, &boxMask);
  if ((boxMask & winMask) != winMask)
  {
     MsgErrorF("The box isn't in the same window as the cursor.\n");
     CMD_RETURN(interp);
  }

  /* expand or unexpand area */
  DBExpandAll(w->lay_rootUse, 
	      &rootRect, 
	      winMask,
	      !hide, 
	      layCurInternalsCmdFunc,
	      (ClientData) winMask);

  /* update expansion modes on instances in selection */
  {
    SearchContext scx;

    (void) SelEnumCells(FALSE, 
			(bool *) NULL, 
			NULL,
			(TerminalPath *) NULL,
			(TerminalPath *) NULL,
			layCurInternalsCmdFunc2,
			(ClientData) NULL);
  }

  CMD_RETURN(interp);

usage:
  MsgErrorF("Usage:  %s [-area] [-hide]\n",cmdName);
  CMD_RETURN(interp);
}



/*
 *--------------------------------------------------------------
 *
 * layCurGridCmd --
 *
 * C Result:
 *	A standard Tcl result.
 *
 *--------------------------------------------------------------
 */

#define lay_grid_DESC "query/modify grid for current window" 

#define lay_grid_DOC "
 Usage:
	lay_grid fine|coarse visibility [0|1]
 or 
        lay_grid fine|coarse rect [x0 y0 x1 y1]

 rect gives template for grid.  (x0,y0) is grid origin.

 Result:
        value of parameter (previous value on set)

 NOTE:  The x and y grid spacings can differ (if desired).
"

#define GRID_VIS 1
#define GRID_RECT 2
static int
layCurGridCmd(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
  char *cmdName;
  bool coarse;
  int op;

  CMD_BEGIN(interp);

  if(!layCurrent)
  {
    /* if no current layout window 
     * (this should only happen before first layout window created on startup)
     */
    MsgErrorF("No current layout window!\n");
    CMD_RETURN(interp);
  }
    
  /* command name */
  cmdName= *argv;
  argv++; argc--;

  /* fine or coarse */
  if(argc == 0) goto usage;
  if(strncmp(*argv,"fine",strlen(*argv))==0)
  {
    coarse = FALSE;
  }
  else if(strncmp(*argv,"coarse",strlen(*argv))==0)
  {
    coarse = TRUE;
  }
  else
  {
    goto usage;
  }
  argv++; argc--;

  /* op */
  if(argc == 0) goto usage;
  if(strncmp(*argv,"visibility",strlen(*argv))==0)
  {
    op = GRID_VIS;
  }
  else if(strncmp(*argv,"rect",strlen(*argv))==0)
  {
    op = GRID_RECT;
  }
  else
  {
    goto usage;
  }
  argv++; argc--;

  if(op == GRID_VIS)
  {
    bool vnew;
    bool vold = layCurrent->lay_flags & (coarse?Lay_GRIDCOARSE:Lay_GRIDFINE);

    /* result is current value */
    Tcl_SetResult(interp, vold?"1":"0", TCL_STATIC);

    /* read and set arg */
    if(argc>0)
    {
      if(strcmp(*argv,"0")==0 || strcmp(*argv,"{}")==0)
      {
	vnew=FALSE;
      }
      else if (strcmp(*argv,"1")==0)
      {
	vnew=TRUE;
      }
      else
      {
	goto usage;
      }
      argv++; argc--;
      if(argc>0) goto usage;

      if(coarse)
      {
	if(vnew)
	{
	  layCurrent->lay_flags |= Lay_GRIDCOARSE;
	} 
	else
	{
	  layCurrent->lay_flags &= ~Lay_GRIDCOARSE;	  
	}
      }
      else
      {
	if(vnew)
	{
	  layCurrent->lay_flags |= Lay_GRIDFINE;
	} 
	else
	{
	  layCurrent->lay_flags &= ~Lay_GRIDFINE;	  
	}
      }

      /* redraw grid */
      LayChangedWindow(layCurrent, (Rect *) NULL);
    }
	 
    CMD_RETURN(interp);
  }
  else if (op == GRID_RECT)
  {

    /* result is current value */
    if(coarse)
    {
      Tcl_AppendResult(interp, 
		       UnitsI2S(layCurrent->lay_gridCoarseRect.r_xbot),		  
		       NULL);
      Tcl_AppendElement(interp, 
		       UnitsI2S(layCurrent->lay_gridCoarseRect.r_ybot));		  
      Tcl_AppendElement(interp, 
		       UnitsI2S(layCurrent->lay_gridCoarseRect.r_xtop));		  
      Tcl_AppendElement(interp, 
		       UnitsI2S(layCurrent->lay_gridCoarseRect.r_ytop));		  
    }
    else
    {
      Tcl_AppendResult(interp, 
		       UnitsI2S(layCurrent->lay_gridFineRect.r_xbot),		  
		       NULL);
      Tcl_AppendElement(interp, 
		       UnitsI2S(layCurrent->lay_gridFineRect.r_ybot));		  
      Tcl_AppendElement(interp, 
		       UnitsI2S(layCurrent->lay_gridFineRect.r_xtop));		  
      Tcl_AppendElement(interp, 
		       UnitsI2S(layCurrent->lay_gridFineRect.r_ytop));		  
    }

    /* do the set */
    if(argc>0)
    {
      Rect r, rcan;

      if(argc!=4) goto usage;

      if(!UnitsValidS(argv[0]) || 
	 !UnitsValidS(argv[1]) ||
	 !UnitsValidS(argv[2]) ||
	 !UnitsValidS(argv[3]))
       {
    	 MsgErrorF("Bad coordinate for grid rect.\n");
	 CMD_RETURN(interp);
       }

      r.r_xbot = UnitsS2I(argv[0]);
      r.r_ybot = UnitsS2I(argv[1]);
      r.r_xtop = UnitsS2I(argv[2]);
      r.r_ytop = UnitsS2I(argv[3]);

      /* make sure lower left is really lower left */
      GeoCanonicalRect(&r,&rcan);

      /* 0 width or height coredumps redisplay, so check for it! */
      if(rcan.r_xbot == rcan.r_xtop || rcan.r_ybot == rcan.r_ytop)
      {
	MsgErrorF("grid width and height must be non-zero!\n");
	CMD_RETURN(interp);
      }

      if(coarse)
      {
	layCurrent->lay_gridCoarseRect = rcan;
      }
      else
      {
	layCurrent->lay_gridFineRect = rcan;
      }

      /* redraw grid */
      LayChangedWindow(layCurrent, (Rect *) NULL);
    }

    CMD_RETURN(interp);
  }
  else
  {

    ASSERT(FALSE,"layCurGridCmd");
  }

usage:
    MsgErrorF("usage:\t\n"
		"%s fine|coarse visibility [0|1]\n\tor\n"
		"%s fine|coarse rect [x0 y0 x1 y1]\n"
		,cmdName, cmdName);
    CMD_RETURN(interp);
}



/*
 *--------------------------------------------------------------
 *
 * layCurLabelsCmd --
 *
 * C Result:
 *	A standard Tcl result.
 *
 *--------------------------------------------------------------
 */

#define lay_labels_DESC "control label display in the current window" 

#define lay_labels_DOC "
 Usage:
	lay_labels non_edit_comments [0|1]

 Control display of \"comment\" and \"local\" labels in non-edit cells.

 If set (1), \"comment \" and \"local\"  labels are displayed for all cells.
 If reset (0), \"comment \" and \"local\"  labels are displayed only for the
 edit cell.

 Result:
        value of parameter (previous value on set)
"

static int
layCurLabelsCmd(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
  char *cmdName;
  int op;

  CMD_BEGIN(interp);

  if(!layCurrent)
  {
    /* if no current layout window 
     * (this should only happen before first layout window created on startup)
     */
    MsgErrorF("No current layout window!\n");
    CMD_RETURN(interp);
  }

  /* command name */
  cmdName= *argv;
  argv++; argc--;

  /* subcommand */
  if(argc == 0) goto usage;
  if(strncmp(*argv,"non_edit_comments",strlen(*argv))==0)
  {
    bool vnew;
    bool vold = layCurrent->lay_flags & Lay_LABELSNONEDIT;

    /* result is current value */
    Tcl_SetResult(interp, vold?"1":"0", TCL_STATIC);

    /* read and set arg */
    argv++; argc--;
    if(argc>0)
    {
      if(strcmp(*argv,"0")==0 || strcmp(*argv,"{}")==0)
      {
	vnew=FALSE;
      }
      else if (strcmp(*argv,"1")==0)
      {
	vnew=TRUE;
      }
      else
      {
	goto usage;
      }
      argv++; argc--;
      if(argc>0) goto usage;

      if(vnew)
      {
	layCurrent->lay_flags |= Lay_LABELSNONEDIT;
      }
      else
      {
	layCurrent->lay_flags &= ~Lay_LABELSNONEDIT;
      }

      /* redraw window */
      LayChangedWindow(layCurrent, (Rect *) NULL);
    }
	 
    CMD_RETURN(interp);
  }

usage:
  MsgErrorF("usage:\t%s non_edit_comments [0|1]\n", cmdName);
  CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * layCellTextCmd --
 *
 *
 * C Result:
 *	A standard Tcl result.

 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define lay_cell_text_DESC "give alternate text to display for cell"

#define lay_cell_text_DOC "
usage:  lay_cell_text [-cell cell_name] line1 line2

if no -cell, default to edit cell.
if line1 not empty string, display instead of cell name.
if line2 ont empty string, display instead of instance name.
"

static int
layCellTextCmd(ClientData clientData, 
	       Tcl_Interp *interp, int argc, char **argv)
{
    char *cmdName;
    char *line1;
    char *line2;
    CellDef *def = EditCellUse->cu_def;

    CMD_BEGIN(interp);

    /* parse command name */
    cmdName = *argv;
    argc--; argv++;

    /* parse command line switchs */
    while(argc>0 && **argv=='-')
    {
      int length = strlen(*argv);
      char c = (*argv)[1];
	
      if(c=='c' && strncmp(*argv,"-cell",length)==0)
      {
	argc--; argv++;
	
	if(argc==0) goto usage;
	def = DBCellLookDef(*argv);
	if(!def)
	{
	  MsgErrorF("%s:  Couldn't find cell '%s'!\n",
		  cmdName, *argv);
	  CMD_RETURN(interp);
	}
	argc--; argv++;

	continue;
      }

      /* unrecognized option */
      goto usage;
    }
	
    /* parse line1 */
    if(!argc) goto usage;
    line1 = *argv;
    argc--; argv++;
	
    /* parse line2 */
    if(!argc) goto usage;
    line2 = *argv;
    argc--; argv++;

    if(argc) goto usage; 

    /* clear current values */
    if(def->cd_showName)
    {
      FREE(def->cd_showName);
      def->cd_showName = NULL;
    }
    if(def->cd_showInst)
    {
      FREE(def->cd_showInst);
      def->cd_showInst = NULL;
    }

    /* set new values */
    if(*line1 != '\0') def->cd_showName = StrDup(NULL,line1); 
    if(*line2 != '\0') def->cd_showInst = StrDup(NULL,line2); 

    /* need to redisplay cell */
    DBChangedArea(def, NULL, &DBAllButSpaceBits, DBCF_DISPLAY_ONLY);

    CMD_RETURN(interp);

usage:
    MsgErrorF("usage: %s [-cell cell_name] line1 line2\n",
	      cmdName);
    CMD_RETURN(interp);
}


/*
 * ----------------------------------------------------------------------------
 *
 * layTclInit --
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
layTclInit(Tcl_Interp *interp)
{

   MnDocCreateCommand(interp, "lay_bbox", layCurBoundingBoxCmd, 
	       (ClientData) NULL,  (Tcl_CmdDeleteProc *) NULL,
	       lay_bbox_DESC,
	       lay_bbox_DOC);

   MnDocCreateCommand(interp, "lay_box", layCurBoxCmd, 
	       (ClientData) NULL,  (Tcl_CmdDeleteProc *) NULL,
	       lay_box_DESC,
	       lay_box_DOC);

   MnDocCreateCommand(interp, "lay_cell_text", layCellTextCmd, 
	       (ClientData) NULL,  (Tcl_CmdDeleteProc *) NULL,
	       lay_cell_text_DESC,
	       lay_cell_text_DOC);

   MnDocCreateCommand(interp, "lay_changed", layCurChangedCmd, 
	       (ClientData) NULL,  (Tcl_CmdDeleteProc *) NULL,
	       lay_changed_DESC,
	       lay_changed_DOC);

   MnDocCreateCommand(interp, "lay_dot", layDotCmd, 
	       (ClientData) NULL,  (Tcl_CmdDeleteProc *) NULL,
	       lay_dot_DESC,
	       lay_dot_DOC);

   MnDocCreateCommand(interp, "lay_editcell", layCurEditCellCmd, 
	       (ClientData) NULL,  (Tcl_CmdDeleteProc *) NULL,
	       lay_editcell_DESC,
	       lay_editcell_DOC);

   MnDocCreateCommand(interp, "lay_frame", layFrameCmd, 
	       (ClientData) NULL,  (Tcl_CmdDeleteProc *) NULL,
	       lay_frame_DESC,
	       lay_frame_DOC);

   MnDocCreateCommand(interp, "lay_grid", layCurGridCmd, 
	       (ClientData) NULL,  (Tcl_CmdDeleteProc *) NULL,
	       lay_grid_DESC,
	       lay_grid_DOC);

   MnDocCreateCommand(interp, "lay_internals", layCurInternalsCmd, 
	       (ClientData) NULL,  (Tcl_CmdDeleteProc *) NULL,
	       lay_internals_DESC,
	       lay_internals_DOC);

   MnDocCreateCommand(interp, "lay_labels", layCurLabelsCmd, 
	       (ClientData) NULL,  (Tcl_CmdDeleteProc *) NULL,
	       lay_labels_DESC,
	       lay_labels_DOC);

   MnDocCreateCommand(interp, "lay_line", layLineCmd, 
	       (ClientData) NULL,  (Tcl_CmdDeleteProc *) NULL,
	       lay_line_DESC,
	       lay_line_DOC);

   MnDocCreateCommand(interp, "lay_point", layCurPointCmd, 
	       (ClientData) NULL,  (Tcl_CmdDeleteProc *) NULL,
	       lay_point_DESC,
	       lay_point_DOC);

   MnDocCreateCommand(interp, "lay_redisplay", layCurRedisplayCmd, 
	       (ClientData) NULL,  (Tcl_CmdDeleteProc *) NULL,
	       lay_redisplay_DESC,
	       lay_redisplay_DOC);

   MnDocCreateCommand(interp, "lay_rootcell", layCurRootCellCmd, 
	       (ClientData) NULL,  (Tcl_CmdDeleteProc *) NULL,
	       lay_rootcell_DESC,
	       lay_rootcell_DOC);

   MnDocCreateCommand(interp, "lay_stat_coarse", layStatCoarseCmd, 
	       (ClientData) NULL,  (Tcl_CmdDeleteProc *) NULL,
	       lay_stat_coarse_DESC,
	       lay_stat_coarse_DOC);

   MnDocCreateCommand(interp, "lay_text", layTextCmd, 
	       (ClientData) NULL,  (Tcl_CmdDeleteProc *) NULL,
	       lay_text_DESC,
	       lay_text_DOC);

}
