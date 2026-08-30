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
 * mnTic.c --
 *
 * Handles "periodic" services during long computations.
 *
 * NOTE: this is not asynchronous, e.g., not separate thread or
 * interrupt handler.  Instead the MnTic() macro is called from
 * database operations etc., to check the passage of time.
 * If enough time has gone by (MN_TIC_SECS) MnTic() calls MnTicService()
 * before returning.
 *
 */

#include "magic.h"
#include "graphics.h"
#include "main.h"
#include "mainInt.h"

time_t MnLastTic = 0;
int MnTicCount = 0;


/*
 *----------------------------------------------------------------------
 *
 * MnTicService(void)
 *
 *	Called at intervals (from MnTic) to perform periodically
 *	required operations (such as reading from the X event socket
 *      so the socket doesn't time out).
 *
 *----------------------------------------------------------------------
 */

void MnTicService(void)
{
  int pending;
 
  /* note pending return value works correctly when 
   *    "after 5000; mn_tic 5000"
   * typed into max startup window, but not when this is put in a
   * proc?
   */
  pending = GrTicService();

/*  fprintf(stderr,"DEBUG MnTicService, pending=%d\n", pending); */
}  

  







