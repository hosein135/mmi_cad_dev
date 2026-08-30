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
 * ntlHier3.c --
 *
 * functions for hierarchical netlisting
 * related to instance-to-instance interaction
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
static char rcsid[] = "$Header: ntlHier3.c,v 6.0 90/08/28 18:15:25 mayo Exp $";
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
#include "netlist.h"

extern bool ntlImplicitPorts;
/*
 * ----------------------------------------------------------------------------
 * ntlPortsConnected
 *	search the ports associated wioth node 1 and node 2, 
 * 	looking for a connection in common parent cell
 *
 * Results:
 *	1 if ports are connected by parent node, else 0
 *
 * Side effects:
 *	Allocates or enlarges port connection lists for both celluses
 *
 * ----------------------------------------------------------------------------
 */
int ntlPortsConnected(
	    NodeRecord * intNode, 
	    NodeRecord * extNode, 
	    PortConnector * conns1, 
	    PortConnector * conns2)
{
    NLabelList * lab1, * lab2;
    NodeRecord * parentNode;

    /* quit if no port connections to either instance yet */
    if( (conns1 == NULL) || (conns2  == NULL))
	return(0);

    /* for all ports connected to Node1 */
    for(lab1 = intNode->nrec_labels; lab1 ; lab1 = lab1->ll_next)
    {
	if(lab1->ll_port == NULL) continue;

	parentNode = conns1->pc_conns [lab1->ll_port->po_portnum];

	/* for all ports connected to Node2 */
	for(lab2 = extNode->nrec_labels; lab2 ; lab2 = lab2->ll_next)
	{
	    if(lab2->ll_port == NULL) continue;
	    if(parentNode == conns2->pc_conns [lab2->ll_port->po_portnum])
		return (1);
	}
    }
    return(0);
}

int ntlFindNodesPortArea(
    NLabelList * llist,
    TileType type,
    Rect *area)
{
    NLabelList * nll;
	
    for(nll = llist; nll; nll = nll->ll_next)
    {
	if(nll->ll_port != NULL
	    && nll->ll_label->lab_type == type
	    && GEO_TOUCH(area, &(nll->ll_label->lab_rect)))
	{
/* MsgInfoF("found port %d\n", nll->ll_port->po_portnum); */
	    return(nll->ll_port->po_portnum);
	}
    }
/* MsgInfoF("did not find port\n"); */
    return(-1);
}

/*
 * ----------------------------------------------------------------------------
 * ntlAddNode --
 *	allocate a new node in the celldef, 
 *	add it to the node list,
 *	with the next sequential node number
 *
 * Results:
 *	A pointer to the new node
 *
 * Side effects:
 *	Increments the pnode count in the celldef
 *
 * ----------------------------------------------------------------------------
 */
NodeRecord * ntlAddNode(CellDef * cd)
{
    NodeRecord * node;

    node = ntlNewNode();
    node->nrec_nodenum = cd->cd_nodeCount++;
    return (node);
}

void ntlInst2InstPorts(
		    NodeRecord  * intNode,
		    TileType intType,
		    Rect * overlapRect,
		    HierArg * ha)
{
    NLabelList *nll;
    int portNum1, portNum2;
    NodeRecord * extNode;
    Transform inverseTrans;
    Rect r, r1;
    PortConnector * connections1, * connections2;
    bool keepPort1, keepPort2;

    /*
     * dont need to update size of connections, 
     * because processing explict ports only
     * dont need to go any further if intNode and extNode 
     * are already connected
     */
    extNode = (NodeRecord *) ha->ha_extTile->ti_client;

    if(  (ha->ha_use1->cu_def->cd_portCount != 0)
      && (ha->ha_use2->cu_def->cd_portCount != 0)
      && ntlPortsConnected(intNode, extNode, 
	    * ha->ha_elementConns1, * ha->ha_elementConns2))
	return;

    /*
     * have overlap, but no connection yet
     * Step 1 : use1 must have overlapping explicit port to continue
     * look for first port on intNode that touches overlapRect
     */
    portNum1 = ntlFindNodesPortArea(
		intNode->nrec_labels,
		intType,
		overlapRect);

    /*
     * if explicit port found, set flag and proceed to step 2
     * else (no explicit port found)
     * stop if in pass one (explicit ports required)
     * else see if OK to add implicit port
     */
    if (portNum1 != -1)
	keepPort1 = TRUE;
    else if (ha->ha_pass2 == FALSE) 
	return;		
    else 	/* if((ha->ha_pass2 == TRUE) && (portNum1 == -1)) */
    {
	if(ntlImplicitPorts == FALSE)
	{
	    MsgInfoF("Warning: Subcells %s and %s are connected in celldef %s",
		ha->ha_use1->cu_id,
		ha->ha_use2->cu_id,
		ha->ha_use1->cu_parent->cd_name
		);
	    MsgInfoF("but first subcell does not have overlapping explicit port");
	    MsgInfoF("and ntlImplicitPorts is false\n");

	    /* abandon this overlap */
	    return;
	}
	else 	/* add a new implicit port to use1's celldef */
	{
	    keepPort1 = FALSE;
	    portNum1 = ntlAddPort( ha->ha_use1->cu_def,
				intNode, 
				intType, 
				overlapRect);
/*MsgInfoF("I2I inst1: adding port %d to use %s\n", portNum1, ha->ha_use1->cu_id); */
	}
    }

    /* 
     * Step2: use2 must have overlapping explicit port to continue
     * look for a port on extNode (in use2) that touches overlapRect 
     * 
     * assumes that connection must be made only with same type, 
     * so extType == intType
     */

    /*
     * transform overlap rect from use1 coordinates to use2 coordinates
     */
    GEOTRANSRECT(ntlTransUse1toParent, overlapRect, &r);

    /* thru parent coordinates */
    GEOINVERTTRANS(ntlTransUse2toParent, &inverseTrans);
    GEOTRANSRECT(&inverseTrans, &r, &r1);

    portNum2 = ntlFindNodesPortArea(
		extNode->nrec_labels,
		intType,
		&r1);

    /*
     * if explicit port found, set flag and proceed to step 3
     * else (no explicit port found)
     * stop if in pass one (explicit ports required)
     * else see if OK to add implicit port
     */
    if(portNum2 != -1)
	keepPort2 = TRUE;
    else if (ha->ha_pass2 == FALSE) 
	return;
    else 	/* if((ha->ha_pass2 == TRUE) && (portNum2 == -1)) */
    {
	if(ntlImplicitPorts == FALSE)
	{
	    MsgInfoF("Warning: Subcells %s and %s are connected in celldef %s",
		ha->ha_use1->cu_id,
		ha->ha_use2->cu_id,
		ha->ha_use1->cu_parent->cd_name
		);
	    MsgInfoF("but second subcell does not have overlapping explicit port");
	    MsgInfoF("and ntlImplicitPorts is false\n");

	    /* abandon this overlap */
	    return;
	}
	else 	/* add a new implicit port to use2's celldef */
	{
	    keepPort2 = FALSE;
	    portNum2 = ntlAddPort( ha->ha_use2->cu_def,
				extNode, 
				intType, 
				&r1);
/*MsgInfoF("I2I inst2: adding port %d to use %s\n", portNum2, ha->ha_use2->cu_id); */
	}
    }

    /* 
     * Step 3: both cells have been found to have overlapping ports
     * first make sure that connection lists have been allocated
     * in both uses
     * add a node to parent, and connect it to both ports
     * (re-uses variable extNode)
     */

/*
MsgInfoF("I1 = %s, I2 = %s, pnum1 = %d, pnum2 = %d\n", 
    ha->ha_use1->cu_id, 
    ha->ha_use2->cu_id,
    ha->ha_use1->cu_def->cd_portCount, 
    ha->ha_use2->cu_def->cd_portCount);
    */

    /* make sure connections list has been allocated for use1 */
    connections1 = ntlAllocPortCons(
		    *(ha->ha_elementConns1),
		    ha->ha_use1->cu_def->cd_portCount);
    *(ha->ha_elementConns1) = connections1;

    /* make sure connections list has been allocated for use2 */
    connections2 = ntlAllocPortCons(
		    *(ha->ha_elementConns2),
		    ha->ha_use2->cu_def->cd_portCount);
    *(ha->ha_elementConns2) = connections2;

    if ((keepPort1 == FALSE) && (keepPort2 == FALSE))
    {
	/* add node to parent */
	extNode = ntlAddNode(ha->ha_use1->cu_parent);

	/* connect parent node to port in use1 */
	connections1->pc_conns[portNum1] = extNode;

	/* connect parent node to port in use2 */
	connections2->pc_conns[portNum2] = extNode;
    }
    else if ((keepPort1 == TRUE) && (keepPort2 == FALSE))
	connections2->pc_conns[portNum2] = connections1->pc_conns[portNum1];
    else if ((keepPort1 == FALSE) && (keepPort2 == TRUE))
	connections1->pc_conns[portNum1] = connections2->pc_conns[portNum2];
    /* else error not connected to each other, but to 2 other nodes */
    
}
