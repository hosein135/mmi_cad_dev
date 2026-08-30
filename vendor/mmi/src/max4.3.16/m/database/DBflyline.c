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
 * DBflyline.c --
 *
 * FlyLine primitives.
 *
 */

#ifndef lint
static char rcsid[] = "$Header$";
#endif  not lint

#include <stdio.h>
#include <string.h>
#include "magic.h"
#include "database.h"
#include "databaseInt.h"
#include "memory.h"
#include "message.h"
#include "geometry.h"
#include "utils.h"
#include "layout.h"
#include "debug.h"

/* tcl linked, if reset, flylines are treated as annotations only */
bool dbFlylinesSave = TRUE;  

/* set on first flyline add,
 * don't do flyline updates if not set!
 */
bool DBFlyLinesExist = FALSE;

static CellDef *dbFlyLabelDef;
static int dbFlyLabelFunc(SearchContext *scx, 
			  Rect *rect, 
			  char *name, 
			  Label *label, 
			  ClientData cdarg)
{
    Rect *loc = (Rect *) cdarg;
    GEO_COPY_RECT(rect,loc);

    dbFlyLabelDef = scx->scx_use->cu_def;

    /* stop search on first match */
    return 1;
}

/* compute fly line position, adjust bounding box, and notify Layout module
 * of areas that need to be redisplayed 
 */

static void dbFlyLineDraw(CellDef *def, FlyLine *fl)
{
   Rect loc;
   bool newLoc = FALSE;
   bool wasVis = (fl->flay_flags&FL_P1_VALID && fl->flay_flags&FL_P2_VALID);
   
   /* first label */
   loc.r_xbot = 1; loc.r_xtop = -1; /* inverted coords signal not found */
   DBLabelFindByPathNameDef(def,fl->fl_name1,dbFlyLabelFunc,&loc, TRUE /* no Load */); 
   if(loc.r_xtop < loc.r_xbot)
   {
     /* label not found */
     fl->flay_flags &= ~FL_P1_VALID;
   }
   else
   {
     float x = (loc.r_xbot + loc.r_xtop)/2.0;
     float y = (loc.r_ybot + loc.r_ytop)/2.0;

     fl->fl_def1 = dbFlyLabelDef;

     if(!(fl->flay_flags & FL_P1_VALID) || x!=fl->fl_p1.pf_x || y!=fl->fl_p1.pf_y)
     {
       newLoc = TRUE;
       fl->fl_p1.pf_x = x;
       fl->fl_p1.pf_y = y;
       fl->flay_flags |= FL_P1_VALID;
     }
   }
      
   /* second label */
   loc.r_xbot = 1; loc.r_xtop = -1; /* inverted coords signal not found */
   DBLabelFindByPathNameDef(def,fl->fl_name2,dbFlyLabelFunc,&loc, TRUE /* noLoad */); 
   if(loc.r_xtop < loc.r_xbot)
   {
     /* label not found */
     fl->flay_flags &= ~FL_P2_VALID;
   }
   else
   {
     float x = (loc.r_xbot + loc.r_xtop)/2.0;
     float y = (loc.r_ybot + loc.r_ytop)/2.0;

     fl->fl_def2 = dbFlyLabelDef;

     if(!(fl->flay_flags & FL_P2_VALID) || x!=fl->fl_p2.pf_x || y!=fl->fl_p2.pf_y)
     {
       newLoc = TRUE;
       fl->fl_p2.pf_x = x;
       fl->fl_p2.pf_y = y;
       fl->flay_flags |= FL_P2_VALID;
     }
   }

   /* adjust bounding box and notify redisplay code */
   {
     bool isVis = (fl->flay_flags&FL_P1_VALID && fl->flay_flags&FL_P2_VALID);

     /* redisplay old bounding box */
     if(wasVis && (!isVis || newLoc))
     {
       DBChangedArea(def, &fl->fl_bbox, &DBFlyLineBits, DBCF_DISPLAY_ONLY);
     }

     /* compute new bounding box */
     if(!isVis)
     {
       GEO_COPY_RECT(&GeoNullRect, &fl->fl_bbox);
     }
     else if (newLoc)
     {
         /* grow bounding box one unit to avoid zero area 
          * and any other nasty boundary conditions.
	  */
         fl->fl_bbox.r_xbot = ROUND(MIN(fl->fl_p1.pf_x,fl->fl_p2.pf_x)) - 1;
         fl->fl_bbox.r_ybot = ROUND(MIN(fl->fl_p1.pf_y,fl->fl_p2.pf_y)) - 1;
         fl->fl_bbox.r_xtop = ROUND(MAX(fl->fl_p1.pf_x,fl->fl_p2.pf_x)) + 1;
         fl->fl_bbox.r_ytop = ROUND(MAX(fl->fl_p1.pf_y,fl->fl_p2.pf_y)) + 1;
     }

     /* redisplay new bounding box */
     if (newLoc)
     {
       DBChangedArea(def, &fl->fl_bbox, &DBFlyLineBits, DBCF_DISPLAY_ONLY);
     }
   }
}

/*
 * ----------------------------------------------------------------------------
 *
 * dbFlyLineAdd --
 *
 * Add a flyline to given cell.
 *
 * ----------------------------------------------------------------------------
 */
void
dbFlyLineAdd(CellDef *def,       /* Cell in which flyline is to be added */
	    char *name1,         /* hierarchical name of first label */
	    char *name2,         /* hierarchical name of second label */
	    int width,           /* width in pixels */
	    char *text)          /* text to display with flyline (or NULL) */ 
{
    FlyLine *new;

    /* ok got to do flyline updates from now on. */
    DBFlyLinesExist = TRUE;

    /* create flyline */
    CALLOC(FlyLine *, new, sizeof(FlyLine));
    new->fl_name1 = StrDup(NULL, name1);
    new->fl_name2 = StrDup(NULL, name2);
    new->fl_width = width;
    new->fl_text = NULL;
    if(text && text!='\0') new->fl_text = StrDup(NULL,text);

    new->fl_next = def->cd_flyLines;
    GEO_COPY_RECT(&GeoNullRect, &new->fl_bbox);
    def->cd_flyLines = new;

    /* compute flyline position */
    dbFlyLineDraw(def,new);

    if(dbFlylinesSave)
    {
      /* record with undo */
      dbUndoFlyLineAdd(def, name1, name2, width, text);
    }

}

/*
 * ----------------------------------------------------------------------------
 *
 * dbFlyLineDelete --
 *
 * Delete flyline(s) from cell.
 *
 * If name1 and name2 are NULL, deletes all flylines.
 * If name1 is given name2 is NULL,  deletes all fly lines to named label.
 * If name1 and name2 are given, deletes flyline connecting them.
 *
 * ----------------------------------------------------------------------------
 */

/* check if flyline matches names */
bool dbFlyLineMatchProc(FlyLine *fl, char *name1, char *name2)
{
  if(name1 == NULL) return 1;

  if(strcmp(name1,fl->fl_name1)==0)
  {
    if(name2 == NULL) return 1;
    if(strcmp(name2,fl->fl_name2)==0) return 1;
  }
  else if(strcmp(name1,fl->fl_name2)==0)
  {
    if(name2 == NULL) return 1;
    if(strcmp(name2,fl->fl_name1)==0) return 1;
  }    
  
  return 0;
}

/* delete flyline (unlinking done elsewhere) */
static void dbFlyLineDelete1(CellDef *def,FlyLine *fl)
{

  bool wasVis = (fl->flay_flags&FL_P1_VALID && fl->flay_flags&FL_P2_VALID);

  /* mark bbox for redisplay to "erase" flyline */
  if(wasVis)
  {
    DBChangedArea(def, &fl->fl_bbox, &DBFlyLineBits, DBCF_DISPLAY_ONLY);
  }

  if(dbFlylinesSave)
  {
    /* record with undo */
    dbUndoFlyLineDelete(def, fl->fl_name1, fl->fl_name2, fl->fl_width, fl->fl_text);
  }

  FREE(fl->fl_name1);
  FREE(fl->fl_name2);
  if(fl->fl_text) FREE(fl->fl_text);
  FREE(fl);
}
     
void
dbFlyLineDelete(CellDef *def,       /* Cell in which flyline is to be deleted */
	    char *name1,         /* hierarchical name of first label */
	    char *name2)         /* hierarchical name of second label */
{
    FlyLine *fl = def->cd_flyLines;
    FlyLine *prev = NULL;

    while(fl)
    {
      if(dbFlyLineMatchProc(fl,name1,name2))
      {
	if(prev)
	{
	  prev->fl_next = fl->fl_next;
	  dbFlyLineDelete1(def,fl);
	  fl=prev->fl_next;
	}
	else
	{
	  def->cd_flyLines = fl->fl_next;
  	  dbFlyLineDelete1(def,fl);
	  fl=def->cd_flyLines;
	}
      }
      else
      {
	prev=fl;
	fl=fl->fl_next;
      }
    }
}

/*
 * ----------------------------------------------------------------------------
 *
 * DBFlyLineNotifyLabelChange --
 *
 * Called to notify flyline module whenever a label is added or deleted.
 *
 * Adjusts flyline endpoints attached to labels (if any) and notifys
 * Layout module for redisplay.
 *
 * ----------------------------------------------------------------------------
 */
/* helper proc */
static int dbFlyLineNotifyLabelChange1(CellDef *def, ClientData cdarg)
{
  FlyLine *fl;
  CellDef *labDef = (CellDef *) cdarg;

  /* TODO use names and hashing to make flyline searching efficient */
  for(fl=def->cd_flyLines; fl; fl=fl->fl_next)
  {

      if( fl->fl_def1==NULL || fl->fl_def2==NULL || 
	 fl->fl_def1==labDef || fl->fl_def2==labDef)
      {
         dbFlyLineDraw(def,fl);
      }
  }

  /* continue enumeration of defs */
  return 0;
}

void DBFlyLineNotifyLabelChange(CellDef *def, char *labName)
{

  if(!DBFlyLinesExist) return; 

  if((def->cd_flags & CD_INTERNAL) && !(def->cd_flags & CD_GENERATED)) return;

  /* adjust relevant flylines in all defs */
  DBCellSrDefs(0,dbFlyLineNotifyLabelChange1, (ClientData) def);
}

/*
 * ----------------------------------------------------------------------------
 *
 * DBFlyLineInstanceChangeNotify --
 *
 * Called to notify flyline module whenever an instance is changed in a way
 * that could impact flylines.
 *
 * Adjusts flyline endpoints attached to labels (if any) and notifys
 * Layout module for redisplay.
 *
 * ----------------------------------------------------------------------------
 */
/* helper proc */
static int dbFlyLineNotifyInstanceChanged1(CellDef *def, ClientData cdarg)
{
  FlyLine *fl;
  CellDef *labDef = (CellDef *) cdarg;

  /* TODO use names and hashing to make flyline searching efficient */
  for(fl=def->cd_flyLines; fl; fl=fl->fl_next)
  {
      if( fl->fl_def1==NULL || fl->fl_def2==NULL ||
	 fl->fl_def1==labDef || fl->fl_def2==labDef)
      {
         dbFlyLineDraw(def,fl);
      }
  }

  /* continue enumeration of defs */
  return 0;
}

void DBFlyLineNotifyInstanceChanged(CellUse *use, CellDef *parentDef)
{
  if(!DBFlyLinesExist) return; 

  /* adjust relevant flylines in all defs */
  DBCellSrDefs(0,dbFlyLineNotifyInstanceChanged1, (ClientData) use->cu_def);
}

/* 
 * ==============================================================================
 *
 * FLYLINE I/O
 *
 * ==============================================================================
 */

#define OUTS(s,f)\
{\
     if (fputs(s,f) == EOF) goto ioerror;\
     DBFileOffset += strlen(s);\
}

/* write flyline */
/* note text and width currently not written out */
static bool dbFlyLineWrite(FlyLine *fl, FILE *f)
{
  Tcl_DString ds;

  Tcl_DStringInit(&ds);

  Tcl_DStringAppend(&ds,"fly",-1);
  Tcl_DStringAppendElement(&ds,fl->fl_name1);
  Tcl_DStringAppendElement(&ds,fl->fl_name2);
  Tcl_DStringAppend(&ds,"\n",-1);

  OUTS(Tcl_DStringValue(&ds),f);

  Tcl_DStringFree(&ds);
  return TRUE;

ioerror:
  Tcl_DStringFree(&ds);
  return FALSE;

}

/* write out flylines */
bool
dbFlyLinesWrite(CellDef *def, FILE *f)
{
  FlyLine *fl;

  for(fl=def->cd_flyLines; fl; fl=fl->fl_next)
  {
      if(!dbFlyLineWrite(fl,f)) return FALSE;
  }
  return TRUE;
}

/*
 * ----------------------------------------------------------------------------
 *
 * dbFlyLinesCopy --
 *
 * Copy flylines in src def to dest def.
 *
 * Results:
 *	Returns TRUE normally, or FALSE on error or EOF.
 *
 * Side effects:
 *	See above.
 *
 * ----------------------------------------------------------------------------
 */
void
dbFlyLinesCopy(CellDef *srcDef, CellDef *destDef)
{
  FlyLine *fl;

  for(fl=srcDef->cd_flyLines; fl; fl=fl->fl_next)
  {
    dbFlyLineAdd(destDef, fl->fl_name1, fl->fl_name2, fl->fl_width, fl->fl_text);
  }
}
  

/*
 * ----------------------------------------------------------------------------
 *
 * dbFlyLinesRead --
 *
 * Starting with the line "SECTION FLYLINES {", read the FLYLINES section.
 *
 * Results:
 *	Returns TRUE normally, or FALSE on error or EOF.
 *
 * Side effects:
 *	See above.
 *
 * ----------------------------------------------------------------------------
 */

/* helper func - reads one flyline */
static __inline__ bool
dbFlyLineRead(CellDef *cellDef, 
                     	/* Cell whose flylines are being read */
	     char *lineBuf, 
               		/* Line buffer */
	     int bufSize, 
            		/* Size of lineBuf */	     
	     FILE *f)
            		/* Input file */
{
  int argc;
  char **argv;
  static Tcl_Interp *privInterp = NULL;

  /* use private interpeter so we don't mess up result codes in real interp */
  if(!privInterp) privInterp = Tcl_CreateInterp();

  /* parse complete string into (newly malloced) elements */
  if(Tcl_SplitList(privInterp, lineBuf, &argc, &argv) != TCL_OK)
  {
    MsgErrorF("%s\n", privInterp->result);
    Tcl_ResetResult(privInterp);
    goto parseError;
  }

  if(argc!=3 || strcmp(argv[0],"fly") != 0)
  {
    MsgErrorF("Parse error on flyline: '%s'\n", lineBuf);
    goto parseError;
  }

  /* currently flyline width and text info not stored in .max file */
  dbFlyLineAdd(cellDef, argv[1], argv[2], 1, NULL);
  free(argv);  /* using free instead of FREE since argv malloce by tcl */
  return TRUE;

parseError:
    MsgErrorF("parse error in flyline:  '%s'\n", lineBuf);
    free(argv);  /* using free instead of FREE since argv malloce by tcl */
    return FALSE;
}

bool
dbFlyLinesRead(CellDef *cellDef, 
                     	/* Cell whose groups are being read */
	     char *lineBuf, 
               		/* Line buffer */
	     int bufSize, 
            		/* Size of lineBuf */	     
	     FILE *f)
            		/* Input file */
{
    while (dbReadNextLine(lineBuf, bufSize, f))
    {

        if (lineBuf[0]== '}' && 
	    strcmp(lineBuf,"} SECTION FLYLINES\n") == 0) return TRUE;
        if(!dbFlyLineRead(cellDef, lineBuf, bufSize, f)) return FALSE;
    }
    return (FALSE);
}





