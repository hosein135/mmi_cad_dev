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
#include "stdpccts.h"



void
lef2pnl_error (const char *format, ...)
{
  va_list ap;
  int len = strlen (format);
  char *new_format = alloca (32 + len);

  sprintf (new_format, "LEF error: line %d: %s", zzline, format);

  va_start (ap, format);
  error_va_list ((const char *) new_format, ap);
}


static
void
lef2pnl_zzerr (const char *text)
{
  error ("error: line %d at '%s': %s", lef_zzline, lef_zzlextext, text);
}


int
lef2pnl_translate_number (char *str, int precision)
{
  int len = strlen (str);
  char *start = alloca (len + precision + 1);
  char *t = start;
  char *s = str;
  int count = 0;
  int decimal = 0;
  int result;
  int i;

  while ( *s != 0 ) {
    if ( decimal ) {
      count++;
    }

    if ( count > precision ) {
      if ( *s != '0' ) {
	lef2pnl_error ("too many decimal places in number (max is %d): %s",
		       precision, str);
      }
    }
    else if ( *s == '.' ) {
      if ( decimal ) {
	lef2pnl_error ("duplicated decimal point: %s", str);
      }
      s++;
      decimal = 1;
    }
    else {
      *t = *s;
      s++;
      t++;
    }
  }

  for ( i = count; i < precision; i++ ) {
    *t = '0';
    t++;
  }

  *t = 0;

  result = atoi (start);

  return result;
}


pnl_libcell
lef2pnl_get_libcell (char *name, pnl_library plibrary)
{
  nl_library library = pnl_library_nl_rep (plibrary);
  nl_libcell libcell = nl_library_get_libcell_by_name (library, name);
  pnl_libcell result;

  if ( libcell == NULL ) {
    libcell = nl_libcell_create (name, library);
  }

  result = pnl_libcell_create (libcell, plibrary);

  return result;
}


pnl_libpin
lef2pnl_get_libpin (char *name, pnl_libcell plibcell)
{
  nl_libcell libcell = pnl_libcell_nl_rep (plibcell);
  nl_libpin libpin = (nl_libpin) nl_libcell_get_libpin_by_name (libcell, name);
  pnl_libpin result;

  if ( libpin == NULL ) {
    libpin = nl_libpin_create (name, nl_direction_null, libcell);
  }

  result = pnl_libpin_create (libpin, plibcell);

  return result;
}


void
lef2pnl_read_lef (FILE *ifp, nl_context context, nl_library library)
{
  mem_group prev_group = mem_group_set (nl_library_mem_group (library));

  error_unwind_protect {
    pnl_library plibrary = NULL;

    nl_library_attr_get_by_name ("pnl library", library, &plibrary);

    if ( plibrary == NULL ) {
      plibrary = pnl_library_create (library);
    }

    lef_zzerr = lef2pnl_zzerr;

    ANTLR (lef_file (plibrary), ifp);
  }
  error_on_exit {
    mem_group_set (prev_group);
  }
  error_end;
}
