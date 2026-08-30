/* -------------------------------------------------------------------
 * drc_macros.i - 
 * 
 *	This file defines m4 macros for use in the drc section
 *	of Max technology files.  It encodes some recurring
 *	checks - such as enclosure, that are not trivial to
 *	specify directly.
 *
 * 	This file is intended to be included (#include drc_macros.i)
 *	in the .tech file, and expects cpp and m4 to be run in
 *	that order to generate the "compiled" .tech27 file.
 *
 *
 * Copyright (c) 1998 Micro Magic, Inc. All rights reserved.
 *
 * IN NO EVENT SHALL MICRO MAGIC, INC. BE LIABLE TO ANY PARTY FOR DIRECT,
 * INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF
 * THE USE OF THESE FILES AND ITS DOCUMENTATION, EVEN IF MICRO MAGIC,
 * INC. HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *        
 * MICRO MAGIC, INC. SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING,
 * BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.  THESE FILES PROVIDED
 * HEREUNDER ARE ON AN "AS IS" BASIS, AND MICRO MAGIC, INC. HAS NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS.
 *
 *  ------------------------------------------------------------------- */

/* m4 prefix is used on internal m4 macros for clarity and to avoid name 
 * clashes.
 * NOTE:  do not use m4_ prefix, this is used internally in m4!
 */

/* Default quotes bother gnu cpp */
changequote({,})

/* STRING_CAT -- concatenated quoted strings */
define(STRING_CAT,{"translit($1,", ) translit($2,", ) translit($3,", )"})

/* define constants */
define(m4NULL_STRING,{{}})

/* m4args -- allows alphameric arg names to be declared and used
 *	     in m4 definitions (in place of $1 etc)
 *
 *	usage: 	
 *		define(macro_name m4args(arg_nm1 ...) macro_defn)
 *	Here the macr_defn can refer to args by name, and 
 *	should not be quoted (to permit arg name expansion 
 *	during definition).
 */
define(
  m4args,

  {
    ifelse($1,m4NULL_STRING,m4NULL_STRING, {{define({$1},$}{1)}})
    ifelse($2,m4NULL_STRING,m4NULL_STRING, {{define({$2},$}{2)}})
    ifelse($3,m4NULL_STRING,m4NULL_STRING, {{define({$3},$}{3)}})
    ifelse($4,m4NULL_STRING,m4NULL_STRING, {{define({$4},$}{4)}})
    ifelse($5,m4NULL_STRING,m4NULL_STRING, {{define({$5},$}{5)}})
    ifelse($6,m4NULL_STRING,m4NULL_STRING, {{define({$6},$}{6)}})
    ifelse($7,m4NULL_STRING,m4NULL_STRING, {{define({$7},$}{7)}})
    ifelse($8,m4NULL_STRING,m4NULL_STRING, {{define({$8},$}{8)}})
    ifelse($9,m4NULL_STRING,m4NULL_STRING, {{define({$9},$}{9)}})
  }
)

/* COVER -
 * Checks that A_TYPES are covered by COVER_TYPES everywhere
 */
#define COVER(A_TYPES,A_PLANE,COVER_TYPES,COVER_PLANE,ERR_MSG) \
  m4cover((A_TYPES),A_PLANE,(COVER_TYPES),COVER_PLANE,{ERR_MSG})

/* use m4 to expand to multiple lines */
define(
  m4cover,
  m4args(m4A_TYPES,m4A_PLANE,m4COVER_TYPES,m4COVER_PLANE,
    m4ERR_MSG)

  /* make sure each A_TYPE region is at least partially covered
     by COVER_TYPES */
  edge ~(m4A_TYPES)/m4A_PLANE (m4A_TYPES)/m4A_PLANE \
    1 m4COVER_TYPES 0 1 \
    m4ERR_MSG m4COVER_PLANE

  /* now make sure the covers are not partial. */
  edge (m4COVER_TYPES)/m4COVER_PLANE ~(m4COVER_TYPES)/m4COVER_PLANE \
  1 ~(m4A_TYPES)/m4A_PLANE 0 1 \
  m4ERR_MSG m4A_PLANE
)

/* CIF_COVER -
 * Checks that A_CIF is covered by COVER_CIF everywhere
 */
#define CIF_COVER(A_CIF,COVER_CIF,ERR_MSG) \
  m4cifcover(A_CIF,COVER_CIF,{ERR_MSG})

/* Use m4 to expand to multiple lines */
define(
  m4cifcover,
  m4args(m4A_CIF,m4COVER_CIF,
    m4ERR_MSG)

    /* make sure each A_CIF region is at least partially covered 
      by COVER_CIF */
    cifedge space m4A_CIF \
      1 m4COVER_CIF 0 1\
      m4ERR_MSG m4COVER_CIF

    /* now make sure the covers are not partial */
    cifedge m4COVER_CIF space \
      1 space 0 1 \
      m4ERR_MSG m4A_CIF
)

/* ENCLOSE -
 * Checks that A_TYPES are enclosed by ENCLOSE_TYPES by at least AMOUNT
 */
#define ENCLOSE(A_TYPES,A_PLANE,ENCLOSE_TYPES,ENCLOSE_PLANE,AMOUNT,ERR_MSG) \
  m4enclose((A_TYPES),A_PLANE,(ENCLOSE_TYPES),ENCLOSE_PLANE,AMOUNT,{ERR_MSG})

/* Use m4 to expand to multiple lines */
define(
  m4enclose,
  m4args(m4A_TYPES,m4A_PLANE,m4ENCLOSE_TYPES,m4ENCLOSE_PLANE,m4AMOUNT,
    m4ERR_MSG)

    /* make sure of enclosure at edges of A_TYPE regions by ENCLOSE_TYPES */
    edge4way (m4A_TYPES)/m4A_PLANE ~(m4A_TYPES)/m4A_PLANE \
      m4AMOUNT m4ENCLOSE_TYPES ~(m4A_TYPES)/m4A_PLANE m4AMOUNT\
      m4ERR_MSG m4ENCLOSE_PLANE

    /* now make sure no holes in cover. */
    edge m4ENCLOSE_TYPES ~(m4ENCLOSE_TYPES)/m4ENCLOSE_PLANE \
      1 ~(m4A_TYPES)/m4A_PLANE 0 1 \
      m4ERR_MSG m4A_PLANE
)

/* CIF_ENCLOSE -
 * Checks that A_CIF is enclosed by ENCLOSE_CIF by at least AMOUNT
 */
#define CIF_ENCLOSE(A_CIF,ENCLOSE_CIF,AMOUNT,ERR_MSG) \
  m4cifenclose(A_CIF,ENCLOSE_CIF,AMOUNT,{ERR_MSG})

/* Use m4 to expand to multiple lines */
define(
  m4cifenclose,
  m4args(m4A_CIF,m4ENCLOSE_CIF,m4AMOUNT,
    m4ERR_MSG)

    /* make sure of enclosure at edges of A_CIF regions by ENCLOSE_CIF */
    cifedge4way m4A_CIF space \
      m4AMOUNT m4ENCLOSE_CIF space m4AMOUNT\
      m4ERR_MSG m4ENCLOSE_CIF

    /* now make sure no holes in cover. */
    cifedge m4ENCLOSE_CIF space \
      1 space 0 1 \
      m4ERR_MSG m4A_CIF
)

/* HALO -
 * Checks that A_TYPES are surrounded by HALO_TYPES for at least AMOUNT
 * But note HALO_TYPES need not cover A_TYPES:  HALO & COVER = ENCLOSE 
 */
#define HALO(A_TYPES,A_PLANE,HALO_TYPES,HALO_PLANE,AMOUNT,ERR_MSG) \
  m4halo((A_TYPES),A_PLANE,(HALO_TYPES),HALO_PLANE,AMOUNT,{ERR_MSG})

/* Use m4 to expand to multiple lines */
define(
  m4halo,
  m4args(m4A_TYPES,m4A_PLANE,m4HALO_TYPES,m4HALO_PLANE,m4AMOUNT,
    m4ERR_MSG)

    /* make sure of HALO_TYPES halo at edges of A_TYPE for at least AMOUNT */
    edge4way (m4A_TYPES)/m4A_PLANE ~(m4A_TYPES)/m4A_PLANE \
      m4AMOUNT m4HALO_TYPES ~(m4A_TYPES)/m4A_PLANE m4AMOUNT\
      m4ERR_MSG m4HALO_PLANE
)

/* CIF_HALO -
 * Checks that A_CIF is surrounded by HALO_CIF for at least AMOUNT
 * But note HALO_CIF need not cover A_CIF:  CIF_HALO & CIF_COVER = CIF_ENCLOSE 
 */
#define CIF_HALO(A_CIF,HALO_CIF,AMOUNT,ERR_MSG) \
  m4cifhalo(A_CIF,HALO_CIF,AMOUNT,{ERR_MSG})

/* Use m4 to expand to multiple lines */
define(
  m4cifhalo,
  m4args(m4A_CIF,m4HALO_CIF,m4AMOUNT,
    m4ERR_MSG)

    /* make sure of HALO_CIF halo at edges of A_CIF for at least AMOUNT */
    cifedge4way m4A_CIF space \
      m4AMOUNT m4HALO_CIF space m4AMOUNT\
      m4ERR_MSG m4HALO_CIF
)

/* NO_OVERLAP -
 * Checks that A_TYPES and B_TYPES don't overlap anywhere.
 */
#define NO_OVERLAP(A_TYPES,A_PLANE,B_TYPES,B_PLANE,ERR_MSG) \
  m4noOverlap((A_TYPES),A_PLANE,(B_TYPES),B_PLANE,{ERR_MSG})

/* Use m4 to expand to multiple lines */
define(
  m4noOverlap,
  m4args(m4A_TYPES,m4A_PLANE,m4B_TYPES,m4B_PLANE,
    m4ERR_MSG)

    /* make sure no A region begins (scanning left to right) inside 
     * a B region.
     */
    edge ~(m4A_TYPES)/m4A_PLANE (m4A_TYPES)/m4A_PLANE \
      1 ~(m4B_TYPES)/m4B_PLANE 0 1 \
      m4ERR_MSG m4B_PLANE

    /* now make sure no B region begins inside an A region */
    edge ~(m4B_TYPES)/m4B_PLANE m4B_TYPES \
      1 ~(m4A_TYPES)/m4A_PLANE 0 1 \
      m4ERR_MSG m4A_PLANE
)

/* CIF_NO_OVERLAP -
 * Checks that A_CIF and B_CIF layers don't overlap anywhere.
 */
#define CIF_NO_OVERLAP(A_CIF,B_CIF,ERR_MSG) \
  m4cif_noOverlap(A_CIF,B_CIF,{ERR_MSG})

/* Use m4 to expand to multiple lines */
define(
  m4cif_noOverlap,
  m4args(m4A_CIF,m4B_CIF,m4ERR_MSG)

    /* make sure no A region begins (scanning left to right) inside 
     * a B region.
     */
    cifedge space m4A_CIF \
      1 space 0 1 \
      m4ERR_MSG m4B_CIF

    /* now make sure no B region begins inside an A region */
    cifedge space m4B_CIF \
      1 space 0 1 \
      m4ERR_MSG m4A_CIF
)

/* RECTANGULAR -
 * Check that regions formed from A_TYPES (joined together) are rectangular
 */
#define RECTANGULAR(A_TYPES,A_PLANE,ERR_MSG) \
  m4rectangular((A_TYPES),A_PLANE,{ERR_MSG})

define(
  m4rectangular,
  m4args(m4A_TYPES,m4A_PLANE,m4ERR_MSG)

  /* check for obtuse corners */	
  edge4way (m4A_TYPES)/m4A_PLANE ~(m4A_TYPES)/m4A_PLANE 1 \
    ~(m4A_TYPES)/m4A_PLANE m4A_TYPES 1 \
    m4ERR_MSG
)

/* CIF_RECTANGULAR -
 * Check that cif layer A_CIF consists of rectangular (convex) shapes.
 */
#define CIF_RECTANGULAR(A_CIF,ERR_MSG) \
  m4cif_rectangular(A_CIF,{ERR_MSG})

define(
  m4cif_rectangular,
  m4args(m4A_CIF,m4ERR_MSG)

  /* check for obtuse corners */	
  cifedge4way m4A_CIF space 1 \
    space m4A_CIF 1 \
    m4ERR_MSG
)

/* EXACT_WIDTH -
 * Check that layer A_TYPES have EXACTLY the given width
 */
#define EXACT_WIDTH(A_TYPES,A_PLANE,DIM,ERR_MSG) \
  m4exactwidth((A_TYPES),A_PLANE,DIM,{ERR_MSG})

define(
  m4exactwidth,
  m4args(m4A_TYPES,m4A_PLANE,m4DIM,m4ERR_MSG)

  maxwidth m4A_TYPES/m4A_PLANE m4DIM bend_ok \
    m4ERR_MSG

  /* this check maybe redundant - as cifmaxwidth with bend_ok seems to enforce
   * exact width despite its name - BUT that seems like a bug that may get fixed
   * sometime in the future?
   */ 
  width m4A_TYPES/m4A_PLANE m4DIM \
    m4ERR_MSG
)

/* CIF_EXACT_WIDTH -
 * Check that cif layer A_CIF regions have EXACTLY the given width
 */
#define CIF_EXACT_WIDTH(A_CIF,DIM,ERR_MSG) \
  m4cif_exact_width(A_CIF,DIM,{ERR_MSG})

define(
  m4cif_exact_width,
  m4args(m4A_CIF,m4DIM,m4ERR_MSG)


  cifmaxwidth m4A_CIF m4DIM bend_ok \
    m4ERR_MSG

  /* this check maybe redundant - as cifmaxwidth with bend_ok seems to enforce
   * exact width despite its name - BUT that seems like a bug that may get fixed
   * sometime in the future?
   */ 
  cifwidth m4A_CIF m4DIM \
    m4ERR_MSG
)
 
/* ILLEGAL
 * Check that no regions of given type are present!
 */
#define ILLEGAL(A_TYPES,A_PLANE,ERR_MSG) \
  m4illegal((A_TYPES),A_PLANE,{ERR_MSG})

define(
  m4illegal,
  m4args(m4A_TYPES,m4A_PLANE,m4ERR_MSG)

  edge4way (m4A_TYPES)/m4A_PLANE ~(m4A_TYPES)/m4A_PLANE 1 \
    0 0 1 \
    m4ERR_MSG
)
 
/* CIF_ILLEGAL
 * Check that no regions of given cif layer are present!
 */
#define CIF_ILLEGAL(A_CIF,ERR_MSG) \
  m4cif_illegal(A_CIF,{ERR_MSG})

define(
  m4cif_illegal,
  m4args(m4A_CIF,m4ERR_MSG)

  cifedge4way m4A_CIF space 1 \
    0 0 1 \
    m4ERR_MSG
)
