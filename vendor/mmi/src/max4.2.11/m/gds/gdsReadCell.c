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
 * gdsReadCell.c --
 *
 * Input of Calma GDS-II stream format.
 * Processing for cells.
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
static char rcsid[] = "$Header: CalmaRdcl.c,v 6.0 90/08/28 18:03:39 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include <sys/types.h>

#include "magic.h"
#include "geometry.h"
#include "geometry.h"
#include "tile.h"
#include "utils.h"
#include "hash.h"
#include "database.h"
#include "databaseInt.h"
#include "malloc.h"
#include "main.h"
#include "cif.h"
#include "cifInt.h"
#include "cifRead.h"
#include "signals.h"
#include "layout.h"
#include "layout.h"
#include "styles.h"
#include "message.h"
#include "debug.h"
#include "gdsInt.h"

/* used to count number of data elements converted to manhattan by introducing
 * stair steps.
 */  
int calmaStairSteps;
int gdsReadNumPolygons;
int gdsReadDebugPolygonsThresh;
int gdsReadDebugStairStepThresh;
bool gdsReadDebugUndefinedRefs;

extern void CIFPaintCurrent();


/*
 * ----------------------------------------------------------------------------
 *
 * gdsReadFindCell --
 *
 * This local procedure "materializes" a cell that is to be read in, or
 * a cell that is referenced.  The cell is looked for 
 * in the following places (in order):
 *
 *   1) looks for the cell in the table of cells we have already referenced
 *   2) look in database 
 *   3) try to read from .max file in cell path (optional)
 *   3) create a new one.
 *
 *  The cell is added to the CifCellTable hash table.
 *
 *  If a new subcell is created, its CDAVAILABLE is left FALSE.
 *
 * Results:
 *	The return value is a pointer to the definition for the
 *	cell whose name is 'name'.
 *
 * Side effects:
 *	A new CellDef may be created, def is added to CifCellTable.
 *
 * ----------------------------------------------------------------------------
 */

static CellDef *
gdsReadFindCell(char *name, 
		                   /* Name of desired cell */
		bool readFromDisk) 
                                   /* if TRUE, and cell not in memory,
				    * try reading in from disk.
				    */
{
    HashEntry *h;
    CellDef *def;

    h = HashFind(&CifCellTable, name);

    /* if def not in CifCellTable - add one */
    if (HashGetValue(h) == 0)
    {

        /* DEBUG */
        if(gdsReadDebug && readFromDisk && !gdsReadDebugUndefinedRefs)
	{
	  fprintf(stderr,
		  "DEBUG, gds reading:  def referenced before defined\n");
	  gdsReadDebugUndefinedRefs = TRUE;
	}
	
        /* try database */
	def = DBCellLookDef(name);

        /* if still not found, create a new def (and try reading from disk) */
	if (def == NULL)
	{
	    def = DBCellNewDef(name, (char *) NULL);

	    /* try reading in cell from disk */
	    if(readFromDisk) 
	    {
	      /* kludge to avoid warning/error on cell not found */
	      def->cd_flags |= CDNOTFOUND;
	      DBCellRead(def, NULL, TRUE); 
	      def->cd_flags &= ~CDNOTFOUND;
	    }
	}

	/* set hash entry in CifCellTable */ 
	HashSetValue(h, def);
    }

   return (CellDef *) HashGetValue(h);
}


/*
 * ----------------------------------------------------------------------------
 *
 * gdsGetINameFromProp --
 *
 * scan tail of SREF for iName property.
 *
 * Sets buf to iname and returns &buf or NULL (if no iname found)
 *
 *
 * ----------------------------------------------------------------------------
 */
char *gdsGetINameFromProp(char *buf, int size)
{
  int nbytes, rtype;

  while(TRUE) 			     
  {
    READRH(nbytes, rtype);
    
    if(rtype == CALMA_PROPATTR)
    {
      int propNum;

      READI2(propNum);
      if(propNum != cifCurReadStyle->crs_iNamePropNum) continue;
      if (!calmaReadStringRecord(CALMA_PROPVALUE, 
				 buf,
				 size-2)) return NULL;
      return buf;
    }

    if(rtype == CALMA_ENDEL)
    {
      UNREADRH(nbytes, rtype);
      return NULL;
    }

    nbytes -= CALMAHEADERLENGTH;
    if (nbytes) calmaSkipBytes(nbytes);
  }
}


/*
 * ----------------------------------------------------------------------------
 *
 * calmaElementSref --
 *
 * Process a structure reference (instance) (either CALMA_SREF or CALMA_AREF).
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Consumes input.
 *	Adds a new cell use to the current def.
 *
 * ----------------------------------------------------------------------------
 */

static void
calmaElementSref(void)
{
    int nbytes, rtype, cols, rows, nref, n;
    int xlo = 0;
    int ylo = 0;
    int xhi = 0;
    int yhi = 0;
    int xsep = 0;
    int ysep = 0;
    char *sname;
    char nameBuf[BUFSIZ];
    bool isArray = FALSE;
    Transform trans, tinv;
    Point refarray[3], p;
    CellUse *use;
    CellDef *def;
    char buf[BUFSIZ];
    char *propIName = NULL;

    /* Skip CALMA_ELFLAGS, CALMA_PLEX */
    calmaSkipSet(calmaElementIgnore);

    /* Read subcell name */
    if (!calmaReadStringRecord(CALMA_SNAME, 
			       nameBuf,
			       CALMANAMELENGTH)) return;
    sname = nameBuf;

    /* Gcell? */
    if (*sname == '#')
    {
      char *mapName;

      mapName = StrMapLookup(gdsReadCellNameMap,sname);
      if(mapName) sname = mapName; 
    }
    else
    {
      if(gdsReadCellnameToLower) StrToLower(sname);
      if(gdsReadCellnameToUpper) StrToUpper(sname);
    }

    /* Read subcell transform */
    if (!calmaReadTransform(&trans, sname))
    {
	gdsReadMsgWarn("Couldn't read transform, skipping instance %s", sname);
	return;
    }

    /* Get number of columns and rows if array */
    cols = rows = 0;  /* For half-smart compilers that complain otherwise. */
    READRH(nbytes, rtype);
    if (nbytes < 0) return;
    if (rtype == CALMA_COLROW)
    {
	isArray = TRUE;
	READI2(cols);
	READI2(rows);
	xlo = 0; xhi = cols - 1;
	ylo = 0; yhi = rows - 1;
	if (gdsRdEOF) return;
	(void) calmaSkipBytes(nbytes - CALMAHEADERLENGTH - 4);
    }
    else
    {
	UNREADRH(nbytes, rtype);
    }

    /*
     * Read reference points.
     * For subcells, there will be a single reference point.
     * For arrays, there will be three; for their meanings, see below.
     * 
     * points scaled to Max DB values.
     */
    READRH(nbytes, rtype);
    if (nbytes < 0) return;
    if (rtype != CALMA_XY)
    {
	gdsReadMsgUnexpectedRecord(CALMA_XY, rtype);
	return;
    }

    /* Length of remainder of record */
    nbytes -= CALMAHEADERLENGTH;

    nref = nbytes / 8;
    if (nref > 3)
    {
	gdsReadMsgWarn("Too many points (%d) in SREF/AREF", nref);
	nref = 3;
    }
    else if (nref < 1)
    {
	gdsReadMsgWarn("Missing reference points in SREF/AREF (using 0,0)\n");
	refarray[0].p_x = refarray[0].p_y = 0;
	refarray[1].p_x = refarray[1].p_y = 0;
	refarray[2].p_x = refarray[2].p_y = 0;
    }

    /*
     * Scale to Max DB units 
     * Make sure we only read three points.
     */
    for (n = 0; n < nref; n++)
    {
	READPOINT(&refarray[n]);  /* READPOINT scales to CIFPlane */
	nbytes -= 8;
	GeoScalePoint(&refarray[n], 
		      cifRdScaleCIFPlane2DB, 
		      &cifRdScaleCIFPlane2DBErr); /* scale to DB */
	if (gdsRdEOF)
	    return;
    }

    /* Skip rest of record */
    if (nbytes)	calmaSkipBytes(nbytes);

    /*
     * Figure out the inter-element spacing of array elements,
     * and also the translation part of the transform.
     * The first reference point for both SREFs and AREFs is the
     * translation of the use's or array's lower-left.
     */
    trans.t_c = refarray[0].p_x;
    trans.t_f = refarray[0].p_y;
    GeoInvertTrans(&trans, &tinv);
    if (isArray)
    {
	/*
	 * The remaining two points for an array are displaced from
	 * the first reference point by:
	 *    - the inter-column spacing times the number of columns,
	 *    - the inter-row spacing times the number of rows.
	 */
	xsep = ysep = 0;
	if (cols)
	{
	    GeoTransPoint(&tinv, &refarray[1], &p);
	    if (p.p_x % cols)
	    {
		n = (p.p_x + (cols+1)/2) / cols;
		gdsReadMsgWarn("# cols in array doesn't divide displacement ref pt\n\t"
			       "%d / %d -> %d", 
			       p.p_x, cols, n); 
		xsep = n;
	    }
	    else xsep = p.p_x / cols;
	}
	if (rows)
	{
	    GeoTransPoint(&tinv, &refarray[2], &p);
	    if (p.p_y % rows)
	    {
		n = (p.p_y + (rows+1)/2) / rows;
		gdsReadMsgWarn("# rows in array doesn't divide displacement ref pt\n\t"
			       "%d / %d -> %d", 
			       p.p_y, rows, n);
		ysep = n;
	    }
	    ysep = p.p_y / rows;
	}
    }

    /* if instance names specified as property,
     * scan rest of SREF element for that property. 
     */
    if(cifCurReadStyle->crs_iNamePropNum>=0)
    {
      propIName = gdsGetINameFromProp(buf, BUFSIZ);
    }

    /*
     * Create a new cell use with this transform.  If the
     * cell being referenced doesn't exist, create it.
     */
    /* TODO instead of reading from .max file, 
     * utilize bbox info in gds file! */
    def = gdsReadFindCell(sname, TRUE);
    if(gdsReadNoDRC && !(def->cd_flags & CDAVAILABLE))
    {
      def->cd_vDRC = DBVStampFixed;
    }
    use = DBCellNewUse(def, propIName?propIName:gdsInstanceName);
    if(gdsInstanceName)
    {
      FREE(gdsInstanceName);
      gdsInstanceName = NULL;
    }
    if (isArray)
    {
      DBMakeArray(use, &GeoIdentityTransform, xlo, ylo, xhi, yhi, xsep, ysep);
    }

    /* if no drc, make drc timestamp consistent */
    if(gdsReadNoDRC)
    {
      use->cu_vDRC = def->cd_vDRC;
    }
	
    DBCellUseSetTrans(use, &trans);
    if(gdsReadReportDuplicateInstances)
    {
      DBInstanceAdd(use, 
		    cifReadCellDef,
		    DBIA_INFOMSG_ON_RENAME | DBIA_INFOMSG_ON_DUP);
    }
    else
    {
      DBInstanceAdd(use, 
		    cifReadCellDef,
		    DBIA_INFOMSG_ON_RENAME);
    }
}


/*
 * ----------------------------------------------------------------------------
 *
 * calmaParseElement --
 *
 * Process one element from a GDS-II structure, including its
 * trailing CALMA_ENDEL record.  In the event of a syntax error, we skip
 * ahead to the closing CALMA_ENDEL, output a warning, and keep going.
 *
 * Results:
 *	TRUE if we processed an element, FALSE when we reach something that
 *	is not an element.  In the latter case, we leave the non-element
 *	record unconsumed.
 *
 * Side effects:
 *	Consumes input.
 *	Depends on the kind of element encountered.
 *	If we process a SREF or AREF, increment *pnsrefs.
 *
 * ----------------------------------------------------------------------------
 */

static bool
calmaParseElement(int *pnsrefs)
{
    static int node[] = { CALMA_ELFLAGS, CALMA_PLEX, CALMA_LAYER,
			  CALMA_NODETYPE, CALMA_XY, -1 };

    int nbytes, rtype;

    READRH(nbytes, rtype);
    if (nbytes < 0)
    {
	gdsReadMsgWarn("Unexpected EOF.\n");
	return (FALSE);
    }

    switch (rtype)
    {
	case CALMA_AREF:
	case CALMA_SREF:
	    calmaElementSref();
	    (*pnsrefs)++;
	    break;
	case CALMA_BOUNDARY:	
	    calmaElementBoundary();
	    break;
	case CALMA_BOX:
	    calmaElementBox();
	    break;
	case CALMA_PATH:	
	    calmaElementPath();
	    break;
	case CALMA_TEXT:	
	    calmaElementText();
	    break;
	case CALMA_NODE:
	    gdsReadMsgWarn("NODE elements not supported: skipping.\n");
	    calmaSkipSet(node);
	    break;
	default:
	    UNREADRH(nbytes, rtype);
	    return (FALSE);
    }

    return calmaSkipTo(CALMA_ENDEL);
}


/*
 * ----------------------------------------------------------------------------
 *
 * calmaParseStructure --
 *
 * Process a complete GDS-II structure (cell) including its closing
 * CALMA_ENDSTR record.  In the event of a syntax error, we skip
 * ahead to the closing CALMA_ENDSTR, output a warning, and keep going.
 *
 * Results:
 *	TRUE if successful, FALSE if the next item in the input is
 *	not a structure.
 *
 * Side effects:
 *	Reads a new cell.
 *	Consumes input.
 *
 * ----------------------------------------------------------------------------
 */

/* feedback control (linked to tcl variables) */
int gdsReadMessageInterval = 100000;

bool
calmaParseStructure(bool cellNames, char *dir) 
     /* if set, ignore cells not in gdsReadCellNameHash */
{
    static int structs[] = { CALMA_STRCLASS, CALMA_STRTYPE, -1 };
    int nbytes, rtype;
    char strname[CALMANAMELENGTH + 2]; 
    HashEntry *he;
    int suffix;
    bool generated = FALSE;
    bool result = TRUE;

    /* Make sure this is a structure; if not, let the caller know we're done */
    PEEKRH(nbytes, rtype);
    if (nbytes <= 0 || rtype != CALMA_BGNSTR)
	return (FALSE);

    /* Read the structure name */
    if (!calmaSkipExact(CALMA_BGNSTR)) goto syntaxerror;
    if (!calmaReadStringRecord(CALMA_STRNAME, 
			       strname, 
			       CALMANAMELENGTH)) goto syntaxerror;

    /* Gcell? */
    if (*strname == '#')
    {
      generated = TRUE;
    }
    else
    {
      if(gdsReadCellnameToLower) StrToLower(strname);
      if(gdsReadCellnameToUpper) StrToUpper(strname);
    }

    /* if cellNames set, skip cells not in list */ 
    /* don't skip gcells since they may be referenced! */
    if(cellNames && !generated && !HashLookOnly(&gdsReadCellNameHash, strname))
    {
      if (!calmaSkipTo(CALMA_ENDSTR)) goto syntaxerror;
      return (TRUE);
    }
      
    if (!generated) MsgInfoF("Reading \"%s\".\n", strname);

    /* set up the cell def */
    if(generated)
    {
      /* read into tmp def first so we can compute correct _version prop */
      cifReadCellDef = DBCellLookDef("__GDSTMP__");
      if(!cifReadCellDef)
      {
        cifReadCellDef = DBCellNewDef("__GDSTMP__",(char *) NULL);
	cifReadCellDef->cd_flags |= CDINTERNAL;
        DBCellSetAvail(cifReadCellDef);
      }
    }
    else
    {
      cifReadCellDef = gdsReadFindCell(strname, FALSE);
      
      /* don't over write read-only cell buffers */
      if(cifReadCellDef->cd_flags&CDREADONLY)
      {
	gdsReadMsgWarn("Skipping cell %s (cell buffer is read-only)", 
		       cifReadCellDef->cd_name);

	if (!calmaSkipTo(CALMA_ENDSTR)) goto syntaxerror;
	return (TRUE);
      }

      /* special handling for no_drc */
      if(gdsReadNoDRC && !generated)
      {
	/* mark for post processing */
	cifReadCellDef->cd_flags |= CD_GDS_TAG;  

	/* fix drc vstamp */
	if(!(cifReadCellDef->cd_flags & CDAVAILABLE))
	{
	  cifReadCellDef->cd_vDRC = DBVStampFixed;
	}
      }
      
      /* set cell file */
      {
	char buf[BUFSIZ];
	sprintf(buf,"%s%s.max",dir,strname);
	StrDup(&cifReadCellDef->cd_file,buf);
      }
    }

    DBCellSetAvail(cifReadCellDef);

    /* start with a blank slate! */
    DBCellClearContents(cifReadCellDef);

    cifCurReadPlanes = cifSubcellPlanes;

    /* Skip CALMA_STRCLASS or CALMA_STRTYPE */
    calmaSkipSet(structs);

    /* intialize counts */
    calmaStairSteps = 0;    /* number of non-manhattan geometries approximated
			     * by stair-steps.
			     */
    gdsReadDebugStairStepThresh = 1; /* report when we get here */
    gdsReadNumPolygons = 0; /* number of Max polygons created */
    gdsReadDebugPolygonsThresh = 1; /* report when we get here */
    gdsReadDebugUndefinedRefs = FALSE;

    /* Process Def (Structure) as sequence of elements */
    {
      int nelements=0; 
      int nsrefs = 0;             /* number of instances */ 
      while (calmaParseElement(&nsrefs))
      {
	if (SigInterruptPending) goto interrupt;

	/* give periodic feedback on progress */
	if ((++nelements % gdsReadMessageInterval) == 0)
	{
	    MsgInfoF("\t%d elements read (%d instances), for cell %s ...\n", 
		     nelements,
		     nsrefs, 
		     cifReadCellDef->cd_name);
	}

	/* DEBUG */
	if(gdsReadDebug)
	{
	  if (calmaStairSteps >= gdsReadDebugStairStepThresh)
	  {
	    fprintf(stderr, 
		    "DEBUG, gds reading: %d steps\n",
		    calmaStairSteps);

            gdsReadDebugStairStepThresh *= 10;
	  }

	  if (gdsReadNumPolygons >= gdsReadDebugPolygonsThresh)
	  {
	    fprintf(stderr, 
		    "DEBUG, gds reading: %d polygons\n",
		    gdsReadNumPolygons);

            gdsReadDebugPolygonsThresh *= 10;
	  }
	}
      }
    }

    if (calmaStairSteps)
    {
      MsgInfoF("\t%d non-Manhattan data elements converted to stair-steps.\n",
	       calmaStairSteps);
    }

    /* if left over instance name, complain and clear it! */
    gdsNoisyFreeInstanceName();

    /*
     * Do the geometrical processing and paint this material back into
     * the appropriate cell of the database.
     */
    CIFPaintCurrent();

    /* Make sure def properly terminated with an ENDSTR record */
    if (!calmaSkipExact(CALMA_ENDSTR)) goto syntaxerror;

    goto done;

    /* Interrupted by Cntl-C */
interrupt:
    /* Make sure def properly terminated with an ENDSTR record */
    result = FALSE;
    if (calmaSkipExact(CALMA_ENDSTR)) goto done;

    /* Syntax error: skip to CALMA_ENDSTR */
syntaxerror:
    gdsReadMsgWarn("Syntax error in cell definition.");
    if(result) result = calmaSkipTo(CALMA_ENDSTR);

done:

    if(generated)
    {
      /* create gcell def and copy tmp cell into it */
      char newName[BUFSIZ];
      char version[BUFSIZ];
      CellDef *tmpDef = cifReadCellDef;
      VStamp vs = DBVStampHash(tmpDef);

      /* set proper _version in gcell name */
      sprintf(version,"%d",vs.vs_time);
      StrPropSet(strname,"-_version",version,newName);

      /* record name change, so instances will be adjusted */
      StrMapAdd(gdsReadCellNameMap,strname,newName);

      /* open gcell def */
      cifReadCellDef = DBCellLookDef(newName);
      if(!cifReadCellDef)
      {
	cifReadCellDef = DBCellNewDef(newName,(char *) NULL);
	DBCellSetAvail(cifReadCellDef);
      }
      
      /* mv tmp cell contents to gcell */
      DBCellClearContents(cifReadCellDef);
      DBChangedArea(tmpDef, NULL, NULL, 0); 
      DBCellCopyDefNotify(tmpDef,cifReadCellDef, &GeoIdentityTransform);
      DBCellClearContents(tmpDef);

      cifReadCellDef->cd_flags |= CD_DRC_WITH_PARENT;
      cifReadCellDef->cd_flags |= CD_GENERATED;
      /*      cifReadCellDef->cd_flags |= CD_NO_UNDO; */
      
      /* set names shown when instance is selected */
      {
	char buf[BUFSIZ];
	char *bufp;
	char *namep;

	/* showName */
	bufp = buf;
	namep = cifReadCellDef->cd_name;
	while(*namep!='\0' && *namep!='!') *bufp++ = *namep++;
	strcpy(bufp," (S)");
	cifReadCellDef->cd_showName = StrDup(NULL, buf);

	/* showInst */
	cifReadCellDef->cd_showInst = "?";
      }

      /* process database changes */
      DBChangedArea(cifReadCellDef, 
		    NULL, 
		    NULL, 
		    gdsReadNoDRC ? DBCF_NODRC : 0);

      /* set versions */
      cifReadCellDef->cd_vMAIN = vs;
      cifReadCellDef->cd_vDRC = vs;
      cifReadCellDef->cd_vBBOX = vs;
      cifReadCellDef->cd_vDISPLAY = vs;
    }
    else
    {
      /* process database changes */
      DBChangedArea(cifReadCellDef, 
		    NULL, 
		    NULL, 
		    gdsReadNoDRC ? DBCF_NODRC : 0);
    }

    /* expand instances of gcells */
    DBGCellProcessInstances(cifReadCellDef, FALSE); 

    return result;
}


