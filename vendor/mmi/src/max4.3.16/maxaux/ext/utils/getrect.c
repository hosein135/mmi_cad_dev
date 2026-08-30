/*
 * getrect.c -
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
 *			Lawrence Livermore National Laboratory
 *
 * This file contains a procedure, GetRect(), for gobbling up
 * four integers from an input file.
 */

#ifndef lint
static char rcsid[] = "$Header: getrect.c,v 6.0 90/08/28 19:00:45 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include <ctype.h>
#include "magic.h"
#include "geometry.h"

#ifdef	ultrix
typedef char STDIOCHAR;
#else
typedef unsigned char STDIOCHAR;
#endif


/*
 * ----------------------------------------------------------------------------
 *
 * GetRect --
 *
 * Parse a rectangle from a file and fill in the supplied rect struct.
 * We assume that the rectangle consists of four decimal numbers, each
 * separated from the next by a single space, and terminated by a newline.
 *
 * ESTHETIC WARNING:
 *	The algorithm used here is gross but extremely fast.
 *
 * Results:
 *	FALSE on end of file or error, TRUE otherwise.
 *
 * Side effects:
 *	Fills in the contents of *rect.
 *
 * ----------------------------------------------------------------------------
 */

#define	RECTBUFTHRESHOLD	100

#ifdef	linux
#define	FILE_CNT(fin)	((fin)->_IO_read_end - (fin)->_IO_read_ptr)
#define	FILE_PTR(fin)	((char *) fin->_IO_read_ptr)
#define FILE_DEC_CNT(fin, n)	
#define	FILE_SET_PTR(fin, cp) ((fin)->_IO_read_ptr = (cp))

#else
#define	FILE_CNT(fin)	((fin)->_cnt)	
#define	FILE_PTR(fin)	((char *) fin->_ptr)
#define FILE_DEC_CNT(fin, n)	((fin)->_cnt -= (n))
#define	FILE_SET_PTR(fin, cp) ((fin)->_ptr = (cp))

#endif

bool
GetRect(fin, skip, rect)
    register FILE *fin;
    int skip;			/* Number of bytes to skip before rect */
    register Rect *rect;	/* Pointer to rectangle to be filled in */
{
    register n, c;
    register char *cp;
    register bool isNegative;

    if (FILE_CNT(fin) < RECTBUFTHRESHOLD) goto slow;
    /*
     * Fast version of GetRect -- read directly from buffer.
     * This depends on the structure of a standard I/O library (FILE *).
     */
    cp = FILE_PTR(fin) + skip;		/* Skip over "ect " */

    if (isNegative = ((c = *cp++) == '-')) c = *cp++;
    for (n = 0; isdigit(c); n = n * 10 + c - '0', c = *cp++)
	/* Nothing */;
    rect->r_xbot = isNegative ? -n : n;
    if (!isspace(c)) goto fastbad;
    while (isspace(c)) c = *cp++;

    if (isNegative = (c == '-')) c = *cp++;
    for (n = 0; isdigit(c); n = n * 10 + c - '0', c = *cp++)
	/* Nothing */;
    rect->r_ybot = isNegative ? -n : n;
    if (!isspace(c)) goto fastbad;
    while (isspace(c)) c = *cp++;

    if (isNegative = (c == '-')) c = *cp++;
    for (n = 0; isdigit(c); n = n * 10 + c - '0', c = *cp++)
	/* Nothing */;
    rect->r_xtop = isNegative ? -n : n;
    if (!isspace(c)) goto fastbad;
    while (isspace(c)) c = *cp++;

    if (isNegative = (c == '-')) c = *cp++;
    for (n = 0; isdigit(c); n = n * 10 + c - '0', c = *cp++)
	/* Nothing */;
    rect->r_ytop = isNegative ? -n : n;

    /* Adjust the stdio pointers to reflect the characters read */
    FILE_DEC_CNT(fin, cp - (char *) fin->_ptr);
    FILE_SET_PTR(fin, (STDIOCHAR *) cp);

    /* Make sure we skip to end of line or EOF */
    while (c != EOF && c != '\n')
	c = getc(fin);
    return (TRUE);

    /* Adjust the stdio pointers to reflect the characters read */
fastbad:
    FILE_DEC_CNT(fin, cp - (char *) fin->_ptr);
    FILE_SET_PTR(fin, (STDIOCHAR *) cp);
    goto bad;

    /* Slow version of GetRect -- read via getc */
slow:
    while (skip-- > 0)
	(void) getc(fin);

    if (isNegative = ((c = getc(fin)) == '-')) c = getc(fin);
    for (n = 0; isdigit(c); n = n * 10 + c - '0', c = getc(fin))
	/* Nothing */;
    rect->r_xbot = isNegative ? -n : n;
    if (!isspace(c)) goto bad;
    while ((c = getc(fin)) != EOF && isspace(c)) /* Nothing */;

    if (isNegative = (c == '-')) c = getc(fin);
    for (n = 0; isdigit(c); n = n * 10 + c - '0', c = getc(fin))
	/* Nothing */;
    rect->r_ybot = isNegative ? -n : n;
    if (!isspace(c)) goto bad;
    while ((c = getc(fin)) != EOF && isspace(c)) /* Nothing */;

    if (isNegative = (c == '-')) c = getc(fin);
    for (n = 0; isdigit(c); n = n * 10 + c - '0', c = getc(fin))
	/* Nothing */;
    rect->r_xtop = isNegative ? -n : n;
    if (!isspace(c)) goto bad;
    while ((c = getc(fin)) != EOF && isspace(c)) /* Nothing */;

    if (isNegative = (c == '-')) c = getc(fin);
    for (n = 0; isdigit(c); n = n * 10 + c - '0', c = getc(fin))
	/* Nothing */;
    rect->r_ytop = isNegative ? -n : n;
    while (c != EOF && c != '\n')
	c = getc(fin);
    return (TRUE);

bad:
    while (c != EOF && c != '\n')
	c = getc(fin);
    return (FALSE);
}
