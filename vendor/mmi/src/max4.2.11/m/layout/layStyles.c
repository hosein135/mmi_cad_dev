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
 *     ********************************************************************* 
 *     * Copyright (C) 1985, 1990 Regents of the University of California. * 
 *     * Permission to use, copy, modify, and distribute this              * 
 *     * software and its documentation for any purpose and without        * 
 *     * fee is hereby granted, provided that the above copyright          * 
 *     * notice appear in all copies.  The University of California        * 
 *     * makes no representations about the suitability of this            * 
 *     * software for any purpose.  It is provided "as is" without         * 
 *     * express or implied warranty.  Export of this software outside     * 
 *     * of the United States of America may require an export license.    * 
 *     *********************************************************************
 */

/* layStyles.c -
 *
 *      Layout redisplay is "vectored" through (Display) styles.
 *
 *	Styles are numbered and processed in increasing order during redisplay,
 *      so that later styles are "on top of" previous ones.
 *
 *      Each style is attached to one or more tile types and is drawn wherever
 *      those tiletypes are present.
 *
 *      A style specifies a colormap entry, which planes in the colormap to
 *      overwrite, possibly a stipple, and an outline type.
 *
 *      Styles are defined in <tech_name>.display_styles in the appropriate
 *      technology directory.
 *
 *      This file contains routines for:
 *           + reading in the .display_styles file,
 *           + processing the styles section of the tech file
 *           + C interface routines to styles database
 *           + tcl interface routines to styles database
 */

#include <stdio.h>
#include <ctype.h>
#include "magic.h"
#include "main.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "utils.h"
#include "signals.h"
#include "message.h"
#include "layout.h"
#include "layint.h"
#include "graphics.h"
#include "styles.h"

/* ---  exported data --- */
void *layStippleTable[MAX_STIPPLES];
void *layLinePatternTable[256];
DisplayStyle layDrawStyleTable[STYLE_TABLE_SIZE];
global StyleGroup *layStyleGroups = NULL;

global TileTypeBitMask	LayStyleToTypesTbl[MAXTILESTYLES];
global int layStyleFirstOpaque = MAXTILESTYLES; /* used in zoomed out redisplay */

/* --- data local to this file --- */

/* MUST be the same indices as the constants in graphics.h */
static char *fillStyles[] = {
	"solid",
	"cross",
	"outline",
	"stipple",
	NULL };
	
/* display style file section ids */
#define	SECTION_DISP_STYLES	0
#define	SECTION_STIPPLES	1

/*
 * ----------------------------------------------------------------------------
 * layStylesInit --
 *
 * Initialize styles datastructures (called at startup time)
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Clears the display module's technology dependent information.
 * ----------------------------------------------------------------------------
 */
void
layStylesInit(void)
{
    register i;

    for (i = 0; i < MAXTILESTYLES; i++) 
    {
      TTMaskZero(&LayStyleToTypesTbl[i]);
    }

    for(i=0; i<MAX_STIPPLES; i++) 
    {
      layStippleTable[i] = NULL; 
    }

    for(i=0; i<STYLE_TABLE_SIZE; i++) 
    {
      layDrawStyleTable[i].ds_fillStyle = FILL_STYLE_SOLID;
      layDrawStyleTable[i].ds_writeMask = 0;
      layDrawStyleTable[i].ds_color = 0;
      layDrawStyleTable[i].ds_outline = 0;
      layDrawStyleTable[i].ds_stipple = 0;
    }
}

/*
 * ----------------------------------------------------------------------------
 * eightBitString: 
 *
 *	convert num to newly malloced string of (8) '0's and '1's
 *      lsb first. 
 *
 *
 * ----------------------------------------------------------------------------
 */
static char *eightBitString(int num)
{
  int i;
  char *result;

  MALLOC(char *, result, 9);
  for(i=0; i<8; i++) result[i] = num&(1<<i) ? '1' : '0'; 
  result[8] = '\0';
  
  return result;
}

/*
 * ----------------------------------------------------------------------------
 * layCreateLinePattern
 *
 *	create line pattern.
 * ----------------------------------------------------------------------------
 */
static void
layCreateLinePattern(int byte)
{
  char *pattern;
  static initialed = FALSE;

  if(!initialed)
  {
    int i;
    for(i=0;i<256;i++) layLinePatternTable[i] = NULL;
    initialed = TRUE;
  }

  if(byte==0 || byte==255) return;
  if(layLinePatternTable[byte]) return;

  pattern = eightBitString(byte);
  layLinePatternTable[byte] = GrCreateLinePattern(pattern);
  FREE(pattern);
}

/*
 * ----------------------------------------------------------------------------
 * layStyleGroupAdd --
 *
 * Add a new style group.
 *
 *
 * Zoomed out paint redisplay is broken into multiple passes with style
 * groups being drawn in order.  The idea is that the order of painting
 * within a style group does not matter.  This is literally true for
 * groups with sg_orthogonal set:  these groups assign a different bit
 * to each "color" used so that they are order independent.  In non-orthogonal
 * groups all bits are set for each style so only the last one painted (within
 * the group) remains visible.
 *
 * ----------------------------------------------------------------------------
 */
static void 
layStyleGroupAdd(unsigned long selMask,    
		                /* style is in group iff 
				 * (selSet && (color&selMask)) ||
				 * (!selSet && !(color&selMask))
				 */
		 bool selSet,
		 void *stippleRev,
                                /* stipple pattern to use when 
				 * displaying this group 
				 * (reversed)
				 */
		 void *stippleDimRev,
                                /* stipple to use to dim non-edit cells.
				 *  (reversed)
				 */
		 bool orthogonal)
                                /* set if order of painting within gorup
				 * doesn't matter.
				 */
{
    StyleGroup *sG;
    StyleGroup **p;
    int style;
    int number = 1;
   
    MALLOC_TAG(StyleGroup *, sG, sizeof(StyleGroup),"StyleGroup");

    sG->sg_selMask = selMask;
    sG->sg_selSet = selSet;
    sG->sg_stippleRev = stippleRev;
    sG->sg_stippleDimRev = stippleDimRev;
    sG->sg_orthogonal = orthogonal;
    sG->sg_next = NULL;

    /* add to end of list */
    for(p = &layStyleGroups; (*p)!=NULL; p = &((*p)->sg_next))
    {
      number++;
    }  
    *p = sG;

    sG->sg_number = number;
}

/*
 * ----------------------------------------------------------------------------
 * layStyleGroupsClear --
 *
 * delete all style groups.
 *
 * ----------------------------------------------------------------------------
 */
static void 
layStyleGroupsClear(void)
{
  while(layStyleGroups)
  {
    StyleGroup *sg = layStyleGroups;
    
    layStyleGroups = sg->sg_next;

    if(sg->sg_stippleRev) GrFreeStipple(sg->sg_stippleRev);
    if(sg->sg_stippleDimRev) GrFreeStipple(sg->sg_stippleDimRev);
    FREE_TAG(sg,"StyleGroup");
  }
}

/*
 * ----------------------------------------------------------------------------
 *
 * layStyleGroupsOne --
 *
 * Setup redisplay for single style group
 *
 * NOTE: display styles should be setup before style groups.
 *
 * ----------------------------------------------------------------------------
 */
void layStyleGroupsOne(void)
{
  layStyleGroupsClear();

  /* transparent layers (active through m2) */
  {
    char *pattern[5];
    void *stippleDim;

    /* stipple for non-edit cell dimming */
    pattern[0] = "0101";
    pattern[1] = "1010";
    pattern[2] = "0101";
    pattern[3] = "1010";
    pattern[4] = NULL; 
    stippleDim = GrCreateStipple(pattern);  

    layStyleGroupAdd(0,                        /* sel mask (always selected) */
		     0,                        /* sel value */
		     NULL,                     /* no stipple for edit cell */
		     stippleDim,
		     FALSE);                   /* not orthogonal */
  }
}

/*
 * ----------------------------------------------------------------------------
 *
 * layStyleGroupsTwo --
 *
 * Setup redisplay for (default) two display style groups:
 * a transparent group and an opaque group.
 * 
 * NOTE: display styles should be setup before style groups.
 *
 * ----------------------------------------------------------------------------
 */

#define LAY_TRANSPARENT_PLANES 037

void layStyleGroupsTwo(void)
{
  unsigned long mask = 0340;  /* high order bits (above transparent) */ 
  layStyleGroupsClear();



  /* transparent layers (active through m2) */
  {
    char *pattern[5];
    void *stippleDim;

    /* stipple for non-edit cell dimming */
    pattern[0] = "0101";
    pattern[1] = "1010";
    pattern[2] = "0101";
    pattern[3] = "1010";
    pattern[4] = NULL; 
    stippleDim = GrCreateStipple(pattern);  

    layStyleGroupAdd(mask,
		     0,                        /* sel value */
		     NULL,                     /* no stipple for edit cell */
		     stippleDim,
		     TRUE);                    /* orthogonal styles */
  }

  /* opaque layers */
  {
    char *pattern[5];
    void *stipple;
    void *stippleDim;  /* used to dim nonedit cell */

    pattern[0] = "1010";
    pattern[1] = "0101";
    pattern[2] = "1010";
    pattern[3] = "0101";
    pattern[4] = NULL; 
    stipple = GrCreateStipple(pattern);  

    /* stipple opaque group so transparent layers show too */
    pattern[0] = "1110";
    pattern[1] = "1101";
    pattern[2] = "1011";
    pattern[3] = "0111";
    pattern[4] = NULL; 
    stippleDim = GrCreateStipple(pattern);  

    layStyleGroupAdd(mask,
		     1,
		     stipple,
		     stippleDim,
		     FALSE);                   /* non-orthogonal styles */ 
  }
}

/*
 *--------------------------------------------------------------
 *
 * layLayerStylesCmd --
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Tcl Result:

 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define lay_layer_styles_DESC "get/set styles for layer" 

#define lay_layer_styles_DOC "
 Usage:
	lay_layer_styles [-add | -clear] layer [style1 ...]

 Attaches layer to given styles.

 If -add, does not remove old style attachments for layer.
 If -clear, clear styles for given layer (default on set)

 Result:
        list of styles attached to layer (before this set)
"

int
layLayerStylesCmd(ClientData clientData, Tcl_Interp *interp, 
		     int argc, char **argv)
{

  char *cmdName;
  TileType layer;
  bool add = FALSE;
  bool clear = FALSE;
  bool changed = FALSE;
  
  CMD_BEGIN(interp);
    
  /* parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* Parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];

    if(c=='a' && strncmp(*argv, "-add", length)==0)
    {
      argc--; argv++;
      add = TRUE;
      continue;
    }

    if(c=='c' && strncmp(*argv, "-clear", length)==0)
    {
      argc--; argv++;
      clear = TRUE;
      continue;
    }

    /* unrecognized option */
    goto usage;
  } 

  /* get layer */
  if(argc<1) goto usage;
  layer = DBTechNameType(*argv);
  if (layer < 0)
  {
    MsgErrorF("Unknown layer: %s\n", *argv);
    CMD_RETURN(interp);
  }
  argc--; argv++;

  /* output styles currently attached to layer */
  {
    int style;
    for(style=0; style<MAXTILESTYLES; style++)
    {
      if(TTMaskHasType(&LayStyleToTypesTbl[style], layer))
      {
	char buf[100];
	sprintf(buf, "%d", style);
	Tcl_AppendElement(interp, buf);
      }
    }
  }

  /* clear all styles for layer */
  if(clear || (!add && argc>0))
  {
    int style;

    for(style=0; style<MAXTILESTYLES; style++)
    {
      TTMaskClearType(&LayStyleToTypesTbl[style], layer);
    }
    
    changed = TRUE;
  }

  /* do set */
  if(argc>0)
  {

    /* now do the sets */
    while(argc>0)
    {
      int style = atoi(*argv);
      argc--;argv++;

      if (style >= MAXTILESTYLES || style<0)
      {
	MsgErrorF("Invalid style %d\n", style);
	goto usage;
      }

      TTMaskSetType(&LayStyleToTypesTbl[style], layer);
      changed = TRUE;
    }
  }

  /* if we changed the styles, we need to redisplay everything */
  if(changed) LayChangedDisplay(NULL);
   
  CMD_RETURN(interp);

usage:
  MsgErrorF("Usage:  %s [-add | -clear] layer [style1 ...]\n",cmdName);
  CMD_RETURN(interp);
}

/*
 *--------------------------------------------------------------
 *
 * layStyleCmd --
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Tcl Result:

 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define lay_style_DESC "get/set display style" 

#define lay_style_DOC "
 Usage:
	lay_style [-dim] number|name [mask color outline fill stipple]

 Returns current settings for given style.
 If mask arg etc., sets style to those values. 

 The -dim option, specifies dim (non-edit cell) version of a style. 
 (-dim is not valid for named styles.)

 Numbers with leading 0 are octal.

 number     - integer (styles used for 'paint' are numbered).  They
              are drawn in ascending order.

 name       - named styles are:  
    annotation,
    background, 
    box,
    feedback_dotted, feedback_medium, feedback_outline, feedback_pale, 
      feedback_solid, 
    flyline, flyline_dim
    grid_coarse, grid_fine, grid_origin
    label, label_dim
    selection_outline, selection_stippled, selection_solid, 
    unexpanded_instance, unexpanded_instance_dim
    watched_tile

 mask       - integer between 0 and 0177 specifies bits to write to pixel.
            This field ignored in direct mode (GR_COLOR_MAPPED reset).

 color      - In colormapped mode (GR_COLOR_MAPPED set) gives index into
              colormap (integer between 0 and 0177) to write to pixel.  

              In direct mode (GR_COLOR_MAPPED reset) gives color value
              (obtained via gr_rgb_to_pixel) to write to pixel.

 outline    - integer between 0 and 0377 specifies outline pattern
              (e.g. 0 = no outline, 0377 = solid outline, 017 = dashed) 
              NOTE:  outlines of stipple styles are stippled, so
                     if you want oultines for solid or stippled regions,
                     need to use separate style with fillStyle set to 
                     `outline'

 fill       - solid   = solid fill + outline   
                        (uses writeMask/color/outline)
              stipple = stipple fill + outline 
                        (uses writeMask/color/stipple/outline)
              outline = outline only
                        (uses writeMask/color/outline)
              cross   = diagonal X             
                        (uses writeMask/color)
                        OBSOLETE - DO NOT USE 'cross'

 stipple - index of stipple pattern to use
           (stipple patterns are created with lay_stipple command).

 NOTE:  Display styles are displayed in numerical order.

 SEE ALSO: lay_layer_styles (for association between layers and styles)
"

/* table for parsing style names */
typedef struct stylenametable {
  char *snt_name;
  int    snt_num;
} StyleNameTable;

int
layStyleCmd(ClientData clientData, Tcl_Interp *interp, 
	     int argc, char **argv)
{

  char *cmdName;
  int style;
  int writeMask, color; 
  int outline,fillStyle,stipple;
  int nfill;

  bool dim = FALSE;

  static StyleNameTable nameTab[] = {
    { "annotation",          STYLE_ANNOTATION          },
    { "background",          STYLE_BACKGROUND          },
    { "box",                 STYLE_BOX                 },
    { "feedback_dotted",     STYLE_FEEDBACK_DOTTED     },
    { "feedback_medium",     STYLE_FEEDBACK_MEDIUM     },
    { "feedback_outline",    STYLE_FEEDBACK_OUTLINE    },
    { "feedback_pale",       STYLE_FEEDBACK_PALE       },
    { "feedback_solid",      STYLE_FEEDBACK_SOLID      },
    { "flyline",             STYLE_FLYLINE             },
    { "flyline_dim",         STYLE_FLYLINE_DIM         },
    { "grid_fine",           STYLE_GRID_FINE           },
    { "grid_coarse",         STYLE_GRID_COARSE         },
    { "grid_origin",         STYLE_GRID_ORIGIN         },
    { "label",               STYLE_LABEL               },
    { "label_dim",           STYLE_LABEL_DIM           },
    { "selection_outline",   STYLE_SELECTION_OUTLINE   },
    { "selection_solid",     STYLE_SELECTION_SOLID     },
    { "selection_stippled",  STYLE_SELECTION_STIPPLED  },
    { "unexpanded_instance", STYLE_UNEXPANDED_INSTANCE },
    { "unexpanded_instance_dim", STYLE_UNEXPANDED_INSTANCE_DIM },
    { "watched_tile",        STYLE_WATCHED_TILE        },
    { (char *) NULL,         -1 }};             
    
  CMD_BEGIN(interp);
    
  /* parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* Parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];
    
    if(c=='d' && strncmp(*argv,"-dim",length) == 0) 
    {
      dim = TRUE;
      argc--;
      argv++;
      continue;
    }

    /* unrecognized option */
    goto usage;
  } 

  /* parse style name/number */
  if(isdigit(**argv))
  {
    /* style number */
    if(sscanf(*argv,"%d", &style)!=1) goto usage;

    if (style < 0 || style >= MAXTILESTYLES)
    {
      MsgErrorF("style number %d is out of range (0 <= style < %d)\n", 
		style, 
		MAXTILESTYLES);
      CMD_RETURN(interp);
    }

    if(dim) style += MAXTILESTYLES;
  }
  else
  {
    /* style name */
    int n;

    if(dim)
    {
      MsgErrorF("-dim option invalid for named styles.\n");
      goto usage;
    }

    n = LookupStruct(*argv, (LookupTable *) nameTab, sizeof nameTab[0]);

    if (n < 0)
    {
      MsgErrorF("Unrecognized style name: '%s'\n",*argv);
      goto usage;
    }

    style = nameTab[n].snt_num;
  }
  argc--; argv++;

  /* output current settings for style */
  {
    char buf[BUFSIZ];

    /* mask color outline fill stipple */

    /* NOTE:  format must match gr_rgb_to_pixel color format, since
     * vaules are used in assoc array by tcl code.
     */
    sprintf(buf,"%#04o %#04o 0%#04o %s %d",
	    layDrawStyleTable[style].ds_writeMask,
	    layDrawStyleTable[style].ds_color,
	    layDrawStyleTable[style].ds_outline,
	    fillStyles[layDrawStyleTable[style].ds_fillStyle],
	    layDrawStyleTable[style].ds_stipple);

    Tcl_SetResult(interp, buf, TCL_VOLATILE);
  }

  /* if no more args, we're done */
  if(argc==0) CMD_RETURN(interp);

  /* parse write mask */
  if(GrColorMapped)
  {
    if(argc<1) goto usage;
    if(sscanf(*argv,"%i", &writeMask)!=1) goto usage;
    if (writeMask < 0 || writeMask > 0177)
    {
      MsgErrorF("writeMask 0%o is out of range (0 <= writeMask <= 0177)\n",
		writeMask);
      CMD_RETURN(interp);
    }
    argc--; argv++;
  }
  else
  {
    /* don't use mask in direct mode */ 
    writeMask = GrMaskColor;
    argc--; argv++;
  }

  /* parse color */
  {
    if(argc<1) goto usage;
    if(sscanf(*argv,"%i", &color)!=1) goto usage;

    if (GrColorMapped && (color < 0 || color > 0177))
    {
      MsgErrorF("color %d is out of range (0 <= color <= 0177)\n", 
		color);
      CMD_RETURN(interp);
    }
    argc--; argv++;
  }

  /* parse outline */
  if(argc<1) goto usage;
  if(sscanf(*argv,"%i", &outline)!=1) goto usage;

  if (outline < 0 || outline > 0377)
  {
    MsgErrorF("outline %d is out of range (0 <= outline <= 0377)\n", 
	      outline);
    CMD_RETURN(interp);
  }
  argc--; argv++;

  /* parse fillStyle */
  if(argc<1) goto usage;
  nfill = LookupFull(*argv, fillStyles);
  if(nfill<0)
  {
    MsgErrorF("bad fillStyle (%s)\n", 
	      *argv);
    CMD_RETURN(interp);
  }
  argc--; argv++;
  
  /* parse stipple */
  if(argc<1) goto usage;
  if(sscanf(*argv,"%i", &stipple)!=1) goto usage;
  if (stipple < 0 || stipple > MAX_STIPPLES)
  {
    MsgErrorF("stipple number %d is out of range (0 <= stipple <= %d)\n", 
	      stipple, 
	      MAX_STIPPLES);
    CMD_RETURN(interp);
  }
  argc--; argv++;

  /* should be no args left */
  if(argc != 0) goto usage;
  
  /* do the set */
  layDrawStyleTable[style].ds_writeMask = writeMask;
  layDrawStyleTable[style].ds_color = color;
  layDrawStyleTable[style].ds_outline = outline;
  layDrawStyleTable[style].ds_fillStyle = nfill;
  layDrawStyleTable[style].ds_stipple = stipple;

  /* need to redisplay everything */
  LayChangedDisplay(NULL);
   
  CMD_RETURN(interp);

usage:
  MsgErrorF("Usage:  "
	    "%s [-dim] number|name [mask color outline fill stipple]\n",
	    cmdName,
	    cmdName);

  CMD_RETURN(interp);
}

/*
 *--------------------------------------------------------------
 *
 * layStyleGroupsCmd --
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Tcl Result:

 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define lay_style_groups_DESC "select one or two display style groups" 

#define lay_style_groups_DOC "
 Usage:
	lay_style_groups [-one | -two] [-orthogonal]

 By default, redisplay is setup for display styles which are split between
 two groups: transparent and opaque (selected by 040 in the pixel values).  
 This command allows redisplay to be setup for a single group or the default
 two.  

 -orthogonal should be specified if and only if ORing together the pixel 
 values of overlapping styles in the first group gives the right result.
 Setting this flag (when appropriate) will allow more transparency during
 zoomed out redisplay.
"

int
layStyleGroupsCmd(ClientData clientData, Tcl_Interp *interp, 
	     int argc, char **argv)
{

  char *cmdName;
  bool one = FALSE;
  bool two = FALSE;
  bool orthogonal = FALSE;
  
  CMD_BEGIN(interp);
    
  /* parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* Parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];

    if(c=='o' && strncmp(*argv, "-one", MIN(length,3))==0)
    {
      argc--; argv++;
      one = TRUE;
      continue;
    }

    if(c=='o' && strncmp(*argv, "-orthogonal", MIN(length,3))==0)
    {
      argc--; argv++;
      orthogonal = TRUE;
      continue;
    }

    if(c=='t' && strncmp(*argv, "-two", length)==0)
    {
      argc--; argv++;
      two = TRUE;
      continue;
    }

    /* unrecognized option */
    goto usage;
  } 

  if(argc != 0) goto usage; 
  if(one && two) goto usage;

  if(one)
  {
    layStyleGroupsOne();
  }
  else if (two)
  {
    layStyleGroupsTwo();
  }
  layStyleGroups->sg_orthogonal = orthogonal;

  /* need to redisplay everything */
  LayChangedDisplay(NULL);
   
  CMD_RETURN(interp);

usage:
  MsgErrorF("Usage:  "
	    "%s [-one | -two] [-orthogonal]\n",
	    cmdName);

  CMD_RETURN(interp);
}

/*
 *--------------------------------------------------------------
 *
 * layStippleCmd --
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Tcl Result:

 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define lay_stipple_DESC "create stipple pattern" 

#define lay_stipple_DOC "
 Usage:
	lay_stipple stipple_number row1 [row2 ... rowN]

  Stipple number is the index of the stipple to create/replace
  Each row arg is string of 0's and 1's (e.g. 00001111)

  NOTE:  Display Style stipples are traditionally 8x8, not sure
         what the consequences of other sizes are.
"

static int 
layStippleCmd(ClientData clientData, Tcl_Interp *interp, int argc, char *argv[])
{
  char *cmdName;
  int stipple;
  
  CMD_BEGIN(interp);
    
  /* parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* stipple number */
  if(argc == 0) goto usage; 
  if(sscanf(*argv,"%i",&stipple) != 1) goto usage;
  if (stipple < 0 || stipple > MAX_STIPPLES)
  {
    MsgErrorF("stipple number %d is out of range (0 <= stipple <= %d)\n", 
	      stipple, 
	      MAX_STIPPLES);
    CMD_RETURN(interp);
  }
  argc--; argv++;

  if(argc == 0) goto usage;

  if(layStippleTable[stipple]) GrFreeStipple(layStippleTable[stipple]);
  layStippleTable[stipple] = GrCreateStipple(argv);

  /* need to redisplay everything */
  LayChangedDisplay(NULL);

  CMD_RETURN(interp);


usage:
  MsgErrorF("Usage:  "
	    "%s stipple_number row1 [row2 ... rowN]\n",
	    cmdName);

  CMD_RETURN(interp);

}

/*
 * ----------------------------------------------------------------------------
 *
 * layStylesTclInit --
 *
 * Register Tcl command interface to this file.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Registers commands with tcl.
 *	
 * ----------------------------------------------------------------------------
 */

void
layStylesTclInit(Tcl_Interp *interp)
{
   MnDocCreateCommand(interp, "lay_layer_styles", layLayerStylesCmd, 
	       (ClientData) NULL,  (Tcl_CmdDeleteProc *) NULL,
	       lay_layer_styles_DESC,
	       lay_layer_styles_DOC);
   MnDocCreateCommand(interp, "lay_stipple", layStippleCmd, 
	       (ClientData) NULL,  (Tcl_CmdDeleteProc *) NULL,
	       lay_stipple_DESC,
	       lay_stipple_DOC);
   MnDocCreateCommand(interp, "lay_style_groups", layStyleGroupsCmd, 
	       (ClientData) NULL,  (Tcl_CmdDeleteProc *) NULL,
	       lay_style_groups_DESC,
	       lay_style_groups_DOC);
   MnDocCreateCommand(interp, "lay_style", layStyleCmd, 
	       (ClientData) NULL,  (Tcl_CmdDeleteProc *) NULL,
	       lay_style_DESC,
	       lay_style_DOC);
}
