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
 * DBlabel.c --
 *
 * Label manipulation primitives.
 *
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

#include <sys/types.h>
#include <stdio.h>
#include <string.h>
#include "magic.h"
#include "database.h"
#include "databaseInt.h"
#include "malloc.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "databaseInt.h"
#include "layout.h"
#include "layout.h"
#include "commands.h"
#include "message.h"
#include "utils.h"

/* largest label encountered */
int DBLabelMaxDim = 0;

/*
 * ----------------------------------------------------------------------------
 *
 * DBLabelKindName --
 *
 *
 * Results:
 *	Name string for label kind
 *
 * ----------------------------------------------------------------------------
 */
char *
DBLabelKindName(int kind)
{
  
    switch(kind)
    {
        case LAB_COMMENT: return("comment");
        case LAB_HIDDEN:  return("hidden");
        case LAB_LOCAL:   return("local");
        case LAB_GLOBAL:  return("global");
        case LAB_INPUT:      return("input");
        case LAB_OUTPUT:     return("output");
        case LAB_INOUT:  return("inout");
        default: ASSERT(FALSE,"DBLabelKindName");
    }
    return "never-happens";
}

/*
 * ----------------------------------------------------------------------------
 *
 * DBLabelTypedText --
 *
 *  Put label text, with prepended label kind id in nameBuf
 *
 * ----------------------------------------------------------------------------
 */
void
DBLabelTypedText(char *text, int kind, char *nameBuf, int bufSize)
{
    int spaceLeft = bufSize;

    switch(kind)
    {
        case LAB_COMMENT: strcpy(nameBuf,"# " ); spaceLeft -=2; break;
        case LAB_HIDDEN:  strcpy(nameBuf,"H "); spaceLeft -=2; break;
        case LAB_LOCAL:   strcpy(nameBuf,""); break;
        case LAB_GLOBAL:  strcpy(nameBuf,"! "); spaceLeft -=2; break;
        case LAB_INPUT:   strcpy(nameBuf,"< "); spaceLeft -=2; break;
        case LAB_OUTPUT:  strcpy(nameBuf,"> "); spaceLeft -=2; break;
        case LAB_INOUT:   strcpy(nameBuf,"<> "); spaceLeft -=3; break;
        defalut: ASSERT(FALSE,"DBLabelKindName");
    }

    (void) strncat(nameBuf,text,spaceLeft-1);
}

/*
 * ----------------------------------------------------------------------------
 *
 * DBLabelKindParse --
 *
 * convert kind name string to integer code.
 *
 * Results:
 *   Label kind, -1 on error.
 *
 * ----------------------------------------------------------------------------
 */
int
DBLabelKindParse(char *name)
{
  char c=name[0];
  int length = strlen(name);

  switch(c)
    {
        case 'c': 
            if(strncmp("comment",name,length)==0) return LAB_COMMENT;
            goto bad;

        case 'h': 
	    if(strncmp("hidden",name,length)==0) return LAB_HIDDEN;
	    goto bad;
	    
        case 'l': 
	    if(strncmp("local",name,length)==0) return LAB_LOCAL;
	    goto bad;

        case 'g': 
	    if(strncmp("global",name,length)==0) return LAB_GLOBAL;
	    goto bad;
	    
        case 'o': 
	    if(strncmp("output",name,length)==0) return LAB_OUTPUT;
	    goto bad;

        case 'i': 
           if(strncmp("input",name,MAX(3,length))==0) return(LAB_INPUT);
           if(strncmp("inout",name,MAX(3,length))==0) return(LAB_INOUT);
           goto bad;

        default: goto bad;
    }

bad:
  MsgErrorF("Bad label kind: %s\n"
	    "Valid label kinds: comment, hidden, local, global, input, output, inout\n",
	    name);
  return -1;
  
}

/* The following variable(s) are shared between dbPickLabelLayer and
 * its search functions (dbPickFunc1 and dbPickFunc2)
 */

static TileTypeBitMask *dbAdjustPlaneTypes;	/* Mask of all types in current
	       				         * plane being searched.
					         */
static Group *dbLabelGroup;

/* Search function for DBPickLabelLayer:  just OR in the type of
 * any tiles (except space) to the mask passed as clientdata.
 * Always return 0 to keep the search alive.
 */

static int
dbPickFunc1(Tile *tile, TileTypeBitMask *mask)
               			/* Tile found. */
                          	/* Mask to be modified. */
{
    TileType type = DBgetTypeG(tile,dbLabelGroup);
    if (type == TT_SPACE) return 0;
    TTMaskSetType(mask, type);
    return 0;
}

/* Another search function for DBPickLabelLayer.  For the first element
 * in the mask array, AND off all types on the current plane except the
 * given type.  For the second element, AND off all types on the current
 * plane except the ones that are components of this tile's type.  For
 * the third element of the array, just OR in the type of the current
 * tile.  A space tile ruins the whole plane so return 1 to abort the
 * search.  Otherwise return 0.
 */

static int
dbPickFunc2(Tile *tile, TileTypeBitMask *mask)
               			/* Tile found. */
                          	/* Mask to be modified. */
{
    TileType type = DBgetTypeG(tile,dbLabelGroup);
    TileTypeBitMask tmp;

    if (type == TT_SPACE)
    {
	/* Space means can't have any tile types on this plane. */

	TTMaskClearMask(&mask[0], dbAdjustPlaneTypes);
	TTMaskClearMask(&mask[1], dbAdjustPlaneTypes);
	return 1;
    }

    tmp = *dbAdjustPlaneTypes;
    TTMaskClearType(&tmp, type);
    TTMaskClearMask(&mask[0], &tmp);
    TTMaskClearMask(&tmp, &DBComponentTbl[type]);
    TTMaskClearMask(&mask[1], &tmp);
    TTMaskSetType(&mask[2], type);
    return 0;
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbPickLabelLayer --
 *
 * 	This procedure looks at the material around a label and
 *	picks a new layer for the label to be attached to.
 *      
 *       NOTE: now only used by DBLabelAddG() to choose initial layer
 *             for label when type not specified.  
 *             The type is initialized to TT_SPACE before this
 *             routine is called.
 *
 * Results:
 *	Returns a tile type, which is a layer that completely
 *	covers the label's area.  The layer chosen,
 *      in order of preference is:
 *             1.  the labels current layer
 *             2.  a layer connecting to the labels current layer
 *             3.  any visible layer
 *             4.  space
 *
 * Side effects:
 *	None.  The label's layer is not changed by this procedure.
 *
 * ----------------------------------------------------------------------------
 */

static TileType
dbPickLabelLayer(CellDef *def, 
                 		/* Cell definition containing label. */
		 Label *lab)
               			/* Label for which a home must be found. */
{
    TileTypeBitMask types[3], types2[3];
    TileTypeBitMask *visibleTypes;
    Rect check1, check2;
    int i, plane;
    TileType choice1, choice2, choice3, choice4, choice5, choice6;
    TileType choice1v, choice2v, choice3v, choice4v, choice5v, choice6v;
    extern int dbPickFunc1(Tile *tile, TileTypeBitMask *mask), dbPickFunc2(Tile *tile, TileTypeBitMask *mask);

    /* Compute an array of three tile type masks:
       [0] all of the types that are present everywhere underneath the label. 
       [1] all types that are components of tiles that completely cover the label.
       [2] is for tile types that touch the label anywhere.
     */

    dbLabelGroup = lab->lab_group;

    if ((lab->lab_rect.r_xbot == lab->lab_rect.r_xtop)
	    && (lab->lab_rect.r_ybot == lab->lab_rect.r_ytop))
    {
	/* Point label.  Find out what layers touch the label and
	 * use this for all three masks.
	 */

	GEO_EXPAND(&lab->lab_rect, 1, &check1);
	types[0] = DBZeroTypeBits;
	for (i = PL_SELECTBASE; i < DBNumPlanes; i += 1)
	{
	    (void) DBPlaneEnumAreaPaint((Tile *) NULL, def->cd_planes[i],
		    &check1, &DBAllTypeBits, dbPickFunc1,
		    (ClientData) &types[0]);
	}
	types[1] = types[0];
	types[2] = types[0];
    }
    else if (lab->lab_rect.r_xbot == lab->lab_rect.r_xtop)
    {
	/* Vertical line label.  Search two areas, one on the
	 * left and one on the right.  For each side, compute
	 * the type arrays separately.  Then merge them together.
	 */
	
	check1 = lab->lab_rect;
	check2 = lab->lab_rect;
	check1.r_xbot -= 1;
	check2.r_xtop += 1;

	twoAreas:
	types[0] = DBAllButSpaceAndDRCBits;
	types[1] = DBAllButSpaceAndDRCBits;
	TTMaskZero(&types[2]);
	types2[0] = DBAllButSpaceAndDRCBits;
	types2[1] = DBAllButSpaceAndDRCBits;
	TTMaskZero(&types2[2]);
	for (i = PL_SELECTBASE; i < DBNumPlanes; i += 1)
	{
	    dbAdjustPlaneTypes = &DBPlaneTypes[i];
	    (void) DBPlaneEnumAreaPaint((Tile *) NULL, def->cd_planes[i],
		    &check1, &DBAllTypeBits, dbPickFunc2,
		    (ClientData) types);
	    (void) DBPlaneEnumAreaPaint((Tile *) NULL, def->cd_planes[i],
		    &check2, &DBAllTypeBits, dbPickFunc2,
		    (ClientData) types2);
	}
	TTMaskSetMask(&types[0], &types2[0]);
	TTMaskSetMask(&types[1], &types2[1]);
	TTMaskSetMask(&types[2], &types2[2]);
    }
    else if (lab->lab_rect.r_ybot == lab->lab_rect.r_ytop)
    {
	/* Horizontal line label.  Search two areas, one on the
	 * top and one on the bottom.  Use the code from above
	 * to handle.
	 */
	
	check1 = lab->lab_rect;
	check2 = lab->lab_rect;
	check1.r_ybot -= 1;
	check2.r_ytop += 1;
	goto twoAreas;
    }
    else
    {
	/* This is a rectangular label.  Same thing as for line labels,
	 * except there's only one area to search.
	 */
	
	types[0] = DBAllButSpaceAndDRCBits;
	types[1] = DBAllButSpaceAndDRCBits;
	TTMaskZero(&types[2]);
	for (i = PL_SELECTBASE; i < DBNumPlanes; i += 1)
	{
	    dbAdjustPlaneTypes = &DBPlaneTypes[i];
	    (void) DBPlaneEnumAreaPaint((Tile *) NULL, def->cd_planes[i],
		    &lab->lab_rect, &DBAllTypeBits, dbPickFunc2,
		    (ClientData) types);
	}
    }

    /* lookup visible types */
    {
      Layout *w = LayCurWindow();
      visibleTypes = &w->lay_visibleLayers;
    }

#define COVER_TYPES &types[0]
#define COVER_COMPONENTS &types[1]
#define TOUCHING_TYPES &types[2]   
#define VISIBLE_TYPES visibleTypes   

    /* 0.  keep present type if covers label */
    if (TTMaskHasType(COVER_TYPES, lab->lab_type)) return lab->lab_type;

    plane = DBPlane(lab->lab_type);
    choice1v = choice2v = choice3v = choice4v = choice5v = choice6v = TT_SPACE;
    choice1 = choice2 = choice3 = choice4 = choice5 = choice6 = TT_SPACE;
    for (i = TT_SELECTBASE; i < DBNumUserLayers; i += 1)
    {
        /* if type doesn't even touch label, keep trying */
	if (!TTMaskHasType(TOUCHING_TYPES, i)) continue;

	if (DBConnectsTo(i, lab->lab_type))
	{
	    if (DBPlane(i) == plane)
	    {
		if (TTMaskHasType(COVER_TYPES, i))
		{
		    /* 1. connects, same plane, covers label */   
		    if (TTMaskHasType(VISIBLE_TYPES, i)) choice1v=i; else choice1=i;
		    continue;
		}
		else if (TTMaskHasType(COVER_COMPONENTS, i))
		{
		    /* 2. connects, same plane, component of cover */
		    if (TTMaskHasType(VISIBLE_TYPES, i)) choice2v=i; else choice2=i;
		    continue;
		}
	    }
	    if (TTMaskHasType(COVER_TYPES, i))
	    {
	        /* 3. connects, different plane, covers label */
      	        if (TTMaskHasType(VISIBLE_TYPES, i)) choice3v=i; else choice3=i;
		continue;
	    }
	    else if (TTMaskHasType(COVER_COMPONENTS, i))
	    {
	        /* 4. connects, different plane, component of cover */
      	        if (TTMaskHasType(VISIBLE_TYPES, i)) choice4v=i; else choice4=i;
		continue;
	    }
	}
	if (TTMaskHasType(COVER_TYPES, i))
	{
            /* 5. doesn't connects, different plane, cover */
            if (TTMaskHasType(VISIBLE_TYPES, i)) choice5v=i; else choice5=i;
	    continue;
	}
	else if (TTMaskHasType(COVER_COMPONENTS, i))
	{
            /* 6. doesn't connects, different plane, component of cover */
            if (TTMaskHasType(VISIBLE_TYPES, i)) choice6v=i; else choice6=i;
	    continue;
	}
    }

    if (choice1v != TT_SPACE) return choice1v;
    else if (choice1 != TT_SPACE) return choice1;
    else if (choice2v != TT_SPACE) return choice2v;
    else if (choice2 != TT_SPACE) return choice2;
    else if (choice3v != TT_SPACE) return choice3v;
    else if (choice3 != TT_SPACE) return choice3;
    else if (choice4v != TT_SPACE) return choice4v;
    else if (choice4 != TT_SPACE) return choice4;
    else if (choice5v != TT_SPACE) return choice5v;
/*  Don't choose unconnected layer unless visible!
    else if (choice5 != TT_SPACE) return choice5;  don't choose unconnected 
*/
    else if (choice6v != TT_SPACE) return choice6v;
/*    else return choice6;  don't choose */
    else return TT_SPACE;
}

/*
 * ----------------------------------------------------------------------------
 *
 * DBLabelAlloc --
 *
 * Allocate a label, copy text into it.
 *
 * Label is not linked into a cell.  
 *
 * See also: DBLabelLink() and DBLabelAddG() 
 *
 * ----------------------------------------------------------------------------
 */
Label *DBLabelAlloc(char *text) 
{
  Label *lab;
  int len;

  len = strlen(text) + sizeof (Label) - sizeof lab->lab_text + 1;
  CALLOC(Label *, lab, (unsigned) len);
  strcpy(lab->lab_text, text);

  return lab;
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBLabelDup --
 *
 * Allocate a new label, and copy old label values into it.
 *
 * Label is not linked into a cell.  
 * NOTE: new label does not inherit old labels group (since groups are per def) 
 *
 * See also: DBLabelLink() and DBLabelAddG() 
 *
 * ----------------------------------------------------------------------------
 */
Label *DBLabelDup(Label *lab) 
{
  Label *new = DBLabelAlloc(lab->lab_text);
  new->lab_kind = lab->lab_kind;
  new->lab_type = lab->lab_type;
  new->lab_rect = lab->lab_rect;
  new->lab_pos = lab->lab_pos;
  
  return new;
}

/*
 * ----------------------------------------------------------------------------
 *
 * DBLabelLink --
 *
 * Link label into cell def.
 * If duplicate, frees (new) label and returns.
 *
 * Goes to pains to add label to end of list (may be required by extractor?)
 *
 * NOTE: there is no DBLabelUnlink() only DBLabelErase() - if you add
 *       DBLabelUnlink(), beware that undoing a DBLabelLink() frees the label!
 *
 * ----------------------------------------------------------------------------
 */
void DBLabelLink(CellDef *cellDef, Label *lab, int flags) 
{
  Label *dup;
  int debCount = 0; /* DEBUG */
  Label *debFirst = NULL;
  /* if duplicate, free new label and return  */

  for(dup = (Label *) IHashLookUp(cellDef->cd_labelLocHash,&lab->lab_rect);
      dup;
      dup = IHashLookUpNext(cellDef->cd_labelLocHash,dup))
  {

    if(dup->lab_type == lab->lab_type && 
       dup->lab_group == lab->lab_group && 
       strcmp(dup->lab_text,lab->lab_text) == 0)
    {
      FREE(lab);
      return;
    }
  }

  if(flags & DBLL_PREPEND)
  {
    /* add label to beginning of list */
    lab->lab_prev = NULL;

    lab->lab_next = cellDef->cd_labels;
    if(lab->lab_next) lab->lab_next->lab_prev = lab;

    cellDef->cd_labels = lab;
    if(!lab->lab_next) cellDef->cd_lastLabel = lab;
  }
  else
  {
    /* add label to end of list */

    lab->lab_next = NULL;
    if (cellDef->cd_labels == NULL)
    {
      lab->lab_prev = NULL;
      cellDef->cd_labels = lab;
    }
    else
    {
      ASSERT(cellDef->cd_lastLabel->lab_next == NULL, "DBLabelLink");
      cellDef->cd_lastLabel->lab_next = lab;
      lab->lab_prev = cellDef->cd_lastLabel;
    }
    cellDef->cd_lastLabel = lab;
  }

  IHashAdd(cellDef->cd_labelHash, lab);
  IHashAdd(cellDef->cd_labelLocHash, lab);

  DBUndoPutLabel(cellDef, 
		 &lab->lab_rect, 
		 lab->lab_pos, 
		 lab->lab_text, 
		 lab->lab_type,
		 lab->lab_group,
		 lab->lab_kind);
  DBFlyLineNotifyLabelChange(cellDef, lab->lab_text);
}

/*
 * ----------------------------------------------------------------------------
 *
 * DBLabelAddG --
 *
 * Place a rectangular label in the database, in given group in given cell.
 *
 * Results:
 *	returns pointer to newly created label.
 *
 * Side effects:
 *	Updates the label list in the CellDef to contain the label.
 *      Updates cd_labelHash 
 *
 * ----------------------------------------------------------------------------
 */
Label *
DBLabelAddG(CellDef *cellDef,   /* Cell in which label is placed */
	    Rect *rect,         /* Location of label; see above for description */
	    int align,          /* Orientation/alignment of text.  If this is < 0,
			         * default to text on right.
			         */
	    char *text,         /* Pointer to actual text of label */
	    TileType type,      /* Type of tile to be labelled 
				 * if -1 we pick a reasonable type 
				 */
	    Group *group,       /* group to put label in */
	    int kind)
{
    register Label *lab;
    Label *dup;
    int len, x1, x2, y1, y2, tmp, labx, laby;

    /* keep track of largest label in database (this Max session)
     *  
     * (used by redisplay code to determine when zoomed out far
     *  enough so no labels are visible.)
     *
     */
    {
      int dx = ABSDIFF(rect->r_xbot,rect->r_xtop);
      int dy = ABSDIFF(rect->r_ybot,rect->r_ytop);

      if(dx>DBLabelMaxDim) DBLabelMaxDim = dx;
      if(dy>DBLabelMaxDim) DBLabelMaxDim = dy;
    }
    
    /* allocate label */
    lab = DBLabelAlloc(text);
    lab->lab_rect = *rect;
    lab->lab_pos = align;

    /* default to text on right 
     * (note rmed clever use of bbox to determine alignment, since
     *  this impacted saved gcells and also was a potential performance
     *  bug)
     */
    if(align < 0) align = GEO_EAST;

    /* if no type was specified, pick something reasonable */ 
    if(type < 0)
    {
      type = dbPickLabelLayer(cellDef, lab);
      lab->lab_type = type;
    }

    /* set fields */ 
    lab->lab_pos = align;
    lab->lab_type = type<0 ? TT_SPACE : type;
    lab->lab_group = group;
    lab->lab_rect = *rect;
    lab->lab_kind = kind;
    lab->lab_next = NULL;

    /* link label into cellDef */
    DBLabelLink(cellDef, lab, 0 /* flags, 0 = append label */);

    return lab;
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBLabelAdd --
 *
 * Place a rectangular label in the database, in a particular cell
 * in the currently active group.
 *
 * Results:
 *	Returns pointer to newly created label.
 *
 * Side effects:
 *	Updates the label list in the CellDef to contain the label.
 *
 * ----------------------------------------------------------------------------
 */
Label *
DBLabelAdd(CellDef *cellDef,   /* Cell in which label is placed */
	    Rect *rect,         /* Location of label; see above for description */
	    int align,          /* Orientation/alignment of text.  If this is < 0,
			         * an orientation will be picked to keep the text
			         * inside the cell boundary.
			         */
	    char *text,         /* Pointer to actual text of label */
	    TileType type,     	/* Type of tile to be labelled, if -1
				 * we choose a reasonable type.
				 */
	    int kind)
{
    return DBLabelAddG(cellDef, 
		       rect, 
		       align, 
		       text, 
		       type, 
		       cellDef->cd_activeGroup, 
		       kind);
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBLabelErase --
 *
 * Delete given label from given def.
 *
 * returns:   pointer to following label.
 *
 * ----------------------------------------------------------------------------
 */

Label *
DBLabelErase(CellDef *cellDef, 
	        		/* Cell being modified */
	      Label *lab) 
               			/* label to delete */
{
    Label *prev = lab->lab_prev;
    Label *next = lab->lab_next;

    /* unlink */
    if(prev)
    {
      prev->lab_next = next;
    }
    else
    {
      cellDef->cd_labels = next;
    }

    if(next)
    {
      next->lab_prev = prev;
    }
    else
    {
      cellDef->cd_lastLabel = prev;
    }

    IHashDelete(cellDef->cd_labelHash, lab);
    IHashDelete(cellDef->cd_labelLocHash, lab);

    DBUndoEraseLabel(cellDef, 
		     &lab->lab_rect, 
		     lab->lab_pos,
		     lab->lab_text, 
		     lab->lab_type, 
		     lab->lab_group, 
		     lab->lab_kind);

    DBChangedArea(cellDef, &lab->lab_rect, NULL, DBCF_LABEL);
    DBFlyLineNotifyLabelChange(cellDef, lab->lab_text);
    FREE((char *) lab);

    return next;
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBLabelsEraseArea --
 *
 * Delete labels attached to tiles of the indicated types that
 * are in the given area (as determined by the macro GEO_LABEL_IN_AREA).  
 * If this procedure is called as part of a command that also modifies paint, 
 * then the paint modifications should be done BEFORE calling here.
 *
 * Only erases labels from activeGroup 
 *
 * Results:
 *	TRUE if any labels were deleted, FALSE otherwise.
 *
 * Side effects:
 *	This procedure tries to be clever in order to avoid deleting
 *	labels whenever possible.  If there's enough material on the
 *	label's attached layer so that the label can stay on its
 *	current layer, or if the label can be migrated to a layer that
 *	connects to its current layer, then the label is not deleted.
 *	Deleting up to the edge of a label won't cause the label
 *	to go away.  There's one final exception:  if the mask includes
 *	L_LABEL, then labels are deleted from all layers even if there's
 *	still enough material to keep them around.
 *
 * ----------------------------------------------------------------------------
 */

bool
DBLabelsEraseArea(CellDef *cellDef, 
	        		/* Cell being modified */
	     Rect *area, 
               			/* Area from which labels are to be erased.
				 * This may be a point; any labels touching
				 * or overlapping it are erased.
				 */
	     TileTypeBitMask *mask)
                          	/* Mask of types from which labels are to
				 * be erased.
				 */
{
    register Label *lab;
    bool erasedAny = FALSE;
    TileType newType;
    Group *group = cellDef->cd_activeGroup;

    lab = cellDef->cd_labels;

    while (lab != NULL)
    {
      Label *del;

      if(lab->lab_group != group) goto nextLab;
      if (!GEO_LABEL_IN_AREA(&lab->lab_rect, area)) goto nextLab;
      if (!TTMaskHasType(mask, L_LABEL) &&
	  !TTMaskHasType(mask, lab->lab_type)) goto nextLab;

      /* delete label */
      lab = DBLabelErase(cellDef,lab);
      erasedAny = TRUE;
      continue;

    nextLab: 
      lab = lab->lab_next;
    }

    return (erasedAny);
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBLabelsEraseByContentG --
 *
 * Erase any labels found on the label list for the given
 * CellDef and specified group that match the given specification.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Modifies the label list for the argument CellDef.  The
 *	Layind module is notified about any labels that were
 *	deleted.
 *
 * ----------------------------------------------------------------------------
 */

void
DBLabelsEraseByContentG(CellDef *def,        	
			              /* Where to look for label to delete. */
			register Rect *rect,    	
			              /* Coordinates of label.  If NULL, then
				       * labels are deleted regardless of coords.
				       */
			register int pos,	
			              /* Position of label.  If < 0, then
				       * labels are deleted regardless of 
				       * position.
				       */
			register TileType type, 	
			              /* Layer label is attached to.  If < 0, then
				       * labels are deleted regardless of type.
				       */
			char *text, 		
			              /* Text associated with label.  If NULL, 
				       * then labels are deleted regardless 
				       * of text.
				       */
		       Group *group)  
                                      /* group to look for label to delete */
{
    register Label *lab;

    if(rect)
    {  
      lab = IHashLookUp(def->cd_labelLocHash,rect);
    }
    else if(text)
    {
      lab = IHashLookUp(def->cd_labelHash,text);
    }
    else
    {
      lab = def->cd_labels;
    }

    while(lab)  
    {
      if (lab->lab_group != group) goto next;
      if ((rect != NULL) && !(GEO_SAMERECT(lab->lab_rect, *rect))) goto next;
      if ((type >= 0) && (type != lab->lab_type)) goto next;
      if ((pos >= 0) && (pos != lab->lab_pos)) goto next;
      if ((text != NULL) && (strcmp(text, lab->lab_text) != 0)) goto next;

      /* delete it */
      lab = DBLabelErase(def,lab);
      continue;

    next:
      if(rect)
      {
	lab = IHashLookUpNext(def->cd_labelLocHash,lab);
      }
      else if(text)
      {
	lab = IHashLookUpNext(def->cd_labelHash,lab);
      }
      else
      {
	lab = lab->lab_next;
      }
    }
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBLabelsEraseByContent --
 *
 * Erase any labels found on the label list for the given
 * CellDef, that match the given specification.
 *
 * Only labels in the currently active group are erased.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Modifies the label list for the argument CellDef.  The
 *	Layind module is notified about any labels that were
 *	deleted.
 *
 * ----------------------------------------------------------------------------
 */

void
DBLabelsEraseByContent(
		       CellDef *def,        	
		                        /* Where to look for label to delete. */
		       register Rect *rect,    	
		                        /* Coordinates of label.  If NULL, then
				         * labels are deleted regardless of 
					 * coords.
				         */
		       register int pos,	
		                        /* Position of label.  If < 0, then
				         * labels are deleted regardless of 
					 * position.
				         */
		       register TileType type, 	
		                        /* Layer label is attached to.  If < 0, 
					 * then labels are deleted regardless 
					 * of type.
				         */
		       char *text) 		
                                        /* Text associated with label.  If NULL, 
					 * then labels are deleted regardless 
					 *  of text.
					 */
{
    DBLabelsEraseByContentG(def,rect,pos,type,text,def->cd_activeGroup);
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBLabelsClear --
 *
 * Remove all labels from celldef.
 *
 *
 * ----------------------------------------------------------------------------
 */

void
DBLabelsClear(CellDef *cellDef)
{
  Label *lab;

  for (lab = cellDef->cd_labels; lab; lab = lab->lab_next)
  {
    FREE((char *) lab);
  }
  cellDef->cd_labels = (Label *) NULL;
  cellDef->cd_lastLabel = (Label *) NULL;
  IHashClear(cellDef->cd_labelHash);
  IHashClear(cellDef->cd_labelLocHash);
}



