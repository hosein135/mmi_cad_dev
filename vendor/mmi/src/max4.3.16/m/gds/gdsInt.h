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
 * gdsInt.h --
 *
 * This file defines constants used internally by the gds
 * module, but not exported to the rest of the world.
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
 *
 * rcsid $Header: gdsInt.h,v 6.0 90/08/28 18:03:53 mayo Exp $
 */
#ifndef _GDSINT
#define _GDSINT

#include <math.h>

#ifndef	_MAGIC
#include "magic.h"
#endif	_MAGIC
#ifndef	_HASH
#include "hash.h"
#endif	_HASH
#ifndef	_DATABASE
#include "database.h"
#endif	_DATABASE
#ifndef	_GEOMETRY
#include "geometry.h"
#endif	_GEOMETRY

/* used to define gds record type names and data types */
typedef struct gdsrecordtype
{
  char *grt_name;
  int grt_dataType;  
} GDSRecordType;

/* Record data types */
#define CALMA_NODATA	0	/* No data present */
#define CALMA_BITARRAY	1	/* Bit array */
#define CALMA_I2	2	/* 2 byte integer */
#define CALMA_I4	3	/* 4 byte integer */
#define CALMA_R4	4	/* 4 byte real */
#define CALMA_R8	5	/* 8 byte real */
#define CALMA_ASCII	6	/* ASCII string */

/* Record types */
#define CALMA_EOF              -1  /* returned by READRH when at end of file */
#define CALMA_HEADER		0
#define CALMA_BGNLIB		1
#define CALMA_LIBNAME		2
#define CALMA_UNITS		3
#define CALMA_ENDLIB		4
#define CALMA_BGNSTR		5
#define CALMA_STRNAME		6
#define CALMA_ENDSTR		7
#define CALMA_BOUNDARY		8
#define CALMA_PATH		9
#define CALMA_SREF		10
#define CALMA_AREF		11
#define CALMA_TEXT		12
#define CALMA_LAYER		13
#define CALMA_DATATYPE		14
#define CALMA_WIDTH		15
#define CALMA_XY		16
#define CALMA_ENDEL		17
#define CALMA_SNAME		18
#define CALMA_COLROW		19
#define CALMA_TEXTNODE		20
#define CALMA_NODE		21
#define CALMA_TEXTTYPE		22
#define CALMA_PRESENTATION	23
#define CALMA_SPACING		24
#define CALMA_STRING		25
#define CALMA_STRANS		26
#define CALMA_MAG		27
#define CALMA_ANGLE		28
#define CALMA_UINTEGER		29
#define CALMA_USTRING		30
#define CALMA_REFLIBS		31
#define CALMA_FONTS		32
#define CALMA_PATHTYPE		33
#define CALMA_GENERATIONS	34
#define CALMA_ATTRTABLE		35
#define CALMA_STYPTABLE		36
#define CALMA_STRTYPE		37
#define CALMA_ELFLAGS		38
#define CALMA_ELKEY		39
#define CALMA_LINKTYPE		40
#define CALMA_LINKKEYS		41
#define CALMA_NODETYPE		42
#define CALMA_PROPATTR		43
#define CALMA_PROPVALUE		44
#define CALMA_BOX		45
#define CALMA_BOXTYPE		46
#define CALMA_PLEX		47
#define CALMA_BGNEXTN		48
#define CALMA_ENDEXTN		49
#define CALMA_TAPENUM		50
#define CALMA_TAPECODE		51
#define CALMA_STRCLASS		52
#define CALMA_RESERVED		53
#define CALMA_FORMAT		54
#define CALMA_MASK		55
#define CALMA_ENDMASKS		56
#define CALMA_LIBDIRSIZE	57
#define CALMA_SRFNAME		58
#define CALMA_LIBSECUR		59
#define CALMA_BORDER            60
#define CALMA_SOFTFENCE         61
#define CALMA_HARDFENCE         62
#define CALMA_SOFTWIRE          63
#define CALMA_HARDWIRE          64
#define CALMA_PATHPORT          65
#define CALMA_NODEPORT          66
#define CALMA_USERCONSTRAINT    67
#define CALMA_SPACERERROR       68
#define CALMA_CONTACT           69

#define	CALMA_NUMRECORDTYPES	70	/* Number of above types */

/* Flags for transforms */
#define	CALMA_STRANS_UPSIDEDOWN	0x8000	/* Mirror about X axis before rot */
#define	CALMA_STRANS_ROTATE	0x0002	/* Rotate by absolute angle */

/* Path types */
#define	CALMAPATH_SQUAREFLUSH	0	/* Square end flush with endpoint */
#define	CALMAPATH_ROUND		1	/* Round end */
#define	CALMAPATH_SQUAREPLUS	2	/* Square end plus half-width extent */
#define	CALMAPATH_VARIABLE	4	/* variable square extension */

/* Largest calma layer or data type numbers */
/* changing from 63 to largest unsigned 2 byte int - 2/12/98 mha 
 *   Lee ran into gds output that had layer num "99"
 *   layer numbers and types stored as 2 byte ints in boundarys etc.
 */
#define	CALMA_LAYER_MAX	((1<<16)-1)

/* max string length (but note that structure names must be MUCH shorter) */
#define GDS_STRING_LENGTH 512

/* Max length of calma names */
/* #define	CALMANAMELENGTH		32 */
#define	CALMANAMELENGTH		GDS_STRING_LENGTH

/* Length of record header */
#define	CALMAHEADERLENGTH	4

/* gds records */
extern char *gdsDataTypes[];           /* int to record data type name */
extern char gdsDataTypeSizes[];        /* int to record data type size */
extern GDSRecordType gdsRecordTypes[];  /* record type index to info */

#define	CalmaIsValidLayer(n)	((n) >= 0 && (n) <= CALMA_LAYER_MAX)

/* Used to index hash tables of (layer, datatype) pairs */
typedef struct
{
    int		 clt_layer;
    int		 clt_type;
} CalmaLayerType;

/* used to stash away gcell versions */
typedef struct gcellversion
{
  char *gv_cellName;          /* hash is on this name */ 
  VStamp gv_version;           
  struct gcellversion *gv_hashLink; /* hash table link */
} GCellVersion;

/* Struc for keeping track of instance name text element during calma read */

/*
 * GLOBAL VARIABLE FOR INSTANCE NAMES
 *
 * text "labels" on a given layer (cifCurReadStyle->crs_iNameCalmaNum) are
 * used to supply instance names.
 * 
 * The labels appears just before the instances (SREF) in the gds file.
 * 
 * When such a label is read it is stashed in this global variable,
 * when the following SREF is encountered, the instance name is used, and
 * this variable is reset.
 *
 * If this variable is not NULL (an instance name has not been used) when
 * another instance name is encountered, a definition is ended, etc.,
 * a warning is generated (by gdsNoisyFreeInstanceName() below).
 *
 */
extern char *gdsInstanceName;

/* if an (unused) instance name is still around, complain, and clear it */ 
extern void gdsNoisyFreeInstanceName();

extern bool gdsMapSlashHack;  /* temporary hack */
 
/* Globals for GDS Read Setup */
extern bool gdsReadDebug;
extern bool gdsReadCellnameToLower;
extern bool gdsReadCellnameToUpper;
extern double gdsReadScaleFactor;
extern bool gdsReadSnapToDesignGrid; /* to be removed! */
extern double gdsReadSnapTo; 
extern bool gdsReadUnmappedLayers;
extern bool gdsReadReportRoundingErrors;
extern bool gdsReadReportDuplicateInstances;
extern bool gdsReadReportUnmappedLayers;
extern int  gdsReadReportMaxWarnings;
extern bool gdsReadNoDRC;

/* Globals for GDS Write Setup */
FILE *calmaWriteFile;
extern char *gdsWriteLibName;
extern double gdsWriteScaleFactor;
extern bool gdsWriteRestrictCharacterSet;
extern bool gdsWriteRestrictCellNameLength;
extern bool gdsWriteReportRoundingErrors;
extern bool gdsWriteReportExtendedCharacterSet;
extern bool gdsWriteReportExtendedCellNameLength;
extern bool gdsWriteProcessInteractions;

/* Other Globals for GDS reading */
extern double gdsRdScaleGDS2CIFPlane;  /* scale factor used when reading GDS */
extern double gdsRdScaleGDS2CIFPlaneErr; /* max error applying above */  
extern int gdsRdRoundRes; /* round input to this grid (derived from gdsReadSnapTo)*/
extern bool calmaLApresent;
extern int calmaLAnbytes;
extern int calmaLArtype;
extern int calmaStairSteps;  /* number of data elements converted to manhattan by
			      * introducing stair-steps.
			      */
int gdsReadMessageInterval;             /* tcl linked */


/* input buffer */
extern bool gdsRdEOF;   /* set when gdsReadBytes() fails */
extern unsigned char gdsRdBuf[BUFSIZ];
extern unsigned char *gdsRdBufEnd;
extern unsigned char *gdsRdBufLoc;
 
/* ------------------------- Input macros ----------------------------- */
  
  
/*
 * Macros for number representation conversion.
 */
#ifdef ibm032
#include <netinet/in.h>    /* as macros in in.h and don't exist as routines */
#endif

#ifndef	ntohl
# ifdef	IS_BIG_ENDIAN
# define ntohl(x)        (x)
# define ntohs(x)        (x)
# define htonl(x)        (x)
# define htons(x)        (x)
# endif 
#endif

typedef union { char uc[2]; unsigned short us; } TwoByteInt;
typedef union { char uc[4]; unsigned int ul; } FourByteInt;

/*
 * ----------------------------------------------------------------------------
 *
 * gdsReadBytes --
 *
 * read bytes from gdsII input file to specified location
 *
 * returns TRUE on success, FALSE on failure.
 *
 * ----------------------------------------------------------------------------
 */
static __inline__ bool gdsReadBytes(void *buf, 
				               /* bytes put here */ 
				    int n)
                                               /* number of bytes to read */
{
  unsigned char *last = gdsRdBufLoc+n-1;

  /* if data not in buffer, get help :-) */
  if(last>gdsRdBufEnd) return gdsReadBytes1(buf,n);

  /* we got the data, just copy it */
  while (gdsRdBufLoc<=last)  *(((unsigned char *) buf)++) = *(gdsRdBufLoc++);
  return TRUE;
}  
  
/* Macro to read a 2-byte integer */
#define	READI2(z) \
	{ \
            TwoByteInt u; \
	    gdsReadBytes(u.uc,2); \
            (z) = (int) ntohs(u.us); \
	}


/* Macro to read a 4-byte integer */
#define	READI4(z) \
	{ \
            FourByteInt u; \
	    gdsReadBytes(u.uc,4); \
            (z) = (int) ntohl(u.ul); \
	}

  
/* Macro to read a bit array (unsigned 2 byte int) */
#define	READ_BITARRAY(z) \
	{ \
            TwoByteInt u; \
	    gdsReadBytes(u.uc,2); \
            (z) = (unsigned int) ntohs(u.us); \
	}

/*
 * Macro to read a point from the input, and scale to CIFPlane coordinates.
 * 
 */
#define READPOINT(p) \
	{ \
	    READI4((p)->p_x); \
	    READI4((p)->p_y); \
	    GeoScalePointGrid(p, \
			      gdsRdScaleGDS2CIFPlane, \
			      &gdsRdScaleGDS2CIFPlaneErr, \
			      gdsRdRoundRes); \
	}

/* Macros for reading and unreading record headers */
#define READRH(nb, rt) \
	{ \
	    if (calmaLApresent) { \
		(nb) = calmaLAnbytes; \
		(rt) = calmaLArtype; \
		calmaLApresent = FALSE; \
	    } else { \
		READI2(nb); \
		if (gdsRdEOF) { (nb) = -1; (rt) = CALMA_EOF; } \
		else { \
                    unsigned char READRHtmp; \
                    gdsReadBytes(&READRHtmp,1); \
                    (rt) = READRHtmp; \
                    gdsReadBytes(&READRHtmp,1); \
		} \
	    } \
	}

#define UNREADRH(nb, rt) \
	{ \
	    ASSERT(!calmaLApresent, "UNREADRH"); \
	    calmaLApresent = TRUE; \
	    calmaLAnbytes = (nb); \
	    calmaLArtype = (rt); \
	}

#define	PEEKRH(nb, rt) \
	{ \
	    READRH(nb, rt); \
	    UNREADRH(nb, rt); \
	}



/* ----------------------- Output macros ----------------------------------- */

/*
 * calmaOutRH --
 *
 * Output a Calma record header.
 * This consists of a two-byte count of the number of bytes in the
 * record (including the two count bytes), a one-byte record type,
 * and a one-byte data type.
 */
#define	calmaOutRH(count, type, datatype) \
    { calmaOutI2(count); (void) putc(type, calmaWriteFile); (void) putc(datatype, calmaWriteFile); }


/*
 * calmaOutBitArray --
 *
 * Output a unsigned two-byte integer.
 * Calma byte order is the same as the network byte order used
 * by the various network library procedures.
 */
#define	calmaOutBitArray(n) \
    { \
	union { short u_s; char u_c[2]; } u; \
	u.u_s = htons(n); \
	(void) putc(u.u_c[0], calmaWriteFile); \
	(void) putc(u.u_c[1], calmaWriteFile); \
    }
/*
 * calmaOutI2 --
 *
 * Output a two-byte integer.
 * Calma byte order is the same as the network byte order used
 * by the various network library procedures.
 */
#define	calmaOutI2(n) \
    { \
	union { short u_s; char u_c[2]; } u; \
	u.u_s = htons(n); \
	(void) putc(u.u_c[0], calmaWriteFile); \
	(void) putc(u.u_c[1], calmaWriteFile); \
    }
/*
 * calmaOutI4 --
 *
 * Output a four-byte integer.
 * Calma byte order is the same as the network byte order used
 * by the various network library procedures.
 */
#define calmaOutI4(n) \
    { \
	union { long u_i; char u_c[4]; } u; \
	u.u_i = htonl(n); \
	(void) putc(u.u_c[0], calmaWriteFile); \
	(void) putc(u.u_c[1], calmaWriteFile); \
	(void) putc(u.u_c[2], calmaWriteFile); \
	(void) putc(u.u_c[3], calmaWriteFile); \
    }

static __inline__ void calmaOutR(double f, int size)
{
  int signBit;
  int exp,exp16;
  unsigned char byte;

  /* split off sign */
  if(f>=0)
  {
    signBit = 0;
  }
  else
  {
    signBit = 128;
    f = -f;
  }

  /* split off exponent */
  f =  frexp(f,&exp);

  /* convert to base 16 */
  exp16 = (exp + 3) / 4;
  f = f  / (1<<(exp16*4 - exp));

  /* output first byte (sign and exponent) */
  byte = signBit | (exp16+64);      /* excess 64 */
  putc(byte,calmaWriteFile);

  /* output mantissa bytes */
  {
    int i;

    f = f*256;
    for(i=1;i<size;i++)
    {
      byte = floor(f);
      putc(byte, calmaWriteFile);
      f = (f - byte) * 256;
    }
  }
}

static __inline__ void calmaOutR4(double f)
{
  calmaOutR(f,4);
}

static __inline__ void calmaOutR8(double f)
{
  calmaOutR(f,8);
}

/* Other commonly used globals */
extern HashTable calmaLayerHash;
extern HashTable gdsReadCellNameHash;
extern void *gdsReadCellNameMap;
extern bool gdsReadCIFWarning[];
extern int calmaElementIgnore[];
extern char *calmaRecordName(int rtype);
extern int gdsReadNumPolygons;

/* ------------------- Imports from CIF reading ----------------------- */

extern CellDef *cifReadCellDef;
extern Plane *cifSubcellPlanes[];
extern Plane **cifCurReadPlanes;
extern HashTable CifCellTable;

/* ------------------- Procedures local to this module ----------------------- */

/* low level I/O */
extern void gdsReadIOInit(int fileDescriptor);
extern void gdsWriteIOInit(FILE *f);
extern bool gdsReadBytes(void *buf, int n);
extern void calmaOutStringRecord(int recordType, char *string);

/* messages */
extern void gdsReadMsgInit(void); 
extern void gdsReadMsgError(char *fmt, ...);
extern void gdsReadMsgWarn(char *fmt, ...);
extern void gdsReadMsgUnexpectedRecord(int wanted, int got);

/* gcell version table */
extern void gdsGCellVersionsInit(void);
extern void gdsGCellVersionAdd(char *cellName, VStamp *vs);
extern void gdsGCellVersionsCleanup(void);
extern VStamp gdsGCellVersionLookup(char *cellName);

/* misc */
extern bool calmaParseStructure(bool cellNames, char *dir);
extern void gdsInfo(Tcl_Interp *interp, int inFD);
extern void gdsDump(int inFD, FILE *out, int verbose);
extern void gdsCompile(FILE *in, FILE *out);
extern CellDef *gdsReadFile(int fd, char *cellNames, char *dir);

#endif _GDSINT




