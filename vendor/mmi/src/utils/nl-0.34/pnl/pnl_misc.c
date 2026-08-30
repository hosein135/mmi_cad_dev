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

#include "port.h"
#include "error.h"
#include "mem.h"
#include "ar.h"
#include "hashtab.h"
#include "nl.h"
#include "skip-list.h"
#include "pnl.h"
#include "pnl_int.h"

#if 0
pnl_loctype
pnl_string_to_loctype (char *str)
{
  if ( strcasecmp (str, "UNPLACED") == 0 )
    return pnl_loctype_UNPLACED;
  else if ( strcasecmp (str, "PLACED") == 0 )
    return pnl_loctype_PLACED;
  else if ( strcasecmp (str, "FIXED") == 0 )
    return pnl_loctype_FIXED;
  else
    return pnl_loctype_null;
}


pnl_orientation
pnl_string_to_orientation (char *str)
{
  if ( strcasecmp (str, "none") == 0 )
    return pnl_orientation_none;
  else if ( strcasecmp (str, "N") == 0 )
    return pnl_orientation_N;
  else if ( strcasecmp (str, "S") == 0 )
    return pnl_orientation_S;
  else if ( strcasecmp (str, "FN") == 0 )
    return pnl_orientation_FN;
  else if ( strcasecmp (str, "FS") == 0 )
    return pnl_orientation_FS;
  else
    return pnl_orientation_null;
}
#endif


pnl_orientation
pnl_translate_orientation (pnl_orientation orient, pnl_orientation rotation)
{
  switch ( rotation ) {
  case pnl_orientation_N:
    return orient;

  case pnl_orientation_S:
    switch ( orient ) {
    case pnl_orientation_N:	return pnl_orientation_S;
    case pnl_orientation_S:	return pnl_orientation_N;
    case pnl_orientation_E:	return pnl_orientation_W;
    case pnl_orientation_W:	return pnl_orientation_E;
    case pnl_orientation_FN:	return pnl_orientation_FS;
    case pnl_orientation_FS:	return pnl_orientation_FN;
    case pnl_orientation_FE:	return pnl_orientation_FW;
    case pnl_orientation_FW:	return pnl_orientation_FE;
    default:			return pnl_orientation_null;
    }
  case pnl_orientation_E:
    switch ( orient ) {
    case pnl_orientation_N:	return pnl_orientation_E;
    case pnl_orientation_S:	return pnl_orientation_W;
    case pnl_orientation_E:	return pnl_orientation_S;
    case pnl_orientation_W:	return pnl_orientation_N;
    case pnl_orientation_FN:	return pnl_orientation_FE;
    case pnl_orientation_FS:	return pnl_orientation_FW;
    case pnl_orientation_FE:	return pnl_orientation_FS;
    case pnl_orientation_FW:	return pnl_orientation_FN;
    default:			return pnl_orientation_null;
    }
  case pnl_orientation_W:
    switch ( orient ) {
    case pnl_orientation_N:	return pnl_orientation_W;
    case pnl_orientation_S:	return pnl_orientation_E;
    case pnl_orientation_E:	return pnl_orientation_N;
    case pnl_orientation_W:	return pnl_orientation_S;
    case pnl_orientation_FN:	return pnl_orientation_FW;
    case pnl_orientation_FS:	return pnl_orientation_FE;
    case pnl_orientation_FE:	return pnl_orientation_FN;
    case pnl_orientation_FW:	return pnl_orientation_FS;
    default:			return pnl_orientation_null;
    }
  case pnl_orientation_FN:
    switch ( orient ) {
    case pnl_orientation_N:	return pnl_orientation_FN;
    case pnl_orientation_S:	return pnl_orientation_FS;
    case pnl_orientation_E:	return pnl_orientation_FE;
    case pnl_orientation_W:	return pnl_orientation_FW;
    case pnl_orientation_FN:	return pnl_orientation_N;
    case pnl_orientation_FS:	return pnl_orientation_S;
    case pnl_orientation_FE:	return pnl_orientation_E;
    case pnl_orientation_FW:	return pnl_orientation_W;
    default:			return pnl_orientation_null;
    }
  case pnl_orientation_FS:
    switch ( orient ) {
    case pnl_orientation_N:	return pnl_orientation_FS;
    case pnl_orientation_S:	return pnl_orientation_FN;
    case pnl_orientation_E:	return pnl_orientation_FW;
    case pnl_orientation_W:	return pnl_orientation_FE;
    case pnl_orientation_FN:	return pnl_orientation_S;
    case pnl_orientation_FS:	return pnl_orientation_N;
    case pnl_orientation_FE:	return pnl_orientation_W;
    case pnl_orientation_FW:	return pnl_orientation_E;
    default:			return pnl_orientation_null;
    }
  case pnl_orientation_FE:
    switch ( orient ) {
    case pnl_orientation_N:	return pnl_orientation_FE;
    case pnl_orientation_S:	return pnl_orientation_FW;
    case pnl_orientation_E:	return pnl_orientation_FS;
    case pnl_orientation_W:	return pnl_orientation_FN;
    case pnl_orientation_FN:	return pnl_orientation_E;
    case pnl_orientation_FS:	return pnl_orientation_W;
    case pnl_orientation_FE:	return pnl_orientation_S;
    case pnl_orientation_FW:	return pnl_orientation_N;
    default:			return pnl_orientation_null;
    }
  case pnl_orientation_FW:
    switch ( orient ) {
    case pnl_orientation_N:	return pnl_orientation_FW;
    case pnl_orientation_S:	return pnl_orientation_FE;
    case pnl_orientation_E:	return pnl_orientation_FN;
    case pnl_orientation_W:	return pnl_orientation_FS;
    case pnl_orientation_FN:	return pnl_orientation_W;
    case pnl_orientation_FS:	return pnl_orientation_E;
    case pnl_orientation_FE:	return pnl_orientation_N;
    case pnl_orientation_FW:	return pnl_orientation_S;
    default:			return pnl_orientation_null;
    }
  default:
    return orient;
  }
}


void
pnl_translate_coordinates (pnl_orientation orient, int x, int y,
			   int xmin, int ymin, int xmax, int ymax,
			   int *xt_p, int *yt_p)
{
  switch (orient) {
  case pnl_orientation_N:
    *xt_p =  x    + -xmin;
    *yt_p =     y + -ymin;
    return;
  case pnl_orientation_S:
    *xt_p = -x    +  xmax;
    *yt_p =    -y +  ymax;
    return;
  case pnl_orientation_E:
    *xt_p =     y + -ymin;
    *yt_p = -x    +  xmax;
    return;
  case pnl_orientation_W:
    *xt_p =    -y +  ymax;
    *yt_p =  x    + -xmin;
    return;
  case pnl_orientation_FN:
    *xt_p = -x    +  xmax;
    *yt_p =     y + -ymin;
    return;
  case pnl_orientation_FS:
    *xt_p =  x    + -xmin;
    *yt_p =    -y +  ymax;
    return;
  case pnl_orientation_FE:
    *xt_p =    -y +  ymax;
    *yt_p = -x    +  xmax;
    return;
  case pnl_orientation_FW:
    *xt_p =     y + -ymin;
    *yt_p =  x    + -xmin;
    return;
  default:
    ASSERT (0);
  }
}


pnl_design
pnl_get_pdesign_for_design (nl_design design)
{
  pnl_design pdesign = NULL;

  nl_design_attr_get_by_name ("pnl design", design, &pdesign);

  if ( pdesign == NULL ) {
    error ("design %s does not have any physical information",
	   nl_design_name (design));
  }

  return pdesign;
}


pnl_library
pnl_get_plibrary_for_library (nl_library library)
{
  pnl_library plibrary = NULL;

  nl_library_attr_get_by_name ("pnl library", library, &plibrary);

  if ( plibrary == NULL ) {
    error ("library %s does not have any physical information",
	   nl_library_name (library));
  }

  return plibrary;
}


pnl_libcell
pnl_get_plibcell_for_libcell (nl_libcell libcell)
{
  nl_library library = nl_libcell_library (libcell);
  pnl_library plibrary = NULL;
  pnl_libcell plibcell;

  nl_library_attr_get_by_name ("pnl library", library, &plibrary);

  plibcell = pnl_library_get_libcell (plibrary, libcell);

  return plibcell;
}


pnl_orientation
pnl_max_string_to_orientation (char *str)
{
  if ( strcmp (str, ""       ) == 0 ) return pnl_orientation_N;
  if ( strcmp (str, "r180"   ) == 0 ) return pnl_orientation_S;
  if ( strcmp (str, "r90"    ) == 0 ) return pnl_orientation_E;
  if ( strcmp (str, "r270"   ) == 0 ) return pnl_orientation_W;
  if ( strcmp (str, "fx"     ) == 0 ) return pnl_orientation_FN;
  if ( strcmp (str, "fy"     ) == 0 ) return pnl_orientation_FS;
  if ( strcmp (str, "fy_r90" ) == 0 ) return pnl_orientation_FE;
  if ( strcmp (str, "fx_r90" ) == 0 ) return pnl_orientation_FW;

  return pnl_orientation_null;
}


pnl_orientation
pnl_sue_string_to_orientation (char *str)
{
  if ( strcmp (str, "R0"     ) == 0 ) return pnl_orientation_N;
  if ( strcmp (str, "RXY"    ) == 0 ) return pnl_orientation_S;
  if ( strcmp (str, "R90"    ) == 0 ) return pnl_orientation_E;
  if ( strcmp (str, "R270"   ) == 0 ) return pnl_orientation_W;
  if ( strcmp (str, "RX"     ) == 0 ) return pnl_orientation_FN;
  if ( strcmp (str, "RY"     ) == 0 ) return pnl_orientation_FS;
  if ( strcmp (str, "R90Y"   ) == 0 ) return pnl_orientation_FE;
  if ( strcmp (str, "R90X"   ) == 0 ) return pnl_orientation_FW;

  return pnl_orientation_null;
}


pnl_orientation
pnl_any_string_to_orientation (char *str)
{
  pnl_orientation result;

  result = pnl_string_to_orientation (str);

  if ( result != pnl_orientation_null )
    return result;

  result = pnl_max_string_to_orientation (str);

  if ( result != pnl_orientation_null )
    return result;

  result = pnl_sue_string_to_orientation (str);

  return result;
}


const char *
pnl_orientation_to_max_string (pnl_orientation orient)
{
  switch ( orient ) {
  case pnl_orientation_N:    return "";
  case pnl_orientation_S:    return "r180";
  case pnl_orientation_E:    return "r90";
  case pnl_orientation_W:    return "r270";
  case pnl_orientation_FN:   return "fx";
  case pnl_orientation_FS:   return "fy";
  case pnl_orientation_FE:   return "fy_r90";
  case pnl_orientation_FW:   return "fx_r90";
  case pnl_orientation_none: return "none";
  case pnl_orientation_null: return "null";
  default: ASSERT (0);
  }
}


const char *
pnl_orientation_to_sue_string (pnl_orientation orient)
{
  switch ( orient ) {
  case pnl_orientation_N:    return "R0";
  case pnl_orientation_S:    return "RXY";
  case pnl_orientation_E:    return "R90";
  case pnl_orientation_W:    return "R270";
  case pnl_orientation_FN:   return "RX";
  case pnl_orientation_FS:   return "RY";
  case pnl_orientation_FE:   return "R90Y";
  case pnl_orientation_FW:   return "R90X";
  case pnl_orientation_none: return "none";
  case pnl_orientation_null: return "null";
  default: ASSERT (0);
  }
}
