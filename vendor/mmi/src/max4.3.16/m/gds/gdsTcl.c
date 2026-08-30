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
 * gdsTcl.c -- Tcl command interface to this module
 */

static char rcsid[] = "$Header$";

#include <tcl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include "magic.h"
#include "main.h"
#include "message.h"
#include "signals.h"
#include "layout.h"
#include "database.h"
#include "units.h"
#include "utils.h"
#include "database.h"
#include "databaseInt.h"
#include "gds.h"
#include "gdsInt.h"


/*
 *--------------------------------------------------------------
 *
 * gdsTclCmdCompile --
 *
 * implements tcl command. 
 *
 * C Result:
 *	A standard Tcl result.
 *
 *--------------------------------------------------------------
 */

#define gds_compile_DESC "convert GDSII ASCII \"dump\" to binary GDSII file"

#define gds_compile_DOC "
Usage:  gds_compile inFile [outFile]

Returns: name of file written.

inFile extension defaults to '.gds_ascii'
outFile defaults to infile name with extension of '.gds' 

gds_dump performs the inverse operation.  The input format of gds_compile 
can be determined by studying the output of gds_dump.

WARNING:  currently incomplete!
"
static int
gdsTclCmdCompile(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
  char *cmdName;
  char *inArg = NULL;
  char *outArg = NULL;
  char inPathName[1000];
  char outPathName[1000];
  int noExt = FALSE;
  FILE *in;
  FILE *out;

  CMD_BEGIN(interp);

  /* parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* Parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];

    /* bad switch */
    goto usage;
  } /* end while(argc>0 && **argv=='-')  */

  /* parse inArg */
  if(argc==0) goto usage;
  inArg = *argv;
  argc--; argv++;

  /* parse outArg */
  if(argc!=0)
  {
    outArg = *argv;
    argc--; argv++;
  }

  /* should be no args left */
  if(argc != 0) goto usage;

  /* setup full pathnames */
  strcpy(inPathName,PaExtendedName(inArg,".gds_ascii"));
  if(outArg)
  {
    strcpy(outPathName,PaExtendedName(outArg,".gds"));
  }
  else
  {
    char dir[BUFSIZ], base[BUFSIZ];
 
    PaSplitName(inPathName,dir,base,NULL);
    strcpy(outPathName,dir);
    strcat(outPathName,base);
    strcat(outPathName,".gds");
  }

  /* open files */
  {
    in = fopen(inPathName, "r");
    if(!in)
    {
      MsgErrorF("Could not read %s\n", inPathName);
      CMD_RETURN(interp);
    }

    out = fopen(outPathName, "w");
    if(!out)
    {
      MsgErrorF("Could not write %s\n", outPathName);
      fclose(in);
      CMD_RETURN(interp);
    }
  }

  gdsCompile(in, out); 

  fclose(in);
  fclose(out);

  /* return name of file written */
  Tcl_SetResult(interp, outPathName, TCL_VOLATILE);
  CMD_RETURN(interp);

usage:
    MsgErrorF("usage:  %s inFile [outFile]\n", 
	      cmdName);
    CMD_RETURN(interp);
}

/*
 *--------------------------------------------------------------
 *
 * gdsTclCmdDump --
 *
 * implements tcl command. 
 *
 * C Result:
 *	A standard Tcl result.
 *
 *--------------------------------------------------------------
 */

#define gds_dump_DESC "convert GDSII stream file to ascii equivalent"

#define gds_dump_DOC "
Usage:  gds_dump [-verbose] inFile [outFile]

Returns: name of file written.

inFile extension defaults to '.gds' 
outFile defaults to input file name with '_ascii' appended (e.g. foo.gds_ascii).

if -verbose, add more comments to output.

NOTE:  See gds_compile for inverse operation!
"
static int
gdsTclCmdDump(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
  char *cmdName;
  char *inArg = NULL;
  char *outArg = NULL;
  char inPathName[1000];
  char outPathName[1000];
  int noExt = FALSE;
  int verbose = FALSE;
  int inFD;                  /* input file descriptor */
  FILE *out;


  CMD_BEGIN(interp);

  /* parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* Parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];

    if (c=='v' && strncmp(*argv,"-verbose",length)==0)
    {
      verbose=TRUE;
      argc--;
      argv++;
      continue;
    }

    /* bad switch */
    goto usage;
  } /* end while(argc>0 && **argv=='-')  */

  /* parse inArg */
  if(argc==0) goto usage;
  inArg = *argv;
  argc--; argv++;

  /* parse outArg */
  if(argc!=0)
  {
    outArg = *argv;
    argc--; argv++;
  }

  /* should be no args left */
  if(argc != 0) goto usage;

  /* setup full pathnames */
  strcpy(inPathName,PaExtendedName(inArg,".gds"));
  if(outArg)
  {
    strcpy(outPathName,PaExtendedName(outArg,".gds_ascii"));
  }
  else
  {
    strcpy(outPathName,inPathName);
    strcat(outPathName,"_ascii");
  }

  /* open files */
  {
    inFD = open(inPathName, O_RDONLY);
    if(inFD<0)
    {
      MsgErrorF("Could not read %s\n", inPathName);
      CMD_RETURN(interp);
    }

    out = fopen(outPathName, "w");
    if(!out)
    {
      MsgErrorF("Could not write %s\n", outPathName);
      fclose(out);
      CMD_RETURN(interp);
    }
  }

  /* do the deed */
  gdsDump(inFD, out, verbose);

  close(inFD);
  fclose(out);

  /* return name of file written */
  Tcl_SetResult(interp, outPathName, TCL_VOLATILE);
  CMD_RETURN(interp);

usage:
    MsgErrorF("usage:  %s [-verbose] inFile [outFile]\n", 
	      cmdName);
    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * gdsTclCmdInfo --
 *
 * implements tcl command. 
 *
 * C Result:
 *	A standard Tcl result.
 *
 *--------------------------------------------------------------
 */

#define gds_info_DESC "summarize GDSII stream file contents"

#define gds_info_DOC "
Usage:  gds_info fileName

fileName extension defaults to '.gds' 

for each layer: 
  {layer_number type_number num_polygons num_wirepaths num_labels}

for each subcell:
  {def_name num_instances}

for each instance property:
  {property_number num_occurences}
"
static int
gdsTclCmdInfo(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
  char *cmdName;
  char *inArg = NULL;
  char inPathName[1000];
  int noExt = FALSE;
  int inFD;                  /* input file descriptor */

  CMD_BEGIN(interp);

  /* parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* Parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];
    
    /* no switchs yet */

    /* bad switch */
    goto usage;
  } /* end while(argc>0 && **argv=='-')  */

  /* parse inArg */
  if(argc==0) goto usage;
  inArg = *argv;
  argc--; argv++;

  /* should be no args left */
  if(argc != 0) goto usage;

  /* open input file */
  strcpy(inPathName,PaExtendedName(inArg,".gds"));
  inFD = open(inPathName, O_RDONLY);
  if(inFD<0)
  {
    MsgErrorF("Could not read %s\n", inPathName);
    CMD_RETURN(interp);
  }

  /* process file, adding statistics to tcl return value */
  gdsInfo(interp, inFD);

  close(inFD);
  CMD_RETURN(interp);

usage:
    MsgErrorF("usage:  %s fileName\n", 
	      cmdName);
    CMD_RETURN(interp);
}

/*
 *--------------------------------------------------------------
 *
 * gdsTclCmdRead --
 *
 * implements tcl command. 
 *
 * C Result:
 *	A standard Tcl result.
 *
 *--------------------------------------------------------------
 */

#define gds_read_DESC "read GDSII stream file"

#define gds_read_DOC "
Usage:  gds_read [-cells names] fileName

If \"-cells names\" option given, reads in only cells in names list.
(names is ',' separated list of cell names - no spaces allowed.)

NOTE:  A number of global variables beginning 'GDS_READ_' modify
the behavior of gds_read.  Consult the 'variables' documentation for
details.
"
static int
gdsTclCmdRead(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
  char *cmdName;
  char *fileName;
  char dir[BUFSIZ];
  int fd;
  CellDef *topDef;  /* set to top cell read in */
  char *cellNames = NULL;
  char *gdsSuffix = Tcl_GetVar2(interp,"CELL","gds_suffix",TCL_GLOBAL_ONLY); 


  CMD_BEGIN(interp);

  /* parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* Parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];
	
    if(c=='c' && strncmp(*argv,"-cells",length)==0)
    {
      argc--; argv++;

      if(argc==0) goto usage;
      cellNames = *argv;
      argc--; argv++;
      continue;
    }

    /* unrecognized option */
    goto usage;
	
  } /* end while(argc>0 && **argv=='-')  */

  /* parse fileName */
    if(argc==0) goto usage;
    fileName = *argv;
    argc--; argv++;

  /* should be no args left */
  if(argc != 0) goto usage;

  /* open file */
  {
    char *pathName;
    FILE *f;

    f = PaOpen(fileName, "r", gdsSuffix, MnPathCell, &pathName);
    if (f == (FILE *) NULL)
    {
      MsgErrorF("Cannot open %s to read GDS-II.\n", pathName);
      CMD_RETURN(interp);
    }
    fclose(f);

    fd = open(pathName, O_RDONLY);
    if(fd<0)
    {
      MsgErrorF("Cannot open %s to read GDS-II.\n", pathName);
      CMD_RETURN(interp);
    }

    /* stash gds file directory */
    PaSplitName(pathName,dir,NULL,NULL);
  }

  /* do the deed */
  topDef = gdsReadFile(fd, cellNames, dir);

  /* set result to name of top cell read in */
  if(topDef) Tcl_SetResult(interp, topDef->cd_name, TCL_VOLATILE);

  close(fd);
  CMD_RETURN(interp);

usage:
    MsgErrorF("usage:  %s [-cell name] file\n", 
	      cmdName);
    CMD_RETURN(interp);
}



/*
 * ----------------------------------------------------------------------------
 *
 * GDSTclInit --
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
GDSTclInit(Tcl_Interp *interp)
{
   MnDocCreateCommand(interp, "gds_compile", gdsTclCmdCompile,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       gds_compile_DESC,
	       gds_compile_DOC);

   MnDocCreateCommand(interp, "gds_dump", gdsTclCmdDump,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       gds_dump_DESC,
	       gds_dump_DOC);

   MnDocCreateCommand(interp, "gds_info", gdsTclCmdInfo,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       gds_info_DESC,
	       gds_info_DOC);

   MnDocCreateCommand(interp, "gds_read", gdsTclCmdRead,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       gds_read_DESC,
	       gds_read_DOC);

   MnDocLinkVar(interp, "GDS_READ_DEBUG", 
	       (char *) &gdsReadDebug, TCL_LINK_BOOLEAN,
		NULL,
		NULL);
   
   MnDocLinkVar(interp, "GDS_READ_SCALE_FACTOR", 
	       (char *) &gdsReadScaleFactor, TCL_LINK_DOUBLE,
		"scale factor to apply during read-in (normally 1.0)",
		NULL);

   MnDocLinkVar(interp, "GDS_READ_SNAP_TO_DESIGN_GRID", 
	       (char *) &gdsReadSnapToDesignGrid, TCL_LINK_BOOLEAN,
		"TO BE REMOVED!  DOES NOTHING see GDS_READ_SNAP_TO",
		NULL);

   MnDocLinkVar(interp, "GDS_READ_SNAP_TO", 
	       (char *) &gdsReadSnapTo, TCL_LINK_DOUBLE,
		"grid to snap (round) input to in microns",
		"(if 0, rounds to internal units)");

   MnDocLinkVar(interp, "GDS_READ_CELLNAME_TO_LOWER", 
	       (char *) &gdsReadCellnameToLower, TCL_LINK_BOOLEAN,
		"if set, map cellnames to lowercase",
		NULL);

   MnDocLinkVar(interp, "GDS_READ_CELLNAME_TO_UPPER", 
	       (char *) &gdsReadCellnameToUpper, TCL_LINK_BOOLEAN,
		"if set, map cellnames to lowercase",
		NULL);

   MnDocLinkVar(interp, "GDS_READ_UNMAPPED_LAYERS", 
	       (char *) &gdsReadUnmappedLayers, TCL_LINK_BOOLEAN,
	       "read in gds layers, even when not defined in current input style. N/Y/I\n",
	       NULL);
      
   MnDocLinkVar(interp, "GDS_READ_REPORT_ROUNDING_ERRORS", 
	       (char *) &gdsReadReportRoundingErrors, TCL_LINK_BOOLEAN,
		"If set, give warning if rounding errors occur.",
		NULL);

   MnDocLinkVar(interp, "GDS_READ_REPORT_DUPLICATE_INSTANCES", 
	       (char *) &gdsReadReportDuplicateInstances, TCL_LINK_BOOLEAN,
		"If set, gives warning when file contains duplicate identical instances",
		NULL);

   MnDocLinkVar(interp, "GDS_READ_REPORT_UNMAPPED_LAYERS", 
	       (char *) &gdsReadReportUnmappedLayers, TCL_LINK_BOOLEAN,
		"If set, give warning if input file contains unmapped layers.",
		NULL);

   MnDocLinkVar(interp, "GDS_READ_REPORT_MAX_WARNINGS", 
	       (char *) &gdsReadReportMaxWarnings, TCL_LINK_INT,
		"Maximum number of warnings to report, during GDS-II file read",
		NULL);

   MnDocLinkVar(interp, "GDS_READ_NO_DRC", 
	       (char *) &gdsReadNoDRC, TCL_LINK_BOOLEAN,
		"If set, the input is assumed to be DRC correct",
		"
If set, the input (including all subcell interactions)
is assumed DRC correct.  However subsequent edits will 
trigger design rule checking of the areas impacted by the edits.
"  
);

   MnDocLinkVar(interp, "GDS_READ_MESSAGE_INTERVAL", 
	       (char *) &gdsReadMessageInterval, TCL_LINK_INT,
		"Number of GDSII elements to read (in a def) between messages",
		NULL);
   
   MnDocLinkVar(interp, "GDS_WRITE_LIB_NAME", 
	       (char *) &gdsWriteLibName, TCL_LINK_STRING,
	       "libname to output when writing GDS",
	       "if null, defaults to the name of the toplevel cell written");
   MnTclSetLinkedString(&gdsWriteLibName,"");
   
   MnDocLinkVar(interp, "GDS_WRITE_SCALE_FACTOR", 
	       (char *) &gdsWriteScaleFactor, TCL_LINK_DOUBLE,
	       "scale by this factor on output N/Y/I",
	       NULL);

   MnDocLinkVar(interp, "GDS_WRITE_RESTRICT_CHARACTER_SET", 
	       (char *) &gdsWriteRestrictCharacterSet, TCL_LINK_BOOLEAN,
	       "if set, strings mapped to strict GDS character set on output. N/Y/I.",
	       NULL);

   MnDocLinkVar(interp, "GDS_WRITE_RESTRICT_CELL_NAME_LENGTH", 
	       (char *) &gdsWriteRestrictCellNameLength, TCL_LINK_BOOLEAN,
	       "N/Y/I",
	       NULL);

   MnDocLinkVar(interp, "GDS_WRITE_MIXED_CASE_LABELS", 
	       (char *) &GDSWriteMixedCaseLabels, TCL_LINK_BOOLEAN,
	       "if nil, labels mapped to all upper case.",
	       NULL);

   MnDocLinkVar(interp, "GDS_WRITE_LABELS", 
	       (char *) &GDSWriteLabels, TCL_LINK_BOOLEAN,
	       "if nil, labels are not written to GDS-II output.",
	       NULL);

   MnDocLinkVar(interp, "GDS_WRITE_ARRAYS", 
	       (char *) &GDSWriteArrays, TCL_LINK_BOOLEAN,
	       "if nil, arrays are written as (multiple) simple instances.\n",
	       NULL);

   MnDocLinkVar(interp, "GDS_WRITE_PROCESS_INTERACTIONS", 
	       (char *) &gdsWriteProcessInteractions, TCL_LINK_BOOLEAN,
	       "if true, special processing is done of cell interaction areas\n",
"
Attempts to make notch fill work between cells.
NOTE:  This slows GDSII writing down by TWO ORDERS OF MAGNITUDE!
");

   MnDocLinkVar(interp, "GDS_WRITE_FLATTEN_GCELLS", 
	       (char *) &GDSWriteFlattenGCells, TCL_LINK_BOOLEAN,
	       "if set gcell geometry is consolidated into parent cells",
	       "
If set, gcells are not written as defs and instances, but rather
directly as geometry in the parent cells.

NOTE:  It may be necessary to set this variable to get generated layers
(such as nplus and pplus) to turn out properly.
");

   MnDocLinkVar(interp, "GDS_WRITE_REPORT_ROUNDING_ERRORS", 
	       (char *) &gdsWriteReportRoundingErrors, TCL_LINK_BOOLEAN,
	       "N/Y/I",
	       NULL);

   MnDocLinkVar(interp, "GDS_WRITE_REPORT_EXTENDED_CHARACTER_SET", 
	       (char *) &gdsWriteReportExtendedCharacterSet, TCL_LINK_BOOLEAN,
	       "N/Y/I",
	       NULL);

   MnDocLinkVar(interp, "GDS_WRITE_REPORT_EXTENDED_CELL_NAME_LENGTH", 
	       (char *) &gdsWriteReportExtendedCellNameLength, TCL_LINK_BOOLEAN,
	       "N/Y/I",
	       NULL);


   MnDocLinkVar(interp, "GDS_MAP_SLASH_HACK", 
	       (char *) &gdsMapSlashHack, TCL_LINK_BOOLEAN,
		"map '/' in labels to '|' (TEMPORARY HACK)",
		"
If set, '/' in labels mapped to '|', on gds input.
Reverse map applied on gds output.

Warns if '|' present on gds input (since will get remapped on GDS output).
");
}







