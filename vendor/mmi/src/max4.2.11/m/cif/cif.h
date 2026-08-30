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
 * cif.h --
 *
 * This procedure defines things that are exported by the
 * cif module to the rest of the world.
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
 *
 * rcsid "$Header: cif.h,v 6.0 90/08/28 18:05:27 mayo Exp $
 */

#define _CIF

#ifndef	_MAGIC
int err0 = Need_to_include_magic_header;
#endif	_MAGIC
#ifndef	_DATABASE
int err1 = Need_to_include_database_header;
#endif	_DATABASE

/* tcl initialization procedure */
void CifTclInit(Tcl_Interp *interp);

/* Procedures that parse the cif sections of a technology file. */
extern Void CIFTechInit(void);
extern bool CIFTechLine(char *sectionName, int argc, char **argv);
extern Void CIFTechFinal(void);
extern Void CIFReadTechInit(void);
extern bool CIFReadTechLine(char *sectionName, int argc, char **argv);
extern Void CIFReadTechFinal(void);

/* export unit sizes (from current cifoutput style */
extern double CIFDBRes; 	/* size of max database unit in microns */
extern double CIFPlaneRes;      /* size of CIF plane unit in microns 
     			         * (cif planes used for ops when generating 
				 * gds or cif and also for drc)
				 */
extern double CIFRes;           /* size of cifoutput unit in microns */
extern double CIFGDSRes;        /* size of gds output unit in microns */

/* Externally-visible procedures: */
extern void CIFSeeLayer(CellDef *rootDef, Rect *area, char *layer);
extern void CIFSeeHierLayer(CellDef *rootDef, Rect *area, char *layer, int arrays, int subcells);
extern void CIFPrintStats(void);

extern void CIFReadFile(FILE *file);

extern void CIFSetStyle(char *name);
extern void CIFSetReadStyle(char *name);
