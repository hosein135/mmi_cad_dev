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
#include "memory.h"
#include "message.h"
#include "debug.h"
#include "signals.h"
#include "styles.h"
#include "netlistInt.h"
#include "netlist.h"

/*
 * ----------------------------------------------------------------------------
 * ntlPortsConnected --
 *	search the ports associated with node 1 and node 2, 
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
static int 
ntlPortsConnected(NodeRecord * intNode, 
		  NodeRecord * extNode, 
		  PortConnector * conns1, 
		  PortConnector * conns2)
{
    NLabelList * lab1, * lab2;
    NodeRecord * parentNode;
    int	portNum1, portNum2;

    /* quit if no port connections to either instance yet */
    if( (conns1 == NULL) || (conns2  == NULL))
	return(0);

    /* for all ports connected to Node1 */
    for(lab1 = intNode->nrec_labels; lab1 ; lab1 = lab1->ll_next)
    {
	if(lab1->ll_port == NULL) 
	    continue;

	/* there is no connection if
	 * 1) connection list in this instance is not big enough
	 * 2) connection is NULL
	 */
	portNum1 = lab1->ll_port->po_portnum;
	if ((portNum1 >= conns1->pc_numAlloced)
	 	|| (conns1->pc_conns[portNum1] == NULL))
	    continue;

	parentNode = conns1->pc_conns [portNum1];

	/* for all ports connected to Node2 */
	for(lab2 = extNode->nrec_labels; lab2 ; lab2 = lab2->ll_next)
	{
	    if(lab2->ll_port == NULL) 
		continue;
	    portNum2 = lab2->ll_port->po_portnum;
	    if ((portNum2 >= conns2->pc_numAlloced)
		    || (conns2->pc_conns[portNum2] == NULL))
		continue;
	    if(parentNode == conns2->pc_conns[portNum2])
	    {
		/*
		MsgInfoF("conns1 = %x\nconns2 = %x\n", conns1, conns2 );
		MsgInfoF("Intnode = %d\nExtnode = %d\n", intNode, extNode );
		MsgInfoF("portnum1 is %d\nportnum2 is %d\n", portNum1, portNum2);
		MsgInfoF("ParentNode = %s\n", ntlNodeName(parentNode));
		MsgInfoF("ntlPortsConnected returns TRUE\n");
		 */

		return (1);
	    }
	}
    }
    return(0);
}

/*
 * ----------------------------------------------------------------------------
 *
 * ntlFindNodesPortArea --
 *
 * ----------------------------------------------------------------------------
 */
static int 
ntlFindNodesPortArea(NLabelList * llist,
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
static NodeRecord * 
ntlAddNode(CellDef * cd)
{
    NodeRecord * node;

    node = ntlNewNode();
    node->nrec_nodenum = cd->cd_nodeCount++;
    return (node);
}

/*
 * ----------------------------------------------------------------------------
 *
 * ntlInst2InstPorts --
 *
 * ----------------------------------------------------------------------------
 */
void 
ntlInst2InstPorts(NodeRecord  * intNode,
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
    NodeRecord *  connNode1, * connNode2;
    bool keepPort1, keepPort2;

    /*
     * dont need to go any further if intNode and extNode 
     * are already connected
     */
    extNode = (NodeRecord *) ha->ha_extTile->ti_client;

    if(  (ha->ha_use1->cu_def->cd_portCount != 0)
      && (ha->ha_use2->cu_def->cd_portCount != 0)
      && ntlPortsConnected(intNode, extNode, 
	    * ha->ha_elementConns1, * ha->ha_elementConns2))
	return;
/* some issue with ntlPortsConnected: sometimes does not find prior connections */

    /*
     * have overlap, but have not made connection yet
     * Step 1 : 
     * if pass1, use 1 must have overlapping explicit port to continue
     * get first port on intNode that touches overlapRect
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
	if(ntlNoImplicitPorts)
	{
	    MsgInfoF("Warning: Subcells %s and %s are connected in celldef %s",
		ha->ha_use1->cu_id,
		ha->ha_use2->cu_id,
		DBCellUseParent(ha->ha_use1)->cd_name
		);
	    MsgInfoF("but first subcell does not have overlapping explicit port");
	    MsgInfoF("and NTL_NO_IMPLICIT_PORTS is set\n");

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
/*
MsgInfoF("I2I inst1: step 1: adding port %d to use %s\n", 
    portNum1, ha->ha_use1->cu_id); 
     */
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
	if(ntlNoImplicitPorts)
	{
	    MsgInfoF("Warning: Subcells %s and %s are connected in celldef %s",
		ha->ha_use1->cu_id,
		ha->ha_use2->cu_id,
		DBCellUseParent(ha->ha_use1)->cd_name
		);
	    MsgInfoF("but second subcell does not have overlapping explicit port");
	    MsgInfoF("and ntlNoImplicitPorts is set\n");

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
/*
MsgInfoF("I2I inst2: step 2: adding port %d to use %s\n", 
    portNum2, ha->ha_use2->cu_id); 
    */
	}
    }

    /* 
     * Step 3: both cells now have overlapping ports
     * first make sure that both connection lists have been allocated
     * (re-uses variable extNode)
     * then 4 cases bases on connection status of each port
     */

/*
MsgInfoF("I2I inst2: step 3: I1 = %s, I2 = %s, pnum1 = %d, pnum2 = %d\n", 
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

    connNode1 = connections1->pc_conns[portNum1];
    connNode2 = connections2->pc_conns[portNum2];

    /*
     * if neither port is connected
     * add a new node in the parent
     */
    if ((NULL == connNode1) && (NULL == connNode2))
    {
/*
MsgInfoF("I2I inst2: step 3A: connecting port %d of use %s to port %d of use %s\n", 
    portNum1, ha->ha_use1->cu_id,
    portNum2, ha->ha_use2->cu_id); 
    */
	extNode = ntlAddNode(DBCellUseParent(ha->ha_use1));

	/* connect parent node to port in use1 */
	connections1->pc_conns[portNum1] = extNode;

	/* connect parent node to port in use2 */
	connections2->pc_conns[portNum2] = extNode;
    }

    /*
     * if only one port is explicit, prefer the node  
     * in the parent that is connected
     */
    else if ((NULL != connNode1) && (NULL == connNode2))
    {
	connections2->pc_conns[portNum2] = connections1->pc_conns[portNum1];
    }
    else if ((NULL == connNode1) && (NULL != connNode2))
    {
	connections1->pc_conns[portNum1] = connections2->pc_conns[portNum2];
    }

    else
    /*
     * both already connected to a node:
     * OK if same node, else ERROR
     */
    if(connNode1 != connNode2)
    {

MsgInfoF("I2I inst2: netlisting error: can't connect port %d of use %s to port %d of use %s\n", 
    portNum1, ha->ha_use1->cu_id,
    portNum2, ha->ha_use2->cu_id); 
MsgInfoF("I2I inst2: 1st node connected to %s (%x)\n", 
	ntlNodeName(connections1->pc_conns[portNum1]), 
	connections1->pc_conns[portNum1]);
MsgInfoF("I2I inst2: 2nd node connected to %s (%x)\n", 
	ntlNodeName(connections2->pc_conns[portNum2]),
	connections2->pc_conns[portNum2]);
    }
    
}
