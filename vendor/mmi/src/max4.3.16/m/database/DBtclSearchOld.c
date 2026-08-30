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
 * DBtclSearchOld.c -- keep old db_search command intact here.
 *                     To be rendered OBSOLETE by db_search_*_l commands.
 *                     TODO: replace by wrapper.
 */

static char rcsid[] = "$Header$";

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


/*
 *--------------------------------------------------------------
 *
 * dbTclCmdSearchLabels --
 *
 *	Implement labels subcommand for dbTclCmdSearch.
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

/* newlines before all but first label */
static int labelsFirst;

/* if non-negative, label kind must match */
static int labelsKind;

/* func for label search below */
int
dbTclCmdSearchLabelsFunc(SearchContext *scx, 
			 Label *label, 
			 TerminalPath *tpath,
			 ClientData clientdata)
{
    Tcl_Interp *interp = (Tcl_Interp *) clientdata;

    if (SigInterruptPending) return 1; 

    /* if kind specified, skip non-matches */
    if(labelsKind>=0 && label->lab_kind != labelsKind) return 0;

    /* output newline prior to all but first cell */
    if(!labelsFirst)
    {
        Tcl_AppendResult(interp,"\n", (char *) NULL);
    }
    labelsFirst = FALSE;

    /* output label type longname */
    Tcl_AppendResult(interp,DBTypeLongName(label->lab_type), (char *) NULL);

    /* output rect in user root coords */
    {
      Rect r;

      GeoTransRect(&scx->scx_trans, &label->lab_rect, &r);
      Tcl_AppendElement(interp, UnitsI2S(r.r_xbot));
      Tcl_AppendElement(interp, UnitsI2S(r.r_ybot));
      Tcl_AppendElement(interp, UnitsI2S(r.r_xtop));
      Tcl_AppendElement(interp, UnitsI2S(r.r_ytop));
    }

    /* output label position */
    {
      int rootPos = GeoTransPos(&scx->scx_trans, label->lab_pos);
      Tcl_AppendElement(interp, GeoPosToName(rootPos));
    }

    /* output label text */
    Tcl_AppendElement(interp, label->lab_text);

    /* output hierarchical instance path from root to label */
    Tcl_AppendElement(interp, tpath->tp_first);

    /* output  group */
    Tcl_AppendElement(interp, label->lab_group?label->lab_group->g_name:"0");

    /* output kind */
    Tcl_AppendElement(interp, DBLabelKindName(label->lab_kind));

    /* return of 0 continues search, 1 aborts search */
    if(++dbCount >= dbCountMax) return 1;
    return 0;  
}

void 
dbTclCmdSearchLabels(Tcl_Interp *interp, int argc, char **argv)
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
  int limit = INT_MAX;

  int kind = -1;  /* if non-negative label kind must match */

  int planeMask;

  /* process args */
  {
    cmdName = *argv;
    argc--; argv++;
      
    /* skip "labels" */
    argc--; argv++;
    ASSERT(argc>=0,"dbTclCmdSearchLabels");

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
	  return;
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

      if(c=='n' && strncmp(*argv,"-non_hier",length)==0)
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
    DBCellUseNewTemp(def, &dummy); 
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
  labelsFirst = TRUE;
  labelsKind = kind;
  DBSearchLabelsGlob(&scx, 
		     &DBAllTypeBits, 
		     expansionMask, 
		     pattern, 
		     dbTclCmdSearchLabelsFunc,
		     (ClientData) interp,
		     flags);

  return;

 usage:
  MsgErrorF("usage:  %s labels [-cell def_name] [-non_hier] [-area xbot ybot xtop ytop] [-limit n] [-kind kind] [glob_pattern]",
	    cmdName); 
  return;
}


/*
 *--------------------------------------------------------------
 *
 * dbTclCmdSearchDBSrTouchingTypes --
 *
 *	Implement Touchingtyles subcommand for dbTclCmdSearch below.
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Tcl Result:
 *      List of tile types touching designated point in current cell
 *      or descendents.
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */
void
dbTclCmdSearchDBSrTouchingTypes(Tcl_Interp *interp, int argc, char **argv)
{
    int expansionMask;
    CellUse *rootUse;
    Point point;
    TileTypeBitMask tTypes;

    /* check args */
    if( (argc != 4) || !UnitsValidS(argv[2]) ||  !UnitsValidS(argv[3]) )
    {
         MsgErrorF("usage:  %s touchingtypes <x> <y>\n",argv[0]); 
         return; 
    }
    
    /* Get expansion mask and rootcell from current Layout window */
    {
        Layout *l = LayCurWindow();
	expansionMask = l->lay_bitmask;
	rootUse = l->lay_rootUse;
    }

    /* Get point from args */
    point.p_x = UnitsS2I(argv[2]);
    point.p_y = UnitsS2I(argv[3]);

    /* look up touching types */
    tTypes = DBSrTouchingTypes(rootUse, expansionMask, &point, 0 /* flags */);

    /* return longnames of types found */
    {
        int i;
        int first = TRUE;

        for (i = 0; i < DBNumUserLayers; i++)
	{
	    if(TTMaskHasType(&tTypes, i))
	    {
	        if(!first) Tcl_AppendResult(interp, " ", NULL);	
	        first = FALSE;
                Tcl_AppendResult(interp, DBTypeLongName(i), NULL);	
	    }
        }
    }
}

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
  Rect rootRect;

  GeoTransRect(&scx->scx_trans, rect, &rootRect);

  /* separate rects in result with newlines */
  if(interp->result && interp->result[0]!='\0') Tcl_AppendResult(interp,"\n",NULL);

  /* add rect to result */
  Tcl_AppendResult(interp, DBTypeLongName(type), NULL);

  /* coordinates in user root cell */ 
  Tcl_AppendElement(interp, UnitsI2S(rootRect.r_xbot));
  Tcl_AppendElement(interp, UnitsI2S(rootRect.r_ybot));
  Tcl_AppendElement(interp, UnitsI2S(rootRect.r_xtop));
  Tcl_AppendElement(interp, UnitsI2S(rootRect.r_ytop));

  /* output hierarchical instance path from root */
  Tcl_AppendElement(interp, tpath->tp_first);

  /*  group */
  Tcl_AppendElement(interp, group?group->g_name:"0");
}


/* callback func for dbTclCmdSearch2 for paint tiles */
int dbPaintFunc(Tile *tile, TreeContext *cxp)
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
int dbPolyFunc(SearchContext *scx, 
	       Polygon *poly, 
	       ClientData cdarg, 
	       TerminalPath *tpath)
{
  Tcl_Interp *interp = (Tcl_Interp *) cdarg;

  /* separate polygons in result with newlines */
  if(interp->result && interp->result[0]!='\0') 
    Tcl_AppendResult(interp,"\n",NULL);

  /* layer */
  Tcl_AppendElement(interp, DBTypeLongName(poly->poly_type));

  /* bbox */
  {
    Rect bbox;

    GeoTransRect(&scx->scx_trans, &poly->poly_bbox, &bbox);

    Tcl_AppendResult(interp, " {", (char *) NULL);
    Tcl_AppendElement(interp, UnitsI2S(bbox.r_xbot));
    Tcl_AppendElement(interp, UnitsI2S(bbox.r_ybot));
    Tcl_AppendElement(interp, UnitsI2S(bbox.r_xtop));
    Tcl_AppendElement(interp, UnitsI2S(bbox.r_ytop));
    Tcl_AppendResult(interp, "}", (char *) NULL);
  }

  /* points */
  {
    PointFloat *p;
    int i;

    Tcl_AppendResult(interp, " {", (char *) NULL);
    p = poly->poly_points;
    for(i=0; i< poly->poly_size; i++)
    {
      PointFloat pRoot;
      GeoTransPointF(&scx->scx_trans, p, &pRoot);

      Tcl_AppendElement(interp, UnitsF2S(pRoot.pf_x));
      Tcl_AppendElement(interp, UnitsF2S(pRoot.pf_y));
      p++;
    }
    Tcl_AppendResult(interp, "}", (char *) NULL);
  }

  /* attributes */
  Tcl_AppendResult(interp, " {", (char *) NULL);
  if(poly->poly_wirePath) Tcl_AppendResult(interp, "dependent", (char *) NULL);
  Tcl_AppendResult(interp, "}", (char *) NULL);

  /* hierarchical instance path from root */
  Tcl_AppendElement(interp, tpath->tp_first);

  /*  group */
  Tcl_AppendElement(interp, poly->poly_group?poly->poly_group->g_name:"0");

  /* continue search */
  if(++dbCount >= dbCountMax) return 1;
  return 0;
}

/* callback func for dbTclCmdSearch2 for cells */
Layout *dbSearchLayout;
int dbCellsFunc(SearchContext *scx, 
		ClientData cdarg, 
		TerminalPath *tpath)
{
  Tcl_Interp *interp = (Tcl_Interp *) cdarg;
  CellUse *use = scx->scx_use;
  Transform *trans = &scx->scx_trans;

  /* separate cells in result with newlines */
  if(interp->result && interp->result[0]!='\0') Tcl_AppendResult(interp,"\n",NULL);

  /* output instance name */
  Tcl_AppendElement(interp,use->cu_id);

  /* output cellname */
  Tcl_AppendElement(interp,use->cu_def->cd_name);

  /* output bbox in rootcell user coords ( = Select cell coords) */
  {
    Rect bbox;

    GeoTransRect(&scx->scx_trans, DBBBoxCellDef(use->cu_def), &bbox);

    Tcl_AppendElement(interp, UnitsI2S(bbox.r_xbot));
    Tcl_AppendElement(interp, UnitsI2S(bbox.r_ybot));
    Tcl_AppendElement(interp, UnitsI2S(bbox.r_xtop));
    Tcl_AppendElement(interp, UnitsI2S(bbox.r_ytop));
  }

  /* output path to instance */
  Tcl_AppendElement(interp, tpath->tp_first); 

  /* output expansion status */
  Tcl_AppendElement(interp, 
		    DBIsExpand(use, dbSearchLayout->lay_bitmask)? "expanded":"");

  /* output transform from instance to root coordinates */
  {
    char c[100];
    char f[100];
    char buf[1000];

    strcpy(c,UnitsI2S(trans->t_c));
    strcpy(f,UnitsI2S(trans->t_f));
    sprintf(buf," {%d %d %s %d %d %s} ",
	    trans->t_a,
	    trans->t_b,
	    c,
	    trans->t_d,
	    trans->t_e,
	    f);

    Tcl_AppendResult(interp, buf, NULL);
  }

  /* output array info */
  if(!DBIsArray(use))
  {
    Tcl_AppendElement(interp,"");
  }
  else
  {
    ArrayInfo ar;
    char xsep[100];
    char ysep[100];
    char buf[1000];

    /* convert array info to rootcell */
    DBArrayTransformInfo(trans, &use->cu_array, &ar);
    
    strcpy(xsep,UnitsI2S(ar.ar_xsep));
    strcpy(ysep,UnitsI2S(ar.ar_ysep));
    sprintf(buf," {%d %d %d %d %d %d %s %s} ",
	    scx->scx_x, /* array indices of this element of array */
	    scx->scx_y,
	    ar.ar_xlo,  /* indice ranges */
	    ar.ar_xhi, 
	    ar.ar_ylo, 
	    ar.ar_yhi, 
	    xsep, 
	    ysep); 
    
    Tcl_AppendResult(interp, buf, NULL);
  }

  /* continue search */
  if(++dbCount >= dbCountMax) return 1;
  return 0;
}

/* callback func for dbTclCmdSearch2 for wirepaths */
int dbWPFunc(SearchContext *scx, 
	     WirePath *wp, 
	     ClientData cdarg, 
	     TerminalPath *tpath)
{
  Tcl_Interp *interp = (Tcl_Interp *) cdarg;

  /* separate wirepaths in result with newlines */
  if(interp->result && interp->result[0]!='\0') 
    Tcl_AppendResult(interp,"\n",NULL);

  /* layer */
  Tcl_AppendElement(interp, DBTypeLongName(wp->wp_type));

  /* bbox */
  {
    Rect bbox;

    GeoTransRect(&scx->scx_trans, &wp->wp_bbox, &bbox);

    Tcl_AppendResult(interp, " {", (char *) NULL);
    Tcl_AppendElement(interp, UnitsI2S(bbox.r_xbot));
    Tcl_AppendElement(interp, UnitsI2S(bbox.r_ybot));
    Tcl_AppendElement(interp, UnitsI2S(bbox.r_xtop));
    Tcl_AppendElement(interp, UnitsI2S(bbox.r_ytop));
    Tcl_AppendResult(interp, "}", (char *) NULL);
  }

  /* width */
  Tcl_AppendElement(interp, UnitsI2S(wp->wp_width));

  /* points */
  {
    Point *p;
    int i;

    Tcl_AppendResult(interp, " {", (char *) NULL);
    p = wp->wp_points;
    for(i=0; i< wp->wp_size; i++)
    {
      Point pRoot;
      GeoTransPoint(&scx->scx_trans, p, &pRoot);

      Tcl_AppendElement(interp, UnitsI2S(pRoot.p_x));
      Tcl_AppendElement(interp, UnitsI2S(pRoot.p_y));
      p++;
    }
    Tcl_AppendResult(interp, "}", (char *) NULL);
  }

  /* attributes */
  Tcl_AppendResult(interp, " {", (char *) NULL);

  /* endcap style */
  switch (wp->wp_style)
  {
  case WP_STYLE_FLUSH:
    Tcl_AppendElement(interp, "flush");
    break;

  case WP_STYLE_ROUNDED:
    Tcl_AppendElement(interp, "rounded");
    break;

  case WP_STYLE_HALFWIDTH:
    Tcl_AppendElement(interp, "half_width");
    break;

  default:
    ASSERT(FALSE,"dbWPFunc");
    break;
  }

  Tcl_AppendResult(interp, "}", (char *) NULL);

  /* output hierarchical instance path from root */
  Tcl_AppendElement(interp, tpath->tp_first);

  /*  group */
  Tcl_AppendElement(interp, wp->wp_group?wp->wp_group->g_name:"0");

  /* continue search */
  if(++dbCount >= dbCountMax) return 1;
  return 0;
}


/*
 *--------------------------------------------------------------
 *
 * dbTclCmdSearch2 --
 *
 *	Implement cells, paint, poly and wirepath subcommand 
 *      for dbTclCmdSearch below.
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Tcl Result:
 *      List describing rects in current cell and expanded
 *      descendents.
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */
void
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
      
      /* skip "paint" */
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
	DBCellUseNewTemp(def, &dummy); 
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

    return;

usage:
    MsgErrorF("usage:  %s cells|paint|polygons|wirepaths [-cell def_name] [-any_cell] [-area xbot ybot xtop ytop] [-limit n] [layers]\n",cmdName); 
    return; 
}


/*
 *--------------------------------------------------------------
 *
 * dbTclCmdSearch --
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
#define db_search_DESC "search (layout) database - OLD VERSION OF db_search RESTORED FOR DEBUGGING"

#define db_search_DOC "
Usage:  db_search subcommand [args]

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
dbTclCmdSearch(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
    int length;
    char c;

    CMD_BEGIN(interp);

    /* check arg count */
    if (argc < 2) 
    {
	MsgErrorF("wrong # args: should be \"%.50s option [arg arg ...]\"",argv[0]);
	CMD_RETURN(interp);
    }

    /* pass off to appropriate subcommand procedure */
    c = argv[1][0];
    length = strlen(argv[1]);

    if ((c == 'c') && (strncmp(argv[1], "cells", length) == 0)) 
    {
        dbTclCmdSearch2(interp,argc,argv, FALSE, FALSE, FALSE, TRUE);
	CMD_RETURN(interp);
    }
    if ((c == 'l') && (strncmp(argv[1], "labels", length) == 0)) 
    {
        dbTclCmdSearchLabels(interp,argc,argv);
	CMD_RETURN(interp);
    }
    else if ((c == 't') && (strncmp(argv[1], "touchingtypes", length) == 0)) 
    {
        dbTclCmdSearchDBSrTouchingTypes(interp,argc,argv);
	CMD_RETURN(interp);
    }
    else if ((c == 'p') && (strncmp(argv[1], "paint", length) == 0)) 
    {
        dbTclCmdSearch2(interp,argc,argv, TRUE, FALSE, FALSE, FALSE );
	CMD_RETURN(interp);
    }
    else if ((c == 'p') && (strncmp(argv[1], "polygons", length) == 0)) 
    {
        dbTclCmdSearch2(interp,argc,argv, FALSE, TRUE, FALSE, FALSE );
	CMD_RETURN(interp);
    }
    else if ((c == 'w') && (strncmp(argv[1], "wirepaths", length) == 0)) 
    {
        dbTclCmdSearch2(interp,argc,argv, FALSE, FALSE, TRUE, FALSE);
	CMD_RETURN(interp);
    }
    else 
    {
	MsgErrorF("%s:  bad option \"%.50s\".  Valid options are:\n\t"
		"cells touchingtypes labels paint polygons wirepaths", 
		argv[0], argv[1]);
	CMD_RETURN(interp);
    }
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbTclSearchOldInit --
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
dbTclSearchOldInit(Tcl_Interp *interp)
{

   MnDocCreateCommand(interp, "db_search_old", dbTclCmdSearch,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_search_DESC,
	       db_search_DOC);
}


