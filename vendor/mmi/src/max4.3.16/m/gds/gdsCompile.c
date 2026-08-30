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
 * gdsCompile.c --
 *
 * Rountines for converting gds ascii 'dump' to binary gds format 
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>

#include "magic.h"
#include "geometry.h"
#include "tile.h"
#include "utils.h"
#include "hash.h"
#include "database.h"
#include "databaseInt.h"
#include "memory.h"
#include "main.h"
#include "cif.h"
#include "cifInt.h"
#include "cifRead.h"
#include "signal.h"
#include "styles.h"
#include "message.h"
#include "gdsInt.h"

#define GDS_MAX_ARGS 1000


/*
 * ----------------------------------------------------------------------------
 *
 * gdsCompileReadLine
 *
 * read line from input file into buffer
 *
 * ----------------------------------------------------------------------------
 */

static bool
gdsCompileReadLine(FILE *in, char *buf, int max)
{
  if(feof(in)) return FALSE;
  return (fgets(buf,max,in)!=NULL);
}

/*
 * ----------------------------------------------------------------------------
 *
 * gdsCompileRecordNoData --
 *
 * Process a no data record.
 *
 * ----------------------------------------------------------------------------
 */

static void
gdsCompileRecordNoData(int recordType, 
		       char *args)
{

  /* make sure no data present */
  if(strtok(args,"\t\n "))
  {
    MsgWarnF("Data given for no_data record type, ignored.\n");
  }

  calmaOutRH(4, recordType, CALMA_NODATA);
}


/*
 * ----------------------------------------------------------------------------
 *
 * gdsCompileRecordBitArray --
 *
 * Process record of datatype bitarray (unsigned 2 byte int)
 *
 * ----------------------------------------------------------------------------
 */

static void
gdsCompileRecordBitArray(int recordType, 
		   char *args)
{
  int data[GDS_MAX_ARGS];
  int num = 0;
  int i;
  char *arg;

  /* convert args */
  for(arg=strtok(args," \t\n"); arg; arg=strtok(NULL," \t\n"))
  {
    char *end;
    data[num++] = strtol(arg,&end,0);
    if(*end!='\0' || data[num-1] < 0 || data[num-1] >= 1<<16) 
    {
      MsgWarnF("bad bit array value:  '%s'\n", arg);
    }

    if(num==GDS_MAX_ARGS)
    {
      MsgWarnF("Too many args.\n");
      break;
    }
  }

  calmaOutRH(4+2*num, recordType, CALMA_BITARRAY);
  for(i=0;i<num;i++) calmaOutBitArray(data[i]);
}


/*
 * ----------------------------------------------------------------------------
 *
 * gdsCompileRecordI2 --
 *
 * Process record of datatype I2
 *
 * ----------------------------------------------------------------------------
 */

static void
gdsCompileRecordI2(int recordType, 
		   char *args)
{
  int data[GDS_MAX_ARGS];
  int num = 0;
  int i;
  char *arg;

  /* convert args */
  for(arg=strtok(args," \t\n"); arg; arg=strtok(NULL," \t\n"))
  {
    char *end;
    data[num++] = strtol(arg,&end,0);
    if(*end!='\0') MsgWarnF("bad integer value:  '%s'\n", arg);

    if(num==GDS_MAX_ARGS)
    {
      MsgWarnF("Too many args.\n");
      break;
    }
  }

  calmaOutRH(4+2*num, recordType, CALMA_I2);
  for(i=0;i<num;i++) calmaOutI2(data[i]);
}


/*
 * ----------------------------------------------------------------------------
 *
 * gdsCompileRecordI4 --
 *
 * Process record of datatype I4
 *
 * ----------------------------------------------------------------------------
 */

static void
gdsCompileRecordI4(int recordType, 
		   char *args)
{
  int data[GDS_MAX_ARGS];
  int num = 0;
  int i;
  char *arg;

  /* convert args */
  for(arg=strtok(args," \t\n"); arg; arg=strtok(NULL," \t\n"))
  {
    char *end;
    data[num++] = strtol(arg,&end,0);
    if(*end!='\0') MsgWarnF("bad integer value:  '%s'\n", arg);

    if(num==GDS_MAX_ARGS)
    {
      MsgWarnF("Too many args.\n");
      break;
    }
  }

  calmaOutRH(4+4*num, recordType, CALMA_I4);
  for(i=0;i<num;i++) calmaOutI4(data[i]);
}

/*
 * ----------------------------------------------------------------------------
 *
 * gdsCompileRecordR4 --
 *
 * Process record of datatype R4
 *
 * ----------------------------------------------------------------------------
 */

static void
gdsCompileRecordR4(int recordType, 
		   char *args)
{
  double data[GDS_MAX_ARGS];
  int num = 0;
  int i;
  char *arg;

  /* convert args */
  for(arg=strtok(args," \t\n"); arg; arg=strtok(NULL," \t\n"))
  {
    char *end;
    data[num++] = strtod(arg,&end);
    if(*end!='\0') MsgWarnF("bad floating point value:  '%s'\n", arg);

    if(num==GDS_MAX_ARGS)
    {
      MsgWarnF("Too many args.\n");
      break;
    }
  }

  calmaOutRH(4+4*num, recordType, CALMA_R8);
  for(i=0;i<num;i++) 
  {
    calmaOutR4(data[i]);
  }
}

/*
 * ----------------------------------------------------------------------------
 *
 * gdsCompileRecordR8 --
 *
 * Process record of datatype R8
 *
 * ----------------------------------------------------------------------------
 */

static void
gdsCompileRecordR8(int recordType, 
		   char *args)
{
  double data[GDS_MAX_ARGS];
  int num = 0;
  int i;
  char *arg;

  /* convert args */
  for(arg=strtok(args," \t\n"); arg; arg=strtok(NULL," \t\n"))
  {
    char *end;
    data[num++] = strtod(arg,&end);
    if(*end!='\0') MsgWarnF("bad floating point value:  '%s'\n", arg);

    if(num==GDS_MAX_ARGS)
    {
      MsgWarnF("Too many args.\n");
      break;
    }
  }

  calmaOutRH(4+8*num, recordType, CALMA_R8);
  for(i=0;i<num;i++) 
  {
    calmaOutR8(data[i]);
  }
}

/*
 * ----------------------------------------------------------------------------
 *
 * gdsCompileRecordASCII --
 *
 * Process record of datatype ASCII
 *
 * ----------------------------------------------------------------------------
 */

static void
gdsCompileRecordASCII(int recordType, 
		      char *args)
{
  int data[GDS_MAX_ARGS];
  char string[BUFSIZ];
  int length;
  
  /* extract string from args */
  {
    char *p;

    if(strlen(args) > BUFSIZ-1)
    {
      MsgWarnF("ASCII string arg way too long!, ignoring record.", 
	       BUFSIZ-1);
      return;
    }

    p = StrQuoteParse(args,string);

    if(!p) MsgWarnF("Bad ASCII string:  '%s'\n", args);
    
    while(p && *p!='\0')
    {
      if(*p!='\t' && *p!='\n' && *p!=' ')
      {
	MsgWarnF("Extraneous args following ASCII string:  '%s'\n", p);
	break;
      }
      p++;
    }
  }
   
  /* get length */
  length = strlen(string);
  if (length > CALMANAMELENGTH)
  {
    MsgWarnF("ASCII string, '%s' > %d long, truncating.\n", string);
  }

  /* write the record out */
  calmaOutStringRecord(recordType, string);
}
 

/*
 * ----------------------------------------------------------------------------
 *
 * gdsCompileRecord --
 *
 * process one record (= one line)
 *
 * ----------------------------------------------------------------------------
 */

static void
gdsCompileRecord(char *p)
{
  char *recordName;
  char *recordArgs;
  int args;
  int i;
  int recordType;
  int dataType;

  recordName = strtok(p," \t\n");
  recordArgs = strtok(NULL,"");

  /* look up record type */
  recordType = -1;
  for(i=0;i<CALMA_NUMRECORDTYPES;i++)
  {
    if(strcmp(gdsRecordTypes[i].grt_name,recordName) == 0)
    {
      recordType = i;
      break;
    }
  }
  if(recordType<0)
  {
    MsgWarnF("Unrecognized record type, '%s', ignored!\n",
	     recordName);
    return;
  }

  /* process record according to its datatype */
  dataType = gdsRecordTypes[i].grt_dataType;
  switch (dataType)
  {
    case CALMA_NODATA:
      gdsCompileRecordNoData(recordType,recordArgs);
      break;

    case CALMA_BITARRAY:
      gdsCompileRecordBitArray(recordType,recordArgs);
      break;

    case CALMA_I2:
      gdsCompileRecordI2(recordType,recordArgs);
      break;

    case CALMA_I4:
      gdsCompileRecordI4(recordType,recordArgs);
      break;

    case CALMA_R4:
      gdsCompileRecordR4(recordType,recordArgs);
      break;

    case CALMA_R8:
      gdsCompileRecordR8(recordType,recordArgs);
      break;

    case CALMA_ASCII:  
      gdsCompileRecordASCII(recordType,recordArgs);
      break;
    
    default:
      ASSERT(FALSE,"gdsCompileRecord");
  }
}


/*
 * ----------------------------------------------------------------------------
 *
 * gdsCompile --
 *
 * read gds ascii file and write binary equivalent.
 *
 * ----------------------------------------------------------------------------
 */

void
gdsCompile(FILE *in, FILE *out)
{
  char line[BUFSIZ];

  /* setup gds output */
  gdsWriteIOInit(out);

  while(gdsCompileReadLine(in,line,BUFSIZ))
  {
    char *p = line;

    /* skip leading white space */
    while(*p ==' ' || *p == '\t') p++;

    /* skip comments */
    if(*p == '#') continue;

    /* skip blank lines  */
    if(*p == '\n' || *p == '\0') continue;

    gdsCompileRecord(p);
  }
}








