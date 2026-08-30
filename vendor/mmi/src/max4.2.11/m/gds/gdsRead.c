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
 * gdsRead.c --
 *
 * Input of GDS-II stream format.
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
static char rcsid[] = "$Header: CalmaRead.c,v 6.0 90/08/28 18:03:46 mayo Exp $";
#endif  not lint

#include <sys/types.h>
#include <stdio.h>
#include <math.h>
#include <stdarg.h>

#include "magic.h"
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
#include "gdsInt.h"
#include "undo.h"
#include "debug.h"
#include "gds.h"

/*
 * data strucs below define gds records
 *
 * (also used by gdsDump.c and gdsInfo.c)
 */

/* Record data types */
char *gdsDataTypes[] =
{
  "no_data",
  "bit_array",
  "int2",
  "int4",
  "real4",
  "real8",
  "string"
};	

/* Record data type element sizes */
char gdsDataTypeSizes[] =
{
  1,  
  1,
  2,
  4,
  4,
  8,
  1
};

/* Record Types */
/* (record datatypes used in gdsCompile.c) */
GDSRecordType gdsRecordTypes[] =
{
  "HEADER",    CALMA_I2,
  "BGNLIB",    CALMA_I2,
  "LIBNAME",   CALMA_ASCII,
  "UNITS",     CALMA_R8,
  "ENDLIB",    CALMA_NODATA,
  "BGNSTR",    CALMA_I2,
  "STRNAME",   CALMA_ASCII,
  "ENDSTR",    CALMA_NODATA,
  "BOUNDARY",  CALMA_NODATA,
  "PATH",      CALMA_NODATA,
  "SREF",      CALMA_NODATA, 
  "AREF",      CALMA_NODATA,
  "TEXT",      CALMA_NODATA,
  "LAYER",     CALMA_I2,
  "DATATYPE",  CALMA_I2,
  "WIDTH",     CALMA_I4,
  "XY",        CALMA_I4,
  "ENDEL",     CALMA_NODATA,
  "SNAME",     CALMA_ASCII,
  "COLROW",    CALMA_I2,
  "TEXTNODE",  CALMA_NODATA,      
  "NODE",      CALMA_NODATA,
  "TEXTTYPE",  CALMA_I2,
  "PRESENTATION", CALMA_BITARRAY,
  "SPACING",   CALMA_NODATA,       
  "STRING",    CALMA_ASCII,
  "STRANS",    CALMA_BITARRAY,
  "MAG",       CALMA_R8,
  "ANGLE",     CALMA_R8,
  "UINTEGER",  CALMA_NODATA,      
  "USTRING",   CALMA_NODATA,      
  "REFLIBS",   CALMA_ASCII,
  "FONTS",     CALMA_ASCII,
  "PATHTYPE",  CALMA_I2, 
  "GENERATIONS",  CALMA_I2,
  "ATTRTABLE", CALMA_ASCII,
  "STYPTABLE", CALMA_NODATA,
  "STRTYPE",   CALMA_I2,
  "ELFLAGS",   CALMA_BITARRAY,
  "ELKEY",     CALMA_I4,
  "LINKTYPE",  CALMA_I2,
  "LINKKEYS",  CALMA_I4,
  "NODETYPE",  CALMA_I2,
  "PROPATTR",  CALMA_I2,
  "PROPVALUE", CALMA_ASCII,
  "BOX",       CALMA_NODATA,
  "BOXTYPE",   CALMA_I2,
  "PLEX",      CALMA_I4,
  "BGNEXTN",   CALMA_I4,
  "ENDEXTN",   CALMA_I4,
  "TAPENUM",   CALMA_I2,
  "TAPECODE",  CALMA_I2,
  "STRCLASS",  CALMA_BITARRAY,
  "RESERVED",  CALMA_NODATA,
  "FORMAT",    CALMA_I2,
  "MASK",      CALMA_ASCII,
  "ENDMASKS",  CALMA_NODATA,
  "LIBDIRSIZE",  CALMA_I2, 
  "SRFNAME",   CALMA_ASCII,
  "LIBSECUR",  CALMA_I2,   
  "BORDER",    CALMA_NODATA,
  "SOFTFENCE", CALMA_NODATA,
  "HARDFENCE", CALMA_NODATA,
  "SOFTWIRE",  CALMA_NODATA,
  "HARDWIRE",  CALMA_NODATA,
  "PATHPORT",  CALMA_NODATA,
  "NODEPORT",  CALMA_NODATA,
  "USERCONSTRAINT", CALMA_NODATA,
  "SPACERERROR", CALMA_NODATA,
  "CONTACT",   CALMA_NODATA
};

/*
 * Globals for GDS Reading setup 
 */

/* linked to tcl var GDS_READ_DEBUG */
bool gdsReadDebug = FALSE;

/* map cellnames to lower or upper case */
bool gdsReadCellnameToLower = FALSE;
bool gdsReadCellnameToUpper = FALSE;

/* scale design by this factor */
double gdsReadScaleFactor = 1.0;

/* round to design grid (aka user units), to be removed! */
bool gdsReadSnapToDesignGrid = TRUE;

/* double grid to round input to in microns (0 = round to internal units) */
double gdsReadSnapTo = 0.0;

/* if set create Max layers for GDS layers in input not defined in 
 * current istyle and read them in (with out transformation)
 */
bool gdsReadUnmappedLayers = FALSE;

/* controls for warnings */
bool gdsReadReportRoundingErrors = TRUE;
bool gdsReadReportDuplicateInstances = FALSE;
bool gdsReadReportUnmappedLayers = TRUE;
bool gdsReadNoDRC = FALSE;
int gdsReadReportMaxWarnings = 100;

/* scale factors used when reading GDS */
double gdsRdScaleGDS2CIFPlane;

/* round resolution, in internal units, computed from gdsReadSnapTo. */
int gdsRdRoundRes;

/* following variable used to keep track of maximum error when applying
 * above scale factor.
 */
double gdsRdScaleGDS2CIFPlaneErr = 0;

/*
 * Lookahead: calmaLApresent is TRUE when calmaLAnbytes and calmaLArtype
 * are set to the record header of a record we just ungot.
 */
bool calmaLApresent;	/* TRUE if lookahead input waiting */
int calmaLAnbytes;	/* # bytes in record (from header)  */
int calmaLArtype;	/* Record type */

/* cellname mapping table
 * initially used only to get "-_versions" right on gcells
 * eventually to be usde for general name mapping.
 */
void *gdsReadCellNameMap;

/*
 * hash table for unrecognized layers.
 *
 * gds "layers" are defined by pair of numbers:
 * (layer, datatype).  These two numbers really just define a mask layer
 * and can be assigned in any way.
 * 
 * Whenever an unrecognized (layer, datatype) is encountered
 * it is entered into this hash table, to avoid repeated error messages.
 *
 */
HashTable calmaLayerHash;

/*
 * hash table for list of cells to read
 * (only used when cellNames given on call to GDSReadFile)
 *
 */
HashTable gdsReadCellNameHash;

/* keep track of warnings on ciflayers not mapped for non-manhattan output */
bool gdsReadCIFWarning[MAXCRSLAYERS];

/* Common stuff to ignore 
 * PLEX     elements are groupings of geometries ?
 * ELFLAGS  element flags ?
 */
int calmaElementIgnore[] = { CALMA_ELFLAGS, CALMA_PLEX, -1 };

/*
 * GLOBAL VARIABLE FOR INSTANCE NAMES
 *
 * text "labels" on a given layer (cifCurReadStyle->crs_iNameCalmaNum) are
 * used to supply instance names.
 * 
 * The labels appear just before the instances (SREF) in the gds file.
 * 
 * When such a label is read it is stashed in this global variable,
 * when the following SREF is encountered, the instance name is used, and
 * this variable is reset.
 *
 * If this variable is not NULL (an instance name has not been used) when
 * another instance name is encountered, a definition is ended, etc.,
 * a warning is generated (by gdsNoisyFreeInstanceName() below).
 *
 */
char *gdsInstanceName=NULL;


/*
 * ----------------------------------------------------------------------------
 *
 * GDSTechInit --
 *
 * Do some checks one time checks at startup time (during technology
 * file read in)
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Error checking.
 *
 * ----------------------------------------------------------------------------
 */
void 
GDSTechInit(void)
{
    ASSERT(sizeof(FourByteInt)==4, "definition in gdsInt.h");
    ASSERT(sizeof(TwoByteInt)==2, "definition in gdsInt.h");
}

/*
 * ----------------------------------------------------------------------------
 *
 * calmaRecordName --
 *
 * Return a pointer to the printable name of a CALMA record type.
 *
 * Results:
 *	See above.
 *
 * Side effects:
 *	May overwrite the string we returned on the previous call.
 *
 * ----------------------------------------------------------------------------
 */
char *
calmaRecordName(int rtype)
{
    static char numeric[10];

    if (rtype < 0 || rtype >= CALMA_NUMRECORDTYPES)
    {
	(void) sprintf(numeric, "%d", rtype);
	return (numeric);
    }

    return (gdsRecordTypes[rtype].grt_name);
}

/*
 * ----------------------------------------------------------------------------
 *
 * gdsNoisyFreeInstanceName --
 *
 * If an (unused) instance name is still around, complain, and clear it 
 *
 * ----------------------------------------------------------------------------
 */
void 
gdsNoisyFreeInstanceName()
{
  if(gdsInstanceName)
  {
    gdsReadMsgWarn("No SREF (instance) for instance name '%s'\n",
	     gdsInstanceName);
    FREE(gdsInstanceName);
  }
}


/*
 * ----------------------------------------------------------------------------
 *
 * gdsReadParseUnits --
 *
 * Process the CALMA_UNITS record that sets the relationship between
 * user units (stored in the stream file) and centimicrons.
 *
 * Results:
 *	TRUE if successful, FALSE if we encountered an error and
 *	the caller should abort.
 *
 * Side effects:
 *	Consumes input.
 *	Sets scalefactor (gdsRdScaleGDS2CIFPlane) used to
 *      scale coordinates and dimensions during gds reading.
 *
 * NOTE:
 *	We don't care about user units, only database units.  The
 *	GDS-II stream specifies the number of meters per database
 *	unit, which we use to compute the number of centimicrons
 *	per database unit.  Since database units are floating point,
 *	there is a possibility of roundoff unless the number of
 *	centimicrons per user unit is an integer value.
 *
 * ----------------------------------------------------------------------------
 */

static bool
gdsReadParseUnits(void)
{
    int nbytes, rtype;
    double metersPerDBUnit;
    double userUnitsPerDBUnit;

    READRH(nbytes, rtype);
#ifdef	lint
    nbytes = nbytes;
#endif	lint

    if (rtype != CALMA_UNITS)
    {
      gdsReadMsgUnexpectedRecord(CALMA_UNITS, rtype);
      gdsReadMsgError("Could not read units record\n");
      return (FALSE);
    }

    /* Skip user units per database unit */
    if (!calmaReadR8(&userUnitsPerDBUnit)) return (FALSE);

    /* Read meters per database unit */
    if (!calmaReadR8(&metersPerDBUnit)) return (FALSE);

#ifdef	notdef
    MsgInfoF("1 database unit equals %e user units\n", userUnitsPerDBUnit);
    MsgInfoF("1 database unit equals %e meters\n", metersPerDBUnit);
    MsgInfoF("1 user unit equals %e database units\n", 1.0/userUnitsPerDBUnit);
    MsgInfoF("1 meter equals %e database units\n", 1.0/metersPerDBUnit);
#endif	notdef

    /* set scale factors for GDS reading */
    {
      double res = metersPerDBUnit * 1.0e6; /* GDS unit size in microns */

      if (cifCurReadStyle->crs_scaleFactor)
      {
	/* old fashioned scaleFactor specified in cifinput style */
	gdsRdScaleGDS2CIFPlane = gdsReadScaleFactor * res / 0.01; /* cifplanes in centimicrons */
      }
      else
      {
	/* compute scale factors from resolutions */
	gdsRdScaleGDS2CIFPlane = gdsReadScaleFactor * res / CIFPlaneRes; 
      }
    }

    return (TRUE);
}

/*
 * ----------------------------------------------------------------------------
 *
 * gdsReadHashCellNames --
 *
 * Sets up gdsReadCellNameHash.
 *
 * ----------------------------------------------------------------------------
 */
void gdsReadHashCellNames(char *cellNames)
{
  if(!cellNames) return;

  HashInit(&gdsReadCellNameHash, 16, HT_STRINGKEYS);

  while(cellNames)
  {
    char *name = cellNames;
    char *p = name;

    /* pick off first name */
    while(*p!='\0' && *p!=',') p++;  
    if(*p==',')
    {
      cellNames = p+1;
    }
    else
    {
      cellNames = NULL;
    }
    *p = '\0';

    /* add it to hash table */
    HashFind(&gdsReadCellNameHash, name);
  }
}    


/*
 * ----------------------------------------------------------------------------
 *
 * gdsReadFile --
 *
 * Read an entire GDS-II stream format library from the open FILE 'file'.
 * If CellName, non null, readin only that cell.
 *
 * Results:
 *	Guess at toplevel def read. 
 *
 * Side effects:
 *	May modify the contents of cifReadCellDef by painting or adding
 *	new uses or labels.  May also create new CellDefs.
 *
 * ----------------------------------------------------------------------------
 */

CellDef * 
gdsReadFile(int fd, 
	                        /* File descriptor from which to 
				   read GDSII data */
	    char *cellNames,
                                /* If cellNames non-null, reads only
				 * cells in cellNames (',' separated
				 *  list)
				 */

	    char *dir)          /* if non-null home cells read in this
				 * directory.
				 */
				   
{
    int version;
    char libName[CALMANAMELENGTH + 2];
    static int hdrSkip[] = { CALMA_FORMAT, CALMA_MASK, CALMA_ENDMASKS,
			     CALMA_REFLIBS, CALMA_FONTS, CALMA_ATTRTABLE,
			     CALMA_STYPTABLE, CALMA_GENERATIONS, -1 };
    static int skipBeforeLib[] = { CALMA_LIBDIRSIZE, CALMA_SRFNAME, 
				   CALMA_LIBSECUR, -1 };
    CellDef *topDef = NULL;  /* returned */

    /* initial lib name */
    libName[0] = '\0'; 

    /* The GDS-II reader maps input geometrys to "cifplanes" which are
     * then processed according to the current cifinput style to generate
     * the "max" layers that are added to the database.
     * 
     * Much of this processing is shared with CIF reading
     * and is done in the cif module.  Initialize the CIF module stuff
     * now.
     *
     * 0 arg = use full cell names as keys in CifCellTable 
     */
    CIFReadCellInit(0);  
    cifReadCellDef=NULL;

    if (cifCurReadStyle == NULL)
    {
	MsgErrorF("Don't know how to read GDS-II:\n");
	MsgErrorF("Nothing in \"cifinput\" section of tech file.\n");
	return NULL;
    }

    /* warn about unimplemented options */
    if(gdsReadUnmappedLayers) 
    {
      MsgWarnF("Input of unmapped layers during GDS-II reading is not yet implemented:\n"
	       "\tIgnoring unmapped layers!");
    }

      
    /* let user know if we are scaling */
    gdsRdRoundRes = 1;
    if(gdsReadScaleFactor != 1.0)
    {
      MsgInfoF("Scaling GDS-II input to %g x.\n", gdsReadScaleFactor);
    }

    /* setup rounding and inform user */
    if(gdsReadSnapTo != 0.0)
    {
      gdsRdRoundRes = gdsReadSnapTo/CIFDBRes;

      if(gdsRdRoundRes <= 0)
      {
	MsgWarnF("GDS-II snap-to (rounding) grid is too small, ignoring!\n");
	gdsRdRoundRes = 1;
      }
      else
      {
	if(ABSDIFF(gdsRdRoundRes*CIFDBRes, gdsReadSnapTo)>UNIT_TOLERANCE)
        {
	  MsgWarnF("GDS-II snap to grid (%g microns) not exact multiple of\n" 
		   "internal units (%g) microns:  rounding errors will result!\n");
	}

	MsgInfoF("Snapping (rounding) GDS-II input to %g grid.\n", gdsReadSnapTo);
      }
    }

    UndoDisable();

    /* convert cellNames to read to hashtable */
    gdsReadHashCellNames(cellNames);

    /* intialize read IO primitives */ 
    gdsReadIOInit(fd);

    /* clear any instance name left over from prior gds read */
    if(gdsInstanceName) 
    {
      FREE(gdsInstanceName);
      gdsInstanceName = NULL;
    }

    /* initialize message processing */
    gdsReadMsgInit();

    /* Initialize cellname mapping table */
    gdsReadCellNameMap = StrMapInit();

    /* Initialize the hash table for layer errors */
    HashInit(&calmaLayerHash, 32, sizeof (CalmaLayerType) / sizeof (unsigned));

    /* Initialize array for ciflayer errors */
    {
      int i;
      for(i=0; i<MAXCRSLAYERS; i++) gdsReadCIFWarning[i] = FALSE;
    }

    /* intialize rounding errors */
    gdsRdScaleGDS2CIFPlaneErr = 0.0;
    cifRdScaleCIFPlane2DBErr = 0.0;

    /* Read the GDS-II header */
    if (!calmaReadI2Record(CALMA_HEADER, &version)) goto error;
    if (version < 600)
	MsgInfoF("Library written using GDS-II Release %d.0\n", version);
    else
	MsgInfoF("Library written using GDS-II Release %d.%d\n", 
	    version / 100, version % 100);
    if (!calmaSkipExact(CALMA_BGNLIB)) goto error;
    calmaSkipSet(skipBeforeLib);
    if (!calmaReadStringRecord(CALMA_LIBNAME, 
			       libName,
			       CALMANAMELENGTH)) goto error;
    if (libName[0])
	MsgInfoF("Library name: %s\n", libName);

    /* Skip the reflibs, fonts, etc. cruft */
    calmaSkipSet(hdrSkip);

    /* Set the scale factors */
    if (!gdsReadParseUnits()) goto error;

    /* Main body of GDS-II input (series of cell defs) */
    while (calmaParseStructure(cellNames!=NULL, dir))
    {
        if (SigInterruptPending) 
	{
	  MsgWarnF("GDS-II reading interrupted!\n");
	  goto done;
	}
    }
    (void) calmaSkipExact(CALMA_ENDLIB);
    goto done;

error:
    gdsReadMsgError("Invalid preliminary records.\n");
done:

    /* report round off errors */
    if(gdsReadReportRoundingErrors)
    {
      if(gdsRdScaleGDS2CIFPlaneErr > UNIT_TOLERANCE) 
      {
	double err = gdsRdScaleGDS2CIFPlaneErr;
	err *= cifRdScaleCIFPlane2DB; 
	err *= CIFDBRes;

	MsgWarnF("GDS-II -> mask planes round off error.  "
		 "(maximum error = %g microns)\n",
		 err);
      }
      if(cifRdScaleCIFPlane2DBErr > UNIT_TOLERANCE)
      {
	double err = cifRdScaleCIFPlane2DBErr;
	err *= CIFDBRes;

	MsgWarnF("mask planes -> Max database round off error.  "
		 "(maximum error = %g microns)\n",
		 err);
      }
    }

    /* warn if we got partial def */
    if (cifSubcellBeingRead)
    {
	gdsReadMsgWarn("File ended partway through a cell definition.\n");
    }

    /* if gdsReadNoDRC, cleanout drc checks */
    if(gdsReadNoDRC)
    {
      /* first update all defs to avoid drc checks to do bbox
       * mismatches
       */
      {
	HashEntry *h;
	HashSearch hs;

	/* update all cells referenced or defined during gds read 
	 * this is done first to fix any bounding box mismatches
	 * that would trigger drc on next update.
	 */
	HashStartSearch(&hs);
	while((h=HashNext(&CifCellTable, &hs)) != NULL)
        {
	  CellDef *def = (CellDef *) HashGetValue(h);
	  DBUpdate(def);
	}

	/* declare all defs read in to be drc clean */
	HashStartSearch(&hs);
	while((h=HashNext(&CifCellTable, &hs)) != NULL)
        {
	  CellDef *def = (CellDef *) HashGetValue(h);

	  /* only 'clean' cells we've read in */
	  if(!(def->cd_flags & CD_GDS_TAG)) continue;

	  def->cd_flags &= ~CD_GDS_TAG;  /* reset GDS_TAG */
	  DRCClean(def);
	}
      }
    }

    /* find a top-level cell read in (to return) */
    {
      HashEntry *h;
      HashSearch hs;
      bool new;

      topDef = NULL;

      /* try starting with library name */
      if(strlen(libName) != 0)
      {
	h = HashLookOnly(&CifCellTable, libName);
	if(h) topDef = (CellDef *) HashGetValue(h);
      }

      /* if no luck, start with any cell referenced in gds file */
      if(!topDef)
      {
	HashStartSearch(&hs);
	h = HashNext(&CifCellTable, &hs);
	if(h) topDef = (CellDef *) HashGetValue(h);
      }

      /* walk up hierarchy until we get to cell that has no parents that
       * were referenced in file 
       */
      new = FALSE;
      if(topDef) new = TRUE;
      while(new)
      {
	CellPar *pars; 
	new = FALSE;

	for(pars = topDef->cd_pars; pars!=NULL; pars=pars->cp_next)
	{
	  CellDef *parent = pars->cp_def;
	  ASSERT(parent,"GDSReadFile");

	  h = HashLookOnly(&CifCellTable, parent->cd_name);
	  if(h) 
	  {
	    topDef = (CellDef *) HashGetValue(h);
	    new = TRUE;
	    break;
	  }
	} /* for */
      } /* while */
    } /* find a toplevel cell ... */

    /* free temporary storage */
    CIFReadCellCleanup();
    HashKill(&calmaLayerHash);
    if(cellNames) HashKill(&gdsReadCellNameHash);
    StrMapFree(gdsReadCellNameMap);

    UndoEnable();
    return topDef; 
}




