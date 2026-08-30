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
 * gdsInfo.c --
 *
 * Rountines for generating summary information on GDS file,
 * e.g. cell defs in file and layers present etc.
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

#include <stdio.h>
#include <sys/types.h>

#include "magic.h"
#include "geometry.h"
#include "tile.h"
#include "utils.h"
#include "hash.h"
#include "database.h"
#include "databaseInt.h"
#include "malloc.h"
#include "main.h"
#include "cif.h"
#include "cifInt.h"
#include "cifRead.h"
#include "signal.h"
#include "layout.h"
#include "layout.h"
#include "styles.h"
#include "message.h"
#include "gdsInt.h"

/* entrys for layer hash table */
typedef struct gdsinfolayer
{
  CalmaLayerType gil_clt;            /* layer/type numbers */  
  int gil_boundarys;                 /* number of boundary elements */
  int gil_paths;                     /* number of paths */
  int gil_texts;                     /* number of text elements */
  struct gdsinfolayer *gil_hashLink; /* hash table link */
  struct gdsinfolayer *gil_next;     
  
} GdsInfoLayer;

static GdsInfoLayer *gdsInfoLayers = NULL;
static IHashTable *gdsInfoLayersHashTable = NULL;

/* entrys for subcells hash table */
typedef struct gdsinfosubcell
{
  char *gis_name;            /* subcell name */
  int gis_number;            /* number of instances */
  struct gdsinfosubcell *gis_hashLink; /* hash table link */
  struct gdsinfosubcell *gis_next;     
  
} GdsInfoSubcell;

/* census of property attributes in sref's */
static gdsInfoInstanceProps[128];

static GdsInfoSubcell *gdsInfoSubcells = NULL;
static IHashTable *gdsInfoSubcellsHashTable = NULL;

/* tcl interpeter to send results to */
static Tcl_Interp *gdsInfoInterp;

static bool gdsInfoDefFound; /* set when first def encountered */
static bool gdsInfoElement;  /* set to current element type */
static int gdsInfoLayer = 0;
static int gdsInfoType = 0;

static void gdsInfoInstancePropsClear(void)
{
  int i;
  for(i=0;i<128;i++) gdsInfoInstanceProps[i] = 0;
}

/* print instance property info */
static void gdsInfoInstancePropsPrint()
{
  char buf[BUFSIZ];
  int i;

  Tcl_AppendResult(gdsInfoInterp,"    {instance_properties\n", NULL);
  Tcl_AppendResult(gdsInfoInterp,"     {\n", NULL);

  for(i=0; i<128; i++)
  {
    if(gdsInfoInstanceProps[i]==0) continue;
    sprintf(buf,"      {%d %d}\n", 
	    i,
	    gdsInfoInstanceProps[i]);
    Tcl_AppendResult(gdsInfoInterp,buf, NULL);
  }

  Tcl_AppendResult(gdsInfoInterp,"     }\n", NULL);
  Tcl_AppendResult(gdsInfoInterp,"    }\n", NULL);
}

/* remove all gdsInfoLayers */
static void gdsInfoLayersClear()
{
  while(gdsInfoLayers)
  {
    GdsInfoLayer *gil = gdsInfoLayers;

    gdsInfoLayers = gil->gil_next;

    IHashDelete(gdsInfoLayersHashTable, gil);
    FREE_TAG(gil,"GdsInfoLayer");
  }
}

/* find a gdsInfoLayer, creating new one if necessary */
static GdsInfoLayer *gdsInfoLayerFind(int layer, int type)
{
  CalmaLayerType clt;
  GdsInfoLayer *gil;

  clt.clt_layer = layer;
  clt.clt_type = type;
  
  gil = IHashLookUp(gdsInfoLayersHashTable, &clt);
  if(gil) return gil;

  CALLOC_TAG(GdsInfoLayer *, gil, sizeof(*gil),"GdsInfoLayer");
  gil->gil_clt = clt;
  gil->gil_next = gdsInfoLayers;
  gdsInfoLayers = gil;

  IHashAdd(gdsInfoLayersHashTable, gil);
  return gil;
}

/* print layer info */
static void gdsInfoLayersPrint()
{
  char buf[BUFSIZ];
  GdsInfoLayer *gil;

  Tcl_AppendResult(gdsInfoInterp,"    {layers\n", NULL);
  Tcl_AppendResult(gdsInfoInterp,"     {\n", NULL);

  for(gil=gdsInfoLayers; gil; gil=gil->gil_next)
  {
    sprintf(buf,"      {%d %d %d %d %d}\n", 
	    gil->gil_clt.clt_layer,
	    gil->gil_clt.clt_type,
	    gil->gil_boundarys,
	    gil->gil_paths,
	    gil->gil_texts);
    Tcl_AppendResult(gdsInfoInterp,buf, NULL);
  }

  Tcl_AppendResult(gdsInfoInterp,"     }\n", NULL);
  Tcl_AppendResult(gdsInfoInterp,"    }\n", NULL);
}

/* hash for layer table */
static int gdsInfoCLTHash(void *keyp)
{
  CalmaLayerType *clt = keyp;

  return clt->clt_layer + clt->clt_type;
}

/* compare for layer numbers */
static int gdsInfoCLTEq(void *key1p, void *key2p)
{
  CalmaLayerType *clt1 = key1p;
  CalmaLayerType *clt2 = key2p;
  return ((clt1->clt_layer == clt2->clt_layer) && 
	  (clt1->clt_type == clt2->clt_type));
}

/* remove all gdsInfoSubcells */
static void gdsInfoSubcellsClear()
{
  while(gdsInfoSubcells)
  {
    GdsInfoSubcell *gis = gdsInfoSubcells;

    gdsInfoSubcells = gis->gis_next;

    IHashDelete(gdsInfoSubcellsHashTable, gis);
    StrDup(&gis->gis_name,NULL); /* free name string */
    FREE_TAG(gis,"GdsInfoSubcell");
  }
}

/* find a gdsInfoSubcell, creating new one if necessary */
static GdsInfoSubcell *gdsInfoSubcellFind(char *name)
{
  GdsInfoSubcell *gis;

  gis = IHashLookUp(gdsInfoSubcellsHashTable, &name);
  if(gis) return gis;

  CALLOC_TAG(GdsInfoLayer *, gis, sizeof(*gis),"GdsInfoSubcell");
  gis->gis_name = StrDup(NULL, name);
  gis->gis_next = gdsInfoSubcells;
  gdsInfoSubcells = gis;

  IHashAdd(gdsInfoSubcellsHashTable, gis);
  return gis;
}

/* print subcells info */
static void gdsInfoSubcellsPrint()
{
  char buf[BUFSIZ];
  GdsInfoSubcell *gis;

  Tcl_AppendResult(gdsInfoInterp,"    {subcells\n", NULL);
  Tcl_AppendResult(gdsInfoInterp,"     {\n", NULL);

  for(gis=gdsInfoSubcells; gis; gis=gis->gis_next)
  {
    /* TODO proper quoting for subcell name */
    sprintf(buf,"      {%s %d}\n", 
	    gis->gis_name,
	    gis->gis_number);
    Tcl_AppendResult(gdsInfoInterp,buf, NULL);
  }

  Tcl_AppendResult(gdsInfoInterp,"     }\n", NULL);
  Tcl_AppendResult(gdsInfoInterp,"    }\n", NULL);
}

 __inline__ bool gdsInfoReadHeader(int *nbytes, int *rtype, int *dtype)
{
  READI2(*nbytes);

  if(gdsRdEOF) goto eof;

  if(*nbytes < 4)
  {
    MsgWarnF("bad GDS-II record size:  %d\n", *nbytes);
    return FALSE;
  }
  
  {
    unsigned char tmp;

    gdsReadBytes(&tmp,1);
    *rtype = tmp;
    gdsReadBytes(&tmp,1);
    *dtype = tmp;
  }

  if(gdsRdEOF) goto eof;

  return TRUE;

eof:
   MsgWarnF("unexpected EOF while reading GDS-II record header\n");
   return FALSE;
}

/* process a gds record */
#define CHECK_EOF if(gdsRdEOF) goto eof
static __inline__ bool gdsInfoRecord()
{
  char buf[BUFSIZ]; /* temporary buffer for formatting output */

  int nbytes;  /* record size (left unprocessed) in bytes */ 
  int rtype;   /* record type */ 
  int dtype;   /* type of data in record */
  int dsize;   /* number of data elements in record */

  /* pointers to record data contents */
  static char *charData = NULL;
  static int *intData = NULL;
  static double *doubleData = NULL;

  /* free data from last record */
  if(charData) { FREE(charData); charData = NULL; }
  if(intData) { FREE(intData); intData = NULL; }
  if(doubleData) { FREE(doubleData); doubleData = NULL; }

  if(!gdsInfoReadHeader(&nbytes, &rtype, &dtype)) return FALSE;

  /* output any error comments and set dsize */  
  nbytes -=  CALMAHEADERLENGTH;
  if(rtype>=CALMA_NUMRECORDTYPES)
    MsgWarnF("unrecognized record type in GDS-II file: %d\n", rtype);
  if(dtype>6)
  {
    dsize = 0;
    MsgWarnF("unrecognized data type in GDS-II file: %d\n", dtype);
  }
  else
  {
    dsize = nbytes/gdsDataTypeSizes[dtype];
    if(nbytes%gdsDataTypeSizes[dtype] !=0) 
    {
      MsgWarnF("data size of GDS-II record not multipe of type size\n", 
	       dtype);
    }
  }
	
  /* read record data */
  switch (dtype)
  {
    case CALMA_NODATA:
    if(nbytes!=0) 
    {
      MsgWarnF("%d data bytes on GDS-II no_data record\n", nbytes);
    }

    /* skip any data bytes! */
    if(nbytes>0) calmaSkipBytes(nbytes);
    break;

    case CALMA_I2:
    {
      int *ip;
      MALLOC(int *, intData, sizeof(int)*nbytes/2);
      ip = intData;

      while(nbytes>=2)
      {
        READI2(*ip); 
	CHECK_EOF; 
	nbytes -=2;
        ip++;
      }
    }
    break;

    case CALMA_I4:
    {
      int *ip;

      MALLOC(int *, intData, sizeof(int)*nbytes/4);
      ip = intData;

      while(nbytes>=4)
      {
        READI4(*ip); 
	CHECK_EOF; 
	nbytes -=4;
	ip++;
      }
    }
    break;

    case CALMA_R8:
    {
      double *dp;
      MALLOC(double *, doubleData, sizeof(double)*nbytes/8);

      dp = doubleData;

      while(nbytes>=8)
      {
        if(!calmaReadR8(dp)) goto eof; 
	nbytes -=8;
	dp++;
      }
    }
    break;

    case CALMA_ASCII:  
    {
      if(nbytes>GDS_STRING_LENGTH)
	MsgWarnF("GDS-II string length %d exceeds limit of %d\n",
		 nbytes, GDS_STRING_LENGTH);

      MALLOC(char *, charData, sizeof(char)*(nbytes+1));
      if(!gdsReadBytes(charData,nbytes)) goto eof;
      charData[nbytes] = '\0';
    }
    break;
    
    default:
    /* skip data bytes */
    if(nbytes>0) calmaSkipBytes(nbytes);
  }

  /* process record */
  switch (rtype)  
  {
    case CALMA_HEADER:      
      sprintf(buf, " {format_version %d}\n", intData[0]);
      Tcl_AppendResult(gdsInfoInterp, buf, NULL);
      break;

    case CALMA_BGNLIB:      
      sprintf(buf, " {last_modified \"%d/%d/%d %d:%d:%d\"}\n",
	      intData[1], intData[2], intData[0],
	      intData[3], intData[4], intData[5]);
      Tcl_AppendResult(gdsInfoInterp, buf, NULL);
      sprintf(buf, " {last_accessed \"%d/%d/%d %d:%d:%d\"}\n",
	      intData[7], intData[8], intData[6],
	      intData[9], intData[10], intData[11]);
      Tcl_AppendResult(gdsInfoInterp, buf, NULL);
      break;

    case CALMA_UNITS:
      if(dtype!=CALMA_R8 || dsize != 2)
      {
        MsgWarnF("bad GDS-II UNITS record.\n\n");
      }
      else
      {
        sprintf(buf,
		" {units_in_microns %g}\n",
		doubleData[1]*1.0E6);
	Tcl_AppendResult(gdsInfoInterp, buf, NULL);
      }
      break;

    case CALMA_LIBNAME:
      Tcl_AppendResult(gdsInfoInterp, 
		       " {lib_name ", charData, "}\n", NULL);
      break;

    case CALMA_BGNSTR:      
      if(!gdsInfoDefFound)
      {
	gdsInfoDefFound = TRUE;
	Tcl_AppendResult(gdsInfoInterp, 
			 " {cell_defs\n",
			 "  {\n",
			 NULL);
      }

      Tcl_AppendResult(gdsInfoInterp, "   {\n", NULL);

      /* initialize per def stats */
      gdsInfoLayersClear();
      gdsInfoSubcellsClear();
      gdsInfoInstancePropsClear();

      break;

    case CALMA_ENDSTR:      
      gdsInfoSubcellsPrint();
      gdsInfoInstancePropsPrint();
      gdsInfoLayersPrint();


      Tcl_AppendResult(gdsInfoInterp, "   }\n", NULL);
      break;

    case CALMA_STRNAME:   
      Tcl_AppendResult(gdsInfoInterp, 
		       "    {name ", charData, "}\n", NULL);
      break;

    case CALMA_SNAME:   
      {
	GdsInfoSubcell *gis;
	gis = gdsInfoSubcellFind(charData);
	gis->gis_number++;
      }
      break;

    case CALMA_PROPATTR:
      if(gdsInfoElement != CALMA_SREF) break;
      if(*intData<0 || *intData>127) break;
      gdsInfoInstanceProps[*intData]++;
      break;

      /* elements */
    case CALMA_BOUNDARY:   
    case CALMA_BOX:   
    case CALMA_PATH:   
    case CALMA_SREF:      
    case CALMA_AREF:      
    case CALMA_TEXT:   
      gdsInfoElement = rtype;
      break;
      
    case CALMA_ENDEL:
      if(gdsInfoElement == CALMA_BOUNDARY ||
	 gdsInfoElement == CALMA_BOX)
      {
	GdsInfoLayer *gil;
	gil = gdsInfoLayerFind(gdsInfoLayer, gdsInfoType);
	gil->gil_boundarys++;
      } 
      else if (gdsInfoElement == CALMA_PATH)
      {
	GdsInfoLayer *gil;
	gil = gdsInfoLayerFind(gdsInfoLayer, gdsInfoType);
	gil->gil_paths++;
      } 
      else if (gdsInfoElement == CALMA_TEXT)
      {
	GdsInfoLayer *gil;
	gil = gdsInfoLayerFind(gdsInfoLayer, gdsInfoType);
	gil->gil_texts++;
      } 
      gdsInfoElement = 0;
      gdsInfoLayer = 0;
      gdsInfoType = 0;
      break;

    case CALMA_LAYER:   
      if(intData)
      {
	gdsInfoLayer = *intData;
      }
      else
      {
	gdsInfoLayer = 0;
	MsgWarnF("Bad GDS-II layer\n");
      }
      break;

    case CALMA_DATATYPE:   
      if(intData)
      {
	gdsInfoType = *intData;
      }
      else
      {
	gdsInfoType = 0;
	MsgWarnF("Bad GDS-II layer type\n");
      }
      break;

    case CALMA_TEXTTYPE:   
      if(intData)
      {
	gdsInfoType = *intData;
      }
      else
      {
	gdsInfoType = 0;
	MsgWarnF("Bad GDS-II text type\n");
      }
      break;

    case CALMA_ENDLIB:

      return(FALSE);  /* done */
      break;
  }

  return (TRUE);

eof:
      MsgErrorF("premature end of file while reading gdsII\n");
      return(FALSE);
}


/*
 * ----------------------------------------------------------------------------
 *
 * gdsInfo
 *
 * read gds file and generate summary info
 *
 * ----------------------------------------------------------------------------
 */

void
gdsInfo(Tcl_Interp *interp, /* results to interp return value */
	int inFD)           /* open file descriptor of GDS-II file */
{
  gdsInfoInterp = interp;
  gdsInfoDefFound = FALSE;

  gdsReadIOInit(inFD);

  /* create hash tables */
  gdsInfoLayersHashTable = 
    IHashInit(256, 
	      OFFSET(GdsInfoLayer,gil_clt), /* key */ 
	      OFFSET(GdsInfoLayer,gil_hashLink),
	      gdsInfoCLTHash, 
	      gdsInfoCLTEq);
  gdsInfoSubcellsHashTable = 
    IHashInit(256, 
	      OFFSET(GdsInfoSubcell,gis_name), /* key */ 
	      OFFSET(GdsInfoSubcell,gis_hashLink),
	      IHashStringPKeyHash, 
	      IHashStringPKeyEq); 

  Tcl_AppendResult(interp,"{\n",NULL);
  while(gdsInfoRecord());
  if(gdsInfoDefFound) Tcl_AppendResult(gdsInfoInterp, 
				       "  }\n", 
				       " }\n", 
				       NULL);
  Tcl_AppendResult(interp,"}",NULL);

  /* delete gds layers, and hash table */
  gdsInfoSubcellsClear();
  IHashFree(gdsInfoSubcellsHashTable);
  gdsInfoLayersClear();
  IHashFree(gdsInfoLayersHashTable);
}









