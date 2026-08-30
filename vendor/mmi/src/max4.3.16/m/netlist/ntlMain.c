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
 * ntlMain.c -- netlisting
 *
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
static char rcsid[] = "$Header: ntlMain.c,v 6.0 90/08/28 18:15:25 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include <string.h>
#include "magic.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "memory.h"
#include "message.h"
#include "debug.h"
#include "netlistInt.h"
#include "netlist.h"
#include "signals.h"
#include "main.h"
#include "utils.h"
#include "stack.h"
#include "styles.h"

/* layer connectivity table */
TileTypeBitMask *ntlConnectTbl = DBConnectTbl;

FILE *outFile;

CellDef * ntlCurDef = NULL;
int ntlOutputAsComment;
int ntlNumFatal = 0; 
int ntlNumWarnings = 0;

/* technology initialized? */
int	ntlTechDone = FALSE;

/* Stack of defs contained in rootdef */
Stack *ntlDefStack;

/*** SWITCHS (ALL SWITCHS ARE LINKED TO TCL VARIABLES) ***/

/* output .globals */
bool ntlUseGlobals = TRUE;

/* if set output topleve as subckt */
bool ntlOutputToplevelAsSubckt = FALSE;

/* if set don't generate implicit ports */
bool ntlNoImplicitPorts = FALSE;

bool ntlVerbose = FALSE;

/* warn on bad devices (tcl linked var) */
bool ntlReportBadDevices = TRUE;

/* warn on split nets (tcl linked var) */
bool ntlReportSplitNets = TRUE;

int ntlUnconnectCount;



/*
 * ----------------------------------------------------------------------------
 *
 * ntlMnResetClients --
 *
 * Given a CellDef whose tiles and polygons have been set to point to Regions
 * by ntlFindNodes, reset all the client fields to uninitialized.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	All the non-space tiles and all polygons in the CellDef have
 *	their ti_client fields set back to MINFINITY
 *
 *	Does not free the NodeRecord structs that these tiles point to;
 *	that must be done by ntlFreeNodeRegs, or ntlFreeNodeRegs_and_Labels.
 *
 * Non-interruptible.
 *
 * ----------------------------------------------------------------------------
 */

static void
ntlMnResetClients(register CellDef *def)
{
  /* paint planes */
  {
    int pNum;
    for (pNum = PL_TECHDEPBASE; pNum < DBNumPlanes; pNum++)
    {
      DBPlaneResetClients(def->cd_planes[pNum], MINFINITY);
    }
  }

  /* polygons */
  {
    Polygon * poly;

    for(poly = def->cd_polygons; 
	poly != (Polygon *) NULL; 
	poly = poly->poly_next)
    {
      poly->poly_client = (ClientData) -1;
    }
  }
}

/*
 * ----------------------------------------------------------------------------
 *
 * ntlCleanupDef --
 *
 * ----------------------------------------------------------------------------
 */
static int
ntlCleanupDef(CellDef * def)
{
    Port * port;
    NodeRecord ** nodePtr;

/* MsgInfoF("CleanupDef, celldef = %s\n", def->cd_name); */

    /* free the labels created for netlisting */
    fprintf(stderr,"TODO ntlCleanupDef, free labels?\n");

    /* free the node records */
    ntlFreeNodeRecs(def);

    /* return tile and polygon client fields to intial value */
    ntlMnResetClients(def);

    /*  free connections in subcells in this def */
    /* this could be done instead in OutputDef */
    (void) DBEnumChildren(def, ntlFreePortConsFn, (ClientData) NULL);

    /* free the ports */
    for(port = (Port *) def->cd_portList; port; port = port->po_next)
	FREE(port);

    def->cd_portList = (ClientData *) NULL;

    def->cd_portCount = 0;
    def->cd_nodeCount = 0;
    def->cd_flags &= ~(CD_ALLFEEDTHRUS | CD_NOFEEDTHRUS);

    /* restore the celldefs client field */
    def->cd_client = (ClientData) NULL;

    return (0);
}


/*
 * ----------------------------------------------------------------------------
 *
 * ntlDefInitFunc --
 *
 * Function to initialize the client data field of all
 * cell defs, in preparation for extracting a subtree
 * rooted at a particular def.
 *
 * ----------------------------------------------------------------------------
 */

static int
ntlDefInitFunc(CellDef *def)
{
    def->cd_client = (ClientData) 0;
    return (0);
}


/*
 * ----------------------------------------------------------------------------
 *
 * ntlFilterDefs --
 *
 * Function to push each cell def on ntlDefStack
 * if it hasn't already been pushed, and then recurse
 * on all that def's children.
 * push onto stack from bottom to top of hierarchy
 *
 * ----------------------------------------------------------------------------
 */
    
static int
ntlFilterDefs(CellUse *use)
{
  /* forward declaration */
  static int ntlPushDefs(CellDef *def);

  CellDef *def = use->cu_def;

  /* process celldefs that have NETLIST_WITH_PARENT set */
  if (def->cd_client || (def->cd_flags & CD_INTERNAL) ) return (0);

  ntlPushDefs(def); /* call recursion function */
  return (0);
}

/*
 * ----------------------------------------------------------------------------
 *
 * ntlPushDefs --
 *
 * ----------------------------------------------------------------------------
 */

static int
ntlPushDefs(CellDef *def)
{
   (void) DBEnumChildren(def, ntlFilterDefs, (ClientData) NULL);
    /* reached bottom of hierarchy */

    /*
    MsgInfoF("pushing  celldef:  client = %x, flags = %x celldef %s\n",
	def->cd_client, def->cd_flags, def->cd_name);
    */

    /* mark already on stack */
    def->cd_client = (ClientData) 1;
    StackPush((ClientData) def, ntlDefStack);

    return (0);
}

/*
 * ----------------------------------------------------------------------------
 *
 * ntlProcessNodes --
 *
 * ----------------------------------------------------------------------------
 */

static int 
ntlProcessNodes(CellDef * def, int i, ClientData none)
{
  /* DEBUG
   * fprintf(stder,,"DEBUG, ProcessNodes() TOP, def=%s\n", 
   def->cd_name); 
  */

  /* generate list of transistor gate regions */
  def->cd_trans = (ClientData *) ntlTransFind(def);

  /*
   * TODO: set NTL_WITH_PARENTS if there are no devices
   * and don't process further in this pass?
   */

  /*
   * necessary because the tiles in transistor regions have been 
   * changed by ntlFindRegions above
   */
  ntlMnResetClients(def);

    /*
     * TODO: copy all subcells that have NTL_WITH_PARENTS flag set
     * into this def before tracing nodes 
     */
    /*
     * create nodes, and mark all paint (except gate layers) 
     * with pointer to its node
     */
    if (!SigInterruptPending)
	def->cd_nodes = (ClientData *) ntlFindNodes(def);

    /*
     * Assign the labels to their associated Node Records
     */
    if (!SigInterruptPending) ntlLabelNodes(def);


    /*
     * Make sure all geometry with the same label is part of the
     * same electrical node
     */
    if (!SigInterruptPending && ntlReportSplitNets)
    {
      ntlFindDuplicateLabels(def, 
			     (NodeRecord *) def->cd_nodes);
    }

    /*
     * fill out node number field in all node records, 
     * and port numbers in port list
     */
    ntlNumberNodes(def);

    return(0);
}


/*
 * ----------------------------------------------------------------------------
 *
 * ntlProcessHier --
 *
 * make hierarchical connections in instances
 * 1) paint to subcell instance
 * 2) subcell instance overlap
 * 3) array element to element, within instance
 *
 * each celluse contains array of pointers to port connections, 
 * one pointer per array element
 * the pointer is only used, and storage allocated for a set of port 
 * connections,
 * if there is a connection discovered in case 1 or 2
 * case 3 connections are handled separately, on an iterative basis
 * in case 2 (or 3), a new node is needed in parent to connect between 
 * the subcells,
 * unless one or both ports was already connected in 1)
 *
 * ----------------------------------------------------------------------------
 */
static int
ntlProcessHier(CellDef * def, int i, ClientData none)
{

 /*
 MsgInfoF("*****\n ProcessHier of celldef %s\n\n", def->cd_name);
  */

    ntlCurDef = def;

    /* first allocate storage in cell use for pointers to connections */
    /* (don't need this if there are no ports)*/
    /* but if that is the case, the cell must not be connected to anything */
    (void) DBEnumChildren(def, ntlAllocPortConsFn, (ClientData) NULL);

    /* then call hier Instances */
    ntlHierInstances(def);

    return(0);
}


/*
 * ----------------------------------------------------------------------------
 *
 * ntlOutputDef --
 *
 * ----------------------------------------------------------------------------
 */
static int
ntlOutputDef(CellDef * def, int i, ClientData rootDef)
{

    /*
     * merge nodes, visit all instances
     */
    (void) DBEnumChildren(def, ntlMergeDefNodesFn, (ClientData) def);

    /* mark feedthru ports */
    ntlMarkFTPorts (def);

    /* ignore cd if there is only all port all feedthrus*/
    if( (  def->cd_flags & (CD_ALLFEEDTHRUS | CD_NETLIST_WITH_PARENT))
	|| (def->cd_portCount < 2) && (rootDef != def)
	|| (def->cd_trans == NULL)	/* new for 121101 */
	)
    {
	    MsgInfoF("WARNING: celldef %s will not be output\n", def->cd_name);
	return(0);
    }
    /*
     * print port declarations (SBCKT line)
     * if processing top level, output ports as comments (final param)
     */
    ntlOutputAsComment = (((CellDef *) rootDef == def) && 
			  !ntlOutputToplevelAsSubckt);

    ntlOutputSbcktDecl(
	def, 
	outFile);

    /*
     * print Node numbers and names as SPICE comments 
     */
    if (!SigInterruptPending)
	ntlOutputNodes(def, outFile);

    /*
     * Transistors: finally process gate layers
     */

/* Output transistors and connectivity between nodes */
    /* HIDE
    if (!SigInterruptPending) ntlOutputTrans(def, outFile);
    */
    fprintf(stderr,"ntlMain.c,  TODO:  ntlOutputTrans\n");

    /*
     * output subcell instances and their port connections 
     * ( as X lines )
     * print all instances in this celldef, except
     * ntlOutputInstanceFn will ignore the instance if
     * the EXT_W_PARENT flag is set in the instance's celldef
     */
    ntlUnconnectCount = 0;
    (void) DBEnumChildren(def, ntlOutputInstancesFn, (ClientData) outFile);

    /*
     * Free the memory used to store port connections in each subcell in this def
     */
    /* ntlFreePortCons(def); */

    if(ntlOutputAsComment)
	fprintf(outFile, "* .ENDS\n");
    else
	fprintf(outFile, ".ENDS\n");
    return(0);
}

/*
 * ----------------------------------------------------------------------------
 *
 * ntlMnNetlist --
 *
 * Netlist the subtree rooted at rootUse.
 *
 * Results:
 *      None.
 *
 * Side effects:
 *      Creates  <topdef>.ntl in the current directory and writes to it.
 *      Adds feedback information where errors have occurred.
 *      Generates info warning and error messages as appropriate.
 *
 * ----------------------------------------------------------------------------
 */

void ntlMnNetlist(CellUse * rootUse, 
		  char * outFileName)
{
  NodeRecord * nodeList;
  char * filename;

/* DEBUG
   fprintf(stderr,"DEBUG ntlMnNetlist, top def=%s outName=%s\n",
           rootUse->cu_def->cd_name,
	   outName);
*/

  /* open output file */
  outFile = DBCellFileOpen(rootUse->cu_def, 
			   outFileName, 
			   ".ntl", 
			   "w", 
			   &filename);
  if (outFile == NULL)
  {
    MsgErrorF("Cannot open output file");
    perror(filename);
    return;
  }

    fprintf(outFile, "* SPICE netlist for cell %s created by MAX version %s\n", 
				rootUse->cu_def->cd_name, MaxVersion);

    MsgInfoF("Netlisting %s into %s:\n", rootUse->cu_def->cd_name, filename);

    MsgInfoF("ntlUseGlobals = %s\n", 
	     (ntlUseGlobals) ? "TRUE" : "FALSE");

    MsgInfoF("ntlOutputToplevelAsSubckt = %s\n", 
	     (ntlOutputToplevelAsSubckt) ? "TRUE" : "FALSE");

    MsgInfoF("ntlVerbose = %s\n", 
	     (ntlVerbose) ? "TRUE" : "FALSE");

    /*
     * Make sure the entire subtree is read in, and instance bounding boxes
     * are up-to-date
     */
    DBReadCellTree(rootUse->cu_def);
    DBUpdate(rootUse->cu_def);

    /*
     * find all the celldefs used by the top level cell
     * and put each unique celldef on the stack
     */
    /* Mark all defs as being unvisited
     * Oct 22 should not be neceessary, as all users of client field 
     * must return it to NULL 
     */
    (void) DBCellSrDefs(0, ntlDefInitFunc, (ClientData) 0);

    /* Recursively visit all defs in the tree and push on stack */
    ntlDefStack = StackNew(100);
    (void) ntlPushDefs(rootUse->cu_def);

/* first pass of all celldefs in rootUse*/
     StackEnum(ntlDefStack, ntlProcessNodes, (ClientData)NULL);

/* second pass of all celldefs in rootUse
 * could be combined with pass 2, if 2-3 are bottom-up
 */
     StackEnum(ntlDefStack, ntlProcessHier, (ClientData)NULL);

/* third pass of all celldefs */
    StackEnum(ntlDefStack, ntlOutputDef, (ClientData)rootUse->cu_def);

    /*
     * after all celldefs have been output, 
     * print globals for all celldefs in design
     * (if using globals)
     * print each unique name (across the entire design) only once
     */
    if (ntlUseGlobals) ntlOutputGlobals(ntlDefStack, outFile);

    fprintf(outFile, ".END\n");

    /*
     * CLEANUP: free node records, and label list (NOT LABELS)
     */
    StackEnum(ntlDefStack, ntlCleanupDef, (ClientData)NULL);

    /* there is only one file open */
    fclose (outFile);

    /* free celldef stack */
    StackFree(ntlDefStack);
}

/*
 * --------------------------------------------------------------------------
 *
 * NtlInit --
 *
 * Called once at Max startup to initialize netlister module
 *
 * --------------------------------------------------------------------------
 */
void
NtlInit(void)
{
  ntlTransInit();
}
