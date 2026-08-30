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
 * ntlHier2.c --
 *
 * functions for hierarchical netlisting
 * that are used for paint-to-instance interaction 
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
static char rcsid[] = "$Header: ntlHier2.c,v 6.0 90/08/28 18:15:25 mayo Exp $";
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
 * ntlAllocPortCons --
 *	If CurConns is NULL, allocates a new PortConnector Struct
 *	Else if the numConns is larger than the number already allocated
 *	enlarges (reallocates) the PortConnector to hold numConns connections
 *	if neither is true, curConns is already the right size
 *
 * Results:
 *	A pointer to a PortConnector struct
 *	Each PortConnector struct is big enough 
 *	to hold "numConns" pointers to NodeRecords
 *
 * ----------------------------------------------------------------------------
 */

PortConnector * ntlAllocPortCons (PortConnector * curConns, int numConns)
{
    PortConnector * newConns;
    int i;
    unsigned n;

    ASSERT(numConns != 0, "ntlAllocPortCons must not be called with zero length\n");

    /* malloc if first list */
    if(curConns == NULL)
    {
	n = sizeof (PortConnector) + (sizeof (NodeRecord *) * (numConns - 1));
	MALLOC( PortConnector *, newConns, n);
	for(i = 0; i < numConns; i = i+1)
	    newConns->pc_conns[i] = (NodeRecord *)NULL;
	newConns->pc_numAlloced = numConns;
	return (newConns);
    }

    /* else realloc if more connections requested */
    else if((curConns->pc_numAlloced) < numConns)
    {
	n = sizeof (PortConnector) + (sizeof (NodeRecord *) * (numConns - 1));

	MALLOC( PortConnector *, newConns, n);

	/* Copy current connections into new connections, followed by nulls */
	for(i = 0; i < numConns; i = i+1)
	    if(i < curConns->pc_numAlloced)
	    {
		newConns->pc_conns[i] = curConns->pc_conns[i];
	    }
	    else
		newConns->pc_conns[i] = (NodeRecord *)NULL;

	newConns->pc_numAlloced = numConns;
	/* free the old one */
	FREE(curConns);
	return (newConns);
    }
    /* if not first or larger,  return original, nothing to do */
    else return (curConns);
}


/*
 * ----------------------------------------------------------------------------
 * ntlTile2InstExplPorts --
 *	
 *	The connection is only made if the external rectangle overlaps
 *	the bbox of the port label
 *
 * Results:
 *	None
 *
 * Side effects:
 *	Memory for the portConnector may be allocated or reallocated
 *	
 *
 * ----------------------------------------------------------------------------
 */
void ntlTile2InstExplPorts( NodeRecord  * intNode, 
		     TileType intType,
		     Rect * overlapRect, 
		     HierArg * ha)
{
    NLabelList * nll;
    int portNum;
    PortConnector * connections;
    NodeRecord * extNode;

    /*
     * search the internal node's port labels, 
     * looking for intersection of the label's rectangle with 
     * overlap rectangle where the 2 pieces of paint connect
     *
     * stops after the first connection is made, because
     * a second connection between two tiles is redundant
     * (even if there is more than one port on the same internal tile)
     *
     * fill in port's connection in the instance connection list
     * the port index is found in label->ll_port->po_num
     */

    for(nll = intNode->nrec_labels; nll; nll = nll->ll_next)
    {
	if(nll->ll_port != NULL     /* skip unless label is a port */
	    && nll->ll_label->lab_type == intType	
			/* only look at ports with internal tile type */
	    && GEO_TOUCH(overlapRect, &(nll->ll_label->lab_rect)))
	{
	    /* index of this port in def */
	    portNum = nll->ll_port->po_portnum;

	    /* external node that connects */
	    extNode = (NodeRecord *) ha->ha_extTile->ti_client;

	    /*
	     * allocate connection array for this instance array element
	     * number of ports is stored in celldef
	     */
	    connections = ntlAllocPortCons(*(ha->ha_elementConns1), 
			    ha->ha_use1->cu_def->cd_portCount);
	    *(ha->ha_elementConns1) = connections;

	    if( connections->pc_conns[portNum] == (NodeRecord *) NULL)	
	    /* first connection to this port */
	    {
		connections->pc_conns[portNum] = extNode;
	    }
	    else if(connections->pc_conns[portNum] != extNode)
	    {
		/*
		 * complain if already connected to a different node
		 * multiple nodes connected to one port not allowed !
		 */
		MsgInfoF("NETLISTING ERROR, second node connected to port %d of use1 =  %s:\n", 
			    portNum,
			    ha->ha_use1->cu_id);

		MsgInfoF("prior connection = %s\n", 
			    ntlNodeName(connections->pc_conns[portNum]));
		MsgInfoF("new connection = %s\n", 
			    ntlNodeName(extNode));
	    }
	    else
	    {
		/* redundant connection to same node */
		/*
		MsgInfoF("redundant connection of extnode = %s to port %d\n", 
		    ntlNodeName(extNode), portNum);
		 */
	    }
	    /* first connection should be  only one (?) */
	    return;
	}
    }
}


/*
 * ----------------------------------------------------------------------------
 * ntlTile2InstImplPorts --
 *	
 *
 * Results:
 *	None
 *
 * Side effects:
 *	Memory for the portConnector may be allocated or reallocated
 *	
 *
 * ----------------------------------------------------------------------------
 */
void ntlTile2InstImplPorts( NodeRecord  * intNode, 
		     TileType intType,
		     Rect * overlapRect, 
		     HierArg * ha)
{
    NLabelList * nll;
    int portNum;
    PortConnector * connections;
    NodeRecord * extNode;

    /*
     * search the internal node's port labels, 
     * looking for any port that is already 
     * connected to the external node
     *
     */

    /* external node that connects */
    extNode = (NodeRecord *) ha->ha_extTile->ti_client;

    for(nll = intNode->nrec_labels; nll; nll = nll->ll_next)
    {
	if(    nll->ll_port != NULL
	    && nll->ll_label->lab_type == intType)
	{
	    /*
	     * there no need to add an implicit port if there is 
	     * already one that intersects 
	     */
	    /* index of this port in def */
	    portNum = nll->ll_port->po_portnum;

	    /*
	     * allocate connection array for this instance array element
	     * number of ports in the celldef may have changed since first pass
	     */
	    connections = ntlAllocPortCons(*(ha->ha_elementConns1), 
			    ha->ha_use1->cu_def->cd_portCount);
	    *(ha->ha_elementConns1) = connections;

	    /*
	     * must not create an implicit connection if any port on this layer
	     * has this connection already, 
	     * regardless of overlap between paint and port
	     *
	     * possibly should enlarge the port: issue is overlap may not be ajacent
	     */
	    if ( connections->pc_conns[portNum] == extNode)
	    {
		/* redundant connection to same node */
/*
MsgInfoF("redundant connection of extnode = %s to port %d\n", 
    ntlNodeName(extNode), portNum);
 */
		return;	/* found overlap */
	    }

	    /*
	     * also dont need implicit port if an overlapping port already exists,
	     * just connect it up if possible
	     */
	    if (GEO_TOUCH(overlapRect, &(nll->ll_label->lab_rect)))
	    {
		/* first connection to this port in this instance*/
		if( connections->pc_conns[portNum] == (NodeRecord *) NULL)	
		    connections->pc_conns[portNum] = extNode;
		else if(connections->pc_conns[portNum] != extNode)
		{
		    /*
		     * complain if already connected to a different node
		     * multiple nodes connected to one port not allowed !
		     */
		    MsgInfoF("NETLISTING ERROR, second node connected to port %d of use1 =  %s:\n", 
				portNum,
				ha->ha_use1->cu_id);

		    MsgInfoF("prior connection = %s\n", 
				ntlNodeName(connections->pc_conns[portNum]));
		    MsgInfoF("new connection = %s\n", 
				ntlNodeName(extNode));
		}
		/* redundant connection cannot occur, covered above
		else if(connections->pc_conns[portNum] == extNode)
		 */
		return;	/* found overlap */
	    }
	}
    }

    /*
     * no explicit (or existing implicit) port overlap exists 
     * see if OK to add implicit port
     */
    if(ntlImplicitPorts == FALSE)
    {
	MsgInfoF("Paint in celldef %s connects to subcell %s",
	    ha->ha_use1->cu_parent->cd_name,
	    ha->ha_use1->cu_id
	    );
	MsgInfoF("but subcell does not have overlapping explicit port");
	MsgInfoF("and ntlImplicitPorts is false\n");

	/* stop netlisting now  ?? */
	return;
    }
    else 	/* add a new implicit port to use1's celldef */
    {
	portNum = ntlAddPort( ha->ha_use1->cu_def,
			    intNode, 
			    intType, 
			    overlapRect);
/*MsgInfoF("connecting new port to node %s\n", ntlNodeName(extNode)); */

	/*
	 * reallocate this instance port connection list, 
	 * since it needs to grow by one
	 *
	 * requires other instances of ths celldef 
	 * to be re-allocated before being accessed
	 */
	connections = ntlAllocPortCons(
			    *(ha->ha_elementConns1), 
			    ha->ha_use1->cu_def->cd_portCount);

	*(ha->ha_elementConns1) = connections;

	/* make connection to new port */
	connections->pc_conns[portNum] = extNode;
    }
}

/*
 * ----------------------------------------------------------------------------
 * ntlTile2PortsFunc --
 *	
 * 	Called by ntlTile2ElementFunc() for every internal tile 
 *	that is connected to overlapping external tile 
 *	
 *	Connection will not be made if internal node does not have a port labeL,
 *	or its node's type is global and using implicit global connections
 *
 *	Otherwise prepare arguments and call 
 *	ntlTile2InstExplPort or ntlTile2InstImplPort based on pass flag
 *
 * Results:
 *	returns 0 to continue search
 *
 * Side effects:
 *	None
 *
 * ----------------------------------------------------------------------------
 */

int ntlTile2PortsFunc(Tile * intTile, HierArg * ha)
{
    NodeRecord * intNode = (NodeRecord *) intTile->ti_client;
    Rect overlapRect;
    int	labType;

/*
MsgInfoF("ntlTile2PortsFunc: use1 =  %s, ha_pass2 = %d\n", 
ha->ha_use1->cu_id, ha->ha_pass2);
 */

    /* ignore if internal node's port type is global, and using globals */
    labType = intNode->nrec_type;
    if ( (labType == LAB_GLOBAL) && ntlUseGlobals)
	return (0);		

    /* compute overlapRect -- overlap of internal and external tiles */
    TITORECT(intTile, &overlapRect);
    GEOCLIP(&overlapRect, ha->ha_intRect);

    if(ha->ha_use2 != NULL)
    {
	ntlInst2InstPorts(
	    intNode, 
	    DBgetTileType(intTile),
	    &overlapRect,
	    ha);
    }
    else
    if(ha->ha_pass2 == FALSE)
    {
	/* subcell's node does not have port label attached */
	if(    (labType !=  LAB_GLOBAL)
	    && (labType !=  LAB_INPUT)
	    && (labType !=  LAB_OUTPUT)
	    && (labType !=  LAB_INOUT)
	  )
	    return(0);

	ntlTile2InstExplPorts(
	    intNode, 
	    DBgetTileType(intTile),
	    &overlapRect,
	    ha);
    }
    else
    {
	ntlTile2InstImplPorts(
	    intNode, 
	    DBgetTileType(intTile),
	    &overlapRect,
	    ha);
    }

    return(0);
}


/*
 * ----------------------------------------------------------------------------
 * ntlTile2ElementFunc --
 *
 *	Transform the the external rect (in parent coordinates)  
 *	into coordinates of the array element's celldef, 
 *	and enumerate all tiles in def that are connected,
 *	based on the type of the external tile
 *
 * Results:
 *	 1 if interrupt pending, else 0 ??
 *
 * Side effects: none
 *
 * ----------------------------------------------------------------------------
 */

int ntlTile2ElementFunc(CellUse *use1, Transform * trans, 
			 int x, int y, HierArg * ha)

{
    Rect * r;
    Rect r1;
    Transform inverseTrans;
    TileType type;
    TileTypeBitMask * mask;
    TileTypeBitMask ttmask;
    int xlen, element;

/*
MsgInfoF("\nntlTile2ElementFunc for use %s of celldef %s\n", use1->cu_id, 
	use1->cu_def->cd_name);
 */

    /* save for later use, I2I only*/
    ntlTransUse1toParent = trans;

    /*
     * compute the address of the port connections for this array 
     * element of use 1
     */
    xlen =  ABS(use1->cu_xhi - use1->cu_xlo) + 1;
    element = (y * xlen ) + x;
    ha->ha_elementConns1 = (PortConnector **) &(use1->cu_elementConns[element]);

    /* pointer to external rect to be transformed */
    r = ha->ha_extRect;

    /*
     * clip external rectangle against bbox of celluse,
     *(this may not be necessary, but seems prudent !)
     */
    GEOCLIP(r, &use1->cu_bbox);

    /*
     * calling transform converts Use coordinates to Parent coordinates
     * (it is use1->cu_transform, translated by array position)
     * invert to get transform from coord of use1->cu_parent 
     * to coord of use1->cu_def
     */
    GEOINVERTTRANS(trans, &inverseTrans);

    /* transform the part of the external rect 
     * that in inside the array element
     * into use1->cu_celldef coordinates
     */
    GEOTRANSRECT (&inverseTrans, r, &r1);

    /*
     * pass ha_intRect to ntlTile2PortsFunc 
     */
    ha->ha_intRect = &r1;

    type = DBgetTileType(ha->ha_extTile);

    /*
     * only look for connections on same type for now
     * later, look on same type first ?? 
     * if Only need to search same layer, 
     * an optimization is available 
     */

    /* connect mask for this type */
    /*mask = &ntlConnectTable[type]; */

    mask = &ttmask;
    TTMaskSetOnlyType(mask, type);

    /* search all connecting planes */
    {
      PlaneList *planes = DBPlaneListFromTypes(mask);
      PlaneList *pll;

      for(pll = planes; pll; pll=pll->pll_next)
      {
	/* search area r1 is ha_extRect transformed 
	 * into use1->cu_def coordinates
	 */
        if( DBPlaneEnumAreaPaint(
		(Tile *) NULL,
		use1->cu_def->cd_planes[pll->pll_num],
		&r1,
		mask,
		ntlTile2PortsFunc,
		(ClientData) ha
		)
	    )
        {
          MsgInfoF("ntlTile2Element: Netlisting interrupted !\n");
          return(1);
        }
      }
      PlaneListFree(planes);
      return(0);
    }
}
