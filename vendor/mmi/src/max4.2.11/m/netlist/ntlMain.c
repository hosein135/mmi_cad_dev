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
#include "malloc.h"
#include "message.h"
#include "debug.h"
#include "netlistInt.h"
#include "netlist.h"
#include "signals.h"
#include "main.h"
#include "utils.h"
#include "stack.h"
#include "styles.h"

/* ------------------------ Exported variables ------------------------ */

    /*
     * See extract.h for the bit flags that may be set in the following.
     * If any are set, the corresponding warnings get generated, leaving
     * feedback messages.  If this word is zero, only fatal errors are
     * reported.
     */
int NtlDoWarn = NTLWARN_DUP|NTLWARN_FETS;
int NtlOptions = NTL_DOALL;

/* --------------------------- Global data ---------------------------- */

  /* Identifier returned by the debug module for circuit extraction */
ClientData ntlDebugID;

      /* Number of errors encountered during extraction */
int ntlNumFatal;
int ntlNumWarnings;

CellDef * ntlCurDef;


/* ------------------------ Data local to this file ------------------- */

ClientData ntlUnInit = (ClientData) MINFINITY;

FILE *outFile;

int	ntlTechDone = FALSE;

    /* Stack of defs contained in rootdef */
Stack *ntlDefStack;

    /* Forward declarations */
int ntlDefInitFunc(CellDef *def);

NodeRecord *ntlFindNodes(CellDef * def);

void ntlLabelNodes(CellDef * def, TileTypeBitMask * connTo);

int ntlFreeNodeRecs(CellDef * cd);
int ntlFreePortConsFn(ClientData * cd);

/*
 * (Tcl linked variable)
 * ntlUseGlobals flag 
 * is set, .global line is output
 * otherwise, globals are treated just like ports
 */
bool ntlUseGlobals = TRUE;

/* (tcl linked var) */
bool ntlCommentTopDef = FALSE;

bool ntlImplicitPorts = TRUE;

bool ntlVerbose = TRUE;

int ntlOutputAsComment;
int ntlUnconnectCount;

int ntlOutputInstancesFn(CellUse * use, ClientData f);
int ntlMergeDefNodesFn	(CellUse * use, ClientData cd);

int ntlAllocPortConsFn(CellUse * use, ClientData none);

void ntlResetClient(CellDef * def, ClientData ntlUnInit);

int ntlBorrowExtTechStyle();
void ntlShowTech(char * name);

int ntlCleanupDef(CellDef * def)
{
    Port * port;
    NodeRecord ** nodePtr;

/* MsgInfoF("CleanupDef, celldef = %s\n", def->cd_name); */

    /* free the labels created for netlisting */

    /* free the node records */
    ntlFreeNodeRecs(def);

    ntlResetClient(def, ntlUnInit);

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
 * ntlFileOpen --
 *
 *	Open the .ntl file corresponding to a .mag file.
 *	If def->cd_file is non-NULL, the .ntl file is just def->cd_file with
 *	the trailing .mag replaced by .ntl.  Otherwise, the .ntl file is just
 *	def->cd_name followed by .ntl.
 *
 * Results:
 *	Return a pointer to an open FILE, or NULL if the .ntl
 *	file could not be opened in the specified mode.
 *
 * Side effects:
 *	Opens a file.
 *
 * ----------------------------------------------------------------------------
 */

FILE *
ntlFileOpen(CellDef *def, char *file, char *mode, char **prealfile)
                 	/* Cell whose .ntl file is to be written */
               		/* If non-NULL, open 'name'.ntl; otherwise,
			 * derive filename from 'def' as described
			 * above.
			 */
               		/* Either "r" or "w", the mode in which the .ntl
			 * file is to be opened.
			 */
                     	/* If this is non-NULL, it gets set to point to
			 * a string holding the name of the .ntl file.
			 */
{
    char namebuf[512], *name, *endp;
    unsigned len;

    if (file) name = file;
    else if (def->cd_file)
    {
	name = def->cd_file;
	if (endp = rindex(def->cd_file, '.'))
	{
	    name = namebuf;
	    len = endp - def->cd_file;
	    if (len > sizeof namebuf - 1) len = sizeof namebuf - 1;
	    (void) strncpy(namebuf, def->cd_file, len);
	    namebuf[len] = '\0';
	}
    }
    else name = def->cd_name;

    return (PaOpen(name, mode, ".ntl", MnPathCell, NULL, prealfile));
}

/*
 * Function to initialize the client data field of all
 * cell defs, in preparation for extracting a subtree
 * rooted at a particular def.
 */
int
ntlDefInitFunc(CellDef *def)
{
    def->cd_client = (ClientData) 0;
    return (0);
}


/*
 * Function to push each cell def on ntlDefStack
 * if it hasn't already been pushed, and then recurse
 * on all that def's children.
 * push onto stack from bottom to top of hierarchy
 */
    
int
ntlFilterDefs(CellUse *use)
{
    CellDef * def = use->cu_def;
    /* process celldefs that have NETLIST_WITH_PARENT set */
    if (def->cd_client || (def->cd_flags & CDINTERNAL) )
        return (0);
    ntlPushDefs(def);	/* call recursion function */
    return (0);
}

int
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

int ntlProcessNodes(CellDef * def, int i, ClientData none)
{
    /* NTransRegion *transList; */

    ntlConnectTable = DBConnectTbl;

/*
 * MsgInfoF("ProcessNodes of celldef %s\n", def->cd_name); 
 */

    /*
     * Build up a list of the transistor regions for ntlOutputTrans()
     * below.  We're only interested in pointers from each region to
     * a tile in that region, not the back pointers from the tiles to
     * the regions.
     */
    def->cd_trans = (ClientData *) ntlFindRegions(def, &TiPlaneRect,
                                    &ntlTech_transMask,
                                    ntlTech_transConn,
                                    ntlUnInit, ntlTransFirst, ntlTransEach);
   /*
    * set NTL_WITH_PARENTS if there are no devices
    * and don't process further in this pass
    */

   /*
    * necessary because the tiles in transistor region have been 
    * changed by ntlFindRegions above
    */
    ntlResetClient(def, ntlUnInit);

    /*
     * copy all subcells that have NTL_WITH_PARENTS flag set
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
    if (!SigInterruptPending)
	ntlLabelNodes(def, ntlTech_nodeConn);

    /*
     * Make sure all geometry with the same label is part of the
     * same electrical node
     */
    if (!SigInterruptPending && (NtlDoWarn & NTLWARN_DUP))
	ntlFindDuplicateLabels(def, def->cd_nodes);

    /*
     * fill out node number field in all node records, 
     * and port numbers in port list
     */
    ntlNumberNodes(def);

    return(0);
}

int ntlProcessHier(CellDef * def, int i, ClientData none)
{
    /*
     * make hierarchical connections in instances
     * 1) paint to subcell instance
     * 2) subcell instance overlap
     * 3) array element to element, within instance
     *
     * each celluse contains array of pointers to port connections, 
     * one pointer per array element
     * the pointer is only used, and storage allocated for a set of port connections,
     * if there is a connection discovered in case 1 or 2
     * case 3 connections are handled separately, on an iterative basis
     *
     * in case 2 (or 3), a new node is needed in parent to connect between the subcells,
     * unless one or both ports was already connected in 1)
     */

 /*
 MsgInfoF("****************************\n ProcessHier of celldef %s\n\
 *********************************\n", def->cd_name);
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

int ntlOutputDef(CellDef * def, int i, ClientData rootDef)
{

    /*
     * merge nodes, visit all instances
     */
    (void) DBEnumChildren(def, ntlMergeDefNodesFn, (ClientData) def);

    /* mark feedthru ports */
    ntlMarkFTPorts (def);

    /* ignore cd if there is only all port all feedthrus*/
    if( (  def->cd_flags & (CD_ALLFEEDTHRUS | CD_NETLIST_WITH_PARENT))
	|| (def->cd_portCount < 2) && (rootDef != def))
    {
	    MsgInfoF("WARNING: celldef %s will not be output\n", def->cd_name);
	return(0);
    }
    /*
     * print port declarations (SBCKT line)
     * if processing top level, output ports as comments (final param)
     */
    ntlOutputAsComment = (((CellDef *) rootDef == def) && ntlCommentTopDef);

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
    if (!SigInterruptPending)
        ntlOutputTrans(def, outFile);

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
 * ntlAll --
 *
 * netlist the subtree rooted at the CellDef 'rootUse->cu_def'.
 * all cells are extracted to a file in the current directory
 * whose name consists of the last part of the rootUse's path,
 * with a .ntl suffix.
 *
 * Results:
 *      None.
 *
 * Side effects:
 *      Creates  one .ntl files and writes to it.
 *      Adds feedback information where errors have occurred.
 *
 * ----------------------------------------------------------------------------
 */

void ntlAll(CellUse * rootUse, char * outName)
{
    NodeRecord * nodeList;
    char * filename;

    /*MsgInfoF("ntlAll called\n"); */

    /* HACK until tech is set by Tcl */
    if(FALSE == ntlTechDone)
    {
	if(FALSE == (ntlTechDone = ntlBorrowExtTechStyle()))
	{
	    MsgErrorF("Extraction technology must be defined before netlisting\n");
	    return;
	    /* can't continue with netlisting*/
	}
    }

    /*
     * print the technology info into a file
    ntlShowTech("ntl_tech.out");
     */

    /*
     * open output file
     */
    outFile = ntlFileOpen(rootUse->cu_def, outName, "w", &filename);
    fprintf(outFile, "* SPICE netlist for cell %s created by MAX version %s\n", 
				rootUse->cu_def->cd_name, MaxVersion);

    MsgInfoF("Netlisting %s into %s:\n", rootUse->cu_def->cd_name, filename);
    MsgInfoF("ntlUseGlobals = %s\n", (ntlUseGlobals == TRUE)? "TRUE" : "FALSE");
    MsgInfoF("ntlCommentTopDef = %s\n", (ntlCommentTopDef == TRUE)? "TRUE" : "FALSE");
    MsgInfoF("ntlVerbose = %s\n", (ntlVerbose == TRUE)? "TRUE" : "FALSE");

    if (outFile == NULL)
    {
        MsgErrorF("Cannot open output file: ");
        perror(filename);
        return;
    }

    /*
     * Make sure the entire subtree is read in, and instance bounding boxes
     * are up-to-date
     */
    DBCellReadTree(rootUse->cu_def);
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
    if (!SigInterruptPending & ntlUseGlobals)
	ntlOutputGlobals(rootUse->cu_def, outFile);

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

