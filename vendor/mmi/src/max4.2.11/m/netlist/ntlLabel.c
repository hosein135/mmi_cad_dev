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
 * ntlLabel.c --
 *
 * Label related functions for netlisting
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
static char rcsid[] = "$Header: ntlLabel.c,v 6.0 90/08/28 18:15:25 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include "magic.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "malloc.h"
#include "message.h"
#include "debug.h"
#include "signals.h"
#include "styles.h"
#include "netlistInt.h"


/*
 * ----------------------------------------------------------------------------
 *
 * ntlLabelNodes --
 *
 * Given a CellDef whose tiles have been set to point to NodeRecords
 * walk down the label list and assign labels
 * to Nodes.  If the tile over which a label lies is still uninitialized
 * ie, points to ntlUnInit, we skip the label.
 *
 * A label is attached to the NodeRecords pointed to by a tile 
 * if the label's type and the tile's type are connected according 
 * to the table 'connTo'.  This disambiguates the case where a label lies
 * on the boundary between two tiles of different types.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Each NodeRecord has labels added to its label list.
 *	Also, nrec_type is filled in, based on the "kind" of attached labels
 *
 *
 * ----------------------------------------------------------------------------
 */

void 
ntlLabelNodes(register CellDef *def, register TileTypeBitMask *connTo)
                          		/* Cell definition being labelled */
                                     	/* Connectivity table (see above) */
{
    static Point offsets[] = { { 0, 0 }, { 0, -1 }, { -1, -1 }, { -1, 0 } };
    register NLabelList *ll;
    register Label *lab;
    register Tile *tp;
    NodeRecord *node;
    int quad, pNum;
    Point p;
    Polygon * poly;
    Port * port;

    for (lab = def->cd_labels; lab; lab = lab->lab_next)
    {
	pNum = DBPlane(lab->lab_type);
/* MsgInfoF( "ntlLable nodes: labels kind = %x, text = %s\n", lab->lab_kind, lab->lab_text); */
	if (lab->lab_type == TT_SPACE || pNum < PL_TECHDEPBASE)
	    continue;
	for (quad = 0; quad < 4; quad++)
	{
	    /*
	     * Visit each of the four quadrants surrounding
	     * the lower-left corner of the label, searching
	     * for a tile whose type matches that of the label
	     * or connects to it.
	     */
	    p.p_x = lab->lab_rect.r_xbot + offsets[quad].p_x;
	    p.p_y = lab->lab_rect.r_ybot + offsets[quad].p_y;
	    tp = def->cd_planes[pNum]->pl_hint;
	    GOTOPOINT(tp, &p);
	    def->cd_planes[pNum]->pl_hint = tp;
	    if (ntlConnectsTo(DBgetTileType(tp), lab->lab_type, connTo)
		    && ntlHasRegion(tp, ntlUnInit))
	    {
		/* attach label to front of list rooted in node
		 * Michael, here, should put port labels in list regardless,
		 * otherwise only keep one non-port label that has 
		 * the "best" name (not yet done)
		 */
		node = (NodeRecord *) ntlGetRegion(tp);

		MALLOC(NLabelList *, ll, sizeof (NLabelList));
		ll->ll_label = lab;
		ll->ll_next = node->nrec_labels;
		ll->ll_uniq = 0;
		ll->ll_flag = FALSE;
		node->nrec_labels = ll;

		/* store type of node in nrec_type
		 * based on attached labels
		 * a single global label promotes the entire node
		 */
		if(lab->lab_kind == LAB_GLOBAL)
		   node->nrec_type  = LAB_GLOBAL;
		else if((lab->lab_kind == LAB_INPUT)
		     || (lab->lab_kind == LAB_OUTPUT)
		     || (lab->lab_kind == LAB_INOUT)
		     && (node->nrec_type != LAB_GLOBAL)
		     )
		   node->nrec_type = lab->lab_kind;

		/* step 2, if label is port type, create port
		 * unless type is global and using implicit globals
		 */
		if(  (lab->lab_kind == LAB_INPUT)
		  || (lab->lab_kind == LAB_OUTPUT)
		  || (lab->lab_kind == LAB_INOUT)
		  || (node->nrec_type == LAB_GLOBAL) & !ntlUseGlobals)
		{
		    MALLOC(Port *, port, sizeof(Port));
		    /* store pointer back to port's node, 
		       to access port's name for output */
		    port->po_node = node;
		    port->po_nextFt = NULL;
		    port->po_flags = 0;

		    /* attach to head of port list rooted in celldef */
		    port->po_next = (Port * ) def->cd_portList;
		    def->cd_portList = (ClientData *) port;
		}
		else port = (Port *) NULL;	/* not port */

		/* store pointer to port in label list, 
		 * to find port when label is found to be connected
		 */
		ll->ll_port = port;

		break;			/* connect only once */
	    }
	}
	if(quad != 4) continue;		/* found label on a tile */

	/* wasn't connected to any tiles, try polygons
	 * enormously ineffcient !!
	 * intersects labels rectangle with polygon
	 * NOTE: does not grow label's bbox, should it ?
	 */
	for(poly = def->cd_polygons; poly != (Polygon *) NULL; 
		poly = poly->poly_next)
	    if( ntlConnectsTo(poly->poly_type, lab->lab_type, connTo)
		&& poly->poly_client != ntlUnInit
		&& DBPolygonIntersectRectQ(poly, &lab->lab_rect))
	    {
		/* attach label to front of list rooted in node */
		node = (NodeRecord *) poly->poly_client;
		MALLOC(NLabelList *, ll, sizeof (NLabelList));
		ll->ll_label = lab;
		ll->ll_next = node->nrec_labels;
		ll->ll_uniq = 0;
		node->nrec_labels = ll;

		/* store type of node in nrec_type
		 * based on attached labels
		 * a single global label promotes the entire node
		 */
		if(lab->lab_kind == LAB_GLOBAL)
		   node->nrec_type  = LAB_GLOBAL;
		else if((lab->lab_kind == LAB_INPUT)
		     || (lab->lab_kind == LAB_OUTPUT)
		     || (lab->lab_kind == LAB_INOUT)
		     && (node->nrec_type != LAB_GLOBAL)
		     )
		   node->nrec_type = lab->lab_kind;

		/* step 2, if label is port type, create port
		 * unless type is global and using implicit globals
		 */
		if(  (lab->lab_kind == LAB_INPUT)
		  || (lab->lab_kind == LAB_OUTPUT)
		  || (lab->lab_kind == LAB_INOUT)
		  || (node->nrec_type == LAB_GLOBAL) & !ntlUseGlobals)
		{
		    MALLOC(Port *, port, sizeof(Port));
		    /* store pointer to port's node, to get port's name for output */
		    port->po_node = node;
		    port->po_nextFt = NULL;
		    port->po_flags = 0;

		    /* attach to head of port list rooted in celldef */
		    port->po_next = (Port * ) def->cd_portList;
		    def->cd_portList = (ClientData *) port;
		}

		/* store pointer to port in label list, 
		 * to find port when label is found to be connected
		 */
		ll->ll_port = port;

		break;			/* connect only once */
	    }
    }
}



/*
 * ----------------------------------------------------------------------------
 *
 * ntlFindDuplicateLabels --
 *
 * Verify that no node in the list 'node' has a label that appears in
 * any other node in the list.  Leave a warning turd if one is.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Leaves feedback attached to each node that contains a label
 *	duplicated in another node.
 *	puts unique number >0 in label list for duplicates
 *
 * ----------------------------------------------------------------------------
 */

void
ntlFindDuplicateLabels(CellDef *def, NodeRecord *nodeList)
{
    static char *badmesg =
	"Label \"%s\" attached to more than one unconnected node: %s";
    bool hashInitialized = FALSE;
    char message[512], name[512], *text;
    register NodeRecord *np, *np2;
    register NLabelList *ll, *ll2;
    register HashEntry *he;
    NodeRecord *lastnode;
    NodeRecord badLabel;
    HashTable labelHash;
    Rect r;
    int  uniq;

    for (np = nodeList; np; np = np->nrec_next)
    {
	for (ll = np->nrec_labels; ll; ll = ll->ll_next)
	{
	    text = ll->ll_label->lab_text;

	    if (!hashInitialized)
		HashInit(&labelHash, 32, 0), hashInitialized = TRUE;
	    he = HashFind(&labelHash, text);
	    lastnode = (NodeRecord *) HashGetValue(he);
	    if (lastnode == (NodeRecord *) NULL)
		HashSetValue(he, (ClientData) np);
	    else if (lastnode != np && lastnode != &badLabel)
	    {
		/*
		 * Make a pass through all labels for all nodes.
		 * Leave a feedback turd over each instance of the
		 * offending label.
		 */
		uniq = 1;
		for (np2 = nodeList; np2; np2 = np2->nrec_next)
		{
		    for (ll2 = np2->nrec_labels; ll2; ll2 = ll2->ll_next)
		    {
			if (strcmp(ll2->ll_label->lab_text, text) == 0)
			{
			    /* possibly skip globals */
			    if(ntlUseGlobals)
			    {
			        if(ll->ll_label->lab_kind == LAB_GLOBAL &&
				   ll2->ll_label->lab_kind == LAB_GLOBAL) 
				  continue;
			    }

			    ntlNumWarnings++;
			    MsgInfoF( "Duplicate label\n");
			/*
			 * uniquify the labels by
			 * placing a number > 1 in each label occurrence
			 * put in label list struct, 
			 * so don't need storage in actual label 
			 * (stored in celldef)
			 */
			    ll2->ll_uniq = uniq++;
			    /*
			    if (!DebugIsSet(ntlDebugID, ntlDebNoFeedback))
			    {
				r.r_ll = r.r_ur = ll2->ll_label->lab_rect.r_ll;
				r.r_xbot--, r.r_ybot--, r.r_xtop++, r.r_ytop++;
				ntlMakeNodeNumPrint(name,
					    np2->nrec_pnum, np2->nrec_ll);
				(void) sprintf(message, badmesg, text, name);
				LayFeedbackAdd(&r, message, def,
					    1, STYLE_PALEHIGHLIGHTS);
			    }
			    */
			}
		    }
		}

		/* Mark this label as already having generated an error */
		HashSetValue(he, (ClientData) &badLabel);
	    }
	}
    }

    if (hashInitialized)
	HashKill(&labelHash);
}


/*
 * ----------------------------------------------------------------------------
 *
 * ntlResetClient --
 *
 * Given a CellDef whose tiles and polygons have been set to point to Regions
 * by ntlFindNodes, reset all the client fields to uninitialized.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	All the non-space tiles and all polygons in the CellDef have
 *	their ti_client fields set back to uninitialized.  
 *	Does not free the NodeRecord structs that these tiles point to;
 *	that must be done by ntlFreeNodeRegs, or ntlFreeNodeRegs_and_Labels.
 *
 * Non-interruptible.
 *
 * ----------------------------------------------------------------------------
 */

void
ntlResetClient(register CellDef *def, ClientData resetTo)
                          
                       		/* New value for all ti_client fileds*/
{
    register int pNum;
    Polygon * poly;

    for (pNum = PL_TECHDEPBASE; pNum < DBNumPlanes; pNum++)
	DBPlaneResetClients(def->cd_planes[pNum], resetTo);

    for(poly = def->cd_polygons; poly != (Polygon *) NULL; 
	    poly = poly->poly_next)
	poly->poly_client = resetTo;
}

/*
 * ----------------------------------------------------------------------------
 *
 * ntlFreeNodeRegs --
 * ntlFreeNodesRegs_and_Labels --
 *
 * ntlFreeNodeRegs also frees the NLabelLists pointed to by nrec_labels.
 * ntlFreeNodeRegs_and_Labels, in addition to freeing the NLabelLists, frees
 * the labels they point to.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Frees memory.
 *
 * Non-interruptible.
 *
 * ----------------------------------------------------------------------------
 */

/* called by EnumStack */
void
ntlFreeNodeRecs(CellDef  *def, int i, ClientData cd ) 
{
    register NodeRecord *node;
    register NLabelList *ll;
    NodeRecord * nodeList = (NodeRecord *) def->cd_nodes;

    for (node = nodeList; node; node = node->nrec_next)
    {
	for (ll = node->nrec_labels; ll; ll = ll->ll_next)
	{
	    /* Erase the actual label, if it was added by netlister */
	    if(ll->ll_flag == TRUE)
		DBLabelErase(def, ll->ll_label);
	    
	    FREE((char *) ll);
	}
	FREE((char *) node);
    }
    def->cd_nodes = NULL;
}

void
ntlFreeNodesRegs_and_Labels(NodeRecord *nodeList) 
{
    register NodeRecord *node;
    register NLabelList *ll;

    for (node = nodeList; node; node = node->nrec_next)
    {
	for (ll = node->nrec_labels; ll; ll = ll->ll_next)
	{
	    FREE((char *) ll->ll_label);
	    FREE((char *) ll);
	}
	/* if(nrec->nrec_type & NTL_OWN_ALIAS) FREE (nrec->alias) */
	FREE((char *) node);
    }
}


/*
 * number the nodes, to use when printing a name for a node 
 * that has no attached labels
 * number the ports, so the size is available to allocate a port connection list
 * number the nodes, so additional nodes can be numbered when making connections
 * of overlapped cells
 */
void 
ntlNumberNodes(CellDef * cd )
{
    NodeRecord * node;
    Port * port;
    int i, nodeCount, portCount;; 

    /* number nodes */
    i = 0;
    for (node = (NodeRecord *) cd->cd_nodes; node; node = node->nrec_next)
	node->nrec_nodenum = i++;
    nodeCount = i;

    cd->cd_nodeCount = i;

    /* ports */
    i = 0;
    for (port = (Port*) cd->cd_portList; port; port = port->po_next)
    {
	port->po_portnum = i++;
    }
    /* store port count in celldef */
    cd->cd_portCount = i;
    portCount =   i;

/*
MsgInfoF("Summary of celldef %s: %d nodes, %d ports\n\n",
	    cd->cd_name,  nodeCount, portCount);
 */
}


