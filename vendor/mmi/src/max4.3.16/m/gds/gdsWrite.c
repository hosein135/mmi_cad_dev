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
 * GdsWrite.c --
 *
 * Output of Calma GDS-II stream format.
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
static char rcsid[]="$Header: GdsWrite.c,v 6.0 90/08/28 18:03:48 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include <ctype.h>
#include <sys/types.h>
#include <time.h>
#include "magic.h"
#include "geometry.h"
#include "tile.h"
#include "utils.h"
#include "hash.h"
#include "database.h"
#include "databaseInt.h"
#include "main.h"
#include "cif.h"
#include "cifInt.h"
#include "signals.h"
#include "layout.h"
#include "styles.h"
#include "message.h"
#include "gdsInt.h"
#include "gds.h"
#include "debug.h"

    /* GDS Write setup globals */
char *gdsWriteLibName = NULL;  /* library name to output */

double gdsWriteScaleFactor = 1.0;  /* scale size by this factor */
bool gdsWriteRestrictCharacterSet = FALSE;  /* map strings to GDS-II character set */
bool gdsWriteRestrictCellNameLength = FALSE; /* map names to 32 chars or less */
bool GDSWriteLabels = TRUE; /* If FALSE, don't output labels with GDS-II */
bool GDSWriteMixedCaseLabels = TRUE;	 /* If TRUE, allow lowercase labels. */
bool GDSWriteArrays = TRUE; /* If FALSE, output arrays as individual uses */
bool gdsWriteReportRoundingErrors = TRUE;   
bool gdsWriteReportExtendedCharacterSet = FALSE;
bool gdsWriteReportExtendedCellNameLength = FALSE;
bool gdsWriteProcessInteractions = TRUE;  /* if true hierarchical interactions
					   * are handled specially - at very
					   * high performance cost!
					   */
bool GDSWriteFlattenGCells = TRUE;         
bool gdsMapSlashHack = FALSE;                 /* temporary hack */

/* Number assigned to each cell */
int calmaCellNum;

/* scale factor for DB to GDS coodinates */
double gdsScaleDB2GDS;

/* Scale factor for CIFPlane to GDS coordinates */
double gdsScaleCIFPlane2GDS;

/*
 * Current layer number and "type".
 * In GDS-II format, this is output with each rectangle.
 */
int calmaPaintLayerNumber;
int calmaPaintLayerType;

/* Current file we are writing to */
FILE *calmaWriteFile;

/* CIF layers that we need to gen */
TileTypeBitMask gdsWriteCIFGenLayers;

/* Imports */
extern time_t time(time_t *);


/* -------------------------------------------------------------------- */

/*
 * gdsWriteIOInit --
 *
 * Call to setup gds output to file (via macros below)
 */
void 
gdsWriteIOInit(FILE *f)
{
  calmaWriteFile = f;
}

static char calmaMapTable[] =
{
      0,    0,    0,    0,    0,    0,    0,    0,	/* NUL - BEL */
      0,    0,    0,    0,    0,    0,    0,    0,	/* BS  - SI  */
      0,    0,    0,    0,    0,    0,    0,    0,	/* DLE - ETB */
      0,    0,    0,    0,    0,    0,    0,    0,	/* CAN - US  */
      0,    0,    0,    0,  '$',    0,    0,    0,	/* SP  - '   */
      0,    0,    0,    0,    0,    0,    0,    0,	/* (   - /   */
    '0',  '1',  '2',  '3',  '4',  '5',  '6',  '7',	/* 0   - 7   */
    '8',  '9',    0,    0,    0,    0,    0,    0,	/* 8   - ?   */
      0,  'A',  'B',  'C',  'D',  'E',  'F',  'G',	/* @   - G   */
    'H',  'I',  'J',  'K',  'L',  'M',  'N',  'O',	/* H   - O   */
    'P',  'Q',  'R',  'S',  'T',  'U',  'V',  'W',	/* P   - W   */
    'X',  'Y',  'Z',    0,    0,    0,    0,  '_',	/* X   - _   */
      0,  'a',  'b',  'c',  'd',  'e',  'f',  'g',	/* `   - g   */
    'h',  'i',  'j',  'k',  'l',  'm',  'n',  'o',	/* h   - o   */
    'p',  'q',  'r',  's',  't',  'u',  'v',  'w',	/* p   - w   */
    'x',  'y',  'z',    0,    0,    0,    0,    0,	/* x   - DEL */
};

/*
 * ----------------------------------------------------------------------------
 *
 * calmaOutStringRecord --
 *
 * Output a complete string-type record.  The actual record
 * type is given by 'type'.  Up to the first CALMANAMELENGTH characters
 * of the string 'str' are output.  Any characters in 'str'
 * not in the legal Calma stream character set are output as
 * 'X' instead.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Writes to the FILE 'f'.
 *
 * ----------------------------------------------------------------------------
 */
void
calmaOutStringRecord(int type, 
		         /* Type of this record (data type is ASCII string) */
		     register char *str)
                       	 /* String to be output (<= CALMANAMELENGTH chars) */
{
    int len;
    register unsigned char c;
    register FILE *f = calmaWriteFile; 

    len = strlen(str);

    /*
     * Make sure length is even.
     * Output at most CALMANAMELENGTH characters.
     */
    if (len & 01) len++;
    if (len > CALMANAMELENGTH) len = CALMANAMELENGTH;
    calmaOutI2(len+4);	/* Record length */
    (void) putc(type, f);		/* Record type */
    (void) putc(CALMA_ASCII, f);	/* Data type */

    /* Output the string itself */
    while (len--)
    {
	c = (unsigned char) *str++;
	if (c == 0)
	{
	  putc('\0', f);
	}  
	else
	{
	    if (c > 127 || 
		(CIFCurStyle->cs_charSetRestrict && calmaMapTable[c] == 0)
	      ) 
	    {
	      c = 'X';
	    }  
	    else
	    {
	      if(CIFCurStyle->cs_charSetRestrict) c = calmaMapTable[c];
	    }

	    if (!GDSWriteMixedCaseLabels && islower(c))
		(void) putc(toupper(c), f);
	    else
		(void) putc(c, f);
	}
    }
}


/*
 * ----------------------------------------------------------------------------
 *
 * calmaOut8 --
 *
 * Output 8 bytes.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Writes to the FILE 'f'.
 *
 * ----------------------------------------------------------------------------
 */
void
calmaOut8(register unsigned char *str)
                                	/* 8-byte string to be output */
                     	/* Stream file */
{
    register i;

    for (i = 0; i < 8; i++)
	(void) putc(*str++, calmaWriteFile);
}


/*
 * ----------------------------------------------------------------------------
 *
 * calmaWriteText --
 *
 * Output a text element to the stream file.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Writes to calmaWriteFile
 *
 * ----------------------------------------------------------------------------
 */
static void
calmaWriteText(Point DBp, char *text, int calmaNum, int calmaType )
     /* DBp is in database coords */
{
  calmaOutRH(4, CALMA_TEXT, CALMA_NODATA);

  calmaOutRH(6, CALMA_LAYER, CALMA_I2);
  calmaOutI2(calmaNum);

  calmaOutRH(6, CALMA_TEXTTYPE, CALMA_I2);
  calmaOutI2(calmaType);

  calmaOutRH(12, CALMA_XY, CALMA_I4);
  calmaOutI4(ROUND(DBp.p_x * gdsScaleDB2GDS));
  calmaOutI4(ROUND(DBp.p_y * gdsScaleDB2GDS));

  /* Text of label */
  if(gdsMapSlashHack)
  {
    char mapped[BUFSIZ];
    bool changed = FALSE;
    char *in, *out;

    /* map '|' to '/' */
    for (in = text,out=mapped ; *in; in++,out++)
    {
      if ( *in == '|' )
      {
	/* this is a temporary hack! */
	/* TODO replace with real escapes! */
	*out = '/';
      }
      else
      {
	*out = *in;
      }
    }
    *out = '\0';

    /* output string */
    calmaOutStringRecord(CALMA_STRING, mapped);
  }
  else
  {
    /* output string */
    calmaOutStringRecord(CALMA_STRING, text);
  }

  /* End of element */
  calmaOutRH(4, CALMA_ENDEL, CALMA_NODATA);
}


/*
 * ----------------------------------------------------------------------------
 *
 * calmaOutStructName --
 *
 * Output the name of a cell def.
 * If the name is legal GDS-II, use it; otherwise, generate one
 * that is legal and unique.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Writes to the disk file.
 *
 * ----------------------------------------------------------------------------
 */

void calmaOutStructName(int type, CellDef *def)
{
    char defname[CALMANAMELENGTH+1];
    register unsigned char c;
    register char *cp;
    int calmanum;

    /* Is the def name a legal Calma name? */
    for (cp = def->cd_name; c = (unsigned char) *cp; cp++)
	if (c > 127 || 
	    (CIFCurStyle->cs_charSetRestrict && calmaMapTable[c] == 0)
	   )
	    goto bad;
    if (cp <= def->cd_name + CALMANAMELENGTH)
    {
	/* Yes, it's legal: use it */
	(void) strcpy(defname, def->cd_name);
    }
    else
    {
	/* Bad name: use XXXXXcalmaNum */
bad:
	calmanum = (int) def->cd_client;
	if (calmanum < 0) calmanum = -calmanum;
	(void) sprintf(defname, "XXXXX%d", calmanum);
    }

    calmaOutStringRecord(type, defname);
}


/*
 * ----------------------------------------------------------------------------
 *
 * calmaWriteUseFunc --
 *
 * Filter function, called by DBEnumChildren on behalf of calmaOutFunc above,
 * to write out each CellUse called by the CellDef being output.  If the
 * CellUse is an array, we output it as a single array instead of as
 * individual uses like CIF.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Appends to the open Calma output file.
 *
 * ----------------------------------------------------------------------------
 */

static int
calmaWriteUseFunc(CellUse *use, ClientData notUsed)
{
    /*
     * r90, r180, and r270 are Calma 8-byte real representations
     * of the angles 90, 180, and 270 degrees.
     */
    static unsigned char r90[] =
		{ 0x42, 0x5a, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };
    static unsigned char r180[] =
		{ 0x42, 0xb4, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };
    static unsigned char r270[] =
		{ 0x43, 0x10, 0xe0, 0x00, 0x00, 0x00, 0x00, 0x00 };
    unsigned char *whichangle;
    int x, y, topx, topy, xxlate, yxlate, hdrsize;
    int rows = 0;  /* initialize to avoid compiler warning */
    int cols = 0;  /* initialize to avoid compiler warning */
    int rectype, stransflags;
    register Transform *t;
    bool isArray = FALSE;
    Point p, p2;

    /* if flattening gcells, don't write as instances */
    if(GDSWriteFlattenGCells && 
       (use->cu_def->cd_flags&CD_GENERATED)) return 0;

    if(DBIsArray(use))
    {
      topx = use->cu_xhi - use->cu_xlo;
      if (topx < 0) topx = -topx;
      topy = use->cu_yhi - use->cu_ylo;
      if (topy < 0) topy = -topy;
    }
    else
    {
      topx = 0;
      topy = 0;
    }

    /*
     * The following translates from the abcdef transforms that
     * we use internally to the rotation and mirroring specification
     * used in Calma stream files.  It only works because orientations
     * are orthogonal in magic, and no scaling is allowed in cell use
     * transforms.  Thus the elements a, b, d, and e always have one
     * of the following forms:
     *
     *		a  d
     *		b  e
     *
     * (counterclockwise rotations of 0, 90, 180, 270 degrees)
     *
     *	1  0	0  1	-1  0	 0 -1
     *	0  1   -1  0	 0 -1	 1  0
     *
     * (mirrored across the x-axis before counterclockwise rotation
     * by 0, 90, 180, 270 degrees):
     *
     *	1  0    0  1    -1  0    0 -1
     *	0 -1    1  0     0  1   -1  0
     *
     * Note that mirroring must be done if either a != e, or
     * a == 0 and b == d.
     *
     */
    t = &use->cu_transform;
    stransflags = 0;
    whichangle = (t->t_a == -1) ? r180 : (unsigned char *) NULL;
    if (t->t_a != t->t_e || (t->t_a == 0 && t->t_b == t->t_d))
    {
	stransflags |= CALMA_STRANS_UPSIDEDOWN;
	if (t->t_a == 0)
	{
	    if (t->t_b == 1) whichangle = r90;
	    else whichangle = r270;
	}
    }
    else if (t->t_a == 0)
    {
	if (t->t_b == -1) whichangle = r90;
	else whichangle = r270;
    }

    if (!GDSWriteArrays)
    {
        /* output instance name as text centered in bounding box */
        /* TODO:  instance name writes with flattened array! */
        if(CIFCurStyle->cs_iNameCalmaNum >=0 || 
	   CIFCurStyle->cs_iNamePropNum>=0 )
        {
	    MsgInfoF("Warning: not outputting instance ids"
		     " with calma write of flattened array\n");
        }

	for (x = 0; x <= topx; x++)
	{
	    for (y = 0; y <= topy; y++)
	    {

		/* Structure reference */
		calmaOutRH(4, CALMA_SREF, CALMA_NODATA);
		calmaOutStructName(CALMA_SNAME, use->cu_def);

		/* Transformation flags */
		calmaOutRH(6, CALMA_STRANS, CALMA_BITARRAY);
		calmaOutI2(stransflags);

		/* Rotation if there is one */
		if (whichangle)
		{
		    calmaOutRH(12, CALMA_ANGLE, CALMA_R8);
		    calmaOut8(whichangle);
		}

		/* Translation */
		if(DBIsArray(use))
		{
		  xxlate = t->t_c + t->t_a*(use->cu_xsep)*x
		    + t->t_b*(use->cu_ysep)*y;
		  yxlate = t->t_f + t->t_d*(use->cu_xsep)*x
		    + t->t_e*(use->cu_ysep)*y;
		}
		else
		{
		  xxlate = t->t_c;
		  yxlate = t->t_f;
		}

		xxlate = ROUND(xxlate * gdsScaleDB2GDS);
		yxlate = ROUND(yxlate * gdsScaleDB2GDS);
		calmaOutRH(12, CALMA_XY, CALMA_I4);
		calmaOutI4(xxlate);
		calmaOutI4(yxlate);

		/* End of element */
		calmaOutRH(4, CALMA_ENDEL, CALMA_NODATA);
	    }
	}
    }
    else
    {
        /* output instance name as text centered in bounding box */
        if(CIFCurStyle->cs_iNameCalmaNum >=0)
	{
	  Point center;
          Rect *bbox = DBBBoxCellUseNoUp(use);

	  /* put label at center of bounding box */
          center.p_x = (bbox->r_xtop + bbox->r_xbot) / 2;
	  center.p_y = (bbox->r_ytop + bbox->r_ybot) / 2;

	  /* write it */
	  ASSERT(use->cu_id, "calmaWriteUseFunc");
	  calmaWriteText(center,
			 use->cu_id,
			 CIFCurStyle->cs_iNameCalmaNum,
			 CIFCurStyle->cs_iNameCalmaType);
	}

	/* Is it an array? */
	isArray = (topx > 0 || topy > 0);
	rectype = isArray ? CALMA_AREF : CALMA_SREF;

	/* Structure reference */
	calmaOutRH(4, rectype, CALMA_NODATA);
	calmaOutStructName(CALMA_SNAME, use->cu_def);

	/* Transformation flags */
	calmaOutRH(6, CALMA_STRANS, CALMA_BITARRAY);
	calmaOutI2(stransflags);

	/* Rotation if there is one */
	if (whichangle)
	{
	    calmaOutRH(12, CALMA_ANGLE, CALMA_R8);
	    calmaOut8(whichangle);
	}

	/* If array, number of columns and rows in the array */
	if (isArray)
	{
	    calmaOutRH(8, CALMA_COLROW, CALMA_I2);
	    cols = topx + 1;
	    rows = topy + 1;
	    calmaOutI2(cols);
	    calmaOutI2(rows);
	}

	/* Translation */
	xxlate = ROUND(t->t_c * gdsScaleDB2GDS);
	yxlate = ROUND(t->t_f * gdsScaleDB2GDS);
	hdrsize = isArray ? 28 : 12;
	calmaOutRH(hdrsize, CALMA_XY, CALMA_I4);
	calmaOutI4(xxlate);
	calmaOutI4(yxlate);

	/* Array sizes if an array */
	if (isArray)
	{
	    /* Column reference point */
	    p.p_x = use->cu_xsep * cols;
	    p.p_y = 0;
	    GeoTransPoint(t, &p, &p2);
	    p2.p_x = ROUND(p2.p_x * gdsScaleDB2GDS);
	    p2.p_y = ROUND(p2.p_y *gdsScaleDB2GDS);
	    calmaOutI4(p2.p_x);
	    calmaOutI4(p2.p_y);

	    /* Row reference point */
	    p.p_x = 0;
	    p.p_y = use->cu_ysep * rows;
	    GeoTransPoint(t, &p, &p2);
	    p2.p_x = ROUND(p2.p_x * gdsScaleDB2GDS);
	    p2.p_y = ROUND(p2.p_y * gdsScaleDB2GDS);
	    calmaOutI4(p2.p_x);
	    calmaOutI4(p2.p_y);
	}

	/* output instance name as property */
        if(CIFCurStyle->cs_iNamePropNum>=0 )
	{
	  ASSERT(use->cu_id,"calmaWriteUseFunc - PROPATTR");
	  calmaOutRH(6, CALMA_PROPATTR, CALMA_I2);
	  calmaOutI2(CIFCurStyle->cs_iNamePropNum);
          calmaOutStringRecord(CALMA_PROPVALUE, use->cu_id);
	}

	/* End of element */
	calmaOutRH(4, CALMA_ENDEL, CALMA_NODATA);
    }

    return (0);
}


/*
 * ----------------------------------------------------------------------------
 *
 * calmaWriteRect --
 *
 * Guts of Write out a rectangle (e.g. a paint tile)
 *
 *			**** NOTE ****
 * There are loads of Calma systems out in the world that
 * don't understand CALMA_BOX, so we output CALMA_BOUNDARY
 * even though CALMA_BOX is more appropriate.  Bletch.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Writes to the disk file.
 *
 * ----------------------------------------------------------------------------
 */
static void
calmaWriteRect(Rect r, int layer, int type)
                        		/* rect to be written out. */
            				/* File in which to write. */
{
    r.r_xbot = ROUND(r.r_xbot * gdsScaleCIFPlane2GDS);
    r.r_ybot = ROUND(r.r_ybot * gdsScaleCIFPlane2GDS);
    r.r_xtop = ROUND(r.r_xtop * gdsScaleCIFPlane2GDS);
    r.r_ytop = ROUND(r.r_ytop * gdsScaleCIFPlane2GDS);

    /* unit conversion may lead to degenerate (0 area rects)
     * don't output these.
     */
    if(r.r_xbot == r.r_xtop || r.r_ybot == r.r_ytop) return;

    /* Boundary */
    calmaOutRH(4, CALMA_BOUNDARY, CALMA_NODATA);

    /* Layer */
    calmaOutRH(6, CALMA_LAYER, CALMA_I2);
    calmaOutI2(layer);

    /* Data type */
    calmaOutRH(6, CALMA_DATATYPE, CALMA_I2);
    calmaOutI2(type);

    /* Coordinates */
    calmaOutRH(44, CALMA_XY, CALMA_I4);
    
    calmaOutI4(r.r_xbot); calmaOutI4(r.r_ybot);
    calmaOutI4(r.r_xtop); calmaOutI4(r.r_ybot);
    calmaOutI4(r.r_xtop); calmaOutI4(r.r_ytop);
    calmaOutI4(r.r_xbot); calmaOutI4(r.r_ytop);
    calmaOutI4(r.r_xbot); calmaOutI4(r.r_ybot);

    /* End of element */
    calmaOutRH(4, CALMA_ENDEL, CALMA_NODATA);
}


/*
 * ----------------------------------------------------------------------------
 *
 * calmaWritePaintFunc --
 *
 * Filter function used to write out a single paint tile.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Writes to the disk file.
 *
 * ----------------------------------------------------------------------------
 */

static int
calmaWritePaintFunc(register Tile *tile, ClientData notUsed)
                        		/* Tile to be written out. */
            				/* File in which to write. */
{
    Rect r;

    TiToRect(tile, &r);
    calmaWriteRect(r,calmaPaintLayerNumber,calmaPaintLayerType);

    return 0;
}




/*
 * ----------------------------------------------------------------------------
 *
 * calmaWriteRectDB --
 *
 * Guts of Write out a rectangle (e.g. a paint tile)
 *
 * This 'DB'version is for writing out database rather than cif tiles.  
 *
 *			**** NOTE ****
 * There are loads of Calma systems out in the world that
 * don't understand CALMA_BOX, so we output CALMA_BOUNDARY
 * even though CALMA_BOX is more appropriate.  Bletch.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Writes to the disk file.
 *
 * ----------------------------------------------------------------------------
 */
static void
calmaWriteRectDB(Rect r, int layer, int type)
{
    r.r_xbot = ROUND(r.r_xbot * gdsScaleDB2GDS);
    r.r_ybot = ROUND(r.r_ybot * gdsScaleDB2GDS);
    r.r_xtop = ROUND(r.r_xtop * gdsScaleDB2GDS);
    r.r_ytop = ROUND(r.r_ytop * gdsScaleDB2GDS);

    /* unit conversion may lead to degenerate (0 area rects)
     * don't output these.
     */
    if(r.r_xbot == r.r_xtop || r.r_ybot == r.r_ytop) return;

    /* Boundary */
    calmaOutRH(4, CALMA_BOUNDARY, CALMA_NODATA);

    /* Layer */
    calmaOutRH(6, CALMA_LAYER, CALMA_I2);
    calmaOutI2(layer);

    /* Data type */
    calmaOutRH(6, CALMA_DATATYPE, CALMA_I2);
    calmaOutI2(type);

    /* Coordinates */
    calmaOutRH(44, CALMA_XY, CALMA_I4);
    
    calmaOutI4(r.r_xbot); calmaOutI4(r.r_ybot);
    calmaOutI4(r.r_xtop); calmaOutI4(r.r_ybot);
    calmaOutI4(r.r_xtop); calmaOutI4(r.r_ytop);
    calmaOutI4(r.r_xbot); calmaOutI4(r.r_ytop);
    calmaOutI4(r.r_xbot); calmaOutI4(r.r_ybot);

    /* End of element */
    calmaOutRH(4, CALMA_ENDEL, CALMA_NODATA);
}


/*
 * ----------------------------------------------------------------------------
 *
 * calmaWriteDBPaintFunc --
 *
 * Filter function used to write out a single paint tile.
 *
 * This 'DB' version is for database rather than cif planes.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Writes to the disk file.
 *
 * ----------------------------------------------------------------------------
 */

static int
calmaWriteDBPaintFunc(Tile *tile, 
		      TreeContext *cxp)
{
    SearchContext *scx = cxp->tc_scx;
    Rect rIn, r;

    /* Construct the rect for the tile in source coordinates */
    TITORECT(tile, &rIn);

    /* Transform to top-level coords (needed for gcells) */ 
    GEOTRANSRECT(&scx->scx_trans, &rIn, &r);

    /* write it out */
    calmaWriteRectDB(r,calmaPaintLayerNumber,calmaPaintLayerType);

    /* continue search */
    return 0;
}


/*
 * ----------------------------------------------------------------------------
 *
 * calmaWriteLabel --
 *
 * Output a single label to the stream file.
 *
 * The CIF type to which this label is attached is 'type'; if this
 * is < 0 then the label is not output.
 *
 * Non-point labels are collapsed to point labels located at the center
 * of the original label.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Writes to the gdsWriteFile.
 *
 * ----------------------------------------------------------------------------
 */

void calmaWriteLabel(Label *lab, 
               	               /* Label to output */
		     CIFLayer *cl)
                               /* CIF Layer label is attached too */ 
{
    Point center;
    int calmaNum;
    int calmaType;

    calmaNum = cl->cl_labelGDSNum[lab->lab_kind];
    if(calmaNum>=0)
    {
      calmaType = cl->cl_labelGDSType[lab->lab_kind];
    }
    else      
    {
      calmaNum = cl->cl_calmanum;
      if (!CalmaIsValidLayer(calmaNum)) return;
      calmaType = cl->cl_calmatype;
    }

    /* center point in database coords */
    center.p_x = (lab->lab_rect.r_xbot + lab->lab_rect.r_xtop) / 2;
    center.p_y = (lab->lab_rect.r_ybot + lab->lab_rect.r_ytop) / 2;

    /* write out text element */
    calmaWriteText(center,
		   lab->lab_text,
		   calmaNum,
		   calmaType);
}


/*
 * ----------------------------------------------------------------------------
 *
 * calmaWritePolygon --
 *
 * Output a single polygon to the stream file.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Writes to the gdsWriteFile.
 *
 * ----------------------------------------------------------------------------
 */

static void calmaWritePolygon(Polygon *poly,
			      int gdsLayer,
			      int gdsType)
{
    int size = poly->poly_size;

    /* Boundary */
    calmaOutRH(4, CALMA_BOUNDARY, CALMA_NODATA);

    /* Layer */
    calmaOutRH(6, CALMA_LAYER, CALMA_I2);
    calmaOutI2(gdsLayer);

    /* Data type */
    calmaOutRH(6, CALMA_DATATYPE, CALMA_I2);
    calmaOutI2(gdsType);

    /* Coordinates */
    calmaOutRH((size+1)*8+4, CALMA_XY, CALMA_I4);
    {
      PointFloat *pf;
      int i;
      pf = poly->poly_points;
      for(i=0; i<size; i++)
      {
	calmaOutI4(ROUND(pf->pf_x*gdsScaleDB2GDS)); 
	calmaOutI4(ROUND(pf->pf_y*gdsScaleDB2GDS));
	pf++;
      }
      /* close by repeating first point */
      calmaOutI4(ROUND(poly->poly_points->pf_x*gdsScaleDB2GDS));
      calmaOutI4(ROUND(poly->poly_points->pf_y*gdsScaleDB2GDS));
    }

    /* End of element */
    calmaOutRH(4, CALMA_ENDEL, CALMA_NODATA);
}



/*
 * ----------------------------------------------------------------------------
 *
 * gdsWriteWP --
 *
 * Output a single wirepath to the stream file.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Writes to the gdsWriteFile.
 *
 * ----------------------------------------------------------------------------
 */

static void gdsWriteWP(WirePath *wp,
		       int gdsLayer,
		       int gdsType)
{
    int size = wp->wp_size;

    /* Path */
    calmaOutRH(4, CALMA_PATH, CALMA_NODATA);

    /* Layer */
    calmaOutRH(6, CALMA_LAYER, CALMA_I2);
    calmaOutI2(gdsLayer);

    /* Data type */
    calmaOutRH(6, CALMA_DATATYPE, CALMA_I2);
    calmaOutI2(gdsType);

    /* end cap style */
    /* Don't support variable style wirepaths yet */
    ASSERT(wp->wp_style != WP_STYLE_VARIABLE,"gdsWriteWP");
    calmaOutRH(6, CALMA_PATHTYPE, CALMA_I2);
    calmaOutI2(wp->wp_style);


    /* width */
    calmaOutRH(8, CALMA_WIDTH, CALMA_I4);
    calmaOutI4(wp->wp_width);

    /* coordinates */
    calmaOutRH(size*8+4, CALMA_XY, CALMA_I4);
    {
      Point *p;
      int i;
      p = wp->wp_points;
      for(i=0; i<size; i++)
      {
	calmaOutI4(ROUND(p->p_x*gdsScaleDB2GDS)); 
	calmaOutI4(ROUND(p->p_y*gdsScaleDB2GDS));
	p++;
      }
    }

    /* End of element */
    calmaOutRH(4, CALMA_ENDEL, CALMA_NODATA);
}


/*
 * ----------------------------------------------------------------------------
 *
 * calmaOutDate --
 *
 * Output a date/time specification to the FILE 'f'.
 * This consists of outputting 6 2-byte quantities,
 * or a total of 12 bytes.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Writes to the FILE 'f'.
 *
 * ----------------------------------------------------------------------------
 */

void calmaOutDate(time_t t)
             	/* Time (UNIX format) to be output */
{
    struct tm *datep = localtime(&t);
    /* year 2000 currently coming out as 100, seems to be consistent 
     * with other tools that gen GDSII, 
     * so we don't correct here. - mha 11/15/00
     */  

    calmaOutI2(datep->tm_year);
    calmaOutI2(datep->tm_mon+1);
    calmaOutI2(datep->tm_mday);
    calmaOutI2(datep->tm_hour);
    calmaOutI2(datep->tm_min);
    calmaOutI2(datep->tm_sec);
}


/*
 * ----------------------------------------------------------------------------
 *
 * gdsWriteCIFGenInit --
 *
 * Called by GDSWriteFile to compute which cif layers we will need.
 * 
 * Results:
 *	None.
 *
 * Side effects:
 *	Sets gdsWriteCIFGenLayers
 *
 * ----------------------------------------------------------------------------
 */
static void gdsWriteCIFGenInit(void)
{
  int type;

  TTMaskZero(&gdsWriteCIFGenLayers);

  /* if processing interactions, give up and gen all layers */
  if(gdsWriteProcessInteractions)
  {
    for (type = 0; type < CIFCurStyle->cs_nLayers; type++)
    {
      TTMaskSetType(&gdsWriteCIFGenLayers,type);
    }
    return;
  }

  for (type = 0; type < CIFCurStyle->cs_nLayers; type++)
  {
    CIFLayer *layer = CIFCurStyle->cs_layers[type];
    CIFOp *co = layer->cl_ops;

    /* skip temp layers */
    if (layer->clay_flags & CIF_TEMP) continue;

    /* skip non-gds layers */
    if (!CalmaIsValidLayer(layer->cl_calmanum)) continue;

    /* skip layers with no operations */
    if (!co) continue;

    /* skip simple ors of paint layers */
    if(!co->co_next && 
       co->co_opcode == CIFOP_OR && 
       TTMaskIsZero(&co->co_cifMask)) continue;

    /* need to gen this layer */
    TTMaskSetType(&gdsWriteCIFGenLayers,type);

    /* DEBUG

    fprintf(stderr,"DEBUG gdsWriteCIFGenInit cl=%s calmanum=%d calmatype=%d\n",
	    layer->cl_name,
	    layer->cl_calmanum,
	    layer->cl_calmatype);
    */
  }

  /* generate closure (include referenced layers) */
  while(1)
  {
    TileTypeBitMask old;

    old = gdsWriteCIFGenLayers;

    for (type = 0; type < CIFCurStyle->cs_nLayers; type++)
    {
      CIFLayer *layer = CIFCurStyle->cs_layers[type];
      CIFOp *co;

      if(!TTMaskHasType(&gdsWriteCIFGenLayers,type)) continue;

      for(co = layer->cl_ops; co; co=co->co_next)
      {
	TTMaskSetMask(&gdsWriteCIFGenLayers,&co->co_cifMask);
      }
    }

    /* if nothing was added, we are done */
    if(TTMaskEqual(&gdsWriteCIFGenLayers,&old)) break;
  }

  /* DEBUG 
  fprintf(stderr,"DEBUG gdsWriteCIFGenInit final layer list:\n");
  for (type = 0; type < CIFCurStyle->cs_nLayers; type++)
  {
    if(!TTMaskHasType(&gdsWriteCIFGenLayers,type)) continue;

    fprintf(stderr,"DEBUG gdsWriteCIFGenInit cl=%s\n",
	    CIFCurStyle->cs_layers[type]->cl_name);
  }
  */
}     


/*
 * ----------------------------------------------------------------------------
 *
 * calmaOutFunc --
 *
 * Write out the definition for a single cell as a GDS-II stream format
 * structure.  We try to preserve the original cell's name if it is legal
 * in GDS-II; otherwise, we generate a unique name.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Appends to the open Calma output file.
 *
 * ----------------------------------------------------------------------------
 */
static void
calmaOutFunc(CellDef *def)
                 	/* Pointer to cell def to be written */
            		/* Open output file */
{
    register Label *lab;
    CIFLayer *layer;
    Rect bigArea;
    int type;

    /* if flatten gcells set, don't output gcell defs */  
    if(GDSWriteFlattenGCells && (def->cd_flags&CD_GENERATED)) return;

    /* Output structure begin */
    calmaOutRH(28, CALMA_BGNSTR, CALMA_I2);
    
    /* creation time and last modified time for this def
     *  (using MAIN timestamp for this def for both.) 
     */
    calmaOutDate(def->cd_version.vs_time);
    calmaOutDate(def->cd_version.vs_time);

    /* Output structure name */
    calmaOutStructName(CALMA_STRNAME, def);

    /* conversion factor from DB to GDS */
    gdsScaleDB2GDS = CIFDBRes/CIFGDSRes;

    /* conversion factor from CIPPlanes to GDS */
    gdsScaleCIFPlane2GDS = CIFPlaneRes/CIFGDSRes;

    /* Output bounding box */
    if(CIFCurStyle->cs_bBoxCalmaNum >= 0) 
    {
      Rect bbox = *DBBBoxCellDef(def);
      double scale = CIFDBRes/CIFPlaneRes;

      /* convert bounding box to cif plane coords */
      bbox.r_xbot = ROUND(bbox.r_xbot * scale);
      bbox.r_xtop = ROUND(bbox.r_xtop * scale);
      bbox.r_ybot = ROUND(bbox.r_ybot * scale);
      bbox.r_ytop = ROUND(bbox.r_ytop * scale);

      calmaWriteRect(bbox,
		     CIFCurStyle->cs_bBoxCalmaNum,
		     CIFCurStyle->cs_bBoxCalmaType);
    }
      
    /*
     * Output the calls that the child makes to its children.  For
     * arrays we output a single call, unlike CIF, since Calma
     * supports the notion of arrays.
     */
    (void) DBEnumChildren(def, calmaWriteUseFunc, (ClientData) 0);

    /* generate cif tile planes */
    GEO_EXPAND(DBBBoxCellDef(def), CIFCurStyle->cs_radius, &bigArea);
    CIFErrorDef = def;
    CIFGen(def, 
	   &bigArea, 
	   CIFPlanes,
	   &gdsWriteCIFGenLayers,
	   TRUE, 
	   FALSE,
	   GDSWriteFlattenGCells);

    if(gdsWriteProcessInteractions && CIFCurStyle->cs_hierInteractions)
    {
      if(TTMaskIntersect(&DBAllTypeBits,&CIFCurStyle->cs_yankLayers))
      {
	CIFGenSubcells(def, &bigArea, CIFPlanes, GDSWriteFlattenGCells);
	CIFGenArrays(def, &bigArea, CIFPlanes, GDSWriteFlattenGCells);
      }
    }

    /* Output all the tiles associated with this cell */
    {
      CellUse searchUse;
      SearchContext scx;

      /* setup search context, 
       * (used for paint plane searches) 
       */

      DBCellUseNewTemp(def,&searchUse);
      searchUse.cu_expandMask = LAY_ALL_WINDOWS; /* need to match gcell mask 
						  * for search below to work.  
						  */
      scx.scx_use = &searchUse;
      scx.scx_x = 0;
      scx.scx_y = 0;
      scx.scx_area = *DBBBoxCellDef(def);
      scx.scx_trans = GeoIdentityTransform;

      for (type = 0; type < CIFCurStyle->cs_nLayers; type++)
      {
	layer = CIFCurStyle->cs_layers[type];
	if (layer->clay_flags & CIF_TEMP) continue;
	if (!CalmaIsValidLayer(layer->cl_calmanum)) continue;
	calmaPaintLayerNumber = layer->cl_calmanum;
	calmaPaintLayerType = layer->cl_calmatype;

	if(TTMaskHasType(&gdsWriteCIFGenLayers,type))
	{
	  /* Output CIF layer */
	  DBPlaneEnumAreaPaint((Tile *) NULL, 
			       CIFPlanes[type],
			       &TiPlaneRect, 
			       &CIFSolidBits, 
			       calmaWritePaintFunc,
			       (ClientData) 0);
	}
	else
	{
	  /* Output database paint layer(s) */
	  CIFLayer *layer = CIFCurStyle->cs_layers[type];
	  CIFOp *co = layer->cl_ops;

	  /* if no associated paint layers, skip */ 
	  if(!co || TTMaskIsZero(&co->co_paintMask)) continue;

	  DBSearchPaintNew2(&scx,
			    &co->co_paintMask,
			    LAY_ALL_WINDOWS,      /* gcell's mask */
			    NULL,   /* terminal path */
			    calmaWriteDBPaintFunc,
			    NULL,   /* polygon func */
			    NULL,   /* wirepath func */
			    NULL,   /* ClientData */
			    GDSWriteFlattenGCells ? 0 : DBSP_NON_RECURSIVE); 
	}
      }
    }

    /* free the cif planes */
    for (type = 0; type < CIFCurStyle->cs_nLayers; type++)
    {
      if (CIFPlanes[type])
      {
	DBFreePaintPlane(CIFPlanes[type]);
	TiFreePlane(CIFPlanes[type]);
	CIFPlanes[type] = NULL;
      }
    }

    /* Output polygons */
    {
      int unmapped[TT_MAXTYPES];  
      Polygon *poly;
      int type;

      /* initialize error info */
      for(type=0; type<TT_MAXTYPES; type++) 
      {
	unmapped[type] = 0;
      }

      /* write them out */
      for(poly = def->cd_polygons; poly; poly = poly->poly_next)
      {
	int cifType, gdsLayer, gdsType;

	/* don't output polygons that are part of a wire path */
	if(poly->poly_wirePath) continue;

        cifType = CIFCurStyle->cs_polygonLayer[poly->poly_type];
	if (cifType < 0)
	{
	  unmapped[poly->poly_type]++; 
	  continue;
	}
	gdsLayer = CIFCurStyle->cs_layers[cifType]->cl_calmanum;
	if (!CalmaIsValidLayer(gdsLayer)) 
	{
	  unmapped[poly->poly_type]++; 
	  continue;
	}
	gdsType= CIFCurStyle->cs_layers[cifType]->cl_calmatype;
	calmaWritePolygon(poly, gdsLayer, gdsType);
      }

      /* report any unmapped output */
      for(type=0; type<TT_MAXTYPES; type++) 
      {
	if (unmapped[type]==0) continue;

	MsgWarnF("GDS write, cell %s:  "
		 "%d polygons on layer %s skipped (not mapped)\n",
		 def->cd_name,
		 unmapped[type],
		 DBTypeLongName(type));
      }
    }

    /* Output wirepaths */
    {
      int unmapped[TT_MAXTYPES];  
      WirePath *wp;
      int type;

      /* initialize error info */
      for(type=0; type<TT_MAXTYPES; type++) 
      {
	unmapped[type] = 0;
      }

      /* write them out */
      for(wp = def->cd_wirePaths; wp; wp = wp->wp_next)
      {
	int cifType, gdsLayer, gdsType;

        cifType = CIFCurStyle->cs_polygonLayer[wp->wp_type];
	if (cifType < 0)
	{
	  unmapped[wp->wp_type]++; 
	  continue;
	}
	gdsLayer = CIFCurStyle->cs_layers[cifType]->cl_calmanum;
	if (!CalmaIsValidLayer(gdsLayer)) 
	{
	  unmapped[wp->wp_type]++; 
	  continue;
	}
	gdsType= CIFCurStyle->cs_layers[cifType]->cl_calmatype;
	gdsWriteWP(wp, gdsLayer, gdsType);
      }

      /* report any unmapped output */
      for(type=0; type<TT_MAXTYPES; type++) 
      {
	if (unmapped[type]==0) continue;

	MsgWarnF("GDS write, cell %s:  "
		 "%d wirepaths on layer %s skipped (not mapped)\n",
		 def->cd_name,
		 unmapped[type],
		 DBTypeLongName(type));
      }
    }

    /* Output labels */
    if (GDSWriteLabels)
    {
      int unmapped[TT_MAXTYPES];  
      int type;

      /* initialize error info */
      for(type=0; type<TT_MAXTYPES; type++) 
      {
	unmapped[type] = 0;
      }

      for (lab = def->cd_labels; lab; lab = lab->lab_next)
      {
	int index = CIFCurStyle->cs_labelLayer[lab->lab_type];
	if (index<0)
	{
	  unmapped[lab->lab_type]++;
	  continue;
	}
	calmaWriteLabel(lab, CIFCurStyle->cs_layers[index]);
      }

      /* report any unmapped output */
      for(type=0; type<TT_MAXTYPES; type++) 
      {
	if (unmapped[type]==0) continue;

	MsgWarnF("GDS write, cell %s:  "
		 "%d labels on layer %s skipped (not mapped)\n",
		 def->cd_name,
		 unmapped[type],
		 DBTypeLongName(type));
      }
    }

    /* End of structure */
    calmaOutRH(4, CALMA_ENDSTR, CALMA_NODATA);
}


/*
 * ----------------------------------------------------------------------------
 *
 * calmaOutHeader --
 *
 * Output the header description for a Calma file.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Writes to the FILE 'f'.
 *
 * ----------------------------------------------------------------------------
 */

Void
calmaOutHeader(CellDef *rootDef)
{
    /* useru = 0.001, mum = 1.0e-9 in Calma 8-byte real format */
    static unsigned char useru[] =
		{ 0x3e, 0x41, 0x89, 0x37, 0x4b, 0xc6, 0xa7, 0xef };
    static unsigned char mum[] =
		{ 0x39, 0x44, 0xb8, 0x2f, 0xa0, 0x9b, 0x5a, 0x53 };

    /* GDS II version 3.0 */
    calmaOutRH(6, CALMA_HEADER, CALMA_I2);
    calmaOutI2(3);

    /* Beginning of library */
    calmaOutRH(28, CALMA_BGNLIB, CALMA_I2);
    
    /* last mod time (using MAIN timestamp of root def) */
    calmaOutDate(rootDef->cd_version.vs_time); 

    /* last access time (using now!) */
    calmaOutDate(time((time_t *) 0));

    /* Library name (name of root cell) */
    if(gdsWriteLibName && *gdsWriteLibName)
    {
      calmaOutStringRecord(CALMA_LIBNAME, gdsWriteLibName);
    }
    else
    {
      /* default to root def name */
      calmaOutStructName(CALMA_LIBNAME, rootDef);
    }

    /*
     * Units.
     * User units are microns; this is really unimportant.
     * Database units are millimicrons, since there are lots
     * of programs that don't understand anything else.
     */
    calmaOutRH(20, CALMA_UNITS, CALMA_R8);
    calmaOut8(useru);	/* User units per database unit */
    calmaOut8(mum);	/* Meters per database unit */
}


/*
 * ----------------------------------------------------------------------------
 *
 * calmaProcessUse --
 * calmaProcessDef --
 *
 * Main loop of Calma generation.  Performs a post-order, depth-first
 * traversal of the tree rooted at 'def'.  Only cells that have not
 * already been output are processed.
 *
 * The procedure calmaProcessDef() is called initially; calmaProcessUse()
 * is called internally by DBEnumChildren().
 *
 * Results:
 *	returns 0
 *
 * Side effects:
 *	Causes Calma GDS-II stream-format to be output.
 *	Returns when the stack is empty.
 *
 * ----------------------------------------------------------------------------
 */




static int calmaProcessUse(CellUse *use, 
                 	/* Process use->cu_def */
			   ClientData notUsed)
               		/* Stream file */
{
  static int calmaProcessDef(CellDef *def);     /* forward ref */
  return (calmaProcessDef(use->cu_def));
}

static int calmaProcessDef(CellDef *def)
                 	/* Output this def's children, then the def itself */
{

    /* Skip if already output */
    if ((int) def->cd_client > 0)
	return (0);

    /* Assign it a (negative) number if it doesn't have one yet */
    if ((int) def->cd_client == 0)
	def->cd_client = (ClientData) calmaCellNum--;

    /* Mark this cell */
    def->cd_client = (ClientData) (- (int) def->cd_client);

    /* Read the cell in if it is not already available. */
    if (!DBReadCell(def)) return 0;

    /*
     * Output the definitions for any of our descendants that have
     * not already been output.  Numbers are assigned to the subcells
     * as they are output.
     */
    (void) DBEnumChildren(def, calmaProcessUse, (ClientData) 0);

    /* Output this cell */
    calmaOutFunc(def);

    return (0);
}


/*
 * ----------------------------------------------------------------------------
 *
 * GDSWriteFile --
 *
 * Write out the entire tree rooted at the supplied CellDef in Calma
 * GDS-II stream format, to the specified file.
 *
 * Results:
 *	TRUE if the cell could be written successfully, FALSE otherwise.
 *
 * Side effects:
 *	Writes a file to disk.
 *	In the event of an error while writing out the cell,
 *	the external integer errno is set to the UNIX error
 *	encountered.
 *
 * Algorithm:
 *
 *	Calma names can be strings of up to CALMANAMELENGTH characters.
 *	Because general names won't map into Calma names, we use the
 *	original cell name only if it is legal Calma, and otherwise
 *	generate a unique numeric name for the cell.
 *
 *	We make a depth-first traversal of the entire design tree, outputting
 *	each cell to the Calma file.  If a given cell has not been read in
 *	when we visit it, we read it in ourselves.
 *
 *	No hierarchical design rule checking or bounding box computation
 *	occur during this traversal -- both are explicitly avoided.
 *
 * ----------------------------------------------------------------------------
 */

bool
GDSWriteFile(CellDef *rootDef, 
        	/* Pointer to CellDef to be written */
	     FILE *f)
      		/* Open output file */
{
    int oldCount = LayFeedbackCount, problems;
    bool good;

    /* setup IO to output */
    gdsWriteIOInit(f); 

    /* figure out which CIF layers we will need */
    gdsWriteCIFGenInit(); 

    /*
     * Make sure that the entire hierarchy rooted at rootDef is
     * read into memory.  And run DBUpdate() to get correct instance
     * bounding boxes.
     */
    DBReadCellTree(rootDef);
    DBUpdate(rootDef);

    /* def client fields used to avoid writing a def multiple times
     * should all be 0 initially, but clear anyway, just to be safe. 
     * 
     * "assert" that this is so.
     */
    DBCellClearDefClients(TRUE);

    rootDef->cd_client = (ClientData) -1;
    calmaCellNum = -2;

    /* Output the header, identifying this file */
    calmaOutHeader(rootDef);

    /*
     * We perform a post-order traversal of the tree rooted at 'rootDef',
     * to insure that each child cell is output before it is used.  The
     * root cell is output last.
     */
    (void) calmaProcessDef(rootDef);

    /* Finish up by outputting the end-of-library marker */
    calmaOutRH(4, CALMA_ENDLIB, CALMA_NODATA);
    good = !ferror(f);

    /* See if any problems occurred */
    if (problems = (LayFeedbackCount - oldCount))
	MsgInfoF("%d problems occurred.  See feedback entries.\n", problems);

    /* Be a good citizen and clear all cd_client fields before returning */
    DBCellClearDefClients(FALSE);

    return (good);
}







