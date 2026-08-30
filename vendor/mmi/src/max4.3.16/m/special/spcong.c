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

#include <stdio.h>
#include <string.h>
#include "main.h"
#include "magic.h"
#include "database.h"
#include "databaseInt.h"
#include "geometry.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "databaseInt.h"
#include "message.h"
#include "signals.h"
#include "utils.h"
#include "units.h"
#include "special.h"

static char *rcsid = "$Header: /volume/mmi/src/max/m/special/RCS/spcong.c,v 1.1 2002/02/19 22:56:30 pat Exp $";


// Holds data for one set of slots.
typedef struct spCongDBinStruct {
    char *bins;
    int xsize;		// Single slot width in max units
    int ysize;		// Single slot height in max units
    int xnslots;	// Total number of slots in x.
    int ynslots;	// Total number of slots in y.
    int slotsperbin;   // Number of slots in each global bin.  Note that:
			// for horizontal congestion, 
			// # slots in y dir = slotsperbin, and # slots in x dir = 1.
			// for vertical congestion, 
			// # slots in y dir = 1, and # slots in x dir = slotsperbin.
    TileTypeBitMask mask;	// mask of layers to search.
    int layercnt;	// Number of layers we are counting.
    // layerBitIndex is 0 for uninitialized, 1 for first bit, 2 for next, etc.
    int layerBitIndex[TT_MAXTYPES+1];	// +1 for good luck
} spCongDBin;

// Each bin represents a two dimensional array of size: bin.xnslots x bin.ynslots,
// arranged such that x index increments more rapidly.
// This macro accesses a specific element.
#define SPCONGBINELEMENT(bin,x,y) ((bin).bins[(x) + (y) * (bin).xnslots])

struct spCongDataStruct {
    spCongDBin h, v;	// horizontal, vertical congestion data.
    Rect area;		// area in max units.
    int gxnbins, gynbins; // Number of global bins in each direction.
    int xbinsize, ybinsize;   // Size of each global bin in nanons.
    int totaltiles;	// For debugging.
    int totalcells;	// For debugging.
};

static struct spCongDataStruct spbins;


static void spCongDoPaint(Tile *tile,SPSearchContext *spx)
{
    Rect tr, r;
    int xbeg, xend, ybeg, yend;
    int i,j;
    TileType ttype = DBgetTileType(tile);
    int bitno;
    int bitmask;


    spbins.totaltiles++;

    TiToRect(tile,&tr);
    if (spx) {
	GeoTransRect(&spx->spx_trans,&tr,&r);
    } else {
	r = tr;
    }
    GeoClip(&r,&spbins.area);
    if (GEO_RECTNULL(&r)) {
	// Dont think this is possible, because the
	// search would not have returned the tile
	// unless it had some overlap.
	return;
    }

    if (TTMaskHasType(&spbins.h.mask,ttype)) {

	// Horizontal congestion:
	bitno = spbins.h.layerBitIndex[ttype];
	ASSERT(bitno > 0 && bitno <= spbins.h.layercnt,"congestion layerBitIndex logic error");
	bitmask = (1<<(bitno-1));

	// Figure out beginning and ending bins that are obstructed.
	xbeg = (r.r_xbot - spbins.area.r_xbot + 1) / spbins.h.xsize;
	xend = (r.r_xtop - spbins.area.r_xbot - 1) / spbins.h.xsize;
	ybeg = (r.r_ybot - spbins.area.r_ybot + 1) / spbins.h.ysize;
	yend = (r.r_ytop - spbins.area.r_ybot - 1) / spbins.h.ysize;

	for (i = xbeg; i <= xend; i++) {
	    for (j = ybeg; j <= yend; j++) {
		// obstruct this slot in the bit representing this layer.
		SPCONGBINELEMENT(spbins.h,i,j) |= bitmask;
	    }
	}
    }

    if (TTMaskHasType(&spbins.v.mask,ttype)) {
	// Vertical congestion:
	bitno = spbins.v.layerBitIndex[ttype];
	ASSERT(bitno > 0 && bitno <= spbins.v.layercnt,"congestion layerBitIndex logic error");
	bitmask = (1<<(bitno-1));

	xbeg = (r.r_xbot - spbins.area.r_xbot + 1) / spbins.v.xsize;
	xend = (r.r_xtop - spbins.area.r_xbot - 1) / spbins.v.xsize;
	ybeg = (r.r_ybot - spbins.area.r_ybot + 1) / spbins.v.ysize;
	yend = (r.r_ytop - spbins.area.r_ybot - 1) / spbins.v.ysize;

	for (i = xbeg; i <= xend; i++) {
	    for (j = ybeg; j <= yend; j++) {
		SPCONGBINELEMENT(spbins.v,i,j) |= bitmask;
	    }
	}
    }
}


static void spCongSubSearch(SPSearchContext *spx,TileTypeBitMask *pmask)
{
    while ((spx = SPInstEnumNext(spx))) {
	SPSearchEnum spe; Tile *tile;
	SPSearchContext *spxchild;

	spbins.totalcells++;

	SPsxPlanesEnumInit(&spe,spx,pmask);
	while (tile = SPPlanesEnumNext(&spe)) {
	    spCongDoPaint(tile,spx);
	}
	SPPlanesEnumTerm(&spe);

	spxchild = SPsxInstEnumInit(spx,"spss");
	spCongSubSearch(spxchild,pmask);
    }
    SPInstEnumTerm(spx);
}


// Return 1 on error, 0 on success
static int spCongInitLayers(char *cmdName, char *layers, spCongDBin *dbin,char *obs_suffix)
{
    int n, tt;
    int nlayers = 0;
    char buf[1000];
    char *layername;
    TileTypeBitMask mask;

    if (!CmdParseLayers(layers,&mask)) {
	return 1;	// CmdParseLayers printed a message.
    }

    TTMaskZero(&dbin->mask);

    // init layerBitIndex.
    for (n = 0; n < TT_MAXTYPES; n++) {
	if (TTMaskHasType(&mask,n)) {

	    if (nlayers == 8) {
		MsgErrorF("%s: maximum of 8 layers allowed\n",cmdName);
		return 1;
	    }

	    TTMaskSetType(&dbin->mask,n);
	    dbin->layerBitIndex[n] = (nlayers+1);

	    // Look for an additional obstruction layer for this layer.
	    if (obs_suffix) {
		layername = DBTypeLongName(n);
		ASSERT(layername,"no layername found for a tile type!");

		strcpy(buf,layername);
		strcat(buf,obs_suffix);
		if ((tt = DBTechNameType(buf)) >= 0) {
		    // There is an obstruction layer that matches layername.
		    // It obstructs the same layer.
		    dbin->layerBitIndex[tt] = (nlayers+1);
		    TTMaskSetType(&dbin->mask,tt);
		}
	    }
	    nlayers++;
	}
    }
    dbin->layercnt = nlayers;
    if (dbin->layercnt > 8) {
    	MsgErrorF("%s: number of layers must be <= 8\n",cmdName);
    	return 1;
    }
    return 0;
}



// xbinsize,ybinsize in max units.
// Return 0 on success, 1 on failure, in which case error message was already printed.
// If any_cell, search all descendents.
// If f_add, add congestion in this cell to previous congestion,
// assuming that all other arguments (area, layers, binsizes) are the same;
// a crash may result if this is not true.
int spCongSearch(char *cmdName,CellDef *cdef,Rect *parea,char *hlayers,char *vlayers,
	int xbinsize,int ybinsize,int xslotsperbin,int yslotsperbin,
	char *obs_suffix,int any_cell,int f_add)
{
    TileTypeBitMask fullmask;

    if (f_add) {
	if (spbins.h.bins == NULL) {
	    MsgErrorF("spCongSearch: called with add==1 but no previous search!\n");
	    return 1;
	}
	if (parea == NULL || memcmp(&spbins.area,parea,sizeof(Rect))  ) {
	    MsgErrorF("spCongSearch: called with add==1 but area differs from previous search!\n");
	}
    } else {

	// Init the bin structure.
	memset(&spbins,0,sizeof(spbins));

	if (spCongInitLayers(cmdName, hlayers, &spbins.h,obs_suffix)) return 1;
	if (spCongInitLayers(cmdName, vlayers, &spbins.v,obs_suffix)) return 1;

	if (spbins.h.layercnt+spbins.v.layercnt == 0) {
	    MsgErrorF("%s: no legal layers specified\n",cmdName);
	    return 1;
	}

	if (parea) {
	    spbins.area = *parea;
	} else {
	    // Search the entire cell.
	    spbins.area = *DBBBoxCellDef(cdef);
	}


	// Disaster will ensue if there is round-off error, ie,
	// xsize not evenly divisible by 

	// This is the number of global bins.
	spbins.gxnbins = (spbins.area.r_xtop - spbins.area.r_xbot + xbinsize-1) / xbinsize;
	spbins.gynbins = (spbins.area.r_ytop - spbins.area.r_ybot + ybinsize-1) / ybinsize;

	// horizontal congestion slots; each global grid has slots: 1 x yslotsperbin.
	spbins.h.slotsperbin = yslotsperbin;
	spbins.h.xsize = xbinsize;
	spbins.h.ysize = ybinsize/yslotsperbin;
	spbins.h.xnslots = spbins.gxnbins;
	spbins.h.ynslots = spbins.gynbins * spbins.h.slotsperbin;
	CALLOC(char*, spbins.h.bins, (spbins.h.xnslots*spbins.h.ynslots));

	// vertical slots; each global grid has slots: xslotsperbin x 1.
	spbins.v.slotsperbin = xslotsperbin;
	spbins.v.xsize = xbinsize/xslotsperbin;
	spbins.v.ysize = ybinsize;
	spbins.v.xnslots = spbins.gxnbins * spbins.v.slotsperbin;
	spbins.v.ynslots = spbins.gynbins;
	CALLOC(char*, spbins.v.bins, (spbins.v.xnslots*spbins.v.ynslots));
    }

    // OR the vertical and horizontal layer masks together.
    fullmask = spbins.h.mask;
    TTMaskSetMask(&fullmask,&spbins.v.mask);

    {	// Search current cell first.
	SPSearchEnum spe; Tile *tile;

	SPPlanesEnumInit(&spe,cdef,NULL,&spbins.area,&fullmask,0,"spSearchPaint");
	while ((tile = SPPlanesEnumNext(&spe))) {
	    spCongDoPaint(tile,NULL);
	}
	SPPlanesEnumTerm(&spe);
	spbins.totalcells++;
    }

    if (any_cell) {
	SPSearchContext *spx;
	spx = SPInstEnumInit(cdef,&spbins.area,NULL,NULL,0,"spSearchPaint");
	spCongSubSearch(spx,&fullmask);
    }

    return 0;	// success
}


// Return horizontal and vertical congestion for specified global bin.
// If xbin or ybin are out of bounds, returns 0,0 congestion.
void spCongGet(int xbin, int ybin, int *phcongestion, int *pvcongestion)
{
    int vcongestion = 0;	// Congestion in the global bin at: xbin,ybin
    int hcongestion = 0;
    int xslot,yslot,i;

    // Compute horizontal congestion in this bin.
    // Look at the yslotsperbin horizontally aligned slots in this bin.
    if (xbin < spbins.h.xnslots) {
	xslot = xbin;
	yslot = ybin * spbins.v.slotsperbin;
	for (i = 0; i < spbins.v.slotsperbin && yslot<spbins.h.ynslots; i++,yslot++) {
	    int slotval = SPCONGBINELEMENT(spbins.h,xslot,yslot);
	    int l;
	    // Add 1 for each layer obstructed in this slot.
	    for (l = spbins.h.layercnt; l > 0; l--) {
		hcongestion += slotval&1;
		slotval = slotval>>1;
	    }
	}
    }

    // Compute vertical congestion in this bin.
    // Look at the xslotsperbin vertically aligned slots in this bin.
    if (ybin < spbins.v.ynslots) {
	xslot = xbin * spbins.h.slotsperbin;
	yslot = ybin;
	for (i = 0; i < spbins.h.slotsperbin && xslot<spbins.v.xnslots; i++,xslot++) {
	    int slotval = SPCONGBINELEMENT(spbins.v,xslot,yslot);
	    int l;
	    // Add 1 for each layer obstructed in this slot.
	    for (l = spbins.v.layercnt; l > 0; l--) {
		vcongestion += slotval&1;
		slotval = slotval>>1;
	    }
	}
    }
    *phcongestion = hcongestion;
    *pvcongestion = vcongestion;
}


void spCongTerm()
{
    if (spbins.h.bins) {
	FREE(spbins.h.bins);
	spbins.h.bins = NULL;
	FREE(spbins.v.bins);
	spbins.v.bins = NULL;
    }
}


// TODO: Change -any_cell to -hier [visible all none stop]
TCL_DOC(spCongBin,sp_cong_bin,"Return the congestion bins for cells",
 "Syntax:  sp_cong_bin [-options] horizontal_layers vertical_layers

  -any_cell                     Look in all subcells, else only specified cell;
  -cell <cell>                  Start in specified cell instead of current cell;
  -area <x1> <y1> <x2> <y2>     Look only in specified area;
	Note that an area should be specified to insure that the bins
	are properly aligned with the actual wire tracks.
  -binsize <sizex> <sizey>      Size of bins in microns;
  -slots <tracksx> <tracksy>    Number of tracks in horizontal and vertical directions.
  -obs_suffix <suffix>

  Return value is a list of lists of pairs of numbers,
  where the outer list is the y direction,
  the inner list is the x direction,
  and the pair of numbers are the number of obstructions
  in the horizontal and vertical directions.

  Example:
  If wire track width is 0.5 micron, a typical use for bins of 10x10 tracks would be:

  sp_cong_bin -binsize 5 5 -slots 10 10 m2,m4 m3,m5

  In the above case, each bin will contain a number from 0 to 20, where 0 is uncongested
  and 20 means every slot is covered.

  if -obs_suffix, then obstruction layers with this suffix are included
  automatically.  The suffix must be specified, but is usually _obs.
  Specifically, for each layer specified, if there exists another
  layer whose name is the same as that layer with the obstruction suffix appended,
  then the obstruction layer is assumed to obstruct the same layer as
  the original layer.

  Note: in each direction, binsize/slotsize should be an integral number of max database units.
  ");
TCL_COMMAND(spCongBin)
{ CMD_BEGIN(interp);
{
    CellDef *cdef;
    static struct {
	int any_cell;
	char *cellstring;
	int f_area;
	int f_binsize;
	int xbinsize, ybinsize;	// In max units.
	int f_slots;
	int xslotsperbin, yslotsperbin;
	Rect area;
	char *obs_suffix;
	int debug;
	} o;

    static void* options[] = {
	"0",	"-any_cell",	&o.any_cell,
	"1s",	"-cell",	0,		&o.cellstring,
	"4u",	"-area",	&o.f_area,	&o.area.r_xbot,&o.area.r_ybot,&o.area.r_xtop,&o.area.r_ytop,
	"2d",	"-slots",	&o.f_slots,	&o.xslotsperbin,&o.yslotsperbin,
	"2u",	"-binsize",	&o.f_binsize,	&o.xbinsize,&o.ybinsize,
	"1s",	"-obs_suffix",	0,	&o.obs_suffix,
	"0",	"-debug",	&o.debug,
	0 };

    char *cmdName = (argc--,*argv++);

    Tcl_Obj *result_list;
    char *hlayers, *vlayers;

    memset(&o,0,sizeof(o));	// init all options to 0.
    //SPInitOptions(options);	// init all options to 0.
    if (SPParseOptions(cmdName,&argc,&argv,options,0)) {CMD_RETURN(interp);}

    if (o.f_slots == 0) {
	MsgErrorF("%s: -slots not specified\n",cmdName);
	CMD_RETURN(interp);
    }
    if (o.f_binsize == 0) {
	MsgErrorF("%s: -binsize not specified\n",cmdName);
	CMD_RETURN(interp);
    }

    // Expecting two more arguments for horizontal and vertical layer lists.
    if (argc < 2) {
	MsgErrorF("%s: no layers specified\n",cmdName);
	CMD_RETURN(interp);
    }
    hlayers = *argv;
    argc--; argv++;
    vlayers = *argv;
    argc--; argv++;

    if (argc != 0) {
	MsgErrorF("%s: too many arguments\n",cmdName);
	CMD_RETURN(interp);
    }

    if (o.cellstring) {
	// Almost all the tcl commands that take a -cell option just look for a
	// previously loaded cell, so we will do the same.
	cdef = DBCellLookDef(o.cellstring);
	if (cdef == NULL) {
	    MsgErrorF("%s: Cell %s not found\n",cmdName,o.cellstring);
	    CMD_RETURN(interp);
	}
    } else {
	cdef = EditCellUse->cu_def;
    }

    if (spCongSearch(cmdName,cdef,o.f_area ? &o.area : NULL,hlayers,vlayers,
	o.xbinsize,o.ybinsize,o.xslotsperbin,o.yslotsperbin,o.obs_suffix,o.any_cell,0)) {
	CMD_RETURN(interp);
    }


    // Read the results back out into a tcl list.
    result_list = Tcl_NewListObj(0,0);

    // Aggregate slots into bins and place in return value.
    if (o.debug) {
	// Return the slots themselves.
#if 0 // BROKEN
	int i,j;
	for (j = 0; j < spbins.ynslots; j++) {
	    Tcl_Obj *sub_list = Tcl_NewListObj(0,0);
	    for (i = 0; i < spbins.xnslots; i++) {
		int val = spbins.bins[i + j*spbins.xnslots];
		Tcl_ListObjAppendElement(interp,sub_list,Tcl_NewIntObj(val));
	    }
	    Tcl_ListObjAppendElement(interp,result_list,sub_list);
	}
#endif
    } else {
	int totalbins = 0;
	int totalcongestion = 0;
	int xbin, ybin;
	for (ybin = 0; ybin < spbins.gynbins; ybin++) {
	    Tcl_Obj *sub_list = Tcl_NewListObj(0,0);
	    for (xbin = 0; xbin < spbins.gxnbins; xbin++) {
		int vcongestion = 0;	// Congestion in the global bin at: xbin,ybin
		int hcongestion = 0;

		spCongGet(xbin,ybin,&hcongestion,&vcongestion);

		// Put horizontal/vertical congestion from this bin into list.
		{ Tcl_Obj *pair_list = Tcl_NewListObj(0,0);
		  Tcl_ListObjAppendElement(interp,pair_list,Tcl_NewIntObj(hcongestion));
		  Tcl_ListObjAppendElement(interp,pair_list,Tcl_NewIntObj(vcongestion));

		  Tcl_ListObjAppendElement(interp,sub_list,pair_list);
		}

		// keep some accounting totals.
		totalbins++;
		totalcongestion += hcongestion + vcongestion;
	    }
	    Tcl_ListObjAppendElement(interp,result_list,sub_list);
	}

	MsgInfoF("totaltiles=%d totalcells=%d totalbins=%d totalcongestion=%d nlayers=%d+%d\n",
	    spbins.totaltiles, spbins.totalcells,totalbins,totalcongestion,
	    spbins.h.layercnt,spbins.v.layercnt);
    }

    spCongTerm();

    Tcl_SetObjResult(interp,result_list);

    CMD_RETURN(interp);
}}

void spcong_init(Tcl_Interp *interp)
{
    spCongBin_init(interp);
}
