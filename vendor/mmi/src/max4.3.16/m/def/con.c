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

// EXTRACTOR DOCUMENTATION:
//
// CONNECTIVITY EXTRACTOR RESTRICTIONS:
//	- Contacts and cuts must be covered with metal in the cell in which they occur.
//	Ie, a naked cut in a cell will not be detected if metal in another cell passes over it.
//	This error condition is not detected.
//	- If there is a box label, it chooses any tile under the box.  If there are multiple
//	tiles that are electrically unconnected under a box label, the user gets what they deserve.
//	This error condition is not detected.
//	- Connections to verilog cells can occur only at metal electrically connected to a label.
//	The code traces connections through vias, but not through other sub-cells.
//	This restriction is actually in the def writer, not the connectivity extractor.
//	- Labels must have the correct type for the paint they are over, and must be
//	over that type of tile in the cell in which they occur.
//	- I have removed the restriction that abutment connections in verilog cells must 
//	be covered by metal in the parent cell.  Any type of abutting connection is ok.
//
//
// Labels may have DEF properties attached, of the form:
//	( +FIXED | +ROUTED | +COVER ) [ +<prop> [: <value>]
// For example: label foo+ROUTED+USE:CLOCK
// The property part of a label must be the same on all electrically connected labels.
// Note: comment labels are ignored.  Must be a local global or i/o label.
//
// Labels in cells that are marked as def COMPONENTS are output as pins in the
// SPECIALNETS section.  Labels in hierarchical cells are printed out as aliases.
//
//
// Max db_prop CellDef properties used by the DEF writer:
//
//	def_via_name	 name	- name of via to be used in NETS/SPECIALNETS section.
//	def_via_name_r90 name	- name of rotated via to be used in NETS/SPECIALNETS section.
//	def_hier_ignore 0/1  - this cell name is not included in hierarchical names.
//	def_section 	NETS/SPECIALNETS	- paint in this cell should go in the NETS section
//			(default is SPECIALNETS)  - This is not implemented!!
//
// Cells are currently marked "PLACED".  Later we may add a property on a cell
// that specifies FIXED, COVER, UNPLACED, any other props on the cell.
//
// If two cells of the same type are exactly on top of each other, one of them is discarded,
// regardless of orientation.  This mimics max flattening behavior, so the resulting def
// file could be read back into max and then re-written without changing the number
// of components.  But I am not sure this is really the desired behavior.
//
// Functions:
// DFConnectInit - call first, to init data-base.
//    After DFConnectInit, use DfSetCellExtType to set the dfext type for each cell.
//    Cells that are unmarked are fully extracted.  Cells marked "dfext_none".
//    are not extracted.  Cells marked dfext_stop are extracted, but nothing below them,
//    except cells marked dfext_all.  That is, dfext_all trumps dfext_stop.  Below a stop
//    cell, extraction stops at the first cell that is not marked dfext_all.  This is meant
//    to allow extraction to proceed through vias inside stop cells.  However, this is not
//    fool proof.  For example, there could be connectivity through a fet contact, or the
//    router could even connect to the fet contact, so you could make an argument for
//    extracting fets, too.  Also, connectivity could be made through other contained stop cells,
//    and we dont handle that either.  The "stop" feature is just to save time and memory.
//    If you are worried about these things you should do a full extraction.  Alternatively,
//    substitute abstract LEFs for the stop cells.  An alternative implementation would
//    be to flatten, which is essentially equivalent to using abstract lefs.
// DFConnectCreate - creates the connectivity database.
// DFConnectTerm - destroys the connectivity database.
// See also: functions below to do DEF files.
// 

#define DF_COLORS 1
#define DF_DEBUG 1


//***********************************************************************
// WRITE-DEF TODO
//***********************************************************************

// Must connect unconnected local labels.  Must connect all local labels throughout
// the entire design.

// TODO: dfWarn messages go to def file!!!  Modify msg to count warnings, automatically
//	cut off after count elapsed.  Make count a tcl variable, set to -1 to not cut off warnings.
//	(I think this is done now)

// TODO: Output NETS connectivity from nl.

// TODO: Add extract type to check and report connections, but not extract.
// IDEA: Could do a normal sel_net when you find a connection into a stop or sub-stop cell,
//       to find if it is hooked to a label or not.  This would save all the memory
//       for TCells for fets.  Basically, you could do the extraction on demand by
//       linking together all the tiles found in the stop-cell during a sel_net.
//	 Can still preallocate the labeled tiles just like now.

// BUG: extracting ~/work/chorus/full/chorus, got:
//	Cell PRXREF label VD33:: label is not over a tile
//  but it is on m1 and looks fine!

// TEST: Modify SearchContext so if no area, go through list of uses - must use kids for this.
//	Test this by writing sp_search_cells!

// TODO: Naked Labels, ie labels that are not over paint in the cell they are in
//	Search them by finding a label having a netdef with dfn_tiles==NULL.
//	This came up in chorus:
//	The labels are on m1, and are actually over a chorus_VIA1 cell which has m1 inside.
//	Cell chorus_smaller label io_hspi|net_92: label is not over a tile
//	Cell chorus_smaller label net_100: label is not over a tile

// TODO: add a mode to extract only up to stop cells, not through stop cells, and use
//	it to write def files without connectivity, only tiles in hierarchical cells.
//	Would be useful if cell too big to extract connectivity.

// TODO: Separate extraction and def_out into completely separate lists:
//	def_con_init: stop_cells, all_cells, ignore_cells (just for optimization)
//		ignore_abutting_cells (make it a list)
//		Add: ignore_label_names - do not extract this label if seen in a stop-cell.
//		(This is an extraction optimization for vdd/gnd.)
//	def_output: components and vias


// TODO: Dont have to clone a sub-tree if there are no connections in the sub-tree.  (eg: a via)

// TODO: Add a printout of the cell names and types.

// TODO: Output the vias in the VIA section of the DEF file
// 	with their origin translated to the center!  Or, warn if origin != center.

// TODO: Implement cell prop "def_section" to specify whether paint in this cell
//	goes in the NETS or SPECIALNETS section.
//	(Or should it be a comment label?  Probably not, because it is an MMI
//	specific thing invisible to the def file itself, so a cell prop is best.)
//	Default is to put all tiles in the SPECIALNETS section.

// TODO: Make sure ext_none cells are handled properly.  Add a bit to specify
//	whether we check and report connections to them, or just completely ignore them.

// TODO: Use user bbox - set to layers of interest to us.

// TODO: Have an option to get the vcell list from nl libcell list.

// TODO: Test option not to look for abutting connections between verilog cells.

// TODO: Add error check of overlapping sibling PRB.  This is not a DEF thing.

// TODO: Might want to add an option to not bother to extract labels for certain cells,
//	notably via cells.  This wont save much time, but it would help detect unlabeled metal,
//	because if there is a via, the net is labeled, so no warning!
//	NO: Take this out.

// TODO: set dfi_vianame some other way beside a cell property.  Or, default it to the cell name,
//	so cells dont have to be modified.  (Doesnt work for vias!)  Maybe make the names up in C
//	instead of tcl.  Could still use the prop, if set.


// TODO: Add options to control extraction of vdd/gnd, but not needed until extractor written.

//***********************************************************************
// NON-DEF TODO
//***********************************************************************

// READ DEF:  Specify three cells (which may be the same) for NETS, SPECIALNETS, and COMPONENTS.
// The NETS and SPECIALNETS cells will have a max db_prop set
// to not be included in hierarchical names.

// Note: Select_net is rechecking all cells from the root each time!



//***********************************************************************
// DONE
//***********************************************************************

// DONE: Add colors to netuses, use in dfConnectNetUse.

// DONE: Add a log file for messages, esp. "label is not over a tile"!

// DONE: Detect exactly overlapping components and only output one of them.
//	print a warning.  Happens for vias, eg, in chorus:clk_c_b_tree cell, which exactly
//	overlaps adjacent cells so vias on the edge overlap.

// DONE: Could save alot of memory by squeezing the noext tcells out of the dft_children array.
//	Currently, there is a tcell for every single via and fet inside every stdcell.
//	Would have to set use->cu_client to -1 or something to indicate no tcells exist.
//	Can do this inside vcells, because we NEVER look their children.
//  DONE 11/5/01.  May crash.

// DONE: Realloc netdefs when done to make smaller.
//       DONE: set chunk size to 1.  Could improve.

// OLD: To detect all connections to unlabeled paint inside a verilog cell,
//	you must either flatten the WHOLE THING (not just the nets of interest)
//	or always trace hierarchy below verilog cells.  If detection is an option,
//	could set a flag on celluses that says whether to search their contents or not.
//	To flatten verilog cells, could use DBCopyConnect.  Could maybe copy into
//	a group to make it easier to delete later, but I'm using the group id for netdef.
//	Must trace through vias inside lef - must implement by flattening vias, to make
//	sure there is paint in the lef cell surrounding the vias.


// DONE: Mark tcells that are inside a verilog leaf cell.  Note that a leaf cell
//	could contain other leaf cells.
//	(Done?)

// DONE: Check the dfext type in dfConChildren - fix this up so the hierarchical extraction
//	stops at the right level.  Must work out interaction between user options.
//	(Done?)

// DONE: Mark LEF/VIA files from a list of names of cells. (Done?)

// DONE: Shorted labels in a verilog cell will result in a netdef with a NULL paint pointer.
//	Make sure this doesnt crash.

// DONT: Use parent field to do the CopyNetUseTree.
//	Did not work!!!


#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include "magic.h"
#include "database.h"
#include "databaseInt.h"
#include "geometry.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "layout.h"
#include "database.h"
#include "databaseInt.h"
#include "message.h"
#include "signals.h"
#include "utils.h"
#include "units.h"
#include "special.h"
#include "def.h"
#include "defInt.h"

#define INLINE __inline__

//static jmp_buf jmp_on_interrupt;

#define DEF_VCELL_OPT 0		/* This is not working */

#define assert(e) ASSERT(e,0)


struct dfGlob_s dfGlob = {0};

// Forward decls
static int dfMakeBothConnect(DfTCell *fcell);
CellDef *DfTCell2Def(DfTCell *fcell);	


/***********************************************************************/
/* Utility Functions */
/***********************************************************************/

#define DFMALLOC_OVERHEAD 8  /* Used only for accounting */

// Track how much memory this module uses.
static void *dfMalloc(int size)
{
    char *foobar;
    dfGlob.dfMem += size + DFMALLOC_OVERHEAD;
    MALLOC(unused,foobar,size);
    return foobar;
}

static void *dfCalloc(int size)
{
    char *foobar;
    dfGlob.dfMem += size + DFMALLOC_OVERHEAD;
    CALLOC(unused,foobar,size);
    return foobar;
}


// Reallocate memory at ptr.  If ptr is NULL or oldsize==0, allocate new.
// Both old and new sizes must be specified.  Size may grow or shrink.
// If fclear, clear any newly allocated memory.
static void *dfRealloc(void *ptr,int oldsize,int newsize,int fclear)
{
    void *new;
    new = dfMalloc(newsize);
    if (ptr) {
	memcpy(new,ptr,MIN(newsize,oldsize));
	FREE(ptr);
    } else {
	dfGlob.dfMem += DFMALLOC_OVERHEAD;
    }
    dfGlob.dfMem += (newsize-oldsize);
    if (fclear && newsize > oldsize) {
	memset((void*) ((char*)new+oldsize),0,newsize-oldsize);
    }
    return new;
}

void dfWarn(char *fmt, ...)
{
    va_list args;
    va_start(args,fmt);

    //if (dfGlob.dfLogfd) { vfprintf(dfGlob.dfLogfd,fmt,args); }

    if (! dfGlob.dfQuiet) {
	MsgWarnV(fmt,args);
    }
    va_end(args);
}

static void dfPrintStatus()
{
    printf("\rsegments: %d connections: %d overlapping cells: %d   \r",
    dfGlob.dfNetDefCnt, dfGlob.dfNetUseConnections, dfGlob.dfOverlapCnt);
    fflush(stdout);
}


static void dfPrintStats(char *msg)
{
    MsgInfoF("%s: Connectivity Database Statistics:\n",msg); 
    MsgInfoF("	Total Memory: %dK; TCells: %d (%dK); NetDefs: %d (%dK)\n",
	dfGlob.dfMem/1000,
	dfGlob.dfTCellCnt, dfGlob.dfTCellCnt * sizeof(DfTCell)/1000,
	dfGlob.dfNetDefCnt, dfGlob.dfNetDefCnt * sizeof(DfNetDef)/1000);
    MsgInfoF("	NetUses: %d (%dK)  Connections: %d\n",
	dfGlob.dfNetUseCnt, dfGlob.dfNetUseCnt * sizeof(DfNetUse)/1000,
	dfGlob.dfNetUseConnections);
    //MsgInfoF("	Memory heap: %uK Count: %u\n", UtlsStatHeapSize()/1000,MallocNumMalloc - MallocNumFree);
}



// Print mask in legible format.
static void dfPrintMask(TileTypeBitMask *mask)
{
    TileType t;
    for (t = 0; t < TT_MAXTYPES; t++ ) {
	if (TTMaskHasType(mask,t)) {
	    MsgInfoF("%s ",DBTypeShortName(t));
	}
    }
    MsgInfoF("\n");
}


// Print planelist.
static void dfPrintPlaneList(PlaneList *pll)
{
    for (; pll; pll = pll->pll_next) {
	MsgInfoF("%s ",DBPlaneShortName(pll->pll_num));
    }
    MsgInfoF("\n");
}

/* Max transforms:
 *  a d =  1  0    0 -1    -1  0    0  1    1  0    0  1    -1  0    0 -1
 *  b e =  0  1    1  0     0 -1   -1  0    0 -1    1  0     0  1   -1  0
 * Tcl Orientation:
 *          ""     r90      r180    r270     fy     fx_r90    fx    fy_r90
 * Def Orientation:
 *          N       E        S       W       FS       FW      FN      FE
 *
 * The first four forms correspond to clockwise rotations of 0, 90,
 * 180, and 270 degrees, and the second four correspond to the same
 * four orientations flipped upside down (mirror across the x-axis
 * after rotating)
 * Note: you mirror across x-axis using the "y" command in max!
 */
int DFTrans2DefOri(Transform *trans)
{
    if (trans->t_a) {
	// non rotated transforms
	return (trans->t_a > 0) ?
	    ((trans->t_e > 0) ? DFDefOri_N  : DFDefOri_FS) :
	    ((trans->t_e > 0) ? DFDefOri_FN : DFDefOri_S);
    } else {
	// rotated transforms
	return (trans->t_b > 0) ?
	    ((trans->t_d > 0) ? DFDefOri_FW : DFDefOri_E) :
	    ((trans->t_d > 0) ? DFDefOri_W  : DFDefOri_FE);
    }
}


char * DFFixName(char *buf,char *name)
{
    char *cp, *bp = buf;
    for (cp = name; *cp; cp++) {
      switch (*cp) {
	    case '\\': strcpy(bp,"{BS}"); bp+= 4; break;
	    case '/':  strcpy(bp,"{FS}"); bp+= 4; break;
	    case '[':  strcpy(bp,"{LB}"); bp+= 4; break;
	    case ']':  strcpy(bp,"{RB}"); bp+= 4; break;
	    case ',':  strcpy(bp,"{CO}"); bp+= 4; break;
	    case '{':  strcpy(bp,"{LC}"); bp+= 4; break;
	    case '}':  strcpy(bp,"{RC}"); bp+= 4; break;
	    default: *bp++ = *cp; break;
	}
    }
    *bp = 0;
    return buf;
}


// Copy max name to buf, converting special character sequences
// back to the original characters in the verilog name.
char *DFUnfixName(char *buf,char *name)
{
    char *cp = name, *bp = buf;
    while (*cp) {
	if (*cp == '{') {    /* balance } for vi*/
	    if (strncmp(cp,"{BS}",4) == 0) { *bp++ = '\\'; cp += 4; continue; }
	    if (strncmp(cp,"{FS}",4) == 0) { *bp++ = '/'; cp += 4; continue; }
	    if (strncmp(cp,"{LB}",4) == 0) { *bp++ = '['; cp += 4; continue; }
	    if (strncmp(cp,"{RB}",4) == 0) { *bp++ = ']'; cp += 4; continue; }
	    if (strncmp(cp,"{CO}",4) == 0) { *bp++ = ','; cp += 4; continue; }
	    if (strncmp(cp,"{LC}",4) == 0) { *bp++ = '{'; cp += 4; continue; }
	    if (strncmp(cp,"{RC}",4) == 0) { *bp++ = '}'; cp += 4; continue; }
	}
	*bp++ = *cp++; 
    }
    *bp = 0;
    return buf;
}

// Return TRUE if the transform is a rotated one.
static int dfTransIsRotated(Transform *trans)
{
    return (trans->t_a == 0);
}



static char *dfDefLayerName(TileType type)
{
    static char layerbuf[100];
    char *layername = DBTypeShortName(type);
    int i;
    // Convert to upper case.
    for (i = 0; layername[i]; i++) {
	ASSERT(i < 99,"layer name too long");
	layerbuf[i] = toupper(layername[i]);
    }
    layerbuf[i] = 0;
    return layerbuf;
}


/***********************************************************************/
/* CellDef Access Functions */
/***********************************************************************/

DfCellInfo *DfCellDef2Info(CellDef *cdef)
{
    DfCellInfo *info = (DfCellInfo*) cdef->cd_client;

    if (info != NULL) { return info; }

    info = (DfCellInfo*) dfCalloc(sizeof(DfCellInfo));
    info->dfi_tag = DFCellInfoTag;
    info->dfi_type = dfext_hier;
    info->dfi_deftype = dfd_hier;
    info->dfi_extPins = 1;		// default is to extract all I/O pins everywhere.
    cdef->cd_client = (ClientData) info;
    return info;
}

DfNetDef *DfCellDef2NetDefs(CellDef *cdef)
{
    DfCellInfo *info = DfCellDef2Info(cdef);
    return info->dfi_netdefs;
}


// Restore cell def when we are all done.
// The cd_client field points to a CellInfo structure.
void dfCellDefRestore(CellDef *cdef)
{
    if (cdef->cd_client != 0) {
	FREE((void*)cdef->cd_client);
	cdef->cd_client = (ClientData) 0;
    }
}

// Return the mask of all metal types contained in cdef or any of its children.
// If there are more than one type per plane, all types corresponding to
// each metal plane will be set, ie, it is not exact in that case.
TileTypeBitMask *dfCellMask(CellDef *cdef)
{
    DfCellInfo *cellinfo = DfCellDef2Info(cdef);
    TileTypeBitMask *mask = &cellinfo->dfi_mask;
    TileTypeBitMask *kidmask;
    CellKid *kid;
    PlaneList *pll;

    if (cellinfo->dfi_didCellMask) return mask;
    cellinfo->dfi_didCellMask = 1;

    // Or in bits from kids.
    for (kid = cdef->cd_kids; kid; kid = kid->ck_next) {
	kidmask = dfCellMask(kid->ck_def);
	TTMaskSetMask(mask,kidmask);	// Its a bitwise OR operation.
    }

    // Check the planes in this def.
    for (pll = dfGlob.dfMetalPlanes; pll; pll = pll->pll_next) {
	// If a kid had this plane, we dont have to check ourself.
	// But its not worth it, because EmptyQ is very fast.
	if (! DBPlaneEmptyQ(cdef->cd_planes[pll->pll_num])) {
	    // OR in all tileTypes stored on this plane.
	    TTMaskSetMask(mask,&DBPlaneTypes[pll->pll_num]);
	}
    }
    // Take out the space tiles, which appear on all the planes.
    TTMaskClearType(mask,TT_SPACE);
    return mask;
}


// Allocate a new info structure if necessary.
// This can be done before starting the other extraction functions.
void DfSetCellExtType(CellDef *cdef,DfExtCellType exttype)
{
    DfCellInfo *cellinfo = DfCellDef2Info(cdef);

    // Do a little sanity checking.
    switch (exttype) {
    default: ASSERT(0,"bad ext type");
    case dfext_hier: case dfext_stop: case dfext_all: case dfext_none:
	break;
    }

    cellinfo->dfi_type = exttype;
}

void DfSetCellDefType(CellDef *cdef,DfDefCellType deftype, int extPins)
{
    DfCellInfo *cellinfo = DfCellDef2Info(cdef);
    //printf("DfSetCellDefType %s %d %d\n",cdef->cd_name,deftype,extPins);
    cellinfo->dfi_deftype = deftype;
    cellinfo->dfi_extPins = extPins;
}


// How many elements are in the array?  If not an array, return 1.
static int dfArrayElementCount(CellUse *use)
{
    if (DBIsArray(use)) {
	int xsize = abs(use->cu_xhi - use->cu_xlo) + 1;
	int ysize = abs(use->cu_yhi - use->cu_ylo) + 1;
	return xsize * ysize;
    } else {
	return 1;
    }
}


static int dfArrayNumber(SPSearchContext *spx)
{
    CellUse *use = spx->spx_use;
    int xlo = MIN(use->cu_xlo,use->cu_xhi);
    int xhi = MAX(use->cu_xlo,use->cu_xhi);
    int ylo = MIN(use->cu_ylo,use->cu_yhi);
    int yhi = MAX(use->cu_ylo,use->cu_yhi);

    //Is this better?
    //int xsize = abs(use->cu_xhi - use->cu_xlo) + 1;
    //int ord = abs(spx->spx_x - use->cu_xlo) + xsize * abs(spx->spx_y - use->cu_ylo);

    // x index varies faster.  See DBSrChildrenNested code.
    return (spx->spx_x-xlo) + (spx->spx_y-ylo) * (xhi-xlo+1); 
}

// Return -1 if the spx refers to a cell that is not being extracted.
static int UNUSED_dfSpxInstNum(SPSearchContext *spx)
{
    CellUse *use = spx->spx_use;
    int instnum = (int) use->cu_client;
    if (instnum >= 0 && DBIsArray(use)) { instnum += dfArrayNumber(spx); }
    return instnum;
}





/***********************************************************************/
/* Tile Access Functions */
/***********************************************************************/

#define FIRSTNETNUM 1	/* 0 is reserved so we can catch error of using undefined net num */


static void INLINE dfTileSetNextTile(Tile *tilep,Tile *next)
{
    tilep->ti_client = (ClientData)next;
}


static INLINE Tile *dfTile2NextTile(Tile *tilep)
{
    return (Tile*) tilep->ti_client;
}

// We use the group field for the point to the netdef to
// which the tile belongs.  This is not much of a stretch
// of imagination, because a valid use of groups would be to
// put each net in its own group.
static INLINE void dfTileSetNetNum(Tile *tilep,int netnum)
{
    // We could assert that ti_groups was NULL when we started.
    tilep->ti_groups = (ClientData)(netnum + FIRSTNETNUM);
}

static INLINE int dfTile2NetNum(Tile *tilep)
{
    int netnum = ((int) tilep->ti_groups) - FIRSTNETNUM;
    assert(netnum >= 0);
    return netnum;
}

static DfNetDef *dfTile2NetDef(CellDef *def,Tile *tilep)
{
    DfCellInfo *info = DfCellDef2Info(def);
    return & info->dfi_netdefs[dfTile2NetNum(tilep)];
}

// Restore max database tile when we are all done.
void dfTileRestore(Tile *tilep)
{
    tilep->ti_groups = 0;
    tilep->ti_client = (ClientData) MINFINITY;
}

// Restore entire tile plane.
void dfPlaneRestore(CellDef *cdef,int pl_num)
{
    Rect rect;
    SPTileEnum tpe;
    Tile *tile;

    /* Make sure we get everything */
    rect = *DBBBoxCellDef(cdef);
    GEO_EXPAND(&rect, 1, &rect);

    // Curently TT_SPACE tiles are not modified, so dont bother looking at them.
    SPTileEnumInit(&tpe, (Tile*)NULL, cdef->cd_planes[pl_num], &rect, &DBNonSpaceUserLayerBits, "dfPlaneRestore");
    while (tile = SPTileEnumNext(&tpe)) {
	dfTileRestore(tile);
    }
    SPTileEnumTerm(&tpe);
}


static Plane *dfTileType2Plane(CellDef *def, TileType type)
{
    return def->cd_planes[DBPlane(type)];
}




/***********************************************************************/
/* NetDef/NetUse Access Functions */
/***********************************************************************/

// Can set this bigger if needed.
#define DF_NETDEF_REALLOC_GROW_SIZE 1


int dfNewNetNum(DfCellInfo *cellinfo)
{
    if (++dfGlob.dfNetDefCnt % 1000 == 0) { dfPrintStatus(); }
    return cellinfo->dfi_netcnt++;
}


// Adds a netdef in the cell info structure associate with this celldef.
// You must do this when there is only one TCell corresponding
// to the celldef, ie, when cell is first traversed.  Therefore
// all cells must be traversed in a bottom-up order.
DfNetDef *UNUSED_DfNewNetDef(CellDef *cdef)
{
    DfCellInfo *cellinfo = DfCellDef2Info(cdef);
    DfNetDef *new;
    int netnum;
    
    if (cellinfo->dfi_netcnt >= cellinfo->dfi_netsize) {
	int oldsize = cellinfo->dfi_netsize;
	int newsize = cellinfo->dfi_netsize + DF_NETDEF_REALLOC_GROW_SIZE;
	cellinfo->dfi_netdefs = dfRealloc(cellinfo->dfi_netdefs,
	    oldsize*sizeof(DfNetDef),newsize*sizeof(DfNetDef),0);
	cellinfo->dfi_netsize = newsize;
    }

    netnum = dfNewNetNum(cellinfo);

    new = &cellinfo->dfi_netdefs[netnum];

    // Initialize new netdef.
    memset(new,0,sizeof(DfNetDef));
    //new->dfn_celldef = cdef;
    
    return new;
}


// Return the netuse.  The netuse array is allocated on demand.
DfNetUse *dfGetNetUse(DfTCell *fcell,int netnum)
{
    if (fcell->dft_netuses == NULL) {
	DfCellInfo *info = DfCellDef2Info(DfTCell2Def(fcell));
	int i; DfNetUse *nu;
        int netcnt = info->dfi_netcnt;
	assert(netnum < netcnt);

	fcell->dft_netuses = (DfNetUse*) dfMalloc(netcnt*sizeof(DfNetUse));
	dfGlob.dfNetUseCnt += netcnt;

	// Init array of netuses.
	for (i = 0, nu = &fcell->dft_netuses[0]; i < netcnt; i++, nu++) {
#if DF_COLORS
	      nu->u.dfu_color = dfGlob.dfColor++;
#else
	      nu->u.dfu_tcell = fcell;
#endif
	      nu->dfu_next = nu;	// init circular list.
	}
    }
    return &fcell->dft_netuses[netnum];
}


int DfNetDef2NetNum(CellDef *def, DfNetDef *ndef)
{
    DfCellInfo *info = DfCellDef2Info(def);
    return (ndef - info->dfi_netdefs);
}

DfTCell *DfNetUse2TCell(DfNetUse *nuse)
{
    // The low bit of dfu_tcell is also used as a flag, so mask it off.
    return (DfTCell*) ((int)nuse->u.dfu_tcell & 0xfffffffe);
}


int DfNetUse2NetNum(DfNetUse *nuse)
{
    // The low bit of dfu_tcell is also used as a flag, so mask it off.
    DfTCell *tc = DfNetUse2TCell(nuse);
    return (nuse - tc->dft_netuses);
}

static DfNetUse *dfTile2NetUse(DfTCell *tc,Tile *tilep)
{
    int netnum = dfTile2NetNum(tilep);
    return dfGetNetUse(tc,netnum);
}


// Get the NetUse in this TCell corresponding to NetDef.
DfNetUse *UNUSED_dfNetDef2NetUse(DfTCell *fcell, DfNetDef *ndef)
{
    int netnum = DfNetDef2NetNum(DfTCell2Def(fcell),ndef);
    return dfGetNetUse(fcell,netnum);
}


DfNetDef *DfNetUse2NetDef(DfNetUse *nuse)
{
    int netnum = DfNetUse2NetNum(nuse);
    CellDef *cdef = DfTCell2Def(DfNetUse2TCell(nuse));
    DfNetDef *netdefs = DfCellDef2NetDefs(cdef);
    return &netdefs[netnum];
}



// Run through all netuses and set the union field to point to the TCell they are in.
static void dfFixNetUses(DfTCell *tc)
{
    DfCellInfo *info = DfCellDef2Info(DfTCell2Def(tc));
    if (tc->dft_netuses) {
	DfNetUse *nu; int n;
	for (n = info->dfi_netcnt, nu = tc->dft_netuses; n > 0; n--, nu++) {
	    nu->u.dfu_tcell = tc;
	}
    }

    if (tc->dft_children) {
	DfTCell *tchild; int n;
	for (n = info->dfi_instcnt, tchild = tc->dft_children; n > 0; n--, tchild++) {
	    dfFixNetUses(tchild);
	}
    }
}

/***********************************************************************/
/* TCell Functions */
/***********************************************************************/

#if 0
// Copy fcell1 to fcell2.  Create subtree as needed.
static DfTCell *UNUSED_clone1(DfTCell *parent2, DfTCell *fcell2, DfTCell *fcell1)
{
    DfCellInfo *cinfo = DfCellDef2Info(DfTCell2Def(fcell1));
    int instcnt = cinfo->dfi_instcnt;
    int netcnt = cinfo->dfi_netcnt;
    int i;

    fcell2->dft_parent = parent2;
    fcell2->dft_celluse = fcell1->dft_celluse;	// Might be changed by caller at top level.
    fcell2->dft_children = (DfTCell*) dfMalloc(instcnt*sizeof(DfTCell));
    for (i = 0; i < instcnt; i++) {
	clone1(fcell2,&fcell2->dft_children[i],&fcell1->dft_children[i]);
    }
    assert(cinfo->dfi_netsize >= netcnt);

    // Temporarily save pointer from fcell1 to fcell2 in a safe spot.
    fcell1->dft_crosslink = fcell2;
    return fcell2;
}
#endif


// DONT DELETE!!!  Going to switch back to this method.
#if 0
// Traverse fcell tree, and convert all netuses to point to equivalent netuses in the new tree.
// In each source fcell, point dft_copydst to the fcell we are copying too.
// Then traverse netuses in source tree and change each corresponding netuse in destination
// tree to point to the same netuse in the destination tree.
// Note: There must be no netuses in the tree of which fsrc is the head
// that point outside of that tree.  In other words, this must be done BEFORE
// doing any hierarchical connectivity in cells above this one.
// NOTE:  This does not work because we cant reset the parent field of the top guy in each tree!!
static UNUSED_dfCopyNetUseTree(DfTCell *fsrc,DfTCell *fdst)
{
    DfCellInfo *info = DfCellDef2Info(DfTCell2Def(fsrc));
    int instcnt = info->dfi_instcnt;
    int netcnt = info->dfi_netcnt;

    assert(DfTCell2Def(fsrc) == DfTCell2Def(fdst));


    fsrc->u.dft_copydst = fdst;

    // Recur bottom up, to get copydst set in every dest cell first.
    for (i = 0; i < instcnt; i++) {
	dfCopyNetUseTree(&fsrc->dft_children[i],&fdst->dft_children[i]);
    }

    if (fsrc->dft_netuses) {
	DfNetUse *nusrc = dfGetNetUse(fsrc,0);
	DfNetUse *nudst = dfGetNetUse(fdst,0);
	for (i = 0; i < netcnt; i++, nusrc++, nudst++) {
	    nudst->u.dfu_tcell = fdst;
	    nudst->dfu_next = dfGetNetUse(
		nusrc->dfu_next->dfu_tcell->u.dft_copydst,
		DfNetUse2NetNum(nusrc->dfu_next));
	}
    }
}
#endif

// Color the netuse chain.  The color doesnt matter, as long as it is unique.
// Count is returned for reporting purposes only.
static int dfRecolor(DfNetUse *nu)
{
    int color = dfGlob.dfColor++;
    int cnt = 0;
    DfNetUse *nu2;
    nu2 = nu; do {
	assert(nu2->u.dfu_color == -1);
#if DF_DEBUG
	cnt++;	// Used only for statistics reporting.
#endif
	nu2->u.dfu_color = color;
    } while ((nu2=nu2->dfu_next) != nu);
    return cnt;
}


#if DF_DEBUG
static void dfChecknu(DfTCell *tc,int maxlevel)
{
    DfCellInfo *info = DfCellDef2Info(DfTCell2Def(tc));
    int instcnt = info->dfi_instcnt;
    int netcnt = info->dfi_netcnt;
    int i;

    for (i = 0; i < instcnt; i++) {
	dfChecknu(&tc->dft_children[i],maxlevel);
    }

    // Check each chain.
    if (tc->dft_netuses) {
	for (i = 0; i < netcnt; i++) {
	    DfNetUse *nu = &tc->dft_netuses[i];
	    DfNetUse *nu2;
	    nu2 = nu; do {
		if (nu2->u.dfu_tcell->dft_level < maxlevel) {
		    DfTCell *t = nu2->u.dfu_tcell;
		    printf("ERROR: %s level %d\n",t->dft_celluse->cu_id,t->dft_level); fflush(stdout);
		}
	    } while ((nu2=nu2->dfu_next) != nu);
	}
    }
}
#endif


// Used to traverse netuses in source tree and change each corresponding netuse in destination
// tree to point to the same netuse in the destination tree.
// Note: There must be no netuses in the tree of which fsrc is the head
// that point outside of that tree.  In other words, this must be done BEFORE
// doing any hierarchical connectivity in cells above this one.
static int dfCopyNetUseTree(DfTCell *fsrc,DfTCell *fdst, int pass)
{
    DfCellInfo *info = DfCellDef2Info(DfTCell2Def(fsrc));
    int instcnt = info->dfi_instcnt;
    int netcnt = info->dfi_netcnt;
    int i;
    int ncnt = 0;

    assert(DfTCell2Def(fsrc) == DfTCell2Def(fdst));

    for (i = 0; i < instcnt; i++) {
	ncnt += dfCopyNetUseTree(&fsrc->dft_children[i],&fdst->dft_children[i],pass);
    }

    if (fsrc->dft_netuses) {
	DfNetUse *nusrc = dfGetNetUse(fsrc,0);
	DfNetUse *nudst = dfGetNetUse(fdst,0);
	if (pass == 0) {
	    for (i = 0; i < netcnt; i++, nusrc++, nudst++) {
		// Temporarily use dfu_color field in src tree to point
		// to equivalent tcell in destination tree.
		nusrc->u.dfu_dst = nudst;
	    }
	} else if (pass == 1) {
	    for (i = 0; i < netcnt; i++, nusrc++, nudst++) {
		// For each dfu_next pointer in source tree,
		// set pointer in dst tree to the equivalent tcell
		// in the destination tree.
		nudst->dfu_next = nusrc->dfu_next->u.dfu_dst;
	    }
	} else if (pass == 2) {
	    for (i = 0; i < netcnt; i++, nusrc++, nudst++) {
		// Set all colors to -1
		nusrc->u.dfu_color = -1;
		nudst->u.dfu_color = -1;
	    }
	} else if (pass == 3) {
	    // Recolor all the chains.
	    for (i = 0; i < netcnt; i++, nusrc++, nudst++) {
		if (nusrc->u.dfu_color == -1) { ncnt += dfRecolor(nusrc); }
		if (nudst->u.dfu_color == -1) { ncnt += dfRecolor(nudst); }
	    }
	}
    }
    return ncnt;
}


// Clone netuses from tree at tcell into any other tcell trees of the same celldef type.
static void dfCloneNetUseTree(DfTCell *fcell)
{
    DfCellInfo *info = DfCellDef2Info(DfTCell2Def(fcell));
    DfTCell *fc;
    int tcnt = 0, ncnt = 0;

    // DEBUG
    //dfFixNetUses(&dfGlob.dfRootTCell);
    //printf("CloneNetUse %s %d:\n",DfTCell2Def(fcell)->cd_name, fcell->dft_level); fflush(stdout);
    //dfChecknu(fcell,fcell->dft_level);

    for (fc = info->dfi_tcells; fc; fc = fc->dft_next) {
	if (fc != fcell) {
	    tcnt++;
	    dfCopyNetUseTree(fcell,fc,0);
	    dfCopyNetUseTree(fcell,fc,1);
	    dfCopyNetUseTree(fcell,fc,2);
	    ncnt += dfCopyNetUseTree(fcell,fc,3);
	}
    }
    if (dfGlob.dfDebug & 0x41) {
	MsgInfoF("dfCloneNetUseTree %s copies %d netuses %d.  \n",
	    fcell->dft_celluse?fcell->dft_celluse->cu_id:"ROOT",tcnt,ncnt);
    }
}


// Returns the linearized array element number for the fcell.
int UNUSED_DfTCell2ArrayNum(DfTCell *fcell)
{
    if (fcell->dft_parent == NULL) {
	// At top of hierarchy.
	return 0;
    }
    
    {
	// This would have to deal with cu_client == -1
	int firstinstnum = (int) fcell->dft_celluse->cu_client;
	int instnum = fcell - fcell->dft_parent->dft_children;
	int arraynum = instnum - firstinstnum;
	return arraynum;
    }
}



// Return cell instance number of this TCell in its parent.
// The cell instance number is unique for every array element
// of all celluses in a celldef.
int DfTCell2CellInstNum(DfTCell*fcell)
{
    if (fcell->dft_parent == NULL) {
	// At top of hierarchy.
	return 0;
    }
    return fcell - fcell->dft_parent->dft_children;
}


CellDef *DfTCell2Def(DfTCell *fcell)
{
    if (fcell->dft_celluse) {
	return fcell->dft_celluse->cu_def;
    } else {
	assert(fcell == &dfGlob.dfRootTCell);
	return dfGlob.dfRootDef;
    }
}

// Return the path of the TCell in the buf.
// For path hierarchy purposes, ignore cells if they have dfi_hierIgnore flag set,
// and also ignore any GROUP gcells.
// If instname is non-NULL, append it to the end of the path.
// For debug purposes, use "" for instname, to distinguish the root tcell in error messages,
// since otherwise it just returns an empty string.
static char *dfTCellPath(char *buf,DfTCell *fc,char *instname)
{
    if (fc->dft_parent) {
	DfCellInfo *info = DfCellDef2Info(DfTCell2Def(fc));
	dfTCellPath(buf,fc->dft_parent,0);
	if (! (info->dfi_hierIgnore || strncmp(fc->dft_celluse->cu_id,"#GROUP",sizeof("#GROUP")) == 0) ) {
	    int slen = strlen(buf);
	    if (slen && buf[slen-1] != '/') { strcat(buf,"/"); }
	    strcat(buf,fc->dft_celluse->cu_id);
	}
    } else {
	// Previous def writer did not use initial slash, so we wont either.
	//strcpy(buf,"/");
	*buf = 0;
	// Note: There is no celluse associated with the topmost fcell, just a def.
    }
    if (instname) {
	int slen = strlen(buf);
	if (slen && buf[slen-1] != '/') { strcat(buf,"/"); }
	strcat(buf,instname);
    }
    return buf;
}


// Return transform from fc coords to root coords.
// Tricky for arrays.
static void DFTCell2Trans(DfTCell *fc,Transform *trans)
{
    *trans = GeoIdentityTransform;

    for ( ; fc->dft_parent; fc = fc->dft_parent) {
	CellUse *use = fc->dft_celluse;
	Transform result;

	if (DBIsArray(use)) {
	    Transform arraytrans;
	    // Recompute x and y indicies of this array element.
	    int xsize = abs(use->cu_xhi - use->cu_xlo) + 1;
	    int ysize = abs(use->cu_yhi - use->cu_ylo) + 1;
	    int elementnum = DfTCell2CellInstNum(fc) - (int) use->cu_client;
	    int y = elementnum / xsize;
	    int x = elementnum - (y*xsize);

	    SPGetArrayTransform(use,x,y,&arraytrans);
	    GeoTransTrans(trans,&arraytrans,&result);
	    *trans = result;

	} else {
	    GeoTransTrans(trans,&use->cu_transform,&result);
	    *trans = result;
	}
    }
}

/***********************************************************************/
// Creating flat connectivity.
// Step 1 functions
/***********************************************************************/



// Hierarchically traverse cells starting at def.
// In each def, allocate CellInfo (if not already done), and set instcnt.
// Note that CellInfo type was done before we were called.
// Iterate over celluses in def and set celluse->cd_client to index of first
// array element of each celluse.
static int dfStep1(CellDef *cdef)
{
    BPEnum bpe;
    CellUse *use;
    int instcnt;
    PlaneList *pll;
    DfCellInfo *info = DfCellDef2Info(cdef);

    if (info->dfi_didStep1) {
	// This def has already been processed.
	return 0;
    }
    info->dfi_didStep1 = 1;

    /* read celldef from disk, if necessary */
    if ((cdef->cd_flags & CD_AVAILABLE) == 0) {
	if (!DBReadCell(cdef)) {
	    MsgErrorF("Cant read cell '%s'\n",cdef->cd_name);
	    return 1;
	}
    }


    // Get other per-def information.
    {   char *prop;
	if ((prop = DBPropGet(cdef,"def_via_name"))) {
	    info->dfi_vianame = prop;
	}
	if ((prop = DBPropGet(cdef,"def_via_name_r90"))) {
	    info->dfi_vianame_r90 = prop;
	}
	if ((prop = DBPropGet(cdef,"def_hier_ignore"))) {
	    if (strcmp(prop,"1")) {
		info->dfi_hierIgnore = 1;
	    } else if (strcmp(prop,"0")) {
		// leave default: info->dfi_hierIgnore = 1;
	    } else {
		MsgErrorF("Cell: '%s': Unrecognized value of def_hier_ignore prop: %s\n",cdef->cd_name,prop);
	    }
	}
	if ((prop = DBPropGet(cdef,"def_section"))) {
	    if (strcasecmp(prop,"NETS") == 0) {
		info->dfi_sectionNets = 1;
	    } else if (strcasecmp(prop,"SPECIALNETS") == 0) {
		// Leave default : info->dfi_sectionNets = 0;
	    } else {
		MsgErrorF("Cell: %s: Unrecognized value of def_section prop: %s\n",cdef->cd_name,prop);
	    }
	}
    }

    // NOTE: If we had flattened paint of leaf cells,
    // we would would not have to check below leaf cells.
    if (info->dfi_type == dfext_none) return 0;

    // Traverse subcells.  Number the celluses.
    BPEnumInit(&bpe,cdef->cd_cellPlane,NULL,BPE_ALL,"dfStep1");

    instcnt = 0;
    while (use = BPEnumNext(&bpe)) {
	DfCellInfo *subinfo = DfCellDef2Info(use->cu_def);
	// TODO: Could compute this better by passing a stop flag as an argument.
	if (info->dfi_type == dfext_stop && subinfo->dfi_type != dfext_all) {
	    use->cu_client = (ClientData) -1;	// illegal value
	    continue;
	}

	use->cu_client = (ClientData) instcnt;
	instcnt += dfArrayElementCount(use);

	if (dfStep1(use->cu_def)) {
	    BPEnumTerm(&bpe);
	    return 1;
	}
    }

    BPEnumTerm(&bpe);

    info->dfi_instcnt = instcnt;
    return 0;
}



// Allocate tcell hierarchy to correspond to cdef.
// All cells have already been read in by dfStep1.
// This flat cell is an instance of this def.
// State marks our point in the descent of the hierarchy, see comments below.
static void dfTCellInit(DfTCell *fcell, CellDef *cdef,int state)
{
    BPEnum bpe;
    CellUse *use;
    int instcnt;
    DfCellInfo *info = DfCellDef2Info(cdef);
    DfTCell *flatchild;

    dfGlob.dfTCellCnt++;

    fcell->dft_tag = DFTCellTag;
    if (fcell->dft_parent) {
	fcell->dft_level = fcell->dft_parent->dft_level+1;

	if (fcell->dft_parent->dft_sub_stop || fcell->dft_parent->dft_type == dfext_stop) {
	    fcell->dft_sub_stop = 1;
	}
    }


    // state traces the position in the hierarchy.
    // As you descend through the hierarchy, you extract everything above leaf.
    // It starts out as dfext_all, changes to dfext_stop when we pass a stop cell,
    // and changes to dfext_none after we pass a non-extracted cell,
    // or another vcell under the first vcell.
    // TODO: Maybe this should depend on full/partial extraction?
    switch (state) {
	default:
	case dfext_null:
	    ASSERT(0,"bad state");
	case dfext_all:
	    switch (info->dfi_type) {
	    default:
	    case dfext_null:
		ASSERT(0,"bad dfi_type"); // unused
	    case dfext_stop:
		state = fcell->dft_type = dfext_stop;
		break;
	    case dfext_hier:
	    case dfext_all:
		state = fcell->dft_type = dfext_all;
		break;
	    case dfext_none:
		state = fcell->dft_type = dfext_none;
		break;
	    }
	    break;
	case dfext_stop:
	    switch (info->dfi_type) {
	    default:
	    case dfext_null:
		ASSERT(0,"bad dfi_type(2)"); // unused
	    case dfext_all:
		fcell->dft_type = info->dfi_type;
		state = dfext_stop;  // the vcell state is sticky.
		break;
	    case dfext_hier:
	    case dfext_stop:
	    case dfext_none:
		state = fcell->dft_type = dfext_none;
		break;
	    }
	    break;
	case dfext_none:
	    state = fcell->dft_type = dfext_none;
	    break;
    }
    ASSERT(fcell->dft_type != 0,0);

    fcell->dft_next = info->dfi_tcells;
    info->dfi_tcells = fcell;

    if (info->dfi_instcnt) {

	// Allocate children for this tcell.
	fcell->dft_children = (DfTCell*)dfCalloc(info->dfi_instcnt*sizeof(DfTCell));

	// Traverse children.
	BPEnumInit(&bpe,cdef->cd_cellPlane,NULL,BPE_ALL,"dfTCI");

	flatchild = &fcell->dft_children[0];
	while (use = BPEnumNext(&bpe)) {
	    int i;
	    if ((int) use->cu_client == -1) continue;
	    // Each array element is its own tcell.
	    for (i = dfArrayElementCount(use); i > 0; i--) {
		flatchild->dft_parent = fcell;
		flatchild->dft_celluse = use;
		dfTCellInit(flatchild,use->cu_def,state);
		flatchild++;
	    }
	}

	BPEnumTerm(&bpe);
    }
    return;
}


/***********************************************************************/
// Creating flat connectivity.
// Step 2 functions
/***********************************************************************/
static int dfLinkTile(CellDef *cdef, Tile *firstTile, Tile *tile, int netnum);  /* forward decl */

// Look in area on plane pl_num for tiles that can connect to tileType.
// If tile is non-null, it is on the correct plane, so use it as the hint tile.
static void dfLinkArea(CellDef *cdef, Tile *firstTile,Tile *hintTile, Rect *rect,int netnum,int tileType, int pl_num)
{
    SPTileEnum tpe;
    Tile *tile;

    SPTileEnumInit(&tpe,hintTile,cdef->cd_planes[pl_num], rect, &DBConnectTbl[tileType], "dfLinkArea");
    while (tile = SPTileEnumNext(&tpe)) {
	if (tile->ti_client == (ClientData) MINFINITY) {
	    // Tile has not been seen before.
	    dfLinkTile(cdef,firstTile,tile,netnum);
	}
    }
    SPTileEnumTerm(&tpe);
}


// Add all tiles connected to this tile into linked list for netdef.
static int dfLinkTile(CellDef *cdef, Tile *firstTile, Tile *tile, int netnum)
{
    int tileType = DBgetTileType(tile);
    PlaneList *pll;
    Rect rect;

    if (TTMaskHasType(&dfGlob.dfMetalMask,tileType)) {
	// Keep tiles in a circular list.  First time through, tile==firstTile
	// and this inits the list.  For subsequent tiles, link them after firstTile.
	assert(tile->ti_client == (ClientData) MINFINITY);
	dfTileSetNextTile(tile,dfTile2NextTile(firstTile));
	dfTileSetNextTile(firstTile,tile);
	dfTileSetNetNum(tile,netnum);
    } else {
	// It is a contact or via-cut tile.  Dont bother to link it into the list.
	// But mark it so we dont process it again.  Set it to a NULL pointer.
	// TODO: Is either of these necessary?
	dfTileSetNextTile(tile,0);
	// Make SURE the netnum is invalid.
	dfTileSetNetNum(tile,-1);
    }

    TiToRect(tile,&rect);
    GEO_EXPAND(&rect, 1, &rect);

    // Process any tiles on this plane that touch this tile.
    dfLinkArea(cdef,firstTile,tile,&rect,netnum,tileType,DBPlane(tileType));

    // Look on connecting planes (vias,contacts).
    for (pll = DBConnectPlanes[tileType]; pll; pll = pll->pll_next) {
	assert(DBPlane(tileType) != pll->pll_num); // already did this plane.  Inefficiency if assert fails.
	// Unfortunately we dont have any hint on this plane.
	dfLinkArea(cdef,firstTile,NULL,&rect,netnum,tileType,pll->pll_num);
    }

    return 0;
}


// Return the tile attached to the label, or print warning and return NULL if none.
static Tile *dfLabel2Tile(CellDef *cdef, Label *lab)
{
    Rect rect = lab->lab_rect;
    TileType ttype = lab->lab_type;
    Tile *tp;

    if (lab->lab_kind == LAB_COMMENT || lab->lab_kind == LAB_HIDDEN) {return NULL;}

    if (ttype == TT_SPACE) {
	// If a local label is over space, ignore it.
	// GDS in from cadence creates a local label on space to mark the origin of every cell instance.
        if (lab->lab_kind != LAB_LOCAL) {
	    dfWarn("Cell '%s' label '%s': label not over a tile\n",cdef->cd_name,lab->lab_text);
	}
        return NULL;
    }

    if (! TTMaskHasType(&dfGlob.dfMetalMask,ttype)) {
        dfWarn("Cell '%s' label '%s': label is not on a wiring layer\n",cdef->cd_name,lab->lab_text);
	return NULL;
    }

    // grow area slightly so we always get touching stuff
    GEO_EXPAND(&rect, 1, &rect);

    {   TileTypeBitMask tmask;
	SPTileEnum tpe;
	TTMaskZero(&tmask);
	TTMaskSetType(&tmask,ttype);
	// This enumeration will pick up the one tile under this label.
	SPTileEnumInit(&tpe, (Tile*)NULL, dfTileType2Plane(cdef,ttype), &rect, &tmask, "dfL2T");
	tp = SPTileEnumNext(&tpe);
	SPTileEnumTerm(&tpe);
    }

    if (tp == NULL) {
	dfWarn("Cell '%s' label '%s': label is not over a tile\n",cdef->cd_name,lab->lab_text);
        return NULL; // dont process this unconnected label.
    }

    // Dont think this can happen:
    if (DBgetTileType(tp) != lab->lab_type) {
	dfWarn("Cell '%s' label '%s': label type does not match tile type\n",cdef->cd_name,lab->lab_text);
        return NULL;
    }
    return tp;
}


// Connect netdef of this tile to this label.  Print warnings.
// Labels are kept in a malloced array, ends with a 0 entry.
// It is extremely rare that there is more than one label on a net,
// but it happens when a cell has been flattened: multiple labels from
// original sub-cells can end up on the metal.
// I dont know why we bother keeping multiple labels; seems like
// any one would do.
static void dfSetNetLabel(CellDef *cdef, Tile *tile,Label *lab)
{
    DfNetDef *net = dfTile2NetDef(cdef,tile);
    int oldlabcnt = 0;
    if (net->dfn_labels) {
	// count old labels.
	Label **labp;
	for (labp = net->dfn_labels; *labp; labp++) {
	    oldlabcnt++;
	}
    }

    if (oldlabcnt) {
	net->dfn_labels = (Label**)dfRealloc(net->dfn_labels,
		(oldlabcnt+1) * sizeof(Label*),(oldlabcnt+2) * sizeof(Label*),0);
    } else {
	net->dfn_labels = (Label**)dfMalloc((oldlabcnt+2) * sizeof(Label*));
    }
    net->dfn_labels[oldlabcnt] = lab;
    net->dfn_labels[oldlabcnt+1] = 0;	// array is 0 terminated.
}


// Process all tiles on each metal plane in celldef.
// Each set of connected tiles are put in a linked list off of a netdef structure.
static void dfMakeDefConnect(CellDef *cdef)
{
    Label *lab;
    DfCellInfo *info = DfCellDef2Info(cdef);

    if (info->dfi_type == dfext_none) {
	assert(0);
#if DEF_VCELL_OPT
    // Take this out.  It needs to be modified to trace through vias,
    // and its probably not worth the effort anyway.
    } else if (info->dfi_type == dfext_stop) {
	// It is a verilog leaf cell.  These could be treated just like hierchical cells,
	// but we can optimize a little because we only have to worry about
	// nets that have labels on them.  It is an error to connect
	// to a verilog leaf cell except at labeled paint.
	// TODO: possible optimization: could allocate all netdefs at once

	// We have to do global labels, too, in case the router
	// connects to vdd/gnd in a sub-cell.  Also to get power taps.
	for (lab = cdef->cd_labels; lab; lab = lab->lab_next) {
	  switch (lab->lab_kind) {
	    case LAB_INPUT: case LAB_OUTPUT: case LAB_INOUT: case LAB_LOCAL: case LAB_GLOBAL: {
		Tile *tile = dfLabel2Tile(cdef,lab);
		if (tile == NULL) { continue; }  // error message printed by dfLabel2Tile.
		if (tile->ti_client == (ClientData)MINFINITY) {
		    // Tile has not been seen before.  If it has, then
		    // there are shorted labels, and a warning will
		    // pop out of dfSetNetLabel.
		    DfNetDef *net = DfNewNetDef(cdef);
		    dfLinkTile(cdef,net,tile);

		    // TODO: We have to trace connectivity through vias!!!!!
		}
		dfSetNetLabel(cdef,tile,lab);
	    }
	  }
	}

#endif
    } else {
	// It is a hierarchical cell.

	SPSearchEnum spp;
	Tile *tile;
	Rect rect = *DBBBoxCellDef(cdef);

	/* grow area slightly so we always get touching stuff */
	GEO_EXPAND(&rect, 1, &rect);

	// Iterate over each tile in all metal planes.
	// Link all connected tiles of interest into circular linked lists.
	// We use a circular list so we can later point the net structure to any
	// of the tiles in the list - dont have to find the head.
	SPPlanesEnumInit(&spp,cdef,dfGlob.dfMetalPlanes,&rect,&dfGlob.dfMetalMask,0,"dfmdc2");

	while (tile = SPPlanesEnumNext(&spp)) {
	    if (tile->ti_client == (ClientData)MINFINITY) {
		// Tile has not been seen before.  Create a new net.
		int netnum = dfNewNetNum(info);
		// And link all paint connected to tile to net.
		dfLinkTile(cdef,tile,tile,netnum);
	    }
	}
	SPPlanesEnumTerm(&spp);

	// Allocate netdefs, and hook them to the linked lists we created above.
	info->dfi_netdefs = dfCalloc(info->dfi_netcnt * sizeof(DfNetDef));

	// Again iterate over each tile in all metal planes.
	// Its kind of irritating to have to do it again, but its the only way to count
	// the nets ahead of time so we can avoid a realloc.
	// Point netdefs to any tile in circular list belonging to netdef.
	SPPlanesEnumInit(&spp,cdef,dfGlob.dfMetalPlanes,&rect,&dfGlob.dfMetalMask,0,"dfmdc2");

	while (tile = SPPlanesEnumNext(&spp)) {
	    if (tile->ti_client != (ClientData)MINFINITY && tile->ti_client != 0) {
		int netnum = dfTile2NetNum(tile);
		assert(netnum >= 0 && netnum < info->dfi_netcnt);
		info->dfi_netdefs[netnum].dfn_tiles = tile;
	    }
	}
	SPPlanesEnumTerm(&spp);

	// PARANOID
	{ int n;
	    for (n = 0; n < info->dfi_netcnt; n++) {
		DfNetDef *net = &info->dfi_netdefs[n];
		assert(net->dfn_tiles);
	    }
	}


	// hook up the labels in this cell to their netdefs.
	// We have to do global labels, too, for power taps and
	// in case someone (or a router) connects to vdd/gnd in a sub-cell.
	// Local labels are used for net names in hierarchical cells.
	for (lab = cdef->cd_labels; lab; lab = lab->lab_next) {
	  switch (lab->lab_kind) {
	    case LAB_INPUT: case LAB_OUTPUT: case LAB_INOUT: case LAB_LOCAL: case LAB_GLOBAL: {
	      // Find the tile under this label. 
	      Tile *tile = dfLabel2Tile(cdef,lab);
	      if (tile != NULL) {
		dfSetNetLabel(cdef,tile,lab);
	      }
	    }
	  }
	}
    }
    return;
}

/***********************************************************************/
// Creating hierarchical connectivity functions.
/***********************************************************************/



// Given a SearchContext that is a subcell of parent, return
// a pointer to the tcell child that spx represents, or NULL
// if this child was not extracted.
static DfTCell *dfSpx2TCellChild(DfTCell *parent,SPSearchContext *spx)
{
    CellUse *use = spx->spx_use;
    int instnum = (int) use->cu_client;
    if (instnum == -1) { return NULL; }
    if (DBIsArray(use)) { instnum += dfArrayNumber(spx); }
    return & parent->dft_children[instnum];
}


// Find the fcell given the current search context and the root fcell
// from which the search started.
// Implemented by going up the spx tree to the root, then traveling
// down the fcell tree.
DfTCell *UNUSED_dfSpx2TCell(DfTCell *fcellroot,SPSearchContext *spx)
{
    CellUse *use = spx->spx_use;
    DfTCell *fc;
    int instnum = (int) use->cu_client;
    assert(instnum >= 0);
    if (DBIsArray(use)) { instnum += dfArrayNumber(spx); }

    if (spx->spx_parent) {
	fc = UNUSED_dfSpx2TCell(fcellroot,spx->spx_parent);
    } else {
	fc = fcellroot;
    }

    return &fc->dft_children[instnum];
}


// Return the bbox in the parent coord system of only the layers that are of interest to us.
// If spx is an array element, return only the area of that array element.
void dfMBBox(SPSearchContext *spx, Rect *result)
{
    Rect bbox;
    Transform *instTrans;	// Tranform from spx->spx_use coords to parent coords.

    // TODO: Compute bbox of interesting layers.  For now, just use cell bbox.
    bbox = *DBBBoxCellDef(spx->spx_use->cu_def);

    GEOTRANSRECT(SPsxGetTrans(spx),&bbox,result);
}



// Link two netuses together.
// They are not necessarily parent and child; could be siblings or distant cousins.
// First we must see if child net is already hooked to parent net.
// We must traverse the entire linked list of either the parent
// or the child.   Child is usually shorter (true for vias),
// but if we are hooking up a power grid, the parent could be shorter
// by a whopping margin.  So for efficiency, traverse both lists
// simultaneously to find the shortest.
static void dfConnectNetUses(DfNetUse *parent,DfNetUse *child)
{
    DfNetUse *child_tail, *parent_tail, *nu;

    // Cache the most recently seen two netuses.
    // Tile fracturing might result in lots of connected child tiles
    // under the same parent tile, resulting in a string of calls
    // to this function with identical parent,child pairs.
    //if (dfGlob.dfcacheNU1 == parent && dfGlob.dfcacheNU2 == child) {return;}  // already connected
    //dfGlob.dfcacheNU1 = parent;
    //dfGlob.dfcacheNU2 = child;

#if DF_COLORS
    if (parent->u.dfu_color == child->u.dfu_color) return;
#endif

    child_tail = child; parent_tail = parent;

    while (1) {
	if (child_tail->dfu_next == child) {
	    // Found end of child circular list.

#if DF_COLORS
	    // Set child list color to parent color.
	    int color = parent->u.dfu_color;
	    nu = child; do {
		nu->u.dfu_color = color;
	    } while ((nu = nu->dfu_next) != child);
#endif

	    // Connect child list to end of parent list.
	    child_tail->dfu_next = parent->dfu_next;
	    parent->dfu_next = child;
	    break;
	}
	if (parent_tail->dfu_next == parent) {
	    // Found end of parent circular list.

#if DF_COLORS
	    // Set parent list color to child color.
	    int color = child->u.dfu_color;
	    nu = parent; do {
		nu->u.dfu_color = color;
	    } while ((nu = nu->dfu_next) != parent);
#endif

	    // Connect parent list to end of child list.
	    parent_tail->dfu_next = child->dfu_next;
	    child->dfu_next = parent;
	    break;
	}
	child_tail = child_tail->dfu_next;
	parent_tail = parent_tail->dfu_next;

	// See if two lists already connected.
	// No longer needed because we check colors.
	//if (child_tail == parent || parent_tail == child) { return; }
    }

    if (++dfGlob.dfNetUseConnections % 5000 == 0) { dfPrintStatus(); }
}


// See if cells (which caller determined are the same type) are in identical location.
static int dfCheckCellClobber(SPSearchContext *spx1, SPSearchContext *spx2)
{
    Rect r1, r2;
    assert(spx1->spx_use->cu_def == spx2->spx_use->cu_def);
    // Use the bbox of the def instead of the use, because we want to ignore the arraying.
    // The def bbox may be out of date, but we dont care because we are only
    // comparing it to itself.  Note that GeoTransRect guarantees canonical output.
    GeoTransRect(&spx1->spx_trans,&spx1->spx_use->cu_def->cd_bbox,&r1);
    GeoTransRect(&spx2->spx_trans,&spx2->spx_use->cu_def->cd_bbox,&r2);
//DEBUG
    if (dfGlob.dfDebug & 8) {
	char  buf1[1000],buf2[1000];
	MsgInfoF("Clobber %s:%s %s:%s %d,%d,%d,%d %d,%d,%d,%d = %d\n",
	SPsxRoot(spx1)->cd_name, SPsxInstPath(spx1, buf1,1000),
	SPsxRoot(spx2)->cd_name, SPsxInstPath(spx2, buf2,1000),
	r1.r_xbot,r1.r_ybot,r1.r_xtop,r1.r_ytop,
	r2.r_xbot,r2.r_ybot,r2.r_xtop,r2.r_ytop,
	GEO_SAMERECT(r1,r2));
    }
    return GEO_SAMERECT(r1,r2);
}

// Search hierarchically in tc2,spx2 for tiles connected to this tile, which was found in spx1,tc1.
// Tc2 is the TCell corresponding to the celluse in spx2.
// If overlapping tiles are found, connect their netuses together.
// Spx1 will be NULL if tc2 is a child of tc1; happens when called from MakeHierConnect.
// If tc1 is non-NULL, then tc1 and tc2 have a common ancestor,
// and we will check if they are identical overlapping cells.
// Return 0 on success, -1 on interrupt, 1 to tell caller to abort any further tests on these two cells.
static int dfConChildren(DfTCell *tc1, SPSearchContext *spx1, Tile *tile1, DfTCell *tc2, SPSearchContext *spx2)
{
    CellDef *def2 = spx2->spx_use->cu_def;

    SPTileEnum tpe;
    TileType tile1Type = DBgetTileType(tile1);
    DfNetUse *nu1 = NULL, *nu2;
    Tile *tile2;
    TileTypeBitMask *mask2 = dfCellMask(spx2->spx_use->cu_def);

    if (SigInterruptPending) { return -1; }

    // First do a quick check to see if any hierarchical child has
    // anything at all on this layer.
    if (! TTMaskHasType(mask2,tile1Type)) { return 0; }

    // TODO: Look at all calls to dfConChildren and SibWhatever, and figure out
    // when to stop the descent.
    // TODO: Do we want to do this here?  We want to find and report bad connections.  TODO: make this an option,
    // so we dont have to dive into rams, for example, unless the user requests the error report.
    // if (fc1->dft_type == dfext_none || fc2->dft_type == dfext_none) return;

    if (tc1->dft_type == dfext_none) { return 0; }
    if (tc2->dft_type == dfext_none) { return 0; }

    if (dfGlob.dfDebug & 1) {
	char buf1[1000], buf2[1000]; Rect rtmp,r;  Rect r2 = spx2->spx_area;
	Transform trans1;
        TiToRect(tile1,&rtmp);
	DFTCell2Trans(tc1,&trans1);
	GEOTRANSRECT(&trans1,&rtmp,&r);
	MsgInfoF("dfConChildren %s tile (%s %d %d %d %d) %s area %d %d %d %d\n",
	    dfTCellPath(buf1,tc1,""),
	    DBTypeShortName(tile1Type),r.r_xbot,r.r_ybot,r.r_xtop,r.r_ytop,
	    dfTCellPath(buf2,tc2,""),
	    r2.r_xbot,r2.r_ybot,r2.r_xtop,r2.r_ytop);
    }


    // See if this cell contains paint of type stuff->tileType in area spx2->area.
    SPTileEnumInit(&tpe, (Tile*)NULL, dfTileType2Plane(def2,tile1Type), &spx2->spx_area,
	&DBConnectTbl[tile1Type], "");

    while (tile2 = SPTileEnumNext(&tpe)) {

	// Found some connected paint.

	// Check to see if the two cells are identical and on top of each other.
	// We can defer this check until now, because any two cells that do this
	// will also be connected to each other, assuming they contain any paint at all.
	if (spx1 && spx1->spx_use->cu_def == def2 && dfCheckCellClobber(spx1,spx2)) {
	    {
		char buf1[1000],buf2[1000];
		if (!dfGlob.dfQuiet) {
		    MsgInfoF("Identical overlapping cells, second removed: %s %s\n",
			    dfTCellPath(buf1,tc1,0),
			    dfTCellPath(buf2,tc2,0));
		}
	    }
	    // One of the two cells should go away.
	    tc2->dft_type = dfext_none;
	    SPTileEnumTerm(&tpe);
	    return 1;	// Tell parent to abort this cell.
	}

	if (tile2->ti_client == (ClientData)MINFINITY) {
	    // This fcell has not been processed!
	    // Do it right now.
	    if (dfMakeBothConnect(tc2)) {
		SPTileEnumTerm(&tpe);
		return -1;
	    }

#if DEF_VCELL_OPT
	    // TODO: This wont happen any more because I took out the vcell optimization in
	    // dfMakeDefConnect.  However, we still probably want to find and report
	    // connections to unlabeled paint in vcells when it occurs, so that
	    // we can report the location.  If we wait until the end, the netuses
	    // do not have location information.
	    // 
	    // The connectivity maker did not connect up this tile.
	    // This will happen if you try to connect to unlabeled
	    // paint in a verilog leaf cell.
	    // Print an error message containing the location in root cell coords.
	    // You will also get this message even if the def has paint connectivity,
	    // but the fcell is dfext_none, which can happen if the same cell
	    // is used both above and below leaf cells, but that case is caught
	    // in dfConnectNetUses.
	    if (tile2->ti_client == (ClientData) MINFINITY) {
	      Rect trect, r;
	      TiToRect(tile2,&trect);
	      GEOCLIP(&trect,&spx2->spx_area);
	      GEOTRANSRECT(&spx2->spx_trans,&trect,&r);
	      dfWarn("warning: Connection to unlabeled paint in cell %s in area (%g,%g) (%g,%g)\n",
		  SPsxRoot(spx2)->cd_name,UnitsI2D(r.r_xbot),UnitsI2D(r.r_ybot),
		  UnitsI2D(r.r_xtop),UnitsI2D(r.r_ytop));

	      // assert(DfCellDef2Info(def2)->dfi_type == dfext_stop || TODO);

	      continue;  // Skip this tile.
	    }
#endif
	    ASSERT(tile2->ti_client != (ClientData) MINFINITY,0);
	}

	if (nu1 == NULL) {
	    nu1 = dfTile2NetUse(tc1,tile1);
	}
	nu2 = dfTile2NetUse(tc2,tile2);

	if (dfGlob.dfDebug & 1) {
	    char buf1[1000], buf2[1000];
	    MsgInfoF("dfConnectNetUses %s %s\n",
		dfTCellPath(buf1,tc1,""), dfTCellPath(buf2,tc2,""));
	}
	dfConnectNetUses(nu1,nu2);
    }
    SPTileEnumTerm(&tpe);


    // Now search children of spx2.
    {
	SPSearchContext *spxchild;
	DfTCell *tchild;

	spxchild = SPsxInstEnumInit(spx2,"");
	while (spxchild = SPInstEnumNext(spxchild)) {
	    tchild = dfSpx2TCellChild(tc2,spxchild);
	    if (tchild) {
		if (++dfGlob.dfOverlapCnt % 10000 == 0) { dfPrintStatus(); }
		if (dfConChildren(tc1,spx1,tile1,tchild,spxchild) == -1) {
		    SPInstEnumTerm(spxchild);
		    return -1;
		}
	    }
	}
    }

    return 0;
}


// Searches for common paint in the overlap area between two sibling cells.
// Search in spx1 and any children for paint tiles in area specified by spx1->spx_area.
// When found, call dfConChildren to search for connected tiles in the hiearchy
// headed by spx2 (whose area is uninitialized on entry.)
// tc1 and tc2 are the TCells corresponding to spx1 and spx2, respectively.
// The imask is the metal intersection mask between tc1 and tc2.
// We could recompute it, but we passed it in because we already had it.
//static void dfFindSibPaint(SPSearchContext *spx1,SPSearchContext *spx2,DfTCell *froot, TileTypeBitMask *mask)
static int dfFindSibPaint(DfTCell *tc1, SPSearchContext *spx1,DfTCell *tc2, SPSearchContext *spx2, TileTypeBitMask *imask)
{
    SPSearchEnum ppe;
    Transform tinv;
    PlaneList *planelist;
    Tile *tile;

    if (dfGlob.dfDebug & 1) {
	char buf1[1000], buf2[1000];
	Rect r = spx1->spx_area;
	MsgInfoF("dfFindSibPaint %s %d %d %d %d %s\n", dfTCellPath(buf1,tc1,""),
	    r.r_xbot,r.r_ybot,r.r_xtop,r.r_ytop,
	    dfTCellPath(buf2,tc2,""));
    }

    if (++dfGlob.dfOverlapCnt % 1000 == 0) { dfPrintStatus(); }

    // TODO: Compute planelist from mask more efficiently by traversing dfMetalPlanes
    // and keeping the ones we want.
    planelist = DBPlaneListFromTypes(imask);

    // Enumerate all paint in tc1 matching imask in area spx1->spx_area 
    SPPlanesEnumInit(&ppe,spx1->spx_use->cu_def,planelist,&spx1->spx_area,imask,0,"dfFSP");
    while (tile = SPPlanesEnumNext(&ppe)) {
	Rect tirect, area;
	int status;

	if (tile->ti_client == (ClientData)MINFINITY) {
	    // This tcell has not been processed!
	    // Do it right now.
	    if (dfMakeBothConnect(tc1)) {
		failure:
		PlaneListFree(planelist);
		SPPlanesEnumTerm(&ppe);
		return -1;
	    }
	}
	ASSERT(tile->ti_client != (ClientData)MINFINITY,0);

	// Compute the interesection of tile with the search area to
	// pass to dfConChildren in spx2->spx_area.
	// This is not strictly necessary; we could have just passed the entire
	// tile area, or even the entire cell area.
	// But we want to minimize the work that dfConChildren must do.

	TiToRect(tile,&tirect);
	GEO_EXPAND(&tirect,1,&tirect);
	// Clip tile area to search area.  Note that spx1 area is already grown by 1.
	GEOCLIP(&tirect,&spx1->spx_area);
	// Convert up to root coords.
	GEOTRANSRECT(&spx1->spx_trans,&tirect,&area);

	// Convert down to spx2 coords.
	GEOINVERTTRANS(&spx2->spx_trans,&tinv);
	// We are overwriting the area in the spx2 struct, which is ok.
	GEOTRANSRECT(&tinv,&area,&spx2->spx_area);

	status = dfConChildren(tc1,spx1,tile,tc2,spx2);
	if (status == -1) { goto failure; }
	if (status == 1) { break; }
    }
    SPPlanesEnumTerm(&ppe);

    PlaneListFree(planelist);

    // Process each subcell.
    // TODO: Do we need to stop at verilog cells?
    {
	SPSearchContext *spxchild;
	DfTCell *tchild;

	spxchild = SPsxInstEnumInit(spx1,"");
	while (spxchild = SPInstEnumNext(spxchild)) {
	    TileTypeBitMask childmask = *dfCellMask(spxchild->spx_use->cu_def);
	    TTMaskAndMask(&childmask,imask);	// childmask is intersect of original mask and child layers.
	    // OLD: if (!TTMaskIntersect(imask,childmask)) continue;
	    if (TTMaskIsZero(&childmask)) continue;
	    tchild = dfSpx2TCellChild(tc1,spxchild);
	    if (tchild == NULL || tchild->dft_type == dfext_none) continue;
	    if (dfFindSibPaint(tchild,spxchild,tc2,spx2,&childmask)) {
		SPInstEnumTerm(spxchild);
		return -1;
	    }
	}
    }
    return 0;
}


// Enumerate all children of fcell for connections between siblings.
// For each pair of siblings, search for paint in the area of overlap
// between the siblings.  Note that overlap area can be the entire cell.
// We have gone to quite a bit of effort to make this a separate step
// from MakeHierConnect, when they could have both been done at once,
// but that would require checking all paint tiles for sibling connections,
// when in fact, sibling connections, especially between stdcells, are rare.
// By separating this out as a separate function we only check the overlap
// areas of siblings for paint.
//
// We must dive into all descendents of both spx1 and spx2 to check for paint in
// the overlap area.  Recursion into spx1 happens in dfFindSibPaint, and into spx2
// happens in dfConChildren.
static int dfMakeSibConnect(DfTCell*fcell)
{
    CellDef *cdef = DfTCell2Def(fcell);
    SPSearchContext *spx1, *spx2;
    DfTCell *tc1, *tc2;

    if (dfGlob.dfDebug & 1) {
	char buf1[1000];
	MsgInfoF("dfMakeSibConnect %s\n", dfTCellPath(buf1,fcell,""));
    }

    // For each child cell...
    spx1 = SPInstEnumInit(cdef,NULL,NULL,NULL,0,"dfMSC1");

    while (spx1 = SPInstEnumNext(spx1)) {
	Rect rect1, rect1plus1;
	TileTypeBitMask *mask1 = dfCellMask(spx1->spx_use->cu_def);
	DfCellInfo *info1 = DfCellDef2Info(spx1->spx_use->cu_def);

	if (dfGlob.dfDebug & 0x10) {
	    if (strcmp(cdef->cd_name,"chorus") == 0) {
		MsgInfoF("testing %s:%s at %d %d %d %d\n", cdef->cd_name,spx1->spx_use->cu_id,
		    rect1plus1.r_xbot,rect1plus1.r_ybot, rect1plus1.r_xtop,rect1plus1.r_ytop);
	    }
	}

	tc1 = dfSpx2TCellChild(fcell,spx1);
	if (tc1 == NULL || tc1->dft_type == dfext_none) continue;

	// Search for overlaping cells.  Note that spx1->spx_area is in sub-cell coord system.
	dfMBBox(spx1,&rect1);
	GEO_EXPAND(&rect1,1,&rect1plus1);

	spx2 = SPInstEnumInit(cdef,&rect1plus1, NULL,NULL,0,"dfMSC2");
	while (spx2 = SPInstEnumNext(spx2)) {
	    Transform t1inv;
	    Rect roverlap;
	    Rect r1overlap;
	    Tile *tile;
	    TileTypeBitMask intersectMask;
	    TileTypeBitMask *mask2;

	    if (dfGlob.dfDebug & 0x20) {
		    MsgInfoF("checking %s:%s vs %s\n", cdef->cd_name,spx1->spx_use->cu_id, spx2->spx_use->cu_id);
	    }


	    tc2 = dfSpx2TCellChild(fcell,spx2);
	    if (tc2 == NULL || tc2->dft_type == dfext_none) continue;

	    if (spx1->spx_use == spx2->spx_use) continue;


	    // Use cell ids to order the cells so as to check each pair only once.
	    if (strcmp(spx1->spx_use->cu_id,spx2->spx_use->cu_id) > 0) {
		// We will check this pair when use1 and use2 are reversed.
		continue;
	    }

	    // Dont check abutment between vcells if option is set.
	    if (dfGlob.dfOptNoAbutCheck && info1->dfi_type == dfext_stop && 
		DfCellDef2Info(spx2->spx_use->cu_def)->dfi_type == dfext_stop) {
		continue;
	    }

	    intersectMask = *mask1;
	    mask2 = dfCellMask(spx2->spx_use->cu_def);
	    TTMaskAndMask(&intersectMask,mask2);
	    if (TTMaskIsZero(&intersectMask)) {
		// There are NO common metal between the two cells.
		// Will happen for top level power cells and stdcells, for example.
		continue;
	    }

	    // Set roverlap to the overlap area between the two cells.
	    dfMBBox(spx2,&roverlap);
	    GEOCLIP(&roverlap,&rect1);

	    // If the rectangles are non-touching, no need to look in this area.
	    // Note we must search even if area == zero, because if the rectangles touch
	    // we must process them to look for abutting connections.
	    if (GEO_HEIGHT(&roverlap) < 0 || GEO_WIDTH(&roverlap) < 0) {
		continue;
	    }

	    GEO_EXPAND(&roverlap,1,&roverlap);

	    // Convert area to spx1 coord system.
	    {
		Transform tinv;  Rect spx1area;
		GEOINVERTTRANS(&spx1->spx_trans,&tinv);
		// We are overwriting the area in the spx struct, which is ok.
		GEOTRANSRECT(&tinv,&roverlap,&spx1->spx_area);

		// TODO: An improvement here would be to compute overlap of every
		// layer separately, by keeping bbox of each layer separately, but
		// that is too hard.  Instead, keep tiletypebitmask for each cell
		// and all hierarchically contained cells, and AND the masks
		// of the two cells to produce the result mask of planes to check.

		// TODO: Can use the new userBBox, with the dbBBoxSetUserPlanes set to dfMetalMask.
		// Is this worth the effort?  Wont it generally just give the same result
		// as the regular bbox?

		if (dfFindSibPaint(tc1,spx1,tc2,spx2,&intersectMask)) {
		    SPInstEnumTerm(spx1); SPInstEnumTerm(spx2);
		    return -1;
		}
	    }
	}
    }
    return 0;
}

// DEBUGGING THIS!!
static int DEBUG_dfMakeSibConnect(DfTCell*fcell)
{
    CellDef *cdef = DfTCell2Def(fcell);
    SPSearchContext *spx1a, *spx1, *spx2;
    DfTCell *tc1, *tc2;
    CellUse *use1;

    BPEnum bpe1;

    BPEnumInit(&bpe1,cdef->cd_cellPlane,0,BPE_ALL,"test1");

    while (use1 = BPEnumNext(&bpe1)) {
	Rect bbox, rect1, rect1plus1;

	bbox = *DBBBoxCellDef(use1->cu_def);
	GEOTRANSRECT(&use1->cu_transform,&bbox,&rect1);
	GEO_EXPAND(&rect1,1,&rect1plus1);

	MsgInfoF("testing %s:%s at %d %d %d %d\n", cdef->cd_name,use1->cu_id,
		rect1plus1.r_xbot,rect1plus1.r_ybot, rect1plus1.r_xtop,rect1plus1.r_ytop);

	{  BPEnum bpe2;

	BPEnumInit(&bpe2,cdef->cd_cellPlane,&rect1plus1,BPE_OVERLAP,"test2");
	while (BPEnumNext(&bpe2)) continue;
	BPEnumTerm(&bpe2);
	}
    }

    return 0;

    // For each child cell...
    spx1a = SPInstEnumInit(cdef,NULL,NULL,NULL,0,"dfMSC1");

    while (spx1a = SPInstEnumNext(spx1a)) {
	Rect rect1, rect1plus1;

	SPSearchContext spxbuf = *spx1a;
	spx1 = &spxbuf;

	MsgInfoF("testing %s:%s at %d %d %d %d\n", cdef->cd_name,spx1->spx_use->cu_id,
		rect1plus1.r_xbot,rect1plus1.r_ybot, rect1plus1.r_xtop,rect1plus1.r_ytop);

	//tc1 = dfSpx2TCellChild(fcell,spx1);
	//if (tc1 == NULL || tc1->dft_type == dfext_none) continue;

	// Search for overlaping cells.  Note that spx1->spx_area is in sub-cell coord system.
	dfMBBox(spx1,&rect1);
	GEO_EXPAND(&rect1,1,&rect1plus1);


	//spx2 = SPInstEnumInit(cdef,&rect1plus1, NULL,NULL,0,"dfMSC2");
	//SPInstEnumTerm(spx2);
	//while (spx2 = SPInstEnumNext(spx2)) { }

	{  BPEnum bpe2;

	BPEnumInit(&bpe2,cdef->cd_cellPlane,&rect1plus1,BPE_OVERLAP,"test2");
	while (BPEnumNext(&bpe2)) continue;
	BPEnumTerm(&bpe2);
	}
    }
    return 0;
}



// Search downward from specified cell for hierarchical connections.
// Assumes that def connectivity is already complete for def corresponding to fcell.
// Hook up the netuses.
static int dfMakeHierConnect(DfTCell *fcell)
{
    CellDef *cdef = DfTCell2Def(fcell);
    DfCellInfo *info = DfCellDef2Info(cdef);
    DfNetDef *net;
    int i;

    if (dfGlob.dfDebug & 1) {
	char buf1[1000];
	MsgInfoF("dfMakeHierConnect %s\n", dfTCellPath(buf1,fcell,""));
    }

    // For each netdef in this celldef, walk connected tiles and search for
    // connections to those tiles in lower level cells.
    // This could instead traverse all tiles on all planes,
    // but this is probably a little faster.
    //
    // TODO: Could try doing this plane by plane, and only search subcells that
    // contain metal on that plane.  However, searching only the netdefs is still
    // required for verilogleaf cells, since much of the paint in them is unconnected.
    for (i = 0, net = &info->dfi_netdefs[0]; i < info->dfi_netcnt; i++, net++) {
	Tile *tile;
	// For each tile connected to this netdef.
	if ((tile = net->dfn_tiles)) do {
	    Rect rect;
	    SPSearchContext *spxchild;
	    DfTCell *tchild;

	    TiToRect(tile,&rect);
	    GEO_EXPAND(&rect,1,&rect);

	    // TODO: It would be nice to clip rect to the bbox
	    // in cdef of the layer of tileType, but you would have to have
	    // the bbox of this layer in all contained hierarchical celluses!
	    // Very hard to compute.
	    spxchild = SPInstEnumInit(cdef,&rect, NULL,NULL,0,"dfMakeHierConnect");
	    while (spxchild = SPInstEnumNext(spxchild)) {
		tchild = dfSpx2TCellChild(fcell,spxchild);
		if (tchild == NULL || tchild->dft_type == dfext_none) continue;
		if (++dfGlob.dfOverlapCnt % 1000 == 0) { dfPrintStatus(); }
		if (dfConChildren(fcell,0,tile,tchild,spxchild) == -1) {
		    SPInstEnumTerm(spxchild);
		    return -1;
		}
	    }
	} while ((tile = dfTile2NextTile(tile)) != net->dfn_tiles);
    }

    return 0;
}


/***********************************************************************/
// Driver Functions
/***********************************************************************/



// Make connectivity for specified cell.
// Do the non-hierarchical connectivity, then check for hierarchical.
// This is a recursive process that works bottom up and establishes
// all connectivity at lower levels first, but that only processes
// lower levels as they are encountered.
static int dfMakeBothConnect(DfTCell *fcell)
{
    CellDef *cdef = DfTCell2Def(fcell);
    DfCellInfo *info = DfCellDef2Info(cdef);
    DfNetDef *net;
    int i;

    if (info->dfi_didMakeConnect) {
	return 0;
    }
    info->dfi_didMakeConnect = 1;

    if (fcell->dft_type == dfext_none) return 0;

    // Mark the cell planes dirty, since we will be modifying them.
    // Need to clean these planes up afterwards.
    info->dfi_dirtyPlanes = 1;

    // Establish non-hierarchical connectivity for this cell.
    dfMakeDefConnect(DfTCell2Def(fcell));

    // Allocate netuses for all instances of this def.
    // Done on demand, now.
#if 0
    { DfTCell *tf;  int i; DfNetUse *nu;
      int netcnt = info->dfi_netcnt;
      for (tf = info->dfi_tcells; tf; tf = tf->dft_next) {
	tf->dft_netuses = (DfNetUse*) dfMalloc(netcnt*sizeof(DfNetUse));
	// Init array of netuses.
	for (i = 0, nu = &tf->dft_netuses[0]; i < netcnt; i++, nu++) {
	  nu->u.dfu_tcell = fcell;
	  nu->dfu_next = nu;	// init circular list.
	}
      }
    }
#endif

    // Hook up netuses for connections from fcell to cells below it.
    dfMakeHierConnect(fcell);

    // Hook up netuses for siblings in fcell.
    if (dfMakeSibConnect(fcell)) {return -1;}

    // Now that we are done with the entire hierarchical tree whose head is fcell,
    // we need to copy the netuse hierarchy to any other instances of this same celldef
    // before we process any cells above fcell.

    dfCloneNetUseTree(fcell);

    // We extract connectivity on demand when a connection is discovered to a sub-cell.
    // However, to make the Clone operation work, we MUST do each sub-tree in its
    // entirety (so we can clone it) before making any connections into the sub-tree from above.
    // Example: If A contains B contains C, and there is a connection found from A to C,
    // then when examining A, dfMakeBothConnect will be called on C, but then the caller will
    // hook the netuses together from A to C.  If we later extract B, we will not be able to clone it
    // because of the connection from C to A, which goes outside the sub-tree at B.
    // Therefore, whenever we extract a cell, we must immediately extract all its parents as well,
    // to make sure we left no unextracted gaps in the tcell hierarchy.
    if (fcell->dft_parent) {
	if (dfMakeBothConnect(fcell->dft_parent)) return -1;
    }

    return 0;
}

// Call me first.
void DFConnectInit()
{
    memset(&dfGlob,0,sizeof(dfGlob));
}


// Create the connectivity database for the root cell.
// This also modifies all tiles in all hierchically referenced cells.
int DFConnectCreate(CellDef *rootDef, char *layers)
{
    int ret = 0;

    //if (setjmp(jmp_on_interrupt)) {goto interrupt;}

    if (rootDef == NULL) {
	Layout *window = LayCurWindow();
	rootDef = window->lay_rootUse->cu_def;
    }

    dfGlob.dfRootDef = rootDef;

    // Was disallowing edit-in-place, but I dont think we care.
    //if (EditCellUse->cu_def != EditRootDef) {
    //	error("edit-in-place not allowed.");
    //	return -1;
    //}

    UndoDisable();

    if (!CmdParseLayers(layers,&dfGlob.dfMetalMask)) {
	ret = -1;		// failed
	goto done;
    }
    dfGlob.dfMetalPlanes = DBPlaneListFromTypes(&dfGlob.dfMetalMask);


    // Step 1.
    // Allocate CellInfo for each def and fill them in (type, instcnt).
    // Also iterate over instances in def and set cu_client to inst number.
    if ((ret = dfStep1(dfGlob.dfRootDef))) {
	goto done;	// oops
    }
    if (SigInterruptPending) {goto interrupt;}

    // Step 2.
    // Create the tree of tcells.
    dfTCellInit(&dfGlob.dfRootTCell,dfGlob.dfRootDef,dfext_all);
    if (SigInterruptPending) {goto interrupt;}

    dfPrintStats("Tree Allocated");

    // Step 3.
    // We start at the root cell and work down, only processing cells that are touched
    // by the root cell.  This avoids doing all the work if there is only a tiny bit
    // of paint that only touches a few cells.
    // However, the connectivity is generated strictly bottom up.
    // Whenever a celldef is first touched, all connectivity within that hierarchical tree
    // is completely computed before returning to the parent.
    // Then that connectivity is copied into all flat cells of the same def.
    //
    // Iterate over paint in the def.  Find the next unmarked paint tile.
    // Create a netdef, and link all tiles into a singly linked list.
    // Search for overlapping paint in subcells.
    (void) dfMakeBothConnect(&dfGlob.dfRootTCell);

#if DF_COLORS
    dfFixNetUses(&dfGlob.dfRootTCell);
#else
#endif

    if (SigInterruptPending) {goto interrupt;}

    dfPrintStatus(); printf("\n");  // print status for the final time.
    dfPrintStats("Connectivity Done");

    UndoEnable();

    done:
    return ret;

    interrupt:
    MsgErrorF("interrupted...\n");
    DFConnectTerm();
    return -2;
}


// Free the info that can be reached from the tcell tree, including the tree itself.
static void dfFreeFtree(DfTCell *fcell)
{
    CellDef *cdef = DfTCell2Def(fcell);
    DfCellInfo *info = DfCellDef2Info(cdef);
    DfTCell *fp;
    int i;

    // Free netuses
    if (fcell->dft_netuses) {
      FREE(fcell->dft_netuses);
    }

    if (fcell->dft_children) {
	// Recur on children.
	for (fp = &fcell->dft_children[0], i = 0; i < info->dfi_instcnt; i++, fp++) {
	  dfFreeFtree(fp);
	}

	// Free the children array.
	FREE(fcell->dft_children);
    }
}


// Free the info that can be reached from the tree of defs.
static void dfRestoreDef(CellDef *cdef)
{
    PlaneList *plist;
    TileType t;
    PlaneList *pll;
    DfCellInfo *info = (DfCellInfo *)cdef->cd_client;

    if (info == NULL) {
	return;
    }

    // Make sure no one changed it when we werent looking.
    assert(info->dfi_tag == DFCellInfoTag);


    if (info->dfi_dirtyPlanes) {

	// Clean up tile planes.  First make a list of all affected planes:
	// all metal planes, and any planes connected to them.
	plist = DBPlaneListFromTypes(&dfGlob.dfMetalMask);
	for (t = 0; t < TT_MAXTYPES; t++) {
	    if (TTMaskHasType(&dfGlob.dfMetalMask,t)) {
		DBPlaneListAddList(&plist,DBConnectPlanes[t]);
	    }
	}

	// Now clean up the list of planes.
	for (pll = plist; pll; pll = pll->pll_next) {
	    dfPlaneRestore(cdef,pll->pll_num);
	}
	PlaneListFree(plist);
    }


    // free netdefs
    if (info->dfi_netdefs) {
	int n;
	DfNetDef *net = & info->dfi_netdefs[0];
	for (n = 0; n < info->dfi_netcnt; n++, net++) {
	    if (net->dfn_labels) { FREE(net->dfn_labels); }
	}
        FREE(info->dfi_netdefs);
    }

    // restore def itself.  Must be the last thing, because we use the
    // info structure stored in the def up until now.
    dfCellDefRestore(cdef);


    // process kids.  No: We dont do this hierarchically any more.
    //{
    //CellKid *kid;
    //  for (kid = cdef->cd_kids; kid; kid = kid->ck_next) {
    //    dfRestoreDef(kid->ck_def);
    //  }
    //}
}


// Restore max database
void DFConnectTerm()
{
    CellDef *def;

    dfPrintStats("Discarding Database");

    if (dfGlob.dfRootTCell.dft_type != dfext_null) {
	dfFreeFtree(&dfGlob.dfRootTCell);  // MUST do this before cleaning up defs,
				// because you need data from the CellInfo
				// structure to traverse the TCell tree.
	dfGlob.dfRootTCell.dft_type = dfext_null;	// Used as indicator we have already done this.
    }

    for (def = DBCellDefs; def; def = def->cd_next) {
      dfRestoreDef(def);
    }

    if (dfGlob.dfMetalPlanes) {
      PlaneListFree(dfGlob.dfMetalPlanes); dfGlob.dfMetalPlanes = NULL;
    }
}

/***********************************************************************/
/* Iterators for connectivity database */
/***********************************************************************/


static void dfPrintTCell(DfTCell *fc)
{
    char buf[1000];
    DfCellInfo *info = DfCellDef2Info(DfTCell2Def(fc));
    MsgInfoF("TCell %s type %d,%d sub=%d netcnt %d instcnt %d netuses=%d deftype=%d defvia=%s\n",
	dfTCellPath(buf,fc,""),fc->dft_type,info->dfi_type,
	fc->dft_sub_stop,info->dfi_netcnt,info->dfi_instcnt,fc->dft_netuses,
	info->dfi_deftype, info->dfi_vianame?info->dfi_vianame:"none");
}


typedef struct DFConEnum_s DFConEnum;
struct DFConEnum_s {
    DfTCell *dfc_tcell;
    int dfc_netnum;
    unsigned int dfc_bSkipNonExtracted:1;
};


// In-order traversal of tcell tree.  Pass it the head of the tree as the first tcell.
DfTCell *DFTCellEnumNext(DFConEnum *dfc)
{
    DfTCell *fc = dfc->dfc_tcell;

    // Initial case.
    if (fc == NULL) {
	fc = &dfGlob.dfRootTCell;
	goto ret;
    }

    while (1) {

	if (fc->dft_children) {
	    fc = & fc->dft_children[0];

	  ret:
	    ASSERT(fc->dft_tag == DFTCellTag,"invalid tcell");
	    // Lets do a little error checking as we go.
	    switch (fc->dft_type) {
		case dfext_stop:
		case dfext_all:
		    break;
		case dfext_none:
		    // This fc is not extracted
		    if (dfc->dfc_bSkipNonExtracted) {
			continue;  // find next tcell.
		    }
		    break;
		default:
		    printf("bad type: %d ",fc->dft_type);
		    ASSERT(0,"bad dft_type");
	    }

	    // Return this tcell.
	    dfc->dfc_tcell = fc;
	    return fc;
	}

	// No children, try sibling.
	if (fc->dft_parent == NULL) {
	    // Can get here if the tree is totally empty except for the head.
	    return NULL;
	}

	while (1) {
	    int n = DfTCell2CellInstNum(fc);
	    DfCellInfo *parentinfo = DfCellDef2Info(DfTCell2Def(fc->dft_parent));
	    ASSERT(parentinfo->dfi_tag == DFCellInfoTag,"bad cell info");

	    // Is there a next sibling?
	    if (++n < parentinfo->dfi_instcnt) {
		fc = & fc->dft_parent->dft_children[n];
		goto ret;
	    }

	    // Pop up
	    fc = fc->dft_parent;
	    if (fc == &dfGlob.dfRootTCell) {
		dfc->dfc_tcell = NULL;	// all done.
		return NULL;
	    }
	}
    }
}

// Enumerate TCells in no particular order.
void DFTCellEnumInit(DFConEnum *dfc)
{
    memset(dfc,0,sizeof(DFConEnum));
}

#if 0 // old
DfTCell *DFTCellEnumNext_UNUSED(DFConEnum *dfc)
{
    // Cheat.  It is easier to enumerate linked lists than trees.

    if (dfc->dfc_tcell) {
	dfc->dfc_tcell = dfc->dfc_tcell->dft_next;
    }

    // If first time here, initialize.
    if (dfc->dfc_def == NULL) {
	dfc->dfc_def = DBCellDefs;
    }

    while (1) {
	if (dfc->dfc_tcell) {
	    if (dfc->dfc_tcell->dft_tag != DFTCellTag) {ASSERT(0,"invalid fcell");}
	    switch (dfc->dfc_tcell->dft_type) {
	    case dfext_null: ASSERT(0,"bad dft_type");
	    case dfext_stop:
	    case dfext_all:
		return dfc->dfc_tcell;
	    case dfext_none:
		continue;
	    }
	}

	// Try the next celldef
	dfc->dfc_def = dfc->dfc_def->cd_next;
	if (dfc->dfc_def == NULL) { return NULL; }
	if (dfc->dfc_def->cd_client == (ClientData)NULL) {
	    continue;
	}
	dfc->dfc_tcell = DfCellDef2Info(dfc->dfc_def)->dfi_tcells;
    }
}
#endif


// Enumerate Nets.
// Each net is represented by a circularly linked list of NetUse.
void DFNetUseEnumInit(DFConEnum *dfc)
{
    DfTCell *fc;

    // Start by unsetting the flag in all netuses.
    // TODO: It is already unset the first time through,
    // so it would be better to unset it at the end.
    DFTCellEnumInit(dfc);
    while (fc = DFTCellEnumNext(dfc)) {
	DfCellInfo *info = DfCellDef2Info(DfTCell2Def(fc));
	int i;
	if (fc->dft_netuses == NULL) {continue;}
	for (i = 0; i < info->dfi_netcnt; i++) {
	    fc->dft_netuses[i].u.dfu_flag &= ~1;
	}
    }


    DFTCellEnumInit(dfc);
    // Get the first cell.  It is left in dfc->dfc_tcell.
    DFTCellEnumNext(dfc);
    dfc->dfc_netnum = -1;	// Will get first netuse in dfc->dfc_tcell.
}

// Traverse the netuses in every tcell.
// If con_only, do not return netuses that are in cells marked sub_stop,
// and return only nets that either have some paint attached,
// or that have two netuses hooked together, indicating an abutting connection.
DfNetUse  * DFNetUseEnumNext(DFConEnum *dfc, int con_only)
{
    DfTCell *fc, *prev_tc;
    DfCellInfo *info;
    DfNetUse *nu, *nu2;
    int fndpaint;
    int connections;	// number of netuses hooked in a chain.

    fc = dfc->dfc_tcell;
    if (fc == NULL) {
	return NULL;	// all done.
    }

    // Search in the current tcell for a netuse whose chain has not previously been seen.
    // If not found, search other tcells.
    while (1) {
	if (dfGlob.dfDebug & 2) {
	    char tname[1000];
	    MsgInfoF("NetUseEnumNext fc %s netnum %d\n",dfTCellPath(tname,fc,""),dfc->dfc_netnum+1);
	}
	if (fc->dft_netuses == NULL) {
	    // There were no hierarchical connections into this cell.
	    next_cell:
	    dfc->dfc_netnum = -1;
	    fc = dfc->dfc_tcell = DFTCellEnumNext(dfc);
	    if (fc == NULL) {return NULL;}   // all done
	    continue;
	}

	if (fc->dft_type == dfext_none) {
	    goto next_cell;
	}

	info = DfCellDef2Info(DfTCell2Def(fc));

	// get next net in this TCell.
	dfc->dfc_netnum++;
	if (dfc->dfc_netnum >= info->dfi_netcnt) {
	    goto next_cell;
	}

	// We already checked above to insure they exist.
	nu = dfGetNetUse(fc,dfc->dfc_netnum);

	// Is the flag set?  If so, we have already processed this one.
	if (nu->u.dfu_flag & 1) {
	    continue;
	}

	// halleluia
	// Set the flag in all netuses in this chain,
	// to mark them as seen.
	connections = fndpaint = 0;
	prev_tc = NULL;
	nu2 = nu; do {
	    nu2->u.dfu_flag |= 1;	// mark netuse as seen.
	    if (con_only) {
		DfTCell *fc2 = DfNetUse2TCell(nu2);
		DfCellInfo *info2;
		DfNetDef *net;

		// Only return nets that are marked to be extracted.
		if (fc2->dft_sub_stop) { continue; }

		// Multiple connections of a vcell to itself dont count.
		// This happens, for example, when there is a via in
		// a tcell: there are two netdefs on each side of the via
		// connected together by their netuses.
		if (fc2 != prev_tc) {connections++;}
		prev_tc = fc2;
		net = DfNetUse2NetDef(nu2);
		info2 = DfCellDef2Info(DfTCell2Def(fc2));
		if (info2->dfi_deftype == dfd_hier && net->dfn_tiles != NULL) {
		    fndpaint = 1;
		}

		// TODO: Is this right?   I took this out because the net
		// must be returned if it has paint.  The check for sub_stop
		// is sufficient.
		//if (! info2->dfi_extPins) { continue; }
	    }
	} while ((nu2=nu2->dfu_next) != nu);

	if (fndpaint || connections > 1 || ! con_only) {
	    return nu;
	}
    }
}


// Compare two labels, and return the winner.
// This is used to choose which of two labels at the same hierarchical level should be picked.
static Label * dfChooseLabel(Label *lab1, Label *lab2)
{
    int kind1 = lab1->lab_kind;
    int kind2 = lab2->lab_kind;
    if (kind1 == LAB_GLOBAL) { return lab1; }
    if (kind2 == LAB_GLOBAL) { return lab2; }
    if (kind1 == LAB_LOCAL) { return lab1; }
    if (kind2 == LAB_LOCAL) { return lab2; }
    if (kind1 == LAB_OUTPUT) { return lab1; }
    if (kind2 == LAB_OUTPUT) { return lab2; }
    if (kind1 != LAB_COMMENT) { return lab1; }
    return lab2;
}

// Return the best label in the array of labels.
static Label *dfChooseLabelFromList(Label **labels)
{
    Label *best = labels[0];
    int n;
    for (n = 1; labels[n]; n++) {
	best = dfChooseLabel(best,labels[n]);
    }
    return best;
}


// Look for DEF properties in the label names.
// Properties are specified as: +NAME[:value]
// An example label:  foo+FIXED+PATTERN:TRUNK+WEIGHT:10+USE:CLOCK


// Get the hierarchial name of a netuse.
// Return the label in highest cell.
// If net_props is non-null, point it to the string of label properties.
// If multiple labels have properties, they must all be the same.
// If no name and default is non-null, make up a name using default as the base name.
char *DFNetUseName(char *buf,DfNetUse *nu,char *default_name,char *net_props_buf)
{
    DfNetUse *nu2;

// highest hierarchical level is 0, increments to lower levels of hiearchy.
#define LOWEST_NET_LEVEL 0x7fffffff
    DfNetUse *highest_nu = 0;	// unneeded initialization to quiet gcc
    int highest_level = LOWEST_NET_LEVEL;
    int highest_label_level = LOWEST_NET_LEVEL;
    DfNetUse *highest_label_nu = 0;	// unneeded initialization to quiet gcc
    Label *highest_label = 0;	// unneeded initialization to quiet gcc
    // The TCell in which props_label was found
    DfTCell *props_fc = 0;	// unneeded initialization to quiet gcc
    Label *props_label = 0;	// unneeded initialization to quiet gcc

    if (net_props_buf) {*net_props_buf = 0;}  // paranoid

    nu2 = nu; do {
	DfNetDef *net = DfNetUse2NetDef(nu2);
	DfTCell *fc2 = DfNetUse2TCell(nu2);
	if (net->dfn_labels && fc2->dft_level <= highest_label_level) {
	    Label *best = dfChooseLabelFromList(net->dfn_labels);
	    if (fc2->dft_level == highest_label_level) {
		// If two labels are at the same hierarchical level, pick the best.
		best = dfChooseLabel(best,highest_label);
		if (best == highest_label) {
		    // The old label is still the best
		    continue;
		}
	    }
	    highest_label_level = fc2->dft_level;
	    highest_label_nu = nu2;
	    highest_label = best;
	}

	if (fc2->dft_level < highest_level) {
	    highest_level = fc2->dft_level;
	    highest_nu = nu2;
	}

	// If net_props_buf is not 0, See if any of the labels have properties affixed.
	if (net_props_buf && net->dfn_labels) {
	    int n;
	    char *pp;
	    Label **labels = net->dfn_labels;
	    for (n = 1; labels[n]; n++) {
		if ((pp = strchr(labels[n]->lab_text,'+'))) {
		    // This label has properties.
		    
		    // Check validity, must start with +FIXED,+ROUTED or +COVER:
		    if (strncmp(pp,"+FIXED",sizeof("+FIXED")) &&
			strncmp(pp,"+ROUTED",sizeof("+ROUTED")) &&
			strncmp(pp,"+COVER",sizeof("+COVER"))) {
			    char tmpbuf1[1000];
			dfWarn("Unrecognized properties on label ignored: %s\n",
				dfTCellPath(tmpbuf1,fc2,labels[n]->lab_text));
			continue;
		    }

		    // Check for conflicts between properties on different labels.
		    if (net_props_buf[0]) {
			if (strcmp(pp,net_props_buf)) {
			    char tmpbuf1[1000], tmpbuf2[1000];
			    dfWarn("Properties on labels differ (using longest): %s %s\n",
				dfTCellPath(tmpbuf1,fc2,labels[n]->lab_text),
				dfTCellPath(tmpbuf2,props_fc,props_label->lab_text));
			}
			// Keep the longest one, on the theory that it is most likely to be correct.
			if (strlen(net_props_buf) >= strlen(pp)) { continue; }
		    }

		    // Use the DEF properties on this label.
		    strcpy(net_props_buf,pp);
		    props_label = labels[n];
		    props_fc = fc2;
		}
	    }
	}

    } while ((nu2=nu2->dfu_next) != nu);

    if (highest_label_level != LOWEST_NET_LEVEL) {
	// Note: There could be multiple labels on this net.
	// We are just using the first one.
	char *netname = DfNetUse2NetDef(highest_label_nu)->dfn_labels[0]->lab_text;
	dfTCellPath(buf,DfNetUse2TCell(highest_label_nu),netname);
    } else {
	// No label found.
	if (default_name) {
	    char netname[100];
	    sprintf(netname,"%s%d",default_name,DfNetUse2NetNum(nu2));
	    dfTCellPath(buf,DfNetUse2TCell(highest_nu),netname);
	} else {
	    return NULL;	// no label found.
	}
    }

    return buf;
}

static void dfPrintNetDefLabels(DfNetDef *net)
{
    if (net->dfn_labels) {
	Label **lab;
	for (lab = net->dfn_labels; *lab; lab++) {
	    MsgInfoF("%s ",(*lab)->lab_text);
	}
    }
}

void DFConnectTest()
{
    DFConEnum dfc;
    CellDef *def;

    MsgInfoF("Metal Planes:");
    dfPrintPlaneList(dfGlob.dfMetalPlanes);
    MsgInfoF("*** Mask Database ***\n");
    { CellDef *def;
	for (def = DBCellDefs; def; def = def->cd_next) {
	    MsgInfoF("Cell %s mask:",def->cd_name);
	    dfPrintMask(dfCellMask(def));
	}
    }

    { DfTCell *fc;
	DFTCellEnumInit(&dfc);
	while (fc = DFTCellEnumNext(&dfc)) {
	    dfPrintTCell(fc);
	}
    }

    // Dump the def tile data-base.
    MsgInfoF("*** NetDef Database ***\n");
    for (def = DBCellDefs; def; def = def->cd_next) {
	DfCellInfo *info;  int i;
	if (!def->cd_client) continue;
	info = DfCellDef2Info(def);
	MsgInfoF("Def %s %d netdefs (didMakeConnect=%d)\n",def->cd_name,info->dfi_netcnt,info->dfi_didMakeConnect);
	for (i = 0; i < info->dfi_netcnt; i++) {
	    DfNetDef *net = & info->dfi_netdefs[i];
	    Tile *tile;
	    tile = net->dfn_tiles; do {
		Rect tirect;  DfNetDef *tinet = dfTile2NetDef(def,tile);
		TiToRect(tile,&tirect);
		ASSERT(net == tinet,"bad tile net");
		MsgInfoF("\tNet %d Tile: %s %d %d %d %d ",
		    DfNetDef2NetNum(def,net),
		    DBTypeLongName(DBgetTileType(tile)),
		    tirect.r_xbot,tirect.r_ybot, tirect.r_xtop,tirect.r_ytop);
		if (net->dfn_labels) { dfPrintNetDefLabels(net); }
		else { MsgInfoF("no labels"); }
		MsgInfoF("\n");
	    } while ((tile = dfTile2NextTile(tile)) != net->dfn_tiles);
	}
    }

    // For each netuse chain.
    {
	DfNetUse *nu, *nu2;
	MsgInfoF("*** NetUse Database ***\n");
	DFNetUseEnumInit(&dfc);
	while (nu = DFNetUseEnumNext(&dfc,0)) {
	    char buf[10000];
	    MsgInfoF("NetUse: %s\n",DFNetUseName(buf,nu,"$NET",0));

	    // Enumerate the netuses in this chain.
	    nu2 = nu;
	    do {
		DfNetDef *net = DfNetUse2NetDef(nu2);
		DfTCell *fc2 = DfNetUse2TCell(nu2);
		CellDef *def2 = DfTCell2Def(fc2);
		DfCellInfo *info2 = DfCellDef2Info(def2);
		// Enumerate paint on this netdef.
		Tile *tile;
		char tname[10000];
		MsgInfoF("    Tcell %s (%s) NetDef: %d sub_stop=%d deftype=%d ",
		    dfTCellPath(tname,fc2,""),
		    def2->cd_name,DfNetDef2NetNum(def2,net),
		    fc2->dft_sub_stop,info2->dfi_deftype);
		if (net->dfn_labels) { dfPrintNetDefLabels(net); }
		else { MsgInfoF("no labels"); }
		MsgInfoF("\n");

		tile = net->dfn_tiles; do {
		    Rect tirect;  Transform trans;
		    TiToRect(tile,&tirect);
		    DFTCell2Trans(fc2,&trans);
		    GeoTransRect(&trans,&tirect,&tirect);
		    MsgInfoF("\tTile: %s %d %d %d %d\n", 
			DBTypeLongName(DBgetTileType(tile)),
			tirect.r_xbot,tirect.r_ybot, tirect.r_xtop,tirect.r_ytop);
		} while ((tile = dfTile2NextTile(tile)) != net->dfn_tiles);
	    } while ((nu2=nu2->dfu_next) != nu);
	}
    }
}


// Print the tiles, if any, attached to the netdef associated with this netuse.
// Return true if any tiles were printed.
bool dfDefPrintTiles(FILE *pf,DfNetUse *nu,char *net_props_buf)
{
    DfNetDef *net = DfNetUse2NetDef(nu);
    DfTCell *fc = DfNetUse2TCell(nu);
    Tile *tile;
    Transform trans;
    bool result = FALSE;
    DFTCell2Trans(fc,&trans);

    if ((tile = net->dfn_tiles)) do {
	Rect tirect, defrect;
	int xlen, ylen;
	int dir;
	TiToRect(tile,&tirect);
	GeoTransRect(&trans,&tirect,&tirect);

	// Convert tirect to DEF units.
	// (Currently same as max units.)
	defrect.r_xbot = tirect.r_xbot * dfGlob.dfDefFactor;
	defrect.r_ybot = tirect.r_ybot * dfGlob.dfDefFactor;
	defrect.r_xtop = tirect.r_xtop * dfGlob.dfDefFactor;
	defrect.r_ytop = tirect.r_ytop * dfGlob.dfDefFactor;

	fprintf(pf,"\n%s %s ",net_props_buf,dfDefLayerName(DBgetTileType(tile)));
	strcpy(net_props_buf,"  NEW");

	// If one of the dimensions is odd, user the other.
	// Otherwise, use th enarrower dimension as the width (for no good reason)
	xlen = defrect.r_xtop - defrect.r_xbot;
	ylen = defrect.r_ytop - defrect.r_ybot;
	dir = xlen > ylen;
	if (xlen%2 == 1) {
	    if (ylen%2 == 1) {
		dir = 1;
		// TODO: You should get this message once per def, not once per use.
		dfWarn("odd size rectangle at %g %g %g %g rounded up\n",
		    UnitsI2D(tirect.r_xbot),UnitsI2D(tirect.r_ybot),UnitsI2D(tirect.r_xtop),UnitsI2D(tirect.r_ytop));
	    }
	} else if (ylen%2 == 1) {
	    dir = 0;
	}

	if (dir) {
	    int width = ylen;
	    int ymid = (defrect.r_ytop + defrect.r_ybot + 1)/2;
	    fprintf(pf,"%d ( %d %d ) ( %d * )",width,defrect.r_xbot,ymid,defrect.r_xtop);
	} else {
	    int width = xlen;
	    int xmid = (defrect.r_xtop + defrect.r_xbot + 1)/2;
	    fprintf(pf,"%d ( %d %d ) ( * %d )",width,xmid,defrect.r_ybot,defrect.r_ytop);
	}
	result = TRUE;
    } while ((tile = dfTile2NextTile(tile)) != net->dfn_tiles);
    return result;
}


// Ouput a DEF via to file pf.  Return TRUE if we actually output something.
bool dfDefPrintVia(FILE *pf,DfTCell *fc,char *net_props_buf)
{
    Transform trans;
    Point center;		// via center in root cell coords.
    Rect *bbox;
    int xsize, ysize;
    CellDef *def = DfTCell2Def(fc);
    DfCellInfo *info = DfCellDef2Info(def);
    TileType mtype;
    char *vianame;

    bbox = DBBBoxCellDef(def);

    xsize = dfGlob.dfDefFactor * (bbox->r_xtop - bbox->r_xbot);
    ysize = dfGlob.dfDefFactor * (bbox->r_ytop - bbox->r_ybot);

    // We should have checked this when we marked the vias to be used in the DEF section:
    // they MUST not have an odd height or width.
    ASSERT(xsize % 2 == 0 && ysize % 2 == 0, "odd width or height via");

    // We Place the cell using its center. All geometry was reoriented
    // to the center when we defined the via.
    // MMI vias have the origin in the center anyway, so none of that matters.
    center.p_x = xsize / 2;
    center.p_y = ysize / 2;
    DFTCell2Trans(fc,&trans);
    GeoTransPoint(&trans,&center,&center);

    vianame = info->dfi_vianame;
    if (vianame == 0) {
	vianame = def->cd_name;
    }

    if (dfTransIsRotated(&trans)) {
	// Use the rotated via cell name.
	if (info->dfi_vianame_r90) {
	    vianame = info->dfi_vianame_r90;
	} else if (xsize != ysize) {
	    if (! info->dfi_error2) {
		dfWarn("Via %s is used rotated but is not 4-way symmetric\n",fc->dft_celluse->cu_id);
		info->dfi_error2 = 1;
	    }
	}
    }

    {
	// Snarf the metal tile types out of the via.
	// Just use the first one found.
	// Note: to go in the NETS/SPECIALNETS section the VIA must
	// have contain only two metal tiles.
	Tile *tile;
	DfNetDef *net;
	ASSERT(info->dfi_netcnt == 1,0);
	net = DfCellDef2NetDefs(def);
	mtype = 0;
	tile = net->dfn_tiles; do {
	    if (TTMaskHasType(&dfGlob.dfMetalMask,DBgetTileType(tile))) {
		mtype = DBgetTileType(tile);
		break;
	    }
	} while ((tile = dfTile2NextTile(tile)) != net->dfn_tiles);
	ASSERT(mtype != 0,"invalid def via");	// logic error: these should have been found earlier.
    }

    fprintf(pf,"\n%s ",net_props_buf);
    strcpy(net_props_buf,"  NEW");

    // Originally jdj thought cadence wroute would not connect to vias, only to metal,
    // so we needed to add little pieces of metal above and below the via.
    // But we are not doing that any more.
    // The width here is irrelevant, but nl may not be able to handle zero width, so use 2.
    fprintf(pf,"%s 2 ( %d %d ) %s",dfDefLayerName(mtype),
	center.p_x,center.p_y,vianame);
    return TRUE;
}


// Does the specified netuse connect to anything hierarchically above it?
int dfNetUseHasUpCon(DfNetUse *nu)
{
    DfTCell *fc = DfNetUse2TCell(nu);
    int level = fc->dft_level;
    DfNetUse *nu2;

    nu2 = nu; do {
	DfTCell *fc2 = DfNetUse2TCell(nu2);
	if (fc2->dft_level < level) return 1;
    } while ((nu2=nu2->dfu_next) != nu);
    return 0;	// not found.
}


// Write the DEF NETS section the specified open file descriptor.
// Notes: JDJ uses "local" type labels for pre-routed paint.
// He reserves "global type labels to indicate to the LVS tool that
// the associated net is guaranteed to be connected.
// Note: Reading GDS drops a "local" label on "space" at the origin of every cell.

// Add props to end of label name "+FIXED" "+ROUTED" "+COVER" "+NET" (goes in NETS section instead
// SPECIALNETS section.  Allow these as comment labels?

// To preserve whether paint was in NETS or SPECIALNETS section, could read it in to two
// different cells.  If you put a label on it to mark it, the specified options
// will go in both NETS and SPECIALNETS sections.

void DFDefOutputNets(FILE *pf, int bConnected)
{
    DFConEnum dfc;
    DfNetUse *nu, *nu2;

    DFNetUseEnumInit(&dfc);
    while (nu = DFNetUseEnumNext(&dfc,bConnected)) {
	char net_name[10000];
	char tmp_buf[100];
	char net_props_tmp[1000];
	char net_props[1000];
	bool incomment;

	// Output the net name.
	// If the net is not connected to any labels, make up a name.
	net_props_tmp[0] = 0;
	sprintf(tmp_buf,"$UNCONNECTED_NET%d",++dfGlob.dfUnconNetCnt);
	DFNetUseName(net_name,nu,tmp_buf,net_props_tmp);
	//if (! DFNetUseName(net_name,nu,0,net_props_tmp)) {
	    //sprintf(net_name,"$UNCONNECTED_NET%d",++dfGlob.dfUnconNetCnt);
	//}
	fprintf(pf,"- %s",net_name);
	incomment = FALSE;


	// Output the connectivity.
	// Of course, we can only output connectivity for pins that have been connected
	// with paint in max.
	// Enumerate the netuses in this chain.
	nu2 = nu;
	do {
	    DfTCell *fc = DfNetUse2TCell(nu2);
	    DfCellInfo *info = DfCellDef2Info(DfTCell2Def(fc));
	    DfNetDef *net;

	    if (fc->dft_sub_stop) { continue; }
	    if (! info->dfi_extPins) { continue; }
	    
	    net = DfNetUse2NetDef(nu2);
	    if (net->dfn_labels) {
		int n;  Label *lab; char buf[1000];
		for (n = 0; (lab = net->dfn_labels[n]); n++) {
		    int kind = lab->lab_kind;
		    if (kind == LAB_INPUT || kind == LAB_OUTPUT || kind == LAB_INOUT || kind == LAB_GLOBAL) {
			if (info->dfi_deftype != dfd_component) {
			    // TODO: Only print one of these per cell.
			    // What should we do now?
			    dfWarn("Cell '%s' label '%s': I/O label found in non-verilog cell.\n",
				    DfTCell2Def(fc)->cd_name,lab->lab_text);
			    goto print_as_alias;
			}
			// The router only wants to see these connections in the specialnets
			// section if they have actually been hooked up, so check first to
			// see if the label has been connected to something hierarchically above it.
			// CHANGED: The Enum already checked to make sure that this netuse has a connection.
			// It might not have an upcon if it is an abutment connection.
			//if (dfNetUseHasUpCon(nu2)) {
			    fprintf(pf,"\n ( %s %s )", dfTCellPath(buf,fc,0), lab->lab_text);
			    incomment = FALSE;
			//} else {
			// goto print_as_alias;
			//}
		     } else if (kind == LAB_LOCAL) {
			print_as_alias:
			dfTCellPath(buf,fc,lab->lab_text);
			if (strcmp(buf,net_name)) {
			    fprintf(pf,"\n# alias %s", buf);
			}
			incomment = TRUE;
		     }
		}
	    }
	} while ((nu2=nu2->dfu_next) != nu);


	// Output the paint on the net.
	// First look for properties on this electrical net.
	// (These were specified in labels.)

	if (net_props_tmp[0] == 0) {
	    strcpy(net_props,"+ FIXED");		// Default net props
	} else {
	    // Fix up the net_props: no spaces were allowed in max labels,
	    // so change "+whatever" to "+ whatever", and change colons to spaces.
	    char *cp, *np;
	    for (cp = net_props_tmp, np = net_props; *cp; cp++) {
		if (*np == '+') { *np++ = '+'; *np++ = ' '; }
		else if (*np = ':') { *np++ = ' '; }
		else { *np++ = *cp; }
	    }
	    *np = 0;
	}

	// Enumerate the netuses in this chain, again.
	nu2 = nu;
	do {
	    DfTCell *fc = DfNetUse2TCell(nu2);
	    DfCellInfo *info = DfCellDef2Info(DfTCell2Def(fc));

	    if (fc->dft_sub_stop) { continue; }

	    if (info->dfi_deftype == dfd_netvia) {
		// If it is a small via, output it as a via in the NETS/SPECIALNETS section.
		// TODO: Need to generate VIA names for Gcells (and others)

		// NOTE: The via MUST have only one netdef, or it would have multiple
		// netuses in this netuse chain, in which case we might try to output it twice.
		// It can have multiple netdefs only if it has internal hierarchy
		// or has internal paint that is not connected.  Lets assert this.
		if (info->dfi_netcnt == 1,"bad via cell") {
		    MsgErrorF("bad via cell (netcnt > 1): %s\n",DfTCell2Def(fc)->cd_name);
		    return;
		}

		if (dfDefPrintVia(pf,fc,net_props)) { incomment = FALSE; }

	    } else if (info->dfi_deftype == dfd_hier) {
		// We only print out paint in hiearchical cells.
		// Enumerate paint on the netdef attached to this particular netuse.
		if (dfDefPrintTiles(pf,nu2,net_props)) { incomment = FALSE; }
	    }
	} while ((nu2=nu2->dfu_next) != nu);
	// End of that net.

	if (incomment) { fprintf(pf,"\n "); }
	fprintf(pf," ;\n");

    }
}

int DFDefCountNets(int bConnected)
{
    int TotalNetCnt;
    DFConEnum dfc;
    DfNetUse *nu;

    // This is pretty goofy. Traverse the entire netuse tree just to count em.
    // If flag is set, count only nets that have paint attached.
    TotalNetCnt = 0;
    DFNetUseEnumInit(&dfc);
    while (nu = DFNetUseEnumNext(&dfc,bConnected)) {
	TotalNetCnt++;
    }
    return TotalNetCnt;
}


// DEF Writing: Pick (one of the) highest label names for the net name.
// Add aliases as comments.
// By default, all prerouted pins and paint go in SPECIALNETS section.
// Add ability to merge max paint into an existing DEF file.
// Note: It turned out we couldnt use this, because the tcl def writer
// must include blockage nets in the specialnets section, as well as real nets.
int DFDefWriteNets(FILE *pf)
{
    int TotalNetCnt = DFDefCountNets(1);

    // TODO: Need to do this twice, once for NETS and once for SPECIALNETS.
    // Only paint in specially marked cells goes into NETS.  Maybe just paint
    // in a single specific cell?

    fprintf(pf,"SPECIALNETS %d ;\n",TotalNetCnt);

    DFDefOutputNets(pf,1);

    fprintf(pf,"END SPECIALNETS\n");

    return 0;
}


static void dfGetBBox(CellDef *def, Rect *bbox)
{
    static TileType prbType = -100;

    if (prbType < 0) {
	TileType type;
	if ((type = DBTechNameType("PRB")) < 0) {
	    type = DBTechNameType("prb");
	}
	if (type < 0 && prbType == -100) {
	    MsgErrorF("Can not find a layer called PRB or prb\n");
	}
	prbType = type;
    }


    if (prbType >= 0) {
	if (DBBBoxPlane(def->cd_planes[DBPlane(prbType)], bbox)) {
	    return;	// success
	} else {
	    DfCellInfo *info = DfCellDef2Info(def);
	    if (! info->dfi_error1) {
		// print this message only once per cell.
		dfWarn("No prb layer found in cell %s, using cell bounding box for size\n",def->cd_name);
		info->dfi_error1 = 1;
	    }
	}
    }

    *bbox = *DBBBoxCellDef(def);
}


static void dfDefOut1Comp(FILE *pf, SPSearchContext *spx,DfTCell *tc)
{
    CellUse *use = tc->dft_celluse;
    char *defori;
    char modnamebuf[1000];
    char tmpbuf[10000], instbuf[10000];
    Rect bbox;
    int defx, defy;
    int xsize, ysize;
    Point zero;		// Origin in child coords (0,0)
    Point origin;	// Origin in root cell coords.
    zero.p_x = zero.p_y = 0;

    GeoTransPoint(&spx->spx_trans,&zero,&origin);

    dfGetBBox(use->cu_def,&bbox);

    xsize = bbox.r_xtop - bbox.r_xbot;
    ysize = bbox.r_ytop - bbox.r_ybot;

    switch (DFTrans2DefOri(&spx->spx_trans)) {
    case DFDefOri_N:
	defori = "N";
	defx = origin.p_x;
	defy = origin.p_y;
	break;
    case DFDefOri_FN:
	defori = "FN";
	defx = origin.p_x - xsize;
	defy = origin.p_y;
	break;
    case DFDefOri_FS:
	defori = "FS";
	defx = origin.p_x;
	defy = origin.p_y - ysize;
	break;
    case DFDefOri_S:
	defori = "S";
	defx = origin.p_x - xsize;
	defy = origin.p_y - ysize;
	break;
    case DFDefOri_E:
	defori = "E";
	defx = origin.p_x;
	defy = origin.p_y - xsize;
	break;
    case DFDefOri_FE:
	defori = "FE";
	defx = origin.p_x - ysize;
	defy = origin.p_y - xsize;
	break;
    case DFDefOri_FW:
	defori = "FW";
	defx = origin.p_x;
	defy = origin.p_y;
	break;
    case DFDefOri_W:
	defori = "W";
	defx = origin.p_x - ysize;
	defy = origin.p_y;
	break;
    default: ASSERT(0,0);
	return;	// makes the parser happy
    }


    // The instance path name must not include GROUP names or cells that
    // are specially marked.


    fprintf(pf,"- %s %s + PLACED ( %d %d ) %s ;\n",
	DFUnfixName(instbuf,dfTCellPath(tmpbuf,tc,0)),
	DFUnfixName(modnamebuf,use->cu_def->cd_name),
	dfGlob.dfDefFactor * defx, dfGlob.dfDefFactor * defy,
	defori);
}


// Recursive routine to output DEF component section.
// Return count of components.  If pf is non-NULL, output a line for each componenet.
static int dfDefOutComps(FILE *pf, SPSearchContext *spx, DfTCell *tc)
{
    SPSearchContext *spxchild;
    DfTCell *tchild;
    DfCellInfo *info;
    int count = 0;

    if (tc->dft_sub_stop) return 0;
    if (tc->dft_type == dfext_none) return 0;

    info = DfCellDef2Info(DfTCell2Def(tc));
    if (info->dfi_deftype == dfd_component) {

	// Output this cell.

	if (pf) {
	    dfDefOut1Comp(pf,spx,tc);
	} else {
	    count++;
	}

    } else {

	// Hierarchical cell.  Traverse its children.
	spxchild = SPsxInstEnumInit(spx,"");
	while (spxchild = SPInstEnumNext(spxchild)) {
	    tchild = dfSpx2TCellChild(tc,spxchild);
	    if (tchild) {
		count += dfDefOutComps(pf,spxchild,tchild);
	    }
	}
    }
    return count;
}


// This hierarchically traverses starting at the root cell and counts
// cell marked as a verilog or component cells.
int DFDefCountComponents()
{
    SPSearchContext *spx;
    int count = 0;
    DfTCell *troot = &dfGlob.dfRootTCell;
    spx = SPInstEnumInit(dfGlob.dfRootDef,0,0,0,0,"DFDOC");
    while (spx = SPInstEnumNext(spx)) {
	DfTCell *tc = dfSpx2TCellChild(troot,spx);
	if (tc) {
	    count += dfDefOutComps(NULL,spx,tc);
	}
    }
    return count;
}


// This hierarchically traverses starting at the root cell and outputs any
// cell marked as a verilog or component cells.
void DFDefOutputComponents(FILE *pf)
{
    SPSearchContext *spx;
    DfTCell *troot = &dfGlob.dfRootTCell;

    spx = SPInstEnumInit(dfGlob.dfRootDef,0,0,0,0,"DFDOC");
    while (spx = SPInstEnumNext(spx)) {
	DfTCell *tc = dfSpx2TCellChild(troot,spx);
	if (tc) {
	    dfDefOutComps(pf,spx,tc);
	}
    }
}


// TODO: Function to enumerate all paint connected to a net.


// TODO: Find net connected to instance port?


// TODO: Enumerate all labels connected to a net.
