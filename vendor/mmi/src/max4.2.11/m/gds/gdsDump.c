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
 * gdsDump.c --
 *
 * Rountines for converting gds stream to ascii format 
 * (see gdsCompile.c for inverse.)
 *
 * For debugging.
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

FILE *gdsDumpFile;
int gdsDumpVerbose;

/* gen max error, and copy message to dump file as well */
static void
gdsDumpErrorF(char *fmt, ...)
{
    va_list args;
    va_start(args,fmt);

    fprintf(gdsDumpFile, "\n#");
    vfprintf(gdsDumpFile, fmt, args);
    MsgErrorV(fmt, args);

    va_end(args);
}

static __inline__ bool gdsDumpReadHeader(int *nbytes, int *rtype, int *dtype)
{
  READI2(*nbytes);

  if(gdsRdEOF) goto eof;

  if(*nbytes < 4)
  {
    gdsDumpErrorF("error, bad gds record size:  %d\n", *nbytes);
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
   gdsDumpErrorF("unexpected EOF while reading gds record header\n");
   /* raise(SIGSEGV);  DEBUG CORE DUMP */
   return FALSE;
}

#define CHECK_EOF if(gdsRdEOF) goto eof
static __inline__ bool gdsDumpRecord()
{
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

  if(!gdsDumpReadHeader(&nbytes, &rtype, &dtype)) return FALSE;

  /* output record size and data type comment */
  if(gdsDumpVerbose)
  {
    fprintf(gdsDumpFile,"#%d byte record, ", nbytes);
    if(dtype<=6)
    {
      fprintf(gdsDumpFile,"data type %s ", gdsDataTypes[dtype]);
    }
    else
    {
      fprintf(gdsDumpFile,"data type %d\n",dtype);
    }

  }

  /* output any error comments and set dsize */  
  nbytes -=  CALMAHEADERLENGTH;
  if(rtype>=CALMA_NUMRECORDTYPES)
    fprintf(gdsDumpFile,"#ERROR, unrecognized record type: %d\n", rtype);
  if(dtype>6)
  {
    dsize = 0;
    fprintf(gdsDumpFile,"#ERROR, unrecognized data type: %d\n", dtype);
  }
  else
  {
    dsize = nbytes/gdsDataTypeSizes[dtype];
    if(nbytes%gdsDataTypeSizes[dtype] !=0) 
	fprintf(gdsDumpFile,"#ERROR, data size not multipe of type size\n", dtype);
  }
  
  /* output record type */
  if(rtype<CALMA_NUMRECORDTYPES)
  {
    fprintf(gdsDumpFile,"%s", gdsRecordTypes[rtype].grt_name);
  }
  else
  {
    fprintf(gdsDumpFile,"%d",rtype);
  }
	
  /* read/write data */
  switch (dtype)
  {
    case CALMA_NODATA:
    if(nbytes!=0) 
    {
      fprintf(gdsDumpFile," #ERROR %d data bytes on no_data record", nbytes);
    }

    /* skip any data bytes! */
    if(nbytes>0) calmaSkipBytes(nbytes);
    break;

     case CALMA_BITARRAY:
    {
      int *ip;
      MALLOC(int *, intData, sizeof(int)*nbytes/2);
      ip = intData;

      while(nbytes>=2)
      {
        READ_BITARRAY(*ip); 
	CHECK_EOF; 
        fprintf(gdsDumpFile," %#o", *ip);
	nbytes -=2;
        ip++;
      }
    }
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
        fprintf(gdsDumpFile," %d", *ip);
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
        fprintf(gdsDumpFile," %d", *ip);
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
        fprintf(gdsDumpFile," %g", *dp);
	nbytes -=8;
	dp++;
      }
    }
    break;

    case CALMA_ASCII:  
    {
      char string[BUFSIZ];

      if(nbytes>GDS_STRING_LENGTH)
	fprintf(gdsDumpFile,"#ERROR, string length %d exceeds calma limit of %d\n",
		nbytes, GDS_STRING_LENGTH);

      MALLOC(char *, charData, sizeof(char)*(nbytes+1));
      if(!gdsReadBytes(charData,nbytes)) goto eof;
      charData[nbytes] = '\0';

      /* output quoted printable string */
      StrQuote(charData,string);
      fprintf(gdsDumpFile," %s", string);
    }
    break;
    
    default:
    /* output ? */
    fprintf(gdsDumpFile," ?");
    /* skip data bytes */
    if(nbytes>0) calmaSkipBytes(nbytes);
  }
  
  /* close record */
  fprintf(gdsDumpFile,"\n");

  /* process record - as desired */
  switch (rtype)  
  {
    case CALMA_HEADER:      
      fprintf(gdsDumpFile,"# GDSII Stream Format, Version %d\n\n",
	      intData[0]);
      break;

    case CALMA_BGNLIB:      
      fprintf(gdsDumpFile, "# library last modified %d/%d/%d %d:%d:%d, "
	      "last accessed %d/%d/%d %d:%d:%d\n",
	      intData[1], intData[2], intData[0],
	      intData[3], intData[4], intData[5],
	      intData[7], intData[8], intData[6],
	      intData[9], intData[10], intData[11]);
      break;

    case CALMA_UNITS:
      if(dtype!=CALMA_R8 || dsize != 2)
      {
        gdsDumpErrorF("bad GDSII UNITS record.\n\n");
      }
      else
      {
        fprintf(gdsDumpFile,
		"# units = %g microns (normally 0.001 microns)\n\n",
		doubleData[1]*1.0E6);
      }
      break;

    case CALMA_BGNSTR:      
      fprintf(gdsDumpFile, "# definition created %d/%d/%d %d:%d:%d, "
	      "last modified %d/%d/%d %d:%d:%d\n",
	      intData[1], intData[2], intData[0],
	      intData[3], intData[4], intData[5],
	      intData[7], intData[8], intData[6],
	      intData[9], intData[10], intData[11]);
      break;

    case CALMA_ENDEL:
      fprintf(gdsDumpFile,"\n");
      break;

    case CALMA_ENDSTR:      
      fprintf(gdsDumpFile,"\n#-----\n\n");
      break;

    case CALMA_ENDLIB:
      return(FALSE);  /* done */
      break;


  }

  return (TRUE);

eof:
      gdsDumpErrorF("premature end of file while reading gdsII\n");
      return(FALSE);
}


/*
 * ----------------------------------------------------------------------------
 *
 * gdsDump
 *
 * read gds file and write ascii equivalent.
 *
 * ----------------------------------------------------------------------------
 */

void
gdsDump(int inFD, FILE *out, int verbose)
{
  gdsReadIOInit(inFD);
  gdsDumpFile = out;
  gdsDumpVerbose = verbose;

  /* write file header comment */
  fprintf(gdsDumpFile,
	  "# This file was generated by Max.\n"
	  "# It is an ASCII translation of a GDSII format binary file.\n\n"
	  );

  while(gdsDumpRecord());
}








