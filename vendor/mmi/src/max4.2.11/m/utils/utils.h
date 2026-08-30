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



/* utils.h --
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
 * This file just defines all the features available from the
 * Magic utility routines.
 */

/* rcsid "$Header: utils.h,v 6.0 90/08/28 19:01:30 mayo Exp $" */

#ifndef _UTILS
#define _UTILS 

#ifndef _STDIO_H
#include <stdio.h>
#endif

#ifndef _DATABASE
#include "database.h"
#endif

/*
 * utils FILES:
 * 
 *   dqueue.[ch]    - double ended queue (implemented with array).
 *   geometry.[ch]  - points, rects, transforms etc.
 *   getrect.c      - hack using stdio internals to read 4 ints very fast.
 *   hash.[ch]      - (external) hash (struct for key and pointers malloced
 *                    for each element added to table.)
 *   heap.[ch]      - implements heaps.
 *   ihash.[ch]     - internal hash avoids malloc for each elemented added
 *                    and key copy, but items being hashed need hash link
 *                    field.
 *   lookup.c[ch]   - name table lookup permitting unique prefixes 
 *                    (mainly useful for command lookup).
 *   malloc.[ch]    - malloc/free macros and wrappers.
 *   match.c        - glob style (e.g. csh filename wildcarding) pattern
 *                    matching.
 *   mm.[ch]        - malloc monitor
 *   mmTcl.c        - tcl commands for mm.c
 *   path.c         - pathnames and search paths.
 *   runstats.[ch]  - routines to get time and space usage of process.
 *   stack.[ch]     - stack (implemented via chained arrays)
 *   string.c       - string routines.
 *   utlStats.c     - runtime statistics
 *   utlTcl.c       - tcl interface to some utils. 
 *                    
 */

/* --- lookup.c (name based table lookup with unique prefix feature) */

/* for lint */
typedef struct
{
    char *d_str;
} LookupTable;

extern int Lookup(char *str, char **table);
extern int LookupAny(char c, char **table);
extern int LookupFull(char *name, char **table);


/* --- match.c glob style pattern matching (e.g. csh filename wildcarding) */
extern int Match(register char *pattern, register char *string);
extern char *MatchPlainTextQ(char *pattern, char *buf, int bufSize);

/* --- path.c (pathnames and search paths) */

extern bool PaHasExtension(char *fname);
extern char *PaExtendedName(char *fname, char *defExt);
extern char *PaTildeExpandName(char *fname);
extern int PaConvertTilde(char **psource, char **pdest, int size);
extern FILE *PaOpen(char *file, char *mode, 
		    char *ext, char *path, 
		    char *library, char **pRealName);
extern void PaSplitName(char *name,  /* name to split */
			char *dir,   /* if non-null, dir part returned here */
			char *base,  /* if non-null, base name returned here */
			char *ext);  /* if non-null, extension returned here */

/* --- string.c */

extern char *StrDup(char **oldstr, char *str);
extern int StrIsWhite(char *line, int commentok);
extern int StrIsInt(char *s);
extern int StrIsDecimal(char *s);
extern void StrToLower(char *s);
extern void StrToUpper(char *s);
extern char *StrPropGet(char *name, char *prop, char *buf);
extern char *StrPropSet(char *name, char *prop, char *value, char *buf);
extern char *StrPropAdd(char *name, char *prop, char *value, char *buf);
extern char *StrQuote(char *s,   /* input string */ 
		      char *buf); /* results stored here */
extern char *StrQuoteParse(char *s,  /* input string */
			   char *result /* results stored here */);

/* strmap funcs manage table of string mappings */
extern void *StrMapInit(void);
extern void StrMapFree(void *map);
extern void StrMapAdd(void *map, char *from, char *to);
extern char *StrMapLookup(void *map, char *from);

/* The following macro takes an integer and returns another integer that
 * is the same as the first except that all the '1' bits are turned off,
 * except for the rightmost '1' bit.
 *
 * Examples:	01010100 --> 00000100
 *		1111 --> 0001
 *		0111011100 --> 0000000100
 */
#define	LAST_BIT_OF(x)	((x) & ~((x) - 1))

/* --- utlsStat.c */

extern void UtlsStatInit(void);
extern unsigned long UtlsStatHeapSize(void);
extern void UtlsStatProcessTimes(double *userp, double *sysp, double *realp); 

/* returns total memory required for malloc of given size */
static __inline__ int UtlsStatMallocMem(int size) 
{
  int result; 

  /* double word aligned */
  result = ((size + 7)/8)*8;

  /* two word overhead per malloc */
  result += 8;

  return result;
}

#endif _UTILS

