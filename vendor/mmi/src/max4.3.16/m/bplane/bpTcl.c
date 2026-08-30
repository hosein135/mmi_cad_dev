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
 * bpTcl.c -- Tcl command interface to this module
 */

static char rcsid[] = "$Header$";

#include <tcl.h>
#include <sys/types.h>
#include <stdlib.h>
#include "magic.h"
#include "main.h"
#include "message.h"
#include "database.h"
#include "units.h"
#include "bplane.h"
#include "bplaneInt.h"

#define BP_TCL_MAX_PLANES 1000
static int bpTclNumPlanes = 0;
static BPlane *bpTclPlanes[BP_TCL_MAX_PLANES];

/*
 *--------------------------------------------------------------
 *
 * bpTclCmdNewPlane --
 *
 * implements tcl command. 
 *
 * C Result:
 *	A standard Tcl result.
 *
 *--------------------------------------------------------------
 */

#define bp_new_plane_DESC "create new bplane"

#define bp_new_plane_DOC "
Usage:  bp_new_plane

Returns: id for newly created bplane.
"
static int
bpTclCmdNewPlane(ClientData clientData, 
		 Tcl_Interp *interp, 
		 int argc, 
		 char **argv)
{
  char *cmdName;

  CMD_BEGIN(interp);

  /* parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* Parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];

    /* NO SWITCHES YET
    if (c=='v' && strncmp(*argv,"-verbose",length)==0)
    {
      verbose=TRUE;
      argc--;
      argv++;
      continue;
    }
    */

     /* bad switch */
    goto usage;
  } /* end while(argc>0 && **argv=='-')  */

  /* no positional args yet */
  if(argc!=0) goto usage;

  /* too many planes ? */
  if(bpTclNumPlanes == BP_TCL_MAX_PLANES)
  {
    MsgErrorF("Alloc failed:  too many bplanes (%d)\n",bpTclNumPlanes+1);
    CMD_RETURN(interp);
  }

  /* do the deed */
  bpTclPlanes[bpTclNumPlanes] = BPNew();
  bpTclNumPlanes++;

  /* return plane id */
  {
    char buf[BUFSIZ];
    sprintf(buf,"bp%d",bpTclNumPlanes-1);
    Tcl_SetResult(interp, buf, TCL_VOLATILE);
  }
  CMD_RETURN(interp);

usage:
    MsgErrorF("usage:  %s\n", 
	      cmdName);
    CMD_RETURN(interp);
}

/*
 *--------------------------------------------------------------
 *
 * bpTclId2BPlane --
 *
 * lookup bplane id.
 *
 * Returns:  pointer to bplane (NULL if not found).
 *
 *--------------------------------------------------------------
 */
static BPlane *
bpTclId2BPlane(char *id)
{
  int index;
  char *end= NULL;

  /* strip "bp" header */
  if(*id != 'b') return NULL;
  id++;
  if(*id != 'p') return NULL;
  id++;

  /* convert */
  index = strtol(id,&end,10);

  /* error check */
  if(*end!='\0') return NULL;
  if(index<0 || index>bpTclNumPlanes-1) return NULL;

  return bpTclPlanes[index];
}

/*
 *--------------------------------------------------------------
 *
 * bpTclCmdAdd --
 *
 * implements tcl command. 
 *
 * C Result:
 *	A standard Tcl result.
 *
 *--------------------------------------------------------------
 */

#define bp_add_DESC "add rect to bplane"

#define bp_add_DOC " 
Usage:  bp_add bplane_id [-text id] xbot ybot xtop ytop
"
static int
bpTclCmdAdd(ClientData clientData, 
	    Tcl_Interp *interp, 
	    int argc, 
	    char **argv)
{
  char *cmdName;
  char *planeId;
  char *text = "";
  Rect r;

  BPlane *bp; 

  CMD_BEGIN(interp);

  /* parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* Parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];

    if (c=='t' && strncmp(*argv,"-text",length)==0)
    {
      argc--;
      argv++;
      if(!argc) goto usage;
      text = StrDup(NULL,*argv);
      argc--;
      argv++;

      continue;
    }

     /* bad switch */
    goto usage;
  } /* end while(argc>0 && **argv=='-')  */

  /* get plane id */
  if(argc == 0) goto usage;
  planeId = *argv;
  argc--; argv++;
 
  /* get coords */
  if(argc == 0) goto usage;
  r.r_ll.p_x = UnitsS2I(*argv);
  argc--; argv++;

  if(argc == 0) goto usage;
  r.r_ll.p_y = UnitsS2I(*argv);
  argc--; argv++;

  if(argc == 0) goto usage;
  r.r_ur.p_x = UnitsS2I(*argv);
  argc--; argv++;

  if(argc == 0) goto usage;
  r.r_ur.p_y = UnitsS2I(*argv);
  argc--; argv++;

  /* no other args recognized */
  if(argc != 0) goto usage;

  /* look up plane */
  bp = bpTclId2BPlane(planeId);
  if(!bp)
  {
    MsgErrorF("bp_add:  Unrecognized BPlane id (%s)\n", 
	      planeId);
    CMD_RETURN(interp);
  }

  /* do it */
  {
    LabeledElement *le;

    MALLOC_TAG(LabeledElement *, 
	       le, 
	       sizeof(LabeledElement), 
	       "LabeledElement");
    le->le_rect = r;
    le->le_text = text;
    BPAdd(bp, le);
  }
  CMD_RETURN(interp);

usage:
    MsgErrorF("usage:  %s [-text id] bplane_id xbot ybot xtop ytop\n", 
	      cmdName);
    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * bpTclCmdDelete --
 *
 * implements tcl command. 
 *
 * C Result:
 *	A standard Tcl result.
 *
 *--------------------------------------------------------------
 */

#define bp_delete_DESC "delete rect from bplane"

#define bp_delete_DOC " 
Usage:  bp_delete bplane_id xbot ybot xtop ytop

Delete first rect found with matching coordinates.
"
static int
bpTclCmdDelete(ClientData clientData, 
	    Tcl_Interp *interp, 
	    int argc, 
	    char **argv)
{
  char *cmdName;
  char *planeId;
  Rect r;

  BPlane *bp; 

  CMD_BEGIN(interp);

  /* parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* Parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];

    /* NO SWITCHES YET
    if (c=='v' && strncmp(*argv,"-verbose",length)==0)
    {
      verbose=TRUE;
      argc--;
      argv++;
      continue;
    }
    */

     /* bad switch */
    goto usage;
  } /* end while(argc>0 && **argv=='-')  */

  /* get plane id */
  if(argc == 0) goto usage;
  planeId = *argv;
  argc--; argv++;
 
  /* get coords */
  if(argc == 0) goto usage;
  r.r_ll.p_x = UnitsS2I(*argv);
  argc--; argv++;

  if(argc == 0) goto usage;
  r.r_ll.p_y = UnitsS2I(*argv);
  argc--; argv++;

  if(argc == 0) goto usage;
  r.r_ur.p_x = UnitsS2I(*argv);
  argc--; argv++;

  if(argc == 0) goto usage;
  r.r_ur.p_y = UnitsS2I(*argv);
  argc--; argv++;

  /* no other args recognized */
  if(argc != 0) goto usage;

  /* look up plane */
  bp = bpTclId2BPlane(planeId);
  if(!bp)
  {
    MsgErrorF("%s:  Unrecognized BPlane id (%s)\n", 
	      cmdName,
	      planeId);
    CMD_RETURN(interp);
  }

  /* do it */
  {
    BPEnum bpe;
    LabeledElement *le;

    BPEnumInit(&bpe, bp, &r, BPE_EQUAL, "bp_delete"); 
    if(le = BPEnumNext(&bpe)) BPDelete(bp,le);
    BPEnumTerm(&bpe);
  }
  CMD_RETURN(interp);

usage:
    MsgErrorF("usage:  %s bplane_id xbot ybot xtop ytop\n", 
	      cmdName);
    CMD_RETURN(interp);
}

/*
 *--------------------------------------------------------------
 *
 * bpTclCmdSearch --
 *
 * implements tcl command. 
 *
 * C Result:
 *	A standard Tcl result.
 *
 *--------------------------------------------------------------
 */

#define bp_search_DESC "search area of bplane"

#define bp_search_DOC " 
Usage:  bp_search [-all | -equal | -touch | -overlap] [-cell] [-silent] name xbot ybot xtop ytop

 If -silent, no results returned. (Useful for timing search.) 
 If -cell, use cellplane for cell name (else name is bplane id).
"
static int
bpTclCmdSearch(ClientData clientData, 
	       Tcl_Interp *interp, 
	       int argc, 
	       char **argv)
{
  char *cmdName;
  char *planeId;
  Rect r;
  int match = BPE_TOUCH;
  bool silent = FALSE;
  bool cell = FALSE;
  BPlane *bp; 


  CMD_BEGIN(interp);

  /* parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* Parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];

    if (c=='a' && strncmp(*argv,"-all",length)==0)
    {
      match = BPE_ALL;
      argc--;
      argv++;
      continue;
    }

    if (c=='c' && strncmp(*argv,"-cell",length)==0)
    {
      cell = TRUE;
      argc--;
      argv++;
      continue;
    }

    if (c=='e' && strncmp(*argv,"-equal",length)==0)
    {
      match = BPE_EQUAL;
      argc--;
      argv++;
      continue;
    }

    if (c=='o' && strncmp(*argv,"-overlap",length)==0)
    {
      match = BPE_OVERLAP;
      argc--;
      argv++;
      continue;
    }

    if (c=='s' && strncmp(*argv,"-silent",length)==0)
    {
      silent = TRUE;
      argc--;
      argv++;
      continue;
    }

    if (c=='t' && strncmp(*argv,"-touch",length)==0)
    {
      match = BPE_TOUCH;
      argc--;
      argv++;
      continue;
    }


     /* bad switch */
    goto usage;
  } /* end while(argc>0 && **argv=='-')  */

  /* get plane id */
  if(argc == 0) goto usage;
  planeId = *argv;
  argc--; argv++;
 
  /* get coords */
  if(argc == 0) goto usage;
  r.r_ll.p_x = UnitsS2I(*argv);
  argc--; argv++;

  if(argc == 0) goto usage;
  r.r_ll.p_y = UnitsS2I(*argv);
  argc--; argv++;

  if(argc == 0) goto usage;
  r.r_ur.p_x = UnitsS2I(*argv);
  argc--; argv++;

  if(argc == 0) goto usage;
  r.r_ur.p_y = UnitsS2I(*argv);
  argc--; argv++;

  /* no other args recognized */
  if(argc != 0) goto usage;

  /* look up plane */
  if(!cell)
  {  
    bp = bpTclId2BPlane(planeId);
    if(!bp)
    {
      MsgErrorF("%s:  Unrecognized BPlane id (%s)\n", 
		cmdName,
		planeId);
      CMD_RETURN(interp);
    }
  }
  else
  {
    CellDef *def = DBCellLookDef(planeId);
    if(!def)
    {
      MsgErrorF("%s:  Couldn't find cell '%s'!\n",
		cmdName, *argv);
      CMD_RETURN(interp);
    }
    bp = def->cd_cellPlane;
  }
  ASSERT(bp,"bp_search");

  /* do it */
  {
    LabeledElement *le;
    BPEnum bpe;
    int i;

    BPEnumInit(&bpe,bp,&r,match,"bp_search");
    while(le=BPEnumNext(&bpe))
    {
      char buf[BUFSIZ];

      i++;  /* keep this loop from being optimized away! */

      if(silent) continue;

      Tcl_AppendResult(interp,"{", le->le_text, " ", NULL);
      Tcl_AppendResult(interp,UnitsI2S(le->le_rect.r_xbot), " ", NULL);
      Tcl_AppendResult(interp,UnitsI2S(le->le_rect.r_ybot), " ", NULL);
      Tcl_AppendResult(interp,UnitsI2S(le->le_rect.r_xtop), " ", NULL);
      Tcl_AppendResult(interp,UnitsI2S(le->le_rect.r_ytop), NULL);
      Tcl_AppendResult(interp,"} ", NULL);
    }
    BPEnumTerm(&bpe);
  }

  CMD_RETURN(interp);

usage:
    MsgErrorF("usage:  %s bplane_id xbot ybot xtop ytop\n", 
	      cmdName);
    CMD_RETURN(interp);
}



/*
 *--------------------------------------------------------------
 *
 * bpTclCmdTest --
 *
 * implements tcl command. 
 *
 * C Result:
 *	A standard Tcl result.
 *
 *--------------------------------------------------------------
 */

#define bp_test_DESC "test bplane code "

#define bp_test_DOC " 
varys from moment to moment at mha's whim.
"
static int
bpTclCmdTest(ClientData clientData, 
	       Tcl_Interp *interp, 
	       int argc, 
	       char **argv)
{
  char *cmdName;
  char *planeId;
  bool gold = FALSE;
  bool reset = FALSE;
  bool tile = FALSE;
  bool trace = FALSE;
  RectFloat rf;
  BPlane *bp; 
  int size;

  CMD_BEGIN(interp);

  /* parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* Parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];

    if (c=='g' && strncmp(*argv,"-gold",length)==0)
    {
      gold=TRUE;
      argc--;
      argv++;
      continue;
    }

    if (c=='r' && strncmp(*argv,"-reset",length)==0)
    {
      reset=TRUE;
      argc--;
      argv++;
      continue;
    }

    if (c=='t' && strncmp(*argv,"-tile",length)==0)
    {
      tile=TRUE;
      argc--;
      argv++;
      continue;
    }

    if (c=='t' && strncmp(*argv,"-trace",length)==0)
    {
      trace=TRUE;
      argc--;
      argv++;
      continue;
    }

     /* bad switch */
    goto usage;
  } /* end while(argc>0 && **argv=='-')  */

  if(reset)
  {
    /* reset random number generator 
     * (so identical sequence repeated)
     */
    srand(1);
    goto done;
  }

  /* size */
  if(argc == 0) goto usage;
  size = atoi(*argv);
  argc--; argv++;

  /* no other args recognized */
  if(argc != 0) goto usage;

  /* do it */
  {
    if(gold)
    {
      bpTestSnowGold(size,trace);
    }
    else if (tile)
    {
      bpTestSnowTile(size,trace); 
      /* TODO reclaim plane */
    }
    else
    {
      bpTestSnow(size,trace); 
      /* TODO free bplane */
    }
  }

done:
  CMD_RETURN(interp);

usage:
    MsgErrorF("usage:  %s [-gold] [-reset] [-tile] [-trace] size\n", 
	      cmdName);
    CMD_RETURN(interp);
}


/* 
 * EXAMPLE FROM bplane.h comments.
 *
 * Here is a procedure that takes an array of id'ed rectangles and an
 * area as input, and prints the ids of all rectangles impinging on the
 * area.
 */

typedef struct rid
{
  struct rid *rid_bpLink;
  Rect rid_rect;           
  char *rid_id;
} RId;

void bpFindRects(RId data[], int n, Rect *area) 
{
  int i;
  BPEnum bpe;
  BPlane *bp;
  RId *rid; 
  
  bp = BPNew();
  for(i=0;i<n;i++) BPAdd(bp,&data[i]);
  BPEnumInit(&bpe,bp,area,BPE_OVERLAP,"findRects");
  while(rid = BPEnumNext(&bpe))
  {
    printf("%s\n", rid->rid_id);
  }
  BPEnumTerm(&bpe);
}

/*
 *--------------------------------------------------------------
 *
 * bpTclCmdTest2 --
 *
 * implements tcl command. 
 *
 * C Result:
 *	A standard Tcl result.
 *
 *--------------------------------------------------------------
 */

#define bp_test2_DESC "test bplane code "

#define bp_test2_DOC " 
varys from moment to moment at mha's whim.
"
 
static int
bpTclCmdTest2(ClientData clientData, 
	       Tcl_Interp *interp, 
	       int argc, 
	       char **argv)
{
  char *cmdName;

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

  {
    int i;
    BPEnum bpe;
    BPEnum bpe2;
    BPlane *bp;
    Element *e;
    Element *e2;
    Rect area;

    /* gen an element */
    MALLOC_TAG(Element *, e, sizeof(Element), "Element");
    e->e_rect.r_xbot =  1;
    e->e_rect.r_xtop =  2;
    e->e_rect.r_ybot =  3;
    e->e_rect.r_ytop =  4;

    MALLOC_TAG(Element *, e2, sizeof(Element), "Element");
    e2->e_rect.r_xbot =  12;
    e2->e_rect.r_xtop =  22;
    e2->e_rect.r_ybot =  32;
    e2->e_rect.r_ytop =  42;

    /* search area */
    area.r_xbot = 0;
    area.r_ybot = 0;
    area.r_xtop = 1000;
    area.r_ytop = 1000;

    bp = BPNew();

    fprintf(stderr,"DEBUG a\n"); bpDump(bp,0);
    BPAdd(bp, e);
    fprintf(stderr,"DEBUG b\n"); bpDump(bp,0);
    BPEnumInit(&bpe,bp,&area,BPE_OVERLAP,"findRects");
    fprintf(stderr,"DEBUG c\n"); bpDump(bp,0);
    BPEnumInit(&bpe2,bp,&area,BPE_OVERLAP,"nested");
    fprintf(stderr,"DEBUG d\n"); bpDump(bp,0);
    BPEnumTerm(&bpe);
    BPAdd(bp, e2);
    fprintf(stderr,"DEBUG e\n"); bpDump(bp,0);
    BPEnumTerm(&bpe2);
    fprintf(stderr,"DEBUG f\n"); bpDump(bp,0);
  }

done:
  CMD_RETURN(interp);

usage:
    MsgErrorF("usage:  %s ?\n", 
	      cmdName);
    CMD_RETURN(interp);
  }

/*
 *--------------------------------------------------------------
 *
 * bpTclCmdDump --
 *
 * implements tcl command. 
 *
 * C Result:
 *	A standard Tcl result.
 *
 *--------------------------------------------------------------
 */

#define bp_dump_DESC "print bplane internals"

#define bp_dump_DOC " 
usage: bp_dump bplane_id
"
static int
bpTclCmdDump(ClientData clientData, 
	       Tcl_Interp *interp, 
	       int argc, 
	       char **argv)
{
  char *cmdName;
  char *planeId;
  RectFloat rf;

  BPlane *bp; 

  CMD_BEGIN(interp);

  /* parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* Parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];

    /* NO SWITCHES YET
    if (c=='v' && strncmp(*argv,"-verbose",length)==0)
    {
      verbose=TRUE;
      argc--;
      argv++;
      continue;
    }
    */

     /* bad switch */
    goto usage;
  } /* end while(argc>0 && **argv=='-')  */

  /* get plane id */
  if(argc == 0) goto usage;
  planeId = *argv;
  argc--; argv++;

  /* look up plane */
  bp = bpTclId2BPlane(planeId);
  if(!bp)
  {
    MsgErrorF("bp_dump:  Unrecognized BPlane id (%s)\n", 
	      planeId);
    CMD_RETURN(interp);
  }

  /* dump it */
  bpDump(bp,BPD_LABELED);

  CMD_RETURN(interp);

usage:
    MsgErrorF("usage:  %s bplane_id\n", 
	      cmdName);
    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * bpTclCmdStat --
 *
 * implements tcl command. 
 *
 * C Result:
 *	A standard Tcl result.
 *
 *--------------------------------------------------------------
 */

#define bp_stat_DESC "print statistics on bplane"

#define bp_stat_DOC " 
usage: bp_stat bplane_id
"
static int
bpTclCmdStat(ClientData clientData, 
	       Tcl_Interp *interp, 
	       int argc, 
	       char **argv)
{
  char *cmdName;
  char *planeId;
  RectFloat rf;

  BPlane *bp; 

  CMD_BEGIN(interp);

  /* parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* Parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];

    /* NO SWITCHES YET
    if (c=='v' && strncmp(*argv,"-verbose",length)==0)
    {
      verbose=TRUE;
      argc--;
      argv++;
      continue;
    }
    */

     /* bad switch */
    goto usage;
  } /* end while(argc>0 && **argv=='-')  */

  /* get plane id */
  if(argc == 0) goto usage;
  planeId = *argv;
  argc--; argv++;

  /* look up plane */
  bp = bpTclId2BPlane(planeId);
  if(!bp)
  {
    MsgErrorF("bp_dump:  Unrecognized BPlane id (%s)\n", 
	      planeId);
    CMD_RETURN(interp);
  }

  /* get stats */
  {
    unsigned int mem;
    int count;           /* ret num of elements in bplane */
    int inBox;           /* ret num of elements in inBox */
    int totBins;
    int emptyBins;       /* ret number of empty bins */
    int binArrays;       /* ret number of bin arrays */
    int maxEff;
    int maxBinCount;     /* ret max count for regular bin */
    int totUnbinned;    
    int maxDepth;
    
    mem = BPStat(bp,
		 &count,
		 &inBox,
		 &totBins,
		 &emptyBins,
		 &binArrays,
		 &maxEff,
		 &maxBinCount, 
		 &totUnbinned,
		 &maxDepth);

    /* set result */
    {
      char buf[BUFSIZ];
      sprintf(buf,
	      "{memory %d} "
	      "{numElements %d} "
	      "{inBox %d} "
	      "{numBins %d} "
	      "{emptyBins %d} "
	      "{binArrays %d} "
	      "{maxEffective %d} " 
	      "{maxBinCount %d} "
	      "{unbinned %d} "
	      "{maxDepth %d} "
	      "\n",
	      mem, count, inBox, totBins, emptyBins, binArrays,
	      maxEff, maxBinCount, totUnbinned, maxDepth);

      Tcl_SetResult(interp, buf, TCL_VOLATILE);                    
    }
  }

  CMD_RETURN(interp);


usage:
  MsgErrorF("usage:  %s bplane_id\n", 
	      cmdName);
  CMD_RETURN(interp);
}


/*
 * ----------------------------------------------------------------------------
 *
 * BPTclInit --
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
BPTclInit(Tcl_Interp *interp)
{
   MnDocCreateCommand(interp, "bp_new_plane", bpTclCmdNewPlane,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       bp_new_plane_DESC,
	       bp_new_plane_DOC);

   MnDocCreateCommand(interp, "bp_add", bpTclCmdAdd,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       bp_add_DESC,
	       bp_add_DOC);

   MnDocCreateCommand(interp, "bp_delete", bpTclCmdDelete,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       bp_delete_DESC,
	       bp_delete_DOC);

   MnDocCreateCommand(interp, "bp_search", bpTclCmdSearch,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       bp_search_DESC,
	       bp_search_DOC);

   MnDocCreateCommand(interp, "bp_test", bpTclCmdTest,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       bp_test_DESC,
	       bp_test_DOC);

   MnDocCreateCommand(interp, "bp_test2", bpTclCmdTest2,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       bp_test2_DESC,
	       bp_test2_DOC);

   MnDocCreateCommand(interp, "bp_dump", bpTclCmdDump,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       bp_dump_DESC,
	       bp_dump_DOC);

   MnDocCreateCommand(interp, "bp_stat", bpTclCmdStat,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       bp_stat_DESC,
	       bp_stat_DOC);

   MnDocLinkVar(interp, "BP_MIN_BA_POP",
		(char *) &bpMinBAPop, TCL_LINK_INT,
		"min number of elements to be (sub) binned",
		"controls bin-array push overhead for large-area searches");

   MnDocLinkVar(interp, "BP_MIN_AVG_BIN_POP",  
		(char *) &bpMinAvgBinPop, TCL_LINK_DOUBLE,
		"minimum average bin population",
		"controls memory overhead due to too many bins");
}
