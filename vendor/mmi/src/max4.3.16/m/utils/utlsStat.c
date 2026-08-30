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
 * utlsStat.c -
 *
 * run time statistics.
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

static char rcsid[] = "$Header:$";

#include <sys/types.h>
#include <sys/times.h>
#include <time.h>
#include <stdio.h>
#include "magic.h"
#include "utils.h"

/* Library imports: */
extern char *sbrk(int);
extern end;                

/* base for elapsed time computations 
 * (time since system booted on my Linux system) 
 */
double UtlsTimeInitial = 0;


/*
 * ----------------------------------------------------------------------------
 *
 * UtlsStatHeapSize --
 *
 * returns memory.heap size (in bytes)
 *
 * ----------------------------------------------------------------------------
 */
unsigned long
UtlsStatHeapSize(void)
{
  return (unsigned long) sbrk(0) - (unsigned long) &end;
}


/*
 * ----------------------------------------------------------------------------
 *
 * utlsStatProcessTimes --
 *
 * returns user time, system time, and elapsed real time for process
 * (all times in seconds).
 *
 * ----------------------------------------------------------------------------
 */
void 
UtlsStatProcessTimes(double *userp, double *sysp, double *realp) 
{
  struct tms buf;
  clock_t real;
 
  real = times(&buf);

  if(userp) *userp = buf.tms_utime / (double) CLK_TCK;
  if(sysp) *sysp = buf.tms_stime / (double) CLK_TCK;
  if(realp) *realp = (real / (double) CLK_TCK) - UtlsTimeInitial;
}


/*
 * ----------------------------------------------------------------------------
 *
 * UtlsStatInit --
 *
 * Called from mnMain.c at start up time (the sooner the better!)
 *
 * ----------------------------------------------------------------------------
 */
void 
UtlsStatInit(void)
{
  /* use current time as base for elapsed time computations */
  UtlsTimeInitial = 0.0;
  UtlsStatProcessTimes(NULL,NULL,&UtlsTimeInitial);
}




