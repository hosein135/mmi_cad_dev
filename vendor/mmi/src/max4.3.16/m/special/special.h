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



#ifndef _SPECIAL
#define _SPECIAL

#ifndef _TCL
#include <tcl.h>
#endif

/*
 * special.h --
 *
 * This file defines the interface between the special
 * module and the rest of max.
 *
 * The special module is intended to hold special purpose routines
 * written as needed to support specific tcl procs, but not intended 
 * to be of general use.
 *                      
 */     

/* module initialization (called once at Max startup) */
extern void SpcTclInit(Tcl_Interp *interp);


// Do a forward decl of the command, and create a command called c_cmd_init
// that actually creates the command in tcl.  To use this,
// put a call to c_cmd_init in the module initialization procedure.
#define TCL_DOC(c_cmd,tcl_cmd,desc,doc) \
    static int c_cmd(ClientData clientData, Tcl_Interp *interp, int argc, char **argv); \
    static void c_cmd##_init (Tcl_Interp *interp) { \
	MnDocCreateCommand(interp, #tcl_cmd, c_cmd, \
	    (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,desc,doc); \
    }


// Start a Tcl comand.
#define TCL_OBJCOMMAND(c_cmd) \
    static int c_cmd(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj **objv)

#define TCL_COMMAND(c_cmd) \
    static int c_cmd(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)


#define TCL_OPT_WARN 1 		/* Error out on unrecognized options */
#define TCL_OPT_NOARGS 2	/* Command has 0 args. */
#define TCL_OPT_NODASHDASH 4	/* Ignore -- argument. */




typedef struct SPPlanesEnum_s SPPlanesEnum;
typedef struct SPSearchContext_s SPSearchContext;
typedef struct SPSearchEnum_s SPSearchEnum;
typedef SPSearchEnum SPTileEnum;
typedef SPSearchEnum SPPolyEnum;
typedef SPSearchEnum SPWirePathEnum;

#define SP_RECURSIVE 1


// Common structure for tile, polygon, and wirepath searches.
struct SPSearchEnum_s {
    Rect spe_area;
    TileTypeBitMask spe_mask;
    int spe_flags;
    CellDef *spe_def;	// Used for PlanesEnum.
    Polygon *spe_poly;	// Only used for polygon searches.
    WirePath *spe_wp;	// Only used for wirepath searches.
    Tile *spe_tile;	// Only used for tile searches.
    Plane *spe_plane;	// Only used for tile searches: plane for hint tile.
    int spe_firsttime;	// Only used for tile searches.
    PlaneList *spe_planelist;	// Used for PlanesEnum: allocated planelist
    PlaneList *spe_pll;		// Used for PlanesEnum: current search plane.
};



#if 0
// Used to search for tiles on a single plane.
typedef struct SPTileEnum_s *SPTileEnum;
struct SPTileEnum_s {
    Rect *spt_area;
    TileTypeBitMask *spt_mask;
    Tile *spt_tp;
    Plane *spt_plane;
    int spt_firsttime;
};
#endif



// Hierarchical search context.  An extension of SearchContext.
// A new search creates a root search context with spx_def, spx_area and spx_trans filled in.
// Calls to enumerate cells return new DFSearchContext with spx_parent pointing
// to hierarchical parent cell.
// The instance path (aka tpath) can be retrieved using SPsxInstPath.
struct SPSearchContext_s {
    // First part of structure identical to SearchContext
    CellUse     *spx_use;       // Pointer to current cell use.
    int          spx_x, spx_y; // X and Y array elementS if scx_use is array
    Rect         spx_area;      // Area searched in scx_use->cu_def coords
    Transform    spx_trans;     // Composite transform from coordinates
                                 // of the cell use (scx_use) all the way
                                 // back to those of the "root" of the search.
    ClientData spx_client;	// Whatever the client wants.
    SPSearchContext *spx_parent;// Pointer to next higher cell in hierarchical search.
				// When on free list, this is the next pointer.
    CellDef *spx_rootdef;	// Only valid in root: def we are searching.

    // The following are private to the search functions; clients should not access!
    // Note: It seems like the parent_trans and parent_area should not be needed because
    // you can look at spx_parent->spx_trans and spx_parent->spx_area.
    // The problem occurs at the top-most SPSearchContext.  If the user specified
    // an area or initial transform, you need to store those somewhere.  You dont
    // really want to make an extra dummy SPSearchContext for the top-most level,
    // because you also want to be able to derive sub-searches from an existing search,
    // and inserting an extra dummy level there would make following the
    // spx_parent chain upwards quite confusing.
    Transform spx_parent_trans;	// Parent transform.
    Rect spx_parent_area;	// Parent area.
    Transform spx_atrans;	// A place to put the array transform.
				// For non_arrays, same as spx_use->cu_transform.
    BPEnum spx_bpe;			// Or BPEnum, depending on spx_allcells.
    union {
      struct {
        short spx_flags:16;
        unsigned int spx_inarray:1;	// True if currently doing an array.
        unsigned int spx_descend:1;	// True if we need to descend into the last use seen.
        unsigned int spx_anchor:1;	// This is the top of its individual searchcontext tree,
	unsigned int spx_allcells:1;	// If TRUE, do all cells, otherwise cells in spx_area.
	} f;
      int spx_all_flags;			// Used to set all flags to 0 at once.
    } u;
				// even if it has an spx_parent.  If anchor == 2,
				// blow away spx_parent as well.
    ArrayInfo	spx_ar;		// Cannonicalized array info.
};



CellDef *SPsxRoot(SPSearchContext *spx);
char * SPsxInstPath(SPSearchContext *spx, char *buf, int buflen);
Transform *SPsxGetTrans(SPSearchContext *spx);

Tile *SPTileNext(register Tile *tp, register Rect *rect, TileTypeBitMask *mask);
Tile *SPTileFirst(register Tile *tp, Rect *rect, TileTypeBitMask *mask);
void SPTileEnumInit(SPTileEnum *tpe, Tile *hintTile, Plane *plane, Rect *rect, TileTypeBitMask *mask, char *id);
Tile *SPTileEnumNext(SPTileEnum *tpe);
void SPTileEnumTerm(SPTileEnum *unused);

void SPPlanesEnumInit(SPSearchEnum *ppe, CellDef *def, PlaneList *planes, 
	Rect *rect, TileTypeBitMask *mask, int flags, char *unused_id);
Tile *SPPlanesEnumNext(SPSearchEnum *ppe);
void SPPlanesEnumTerm(SPSearchEnum *ppe);

SPSearchContext *SPInstEnumInit(CellDef *def, Rect *area, Transform *trans,
	SPSearchContext *spxpar,int flags, char *id);
SPSearchContext *SPsxInstEnumInit(SPSearchContext *spx,char *id);
SPSearchContext *SPInstEnumNext(SPSearchContext *spx);
void SPInstEnumTerm(SPSearchContext *spx);


/*  spTcl.c  */
void SPInitOptions(void **options);
int SPParseOptions(char *cmdName,int *pargc, char ***argv,void **options, int flags);
int SPParseObjOptions(Tcl_Interp *interp,char *cmdName,int *pargc, Tcl_Obj ***objv,void **options, int flags);
char *SPTListGetStr(Tcl_Interp *interp, Tcl_Obj *list,int n);




CellDef *SPCellLoad(char *cellname);



int spCongSearch(char *cmdName,CellDef *cdef,Rect *parea,char *hlayers,char *vlayers,
	int xbinsize,int ybinsize,int xslotsperbin,int yslotsperbin,
	char *obs_suffix,int any_cell,int f_add);
void spCongGet(int xbin, int ybin, int *phcongestion, int *pvcongestion);
void spCongTerm();

#endif _SPECIAL

