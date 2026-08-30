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
 * gdsReadIO.c --
 *
 * Input of Calma GDS-II stream format.
 * Low-level input.
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
static char rcsid[]="$Header: CalmaRdio.c,v 6.0 90/08/28 18:03:41 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include <sys/types.h>

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

/* input buffer */
static int gdsRdFD = -1;        /* Reading from this file descriptor */
bool gdsRdEOF;                  /* set when EOF or error encountered 
				 * while filling input buffer.
				 */
unsigned char gdsRdBuf[BUFSIZ];
unsigned char *gdsRdBufEnd;
unsigned char *gdsRdBufLoc;

/*
 * ----------------------------------------------------------------------------
 *
 * gdsReadIOInit --
 *
 * initializes input buffer, look ahead data etc.
 *
 * called when setting up to read a gdsII file
 *
 * ----------------------------------------------------------------------------
 */
void gdsReadIOInit(int fd)
{
  ASSERT(sizeof(char)==1,"gdsRdIOInit");

  /* file descriptor to read from */
  gdsRdFD = fd;  

  gdsRdEOF = FALSE;

  /* input buffer empty */
  gdsRdBufEnd = &gdsRdBuf[BUFSIZ-1];
  gdsRdBufLoc = gdsRdBufEnd + 1;

  /* no look ahead data */
  calmaLApresent = FALSE; 
}  

/*
 * ----------------------------------------------------------------------------
 *
 * gdsReadBytes1 --
 *
 * read bytes from gdsII input file to specified location
 *
 * called by inline proc gdsReadBytes1() when data not already buffer.
 *
 * returns TRUE on success, FALSE on failure.
 *
 * ----------------------------------------------------------------------------
 */
bool gdsReadBytes1(void *buf, 
		             /* bytes put here */ 
		   int n)
                             /* number of bytes to read */
{
  char *last = gdsRdBufLoc+n;

  ASSERT(gdsRdBufLoc+n > gdsRdBufEnd,"gdsReadBytes1");

  /* copy remaining bytes in current buffer */
  n -= gdsRdBufEnd - gdsRdBufLoc + 1;
  while (gdsRdBufLoc<=gdsRdBufEnd)
  {
    *(((unsigned char *) buf)++) = *(gdsRdBufLoc++);
  }

  /* refill buf */
  {
    int bytesRead = read(gdsRdFD, 
			 (void *) gdsRdBuf,
			  BUFSIZ);

    /* mark the passage of time */
    MnTic(BUFSIZ/50);

    if(bytesRead < MIN(n,BUFSIZ))
    {
      gdsRdEOF = TRUE;

      /* buffer empty */
      gdsRdBufEnd = gdsRdBuf;
      gdsRdBufLoc = gdsRdBuf+1;      

      return FALSE;
    }

    gdsRdBufLoc = gdsRdBuf;
    gdsRdBufEnd = gdsRdBuf+bytesRead-1;
  }

  /* finish (recursively) */

  return gdsReadBytes(buf,n);
}


/*
 * ----------------------------------------------------------------------------
 *
 * calmaSkipBytes --
 *
 * Skip 'nbytes' bytes from the input.
 * WARNING: this procedure doesn't know about input saved via UNREADRH(),
 * so if the caller wants this input to be discarded, it must call READRH()
 * itself.
 *
 * Results:
 *	TRUE if successful, FALSE if EOF was encountered.
 *
 * Side effects:
 *	Consumes nbytes of input.
 *
 * ----------------------------------------------------------------------------
 */

bool calmaSkipBytes(register int nbytes)
                           /* Skip this many bytes */
{
  char skip[BUFSIZ];

  while (nbytes > 0)
  {
    int n = MIN(nbytes,BUFSIZ);

    if (!gdsReadBytes(skip,n)) return FALSE;
    nbytes -= n;
  }

  return TRUE;
}


/*
 * ----------------------------------------------------------------------------
 *
 * calmaReadTransform --
 *
 * Read a CALMA_STRANS, CALMA_MAG, CALMA_ANGLE sequence and construct
 * the corresponding geometric transform.
 *
 * Results:
 *	TRUE normally, FALSE on EOF or fatal syntax error.
 *
 * Side effects:
 *	Consumes input.
 *	Modifies the Transform pointed to by 'ptrans'.
 *
 * ----------------------------------------------------------------------------
 */

bool
calmaReadTransform(Transform *ptrans, char *name)
                      	/* Fill in this transform */
               		/* Name of subcell (for errors) */
{
    int nbytes, rtype, flags, angle;
    double dangle;
    Transform t;

    /* Default is the identity transform */
    *ptrans = GeoIdentityTransform;

    /* Is there any transform at all? */
    READRH(nbytes, rtype);
    if (nbytes < 0) return (FALSE);
    if (rtype != CALMA_STRANS)
    {
	UNREADRH(nbytes, rtype);
	return (TRUE);
    }
    if (nbytes != 6)
    {
	(void) calmaSkipBytes(nbytes - CALMAHEADERLENGTH);
	return (FALSE);
    }
    READI2(flags);

    /* Look for magnification and angle */
    READRH(nbytes, rtype);
    if (nbytes < 0) return (FALSE);
    if (rtype == CALMA_MAG)
    {
	gdsReadMsgWarn("Magnification ignored for instance %s", name);
	calmaSkipBytes(nbytes - CALMAHEADERLENGTH);
    }
    else UNREADRH(nbytes, rtype);

    READRH(nbytes, rtype);
    if (nbytes < 0) return (FALSE);
    dangle = 0.0;
    if (rtype == CALMA_ANGLE)
    {
	if (nbytes != CALMAHEADERLENGTH + 8)
	{
	    (void) calmaSkipBytes(nbytes - CALMAHEADERLENGTH);
	    return (FALSE);
	}
	if (!calmaReadR8(&dangle)) return (FALSE);
    }
    else UNREADRH(nbytes, rtype);

    /* Make sure the angle is Manhattan */
    angle = (int) dangle;
    while (angle < 0) angle += 360;
    while (angle > 360) angle -= 360;
    switch (angle)
    {
	case 360:
	    angle = 0;
	    break;
	case 0:	case 90: case 180: case 270:
	    break;
	default:
	{
	  int angleIn = angle;
	 
	  /* round to manhattan angle */
	  if (angle < 45) angle = 0;
	  else if (angle < 135) angle = 90;
	  else if (angle < 225) angle = 180;
	  else if (angle < 315) angle = 270;
	  else angle = 0;

	  gdsReadMsgWarn("Non-Manhattan instance transform\n\t"
			 "(rotation of %d degrees rounded to %d)",
			 angleIn,angle);
	}
    }

    /*
     * Construct the transform.
     * Max angles are clockwise; Calma angles are counterclockwise.
     */
    if (flags & CALMA_STRANS_UPSIDEDOWN)
    {
	GeoTransTrans(ptrans, &GeoUpsideDownTransform, &t);
	*ptrans = t;
    }
    switch (angle)
    {
	case 90:
	    GeoTransTrans(ptrans, &Geo270Transform, &t);
	    *ptrans = t;
	    break;
	case 180:
	    GeoTransTrans(ptrans, &Geo180Transform, &t);
	    *ptrans = t;
	    break;
	case 270:
	    GeoTransTrans(ptrans, &Geo90Transform, &t);
	    *ptrans = t;
	    break;
    }

    return (TRUE);
}

/*
 * ----------------------------------------------------------------------------
 *
 * calmaReadI2Record --
 *
 * Read a record that should contain a two-byte integer.
 *
 * Results:
 *	TRUE on success, FALSE if the record type we read is not
 *	what we're expecting, or if it is of the wrong size.
 *
 * Side effects:
 *	Consumes input.
 *	Stores the result value in *pvalue (note that this is a normal
 *	int, even though we're reading only 16 bits from the input).
 *
 * ----------------------------------------------------------------------------
 */

bool
calmaReadI2Record(int type, 
             		/* Type of record expected */
		  int *pvalue)
                	/* Store value here */
{
    int nbytes, rtype, n;

    READRH(nbytes, rtype);
    if (nbytes < 0)
	goto eof;
    if (type != rtype)
    {
	gdsReadMsgUnexpectedRecord(type, rtype);
	return (FALSE);
    }

    /* Read the value */
    READI2(n);
    if (gdsRdEOF) goto eof;
    *pvalue = n;
    return (TRUE);

eof:
    gdsReadMsgWarn("Unexpected EOF.\n");
    return (FALSE);
}

/*
 * ----------------------------------------------------------------------------
 *
 * calmaReadI4Record --
 *
 * Read a record that should contain a four-byte integer.
 *
 * Results:
 *	TRUE on success, FALSE if the record type we read is not
 *	what we're expecting, or if it is of the wrong size.
 *
 * Side effects:
 *	Consumes input.
 *	Stores the result value in *pvalue.
 *
 * ----------------------------------------------------------------------------
 */

bool
calmaReadI4Record(int type, int *pvalue)
             		/* Type of record expected */
                	/* Store value here */
{
    int nbytes, rtype, n;

    READRH(nbytes, rtype);
    if (nbytes < 0)
	goto eof;
    if (type != rtype)
    {
	gdsReadMsgUnexpectedRecord(type, rtype);
	return (FALSE);
    }

    /* Read the value */
    READI4(n);
    if (gdsRdEOF) goto eof;
    *pvalue = n;
    return (TRUE);

eof:
    gdsReadMsgWarn("Unexpected EOF.\n");
    return (FALSE);
}

/*
 * ----------------------------------------------------------------------------
 *
 * calmaReadStringRecord --
 *
 * Read a record that should contain an ASCII string.
 *
 * Results:
 *	TRUE on success, FALSE if the record type we read is not
 *	what we're expecting.
 *
 * Side effects:
 *	Consumes input.
 *	Stores the result in the string pointed to by 'str'.
 *
 * ----------------------------------------------------------------------------
 */

bool
calmaReadStringRecord(int type,            /* record type */
		      char *str,           /* string buffer */
		      int maxLength)       /* max length to read 
					    *(excluding terminating '\0')
					    */
{
    int nbytes, rtype;

    READRH(nbytes, rtype);
    if (nbytes < 0)
	goto eof;

    if (type != rtype)
    {
	gdsReadMsgUnexpectedRecord(type, rtype);
	return (FALSE);
    }

    nbytes -= CALMAHEADERLENGTH;

    /* check length */
    if(nbytes>maxLength)
    {
      gdsReadMsgWarn("GDS string length of %d exceeds max of %d\n",
		     nbytes, maxLength);
      return (FALSE);
    }

    if(!gdsReadBytes(str,nbytes)) goto eof;
    str[nbytes] = '\0';
    return (TRUE);

eof:
    gdsReadMsgWarn("Unexpected EOF.\n");
    return (FALSE);
}

/*
 * ----------------------------------------------------------------------------
 *
 * calmaReadR8 --
 *
 * Read a single 8-byte real number in Calma stream format.
 * Convert to internal double-precision format and store in
 * the double pointed to by 'pd'.
 *
 * Results:
 *	TRUE on success, FALSE if EOF is encountered.
 *
 * Side effects:
 *	Consumes input.
 *	Stores the result in the *pd.
 *
 * ----------------------------------------------------------------------------
 */

bool
calmaReadR8(double *pd)
               		/* Store result in *pd */
{
    register int i, exponent;
    unsigned char dchars[8];
    double mantissa, d;
    bool isneg;

    if(!gdsReadBytes(dchars, sizeof dchars)) return FALSE;

    /* Extract the sign and exponent */
    exponent = dchars[0];
    if (isneg = (exponent & 0x80))
	exponent &= ~0x80;
    exponent -= 64;

    /* Construct the mantissa */
    mantissa = 0.0;
    for (i = 7; i > 0; i--)
    {
	mantissa += dchars[i];
	mantissa /= 256.0;
    }

    /* Now raise the mantissa to the exponent */
    d = mantissa;
    if (exponent > 0)
    {
	while (exponent-- > 0)
	    d *= 16.0;
    }
    else if (exponent < 0)
    {
	while (exponent++ < 0)
	    d /= 16.0;
    }

    /* Make it negative if necessary */
    if (isneg)
	d = -d;

    *pd = d;
    return (TRUE);
}

/*
 * ----------------------------------------------------------------------------
 *
 * calmaSkipSet --
 *
 * Skip all records falling in a specified set of types.
 * Leave the input stream positioned to the start of the first
 * record not in the specified set.
 *
 * The array pointed to by 'skipwhat' contains the record types
 * of all records to be skipped, terminated with -1.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Consumes input.
 *
 * ----------------------------------------------------------------------------
 */

Void
calmaSkipSet(int *skipwhat)
{
    int *skipp;
    int nbytes, rtype;

    for (;;)
    {
	READRH(nbytes, rtype);
	if (nbytes < 0)
	    return;

	for (skipp = skipwhat; *skipp >= 0; skipp++)
	    if (*skipp == rtype)
		goto skipit;

	UNREADRH(nbytes, rtype);
	break;

skipit:
	(void) calmaSkipBytes(nbytes - CALMAHEADERLENGTH);
    }
}

/*
 * ----------------------------------------------------------------------------
 *
 * calmaSkipExact --
 *
 * Skip a single stream record, which must be of the type 'type'.
 * Leave the input positioned to the start of the record following
 * this one.  Complain if the record is not the one expected.
 *
 * Results:
 *	TRUE if successful, FALSE if we encountered an error and
 *	the caller should abort.
 *
 * Side effects:
 *	Consumes input.
 *
 * ----------------------------------------------------------------------------
 */

bool
calmaSkipExact(int type)
{
    int nbytes, rtype;

    /* Eat up the record header */
    READRH(nbytes, rtype);

    if (nbytes < 0)
	goto eof;

    /* Skip remainder of record */
    if (!calmaSkipBytes(nbytes - CALMAHEADERLENGTH))
	goto eof;

    if (rtype != type)
    {
	gdsReadMsgUnexpectedRecord(type, rtype);
	return (FALSE);
    }

    return (TRUE);

eof:
    gdsReadMsgWarn("Unexpected EOF.\n");
    return (FALSE);
}


/*
 * ----------------------------------------------------------------------------
 *
 * calmaSkipTo --
 *
 * Skip to a record of a particular type.  Leaves the input stream
 * positioned AFTER the record whose type is given by 'what'.
 *
 * Results:
 *	TRUE if we found this record, FALSE if EOF was encountered.
 *
 * Side effects:
 *	Consumes input.
 *
 * ----------------------------------------------------------------------------
 */

bool
calmaSkipTo(int what)
{
    int nbytes, rtype;

    do
    {
	READRH(nbytes, rtype);
	if (nbytes < 0)
	    return (FALSE);
	calmaSkipBytes(nbytes - CALMAHEADERLENGTH);
    } while (rtype != what);

    return (TRUE);
}
