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
 * DBread.c --
 *
 * Code to read cells in native (max) format.
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
static char rcsid[] = "$Header: DBio.c,v 6.0 90/08/28 18:09:53 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <ctype.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/file.h>
#include <sys/stat.h>
#include "magic.h"
#include "database.h"
#include "databaseInt.h"
#include "geometry.h"
#include "tile.h"
#include "utils.h"
#include "hash.h"
#include "database.h"
#include "databaseInt.h"
#include "message.h"
#include "drc.h"
#include "undo.h"
#include "memory.h"
#include "signals.h"
#include "main.h"
#include "layout.h"
#include "cif.h"

extern int errno;

/* Suffix for Max cell data files */
char *DBSuffix = ".max";

/* If set to FALSE, don't print warning messages. */
bool DBVerbose = FALSE;

/* if non-zero, default Res for Max files 
 * (overridden by __RESOLUTION__ property)
 * linked to tclvar DB_READ_LEGACY_RES
 */
double dbReadLegacyRes = 0;

/* tcl linked */
bool dbReadReportRoundingErrors = TRUE;

/* tcl linked, if positive, dbReadOpen() does not print load messages. */
int DBReadOpenQuiet = 0;

/* version of .max format of file being read
 * (given on "max <version>" line at beginning of .max files,
 *  except that in version "0", no version is specified.)
 *
 * version 0 - original                      (Max 1  12/03/96)
 * version 1 - new vstamps                   (Max 2   2/10/98)
 * version 2 - add resolution to header      (Max 3   8/13/99)
 * version 3 - save gcell layout             (Max 3.3 6/09/00)
 * version 4 - add bbox_user                 (Max 4.3 9/26/01)
 */  
int DBReadMaxFormat;

/* scale factor applied when reading .max file (usually 1.0) */
double dbRdScaleFile2DB = 1.0;

/* max rounding error since last reset */
double dbRdScaleFile2DBErr = 0;


/*
 * ----------------------------------------------------------------------------
 *
 * dbReadNextLine --
 *
 * Like fgets(), EXCEPT skip blank lines and lines beginning with '#'
 *
 * Results:
 *	Returns a pointer to 'line', or NULL on EOF.
 *
 * Side effects:
 *	Stores characters into 'line', terminating it with a
 *	NULL byte.
 *
 * ----------------------------------------------------------------------------
 */

char *
dbReadNextLine(char *line, int len, register FILE *f)
{
    register char *cs;
    register int l;
    register int c = '\0';  /* initialize to avoid warnings */

    do
    {
	cs = line, l = len;
	while (--l > 0 && (c = getc(f)) != EOF)
	{
	    *cs++ = c;
	    if (c == '\n')
		break;
	}
	*cs = '\0';

	if (c == EOF && cs == line) return (NULL);
    } while (line[0] == '#' || line[0]=='\n');

    return (line);
}

/*
 * ----------------------------------------------------------------------------
 *
 * dbReadOpen --
 *
 * called by dbReadCell1() to ...
 *
 * open the file containing the cell we are going to read.
 * If a filename for the cell is specified ('name' is non-NULL),
 * we try to open it somewhere in the search path.  Otherwise,
 * we try the filename already associated with the cell, or the
 * name of the cell itself as the name of the file containing
 * the definition of the cell.
 *
 * Results:
 *	Returns an open FILE * if successful, or NULL on error.
 *
 * Side effects:
 *	Opens a FILE.  Leaves cellDef->cd_flags marked as
 *	CD_AVAILABLE, with the CD_NOT_FOUND bit clear, if we
 *	were successful.
 *
 * ----------------------------------------------------------------------------
 */

static FILE *
dbReadOpen(CellDef *cellDef) 
                     	/* Def being read */
{
  FILE *f;
  char *filename;

  f = DBCellFileOpen(cellDef, NULL, DBSuffix, "r", &filename);
  if(f && !cellDef->cd_file) cellDef->cd_file = StrDup(NULL, filename);

  if (!f)
  {
    /* Don't print another message if we've already tried to read it */
    if (cellDef->cd_flags & CD_NOT_FOUND) return NULL;
    cellDef->cd_flags |= CD_NOT_FOUND;

    if(DBReadOpenQuiet<=0) 
    {
      if (cellDef->cd_file != (char *) NULL)
      {
	MsgErrorF("File %s couldn't be found\n", cellDef->cd_file);
      }
      else
      {
	MsgErrorF("Cell %s couldn't be found\n", cellDef->cd_name);
      }
    }
    return NULL;
  }

  if (access(filename, W_OK) < 0) 
  {
    cellDef->cd_flags |= CD_READ_ONLY;
  }

  cellDef->cd_flags &= ~CD_NOT_FOUND;
  cellDef->cd_flags |= CD_AVAILABLE;

  if(DBReadOpenQuiet<=0)
  {
    MsgInfoF("Loading cell %s from %s\n",
	     cellDef->cd_name,
	     filename);
  }

  return (f);
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBGetTech --
 *
 * 	Reads the first few lines of a file to find out what technology
 *	it is.
 *
 * Results:
 *	The return value is a pointer to a string containing the name
 *	of the technology of the file containing cell cellName.  NULL
 *	is returned if the file couldn't be read or isn't in Magic
 *	format.  The string is stored locally to this procedure and
 *	will be overwritten on the next call to this procedure.
 *
 * Side effects:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */

char *
DBGetTech(char *name)
                   			/* (file) name of  cell whose technology
					 * is desired.
					 */
{
    FILE *f;
    static char line[512];
    char *p;

    f = PaOpen(name, "r", DBSuffix, MnPathCell, (char **) NULL);
    if (f == NULL) return NULL;

    p = (char *) NULL;
    if (dbReadNextLine(line, sizeof line - 1, f) == NULL) goto ret;
    if (strncmp(line, "max",3) != 0) goto ret;
    if (dbReadNextLine(line, sizeof line - 1, f) == NULL) goto ret;
    if (strncmp(line, "tech ", 5) != 0) goto ret;
    for (p = &line[5]; (*p != '\n') && (*p != 0); p++)
	/* Find the newline */;
    *p = 0;
    for (p = &line[5]; isspace(*p); p++)
	/* Find the tech name */;

ret:
    (void) fclose(f);
    return (p);
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbReadLabels --
 *
 * Starting with the line "SECTION LABELS {", read LABELS section of 
 * max file.  
 *
 * Results:
 *	Returns TRUE normally, or FALSE on error or EOF.
 *
 * Side effects:
 *	See above.
 *
 * ----------------------------------------------------------------------------
 */

bool
dbReadLabels(CellDef *cellDef, 
                     	/* Cell whose labels are being read */
	     char *line, 
               		/* Line buffer */
	     int len, 
            		/* Size of line buffer */
	     FILE *f)
            		/* Input file */
{
    char layername[50], text[1024];
    TileType type;
    int orient;
    int kind;
    Rect r;

    while (dbReadNextLine(line, len, f))
    {
	if (line[0] == 'l')
	{
	    if (sscanf(line, "lab %1023s %d %d %d %d %d %d %99[^\n]",
		    layername, &r.r_xbot, &r.r_ybot, &r.r_xtop, &r.r_ytop,
			       &orient, &kind, text) != 8)
	    {
		MsgErrorF("Skipping bad \"label\" line: '%s'", line);
		continue;
	    }

	    /* scale rect to internal DB coords */
	    GeoScaleRect(&r, dbRdScaleFile2DB, &dbRdScaleFile2DBErr);

	    type = DBTechNameType(layername);
	    if (type < 0)
	    {
		MsgWarnF("Warning: label \"%s\" attached to unknown type"
			 "\"%s\"\n", text, layername);
		type = TT_SPACE;
	    }
	    (void) DBLabelAdd(cellDef, &r, orient, text, type, kind);
	}
	else if (line[0] == 't')
	{
	    /* new fangled sized label (not yet used) */
	    int sizeUnused;

	    if (sscanf(line, "t %1023s %d %d %d %d %d %d %d %99[^\n]",
		    layername, &r.r_xbot, &r.r_ybot, &r.r_xtop, &r.r_ytop,
			       &orient, &kind, &sizeUnused, text) != 9)
	    {
		MsgErrorF("Skipping bad \"label\" line: '%s'", line);
		continue;
	    }

	    /* scale rect to internal DB coords */
	    GeoScaleRect(&r, dbRdScaleFile2DB, &dbRdScaleFile2DBErr);

	    type = DBTechNameType(layername);
	    if (type < 0)
	    {
		MsgWarnF("Warning: label \"%s\" attached to unknown type"
			 "\"%s\"\n", text, layername);
		type = TT_SPACE;
	    }
	    (void) DBLabelAdd(cellDef, &r, orient, text, type, kind);
	}
	else if (strcmp(line,"} SECTION LABELS\n") == 0)
	{
	    return TRUE;
	}
	else
	{
 	    MsgWarnF("Ignoring bad line in LABELS section of %s: `%s'\n",
		     cellDef->cd_name, line);
        }
    }
    return (FALSE);
}

/* RECTS section replaced PAINT section in Max format 3 */
static bool
dbReadPaint(CellDef *cellDef, char *line, int lineSize, FILE *f) 
{
    PaintResultType *ptable = NULL;
    int rectCount = 0;
    int rectReport = 10000;
    TileType type = 0;
    Plane *plane = 0;

    while(dbReadNextLine(line, lineSize, f)) 
    {
      char c = line[0];

      /* rectangle */
      if(c=='r')
      {
	Rect r;
	int numRead;	
	char *groupName;
	char nameBuf[100];
	
	/* parse rect */
	numRead = sscanf(line,"rect %d %d %d %d %99[^\n]",
			 &r.r_xbot, &r.r_ybot, &r.r_xtop, &r.r_ytop,
			 nameBuf);
	if(numRead == 5)
	{
	  groupName = nameBuf;
	}
	else if(numRead == 4)
	{
	  groupName = NULL;
	}
	else
	{
	  MsgErrorF("Skipping bad \"rect\" line: '%s'", line);
	  continue;
	}

	/* keep stats */
	if ((++rectCount % rectReport == 0) && DBVerbose)
	{
	  MsgInfoF("%s: %d rects\n", cellDef->cd_name, rectCount);
	  fflush(stdout);
	}

        /* if rectangle null or on bad layer, skip it */
	if (GEO_RECTNULL(&r) || !plane) continue;

	/* scale rect to internal DB coords */
	GeoScaleRect(&r, dbRdScaleFile2DB, &dbRdScaleFile2DBErr);

	/* set group */
	cellDef->cd_activeGroup = 
	  groupName ? DBGroupFromName(cellDef, groupName) : NULL;

	/*
	 * We use DBPaintPlane, so inter-plane effects of painting
	 * tiles do not occur during read-in. 
	 *
	 * Warning:  May cause unexpected behavior when reading in "max" files
	 * not generated by max
	 */
	if(!ptable)
	{
          MsgErrorF("rectange before first layer specification '%s'\n", 
		    line);
	  return FALSE;
	}
	DBPaintPlane(plane, &r, ptable, (PaintUndoInfo *) NULL);

	/* reset group */
	cellDef->cd_activeGroup = NULL;

	continue;
      }

      /* blank line */
      if(c=='\n') continue;

      /* layer change */
      if(c=='t' && strncmp(line,"type",4)==0)
      {
        char layerName[50];

        if (sscanf(line, "type %49s", layerName) != 1)
        {
          MsgErrorF("Paint error:  bad type line: '%s'\n", line);
	  return FALSE;
        }

        type = DBTechNameType(layerName);
        if (type < 0)
        {
	   MsgErrorF("Unknown type %s\n",layerName);
	   return FALSE;
        }

        /* set plane and paint table for this type */
        if ((type > 0) && (DBPlane(type) > 0))
        {
	    ptable = DBStdPaintTbl(type, DBPlane(type));
	    plane = cellDef->cd_planes[DBPlane(type)];
         }
         else 
         {
	   plane = NULL;
         }
	 continue;
      }
	 
      /* section end */
      if(c=='}' && strcmp(line,"} SECTION PAINT\n")==0) return TRUE;

       /* bad line */
       MsgErrorF("Parse error in PAINT section of %s:  '%s'", 
		 cellDef->cd_name, line);
       return FALSE;
    }

    return TRUE;
}

/* RECTS section replaced PAINT section in Max format 3 */
static bool
dbReadRects(CellDef *cellDef, char *line, int lineSize, FILE *f) 
{
    PaintResultType *ptable = NULL;
    int rectCount = 0;
    int rectReport = 10000;
    TileType type = 0;
    Plane *plane = 0;

    while(dbReadNextLine(line, lineSize, f)) 
    {
      char c = line[0];

      /* rectangle */
      if((c>='0' && c<='9') || c=='-')
      {
	Rect r;
	int numRead;	
	char *groupName;
	char nameBuf[100];
	
	/* parse rect */
	numRead = sscanf(line,"%d %d %d %d %99[^\n]",
			 &r.r_xbot, &r.r_ybot, &r.r_xtop, &r.r_ytop,
			 nameBuf);
	if(numRead == 5)
	{
	  groupName = nameBuf;
	}
	else if(numRead == 4)
	{
	  groupName = NULL;
	}
	else
	{
	  MsgErrorF("Skipping bad line in rects section: '%s'", line);
	  continue;
	}

	/* keep stats */
	if ((++rectCount % rectReport == 0) && DBVerbose)
	{
	  MsgInfoF("%s: %d rects\n", cellDef->cd_name, rectCount);
	  fflush(stdout);
	}

        /* if rectangle null or on bad layer, skip it */
	if (GEO_RECTNULL(&r) || !plane) continue;

	/* scale rect to internal DB coords */
	GeoScaleRect(&r, dbRdScaleFile2DB, &dbRdScaleFile2DBErr);

	/* set group */
	cellDef->cd_activeGroup = 
	  groupName ? DBGroupFromName(cellDef, groupName) : NULL;

	/*
	 * We use DBPaintPlane, so inter-plane effects of painting
	 * tiles do not occur during read-in. 
	 *
	 * Warning:  May cause unexpected behavior when reading in "max" files
	 * not generated by max
	 */
	if(!ptable)
	{
          MsgErrorF("RECTS error:  rectange before first layer specification '%s'\n", line);
	  return FALSE;
	}
	DBPaintPlane(plane, &r, ptable, (PaintUndoInfo *) NULL);

	/* reset group */
	cellDef->cd_activeGroup = NULL;

	continue;
      }

      /* blank line */
      if(c=='\n') continue;

      /* layer change */
      if(c=='l' && strncmp(line,"layer",5)==0)
      {
        char layerName[50];

        if (sscanf(line, "layer %49s", layerName) != 1)
        {
          MsgErrorF("RECTS error:  bad layer line: '%s'\n", line);
	  return FALSE;
        }

        type = DBTechNameType(layerName);
        if (type < 0)
        {
	   MsgErrorF("Unknown layer %s\n",layerName);
	   return FALSE;
        }

        /* set plane and paint table for this type */
        if ((type > 0) && (DBPlane(type) > 0))
        {
	    ptable = DBStdPaintTbl(type, DBPlane(type));
	    plane = cellDef->cd_planes[DBPlane(type)];
         }
         else 
         {
	   plane = NULL;
         }
	 continue;
      }
	 
      /* section end */
      if(c=='}' && strcmp(line,"} SECTION RECTS\n")==0) return TRUE;

       /* bad line */
       MsgErrorF("Parse error in RECTS section of %s:  '%s'\n", 
		 cellDef->cd_name, line);
       return FALSE;
    }

    return TRUE;
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbReadVersions --
 *
 * Starting with the line "SECTION VERSIONS {", read VERSIONS section of 
 * max file.  
 *
 * Results:
 *	Returns TRUE normally, or FALSE on error or EOF.
 *
 * Side effects:
 *	See above.
 *
 * ----------------------------------------------------------------------------
 */

static bool
dbReadVersions(CellDef *cellDef, 
                     	/* Cell whose labels are being read */
	     char *line, 
               		/* Line buffer */
	     int len, 
            		/* Size of line buffer */
	     FILE *f)
            		/* Input file */
{
  VStamp notUsed;
  /* DEF version stamp */
  if (dbReadNextLine(line, len, f) == NULL) return FALSE;
  if (sscanf(line, "vMAIN %d %d", 
		 &cellDef->cd_vMAIN.vs_time, 
		 &cellDef->cd_vMAIN.vs_rev) != 2)
  {
    MsgErrorF("Bad vMAIN line: %s", line);
  }
  
  /* initialize internal version to external */
  cellDef->cd_version = cellDef->cd_vMAIN;

  /* DRC version stamp */
  if (dbReadNextLine(line, len, f) == NULL) return FALSE;
  if (sscanf(line, "vDRC %d %d", 
	     &cellDef->cd_vDRC.vs_time, 
	     &cellDef->cd_vDRC.vs_rev) != 2)
  {
    MsgErrorF("Bad vDRC line: %s", line);
  }

  /* BBOX version stamp */
  if (dbReadNextLine(line, len, f) == NULL) return FALSE;
  if (sscanf(line, "vBBOX %d %d", 
	     &notUsed.vs_time, 
	     &notUsed.vs_rev) != 2)
  {
    MsgErrorF("Bad vBBOX line: %s", line);
  }

  /* end of section */ 
  if (dbReadNextLine(line, len, f) == NULL) return FALSE;
  if (strcmp(line,"} SECTION VERSIONS\n") != 0)
  {
    MsgWarnF("Bad line in VERSIONS section of %s: `%s'\n",
	     cellDef->cd_name, line);
    return FALSE;
  }

  return TRUE;
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbReadSections --
 *
 * called by dbReadCell1 for each DEF in file, to read data SECTIONS
 * (i.e. first for each dependent def, then for main def.)
 *
 * Reads in def contents - and does necessary notifications.  
 *
 * Return TRUE iff def successfully read.
 *
 * ----------------------------------------------------------------------------
 */

/* change notification for DBReadCellSections() */
static void dbReadChangeNotify(CellDef *cellDef)
{

  /* expand instances of generated and process version mismatchs */
  {
    bool processMismatches = (DBReadMaxFormat>=3);
    DBGCellProcessInstances(cellDef, processMismatches);
  }

  /* mark need to compute bbox */
  cellDef->cd_flags |= CD_CHANGED_BBOX;      

  /* mark cell available (read in) */
  cellDef->cd_flags |= CD_AVAILABLE;      

  if(cellDef->cd_refCnt)
  {
    DBChangedArea(cellDef, NULL, NULL, DBCF_DEFREAD|DBCF_INSTANCE_ONLY);
  }
  else
  {
    DBChangedArea(cellDef, NULL, NULL, DBCF_DEFREAD);
  }
}

static bool
dbReadSections(CellDef *cellDef,  /* read contents into this def */
	      char *line,        /* buffer for current line */
	      int lineSize, 
	      FILE *f)           /* file being read */
{
    bool notified = FALSE;

    /* read in sections */
    while (dbReadNextLine(line, lineSize-1, f))
    {
      char section[25];
      char junk[5];
      char *p = line;

      /* skip blank lines */
      if(line[0]=='\n') continue;

      if(line[0]!='S') break;

      /* parse section heading */
      if( sscanf(line,"SECTION %20s { %1s", section, junk) != 1 )
      {
	MsgErrorF("Bad section heading: %s\n", line); 
	return FALSE;
      }

      /* parse section heading */
      if(notified)
      {
	MsgErrorF("Bad section ordering (FLYLINES must be last)\n");
	return FALSE;
      }

      if(strcmp(section,"VERSIONS") == 0)
      {
	if(!dbReadVersions(cellDef, line, lineSize, f)) 
	{
	  goto skipToEndOfSection;
	}
      }
      else if(strcmp(section,"PROPERTIES") == 0)
      {
	if(!dbPropertiesRead(cellDef, line, lineSize, f)) 
	{
	  goto skipToEndOfSection;
	}
      }
      else if(strcmp(section,"PAINT") == 0)  /* format 2 and older */
      {
	if(!dbReadPaint(cellDef, line, lineSize, f)) 
	{
	  goto skipToEndOfSection;
	}
      }
      else if(strcmp(section,"RECTS") == 0)
      {
	if(!dbReadRects(cellDef, line, lineSize, f)) 
	{
	  goto skipToEndOfSection;
	}
      }
      else if(strcmp(section,"POLYGONS") == 0)
      {
	if(!dbPolyRead(cellDef, line, lineSize, f)) 
	{
	  goto skipToEndOfSection;
	}
      }
      else if(strcmp(section,"WIREPATHS") == 0)
      {
	if(!dbWPathRead(cellDef, line, lineSize, f)) 
	{
	  goto skipToEndOfSection;
	}
      }
      else if(strcmp(section,"LABELS") == 0)
      {
	if(!dbReadLabels(cellDef, line, lineSize, f)) 
	{
	  goto skipToEndOfSection;
	}
      }
      else if(strcmp(section,"GROUPS") == 0)
      {
	if(!dbGroupsRead(cellDef, line, lineSize, f)) 
	{
	  goto skipToEndOfSection;
	}
      }
      else if(strcmp(section,"FLYLINES") == 0)
      {
	if(dbFlylinesSave)
	{
	  /* need to propagate bounding boxes before adding flylines */
	  dbReadChangeNotify(cellDef);
	  notified = TRUE;

	  if(!dbFlyLinesRead(cellDef, line, lineSize, f)) 
	  {
	    goto skipToEndOfSection;
	  }
	}
	else
	{
	  goto skipToEndOfSection;
	}
      }
      else if(strcmp(section,"INSTANCES") == 0)
      {
	if(!dbInstancesRead(cellDef, line, lineSize, f)) 
	{
	  goto skipToEndOfSection;
	}
      }
      else
      {
	MsgWarnF("Skipping unrecognized section: %s, while reading cell %s\n", 
		  section, cellDef->cd_name); 
	goto skipToEndOfSection;
      }

      continue;

skipToEndOfSection:
      {
	int len = strlen(section);
        while(line[0]!='}' || 
	    strncmp(&line[1]," SECTION ",9)!=0 || 
	    strncmp(&line[10],section,len)!=0 ||
	    line[10+len]!='\n')
        {
	  if(!dbReadNextLine(line, lineSize -1, f))
	  {
   	     MsgErrorF("Premature EOF.\n"); 
	     return FALSE;
	  }
        }
      }
    }
       
    /* set hash based version stamp for gcells */
    if(cellDef->cd_flags & CD_GENERATED)
    { 
      VStamp stamp = DBVStampHash(cellDef);
      cellDef->cd_version = stamp;
      cellDef->cd_vMAIN = stamp;
      cellDef->cd_vDRC = stamp;
    }

    /* clear modified flag */  
    cellDef->cd_flags &= ~CD_MODIFIED;

    /* propagate database changes 
     *(normally done before processing FLYLINE section)
     */
    if(!notified) dbReadChangeNotify(cellDef);


    if(cellDef->cd_refCnt)
    {
      DBChangedArea(cellDef, NULL, NULL, DBCF_DEFREAD|DBCF_INSTANCE_ONLY);
    }
    else
    {
      DBChangedArea(cellDef, NULL, NULL, DBCF_DEFREAD);
    }

    return TRUE;
}

/*
 * ----------------------------------------------------------------------------
 *
 * dbReadCell1 --
 *
 * Called by inlined DBReadCell() to do the "real" work.  
 *
 * If the cell is generated (a gcell) call tcl proc "gcell_load name"   
 * to generate it.
 * 
 * Otherwise, call tcl procedure cell_load_hook, and then read in 
 * the cell from its associated disk file (cd_file).
 *
 * If cd_file NULL, searches the cell path (MN_PATH_CELL)
 * for a <cell>.max  (<cell> = cd_name).
 *
 * Marks the cell definition as "read in" (CD_AVAILABLE), and
 * call DBChangedArea() to process database changes.
 *
 * Results:
 *	TRUE if the cell could be read successfully, FALSE
 *	otherwise.  (If the cell is already read in, TRUE is
 *	also returned.)
 *
 * Side effects:
 *	Cell contents set to match file.
 *      cd_file is set to the full name of the file read.
 *	The cell definition is marked as available.
 *	The cell's MODIFIED bit is cleared.
 *      DBChangedArea() is called to process database changes.
 *
 *	In the event of an error while reading in the cell,
 *	the external integer errno is set to the UNIX error
 *	encountered.
 *
 * ----------------------------------------------------------------------------
 */

bool
dbReadCell1(CellDef *cellDef) 
                     	/* Pointer to definition of main cell to be read in */
{
    char line[2048]; 
    char propBuf[BUFSIZ];
    bool result = TRUE;
    register FILE *f;

    /* cell already in memory, so just return */
    if (cellDef->cd_flags & CD_AVAILABLE)
    {
      return (TRUE);
    }

    /* generated cell */
    if (cellDef->cd_flags & CD_GENERATED)
    {
      char script[BUFSIZ];
      bool loadResult;

      SigDisableInterrupts();
      UndoDisable();

      /* important to mark cell available before gcell_load
       * so that flyline updates work right for labels in gcell.
       */
      cellDef->cd_flags |= CD_AVAILABLE;

      sprintf(script,"gcell_load {%s}", cellDef->cd_name);
      loadResult = MnTclEvalBg(script,
			       "gcell_load call from DBReadCell");

      UndoEnable();
      SigEnableInterrupts();

      return loadResult; /* TRUE on normal completion */  
    }

    /* first call cell_load_hook 
     * (to inform version control)
     */
    {
      Tcl_DString cmd;
      bool loadResult; 

      SigDisableInterrupts();
      UndoDisable();

      Tcl_DStringInit(&cmd);

      Tcl_DStringAppendElement(&cmd,"cell_load_hook");
      Tcl_DStringAppendElement(&cmd,cellDef->cd_name);

      loadResult = MnTclEvalBg(Tcl_DStringValue(&cmd),
			       "cell_load_hook call from DBReadCell");

      Tcl_DStringFree(&cmd);

      UndoEnable();
      SigEnableInterrupts();

      if (!loadResult) return FALSE; 
    }

    /* open file */
    if ((f = dbReadOpen(cellDef)) == NULL)
    {
      return (FALSE);
    }

    /*
     * It's very important to disable interrupts during the body of
     * this routine.  Otherwise, if the user types the interrupt key
     * only part of the file will be read in, and if he then writes
     * the cell out, the disk copy will get trashed.
     */
    SigDisableInterrupts();

    /* disable undo during cell loading */
    UndoDisable();

    /* max format line */
    if (dbReadNextLine(line, sizeof line -1 , f) == NULL) goto badfile;
    if (strncmp(line, "max", 3) != 0)
    {
      MsgErrorF("Input file not in max format!\n");
      goto badfile;
    }

    /* NOTE: format version 0 has no integer on "max" line */
    DBReadMaxFormat = 0;
    sscanf(line, "max %d", &DBReadMaxFormat);
    if(DBReadMaxFormat<0 || DBReadMaxFormat>4)
    {
      MsgErrorF("Unsupported Max Format Version '%d', "
		"(format versions 0 through 4 are read by this Max)\n",
		DBReadMaxFormat); 
	goto badfile;
    } 

    /* tech line */
    {
      char tech[50];

      if (dbReadNextLine(line, sizeof line -1 , f) == NULL)
	goto badfile;

      if (sscanf(line, "tech %49s", tech) != 1)
      {
	MsgErrorF("Malformed \"tech\" line: %s", line);
	goto badfile;
      }
      if (strcmp(DBTechName, tech) != 0)
      {
	MsgErrorF("Cell %s has wrong technology %s\n", cellDef->cd_name,
		  tech);
	goto badfile;
      }
    }

    /* resolution line (setup scaling) */
    dbRdScaleFile2DBErr = 0;
    if (DBReadMaxFormat < 2)
    {
      dbRdScaleFile2DB = dbReadLegacyRes ? dbReadLegacyRes/CIFDBRes : 1.0;
    }
    else
    {
      double fileRes;

      if (dbReadNextLine(line, sizeof line -1 , f) == NULL)
	goto badfile;

      if (sscanf(line, "resolution %lf", &fileRes) != 1)
      {
	MsgErrorF("Malformed \"resolution\" line: %s", line);
	goto badfile;
      }

      dbRdScaleFile2DB = fileRes/CIFDBRes;
    }
      
    /* version stamps for Max format < 3) */
    if (DBReadMaxFormat == 0)
    {
      int cellStamp;

      /* time stamp */
      if (dbReadNextLine(line, sizeof line -1, f) == NULL)
	goto badfile;

      if (sscanf(line, "timestamp %d", &cellStamp) != 1)
	MsgErrorF("Expected timestamp but got: %s", line);

      cellDef->cd_version.vs_time = cellStamp;
      cellDef->cd_version.vs_rev = 0;
    }
    else if (DBReadMaxFormat <= 2)
    {
      VStamp notUsed;

      /* DEF version stamp */
      if (dbReadNextLine(line, sizeof line -1, f) == NULL)
	goto badfile;
      if (sscanf(line, "vMAIN %d %d", 
		 &cellDef->cd_vMAIN.vs_time, 
		 &cellDef->cd_vMAIN.vs_rev) != 2)
	MsgErrorF("Bad vMAIN line: %s", line);
      
      /* initialize internal version to external */
      cellDef->cd_version = cellDef->cd_vMAIN;

      /* DRC version stamp */
      if (dbReadNextLine(line, sizeof line -1, f) == NULL)
	goto badfile;
      if (sscanf(line, "vDRC %d %d", 
		 &cellDef->cd_vDRC.vs_time,
		 &cellDef->cd_vDRC.vs_rev) != 2)
	MsgErrorF("Bad vDRC line: %s", line);

      /* BBOX version stamp */
      if (dbReadNextLine(line, sizeof line -1, f) == NULL)
	goto badfile;
      if (sscanf(line, "vBBOX %d %d", 
		 &notUsed.vs_time,
		 &notUsed.vs_rev) != 2)
	MsgErrorF("Bad vBBOX line: %s", line);
    }
    else
    {
      /* beginning with format versions 3, versions
       * are in VERSIONS section of main DEF
       */
    }

    /* read file def by def */
    if(DBReadMaxFormat<3)
    {
      /* no DEF lines, just (unintroduced main def) */
      if(!dbReadSections(cellDef, 
			 line, 
			 sizeof line -1,
			 f)) goto badfile;
    }
    else
    {
      /* skip to first DEF line */
      while(dbReadNextLine(line, sizeof line -1, f)!=NULL && line[0]=='\n'); 
      
      while(line[0]!='\0')
      {
	char *name;

	if(strncmp(line,"DEF",3)!=0)
        {
	  MsgErrorF("Bad def heading: %s\n", line); 
	  goto badfile;
	}

	/* get name */
	name = strtok(line+3," \t\n");

	if(!name) 
        {
	  /* no name on DEF line, so main def */
	  /* (returns with line empty (at EOF) or 
	   *  containing next DEF header) 
	   */
	  if(!dbReadSections(cellDef, 
			     line, 
			     sizeof line -1,
			     f)) goto badfile;

	}
	else
        {
	  CellDef *depDef;

	  /* setup def for dependent cell */
	  depDef = DBCellLookDef(name);
	  if(!depDef) depDef = DBCellNewDef(name, (char *) NULL);
	  if(!depDef)
	  {
	    MsgErrorF("Bad name on DEF: %s\n", name); 
	    goto badfile;
	  }

	  DBCellClearContents(depDef);
	  depDef->cd_flags |= CD_AVAILABLE;
	  depDef->cd_flags |= CD_DRC_WITH_PARENT;
	  depDef->cd_flags |= CD_GENERATED;
	  /*	  depDef->cd_flags |= CD_NO_UNDO; */

	  /* set showName and showInst from DEF line */
	  {
	    char buf[BUFSIZ];
	    char *p = name;

	    /* showName follows name */
	    while(*p!='\0') p++;
	    p++;

	    p = StrQuoteParse(p, buf);
	    if(!p) 
	    {
	      MsgErrorF("Bad showName on DEF line\n");
	      goto badfile;
	    }
	    StrDup(&depDef->cd_showName,buf);

	    p = StrQuoteParse(p, buf);
	    if(!p) 
	    {
	      MsgErrorF("Bad showInst on DEF line\n");
	      goto badfile;
	    }
	    StrDup(&depDef->cd_showInst,buf);
	  }

	  /* read dependent def contents */
	  if(!dbReadSections(depDef, 
			     line, 
			     sizeof line -1,
			     f)) goto badfile;

	}
      }
    }

done:
    (void) fclose(f);

    /* report rounding errors */
    if(dbReadReportRoundingErrors)
    {
      if(dbRdScaleFile2DBErr > UNIT_TOLERANCE) 
      {
	double err = dbRdScaleFile2DBErr;
	err *= CIFDBRes;

	MsgWarnF("Rounding errors reading %s  "
		 "(maximum error = %g microns)\n",
		 cellDef->cd_name,
		 err);
      }
    }

    UndoEnable();
    SigEnableInterrupts();
    return (result);

badfile:
    MsgErrorF("File %s contained format error\n", cellDef->cd_name);
    result = FALSE;
    goto done;
}



/*
 * ----------------------------------------------------------------------------
 *
 * DBReadCellTree --
 *
 * Read in entire cell tree rooted at def.  
 * Does not read in cells already in memory.
 *
 * ----------------------------------------------------------------------------
 */

void
DBReadCellTree(CellDef *def) 
{
  CellKid *kid;

  /* make sure def is in memory */
  if ((def->cd_flags & CD_AVAILABLE) == 0)
  {
    DBReadCell(def);
  }

  /* now recursively read-in descendents */
  for (kid=def->cd_kids; kid; kid=kid->ck_next) DBReadCellTree(kid->ck_def);
}


