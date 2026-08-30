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
 * spcTcl.c -- Tcl command interface to this module
 */

#include <tcl.h>
#include <stdlib.h>
#include "magic.h"
#include "main.h"
#include "utils.h"
#include "units.h"
#include "message.h"
#include "database.h"
#include "special.h"
#include "specialInt.h"


// Parse tcl options.
// The interp argument is used only if tcl by SPParseObjOptions when processing lists.
// The cmdName is optional, will appear in any error messages.
// The pargc and pargv are pointers to argc,argv, and are advanced past options
// recognized in the command line.
//
// Options are described by a list of void*, in which each option to parse
// is specified by three or more of the void* pointers.
// Each option looks like this:
//	flags  option_name  bool_pointer [ value_pointer ...]
// The flags is a string whose first char is a digit giving the number of arguments
// to the option (and the number of void*value_pointers that must be supplied in the
// options array), and whose second char describes the types of arguments.
// Valid flags are:
//	s - string, requires (char*) pointer.
//	u - integer converted to max db_units, requires (int*) pointer.
//	d - integer, requires (int*) pointer.
//	f - float, requires (double*) pointer.
//	o - tcl object, requires (Tcl_Obj*) pointer.  (SPParseObjOptions only)
//	l - tcl list,   requires (Tcl_Obj*) pointer.  (SPParseObjOptions only)
// The option_name is a string like "-verbose".
// The bool_pointer is a pointer to an int that is set to 1 if the option is discovered.
// The optional value_pointer(s) is a pointer to a variable of the correct type to receive
// the value(s) of the option.
// This entire option list is terminated by an option with flags == 0.
// Example:
//   static struct {
//	int any_cell;
//   	Rect area;
//   	int rect_flag;
//   	char *cellstring;
//	} o;
//   static void *options = {
//	"0",	"-any_cell",	&o.any_cell,	               // binary option
//	"1s",	"-cell",	0,		&o.cellstring,   // the bool_pointer is not needed here.
//	"4u",	"-area",	&o.rect_flag,	&o.area.r_xbot,&o.area.r_ybot,&o.area.r_xtop,&o.area.r_ytop,
//      0 };  					               // Terminates the list.
//	char *cmdName = (argc--,*argv++);
//
//      Note: The pointer values MUST be initialized before calling ParseOptions,
//	since they are static.  Use memset to init all to 0.
//      memset(&o,0,sizeof(o));
//	if (SPParseOptions(interp,&argc,&argv,options,0)) {CMD_RETURN(interp);}
//
int SPParseOptions(char *cmdName,int *pargc, char ***pargv,void **options, int flags)
{
    int argc = *pargc;
    char **argv = *pargv;
    char **opa;  /* Pointer into user supplied options array */
    int ncnt;

    while (argc>0 && argv[0][0] =='-') {
	char *cp = *argv;
	if (cp[1] == '-' && cp[2] == 0 && !(flags & TCL_OPT_NODASHDASH)) {
	    // Found '--"
	    argc--; argv++;
	    break;
	}

	// Cruise the options, see if this option matches any.
	for (opa = (char**)options; *opa; opa += 3+ncnt) {
	    // check char 1, which is the first char of the option.
	    char *option_flags = opa[0];
	    char *option_name = opa[1];
	    ncnt = option_flags[0] - '0';

	    ASSERT(option_name != NULL,"ParseOptions: Missing option name");
	    ASSERT(isdigit(option_flags[0]),"ParseOptions: missing digit in option flags");

	    if (option_name[1] == cp[1] && strcmp(option_name,cp) == 0) {
		int n;
		void *option_bool = opa[2];
		if (option_bool) {
		    *(int*)option_bool = 1;
		}
		argc--; argv++;

		for (n = 0; n < ncnt; n++) {
		    if (argc <= 0) {
			if (cmdName) MsgErrorF("%s: ",cmdName);
			MsgErrorF("error: expecting argument to %s option\n",option_name);
			return -1;
		    }
		    switch (option_flags[1]) {
		    case 'o':	// objects are treated like a string by ParseOptions.
		    case 'l':	// lists are treated like a string by ParseOptions.
		    case 's': {	// String valued option.
			*(char**)(opa[3+n]) = *argv;
			break;
		    }
		    case 'd': {	// Integer.
			char *endptr;
			*(int*)(opa[3+n]) = strtol(*argv,&endptr,10);
			if (*endptr != 0) {
			    // conversion failed.
			    if (cmdName) MsgErrorF("%s: ",cmdName);
			    MsgErrorF("error: expecting integer argument to %s option\n",option_name);
			    return -1;
			}
			break;
		    }
		    case 'f': {	// Float (double)
			char *endptr;
			*(double*)(opa[3+n]) = strtod(*argv,&endptr);
			if (*endptr != 0) {
			    // conversion failed.
			    if (cmdName) MsgErrorF("%s: ",cmdName);
			    MsgErrorF("error: expecting integer argument to %s option\n",option_name);
			    return -1;
			}
			break;
		    }
		    case 'u': {	// Data-base units.
			if (!UnitsValidS(*argv)) {
			    // It already printed an error.
			    return -1;
			}
			*(int*)(opa[3+n]) = UnitsS2I(*argv);
			break;
		    }
		    default:
			ASSERT(0,"ParseOptions: invalid option array");
		    }

		    argc--; argv++;
		}
		goto nextoption;
	    }
	}

	// The option is unrecognized.
	// If TCL_OPT_WARN, and it is not just a negative number, then fail.
	if ((flags & TCL_OPT_WARN) && !isdigit((*argv)[1])) {
	    if (cmdName) MsgErrorF("%s: ",cmdName);
	    MsgErrorF("error: unrecognized option: %s\n",*argv);
	    return -1;
	}
	break;

	nextoption:;
    }

    if (flags & TCL_OPT_NOARGS) {
	if (cmdName) MsgErrorF("%s: ",cmdName);
	MsgErrorF("error: unexpected argument: %s\n",*argv);
    }


    *pargc = argc;
    *pargv = argv;
    return 0;
}

#if 0  // not needed
// Init all variables in an options array.
void SPInitOptions(void **options)
{
    char **opa;  /* Pointer into user supplied options array */
    int n, ncnt;
    void *option_bool;

    for (opa = (char**)options; *opa; opa += 3+ncnt) {
	// check char 1, which is the first char of the option.
	char *option_flags = opa[0];
	ncnt = option_flags[0] - '0';

	ASSERT(opa[1] != NULL,"InitOptions: Missing option name");
	ASSERT(isdigit(option_flags[0]),"InitOptions: missing digit in option flags");

	option_bool = opa[2];
	if (option_bool) {
	    *(int*)option_bool = 0;
	}
	for (n = 0; n < ncnt; n++) {
	    *(int*)opa[3+n] = 0;
	}
    }
}
#endif


#if TODO
// Parse tcl options for a tcl ObjCmdProc.
int SPParseObjOptions(Tcl_Interp *interp,char *cmdName,int *pargc, Tcl_Obj ***objv,void **options, int flags)
{
	// ...
}
#endif


// Return the nth element from the tcl list object,
// or NULL if n is out of range, or the obj can not be
// converted to a list.
char *SPTListGetStr(Tcl_Interp *interp, Tcl_Obj *list,int n)
{
    Tcl_Obj *obj;
    if (Tcl_ListObjIndex(interp,list,n,&obj) != TCL_OK) {
	MsgErrorF("%s\n",Tcl_GetStringResult(interp));
	return NULL;
    }
    return obj ? Tcl_GetStringFromObj(obj,NULL) : NULL;
}


static void spAddPaint(Tcl_Interp *interp,Tcl_Obj *plist,Tile *tile,SPSearchContext *spx,int *plimit)
{
    char pathbuf[200];
    Tcl_Obj *list = Tcl_NewListObj(0,0);
    Rect tr, r;

    TListAppendStr(interp,list, DBTypeLongNameTbl[DBgetTileType(tile)]);

    TiToRect(tile,&tr);
    if (spx) {
	GeoTransRect(&spx->spx_trans,&tr,&r);
    } else {
	r = tr;
    }

    TListAppendDouble(interp,list,UnitsI2D(r.r_xbot));
    TListAppendDouble(interp,list,UnitsI2D(r.r_ybot));
    TListAppendDouble(interp,list,UnitsI2D(r.r_xtop));
    TListAppendDouble(interp,list,UnitsI2D(r.r_ytop));

    if (spx) {
	SPsxInstPath(spx,pathbuf,200);
	strcat(pathbuf,"/");	// makes it look like db_search_paint result
	TListAppendStr(interp,list, pathbuf);
    } else {
	TListAppendStr(interp,list, "");
    }

    // Group.  Does not handle multigroup case as well as max, but this is just for testing anyway.
    if (DBisSetTileFlag(tile,TF_MULTIGROUP)) {
	char *gbuf[1000];
	GroupList *gl;
	gbuf[0] = 0;
	for (gl=(GroupList *) TiGetGroups(tile); gl; gl=gl->gl_next) {
	    strcat(gbuf,gl->gl_group->g_name);
	}
        TListAppendStr(interp, list, gbuf);
    } else {
      Group *g = TiGetGroups(tile);
      TListAppendStr(interp, list, g ? g->g_name:"0");
    }

    // Add the list for this paint tile onto the list of paints.
    TListAppendObj(interp,plist,list);

    (*plimit)--;
}



static void spAddCell(Tcl_Interp *interp,Tcl_Obj *plist,SPSearchContext *spx)
{
    Tcl_Obj *list = Tcl_NewListObj(0,0);
    char pathbuf[200];

    TListAppendStr(interp,list, SPsxInstPath(spx,pathbuf,200));

    TListAppendStr(interp,list, spx->spx_use->cu_def->cd_name);

    TListAppendDouble(interp,list,UnitsI2D(spx->spx_area.r_xbot));
    TListAppendDouble(interp,list,UnitsI2D(spx->spx_area.r_ybot));
    TListAppendDouble(interp,list,UnitsI2D(spx->spx_area.r_xtop));
    TListAppendDouble(interp,list,UnitsI2D(spx->spx_area.r_ytop));

    // Forget the expansion, transform and arrayinfo for now.

    // Add the list for this paint tile onto the list of paints.
    TListAppendObj(interp,plist,list);
}


static void spSubSearch(Tcl_Interp *interp,Tcl_Obj*result,SPSearchContext *spx,TileTypeBitMask *pmask,int *plimit)
{
    while (*plimit && (spx = SPInstEnumNext(spx))) {
	SPSearchEnum spe; Tile *tile;
	SPSearchContext *spxchild;

	SPsxPlanesEnumInit(&spe,spx,pmask);
	while (tile = SPPlanesEnumNext(&spe)) {
	    spAddPaint(interp,result,tile,spx,plimit);
	}
	SPPlanesEnumTerm(&spe);

	spxchild = SPsxInstEnumInit(spx,"spss");
	spSubSearch(interp,result,spxchild,pmask,plimit);
    }
    SPInstEnumTerm(spx);
}



// Used to test both the new paint and inst search routines.
// TODO: Change -any_cell to -hier [visible all none stop]
TCL_DOC(spSearchPaint,sp_search_paint,"Search for paint, like db_search_paint",
  "");
TCL_COMMAND(spSearchPaint)
{ CMD_BEGIN(interp);
{
    static struct {
	char *cellstring;
	int any_cell;
	int limit;
	int f_area;
	Rect area;
	} o;

    static void* options[] = {
	"0",	"-any_cell",	&o.any_cell,
	"1s",	"-cell",	0,		&o.cellstring,
	"4u",	"-area",	&o.f_area,	&o.area.r_xbot,&o.area.r_ybot,&o.area.r_xtop,&o.area.r_ytop,
	"1s",	"-limit",	0,		&o.limit,
	0 };

    char *cmdName = (argc--,*argv++);

    int i;  char *name;
    CellDef *cdef;
    TileTypeBitMask mask;
    Tcl_Obj *result_list;

    // Init options.
    memset(&o,0,sizeof(o));
    o.limit = -1;

    if (SPParseOptions(cmdName,&argc,&argv,options,0)) {CMD_RETURN(interp);}

    if (argc > 0) {
	char *layers = *argv;
	argc--; argv++;
	if (!CmdParseLayers(layers,&mask)) {
	    CMD_RETURN(interp);	// CmdParseLayers printed a message.
	}
    } else {
	// Search all user layers (skips drc, etc).
	mask = DBNonSpaceUserLayerBits;
    }

    if (argc != 0) {
	MsgErrorF("too many arguments\n");
	CMD_RETURN(interp);
    }

    if (o.cellstring) {
	cdef = DBCellLookDef(o.cellstring);
	if (cdef == NULL) {
	    MsgErrorF("Cell %s not found\n",o.cellstring);
	    CMD_RETURN(interp);
	}
    } else {
	cdef = EditCellUse->cu_def;
    }

    if (!o.f_area) {
	// Search the entire cell.
	o.area = *DBBBoxCellDef(cdef);
    }

    result_list = Tcl_NewListObj(0,0);

    {	// Search current cell first.
	SPSearchEnum spe; Tile *tile;

	SPPlanesEnumInit(&spe,cdef,NULL,&o.area,&mask,0,"spSearchPaint");
	while (o.limit && (tile = SPPlanesEnumNext(&spe))) {
	    spAddPaint(interp,result_list,tile,NULL,&o.limit);
	}
	SPPlanesEnumTerm(&spe);
    }

    if (o.any_cell) {
	SPSearchContext *spx;
	spx = SPInstEnumInit(cdef,&o.area,NULL,NULL,0,"spSearchPaint");
	spSubSearch(interp,result_list,spx,&mask,&o.limit);
    }

    Tcl_SetObjResult(interp,result_list);

    CMD_RETURN(interp);
}}


// Used to test both the new paint and inst search routines.
// TODO: Change -any_cell to -hier [visible all none stop]
TCL_DOC(spSearchCells,sp_search_cells,"Search for cells, like db_search_cells",
  "");
TCL_COMMAND(spSearchCells)
{ CMD_BEGIN(interp);
{
    static struct {
	char *cellstring;
	int any_cell;
	int limit;
	int f_area;
	Rect area;
	} o;

    static void* options[] = {
	"0",	"-any_cell",	&o.any_cell,
	"1s",	"-cell",	0,		&o.cellstring,
	"4u",	"-area",	&o.f_area,	&o.area.r_xbot,&o.area.r_ybot,&o.area.r_xtop,&o.area.r_ytop,
	"1s",	"-limit",	0,		&o.limit,
	0 };

    char *cmdName = (argc--,*argv++);

    int i;  char *name;
    CellDef *cdef;
    TileTypeBitMask mask;
    Tcl_Obj *result_list;

    // Init options.
    memset(&o,0,sizeof(o));
    o.limit = -1;

    if (SPParseOptions(cmdName,&argc,&argv,options,0)) {CMD_RETURN(interp);}

    if (argc != 0) {
	MsgErrorF("too many arguments\n");
	CMD_RETURN(interp);
    }

    if (o.cellstring) {
	cdef = DBCellLookDef(o.cellstring);
	if (cdef == NULL) {
	    MsgErrorF("Cell %s not found\n",o.cellstring);
	    CMD_RETURN(interp);
	}
    } else {
	cdef = EditCellUse->cu_def;
    }

    //if (!o.f_area) {
	// Search the entire cell.
    //	o.area = *DBBBoxCellDef(cdef);
    //}

    result_list = Tcl_NewListObj(0,0);

    {	// Search current cell first.
	SPSearchContext *spx;

	spx = SPInstEnumInit(cdef,o.f_area ? &o.area : NULL,0,0,
		o.any_cell ? SP_RECURSIVE:0,"spSearchCells");
	while (o.limit && (spx = SPInstEnumNext(spx))) {
	    spAddCell(interp,result_list,spx);
	    o.limit--;
	}
	SPInstEnumTerm(spx);	// Its OK if spx is null.
    }

    Tcl_SetObjResult(interp,result_list);

    CMD_RETURN(interp);
}}



#if 0
//**************************************************************************************
// LOG FILE AND WARNING MESSAGE PACKAGE
//**************************************************************************************

static int SPMsgWarnCount = 0;
static int SPMsgWarnMax = 20;
// If non null, this is the log file descriptor.
FILE *SPLogfd = NULL;

void SPMsgWarnV(char *fmt, va_list args)
{
    if (SPLogfd) {
	vfprintf(SPLogfd,fmt,args);
    }
    MsgWarnV(fmt,args);
}

void SPMsgWarnF(char *fmt, ...)
{
    va_list args;
    va_start(args,fmt);
    SPMsgWarnV(fmt,args);
    va_end(args);
}

void SPMsgInfoV(char *fmt, va_list args)
{
    if (SPLogfd) {
	vfprintf(SPLogfd,fmt,args);
    }
    MsgInfoV(fmt,args);
}

void SPMsgInfoF(char *fmt, ...)
{
    va_list args;
    va_start(args,fmt);
    SPMsgInfoV(fmt,args);
    va_end(args);
}
#endif




/*
 * ----------------------------------------------------------------------------
 *
 *
 * SpcTclInit --
 *
 * Initialize tcl commands for this module
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Registers command(s) with tcl.
 *	
 * ----------------------------------------------------------------------------
 */
void
SpcTclInit(Tcl_Interp *interp)
{


// Temporary: To run purify the groute and nl are loaded statically.  Init them.
//Max_gr_package_Init(interp);
// Note: This did not work because the def reader in nl collides with mine.
//Nl_shell_Init(interp);


    spSearchPaint_init(interp);
    spSearchCells_init(interp);
    spcong_init(interp);
#if 0
    MnDocLinkVar(interp, "SP_MSG_WARN_MAX",
   	(char *) &SPMsgWarnMax, TCL_LINK_INT,
   	"Max number of warnings per command",
   	"After this number of warnings are printed, further warnings are suppressed.");
    MnDocLinkVar(interp, "SP_MSG_WARN_COUNT",
   	(char *) &SPMsgWarnCount, TCL_LINK_INT,
   	"Count of warnings printed",
   	"Incremented when a warning is printed.  Reset in tcl at the start of each command");
#endif


#if 0
    // NOTE: Router interface is being loaded as a dynamic link library,
    // so this code currently unneeded.

    //**************************************************************************************
    // Global Router Interface.  By Lee, adapted to max by pat.
    //**************************************************************************************
    {
	extern int tcl_gr();
	extern int tcl_gr_block();
	extern int tcl_gr_grid();
	extern int tcl_gr_grid_iter();


	MnDocCreateCommand(interp, "gr_command", tcl_gr, NULL, NULL,
	    "global router interface",
	    "Usage: gr_command <nl_cell_object> <x_ggrid_size> <y_ggrid_size> <v_resources_per_track> <h_resources_per_track> <show_grid>
	    show_grid typically 0 or 1.
	    if adding blockages, call this proc with show_grid=2 to setup grid, 
	    then call gr_block to add blockages, and then call with show_grid=3 to 
	    route.
	    ");
	MnDocCreateCommand(interp, "gr_block", tcl_gr_block, NULL, NULL,
	    "global router interface",
	    "usage (from tcl): gr_block x y v h
	    where x,y is the ggrid in ggrid units (i.e. 0,0 is lower left)
	    h,v are the blockage amounts in horizontal/vertical dirs.
	    ");
	MnDocCreateCommand(interp, "gr_grid", tcl_gr_grid, NULL, NULL,
	    "global router interface","");
	MnDocCreateCommand(interp, "gr_grid_iter", tcl_gr_grid_iter, NULL, NULL,
	    "global router interface","
	    Returns x, y, h, v.  Where x, y are the coords of the ggrid (offset
	    to corresponds to microns) and h, v are the congestions there.
	    ");
    }
#endif
}
