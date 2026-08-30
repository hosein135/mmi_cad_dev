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
 * ntlOutput.c --
 *
 * functions that write to netlisting output file
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
static char rcsid[] = "$Header: ntlOutput.c,v 6.0 90/08/28 18:15:25 mayo Exp $";
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
#include "stack.h"

#include "netlistInt.h"

extern bool ntlUseGlobals;
extern int ntlUnconnectCount;

int ntlCurLineLen;
#define NTL_MAX_LINE_LEN 80

/* 
 * ----------------------------------------------------------------------------
 *
 * ntlPrint Item --
 *
 * equivalent to 
 * fprint (f, " %s", Item);
 * but split lines with continuation character if necessary
 *
 * ----------------------------------------------------------------------------
 */
static void 
ntlPrintItem(FILE * f, char * str, bool inComment)
{
    int stringLen = strlen(str);

    int addSpace = (ntlCurLineLen == 0) ? 0 : 1;

    /* if (stringLen > NTL_MAX_LINE_LEN), do what ? */

    /* add 1 if space before item's string */
    if((ntlCurLineLen + stringLen + addSpace) > NTL_MAX_LINE_LEN)
    {
	if(inComment)
	    fprintf(f, "\n*");
	else
	    fprintf(f, "\n+");
	ntlCurLineLen = stringLen + 1;
    }
    else
	ntlCurLineLen = ntlCurLineLen + stringLen + addSpace;

    if(addSpace)
	fprintf(f, " %s", str);
    else
	fprintf(f, "%s", str);
}

/* 
 * ----------------------------------------------------------------------------
 *
 * ntlNodeName --
 *
 * ----------------------------------------------------------------------------
 */
char *
ntlNodeName(NodeRecord * node)
{
    NLabelList * cur_llist;
    static char name[BUFSIZ];

    ASSERT((node != NULL), "ntlNodeName called with null node");

    /* print 1st label in list for now
     * TODO, pick best name, here or when assigned
     */
    cur_llist = (ntlBaseNode(node)) ->nrec_labels;

    if(cur_llist != NULL)
    {
	(void) sprintf(name, "%s",
			cur_llist->ll_label->lab_text);

	/* ll_uniq has incrementing number for duplicate node names */
	if(cur_llist->ll_uniq != 0)
	    (void) sprintf(name, "#%d", cur_llist->ll_uniq);
    }
    else
    {
	(void) sprintf(name, "N_%d", ntlBaseNode(node)->nrec_nodenum);
	/* MsgInfoF("node = %x\n", node); */
    }
    return (name);
}



/* 
 * ----------------------------------------------------------------------------
 *
 * ntlNodeNameG --
 *
 * same as ntlNodeName, but dont uniquify for globals
 * also, use G_ if no name on global 
 * only happens if label text is null, maybe cannot ever occur
 *
 *
 * ----------------------------------------------------------------------------
 */
char *
ntlNodeNameG(NodeRecord * node)
{
    NLabelList * cur_llist;
    static char name[BUFSIZ];

    ASSERT((node != NULL), "ntlNodeNameG called with null node");

    /*
     * print 1st label in list for now
     * TODO, pick best name, here or when assigned
     */
    cur_llist = node->nrec_labels;

    if(cur_llist != NULL)
	return( ntlBaseNode(node)->nrec_labels->ll_label->lab_text);
    else
    {
	(void) sprintf(name, "G_%d", ntlBaseNode(node)->nrec_nodenum);
	return (name);
    }

}

    /*
     * the following function that returns a static char *
     * that is used for all printing of node names
     * 1) devices, and 2)port definitions, port connections
     */


/* 
 * ----------------------------------------------------------------------------
 *
 * ntlNodeNameNoAlias --
 *
 * the following function that returns a static char *
 * that is used for all printing of node names
 * 1) devices, and 2)port definitions, port connections
 *
 * ----------------------------------------------------------------------------
 */
char *
ntlNodeNameNoAlias(NodeRecord * node)
{
    NLabelList * cur_llist;
    static char name[BUFSIZ];

    ASSERT((node != NULL), "ntlNodeNameNoAlias called with null node");

    /* print 1st label in list for now
     * TODO, pick best name, here or when assigned
     */
    cur_llist = node->nrec_labels;

    if(cur_llist != NULL)
    {
	(void) sprintf(name, "%s",
			cur_llist->ll_label->lab_text);

	/* ll_uniq has incrementing number for duplicate node names */
	if(cur_llist->ll_uniq != 0)
	    (void) sprintf(name, "#%d", cur_llist->ll_uniq);
    }
    else
    {
	(void) sprintf(name, "N_%d", node->nrec_nodenum);
	/* MsgInfoF("node = %x\n", node); */
    }
    return (name);
}

/*
 * ----------------------------------------------------------------------------
 *
 * ntlOutputSbcktDecl --
 *
 * outputs the .sbckt line for a celldef into file f
 * first, the sbckt text, followed by the cell name
 * then, the ports
 * there are 2 cases based on using globals flag
 * if using globals, then global ports are not output in sbckt line 
 * (the .global line is used instead)
 * otherwise, treat globals exactly the same as other ports
 * --print them in the port list 
 * and multiple port nodes with the same name get unique suffixes
 *
 * .SUBCKT line format is 
 * ".SUBCKT" name [ports]
 *
 * ----------------------------------------------------------------------------
 */

void
ntlOutputSbcktDecl(CellDef * cd, 
		   FILE * f)
{
    Port * port;

    fprintf(f, "\n");
    ntlCurLineLen = 0;

    if(ntlOutputAsComment == TRUE)
	ntlPrintItem(f, "* .SUBCKT", FALSE);
    else
	ntlPrintItem(f, ".SUBCKT", TRUE);

    /* celldef name */
    ntlPrintItem(f, cd->cd_name, ntlOutputAsComment);

    for (port = (Port *)cd->cd_portList; 
	 port;
	 port = port->po_next)
    {
	/* don't output if port marked as feedthru element*/
	if((port->po_flags & NTL_PORT_FT_ELEM )
	    /* skip global ports if ntlUseGlobals is true */
	    || ((port->po_node->nrec_type == LAB_GLOBAL) && ntlUseGlobals))
	    continue;
	ntlPrintItem(f, ntlNodeName(port->po_node), ntlOutputAsComment);
    }
    fprintf(f, "\n");
}



/*
 * ----------------------------------------------------------------------------
 *
 * ntlOutputInstancesFn --
 *
 * called for each celluse in parent celldef
 * outputs each element of arrayed instances as a separate instance
 * always returns 0
 *
 * !!!! need to account for array overlaps
 *
 * ----------------------------------------------------------------------------
 */
int
ntlOutputInstancesFn(CellUse * use, 
		     FILE * f)
{
  int i, x, y, xlen, xoff, yoff, xlo, xhi, ylo, yhi;
    int element;
    PortConnector * connector;
    NodeRecord * connection = NULL;
    Port * port, * port2;
    int numPorts;
    int labType;
    static char	outStr[80];

    /* dont output if def's ports are all fts */
    /* also, skip if netlist with parent flag is set */
    if( (  use->cu_def->cd_flags & (CD_ALLFEEDTHRUS | CD_NETLIST_WITH_PARENT))
	|| use->cu_def->cd_portCount < 2)
	return(0);

    /* clear checked flag for next time  */
    use->cu_flags &= ~CU_NTL_CHECKED;
    use->cu_flags &= ~CU_NTL_CHECKED2;

    /*
     * for each array element, in case instance is arrayed
     * each array element has associated with it
     * an array of (NodeRecord *)
     * to contain its port connections
     * this array is numPorts in length
     */
    numPorts = use->cu_def->cd_portCount;
    if(DBIsArray(use))
    {
      xlen = ABS(use->cu_xhi - use->cu_xlo) + 1;	

      /* find index of element at LL corner
       */
      xoff = MIN(use->cu_xlo, use->cu_xhi);
      yoff = MIN(use->cu_ylo, use->cu_yhi);

      xlo = use->cu_xlo;
      xhi = use->cu_xhi;
      ylo = use->cu_ylo;
      yhi = use->cu_yhi;
    }
    else
    {
      xlen = 1;
      xoff = 0;
      yoff = 0;
      xlo = xhi = 0; 
      ylo = yhi = 0; 
    }

    /* element traversal may be in any direction
     *
     * xoff and yoff are used so that indexes start at 0,0
     */
    for(x = use->cu_xlo; x <= use->cu_xhi; x = x+1)
      for(y = use->cu_ylo; y <= use->cu_yhi; y = y+1)
      {
	/*
	 * print instance name in celluse 
	 * plus array index, if not 1st element
	 */

	ntlCurLineLen = 0;

	if(((x-xoff) == 0) && ((y-yoff) == 0))
	    sprintf(outStr, "X%s", use->cu_id);
	else
	    sprintf(outStr, "X%s_%d_%d", use->cu_id, use->cu_xlo, use->cu_xhi);

	ntlPrintItem(f, outStr, FALSE);

	/*
	 * get pointer to connections for this array element
	 */
	element =  (xlen * (y-yoff) + (x-xoff));

	connector = (PortConnector *) use->cu_elementConns[element];

if(ntlVerbose)
    MsgInfoF("OutputInstances: use %s of celldef %s, connector = 0x%x, number of def ports = %d, number of connections = %d\n", 
	use->cu_id, use->cu_def->cd_name, connector, numPorts, 
	connector == NULL ? -1 : connector->pc_numAlloced );
	/*
	 * traverse ports in definition,
	 * rather than simply traversing port connections
	 * so can check for globals
	 */
	for (port = (Port *)use->cu_def->cd_portList, i = 0;
		port;
		port = port->po_next, i = i+1)
	{
if(ntlVerbose)
    MsgInfoF("output port %d\n", i);
	    labType = port->po_node->nrec_type;
	    /* skip global ports if ntlUseGlobals is true
	     *
	     * NOTE: this should not be necessary, if the flag was set,
	     * then no global ports were created !!
	     */
	    if(port->po_flags & NTL_PORT_FT_ELEM )
	    {
if(ntlVerbose)
    MsgInfoF("skipping FT port %s\n", ntlNodeName(port->po_node));
		continue;
	    }
	    if((labType == LAB_GLOBAL) && ntlUseGlobals)
	    {
if(ntlVerbose)
    MsgInfoF("skipping global port %s\n",  ntlNodeName(port->po_node));
		continue;
	    }

	    /*
	     * There are 3 cases that indicate that no connection was found
	     * 1- the pointer to element's list is NULL,
	     * so the list was never allocated
	     * since no connections were found to any port
	     *
	     * 2- the list was allocated,(there is at least one connected port)
	     * but this connection is NULL
	     *
	     * 3- the connection of interest is past the A end of
	     * the connections that have been allocated for this instance
	     *
	     * In either case no connection to this port was found, 
	     * Input ports are connected to GND,
	     * Inouts and outputs are connected to uc_net_#
	     */
	    if((connector == (PortConnector *) NULL) 
			|| (i >= connector->pc_numAlloced))
		connection == (NodeRecord *) NULL;
	    else if (((connection = connector->pc_conns[i]) == (NodeRecord *) NULL) 
		    && (port->po_flags & NTL_PORT_FT_HEAD))
	    {
/*
if(ntlVerbose)
    MsgInfoF("searching FT list starting with port %d\n", i);
    */
		/*
		 * look for non-null connection to associated FT port
		 */
		for (port2 = port->po_nextFt; port2; port2 = port2->po_nextFt) 
		{
/*
if(ntlVerbose)
    MsgInfoF("FTport is %d\n", port2->po_portnum);
    */
		    if(port2->po_portnum >= connector->pc_numAlloced)
			continue;
		    if ((connection = connector->pc_conns[port2->po_portnum]) != (NodeRecord *) NULL)
			break;
		}
	    }

	    if (connection != (NodeRecord *)NULL)
		ntlPrintItem(f, ntlNodeName(connection), FALSE);
	    else
	    {
		MsgInfoF ("Port %d of instance %s ", i, use->cu_id);
		if(x!= 0 | y != 0)
		    MsgInfoF("(%d, %d)",x, y);
		MsgInfoF ("of celldef %s is unconnected: using ""uc_net_%d""\n",
		     use->cu_def->cd_name, ntlUnconnectCount);
		sprintf(outStr, " uc_net_%d", ntlUnconnectCount++);
		ntlPrintItem(f, outStr, FALSE);
		}
	}
	/* after port connections,  output celldef that this is an instance of */
	ntlPrintItem(f, use->cu_def->cd_name, FALSE);
	fprintf(f, "\n");
    }
    return (0);
}



/*
 * ----------------------------------------------------------------------------
 *
 * ntlOutputGlobals --
 *
 * outputs a single .GLOBAL line for globals nodes in design
 * they are found in each celldef, rooted in cd->cd_portnames
 * each unique string is only output once
 *
 * Results:
 *	None.
 *
 * Side effects:
 *
 * ----------------------------------------------------------------------------
 */

void
ntlOutputGlobals(Stack * stack, 
		 FILE * f)
{
    bool hashInitialized = FALSE;
    char *text;
    register Port *port;
    register NLabelList *nl;
    register HashEntry *he;
    NodeRecord *HashVal;
    NodeRecord badLabel;
    HashTable labelHash;

    CellDef * def;

    struct stackBody * sb;
    int i;
    bool first = TRUE;

    /* for all celldefs
     * traverse the global node list
     * output .global line  
     * and each unique name only once
     * the hash value is set to the the first node  
     * to indicate that the name has already been output
     */

    /* the outer loop comes from EnumStack
     */
    fprintf(stderr,
	    "TODO ntlOutputGlobals, don't expose stack code guts!\n");

    for(sb=stack->st_body; sb!=(struct stackBody *) NULL; sb=sb->sb_next)
        for(i=0; i<=stack->st_incr; i++)
        {
            if( &(sb->sb_data[i]) == stack->st_ptr ) goto done;
	    def = (CellDef *)sb->sb_data[i];

	    for (port = (Port *)def->cd_portList; 
		port && port->po_node->nrec_type == LAB_GLOBAL; 
		port = port->po_next)
	    {
		text = ntlNodeNameG(port->po_node);
		if (!hashInitialized)
		    HashInit(&labelHash, 32, 0), hashInitialized = TRUE;
		he = HashFind(&labelHash, text);
		HashVal = (NodeRecord *) HashGetValue(he);
		if (HashVal == (NodeRecord *) NULL)	/* not printed yet */
		{
		    HashSetValue(he, (ClientData) port->po_node);
		    if(first)	/* print .global at beginning of line */
		    {
			(void) fprintf(f, ".GLOBAL" );
			first = FALSE;
		    }
		    (void) fprintf(f, " %s", text );
		}
	    }
	}
done:
    if(first == FALSE)	/* only need cr if printed something */
	(void) fprintf(f, "\n" );

    if (hashInitialized)
	HashKill(&labelHash);
}

/*
 * ----------------------------------------------------------------------------
 *
 * ntlOutputNodes --
 *
 * these are comments for now
 * also for now, output only name from the first label in label list
 *
 * separately, may need to output all names for each node, if not global
 * how to report each name only once ??
 *
 * ----------------------------------------------------------------------------
 */
void 
ntlOutputNodes(CellDef *cd, 
	       FILE * f)
{
    Port * port;
    NodeRecord * node;

/* dont print ports, they are declared in the cell definition
    if(cd->cd_portList)			
	(void) fprintf(f, "*      Ports\n" );

    for (port = (Port *) cd->cd_portList; port; port = port->po_next)
    {
	(void) fprintf(f, "*        %s        (%s)", ntlNodeName(port->po_node),
						    ntlNodeNameNoAlias(port->po_node));
	if(port->po_node->nrec_type == LAB_GLOBAL)
	    (void) fprintf(f, "        (GLOBAL)", ntlNodeName(port->po_node));
	(void) fprintf(f, "\n");
    }
*/

    /* omit header if list is empty */
    if(cd->cd_nodes)
	(void) fprintf(f, "*      Nodes    	(before alias)\n" );

    for (node = (NodeRecord *) cd->cd_nodes; node; node = node->nrec_next)
    {
	(void) fprintf(f, "*        %s", ntlNodeName(node));
	if (node->nrec_alias != NULL) 
	    (void) fprintf(f, "    \t(%s)\n", ntlNodeNameNoAlias(node));
	else
	    (void) fprintf(f, "\n");
    }
}
