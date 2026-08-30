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
 * defInt.h --
 *
 * This file defines constants and datastructures used internally by the 
 * def module, but not exported to the rest of the world.
 */
#ifndef _DEFINT
#define _DEFINT


typedef struct DfNetDef_s DfNetDef;
typedef struct DfNetUse_s DfNetUse;
typedef struct DfTCell_s DfTCell;
typedef struct DfCellInfo_s DfCellInfo;

// EXTRACTION CONTROL:
// Extraction is controlled by marking cells to be extracted.
// The special cell types are: vcell, always_extract, and ignore.
//	vcell cells: only labeled paint is searched.
//		These are typically the leaf cells in verilog, also corresponding
//		to stdcells or other macrocells.
//	always cells: these are always extracted unless they are hiarchically below
//		a cell that was not extracted.  This should be the list of vias
//		used inside vcells, plus any other cells inside vcells that may
//		need to be traced to establish connectivity inside a vcell cell
//		from a label to a hierarchical connection.
//	Ignore cells are just not extracted.
//		You could use this for cells that you want the netlister to return an error
//		if it finds a connection to these cells, instead of wasting time extracting them.
//		This might also be useful to extract only part of a chip.
//	In cells below vcell cells, always_extract cells are traced if they
//	are immediate descendents of the vcell cell, but all other cells
//	are unextracted, and it is an error to connect to them.
// It is OK to not mark any cells specially.  In that case, all information from
// all cells is extracted.
// TODO: Do we report bad connections inside ignored cells?
//

// Extraction directives for both CellDefs and tcells.
// The extraction type for tcells is determined by a combination of
// the tcell position in the tcell hierarchy, and the extraction
// directive on the corresponding cell def.
// The dfext_hier type appears only in celldefs, never tcells.
typedef enum {
    dfext_null,		// Illegal value
    dfext_stop,		// Stop extraction at this cell, except for dfext_all cells.
    dfext_all,		// Extract, even if sub-leaf (used for vias)
    dfext_none,		// Never extract  (optional warning if accidental connection occurs to contents.)
    dfext_hier		// Default type for celldefs, but never appears in tcells.
		    // Extract only if above a leaf cell.  For tcells, this type will
		    // be changed to dfext_all or dfext_none, depending on if it is above
		    // or below a stop cell.
} DfExtCellType;



// During DEF writing, all cells must be marked as one of the following types.
// Meaning of types is given by this table.  are treated specially:
//
//  DefCellType:     Goes in DEF section:      Labels in cell are:      Typical ExtCellType:
//  ------------     --------------------      ------------------       -------------------
//   component       COMPONENTS                Pin names(if dfi_extPins) stop
//   Hier            none                      Net names                 hier
//   Netvia          NETS/SPECIALNETS          ignored                   all
//   Discard         none                      ignored                   none
//
// Additionally, each cell has a bit that indicates whether Paint tiles in that
// cell should appear in the NETS section instead of SPECIALNETS (the default.)
// 
// Names of cell instances and pins are output as full hierarchical names, however,
// cells marked with the FOO bit are not included in the path.
//
// TODO: Might want the ability to control messages about connections to discard cells.
typedef enum {
	dfd_null, dfd_netvia, dfd_component, dfd_discard, dfd_hier
} DfDefCellType;


// This struct is hung off the Celldef->cd_client field.
struct DfCellInfo_s {
    unsigned int dfi_tag:8;	// Always DFCellInfoTag for error checking.
			    	// Can detect if some other client changes def->cd_client.
    DfExtCellType dfi_type:4;	// Specifies whether verilog cell,, VIA, or hierarchical cell.
    DfDefCellType dfi_deftype:4;	// see above
    unsigned int dfi_extPins:1;	// If set, pins on this component will be extracted.

    unsigned int dfi_didMakeConnect:1;	// used during connectivity proessing.
    unsigned int dfi_didCellMask:1;	// used during connectivity proessing.
    unsigned int dfi_didStep1:1;	// used during connectivity proessing.
    unsigned int dfi_dirtyPlanes:1;	// The metal planes in this cell have been modified.

    unsigned int dfi_hierIgnore:1;	// If set, the name of this cell is not included in hiearchical names.
    unsigned int dfi_sectionNets:1;	// If set, paint from this cell goes in NETS, not SPECIALNETS>
    unsigned int dfi_error1:1;		// Set when error occurs.
    unsigned int dfi_error2:1;		// Set when error occurs.
    unsigned int dfi_error3:1;		// Set when error occurs.

    DfNetDef *dfi_netdefs;		// Array of netdefs for this celldef.
    int dfi_netcnt;			// Number of netdefs == number of netuses.
    int dfi_netsize;		// Current size of netdef array
    int dfi_instcnt;		// Total number of instances inside def, including array elements.
    DfTCell *dfi_tcells;	// Linked list of tcells of this def, for non-LEF cells only.
	    // Note: alternatives:
	    // 1. could traverse entire hiearchy looking for them.  This might not be too
	    // bad if this never happens for LEF cells.
	    // 2. could traverse list of uses of def, and try to find corresponding tcells,
	    // possibly by going up to the root, then back down through the tcells.
    TileTypeBitMask dfi_mask;	// Mask of all metal types in this def, or any contained kid.
    char *dfi_vianame;		// If this cell should go in the NETS/SPECIALNETS section as a
				// via, set this to the vianame to use there.
    char *dfi_vianame_r90;	// Rotated via name.
};
#define DFCellInfoTag	0xe4	/* Totally invented */


// The net number is implicit in the array offset of this
// element in the CellDef->dfi_netdefs array.
struct DfNetDef_s {
    //CellDef *dfn_celldef;	// : This field is not required any more.
    Tile *dfn_tiles;	// List of tiles comprising this net, linked
			// through the tile client field.
    Label **dfn_labels;	// Pointer to an allocated array of pointers to labels.
			// Array ends with a 0 entry.
    void *dfn_cap;	// Area/capacitance info.
};


// The net number is implicit in the array offset of this
// element in the TCell->dft_netuses array.
// The union is used for multiple things.
// While the netuses are being hooked up, which is inside DFConnectCreate,
// the field is used for the color of this netuse chain.
// The color is an optimization specifically for power vias,
// or for any case where there are electrical loops.
// Consider hooking up a power via without color:  The via is probably electrically connected
// to two other layers, which will cause two calls to dfConnectNetuses.
// The first connection is easy because the netuse chain in the via
// is only one long.  For the second connection, we traverse the entire chain of netuses
// for this power net just to discover that this via netuse is already on the list,
// so we dont need to to danything.
// With color: the first call to dfConnectNetUses finds the netuse chain for the via is smaller,
// and colors it whatever color the netuse chain for power was.  The second
// call to dfConnectUses sees that both nets have the same color, and just returns instantly.
// Before adding colors, the code was spending over 90% of its time in dfConnectNetUses
// for designs with lots of power vias.
// At the end of DFConnectCreate, the union field is set to point to the tcell
// that owns this array of netuses, so that we can traverse a linked list of
// netuses and figure out who owns them.
// When traversing all the NetUses in the design, we need a bit to tell whether we
// have seen a NetUse before - the low bit of dfu_flag is used AT THE SAME TIME
// as the dfu_tcell field.
struct DfNetUse_s {
    union {
	int dfu_flag;		// WARNING: The low bit of this flag is set at the same time
				// as dfu_tcell is used as a pointer.
	DfTCell *dfu_tcell;
	DfNetUse  *dfu_dst;	// Used temporarily during cloning.
	int dfu_color;		// Electrically connected nets receive the same color.
    } u;
    DfNetUse *dfu_next;		// Next in linked list of all hierarchically connected nets.
};



// There is one TCell for each unique cell instance in the entire hierarchy,
// including both hierarchical and leaf (LEF) cells.
// Arrays of cells have one TCell for each array element.
// The client field of the CellUse is the index
// of the first element of the array of celluses
// in the dft_children array.
// The cell instance number is implicit in the array offset of this
// element in the Parent->dft_children array.
struct DfTCell_s {
    unsigned int dft_tag:8;			// Always DFTCellTag for error checking.
    DfExtCellType dft_type:7;		// Extraction type.
    unsigned int dft_sub_stop:1;	// Set to 1 if hiearchically below a vcell.
    unsigned int dft_level:16;		// Hierarchical level.
    DfTCell *dft_parent;
    CellUse *dft_celluse;	    // The one represented by this TCell.
				    // Interestingly, this field is rarely accessed except
				    // to get the associated def.  The only time we actually
				    // use the client data in the use is when the celluse is found
				    // during a traversal of the max database.
    DfNetUse *dft_netuses;	    // Pointer to array.
    // The rest not used for leaf cells.
    struct DfTCell_s *dft_children;	// Pointer to array.
    DfTCell *dft_next;			// Next tcell of this CellDef type, for hierchical cells only.
					// Only needed for cloning.  Could eliminate this and just
					// search the entire tcell tree.
};
#define DFTCellTag	0xc8	/* Totally invented */



// Global variables used by extraction module.
struct dfGlob_s {
    // The name here is a misnomer, since the planes may include poly.
    TileTypeBitMask dfMetalMask;	// Has bit set for each plane we will extract, but not contacts.
    PlaneList *dfMetalPlanes;		// Planelist for above.
    DfTCell dfRootTCell;		// Head of tree of tcells.
    CellDef *dfRootDef;			// Root def we extracted.

    DfNetUse *dfcacheNU1, *dfcacheNU2;	// Two netuses that were connected together.
    int dfOptNoAbutCheck:1;	// Dont check verilog cells for abutment connections.
    int dfQuiet:1;			// If set, reduced error messages.
    int dfDebug;			// Debug flags.

    int dfMem;				// Memory used.
    int dfNetDefCnt;			// Statistic keeping.
    int dfNetUseCnt;			// Statistic keeping.
    int dfTCellCnt;			// Statistic keeping.
    int dfNetUseConnections;		// Statistic keeping: number of hierarchical connections.
    int dfOverlapCnt;			// Statistic keeping: overlapping cells checked.
    int dfColor;			// Generates unique colors for netuses.
    int dfUnconNetCnt;			// Count of unconnected nets (not just a statistic - used to create unique net names).
    int dfDefFactor;			// Factor to multiply max coord by to get def coord.
    FILE *dfLogfd;			// Log file descriptor.
};
extern struct dfGlob_s dfGlob;



int DfConnectInit(CellDef *rootDef,char*layers);
int DfConnectTest();
void DFConnectTerm();
void DfSetCellExtType(CellDef *cdef,DfExtCellType exttype);
void DfSetCellDefType(CellDef *cdef,DfDefCellType deftype,int extPins);


#endif _DEFINT


