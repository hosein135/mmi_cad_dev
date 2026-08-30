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
#include <setjmp.h>
#include "main.h"		// For EditCellUse
#include "utils.h"
#include "layout.h"		// For LayCurWindow
#include "signals.h"		// For SigInterruptPending
#include "cif.h"		// For CIFDBRes

#include "def2max.h"

#include "dlgdef.h"
#include "antlr.h"  /* Needed for def of ANTLR */

static double defUnits;
static int defDivChar;
static int defDoMerge;
static int defDoNets;
static int defDoComponents;
static int defBusBitBeg, defBusBitEnd;
static int defCaseSensitive;		// not used.
static jmp_buf defAbortJmpBuf;


static char *strtolower(char *str) {
    register char *cp;
    for (cp=str;*cp;cp++) { *cp = tolower(*cp); }
    return str;
}
static char *strtoupper(char *str) {
    register char *cp;
    for (cp=str;*cp;cp++) { *cp = toupper(*cp); }
    return str;
}

void def2max_failed_pred(char *p) {
	fprintf(stderr,"semantic error line %d at: %s\n",zzline,p);
}


#if ZZCR_MALLOC
// The big lex buffers are kept in a free list that looks like this:
struct def_zz_s {
    struct def_zz_s *next;
} *def_zz_head = NULL;


/* This code is from the PCCTS charptr.h file. */
/*UNUSED*/void def_zzcr_attr(Attrib *a,int token,char *text)
{
#if 0
	a->text = malloc(D_TextSize+1);
#else
	// Avoid malloc.  Allocate max size buffers ourselves.
	if (def_zz_head == NULL) {
	    a->text  = (char*)malloc(D_TextSize+1);
	    if (a->text==0) {MaxAbort("out of mem");}
	} else {
	    a->text = (char*) def_zz_head;
	    def_zz_head = def_zz_head->next;
	}
#endif
	//*a = (char *) malloc(strlen(text)+1);			/* MR6 */
	//if ( *a == NULL ) {fprintf(stderr, "zzcr_attr: out of memory!\n"); exit(-1);}

    // This code is: strcpy(a->text,text)  with overflow detection.
    {
    register char *s1 = a->text, *s2 = text;
    char *e = &a->text[D_TextSize-1];
    while (s1 < e) { if (!(*s1++ = *s2++)) return; }
    // This probably should not happen, because lex input buffer is the same size,
    // and error should get reported then.
    MsgErrorF("Token too long, truncated, at line %d\n",zzline);
    *s1 = 0;
    }
}

// Note: antler calls this on null attribs that have not been allocated by zzcr_attr!
/*UNUSED*/void def_zzd_attr(Attrib *a)
{
#if 0
    if (a->text) {
	free(a->text);	// free(0) is ok, but we will avoid it anyway!
	a->text = 0;
    }
#else
    if (a->text) {
	struct def_zz_s *tmp = (struct def_zz_s*)(a->text);
	tmp->next = def_zz_head;
	def_zz_head = tmp;
	a->text = NULL;	// paranoid
    }
#endif
}

/*UNUSED*/void def_zz_cleanup()
{
    while (def_zz_head) {
	struct def_zz_s *tmp = def_zz_head;
	def_zz_head = def_zz_head->next;
	free(tmp);
    }
}
#endif

int defUnits2Max(int defx)
{
    double val = ((double)defx / defUnits) / CIFDBRes;
    return ROUND(val);
}

// The x,y are in DEF units.
static void def2maxtrans(char *inst_name,CellDef *def,int x, int y, pnl_orientation ori, Transform *ptrans)
{
    Rect *box = DBBBoxCellDef(def);
    int xsize = box->r_xtop - box->r_xbot;
    int ysize = box->r_ytop - box->r_ybot;
    int cx, cy;
    Transform *ctr;

    x = defUnits2Max(x);
    y = defUnits2Max(y);

    switch (ori) {
	case pnl_orientation_N:
	  ctr = &GeoIdentityTransform; // don't flip
	  cx = x;
	  cy = y;
	  break;
	case pnl_orientation_FN:
	  ctr = &GeoSidewaysTransform; // flip fx
	  cx = x + xsize;
	  cy = y;
	  break;
	case pnl_orientation_FS:
	  ctr = &GeoUpsideDownTransform; // flip fy
	  cx = x;
	  cy = y + ysize;
	  break;
	case pnl_orientation_S:
	  ctr = &Geo180Transform;  // r180
	  cx = x + xsize;
	  cy = y + ysize;
	  break;
	case pnl_orientation_E:
	  ctr = &Geo90Transform; // r90
	  cx = x;
	  cy = y + xsize;
	  break;
	case pnl_orientation_FE:
	  ctr = &GeoRef135Transform; // fy_r90
	  cx = x + ysize;
	  cy = y + xsize;
	  break;
	case pnl_orientation_FW:
	  ctr = &GeoRef45Transform; // fx_r90
	  cx = x;
	  cy = y;
	  break;
	case pnl_orientation_W:
	  ctr = &Geo270Transform; // r270
	  cx = x + ysize;
	  cy = y;
	  break;
	default:
	  MsgErrorF("Unrecognized orientation on cell %s\n",inst_name);
	  longjmp(defAbortJmpBuf,1);
	  break;
    }
    GeoTranslateTrans(ctr,cx,cy,ptrans);
}


// The inst_name and mod_name have been malloced.
void def2max_component (char *inst_name, char *mod_name, pnl_loctype loctype, 
    int defx, int defy, pnl_orientation defori)
{
    CellDef *def = EditCellUse->cu_def;	// Read into current cell.
    char *subDefName;
    CellDef *subCellDef;
    CellUse *subCellUse;
    Transform trans;

    if (SigInterruptPending) { longjmp(defAbortJmpBuf,1); }
    if (!defDoComponents) {return;}

    //TODO: Must translate mod_name from verilog to max chars.
    subDefName = mod_name;

    subCellDef = DBCellLookDef(subDefName);
    if (!subCellDef) {
      // Try to auto-load it.
      MsgInfoF("def_read auto-loading cell %s\n",subDefName);
      subCellDef = DBCellNewDef(subDefName,NULL);
      if (!DBReadCell(subCellDef)) {
	  // This is really bad.
	  // TODO: should we create a cell?  Maybe only if defori is N?
	  DBCellSetAvail(subCellDef);
	  MsgErrorF("Cell %s not found, creating empty cell\n",subDefName);
	  longjmp(defAbortJmpBuf,1);
      }
    }

    subCellUse = DBCellUseNew(subCellDef,inst_name);

    // Convert the DEF orientation into a max Transform.
    def2maxtrans(inst_name,subCellDef,defx,defy,defori,&trans);
    DBCellUseSetTrans(subCellUse,&trans);

    // create instance.
    if (!DBInstanceAdd(subCellUse,def,DBIA_DUP_OK)) {
	MsgErrorF("Can not add instance %s\n",inst_name);
    }

    ret:
    free(inst_name);
    free(mod_name);
}

// Ignore history.
void def2max_history (char *str) {}


void def2max_port(defparse_place *pport)
{
    Rect r;
    TileType ttype;
    int kind;
    r.r_xbot = r.r_xtop = pport->x;
    r.r_ybot = r.r_ytop = pport->y;
    if (pport->layer[0]) {
	ttype = DBTechNameType(pport->layer);
	if (ttype < 0 && strlen(pport->layer) < 200-1) {
	    char cbuf[200];
	    // Try lower case.
	    ttype = DBTechNameType(strtolower(strcpy(cbuf,pport->layer)));
	}
	if (ttype < 0) {
	    MsgWarnF("Invalid layer %s on port %s\n",pport->layer,pport->name);
	    ttype = TT_SPACE;
	}
    } else {
	ttype = TT_SPACE;
    }
    // TODO: Should we check if label is already there?  Then what?
    DBLabelAdd(EditCellUse->cu_def,&r,-1,pport->name,ttype,pport->iotype);
}


// Create the cell 
void def2max_design(char *str)
{
    CellDef *def;
    if (!defDoMerge) {
	// See if cell already loaded.
	if ((def = DBCellLookDef(str))) {
	    if (!DBAccessModify(def)) {
		MsgErrorF("Can not read def into read-only cell: %s\n",def->cd_name);
		longjmp(defAbortJmpBuf,1);
	    }
	    // clear existing cell
	    MsgInfoF("Clearing old contents of cell %s\n",str);
	    DBCellClearContents(def);
	    // Must also clear select cell, in case something was selected from def.
	    SelectClear();
	} else {
	    // create new cell
	    def = DBCellNewDef(str,NULL);
	    DBCellSetAvail(def);
	}

	// Load cell into window.
	LayloadWindow(LayCurWindow(),str);
    }
}

// Lay PRB over die area.
void def2max_die_area(int x1, int y1, int x2, int y2)
{
    TileType paintType = DBTechNameType("PRB");
    if (paintType < 0) {
        paintType = DBTechNameType("prb");
    }

    if (paintType < 0) {
	MsgWarnF("Could not find PRB layer, die area ignored\n");
    } else {
	CellDef *def = EditCellUse->cu_def;	  // current cell.
	Rect r;
	r.r_xbot = defUnits2Max(x1); r.r_ybot = defUnits2Max(y1);
	r.r_xtop = defUnits2Max(x2); r.r_ytop = defUnits2Max(y2);
	DBPaint(def,&r,paintType);
    }
}

void def2max_divider_char(char *str)
{
    if (strlen(str) == 1) {
	defDivChar = str[0];
    } else if (strlen(str) == 3) {
	// it was a quoted string: "/"
	defDivChar = str[1];
    } else {
	MsgWarnF("DIVIDERCHAR must be a single char, was: %s\n",str);
    }
}

void def2max_busbit_char(char *str)
{
    if (strlen(str) == 2) {
	defBusBitBeg = str[0];
	defBusBitEnd = str[1];
    } else if (strlen(str) == 4) {
	// it was a quoted string
	defBusBitBeg = str[1];
	defBusBitEnd = str[2];
    } else {
	MsgWarnF("BUSBITCHARS must two chars, was: %s\n",str);
    }
}


pnl_net def2max_net (char *name, int special)
{
    if (SigInterruptPending) { longjmp(defAbortJmpBuf,1); }
    if (!defDoNets) {return 0;}

    // TODO

    return 0;
}

void def2max_case_sensitive(int val)
{
    defCaseSensitive = val;
}

void def2max_distance_units (char *name, int num)
{
    if (strcasecmp(name,"MICRONS") == 0) {
      defUnits = (double) num;
    } else {
      MsgWarnF("Unrecognized unit ignored in UNITS DISTANCE statement: %s\n",name);
    }
}

// This is the entry point for the parser.
// ipf is the open file descriptor.
// If merge, read contents of this cell into the current cell; otherwise create new cell.
void def_file(void);
int def_read(FILE *ipf,int do_nets,int do_components,int do_merge)
{
    int ret = 0;

    defUnits = 1000.0;		// The default.
    defDivChar = '/';		// The default.
    defCaseSensitive = 0;	// The default.
    defBusBitBeg = '(';
    defBusBitEnd = ')';

    defDoMerge = do_merge;
    defDoNets = do_nets;
    defDoComponents = do_components;

    UndoDisable();

    if (do_merge) {
	// check current cell for read-only
	CellDef *def = EditCellUse->cu_def;
        if (!DBAccessModify(def)) {
	    // DBAccessModify probably already printed a msg, but be sure.
	    MsgErrorF("Can not read def into read-only cell: %s\n",def->cd_name);
	    return 1;
	}
    }

    if ((ret = setjmp(defAbortJmpBuf)) == 0) {

	ANTLR(def_file(),ipf);

	if (zzSyntaxErrCount) { ret = 1; }
    } else {
        MsgErrorF("def_read aborted\n");
    }

    // Note that if !do_merge, the top level cell might have changed.
    // Mark entire current cell as changed.
    DBChangedArea(EditCellUse->cu_def,NULL,NULL,0);

#if ZZCR_MALLOC
    def_zz_cleanup();
#endif
    UndoEnable();
    return ret;
}
