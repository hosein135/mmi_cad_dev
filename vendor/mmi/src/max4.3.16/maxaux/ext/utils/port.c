/* port.c
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
 *
 * This file contains routines that are needed when porting between machines.
 */

#ifndef lint
static char rcsid[] = "$Header: port.c,v 6.0 90/08/28 19:01:11 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include <math.h>
#include "magic.h"
#include "hash.h"
#include "malloc.h"

/*-------------------------------------------------------------------
 * MagAtof --
 *	Magic's own atof function.
 *	Convert a string to a double floating point number.
 *
 * Results:
 *	A floating point number.
 *
 * Special Features:
 *	No error is produced if the string isn't a valid number.
 *-------------------------------------------------------------------
 */

double
MagAtof(s)
    char *s;
{
#ifdef linux
    float flt;
    if (sscanf (s, "%f", &flt) == 1) return flt;
    else return -1.0;
#else
    return atof(s);
#endif
}
