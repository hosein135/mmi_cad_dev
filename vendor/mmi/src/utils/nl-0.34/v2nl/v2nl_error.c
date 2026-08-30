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

#include "stdpccts.h"
#include "error.h"


void
v2nl_zzsyn (char *text, int tok, char *egroup, SetWordType *eset,
       int etok, int k, char *bad_text)
{
  error ("Syntax error, line %d at \"%s\"", zzline, bad_text);
}


void
v2nl_failed_predicate (char *text)
{
  char *s = alloca (strlen (text) + 1);

  sscanf (text, "%[^ \t]", s);

  if ( strcmp (s, "v2nl_rtl") ) {
    v2nl_error ("RTL language feature detected at \"%s\".\n"
		"\tThe -rtl option must be used to read this file", zztext);
  }
  else {
    v2nl_error ("intenal error: failed semantic predicate \"%s\"", text);
  }
}


void
v2nl_error (const char *format, ...)
{
  va_list ap;
  int len = strlen (format);
  char *new_format = alloca (32 + len);

  sprintf (new_format, "error: %s line %d: %s", v2nl_current_file, zzline,
	   format);

  va_start (ap, format);
  error_va_list ((const char *) new_format, ap);
}


void
v2nl_ast_error (nl_ast node, const char *format, ...)
{
  va_list ap;
  int len = strlen (format);
  char *new_format = alloca (32 + len);
  char *file = nl_ast_file (node);
  int line = nl_ast_line (node);

  sprintf (new_format, "error: %s line %d: %s", file, line, format);

  va_start (ap, format);
  error_va_list ((const char *) new_format, ap);
}


void
v2nl_warning (const char *format, ...)
{
  va_list ap;
  int len = strlen (format);
  char *new_format = alloca (32 + len);

  sprintf (new_format, "warning: %s line %d: %s\n",
	   v2nl_current_file, zzline,
	   format);

  va_start (ap, format);
  vfprintf (stderr, (const char *) new_format, ap);
}


void
v2nl_ast_warning (nl_ast node, const char *format, ...)
{
  va_list ap;
  int len = strlen (format);
  char *new_format = alloca (32 + len);
  char *file = nl_ast_file (node);
  int line = nl_ast_line (node);

  sprintf (new_format, "warning: %s line %d: %s\n", file, line, format);

  va_start (ap, format);
  vfprintf (stderr, (const char *) new_format, ap);
}
