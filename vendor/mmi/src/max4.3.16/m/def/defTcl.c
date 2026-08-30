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
 * defTcl.c -- Tcl command interface to this module
 */

#include <tcl.h>
#include <stdlib.h>
#include "magic.h"
#include "main.h"
#include "message.h"
#include "database.h"
#include "utils.h"
#include "units.h"
#include "special.h"
#include "def.h"
#include "defInt.h"
#include "drc.h"



#if 0
/*
 *--------------------------------------------------------------
 *
 * defTclHello --
 *
 * implements tcl command. 
 *
 * C Result:
 *	A standard Tcl result.
 *
 *--------------------------------------------------------------
 */

TCL_DOC(defTclHello,def_hello,"example def tcl cmd","
  Usage: def_hello

  Returns: {hello world}
  ")

TCL_COMMAND(defTclHello)
{ CMD_BEGIN(interp);
{
    static struct {
	int verbose;	// Must be initialized below!
	} o;
    static void* options[] = {
      "0","-verbose",&o.verbose,
      0,0,0};
    char *cmdName = (argc--,*argv++);

    o.verbose = 0;

    if (SPParseOptions(cmdName,&argc,&argv,options,0)) {CMD_RETURN(interp);}

    /* no positional args yet */
    if(argc!=0) {
       MsgErrorF("%s: error: wrong number of arguments",cmdName);
       CMD_RETURN(interp);
    }

    /* set result */
    Tcl_SetResult(interp, "Hello World.", TCL_VOLATILE);

    CMD_RETURN(interp);
}}
#endif



TCL_DOC(defTclConInit,def_con_init,"Create internal connectivity database","
  Usage: def_con_init [-match] [-component comp_list] [-vias via_list] [-ignore ignore_list]
	[-component_nopin comp_nopin_list] [-layers layers] [-verbose <value>]

  <comp_list> is the list of leaf cells.  If connectivity is being extracted for
	use in a DEF file, this would typically be the list of LEF cells.
  <via_list> is the list of cells through which connectivity will be extracted
	even if they appear as subcells of the cells in <comp_list>
	Typically, this is a list of vias, but it could be anything.
  <ignore_list> is a list of cells to completely ignore.
  <comp_nopin_list> is like <comp_list>, except that labels in these cells,
	if any, are ignored.
	During DEF generation this list is used for power vias.  These vias
	have a label that is required by other tools, but they do not appear
	in the verilog netlist and so the label should not be included in
	the connectivity section of the DEF file.
  <layers> is the list of layers to extract, typically metal, and found using:
	[techinfo layers metal].

    This command builds an internal data-base representing the
    connectivity in the cell hierarchy starting at the root cell,
    down through cells specified by the arguments above.

    Other commands are used to trace the resulting data-base
    to write a DEF file, or other connectivity based operations.
    After using the data-base, it must be released using def_con_term.

    Thus writing a DEF file is a multi-phase process:
	1.  Build the connectivity data-base with def_con_init
	2.  Traverse the data-base and write the def file using:
		def_output_components, def_count_components, def_output_nets
		and def_count_nets.
	3.  Release the connectivity database using def_con_term.
	    Note that you must call def_con_term before anything else
	    happens in max that might use the shared area of the
	    max data-base, which typically means that you must do
	    this before returning interactive control to the user.


    Note: the lists provided to this command currently control both
    phases of DEF generation.  This will eventually be changed so that
    this command specifies only the information pertinent to connectivity
    extraction, and the other def routines will specify the lists
    pertinent to them.

    It is an error if paint connects to a leaf cell at paint that has no
    connected label inside the cell.

    Note that vias do not need to be included in the list of lef cells.

    WARNING!!!

    This command modifies the max internal database by using an area
    in max internal structures that is shared among other commands.
    You MUST destroy the connectivity data-base with def_con_term before
    control is returned to max, to restore these shared areas.

    WARNING!!! The max interactive DRC modifies the paint planes when it
    is running in background mode, destroying the connectivity database.
    This procedure turns off DRC as a side-effect.
    This is not strictly necessary if def_con_term is called before any other interactive
    commands occur, however, if you were to forget, the cost of a mistake is a core-dump.
    ")
TCL_COMMAND(defTclConInit)
{   CMD_BEGIN(interp);
{
    static struct {
	char *via_names;
	char *vcell_names;
	char *skip_names;
	char *comp_nopin_names;
	char *layers;
	int debug, noabut, match, verbose;
	} o;
    static void* options[] = {
	"1s",	"-vias",	0,	&o.via_names,
	"1s",	"-component_nopins",	0,	&o.comp_nopin_names,
	"1s",	"-component",	0,	&o.vcell_names,
	"1s",	"-ignore",	0,	&o.skip_names,
	"1s",	"-layers",	0,	&o.layers,
	"1d",	"-debug",	0,	&o.debug,
	"0",	"-noabut",	&o.noabut,
	"0",	"-match",	&o.match,
	"1d",	"-verbose",	0,	&o.verbose,
	0,0,0};
    char *cmdName = (argc--,*argv++);

    int i;  char *pattern;
    CellDef *def;

    memset(&o,0,sizeof(o));	// init all options to 0.

    if (SPParseOptions(cmdName,&argc,&argv,options,0)) {CMD_RETURN(interp);}


    if (o.via_names) {
	// TODO: This wont be necessary when we switch this to a Tcl_ObjCmd.
	Tcl_Obj *via_list = Tcl_NewStringObj(o.via_names,-1);
	for (i = 0; (pattern = SPTListGetStr(interp,via_list,i)); i++) {
	    if (o.match) {
		for (def = DBCellDefs; def; def = def->cd_next) {
		    if (Match(pattern,def->cd_name)) {
			DfSetCellExtType(def,dfext_all);
			DfSetCellDefType(def,dfd_netvia,0);
		    }
		}
	    } else {
		if ((def = DBCellLookDef(pattern)) == NULL) {
		    if (o.verbose) {
			MsgWarnF("%s: Cell %s not found\n",cmdName,pattern);
		    }
		    continue;
		}
		DfSetCellExtType(def,dfext_all);
		DfSetCellDefType(def,dfd_netvia,0);
	    }
	}
	Tcl_DecrRefCount(via_list);
    }

    if (o.skip_names) {
	// TODO: This wont be necessary when we switch this to a Tcl_ObjCmd.
	Tcl_Obj *skip_list = Tcl_NewStringObj(o.skip_names,-1);
	for (i = 0; (pattern = SPTListGetStr(interp,skip_list,i)); i++) {
	    if (o.match) {
		CellDef *def;
		for (def = DBCellDefs; def; def = def->cd_next) {
		    if (Match(pattern,def->cd_name)) {
			DfSetCellExtType(def,dfext_none);
			DfSetCellDefType(def,dfd_discard,0);
		    }
		}
	    } else {
		if ((def = DBCellLookDef(pattern)) == NULL) {
		    if (o.verbose) {
			MsgWarnF("%s: Cell %s not found\n",cmdName,pattern);
		    }
		    continue;
		}
		DfSetCellExtType(def,dfext_none);
		DfSetCellDefType(def,dfd_discard,0);
	    }
	}
	Tcl_DecrRefCount(skip_list);
    }

    if (o.comp_nopin_names) {
	// TODO: This wont be necessary when we switch this to a Tcl_ObjCmd.
	Tcl_Obj *comp_nopin_list = Tcl_NewStringObj(o.comp_nopin_names,-1);
	for (i = 0; (pattern = SPTListGetStr(interp,comp_nopin_list,i)); i++) {
	    if (o.match) {
		for (def = DBCellDefs; def; def = def->cd_next) {
		    if (Match(pattern,def->cd_name)) {
			DfSetCellExtType(def,dfext_all);
			DfSetCellDefType(def,dfd_component,0);
		    }
		}
	    } else {
		if ((def = DBCellLookDef(pattern)) == NULL) {
		    if (o.verbose) {
			MsgWarnF("%s: Cell %s not found\n",cmdName,pattern);
		    }
		    continue;
		}
		DfSetCellExtType(def,dfext_all);
		DfSetCellDefType(def,dfd_component,0);
	    }
	}
	Tcl_DecrRefCount(comp_nopin_list);
    }

    if (o.vcell_names) {
	// TODO: This wont be necessary when we switch this to a Tcl_ObjCmd.
	Tcl_Obj *vcell_list = Tcl_NewStringObj(o.vcell_names,-1);
	for (i = 0; (pattern = SPTListGetStr(interp,vcell_list,i)); i++) {
	    if (o.match) {
		CellDef *def;
		for (def = DBCellDefs; def; def = def->cd_next) {
		    if (Match(pattern,def->cd_name)) {
			DfSetCellExtType(def,dfext_stop);
			DfSetCellDefType(def,dfd_component,1);
		    }
		}
	    } else {
		if ((def = DBCellLookDef(pattern)) == NULL) {
		    if (o.verbose) {
			MsgWarnF("%s: Cell %s not found\n",cmdName,pattern);
		    }
		    continue;
		}
		DfSetCellExtType(def,dfext_stop);
		DfSetCellDefType(def,dfd_component,1);
	    }
	}
	Tcl_DecrRefCount(vcell_list);
    }


    if (o.layers == NULL) {
	MsgErrorF("No layers specified\n");
	CMD_RETURN(interp);
    }

    DFConnectInit();
    dfGlob.dfQuiet = !o.verbose;
    if (o.noabut) {
	dfGlob.dfOptNoAbutCheck = 1;
    }
    if (o.debug) {
	dfGlob.dfDebug = o.debug;
    }
    dfGlob.dfDefFactor = 1;

#if 0
    // This code shows how you can get a file descriptor from Tcl into C.
    if (logfile && *logfile) {
	Tcl_Channel chan;
	// If the file is a tcl channel...
	if (strncmp(logfile,"file",4) == 0 && (chan=Tcl_GetChannel(interp,logfile,0))) {
	    Tcl_Flush(chan);
	    dfGlob.dfLogfd = fdopen(dup(atoi(&logfile[4])),"a");
	} else {
	    dfGlob.dfLogfd = fopen(logfile,"w");
	}
	if (dfGlob.dfLogfd == NULL) {
	    MsgWarnF("Can not open -logfile %s\n",logfile);
	}
    }
#endif
    DFConnectCreate(NULL,o.layers);

    // This just flushes and closes our file FILE pointer;
    // does not touch the underlying file descriptor.
    if (dfGlob.dfLogfd) { fclose(dfGlob.dfLogfd); }

    // Turn this off to make SURE we wont get a core-dump because DRC is changing
    // the paint tiles when we are not looking.
    DRCBackGround = FALSE;

    CMD_RETURN(interp);
}}


TCL_DOC(defTclCountNets,def_count_nets,"Return count of nets in hierarchy","")
TCL_COMMAND(defTclCountNets)
{   CMD_BEGIN(interp);
{
    int cnt;
    char *cmdName = (argc--,*argv++);

    cnt = DFDefCountNets(1);

    Tcl_SetObjResult(interp, Tcl_NewIntObj(cnt));

    CMD_RETURN(interp);
}}


// Convert tcl channel name to FILE* pointer.  Flush it first.
// Print error and return NULL on failure.
// You can fclose the returned file when you are done.
static FILE *getTclFile(Tcl_Interp *interp,char *chan_name, char *cmdName)
{
    int file_descriptor;  FILE *fp;
    Tcl_Channel chan;

    // The argument is supposed to be something like "file6"
    if (strncasecmp(chan_name,"FILE",4) != 0) {
	MsgErrorF("%s: expecting open file descriptor\n",cmdName);
	return NULL;
    }
    file_descriptor = dup(atoi(&chan_name[4]));
    if (file_descriptor < 0) {
	MsgErrorF("%s: can not attach to specified file descriptor\n",cmdName);
	return NULL;
    }

    chan = Tcl_GetChannel(interp,chan_name,NULL);
    if (chan == NULL) {
	MsgErrorF("%s: can not attach to specified tcl channel\n",cmdName);
	return NULL;
    }
    Tcl_Flush(chan);

    fp = fdopen(file_descriptor,"w");
    if (fp == NULL) {
	MsgErrorF("%s: cannot attach to specified file\n",cmdName);
	return NULL;
    }

    return fp;
}



TCL_DOC(defTclOutputNets,def_output_nets,"Output contents of DEF file NETS/SPECIALNETS section","
    Usage: def_output_nets <file>
")
TCL_COMMAND(defTclOutputNets)
{   CMD_BEGIN(interp);
{
    int cnt;
    char *cmdName = (argc--,*argv++);
    char *file_name;  int file_descriptor;  FILE *fp;

    if (argc != 1) {
	MsgErrorF("%s: syntax error\n",cmdName);
	CMD_RETURN(interp);
    }
    file_name = argv[0];

    fp = getTclFile(interp,file_name,cmdName);
    if (fp == NULL) { CMD_RETURN(interp); }

    DFDefOutputNets(fp,1);

    fclose(fp);

    CMD_RETURN(interp);
}}

TCL_DOC(defTclCountComponents,def_count_components,"Return count of DEF COMPONENTS in hierarchy","")
TCL_COMMAND(defTclCountComponents)
{   CMD_BEGIN(interp);
{
    int cnt;
    char *cmdName = (argc--,*argv++);

    cnt = DFDefCountComponents();

    Tcl_SetObjResult(interp, Tcl_NewIntObj(cnt));

    CMD_RETURN(interp);
}}


TCL_DOC(defTclOutputComponents,def_output_components,"Output contents of DEF file COMPONENTS section","
    Usage: def_output_components <file>
")
TCL_COMMAND(defTclOutputComponents)
{   CMD_BEGIN(interp);
{
    int cnt;
    char *cmdName = (argc--,*argv++);
    char *file_name;  int file_descriptor;  FILE *fp;

    if (argc != 1) {
	MsgErrorF("%s: syntax error\n",cmdName);
	CMD_RETURN(interp);
    }
    file_name = argv[0];

    fp = getTclFile(interp,file_name,cmdName);
    if (fp == NULL) { CMD_RETURN(interp); }

    DFDefOutputComponents(fp);

    fclose(fp);

    CMD_RETURN(interp);
}}


TCL_DOC(defTclConTerm,def_con_term,"Destroy internal connectivity database","
  You MUST call this after def_con_init to restore the max internal database.
  ")
TCL_COMMAND(defTclConTerm)
{   CMD_BEGIN(interp);
{
    static void* options[] = {
	0};
    char *cmdName = (argc--, *argv++);
    // No options
    // if (SPParseOptions(cmdName,&argc,&argv,options,0)) {CMD_RETURN(interp);}


    DFConnectTerm();

    CMD_RETURN(interp);
}}


TCL_DOC(defTclReadDef,def_read,"Read DEF file","
  Options:
  -components <value>      [default 1]  read COMPONENTS section if <value> is non-zero.
  -nets <value>            [default 1]  read NETS and SPECIALNETS section if <value> is non-zero.
  -merge <value>           [default 0]  merge DEF into current cell if <value> is non-zero.
		    default is to create a cell with name specified in the DEF file.
  ")
TCL_COMMAND(defTclReadDef)
{   CMD_BEGIN(interp);
{
    static int do_nets, do_components, do_merge;
    static void* options[] = {
	"1d",	"-components",	0,	&do_components,
	"1d",	"-nets",	0,	&do_nets,
	"1d",	"-merge",	0,	&do_merge,
	0,0,0};
    char *cmdName = (argc--,*argv++);
    char *file_name;

    do_merge = 0;
    do_nets = do_components = 1;
    if (SPParseOptions(cmdName,&argc,&argv,options,0)) {CMD_RETURN(interp);}

    if (argc != 1) {
	MsgErrorF("%s: syntax error\n",cmdName);
	CMD_RETURN(interp);
    }

    file_name = argv[0];

    {
	FILE *pf = fopen(file_name,"r");

	if (pf == NULL) {
	    MsgErrorF("%s: can not open file: %s\n",cmdName,file_name);
	    CMD_RETURN(interp);
	}

	def_read(pf,do_nets,do_components,do_merge);
	fclose(pf);
    }

    CMD_RETURN(interp);
}}


static void bugtest()
{
    BPEnum bpe1;
    int cnt1;
    CellUse *use1;
    CellDef *def = DBCellLookDef("chorus");

    cnt1 = 0;
    BPEnumInit(&bpe1,def->cd_cellPlane,0,BPE_ALL,"test1");
    while (use1 = BPEnumNext(&bpe1)) {
	CellUse *use2;
	BPEnum bpe2;
	Rect bbox, rect1, rect1plus1;
	printf("use %s\n",use1->cu_id);

	cnt1++;

	bbox = *DBBBoxCellDef(use1->cu_def);
	GEOTRANSRECT(&use1->cu_transform,&bbox,&rect1);
	GEO_EXPAND(&rect1,1,&rect1plus1);

	// If you comment out the following three lines, the outer loop will traverse all cells in chorus.
	// If this code is left in, the outer loop will terminate early.
	BPEnumInit(&bpe2,def->cd_cellPlane,&rect1plus1,BPE_OVERLAP,"test2");
	while (use2 = BPEnumNext(&bpe2)) { continue; }
	BPEnumTerm(&bpe2);
    }
    BPEnumTerm(&bpe1);
    printf("cnt1 = %d\n",cnt1);
}


TCL_DOC(defTclConTest,def_con_test,"Used during testing of connectivity database","
  ")
TCL_COMMAND(defTclConTest)
{   CMD_BEGIN(interp);
{
    static struct {
	int debug;
	} o;
    static void* options[] = {
	"1d",	"-debug",	0,	&o.debug,
	0};
    char *cmdName = (argc--, *argv++);
    
    o.debug = 0;

    if (SPParseOptions(cmdName,&argc,&argv,options,0)) {CMD_RETURN(interp);}

    bugtest();
    CMD_RETURN(interp);

    if (o.debug) { dfGlob.dfDebug = o.debug; }

    DFConnectTest();

    CMD_RETURN(interp);
}}





// example tcl linked var
// static int defLinkedInt = 31415;



/*
 * ----------------------------------------------------------------------------
 *
 *
 * DefTclInit --
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
DefTclInit(Tcl_Interp *interp)
{
   //defTclHello_init(interp);
   defTclConInit_init(interp);
   defTclConTerm_init(interp);
   defTclConTest_init(interp);
   defTclCountNets_init(interp);
   defTclOutputNets_init(interp);
   defTclCountComponents_init(interp);
   defTclOutputComponents_init(interp);
   defTclReadDef_init(interp);

   // MnDocLinkVar(interp, "DEF_LINKED_INT",
   //		(char *) &defLinkedInt, TCL_LINK_INT,
   //		"example tcl linked integer",
   //		"not used for anything");
}

