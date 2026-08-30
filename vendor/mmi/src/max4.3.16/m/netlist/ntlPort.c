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
 * ntlPort.c --
 *
 * Port related functions for netlisting
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
static char rcsid[] = "$Header: ntlPort.c,v 6.0 90/08/28 18:15:25 mayo Exp $";
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

/*
 * ----------------------------------------------------------------------------
 *
 * ntlAllocPortConsFn --
 *
 *	Called by DBEnumChildren, for each instance.
 *	Since each instance can actually be an array of instances,
 *	a port connection list is needed for each array element.
 *	
 *	THe pointer for each element will later be allocated to point 
 *	to an array that contains a connection for each port
 *
 * Result: 
 *	0, to contiune with next celluse
 *
 * Side Effects:
 *	Allocates space for (xlen * ylen) pointers to PortConss
 *	and sets use->cu_elementcons to point to it.
 *	The pointers are initialized to NULL
 *
 * ----------------------------------------------------------------------------
 */
int 
ntlAllocPortConsFn(CellUse * use, ClientData none)
{
    PortConnector ** aptrs;		/* array of pointers to PortConns */
    int	xlen, ylen, total, i;

    if(DBIsArray(use))
    {
      xlen = ABS(use->cu_xhi - use->cu_xlo) + 1;
      ylen = ABS(use->cu_yhi - use->cu_ylo) + 1;
    }
    else
    {
      xlen = 1;
      ylen = 1;
    }

    total =  xlen * ylen;
    MALLOC(PortConnector **, aptrs, total * sizeof (PortConnector *));

    use->cu_elementConns = (ClientData ** ) aptrs; 

    for(i = 0; i < total; i ++)
	aptrs[i] = (PortConnector * ) NULL;

/*
MsgInfoF("Allocating ElementConns in cell use %s, size is %x\n",
		use->cu_id,
		total);
 */

    return(0);
}

/*
 * ----------------------------------------------------------------------------
 *
 * ntlFreePortConsFn --
 *
 *	Called by DBEnumChildren, for each instance.
 *
 * Result: 
 *	0, to contiune with next celluse
 *
 * Side Effects:
 *	Frees the PortConns pointed to by the 
 *	contents of cu->cu_elementCons
 *	and finally cu->cu_elementCons itself
 *
 * ----------------------------------------------------------------------------
 */

int 
ntlFreePortConsFn(CellUse * use, ClientData none)
{
    PortConnector ** aptrs;		/* array of pointers to PortConns */
    int	xlen, ylen, total, i;

    if(DBIsArray(use))
    {
      xlen = ABS(use->cu_xhi - use->cu_xlo) + 1;
      ylen = ABS(use->cu_yhi - use->cu_ylo) + 1;
    }
    else
    {
      xlen = 1;
      ylen = 1;
    }

    total =  xlen * ylen;

    aptrs = (PortConnector **) use->cu_elementConns;
    for(i = 0; i < total; i ++)
	if(aptrs[i] != (PortConnector *) NULL)
	    FREE(aptrs[i]);
    FREE(aptrs);
    return (0);
}

/*
 * ----------------------------------------------------------------------------
 * ntlAddPort --
 *	add a new port to a the celldef's node
 *		create a label,and the attach it to the celldef's label list
 *		in the same fashion as ntlLabelNodes,
 *		except attach the new port to the END of the portlist
 * Results:
 *
 * Side effects: see above
 * 
 * NOTE: should not call this function if node type is global
 *
 * ----------------------------------------------------------------------------
 */ 
int
ntlAddPort(CellDef * def, NodeRecord * node, TileType type, Rect * bbox)
{
    Label * newLab;
    NLabelList * ll;
    Port * lastPort, * newPort;
    char name[100];
    /*
     * allocate a new label 
     * label must be flagged for removal after netlisting done
     */
    (void) sprintf(name, "P_%d", def->cd_portCount);

    newLab = DBLabelAdd(def, bbox, -1, name, type, LAB_INOUT);

    if(ntlVerbose)
	MsgInfoF("ntlAddPort: adding Implicit port to celldef %s\n\
\tPort name = %s, type = %s, location = (%d, %d) (%d, %d)\n",
	    def->cd_name,
	    name,
	    DBTypeShortName(type),
	    bbox->r_xbot, bbox->r_ybot,
	    bbox->r_xtop, bbox->r_ytop );
    /*
     * create a list element for the new label
     * and link it on to the nodes label list
     */
    MALLOC(NLabelList *, ll, sizeof (NLabelList));
    ll->ll_label = newLab;
    ll->ll_next = node->nrec_labels;
    ll->ll_uniq = 0;
    ll->ll_flag = TRUE;	/* mark label as added by netlister for later removal */
    node->nrec_labels = ll;

    /*
     * make node's type inout, if it is not already 
     * global, input, or output 
     */
    if ( (node->nrec_type != LAB_INPUT)
      && (node->nrec_type != LAB_OUTPUT)
      && (node->nrec_type != LAB_GLOBAL))
	node->nrec_type = LAB_INOUT;

    MALLOC(Port *, newPort, sizeof(Port));
    newPort->po_node = node;
    newPort->po_portnum = def->cd_portCount;
    newPort->po_next   = (Port *) NULL;
    newPort->po_nextFt = (Port *) NULL;
    newPort->po_flags  = 0;

    if(0 == def->cd_portCount)		/* port list empty */
    {
	/*
	MsgInfoF("def->cd_portCount = %d def->cd_portList = %x, newPort = %x\n", 
	def->cd_portCount, def->cd_portList, newPort);
	*/
	def->cd_portList = (ClientData *) newPort;
    }
    else
    {
	/* add port to END of celldefs port list */
	for(lastPort = (Port *) def->cd_portList;
	    lastPort->po_next != (Port *) NULL;
	    lastPort = (Port *) lastPort->po_next)
	    ;
	lastPort->po_next = newPort;
    }

    /* increment port count in celldef */
    def->cd_portCount++;

    /* store pointer to port in label list*/
    ll->ll_port = newPort;

    /* port number is zero based */
    return(def->cd_portCount-1);
}

/*
 * ----------------------------------------------------------------------------
 * ntl2ndNodeNameBetter --
 *
 * Ignores effect of uniq suffix on names.
 *
 * ----------------------------------------------------------------------------
 */ 
static int 
ntl2ndNodeNameBetter(NodeRecord * node0, NodeRecord * node1)
{
char * str0, * str1;
    /* check for no labels on node */
    if ( node1->nrec_labels == NULL )
	return 0;
    if ( node0->nrec_labels == NULL )
	return 1;

    /* both have labels, check for 1 global */
    if ( (node0->nrec_type == LAB_GLOBAL)
      && (node1->nrec_type != LAB_GLOBAL))
	return 0;
    if ( (node0->nrec_type != LAB_GLOBAL)
      && (node1->nrec_type == LAB_GLOBAL))
	return 1;

    /* both same type, check for null strings (may never happen ?) */
    str0 = node0->nrec_labels->ll_label->lab_text;
    str1 = node1->nrec_labels->ll_label->lab_text;
    if ((str0 != NULL) && (str1 == NULL))
	return 0;
    if ((str0 == NULL) && (str1 != NULL))
	return 1;

    /* finally: take the longer string */
    if (strlen(str0) > strlen(str1))
	return 0;
    else 
	return 1;

}

/*
 * ----------------------------------------------------------------------------
 *
 * ntlMergeNodes --
 *
 * Merge two nodes:
 * after done, the alias field of both nodes will point to 
 * the single node that has the "best" name
 *
 * four cases bases on the current state of the alias fields
 * 
 * NOTE: both node arguments must be non-NULL
 *
 * ----------------------------------------------------------------------------
 */
static void 
ntlMergeNodes(NodeRecord * node0, NodeRecord * node1)
{
    NodeRecord ** alias0, ** alias1;

    if(ntlVerbose)
    {
	MsgInfoF("ntlMergeNodes: node0 = %s (%x) (alias = %x), *alias = %x\n", 
	    ntlNodeName(node0), node0, node0->nrec_alias, 
		(node0->nrec_alias == 0) ? 0 : *node0->nrec_alias);
	MsgInfoF("ntlMergeNodes: node1 = %s (%x) (alias = %x), *alias = %x\n",
	    ntlNodeName(node1), node1, node1->nrec_alias,
		(node1->nrec_alias == 0) ? 0 : *node1->nrec_alias);
    }

    if((node0->nrec_alias == NULL) && (node1->nrec_alias == NULL))
    {
	/* allocate storage for common alias */
	MALLOC(NodeRecord **, alias0, sizeof (NodeRecord *));

	/* set alias field of both nodes to point to new alias */
	node0->nrec_alias = node1->nrec_alias = alias0;

	/* store pointer to winning node in common alias */
	if(ntl2ndNodeNameBetter(node0, node1))
	    (* alias0) = node1 ;
	else
	    (* alias0) = node0 ;
    }
    else if(node0->nrec_alias == NULL)	/* Node 1's alias will be used */
    {
	node0->nrec_alias = node1->nrec_alias;
    }

    else if(node1->nrec_alias == NULL)  /* Node 0's alias will be used */
    {
	node1->nrec_alias = node0->nrec_alias;
    }

    else /* if((node0->nrec_alias != NULL) && (node1->nrec_alias != NULL)) */
    /* both non-NULL, pick winner and change losing alias to point to winning node */
    {
	alias0 = node0->nrec_alias;
	alias1 = node1->nrec_alias;
	if (( alias0 ==  alias1) 	/* share common alias */
	||  (*alias0 == *alias1))	/* aliases alreadye point to same node, merged */
	    return;

	if(ntl2ndNodeNameBetter(*alias0, *alias1))
	    *alias0 = *alias1;
	else	/* node 0 winner */
	    *alias1 = *alias0;
    }
}

/*
 * ----------------------------------------------------------------------------
 *
 * ntlMergeDefNodesFn --
 *
 * ----------------------------------------------------------------------------
 */
int ntlMergeDefNodesFn(CellUse * use, CellDef * def)
{
    int x, y, xlen, xoff, yoff, ylen, element;
    int xlo, xhi, ylo, yhi;
    Port * port1, * port2;
    NodeRecord * node1, * node2;
    PortConnector * connector;
    CellDef * usesDef = use->cu_def;

    if(ntlVerbose)
	MsgInfoF("ntlMergeDefNodes: def = %s\n", def->cd_name);
    /*
     * don't process if this use's definition contains no feedthrus, 
     * or has less than 2 ports 
     */
    if (   (usesDef->cd_flags & CD_NOFEEDTHRUS) 
	|| (usesDef->cd_portCount < 2 ))
	return(0);

    if(DBIsArray(use))
    {
      xlo = use->cu_xlo;
      xhi = use->cu_xhi;
      ylo = use->cu_ylo;
      yhi = use->cu_yhi;
    }
    else
    {  
      xlo = 0;
      xhi = 0;
      ylo = 0;
      yhi = 0;
    }

    xlen = ABS(xhi - xlo) + 1;
    xoff = MIN(xlo, xhi);
    yoff = MIN(ylo, yhi);

    for (x = xlo; x <= xhi; x = x+1)
    for (y = ylo; y <= yhi; y = y+1)
    {
	element =  (xlen * (y-yoff) + (x-xoff));
	connector = (PortConnector *) use->cu_elementConns[element];

	/* no connections to this instance */
	if (connector == NULL)
	    return(0);

	/* traverse the feedthru port list(s) in the use's cd */
	for (port1 = (Port *) usesDef->cd_portList; 
	     port1; 
	     port1 = port1->po_next)
	{
		/* keep going until find head of feedthru list */
	    if ( ((port1->po_flags & NTL_PORT_FT_HEAD) == 0)
		    /* no connection to port1 */
		  ||  (port1->po_portnum >= connector->pc_numAlloced)
		  || ((node1 = connector->pc_conns[port1->po_portnum]) == NULL))
		continue;

	    for (port2 = port1->po_nextFt; 
		 port2; 
		 port2 = port2->po_nextFt)
	    {
		    /* no connection to port2 */
		if (  (port2->po_portnum >= connector->pc_numAlloced)
		  || ((node2 = connector->pc_conns[port2->po_portnum]) == NULL)
		  || (node1 == node2))	/* dont merge if nodes are the same */
		    continue;

		/* have 2 nodes to merge  !! */
		if(ntlVerbose)
		{
			/* must be careful with ntlNodeName() */
		    MsgInfoF ("Merging nodes %s", ntlNodeName(node1));
		    MsgInfoF (" and %s in celldef %s, based on FT in use %s\n", 
			ntlNodeName(node2), def->cd_name, use->cu_id);
		}
	        ntlMergeNodes( node1, node2);
	    }
	}
    }
    return(0);
}

/*
 * ----------------------------------------------------------------------------
 *
 * ntlMarkFtPorts --
 *
 * traverse the ports in a celldef,
 * creating possibly multiple linked lists
 *
 * each list contains all the ports that belong to the same node
 * (feed-thrus)
 *
 * each port is flagged as one of 3 types
 * 1) the head of a linked list of all of the ports 
 *    that belong to a single node
 * 2) a member of a FT list (not the first entry)
 * or 3) neither of the above
 *
 * note that any single port can only be in one list
 *
 * the first flag is used to locate the start of 
 * the port lists that will be traversed when merging nodes 
 *
 * type 2 ports are not output when writing celldefs 
 * or instances of the celldef
 * (types 1 and 3 ARE output)
 *
 * also, count the number of FTS (type 2 ports) found, 
 * so that 2 conditions can be flagged in the celldef
 *
 * 1) no feedthru ports in the cd, so that node merging can 
 * skip instances of this cd, and 
 *
 * 2) all ports of this cd are a single node, 
 * so that this cd will not be output at all
 *
 * in this case, this cd must be a via or a wire
 *
 * ----------------------------------------------------------------------------
 */

void 
ntlMarkFTPorts(CellDef * def)
{
    NodeRecord * node1, * node2;
    Port * port1, * port2, * lastPort;
    int ftCount = 0;

    for(port1 = (Port*)def->cd_portList; port1; port1 = port1->po_next)
    {
	/*
	 * if already marked as feed-thru, 
	 * this port already already in a FT list, so move on
	 */
	if(port1->po_flags & (NTL_PORT_FT_HEAD | NTL_PORT_FT_ELEM))
	    continue;
	lastPort = port1;
	for(port2 = port1->po_next; port2; port2 = port2->po_next)
	{
	    if(ntlBaseNode(lastPort->po_node) == ntlBaseNode(port2->po_node))
	    {
		    /*
		     * its OK to set HEAD flag in port 1 multiple times,
		     * so dont bother to check for first time
		     */
		port1->po_flags = NTL_PORT_FT_HEAD;
		    /* mark next item as ft */
		port2->po_flags = NTL_PORT_FT_ELEM;

		lastPort->po_nextFt = port2;
		lastPort = port2;
		ftCount ++;
	    }
	}
    }
	/* set def flags, make sure not to disturb other flags */
/*
if(ntlVerbose)
MsgInfoF("MarkFTPorts for %s ftCount = %d\n", def->cd_name, ftCount);
 */
    if(ftCount == 0) 
	def->cd_flags |= CD_NOFEEDTHRUS;
    else if(ftCount == def->cd_portCount -1) 
	def->cd_flags |= CD_ALLFEEDTHRUS;
}

