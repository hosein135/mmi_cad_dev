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



/* netlist.h -
 *
 * Defines the (exported) interface to the netlist module.
 *
 */


#ifndef _NETLIST
#define _NETLIST

/* Netlister warnings */
#define NTLWARN_DUP     0x01    /* Warn if two nodes have the same name */
#define NTLWARN_DUPGLOBAL 0x02  /* Warn on dup names, even for global labels */

#define NTLWARN_LABELS  0x04    /* Warn if connecting to unlabelled subcell
                                 * node.
                                 */
#define NTLWARN_FETS    0x08    /* Warn about badly constructed fets */

#define NTLWARN_ALL     (NTLWARN_DUP|NTLWARN_DUPGLOBAL|NTLWARN_LABELS|NTLWARN_FETSmv )

extern int NtlDoWarn;           /* Bitmask of above */

/* Extractor options */
#define NTL_DOADJUST            0x01    /* Extract hierarchical adjustments */
#define NTL_DOCAPACITANCE       0x02    /* Extract capacitance */
#define NTL_DOCOUPLING          0x04    /* Extract coupling capacitance */
#define NTL_DORESISTANCE        0x08    /* Extract resistance */
#define NTL_DOLENGTH            0x10    /* Extract pathlengths */
#define NTL_DOALL               0x1f    /* ALL OF THE ABOVE */

extern int NtlOptions;          /* Bitmask of above */

/* called at startup time to register ntl tcl commands and variables */
extern void NtlTclInit(Tcl_Interp *interp);

#endif _NETLIST



/*
 * Global Variables used to define Technology
 * filled in by Tcl
 */

char * ntlTech_name;

    /*
     * Connectivity for determining electrical nodes.
     * This should be essentially the same as DBConnectTbl[].
     */
TileTypeBitMask	 ntlTech_nodeConn[NT];

    /*
     * Connectivity for determining transistors.
     * Each transistor type should connect only to itself.
     * Nothing else should connect to anything else.
     */
TileTypeBitMask	 ntlTech_transConn[NT];


/* Transistors */

    /* Name of each transistor type as output in .ext file */
char		*ntlTech_transName[NT];

    /* Contains one for each type of fet, zero for all other types */
TileTypeBitMask	 ntlTech_transMask;


    /*
     * Mask of the types of tiles that connect to the channel terminals
     * of a transistor type.  The intent is that these will be the
     * diffusion terminals of a transistor, ie, its source and drain.
     */
TileTypeBitMask	 ntlTech_transSDTypes[NT];

    /*
     * Maximum number of terminals (source/drains) per transistor type.
     * This table exists to allow the possibility of transistors with
     * more than two diffusion terminals at some point in the future.
     */
int		ntlTech_transSDCount[NT];

    /*
     * Each type of transistor has a substrate node.  By default,
     * it is the one given by ntlTech_transSubstrateName[t].  However,
     * if the mask ntlTech_transSubstrateTypes[t] is non-zero, and if
     * the transistor overlaps material of one of the types in the
     * mask, then the transistor substrate node is the node of the
     * material it overlaps.
     */
char		*ntlTech_transSubstrateName[NT];
TileTypeBitMask	 ntlTech_transSubstrateTypes[NT];

