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
 * DRCcif.c --
 *
 *********************************************************************************
 * Copyright (C) 1989 Digital Equipment Corporation                              *
 * Permission to use, copy, modify, and distribute this                          *
 * software and its documentation for any purpose and without                    *
 * fee is hereby granted, provided that the above copyright                      *
 * notice appear in all copies.  Digital Equipment Corporation                   *
 * makes no representations about the suitability of this                        *
 * software for any purpose.  It is provided "as is" without                     * 
 * express or implied warranty.  Export of this software outside                 *
 * of the United States of America may require an export license.                *
 *                                                                               * 
 * THE SOFTWARE IS PROVIDED "AS IS" AND DIGITAL EQUIPMENT CORP. DISCLAIMS ALL    *
 * WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF  *
 * MERCHANTABILITY AND FITNESS.   IN NO EVENT SHALL DIGITAL EQUIPMENT            *
 * CORPORATION BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL     *
 * DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR         *
 * PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS       *
 * ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS   *
 * SOFTWARE.                                                                     *
 *********************************************************************************
 *
 */

#ifndef	lint
static char rcsid[] = "$Header: DRCcif.c,v 1.11 92/07/17 15:20:11 mayo Exp $";
#endif	not lint

#include <sys/types.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "magic.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "layout.h"
#include "layout.h"
#include "layout.h"
#include "drc.h"
#include "cif.h"
#include "cifInt.h"
#include "signals.h"
#include "stack.h"
#include "memory.h"
#include "utils.h"
#include "mm.h"

extern Stack	*DRCstack;

#define PUSHTILE(tp) \
    if ((tp)->ti_client == (ClientData) DRC_UNPROCESSED) { \
        (tp)->ti_client = (ClientData)  DRC_PENDING; \
        STACKPUSH((ClientData) (tp), DRCstack); \
    }

extern CIFStyle	*drcCifStyle;
TileTypeBitMask drcCifGenLayers;
int	drcCifTile(register Tile *tile, struct drcClientData *arg);
extern int areaCifCheck(register Tile *tile, register struct drcClientData *arg);

typedef struct drccifcookie
{
    int    	       drcc_dist;	/* Extent of rule from edge. */
    TileTypeBitMask      drcc_mask;	/* Legal types on RHS */
    TileTypeBitMask      drcc_corner;	/* Types that trigger corner check */
    struct drccifcookie * drcc_next;
    char             * drcc_why;	/* Explanation of error found */
    int		       drcc_cdist;	/* Size of corner extension. */
    int		       drcc_flags;	/* Miscellaneous flags, see below. */
    int		       drcc_plane;	
} DRCCifCookie;

DRCCifCookie	*drcCifRules[MAXCIFLAYERS][2];
int	drcCifValid = FALSE;
#define DRC_CIF_SPACE		0
#define DRC_CIF_SOLID		1
DRCCifCookie	*drcCifCur=NULL;

#define ASSIGN(cookie,dist,next,mask,corner,why,cdist,flags,layer) \
	((cookie)->drcc_dist = dist, \
	(cookie)->drcc_next = next, \
	(cookie)->drcc_mask = mask, \
	(cookie)->drcc_corner = corner, \
	(cookie)->drcc_why = StrDup ((char **) NULL, why), \
	(cookie)->drcc_cdist = cdist, \
	(cookie)->drcc_flags = flags, \
        (cookie)->drcc_plane = layer)


/*
 * ----------------------------------------------------------------------------
 * drcCIFDimension --
 *
 * Convert string to int.
 *
 * If string is int (no '.'), it is in cifplane units.
 *
 * If string is not int (has  '.') its in microns,
 * converted to microns using scale factor of drc cifstyle.
 *
 * On error, returns 1, since non-positive dimension may lead to coredump
 * ----------------------------------------------------------------------------
 */

static int drcCIFDimension(char *s)
{
  int result;

  if(!strchr(s,'.'))
  {
    /* integer dimension (DB units) */
    char *tail;
    result = strtol(s, &tail, 10);
    if(*tail)
    {
      MnTechError("Bad DRC CIF dimension: '%s'", s);
      return 1;
    }
    if(result <= 0)
    {
      MnTechError("Bad DRC CIF dimension (must be positive): '%d'\n", 
		  result);
      return 1;
    }
    return result;
  }
  else
  {
    /* floating point dimension (microns) */
    char *tail;
    double d;
    double res;  
    
    if(!drcCifStyle)
    {
      MnTechError("DRC dimension in microns requires 'cifstyle': '%s'", s);
      return 1;
    }
    res = drcCifStyle->cs_CIFPlaneRes;

    d = strtod(s, &tail);
    if(*tail)
    {
      MnTechError("Bad DRC dimension: '%s'", s);
      return 1;
    }

    result = ROUND(d/res);

    if(ABSDIFF(result*res,d) > UNIT_TOLERANCE)
    {
      MnTechError("DRC CIF dimension %f not on %g design grid, approximating as %g\n",
		  d, res, result*res);
    }
    if(result*res <= 0)
    {
      MnTechError("Bad DRC dimension (must be positive): '%g'\n",
		  result*res);
      return 1;
    }      
    return result;
  }
}


/*
 * ----------------------------------------------------------------------------
 * drcCIFDimension2 --
 *
 * Convert string to int (square dimension).
 *
 * If string is int (no '.'), it is in DB units**2.
 *
 * If string is floating point (has  '.') its in microns**2,
 * converted to microns using drc scale factor of drc output style.
 *
 * On error, returns 1, since non-positive dimension may lead to coredump
 *
 * ----------------------------------------------------------------------------
 */

static int drcCIFDimension2(char *s)
{
  int result;

  if(!strchr(s,'.'))
  {
    /* integer dimension (DB units) */
    char *tail;
    result = strtol(s, &tail, 10);
    if(*tail)
    {
      MnTechError("Bad CIF dimension: '%s'", s);
      return 1;
    }
    if(result <= 0)
    {
      MnTechError("Bad CIF DRC dimension (must be positive): '%d'\n", 
		  result);
      return 1;
    }
    return result;
  }
  else
  {
    /* floating point dimension (microns) */
    char *tail;
    double d;
    double res;  

    if(!drcCifStyle)
    {
      MnTechError("DRC CIF dimension in microns requires 'cifstyle': '%s'", s);
      return 1;
    }
    res = drcCifStyle->cs_CIFPlaneRes;

    d = strtod(s, &tail);
    if(*tail)
    {
      MnTechError("Bad DRC CIF dimension: '%s'", s);
      return 1;
    }

    result = ROUND(d/(res*res));
    if(ABSDIFF(result*(res*res),d)> UNIT_TOLERANCE)
    {
      MnTechError("DRC CIF square dimension %f not on %g design grid, approximating as %g\n",
		  d, res, result*res*res);
    }
    if(result*res*res <= 0)
    {
      MnTechError("Bad DRC CIF dimension (must be positive): '%g'\n", 
		  result*res*res);
      return 1;
    }      
    return result;
  }
}

/*
 * ----------------------------------------------------------------------------
 *
 * drcParseCifLayer -- convert string to cif layer index.
 *
 * Results:
 *	Returns index of cif layer with name s, DRC_CL_SPACE for "space",
 *      DRC_CL_0 for "0", or DRC_CL_ERROR if an error occured.
 *
 *
 * Side effects:
 *	Complains via MnTechError() if error encountered.
 *
 * ----------------------------------------------------------------------------
 */

#define DRC_CL_SPACE -1
#define DRC_CL_0 -2
#define DRC_CL_ERROR -3

int drcParseCifLayer(char *s)
{
    int i;

    if (drcCifStyle == NULL)
    {
    	 MnTechError("Missing cif style for drc\n");
	 return DRC_CL_ERROR;
    } 

    if (strcmp(s,"0")==0)
    {
         return DRC_CL_0;
    }

    if (strcmp(s,"space")==0)
    {
         return DRC_CL_SPACE;
    }

    for (i = 0; i < drcCifStyle->cs_nLayers;i++)
    {
    	 CIFLayer	*layer = drcCifStyle->cs_layers[i];
	 if (strcmp(layer->cl_name,s) == 0) break;
    }

    if (i == drcCifStyle->cs_nLayers)
    {
    	 MnTechError("Unknown cif layer: %s\n",s);
         return DRC_CL_ERROR;
    }

   return i;
}


/*
 * ----------------------------------------------------------------------------
 *
 * drcCifEdge -- Same as drcEdge, except that it works on cif layers.
 *
 * Process a primitive edge rule.
 *
 * An "edge" rule is applied only down and to the left.
 * An "edge4way" rule is applied in all four directions.
 *
 * Results:
 *	Returns greater of dist and cdist.
 *
 * Side effects:
 *	Updates the DRC technology variables.
 *
 * ----------------------------------------------------------------------------
 */

int drcCifEdge(int argc, char **argv)
{
    char *layers1 = argv[1], *layers2 = argv[2];
    int distance = drcCIFDimension(argv[3]);
    char *okTypes = argv[4], *cornerTypes = argv[5];
    int cdist = (*cornerTypes=='0') ? 1 : drcCIFDimension(argv[6]);
    char *why = argv[7];
    bool fourway = (strcmp(argv[0], "cifedge4way") == 0);
    DRCCifCookie *dpnext, *dpnew;
    int plane, checkPlane;
    int cif1, cif2, cifCorner, cifOK;
    TileTypeBitMask setC, setM;

    /* crude hack to implement zero spacing rule.  If distance is zero,
       set the DRC_SEROSPACERULE flag and reset it to 1. areaCheck should
       do the rest.
    */
    if (distance == 0) 
    {
    	 distance=1;
    }

    /* parse layers1 and layers2 */
    if ( (cif1=drcParseCifLayer(layers1)) == DRC_CL_ERROR ) return 0; 
    if ( (cif2=drcParseCifLayer(layers2)) == DRC_CL_ERROR ) return 0; 

    /* check that cif1 and cif2 are non-zero */
    if ( cif1==DRC_CL_0 || cif2==DRC_CL_0 )
    {
        MnTechError("cifedge: layers1 and layers2 must be nonzero.\n");
	return 0;
    }

    /* check that one of cif1 and cif2 is space */
    if (cif1!=DRC_CL_SPACE && cif2!=DRC_CL_SPACE)
    {
        MnTechError("cifedge: either layers1 or layers2 must be space.\n");
	return 0;
    }

    /* set edge plane */
    plane=cif1;
    if(plane == DRC_CL_SPACE) plane=cif2;

    /* parse corner types */
    if ( (cifCorner=drcParseCifLayer(cornerTypes)) == DRC_CL_ERROR ) return 0; 

    /* check that corner types on plane */
    if ( cifCorner>=0 && cifCorner!=plane )
    {
	MnTechError("cifedge:  Corner types aren't in same plane as edges.\n");
	return (0);
    }

    /* parse check plane */
    checkPlane = plane;
    if (argc == 9)
    {
	checkPlane = drcParseCifLayer(argv[8]);
	if (checkPlane < 0)
	{
            MnTechError("cifedge:  bad checkPlane\n");
	    return (0);
        }
     }

    /* parse ok types */
    if ( (cifOK=drcParseCifLayer(okTypes)) == DRC_CL_ERROR ) return 0; 

    /* make sure ok types are on check plane */
    if ( cifOK>=0 && cifOK!=checkPlane )
    {
	MnTechError("cifedge:  OK types aren't all in the right plane.\n");
	return (0);
    }
 
    /* compute corner types mask */
    switch ( cifCorner )
    {
        case DRC_CL_0:
            setC = DBZeroTypeBits;
	    break;
	case DRC_CL_SPACE:
	    setC = DBSpaceBits;
	    break;
        default:
	    setC = CIFSolidBits;
    }

    /* compute OK types mask */
    setM = (cifOK == DRC_CL_SPACE) ? DBSpaceBits : CIFSolidBits;

    /* build forward rule (cookie) */
    MALLOC(DRCCifCookie *, dpnew, sizeof (DRCCifCookie));
    dpnext = drcCifRules[plane][cif1!=DRC_CL_SPACE];
    ASSIGN(dpnew, distance, dpnext, setM, setC, why, cdist, 
	   DRC_FORWARD, checkPlane);
    if (distance == 0) dpnew->drcc_flags |= DRC_ZEROSPACERULE;
    if (fourway) dpnew->drcc_flags |= DRC_BOTHCORNERS;
    if (checkPlane != plane) dpnew->drcc_flags |= DRC_XPLANE;
    drcCifRules[plane][cif1!=DRC_CL_SPACE] = dpnew;

    /* if fourway rule, build reverse rule (cookie) */
    if (fourway)
    {
        MALLOC(DRCCifCookie *, dpnew, sizeof (DRCCifCookie));
        dpnext = drcCifRules[plane][cif1==DRC_CL_SPACE];
        ASSIGN(dpnew, distance, dpnext, setM, setC, why, cdist, 
	       DRC_REVERSE, checkPlane);
        if (distance == 0) dpnew->drcc_flags |= DRC_ZEROSPACERULE;
        if (fourway) dpnew->drcc_flags |= DRC_BOTHCORNERS;
        if (checkPlane != plane) dpnew->drcc_flags |= DRC_XPLANE;
        drcCifRules[plane][cif1==DRC_CL_SPACE] = dpnew;
    }

    /* distance and cdist are in centimicrons, 
     * return max of these in Magic Internal units, rounding up.
     */
    {
       int scalefactor = drcCifStyle->cs_DBRes/drcCifStyle->cs_CIFPlaneRes;
       int maxCifD = MAX(distance, cdist);

       return ((maxCifD+scalefactor-1)/scalefactor);
    }
}


/*
 * ----------------------------------------------------------------------------
 *
 * drcCifWidth -- same as drcWidth, except that it works on 
 *	cif layers
 *
 * Results:
 *	Returns distance.
 *
 * Side effects:
 *	Updates the DRC technology variables.
 *
 * ----------------------------------------------------------------------------
 */

    /*ARGSUSED*/
int drcCifWidth(int argc, char **argv)
{
    char *layername = argv[1];
    int scalefactor;
    int centidistance = drcCIFDimension(argv[2]);
    char *why = argv[3];
    TileTypeBitMask set, setC, tmp1;
    int	thislayer = -1;
    DRCCifCookie *dpnew,*dpnext;
    TileType i;

    if (drcCifStyle == NULL)
    {
    	 MnTechError("Missing cif style for drc\n");
	 return 0;
    } 
    for (i = 0; i < drcCifStyle->cs_nLayers;i++)
    {
    	 CIFLayer	*layer = drcCifStyle->cs_layers[i];
	 
	 if (strcmp(layer->cl_name,layername) == 0) 
	 {
	      thislayer = i;
	      break;
	 }
    }
    if (thislayer == -1)
    {
    	 MnTechError("Unknown cif layer: %s\n",layername);
         return (0);
    }
    scalefactor = drcCifStyle->cs_DBRes/drcCifStyle->cs_CIFPlaneRes;
    dpnext = drcCifRules[thislayer][DRC_CIF_SPACE];
    MALLOC(DRCCifCookie *, dpnew, sizeof (DRCCifCookie));
    ASSIGN(dpnew,centidistance,dpnext,CIFSolidBits,
    		CIFSolidBits,why,centidistance,DRC_FORWARD,thislayer);
    drcCifRules[thislayer][DRC_CIF_SPACE] = dpnew;

    return ((centidistance+scalefactor-1)/scalefactor);
}

/*
 * ----------------------------------------------------------------------------
 *
 * drcCifSpacing -- same this as drcSpacing, except that it works on cif 
 	layers.
 *
 * Results:
 *	Returns distance.
 *
 * Side effects:
 *	Updates the DRC technology variables.
 *
 * ----------------------------------------------------------------------------
 */

    /*ARGSUSED*/
int drcCifSpacing(int argc, char **argv)
{
    char *adjacency = argv[4];
    char *why = argv[5];
    DRCCifCookie *dpnext, *dpnew;
    int needReverse = FALSE;
    TileType i, j;
    int scalefactor;
    int centidistance = drcCIFDimension(argv[3]);
    char *layers[2];
    TileType layer[2];
    TileTypeBitMask	cmask;
    int	k;

    layers[0] = argv[1];
    layers[1] = argv[2];
    
    if (drcCifStyle == NULL)
    {
    	 MnTechError("Missing cif style for drc\n");
	 return 0;
    } 
    for (k=0; k!= 2;k++)
    {
         for (i = 0; i < drcCifStyle->cs_nLayers;i++)
         {
    	      CIFLayer	*l = drcCifStyle->cs_layers[i];
	 
	      if (strcmp(l->cl_name,layers[k]) == 0)
	      {
	      	   layer[k]=i;
	           break;
	      } 
         }
         if (i == drcCifStyle->cs_nLayers || layer[k] == -1)
         {
    	      MnTechError("Unknown cif layer: %s",layers[k]);
              return (0);
         }
    }

    if (strcmp (adjacency, "touching_ok") == 0)
    {
	/* If touching is OK, everything must fall in the same plane. */
	if (layer[0] != layer[1])
	{
	    MnTechError(
		"Spacing check with touching ok must all be in one plane.\n");
	    return (0);
	}
	cmask = DBSpaceBits;
    }
    else if (strcmp (adjacency, "touching_illegal") == 0)
    {
	 cmask = DBAllTypeBits;
	 needReverse = TRUE;
         /* nothing for now */
    }
    else
    {
	MnTechError("Badly formed drc spacing line\n");
	return (0);
    }
    scalefactor = drcCifStyle->cs_DBRes/drcCifStyle->cs_CIFPlaneRes;
    dpnext = drcCifRules[layer[0]][DRC_CIF_SOLID];
    MALLOC(DRCCifCookie *, dpnew, sizeof (DRCCifCookie));
    ASSIGN(dpnew,centidistance,dpnext,DBSpaceBits,
    		cmask,why,centidistance,DRC_FORWARD,layer[1]);
    drcCifRules[layer[0]][DRC_CIF_SOLID] = dpnew;
    
    if (needReverse)
    {
         dpnew->drcc_flags |= DRC_BOTHCORNERS|DRC_XPLANE;
         dpnext = drcCifRules[layer[1]][DRC_CIF_SOLID];
         MALLOC(DRCCifCookie *, dpnew, sizeof (DRCCifCookie));
         ASSIGN(dpnew,centidistance,dpnext,DBSpaceBits,
    		cmask,why,centidistance,
		DRC_XPLANE|DRC_FORWARD|DRC_BOTHCORNERS,layer[0]);
         drcCifRules[layer[1]][DRC_CIF_SOLID] = dpnew;
	 
	 if (layer[0] == layer[1])
	 {
              dpnext = drcCifRules[layer[1]][DRC_CIF_SPACE];
              MALLOC(DRCCifCookie *, dpnew, sizeof (DRCCifCookie));
              ASSIGN(dpnew,centidistance,dpnext,DBSpaceBits,
    		     cmask,why,centidistance,
		     DRC_XPLANE|DRC_REVERSE|DRC_BOTHCORNERS,layer[0]);
                 drcCifRules[layer[1]][DRC_CIF_SPACE] = dpnew;
	 
              dpnext = drcCifRules[layer[0]][DRC_CIF_SPACE];
              MALLOC(DRCCifCookie *, dpnew, sizeof (DRCCifCookie));
              ASSIGN(dpnew,centidistance,dpnext,DBSpaceBits,
    		     cmask,why,centidistance,
		     DRC_XPLANE|DRC_REVERSE|DRC_BOTHCORNERS,layer[1]);
                 drcCifRules[layer[0]][DRC_CIF_SPACE] = dpnew;
	 }
    }

    if (layer[0] != layer[1]) /* make sure they don't overlap exactly */
    {
         dpnext = drcCifRules[layer[1]][DRC_CIF_SPACE];
         MALLOC(DRCCifCookie *, dpnew, sizeof (DRCCifCookie));
         ASSIGN(dpnew,scalefactor,dpnext,DBSpaceBits,
    		DBZeroTypeBits,why,scalefactor,
		DRC_FORWARD,layer[0]);
         drcCifRules[layer[1]][DRC_CIF_SPACE] = dpnew;

         dpnext = drcCifRules[layer[0]][DRC_CIF_SPACE];
         MALLOC(DRCCifCookie *, dpnew, sizeof (DRCCifCookie));
         ASSIGN(dpnew,scalefactor,dpnext,DBSpaceBits,
    		DBZeroTypeBits,why,scalefactor,
		DRC_FORWARD,layer[1]);
         drcCifRules[layer[0]][DRC_CIF_SPACE] = dpnew;
    }
    
    return ((centidistance+scalefactor-1)/scalefactor);
}

void drcCifInit(void)
{
     int	i;

     for (i=0; i != MAXCIFLAYERS; i++)
     {
     	  drcCifRules[i][DRC_CIF_SPACE] = NULL;
     	  drcCifRules[i][DRC_CIF_SOLID] = NULL;
     }
     drcCifValid= FALSE;
     TTMaskZero(&drcCifGenLayers);
}
void drcCifFinal(void)
{
     int i;

     for (i=0; i != MAXCIFLAYERS; i++)
     {
          DRCCifCookie *dp;
     	  
	  for (dp =  drcCifRules[i][DRC_CIF_SPACE];dp;dp=dp->drcc_next)
	  {
     	       drcCifValid= TRUE;
               TTMaskSetType(&drcCifGenLayers,i);
               TTMaskSetType(&drcCifGenLayers,dp->drcc_plane);
	  }
	  for (dp =  drcCifRules[i][DRC_CIF_SOLID];dp;dp=dp->drcc_next)
	  {
     	       drcCifValid= TRUE;
               TTMaskSetType(&drcCifGenLayers,i);
               TTMaskSetType(&drcCifGenLayers,dp->drcc_plane);
	  }
     }
}

void drcCifCheck(struct drcClientData *arg)
{
     Rect		*checkRect = arg->dCD_rect;
     Rect		cifrect;
     int		scale;
     CIFStyle		*tmp;
     int		i,j;
     int oldTiles;

     if (drcCifValid == FALSE) return;
     scale = drcCifStyle->cs_DBRes/drcCifStyle->cs_CIFPlaneRes;
     tmp = CIFCurStyle;
     CIFCurStyle = drcCifStyle;
     cifrect = *checkRect;
     cifrect.r_xbot *= scale;
     cifrect.r_xtop *= scale;
     cifrect.r_ybot *= scale;
     cifrect.r_ytop *= scale;
     arg->dCD_rect = &cifrect;
     oldTiles = DRCstatTiles;

/*   CIFGen(arg->dCD_celldef,checkRect,CIFPlanes,&drcCifGenLayers,TRUE,FALSE); */

     CIFGen(arg->dCD_celldef,
	    checkRect,
	    CIFPlanes,
	    &DBAllTypeBits,
	    TRUE,
	    TRUE,
	    FALSE);

     for (i = 0; i < drcCifStyle->cs_nLayers;i++)
     {
          for (j = 0; j != 2;j++)
	  {
	       for (drcCifCur=drcCifRules[i][j]; 
	       			drcCifCur;drcCifCur=drcCifCur->drcc_next)
               {
     	            Plane *plane = CIFPlanes[i];
	  	    TileTypeBitMask	*mask;
		    
		    mask = (j == DRC_CIF_SOLID)?(&DBSpaceBits):&CIFSolidBits;
	  
	            DBPlaneEnumAreaPaint((Tile *) NULL,plane,&cifrect,mask,
	  		drcCifTile, arg);
     	       }
	       
	  }
     }

     arg->dCD_rect = checkRect;
     CIFCurStyle = tmp;
     DRCstatCifTiles += DRCstatTiles - oldTiles;

}


/*
 * ----------------------------------------------------------------------------
 *
 * areaCifCheck -- 
 *
 * Call the function passed down from DRCBasicCheck() if the current tile
 * violates the rule in the given DRCCookie.  If the rule's connectivity
 * flag is set, then make sure the violating material isn't connected
 * to what's on the initial side of the edge before calling the client
 * error function.
 *
 * This function is called from DBPlaneEnumAreaPaint().
 *
 * Results:
 *	Zero (so that the search will continue).
 *
 * Side effects:
 *      Applies the function passed as an argument.
 *
 * ----------------------------------------------------------------------------
 */

int
areaCifCheck(register Tile *tile, register struct drcClientData *arg)
{
    Rect rect;		/* Area where error is to be recorded. */
    int scale = drcCifStyle->cs_DBRes/drcCifStyle->cs_CIFPlaneRes;

    /* If the tile has a legal type, then return. */
    if (TTMaskHasType(&arg->dCD_cptr->drcc_mask, DBgetTileType(tile))) return 0;

    /* Only consider the portion of the suspicious tile that overlaps
     * the clip area for errors.
     */

    TiToRect(tile, &rect);
    GeoClip(&rect, arg->dCD_constraint);
    if ((rect.r_xbot >= rect.r_xtop) || (rect.r_ybot >= rect.r_ytop))
	return 0;
    rect.r_xbot /= scale;
    rect.r_xtop /= scale;
    if (rect.r_xbot == rect.r_xtop)
    {
    	 if (rect.r_xbot < 0) rect.r_xbot--; else rect.r_xtop++;
    }
    rect.r_ybot /= scale;
    rect.r_ytop /= scale;
    if (rect.r_ybot == rect.r_ytop)
    {
    	 if (rect.r_ybot < 0) rect.r_ybot--; else rect.r_ytop++;
    }
    GeoClip(&rect, arg->dCD_clip);
    if ((rect.r_xbot >= rect.r_xtop) || (rect.r_ybot >= rect.r_ytop))
	return 0;

    (*(arg->dCD_function)) (arg->dCD_celldef, &rect,
	arg->dCD_cptr, arg->dCD_clientData);
    (*(arg->dCD_errors))++;
    return (0);
}

/*
 * ----------------------------------------------------------------------------
 *
 * drcCifArea --
 *
 * Process an area rule.
 * This is of the form:
 *
 *	cifarea layers distance why
 *
 * e.g,
 *
 *	cifarea VIA 4 "via area must be at least 4"
 *
 * Results:
 *	Returns distance.
 *
 * Side effects:
 *	Updates the DRC technology variables.
 *
 * ----------------------------------------------------------------------------
 */

    /*ARGSUSED*/
int drcCifArea(int argc, char **argv)
{
    char *layers = argv[1];
    int centidistance = drcCIFDimension2(argv[2]);
    int	centiminWidth = drcCIFDimension(argv[3]);
    int centihorizon;
    char *why = argv[4];
    TileTypeBitMask set, setC, tmp1;
    DRCCifCookie *dpnext, *dpnew;
    TileType i, j;
    int plane;
    int	thislayer = -1;
    int scalefactor;

    /* horizon = amount of context needed to check this rule properly. */ 
    centihorizon = (centidistance + centiminWidth - 1) / centiminWidth;

    if (drcCifStyle == NULL)
    {
    	 MnTechError("Missing cif style for drc\n");
	 return 0;
    } 
    for (i = 0; i < drcCifStyle->cs_nLayers;i++)
    {
    	 CIFLayer	*layer = drcCifStyle->cs_layers[i];
	 
	 if (strcmp(layer->cl_name,layers) == 0) 
	 {
	      thislayer = i;
	      break;
	 }
    }
    if (thislayer == -1)
    {
    	 MnTechError("Unknown cif layer: %s\n",layers);
         return (0);
    }

    scalefactor = drcCifStyle->cs_DBRes/drcCifStyle->cs_CIFPlaneRes;
    dpnext = drcCifRules[thislayer][DRC_CIF_SPACE];
    MALLOC(DRCCifCookie *, dpnew, sizeof (DRCCifCookie));
    ASSIGN(dpnew,centihorizon,dpnext,CIFSolidBits,
    		CIFSolidBits,why,centidistance,DRC_AREA|DRC_FORWARD,thislayer);
    drcCifRules[thislayer][DRC_CIF_SPACE] = dpnew;


    return ((centihorizon+scalefactor-1)/scalefactor);
}

/*
 * ----------------------------------------------------------------------------
 *
 * drcCifMaxwidth --  cif version of drc list.
 *
 * Results:
 *	Returns distance.
 *
 * Side effects:
 *	Updates the DRC technology variables.
 *
 * ----------------------------------------------------------------------------
 */

    /*ARGSUSED*/
int drcCifMaxwidth(int argc, char **argv)
{
    char *layers = argv[1];
    int centidistance = drcCIFDimension(argv[2]);
    char *bends = argv[3];
    char *why = argv[4];
    TileTypeBitMask set, setC, tmp1;
    DRCCifCookie *dpnext, *dpnew;
    TileType i, j;
    int plane;
    int bend;
    int thislayer = -1;
    int scalefactor;

    if (drcCifStyle == NULL)
    {
    	 MnTechError("Missing cif style for drc\n");
	 return 0;
    } 

    for (i = 0; i < drcCifStyle->cs_nLayers;i++)
    {
    	 CIFLayer	*layer = drcCifStyle->cs_layers[i];
	 
	 if (strcmp(layer->cl_name,layers) == 0) 
	 {
	      thislayer = i;
	      break;
	 }
    }
    if (thislayer == -1)
    {
    	 MnTechError("Unknown cif layer: %s\n",layers);
         return (0);
    }

    if (strcmp(bends,"bend_illegal") == 0) bend =0;
    else if (strcmp(bends,"bend_ok") == 0) bend =DRC_BENDS;
    else
    {
    	 MnTechError("unknown bend option %s\n",bends);
	 return (0);
    }
    
    scalefactor = drcCifStyle->cs_DBRes/drcCifStyle->cs_CIFPlaneRes;
    dpnext = drcCifRules[thislayer][DRC_CIF_SPACE];
    MALLOC(DRCCifCookie *, dpnew, sizeof (DRCCifCookie));
    ASSIGN(dpnew,centidistance,dpnext,CIFSolidBits,
    		CIFSolidBits,why,centidistance,DRC_MAXWIDTH|bend,thislayer);
    drcCifRules[thislayer][DRC_CIF_SPACE] = dpnew;


    return ((centidistance+scalefactor-1)/scalefactor);
}

/*
 *-------------------------------------------------------------------------
 *
 * drcCifCheckArea- checks to see that a collection of cif tiles 
 *	have more than a minimum area.
 *
 * Results: none
 *
 * Side Effects: may cause errors to be painted.
 *
 *-------------------------------------------------------------------------
 */
static void drcCheckCifArea(Tile *starttile, 
			    struct drcClientData *arg, 
			    DRCCifCookie *cptr)
{
     int		arealimit = cptr->drcc_cdist;
     int		area=0;
     TileTypeBitMask	*oktypes = &cptr->drcc_mask;
     Tile		*tile,*tp;
     Rect		*cliprect = arg->dCD_rect;
     int scale = drcCifStyle->cs_DBRes/drcCifStyle->cs_CIFPlaneRes;
     
    arg->dCD_cptr = (DRCCookie *)cptr;
    if (DRCstack == (Stack *) NULL)
	DRCstack = StackNew(64);

    /* Mark this tile as pending and push it */
    PUSHTILE(starttile);

    while (!StackEmpty(DRCstack))
    {
	tile = (Tile *) STACKPOP(DRCstack);
	if (tile->ti_client != (ClientData)DRC_PENDING) continue;
	area += (RIGHT(tile)-LEFT(tile))*(TOP(tile)-BOTTOM(tile));
	tile->ti_client = (ClientData)DRC_PROCESSED;
	/* are we at the clip boundary? If so, skip to the end */
	if (RIGHT(tile) == cliprect->r_xtop ||
	    LEFT(tile) == cliprect->r_xbot ||
	    BOTTOM(tile) == cliprect->r_ybot ||
	    TOP(tile) == cliprect->r_ytop) goto forgetit;

         if (area >= arealimit) goto forgetit;

	/* Top */
	for (tp = RT(tile); RIGHT(tp) > LEFT(tile); tp = BL(tp))
	    if (TTMaskHasType(oktypes, DBgetTileType(tp)))	PUSHTILE(tp);

	/* Left */
	for (tp = BL(tile); BOTTOM(tp) < TOP(tile); tp = RT(tp))
	    if (TTMaskHasType(oktypes, DBgetTileType(tp))) PUSHTILE(tp);

	/* Bottom */
	for (tp = LB(tile); LEFT(tp) < RIGHT(tile); tp = TR(tp))
	    if (TTMaskHasType(oktypes, DBgetTileType(tp))) PUSHTILE(tp);

	/* Right */
	for (tp = TR(tile); TOP(tp) > BOTTOM(tile); tp = LB(tp))
	    if (TTMaskHasType(oktypes, DBgetTileType(tp))) PUSHTILE(tp);
     }
     if (area <arealimit)
     {
	 Rect	rect;
	 TiToRect(starttile,&rect);
         rect.r_xbot /= scale;
         rect.r_xtop /= scale;
         rect.r_ybot /= scale;
         rect.r_ytop /= scale;
	 GeoClip(&rect, arg->dCD_clip);
	 if (!GEO_RECTNULL(&rect)) {
	     (*(arg->dCD_function)) (arg->dCD_celldef, &rect,
		 arg->dCD_cptr, arg->dCD_clientData);
	     /***
	     DBChangedArea(arg->dCD_celldef,
	     &rect, 
	     &DBAllButSpaceBits,
	     DBCF_DRC_ERROR_ONLY)
	     ***/
	     (*(arg->dCD_errors))++;
	 }
	 
     }
forgetit:
     /* reset the tiles */
     starttile->ti_client = (ClientData)DRC_UNPROCESSED;
     STACKPUSH(starttile, DRCstack);
     while (!StackEmpty(DRCstack))
     {
	tile = (Tile *) STACKPOP(DRCstack);

	/* Top */
	for (tp = RT(tile); RIGHT(tp) > LEFT(tile); tp = BL(tp))
	    if (tp->ti_client != (ClientData)DRC_UNPROCESSED)
	    {
	    	 tp->ti_client = (ClientData)DRC_UNPROCESSED;
		 STACKPUSH(tp,DRCstack);
	    }

	/* Left */
	for (tp = BL(tile); BOTTOM(tp) < TOP(tile); tp = RT(tp))
	    if (tp->ti_client != (ClientData)DRC_UNPROCESSED)
	    {
	    	 tp->ti_client = (ClientData)DRC_UNPROCESSED;
		 STACKPUSH(tp,DRCstack);
	    }

	/* Bottom */
	for (tp = LB(tile); LEFT(tp) < RIGHT(tile); tp = TR(tp))
	    if (tp->ti_client != (ClientData)DRC_UNPROCESSED)
	    {
	    	 tp->ti_client = (ClientData)DRC_UNPROCESSED;
		 STACKPUSH(tp,DRCstack);
	    }

	/* Right */
	for (tp = TR(tile); TOP(tp) > BOTTOM(tile); tp = LB(tp))
	    if (tp->ti_client != (ClientData)DRC_UNPROCESSED)
	    {
	    	 tp->ti_client = (ClientData)DRC_UNPROCESSED;
		 STACKPUSH(tp,DRCstack);
	    }
     }
}


/*
 *-------------------------------------------------------------------------
 *
 * drcCheckCifMaxwidth - checks to see that at least one dimension of a region
 *	does not exceed some amount.
 *
 * Results: none
 *
 * Side Effects: may cause errors to be painted.
 *
 *-------------------------------------------------------------------------
 */
static void drcCheckCifMaxwidth(Tile *starttile, 
				struct drcClientData *arg, 
				DRCCifCookie *cptr)
{
     int		edgelimit = cptr->drcc_dist;
     Rect		boundrect;
     TileTypeBitMask	*oktypes = &cptr->drcc_mask;
     Tile		*tile,*tp;
     int scale = drcCifStyle->cs_DBRes/drcCifStyle->cs_CIFPlaneRes;

     
    arg->dCD_cptr = (DRCCookie *)cptr;
    if (DRCstack == (Stack *) NULL)
	DRCstack = StackNew(64);

    /* if bends are allowed, just check on a tile-by-tile basis that
        one dimension is the max.  This is pretty stupid, but it correctly
	calculates the trench width rule. dcs 12.06.89 */
    if (cptr->drcc_flags & DRC_BENDS)
    {
	 Rect	rect;
	 TiToRect(starttile,&rect);
	 if (rect.r_xtop-rect.r_xbot != edgelimit &&
	    rect.r_ytop-rect.r_ybot != edgelimit)
	 {
              rect.r_xbot /= scale;
              rect.r_xtop /= scale;
              rect.r_ybot /= scale;
              rect.r_ytop /= scale;
	      GeoClip(&rect, arg->dCD_clip);
	      if (!GEO_RECTNULL(&rect)) {
		  (*(arg->dCD_function)) (arg->dCD_celldef, &rect,
			arg->dCD_cptr, arg->dCD_clientData);
		  /***
		  DBChangedArea(arg->dCD_celldef,
		  &rect, 
		  &DBAllButSpaceBits,
		  DBCF_DRC_ERROR_ONLY);
		  ***/
		  (*(arg->dCD_errors))++;
	     }
	 }
	 return;
    }
    /* Mark this tile as pending and push it */
    PUSHTILE(starttile);
    TiToRect(starttile,&boundrect);

    while (!StackEmpty(DRCstack))
    {
	tile = (Tile *) STACKPOP(DRCstack);
	if (tile->ti_client != (ClientData)DRC_PENDING) continue;
	
	if (boundrect.r_xbot > LEFT(tile)) boundrect.r_xbot = LEFT(tile);
	if (boundrect.r_xtop < RIGHT(tile)) boundrect.r_xtop = RIGHT(tile);
	if (boundrect.r_ybot > BOTTOM(tile)) boundrect.r_ybot = BOTTOM(tile);
	if (boundrect.r_ytop < TOP(tile)) boundrect.r_ytop = TOP(tile);
	tile->ti_client = (ClientData)DRC_PROCESSED;

         if (boundrect.r_xtop - boundrect.r_xbot > edgelimit &&
             boundrect.r_ytop - boundrect.r_ybot > edgelimit) break;

	/* Top */
	for (tp = RT(tile); RIGHT(tp) > LEFT(tile); tp = BL(tp))
	    if (TTMaskHasType(oktypes, DBgetTileType(tp)))	PUSHTILE(tp);

	/* Left */
	for (tp = BL(tile); BOTTOM(tp) < TOP(tile); tp = RT(tp))
	    if (TTMaskHasType(oktypes, DBgetTileType(tp))) PUSHTILE(tp);

	/* Bottom */
	for (tp = LB(tile); LEFT(tp) < RIGHT(tile); tp = TR(tp))
	    if (TTMaskHasType(oktypes, DBgetTileType(tp))) PUSHTILE(tp);

	/* Right */
	for (tp = TR(tile); TOP(tp) > BOTTOM(tile); tp = LB(tp))
	    if (TTMaskHasType(oktypes, DBgetTileType(tp))) PUSHTILE(tp);
     }

     if (boundrect.r_xtop - boundrect.r_xbot > edgelimit &&
             boundrect.r_ytop - boundrect.r_ybot > edgelimit) 
     {
	 Rect	rect;
	 TiToRect(starttile,&rect);
	 {
              rect.r_xbot /= scale;
              rect.r_xtop /= scale;
              rect.r_ybot /= scale;
              rect.r_ytop /= scale;
	      GeoClip(&rect, arg->dCD_clip);
	      if (!GEO_RECTNULL(&rect)) {
		  (*(arg->dCD_function)) (arg->dCD_celldef, &rect,
			arg->dCD_cptr, arg->dCD_clientData);
		  /***
		  DBChangedArea(arg->dCD_celldef,
		  &rect,
		  &DBAllButSpaceBits,
		  DBCF_DRC_ERROR_ONLY);
		  ***/
		  (*(arg->dCD_errors))++;
	      }
	 }
	 
     }
     /* reset the tiles */
     starttile->ti_client = (ClientData)DRC_UNPROCESSED;
     STACKPUSH(starttile, DRCstack);
     while (!StackEmpty(DRCstack))
     {
	tile = (Tile *) STACKPOP(DRCstack);

	/* Top */
	for (tp = RT(tile); RIGHT(tp) > LEFT(tile); tp = BL(tp))
	    if (tp->ti_client != (ClientData)DRC_UNPROCESSED)
	    {
	    	 tp->ti_client = (ClientData)DRC_UNPROCESSED;
		 STACKPUSH(tp,DRCstack);
	    }

	/* Left */
	for (tp = BL(tile); BOTTOM(tp) < TOP(tile); tp = RT(tp))
	    if (tp->ti_client != (ClientData)DRC_UNPROCESSED)
	    {
	    	 tp->ti_client = (ClientData)DRC_UNPROCESSED;
		 STACKPUSH(tp,DRCstack);
	    }

	/* Bottom */
	for (tp = LB(tile); LEFT(tp) < RIGHT(tile); tp = TR(tp))
	    if (tp->ti_client != (ClientData)DRC_UNPROCESSED)
	    {
	    	 tp->ti_client = (ClientData)DRC_UNPROCESSED;
		 STACKPUSH(tp,DRCstack);
	    }

	/* Right */
	for (tp = TR(tile); TOP(tp) > BOTTOM(tile); tp = LB(tp))
	    if (tp->ti_client != (ClientData)DRC_UNPROCESSED)
	    {
	    	 tp->ti_client = (ClientData)DRC_UNPROCESSED;
		 STACKPUSH(tp,DRCstack);
	    }

     }
     return;
}

/*
 * ----------------------------------------------------------------------------
 *
 * drcCifTile --
 *
 * Results:
 *	Zero (so that the search will continue), unless an interrupt
 *	occurs, in which case 1 is returned to stop the check.
 *
 * Side effects:
 *	Calls the client's error function if errors are found.
 *
 * ----------------------------------------------------------------------------
 */

int
drcCifTile (register Tile *tile, struct drcClientData *arg)
                        	/* Tile being examined */
                              
{
    register DRCCifCookie *cptr;	/* Current design rule on list */
    register Tile *tp;		/* Used for corner checks */
    Rect *rect = arg->dCD_rect;	/* Area being checked */
    Rect errRect;		/* Area checked for an individual rule */
    TileTypeBitMask tmpMask;

    arg->dCD_constraint = &errRect;

    /*
     * If we were interrupted, we want to
     * abort the check as quickly as possible.
     */
    if (SigInterruptPending) return 1;
    DRCstatTiles++;

    /*
     * Check design rules along a vertical boundary between two tiles.
     *
     *			      1 | 4
     *				T
     *				|
     *			tpleft	|  tile
     *				|
     *				B
     *			      2 | 3
     *
     * The labels "T" and "B" indicate pointT and pointB respectively.
     *
     * If a rule's direction is FORWARD, then check from left to right.
     *
     *	    * Check the top right corner if the 1x1 lambda square
     *	      on the top left corner (1) of pointT matches the design
     *	      rule's "corner" mask.
     *
     *	    * Check the bottom right corner if the rule says check
     *	      BOTHCORNERS and the 1x1 lambda square on the bottom left
     *	      corner (2) of pointB matches the design rule's "corner" mask.
     *
     * If a rule's direction is REVERSE, then check from right to left.
     *
     *	    * Check the bottom left corner if the 1x1 lambda square
     *	      on the bottom right corner (3) of pointB matches the design
     *	      rule's "corner" mask.
     *
     *	    * Check the top left corner if the rule says check BOTHCORNERS
     *	      and the 1x1 lambda square on the top right corner (4) of
     *	      pointT matches the design rule's "corner" mask.
     */

    if (drcCifCur->drcc_flags & DRC_AREA)
    {
    	 drcCheckCifArea(tile,arg,drcCifCur);
	 return 0;
    }
    if (drcCifCur->drcc_flags & DRC_MAXWIDTH)
    {
    	 drcCheckCifMaxwidth(tile,arg,drcCifCur);
	 return 0;
    }
    if (LEFT(tile) >= rect->r_xbot)		/* check tile against rect */
    {
	register Tile *tpleft;
	int edgeTop, edgeBot;
        int top = MIN(TOP(tile), rect->r_ytop);
        int bottom = MAX(BOTTOM(tile), rect->r_ybot);
	int edgeX = LEFT(tile);

        for (tpleft = BL(tile); BOTTOM(tpleft) < top; tpleft = RT(tpleft))
        {
	    /* Don't check synthetic edges, i.e. edges with same type on
             * both sides.  Such "edges" have no physical significance, and
	     * depend on internal-details of how paint is spit into tiles.
	     * Thus checking them just leads to confusion.  (When edge rules
	     * involving such edges are encountered during technology readin
	     * the user is warned that such edges are not checked).
	     */
	    if(DBgetTileType(tpleft) == DBgetTileType(tile))
	        continue;

	    /*
	     * Go through list of design rules triggered by the
	     * left-to-right edge.
	     */
	    edgeTop = MIN(TOP (tpleft), top);
	    edgeBot = MAX(BOTTOM(tpleft), bottom);
	    if (edgeTop <= edgeBot)
		continue;

	    /* do this more intelligently later XXX */
	    cptr = drcCifCur;
	    {
		errRect.r_ytop = edgeTop;
		errRect.r_ybot = edgeBot;

		if (cptr->drcc_flags & DRC_REVERSE)
		{
		    /*
		     * Determine corner extensions.
		     * Find the point (3) to the bottom right of pointB
		     */
		    for (tp = tile; BOTTOM(tp) >= errRect.r_ybot; tp = LB(tp))
			/* Nothing */;
		    if (TTMaskHasType(&cptr->drcc_corner, DBgetTileType(tp)))
			errRect.r_ybot -= cptr->drcc_cdist;

		    if (cptr->drcc_flags & DRC_BOTHCORNERS)
		    {
			/*
			 * Check the other corner by finding the
			 * point (4) to the top right of pointT.
			 */
			if (TOP(tp = tile) <= errRect.r_ytop)
			    for (tp = RT(tp); LEFT(tp) > edgeX; tp = BL(tp))
				/* Nothing */;
			if (TTMaskHasType(&cptr->drcc_corner, DBgetTileType(tp)))
			    errRect.r_ytop += cptr->drcc_cdist;
		    }

		    /*
		     * Just for grins, see if we could avoid a messy search
		     * by looking only at tpleft.
		     */
		    errRect.r_xbot = edgeX - cptr->drcc_dist;
		    if (LEFT(tpleft) <= errRect.r_xbot
			&& BOTTOM(tpleft) <= errRect.r_ybot
			&& TOP(tpleft) >= errRect.r_ytop
			&& !(cptr->drcc_flags & DRC_XPLANE)
			&& TTMaskHasType(&cptr->drcc_mask, DBgetTileType(tpleft)))
			    continue;
		    errRect.r_xtop = edgeX;
		    arg->dCD_initial = tile;
		}
		else
		{
		    /*
		     * Determine corner extensions.
		     * Find the point (1) to the top left of pointT
		     */
		    for (tp = tpleft; TOP(tp) <= errRect.r_ytop; tp = RT(tp))
			/* Nothing */;
		    if (TTMaskHasType(&cptr->drcc_corner, DBgetTileType(tp)))
			errRect.r_ytop += cptr->drcc_cdist;

		    if (cptr->drcc_flags & DRC_BOTHCORNERS)
		    {
			/*
			 * Check the other corner by finding the
			 * point (2) to the bottom left of pointB.
			 */
			if (BOTTOM(tp = tpleft) >= errRect.r_ybot)
			    for (tp = LB(tp); RIGHT(tp) < edgeX; tp = TR(tp))
				/* Nothing */;
			if (TTMaskHasType(&cptr->drcc_corner, DBgetTileType(tp)))
			    errRect.r_ybot -= cptr->drcc_cdist;
		    }

		    /*
		     * Just for grins, see if we could avoid a messy search
		     * by looking only at tile.
		     */
		    errRect.r_xtop = edgeX + cptr->drcc_dist;
		    if (RIGHT(tile) >= errRect.r_xtop
			&& BOTTOM(tile) <= errRect.r_ybot
			&& TOP(tile) >= errRect.r_ytop
			&& !(cptr->drcc_flags & DRC_XPLANE)
			&& TTMaskHasType(&cptr->drcc_mask, DBgetTileType(tile)))
			    continue;
		    errRect.r_xbot = edgeX;
		    arg->dCD_initial= tpleft;
		}

		DRCstatSlow++;
		arg->dCD_cptr = (DRCCookie *)cptr;
		TTMaskCom2(&tmpMask, &cptr->drcc_mask);
		(void) DBPlaneEnumAreaPaint((Tile *) NULL,
		    CIFPlanes[cptr->drcc_plane],
		    &errRect, &tmpMask, areaCifCheck, (ClientData) arg);
	    }
	    DRCstatEdges++;
        }
    }


    /*
     * Check design rules along a horizontal boundary between two tiles.
     *
     *			 4	tile	    3
     *			--L----------------R--
     *			 1	tpbot	    2
     *
     * The labels "L" and "R" indicate pointL and pointR respectively.
     * If a rule's direction is FORWARD, then check from bottom to top.
     *
     *      * Check the top left corner if the 1x1 lambda square on the bottom
     *        left corner (1) of pointL matches the design rule's "corner" mask.
     *
     *      * Check the top right corner if the rule says check BOTHCORNERS and
     *        the 1x1 lambda square on the bottom right (2) corner of pointR
     *	      matches the design rule's "corner" mask.
     *
     * If a rule's direction is REVERSE, then check from top to bottom.
     *
     *	    * Check the bottom right corner if the 1x1 lambda square on the top
     *	      right corner (3) of pointR matches the design rule's "corner"
     *	      mask.
     *
     *	    * Check the bottom left corner if the rule says check BOTHCORNERS
     *	      and the 1x1 lambda square on the top left corner (4) of pointL
     *	      matches the design rule's "corner" mask.
     */

    if (BOTTOM(tile) >= rect->r_ybot)
    {
	register Tile *tpbot;
	int edgeLeft, edgeRight;
        int left = MAX(LEFT(tile), rect->r_xbot);
        int right = MIN(RIGHT(tile), rect->r_xtop);
	int edgeY = BOTTOM(tile);

	/* Go right across bottom of tile */
        for (tpbot = LB(tile); LEFT(tpbot) < right; tpbot = TR(tpbot))
        {

	    /* Don't check synthetic edges, i.e. edges with same type on
             * both sides.  Such "edges" have no physical significance, and
	     * depend on internal-details of how paint is spit into tiles.
	     * Thus checking them just leads to confusion.  (When edge rules
	     * involving such edges are encountered during technology readin
	     * the user is warned that such edges are not checked).
	     */
	    if(DBgetTileType(tpbot) == DBgetTileType(tile))
	        continue;

	    /*
	     * Check to insure that we are inside the clip area.
	     * Go through list of design rules triggered by the
	     * bottom-to-top edge.
	     */
	    edgeLeft = MAX(LEFT(tpbot), left);
	    edgeRight = MIN(RIGHT(tpbot), right);
	    if (edgeLeft >= edgeRight)
		continue;

	    cptr = drcCifCur;
	    {
		DRCstatRules++;
		errRect.r_xbot = edgeLeft;
		errRect.r_xtop = edgeRight;

		/* top to bottom */
		if (cptr->drcc_flags & DRC_REVERSE)
		{
		    /*
		     * Determine corner extensions.
		     * Find the point (3) to the top right of pointR
		     */
		    if (RIGHT(tp = tile) <= errRect.r_xtop)
			for (tp = TR(tp); BOTTOM(tp) > edgeY; tp = LB(tp))
			    /* Nothing */;
		    if (TTMaskHasType(&cptr->drcc_corner, DBgetTileType(tp)))
			errRect.r_xtop += cptr->drcc_cdist; 	

		    if (cptr->drcc_flags & DRC_BOTHCORNERS)
		    {
			/*
			 * Check the other corner by finding the
			 * point (4) to the top left of pointL.
			 */
			for (tp = tile; LEFT(tp) >= errRect.r_xbot; tp = BL(tp))
			    /* Nothing */;
			if (TTMaskHasType(&cptr->drcc_corner, DBgetTileType(tp)))
			    errRect.r_xbot -= cptr->drcc_cdist; 	
		    }

		    /*
		     * Just for grins, see if we could avoid
		     * a messy search by looking only at tpbot.
		     */
		    errRect.r_ybot = edgeY - cptr->drcc_dist;
		    if (BOTTOM(tpbot) <= errRect.r_ybot
			&& LEFT(tpbot) <= errRect.r_xbot
			&& RIGHT(tpbot) >= errRect.r_xtop
			&& !(cptr->drcc_flags & DRC_XPLANE)
			&& TTMaskHasType(&cptr->drcc_mask, DBgetTileType(tpbot)))
			    continue;
		    errRect.r_ytop = edgeY;
		    arg->dCD_initial = tile;
		}
		else
		{
		    /*
		     * Determine corner extensions.
		     * Find the point (1) to the bottom left of pointL
		     */
		    if (LEFT(tp = tpbot) >= errRect.r_xbot)
			for (tp = BL(tp); TOP(tp) < edgeY; tp = RT(tp))
			    /* Nothing */;

		    if (TTMaskHasType(&cptr->drcc_corner, DBgetTileType(tp)))
			errRect.r_xbot -= cptr->drcc_cdist;

		    if (cptr->drcc_flags & DRC_BOTHCORNERS)
		    {
			/*
			 * Check the other corner by finding the
			 * point (2) to the bottom right of pointR.
			 */
			for (tp=tpbot; RIGHT(tp) <= errRect.r_xtop; tp=TR(tp))
			    /* Nothing */;
			if (TTMaskHasType(&cptr->drcc_corner, DBgetTileType(tp)))
			    errRect.r_xtop += cptr->drcc_cdist;
		    }

		    /*
		     * Just for grins, see if we could avoid
		     * a messy search by looking only at tile.
		     */
		    errRect.r_ytop = edgeY + cptr->drcc_dist;
		    if (TOP(tile) >= errRect.r_ytop
			&& LEFT(tile) <= errRect.r_xbot
			&& RIGHT(tile) >= errRect.r_xtop
			&& !(cptr->drcc_flags & DRC_XPLANE)
			&& TTMaskHasType(&cptr->drcc_mask, DBgetTileType(tile)))
			    continue;
		    errRect.r_ybot = edgeY;
		    arg->dCD_initial = tpbot;
		}

		DRCstatSlow++;
		arg->dCD_cptr = (DRCCookie *)cptr;
		TTMaskCom2(&tmpMask, &cptr->drcc_mask);
		(void) DBPlaneEnumAreaPaint((Tile *) NULL,
		    CIFPlanes[cptr->drcc_plane],
		    &errRect, &tmpMask, areaCifCheck, (ClientData) arg);
	    }
	    DRCstatEdges++;
        }
    }
    return (0);
}
