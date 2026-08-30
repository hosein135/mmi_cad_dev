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

#include "port.h"
#include "error.h"
#include "mem.h"
#include "ar.h"
#include "nl.h"
#include "pnl.h"
#include "pl_int.h"

#include "g2c.h"


extern
int
setulb_ (integer *n,
	 integer *m,
	 doublereal *x,
	 doublereal *l,
	 doublereal *u,
	 integer *nbd,
	 doublereal *f,
	 doublereal *g,
	 doublereal *factr,
	 doublereal *pgtol,
	 doublereal *wa,
	 integer *iwa,
	 char *task,
	 integer *iprint,
	 char *csave,
	 logical *lsave,
	 integer *isave,
	 doublereal *dsave,
	 ftnlen task_len,
	 ftnlen csave_len);


extern void s_copy (char *, char *, ftnlen, ftnlen);
extern int  s_cmp (char *, char *, ftnlen, ftnlen);


void
pl_lbfgs (double *min, double *x, int n, pl_obj_fun_t fg, pl_step_fun_t step)
{
  int i;
  int m = 5;

  /* Fortran parameters. */
  integer N[1] = { n };
  integer M[1] = { m };
  doublereal *X = x;
  doublereal L[n];
  doublereal U[n];
  integer NBD[n];
  doublereal F[1];
  doublereal G[n];
  doublereal FACTR[1] = { 1.0e7 };
  doublereal PGTOL[1] = { 1.0e-5 };
  doublereal WA[(2 * m + 4) * n + 12 * m * (m + 1)];
  integer IWA[3*n];
  char TASK[60];
  integer IPRINT[1] = { -1 };
  char CSAVE[60];
  logical LSAVE[4];
  integer ISAVE[44];
  doublereal DSAVE[29];

  /* Unconstrained optimization. */
  for ( i = 0; i < n; i++ ) {
    NBD[i] = 0;
  }

  s_copy (TASK, "START", (ftnlen)60, (ftnlen)5);

  do {
    setulb_ (N, M, X, L, U, NBD, F, G, FACTR, PGTOL, WA, IWA, TASK, IPRINT,
	     CSAVE, LSAVE, ISAVE, DSAVE, (ftnlen)60, (ftnlen)60);

    if ( s_cmp (TASK, "FG", (ftnlen)2, (ftnlen)2) == 0 ) {
      F[0] = fg (X, G);
    }
    else if ( s_cmp (TASK, "NEW_X", (ftnlen)5, (ftnlen)5) == 0 ) {
      int cont = step (X, G);

      if ( !cont )
	break;
    }
    else {
      break;
    }
  } while (1);

  *min = F[0];
}
