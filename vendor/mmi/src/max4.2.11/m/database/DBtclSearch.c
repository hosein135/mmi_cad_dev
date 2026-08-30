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
 * DBtclSearch.c -- implements db_search_* commands
 *                  (database enumeration routines)
 */

static char rcsid[] = "$Header$";
#include <stdio.h>
#include <stdlib.h>
#include <limits.h>
#include <tcl.h>
#include "magic.h"
#include "main.h"
#include "message.h"
#include "string.h"
#include "signals.h"
#include "layout.h"
#include "units.h"
#include "utils.h"
#include "geometry.h"
#include "database.h"
#include "databaseInt.h"
#include "bplane.h"
#include "debug.h"

/* used to implement -limit options to db_search */
static int dbCountMax;
static int dbCount; 

/* used to build up results */
static Tcl_Obj *dbResult;



/*
 *--------------------------------------------------------------
 *
 * dbTclCmdSearch2 --
 *
 *      Does the work for following commands:
 *         db_search_cells 
 *         db_search_paint
 *         db_search_polygons
 *         db_search_wirepaths
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Tcl Result:
 *      List describing matching items.
 *
 *
 *--------------------------------------------------------------
 */

/* called by dbPaintFunc for each group tile belongs to */
static __inline__ void 
dbPaintFuncGroup(Rect *rect, 
		 int type,
		 Group *group,
		 TreeContext *cxp)
{
  Tcl_Interp *interp = (Tcl_Interp *) cxp->tc_filter->tf_arg;
  TerminalPath *tpath = cxp->tc_filter->tf_tpath;
  SearchContext *scx = cxp->tc_scx;
  Tcl_Obj *p = Tcl_NewListObj(0,0);
  Rect rootRect;

  GeoTransRect(&scx->scx_trans, rect, &rootRect);

  /* output layer */
  TListAppendStr(interp, p, DBTypeLongName(type));

  /* output coordinates in user root cell */ 
  TListAppendDouble(interp, p, UnitsI2D(rootRect.r_xbot));
  TListAppendDouble(interp, p, UnitsI2D(rootRect.r_ybot));
  TListAppendDouble(interp, p, UnitsI2D(rootRect.r_xtop));
  TListAppendDouble(interp, p, UnitsI2D(rootRect.r_ytop));

  /* output hierarchical instance path from root */
  TListAppendStr(interp, p, tpath->tp_first);

  /* output group */
  TListAppendStr(interp, p, group?group->g_name:"0");

  /* add to result */
  TListAppendObj(interp, dbResult, p);
}

/* callback func for dbTclCmdSearch2 for paint tiles */
static int 
dbPaintFunc(Tile *tile, TreeContext *cxp)
{
  GroupList *gl;
  int i = 0;
  char *s;
  Rect rect, rootRect;

  TiToRect(tile, &rect);

  /*** SINGLE GROUP CASE ***/
  if (!DBisSetTileFlag(tile,TF_MULTIGROUP))
  {
    dbPaintFuncGroup(&rect, DBgetTileType(tile), TiGetGroups(tile), cxp);
    if(++dbCount >= dbCountMax) return 1;
    return 0;
  }

  /*** MULTI GROUP CASE ***/
  for(gl=(GroupList *) TiGetGroups(tile);
      gl;
      gl=gl->gl_next)
  {
    dbPaintFuncGroup(&rect, gl->gl_type, gl->gl_group, cxp);
    if(++dbCount >= dbCountMax) return 1;
  }
  return 0;
}

/* callback func for dbTclCmdSearch2 for polygons */
static int 
dbPolyFunc(SearchContext *scx, 
	       Polygon *poly, 
	       ClientData cdarg, 
	       TerminalPath *tpath)
{
  Tcl_Interp *interp = (Tcl_Interp *) cdarg;
  Tcl_Obj *pl = Tcl_NewListObj(0,0);

  /* layer */
  TListAppendStr(interp, pl, DBTypeLongName(poly->poly_type));

  /* bbox */
  {
    Rect bbox;
    Tcl_Obj *bl = Tcl_NewListObj(0,0);

    GeoTransRect(&scx->scx_trans, &poly->poly_bbox, &bbox);

    TListAppendDouble(interp, bl, UnitsI2D(bbox.r_xbot));
    TListAppendDouble(interp, bl, UnitsI2D(bbox.r_ybot));
    TListAppendDouble(interp, bl, UnitsI2D(bbox.r_xtop));
    TListAppendDouble(interp, bl, UnitsI2D(bbox.r_ytop));

    TListAppendObj(interp, pl, bl);
  }

  /* points */
  {
    PointFloat *p;
    int i;
    Tcl_Obj *pl2 = Tcl_NewListObj(0,0);

    p = poly->poly_points;
    for(i=0; i< poly->poly_size; i++)
    {
      PointFloat pRoot;
      GeoTransPointF(&scx->scx_trans, p, &pRoot);

      TListAppendDouble(interp, pl2, UnitsF2D(pRoot.pf_x));
      TListAppendDouble(interp, pl2, UnitsF2D(pRoot.pf_y));
      p++;
    }
    TListAppendObj(interp, pl, pl2);
  }

  /* attributes */
  {
    Tcl_Obj *al = Tcl_NewListObj(0,0);
    if(poly->poly_wirePath) TListAppendStr(interp, al, "dependent");
    TListAppendObj(interp, pl, al);
  }

  /* hierarchical instance path from root */
  TListAppendStr(interp, pl, tpath->tp_first);

  /*  group */
  TListAppendStr(interp, pl, poly->poly_group?poly->poly_group->g_name:"0");

  /* add to result */
  TListAppendObj(interp, dbResult, pl);

  /* continue search */
  if(++dbCount >= dbCountMax) return 1;
  return 0;
}

/* callback func for dbTclCmdSearch2 for cells */
static Layout *dbSearchLayout;
static int 
dbCellsFunc(SearchContext *scx, 
	    ClientData cdarg, 
	    TerminalPath *tpath)
{
  Tcl_Interp *interp = (Tcl_Interp *) cdarg;
  CellUse *use = scx->scx_use;
  Transform *trans = &scx->scx_trans;
  Tcl_Obj *c = Tcl_NewListObj(0,0);

  /* output instance name */
  TListAppendStr(interp, c, use->cu_id);

  /* output cellname */
  TListAppendStr(interp, c, use->cu_def->cd_name);

  /* output bbox in rootcell user coords ( = Select cell coords) */
  {
    Rect bbox;

    GeoTransRect(&scx->scx_trans, DBBBoxCellDef(use->cu_def), &bbox);

    TListAppendDouble(interp, c, UnitsI2D(bbox.r_xbot));
    TListAppendDouble(interp, c, UnitsI2D(bbox.r_ybot));
    TListAppendDouble(interp, c, UnitsI2D(bbox.r_xtop));
    TListAppendDouble(interp, c, UnitsI2D(bbox.r_ytop));
  }

  /* output path to instance */
  TListAppendStr(interp, c, tpath->tp_first); 

  /* output expansion status */
  TListAppendStr(interp, 
		 c, 
		 DBIsExpand(use, dbSearchLayout->lay_bitmask)? "expanded":"");

  /* output transform from instance to root coordinates */
  {
    Tcl_Obj *t = Tcl_NewListObj(0,0);

    TListAppendInt(interp, t, trans->t_a);
    TListAppendInt(interp, t, trans->t_b);
    TListAppendDouble(interp, t, UnitsI2D(trans->t_c));
    TListAppendInt(interp, t, trans->t_d);
    TListAppendInt(interp, t, trans->t_e);
    TListAppendDouble(interp, t, UnitsI2D(trans->t_f));

    TListAppendObj(interp, c, t);
  }

  /* output array info */
  if(!DBIsArray(use))
  {
    TListAppendStr(interp, c, "");
  }
  else
  {
    ArrayInfo ar;

    Tcl_Obj *la = Tcl_NewListObj(0,0);

    /* convert array info to rootcell */
    DBArrayTransformInfo(trans, &use->cu_array, &ar);

    /* indices of this element */
    TListAppendInt(interp, la, scx->scx_x);
    TListAppendInt(interp, la, scx->scx_y);

    TListAppendInt(interp, la, ar.ar_xlo);
    TListAppendInt(interp, la, ar.ar_xhi);
    TListAppendInt(interp, la, ar.ar_ylo);
    TListAppendInt(interp, la, ar.ar_yhi);
    TListAppendDouble(interp, la, UnitsI2D(ar.ar_xsep));
    TListAppendDouble(interp, la, UnitsI2D(ar.ar_ysep));

    TListAppendObj(interp, c, la);
  }
    
  /* add to result */
  TListAppendObj(interp, dbResult, c);

  /* continue search */
  if(++dbCount >= dbCountMax) return 1;
  return 0;
}

/* callback func for dbTclCmdSearch2 for wirepaths */
static int 
dbWPFunc(SearchContext *scx, 
	 WirePath *wp, 
	 ClientData cdarg, 
	 TerminalPath *tpath)
{
  Tcl_Interp *interp = (Tcl_Interp *) cdarg;
  Tcl_Obj *wl = Tcl_NewListObj(0,0);

  /* layer */
  TListAppendStr(interp, wl, DBTypeLongName(wp->wp_type));

  /* bbox */
  {
    Rect bbox;
    Tcl_Obj *bl = Tcl_NewListObj(0,0);

    GeoTransRect(&scx->scx_trans, &wp->wp_bbox, &bbox);

    TListAppendDouble(interp, bl, UnitsI2D(bbox.r_xbot));
    TListAppendDouble(interp, bl, UnitsI2D(bbox.r_ybot));
    TListAppendDouble(interp, bl, UnitsI2D(bbox.r_xtop));
    TListAppendDouble(interp, bl, UnitsI2D(bbox.r_ytop));

    TListAppendObj(interp, wl, bl);
  }

  /* width */
  TListAppendDouble(interp, wl, UnitsI2D(wp->wp_width));

  /* points */
  {
    Point *p;
    int i;
    Tcl_Obj *pl = Tcl_NewListObj(0,0);

    p = wp->wp_points;
    for(i=0; i< wp->wp_size; i++)
    {
      Point pRoot;
      GeoTransPoint(&scx->scx_trans, p, &pRoot);

      TListAppendDouble(interp, pl, UnitsI2D(pRoot.p_x));
      TListAppendDouble(interp, pl, UnitsI2D(pRoot.p_y));
      p++;
    }
    TListAppendObj(interp, wl, pl);
  }

  /* attributes */
  {
    Tcl_Obj *al = Tcl_NewListObj(0,0);

    /* endcap style */
    switch (wp->wp_style)
    {
    case WP_STYLE_FLUSH:
      TListAppendStr(interp, al, "flush");
      break;

    case WP_STYLE_ROUNDED:
      TListAppendStr(interp, al, "rounded");
      break;

    case WP_STYLE_HALFWIDTH:
      TListAppendStr(interp, al, "half_width");
      break;

    default:
      ASSERT(FALSE,"dbWPFunc");
      break;
    }

    TListAppendObj(interp, wl, al);
  }

  /* output hierarchical instance path from root */
  TListAppendStr(interp, wl, tpath->tp_first);

  /*  group */
  TListAppendStr(interp, wl, wp->wp_group?wp->wp_group->g_name:"0");

  /* add to result */
  TListAppendObj(interp, dbResult, wl);

  /* continue search */
  if(++dbCount >= dbCountMax) return 1;

  return 0;
}

static void
dbTclCmdSearch2(Tcl_Interp *interp, 
		int argc, 
		char **argv,
		bool paint,
		bool poly,
		bool wp,
		bool cells)
{
    int pNum;
    char *cmdName;
    TileTypeBitMask tTypes = DBAllButSpaceBits;
    bool anyCell = FALSE;
    bool group = FALSE;
    bool area = FALSE;
    CellDef *def = NULL;
    Rect rect;
    int planeMask;
    int limit = INT_MAX;

    /* process args */
    {
      
      cmdName = *argv;
      argc--; argv++;
      
      /* Parse command line switchs */
      while(argc>0 && **argv=='-')
      {
	int length = strlen(*argv);
	char c = (*argv)[1];
	
	if(c=='a' && strncmp(*argv,"-any_cell",MAX(length,3))==0)
	{
	  argc--; argv++;
	  anyCell = TRUE;
	  continue;
	}
	if(c=='a' && strncmp(*argv,"-area",MAX(length,3))==0)
	{
	  Rect t;
	  argc--; argv++;
	  area = TRUE;

	  if(argc==0 || !UnitsValidS(*argv)) goto usage;
	  t.r_ll.p_x = UnitsS2I(*argv);
	  argc--; argv++;
	  if(argc==0 || !UnitsValidS(*argv)) goto usage;
	  t.r_ll.p_y = UnitsS2I(*argv);
	  argc--; argv++;
	  if(argc==0 || !UnitsValidS(*argv)) goto usage;
	  t.r_ur.p_x = UnitsS2I(*argv);
	  argc--; argv++;
	  if(argc==0 || !UnitsValidS(*argv)) goto usage;
	  t.r_ur.p_y = UnitsS2I(*argv);
	  argc--; argv++;

	  GeoCanonicalRect(&t, &rect);
	  if(rect.r_xbot == rect.r_xtop) rect.r_xtop++;
	  if(rect.r_ybot == rect.r_ytop) rect.r_ytop++;

	  continue;
	}
	
	if(c=='c' && strncmp(*argv,"-cell",length)==0)
        {
	  argc--; argv++;

	  if(argc==0) goto usage;
	  def = DBCellLookDef(*argv);
	  if(!def)
	  {
	    MsgErrorF("%s:  Couldn't find cell '%s'!\n",
		      cmdName, *argv);
	    return;
	  }
	  argc--; argv++;
	  continue;
	}
	
	if(c=='l' && strncmp(*argv,"-limit",length)==0)
        {
	  argc--; argv++;

	  if(argc==0) goto usage;
	  limit = atoi(*argv);
	  argc--; argv++;

	  continue;
	}

	/* unrecognized option */
	goto usage;
	
      } /* end while(argc>0 && **argv=='-')  */

      /* types list arg */
      if(argc > 0)
      {
	if(!CmdParseLayers(argv[0], &tTypes)) return;
	argc--; argv++;
      }

      if(argc > 0) goto usage;
    }

    /* setup result limit */
    dbCountMax = limit;
    dbCount = 0;

    /* get current layout window (used by db_search cells func) */
    dbSearchLayout = LayCurWindow();

    if(def || anyCell)
    {
      /* -any_cell and/or -cell option */

      Layout *l = LayCurWindow();
      CellUse *rootUse = l->lay_rootUse;
      CellUse dummy;
      SearchContext scx;
      TerminalPath tpath;
      char buf[BUFSIZ];   /* buffer for terminal path */    
      
      /* -cell option overrides rootdef */
      if(def)
      {
	DBCellInitTempUse(def, &dummy); 
	rootUse = &dummy;
      }

      /* Setup search context */
      scx.scx_use = rootUse;
      scx.scx_trans = GeoIdentityTransform;
      scx.scx_area = area ? rect : *DBBBoxCellUse(rootUse);

      /* grow area slightly so we always get touching stuff,
       * this is important since bbox may not include all drc error	 
       * tiles for example.
       */
      GEO_EXPAND(&scx.scx_area, 1, &scx.scx_area);

      /* set up terminal path */
      buf[0] = '\0';
      tpath.tp_first = tpath.tp_next = buf;
      tpath.tp_last =  &buf[BUFSIZ-2];

      /* do the search */
      dbResult =  Tcl_NewListObj(0,0);
      if(cells)
      {
	int flags = DBSI_INCLUDE_EXPANDED;
	if(!anyCell) flags |= DBSI_NON_RECURSIVE;
	DBSearchInstances2(&scx,
			   def ? 0 : l->lay_bitmask,
			   &tpath,	         /* tpath */
			   dbCellsFunc,
			   (ClientData) interp,
			   flags);
      }
      else
      {
	DBSearchPaintNew2(&scx,
			  &tTypes,         /* layers */
			  def ? 0 : l->lay_bitmask,
			  &tpath,	         /* tpath */
			  paint ? dbPaintFunc : NULL,
			  poly  ? dbPolyFunc  : NULL,
			  wp    ? dbWPFunc    : NULL,
			  (ClientData) interp,
			  anyCell ? 0 : DBSP_NON_RECURSIVE);   /* flags */
      }
    }
    else
    {
      /* EDIT CELL ONLY */
 
      Layout *l = LayCurWindow();
      CellUse *rootUse = l->lay_rootUse;
      SearchContext scx;
      TerminalPath tpath;
      char buf[BUFSIZ];   /* buffer for terminal path */    

      /* Setup search context */
      scx.scx_use = EditCellUse;
      scx.scx_trans = EditToRootTransform;

      /* area in edit cell coords */
      if(area)
      {
	GEOTRANSRECT(&RootToEditTransform, &rect, &scx.scx_area);
      }
      else
      {
	/* default area to bounding box */
	scx.scx_area = *DBBBoxCellDef(EditCellUse->cu_def); 
      }

      /* set up terminal path */
      buf[0] = '\0';
      tpath.tp_first = tpath.tp_next = buf;
      tpath.tp_last =  &buf[BUFSIZ-2];

      /* TODO compute edit cell path! */
      strcpy(buf,"EDIT_CELL_PATH");
      tpath.tp_next += strlen("EDIT_CELL_PATH");				      
      /* do the search */
      dbResult =  Tcl_NewListObj(0,0);
      if(cells)
      {
	DBSearchInstances2(&scx,
			   0,                    /* ignore expansion status */
			   &tpath,	         /* tpath */
			   dbCellsFunc,
			   (ClientData) interp,
			   DBSI_NON_RECURSIVE | DBSI_INCLUDE_EXPANDED);
      }
      else
      {
	DBSearchPaintNew2(&scx,
			  &tTypes,         /* layers */
			  l->lay_bitmask,  /* look inside expanded cells */
			  &tpath,	         /* tpath */
			  paint ? dbPaintFunc : NULL,
			  poly  ? dbPolyFunc  : NULL,
			  wp    ? dbWPFunc    : NULL,
			  (ClientData) interp,
			  DBSP_NON_RECURSIVE);  /* don't dive inside subcells */
      }

    }

    /* set result */
    Tcl_SetObjResult(interp,dbResult);
    return;

usage:
    MsgErrorF("usage:  %s [-cell def_name] [-any_cell] [-area xbot ybot xtop ytop] [-limit n] [layers]\n",cmdName); 
    return; 
}


/*
 *--------------------------------------------------------------
 *
 * dbTclCmdSearchPaintL --
 *
 * Implements db_search_paint
 *
 *
 * Result:
 *	A standard Tcl result.
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */
#define db_search_paint_DESC "find paint rectangles in area"

#define db_search_paint_DOC "
Usage:  db_search_paint [-cell def_name] [-any_cell] [-area xbot ybot xtop ytop] [-limit n] [layers]
       returns, for each paint rectangle found:
         \"layer xbot ybot xtop ytop instance_path group\"
       (root cell coordinates).

       If -any_cell present, paint is not restricted to editcell, rather
       any paint in rootcell or expanded descendents, is given.

       If -cell given, search named cell instead of root (or edit) cell.
       (coordinates are in terms of def_name

       If -cell AND -any_cell, looks inside all descendents of named cell
       regardless of expansion mask.

       If -limit n, output is limited to n matchs.

NOTE: Returns tcl list object:  no new-lines!
"

static int
dbTclCmdSearchPaintL(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
    int length;
    char c;

    CMD_BEGIN(interp);

    /* real work done by 'Search2' */ 
    dbTclCmdSearch2(interp,argc,argv, TRUE, FALSE, FALSE, FALSE );

    CMD_RETURN(interp);
}



/*
 *--------------------------------------------------------------
 *
 * dbTclCmdSearchPolygonsL --
 *
 * Implements db_search_polygons
 *
 *
 * Result:
 *	A standard Tcl result.
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */
#define db_search_polygons_DESC "find polygons in area"

#define db_search_polygons_DOC "

Usage:  db_search_polygons [-cell] [-any_cell] [-area xbot ybot xtop ytop] [-limit n] [layers] 
       returns, for each polygon:
         \"layer bbox coordinates attributes instance_path group\"
       (root cell coordinates).

       If -any_cell present, polygons are not restricted to editcell, rather
       any polygon in rootcell or expanded descendents, is given.

       If -cell given, search named cell instead of root (or edit) cell.
       (coordinates are in terms of def_name

       If -cell AND -any_cell, looks inside all descendents of named cell
       regardless of expansion mask.

       If -limit n, output is limited to n matchs.

NOTE: Returns tcl list object:  no new-lines!
"

static int
dbTclCmdSearchPolygonsL(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
    int length;
    char c;

    CMD_BEGIN(interp);

    /* real work done by 'Search2' */ 
    dbTclCmdSearch2(interp,argc,argv, FALSE, TRUE, FALSE, FALSE );

    CMD_RETURN(interp);
}



/*
 *--------------------------------------------------------------
 *
 * dbTclCmdSearchWirePathsL --
 *
 * Implements db_search_wire_paths
 *
 *
 * Result:
 *	A standard Tcl result.
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */
#define db_search_wire_paths_DESC "find wire paths in area"

#define db_search_wire_paths_DOC "
Usage:  db_search_wire_paths [-cell] [-any_cell] [-area xbot ybot xtop ytop] [-limit n] [layers]

       returns, for each wire path:
         \"layer bbox width coordinates attributes instance_path group\"
       (root cell coordinates).

       If -any_cell present, wirepaths are not restricted to editcell, rather
       any wirepath in rootcell or expanded descendents, is given.

       If -cell given, search named cell instead of root (or edit) cell.
       (coordinates are in terms of def_name

       If -cell AND -any_cell, looks inside all descendents of named cell
       regardless of expansion mask.

       If -limit n, output is limited to n matchs.

NOTE: Returns tcl list object:  no new-lines!
"

static int
dbTclCmdSearchWirePathsL(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
    int length;
    char c;

    CMD_BEGIN(interp);

    /* real work done by 'Search2' */ 
    dbTclCmdSearch2(interp,argc,argv, FALSE, FALSE, TRUE, FALSE );

    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * dbTclCmdSearchCellsL --
 *
 * Implements db_search_cells
 *
 *
 * Result:
 *	A standard Tcl result.
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */
#define db_search_cells_DESC "find instances in area"

#define db_search_cells_DOC "
Usage:  db_search_cells [-cell def_name] [-any_cell] [-area xbot ybot xtop ytop] [-limit n]
       returns, for each instance found:
         \"instanceName defName xbot ybot xtop ytop path expansion transform arrayInfo\"
       (root cell coordinates).

       xbot ybot xtop ytop = bounding box

       path = 'EDIT_CELL_PATH' if -any_cell is not specified.
	      If -any_cell is specified, it is the path from
	      the root cell to the cell containing the instance,
	      or {} (null list) if the instance is directly in the rootcell.

       expansion = 'expanded' if internals visible, else {} (null list) 
       transform = {a b c d e f}  (first two columns of 3x3 transform matrix
                                   last column is {0 0 1})
       arrayInfo = {xindex yindex xlo xhi ylo yhi xsep ysep} 
                   (or NULL if not array)

          NOTES ON ARRAYS:  if an arrayed cell is rotated or flipped,
	  max modifies the transform and arrayinfo.  If an array
	  is rotated, the xlo/xhi and ylo/yhi are swapped so that
	  the x info is always horizontal, and y info is vertical.
	  The xsep and ysep may be positive or negative to indicate
	  the direction in which array elements are currently numbered.

       If -any_cell, instances are not restricted to editcell, rather
       all instances in rootcell and in expanded descendents are given.

       If -cell given, search named cell instead of root (or edit) cell.
       (coordinates are in terms of def_name)

       If -cell AND -any_cell, gives all descendents of the named cell.

       If -limit n, output is limited to n matchs.

NOTE: Returns tcl list object:  no new-lines!
"

static int
dbTclCmdSearchCellsL(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
    int length;
    char c;

    CMD_BEGIN(interp);
    
    /* real work done by 'Search2' */ 
    dbTclCmdSearch2(interp,argc,argv, FALSE, FALSE, FALSE, TRUE );

    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * dbTclCmdSearchLabelsL --
 *
 *	Implement db_serach_labels
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Tcl Result:
 *      list describing labels in current cell (or descendents)
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */
#define db_search_labels_DESC "find labels in area"

#define db_search_labels_DOC "
Usage:  db_search_labels [-cell def_name] [-non_hier] [-area xbot ybot xtop ytop] [-limit n] [-kind kind] [glob_pattern] 

       for each label found (in rootcell or expanded descendents), returns: 
       \"layer xbot ybot xtop ytop pos text instance_path group kind\"
       (root cell coordinates).

       If -non_hier, don't search instances.
       
       If -kind, prints only labels of given kind (i.e. in, out, in_out,
       local, global, text, or hidden)
 
       If glob_pattern is given, only labels with text matching the 
       pattern are returned.

       Glob matching uses the characters: * ? [ ]
       To match one of these characters, precede it with a backslash.
       Note that both the backslash and bracket characters are special
       to tcl, and so must be enclosed in curly braces.
       To search for the label x[1], you must use:

	   db_search labels {x\\[1\\]}

       If -no_glob, glob_pattern is treated as straight text: no special
       characters.

       If glob_pattern contains a '/' it is recognized as a hierarchical
       path name.  In this case -anyCell is irrelevant.  Currently hierarchical
       path names with array subscripts, or wildcards are not handled.  Also
       path names with leading '/' are not yet allowed.

       NOTE:  Searching for labels with specific text (no
       wild-carding) is very efficient.  Wild-carded searches
       are inefficient.

       If -cell given, search named cell instead of root cell.
       (coordinates are in terms of def_name).  When this option
       is given, and -non_hier is not specified, ALL descendents 
       (not just expanded ones) are searched.

       If -limit n, output is limited to n matchs.

NOTE: Returns tcl list object:  no new-lines!
"

/* if non-negative, label kind must match */
static int labelsKind;

/* helper func */
static int
dbTclCmdSearchLabelsLFunc(SearchContext *scx, 
			  Label *label, 
			  TerminalPath *tPath,
			  ClientData clientdata)
{
    Tcl_Interp *interp = (Tcl_Interp *) clientdata;
    Tcl_Obj *l = Tcl_NewListObj(0,0);

    if (SigInterruptPending) return 1; 

    /* if kind specified, skip non-matches */
    if(labelsKind>=0 && label->lab_kind != labelsKind) return 0;

    /* output label type */
    TListAppendStr(interp, l, DBTypeLongName(label->lab_type));

    /* output rect in user root coords */
    {
      Rect rootRect;

      GeoTransRect(&scx->scx_trans, &label->lab_rect, &rootRect);

      TListAppendDouble(interp, l, UnitsI2D(rootRect.r_xbot));
      TListAppendDouble(interp, l, UnitsI2D(rootRect.r_ybot));
      TListAppendDouble(interp, l, UnitsI2D(rootRect.r_xtop));
      TListAppendDouble(interp, l, UnitsI2D(rootRect.r_ytop));
    }

    /* output label position */
    {
      int rootPos = GeoTransPos(&scx->scx_trans, label->lab_pos);
      TListAppendStr(interp, l, GeoPosToName(rootPos));
    }

    /* output label text */
    TListAppendStr(interp, l, label->lab_text);

    /* output path */
    TListAppendStr(interp, l, tPath->tp_first);

    /* output  group */
    TListAppendStr(interp, l, label->lab_group?label->lab_group->g_name:"0");

    /* output kind */
    TListAppendStr(interp, l, DBLabelKindName(label->lab_kind));

    /* add to result */
    TListAppendObj(interp, dbResult, l);

    /* return of 0 continues search, 1 aborts search */
    if(++dbCount >= dbCountMax) return 1;
    return 0;  
}

static int 
dbTclCmdSearchLabelsL(ClientData clientData,
		      Tcl_Interp *interp, 
		      int argc, 
		      char **argv)
{
  int expansionMask;
  int flags;
  SearchContext scx;
  CellDef *def = NULL;
  CellUse dummy;
  CellUse *rootUse;

  char *pattern = NULL;

  char *cmdName;
  bool area = FALSE;
  Rect rect;

  int pNum;
  TileTypeBitMask tTypes = DBAllButSpaceBits;
  bool anyCell = FALSE;
  bool group = FALSE;
  bool nonHier = FALSE;
  bool noGlob = FALSE;
  int limit = INT_MAX;

  int kind = -1;  /* if non-negative label kind must match */

  int planeMask;

  CMD_BEGIN(interp);      

  /* process args */
  {
    cmdName = *argv;
    argc--; argv++;
      
    /* Parse command line switchs */
    while(argc>0 && **argv=='-')
    {
      int length = strlen(*argv);
      char c = (*argv)[1];
      
      if(c=='a' && strncmp(*argv,"-area",MAX(length,3))==0)
      {
	argc--; argv++;
	area = TRUE;

	if(argc==0 || !UnitsValidS(*argv)) goto usage;
	rect.r_ll.p_x = UnitsS2I(*argv);
	argc--; argv++;
	if(argc==0 || !UnitsValidS(*argv)) goto usage;
	rect.r_ll.p_y = UnitsS2I(*argv);
	argc--; argv++;
	if(argc==0 || !UnitsValidS(*argv)) goto usage;
	rect.r_ur.p_x = UnitsS2I(*argv);
	argc--; argv++;
	if(argc==0 || !UnitsValidS(*argv)) goto usage;
	rect.r_ur.p_y = UnitsS2I(*argv);
	argc--; argv++;
	continue;
      }

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

      if((c=='k') && (strncmp(*argv,"-kind",length) == 0)) 
      {
	argc--; argv++;
	if(argc<1) goto usage;
	kind = DBLabelKindParse(*argv);
	if(kind<0) goto usage;
	argc--; argv++;
	continue;
      }
	
      if(c=='l' && strncmp(*argv,"-limit",length)==0)
      {
	argc--; argv++;

	if(argc==0) goto usage;
	limit = atoi(*argv);
	argc--; argv++;
	
	continue;
      }

      if(c=='n' && strncmp(*argv,"-no_glob",MAX(length,4))==0)
      {
	noGlob = TRUE;
	argc--; argv++;
	continue;
      }

      if(c=='n' && strncmp(*argv,"-non_hier",MAX(length,4))==0)
      {
	nonHier = TRUE;
	argc--; argv++;
	continue;
      }

      /* unrecognized option */
      goto usage;
	
    } /* end while(argc>0 && **argv=='-')  */

    /* pattern arg.  
     *  Only labels with text matching pattern (glob-style) are
     * returned.
     */
    if (argc)
    {
      pattern = *argv;
      argc--; argv++;
    }
    
    /* should be no args left */
    if(argc!=0) goto usage;
  }

  /* setup result limit */
  dbCountMax = limit;
  dbCount = 0;

  if(def)
  {
    DBCellInitTempUse(def, &dummy); 
    rootUse = &dummy;

    /* look inside all subcells */
    expansionMask = 0;
  }
  else
  {
    /* default to rootcell in window */
    Layout *l = LayCurWindow();

    rootUse = l->lay_rootUse;

    /* look inside subcells expanded in window */
    expansionMask = l->lay_bitmask;  
  }

  /* set up search flags */
  flags = nonHier ? DBSL_NON_RECURSIVE : 0;
 
  /* Setup search context */
  scx.scx_use = rootUse;
  scx.scx_trans = GeoIdentityTransform;
  scx.scx_area = area ? rect : *DBBBoxCellUse(rootUse);

  /* Do the search */
  dbResult =  Tcl_NewListObj(0,0);
  labelsKind = kind;
  if(noGlob)
  {
    TerminalPath tpath;
    char buf[BUFSIZ];	        /* String buffer in which the full 
				 * pathname of each label is assembled 
				 * for handing to the filter function.
				 */

    buf[0] = '\0';
    tpath.tp_first = tpath.tp_next = buf;
    tpath.tp_last = &buf[BUFSIZ - 2];

    DBSearchLabels2(&scx, 
		    &DBAllTypeBits, 
		    NULL, /* location unknown */
		    pattern,
		    expansionMask, 
		    &tpath,
		    dbTclCmdSearchLabelsLFunc,
		    (ClientData) interp,
		    flags);
  }
  else
  {
    DBSearchLabelsGlob(&scx, 
		       &DBAllTypeBits, 
		       expansionMask, 
		       pattern, 
		       dbTclCmdSearchLabelsLFunc,
		       (ClientData) interp,
		       flags);
  }

  /* return result */
  Tcl_SetObjResult(interp,dbResult);
  CMD_RETURN(interp);

 usage:
  MsgErrorF("usage:  %s [-cell def_name] [-non_hier] [-area xbot ybot xtop ytop] [-limit n] [-kind kind] [glob_pattern]",
	    cmdName); 
  CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * dbTclCmdSearchSrTouchingTypesL --
 *
 *	Implement db_search_touching_types
 *
 * Result:
 *	A standard Tcl result.
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */
#define db_search_touching_types_DESC "find layers at point"

#define db_search_touching_types_DOC "
Usage:  db_search_touching_types x y

       returns list of layers present at indicated (rootcell) coordinates
       (does not look inside unexpanded subcells)

NOTE: Returns tcl list object:  no new-lines!
"
static int
dbTclCmdSearchTouchingTypesL(ClientData clientData,
			     Tcl_Interp *interp, 
			     int argc, 
			     char **argv)
{
    int expansionMask;
    CellUse *rootUse;
    Point point;
    TileTypeBitMask tTypes;
    char *cmdName;

    CMD_BEGIN(interp);      

    /* parse command name */
    cmdName = *argv;
    argc--; argv++;

    /* parse x */
    if(!argc || !UnitsValidS(*argv)) goto usage; 
    point.p_x = UnitsS2I(*argv);
    argc--; argv++;

    /* parse y */
    if(!argc || !UnitsValidS(*argv)) goto usage; 
    point.p_y = UnitsS2I(*argv);
    argc--; argv++;

    if(argc) goto usage;
    
    /* Get expansion mask and rootcell from current Layout window */
    {
        Layout *l = LayCurWindow();
	expansionMask = l->lay_bitmask;
	rootUse = l->lay_rootUse;
    }

    /* look up touching types */
    tTypes = DBSrTouchingTypes(rootUse, expansionMask, &point, 0 /* flags */);

    /* return names of types found */
    {
      int i;

      Tcl_Obj *result = Tcl_NewListObj(0,0);

      for (i = 0; i < DBNumUserLayers; i++)
      {
	if(TTMaskHasType(&tTypes, i))
	{
	  TListAppendStr(interp, result, DBTypeLongName(i));	
        }
      }
      Tcl_SetObjResult(interp,result);
    }
    CMD_RETURN(interp);

 usage:
    MsgErrorF("usage:  %s x y\n",cmdName);
    CMD_RETURN(interp); 
}


/*
 *--------------------------------------------------------------
 *
 * dbTclCmdSearchX --
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
#define db_search_DESC "search database (OBSOLETE)"

#define db_search_DOC "
Usage:  db_search subcommand [args]

OBSOLETE AND INEFFICIENT:  please use db_search_* commands instead!

Subcommands:
    touchingtypes x y
       returns list of layers present at indicated (rootcell) coordinates
       (does not look inside unexpanded subcells)

    cells [-cell def_name] [-any_cell] [-area xbot ybot xtop ytop] [-limit n]
       returns a line for each instance in editcell
       of the form:
         \"instanceName defName xbot ybot xtop ytop path expansion transform arrayInfo\"
       (root cell coordinates).

       xbot ybot xtop ytop = bounding box

       path = 'EDIT_CELL_PATH' if -any_cell is not specified.
	      If -any_cell is specified, it is the path from
	      the root cell to the cell containing the instance,
	      or {} (null list) if the instance is directly in the rootcell.

       expansion = 'expanded' if internals visible, else {} (null list) 
       transform = {a b c d e f}  (first two columns of 3x3 transform matrix
                                   last column is {0 0 1})
       arrayInfo = {xindex yindex xlo xhi ylo yhi xsep ysep} 
                   (or NULL if not array)

          NOTES ON ARRAYS:  if an arrayed cell is rotated or flipped,
	  max modifies the transform and arrayinfo.  If an array
	  is rotated, the xlo/xhi and ylo/yhi are swapped so that
	  the x info is always horizontal, and y info is vertical.
	  The xsep and ysep may be positive or negative to indicate
	  the direction in which array elements are currently numbered.

       If -any_cell, instances are not restricted to editcell, rather
       all instances in rootcell and in expanded descendents are given.

       If -cell given, search named cell instead of root (or edit) cell.
       (coordinates are in terms of def_name)

       If -cell AND -any_cell, gives all descendents of the named cell.

       If -limit n, output is limited to n matchs.

    labels [-cell def_name] [-non_hier] [-area xbot ybot xtop ytop] [-limit n] [-kind kind] [glob_pattern] 

       returns a line for each labels in (rootcell or expanded descendents) 
       of the form:  
       \"layer xbot ybot xtop ytop pos text instance_path group kind\"
       (root cell coordinates).

       If -non_hier, don't search instances.
       
       If -kind, prints only labels of given kind (i.e. in, out, in_out,
       local, global, text, or hidden)
 
       If glob_pattern is given, only labels with text matching the 
       pattern are returned.

       Glob matching uses the characters: * ? [ ]
       To match one of these characters, precede it with a backslash.
       Note that both the backslash and bracket characters are special
       to tcl, and so must be enclosed in curly braces.
       To search for the label x[1], you must use:

	   db_search labels {x\\[1\\]}

       NOTE:  Searching for labels with specific text (no
       wild-carding) is very efficient.  Wild-carded searches
       are inefficient.

       If -cell given, search named cell instead of root cell.
       (coordinates are in terms of def_name)

       If -limit n, output is limited to n matchs.

    paint [-cell def_name] [-any_cell] [-area xbot ybot xtop ytop] [-limit n] [layers]
       returns a line for each paint rectangle in editcell
       of the form:
         \"layer xbot ybot xtop ytop instance_path group\"
       (root cell coordinates).

       If -any_cell present, paint is not restricted to editcell, rather
       any paint in rootcell or expanded descendents, is given.

       If -cell given, search named cell instead of root (or edit) cell.
       (coordinates are in terms of def_name

       If -cell AND -any_cell, looks inside all descendents of named cell
       regardless of expansion mask.

       If -limit n, output is limited to n matchs.

    polygons [-cell] [-any_cell] [-area xbot ybot xtop ytop] [-limit n] [layers] 
       returns a line for each polygon in editcell
       of the form:
         \"layer bbox coordinates attributes instance_path group\"
       (root cell coordinates).

       If -any_cell present, polygons are not restricted to editcell, rather
       any polygon in rootcell or expanded descendents, is given.

       If -cell given, search named cell instead of root (or edit) cell.
       (coordinates are in terms of def_name

       If -cell AND -any_cell, looks inside all descendents of named cell
       regardless of expansion mask.

       If -limit n, output is limited to n matchs.

    wirepaths [-cell] [-any_cell] [-area xbot ybot xtop ytop] [-limit n] [layers]
       returns a line for each paint rectangle in editcell
       of the form:
         \"layer bbox width coordinates attributes instance_path group\"
       (root cell coordinates).

       If -any_cell present, wirepaths are not restricted to editcell, rather
       any wirepath in rootcell or expanded descendents, is given.

       If -cell given, search named cell instead of root (or edit) cell.
       (coordinates are in terms of def_name

       If -cell AND -any_cell, looks inside all descendents of named cell
       regardless of expansion mask.

       If -limit n, output is limited to n matchs.
"

static int
dbTclCmdSearch(ClientData clientData, 
	       Tcl_Interp *interp, 
	       int argc, 
	       char **argv)
{
  char *cmdName;
  char *subCmd;
  Tcl_DString script;

  CMD_BEGIN(interp);

  /* get cmd name */
  cmdName = *argv;
  argc--;argv++;

  /* get sub command */
  if(!argc) 
  {
    MsgErrorF("wrong # args: should be \"%s sub_command [arg arg ...]\"",
	      cmdName);
    CMD_RETURN(interp);
  }
  subCmd = *argv;
  argc--; argv++;

  /* special case wirepaths */
  if(strncmp(subCmd,"wirepaths",strlen(subCmd))==0) subCmd = "wire_paths";


  /* build script */

  /* build script */
  if(strncmp("touchingtypes",subCmd,strlen(subCmd))==0)
  {
    /* special case 'db_search touchingtypes' */

    Tcl_DStringInit(&script);

    /* command */
    Tcl_DStringAppend(&script, "db_search_touching_types", -1);

    /* args */
    while(argc)
    {
      Tcl_DStringAppendElement(&script, *argv);
      argc--;argv++;
    }

    /* suffix */
    Tcl_DStringAppend(&script,"\n", -1);
  }
  else
  {
    Tcl_DStringInit(&script);

    /* prefix */
    Tcl_DStringAppend(&script, "join [db_search_", -1);

    /* subCmd */
    Tcl_DStringAppend(&script, subCmd, -1);

    /* args */
    while(argc)
    {
      Tcl_DStringAppendElement(&script, *argv);
      argc--;argv++;
    }

    /* suffix */
    Tcl_DStringAppend(&script,"] \\n \n", -1);
  }

  /* run the script */
  if(Tcl_Eval(interp,Tcl_DStringValue(&script))!=TCL_OK)
  {
    MsgErrorF("%s",Tcl_GetStringResult(interp));
  }

  /* clean up */
  Tcl_DStringFree(&script);

  CMD_RETURN(interp);
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbTclSearchInit --
 *
 * Initialize tcl commands in this file.
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
dbTclSearchInit(Tcl_Interp *interp)
{
   MnDocCreateCommand(interp, 
		      "db_search_paint", 
		      dbTclCmdSearchPaintL,
		      (ClientData) NULL, 
		      (Tcl_CmdDeleteProc *) NULL,
		      db_search_paint_DESC,
		      db_search_paint_DOC);

   MnDocCreateCommand(interp, 
		      "db_search_polygons", 
		      dbTclCmdSearchPolygonsL,
		      (ClientData) NULL, 
		      (Tcl_CmdDeleteProc *) NULL,
		      db_search_polygons_DESC,
		      db_search_polygons_DOC);

   MnDocCreateCommand(interp, 
		      "db_search_wire_paths", 
		      dbTclCmdSearchWirePathsL,
		      (ClientData) NULL, 
		      (Tcl_CmdDeleteProc *) NULL,
		      db_search_wire_paths_DESC,
		      db_search_wire_paths_DOC);

   MnDocCreateCommand(interp, 
		      "db_search_cells", 
		      dbTclCmdSearchCellsL,
		      (ClientData) NULL, 
		      (Tcl_CmdDeleteProc *) NULL,
		      db_search_cells_DESC,
		      db_search_cells_DOC);

   MnDocCreateCommand(interp, 
		      "db_search_labels", 
		      dbTclCmdSearchLabelsL,
		      (ClientData) NULL, 
		      (Tcl_CmdDeleteProc *) NULL,
		      db_search_labels_DESC,
		      db_search_labels_DOC);

   MnDocCreateCommand(interp, 
		      "db_search_touching_types", 
		      dbTclCmdSearchTouchingTypesL,
		      (ClientData) NULL, 
		      (Tcl_CmdDeleteProc *) NULL,
		      db_search_touching_types_DESC,
		      db_search_touching_types_DOC);

   MnDocCreateCommand(interp, 
		      "db_search", 
		      dbTclCmdSearch,
		      (ClientData) NULL, 
		      (Tcl_CmdDeleteProc *) NULL,
		      db_search_DESC,
		      db_search_DOC);

   /* TODO: cells, polygons, wp */ 
}


