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
 * magic.h --
 *
 * Global definitions for all Max modules
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
 * rcsid="$Header"
 */

#ifndef _MAGIC
#define	_MAGIC

#if _MSC_VER || WINNTPAT
/* _MSC_VER is defined by Microsoft compiler, which is only used
 * for Windows NT compiler.
 */
#ifndef WINNTPAT
#define WINNTPAT 1
#endif
#define	IS_LITTLE_ENDIAN	/* Intel x86 processors. */
/* Win NT compiler uses __inline for inline functions. */
#ifndef __inline__
#define __inline__ __inline
#endif
/* The Microsoft folks reserve the words "near" and "far".
 * Magic uses these as identifiers, so rename them.
 */
#define near near_xxx
#define far far_xxx

/* Some additional junk Win NT doesnt have.
 */
#define S_IFBLK (S_IFMT+1)  /* Set to an impossible value */
#define S_IFLNK (S_IFMT+2)  /* Set to an impossible value */
#define S_IFSOCK (S_IFMT+3)  /* Set to an impossible value */

/* The prototypes for ntohl, etc, used in m/gds/gdsInt.h, are defined
 * in winsock.h.  The prototypes are required, because the dips
 * at Microsoft defined them as using __stdcall instead of cdecl.
 * Unfortunately, winsock.h includes windows.h, and we do not
 * want to include that in every magic C file.  So we have to
 * explicitly pull out the decls we need and put them here.  Yuck.
 */
long __stdcall ntohl(long);
short __stdcall ntohs(short);
long __stdcall htonl(long);
short __stdcall htons(short);

/* sleep must be _sleep, and does not appear to exist in oldnames.lib
 */
#define sleep(x) _sleep(x)

/* rint function undefined in MSC library.
 */
#define rint(x) floor(x)

#endif /* WINNTPAT */

#ifndef _MATH_H
#include <math.h>
#endif

/* Note:  System files, such as "stdio.h" and "sys/types.h", should be
 * included before this magic.h file.
 */

#ifdef ALPHA32BIT
    /* must be before any declarations with pointers in them! */
#   pragma pointer_size(short)
#   ifndef ALPHA
#	define	ALPHA
#   endif
#endif

/* --------------------- Universal pointer type ----------------------- */

#ifndef _CLIENTDATA
#   ifdef __STDC__
        typedef void *ClientData;
#   else
        typedef int *ClientData;
#   endif /* __STDC__ */
#define _CLIENTDATA
#endif

/* --------------------------- Booleans ------------------------------- */

#define	bool	int
#define	TRUE	1
#define	FALSE	0

/* ----------------------- Simple functions --------------------------- */

static __inline__ int mod(int i, int m)
{
  int r;
  
  r = i%m;
  if(r<0) r += m;

  return r;
}

#ifndef	MAX
#define MAX(a,b)	(((a) < (b)) ? (b) : (a))
#endif

#ifndef	MIN
#define MIN(a,b)	(((a) > (b)) ? (b) : (a))
#endif

#define MAXI(a,b) ceil(MIN(a,b))

#define	ABS(x)		(((x) >= 0)  ? (x) : -(x))
#define	ABSDIFF(x,y)	(((x) < (y)) ? (y) - (x) : (x) - (y))
#define ODD(i)		(i&1)
#define EVEN(i)		(!(i&1))
/* Round anything (e.g. a double) to nearest integer */
#define ROUND(x) ((int) (((x)>0)?(x)+.5:(x)-.5 ))
static __inline__ int MODULO(int a, int n)
{
  a = a % n;
  return (a<0) ? a+n : a;
}

#define UNIT_TOLERANCE 1E-5	/* tolerance for checking for off grid dims */

/*** round to grid ***/

static __inline__ int roundDown(int i, int res)
{
  int r = (i%res);

  /* subtract positive remainder */
  if (r<0) r = r+res;
  return i-r;
}

static __inline__ int roundUp(int i, int res)
{
  int r = (i%res);

  /* subtract negative remainder */
  if (r>0) r = r-res;
  return i-r;
}

/* This "round about" method works for positive and negative numbers
 * for all legal arithmetic implementations.
 *
 * Consistently rounds down when in exact middle.
 * consistency important, so that connected things stay connected.
 */  
static __inline__ int roundNearest(int i, int res)
{
  int rNeg, rPos;
  int r = (i%res);

  if(r<0)
  {
    rNeg = r;
    rPos = r+res;
  }
  else
  {
    rNeg = r-res;
    rPos = r;
  }

  if(rPos < -rNeg)
  {
    return i-rPos;
  }
  else
  {
    return i-rNeg;
  }
}

/* offset of a structure member (used to gen offsets for ihash stuff) */
#if _MSC_VER
/* Microsoft compile complains about size of (void*), so must use (char*) */
/* Could use (char*) in UNIX version too. */
#define OFFSET(structure,member)   \
( ((char *) &(((structure *) 0))->member) - ((char *) 0) )
#else
#define OFFSET(structure,member)   \
( ((void *) &(((structure *) 0))->member) - ((void *) 0) )
#endif

/* returns greatest integer <= a and b */
static __inline__ int MINF2I(double a, double  b) 
{
  int i;

  if(a<b) 
  {
    i = a;
    return (a<0 && i!=a) ? i-1 : i;
  } 

  i = b;
  return (b<0 && i!=b) ? i-1 : i;
}

/* returns smallest integer >= a and b */
static __inline__ int MAXF2I(double a, double b) 
{
  int i;

  if(a>b) 
  {
    i = a;
    return (a>0 && i!=a ) ? i+1 : i;   
  } 

  i = b;
  return (b>0 && i!=b) ? i+1 : i;
}
/* --------------------- Assertions, Fatal Errors, and Debugging ------- */

/* backup modified cells, print error message, and coredump */
extern void MaxAbort(char *fmt, ...);

/* ASSERT() differences from POSIX assert():
 *   1. ASSERT() takes additional "description" arg.
 *   2. Calls MaxAbort() to try and backup modified cells before aborting.
 */
#ifdef	NDEBUG
#define ASSERT(p, where) (FALSE)
#else
#define	ASSERT(p, description) \
    ((!(p)) \
	? MaxAbort("Assertion %s %s failed, in file %s at line %d", \
		    (description)?description:"", \
		    #p, \
		    __FILE__, \
		    __LINE__) \
	: \
	   FALSE)
#endif NDEBUG

/* prefer ASSERT() to POSIX assert()
#define assert USE_ASSERT_INSTEAD_OF_assert

/* ---------- Flag for global variables (for readability) ------------- */
/*	      Also a Void type, which is like void except that we	*/
/*	      can declare pointers to functions that return it.	        */

#define	global	/* Nothing */
#define Void	void

/* ------------ Globally-used strings. -------------------------------- */

extern char *MaxVersion;
extern char *MaxVersionTag;  /* e.g. BETA */
extern char *MCVersion;
extern char *MaxCompileTime;

/* ---------------- Start of Machine Configuration Section ----------------- */

/* The great thing about standards is that there are so many to choose from! */
#ifdef	m68k
#define	mc68000		
#endif


    /* ------- Configuration:  Selection of Byte Ordering ------- */

/*	Big Endian:
 *		MSB....................LSB
 *		byte0  byte1  byte2  byte3
 *
 *	Little Endian:
 *		MSB....................LSB
 *		byte3  byte2  byte1  byte0
 *
 *	In big-endian, a pointer to a word points to the byte that
 *	contains the most-significant-bit of the word.  In little-endian, 
 *	it points to the byte containing the least-significant-bit.
 *
 */

#ifdef	linux
#define	IS_LITTLE_ENDIAN	/* Intel x86 processors running Linux >=.99p7. */
#endif

#ifdef	vax
#define	IS_LITTLE_ENDIAN	/* The good 'ol VAX. */
#endif

#ifdef	MIPSEL
#define	IS_LITTLE_ENDIAN	/* MIPS processors in little-endian mode. */
#endif

#ifdef	wrltitan
#define	IS_LITTLE_ENDIAN 	/* A DEC-WRL titan research machine (only 20 exist). */
			/* NOT intended for the Ardent titan machine. */
#endif

#ifdef	MIPSEB
#define	IS_BIG_ENDIAN	/* MIPS processors in big-endian mode. */
#endif

#ifdef	mc68000
#define	IS_BIG_ENDIAN	/* All 68xxx machines, such as Sun2's and Sun3's. */
#endif

#ifdef	macII
#define	IS_BIG_ENDIAN	/* Apple MacII (also a 68000, but being safe here.) */
#endif

#ifdef	sparc
#define	IS_BIG_ENDIAN	/* All SPARC-based machines. */
#endif

#ifdef	ibm032
#define	IS_BIG_ENDIAN 	/* IBM PC-RT and related machines. */
#endif

#ifdef	hp9000s300
#define	IS_BIG_ENDIAN 	/* HP 9000 machine.  */
#endif

#ifdef	hp9000s800
#define	IS_BIG_ENDIAN 	/* HP 9000 machine.  */
#endif

#ifdef	hp9000s820
#define	IS_BIG_ENDIAN 	/* HP 9000 machine.  */
#endif

#ifdef	ALPHA
#define	IS_LITTLE_ENDIAN	/* Digital Alpha AXP */
#endif

/* Well, how'd we do? */

#if	!defined(IS_BIG_ENDIAN) && !defined(IS_LITTLE_ENDIAN)
    You_need_to_define_IS_LITTLE_ENDIAN_or_IS_BIG_ENDIAN_for_your_machine.
#endif
#if	defined(IS_BIG_ENDIAN) && defined(IS_LITTLE_ENDIAN)
    You_should_not_define_both_IS_LITTLE_ENDIAN_and_IS_BIG_ENDIAN.
#endif

    /* ------- Configuration:  Handle Missing Routines/Definitions ------- */

/* System V is missing some BSDisms. */
#ifdef SYSV
# ifndef index
#  define index(x,y)		strchr((x),(int)(y))
# endif
# ifndef bcopy
#  define bcopy(a, b, c)	memcpy(b, a, c)
# endif
# ifndef bzero
#  define bzero(a, b)		memset(a, 0, b)
# endif
# ifndef rindex
#  define rindex(x,y)  strrchr((x),(int)(y))
# endif
#endif

/* Some machines expect signal handlers to return an "int".  But most machines
 * expect them to return a "void".  If your machine expects an "int", put in
 * an "ifdef" below.
 */

#if 	(defined(MIPSEB) && defined(SYSTYPE_BSD43)) || ibm032
# define	SIG_RETURNS_INT
#endif

/*
 * Irix 
 */
#ifdef IRIX
#define vfork fork
#endif

/* ------------------ End of Machine Configuration Section ----------------- */

#endif _MAGIC

